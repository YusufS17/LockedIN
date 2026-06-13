# Architecture Research

**Domain:** iOS SwiftUI multiplayer commitment/study app (hackathon prototype)
**Researched:** 2026-06-13
**Confidence:** HIGH — derived directly from spec acceptance criteria; no external ecosystem uncertainty

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│  UI LAYER  (SwiftUI Views + ViewModels)                             │
│  ┌──────────────┐  ┌────────────────┐  ┌──────────────────────┐    │
│  │  LobbyView   │  │  SessionView   │  │    ResultsView       │    │
│  │  + ViewModel │  │  + ViewModel   │  │    + ViewModel       │    │
│  └──────┬───────┘  └───────┬────────┘  └──────────┬───────────┘    │
│         │                  │                       │                │
│  FORBIDDEN: UI never calls CommitmentService directly               │
├─────────────────────────────────────────────────────────────────────┤
│  SESSION ENGINE  (SessionCoordinator — @MainActor ObservableObject) │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  SessionCoordinator                                           │  │
│  │  - Owns session state machine (idle→running→ended)           │  │
│  │  - Drives bot timeline via BotScriptEngine                   │  │
│  │  - Receives FocusEvents from FocusControlAdapter             │  │
│  │  - Applies ContractRules to compute participant metrics      │  │
│  │  - Calls CommitmentService only at settlement trigger points │  │
│  └───────────────────────────────────────────────────────────────┘  │
├──────────────────────────┬──────────────────────────────────────────┤
│  SERVICES LAYER          │                                          │
│  ┌───────────────────┐   │  ┌──────────────────────────────────┐   │
│  │ CommitmentService │   │  │    FocusControlAdapter           │   │
│  │ (protocol)        │   │  │    (protocol)                    │   │
│  │                   │   │  │                                  │   │
│  │ MockCommitment-   │   │  │    MockFocusControlAdapter       │   │
│  │ Service (impl)    │   │  │    (scripted event emitter)      │   │
│  └───────────────────┘   │  └──────────────────────────────────┘   │
│                          │                                          │
│  FORBIDDEN: Services     │  FORBIDDEN: Adapter never touches        │
│  never import SwiftUI    │  CommitmentService or settlement         │
├──────────────────────────┴──────────────────────────────────────────┤
│  MODEL LAYER  (value types, no behaviour, no imports)               │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │ CommitmentContract│ │Participant   │  │ SettlementRecord      │  │
│  │ (frozen struct) │  │ Metrics      │  │ FocusEvent            │  │
│  └─────────────────┘  └──────────────┘  └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Forbidden From |
|-----------|----------------|----------------|
| `CommitmentContract` | Immutable record of agreed terms (amount, duration, thresholds) | Mutating itself after `freeze()` |
| `SessionCoordinator` | Owns session lifecycle, bot clock, distraction accounting, calls CommitmentService at end | Directly rendering UI; importing SwiftUI |
| `CommitmentService` (protocol + mock) | Authorise hold, settle pass/fail, query wallet balance | Knowing anything about session state or UI |
| `FocusControlAdapter` (protocol + mock) | Emit `FocusEvent`s on a timeline | Knowing about settlement; importing CommitmentService |
| `BotScriptEngine` | Tick scripted bot timelines, emit synthetic `ParticipantAction`s | Contacting any external source |
| `ContractRules` | Pure functions: given metrics + contract, return pass/fail verdict | Having any state |
| `LobbyViewModel` | Assemble participants, present contract for acceptance | Calling settlement; mutating contract post-freeze |
| `SessionViewModel` | Observe `SessionCoordinator` published state, translate for display | Driving bot logic directly |
| `ResultsViewModel` | Present final metrics, titles, wallet changes | Re-computing settlement; replaying session |

---

## Layer Boundaries (Enforced)

```
UI  ──can call──▶  SessionCoordinator  ──can call──▶  CommitmentService
UI  ──can call──▶  SessionCoordinator  ──receives──▶  FocusControlAdapter
UI  ──CANNOT──▶  CommitmentService  (direct call forbidden)
UI  ──CANNOT──▶  FocusControlAdapter  (direct call forbidden)
CommitmentService  ──CANNOT──▶  SessionCoordinator  (no circular deps)
FocusControlAdapter  ──CANNOT──▶  CommitmentService
Models  ──CANNOT──▶  anything  (pure value types, zero imports)
```

---

## CommitmentContract: Enforced Immutability

Use a two-phase struct with a private `isFrozen` flag plus compile-time protection via the type system.

```swift
// Models/CommitmentContract.swift

struct CommitmentContract {
    let id: UUID
    let roomName: String
    let durationSeconds: Int
    let stakeMinorUnits: Int          // 500 = £5.00 — never Double
    let maxDistractionSeconds: Int
    let maxBreaks: Int
    let allowedBreakDurationSeconds: Int
    let currencyCode: String          // "GBP"
    let createdAt: Date
    private(set) var frozenAt: Date?

    // Only mutable before freeze
    var isFrozen: Bool { frozenAt != nil }

    // Returns a new frozen copy — original remains unfrozen during lobby
    func frozen() -> CommitmentContract {
        var copy = self
        copy.frozenAt = Date()
        return copy
    }
}

// ContractMutation is only possible through a builder, never through
// direct property mutation on a frozen contract.
// SessionCoordinator holds a `let contract: CommitmentContract` (frozen copy)
// ensuring no code path can mutate it after session start.
```

Rule: `SessionCoordinator` is initialised with a `frozen()` copy. `LobbyViewModel` holds the mutable draft. Once every participant has accepted and `SessionCoordinator.start()` is called, the draft is discarded. The coordinator's `contract` property is `let`, not `var`.

Money is always `Int` (minor units). A `MoneyAmount` typealias or lightweight wrapper enforces this at call sites:

```swift
typealias MinorUnits = Int   // 500 == £5.00
// Never: Double, Float, Decimal for stake arithmetic
```

---

## CommitmentService Protocol + Mock

```swift
// Services/CommitmentService.swift

protocol CommitmentService: AnyObject {
    // Called once per participant when they accept the contract
    func authoriseHold(
        participantID: UUID,
        amountMinorUnits: MinorUnits,
        contract: CommitmentContract
    ) async throws -> HoldReference

    // Called by SessionCoordinator at session end, per participant
    func settle(
        holdRef: HoldReference,
        verdict: SettlementVerdict       // .passed / .failed
    ) async throws -> SettlementRecord

    // UI balance display only — read-only
    func walletBalance(participantID: UUID) async -> MinorUnits
}

struct HoldReference: Identifiable, Hashable {
    let id: UUID
    let participantID: UUID
    let amountMinorUnits: MinorUnits
}

struct SettlementRecord {
    let holdRef: HoldReference
    let verdict: SettlementVerdict
    let returnedMinorUnits: MinorUnits
    let forfeitedMinorUnits: MinorUnits
    let settledAt: Date
    let isTestMode: Bool               // always true in prototype — drives UI label
}
```

```swift
// Services/MockCommitmentService.swift

@MainActor
final class MockCommitmentService: CommitmentService {
    // Simulated wallet: starts at £50 per participant in test mode
    private var balances: [UUID: MinorUnits] = [:]
    private var holds: [UUID: HoldReference] = [:]

    private let startingBalance: MinorUnits = 5_000  // £50.00

    func authoriseHold(
        participantID: UUID,
        amountMinorUnits: MinorUnits,
        contract: CommitmentContract
    ) async throws -> HoldReference {
        // Deduct from simulated balance (hold semantics)
        balances[participantID, default: startingBalance] -= amountMinorUnits
        let ref = HoldReference(id: UUID(), participantID: participantID, amountMinorUnits: amountMinorUnits)
        holds[ref.id] = ref
        return ref
    }

    func settle(holdRef: HoldReference, verdict: SettlementVerdict) async throws -> SettlementRecord {
        let returned: MinorUnits = verdict == .passed ? holdRef.amountMinorUnits : 0
        let forfeited: MinorUnits = verdict == .failed ? holdRef.amountMinorUnits : 0
        if verdict == .passed {
            balances[holdRef.participantID, default: 0] += returned
        }
        return SettlementRecord(
            holdRef: holdRef,
            verdict: verdict,
            returnedMinorUnits: returned,
            forfeitedMinorUnits: forfeited,
            settledAt: Date(),
            isTestMode: true
        )
    }

    func walletBalance(participantID: UUID) async -> MinorUnits {
        balances[participantID, default: startingBalance]
    }
}
```

The `MockCommitmentService` is injected via the app's environment object / `@EnvironmentObject` at app root. The protocol type is what `SessionCoordinator` holds — never the concrete mock type.

---

## FocusControlAdapter Protocol + Mock

```swift
// Services/FocusControlAdapter.swift

protocol FocusControlAdapter: AnyObject {
    /// Start monitoring. Events are emitted via the AsyncStream.
    func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent>
    func stopMonitoring(participantID: UUID)
}

enum FocusEvent {
    case distractionStarted(participantID: UUID, at: Date)
    case distractionEnded(participantID: UUID, at: Date)
    case breakStarted(participantID: UUID, at: Date)
    case breakEnded(participantID: UUID, at: Date)
    case leftSession(participantID: UUID, at: Date)
    // No app names, URLs, or notification content — ever
}
```

```swift
// Services/MockFocusControlAdapter.swift

// Scripted timeline entry — offset from session start
struct ScriptedFocusEvent {
    let offsetSeconds: Double
    let event: FocusEvent
}

final class MockFocusControlAdapter: FocusControlAdapter {
    // Injected at construction; one script per participant
    private let scripts: [UUID: [ScriptedFocusEvent]]
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(scripts: [UUID: [ScriptedFocusEvent]]) {
        self.scripts = scripts
    }

    func startMonitoring(participantID: UUID) -> AsyncStream<FocusEvent> {
        let script = scripts[participantID] ?? []
        return AsyncStream { continuation in
            let task = Task {
                let sessionStart = Date()
                for entry in script.sorted(by: { $0.offsetSeconds < $1.offsetSeconds }) {
                    let delay = entry.offsetSeconds - Date().timeIntervalSince(sessionStart)
                    if delay > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                    if Task.isCancelled { break }
                    continuation.yield(entry.event)
                }
                continuation.finish()
            }
            self.tasks[participantID] = task
        }
    }

    func stopMonitoring(participantID: UUID) {
        tasks[participantID]?.cancel()
        tasks[participantID] = nil
    }
}
```

The bot script for Sam (Biggest Culprit) is defined as a `[ScriptedFocusEvent]` array injected at app startup. This script is the single source of truth for the section-13 demo outcome — deterministic and repeatable.

---

## Settlement State Machine

Each participant's stake follows this explicit state machine. Stored in `ParticipantSettlementState` enum — never a String.

```
not_required
     │  (participant accepted contract + hold authorised)
     ▼
awaiting_authorisation
     │  (MockCommitmentService.authoriseHold returns HoldReference)
     ▼
held
     │  ◄─── session is live; stake frozen in simulated wallet
     │
     ├─── session ends: ContractRules.evaluate() returns .passed
     │         ▼
     │      authorised_for_return
     │         │  (CommitmentService.settle(.passed) called)
     │         ▼
     │      returned   ✓  (terminal)
     │
     └─── session ends: ContractRules.evaluate() returns .failed
               ▼
           authorised_for_forfeit
               │  (CommitmentService.settle(.failed) called)
               ▼
           forfeited   ✗  (terminal)

Error path (settle call throws):
     held ──▶ settlement_error  (show error UI; retry available)
```

```swift
enum ParticipantSettlementState: Equatable {
    case notRequired
    case awaitingAuthorisation
    case held(ref: HoldReference)
    case authorisedForReturn(ref: HoldReference)
    case authorisedForForfeit(ref: HoldReference)
    case returned(record: SettlementRecord)
    case forfeited(record: SettlementRecord)
    case settlementError(ref: HoldReference, error: String)
}
```

State transitions are enforced by `SessionCoordinator` — only it may drive the state machine forward. UI observes the state; it never writes to it.

---

## BotScriptEngine

Drives scripted participants without networking. Reads from a static `BotScript` definition.

```swift
struct BotScript {
    let participantID: UUID
    let displayName: String
    let avatarSeed: String
    let focusEvents: [ScriptedFocusEvent]
    // Verdict pre-determined by script; ContractRules still validate
}

// Canonical section-13 demo scripts (constructed once at app launch)
extension BotScript {
    static let maya = BotScript(...)   // stays focused entire session
    static let leo  = BotScript(...)   // one short break ~15 min in
    static let sam  = BotScript(...)   // exceeds distraction limit → forfeited
}
```

`SessionCoordinator` iterates all participants (user + bots), opens an `AsyncStream<FocusEvent>` per participant from `FocusControlAdapter`, and merges them via a `withTaskGroup` loop. Bot streams come from `MockFocusControlAdapter`; the user's stream also comes from `MockFocusControlAdapter` (scripted as "passes" for the demo, meaning the real user appears as LockedIN Champion).

---

## ContractRules (Pure Functions)

```swift
// Models/ContractRules.swift

enum SettlementVerdict: Equatable { case passed, failed }

struct ParticipantMetrics {
    let participantID: UUID
    let totalDistractionSeconds: Int
    let breakCount: Int
    let longestBreakSeconds: Int
    let leftEarly: Bool
}

enum ContractRules {
    static func evaluate(
        metrics: ParticipantMetrics,
        contract: CommitmentContract
    ) -> SettlementVerdict {
        if metrics.leftEarly { return .failed }
        if metrics.totalDistractionSeconds > contract.maxDistractionSeconds { return .failed }
        if metrics.breakCount > contract.maxBreaks { return .failed }
        return .passed
    }

    static func isApproachingThreshold(
        metrics: ParticipantMetrics,
        contract: CommitmentContract
    ) -> Bool {
        // Used to trigger the warning interruption screen
        let remaining = contract.maxDistractionSeconds - metrics.totalDistractionSeconds
        return remaining < 60 && remaining > 0
    }
}
```

No state. No imports. Pure input → output. Tested trivially. `SessionCoordinator` calls these; UI calls nothing here directly.

---

## Data Flow During a Session

```
[Timer tick / Bot clock]
        │
        ▼
MockFocusControlAdapter  ──AsyncStream<FocusEvent>──▶  SessionCoordinator
                                                               │
                                                    updates ParticipantMetrics
                                                               │
                                              ContractRules.isApproachingThreshold?
                                                               │  YES
                                                               ▼
                                                    publishes warningState
                                                               │
                                                      SessionViewModel observes
                                                               │
                                                               ▼
                                                    SessionView shows interruption screen

[Session timer expires or all bots done]
        │
        ▼
SessionCoordinator.endSession()
        │
        ├──▶  ContractRules.evaluate(metrics, contract) → SettlementVerdict per participant
        │
        ├──▶  CommitmentService.settle(holdRef, verdict) per participant
        │              │
        │              ▼
        │       ParticipantSettlementState transitions → .returned / .forfeited
        │
        └──▶  publishes sessionPhase = .results
                       │
                       ▼
             ResultsViewModel assembles:
               - Room totals (collective £ at stake)
               - Individual SettlementRecord per participant
               - Title assignment (LockedIN Champion / Biggest Culprit / First to Fold)
               - TEST MODE badge on every money figure
```

---

## Recommended Project Structure

```
LockedIN/
├── App/
│   ├── LockedINApp.swift          # @main; builds and injects service graph
│   └── AppEnvironment.swift       # Holds CommitmentService + FocusControlAdapter instances
│
├── Models/
│   ├── CommitmentContract.swift   # Frozen struct; MinorUnits typealias
│   ├── Participant.swift          # Participant value type (id, name, isBot)
│   ├── ParticipantMetrics.swift   # Accumulated focus/distraction counters
│   ├── FocusEvent.swift           # FocusEvent enum
│   ├── SettlementRecord.swift     # HoldReference, SettlementRecord, SettlementVerdict
│   └── ParticipantSettlementState.swift  # Full state machine enum
│
├── Services/
│   ├── CommitmentService.swift    # Protocol only
│   ├── MockCommitmentService.swift
│   ├── FocusControlAdapter.swift  # Protocol only
│   ├── MockFocusControlAdapter.swift
│   └── ContractRules.swift        # Pure static functions
│
├── Engine/
│   ├── SessionCoordinator.swift   # @MainActor ObservableObject; owns session lifecycle
│   ├── BotScriptEngine.swift      # Script definitions + timeline driving
│   └── TitleAssigner.swift        # Maps metrics → titles (Champion/Culprit/Fold)
│
└── UI/
    ├── Lobby/
    │   ├── LobbyView.swift
    │   └── LobbyViewModel.swift
    ├── Session/
    │   ├── SessionView.swift
    │   ├── SessionViewModel.swift
    │   ├── ParticipantRowView.swift
    │   └── InterruptionWarningView.swift  # Hold-to-confirm overlay
    ├── Results/
    │   ├── ResultsView.swift
    │   └── ResultsViewModel.swift
    └── Shared/
        ├── TestModeBadge.swift    # Reusable "TEST MODE" label — shown near every money figure
        ├── MoneyLabel.swift       # Formats MinorUnits → "£5.00"; always appends TEST badge
        └── ContractCard.swift     # Read-only frozen-contract display
```

### Structure Rationale

- **Models/:** Zero dependencies. Safe to import anywhere. Value types only.
- **Services/:** Protocol files import only Models. Mock implementations import only Models + Foundation.
- **Engine/:** Imports Models + Services (via protocols). Never imports SwiftUI.
- **UI/:** Imports Engine (observes published state) and Models (for display). Never imports Services directly.

---

## Architectural Patterns

### Pattern 1: Protocol-First Service Injection

**What:** Define `CommitmentService` and `FocusControlAdapter` as protocols. Inject concrete implementations (always Mock for this prototype) at app root. `SessionCoordinator` holds protocol-typed properties.

**When to use:** Mandatory here — acceptance criterion #15 requires payment logic to be swappable.

**Trade-offs:** Tiny overhead (one extra file per protocol) for huge payoff: `StripeCommitmentService` slots in without touching SessionCoordinator or any UI.

### Pattern 2: @MainActor ObservableObject for SessionCoordinator

**What:** `SessionCoordinator` is `@MainActor final class` conforming to `ObservableObject`. All `@Published` properties update UI automatically. Async work inside the coordinator uses structured concurrency (`async/await`, `withTaskGroup`).

**When to use:** Single-device SwiftUI app with async event streams — the natural fit.

**Trade-offs:** All state updates on main thread = no data races; cost is that heavy computation must be explicitly offloaded (not an issue for this domain).

### Pattern 3: AsyncStream for FocusEvent Delivery

**What:** `FocusControlAdapter.startMonitoring` returns `AsyncStream<FocusEvent>`. `SessionCoordinator` consumes it with `for await event in stream { }`. Backpressure is handled by the stream buffer.

**When to use:** Timer-driven scripted event emission — cleaner than delegates/callbacks.

**Trade-offs:** Requires iOS 15+; cancellation is clean via `Task.cancel()`; no third-party dependencies.

---

## Anti-Patterns

### Anti-Pattern 1: UI Calling CommitmentService Directly

**What people do:** Put a `settle()` call in a button action inside `ResultsView`.

**Why it's wrong:** Violates acceptance criterion #15; makes settlement untestable in isolation; prevents clean Stripe swap.

**Do this instead:** `ResultsViewModel` observes `SessionCoordinator.settlementStates: [UUID: ParticipantSettlementState]`. Settlement is already done by the time Results is shown. ViewModel only reads final `SettlementRecord` values.

### Anti-Pattern 2: Floating-Point Money

**What people do:** Store `stake: Double = 5.0` or `stake: Decimal`.

**Why it's wrong:** Floating-point arithmetic on currency is a correctness bug; `Decimal` is slower and unnecessary.

**Do this instead:** `stake: MinorUnits = 500`. Format for display only in `MoneyLabel`. Never use Double/Float for stake arithmetic.

### Anti-Pattern 3: Mutable Contract After Acceptance

**What people do:** Allow `LobbyViewModel` to hold the same `CommitmentContract` reference that `SessionCoordinator` uses.

**Why it's wrong:** Any mutation after session start violates the "frozen contract" requirement. User trust depends on this.

**Do this instead:** Call `contract.frozen()` at the moment the last participant accepts. Pass the frozen copy to `SessionCoordinator` as a `let` constant. The lobby's draft copy is discarded.

### Anti-Pattern 4: SessionCoordinator Knowing About UI Phases

**What people do:** Add `showResultsView = true` or navigation state into the coordinator.

**Why it's wrong:** Couples session logic to navigation; breaks layer boundary.

**Do this instead:** Coordinator publishes `sessionPhase: SessionPhase` (`.lobby / .running / .ended`). Navigation is driven by `@State` in the parent view observing this published value.

---

## Build Order (5-Hour Budget)

Dependencies determine order. Each step below is a prerequisite for the next.

```
Hour 1 — Models + Services (no UI yet; everything else depends on this)
  ├── CommitmentContract.swift  (frozen struct, MinorUnits typealias)
  ├── FocusEvent.swift
  ├── ParticipantMetrics.swift
  ├── SettlementRecord.swift + ParticipantSettlementState.swift
  ├── ContractRules.swift  (pure functions; validates the state machine logic)
  ├── CommitmentService.swift  (protocol)
  ├── MockCommitmentService.swift
  ├── FocusControlAdapter.swift  (protocol)
  └── MockFocusControlAdapter.swift  (with section-13 Sam/Maya/Leo scripts)

Hour 2 — Session Engine (depends on Models + Services)
  ├── BotScriptEngine.swift  (constructs static scripts, nothing else)
  ├── SessionCoordinator.swift  (session lifecycle, async event loop, settlement)
  └── TitleAssigner.swift  (Champion / Culprit / Fold logic)

Hour 3 — Lobby UI (depends on Models; does NOT need Engine to be complete)
  ├── AppEnvironment.swift  (injects Mock services into environment)
  ├── LobbyViewModel.swift  (assembles participants, presents contract)
  ├── ContractCard.swift
  ├── LobbyView.swift
  └── TestModeBadge.swift + MoneyLabel.swift  (shared; needed by all money UI)

Hour 4 — Session UI (depends on Engine)
  ├── SessionViewModel.swift
  ├── ParticipantRowView.swift
  ├── InterruptionWarningView.swift  (hold-to-confirm overlay for Sam)
  └── SessionView.swift

Hour 5 — Results UI + polish (depends on Engine settlement output)
  ├── ResultsViewModel.swift
  ├── ResultsView.swift  (room totals → individual reveals → wallet change)
  └── Integration smoke-test: full section-13 flow end to end
```

**Critical path:** `CommitmentContract` → `MockCommitmentService` + `MockFocusControlAdapter` → `SessionCoordinator` → `SessionView` → `ResultsView`. If time runs short, cut polish (animations, typography) not the critical path.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Rule |
|----------|---------------|------|
| UI ↔ Engine | `@Published` properties on `SessionCoordinator` | One-way: Engine writes, UI reads |
| Engine ↔ CommitmentService | `async throws` method calls | Engine calls service; service never calls engine |
| Engine ↔ FocusControlAdapter | `AsyncStream<FocusEvent>` | Adapter emits; engine consumes |
| UI ↔ Models | Direct value-type access | Read-only; no mutation from UI |
| LobbyViewModel ↔ SessionCoordinator | Lobby creates coordinator and calls `start()` once | After `start()`, lobby has no reference |

### External Services

| Service | Status | Integration Pattern |
|---------|--------|---------------------|
| Stripe | Out of scope for prototype | `StripeCommitmentService: CommitmentService` — implement when real money is needed |
| Screen Time / FamilyControls | Out of scope | `ScreenTimeFocusAdapter: FocusControlAdapter` — implement when real tracking is needed |

---

## Sources

- LockedIN PROJECT.md — spec acceptance criteria, especially criterion #15 (separation requirement) and money-in-minor-units constraint
- Apple Swift Concurrency documentation — AsyncStream, TaskGroup, @MainActor
- SwiftUI architecture conventions — ObservableObject, @Published, EnvironmentObject injection
- Accepted iOS pattern: protocol-based dependency injection at app root for testability and swappability

---

*Architecture research for: iOS SwiftUI multiplayer commitment/study app (hackathon prototype)*
*Researched: 2026-06-13*
