# Pick up LockedIN on a new laptop

Repository: https://github.com/YusufS17/LockedIN

## Get the project

Sign into GitHub using an account with access to this repository. Clone it through VS Code's Clone Repository command, or use:

```sh
git clone https://github.com/YusufS17/LockedIN.git
cd LockedIN
```

Installing VS Code or a coding assistant alone does not download the project. Open the cloned LockedIN folder in your editor.

## Build the native iPhone app

Use a Mac with Xcode installed, launch Xcode to complete its setup and install an iPhone Simulator runtime. Open `LockedIN.xcodeproj`, choose the `LockedIN` scheme and an iPhone simulator, then Run. Deployment target is iOS 17. Simulator builds need no device signing; running on a physical iPhone requires local signing setup.

Windows/Linux can edit project files and inspect design artifacts but cannot run this project's native Xcode iPhone build locally.

## Resume the work

Tell your coding assistant:

> Read AGENTS.md, PROGRESS.md, .planning/STATE.md and .planning/PHASES_AND_AGENTS.md. Act as lead engineer, preserve existing saves and code, and continue the next authorised offline-beta slice with Builder/Verifier/QC responsibilities. Phase1 and Phase2 wallet/model checks are verified; Phase2 onboarding/lifecycle/save-semantics now builds. Read docs/verification/offline-beta-phase2-2026-10-13/README.md for the runtime blocker. Real character-style and backend/account decisions still require input. No deployment or destructive resets.

Current next work: recover Xcode/simulator destination discovery without erasing data, then verify compact onboarding backtracking, offline results/upgrade persistence, largest text and actual Settings Reduce Motion. Full VoiceOver/device soak remains open. The original character boards remain unapproved concepts. Clone/pull the latest branch and use PROGRESS.md for the actual GitHub receipt; earlier continuation evidence is historical.

## What transfers and what does not

Git carries source, project settings, saved design references, generated concept PNGs/prompts, tests and handoff notes. Local editor/assistant chat history, installed plugins, account credentials, Xcode caches, simulator installations and simulator app saves do not transfer through this repository. Saved project handoffs provide continuity without old chat history. Existing simulator progress stays on the old Mac; new simulator data starts separately.

Install/authenticate your chosen coding assistant separately. Image-generation tool availability depends on that assistant; the saved images and prompts remain usable regardless. If this is an employer-managed laptop, use the employer's permitted setup for personal projects and accounts.
