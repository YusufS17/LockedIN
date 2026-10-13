# Phase 3 — chosen visual direction as a real game world

Prerequisite: user chooses/refines the saved October character family. The current B/C board is a concept, not an approved asset. Review `docs/design/ART_DIRECTION.md`, references and both concept directories before implementation.

1. Lead presents the current app and selected concept together, records concrete proportions/detail choices and freezes one character-family target.
2. Avatar Builder owns `PixelKit/Avatar/AvatarSpriteV3.swift`, portrait views and appearance-compatible sprite layers. Implement standing/seated, turn directions, readable faces/hairstyles, independent garments/shoes/accessories and restrained animation. Keep `CharacterAppearance` saved IDs compatible.
3. Room Builder works separately in `PixelKit/Room/` and composition anchors: coherent isometric furniture, warm lighting, convincing shadows, chair/desk/body/hand layering and uncluttered study props. Do not flatten the room into a generated screenshot.
4. Verifier renders normal/dark skin, short/long hair, glasses, jacket/skirt/boots, standing and seated combinations. Check the personal room and 2/4/8-seat scenes at actual phone size, including break positions and both areas.
5. QC compares those renders with supplied references, checks silhouette/detail/occlusion and saved customisation, and rejects claims based solely on concept images or compilation.

Exit: visible before/after phone evidence, customisation still changes actual layers and persists, room purchases still place real items, and no major perspective/occlusion defect. Final reference fidelity is explicitly reviewed, not inferred from test passes.

Artifacts: repository-bound images/exported renders with exact prompts/provenance where generated; production assets distinguished from concepts. Native source layers remain the interaction implementation. No asset purchase implied.
