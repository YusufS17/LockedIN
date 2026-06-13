import SwiftUI

// MARK: - OnboardingView (ONB-01)
//
// DEMO MODE: image-driven onboarding slideshow using the approved design mockups
// (Assets: Onboard1…Onboard6). Tap the screen (or swipe) to advance; the final
// slide completes onboarding and routes to HomeView.
//
// Rationale: the design mockups are the agreed visual target. Code-drawn art could
// not match them in the hackathon window, so the polished mockups themselves are
// used as the onboarding slides. The functional character creator + components
// (CharacterCreatorView, AvatarView, IsometricRoomView, persistence) remain in the
// codebase and can replace these slides post-hackathon.

struct OnboardingView: View {

    @Environment(AppStore.self) private var appStore
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    @State private var index = 0

    // Slide order: splash → welcome → avatar select → customiser → reveal → first room
    private let slides = ["Onboard1", "Onboard2", "Onboard3", "Onboard4", "Onboard5", "Onboard6"]

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.offset) { i, name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, Theme.Spacing.md)
                        .tag(i)
                        .contentShape(Rectangle())
                        .onTapGesture { advance() }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Honest skip — straight to Home
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(Theme.TypeScale.captionBold)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .padding(Theme.Spacing.md)
                }
                Spacer()
            }
        }
    }

    private func advance() {
        if index < slides.count - 1 {
            withAnimation { index += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        if appStore.displayName.isEmpty { appStore.displayName = "You" }
        appStore.userCharacter = .default
        hasCompletedOnboarding = true
    }
}

#Preview("Onboarding — image slideshow") {
    OnboardingView()
        .environment(AppStore())
}
