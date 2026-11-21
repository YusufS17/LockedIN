# Pixel Apartment main-screen implementation — 2026-11-21

This continues the full user-requested redesign after the onboarding/creator foundation. Selected concept A remains the reference; native changes below are not a claim that final character/art fidelity is complete.

## Implemented

- Native Room / Friends / Profile tabs. Room owns decorating and direct saved-session entry; Profile owns avatar editing. Friends explicitly labels unimplemented networking and simulated club entry.
- Layered native pixel city backdrop with stepped cloud banks, sparse stars, multiple building depths, cornices, rooftop silhouettes and individually lit windows. Shared by onboarding, main tabs and setup; no generated flat app screenshot.
- Evening room shell now has petrol walls, projected timber cornices/posts/wainscot, richer walnut materials and warm city windows. Catalogue IDs, placement geometry and inventory unchanged. The default `wall.cream` identifier is retained for save compatibility; its authored evening lighting is petrol, daylight remains pale.
- Concise subject/goal/duration setup. Capability disclosures in an explicit sheet.
- Focus viewport has compact safe-area clock/exit/details controls, text focus status for solo and small bottom interruption/break dock. Solo uses an intentional close camera; multi-seat rooms fit all participants and preserve area controls. Maximum accessibility text uses scrolling.
- Session clock/checkpoint/restore/reward implementations unchanged. No real multiplayer, app tracking/shielding or payments added.

## Verification

- Production-model disposable-fixture regressions passed (`model.log`): restored UUIDs, interruption/break/expiry, reward replay, ownership and protected-save recovery.
- Initial and final main-screen app/UI builds passed. `build.log` is the successful second build; Debug direct-render refinement build also passed (`render-build.log`). Camera containment correction app/UI build passed (`containment-build.log`).
- Independent source reviews covered tab recovery/session routing, lifecycle preservation, group fit/contrast, solo break-label crop and landscape fallback.
- Four UI journeys were selected, but the bounded run stopped at600s with no passing case. Startup consumed several minutes; first compact case exceeded its180s allowance while app launch/accessibility snapshot was unresolved. `ui-first-run.log` retained. The xcresult bundle has no finalized Info.plist and cannot be exported as passing evidence. Fixture teardown was not confirmed for that interrupted run; only namespaced disposable data was involved.
- `launch-not-ready.png` records a black launch frame during automation. The1s sample (`launch-sample.txt`, only2 collected samples due environment delay) shows UIKit/CoreText first-commit text drawing; this is insufficient to establish the cause.
- Direct launch with separate `LockedIN.ui-tests.apartment-visual-20261121` suite and Reduce Motion succeeded. `direct-room.png` is the actual new native Room screenshot, visually inspected. `direct-focus-group.png` is the actual four-person render; desks/avatar layers visible, but top controls were too high. Root removed the room's top safe-area override; subsequent solo capture (`direct-focus-solo-before-containment.png`) still showed top overlap and missing dock. Camera looked immersive, with seated avatar/hands behind/on desk and readable In focus. Source correction now removes redundant safe-area-ignoring scene backdrop and bounds zoom to the actual viewport; `focus-contained.png` is the final actual solo render: status bar visible above controls, both dock actions visible, readable In focus, seated avatar behind desk with hands on top. Scene sides are intentionally cropped for immersion. This is visual evidence, not an interaction pass.
- Copied text logs normalize trailing whitespace; raw originals remain in /tmp/the runner directory. Ordinary user data has not been erased.


## Remaining art work

Current editable avatar sprite family and furniture silhouettes remain implementation material. Richer full-height apartment architecture and final A character identity still need direct reference comparison; a dark palette alone does not satisfy that gate.

## Final review and next action

Lead and independent source/render reviews completed. `git diff --check` passed. Current room/sprite family is still below final A fidelity; next work must author the taller portrait interior and refine original characters, then run actual route/session interaction acceptance when simulator automation is responsive. Four requested UI journeys are still unverified against this milestone. No real multiplayer or native app blocking is claimed.

Direct visual fixture cleanup was launched through the existing namespaced reset/cleanup route (PID27562), then terminated. No screenshot/accessibility assertion of that cleanup surface was made. The ordinary app was relaunched without test arguments afterward; this does not prove interaction acceptance. Interrupted automation fixture cleanup remains unconfirmed. Local milestone commit and remote backup status are recorded in PROGRESS.
