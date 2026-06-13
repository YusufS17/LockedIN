# Phase 2: Room & Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 2-room-contract
**Areas discussed:** Entry & 18+ gate flow, Contract screen layout, Bot join/accept choreography, Freeze moment + room visual

---

## Entry & 18+ gate flow

User selected this area but explicitly down-prioritised the 18+ gate ("idc about the 18+ thing too much for demo purpose").

**User's choice:** Simple home screen with the single £5 preset tile (Claude default, accepted); 18+ gate kept minimal — one-tap confirm, no ceremony.
**Notes:** Gate must exist for SAFE/STK-05 and stay honest, but gets no extra build. In-memory confirmation flag, no persistence. → CONTEXT D-13, D-14.

---

## Contract screen layout

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped Pass vs Fail | Two sections — "KEEPS YOUR £5" / "LOSES YOUR £5" — stake + forfeit summary up top. Hardest consequence framing. | ✓ |
| Single scrollable term list | All 6 terms as rows, stake/forfeit pinned. Simplest, less dramatic. | |
| Card deck | One term per card, swipe/scroll. Most playful, higher cost. | |

**User's choice:** Grouped Pass vs Fail.
**Notes:** Serves core value (stake must feel real). All 6 CTR-02 terms distributed across the two groups. → CONTEXT D-15.

---

## Bot join/accept choreography

| Option | Description | Selected |
|--------|-------------|----------|
| Deliberate & suspenseful | ~2s/bot, joining→accepted, tally ticks £5→£10→£15→£20. | ✓ |
| Snappy cascade | ~0.8s each, quick succession. | |
| All at once | Bots accept near-simultaneously after user. | |

**User's choice:** Deliberate & suspenseful.
**Notes:** Order: user first, then Maya, Leo, Sam. Driven by `Task.sleep`. Makes the £20 header land with weight. → CONTEXT D-17, D-18.

---

## Freeze moment + room visual

| Option | Description | Selected |
|--------|-------------|----------|
| Room: defer to Phase 3 | Phase 2 = contract + roster (pixel portraits); full isometric room debuts Phase 3. | ✓ |
| Room: static backdrop now | Pixel room as still background. | |
| Room: full room in Phase 2 | Build animated room now (high cost). | |
| Freeze: satisfying animation | Dim+disable, lock snap, seal/shake + haptic. | ✓ |
| Freeze: simple lock + disabled | Icon + greyed fields, minimal. | |

**User's choice:** Defer room to Phase 3 + satisfying freeze animation.
**Notes:** Protects 5h budget; room built once in Phase 3, reused later. Freeze is a core "feels real" beat. Immutability enforced by Phase 1's frozen `CommitmentContract`. → CONTEXT D-19, D-20.

---

## Claude's Discretion

- Exact copy/wording for term rows, buttons, freeze caption.
- Concrete contract term values (25 min · 1×5-min break · ≤3 distractions · leave-early forfeits · £5 · British Red Cross) — D-16.
- Avatar/pixel-portrait style for the roster (lightweight).
- Visual styling within Phase 1 `Theme` tokens and playful tone.

## Deferred Ideas

- Cozy isometric pixel-art room with avatars at desks → Phase 3.
- Richer bot personalities (banter, Sam cracking) → Phases 3–5.
- Multiple rooms / real lobby / custom contracts / friend invites → future milestone.
- Elaborate age verification → out of hackathon scope.
- Persisting 18+ confirmation / room state → not needed (session stays in-memory).
