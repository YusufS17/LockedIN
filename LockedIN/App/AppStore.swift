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

    // MARK: - Service Boundaries (FND-02, FND-03, SAFE-04, T-01-08)

    /// Payment/settlement service boundary.
    ///
    /// Protocol-typed so UI/session code never references a concrete payment type directly.
    /// Mocked for the prototype; swap for `StripeCommitmentService` in v2 (PAY-01).
    let commitmentService: CommitmentService

    /// Focus-tracking service boundary.
    ///
    /// Protocol-typed so UI/session code never references a concrete tracking type directly.
    /// Mocked for the prototype; swap for `RealScreenTimeFocusControlAdapter` in v2 (REAL-01).
    let focusAdapter: FocusControlAdapter

    // MARK: - Init

    /// Inject service implementations.
    /// Defaults to the mock implementations so the prototype works out of the box.
    init(
        commitmentService: CommitmentService = MockCommitmentService(),
        focusAdapter: FocusControlAdapter = MockFocusControlAdapter()
    ) {
        self.commitmentService = commitmentService
        self.focusAdapter = focusAdapter
    }
}
