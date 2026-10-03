# Private friends contract prototype

**Not part of the iPhone target. No networking, authentication, backend or production multiplayer.** Read the [beta architecture and prerequisites](../../docs/PRIVATE_FRIENDS_BETA.md) before reusing these types.

Run from the repository root on a Mac with the Swift compiler installed:

```sh
bash Tools/FriendsPrototype/run-checks.sh
```

The runner creates and removes its own temporary executable and module cache. It has no preferences, database, simulator or network access. A successful run prints the assertion count and the fixture-only limitation.

- `FriendsProtocol.swift`: in-memory invitation/membership authority, minimal aggregate snapshot, and monotonic client reducer.
- `FriendsChecks.swift`: executable negative-path and recovery fixtures using injected dates.
- `run-checks.sh`: isolated compile/run/cleanup.

The authority assumes callers are already authenticated; passing someone else’s UUID is possible here because this is not an auth implementation. Its single Swift value stands in for a serialized durable transaction. Concurrent server requests, process crashes, durable invite storage, command idempotency and authenticated stream delivery still need real integration checks. UUID invite tokens are fixture values, not a production secret protocol.

A lobby has 1–8 members and requires 2–8 to start. Membership freezes on start. Each member receives one immutable per-session participant UUID; reconnect/restoration keeps it so a future integration can retain the app’s existing reward receipt key. There is no reward calculation here. `finish` is a fixture transition, not an authoritative study-completion decision.

The snapshot reducer accepts full snapshots only, ignores old revisions, and rejects contradictory equal revisions, changed participant identity, frozen shared-intent changes and phase reversal. `FriendsConnection` wraps it with lifecycle state: startup-only recipient-scoped cache remains disconnected; each reconnect creates a generation token; only a fresh authorised full read for the current generation can enable command revisions. Streams received before that read and all callbacks from closed generations are ignored. Gaps in full snapshots are safe. A read older than the cache cannot establish freshness. Contradictory/invalid current-generation payloads close the generation and retain the last valid display; current-generation access denial clears it. Disconnection preserves the display and disables controls. No commands are queued offline.

Members can explicitly share an optional `SharedStudyIntent` in the lobby: a nonempty subject up to 40 characters and a nonempty goal up to 120 characters. The whole intent is optional; when present both fields are required. Text must already be trimmed and contain no control characters. A person can publish or withdraw only their own intent. Start freezes it with the roster; private planning text and post-session review have no wire fields. These are Unicode character limits matching the app, not a production request-body byte limit.

`FriendsEnvelope.recipientID` is a routing/privacy guard, **not proof of authentication**. A real adapter must derive the identity from its verified channel, reauthorise membership on refresh/subscription, distinguish fresh responses from cached frames, and call `accessDenied` on current permission denial. An old callback cannot clear a newly connected account's cache. There is no network transport, auth token handling, heartbeat timeout, disk persistence or server-side revocation implementation. The raw `FriendsReplica` is a lower-level ordering reducer; app controls must depend on the connection wrapper, never the raw reducer's connected flag.

Production still needs schema versioning, server clocks, per-person break/leave/completion, membership removal, cancellation/host departure behavior, durable idempotent commands, byte limits, and privacy-safe account deletion. A fixture owner's `finish` never establishes reward eligibility.

Last run: 2026-10-03, **83 assertions passed** with `swiftc`, including a two-client delivery/reconnect sequence. No app or physical-device integration is claimed.

A production read-to-subscription handoff must be atomic or replay snapshots newer than the acknowledged read revision. The reducer intentionally ignores pre-read stream frames and does not buffer them; an adapter that drops its last update during this handoff could remain stale until another full snapshot. Test that race against the actual service before integration.
