# Project Research Summary

**Project:** LockedIN
**Domain:** iOS SwiftUI multiplayer commitment/accountability app (hackathon prototype)
**Researched:** 2026-06-13
**Confidence:** HIGH

## Executive Summary

LockedIN is a native iOS SwiftUI commitment-device app built in a single ~5-hour hackathon session. The product proves a core loop — commitment contract → social pressure → best-effort tracking → consequence reveal — using three scripted bot participants, a simulated £ wallet, and a deterministic pass/fail rules engine. Comparable products (StickK, Beeminder, Forest, Flora, Focusmate) validate each pillar: frozen contracts are the credibility mechanism, shared monetary stakes create social pressure, deterministic pass/fail outcomes feel fair, and a competitive reveal is the entertainment payoff. No comparable does all four together; that gap is the product's differentiator.

The recommended approach is maximally lean: iOS 17 target, `@Observable` for state management, zero external dependencies, no persistence, `Task`-based bot scripting, `Int` pence for all money, `TimelineView` for the countdown, and protocol boundaries (`CommitmentService`, `FocusControlAdapter`) that make the mock-to-real upgrade path credible without requiring it to be built now. The entire prototype runs on Apple frameworks only and targets a single deterministic demo scenario: the £5 Serious Lock-In, Maya focuses, Leo takes one break, Sam cracks, Sam = Biggest Culprit, £15 returned / £5 forfeited.

The dominant risks are not technical — they are build-order and discipline risks. Scope creep into the custom-contract form, over-engineering the mock layer, and building networking/Stripe are the three demo-day killers. The mitigation is strict: nothing is built unless it is load-bearing for the section-13 demo spine. Foundations (money type, TEST MODE component, service protocols) ship in Hour 1 before any UI is touched, because retroactively changing money representation or adding missing safety labels after four screens are built is the highest-recovery-cost failure mode in the project.

---

## Key Findings

### Recommended Stack

Target iOS 17.0 — the `@Observable` macro is the hard lower bound, and iOS 17 eliminates all `#available` guards from the prototype. Use Swift 5 language mode (not Swift 6 strict) to avoid Sendable concurrency errors that would burn 30–60 minutes without demo value. State is managed by `@Observable`-annotated service classes injected via `.environment()` — no MVVM wrappers, no TCA, no `ObservableObject`. All state is in-memory; no SwiftData, no UserDefaults. Zero third-party dependencies.

**Core technologies:**
- **Swift 5.10 / Xcode 16, iOS 17 target:** Stable API surface, no `#available` guards, `@Observable` support
- **`@Observable` macro:** Fine-grained view invalidation, zero boilerplate, replaces `ObservableObject` entirely
- **`typealias Pence = Int`:** All money as minor units — `500 = £5.00`; never `Double` or `Float`; formatted at display boundaries only
- **`TimelineView(.periodic)`:** SwiftUI-native countdown; no Combine, no `Timer.publish`
- **`Task` / `async/await` / `Task.sleep`:** Bot scripting — deterministic `[(TimeInterval, BotEvent)]` arrays; cancellable; readable
- **`NavigationStack` + `NavigationPath`:** Five-screen push flow; `.fullScreenCover` with `interactiveDismissDisabled(true)` for the interruption overlay
- **`CommitmentService` protocol + `MockCommitmentService`:** Payment boundary; slots Stripe in later without touching session or UI code
- **`FocusControlAdapter` protocol + `MockFocusControlAdapter`:** Tracking boundary; slots real Screen Time adapter in without touching session or UI code

**What NOT to use:** `Double`/`Float` for money, `Timer.publish` + Combine, `ObservableObject` + `@Published`, `NavigationView`, Stripe iOS SDK, `FamilyControls`/Screen Time API, Swift 6 strict concurrency, TCA, SwiftData, any networking.

### Expected Features

**Must have — demo fails without these (all P1):**
- Preset room creation — "£5 Serious Lock-In", single tap, no form, hardcoded `SessionPreset`
- Contract review screen with explicit pass/fail conditions and TEST MODE banner
- Per-participant "Accept and stake £5" — user + 3 bots each accept in sequence
- Contract freeze — visible lock state (lock icon, all edits disabled) after last acceptance
- Scripted bot participants: Maya (focused), Leo (one break), Sam (cracks at ~20 min mark)
- "£20 collectively at stake" display in session header (with "£5 each" breakdown)
- Session countdown timer
- `MockFocusControlAdapter` emitting scripted distraction/break/leave events
- Deterministic pass/fail logic via `ContractRules` pure functions
- Warning/interruption screen with hold-to-confirm and always-visible honest exit
- Wallet state machine: `authorized → held → returned (£15) / forfeited (£5)`
- Results reveal: room totals → LockedIN Champion → Biggest Culprit (Sam + stats) → First to Fold
- Persistent TEST MODE banner on every screen showing a £ amount

**Differentiators to protect — last to cut under time pressure:**
- Contract freeze as a visible UX moment (lock animation, disabled fields) — the product's core idea
- Hold-to-confirm interruption screen — without friction, forfeiture feels trivial
- Stats-backed reveal titles — numbers make competitive titles fair, not mean-spirited

**Defer to post-hackathon:**
- Real FamilyControls / Screen Time integration (MDM entitlement not available in hackathon Xcode project)
- Real-time cross-device multiplayer (WebSocket/Firebase risk cannot be absorbed in 5h)
- Stripe / real-money integration (legal review, KYC, age verification)
- Custom-contract create-room UI (full host configuration form)
- Accountability-partner forfeit settlement

**Defer to v2+:**
- Room prize pool / pot redistribution (`ENABLE_ROOM_PRIZE_POOL=false` — legal review per jurisdiction)
- Sponsored rewards (`ENABLE_SPONSORED_REWARDS` flag exists, flow not built)
- LockedIN-coin cosmetic economy (separate product workstream; never conflate with commitment money)

**Anti-features — never build, never drift toward:**
- Childish punishments (random calls, secret social posts, harassment) — spec explicitly overrides earlier avatar-punishment concept
- Chance-based financial outcomes — legally gambling; undermines deterministic commitment logic
- Live per-name attribution during session — privacy violation; defer individual stats to reveal only
- Exposing app names in distraction events — even in mock; `DistractionEvent` has aggregate fields only
- Cosmetic coins conflated with commitment money — two separate economies, one is out of scope

### Architecture Approach

The architecture has four strict layers: Models (pure value types, zero imports), Services (protocols + mock implementations, no SwiftUI), Engine (`SessionCoordinator` — `@MainActor`, owns session lifecycle, drives bots, calls services, never imports SwiftUI), and UI (observes engine state, never calls services directly). The two protocol boundaries (`CommitmentService`, `FocusControlAdapter`) are the only integration seams between the demo-ready prototype and a production implementation. `CommitmentContract` is a two-phase struct that returns a frozen copy via `.frozen()` — `SessionCoordinator` holds it as a `let` constant, making post-acceptance mutation structurally impossible.

**Major components:**
1. **`CommitmentContract` (frozen struct)** — immutable record of agreed terms; `frozenAt: Date?` encodes the two-phase lifecycle; `MinorUnits = Int` for all stake fields
2. **`SessionCoordinator` (`@MainActor`)** — session state machine (`idle → running → ended`), merges `AsyncStream<FocusEvent>` from all participants via `withTaskGroup`, applies `ContractRules`, drives settlement
3. **`CommitmentService` protocol + `MockCommitmentService`** — hold authorisation, settlement, wallet balance; mock starts each participant at £50 simulated balance; `SettlementRecord.isTestMode = true` drives the UI banner
4. **`FocusControlAdapter` protocol + `MockFocusControlAdapter`** — emits scripted `FocusEvent`s on an offset timeline; one script per participant; Sam's script deterministically crosses the distraction threshold
5. **`ContractRules`** — pure static functions, no state, no imports; `evaluate(metrics:contract:) → SettlementVerdict` and `isApproachingThreshold(metrics:contract:) → Bool`
6. **`BotScriptEngine`** — constructs static `BotScript` definitions (`maya`, `leo`, `sam`); section-13 outcome is fully encoded here
7. **`TitleAssigner`** — maps final metrics to competitive titles (LockedIN Champion / Biggest Culprit / First to Fold)
8. **`TestModeBadge` / `MoneyLabel`** — shared UI components; `MoneyLabel` formats `Pence → "£5.00"` and always appends `TestModeBadge`; built in Hour 1 before any money is displayed

**Layer boundary rules (enforced, no exceptions):**
- UI cannot call `CommitmentService` or `FocusControlAdapter` directly
- Services cannot import SwiftUI
- Models have zero imports
- `FocusControlAdapter` cannot touch `CommitmentService`

**Recommended file structure:**
```
LockedIN/
├── App/          — @main, AppEnvironment (service graph)
├── Models/       — CommitmentContract, Participant, ParticipantMetrics, FocusEvent,
│                   SettlementRecord, ParticipantSettlementState, ContractRules
├── Services/     — CommitmentService (protocol), MockCommitmentService,
│                   FocusControlAdapter (protocol), MockFocusControlAdapter
├── Engine/       — SessionCoordinator, BotScriptEngine, TitleAssigner
└── UI/
    ├── Lobby/    — LobbyView, LobbyViewModel
    ├── Session/  — SessionView, SessionViewModel, ParticipantRowView,
    │               InterruptionWarningView
    ├── Results/  — ResultsView, ResultsViewModel
    └── Shared/   — TestModeBadge, MoneyLabel, ContractCard
```

### Critical Pitfalls

1. **Scope creep into custom-contract UI** — Lock in `SessionPreset.seriousLockIn` as the only entry point in Phase 1; zero `Picker`/`Stepper`/`TextField` for stake or thresholds until the end-to-end spine works. Any time on room-config UI before the spine is demoed is wasted. Recovery cost: HIGH (requires deleting work).

2. **Floating-point money** — Define `typealias Pence = Int` in Phase 1 before any model that holds a stake. Recovery is HIGH cost if caught late. Grep for `var.*Double` and `let.*Float` in money models before Phase 3.

3. **Missing TEST MODE labelling** — Build `TestModeBadge` as the first UI component. Audit each screen individually: contract review, stake authorisation, session header, reveal. Missing it on any screen is a legal and credibility failure.

4. **SwiftUI timer / `@StateObject` lifecycle bugs** — Use `@StateObject` (not `@ObservedObject`) for the session model at the root view that owns it; use `TimelineView(.periodic)` not `Timer.publish`; `@MainActor` on `SessionCoordinator` prevents background-thread publish warnings. Verify the timer runs 2+ minutes without crash before building session UI on top of it.

5. **Over-engineering the mock layer** — `MockFocusControlAdapter` and `MockCommitmentService` are each one file with a hardcoded script array. No Combine subjects, no config enums, no factory. If you find yourself writing `MockFactory`, stop and delete it.

6. **Deceptive or missing emergency exit** — The interruption screen must always show a clearly labelled "End session early (forfeit £5)" path. Use `.fullScreenCover` with `interactiveDismissDisabled(true)`. The honest exit is not optional and takes 20 minutes — do not defer it.

7. **Chance-based bot outcomes** — Sam's failure is a `[(TimeInterval, BotEvent)]` array; no `Bool.random()`, no probability weights. Same demo, same result, every run.

---

## Watch Out For: Demo-Speed Acceleration

**Open question requiring a decision before Phase 2:** The section-13 demo runs a 60-minute session. Bot scripts use absolute `TimeInterval` offsets from session start.

**Recommendation: Hardcode short offsets.** Write Sam's script with short absolute offsets (e.g., Sam cracks at `offsetSeconds: 90`) and set `durationSeconds: 180`. Session genuinely runs for 3 minutes in the demo. No multiplier logic, no constant to forget to revert. Document the "real" offsets as comments in `BotScriptEngine.swift`. This is simpler, has fewer moving parts, and is fully deterministic.

Alternative (runtime multiplier): Divide all offsets by a `demoSpeedFactor` constant — cleaner long-term but adds a moving part that can be misconfigured during a live demo.

---

## Implications for Roadmap

Based on research, the build order is dictated by strict layer dependencies. Nothing in the UI layer is buildable without the Engine; nothing in the Engine is buildable without Models + Services. This maps directly to a 5-phase hourly structure.

### Phase 1: Foundations — Models, Services, Design System (Hour 1)
**Rationale:** Everything else depends on these definitions. Retroactive changes here are the highest-recovery-cost failure in the project. Money type and TEST MODE component must exist before any UI file is written.
**Delivers:** `typealias Pence = Int`; `CommitmentContract` frozen struct; `FocusEvent`, `ParticipantMetrics`, `SettlementRecord`, `ParticipantSettlementState` value types; `ContractRules` pure functions; `CommitmentService` + `MockCommitmentService`; `FocusControlAdapter` + `MockFocusControlAdapter` (with section-13 bot scripts hardcoded); `TestModeBadge` + `MoneyLabel` shared UI components; `SessionPreset.seriousLockIn` hardcoded preset
**Addresses:** Preset-only entry point (no config UI surface), money type safety, TEST MODE labelling system
**Avoids:** Floating-point money, missing TEST MODE labels, scope creep, external dependency creep

### Phase 2: Session Engine (Hour 2)
**Rationale:** `SessionCoordinator` is the critical-path orchestrator — Lobby and Session UI are blocked on it. Must be correct and stable before UI is built on top.
**Delivers:** `BotScriptEngine` (static `maya`/`leo`/`sam` scripts with short demo offsets); `SessionCoordinator` (`@MainActor`, session state machine, `AsyncStream` merge loop, `ContractRules` integration, settlement trigger); `TitleAssigner`
**Uses:** All Models + Services from Phase 1
**Avoids:** Non-deterministic bot outcomes, chance-based results, `@StateObject` lifecycle bugs

### Phase 3: Lobby UI (Hour 3)
**Rationale:** Lobby does not require Engine to be complete — it assembles participants and presents the contract for acceptance. Validates the frozen-contract data model before the coordinator consumes it.
**Delivers:** `AppEnvironment` (mock service injection at app root); `LobbyViewModel`; `ContractCard`; `LobbyView` (preset room, contract review, per-participant accept + stake, contract freeze lock state with lock icon + disabled fields); TEST MODE banner on contract and stake screens; "£20 at stake (£5 each)" display
**Addresses:** Contract freeze visible UX moment; per-participant acceptance sequence
**Avoids:** Missing TEST MODE labels on contract screen; mutable contract after acceptance

### Phase 4: Session UI + Interruption Screen (Hour 4)
**Rationale:** Session UI depends on `SessionCoordinator` publishing live events. Interruption screen must be built here — not deferred — because the honest exit path is a non-negotiable spec requirement and building it last risks running out of time.
**Delivers:** `SessionViewModel`; `ParticipantRowView`; `InterruptionWarningView` (`.fullScreenCover`, `interactiveDismissDisabled(true)`, hold-to-confirm gesture, always-visible labelled forfeit exit); `SessionView` (`TimelineView` countdown, participant list, £20 collective header)
**Implements:** `AsyncStream<FocusEvent>` consumption in SessionView; warning threshold trigger; Sam's interruption sequence
**Avoids:** Missing emergency exit, background-thread publish warnings, timer lifecycle bugs

### Phase 5: Results Reveal + Integration Smoke-Test (Hour 5)
**Rationale:** Results depend on settled wallet state. This phase is also the integration and smoke-test phase — the full section-13 spine must complete end-to-end before submission.
**Delivers:** `ResultsViewModel`; `ResultsView` (sequenced reveal: room totals → LockedIN Champion → Biggest Culprit [Sam + stats] → First to Fold; TEST MODE banner on all settlement amounts); full section-13 end-to-end walkthrough verification
**Addresses:** Stats-backed competitive titles; correct £15 returned / £5 forfeited outcome; no coin economy conflation
**Avoids:** Reveal before settlement is complete, coin/economy conflation, missing TEST MODE on reveal amounts

### Phase Ordering Rationale

- **Dependency chain is rigid:** `Pence` type → service protocols → `SessionCoordinator` → UI. Cannot be shortcut.
- **TEST MODE component ships in Phase 1** because it must be present from the first money-displaying screen — adding it retroactively across four screens is error-prone.
- **Interruption screen is Phase 4, not Phase 5** because the honest exit is a spec requirement and deferring it risks running out of time.
- **Lobby before Session UI** because the contract-freeze transition is simpler and validates the frozen-contract model before the coordinator consumes it.
- **Results last** because it reads from settled `CommitmentService` state — structurally cannot be built until the engine produces settlement records.

### Research Flags

Phases with standard, well-documented patterns (no deeper research needed):
- **Phase 1:** Value types, typealias, protocol definitions — textbook Swift
- **Phase 2:** `@MainActor`, `AsyncStream`, `withTaskGroup` — established SwiftUI concurrency patterns
- **Phase 3:** `NavigationStack`, `.environment()` injection — well-documented
- **Phase 4:** `.fullScreenCover`, `interactiveDismissDisabled`, long-press gesture — standard SwiftUI

Phases that may benefit from a short spike during planning:
- **Phase 5 (sequenced reveal animation):** If title-card reveal requires elaborate staggered sequencing, a 15-minute spike on `withAnimation` + `Task.sleep` sequencing before committing to implementation.
- **Phase 4 (hold-to-confirm gesture):** `LongPressGesture` + `@GestureState` with visual progress feedback is slightly non-obvious — a 10-minute spike before building the full overlay is worth it.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All choices derived from Apple documentation and established SwiftUI patterns; iOS 17 `@Observable` minimum is authoritative |
| Features | HIGH | Spec is detailed and authoritative; comparable product research (StickK, Beeminder, Forest, Flora) is well-documented and maps directly to feature decisions |
| Architecture | HIGH | Layer boundaries and component responsibilities derived directly from spec acceptance criteria; patterns are standard iOS |
| Pitfalls | HIGH | Money representation, timer lifecycle, and `@StateObject` pitfalls are well-documented SwiftUI failure modes; scope-creep and mock over-engineering are well-documented hackathon failure patterns |

**Overall confidence:** HIGH

### Gaps to Address

- **Demo speed factor (decide in Phase 2):** Hardcode short offsets (recommended) vs. runtime multiplier. Encode the decision at the top of `BotScriptEngine.swift` before writing any `Task.sleep` call.
- **Results reveal animation depth (decide in Phase 5):** Spec calls for "sequenced reveal" without specifying animation complexity. Under 5h constraint, simplest path (`withAnimation` + staggered `Task.sleep`) is recommended over elaborate card-flip transitions.
- **Warning trigger ownership (decide in Phase 2):** Coordinator-driven polling of `ContractRules.isApproachingThreshold` vs. dedicated threshold event from mock adapter. Coordinator-driven is simpler and recommended.

---

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` — spec acceptance criteria, section-13 demo requirements, out-of-scope list, ethical hard lines
- Apple Developer Documentation — `@Observable`, `AsyncStream`, `Task.sleep`, `NavigationStack`, `TimelineView`, `@MainActor`

### Secondary (MEDIUM confidence)
- Sarunw — Observation Framework in iOS 17 — `@Observable` minimum iOS requirement
- Hacking with Swift — TimelineView vs `Timer.publish`
- StickK FAQ — commitment contract UX patterns
- Beeminder — Akrasia Horizon — contract freeze rationale
- Forest gamification case study — shared-stake social pressure pattern
- Donny Wals — Swift 6 Migration — Swift 5 language mode recommendation

### Tertiary (MEDIUM-LOW confidence)
- Hackathon post-mortem community experience — scope creep and mock over-engineering as dominant failure modes

---

*Research completed: 2026-06-13*
*Ready for roadmap: yes*
