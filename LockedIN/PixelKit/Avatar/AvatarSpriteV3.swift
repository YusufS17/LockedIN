import SwiftUI

// MARK: - AvatarSpriteV3 — 48×64 layered study-world characters
//
// A compact game-like character family: a turned 25-row head above substantial
// garment silhouettes, offset legs and shoes. Hair, clothes, face, accessories and
// desk forearms remain independently editable layers. The 48×64 canvas and desk
// anchor coordinates stay stable for existing room compositions.
//
// Materials extend the v2 set:
//   H hair   h hair-shadow(flat)   S skin   E eye-highlight(flat)   e pupil(flat)
//   b brow   m mouth(flat)   u blush(flat)   O top   c top-trim   L bottoms
//   w shoe-white   f sole(flat)   W white detail   G dark accessory   A accent accessory
//   g glow(flat)   K mug

enum AvatarSpriteV3 {

    static let cols = 48
    static let rows = 64

    // MARK: Hair construction source — mirrored crown beneath hairstyle overlays.

    private static let hairCrownHalf: [String] = [
        "........................",
        "........................",
        ".................HHHHHHH",
        "...............HHHHHHHHH",
        ".............HHHHHHHHHHH",
        "............HHHHHHHHHHHH",
        "...........HHHHHHHHHHHHH",
        "..........HHHHHHHHHHHHHH",
        "..........HHHHHHHHHHHHHH",
        ".........HHHHHHHHHHHHHHH",
        ".........HHHHHHHHHHHHHHH",
        ".........HHHHHHHHHHHHHHH",
        ".........HHHHHHHHHHHHHHH",
        ".........HH.............",
        ".........H..............",
        ".........H..............",
    ]

    // MARK: - Assembly

    static func grid(appearance: CharacterAppearance,
                     pose: AvatarPose = .stand,
                     status: AvatarStatus = .idle,
                     frame: Int = 0,
                     layer: AvatarRenderLayer = .full) -> PixelGrid {
        var g = PixelGrid(cols: cols, rows: rows)
        drawOutfit(&g, appearance: appearance, seated: pose == .sitTypingFront)
        drawHead(&g, appearance: appearance, status: status, frame: frame)
        drawGesture(&g, pose: pose, frame: frame)
        if layer == .deskHands {
            for y in 0..<rows {
                for x in 0..<cols {
                    if pose != .sitTypingFront || !isDeskHandPixel(x: x, y: y) { g[x, y] = "." }
                }
            }
        }
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

    /// Head crop for roster rows, cards and the home greeting.
    static func portraitGrid(appearance: CharacterAppearance) -> PixelGrid {
        grid(appearance: appearance, pose: .stand, status: .idle, frame: 0)
            .subgrid(x: 6, y: 0, cols: 36, rows: 30)
    }

    /// A deliberately turned face: one near ear, broad near cheek, narrower far
    /// eye and an offset nose. Hair is a separate silhouette, not painted onto skin.
    private static func drawHead(_ g: inout PixelGrid, appearance a: CharacterAppearance,
                                 status: AvatarStatus, frame: Int) {
        let edges: [(Int,Int)] = [(19,29),(17,32),(16,33),(15,34),(15,34),(15,34),
                                 (15,34),(15,34),(15,34),(16,34),(16,34),(17,33),
                                 (18,33),(19,32),(20,31),(22,29)]
        for y in 8...23 {
            let (left,right) = edges[y-8]
            for x in left...right { g[x,y] = (x < 19 || y > 21) ? "s" : "S" }
        }
        for y in 14...18 { g.set(row:y,cols:[13,14,15],y == 14 || y == 18 ? "s" : "S") }
        g[14,16] = "s"
        // Taller near eye and compressed far eye; sparse catchlights retain dark eyes.
        for y in 14...17 { g.set(row:y,cols:[21,22,23,31,32],"e") }
        g[21,14] = "E"; g[31,14] = "E"
        g[21,17] = "S"; g[32,17] = "S"
        g.set(row:12,cols:[21,22,23,31,32],"b")
        g[29,17] = "s"; g[29,18] = "s"; g[28,19] = "s"
        g[28,17] = "n"; g[27,18] = "n"
        g[22,19] = "n"; g[23,19] = "n"; g[14,15] = "n"
        if a.skinTone == .dark || a.skinTone == .deep {
            g[20,15] = "E"; g[30,15] = "E"
        }
        g.set(row:21,cols:[26,27,28],"m")
        if a.faceStyle == .smile || status == .finished || status == .onBreak { g[29,20] = "m" }
        if a.faceStyle == .freckles { g.set(row:18,cols:[20,22,32],"b") }
        if a.faceStyle == .lashes { g.set(row:13,cols:[20,21,23,31,32,33],"e") }
        if a.faceStyle == .stern || status == .deepFocus { g.set(row:13,cols:[22,23,31],"b") }
        if (frame+1) % 18 == 0 {
            for y in 14...17 { g.set(row:y,cols:[21,22,23,31,32],"S") }
            g.set(row:16,cols:[21,22,23,31,32],"m")
            g.set(row:15,cols:[20,30],"S")
        }
        // Resample only the established hairstyle silhouettes. The face underneath
        // is newly authored; none of the old front-facing eyes or ears remain.
        var hair = mirroredBase()
        applyHair(&hair,a.hairStyle)
        applyMaterialDetails(&hair,appearance:a)
        for y in 0...32 {
            for x in 9...39 {
                let material = hair[Int((Double(x)-5.5)/0.79),Int(Double(y)/0.79)]
                if ![HairStyle.curly, .afro, .tied].contains(a.hairStyle), "HhI".contains(material) { g[x,y] = material }
            }
        }
        if a.hairStyle == .curly || a.hairStyle == .afro || a.hairStyle == .tied {
            drawSculptedHair(&g, style: a.hairStyle)
        }
        // Locks catch the same upper-left light as the shoulders. Deliberate
        // short runs describe individual clumps without uniform noisy stripes.
        if a.hairStyle == .short {
            g.set(row:4,cols:[18,19,20],"I")
            g.set(row:5,cols:[17,18],"I")
            g.set(row:6,cols:[16,17],"I")
            g.set(row:3,cols:[26,27],"I")
            g[25,4] = "I"; g[24,5] = "I"
            g.set(row:9,cols:[26,27,28],"h")
        }
        if a.hairStyle == .long {
            // Break the curtain into irregular overlapping locks and tapered tips.
            for y in 21...32 {
                for x in 9...14 where "HhI".contains(g[x,y]) {
                    if x < 11+(y-21)/5 { g[x,y] = "." }
                }
                for x in 34...39 where "HhI".contains(g[x,y]) {
                    if x > 37-(y-21)/4 { g[x,y] = "." }
                }
            }
            for y in 15...27 { if "HhI".contains(g[12,y]) { g[12,y] = "I" } }
            for y in 18...29 { if "HhI".contains(g[35,y]) { g[35,y] = "h" } }
            for y in 19...25 { g.set(row:y,cols:[14,15],"H") }
            g.set(row:26,cols:[15,16],"H"); g[16,27] = "h"
            g.set(row:22,cols:[13,14],"I"); g[14,23] = "I"
            g.set(row:26,cols:[34,35,36],"H")
            g.set(row:27,cols:[34,35],"H"); g[34,28] = "h"
        }
        switch a.accessory {
        case .none: break
        case .glasses:
            for y in 13...17 { g.set(row:y,cols:[19,25,30,34],"G") }
            for y in [13,18] { g.set(row:y,cols:Array(20...24)+Array(31...33),"G") }
            g.set(row:15,cols:Array(26...29),"G")
        case .headphones:
            g.set(row:2,cols:Array(19...28),"G")
            g.set(row:3,cols:[17,18,29,30],"G")
            for y in 12...18 { g.set(row:y,cols:[11,12,35,36],"G") }
        case .cap, .beanie:
            // Hats own their crown shape; they do not inherit an afro's outline.
            for y in 0...10 {
                for x in 7...40 where "HhI".contains(g[x,y]) { g[x,y] = "." }
            }
            for y in 9...13 {
                for x in 7...40 where (x < 12 || x > 35) && "HhI".contains(g[x,y]) { g[x,y] = "." }
            }
            let hatEdges = [(20,28),(17,31),(15,33),(14,34),(13,35),(13,35),(12,35),(12,35)]
            for y in 2...9 {
                let (left,right) = hatEdges[y-2]
                g.set(row:y,cols:Array(left...right),"A")
                g[left,y] = "c"
            }
            if a.accessory == .cap {
                g.set(row:10,cols:Array(14...37),"o")
                g.set(row:11,cols:Array(27...38),"A")
                g[26,3] = "c"; g[26,4] = "c"; g[26,5] = "c"
            } else {
                for y in 9...11 { g.set(row:y,cols:Array(12...35),"A") }
                for x in stride(from:14,through:33,by:3) { g[x,10] = "c"; g[x,11] = "o" }
            }
        }
    }

    /// Native-size curls retain a scalloped silhouette at phone scale. The bun
    /// sits behind the right crown so it reads as tied hair rather than a quiff.
    private static func drawSculptedHair(_ g: inout PixelGrid, style: HairStyle) {
        func clump(_ cx: Int, _ cy: Int, _ radius: Int) {
            for dy in -radius...radius {
                for dx in -radius...radius where dx*dx + dy*dy <= radius*radius + 1 {
                    g[cx+dx,cy+dy] = dy >= radius-1 ? "h" : "H"
                }
            }
            g[cx-1,cy-1] = "I"; g[cx,cy-2] = "I"
        }
        switch style {
        case .afro:
            // A tall, softly irregular halo with broad overlapping curls.
            for y in 4...11 { g.set(row:y,cols:Array(12...35),"H") }
            for (x,y,r) in [(16,4,4),(22,3,4),(28,3,4),(34,5,4),
                            (12,9,4),(36,10,4),(15,12,3),(21,9,4),(28,9,4),(33,10,3)] {
                clump(x,y,r)
            }
            g[12,16] = "h"; g[13,16] = "H"
        case .curly:
            // Shorter and closer to the scalp, with individual fringe curls.
            for y in 5...9 { g.set(row:y,cols:Array(14...33),"H") }
            for (x,y,r) in [(16,5,3),(21,3,3),(27,4,3),(32,6,3),
                            (13,10,3),(18,9,3),(24,8,3),(29,10,3),(34,11,2)] {
                clump(x,y,r)
            }
            g[14,14] = "h"; g[15,13] = "H"
        case .tied:
            clump(32,3,4)
            g.set(row:5,cols:[29,30,31],"h")
            let edges = [(20,27),(17,30),(15,32),(14,33),(13,34),(13,34),(13,34),(13,34)]
            for y in 3...10 {
                let (left,right) = edges[y-3]
                g.set(row:y,cols:Array(left...right),"H")
                g[right,y] = "h"
            }
            g.set(row:6,cols:[18,19,20,21],"I")
            g.set(row:7,cols:[16,17,18],"I")
            g.set(row:9,cols:[15,16],"I")
            for y in 10...17 { g.set(row:y,cols:[14,15],"H") }
            g.set(row:18,cols:[15,16],"H"); g[16,19] = "h"
            g.set(row:10,cols:[26,27,28,29,30],"h")
            g.set(row:11,cols:[29,30,31,32],"H")
        default: break
        }
    }

    /// A three-quarter outfit with broad sleeves, a lit front, shaded side plane,
    /// independent trousers and offset shoes. No clothing choice is a colour-only skin.
    private static func drawOutfit(_ g: inout PixelGrid, appearance a: CharacterAppearance, seated: Bool) {
        func bar(_ y: Int, _ left: Int, _ right: Int, _ material: Character) {
            g.set(row: y, cols: Array(left...right), material)
        }
        // Neck, shoulders and a generous garment silhouette.
        for y in 23...27 { bar(y, 21, 28, y > 24 ? "s" : "S") }
        let left = [18,16,14,13,12,12,12,12,12,12,12,12,13,13,13,14,14,15,15,15,16,16,17]
        let right = [29,31,33,34,35,35,35,35,35,35,35,35,35,35,34,34,34,33,33,33,32,32,31]
        for y in 26...48 {
            bar(y, left[y-26], right[y-26], "O")
            for x in left[y-26]...min(left[y-26]+2, right[y-26]) { g[x,y] = "c" }
            if y > 28 { bar(y, 30, right[y-26], "o") }
        }
        // Sleeve seams curve into the underarm; cuffs have a different material.
        for y in 31...41 { g[18,y] = "o"; g[30,y] = "o" }
        bar(30, 15, 18, "c")
        bar(41, 13, 17, "o"); bar(42,13,17,"c")
        bar(41,31,34,"o"); bar(42,31,34,"c")
        for y in 43...45 { bar(y,14,17,y == 45 ? "s" : "S"); bar(y,31,33,y == 45 ? "s" : "S") }
        for y in 46...48 { bar(y,18,30,y == 48 ? "o" : "O") }
        bar(47,19,28,"c")
        // Readable folds: deliberately placed, not a texture/noise overlay.
        bar(38,20,22,"c"); bar(39,20,21,"c")
        bar(44,27,29,"o"); bar(45,25,28,"o")
        switch a.topStyle {
        case .tee:
            for y in 36...42 { bar(y,13,17,"S"); bar(y,31,34,"s") }
            bar(35,12,17,"c"); bar(35,31,35,"c")
            bar(27,21,28,"o"); bar(28,23,27,"c")
        case .hoodie:
            bar(25,18,21,"o"); bar(25,28,31,"o")
            bar(26,17,21,"c"); bar(26,29,32,"c")
            bar(27,19,22,"o"); bar(27,28,31,"o")
            bar(28,21,23,"c"); bar(28,27,29,"c")
            for y in 29...34 { g[22,y] = "W" }
            for y in 29...32 { g[28,y] = "W" }
            bar(39,22,27,"o"); g[21,40] = "o"; g[28,40] = "o"
            bar(43,21,28,"o"); bar(42,22,27,"c")
        case .jumper:
            bar(26,20,29,"c"); bar(27,22,28,"o")
            for x in stride(from:18,through:30,by:2) { g[x,47] = "o" }
            bar(34,20,28,"c")
        case .jacket:
            for y in 27...46 { bar(y,24,27,"W"); g[23,y] = "o"; g[28,y] = "o" }
            bar(27,20,23,"c"); bar(28,21,24,"c"); bar(29,22,24,"c")
            bar(27,28,31,"c"); bar(28,28,30,"c"); bar(29,28,29,"c")
            bar(38,19,22,"o"); bar(39,19,22,"c")
            for y in [34,39,44] { g[28,y] = "t" }
        case .shirt:
            bar(27,20,23,"c"); bar(28,22,24,"c"); bar(27,28,30,"c")
            for y in 29...46 { g[26,y] = "c" }
            for y in [31,36,41,46] { g[26,y] = "t" }
            bar(33,28,30,"o"); bar(36,28,30,"o")
        }
        // Offset legs and shoe toes establish the same turn as the torso.
        for y in 49...57 {
            bar(y,18,23,"L"); bar(y,26,31,"L")
            g[23,y] = "l"; g[30,y] = "l"; g[31,y] = "l"
        }
        bar(49,18,31,"l"); bar(50,24,25,"L")
        bar(54,18,20,"l"); bar(55,27,29,"l")
        if a.bottomStyle == .shorts || a.bottomStyle == .skirt {
            for y in 54...57 { bar(y,18,22,"S"); bar(y,27,31,"s") }
        }
        if a.bottomStyle == .skirt {
            for y in 49...53 { bar(y,17-(y-49)/2,32+(y-49)/3,"L"); g[23,y] = "l"; g[29,y] = "l" }
            bar(53,15,33,"l")
        }
        if a.bottomStyle == .joggers { bar(57,18,23,"l"); bar(57,26,31,"l") }
        for y in 58...61 {
            bar(y,15,23,y == 61 ? "f" : "w")
            bar(y+1,25,34,y == 61 ? "f" : "w")
        }
        if a.shoeStyle == .boots {
            for y in 55...58 { bar(y,18,23,"w"); bar(y,26,31,"w") }
            bar(57,20,22,"F"); bar(58,28,30,"F")
        } else if a.shoeStyle == .sneakers {
            bar(58,18,21,"F"); bar(59,17,20,"W")
            bar(59,28,31,"F"); bar(60,27,30,"W")
        } else {
            bar(58,18,22,"L"); bar(59,27,31,"L")
        }
        if seated {
            // The arms bend forward from the shoulder. Remove standing wrists
            // completely before the two desk forearms are drawn in their own layer.
            for y in 39...45 {
                for x in 12...17 { g[x,y] = y < 43 ? "o" : "." }
                for x in 31...35 { g[x,y] = y < 42 && x < 34 ? "o" : "." }
            }
            for y in 32...39 { g.set(row:y,cols:[14,15,16],"c") }
            g.set(row:38,cols:[17,18,19],"o")
            // Seated feet tuck below the chair; retain independent garment materials.
            let standing = g
            for y in 51..<rows { for x in 0..<cols { g[x,y] = "." } }
            for y in 51...59 {
                let sourceY = min(62,y+3)
                for x in 14...35 { g[x,y] = standing[x,sourceY] }
            }
        }
    }

    /// Tapered forearms retain the established desk registration rectangles.
    /// The mask excludes torso pixels behind the wrists when compositing over desks.
    private static func isDeskHandPixel(x: Int, y: Int) -> Bool {
        switch y {
        case 35: return (16...18).contains(x)
        case 36: return (16...19).contains(x)
        case 37: return (17...20).contains(x)
        case 38: return (18...20).contains(x)
        case 39: return (19...20).contains(x) || (27...29).contains(x)
        case 40: return (27...30).contains(x)
        case 41: return (28...31).contains(x)
        case 42: return (29...31).contains(x)
        case 43: return (30...31).contains(x)
        default: return false
        }
    }

    private static func drawGesture(_ g: inout PixelGrid, pose: AvatarPose, frame: Int) {
        switch pose {
        case .sitTypingFront:
            for y in 35...43 {
                for x in 16...31 where isDeskHandPixel(x: x, y: y) {
                    let near = x >= 27
                    let cuff = near ? y <= 40 : y <= 36
                    g[x,y] = cuff ? "c" : "S"
                }
            }
            g[20,38] = "n"; g[31,42] = "n"
            g[19,39] = "s"; g[30,43] = "s"
            if frame % 2 == 0 { g[30,42] = "s"; g[19,38] = "s" }
        case .coffee:
            for y in 43...45 { g.set(row:y,cols:Array(13...17),".") }
            for y in 37...40 { g.set(row:y,cols:[15,16,17],"o") }
            for y in 34...39 { g.set(row:y, cols:Array(9...14), "K") }
            g.set(row:40, cols:Array(11...15), "S")
            g.set(row:35, cols:[8,15], "W"); g.set(row:37, cols:[8,15], "W")
            if frame % 4 < 2 { g[11,31] = "W"; g[12,29] = "W" }
        case .phone:
            for y in 43...45 { g.set(row:y,cols:Array(13...17),".") }
            for y in 40...42 { g.set(row:y,cols:[14,15,16],"S") }
            for y in 37...43 { g.set(row:y,cols:Array(10...14),"G") }
            for y in 38...41 { g.set(row:y,cols:[11,12,13],"g") }
        case .celebrate:
            for y in 31...45 {
                g.set(row:y,cols:Array(12...17)+Array(31...35),".")
            }
            for y in 22...29 {
                g.set(row:y,cols:Array(10...13)+Array(34...37),"O")
                g.set(row:y,cols:[10,34],"c")
            }
            g.set(row:28,cols:Array(13...18)+Array(30...35),"O")
            g.set(row:29,cols:Array(14...19)+Array(30...34),"O")
            for y in 19...21 { g.set(row:y,cols:[10,11,12,35,36,37],"S") }
            if frame % 2 == 0 { g[7,18] = "W"; g[40,17] = "W" }
        case .stand: break
        }
    }

    private static func mirroredBase() -> PixelGrid {
        let half = PixelGrid(rows: hairCrownHalf)
        var full = PixelGrid(cols: cols, rows: rows)
        full.stamp(half, atX: 0, y: 0)
        full.stamp(half.mirrored(), atX: half.cols, y: 0)
        return full
    }

    // MARK: Hair styles (restyle rows 0–15; long styles also drape rows 16+)

    private static func applyHair(_ g: inout PixelGrid, _ hair: HairStyle) {
        switch hair {
        case .short:
            // Authored asymmetrical locks: a silhouette and fringe, not a flat cap.
            for y in 0...15 {
                for x in 0..<cols where g[x, y] == "H" { g[x, y] = "." }
            }
            g.stamp(PixelGrid(rows: [
                "...............HH...................",
                "..........HH..HHHH...HH.............",
                ".........HHHHHHHHHHHHHHH............",
                "......HHHHHHHHHHHHHHHHHHHH..........",
                ".......HHHHHHHHHHHHHHHHHHHHH........",
                ".....HHHHHHHHHHHHHHHHHHHHHHHH.......",
                "....HHHHHHHHHHHHHHHHHHHHHHHHHH......",
                "...HHHHHHHHHHHHHHHHHHHHHHHHHHHH.....",
                "....HHHHHHHHHHHHHHHHHHHHHHHHHHHH....",
                "...HHHHHHHHHHHHHHHHHHHHHHHHHHHH.....",
                "..HHHHHHHHHHHHHHHHHHHHHHHHHHHHHH....",
                "...HHHHHHHHHHHHHHHHHHHHHHHHHHHH.....",
                "..HHHHHHHHHHHHHHHHHHHHHHHHHHHH......",
                "...HHHHHHHHH.HHHHHHH.HHHHHHHHH......",
                "...HHHH.HHH..HHHHHH...HHHHHHHH......",
                "...HHH..HH...HHHH.....HHH.HHHHH.....",
                "....HH..H.....HH.......H..HHH.......",
                "....H..........H..........HH........",
            ]), atX: 6, y: 0)

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
            for y in 12...37 {
                let left = y < 25 ? 7 : 6
                for x in left...11 { g[x, y] = "H" }
                for x in 36...(47 - left) { g[x, y] = "H" }
            }
            for y in 38...42 {
                g.set(row: y, cols: y < 41 ? [7, 8, 9, 38, 39, 40] : [8, 39], "H")
            }
            for y in 12...15 { g.set(row: y, cols: Array(10...(25 - y / 2)), "H") }

        case .tied:
            // Top-knot bun + clean sides.
            for x in 0..<cols where g[x, 2] == "H" { g[x, 2] = "." }
            g.set(row: 0, cols: [21, 22, 23, 24, 25, 26], "H")
            g.set(row: 1, cols: [20, 21, 22, 23, 24, 25, 26, 27], "H")
            g.set(row: 2, cols: [20, 21, 22, 23, 24, 25, 26, 27], "H")
        }
    }

    // MARK: Authored material detail

    private static func applyMaterialDetails(_ g: inout PixelGrid, appearance: CharacterAppearance) {
        let silhouette = g
        for y in 0..<rows {
            for x in 0..<cols where silhouette[x,y] == "H" {
                if silhouette[x,y+1] != "H" || x > 33 { g[x,y] = "h" }
                else if y > 3 && y < 11 && (x+y/2)%9 < 2 && x < 32 { g[x,y] = "I" }
                else if appearance.hairStyle == .long && y > 15 && (x == 8 || x == 38) { g[x,y] = "I" }
            }
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

enum AvatarRenderLayer: String {
    case full
    case deskHands
}

// MARK: - v3 material rules + palette

extension PixelMaterialRules.Rules {
    static let avatarV3 = PixelMaterialRules.Rules(
        isEmpty: { $0 == "." || $0 == " " },
        isFlat: { "EeumbWgfhosIln".contains($0) },
        group: { ch in
            switch ch {
            case ".", " ":           return 0
            case "S", "s", "n", "m", "b", "u": return 1
            case "H", "h", "I":           return 2
            case "O", "c", "t", "o": return 3
            case "L", "l":           return 4
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
            "s": PixelRGBA(a.skinTone.colour.darkened(0.16)),
            "n": PixelRGBA(a.skinTone.colour.lightened(a.skinTone == .deep ? 0.18 : 0.11)),
            "I": PixelRGBA(a.hairColour.colour.lightened(0.17)),
            "E": PixelRGBA(Color(white: 0.98)),                          // eye catch-light
            "e": PixelRGBA(Color(red: 0.16, green: 0.12, blue: 0.11)),   // compact pupil
            "m": PixelRGBA(a.skinTone == .deep ? a.skinTone.colour.lightened(0.24) : a.skinTone.colour.darkened(0.42)),
            "b": PixelRGBA(a.skinTone.colour.darkened(0.24)),
            "u": PixelRGBA(Color(red: 0.94, green: 0.62, blue: 0.60)),
            "O": PixelRGBA(a.accentColour.colour),
            "o": PixelRGBA(a.accentColour.colour.darkened(0.22)),        // sleeve seam
            "c": PixelRGBA(a.accentColour.colour.lightened(0.28)),
            "t": PixelRGBA(Theme.Colour.buttonFill),
            "L": PixelRGBA(a.bottomStyle.colour),                        // bottoms (per style)
            "l": PixelRGBA(a.bottomStyle.colour.darkened(0.24)),
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
