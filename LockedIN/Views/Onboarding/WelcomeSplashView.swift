import SwiftUI

// MARK: - WelcomeSplashView — Beat 1 of 6: the arrival moment
//
// Matches mockup 05-welcome-splash: "Welcome to LockedIN" over a glowing pixel
// padlock and a hero study-room scene framed by clouds and gold sparkles, with the
// chunky gold "Let's go →" pixel CTA. The village-island half of the mockup is
// Phase-4 room art — the hero slot shows the live room scene until that lands.

struct WelcomeSplashView: View {

    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heroVisible = false

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            OnboardingBackdrop()

            VStack(spacing: 0) {
                HStack {
                    Button("Skip") { onSkip() }
                        .font(Theme.TypeScale.captionBold)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .accessibilityLabel("Skip onboarding")
                    Spacer()
                }

                Spacer(minLength: Theme.Spacing.md)

                heading

                Spacer(minLength: Theme.Spacing.lg)

                heroScene
                    .opacity(heroVisible ? 1 : 0)
                    .offset(y: heroVisible ? 0 : 12)

                Spacer(minLength: Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.md) {
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Text("Let's go")
                            Image(systemName: "arrow.right").font(.system(size: 15, weight: .heavy))
                        }
                    }
                    .buttonStyle(PixelButtonStyle(kind: .gold))

                    PageDots(count: 6, active: 0)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
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
                .font(Theme.TypeScale.title2)
                .foregroundStyle(Theme.Colour.textSecondary)
            Text("LockedIN")
                .font(Theme.TypeScale.largeTitle)
                .foregroundStyle(Theme.Colour.textPrimary)

            VStack(spacing: 2) {
                Text("Study together.")
                Text("Stay accountable.")
                Text("Build your world.")
            }
            .font(Theme.TypeScale.body)
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

            // Study-room hero card (placeholder art until Phase 4's baked pixel room).
            ZStack {
                IsometricRoomView()
                    .frame(height: 190)
                    .clipShape(PixelPanelShape(unit: 6))
                LiveRoomSceneAvatars()
            }
            .frame(height: 190)
            .overlay(PixelPanelShape(unit: 6).stroke(Theme.Colour.appShell, lineWidth: 2))
            .background(PixelPanelShape(unit: 6).fill(Theme.Colour.appShell).offset(y: 5))
        }
    }
}

/// Three catalog characters studying together in the splash hero — the "study
/// together" promise, rendered with the real v3 sprites.
private struct LiveRoomSceneAvatars: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            AvatarView(appearance: .maya, status: .focused, size: 56, pose: .sitTypingFront)
                .position(x: w * 0.32, y: h * 0.60)
            AvatarView(appearance: .leo, status: .focused, size: 56, pose: .sitTypingFront)
                .position(x: w * 0.55, y: h * 0.66)
            AvatarView(appearance: .sam, status: .idle, size: 52)
                .position(x: w * 0.76, y: h * 0.56)
        }
        .allowsHitTesting(false)
    }
}

#Preview("Welcome splash") {
    WelcomeSplashView(onContinue: {}, onSkip: {})
        .environment(AppStore())
}
