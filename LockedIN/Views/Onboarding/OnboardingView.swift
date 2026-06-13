import SwiftUI

// MARK: - OnboardingView (ONB-01) — image-driven, full-bleed, tap to advance
//
// Three approved design slides (Slide1 welcome → Slide2 choose avatar → Slide3 player ready).
// Full-bleed fill (bottom-anchored so the on-image buttons stay visible); real status bar
// hidden so each slide reads as its own screen. Tap anywhere (i.e. the on-image button) to
// advance; the final slide completes onboarding and routes to HomeView.

struct OnboardingView: View {

    @Environment(AppStore.self) private var appStore
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false

    @State private var index = 0
    private let slides = ["Slide1", "Slide2", "Slide3"]

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.offset) { i, name in
                    GeometryReader { geo in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                            .clipped()
                    }
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }

    private func advance() {
        if index < slides.count - 1 {
            withAnimation { index += 1 }
        } else {
            if appStore.displayName.isEmpty { appStore.displayName = "You" }
            appStore.userCharacter = .default
            hasCompletedOnboarding = true
        }
    }
}

#Preview("Onboarding — 3 slides") {
    OnboardingView().environment(AppStore())
}
