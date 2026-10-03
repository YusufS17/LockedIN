import SwiftUI

// MARK: - Wall-mounted room furniture — window, clock, pinboard, poster
//
// Wall pieces project onto the corresponding 2:1 wall plane at bake time. Shading is hand-authored
// flat tones (top face light, right/bottom dark edge lines) baked with `.flatIcon`
// rules; the auto light shader is NOT used for furniture.
// The window takes raw sky/accent colours so this file has no dependency on
// DayPhase (defined in RoomSpriteShell.swift) — the caller maps phase → colours.

// Shared wall-piece wood ramp (art-direction wood: base 8B5E3C ramp).
private enum WallWood {
    static let light = PixelRGBA(r: 0xA9, g: 0x78, b: 0x4F)
    static let base  = PixelRGBA(r: 0x8B, g: 0x5E, b: 0x3C)
    static let dark  = PixelRGBA(r: 0x6E, g: 0x46, b: 0x29)
    static let line  = PixelRGBA(r: 0x59, g: 0x37, b: 0x1F)
}

/// Warm dark silhouette ring shared by all room bakes.
private let wallOutline = PixelRGBA(r: 59, g: 42, b: 33)

/// Wood ramp derived from an optional tint; nil keeps the default room wood.
private func woodRamp(_ tint: PixelRGBA?) -> (light: PixelRGBA, base: PixelRGBA, dark: PixelRGBA, line: PixelRGBA) {
    guard let t = tint else { return (WallWood.light, WallWood.base, WallWood.dark, WallWood.line) }
    return (t.lightened(0.22), t, t.darkened(0.22), t.darkened(0.45))
}

// MARK: - RoomWindowSprite (52×40)
//
// Wooden frame + 2×2 panes. Pane materials: 's' sky, 'a' sky accent (clouds by
// day, stars/moon by night, horizon glow at dawn/dusk), 'g' glass glint (derived
// from sky). Variant 1 drapes a vine over the top-left corner (solo mockup).

enum RoomWindowSprite {

    static func grid(variant: Int) -> PixelGrid {
        // 22-wide pane interiors. Accent placement is phase-neutral: a blob up
        // top (cloud/moon), scattered dots (stars/wisps), a horizon band low.
        let topLeft: [String] = [
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "sssssssssssssssaaassss",
            "sssssssssssssaaaaaasss",
            "ssssssssssssssaaaassss",
            "ssssssssssssssssssssss",
            "sssssssssssssssssggsss",
            "ssssssssssssssssggssss",
            "sssssssssssssssggsssss",
            "ssssssssssssssggssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
        ]
        let topRight: [String] = [
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "sssssassssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssasssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssasssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssasss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
        ]
        let bottomLeft: [String] = [
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssasssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "aaaaaaaaaaaaaaaaaaaaaa",
            "aasaasaasaasaasaasaasa",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
        ]
        let bottomRight: [String] = [
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "sssggsssssssssssssssss",
            "ssggssssssssssssssssss",
            "sggsssssssssssssssssss",
            "ggssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "aaaaaaaaaaaaaaaaaaaaaa",
            "aasaasaasaasaasaasaasa",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
            "ssssssssssssssssssssss",
        ]

        // Frame: top rows light, left mid, right/bottom dark; 'E' inner edge
        // line around the glass; protruding light-topped sill at the base.
        var rows: [String] = []
        rows.append(String(repeating: "L", count: 52))
        rows.append(String(repeating: "L", count: 52))
        rows.append(String(repeating: "F", count: 52))
        for i in 0..<15 { rows.append("FFE" + topLeft[i] + "FD" + topRight[i] + "EDD") }
        rows.append(String(repeating: "F", count: 49) + "DDD")           // horizontal mullion
        rows.append("FF" + String(repeating: "D", count: 50))            // mullion shadow
        for i in 0..<15 { rows.append("FFE" + bottomLeft[i] + "FD" + bottomRight[i] + "EDD") }
        rows.append("FF" + String(repeating: "E", count: 48) + "DD")     // inner line above sill
        rows.append(String(repeating: "F", count: 52))
        rows.append(String(repeating: "L", count: 52))                   // sill top catches light
        rows.append(String(repeating: "F", count: 52))
        rows.append(String(repeating: "E", count: 52))

        var g = PixelGrid(rows: rows)
        // Three restrained sky bands keep the view luminous without making
        // the pane a flat colour block. Coordinates remain in the authored
        // face, so projection and mirrored wall registration stay unchanged.
        for y in 3...34 {
            for x in 3...48 where g[x, y] == "s" {
                g[x, y] = y < 13 ? "S" : (y > 24 ? "H" : "s")
            }
        }
        // A distant neighbourhood at the horizon links this study nook to
        // the wider world. Interrupted heights read as rooftops at phone size.
        for (left, width, height) in [(3, 5, 3), (9, 7, 5), (18, 5, 2),
                                      (27, 6, 4), (35, 7, 2), (44, 5, 5)] {
            for x in left..<(left + width) {
                for y in (35 - height)..<35 where g[x, y] == "H" || g[x, y] == "s" || g[x, y] == "a" {
                    g[x, y] = "B"
                }
            }
        }
        for (x, y) in [(11, 32), (14, 33), (29, 33), (46, 31), (46, 33)] {
            if g[x, y] == "B" { g[x, y] = "b" }
        }
        if variant == 1 { g.stamp(vine, atX: 0, y: 0) }
        return g
    }

    // Hanging vine draping the top-left corner (variant 1). Short rows are
    // padded with '.' by PixelGrid.
    private static let vine = PixelGrid(rows: [
        "vvvvvvvvvvvv",
        "wvvwvvvwvvvvvv",
        ".vvvvwvvvvwvvv",
        "..wvv..vvv.vvv",
        "..vvv..vwv..wv",
        "...vv..vvv..vv",
        "...wv...vv...v",
        "...vv...wv",
        "....v...vv",
        "....vv...v",
        ".....v",
        "....wv",
        ".....v",
    ])

    /// Sky + accent come from the caller's day phase; no tint here.
    static func palette(variant: Int, sky: PixelRGBA, accent: PixelRGBA) -> PixelPalette {
        PixelPalette([
            "L": WallWood.light, "F": WallWood.base, "D": WallWood.dark, "E": WallWood.line,
            "s": sky,
            "S": sky.darkened(0.12),
            "H": DayPhase.mix(sky, accent, 0.22),
            "B": sky.darkened(0.32),
            "b": DayPhase.mix(accent, PixelRGBA(r: 255, g: 211, b: 139), 0.55),
            "a": accent,
            "g": sky.lightened(0.35),
            "v": PixelRGBA(r: 0x4A, g: 0x7C, b: 0x59),
            "w": PixelRGBA(r: 0x63, g: 0x9A, b: 0x6F),
        ])
    }

    @MainActor
    static func image(variant: Int, sky: PixelRGBA, accent: PixelRGBA, mirrored: Bool = false) -> UIImage {
        let key = "room-window-horizon4|v\(variant)|\(sky.keyFragment)|\(accent.keyFragment)|\(mirrored ? "m" : "n")"
        return SpriteBakery.shared.image(key: key) {
            var g = grid(variant: variant).isometricFace(rising: true)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g,
                                      palette: palette(variant: variant, sky: sky, accent: accent),
                                      rules: .flatIcon,
                                      outline: wallOutline,
                                      margin: 1)
        }
    }
}

// MARK: - RoomClockSprite (18×18)
//
// Round wall clock: dark rim 'R' (tintable), cream face, hands fixed at 10:10.

enum RoomClockSprite {

    static func grid(variant: Int) -> PixelGrid {
        PixelGrid(rows: [
            "......RRRRRR......",
            "....RRccccccRR....",
            "...RccccttccccR...",
            "..RccccccccccccR..",
            ".RccccccccccccccR.",
            ".RcccccccccchcccR.",
            "RcccchhcccchhccccR",
            "RccccchhcchhcccccR",
            "RttcccchhhhccccttR",
            "RttccccchhcccccttR",
            "RccccccccccccccccR",
            "RccccccccccccccccR",
            ".RccccccccccccccR.",
            ".RccccccccccccccR.",
            "..RccccccccccccR..",
            "...RddddttddddR...",
            "....RRddddddRR....",
            "......RRRRRR......",
        ])
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        PixelPalette([
            "R": tint ?? WallWood.line,
            "c": PixelRGBA(r: 0xF4, g: 0xEB, b: 0xD8),
            "d": PixelRGBA(r: 0xE4, g: 0xD5, b: 0xB8),   // face shade, lower arc
            "t": PixelRGBA(r: 0xC9, g: 0xA1, b: 0x6B),   // hour ticks
            "h": PixelRGBA(r: 0x2B, g: 0x26, b: 0x20),   // hands
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let rgba = tint.map(PixelRGBA.init)
        let key = "room-clock-iso3|v\(variant)|\(rgba?.keyFragment ?? "-")|\(mirrored ? "m" : "n")"
        return SpriteBakery.shared.image(key: key) {
            var g = grid(variant: variant).isometricFace(rising: true)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g,
                                      palette: palette(variant: variant, tint: rgba),
                                      rules: .flatIcon,
                                      outline: wallOutline,
                                      margin: 1)
        }
    }
}

// MARK: - RoomPinboardSprite (40×26)
//
// Corkboard: tan cork, wooden frame (tintable wood), six pastel sticky notes
// with pin dots, ink squiggles, and a cast shadow toward bottom-right.

enum RoomPinboardSprite {

    static func grid(variant: Int) -> PixelGrid {
        var rows: [String] = []
        rows.append(String(repeating: "L", count: 40))
        rows.append("F" + String(repeating: "E", count: 38) + "D")
        for _ in 0..<22 { rows.append("FE" + String(repeating: "k", count: 36) + "ED") }
        rows.append("F" + String(repeating: "E", count: 38) + "D")
        rows.append(String(repeating: "D", count: 40))
        var g = PixelGrid(rows: rows)

        // Cork speckle for texture.
        for (x, y) in [(6, 10), (12, 20), (20, 3), (28, 12), (34, 20), (10, 3), (25, 21), (36, 9)] {
            g[x, y] = "K"
        }
        // Sticky notes (char, x, y) — 7×6 stamps including shadow, inside cork x2…37 y2…23.
        let notes: [(Character, Int, Int)] = [
            ("y", 4, 4), ("b", 14, 3), ("p", 23, 5), ("g", 31, 4), ("o", 7, 13), ("u", 18, 14),
        ]
        for (ch, x, y) in notes { g.stamp(note(ch), atX: x, y: y) }
        return g
    }

    /// 6×5 note + 'E' pin + 'i' ink lines + 'K' cast shadow, in one 7×6 stamp.
    private static func note(_ ch: Character) -> PixelGrid {
        let c = String(ch)
        return PixelGrid(rows: [
            c + c + "E" + c + c + c + ".",
            c + c + c + c + c + c + "K",
            c + "iiii" + c + "K",
            c + "iii" + c + c + "K",
            c + c + c + c + c + c + "K",
            ".KKKKKK",
        ])
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        let wood = woodRamp(tint)
        let cork = PixelRGBA(r: 0xC7, g: 0x9A, b: 0x63)
        return PixelPalette([
            "L": wood.light, "F": wood.base, "D": wood.dark, "E": wood.line,
            "k": cork,
            "K": cork.darkened(0.18),
            "i": PixelRGBA(r: 0x8A, g: 0x7A, b: 0x63),
            "y": PixelRGBA(r: 0xF2, g: 0xD8, b: 0x79),
            "p": PixelRGBA(r: 0xF0, g: 0xB9, b: 0xC4),
            "b": PixelRGBA(r: 0xA9, g: 0xC7, b: 0xE8),
            "g": PixelRGBA(r: 0xB5, g: 0xD9, b: 0xA8),
            "o": PixelRGBA(r: 0xF5, g: 0xC7, b: 0x9A),
            "u": PixelRGBA(r: 0xA8, g: 0xD8, b: 0xCB),
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let rgba = tint.map(PixelRGBA.init)
        let key = "room-pinboard-iso3|v\(variant)|\(rgba?.keyFragment ?? "-")|\(mirrored ? "m" : "n")"
        return SpriteBakery.shared.image(key: key) {
            var g = grid(variant: variant).isometricFace(rising: false)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g,
                                      palette: palette(variant: variant, tint: rgba),
                                      rules: .flatIcon,
                                      outline: wallOutline,
                                      margin: 1)
        }
    }
}

// MARK: - RoomPosterSprite (24×32)
//
// Framed poster: wood frame + cream mat + 16×22 art plate. 'A' is the tintable
// art accent (default gold). Variants: 0 FOCUS/PLAN/GROW blocks with abstract
// text dashes (no real letters), 1 mountains, 2 abstract sun.

enum RoomPosterSprite {

    static func grid(variant: Int) -> PixelGrid {
        var rows: [String] = []
        rows.append(String(repeating: "L", count: 24))
        rows.append("F" + String(repeating: "M", count: 22) + "D")
        rows.append("F" + String(repeating: "M", count: 22) + "D")
        rows.append("FMM" + String(repeating: "E", count: 18) + "MMD")
        for _ in 0..<22 { rows.append("FMME" + String(repeating: "W", count: 16) + "EMMD") }
        rows.append("FMM" + String(repeating: "E", count: 18) + "MMD")
        rows.append("F" + String(repeating: "M", count: 22) + "D")
        rows.append("F" + String(repeating: "M", count: 22) + "D")
        rows.append("F" + String(repeating: "M", count: 22) + "D")
        rows.append(String(repeating: "D", count: 24))
        rows.append(String(repeating: "E", count: 24))
        var g = PixelGrid(rows: rows)
        g.stamp(art(variant: variant), atX: 4, y: 4, transparent: "?")
        return g
    }

    /// The 16×22 art plate. Text is abstract dash marks — never real letters.
    private static func art(variant: Int) -> PixelGrid {
        switch variant {
        case 1:  // mountains: pale sky, gold sun, snow-capped peaks, meadow
            return PixelGrid(rows: [
                "qqqqqqqqqqqqqqqq",
                "qqqqqqqqqqqAAAqq",
                "qqqqqqqqqqqAAAqq",
                "qqqqqqqqqqqAAAqq",
                "qqqqqqqqqqqqqqqq",
                "qqqqqqqqqqqqqqqq",
                "qqqqnnqqqqqqqqqq",
                "qqqnnnnqqqqqqqqq",
                "qqnnnnnnqqWWqqqq",
                "qnnnnnnnnmWWmqqq",
                "nnnnnnnnnmmmmmqq",
                "nnnnnnnnmmmmmmmq",
                "nnnnnnnmmmmmmmmm",
                "nnnnnnmmmmmmmmmm",
                "llllllllllllllll",
                "llmllllllmllllll",
                "llllllllllllllll",
                "llllllmlllllmlll",
                "llllllllllllllll",
                "lllmllllllllmlll",
                "llllllllllllllll",
                "mmmmmmmmmmmmmmmm",
            ])
        case 2:  // abstract sun over horizon lines
            return PixelGrid(rows: [
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWAAAAWWWWWW",
                "WWWWAAAAAAAAWWWW",
                "WWWAAAAAAAAAAWWW",
                "WWWAAAAAAAAAAWWW",
                "WWAAAAAAAAAAAAWW",
                "WWAAAAAAAAAAAAWW",
                "WWWAAAAAAAAAAWWW",
                "WWWAAAAAAAAAAWWW",
                "WWWWAAAAAAAAWWWW",
                "WWWWWWAAAAWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "3333333333333333",
                "WWWWWWWWWWWWWWWW",
                "W33WW33WW33WW33W",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
            ])
        default: // FOCUS / PLAN / GROW — coloured block + abstract text dashes
            return PixelGrid(rows: [
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WAAAAWWWWWWWWWWW",
                "WAAAAWxxxxxxxWWW",
                "WAAAAWxxxxxWWWWW",
                "WAAAAWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "W2222WWWWWWWWWWW",
                "W2222WxxxxxxxWWW",
                "W2222WxxxxxWWWWW",
                "W2222WWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "W3333WWWWWWWWWWW",
                "W3333WxxxxxxxWWW",
                "W3333WxxxxxWWWWW",
                "W3333WWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
                "WWWWWWWWWWWWWWWW",
            ])
        }
    }

    static func palette(variant: Int, tint: PixelRGBA?) -> PixelPalette {
        PixelPalette([
            "L": WallWood.light, "F": WallWood.base, "D": WallWood.dark, "E": WallWood.line,
            "M": PixelRGBA(r: 0xEF, g: 0xE3, b: 0xCC),   // mat
            "W": PixelRGBA(r: 0xFA, g: 0xF3, b: 0xE3),   // paper
            "A": tint ?? PixelRGBA(r: 0xFF, g: 0xB6, b: 0x26),
            "2": PixelRGBA(r: 0x63, g: 0x9A, b: 0x6F),
            "3": PixelRGBA(r: 0xC9, g: 0x6F, b: 0x4A),
            "x": PixelRGBA(r: 0xB0, g: 0xA2, b: 0x8A),   // abstract text dashes
            "q": PixelRGBA(r: 0xBC, g: 0xD6, b: 0xE4),   // poster sky
            "n": PixelRGBA(r: 0x8F, g: 0xA3, b: 0xB0),   // back peaks
            "m": PixelRGBA(r: 0x4A, g: 0x7C, b: 0x59),   // front peaks / tree green
            "l": PixelRGBA(r: 0x8F, g: 0xB5, b: 0x7C),   // meadow
        ])
    }

    @MainActor
    static func image(variant: Int, tint: Color?, mirrored: Bool = false) -> UIImage {
        let rgba = tint.map(PixelRGBA.init)
        let key = "room-poster-iso3|v\(variant)|\(rgba?.keyFragment ?? "-")|\(mirrored ? "m" : "n")"
        return SpriteBakery.shared.image(key: key) {
            var g = grid(variant: variant).isometricFace(rising: true)
            if mirrored { g = g.mirrored() }
            return PixelRenderer.bake(grid: g,
                                      palette: palette(variant: variant, tint: rgba),
                                      rules: .flatIcon,
                                      outline: wallOutline,
                                      margin: 1)
        }
    }
}
