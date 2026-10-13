# LockedIN engineering audit and delivery plan

Reviewed 2026-10-13 against the app sources, Xcode project, regression suites, tooling and saved verification evidence. This is the current engineering plan; historical phase files remain reference material. The latest user request authorises autonomous maintenance and independent agent reviews, with approval required for deployment, destructive actions and production-data changes.

## Architecture and dependencies

Native SwiftUI iPhone application, iOS 17 minimum, Swift 5 language mode. Xcode filesystem-synchronised groups include app sources and the separate UI test target. No third-party package dependencies are declared. Platform frameworks include SwiftUI, Foundation, Observation and UIKit; builds require macOS/Xcode.

`LockedINApp` creates one observable `AppStore` and injects it into the view tree. `RootView` routes onboarding or Home using the injected preferences store. `AppStore` owns identity, `WorldStore`, `StudySessionStore` and mock service boundaries.

Solo and labelled demo clubs use `StudySessionFlowView`: setup → saved focus/break → private goal check → results. `ActiveStudySession` freezes rules and roster identity; `FocusClock` uses deadlines and accumulated break timing. `StudySessionStore` restores checkpoints. `WorldStore` records receipts keyed by the user participant UUID, rewards completed sessions and saves earned progression, purchases and room placements together. Identity and active-session payloads are separate UserDefaults records, so this is local persistence, not a transaction across all stores or cloud backup.

PixelKit authors grids/material palettes, shades and bakes small UIKit images through `PixelRenderer`, caches them in `SpriteBakery`, and displays independent room, furniture and avatar layers. `LiveRoomScene` handles seating, occlusion, status and multiple areas for 2–8 demo participants. Customisation retains independent appearance axes and fixed room slots. Generated character boards are concepts only.

The optional `RoomFlowView` commitment demonstration is reachable from Home's More options menu. `MockCommitmentService` uses an in-memory simulated wallet; no real money moves. `MockFocusControlAdapter` emits scripted events; the current persisted study flow records timer time and explicit self-reports rather than native app activity. `Tools/FriendsPrototype` is an isolated contract prototype outside the app target, not an authenticated multiplayer service.

## Current features and limits

Implemented: six-step onboarding; avatar editor; room decorating and earned catalogue purchases; personal world/building progression; solo and demo-club setup; deadlines, pause/resume and restoration; goal review; reward deduplication; labelled simulated companions and per-person demo study intent.

Saved simulator evidence covers onboarding, largest-text main journeys/editors, independent garments, session restoration, rewards, purchases and club areas. Those historical results do not verify new edits. Physical-device testing, comprehensive VoiceOver, runtime accessibility-setting changes and smaller-phone acceptance remain open.

Unimplemented: real authentication/invites/presence/reconnect, authoritative shared room rewards/furniture, native focus enforcement and production backend. Final avatar/room reference fidelity is unfinished; the October 12 character direction is still unapproved.

## Confirmed defects addressed in this maintenance milestone

- Debug identity self-check deleted the ordinary saved identity. It now uses a unique disposable preferences suite and removes only that suite.
- Negative building prices could increase coins. Construction rejects negative prices before mutation; insufficient funds and repeat construction are checked.
- Unknown cosmetic and furniture IDs were treated as owned/free purchases. Catalogue membership is now required.
- A forged simulated hold reference could reuse a valid ID with another amount or participant. Settlement now validates the entire authorised reference before consuming it.
- Termination of an old focus stream could cancel a replacement for the same participant. Each monitor now has its own generation, with atomic replacement and cancellation outside the lock.
- Avatar breathing started a perpetual animation only on appearance, ignoring later Reduce Motion changes. Playback now derives motion from the live environment.
- Reduced-motion sparkles left static particles at the centre. Reduced Motion now renders no particles; decorative bursts are hidden from VoiceOver.
- Character model comments incorrectly promised automatic PNG integration. Comments now describe the actual procedural renderer.

## Remaining technical issues, ordered by priority

1. World save corruption can silently fall back to a seeded world and subsequent mutations can overwrite the unreadable payload. Add non-destructive recovery semantics and disposable migration/corruption checks before expanding economy persistence.
2. Session validation should be strengthened for contradictory result fields and stale checkpoint rollback. Current identity/rule protection and normal restoration tests do not establish resilience to every malformed payload or concurrent writer.
3. World UI uses fixed-point `Theme.TypeScale` fonts and fixed-height district tiles. Extend accessibility typography/layouts and inspect largest-text world renders. Smaller-phone and VoiceOver journeys need dedicated acceptance.
4. Legacy simulated stakes authorise at results and have no durable session-level settlement ledger. Keep explicitly simulated; do not extend them into real payments.
5. Feature flags for test stakes, prize pools and sponsored rewards lack integrated readers. Do not present them as functional switches.
6. Onboarding gallery backtracking can reset staged customisation when confirming the same base. Decide whether returning to the same selection should preserve the draft before changing product behaviour.
7. Short animation tasks sometimes ignore cancellation. Review view-disappearance cleanup when touching those surfaces.
8. Mock commitment balances/holds are mutable class dictionaries without actor or lock isolation. Current sequential fixture passes do not establish concurrent-call safety. Serialize this boundary and test concurrent authorisation/settlement before introducing concurrent clients.
9. Reward receipts have no pruning/archive policy and grow with completed sessions; retain deduplication guarantees when planning longer-term storage. Wall-clock adjustments also affect deadline timers.

## Milestones and acceptance

| Milestone | Deliverable | Acceptance / dependencies |
| --- | --- | --- |
| A — audit and safe maintenance | Architecture map, confirmed defect fixes, regression coverage and truthful handoff | Production-model/service checks, app build, diff review; inspect changed UI where simulator is available |
| B — save protection and accessibility | Preserve unreadable world saves; strengthen malformed/stale session validation; accessible world layouts | Disposable failure/recovery tests, smaller-phone/large-text renders, VoiceOver and Reduce Motion runtime checks |
| C — approved visual refinement | Chosen avatar family and richer room craft implemented as editable layers | User character-direction decision; standing/seated/customisation phone renders compared with references |
| D — genuine private friends | Authenticated private membership, invites, shared intent, authoritative sessions and reconnect | Provider/account decision and service provisioning; two actual accounts/devices; identity/reward replay checks |
| E — shared earned room and native focus | Persistent shared upgrades and supported focus controls | Server purchase/reward retry tests; platform capability review, permissions and physical-device verification |

A is the current authorised implementation slice. B follows independently of art choice. C requires a real visual decision; D requires external service/account decisions. No deployment, remote push, production migration or real-payment work is authorised by this plan.

Verification for this run is recorded in PROGRESS.md and .planning/STATE.md. Reproducible commands are in Tests/README.md. Local commits are not remote backup.
