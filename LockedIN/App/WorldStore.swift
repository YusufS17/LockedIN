import Foundation
import Observation

// MARK: - WorldPersistence — local-first world/coin save (CLAUDE.md: on-device only)

enum WorldPersistence {
    private static let key = "worldStateV1"

    static func load() -> WorldState? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(WorldState.self, from: data)
        else { return nil }
        return state
    }

    static func save(_ state: WorldState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - WorldStore — the progression + world economy (persisted)
//
// Holds the player's Focus XP / coins / level and the district's buildings. Sessions
// award quality-weighted rewards (RewardRules); earned XP banks into the active building,
// levelling it up and unlocking the next one. All progress persists locally and survives
// relaunch (CLAUDE.md permits on-device persistence for world + coin progress).
//
// @Observable child of AppStore. No progression logic lives in views.

@Observable
final class WorldStore {

    private(set) var state: WorldState

    init(state: WorldState? = nil) {
        self.state = state ?? WorldPersistence.load() ?? .seeded
    }

    // MARK: - Apply a finished session

    /// Evaluates the user's result, banks the reward, persists, and returns the outcome
    /// for the reveal. Call once per completed session.
    @discardableResult
    func applySession(user: SessionParticipant, config: RoomConfig) -> RewardOutcome {
        let p = state.progression
        let outcome = RewardRules.evaluate(
            user: user, config: config,
            streakBefore: p.currentStreak, levelBefore: p.level, xpBefore: p.focusXP
        )
        award(outcome)
        return outcome
    }

    private func award(_ outcome: RewardOutcome) {
        state.progression.focusXP += outcome.focusXP
        state.progression.coins += outcome.coins
        state.progression.sessionsCompleted += 1
        state.progression.currentStreak = outcome.passed ? state.progression.currentStreak + 1 : 0
        state.progression.bestStreak = max(state.progression.bestStreak, state.progression.currentStreak)
        contribute(outcome.focusXP)
        WorldPersistence.save(state)
    }

    /// Banks XP into the active building, rolling over level-ups and unlocking the next.
    private func contribute(_ xp: Int) {
        guard xp > 0,
              let idx = state.buildings.firstIndex(where: { $0.id == state.activeBuildingID })
        else { return }
        state.buildings[idx].progressXP += xp
        while state.buildings[idx].progressXP >= state.buildings[idx].requiredXP {
            state.buildings[idx].progressXP -= state.buildings[idx].requiredXP
            state.buildings[idx].level += 1
            unlockNext()
        }
    }

    /// Unlocks the first still-locked building (becomes selectable/buildable).
    private func unlockNext() {
        if let idx = state.buildings.firstIndex(where: { !$0.unlocked }) {
            state.buildings[idx].unlocked = true
        }
    }

    // MARK: - World direction

    /// Choose which unlocked building receives future contributions.
    func setActiveBuilding(_ type: BuildingType) {
        guard state.buildings.contains(where: { $0.id == type.rawValue && $0.unlocked }) else { return }
        state.activeBuildingID = type.rawValue
        WorldPersistence.save(state)
    }

    /// Spend coins to begin building an unlocked-but-unbuilt (level 0) plot.
    @discardableResult
    func startBuilding(_ type: BuildingType, cost: Int) -> Bool {
        guard let idx = state.buildings.firstIndex(where: { $0.id == type.rawValue }),
              state.buildings[idx].unlocked, state.buildings[idx].level == 0,
              state.progression.coins >= cost
        else { return false }
        state.progression.coins -= cost
        state.buildings[idx].level = 1
        state.activeBuildingID = type.rawValue
        WorldPersistence.save(state)
        return true
    }

    // MARK: - Debug

    /// Reset all world/coin progress (used by onboarding reset / dev).
    func reset() {
        state = .seeded
        WorldPersistence.clear()
    }
}
