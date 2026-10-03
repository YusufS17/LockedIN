# LockedIN progress

Last updated: 2026-10-03

## Current work — recovery and polish, 2026-10-03

- Recovered all saved source/assets/evidence; preserved pre-existing edits in local commit `e2af5a1`. No remote push.
- Three agents completed room atmosphere, truthful onboarding and adaptive Home/setup/shared controls. No agents remain running. Implementation saved in local commit `175271e`.
- Root: new onboarding/large-text UI checks added; current Xcode build is running before runtime inspection.
- Existing iPhone 17 simulator booted without data erasure. Clock/reward/persistence/session/seating and private-state fixture checks all passed. Source-art exports inspected; new screens await build/runtime verification.
- Next: integrate agent changes, inspect actual renders and save final evidence/commits.

## Product direction

Read [the restored user direction](docs/USER_DIRECTION.md) and [the original attached product brief](docs/PRODUCT_BRIEF_ORIGINAL.md). The target is a polished Habbo-inspired social study world for real use with friends. The hackathon is over; the old test-stake demo is not the main product. Visual quality and genuine private multiplayer remain acceptance requirements.

## Where we are

The room-centred interface and saved offline study loop now have actual iPhone simulator interaction evidence. Sessions resume after relaunch, results cannot award twice, and the earned rug remains in the room. Saved skin/floor choices also survive relaunch.

This is a native SwiftUI iPhone app. Open `LockedIN.xcodeproj`, select LockedIN and an iPhone destination, then Run (⌘R). The existing iPhone 17 / iOS 26.3 simulator worked for this verification; the older iOS 18.6 QA simulator still has startup issues.

## Implemented so far

- Personal-room home with direct avatar and decorating entry points.
- Shared solo/demo-club study setup: subject, goal, 25/50/90-minute presets and supportive defaults.
- Larger wardrobe previews and furniture selection using actual renderer assets.
- Live focus room with goal, deadline-based timer, break/resume and explicit early leaving.
- Early exits and quick demos do not earn completion XP or coins.
- Persistent reward receipts prevent repeated results from awarding progress twice, including after reloading the world store.

## Verification

| Check | Latest result |
| --- | --- |
| Debug iPhone Simulator build | Passed 2026-10-03, including character/UI redesign and final world fix |
| Focus clock regression checks | Passed |
| Reward rules regression checks | Passed |
| Persistent reward checks, legacy save migration and reset | Passed |
| Git whitespace check | Passed |
| Production-model integration | Passed, including restoration, receipt replay and catalogue purchases |
| App screenshots and interaction walkthrough | All seven journeys have passing evidence; final editor/eight-person/custom-garment recheck passed with zero failures; screenshots inspected |

Build log: `/tmp/LockedIN-visual-redesign-world-build.log` (temporary and may disappear). Reproducible regression commands are in [Tests/README.md](Tests/README.md).

## Still unfinished

- Final reference fidelity: runtime group inspection is complete; richer room/avatar art remains an ongoing product gate.
- Physical-device testing and native app tracking; current verification uses the simulator.
- Real friend invites, networking and multiplayer; current companions are simulated.
- Native focus enforcement; no real app blocking is implemented.

## Continue from here

1. Read [current handoff](.planning/STATE.md) for exact recovery context and constraints.
2. Follow the [active roadmap](.planning/ROADMAP.md), starting with the remaining directional art and private-friends integration gates.
3. Use the [implementation summary](docs/INTERFACE_PASS.md) for screen details and Debug preview arguments.
4. Consult the [product audit](docs/PRODUCT_AUDIT.md) for rationale and outstanding architecture gaps; it records the earlier baseline, not the latest completion status.

## How these notes are maintained

Update this file and `.planning/STATE.md` after meaningful milestones or before handing work back. Update roadmap checkboxes only when their acceptance checks are met. Record what changed, checks actually run, blockers and the next concrete action. Distinguish implemented code from runtime-verified behaviour. Preserve existing local edits and do not infer completion from historical plans.

Recovered work is preserved in local commit `e2af5a1`. Local commits survive a restart but are not a remote backup.

## Visual references recovered — 2026-09-27

Inspected the six user-supplied chat references and all ten existing `Design images` mockups. Saved named, unmodified copies of the ten local mockups plus a related dark-room reference in [the reference folder](docs/design/references/README.md). [Art direction](docs/design/ART_DIRECTION.md) captures character quality, room lighting, customisation behaviour and progression. Exact chat originals for the welcome/district, classic Habbo customiser and dark Room + World remain unavailable as local files; do not claim all six attachments were saved. Immediate next implementation task remains a visible app run and reference comparison.

## Latest visible work — 2026-09-27

- Added root [AGENTS.md](AGENTS.md) for automatic project instructions and a [workflow guide](docs/CODEX_WORKFLOW.md). The current-work table records real task ownership/status.
- Generated and showed the personal-room concept; saved it and its prompt in `docs/design/concepts/`. User requests a more game-like character; that concept revision is deferred.
- Built an offscreen art exporter using the actual PixelKit source, so artwork can be inspected without the simulator. [Current art and limits](docs/design/runtime/README.md).
- Improved short/long hair, shading and garment/shoe details in the existing avatar layers. This is an initial iteration, not the final character-art target.
- Rebuilt the desk with an isometric top, laptop/notebook, separate shaded faces and visible legs.
- Fixed break rendering so the occupant moves while their desk/chair stays; added participant/status accessibility labels.
- Inspected personal-room and group focus/break art exports. Group arrangement remains crowded; other furniture still needs perspective changes.
- Latest Debug iPhone Simulator build passed; `git diff --check` passed. Log: `/tmp/LockedIN-visual-followup-build.log`.
- Full app screenshots/interaction remain unverified. [Simulator diagnosis](docs/verification/SIMULATOR_BLOCKER.md) records a graphics compiler hang and bounded failed startup/install attempts.

## Simulator recovered — 2026-09-27, 14:58 London

Removed 32 abandoned iOS 26.3 processes after verifying their devices were shut down; the existing iOS 18.6 simulator completed startup, installed LockedIN and rendered home. No data reset or app-code change. [Actual screenshot](docs/verification/simulator-recovery/home.png) · [Diagnosis and limits](docs/verification/SIMULATOR_BLOCKER.md). Resource contention is a likely contributor; a unique root cause is not proven. Simulator is left open for the user, with no diagnostic commands still running. Next: full interaction walkthrough and visual fixes against real screens. Earlier blocked-status entries describe previous attempts.

## Perspective pass — 2026-09-28

Corrected wall-mounted art to follow wall slopes, added bookcase/drawer depth, rebuilt the sofa and adjusted placements. Build and whitespace checks passed; exporter and actual iPhone home inspected. [Updated app screenshot](docs/verification/simulator-recovery/home-perspective.png) · [Changes and remaining work](docs/verification/ROOM_PERSPECTIVE.md). Next: reduce shelf visual weight, improve chair/props and group spacing, then character fidelity; complete the local interaction walkthrough. No jobs remain running; simulator left open.

## Shared-room and chair pass — 2026-10-03

Started the authorised phase plan. Added projected stool/cushioned/padded chairs, a less dominant shelf, shared-room perimeter furniture, staggered four-person seating and a clear foreground break position with matching lamp lighting. [Source-art group view](docs/design/runtime/group-focus-art.png) · [Chair variants](docs/design/runtime/chair-variants.png) · [Verification and remaining work](docs/verification/OCT03_CHECKPOINT.md). Final build and all three regression suites passed. Full iPhone interaction acceptance remains open. Existing local changes remain uncommitted.

## Offline-loop implementation — active goal, 2026-10-03

The user explicitly activated a goal to complete and verify the offline loop. Added saved sessions/restore, private goal check, truthful user summaries, affordable room upgrade action, incomplete-result protection and honest simulated-settlement errors. Fixed separate garment restoration. Production-model integration checks pass, including an actual earned catalogue purchase and reload. App/UI target compilation passes; iPhone interaction evidence is still pending. [Current evidence](docs/verification/OFFLINE_LOOP.md) · [Reproducible checks](Tests/README.md).
