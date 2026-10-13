import Foundation
import SwiftUI

// UI/catalog fixtures only; compile the actual world state, store and reward engine.
enum Theme {
    enum Colour {
        static let accent = Color.orange
        static let accentRose = Color.pink
        static let accentTeal = Color.teal
        static let accentLavender = Color.purple
        static let plantGreen = Color.green
    }
}
struct PersonalRoom: Codable, Equatable {
    var placements: [String: String] = [:]
    static let seeded = PersonalRoom()
}
enum CosmeticCatalog {
    static func cost(for id: String) -> Int { id == "premium" ? 10 : 0 }
    static func contains(_ id: String) -> Bool { ["free", "premium"].contains(id) }
}
enum RoomItemCatalog {
    struct Item { let slot: Slot }
    enum Slot: String { case desk }
    static func cost(for id: String) -> Int { id == "premiumDesk" ? 10 : 0 }
    static func item(id: String) -> Item? { ["freeDesk", "premiumDesk"].contains(id) ? Item(slot: .desk) : nil }
}
struct RoomConfig {
    var quickDemo = false
    var distractionLimit = 3
    var competitive = false
    var sessionSeconds = 1500
    var breakAllowance = 1
}
struct SessionParticipant {
    let id = UUID()
    var leftEarly = false
    var distractions = 0
    var focusPct = 98
    var focusedSeconds: Int? = 1500
    var recordedBreakCount: Int? = 0
}

@main
struct WorldRewardChecks {
    static func main() throws {
        let suite = "LockedIN.reward-checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WorldStore(state: .seeded, defaults: defaults)
        let user = SessionParticipant()
        let config = RoomConfig()
        let reward = store.applySession(user: user, config: config)
        let after = store.state
        assert(reward.focusXP > 0 && after.progression.sessionsCompleted == 1)
        assert(store.applySession(user: user, config: config) == reward)
        assert(store.state == after)

        let restored = WorldStore(defaults: defaults)
        assert(restored.state == after)
        assert(restored.applySession(user: user, config: config) == reward)
        assert(restored.state == after)
        restored.applySession(user: SessionParticipant(), config: config)
        assert(restored.state.progression.sessionsCompleted == 2)
        let earned = restored.state.progression
        let buildings = restored.state.buildings
        restored.applySession(user: SessionParticipant(leftEarly: true), config: config)
        restored.applySession(user: SessionParticipant(), config: RoomConfig(quickDemo: true))
        assert(restored.state.progression == earned && restored.state.buildings == buildings)

        // A pre-receipt save retains existing progress and starts with an empty ledger.
        let data = try JSONEncoder().encode(after)
        var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        legacy.removeValue(forKey: "sessionRewards")
        let migrated = try JSONDecoder().decode(WorldState.self, from: JSONSerialization.data(withJSONObject: legacy))
        assert(migrated.progression == after.progression && migrated.sessionRewards.isEmpty)
        // Older saves without version metadata still retain balances and receipt UUIDs.
        var unversioned = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        unversioned.removeValue(forKey: "schemaVersion")
        defaults.set(try JSONSerialization.data(withJSONObject: unversioned), forKey: "worldStateV1")
        let legacyStore = WorldStore(defaults: defaults)
        assert(legacyStore.recoveryIssue == nil && legacyStore.state == after)
        assert(legacyStore.applySession(user: user, config: config) == reward)

        var future = unversioned
        future["schemaVersion"] = WorldState.currentSchemaVersion + 1
        future["progression"] = "a future format we cannot decode"
        let futureData = try JSONSerialization.data(withJSONObject: future)
        let malformedData = Data("not JSON".utf8)
        let fixtures: [Any] = [malformedData, Data("{}".utf8), Data("[]".utf8), "wrong storage type", futureData]
        for fixture in fixtures {
            defaults.set(fixture, forKey: "worldStateV1")
            let original = defaults.object(forKey: "worldStateV1")! as! NSObject
            var supplied = WorldState.seeded
            supplied.progression.coins = 100
            let protected = WorldStore(state: supplied, defaults: defaults)
            assert(protected.recoveryIssue != nil)
            if let data = fixture as? Data, data == futureData {
                assert(protected.recoveryIssue == .newerSaveVersion(2))
            }
            let before = protected.state
            let blockedReward = protected.applySession(user: SessionParticipant(), config: config)
            assert(blockedReward.focusXP == 0 && blockedReward.coins == 0 && !blockedReward.passed)
            assert(!protected.purchase("free") && !protected.purchase("premium"))
            assert(!protected.purchaseRoomItem("freeDesk") && !protected.purchaseRoomItem("premiumDesk"))
            assert(protected.selectRoomItem("freeDesk") == .saveUnavailable)
            assert(!protected.startBuilding(.libraryHub, cost: 0))
            protected.setActiveBuilding(.libraryHub)
            protected.reset()
            WorldPersistence.save(supplied, defaults: defaults)
            WorldPersistence.clear(defaults: defaults)
            assert(protected.state == before && protected.state.sessionRewards.isEmpty)
            assert(original.isEqual(defaults.object(forKey: "worldStateV1")))
            assert(WorldStore(defaults: defaults).recoveryIssue != nil)
        }
        // A bad save appearing after initialization also locks the live store.
        defaults.removeObject(forKey: "worldStateV1")
        var funded = WorldState.seeded
        funded.progression.coins = 100
        funded.buildings[1].unlocked = true
        let live = WorldStore(state: funded, defaults: defaults)
        defaults.set(malformedData, forKey: "worldStateV1")
        assert(live.applySession(user: SessionParticipant(), config: config).coins == 0)
        assert(live.recoveryIssue == .unreadableSave && live.state == funded)
        assert(!live.purchase("premium") && !live.purchaseRoomItem("premiumDesk"))
        assert(live.selectRoomItem("freeDesk") == .saveUnavailable)
        assert(!live.startBuilding(.languageCafe, cost: 10))
        live.setActiveBuilding(.languageCafe)
        live.reset()
        assert(live.state == funded)
        assert(defaults.data(forKey: "worldStateV1") == malformedData)
        defaults.removeObject(forKey: "worldStateV1")
        restored.reset()
        assert(restored.state == .seeded && WorldPersistence.load(defaults: defaults) == nil)
        print("PASS: duplicate rewards, persisted receipts/reload, distinct sessions, demo/exit isolation, legacy migration, reset, unreadable/wrong-type/future save preservation, mutation locks")
    }
}
