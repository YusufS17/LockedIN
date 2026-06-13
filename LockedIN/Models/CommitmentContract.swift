import Foundation

// MARK: - Commitment Contract

/// An immutable record of a study-room commitment agreement.
///
/// A contract starts unfrozen (mutable via builder) and is frozen once all
/// participants have agreed — after which it cannot be changed.
///
/// Money fields use `MinorUnits = Int` (pence); no Double/Float/Decimal (FND-01).
///
/// Invariants enforced at construction (WR-03):
/// - `stakeMinorUnits >= 0`
/// - `durationSeconds > 0`
/// - `maxBreaks >= 0`
/// - `maxDistractionSeconds >= 0`
struct CommitmentContract: Equatable {

    // MARK: - Immutable Contract Terms (set at creation)

    /// Unique identifier for this contract.
    let id: UUID

    /// Display name of the study room.
    let roomName: String

    /// Total session duration in seconds (e.g. 50 * 60 == 50 minutes).
    let durationSeconds: Int

    /// Stake amount in minor units (pence). Must be >= 0; > 0 for staked contracts.
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

    // MARK: - Failable Initialiser (WR-03)

    /// Creates a `CommitmentContract` with validated invariants.
    ///
    /// Returns `nil` if any invariant is violated — prevents invalid contracts from
    /// ever being constructed (WR-03).
    ///
    /// - Parameters:
    ///   - id: Unique identifier (default: new UUID).
    ///   - roomName: Display name of the study room.
    ///   - durationSeconds: Session duration in seconds. Must be > 0.
    ///   - stakeMinorUnits: Stake in pence. Must be >= 0.
    ///   - maxDistractionSeconds: Allowed distraction window. Must be >= 0.
    ///   - maxBreaks: Max permitted breaks. Must be >= 0.
    ///   - currencyCode: ISO 4217 code (default: "GBP").
    ///   - createdAt: Creation timestamp (default: now).
    init?(
        id: UUID = UUID(),
        roomName: String,
        durationSeconds: Int,
        stakeMinorUnits: MinorUnits,
        maxDistractionSeconds: Int,
        maxBreaks: Int,
        currencyCode: String = "GBP",
        createdAt: Date = Date()
    ) {
        guard stakeMinorUnits >= 0,
              durationSeconds > 0,
              maxBreaks >= 0,
              maxDistractionSeconds >= 0 else {
            return nil
        }
        self.id = id
        self.roomName = roomName
        self.durationSeconds = durationSeconds
        self.stakeMinorUnits = stakeMinorUnits
        self.maxDistractionSeconds = maxDistractionSeconds
        self.maxBreaks = maxBreaks
        self.currencyCode = currencyCode
        self.createdAt = createdAt
    }

    // MARK: - Freeze (WR-04)

    /// Returns a frozen copy of this contract.
    /// Call once all participants have agreed — the returned copy cannot be mutated further.
    ///
    /// Idempotent: calling `frozen()` on an already-frozen contract returns the same
    /// contract unchanged (WR-04) — the `frozenAt` timestamp is never re-stamped.
    func frozen() -> CommitmentContract {
        guard frozenAt == nil else { return self } // already frozen: no-op (WR-04)
        var copy = self
        copy.frozenAt = Date()
        return copy
    }
}
