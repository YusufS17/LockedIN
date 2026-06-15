import Foundation

// MARK: - CosmeticCatalog — which customization options cost coins
//
// Most appearance options are free; a handful of premium cosmetics are gated behind
// LockedIN coins (cosmetic-only, never pay-to-win — VISION economy). Ownership is tracked
// by stable string ids in WorldState.ownedCosmetics; free items are always "owned".

enum CosmeticCatalog {

    /// Premium cosmetic ids → coin cost. Anything not listed is free (cost 0).
    static let premium: [String: Int] = [
        id(accessory: .headphones): 40,
        id(accessory: .cap):        30,
        id(accessory: .beanie):     30,
        id(hairColour: .pink):      25,
        id(hairColour: .auburn):    15,
        id(hairStyle: .afro):       20
    ]

    static func cost(for id: String) -> Int { premium[id] ?? 0 }
    static func isPremium(_ id: String) -> Bool { premium[id] != nil }

    // MARK: - Stable id builders (one namespace per axis)

    static func id(accessory: Accessory) -> String   { "accessory.\(accessory.rawValue)" }
    static func id(hairStyle: HairStyle) -> String    { "hairStyle.\(hairStyle.rawValue)" }
    static func id(hairColour: HairColour) -> String  { "hairColour.\(hairColour.rawValue)" }
    static func id(outfit: OutfitStyle) -> String     { "outfit.\(outfit.rawValue)" }
    static func id(skin: SkinTone) -> String          { "skin.\(skin.rawValue)" }
    static func id(accent: AccentColour) -> String    { "accent.\(accent.rawValue)" }
}
