# Phase 2: Character & Onboarding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 2-character-onboarding
**Areas discussed:** Visual fidelity vs build cost, Character creator depth & style, Onboarding flow & animation, Onboarding payoff + display name

---

## Visual fidelity vs build cost

| Option | Description | Selected |
|--------|-------------|----------|
| SwiftUI-native stylized | All code, no assets, reliable; not literal pixel-art | |
| Real pixel-art sprite assets | True pixel look matching mockup; high risk (sourcing/licensing) | |
| Hybrid: pre-rendered art + code room | Real art feel, code-built room, medium risk | ✓ |

**User's choice:** Hybrid.
**Notes:** Reconciled with the mix-and-match choice below → implemented as *layered* pre-rendered PNG parts composited in code over a code-built room (D-21), with a graceful fallback to code-drawn shape layers if asset generation stalls (D-21a). Asset work bounded to ~3–4 options/layer (D-21b).

---

## Character creator depth & style

| Option | Description | Selected |
|--------|-------------|----------|
| Mix-and-match layers | skin/hair/outfit/accent + live preview | ✓ |
| Pick-one presets | ~6–8 ready-made characters | |
| Layers + accessory/vibe | fuller layer set, more build/art | |

**User's choice:** Mix-and-match layers.
**Notes:** Live preview uses the same reusable avatar component rendered everywhere (D-22, D-23). → D-22.

---

## Onboarding flow & animation

| Option | Description | Selected |
|--------|-------------|----------|
| Concept → create → land in room | 3 beats; teaches commitment idea + builds identity | ✓ |
| Create first → quick how-it-works | identity first | |
| Minimal: welcome + create | shortest, skips concept | |

**User's choice:** Concept → create → land in room.
**Notes:** Animated, not static; respect Reduce Motion (D-24, D-25). Intro framing "Stake it. Lock in. Win it back."

---

## Onboarding payoff + display name

| Option | Description | Selected |
|--------|-------------|----------|
| Avatar in room + display name | reveal in cozy room + capture name | ✓ |
| Avatar reveal only (auto name) | no name step | |
| Name first, simple reveal | name + modest reveal | |

**User's choice:** Avatar in room + display name.
**Notes:** Name reused in Phase 3 roster + Phase 6 reveal titles; character + name persist locally, first-launch-only onboarding (D-26, D-27).

## Claude's Discretion

- Copy/wording, exact part-layer options + palette, animation timings + Reduce-Motion fallback, persistence mechanism (UserDefaults vs SwiftData), default character, AI-generated vs licensed art (clean licensing required, else code-drawn fallback).

## Deferred Ideas

- Room-item customisation slots/editor, Squad/District/build-voting/Focus XP → v2 "World".
- Avatar desk animations during a session → Phase 4.
- Richer accessory sets / full re-customisation UI → post-MVP.
