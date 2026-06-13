# Pitfalls Research

**Domain:** iOS SwiftUI multiplayer commitment/fintech prototype (5-hour hackathon build)
**Researched:** 2026-06-13
**Confidence:** HIGH (spec is authoritative; SwiftUI patterns from well-established knowledge)

---

## Critical Pitfalls

### Pitfall 1: Scope Creep into the Custom-Contract UI

**What goes wrong:**
The full custom-contract creation form (custom stake amounts, custom break allowances, custom distraction thresholds) consumes 2+ hours and is never demoed. The section-13 spine — a preset £5 "Serious Lock-In" with three bots — is the only path that matters. Building even partial config UI before the spine is complete loses the hackathon.

**Why it happens:**
The product concept naturally invites "just add one more field." The custom-contract form feels like the product's identity, so builders default to it. SwiftUI form components also make it feel fast to start.

**How to avoid:**
Lock the preset path first — one hard-coded `SessionPreset.seriousLockIn` value object, no UI sliders or pickers for stake/threshold/breaks. The full config form is explicitly Out of Scope in the spec; do not add a single text field or stepper for it until the spine passes an end-to-end walkthrough.

**Warning signs:**
- Any `Picker`, `Stepper`, or `TextField` for stake amount before the demo spine works end-to-end
- Time spent on "room creation" UI exceeding 30 minutes
- Any discussion of "letting the user configure the break limit"

**Phase to address:**
Phase 1 (Foundation / Session Model) — establish the preset as the only entry point; no config surface

---

### Pitfall 2: Over-Engineering the Mock Layer

**What goes wrong:**
The `MockFocusControlAdapter` and `MockCommitmentService` grow into a mini-framework: configurable injection, protocol hierarchies, combine pipelines, test harness wiring. This is the second most common hackathon time sink after scope creep. The mock only needs to emit the exact scripted sequence for the section-13 demo — Maya focused, Leo one break, Sam cracks — deterministically and repeatably.

**Why it happens:**
Good engineering instincts say "make it testable and swappable." In a 5-hour build, that instinct destroys the timeline. The mock will never be swapped during this build; it only needs to work once, correctly.

**How to avoid:**
Write the mock as a plain struct/class with a hardcoded script array (`[(TimeInterval, BotEvent)]`). No Combine subject trees, no injection config, no protocol hierarchy beyond the single interface boundary (`CommitmentService`, `FocusControlAdapter`) the spec already mandates. If you find yourself writing `MockFactory`, stop.

**Warning signs:**
- More than one file dedicated to the mock layer
- Any `@Published` property on the mock that isn't driven directly from the script
- Writing a mock configuration enum ("slowBot", "fastBot")
- Time on mocks exceeding 45 minutes total

**Phase to address:**
Phase 1 (Foundation) — define the interface; Phase 2 (Session) — implement the minimal script-driven mock inline

---

### Pitfall 3: SwiftUI Timer / State Lifecycle Bugs

**What goes wrong:**
The session countdown timer fires on a background thread or its `Publisher` outlives the `View`, causing `[SwiftUI] Publishing changes from background threads is not allowed` crashes. Alternatively, the `@StateObject` session model is re-initialised on view re-renders, resetting the timer mid-session. Either bug appears only during a live demo.

**Why it happens:**
`Timer.publish` requires explicit `.autoconnect()` and `.receive(on: RunLoop.main)`. `@StateObject` vs `@ObservedObject` confusion is the single most common SwiftUI bug in time-pressure builds — using `@ObservedObject` for the root session object means SwiftUI can recreate and lose it.

**How to avoid:**
- Use `@StateObject` for the session model at the root view that owns the session; pass as `@ObservedObject` or `environmentObject` to children.
- Drive the timer from `Timer.publish(every: 1, on: .main, in: .common).autoconnect()` — never from a background `DispatchQueue`.
- Cancel the timer subscription with `.onDisappear` or in the `deinit` of the view model.
- Test the timer on a physical device or at minimum run it for 60 seconds in simulator before calling it done.

**Warning signs:**
- Using `DispatchQueue.global().asyncAfter` for timer ticks
- Session ViewModel created inside a child View struct (not at root)
- Any console output containing "Publishing changes from background threads"

**Phase to address:**
Phase 2 (Session / Timer) — timer architecture must be correct before the session flow is built on top of it

---

### Pitfall 4: Building Real Networking or Stripe by Accident

**What goes wrong:**
A developer adds `URLSession` calls to a "real API just to see," imports Stripe SDK "to understand the interface," or adds Firebase/Supabase "for later." None of these are needed. Each adds build time, entitlement complexity, and cognitive overhead. Real multiplayer and real payments are explicitly Out of Scope. Even touching them directs attention away from the demo spine.

**Why it happens:**
"I'll just wire up the backend while I wait for the UI to compile." The impulse is productive-feeling but actively harmful in a 5-hour constraint.

**How to avoid:**
No third-party networking or payments SDK in the project at all. `CommitmentService` is a Swift protocol backed only by `MockCommitmentService`. If any external dependency is needed, it must be justified against the section-13 demo walkthrough — if the demo works without it, it is not added.

**Warning signs:**
- Any `import` of Stripe, Firebase, Supabase, or Alamofire
- Any `URLSession.shared.dataTask` call outside of a clearly labelled future-stub file
- SPM package resolution taking more than a few seconds (suggests real dependencies were added)

**Phase to address:**
Phase 1 (Foundation) — the `CommitmentService` mock interface must be the only payment surface defined

---

### Pitfall 5: Inventing Tracking Data (Ethics / Credibility Hard Line)

**What goes wrong:**
The mock emits specific app names ("Safari", "Instagram", "Messages") as distraction causes, or the results reveal shows "you opened WhatsApp 4 times." This is a hard ethical line from the spec: the app must never expose which apps a participant opened. In a real product, that data is private. In a demo, inventing it normalises a deceptive product pattern that would destroy credibility with any technical judge.

**Why it happens:**
App names feel concrete and funny in a reveal screen. The builder thinks "it's just mock data, it's fine." But the spec explicitly prohibits exposing app/usage data even in the mock — the boundary matters for product integrity.

**How to avoid:**
The mock emits only aggregate metrics: distraction count, minutes away, break count, leave-early flag. Zero app names, zero notification contents, zero browsing history, zero contact names. The reveal screen shows "Sam crossed the distraction threshold 3 times" — not "Sam opened Instagram." Label the adapter as `MockFocusControlAdapter` in code to make the boundary explicit.

**Warning signs:**
- Any string constant containing an app name ("Safari", "YouTube", "Instagram", "WhatsApp") in tracking output
- Any `appName: String` property on a distraction event model
- Results reveal screen showing per-app breakdown

**Phase to address:**
Phase 2 (Tracking / Mock Adapter) — the distraction event model must be defined without app-name fields from the start

---

### Pitfall 6: Deceptive or Missing Emergency Exit

**What goes wrong:**
The "interruption" hold-to-confirm screen is designed to create friction — that is correct. But if there is no visible honest exit path (e.g., the button label is "I give up (forfeit £5)" but actually does something else, or there is no exit at all), or if the UI implies the app has locked the device in a way it cannot, the demo fails the spec's honesty requirement and raises a red flag with any investor or judge evaluating it.

**Why it happens:**
The commitment mechanic makes builders want to maximise friction. The line between "meaningful friction" and "deceptive lock" is thin. Omitting the exit entirely is the most common shortcut under time pressure.

**How to avoid:**
The interruption screen must always show a clearly labelled "End session early (forfeit stake)" path that works. The hold-to-confirm gesture adds friction but must resolve to a real exit. Label must be honest about the consequence. Never grey out or hide this button. This takes 20 minutes to implement correctly and must not be deferred.

**Warning signs:**
- Interruption screen with no exit button at all
- Button labelled "Exit" that is disabled or zero-opacity
- Exit path that navigates nowhere or crashes
- Any `isHidden` or `opacity(0)` on the exit button

**Phase to address:**
Phase 2 (Session / Interruption Screen) — implement exit path at the same time as the interruption screen, not after

---

### Pitfall 7: Missing or Inconsistent TEST MODE Labelling

**What goes wrong:**
Money amounts (£5 stake, £15 returned, £5 forfeited) appear without the persistent "TEST MODE — NO REAL MONEY WILL MOVE" label on one or more screens. During a demo, this creates a false impression that real money is at risk, which is both legally problematic and a credibility failure with judges who will ask "is that real money?"

**Why it happens:**
The label is added to the wallet screen but forgotten on the contract acceptance screen, the session header, and the reveal. Each screen is built separately.

**How to avoid:**
Create a single `TestModeBanner` SwiftUI component in Phase 1 and mandate its presence in any view that shows a currency amount. Make it impossible to miss — persistent top or bottom banner, not a small footnote. Write a simple checklist: contract screen, stake authorisation, session header, reveal screen — every one must carry the banner.

**Warning signs:**
- Any `Text("£\(amount)")` without `TestModeBanner` in the same view hierarchy
- Reveal screen showing "£15 returned" with no test mode context
- The banner being added "at the end" — it should be the first UI component built

**Phase to address:**
Phase 1 (Foundation / Design System) — `TestModeBanner` is the first component built, before any money amount is displayed

---

### Pitfall 8: Floating-Point Money Representation

**What goes wrong:**
Stake amounts are stored as `Double` (e.g., `5.0`, `15.0`). Under arithmetic operations (splitting the forfeited £5 across three passing bots), floating-point rounding produces `£4.999999999` or display anomalies. In a fintech-adjacent demo, this is an immediate credibility failure.

**Why it happens:**
`Double` is the default Swift numeric type. "It's just mock data" makes it feel harmless. The spec explicitly mandates minor units, but this is easy to overlook when typing `let stake = 5.0`.

**How to avoid:**
Define `typealias Pence = Int` (or `struct Money: Equatable { let pence: Int }`) in Phase 1. All stake values, wallet balances, and settlement amounts are `Pence` throughout the codebase. Display formatting is the only place conversion happens: `String(format: "£%.2f", Double(pence) / 100.0)`. Never store or compute money as `Double`.

**Warning signs:**
- Any `var stake: Double` or `let amount: Float` in a model
- Any `5.0` or `0.05` literal in session or payment logic
- `NumberFormatter` with currency style applied to a `Double` balance

**Phase to address:**
Phase 1 (Foundation / Data Model) — `Money`/`Pence` type defined before any model that holds a stake amount

---

### Pitfall 9: Chance-Based Financial Outcomes

**What goes wrong:**
Pass/fail is determined by a random element — "Sam has a 70% chance of cracking" — instead of deterministic contract rules applied to scripted bot behaviour. The spec is explicit: outcomes are never chance-based. If a judge asks "what decides who forfeits?" and the answer involves randomness, the product is unsound. Additionally, non-deterministic bots make the demo unrepeatable, which is a demo-day disaster.

**Why it happens:**
Randomness feels natural for scripted bots. `Bool.random()` is one line. "It's just a demo" masks the architectural problem.

**How to avoid:**
Sam's failure is encoded in the script: at T+18min Sam crosses the distraction threshold for the third time (or whatever the contract specifies), and `deterministic pass/fail` logic fires. The `MockFocusControlAdapter` script is a `[(TimeInterval, BotEvent)]` array — no randomness, no probability weights. The same demo plays out identically every run.

**Warning signs:**
- Any `Bool.random()`, `Int.random()`, or `Double.random()` in bot or session logic
- Bot behaviour described as "probability of distraction" rather than "scripted events"
- Results that differ between demo runs

**Phase to address:**
Phase 2 (Bot Script / Mock Adapter) — script must be deterministic from first implementation

---

### Pitfall 10: Conflating the Two Economies

**What goes wrong:**
Commitment money (the £5 stake, real-feeling, returned or forfeited) is displayed alongside or confused with LockedIN coins (cosmetic, non-withdrawable). A judge asks "can I withdraw those coins?" and the answer is unclear. Or worse: the UI implies coins are a form of financial stake. The spec is explicit that these are separate economies; only economy A (commitment money) is in the prototype.

**Why it happens:**
The broader product vision mentions coins, and a builder adds a "you earned 50 coins" line to the reveal screen "to show the full vision." This muddies the demo.

**How to avoid:**
Zero mention of LockedIN coins in the prototype UI. The reveal screen shows only: stake returned/forfeited amounts, session stats, and player titles. If coins are mentioned at all, they must be clearly labelled "coming soon" and visually separated from the commitment wallet. In the 5-hour build, the safest choice is to omit them entirely.

**Warning signs:**
- Any `coin`, `lockedInCoin`, or `reward` variable in the prototype data model
- Reveal screen showing a coin amount alongside a £ amount without clear separation
- Any UI element that could imply coins are withdrawable

**Phase to address:**
Phase 3 (Reveal / Results Screen) — results screen review must confirm no coin/economy conflation

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode the section-13 bot script | Saves 1h of configuration work | Can't demo other scenarios | Always acceptable for the hackathon |
| Single `SessionViewModel` doing everything | Avoids architecture overhead | Hard to test or extend | Acceptable if `CommitmentService` interface boundary is clean |
| `TestModeBanner` as a plain `Text` view, not a full component | 5 min to implement | Inconsistent across screens | Never — make it a reusable component from the start |
| Skip unit tests entirely | Saves 30+ min | No regression safety | Acceptable given 5h constraint; manual walkthrough is the test |
| Use `@EnvironmentObject` for session state | Simple to thread through view tree | Tight coupling if over-used | Acceptable for session model; avoid for domain models |
| `Double` for display-only currency formatting | Convenient | Looks sloppy if rounding shows | Never for stored values; `Double` is only acceptable at the display layer after converting from `Pence` |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `Timer.publish` | Firing on background thread, causing SwiftUI publish warnings | Always use `Timer.publish(every:, on: .main, in: .common).autoconnect()` |
| `@StateObject` session model | Using `@ObservedObject` at the root view, causing re-init on re-render | `@StateObject` at the view that owns the session lifetime; `@ObservedObject` for children |
| `CommitmentService` protocol | Calling the real (unimplemented) conformance by accident | Use a compile-time flag or `#if DEBUG` guard; `MockCommitmentService` must be the only conformance in the prototype build |
| SwiftUI `.sheet` / `.fullScreenCover` for interruption screen | Sheet dismissed by swipe gesture, bypassing hold-to-confirm | Use `.fullScreenCover` with `interactiveDismissDisabled(true)` so only the explicit "End session" action can dismiss |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Re-rendering entire session view on every timer tick | Jank at 60fps countdown; battery drain in demo | Isolate the timer label into its own `View` with only the time as its input; use `@Binding` not `@EnvironmentObject` for the clock | Immediately visible at demo; affects any screen with a running timer |
| Storing bot event history in a growing array without cap | Memory grows during long sessions | Cap event history at last N events for display; bots emit only scripted events so total count is bounded | Not a real risk in 5h demo, but can cause slow list re-renders |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing app names in distraction events (even mock) | Normalises a privacy-violating product pattern; credibility failure with technical judges | Define `DistractionEvent` with only aggregate fields: `count: Int`, `timestamp: Date`, `severity: DistractionSeverity` — no `appName`, no `bundleId` |
| Displaying test wallet balance without TEST MODE banner | Implies real financial risk; legally and ethically problematic | `TestModeBanner` must be present in every view that shows a `£` amount — enforce via code review of each screen before submission |
| Confusing `ENABLE_REAL_MONEY_STAKES=false` flag with a runtime toggle | Flag could be flipped by mistake, implying real settlement | Keep flag as a compile-time constant (`#if REAL_MONEY_ENABLED`), not a `UserDefaults` bool |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Contract acceptance screen missing explicit pass/fail conditions | Users (and judges) don't understand what they're agreeing to | Contract screen must enumerate the exact thresholds: "3 distractions = fail, 2 breaks allowed, leaving early = immediate forfeit" — these are the core of the product |
| Interruption screen friction so high it appears broken | Judge tries to exit and can't find the button; thinks the app is locked | Always-visible "End session (forfeit £5)" text link below the hold gesture; friction is the gesture, not the discoverability |
| Reveal screen shows data without narrative | Feels like a spreadsheet, not an entertainment moment | Lead with the crowning title ("Sam — Biggest Culprit") before the numbers; numbers are the evidence, not the headline |
| "£20 collectively at stake" shown without clear per-person breakdown | Confusing: is it £20 each? | Always pair the room total with the per-person amount: "£20 at stake (£5 each)" |

---

## "Looks Done But Isn't" Checklist

- [ ] **Session timer:** Runs for full contract duration without crashing — verify by letting it run 2 minutes in simulator with all three bots active
- [ ] **Bot script:** Sam crosses the failure threshold at the right moment AND the UI responds (distraction count increments, warning fires) — verify via section-13 walkthrough
- [ ] **Contract immutability:** Host cannot change stake or thresholds after all participants accept — verify by attempting to modify session model post-acceptance
- [ ] **TEST MODE banner:** Present on contract screen, stake authorisation confirmation, session header, AND reveal screen — verify each screen individually
- [ ] **Emergency exit:** "End session early" button on interruption screen navigates correctly to forfeiture result — verify by tapping it deliberately
- [ ] **Money in minor units:** `Money(pence: 500)` is `£5.00` — verify with a unit test or REPL check before reveal screen is built
- [ ] **Reveal correctness:** Maya and Leo get £5 returned, Sam forfeits £5; room shows "£15 returned / £5 forfeited" — verify with section-13 walkthrough
- [ ] **No app names in output:** Search codebase for "Safari", "Instagram", "WhatsApp", "Messages" — zero results in any model or view
- [ ] **No `Double` in money model:** Search codebase for `var.*Double` and `let.*Float` in any file touching stake/wallet/settlement — zero results

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Timer crashes discovered late | MEDIUM | Replace with simpler `DispatchQueue.main` repeating timer in the ViewModel; costs 30 min |
| Scope crept into custom-contract UI with 2h left | HIGH | Hard-cut all custom UI, restore preset-only path; requires deleting work which is psychologically hard — prevent rather than recover |
| Mock layer too complex to debug | MEDIUM | Delete and rewrite as a plain struct with hardcoded `[(TimeInterval, BotEvent)]` array; costs 45 min |
| TEST MODE label missing from reveal screen | LOW | Add `TestModeBanner()` to the reveal view — 5 min fix but requires remembering to do it |
| `Double` money discovered in model | HIGH (if late) | Requires changing every money-touching model and view; migrate early — this is why the type alias must be defined in Phase 1 |
| App names appear in distraction events | MEDIUM | Remove `appName` field from event model and update all usages — costs 30 min plus requires checking all views that display event data |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Scope creep into custom-contract UI | Phase 1 | No Picker/Stepper/TextField for stake or thresholds in codebase after Phase 1 |
| Over-engineering mock layer | Phase 1 (interface) + Phase 2 (implementation) | Mock is a single file, no factory, no config enum |
| SwiftUI timer/state lifecycle bugs | Phase 2 | Timer runs 2+ minutes without crash or re-init |
| Building real networking/Stripe | Phase 1 | Zero external package dependencies beyond Apple frameworks |
| Inventing tracking data / exposing app names | Phase 2 | `DistractionEvent` model has no `appName` field; grep confirms no app name strings |
| Deceptive or missing emergency exit | Phase 2 | Interruption screen always shows labelled exit path; verified manually |
| Missing TEST MODE labelling | Phase 1 (component) + Phase 3 (audit) | `TestModeBanner` present on all money screens |
| Floating-point money | Phase 1 | `typealias Pence = Int` defined; no `Double` in money model |
| Chance-based outcomes | Phase 2 | Bot script is a static array; no `random()` calls in session or bot logic |
| Conflating two economies | Phase 3 | Reveal screen contains zero coin references |

---

## Sources

- PROJECT.md spec (authoritative): hard ethical lines, Out of Scope list, section-13 demo requirements, minor-unit mandate, data privacy requirements
- SwiftUI known issues: `@StateObject` vs `@ObservedObject` lifecycle (Swift documentation, well-established); `Timer.publish` threading (Swift concurrency documentation)
- Hackathon post-mortem patterns: scope creep and over-engineering mock layers are the two dominant failure modes in constrained iOS builds (HIGH confidence from well-documented community experience)
- Fintech UI patterns: floating-point currency is a well-documented anti-pattern with a well-documented fix (minor units + integer arithmetic) — HIGH confidence

---
*Pitfalls research for: iOS SwiftUI multiplayer commitment prototype (LockedIN hackathon build)*
*Researched: 2026-06-13*
