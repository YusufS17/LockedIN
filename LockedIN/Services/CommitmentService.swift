import Foundation

// MARK: - CommitmentService Protocol (FND-02)

/// The payment/settlement boundary for LockedIN.
///
/// All payment and stake operations reach the wallet ONLY through this protocol —
/// UI, session, and shield code never call a concrete payment type directly (SAFE-04, T-01-08).
///
/// Real implementation path: `StripeCommitmentService: CommitmentService` (PAY-01, v2).
/// Prototype path: `MockCommitmentService` (seeded at 2000 pence, no real money moves).
///
/// Money: all amounts are `MinorUnits = Int` (pence). FORBIDDEN: Double, Float, Decimal (FND-01).
protocol CommitmentService: AnyObject {

    /// Authorise a stake hold on a participant's wallet.
    ///
    /// - Parameters:
    ///   - participantID: The participant whose wallet is debited.
    ///   - amountMinorUnits: Stake amount in pence (> 0).
    ///   - contract: The frozen commitment contract governing the stake.
    /// - Returns: A `HoldReference` identifying this hold — pass to `settle`.
    /// - Throws: If authorisation fails (insufficient balance, service error, etc.).
    func authoriseHold(
        participantID: UUID,
        amountMinorUnits: MinorUnits,
        contract: CommitmentContract
    ) async throws -> HoldReference

    /// Settle a previously authorised hold.
    ///
    /// Money conservation invariant (T-01-05):
    ///   `record.returnedMinorUnits + record.forfeitedMinorUnits == holdRef.amountMinorUnits`
    ///
    /// - Parameters:
    ///   - holdRef: The reference returned by `authoriseHold`.
    ///   - verdict: `.passed` → return stake; `.failed` → forfeit stake.
    /// - Returns: An immutable `SettlementRecord` confirming the outcome.
    /// - Throws: If settlement fails (hold not found, service error, etc.).
    func settle(
        holdRef: HoldReference,
        verdict: SettlementVerdict
    ) async throws -> SettlementRecord

    /// Current simulated wallet balance for a participant, in minor units (pence).
    ///
    /// - Parameter participantID: The participant to query.
    /// - Returns: Balance in pence (`MinorUnits = Int`).
    func walletBalance(participantID: UUID) async -> MinorUnits
}
