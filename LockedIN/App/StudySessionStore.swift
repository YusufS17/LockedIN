import Foundation
import Observation

/// One pending study journey, kept until the user acknowledges the results.
/// A crash between world reward saving and acknowledgment safely replays the same UUID.
@Observable
final class StudySessionStore {
    static let persistenceKey = "lockedin.activeStudySession.v1"
    private(set) var current: ActiveStudySession?
    private(set) var recoveryIssue: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        guard let data = defaults.data(forKey: Self.persistenceKey) else { return }
        do {
            var session = try JSONDecoder().decode(ActiveStudySession.self, from: data)
            guard session.isValid else { throw CocoaError(.coderReadCorrupt) }
            session.update(at: now)
            current = session
            persist()
        } catch {
            // Preserve the original payload; do not silently erase a failed recovery.
            recoveryIssue = "Your saved session couldn’t be restored. Your room and earned progress are safe."
        }
    }

    @discardableResult
    func begin(config: RoomConfig, participants: [SessionParticipant], now: Date = Date()) -> Bool {
        guard current == nil, recoveryIssue == nil, !config.isStaked,
              (1...180).contains(config.focusMinutes) else { return false }
        let session = ActiveStudySession(config: config, participants: participants, now: now)
        guard session.isValid else { return false }
        current = session
        persist()
        return true
    }

    func checkpoint(_ session: ActiveStudySession) {
        guard let previous = current, previous.id == session.id, session.isValid else { return }
        // Live checkpoints cannot rewrite a frozen outcome or its receipt identity.
        // Goal review has its own transition below.
        guard previous.isRunning, previous.config == session.config,
              previous.startedAt == session.startedAt,
              previous.participants.count == session.participants.count else { return }
        guard zip(previous.participants, session.participants).allSatisfy({ old, new in
            old.id == new.id && old.isUser == new.isUser &&
            old.character == new.character && old.displayName == new.displayName &&
            old.studyIntent == new.studyIntent
        }) else { return }
        guard previous != session else { return }
        current = session
        persist()
    }

    func reviewGoal(_ answer: ActiveStudySession.GoalReview) {
        current?.reviewGoal(answer)
        persist()
    }

    func acknowledgeResults(id: UUID) {
        guard current?.id == id, current?.phase == .results else { return }
        current = nil
        defaults.removeObject(forKey: Self.persistenceKey)
    }

    /// Only offered after an explicit user action on the recovery error UI.
    func discardUnreadableSession() {
        guard recoveryIssue != nil else { return }
        defaults.removeObject(forKey: Self.persistenceKey)
        recoveryIssue = nil
    }

    private func persist() {
        guard let current, let data = try? JSONEncoder().encode(current) else { return }
        defaults.set(data, forKey: Self.persistenceKey)
    }
}
