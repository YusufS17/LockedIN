import SwiftUI

// MARK: - PixelKit core types — pixel art authored as data
//
// PixelKit is LockedIN's in-code art pipeline. Art is authored as character grids
// ("string art") plus palettes, shaded by a procedural light model (PixelShader),
// baked ONCE to a small UIImage (PixelRenderer + SpriteBakery), and composited by
// SwiftUI at display size with nearest-neighbour scaling (PixelSpriteView).
// Nothing re-renders per frame; animation swaps cached baked frames.

// MARK: - PixelRGBA

/// A resolved sRGB colour. SwiftUI `Color` is resolved to bytes once, at palette
/// build time, so baking never touches the SwiftUI colour system.
struct PixelRGBA: Hashable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    init(_ colour: Color) {
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        UIColor(colour).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        self.init(r: UInt8(max(0, min(1, rr)) * 255),
                  g: UInt8(max(0, min(1, gg)) * 255),
                  b: UInt8(max(0, min(1, bb)) * 255),
                  a: UInt8(max(0, min(1, aa)) * 255))
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    /// Mix toward white by `t` (0…1). Matches `Color.lightened`.
    func lightened(_ t: Double) -> PixelRGBA { mixed(toward: (255, 255, 255), t) }
    /// Mix toward black by `t` (0…1). Matches `Color.darkened`.
    func darkened(_ t: Double) -> PixelRGBA { mixed(toward: (0, 0, 0), t) }

    func opacity(_ t: Double) -> PixelRGBA {
        var c = self
        c.a = UInt8(Double(a) * max(0, min(1, t)))
        return c
    }

    private func mixed(toward other: (Double, Double, Double), _ t: Double) -> PixelRGBA {
        let t = max(0, min(1, t))
        return PixelRGBA(r: UInt8(Double(r) + (other.0 - Double(r)) * t),
                         g: UInt8(Double(g) + (other.1 - Double(g)) * t),
                         b: UInt8(Double(b) + (other.2 - Double(b)) * t),
                         a: a)
    }

    /// Compact hex form used in palette cache keys.
    var keyFragment: String { String(format: "%02x%02x%02x%02x", r, g, b, a) }
}

// MARK: - PixelPalette

/// Maps material characters ('H' hair, 'S' skin, …) to resolved colours.
/// The `cacheKey` is stable for identical palettes, so baked frames can be reused
/// across sprites that share appearance.
struct PixelPalette {
    private var map: [Character: PixelRGBA]
    let cacheKey: String

    init(_ entries: [Character: PixelRGBA], cacheKey: String? = nil) {
        self.map = entries
        self.cacheKey = cacheKey ?? entries
            .sorted { $0.key < $1.key }
            .map { "\($0.key)\($0.value.keyFragment)" }
            .joined()
    }

    subscript(ch: Character) -> PixelRGBA? { map[ch] }
}

// MARK: - PixelGrid

/// A rectangular grid of material characters — the authored form of every sprite.
/// '.' and ' ' are empty. Authored as string rows for readability.
struct PixelGrid: Hashable {
    let cols: Int
    let rows: Int
    private(set) var cells: [Character]   // row-major

    init(rows strings: [String]) {
        let parsed = strings.map(Array.init)
        self.rows = parsed.count
        self.cols = parsed.map(\.count).max() ?? 0
        var flat: [Character] = []
        flat.reserveCapacity(rows * cols)
        for row in parsed {
            flat.append(contentsOf: row)
            if row.count < cols { flat.append(contentsOf: repeatElement(".", count: cols - row.count)) }
        }
        self.cells = flat
    }

    init(cols: Int, rows: Int, fill: Character = ".") {
        self.cols = cols
        self.rows = rows
        self.cells = Array(repeating: fill, count: cols * rows)
    }

    init(_ grid: [[Character]]) {
        self.rows = grid.count
        self.cols = grid.map(\.count).max() ?? 0
        var flat: [Character] = []
        flat.reserveCapacity(rows * cols)
        for row in grid {
            flat.append(contentsOf: row)
            if row.count < cols { flat.append(contentsOf: repeatElement(".", count: cols - row.count)) }
        }
        self.cells = flat
    }

    /// Out-of-bounds reads return '.', writes are ignored — matches sprite authoring habits.
    subscript(x: Int, y: Int) -> Character {
        get {
            guard x >= 0, x < cols, y >= 0, y < rows else { return "." }
            return cells[y * cols + x]
        }
        set {
            guard x >= 0, x < cols, y >= 0, y < rows else { return }
            cells[y * cols + x] = newValue
        }
    }

    /// Stamp another grid on top; `transparent` cells in the layer are skipped.
    mutating func stamp(_ layer: PixelGrid, atX ox: Int = 0, y oy: Int = 0, transparent: Character = ".") {
        for ly in 0..<layer.rows {
            for lx in 0..<layer.cols {
                let ch = layer[lx, ly]
                if ch != transparent && ch != " " { self[ox + lx, oy + ly] = ch }
            }
        }
    }

    /// Set several columns of one row to a material — the workhorse of frame mutations.
    mutating func set(row: Int, cols columns: [Int], _ ch: Character) {
        for c in columns { self[c, row] = ch }
    }

    /// Rectangular crop — used for portrait head-crops and swatch tiles.
    func subgrid(x: Int, y: Int, cols w: Int, rows h: Int) -> PixelGrid {
        var out = PixelGrid(cols: w, rows: h)
        for oy in 0..<h {
            for ox in 0..<w { out[ox, oy] = self[x + ox, y + oy] }
        }
        return out
    }

    /// Horizontal mirror — author half a symmetric sprite, or flip furniture to face the other way.
    func mirrored() -> PixelGrid {
        var out = PixelGrid(cols: cols, rows: rows)
        for y in 0..<rows {
            for x in 0..<cols { out[cols - 1 - x, y] = self[x, y] }
        }
        return out
    }
}

// MARK: - PixelMaterialRules

/// Per-domain material semantics: what's empty, what's drawn flat (no shading),
/// and which broad group a material belongs to (shading respects group boundaries).
enum PixelMaterialRules {
    struct Rules {
        var isEmpty: (Character) -> Bool
        var isFlat: (Character) -> Bool
        var group: (Character) -> Int
    }
}

// MARK: - Colour adjust helpers (shared app-wide; previously lived in PixelAvatarView)

extension Color {
    /// Lighten toward white by `amount` (0…1).
    func lightened(_ amount: CGFloat) -> Color { mixed(with: .white, amount) }
    /// Darken toward black by `amount` (0…1).
    func darkened(_ amount: CGFloat) -> Color { mixed(with: .black, amount) }

    private func mixed(with other: Color, _ amount: CGFloat) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, amount))
        return Color(red: Double(r1 + (r2 - r1) * t),
                     green: Double(g1 + (g2 - g1) * t),
                     blue: Double(b1 + (b2 - b1) * t))
    }
}
