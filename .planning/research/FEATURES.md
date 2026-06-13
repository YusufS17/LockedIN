# Feature Research

**Domain:** Multiplayer commitment / accountability study app (iOS SwiftUI, 5-hour hackathon prototype)
**Researched:** 2026-06-13
**Confidence:** HIGH (spec is detailed; comparables are well-documented; research verified against multiple sources)

---

## Grounding: How Comparable Products Work

Before categorizing features, here is what research shows about each comparable:

**StickK** (commitment contract): Contract creation → stake authorization (card held, not charged upfront) → periodic self-reporting → referee can override a "successful" report → forfeit wired to designated recipient. The critical UX pattern: *money is held but not moved until outcome is determined*. Pass/fail is deterministic (you either hit the metric or you didn't). Stakes must have a named recipient (charity, friend/foe, anti-charity) — failure must go *somewhere* real. Referee is the trust anchor for honesty.

**Beeminder** (commitment device with akrasia horizon): You set a measurable goal path. If you derail, you are charged immediately. The crucial pattern here is the *akrasia horizon* — you cannot make the goal easier within 7 days. This is Beeminder's version of contract freezing. The system explicitly refuses to let a panicking user escape the contract mid-session. Pledge escalation (first derail = $5, second = $10) keeps pressure growing.

**Forest / Flora** (social focus): Forest's "Plant Together" makes one person's failure kill everyone's tree — shared consequences, cooperative accountability. Flora adds an optional real-money bet (charged to charity if you fail). Neither has a results "reveal" — they end silently. The key insight: *shared stake, not individual, dramatically increases social pressure*. Flora's per-person stake is low-key; Forest's shared tree is high-drama.

**Focusmate** (body doubling): Pure social presence — cameras on, state your goal at start, silent work, check-in at end. No money, no tracking, no scoring. The accountability mechanism is entirely the *embarrassment cost* of visibly abandoning the session. Very low friction to set up, very high psychological effectiveness. The check-in at the end (brief verbal report) is the payoff moment.

**Study-With-Me livestreams**: Parasocial social presence. No accountability mechanism — pure observational. Shows that social presence alone has real value, but without consequence it is not a commitment device.

**What makes a stakes-based demo feel meaningful vs gimmicky:**
- Money that looks like real currency (£5, not 500 coins) — spec explicitly requires this
- A specific outcome that a neutral observer could confirm (pass/fail criteria must be unambiguous)
- Consequences that go somewhere (forfeited money has a named destination)
- Immutable terms — you cannot renegotiate once committed (Beeminder's akrasia horizon, StickK's frozen contract)
- A reveal that names names — competitive ranking requires courage from the product; avoiding it feels mealy-mouthed

---

## Feature Landscape

### Table Stakes (Demo Fails Without These)

These are the features the section-13 demo cannot function without. Each is a load-bearing pillar. Missing any one makes the core loop feel incomplete or fake.

| Feature | Why Expected / Why Demo Fails Without It | Complexity (5h) | Notes |
|---------|------------------------------------------|-----------------|-------|
| **Preset room creation — "£5 Serious Lock-In"** | Users need a single-tap path into the demo; full custom-contract UI is explicitly out of scope and too slow to build | LOW | One hardcoded preset; no form needed. NavigationLink to review screen. |
| **Contract review screen with explicit pass/fail conditions** | StickK and Beeminder both make terms explicit before commitment. Without reading the contract, "acceptance" is meaningless. Demo must show: 60 min, max 2 distractions, max 1 break, no leaving early | LOW | Static screen with the hardcoded preset terms. Scrollable text + Accept button. |
| **Per-participant "Accept and stake £5" action** | StickK requires individual acceptance; Forest shows individual joins. Without this, there is no commitment moment — the whole loop collapses | LOW | Each bot also "accepts" in the scripted flow (shown as avatar + accepted state). |
| **Contract freeze — immutable after acceptance** | Beeminder's akrasia horizon, StickK's frozen terms. Without this, stakes feel fake (host could just change them). The freeze is the moment the contract becomes real | LOW | State transition: `pending → active`. UI shows lock icon, all edit controls disabled. |
| **Scripted bot participants (Maya, Leo, Sam)** | Without other participants, there is no "room total" and no reveal differentiation. Bots make the demo deterministic and repeatable — essential for a hackathon demo | MEDIUM | Three bots with scripted distraction/override event timelines. Mock data structs, no networking. |
| **"£20 collectively at stake" room total display** | Forest's shared-stake display drives social pressure. Without seeing the collective figure, stakes feel personal rather than social. This is a key differentiator moment | LOW | Sum of 4 × £5 = £20. Display in session header. |
| **Session timer** | Every focus app has a visible countdown. Without it, the session has no tension arc | LOW | SwiftUI `Timer.publish`. Countdown from 60:00. |
| **MockFocusControlAdapter emitting distraction events** | Without fake tracking events, pass/fail has no basis. The mock must emit scripted distraction/override/break events on a timeline | MEDIUM | Simple struct with a timeline array. `DispatchQueue` or Combine-based event emission. |
| **Warning / interruption screen before threshold** | StickK referees can challenge reports; the ethical requirement is that users must know they are about to fail. Without this, the pass/fail feels arbitrary | MEDIUM | Overlay sheet with hold-to-confirm (30px drag or 2s press). Not a cheap toast — this must feel weighty. |
| **Deterministic pass/fail logic in session engine** | Without deterministic rules, the result is unjustifiable. Spec: distraction count, break count, early exit. Sam crosses threshold → fail. Others pass | LOW | Simple counter logic in a `SessionManager` or `CommitmentService`. No ML needed. |
| **Results reveal — room totals + individual titles** | This is the entertainment. Focusmate has an end-of-session check-in; Forest ends silently. LockedIN must end loudly. Without the reveal, there is no payoff for the commitment arc | HIGH | Sequenced animation: room total → champion → biggest culprit (Sam) → first to fold. Title cards with stats behind each. |
| **Wallet: stake held during session, then £15 returned / £5 forfeited** | StickK holds money, then settles. Without the wallet state transition (authorized → held → settled), stakes are just numbers on screen | MEDIUM | `CommitmentService` (Mock) with explicit states: `authorized`, `held`, `returned`, `forfeited`. Minor currency units only (500 = £5.00). |
| **TEST MODE labelling wherever money appears** | Legal and ethical requirement from spec. Without this, the demo could be confused for a real payment product | LOW | A persistent banner/badge component. Injected at every money display site. No exceptions. |
| **`CommitmentService` interface / Mock separation** | Spec acceptance criterion: payment logic must be separated from session and UI code. Without this, there is no credible story for "plug in Stripe later" | LOW | Protocol + Mock implementation. 2-3 methods. The architecture constraint costs almost nothing in time. |

### Differentiators (What Makes LockedIN Distinct)

These are features that no comparable does in quite the same way. They are what justify building LockedIN instead of just using StickK. All of these are in the spec as active requirements — they are differentiators worth protecting in the 5-hour build.

| Feature | Value Proposition | Complexity (5h) | Notes |
|---------|-------------------|-----------------|-------|
| **Frozen contract with visible immutability** | Beeminder has the akrasia horizon (7-day delay); StickK allows changes with referee knowledge. LockedIN freezes instantly on acceptance with an explicit UI state (lock icon, disabled edits). First app to make contract immutability a *visible UX moment* | LOW | Lock icon + disabled state on all contract fields. Transition animation from editable → locked reinforces the moment. |
| **Competitive individual reveal with named titles** | Forest ends silently. Focusmate is supportive. Neither ranks individuals or calls anyone out. LockedIN's "Biggest Culprit" and "First to Fold" titles are the entertainment payoff — competitive/teasing, not punitive | HIGH | The sequenced reveal (room → champion → culprit → first to fold) with stats beneath each title is the centrepiece. Stats prevent the label from feeling arbitrary. |
| **Real-£ framing for test money** | Flora charges real money to charity; Forest uses virtual coins. LockedIN uses simulated £ that looks exactly like real £ (£5.00, not "500 focus coins"). This makes the commitment feel real even in test mode. The spec is explicit: test money must feel meaningful | LOW | Currency formatting throughout. `TEST MODE` label is the safety valve, not a reason to use fantasy currency. |
| **Room-level collective stake display (£20 at stake)** | Forest has shared trees but not shared money. No comparable shows "£20 collectively at stake" as a live social pressure signal. This number gets bigger with more participants — powerful scaling motivation | LOW | Computed from participant count × stake amount. Display in session header. |
| **Hold-to-confirm interruption screen** | StickK lets you just self-report failure. Forest just kills the tree. LockedIN's hold-to-confirm creates deliberate friction before crossing the failure threshold — mirrors Beeminder's "commitment contract you can't easily escape." Makes forfeiture feel earned, not accidental | MEDIUM | SwiftUI long-press gesture or drag interaction. The friction *is the feature*. |
| **Stats-backed titles (culprit reveal with numbers)** | Duolingo leaderboards show points; Forest shows time. LockedIN's reveal titles ("Biggest Culprit — 4 distractions, 2 breaks, left 12 min early") show *why* someone earned their title. This makes the competitive element feel fair rather than arbitrary | MEDIUM | Part of the reveal screen. Each title card unfolds to show the actual metrics. |

### Anti-Features (Deliberately NOT Building)

These are features that seem appealing but would harm the demo, the ethics of the product, or the 5-hour budget. The spec already rules most of these out explicitly — this section explains *why* so the team does not drift back toward them.

| Feature | Why It Seems Appealing | Why It Is Harmful / Out of Scope | What to Do Instead |
|---------|----------------------|----------------------------------|-------------------|
| **Childish punishments (random calls, secret social posts, harassment)** | "Higher stakes" through embarrassment — some apps threaten to post to your social media | Spec explicitly overrides earlier avatar-punishment concept. Harassment is ethically wrong, legally risky, and makes LockedIN feel like a prank app rather than a serious tool. Research shows child/teen-like punishment language reads as "try-hard" and "annoying" | Competitive-but-supportive naming. Titles tease, stats justify. "Biggest Culprit" with actual numbers is teasing, not harassment |
| **Chance-based financial outcomes** | "Jackpot" or lottery mechanics for re-distributing forfeited stakes — feels exciting | Legally a gambling product in most jurisdictions. Spec flags `ENABLE_ROOM_PRIZE_POOL=false` for exactly this reason. Undermines the commitment-device logic (outcome should be deterministic, not random) | Deterministic pass/fail: you passed or you did not. Sam forfeits £5 because of specific rule violations, not by luck |
| **Live attribution / real-time name-on-distraction** | Watching who is distracted in real time feels intense and social | Privacy violation. Spec: default is "private until results." Live attribution deferred. Also creates anxiety rather than accountability | Show live stats only in aggregate during session (e.g. "2 distractions in this room"). Individual attribution only at reveal |
| **Full custom-contract create-room UI** | Users want flexibility to set their own terms | Too expensive for 5h. One polished preset path beats a buggy multi-step form. Also unnecessary for demo — the demo always runs the £5 Serious Lock-In | Single hardcoded preset. Document the interface so a real UI can slot in |
| **Real money / Stripe integration** | Makes the product feel serious | Integration overhead + legal review = easily 10+ hours. Payment architecture is not validated yet. Risk of real financial harm during a demo | `CommitmentService(Mock)` interface — full settlement state machine, but no real money. TEST MODE label everywhere money appears |
| **Real iOS Screen Time / FamilyControls tracking** | Seems necessary for honest focus tracking | OS-level constraints make exact measurement unreliable. FamilyControls requires device entitlements and a managed MDM profile for most configurations. Privacy violations if app names are exposed | `MockFocusControlAdapter` with scripted events. Label tracking as best-effort by design. Never expose which apps were opened |
| **Exposing specific app names in distraction events** | Feels specific and credible | Privacy violation per spec. Even in mock mode, normalizing "you opened Instagram" logging trains users to expect private data exposure | Aggregate metrics only: "3 distractions" not "opened Instagram 3 times" |
| **Accountability-partner forfeit payouts** | Interesting social mechanic — your forfeit goes to a friend's wallet | Settlement path not implemented. Legally complex (is this a transfer of funds between users?). Adds a second party who must be modelled/managed | Forfeits go to a charity placeholder in the mock. Model the `AccountabilityPartner` stake type in the data model but do not implement the settlement path |
| **Cosmetic LockedIN-coin economy** | Avatars, room themes, and cosmetics drive retention | Separate economy from commitment money — conflating them confuses the core value proposition. Out of scope per spec | Two economies must stay separate. Commitment money (real or simulated) never converts to cosmetic coins |
| **Underage onboarding / age verification** | Regulatory completeness | A real age-verification flow takes weeks of legal review and UX work. Gate behind an 18+ confirmation checkbox only for now | Simple "I confirm I am 18+" checkbox before entering a cash-stake room |
| **Real-time cross-device multiplayer** | Makes the demo feel "real" | Networking risk cannot be absorbed in 5h. WebSocket/Firebase integration adds massive surface area for demo failure | Scripted bots on one device. Architecture models multiple participants correctly — the multiplayer story is credible even with local simulation |
| **Sponsored rewards flow** | Revenue model and added value | Flag exists (`ENABLE_SPONSORED_REWARDS`) but flow is not built. Adds a third-party dependency and complicates the UX story | Feature flag only. Do not build the flow |

---

## Feature Dependencies

```
[Preset Room Creation]
    └──requires──> [Contract Review Screen]
                       └──requires──> [Accept + Stake Action (per participant)]
                                          └──requires──> [Contract Freeze / Lock]
                                                             └──requires──> [Session Timer + MockFocusControlAdapter]
                                                                                └──requires──> [Pass/Fail Logic]
                                                                                                   └──requires──> [Wallet: hold → settle]
                                                                                                                      └──requires──> [Results Reveal]

[Bot Participants (Maya, Leo, Sam)]
    └──feeds──> [Room Collective Stake Display (£20)]
    └──feeds──> [Pass/Fail Logic (Sam crosses threshold)]
    └──feeds──> [Results Reveal (individual titles)]

[MockFocusControlAdapter]
    └──feeds──> [Pass/Fail Logic]
    └──feeds──> [Warning / Interruption Screen]

[CommitmentService (Mock)]
    └──implements──> [Wallet state machine]
    └──separates from──> [Session engine and UI]

[TEST MODE Label]
    └──appears at──> [Contract review screen]
    └──appears at──> [Wallet / stake authorization display]
    └──appears at──> [Results reveal (settlement amounts)]
```

### Dependency Notes

- **Contract freeze requires all participants to accept:** The lock transition must only fire when the last participant (or the scripted last bot) has accepted. Partial acceptance = still editable.
- **Results reveal requires settled wallet state:** The wallet must reach `forfeited` / `returned` before the reveal screen renders final amounts. Do not show a reveal while the settlement is "pending."
- **Warning screen requires MockFocusControlAdapter events:** The interruption screen is triggered by a threshold-crossing event from the adapter. Without the adapter emitting events, the warning never fires.
- **Bot timelines must be deterministic:** Bots must follow a fixed script so the demo is repeatable. Sam's "cracks" event must arrive at a predictable point in the session timeline.
- **CommitmentService is a hard architectural boundary:** Pass/fail logic in the session engine calls `CommitmentService.settle(participant:outcome:)`. The UI reads from the service. No money math in views.

---

## MVP Definition

### The Section-13 Demo Spine (Hackathon MVP)

The minimum that must work for the demo to land. Every item here is a table-stakes or differentiator feature from above.

- [ ] **Preset room creation** — single tap, no form
- [ ] **Contract review screen** — readable terms, TEST MODE banner
- [ ] **Per-participant accept + stake £5** — user + 3 bots each accept in sequence
- [ ] **Contract freeze** — visible lock state after last acceptance
- [ ] **£20 collectively at stake** — session header
- [ ] **Session timer** — 60-minute countdown
- [ ] **MockFocusControlAdapter** — scripted timeline: Maya clean, Leo one break, Sam cracks at ~20 min mark
- [ ] **Pass/fail logic** — Sam crosses distraction threshold → fails
- [ ] **Warning / interruption screen** — fires before Sam crosses threshold; Sam confirms through it (scripted)
- [ ] **Wallet state machine** — `authorized → held → returned (£15) / forfeited (£5)`
- [ ] **Results reveal** — sequenced: room total → LockedIN Champion → Biggest Culprit (Sam, with stats) → First to Fold
- [ ] **TEST MODE labelling** — at every money display point

### Differentiators to Protect (Do Not Cut These)

If time pressure forces cuts, these should be the last to go because they are what make LockedIN *distinct*:

- [ ] **Contract freeze with visible lock UX** — the immutability moment is the product's core idea
- [ ] **Hold-to-confirm interruption screen** — without friction, the failure feels trivial
- [ ] **Stats-backed titles in reveal** — without numbers, titles feel arbitrary and mean-spirited

### Add After Validation (Post-Hackathon)

- [ ] Real FamilyControls / Screen Time integration — requires device entitlements and UX for permission
- [ ] Real-time cross-device multiplayer — WebSocket or Firebase; validate demand first
- [ ] Stripe / real-money integration — legal review, KYC, age verification pipeline
- [ ] Custom-contract create-room UI — full host configuration form
- [ ] Accountability-partner forfeit settlement — complex legal and UX; model data first

### Future Consideration (v2+)

- [ ] Room prize pool / pot redistribution — legal review per jurisdiction; `ENABLE_ROOM_PRIZE_POOL`
- [ ] Sponsored rewards — partnership pipeline; `ENABLE_SPONSORED_REWARDS`
- [ ] LockedIN-coin cosmetic economy — separate product workstream; never conflate with commitment money
- [ ] Supportive mode (no negative rankings) — settings toggle; validate need from users first

---

## Feature Prioritization Matrix

| Feature | Demo Value | Build Cost (5h budget) | Priority |
|---------|------------|------------------------|----------|
| Preset room creation | HIGH | LOW | P1 |
| Contract review screen | HIGH | LOW | P1 |
| Accept + stake action | HIGH | LOW | P1 |
| Contract freeze / lock | HIGH | LOW | P1 |
| Scripted bot participants | HIGH | MEDIUM | P1 |
| Room collective stake (£20) | HIGH | LOW | P1 |
| Session timer | HIGH | LOW | P1 |
| MockFocusControlAdapter | HIGH | MEDIUM | P1 |
| Pass/fail logic | HIGH | LOW | P1 |
| Warning / interruption screen | HIGH | MEDIUM | P1 |
| Wallet state machine | HIGH | MEDIUM | P1 |
| Results reveal (sequenced) | HIGH | HIGH | P1 |
| TEST MODE labelling | HIGH | LOW | P1 |
| CommitmentService interface | MEDIUM | LOW | P1 (architecture gate) |
| Hold-to-confirm friction | HIGH | MEDIUM | P1 (differentiator) |
| Stats-backed reveal titles | HIGH | MEDIUM | P1 (differentiator) |
| Real Stripe integration | LOW | VERY HIGH | P3 |
| Custom-contract form | LOW | HIGH | P3 |
| Real FamilyControls | LOW | HIGH | P3 |
| Cosmetic coin economy | NONE (demo) | HIGH | P3 |

**Priority key:**
- P1: Must have — demo fails without it
- P2: Should have — enhances demo but is not a failure if cut
- P3: Defer — future milestone

---

## Competitor Feature Analysis

| Feature | StickK | Beeminder | Forest | Flora | Focusmate | LockedIN (planned) |
|---------|--------|-----------|--------|-------|-----------|-------------------|
| Financial stake | Yes (real $) | Yes (real $, escalating) | No | Optional (real $, to charity) | No | Simulated £ (looks real) |
| Multiplayer / group | No | No | Yes (shared tree) | Yes (group session) | Yes (1:1 pairs) | Yes (room with bots, then real) |
| Contract freeze / immutability | Partial (referee) | Yes (akrasia horizon, 7-day) | N/A | N/A | N/A | Yes (instant freeze on acceptance) |
| Deterministic pass/fail | Self-report + referee | Automated (data-driven) | Binary (left or not) | Binary (left or not) | Honour system | Deterministic rules engine |
| Competitive reveal / ranking | No | No | No | No | No | Yes (titles + stats) |
| Forfeit recipient | Charity / friend/foe | Beeminder | Virtual (tree dies) | Charity (real trees) | N/A | Settlement placeholder (mock) |
| Real-time tracking | Self-report | Data entry / integrations | Binary leave-detection | Binary leave-detection | Camera / presence | MockFocusControlAdapter (scripted) |
| Social pressure signal | Supporters journal | Public graph | Shared tree death | Shared tree | Visible partner | £20 collectively at stake |
| Warning before failure | No | Yes (yellow road → red) | No (instant) | No (instant) | No | Yes (interruption screen + hold-to-confirm) |
| Results entertainment | No | Graph / history | Silent | Silent | Brief check-in | Sequenced reveal with competitive titles |

---

## Sources

- [StickK FAQ — Stakes and Commitment Contracts](https://www.stickk.com/faq/stakes/Commitment+Contracts)
- [StickK — How It Works (Help Center)](https://stickk.zendesk.com/hc/en-us/articles/206833157-How-it-Works)
- [StickK — Referee FAQ](https://www.stickk.com/faq/referees/Commitment+Contracts)
- [Beeminder — What Is Beeminder?](https://help.beeminder.com/article/70-what-is-beeminder)
- [Beeminder — The Akrasia Horizon](https://help.beeminder.com/article/45-what-is-the-akrasia-horizon)
- [Beeminder — The Road Dial and the Akrasia Horizon (Blog)](https://blog.beeminder.com/dial/)
- [Focusmate — FAQ](https://www.focusmate.com/faq/)
- [Forest — Gamification Case Study (Trophy)](https://trophy.so/blog/forest-gamification-case-study)
- [Flora — FAQ](https://flora.appfinca.com/faq/)
- [Forest vs Flora Comparison — NerdyNav](https://nerdynav.com/forest-vs-flora-pomodoro/)
- [Study With Me — Peer Support Research (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC12257490/)
- [Psychology of Commitment Devices — C'Meet It Blog](https://cmeetit.com/blog/psychology-of-commitment-devices.html)
- [Commitment Devices — Learning Loop](https://learningloop.io/plays/psychology/commitment-devices)
- [Commitment and Behavioral Consistency UX — NN/g](https://www.nngroup.com/articles/commitment-consistency-ux/)
- [Dark Side of Gamification — Medium](https://medium.com/@jgruver/the-dark-side-of-gamification-ethical-challenges-in-ux-ui-design-576965010dba)

---

*Feature research for: LockedIN — multiplayer commitment study app*
*Researched: 2026-06-13*
