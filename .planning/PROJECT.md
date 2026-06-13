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
- [ ] **Opal-style app shield (simulated):** "opening" a blocked social/games app during a session triggers a full-screen LockedIN block overlay; driven by the `MockFocusControlAdapter`, it counts as a distraction/override event per contract rules and offers the honest "return / use break / continue and record" choices
- [ ] **Idle focus rewards:** focused participants visibly "work" and accrue LockedIN coins/treasure on a timer (accelerated for the demo); earning pauses while a participant is distracted or has cracked — rewards genuinely staying in the room
- [ ] Results screen tallies coins/treasure earned **separately** from the commitment £ (the two economies stay visually and conceptually distinct)
- [ ] **Personal world:** each user has a world/room that visibly grows as they earn coins/treasure from focused study; study solo to build your own
- [ ] **Shared world:** a user can join a group world and contribute alongside the room's participants (demo: aggregated locally from the room)
- [ ] **View neighbours' worlds:** browse the bots'/neighbours' pre-seeded worlds for Minecraft-esque comparison and competition
- [ ] **Local persistence:** world + coin/treasure progress is saved on-device and survives app relaunch (SwiftData/UserDefaults)

### Out of Scope

<!-- Architecture-aware but NOT built in the 5-hour prototype. Documented as feature-flagged / future so the design stays honest. -->

- Real money / Stripe integration — `ENABLE_REAL_MONEY_STAKES=false`; simulated wallet only for the demo; legal + payment architecture not in scope
- Real-time cross-device multiplayer — bots are scripted on one device; live state-sync is networking risk we can't afford in 5h
- Networked worlds (real cross-device shared/joint world sync; browsing real strangers' worlds globally) — requires accounts + a backend; the in-build world system is local-only (your world + pre-seeded neighbour worlds). True multi-device worlds are the next milestone
- Real OS-level app blocking + Screen Time / FamilyControls tracking — needs Apple's Family Controls entitlement + a physical device + provisioning; too risky for 5h. The **simulated shield** (above) delivers the Opal-style experience; real OS enforcement is the documented post-hackathon path
- Full custom-contract create-room UI — preset path only; the full host configuration form is deferred
- Room prize pool — `ENABLE_ROOM_PRIZE_POOL=false`; legally sensitive, adult-only, requires jurisdiction review
- Sponsored rewards — flag exists (`ENABLE_SPONSORED_REWARDS`) but the flow isn't built for the prototype
- Accountability-partner forfeit payouts — modelled as a stake type, settlement path not implemented
- LockedIN-coin **spending** (avatar/room cosmetic shop) — coins are *earned and displayed* in the demo (see Active), but the shop/purchase side is deferred; coins remain non-withdrawable, non-transferable, and never convertible to commitment money
- Underage onboarding flows — prototype gates cash-stake rooms behind an 18+ adult confirmation; no real age verification
- Live-attribution visibility mode — default is "private until results"; live name-attribution path deferred

## Context

- **Hackathon build**, brand-new empty repo (no prior code, spikes, or sketches).
- Source spec: a detailed "High-Stakes Commitment System" amendment that explicitly *overrides* an earlier avatar-punishment concept. The behavioural mechanism is meaningful commitment and genuine stakes — never childish punishments (no random calls/messages, no secret posts, no harassment).
- Two **separate economies** in the product vision: (A) commitment money (real or simulated, returned/forfeited per contract, never a cosmetic currency) and (B) LockedIN coins (earned by focused time, cosmetic-only, non-withdrawable). Economy A is fully in the prototype; economy B is now **partially** in — coins are *earned and displayed* (the idle focus-reward mechanic), but *spending* them in a cosmetic shop is deferred. The two must never be conflated on screen.
- **Opal-style blocking** is delivered as a *simulated shield overlay* for the hackathon: the experience of being blocked from a distracting app is reproduced in-app via the Mock adapter, without real OS-level enforcement (which needs the Family Controls entitlement). This keeps the demo honest — we never claim real enforcement we don't have.
- Tracking is **best-effort by design** — the app must never invent data in production, must label tracking honestly, and must never expose which apps a participant blocked/opened, browsing, messages, contacts, or notification contents. Only aggregate metrics are shown.
- The **reveal is the entertainment** — competitive/teasing tone is fine, abuse is not; supportive rooms can disable negative rankings; titles always show the numbers behind them.
- Target demo is section 13 of the spec: £5 Serious Lock-In, three bots, Sam cracks, Sam = Biggest Culprit, £15 returned / £5 forfeited.

## Constraints

- **Timeline**: ~5 hours total build budget — ruthless scope; nail the single section-13 demo spine, defer everything else. This is the dominant constraint.
- **Tech stack**: Native iOS, SwiftUI — chosen over web/cross-platform despite the tighter hackathon timeline.
- **Multiplayer**: Simulated participants (scripted bots) only — architecture models multiple participants, but no real networking.
- **Persistence**: Local on-device only (SwiftData/UserDefaults) for world + coin progress. This intentionally overrides the research's "zero persistence" recommendation, but *only* for the world-save feature — the commitment session itself stays in-memory and deterministic. No cloud/backend persistence.
- **World/social**: The world system ships local-only — your world grows from earned coins, neighbour worlds are pre-seeded mocks. Genuine networked/shared worlds are deferred (need a backend).
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
| Opal-style blocking is a simulated shield, not real OS enforcement | Family Controls entitlement + device provisioning can't be reliably done in 5h; sim delivers the same demo experience honestly | — Pending |
| Idle coins earned by focused time only (not pure presence) | Rewards genuine focus and reinforces the core loop; pure-presence would reward sitting distracted | — Pending |
| Coins earned + shown in demo, but coin shop/spending deferred | Earning/display is cheap and adds charm; the cosmetic purchase economy is out-of-spine for 5h | — Pending |
| Coins/treasure build a persistent personal world (the coin sink) | Makes focus visibly rewarding (Forest/Minecraft-esque); turns the coin economy into a trophy | — Pending |
| World system is local-only; networked/shared worlds deferred | Real cross-device shared worlds + browsing strangers need a backend — impossible in 5h | — Pending |
| Add local persistence (SwiftData/UserDefaults) for world + coins only | "Progress is saved" must feel true on the demo device; session stays in-memory | — Pending |
| Demo spine sequenced first, world/social as the ambitious back half | Guarantees a working commitment demo even if world build runs long | — Pending |

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
*Last updated: 2026-06-13 after initialization (+ simulated app-shield, idle focus-reward, and local persistent world/social features)*
