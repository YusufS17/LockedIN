# Walking Skeleton — LockedIN

**Phase:** 1
**Generated:** 2026-06-13

## Capability Proven End-to-End

A `Pence` integer flows from the `@Observable` `AppStore` (injected at the `WindowGroup` root via `.environment()`) through the single display-boundary formatter into the `MoneyLabel` component, and renders on the root screen of a running iOS 17 SwiftUI app as `£20.00` with the "TEST MODE — NO REAL MONEY WILL MOVE" marker baked inline — proving the money-correct, safety-first substrate compiles and renders on the iOS 17 simulator.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| UI framework | SwiftUI, iOS 17 deployment target | `@Observable` macro is the hard lower bound; iOS 17 removes all `#available` guards (CLAUDE.md LOCKED) |
| Language mode | Swift 5 (`SWIFT_VERSION = 5.0`) on the Xcode 16 compiler | Avoids Swift 6 strict-concurrency `Sendable` friction during a 5h build; keeps compiler speed (CLAUDE.md LOCKED) |
| State management | Single `@Observable final class AppStore`, injected via `.environment()` at the root; read via `@Environment(AppStore.self)` | Lightest correct shared-state choice; AppStore will hold SessionStore/WalletStore/RoomStore in later phases. FORBIDDEN: ObservableObject, @Published, @StateObject, Combine, MVVM, TCA (CLAUDE.md) |
| Money representation | `typealias Pence = Int` (and `MinorUnits = Int`), 500 == £5.00; one `formatPence()` at the display boundary only | Exact integer arithmetic; FORBIDDEN: Double, Float, Decimal for money (FND-01, SAFE-03) |
| TEST MODE enforcement | `MoneyLabel` is the ONLY sanctioned `£` renderer; it always emits the TEST marker, gated on `ENABLE_REAL_MONEY_STAKES=false` | Makes money-without-marker structurally impossible rather than per-screen discipline (D-02, SAFE-01) |
| Feature flags | `enum FeatureFlags` with 4 locked static constants, READ at their boundaries | Honoured not just declared: REAL_MONEY=false, TEST_STAKES=true, ROOM_PRIZE_POOL=false, SPONSORED_REWARDS=true (FND-05, SAFE-02, D-12) |
| Service boundaries | `CommitmentService` + `FocusControlAdapter` protocols, mock impls injected as protocol-typed AppStore properties | Stripe / Screen Time can slot in later without touching UI/session; payment logic stays out of UI (FND-02, FND-03, SAFE-04) |
| Settlement model | `ParticipantSettlementState` enum, EXACTLY 8 canonical states (typed, never String) | No ad-hoc/typo states; conserves money across transitions (FND-04, D-11) |
| Persistence | In-memory only (mock wallet is a dictionary) | No resume requirement in demo scope; FORBIDDEN: SwiftData, UserDefaults, @AppStorage (CLAUDE.md) |
| Dependencies | Zero third-party packages | Apple frameworks only; no SPM `packageReferences`; no install/supply-chain surface |
| Xcode project | Hand-authored `LockedIN.xcodeproj` using a `PBXFileSystemSynchronizedRootGroup` over `LockedIN/` | No xcodegen/tuist available; synchronized root group means later phases drop `.swift` files into the folder without editing pbxproj |
| Directory layout | `LockedIN/{App, Models, Design}` now; `{Services, Engine, UI}` added as later phases need them | Mirrors the layered architecture: Models (pure value types) -> Services (protocol seams) -> Engine -> UI; Models/Services never import SwiftUI |

## Stack Touched in Phase 1

- [x] Project scaffold — hand-authored `LockedIN.xcodeproj`, iOS 17 target, Swift 5, zero deps, synchronized file group, Assets.xcassets (Plan 01-01 Task 1) — commit 89cabba
- [x] App entry + routing — `LockedINApp` (`@main`, `WindowGroup { RootView() }`) with `.environment(appStore)` (Plan 01-01 Task 3) — commit 4b9db22
- [ ] "Data layer" (in-memory) — `MockCommitmentService` simulated wallet read/write (authoriseHold deducts, settle credits) seeded at 2000 pence (Plan 01-02 Task 2)
- [x] UI wired to the substrate — `RootView` reads `@Environment(AppStore.self)` and renders `MoneyLabel(appStore.walletBalancePence)` (Plan 01-01 Task 3) — commit 4b9db22
- [x] Full-stack run — `xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -destination 'platform=iOS Simulator,name=iPhone 16' build CODE_SIGNING_ALLOWED=NO` exits 0; the root screen renders the seeded £20.00 with the TEST marker on the iOS 17 (run on 18.6 sim) target — confirmed BUILD SUCCEEDED

> Executor: update these checkboxes to `[x]` as each is delivered.

## Out of Scope (Deferred to Later Slices)

This phase is plumbing + one design-system component. NOT in the skeleton:

- Any user-facing flow beyond the `MoneyLabel` render: no lobby, contract, session, shield, results, or world screens.
- `SessionCoordinator`, `BotScriptEngine`, `TitleAssigner`, `ContractRules` (Phase 2-3 engine layer). The mock focus adapter proves the *seam* but the Maya/Leo/Sam scripts are Phase 3.
- Real `StripeCommitmentService` / real Screen Time `FocusControlAdapter` — v2 (PAY-01/02, REAL-01/02). The protocols stay clean enough that these slot in later; they are not built now.
- Room prize pool as a forfeit destination — gated behind `ENABLE_ROOM_PRIZE_POOL=false` (v2 STAKE-02).
- LockedIN coin economy / world growth (Phase 6); commitment £ and coins are kept structurally separate (SAFE-04).
- Any persistence (SwiftData/UserDefaults) — Phase 6 adds local world/coin persistence only.

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- **Phase 2 — Room & Contract:** preset £5 room -> contract review (consumes `MoneyLabel`, `CommitmentContract`, `MockCommitmentService.authoriseHold`) -> per-participant accept -> visible contract freeze.
- **Phase 3 — Session Engine & Tracking:** `SessionCoordinator` + `BotScriptEngine` + `ContractRules` driving the `MockFocusControlAdapter` seam with the Maya/Leo/Sam scripts; deterministic pass/fail.
- **Phase 4 — Screen Shield & Interruption:** full-screen overlay + hold-to-confirm forfeit gate + honest emergency exit, driven by the focus adapter's scripted distraction events.
- **Phase 5 — Results & Settlement:** `MockCommitmentService.settle` drives `ParticipantSettlementState` to returned/forfeited; sequenced reveal with `MoneyLabel` on every figure (£15 returned / £5 forfeited).
- **Phase 6 — Rewards, Coins & World:** idle coins (separate economy), personal/shared world growth, local persistence — the first phase to add SwiftData/UserDefaults.
