# Phase 2 — dependable offline beta

Prerequisite: Phase1 code and production-model checks, plus truthful documentation of any pending runtime acceptance. Roles below are future responsibilities, not background jobs. Lead controls integration and simulator scheduling.

| Slice | Builder work / files | Verifier and QC exit |
| --- | --- | --- |
| 2A simulated wallet safety | Actor-isolate `MockCommitmentService`; retain protocol/init compatibility. Implemented in current run. | `ServiceBoundaryChecks`: competing holds cannot overdraw; duplicate settlements cannot refund twice; both verdicts conserve funds. Builder and independent QC checks passed. |
| 2B robust runtime checks | `Tests/run-ui-checks.py`, dedicated World/recovery tests: bounded process lifetime, evidence on failed navigation, isolated cleanup, deliberate test size/device selection. | Actual screenshot/journey results; timeout is recorded as blocked, never passed. No unrelated process killing or simulator data erasure. |
| 2C identity backtracking | `CharacterGalleryView`/`OnboardingHostView`: preserve confirmed edits when returning to the same base; make choosing a different base an explicit reset of draft appearance. Preserve independent clothing axes and purchased unlocks. | Confirm draft survives back/forward and relaunch where already saved; new base still works; no silent purchase refund/removal. Inspect normal/largest-text onboarding. |
| 2D task and lifecycle cleanup | Onboarding/results short async animation tasks; review cancellation on dismiss/relaunch. Keep recorded results independent of animation completion. | Dismiss/reopen cannot start a second award or keep abandoned work running. Targeted lifecycle checks instead of tests mirroring delay code. |
| 2E accessible compact phones | World/Home/editors/setup/results at a smaller existing iPhone destination; reachable close, focus, break and results actions. | Largest-text plus smaller-phone renders, VoiceOver order/labels/actions, real Reduce Motion toggling. Record physical-device checks separately. |
| 2F storage lifetime | Define valid economy ranges, receipt retention/archive strategy and save format evolution; keep raw payload backups/recovery semantics non-destructive. | Old version1 rewards/identity remain valid; no duplicate award after archive/reload. Concurrent independent writer support remains separate architecture work. |

Finish: usable local beta with complete study → results → earned item → relaunch evidence, accessible controls, no save erasure, no duplicate progress. A compile is not enough. Physical-device soak acceptance requires an available signed device; do independent simulator/model work first.

Decision/limit: full multiplayer and native enforcement are later phases; simulations remain labelled. No real payments or deployment.
