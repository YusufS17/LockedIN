import Foundation

// MARK: - StudyCharacter — a pickable character in the curated gallery
//
// SpriteAvatarView renders the editable appearance through PixelKit. Asset names
// are retained as legacy metadata; adding a PNG does not switch the renderer.
// Generated character boards are reference concepts, not production sprite layers.

struct StudyCharacter: Identifiable, Equatable, Codable {
    let id: String                 // stable id, e.g. "maya" (persisted)
    let name: String               // default display name
    let spriteAsset: String        // legacy base sprite asset name
    let fallback: CharacterAppearance  // appearance used by the current PixelKit renderer

    /// Per-state sprite asset name, by convention "<spriteAsset>_<state>"
    /// (e.g. "char_maya_focused"). Legacy metadata, not a renderer lookup.
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
