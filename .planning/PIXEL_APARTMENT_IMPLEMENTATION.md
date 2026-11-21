# Pixel Apartment native implementation

Started 2026-11-21 from clean `b17826b`. Approved target: A board under `docs/design/concepts/visual-reset-2026-11-15/`. User corrections in DIRECTION.md govern; concepts are not runtime assets.

## Milestone 1 — onboarding and creator (current)

- Welcome → Creator → name → room arrival, one top progress bar, no skip/gallery/pager.
- Charcoal/amber surfaces, coherent evening-room preview and compact controls. Use native layered rendering; do not flatten the app into a generated screenshot.
- Numbered skin swatches with yellow only as new-user starter, M/F presentation, freely selectable identity features, Randomize. Future clothing/accessories last; preserve already-saved garments/headphones and ownership metadata.
- Compatible persistence/legacy defaults, raw identity recovery guard and receipt/session identity unchanged.
- Model compatibility checks, app/UI build, current compact/largest-text renders, new onboarding/backtracking and legacy-outfit persistence journeys; independent source review. Simulator failures are bounded and do not imply pass.

## Milestone 2 — room navigation and concise setup

Room/Friends/Profile tabs; Profile owns avatar edit, Room owns decorating, Friends remains honest about unavailable networking. Concise subject/goal/duration setup without generic promotional cards. Preserve active session routing.

## Milestone 3 — immersive room and final art

Full-viewport room with timer/dock overlays, short focus status instead of padlock, correct seated desk/chair/character order. Produce and verify richer original character/room layers matching A; this milestone is not completed by dark UI around the existing renderer.

## Milestone 4 — private friends and native controls

Backend/auth provisioning and real invites, durable membership/session/reconnect/two-account acceptance. App shielding separately requires Apple authorization/entitlements and physical-device verification. No private app/screen activity sharing or real-money work.

## Team for milestone 1

Onboarding builder: host/welcome/name/arrival + backtracking test. Creator builder: CharacterCustomizerView. Model/render builder: compatible appearance/palettes/caches + identity regressions. Lead: integration, phase control, old UI-test adaptation, evening scene override, legacy outfit fixture, serialized verification, render inspection and Git. Builders cross-review after implementation. Role entries describe this run; PROGRESS records actual live status.

## Milestone1 checkpoint — 2026-11-21

Native flow/creator implemented, reviewed, built and model-checked; six initial UI cases plus two final affected single-centre-tap normal/AX rechecks passed. Current render evidence in `docs/verification/pixel-apartment-2026-11-21/`. Earlier tap miss and hardening are documented. Final character/room reference fidelity remains milestone3, not a completed claim. Next is milestone2.

## Main-screen continuation — 2026-11-21

User explicitly requested continuation of the whole design brief, including atmospheric backgrounds and A fidelity, rather than another scope-choice conversation. Room/Friends/Profile shell, concise setup, full-viewport focus camera/status and richer authored room shell/city are implemented and in integration verification. Current avatar family/furniture silhouettes remain below final A art target; do not conflate the new shell with final artwork acceptance. Model checks and first app/UI build passed; final changed-code build and actual screen journeys pending. See `docs/verification/pixel-apartment-main-2026-11-21/README.md`.

### Actual-render review after main-screen build

Direct Room and four-person focus renders now exist in the main-screen evidence folder. Material/architecture/city details improved, but A fidelity remains open: room island has too much surrounding sky/foreground, current avatar head/eye proportions and furniture silhouettes remain earlier family, and greenery/rugs are sparse in the saved default. Do not treat these as the final art direction being delivered.

Solo close-camera render exposed real containment/safe-area defects (top controls too high, bottom dock absent), despite initial source review. Correction removes the redundant safe-area-ignoring backdrop from inside LiveRoomScene and explicitly bounds the camera's ZStack. Parent backdrop alone handles system chrome. Require a new actual render before accepting focus layout. The interrupted UI run supplies zero passes and cannot establish navigation/session regression acceptance.

Next art work after verified containment: author a portrait interior camera with taller wall/window architecture rather than simply zooming a room island; refine original avatar proportions, face/hair and seated variants together; retain separate editable room/furniture/people and saved catalogue identity. Compare normal-size Welcome/Creator/Room/Focus directly with selected A; do not keep substituting palette changes for art changes.

Final containment build passed and `focus-contained.png` was inspected: status bar/timer/bottom dock visible, text focus status and seated layering correct. This closes the observed solo layout defect, not the final art or interaction acceptance gates. Production-model checks and4 builds passed; UI run600s has0passes. All builders/reviewers stopped. See current PROGRESS and evidence for commit/backup and next concrete work.
