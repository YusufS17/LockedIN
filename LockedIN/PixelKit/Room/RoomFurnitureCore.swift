import SwiftUI

// MARK: - RoomFurnitureCore — the seating furniture of the isometric room
//
// Desk, chair, sofa and side table, authored as flat-shaded string grids and
// baked once via SpriteBakery. These pieces layer AROUND the 48×64 avatar
// sprite at runtime. Keep their ground anchors consistent with RoomLayout.
//
// Shading is hand-authored (top-left light: top faces lightest, fronts mid,
// right edges dark, hard 1px edge lines) — rules are `.flatIcon` so the auto
// light shader never touches these tones. `tint` recolours only each piece's
// accent material; everything else keeps the warm wood/cream ramp.

/// Warm dark silhouette ring shared by every furniture bake.
private let furnitureOutline = PixelRGBA(r: 59, g: 42, b: 33)

/// Four-tone flat wood ramp: top faces, base, right/front shade, edge lines.
private struct WoodRamp {
    let top: PixelRGBA
    let base: PixelRGBA
    let shade: PixelRGBA
    let line: PixelRGBA

    static let standard = WoodRamp(top: PixelRGBA(r: 169, g: 120, b: 79),
                                   base: PixelRGBA(r: 139, g: 94, b: 60),
                                   shade: PixelRGBA(r: 110, g: 70, b: 41),
                                   line: PixelRGBA(r: 89, g: 55, b: 31))
    static let dark = WoodRamp(top: PixelRGBA(r: 139, g: 94, b: 60),
                               base: PixelRGBA(r: 110, g: 70, b: 41),
                               shade: PixelRGBA(r: 89, g: 55, b: 31),
                               line: PixelRGBA(r: 69, g: 40, b: 18))
    static let birch = WoodRamp(top: PixelRGBA(r: 220, g: 194, b: 155),
                                base: PixelRGBA(r: 196, g: 162, b: 114),
                                shade: PixelRGBA(r: 163, g: 130, b: 83),
                                line: PixelRGBA(r: 122, g: 90, b: 56))

    var entries: [Character: PixelRGBA] {
        ["W": top, "w": base, "d": shade, "l": line]
    }
}

// MARK: - RoomDeskSprite

/// Isometric desk with open laptop, notebook and coffee mug, 68×46.
/// Variants: standard, dark wood + books, birch + plant. Mug is tintable.
enum RoomDeskSprite {

    // A real 2:1 isometric tabletop, with vertical legs and distinct lit faces.
    // Keep the 68×46 footprint so saved placements and seating anchors remain valid.
    private static func baseGrid() -> PixelGrid {
        var g = PixelGrid(cols: 68, rows: 46)
        // Legs are drawn before the worktop. Their bottoms follow its depth.
        g.polygon([(20, 10), (24, 12), (24, 29), (20, 27)], "d")
        g.polygon([(57, 27), (61, 25), (61, 41), (57, 43)], "d")
        g.polygon([(7, 19), (11, 21), (11, 35), (7, 33)], "w")
        g.polygon([(41, 33), (45, 35), (45, 45), (41, 43)], "w")
        g.line(from: (7, 21), to: (7, 32), "l")
        g.line(from: (44, 35), to: (44, 44), "l")
        // Shallow apron leaves visible space under the desk rather than a solid box.
        g.polygon([(5, 18), (45, 38), (45, 33), (5, 13)], "w")
        g.polygon([(45, 33), (62, 25), (62, 30), (45, 38)], "d")
        // Long edge slopes down-right; depth edge slopes up-right.
        g.polygon([(5, 13), (22, 5), (62, 25), (45, 33)], "W")
        g.line(from: (5, 13), to: (45, 33), "l")
        g.line(from: (45, 33), to: (62, 25), "l")
        g.line(from: (5, 16), to: (45, 36), "d")
        g.line(from: (13, 12), to: (49, 30), "w")
        g.line(from: (20, 9), to: (56, 27), "w")
        // Laptop follows the same plane, with a raised screen and a keyboard deck.
        g.polygon([(29, 16), (40, 11), (53, 18), (42, 23)], "G")
        g.line(from: (32, 16), to: (43, 21), "g")
        g.line(from: (35, 14), to: (47, 20), "g")
        g.polygon([(39, 0), (54, 7), (53, 18), (39, 11)], "g")
        g.polygon([(41, 3), (52, 8), (51, 15), (41, 10)], "s")
        g.line(from: (43, 5), to: (49, 8), "S")
        g.line(from: (43, 7), to: (47, 9), "S")
        // Open notebook, cream pages with a warm central fold.
        g.polygon([(17, 13), (23, 10), (34, 16), (28, 19)], "x")
        g.line(from: (22, 11), to: (28, 17), "r")
        g.line(from: (18, 14), to: (22, 16), "G")
        g.line(from: (27, 14), to: (31, 16), "G")
        // Small mug on the front-right corner; tint remains the saved desk accent.
        g.polygon([(48, 23), (53, 23), (53, 28), (49, 29)], "m")
        g.line(from: (49, 24), to: (49, 27), "M")
        g.line(from: (49, 23), to: (52, 23), "b")
        g.line(from: (54, 24), to: (55, 24), "m")
        g.line(from: (55, 24), to: (55, 26), "m")
        g.line(from: (54, 27), to: (55, 26), "m")
        return g
    }

    // Variant 1: stacked books, stamped at (2, 5). 'x' = page edges.
    private static let books: [String] = [
        ".rrrrrrrrrrxx.",
        ".rrrrrrrrrrxx.",
        ".llllllllllll.",
        "qqqqqqqqqqqxx.",
        "qqqqqqqqqqqxx.",
        "lllllllllllll.",
        "ppppppppppppxx",
        "ppppppppppppxx",
        "ppppppppppppxx",
    ]

    // Variant 2: potted plant sprig, stamped at (55, 3).
    private static let plant: [String] = [
        "...eeee.....",
        "...Eeee.e...",
        "e.eeEeeEee.e",
        "e.eEeeeeee.e",
        "..EeeeeeEe..",
        "..eeeEeeee..",
        "..eeeeeeee..",
        ".TTTTTTTTTT.",
        "..tttttttt..",
        "..tttttttt..",
        "..tttttttt..",
        "..tttttttt..",
        "..tttttttt..",
    ]

    static func grid(variant: Int) -> PixelGrid {
        var g = baseGrid()
        switch max(0, min(2, variant)) {
        case 1: g.stamp(PixelGrid(rows: books), atX: 5, y: 2)
        case 2: g.stamp(PixelGrid(rows: plant), atX: 10, y: 0)
        default: break
        }
        return g
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let v = max(0, min(2, variant))
        let ramp: WoodRamp = v == 1 ? .dark : (v == 2 ? .birch : .standard)
        let mug = tint ?? PixelRGBA(r: 74, g: 124, b: 89)
        var entries = ramp.entries
        entries["g"] = PixelRGBA(r: 74, g: 68, b: 60)     // laptop shell
        entries["G"] = PixelRGBA(r: 107, g: 98, b: 87)    // laptop deck
        entries["s"] = PixelRGBA(r: 191, g: 217, b: 232)  // screen
        entries["S"] = PixelRGBA(r: 221, g: 237, b: 246)  // screen glow centre
        entries["m"] = mug                                // ACCENT: mug body
        entries["M"] = mug.lightened(0.25)
        entries["b"] = PixelRGBA(r: 74, g: 47, b: 28)     // coffee
        entries["p"] = PixelRGBA(r: 176, g: 88, b: 74)    // book spines
        entries["q"] = PixelRGBA(r: 74, g: 124, b: 89)
        entries["r"] = PixelRGBA(r: 217, g: 164, b: 65)
        entries["x"] = PixelRGBA(r: 239, g: 227, b: 204)  // page edges
        entries["t"] = PixelRGBA(r: 180, g: 113, b: 78)   // terracotta pot
        entries["T"] = PixelRGBA(r: 201, g: 138, b: 99)
        entries["e"] = PixelRGBA(r: 74, g: 124, b: 89)    // leaves
        entries["E"] = PixelRGBA(r: 99, g: 154, b: 111)
        return PixelPalette(entries)
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let v = max(0, min(2, variant))
        let pal = palette(variant: v, tint: tint.map { PixelRGBA($0) })
        return SpriteBakery.shared.image(key: "room-desk-iso2|v\(v)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            let g = mirrored ? grid(variant: v).mirrored() : grid(variant: v)
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: furnitureOutline, margin: 1)
        }
    }
}

// MARK: - RoomChairSprite

/// Chairs share the desk's 2:1 axes. The free stool stays backless;
/// upgrades add a wooden back and independently tintable upholstered panels.
enum RoomChairSprite {

    static func grid(variant: Int) -> PixelGrid {
        let v = max(0, min(2, variant))
        let lift = v == 0 ? 0 : 12
        var g = PixelGrid(cols: 28, rows: 26 + lift)
        // Four vertical legs are placed under the corners of the seat diamond.
        for (x, y) in [(3, 9), (12, 4), (23, 10), (15, 16)] {
            g.polygon([(x,y+lift),(x+2,y+lift+1),(x+2,y+lift+10),(x,y+lift+9)], "d")
            g.line(from: (x,y+lift+1), to: (x,y+lift+8), "w")
        }
        if v > 0 {
            // Upright back plane follows the long edge of the seat.
            g.polygon([(3,1),(6,0),(19,6),(16,8)], "W")
            g.polygon([(3,1),(16,8),(16,23),(3,16)], "w")
            g.polygon([(16,8),(19,6),(19,21),(16,23)], "d")
            for y in [6, 11] {
                g.line(from: (5,y), to: (14,y+4), "l")
            }
            if v == 2 {
                g.polygon([(5,4),(14,8),(14,18),(5,14)], "c")
                g.line(from: (6,5), to: (13,8), "C")
                g.line(from: (6,13), to: (13,16), "D")
            }
        }
        // Separate top, front and side faces; cushions preserve saved accent tints.
        g.polygon([(1,9+lift),(15,16+lift),(15,19+lift),(1,12+lift)], "w")
        g.polygon([(15,16+lift),(26,11+lift),(26,14+lift),(15,19+lift)], "d")
        g.polygon([(1,9+lift),(12,4+lift),(26,11+lift),(15,16+lift)], v == 0 ? "W" : "c")
        g.line(from: (2,9+lift), to: (15,15+lift), v == 0 ? "l" : "C")
        g.line(from: (15,16+lift), to: (25,11+lift), v == 0 ? "l" : "D")
        return g
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let pad = tint ?? PixelRGBA(r: 217, g: 164, b: 65)
        var entries = WoodRamp.standard.entries
        entries["c"] = pad                                // ACCENT: cushion
        entries["C"] = pad.lightened(0.25)
        entries["D"] = pad.darkened(0.25)
        return PixelPalette(entries)
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let v = max(0, min(2, variant))
        let pal = palette(variant: v, tint: tint.map { PixelRGBA($0) })
        return SpriteBakery.shared.image(key: "room-chair-iso4|v\(v)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            let g = mirrored ? grid(variant: v).mirrored() : grid(variant: v)
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: furnitureOutline, margin: 1)
        }
    }
}

// MARK: - RoomSofaSprite

/// Cozy two-seat cream sofa (solo-room mockup): rolled arms, two seat
/// cushions, two throw pillows — the pillows are the tintable accent. 76×64.
/// Single design; `variant` is accepted for API symmetry and ignored.
enum RoomSofaSprite {

    static func grid(variant: Int) -> PixelGrid {
        var g = PixelGrid(cols: 76, rows: 64)
        // Long axis runs up-right, parallel to the left wall. Depth runs down-right.
        for (x, y) in [(10, 47), (27, 56), (62, 38)] {
            g.polygon([(x,y),(x+4,y-2),(x+4,y+5),(x,y+7)], "d")
        }
        g.polygon([(8,30),(52,8),(56,10),(12,32)], "F")
        g.polygon([(12,32),(56,10),(56,33),(12,55)], "f")
        g.line(from: (14,34), to: (54,14), "n")
        // Two separate seat cushions on a horizontal plane.
        g.polygon([(13,43),(55,22),(67,28),(25,49)], "F")
        g.polygon([(25,49),(67,28),(67,39),(25,60)], "h")
        g.line(from: (26,51), to: (65,31), "n")
        g.line(from: (34,33), to: (46,39), "n")
        // Back cushions and their lower seams follow the wall slope.
        for x in [18, 38] {
            let y = 41 - x / 2
            g.polygon([(x,y),(x+14,y-7),(x+14,y+5),(x,y+12)], "c")
            g.line(from: (x+1,y+1), to: (x+12,y-5), "C")
            g.line(from: (x+1,y+11), to: (x+13,y+5), "D")
        }
        // Solid rolled arms: top, lit front and shaded end.
        for (x,y) in [(5,38),(55,13)] {
            g.polygon([(x,y),(x+5,y-3),(x+18,y+4),(x+13,y+7)], "F")
            g.polygon([(x,y),(x+13,y+7),(x+13,y+22),(x,y+15)], "f")
            g.polygon([(x+13,y+7),(x+18,y+4),(x+18,y+19),(x+13,y+22)], "h")
            g.line(from: (x+1,y+2), to: (x+11,y+7), "n")
        }
        return g
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let pillow = tint ?? PixelRGBA(r: 217, g: 164, b: 65)
        return PixelPalette([
            "f": PixelRGBA(r: 232, g: 222, b: 201),  // cream fabric
            "F": PixelRGBA(r: 244, g: 237, b: 221),  // fabric highlight
            "h": PixelRGBA(r: 205, g: 191, b: 163),  // fabric shade
            "n": PixelRGBA(r: 179, g: 163, b: 133),  // seams / creases
            "c": pillow,                             // ACCENT: throw pillows
            "C": pillow.lightened(0.25),
            "D": pillow.darkened(0.25),
            "w": WoodRamp.standard.base,             // feet
            "d": WoodRamp.standard.shade,
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let pal = palette(variant: 0, tint: tint.map { PixelRGBA($0) })
        return SpriteBakery.shared.image(key: "room-sofa-iso3|v0|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            let g = mirrored ? grid(variant: 0).mirrored() : grid(variant: 0)
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: furnitureOutline, margin: 1)
        }
    }
}

// MARK: - RoomSideTableSprite

/// Two-drawer cabinet with a projected front and separate top/side faces.
/// Handles remain tintable; variant 1 adds an upright lamp on its worktop.
enum RoomSideTableSprite {

    private static let body: [String] = [
        "..WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW..",
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        "llllllllllllllllllllllllllllllllllll",
        ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd.",
        ".wwllllllllllllllllllllllllllllwddd.",
        ".wwlwwwwwwwwwwwwwwwwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwKKKkwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwkkkkwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwwwwwwwwwwwwwwwwlwddd.",
        ".wwllllllllllllllllllllllllllllwddd.",
        ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd.",
        ".wwllllllllllllllllllllllllllllwddd.",
        ".wwlwwwwwwwwwwwwwwwwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwKKKkwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwkkkkwwwwwwwwwwwlwddd.",
        ".wwlwwwwwwwwwwwwwwwwwwwwwwwwwwlwddd.",
        ".wwllllllllllllllllllllllllllllwddd.",
        ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd.",
        ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwddd.",
        ".llllllllllllllllllllllllllllllllll.",
        "...wwwdd....................wwwdd...",
        "...wwwdd....................wwwdd...",
        "...wwwdd....................wwwdd...",
        "...wwwdd....................wwwdd...",
    ]

    // Variant 1: lamp overlay, stamped at (8, 0) above the body. Detached 'A'
    // cells are deliberate — floating warm-glow pixels around the shade.
    private static let lamp: [String] = [
        ".......aaaaaa.......",
        "......aaaaaaaa......",
        "..A..aaaaaaaaaa..A..",
        "....aaaaaaaaaaaa....",
        "....AAAAAAAAAAAA....",
        "A........ll........A",
        ".........ll.........",
        ".........ll.........",
        "..A...wwwwwwww...A..",
        "......wwwwwwww......",
    ]

    static func grid(variant: Int) -> PixelGrid {
        let cabinet = PixelGrid(rows: body).isometricFace(rising: false, depth: 8,
                                                          top: "W", side: "d")
        guard max(0, min(1, variant)) == 1 else { return cabinet }
        var g = PixelGrid(cols: cabinet.cols, rows: cabinet.rows + 8)
        g.stamp(cabinet, atX: 0, y: 8)
        g.stamp(PixelGrid(rows: lamp), atX: 13, y: 7)
        return g
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let handle = tint ?? PixelRGBA(r: 217, g: 164, b: 65)
        var entries = WoodRamp.standard.entries
        entries["k"] = handle                             // ACCENT: handles
        entries["K"] = handle.lightened(0.30)
        entries["a"] = PixelRGBA(r: 232, g: 168, b: 76)   // lamp shade
        entries["A"] = PixelRGBA(r: 255, g: 214, b: 130)  // warm glow
        return PixelPalette(entries)
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let v = max(0, min(1, variant))
        let pal = palette(variant: v, tint: tint.map { PixelRGBA($0) })
        return SpriteBakery.shared.image(key: "room-sidetable-iso3|v\(v)|\(pal.cacheKey)|m\(mirrored ? 1 : 0)") {
            let g = mirrored ? grid(variant: v).mirrored() : grid(variant: v)
            return PixelRenderer.bake(grid: g, palette: pal, rules: .flatIcon,
                                      outline: furnitureOutline, margin: 1)
        }
    }
}

// Integer raster helpers keep furniture edges crisp at the native pixel scale.
extension PixelGrid {
    mutating func line(from a: (Int, Int), to b: (Int, Int), _ material: Character) {
        var x = a.0, y = a.1
        let dx = abs(b.0 - x), dy = -abs(b.1 - y)
        let sx = x < b.0 ? 1 : -1, sy = y < b.1 ? 1 : -1
        var error = dx + dy
        while true {
            self[x, y] = material
            if x == b.0 && y == b.1 { break }
            let twice = 2 * error
            if twice >= dy { error += dy; x += sx }
            if twice <= dx { error += dx; y += sy }
        }
    }

    mutating func polygon(_ points: [(Int, Int)], _ material: Character) {
        guard points.count >= 3 else { return }
        let minY = points.map { $0.1 }.min()!, maxY = points.map { $0.1 }.max()!
        for y in minY...maxY {
            var crossings: [Double] = []
            let scan = Double(y) + 0.5
            for i in points.indices {
                let a = points[i], b = points[(i + 1) % points.count]
                if (Double(a.1) <= scan && Double(b.1) > scan) || (Double(b.1) <= scan && Double(a.1) > scan) {
                    crossings.append(Double(a.0) + (scan - Double(a.1)) * Double(b.0 - a.0) / Double(b.1 - a.1))
                }
            }
            crossings.sort()
            for i in stride(from: 0, to: crossings.count - 1, by: 2) {
                let left = Int(ceil(crossings[i])), right = Int(floor(crossings[i + 1]))
                if left <= right { for x in left...right { self[x, y] = material } }
            }
        }
        for i in points.indices { line(from: points[i], to: points[(i + 1) % points.count], material) }
    }
}

// Project authored material faces onto the same 2:1 axes as the room shell.
// Column offsets are integer raster steps, preserving crisp pixels and saved palettes.
extension PixelGrid {
    func isometricFace(rising: Bool, depth: Int = 0,
                       top: Character = ".", side: Character = ".") -> PixelGrid {
        let rise = (cols - 1) / 2
        var result = PixelGrid(cols: cols + depth, rows: rows + rise + depth / 2)
        if depth > 0 {
            // Front slopes down-right; depth recedes up-right.
            result.polygon([(0,depth/2),(depth,0),(cols-1+depth,rise),
                            (cols-1,rise+depth/2)], top)
            result.polygon([(cols-1,rise+depth/2),(cols-1+depth,rise),
                            (cols-1+depth,rise+rows-1),(cols-1,rise+depth/2+rows-1)], side)
        }
        for x in 0..<cols {
            let offset = (rising ? rise - x / 2 : x / 2) + depth / 2
            for y in 0..<rows {
                let cell = self[x,y]
                if cell != "." && cell != " " { result[x,y+offset] = cell }
            }
        }
        return result
    }
}
