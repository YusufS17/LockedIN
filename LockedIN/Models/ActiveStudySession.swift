import Foundation

/// The frozen local session and its recorded events. Dates survive process termination;
/// participant IDs survive restoration and remain the world reward receipt keys.
struct ActiveStudySession: Codable, Equatable, Identifiable {
    enum Phase: String, Codable { case focusing, onBreak, goalCheck, results }
    enum GoalReview: String, Codable, CaseIterable {
        case achieved, partly, notYet, skipped
        var label: String {
            switch self {
            case .achieved: return "I did it"
            case .partly: return "Made progress"
            case .notYet: return "Not this time"
            case .skipped: return "Skip for now"
            }
        }
    }

    let version: Int
    let id: UUID
    let config: RoomConfig
    let startedAt: Date
    private(set) var participants: [SessionParticipant]
    private(set) var clock: FocusClock
    private(set) var phase: Phase = .focusing
    private(set) var breaksUsed = 0
    private(set) var breakStartedAt: Date?
    private(set) var accumulatedBreakSeconds: TimeInterval = 0
    private(set) var endedAt: Date?
    private(set) var goalReview: GoalReview?

    init(config: RoomConfig, participants: [SessionParticipant], now: Date = Date()) {
        version = 1
        id = UUID()
        self.config = config
        startedAt = now
        self.participants = participants
        clock = FocusClock(seconds: config.sessionSeconds, now: now)
        for i in self.participants.indices {
            self.participants[i].status = .focused
            if self.participants[i].isUser {
                self.participants[i].focusPct = 0
                self.participants[i].distractions = 0
                self.participants[i].leftEarly = false
                self.participants[i].focusedSeconds = nil
            }
        }
    }

    var isRunning: Bool { phase == .focusing || phase == .onBreak }
    var user: SessionParticipant? { participants.first(where: \.isUser) }
    var isValid: Bool {
        version == 1 && (1...180).contains(config.focusMinutes) &&
        config.breakAllowance >= 0 && config.breakAllowance <= 10 &&
        participants.count >= 1 && participants.count <= 8 &&
        participants.filter(\.isUser).count == 1 &&
        Set(participants.map(\.id)).count == participants.count &&
        participants.allSatisfy { $0.studyIntent?.isValid ?? true } &&
        clock.isValid && clock.duration == Double(config.sessionSeconds) &&
        clock.isPaused == (phase != .focusing) &&
        breaksUsed >= 0 && breaksUsed <= config.breakAllowance &&
        accumulatedBreakSeconds.isFinite && accumulatedBreakSeconds >= 0 &&
        (phase == .onBreak) == (breakStartedAt != nil) &&
        (isRunning ? endedAt == nil : endedAt != nil)
    }

    func breakSeconds(at now: Date) -> Int {
        Int((accumulatedBreakSeconds + (breakStartedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0)).rounded(.down))
    }

    /// Expiry is determined by the saved deadline, not the number of UI ticks.
    mutating func update(at now: Date) {
        guard isRunning else { return }
        if clock.remaining(at: now) == 0 { finish(leaving: false, at: now); return }
        let elapsed = clock.focusedSeconds(at: now)
        for i in participants.indices where !participants[i].isUser {
            if elapsed >= max(2, Int(Double(config.sessionSeconds) * 0.45)),
               participants[i].distractions > config.distractionLimit {
                participants[i].status = .distracted
            } else if elapsed > 20 { participants[i].status = .deepFocus }
        }
    }

    mutating func toggleBreak(at now: Date) {
        update(at: now)
        guard isRunning, let me = participants.firstIndex(where: \.isUser) else { return }
        if phase == .onBreak {
            accumulatedBreakSeconds += breakStartedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0
            breakStartedAt = nil
            clock.resume(at: now)
            phase = .focusing
            participants[me].status = .focused
        } else if breaksUsed < config.breakAllowance {
            clock.pause(at: now)
            breakStartedAt = now
            breaksUsed += 1
            phase = .onBreak
            participants[me].status = .onBreak
        }
    }

    /// Explicit self-report only. No claim to detect app usage or interruptions.
    mutating func reportInterruption(at now: Date) {
        update(at: now)
        guard phase == .focusing, let me = participants.firstIndex(where: \.isUser) else { return }
        participants[me].distractions += 1
    }

    mutating func finish(leaving: Bool, at now: Date) {
        guard isRunning, leaving || clock.remaining(at: now) == 0 else { return }
        let elapsed = clock.focusedSeconds(at: now)
        let early = leaving && clock.remaining(at: now) > 0
        let breaks = breakSeconds(at: now)
        clock.pause(at: now)
        accumulatedBreakSeconds = Double(breaks)
        breakStartedAt = nil
        endedAt = now
        for i in participants.indices {
            if participants[i].isUser {
                participants[i].focusedSeconds = elapsed
                participants[i].focusPct = min(100, elapsed * 100 / config.sessionSeconds)
                participants[i].leftEarly = early
                participants[i].recordedBreakCount = breaksUsed
                participants[i].recordedBreakSeconds = breaks
            } else {
                participants[i].focusedSeconds = elapsed * participants[i].focusPct / 100
            }
            participants[i].status = early ? .idle : .finished
        }
        phase = early ? .results : .goalCheck
    }

    mutating func reviewGoal(_ answer: GoalReview) {
        guard phase == .goalCheck else { return }
        goalReview = answer
        phase = .results
    }
}
