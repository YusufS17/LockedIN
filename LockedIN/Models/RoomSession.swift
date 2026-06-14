import Foundation

// MARK: - RoomConfig — the commitment contract the user sets up

struct RoomConfig: Equatable {
    var roomName: String
    var subject: String
    var focusMinutes: Int
    var stakePence: Pence
    var breakAllowance: Int       // permitted breaks (count)
    var distractionLimit: Int     // permitted distraction events (count)
    var competitive: Bool         // competitive vs supportive (supportive hides negative titles)
    var quickDemo: Bool           // 20s timer for demoing

    static let preset = RoomConfig(
        roomName: "Finals Focus Room",
        subject: "Economics",
        focusMinutes: 25,
        stakePence: 500,
        breakAllowance: 1,
        distractionLimit: 3,
        competitive: true,
        quickDemo: false
    )

    var sessionSeconds: Int { quickDemo ? 20 : max(1, focusMinutes) * 60 }
    var forfeitDestination: String { ForfeitConfig.destination }

    /// Builds the frozen `CommitmentContract` that governs the stake/holds (FND money path).
    func makeFrozenContract() -> CommitmentContract {
        let contract = CommitmentContract(
            roomName: roomName,
            durationSeconds: sessionSeconds,
            stakeMinorUnits: stakePence,
            maxDistractionSeconds: distractionLimit,   // proxy: limit as a config value
            maxBreaks: breakAllowance
        )
        // Init is failable only on invalid invariants; preset values are always valid.
        return (contract ?? CommitmentContract(
            roomName: "Focus Room", durationSeconds: 60, stakeMinorUnits: 500,
            maxDistractionSeconds: 3, maxBreaks: 1
        )!).frozen()
    }
}

// MARK: - SessionParticipant

struct SessionParticipant: Identifiable {
    let id = UUID()
    let character: StudyCharacter
    let displayName: String
    let isUser: Bool

    // Scripted behaviour (deterministic — no randomness, SES-04).
    var distractions: Int
    var leftEarly: Bool
    var focusPct: Int

    // Live state during the session.
    var status: AvatarStatus = .focused

    /// Builds the deterministic demo roster: you + Maya (clean), Leo (1 distraction), Sam (cracks).
    static func makeRoster(userCharacter: StudyCharacter, userName: String, config: RoomConfig) -> [SessionParticipant] {
        [
            SessionParticipant(character: userCharacter, displayName: userName.isEmpty ? "You" : userName,
                               isUser: true, distractions: 0, leftEarly: false, focusPct: 97),
            SessionParticipant(character: CharacterCatalog.character(id: "maya"), displayName: "Maya",
                               isUser: false, distractions: 0, leftEarly: false, focusPct: 95),
            SessionParticipant(character: CharacterCatalog.character(id: "leo"), displayName: "Leo",
                               isUser: false, distractions: 1, leftEarly: false, focusPct: 88),
            SessionParticipant(character: CharacterCatalog.character(id: "sam"), displayName: "Sam",
                               isUser: false, distractions: config.distractionLimit + 1, leftEarly: false, focusPct: 61)
        ]
    }
}

// MARK: - ContractRules — deterministic pass/fail (SES-04)

enum ContractRules {
    static func verdict(for participant: SessionParticipant, config: RoomConfig) -> SettlementVerdict {
        (participant.leftEarly || participant.distractions > config.distractionLimit) ? .failed : .passed
    }
}

// MARK: - Results

struct ParticipantResult: Identifiable {
    var id: UUID { participant.id }
    let participant: SessionParticipant
    let verdict: SettlementVerdict
    let returnedPence: Pence
    let forfeitedPence: Pence
}

struct SessionResult {
    let results: [ParticipantResult]
    let totalReturnedPence: Pence
    let totalForfeitedPence: Pence
    let champion: SessionParticipant?     // highest focus among passers
    let culprit: SessionParticipant?      // most distractions among failers
    let firstToFold: SessionParticipant?  // first to cross the limit (demo: the culprit)
    let isTestMode: Bool
}

// MARK: - SettlementEngine — real money settlement via CommitmentService

@MainActor
enum SettlementEngine {

    /// Authorises a hold per participant, settles each by deterministic verdict, and
    /// aggregates the result. Real Int-pence money through the service boundary (FND-02).
    static func run(config: RoomConfig, participants: [SessionParticipant], service: CommitmentService) async -> SessionResult {
        let contract = config.makeFrozenContract()
        var results: [ParticipantResult] = []
        var totalReturned = 0
        var totalForfeited = 0
        var testMode = true

        for p in participants {
            let verdict = ContractRules.verdict(for: p, config: config)
            do {
                let hold = try await service.authoriseHold(
                    participantID: p.id, amountMinorUnits: config.stakePence, contract: contract
                )
                let record = try await service.settle(holdRef: hold, verdict: verdict)
                totalReturned += record.returnedMinorUnits
                totalForfeited += record.forfeitedMinorUnits
                testMode = record.isTestMode
                results.append(ParticipantResult(participant: p, verdict: verdict,
                                                 returnedPence: record.returnedMinorUnits,
                                                 forfeitedPence: record.forfeitedMinorUnits))
            } catch {
                // Conservative fallback keeps money conserved even if the service errors.
                let returned = verdict == .passed ? config.stakePence : 0
                let forfeited = verdict == .passed ? 0 : config.stakePence
                totalReturned += returned
                totalForfeited += forfeited
                results.append(ParticipantResult(participant: p, verdict: verdict,
                                                 returnedPence: returned, forfeitedPence: forfeited))
            }
        }

        let passers = results.filter { $0.verdict == .passed }.map(\.participant)
        let failers = results.filter { $0.verdict == .failed }.map(\.participant)
        let champion = passers.max(by: { $0.focusPct < $1.focusPct })
        let culprit = failers.max(by: { $0.distractions < $1.distractions })

        return SessionResult(
            results: results,
            totalReturnedPence: totalReturned,
            totalForfeitedPence: totalForfeited,
            champion: champion,
            culprit: culprit,
            firstToFold: culprit,
            isTestMode: testMode
        )
    }
}
