# Offline beta acceptance — 2026-11-15

Resumed clean checkpoint `417e96e`. Automatic approval review enabled; no permission-setting edits performed by the agent.

## Implemented

Results now distinguish the session's saved Focus XP from current world progress. Switching a study destination no longer labels the old session as contributing to the newly selected building or displays the previous building's fill. Current progress reads the selected building directly. Missing destinations no longer invent Library Hub progress. No persistence schema, receipt identity or reward calculation changes.

Added a scoped Debug fixture with two valid unlocked destinations at deliberately different progress values and a UI regression: earn/replay 120 XP, switch Library50% → Cafe70%, return to results, relaunch, preserve session XP/15 coins and prevent repeat contribution to Cafe. Fixture requires a namespaced suite + reset; ordinary saves unaffected. Corrected result-test scrolling to recognise that results actions are scroll content, not a fixed dock.

## Independent review

Separate builder and reviewer completed source/fixture review. Reviewer checked receipt replay, environment observation, demo/save-failure behavior, XP math, WorldView selection/value semantics and namespaced reset/relaunch. Lead reviewed final diff and actual renders. No blocking source finding remained; runtime outcomes are separate below.

## Actual verification

- Direct protected-identity onboarding launch succeeded on existing compact iPhone16e/iOS26.3. Actual recovery render inspected (`onboarding-recovery.png`).
- Incomplete-onboarding continuation/relaunch/protected-editor/close/cleanup test passed in58.336s; test process exit0 (`onboarding-recovery-test.log`). Exported recovery screenshots inspected in `recovery/`.
- Initial identity/compact group: ordinary avatar/decorating persistence and protected-avatar relaunch passed; compact failed at opening setup (study.goal absent after correct centre tap). Whole test exit65; no blanket group pass. Exported failure event/hierarchy/video and passing identity captures in `identity-compact-first/`; log in `identity-compact-first.log`.
- Failure review: single tap landed195,755.17 inside enabled study.start frame(24,727.7,342,55), Home stayed visible. No blocker/guard or concrete interception identified. Cause remains unresolved; no retry fallback or speculative navigation fix added.
- App/UI `build-for-testing` with reviewed results fix and regression passed (`build.log`).
- Final affected group passed all3 cases, process exit0: compact142.628s, largest-text results/purchase62.650s, destination-change/relaunch52.903s (`accepted-tests.log`). Actual compact focus, normal destination-change and identity renders inspected. Earlier start miss remains unexplained, not retroactively passed.
- Initial actual-system motion case failed immediately after row-centre tap left switch0 (expected1). App reported Motion enabled correctly; teardown confirmed original0 and cleaned fixture. See `system-motion-first.log` and exported recording. Test interaction corrected to single trailing-control tap for wide Settings AX rows plus bounded value observation. No tap retries.
- Final app/UI rebuild passed (`final-build.log`). Final expanded largest-text result XP/destination/progress/purchase/relaunch test passed100.348s; actual system Reduce Motion + visible sufficient-description audit passed59.647s; combined exit0 (`final-accessibility-tests.log`). Test confirmed original Motion setting restored. Exported normal/maximum-text/results/reduced-motion captures inspected; card text wraps and scrolls, without horizontal clipping. This is not a VoiceOver traversal audit.
- All test fixtures' cleanup assertions passed in completed cases. Direct-render fixture cleanup launched with only its isolated suite reset; app then relaunched with ordinary preferences and no test arguments. No build/test clients or agents remain running.
- Whitespace check passed during integration.

No user data erasure, deployment, real networking or money movement. Injected session elapsed time is not a physical-device real-time soak. Full VoiceOver/device acceptance and final reference fidelity remain open.

Saved text logs have trailing whitespace/blank EOF normalised; result content and timing remain unchanged. Original bundles remain at the paths in each log.
