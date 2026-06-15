import Foundation
import SwiftUI

// MARK: - CharacterAppearance (D-21, D-21b, ONB-02, ONB-04)
//
// The user's avatar configuration. Codable for UserDefaults persistence (ONB-04).
// Equatable for live-preview change detection in CharacterCreatorView.
// All option enums are CaseIterable to support ◀▶ cycling in the creator.

struct CharacterAppearance: Codable, Equatable {
    var skinTone:    SkinTone
    var hairStyle:   HairStyle
    var hairColour:  HairColour
    var outfitStyle: OutfitStyle
    var accentColour: AccentColour
    var accessory:   Accessory = .none      // cosmetic overlay (some coin-gated)

    // Default character — always valid; shown when user skips onboarding (D-27).
    static let `default` = CharacterAppearance(
        skinTone: .medium, hairStyle: .short, hairColour: .brown,
        outfitStyle: .casual, accentColour: .amber, accessory: .none
    )

    // Static seeded appearances for bots (RESEARCH.md Open Question Q3 — resolved)
    static let maya = CharacterAppearance(
        skinTone: .dark,   hairStyle: .long,  hairColour: .black,
        outfitStyle: .academic, accentColour: .teal, accessory: .glasses
    )
    static let leo = CharacterAppearance(
        skinTone: .light,  hairStyle: .short, hairColour: .blonde,
        outfitStyle: .hoodie,   accentColour: .lavender, accessory: .headphones
    )
    static let sam = CharacterAppearance(
        skinTone: .medium, hairStyle: .tied,  hairColour: .brown,
        outfitStyle: .smart,    accentColour: .rose, accessory: .none
    )
}

// MARK: - Forward-compatible decoding
//
// Defined in an extension so the memberwise initialiser is preserved. Every field is
// decoded with a fallback, so older saved characters (written before `accessory` and the
// new hair options existed) still load instead of being discarded to `.default`.

extension CharacterAppearance {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.skinTone     = try c.decodeIfPresent(SkinTone.self,     forKey: .skinTone)     ?? .medium
        self.hairStyle    = try c.decodeIfPresent(HairStyle.self,    forKey: .hairStyle)    ?? .short
        self.hairColour   = try c.decodeIfPresent(HairColour.self,   forKey: .hairColour)   ?? .brown
        self.outfitStyle  = try c.decodeIfPresent(OutfitStyle.self,  forKey: .outfitStyle)  ?? .casual
        self.accentColour = try c.decodeIfPresent(AccentColour.self, forKey: .accentColour) ?? .amber
        self.accessory    = try c.decodeIfPresent(Accessory.self,    forKey: .accessory)    ?? .none
    }
}

// MARK: - VoiceOver Description

extension CharacterAppearance {
    /// Human-readable description for VoiceOver (AvatarView accessibilityLabel).
    var description: String {
        "\(skinTone.displayName) skin, \(hairStyle.displayName) \(hairColour.displayName) hair, \(outfitStyle.displayName) outfit"
    }
}

// MARK: - Option Enums

enum SkinTone: String, Codable, CaseIterable {
    case light, medium, dark, deep
    var displayName: String { rawValue.capitalized }
}

enum HairStyle: String, Codable, CaseIterable {
    case short, buzz, curly, afro, long, tied
    var displayName: String { rawValue.capitalized }
}

enum HairColour: String, Codable, CaseIterable {
    case blonde, brown, black, silver, auburn, pink
    var displayName: String { rawValue.capitalized }
}

enum OutfitStyle: String, Codable, CaseIterable {
    case casual, academic, hoodie, smart
    var displayName: String { rawValue.capitalized }
}

enum AccentColour: String, Codable, CaseIterable {
    case amber, teal, rose, lavender
    var displayName: String { rawValue.capitalized }
}

// MARK: - Accessory (cosmetic overlay axis; some are coin-gated, see CosmeticCatalog)

enum Accessory: String, Codable, CaseIterable {
    case none, glasses, headphones, cap, beanie
    var displayName: String {
        switch self {
        case .none: return "None"
        default:    return rawValue.capitalized
        }
    }
}

// MARK: - Color Mapping Extensions (D-21a, AvatarView layer fills)

extension SkinTone {
    var colour: Color {
        switch self {
        case .light:  return Theme.Colour.skinLight
        case .medium: return Theme.Colour.skinMedium
        case .dark:   return Theme.Colour.skinDark
        case .deep:   return Theme.Colour.skinDeep
        }
    }
}

extension HairColour {
    var colour: Color {
        switch self {
        case .blonde: return Theme.Colour.hairBlonde
        case .brown:  return Theme.Colour.hairBrown
        case .black:  return Theme.Colour.hairBlack
        case .silver: return Theme.Colour.hairSilver
        case .auburn: return Color(red: 0.545, green: 0.224, blue: 0.157)   // #8B3928 warm auburn
        case .pink:   return Color(red: 0.914, green: 0.490, blue: 0.682)   // #E97DAE candy pink
        }
    }
}

extension AccentColour {
    var colour: Color {
        switch self {
        case .amber:    return Theme.Colour.accent
        case .teal:     return Theme.Colour.accentTeal
        case .rose:     return Theme.Colour.accentRose
        case .lavender: return Theme.Colour.accentLavender
        }
    }
}
