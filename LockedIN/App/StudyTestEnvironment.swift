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
        #endif
        return defaults
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
