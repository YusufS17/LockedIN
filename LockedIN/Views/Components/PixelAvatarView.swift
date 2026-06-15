import SwiftUI

// MARK: - PixelAvatarView — code-drawn pixel-art student sprite (deep)
//
// A parametric full-body pixel character rendered entirely in SwiftUI `Canvas` (no PNG
// assets). A 12×16 grid is assembled from a base body, a hair-style mask (6 styles), an
// outfit motif (4 styles), an accessory overlay (glasses / headphones / cap / beanie),
// and a status-driven face, then recoloured from the character's `CharacterAppearance`
// (skin / hair / outfit-accent). Eyes have whites + pupils, the body has legs and shoes,
// and outfits carry collars / ties / hoods — crisp at any size, themeable, expressive.
//
// Universal fallback behind `SpriteAvatarView`; real `char_*.png` override when present.
//
// Legend: '.' clear  H hair  h hair-hi  S skin  k skin-shade  E eye-white  e pupil
//         m mouth  O outfit  o outfit-shade  c collar(light)  t tie(dark)
//         P trousers  F shoe  G dark-accessory  A accent-accessory  W white

struct PixelAvatarView: View {
    let appearance: CharacterAppearance
    var status: AvatarStatus = .idle
    var size: CGFloat = 80

    private let cols = 12
    private let rows = 16

    var body: some View {
        Canvas { ctx, canvasSize in
            let grid = PixelSprite.grid(appearance: appearance, status: status)
            let cell = min(canvasSize.width / CGFloat(cols), canvasSize.height / CGFloat(rows))
            let ox = (canvasSize.width - cell * CGFloat(cols)) / 2
            let oy = (canvasSize.height - cell * CGFloat(rows)) / 2
            for r in 0..<grid.count {
                for (c, ch) in grid[r].enumerated() {
                    guard let colour = colour(for: ch) else { continue }
                    let rect = CGRect(x: ox + CGFloat(c) * cell,
                                      y: oy + CGFloat(r) * cell,
                                      width: cell + 0.6, height: cell + 0.6)
                    ctx.fill(Path(rect), with: .color(colour))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")
    }

    private func colour(for ch: Character) -> Color? {
        switch ch {
        case "H": return appearance.hairColour.colour
        case "h": return appearance.hairColour.colour.lightened(0.24)
        case "S": return appearance.skinTone.colour
        case "k": return appearance.skinTone.colour.darkened(0.16)
        case "E": return Color(white: 0.97)
        case "e": return Color(red: 0.13, green: 0.10, blue: 0.09)
        case "m": return appearance.skinTone.colour.darkened(0.32)
        case "O": return appearance.accentColour.colour
        case "o": return appearance.accentColour.colour.darkened(0.20)
        case "c": return Theme.Colour.surface
        case "t": return Theme.Colour.buttonFill
        case "P": return Color(red: 0.27, green: 0.31, blue: 0.42)   // denim trousers
        case "F": return Color(red: 0.13, green: 0.11, blue: 0.10)   // shoes
        case "G": return Theme.Colour.buttonFill                     // dark frames / headphones
        case "A": return appearance.accentColour.colour              // cap / beanie
        case "W": return .white
        default:  return nil
        }
    }
}

// MARK: - PixelSprite — grid assembly

enum PixelSprite {

    /// Short-hair, casual, neutral base. 12 wide × 16 tall.
    private static let base: [String] = [
        "...HHHHHH...",   // 0
        "..HHHHHHHH..",   // 1
        ".HHHHHHHHHH.",   // 2
        ".HHSSSSSSHH.",   // 3
        ".HSSSSSSSSH.",   // 4
        ".SSEeSSEeSS.",   // 5  eyes
        ".SSSSSSSSSS.",   // 6
        ".SSSSmmSSSS.",   // 7  mouth
        "..SSSSSSSS..",   // 8  chin
        "...OOOOOO...",   // 9  shoulders
        ".OOOOOOOOOO.",   // 10
        "OOOOOOOOOOOO",   // 11 torso
        "SOOOOOOOOOOS",   // 12 hands
        ".OOOOOOOOOO.",   // 13
        "..PPP..PPP..",   // 14 legs
        "..FFF..FFF.."    // 15 shoes
    ]

    static func grid(appearance: CharacterAppearance, status: AvatarStatus) -> [[Character]] {
        var g = base.map { Array($0) }
        applyHair(&g, appearance.hairStyle)
        applyOutfit(&g, appearance.outfitStyle)
        applyAccessory(&g, appearance.accessory)
        applyFace(&g, status)
        return g
    }

    // MARK: Hair (6 styles)

    private static func applyHair(_ g: inout [[Character]], _ hair: HairStyle) {
        switch hair {
        case .short:
            break

        case .buzz:
            // Tight to the skull: drop the crown volume.
            set(&g, 0, Array(0..<12), ".")
            set(&g, 1, [0, 1, 2, 9, 10, 11], ".")

        case .curly:
            set(&g, 0, [2, 9], "H"); set(&g, 0, [1, 10], "h")
            set(&g, 1, [1, 10], "H")
            set(&g, 2, [0, 11], "H")
            set(&g, 2, [3, 8], "h"); set(&g, 3, [4, 7], "h")

        case .afro:
            set(&g, 0, [1, 2, 9, 10], "H")
            set(&g, 1, [0, 1, 10, 11], "H")
            set(&g, 2, [0, 11], "H")
            set(&g, 4, [0, 11], "H")
            set(&g, 5, [0, 11], "H")
            set(&g, 6, [0, 11], "H")

        case .long:
            for r in 5...11 { set(&g, r, [0, 11], "H") }
            set(&g, 12, [0, 11], "H")

        case .tied:
            // Pulled-back: small top bun, sleek sides.
            set(&g, 0, [3, 4, 7, 8], ".")
            set(&g, 0, [5, 6], "h")
            set(&g, 5, [0, 11], "H")
        }
    }

    // MARK: Outfit motifs (torso rows 9–13)

    private static func applyOutfit(_ g: inout [[Character]], _ outfit: OutfitStyle) {
        switch outfit {
        case .casual:
            set(&g, 13, [1, 10], "o")

        case .academic:
            set(&g, 9, [4, 7], "c")
            set(&g, 10, [5, 6], "c")

        case .hoodie:
            set(&g, 9, [2, 9], "o")
            set(&g, 10, [2, 9], "o")
            set(&g, 11, [5, 6], "W")   // drawstrings

        case .smart:
            set(&g, 9, [4, 7], "c")
            set(&g, 10, [5, 6], "t")
            set(&g, 11, [5, 6], "t")
        }
    }

    // MARK: Accessories

    private static func applyAccessory(_ g: inout [[Character]], _ accessory: Accessory) {
        switch accessory {
        case .none:
            break

        case .glasses:
            // Frames around both eyes + nose bridge.
            set(&g, 5, [2, 5, 6, 9], "G")

        case .headphones:
            set(&g, 4, [0, 11], "G")   // ear cups
            set(&g, 5, [0, 11], "G")
            set(&g, 1, [0, 11], "G")   // band ends
            set(&g, 0, [1, 10], "G")

        case .cap:
            set(&g, 0, [3, 4, 5, 6, 7, 8], "A")
            set(&g, 1, [2, 3, 4, 5, 6, 7, 8, 9], "A")
            set(&g, 2, Array(1...10), "A")
            set(&g, 3, Array(1...10), "A")   // brim over the forehead

        case .beanie:
            set(&g, 0, Array(2...9), "A")
            set(&g, 1, Array(1...10), "A")
            set(&g, 2, Array(0...11), "A")
            set(&g, 3, Array(1...10), "A")   // folded band
        }
    }

    // MARK: Status faces

    private static func applyFace(_ g: inout [[Character]], _ status: AvatarStatus) {
        switch status {
        case .idle, .focused:
            break

        case .deepFocus:
            set(&g, 4, [3, 8], "k")             // furrowed brow
            set(&g, 7, [4, 5, 6, 7], "S")
            set(&g, 7, [5, 6], "m")             // flat, determined

        case .onBreak:
            set(&g, 7, [3, 4, 7, 8], "m")       // wide smile
            set(&g, 12, [0], "A")               // mug by the hand

        case .distracted:
            set(&g, 3, [10], "W"); set(&g, 4, [10], "W")   // sweat drop
            set(&g, 7, [4, 5, 6, 7], "S")
            set(&g, 7, [4, 7], "m")             // open frown

        case .finished:
            set(&g, 0, [1], "W"); set(&g, 1, [0], "W")     // sparkle
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

#Preview("Hair + accessories") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach(HairStyle.allCases, id: \.self) { h in
                    PixelAvatarView(appearance: CharacterAppearance(skinTone: .medium, hairStyle: h, hairColour: .brown, outfitStyle: .casual, accentColour: .teal), size: 56)
                }
            }
            HStack(spacing: 10) {
                ForEach(Accessory.allCases, id: \.self) { a in
                    PixelAvatarView(appearance: CharacterAppearance(skinTone: .light, hairStyle: .short, hairColour: .blonde, outfitStyle: .smart, accentColour: .rose, accessory: a), size: 56)
                }
            }
        }
        .padding()
    }
}
