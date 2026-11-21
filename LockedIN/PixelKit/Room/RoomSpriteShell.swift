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
            return [PixelRGBA(r: 24, g: 39, b: 65),
                    PixelRGBA(r: 42, g: 64, b: 91),
                    PixelRGBA(r: 122, g: 104, b: 111)]
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
                // Short grain runs follow each board's long axis. Contrast is
                // deliberately low, leaving faces and furniture easy to read.
                let grain = ((x - 2 * y + band * 11) % 64 + 64) % 64
                if ch != "l", kMod == 5 || kMod == 6, (18...33).contains(grain) {
                    g[x, y] = band % 3 == 0 ? "h" : "q"
                }
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
            // Timber cornice and recessed lower panelling share the wall's
            // projected slope instead of introducing front-facing decoration.
            g[x, top + 1] = "U"
            for y in (top + 2)...(top + 4) { g[x, y] = "T" }
            g[x, top + 5] = "R"
            for y in (edge - 18)..<(edge - 4) {
                g[x, y] = x < cx ? "P" : "p"
                if x % 24 == 0 || x % 24 == 1 { g[x, y] = "R" }
            }
            g[x, edge - 19] = "U"
            g[x, edge - 18] = "T"
            g[x, edge - 3] = "k"                  // skirting top line
            g[x, edge - 2] = "s"; g[x, edge - 1] = "s"
        }

        // Corner line: 1px hard edge down the wall join, stopping at skirting
        // so the skirting board runs continuous through the corner.
        let cornerEdge = floorY(atX: cx)
        for y in (cornerEdge - wallHeight)..<(cornerEdge - 3) {
            g[cx, y] = "t"
        }
        // The corner post and cutaway edges give the apartment structural depth.
        for x in [floorLeft.x, floorLeft.x + 1, cx - 1, cx + 1,
                  floorRight.x - 1, floorRight.x] {
            let edge = floorY(atX: x)
            for y in (edge - wallHeight + 1)..<(edge - 3) {
                g[x, y] = x == cx - 1 || x == floorLeft.x ? "U" : "T"
            }
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
        let woodBase = PixelRGBA(r: 137, g: 87, b: 55)
        let woodLight = PixelRGBA(r: 153, g: 102, b: 65)
        let woodDark = PixelRGBA(r: 78, g: 47, b: 32)
        let woodLine = PixelRGBA(r: 111, g: 68, b: 43)
        let afterDark = phase == .evening || phase == .night
        let wallLit = afterDark ? PixelRGBA(r: 49, g: 66, b: 70) : PixelRGBA(r: 229, g: 218, b: 196)
        let wallShade = afterDark ? PixelRGBA(r: 35, g: 46, b: 51) : PixelRGBA(r: 213, g: 201, b: 177)
        let skirt = PixelRGBA(r: 124, g: 78, b: 46)
        // Preserve named wallpaper choices under night lighting rather than
        // collapsing all purchased colours into the default petrol architecture.
        func wall(_ base: PixelRGBA) -> PixelRGBA {
            let colour = wallTint.map { DayPhase.mix(base, $0, afterDark ? 0.55 : 0.35) } ?? base
            return afterDark ? colour : phase.ambient(colour)
        }

        return PixelPalette([
            "f": tone(woodBase, floorTint),
            "g": tone(woodLight, floorTint),
            "d": tone(woodDark, floorTint),
            "l": tone(woodLine, floorTint),
            "h": tone(woodLight.lightened(0.04), floorTint),
            "q": tone(woodBase.darkened(0.07), floorTint),
            "w": wall(wallLit),
            "v": wall(wallShade),
            "c": wall(wallShade.darkened(0.12)),
            "t": PixelRGBA(r: 27, g: 29, b: 30),
            "P": wall(wallLit.darkened(0.18)),
            "p": wall(wallShade.darkened(0.18)),
            "T": phase.ambient(PixelRGBA(r: 104, g: 64, b: 40)),
            "U": phase.ambient(PixelRGBA(r: 163, g: 111, b: 65)),
            "R": PixelRGBA(r: 45, g: 33, b: 28),
            "s": phase.ambient(skirt),
            "k": phase.ambient(skirt.darkened(0.22)),
        ])
    }

    // MARK: Image

    @MainActor
    static func image(floorTint: Color?, wallTint: Color?, phase: DayPhase) -> UIImage {
        let f = floorTint.map(PixelRGBA.init)
        let w = wallTint.map(PixelRGBA.init)
        let key = "room-shell-apartment1|\(f?.keyFragment ?? "def")|\(w?.keyFragment ?? "def")|\(phase.rawValue)"
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
