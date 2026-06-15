import SwiftUI

// MARK: - AvatarView (D-21a, D-22, D-23, ONB-02, ONB-03)
//
// The SINGLE reusable avatar renderer across home, onboarding, Phase 3 roster,
// Phase 4 session HUD, Phase 7 world. Stateless: given (appearance, status, size)
// it produces the visual. No internal mutable state.
//
// Layer order (ZStack bottom → top):
//   1. AvatarBodyLayer  (skin tone — head circle + body rounded-rect)
//   2. AvatarHairLayer  (hair style + colour — 4 visually-distinct options)
//   3. AvatarOutfitLayer (outfit + accent colour tint — 4 visually-distinct options)
//   4. AvatarStatusOverlay (visible only when status != .idle)
//
// D-21a DEFAULT: All layers are code-drawn SwiftUI shapes.
// D-21 UPGRADE:  Replace layer views with Image PNGs — this public API is unchanged.
//
// Sizes: 120 (creator preview), 80 (payoff/home default), 48 (Phase 3 roster), 40 (Phase 4 HUD)

struct AvatarView: View {
    let appearance: CharacterAppearance
    let status: AvatarStatus
    var size: CGFloat = 80

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Code-drawn pixel-art sprite (skin/hair/outfit/status from appearance).
            PixelAvatarView(appearance: appearance, status: status, size: size)
            // Status badge — non-idle only; parent label carries the status for VoiceOver
            if status != .idle {
                AvatarStatusOverlay(status: status, size: size)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")
    }
}

// MARK: - Status badge

// AvatarStatusOverlay: small badge with ring colour + SF Symbol icon (non-colour-only, ONB-03)
// Positioned at bottomTrailing via parent ZStack alignment; offset inward by xs.
private struct AvatarStatusOverlay: View {
    let status: AvatarStatus
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(status.ringColour.opacity(0.9))
                .frame(width: size * 0.28, height: size * 0.28)
            if let symbol = status.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
        }
        // Inset from the corner so it sits just inside the avatar frame
        .offset(x: Theme.Spacing.xs, y: Theme.Spacing.xs)
    }
}

// MARK: - Previews

#Preview("Default appearance — size 120") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        AvatarView(appearance: .default, status: .idle, size: 120)
    }
}

#Preview("All accent colour variants") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: Theme.Spacing.lg) {
            Text("Accent & Outfit Variations")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
            HStack(spacing: Theme.Spacing.lg) {
                // Amber / casual (default)
                VStack(spacing: Theme.Spacing.xs) {
                    AvatarView(appearance: .default, status: .idle, size: 80)
                    Text("Amber").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                // Teal / academic
                VStack(spacing: Theme.Spacing.xs) {
                    AvatarView(appearance: .maya, status: .idle, size: 80)
                    Text("Teal").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                // Lavender / hoodie
                VStack(spacing: Theme.Spacing.xs) {
                    AvatarView(appearance: .leo, status: .idle, size: 80)
                    Text("Lavender").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                // Rose / smart
                VStack(spacing: Theme.Spacing.xs) {
                    AvatarView(appearance: .sam, status: .idle, size: 80)
                    Text("Rose").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
            }
        }
        .padding()
    }
}

#Preview("All AvatarStatus cases") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: Theme.Spacing.md) {
            Text("Status Overlay System")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
            // Idle + active states — confirms icon+colour non-colour-only cues
            HStack(spacing: Theme.Spacing.md) {
                ForEach([AvatarStatus.idle, .focused, .deepFocus], id: \.rawValue) { s in
                    VStack(spacing: Theme.Spacing.xs) {
                        AvatarView(appearance: .default, status: s, size: 64)
                        Text(s.label)
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(Theme.Colour.textSecondary)
                    }
                }
            }
            HStack(spacing: Theme.Spacing.md) {
                ForEach([AvatarStatus.onBreak, .distracted, .finished], id: \.rawValue) { s in
                    VStack(spacing: Theme.Spacing.xs) {
                        AvatarView(appearance: .default, status: s, size: 64)
                        Text(s.label)
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(Theme.Colour.textSecondary)
                    }
                }
            }
        }
        .padding()
    }
}
