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
            // Layer 1: Base body (skin tone)
            AvatarBodyLayer(skinTone: appearance.skinTone, size: size)
            // Layer 2: Hair (style + colour)
            AvatarHairLayer(style: appearance.hairStyle, colour: appearance.hairColour, size: size)
            // Layer 3: Outfit (style + accent colour tint)
            AvatarOutfitLayer(style: appearance.outfitStyle, accentColour: appearance.accentColour, size: size)
            // Layer 4: Status badge — non-idle only; parent label carries the status for VoiceOver
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

// MARK: - Layer Sub-views (D-21a code-drawn)

// AvatarBodyLayer: head circle (upper ~45%) + body rounded-rect (lower ~30%)
private struct AvatarBodyLayer: View {
    let skinTone: SkinTone
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Head
            Circle()
                .fill(skinTone.colour)
                .frame(width: size * 0.45, height: size * 0.45)
            // Body / torso
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(skinTone.colour)
                .frame(width: size * 0.50, height: size * 0.30)
        }
        .frame(width: size, height: size, alignment: .bottom)
        .padding(.bottom, size * 0.02)
    }
}

// AvatarHairLayer: 4 visually-distinct styles placed above the head
private struct AvatarHairLayer: View {
    let style: HairStyle
    let colour: HairColour
    let size: CGFloat

    var body: some View {
        ZStack {
            switch style {
            case .short:
                // Short: flat cap shape across the top of the head
                Ellipse()
                    .fill(colour.colour)
                    .frame(width: size * 0.48, height: size * 0.22)
                    .offset(y: -size * 0.25)

            case .curly:
                // Curly: wider, taller puff with jagged outline approximated by overlapping circles
                ZStack {
                    Circle()
                        .fill(colour.colour)
                        .frame(width: size * 0.38, height: size * 0.28)
                        .offset(x: -size * 0.08, y: -size * 0.27)
                    Circle()
                        .fill(colour.colour)
                        .frame(width: size * 0.32, height: size * 0.26)
                        .offset(x: size * 0.08, y: -size * 0.27)
                    Circle()
                        .fill(colour.colour)
                        .frame(width: size * 0.28, height: size * 0.22)
                        .offset(x: 0, y: -size * 0.30)
                }

            case .long:
                // Long: wide cap + side panels hanging down
                ZStack {
                    Ellipse()
                        .fill(colour.colour)
                        .frame(width: size * 0.50, height: size * 0.24)
                        .offset(y: -size * 0.25)
                    // Left side panel
                    RoundedRectangle(cornerRadius: size * 0.04)
                        .fill(colour.colour)
                        .frame(width: size * 0.10, height: size * 0.35)
                        .offset(x: -size * 0.20, y: -size * 0.08)
                    // Right side panel
                    RoundedRectangle(cornerRadius: size * 0.04)
                        .fill(colour.colour)
                        .frame(width: size * 0.10, height: size * 0.35)
                        .offset(x: size * 0.20, y: -size * 0.08)
                }

            case .tied:
                // Tied: sleek cap + small bun/ponytail on top
                ZStack {
                    Ellipse()
                        .fill(colour.colour)
                        .frame(width: size * 0.48, height: size * 0.20)
                        .offset(y: -size * 0.24)
                    // Bun
                    Circle()
                        .fill(colour.colour)
                        .frame(width: size * 0.18, height: size * 0.18)
                        .offset(x: size * 0.14, y: -size * 0.34)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// AvatarOutfitLayer: 4 visually-distinct outfit styles tinted with accent colour
private struct AvatarOutfitLayer: View {
    let style: OutfitStyle
    let accentColour: AccentColour
    let size: CGFloat

    var body: some View {
        ZStack {
            switch style {
            case .casual:
                // Casual: simple solid tee — flat rounded rect
                RoundedRectangle(cornerRadius: size * 0.06)
                    .fill(accentColour.colour.opacity(0.85))
                    .frame(width: size * 0.50, height: size * 0.28)
                    .offset(y: size * 0.14)

            case .academic:
                // Academic: jacket with lapels — main rect + two small collar triangles
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.06)
                        .fill(accentColour.colour.opacity(0.80))
                        .frame(width: size * 0.52, height: size * 0.28)
                        .offset(y: size * 0.14)
                    // Left collar
                    Triangle()
                        .fill(Theme.Colour.surface)
                        .frame(width: size * 0.09, height: size * 0.12)
                        .offset(x: -size * 0.06, y: size * 0.09)
                    // Right collar
                    Triangle()
                        .fill(Theme.Colour.surface)
                        .frame(width: size * 0.09, height: size * 0.12)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .offset(x: size * 0.06, y: size * 0.09)
                }

            case .hoodie:
                // Hoodie: wide block with a small hood nub on top
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(accentColour.colour.opacity(0.75))
                        .frame(width: size * 0.56, height: size * 0.30)
                        .offset(y: size * 0.14)
                    // Hood nub
                    Capsule()
                        .fill(accentColour.colour.opacity(0.75))
                        .frame(width: size * 0.24, height: size * 0.10)
                        .offset(y: size * 0.00)
                }

            case .smart:
                // Smart: narrow fitted jacket with a small tie
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.05)
                        .fill(accentColour.colour.opacity(0.85))
                        .frame(width: size * 0.46, height: size * 0.28)
                        .offset(y: size * 0.14)
                    // Tie
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(Theme.Colour.accent.opacity(0.9))
                        .frame(width: size * 0.06, height: size * 0.14)
                        .offset(y: size * 0.11)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

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

// MARK: - Triangle Shape (academic jacket collar helper)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
