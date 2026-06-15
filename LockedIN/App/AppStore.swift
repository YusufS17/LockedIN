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

    // MARK: - World / Progression (Phase 7)

    /// The persisted world economy: Focus XP, coins, level, and the district's buildings.
    /// Sessions award rewards here; progress survives relaunch (CLAUDE.md local persistence).
    let world = WorldStore()

    // MARK: - User Identity (Phase 2, ONB-04)
    //
    // Plain var — @Observable tracks these automatically.
    // Do NOT use @AppStorage here: @Observable classes cannot hold property wrappers
    // that are themselves observation-tracked (RESEARCH.md Pitfall 8).
    // Do NOT log these values (T-02-05: identity data must not appear in captured logs).

    /// The user's chosen avatar appearance. Defaults to `.default` if no persisted value.
    var userCharacter: CharacterAppearance = .default

    /// The user's chosen display name. Defaults to `""` until onboarding completes.
    var displayName: String = ""

    /// The id of the user's chosen gallery character (`StudyCharacter.id`). Persisted directly
    /// (not via @AppStorage — @Observable cannot hold property wrappers, RESEARCH Pitfall 8).
    var selectedCharacterID: String = CharacterCatalog.first.id {
        didSet { UserDefaults.standard.set(selectedCharacterID, forKey: PersistenceKeys.selectedCharacter) }
    }

    /// The chosen character resolved from the catalog.
    var selectedCharacter: StudyCharacter { CharacterCatalog.character(id: selectedCharacterID) }

    /// The user's avatar as a `StudyCharacter`, built from their editable `userCharacter`
    /// appearance — the single source of truth for how the user looks everywhere (rooms,
    /// reveal, world). Reflects customization immediately. Renders the custom appearance
    /// via SpriteAvatarView's code-drawn fallback (no `char_you` PNG required).
    var userStudyCharacter: StudyCharacter {
        StudyCharacter(id: "you",
                       name: displayName.isEmpty ? "You" : displayName,
                       spriteAsset: "char_you",
                       fallback: userCharacter)
    }

    // MARK: - Init

    /// Inject service implementations.
    /// Defaults to the mock implementations so the prototype works out of the box.
    init(
        commitmentService: CommitmentService = MockCommitmentService(),
        focusAdapter: FocusControlAdapter = MockFocusControlAdapter()
    ) {
        self.commitmentService = commitmentService
        self.focusAdapter = focusAdapter
        // Restore persisted identity on start (ONB-04).
        // Falls back to .default / "" if no data saved or data is corrupt (T-02-03).
        if let saved = CharacterPersistence.load() {
            self.userCharacter = saved.appearance
            self.displayName   = saved.displayName
        }
        if let savedID = UserDefaults.standard.string(forKey: PersistenceKeys.selectedCharacter) {
            self.selectedCharacterID = savedID
        }
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
