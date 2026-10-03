# Offscreen art inspection

Run from the repository root on macOS with Xcode installed:

```sh
python3 Tools/ArtPreview/render.py
```

This compiles the app's actual sprite grids, palettes, shader and room composer. Temporary copies remove UIKit imports and trailing Xcode previews; `MacRasterBridge.swift` supplies the small bitmap API surface using AppKit/CoreGraphics. Production iOS source files are not rewritten by the exporter. No network, user preferences or simulator is needed.

Outputs go to `docs/design/runtime/`:

- `room-native.png`: furnished room at authored resolution.
- `avatar-0-native.png` through `avatar-3-native.png`: default and seeded character art, using the avatar renderer's outline colour.
- `current-art-board.png`: enlarged room and four standing avatars, nearest-neighbour scaling.
- `group-focus-art.png`, `group-break-art.png`: art-only layering studies using current LiveRoomScene anchors, scales and draw order.
- `avatar-pose-family.png`: five preserved appearances (default, Maya, Leo, Sam, independent jacket/skirt/boots) in standing, seated and mirrored seated rows. Raw body grids; the room composite supplies desk occlusion.
- `chair-variants.png`: free stool, cushioned chair and padded chair rendered from the production sprites.

These are **not full SwiftUI screens or iPhone screenshots**. The group study repeats the view's placement formulas in this tool; future changes must keep them in sync. It does not render UI labels, status badges, SwiftUI ambient lighting, shadows, animation, accessibility or interaction. AppKit colour conversion can differ from UIKit. It establishes visible source-art evidence while the simulator is unavailable, not full app verification.

`baseline-art-board.png` is the initial diagnostic export before the art changes. That early exporter omitted avatar outline rings already present in the app; do not attribute the later rings to newly implemented artwork. Current exports include them.
