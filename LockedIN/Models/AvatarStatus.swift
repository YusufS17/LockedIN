import SwiftUI

// MARK: - AvatarStatus (D-23, ONB-03)
//
// Status states for the reusable AvatarView component.
// All states declared now; only .idle used in Phase 2.
// Phase 4 activates focused/deepFocus/onBreak/distracted/finished.
// Non-colour-only overlays are required (ONB-03 accessibility).

enum AvatarStatus: String, Equatable {
    case idle
    case focused
    case deepFocus
    case onBreak
    case distracted
    case finished

    /// Human-readable label for VoiceOver and the status badge text.
    var label: String {
        switch self {
        case .idle:       return "Idle"
        case .focused:    return "Focused"
        case .deepFocus:  return "Deep"
        case .onBreak:    return "Break"
        case .distracted: return "!"
        case .finished:   return "Done"
        }
    }

    /// SF Symbol name for the status badge icon (non-colour-only cue, ONB-03).
    /// Returns nil for .idle (no badge shown when idle).
    var symbolName: String? {
        switch self {
        case .idle:       return nil
        case .focused:    return "lock.fill"
        case .deepFocus:  return "bolt.fill"
        case .onBreak:    return "cup.and.saucer.fill"
        case .distracted: return "exclamationmark.triangle.fill"
        case .finished:   return "checkmark.circle.fill"
        }
    }

    /// Ring colour for the status badge background (non-colour-only — always paired with symbolName/label).
    var ringColour: Color {
        switch self {
        case .idle:       return .clear
        case .focused:    return Theme.Colour.accent
        case .deepFocus:  return Theme.Colour.accentTeal
        case .onBreak:    return Theme.Colour.textSecondary
        case .distracted: return Theme.Colour.forfeitRed
        case .finished:   return Theme.Colour.moneyGreen
        }
    }
}
