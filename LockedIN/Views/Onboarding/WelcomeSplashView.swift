import SwiftUI

// First-run welcome with a live, layered personal-room preview.

struct WelcomeSplashView: View {

    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heroVisible = false

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            OnboardingBackdrop()

            ScrollView {
                VStack(spacing: 24) {
                    heading
                    heroScene
                        .opacity(heroVisible ? 1 : 0)
                        .offset(y: heroVisible ? 0 : 12)
                    Text("A little focus. A place that grows with you.")
                        .font(.body)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button("Let's go", action: onContinue)
                        .buttonStyle(StudioButtonStyle(primary: true))
                        .accessibilityIdentifier("onboarding.continue")
                    Button("Skip introduction", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("onboarding.skip")
                    PageDots(count: 6, active: 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Theme.Colour.background)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6).delay(0.15)) {
                heroVisible = true
            }
        }
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Welcome to")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textSecondary)
            Text("LockedIN")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textPrimary)

            VStack(spacing: 2) {
                Text("Study together.")
                Text("Stay accountable.")
                Text("Build your world.")
            }
            .font(.body)
            .foregroundStyle(Theme.Colour.textSecondary)
            .padding(.top, Theme.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - Hero scene: glowing padlock over the room

    private var heroScene: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Glowing pixel padlock — the brand mark.
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colour.sparkle.opacity(0.55),
                                     Theme.Colour.sparkle.opacity(0.12),
                                     .clear],
                            center: .center, startRadius: 6, endRadius: 62
                        )
                    )
                    .frame(width: 124, height: 124)
                PixelIconView(icon: .lock, size: 64, tint: Theme.Colour.appShell)
            }

            PersonalRoomScene(room: .seeded, character: CharacterCatalog.first)
                .frame(height: 240)
                .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
    }
}

#Preview("Welcome splash") {
    WelcomeSplashView(onContinue: {}, onSkip: {})
        .environment(AppStore())
}
