import Foundation

enum ForfeitConfig { static let destination = "Fixture charity" }

@main
struct WorldSemanticChecks {
    static func main() throws {
        let suite = "LockedIN.world-semantic.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func reject(_ state: WorldState) throws {
            let bytes = try JSONEncoder().encode(state)
            defaults.set(bytes, forKey: WorldPersistence.persistenceKey)
            let store = WorldStore(defaults: defaults)
            assert(store.recoveryIssue != nil)
            store.reset()
            store.setActiveBuilding(.libraryHub)
            assert(!store.purchaseRoomItem("desk_oak"))
            assert(defaults.data(forKey: WorldPersistence.persistenceKey) == bytes)
        }
        var invalid = WorldState.seeded
        invalid.progression.focusXP = -1
        try reject(invalid)
        invalid = .seeded; invalid.progression.coins = Int.max; try reject(invalid)
        invalid = .seeded; invalid.progression.currentStreak = 1; try reject(invalid)
        invalid = .seeded; invalid.buildings[0].level = Int.max; try reject(invalid)
        invalid = .seeded; invalid.buildings[0].progressXP = -1; try reject(invalid)
        invalid = .seeded; invalid.buildings[0].progressXP = Int.max / 4; try reject(invalid)
        invalid = .seeded; invalid.buildings[0].progressXP = invalid.buildings[0].requiredXP; try reject(invalid)
        invalid = .seeded; invalid.buildings[1] = invalid.buildings[0]; try reject(invalid)
        invalid = .seeded; invalid.buildings.removeLast(); try reject(invalid)
        invalid = .seeded; invalid.activeBuildingID = "unknown"; try reject(invalid)
        invalid = .seeded; invalid.activeBuildingID = BuildingType.languageCafe.rawValue; try reject(invalid)
        invalid = .seeded; invalid.sessionRewards[UUID()] = RewardOutcome(focusXP: -1, coins: 0, passed: false, leveledUp: false, newLevel: 1, breakdown: []); try reject(invalid)
        var valid = WorldState.seeded
        valid.progression.focusXP = Int.max / 4
        valid.progression.coins = Int.max / 4
        valid.buildings[0].level = Int.max / 600
        valid.ownedCosmetics.insert("retired-cosmetic")
        valid.ownedRoomItems.insert("future-room-item")
        valid.personalRoom.placements["future-slot"] = "future-room-item"
        let participantID = UUID()
        valid.sessionRewards[participantID] = RewardOutcome(focusXP: 120, coins: 15, passed: true, leveledUp: false, newLevel: 1, breakdown: [])
        defaults.set(try JSONEncoder().encode(valid), forKey: WorldPersistence.persistenceKey)
        let restored = WorldStore(defaults: defaults)
        assert(restored.recoveryIssue == nil && restored.state == valid)
        assert(restored.state.progression.level > 1)
        assert(restored.state.progression.xpForThisLevel > 0)
        assert(restored.state.activeBuilding!.requiredXP > 0)
        let before = defaults.data(forKey: WorldPersistence.persistenceKey)
        let character = StudyCharacter(id: "you", name: "Fixture", spriteAsset: "char_you", fallback: .default)
        var user = SessionParticipant.makeSolo(userCharacter: character, userName: "Fixture")[0]
        user.focusedSeconds = RoomConfig.solo.sessionSeconds
        user.recordedBreakCount = 0
        let refused = restored.applySession(user: user, config: .solo)
        assert(refused.focusXP == 0 && restored.recoveryIssue == .progressionLimit)
        assert(restored.state == valid && restored.state.sessionRewards[user.id] == nil)
        assert(defaults.data(forKey: WorldPersistence.persistenceKey) == before)
        assert(Progression.xpToReach(level: Int.max) == Int.max)
        assert(Progression(focusXP: Int.max).level > 1)
        for level in 1...1000 {
            let xp = 100 * level * (level - 1) / 2
            assert(Progression.xpToReach(level: level) == xp)
            assert(Progression(focusXP: xp).level == level)
            if level > 1 { assert(Progression(focusXP: xp - 1).level == level - 1) }
        }
        print("PASS: world semantic preservation, integer headroom, catalogue compatibility, receipt retention and bounded level calculation")
    }
}
