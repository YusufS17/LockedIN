import Foundation

// MARK: - Hold Reference

/// An opaque reference to an authorised payment hold on a participant's wallet.
/// Returned by `CommitmentService.authoriseHold` and passed to `settle`.
///
/// Money representation: `amountMinorUnits` is always `MinorUnits = Int` (pence).
/// FORBIDDEN: Double, Float, Decimal (FND-01, T-01-05).
struct HoldReference: Identifiable, Hashable {
    /// Unique identifier for this hold.
    let id: UUID
    /// The participant whose wallet is held.
    let participantID: UUID
    /// The held amount in minor units (pence). Integer-only — no floats.
    let amountMinorUnits: MinorUnits
}

// MARK: - Settlement Verdict

/// Whether a participant passed or failed their commitment contract.
enum SettlementVerdict: Equatable {
    /// Participant met the contract — stake returned.
    case passed
    /// Participant broke the contract — stake forfeited.
    case failed
}

// MARK: - Settlement Record

/// The immutable outcome of a settled hold.
///
/// Money conservation invariant (T-01-05, FND-01):
///   `returnedMinorUnits + forfeitedMinorUnits == holdRef.amountMinorUnits`
/// This must hold for BOTH verdicts. Integer arithmetic enforces it.
///
/// `isTestMode` is always `true` for the prototype — SettlementRecord carries this
/// flag so any future display layer can surface the TEST marker without querying FeatureFlags.
struct SettlementRecord: Equatable {
    /// The hold that was settled.
    let holdRef: HoldReference
    /// The pass/fail outcome.
    let verdict: SettlementVerdict
    /// Amount returned to the participant's wallet, in minor units (pence).
    let returnedMinorUnits: MinorUnits
    /// Amount forfeited (sent to forfeit destination), in minor units (pence).
    let forfeitedMinorUnits: MinorUnits
    /// Timestamp of settlement.
    let settledAt: Date
    /// Always `true` for the prototype mock — no real money moves.
    let isTestMode: Bool
}
