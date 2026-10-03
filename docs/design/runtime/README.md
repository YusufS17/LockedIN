# Current game artwork

Latest exports generated from the app's PixelKit source on 2026-10-03 using [the offscreen exporter](../../../Tools/ArtPreview/README.md). These images show source art and composition studies, not a running iPhone interface.

## Latest: character redesign after user feedback

The user rejected the prior avatar quality. Current exports now use a new48×64 family with a roughly25-row turned head, fuller garment body, offset shoes, separately authored curls/afro/bun, tapered long hair and corrected seated/coffee/phone/celebration arms. Deep-skin face planes and eye highlights were adjusted for readability. Appearance save identifiers and independent top/bottom/shoe selections are retained.

- `avatar-pose-family.png`: five appearances, standing/seated/mirrored seated.
- `avatar-hair-accessories.png`: rows none/glasses/headphones/cap/beanie; columns short/buzz/curly/afro/long/tied, with skin tones cycling.
- `avatar-gesture-family.png`: rows standing/typing/coffee/phone/celebrating; columns all hairstyles, with tops cycling.
- `avatar-wardrobe-family.png`: all five tops by all five bottoms, with shoes/palettes/face variants cycling.
- `group-focus-art.png` / `group-break-art.png`: desk/body/hand composition studies.

These are actual source sprite exports, not screenshots or generated concept images. The original mockups retain richer hand-crafted hair/clothing volume; do not call the reference fidelity gate complete. Phone evidence is recorded separately in `docs/verification/visual-redesign/`.

## Earlier iterations (historical)

## Findings and changes

The baseline showed front-facing furniture within an isometric room and simplistic avatar detail. The reference quality gap is substantial.

- Authored an angled desk with a 2:1 tabletop, shaded apron, visible legs, projected laptop and notebook, and tintable mug. Retains the existing 68×46 grid footprint, variants and saved selections.
- Added an asymmetrical short fringe, fuller long-hair silhouette, hair highlights, skin/clothing shading, hoodie pocket and sneaker details to existing customisable avatar layers.
- In the live view, taking a break preserves the desk/chair and draws the standing character in front of the seated rows. Added participant/status accessibility labels.

The wardrobe model and saved appearances are retained. These changes are a first art iteration, not reference fidelity completion. The September 28 pass corrected sofa, shelving, wall pieces and cabinet perspective. The October 3 pass adds projected stool/chair variants, smaller shelving and a shared-study composition with perimeter furniture and spaced desks. The break position moves into the foreground aisle so it does not obscure seated faces. Avatar proportions, clothing silhouettes, remaining props and room texture/lighting still need further work.

User feedback on the separate generated concept: make its character less developed/realistic and more game-like; defer that concept revision while room work continues.

See `current-art-board.png`, `group-focus-art.png` and `group-break-art.png`. The initial `baseline-art-board.png` omitted the pre-existing avatar outline rings; current exports include them. Do not present that difference as new app functionality.

October 3: `chair-variants.png` shows the three actual catalogue chair sprites. Shared-room exports omit the personal sofa and use a compact side cabinet; personal-room exports retain the sofa. Full SwiftUI layouts, status badges, lighting and interaction require separate iPhone verification.

## Autonomous team refinement — October 3

The current exports include wider, softer floorboard seams, a shifted/reduced shared shelf to separate dark hair from its background, bent seated legs, directional head/collar shading and separately composited tabletop hands. The shared floor book pile is omitted to keep the standing break pose clear; personal-room decor remains. The exporter mirrors body and hand layers with each desk and uses the same 48-cell avatar scale as the live scene.

`avatar-pose-family.png` compares five independent appearances in standing, seated and mirrored seated poses. The raw seated row intentionally includes body areas hidden by desks in the app; use the group composites to judge occlusion. Long hair and facial/accessory pixels follow the shallow head turn. This is an incremental direction pass; fully authored directional torsos and richer reference detail remain open.

### Friends-ready club clothing pass

Latest source family adds directional seated shoulder/sleeve construction and distinct tee, hoodie, jumper, jacket lapels and shirt collar/buttons. Raw family and group composites were inspected; final tee elbow joins the fixed desk-hand mask. Standing appearance axes are unchanged. Actual custom jacket/skirt/boots seated/break captures are recorded separately under `docs/verification/club-expansion/`. Current group composites remain four-person source studies; the app pages larger rosters into balanced areas.
