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
        // Corruption fixtures are Debug-only and require an isolated suite plus reset.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ui-test-reset"), args.contains("-ui-test-world-corrupt") {
            defaults.set(Data([0xFF, 0xFE]), forKey: WorldPersistence.persistenceKey)
            if args.contains("-ui-test-pending-results") {
                let now = Date()
                let config = RoomConfig.solo
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
