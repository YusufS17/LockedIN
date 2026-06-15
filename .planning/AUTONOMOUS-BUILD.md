# LockedIN — Autonomous Build Plan (continuation brief)

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
- **Juice**: animate buildings levelling up, world reveal sequence after results, avatar idle/breathing animation frames, particle/sparkle polish.
- Possibly deepen sprites further (differentiate short/buzz/curly hair more at small sizes; more outfits/accessories).
- Squad/District/build-voting = later networked milestone (needs backend) — see `.planning/reference/world-layer-prompt.md`.

## SPRITES (still pending from user)
Characters render via code-drawn fallback until `char_*.png` land. See `.planning/reference/SPRITE-ASSETS-SPEC.md`. Drop them into `Assets.xcassets` as `char_<id>` imagesets — `SpriteAvatarView` picks them up, no code change.

## SPRITES (user provides; see `.planning/reference/SPRITE-ASSETS-SPEC.md`)
When `char_*.png` (transparent) land in `Design images/` or assets: add each as an imageset (`Assets.xcassets/char_maya.imageset/` + Contents.json), names `char_maya`…`char_mei` (+ `char_sam_focused`/`char_sam_distracted`). No code change needed — `SpriteAvatarView` picks them up.

## Conventions
- Cream/charcoal/gold theme tokens only, no raw colours. Dark `buttonFill` pills for primary, gold `accent` for hero CTAs. Modern sans headings; pixel art = game layer only.
- Money: Int pence only, render via `MoneyLabel`. Reduce-Motion: gate animations on `@Environment(\.accessibilityReduceMotion)`.
- Commit per screen: `feat(core): <screen> …`, push after each. Keep HEAD green.
