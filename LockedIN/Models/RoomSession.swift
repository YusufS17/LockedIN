import Foundation

// MARK: - RoomConfig — the commitment contract the user sets up

struct RoomConfig: Equatable, Codable {
    var roomName: String
    var subject: String
    var focusMinutes: Int
    var stakePence: Pence
    var breakAllowance: Int       // permitted breaks (count)
    var distractionLimit: Int     // permitted distraction events (count)
    var competitive: Bool         // competitive vs supportive (supportive hides negative titles)
    var quickDemo: Bool           // 20s timer for demoing

    var goal: String = ""

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

    /// Personal focus room — no stake, no opponents, supportive.
    static let solo = RoomConfig(
        roomName: "Your Focus Room",
        subject: "Deep work",
        focusMinutes: 25,
        stakePence: 0,
        breakAllowance: 1,
        distractionLimit: 3,
        competitive: false,
        quickDemo: false
    )

    /// Drop-in squad room — social, no stake, crowns a focus champion.
    static let groupRoom = RoomConfig(
        roomName: "The study club",
        subject: "Mixed subjects",
        focusMinutes: 25,
        stakePence: 0,
        breakAllowance: 1,
        distractionLimit: 3,
        competitive: false,
        quickDemo: false
    )

    /// Whether this room uses a simulated test stake (drives the settlement card).
    var isStaked: Bool { stakePence > 0 }

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

/// Text intentionally shown alongside a participant. Private outcome reviews and
/// interruption history never belong here. Optional on old saved sessions.
struct ParticipantStudyIntent: Codable, Equatable {
    let subject: String
    let goal: String

    var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        subject == subject.trimmingCharacters(in: .whitespacesAndNewlines) &&
        goal == goal.trimmingCharacters(in: .whitespacesAndNewlines) &&
        subject.count <= 40 && goal.count <= 120 &&
        !subject.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) &&
        !goal.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    }
}

// MARK: - SessionParticipant

struct SessionParticipant: Identifiable, Codable, Equatable {
    var id = UUID()
    let character: StudyCharacter
    let displayName: String
    let isUser: Bool

    // User interruptions are self-reported; companion values remain deterministic demo data.
    var distractions: Int
    var leftEarly: Bool
    /// User: percentage of planned timer completed. Companions: simulated values.
    var focusPct: Int

    // Live state during the session.
    var status: AvatarStatus = .focused
    var focusedSeconds: Int? = nil
    var recordedBreakSeconds: Int? = nil
    var recordedBreakCount: Int? = nil
    var studyIntent: ParticipantStudyIntent? = nil

    /// Solo roster — just the user, clean run.
    static func makeSolo(userCharacter: StudyCharacter, userName: String) -> [SessionParticipant] {
        [SessionParticipant(character: userCharacter, displayName: userName.isEmpty ? "You" : userName,
                            isUser: true, distractions: 0, leftEarly: false, focusPct: 0)]
    }

    /// Seeded companions are always labelled simulated in the app. Roster UUIDs
    /// are generated once at start and then retained by ActiveStudySession.
    static func makeRoster(userCharacter: StudyCharacter, userName: String, config: RoomConfig,
                           count: Int = 4) -> [SessionParticipant] {
        let intents = [
            ParticipantStudyIntent(subject: "Biology", goal: "Review cell division notes"),
            ParticipantStudyIntent(subject: "Literature", goal: "Outline one essay paragraph"),
            ParticipantStudyIntent(subject: "Maths", goal: "Practise five algebra problems"),
            ParticipantStudyIntent(subject: "Computer science", goal: "Trace a sorting algorithm"),
            ParticipantStudyIntent(subject: "History", goal: "Summarise the chapter"),
            ParticipantStudyIntent(subject: "Design", goal: "Sketch three layout ideas"),
            ParticipantStudyIntent(subject: "Languages", goal: "Practise new vocabulary")
        ]
        var me = makeSolo(userCharacter: userCharacter, userName: userName)[0]
        let intent = ParticipantStudyIntent(subject: config.subject, goal: config.goal)
        me.studyIntent = intent.isValid ? intent : nil
        var people = [me]
        for index in 0..<(min(8, max(2, count)) - 1) {
            let character = CharacterCatalog.all[index]
            var person = SessionParticipant(character: character, displayName: character.name,
                isUser: false, distractions: index == 2 ? config.distractionLimit + 1 : (index == 1 ? 1 : 0),
                leftEarly: false, focusPct: index == 2 ? 61 : (index == 1 ? 88 : 95))
            person.studyIntent = intents[index]
            people.append(person)
        }
        return people
    }

}

// MARK: - ContractRules — deterministic pass/fail (SES-04)

enum ContractRules {
    static func verdict(for participant: SessionParticipant, config: RoomConfig) -> SettlementVerdict {
        (participant.leftEarly || (config.competitive && participant.distractions > config.distractionLimit)) ? .failed : .passed
    }
}

// MARK: - Results

struct ParticipantResult: Identifiable {
    var id: UUID { participant.id }
    let participant: SessionParticipant
    let verdict: SettlementVerdict
    let returnedPence: Pence
    let forfeitedPence: Pence
    var settlementFailed = false
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
        if !config.isStaked {
            let results = participants.map {
                ParticipantResult(participant: $0, verdict: ContractRules.verdict(for: $0, config: config),
                                  returnedPence: 0, forfeitedPence: 0)
            }
            return SessionResult(results: results, totalReturnedPence: 0, totalForfeitedPence: 0,
                                 champion: nil, culprit: nil, firstToFold: nil, isTestMode: true)
        }
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
                // A service failure is not a settlement. Never invent returned/forfeited amounts.
                results.append(ParticipantResult(participant: p, verdict: verdict,
                                                 returnedPence: 0, forfeitedPence: 0, settlementFailed: true))
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
