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
enum CosmeticCatalog { static func cost(for id: String) -> Int { 0 } }
enum RoomItemCatalog {
    struct Item { let slot: Slot }
    enum Slot: String { case desk }
    static func cost(for id: String) -> Int { 0 }
    static func item(id: String) -> Item? { nil }
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
        restored.reset()
        assert(restored.state == .seeded && WorldPersistence.load(defaults: defaults) == nil)
        print("PASS: duplicate rewards, persisted receipts/reload, distinct sessions, demo/exit isolation, legacy migration, reset")
    }
}
