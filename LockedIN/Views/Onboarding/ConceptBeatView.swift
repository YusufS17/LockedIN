import SwiftUI

// MARK: - ConceptBeatView (D-24, D-25, ONB-01) — Beat 1 of 4: Welcome
//
// Matches mockup 06-welcome-valueprops.png:
//   "Welcome to LockedIN" heading, small isometric world scene,
//   THREE value-prop rows (Join a room / Focus with friends / Build your world)
//   each with a tiny icon, gold CONTINUE pill, page dots.
//
// Animation: The three value-prop rows stagger in sequentially.
// Reduce Motion: All rows appear simultaneously, opacity-only (no slide, no stagger).
//
// Init: ConceptBeatView(onContinue: () -> Void, onSkip: () -> Void)

struct ConceptBeatView: View {

    // MARK: - Init

    let onContinue: () -> Void
    let onSkip: () -> Void

    // MARK: - State

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var row1Visible = false
    @State private var row2Visible = false
    @State private var row3Visible = false
    @State private var ctaVisible  = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip link — top right
                topBar

                Spacer(minLength: Theme.Spacing.md)

                // Heading
                headingSection

                Spacer(minLength: Theme.Spacing.lg)

                // Isometric world scene illustration area
                worldScene

                Spacer(minLength: Theme.Spacing.lg)

                // Value prop rows
                valuePropRows

                Spacer(minLength: Theme.Spacing.xl)

                // Progress dots + CTA
                bottomSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .task { await animateIn() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") {
                onSkip()
            }
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.textSecondary)
            .accessibilityLabel("Skip onboarding")
        }
    }

    // MARK: - Heading

    private var headingSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Welcome to")
                .font(Theme.TypeScale.title2)
                .foregroundStyle(Theme.Colour.textSecondary)
            Text("LockedIN")
                .font(Theme.TypeScale.largeTitle)
                .foregroundStyle(Theme.Colour.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - World Scene (isometric room as illustration)

    private var worldScene: some View {
        ZStack {
            // Soft glow platform behind the room
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colour.sparkle.opacity(0.30),
                            Theme.Colour.sparkle.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 200, height: 70)
                .offset(y: 50)

            // IsometricRoomView as a decorative illustration (clipped to a rounded card)
            IsometricRoomView()
                .frame(width: 200, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
                )
        }
        .frame(height: 160)
    }

    // MARK: - Value Prop Rows

    private var valuePropRows: some View {
        VStack(spacing: Theme.Spacing.md) {
            if row1Visible {
                valuePropRow(
                    icon: "door.right.hand.open",
                    title: "Join a room",
                    body: "Pick a room, set your stake, and lock in with others."
                )
                .transition(rowTransition)
            }
            if row2Visible {
                valuePropRow(
                    icon: "bolt.fill",
                    title: "Focus with friends",
                    body: "Stay on task and hold each other accountable."
                )
                .transition(rowTransition)
            }
            if row3Visible {
                valuePropRow(
                    icon: "house.fill",
                    title: "Build your world",
                    body: "Earn coins from sessions and grow your study world."
                )
                .transition(rowTransition)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: row3Visible)
    }

    private func valuePropRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Icon in a small amber circle
            ZStack {
                Circle()
                    .fill(Theme.Colour.accent.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Colour.accent)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textPrimary)
                Text(body)
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.Colour.cardBorder, lineWidth: 0.5)
        )
    }

    private var rowTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .opacity.combined(with: .offset(y: 20))
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            progressDots(active: 0)

            // CONTINUE pill — amber/gold per mockup 06 design (gold CTA on welcome)
            if ctaVisible {
                Button(action: onContinue) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("CONTINUE")
                            .font(Theme.TypeScale.headline)
                            .foregroundStyle(Theme.Colour.textOnAccent)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.Colour.textOnAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
                }
                .transition(reduceMotion ? .opacity : .opacity)
            }

            // "Already have an account? Log in" — soft skip link per mockup
            Button("Already have an account? Log in") {
                onSkip()
            }
            .font(Theme.TypeScale.caption)
            .foregroundStyle(Theme.Colour.textSecondary)
            .accessibilityLabel("Skip onboarding")
        }
    }

    // MARK: - Progress Dots

    /// 3-dot progress indicator. Active dot: 8×8pt amber. Inactive: 4×4pt textSecondary@40%.
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

    // MARK: - Animation

    /// Animates value-prop rows in sequentially (stagger 0.6s each).
    /// Reduce Motion: all rows appear simultaneously with opacity only — no stagger, no offset.
    private func animateIn() async {
        if reduceMotion {
            row1Visible = true
            row2Visible = true
            row3Visible = true
            ctaVisible  = true
            return
        }
        withAnimation(.easeOut(duration: 0.5)) { row1Visible = true }
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation(.easeOut(duration: 0.5)) { row2Visible = true }
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation(.easeOut(duration: 0.5)) { row3Visible = true }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeOut(duration: 0.4)) { ctaVisible = true }
    }
}

// MARK: - Preview

#Preview("Welcome Beat") {
    ConceptBeatView(onContinue: {}, onSkip: {})
}
