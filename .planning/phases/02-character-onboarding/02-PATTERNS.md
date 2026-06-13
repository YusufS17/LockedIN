# Phase 2: Character & Onboarding - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 12 (10 new, 2 modified)
**Analogs found:** 8 / 12 (4 files have no codebase analog — see §No Analog Found)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `LockedIN/Design/Theme.swift` (MODIFY) | config | — | self (existing) | exact |
| `LockedIN/App/AppStore.swift` (MODIFY) | store | CRUD | self (existing) | exact |
| `LockedIN/App/RootView.swift` (REPLACE) | component | request-response | `RootView.swift` (current) | exact |
| `LockedIN/Models/CharacterAppearance.swift` (NEW) | model | CRUD | `LockedIN/Models/Money.swift` | role-match |
| `LockedIN/Models/AvatarStatus.swift` (NEW) | model | — | `LockedIN/Models/Participant.swift` | role-match |
| `LockedIN/Services/CharacterPersistence.swift` (NEW) | service | file-I/O | `LockedIN/Models/Money.swift` (utility pattern) | partial |
| `LockedIN/Views/Onboarding/OnboardingView.swift` (NEW) | component | event-driven | `LockedIN/App/RootView.swift` | role-match |
| `LockedIN/Views/Onboarding/ConceptBeatView.swift` (NEW) | component | event-driven | `LockedIN/App/RootView.swift` | role-match |
| `LockedIN/Views/Onboarding/CharacterCreatorView.swift` (NEW) | component | event-driven | `LockedIN/App/RootView.swift` | role-match |
| `LockedIN/Views/Onboarding/PayoffBeatView.swift` (NEW) | component | event-driven | `LockedIN/App/RootView.swift` | role-match |
| `LockedIN/Views/Components/AvatarView.swift` (NEW) | component | transform | `LockedIN/Design/MoneyLabel.swift` | role-match |
| `LockedIN/Views/Components/IsometricRoomView.swift` (NEW) | component | transform | `LockedIN/Design/MoneyLabel.swift` | role-match |
| `LockedIN/Views/HomeView.swift` (NEW) | component | request-response | `LockedIN/App/RootView.swift` | exact |

---

## Pattern Assignments

### `LockedIN/Design/Theme.swift` (MODIFY — extend colour tokens)

**Analog:** self

**Change:** Add new `static let` colour tokens inside `enum Colour`. Follow the exact existing pattern — one token per line, `Color(red:green:blue:)` initialiser, hex comment.

**Existing token pattern** (lines 15–35):
```swift
// Existing pattern to copy for new tokens:
static let background = Color(red: 0.118, green: 0.098, blue: 0.078)   // #1E190F deep warm brown
static let surface    = Color(red: 0.196, green: 0.165, blue: 0.129)   // #322A21 warm surface
```

**New tokens to append inside `enum Colour`** (from UI-SPEC.md §Color):
```swift
// Skin tones (avatar layer fills)
static let skinLight  = Color(red: 0.992, green: 0.859, blue: 0.706)   // #FDDBB4 warm pale
static let skinMedium = Color(red: 0.831, green: 0.584, blue: 0.416)   // #D4956A warm golden
static let skinDark   = Color(red: 0.553, green: 0.333, blue: 0.141)   // #8D5524 deep warm brown
static let skinDeep   = Color(red: 0.290, green: 0.161, blue: 0.071)   // #4A2912 richest tone

// Hair colours (avatar layer fills)
static let hairBlonde = Color(red: 0.910, green: 0.788, blue: 0.478)   // #E8C97A warm straw
static let hairBrown  = Color(red: 0.420, green: 0.227, blue: 0.165)   // #6B3A2A chestnut
static let hairBlack  = Color(red: 0.102, green: 0.071, blue: 0.063)   // #1A1210 near-black warm
static let hairSilver = Color(red: 0.627, green: 0.627, blue: 0.627)   // #A0A0A0 cool grey-silver

// Avatar accent colours (outfit tints — amber reuses Theme.Colour.accent)
static let accentTeal     = Color(red: 0.302, green: 0.722, blue: 0.643) // #4DB8A4 study-room teal
static let accentRose     = Color(red: 0.878, green: 0.420, blue: 0.545) // #E06B8B warm rose
static let accentLavender = Color(red: 0.608, green: 0.494, blue: 0.784) // #9B7EC8 muted lavender

// Room furniture colours
static let plantGreen  = Color(red: 0.290, green: 0.486, blue: 0.349)   // #4A7C59 dark olive green
static let windowSlate = Color(red: 0.165, green: 0.227, blue: 0.322)   // #2A3A52 night window
```

**TypeScale update required** (lines 43 and 47 — per UI-SPEC.md §Typography):
```swift
// Change .semibold → .bold for these two tokens only:
static let headline    = Font.system(size: 17, weight: .bold,     design: .rounded)  // was .semibold
static let captionBold = Font.system(size: 13, weight: .bold,     design: .rounded)  // was .semibold
```

---

### `LockedIN/App/AppStore.swift` (MODIFY — add user identity properties)

**Analog:** self (lines 1–69)

**Pattern:** `@Observable` class; plain `var` properties (no `@AppStorage`, no `@Published` — per RESEARCH.md Pitfall 8). Keep existing `commitmentService` and `focusAdapter` unchanged.

**Existing `@Observable` property pattern** (lines 23–29):
```swift
@Observable
final class AppStore {
    let forfeitDestination: String = ForfeitConfig.destination
    let commitmentService: CommitmentService
    let focusAdapter: FocusControlAdapter
```

**New properties to add** (plain `var`, observed automatically by `@Observable`):
```swift
// MARK: - User Identity (Phase 2, ONB-04)
// Plain var — @Observable tracks these automatically.
// Do NOT use @AppStorage here: @Observable classes cannot hold property wrappers
// that are themselves observation-tracked (RESEARCH.md Pitfall 8).

var userCharacter: CharacterAppearance = .default
var displayName: String = ""
```

**Init update** — load persisted values:
```swift
init(
    commitmentService: CommitmentService = MockCommitmentService(),
    focusAdapter: FocusControlAdapter = MockFocusControlAdapter()
) {
    self.commitmentService = commitmentService
    self.focusAdapter = focusAdapter
    // Load persisted identity on start (ONB-04)
    if let saved = CharacterPersistence.load() {
        self.userCharacter = saved.appearance
        self.displayName   = saved.displayName
    }
}
```

---

### `LockedIN/App/RootView.swift` (REPLACE — first-launch gate)

**Analog:** current `RootView.swift` (lines 1–141) — import + `@Environment` pattern stays identical

**Import + Environment pattern** (lines 1–11):
```swift
import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var appStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
```

**Routing pattern** — replace the entire body with a conditional:
```swift
var body: some View {
    if hasCompletedOnboarding {
        HomeView()
    } else {
        OnboardingView()
    }
}
```

**Note:** Keep `.preferredColorScheme(.dark)` from the current `RootView` body, applied to the outer container. The `NavigationStack` is no longer at the root — each child view manages its own stack if needed.

---

### `LockedIN/Models/CharacterAppearance.swift` (NEW)

**Analog:** `LockedIN/Models/Money.swift` (utility model pattern — plain Swift types, no SwiftUI import, rich documentation header)

**Money.swift header/structure pattern** (lines 1–12):
```swift
import Foundation

// MARK: - [Type Name]
//
// [Brief description]
// [Key constraint / invariant]

typealias Pence = Int
```

**CharacterAppearance pattern** (copy Codable + Equatable approach, use nested enums with `CaseIterable` for cycling):
```swift
import Foundation

// MARK: - CharacterAppearance (D-21, D-21b, ONB-02, ONB-04)
//
// The user's avatar configuration. Codable for UserDefaults persistence (ONB-04).
// Equatable for live-preview change detection in CharacterCreatorView.
// All option enums are CaseIterable to support ◀▶ cycling in the creator.

struct CharacterAppearance: Codable, Equatable {
    var skinTone:    SkinTone
    var hairStyle:   HairStyle
    var hairColour:  HairColour
    var outfitStyle: OutfitStyle
    var accentColour: AccentColour

    // Default character — always valid; shown when user skips onboarding (D-27).
    static let `default` = CharacterAppearance(
        skinTone: .medium, hairStyle: .short, hairColour: .brown,
        outfitStyle: .casual, accentColour: .amber
    )

    // Static seeded appearances for bots (RESEARCH.md Open Question Q3)
    static let maya = CharacterAppearance(skinTone: .dark,   hairStyle: .long,  hairColour: .black,  outfitStyle: .academic, accentColour: .teal)
    static let leo  = CharacterAppearance(skinTone: .light,  hairStyle: .short, hairColour: .blonde, outfitStyle: .hoodie,   accentColour: .lavender)
    static let sam  = CharacterAppearance(skinTone: .medium, hairStyle: .tied,  hairColour: .brown,  outfitStyle: .smart,    accentColour: .rose)
}

enum SkinTone: String, Codable, CaseIterable {
    case light, medium, dark, deep
    var displayName: String { rawValue.capitalized }
}

enum HairStyle: String, Codable, CaseIterable {
    case short, curly, long, tied
    var displayName: String { rawValue.capitalized }
}

enum HairColour: String, Codable, CaseIterable {
    case blonde, brown, black, silver
    var displayName: String { rawValue.capitalized }
}

enum OutfitStyle: String, Codable, CaseIterable {
    case casual, academic, hoodie, smart
    var displayName: String { rawValue.capitalized }
}

enum AccentColour: String, Codable, CaseIterable {
    case amber, teal, rose, lavender
    var displayName: String { rawValue.capitalized }
}
```

**VoiceOver description** (required by UI-SPEC.md §Accessibility):
```swift
extension CharacterAppearance {
    /// Human-readable description for VoiceOver (AvatarView accessibilityLabel).
    var description: String {
        "\(skinTone.displayName) skin, \(hairStyle.displayName) \(hairColour.displayName) hair, \(outfitStyle.displayName) outfit"
    }
}
```

---

### `LockedIN/Models/AvatarStatus.swift` (NEW)

**Analog:** `LockedIN/Models/Participant.swift` (plain struct/enum, Foundation only, clean doc header)

**Participant.swift pattern** (lines 1–16):
```swift
import Foundation

// MARK: - [Name]
/// [Doc comment]
struct Participant: Identifiable, Equatable { ... }
```

**AvatarStatus pattern:**
```swift
import Foundation

// MARK: - AvatarStatus (D-23, ONB-03)
//
// Status states for the reusable AvatarView component.
// All states declared now; only .idle used in Phase 2.
// Phase 4 activates focused/deepFocus/onBreak/distracted/finished.
// Non-colour-only overlays are required (ONB-03 accessibility).

enum AvatarStatus: String, Equatable {
    case idle
    case focused
    case deepFocus
    case onBreak
    case distracted
    case finished

    /// Human-readable label for VoiceOver and the status badge text.
    var label: String {
        switch self {
        case .idle:      return "Idle"
        case .focused:   return "Focused"
        case .deepFocus: return "Deep"
        case .onBreak:   return "Break"
        case .distracted: return "!"
        case .finished:  return "Done"
        }
    }

    /// SF Symbol name for the status badge icon (non-colour-only cue, ONB-03).
    var symbolName: String? {
        switch self {
        case .idle:      return nil
        case .focused:   return "lock.fill"
        case .deepFocus: return "bolt.fill"
        case .onBreak:   return "cup.and.saucer.fill"
        case .distracted: return "exclamationmark.triangle.fill"
        case .finished:  return "checkmark.circle.fill"
        }
    }
}
```

---

### `LockedIN/Services/CharacterPersistence.swift` (NEW)

**Analog:** No exact analog. Closest pattern: utility enum in `Money.swift` (caseless enum as a namespace).

**Money.swift namespace pattern** (pure function, no `class`/`struct` needed):
```swift
// caseless enum used as a namespace for functions
// (same pattern as Theme — enum with no cases)
```

**CharacterPersistence pattern** (from RESEARCH.md Pattern 6):
```swift
import Foundation

// MARK: - PersistenceKeys (ONB-04, RESEARCH.md Pitfall 5)
//
// Single source of truth for all UserDefaults key strings.
// NEVER hardcode key strings at the call site — always use these constants.

enum PersistenceKeys {
    static let character   = "userCharacterAppearance"
    static let displayName = "userDisplayName"
    static let onboarding  = "hasCompletedOnboarding"
}

// MARK: - CharacterPersistence

/// Lightweight wrapper around UserDefaults + JSONEncoder/Decoder for identity persistence.
/// Uses `try?` on all decode operations — failure silently returns nil; caller falls back
/// to CharacterAppearance.default (RESEARCH.md §Security, V5 threat: stale data / crash).
enum CharacterPersistence {

    struct PersistedIdentity {
        let appearance: CharacterAppearance
        let displayName: String
    }

    static func save(appearance: CharacterAppearance, displayName: String) {
        if let data = try? JSONEncoder().encode(appearance) {
            UserDefaults.standard.set(data, forKey: PersistenceKeys.character)
        }
        UserDefaults.standard.set(displayName, forKey: PersistenceKeys.displayName)
    }

    static func load() -> PersistedIdentity? {
        guard
            let data = UserDefaults.standard.data(forKey: PersistenceKeys.character),
            let appearance = try? JSONDecoder().decode(CharacterAppearance.self, from: data)
        else { return nil }
        let name = UserDefaults.standard.string(forKey: PersistenceKeys.displayName) ?? ""
        return PersistedIdentity(appearance: appearance, displayName: name)
    }
}
```

---

### `LockedIN/Views/Components/AvatarView.swift` (NEW)

**Analog:** `LockedIN/Design/MoneyLabel.swift` — reusable stateless component, Theme tokens throughout, `#Preview` blocks, sub-view decomposition with private computed vars/sub-structs.

**MoneyLabel structural pattern** (lines 14–30):
```swift
struct MoneyLabel: View {
    let amount: Pence          // ← immutable input(s)
    var compact: Bool = false  // ← optional param with default

    init(_ amount: Pence, compact: Bool = false) { ... }

    var body: some View {
        if compact { compactLayout } else { fullLayout }
    }

    private var fullLayout: some View { ... }   // private sub-views
    private var compactLayout: some View { ... }
}
```

**MoneyLabel Theme usage pattern** (lines 34–37):
```swift
Text(formatPence(amount))
    .font(Theme.TypeScale.money)
    .foregroundStyle(Theme.Colour.moneyGreen)
```

**MoneyLabel preview pattern** (lines 134–153):
```swift
#Preview("Full layout") {
    VStack(spacing: Theme.Spacing.lg) {
        MoneyLabel(500)
    }
    .padding()
    .background(Theme.Colour.background)
}
```

**AvatarView pattern** (apply MoneyLabel structure to avatar layers):
```swift
import SwiftUI

// MARK: - AvatarView (D-21a, D-22, D-23, ONB-02, ONB-03)
//
// The SINGLE reusable avatar renderer across home, onboarding, Phase 3 roster,
// Phase 4 session HUD, Phase 7 world. Stateless: given (appearance, status, size)
// it produces the visual. No internal mutable state.
//
// Layer order (ZStack bottom → top):
//   1. AvatarBodyLayer  (skin tone)
//   2. AvatarHairLayer  (hair style + colour)
//   3. AvatarOutfitLayer (outfit + accent colour tint)
//   4. AvatarStatusOverlay (visible only when status != .idle)
//
// D-21a DEFAULT: All layers are code-drawn SwiftUI shapes.
// D-21 UPGRADE: Replace layer views with Image PNGs — this public API is unchanged.

struct AvatarView: View {
    let appearance: CharacterAppearance
    let status: AvatarStatus
    var size: CGFloat = 80          // default 80; creator uses 120; roster 48; HUD 40

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Layer 1: Body (skin)
            AvatarBodyLayer(skinTone: appearance.skinTone, size: size)
            // Layer 2: Hair
            AvatarHairLayer(style: appearance.hairStyle, colour: appearance.hairColour, size: size)
            // Layer 3: Outfit
            AvatarOutfitLayer(style: appearance.outfitStyle, accentColour: appearance.accentColour, size: size)
            // Layer 4: Status badge (non-idle only)
            if status != .idle {
                AvatarStatusOverlay(status: status, size: size)
                    .accessibilityHidden(true)  // parent AvatarView label carries the status
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Avatar: \(appearance.description), status: \(status.label)")
        .accessibilityElement(children: .ignore)
    }
}

// MARK: - Layer Sub-views (D-21a code-drawn)

private struct AvatarBodyLayer: View {
    let skinTone: SkinTone
    let size: CGFloat

    var body: some View {
        // Head: upper circle. Body: lower rounded rect. Simple pixel-art silhouette.
        VStack(spacing: 0) {
            Circle()
                .fill(skinTone.colour)
                .frame(width: size * 0.45, height: size * 0.45)
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(skinTone.colour)
                .frame(width: size * 0.5, height: size * 0.3)
        }
        .frame(width: size, height: size, alignment: .bottom)
    }
}

// ... AvatarHairLayer, AvatarOutfitLayer follow same structure

private struct AvatarStatusOverlay: View {
    let status: AvatarStatus
    let size: CGFloat

    var body: some View {
        // Badge: filled circle + SF Symbol icon + text (non-colour-only, ONB-03)
        ZStack {
            Circle()
                .fill(status.badgeColour.opacity(0.9))
                .frame(width: size * 0.28, height: size * 0.28)
            if let symbol = status.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
        }
        .offset(x: Theme.Spacing.xs, y: Theme.Spacing.xs)
    }
}
```

**SkinTone colour extension** (add to `CharacterAppearance.swift` or `AvatarView.swift`):
```swift
extension SkinTone {
    var colour: Color {
        switch self {
        case .light:  return Theme.Colour.skinLight
        case .medium: return Theme.Colour.skinMedium
        case .dark:   return Theme.Colour.skinDark
        case .deep:   return Theme.Colour.skinDeep
        }
    }
}
```

---

### `LockedIN/Views/Components/IsometricRoomView.swift` (NEW)

**Analog:** No close codebase analog — no Path-based drawing exists in Phase 1. Use RESEARCH.md Pattern 3 directly.

**Closest structural analog:** `RootView.swift` — ZStack composition with background + layered content. Copy the ZStack + GeometryReader shell pattern.

**RootView ZStack pattern** (lines 22–50):
```swift
var body: some View {
    NavigationStack {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) { ... }
                    .padding(Theme.Spacing.md)
            }
        }
    }
}
```

**IsometricRoomView pattern** (RESEARCH.md Pattern 3 + UI-SPEC.md §IsometricRoomView):
```swift
import SwiftUI

// MARK: - IsometricRoomView (D-28, ONB-05)
//
// Reusable cozy isometric study room — drawn entirely in SwiftUI Path + gradients.
// No external assets. Stateless and parameterless in Phase 2.
// Phase 4 adds participant placement via overlay modifier (do not add param now).
//
// Isometric geometry: 2:1 ratio (~26.6°). Floor rhombus lower 40%; left/right walls rise above.

struct IsometricRoomView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.Colour.background.ignoresSafeArea()
                // Right wall — shadow side (draw first, behind left wall)
                RightWallShape(size: geo.size)
                    .fill(Theme.Colour.surface)
                // Left wall — ambient light side (warm gradient)
                LeftWallShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [Theme.Colour.surfaceMid, Theme.Colour.surface],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                // Floor — warm wood feel
                FloorShape(size: geo.size)
                    .fill(LinearGradient(
                        colors: [Theme.Colour.background, Theme.Colour.surfaceMid],
                        startPoint: .top, endPoint: .bottom))
                // Furniture layer (code-drawn rectangles in isometric perspective)
                RoomFurnitureLayer(size: geo.size)
            }
        }
    }
}

// MARK: - Room Shapes (Path-based parallelograms)

private struct LeftWallShape: Shape {
    let size: CGSize
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = size.width, h = size.height
        p.move(to:    CGPoint(x: 0,      y: h * 0.55))   // bottom-left
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.15))  // top-centre
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))  // bottom-centre
        p.addLine(to: CGPoint(x: 0,       y: h * 0.90))  // bottom-left-floor
        p.closeSubpath()
        return p
    }
}
// RightWallShape and FloorShape follow the same Path pattern with mirrored coordinates.
```

---

### `LockedIN/Views/Onboarding/OnboardingView.swift` (NEW)

**Analog:** `LockedIN/App/RootView.swift` — `@Environment(AppStore.self)` injection, Theme usage, `NavigationStack`, ZStack composition.

**RootView environment injection pattern** (lines 9–11):
```swift
struct RootView: View {
    @Environment(AppStore.self) private var appStore
```

**RootView background pattern** (lines 23–24):
```swift
ZStack {
    Theme.Colour.background.ignoresSafeArea()
```

**OnboardingView pattern** (from RESEARCH.md Pattern 4):
```swift
import SwiftUI

// MARK: - OnboardingView (D-24, D-25, ONB-01)
//
// 3-beat state machine: .concept → .create → .payoff
// withAnimation + explicit .zIndex guards against the ZStack transition bug
// (RESEARCH.md Pitfall 1; sarunw.com/posts/how-to-fix-zstack-transition-animation).

enum OnboardingBeat: Int {
    case concept = 0, create = 1, payoff = 2
}

struct OnboardingView: View {
    @Environment(AppStore.self) private var appStore
    @AppStorage(PersistenceKeys.onboarding) private var hasCompletedOnboarding = false
    @State private var beat: OnboardingBeat = .concept
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Timing constants (UI-SPEC.md §Animation & Motion)
    private enum Timing {
        static let beatTransitionSpring = Animation.spring(duration: 0.4, bounce: 0.2)
        static let conceptLineDelay: Duration = .seconds(0.6)
        static let headingSwapFade = Animation.easeInOut(duration: 0.25)
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            // Beat views — explicit .zIndex prevents ZStack transition snap (RESEARCH.md Pitfall 1)
            switch beat {
            case .concept:
                ConceptBeatView(onContinue: { advance() }, onSkip: { skip() })
                    .zIndex(beat == .concept ? 1 : 0)
                    .transition(beatTransition)
            case .create:
                CharacterCreatorView(onContinue: { advance() }, onSkip: { skip() })
                    .zIndex(beat == .create ? 1 : 0)
                    .transition(beatTransition)
            case .payoff:
                PayoffBeatView(onComplete: { complete(appearance:displayName:) })
                    .zIndex(beat == .payoff ? 1 : 0)
                    .transition(beatTransition)
            }
        }
        .animation(reduceMotion ? nil : Timing.beatTransitionSpring, value: beat)
        .preferredColorScheme(.dark)
    }

    private var beatTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity))
    }

    private func advance() {
        withAnimation(reduceMotion ? nil : Timing.beatTransitionSpring) {
            beat = OnboardingBeat(rawValue: beat.rawValue + 1) ?? .payoff
        }
    }

    private func skip() {
        appStore.userCharacter = .default
        appStore.displayName   = "You"
        hasCompletedOnboarding = true
    }

    private func complete(appearance: CharacterAppearance, displayName: String) {
        appStore.userCharacter = appearance
        appStore.displayName   = displayName
        CharacterPersistence.save(appearance: appearance, displayName: displayName)
        hasCompletedOnboarding = true
    }
}
```

---

### `LockedIN/Views/Onboarding/ConceptBeatView.swift` (NEW)

**Analog:** `LockedIN/App/RootView.swift` — section decomposition into private `var` properties, Theme tokens, VStack layout.

**RootView section decomposition pattern** (lines 53–121):
```swift
private var headerSection: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
        Text("Walking Skeleton")
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.accent)
            .textCase(.uppercase)
        Text("Foundation Substrate")
            .font(Theme.TypeScale.title)
            .foregroundStyle(Theme.Colour.textPrimary)
    }
}
```

**ConceptBeatView pattern** — sequential line animation with `Task.sleep`, Reduce Motion gate:
```swift
import SwiftUI

// MARK: - ConceptBeatView (D-24, D-25, ONB-01) — Beat 1 of 3
//
// Animates "Stake it." / "Lock in." / "Win it back." sequentially.
// Task.sleep stagger (0.6s per line) with Reduce Motion fallback (all-at-once).

struct ConceptBeatView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var line1Visible = false
    @State private var line2Visible = false
    @State private var line3Visible = false
    @State private var bodyVisible  = false
    @State private var ctaVisible   = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Spacer()
            conceptLines
            if bodyVisible { supportingBody }
            Spacer()
            if ctaVisible  { ctaBlock }
            progressDots(active: 0)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
        .task { await animateIn() }
    }

    private var conceptLines: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if line1Visible {
                Text("Stake it.")
                    .font(Theme.TypeScale.largeTitle)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .transition(lineTransition)
            }
            if line2Visible {
                Text("Lock in.")
                    .font(Theme.TypeScale.largeTitle)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .transition(lineTransition)
            }
            if line3Visible {
                Text("Win it back.")
                    .font(Theme.TypeScale.largeTitle)
                    .foregroundStyle(Theme.Colour.accent)
                    .transition(lineTransition)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: line3Visible)
    }

    private var lineTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 20))
    }

    private func animateIn() async {
        if reduceMotion {
            line1Visible = true; line2Visible = true; line3Visible = true
            bodyVisible = true; ctaVisible = true
            return
        }
        withAnimation { line1Visible = true }
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation { line2Visible = true }
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation { line3Visible = true }
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation { bodyVisible = true }
        try? await Task.sleep(for: .seconds(0.4))
        withAnimation { ctaVisible = true }
    }
}
```

---

### `LockedIN/Views/Onboarding/CharacterCreatorView.swift` (NEW)

**Analog:** `LockedIN/App/RootView.swift` — local `@State` for display values, surface card helper, VStack section layout.

**RootView surfaceCard helper pattern** (lines 125–131):
```swift
private func surfaceCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colour.surfaceMid)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
}
```

**CharacterCreatorView pattern** — local `@State` for live preview, cycling ◀▶ selectors:
```swift
import SwiftUI

// MARK: - CharacterCreatorView (D-22, ONB-02) — Beat 2 of 3
//
// Local @State localAppearance drives live AvatarView preview on every change.
// On "That's me", writes localAppearance back to the parent (via callback or @Binding).
// Does NOT write to AppStore directly — OnboardingView commits on completion (D-22).

struct CharacterCreatorView: View {
    let onContinue: (CharacterAppearance) -> Void
    let onSkip: () -> Void

    @State private var localAppearance: CharacterAppearance = .default

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            skipButton
            Text("Create your character")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
            avatarPreviewCard
            selectorRows
            Spacer()
            ctaButton
            progressDots(active: 1)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
    }

    private var avatarPreviewCard: some View {
        AvatarView(appearance: localAppearance, status: .idle, size: 120)
            .padding(Theme.Spacing.lg)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    // Generic stepper row — copies RootView's HStack pattern for consistent layout
    private func stepperRow<Option: CaseIterable & Equatable>(
        label: String,
        current: Option,
        displayName: String,
        swatch: Color? = nil,
        previous: @escaping () -> Void,
        next: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.textSecondary)
            Spacer()
            Button(action: previous) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(width: 44, height: 44)         // iOS HIG 44pt minimum touch target
            .accessibilityLabel("Previous \(label)")
            HStack(spacing: Theme.Spacing.xs) {
                if let swatch {
                    Circle().fill(swatch).frame(width: 16, height: 16)
                }
                Text(displayName)
                    .font(Theme.TypeScale.body)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .frame(minWidth: 80)
            }
            Button(action: next) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Next \(label)")
        }
    }
}
```

---

### `LockedIN/Views/Onboarding/PayoffBeatView.swift` (NEW)

**Analog:** `LockedIN/App/RootView.swift` — ZStack + background layer pattern; `@State` for local UI state.

**No analog for PhaseAnimator** — use RESEARCH.md Pattern 5 directly.

**RootView ZStack + background pattern** (lines 22–26):
```swift
ZStack {
    Theme.Colour.background.ignoresSafeArea()
    ScrollView { ... }
}
```

**PayoffBeatView pattern** — IsometricRoomView background + PhaseAnimator entrance + inline TextField:
```swift
import SwiftUI

// MARK: - PayoffBeatView (D-26, ONB-05) — Beat 3 of 3
//
// IsometricRoomView fills the screen. Avatar appears at desk via PhaseAnimator.
// Inline TextField captures displayName. "Lock me in" completes onboarding.
// Reduce Motion: skip scale/offset; opacity-only avatar entrance.

enum AvatarEntrancePhase {
    case hidden, riseUp, settle
}

struct PayoffBeatView: View {
    let appearance: CharacterAppearance
    let onComplete: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayName = ""
    @State private var showAvatar  = false
    @State private var showHint    = false          // "Enter a name to continue" hint

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background: full-bleed isometric room
            IsometricRoomView()
                .ignoresSafeArea()

            // Avatar at desk (positioned at ~50% x, ~58% y per UI-SPEC)
            GeometryReader { geo in
                avatarEntrance
                    .position(x: geo.size.width * 0.50, y: geo.size.height * 0.58)
            }

            // Foreground overlay: gradient + name input + CTA
            foregroundOverlay
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                showAvatar = true
            }
        }
    }

    // PhaseAnimator avatar entrance (RESEARCH.md Pattern 5)
    @ViewBuilder
    private var avatarEntrance: some View {
        if reduceMotion {
            AvatarView(appearance: appearance, status: .idle, size: 80)
                .opacity(showAvatar ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: showAvatar)
        } else {
            AvatarView(appearance: appearance, status: .idle, size: 80)
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
                    case .hidden:  .easeIn(duration: 0.01)
                    case .riseUp:  .spring(duration: 0.45, bounce: 0.5)
                    case .settle:  .spring(duration: 0.3,  bounce: 0.2)
                    }
                }
        }
    }

    private var foregroundOverlay: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Heading: swaps from "Almost there" → "Meet [name]" when name entered
            Group {
                if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Almost there — what's your name?")
                } else {
                    Text("Meet \(displayName.trimmingCharacters(in: .whitespaces)).")
                }
            }
            .font(Theme.TypeScale.title)
            .foregroundStyle(Theme.Colour.textPrimary)
            .animation(.easeInOut(duration: 0.25), value: displayName.isEmpty)
            .transition(.opacity)

            // Display name TextField (inline — RESEARCH.md Open Question Q1)
            TextField("Your name", text: $displayName)
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textPrimary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colour.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .submitLabel(.done)
                .onChange(of: displayName) { _, new in
                    // Enforce 30-char max (UI-SPEC §Copywriting, RESEARCH.md §Security V5)
                    if new.count > 30 { displayName = String(new.prefix(30)) }
                }
            // Inline hint on failed CTA tap
            if showHint {
                Text("Enter a name to continue")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.accentSoft)
            }

            progressDots(active: 2)
            ctaButton
        }
        .padding(Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
        .background(
            LinearGradient(
                colors: [Theme.Colour.background.opacity(0), Theme.Colour.background.opacity(0.92)],
                startPoint: .top, endPoint: .bottom)
        )
    }

    private var ctaButton: some View {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return Button("Lock me in") {
            guard !trimmed.isEmpty else { showHint = true; return }
            onComplete(trimmed)
        }
        .font(Theme.TypeScale.headline)
        .foregroundStyle(Theme.Colour.textOnAccent)
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colour.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        .opacity(trimmed.isEmpty ? 0.4 : 1.0)
    }
}
```

---

### `LockedIN/Views/HomeView.swift` (NEW)

**Analog:** `LockedIN/App/RootView.swift` — `@Environment(AppStore.self)`, ZStack + background + section decomposition, Theme tokens throughout.

**RootView environment + ZStack pattern** (lines 9–48):
```swift
struct RootView: View {
    @Environment(AppStore.self) private var appStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colour.background.ignoresSafeArea()
                ...
            }
        }
        .preferredColorScheme(.dark)
    }
}
```

**RootView preview pattern** (lines 136–140):
```swift
#Preview {
    let store = AppStore()
    return RootView()
        .environment(store)
}
```

**HomeView pattern:**
```swift
import SwiftUI

// MARK: - HomeView (D-26, D-28) — Post-onboarding landing
//
// IsometricRoomView fills the screen. Greeting overlay anchored top.
// Bottom action card: mini avatar + displayName + "Start a room" CTA (placeholder Phase 3).

struct HomeView: View {
    @Environment(AppStore.self) private var appStore

    var body: some View {
        ZStack(alignment: .bottom) {
            IsometricRoomView().ignoresSafeArea()

            // Avatar at desk
            GeometryReader { geo in
                AvatarView(
                    appearance: appStore.userCharacter,
                    status: .idle,
                    size: 80
                )
                .position(x: geo.size.width * 0.50, y: geo.size.height * 0.58)
                .opacity(0)   // fade in on appear
                .onAppear { /* withAnimation { opacity = 1 } */ }
            }

            // Top greeting overlay
            VStack {
                topGreeting
                Spacer()
                bottomActionCard
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topGreeting: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Hi, \(appStore.displayName.isEmpty ? "You" : appStore.displayName).")
                .font(Theme.TypeScale.title)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Ready to lock in?")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [Theme.Colour.background.opacity(0.85), Theme.Colour.background.opacity(0)],
                startPoint: .top, endPoint: .bottom)
        )
    }

    private var bottomActionCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                AvatarView(appearance: appStore.userCharacter, status: .idle, size: 48)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(appStore.displayName.isEmpty ? "You" : appStore.displayName)
                        .font(Theme.TypeScale.headline)
                        .foregroundStyle(Theme.Colour.textPrimary)
                    Text("Idle")
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
            }
            Button("Start a room") {
                // Phase 3 navigation — placeholder
            }
            .font(Theme.TypeScale.headline)
            .foregroundStyle(Theme.Colour.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colour.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colour.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
    }
}

#Preview {
    let store = AppStore()
    return HomeView()
        .environment(store)
}
```

---

## Shared Patterns

### `@Environment(AppStore.self)` injection
**Source:** `LockedIN/App/RootView.swift` line 10; `LockedIN/App/LockedINApp.swift`
**Apply to:** `OnboardingView`, `CharacterCreatorView`, `PayoffBeatView`, `HomeView`, `RootView` (replacement)
```swift
@Environment(AppStore.self) private var appStore
```

### Theme token usage
**Source:** `LockedIN/Design/Theme.swift` + `LockedIN/App/RootView.swift` (all lines)
**Apply to:** Every new view file
```swift
// Background fill — always first in ZStack
Theme.Colour.background.ignoresSafeArea()

// Text hierarchy
.font(Theme.TypeScale.title)
.foregroundStyle(Theme.Colour.textPrimary)
.font(Theme.TypeScale.body)
.foregroundStyle(Theme.Colour.textSecondary)

// Surface card
.background(Theme.Colour.surfaceMid)
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

// CTA pill button
.background(Theme.Colour.accent)
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
.foregroundStyle(Theme.Colour.textOnAccent)
```

### Reduce Motion gate
**Source:** RESEARCH.md Pattern 4 (no codebase analog — new in Phase 2)
**Apply to:** `OnboardingView`, `ConceptBeatView`, `PayoffBeatView`
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Before every withAnimation call:
withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2)) { ... }
```

### ZStack transition `.zIndex` fix
**Source:** RESEARCH.md Pitfall 1 + Pattern 4 (sarunw.com citation)
**Apply to:** `OnboardingView` beat switching
```swift
// Every conditionally-shown view in a ZStack MUST have explicit .zIndex
SomeBeatView()
    .zIndex(beat == .concept ? 1 : 0)
    .transition(beatTransition)
```

### Private sub-view decomposition
**Source:** `LockedIN/App/RootView.swift` lines 53–131; `LockedIN/Design/MoneyLabel.swift` lines 33–130
**Apply to:** All new view files
```swift
// Decompose body into private computed var properties, NOT separate structs,
// unless the sub-view needs its own @State or is reused across files.
private var headerSection: some View { ... }
private var ctaButton: some View { ... }
```

### Progress dots (shared UI element)
**No codebase analog** — build once, share via a free function or ViewModifier.
**Apply to:** `ConceptBeatView`, `CharacterCreatorView`, `PayoffBeatView`
```swift
// Recommended: a private free function passed the active index (0, 1, 2)
private func progressDots(active: Int) -> some View {
    HStack(spacing: Theme.Spacing.sm) {
        ForEach(0..<3) { i in
            Circle()
                .fill(i == active ? Theme.Colour.accent : Theme.Colour.textSecondary.opacity(0.4))
                .frame(width: i == active ? 8 : 4, height: i == active ? 8 : 4)
        }
    }
}
```

### `#Preview` pattern
**Source:** `LockedIN/App/RootView.swift` lines 136–140; `LockedIN/Design/MoneyLabel.swift` lines 134–153
**Apply to:** All new view files
```swift
#Preview {
    let store = AppStore()
    return SomeView()
        .environment(store)
}
// For component previews that don't need AppStore:
#Preview("All statuses") {
    VStack(spacing: Theme.Spacing.md) {
        AvatarView(appearance: .default, status: .idle, size: 80)
        AvatarView(appearance: .default, status: .focused, size: 80)
    }
    .padding()
    .background(Theme.Colour.background)
}
```

---

## No Analog Found

Files with no close match in the codebase — planner should use RESEARCH.md patterns instead:

| File | Role | Data Flow | Reason | RESEARCH.md Reference |
|------|------|-----------|--------|----------------------|
| `LockedIN/Views/Components/IsometricRoomView.swift` | component | transform | No `Path`-based drawing exists in Phase 1 | Pattern 3 (§Isometric Room) |
| `LockedIN/Views/Onboarding/PayoffBeatView.swift` (PhaseAnimator portion) | component | event-driven | `PhaseAnimator` not used anywhere in Phase 1 | Pattern 5 (§PhaseAnimator Avatar Entrance) |
| `LockedIN/Services/CharacterPersistence.swift` | service | file-I/O | No UserDefaults/JSONEncoder usage in Phase 1 | Pattern 6 (§CharacterAppearance Model + Persistence) |
| `LockedIN/Views/Onboarding/ConceptBeatView.swift` (animation portion) | component | event-driven | `Task.sleep` stagger animation not used in Phase 1 | §ConceptBeatView, Pitfall 4 (Reduce Motion) |

---

## Metadata

**Analog search scope:** `LockedIN/` directory (all Phase 1 files — 7 files total in codebase)
**Files scanned:** 7 (Theme.swift, MoneyLabel.swift, AppStore.swift, RootView.swift, LockedINApp.swift, Participant.swift, Money.swift)
**Pattern extraction date:** 2026-06-13
