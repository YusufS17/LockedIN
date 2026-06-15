import SwiftUI

// MARK: - PersonalRoom — the customisable study room (world-layer §11–12)
//
// A fixed-slot room: every slot (floor, wall, rug, desk, chair, lamp, shelf, plant,
// poster, window) holds exactly one item chosen from that slot's catalogue. Most items
// are free; a handful are coin-gated (cosmetic-only, never pay-to-win — VISION economy).
// Pure value type — Codable, persisted inside WorldState. The renderer
// (IsometricRoomView) reads placements and draws the chosen variant per slot.

// MARK: - RoomSlot — the fixed customisation slots

enum RoomSlot: String, Codable, CaseIterable, Identifiable {
    case floor, wall, rug, desk, chair, lamp, shelf, plant, poster, window

    var id: String { rawValue }

    var title: String {
        switch self {
        case .floor:  return "Floor"
        case .wall:   return "Wall"
        case .rug:    return "Rug"
        case .desk:   return "Desk"
        case .chair:  return "Chair"
        case .lamp:   return "Lamp"
        case .shelf:  return "Shelf"
        case .plant:  return "Plant"
        case .poster: return "Poster"
        case .window: return "Window"
        }
    }

    /// SF Symbol used in the slot chip selector.
    var symbol: String {
        switch self {
        case .floor:  return "square.grid.3x3.fill"
        case .wall:   return "rectangle.fill"
        case .rug:    return "square.dashed"
        case .desk:   return "table.furniture.fill"
        case .chair:  return "chair.fill"
        case .lamp:   return "lamp.desk.fill"
        case .shelf:  return "books.vertical.fill"
        case .plant:  return "leaf.fill"
        case .poster: return "photo.fill"
        case .window: return "window.vertical.closed"
        }
    }
}

// MARK: - RoomItem — one catalogue option for a slot

struct RoomItem: Identifiable, Equatable {
    let id: String          // stable, namespaced: "rug.persian", "floor.oak", …
    let slot: RoomSlot
    let name: String
    let cost: Int           // LockedIN coins; 0 = free / default
    let tint: Color         // primary colour used by the renderer + swatch
    var variant: Int = 0    // optional shape variant within a slot (0 = base)

    var isPremium: Bool { cost > 0 }
}

// MARK: - RoomItemCatalog — every slot's options

enum RoomItemCatalog {

    /// All items, grouped by slot. First item in each slot is the free default.
    static let all: [RoomItem] = [
        // Floor — plank colour
        RoomItem(id: "floor.oak",    slot: .floor, name: "Oak",     cost: 0,  tint: Theme.Colour.surfaceMid),
        RoomItem(id: "floor.walnut", slot: .floor, name: "Walnut",  cost: 0,  tint: Color(red: 0.40, green: 0.28, blue: 0.18)),
        RoomItem(id: "floor.ash",    slot: .floor, name: "Ash",     cost: 15, tint: Color(red: 0.78, green: 0.74, blue: 0.66)),
        RoomItem(id: "floor.slate",  slot: .floor, name: "Slate",   cost: 20, tint: Color(red: 0.34, green: 0.36, blue: 0.40)),

        // Wall — paint
        RoomItem(id: "wall.cream",   slot: .wall, name: "Cream",    cost: 0,  tint: Theme.Colour.surface),
        RoomItem(id: "wall.sage",    slot: .wall, name: "Sage",     cost: 0,  tint: Color(red: 0.74, green: 0.78, blue: 0.66)),
        RoomItem(id: "wall.dusk",    slot: .wall, name: "Dusk",     cost: 15, tint: Color(red: 0.58, green: 0.55, blue: 0.70)),
        RoomItem(id: "wall.charcoal", slot: .wall, name: "Charcoal", cost: 25, tint: Color(red: 0.27, green: 0.25, blue: 0.24)),

        // Rug — under the desk (variant 0 = none)
        RoomItem(id: "rug.none",     slot: .rug, name: "None",      cost: 0,  tint: .clear, variant: 0),
        RoomItem(id: "rug.amber",    slot: .rug, name: "Amber",     cost: 0,  tint: Theme.Colour.accent, variant: 1),
        RoomItem(id: "rug.teal",     slot: .rug, name: "Teal",      cost: 10, tint: Theme.Colour.accentTeal, variant: 1),
        RoomItem(id: "rug.rose",     slot: .rug, name: "Rose round", cost: 20, tint: Theme.Colour.accentRose, variant: 2),

        // Desk — surface wood
        RoomItem(id: "desk.maple",   slot: .desk, name: "Maple",    cost: 0,  tint: Theme.Colour.surfaceMid),
        RoomItem(id: "desk.cherry",  slot: .desk, name: "Cherry",   cost: 0,  tint: Color(red: 0.52, green: 0.30, blue: 0.24)),
        RoomItem(id: "desk.onyx",    slot: .desk, name: "Onyx",     cost: 20, tint: Color(red: 0.20, green: 0.19, blue: 0.18)),

        // Chair (variant 0 = none / stool)
        RoomItem(id: "chair.stool",  slot: .chair, name: "Stool",   cost: 0,  tint: Theme.Colour.textSecondary, variant: 0),
        RoomItem(id: "chair.amber",  slot: .chair, name: "Amber",   cost: 0,  tint: Theme.Colour.accent, variant: 1),
        RoomItem(id: "chair.teal",   slot: .chair, name: "Teal",    cost: 10, tint: Theme.Colour.accentTeal, variant: 1),
        RoomItem(id: "chair.gamer",  slot: .chair, name: "Gamer",   cost: 25, tint: Theme.Colour.accentRose, variant: 2),

        // Lamp — glow colour
        RoomItem(id: "lamp.amber",   slot: .lamp, name: "Amber",    cost: 0,  tint: Theme.Colour.accentSoft),
        RoomItem(id: "lamp.teal",    slot: .lamp, name: "Teal",     cost: 0,  tint: Theme.Colour.accentTeal),
        RoomItem(id: "lamp.rose",    slot: .lamp, name: "Rose",     cost: 10, tint: Theme.Colour.accentRose),
        RoomItem(id: "lamp.lavender", slot: .lamp, name: "Lavender", cost: 15, tint: Theme.Colour.accentLavender),

        // Shelf — book-spine palette (variant picks a palette set in the renderer)
        RoomItem(id: "shelf.classic", slot: .shelf, name: "Classic", cost: 0,  tint: Theme.Colour.accent, variant: 0),
        RoomItem(id: "shelf.cool",    slot: .shelf, name: "Cool",    cost: 0,  tint: Theme.Colour.accentTeal, variant: 1),
        RoomItem(id: "shelf.warm",    slot: .shelf, name: "Warm",    cost: 10, tint: Theme.Colour.accentRose, variant: 2),

        // Plant (variant 0 = none)
        RoomItem(id: "plant.none",   slot: .plant, name: "None",    cost: 0,  tint: .clear, variant: 0),
        RoomItem(id: "plant.fern",   slot: .plant, name: "Fern",    cost: 0,  tint: Theme.Colour.plantGreen, variant: 1),
        RoomItem(id: "plant.cactus", slot: .plant, name: "Cactus",  cost: 10, tint: Color(red: 0.36, green: 0.55, blue: 0.36), variant: 2),
        RoomItem(id: "plant.bloom",  slot: .plant, name: "Bloom",   cost: 20, tint: Theme.Colour.accentRose, variant: 3),

        // Poster (variant 0 = none)
        RoomItem(id: "poster.none",  slot: .poster, name: "None",   cost: 0,  tint: .clear, variant: 0),
        RoomItem(id: "poster.focus", slot: .poster, name: "Focus",  cost: 0,  tint: Theme.Colour.accent, variant: 1),
        RoomItem(id: "poster.galaxy", slot: .poster, name: "Galaxy", cost: 15, tint: Theme.Colour.accentLavender, variant: 2),
        RoomItem(id: "poster.map",   slot: .poster, name: "Map",    cost: 20, tint: Theme.Colour.accentTeal, variant: 3),

        // Window — pane glow
        RoomItem(id: "window.night", slot: .window, name: "Night",  cost: 0,  tint: Theme.Colour.windowSlate),
        RoomItem(id: "window.dawn",  slot: .window, name: "Dawn",   cost: 0,  tint: Color(red: 0.86, green: 0.62, blue: 0.42)),
        RoomItem(id: "window.aurora", slot: .window, name: "Aurora", cost: 20, tint: Theme.Colour.accentTeal)
    ]

    static func items(for slot: RoomSlot) -> [RoomItem] {
        all.filter { $0.slot == slot }
    }

    static func item(id: String) -> RoomItem? {
        all.first { $0.id == id }
    }

    static func cost(for id: String) -> Int {
        item(id: id)?.cost ?? 0
    }

    /// The free default item for a slot (first one authored).
    static func defaultItem(for slot: RoomSlot) -> RoomItem {
        items(for: slot).first!
    }
}

// MARK: - PersonalRoom — chosen item per slot

struct PersonalRoom: Codable, Equatable {
    /// slot.rawValue → RoomItem.id
    var placements: [String: String]

    /// The item id placed in a slot, falling back to the slot's free default.
    func itemID(for slot: RoomSlot) -> String {
        placements[slot.rawValue] ?? RoomItemCatalog.defaultItem(for: slot).id
    }

    /// The resolved RoomItem in a slot (always non-nil — falls back to default).
    func item(for slot: RoomSlot) -> RoomItem {
        RoomItemCatalog.item(id: itemID(for: slot)) ?? RoomItemCatalog.defaultItem(for: slot)
    }

    /// Fresh room: every slot on its free default.
    static var seeded: PersonalRoom {
        var placements: [String: String] = [:]
        for slot in RoomSlot.allCases {
            placements[slot.rawValue] = RoomItemCatalog.defaultItem(for: slot).id
        }
        return PersonalRoom(placements: placements)
    }
}
