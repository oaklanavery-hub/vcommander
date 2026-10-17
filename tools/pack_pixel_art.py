#!/usr/bin/env python3
"""Package reviewed generated atlases into native game cells with ImageMagick.

This only crops, nearest-samples and pads the approved artwork. It does not
generate artwork. Source crop rectangles refer to the reviewed 1254px roster.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--commanders', required=True, type=Path)
parser.add_argument('--units', required=True, type=Path)
args = parser.parse_args()
output = ROOT / 'assets/pixel'

def convert(*values):
    subprocess.run(['convert', *map(str, values)], check=True, timeout=30)

# Exact reviewed crops include detached effects and avoid neighboring sprites.
# Each fitted sprite has transparent gutters and the same 60px foot baseline.
roster = [
    ('magma_golem', (0, 8, 349, 302), (54, 54)),
    ('fire_imp', (350, 70, 235, 240), (40, 44)),
    ('sorcerer', (635, 15, 298, 295), (48, 52)),
    ('dragon', (937, 38, 310, 269), (56, 50)),
    ('ice_giant', (4, 315, 340, 306), (56, 54)),
    ('sea_serpent', (348, 315, 291, 310), (54, 54)),
    ('penguins', (650, 395, 255, 230), (44, 43)),
    ('water_wizard', (936, 313, 312, 310), (52, 54)),
    ('giant_tree', (0, 623, 341, 315), (56, 54)),
    ('pitcher_plant', (343, 629, 296, 311), (52, 54)),
    ('bear', (638, 685, 303, 252), (56, 46)),
    ('wood_archers', (958, 668, 294, 270), (52, 50)),
    ('commander_plant', (9, 940, 310, 309), (46, 46)),
]
output.mkdir(parents=True, exist_ok=True)
convert(args.commanders, '-filter', 'point', '-resize', '384x192!', '-define', 'png:color-type=6', output / 'commanders-v2.png')
with tempfile.TemporaryDirectory(prefix='vcommander-atlas-') as directory:
    directory = Path(directory)
    parts = []
    for index, (name, (x, y, width, height), (fit_width, fit_height)) in enumerate(roster):
        cell = directory / (name + '.png')
        convert(args.units, '-crop', f'{width}x{height}+{x}+{y}', '+repage', '-trim', '+repage',
                '-filter', 'point', '-resize', f'{fit_width}x{fit_height}',
                '-background', 'none', '-gravity', 'south', '-extent', '64x60',
                '-gravity', 'north', '-extent', '64x64', '-define', 'png:color-type=6', cell)
        parts += [str(cell), '-geometry', f'+{(index % 4) * 64}+{(index // 4) * 64}', '-composite']
    convert('-size', '256x256', 'xc:none', *parts, '-define', 'png:color-type=6', output / 'roster-v2.png')
print('Packed three 128x192 Commander frames and thirteen 64x64 army frames.')
