# Simulator startup diagnosis and recovery

Observed 2026-09-27 on this workspace's Mac.

**Update: recovered at approximately 14:58 London time. LockedIN installed, launched and rendered its personal-room home screen.** See [actual app screenshot](simulator-recovery/home.png). Full interaction QA remains pending. Earlier failure evidence below is historical.

The iOS 18.6 QA simulator (`9D097FC5-9F94-4E99-89F3-42053E145921`) accepted boot but did not reach usable app startup. Bounded screenshot/install attempts timed out. A previous screenshot was entirely black. Boot-readiness polling also stalled; the polling process was interrupted. No app interaction pass is claimed.

A local crash report, `~/Library/Logs/DiagnosticReports/MTLCompilerService-2026-09-27-014116.ips`, identifies the same simulator UUID and reports:

> Compiler service plugin hung while serving backboardd_58142. Timeout type was Default

This is evidence of a simulator graphics/runtime failure during an earlier attempt. It is not proof that every startup failure has the same cause, nor proof that the app itself is visually correct. The report identifies an Intel MacBookPro16,3 and macOS 15.8. Approximately 20 GiB free disk was reported during inspection.

The app's Debug simulator build previously passed. Do not erase simulator/user data to work around this without authorization. Do not repeat unbounded `simctl install` or `bootstatus` calls. A healthy alternate simulator/runtime or a configured physical iPhone is the next route for runtime verification; meanwhile, progress independent design and code work.

Note: Python `subprocess.run(timeout=...)` itself waited during process cleanup when the system command was hung. A shell/tool session may still need explicit interruption; a configured timeout is not proof of clean cancellation.

## Recovery — 2026-09-27 afternoon

- Confirmed all devices initially reported Shutdown, but 32 orphaned iOS 26.3 runtime processes remained parented to PID 1 from approximately 23 hours earlier.
- Booted the existing iOS 18.6 QA device. Captured the iOS startup spinner before launching LockedIN.
- Sent SIGTERM only to processes whose parent was PID 1 and whose executable path began with the installed iOS 26.3 runtime volume path. No simulator data, app saves, caches or runtime installations were deleted.
- Allowed this boot to continue; later captured the iOS home screen. Opened Simulator for this device. The app install completed and `simctl launch ... com.lockedin.app -smoke-room home` returned PID 34683. After an initially white launch screen, LockedIN rendered the actual home UI.
- Host observations: 8 GiB RAM, approximately 5 GiB swap in use, 15 GiB free disk, very high system load and a disk activity sample near 178 MB/s. These support resource contention as a contributor, but do not prove a sole cause.
- Current Metal compiler sample showed idle waiting; SpringBoard and app samples showed run-loop/render activity. The earlier Metal timeout remains valid historical evidence, not a confirmed explanation of every delay.

**Conclusion:** startup recovered following a fresh boot, cleanup of abandoned runtime processes and additional startup time. The individual contribution of each is unproven. No app-code fix was necessary to obtain the screenshot; recurrence and full interaction behaviour are untested.

Simulator is intentionally left open with LockedIN home visible for the user. Choose **LockedIN Interface QA (iOS 18.6)** in Xcode for subsequent runs. Keep only one simulator running while investigating performance. Do not run broad process-kill commands; the cleanup above depended on verifying that the iOS 26.3 devices were shut down.

Temporary diagnostic samples are under `/tmp/LockedIN-*-sample.txt`; durable visual evidence is in `simulator-recovery/`.

## Recurrence — 2026-10-03

The previous recovery was not durable across sessions. The existing QA device was shut down at session start. First boot failed at launchd; a retry reached the Apple startup screen. Two captures still showed system startup. One bounded install of the successfully built app timed out after 30 seconds and was stopped. No data was reset. Xcode builds and the independent art exporter passed. See [October 3 checkpoint](OCT03_CHECKPOINT.md) for details; current runtime interaction acceptance remains open.


## Alternate runtime recovery — 2026-10-03

The stalled iOS 18.6 device was shut down without erasing data. The existing iPhone 17 / iOS 26.3 device (`5DA4238F-6617-4E78-BBD0-80936A3A4B1E`) successfully launched the app and executed UI tests. Study/break/relaunch/check-in/purchase/relaunch and early-exit checks passed; current evidence and remaining checks are tracked in [offline-loop verification](OFFLINE_LOOP.md). Keep the old startup failure as history, not a current universal blocker.
