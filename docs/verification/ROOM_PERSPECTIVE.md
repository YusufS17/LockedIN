# Room perspective pass

Checkpoint: 2026-09-28. User prioritised coherent isometric furniture before further character refinement.

Implemented in the existing PixelKit renderer:

- Window, clock, poster and noticeboard project onto their respective 2:1 wall slopes using integer pixel offsets.
- Bookcase and drawers retain catalogue materials/variants and now have projected fronts plus separate top and side faces.
- Sofa rebuilt from angled cushions, arms, seams and feet along the left wall.
- Wall and furniture anchors adjusted for the new sprite bounds. Cache keys revised.

Debug iPhone Simulator build passed (`/tmp/LockedIN-perspective-build.log`). Offscreen exporter compiled and its room art was inspected. See `../design/runtime/current-art-board.png`; this is source-art evidence, not an iPhone screenshot.

Remaining: bookcase visual weight, chair/floor props, group-room crowding, character fidelity, and full interaction walkthrough. Current code supports local avatar/decor selection, study setup, focus/break timer and persisted rewards. Group companions and focus percentages remain simulated/seeded; real friend networking, app enforcement and active-session recovery remain unimplemented.

Runtime verification: installed and launched the new build on the iOS 18.6 QA simulator. Inspected [actual home screenshot](simulator-recovery/home-perspective.png). Wall slopes and furniture depth are visible in the app. Full interaction QA is still pending. Simulator left open; no build/export/diagnostic jobs remain running.
