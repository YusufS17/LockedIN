---
status: visual_redesign_iteration_verified
last_updated: "2026-10-03"
stopped_at: "Character/main-flow redesign verified; final affected3 UI cases passed; app open Home; no jobs running"
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

## Exact next action

The user reprioritized character art and detailed UI/UX over networking. The substantial [visual redesign iteration](VISUAL_REDESIGN.md) is implemented and verified. Three agents completed character, live study, and home/setup/results work; root integrated shared controls, wardrobe/decorating, private check-in, world polish and verification. [Design decisions](../docs/design/INTERFACE_SYSTEM.md) · [Evidence](../docs/verification/VISUAL_REDESIGN.md).

Final character source retains48×64 canvas and saved wardrobe IDs but replaces body/face geometry, several hairstyles and gesture arms. Desk hands now taper within the existing registration masks and render without a heavy outline. Head/portrait bounds and wardrobe thumbnail crops were updated. Editors keep previews visible while browsing; room floor/wall thumbnails use the actual shell renderer.

Verification: model/area checks passed; production and UI targets built. Seven-case run `LockedIN-ui-checks-66l7wowx` passed6 and stopped8-person at an uppercase subject assertion; corrected test compares subject case-insensitively. Final affected recheck `LockedIN-ui-checks-41dmm8d5` passed editor/eight-person/custom garments with zero failures in260.376s. Saved screenshots: `docs/verification/visual-redesign/reviewed/` (final affected views), `journey-check/` (earlier complete journey views), `before/` (baseline). Root/agent phone review fixed timer glyph shadowing, status contrast, typing-hand blocks and editor preview visibility. Final world-only fix removed inactive stars over building names; production build and actual world render passed.

Next: richer hair/garment volume, more natural seated silhouettes and room atmosphere, then onboarding/Dynamic Type consistency. Do not claim original mockup fidelity complete or resume networking as the immediate priority without considering this visual direction. Preserve verified session UUIDs, frozen intent, wardrobe saves and idempotent rewards.

All agents/build/test/export jobs finished; no background automation. Updated app open on Home using normal saved preferences. Environment: one root-owned Xcode/simulator, iPhone17/iOS26.3 `5DA4238F-6617-4E78-BBD0-80936A3A4B1E`. Final build `/tmp/LockedIN-visual-redesign-world-build.log`; affected-test build `/tmp/LockedIN-visual-redesign-reviewed-build.log`. Temporary logs may disappear. No commits or data erasure.

## Current environment

- Project: `/Users/yusufsalih/Developer/LockedIN/LockedIN.xcodeproj`; scheme `LockedIN`; bundle `com.lockedin.app`.
- Build: `/tmp/LockedIN-codex-build/Build/Products/Debug-iphonesimulator/LockedIN.app`.
- QA device: iOS 18.6, UUID `9D097FC5-9F94-4E99-89F3-42053E145921`.
- October 3 baseline, room/chair and final lighting builds passed. All three regression suites passed. Offscreen room/focus/break/chair exports inspected.
- Historical iOS 18.6 startup failure is superseded for verification by working iPhone 17 / iOS 26.3; solo/early-exit/editor UI cases passed. Do not erase the older device.
- Elevated CoreSimulator/Xcode and Observation compiler access was approved; no automatic approval rejection occurred. No app data reset.
- Temporary build/log paths may disappear. Recheck the runtime rather than assuming the September simulator is still open and working.

## Verification commands

```sh
xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/LockedIN-codex-build CODE_SIGNING_ALLOWED=NO build

git diff --check
```

Run the three regression executables using [Tests/README.md](../Tests/README.md). All three and the added production-model integration suite passed on 2026-10-03; simulator solo/early-exit/editor UI evidence is recorded in OFFLINE_LOOP.md.

## Important implementation constraints

- Existing tracked modifications and untracked source files predate this resumed session. Preserve them; nothing has been committed or pushed by this work.
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
