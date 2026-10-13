import SwiftUI

// MARK: - OnboardingHostView — first-run beats (mockup 6-beat flow)
//
// Chains the code-drawn onboarding beats, matching mockups 05 → 06 → 01 → 02 → 03 → 04:
//   1. WelcomeSplashView     — "Welcome to LockedIN" hero splash
//   2. ValuePropsView        — numbered value-prop cards
//   3. CharacterGalleryView  — choose a base study avatar
//   4. CharacterCustomizerView — fully customise the look (wardrobe axes)
//   5. AvatarRevealView      — "You're all set!" + name your avatar
//   6. FirstRoomBeatView     — arrive in your first room
// A "N OF 6" step badge occupies a reserved header (except inside the customizer, which has
// its own chrome). Identity persists at the reveal beat; the completion flag flips
// on "Explore room", so RootView routes to Home next launch.
//
// @AppStorage lives here in the View (never on the @Observable AppStore — Pitfall 8).

struct OnboardingHostView: View {

    @Environment(AppStore.self) private var appStore
    @ReducedMotionPreference private var reduceMotion
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    enum Beat: Int { case splash = 0, valueProps, gallery, customizer, reveal, firstRoom }
    @State private var beat: Beat = .splash
    @State private var hasChosenBase = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Colour.background.ignoresSafeArea()

            switch beat {
            case .splash:
                WelcomeSplashView(onContinue: { go(.valueProps) }, onSkip: { go(.gallery) })
                    .transition(beatTransition)

            case .valueProps:
                ValuePropsView(onContinue: { go(.gallery) }, onSkip: { go(.gallery) })
                    .transition(beatTransition)

            case .gallery:
                CharacterGalleryView(
                    preserveCurrentLook: hasChosenBase || CharacterPersistence.load(defaults: appStore.defaults) != nil,
                    onContinue: {
                        hasChosenBase = true
                        go(.customizer)
                    }
                )
                    .transition(beatTransition)

            case .customizer:
                CharacterCustomizerView(
                    initial: appStore.userCharacter,
                    initialName: appStore.displayName,
                    onBack: { go(.gallery) },
                    onSave: { appearance, _ in
                        appStore.userCharacter = appearance
                        go(.reveal)
                    }
                )
                .transition(beatTransition)

            case .reveal:
                AvatarRevealView(
                    appearance: appStore.userCharacter,
                    initialName: appStore.displayName,
                    onConfirm: { name in
                        appStore.displayName = name
                        CharacterPersistence.save(appearance: appStore.userCharacter,
                                                  displayName: name, defaults: appStore.defaults)
                        go(.firstRoom)
                    }
                )
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
        .safeAreaInset(edge: .top, spacing: 0) {
            if beat != .customizer {
                HStack {
                    if beat != .splash {
                        Button {
                            if let previous = Beat(rawValue: beat.rawValue - 1) { go(previous) }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 44, height: 44)
                        }
                        .foregroundStyle(Theme.Colour.textPrimary)
                        .accessibilityLabel("Previous onboarding step")
                        .accessibilityIdentifier("onboarding.back")
                    } else {
                        PixelIconView(icon: .lock, size: 24, tint: Theme.Colour.textPrimary)
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    StepBadge(current: beat.rawValue + 1, total: 6)
                        .accessibilityLabel("Step \(beat.rawValue + 1) of 6")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Theme.Colour.background)
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
