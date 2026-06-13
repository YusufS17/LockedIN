# Roadmap: LockedIN

## Overview

Six phases deliver the section-13 demo spine first, then layer the world/social system on top. Phases 1–5 build a fully demoable commitment loop — preset room creation, frozen contract acceptance, a live session with scripted bots, an Opal-style interruption shield, and a competitive results reveal with real wallet settlement. Phase 6 adds the ambitious back half: idle coin rewards, a personal world that grows from focused study, and locally-persisted neighbour worlds for Minecraft-esque comparison. If time runs short, cut Phase 6 — Phases 1–5 always produce a working, submittable demo.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Core data types, service protocols, mock implementations, and the TEST MODE design system
- [ ] **Phase 2: Room & Contract** - Lobby UI, preset room creation, contract review, per-participant acceptance, and contract freeze
- [ ] **Phase 3: Session Engine & Tracking** - SessionCoordinator, scripted bots, countdown timer, metrics accumulation, and deterministic pass/fail rules
- [ ] **Phase 4: Screen Shield & Interruption** - Full-screen Opal-style block overlay, hold-to-confirm forfeit gate, and honest emergency exit
- [ ] **Phase 5: Results & Settlement** - Wallet settlement state machine, sequenced competitive reveal, and room totals
- [ ] **Phase 6: Rewards, Coins & World** - Idle coin earning, personal world growth, shared world contribution, neighbour browsing, and local persistence

## Phase Details

### Phase 1: Foundation
**Goal**: The safe, money-correct substrate every other phase builds on exists: integer pence type, settlement state machine, service protocols with mock implementations, and the TEST MODE design system
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: FND-01, FND-02, FND-03, FND-04, FND-05, SAFE-01, SAFE-02, SAFE-03, SAFE-04
**Success Criteria** (what must be TRUE):
  1. A `Pence`/`MinorUnits` typealias exists and all money-holding model fields use it — no `Double` or `Float` for monetary values anywhere in the codebase
  2. `CommitmentService` and `FocusControlAdapter` protocols exist with `MockCommitmentService` and `MockFocusControlAdapter` implementations; session and UI code contain zero direct payment calls
  3. `ParticipantSettlementState` enum covers all named states (notRequired, awaitingAuthorisation, held, authorisedForReturn, authorisedForForfeit, returned, forfeited, settlementError)
  4. All five feature flags exist and are honoured (`ENABLE_REAL_MONEY_STAKES=false`, `ENABLE_TEST_STAKES=true`, `ENABLE_ROOM_PRIZE_POOL=false`, `ENABLE_SPONSORED_REWARDS=true`)
  5. A `TestModeBadge` / `MoneyLabel` component renders a persistent "TEST MODE — NO REAL MONEY WILL MOVE" label alongside any formatted `£` amount, and no money-displaying screen in the app omits it
**Plans**: 2 plans
Plans:
- [ ] 01-01-PLAN.md — Walking Skeleton: buildable iOS 17 app, Pence type + single 2dp formatter, MoneyLabel (structural TEST marker), 4 feature flags, design tokens, @Observable AppStore via .environment()
- [ ] 01-02-PLAN.md — 8-state ParticipantSettlementState enum, CommitmentService/FocusControlAdapter protocols + money-conserving mocks (wallet seed £20.00 / "British Red Cross"), wired into AppStore

### Phase 2: Room & Contract
**Goal**: A user can launch a preset £5 room, review the full contract with explicit pass/fail terms, accept and stake £5, watch three scripted bots do the same, and see the contract lock visibly with £20 at stake before the session starts
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: CTR-01, CTR-02, CTR-03, CTR-04, CTR-05, CTR-06, STK-01, STK-04, STK-05
**Success Criteria** (what must be TRUE):
  1. Tapping "£5 Serious Lock-In" launches a room without any configuration form — a single tap leads directly to the contract review screen
  2. The contract screen shows all explicit pass/fail conditions: duration, break allowance, permitted distraction events, leaving-early rule, stake amount, and forfeit destination
  3. After the user accepts, three bots (Maya, Leo, Sam) are shown joining and accepting in sequence; the room header reads "£20 collectively at stake (£5 each)"
  4. The contract becomes visibly frozen (lock icon displayed, all fields disabled) once the last participant accepts — attempting to modify it after this point has no effect
  5. An 18+ adult-confirmation gate blocks entry to the cash-stake room; the stake is shown as authorised/held in the simulated wallet alongside the "TEST MODE" label and the chosen forfeit destination
**Plans**: TBD
**UI hint**: yes

### Phase 3: Session Engine & Tracking
**Goal**: A live session runs: the countdown ticks, scripted bot events fire on a deterministic timeline, per-participant focus metrics accumulate, and pass/fail is decided by pure contract rules with no randomness
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: SES-01, SES-02, SES-03, SES-04, SES-05
**Success Criteria** (what must be TRUE):
  1. The session shows a countdown timer that runs for the contracted duration (short offsets in demo mode) and reaches zero without crashing
  2. The `MockFocusControlAdapter` fires scripted distraction, break, and leave events for Maya, Leo, and Sam at their hardcoded offsets — the same events fire in the same order every run
  3. Per-participant metrics (focused seconds, break seconds, distraction count, override count, left early, focus percentage) are accumulated correctly and reflect each bot's scripted behaviour at session end
  4. Sam's metrics deterministically cross the distraction threshold and `ContractRules.evaluate` returns `.failed` for Sam; Maya and Leo return `.passed` — no randomness in the outcome
  5. The live room displays only aggregate signals ("3 still perfectly LockedIN", "2 distraction events recorded") with no per-name attribution mid-session
**Plans**: TBD

### Phase 4: Screen Shield & Interruption
**Goal**: When a blocked app is "opened" during a session, a full-screen LockedIN overlay fires and gives the participant honest, pressure-appropriate choices — and a clearly labelled forfeit exit is always reachable
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: SHD-01, SHD-02, SHD-03, SHD-04, SHD-05
**Success Criteria** (what must be TRUE):
  1. A scripted distraction event from the Mock adapter triggers a full-screen block overlay (simulated Opal-style shield) that covers the session entirely and cannot be swiped away
  2. The overlay states the current stake, time remaining, and distraction tally (e.g. "You have used 1 of your 2 permitted distraction events")
  3. The overlay offers three clearly labelled honest choices: Return to the room / Use planned break / Continue and record distraction
  4. When Sam's distraction count crosses the contract threshold, a hold-to-confirm warning screen appears that explicitly states continuing will forfeit the £5 stake; the action requires a deliberate hold gesture to confirm
  5. An "End session early (forfeit £5)" exit is always visible and clearly labelled on both the interruption and warning screens — no hidden or deceptive paths
**Plans**: TBD
**UI hint**: yes

### Phase 5: Results & Settlement
**Goal**: When the session ends, each participant's stake settles through the explicit state machine, and a sequenced reveal shows room totals then individual competitive titles with the numbers behind them
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: STK-02, STK-03, RES-01, RES-02, RES-03, RES-04
**Success Criteria** (what must be TRUE):
  1. Passing participants (Maya, Leo, the user) each have their £5 stake returned; Sam's £5 stake is forfeited — settlement record shows £15 returned / £5 forfeited with isTestMode=true and the TEST MODE label on every figure
  2. The results screen first reveals room totals: focused minutes, total stake protected, total stake forfeited, successful participant count, and room focus percentage
  3. Individual titles are then revealed in sequence — LockedIN Champion, Biggest Culprit (Sam), First to Fold — each accompanied by the specific stats that earned the title (distraction count, focus percentage, override attempts, stake outcome)
  4. Supportive room mode suppresses negative ranking titles ("Biggest Culprit") when that setting is enabled, honouring the contract's visibility configuration
**Plans**: TBD
**UI hint**: yes

### Phase 6: Rewards, Coins & World
**Goal**: Focused participants visibly earn LockedIN coins during the session, those coins build a personal world that grows and persists, users can see neighbours' pre-seeded worlds, and the coin economy stays visually and conceptually distinct from commitment £ at all times
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: RWD-01, RWD-02, RWD-03, RWD-04, WLD-01, WLD-02, WLD-03, WLD-04, WLD-05, WLD-06
**Success Criteria** (what must be TRUE):
  1. During an active session, focused participants show a visible "working" animation and their coin/treasure balance increments on a timer; coin earning pauses immediately when a participant is distracted or has cracked
  2. The results screen tallies coins earned in a section clearly separated from the stake settlement — the two economies are never shown in the same UI element or formatted with the same currency symbol
  3. A user's personal world/room visibly reflects their accumulated coins — more coins means more visible world growth — and solo study also builds the personal world
  4. A shared world view shows aggregated contributions from all session participants; neighbours' pre-seeded worlds are browsable for comparison
  5. World progress and coin balance persist across app relaunches on the demo device (SwiftData or UserDefaults) — relaunching the app after a session shows the same world state as before quitting
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/2 | Planned | - |
| 2. Room & Contract | 0/TBD | Not started | - |
| 3. Session Engine & Tracking | 0/TBD | Not started | - |
| 4. Screen Shield & Interruption | 0/TBD | Not started | - |
| 5. Results & Settlement | 0/TBD | Not started | - |
| 6. Rewards, Coins & World | 0/TBD | Not started | - |
