# LockedIN: product reset and first playable slice

Date: 2026-09-26. Based on the repository, supplied brief and visual references.

## Confirmed direction

- Keep the native iPhone app.
- Warm cream interface, detailed cosy rooms, expressive Habbo-inspired avatars.
- Build a product for personal use and private friend groups. The hackathon deadline no longer applies.
- The emotional centre is a place and character that improve through studying. Test stakes are optional demo material, not the home screen's main proposition.
- Supportive study is the default; competitive comparisons are opt-in.

## Existing architecture

SwiftUI, iOS 17+, one application target, no third-party packages or backend. `AppStore` supplies identity, mock services and `WorldStore`. Identity, cosmetics, furniture and world progression save locally through UserDefaults/JSON. Active sessions live in view state.

Navigation: `RootView` → six-step onboarding → `HomeView`. Home presents separate full-screen solo, group, commitment and world flows. Each study flow ultimately uses `LiveSessionView` and `SettlementResultsView`. Avatar editing and the room builder are accessible from World. The home screen gives the simulated £5 contract the strongest prominence.

Rendering: `PixelKit` assembles and caches code-drawn avatar and room textures. `CharacterAppearance` has nine customisation axes. `RoomComposer` places furniture; `LiveRoomScene` layers chairs, seated avatars and desks. The asset catalog currently contains no character or furniture image assets. Older comments promising automatic PNG discovery are stale: `SpriteAvatarView` currently calls the code renderer directly.

There were already nine modified tracked files and five untracked room-renderer source files at the start. Preserve them. Planning documents contain contradictory and outdated completion claims; code and runtime verification take precedence.

## Gap analysis

| Area | Actual state | Decision |
|---|---|---|
| Native app structure | Working SwiftUI target, shared stores, local saves | Preserve |
| Avatar creation | Gallery, hair/skin/face/clothing/accessory options, persistence | Preserve data; improve silhouette, face, layered art, previews and discoverability |
| Room decorating | Ten fixed furniture slots, free/earned items, saved choices | Preserve model; show real item previews and obvious entry from personal room |
| Art | Procedural pixel textures, shaders, ambient lighting, poses | Assess visually and replace/refine pieces against one consistent art standard |
| Home/navigation | Stake-first menu; identity and room customisation buried in World | Make personal room the landing experience |
| Session setup | Subject and contract settings; solo duration picker | Add concrete goal, 25/50/90 presets, supportive default, concise setup |
| Timer | One-second decrement in view task | Replace with timestamp-based session state; define background and break behaviour |
| Early exit | Leave invokes the same finish method as timeout; does not set `leftEarly` | Fix before progress is trusted |
| Focus metrics | Seeded percentages; live/reveal minutes derived from full planned duration | Calculate actual elapsed focus, break and override totals; label demo data |
| Breaks | Count allowance; pause indefinitely; no break-duration accounting | Track start/end and allowance consistently |
| Enforcement | Mock adapter exists but is not consumed by live session | Implement explicit simulation + pause/reason/hold override; no real blocking claims |
| Results | Staged cards, test settlement, XP/coins, local world contribution | Preserve presentation structure; use measured session outcome and transparent score |
| Rewards | Persisted; early leave and 20-second demo can receive full rewards | Separate demo from earned progression; make awards idempotent by session ID |
| Test commitments | Mock service with integer pence | Keep behind demo; holds currently occur at results, not session start; error fallback fabricates settlement |
| Supportive/privacy | Toggle hides culprit card, but individual negative metrics remain visible | Make supportive default; define visibility for every room/result surface |
| Multiplayer | Scripted participants only, no invite/account/network system | Separate private-beta milestone; do not call seeded characters real friends |
| Sharing/history | No result sharing or durable session history | Add privacy-safe sharing/history after outcome data is reliable |
| Verification | Existing app builds; no automated test target | Add focused tests for clock, exits, scoring and duplicate reward prevention |

## What to retire or defer

Retire the five-hour deadline as a product constraint, stake-first home, implied charity transfers, disabled chat teaser, duplicated/stale renderer documentation and unearned demo progression. Keep real money, public rooms, feeds, voice/video and a full freeform editor out of the first slice.

Do not replace working SwiftUI/store/persistence code simply to change visual direction. A move to another engine needs evidence from actual performance or interaction limits.

## Implementation order and acceptance gates

1. **Art and room proof.** One personal room, one four-seat variant, one expressive customisable character family. Establish pixel scale, isometric projection, palette, outlines and seated/standing poses. Use separate room shell, furniture and avatar layers. Gate: customisation visibly changes real runtime art, characters sit correctly behind desks, and the scene looks good at iPhone size. A flattened generated mockup is reference only.
2. **Reliable session core.** Extract clock/outcome state from the screen; record timestamps, goal, breaks, distractions, overrides and completion. Distinguish leaving from finishing. Freeze rules at start. Gate: background/foreground, cancellation, early exit, break/resume, duplicate result presentation and demo isolation have meaningful tests.
3. **One coherent local loop.** Personal room → subject/goal + preset → solo or clearly labelled demo squad → calm focus room → goal check → reveal → earned room item. Add deliberate simulated interruption flow. Gate: one complete session works offline; supportive mode has no negative public ranking; rewards survive relaunch exactly once.
4. **Private friends beta.** Authentication, invite codes, 2–8 person rooms, authoritative session state, presence/reconnect handling and shared room persistence. Gate: two real iPhones see the same room and outcomes; retries/reconnections cannot duplicate rewards; only intended aggregate information leaves the device.
5. **Native focus controls.** Separate capability work after the loop is usable. Verify actual platform capabilities and permissions before promising app blocking. Keep simulation visibly labelled until implemented.

The local vertical slice is a milestone, not the finished friend-ready product. Genuine multiplayer is required for the private beta.

## Verification record

- Baseline simulator build: **passed**, Debug, `CODE_SIGNING_ALLOWED=NO`, Xcode iPhone Simulator SDK 26.2.
- Build output: `/tmp/LockedIN-codex-build.log` (temporary local artifact).
- No app source was changed during the initial audit.
- New image concept is an art-direction reference, not evidence of implemented visuals or functionality.
- Concept and generation prompt: `docs/design/warm-room-concept.png` and `docs/design/CONCEPT.md` (built-in imagegen).
- Simulator startup/install/launch remained pending during inspection; initial screenshot was blank. Runtime visual QA is not yet verified.
