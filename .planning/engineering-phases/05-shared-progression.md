# Phase 5 — shared rooms grow through earned effort

Prerequisite: Phase4 authoritative private sessions and stable identity/reconnect. Shared progression is not the current local `WorldStore` economy.

1. Economy Builder defines authoritative individual outcomes and permitted group contributions. Rewards use recorded timer/explicit events; never claim measured attention without native evidence.
2. Backend Builder creates persistent shared-world balances/ownership/placements and an idempotent contribution/purchase ledger. Proposed server schema and migrations require review; do not run production migrations automatically.
3. Client Builder adds a shared-room store/adapter while preserving the solo `WorldState` and catalogue. Purchases show pending, confirmed or failed states and do not announce success before authoritative confirmation.
4. Verifier retries outcome/purchase requests, disconnects before/after acknowledgement and restores both devices. Verify duplicate/replayed operations cannot mint XP/coins, spend twice or lose a confirmed placement.
5. QC checks private aggregate accountability, opt-in competition, ownership/access boundaries, upgrade clarity and renderer compatibility.

Exit: two real accounts see the same earned furniture after termination/reconnect, balances and receipts remain consistent under retries, and the user can explain which room received the effort. Restore participant UUIDs; recreating the roster must not create a new reward claim.

No real-money movement, public ranking or deployment is implied. Retention and recovery require explicit compatible designs, not deleting old receipt IDs to reduce storage.
