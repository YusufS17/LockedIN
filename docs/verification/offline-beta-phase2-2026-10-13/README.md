# Phase 2 offline-beta continuation — 2026-10-13

## Delivered

Same-base onboarding preserves customised appearance; a different base asks before replacing a customised look, preserving name/unlocks. Onboarding and World decorative tasks cancel when dismissed; results persist earned rewards before decorative awaits and resume staged presentation safely. World loading rejects invalid essential counters, buildings and receipt values while preserving original bytes. XP level calculation is bounded and overflow-safe; unsupported reward growth rolls back and preserves pending results. All receipt UUIDs remain retained.

[Independent QC](../PHASE2_QC.md) and [storage lifetime/limits](../../STORAGE_LIFETIME.md). Legacy simulated-stake settlement caching lasts for a view identity, not a durable journal across recreation/relaunch. Offline zero-stake persisted receipts remain the supported flow.

## Actual checks

- Initial app/UI build and final UI-target rebuild passed: [build](build.log), [final build](final-build.log). Only informational AppIntents metadata warnings.
- Dedicated world-semantic checks passed (QC): essential invalid values, extreme accepted values, payload preservation, growth rollback, 1,000 normal level boundaries. Service concurrency checks independently passed. See QC record.
- Existing affected world, reward rules and production study integration passed: [world](world.log), [reward](reward.log), [study](study.log).
- Source whitespace review passed. Saved Xcode stdout logs have trailing whitespace/blank endings normalised; diagnostic text and outcomes retained. Final complete-change whitespace check passed after normalisation.

## Runtime acceptance blocked

Existing iPhone16e / iOS26.3, destination DB03CCDF-9915-45BD-B3C0-3A68C136313C; iPhone17 shut down without erasure. [Initial compact group](initial-compact-stalled.log) launched the runner after several minutes, logged “Running tests”, then the runner exited without case/assertion output. Xcode kept waiting. Lead interrupted then killed only that run’s owned process group (wrapper exit -9). Separate [system accessibility attempt](initial-system-stalled.log) also stalled before assertions and was stopped the same way. No passed journeys or completed screenshots claimed.

QC identified a possible discovery issue: Settings XCUIApplication was initialized as a stored property before setup. Moved into setUp alongside the main app; final rebuild passed. This is a defensive fix, not a confirmed stall diagnosis. [Focused recheck](focused-onboarding-destination-failed.log) exited70: Xcode listed only generic placeholders and could not find the existing simulator destination. No app assertion ran. No automatic approval rejection.

New targeted tests are compiled but unverified: customised-base backtracking/replacement/relaunch; compact study → break restoration → results replay → earned rug → relaunch; actual Settings Reduce Motion toggles and visible-element description audit. Settings test restores its initial value when executed; no evidence that this test reached a setting mutation, and no OS-toggle/audit pass claimed. Full VoiceOver traversal and physical-device soak remain pending. Initial runner fixture cleanup cannot be confirmed; no ordinary user save or simulator data was reset.

Next: recover Xcode/simulator destination discovery without erasing data; run the three new groups plus largest-text onboarding serially, export screenshots and inspect actual renders before closing Phase2. No deployment. Phase3 character direction and Phase4 real backend/account decisions remain open.

## Final fallback and handoff

Direct `simctl launch` with namespaced render preferences failed with FBSOpenApplicationServiceErrorDomain code4 (request to open app failed). Explicit install of the compiled app then stalled for about three minutes; only that simctl client was terminated (exit143). Installation completion is unconfirmed. No current app render or passed runtime journey is claimed. No agents/build/test/export/install clients remain running; existing compact simulator remains booted, current app/fixture state unconfirmed. No reset, service kill or deployment.

Implementation milestone `320297fe6d1b2fa9af6712e56bff4a47ce2d1c40` was pushed to existing GitHub main and confirmed with `git ls-remote`. Final handoff/log whitespace normalisation is saved in a subsequent commit; these cosmetic log changes do not alter test results.
