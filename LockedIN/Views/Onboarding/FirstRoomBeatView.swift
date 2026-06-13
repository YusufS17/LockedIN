import SwiftUI

// MARK: - FirstRoomBeatView — Beat 4 of 4: First Room Arrival
//
// Matches mockup 04-first-room.png:
//   "This is your first room" heading,
//   "Your space. Your focus. Your journey." body,
//   IsometricRoomView with the user's AvatarView placed at the desk slot in a cream card,
//   dark charcoal "EXPLORE ROOM" pill.
//
// This beat bridges the onboarding payoff to the Home screen.
// Init: FirstRoomBeatView(appearance: CharacterAppearance, displayName: String, onExplore: () -> Void)

struct FirstRoomBeatView: View {

    // MARK: - Init

    let appearance: CharacterAppearance
    let displayName: String
    let onExplore: () -> Void

    // MARK: - State

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var avatarVisible = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Heading block
                headingSection

                Spacer(minLength: Theme.Spacing.xl)

                // Room card with avatar (matches mockup: cream card with room inside)
                roomCard

                Spacer(minLength: Theme.Spacing.xl)

                // Progress dots + CTA
                bottomSection

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .preferredColorScheme(.light)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation(reduceMotion ? nil : .easeIn(duration: 0.4)) {
                    avatarVisible = true
                }
            }
        }
    }

    // MARK: - Heading

    private var headingSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("This is your\nfirst room")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Your space.")
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Text("Your focus.")
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Text("Your journey.")
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Room Card

    private var roomCard: some View {
        ZStack {
            // IsometricRoomView as the card background
            IsometricRoomView()
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))

            // Avatar at desk slot (50% x, 58% y) — matches IsometricRoomView desk convention
            GeometryReader { geo in
                AvatarView(appearance: appearance, status: .idle, size: 72)
                    .position(
                        x: geo.size.width  * 0.50,
                        y: geo.size.height * 0.58
                    )
                    .opacity(avatarVisible ? 1 : 0)
            }
            .frame(height: 240)
        }
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.Colour.textSecondary.opacity(0.10), radius: 8, x: 0, y: 4)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            progressDots(active: 3)

            // EXPLORE ROOM pill — dark charcoal (matches mockup 04)
            Button(action: onExplore) {
                Text("EXPLORE ROOM")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
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
}

// MARK: - Preview

#Preview("First Room Beat") {
    FirstRoomBeatView(
        appearance: .default,
        displayName: "Alex",
        onExplore: {}
    )
}
