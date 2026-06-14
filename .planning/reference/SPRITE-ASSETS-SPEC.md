# Sprite Assets Spec — what to generate, exactly

The app is now **asset-driven**: drop these PNGs into `LockedIN/Assets.xcassets` (as imagesets,
or hand them to me and I'll add them) and the real sprites appear everywhere automatically.
Until a sprite exists, the app falls back to a code-drawn avatar — so nothing breaks while you generate them.

> Generate these with your image tool (the one that made the mockups) in the **same cozy
> pixel-art style**. The single most important requirement: **transparent background** and
> **consistent canvas size / foot position** across all of them.

## 1. Characters (8) — REQUIRED for the gallery + everywhere

Full-body, front-facing, standing, **transparent background**, square canvas (e.g. 512×512),
character centred, feet near the bottom. One PNG each:

| Asset name | Vibe (match the avatar-grid mockup) |
|------------|--------------------------------------|
| `char_maya` | warm, tidy, focused (blue top) |
| `char_leo`  | relaxed hoodie guy |
| `char_sam`  | dark-hair, black outfit (the "selected" one in the mockup) |
| `char_ada`  | curly dark hair, academic |
| `char_noah` | dark skin, short hair, hoodie |
| `char_iris` | blonde, long hair, smart |
| `char_kai`  | tied-back hair, casual |
| `char_mei`  | long brown hair, academic |

(Names are flexible — keep the 8 asset filenames exactly as above so they wire up.)

## 2. Character state poses (optional but great for the live session)

Same character, same canvas/foot position, **transparent**, one per state. Naming convention is
`<char>_<state>`. If a pose is missing the app uses the base sprite, so these are incremental.

For each character you want animated in the room, add any of:
- `char_maya_focused`   — typing / reading / heads-down
- `char_maya_break`     — standing / stretching / holding a drink
- `char_maya_distracted`— looking at phone
- `char_maya_finished`  — standing / small celebration
- `char_maya_deepfocus` — headphones on (optional)

(Start with just **Sam's** poses if you want the demo's "Sam cracks" beat to animate — `char_sam_focused`, `char_sam_distracted` are the high-value two.)

## 3. Rooms / scenes (optional — we can keep using your scene PNGs as backdrops)

If you want cleaner room compositing later:
- `room_solo`   — isometric personal study room, transparent or full-bleed
- `room_group`  — isometric group study room

These aren't required for the core loop (we use the existing scene art as backdrops).

---

### Priority order (highest value first)
1. The **8 `char_*` base sprites** (transparent) → real gallery + avatars everywhere.
2. **`char_sam_focused` + `char_sam_distracted`** → the live-session "cracks" beat animates.
3. The rest of the state poses → fuller live room.
4. Room scenes → cleaner compositing.

Hand me the PNGs (or drop them in `Design images/` named as above) and I'll wire them in — no code changes needed on your side.
