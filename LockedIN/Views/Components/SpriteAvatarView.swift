import SwiftUI

// MARK: - SpriteAvatarView — a character's animated sprite with idle "breathing"
//
// Renders the character's code-drawn PixelKit sprite (all art is in-engine — no PNG
// assets) and layers on the BreathingModifier for idle life. Optionally overlays a
// non-colour-only status badge (icon + ring) for live session states.

struct SpriteAvatarView: View {

    let character: StudyCharacter
    var status: AvatarStatus = .idle
    var size: CGFloat = 80
    var showStatusBadge: Bool = false
    /// Subtle idle "breathing" (juice). On by default; pickers/grids pass `false`.
    var animated: Bool = true

    /// Stable per-avatar phase so a roomful of avatars don't breathe in lockstep.
    private var phase: Double {
        Double(abs(character.id.hashValue) % 1000) / 1000.0
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatar
                .modifier(BreathingModifier(enabled: animated, status: status, phase: phase))

            if showStatusBadge, status != .idle, let symbol = status.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: max(10, size * 0.22), weight: .bold))
                    .foregroundStyle(.white)
                    .padding(max(3, size * 0.06))
                    .background(Circle().fill(status.ringColour))
                    .overlay(Circle().strokeBorder(Theme.Colour.surface, lineWidth: 1.5))
            }
        }
        .frame(width: size, height: size)
    }

    private var avatar: some View {
        PixelAvatarView(appearance: character.fallback, status: status, size: size, animated: animated)
    }
}

// MARK: - BreathingModifier — gentle idle life, flavoured by status
//
// A clock-driven micro-animation: a slow breath for focus states, a relaxed
// sway on break, and a tiny anxious jitter when distracted. Anchored at the feet so the
// avatar appears to settle on the floor. Fully gated on Reduce Motion.

private struct BreathingModifier: ViewModifier {
    let enabled: Bool
    let status: AvatarStatus
    let phase: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isAnimating: Bool { enabled && !reduceMotion }

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !isAnimating)) { timeline in
            let amount = isAnimating
                ? (1 - cos((timeline.date.timeIntervalSinceReferenceDate / period + phase) * .pi)) / 2
                : 0
            content
                .scaleEffect(1 + (scale - 1) * amount, anchor: .bottom)
                .offset(x: xOffset * amount, y: yOffset * amount)
                .rotationEffect(.degrees(tilt * amount))
        }
    }

    // Per-status motion character.
    private var period: Double {
        switch status {
        case .deepFocus, .finished: return 2.2   // slow, calm
        case .onBreak:              return 1.8
        case .distracted:           return 0.5   // quick, restless
        default:                    return 1.7
        }
    }
    private var scale: CGFloat {
        switch status {
        case .distracted: return 1.0
        case .onBreak:    return 1.02
        default:          return 1.03
        }
    }
    private var yOffset: CGFloat {
        return status == .distracted ? 0 : -2
    }
    private var xOffset: CGFloat {
        return status == .distracted ? 1.5 : 0   // restless side-to-side
    }
    private var tilt: Double {
        return status == .onBreak ? 2.5 : 0       // relaxed sway
    }
}

#Preview("Sprite avatars (fallback)") {
    HStack(spacing: 16) {
        SpriteAvatarView(character: CharacterCatalog.character(id: "maya"), status: .focused, size: 80, showStatusBadge: true)
        SpriteAvatarView(character: CharacterCatalog.character(id: "sam"), status: .distracted, size: 80, showStatusBadge: true)
    }
    .padding()
    .background(Theme.Colour.background)
}
