---
phase: 01-foundation
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - LockedIN/App/AppStore.swift
  - LockedIN/App/LockedINApp.swift
  - LockedIN/App/RootView.swift
  - LockedIN/Design/FeatureFlags.swift
  - LockedIN/Design/MoneyLabel.swift
  - LockedIN/Design/Theme.swift
  - LockedIN/Models/CommitmentContract.swift
  - LockedIN/Models/FocusEvent.swift
  - LockedIN/Models/Money.swift
  - LockedIN/Models/Participant.swift
  - LockedIN/Models/ParticipantSettlementState.swift
  - LockedIN/Models/SettlementRecord.swift
  - LockedIN/Services/CommitmentService.swift
  - LockedIN/Services/FocusControlAdapter.swift
  - LockedIN/Services/MockCommitmentService.swift
  - LockedIN/Services/MockFocusControlAdapter.swift
findings:
  critical: 2
  warning: 6
  info: 3
  total: 11
status: resolved
---

# Phase 1: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 1 lays the foundation substrate: money types, design tokens, the sanctioned `MoneyLabel` renderer, settlement state machine, service protocol boundaries, and two mock service implementations. The CLAUDE.md project rules are well respected on the surface — money is `Int` minor units throughout, `@Observable` is used (no `ObservableObject`/`@Published`), `FocusEvent` carries only `participantID + Date`, settlement states are explicit, and `MoneyLabel` is the single £ renderer with an always-on TEST marker.

However, the adversarial pass surfaced two genuine concurrency BLOCKERs in `MockFocusControlAdapter` (unsynchronised mutable state mutated from concurrent contexts, and task-storage races that break cancellation/cause leaks), plus several correctness and architectural WARNINGs: a duplicated wallet source-of-truth between `AppStore` and `MockCommitmentService`, unenforced contract invariants (`stake > 0`, single-freeze), a `formatPence` format-string interpolation issue, and a settlement re-credit that uses an inconsistent default. The TEST-marker safety mechanism also has a subtle gap worth flagging.

## Critical Issues

### CR-01: Data race on `activeTasks` in `MockFocusControlAdapter`

**File:** `LockedIN/Services/MockFocusControlAdapter.swift:38,81,84-87,93-96`
**Issue:** `activeTasks` is a plain `var [UUID: Task<Void, Never>]` on a non-isolated `final class`, but it is mutated from at least three concurrent contexts with no synchronisation:

1. The `AsyncStream` build closure (caller thread): `activeTasks[participantID] = task` (line 81).
2. `continuation.onTermination` (line 84-87) — this closure runs on an arbitrary executor/thread when the consumer cancels or the stream finishes; it both reads and removes from `activeTasks`.
3. `stopMonitoring` (line 93-96) — callable from any thread.

Concurrent reads/writes to a Swift `Dictionary` are undefined behaviour: this can corrupt the dictionary's internal buffer or crash with a heap fault. Even though CLAUDE.md pins Swift 5 language mode (so the compiler will not flag this), the race is real at runtime. With multiple bot participants each calling `startMonitoring`/`stopMonitoring`, this is a plausible crash in the demo path.

**Fix:** Isolate the mutable state. The cleanest option for this codebase is to make the adapter an `actor`, or guard `activeTasks` with a serial queue / `NSLock`. Actor example:
```swift
actor MockFocusControlAdapter: FocusControlAdapter {
    private let scripts: [UUID: [ScriptedFocusEvent]]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    // ... startMonitoring/stopMonitoring become actor-isolated;
    // protocol methods may need `nonisolated` wrappers or protocol update.
}
```
If keeping a class, wrap every `activeTasks` access in a lock:
```swift
private let lock = NSLock()
private func setTask(_ task: Task<Void, Never>?, for id: UUID) {
    lock.lock(); defer { lock.unlock() }
    if let task { activeTasks[id] = task } else { activeTasks.removeValue(forKey: id) }
}
```

### CR-02: Task-storage / termination ordering race loses cancellation and leaks tasks

**File:** `LockedIN/Services/MockFocusControlAdapter.swift:54-91`
**Issue:** Two ordering hazards in `startMonitoring`:

1. **Storage vs. termination race.** The `Task { ... }` (line 55) may begin and even finish/cancel before `activeTasks[participantID] = task` executes (line 81). If `continuation.onTermination` fires (e.g. the consumer never iterates and the stream is deallocated) before line 81 runs, the `onTermination` handler removes nothing, and then line 81 stores a task that nothing will ever cancel — a leaked, running `Task` that keeps sleeping and yielding into a finished continuation.
2. **Re-entrant overwrite.** Calling `startMonitoring(participantID:)` twice for the same participant (or after a prior session for that UUID) overwrites `activeTasks[participantID]` (line 81), orphaning the previous task. The first task is never cancelled and continues running until its script completes — a goroutine-style leak and a source of duplicate/ghost `FocusEvent` emissions for that participant.

**Fix:** Cancel any pre-existing task before storing, and store the task synchronously before the `Task` body can run by creating the `Task` after registration, or by guarding inside the lock/actor from CR-01. Example:
```swift
func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent> {
    stopMonitoring(participantID: participantID) // cancel any prior task first
    let script = scripts[participantID] ?? []
    return AsyncStream { continuation in
        let task = Task { /* ... existing loop ... */ }
        setTask(task, for: participantID)        // lock/actor-guarded (CR-01)
        continuation.onTermination = { [weak self] _ in
            self?.cancelTask(for: participantID)  // lock/actor-guarded, idempotent
        }
    }
}
```
Combined with CR-01's isolation, this closes both the leak and the lost-cancellation window.

## Warnings

### WR-01: Two sources of truth for the wallet balance

**File:** `LockedIN/App/AppStore.swift:18` and `LockedIN/Services/MockCommitmentService.swift:21,29,46,117`
**Issue:** `AppStore.walletBalancePence = 2000` holds a wallet balance, and `MockCommitmentService` independently seeds and mutates per-participant balances at 2000 pence. These are separate state stores. A `settle(.passed)` or `authoriseHold` updates `MockCommitmentService.balances` but never `AppStore.walletBalancePence`, so the UI (which reads `appStore.walletBalancePence` in `RootView.swift:73`) will display a stale balance once real settlement flows are wired in Phase 2+. CLAUDE.md requires payment logic separated from UI with a clean service boundary — the duplicated field undermines that boundary by re-introducing balance state into the UI store.
**Fix:** Make `AppStore` derive the displayed balance from the service rather than storing its own copy, or document `walletBalancePence` as a Phase-1 display stub that must be removed when the wallet is wired. Preferred:
```swift
// Drop the stored property; surface balance via the service:
func currentBalance(for participantID: UUID) async -> Pence {
    await commitmentService.walletBalance(participantID: participantID)
}
```

### WR-02: `forfeitDestination` duplicated and can diverge

**File:** `LockedIN/App/AppStore.swift:23` and `LockedIN/Services/MockCommitmentService.swift:24`
**Issue:** The string `"British Red Cross"` is hardcoded in two places (D-10). If one is edited, the other silently disagrees — the UI could name a different charity than the one settlement attributes the forfeit to.
**Fix:** Define once and reference from both, e.g. a single constant:
```swift
enum ForfeitConfig { static let destination = "British Red Cross" }
```
and have both `AppStore` and `MockCommitmentService` read `ForfeitConfig.destination`.

### WR-03: `CommitmentContract` never enforces `stakeMinorUnits > 0`

**File:** `LockedIN/Models/CommitmentContract.swift:24-25`
**Issue:** The doc comment states "Must be > 0 for staked contracts," but the struct uses the compiler-synthesised memberwise init with no validation. A contract can be constructed with `stakeMinorUnits = 0` or negative. `durationSeconds`, `maxDistractionSeconds`, and `maxBreaks` are likewise unvalidated (negative durations/breaks are nonsensical). The invariant is only enforced later in `MockCommitmentService.authoriseHold` (line 48), which is too late and only catches stake, not duration/breaks.
**Fix:** Add a failable or throwing init that validates invariants at construction, or a `validate()` guard used by the builder before `frozen()`:
```swift
init?(id: UUID, roomName: String, durationSeconds: Int, stakeMinorUnits: MinorUnits, ...) {
    guard stakeMinorUnits >= 0, durationSeconds > 0, maxBreaks >= 0,
          maxDistractionSeconds >= 0 else { return nil }
    // assign...
}
```

### WR-04: `frozen()` can be called repeatedly, re-stamping `frozenAt`

**File:** `LockedIN/Models/CommitmentContract.swift:56-60`
**Issue:** The comment promises the frozen copy "cannot be mutated further," but `frozen()` itself is callable on an already-frozen contract and overwrites `frozenAt` with a new `Date()`. Nothing enforces single-freeze. A double-freeze silently moves the freeze timestamp, which downstream session logic may treat as the contract start — a subtle correctness bug for any timing derived from `frozenAt`.
**Fix:** Make `frozen()` idempotent / guard against re-freezing:
```swift
func frozen() -> CommitmentContract {
    guard frozenAt == nil else { return self } // already frozen: no-op
    var copy = self
    copy.frozenAt = Date()
    return copy
}
```

### WR-05: `formatPence` interpolates user/dev-supplied values into a format string

**File:** `LockedIN/Models/Money.swift:37,40`
**Issue:** Line 40 builds the format string via interpolation: `String(format: "\(sign)\(symbol)%d.%02d", ...)`. For unknown currency codes, `symbol = currencyCode + " "` (line 37) places the raw `currencyCode` directly inside the format string. If a `currencyCode` ever contains a `%` (e.g. a malformed/attacker-influenced ISO code), `String(format:)` will interpret it as a conversion specifier, producing garbage output or reading uninitialised varargs — a classic format-string defect. Currency code is developer-controlled today, so severity is limited, but the pattern is fragile and the function is the single money display boundary, so it must be robust.
**Fix:** Keep the dynamic parts out of the format string:
```swift
let amountString = String(format: "%d.%02d", pounds, pence)
return sign + symbol + amountString
```

### WR-06: `settle(.passed)` re-credits with `default: 0`, inconsistent with seeding semantics

**File:** `LockedIN/Services/MockCommitmentService.swift:92`
**Issue:** On a passed verdict, the stake is returned via `balances[holdRef.participantID, default: 0] += held`. Everywhere else the balance default is `Self.startingBalance` (lines 46, 117). In the normal flow `authoriseHold` has already seeded the entry, so `default: 0` is reached only in an out-of-order/edge call (`settle` without a prior `authoriseHold` having seeded, or after the entry was cleared). In that edge case the participant ends up with only the returned stake and silently loses their £20 seed — an inconsistent, hard-to-debug money state. The two different defaults for the same dictionary are a latent correctness hazard.
**Fix:** Use the same seeding default and add an explicit guard for the unexpected path:
```swift
balances[holdRef.participantID, default: Self.startingBalance] += held
```
(or assert the participant balance exists before crediting).

## Info

### IN-01: TEST marker gating depends on a flag whose flip silently removes the only safety marker

**File:** `LockedIN/Design/MoneyLabel.swift:45-47,60-62`
**Issue:** The TEST marker is rendered only `if !FeatureFlags.ENABLE_REAL_MONEY_STAKES`. The inline comment correctly notes that flipping the flag true suppresses the marker — but that means the project's "money-without-marker is structurally impossible" guarantee is actually one boolean away from being false, with no compile-time or test enforcement. For a safety/ethics-critical invariant (CLAUDE.md SAFE-02), consider asserting at startup that real-money mode is disabled for the prototype build, or rendering a distinct real-money badge rather than nothing.
**Fix:** Add a guard so the absence of a marker is never silent, e.g. render an explicit real-money indicator in the `else` branch, or `assert(!FeatureFlags.ENABLE_REAL_MONEY_STAKES)` in a prototype build.

### IN-02: `ENABLE_SPONSORED_REWARDS = true` for a flow that does not exist

**File:** `LockedIN/Design/FeatureFlags.swift:21`
**Issue:** The flag defaults to `true` while its own comment says "flow not yet built." A flag that reads true but gates nothing is a footgun: the first code that reads it will believe the feature is live. Prefer defaulting unbuilt features to `false`.
**Fix:** Set `ENABLE_SPONSORED_REWARDS = false` until the flow exists, or document explicitly why it is true.

### IN-03: `Theme.forfeitRed` semantics vs. comment mismatch / unused token risk

**File:** `LockedIN/Design/Theme.swift:25` and `01-ARTIFACTS.md:34`
**Issue:** The artifacts doc describes the forfeit colour as "forfeit/warning amber-red," but `forfeitRed` is a pure red `#ED4747`. Minor naming/spec drift; harmless now but worth aligning so later phases pick the intended hue. Also several `Theme` tokens (`surface`, `accentSoft`, `textOnAccent`, `Radius.pill`, `TypeScale.largeTitle/title2`) are declared but not yet consumed by any reviewed file — acceptable for a foundation phase, just noting they are currently unexercised.
**Fix:** None required this phase; reconcile the colour description with the actual hex when the reveal screen is built.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
