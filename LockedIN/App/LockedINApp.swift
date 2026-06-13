import SwiftUI

// MARK: - App Entry Point (CLAUDE.md: single AppStore, .environment() at WindowGroup root)
//
// Single @Observable AppStore instance is injected at the WindowGroup root.
// All views read it via @Environment(AppStore.self).
// FORBIDDEN: @StateObject, ObservableObject, @Published, Combine.

@main
struct LockedINApp: App {
    // The single root store — holds wallet, session, room stores (later phases).
    private let appStore = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .environment(appStore)
    }
}
