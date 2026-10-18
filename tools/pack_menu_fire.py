#!/usr/bin/env python3
"""Nearest-sample the reviewed six-frame fire sheet with fixed root anchors."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
args = parser.parse_args()

def convert(*parts):
    subprocess.run(['convert', *map(str, parts)], check=True, timeout=30)

# Reviewed 1536x1024 source: 3x2 cells. Anchor the bright flame root,
# retaining the full original cell/alpha glow within a transparent gutter.
anchors = [(299, 466), (255, 466), (216, 466),
           (296, 455), (255, 455), (222, 455)]
with tempfile.TemporaryDirectory(prefix='vcommander-menu-fire-') as directory:
    parts = []
    for index, (root_x, root_y) in enumerate(anchors):
        scaled = Path(directory) / f'{index}-scaled.png'
        cell = Path(directory) / f'{index}.png'
        convert(args.source, '-crop', f'512x512+{index % 3 * 512}+{index // 3 * 512}',
                '+repage', '-filter', 'point', '-resize', '64x64!', scaled)
        offset_x, offset_y = 40 - round(root_x / 8), 68 - round(root_y / 8)
        convert('-size', '80x80', 'xc:none', scaled, '-geometry',
                f'+{offset_x}+{offset_y}', '-composite', '-depth', '8',
                '-define', 'png:color-type=6', cell)
        parts += [cell, '-geometry', f'+{index * 80}+0', '-composite']
    convert('-size', '480x80', 'xc:none', *parts, '-depth', '8',
            '-define', 'png:color-type=6', ROOT / 'assets/pixel/menu-fire-v1.png')
print('Packed six transparent 80x80 fire frames with a shared root baseline.')
