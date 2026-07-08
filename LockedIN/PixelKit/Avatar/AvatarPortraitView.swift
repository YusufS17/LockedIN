import SwiftUI

// MARK: - AvatarPortraitView — head-crop portrait for roster rows and cards
//
// A square crop of the v3 sprite's head (hair + face), baked once and cached.
// Used at small sizes: roster rows (~40pt), home greeting card, champion/culprit
// cards, friends rail. Static by design — no animation at these sizes.

struct AvatarPortraitView: View {
    let appearance: CharacterAppearance
    var size: CGFloat = 40
    /// Warm card behind the head, per the mockups' roster rows.
    var showsBackground: Bool = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(Theme.Colour.surfaceMid)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22)
                            .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
                    )
            }
            PixelSpriteView(
                cacheKey: Self.cacheKey(appearance: appearance),
                frameCount: 1,
                build: { _ in
                    PixelRenderer.bake(
                        grid: AvatarSpriteV3.portraitGrid(appearance: appearance),
                        palette: .avatarV3(appearance),
                        rules: .avatarV3,
                        outline: PixelRGBA(r: 31, g: 23, b: 20)
                    )
                },
                animated: false
            )
            .padding(size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Portrait: \(appearance.description)")
    }

    private static func cacheKey(appearance a: CharacterAppearance) -> String {
        "av3p|\(a.skinTone).\(a.hairStyle).\(a.hairColour).\(a.accentColour).\(a.accessory)"
    }
}

#Preview("Portraits") {
    ZStack {
        Theme.Colour.background.ignoresSafeArea()
        HStack(spacing: 12) {
            ForEach(CharacterCatalog.all) { ch in
                AvatarPortraitView(appearance: ch.fallback, size: 44)
            }
        }
        .padding()
    }
}
