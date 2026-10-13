# LockedIN phases and agent delivery plan

Active plan, 2026-10-13. The user requests detailed phases, Builder/Verifier/QC ownership, implementation, local commits and a push to the configured repository `https://github.com/YusufS17/LockedIN`. This supersedes historical build-phase instructions. It does not authorise deployment, production data changes, destructive resets or real payments.

## Team responsibilities

| Role | Responsibility | Finish condition |
| --- | --- | --- |
| Lead / integrator | Choose bounded slices, assign non-overlapping files, integrate flows, inspect renders, maintain handoff, review and push commits | User-visible deliverable with actual evidence and exact remaining limits |
| Builder — persistence | Implement durable saves and session protections while preserving receipt UUIDs and legacy payloads | Meaningful failure/recovery regressions pass |
| Builder — UI | Improve adaptive layouts, labels, honest recovery and visual quality within agreed art direction | Compiles, actual screens inspected, affected journeys checked |
| Verifier | Reproduce bugs, test production models with isolated fixtures, run bounded simulator journeys | Reports command/result/evidence; distinguishes build from interaction pass |
| QC reviewer | Independently review diff, acceptance, data safety, reference fidelity and claims | No unresolved critical finding; limitations recorded |

Builders do not approve their own work alone. Lead serialises simulator/build operations to reduce contention. Verifier/QC can reuse an available agent slot; role names describe responsibilities, not claims of always-running agents. At most four simultaneous agents including lead. No background work is claimed after agents finish.

## Phase 1 — save protection, reliable outcomes and accessible world (locally verified)

**1A World save protection:** distinguish missing, valid legacy/current, unreadable/wrong-type and future-version payloads. Preserve unreadable bytes. Block progression, purchases, placements and reset until recovery. Give clear UI feedback without showing a seeded world as recovered progress. Keep pending results/participant UUID when reward saving is unavailable.

**1B Session validation:** reject contradictory result/clock/configuration fields, preserve existing valid version-1 saves, prevent older checkpoints undoing newer recorded events. Add disposable malformed-save and stale-checkpoint tests; preserve frozen rules and roster IDs.

**1C Accessible world:** semantic fonts, growing cards, wrapping names, single-column district at accessibility sizes, stacked controls/statistics, descriptive VoiceOver labels and close routes. Cover a largest-text World → decorating → World → Home journey with disposable preferences.

**Acceptance:** production-model checks, compatibility/replay tests, app/test-target build, clean diff, independent QC; inspect ordinary/largest-text renders and affected journeys. Simulator timeouts leave interaction acceptance open. No automatic data erasure.

**Completed implementation ownership:** save_builder owns WorldStore/WorldState + existing economy integration tests; accessibility_builder owns WorldView + dedicated UI tests; qc_verifier owns ActiveStudySession/StudySessionStore + dedicated validation tests and later independent review; lead owns recovery call-site integration, planning, build/runtime orchestration and Git.

**Verification outcome:** model/store/service checks and final app/UI build pass. All3 targeted journeys have passing evidence across revised runs; actual normal/large-text/recovery captures inspected. Earlier failures/timeouts and remaining full accessibility/device limits are recorded in [evidence](../docs/verification/save-accessibility-2026-10-13/README.md). Source/evidence pushed through d37d43b; no jobs remain running.

## Phase 2 — offline beta acceptance and remaining engineering hardening

The independent simulated-wallet concurrency slice is implemented: actor-isolated balances/holds and concurrent authorisation/duplicate-settlement regressions pass; independent QC also passed. Other Phase2 acceptance below remains open.

Serialize simulated service state and exercise concurrent holds/settlement. Check onboarding backtracking preserves edits when selecting the same base. Review short task cancellation. Add compact-phone layouts and verify VoiceOver navigation and runtime Reduce Motion toggles. Strengthen test-runner diagnosis without resetting user saves. Establish supported version/migration boundaries and receipt retention policy without sacrificing deduplication.

**Acceptance:** complete offline study/goal/reward/purchase/relaunch loop on current and smaller phone sizes, accessible navigation, safe corruption handling and repeat rewards; physical-device soak test separately documented. Builder fixes reproduced defects, verifier runs journeys, QC compares screenshots and claims.

## Phase 3 — approved character and room craft

Choose/refine the October character direction before changing production proportions. Build standing and seated identities, hair/face expressions, independent tops/bottoms/shoes/accessories and directional poses as editable runtime layers. Improve warm room light, props and coherent furniture perspective. Keep catalogue and saved identities compatible.

**Acceptance:** visible phone-size before/after comparisons with supplied references; normal/dark skin, long/short hair, clothing variation and group seated overlap. Generated flat concepts are not implementation. User character choice is a dependency; preserve existing art while awaiting it.

## Phase 4 — real private friends beta

Select authentication/backend provider and provision a development environment after the user's account/service decision. Implement authenticated admission/invites, private membership, permitted shared subject/goal and aggregate focus state. Add authoritative session transitions, monotonic revisions and reconnect. Preserve participant/reward UUIDs across transport retries.

**Acceptance:** two real accounts/devices share a private room, reconnect after loss, unauthorised users cannot enter/read it, outcomes cannot pay twice. Prototype fixtures remain labelled; no deployment without approval.

## Phase 5 — shared earned room

Persist authoritative per-person outcomes, group contributions, shared furniture ownership/placement and replay-safe purchases. Handle disconnects and retries without false success or duplicate spending. Keep solo progression compatible and separate where the product requires it.

**Acceptance:** two accounts see the same earned upgrade after relaunch/reconnect; duplicate requests cannot mint/spend twice; privacy boundaries hold.

## Phase 6 — native focus controls and device release readiness

Verify current platform capabilities/entitlements from primary Apple documentation. Implement honest permission, override and unsupported-device states. Verify enforcement on actual supported iPhones. Complete device accessibility, interruption/background, privacy and beta-release checks.

**Acceptance:** blocking claims correspond to tested capabilities, private accountability exposes no app/site/message detail, competition stays opt-in. Signing/provisioning/deployment decisions require input; no real-money work.

## Detailed follow-on work packets

[Phase2 offline beta](engineering-phases/02-offline-beta.md) · [Phase3 visual craft](engineering-phases/03-visual-craft.md) · [Phase4 private friends](engineering-phases/04-private-friends.md) · [Phase5 shared progression](engineering-phases/05-shared-progression.md) · [Phase6 device focus](engineering-phases/06-device-focus.md). Each packet gives builder scope, verifier/QC exits and real dependencies. Phase1 scope and current ownership are detailed above.

## Commit and push policy

Each meaningful slice: builder completion → verifier checks → QC diff → lead integration → saved evidence/handoff → local commit → ordinary non-force push. Fetch before pushing; inspect outgoing changes; stop for divergent history rather than overwrite it. Record the actual remote head. Existing pending local milestones are included in the user's push request. Never describe a local commit as remote backup.
