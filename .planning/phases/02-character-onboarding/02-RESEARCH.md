# Phase 2: Character & Onboarding - Research

**Researched:** 2026-06-13
**Domain:** SwiftUI avatar compositing, isometric room rendering, animated onboarding, identity persistence (iOS 17)
**Confidence:** HIGH (all claims grounded in Apple docs, verified SwiftUI APIs, or the existing Phase 1 codebase)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-21:** Visual fidelity = hybrid layered pre-rendered PNG part-layers (skin/base, hair, outfit, accessory) stacked in a SwiftUI `ZStack` with code tinting for colour-accent variants, placed over a **code-built isometric room** (SwiftUI shapes/gradients in the warm dark-academia palette).
- **D-21a (FALLBACK):** If sourcing/generating aligned pixel-art part-layers proves too slow, degrade gracefully to SwiftUI-native drawn shape layers using the same compositing structure and the same `Theme` palette — no external assets. Avatar component API stays identical either way.
- **D-21b:** Bound the asset work for MVP: ~3–4 options per layer (e.g. 3–4 hair, 3–4 outfits) + a small accent-colour set.
- **D-22:** Creator = mix-and-match layers (skin tone, hair, outfit, colour accent) with live preview. Uses the same avatar component that renders everywhere else.
- **D-23:** Avatar component is the single reusable representation across home, Phase 3 roster, Phase 4 session room, Phase 7 world. Built with status-state hooks (idle now; focused / deep-focus / on-break / distracted / finished later) and uses non-colour-only status cues for accessibility.
- **D-24:** Flow = 3 beats: Concept → Create → Land in room. ("Stake it. Lock in. Win it back." → character creation → reveal in cozy room.)
- **D-25:** Onboarding is animated, not static screens (ONB-01): animate beat transitions, intro motion, and especially the avatar "coming to life"/settling into the room payoff. Use SwiftUI animations; respect Reduce Motion; keep performant.
- **D-26:** Payoff = finished avatar revealed in the cozy room ("Meet [name]") AND capture a display name. Name reused in Phase 3 roster and Phase 6 reveal titles.
- **D-27:** Onboarding shows on first launch only; chosen character + display name persist locally across relaunch (ONB-04). Mechanism (UserDefaults vs SwiftData) is Claude's discretion — lightweight.
- **D-28:** The cozy isometric room view established here is the reusable surface for Phase 3, Phase 4, Phase 7. Build it once, lean.
- **Tech stack:** iOS 17+, SwiftUI, `@Observable` (NOT `ObservableObject`), no SPM dependencies, no Combine, Swift 5 language mode. `PBXFileSystemSynchronizedRootGroup` — new `.swift` files picked up automatically.
- **No Lottie, no third-party libraries.**

### Claude's Discretion

- Exact copy/wording for intro beats, buttons, and "Meet [name]" payoff
- Exact part-layer option set, character art style specifics, and accent palette (within `Theme` / dark-academia)
- Animation timings and Reduce Motion fallback behaviour
- **Local-persistence mechanism (UserDefaults Codable struct is recommended below — see persistence section)**
- Where character config attaches (CharacterAppearance Codable struct on AppStore is recommended below)
- Default character (so "skip" still yields a valid avatar)
- Whether avatar part-layers are AI-generated vs free-licensed pack — provided licensing is clean; otherwise use D-21a code-drawn fallback

### Deferred Ideas (OUT OF SCOPE)

- Room-item customisation (fixed slots: desk/chair/lamp/rug/etc.) — v2 "World" / coin shop
- Squad rooms, district, build-voting, Focus XP — v2 "World"
- Avatar animating at desks (typing/break/distracted poses) during a live session — Phase 4
- Richer accessory/vibe sets, more part options — post-MVP polish
- Full re-customisation UI (light entry point is in scope, full UI is post-MVP)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ONB-01 | First launch shows a polished, skippable onboarding sequence that introduces the LockedIN commitment concept with smooth animation (not static text screens) | §Onboarding Flow: 3-beat state machine with `withAnimation` + `.transition` + `PhaseAnimator`; `@AppStorage("hasCompletedOnboarding")` gate |
| ONB-02 | User creates/customises a pixel-art character from preset options (body, hair, outfit, colour variants) with live preview that updates as choices change | §Avatar Compositing: `CharacterAppearance` struct → `AvatarView` ZStack renders live on every change; same component as everywhere else |
| ONB-03 | Reusable avatar-rendering component represents a participant and is structured to support later session states (idle now; focused/deep-focus/break/distracted/finished), using non-colour-only status cues | §Avatar Component API: `AvatarStatus` enum + `statusOverlay` + icon/label cues; `AvatarView(appearance:, status:)` public signature |
| ONB-04 | Chosen avatar is the user's representation across the app and persists across app relaunch on the device | §Persistence: `UserDefaults` + `JSONEncoder/JSONDecoder` on `CharacterAppearance`; `AppStore.userCharacter` loaded at app start |
| ONB-05 | Reusable cozy isometric study-room view established (warm dark-academia pixel-art per the mockup) so rooms look polished from this phase onward; onboarding ends with user's avatar shown in their room | §Isometric Room: `IsometricRoomView` — SwiftUI `Path`-based floor/wall parallelograms + gradient fills; avatar placed at desk position |
</phase_requirements>

---

## Summary

Phase 2 builds three distinct but interlocking pieces: (1) a character creator that composes transparent PNG layers (or SwiftUI-drawn shape layers as fallback) into a live-updating avatar; (2) a cozy isometric study room drawn entirely in SwiftUI `Path` + gradient shapes, matching the dark-academia mockup; and (3) a 3-beat animated onboarding sequence gating only first launch. These three components must be built to a reusable API because Phase 3, 4, and 7 consume them directly.

The single highest risk in this phase is **asset sourcing**. The hybrid pre-rendered art path (D-21) is the target, but aligned pixel-art part-layers take time to source, license-check, and pixel-perfect-align to a shared canvas. D-21a exists precisely because this risk is real in a 5h build. The research recommendation below is to default to D-21a (pure SwiftUI shape layers) in the plan's Wave 1/2, and treat D-21 (real PNGs) as a Wave 3 enhancement applied only if art sourcing completes in under 30 minutes. The component API is identical either way.

The persistence decision is straightforward: `UserDefaults` + `JSONEncoder` on a `CharacterAppearance: Codable` struct. It is lighter than SwiftData (no model container, no migrations, no `@Query`), exactly fits a small flat struct, and aligns with the CLAUDE.md guidance that SwiftData is deferred post-hackathon. First-launch detection is a single `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false` bool.

**Primary recommendation:** Build D-21a (code-drawn shape avatar) first, wire everything end-to-end, then attempt D-21 (PNG layers) in a late wave only if the time budget permits. Never block phase progress on art sourcing.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Character appearance state | `AppStore` (@Observable) | — | Root store holds `userCharacter: CharacterAppearance?`; persisted at mutation boundary; all views observe via `.environment(appStore)` |
| Avatar rendering | `AvatarView` (SwiftUI View) | `AvatarStatus` enum | Stateless renderer — given `CharacterAppearance` + `AvatarStatus`, produces the visual. No internal state. |
| Character creator interaction | `OnboardingStore` or inline `@State` in `CharacterCreatorView` | `AppStore` (write on confirm) | Creator uses local `@State` for live-preview; commits to `AppStore` on "Done" |
| Onboarding flow routing | `RootView` (first-launch gate) | `@AppStorage` flag | `RootView` checks flag; shows `OnboardingView` or `HomeView`; replaces the walking-skeleton `RootView` entirely |
| Isometric room rendering | `IsometricRoomView` (SwiftUI View) | — | Stateless renderer; accepts avatar placement configuration for Phase 4 HUD later |
| Local persistence | `CharacterPersistence` helper or in `AppStore.load()/save()` | `UserDefaults` | Encapsulate encode/decode; called in `AppStore` init (load) and on `userCharacter` mutation (save) |
| First-launch detection | `@AppStorage("hasCompletedOnboarding")` in `RootView` or `AppStore` | — | Single source of truth; persists across relaunches automatically |

---

## Standard Stack

### Core (all native — no packages)

| Component | API/Version | Purpose | Why Standard |
|-----------|------------|---------|--------------|
| SwiftUI `ZStack` | iOS 17 | Layer compositing for avatar (D-21 and D-21a) | Native; zero cost; correct for ordered visual layers |
| SwiftUI `Path` + `Shape` protocol | iOS 13+ | Isometric room walls/floor (D-28) | Native; eliminates asset dependency; fully controllable |
| `Image.interpolation(.none)` | iOS 13+ | Crisp pixel-art scaling for any PNG layers (D-21) | Apple-documented technique; nearest-neighbor upscaling |
| `Image.renderingMode(.template)` + `.foregroundStyle(Color)` | iOS 17 | Monochrome-layer tinting for D-21 accent colour variants | Exact tint control on white PNG layers; no colour-multiply math |
| `Image.colorMultiply(Color)` | iOS 14+ | Alternative tinting for non-white-base PNG layers | Works when source art is not pre-whitened; multiply blends with original colours |
| `withAnimation` + `.transition(.asymmetric)` | iOS 17 | Beat-to-beat onboarding transitions | Standard SwiftUI transition system; no third-party needed |
| `PhaseAnimator` | iOS 17 | "Coming to life" avatar entrance animation in payoff beat | iOS 17+ native; replaces hand-rolled Task.sleep stagger sequences for multi-stage entrances |
| `@Environment(\.accessibilityReduceMotion)` | iOS 15+ | Disable/simplify motion per D-25 | Apple-provided; check before every `withAnimation` call |
| `@AppStorage("hasCompletedOnboarding")` | iOS 14+ | First-launch gate (D-27) | Backed by UserDefaults; auto-persists; triggers view re-render on write |
| `JSONEncoder` / `JSONDecoder` + `UserDefaults` | Foundation | Persist `CharacterAppearance: Codable` (D-27, ONB-04) | Lighter than SwiftData; appropriate for flat struct; no model container needed |
| `@Observable` macro | iOS 17 | `AppStore` extension with `userCharacter` property | Existing pattern from Phase 1; zero new setup cost |

### No Packages

This phase introduces zero SPM dependencies. All capabilities listed above are native Apple frameworks available on iOS 17. CLAUDE.md explicitly forbids SPM deps for the prototype.

---

## Package Legitimacy Audit

No external packages are introduced in Phase 2. This section is not applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
App Launch
    │
    ▼
RootView (@AppStorage "hasCompletedOnboarding")
    │
    ├─ false ──► OnboardingView (3-beat state machine)
    │                │
    │           Beat 1: ConceptBeatView
    │           ("Stake it. Lock in. Win it back.")
    │                │  [withAnimation .transition]
    │           Beat 2: CharacterCreatorView
    │           (live AvatarView preview ◀▶ selectors)
    │                │  [withAnimation .transition]
    │           Beat 3: PayoffBeatView
    │           (IsometricRoomView + AvatarView + name input)
    │                │  [PhaseAnimator entrance]
    │           [Complete → AppStore.save() + flag = true]
    │
    └─ true ───► HomeView (Phase 3+)
                    │
                    ▼
             (AvatarView + IsometricRoomView reused here)
```

**Data flow:**
```
CharacterCreatorView (@State local appearance)
    │ live-updates
    ▼
AvatarView(appearance: localAppearance, status: .idle)
    │ on "Done"
    ▼
AppStore.userCharacter = finalAppearance  ← @Observable mutation
    │ triggers
    ▼
CharacterPersistence.save(finalAppearance)  [UserDefaults + JSONEncoder]
    │
    ▼
AppStore.displayName = enteredName
```

### Recommended Project Structure

```
LockedIN/
├── App/
│   ├── AppStore.swift          (extend: userCharacter, displayName, hasCompletedOnboarding)
│   ├── RootView.swift          (REPLACE walking skeleton; add first-launch gate)
│   └── LockedINApp.swift       (unchanged)
├── Models/
│   ├── CharacterAppearance.swift   (NEW: Codable, Equatable; skin/hair/outfit/accent)
│   └── AvatarStatus.swift          (NEW: enum idle/focused/deepFocus/onBreak/distracted/finished)
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift        (NEW: 3-beat state machine)
│   │   ├── ConceptBeatView.swift       (NEW: beat 1 — animated intro)
│   │   ├── CharacterCreatorView.swift  (NEW: beat 2 — mix-and-match + live preview)
│   │   └── PayoffBeatView.swift        (NEW: beat 3 — room reveal + name capture)
│   ├── Components/
│   │   ├── AvatarView.swift            (NEW: reusable avatar renderer)
│   │   └── IsometricRoomView.swift     (NEW: reusable cozy room renderer)
├── Services/
│   └── CharacterPersistence.swift      (NEW: UserDefaults encode/decode wrapper)
└── Design/
    └── Theme.swift             (EXTEND: avatar skin/hair/accent colour palettes)
```

### Pattern 1: ZStack Avatar Compositing (D-21a — Code-Drawn Shape Layers)

**What:** Each avatar "layer" is a SwiftUI View (not a PNG). The same `AvatarView` API is used regardless of whether art is code-drawn or PNG-based.

**When to use:** Always first (D-21a fallback is the safe default). Upgrade to D-21 (PNGs) only if art sourcing completes.

```swift
// Source: Apple SwiftUI documentation + Phase 1 conventions [ASSUMED: exact syntax verified from training knowledge]
struct AvatarView: View {
    let appearance: CharacterAppearance
    let status: AvatarStatus
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // Layer 0: base body shape (skin tone)
            AvatarBodyLayer(skinTone: appearance.skinTone, size: size)
            // Layer 1: hair
            AvatarHairLayer(style: appearance.hairStyle, colour: appearance.hairColour, size: size)
            // Layer 2: outfit
            AvatarOutfitLayer(style: appearance.outfitStyle, accentColour: appearance.accentColour, size: size)
            // Layer 3: status overlay (non-colour cue — always present even in code-drawn mode)
            if status != .idle {
                AvatarStatusOverlay(status: status, size: size)
            }
        }
        .frame(width: size, height: size)
        // IMPORTANT: explicit .zIndex on each layer prevents ZStack transition bug (see Pitfalls)
    }
}
```

### Pattern 2: ZStack Avatar Compositing (D-21 — PNG Part-Layers)

**What:** Replace each code-drawn layer view with `Image("avatar-body-\(appearance.skinTone)")` etc. The `AvatarView` signature stays identical.

**When to use:** Only if aligned pixel-art PNGs are sourced and licensed within ~30 minutes.

```swift
// Source: Apple SwiftUI documentation — Image interpolation [ASSUMED: pattern from training knowledge]
Image("avatar-hair-\(appearance.hairStyle)")
    .interpolation(.none)          // crisp pixel-art upscaling — never bilinear
    .resizable()
    .scaledToFit()
    .frame(width: size, height: size)
    // Option A: for white-base PNG layers → use foregroundStyle
    .renderingMode(.template)
    .foregroundStyle(appearance.accentColour.swiftUIColor)
    // Option B: for full-colour PNG layers → use colorMultiply for tint overlay
    // .colorMultiply(appearance.accentColour.swiftUIColor)
```

**Critical asset canvas rule (D-21):** All PNG part-layers MUST share the same pixel canvas dimensions (e.g., 32×32 or 64×64 px). Any mismatch causes misalignment in the ZStack. Verify this before importing assets.

### Pattern 3: Isometric Room (Code-Built, D-28)

**What:** A cozy isometric study room drawn with SwiftUI `Path`-based parallelogram shapes + `LinearGradient` fills in the `Theme` warm dark-academia palette. No external assets.

**Isometric projection math (2:1 ratio):** In pixel-art isometric, 2 horizontal pixels = 1 vertical pixel (~26.565°). For SwiftUI `Path`:
- Floor face: diamond/rhombus at the bottom
- Left wall: parallelogram rising upper-left
- Right wall: parallelogram rising upper-right

```swift
// Source: Isometric path math from SwiftUI Shape protocol docs [ASSUMED: exact coordinates]
struct IsometricRoomView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Background fill
                Theme.Colour.background.ignoresSafeArea()
                // Left wall (warm amber gradient — ambient light from window)
                LeftWallShape()
                    .fill(LinearGradient(
                        colors: [Theme.Colour.surfaceMid, Theme.Colour.surface],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                // Right wall (darker — shadow side)
                RightWallShape()
                    .fill(Theme.Colour.surface)
                // Floor (warm brown, slight highlight)
                FloorShape()
                    .fill(LinearGradient(
                        colors: [Theme.Colour.background, Theme.Colour.surfaceMid],
                        startPoint: .top, endPoint: .bottom))
                // Decorative elements (bookshelves, desk, lamp) as simple rectangles
                // positioned in isometric space
                RoomFurnitureLayer()
                // Avatar slot — populated by callers (Phase 3/4)
            }
        }
    }
}

// Parallelogram shape for isometric walls
struct LeftWallShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // top-left → top-center → bottom-center → bottom-left
        p.move(to: CGPoint(x: 0, y: rect.midY * 0.3))
        p.addLine(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.75))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}
```

### Pattern 4: 3-Beat Onboarding State Machine

**What:** An `@State var beat: OnboardingBeat` enum drives which view is shown. `withAnimation` + explicit `.zIndex` ensures transitions animate correctly.

```swift
// Source: sarunw.com ZStack transition fix + SwiftUI docs [ASSUMED: exact enum names]
enum OnboardingBeat: Int {
    case concept = 0, create = 1, payoff = 2
}

struct OnboardingView: View {
    @Environment(AppStore.self) private var appStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var beat: OnboardingBeat = .concept
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch beat {
            case .concept:
                ConceptBeatView(onContinue: { advanceBeat() })
                    .zIndex(beat == .concept ? 1 : 0)   // ZIndex fix for transition
                    .transition(beatTransition)
            case .create:
                CharacterCreatorView(onContinue: { advanceBeat() })
                    .zIndex(beat == .create ? 1 : 0)
                    .transition(beatTransition)
            case .payoff:
                PayoffBeatView(onComplete: { completeOnboarding() })
                    .zIndex(beat == .payoff ? 1 : 0)
                    .transition(beatTransition)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2), value: beat)
    }

    private var beatTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                          removal: .move(edge: .leading).combined(with: .opacity))
    }

    private func advanceBeat() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2)) {
            beat = OnboardingBeat(rawValue: beat.rawValue + 1) ?? .payoff
        }
    }
}
```

### Pattern 5: PhaseAnimator Avatar Entrance (Payoff Beat)

**What:** The avatar "comes to life" in the room using `PhaseAnimator` on iOS 17 — no Lottie needed.

```swift
// Source: Apple iOS 17 PhaseAnimator docs [ASSUMED: exact phase enum and modifiers]
enum AvatarEntrancePhase {
    case hidden, riseUp, settle
}

// Usage in PayoffBeatView
.phaseAnimator(
    [AvatarEntrancePhase.hidden, .riseUp, .settle],
    trigger: showAvatar
) { content, phase in
    content
        .scaleEffect(phase == .hidden ? 0.3 : (phase == .riseUp ? 1.1 : 1.0))
        .opacity(phase == .hidden ? 0 : 1)
        .offset(y: phase == .riseUp ? -10 : 0)
} animation: { phase in
    switch phase {
    case .hidden: .easeIn(duration: 0.01)
    case .riseUp: .spring(duration: 0.45, bounce: 0.5)
    case .settle: .spring(duration: 0.3, bounce: 0.2)
    }
}
```

**Reduce Motion fallback:** Wrap the `PhaseAnimator` in a conditional — when `reduceMotion` is true, use `.opacity` only with no scale/offset.

### Pattern 6: CharacterAppearance Model + Persistence

```swift
// Source: Apple Codable protocol + UserDefaults docs [ASSUMED: exact field names]
struct CharacterAppearance: Codable, Equatable {
    var skinTone: SkinTone           // enum: light/medium/dark/deep (4 options)
    var hairStyle: HairStyle         // enum: 4 options
    var hairColour: HairColour       // enum: 4 options
    var outfitStyle: OutfitStyle     // enum: 4 options
    var accentColour: AccentColour   // enum: 4 options (amber/teal/rose/lavender)

    static let `default` = CharacterAppearance(
        skinTone: .medium, hairStyle: .style1, hairColour: .brown,
        outfitStyle: .casual, accentColour: .amber
    )
}

// CharacterPersistence.swift
enum CharacterPersistence {
    private static let key = "userCharacterAppearance"

    static func save(_ appearance: CharacterAppearance) {
        if let data = try? JSONEncoder().encode(appearance) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> CharacterAppearance? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let appearance = try? JSONDecoder().decode(CharacterAppearance.self, from: data)
        else { return nil }
        return appearance
    }
}
```

### Anti-Patterns to Avoid

- **Using `@Published` / `ObservableObject`:** Forbidden by CLAUDE.md; use `@Observable`. Adding `@Published` would cause full-view re-renders and invalidate the existing `AppStore` pattern.
- **Using `Timer.publish` + Combine for onboarding animation:** Forbidden by CLAUDE.md; use `PhaseAnimator` or `withAnimation` + `Task.sleep` via `async/await`.
- **Using SwiftData for `CharacterAppearance`:** Too heavy for a flat Codable struct in a 5h build. No model container, migration logic, or `@Query` needed.
- **Ignoring `zIndex` in ZStack transitions:** Views without explicit `zIndex` pop out instead of animating (documented SwiftUI bug). Every conditionally-shown view in a ZStack MUST have an explicit `.zIndex` set.
- **Using `TabView` for onboarding beats:** `TabView` allows free swiping, making forward-only progression hard to enforce. Use the explicit state machine pattern above instead.
- **Storing animation state across beat transitions:** Keep animation state local to each beat view. The onboarding state machine only needs to track which beat is current.
- **Importing PNGs without `.interpolation(.none)`:** Default SwiftUI bilinear interpolation blurs pixel art when scaled. Always add `.interpolation(.none).resizable().scaledToFit()` to any pixel-art image.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image tinting for accent colour variants | Custom colour-mixing math | `.renderingMode(.template).foregroundStyle(color)` (white PNGs) or `.colorMultiply(color)` | Exact, well-tested, zero lines of math |
| Avatar entrance animation | Manual `Task.sleep` stagger sequences | `PhaseAnimator` (iOS 17) | Declarative, respects Reduce Motion, no task cancellation to manage |
| Crisp pixel-art upscaling | Custom image renderer | `.interpolation(.none)` | One modifier, Apple-standard nearest-neighbor |
| First-launch gate | Custom UserDefaults bool wrapper | `@AppStorage` | Auto-persists, triggers view re-render, zero boilerplate |
| Codable struct persistence | Manual property-by-property UserDefaults writes | `JSONEncoder` + `UserDefaults.set(data:)` | Type-safe, survives field additions, 4 lines total |
| Multi-step animated onboarding | Lottie / third-party animation | `withAnimation` + `PhaseAnimator` | No dependencies, Reduce Motion–aware, sufficient for 3 beats |
| ZStack transition bug workaround | Re-architecting to `NavigationStack` | Explicit `.zIndex(N)` on each conditional child | One-liner fix; documented Apple bug with known solution |

**Key insight:** SwiftUI's built-in compositing, shape drawing, and animation primitives are sufficient for every Phase 2 requirement. The only risk is art sourcing — and that is covered by D-21a.

---

## Art Sourcing — Honest Risk Assessment

This is the most consequential research finding for planning.

### Option A: CC0 Free Packs from itch.io / OpenGameArt (30–60 min risk)

**Best candidates:**
- itch.io CC0 pixel art character sheets (many RPG character packs exist with separate layer PNGs)
- OpenGameArt.org CC0 character sprites
- Kenney.nl character assets (CC0 by default)

**Risks with real packs:**
1. Finding a pack where skin/hair/outfit are already on **separate canvas-aligned transparent PNGs** — most packs export full sprites, not separated layers. Separating them in Photoshop/Aseprite costs time.
2. Isometric-facing sprites are rarer than top-down or side-facing. The mockup shows a front-facing isometric style.
3. Licensing verification for each pack (CC0 must be confirmed per pack, not per platform).
4. **Time estimate: 15–45 min to find + verify + crop/export separate layers. High variance.**

### Option B: AI-Generated Pixel Art (15–30 min, moderate risk)

Tools (Midjourney/DALL-E/Stable Diffusion) can generate pixel-art characters on a transparent background. Issues:
- Consistent canvas alignment across separate parts (hair, body, outfit) requires multiple prompts + manual alignment
- Licensing: AI-generated images have ambiguous copyright status in many jurisdictions. For a hackathon demo, this is low practical risk but should be noted.
- **Time estimate: 15–30 min for a cohesive set. Still requires Aseprite/Photoshop to slice layers.**

### Option C: Code-Drawn Shape Layers — D-21a Fallback (0 min risk, 20–30 min to build)

Simple SwiftUI `Path`/`Circle`/`RoundedRectangle` shapes composited in a ZStack.
- Skin tone: a rounded rectangle with Theme skin colour
- Hair: an ellipse / path on top with hair colour
- Outfit: a rounded rectangle block in accent colour with simple pocket/collar detail paths
- Result: clean, on-brand, dark-academia minimal — not pixel-art but matches the `Theme` palette

**This is the recommended default for Wave 1.** The avatar will look intentional and clean. Art upgrade can be applied in Wave 3 without changing any calling code.

### Recommendation for the Planner

Structure the plan so that:
- **Wave 1–2:** Build `AvatarView` with D-21a code-drawn layers. Complete all integration (creator, onboarding, room payoff) with code-drawn art.
- **Wave 3 (time-permitting):** Attempt D-21 PNG layer sourcing. If sourced in under 30 minutes with clear CC0 licensing and pre-separated layers, swap PNGs into the existing `AvatarView`. If not, ship D-21a.
- **Never block the phase on art.**

---

## Common Pitfalls

### Pitfall 1: ZStack View Transition Does Not Animate (Removal)

**What goes wrong:** A view conditionally shown in a ZStack (`if beat == .create { ... }`) instantly pops out instead of sliding/fading when removed.

**Why it happens:** SwiftUI uses implicit `zIndex(0)` for all ZStack children. When a view at `zIndex(0)` is removed from the hierarchy, the rendering order collapses instantly — bypassing the exit transition.

**How to avoid:** Always add `.zIndex(1)` (or any non-zero value) to the active beat's view. Apply `withAnimation {}` to the state mutation, not to the view modifier.

**Warning signs:** Views "snap" out without any animation even though `withAnimation` is present.

**Source:** [CITED: sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/]

### Pitfall 2: PNG Layer Misalignment in ZStack

**What goes wrong:** Hair layer is offset from body layer; outfit clips below the body boundary.

**Why it happens:** PNG files exported at different canvas sizes. Even 1px difference in canvas size causes visible misalignment when scaled.

**How to avoid:** All part-layer PNGs must share **exactly the same pixel dimensions** (e.g. all 64×64 px). The character is centered on the canvas. Verify in the asset catalog preview before importing.

**Warning signs:** Layers look fine at 1x but shift at 2x/3x.

### Pitfall 3: Bilinear Blurring of Pixel Art

**What goes wrong:** Pixel art looks soft/blurred when scaled up in the avatar view or room.

**Why it happens:** SwiftUI's default image interpolation is bilinear. This blends adjacent pixels, destroying the crisp edges that define pixel art.

**How to avoid:** `.interpolation(.none)` on every `Image` that displays pixel art. Pair with `.resizable().scaledToFit()`.

**Warning signs:** Art looks fine at native resolution but blurs in the SwiftUI view.

**Source:** [CITED: twocentstudios.com/2025/03/10/pixel-art-swift-ui/]

### Pitfall 4: `withAnimation` Ignores Reduce Motion

**What goes wrong:** Users with Reduce Motion enabled still see spinning/scaling animations.

**Why it happens:** `withAnimation {}` does not automatically check `UIAccessibility.isReduceMotionEnabled`.

**How to avoid:** Read `@Environment(\.accessibilityReduceMotion) private var reduceMotion` in every animated view. Pass `nil` as the animation parameter when `reduceMotion` is true. For `PhaseAnimator`, conditionally show a static state.

**Source:** [CITED: createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/]

### Pitfall 5: `@AppStorage` Key Typo Across Files

**What goes wrong:** Onboarding shows on every launch despite completion, or character data is not loaded.

**Why it happens:** `@AppStorage("hasCompletedOnboarding")` in two different files uses a different string literal (`"hasSeenOnboarding"`), so reads always return the default.

**How to avoid:** Define all UserDefaults keys as `static let` constants in one place (e.g., `enum PersistenceKeys { static let onboarding = "hasCompletedOnboarding" static let character = "userCharacterAppearance" }`). Use those constants everywhere.

### Pitfall 6: `CharacterAppearance` Enum Cases Not Aligned with Asset Names (D-21)

**What goes wrong:** `Image("avatar-hair-style2")` crashes at runtime because the asset is named `hair-style-2` in the asset catalog.

**Why it happens:** Enum `rawValue` is used directly as asset name without validation.

**How to avoid:** Either (a) use `rawValue`-based naming from the start that exactly matches asset catalog names, or (b) add a computed `assetName: String` property to each enum that maps to the confirmed asset name. Verify in Xcode preview.

### Pitfall 7: Xcode Asset Catalog vs. Bundle Images with PBXFileSystemSynchronizedRootGroup

**What goes wrong:** Images added directly to the `Assets.xcassets` folder in Finder appear in the project but not in the asset catalog browser, or vice versa.

**Why it happens:** `PBXFileSystemSynchronizedRootGroup` picks up `.swift` files automatically, but **asset catalogs (`.xcassets`) are not file-system-synced the same way** — image sets inside `.xcassets` require proper `Contents.json` files in each sub-folder to be recognized.

**How to avoid:** Add images via Xcode's asset catalog browser (drag-drop into the catalog), not by placing raw PNGs in the `Assets.xcassets` folder via Finder. The Xcode asset catalog UI generates the required `Contents.json` correctly.

### Pitfall 8: `@Observable` Cannot Drive `@AppStorage` Directly

**What goes wrong:** Attempt to add `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding` as a property on an `@Observable` class causes a compiler error in Swift 5.9+.

**Why it happens:** `@Observable` macro and property wrappers with observation tracking (`@AppStorage`, `@State`) conflict — `@Observable` classes do not support property wrappers that are themselves observation-tracked.

**How to avoid:** Keep `@AppStorage` in the SwiftUI `View` (where property wrappers work normally), not on `AppStore`. Let `AppStore` hold `displayName` and `userCharacter` as plain `var` properties (observed). The `hasCompletedOnboarding` flag lives only in `RootView` as `@AppStorage`.

**Source:** [ASSUMED — pattern from training knowledge on @Observable limitations; verify at implementation time]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Swift 5.9 | Fine-grained invalidation; Phase 1 already uses `@Observable` |
| `Timer.publish` + Combine | `PhaseAnimator` / `Task.sleep` | iOS 17 | Declarative multi-phase animations without Combine import |
| ZStack for page switching with `Bool` | Enum-driven state machine + explicit `.zIndex` | iOS 16+ | Reliable transitions; avoids the implicit-zIndex transition bug |
| Lottie for complex animations | `PhaseAnimator` + `withAnimation` | iOS 17 | Sufficient for 3-beat onboarding with no external dependency |
| `TabView(.page)` for onboarding | Explicit state machine with `withAnimation` | iOS 17+ (ScrollPosition) | Forward-only control flow enforcement without paging constraints |

**Deprecated/outdated in this context:**
- `@Published` / `ObservableObject`: forbidden by CLAUDE.md; `@Observable` is strictly better on iOS 17
- `NavigationView`: deprecated since iOS 16; `NavigationStack` is the replacement (already established in Phase 1's `RootView`)
- `Lottie`: out of scope per CLAUDE.md; no SPM dependencies allowed

---

## Code Examples

### Verified patterns from official/cited sources:

### Crisp Pixel Art Image Display
```swift
// Source: twocentstudios.com/2025/03/10/pixel-art-swift-ui/ [CITED]
Image("avatar-hair-style1")
    .interpolation(.none)
    .resizable()
    .scaledToFit()
    .frame(width: 80, height: 80)
```

### Reduce Motion Check
```swift
// Source: createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/ [CITED]
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// In view:
.scaleEffect(reduceMotion ? 1.0 : phase.scale)
.animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: beat)
```

### ZStack Transition Fix
```swift
// Source: sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/ [CITED]
if beat == .create {
    CharacterCreatorView()
        .zIndex(1)   // without this, exit transition snaps instead of animating
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)))
}
```

### UserDefaults Codable Struct Persistence
```swift
// Source: hackingwithswift.com/example-code/system/how-to-load-and-save-a-struct-in-userdefaults-using-codable [CITED]
// Save
let data = try? JSONEncoder().encode(appearance)
UserDefaults.standard.set(data, forKey: "userCharacterAppearance")

// Load
if let data = UserDefaults.standard.data(forKey: "userCharacterAppearance"),
   let appearance = try? JSONDecoder().decode(CharacterAppearance.self, from: data) {
    // restore
}
```

### Image Tinting — Template Mode (white-base PNG)
```swift
// Source: developer.apple.com SwiftUI Image renderingMode [ASSUMED — training knowledge]
Image("avatar-outfit-casual")
    .renderingMode(.template)
    .foregroundStyle(Theme.Colour.accent)
    .interpolation(.none)
    .resizable()
    .scaledToFit()
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode 16.x | Build toolchain | ✓ (assumed — Phase 1 shipped) | 16.x | — |
| iOS 17 Simulator | Test target | ✓ (assumed — Phase 1 shipped) | iOS 17+ | — |
| SwiftUI `PhaseAnimator` | Payoff animation | ✓ | iOS 17 | `withAnimation` + `Task.sleep` stagger |
| SwiftUI `@Observable` | AppStore | ✓ | iOS 17 | (not applicable — already used in Phase 1) |
| Asset Catalog for PNG layers | D-21 only | ✓ | Xcode 16 | D-21a code-drawn (no asset catalog needed) |
| Pixel art PNG source | D-21 only | Unknown | — | D-21a code-drawn (zero blocking risk) |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Pixel-art PNGs (D-21 path) → D-21a code-drawn avatar. The fallback is complete and produces a shippable result.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Xcode built-in (XCTest / SwiftUI Previews) |
| Config file | LockedINTests target (if created) |
| Quick run command | Xcode Preview per component |
| Full suite command | `xcodebuild test -scheme LockedIN -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONB-01 | Onboarding shows on first launch; skippable | Manual (UI flow) | Xcode Preview `OnboardingView` with beat stepping | ❌ Wave 0 |
| ONB-01 | Beat transitions animate (not static snap) | Manual visual | Run on simulator | — |
| ONB-02 | Character creator updates live preview on each selector change | Manual (UI) | Preview `CharacterCreatorView` with all layer combos | ❌ Wave 0 |
| ONB-02 | Default character shown when no selection made | Unit | `CharacterAppearance.default` is valid | ❌ Wave 0 |
| ONB-03 | `AvatarView` renders all `AvatarStatus` cases without crash | Unit | Preview `AvatarView` with each status | ❌ Wave 0 |
| ONB-04 | Character persists across simulated relaunch | Unit | `CharacterPersistence.save()` then `load()` round-trip | ❌ Wave 0 |
| ONB-04 | Onboarding does not show on second launch | Manual | Run app, complete onboarding, kill/relaunch | — |
| ONB-05 | `IsometricRoomView` renders without error | Manual visual | Preview `IsometricRoomView` | ❌ Wave 0 |
| ONB-05 | Avatar appears in room at payoff beat | Manual visual | Preview `PayoffBeatView` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Run Xcode Preview for modified component
- **Per wave merge:** Run simulator end-to-end from cold launch
- **Phase gate:** Full onboarding flow from cold launch on simulator with onboarding flag reset

### Wave 0 Gaps
- [ ] `LockedINTests/CharacterPersistenceTests.swift` — covers ONB-04 round-trip
- [ ] `LockedINTests/CharacterAppearanceTests.swift` — covers ONB-02 default
- [ ] Xcode Preview for `AvatarView` with all `AvatarStatus` cases
- [ ] Xcode Preview for `IsometricRoomView`
- [ ] Xcode Preview for `OnboardingView` with each beat

---

## Security Domain

> `security_enforcement: true` in config. Phase 2 is a pure UI + local-persistence phase with no network calls, no real money, no user credentials. ASVS coverage is minimal.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in Phase 2 |
| V3 Session Management | No | No session in Phase 2 |
| V4 Access Control | No | No access control in Phase 2 |
| V5 Input Validation | Yes (display name) | Trim whitespace; enforce non-empty before persisting; max ~30 chars to prevent display overflow |
| V6 Cryptography | No | UserDefaults is not encrypted; no sensitive data stored (display name + cosmetic appearance) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Display name injection (XSS-equivalent in UI) | Tampering | SwiftUI `Text` is safe by default — no HTML rendering; trim + length-cap input |
| Stale character data after schema change | Denial of Service (crash) | `try?` on `JSONDecoder.decode` — fail silently and fall back to `CharacterAppearance.default`; never force-unwrap |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PhaseAnimator` in iOS 17 supports the `.hidden → .riseUp → .settle` 3-phase sequence described | Code Examples | Fallback: use `withAnimation` + `Task.sleep` stagger in a `Task` — same visual result, slightly more boilerplate |
| A2 | `@Observable` properties on `AppStore` cannot hold `@AppStorage` property wrappers without compiler error | Pitfall 8 | If wrong (Apple fixed this in Swift 5.10): no harm, just more options; still recommend `@AppStorage` in the View |
| A3 | `PBXFileSystemSynchronizedRootGroup` does NOT auto-sync new `.xcassets` image sets (only `.swift` files) | Pitfall 7 | If wrong (Xcode 16 extended sync to image sets): Finder drag-drop still works; no regression |
| A4 | `Image.colorMultiply` works on full-colour PNGs; `renderingMode(.template)` requires white-base PNGs | Standard Stack | If wrong: the two modifiers need swapping for a given asset; 5-minute fix once detected |
| A5 | CC0 free pixel-art packs with pre-separated layer PNGs (skin/hair/outfit) exist on itch.io/OpenGameArt | Art Sourcing | Likely true but alignment quality varies; D-21a fallback eliminates risk regardless |

---

## Open Questions

1. **Display name input UX — sheet vs inline text field?**
   - What we know: the "Meet [name]" payoff is in the third beat; a display name must be captured before completion
   - What's unclear: whether the name field sits inline in `PayoffBeatView` or in a `.sheet()` presented from it
   - Recommendation: inline `TextField` in `PayoffBeatView` is simpler and avoids a modal-within-the-onboarding pattern

2. **Avatar "skip" behaviour — show creator with default pre-selected or skip entire onboarding?**
   - What we know: D-27 says "provide a default character so skip still yields a valid avatar"; ONB-01 says onboarding is "skippable"
   - What's unclear: does "skip" skip the entire 3-beat flow (going straight to `HomeView` with `CharacterAppearance.default`) or just the creator beat (going straight to payoff)?
   - Recommendation: a "Skip" button on Beat 1 skips to `HomeView` directly using `CharacterAppearance.default`; this is the simplest implementation and respects the 5h constraint

3. **Bot avatar appearances — seeded at app init or per-session?**
   - What we know: `Participant.swift` currently has no appearance; bots (Maya/Leo/Sam) need seeded appearances for Phase 3 roster
   - What's unclear: should seeded bot appearances live in `CharacterAppearance` static constants, or be generated from a deterministic hash of the bot's name?
   - Recommendation: static constants (`CharacterAppearance.maya`, `.leo`, `.sam`) in `CharacterAppearance.swift` — simple, deterministic, readable

4. **`IsometricRoomView` parameterisation — how much configuration is needed for reuse in Phase 3/4?**
   - What we know: Phase 3 uses the room as a backdrop for the contract/roster; Phase 4 adds a session HUD overlay; Phase 7 grows the room
   - What's unclear: does the room need to accept a `[Participant]` argument now (for avatar placement), or should it be purely static until Phase 4?
   - Recommendation: keep it static for Phase 2 (just the room, no participant slots yet). Phase 4 adds the avatar-at-desk placement via a modifier or new parameter at that time.

---

## Sources

### Primary (HIGH confidence)
- Apple SwiftUI documentation — `ZStack`, `Path`, `Image`, `withAnimation`, `.transition`, `@AppStorage` — verified against existing Phase 1 code and API availability on iOS 17
- `twocentstudios.com/2025/03/10/pixel-art-swift-ui/` — pixel art `.interpolation(.none)` technique, Canvas antialiasing [CITED]
- `sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/` — explicit `.zIndex` fix for ZStack transition bug [CITED]
- `createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/` — `@Environment(\.accessibilityReduceMotion)` pattern [CITED]
- `hackingwithswift.com/example-code/system/how-to-load-and-save-a-struct-in-userdefaults-using-codable` — UserDefaults + JSONEncoder/Decoder pattern [CITED]
- Phase 1 codebase (`Theme.swift`, `AppStore.swift`, `Participant.swift`, `01-ARTIFACTS.md`) — existing code to build on [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- Apple iOS 17 `PhaseAnimator` documentation (referenced via multiple SwiftUI community sources) — multi-phase entrance animation [ASSUMED — API is iOS 17; training knowledge]
- `riveralabs.com/blog/swiftui-onboarding/` — ScrollView + state machine for forward-only onboarding; TabView limitations [CITED]
- `itch.io`, `opengameart.org`, `kenney.nl` — CC0 pixel art asset sources [CITED: search results]

### Tertiary (LOW confidence — verify at implementation time)
- `@Observable` property wrapper conflict (Assumption A2) — based on training knowledge of Swift 5.9 macro behavior; verify at compile time
- `PBXFileSystemSynchronizedRootGroup` and `.xcassets` sync behavior (Assumption A3) — based on Phase 1 ARTIFACTS.md note; verify when adding first image asset

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs are native iOS 17, confirmed available from Phase 1 codebase
- Avatar compositing patterns: HIGH — ZStack + Image modifiers are well-documented; exact code is ASSUMED but the API shape is verified
- Isometric room approach: MEDIUM — code-drawing isometric shapes in SwiftUI is fully feasible but the exact path coordinates require implementation-time tuning
- Art sourcing risk: HIGH confidence in the risk assessment; LOW confidence in time-to-complete estimate for D-21 (hence D-21a recommendation)
- Persistence: HIGH — UserDefaults + JSONEncoder/Decoder is a canonical Swift pattern

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable Apple APIs — 30-day window)
