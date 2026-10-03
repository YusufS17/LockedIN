# Avatar material refinement — 2026-10-03

Reviewed the supplied `docs/design/references/avatar-selection.png` against the existing production-source pose and wardrobe exports. The reference calls for readable layered garments, independent shoes and deliberately shaped hair. Current characters still have a simpler silhouette and smaller detail budget than that artwork; this pass is a material refinement, not final reference acceptance.

Changed only `LockedIN/PixelKit/Avatar/AvatarSpriteV3.swift`:

- Narrowed the dark upper torso plane so chest and sleeve read separately, with shoulder highlights following the garment volume.
- Added distinct tee neck/folds, hoodie pouch/drawstring/cuff details, jumper shoulder/elbow knit folds, jacket pocket seams and shirt pocket/hem folds. Removed the jumper's flat horizontal chest stripe.
- Added offset trouser hip/knee seams and sneaker heel collars, laces and rubber toe details.
- Added sparse swept-part light and shadow runs for long hair, continuing the existing side locks.

Preserved 48×64 size, wardrobe/save IDs, palette keys, silhouette registration, poses, seated leg transformation and the exact desk-hand mask. No persistence or room-composition changes.

Agent verification: `git diff --check` passed. Inspected root's fresh production-source `avatar-pose-family.png`, `avatar-wardrobe-family.png` and `current-art-board.png` exports after the change. The jumper now reads as shaped fabric rather than a horizontal stripe; hoodie pocket and shirt/jacket pockets remain distinguishable across light/dark colours. Sneaker toes, laces and collars read independently from trouser cuffs. Standing and seated rows retain their outlines; long-hair highlights leave the face and glasses readable. No serious source-art defect was found, so no further artwork edit was made. Root owns the shared production build and runtime inspection; their results belong in the continuation handoff. This inspection covers source-art exports only.

Remaining: richer native hair silhouettes across the family, finer face expression and continued room-scale/reference comparison. A standalone source-art sheet does not establish screen accessibility or seated compositing acceptance.


Root completed integrated build, focused UI checks and actual render review after this agent report. See [final team evidence and limitations](CONTINUATION_TEAM.md), which supersedes pending root checks above.
