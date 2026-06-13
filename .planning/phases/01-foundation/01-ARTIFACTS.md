# Phase 1 — Artifacts Produced

> Every symbol this phase CREATES. The source-grounding pass reads this to exclude newly-created symbols from drift verification. All of these are NEW — none exist in the codebase before Phase 1.

## Type aliases (Models/Money.swift)

- `Pence` — `typealias Pence = Int`
- `MinorUnits` — `typealias MinorUnits = Int` (alias of Pence)

## Functions (Models/Money.swift)

- `formatPence(_ amount: Pence, currencyCode: String = "GBP") -> String` — the single display-boundary money formatter (always 2 decimals)

## SwiftUI components

- `MoneyLabel` (Design/MoneyLabel.swift) — `struct MoneyLabel: View`; init `MoneyLabel(_ amount: Pence, compact: Bool = false)`. The ONLY sanctioned `£` renderer; always emits the TEST marker. (Also referred to as TestModeBadge in the design system; the TEST marker is rendered inline by MoneyLabel.)
- `RootView` (App/RootView.swift) — Walking Skeleton root screen
- `LockedINApp` (App/LockedINApp.swift) — `@main App`

## Stores (App/AppStore.swift)

- `AppStore` — `@Observable final class AppStore`; properties: `walletBalancePence: Pence = 2000`, `forfeitDestination = "British Red Cross"`, `commitmentService: CommitmentService`, `focusAdapter: FocusControlAdapter`. Injected via `.environment()` at the WindowGroup root.

## Feature flags (Design/FeatureFlags.swift)

- `FeatureFlags` — `enum FeatureFlags` with static constants:
  - `ENABLE_REAL_MONEY_STAKES = false`
  - `ENABLE_TEST_STAKES = true`
  - `ENABLE_ROOM_PRIZE_POOL = false`
  - `ENABLE_SPONSORED_REWARDS = true`

## Design tokens (Design/Theme.swift)

- `Theme` — palette tokens (background, surface, primary accent, success/return green, forfeit/warning amber-red, text), type-scale Font tokens (largeTitle/title/headline/body/caption), spacing constants (xs/sm/md/lg). Exact names/hex at executor discretion (D-06).

## Enums (Models/)

- `ParticipantSettlementState` (Models/ParticipantSettlementState.swift) — EXACTLY 8 cases:
  - `notRequired`
  - `awaitingAuthorisation`
  - `held`
  - `authorisedForReturn`
  - `authorisedForForfeit`
  - `returned`
  - `forfeited`
  - `settlementError`
- `SettlementVerdict` (Models/SettlementRecord.swift) — `passed`, `failed`
- `FocusEvent` (Models/FocusEvent.swift) — `distractionStarted`, `distractionEnded`, `breakStarted`, `breakEnded`, `leftSession` (each carries participantID: UUID + at: Date only)

## Structs (Models/)

- `HoldReference` (Models/SettlementRecord.swift) — `Identifiable, Hashable` (id, participantID, amountMinorUnits)
- `SettlementRecord` (Models/SettlementRecord.swift) — holdRef, verdict, returnedMinorUnits, forfeitedMinorUnits, settledAt, isTestMode
- `CommitmentContract` (Models/CommitmentContract.swift) — frozen struct; `let` term fields, `private(set) var frozenAt: Date?`, `var isFrozen: Bool`, `func frozen() -> CommitmentContract`
- `Participant` (Models/Participant.swift) — id, displayName, isBot

## Protocols (Services/)

- `CommitmentService` (Services/CommitmentService.swift) — `authoriseHold(...)`, `settle(...)`, `walletBalance(...)`
- `FocusControlAdapter` (Services/FocusControlAdapter.swift) — `startMonitoring(participantID:) -> AsyncStream<FocusEvent>`, `stopMonitoring(participantID:)`

## Mock implementations (Services/)

- `MockCommitmentService` (Services/MockCommitmentService.swift) — in-memory wallet seeded at 2000 pence; `forfeitDestination = "British Red Cross"`; money-conserving settle
- `MockFocusControlAdapter` (Services/MockFocusControlAdapter.swift) — scripted AsyncStream<FocusEvent> emitter (Maya/Leo/Sam scripts deferred to Phase 3)

## New file paths

- `LockedIN.xcodeproj/project.pbxproj`
- `LockedIN/App/LockedINApp.swift`
- `LockedIN/App/AppStore.swift`
- `LockedIN/App/RootView.swift`
- `LockedIN/Models/Money.swift`
- `LockedIN/Models/CommitmentContract.swift`
- `LockedIN/Models/Participant.swift`
- `LockedIN/Models/ParticipantSettlementState.swift`
- `LockedIN/Models/SettlementRecord.swift`
- `LockedIN/Models/FocusEvent.swift`
- `LockedIN/Design/Theme.swift`
- `LockedIN/Design/FeatureFlags.swift`
- `LockedIN/Design/MoneyLabel.swift`
- `LockedIN/Services/CommitmentService.swift`
- `LockedIN/Services/MockCommitmentService.swift`
- `LockedIN/Services/FocusControlAdapter.swift`
- `LockedIN/Services/MockFocusControlAdapter.swift`
- `LockedIN/Assets.xcassets/` (Contents.json, AppIcon.appiconset, AccentColor.colorset)
