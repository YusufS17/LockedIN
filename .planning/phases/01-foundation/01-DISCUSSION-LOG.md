# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 1-Foundation
**Areas discussed:** TEST MODE treatment, Design system tone, Money display format, Mock/demo seed defaults (wallet + forfeit destination)

---

## TEST MODE treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Banner + inline badge | Persistent top strip AND a TEST tag on each amount | |
| Top banner only | One bold persistent strip; clean amounts | |
| Inline badge per amount | TEST marker travels with every £ figure, no banner | ✓ |

**User's choice:** Inline badge per amount
**Notes:** Interpreted as: funnel all £ rendering through one `MoneyLabel` component that always carries the marker, making money-without-warning structurally impossible — the cleanest guarantee for SAFE-01.

---

## Design system tone

| Option | Description | Selected |
|--------|-------------|----------|
| Serious commit, playful reveal | Premium fintech during commit/session, playful at reveal | |
| Playful throughout | Bright, game-y energy on every screen | ✓ |
| Strictly serious/minimal | Restrained fintech minimalism end-to-end | |

**User's choice:** Playful throughout
**Notes:** Foundational mood for all 6 phases. Constrained by core value (the £5 stake must still feel real) and SAFE (honest UX, no dark patterns / gimmick punishments).

---

## Money display format

| Option | Description | Selected |
|--------|-------------|----------|
| Always 2 decimals (£5.00) | Two decimal places always; reads as real money | ✓ |
| Trim whole amounts (£5) | £5 for whole pounds, £5.50 when needed | |

**User's choice:** Always 2 decimals (£5.00)

---

## Mock/demo seed defaults — wallet

| Option | Description | Selected |
|--------|-------------|----------|
| £20.00 | Tight; stake feels consequential | ✓ |
| £50.00 | Comfortable cushion | |
| £100.00 | Generous; stake feels small | |

**User's choice:** £20.00 (2000 pence)

---

## Mock/demo seed defaults — forfeit destination

| Option | Description | Selected |
|--------|-------------|----------|
| A named charity | e.g. "British Red Cross" | ✓ (Claude's discretion) |
| Generic 'Charity pot' | Neutral label, no specific org | |
| Room prize pool (split among passers) | Deferred — behind ENABLE_ROOM_PRIZE_POOL=false | |

**User's choice:** Deferred to Claude ("you decide"). Defaulted to named charity "British Red Cross".
**Notes:** User initially paused, unsure whether the workflow was producing a mock *video*. Clarified that "mock" = simulated service code (no real payments/networking), not a video, and that this step only produces a CONTEXT.md planning file. User then delegated the forfeit-destination choice.

---

## Claude's Discretion

- Forfeit-destination charity name → defaulted to "British Red Cross".
- Exact short-form wording of the inline TEST marker (full "NO REAL MONEY WILL MOVE" statement must stay reachable).
- Concrete design tokens (palette, type scale) under the "playful throughout" direction.
- Internal module layout — follow CLAUDE.md (`AppStore` + `SessionStore`/`WalletStore`/`RoomStore` via `.environment()`).

## Deferred Ideas

- Room prize pool as a forfeit destination — gated behind `ENABLE_ROOM_PRIZE_POOL=false`; v2 (STAKE-02). Not for the demo.
- Real `StripeCommitmentService` / real Screen Time `FocusControlAdapter` behind the same protocols — v2 (PAY-01/02, REAL-01/02).
