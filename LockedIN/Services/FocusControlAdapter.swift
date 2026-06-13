import Foundation

// MARK: - FocusControlAdapter Protocol (FND-03)

/// The focus-tracking boundary for LockedIN.
///
/// All focus-monitoring signals reach session logic ONLY through this protocol —
/// the concrete tracking mechanism (mock script / Screen Time / etc.) is hidden behind
/// the seam (SAFE-04, T-01-08).
///
/// Real implementation path: `RealScreenTimeFocusControlAdapter: FocusControlAdapter` (REAL-01, v2).
/// Prototype path: `MockFocusControlAdapter` (scripted deterministic event sequences).
///
/// PRIVACY INVARIANT (SAFE-02, T-01-06):
/// `startMonitoring` emits only `FocusEvent` values, which carry participantID + Date only.
/// No app names, bundle IDs, URLs, message content, or any private usage data ever crosses this boundary.
protocol FocusControlAdapter: AnyObject {

    /// Begin monitoring focus for the given participant.
    ///
    /// Returns an `AsyncStream<FocusEvent>` that yields aggregate focus signals.
    /// The stream continues until `stopMonitoring` is called for this participant.
    ///
    /// - Parameter participantID: The participant to monitor.
    /// - Returns: An async stream of aggregate-only FocusEvents (SAFE-02).
    func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent>

    /// Stop monitoring and cancel the stream for the given participant.
    ///
    /// After this call, the stream returned by the corresponding `startMonitoring` will finish.
    ///
    /// - Parameter participantID: The participant whose monitoring should stop.
    func stopMonitoring(participantID: UUID)
}
