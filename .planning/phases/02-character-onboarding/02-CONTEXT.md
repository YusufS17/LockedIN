# Phase 2: Character & Onboarding - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

The **first-run experience and the visual rendering foundation**: a polished, animated onboarding flow + a pixel-art-style character creator, plus the **reusable avatar component and cozy isometric study-room view** that every later screen (Phase 3 roster, Phase 4 session HUD, Phase 7 world) reuses. This is the user's flagged top-priority phase — rooms and the character onboarding must feel nice.

In scope: first-launch onboarding sequence (animated) · mix-and-match character creator with live preview · reusable avatar component (with hooks for later participant states) · reusable cozy isometric room view · display-name capture · local persistence of the chosen character + name.

Out of scope (defer): real friends/multiplayer, the Squad/District/world-building system and build-voting (v2 "World"), the coin shop / room-item customisation slots (v2), avatars animating at desks during a live session (Phase 4), the contract/stake flow (Phase 3).
</domain>

<decisions>
## Implementation Decisions

### Visual fidelity & rendering approach
- **D-21:** Fidelity = **hybrid, implemented as LAYERED pre-rendered art**. The avatar is composed of separate transparent PNG part-layers (skin/base, hair, outfit, accessory) stacked in a SwiftUI `ZStack`, with code tinting for colour-accent variants, placed over a **code-built isometric room** (SwiftUI shapes/gradients in the warm dark-academia palette). This reconciles the user's two choices — "hybrid pre-rendered art" (real cozy-art feel) + "mix-and-match layers" (independent skin/hair/outfit/accent). Medium risk acknowledged: part-layers must align on a common canvas.
- **D-21a (FALLBACK — important):** If sourcing/generating aligned pixel-art part-layers proves too slow during execution, **degrade gracefully to SwiftUI-native drawn shape layers** using the same compositing structure and the same `Theme` palette — no external assets. The avatar component's API stays identical either way, so the rest of the phase (creator, onboarding, room) is unaffected. The phase must never stall on art sourcing.
- **D-21b:** Bound the asset work for MVP: ~**3–4 options per layer** (e.g. 3–4 hair, 3–4 outfits) + a small accent-colour set. Enough to feel personal, small enough to ship.

### Character creator
- **D-22:** Creator = **mix-and-match layers** — skin tone, hair, outfit, colour accent — with a **live preview** that updates on every change. Uses the exact same avatar component that renders everywhere else (no separate "preview" renderer).
- **D-23:** The avatar component is the **single reusable representation** across home, Phase 3 roster, Phase 4 session room, and Phase 7 world. It is built with **status-state hooks** (idle now; focused / deep-focus / on-break / distracted / finished later) and uses **non-colour-only status cues** (icon/shape/label in addition to colour) for accessibility — per the world-prompt's avatar-state guidance.

### Onboarding flow & animation
- **D-24:** Flow = **3 beats: Concept → Create → Land in room.** (1) a short animated intro to the LockedIN commitment idea ("Stake it. Lock in. Win it back." — stake → lock in → reveal), (2) character creation, (3) reveal in the cozy room. Teaches the product AND builds identity before the contract phase.
- **D-25:** Onboarding is **animated, not static screens** (ONB-01): animate beat transitions, the intro motion, and especially the avatar "coming to life" / settling into the room at the payoff. Use SwiftUI animations; **respect Reduce Motion** (provide a calm fallback). Keep it performant on the demo device.

### Payoff & identity
- **D-26:** Payoff = the finished avatar **revealed in the cozy room** ("Meet [name]") AND **capture a display name**. The name is reused in the Phase 3 roster and the Phase 6 reveal titles.
- **D-27:** Onboarding shows on **first launch only**; the chosen character + display name **persist locally** across relaunch (ONB-04). Persistence here is allowed (it's identity/world data, not the commitment session, which stays in-memory — per PROJECT constraints). Mechanism (UserDefaults vs SwiftData) is the planner's call — lightweight. Provide a small "edit character" entry point later; full room-item customisation (slots) stays in v2.
- **D-28:** The **cozy isometric room view established here is the reusable surface** for Phase 3 (contract/roster can sit against it), Phase 4 (session HUD animates it), and Phase 7 (world grows it). Build it **once, lean** — later phases reuse, not rebuild.

### Claude's Discretion
- Exact copy/wording for the intro beats, buttons, and the "Meet [name]" payoff.
- Exact part-layer option set, character art style specifics, and accent palette (within `Theme` / dark-academia).
- Animation timings and the Reduce-Motion fallback behaviour.
- Local-persistence mechanism (UserDefaults vs SwiftData) and where character config attaches (e.g. on the `Participant`/user model).
- Default character (so a "skip" still yields a valid avatar).
- Whether the avatar part-layers are AI-generated vs hand-picked from a free/licensed pack — provided licensing is clean; otherwise use the D-21a code-drawn fallback.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & phase scope
- `.planning/ROADMAP.md` §"Phase 2: Character & Onboarding" — goal, 5 success criteria
- `.planning/REQUIREMENTS.md` — ONB-01, ONB-02, ONB-03, ONB-04, ONB-05 (full text)
- `.planning/PROJECT.md` §"Visual Direction" + §"Active" (character-onboarding + reusable room/avatar bullets are top priority)

### Visual reference
- `.planning/reference/study-room-mockup.png` — the cozy isometric study-room aesthetic the room view + character style should evoke (warm dark-academia, amber light, pixel-art cozy-game feel)
- `.planning/reference/world-layer-prompt.md` §2 — avatar-state behaviours (focused/deep-focus/break/distracted/finished) + accessibility (not colour-only); informs the ONB-03 state hooks even though the world system itself is v2

### Carried-forward decisions (Phase 1)
- `.planning/phases/01-foundation/01-CONTEXT.md` — D-04/05 (playful tone, no dark patterns), D-06 (design tokens established)
- `.planning/phases/01-foundation/01-SUMMARY.md` — what exists: `Theme`, `AppStore` (@Observable, `.environment()`), `RootView` (walking skeleton to replace), `Participant` model, `MoneyLabel`

### Build conventions
- `CLAUDE.md` — iOS 17, SwiftUI, `@Observable`, no SPM deps, Swift 5 mode; persistence allowed for world/identity only; playful but honest UX

No external (third-party) specs — requirements fully captured above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LockedIN/Design/Theme.swift` — design tokens (palette, type, spacing) from Phase 1; extend with the avatar/room palette rather than inventing new colours.
- `LockedIN/App/AppStore.swift` — `@Observable` root store; add the user's character config + display name here (observed by onboarding, home, later roster).
- `LockedIN/App/RootView.swift` — the walking-skeleton screen; **replaced** by the onboarding-or-home routing (first launch → onboarding; thereafter → home).
- `LockedIN/App/LockedINApp.swift` — `.environment(appStore)` wiring at `WindowGroup` root; keep intact.
- `LockedIN/Models/Participant.swift` — natural home for an avatar/appearance descriptor reused by bots (Maya/Leo/Sam get seeded appearances too).

### Established Patterns
- `@Observable` + `.environment()` for shared state; `NavigationStack`/`NavigationPath` for flow (onboarding beats → home).
- SwiftUI-native rendering preferred (Phase 1 built everything in code); the D-21 hybrid adds image part-layers on top of that, with the D-21a code-drawn fallback keeping the all-SwiftUI option open.

### Integration Points
- First-launch gate: `AppStore` (or a persisted flag) decides onboarding vs home.
- The avatar component + room view created here are consumed by Phase 3 (roster/contract) and Phase 4 (session) — design their public API for reuse from the start.
</code_context>

<specifics>
## Specific Ideas

- Intro framing line: "Stake it. Lock in. Win it back." (stake → lock in → reveal) — 3-beat concept teaser.
- Payoff: "Meet [name] —" with the finished avatar shown in the cozy room.
- Creator controls (live preview): skin ◀▶ · hair ◀▶ · outfit ◀▶ · accent ◀▶.
- Avatar must carry non-colour status cues from day one so later session states are accessible.
</specifics>

<deferred>
## Deferred Ideas

- **Room-item customisation** (fixed slots: desk/chair/lamp/rug/etc., colour variants, save) — v2 "World" / coin shop; NOT this phase (this phase establishes the room *view*, not an editor).
- **Squad rooms, district, build-voting, Focus XP** — v2 "World".
- **Avatar animating at desks** (typing/break/distracted poses) during a live session — Phase 4.
- **Richer accessory/vibe sets, more part options** — post-MVP polish if time allows.
- **Editing/replaying the character later** — a light entry point is in scope (D-27); a full re-customisation UI is post-MVP.

None pulled into Phase 2 scope — discussion stayed within onboarding + character + render-foundation.
</deferred>

---

*Phase: 2-character-onboarding*
*Context gathered: 2026-06-13*
