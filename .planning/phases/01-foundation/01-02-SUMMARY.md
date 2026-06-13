---
phase: 01-foundation
plan: 02
subsystem: models-services
tags: [swift, ios17, observable, money-types, settlement-state-machine, protocol-boundaries, mock-services]

requires:
  - "01-01: Pence/MinorUnits typealias, formatPence(), @Observable AppStore, FeatureFlags"

provides:
  - "ParticipantSettlementState — 8 canonical states as typed enum with associated values (held(ref:), returned(record:), forfeited(record:), settlementError(message:))"
  - "HoldReference, SettlementVerdict, SettlementRecord — settlement value types with money-conservation invariant"
  - "CommitmentContract frozen struct — isFrozen computed var, frozen() method, all money fields in MinorUnits"
  - "Participant value type — id, displayName, isBot"
  - "FocusEvent enum — 5 aggregate-only cases, participantID + Date only (SAFE-02)"
  - "CommitmentService protocol — payment/settlement boundary (FND-02)"
  - "MockCommitmentService — in-memory wallet seeded at 2000 pence, 'British Red Cross' forfeit destination, integer money conservation"
  - "FocusControlAdapter protocol — focus-tracking boundary (FND-03)"
  - "MockFocusControlAdapter — scripted AsyncStream<FocusEvent> emitter, cancellable via stopMonitoring"
  - "AppStore extended with protocol-typed commitmentService + focusAdapter properties (SAFE-04)"

affects:
  - "02-lobby-contract"
  - "03-session-engine"
  - "04-interruption-shield"
  - "05-results-settlement"

tech-stack:
  added:
    - "AsyncStream<FocusEvent> — Task.sleep-driven scripted event sequences for bot simulation"
    - "ScriptedFocusEvent struct — per-participant bot script injection point for Phase 3"
    - "CommitmentServiceError — typed error enum for authoriseHold/settle failures"
  patterns:
    - "Protocol-typed service properties in AppStore — all payment/focus access goes through the seam (SAFE-04, T-01-08)"
    - "Money conservation asserted in settle(): returnedMinorUnits + forfeitedMinorUnits == held, integer-only"
    - "MockFocusControlAdapter accepts scripts: [UUID: [ScriptedFocusEvent]] at init — Phase 3 injects detailed bot timelines"
    - "FocusEvent aggregate-only: participantID + Date, no app/URL/message fields by construction (SAFE-02)"

key-files:
  created:
    - "LockedIN/Models/ParticipantSettlementState.swift — 8-state enum, extracted from Money.swift, with associated values"
    - "LockedIN/Models/SettlementRecord.swift — HoldReference, SettlementVerdict, SettlementRecord"
    - "LockedIN/Models/CommitmentContract.swift — frozen struct with isFrozen/frozen()"
    - "LockedIN/Models/Participant.swift — Participant value type"
    - "LockedIN/Models/FocusEvent.swift — aggregate-only focus event enum (SAFE-02)"
    - "LockedIN/Services/CommitmentService.swift — CommitmentService protocol"
    - "LockedIN/Services/MockCommitmentService.swift — in-memory mock, 2000 pence seed, British Red Cross"
    - "LockedIN/Services/FocusControlAdapter.swift — FocusControlAdapter protocol"
    - "LockedIN/Services/MockFocusControlAdapter.swift — scripted AsyncStream emitter"
  modified:
    - "LockedIN/Models/Money.swift — ParticipantSettlementState block removed (moved to own file)"
    - "LockedIN/App/AppStore.swift — added protocol-typed commitmentService + focusAdapter with mock defaults"

decisions:
  - "ParticipantSettlementState moved to its own file (not duplicated) — Wave 1 had it in Money.swift; Wave 2 plan wanted it in ParticipantSettlementState.swift; resolved by moving and adding associated values"
  - "MockFocusControlAdapter accepts scripts at init (not hardcoded bot names) — Phase 3 injects the full Maya/Leo/Sam timelines; Wave 2 proves the seam only"
  - "MockCommitmentService uses per-access balance seeding (balances[participantID, default: 2000]) so any participant UUID seeds correctly without explicit registration"
  - "CommitmentServiceError typed enum added (Rule 2: missing error handling) — authoriseHold needs to signal insufficient balance and invalid amounts"

metrics:
  duration: 15min
  started: "2026-06-13T12:29:52Z"
  completed: "2026-06-13T13:34:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 9
  files_modified: 2
---

# Phase 1 Plan 02: Service Protocol Boundaries and Settlement State Machine Summary

**8-state settlement enum (typed, with associated values) + CommitmentService/FocusControlAdapter protocol seams with money-conserving 2000-pence mock wallet and scripted AsyncStream focus adapter, wired into AppStore as protocol-typed properties; BUILD SUCCEEDED**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-13T12:29:52Z
- **Completed:** 2026-06-13T13:34:00Z
- **Tasks:** 2 of 2
- **Files modified:** 9 created, 2 modified

## Accomplishments

- Settlement state machine fully typed: `ParticipantSettlementState` enum with exactly 8 canonical cases and associated values (`held(ref: HoldReference)`, `returned(record: SettlementRecord)`, `forfeited(record: SettlementRecord)`, `settlementError(message: String)`)
- Money conservation guaranteed by construction: `MockCommitmentService.settle()` uses integer-only arithmetic, asserts `returned + forfeited == held` for both verdicts, no Double/Float/Decimal anywhere
- Mock wallet seeds at 2000 pence (£20.00) per D-09; forfeit destination = "British Red Cross" per D-10
- Both protocol seams (`CommitmentService`, `FocusControlAdapter`) fully established — UI/session/shield phases reach payment and focus exclusively through these boundaries
- `MockFocusControlAdapter` emits `FocusEvent` via `AsyncStream` driven by `Task.sleep`, fully cancellable — Phase 3 injects bot scripts at init
- `FocusEvent` carries only `participantID + Date` by construction — app names, URLs, messages, notifications structurally impossible (SAFE-02, T-01-06)
- AppStore holds protocol-typed `let commitmentService: CommitmentService` and `let focusAdapter: FocusControlAdapter` — no concrete type leaks to UI (SAFE-04, T-01-08)
- xcodebuild BUILD SUCCEEDED on iPhone 16 simulator (iOS 17)

## Task Commits

1. **Task 1: Value-type model layer + 8-state settlement enum** — `328839c` (feat)
2. **Task 2: CommitmentService + FocusControlAdapter protocols, mocks, AppStore wiring** — `0db1c10` (feat)

## Files Created/Modified

- `LockedIN/Models/ParticipantSettlementState.swift` — 8-state enum with associated values (moved from Money.swift)
- `LockedIN/Models/SettlementRecord.swift` — HoldReference (Identifiable, Hashable), SettlementVerdict, SettlementRecord with conservation invariant documented
- `LockedIN/Models/CommitmentContract.swift` — frozen struct, isFrozen computed var, frozen() method; all money fields as MinorUnits
- `LockedIN/Models/Participant.swift` — Participant (id, displayName, isBot)
- `LockedIN/Models/FocusEvent.swift` — 5-case aggregate-only enum (SAFE-02)
- `LockedIN/Models/Money.swift` — ParticipantSettlementState block removed (moved to own file)
- `LockedIN/Services/CommitmentService.swift` — protocol with authoriseHold/settle/walletBalance
- `LockedIN/Services/MockCommitmentService.swift` — in-memory impl, 2000p seed, British Red Cross, typed errors
- `LockedIN/Services/FocusControlAdapter.swift` — protocol with startMonitoring/stopMonitoring
- `LockedIN/Services/MockFocusControlAdapter.swift` — scripted AsyncStream emitter (ScriptedFocusEvent), cancellable
- `LockedIN/App/AppStore.swift` — protocol-typed service properties, mock defaults

## Decisions Made

- Moved `ParticipantSettlementState` from `Money.swift` to its own file to match the plan's artifact map; added associated values for `held`, `returned`, `forfeited`, `settlementError` cases while keeping exactly 8 case names
- `MockFocusControlAdapter` accepts `scripts: [UUID: [ScriptedFocusEvent]]` at init rather than hardcoded bot names — keeps Phase 3 injection clean and Wave 2 focused on proving the seam, not scripting content
- `MockCommitmentService` seeds balance on first access using `[UUID: MinorUnits]` dictionary with default 2000 — any participant ID auto-seeds correctly without upfront registration
- Added `CommitmentServiceError` typed enum — Rule 2 (missing error handling): authoriseHold must be able to signal insufficient balance and invalid amounts for the settlement flow to be correct

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added CommitmentServiceError typed enum**
- **Found during:** Task 2
- **Issue:** `authoriseHold` throws but had no typed error to signal insufficient balance or invalid amounts — callers would receive untyped errors
- **Fix:** Added `CommitmentServiceError: Error, LocalizedError` enum with `invalidAmount`, `insufficientBalance`, and `holdNotFound` cases
- **Files modified:** `LockedIN/Services/MockCommitmentService.swift`
- **Commit:** `0db1c10`

**2. [Rule 1 - Bug] Removed duplicate ParticipantSettlementState from Money.swift**
- **Found during:** Task 1 (pre-build reconciliation)
- **Issue:** Wave 1 placed `ParticipantSettlementState` in `Money.swift`; plan 01-02 creates `ParticipantSettlementState.swift` — two declarations would cause a compile error
- **Fix:** Removed the enum block from `Money.swift` before creating the new standalone file
- **Files modified:** `LockedIN/Models/Money.swift`
- **Commit:** `328839c`

## Threat Surface Scan

No new network endpoints, auth paths, file I/O, or external data sources. All changes are in-memory only.

| Flag | File | Description |
|------|------|-------------|
| Reviewed: T-01-05 | MockCommitmentService.swift | Money conservation: integer-only, assert confirmed, returned+forfeited==held for both verdicts |
| Reviewed: T-01-06 | FocusEvent.swift | FocusEvent cases carry only participantID+Date — app/URL/message fields structurally absent |
| Reviewed: T-01-07 | ParticipantSettlementState.swift | Exactly 8 typed cases, no string-based state |
| Reviewed: T-01-08 | AppStore.swift | Protocol-typed service properties only — no concrete type referenced in UI path |
| Reviewed: T-01-09 | SettlementRecord.swift | SettlementRecord money is all MinorUnits; no coin fields mixed in |

No new threat surfaces identified.

## Known Stubs

- `MockFocusControlAdapter` with an empty `scripts: [:]` default emits no events — Phase 3 injects real bot scripts (Maya/Leo/Sam timelines). This is intentional; the seam is proven; scripts are Phase 3 content.
- `AppStore.walletBalancePence` is still a separate property from `MockCommitmentService`'s in-memory balances — Phase 2 will wire the displayed balance to the commitment service query. Current display shows the seed value from AppStore init directly.

## Next Phase Readiness

- Phase 01 is now complete — all 2 plans executed and BUILD SUCCEEDED
- Phase 02 (lobby/contract flow) can immediately use `CommitmentService.authoriseHold`, `CommitmentContract.frozen()`, `Participant`, and `ParticipantSettlementState` — all typed contracts are in place
- Phase 03 (session engine) can inject bot scripts into `MockFocusControlAdapter(scripts:)` and subscribe to `AsyncStream<FocusEvent>` — seam proven
- Phase 05 (results/settlement) can call `CommitmentService.settle(holdRef:verdict:)` and receive a money-conserving `SettlementRecord` — settlement state machine ready

---

## Self-Check: PASSED

Files verified present:
- `LockedIN/Models/ParticipantSettlementState.swift` — FOUND
- `LockedIN/Models/SettlementRecord.swift` — FOUND
- `LockedIN/Models/CommitmentContract.swift` — FOUND
- `LockedIN/Models/Participant.swift` — FOUND
- `LockedIN/Models/FocusEvent.swift` — FOUND
- `LockedIN/Services/CommitmentService.swift` — FOUND
- `LockedIN/Services/MockCommitmentService.swift` — FOUND
- `LockedIN/Services/FocusControlAdapter.swift` — FOUND
- `LockedIN/Services/MockFocusControlAdapter.swift` — FOUND

Commits verified:
- `328839c` feat(01-02): value-type model layer — FOUND
- `0db1c10` feat(01-02): CommitmentService protocols — FOUND

Build: xcodebuild BUILD SUCCEEDED (iPhone 16 simulator, iOS 17, Swift 5)

*Phase: 01-foundation*
*Completed: 2026-06-13*
