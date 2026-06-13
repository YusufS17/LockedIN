---
phase: 01-foundation
fixed_at: 2026-06-13T13:47:00Z
review_path: .planning/phases/01-foundation/01-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 10
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-06-13
**Source review:** `.planning/phases/01-foundation/01-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (2 BLOCKER + 6 WARNING + 3 INFO)
- Fixed: 10
- Skipped: 1 (IN-03 — doc/comment only, no code change warranted this phase)

---

## Fixed Issues

### CR-01 + CR-02: MockFocusControlAdapter concurrency

**Files modified:** `LockedIN/Services/MockFocusControlAdapter.swift`
**Commit:** `bf131b1`
**Applied fix:**
- Added `private let lock = NSLock()` to guard all `activeTasks` dictionary accesses.
- Introduced `setTask(_:for:)` and `cancelTask(for:)` helpers that acquire the lock before reading or mutating the dictionary, eliminating concurrent read/write undefined behaviour (CR-01).
- `startMonitoring` now calls `stopMonitoring` (via `cancelTask`) before creating any new Task, preventing orphaned tasks and ghost event emissions on re-entrant calls (CR-02).
- The Task is stored under lock before `onTermination` is registered, closing the storage-vs-termination ordering race that could leave an uncancellable leaked Task (CR-02).
- `stopMonitoring` delegates to `cancelTask` — lock-guarded and idempotent.

### WR-01: Two sources of truth for wallet balance

**Files modified:** `LockedIN/App/AppStore.swift`, `LockedIN/App/RootView.swift`
**Commit:** `8ed845e`
**Applied fix:**
- Removed `AppStore.walletBalancePence` stored property — it was an independent copy that diverged from `MockCommitmentService.balances` after `authoriseHold`/`settle`.
- Added `AppStore.currentBalance(for participantID: UUID) async -> Pence` which delegates to `commitmentService.walletBalance(participantID:)` — the single source of truth.
- `RootView` updated to use a local `@State private var displayBalancePence: Pence = MockCommitmentService.startingBalance` for the walking-skeleton display (no real participant UUID in Phase 1). Phase 2+ views use `currentBalance(for:)` in `.task {}`.
- Added `import Foundation` to AppStore.swift (needed for `UUID` in the new method signature).

### WR-02: `forfeitDestination` duplicated

**Files modified:** `LockedIN/App/AppStore.swift`, `LockedIN/Services/MockCommitmentService.swift`
**Commit:** `8ed845e`
**Applied fix:**
- Introduced `enum ForfeitConfig { static let destination = "British Red Cross" }` in `AppStore.swift` as a single constant.
- Both `AppStore.forfeitDestination` and `MockCommitmentService.forfeitDestination` now read from `ForfeitConfig.destination`. They cannot silently diverge.

### WR-03: `CommitmentContract` never enforces `stakeMinorUnits > 0`

**Files modified:** `LockedIN/Models/CommitmentContract.swift`
**Commit:** `c09a98c`
**Applied fix:**
- Replaced the compiler-synthesised memberwise `init` with a failable `init?` that guards: `stakeMinorUnits >= 0`, `durationSeconds > 0`, `maxBreaks >= 0`, `maxDistractionSeconds >= 0`. Returns `nil` on violation. Invalid contracts can no longer be constructed — the invariant is now structural.

### WR-04: `frozen()` can re-stamp `frozenAt`

**Files modified:** `LockedIN/Models/CommitmentContract.swift`
**Commit:** `c09a98c`
**Applied fix:**
- `frozen()` now starts with `guard frozenAt == nil else { return self }`. Calling it on an already-frozen contract is a no-op — the `frozenAt` timestamp is never overwritten. Idempotent.

### WR-05: `formatPence` interpolates into format string

**Files modified:** `LockedIN/Models/Money.swift`
**Commit:** `04d0fd5`
**Applied fix:**
- Split into two steps: `let amountString = String(format: "%d.%02d", pounds, pence)` (fixed specifiers only), then `return sign + symbol + amountString` via string concatenation. Dynamic values (sign, symbol) never enter the format string, eliminating the `%` injection vector.

### WR-06: `settle(.passed)` uses inconsistent `default: 0`

**Files modified:** `LockedIN/Services/MockCommitmentService.swift`
**Commit:** `8ed845e`
**Applied fix:**
- Changed `balances[holdRef.participantID, default: 0] += held` to `balances[holdRef.participantID, default: Self.startingBalance] += held`. Consistent with the defaults used in `authoriseHold` and `walletBalance`. An out-of-order edge call no longer silently loses the £20 seed.

### IN-01: TEST marker gating can silently remove safety qualifier

**Files modified:** `LockedIN/Design/MoneyLabel.swift`
**Commit:** `b45a319`
**Applied fix:**
- Both `fullLayout` and `compactLayout` now have an `else` branch: when `ENABLE_REAL_MONEY_STAKES` is `true`, a red "REAL MONEY — STAKES ACTIVE" badge (full) or "LIVE" pill (compact) is rendered instead of nothing. A £ figure is never shown without a visible qualifier regardless of the flag state.

### IN-02: `ENABLE_SPONSORED_REWARDS = true` for unbuilt flow

**Files modified:** `LockedIN/Design/FeatureFlags.swift`
**Commit:** `b45a319`
**Applied fix:**
- `ENABLE_SPONSORED_REWARDS` set to `false`. Comment updated to explain the default. Will be flipped to `true` when the sponsored reward flow is implemented.

---

## Skipped Issues

### IN-03: `Theme.forfeitRed` comment vs. spec colour mismatch

**File:** `LockedIN/Design/Theme.swift:25`
**Reason:** No code change required this phase. The finding notes a discrepancy between the artifacts doc description ("amber-red") and the actual hex `#ED4747` (pure red). The review itself says "Fix: None required this phase; reconcile the colour description with the actual hex when the reveal screen is built." Deferred to the reveal-screen phase per the reviewer's own guidance.
**Original issue:** The forfeit colour is named `forfeitRed` and is `#ED4747` (pure red), while the artifacts doc describes it as "forfeit/warning amber-red". Minor naming/spec drift with no current consumers.

---

## Build Verification

Final build after all fixes:

```
** BUILD SUCCEEDED **
```

Command: `xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -destination 'platform=iOS Simulator,name=iPhone 16' build`

---

## Commit Summary

| Commit | Finding(s) | Files |
|--------|-----------|-------|
| `bf131b1` | CR-01, CR-02 | `MockFocusControlAdapter.swift` |
| `8ed845e` | WR-01, WR-02, WR-06 | `AppStore.swift`, `MockCommitmentService.swift`, `RootView.swift` |
| `c09a98c` | WR-03, WR-04 | `CommitmentContract.swift` |
| `04d0fd5` | WR-05 | `Money.swift` |
| `b45a319` | IN-01, IN-02 | `MoneyLabel.swift`, `FeatureFlags.swift` |

---

_Fixed: 2026-06-13_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
