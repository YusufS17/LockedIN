import SwiftUI

// MARK: - DayPhase — real-clock time of day driving room lighting

/// Time-of-day bucket for room lighting. The shell applies a subtle warm/dark
/// ambient to walls and floor for evening/night; window pieces read `skyRamp`.
enum DayPhase: String, CaseIterable {
    case morning, day, evening, night

    /// Real clock: 5–10 morning, 10–17 day, 17–21 evening, else night.
    static func current(date: Date = .now) -> DayPhase {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<10: return .morning
        case 10..<17: return .day
        case 17..<21: return .evening
        default: return .night
        }
    }

    /// Window sky ramp, top → horizon (3 stops). Consumed by window furniture.
    var skyRamp: [PixelRGBA] {
        switch self {
        case .morning:
            return [PixelRGBA(r: 143, g: 195, b: 232),
                    PixelRGBA(r: 200, g: 224, b: 239),
                    PixelRGBA(r: 255, g: 224, b: 176)]
        case .day:
            return [PixelRGBA(r: 111, g: 177, b: 228),
                    PixelRGBA(r: 156, g: 205, b: 240),
                    PixelRGBA(r: 205, g: 231, b: 248)]
        case .evening:
            return [PixelRGBA(r: 122, g: 93, b: 158),
                    PixelRGBA(r: 201, g: 123, b: 110),
                    PixelRGBA(r: 255, g: 179, b: 107)]
        case .night:
            return [PixelRGBA(r: 27, g: 36, b: 64),
                    PixelRGBA(r: 42, g: 53, b: 96),
                    PixelRGBA(r: 74, g: 85, b: 131)]
        }
    }

    /// Ambient multiplier for wall/floor tones — identity by day, slightly
    /// warmer at evening, warmer + darker at night (lamp-lit feel).
    func ambient(_ c: PixelRGBA) -> PixelRGBA {
        let warm = PixelRGBA(r: 255, g: 158, b: 90)
        switch self {
        case .morning, .day:
            return c
        case .evening:
            return DayPhase.mix(c, warm, 0.10).darkened(0.03)
        case .night:
            return DayPhase.mix(c, warm, 0.06).darkened(0.16)
        }
    }

    /// Channel lerp preserving `a`'s alpha.
    static func mix(_ a: PixelRGBA, _ b: PixelRGBA, _ t: Double) -> PixelRGBA {
        let t = max(0, min(1, t))
        func lerp(_ x: UInt8, _ y: UInt8) -> UInt8 {
            UInt8(Double(x) + (Double(y) - Double(x)) * t)
        }
        return PixelRGBA(r: lerp(a.r, b.r), g: lerp(a.g, b.g), b: lerp(a.b, b.b), a: a.a)
    }
}

// MARK: - RoomSpriteShell — the empty isometric room

/// Baked empty room: floor diamond + two back walls, 2:1 pixel iso, canvas
/// 192×160 with the floor's bottom tip on the last row (ground anchor is
/// bottom-centre — no empty rows below the piece). Geometry is a single static
/// grid; tint and day-phase variation live entirely in the palette so the
/// bakery caches one grid bake per (floorTint, wallTint, phase) combination.
enum RoomSpriteShell {

    static let canvas = (cols: 192, rows: 160)

    /// Floor diamond corners — RoomComposer places furniture inside these.
    static let floorTop = (x: 96, y: 71)
    static let floorLeft = (x: 8, y: 115)
    static let floorRight = (x: 184, y: 115)
    static let floorBottom = (x: 96, y: 159)

    static let wallHeight = 64

    /// Topmost floor cell in column `x` (the wall/floor meeting line). Only
    /// meaningful for x in floorLeft.x...floorRight.x.
    static func floorY(atX x: Int) -> Int {
        floorTop.y + (abs(x - floorTop.x) + 1) / 2
    }

    // MARK: Grid

    // Materials: f/g plank tones, l seam, d soft seam + front rim,
    //            w lit wall, v shaded wall, c corner shade, t edge line,
    //            s skirting, k skirting top line.
    static let baseGrid: PixelGrid = buildGrid()

    private static func buildGrid() -> PixelGrid {
        var g = PixelGrid(cols: canvas.cols, rows: canvas.rows)
        let cx = floorTop.x

        // Floor diamond with plank texture. Planks run parallel to the
        // left-back edge: k = x + 2y is constant along that 2:1 diagonal.
        // Wider boards keep the floor quieter behind the small people. Seams
        // retain 2-cell runs per row for clean 2:1 lines; ends are staggered.
        for y in floorTop.y...floorBottom.y {
            let d = y <= floorLeft.y ? y - floorTop.y : floorBottom.y - y
            let half = 2 * d
            for x in (cx - half)...(cx + half) {
                let k = x + 2 * y
                let kMod = ((k % 12) + 12) % 12
                let band = k / 12
                var ch: Character = band % 2 == 0 ? "f" : "g"
                if kMod < 2 {
                    ch = "l"
                } else {
                    // Cross seams (plank ends) on the opposite diagonal,
                    // offset per band so ends never line up.
                    let m = x - 2 * y - (band * 17) % 48
                    if ((m % 48) + 48) % 48 < 2 { ch = "l" }
                }
                g[x, y] = ch
            }
        }

        // Front rim: outermost 2 cells of each lower-half row form a 1px-thick
        // 2:1 edge line along both front edges of the diamond.
        for y in (floorLeft.y + 1)...floorBottom.y {
            let half = 2 * (floorBottom.y - y)
            g[cx - half, y] = "d"; g[cx - half + 1, y] = "d"
            g[cx + half, y] = "d"; g[cx + half - 1, y] = "d"
        }

        // Back walls: rise wallHeight above the floor meeting line. Left wall
        // is the lit face (top-left light), right wall shaded, hard corner at
        // x = floorTop.x with a shade gradient bleeding onto the right wall.
        for x in floorLeft.x...floorRight.x {
            let edge = floorY(atX: x)
            let top = edge - wallHeight
            for y in top..<edge {
                var ch: Character = x < cx ? "w" : "v"
                if x > cx && x <= cx + 6 { ch = "c" }
                g[x, y] = ch
            }
            g[x, top] = "t"                       // hard wall-top edge line
            g[x, edge - 3] = "k"                  // skirting top line
            g[x, edge - 2] = "s"; g[x, edge - 1] = "s"
        }

        // Corner line: 1px hard edge down the wall join, stopping at skirting
        // so the skirting board runs continuous through the corner.
        let cornerEdge = floorY(atX: cx)
        for y in (cornerEdge - wallHeight)..<(cornerEdge - 3) {
            g[cx, y] = "t"
        }

        // Hand-stamped floor knots — sparse irregular detail the loops can't give.
        for (kx, ky) in [(58, 122), (59, 122), (128, 132), (129, 132), (92, 146), (150, 120)] {
            if g[kx, ky] == "f" || g[kx, ky] == "g" { g[kx, ky] = "d" }
        }

        return g
    }

    // MARK: Palette

    /// Wood + cream ramps, optionally pulled toward a tint (quantised — the
    /// ramp keeps its tone steps, hue mixes 35% toward the tint), then run
    /// through the phase ambient.
    static func palette(floorTint: PixelRGBA?, wallTint: PixelRGBA?, phase: DayPhase) -> PixelPalette {
        func tone(_ base: PixelRGBA, _ tint: PixelRGBA?) -> PixelRGBA {
            phase.ambient(tint.map { DayPhase.mix(base, $0, 0.35) } ?? base)
        }
        // Close face tones and softer joints make wood read as a surface, while
        // the dark outside rim still grounds the room's isometric silhouette.
        let woodBase = PixelRGBA(r: 151, g: 105, b: 72)
        let woodLight = PixelRGBA(r: 160, g: 115, b: 80)
        let woodDark = PixelRGBA(r: 110, g: 70, b: 41)
        let woodLine = PixelRGBA(r: 125, g: 84, b: 53)
        let wallLit = PixelRGBA(r: 239, g: 227, b: 204)    // #EFE3CC
        let wallShade = PixelRGBA(r: 228, g: 213, b: 184)  // #E4D5B8
        let skirt = PixelRGBA(r: 201, g: 161, b: 107)      // #C9A16B

        return PixelPalette([
            "f": tone(woodBase, floorTint),
            "g": tone(woodLight, floorTint),
            "d": tone(woodDark, floorTint),
            "l": tone(woodLine, floorTint),
            "w": tone(wallLit, wallTint),
            "v": tone(wallShade, wallTint),
            "c": tone(wallShade.darkened(0.07), wallTint),
            "t": tone(wallShade.darkened(0.18), wallTint),
            "s": tone(skirt, wallTint),
            "k": tone(skirt.darkened(0.22), wallTint),
        ])
    }

    // MARK: Image

    @MainActor
    static func image(floorTint: Color?, wallTint: Color?, phase: DayPhase) -> UIImage {
        let f = floorTint.map(PixelRGBA.init)
        let w = wallTint.map(PixelRGBA.init)
        let key = "room-shell-wideboards|\(f?.keyFragment ?? "def")|\(w?.keyFragment ?? "def")|\(phase.rawValue)"
        return SpriteBakery.shared.image(key: key) {
            PixelRenderer.bake(
                grid: baseGrid,
                palette: palette(floorTint: f, wallTint: w, phase: phase),
                rules: .flatIcon,
                outline: PixelRGBA(r: 59, g: 42, b: 33),
                margin: 1
            )
        }
    }
}
