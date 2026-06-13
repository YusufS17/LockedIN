import Observation

// MARK: - AppStore (CLAUDE.md: single @Observable root store)
//
// The root @Observable store, injected via .environment(appStore) at the WindowGroup root.
// Read in views via @Environment(AppStore.self).
//
// Will later hold SessionStore, WalletStore, and RoomStore as child stores.
// FORBIDDEN: ObservableObject, @Published, @StateObject, Combine (CLAUDE.md).

@Observable
final class AppStore {

    // MARK: - Wallet Seed (D-09)

    /// Simulated wallet balance in Pence (D-09: starts at £20.00 = 2000 pence).
    /// All monetary values are `Pence = Int` — never Double/Float/Decimal (FND-01, SAFE-03).
    var walletBalancePence: Pence = 2000

    // MARK: - Forfeit Destination (D-10)

    /// The named charity where forfeited stakes are donated in test mode (D-10).
    let forfeitDestination: String = "British Red Cross"
}
