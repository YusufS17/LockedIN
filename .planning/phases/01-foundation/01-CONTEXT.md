# Phase 1: Foundation - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

The money-correct substrate every later phase builds on. Phase 1 delivers, with **no user-facing flows** beyond the design-system component:

- `Pence` / `MinorUnits` integer typealias — all monetary fields use it; zero `Double`/`Float` for money anywhere
- `ParticipantSettlementState` enum — the 8 named states (see Decisions)
- `CommitmentService` and `FocusControlAdapter` protocols + `MockCommitmentService` / `MockFocusControlAdapter` implementations
- The 4 feature flags + their locked values
- The TEST MODE design system: a `MoneyLabel` / `TestModeBadge` component that renders £ amounts with the TEST marker baked in

Maps to requirements **FND-01..05** and **SAFE-01..04**.

This phase is plumbing + one design-system component. Room/contract UI, session engine, shield, results, and world are later phases.

</domain>

<decisions>
## Implementation Decisions

### TEST MODE treatment (SAFE-01)
- **D-01:** The "NO REAL MONEY" warning is delivered as an **inline badge attached to every £ amount** — NOT a separate persistent top banner. The marker travels with the figure.
- **D-02:** This must be **structurally enforced**: the `MoneyLabel` component is the only sanctioned way to render a £ amount, and it always renders the TEST marker alongside the value. It should be impossible to display formatted money without the marker — that's how SAFE-01 ("every screen that shows a £ amount") is guaranteed by construction rather than by remembering to add a banner per screen.
- **D-03:** Marker copy carries the full intent of "TEST MODE — NO REAL MONEY WILL MOVE." A compact inline form (e.g. a "TEST" pill on the figure) is acceptable as long as the full statement is reachable/legible on money screens; planner/UI to settle exact short-form wording.

### Design system tone
- **D-04:** **Playful throughout** — bright, game-y, energetic personality across ALL screens including the stake/contract/session screens, not just the reveal. This is the foundational mood for all 6 phases.
- **D-05:** Playful tone must NOT undercut the two hard constraints: (a) the stake still has to *feel real* (core value), and (b) honest UX / no deceptive buttons (SAFE). Playful = visual energy, color, character — never gimmicky punishments or dark patterns (those are explicitly out of scope).
- **D-06:** Establish foundational design tokens here (color palette, type scale, spacing, the playful character) so later phases consume them rather than reinventing per screen. Keep it lightweight — this is a 5h build, not a full design system.

### Money display format
- **D-07:** Always render **2 decimal places** — `£5.00`, `£15.00`, `£0.50`. Never trim whole amounts. Reinforces "this is real money" trust.
- **D-08:** Single formatting function converts `Pence` → display string at the display boundary only (per CLAUDE.md). `MoneyLabel` is the consumer of that function.

### Mock / demo seed defaults
- **D-09:** Simulated wallet starts at **£20.00** (2000 pence). The £5 stake comes out of this, leaving a believable student balance with consequential-feeling headroom.
- **D-10:** Forfeit-destination placeholder = a **named charity, "British Red Cross"** (Claude's discretion — user said "you decide"). Shown identically before and after settlement (STK-04 surfaces in later phases; seed the value here in the mock).

### Settlement state model (locked from ROADMAP, not re-discussed)
- **D-11:** `ParticipantSettlementState` uses exactly the 8 states from ROADMAP success criterion #3: `notRequired`, `awaitingAuthorisation`, `held`, `authorisedForReturn`, `authorisedForForfeit`, `returned`, `forfeited`, `settlementError`. Where REQUIREMENTS FND-04 lists looser example states ("e.g. ..."), the ROADMAP's 8-state set is canonical.

### Feature flags (locked from ROADMAP/FND-05, not re-discussed)
- **D-12:** Four flags with these values: `ENABLE_REAL_MONEY_STAKES=false`, `ENABLE_TEST_STAKES=true`, `ENABLE_ROOM_PRIZE_POOL=false`, `ENABLE_SPONSORED_REWARDS=true`. They must be honoured (read at the relevant boundaries), not just declared.

### Claude's Discretion
- Exact short-form wording of the inline TEST marker (full statement must remain reachable).
- Concrete design tokens (palette hex, type scale) — guided by "playful throughout."
- Forfeit-destination charity name (defaulted to "British Red Cross").
- Internal file/module layout — follow CLAUDE.md's single `AppStore` holding `SessionStore` / `WalletStore` / `RoomStore`, injected via `.environment()`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project specs (primary)
- `CLAUDE.md` — full locked tech stack: `@Observable` stores, `Int` pence minor units, `TimelineView` timer, mock `CommitmentService` / `FocusControlAdapter`, in-memory only (NO SwiftData/UserDefaults for session state), iOS 17 target, Swift 5 language mode. Also the "What NOT to Use" table — hard exclusions.
- `.planning/ROADMAP.md` §"Phase 1: Foundation" — goal + 5 success criteria (the 8-state enum and 4 flags are spelled out here authoritatively).
- `.planning/REQUIREMENTS.md` — FND-01..05 (foundation) and SAFE-01..04 (safety/integrity). Note FND-04's state list is illustrative; ROADMAP's is canonical.

No external ADRs — requirements fully captured in CLAUDE.md + ROADMAP + REQUIREMENTS + the decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — empty codebase (no `.swift` files). This phase establishes the assets everything else reuses.

### Established Patterns
- Patterns are defined prescriptively in CLAUDE.md (not yet in code): one `@Observable` class per domain, `.environment()` injection, money formatted only at display boundaries, protocol boundaries for `CommitmentService` / `FocusControlAdapter`.

### Integration Points
- `MoneyLabel` / `TestModeBadge` → consumed by every money-displaying screen in Phases 2, 5, 6.
- `CommitmentService` mock → consumed by wallet/stake flows in Phases 2 and 5.
- `FocusControlAdapter` mock → consumed by the session engine (Phase 3) and shield (Phase 4).
- `ParticipantSettlementState` → drives the settlement state machine in Phase 5.

</code_context>

<specifics>
## Specific Ideas

- Make displaying money-without-the-TEST-marker structurally impossible by funnelling all £ rendering through one `MoneyLabel` component (D-02) — this is the cleanest way to satisfy SAFE-01 across an unknown number of future screens.
- "Playful throughout" but the £5 stake must still land as real — visual energy, not gimmicks.

</specifics>

<deferred>
## Deferred Ideas

- **Room prize pool as a forfeit destination** (redistribute forfeited £ to passers) — gated behind `ENABLE_ROOM_PRIZE_POOL=false`; a v2 stake type (REQUIREMENTS STAKE-02). Not for the demo. Surfaced while choosing the forfeit placeholder.
- Real implementations behind the same protocols (`StripeCommitmentService`, real Screen Time `FocusControlAdapter`) — explicitly v2 (PAY-01/02, REAL-01/02). The Phase 1 protocols must stay clean enough that these slot in later, but they are not built now.

None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Foundation*
*Context gathered: 2026-06-13*
