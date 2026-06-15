import SwiftUI

// MARK: - IsometricRoomView (D-28, ONB-05) — now customisable (world-layer §11–12)
//
// Reusable cozy isometric study room — drawn entirely in SwiftUI Path + gradients.
// No external assets. Driven by a `PersonalRoom`: each slot (floor, wall, rug, desk,
// chair, lamp, shelf, plant, poster, window) renders the player's chosen variant.
// The default `.seeded` room reproduces the original look, so existing parameterless
// callers (`IsometricRoomView()`) are visually unchanged.
//
// Isometric geometry: 2:1 ratio (~26.6°). Walls rise from a centre-bottom floor rhombus.
// Back-to-front draw order: RightWallShape → LeftWallShape → FloorShape → RoomFurnitureLayer.
//
// Avatar desk slot (for callers): position AvatarView at (width * 0.50, height * 0.58).

struct IsometricRoomView: View {
    var room: PersonalRoom = .seeded

    var body: some View {
        // Resolve chosen items once per render.
        let floor  = room.item(for: .floor)
        let wall   = room.item(for: .wall)

        GeometryReader { geo in
            ZStack {
                // Room background (behind all walls)
                Theme.Colour.background.ignoresSafeArea()

                // Right wall — shadow side (draw first, behind left wall)
                RightWallShape(size: geo.size)
                    .fill(wall.tint.opacity(0.85))

                // Left wall — ambient light side (warm gradient from window upper-left)
                LeftWallShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [wall.tint, wall.tint.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))

                // Floor — warm wood-plank feel
                FloorShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [Theme.Colour.background, floor.tint],
                        startPoint: .top,
                        endPoint: .bottom))

                // Furniture layer (code-drawn — driven by the room's placements)
                RoomFurnitureLayer(size: geo.size, room: room)
            }
        }
    }
}

// MARK: - Room Shapes (Path-based parallelograms, 2:1 isometric ratio)

/// Left wall — ambient light side, rises upper-left.
private struct LeftWallShape: Shape {
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        let w = size.width
        let h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: 0,       y: h * 0.50))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: 0,        y: h * 0.88))
        p.closeSubpath()
        return p
    }
}

/// Right wall — shadow side, rises upper-right.
private struct RightWallShape: Shape {
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        let w = size.width
        let h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: w,        y: h * 0.50))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: w,        y: h * 0.88))
        p.closeSubpath()
        return p
    }
}

/// Floor — rhombus/diamond in lower 40% of the view.
private struct FloorShape: Shape {
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        let w = size.width
        let h = size.height
        var p = Path()
        p.move(to:    CGPoint(x: 0,        y: h * 0.88))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
        p.addLine(to: CGPoint(x: w,        y: h * 0.88))
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 1.00))
        p.closeSubpath()
        return p
    }
}

// MARK: - Furniture Layer
//
/// RoomFurnitureLayer: code-drawn cozy study furniture, each piece reading its slot's
/// chosen item from the room. All elements use Theme.Colour tokens + item tints.
private struct RoomFurnitureLayer: View {
    let size: CGSize
    let room: PersonalRoom

    var body: some View {
        let w = size.width
        let h = size.height

        ZStack {
            // Rug — under the desk, drawn first so furniture sits on top
            rug(w: w, h: h)

            // Window (left wall, upper portion)
            roomWindow(w: w, h: h)

            // Poster (right wall, upper portion)
            poster(w: w, h: h)

            // Bookshelf (left wall, lower-left)
            bookshelf(w: w, h: h)

            // Desk (centre-left of floor)
            desk(w: w, h: h)

            // Chair (behind/under the avatar at the desk)
            chair(w: w, h: h)

            // Desk lamp (on desk, top)
            deskLamp(w: w, h: h)

            // Plant (right wall corner)
            plant(w: w, h: h)
        }
    }

    // MARK: Rug

    @ViewBuilder
    private func rug(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .rug)
        if item.variant == 0 {
            EmptyView()   // "None"
        } else if item.variant == 2 {
            // Round rug
            Ellipse()
                .fill(item.tint.opacity(0.35))
                .frame(width: w * 0.40, height: h * 0.16)
                .overlay(Ellipse().strokeBorder(item.tint.opacity(0.6), lineWidth: 2))
                .offset(x: -w * 0.02, y: h * 0.27)
        } else {
            // Rectangular iso rug (diamond)
            IsoRugShape()
                .fill(item.tint.opacity(0.30))
                .overlay(IsoRugShape().stroke(item.tint.opacity(0.55), lineWidth: 2))
                .frame(width: w * 0.44, height: h * 0.18)
                .offset(x: -w * 0.02, y: h * 0.27)
        }
    }

    private func roomWindow(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .window)
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(item.tint)
                .frame(width: w * 0.14, height: h * 0.12)
                .offset(x: -w * 0.22, y: -h * 0.22)
            RoundedRectangle(cornerRadius: 6)
                .fill(item.tint.opacity(0.30))
                .frame(width: w * 0.18, height: h * 0.15)
                .offset(x: -w * 0.22, y: -h * 0.22)
            Rectangle()
                .fill(Theme.Colour.surfaceMid)
                .frame(width: w * 0.14, height: 1.5)
                .offset(x: -w * 0.22, y: -h * 0.22)
            Rectangle()
                .fill(Theme.Colour.surfaceMid)
                .frame(width: 1.5, height: h * 0.12)
                .offset(x: -w * 0.22, y: -h * 0.22)
        }
    }

    @ViewBuilder
    private func poster(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .poster)
        if item.variant == 0 {
            EmptyView()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(item.tint.opacity(0.85))
                    .frame(width: w * 0.11, height: h * 0.13)
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Theme.Colour.surface, lineWidth: 2)
                    .frame(width: w * 0.11, height: h * 0.13)
                // Simple motif glyph by variant
                Image(systemName: posterGlyph(item.variant))
                    .font(.system(size: w * 0.045, weight: .bold))
                    .foregroundStyle(Theme.Colour.surface.opacity(0.9))
            }
            .offset(x: w * 0.22, y: -h * 0.22)
        }
    }

    private func posterGlyph(_ variant: Int) -> String {
        switch variant {
        case 1:  return "bolt.fill"        // Focus
        case 2:  return "sparkles"         // Galaxy
        default: return "map.fill"         // Map
        }
    }

    private func bookshelf(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .shelf)
        let spines = shelfPalette(item.variant)
        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.Colour.surface)
                .frame(width: w * 0.16, height: h * 0.16)
                .offset(x: -w * 0.20, y: h * 0.06)
            HStack(spacing: 2) {
                ForEach(Array(spines.enumerated()), id: \.offset) { _, c in
                    bookSpine(c, w: w, h: h)
                }
            }
            .offset(x: -w * 0.20, y: h * 0.04)
        }
    }

    private func shelfPalette(_ variant: Int) -> [Color] {
        switch variant {
        case 1:  // Cool
            return [Theme.Colour.accentTeal, Theme.Colour.accentLavender, Theme.Colour.accentTeal,
                    Theme.Colour.windowSlate, Theme.Colour.accentLavender]
        case 2:  // Warm
            return [Theme.Colour.accentRose, Theme.Colour.accent, Theme.Colour.accentSoft,
                    Theme.Colour.accentRose, Theme.Colour.accent]
        default: // Classic
            return [Theme.Colour.accent, Theme.Colour.accentSoft, Theme.Colour.accentTeal,
                    Theme.Colour.accentRose, Theme.Colour.accentLavender]
        }
    }

    private func bookSpine(_ color: Color, w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: w * 0.018, height: h * 0.10)
    }

    private func desk(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .desk)
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(item.tint)
                .frame(width: w * 0.26, height: h * 0.05)
                .offset(x: -w * 0.04, y: h * 0.20)
            RoundedRectangle(cornerRadius: 2)
                .fill(item.tint.opacity(0.7))
                .frame(width: w * 0.26, height: h * 0.04)
                .offset(x: -w * 0.04, y: h * 0.24)
        }
    }

    @ViewBuilder
    private func chair(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .chair)
        if item.variant == 0 {
            // Stool — seat pad only
            Ellipse()
                .fill(item.tint)
                .frame(width: w * 0.09, height: h * 0.03)
                .offset(x: w * 0.02, y: h * 0.30)
        } else {
            // Chair with back (taller back for "gamer" variant)
            let backHeight: CGFloat = item.variant == 2 ? h * 0.14 : h * 0.10
            ZStack {
                // Backrest (rises behind the avatar)
                RoundedRectangle(cornerRadius: 4)
                    .fill(item.tint)
                    .frame(width: w * 0.10, height: backHeight)
                    .offset(x: w * 0.02, y: h * 0.20)
                // Seat
                Ellipse()
                    .fill(item.tint.opacity(0.9))
                    .frame(width: w * 0.10, height: h * 0.03)
                    .offset(x: w * 0.02, y: h * 0.30)
            }
        }
    }

    private func deskLamp(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .lamp)
        return ZStack {
            Circle()
                .fill(item.tint.opacity(0.40))
                .frame(width: w * 0.10, height: w * 0.10)
                .offset(x: w * 0.08, y: h * 0.12)
            Rectangle()
                .fill(Theme.Colour.textSecondary)
                .frame(width: 2, height: h * 0.06)
                .offset(x: w * 0.08, y: h * 0.17)
            Capsule()
                .fill(Theme.Colour.textSecondary)
                .frame(width: w * 0.04, height: h * 0.015)
                .offset(x: w * 0.08, y: h * 0.20)
        }
    }

    @ViewBuilder
    private func plant(w: CGFloat, h: CGFloat) -> some View {
        let item = room.item(for: .plant)
        switch item.variant {
        case 0:
            EmptyView()
        case 2:
            // Cactus — upright pads
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.Colour.surfaceMid)
                    .frame(width: w * 0.06, height: h * 0.05)
                    .offset(x: w * 0.28, y: h * 0.18)
                Capsule().fill(item.tint)
                    .frame(width: w * 0.03, height: h * 0.12)
                    .offset(x: w * 0.28, y: h * 0.10)
                Capsule().fill(item.tint.opacity(0.9))
                    .frame(width: w * 0.018, height: h * 0.05)
                    .offset(x: w * 0.31, y: h * 0.11)
            }
        case 3:
            // Bloom — green leaves + coloured flowers
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.Colour.surfaceMid)
                    .frame(width: w * 0.06, height: h * 0.05)
                    .offset(x: w * 0.28, y: h * 0.18)
                Ellipse().fill(Theme.Colour.plantGreen)
                    .frame(width: w * 0.07, height: h * 0.08)
                    .rotationEffect(.degrees(-25))
                    .offset(x: w * 0.25, y: h * 0.11)
                Circle().fill(item.tint)
                    .frame(width: w * 0.025, height: w * 0.025)
                    .offset(x: w * 0.27, y: h * 0.08)
                Circle().fill(item.tint.opacity(0.85))
                    .frame(width: w * 0.022, height: w * 0.022)
                    .offset(x: w * 0.31, y: h * 0.10)
            }
        default:
            // Fern — original three-leaf plant
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.Colour.surfaceMid)
                    .frame(width: w * 0.06, height: h * 0.05)
                    .offset(x: w * 0.28, y: h * 0.18)
                Ellipse().fill(item.tint)
                    .frame(width: w * 0.07, height: h * 0.08)
                    .rotationEffect(.degrees(-30))
                    .offset(x: w * 0.24, y: h * 0.10)
                Ellipse().fill(item.tint.opacity(0.85))
                    .frame(width: w * 0.06, height: h * 0.07)
                    .rotationEffect(.degrees(25))
                    .offset(x: w * 0.31, y: h * 0.11)
                Ellipse().fill(item.tint.opacity(0.95))
                    .frame(width: w * 0.05, height: h * 0.09)
                    .offset(x: w * 0.28, y: h * 0.10)
            }
        }
    }
}

// MARK: - Iso rug diamond

private struct IsoRugShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX,  y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX,  y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX,  y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX,  y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Previews

#Preview("Default room") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView().ignoresSafeArea()
    }
}

#Preview("Customised room") {
    var room = PersonalRoom.seeded
    room.placements[RoomSlot.floor.rawValue]  = "floor.slate"
    room.placements[RoomSlot.wall.rawValue]   = "wall.dusk"
    room.placements[RoomSlot.rug.rawValue]    = "rug.rose"
    room.placements[RoomSlot.chair.rawValue]  = "chair.gamer"
    room.placements[RoomSlot.lamp.rawValue]   = "lamp.lavender"
    room.placements[RoomSlot.plant.rawValue]  = "plant.bloom"
    room.placements[RoomSlot.poster.rawValue] = "poster.galaxy"
    return ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView(room: room).ignoresSafeArea()
    }
}
