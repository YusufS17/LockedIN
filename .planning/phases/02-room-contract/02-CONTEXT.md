# Phase 2: Room & Contract - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

The **commitment ritual**: from tapping the preset "£5 Serious Lock-In" room, through reviewing and accepting a real-feeling contract, watching three scripted bots (Maya, Leo, Sam) join and stake, to the contract visibly **freezing** with £20 collectively at stake — all before any session starts.

This phase delivers the "commitment + social pressure" half of the core loop becoming tangible on screen. It does NOT include the live study session, focus tracking, interruptions, or the reveal (Phases 3–5), nor the buildable world/edit (Phase 6).

In scope: home/entry screen with the one preset room tile · minimal 18+ gate · contract review screen · per-participant accept-and-stake · scripted bot join/accept choreography · contract freeze (immutability + visible lock) · stake shown as authorised/held in the simulated wallet.

Out of scope (defer / other phases): custom contract configuration, multiple rooms / real lobby, friend invites, the live session HUD, the cozy isometric pixel-art room view (Phase 3), real networking, real payments.
</domain>

<decisions>
## Implementation Decisions

### Entry & 18+ gate flow
- **D-13:** App lands on a **simple home screen** with the single "£5 Serious Lock-In" preset room tile, replacing the current Phase 1 walking-skeleton `RootView`. No room list, no configuration form — one tap on the tile leads to the contract review screen (CTR-01).
- **D-14:** The **18+ adult-confirmation gate is intentionally minimal** for the demo (user: "idc about the 18+ thing too much for demo purpose"). Implement it as a lightweight one-tap "I confirm I'm 18+" confirmation the first time the user enters the cash-stake room, then proceed. It must exist (SAFE / STK-05) and be honest (no deceptive buttons), but gets no extra ceremony. A simple in-memory "confirmed" flag is fine — no persistence required.

### Contract screen layout
- **D-15:** Present the contract as **two grouped sections — "KEEPS YOUR £5" (pass conditions) and "LOSES YOUR £5" (fail conditions)** — with a summary block up top showing the £5.00 stake (with the inline TEST marker via `MoneyLabel`) and the "forfeit → ❤ British Red Cross" destination. This framing makes the consequence land hardest and serves the core value (stake must *feel real*). All six terms from CTR-02 must appear across the two groups: duration, break allowance, permitted distractions, leaving-early rule, stake amount, forfeit destination.
- **D-16:** Concrete contract term values (Claude's discretion, aligned with the section-13 demo and the accepted previews): **duration 25 min · 1 break up to 5 min · up to 3 permitted distraction events · leaving early forfeits the full stake · stake £5.00 each · forfeit destination British Red Cross.** These are the displayed/frozen contract values; the *accelerated demo clock* for actually running the timer is a Phase 3 concern, not Phase 2.

### Bot join/accept choreography
- **D-17:** Bots accept with a **deliberate, suspenseful cadence (~2s per bot)**: each shows a "joining…" state that flips to "accepted ✓ staked £5", driven by `Task.sleep` scripted sequences (per CLAUDE.md bot-scripting approach). A running tally ticks up **£5 → £10 → £15 → £20** as each participant commits, so the "£20 collectively at stake (£5 each)" header (CTR-06) lands with weight. Order: the user accepts first, then Maya, Leo, Sam.
- **D-18:** Participants are shown in a **roster/list** (you + the three bots) with per-participant status (waiting · joining… · accepted ✓). Avatars are **simple pixel portraits / coloured circles** in this phase — NOT the full isometric room (see D-19).

### Freeze moment + room visual
- **D-19:** The **cozy isometric pixel-art study room is deferred to Phase 3** (the live session HUD). Phase 2 stays as clean contract + participant-roster screens. The room is built once in Phase 3 and reused/grown later (protects the 5h budget; lets Phase 2 ship reliably). Avatars in Phase 2 are lightweight pixel portraits/circles.
- **D-20:** The contract **freeze is a satisfying beat, not just a flag flip**: when the last participant (Sam) accepts, the contract fields dim & disable, a 🔒 lock icon snaps in with a brief seal/shake effect and a haptic, and the header settles to "£20 locked in / collectively at stake." This is a core "feels real" moment (frozen contract). After freeze, the contract is immutable (CTR-04/CTR-05) — any attempt to modify has no effect, enforced structurally (the frozen `CommitmentContract` from Phase 1 already supports `frozen()` / `frozenAt`).

### Claude's Discretion
- Exact short-form copy/wording for term rows, button labels, and the freeze caption.
- Exact pixel-portrait/avatar style for the roster (keep lightweight).
- Visual styling within the established Phase 1 design tokens (`Theme`) and playful tone (D-04/D-05).
- Bot personalities surfaced lightly (names only required: Maya, Leo, Sam); richer character is a reveal-phase concern.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & phase scope
- `.planning/PROJECT.md` — core value (stake must feel real), constraints (5h budget, simulated wallet/bots, iOS/SwiftUI), and the **Visual Direction** section describing the study-room aesthetic
- `.planning/ROADMAP.md` §"Phase 2: Room & Contract" — goal, 5 success criteria, requirement IDs
- `.planning/REQUIREMENTS.md` — CTR-01..CTR-06, STK-01, STK-04, STK-05 (full text)

### Carried-forward decisions (Phase 1)
- `.planning/phases/01-foundation/01-CONTEXT.md` — D-01..D-12 (inline TEST money markers, playful tone, design tokens, £20 wallet, British Red Cross, 8 settlement states)
- `.planning/phases/01-foundation/01-SUMMARY.md` — what Phase 1 actually built (Money, MoneyLabel, Theme, FeatureFlags, AppStore, CommitmentContract, Participant, ParticipantSettlementState, CommitmentService/FocusControlAdapter protocols + mocks)

### Visual reference
- `.planning/reference/study-room-mockup.png` — the cozy isometric study-room mockup. **Informs Phase 3+, NOT Phase 2's screens** (room visual deferred per D-19) — but planner/UI should keep Phase 2 visually compatible with it (same design tokens, same warm dark-academia palette).

### Build conventions
- `CLAUDE.md` — tech stack (iOS 17, SwiftUI, `@Observable`, no SPM deps, Swift 5 mode), money as `Int` pence, TEST MODE enforcement, bot scripting via `Task.sleep`, safety/ethics (honest exit, no deceptive buttons, no chance-based outcomes)

No external (third-party) specs — requirements fully captured in the decisions above and the refs listed.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LockedIN/Models/CommitmentContract.swift` — frozen-struct contract with `frozen()` / `frozenAt` and invariant-guarded init; directly powers the contract screen + freeze (D-20).
- `LockedIN/Models/Participant.swift` — participant model for the roster (you + Maya/Leo/Sam).
- `LockedIN/Models/ParticipantSettlementState.swift` — 8-state machine; "authorised/held" maps to `.awaitingAuthorisation` → `.held` for STK-01.
- `LockedIN/Services/CommitmentService.swift` + `MockCommitmentService.swift` — the wallet seam; authorise/hold the £5 stakes through this protocol (UI must NOT call concrete service — go through AppStore, per SAFE-04). Wallet seeded £20.00, forfeit "British Red Cross" (shared `ForfeitConfig`).
- `LockedIN/Design/MoneyLabel.swift` — the ONLY sanctioned £ renderer; use it for the stake, the tally, and the wallet display (TEST marker travels with every figure).
- `LockedIN/Design/Theme.swift` — design tokens (palette, type, spacing) established in Phase 1; consume, don't reinvent.
- `LockedIN/Services/MockFocusControlAdapter.swift` — not used in Phase 2, but the `Task.sleep` scripted-emitter pattern is the model for the bot accept choreography (D-17).

### Established Patterns
- `@Observable AppStore` injected via `.environment()` at `WindowGroup` root — Phase 2 screens read/observe AppStore; navigation likely via `NavigationStack`/`NavigationPath` (per CLAUDE.md) home → contract → frozen.
- Money is `Int` pence end-to-end; format only at the `MoneyLabel` boundary.
- Bots are scripted `Task.sleep` sequences whose `Task` handles are stored for cancellation (mirror the focus-adapter approach, now `NSLock`-guarded).

### Integration Points
- Replace the Phase 1 walking-skeleton `RootView` content with the new home screen (the £5 room tile). Keep the AppStore wiring intact.
- Stake authorisation flows AppStore → `commitmentService.authoriseHold(...)`, transitioning each participant's settlement state to `.held` (STK-01).
</code_context>

<specifics>
## Specific Ideas

- Contract screen "Grouped Pass vs Fail" mock the user approved:
  `£5.00 at stake · TEST` / `forfeit → ❤ British Red Cross` / **KEEPS YOUR £5**: ✓ stay 25 min, ✓ ≤1 break (5 min) / **LOSES YOUR £5**: ✗ leave early, ✗ >3 distractions.
- Roster choreography mock the user approved: `You ✓ staked £5 / Maya ✓ staked £5 / Leo … joining / Sam · waiting` with `£10 of £20 at stake` building to £20.
- Freeze beat the user approved: contract dims → `🔒 CONTRACT FROZEN` *snap* + haptic → `£20 locked in`.
</specifics>

<deferred>
## Deferred Ideas

- **Cozy isometric pixel-art study room** with avatars at desks — deferred to **Phase 3** (session HUD); built once and reused/grown in Phase 6 (D-19).
- **Richer bot personalities** (banter, distinct behaviours) — surfaces in the **session (Phase 3/4)** and **reveal (Phase 5)**, where Sam cracks and becomes Biggest Culprit.
- **Multiple rooms / real lobby / custom contracts / friend invites** — out of the preset-only spine; future milestone (need backend for real multiplayer).
- **Elaborate 18+ / age verification** — kept minimal by user direction (D-14); a real KYC/age flow is out of hackathon scope.
- **Persisting the 18+ confirmation / room state** — Phase 2 keeps session state in-memory; persistence is reserved for world + coins only (per PROJECT.md).

None of the above pulled into Phase 2 scope — discussion stayed within the commitment-ritual boundary.
</deferred>

---

*Phase: 2-room-contract*
*Context gathered: 2026-06-13*
