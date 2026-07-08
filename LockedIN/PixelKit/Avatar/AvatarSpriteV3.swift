import SwiftUI

// MARK: - AvatarSpriteV3 — 48×64 chibi sprite (mockup-fidelity character art)
//
// The v3 character: chibi proportions per the design mockups — head ≈ 44% of height,
// big dark oval eyes with a white catch-light, soft jaw, compact body, chunky white
// sneakers. Authored as a HALF grid (24 cols) mirrored to 48, then asymmetric details
// (fringe sweep, mouth offset) stamped after the mirror.
//
// Materials extend the v2 set:
//   H hair   h hair-shadow(flat)   S skin   E eye-highlight(flat)   e pupil(flat)
//   b brow   m mouth(flat)   u blush(flat)   O top   c top-trim   L bottoms
//   w shoe-white   f sole(flat)   W white detail   G dark accessory   A accent accessory
//   g glow(flat)   K mug

enum AvatarSpriteV3 {

    static let cols = 48
    static let rows = 64

    // MARK: Base body — LEFT half (24×64), mirrored right at assembly.

    private static let baseHalf: [String] = [
        "........................",  //  0
        "........................",  //  1
        ".................HHHHHHH",  //  2  crown (rounded)
        "...............HHHHHHHHH",  //  3
        ".............HHHHHHHHHHH",  //  4
        "............HHHHHHHHHHHH",  //  5
        "...........HHHHHHHHHHHHH",  //  6
        "..........HHHHHHHHHHHHHH",  //  7
        "..........HHHHHHHHHHHHHH",  //  8
        ".........HHHHHHHHHHHHHHH",  //  9
        ".........HHHHHHHHHHHHHHH",  // 10
        ".........HHHHHHHHHHHHHHH",  // 11
        ".........HHHHHHHHHHHHHHH",  // 12 fringe mass
        ".........HHSSSSSSSSSSSSS",  // 13 forehead (clean fringe edge)
        ".........HSSSSSSSSSSSSSS",  // 14
        ".........HSSSSSSSSSSSSSS",  // 15
        ".........SSSSSSSSSSSSSSS",  // 16 face widest
        ".........SSSSeeeeSSSSSSS",  // 17 eyes (rounded top)
        "........SSSSEEeeeeSSSSSS",  // 18 catch-light
        "........SSSSEeeeeeSSSSSS",  // 19
        "........SSSSSeeeeSSSSSSS",  // 20
        ".........SSSSSeeSSSSSSSS",  // 21 eye taper
        ".........SuuSSSSSSSSSSSS",  // 22 blush under eyes
        ".........SuuSSSSSSSSSSSS",  // 23
        "..........SSSSSSSSSSSSmm",  // 24 small mouth (mirrors to 4-wide)
        "..........SSSSSSSSSSSSSS",  // 25
        "...........SSSSSSSSSSSSS",  // 26 jaw taper
        "............SSSSSSSSSSSS",  // 27
        "..............SSSSSSSSSS",  // 28
        ".................SSSSSSS",  // 29 chin
        "..................SSSSSS",  // 30 neck
        "..................SSSSSS",  // 31
        "...............OOOOOOOOO",  // 32 shoulders (narrower than head)
        ".............OOOOOOOOOOO",  // 33
        "............OOOOOOOOOOOO",  // 34
        "...........OOOoOOOOOOOOO",  // 35 sleeve seam
        "...........OOOoOOOOOOOOO",  // 36
        "...........OOOoOOOOOOOOO",  // 37
        "...........OOOoOOOOOOOOO",  // 38
        "...........OOOoOOOOOOOOO",  // 39
        "...........OOOoOOOOOOOOO",  // 40
        "...........OOOoOOOOOOOOO",  // 41
        "...........OOOoOOOOOOOOO",  // 42
        "...........OOOOOOOOOOOOO",  // 43
        "...........SSOOOOOOOOOOO",  // 44 hands below sleeves
        "...........SSOOOOOOOOOOO",  // 45
        ".............OOOOOOOOOOO",  // 46 lower torso
        ".............OOOOOOOOOOO",  // 47
        ".............OOOOOOOOOOO",  // 48 hem
        "...............LLLLLL...",  // 49 legs
        "...............LLLLLL...",  // 50
        "...............LLLLLL...",  // 51
        "...............LLLLLL...",  // 52
        "...............LLLLLL...",  // 53
        "...............LLLLLL...",  // 54
        "...............LLLLLL...",  // 55
        "...............LLLLLL...",  // 56
        "..............wwwwwww...",  // 57 sneakers
        "..............wwwwwww...",  // 58
        "..............wwwwwww...",  // 59
        "..............fffffff...",  // 60 sole
        "..............fffffff...",  // 61
        "........................",  // 62
        "........................",  // 63
    ]

    // MARK: - Assembly

    static func grid(appearance: CharacterAppearance,
                     pose: AvatarPose = .stand,
                     status: AvatarStatus = .idle,
                     frame: Int = 0) -> PixelGrid {
        var g = mirroredBase()
        applyHair(&g, appearance.hairStyle)
        applyFaceStyle(&g, appearance.faceStyle)
        applyFace(&g, status: status)
        applyTop(&g, appearance.topStyle)
        applyBottoms(&g, appearance.bottomStyle)
        applyShoes(&g, appearance.shoeStyle)
        applyAccessory(&g, appearance.accessory)
        applyPose(&g, pose)
        applyAnimation(&g, pose: pose, status: status, frame: frame)
        return g
    }

    static func frameCount(pose: AvatarPose, status: AvatarStatus) -> Int { 36 }

    /// The natural pose for a status when the caller doesn't specify one.
    /// Rooms pass `.sitTypingFront` explicitly for seated participants.
    static func defaultPose(for status: AvatarStatus) -> AvatarPose {
        switch status {
        case .onBreak:    return .coffee
        case .distracted: return .phone
        case .finished:   return .celebrate
        default:          return .stand
        }
    }

    /// Head crop for roster rows, cards and the home greeting: rows 0–31, cols 8–39.
    static func portraitGrid(appearance: CharacterAppearance) -> PixelGrid {
        grid(appearance: appearance, pose: .stand, status: .idle, frame: 0)
            .subgrid(x: 8, y: 0, cols: 32, rows: 32)
    }

    private static func mirroredBase() -> PixelGrid {
        let half = PixelGrid(rows: baseHalf)
        var full = PixelGrid(cols: cols, rows: rows)
        full.stamp(half, atX: 0, y: 0)
        full.stamp(half.mirrored(), atX: half.cols, y: 0)
        return full
    }

    // MARK: Hair styles (restyle rows 0–15; long styles also drape rows 16+)

    private static func applyHair(_ g: inout PixelGrid, _ hair: HairStyle) {
        switch hair {
        case .short:
            break   // base

        case .buzz:
            // Tighter crown: lift the top two hair rows, thin the sides.
            for x in 0..<cols where g[x, 2] == "H" { g[x, 2] = "." }
            for x in 0..<cols where g[x, 3] == "H" { g[x, 3] = "." }
            for y in 4...6 { g[9, y] = "."; g[cols - 10, y] = "." }

        case .curly:
            // Chunky rounded bumps along the crown + temples.
            g.set(row: 1, cols: [13, 14, 15, 19, 20, 21, 26, 27, 28, 32, 33, 34], "H")
            g.set(row: 0, cols: [14, 20, 27, 33], "H")
            for y in 13...18 { g.set(row: y, cols: [8, 9, cols - 10, cols - 9], "H") }
            g.set(row: 19, cols: [8, cols - 9], "H")

        case .afro:
            // Big rounded halo, wider and taller than the head.
            g.set(row: 0, cols: Array(16..<(cols - 16)), "H")
            g.set(row: 1, cols: Array(12..<(cols - 12)), "H")
            for y in 2...4 { g.set(row: y, cols: Array(9..<(cols - 9)), "H") }
            for y in 5...15 { g.set(row: y, cols: [7, 8, cols - 9, cols - 8], "H") }
            g.set(row: 16, cols: [8, cols - 9], "H")

        case .long:
            // Drapes behind the shoulders to mid-torso.
            for y in 16...40 {
                g.set(row: y, cols: [7, 8, cols - 9, cols - 8], "H")
            }
            for y in 41...43 { g.set(row: y, cols: [7, cols - 8], "H") }

        case .tied:
            // Top-knot bun + clean sides.
            for x in 0..<cols where g[x, 2] == "H" { g[x, 2] = "." }
            g.set(row: 0, cols: [21, 22, 23, 24, 25, 26], "H")
            g.set(row: 1, cols: [20, 21, 22, 23, 24, 25, 26, 27], "H")
            g.set(row: 2, cols: [20, 21, 22, 23, 24, 25, 26, 27], "H")
        }
    }

    // MARK: Status faces

    private static func applyFace(_ g: inout PixelGrid, status: AvatarStatus) {
        switch status {
        case .idle, .focused:
            break
        case .deepFocus:
            // Determined: flat brows just above the eyes.
            g.set(row: 16, cols: [12, 13, 14, 15, 16], "b")
            g.set(row: 16, cols: [31, 32, 33, 34, 35], "b")
        case .onBreak, .finished:
            // Smile: widen the mouth upward at the corners.
            g.set(row: 24, cols: [20, 27], "m")
            g.set(row: 23, cols: [19, 28], "m")
        case .distracted:
            // Worry: raised brow + small frown + sweat drop.
            g.set(row: 15, cols: [31, 32, 33], "b")
            g.set(row: 25, cols: [22, 23, 24, 25], "S")
            g.set(row: 26, cols: [23, 24], "m")
            g.set(row: 13, cols: [40], "W")
            g.set(row: 14, cols: [40], "W")
        }
    }

    // MARK: Face styles (permanent features, applied before status expressions)

    private static func applyFaceStyle(_ g: inout PixelGrid, _ face: FaceStyle) {
        switch face {
        case .neutral:
            break
        case .smile:
            g.set(row: 23, cols: [20, 27], "m")   // upturned corners
        case .freckles:
            g.set(row: 22, cols: [14, 16, 31, 33], "b")
            g.set(row: 23, cols: [15, 32], "b")
        case .lashes:
            g.set(row: 16, cols: [12, 16, 31, 35], "e")   // lash flicks above the eyes
        case .stern:
            g.set(row: 16, cols: [12, 13, 14, 15, 33, 34, 35, 36], "b")
        }
    }

    // MARK: Tops (torso rows 32–48; accent-tinted)

    private static func applyTop(_ g: inout PixelGrid, _ top: TopStyle) {
        switch top {
        case .tee:
            // Short sleeves: forearms bare from row 40 down.
            for y in 40...45 {
                g.set(row: y, cols: [11, 12, 13, 34, 35, 36], y <= 43 ? "S" : "S")
            }
            for y in 40...45 { g.set(row: y, cols: [14, 33], "S") }
            g.set(row: 33, cols: [23, 24], "c")

        case .hoodie:
            // Hood rim + drawstrings + front pocket.
            g.set(row: 31, cols: [16, 17, 18, 29, 30, 31], "c")
            g.set(row: 32, cols: [15, 16, 31, 32], "c")
            for y in 33...36 { g.set(row: y, cols: [21, 26], "W") }
            for y in 44...47 { g.set(row: y, cols: Array(18...29), "c") }

        case .jumper:
            // Wide ribbed collar + cuff trim.
            g.set(row: 32, cols: [18, 19, 20, 27, 28, 29], "c")
            g.set(row: 33, cols: [21, 22, 25, 26], "c")
            g.set(row: 43, cols: [11, 12, 13, 34, 35, 36], "c")

        case .jacket:
            // Open front panel over a lighter inner layer.
            for y in 33...46 { g.set(row: y, cols: [21, 22, 25, 26], "c") }
            for y in 33...46 { g.set(row: y, cols: [23, 24], "W") }

        case .shirt:
            // Collar points + button placket.
            g.set(row: 32, cols: [20, 21, 26, 27], "c")
            for y in 33...38 { g.set(row: y, cols: [23, 24], "t") }
        }
    }

    // MARK: Bottoms (rows 49–56) + shoes (rows 57–61)

    private static func applyBottoms(_ g: inout PixelGrid, _ bottoms: BottomStyle) {
        switch bottoms {
        case .jeans, .chinos:
            break   // base silhouette, palette recolours
        case .joggers:
            g.set(row: 55, cols: [15, 16, 17, 18, 19, 20, 27, 28, 29, 30, 31, 32], "c")   // cuffs
        case .shorts:
            // Bare shins from row 53 down.
            for y in 53...56 {
                for x in 0..<cols where g[x, y] == "L" { g[x, y] = "S" }
            }
        case .skirt:
            // Flared block over bare legs.
            for y in 49...52 {
                for x in 14...33 where g[x, y] == "L" || g[x, y] == "." { g[x, y] = "L" }
            }
            g.set(row: 52, cols: Array(13...34), "L")
            for y in 53...56 {
                for x in 0..<cols where g[x, y] == "L" { g[x, y] = "S" }
            }
        }
    }

    private static func applyShoes(_ g: inout PixelGrid, _ shoes: ShoeStyle) {
        switch shoes {
        case .sneakers:
            break   // base: white upper + dark sole
        case .boots:
            // Taller shaft eating the lower shin.
            for y in 55...56 {
                for x in 0..<cols where (g[x, y] == "L" || g[x, y] == "S") { g[x, y] = "w" }
            }
        case .slipOns:
            // Lower profile: top shoe row becomes leg/skin.
            for x in 0..<cols where g[x, 57] == "w" {
                g[x, 57] = g[x, 56] == "S" ? "S" : "L"
            }
        }
    }

    // MARK: Accessories

    private static func applyAccessory(_ g: inout PixelGrid, _ accessory: Accessory) {
        switch accessory {
        case .none:
            break
        case .glasses:
            for y in 17...20 { g.set(row: y, cols: [11, 18, 29, 36], "G") }
            g.set(row: 16, cols: [12, 13, 14, 15, 16, 17, 30, 31, 32, 33, 34, 35], "G")
            g.set(row: 21, cols: [12, 13, 14, 15, 16, 17, 30, 31, 32, 33, 34, 35], "G")
            g.set(row: 18, cols: [23, 24], "G")
        case .headphones:
            g.set(row: 3, cols: Array(19...28), "G")
            g.set(row: 4, cols: [16, 17, 18, 29, 30, 31], "G")
            for y in 15...20 { g.set(row: y, cols: [7, 8, cols - 9, cols - 8], "G") }
        case .cap:
            for y in 4...9 {
                for x in 0..<cols where g[x, y] == "H" { g[x, y] = "A" }
            }
            g.set(row: 10, cols: Array(6...20), "A")   // brim sweep left
        case .beanie:
            for y in 2...9 {
                for x in 0..<cols where g[x, y] == "H" { g[x, y] = "A" }
            }
            g.set(row: 10, cols: Array(9..<(cols - 9)), "A")
        }
    }

    // MARK: Poses (body + prop layout; animation cycles the details)

    private static func applyPose(_ g: inout PixelGrid, _ pose: AvatarPose) {
        switch pose {
        case .stand:
            break

        case .sitTypingFront:
            // Hands come forward onto an implied desk edge; legs are occluded in-room.
            g.set(row: 43, cols: [17, 18, 19, 28, 29, 30], "S")
            g.set(row: 44, cols: [17, 18, 19, 28, 29, 30], "S")

        case .coffee:
            // Mug held chest-height beside the sleeve.
            for y in 36...39 { g.set(row: y, cols: [5, 6, 7, 8], "K") }
            g.set(row: 40, cols: [6, 7, 8], "S")   // hand under mug

        case .phone:
            // Lit phone in the lowered hand.
            for y in 40...45 { g.set(row: y, cols: [5, 6, 7, 8], "G") }
            for y in 41...44 { g.set(row: y, cols: [6, 7], "g") }

        case .celebrate:
            // Arms thrown up beside the head.
            for y in 26...34 { g.set(row: y, cols: [7, 8, cols - 9, cols - 8], "O") }
            g.set(row: 24, cols: [7, 8, cols - 9, cols - 8], "S")
            g.set(row: 25, cols: [7, 8, cols - 9, cols - 8], "S")
        }
    }

    // MARK: Animation frames (36-frame loop, matching PixelKit playback)

    private static func applyAnimation(_ g: inout PixelGrid, pose: AvatarPose,
                                       status: AvatarStatus, frame: Int) {
        let tick = frame + 1   // frame 0 (static) must not land on the blink beat
        if tick % 18 == 0 {
            // Blink: pupils collapse to a lash line.
            for y in 17...20 {
                for x in 0..<cols where (g[x, y] == "e" || g[x, y] == "E") { g[x, y] = "S" }
            }
            g.set(row: 20, cols: [12, 13, 14, 15, 16], "m")
            g.set(row: 20, cols: [31, 32, 33, 34, 35], "m")
        }

        switch pose {
        case .sitTypingFront:
            // Typing: forward hands rise and fall on alternating beats.
            if tick % 2 == 0 {
                g.set(row: 44, cols: [17, 18, 19, 28, 29, 30], "O")
                g.set(row: 42, cols: [17, 18, 19, 28, 29, 30], "S")
            }

        case .coffee:
            // Sip: mug lifts toward the face on the second half of the cycle.
            if tick % 4 >= 2 {
                for y in 36...39 { g.set(row: y, cols: [5, 6, 7, 8], ".") }
                g.set(row: 40, cols: [6, 7, 8], ".")
                for y in 28...31 { g.set(row: y, cols: [5, 6, 7, 8], "K") }
                g.set(row: 26, cols: [6], "W"); g.set(row: 25, cols: [7], "W")   // steam
            }

        case .phone:
            // Screen glow flicker.
            if tick % 4 < 2 { g.set(row: 42, cols: [6, 7], "G") }

        case .celebrate:
            // Twinkles by the raised hands.
            if tick % 2 == 0 {
                g.set(row: 22, cols: [5], "W"); g.set(row: 21, cols: [cols - 6], "W")
            }

        case .stand:
            // Standing focus reads as attentive stillness; break status still sips via pose.
            break
        }
    }
}

// MARK: - AvatarPose

enum AvatarPose: String, CaseIterable {
    case stand
    case sitTypingFront
    case coffee
    case phone
    case celebrate
}

// MARK: - v3 material rules + palette

extension PixelMaterialRules.Rules {
    static let avatarV3 = PixelMaterialRules.Rules(
        isEmpty: { $0 == "." || $0 == " " },
        isFlat: { "EeumbWgfho".contains($0) },
        group: { ch in
            switch ch {
            case ".", " ":           return 0
            case "S", "m", "b", "u": return 1
            case "H", "h":           return 2
            case "O", "c", "t", "o": return 3
            case "L":                return 4
            case "w", "f", "F":      return 5
            case "G", "A":           return 6
            case "K", "W", "g":      return 7
            default:                 return 8
            }
        }
    )
}

extension PixelPalette {
    static func avatarV3(_ a: CharacterAppearance) -> PixelPalette {
        PixelPalette([
            "H": PixelRGBA(a.hairColour.colour),
            "h": PixelRGBA(a.hairColour.colour.darkened(0.30)),          // fringe under-shadow
            "S": PixelRGBA(a.skinTone.colour),
            "E": PixelRGBA(Color(white: 0.98)),                          // eye catch-light
            "e": PixelRGBA(Color(red: 0.16, green: 0.12, blue: 0.11)),   // big pupil mass
            "m": PixelRGBA(a.skinTone.colour.darkened(0.42)),
            "b": PixelRGBA(a.skinTone.colour.darkened(0.24)),
            "u": PixelRGBA(Color(red: 0.94, green: 0.62, blue: 0.60)),
            "O": PixelRGBA(a.accentColour.colour),
            "o": PixelRGBA(a.accentColour.colour.darkened(0.22)),        // sleeve seam
            "c": PixelRGBA(a.accentColour.colour.lightened(0.28)),
            "t": PixelRGBA(Theme.Colour.buttonFill),
            "L": PixelRGBA(a.bottomStyle.colour),                        // bottoms (per style)
            "w": PixelRGBA(a.shoeStyle.upperColour),                     // shoe upper (per style)
            "f": PixelRGBA(Color(red: 0.22, green: 0.19, blue: 0.17)),   // sole
            "F": PixelRGBA(Color(red: 0.15, green: 0.12, blue: 0.11)),
            "G": PixelRGBA(Theme.Colour.buttonFill),
            "A": PixelRGBA(a.accentColour.colour),
            "g": PixelRGBA(Theme.Colour.accentTeal),
            "W": PixelRGBA(.white),
            "K": PixelRGBA(Color(red: 0.85, green: 0.84, blue: 0.82)),
        ])
    }
}
