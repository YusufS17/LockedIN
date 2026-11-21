# Native Pixel Apartment onboarding/creator — 2026-11-21

Started from clean `b17826b`. Approved visual target A and user corrections remain under `docs/design/concepts/visual-reset-2026-11-15/`. This is milestone1 of `.planning/PIXEL_APARTMENT_IMPLEMENTATION.md`, not completion of the whole visual redesign.

## Implementation

- Four-beat Welcome → creator → name → arrival. Removed production skip/gallery/value-card/pager/step-badge route; one accessible top progress bar.
- Charcoal/amber native UI, architectural backdrop and fitted real layered room preview using explicit evening lighting; ordinary app rooms retain clock-driven lighting.
- Creator: numbered skin choices, yellow starter only for new identities, M/F styling, ordered face/hair/colour/glasses controls, Randomize, no coin checkout. Future clothing/accessories are grouped last as non-actions. Existing outfits and future accessories survive edits/randomisation/save/relaunch.
- Compatible missing-presentation defaults and stable raw IDs. New presentation affects modest garment tailoring and relevant image caches. Unsafe identity guard supports new field and still preserves unknown fields/values.
- Existing onboarding/wardrobe tests updated to current UI; new namespaced/reset-only existing-outfit fixture. No user preferences reset, schema/reward/receipt UUID rewrite or networking added.

## Review

Three non-overlapping builders completed their slices. Separate source cross-review covered creator save/discard/no-purchase behavior, model compatibility/palette/cache identity and host draft/recovery/aspect-fit behavior. Lead reviewed integration, numbered skin descriptions, fixtures and native render. No blocking source review finding. Render acceptance and full art fidelity are separate.

## Verification

- Production study/identity integration passed (`model-checks.log`), including legacy full/partial avatar payloads, yellow/F identity and independent garments/name roundtrip, future presentation/raw payload preservation, session identity/reward replay and earned item persistence.
- App/UI build-for-testing passed (`build.log`).
- Initial six-case targeted run passed, exit0,427.247s total (`first-acceptance.log`): existing outfit127.543s, draft/discard/name120.329s, partial saved identity56.437s, largest text38.910s, recovery continuation40.322s, protected wardrobe43.705s. Screens exported in `first-acceptance/`.
- Final starter colour refinement (cream shirt for new users only) passed model integration (`final-model-checks.log`) and final build (`final-build.log`). First refinement group exited65: normal Welcome tap failed to reach creator59.658s; maximum-text flow plus actual Randomize reachability passed39.137s. Exported evidence in `refinement-first/`, log `refinement-first.log`.
- Failure event showed a single tap195,768 inside enabled Welcome button frame24,742,342,52; hierarchy remained Welcome. Cause not established by source review. Bounded hardening adds an explicit full-width rectangular hit shape inside the actual Text label, retaining styled size/appearance. The test now explicitly sends one centre coordinate tap for Continue with no retry fallback. Separate QC passed; `hit-area-build.log` passed. Final exact-centre normal draft/relaunch test passed116.134s and AX/Randomize test passed38.531s; combined exit0 (`final-acceptance.log`). Final starter/controls/room screenshots exported to `final-acceptance/` and inspected. Earlier failed run is retained; root cause is not conclusively established by this passing rerun.
- Inspected actual compact creator (`creator-live.png`); normal controls fit, options use deliberate horizontal rails. Existing layered avatar renderer is still recognisably the old family, with modest presentation variation. Final A character/room fidelity is NOT claimed.
- Whitespace check passed for tracked source during integration.

## Next milestones and limits

Room/Friends/Profile navigation, concise setup, immersive full-screen focus and richer runtime art are next. Real friends, native blocking, full VoiceOver and physical-device soak remain separate. No concept PNG is installed as an interactive room. Current UI tests use disposable preferences and simulated companions, not networking evidence.

Saved text logs have trailing whitespace normalised; original result bundles remain at the logged temporary paths.

All completed fixture teardown assertions passed. No agents/build/test clients remain running; app relaunched with ordinary saved preferences and no test flags. Recovery checkpoint `5db37c4` preserves the pre-final state after a server restart. Full VoiceOver/physical device and final art acceptance remain open.
