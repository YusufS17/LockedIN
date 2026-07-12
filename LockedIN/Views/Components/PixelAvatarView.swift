import SwiftUI

// MARK: - PixelAvatarView — code-drawn pixel-art student sprite (v2 art, PixelKit renderer)
//
// A parametric full-body pixel character. The art is unchanged v2 (24×32 material-channel
// grid, procedural top-left light shader, silhouette outline, blink/type/sip/phone/celebrate
// frames) — but rendering now goes through PixelKit: each animation frame is baked ONCE to a
// tiny UIImage and cached in SpriteBakery, then composited by SwiftUI with nearest-neighbour
// scaling. Zero per-frame drawing work; a roomful of avatars is a handful of texture swaps.
//
// The animation loop is deterministic: blink every 18 ticks, typing every 2, sipping every 4
// → the whole cycle repeats every 36 frames, so at most 36 baked frames per (appearance,
// status). Static renders (Reduce Motion / animated:false) show a phase where eyes are open.

struct PixelAvatarView: View {
    let appearance: CharacterAppearance
    var status: AvatarStatus = .idle
    var size: CGFloat = 80
    /// Frame animation (blink/typing/…). Static when false or under Reduce Motion.
    var animated: Bool = true

    /// Room scenes pass an explicit pose; nil derives one from the status.
    var pose: AvatarPose? = nil

    private static let frameCount = 36   // LCM of all animation periods (18, 2, 4)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Soft floor shadow under the feet (grounds the character).
            Ellipse()
                .fill(.black.opacity(0.16))
                .frame(width: size * 20 / 48, height: size * 3.5 / 64)
                .offset(y: size * 0.5 / 64)

            PixelSpriteView(
                cacheKey: Self.cacheKey(appearance: appearance, status: status, pose: resolvedPose),
                frameCount: Self.frameCount,
                build: { frame in
                    PixelRenderer.bake(
                        grid: AvatarSpriteV3.grid(appearance: appearance, pose: resolvedPose,
                                                  status: status, frame: frame),
                        palette: .avatarV3(appearance),
                        rules: .avatarV3,
                        outline: PixelRGBA(r: 31, g: 23, b: 20)   // Color(red:0.12, green:0.09, blue:0.08)
                    )
                },
                animated: animated
            )
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")
    }

    private var resolvedPose: AvatarPose {
        pose ?? AvatarSpriteV3.defaultPose(for: status)
    }

    private static func cacheKey(appearance a: CharacterAppearance, status: AvatarStatus, pose: AvatarPose) -> String {
        // Style axes shape the grid; colour axes shape the palette. Both must key the bake.
        "av3|\(a.skinTone).\(a.hairStyle).\(a.hairColour).\(a.faceStyle).\(a.topStyle).\(a.bottomStyle).\(a.shoeStyle).\(a.accentColour).\(a.accessory)|\(pose)|\(status)"
    }
}

// MARK: - Avatar material rules + palette (PixelKit bindings for the v2 sprite)

extension PixelMaterialRules.Rules {
    /// Ports PixelSprite's isEmpty/isFlat/group semantics.
    static let avatar = PixelMaterialRules.Rules(
        isEmpty: { PixelSprite.isEmpty($0) },
        isFlat: { PixelSprite.isFlat($0) },
        group: { PixelSprite.group($0) }
    )
}

extension PixelPalette {
    /// Material → resolved colour for one appearance. Mirrors the v2 `baseColour(for:)` map.
    static func avatar(_ a: CharacterAppearance) -> PixelPalette {
        PixelPalette([
            "H": PixelRGBA(a.hairColour.colour),
            "S": PixelRGBA(a.skinTone.colour),
            "E": PixelRGBA(Color(white: 0.97)),                          // eye white
            "e": PixelRGBA(Color(red: 0.13, green: 0.10, blue: 0.09)),   // pupil
            "m": PixelRGBA(a.skinTone.colour.darkened(0.40)),            // mouth line
            "b": PixelRGBA(a.skinTone.colour.darkened(0.22)),            // brow / nose shade
            "u": PixelRGBA(Color(red: 0.92, green: 0.55, blue: 0.55)),   // blush
            "O": PixelRGBA(a.accentColour.colour),                       // outfit primary
            "c": PixelRGBA(a.accentColour.colour.lightened(0.30)),       // collar / trim
            "t": PixelRGBA(Theme.Colour.buttonFill),                     // tie / dark trim
            "L": PixelRGBA(Color(red: 0.27, green: 0.31, blue: 0.42)),   // denim legs
            "F": PixelRGBA(Color(red: 0.15, green: 0.12, blue: 0.11)),   // shoes
            "G": PixelRGBA(Theme.Colour.buttonFill),                     // frames / headphones / phone
            "A": PixelRGBA(a.accentColour.colour),                       // cap / beanie
            "g": PixelRGBA(Theme.Colour.accentTeal),                     // phone glow
            "W": PixelRGBA(.white),                                      // drawstrings / sparkle / steam
            "K": PixelRGBA(Color(red: 0.85, green: 0.84, blue: 0.82)),   // mug ceramic
        ])
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
