# Requirements: LockedIN

**Defined:** 2026-06-13
**Core Value:** The commitment-to-consequence loop must *feel real* — a frozen contract with a genuine-feeling stake, honest pressure when you try to break it, and a satisfying reveal that returns or forfeits the money.

## v1 Requirements

Requirements for the hackathon prototype. Each maps to a roadmap phase. Scope is the section-13 demo spine plus the simulated app-shield and idle focus-reward mechanics.

### Foundation & Architecture

- [x] **FND-01**: All monetary values are stored as integer minor units (pence); never floating point
- [x] **FND-02**: Payment/settlement logic lives behind a `CommitmentService` protocol (with a `MockCommitmentService` implementation); no payment calls appear in UI or session code
- [x] **FND-03**: Focus tracking goes through a `FocusControlAdapter` protocol (with a `MockFocusControlAdapter` implementation) so a real Screen Time adapter can slot in later
- [x] **FND-04**: Settlement has explicit, enumerated states (e.g. not_required, awaiting_authorisation, authorised, held, passed, refunded, failed, forfeited) modelled as a type
- [x] **FND-05**: Feature flags exist and are honoured: `ENABLE_REAL_MONEY_STAKES=false`, `ENABLE_TEST_STAKES=true`, `ENABLE_ROOM_PRIZE_POOL=false`, `ENABLE_SPONSORED_REWARDS=true`

### Onboarding & Character

- [ ] **ONB-01**: First launch shows a polished, skippable onboarding sequence that introduces the LockedIN commitment concept with smooth animation (not static text screens)
- [ ] **ONB-02**: User creates/customises a pixel-art character from preset options (e.g. body, hair, outfit, colour variants) with a live preview that updates as choices change
- [ ] **ONB-03**: A reusable avatar-rendering component represents a participant and is structured to support later session states (idle now; focused / deep-focus / break / distracted / finished), using non-colour-only status cues for accessibility
- [ ] **ONB-04**: The chosen avatar is the user's representation across the app (home, room roster, session room) and persists across app relaunch on the device
- [ ] **ONB-05**: A reusable cozy isometric study-room view is established (warm dark-academia pixel-art per the mockup) so rooms look polished from this phase onward; onboarding ends with the user's avatar shown in their room

### Room & Contract

- [ ] **CTR-01**: User can start a "£5 Serious Lock-In" room from a preset without filling out a custom-configuration form
- [ ] **CTR-02**: The contract screen shows explicit pass/fail conditions (duration, break allowance, permitted distractions, leaving-early rule, stake amount, forfeit destination)
- [ ] **CTR-03**: Each participant separately accepts the contract via an "Accept and stake £5" action
- [ ] **CTR-04**: The contract becomes immutable (frozen) once accepted — host cannot raise the stake, reduce breaks, change the failure threshold, or change the forfeit destination
- [ ] **CTR-05**: The frozen state is visibly indicated (lock icon, disabled fields)
- [ ] **CTR-06**: Three scripted bot participants (Maya, Leo, Sam) join and accept the contract; the room shows "£20 collectively at stake (£5 each)"

### Stakes & Wallet

- [ ] **STK-01**: The simulated wallet shows each participant's stake as authorised/held during the session
- [ ] **STK-02**: On pass, a participant's stake is returned to their wallet (demo: £15 returned across the passers)
- [ ] **STK-03**: On fail, a participant's stake is forfeited according to the contract (demo: £5 forfeited)
- [ ] **STK-04**: The forfeit destination (e.g. selected charity placeholder) is shown to participants before and after
- [ ] **STK-05**: Underage accounts cannot enter cash-stake rooms — an 18+ adult-confirmation gate guards entry

### Session & Tracking

- [ ] **SES-01**: The session runs a countdown timer for the contracted duration (accelerated for the demo)
- [ ] **SES-02**: The `MockFocusControlAdapter` emits scripted distraction / break / override / leave events on a deterministic timeline
- [ ] **SES-03**: Aggregate per-participant metrics are tracked (focused seconds, break seconds, distraction count, override count, left early, focus percentage)
- [ ] **SES-04**: Pass/fail is decided by deterministic `ContractRules` from metrics + contract — no randomness or chance
- [ ] **SES-05**: The live room displays only aggregate signals (e.g. "3 still perfectly LockedIN", "2 distraction events recorded"); default visibility is private-until-results with no per-name attribution mid-session

### Screen Shield & Interruption

- [ ] **SHD-01**: "Opening" a blocked social/games app during a session triggers a full-screen LockedIN shield/block overlay (simulated Opal-style blocking, driven by the Mock adapter)
- [ ] **SHD-02**: The interruption screen states the stake, time remaining, and distraction events used (e.g. "You have used 1 of your 2 permitted distraction events")
- [ ] **SHD-03**: The interruption screen offers honest choices: Return to the room / Use planned break / Continue and record distraction
- [ ] **SHD-04**: Crossing the failure threshold shows an explicit warning that continuing forfeits the stake, gated by a hold-to-confirm (or second confirmation) interaction
- [ ] **SHD-05**: An honest emergency exit is always available and clearly states whether leaving fails the commitment; no deceptive buttons

### Rewards & Coins

- [ ] **RWD-01**: Focused participants visibly "work" and accrue LockedIN coins/treasure on a timer while locked in
- [ ] **RWD-02**: Coin earning pauses while a participant is distracted or has cracked (earned by focused time only)
- [ ] **RWD-03**: LockedIN coins are a separate economy from commitment £ — non-withdrawable, non-transferable, never converted into stake money
- [ ] **RWD-04**: The results screen tallies coins/treasure earned separately from the stake settlement

### World & Social

- [ ] **WLD-01**: Each user has a personal world/room that visibly grows as they earn coins/treasure from focused study (focus → reward → visible world growth)
- [ ] **WLD-02**: A user can study solo (solo room) and build their own world
- [ ] **WLD-03**: A user can join a group/shared world and contribute to it alongside the session's participants (demo: shared world aggregated locally from the room's participants)
- [ ] **WLD-04**: World and coin/treasure progress persists locally across app relaunches on the device (SwiftData/UserDefaults)
- [ ] **WLD-05**: A user can view other participants' worlds — the bots'/neighbours' pre-seeded worlds — for Minecraft-esque comparison and competition
- [ ] **WLD-06**: Coins/treasure earned (see Rewards & Coins) are the currency that builds the world, never convertible to commitment £

### Results & Reveal

- [ ] **RES-01**: Results first show room totals (focused minutes, stake protected, stake forfeited, successful participants, room focus percentage)
- [ ] **RES-02**: Results then reveal individual titles (LockedIN Champion, Biggest Culprit, First to Fold)
- [ ] **RES-03**: Each title shows the numbers behind it (distraction events, override attempts, focus percentage, stake outcome)
- [ ] **RES-04**: Supportive rooms can disable negative rankings; the reveal honours that setting

### Safety & Integrity

- [x] **SAFE-01**: A persistent "TEST MODE — NO REAL MONEY WILL MOVE" label appears on every screen that shows a £ amount
- [x] **SAFE-02**: The app never exposes which specific apps were blocked/opened, browsing history, messages, contacts, or notification contents — only aggregate metrics
- [x] **SAFE-03**: Tracking is labelled best-effort; no invented data is presented as real measurement
- [x] **SAFE-04**: Commitment £ and LockedIN coins are never conflated on screen

## v2 Requirements

Deferred to future releases. Tracked but not in the current roadmap.

### Real Enforcement & Tracking

- **REAL-01**: Real OS-level app blocking via FamilyControls / ManagedSettings (requires Family Controls entitlement + device)
- **REAL-02**: Real Screen Time / DeviceActivity-based focus measurement with documented capability limits

### Real Money

- **PAY-01**: Stripe test-mode authorise/hold/release wired through a `StripeCommitmentService`
- **PAY-02**: Real-money settlement behind `ENABLE_REAL_MONEY_STAKES` with full payment + legal architecture

### Multiplayer

- **MP-01**: Real-time cross-device room sync (multiple phones in one live room)

### Worlds (networked)

- **WLDN-01**: Real cross-device shared/joint world sync — build a world with remote friends whose progress syncs
- **WLDN-02**: Discover and browse other real users' worlds globally (requires accounts + backend)

### Stake Types & Economy

- **STAKE-01**: Accountability-partner forfeit payouts (deliberate selection + verification)
- **STAKE-02**: Room prize pool (`ENABLE_ROOM_PRIZE_POOL`, adult-only, jurisdiction-specific legal review, no chance-based outcome)
- **STAKE-03**: Sponsor-funded challenges (`ENABLE_SPONSORED_REWARDS` flow)
- **COIN-01**: LockedIN coin shop — spend coins on avatar and room cosmetics

### Configuration & Visibility

- **CFG-01**: Full custom-contract create-room UI (host configures all settings)
- **CFG-02**: Live-accountability visibility mode (per-name attribution during session, with explicit opt-in)

## Out of Scope

Explicitly excluded — anti-features and hard ethical lines. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Childish punishments (random calls/messages, secret social posts, avatar shame) | Spec amendment explicitly overrides these; mechanism is meaningful commitment, not gimmicks |
| Random / chance-based financial outcomes | Legally gambling; undermines deterministic commitment logic |
| Real money movement without payment + legal architecture | Regulatory, safeguarding, and KYC requirements not met in a prototype |
| Exposing private app/usage data (app names, browsing, messages, contacts, notifications) | Privacy violation; spec forbids; only aggregate metrics allowed |
| Deceptive interruption buttons / hidden contract terms | Dark patterns; spec requires honest UX and an honest emergency exit |
| Conflating commitment £ with cosmetic coins | Two separate economies; mixing them muddies the product and harms credibility |

## Traceability

Populated during roadmap creation by the roadmapper. Each requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 1 | Complete |
| FND-02 | Phase 1 | Complete |
| FND-03 | Phase 1 | Complete |
| FND-04 | Phase 1 | Complete |
| FND-05 | Phase 1 | Complete |
| SAFE-01 | Phase 1 | Complete |
| SAFE-02 | Phase 1 | Complete |
| SAFE-03 | Phase 1 | Complete |
| SAFE-04 | Phase 1 | Complete |
| ONB-01 | Phase 2 | Pending |
| ONB-02 | Phase 2 | Pending |
| ONB-03 | Phase 2 | Pending |
| ONB-04 | Phase 2 | Pending |
| ONB-05 | Phase 2 | Pending |
| CTR-01 | Phase 3 | Pending |
| CTR-02 | Phase 3 | Pending |
| CTR-03 | Phase 3 | Pending |
| CTR-04 | Phase 3 | Pending |
| CTR-05 | Phase 3 | Pending |
| CTR-06 | Phase 3 | Pending |
| STK-01 | Phase 3 | Pending |
| STK-04 | Phase 3 | Pending |
| STK-05 | Phase 3 | Pending |
| SES-01 | Phase 4 | Pending |
| SES-02 | Phase 4 | Pending |
| SES-03 | Phase 4 | Pending |
| SES-04 | Phase 4 | Pending |
| SES-05 | Phase 4 | Pending |
| SHD-01 | Phase 5 | Pending |
| SHD-02 | Phase 5 | Pending |
| SHD-03 | Phase 5 | Pending |
| SHD-04 | Phase 5 | Pending |
| SHD-05 | Phase 5 | Pending |
| STK-02 | Phase 6 | Pending |
| STK-03 | Phase 6 | Pending |
| RES-01 | Phase 6 | Pending |
| RES-02 | Phase 6 | Pending |
| RES-03 | Phase 6 | Pending |
| RES-04 | Phase 6 | Pending |
| RWD-01 | Phase 7 | Pending |
| RWD-02 | Phase 7 | Pending |
| RWD-03 | Phase 7 | Pending |
| RWD-04 | Phase 7 | Pending |
| WLD-01 | Phase 7 | Pending |
| WLD-02 | Phase 7 | Pending |
| WLD-03 | Phase 7 | Pending |
| WLD-04 | Phase 7 | Pending |
| WLD-05 | Phase 7 | Pending |
| WLD-06 | Phase 7 | Pending |

**Coverage:**

- v1 requirements: 49 total
- Mapped to phases: 49 (Phase 1: 9, Phase 2: 5, Phase 3: 9, Phase 4: 5, Phase 5: 5, Phase 6: 6, Phase 7: 10)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-13 — inserted Phase 2 (Character & Onboarding, ONB-01..05); renumbered Room&Contract→3 … Rewards/World→7; 49 requirements across 7 phases*
