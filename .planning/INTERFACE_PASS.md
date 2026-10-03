# Interface pass — 2026-09-26

User authorised planning and implementation. iPhone first; warm cream shell, cosy rooms, Habbo-inspired avatars. Preserve all existing local modifications.

## Deliverables

1. Room-centred home, direct wardrobe/decorating entry, honest study-club demo entry, saved progression.
2. Shared study setup surface for solo and demo club: subject, concrete goal, 25/50/90 presets, supportive defaults.
3. Larger wardrobe preview with labelled options; furniture browser using actual renderer assets.
4. Calm live-session interface showing subject/goal, room and meaningful actions. Preserve existing flows while fixing early-leave classification and task cancellation.
5. Build verification and simulator screenshots where available. Record limitations honestly.

## Design rules

- Use existing native scene and saved models; do not flatten concept artwork into the interface.
- Modern readable text and generous touch targets. No pixel borders around every control.
- Real saved balances/progress only; no fabricated friends-online counts.
- Existing generated concept remains reference art, not implementation evidence.
- No networking or real blocking claims. Friend-ready multiplayer and trustworthy scoring remain separate milestones in PRODUCT_AUDIT.md.

## Status

- [x] Repository audit and direction
- [x] Home and shared components
- [x] Study setup and club preview
- [x] Customisation interfaces
- [x] Live interface and exit behaviour
- [x] Final build and regression checks
- [ ] Simulator visual verification — blocked by simulator startup

## Verification so far

- Main interface implementation compiled successfully with Xcode's iPhone Simulator SDK.
- FocusClock regression checks passed: suspension, breaks, duplicate pause/resume, expiry, rounding.
- RewardRules regression checks passed: ordinary rewards retained, early exits and quick demos mint no XP/coins.
- Final palette/status/results adjustments compiled successfully; `git diff --check` passed.
- Runtime screenshots remain unverified: iOS 26 stalled at startup. A separate iPhone 16 / iOS 18.6 simulator progressed to a system loading spinner, but app installation/boot completion remained pending. No actual app screenshot or interaction pass is claimed.

## Scope limits

This pass uses the existing procedural room and avatar artwork with clearer presentation and real furniture previews. It does not yet achieve the generated concept's illustration fidelity. Real multiplayer, focus enforcement, computed focus scores, durable session recovery remain follow-up work.

## Resumed work — 2026-09-27

- Recovered this handoff; prior interface work is preserved.
- Added persistent reward receipts keyed by the user's per-session participant UUID. Repeated results return the original outcome without changing XP, coins, streaks or building contributions. Receipts and balances use one world save; old saves decode with an empty receipt ledger.
- WorldStore accepts an isolated preferences suite for regression checks. Tests cover duplicate results, save/reload, separate sessions, demo/exit isolation, old-save migration and reset.
- Clock, reward rules and persistent reward checks passed. Final simulator build and whitespace checks passed.
- Simulator still renders black. Installation stalled; no app visual or interaction verification is claimed.
- Next: restore simulator runtime verification, then measured session outcomes and durable active-session recovery. Persisted receipts do not restore active sessions; any future restoration must preserve the roster participant UUID used for the receipt.
