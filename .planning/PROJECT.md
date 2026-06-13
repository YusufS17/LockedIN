# LockedIN

## What This Is

LockedIN is a multiplayer *commitment* platform for students — not a Pomodoro timer with avatars. Students enter a study room, agree to a measurable focus contract, put a meaningful stake on the line, study while their behaviour is tracked on a best-effort basis, and then win back their stake (or forfeit it) at a funny-but-meaningful post-session reveal that crowns the most focused player and the biggest culprit.

This repo targets a **hackathon prototype**: a native iOS (SwiftUI) app that proves the core loop — *commitment → social pressure → best-effort tracking → consequence reveal* — using simulated participants and a simulated test-money wallet that looks and feels like real £.

## Core Value

The commitment-to-consequence loop must *feel real*: a frozen contract with a genuine-feeling stake, honest pressure when you try to break it, and a satisfying reveal that returns or forfeits the money. If everything else is cut, the £5 stake landing as "£15 returned / £5 forfeited" with Sam crowned Biggest Culprit must work.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. The section-13 demo spine. -->

- [ ] User can start a £5 "Serious Lock-In" room from a preset (minimal config, not the full custom-contract form)
- [ ] Each participant sees a clear contract with explicit pass/fail conditions and separately accepts via "Accept and stake £5"
- [ ] Contract becomes immutable (frozen) once accepted — host cannot raise stake, cut breaks, or change thresholds
- [ ] 3 scripted bot friends (Maya focused, Leo one break, Sam cracks) join the room; UI shows "£20 collectively at stake"
- [ ] Session timer runs and the Mock focus adapter emits scripted distraction/override events without exposing app names
- [ ] A participant receives a clear warning before crossing the failure threshold (interruption screen with hold-to-confirm)
- [ ] Pass/fail is decided by deterministic contract rules (distraction limit, breaks, leaving early)
- [ ] Simulated wallet shows the stake authorised/held during the session, then £15 returned / £5 forfeited in test mode
- [ ] Persistent, unmissable "TEST MODE — NO REAL MONEY WILL MOVE" labelling wherever money appears
- [ ] Results reveal shows room totals, then individual titles (LockedIN Champion, Biggest Culprit, First to Fold) with the real stats behind each
- [ ] Payment/settlement logic lives behind a `CommitmentService` (Mock) interface, fully separated from session and UI code
- [ ] Money stored in minor currency units (£5.00 = 500), never floating point

### Out of Scope

<!-- Architecture-aware but NOT built in the 5-hour prototype. Documented as feature-flagged / future so the design stays honest. -->

- Real money / Stripe integration — `ENABLE_REAL_MONEY_STAKES=false`; simulated wallet only for the demo; legal + payment architecture not in scope
- Real-time cross-device multiplayer — bots are scripted on one device; live state-sync is networking risk we can't afford in 5h
- Real iOS Screen Time / FamilyControls tracking — OS limits make exact measurement unreliable; `MockFocusControlAdapter` drives the demo
- Full custom-contract create-room UI — preset path only; the full host configuration form is deferred
- Room prize pool — `ENABLE_ROOM_PRIZE_POOL=false`; legally sensitive, adult-only, requires jurisdiction review
- Sponsored rewards — flag exists (`ENABLE_SPONSORED_REWARDS`) but the flow isn't built for the prototype
- Accountability-partner forfeit payouts — modelled as a stake type, settlement path not implemented
- Cosmetic LockedIN-coin economy (avatars/room customisation) — separate economy, not part of the commitment demo
- Underage onboarding flows — prototype gates cash-stake rooms behind an 18+ adult confirmation; no real age verification
- Live-attribution visibility mode — default is "private until results"; live name-attribution path deferred

## Context

- **Hackathon build**, brand-new empty repo (no prior code, spikes, or sketches).
- Source spec: a detailed "High-Stakes Commitment System" amendment that explicitly *overrides* an earlier avatar-punishment concept. The behavioural mechanism is meaningful commitment and genuine stakes — never childish punishments (no random calls/messages, no secret posts, no harassment).
- Two **separate economies** in the product vision: (A) commitment money (real or simulated, returned/forfeited per contract, never a cosmetic currency) and (B) LockedIN coins (earned, cosmetic-only, non-withdrawable). Only economy A is in the prototype.
- Tracking is **best-effort by design** — the app must never invent data in production, must label tracking honestly, and must never expose which apps a participant blocked/opened, browsing, messages, contacts, or notification contents. Only aggregate metrics are shown.
- The **reveal is the entertainment** — competitive/teasing tone is fine, abuse is not; supportive rooms can disable negative rankings; titles always show the numbers behind them.
- Target demo is section 13 of the spec: £5 Serious Lock-In, three bots, Sam cracks, Sam = Biggest Culprit, £15 returned / £5 forfeited.

## Constraints

- **Timeline**: ~5 hours total build budget — ruthless scope; nail the single section-13 demo spine, defer everything else. This is the dominant constraint.
- **Tech stack**: Native iOS, SwiftUI — chosen over web/cross-platform despite the tighter hackathon timeline.
- **Multiplayer**: Simulated participants (scripted bots) only — architecture models multiple participants, but no real networking.
- **Payments**: Simulated in-app wallet only — no Stripe, no real money; `CommitmentService` interface kept clean so a real implementation could slot in later.
- **Data integrity**: Money in minor units, no floats; settlement states explicit; payment logic separated from UI/session (acceptance criterion #15).
- **Safety/ethics**: No deceptive buttons, always an honest emergency exit, no exposure of private app/usage data, no harassment or chance-based financial outcomes.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native iOS (SwiftUI) over web/RN | User chose iOS; aligns with Screen Time framing even though real tracking is deferred | — Pending |
| Simulated participants, not real-time multiplayer | 5h budget can't absorb live state-sync risk; bots make the demo deterministic and repeatable | — Pending |
| Simulated wallet, no Stripe | Avoids integration + legal overhead; `CommitmentService` interface preserves a future Stripe path | — Pending |
| Preset £5 "Serious Lock-In" path only | Full custom-contract UI is too expensive for 5h; one polished vertical slice beats broad-but-shallow | — Pending |
| Model the full data model + settlement states despite mocks | Cheap to add and makes the demo feel real/credible; keeps architecture honest | — Pending |
| Test money looks like real £ (not fantasy coins) in commitment flow | Spec is explicit: the stake must feel meaningful; cosmetic coins stay a separate economy | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-13 after initialization*
