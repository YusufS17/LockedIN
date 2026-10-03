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
        duration.isFinite && duration > 0 && pausedRemaining.isFinite &&
        pausedRemaining >= 0 && pausedRemaining <= duration &&
        (deadline?.timeIntervalSince1970.isFinite ?? true)
    }

    func remaining(at now: Date) -> Int {
        Int(ceil(exactRemaining(at: now)))
    }

    func focusedSeconds(at now: Date) -> Int {
        Int((duration - exactRemaining(at: now)).rounded(.down))
    }

    mutating func pause(at now: Date) {
        guard deadline != nil else { return }
        pausedRemaining = exactRemaining(at: now)
        deadline = nil
    }

    mutating func resume(at now: Date) {
        guard deadline == nil, pausedRemaining > 0 else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
    }

    private func exactRemaining(at now: Date) -> TimeInterval {
        min(duration, max(0, deadline.map { $0.timeIntervalSince(now) } ?? pausedRemaining))
    }
}
