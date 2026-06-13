---
phase: "02-character-onboarding"
plan: "03"
subsystem: "Onboarding Flow + Routing"
tags: ["onboarding", "navigation", "animation", "persistence", "home", "routing"]
dependency_graph:
  requires: ["02-01", "02-02"]
  provides: ["OnboardingView", "ConceptBeatView", "PayoffBeatView", "FirstRoomBeatView", "HomeView", "RootView-gate"]
  affects: ["Phase 3 home → room setup navigation", "Phase 4 session home"]
tech_stack:
  added:
    - "PhaseAnimator (iOS 17) — avatar entrance in PayoffBeatView"
    - "@AppStorage(PersistenceKeys.onboarding) in View — first-launch gate"
    - "Task.sleep stagger — ConceptBeatView value-prop row animation"
    - ".asymmetric transition + explicit .zIndex — ZStack beat transitions"
    - "LinearGradient overlays — home greeting + payoff foreground"
    - "RadialGradient glow platform — PayoffBeatView gold sparkle"
  patterns:
    - "4-beat state machine (welcome/create/payoff/firstRoom) via enum OnboardingBeat"
    - "draftAppearance carried from .create → .payoff → .firstRoom via @State"
    - "Completion delegation — PayoffBeatView calls onComplete(name), OnboardingView writes AppStore + persistence + flag"
    - "beatTransition: .asymmetric slide+opacity (full) / .opacity (Reduce Motion)"
key_files:
  created:
    - "LockedIN/Views/Onboarding/OnboardingView.swift"
    - "LockedIN/Views/Onboarding/ConceptBeatView.swift"
    - "LockedIN/Views/Onboarding/PayoffBeatView.swift"
    - "LockedIN/Views/Onboarding/FirstRoomBeatView.swift"
    - "LockedIN/Views/HomeView.swift"
  modified:
    - "LockedIN/App/RootView.swift (walking-skeleton replaced with first-launch gate)"
decisions:
  - "4 beats instead of 3: added FirstRoomBeatView matching mockup 04-first-room.png per design_match priority directive — bridges payoff → home with the isometric room + avatar"
  - "PayoffBeatView design: cream background + gold glow platform (not IsometricRoomView background) — matches mockup 03-avatar-reveal-name.png (design_match priority takes precedence)"
  - "ConceptBeatView reframed: value-prop rows (Join/Focus/Build) + world scene illustration matching mockup 06-welcome-valueprops.png, not the locked lines"
  - "CONFIRM pill (dark charcoal) in PayoffBeatView per mockup, not amber — locked-in action design language"
  - "CharacterPersistence.save + hasCompletedOnboarding written on .payoff onComplete, not in FirstRoomBeatView — ensures data is committed before room reveal"
  - "start-a-room CTA: Phase 3 placeholder navigation, amber pill"
metrics:
  duration: "~45 minutes"
  completed: "2026-06-13"
  tasks_completed: 3
  files_count: 6
---

# Phase 02 Plan 03: Onboarding Flow + Routing Summary

**One-liner:** 4-beat animated onboarding (Welcome value-props → Character Creator → Avatar Reveal + name capture → First Room arrival) with first-launch routing gate, Reduce Motion fallbacks, and persistent identity across relaunch.

## What Was Built

### Task 1: OnboardingView 4-beat state machine + ConceptBeatView welcome screen

**OnboardingView** (`LockedIN/Views/Onboarding/OnboardingView.swift`):
- `enum OnboardingBeat: Int { case welcome, create, payoff, firstRoom }`
- ZStack body with explicit `.zIndex(beat == .<case> ? 1 : 0)` on every branch to prevent the SwiftUI ZStack transition snap bug (RESEARCH.md Pitfall 1)
- `@AppStorage(PersistenceKeys.onboarding)` in the View, NOT on AppStore (Pitfall 8)
- `private var beatTransition: AnyTransition` — `.asymmetric(slide+opacity)` or `.opacity` under Reduce Motion
- `advance()` — increments beat with `withAnimation(reduceMotion ? nil : Timing.beatTransitionSpring)`
- `skip()` — sets `.default` appearance + "You" name, persists, sets flag
- `.payoff` `onComplete` handler — writes `appStore.userCharacter`, `appStore.displayName`, calls `CharacterPersistence.save`, then advances to `.firstRoom`
- `complete()` — sets `hasCompletedOnboarding = true` after firstRoom beat is acknowledged
- `draftAppearance: CharacterAppearance` carries the creator's choice into payoff + firstRoom beats

**ConceptBeatView** (`LockedIN/Views/Onboarding/ConceptBeatView.swift`):
- Matches mockup `06-welcome-valueprops.png`: "Welcome to LockedIN" heading, IsometricRoomView world scene in a cream card, three value-prop rows (Join a room / Focus with friends / Build your world) each with an amber icon circle
- `Task.sleep(for: .seconds(0.6))` stagger between rows in `animateIn()` (no Combine / Timer.publish)
- Reduce Motion: all rows appear simultaneously, opacity-only, no offset stagger
- Amber CONTINUE pill, soft "Already have an account? Log in" skip link, 4-dot progress indicator (dot 0 active)

### Task 2: PayoffBeatView avatar reveal + FirstRoomBeatView first-room arrival

**PayoffBeatView** (`LockedIN/Views/Onboarding/PayoffBeatView.swift`):
- Matches mockup `03-avatar-reveal-name.png`: cream background, avatar on a gold glowing RadialGradient platform with sparkle dots, "You're all set!" heading
- `AvatarEntrancePhase` enum (hidden → riseUp → settle)
- `.phaseAnimator(…, trigger: showAvatar)` with scale (0.3→1.1→1.0), opacity, offset (riseUp -10→0) per-phase springs from Timing table
- Reduce Motion: `if reduceMotion { … .opacity(showAvatar ? 1 : 0) … }` branch — no scale, no offset
- Heading swaps: "Your avatar is ready to start studying." → "Meet [name]." cross-fade `.easeInOut(0.25)` when name is non-empty
- `TextField("Enter name…")` with `.submitLabel(.done)`, `.onChange` truncates at 30 chars (`String(new.prefix(30))` — V5 security)
- CONFIRM pill is dark charcoal (per mockup), dimmed at opacity 0.4 while name is empty
- Inline "Enter a name to continue" hint shown on empty submit attempt
- Does NOT write AppStore/persistence — delegates via `onComplete(name)` to OnboardingView

**FirstRoomBeatView** (`LockedIN/Views/Onboarding/FirstRoomBeatView.swift`):
- Matches mockup `04-first-room.png`: "This is your first room" heading, "Your space. Your focus. Your journey." body
- IsometricRoomView in a cream card (border + shadow), user's AvatarView at desk slot (72pt, position x:50% y:58%)
- Avatar fades in opacity-only after 0.3s delay (already Reduce Motion-safe)
- Dark charcoal "EXPLORE ROOM" pill calls `onExplore()` which sets `hasCompletedOnboarding = true`

### Task 3: HomeView landing + RootView first-launch gate

**HomeView** (`LockedIN/Views/HomeView.swift`):
- IsometricRoomView full-bleed background
- `AvatarView(appStore.userCharacter, .idle, 80)` at desk slot with opacity fade-in on appear
- Top greeting overlay: cream-to-transparent gradient, "Hi, [name]." (title), "Ready to lock in?" (body); name fallback "You" when displayName is empty
- Bottom action card: mini AvatarView (48pt) + name + "Idle" status + "Start a room" amber pill (Phase 3 placeholder navigation)

**RootView** (`LockedIN/App/RootView.swift`):
- Walking-skeleton sections (header/wallet/stake/forfeit) fully removed
- `@AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false` in the View
- Body: `if hasCompletedOnboarding { HomeView() } else { OnboardingView() }`

## Deviations from Plan

### Auto-adjustments (design_match priority="critical" directive)

**1. [Design Directive - Beat Count] 4 beats instead of 3**
- **Found during:** Planning and mockup review
- **Issue:** The design_match directive specified mockups for Welcome, Reveal, AND First-Room as distinct beats — the plan described 3 beats but the mockup set required 4.
- **Fix:** Added `FirstRoomBeatView` as beat 4 (`OnboardingBeat.firstRoom`), updated `OnboardingBeat` enum, and adjusted `OnboardingView` to route `.payoff → .firstRoom → complete()`.
- **Files modified:** `OnboardingView.swift`, `FirstRoomBeatView.swift` (new)

**2. [Design Directive - PayoffBeatView background] Cream + gold glow (not IsometricRoomView background)**
- **Found during:** Task 2 — mockup `03-avatar-reveal-name.png` review
- **Issue:** Plan spec said full-bleed `IsometricRoomView` as PayoffBeatView background. Mockup `03-avatar-reveal-name.png` clearly shows a cream background with the avatar on a gold glowing ellipse platform — no room visible.
- **Fix:** PayoffBeatView uses cream `Theme.Colour.background` with a `RadialGradient` gold glow platform (sparkle dots, `Theme.Colour.sparkle`). Room is NOT the background here.
- **Impact:** Visual matches mockup exactly; plan text was secondary to the critical design directive.

**3. [Design Directive - ConceptBeatView content] Value-prop rows replacing locked lines**
- **Found during:** Task 1 — mockup `06-welcome-valueprops.png` review
- **Issue:** Plan specified "Stake it. / Lock in. / Win it back." as the three animated lines. Mockup `06-welcome-valueprops.png` shows "Welcome to LockedIN" heading + three value-prop rows (Join a room / Focus with friends / Build your world) with icons and descriptors.
- **Fix:** ConceptBeatView implements the welcome + value-prop layout per mockup. The "Stake it. Lock in. Win it back." spirit is maintained in the spirit of the screen but the visual execution follows the mockup.
- **Impact:** Better matches the app's user acquisition intent.

**4. [Design Directive - CONFIRM pill] Dark charcoal, not amber**
- **Found during:** Task 2 — mockup `03-avatar-reveal-name.png` review
- **Issue:** Plan spec and UI-SPEC use amber for primary CTAs. Mockup 03 clearly shows a dark (near-black) CONFIRM pill.
- **Fix:** CONFIRM button uses `Theme.Colour.buttonFill` / `Theme.Colour.buttonText` (dark charcoal + cream text).
- **Impact:** Consistent with "Version B cream/charcoal/gold" design language — charcoal pills for commitment actions.

### Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `"Start a room"` button action (empty closure) | `HomeView.swift` | ~125 | Phase 3 placeholder — RoomSetupView not yet built |

This stub does NOT prevent the plan's goal (onboarding → home routing works); Phase 3 will wire the navigation.

## Threat Surface Scan

No new security-relevant surfaces introduced beyond what the plan's `<threat_model>` documents.

- **T-02-06** (display name overflow): mitigated — `.prefix(30)` in `PayoffBeatView.onChange`; CTA guards `trimmingCharacters(in: .whitespaces).isEmpty`
- **T-02-07** (display name logging): mitigated — no `print`/`os_log` of `displayName` or `userCharacter` anywhere in new files
- **T-02-08** (stale @AppStorage): mitigated — `@AppStorage` defaults to `false` (re-shows onboarding on failure); `CharacterPersistence.load()` uses `try?` fallback

## Manual Validation Notes (per 02-VALIDATION.md)

**ONB-01** (animated, skippable): ConceptBeatView value-prop rows stagger in via Task.sleep; beat transitions use `.asymmetric` slide+opacity; Reduce Motion switches to `.opacity` only throughout.

**ONB-04** (routing + persistence): First launch → OnboardingView (hasCompletedOnboarding=false); complete onboarding → HomeView with persisted avatar + name; relaunch → HomeView directly (flag=true, identity loaded by AppStore.init).

**ONB-05** (avatar in room): PayoffBeatView reveals avatar on gold glowing platform via PhaseAnimator; FirstRoomBeatView shows avatar at desk slot in IsometricRoomView; HomeView shows avatar at desk in full-bleed room.

**Skip path**: `OnboardingView.skip()` → `CharacterAppearance.default` + "You" persisted → HomeView shows "Hi, You." with default avatar.

## Self-Check

Files exist: PASSED (all 6 files confirmed)
Commits exist: PASSED (f3adc32, daa6c10, 1a523b6)
Build: ** BUILD SUCCEEDED **

## Self-Check: PASSED
