import Foundation

// MARK: - Focus Event (SAFE-02)

/// An aggregate focus-tracking signal emitted by `FocusControlAdapter`.
///
/// PRIVACY INVARIANT (SAFE-02, T-01-06):
/// Every case carries ONLY `participantID: UUID` and `at: Date`.
/// FORBIDDEN fields — must never be added to any case:
///   - App names, bundle IDs, or usage durations
///   - URLs or web domains
///   - Message or notification content
///   - Contact names or identifiers
///   - Any user-identifiable or third-party-app information
///
/// The `FocusControlAdapter` protocol and `MockFocusControlAdapter` are the
/// only emitters; SourceKit / Screen Time data is out of scope for the prototype.
enum FocusEvent: Equatable {

    /// Participant began a distraction period (left the focus app context).
    case distractionStarted(participantID: UUID, at: Date)

    /// Participant ended a distraction period (returned to focus app context).
    case distractionEnded(participantID: UUID, at: Date)

    /// Participant started an explicit break.
    case breakStarted(participantID: UUID, at: Date)

    /// Participant ended an explicit break.
    case breakEnded(participantID: UUID, at: Date)

    /// Participant left the session entirely (app backgrounded / closed).
    case leftSession(participantID: UUID, at: Date)
}
