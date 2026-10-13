import Foundation
import Observation

// MARK: - WorldPersistence — local-first world/coin save (CLAUDE.md: on-device only)

enum WorldRecoveryIssue: Equatable {
    case unreadableSave
    case newerSaveVersion(Int)

    var message: String {
        switch self {
        case .unreadableSave:
            return "Your saved world could not be read. It has been kept safe. Progress and purchases are paused until it can be recovered."
        case .newerSaveVersion:
            return "Your world was saved by a newer version of LockedIN. Update the app to continue. Your save has been kept safe."
        }
    }
}

enum WorldPersistence {
    static let persistenceKey = "worldStateV1"
    private static let key = persistenceKey

    enum LoadResult {
        case missing
        case loaded(WorldState)
        case needsRecovery(WorldRecoveryIssue)
    }

    static func loadResult(defaults: UserDefaults = .standard) -> LoadResult {
        guard let object = defaults.object(forKey: key) else { return .missing }
        guard let data = object as? Data else { return .needsRecovery(.unreadableSave) }
        do {
            // Read the version before decoding fields a future app may have changed.
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .needsRecovery(.unreadableSave)
            }
            if let version = json["schemaVersion"] as? Int, version > WorldState.currentSchemaVersion {
                return .needsRecovery(.newerSaveVersion(version))
            }
            // These three fields existed in the first world format. Optional later
            // additions may migrate, but unrelated/empty JSON is not a fresh save.
            guard ["progression", "buildings", "activeBuildingID"].allSatisfy({ json[$0] != nil && !(json[$0] is NSNull) }) else {
                return .needsRecovery(.unreadableSave)
            }
            let state = try JSONDecoder().decode(WorldState.self, from: data)
            guard state.schemaVersion == WorldState.currentSchemaVersion else {
                return .needsRecovery(.unreadableSave)
            }
            return .loaded(state)
        } catch {
            return .needsRecovery(.unreadableSave)
        }
    }

    static func load(defaults: UserDefaults = .standard) -> WorldState? {
        if case .loaded(let state) = loadResult(defaults: defaults) { return state }
        return nil
    }

    static func save(_ state: WorldState, defaults: UserDefaults = .standard) {
        // Re-check immediately before writing, even if another store changed the save.
        if case .needsRecovery = loadResult(defaults: defaults) { return }
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: key) }
    }

    static func clear(defaults: UserDefaults = .standard) {
        if case .needsRecovery = loadResult(defaults: defaults) { return }
        defaults.removeObject(forKey: key)
    }
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
    private(set) var recoveryIssue: WorldRecoveryIssue?
    private let defaults: UserDefaults

    init(state: WorldState? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        switch WorldPersistence.loadResult(defaults: defaults) {
        case .missing: self.state = state ?? .seeded
        case .loaded(let saved): self.state = state ?? saved
        case .needsRecovery(let issue):
            self.state = .seeded
            self.recoveryIssue = issue
        }
    }

    // MARK: - Apply a finished session

    /// Evaluates the user's result, banks the reward, persists, and returns the outcome
    /// for the reveal. Repeated results return the saved receipt without awarding again.
    @discardableResult
    func applySession(user: SessionParticipant, config: RoomConfig) -> RewardOutcome {
        guard canMutate else {
            return RewardOutcome(focusXP: 0, coins: 0, passed: false, leveledUp: false,
                                 newLevel: state.progression.level,
                                 breakdown: [.init(label: "Progress not saved — existing save needs recovery", xp: 0)])
        }
        if let existing = state.sessionRewards[user.id] { return existing }
        let p = state.progression
        let outcome = RewardRules.evaluate(
            user: user, config: config,
            streakBefore: p.currentStreak, levelBefore: p.level, xpBefore: p.focusXP
        )
        // Do not seal a receipt for an unfinished snapshot or count it as a session.
        if !config.quickDemo && !user.leftEarly && (user.focusedSeconds ?? 0) < config.sessionSeconds {
            return outcome
        }
        state.sessionRewards[user.id] = outcome
        if outcome.focusXP > 0 { award(outcome) }
        WorldPersistence.save(state, defaults: defaults)
        return outcome
    }

    private func award(_ outcome: RewardOutcome) {
        state.progression.focusXP += outcome.focusXP
        state.progression.coins += outcome.coins
        state.progression.sessionsCompleted += 1
        state.progression.currentStreak = outcome.passed ? state.progression.currentStreak + 1 : 0
        state.progression.bestStreak = max(state.progression.bestStreak, state.progression.currentStreak)
        contribute(outcome.focusXP)
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

    // MARK: - Cosmetics

    /// Whether a cosmetic is usable: free items always, premium only once purchased.
    func owns(_ id: String) -> Bool {
        guard CosmeticCatalog.contains(id) else { return false }
        return CosmeticCatalog.cost(for: id) == 0 || state.ownedCosmetics.contains(id)
    }

    /// Buy a premium cosmetic with coins. Returns true if owned afterwards.
    @discardableResult
    func purchase(_ id: String) -> Bool {
        guard canMutate, CosmeticCatalog.contains(id) else { return false }
        if owns(id) { return true }
        let cost = CosmeticCatalog.cost(for: id)
        guard cost > 0, state.progression.coins >= cost else { return false }
        state.progression.coins -= cost
        state.ownedCosmetics.insert(id)
        WorldPersistence.save(state, defaults: defaults)
        return true
    }

    // MARK: - Personal room customisation (world-layer §12 RoomCustomisationService)

    /// Whether a room item is usable: free items always, premium only once purchased.
    func ownsRoomItem(_ id: String) -> Bool {
        guard RoomItemCatalog.item(id: id) != nil else { return false }
        return RoomItemCatalog.cost(for: id) == 0 || state.ownedRoomItems.contains(id)
    }

    /// Buy a premium room item with coins. Returns true if owned afterwards.
    @discardableResult
    func purchaseRoomItem(_ id: String) -> Bool {
        guard canMutate, RoomItemCatalog.item(id: id) != nil else { return false }
        if ownsRoomItem(id) { return true }
        let cost = RoomItemCatalog.cost(for: id)
        guard cost > 0, state.progression.coins >= cost else { return false }
        state.progression.coins -= cost
        state.ownedRoomItems.insert(id)
        WorldPersistence.save(state, defaults: defaults)
        return true
    }

    /// Outcome of trying to place a room item (drives the builder's feedback).
    enum RoomItemResult { case placed, purchasedAndPlaced, cannotAfford, saveUnavailable }

    /// Place an item in its slot — buying it first if it's premium and affordable.
    @discardableResult
    func selectRoomItem(_ id: String) -> RoomItemResult {
        guard canMutate else { return .saveUnavailable }
        guard let item = RoomItemCatalog.item(id: id) else { return .cannotAfford }
        let alreadyOwned = ownsRoomItem(id)
        if !alreadyOwned {
            guard purchaseRoomItem(id) else { return .cannotAfford }
        }
        state.personalRoom.placements[item.slot.rawValue] = id
        WorldPersistence.save(state, defaults: defaults)
        return alreadyOwned ? .placed : .purchasedAndPlaced
    }

    // MARK: - World direction

    /// Choose which unlocked building receives future contributions.
    func setActiveBuilding(_ type: BuildingType) {
        guard canMutate, state.buildings.contains(where: { $0.id == type.rawValue && $0.unlocked }) else { return }
        state.activeBuildingID = type.rawValue
        WorldPersistence.save(state, defaults: defaults)
    }

    /// Spend coins to begin building an unlocked-but-unbuilt (level 0) plot.
    @discardableResult
    func startBuilding(_ type: BuildingType, cost: Int) -> Bool {
        guard canMutate, cost >= 0,
              let idx = state.buildings.firstIndex(where: { $0.id == type.rawValue }),
              state.buildings[idx].unlocked, state.buildings[idx].level == 0,
              state.progression.coins >= cost
        else { return false }
        state.progression.coins -= cost
        state.buildings[idx].level = 1
        state.activeBuildingID = type.rawValue
        WorldPersistence.save(state, defaults: defaults)
        return true
    }

    /// Refresh the lock before every mutation so a newly unreadable save stays protected.
    private var canMutate: Bool {
        if case .needsRecovery(let issue) = WorldPersistence.loadResult(defaults: defaults) {
            recoveryIssue = issue
        }
        return recoveryIssue == nil
    }

    // MARK: - Debug

    /// Reset all world/coin progress (used by onboarding reset / dev).
    func reset() {
        guard canMutate else { return }
        state = .seeded
        WorldPersistence.clear(defaults: defaults)
    }
}
