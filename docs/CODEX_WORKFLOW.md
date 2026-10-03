# Working on LockedIN with Codex

Updated 2026-09-27.

## Project instructions and memory

- `AGENTS.md`: the project entry-point instructions Codex discovers. Defines working style, quality standards, autonomy and relevant documents.
- `PROGRESS.md`: the user-facing checkpoint: current work, completed features and actual verification.
- `.planning/STATE.md`: exact handoff, environment, blockers and next action.
- `.planning/ROADMAP.md`: ordered milestones and acceptance gates.
- `docs/USER_DIRECTION.md` and `docs/PRODUCT_BRIEF_ORIGINAL.md`: current intent and the supplied original brief.
- `docs/design/ART_DIRECTION.md` and `docs/design/references/README.md`: visual standard and reference provenance.
- `Tests/README.md`: reproducible focused checks and their limits.

These are saved files, not an unlimited memory guarantee. They let a fresh session recover the project without relying on an old transcript. Current direction supersedes the archived hackathon stage tracker.

## What the user should see during work

Before substantive work: a concrete deliverable and current task. During work: concise progress updates about once a minute, including discoveries, changes and blockers. At milestones: saved progress and a visible result when the task is visual. At handoff: what changed, verification evidence, limitations and next action.

A current-work table is a checkpoint updated by the agent, not a live dashboard. Only list agents that are actually running. One coding agent can run independent tools concurrently; an image-generation job is not another coding agent.

## Context and activity controls

The official command reference documents `/status` for context usage and rate limits, `/review` for code review and `/goal` for a persistent objective. Available commands depend on the environment and access; typing `/` shows the available list. The assistant should not invent exact token counts or claim to control the app's usage display.

Goal mode is optional when the user wants a persistent task across turns. Ordinary chat work does not imply an indefinite background worker after a completed response. No persistent goal was created by this setup.

Sources checked 2026-09-27:

- [Slash commands](https://learn.chatgpt.com/docs/reference/slash-commands)
- [Project instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Astra guidance on focused instructions and skills](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra)

## Skills

Use the available image generation skill for raster concepts/assets and the browser skill for actual browser automation. Read other skills when the task needs their workflow. A SKILL.md is a reusable task procedure, not the project status file. No extra project skill is currently needed just to repeat AGENTS.md or the roadmap.

## Current autonomy

The user authorises continuing implementation and design, including routine local fixes, appropriate tests and mockup generation. Make normal decisions from their brief and references without repeatedly stopping for confirmation. Preserve pre-existing edits and saved app data. Record meaningful decisions. The first deliverable should be completed and verified as far as the environment permits, not merely proposed.
