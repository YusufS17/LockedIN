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
final class MockFocusControlAdapter: FocusControlAdapter {

    // MARK: - Script Storage

    /// Per-participant scripted event sequences. Keyed by participant UUID.
    /// Inject at init; swap scripts to simulate different behaviours in tests.
    private let scripts: [UUID: [ScriptedFocusEvent]]

    /// Active monitoring tasks, keyed by participant UUID.
    /// Stored so `stopMonitoring` can cancel them.
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Init

    /// - Parameter scripts: A dictionary mapping participant UUIDs to their scripted event sequences.
    ///   Events are emitted in order after their `offsetSeconds` delay from the moment `startMonitoring` is called.
    ///   An empty dict or missing key means the participant emits no events.
    init(scripts: [UUID: [ScriptedFocusEvent]] = [:]) {
        self.scripts = scripts
    }

    // MARK: - FocusControlAdapter

    func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent> {
        let script = scripts[participantID] ?? []

        let stream = AsyncStream<FocusEvent> { continuation in
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

            // Store task so stopMonitoring can cancel it.
            activeTasks[participantID] = task

            // When the stream consumer cancels, also cancel the task.
            continuation.onTermination = { [weak self] _ in
                self?.activeTasks[participantID]?.cancel()
                self?.activeTasks.removeValue(forKey: participantID)
            }
        }

        return stream
    }

    func stopMonitoring(participantID: UUID) {
        activeTasks[participantID]?.cancel()
        activeTasks.removeValue(forKey: participantID)
    }
}
