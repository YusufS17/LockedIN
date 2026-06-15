import SwiftUI

// MARK: - SpriteAvatarView — renders a real pixel sprite, or falls back gracefully
//
// If the character's pixel-art PNG exists in the asset catalog it is rendered crisply
// (`.interpolation(.none)`); otherwise it falls back to the code-drawn `AvatarView` so
// the app always works. Optionally overlays a non-colour-only status badge (icon + ring
// + the label is provided by callers) for live session states.
//
// Resolution order for the sprite image:
//   1. per-state pose  "<spriteAsset>_<state>"  (e.g. char_maya_break)
//   2. base sprite     "<spriteAsset>"          (e.g. char_maya)
//   3. code-drawn AvatarView(appearance: fallback)

struct SpriteAvatarView: View {

    let character: StudyCharacter
    var status: AvatarStatus = .idle
    var size: CGFloat = 80
    var showStatusBadge: Bool = false

    private var resolvedAssetName: String? {
        let pose = character.poseAsset(for: status)
        if UIImage(named: pose) != nil { return pose }
        if UIImage(named: character.spriteAsset) != nil { return character.spriteAsset }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let asset = resolvedAssetName {
                Image(asset)
                    .interpolation(.none)        // crisp pixel art (RESEARCH pitfall 3)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                PixelAvatarView(appearance: character.fallback, status: status, size: size)
            }

            if showStatusBadge, status != .idle, let symbol = status.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: max(10, size * 0.22), weight: .bold))
                    .foregroundStyle(.white)
                    .padding(max(3, size * 0.06))
                    .background(Circle().fill(status.ringColour))
                    .overlay(Circle().strokeBorder(Theme.Colour.surface, lineWidth: 1.5))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("Sprite avatars (fallback)") {
    HStack(spacing: 16) {
        SpriteAvatarView(character: CharacterCatalog.character(id: "maya"), status: .focused, size: 80, showStatusBadge: true)
        SpriteAvatarView(character: CharacterCatalog.character(id: "sam"), status: .distracted, size: 80, showStatusBadge: true)
    }
    .padding()
    .background(Theme.Colour.background)
}
