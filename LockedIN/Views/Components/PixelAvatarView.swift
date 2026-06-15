import SwiftUI

// MARK: - PixelAvatarView — code-drawn pixel-art student sprite (v2: lit + animated)
//
// A parametric full-body pixel character rendered in SwiftUI `Canvas` — no PNG assets.
// v2 upgrades the look from a flat 12×16 blob to a 24×32 sprite with:
//   • a procedural LIGHT-AWARE shader — every cell is tinted by a top-left light, giving
//     automatic highlights, shadows and ambient occlusion without hand-authoring tones;
//   • a crisp silhouette OUTLINE + soft floor shadow for a readable, "framed" pixel look;
//   • TimelineView-driven ANIMATION frames — blink, typing, sipping, phone-glance,
//     celebration — gated on Reduce Motion.
//
// The sprite is authored in MATERIAL channels (skin / hair / outfit / …); the renderer
// resolves each material to a base colour from `CharacterAppearance` and then shades it.
// Universal fallback behind `SpriteAvatarView`; real `char_*.png` override when present.

struct PixelAvatarView: View {
    let appearance: CharacterAppearance
    var status: AvatarStatus = .idle
    var size: CGFloat = 80
    /// Frame animation (blink/typing/…). Static when false or under Reduce Motion.
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cols = PixelSprite.cols
    private let rows = PixelSprite.rows

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.16, paused: !animated || reduceMotion)) { tl in
            Canvas { ctx, canvasSize in
                let tick = (animated && !reduceMotion)
                    ? Int(tl.date.timeIntervalSinceReferenceDate / 0.16)
                    : 0
                let grid = PixelSprite.grid(appearance: appearance, status: status, tick: tick)
                render(grid, in: &ctx, canvasSize: canvasSize)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")
    }

    // MARK: - Renderer (outline + procedural shading + floor shadow)

    private func render(_ grid: [[Character]], in ctx: inout GraphicsContext, canvasSize: CGSize) {
        let cell = min(canvasSize.width / CGFloat(cols), canvasSize.height / CGFloat(rows))
        let ox = (canvasSize.width - cell * CGFloat(cols)) / 2
        let oy = (canvasSize.height - cell * CGFloat(rows)) / 2

        func mat(_ x: Int, _ y: Int) -> Character {
            guard y >= 0, y < grid.count, x >= 0, x < grid[y].count else { return "." }
            return grid[y][x]
        }

        // Soft floor shadow under the feet (grounds the character).
        let shadowRect = CGRect(x: ox + cell * 5, y: oy + cell * CGFloat(rows) - cell * 1.6,
                                width: cell * 14, height: cell * 2.4)
        ctx.fill(Ellipse().path(in: shadowRect), with: .color(.black.opacity(0.16)))

        let outline = Color(red: 0.12, green: 0.09, blue: 0.08)

        // Pass 1 — outline: empty cells 4-adjacent to a filled cell.
        for y in 0..<rows {
            for x in 0..<cols where PixelSprite.isEmpty(mat(x, y)) {
                let touches = !PixelSprite.isEmpty(mat(x - 1, y)) || !PixelSprite.isEmpty(mat(x + 1, y))
                    || !PixelSprite.isEmpty(mat(x, y - 1)) || !PixelSprite.isEmpty(mat(x, y + 1))
                guard touches else { continue }
                let rect = CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell,
                                  width: cell + 0.7, height: cell + 0.7)
                ctx.fill(Path(rect), with: .color(outline.opacity(0.9)))
            }
        }

        // Pass 2 — fill with light-aware shading.
        for y in 0..<rows {
            for x in 0..<cols {
                let ch = mat(x, y)
                guard let base = baseColour(for: ch) else { continue }
                let colour = PixelSprite.isFlat(ch)
                    ? base
                    : shade(base, level: shadeLevel(x: x, y: y, mat: mat))
                let rect = CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell,
                                  width: cell + 0.7, height: cell + 0.7)
                ctx.fill(Path(rect), with: .color(colour))
            }
        }
    }

    /// Top-left light model: top/left edges of a form catch light, bottom/right fall to shadow.
    private func shadeLevel(x: Int, y: Int, mat: (Int, Int) -> Character) -> Int {
        let me = mat(x, y)
        let g = PixelSprite.group(me)
        func diff(_ nx: Int, _ ny: Int) -> Bool { PixelSprite.group(mat(nx, ny)) != g }
        var level = 0
        if diff(x, y + 1) { level -= 2 }   // bottom edge → shadow
        if diff(x, y - 1) { level += 2 }   // top edge → highlight
        if diff(x + 1, y) { level -= 1 }   // right edge → shadow
        if diff(x - 1, y) { level += 1 }   // left edge → highlight
        return max(-2, min(2, level))
    }

    private func shade(_ base: Color, level: Int) -> Color {
        switch level {
        case 2:   return base.lightened(0.30)
        case 1:   return base.lightened(0.15)
        case -1:  return base.darkened(0.16)
        case -2:  return base.darkened(0.30)
        default:  return base
        }
    }

    // MARK: - Material → base colour

    private func baseColour(for ch: Character) -> Color? {
        switch ch {
        case "H": return appearance.hairColour.colour
        case "S": return appearance.skinTone.colour
        case "E": return Color(white: 0.97)                          // eye white
        case "e": return Color(red: 0.13, green: 0.10, blue: 0.09)   // pupil
        case "m": return appearance.skinTone.colour.darkened(0.40)   // mouth line
        case "b": return appearance.skinTone.colour.darkened(0.22)   // brow / nose shade
        case "u": return Color(red: 0.92, green: 0.55, blue: 0.55)   // blush
        case "O": return appearance.accentColour.colour              // outfit primary
        case "c": return appearance.accentColour.colour.lightened(0.30)  // collar / trim
        case "t": return Theme.Colour.buttonFill                     // tie / dark trim
        case "L": return Color(red: 0.27, green: 0.31, blue: 0.42)   // denim legs
        case "F": return Color(red: 0.15, green: 0.12, blue: 0.11)   // shoes
        case "G": return Theme.Colour.buttonFill                     // dark frames / headphones / phone
        case "A": return appearance.accentColour.colour              // cap / beanie
        case "g": return Theme.Colour.accentTeal                     // phone glow
        case "W": return .white                                       // drawstrings / sparkle / steam
        case "K": return Color(red: 0.85, green: 0.84, blue: 0.82)   // mug ceramic
        default:  return nil
        }
    }
}

// MARK: - PixelSprite — 24×32 grid assembly (material channels + animation)

enum PixelSprite {

    static let cols = 24
    static let rows = 32

    static func isEmpty(_ ch: Character) -> Bool { ch == "." || ch == " " }

    /// Detail materials drawn flat (no procedural shading): face features, sparkles, glow.
    static func isFlat(_ ch: Character) -> Bool {
        "EeumbWg".contains(ch)
    }

    /// Broad material group — shading respects boundaries between groups, not within them.
    static func group(_ ch: Character) -> Int {
        switch ch {
        case ".", " ":           return 0   // empty
        case "S", "m", "b", "u": return 1   // skin
        case "H":                return 2   // hair
        case "O", "c", "t":      return 3   // outfit
        case "L":                return 4   // legs
        case "F":                return 5   // shoes
        case "G", "A":           return 6   // accessory
        case "K", "W", "g":      return 7   // props
        default:                 return 8   // eyes etc. (flat anyway)
        }
    }

    // MARK: Base body (short hair, casual, neutral idle). 24 wide × 32 tall.

    private static let base: [String] = [
        "........HHHHHHHH........",  // 0
        "......HHHHHHHHHHHH......",  // 1
        ".....HHHHHHHHHHHHHH.....",  // 2
        "....HHHHHHHHHHHHHHHH....",  // 3
        "....HHHHHHHHHHHHHHHH....",  // 4
        "...HHHHHHHHHHHHHHHHHH...",  // 5
        "...HHHSSSSSSSSSSSSHHH...",  // 6  face begins
        "...HHSSSSSSSSSSSSSSHH...",  // 7
        "...HSSSSSSSSSSSSSSSSH...",  // 8
        "...HSSbbSSSSSSSbbSSSH...",  // 9  brows
        "...SSSEESSSSSSSEESSSS...",  // 10 eyes (white)
        "...SSSeeSSSSSSSeeSSSS...",  // 11 pupils
        "....SSSSSSbbSSSSSSSS....",  // 12 nose
        "....SSuSSSSSSSSSSuSS....",  // 13 blush
        "....SSSSSmmmmmmSSSS.....",  // 14 mouth
        ".....SSSSSSSSSSSSSS.....",  // 15 chin
        "......SSSSSSSSSSSS......",  // 16 jaw
        "........SSSSSSSS........",  // 17 neck
        ".....cccOOOOOOOOccc.....",  // 18 shoulders + collar
        "....OOOOOOOOOOOOOOOO....",  // 19 torso
        "...OOOOOOOOOOOOOOOOOO...",  // 20 arms out
        "...OOOOOOOOOOOOOOOOOO...",  // 21
        "...OOOOOOOOOOOOOOOOOO...",  // 22
        "...OOOOOOOOOOOOOOOOOO...",  // 23
        "...SSOOOOOOOOOOOOOOSS...",  // 24 hands
        "...SSOOOOOOOOOOOOOOSS...",  // 25 hands
        "....OOOOOOOOOOOOOOOO....",  // 26 lower torso
        "....OOOOOOOOOOOOOOOO....",  // 27 hips
        ".....LLLLLL..LLLLLL.....",  // 28 legs
        ".....LLLLLL..LLLLLL.....",  // 29
        ".....LLLLLL..LLLLLL.....",  // 30
        ".....FFFFFF..FFFFFF....."   // 31 shoes
    ]

    // MARK: - Assembly

    static func grid(appearance: CharacterAppearance, status: AvatarStatus, tick: Int) -> [[Character]] {
        var g = base.map { Array($0) }
        applyHair(&g, appearance.hairStyle)
        applyOutfit(&g, appearance.outfitStyle)
        applyAccessory(&g, appearance.accessory)
        applyFace(&g, status)
        applyAnimation(&g, status: status, accessory: appearance.accessory, tick: tick)
        return g
    }

    // MARK: Hair (6 styles) — operate on the head region

    private static func applyHair(_ g: inout [[Character]], _ hair: HairStyle) {
        switch hair {
        case .short:
            break

        case .buzz:
            // Tight cap — strip crown volume, keep a thin hairline.
            set(&g, 0, Array(0..<24), ".")
            set(&g, 1, Array(0..<24), ".")
            set(&g, 2, [5, 6, 17, 18], ".")
            for r in 3...5 { set(&g, r, Array(4..<20).filter { $0 % 2 == 0 }, "H") } // sparse texture

        case .curly:
            // Rounded bumps along the top + temples.
            set(&g, 0, [5, 6, 9, 10, 13, 14, 17, 18], "H")
            set(&g, 1, [3, 4, 7, 8, 15, 16, 19, 20], "H")
            set(&g, 2, [2, 3, 20, 21], "H")
            set(&g, 3, [2, 3, 20, 21], "H")
            for r in 6...9 { set(&g, r, [2, 21], "H") }   // bushy temples

        case .afro:
            // Big rounded halo.
            set(&g, 0, Array(4..<20), "H")
            set(&g, 1, Array(2..<22), "H")
            for r in 2...4 { set(&g, r, Array(1..<23), "H") }
            for r in 5...12 { set(&g, r, [1, 2, 21, 22], "H") }
            set(&g, 13, [2, 21], "H")

        case .long:
            // Sleek crown that drapes well past the shoulders.
            for r in 6...23 { set(&g, r, [3, 4, 19, 20], "H") }
            set(&g, 24, [3, 20], "H")
            set(&g, 25, [3, 20], "H")

        case .tied:
            // Sleek, with a clear top-knot bun + short tail.
            set(&g, 0, Array(0..<24), ".")
            set(&g, 1, Array(0..<24), ".")
            set(&g, 0, [10, 11, 12, 13], "H")          // bun crown
            set(&g, 1, [9, 10, 11, 12, 13, 14], "H")
            set(&g, 2, [9, 10, 11, 12, 13, 14], "H")
            for r in 6...12 { set(&g, r, [20], "H") }   // short tail at nape
            set(&g, 13, [20, 21], "H")
        }
    }

    // MARK: Outfit motifs (torso rows 18–27)

    private static func applyOutfit(_ g: inout [[Character]], _ outfit: OutfitStyle) {
        switch outfit {
        case .casual:
            set(&g, 19, [11, 12], "c")               // small placket

        case .academic:
            set(&g, 18, [8, 9, 14, 15], "c")         // wide collar
            set(&g, 19, [10, 11, 12, 13], "c")
            set(&g, 20, [11, 12], "t")               // buttoned

        case .hoodie:
            set(&g, 17, [7, 8, 15, 16], "c")         // hood sides
            set(&g, 18, [6, 7, 16, 17], "c")
            set(&g, 19, [11, 12], "W")               // drawstrings
            set(&g, 20, [11, 12], "W")
            set(&g, 24, Array(9...14), "c")          // front pocket

        case .smart:
            set(&g, 18, [9, 10, 13, 14], "c")        // lapels
            set(&g, 19, [11, 12], "t")               // tie
            set(&g, 20, [11, 12], "t")
            set(&g, 21, [11, 12], "t")
        }
    }

    // MARK: Accessories

    private static func applyAccessory(_ g: inout [[Character]], _ accessory: Accessory) {
        switch accessory {
        case .none:
            break

        case .glasses:
            set(&g, 10, [5, 8, 14, 17], "G")         // frame sides
            set(&g, 9, [6, 7, 15, 16], "G")          // tops
            set(&g, 11, [6, 7, 15, 16], "G")         // bottoms
            set(&g, 10, [11, 12], "G")               // bridge

        case .headphones:
            set(&g, 2, [9, 10, 11, 12, 13, 14], "G") // band
            set(&g, 1, [7, 8, 15, 16], "G")
            for r in 9...11 { set(&g, r, [3, 4, 19, 20], "G") }  // ear cups

        case .cap:
            set(&g, 2, Array(5..<19), "A")
            set(&g, 3, Array(4..<20), "A")
            set(&g, 4, Array(4..<20), "A")
            set(&g, 5, Array(3..<11), "A")           // brim over forehead-left

        case .beanie:
            set(&g, 0, Array(7..<17), "A")
            set(&g, 1, Array(5..<19), "A")
            set(&g, 2, Array(4..<20), "A")
            set(&g, 3, Array(4..<20), "A")
            set(&g, 4, [4, 5, 6, 17, 18, 19], "A")   // folded band edges
        }
    }

    // MARK: Status faces (eyes/brows/mouth — rows 9–14)

    private static func applyFace(_ g: inout [[Character]], _ status: AvatarStatus) {
        switch status {
        case .idle, .focused:
            break

        case .deepFocus:
            set(&g, 9, [6, 7, 15, 16], "b")          // lowered brows
            set(&g, 14, [9, 10, 11, 12, 13, 14], "S")
            set(&g, 14, [10, 11, 12, 13], "m")       // flat, set mouth

        case .onBreak:
            set(&g, 14, [8, 9, 14, 15], "m")         // wide smile
            set(&g, 15, [9, 10, 13, 14], "m")

        case .distracted:
            set(&g, 9, [15, 16], "b")                // raised worried brow
            set(&g, 8, [16, 17], "b")
            set(&g, 14, [9, 10, 11, 12, 13, 14], "S")
            set(&g, 14, [10, 13], "m"); set(&g, 15, [11, 12], "m")  // open frown
            set(&g, 7, [19], "W"); set(&g, 8, [19], "W")            // sweat drop

        case .finished:
            set(&g, 14, [8, 9, 14, 15], "m")         // smile
            set(&g, 15, [9, 10, 13, 14], "m")
        }
    }

    // MARK: Animation (frame mutations driven by tick)

    private static func applyAnimation(_ g: inout [[Character]], status: AvatarStatus,
                                       accessory: Accessory, tick: Int) {
        // Blink: briefly close eyes ~every 18 ticks (~3s).
        if tick % 18 == 0 {
            set(&g, 10, [6, 7, 15, 16], "S"); set(&g, 11, [6, 7, 15, 16], "S")
            set(&g, 11, [6, 7, 15, 16], "m")   // closed eye line
        }

        switch status {
        case .focused, .deepFocus:
            // Typing — hands rise/fall on alternating frames.
            if tick % 2 == 0 {
                set(&g, 24, [4, 5, 18, 19], ".")
                set(&g, 23, [4, 5, 18, 19], "S")
            }

        case .onBreak:
            // Lift a mug toward the face on the second half of the cycle.
            if tick % 4 >= 2 {
                set(&g, 16, [4, 5], "K"); set(&g, 17, [4, 5], "K")  // mug at hand height
                set(&g, 15, [4], "W")                                // steam
            } else {
                set(&g, 24, [4, 5], "K"); set(&g, 23, [4, 5], "K")
            }

        case .distracted:
            // Phone glance — a lit phone appears in the lowered hand.
            set(&g, 26, [4, 5], "G"); set(&g, 25, [4, 5], "g")
            if tick % 4 < 2 { set(&g, 25, [5], "G") }

        case .finished:
            // Celebration — arms up + twinkle on alternating frames.
            if tick % 2 == 0 {
                set(&g, 24, [3, 4, 19, 20], ".")
                set(&g, 19, [2, 3, 20, 21], "S")     // raised hands
                set(&g, 0, [4], "W"); set(&g, 2, [21], "W")
            }

        case .idle:
            break
        }
    }

    // MARK: Helper

    private static func set(_ g: inout [[Character]], _ row: Int, _ cols: [Int], _ ch: Character) {
        guard g.indices.contains(row) else { return }
        for c in cols where g[row].indices.contains(c) { g[row][c] = ch }
    }
}

// MARK: - Colour adjust helpers

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

// MARK: - Previews

#Preview("Pixel catalog") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(CharacterCatalog.all) { ch in
                VStack(spacing: 4) {
                    PixelAvatarView(appearance: ch.fallback, status: .idle, size: 72)
                    Text(ch.name).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
            }
        }
        .padding()
    }
}

#Preview("States") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        HStack(spacing: 10) {
            ForEach([AvatarStatus.focused, .deepFocus, .onBreak, .distracted, .finished], id: \.self) { s in
                PixelAvatarView(appearance: .leo, status: s, size: 64)
            }
        }
    }
}
