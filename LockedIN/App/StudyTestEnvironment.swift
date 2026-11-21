import Foundation

/// Debug UI checks use a namespaced disposable save. Release builds always use
/// the ordinary app store and real date; no test clock is exposed to users.
enum StudyTestEnvironment {
    static var suiteName: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ui-test-suite"), i + 1 < args.count,
              args[i + 1].hasPrefix("LockedIN.ui-tests.") else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }

    static var defaults: UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else { return .standard }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-test-reset") {
            defaults.removePersistentDomain(forName: suiteName)
        }
        // Saved-state fixtures are Debug-only and require an isolated suite plus reset.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ui-test-reset") {
            if args.contains("-ui-test-avatar-corrupt") {
                defaults.set(Data([0xFF, 0xFE]), forKey: PersistenceKeys.character)
                defaults.set("Saved student", forKey: PersistenceKeys.displayName)
            }
            if args.contains("-ui-test-avatar-existing-outfit"), !args.contains("-ui-test-avatar-corrupt") {
                var appearance = CharacterAppearance.default
                appearance.topStyle = .jacket
                appearance.bottomStyle = .skirt
                appearance.shoeStyle = .boots
                appearance.accessory = .headphones
                CharacterPersistence.save(appearance: appearance, displayName: "Saved student", defaults: defaults)
            }
            if args.contains("-ui-test-world-corrupt") {
                defaults.set(Data([0xFF, 0xFE]), forKey: WorldPersistence.persistenceKey)
            }
            if args.contains("-ui-test-world-destinations"), !args.contains("-ui-test-world-corrupt") {
                var world = WorldState.seeded
                world.progression.focusXP = 300
                world.progression.sessionsCompleted = 3
                if let library = world.buildings.firstIndex(where: { $0.type == .libraryHub }),
                   let cafe = world.buildings.firstIndex(where: { $0.type == .languageCafe }) {
                    // The pending 120-XP result takes Library to 50%; Cafe stays 70%.
                    // Distinct values expose stale progress after changing destination.
                    world.buildings[library].progressXP = 55
                    world.buildings[cafe].level = 1
                    world.buildings[cafe].unlocked = true
                    world.buildings[cafe].progressXP = 245
                    if world.hasValidEssentialValues, let data = try? JSONEncoder().encode(world) {
                        defaults.set(data, forKey: WorldPersistence.persistenceKey)
                    }
                }
            }
            if args.contains("-ui-test-pending-results") {
                let now = Date()
                var config = RoomConfig.solo
                config.subject = "Study"
                config.goal = "Review one paragraph"
                let roster = SessionParticipant.makeSolo(userCharacter: CharacterCatalog.first, userName: "Fixture")
                var session = ActiveStudySession(config: config, participants: roster,
                                                now: now.addingTimeInterval(-Double(config.sessionSeconds)))
                session.update(at: now)
                session.reviewGoal(.achieved)
                if session.isValid, let data = try? JSONEncoder().encode(session) {
                    defaults.set(data, forKey: StudySessionStore.persistenceKey)
                }
            }
        }
        #endif
        return defaults
    }

    /// Keeps layout/recovery checks deterministic; never overrides ordinary user settings.
    static var reducedMotionForChecks: Bool {
        #if DEBUG
        return suiteName != nil && ProcessInfo.processInfo.arguments.contains("-ui-test-reduce-motion")
        #else
        return false
        #endif
    }

    static var restorationDate: Date {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if suiteName != nil, let i = args.firstIndex(of: "-ui-test-elapsed"), i + 1 < args.count,
           let seconds = Double(args[i + 1]), seconds.isFinite, (0...10800).contains(seconds) {
            return Date().addingTimeInterval(seconds)
        }
        #endif
        return Date()
    }
}
