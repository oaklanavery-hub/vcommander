#!/usr/bin/env python3
"""Crop/nearest-sample reviewed menu layers; does not generate or repaint art."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--background', required=True, type=Path)
parser.add_argument('--seated', required=True, type=Path)
args = parser.parse_args()
output = ROOT / 'assets/pixel'

def convert(*parts):
    subprocess.run(['convert', *map(str, parts)], check=True, timeout=30)

convert(args.background, '-filter', 'point', '-resize', '640x360^',
        '-gravity', 'center', '-extent', '640x360', '-depth', '8',
        '-define', 'png:color-type=6', output / 'menu-camp-v1.png')

# The reviewed 1254px source has a clear gap at y=615; the Earth staff
# begins above its mathematical quadrant. Include it only in Earth's crop.
crops = [(0, 0, 627, 615), (627, 0, 627, 615),
         (0, 615, 627, 639), (627, 615, 627, 639)]
with tempfile.TemporaryDirectory(prefix='vcommander-menu-') as directory:
    parts = []
    for index, (x, y, width, height) in enumerate(crops):
        cell = Path(directory) / f'{index}.png'
        convert(args.seated, '-crop', f'{width}x{height}+{x}+{y}', '+repage',
                '-trim', '+repage', '-filter', 'point', '-resize', '112x112',
                '-background', 'none', '-gravity', 'south', '-extent', '128x120',
                '-gravity', 'north', '-extent', '128x128', '-depth', '8',
                '-define', 'png:color-type=6', cell)
        parts += [cell, '-geometry', f'+{index * 128}+0', '-composite']
    convert('-size', '512x128', 'xc:none', *parts, '-depth', '8',
            '-define', 'png:color-type=6', output / 'menu-commanders-v1.png')
print('Packed 640x360 scenery and four transparent seated 128x128 Commander frames.')
