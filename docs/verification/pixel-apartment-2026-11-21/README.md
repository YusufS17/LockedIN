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
- Final starter colour refinement (cream shirt for new users only) passed model integration (`final-model-checks.log`). Final rebuild + normal/AX targeted recheck pending after server interruption; added explicit AX Randomize-above-Continue reachability assertion.
- Inspected actual compact creator (`creator-live.png`); normal controls fit, options use deliberate horizontal rails. Existing layered avatar renderer is still recognisably the old family, with modest presentation variation. Final A character/room fidelity is NOT claimed.
- Whitespace check passed for tracked source during integration.

## Next milestones and limits

Room/Friends/Profile navigation, concise setup, immersive full-screen focus and richer runtime art are next. Real friends, native blocking, full VoiceOver and physical-device soak remain separate. No concept PNG is installed as an interactive room. Current UI tests use disposable preferences and simulated companions, not networking evidence.

Saved text logs have trailing whitespace normalised; original result bundles remain at the logged temporary paths.
