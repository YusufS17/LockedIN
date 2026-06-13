import SwiftUI

// MARK: - HomeView — post-onboarding landing
//
// Clean cream home: greeting + the one preset room tile ("£5 Serious Lock-In") +
// a primary "Start a room" CTA that launches the core loop (RoomFlowView).
// Well-proportioned with spacers; no floating mockup imagery.

struct HomeView: View {

    @Environment(AppStore.self) private var appStore
    @State private var showRoom = false

    private var name: String {
        appStore.displayName.isEmpty ? "You" : appStore.displayName
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {

                // Greeting
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Hi, \(name).")
                        .font(Theme.TypeScale.largeTitle)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Text("Ready to lock in?")
                        .font(Theme.TypeScale.body)
                        .foregroundStyle(Theme.Colour.textSecondary)
                }
                .padding(.top, Theme.Spacing.md)

                Spacer()

                // Preset room tile
                Button { showRoom = true } label: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ZStack {
                                Circle().fill(Theme.Colour.accent.opacity(0.25)).frame(width: 52, height: 52)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Theme.Colour.accent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("£5 Serious Lock-In")
                                    .font(Theme.TypeScale.title2)
                                    .foregroundStyle(Theme.Colour.textPrimary)
                                Text("25 min · 1 break · with Maya, Leo & Sam")
                                    .font(Theme.TypeScale.caption)
                                    .foregroundStyle(Theme.Colour.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.Colour.textSecondary)
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            Text("Stake")
                                .font(Theme.TypeScale.caption)
                                .foregroundStyle(Theme.Colour.textSecondary)
                            MoneyLabel(500, compact: true)
                            Spacer()
                            Text("Forfeit → ❤️ British Red Cross")
                                .font(Theme.TypeScale.caption)
                                .foregroundStyle(Theme.Colour.textSecondary)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colour.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .strokeBorder(Theme.Colour.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Primary CTA
                Button { showRoom = true } label: {
                    Text("Start a room")
                        .font(Theme.TypeScale.headline)
                        .foregroundStyle(Theme.Colour.buttonText)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colour.buttonFill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
                }

                Spacer()

                Text("TEST MODE — NO REAL MONEY WILL MOVE")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.testBadgeFg)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showRoom) {
            RoomFlowView().environment(appStore)
        }
    }
}

#Preview("HomeView") {
    HomeView().environment(AppStore())
}
