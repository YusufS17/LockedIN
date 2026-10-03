import SwiftUI

// MARK: - IsometricRoomView (v3 — baked pixel-art room)
//
// The single-occupant study room, rendered by `RoomComposer` as ONE cached pixel-art
// texture (shell + furniture + the occupant's chair/desk), scaled with nearest-
// neighbour so cells stay crisp at any size. Driven by a `PersonalRoom` (every slot's
// chosen item recolours its sprite) and the real clock (`DayPhase.current()`).
//
// Dynamic light stays live on top via `RoomAmbientLayer`: lamp glow, window light
// pool, drifting dust and a vignette — positioned through the canvas→view projection
// so they track the art wherever the letterboxed image lands.
//
// Public signature unchanged: `IsometricRoomView(room:)` / `IsometricRoomView()`.
// Avatar desk slot for callers remains ≈ (width*0.50, height*0.56).

struct IsometricRoomView: View {
    var room: PersonalRoom = .seeded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            ZStack {
                // Transparent outside the room silhouette so editor/home panels
                // supply their own surface without a mismatched rectangular patch.
                Image(uiImage: RoomComposer.baseImage(room: room,
                                                      phase: DayPhase.current(),
                                                      includeSeating: true))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: s.width, height: s.height)

                RoomAmbientLayer(
                    size: s, room: room, reduceMotion: reduceMotion,
                    lampAt: RoomCanvas.fraction(RoomCanvas.lampGlow(room: room), in: s),
                    windowAt: RoomCanvas.fraction(RoomCanvas.windowGlow, in: s)
                )
            }
        }
    }
}

// MARK: - RoomCanvas — shared canvas-anchor helpers for the ambient overlays

/// Where the dynamic light effects centre on the composed room art, in canvas
/// coordinates (see `RoomComposer.Anchor`), plus the canvas→fraction projection
/// `RoomAmbientLayer` consumes. Shared by this view and `LiveRoomScene`.
enum RoomCanvas {
    /// Shade centre follows the sprite variant, ground anchor and shared-room scale.
    static func lampGlow(room: PersonalRoom, sharedStudy: Bool = false) -> CGPoint {
        let scale: CGFloat = sharedStudy ? 0.8 : 1
        let ground = sharedStudy ? CGPoint(x: 27, y: 119) : CGPoint(x: 58, y: 132)
        let compact = room.item(for: .lamp).variant == 2
        return CGPoint(x: ground.x + (compact ? 0 : 5) * scale,
                       y: ground.y - (compact ? 22 : 38) * scale)
    }
    /// Centre of the sloped window pane (ground anchor 43,91).
    static let windowGlow = CGPoint(x: 43, y: 59)

    /// Canvas point → fractional view position for a `.scaledToFit` room image.
    static func fraction(_ canvas: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        let p = RoomLayout.project(canvas, in: size)
        return CGPoint(x: p.x / size.width, y: p.y / size.height)
    }
}

// MARK: - Ambient lighting + dust (animated)

struct RoomAmbientLayer: View {
    let size: CGSize
    let room: PersonalRoom
    let reduceMotion: Bool
    /// Centre of the warm lamp glow, in fractions.
    var lampAt: CGPoint = CGPoint(x: 0.60, y: 0.55)
    /// Centre of the window light pool, in fractions.
    var windowAt: CGPoint = CGPoint(x: 0.28, y: 0.30)

    var body: some View {
        let w = size.width, h = size.height
        // Effects scale with the fitted artwork, including tall/narrow containers.
        let roomWidth = RoomLayout.scale(in: size) * CGFloat(RoomSpriteShell.canvas.cols)
        let phase = DayPhase.current()
        let evening = phase == .evening || phase == .night
        // Catalogue lamp tint changes its wooden pole; the authored bulb stays amber.
        let lampTint = Color(red: 1, green: 0.79, blue: 0.39)
        let silhouette = RoomSpriteShell.image(floorTint: nil, wallTint: nil, phase: .day)

        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            let flicker = 0.85 + 0.15 * sin(t * 2.3)

            ZStack {
                RadialGradient(colors: [lampTint.opacity((evening ? 0.45 : 0.26) * flicker), .clear],
                               center: .center, startRadius: 0, endRadius: roomWidth * 0.25)
                    .frame(width: roomWidth * 0.5, height: roomWidth * 0.5)
                    .position(x: w * lampAt.x, y: h * lampAt.y)
                    .blendMode(.screen)

                RadialGradient(colors: [room.item(for: .window).tint.opacity(evening ? 0.12 : 0.20), .clear],
                               center: .center, startRadius: 0, endRadius: roomWidth * 0.18)
                    .frame(width: roomWidth * 0.4, height: roomWidth * 0.4)
                    .position(x: w * windowAt.x, y: h * windowAt.y)
                    .blendMode(.screen)

                if !reduceMotion { DustMotes(size: size, time: t) }

                RadialGradient(colors: [.clear, .clear, Color.black.opacity(evening ? 0.22 : 0.12)],
                               center: .center, startRadius: roomWidth * 0.30, endRadius: roomWidth * 0.75)
                    .blendMode(.multiply)
            }
            .frame(width: w, height: h)
            .allowsHitTesting(false)
        }
        // Match the shell's actual pixel silhouette and letterboxing. Keep the
        // cached image lookup outside the timeline's per-frame content updates.
        .mask {
            Image(uiImage: silhouette)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
        }
        .allowsHitTesting(false)
    }
}

private struct DustMotes: View {
    let size: CGSize
    let time: TimeInterval

    var body: some View {
        Canvas { ctx, _ in
            let w = size.width, h = size.height
            for i in 0..<10 {
                let fi = Double(i)
                let phase = time * 0.06 + fi * 0.7
                let x = (0.18 + 0.5 * (0.5 + 0.5 * sin(phase * 1.3 + fi))) * w
                let y = (0.30 + 0.45 * ((cos(phase) + 1) / 2)).truncatingRemainder(dividingBy: 0.9) * h + h * 0.18
                let r = 0.7 + 0.6 * (0.5 + 0.5 * sin(phase * 2))
                let op = 0.10 + 0.18 * (0.5 + 0.5 * sin(phase * 1.7 + fi))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(op)))
            }
        }
        .blendMode(.screen)
    }
}

// MARK: - Previews

#Preview("Default room") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView().frame(height: 300).padding()
    }
}
