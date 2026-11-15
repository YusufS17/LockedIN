# LockedIN visual reset concepts — 2026-11-15

Generated with the built-in image-generation tool, shown inline in chat and copied unmodified into this folder. Exact prompts: `prompt-a.txt`, `prompt-b.txt`, `prompt-c.txt`. User corrections and interpretation: `DIRECTION.md`. Current-app screenshots are separately preserved under `../../references/current-app-2026-11-15/`.

## Deliverables

- `a-pixel-apartment.png`: four proposed welcome/creator/Room/focus screens, dark architectural pixel world.
- `b-studio-blocks.png`: four proposed screens, bright tactile geometric 2.5D world.
- `c-character-workshop.png`: three original character families, standing/seated and identity variations.

All are unapproved concepts, not production assets, native screens, validated sprite sheets or evidence of multiplayer/blocking. No app implementation changed during this exploration. Generated text/layout can drift: A renders starter skin more peach than yellow; B incorrectly carries an onboarding progress bar onto Room. Final UI must use a true yellow initial option and remove progress outside onboarding. Artwork dimensions are not sprite specifications. The pixel examples are illustrations and still require intentional grid/layer/animation production.

## Proposed build phases

1. Choose room direction and character family. Refine a single creator and full-screen focus mockup at actual phone aspect ratio, including seated occlusion and safe areas.
2. Restructure onboarding to Welcome → Creator → name/arrival, with a top bar only, no skip/pager/gallery. Keep staged identity/purchases and unreadable-save protection intact; ordinary content fits without scroll, larger accessibility text may scroll deliberately.
3. Implement creator feature order and numbered skin choices, yellow starter for new identities only, M/F presentation options, Randomize, available hair/faces/glasses, future outfit/accessory sections last. Preserve existing saved identities/owned items; no coin checkout in creator. Existing users' skin/outfit must not reset to defaults.
4. Add Room/Friends/Profile navigation, profile-owned avatar editor, Room decorating, concise setup and immersive focus. Preserve session restore/participant UUIDs, reward receipts, world state and exit confirmation. Keep honest demo labels near simulated friends; remove redundant promotional copy.
5. Produce chosen character/room art as editable runtime layers, with per-pose seating/desk/chair depth. Compare actual normal/compact/largest-text phone renders before claiming fidelity.
6. Real friends: provision selected backend/auth, private invites, membership, shared timer/state, reconnect and authoritative reward identity; verify two accounts/devices. Mockup avatars/status indicators do not close this gate.
7. Optional native focus controls: authorized app selection/shielding, Apple entitlement approval for distribution and physical-device tests. Do not expose friends' private app/screen activity. Simple explicitly shared focus/break statuses are the first social scope.

## Capability sources checked

- https://developer.apple.com/documentation/FamilyControls/requesting-the-family-controls-entitlement
- https://developer.apple.com/documentation/familycontrols
- https://developer.apple.com/documentation/managedsettings
- https://developer.apple.com/documentation/deviceactivity

Current app has an offline solo/demo loop. Authenticated networking and native app shielding remain unimplemented.

## Generation provenance

- A source: `$CODEX_HOME/generated_images/01a1dac2-30b6-7762-b28a-4f1d4182c8bb/exec-4ecc7f3d-7c03-4818-8e6d-c2ab86743e24.png`
- B source: same directory, `exec-60517631-69ef-455b-98ec-7473c86b3242.png`
- C source: same directory, `exec-670cbfa6-979c-4ec6-8989-afc7b3caaa25.png`

No model/version parameter was selected or reported by the tool. No API/CLI fallback used.
