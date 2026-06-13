import SwiftUI

// MARK: - IsometricRoomView (D-28, ONB-05)
//
// Reusable cozy isometric study room — drawn entirely in SwiftUI Path + gradients.
// No external assets. Stateless and parameterless in Phase 2.
//
// Phase 4 extension: add participant placement via overlay modifier or new param at that time.
// Do NOT add a `participants:` parameter here — Phase 4 adds it externally.
//
// Isometric geometry: 2:1 ratio (~26.6°). Walls rise from a centre-bottom floor rhombus.
// Back-to-front draw order: RightWallShape → LeftWallShape → FloorShape → RoomFurnitureLayer.
//
// Avatar desk slot (for callers): position AvatarView at (width * 0.50, height * 0.58).
// This places it centred at the desk surface in the isometric floor plane.

struct IsometricRoomView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Room background (behind all walls)
                Theme.Colour.background.ignoresSafeArea()

                // Right wall — shadow side (draw first, behind left wall)
                RightWallShape(size: geo.size)
                    .fill(Theme.Colour.surface)

                // Left wall — ambient light side (warm gradient from window upper-left)
                LeftWallShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [Theme.Colour.surfaceMid, Theme.Colour.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))

                // Floor — warm wood-plank feel
                FloorShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [Theme.Colour.background, Theme.Colour.surfaceMid],
                        startPoint: .top,
                        endPoint: .bottom))

                // Furniture layer (code-drawn — desk, bookshelf, lamp, plant, window)
                RoomFurnitureLayer(size: geo.size)
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
        // Four corners of the left wall parallelogram:
        // top-left of wall → apex (vanishing point) → bottom-centre (floor join) → bottom-left
        p.move(to:    CGPoint(x: 0,       y: h * 0.50))  // left wall bottom-left
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10)) // apex / top-centre
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65)) // floor centre join
        p.addLine(to: CGPoint(x: 0,        y: h * 0.88)) // bottom-left floor
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
        // Mirror of left wall on the right side:
        p.move(to:    CGPoint(x: w,        y: h * 0.50)) // right wall bottom-right
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.10)) // apex / top-centre
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65)) // floor centre join
        p.addLine(to: CGPoint(x: w,        y: h * 0.88)) // bottom-right floor
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
        // Diamond: left mid → top-centre → right mid → bottom-centre
        p.move(to:    CGPoint(x: 0,        y: h * 0.88))  // bottom-left
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))  // top-centre (wall/floor join)
        p.addLine(to: CGPoint(x: w,        y: h * 0.88))  // bottom-right
        p.addLine(to: CGPoint(x: w * 0.50, y: h * 1.00))  // bottom-centre
        p.closeSubpath()
        return p
    }
}

// MARK: - Furniture Layer

/// RoomFurnitureLayer: code-drawn cozy dark-academia room furniture.
/// All elements use Theme.Colour tokens only — no external assets.
private struct RoomFurnitureLayer: View {
    let size: CGSize

    var body: some View {
        let w = size.width
        let h = size.height

        ZStack {
            // Window (left wall, upper portion) — night window with glow
            roomWindow(w: w, h: h)

            // Bookshelf (left wall, lower-left) — surface body + accent book spines
            bookshelf(w: w, h: h)

            // Desk (centre-left of floor) — study desk surface
            desk(w: w, h: h)

            // Desk lamp (on desk, top) — accentSoft glow + textSecondary stand
            deskLamp(w: w, h: h)

            // Plant (right wall corner) — plantGreen leaves + surfaceMid pot
            plant(w: w, h: h)
        }
    }

    // MARK: Furniture Elements

    private func roomWindow(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Window frame — night slate panel
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colour.windowSlate)
                .frame(width: w * 0.14, height: h * 0.12)
                .offset(x: -w * 0.22, y: -h * 0.22)
            // Window glow — accentSoft shimmer at low opacity
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.Colour.accentSoft.opacity(0.15))
                .frame(width: w * 0.18, height: h * 0.15)
                .offset(x: -w * 0.22, y: -h * 0.22)
            // Window cross (frame dividers)
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

    private func bookshelf(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Shelf body
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.Colour.surface)
                .frame(width: w * 0.16, height: h * 0.16)
                .offset(x: -w * 0.20, y: h * 0.06)
            // Book spines — 5 coloured rectangles
            HStack(spacing: 2) {
                bookSpine(Theme.Colour.accent, w: w, h: h)
                bookSpine(Theme.Colour.accentSoft, w: w, h: h)
                bookSpine(Theme.Colour.accentTeal, w: w, h: h)
                bookSpine(Theme.Colour.accentRose, w: w, h: h)
                bookSpine(Theme.Colour.accentLavender, w: w, h: h)
            }
            .offset(x: -w * 0.20, y: h * 0.04)
        }
    }

    private func bookSpine(_ color: Color, w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: w * 0.018, height: h * 0.10)
    }

    private func desk(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Desk top surface
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.Colour.surfaceMid)
                .frame(width: w * 0.26, height: h * 0.05)
                .offset(x: -w * 0.04, y: h * 0.20)
            // Desk front face (isometric depth)
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colour.surface)
                .stroke(Theme.Colour.surface, lineWidth: 2)
                .frame(width: w * 0.26, height: h * 0.04)
                .offset(x: -w * 0.04, y: h * 0.24)
        }
    }

    private func deskLamp(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Lamp glow — accentSoft ambient light circle
            Circle()
                .fill(Theme.Colour.accentSoft.opacity(0.40))
                .frame(width: w * 0.10, height: w * 0.10)
                .offset(x: w * 0.08, y: h * 0.12)
            // Lamp stand
            Rectangle()
                .fill(Theme.Colour.textSecondary)
                .frame(width: 2, height: h * 0.06)
                .offset(x: w * 0.08, y: h * 0.17)
            // Lamp base
            Capsule()
                .fill(Theme.Colour.textSecondary)
                .frame(width: w * 0.04, height: h * 0.015)
                .offset(x: w * 0.08, y: h * 0.20)
        }
    }

    private func plant(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Pot (surfaceMid)
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.Colour.surfaceMid)
                .frame(width: w * 0.06, height: h * 0.05)
                .offset(x: w * 0.28, y: h * 0.18)
            // Left leaf (oval)
            Ellipse()
                .fill(Theme.Colour.plantGreen)
                .frame(width: w * 0.07, height: h * 0.08)
                .rotationEffect(.degrees(-30))
                .offset(x: w * 0.24, y: h * 0.10)
            // Right leaf (oval)
            Ellipse()
                .fill(Theme.Colour.plantGreen.opacity(0.85))
                .frame(width: w * 0.06, height: h * 0.07)
                .rotationEffect(.degrees(25))
                .offset(x: w * 0.31, y: h * 0.11)
            // Centre stem leaf
            Ellipse()
                .fill(Theme.Colour.plantGreen.opacity(0.95))
                .frame(width: w * 0.05, height: h * 0.09)
                .offset(x: w * 0.28, y: h * 0.10)
        }
    }
}

// MARK: - Previews

#Preview("Full-screen room — dark background") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView()
            .ignoresSafeArea()
    }
}

#Preview("Room with avatar at desk slot") {
    // Demonstrates the caller-composition pattern:
    // IsometricRoomView provides the room; caller positions AvatarView at (50%, 58%).
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        IsometricRoomView()
            .ignoresSafeArea()
        GeometryReader { geo in
            AvatarView(appearance: .default, status: .idle, size: 80)
                .position(
                    x: geo.size.width  * 0.50,
                    y: geo.size.height * 0.58
                )
        }
    }
}
