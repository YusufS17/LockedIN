---
status: passed
phase: 01-foundation
verified: "2026-06-13"
method: inline (verifier disabled in config; no test suite yet)
build: "xcodebuild BUILD SUCCEEDED — iPhone 16 simulator, iOS 17, Swift 5"
must_haves_verified: 5
must_haves_total: 5
requirements: FND-01, FND-02, FND-03, FND-04, FND-05, SAFE-01, SAFE-02, SAFE-03, SAFE-04
---

# Phase 1: Foundation — Verification

**Goal:** The safe, money-correct substrate every other phase builds on exists — integer pence type, settlement state machine, service protocols with mock implementations, and the TEST MODE design system.

**Verdict:** PASSED. All 5 success criteria verified against the live codebase; `xcodebuild` BUILD SUCCEEDED.

## Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `Pence`/`MinorUnits` typealias; no `Double`/`Float` for money anywhere | ✓ | `Money.swift:8,11` (`= Int`); only Double/Float occurrence is a comment forbidding them (`CommitmentService.swift:13`) |
| 2 | `CommitmentService` + `FocusControlAdapter` protocols with mock impls; UI/session contain zero direct payment calls | ✓ | Protocols + `MockCommitmentService`/`MockFocusControlAdapter` in `Services/`; only concrete-mock reference is protocol-typed DI default args at `AppStore.swift:44-45` (composition root); `App/` and `Design/` make no direct service calls |
| 3 | `ParticipantSettlementState` covers all 8 named states | ✓ | `ParticipantSettlementState.swift` — notRequired, awaitingAuthorisation, held, authorisedForReturn, authorisedForForfeit, returned, forfeited, settlementError |
| 4 | Feature flags exist and honoured (`ENABLE_REAL_MONEY_STAKES=false`, `ENABLE_TEST_STAKES=true`, `ENABLE_ROOM_PRIZE_POOL=false`, `ENABLE_SPONSORED_REWARDS=true`) | ✓ | `FeatureFlags.swift:11,14,18,21` — all four present with required values |
| 5 | `MoneyLabel` renders persistent "TEST MODE — NO REAL MONEY WILL MOVE" alongside any `£` amount; no money screen omits it | ✓ | `MoneyLabel.swift:39,85` — marker always rendered; `ENABLE_REAL_MONEY_STAKES` read at the render boundary so money-without-marker is structurally impossible |

## Requirement Traceability

- **FND-01** (Int pence money) — Money.swift ✓
- **FND-02/03/04** (settlement state machine, service protocols, mocks) — Models/ + Services/ ✓
- **FND-05** (locked feature flags) — FeatureFlags.swift ✓
- **SAFE-01/03/04** (TEST MODE enforcement, no real money, payment/UI separation) — MoneyLabel.swift + protocol seam ✓
- **SAFE-02** (aggregate-only focus data, no app names/private data) — FocusEvent.swift / MockFocusControlAdapter.swift ✓

## Notes / Carry-Forward

Code review (`01-REVIEW.md`) found **2 BLOCKER** concurrency defects in `MockFocusControlAdapter` (unsynchronised `activeTasks` dictionary mutation — undefined behaviour; task-storage ordering races causing leaks/ghost events). These do **not** violate any Phase 1 success criterion, but Phase 2's bot scripting builds directly on the focus adapter — recommend fixing via `/gsd-code-review 01 --fix` before starting Phase 2. Also WR-01: `AppStore.walletBalancePence` duplicates `MockCommitmentService.balances` (stale-balance risk) — relevant once settlement UI lands.
