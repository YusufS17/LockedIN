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

> Read AGENTS.md, PROGRESS.md and .planning/STATE.md before working. We are exploring character art directions. Review docs/design/concepts/character-directions-2026-10-04/. Two generated comparison boards are saved with exact prompts. Wait for my choice before implementing a character style. Preserve existing app code and saves.

Current next step: choose/refine a visual direction, including multiple identities, seated poses and room context. Concepts are not implemented sprites; printed sprite dimensions are illustrative. Previous app build and simulator verification evidence is saved in docs/verification/CONTINUATION_TEAM.md.

## What transfers and what does not

Git carries source, project settings, saved design references, generated concept PNGs/prompts, tests and handoff notes. Local editor/assistant chat history, installed plugins, account credentials, Xcode caches, simulator installations and simulator app saves do not transfer through this repository. Saved project handoffs provide continuity without old chat history. Existing simulator progress stays on the old Mac; new simulator data starts separately.

Install/authenticate your chosen coding assistant separately. Image-generation tool availability depends on that assistant; the saved images and prompts remain usable regardless. If this is an employer-managed laptop, use the employer's permitted setup for personal projects and accounts.
