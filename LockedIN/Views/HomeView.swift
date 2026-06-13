import SwiftUI

// MARK: - HomeView (D-26, D-28, ONB-04) — Post-onboarding landing
//
// Matches mockup 05-welcome-splash.png direction:
//   IsometricRoomView fills the screen (the cozy room is the home).
//   Top gradient overlay with greeting "Hi, [name]." / "Ready to lock in?".
//   Avatar at desk slot (80pt).
//   Bottom action card: mini avatar (48pt) + displayName + status "Idle" + "Start a room" CTA.
//
// Reads appStore.userCharacter + appStore.displayName.
// Fallback: displayName.isEmpty → "You"; userCharacter → .default (already guaranteed by
// CharacterPersistence.load() in AppStore.init and onboarding skip path).
//
// "Start a room" is a Phase 3 placeholder — no navigation yet; leave comment.

struct HomeView: View {

    // MARK: - Environment

    @Environment(AppStore.self) private var appStore

    // MARK: - State

    @State private var avatarOpacity: Double = 0
    @State private var showRoom = false

    // MARK: - Computed

    private var name: String {
        appStore.displayName.isEmpty ? "You" : appStore.displayName
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cream backdrop + cozy room mockup image (design-matched)
            Theme.Colour.background.ignoresSafeArea()

            Image("Onboard6")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, Theme.Spacing.md)
                .opacity(avatarOpacity)

            // Foreground VStack: top greeting + bottom action card
            VStack(spacing: 0) {
                topGreeting
                Spacer()
                bottomActionCard
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showRoom) {
            RoomFlowView()
                .environment(appStore)
        }
        .onAppear {
            // Opacity-only fade-in — already Reduce Motion-safe
            withAnimation(.easeIn(duration: 0.3)) {
                avatarOpacity = 1
            }
        }
    }

    // MARK: - Top Greeting Overlay

    private var topGreeting: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Hi, \(name).")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Ready to lock in?")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
        .background(
            LinearGradient(
                colors: [
                    Theme.Colour.background.opacity(0.85),
                    Theme.Colour.background.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Bottom Action Card

    private var bottomActionCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // name + status row
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colour.accent)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(name)
                        .font(Theme.TypeScale.headline)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Text("Idle")
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(Theme.Colour.textSecondary)
                }

                Spacer()
            }

            // "Start a room" — launches the core commit → session → reveal loop
            Button {
                showRoom = true
            } label: {
                Text("Start a room")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
    }
}

// MARK: - Preview

#Preview("HomeView — default avatar") {
    HomeView()
        .environment(AppStore())
}
