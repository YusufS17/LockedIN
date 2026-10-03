# First interface implementation

Implemented 2026-09-26. See `.planning/INTERFACE_PASS.md` for checklist and verification status.

## What changed

- **Home:** personal room and saved avatar are the main content. Edit avatar and Decorate open directly. Start studying opens setup. The study-club card explicitly says Demo. Coins and progress come from the saved world. Test-stake flow moved into More.
- **Setup:** solo and group share subject, goal and 25/50/90-minute controls. Start requires nonblank subject and goal. The demo club previews four occupants and labels simulated companions. Supportive mode is the default for this flow.
- **Wardrobe:** larger avatar preview, scrollable named categories, labelled appearance options, retained saved cosmetics and coin unlocks.
- **Decorating:** real furniture sprites replace generic symbol swatches for furniture; floor/wall retain material swatches. Selection writes through the existing room store. Placed/Owned/coin-price states are visible.
- **Live focus:** room, timer and goal; break/resume control; participant details in a sheet; no disabled chat teaser. Existing room progression remains visible beneath the goal.
- **Session correctness:** deadline-based countdown replaces decrement-only timing. Cancellation ends the timer task. Early leave is recorded, final minutes use elapsed focus time, and early exits/quick demos do not mint XP or coins. Supportive results hide the failed-count tile.

## Try it

Open `LockedIN.xcodeproj`, select the LockedIN scheme and an iPhone simulator, then Run. Complete the existing onboarding to reach the new home.

For direct screen inspection in Debug, the existing launch-argument harness now accepts:

```
-smoke-room home
-smoke-room avatar
-smoke-room builder
-smoke-room solo
-smoke-room group
-smoke-room live
```

Use one pair at a time in the scheme's Run arguments; remove it to return to normal onboarding/home routing. These previews do not replace interaction testing. Normal avatar editing saves identity; the standalone avatar preview intentionally has a no-op save callback.

## Remaining work

The underlying pixel assets are still the existing code-drawn artwork. This is an interface implementation, not completion of the richer art target. Scores and companions are still seeded. No real invites, multiplayer or app blocking have been added. Timestamp timing handles UI suspension, not app termination/restoration. The broader roadmap remains in `PRODUCT_AUDIT.md`.

Regression check commands and limitations are in `Tests/README.md`.

## Verification

Final Debug simulator build passed. Clock and reward regression checks passed; `git diff --check` passed. Runtime visual/interaction verification remains outstanding because both simulator startup attempts stalled before an app screen could be inspected. The screenshot captures were system loading screens, not app renders.

## Follow-up — 2026-09-27

Rewards now save a receipt with the world balances. Presenting the same session result again, including after a world-store reload, returns the original reward without adding XP, coins, streaks or building progress twice. Existing saves migrate with an empty receipt ledger. The key is the user's per-session participant UUID, which future active-session restoration must preserve.

Persistent reward regression checks passed (see `Tests/README.md`). Simulator installation still stalls with a black system screen; visual verification remains outstanding.

## Visual follow-up — 2026-09-27

Added source-art exports independent of the simulator (`Tools/ArtPreview/`), an isometric desk, initial avatar hair/material detail, and a fix retaining desks/chairs during breaks. Personal and group focus/break art exports inspected; latest iPhone Simulator build passed. Full UI verification remains blocked, and reference-level visual quality remains unfinished. User requests a more game-like character in the generated concept; that revision is deferred.
