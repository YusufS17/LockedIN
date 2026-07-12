import SwiftUI

// MARK: - RootView (ONB-04)
//
// First-launch routing gate.
// Reads @AppStorage(PersistenceKeys.onboarding) to decide which experience to show:
//   - false (first launch / onboarding not completed) → OnboardingHostView
//   - true  (returning user)                          → HomeView
//
// @AppStorage lives HERE (in the View), NOT on AppStore.
// @Observable classes cannot hold @AppStorage property wrappers (RESEARCH.md Pitfall 8).
//
// LockedINApp.swift mounts RootView() under .environment(appStore) — leave unchanged.

struct RootView: View {

    // MARK: - Environment

    @Environment(AppStore.self) private var appStore

    // First-launch gate — uses the canonical key constant (RESEARCH.md Pitfall 5)
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    // MARK: - Body

    var body: some View {
        // First-launch gate: real onboarding beats until completed, then Home.
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingHostView()
        }
    }
}

// MARK: - Preview

#Preview("Root — first launch (onboarding)") {
    RootView()
        .environment(AppStore())
}
