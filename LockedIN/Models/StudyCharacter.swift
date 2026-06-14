import Foundation

// MARK: - StudyCharacter — a pickable character in the curated gallery
//
// Asset-driven: `spriteAsset` names a pixel-art PNG (added to Assets.xcassets, e.g.
// "char_maya"). If that image is present it is rendered as the real sprite; if not,
// `SpriteAvatarView` falls back to the code-drawn `AvatarView(appearance:)` so the app
// always works. Drop the real sprites in and they appear everywhere automatically.
//
// See .planning/reference/SPRITE-ASSETS-SPEC.md for the exact asset list + sizes.

struct StudyCharacter: Identifiable, Equatable {
    let id: String                 // stable id, e.g. "maya" (persisted)
    let name: String               // default display name
    let spriteAsset: String        // base sprite asset name (idle pose)
    let fallback: CharacterAppearance  // code-drawn fallback until the sprite exists

    /// Per-state sprite asset name, by convention "<spriteAsset>_<state>"
    /// (e.g. "char_maya_focused"). Falls back to the base sprite if absent.
    func poseAsset(for status: AvatarStatus) -> String {
        "\(spriteAsset)_\(status.assetSuffix)"
    }
}

// MARK: - Catalog

enum CharacterCatalog {

    static let all: [StudyCharacter] = [
        StudyCharacter(id: "maya", name: "Maya", spriteAsset: "char_maya", fallback: .maya),
        StudyCharacter(id: "leo",  name: "Leo",  spriteAsset: "char_leo",  fallback: .leo),
        StudyCharacter(id: "sam",  name: "Sam",  spriteAsset: "char_sam",  fallback: .sam),
        StudyCharacter(id: "ada",  name: "Ada",  spriteAsset: "char_ada",
            fallback: CharacterAppearance(skinTone: .medium, hairStyle: .curly, hairColour: .black, outfitStyle: .academic, accentColour: .teal)),
        StudyCharacter(id: "noah", name: "Noah", spriteAsset: "char_noah",
            fallback: CharacterAppearance(skinTone: .dark, hairStyle: .short, hairColour: .black, outfitStyle: .hoodie, accentColour: .amber)),
        StudyCharacter(id: "iris", name: "Iris", spriteAsset: "char_iris",
            fallback: CharacterAppearance(skinTone: .light, hairStyle: .long, hairColour: .blonde, outfitStyle: .smart, accentColour: .rose)),
        StudyCharacter(id: "kai",  name: "Kai",  spriteAsset: "char_kai",
            fallback: CharacterAppearance(skinTone: .deep, hairStyle: .tied, hairColour: .black, outfitStyle: .casual, accentColour: .lavender)),
        StudyCharacter(id: "mei",  name: "Mei",  spriteAsset: "char_mei",
            fallback: CharacterAppearance(skinTone: .medium, hairStyle: .long, hairColour: .brown, outfitStyle: .academic, accentColour: .rose))
    ]

    static func character(id: String) -> StudyCharacter {
        all.first { $0.id == id } ?? all[0]
    }

    static var first: StudyCharacter { all[0] }
}

// MARK: - AvatarStatus → asset suffix

extension AvatarStatus {
    /// Lowercase suffix used in per-state sprite asset names (e.g. char_maya_break).
    var assetSuffix: String {
        switch self {
        case .idle:       return "idle"
        case .focused:    return "focused"
        case .deepFocus:  return "deepfocus"
        case .onBreak:    return "break"
        case .distracted: return "distracted"
        case .finished:   return "finished"
        }
    }
}
