---
phase: 01-foundation
plan: 01
subsystem: ui
tags: [swiftui, ios17, observable, xcode16, money-types, design-tokens]

requires: []

provides:
  - "Buildable iOS 17 SwiftUI Xcode project (PBXFileSystemSynchronizedRootGroup, objectVersion 77)"
  - "typealias Pence = Int + typealias MinorUnits = Int — the canonical money type"
  - "func formatPence() — single display-boundary £ formatter (integer arithmetic, always 2dp)"
  - "ParticipantSettlementState — all 8 canonical states typed as enum"
  - "enum FeatureFlags — 4 locked flags (ENABLE_REAL_MONEY_STAKES=false, ENABLE_TEST_STAKES=true, ENABLE_ROOM_PRIZE_POOL=false, ENABLE_SPONSORED_REWARDS=true)"
  - "struct MoneyLabel — the ONLY sanctioned £ renderer; always emits TEST marker; flag honoured at render boundary"
  - "@Observable final class AppStore — root store, walletBalancePence = 2000, forfeitDestination = 'British Red Cross'"
  - "LockedINApp @main + .environment(appStore) injection at WindowGroup root"
  - "RootView — end-to-end Walking Skeleton render: £20.00 seeded balance + £5.00 compact stake sample with TEST markers"
  - "enum Theme — warm dark-academia colour palette, rounded type scale, spacing/radius tokens"

affects:
  - "02-lobby-contract"
  - "03-session-engine"
  - "04-interruption-shield"
  - "05-results-settlement"
  - "06-rewards-world"

tech-stack:
  added:
    - "Swift 5.9 @Observable macro (Observation framework, iOS 17+)"
    - "SwiftUI (iOS 17+ API surface)"
    - "Xcode 16.4, objectVersion 77 pbxproj"
  patterns:
    - "Single @Observable AppStore injected via .environment() — all views use @Environment(AppStore.self)"
    - "Pence = Int minor units everywhere; formatPence() called only at MoneyLabel display boundary"
    - "MoneyLabel as structural guard — money-without-TEST-marker is impossible by construction"
    - "PBXFileSystemSynchronizedRootGroup — new .swift files added to LockedIN/ folder are picked up without pbxproj surgery"

key-files:
  created:
    - "LockedIN.xcodeproj/project.pbxproj"
    - "LockedIN.xcodeproj/xcshareddata/xcschemes/LockedIN.xcscheme"
    - "LockedIN/Assets.xcassets/{Contents.json,AppIcon.appiconset/Contents.json,AccentColor.colorset/Contents.json}"
    - "LockedIN/Models/Money.swift"
    - "LockedIN/Design/FeatureFlags.swift"
    - "LockedIN/Design/Theme.swift"
    - "LockedIN/Design/MoneyLabel.swift"
    - "LockedIN/App/AppStore.swift"
    - "LockedIN/App/LockedINApp.swift"
    - "LockedIN/App/RootView.swift"
  modified:
    - ".planning/phases/01-foundation/SKELETON.md (4 of 5 checkboxes ticked)"

key-decisions:
  - "PBXFileSystemSynchronizedRootGroup (objectVersion 77) used so future phase .swift files are auto-included without editing pbxproj"
  - "formatPence() uses integer division/modulo (not NumberFormatter) for guaranteed 2dp with no floating-point surface"
  - "MoneyLabel reads ENABLE_REAL_MONEY_STAKES at render boundary — flag is honoured structurally, not just declared"
  - "AppStore seeds walletBalancePence = 2000 (£20.00) and forfeitDestination = 'British Red Cross' as D-09/D-10 mandated"
  - "Assets.xcassets delivered inside the LockedIN/ sync group (no separate PBXBuildFile reference needed) — cleaner than an exception set"

patterns-established:
  - "Money: always Pence = Int; formatPence() called only inside MoneyLabel; no other view renders £ directly"
  - "State: @Observable final class, injected via .environment() — FORBIDDEN: ObservableObject, @Published, @StateObject, Combine"
  - "TEST enforcement: MoneyLabel is the guard; FeatureFlags.ENABLE_REAL_MONEY_STAKES is the honoured gate"

requirements-completed: [FND-01, FND-05, SAFE-01, SAFE-02, SAFE-03, SAFE-04]

duration: 20min
completed: 2026-06-13
---

# Phase 1 Plan 01: Foundation Walking Skeleton Summary

**Buildable iOS 17 SwiftUI app with Pence = Int money type, single formatPence() formatter, MoneyLabel structural TEST MODE guard, @Observable AppStore, and end-to-end root render of £20.00 + £5.00 TEST-marked amounts**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-13T12:17:22Z
- **Completed:** 2026-06-13T12:37:00Z
- **Tasks:** 3 of 3
- **Files modified:** 10 created

## Accomplishments

- iOS 17 Xcode project builds clean: `xcodebuild BUILD SUCCEEDED` for iPhone 16 simulator with zero SPM packages and zero forbidden framework imports
- Money substrate locked in: `typealias Pence = Int`, `formatPence()` (integer arithmetic, 2dp guaranteed), `ParticipantSettlementState` (all 8 canonical states), no Double/Float/Decimal anywhere
- TEST MODE enforcement is structural: `MoneyLabel` is the sole `£` renderer, reads `ENABLE_REAL_MONEY_STAKES` at the render boundary — displaying money without the TEST marker is impossible by construction
- All 4 feature flags declared with locked values and honoured at their boundary (not just declared)
- `@Observable AppStore` injected at `WindowGroup` root via `.environment(appStore)` — no ObservableObject, no Combine, no MVVM boilerplate
- Walking Skeleton render slice proven end-to-end: `appStore.walletBalancePence` (2000 pence) → `MoneyLabel` → `£20.00` + `TEST MODE — NO REAL MONEY WILL MOVE` on the root screen

## Task Commits

1. **Task 1: Scaffold buildable iOS 17 Xcode project** — `89cabba` (chore)
2. **Task 2: Money type, formatter, feature flags, design tokens** — `a4df777` (feat)
3. **Task 3: MoneyLabel, AppStore wiring, root render** — `4b9db22` (feat)

## Files Created/Modified

- `LockedIN.xcodeproj/project.pbxproj` — iOS 17 target, Swift 5.0, PBXFileSystemSynchronizedRootGroup, objectVersion 77, no SPM
- `LockedIN.xcodeproj/xcshareddata/xcschemes/LockedIN.xcscheme` — xcodebuild scheme for iPhone 16 sim
- `LockedIN/Assets.xcassets/` — Contents.json, AppIcon.appiconset, AccentColor.colorset
- `LockedIN/Models/Money.swift` — Pence, MinorUnits, ParticipantSettlementState (8 states), formatPence()
- `LockedIN/Design/FeatureFlags.swift` — 4 locked flags with locked values
- `LockedIN/Design/Theme.swift` — warm dark-academia palette, rounded type scale, spacing/radius tokens
- `LockedIN/Design/MoneyLabel.swift` — ONLY sanctioned £ renderer; TEST marker structural guard; reads ENABLE_REAL_MONEY_STAKES
- `LockedIN/App/AppStore.swift` — @Observable root store; walletBalancePence = 2000; forfeitDestination = "British Red Cross"
- `LockedIN/App/LockedINApp.swift` — @main App; WindowGroup + .environment(appStore)
- `LockedIN/App/RootView.swift` — @Environment(AppStore.self); renders MoneyLabel for seeded balance and stake sample
- `.planning/phases/01-foundation/SKELETON.md` — 4 of 5 checkboxes ticked (MockCommitmentService is Plan 01-02)

## Decisions Made

- Used `PBXFileSystemSynchronizedRootGroup` (objectVersion 77, Xcode 16 feature) so all future `.swift` files dropped into `LockedIN/` are auto-included — no pbxproj surgery needed in any subsequent plan
- `formatPence()` implemented via integer division/modulo rather than `NumberFormatter` to guarantee exactly 2dp with zero floating-point involvement
- Assets.xcassets placed inside the synchronized `LockedIN/` group (no `PBXFileSystemSynchronizedBuildFileExceptionSet` or separate `PBXBuildFile` needed) — cleaner and avoids the root-path confusion that caused the first build failure
- AppStore initialised with only the D-09/D-10 seeds for now; SessionStore/WalletStore/RoomStore are child stores added in later phases

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed separate Assets.xcassets PBXBuildFile reference from initial pbxproj**

- **Found during:** Task 1 (first build attempt)
- **Issue:** Initial pbxproj had a `PBXBuildFile` + `PBXFileReference` pointing to `Assets.xcassets` at the project root (not inside `LockedIN/`), causing `actool` to error: "None of the input catalogs contained a matching AppIcon". The `PBXFileSystemSynchronizedBuildFileExceptionSet` approach also caused path confusion.
- **Fix:** Removed the separate `PBXBuildFile`, `PBXFileReference`, and `PBXFileSystemSynchronizedBuildFileExceptionSet` entries. The `PBXFileSystemSynchronizedRootGroup` covering `LockedIN/` picks up `Assets.xcassets` automatically, including it in the Resources build phase without an explicit reference.
- **Files modified:** `LockedIN.xcodeproj/project.pbxproj`
- **Verification:** BUILD SUCCEEDED on second attempt
- **Committed in:** 89cabba (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — build error from incorrect pbxproj asset path)
**Impact on plan:** Fix was necessary for the build to succeed. No scope creep. The final pbxproj structure is simpler than the original attempt.

## Issues Encountered

- First `xcodebuild` run failed with `actool` error about missing AppIcon — caused by an explicit `Assets.xcassets` file reference in the pbxproj pointing to the project root rather than the `LockedIN/` subfolder. Fixed by removing the redundant reference and trusting the synchronized root group (resolved in first fix attempt, BUILD SUCCEEDED immediately after).

## Threat Surface Scan

No new security-relevant surfaces introduced. This plan has no network endpoints, no auth paths, no file I/O, and no user data. The only trust boundary is the Pence → £ render boundary, which is fully mitigated by `MoneyLabel` + `ENABLE_REAL_MONEY_STAKES` enforcement as designed.

## Known Stubs

- `RootView` is a Walking Skeleton proof screen only — not a real user-facing screen. It will be replaced by the lobby/contract flow in Phase 2. This is intentional and documented in SKELETON.md.
- `AppStore` holds only `walletBalancePence` and `forfeitDestination`; `SessionStore`/`WalletStore`/`RoomStore` are added in later phases. The stub seeds are D-09/D-10 mandated values.

## Next Phase Readiness

- Phase 01-02 (MockCommitmentService, FocusControlAdapter, protocols) can proceed immediately — all substrate types it depends on (`Pence`, `ParticipantSettlementState`, `AppStore`) are in place
- Every subsequent phase can import `MoneyLabel` for money display without re-implementing the TEST guard
- The synchronized Xcode project will pick up new `.swift` files in any `LockedIN/` subfolder without pbxproj edits

---

## Self-Check: PASSED

Files verified present:
- `LockedIN.xcodeproj/project.pbxproj` — FOUND
- `LockedIN/Models/Money.swift` — FOUND
- `LockedIN/Design/FeatureFlags.swift` — FOUND
- `LockedIN/Design/Theme.swift` — FOUND
- `LockedIN/Design/MoneyLabel.swift` — FOUND
- `LockedIN/App/AppStore.swift` — FOUND
- `LockedIN/App/LockedINApp.swift` — FOUND
- `LockedIN/App/RootView.swift` — FOUND

Commits verified:
- `89cabba` chore(01-01): scaffold — FOUND
- `a4df777` feat(01-01): money type — FOUND
- `4b9db22` feat(01-01): MoneyLabel — FOUND

*Phase: 01-foundation*
*Completed: 2026-06-13*
