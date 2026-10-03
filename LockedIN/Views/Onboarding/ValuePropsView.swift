import SwiftUI

// Explain the current offline loop and label simulated club companions.

struct ValuePropsView: View {

    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCards = 0

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            OnboardingBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    heading
                    if visibleCards > 0 { card1.transition(cardTransition) }
                    if visibleCards > 1 { card2.transition(cardTransition) }
                    if visibleCards > 2 { card3.transition(cardTransition) }
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Theme.Colour.background)
            }
        }
        .task { await animateIn() }
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(spacing: Theme.Spacing.xs) {
            PixelIconView(icon: .book, size: 30, tint: Theme.Colour.textPrimary)
            Text("Welcome to LockedIN")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Stay accountable. Build your world.")
                .font(.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var card1: some View {
        propCard(number: 1, title: "Find your focus",
                 copy: "Set a subject, choose a goal and settle into your personal room.") {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(CharacterCatalog.all.prefix(4))) { ch in
                    AvatarPortraitView(appearance: ch.fallback, size: 38)
                }
            }
        }
    }

    private var card2: some View {
        propCard(number: 2, title: "Try a study club",
                 copy: "Explore shared rooms with simulated companions. Real friend sessions are still being built.") {
            HStack(alignment: .bottom, spacing: Theme.Spacing.md) {
                AvatarView(appearance: .maya, status: .focused, size: 46, pose: .sitTypingFront)
                PixelSpeechBubble(text: "Locked in!", icon: .bolt)
                    .scaleEffect(0.85)
                AvatarView(appearance: .leo, status: .focused, size: 46, pose: .sitTypingFront)
            }
        }
    }

    private var card3: some View {
        propCard(number: 3, title: "Build your world",
                 copy: "Complete focus sessions to earn coins and unlock furniture for your room.") {
            HStack(spacing: Theme.Spacing.md) {
                iconTile(.house)
                iconTile(.coin)
                iconTile(.globe)
            }
        }
    }

    private func propCard(number: Int, title: String, copy: String,
                          @ViewBuilder illustration: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Text("\(number)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colour.textOnAccent)
                    .frame(width: 28, height: 28)
                    .background(PixelPanelShape(unit: 2).fill(Theme.Colour.accent))
                    .overlay(PixelPanelShape(unit: 2).stroke(Theme.Colour.appShell, lineWidth: 1.5))
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colour.textPrimary)
                Spacer()
            }
            Text(copy)
                .font(.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            illustration()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.md)
        .background(PixelPanelShape(unit: 4).fill(Theme.Colour.surface))
        .overlay(PixelPanelShape(unit: 4).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
    }

    private func iconTile(_ icon: PixelIcon) -> some View {
        PixelIconView(icon: icon, size: 26, tint: Theme.Colour.textPrimary)
            .frame(width: 44, height: 44)
            .background(PixelPanelShape(unit: 3).fill(Theme.Colour.surfaceMid))
            .overlay(PixelPanelShape(unit: 3).stroke(Theme.Colour.cardBorder, lineWidth: 1.5))
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 18))
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            PageDots(count: 6, active: 1)

            Button("Choose my avatar") { onContinue() }
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("onboarding.continue")

            Button("Skip introduction") { onSkip() }
                .font(.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
                .frame(minHeight: 44)
                .accessibilityLabel("Skip introduction and choose avatar")
                .accessibilityIdentifier("onboarding.skip")
        }
    }

    // MARK: - Animation

    private func animateIn() async {
        if reduceMotion {
            visibleCards = 3
            return
        }
        for i in 1...3 {
            withAnimation(.easeOut(duration: 0.45)) { visibleCards = i }
            try? await Task.sleep(for: .seconds(0.35))
        }
    }
}

#Preview("Value props") {
    ValuePropsView(onContinue: {}, onSkip: {})
        .environment(AppStore())
}
