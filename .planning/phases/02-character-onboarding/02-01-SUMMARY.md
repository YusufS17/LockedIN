---
phase: 02-character-onboarding
plan: "01"
subsystem: rendering-foundation
tags: [avatar, isometric-room, theme, models, swiftui, d21a, onb-02, onb-03, onb-05]
dependency_graph:
  requires: [01-foundation]
  provides: [CharacterAppearance, AvatarStatus, AvatarView, IsometricRoomView, Theme.avatar-palette]
  affects: [02-02-character-creator, 02-03-onboarding-payoff-home, phase-03, phase-04, phase-07]
tech_stack:
  added: []
  patterns: [SwiftUI ZStack layer compositing (D-21a), Path-based isometric parallelograms (D-28), CaseIterable enum cycling]
key_files:
  created:
    - LockedIN/Models/CharacterAppearance.swift
    - LockedIN/Models/AvatarStatus.swift
    - LockedIN/Views/Components/AvatarView.swift
    - LockedIN/Views/Components/IsometricRoomView.swift
  modified:
    - LockedIN/Design/Theme.swift
decisions:
  - "D-21a chosen over D-21 (PNG layers): code-drawn shape layers built first per RESEARCH recommendation; API unchanged if PNG upgrade applied later"
  - "Avatar desk slot convention: callers position AvatarView at (width * 0.50, height * 0.58) over IsometricRoomView in their own ZStack"
  - "AvatarBodyLayer uses VStack(head-circle + body-rounded-rect) aligned .bottom so sizes scale cleanly at 120/80/48/40"
  - "Triangle Shape helper introduced for academic jacket collar lapels"
metrics:
  duration: "~10 min"
  completed: "2026-06-13T14:47:27Z"
  tasks_completed: 3
  files_changed: 5
---

# Phase 02 Plan 01: Rendering Foundation Summary

**One-liner:** Code-drawn ZStack avatar (AvatarBodyLayer/HairLayer/OutfitLayer/StatusOverlay) + isometric study room (Path parallelograms + SwiftUI gradients) with Theme palette extended by 14 new colour tokens.

---

## Tasks Completed

| # | Task | Commit | Key files |
|---|------|--------|-----------|
| 1 | Extend Theme + add CharacterAppearance and AvatarStatus models | cba6acc | Theme.swift, CharacterAppearance.swift, AvatarStatus.swift |
| 2 | Build AvatarView (code-drawn, D-21a) with status overlay + previews | dc12914 | AvatarView.swift |
| 3 | Build IsometricRoomView (static cozy room, D-28) with previews | 6dd6b8a | IsometricRoomView.swift |

---

## What Was Built

### Task 1 — Theme + Models

**Theme.swift (extended):**
- 14 new `Theme.Colour` tokens: skin (4), hair (4), avatar accent (3 — amber reuses `Theme.Colour.accent`), room (`plantGreen`, `windowSlate`)
- `TypeScale.headline` and `TypeScale.captionBold` changed from `.semibold` → `.bold` (two-weight rule per UI-SPEC)
- `title2` (.semibold) and `callout` (.medium) left untouched as required

**CharacterAppearance.swift:**
- `struct CharacterAppearance: Codable, Equatable` with 5 fields (skinTone, hairStyle, hairColour, outfitStyle, accentColour)
- 5 option enums: `SkinTone`, `HairStyle`, `HairColour`, `OutfitStyle`, `AccentColour` — all `String, Codable, CaseIterable` with `displayName`
- Static constants: `.default` (medium/short/brown/casual/amber), `.maya` (dark/long/black/academic/teal), `.leo` (light/short/blonde/hoodie/lavender), `.sam` (medium/tied/brown/smart/rose)
- VoiceOver `description` extension: "{Skin} skin, {HairStyle} {HairColour} hair, {Outfit} outfit"
- Color mapping extensions: `SkinTone.colour`, `HairColour.colour`, `AccentColour.colour` → Theme tokens

**AvatarStatus.swift:**
- `enum AvatarStatus: String, Equatable` with 6 cases: idle/focused/deepFocus/onBreak/distracted/finished
- `var label: String` (Idle/Focused/Deep/Break/!/Done)
- `var symbolName: String?` (nil for idle; SF Symbol names for active states)
- `var ringColour: Color` (clear for idle; accent/accentTeal/textSecondary/forfeitRed/moneyGreen for active)

### Task 2 — AvatarView (D-21a)

**Public API** (fixed contract, consumed by 02-02/02-03/Phase 3/4/7):
```swift
AvatarView(appearance: CharacterAppearance, status: AvatarStatus, size: CGFloat = 80)
```

**Layers (ZStack bottomTrailing):**
- `AvatarBodyLayer`: VStack with Circle (head, 45% size) + RoundedRectangle (body, 50% × 30%) filled with `skinTone.colour`
- `AvatarHairLayer`: 4 visually distinct styles — short (flat Ellipse cap), curly (3-circle puff), long (cap + side panel rects), tied (cap + bun circle)
- `AvatarOutfitLayer`: 4 visually distinct styles — casual (solid rounded rect), academic (rect + Triangle collar lapels), hoodie (wide rect + hood Capsule), smart (fitted rect + accent tie)
- `AvatarStatusOverlay`: `size * 0.28` Circle with `status.ringColour` + `status.symbolName` SF Symbol; offset `Theme.Spacing.xs` inward; `accessibilityHidden(true)`

**Accessibility:** Root `.accessibilityElement(children: .ignore)` + `.accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")`

**Previews (3 blocks):** Default at size 120; all 4 accent/outfit variants side-by-side; all 6 AvatarStatus cases in two rows.

### Task 3 — IsometricRoomView (D-28)

**Public API** (parameterless — Phase 4 adds participant overlay externally):
```swift
IsometricRoomView()
```

**Geometry:** `GeometryReader` + `ZStack`, back-to-front draw order:
1. `RightWallShape` — flat `Theme.Colour.surface` (shadow side)
2. `LeftWallShape` — `LinearGradient(surfaceMid→surface, topLeading→bottomTrailing)` (ambient light side)
3. `FloorShape` — `LinearGradient(background→surfaceMid, top→bottom)` (warm wood-plank feel)
4. `RoomFurnitureLayer` — code-drawn furniture using `RoundedRectangle`/`Ellipse`/`Rectangle`/`Capsule`

**Furniture (all code-drawn, no external assets):**
- Window: `windowSlate` panel + `accentSoft` glow at 0.15 opacity + crossframe dividers
- Bookshelf: `surface` body + 5 book spines in `accent`/`accentSoft`/`accentTeal`/`accentRose`/`accentLavender`
- Desk: `surfaceMid` top surface + `surface` front face
- Lamp: `accentSoft` glow circle at 40% opacity + `textSecondary` stand + base Capsule
- Plant: 3 `plantGreen` Ellipse leaves + `surfaceMid` pot

**Avatar desk slot:** Callers position `AvatarView` at `(width * 0.50, height * 0.58)` in their own ZStack overlay.

**Previews (2 blocks):** Full-screen room; room with `AvatarView(.default, .idle, 80)` at desk slot.

---

## Deviations from Plan

None — plan executed exactly as written.

D-21a (code-drawn shape layers) was used as the primary path per RESEARCH recommendation. This is the execution default, not a fallback.

---

## Manual Verification Notes (ONB-03, ONB-05)

**ONB-03 status cues (AvatarView):** AvatarView preview shows all 6 status cases. For each non-idle state, the badge combines:
- A ring colour (different for each state)
- An SF Symbol icon unique to that state (lock.fill, bolt.fill, cup.and.saucer.fill, exclamationmark.triangle.fill, checkmark.circle.fill)
This satisfies the non-colour-only accessibility requirement.

**ONB-05 isometric room (IsometricRoomView):** Preview "Room with avatar at desk slot" shows:
- A recognizable warm isometric room with left wall (lighter gradient), right wall (darker), and floor rhombus
- Desk centred-left on the floor with lamp and bookshelf on the left wall
- Plant in the right corner; window panel on the left wall
- Default avatar positioned at the desk via the (50%, 58%) caller-composition pattern

---

## D-21a Shape Decisions

| Layer | Approach | Notes |
|-------|----------|-------|
| Body | VStack(Circle + RoundedRectangle) aligned .bottom | Head 45% size, body 50% × 30%; scales cleanly at all sizes |
| Hair: short | Flat Ellipse cap offset upward | Minimal, reads as "short" |
| Hair: curly | 3 overlapping circles | Width variation gives puff silhouette |
| Hair: long | Cap Ellipse + two side-panel RoundedRects | Panels hang past shoulder level |
| Hair: tied | Ellipse cap + small offset Circle bun | Bun at top-right of head |
| Outfit: casual | Simple RoundedRectangle | Plain tee shape |
| Outfit: academic | RoundedRectangle + 2 Triangle collar lapels | Triangle Shape helper added (not in original plan) |
| Outfit: hoodie | Wide RoundedRectangle + Capsule hood nub | Hood bump at top |
| Outfit: smart | Narrow RoundedRectangle + small tie rect | Tie in accent gold |

**Triangle Shape helper:** A private `Triangle: Shape` was added to `AvatarView.swift` to draw the academic jacket collar lapels. This is a sub-5-line SwiftUI shape, not an external dependency. Tracked as an additive micro-decision within D-21a discretion.

---

## Known Stubs

None — all components are functional and renderable. No data is hardcoded as empty/placeholder. AvatarView renders appearance-driven content; IsometricRoomView draws all furniture explicitly.

---

## Threat Surface Scan

No new security-relevant surface introduced. This plan is pure in-memory rendering: no network endpoints, no auth paths, no file access, no schema changes at trust boundaries. Consistent with plan's threat model (T-02-02 accept, T-02-SC accept).

---

## Self-Check

Files created:
- LockedIN/Models/CharacterAppearance.swift — FOUND (committed cba6acc)
- LockedIN/Models/AvatarStatus.swift — FOUND (committed cba6acc)
- LockedIN/Views/Components/AvatarView.swift — FOUND (committed dc12914)
- LockedIN/Views/Components/IsometricRoomView.swift — FOUND (committed 6dd6b8a)
- LockedIN/Design/Theme.swift (modified) — FOUND (committed cba6acc)

Build gate: xcodebuild ended `** BUILD SUCCEEDED **` after each task and final verification.

## Self-Check: PASSED
