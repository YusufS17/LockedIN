# Save protection, accessibility and service safety — 2026-10-13

Implemented Phase1 and the independent Phase2 simulated-wallet concurrency slice. Detailed delivery/agent plan: `.planning/PHASES_AND_AGENTS.md`, with follow-on packets under `.planning/engineering-phases/`.

## Passing checks

- Final app/UI target build-for-testing: final-build.log. Includes all save/session changes, actor wallet, reduced-motion preference and revised UI tests.
- World save recovery/reward/migration checks: world-recovery.log. Original unreadable/wrong-type/future payloads and existing balances/receipt UUIDs are preserved; funded mutation attempts are blocked.
- Session validation: session-validation.log. Stale/equal revisions, legacy UUIDs, malformed outcomes, exact fractional breaks and wrong-type saved values checked.
- Production study integration: study-integration.log. Passed after fractional-break fix; later small wrong-type guard is covered by final dedicated validation.
- Concurrent simulated services: service-concurrency.log. Eight competing requests per scenario, 120 disposable wallets/960 requests; overdraw and repeated settlement prevented for both verdicts. Existing forgery/replay/monitor tests also pass. Independent QC ran this suite successfully.
- Independent QC reviewed recovery UI, pending results/UUID retention, wallet isolation and motion preference. Diff whitespace checks passed.

## Runtime attempts and limits

First targeted three-case simulator attempt used disposable suites on existing iPhone17 (`5DA4238F-6617-4E78-BBD0-80936A3A4B1E`). It reached largest-text World, opened/closed Decorate, then failed finding the Library Button (UI test line39). It also exceeded the per-test allowance; recovery launch subsequently timed out. Wrapper stopped its own subprocess group at600s (exit124). See ui-first-run.log. The incomplete xcresult lacked Info.plist; attachment export failed. No full runtime pass or screenshot inspection is claimed from that attempt.

Improved test uses identifier lookup across element roles, smaller/bidirectional drags and failure hierarchy capture. Layout/recovery fixtures now opt into reduced motion through a shared DynamicProperty. This reads actual iOS Reduce Motion plus a Debug-only namespaced fixture flag; ordinary/Release settings are respected, no preferences are changed. Actual system setting toggling remains a separate acceptance check.

Initial attempt to write SwiftUI's read-only motion environment failed compilation; preserved in initial-motion-build-failure.log. Replaced with the supported preference wrapper; final build passed.

Targeted420s recheck finished exit65: largest-text World failed at locked café enabled-state assertion; both recovery cases passed (pending results40.471s; unreadable-world35.332s). Completed xcresult attachments exported under recovery-and-world-recheck/. Library/header and recovery Home/results screenshots inspected. Runtime identified redundant accessibility grouping changing native buttons into generic elements with incorrect disabled reporting. Removed that grouping; added explicit Button-role assertions. Button-fix build passed (button-fix-build.log). Final World-only recheck passed exit0 in109.861s with zero failures (ui-accepted-world.log), including native Button roles, selected Library, disabled locked plots, full-width large-text cards, all district entries/stats, decorating and Home return. Attachments/manifest are in accepted-world/.

All three targeted journeys have passing evidence across the revised runs: World109.861s; pending results40.471s; unreadable world35.332s. This is not a claim that the earlier mixed/timeout runs passed. Final largest-text header/Library/locked plots/statistics and ordinary World render (world-normal.png), plus recovery Home/results, were visually inspected. Ordinary World used isolated render suite LockedIN.ui-tests.phase1-normal-world; app/simulator left open there. No agents/build/test/export jobs remain running. No app data erasure. Fixture cleanup after timed-out attempts is not confirmed; suites are namespaced and isolated from ordinary saves.

## Remaining scope

Cross-process/independent writer transactions and exhaustive semantic validation of world economy fields are not implemented. Corrupt-world recovery currently preserves and locks the original, rather than providing an automatic repair/reset. Full VoiceOver, real system Reduce Motion toggling, compact-phone/device soak checks, approved character craft, authenticated multiplayer and native focus enforcement remain open.

No deployment, production migration or real-money work. Prior13 local commits successfully pushed to origin/main through285da60; implementation commit d82004d also pushed successfully. Final accessibility fix/evidence follow-up is included in the next local milestone and requested ordinary push.
