import Foundation

/// A deadline-based focus clock. Suspended UI updates do not extend a session.
/// Approved breaks freeze the remaining duration until explicitly resumed.
struct FocusClock: Codable, Equatable {
    let duration: TimeInterval
    private var deadline: Date?
    private var pausedRemaining: TimeInterval

    init(seconds: Int, now: Date = Date()) {
        duration = TimeInterval(max(1, seconds))
        pausedRemaining = duration
        deadline = now.addingTimeInterval(duration)
    }

    var isPaused: Bool { deadline == nil }

    var isValid: Bool {
        duration.isFinite && duration > 0 && duration < Double(Int.max) && pausedRemaining.isFinite &&
        pausedRemaining >= 0 && pausedRemaining <= duration &&
        (deadline.map(Self.isRepresentableDate) ?? true)
    }

    func remaining(at now: Date) -> Int {
        Self.integerSeconds(ceil(exactRemaining(at: now)))
    }

    func focusedSeconds(at now: Date) -> Int {
        Self.integerSeconds((duration - exactRemaining(at: now)).rounded(.down))
    }

    mutating func pause(at now: Date) {
        guard isValid, Self.isRepresentableDate(now), deadline != nil else { return }
        pausedRemaining = exactRemaining(at: now)
        deadline = nil
    }

    mutating func resume(at now: Date) {
        guard isValid, Self.isRepresentableDate(now), deadline == nil, pausedRemaining > 0 else { return }
        guard Self.isRepresentableDate(now.addingTimeInterval(pausedRemaining)) else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
    }

    /// Date and integer display conversions share a representable numeric range.
    /// This is a machine bound, not a calendar-age limit on stored sessions.
    static func isRepresentableDate(_ date: Date) -> Bool {
        let seconds = date.timeIntervalSince1970
        return seconds.isFinite && seconds >= -Double(Int.max) && seconds < Double(Int.max)
    }

    private static func integerSeconds(_ seconds: TimeInterval) -> Int {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        guard seconds < Double(Int.max) else { return Int.max }
        return Int(seconds)
    }

    private func exactRemaining(at now: Date) -> TimeInterval {
        guard isValid, Self.isRepresentableDate(now) else { return 0 }
        return min(duration, max(0, deadline.map { $0.timeIntervalSince(now) } ?? pausedRemaining))
    }
}
