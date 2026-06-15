import SwiftUI

// MARK: - IsometricRoomView (v2 — depth, lighting, ambient life)
//
// A cosy isometric study room drawn entirely in SwiftUI — no external assets. Driven by a
// `PersonalRoom`: each slot (floor, wall, rug, desk, chair, lamp, shelf, plant, poster,
// window) renders the player's chosen variant.
//
// The scene is composed from reusable pieces so the single-occupant room (this view) and
// the multi-desk squad room (`LiveRoomScene`) share one art vocabulary:
//   • `RoomShell`      — walls + floor + plank texture + window light cast
//   • `RoomDecor`      — every furniture piece (position-parameterised), with depth + shadows
//   • `RoomAmbientLayer` — lamp glow, window pool, vignette, drifting dust
//
// Default `.seeded` room reproduces the original layout, so parameterless callers
// (`IsometricRoomView()`) keep working. Avatar desk slot for callers: (width*0.50, height*0.58).

struct IsometricRoomView: View {
    var room: PersonalRoom = .seeded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            ZStack {
                RoomShell(size: s, room: room)

                // Back-wall decor.
                RoomDecor.window(size: s, room: room)
                RoomDecor.poster(size: s, room: room)
                RoomDecor.shelf(size: s, room: room)

                // Floor decor + a single central desk (the occupant sits here).
                RoomDecor.rug(size: s, room: room)
                RoomDecor.floorShadow(size: s, cx: 0.46, cy: 0.72, rw: 0.30, rh: 0.05)
                RoomDecor.chair(size: s, room: room, at: CGPoint(x: 0.50, y: 0.58))
                RoomDecor.desk(size: s, room: room, at: CGPoint(x: 0.46, y: 0.69), scale: 1)
                RoomDecor.lamp(size: s, room: room, at: CGPoint(x: 0.60, y: 0.62))
                RoomDecor.plant(size: s, room: room, at: CGPoint(x: 0.80, y: 0.58))

                RoomAmbientLayer(size: s, room: room, reduceMotion: reduceMotion)
            }
        }
    }
}

// MARK: - Interior shell

struct RoomShell: View {
    let size: CGSize
    let room: PersonalRoom

    var body: some View {
        let w = size.width, h = size.height
        let floor = room.item(for: .floor)
        let wall  = room.item(for: .wall)
        ZStack {
            Theme.Colour.background

            RightWallShape(size: size).fill(wall.tint.darkened(0.10))
            LeftWallShape(size: size).fill(LinearGradient(
                colors: [wall.tint.lightened(0.10), wall.tint.darkened(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
            }.stroke(Color.black.opacity(0.10), lineWidth: 2)

            FloorShape(size: size).fill(LinearGradient(
                colors: [floor.tint.lightened(0.06), floor.tint.darkened(0.10)],
                startPoint: .top, endPoint: .bottom))
            FloorPlanks(size: size).stroke(floor.tint.darkened(0.16), lineWidth: 1)

            WindowLightCast(size: size)
                .fill(LinearGradient(colors: [room.item(for: .window).tint.opacity(0.16), .clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
}

// MARK: - Room shapes (2:1 isometric)

private struct LeftWallShape: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: 0,        y: h * 0.50))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: 0,        y: h * 0.88))
        p.closeSubpath()
        return p
    }
}

private struct RightWallShape: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: w,        y: h * 0.50))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: w,        y: h * 0.88))
        p.closeSubpath()
        return p
    }
}

private struct FloorShape: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: 0,        y: h * 0.88))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: w,        y: h * 0.88))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 1.00))
        p.closeSubpath()
        return p
    }
}

private struct FloorPlanks: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        let apex = CGPoint(x: w * 0.50, y: h * 0.65)
        let bottom = CGPoint(x: w * 0.50, y: h * 1.00)
        for t in stride(from: 0.22, through: 0.85, by: 0.18) {
            let lx = w * 0.50 * (1 - t)
            let ly = apex.y + (h * 0.88 - apex.y) * t
            let bx = w * 0.50 + (w * 0.50) * t
            let by = bottom.y - (bottom.y - h * 0.88) * t
            p.move(to: CGPoint(x: lx, y: ly)); p.addLine(to: CGPoint(x: bx, y: by))
        }
        for t in stride(from: 0.22, through: 0.85, by: 0.18) {
            let rx = w - w * 0.50 * (1 - t)
            let ry = apex.y + (h * 0.88 - apex.y) * t
            let bx = w * 0.50 - (w * 0.50) * t
            let by = bottom.y - (bottom.y - h * 0.88) * t
            p.move(to: CGPoint(x: rx, y: ry)); p.addLine(to: CGPoint(x: bx, y: by))
        }
        return p
    }
}

private struct WindowLightCast: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: w * 0.06, y: h * 0.62))
        p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.58))
        p.addLine(to: CGPoint(x: w * 0.52, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.92))
        p.closeSubpath()
        return p
    }
}

// MARK: - RoomDecor — reusable, position-parameterised furniture (depth + shadows)

enum RoomDecor {

    // MARK: shared primitives

    static func floorShadow(size: CGSize, cx: CGFloat, cy: CGFloat, rw: CGFloat, rh: CGFloat) -> some View {
        Ellipse().fill(Color.black.opacity(0.16))
            .frame(width: size.width * rw, height: size.height * rh)
            .position(x: size.width * cx, y: size.height * cy)
            .blur(radius: 1.5)
    }

    /// A block with a lit top face + darker front face → pseudo-3D depth.
    static func block(tint: Color, w: CGFloat, topH: CGFloat, frontH: CGFloat,
                      cx: CGFloat, cy: CGFloat, radius: CGFloat = 4) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius).fill(tint.darkened(0.22))
                .frame(width: w, height: frontH)
                .position(x: cx, y: cy + topH / 2 + frontH / 2 - 1)
            RoundedRectangle(cornerRadius: radius).fill(LinearGradient(
                colors: [tint.lightened(0.12), tint.darkened(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: w, height: topH)
                .position(x: cx, y: cy)
        }
    }

    // MARK: rug (centre)

    @ViewBuilder static func rug(size: CGSize, room: PersonalRoom) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .rug)
        if item.variant == 0 {
            EmptyView()
        } else if item.variant == 2 {
            Ellipse().fill(item.tint.opacity(0.34))
                .overlay(Ellipse().strokeBorder(item.tint.opacity(0.6), lineWidth: 2))
                .overlay(Ellipse().strokeBorder(item.tint.lightened(0.3).opacity(0.5), lineWidth: 1).padding(5))
                .frame(width: w * 0.40, height: h * 0.16)
                .position(x: w * 0.48, y: h * 0.78)
        } else {
            IsoDiamond().fill(item.tint.opacity(0.30))
                .overlay(IsoDiamond().stroke(item.tint.opacity(0.55), lineWidth: 2))
                .overlay(IsoDiamond().stroke(item.tint.lightened(0.3).opacity(0.5), lineWidth: 1).padding(6))
                .frame(width: w * 0.46, height: h * 0.20)
                .position(x: w * 0.48, y: h * 0.78)
        }
    }

    // MARK: window (back wall, day/night sky)

    static func window(size: CGSize, room: PersonalRoom) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .window)
        let isNight = item.name == "Night"
        let isAurora = item.name == "Aurora"
        return ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Theme.Colour.buttonFill.opacity(0.85))
                .frame(width: w * 0.16, height: h * 0.15)
            RoundedRectangle(cornerRadius: 3).fill(LinearGradient(
                colors: [item.tint.lightened(isNight ? 0.0 : 0.15), item.tint.darkened(0.18)],
                startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.135, height: h * 0.125)
            if isNight {
                Circle().fill(Color(white: 0.96)).frame(width: w * 0.028, height: w * 0.028)
                    .offset(x: w * 0.03, y: -h * 0.025)
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(.white.opacity(0.85)).frame(width: 1.6, height: 1.6)
                        .offset(x: w * (0.04 - CGFloat(i) * 0.022), y: h * (0.02 + CGFloat(i % 2) * 0.018))
                }
            } else if isAurora {
                Capsule().fill(Theme.Colour.accentTeal.opacity(0.5)).frame(width: w * 0.12, height: 3).offset(y: -h * 0.01)
                Capsule().fill(Theme.Colour.accentLavender.opacity(0.5)).frame(width: w * 0.10, height: 3).offset(y: h * 0.005)
            } else {
                Circle().fill(Theme.Colour.accentSoft).frame(width: w * 0.03, height: w * 0.03)
                    .offset(x: -w * 0.025, y: -h * 0.02)
            }
            Rectangle().fill(Theme.Colour.buttonFill.opacity(0.85)).frame(width: w * 0.135, height: 2)
            Rectangle().fill(Theme.Colour.buttonFill.opacity(0.85)).frame(width: 2, height: h * 0.125)
        }
        .position(x: w * 0.28, y: h * 0.26)
    }

    // MARK: poster (back wall)

    @ViewBuilder static func poster(size: CGSize, room: PersonalRoom) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .poster)
        if item.variant == 0 {
            EmptyView()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(LinearGradient(
                    colors: [item.tint.lightened(0.1), item.tint.darkened(0.12)],
                    startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.11, height: h * 0.13)
                RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.Colour.surface, lineWidth: 1.5)
                    .frame(width: w * 0.11, height: h * 0.13)
                Image(systemName: posterGlyph(item.variant))
                    .font(.system(size: w * 0.04, weight: .bold))
                    .foregroundStyle(Theme.Colour.surface.opacity(0.92))
            }
            .position(x: w * 0.71, y: h * 0.24)
        }
    }

    private static func posterGlyph(_ v: Int) -> String {
        switch v { case 1: return "bolt.fill"; case 2: return "sparkles"; default: return "map.fill" }
    }

    // MARK: shelf (left wall)

    static func shelf(size: CGSize, room: PersonalRoom) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .shelf)
        let spines = shelfPalette(item.variant)
        return ZStack {
            block(tint: Color(red: 0.45, green: 0.32, blue: 0.24),
                  w: w * 0.17, topH: h * 0.17, frontH: h * 0.02, cx: w * 0.20, cy: h * 0.44)
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 1.5) {
                    ForEach(Array(spines.enumerated()), id: \.offset) { _, c in
                        RoundedRectangle(cornerRadius: 1).fill(LinearGradient(
                            colors: [c.lightened(0.12), c.darkened(0.12)], startPoint: .top, endPoint: .bottom))
                            .frame(width: w * 0.018, height: h * 0.06)
                    }
                }
                .position(x: w * 0.20, y: h * (0.40 + Double(row) * 0.075))
            }
        }
    }

    private static func shelfPalette(_ v: Int) -> [Color] {
        switch v {
        case 1: return [Theme.Colour.accentTeal, Theme.Colour.accentLavender, Theme.Colour.accentTeal,
                        Theme.Colour.windowSlate, Theme.Colour.accentLavender]
        case 2: return [Theme.Colour.accentRose, Theme.Colour.accent, Theme.Colour.accentSoft,
                        Theme.Colour.accentRose, Theme.Colour.accent]
        default: return [Theme.Colour.accent, Theme.Colour.accentSoft, Theme.Colour.accentTeal,
                         Theme.Colour.accentRose, Theme.Colour.accentLavender]
        }
    }

    // MARK: desk (position-parameterised)

    static func desk(size: CGSize, room: PersonalRoom, at p: CGPoint, scale: CGFloat) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .desk)
        let cx = w * p.x, cy = h * p.y
        let dw = w * 0.30 * scale
        return ZStack {
            Rectangle().fill(item.tint.darkened(0.3)).frame(width: w * 0.02 * scale, height: h * 0.06 * scale)
                .position(x: cx - dw * 0.4, y: cy + h * 0.05 * scale)
            Rectangle().fill(item.tint.darkened(0.3)).frame(width: w * 0.02 * scale, height: h * 0.06 * scale)
                .position(x: cx + dw * 0.4, y: cy + h * 0.05 * scale)
            block(tint: item.tint, w: dw, topH: h * 0.045 * scale, frontH: h * 0.035 * scale, cx: cx, cy: cy, radius: 4)
            RoundedRectangle(cornerRadius: 1).fill(Theme.Colour.accentRose)
                .frame(width: w * 0.05 * scale, height: h * 0.012 * scale).position(x: cx - dw * 0.2, y: cy - h * 0.008)
            Circle().fill(Theme.Colour.surface).frame(width: w * 0.022 * scale, height: w * 0.022 * scale)
                .position(x: cx + dw * 0.26, y: cy - h * 0.008)
        }
    }

    // MARK: chair (position-parameterised)

    @ViewBuilder static func chair(size: CGSize, room: PersonalRoom, at p: CGPoint, scale: CGFloat = 1) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .chair)
        let cx = w * p.x, cy = h * p.y
        if item.variant == 0 {
            Ellipse().fill(LinearGradient(colors: [item.tint.lightened(0.1), item.tint.darkened(0.15)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.09 * scale, height: h * 0.03 * scale).position(x: cx, y: cy + h * 0.08 * scale)
        } else {
            let backH: CGFloat = (item.variant == 2 ? h * 0.15 : h * 0.10) * scale
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(LinearGradient(
                    colors: [item.tint.lightened(0.12), item.tint.darkened(0.14)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.11 * scale, height: backH).position(x: cx, y: cy - h * 0.03 * scale)
                Ellipse().fill(item.tint.darkened(0.05))
                    .frame(width: w * 0.10 * scale, height: h * 0.03 * scale).position(x: cx, y: cy + h * 0.07 * scale)
            }
        }
    }

    // MARK: lamp (position-parameterised; glow lives in RoomAmbientLayer)

    static func lamp(size: CGSize, room: PersonalRoom, at p: CGPoint) -> some View {
        let w = size.width, h = size.height
        let cx = w * p.x, cy = h * p.y
        let tint = room.item(for: .lamp).tint
        return ZStack {
            Capsule().fill(Theme.Colour.textSecondary.darkened(0.1))
                .frame(width: w * 0.045, height: h * 0.012).position(x: cx, y: cy + h * 0.045)
            Rectangle().fill(Theme.Colour.textSecondary)
                .frame(width: 2, height: h * 0.07).position(x: cx, y: cy)
            Path { pa in
                pa.move(to: CGPoint(x: cx - w * 0.035, y: cy - h * 0.035))
                pa.addLine(to: CGPoint(x: cx + w * 0.035, y: cy - h * 0.035))
                pa.addLine(to: CGPoint(x: cx + w * 0.015, y: cy - h * 0.065))
                pa.addLine(to: CGPoint(x: cx - w * 0.015, y: cy - h * 0.065))
                pa.closeSubpath()
            }.fill(LinearGradient(colors: [tint.lightened(0.2), tint.darkened(0.1)], startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: plant (position-parameterised)

    @ViewBuilder static func plant(size: CGSize, room: PersonalRoom, at p: CGPoint) -> some View {
        let w = size.width, h = size.height
        let item = room.item(for: .plant)
        let cx = p.x, cy = p.y   // fractions
        Group {
            switch item.variant {
            case 0:
                EmptyView()
            case 2:
                ZStack {
                    pot(size: size, cx: cx, cy: cy)
                    Capsule().fill(item.tint).frame(width: w * 0.03, height: h * 0.10).position(x: w * cx, y: h * (cy - 0.04))
                    Capsule().fill(item.tint.darkened(0.08)).frame(width: w * 0.016, height: h * 0.045).position(x: w * (cx + 0.025), y: h * (cy - 0.03))
                }
            case 3:
                ZStack {
                    pot(size: size, cx: cx, cy: cy)
                    Ellipse().fill(Theme.Colour.plantGreen).frame(width: w * 0.07, height: h * 0.08).rotationEffect(.degrees(-22)).position(x: w * (cx - 0.02), y: h * (cy - 0.05))
                    Circle().fill(item.tint).frame(width: w * 0.026, height: w * 0.026).position(x: w * (cx - 0.01), y: h * (cy - 0.08))
                    Circle().fill(item.tint.lightened(0.1)).frame(width: w * 0.022, height: w * 0.022).position(x: w * (cx + 0.025), y: h * (cy - 0.06))
                }
            default:
                ZStack {
                    pot(size: size, cx: cx, cy: cy)
                    Ellipse().fill(item.tint).frame(width: w * 0.07, height: h * 0.085).rotationEffect(.degrees(-28)).position(x: w * (cx - 0.025), y: h * (cy - 0.05))
                    Ellipse().fill(item.tint.darkened(0.08)).frame(width: w * 0.06, height: h * 0.07).rotationEffect(.degrees(26)).position(x: w * (cx + 0.03), y: h * (cy - 0.045))
                    Ellipse().fill(item.tint.lightened(0.08)).frame(width: w * 0.05, height: h * 0.09).position(x: w * cx, y: h * (cy - 0.065))
                }
            }
        }
    }

    private static func pot(size: CGSize, cx: CGFloat, cy: CGFloat) -> some View {
        block(tint: Color(red: 0.62, green: 0.44, blue: 0.34),
              w: size.width * 0.065, topH: size.height * 0.05, frontH: size.height * 0.015,
              cx: size.width * cx, cy: size.height * cy, radius: 3)
    }
}

// MARK: - Ambient lighting + dust (animated)

struct RoomAmbientLayer: View {
    let size: CGSize
    let room: PersonalRoom
    let reduceMotion: Bool
    /// Centre of the warm lamp glow, in fractions.
    var lampAt: CGPoint = CGPoint(x: 0.60, y: 0.55)

    var body: some View {
        let w = size.width, h = size.height
        let lampTint = room.item(for: .lamp).tint

        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            let flicker = 0.85 + 0.15 * sin(t * 2.3)

            ZStack {
                RadialGradient(colors: [lampTint.opacity(0.55 * flicker), .clear],
                               center: .center, startRadius: 1, endRadius: w * 0.26)
                    .frame(width: w * 0.5, height: w * 0.5)
                    .position(x: w * lampAt.x, y: h * lampAt.y)
                    .blendMode(.screen)

                RadialGradient(colors: [room.item(for: .window).tint.opacity(0.20), .clear],
                               center: .center, startRadius: 1, endRadius: w * 0.18)
                    .frame(width: w * 0.4, height: w * 0.4)
                    .position(x: w * 0.28, y: h * 0.30)
                    .blendMode(.screen)

                if !reduceMotion { DustMotes(size: size, time: t) }

                RadialGradient(colors: [.clear, .clear, Color.black.opacity(0.28)],
                               center: .center, startRadius: w * 0.30, endRadius: w * 0.75)
                    .blendMode(.multiply)
            }
            .allowsHitTesting(false)
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

// MARK: - Iso diamond (rug)

struct IsoDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Previews

#Preview("Default room") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView().frame(height: 300).padding()
    }
}
