#!/usr/bin/env python3
"""Render actual PixelKit art on macOS without launching an iOS simulator.

UIKit imports and trailing Xcode preview declarations are removed from temporary copies. The sprite geometry,
material shading, palettes and room composition compile from app source.
The bridge implements the tiny bitmap API surface with CoreGraphics/AppKit.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
output = root / 'docs/design/runtime'
output.mkdir(parents=True, exist_ok=True)
files = [
    'Design/Theme.swift', 'Models/CharacterAppearance.swift', 'Models/AvatarStatus.swift',
    'Models/Cosmetic.swift', 'Models/PersonalRoom.swift',
    'PixelKit/PixelCore.swift', 'PixelKit/PixelShader.swift', 'PixelKit/PixelRenderer.swift',
    'PixelKit/SpriteBakery.swift', 'PixelKit/Avatar/AvatarSpriteV3.swift', 'PixelKit/UI/PixelIcon.swift',
    *[str(p.relative_to(root / 'LockedIN')) for p in sorted((root / 'LockedIN/PixelKit/Room').glob('*.swift'))]
]
with tempfile.TemporaryDirectory(prefix='LockedIN-art-') as scratch:
    scratch = Path(scratch)
    combined = scratch / 'AppArt.swift'
    combined.write_text('import AppKit\n' + '\n'.join(
        (root / 'LockedIN' / f).read_text().split('#Preview(')[0].replace('import UIKit', 'import AppKit') for f in files))
    executable = scratch / 'art-preview'
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', '/tmp/LockedIN-swift-cache',
                    str(root / 'Tools/ArtPreview/MacRasterBridge.swift'), str(combined),
                    '-o', str(executable)], check=True)
    subprocess.run([str(executable), str(output)], check=True)
