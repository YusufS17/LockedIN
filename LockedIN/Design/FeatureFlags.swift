// MARK: - Feature Flags (D-12, FND-05, SAFE-02)
//
// These 4 flags are LOCKED at the values below for the hackathon prototype.
// They must be READ at the relevant boundaries — not just declared.
// ENABLE_REAL_MONEY_STAKES is read at the MoneyLabel render boundary so the
// TEST marker is always shown, making money-without-marker structurally impossible.

enum FeatureFlags {
    /// When `false` (prototype default): simulated wallet only; no real money moves.
    /// Read at the MoneyLabel render boundary (SAFE-02, FND-05).
    static let ENABLE_REAL_MONEY_STAKES = false

    /// When `true`: simulated test-money stakes are active (the demo mode).
    static let ENABLE_TEST_STAKES = true

    /// When `false`: room prize pool (redistribute forfeited £ to passers) is disabled.
    /// Legally sensitive; deferred to v2 (STAKE-02).
    static let ENABLE_ROOM_PRIZE_POOL = false

    /// When `false` (prototype default): sponsored reward flow not yet built (IN-02).
    /// Set to `true` only once the flow exists; a `true` flag for an unbuilt feature
    /// is a footgun — the first reader will believe it is live.
    static let ENABLE_SPONSORED_REWARDS = false
}
