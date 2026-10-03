# LockedIN — working agreement

## Product and continuity

Build a polished native iPhone social study world: expressive customisable pixel avatars, cosy isometric rooms, meaningful earned upgrades and eventually real private friend sessions. The hackathon is over. The user is non-technical and wants visible results, clear explanations and autonomous follow-through.

On a new/resumed task, use `PROGRESS.md` and `.planning/STATE.md` to recover the current stage. Consult `.planning/ROADMAP.md` for milestones, `docs/USER_DIRECTION.md` for product intent, and `docs/design/ART_DIRECTION.md` plus `docs/design/references/README.md` for visual work. `docs/PRODUCT_BRIEF_ORIGINAL.md` preserves the source brief. Historical June plans and the old five-hour/fake-stake-first guidance in `CLAUDE.md` are superseded by current direction.

## Working style

- Start substantive work with the concrete deliverable and current task. During work, give short meaningful updates roughly every minute and whenever the plan changes. State what is done, what is running, what is blocked and what comes next.
- Maintain a compact current-work section in `PROGRESS.md`; it is a saved checkpoint, not a live token or agent monitor. List sub-agents only if actually running, with their specific responsibilities. Never invent usage metrics or background activity.
- Continue authorised implementation, local builds, disposable-fixture regression checks, mockup generation and reversible fixes without repeatedly asking whether to proceed. Make routine design decisions from the supplied references and explain material choices.
- Work through implementation and appropriate verification. If one path is blocked, progress independent authorised work and record the exact blocker. Avoid spending the whole session repeatedly trying the same stalled simulator command.
- Save and commit meaningful local milestones after reviewing the diff and running appropriate checks; record any checks still pending. On recovery, preserve accumulated pre-existing edits in a clearly labelled checkpoint commit before new implementation. Keep generated assets and their provenance with the project. Local commits are not a remote backup; record whether a push actually occurred.
- Update progress/handoff notes after milestones and before ending work: files/artifacts changed, actual verification, unresolved issues and the next concrete action. Do not leave claims that a task is running after it has stopped.

## Quality and scope

- Preserve useful existing SwiftUI, models and persistence; preserve all pre-existing uncommitted edits. No broad rewrite just to change the look.
- Treat reference fidelity as a real acceptance criterion. Detailed faces, hairstyles, separate clothing/shoes, coherent room perspective and convincing seated layering matter. Existing procedural art is not automatically the quality target.
- Keep concepts, production assets, compiled UI and runtime-verified screens clearly distinguished. Show visual artifacts in chat when available. Save project-bound generated assets in the repository, with prompt and provenance.
- Rooms, furniture and avatars must remain usable layers; a flat generated screenshot is not an interactive implementation.
- Supportive by default; competitive teasing only by opt-in. Private aggregate accountability only. Label seeded participants and simulated controls. Never claim real multiplayer/blocking before implementing and testing them. No real-money movement.
- Future active-session restoration must preserve the participant UUID currently used to deduplicate reward receipts.

## Build and verification

Project/scheme: `LockedIN.xcodeproj` / `LockedIN`. Build:

```sh
xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/LockedIN-codex-build CODE_SIGNING_ALLOWED=NO build
```

Regression commands and fixture limits: `Tests/README.md`. Those checks use disposable fixtures; run appropriate checks without asking for separate permission. UI changes need real render inspection when available, not just compilation. Use `git diff --check` before handing off edits. No app data erasure as a routine simulator workaround.
