# Friends-ready clubs — autonomous goal, 2026-10-03

Completed, explicitly requested by user. No token budget or scheduled daemon. Continue implement/review/test/fix across intermediate milestones.

## Roadmap in plain language

1. Preserve the verified solo and demo study loop.
2. Make 2–8 person clubs legible and useful: selectable demo size, balanced seating areas, per-person subject/goal, saved identities and frozen intent.
3. Improve directional seated clothing using separate runtime layers.
4. Strengthen the local private-friends reconnect/intent contract; then implement authenticated service integration with real two-device evidence.
5. Native focus controls follow verified platform capability/device work. No blocking claim yet.

## Ownership

- Root: RoomSession/ActiveStudySession/StudySessionStore, StudySetup/Flow/LiveSession integration, UI/model checks, one Xcode/simulator, exports and acceptance.
- directional_clothing: AvatarSpriteV3 seated garment artwork only, source review with root.
- club_seating: LiveRoomScene, pure StudyAreaLayout and new mapping checks; source task completed, runtime review pending.
- friends_reconnect: isolated FriendsPrototype transport/intent fixtures and architecture; no app networking.

## Acceptance

- 2–8 frozen demo rosters; legacy saves still decode with nil optional intent and retain participant UUIDs.
- Every participant appears once across balanced areas of at most four; no seat modulo overlap. Break placement respects global identity.
- Setup size selection, per-person readable study information and aggregate state, obvious simulated labels; private outcome review never shared.
- Seated top styles are directionally distinct while standing art/independent garment axes/hand registration stay intact.
- Build plus iPhone renders at small/default/max sizes; max-size area switching, participant goals and paused restoration; affected solo/customisation/reward checks.
- Shared-intent and generation-scoped two-client reconnect fixtures pass; real network/auth limitations remain explicit.
- Saved screenshots/provenance, whitespace checks and current handoff updated before completion.

## Completion

All scoped acceptance gates have evidence in `docs/verification/CLUB_EXPANSION.md`. Five final affected UI cases passed together; targeted second-area check passed. Phone renders inspected, model/area checks and 83 friends fixtures passed, whitespace clean. No jobs remain running. Next delivery is real authenticated private-room integration; local fixture success is not networking proof.
