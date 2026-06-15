import SwiftUI

// MARK: - IsometricRoomView (v2 — depth, lighting, ambient life)
//
// A cosy isometric study room drawn entirely in SwiftUI (Path + gradients + Canvas) — no
// external assets. Driven by a `PersonalRoom`: each slot (floor, wall, rug, desk, chair,
// lamp, shelf, plant, poster, window) renders the player's chosen variant.
//
// v2 elevates the look from flat shapes to a lit, layered scene:
//   • furniture has DEPTH (top + front faces) and casts soft floor SHADOWS;
//   • a warm LAMP GLOW, a WINDOW LIGHT-CAST on the floor, and an edge VIGNETTE
//     (ambient occlusion) give cosy directional lighting;
//   • DUST MOTES drift slowly through the light and the lamp gently flickers
//     (TimelineView-driven, paused under Reduce Motion);
//   • the window shows a day/night sky for its variant.
//
// The default `.seeded` room reproduces the original layout, so parameterless callers
// (`IsometricRoomView()`) keep working. Avatar desk slot for callers: (width*0.50, height*0.58).

struct IsometricRoomView: View {
    var room: PersonalRoom = .seeded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let floor = room.item(for: .floor)
        let wall  = room.item(for: .wall)

        GeometryReader { geo in
            ZStack {
                // Interior shell — walls + floor + plank texture + window light cast.
                RoomShell(size: geo.size, floor: floor, wall: wall, room: room)
                // Furniture with depth + floor shadows.
                RoomFurnitureLayer(size: geo.size, room: room)
                // Cosy lighting + drifting dust (over furniture, under caller's avatars).
                RoomAmbientLayer(size: geo.size, room: room, reduceMotion: reduceMotion)
            }
        }
    }
}

// MARK: - Interior shell

private struct RoomShell: View {
    let size: CGSize
    let floor: RoomItem
    let wall: RoomItem
    let room: PersonalRoom

    var body: some View {
        let w = size.width, h = size.height
        ZStack {
            Theme.Colour.background

            // Right wall — shadow side.
            RightWallShape(size: size).fill(wall.tint.darkened(0.10))
            // Left wall — lit side (warm gradient toward the window).
            LeftWallShape(size: size).fill(LinearGradient(
                colors: [wall.tint.lightened(0.10), wall.tint.darkened(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            // Wall crease — soft ambient occlusion where the walls meet.
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
            }.stroke(Color.black.opacity(0.10), lineWidth: 2)

            // Floor.
            FloorShape(size: size).fill(LinearGradient(
                colors: [floor.tint.lightened(0.06), floor.tint.darkened(0.10)],
                startPoint: .top, endPoint: .bottom))
            FloorPlanks(size: size).stroke(floor.tint.darkened(0.16), lineWidth: 1)

            // Window light cast onto the floor (only meaningfully visible for bright skies).
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

/// Plank seams running along both isometric floor axes.
private struct FloorPlanks: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        let w = size.width, h = size.height
        var p = Path()
        let apex = CGPoint(x: w * 0.50, y: h * 0.65)
        let bottom = CGPoint(x: w * 0.50, y: h * 1.00)
        // Lines parallel to the left edge (apex→bottom-left) stepping toward the right.
        for t in stride(from: 0.22, through: 0.85, by: 0.18) {
            let lx = w * 0.50 * (1 - t)
            let ly = apex.y + (h * 0.88 - apex.y) * t
            let bx = w * 0.50 + (w * 0.50) * t
            let by = bottom.y - (bottom.y - h * 0.88) * t
            p.move(to: CGPoint(x: lx, y: ly)); p.addLine(to: CGPoint(x: bx, y: by))
        }
        // Lines parallel to the right edge.
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

/// A soft beam from the window onto the floor.
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

// MARK: - Furniture layer (depth + shadows, variant-driven)

private struct RoomFurnitureLayer: View {
    let size: CGSize
    let room: PersonalRoom

    var body: some View {
        let w = size.width, h = size.height
        ZStack {
            rug(w: w, h: h)
            window(w: w, h: h)
            poster(w: w, h: h)
            shelf(w: w, h: h)
            // Desk group (shadow → desk → chair behind avatar slot).
            floorShadow(cx: w * 0.46, cy: h * 0.72, rw: w * 0.30, rh: h * 0.05)
            chair(w: w, h: h)
            desk(w: w, h: h)
            lamp(w: w, h: h)
            plant(w: w, h: h)
        }
    }

    // MARK: shared helpers

    private func floorShadow(cx: CGFloat, cy: CGFloat, rw: CGFloat, rh: CGFloat) -> some View {
        Ellipse().fill(Color.black.opacity(0.16))
            .frame(width: rw, height: rh)
            .position(x: cx, y: cy)
            .blur(radius: 1.5)
    }

    /// A furniture block with a lit top face and a darker front face → pseudo-3D depth.
    private func block(tint: Color, w: CGFloat, h: CGFloat, topH: CGFloat,
                       frontH: CGFloat, cx: CGFloat, cy: CGFloat, radius: CGFloat = 4) -> some View {
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

    // MARK: rug

    @ViewBuilder private func rug(w: CGFloat, h: CGFloat) -> some View {
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

    // MARK: window (with day/night sky)

    private func window(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .window)
        let isNight = item.name == "Night"
        let isAurora = item.name == "Aurora"
        return ZStack {
            // Frame + sill.
            RoundedRectangle(cornerRadius: 5).fill(Theme.Colour.buttonFill.opacity(0.85))
                .frame(width: w * 0.16, height: h * 0.15)
            // Sky.
            RoundedRectangle(cornerRadius: 3).fill(LinearGradient(
                colors: [item.tint.lightened(isNight ? 0.0 : 0.15), item.tint.darkened(0.18)],
                startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.135, height: h * 0.125)
            // Celestial detail.
            if isNight {
                Circle().fill(Color(white: 0.96)).frame(width: w * 0.028, height: w * 0.028)
                    .offset(x: w * 0.03, y: -h * 0.025)
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(.white.opacity(0.85)).frame(width: 1.6, height: 1.6)
                        .offset(x: w * (0.04 - CGFloat(i) * 0.022), y: h * (0.02 + CGFloat(i % 2) * 0.018))
                }
            } else if isAurora {
                Capsule().fill(Theme.Colour.accentTeal.opacity(0.5)).frame(width: w * 0.12, height: 3)
                    .offset(y: -h * 0.01)
                Capsule().fill(Theme.Colour.accentLavender.opacity(0.5)).frame(width: w * 0.10, height: 3)
                    .offset(y: h * 0.005)
            } else {
                Circle().fill(Theme.Colour.accentSoft).frame(width: w * 0.03, height: w * 0.03)
                    .offset(x: -w * 0.025, y: -h * 0.02)
            }
            // Mullions.
            Rectangle().fill(Theme.Colour.buttonFill.opacity(0.85)).frame(width: w * 0.135, height: 2)
            Rectangle().fill(Theme.Colour.buttonFill.opacity(0.85)).frame(width: 2, height: h * 0.125)
        }
        .position(x: w * 0.28, y: h * 0.26)
    }

    // MARK: poster

    @ViewBuilder private func poster(w: CGFloat, h: CGFloat) -> some View {
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

    private func posterGlyph(_ v: Int) -> String {
        switch v { case 1: return "bolt.fill"; case 2: return "sparkles"; default: return "map.fill" }
    }

    // MARK: shelf (with depth + books)

    private func shelf(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .shelf)
        let spines = shelfPalette(item.variant)
        return ZStack {
            block(tint: Color(red: 0.45, green: 0.32, blue: 0.24),
                  w: w * 0.17, h: h, topH: h * 0.17, frontH: h * 0.02, cx: w * 0.20, cy: h * 0.44)
            // Two shelves of book spines.
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

    private func shelfPalette(_ v: Int) -> [Color] {
        switch v {
        case 1: return [Theme.Colour.accentTeal, Theme.Colour.accentLavender, Theme.Colour.accentTeal,
                        Theme.Colour.windowSlate, Theme.Colour.accentLavender]
        case 2: return [Theme.Colour.accentRose, Theme.Colour.accent, Theme.Colour.accentSoft,
                        Theme.Colour.accentRose, Theme.Colour.accent]
        default: return [Theme.Colour.accent, Theme.Colour.accentSoft, Theme.Colour.accentTeal,
                         Theme.Colour.accentRose, Theme.Colour.accentLavender]
        }
    }

    // MARK: desk

    private func desk(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .desk)
        return ZStack {
            // Legs.
            Rectangle().fill(item.tint.darkened(0.3)).frame(width: w * 0.02, height: h * 0.06)
                .position(x: w * 0.34, y: h * 0.74)
            Rectangle().fill(item.tint.darkened(0.3)).frame(width: w * 0.02, height: h * 0.06)
                .position(x: w * 0.58, y: h * 0.74)
            // Top surface with depth.
            block(tint: item.tint, w: w * 0.30, h: h, topH: h * 0.045, frontH: h * 0.035,
                  cx: w * 0.46, cy: h * 0.69, radius: 4)
            // A book + cup on the desk.
            RoundedRectangle(cornerRadius: 1).fill(Theme.Colour.accentRose)
                .frame(width: w * 0.05, height: h * 0.012).position(x: w * 0.40, y: h * 0.675)
            Circle().fill(Theme.Colour.surface).frame(width: w * 0.022, height: w * 0.022)
                .position(x: w * 0.54, y: h * 0.675)
        }
    }

    // MARK: chair

    @ViewBuilder private func chair(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .chair)
        if item.variant == 0 {
            Ellipse().fill(LinearGradient(colors: [item.tint.lightened(0.1), item.tint.darkened(0.15)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.09, height: h * 0.03).position(x: w * 0.50, y: h * 0.66)
        } else {
            let backH: CGFloat = item.variant == 2 ? h * 0.15 : h * 0.10
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(LinearGradient(
                    colors: [item.tint.lightened(0.12), item.tint.darkened(0.14)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.11, height: backH).position(x: w * 0.50, y: h * 0.55)
                Ellipse().fill(item.tint.darkened(0.05))
                    .frame(width: w * 0.10, height: h * 0.03).position(x: w * 0.50, y: h * 0.65)
            }
        }
    }

    // MARK: lamp (glow added in ambient layer)

    private func lamp(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Theme.Colour.textSecondary.darkened(0.1))
                .frame(width: w * 0.045, height: h * 0.012).position(x: w * 0.60, y: h * 0.665)  // base
            Rectangle().fill(Theme.Colour.textSecondary)
                .frame(width: 2, height: h * 0.07).position(x: w * 0.60, y: h * 0.62)            // stem
            // Shade.
            Path { p in
                p.move(to: CGPoint(x: w * 0.565, y: h * 0.585))
                p.addLine(to: CGPoint(x: w * 0.635, y: h * 0.585))
                p.addLine(to: CGPoint(x: w * 0.615, y: h * 0.555))
                p.addLine(to: CGPoint(x: w * 0.585, y: h * 0.555))
                p.closeSubpath()
            }.fill(LinearGradient(colors: [room.item(for: .lamp).tint.lightened(0.2),
                                           room.item(for: .lamp).tint.darkened(0.1)],
                                  startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: plant

    @ViewBuilder private func plant(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .plant)
        Group {
            switch item.variant {
            case 0:
                EmptyView()
            case 2:
                ZStack {
                    pot(w: w, h: h)
                    Capsule().fill(item.tint).frame(width: w * 0.03, height: h * 0.10)
                        .position(x: w * 0.80, y: h * 0.56)
                    Capsule().fill(item.tint.darkened(0.08)).frame(width: w * 0.016, height: h * 0.045)
                        .position(x: w * 0.825, y: h * 0.57)
                }
            case 3:
                ZStack {
                    pot(w: w, h: h)
                    Ellipse().fill(Theme.Colour.plantGreen).frame(width: w * 0.07, height: h * 0.08)
                        .rotationEffect(.degrees(-22)).position(x: w * 0.78, y: h * 0.55)
                    Circle().fill(item.tint).frame(width: w * 0.026, height: w * 0.026).position(x: w * 0.79, y: h * 0.52)
                    Circle().fill(item.tint.lightened(0.1)).frame(width: w * 0.022, height: w * 0.022).position(x: w * 0.825, y: h * 0.54)
                }
            default:
                ZStack {
                    pot(w: w, h: h)
                    Ellipse().fill(item.tint).frame(width: w * 0.07, height: h * 0.085)
                        .rotationEffect(.degrees(-28)).position(x: w * 0.775, y: h * 0.55)
                    Ellipse().fill(item.tint.darkened(0.08)).frame(width: w * 0.06, height: h * 0.07)
                        .rotationEffect(.degrees(26)).position(x: w * 0.83, y: h * 0.555)
                    Ellipse().fill(item.tint.lightened(0.08)).frame(width: w * 0.05, height: h * 0.09)
                        .position(x: w * 0.80, y: h * 0.535)
                }
            }
        }
    }

    private func pot(w: CGFloat, h: CGFloat) -> some View {
        block(tint: Color(red: 0.62, green: 0.44, blue: 0.34),
              w: w * 0.065, h: h, topH: h * 0.05, frontH: h * 0.015, cx: w * 0.80, cy: h * 0.60, radius: 3)
    }
}

// MARK: - Ambient lighting + dust (animated)

private struct RoomAmbientLayer: View {
    let size: CGSize
    let room: PersonalRoom
    let reduceMotion: Bool

    var body: some View {
        let w = size.width, h = size.height
        let lampTint = room.item(for: .lamp).tint

        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            let flicker = 0.5 + 0.5 * (0.85 + 0.15 * sin(t * 2.3))   // gentle lamp breathing

            ZStack {
                // Warm lamp glow (screen-blended).
                RadialGradient(colors: [lampTint.opacity(0.55 * flicker), .clear],
                               center: .center, startRadius: 1, endRadius: w * 0.26)
                    .frame(width: w * 0.5, height: w * 0.5)
                    .position(x: w * 0.60, y: h * 0.55)
                    .blendMode(.screen)

                // Window cool light pool.
                RadialGradient(colors: [room.item(for: .window).tint.opacity(0.20), .clear],
                               center: .center, startRadius: 1, endRadius: w * 0.18)
                    .frame(width: w * 0.4, height: w * 0.4)
                    .position(x: w * 0.28, y: h * 0.30)
                    .blendMode(.screen)

                // Dust motes drifting through the light.
                if !reduceMotion {
                    DustMotes(size: size, time: t)
                }

                // Edge vignette — ambient occlusion in the corners.
                RadialGradient(colors: [.clear, .clear, Color.black.opacity(0.28)],
                               center: .center, startRadius: w * 0.30, endRadius: w * 0.75)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

/// A handful of slow-drifting dust specks lit by the room.
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

private struct IsoDiamond: Shape {
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

#Preview("Customised room") {
    var room = PersonalRoom.seeded
    room.placements[RoomSlot.floor.rawValue]  = "floor.walnut"
    room.placements[RoomSlot.wall.rawValue]   = "wall.dusk"
    room.placements[RoomSlot.rug.rawValue]    = "rug.rose"
    room.placements[RoomSlot.chair.rawValue]  = "chair.gamer"
    room.placements[RoomSlot.lamp.rawValue]   = "lamp.amber"
    room.placements[RoomSlot.plant.rawValue]  = "plant.bloom"
    room.placements[RoomSlot.poster.rawValue] = "poster.galaxy"
    room.placements[RoomSlot.window.rawValue] = "window.night"
    return ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView(room: room).frame(height: 300).padding()
    }
}
