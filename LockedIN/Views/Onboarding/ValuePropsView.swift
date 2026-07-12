import SwiftUI

// MARK: - ValuePropsView — Beat 2 of 6: how LockedIN works
//
// Matches mockup 06-welcome-valueprops: book mark over "Welcome to LockedIN",
// three numbered cards (Join a room / Focus with friends / Build your world),
// each pairing copy with a live-sprite illustration, gold CONTINUE pixel CTA and
// the "Already have an account? Log in" soft skip.

struct ValuePropsView: View {

    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCards = 0
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            OnboardingBackdrop()

            VStack(spacing: 0) {
                heading
                    .padding(.top, Theme.Spacing.lg)

                Spacer(minLength: Theme.Spacing.md)

                VStack(spacing: Theme.Spacing.md) {
                    if visibleCards > 0 { card1.transition(cardTransition) }
                    if visibleCards > 1 { card2.transition(cardTransition) }
                    if visibleCards > 2 { card3.transition(cardTransition) }
                }

                Spacer(minLength: Theme.Spacing.lg)

                bottomSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .task { await animateIn() }
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(spacing: Theme.Spacing.xs) {
            PixelIconView(icon: .book, size: 30, tint: Theme.Colour.textPrimary)
            Text("Welcome to LockedIN")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Stay accountable. Build your world.")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var card1: some View {
        propCard(number: 1, title: "Join a room",
                 copy: "Pick a room that matches your vibe and goals.") {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(CharacterCatalog.all.prefix(4))) { ch in
                    AvatarPortraitView(appearance: ch.fallback, size: 38)
                }
            }
        }
    }

    private var card2: some View {
        propCard(number: 2, title: "Focus with friends",
                 copy: "Study together in real time. Stay on track and keep each other motivated.") {
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
                 copy: "Unlock items, customise your room, and grow your world together.") {
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
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textOnAccent)
                    .frame(width: 28, height: 28)
                    .background(PixelPanelShape(unit: 2).fill(Theme.Colour.accent))
                    .overlay(PixelPanelShape(unit: 2).stroke(Theme.Colour.appShell, lineWidth: 1.5))
                Text(title)
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textPrimary)
                Spacer()
            }
            Text(copy)
                .font(Theme.TypeScale.caption)
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

            Button("CONTINUE") { onContinue() }
                .buttonStyle(PixelButtonStyle(kind: .gold))
                .opacity(ctaVisible ? 1 : 0)

            Button("Already have an account? Log in") { onSkip() }
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.textSecondary)
                .accessibilityLabel("Skip onboarding")
        }
    }

    // MARK: - Animation

    private func animateIn() async {
        if reduceMotion {
            visibleCards = 3
            ctaVisible = true
            return
        }
        for i in 1...3 {
            withAnimation(.easeOut(duration: 0.45)) { visibleCards = i }
            try? await Task.sleep(for: .seconds(0.35))
        }
        withAnimation(.easeOut(duration: 0.4)) { ctaVisible = true }
    }
}

#Preview("Value props") {
    ValuePropsView(onContinue: {}, onSkip: {})
        .environment(AppStore())
}
