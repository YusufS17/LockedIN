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

## CURRENT WIRING (compiles today)
- `RootView` → `DemoFlowView` (hackathon PNG deck). HomeView → RoomFlowView + StaticRoomScreen. DemoFlowView → LiveSessionView(onFinish:onCancel:) + CharacterCreationFlow.

## NEXT STEPS (in order — build+commit each)
1. **RoomSetupView** (`Views/RoomSetupView.swift`) — real "Set your lock-in": edit a `@State RoomConfig` (room name, subject, focus length stepper, break stepper, distraction stepper, stake shown via `MoneyLabel(config.stakePence)`, competitive/supportive toggle, "Quick demo 20s" toggle, contract summary). `var onStart:(RoomConfig)->Void`, `var onCancel:()->Void`. "Create room" → onStart(config).
2. **LiveSessionView REWRITE** — `init(config:RoomConfig, participants:[SessionParticipant], onFinish:([SessionParticipant])->Void, onCancel:()->Void)`. Real countdown (`.task` Task.sleep loop from config.sessionSeconds), progress ring, aggregate signal ("N focused · M distractions"), a participant list using `SpriteAvatarView(character:status:showStatusBadge:true)` with live state (partway, set Sam `.distracted`). Honest "End session" → onFinish(participants).
3. **SettlementResultsView** (`Views/SettlementResultsView.swift`) — `init(config:, participants:, onDone:)`. `.task { result = await SettlementEngine.run(...) }` using `appStore.commitmentService`. Show room totals (`MoneyLabel(result.totalReturnedPence)` / forfeited), titles (Champion=result.champion, Biggest Culprit=result.culprit unless `!config.competitive` → hide negative), per-participant rows. "Done" → onDone.
4. **RoomFlowView REWRITE** — orchestrator `enum Stage{setup,session,results}`; setup→session→results passing `RoomConfig` + `[SessionParticipant]` (build roster via `SessionParticipant.makeRoster(userCharacter: appStore.selectedCharacter, userName: appStore.displayName, config:)`). No args (`RoomFlowView()`), reads `@Environment(AppStore.self)`. Keep this so HomeView's `RoomFlowView()` still works.
5. **OnboardingHostView** (`Views/OnboardingHostView.swift`) — splash (`Image("Demo01")` full-bleed, tap) → welcome (`Image("Demo02")`, tap) → `CharacterGalleryView(onContinue:)` → set `@AppStorage(PersistenceKeys.onboarding)=true`. statusBarHidden.
6. **RootView REWRITE** — `@AppStorage(PersistenceKeys.onboarding)` gate: false→OnboardingHostView, true→HomeView. (Drop DemoFlowView from root. You may delete `Views/DemoFlowView.swift` + `Views/CharacterCreationFlow.swift` after, OR leave compiling.)
7. Build green, run `/gsd-code-review 2` style pass mentally, commit+push.
8. **THEN** world layer (v2): coins/XP after session, personal room growth, district. See `.planning/reference/world-layer-prompt.md`.

## SPRITES (user provides; see `.planning/reference/SPRITE-ASSETS-SPEC.md`)
When `char_*.png` (transparent) land in `Design images/` or assets: add each as an imageset (`Assets.xcassets/char_maya.imageset/` + Contents.json), names `char_maya`…`char_mei` (+ `char_sam_focused`/`char_sam_distracted`). No code change needed — `SpriteAvatarView` picks them up.

## Conventions
- Cream/charcoal/gold theme tokens only, no raw colours. Dark `buttonFill` pills for primary, gold `accent` for hero CTAs. Modern sans headings; pixel art = game layer only.
- Money: Int pence only, render via `MoneyLabel`. Reduce-Motion: gate animations on `@Environment(\.accessibilityReduceMotion)`.
- Commit per screen: `feat(core): <screen> …`, push after each. Keep HEAD green.
