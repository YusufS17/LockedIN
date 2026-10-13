---
status: phase1_verification
last_updated: "2026-10-13"
stopped_at: "Phase 1 integrated; final validation, build and runtime verification in progress; push authorised"
---

# Current handoff

## Read first

[Progress overview](../PROGRESS.md) · [Active roadmap](ROADMAP.md) · [Interface details](../docs/INTERFACE_PASS.md)

This replaces the stale June phase tracker. The original is preserved in [archive/STATE-2026-06-13.md](archive/STATE-2026-06-13.md). Do not resume June phase 02-03 merely because an old file says to.

## Restored original context

The user re-supplied the morning request and attached GPT brief on 2026-09-27. Read [USER_DIRECTION.md](../docs/USER_DIRECTION.md) and the verbatim [PRODUCT_BRIEF_ORIGINAL.md](../docs/PRODUCT_BRIEF_ORIGINAL.md). The original prompt was not available in the resumed conversation until this point. Preserve this distinction; do not claim memory of unseen material. The next priority remains making the app visible, then assessing art against the user’s references and completing the coherent local loop.

## User direction

Continue building the native iPhone app, preserve existing work and make progress visible. Keep current-stage notes, roadmaps and handoffs saved as Markdown. Current product direction is room-centred, warm cream, cosy rooms, customisable characters and supportive study by default. The old hackathon deadline is no longer the active constraint.

## Last completed work

- Recovered September interface handoff and preserved the accumulated local changes.
- Verified the current app builds and clock/reward checks pass.
- Added Codable reward receipts to WorldState and backward-compatible decoding for older saves.
- WorldStore returns the original receipt for repeated results; balances, streaks and building contributions are not awarded twice.
- Added isolated UserDefaults injection and `Tests/WorldRewardChecks.swift` to verify the real store/save/reward implementation with UI/catalog fixtures.
- Rebuilt the app successfully and passed duplicate-reward, reload, distinct-session, demo/exit, migration and reset checks.
- Created the root progress overview and refreshed this handoff and the roadmap.

## Active phase — 2026-10-13

[Detailed phases and agent responsibilities](PHASES_AND_AGENTS.md) is the active plan. User authorised next-phase implementation, delegation, commits and push to existing origin `https://github.com/YusufS17/LockedIN`; remote fetched successfully. This supersedes older statements that push requires destination confirmation. Deployment/destructive changes/production data remain unapproved.

Phase1 implements non-destructive world-save recovery, pending-result retention, monotonic session checkpoints/consistent outcomes and accessible World layouts. Builders finished their slices; QC/verifier and lead integration verification are running. New tests use disposable suites. Final build-for-testing/model/runtime checks and commit/push evidence are pending. Do not claim completion from previous screenshots or fixture passes.

## Engineering continuation — 2026-10-13

The user now requests lead-engineer ownership, whole-codebase review, a milestone plan, autonomous safe fixes, relevant tests and supported delegation. [Engineering audit and milestone plan](../docs/ENGINEERING_AUDIT.md) is the current implementation guide; older numbered phases remain historical.

Three agent reviews are finished; no agents remain running. Maintenance changes protect debug identity fixtures, catalogue purchases/construction prices, authorised simulated holds and replacement focus monitors; avatar/sparkle motion now responds to Reduce Motion. Character concepts remain unapproved and are not production assets.

Actual checks: clock, reward rules, persistent world rewards, production study integration, area mapping, simulated services and 83 private-friends fixtures passed. Debug app build and build-for-testing passed with simulator-service access; initial sandbox build failed at asset compilation because simulator services were unavailable. Bounded avatar/decorating UI case timed out after 240s (exit124) with no completed assertions. Direct fallback launch succeeded and actual [Home render](../docs/verification/engineering-maintenance-2026-10-13/home.png) was inspected; editor journey/runtime motion toggles remain pending. [Evidence](../docs/verification/engineering-maintenance-2026-10-13/README.md). No app-data reset, deployment or remote push.

Next: recover bounded runtime acceptance, then preserve corrupt world payloads before mutations and improve world accessibility. Broader remaining work is prioritised in ENGINEERING_AUDIT.md. The historical October 12 character handoff below remains relevant for visual choice. No agents/build/test/export jobs remain running. App remains open on Home with isolated render preferences; timed-out UI suite cleanup is unconfirmed.

## Exact next action

2026-10-12: Proposed B/C refinement generated and inspected; saved under `docs/design/concepts/character-refinement-2026-10-12/`. Four identities, standing/seated, expressions and room. Still unapproved; taller C proportions dominate. Next: feedback/refine before implementation. No app edits or jobs running. GitHub push still pending explicit destination confirmation after automatic review rejection.

2026-10-04: User requested visual exploration before implementation. Two concept boards and exact prompts saved in `docs/design/concepts/character-directions-2026-10-04/`. First too similar; second stronger stylistic contrast. Concepts unapproved; generated native-size labels are not verified sprite dimensions. Next: refine user-selected direction, then build only when directed. No app edits or jobs running. Prior implementation evidence follows.

Refinement team completed avatars (fabric/hair/shoes), editors (adaptive previews, feedback, safe outfit discard) and live/check-in/results readability. Root integrated, built, inspected actual simulator renders and fixed observed omitted cancel action, timer/check-in wrapping, fixed-size result statistics and editor-header crowding. Implementation/fixes saved in `4d75304`, `6bbb5ac`, `870ff27`, `bc34880`; final evidence/handoff also saved in Git. No remote push.

[Final team evidence](../docs/verification/CONTINUATION_TEAM.md). Production study-model integration passed. Production/UI target builds passed. Six targeted journeys have passing evidence across the run: normal onboarding/saved identity54.674s, largest-text onboarding28.997s, independent garments84.497s, final affected largest-text full study67.462s, saved solo reward/purchase81.798s, editor discard/large editors62.799s (all3 final affected zero failures in212.059s). Subsequent header/catalogue editor recheck passed76.494s, zero failures.

Valid xcresult screenshots/manifests exported under `docs/verification/continuation/` and inspected. Initial integration compile errors and two editor test failures are documented with fixes; no false full-run pass. Final editor captures are `continuation/editors/`; accepted study/stat captures `continuation/accepted/`; normal onboarding `continuation/onboarding/`. User saves preserved; test fixtures namespaced and cleared through lightweight Debug-only cleanup. No agents/build/test/export jobs remain running. App launched on Home using ordinary preferences through Debug render route; simulator available.

Next concrete slice: smaller iPhone/Dynamic Type layouts, VoiceOver + Reduce Motion runtime checks, then richer avatar/reference fidelity and authenticated private-friends integration per roadmap. Comprehensive accessibility and physical-device acceptance remain open. Preserve participant UUIDs, frozen intent, independent outfit saves and idempotent receipts; fixtures are not multiplayer evidence.

## Current environment

- Project: `/Users/yusufsalih/Developer/LockedIN/LockedIN.xcodeproj`; scheme `LockedIN`; bundle `com.lockedin.app`.
- Build: `/tmp/LockedIN-codex-build/Build/Products/Debug-iphonesimulator/LockedIN.app`.
- QA device: iOS 18.6, UUID `9D097FC5-9F94-4E99-89F3-42053E145921`.
- October 3 baseline, room/chair and final lighting builds passed. All three regression suites passed. Offscreen room/focus/break/chair exports inspected.
- Historical iOS 18.6 startup failure is superseded for verification by working iPhone 17 / iOS 26.3; solo/early-exit/editor UI cases passed. Do not erase the older device.
- Elevated CoreSimulator/Xcode and Observation compiler access was approved; no automatic approval rejection occurred. No app data reset.
- Earlier recovery destination loss is superseded by successful continuation-team simulator tests. Final editor check passed; app launched Home. Recheck availability on next resume; temporary logs may disappear.

## Verification commands

```sh
xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/LockedIN-codex-build CODE_SIGNING_ALLOWED=NO build

git diff --check
```

Run the three regression executables using [Tests/README.md](../Tests/README.md). All three and the added production-model integration suite passed on 2026-10-03; simulator solo/early-exit/editor UI evidence is recorded in OFFLINE_LOOP.md.

## Important implementation constraints

- Accumulated pre-existing work was preserved in local recovery commit `e2af5a1`; implementation polish is in `175271e`. Nothing was pushed. Preserve all saves and later edits.
- Reward receipt identity is the user's participant UUID, created per session roster. Future session restoration must retain it; rebuilding the roster creates a different identity.
- Receipts and balances are saved in one world payload. ActiveStudySession is persisted separately until results acknowledgment; a replay keeps the participant UUID and reuses the receipt. Tests cover normal save/reload, not power-loss durability or concurrent writers.
- User results now report recorded timer completion and self-reported breaks/interruptions, not attention/app usage. Companion values remain seeded; never describe them as real friends.
- Procedural room/avatar assets remain in use. Generated concept artwork is reference only.
- Real payments, networking and native app blocking are not implemented.

## Update rule

After each meaningful milestone or handoff, update `PROGRESS.md`, this file and any affected roadmap gates. Record the next concrete action and actual verification evidence. Archive historical plans rather than silently using stale phase numbers or completion percentages.

## Visual references recovered — 2026-09-27

Inspected the six user-supplied chat references and all ten existing `Design images` mockups. Saved named, unmodified copies of the ten local mockups plus a related dark-room reference in [the reference folder](../docs/design/references/README.md). [Art direction](../docs/design/ART_DIRECTION.md) captures character quality, room lighting, customisation behaviour and progression. Exact chat originals for the welcome/district, classic Habbo customiser and dark Room + World remain unavailable as local files; do not claim all six attachments were saved. Immediate next implementation task remains a visible app run and reference comparison.

## Latest completed checkpoint

- Root `AGENTS.md` now provides current product/workflow/quality instructions; `docs/CODEX_WORKFLOW.md` explains progress/context controls and document roles.
- Personal-room concept generated using built-in image generation after a network failure on the first request. Saved PNG and exact successful prompt under `docs/design/concepts/`; shown in chat. User says concept character is too developed and wants more game-like proportions, deferred until room work progresses.
- `Tools/ArtPreview/` compiles app PixelKit code using a small Mac bitmap bridge. Native room/avatar exports and enlarged group art studies are saved under `docs/design/runtime/`. See tool README for omissions and the baseline outline caveat.
- Updated AvatarSpriteV3 hair shapes/material details while preserving wardrobe models. Rebuilt RoomDeskSprite using actual isometric geometry and the same footprint/variant IDs.
- LiveRoomScene keeps furniture during breaks, draws the break occupant after seated rows, and announces participant/status accessibly.
- Inspected latest source-art exports: desk geometry improved; remaining front-facing furniture and crowding are explicitly unfinished.
- Final Debug simulator build and whitespace checks passed. No simulator interaction pass. No pending image/build/agent jobs at handoff.

## Simulator recovery checkpoint — 2026-09-27 14:58 London

Fresh boot of the existing iOS 18.6 QA simulator plus targeted SIGTERM of 32 orphaned processes from shut-down iOS 26.3 devices and additional startup time produced a functioning iOS home screen. Install and launch of LockedIN succeeded; actual home UI captured in `docs/verification/simulator-recovery/home.png`. No app code/data/cache reset. Host has 8 GiB RAM, about 5 GiB swap in use, heavy I/O/load; resource contention suspected, sole root cause not proven. Historical blocker paragraphs above are superseded by this checkpoint. Simulator/app intentionally remain open for user inspection. Diagnostic commands completed.

## Perspective checkpoint — 2026-09-28

RoomFurnitureCore now contains integer face projection plus shared raster helpers; sofa redrawn as geometry. Shelf/drawer fronts project with top and side depth; window/clock/poster/pinboard bake onto correct wall slopes. Anchors/cache keys updated. Build passed and actual home screenshot inspected: `docs/verification/simulator-recovery/home-perspective.png`. See `docs/verification/ROOM_PERSPECTIVE.md`. User prioritises perspective before character polish. Remaining shelf bulk, chair/props, group spacing and walkthrough. All tool jobs completed, simulator left open.

## October 3 implementation checkpoint

Projected stool/chair variants; reduced shelf size; shared-study perimeter furniture without the personal sofa; staggered four-person desks; a foreground break position; moved lamp lighting. Actual render sources remain independent layers with the existing wardrobe/catalogue/persistence intact. Production-source exports inspected, including all chair variants. Final Debug simulator build and three regression suites passed. See the checkpoint for runtime limits. The September runtime evidence below/above is historical and does not verify this new build.

## Completed offline-loop goal checkpoint

New files: ActiveStudySession, StudySessionStore, StudySessionFlowView, StudyTestEnvironment, actual-model StudySessionChecks, isolated OfflineStudyLoopTests and bounded UI runner. Solo/group share the saved flow; legacy optional test stakes remain outside restoration. WorldStore rejects unfinished snapshots; results show private goal review and paid-on-tap catalogue upgrade. CharacterAppearance decode now preserves independent garment axes. See OFFLINE_LOOP.md for commands and evidence. No subagents are running.
