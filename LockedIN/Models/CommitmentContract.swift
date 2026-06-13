import Foundation

// MARK: - Commitment Contract

/// An immutable record of a study-room commitment agreement.
///
/// A contract starts unfrozen (mutable via builder) and is frozen once all
/// participants have agreed — after which it cannot be changed.
///
/// Money fields use `MinorUnits = Int` (pence); no Double/Float/Decimal (FND-01).
struct CommitmentContract: Equatable {

    // MARK: - Immutable Contract Terms (set at creation)

    /// Unique identifier for this contract.
    let id: UUID

    /// Display name of the study room.
    let roomName: String

    /// Total session duration in seconds (e.g. 50 * 60 == 50 minutes).
    let durationSeconds: Int

    /// Stake amount in minor units (pence). Must be > 0 for staked contracts.
    let stakeMinorUnits: MinorUnits

    /// Allowed distraction window in total seconds before the stake is at risk.
    let maxDistractionSeconds: Int

    /// Maximum number of breaks permitted during the session.
    let maxBreaks: Int

    /// ISO 4217 currency code (e.g. "GBP").
    let currencyCode: String

    /// Timestamp when the contract was first created.
    let createdAt: Date

    // MARK: - Freeze State

    /// Set when all participants agree; nil means the contract is still open.
    /// `private(set)` ensures only `frozen()` can set this.
    private(set) var frozenAt: Date?

    // MARK: - Computed State

    /// `true` once the contract has been agreed and frozen by all participants.
    var isFrozen: Bool {
        frozenAt != nil
    }

    // MARK: - Freeze

    /// Returns a frozen copy of this contract.
    /// Call once all participants have agreed — the returned copy cannot be mutated further.
    func frozen() -> CommitmentContract {
        var copy = self
        copy.frozenAt = Date()
        return copy
    }
}
