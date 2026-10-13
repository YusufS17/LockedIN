# Local save lifetime and format policy

2026-10-13. This describes the offline implementation and its acceptance limits; it does not promise a backend, transactional storage or automatic recovery.

| Payload | Supported format and lifetime | Current recovery behavior |
| --- | --- | --- |
| `worldStateV1` | JSON Data, schema version 1; missing schema version migrates as version 1. Required original fields: progression, buildings, activeBuildingID. Later missing ownership/room/receipt fields get legacy defaults. Retained until an explicit supported reset. | Wrong type, unreadable JSON, unsupported version and missing original fields lock mutations and preserve original payload. Future schema version prompts app update. |
| `lockedin.activeStudySession.v1` | JSON Data, version 1; optional old revision defaults to zero. One active or unacknowledged session. | Invalid payload remains untouched until explicit recovery discard. Successful restoration advances the saved clock. Results remain until acknowledgment; blocked world saving retains the result. |
| Avatar, display name, chosen base, onboarding | Codable appearance Data plus separate String/String/Bool preferences. No explicit appearance schema version. | Decode failure falls back to default appearance; raw appearance is not deliberately removed by loading. Separate keys are not an atomic identity transaction. |

## Valid values and compatibility

Session validation currently enforces focus duration 1–180 minutes, zero stake, break allowance 0–10, roster size 1–8 with exactly one user and unique UUIDs, focus percentages 0–100, nonnegative interruption counts, finite timestamps, monotonic-compatible revisions, clock/config duration agreement and consistent running/finished outcomes. Valid legacy version-1 sessions retain their participant UUID. An absent checkpoint revision is supported. Arbitrary nonnegative interruption/config distraction-limit magnitudes and unusually distant finite dates are not comprehensively bounded.

The world loader now enforces nonnegative XP, coins, completed sessions and streaks up to `Int.max / 4`, best streak at least current streak, exactly one record per building type, a recognised unlocked active building, nonnegative banked XP below that building’s required XP threshold (generated saves always roll over level-ups), and building levels up to `Int.max / 600` (positive levels require unlocked state). Receipt XP/coins/breakdown XP use the aggregate bound; receipt levels must be positive. These generous integer-derived limits leave space for reward additions and `200 + level * 150` building thresholds. Progression thresholds saturate instead of overflowing, and binary search bounds level-calculation runtime even at extreme XP. Unknown ownership IDs and placement metadata remain preserved for catalogue compatibility; slot ownership/coherence validation remains open. Invalid essential values follow the existing recovery lock and retain raw bytes. A reward that would exceed these supported bounds rolls back before saving and keeps the pending result under an explicit progression-limit lock. No automatic clamping or pruning occurs.

## Receipt retention

Keep every `sessionRewards` entry for the lifetime of that world. Its key is the user's participant UUID, created once per roster/session and retained through restoration. A session's model ID is a different UUID and must not replace this receipt identity. Zero-reward demo/early-exit receipts are also retained if recorded. No expiry, oldest-first pruning, cap or archive is implemented or permitted as an ordinary cleanup: removing a receipt could award a replay twice.

Before moving receipts out of the aggregate, introduce a durable deduplication ledger/tombstone whose lifetime covers all replayable sessions, with atomic reward/receipt writes and migration/reload/retry tests. A separate server ledger later requires authoritative identity and transactions. An explicit whole-world reset currently clears balances and receipts together; it is not receipt housekeeping and must not be triggered as a simulator workaround.

## Remaining storage guarantees

Balances and receipts share one world JSON payload, which protects ordinary save/reload replay. World and active session remain separate UserDefaults keys. UserDefaults writes have no application-level confirmed durability result, filesystem backup, crash/power-loss transaction, independent-writer serialization or compare-and-swap. Rechecking readability before saving does not merge a concurrently changed valid save. Within-store session revisions reject stale checkpoints; they do not resolve independent stores/processes. Automatic export/repair of unreadable bytes is not implemented. These limits remain engineering work, not evidence of data loss in ordinary fixtures.
