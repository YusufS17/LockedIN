import SwiftUI

// MARK: - PixelDecor — authored decorative chrome for the game layer
//
// The small pixel furniture of the onboarding + shell screens: drifting parchment
// clouds, twinkling 4-point gold sparkles, page dots, the "N OF 6" step badge, and
// the speech bubble the live room reuses for status callouts. All motion is gated
// on Reduce Motion; sparkles and clouds are baked once like every PixelKit sprite.

// MARK: - PixelCloud

/// A soft two-tone parchment cloud, authored as a grid and baked once.
struct PixelCloud: View {
    var width: CGFloat = 64
    var opacity: Double = 1

    private static let art: [String] = [
        "........++++++..............",
        "......++++++++++....++++....",
        "....++++++++++++++++++++++..",
        "..++++++++++++++++++++++++++",
        "+++++++++++++++++++++++++++o",
        "++++++++++++++++++++++++++oo",
        ".+++++++++++++++++++++++oo..",
        "...++++++++++++++++++oo.....",
    ]

    var body: some View {
        Image(uiImage: SpriteBakery.shared.image(key: "px-cloud") {
            PixelRenderer.bake(
                grid: PixelGrid(rows: Self.art),
                palette: PixelPalette([
                    "+": PixelRGBA(Theme.Colour.surfaceMid),
                    "o": PixelRGBA(Theme.Colour.cardBorder),
                ]),
                rules: .flatIcon,
                outline: nil
            )
        })
        .interpolation(.none)
        .resizable()
        .scaledToFit()
        .frame(width: width)
        .opacity(opacity)
        .accessibilityHidden(true)
    }
}

// MARK: - PixelSparkle

/// A twinkling 4-point gold sparkle. `phase` staggers instances so a field of
/// sparkles never pulses in unison. Static at mid-brightness under Reduce Motion.
struct PixelSparkle: View {
    var size: CGFloat = 14
    var phase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            sparkleShape.opacity(0.65)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 8)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate * 1.7 + phase
                let pulse = 0.35 + 0.65 * (0.5 + 0.5 * sin(t))
                sparkleShape
                    .opacity(pulse)
                    .scaleEffect(0.7 + 0.3 * pulse)
            }
        }
    }

    private var sparkleShape: some View {
        SparkleCross()
            .fill(Theme.Colour.accent)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The hard-edged 4-point star: a plus of pixels tapering to points.
private struct SparkleCross: Shape {
    func path(in rect: CGRect) -> Path {
        let u = rect.width / 7
        var p = Path()
        // Vertical spike
        p.addRect(CGRect(x: 3 * u, y: 0, width: u, height: rect.height))
        // Horizontal spike
        p.addRect(CGRect(x: 0, y: 3 * u, width: rect.width, height: u))
        // Thicker centre
        p.addRect(CGRect(x: 2 * u, y: 2 * u, width: 3 * u, height: 3 * u))
        return p
    }
}

// MARK: - OnboardingBackdrop

/// Clouds in the top corners + a scattering of staggered sparkles — the shared
/// dressing behind the onboarding beats (mockups 05/06/03).
struct OnboardingBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                PixelCloud(width: 70, opacity: 0.8).position(x: w * 0.14, y: h * 0.10)
                PixelCloud(width: 52, opacity: 0.6).position(x: w * 0.88, y: h * 0.16)
                PixelCloud(width: 44, opacity: 0.5).position(x: w * 0.80, y: h * 0.55)
                PixelCloud(width: 56, opacity: 0.55).position(x: w * 0.10, y: h * 0.62)

                PixelSparkle(size: 13, phase: 0.0).position(x: w * 0.22, y: h * 0.20)
                PixelSparkle(size: 10, phase: 1.6).position(x: w * 0.80, y: h * 0.08)
                PixelSparkle(size: 15, phase: 3.1).position(x: w * 0.92, y: h * 0.34)
                PixelSparkle(size: 9,  phase: 4.4).position(x: w * 0.08, y: h * 0.38)
                PixelSparkle(size: 12, phase: 2.2).position(x: w * 0.16, y: h * 0.78)
                PixelSparkle(size: 10, phase: 5.3).position(x: w * 0.86, y: h * 0.72)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - PageDots

/// Shared onboarding progress dots — active dot is a larger gold square (pixel
/// language), inactive are small muted squares.
struct PageDots: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(i == active
                          ? Theme.Colour.accent
                          : Theme.Colour.textSecondary.opacity(0.35))
                    .frame(width: i == active ? 8 : 5,
                           height: i == active ? 8 : 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(active + 1) of \(count)")
    }
}

// MARK: - StepBadge

/// The "2 OF 6" chip pinned top-trailing during onboarding.
struct StepBadge: View {
    let current: Int   // 1-based
    let total: Int

    var body: some View {
        Text("\(current) OF \(total)")
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.textSecondary)
            .padding(.horizontal, Theme.Spacing.sm + 2)
            .padding(.vertical, 5)
            .background(PixelPanelShape(unit: 2).fill(Theme.Colour.surface))
            .overlay(PixelPanelShape(unit: 2).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
            .accessibilityLabel("Step \(current) of \(total)")
    }
}

// MARK: - PixelSpeechBubble

/// A stepped-corner speech bubble with a hard pixel tail — onboarding hints now,
/// live-room status callouts in Phase 4. Tail points down from the leading edge.
struct PixelSpeechBubble: View {
    let text: String
    var icon: PixelIcon? = nil
    var tint: Color = Theme.Colour.surface

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon {
                PixelIconView(icon: icon, size: 16)
            }
            Text(text)
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(PixelPanelShape(unit: 3).fill(tint))
        .overlay(PixelPanelShape(unit: 3).stroke(Theme.Colour.appShell, lineWidth: 2))
        .background(alignment: .bottomLeading) {
            BubbleTail()
                .fill(tint)
                .overlay(BubbleTail().stroke(Theme.Colour.appShell, lineWidth: 2))
                .frame(width: 14, height: 10)
                .offset(x: 18, y: 8)
        }
    }

    /// Two hard steps narrowing to a point.
    private struct BubbleTail: Shape {
        func path(in rect: CGRect) -> Path {
            let u = rect.height / 2
            var p = Path()
            p.move(to:    CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - u, y: rect.minY + u))
            p.addLine(to: CGPoint(x: rect.minX + u, y: rect.minY + u))
            p.addLine(to: CGPoint(x: rect.minX + u, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }
}

#Preview("Decor") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        OnboardingBackdrop()
        VStack(spacing: 28) {
            StepBadge(current: 2, total: 6)
            PixelSpeechBubble(text: "Visible to your study buddies", icon: .users)
            PageDots(count: 6, active: 1)
        }
    }
}
