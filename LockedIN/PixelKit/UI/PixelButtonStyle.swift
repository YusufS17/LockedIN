import SwiftUI

// MARK: - PixelPanelShape — the stepped-corner rectangle behind all pixel chrome
//
// The game layer's answer to RoundedRectangle: corners step in two hard pixel
// increments instead of curving. One `unit` controls the chunkiness; buttons use
// ~4pt, small chips ~2pt. Shared by PixelButtonStyle, StepBadge, PixelSpeechBubble.

struct PixelPanelShape: Shape {
    /// Size of one corner step in points.
    var unit: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let u = min(unit, rect.width / 4, rect.height / 4)
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX + 2 * u, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w - 2 * u, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w - 2 * u, y: rect.minY + u))
        p.addLine(to: CGPoint(x: rect.minX + w - u, y: rect.minY + u))
        p.addLine(to: CGPoint(x: rect.minX + w - u, y: rect.minY + 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + w, y: rect.minY + 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + w, y: rect.minY + h - 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + w - u, y: rect.minY + h - 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + w - u, y: rect.minY + h - u))
        p.addLine(to: CGPoint(x: rect.minX + w - 2 * u, y: rect.minY + h - u))
        p.addLine(to: CGPoint(x: rect.minX + w - 2 * u, y: rect.minY + h))
        p.addLine(to: CGPoint(x: rect.minX + 2 * u, y: rect.minY + h))
        p.addLine(to: CGPoint(x: rect.minX + 2 * u, y: rect.minY + h - u))
        p.addLine(to: CGPoint(x: rect.minX + u, y: rect.minY + h - u))
        p.addLine(to: CGPoint(x: rect.minX + u, y: rect.minY + h - 2 * u))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h - 2 * u))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + u, y: rect.minY + 2 * u))
        p.addLine(to: CGPoint(x: rect.minX + u, y: rect.minY + u))
        p.addLine(to: CGPoint(x: rect.minX + 2 * u, y: rect.minY + u))
        p.closeSubpath()
        return p
    }
}

// MARK: - PixelButtonStyle — the chunky mockup CTA
//
// Gold (hero CTAs) or charcoal (secondary primary actions): stepped-corner panel,
// charcoal outline, a light top-highlight band, and a hard offset shadow the button
// visibly drops onto when pressed. Matches the "Let's go" / "CONTINUE" buttons in
// mockups 05/06.

struct PixelButtonStyle: ButtonStyle {

    enum Kind { case gold, charcoal }
    var kind: Kind = .gold
    /// Full-width by default (hero CTA); false hugs the label (compact chips).
    var fullWidth: Bool = true

    private var fill: Color { kind == .gold ? Theme.Colour.accent : Theme.Colour.buttonFill }
    private var highlight: Color {
        kind == .gold ? Theme.Colour.accentSoft : Theme.Colour.buttonFill.lightened(0.18)
    }
    private var textColour: Color { kind == .gold ? Theme.Colour.textOnAccent : Theme.Colour.buttonText }
    private static let dropDepth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(Theme.TypeScale.headline)
            .foregroundStyle(textColour)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background {
                ZStack {
                    PixelPanelShape().fill(fill)
                    // Top highlight band — hard edge, like a lit bevel.
                    GeometryReader { geo in
                        PixelPanelShape()
                            .fill(highlight)
                            .frame(height: 8)
                            .offset(y: 5)
                            .padding(.horizontal, 10)
                            .frame(width: geo.size.width, alignment: .center)
                    }
                    PixelPanelShape().stroke(Theme.Colour.appShell, lineWidth: 2)
                }
            }
            // Hard offset shadow the face drops onto when pressed.
            .background(
                PixelPanelShape()
                    .fill(Theme.Colour.appShell)
                    .offset(y: pressed ? 1 : Self.dropDepth)
            )
            .offset(y: pressed ? Self.dropDepth - 1 : 0)
            .animation(.linear(duration: 0.05), value: pressed)
    }
}

#Preview("Pixel buttons") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: 24) {
            Button("Let's go  →") {}.buttonStyle(PixelButtonStyle())
            Button("CONTINUE") {}.buttonStyle(PixelButtonStyle(kind: .charcoal))
            Button("NEXT") {}.buttonStyle(PixelButtonStyle(kind: .gold, fullWidth: false))
        }
        .padding(32)
    }
}
