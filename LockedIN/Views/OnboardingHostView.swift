import SwiftUI

// MARK: - OnboardingHostView — first-run beats, real SwiftUI (no PNG slides)
//
// Chains the code-drawn onboarding beats that match the mockups:
//   1. ConceptBeatView   — "Welcome to LockedIN" value props (06-welcome-valueprops)
//   2. CharacterGalleryView — choose + name your study avatar (01/03 mockups)
//   3. FirstRoomBeatView — "This is your first room" arrival (04-first-room)
// On "Explore room" it sets the onboarding flag, so RootView routes to Home next launch.
//
// @AppStorage lives here in the View (never on the @Observable AppStore — Pitfall 8).

struct OnboardingHostView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    enum Beat { case concept, gallery, firstRoom }
    @State private var beat: Beat = .concept

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            switch beat {
            case .concept:
                ConceptBeatView(onContinue: { go(.gallery) }, onSkip: { go(.gallery) })
                    .transition(beatTransition)

            case .gallery:
                CharacterGalleryView(onContinue: { go(.firstRoom) })
                    .transition(beatTransition)

            case .firstRoom:
                FirstRoomBeatView(
                    appearance: appStore.userCharacter,
                    displayName: appStore.displayName,
                    onExplore: { complete() }
                )
                .transition(beatTransition)
            }
        }
        .statusBarHidden(true)
    }

    private func go(_ next: Beat) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { beat = next }
    }

    private func complete() {
        hasCompletedOnboarding = true
    }

    private var beatTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

#Preview("Onboarding host") {
    OnboardingHostView().environment(AppStore())
}
