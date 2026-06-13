import Foundation

// MARK: - Mock Commitment Service (D-09, D-10)

/// Simulated in-memory wallet for the LockedIN prototype.
///
/// Conforms to `CommitmentService`; no real money moves (D-09, D-10, SAFE-01).
/// Wallet seeds at 2000 pence (£20.00) per D-09.
/// Forfeit destination = "British Red Cross" per D-10.
///
/// Money conservation invariant (T-01-05, FND-01):
///   `settle()` ensures `returnedMinorUnits + forfeitedMinorUnits == holdRef.amountMinorUnits`
///   for BOTH verdicts. Integer arithmetic only — no Double/Float/Decimal.
///
/// NOT ObservableObject — plain class per CLAUDE.md (@Observable used in AppStore for UI state).
final class MockCommitmentService: CommitmentService {

    // MARK: - Configuration

    /// Starting wallet balance in pence (D-09: £20.00 = 2000 pence).
    static let startingBalance: MinorUnits = 2000

    /// Named charity where forfeited stakes are donated in test mode (D-10).
    let forfeitDestination: String = "British Red Cross"

    // MARK: - In-Memory State

    /// Per-participant simulated wallet balances (pence).
    private var balances: [UUID: MinorUnits] = [:]

    /// Active holds: maps hold UUID → HoldReference.
    private var activeHolds: [UUID: HoldReference] = [:]

    // MARK: - Init

    init() {}

    // MARK: - CommitmentService

    func authoriseHold(
        participantID: UUID,
        amountMinorUnits: MinorUnits,
        contract: CommitmentContract
    ) async throws -> HoldReference {
        // Seed balance on first access for this participant.
        let current = balances[participantID, default: Self.startingBalance]

        guard amountMinorUnits > 0 else {
            throw CommitmentServiceError.invalidAmount("Hold amount must be > 0; got \(amountMinorUnits)")
        }
        guard current >= amountMinorUnits else {
            throw CommitmentServiceError.insufficientBalance(
                available: current, required: amountMinorUnits
            )
        }

        // Deduct the hold from the available balance.
        balances[participantID] = current - amountMinorUnits

        let holdRef = HoldReference(
            id: UUID(),
            participantID: participantID,
            amountMinorUnits: amountMinorUnits
        )
        activeHolds[holdRef.id] = holdRef
        return holdRef
    }

    func settle(
        holdRef: HoldReference,
        verdict: SettlementVerdict
    ) async throws -> SettlementRecord {
        guard activeHolds[holdRef.id] != nil else {
            throw CommitmentServiceError.holdNotFound(holdRef.id)
        }

        // Remove the hold — it is now being settled.
        activeHolds.removeValue(forKey: holdRef.id)

        let held = holdRef.amountMinorUnits

        // Money conservation (T-01-05): returnedMinorUnits + forfeitedMinorUnits == held.
        // Integer arithmetic only — no Double/Float/Decimal.
        let returnedMinorUnits: MinorUnits
        let forfeitedMinorUnits: MinorUnits

        switch verdict {
        case .passed:
            // Return the full stake to the participant's balance.
            returnedMinorUnits = held
            forfeitedMinorUnits = 0
            balances[holdRef.participantID, default: 0] += held

        case .failed:
            // Forfeit the full stake to the forfeit destination; balance unchanged.
            returnedMinorUnits = 0
            forfeitedMinorUnits = held
        }

        // Assert conservation — belt-and-suspenders for the prototype.
        assert(
            returnedMinorUnits + forfeitedMinorUnits == held,
            "MockCommitmentService: money conservation violated — \(returnedMinorUnits) + \(forfeitedMinorUnits) != \(held)"
        )

        return SettlementRecord(
            holdRef: holdRef,
            verdict: verdict,
            returnedMinorUnits: returnedMinorUnits,
            forfeitedMinorUnits: forfeitedMinorUnits,
            settledAt: Date(),
            isTestMode: true
        )
    }

    func walletBalance(participantID: UUID) async -> MinorUnits {
        balances[participantID, default: Self.startingBalance]
    }
}

// MARK: - Error Types

enum CommitmentServiceError: Error, LocalizedError {
    case invalidAmount(String)
    case insufficientBalance(available: MinorUnits, required: MinorUnits)
    case holdNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .invalidAmount(let msg):
            return "Invalid amount: \(msg)"
        case .insufficientBalance(let available, let required):
            return "Insufficient balance: have \(available)p, need \(required)p"
        case .holdNotFound(let id):
            return "Hold not found: \(id)"
        }
    }
}
