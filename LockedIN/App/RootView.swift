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
        #if DEBUG
        if let screen = Self.smokeScreen {
            SmokeRoomScreen(screen: screen)   // Debug-only isolated render and interaction harness
        } else if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingHostView()
        }
        #else
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingHostView()
        }
        #endif
    }
}

#if DEBUG
extension RootView {
    /// Debug-only QA — `-smoke-room <screen>` renders one room surface headlessly.
    static var smokeScreen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-smoke-room"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}

// Debug-only QA harness; Release routing uses the real onboarding gate.
private struct SmokeRoomScreen: View {
    @Environment(AppStore.self) private var appStore
    let screen: String

    var body: some View {
        switch screen {
        case "home":
            HomeView()
        case "avatar":
            CharacterCustomizerView(initial: appStore.userCharacter, initialName: appStore.displayName, onSave: { _, _ in })
        case "group":
            GroupRoomView()
        case "solo":
            SoloRoomView()
        case "live":
            LiveSessionView(
                config: .preset,
                participants: SessionParticipant.makeRoster(
                    userCharacter: appStore.userStudyCharacter,
                    userName: "You",
                    config: .preset),
                onFinish: { _ in }, onCancel: {})
        case "builder":
            PersonalRoomBuilderView()
        case "world":
            WorldView()
        case "first":
            FirstRoomBeatView(appearance: .default, displayName: "You", onExplore: {})
        default:
            Text("unknown screen \(screen)")
        }
    }
}
#endif

// MARK: - Preview

#Preview("Root — first launch (onboarding)") {
    RootView()
        .environment(AppStore())
}
