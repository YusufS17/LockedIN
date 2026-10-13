# Engineering maintenance verification — 2026-10-13

Debug app build passed after escalation for simulator-service access; the initial sandbox attempt failed during asset compilation. Final build-for-testing passed, including the app and UI test target. Logs: app-build.log and test-build.log.

Passing disposable regression suites: FocusClock, RewardRules, WorldReward, full production StudySession integration, StudyAreaLayout, simulated ServiceBoundary. Private-friends prototype passed its 83 fixture assertions; no networking or app integration is established.

New integration checks reject unknown cosmetic/furniture IDs and negative building prices without mutation, validate all wardrobe axes, and confirm construction persistence. Service checks reject forged authorisation references without consuming valid holds, verify return/forfeit/replay, and exercise 40 monitor replacement sequences and independent participant stops.

The existing `testAvatarAndDecoratingPersist` UI case was attempted on iPhone 17 (`5DA4238F-6617-4E78-BBD0-80936A3A4B1E`) using disposable preferences and the repository runner with `--timeout 240`. It timed out with exit 124. The runner started but no individual test assertions or passing result were reported. Only this invocation's process group was stopped. No app or simulator data was erased. See ui-run.log. This is a verification blocker, not a successful UI journey or an established app defect. Runtime Reduce Motion toggle acceptance remains pending.

Temporary result bundle: `/var/folders/np/6b4kn9lx3vz8_1jgw6tmw10r0000gn/T/LockedIN-ui-checks-tbvywo73/OfflineLoop.xcresult`. It may be incomplete and is not durable pass evidence.

`git diff --check` passed. Final source/diff review completed by root. No deployment or remote push.

Direct fallback launch succeeded using `-smoke-room home -ui-test-suite LockedIN.ui-tests.engineering-render-20261013`. Initial capture was a blank launch surface; the settled capture [home.png](home.png) is the actual app Home screen and was visually inspected. Room perspective, avatar, editor entry buttons and study dock render legibly. This single screen does not prove an editor journey or runtime Reduce Motion toggling. Simulator/app remain open using this isolated fixture; timed-out test fixture cleanup is not confirmed. No agents/build/test/export jobs remain running.
