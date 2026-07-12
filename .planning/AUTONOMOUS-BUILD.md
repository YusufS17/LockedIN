# LockedIN — Autonomous Build Plan (continuation brief)

---
## ▶ RESUME HERE (last worked 2026-07-07)

**Status:** executing the USER-APPROVED **Studio-Fidelity Rebuild Plan** (plan file:
`~/.claude/plans/swirling-inventing-feigenbaum.md` — full phase detail there). Session tasks #1–#7
track phases P0–P6.

**Mode:** post-hackathon proper build ([[proper-build-pivot]], [[aaa-game-vision]]). Art is
**organic** — authored in Swift, NO asset packs, NO AI-generated PNGs (user-confirmed 2026-07-07).
Reference = 11 ChatGPT mockups: `.planning/reference/mockups/` + home-dashboard, "Set your
lock-in", expanded customizer screenshots (user-shared; home/lock-in not in repo folder).

**The plan in one line per phase:**
- **P0** baseline + dead-weight removal (dead onboarding views + 21 unused imagesets DELETED, staged)
- **P1** PixelKit: bake-once pipeline (grids+palettes → cached UIImage, nearest-neighbour) — `LockedIN/PixelKit/` WRITTEN, PixelAvatarView rewired at v2-art parity, SpriteAvatarView PNG path dropped
- **P2** character art v3: 48×64 chibi, pose system (stand/sitTypingFront/coffee/phone/celebrate), AvatarPortraitView, appearance split top/bottoms/shoes/face + randomise (legacy outfitStyle decode mapping!)
- **P3** onboarding rebuild: 6 beats (splash/valueprops/8-char gallery/customizer icon-rail/reveal/first-room), PixelButtonStyle/PixelDecor/PixelIcons
- **P4** room art v3: pixel shell+furniture, RoomComposer bake, pixel-space seat anchors + project(), live session mockup chrome (speech bubbles, roster rows, 4-action bar)
- **P5** app shell: custom pixel tab bar (Home/Rooms/World/Profile), home dashboard (greeting/coins/STREAK chips, action cards, friends-now rail via PresenceSimulator, world card), "Set your lock-in" setup (goal+privacy fields, contract card); Progression gains streakDays via decodeIfPresent
- **P6** game feel: scenePhase real user distraction tracking, haptics, sessionHistoryV1 store, Profile/settings, transitions, final cleanup

**Environment gotchas (this machine, 2026-07-07):** Xcode moved to `~/Downloads/Xcode.app`
(26.3); xcode-select now points there, license accepted. iOS 26.2 sim platform was downloading
(`xcodebuild -downloadPlatform iOS`) — old iOS 18.6 runtime is INELIGIBLE for Xcode 26.3.

**PROGRESS (2026-07-12):** ✅ P0 (`a111f6e`) ✅ P1 (`7ceaf74`) ✅ P2 (`e7c3cde`+`9d34b66`+`bea1a71`
+`e0ec721` pose-from-status/cache-key fix) ✅ **P3 onboarding rebuild** — 6-beat flow live:
WelcomeSplash → ValueProps → gallery (2×4 pixel cards) → customizer (icon rail: skin/hair/
hairColour/face/top/bottoms/shoes/accent/accessory + dice randomise, coin gating kept) →
AvatarReveal ("You're all set!", pedestal+burst, name field — identity persists HERE now) →
FirstRoom. `PixelKit/UI/`: PixelPanelShape (stepped corners), PixelButtonStyle (gold/charcoal,
hard drop shadow, pressed-shifts-down), PixelDecor (PixelCloud/PixelSparkle/OnboardingBackdrop/
PageDots/StepBadge/PixelSpeechBubble), PixelIcon (25 authored 12×12 glyphs incl. customizer rail).
ConceptBeatView DELETED. Customizer signature: `initial/initialName/onBack/onSave` — name field
removed (name set at reveal; WorldView caller unaffected, name passes through).
NEXT = **P4 room art v3** (RoomSpriteShell ~192×160, RoomFurniture, RoomComposer bake +
pixel-space seat anchors + project(), LiveSessionView group-room chrome, speech-bubble statuses).

Progress artifact for the user: https://claude.ai/code/artifact/d0ee3838-4ed6-48af-b361-7651eac6ef2e
(update per phase). Sim destination is **iPhone 17 Pro** (iOS 26.x) — first boot of a fresh
runtime is SLOW (simctl install can hang minutes; poll listapps instead of blocking).

**How to QA a single screen headlessly:** add a temporary `#if DEBUG` branch in `RootView.body` that reads `ProcessInfo.processInfo.arguments.contains("-smoke")` and returns the view, then `xcrun simctl launch booted com.lockedin.app -smoke` + screenshot. REMOVE before commit. (Mid-launch screenshots can be blank white — wait ~3-4s and retake.) See memory `simulator-smoke-test`.

---

**Goal:** finish the REAL, working core loop (and then the world layer), matching the design
mockups, on the existing engine. Build screen-by-screen, `xcodebuild` green after each, commit + push each.

**Mode:** proper build. Do NOT add static-PNG shortcuts as functionality. Real SwiftUI on the engine.
Use the asset-driven sprite system (`SpriteAvatarView`) — code-drawn fallback until `char_*.png` arrive.

## How to verify (authoritative)
```
xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```
Must end `** BUILD SUCCEEDED **`. IGNORE harness SourceKit "Cannot find type/Theme in scope" diagnostics — they are FALSE POSITIVES (no module context); xcodebuild is truth. New `.swift` files under `LockedIN/` are auto-included (synchronized root group — no pbxproj edits).

## DONE (committed, green)
- Engine: `Money`(Pence=Int), `CommitmentService`/`MockCommitmentService` (wallet seeds £20/participant), `CommitmentContract`, `SettlementRecord`, `ParticipantSettlementState`.
- Sprite system: `Models/StudyCharacter.swift` (`StudyCharacter`, `CharacterCatalog` 8 chars, `AvatarStatus.assetSuffix`), `Views/Components/SpriteAvatarView.swift` (renders `char_*` PNG or falls back to code-drawn `AvatarView`).
- `Models/RoomSession.swift`: `RoomConfig`(.preset, sessionSeconds, makeFrozenContract()), `SessionParticipant`(+`makeRoster`), `ContractRules.verdict`, `ParticipantResult`, `SessionResult`, `SettlementEngine.run(config:participants:service:) async -> SessionResult` (REAL holds+settle, Sam fails).
- `CharacterGalleryView` (real pick + name, persists `AppStore.selectedCharacterID`).
- AppStore has `selectedCharacterID` (persisted) + `selectedCharacter`.

## VERIFIED APIs (don't re-grep)
- `CommitmentContract(id?, roomName:String, durationSeconds:Int, stakeMinorUnits:MinorUnits, maxDistractionSeconds:Int, maxBreaks:Int, currencyCode="GBP", createdAt?)?` → `.frozen()`. (failable; fields are `let`)
- `service.authoriseHold(participantID:UUID, amountMinorUnits:MinorUnits, contract:CommitmentContract) async throws -> HoldReference`
- `service.settle(holdRef:HoldReference, verdict:SettlementVerdict) async throws -> SettlementRecord`  (verdict `.passed`/`.failed`)
- `service.walletBalance(participantID:UUID) async -> MinorUnits`
- `SettlementRecord`: `returnedMinorUnits, forfeitedMinorUnits, isTestMode, verdict, holdRef, settledAt`
- `MoneyLabel(_ amount: Pence, compact: Bool = false)` — the ONLY £ renderer (has TEST marker)
- `formatPence(_:currencyCode:) -> String`
- `AvatarStatus`: idle/focused/deepFocus/onBreak/distracted/finished (`.label`,`.symbolName`,`.ringColour`,`.assetSuffix`)
- `CharacterAppearance` enums: SkinTone(light/medium/dark/deep) HairStyle(short/curly/long/tied) HairColour(blonde/brown/black/silver) OutfitStyle(casual/academic/hoodie/smart) AccentColour(amber/teal/rose/lavender)
- Theme: `Colour.{background,surface,surfaceMid,appShell,buttonFill,buttonText,cardBorder,sparkle,accent,accentSoft,accentTeal,accentRose,accentLavender,moneyGreen,forfeitRed,textPrimary,textSecondary,testBadgeFg}`, `TypeScale.{largeTitle,title,title2,headline,body,callout,caption,captionBold,money}`, `Spacing.{xs,sm,md,lg,xl,xxl}`, `Radius.{sm,md,lg,pill}`
- Persistence: `CharacterPersistence.save(appearance:displayName:)` / `.load()`; `PersistenceKeys.{character,displayName,onboarding,selectedCharacter}`
- `@AppStorage` must live in Views, never on `@Observable` AppStore.

## CURRENT WIRING (compiles today — real spine, no PNG deck)
- `RootView` (`App/RootView.swift`) → `@AppStorage(onboarding)` gate: false→`OnboardingHostView`, true→`HomeView`.
- `OnboardingHostView` → ConceptBeatView → CharacterGalleryView → FirstRoomBeatView → sets onboarding flag.
- `HomeView` `.lockIn` → `RoomFlowView()` (staked loop). `.solo` → `SoloRoomView()`. `.group` → `GroupRoomView()`. ALL real — no PNG screens left.
- `RoomFlowView` = orchestrator `enum Stage{setup,session,results}`: `RoomSetupView` → `LiveSessionView(config:participants:onFinish:onCancel:)` → `SettlementResultsView(config:participants:onDone:)`.
- `LiveSessionView` = Demo09 isometric room (IsometricRoomView + placed SpriteAvatarViews + status pills + stat tiles + toolbar).
- `SettlementResultsView` = Demo10 animated reveal (real SettlementEngine money + trophy/coins/champion/culprit/world teaser).
- `BrandLockHeader` shared masthead. DemoFlowView + CharacterCreationFlow DELETED.

## DONE (committed, green) — steps 1–6 of the original plan
1. ✅ RoomSetupView  2. ✅ LiveSessionView (isometric room)  3. ✅ SettlementResultsView (animated)
4. ✅ RoomFlowView orchestrator  5. ✅ OnboardingHostView (real beats, not PNG)  6. ✅ RootView gate + PNG deck deleted

## NEXT STEPS (in order — build+commit each)
7. ✅ **Solo / Group rooms** — real `SoloRoomView` + `GroupRoomView` on the iso engine; `StaticRoomScreen` deleted. No PNG screens left.
8. ✅ **Smoke test passed** (simulator) — onboarding → rooms → reveal, no crashes. NOTE simulator cfprefsd cache: `simctl erase` to reset first-launch state, not just reinstall.
9. ✅ **Pixel-art characters** — `PixelAvatarView` (code-drawn Canvas sprite); SpriteAvatarView + AvatarView render it. User has NO PNGs — build all art in-engine.
10. ✅ **World layer v1 (Phase 7) FUNCTIONAL** — `Progression`(XP/coins/level) + `RewardRules` + `WorldState`/`WorldBuilding` + `WorldStore`(@Observable, persisted via `WorldPersistence`). AppStore holds `world`. Reveal awards real XP/coins (once) + level-up flourish + real building-progress card. `WorldView` (district: level ring, coins, hero room, 8 buildings tap-to-focus/build, stats). Home world chip + reveal "View world" open it.

## VISION (committed) — see `.planning/VISION.md`
Aim: state-of-the-art studio-quality game (Pokémon/Minecraft tier) — proper world + deep character customization + gamification. **Build systems first, then polish the game/visual side.** Art is code-drawn/in-engine (never ask for PNGs).

## GAME-SIDE POLISH (in progress)
- ✅ **Deeper sprites** — `PixelAvatarView` 12×16 full-body (eyes/pupils, mouth, legs, shoes, outfit motifs); 6 hair styles, 6 hair colours, accessory axis (glasses/headphones/cap/beanie).
- ✅ **Character customizer/wardrobe** — `CharacterCustomizerView` (live preview, all axes, coin-gated premium cosmetics via `CosmeticCatalog`/`WorldStore.purchase`). `AppStore.userStudyCharacter` makes customization show everywhere. Entry: World "Edit your character" + onboarding "Customise".

## NEXT (still to do for the game side)
- ✅ **Customizable personal room** — `Models/PersonalRoom.swift` (`RoomSlot` 10 slots, `RoomItem`, `RoomItemCatalog`, `PersonalRoom`); `WorldStore.{ownsRoomItem,purchaseRoomItem,selectRoomItem}` (RoomCustomisationService); `IsometricRoomView(room:)` now variant-driven (floor/wall tints + desk/chair/rug/poster/lamp/shelf/plant variants, default preserves old look); `PersonalRoomBuilderView` (live preview + slot chips + coin-gated item tiles). Entry: World "Customise room". Shows everywhere (hero/live/solo room). Verified in sim (113 coins, price tags, customized render).
- ✅ **Juice pass v1** — `SpriteAvatarView` idle breathing (per-status: calm breath / break sway / distracted jitter, phase-offset per avatar, reduce-motion gated; pickers+small list rows opt out via `animated:false`). Reusable `SparkleBurst` (radial particle one-shot, reduce-motion gated). Wired: reveal trophy celebratory burst; World building tiles pop + sparkle on successful build/focus tap (`celebrate(_:)`). Verified in sim (world layout clean, reveal trophy + coin count-up).
- Possibly deepen sprites further (differentiate short/buzz/curly hair more at small sizes; more outfits/accessories).
- More juice still ahead: dedicated post-results world-reveal *screen*, building level-up celebration tied to the session that caused it, coin/XP fly-to-counter particles.

## LIVE ROOM = THE PRODUCT (room vertical slice — adapting ChatGPT room directive to SwiftUI)
See `docs/ROOM_IMPLEMENTATION_PLAN.md` (audit + gap analysis + what's mocked). Web-specific
bits (.ts types, image-rendering, src/features) mapped to SwiftUI; art stays code-drawn.
- ✅ **Live room promoted to hero** — `LiveSessionView` room scene now fills the screen (was a 240pt card). Header shows room name + mode (Competitive/Supportive) + "N/M still LockedIN".
- ✅ **Compact group-status bar** — "N focused · N break · N distracted" + Details affordance (replaced the 3 stat tiles).
- ✅ **Expandable participant panel** — bottom sheet (medium/large detents) with per-participant cards: focused min / off-task / warns-left / signal bars + "simulated multiplayer" disclaimer.
- ✅ **In-room world-progress board** — "BUILDING · <active building>" + progress bar pinned on the room scene (real `WorldStore.activeBuilding`). The world shows up *inside* the room.
- ✅ **Break corner + transition** — cosy break-area object (mug+table); user avatar springs to it on an approved break (re-slotted), back to desk on resume.
- Verified in sim: hero room w/ 4 avatars + status pills, group-status bar single-line, participant sheet, world board, break corner.

## POST-HACKATHON — building it properly (state-of-the-art, curated)
Hackathon is OVER. No more MVP/demo scoping — build the real app/game to a high bar (see
memory `proper-build-pivot`). Chosen first axis: **art & world fidelity**.
- ✅ **Sprite engine v2** (`PixelAvatarView`) — 24×32 (was 12×16), procedural top-left **light shader** (auto highlight/shadow/AO, no hand-authored tones), silhouette outline + floor shadow, bigger expressive faces, distinct hair (short/buzz/curly/afro/long/tied), real **animation frames** via TimelineView (blink/type/sip/phone-glance/celebrate), reduce-motion gated. API unchanged → every caller upgraded.
- ✅ **Room engine v2** (`IsometricRoomView`) — furniture **depth** (top+front faces) + floor shadows, plank-textured floor, warm **lamp glow** + window **light-cast** + cool window pool + edge **vignette**, drifting **dust motes** + lamp breathing (TimelineView, reduce-motion gated), **day/night** window sky. PersonalRoom variant system + caller API preserved.

### Art fidelity — next
- Verify/tune the new art in the REAL flows (customizer, live room w/ 4 avatars, world, reveal, onboarding) — the lab looks great; the live room may want a **multi-desk squad layout** so 4 avatars each get a desk (currently one central desk).
- Per-participant micro-animations already in the sprite (type/sip/phone) — make sure live-room statuses drive them.
- Curated polish pass: transitions, haptics, day/night tied to real time, richer onboarding character-creator.

## LIVE ROOM — still ahead (next room polish)
- Per-participant micro-animations (typing/writing/page-turn/phone-glance) — currently status faces + idle breathing only.
- 8-participant layout (slots scale 4→8); more desks/seats drawn in-scene.
- Distracted/break states fire fast in a quick-demo config so they're visible without waiting for crackMoment (~45% elapsed).
- Trophy shelf + richer back-wall decoration in the live room; reach the room builder contextually from the room.
- Squad/District/build-voting = later networked milestone (needs backend) — see `.planning/reference/world-layer-prompt.md`.

## SPRITES (still pending from user)
Characters render via code-drawn fallback until `char_*.png` land. See `.planning/reference/SPRITE-ASSETS-SPEC.md`. Drop them into `Assets.xcassets` as `char_<id>` imagesets — `SpriteAvatarView` picks them up, no code change.

## SPRITES (user provides; see `.planning/reference/SPRITE-ASSETS-SPEC.md`)
When `char_*.png` (transparent) land in `Design images/` or assets: add each as an imageset (`Assets.xcassets/char_maya.imageset/` + Contents.json), names `char_maya`…`char_mei` (+ `char_sam_focused`/`char_sam_distracted`). No code change needed — `SpriteAvatarView` picks them up.

## Conventions
- Cream/charcoal/gold theme tokens only, no raw colours. Dark `buttonFill` pills for primary, gold `accent` for hero CTAs. Modern sans headings; pixel art = game layer only.
- Money: Int pence only, render via `MoneyLabel`. Reduce-Motion: gate animations on `@Environment(\.accessibilityReduceMotion)`.
- Commit per screen: `feat(core): <screen> …`, push after each. Keep HEAD green.
