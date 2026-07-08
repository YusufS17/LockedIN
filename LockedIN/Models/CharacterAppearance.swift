import Foundation
import SwiftUI

// MARK: - CharacterAppearance (D-21, D-21b, ONB-02, ONB-04)
//
// The user's avatar configuration. Codable for UserDefaults persistence (ONB-04).
// Equatable for live-preview change detection in the customizer.
//
// v3 expands the single OutfitStyle axis into TOP / BOTTOMS / SHOES / FACE (per the
// customizer design mockup). `outfitStyle` survives as a legacy bridge:
//   - old saved characters (no new keys) decode via the outfit→wardrobe mapping
//   - setting it (old customizer UI, presets) maps onto the new axes
//   - it is still encoded, so a rollback to an older build loses nothing

struct CharacterAppearance: Codable, Equatable {
    var skinTone:    SkinTone
    var hairStyle:   HairStyle
    var hairColour:  HairColour
    var faceStyle:   FaceStyle   = .neutral
    var topStyle:    TopStyle    = .tee
    var bottomStyle: BottomStyle = .jeans
    var shoeStyle:   ShoeStyle   = .sneakers
    var accentColour: AccentColour
    var accessory:   Accessory = .none      // cosmetic overlay (some coin-gated)

    /// Legacy single-axis outfit. Setting it re-derives the wardrobe axes.
    var outfitStyle: OutfitStyle {
        didSet {
            let w = Self.wardrobe(for: outfitStyle)
            topStyle = w.top; bottomStyle = w.bottom; shoeStyle = w.shoes
        }
    }

    /// Legacy-signature initialiser — all existing call sites (presets, catalog,
    /// customizer previews) construct through here and get mapped wardrobe axes.
    init(skinTone: SkinTone, hairStyle: HairStyle, hairColour: HairColour,
         outfitStyle: OutfitStyle, accentColour: AccentColour, accessory: Accessory = .none) {
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.hairColour = hairColour
        self.outfitStyle = outfitStyle
        self.accentColour = accentColour
        self.accessory = accessory
        let w = Self.wardrobe(for: outfitStyle)
        self.topStyle = w.top; self.bottomStyle = w.bottom; self.shoeStyle = w.shoes
    }

    /// Full-axis initialiser for the v3 customizer.
    init(skinTone: SkinTone, hairStyle: HairStyle, hairColour: HairColour,
         faceStyle: FaceStyle, topStyle: TopStyle, bottomStyle: BottomStyle,
         shoeStyle: ShoeStyle, accentColour: AccentColour, accessory: Accessory) {
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.hairColour = hairColour
        self.faceStyle = faceStyle
        self.topStyle = topStyle
        self.bottomStyle = bottomStyle
        self.shoeStyle = shoeStyle
        self.accentColour = accentColour
        self.accessory = accessory
        self.outfitStyle = Self.legacyOutfit(for: topStyle)
    }

    static func wardrobe(for outfit: OutfitStyle) -> (top: TopStyle, bottom: BottomStyle, shoes: ShoeStyle) {
        switch outfit {
        case .casual:   return (.tee,    .jeans,   .sneakers)
        case .academic: return (.jumper, .chinos,  .slipOns)
        case .hoodie:   return (.hoodie, .joggers, .sneakers)
        case .smart:    return (.shirt,  .chinos,  .slipOns)
        }
    }

    static func legacyOutfit(for top: TopStyle) -> OutfitStyle {
        switch top {
        case .hoodie:        return .hoodie
        case .jumper:        return .academic
        case .shirt:         return .smart
        case .tee, .jacket:  return .casual
        }
    }

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

    /// A random appearance from FREE options plus any owned premium cosmetics.
    /// Deterministic given the same generator; UI passes SystemRandomNumberGenerator.
    static func randomised(owned: Set<String>, using generator: inout some RandomNumberGenerator) -> CharacterAppearance {
        func allowed<T: CaseIterable & Hashable>(_ all: T.Type, id: (T) -> String?) -> [T] {
            T.allCases.filter { option in
                guard let cid = id(option) else { return true }
                return !CosmeticCatalog.isPremium(cid) || owned.contains(cid)
            }
        }
        let hairColours = allowed(HairColour.self) { CosmeticCatalog.id(hairColour: $0) }
        let hairStyles  = allowed(HairStyle.self)  { CosmeticCatalog.id(hairStyle: $0) }
        let accessories = allowed(Accessory.self)  { $0 == .none ? nil : CosmeticCatalog.id(accessory: $0) }
        return CharacterAppearance(
            skinTone: SkinTone.allCases.randomElement(using: &generator)!,
            hairStyle: hairStyles.randomElement(using: &generator) ?? .short,
            hairColour: hairColours.randomElement(using: &generator) ?? .brown,
            faceStyle: FaceStyle.allCases.randomElement(using: &generator)!,
            topStyle: TopStyle.allCases.randomElement(using: &generator)!,
            bottomStyle: BottomStyle.allCases.randomElement(using: &generator)!,
            shoeStyle: ShoeStyle.allCases.randomElement(using: &generator)!,
            accentColour: AccentColour.allCases.randomElement(using: &generator)!,
            accessory: accessories.randomElement(using: &generator) ?? .none
        )
    }
}

// MARK: - Forward-compatible decoding
//
// Defined in an extension so the initialisers above are preserved. Every field decodes
// with a fallback; when the new wardrobe keys are absent (pre-split saves) they are
// derived from the legacy outfitStyle, so no saved character ever changes appearance.

extension CharacterAppearance {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let skin    = try c.decodeIfPresent(SkinTone.self,     forKey: .skinTone)     ?? .medium
        let hair    = try c.decodeIfPresent(HairStyle.self,    forKey: .hairStyle)    ?? .short
        let hairC   = try c.decodeIfPresent(HairColour.self,   forKey: .hairColour)   ?? .brown
        let outfit  = try c.decodeIfPresent(OutfitStyle.self,  forKey: .outfitStyle)  ?? .casual
        let accent  = try c.decodeIfPresent(AccentColour.self, forKey: .accentColour) ?? .amber
        let acc     = try c.decodeIfPresent(Accessory.self,    forKey: .accessory)    ?? .none
        let mapped  = Self.wardrobe(for: outfit)
        self.init(
            skinTone: skin, hairStyle: hair, hairColour: hairC,
            faceStyle: try c.decodeIfPresent(FaceStyle.self, forKey: .faceStyle) ?? .neutral,
            topStyle: try c.decodeIfPresent(TopStyle.self, forKey: .topStyle) ?? mapped.top,
            bottomStyle: try c.decodeIfPresent(BottomStyle.self, forKey: .bottomStyle) ?? mapped.bottom,
            shoeStyle: try c.decodeIfPresent(ShoeStyle.self, forKey: .shoeStyle) ?? mapped.shoes,
            accentColour: accent, accessory: acc
        )
        // Preserve the exact stored legacy value (init derived it from topStyle).
        self.outfitStyle = outfit
    }
}

// MARK: - VoiceOver Description

extension CharacterAppearance {
    /// Human-readable description for VoiceOver (AvatarView accessibilityLabel).
    var description: String {
        "\(skinTone.displayName) skin, \(hairStyle.displayName) \(hairColour.displayName) hair, \(topStyle.displayName), \(bottomStyle.displayName), \(shoeStyle.displayName)"
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

enum FaceStyle: String, Codable, CaseIterable {
    case neutral, smile, freckles, lashes, stern
    var displayName: String { rawValue.capitalized }
}

enum TopStyle: String, Codable, CaseIterable {
    case tee, hoodie, jumper, jacket, shirt
    var displayName: String {
        switch self {
        case .tee: return "Tee"
        default:   return rawValue.capitalized
        }
    }
}

enum BottomStyle: String, Codable, CaseIterable {
    case jeans, joggers, chinos, shorts, skirt
    var displayName: String { rawValue.capitalized }
}

enum ShoeStyle: String, Codable, CaseIterable {
    case sneakers, boots, slipOns
    var displayName: String {
        switch self {
        case .slipOns: return "Slip-ons"
        default:       return rawValue.capitalized
        }
    }
}

/// Legacy single-axis outfit — kept for decode compatibility + rollback safety.
enum OutfitStyle: String, Codable, CaseIterable {
    case casual, academic, hoodie, smart
    var displayName: String { rawValue.capitalized }
}

enum AccentColour: String, Codable, CaseIterable {
    case amber, teal, rose, lavender, indigo, forest, charcoal, cream
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
        case .indigo:   return Color(red: 0.36, green: 0.38, blue: 0.65)    // #5C61A6
        case .forest:   return Color(red: 0.31, green: 0.49, blue: 0.28)    // #4F7D47
        case .charcoal: return Color(red: 0.27, green: 0.24, blue: 0.22)    // #453D38
        case .cream:    return Color(red: 0.93, green: 0.89, blue: 0.80)    // #EDE3CD
        }
    }
}

extension BottomStyle {
    /// Fixed garment colours — bottoms don't take the accent tint.
    var colour: Color {
        switch self {
        case .jeans, .shorts: return Color(red: 0.28, green: 0.32, blue: 0.44)   // denim
        case .joggers:        return Color(red: 0.52, green: 0.48, blue: 0.44)   // warm grey
        case .chinos:         return Color(red: 0.72, green: 0.60, blue: 0.42)   // tan
        case .skirt:          return Color(red: 0.42, green: 0.30, blue: 0.32)   // plum
        }
    }
}

extension ShoeStyle {
    var upperColour: Color {
        switch self {
        case .sneakers: return Color(white: 0.94)
        case .boots:    return Color(red: 0.42, green: 0.28, blue: 0.18)   // leather
        case .slipOns:  return Color(red: 0.30, green: 0.27, blue: 0.25)   // dark canvas
        }
    }
}
