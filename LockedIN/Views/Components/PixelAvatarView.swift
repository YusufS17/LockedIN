import SwiftUI

// MARK: - PixelAvatarView — code-drawn pixel-art student sprite
//
// A parametric pixel character rendered entirely in SwiftUI `Canvas` (no PNG assets).
// A 12×14 pixel grid is assembled from a base body, a hair-style mask, an outfit motif,
// and a status-driven face, then recoloured from the character's `CharacterAppearance`
// (skin / hair / outfit-accent). Crisp at any size — each cell is a filled rect, so it
// scales like real pixel art with no interpolation blur.
//
// This is the universal fallback behind `SpriteAvatarView`; drop real `char_*.png` in
// and those take over, otherwise every avatar in the app is this sprite.
//
// Grid legend:
//   '.' transparent   H hair        h hair-highlight   S skin        k skin-shade
//   e  eye            m mouth        O outfit(accent)   o outfit-shade
//   c  collar/surface t tie/dark     W white            ' ' transparent

struct PixelAvatarView: View {
    let appearance: CharacterAppearance
    var status: AvatarStatus = .idle
    var size: CGFloat = 80

    private let cols = 12
    private let rows = 14

    var body: some View {
        Canvas { ctx, canvasSize in
            let grid = PixelSprite.grid(hair: appearance.hairStyle,
                                        outfit: appearance.outfitStyle,
                                        status: status)
            let cell = min(canvasSize.width / CGFloat(cols), canvasSize.height / CGFloat(rows))
            let ox = (canvasSize.width - cell * CGFloat(cols)) / 2
            let oy = (canvasSize.height - cell * CGFloat(rows)) / 2
            for r in 0..<grid.count {
                let line = grid[r]
                for (c, ch) in line.enumerated() {
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

    // MARK: - Palette mapping

    private func colour(for ch: Character) -> Color? {
        switch ch {
        case "H": return appearance.hairColour.colour
        case "h": return appearance.hairColour.colour.lightened(0.22)
        case "S": return appearance.skinTone.colour
        case "k": return appearance.skinTone.colour.darkened(0.18)
        case "e": return Color(red: 0.13, green: 0.10, blue: 0.09)
        case "m": return appearance.skinTone.colour.darkened(0.30)
        case "O": return appearance.accentColour.colour
        case "o": return appearance.accentColour.colour.darkened(0.20)
        case "c": return Theme.Colour.surface
        case "t": return Theme.Colour.buttonFill
        case "W": return .white
        default:  return nil    // '.' or space → transparent
        }
    }
}

// MARK: - PixelSprite — grid assembly

enum PixelSprite {

    /// Base body: face + torso, hair filled per style elsewhere. 12 wide × 14 tall.
    /// Hair cells ('H') here are the common skull cap; styles add/remove around it.
    private static let base: [String] = [
        "....HHHH....",   // 0  crown
        "..HHHHHHHH..",   // 1
        ".HHHHHHHHHH.",   // 2
        ".HHSSSSSSHH.",   // 3  forehead
        ".HSSSSSSSSH.",   // 4
        ".SSSSSSSSSS.",   // 5
        ".SeSSSSSSeS.",   // 6  eyes
        ".SSSSSSSSSS.",   // 7
        ".SSSSmmSSSS.",   // 8  mouth
        "..SSSSSSSS..",   // 9  chin
        "...OOOOOO...",   // 10 shoulders
        ".OOOOOOOOOO.",   // 11 torso
        "OOOOOOOOOOOO",   // 12 torso
        "SOoOOOOOOoOS"    // 13 hands + torso base
    ]

    static func grid(hair: HairStyle, outfit: OutfitStyle, status: AvatarStatus) -> [[Character]] {
        var g = base.map { Array($0) }
        applyHair(&g, hair)
        applyOutfit(&g, outfit)
        applyFace(&g, status)
        return g
    }

    // MARK: Hair styles

    private static func applyHair(_ g: inout [[Character]], _ hair: HairStyle) {
        switch hair {
        case .short:
            break   // base cap is already short

        case .curly:
            // Bumpy, voluminous top using highlights and rounded crown.
            set(&g, 0, [3, 4, 7, 8], "H")
            set(&g, 0, [5, 6], "h")
            set(&g, 1, [1, 2, 9, 10], "h")
            set(&g, 2, [0, 11], "H")
            set(&g, 3, [0, 11], "H")   // fuller temples

        case .long:
            // Hair falls down both sides past the shoulders.
            for r in 5...11 { set(&g, r, [0], "H"); set(&g, r, [11], "H") }
            set(&g, 12, [0, 11], "H")

        case .tied:
            // Sleek cap + top bun + a small tie band.
            set(&g, 0, [5, 6], "h")          // bun highlight
            set(&g, 1, [5, 6], "H")
            set(&g, 5, [0], "H"); set(&g, 5, [11], "H")   // short side bits
        }
    }

    // MARK: Outfit motifs (torso rows 10–13)

    private static func applyOutfit(_ g: inout [[Character]], _ outfit: OutfitStyle) {
        switch outfit {
        case .casual:
            break

        case .academic:
            // Open collar / lapels in surface colour forming a V.
            set(&g, 10, [4, 7], "c")
            set(&g, 11, [5, 6], "c")

        case .hoodie:
            // Hood ring around the neck + drawstrings.
            set(&g, 9, [2, 9], "o")
            set(&g, 10, [3, 8], "o")
            set(&g, 11, [5, 6], "W")   // drawstrings

        case .smart:
            // Collar + a dark tie down the centre.
            set(&g, 10, [4, 7], "c")
            set(&g, 11, [5, 6], "t")
            set(&g, 12, [5, 6], "t")
        }
    }

    // MARK: Status faces

    private static func applyFace(_ g: inout [[Character]], _ status: AvatarStatus) {
        switch status {
        case .idle, .focused:
            break   // base neutral face

        case .deepFocus:
            // Determined: flat mouth, subtle brow shadow above the eyes.
            set(&g, 5, [2, 9], "k")
            set(&g, 8, [4, 5, 6, 7], "S")
            set(&g, 8, [5, 6], "m")

        case .onBreak:
            // Relaxed smile + a little cup by the hand.
            set(&g, 8, [3, 8], "m")
            set(&g, 13, [1], "c")

        case .distracted:
            // Worried: sweat droplet + open frown.
            set(&g, 4, [10], "W")
            set(&g, 5, [10], "W")
            set(&g, 8, [4, 5, 6, 7], "S")
            set(&g, 8, [4, 7], "m")

        case .finished:
            // Crowned with a little sparkle.
            set(&g, 0, [1], "W")
            set(&g, 1, [0], "W")
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
        let a = UIColor(self)
        let b = UIColor(other)
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

#Preview("Pixel avatars — catalog") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        VStack(spacing: Theme.Spacing.lg) {
            Text("Pixel-art catalog").font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: Theme.Spacing.md) {
                ForEach(CharacterCatalog.all) { ch in
                    VStack(spacing: 4) {
                        PixelAvatarView(appearance: ch.fallback, status: .idle, size: 64)
                        Text(ch.name).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("Pixel avatar — statuses") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        HStack(spacing: Theme.Spacing.md) {
            ForEach([AvatarStatus.focused, .deepFocus, .onBreak, .distracted, .finished], id: \.rawValue) { s in
                VStack(spacing: 4) {
                    PixelAvatarView(appearance: .sam, status: s, size: 64)
                    Text(s.label).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
            }
        }
        .padding()
    }
}
