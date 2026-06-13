import SwiftUI

// MARK: - RootView
//
// Walking Skeleton end-to-end render slice (Phase 1 proof).
// Reads AppStore via @Environment and renders MoneyLabel for the seeded wallet balance.
// Proves: Pence -> formatPence -> MoneyLabel -> £X.XX + TEST marker all compile and render.

struct RootView: View {
    @Environment(AppStore.self) private var appStore

    // Demo stake sample: £5.00 (500 pence)
    private let stakeSamplePence: Pence = 500

    // WR-01: Wallet balance is now derived from CommitmentService (single source of truth).
    // For this walking-skeleton screen, which has no real participant UUID, we show the
    // seeded starting balance as a display constant. Phase 2+ views will call
    // appStore.currentBalance(for: participantID) with a real UUID inside .task {}.
    @State private var displayBalancePence: Pence = MockCommitmentService.startingBalance

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colour.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {

                        // MARK: Header
                        headerSection

                        // MARK: Wallet Balance
                        walletSection

                        // MARK: Stake Sample
                        stakeSection

                        // MARK: Forfeit Destination
                        forfeitSection
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("LockedIN")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Walking Skeleton")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.accent)
                .textCase(.uppercase)

            Text("Foundation Substrate")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)

            Text("Proves the end-to-end money render: Pence → MoneyLabel → £X.XX with TEST marker.")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Simulated Wallet Balance")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
                .textCase(.uppercase)

            surfaceCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    MoneyLabel(displayBalancePence)
                }
            }
        }
    }

    private var stakeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Stake Sample (Compact Label)")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
                .textCase(.uppercase)

            surfaceCard {
                HStack {
                    Text("£5.00 Serious Lock-In stake")
                        .font(Theme.TypeScale.callout)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Spacer()
                    MoneyLabel(stakeSamplePence, compact: true)
                }
            }
        }
    }

    private var forfeitSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Forfeit Destination")
                .font(Theme.TypeScale.captionBold)
                .foregroundStyle(Theme.Colour.textSecondary)
                .textCase(.uppercase)

            surfaceCard {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.Colour.forfeitRed)
                    Text(appStore.forfeitDestination)
                        .font(Theme.TypeScale.callout)
                        .foregroundStyle(Theme.Colour.textPrimary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func surfaceCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surfaceMid)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

// MARK: - Preview

#Preview {
    let store = AppStore()
    return RootView()
        .environment(store)
}
