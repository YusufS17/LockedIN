import SwiftUI

// MARK: - AvatarEntrancePhase (D-25, ONB-05)
//
// Three-phase sequence for the PhaseAnimator avatar entrance in the payoff beat.
// RESEARCH.md Pattern 5 + UI-SPEC.md §Screen 3 §Animation.

enum AvatarEntrancePhase {
    case hidden
    case riseUp
    case settle
}

// MARK: - PayoffBeatView (D-26, ONB-05) — Beat 3 of 4: Avatar Reveal + Name Capture
//
// Matches mockup 03-avatar-reveal-name.png:
//   "You're all set!" heading, avatar on a gold glowing platform with sparkles,
//   cream "Name your avatar" text field, dark charcoal CONFIRM pill.
//
// The avatar enters via PhaseAnimator (hidden → riseUp → settle).
// Reduce Motion: skip scale/offset; opacity-only entrance.
//
// Init: PayoffBeatView(appearance: CharacterAppearance, onComplete: (String) -> Void)
// Does NOT write to AppStore or CharacterPersistence — delegates to OnboardingView.onComplete.

struct PayoffBeatView: View {

    // MARK: - Init

    let appearance: CharacterAppearance
    let onComplete: (String) -> Void

    // MARK: - State

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var displayName = ""
    @State private var showAvatar  = false
    @State private var showHint    = false  // "Enter a name to continue" hint on empty submit

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background — cream theme (not the room; this beat is a card-style reveal)
            Theme.Colour.background.ignoresSafeArea()

            // Main content — vertically centred card layout matching mockup
            VStack(spacing: 0) {
                Spacer()

                // Heading
                headingSection

                Spacer(minLength: Theme.Spacing.xl)

                // Avatar on gold glowing platform (mockup: avatar with sparkles + glow)
                avatarPlatformSection

                Spacer(minLength: Theme.Spacing.xl)

                // Name input card + hint + CTA
                nameInputSection

                Spacer(minLength: Theme.Spacing.md)

                progressDots(active: 2)

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .preferredColorScheme(.light)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                showAvatar = true
            }
        }
    }

    // MARK: - Heading

    private var headingSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // "You're all set!" — matches mockup heading exactly
            Text("You're all set!")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
                .multilineTextAlignment(.center)

            // Heading swaps based on whether a name has been entered
            // ("Meet [name]." when non-empty) — cross-fade via .transition(.opacity)
            Group {
                if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Your avatar is ready to start studying.")
                        .font(Theme.TypeScale.body)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Meet \(displayName.trimmingCharacters(in: .whitespaces)).")
                        .font(Theme.TypeScale.title)
                        .foregroundStyle(Theme.Colour.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: displayName.trimmingCharacters(in: .whitespaces).isEmpty)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Avatar Platform Section

    private var avatarPlatformSection: some View {
        ZStack {
            // Gold glow platform (sparkle colour per Theme — the reveal-moment glow)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colour.sparkle.opacity(0.70),
                            Theme.Colour.sparkle.opacity(0.35),
                            Theme.Colour.sparkle.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 160, height: 60)
                .offset(y: 44)

            // Sparkle dots around the avatar (decorative — matches mockup glow)
            sparkleLayer

            // Avatar — PhaseAnimator entrance OR opacity-only fallback
            avatarEntrance
        }
        .frame(height: 180)
    }

    private var sparkleLayer: some View {
        ZStack {
            // Four sparkle dots at cardinal + diagonal positions
            sparkle(angle: 45,  radius: 55, size: 5)
            sparkle(angle: 135, radius: 55, size: 4)
            sparkle(angle: 225, radius: 50, size: 5)
            sparkle(angle: 315, radius: 55, size: 3)
            sparkle(angle: 0,   radius: 60, size: 4)
            sparkle(angle: 90,  radius: 65, size: 3)
        }
        .opacity(showAvatar ? 1 : 0)
        .animation(reduceMotion ? nil : .easeIn(duration: 0.6).delay(0.5), value: showAvatar)
    }

    private func sparkle(angle: Double, radius: CGFloat, size: CGFloat) -> some View {
        let rad = angle * .pi / 180.0
        return Circle()
            .fill(Theme.Colour.sparkle)
            .frame(width: size, height: size)
            .offset(
                x: CGFloat(cos(rad)) * radius,
                y: CGFloat(sin(rad)) * radius
            )
    }

    // MARK: - Avatar Entrance

    @ViewBuilder
    private var avatarEntrance: some View {
        if reduceMotion {
            // Reduce Motion: opacity-only, no scale/offset (D-25 fallback)
            AvatarView(appearance: appearance, status: .idle, size: 100)
                .opacity(showAvatar ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: showAvatar)
        } else {
            // Full motion: PhaseAnimator with scale + offset entrance (RESEARCH.md Pattern 5)
            AvatarView(appearance: appearance, status: .idle, size: 100)
                .phaseAnimator(
                    [AvatarEntrancePhase.hidden, .riseUp, .settle],
                    trigger: showAvatar
                ) { content, phase in
                    content
                        .scaleEffect(phase == .hidden ? 0.3 : (phase == .riseUp ? 1.1 : 1.0))
                        .opacity(phase == .hidden ? 0 : 1)
                        .offset(y: phase == .riseUp ? -10 : 0)
                } animation: { phase in
                    switch phase {
                    case .hidden:  .easeIn(duration: 0.01)
                    case .riseUp:  .spring(duration: 0.45, bounce: 0.5)
                    case .settle:  .spring(duration: 0.3, bounce: 0.2)
                    }
                }
        }
    }

    // MARK: - Name Input Section

    private var nameInputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Name field on a surface card — matches mockup "Enter name..." field
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Name your avatar")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.textSecondary)
                    .textCase(.uppercase)

                TextField("Enter name...", text: $displayName)
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.surfaceMid)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    .submitLabel(.done)
                    .onSubmit {
                        attemptComplete()
                    }
                    .onChange(of: displayName) { _, new in
                        // V5 security: enforce 30-char max silently (UI-SPEC §Copywriting)
                        // T-02-06: Tampering / display overflow mitigation
                        if new.count > 30 {
                            displayName = String(new.prefix(30))
                        }
                    }

                // Inline hint shown only after a failed CTA tap (empty name)
                if showHint {
                    Text("Enter a name to continue")
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(Theme.Colour.accentSoft)
                        .transition(.opacity)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
            )

            // CONFIRM pill — dark charcoal per mockup 03 (not amber; this is the locked-in action)
            Button(action: attemptComplete) {
                Text("CONFIRM")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
            .opacity(displayName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
        }
    }

    // MARK: - Progress Dots

    private func progressDots(active: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i == active
                          ? Theme.Colour.accent
                          : Theme.Colour.textSecondary.opacity(0.4))
                    .frame(
                        width:  i == active ? 8 : 4,
                        height: i == active ? 8 : 4
                    )
            }
        }
    }

    // MARK: - Actions

    private func attemptComplete() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation { showHint = true }
            return
        }
        onComplete(trimmed)
    }
}

// MARK: - Preview

#Preview("Payoff Beat — default appearance") {
    PayoffBeatView(
        appearance: .default,
        onComplete: { _ in }
    )
    .environment(AppStore())
}
