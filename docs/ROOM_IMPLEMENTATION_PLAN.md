# Room System — Implementation Plan & Gap Analysis

_Adapting the (web-oriented) room directive to our actual stack: **native iOS / SwiftUI,
code-drawn pixel art, no PNG assets, `@Observable` state, on-device persistence**. Web-only
items (`image-rendering: pixelated`, `.ts` types, `src/features/` tree, DOM layers) are
mapped to their SwiftUI equivalents; they are not adopted literally._

## Audit — what already exists (do not rebuild)

| Capability | Where | State |
|---|---|---|
| Cosy isometric room, code-drawn | `Views/Components/IsometricRoomView.swift` | ✅ now variant-driven (floor/wall/desk/chair/lamp/rug/shelf/plant/poster/window) |
| Live study room w/ placed avatars | `Views/LiveSessionView.swift` | ✅ 4 desk slots, status pills, timer, stat tiles, participant list, toolbar |
| Avatar states | `Models/AvatarStatus.swift` + `PixelAvatarView` | ✅ idle/focused/deepFocus/onBreak/distracted/finished, status-driven faces |
| Idle animation | `SpriteAvatarView` breathing | ✅ per-status, reduce-motion gated |
| Replaceable furniture slots | `PersonalRoomBuilderView` + `WorldStore` RoomCustomisationService | ✅ 10 slots, coin-gated, persisted |
| World-progress (district) | `WorldView`, `WorldStore`, `SettlementResultsView` | ✅ buildings, XP, level — but only OUTSIDE the live room |
| Seeded demo choreography | `LiveSessionView.applyChoreography` | ✅ crackers flip to distracted at crack moment |
| Reward economy | `Progression`, `RewardRules` | ✅ quality-weighted, deterministic |

## Gaps to close in THIS slice (the live room is the priority surface)

1. **Compact group-status summary** — "N focused · N break · N distracted" collapsed bar
   (replaces the three stat tiles; folds break/distraction counts in).
2. **Expandable participant panel** — a bottom sheet with per-participant detail cards
   (focused minutes, distractions, warnings remaining, status). Keeps the room uncluttered.
3. **In-room world-progress object** — a "what this room is building" board pinned on the
   room scene: active building, % to next, XP earned this session. Real `WorldStore` data.
4. **Break-corner transition** — a visible break area in the room; the user's avatar walks
   to it on an approved break (re-slotted), status → On break.
5. **Room promoted to hero** — the scene fills the screen (not a 240pt card sandwiched in a
   dashboard), header/status float as compact chrome.
6. **Richer header** — room name + mode (Supportive/Competitive) + "N / M still LockedIN".

## Out of scope (deferred / mocked — documented)

- **Multiplayer** is simulated (scripted bots) — CLAUDE.md constraint. Labelled in UI copy.
- **Native focus detection** is mocked (`MockFocusControlAdapter`) — no Screen Time entitlement.
- **Real payments** — `MockCommitmentService`, TEST MODE marker everywhere.
- **Full freeform room editing / drag-drop** — fixed slots only (per directive MVP).
- **Themes** — one cohesive theme shipped; furniture is data-driven so themes can follow.
- **Asset manifest / PNG pipeline** — N/A: art is code-drawn in SwiftUI `Canvas`/`Path`.
  When `char_*.png` / room PNGs arrive they slot in via `SpriteAvatarView` (no code change).
- **Disconnected / explicit warning states** — visual states exist as colour+label; the
  warnings-remaining count is surfaced in the participant panel.

## Render layering (SwiftUI ZStack order, back→front)

floor → walls → rug → back-wall furniture (window/poster/shelf) → desks → chairs →
avatars → desk objects (lamp) → break corner → world-progress board → status pills → UI.

## Definition of done (this slice)

Room feels like a game environment, 4 avatars sit naturally, states are instantly readable,
timer + room info stay legible, one furniture item replaceable, break & distracted states
visibly change the scene, world progress shows inside the room, builds clean, runs on iPhone.
