# World Layer Prompt (inbound, from ChatGPT) — 2026-06-13

> **Status: APPROVED as a FUTURE MILESTONE (v2 "World") — 2026-06-13.**
> Decision: keep Phases 1–5 (the section-13 commitment demo spine) frozen; the full
> world layer (Squad, District, build voting, room builder, Focus XP) becomes its own
> milestone AFTER the v1.0 demo ships. Do NOT expand the current 5h spine to absorb it.
> Created via /gsd-new-milestone when v1.0 is complete (or promoted from backlog).
> The prompt's own §17 says "wait for approval before performing a large refactor."
> Core principle: **"The study room is where focus happens. The world is what focus
> creates."** Room first → District second → World later.
>
> **USER PRIORITY (2026-06-13):** user is confident on time and wants the full thing
> built out, but the explicit top priority / success bar is: **the rooms and the
> character-onboarding animation must be nice and polished.** NOTE: a "character
> onboarding / avatar creator" is currently NOT in the roadmap — it is a new, important
> requirement to slot in (see conversation). This likely pulls the pixel-art avatar
> rendering earlier than the Phase 3 deferral in 02-CONTEXT D-19.

---

## Summary of what it asks for

A new **persistent world-building layer** wrapped around the existing study room (does NOT replace it). Three connected levels: **Personal Room → Squad Study Room → Shared District/World**. Progression loop: join room → finish session → earn Focus XP + building progress → contribute to a chosen world project → unlock/upgrade a building → choose next build → return to room.

Key additions:
- **Preserve** the live isometric study room with explicit avatar states (focused / deep focus / on break / distracted / finished), name + status + focused/break/distraction counts, accessibility beyond colour.
- **Personal Room**: fixed-slot customisation (desk, chair, lamp, rug, bookshelf, plant, poster, window, floor, wall), locked/unlocked items, colour variants, preview, save. Not a freeform editor.
- **Squad Study Room**: 2–8 members, invite code, persistent identity, shared furniture/level/trophy wall, shared world contribution; every member contributes via study (not host-controlled).
- **Shared District/World**: predefined isometric layouts, fixed building slots, 8 building types (Library Hub, Language Café, Science Lab, Dorm Commons, Engineering Tower, History Hall, Creative Studio, Student Courtyard), each with level/progress XP/required XP/state/slot/asset key/optional bonus. Lightweight, no pay-to-win.
- **World direction via milestone choices**: at an XP milestone the squad picks the next build. Personal world = user chooses; Squad world = members vote (one vote each, deadline, highest valid wins). New screens: "World Path", "Squad Council".
- **Room + World** connecting screen (live room on top, mini district + active projects below; "What this room is building" panel).
- **Economy**: Focus XP (genuine participation), LockedIN coins (cosmetics, non-withdrawable), Building progress. Reward rules reward quality (completion, break discipline, low distraction, goals, streaks w/ cap), not raw time.
- **Post-session world reveal** sequence AFTER the existing results reveal.
- **Live world status**: aggregate counts only (focused/break/deep/distracted). Never expose blocked apps, history, messages, contacts, notifications.
- **Data model (§11)**: PersonalRoom, RoomItemPlacement, Squad, SquadMember, WorldBuilding, ActiveBuildProject, BuildVoteRound, BuildVoteOption, BuildVote, WorldContribution (unique constraints to prevent duplicate votes).
- **Services (§12)**: WorldProgressService, BuildVotingService, RoomCustomisationService. No progression logic in UI.
- **MVP (§13)**: 1 personal room, 1 squad room, 1 small district, 3 building choices, 1 vote round, 1 active project, 1 post-session contribution, seeded demo participants, local persistence or mocked backend. Label simulated parts in STATUS.md.
- **Screens (§14)**: Personal Room Builder, Live Squad Study Room, Room + World, World Path, Squad Council, World Contribution Reveal, District Overview. Preserve existing: avatar creator, home, room lobby, active session, blocked-app warning, session results.
- **UI principles (§15)**: premium dark shell, warm cream cards, gold accents, cozy isometric pixel-art, clear status labels, modern type, nostalgic game layer. World is a reward/navigation layer, not a second full game.
- **Docs to update (§16)**: docs/UPDATED_PRD.md, WORLD_PROGRESSION.md, ROOM_SYSTEM.md, BUILD_VOTING.md, WORLD_DATA_MODEL.md, WORLD_UI_FLOWS.md, MVP_SCOPE.md, HACKATHON_DEMO.md, STATUS.md.
- **§17 First action**: inspect repo, gap analysis, explain non-breaking integration, propose exact file/schema changes, mark real vs mocked, **wait for approval before large refactor.**

(Full original prompt text is in the conversation history for 2026-06-13.)
