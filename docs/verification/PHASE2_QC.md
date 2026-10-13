# Phase 2 independent QC

2026-10-13. Reviewer scope: onboarding draft preservation, cancellable reveal work, compact accessibility risks, local-storage policy and pure regression evidence. Builder/runtime results will be recorded after review; no simulator launch, build or setting mutation performed by this reviewer.

## Accessibility control boundary

Read-only local `xcrun simctl help` and `xcrun simctl help ui` succeeded. Public UI options on this installation are `appearance`, `increase_contrast` and `content_size`. No VoiceOver or Reduce Motion toggle is exposed by that help. Debug reduced-motion rendering and accessibility element assertions do not establish actual OS toggles or spoken focus traversal. Those require Settings interaction or a physical-device pass. Do not change private preferences or erase simulator data to manufacture acceptance.

Compact-phone risks to inspect: custom headers and sticky actions at largest text, horizontal outfit/room controls, long user names/subject/goal text, focus/break/results controls below the fold and room art occlusion. Reachability assertions should be accompanied by render inspection; accessibility identifiers do not demonstrate VoiceOver labels, order or meaningful state announcement.

## Storage review

See [save lifetime policy](../STORAGE_LIFETIME.md). Raw unreadable/future payload preservation and retained participant receipt UUIDs are implemented. Follow-up implementation now rejects invalid essential economy/building/receipt values while preserving original bytes and unknown catalogue metadata. Bounded overflow-safe level calculation prevents enormous decoded XP from hanging the UI; normalised building banks prevent runaway contribution loops. Catalogue/slot coherence, independent writers, confirmed disk durability and atomic world/session/identity updates remain open. Receipt pruning must not be introduced without persistent deduplication.

## Current acceptance

Source diff review passed for onboarding same-base preservation, explicit customised-base replacement, cancellable onboarding delays, results reveal cancellation and revised World flourish. The existing editor keeps its separate unsaved-draft discard protection. Results persist the reward before decorative awaits and deduplicate by participant UUID. A retained settlement operation prevents repeats within the same view identity; legacy simulated staked results are not a durable settlement journal across full view destruction/relaunch. This is separate from the persisted zero-stake offline flow.

Independent `bash Tests/run-service-checks.sh` passed: authorised hold identity, forgery rejection, balance conservation, competing authorisations/duplicate settlement, replay, monitor replacement and stop isolation. Fixtures are disposable and no real funds/preferences are used. `git diff --check` passed during review. Source review and these service fixtures do not establish UI lifecycle interaction acceptance.

Dedicated `bash Tests/run-world-semantic-checks.sh` passed, including final reward-limit rollback/payload preservation. Production store/model/catalogue sources test negative/huge counters, invalid streak, duplicate/missing buildings, unsupported active targets, unnormalised banked XP, invalid receipts, supported extreme values, unknown metadata preservation and 1,000 normal level thresholds. Initial runner compile missed a service dependency (fixed); subsequent nested sandbox denied the Observation compiler plugin, then approved escalation passed. No automatic approval rejection occurred. Existing production integration/regression rechecks are lead-owned before handoff.

Final changed-code rechecks also passed sequentially: existing `WorldRewardChecks`, `RewardRulesChecks` and full production `bash Tests/run-study-session-checks.sh`. Stdout saved in `/tmp/LockedIN-phase2-world.log`, `/tmp/LockedIN-phase2-reward.log` and `/tmp/LockedIN-phase2-study.log`. These confirm ordinary rewards, replay, legacy migration, recovery locks, active-session restoration, catalogue purchases and earned-room persistence survive the semantic guard. No further compiler jobs remain running from QC.

Runtime orchestration belongs to lead. Physical-device soak, VoiceOver traversal and actual system Reduce Motion toggle acceptance are pending. Compact-phone render inspection and affected interaction checks remain required before phase completion.

Lead runtime follow-up: compact group and separate system attempt stalled before assertions; only owned process groups stopped. Review identified a plausible pre-setup Settings app initializer; lead moved it into setup and rebuild passed. Subsequent focused run failed destination discovery (exit70), so the hypothesis remains unconfirmed and UI acceptance remains pending. See [actual evidence](offline-beta-phase2-2026-10-13/README.md). No reviewer jobs remain running.
