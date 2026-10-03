# Focus regression checks

Run from the repository root on a Mac with Xcode:

```sh
swiftc -module-cache-path /tmp/LockedIN-swift-cache LockedIN/Models/FocusClock.swift Tests/FocusClockChecks.swift -o /tmp/LockedIN-clock-checks
/tmp/LockedIN-clock-checks
swiftc -module-cache-path /tmp/LockedIN-swift-cache LockedIN/Models/Progression.swift Tests/RewardRulesChecks.swift -o /tmp/LockedIN-reward-checks
/tmp/LockedIN-reward-checks
```

The reward check compiles the actual reward implementation with small input fixtures to avoid bringing iOS avatar/UI dependencies into a macOS executable. Compile these checks separately: each has its own entry point. These checks do not replace simulator interaction tests.

## Persistent reward checks

```sh
swiftc -module-cache-path /tmp/LockedIN-swift-cache LockedIN/Models/Progression.swift LockedIN/Models/WorldState.swift LockedIN/App/WorldStore.swift Tests/WorldRewardChecks.swift -o /tmp/LockedIN-world-checks
/tmp/LockedIN-world-checks
```

Compiles the real store, save model and reward engine with UI/catalog fixtures. Uses and removes an isolated UserDefaults suite; does not touch the app save. Checks repeated results, store reload, distinct sessions, early exit/demo isolation, migration from saves without receipts and reset. Swift's Observation macro requires permission to execute its compiler plugin when running under a nested sandbox.

Receipt identity is the user's per-session roster participant UUID. Active-session restoration retains that UUID and is covered by the integration suite below. These tests validate normal save/reload, not power-loss durability or simultaneous writers.

## Durable study and earned-room-item integration

```sh
bash Tests/run-study-session-checks.sh
```

Compiles the real session, avatar, room catalogue, store, reward, identity persistence and settlement implementations. Only the app-root forfeit-name constant is a fixture. Uses and removes an isolated UserDefaults suite. Covers active and paused relaunch, expiry during suspension, participant UUID retention, frozen checkpoint identity/configuration, rejection of contradictory saved clock phases, custom garment restoration, 2–8-person frozen roster/shared-intent restoration and legacy missing-intent migration, fractional breaks, self-reported interruptions, goal review, repeated results, actual catalogue purchases and placement after reload, early exit/demo exclusion, unfinished snapshots, corrupt/future save preservation, and truthful settlement failure handling. Dates are injected; this is not a real-time 25-minute device test.

## iPhone interaction checks

```sh
xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/LockedIN-codex-build CODE_SIGNING_ALLOWED=NO build-for-testing
python3 Tests/run-ui-checks.py --device <existing-simulator-UUID> --timeout 900
```

The `LockedINUITests` target drives the real screens, takes screenshots and verifies starting, pausing, relaunching, resuming, goal check, earning/purchasing an upgrade, returning home, results replay without duplicate awards, an early exit, saved avatar/decorating selections, independent top/bottom/shoe persistence, and the labelled demo-club setup/focus/break/relaunch/results journey. Each test uses a unique `LockedIN.ui-tests.*` preferences suite, cleaned up at the end. The actual user save is not reset. Debug-only launch arguments advance the restoration date after a real UI start/pause/resume sequence; production clocks are unchanged. Screenshot attachments are in the printed `.xcresult` bundle. Use `--only-testing LockedINUITests/OfflineStudyLoopTests/testAvatarAndDecoratingPersist` to rerun only a specific case. The wrapper bounds the run and stops only its own subprocess group on timeout. Compilation or a system startup screenshot does not count as a UI test pass.


## Private-friends contract fixtures

```sh
bash Tools/FriendsPrototype/run-checks.sh
```

Isolated Foundation prototype outside the app target; verifies admission/privacy, capacity, monotonic revisions/reconnect, validated startup cache and stable participant UUIDs. It is not a network, backend-transaction, authentication or real-device test. See [prototype limitations](../Tools/FriendsPrototype/README.md) and [beta architecture](../docs/PRIVATE_FRIENDS_BETA.md).

## Study area mapping

```sh
bash Tests/run-study-area-checks.sh
```

Compiles the actual pure mapping helper; checks balanced size1–8 areas, one occurrence per roster index and global break membership. Pixel occlusion/readability still require iPhone inspection. UI checks now include 2- and 8-person clubs, area selection, shared study text and restoration. Repeat `--only-testing` to run multiple specific cases.


## Onboarding and larger text

`OfflineStudyLoopTests` also includes `testOnboardingArrivalAndSavedIdentity`, `testOnboardingAtLargestAccessibilitySize` and `testHomeAndSetupAtLargestAccessibilitySize`. These use the same disposable suites; the latter two request the largest accessibility content-size category through a launch argument. Assertions establish journey reachability; inspect screenshots for actual wrapping/scrolling quality. October3 recovery runs encountered simulator cleanup/destination failures; see [recorded limits](../docs/verification/RECOVERY_POLISH.md). They are not yet all passing acceptance evidence.
