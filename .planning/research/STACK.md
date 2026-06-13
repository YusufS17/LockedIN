# Stack Research

**Domain:** Native iOS SwiftUI — multiplayer commitment/accountability app (hackathon prototype)
**Researched:** 2026-06-13
**Confidence:** HIGH

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 5.10 (Swift 6 compiler, Swift 5 language mode) | Primary language | Swift 6 compiler ships with Xcode 16 but strict concurrency mode adds friction in a 5h build; keep SWIFT_VERSION=5, get the compiler speed without data-race errors slowing you down |
| SwiftUI | iOS 17+ API surface | UI framework | All required primitives (NavigationStack, sheet, TimelineView, @Observable) are stable and non-deprecated on iOS 17; no #available guards needed for the demo spine |
| Observation (`@Observable` macro) | iOS 17+ (Swift 5.9+) | State management | The lightest correct choice for shared mutable state in SwiftUI 2025: no `@Published` boilerplate, fine-grained view invalidation, zero external dependencies. Replaces ObservableObject wholesale |
| Swift Concurrency (`async/await`, `Task`, `Task.sleep`) | Swift 5.5+ / iOS 15+ | Bot scripting, timer events | Native, no library needed; `Task.sleep(for: .seconds(N))` drives deterministic bot event sequences with readable, cancellable code |
| Foundation (`Formatter`, `Date`, `Calendar`) | iOS 17 | Time math, currency display | `Date` arithmetic for session clock; `Measurement`/`NumberFormatter` for £ display from minor units; no third-party needed |

### Minimum Deployment Target

**iOS 17.0.** Rationale:
- `@Observable` macro requires iOS 17 — this is the single hardest API lower bound in the stack.
- `NavigationStack` + `NavigationPath` (required for clean modal flows) available from iOS 16; iOS 17 supersedes that.
- `TimelineView(.periodic)` available from iOS 15, well within range.
- Targeting iOS 17 means zero `#available` guards in any prototype code — every modern API Just Works.
- In 2025, iOS 17 adoption is above 90% globally, so this is a practical target even post-hackathon.

### State Management — Plain `@Observable` (No MVVM wrapper, No TCA)

**Decision: `@Observable`-annotated service/model classes injected via `.environment()`. No explicit ViewModel layer, no TCA.**

Rationale against alternatives:

| Pattern | Verdict | Reason |
|---------|---------|--------|
| **Plain `@Observable` classes** | **USE THIS** | Zero setup cost; SwiftUI tracks exactly which properties each view reads, re-renders only what changed; one class per domain (SessionStore, WalletStore, RoomStore) is sufficient for a demo with 5 screens |
| MVVM (ViewModel per screen) | Skip | Adds a boilerplate layer with no payoff — SwiftUI views are already view-models in the `@Observable` model. You'd spend 30-45 min writing ViewModel shells that add nothing |
| TCA (The Composable Architecture) | Hard no | Steep learning curve, heavy boilerplate (Reducer, Store, Action enum per feature), 15-20 min dependency installation, no benefit for a single-device scripted demo. Excellent for large teams/long-lived apps; wrong tool here |
| ObservableObject + @Published | Skip | Deprecated pattern as of iOS 17; causes over-rendering; `@Observable` is strictly better and ships with the OS |

### Persistence — In-Memory Only (No SwiftData, No UserDefaults)

**Decision: No persistence. All state lives in `@Observable` class instances held in the app's root `@State`.**

The demo is scripted and deterministic. The app does not need to survive process death:
- The hackathon judge runs the app, taps through the section-13 demo spine, sees the reveal.
- There is no "resume after backgrounding" requirement in scope.
- Adding SwiftData adds a model container, migration logic, and `@Query` plumbing — all 30-60 min overhead with no user-facing benefit.
- UserDefaults is appropriate for individual settings (e.g. a user preference flag); it is not appropriate for structured relational data like session participants + contract + wallet state.

**If persistence becomes needed post-hackathon:** SwiftData (iOS 17+) is the correct upgrade path. The `@Observable` store classes map cleanly to `@Model` classes. This upgrade can happen without touching UI code if the service boundary is respected.

### Money Representation — `Int` Minor Units (Pence)

**Decision: All monetary amounts stored as `Int` representing pence (£1.00 = 100). Never `Double`, never `Float`.**

```swift
typealias Pence = Int   // £5.00 = 500, £20.00 = 2000

// Display only — format at the boundary
func formatGBP(_ pence: Pence) -> String {
    let pounds = Decimal(pence) / 100
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "GBP"
    return formatter.string(from: pounds as NSDecimalNumber) ?? "£0.00"
}
```

Rationale:
- `Double` cannot exactly represent 0.1 or 0.3; floating-point rounding errors in financial displays erode trust instantly.
- `Int` arithmetic is exact, trivially diffable, and Codable without precision loss.
- The project spec explicitly requires minor-unit storage (acceptance criterion #15).
- No external Money library needed — the type alias + one formatter function covers all display needs.

### Session Timer — `TimelineView(.periodic)` + Stored `Date` Deadline

**Decision: Store session end `Date` in `SessionStore`; use `TimelineView(.periodic(from:by:1.0))` for per-second UI updates. No `Timer.publish`, no `Combine`.**

```swift
// In SessionStore (@Observable)
var sessionEndDate: Date = .now.addingTimeInterval(3600) // 60 min

// In View
TimelineView(.periodic(from: .now, by: 1.0)) { context in
    let remaining = max(0, sessionEndDate.timeIntervalSince(context.date))
    CountdownDisplay(seconds: Int(remaining))
}
```

Rationale:
- `TimelineView` is the SwiftUI-native, power-efficient replacement for `Timer.publish` + `Combine`. Apple recommends it explicitly for clocks/countdowns.
- Storing a `Date` deadline (not a countdown counter) is robust to backgrounding/foreground transitions without any extra work.
- `Timer.publish` requires Combine import and a `@Published` sink — unnecessary complexity.
- `DispatchSourceTimer` or `CADisplayLink` are UIKit-era approaches; wrong layer.

### Bot Scripting — `async/await` Task sequences with `Task.sleep`

**Decision: Each bot runs as a `Task` launched at session start, executing a fixed script of `(waitDuration, event)` pairs.**

```swift
// BotScript: value type, deterministic
struct BotEvent {
    let offsetSeconds: TimeInterval
    let action: ParticipantAction  // enum: .distracted, .tookBreak, .leftEarly
}

// Scripted sequence for "Sam cracks"
let samScript: [BotEvent] = [
    BotEvent(offsetSeconds: 300, action: .distracted),
    BotEvent(offsetSeconds: 720, action: .tookBreak),
    BotEvent(offsetSeconds: 1800, action: .leftEarly)
]

// Runner in SessionStore
func runBotScript(_ script: [BotEvent], for participant: Participant) {
    Task { @MainActor in
        let start = Date()
        for event in script {
            let delay = start.addingTimeInterval(event.offsetSeconds).timeIntervalSinceNow
            guard delay > 0 else { continue }
            try? await Task.sleep(for: .seconds(delay))
            applyEvent(event.action, to: participant)
        }
    }
}
```

Rationale:
- Pure Swift, no library, no network, fully deterministic.
- `Task.sleep(for:)` (Duration-based API, Swift 5.7+, iOS 16+) is non-blocking, cooperative, and cancellable.
- Scripts are value types — easy to unit test, swap, or accelerate for a demo (divide all offsets by 60 for a 1-minute demo run).
- Cancellation: store returned `Task` references in `SessionStore`; call `.cancel()` on session end.

### Navigation — `NavigationStack` + `NavigationPath` + `sheet`

**Decision: Single `NavigationStack` at app root with a `NavigationPath` router; modal overlays (contract acceptance, interruption warning) as `.sheet` or `.fullScreenCover`.**

The section-13 demo spine requires approximately 5 screens:
1. Lobby / room preview
2. Contract review + accept
3. Live session (timer, participant list)
4. Interruption warning (modal)
5. Results reveal

`NavigationStack` with enum-typed routes handles the push flow cleanly. No third-party router needed.

### `CommitmentService` Interface (Mock Implementation)

**Decision: Protocol-based service boundary. `MockCommitmentService` used in the prototype; `StripeCommitmentService` slots in later without touching UI or session code.**

```swift
protocol CommitmentService {
    func authoriseStake(amount: Pence, participantId: UUID) async throws -> StakeAuthorisation
    func settleStake(_ authorisation: StakeAuthorisation, outcome: StakeOutcome) async throws
}

// Prototype
final class MockCommitmentService: CommitmentService { ... }

// Future
// final class StripeCommitmentService: CommitmentService { ... }
```

Rationale: The spec requires this boundary explicitly (acceptance criterion #14). It costs 30 minutes to define correctly and prevents a full rewrite when real money is needed.

### `FocusControlAdapter` Interface (Mock Implementation)

Same pattern as CommitmentService:

```swift
protocol FocusControlAdapter {
    func startMonitoring() async
    func stopMonitoring()
    // Publishes DistractionEvent via AsyncStream or callback
}

final class MockFocusControlAdapter: FocusControlAdapter { ... }
// Future: RealScreenTimeFocusControlAdapter (FamilyControls framework)
```

---

### Supporting Libraries

**None required.** The entire prototype runs on Apple frameworks only.

| Library | Status | Reason |
|---------|--------|--------|
| Stripe iOS SDK | Out of scope | No real money; `MockCommitmentService` replaces it; adds 10 min install + 30 min setup minimum |
| Alamofire / URLSession wrappers | Out of scope | No networking in the prototype at all |
| TCA / swift-composable-architecture | Out of scope | Overkill; adds 15 min install + steep learning curve |
| Combine | Out of scope | `@Observable` + `async/await` covers all reactive needs without importing Combine |
| SwiftData | Deferred | Not needed for scripted demo; use if persistence added post-hackathon |
| Firebase / Supabase | Out of scope | Real-time multiplayer is explicitly out of scope |
| Lottie | Optional only | If animation budget exists after core loop ships; not a dependency |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 16.x | IDE, build, simulator | Use iOS 17 simulator target to match deployment target; Swift 5 language mode (not Swift 6 strict) to avoid concurrency errors during rapid iteration |
| Swift Package Manager | Dependency management | No packages needed for the prototype; SPM is available if a future dependency is added |
| Xcode Previews | Rapid UI iteration | Works perfectly with `@Observable` — inject mock `SessionStore` directly into preview; no extra setup |
| Instruments (Time Profiler) | Performance validation | Only needed if frame drops observed; unlikely for a 5-screen prototype |

---

## Installation

No package dependencies. Create a new SwiftUI project in Xcode 16:

```
File → New → Project → iOS App → SwiftUI interface → Swift language
Set Minimum Deployments: iOS 17.0
```

No `Package.swift` additions needed for the hackathon prototype.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Plain `@Observable` | MVVM (ViewModel per screen) | When you have 10+ screens, complex per-screen logic, or a team where ViewModel is an established convention — not a 5h solo build |
| Plain `@Observable` | TCA | Large production apps with multiple contributors, where testability and traceability of state mutations justify the boilerplate cost |
| `TimelineView` | `Timer.publish` + Combine | When you need sub-second precision or event-driven (non-periodic) updates; overkill for a 1-second countdown |
| In-memory `@State` | SwiftData | When the app must survive backgrounding/termination, or has relational data queries; add this post-hackathon |
| `Int` pence | `Decimal` | `Decimal` is correct for financial math at scale, but adds formatting complexity; `Int` pence is exact and simpler for the prototype |
| iOS 17.0 target | iOS 16.0 target | If you need to support users below iOS 17 post-launch — add `@available` guards around `@Observable` usage |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `Double` / `Float` for money | Floating-point imprecision corrupts display values; £0.10 + £0.20 ≠ £0.30 in IEEE 754 | `Int` pence (minor units) |
| `Timer.publish` + Combine | Requires Combine import, sink lifecycle management, and `@Published` — 3x the code for the same result | `TimelineView(.periodic)` |
| `ObservableObject` + `@Published` | Deprecated iOS 17 pattern; causes full-view re-renders on any property change | `@Observable` macro |
| `NavigationView` | Deprecated iOS 16; replaced by `NavigationStack` | `NavigationStack` + `NavigationPath` |
| Stripe iOS SDK | 10 min install, 30+ min setup, requires backend secret, legal overhead — none of which exist in the prototype | `MockCommitmentService` protocol impl |
| `FamilyControls` / Screen Time API | Requires MDM entitlement provisioning (not available in a hackathon Xcode project), user approval flow, parent/guardian flows — hours of setup for zero demo value | `MockFocusControlAdapter` emitting scripted events |
| Swift 6 strict concurrency mode | `Sendable` conformance errors on `@Observable` classes will burn 30-60 min of the 5h budget | Keep `SWIFT_VERSION = 5` in project settings |
| Heavy DI containers (Needle, Swinject) | Container registration, factory boilerplate, and learning curve with zero benefit over passing `@Observable` stores via `.environment()` | `.environment()` with `@Observable` stores |
| `UserDefaults` for session state | Not designed for structured/relational data; no type safety; awkward to serialize participant arrays | In-memory `@Observable` classes (no persistence needed) |
| Real networking (WebSocket, Multipeer) | Real-time multiplayer is explicitly out of scope; adds hours of debugging for zero demo payoff | `Task`-based scripted bot sequences |

---

## Stack Patterns by Variant

**For the hackathon demo (section-13 spine):**
- Single `@Observable` `AppStore` holding `SessionStore`, `WalletStore`, `RoomStore`
- Inject via `.environment(appStore)` at the root `WindowGroup`
- Bot tasks launched from `SessionStore.startSession()`, cancelled from `SessionStore.endSession()`
- All money as `Pence = Int`, formatted at display boundaries only

**If adding real persistence post-hackathon:**
- Annotate model classes with `@Model` (SwiftData)
- Add `ModelContainer` to `WindowGroup`
- `CommitmentService` and `FocusControlAdapter` protocols unchanged

**If adding real money post-hackathon:**
- Implement `StripeCommitmentService: CommitmentService`
- Add Stripe iOS SDK via SPM
- No other code changes required (CommitmentService boundary holds)

**If adding real focus tracking post-hackathon:**
- Implement `RealScreenTimeFocusControlAdapter: FocusControlAdapter`
- Requires `com.apple.developer.family-controls` entitlement
- No other code changes required (FocusControlAdapter boundary holds)

---

## Version Compatibility

| Component | iOS Minimum | Notes |
|-----------|-------------|-------|
| `@Observable` macro | iOS 17.0 | Hard lower bound for the stack |
| `NavigationStack` + `NavigationPath` | iOS 16.0 | Available, iOS 17 target covers it |
| `TimelineView(.periodic)` | iOS 15.0 | Available, iOS 17 target covers it |
| `Task.sleep(for: .seconds())` (Duration API) | iOS 16.0 | Available, iOS 17 target covers it |
| Swift 5.9 macro support | Xcode 15+ | Required for `@Observable`; Xcode 16 is current |
| SwiftData (if added later) | iOS 17.0 | Aligns perfectly with the chosen deployment target |

---

## Is Any Persistence Needed for the Scripted Demo?

**No.** The section-13 demo is a single deterministic run:
1. Open app → select preset → bots join → session runs → reveal fires
2. There is no "save and resume" requirement
3. There is no "history of past sessions" requirement
4. The judge re-runs the demo by force-quitting and reopening — the scripted bots always produce the same outcome

Adding persistence would cost 30-60 minutes and deliver zero visible value during the demo. Deliberately skip it and mark it as a known post-hackathon upgrade.

---

## Sources

- [Observation Framework in iOS 17 — Sarunw](https://sarunw.com/posts/observation-framework-in-ios17/) — `@Observable` minimum iOS requirement confirmed HIGH confidence
- [SwiftUI's New @Observable: Clean State Management for iOS 17+ — Medium](https://medium.com/@somasharma95/swiftuis-new-observable-clean-state-management-for-ios-17-73802342ed41) — fine-grained invalidation behavior MEDIUM confidence
- [TimelineView in SwiftUI — SwiftProgramming](https://swiftprogramming.com/timelineview-swiftui/) — periodic scheduler for countdowns HIGH confidence
- [How to use a timer with SwiftUI — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-a-timer-with-swiftui) — Timer.publish comparison MEDIUM confidence
- [Mastering NavigationStack and NavigationPath in SwiftUI — Medium](https://medium.com/@mhamdouchi/mastering-navigationstack-and-navigationpath-in-swiftui-32c2b38cbc2b) — NavigationStack pattern HIGH confidence
- [Task.sleep Apple Developer Documentation](https://developer.apple.com/documentation/swift/task/sleep(nanoseconds:)) — Task.sleep API HIGH confidence
- [Swift 6 Migration — Donny Wals](https://www.donnywals.com/enabling-concurrency-warnings-in-xcode/) — Swift 5 language mode recommendation for active projects MEDIUM confidence
- [@AppStorage vs UserDefaults vs SwiftData — BleepingSwift](https://bleepingswift.com/blog/appstorage-vs-userdefaults-vs-swiftdata) — persistence tier comparison MEDIUM confidence
- [Decimal in Swift — Yakov Manshin](https://yakovmanshin.com/2023/04/decimal-in-swift/) — currency representation rationale MEDIUM confidence
- Project spec (`.planning/PROJECT.md`) — constraints, out-of-scope list, acceptance criteria HIGH confidence (primary source)

---

*Stack research for: LockedIN — native iOS SwiftUI hackathon prototype*
*Researched: 2026-06-13*
