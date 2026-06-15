import SwiftUI

// MARK: - BuildingType — the district's building catalogue (world-layer §10)

enum BuildingType: String, Codable, CaseIterable, Identifiable {
    case libraryHub, languageCafe, scienceLab, dormCommons
    case engineeringTower, historyHall, creativeStudio, courtyard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .libraryHub:       return "Library Hub"
        case .languageCafe:     return "Language Café"
        case .scienceLab:       return "Science Lab"
        case .dormCommons:      return "Dorm Commons"
        case .engineeringTower:  return "Engineering Tower"
        case .historyHall:      return "History Hall"
        case .creativeStudio:   return "Creative Studio"
        case .courtyard:        return "Student Courtyard"
        }
    }

    /// SF Symbol used until bespoke pixel-art building sprites are authored.
    var symbol: String {
        switch self {
        case .libraryHub:       return "books.vertical.fill"
        case .languageCafe:     return "cup.and.saucer.fill"
        case .scienceLab:       return "testtube.2"
        case .dormCommons:      return "bed.double.fill"
        case .engineeringTower:  return "wrench.and.screwdriver.fill"
        case .historyHall:      return "building.columns.fill"
        case .creativeStudio:   return "paintpalette.fill"
        case .courtyard:        return "tree.fill"
        }
    }

    var tint: Color {
        switch self {
        case .libraryHub:       return Theme.Colour.accent
        case .languageCafe:     return Theme.Colour.accentRose
        case .scienceLab:       return Theme.Colour.accentTeal
        case .dormCommons:      return Theme.Colour.accentLavender
        case .engineeringTower:  return Theme.Colour.accent
        case .historyHall:      return Theme.Colour.accentTeal
        case .creativeStudio:   return Theme.Colour.accentRose
        case .courtyard:        return Theme.Colour.plantGreen
        }
    }
}

// MARK: - WorldBuilding — one building's progression state

struct WorldBuilding: Codable, Equatable, Identifiable {
    let type: BuildingType
    var level: Int          // 0 = locked/unbuilt, 1+ = built tiers
    var progressXP: Int     // XP banked toward the next level
    var unlocked: Bool

    var id: String { type.rawValue }

    /// XP needed to reach the next level (grows per tier).
    var requiredXP: Int { 200 + level * 150 }

    var progress: Double {
        requiredXP > 0 ? min(1, Double(progressXP) / Double(requiredXP)) : 0
    }
}

// MARK: - WorldState — the persisted world aggregate

struct WorldState: Codable, Equatable {
    var progression: Progression
    var buildings: [WorldBuilding]
    var activeBuildingID: String     // BuildingType.rawValue receiving contributions

    var activeBuilding: WorldBuilding? {
        buildings.first { $0.id == activeBuildingID }
    }

    /// Fresh world: Library Hub unlocked + active, everything else locked.
    static var seeded: WorldState {
        let buildings = BuildingType.allCases.map { type in
            WorldBuilding(type: type,
                          level: type == .libraryHub ? 1 : 0,
                          progressXP: 0,
                          unlocked: type == .libraryHub)
        }
        return WorldState(progression: Progression(),
                          buildings: buildings,
                          activeBuildingID: BuildingType.libraryHub.rawValue)
    }
}
