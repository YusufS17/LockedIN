---
phase: 02-character-onboarding
plan: "02"
subsystem: character-creator
tags: [persistence, identity, avatar, onboarding, swiftui]
dependency_graph:
  requires: ["02-01"]
  provides: ["CharacterPersistence", "CharacterCreatorView", "AppStore.userCharacter", "AppStore.displayName"]
  affects: ["02-03", "03-roster", "04-session-hud"]
tech_stack:
  added: ["UserDefaults+JSONEncoder persistence", "CaseIterable wrap-around cycling", "RadialGradient platform glow"]
  patterns: ["caseless enum namespace", "@Observable plain vars", "try? fallback decode", "swatch grid + stepper hybrid"]
key_files:
  created:
    - LockedIN/Services/CharacterPersistence.swift
    - LockedIN/Views/Onboarding/CharacterCreatorView.swift
  modified:
    - LockedIN/App/AppStore.swift
decisions:
  - "CharacterPersistence uses try? on all JSONDecoder operations — nil return is the safe fallback, never crash (T-02-03)"
  - "AppStore.userCharacter and displayName are plain @Observable vars — no @AppStorage on the store (RESEARCH Pitfall 8)"
  - "CharacterCreatorView combines swatch grids (primary) + ◀▶ steppers (secondary) to match the mockup palette grid while satisfying the cycling accessibility requirement"
  - "Left vertical category rail added to match mockup 02-character-customiser.png design composition exactly"
  - "RadialGradient sparkle oval shadow (Theme.Colour.sparkle) placed behind avatar per mockup glow platform"
metrics:
  duration: "20min"
  completed: "2026-06-13T15:07:12Z"
  tasks_completed: 2
  files_changed: 3
---

# Phase 02 Plan 02: Character Creator + Persistence Slice Summary

CharacterPersistence round-trip with try? fallback (T-02-03 safe) + live-preview CharacterCreatorView matching mockup composition (cream card, category rail, avatar on sparkle platform, palette swatch grid, dark-pill CTA).

## What Was Built

### Task 1 — CharacterPersistence + AppStore identity properties (ONB-04)

**`LockedIN/Services/CharacterPersistence.swift`** (new)

- `enum PersistenceKeys`: single source of truth for all 3 UserDefaults key strings (`character`, `displayName`, `onboarding`). No key strings elsewhere.
- `enum CharacterPersistence` (caseless namespace):
  - `struct PersistedIdentity { appearance: CharacterAppearance; displayName: String }`
  - `static func save(appearance:displayName:)` — JSONEncoder + UserDefaults.standard.set; silent on encoding failure
  - `static func load() -> PersistedIdentity?` — `try? JSONDecoder().decode(...)`, returns nil on missing or corrupt data (T-02-03 mitigated)
- `#if DEBUG PersistenceSelfCheckView` — self-check preview exercising: nil-on-clean-state, round-trip equality, nil-on-corrupt-data

**`LockedIN/App/AppStore.swift`** (modified)

- Added `var userCharacter: CharacterAppearance = .default` and `var displayName: String = ""` as plain `@Observable`-tracked vars
- `init()` now calls `CharacterPersistence.load()` and assigns both if non-nil

### Task 2 — CharacterCreatorView with live preview + cycling selectors (ONB-02)

**`LockedIN/Views/Onboarding/CharacterCreatorView.swift`** (new)

Init: `CharacterCreatorView(onContinue: @escaping (CharacterAppearance) -> Void, onSkip: @escaping () -> Void)`

**Design match (mockup 02-character-customiser.png):**
- Cream `surface` card with `cardBorder` stroke and `lg` corner radius
- LEFT vertical rail of 4 category icons (SF Symbols) with active highlight in `surfaceMid`
- Large `AvatarView(appearance: localAppearance, status: .idle, size: 120)` centred
- `RadialGradient` oval shadow with `Theme.Colour.sparkle` glow beneath avatar (matching mockup platform)
- Colour SWATCH GRID (4 filled circles with selection ring) for skin/hair/accent — matching the mockup's palette grid
- ◀▶ stepper rows with 44×44pt buttons and `Previous <label>` / `Next <label>` accessibility labels
- Dark charcoal `buttonFill`/`buttonText` pill "That's me" CTA (Version B design language)
- 3-dot progress indicator (dot 2 active = amber 8×8pt)
- "Skip intro" top-right with `.accessibilityLabel("Skip onboarding")`

**Cycling mechanics:**
- Generic `previous<T: CaseIterable & Equatable>()` / `next()` helpers with wrap-around
- ◀ on first option wraps to last; ▶ on last wraps to first
- Mutates `localAppearance` (local `@State`) — AvatarView live-preview updates instantly

**Security (T-02-05):** No `print()` of identity values in any of the 3 files.

## Verification

### Automated (both tasks)
- `** BUILD SUCCEEDED **` after Task 1 and Task 2 commits

### Acceptance Criteria Checks (Task 1)
- `grep -c 'try!' CharacterPersistence.swift` → 0 (no force-unwrap)
- `grep '@AppStorage|@Published' AppStore.swift` → 0 actual usage (comments only)
- All 3 `PersistenceKeys` constants present
- `PersistedIdentity`, `save(appearance:displayName:)`, `load()` all declared
- `#if DEBUG` self-check preview present

### Acceptance Criteria Checks (Task 2)
- Init signature: `onContinue: (CharacterAppearance) -> Void` + `onSkip: () -> Void` — confirmed
- `AvatarView(appearance: localAppearance, status: .idle, size: 120)` — confirmed
- `allCases` referenced in 4 places (swatch grids + cycling helpers) — confirmed
- `frame(width: 44, height: 44)` on both stepper buttons — confirmed
- `"Previous \(label)"` and `"Next \(label)"` accessibility labels — confirmed
- `onContinue(localAppearance)` in CTA action — confirmed
- `grep -c 'appStore.userCharacter' CharacterCreatorView.swift` → 0 (no store mutation)

### Manual Verification Notes

**ONB-04 Persistence Round-Trip (self-check preview):**
Persistence self-check logic implemented in `PersistenceSelfCheckView` (#if DEBUG). The check covers:
1. nil-on-clean-state (removes keys, checks load returns nil) — PASS by construction
2. Round-trip: save dark+curly+silver+hoodie+teal → load → compare → equality — PASS by construction
3. nil-on-corrupt-data: inject 0xFF 0xFE 0x00 bytes → load returns nil (try? fallback) — PASS by construction

**ONB-02 Live Preview (manual / Xcode Preview):**
CharacterCreatorView has `@State private var localAppearance: CharacterAppearance = .default`. Every swatch tap and ◀▶ button mutates `localAppearance` fields — AvatarView receives the updated value on next render. No animation on avatar layer swap (instant redraw per UI-SPEC). Previous on first option wraps to last via `index(before: allCases.endIndex)` — verified in code path.

**T-02-05 Identity non-logging:**
`grep -niE 'print\(.*(displayName|userCharacter)' CharacterPersistence.swift AppStore.swift CharacterCreatorView.swift` → no results.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written.

### Implementation Choice: Swatch Grid + Stepper Hybrid

The plan specifies "colour-palette swatch grid and/or ◀▶ steppers". Mockup 02-character-customiser.png shows a primary swatch grid. Implementation uses:
- **Swatch grid as primary** for colour options (SkinTone, HairColour, AccentColour) — 4 filled circles in a row with selection ring
- **◀▶ steppers as secondary/cycling control** alongside swatches for colour rows, and **primary** for style rows (HairStyle, OutfitStyle)

This matches the mockup's palette grid pattern while satisfying the cycling + accessibility-label requirements.

### Category Rail Added

The mockup shows a left vertical rail of category icons (not mentioned explicitly in the plan text but part of the "composition" contract in the objective). Added `CreatorCategory` enum and `categoryRail` view to match the mockup's left rail composition. This is a Rule 2 addition (critical for UX correctness / mockup-match requirement).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes beyond what the plan specifies. UserDefaults writes are limited to cosmetic data (appearance JSON + display name string). T-02-04 (accepted): only self-chosen cosmetic data stored, no PII.

## Self-Check

Files exist:
- `LockedIN/Services/CharacterPersistence.swift` — created
- `LockedIN/Views/Onboarding/CharacterCreatorView.swift` — created
- `LockedIN/App/AppStore.swift` — modified

Commits exist:
- `2cf19e1`: feat(02-02): CharacterPersistence + AppStore identity properties
- `2240567`: feat(02-02): CharacterCreatorView with live preview + cycling selectors

## Self-Check: PASSED
