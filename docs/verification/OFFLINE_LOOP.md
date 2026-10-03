# Offline study-loop implementation and verification

Checkpoint: 2026-10-03. Completed goal: implement and verify the offline study-to-earned-room-upgrade journey, working economically.

## Implemented

- Versioned `ActiveStudySession`: frozen configuration, roster and participant UUIDs, deadline-based focus clock, recorded breaks/interruption self-reports, goal check and results state.
- `StudySessionStore`: restores active/paused/expired sessions and keeps terminal results until acknowledged. Corrupt/unknown-version data is preserved with an explicit recovery action. Existing worlds and reward receipts remain intact.
- Shared solo/demo-club orchestration. Home offers return/check-in/results actions instead of silently replacing a pending session.
- Results show the user's recorded timer time and self-reported events. Supportive results omit competitive crowns. Demo companions never contribute to the user's displayed minutes or rewards.
- Rewards require recorded completion; unfinished snapshots, quick demos and early exits cannot mint completion rewards. Seeded focus-quality and unmeasured clean-focus bonuses removed. Previously saved reward receipts retain their original outcomes.
- Goal check is private and does not reduce rewards. Results offer an affordable catalogue upgrade, bought/placed only on the user's tap.
- Zero-stake results bypass the simulated money service. Failed legacy test settlements show zero confirmed amounts and a failure state instead of invented successful settlement.
- Fixed legacy outfit decoding that overwrote separately saved tops, bottoms and shoes.
- Added isolated iPhone UI test target and bounded runner. Debug test flags never change the production save or release clock.

## Verified

- App Debug simulator builds passed for the session implementation and saved-avatar correction.
- App + UI target `build-for-testing` passed. Final incremental build and simulator-platform target correction also passed.
- All three pre-existing clock/reward/world regression suites passed after reward changes.
- New production-model integration suite passed, including identity/garment persistence, active/paused relaunch, expiry, stable UUIDs, fractional breaks, replay, actual catalogue purchase/placement/reload, demo/exit/incomplete exclusions, corrupt/future payload preservation and settlement error reporting.
- `git diff --check` passed at handoff.

## Meaning and limits

Timer time includes background time unless the user takes a break. It is not measured attention or app-use enforcement, and the UI says so. Interruptions are explicitly self-reported; companions remain simulated. The legacy optional test-stake flow is not covered by active-session restoration. UserDefaults checks cover normal save/relaunch, not power-loss durability or concurrent writers.

The iOS 18.6 QA simulator stayed at the Apple startup screen and was shut down without erasure. The existing iPhone 17 / iOS 26.3 runtime recovered and ran actual app interaction tests. Initial test infrastructure problems were corrected: simulator support in the test target, the goal field accessibility query, disambiguating the leave confirmation, and explicitly selecting editor categories before querying their options. These were recorded failures, not counted as passes.

### Actual iPhone interaction evidence

On 2026-10-03, `testStudyRestoreGoalRewardAndUpgrade` passed (92.944 seconds) and `testEarlyExitDoesNotAwardCoins` passed (37.104 seconds), in `LockedIN-ui-checks-wlxqw5ou/OfflineLoop.xcresult`. The same invocation's editor test failed and was corrected for a separate targeted rerun.

The complete study test drove home → setup → focus → break → terminate/relaunch → resume → terminate/relaunch at an advanced DEBUG restoration date → private goal check → results → terminate/reopen results with unchanged balance → buy/place Teal rug → home → relaunch. It verifies real UI navigation and persistence, but does **not** represent waiting 25 real minutes or a physical-device test. Each case used a disposable preferences suite; normal user data was preserved.

Saved actual screenshots: [home](offline-loop/home.png), [setup](offline-loop/setup.png), [focus](offline-loop/focus.png), [break](offline-loop/break.png), [goal check](offline-loop/goal-check.png), [earned upgrade](offline-loop/earned-upgrade.png), [restored room](offline-loop/restored-room.png), [early exit](offline-loop/early-exit.png).

Visual review: readable setup/check-in/results; the purchased teal rug is visible in the restored room with 5 coins and level 2; early exit displays +0 coins and +0 XP. The break capture catches a button crossfade. The room's square ambient-overlay corners and remaining avatar/seated-layer polish are art follow-ups, not claimed finished. Group-room runtime/reference fidelity remains a separate acceptance gate.

## Reproduce

See `Tests/README.md` for the actual-model integration command and `build-for-testing` + bounded UI runner. Temporary build logs: `/tmp/LockedIN-session-build.log`, `/tmp/LockedIN-session-final-build.log`, `/tmp/LockedIN-loop-ui-build.log`, `/tmp/LockedIN-loop-final-ui-build.log`.

## Completed acceptance and next work

The corrected `testAvatarAndDecoratingPersist` passed in the targeted `LockedIN-ui-checks-zavmivbw/OfflineLoop.xcresult` run (exit 0, TEST EXECUTE SUCCEEDED). Inspected [restored wardrobe](offline-loop/wardrobe-restored.png) and [restored decorating](offline-loop/decorating-restored.png): Deep skin remains selected and rendered; Walnut remains placed; save/return controls are readable. All three current UI cases have passing evidence across the final main run and targeted rerun; no claim that the earlier all-three invocation passed.

The bounded offline-loop goal is complete. Remaining product work: group-room runtime inspection, reference-driven room/avatar polish (including ambient square edges and seated layering), then private friends and native controls. No tests/builds/agents remain running.

Actual iPhone evidence so far: [solo setup](offline-loop/setup.png), captured on iPhone 17 / iOS 26.3. Inspected: readable input fields, duration presets and fixed start action. This is an actual app render, not an art export.
