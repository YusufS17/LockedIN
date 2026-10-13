import SwiftUI

// First-room arrival connects the saved identity to earned room upgrades.

struct FirstRoomBeatView: View {

    // MARK: - Init

    let appearance: CharacterAppearance
    let displayName: String
    let onExplore: () -> Void

    // MARK: - State

    @ReducedMotionPreference private var reduceMotion
    @State private var avatarVisible = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headingSection
                    roomCard
                    Text("Finish focus sessions to earn coins, then make this space your own.")
                        .font(.body)
                        .foregroundStyle(Theme.Colour.textSecondary)
                        .multilineTextAlignment(.center)
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
        .preferredColorScheme(.light)
        .task {
            guard !Task.isCancelled else { return }
            if !reduceMotion {
                do { try await Task.sleep(for: .seconds(0.3)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.4)) {
                avatarVisible = true
            }
        }
    }

    // MARK: - Heading

    private var headingSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Welcome home, \(displayName)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colour.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Your space.")
                    .font(.body)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Text("Your focus.")
                    .font(.body)
                    .foregroundStyle(Theme.Colour.textSecondary)
                Text("Your journey.")
                    .font(.body)
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

            // Avatar stands on the open front floor beside the desk (mockup 04).
            GeometryReader { geo in
                let cell = RoomLayout.scale(in: geo.size)
                let feet = RoomLayout.project(RoomLayout.heroStand, in: geo.size)
                let h = 44 * cell
                AvatarView(appearance: appearance, status: .idle, size: h)
                    .position(x: feet.x, y: feet.y - h / 2)
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
            PageDots(count: 6, active: 5)

            Button("Explore my room", action: onExplore)
                .buttonStyle(StudioButtonStyle(primary: true))
                .accessibilityIdentifier("onboarding.finish")
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
