import Foundation

// MARK: - Scripted Focus Event

/// A single scripted event in a bot's focus timeline.
///
/// `offsetSeconds` is the delay from session start before the event fires.
/// `event` is the FocusEvent emitted at that offset.
struct ScriptedFocusEvent {
    let offsetSeconds: Double
    let event: FocusEvent
}

// MARK: - Mock Focus Control Adapter (FND-03, SAFE-02)

/// Scripted, deterministic focus event emitter for the LockedIN prototype.
///
/// Accepts a per-participant script of `ScriptedFocusEvent` values.
/// Each `startMonitoring` call returns an `AsyncStream<FocusEvent>` driven by
/// `Task.sleep` at the configured offsets — fully cancellable via `stopMonitoring`.
///
/// PRIVACY INVARIANT (SAFE-02, T-01-06):
/// Only `FocusEvent` values are emitted — each carrying `participantID + Date` only.
/// No app names, bundle IDs, URLs, message or notification content is ever emitted.
///
/// NOT ObservableObject — plain class per CLAUDE.md.
/// Task.sleep(for:) (Duration API, Swift 5.7+, iOS 16+) drives timing.
///
/// Thread-safety: `activeTasks` is guarded by `lock` (CR-01).
/// Task-ordering: any prior task for a participant is cancelled before a new one
/// is registered, preventing orphaned tasks and duplicate emissions (CR-02).
final class MockFocusControlAdapter: FocusControlAdapter {

    // MARK: - Script Storage

    /// Per-participant scripted event sequences. Keyed by participant UUID.
    /// Inject at init; swap scripts to simulate different behaviours in tests.
    private let scripts: [UUID: [ScriptedFocusEvent]]

    /// Active monitoring tasks, keyed by participant UUID.
    /// Stored so `stopMonitoring` can cancel them.
    /// ALL accesses (read and write) must be guarded by `lock` (CR-01).
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    /// Serial lock protecting `activeTasks` from concurrent reads/writes (CR-01).
    private let lock = NSLock()

    // MARK: - Init

    /// - Parameter scripts: A dictionary mapping participant UUIDs to their scripted event sequences.
    ///   Events are emitted in order after their `offsetSeconds` delay from the moment `startMonitoring` is called.
    ///   An empty dict or missing key means the participant emits no events.
    init(scripts: [UUID: [ScriptedFocusEvent]] = [:]) {
        self.scripts = scripts
    }

    // MARK: - Lock-Guarded Task Helpers (CR-01)

    /// Store (or remove, if nil) a task for a participant, guarded by `lock`.
    private func setTask(_ task: Task<Void, Never>?, for id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        if let task {
            activeTasks[id] = task
        } else {
            activeTasks.removeValue(forKey: id)
        }
    }

    /// Cancel and remove the task for a participant, guarded by `lock`.
    private func cancelTask(for id: UUID) {
        lock.lock()
        let task = activeTasks.removeValue(forKey: id)
        lock.unlock()
        task?.cancel()
    }

    // MARK: - FocusControlAdapter

    func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent> {
        // CR-02 fix: cancel any prior task for this participant BEFORE creating the new
        // one, so we never orphan a running task or emit ghost events for old sessions.
        stopMonitoring(participantID: participantID)

        let script = scripts[participantID] ?? []

        return AsyncStream { continuation in
            // CR-02 fix: create the Task and register it in `activeTasks` before the
            // Task body can observe `onTermination`, eliminating the storage-vs-
            // termination race. We create the Task but guard registration under lock.
            let task = Task {
                // Emit scripted events in chronological order.
                // Each event fires after `offsetSeconds` from startMonitoring call.
                var lastOffset: Double = 0
                for scripted in script {
                    // Compute incremental sleep duration (avoids drift accumulation).
                    let increment = scripted.offsetSeconds - lastOffset
                    lastOffset = scripted.offsetSeconds

                    if increment > 0 {
                        // Task.sleep(for:) is cancellable and non-blocking (Swift 5.7+, iOS 16+).
                        do {
                            try await Task.sleep(for: .seconds(increment))
                        } catch {
                            // Task was cancelled — stop emitting.
                            break
                        }
                    }

                    if Task.isCancelled { break }
                    continuation.yield(scripted.event)
                }
                continuation.finish()
            }

            // CR-01 fix: store task under lock so concurrent startMonitoring /
            // stopMonitoring / onTermination calls cannot race on the dictionary.
            setTask(task, for: participantID)

            // When the stream consumer cancels, also cancel the task.
            // cancelTask is lock-guarded and idempotent (CR-01).
            continuation.onTermination = { [weak self] _ in
                self?.cancelTask(for: participantID)
            }
        }
    }

    func stopMonitoring(participantID: UUID) {
        // cancelTask is lock-guarded and idempotent (CR-01).
        cancelTask(for: participantID)
    }
}
