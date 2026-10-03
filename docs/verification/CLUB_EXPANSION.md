# Friends-ready club expansion — 2026-10-03

Scoped autonomous goal completed. Implementation, model checks and actual iPhone interaction/render evidence are recorded below; chronological intermediate checkpoints are retained.

## Implemented

- Setup selects 2–8 demo seats. The frozen roster, optional per-person subject/goal and participant UUID persist through the existing study store. Old saves decode absent intent as nil. Checkpoints cannot replace intent after start.
- Room scenes use balanced seating areas of at most four for 5–8 participants, explicit area buttons, stable global indices and a break pose only in its participant's area. Existing 1–4 furniture anchors remain unchanged.
- Participant sheet shows subject/goal and aggregate status, labels companions simulated and omits interruption history/private goal reviews.
- Seated tee, hoodie, jumper, jacket and shirt have directional shoulders, sleeve/side volume and distinct collars/lapels; standing artwork and hand registration remain intact.
- Isolated friends fixtures add optional shared intent and generation-scoped reconnect/read rules; no network or app integration.

## Verified so far

- Production-model integration passed including all sizes 2–8, paused restore, frozen intent, old missing-intent decoding and invalid text rejection; prior reward/purchase/UUID checks continue to pass.
- Root independently ran balanced-area mapping checks and all 81 friends prototype assertions: passed.
- Source pose-family/group exports regenerated after final tee elbow edit; root/avatar agent inspected. These are not phone screenshots.
- Integrated app/UI build passed: `/tmp/LockedIN-clubs-build.log`.
- 2/4/8-person simulator tests running in `LockedIN-ui-checks-o62szaex` on iPhone17/iOS26.3. Disposable preference suites; no user-save reset. Full completion uses DEBUG-only restoration time advance.

## Acceptance checklist at the first checkpoint

Inspect actual 2/4/8-person screenshots, per-person sheet, maximum-size paging and paused relaunch. Run affected solo and independent-garment checks. Fix concrete defects, update roadmap/handoff and whitespace-check before completion.

## Limits

This is a labelled local demo, not real multiplayer. Reconnect fixtures assume an authorised adapter and do not implement a service, signing/auth, transactional server timing or real two-device connectivity. The new garment direction is incremental; final reference-level character detail and fully authored poses remain open.

## Independent review

Read-only peer review found no UUID/reward/legacy-decoding or private-review regression. Corrected setup wording to identify the participant list, and aligned app/prototype text validation: subject and goal required/trimmed when intent exists, control characters rejected, whole intent optional for old saves/withdrawal. Updated prototype reports 83 passing checks; final root rerun/rebuild pending.

## First phone run and correction

`LockedIN-ui-checks-o62szaex` exited 65: default four-person case passed 120.809s; two-person passed 51.415s; eight-person failed 86.669s while expecting the participant sheet. Exported UI hierarchy shows the test targeted the offscreen participant button at y827 behind the pinned break control and toggled a break instead. The test now scrolls that specific control fully above the inset before tapping. App entry gains a 44pt minimum tap area and clearer “Everyone’s goals” text. Root inspected two-person focus and second-area eight-person renders: spacing/readability good, no seat overlap. Final aligned text/model checks and all 83 friends fixtures independently pass.

Final integration build passed (`/tmp/LockedIN-clubs-final-tests-build.log`). The corrected eight-person case, independent garments including seated/break captures, and solo reward/purchase replay now run in `LockedIN-ui-checks-n8b9p1ux`. All three source agents have finished; root owns remaining runtime acceptance.

## Secondary visual review

Seating agent reviewed actual 2/4/8-person captures: correct area selection/You mapping, unique occupants, preserved empty desk on breaks. Found a transient old/new break-button text overlap in the two-person capture and a narrow Deep focus tag contact at the rear-left cheek. Screenshot helper now allows 0.7s for short transitions; conservative head-clearance geometry is being corrected before affected2/4 recapture. These are not recorded as final visual acceptance yet.

## Passing integration regression

`LockedIN-ui-checks-n8b9p1ux` exited 0, TEST EXECUTE SUCCEEDED: eight-person 115.903s, independent garments 82.649s, solo reward/purchase journey passed. All 19 captures saved under `club-expansion/regression/`. Root inspected the per-person sheet: clear subjects/goals, companion labels, private-review omission. Restored jacket/skirt/boots remain correct seated and standing.

Final screenshot review also found the personal live room's decorative floor books intersected the standing boots. Books now remain in home/builder art but are omitted from all live break aisles. Label clearance now uses cached actual seated head row silhouettes (including outline/mirroring) instead of a coarse rectangle. Final build and affected render rechecks remain.

Final visual build passed (`/tmp/LockedIN-clubs-render-build.log`). Five affected cases run together in `LockedIN-ui-checks-c8g12_xd` with a 900-second bound: default club, eight-person, two-person, custom garments and solo loop. This recheck is justified by new scene-label/break-aisle changes. No tests beyond affected scope are being repeated.

## Final five-case run

`LockedIN-ui-checks-c8g12_xd` exited 0: five cases passed, zero failures (413.634s): default 87.782s, eight-person 112.849s, garments 84.349s, solo 84.649s, two-person 44.004s. All 28 PNGs and metadata are saved in `club-expansion/final/`. Root inspected default long-label clearance, second area, restored8-person break, shared goals, settled2-person break and custom boots in the clear solo aisle. Label/transition/book issues are resolved in these captures.

One final targeted coverage addition checks the second area after Deep focus while the user is paused elsewhere: no duplicate break avatar and readable longer labels across its different hairstyles. Production code is unchanged. The targeted rerun `LockedIN-ui-checks-2b8joyl6` passed in 119.778s, exit 0. Root inspected `area-two-check/eight-07b-other-area-during-break.png`: all four longer labels clear faces, area 2 has its own four occupants, and the paused user is not duplicated. Its nine original captures and metadata are saved separately.

## Completed acceptance

- Final app/UI build passed; five affected UI cases passed together, zero failures. Additional second-area long-label/break-identity case passed.
- Production-model suite passed, including saved roster/intent for every size 2–8, older saves, frozen UUID/configuration/intent and reward replay/purchase persistence.
- Root independently passed area mapping checks and all 83 isolated friends fixtures.
- Actual phone screens inspected: two/default/eight seating, both areas/long labels, per-person goals, paused restoration, custom garments in seated/break poses and earned-room persistence. Source artwork remains separately identified.
- `git diff --check` passed. All three agents and root implementation/test/export jobs finished. Changes remain local and uncommitted; no app data erased, external service deployed or messages sent.

Next substantial implementation is an authenticated private-room service and app adapter, following `docs/PRIVATE_FRIENDS_BETA.md`, with durable identity, private admission/reconnect and actual two-account/device evidence. Shared earned-room progression and native focus controls follow. Final character reference fidelity remains an ongoing art gate; this milestone does not claim real multiplayer.
