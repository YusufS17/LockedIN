import Foundation

// MARK: - Participant

/// A participant in a study room session — either the real user or a scripted bot.
///
/// Bots are simulated participants driven by Task-based scripts in Phase 3.
/// No network identity; all data is local/in-memory.
struct Participant: Identifiable, Equatable {
    /// Unique identifier (stable for the session lifetime).
    let id: UUID
    /// Display name shown in the UI (e.g. "You", "Maya", "Leo").
    let displayName: String
    /// `true` for scripted bots; `false` for the real user.
    let isBot: Bool
}
