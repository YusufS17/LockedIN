import Foundation
import Observation

// MARK: - AppStore (CLAUDE.md: single @Observable root store)
//
// The root @Observable store, injected via .environment(appStore) at the WindowGroup root.
// Read in views via @Environment(AppStore.self).
//
// Will later hold SessionStore, WalletStore, and RoomStore as child stores.
// FORBIDDEN: ObservableObject, @Published, @StateObject, Combine (CLAUDE.md).

// MARK: - Forfeit Config (D-10, WR-02)

/// Single source of truth for the forfeit destination name (D-10).
/// Referenced by both `AppStore` and `MockCommitmentService` to prevent silent divergence (WR-02).
enum ForfeitConfig {
    static let destination = "British Red Cross"
}

// MARK: - AppStore

@Observable
final class AppStore {

    // MARK: - Forfeit Destination (D-10)

    /// The named charity where forfeited stakes are donated in test mode (D-10).
    /// Derived from `ForfeitConfig.destination` — single source of truth (WR-02).
    let forfeitDestination: String = ForfeitConfig.destination

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

    // MARK: - Wallet Balance (WR-01)

    /// Returns the current wallet balance in pence for the given participant.
    ///
    /// Derives directly from `commitmentService` — the single source of truth for
    /// wallet state. This avoids the stale-copy hazard of a stored `walletBalancePence`
    /// property in `AppStore` that would diverge after `authoriseHold`/`settle` (WR-01).
    ///
    /// All monetary values are `Pence = Int` — never Double/Float/Decimal (FND-01, SAFE-03).
    func currentBalance(for participantID: UUID) async -> Pence {
        await commitmentService.walletBalance(participantID: participantID)
    }
}
