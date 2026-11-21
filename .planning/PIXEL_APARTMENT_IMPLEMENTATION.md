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
