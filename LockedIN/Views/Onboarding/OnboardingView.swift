import SwiftUI

// MARK: - OnboardingBeat (D-24, D-25, ONB-01)
//
// 4-beat state machine: .welcome → .create → .payoff → .firstRoom → HomeView
// The welcome beat matches mockup 06-welcome-valueprops.png (value prop rows + world scene).
// The payoff beat matches mockup 03-avatar-reveal-name.png (avatar on gold platform + name).
// The firstRoom beat matches mockup 04-first-room.png (room preview + EXPLORE ROOM).
//
// ZStack transitions use explicit .zIndex to work around the SwiftUI ZStack transition bug
// where views without explicit zIndex snap out instead of animating.
// (RESEARCH.md Pitfall 1: sarunw.com/posts/how-to-fix-zstack-transition-animation)

enum OnboardingBeat: Int {
    case welcome = 0
    case create  = 1
    case payoff  = 2
    case firstRoom = 3
}

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: - Environment

    @Environment(AppStore.self) private var appStore

    // @AppStorage MUST live in the View, NOT on the @Observable class.
    // @Observable classes cannot hold property wrappers that are themselves
    // observation-tracked (RESEARCH.md Pitfall 8).
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var beat: OnboardingBeat = .welcome

    /// Carries the creator's chosen CharacterAppearance forward into the payoff beat.
    /// Set when the .create beat calls its onContinue callback.
    @State private var draftAppearance: CharacterAppearance = .default

    // MARK: - Timing Constants (UI-SPEC.md §Animation & Motion)

    private enum Timing {
        static let beatTransitionSpring = Animation.spring(duration: 0.4, bounce: 0.2)
        static let conceptLineDelay: Duration = .seconds(0.6)
        static let headingSwapFade = Animation.easeInOut(duration: 0.25)
        static let avatarEntranceRise = Animation.spring(duration: 0.45, bounce: 0.5)
        static let avatarEntranceSettle = Animation.spring(duration: 0.3, bounce: 0.2)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            // Beat views — EACH branch has explicit .zIndex to prevent the ZStack
            // transition snap bug (RESEARCH.md Pitfall 1). The active beat gets
            // zIndex(1); all others get zIndex(0).
            switch beat {
            case .welcome:
                ConceptBeatView(
                    onContinue: { advance() },
                    onSkip: { skip() }
                )
                .zIndex(beat == .welcome ? 1 : 0)
                .transition(beatTransition)

            case .create:
                CharacterCreatorView(
                    onContinue: { appearance in
                        draftAppearance = appearance
                        advance()
                    },
                    onSkip: { skip() }
                )
                .zIndex(beat == .create ? 1 : 0)
                .transition(beatTransition)

            case .payoff:
                PayoffBeatView(
                    appearance: draftAppearance,
                    onComplete: { displayName in
                        // Capture name from payoff beat, write to store + persistence,
                        // then advance to the first-room beat (the completion gate)
                        appStore.userCharacter = draftAppearance
                        appStore.displayName = displayName.trimmingCharacters(in: .whitespaces)
                        CharacterPersistence.save(
                            appearance: draftAppearance,
                            displayName: displayName.trimmingCharacters(in: .whitespaces)
                        )
                        advance()
                    }
                )
                .zIndex(beat == .payoff ? 1 : 0)
                .transition(beatTransition)

            case .firstRoom:
                FirstRoomBeatView(
                    appearance: draftAppearance,
                    displayName: appStore.displayName.isEmpty ? "You" : appStore.displayName,
                    onExplore: { complete() }
                )
                .zIndex(beat == .firstRoom ? 1 : 0)
                .transition(beatTransition)
            }
        }
        .animation(reduceMotion ? nil : Timing.beatTransitionSpring, value: beat)
        .preferredColorScheme(.light)
    }

    // MARK: - Beat Transition

    /// Returns the beat-to-beat transition. Slides with opacity in full motion;
    /// opacity-only in Reduce Motion (UI-SPEC.md §Animation & Motion, D-25).
    private var beatTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
              )
    }

    // MARK: - Navigation

    /// Advances to the next beat. Applies the beat transition animation.
    private func advance() {
        withAnimation(reduceMotion ? nil : Timing.beatTransitionSpring) {
            beat = OnboardingBeat(rawValue: beat.rawValue + 1) ?? .firstRoom
        }
    }

    /// Skips onboarding entirely. Sets default appearance + "You" display name,
    /// persists, and sets the first-launch flag. No confirmation — honest, immediate.
    /// (RESEARCH.md Open Question Q2 resolution; UI-SPEC.md §Screen 1 "Skip intro")
    private func skip() {
        appStore.userCharacter = .default
        appStore.displayName   = "You"
        CharacterPersistence.save(appearance: .default, displayName: "You")
        hasCompletedOnboarding = true
    }

    /// Completes onboarding after the firstRoom beat is acknowledged.
    /// AppStore + persistence are already written in the .payoff onComplete handler.
    private func complete() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Preview

#Preview("Onboarding — Welcome beat") {
    OnboardingView()
        .environment(AppStore())
}
