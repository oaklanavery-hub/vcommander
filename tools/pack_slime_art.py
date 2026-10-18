#!/usr/bin/env python3
"""Pack reviewed Slime artwork, preserving all existing atlas pixels.

Only nearest-neighbor sizing, padding and atlas placement are performed here.
The five source images are original imagegen output; see pixel/CREDITS.md.
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel'
parser = argparse.ArgumentParser()
for name in ('princess', 'giant', 'cannon', 'ball', 'barrel'):
    parser.add_argument('--' + name, required=True, type=Path)
args = parser.parse_args()


def convert(*values):
    subprocess.run(['convert', *map(str, values)], check=True, timeout=30)


with tempfile.TemporaryDirectory(prefix='vcommander-slime-') as directory:
    directory = Path(directory)
    portrait = directory / 'princess.png'
    convert(args.princess, '-filter', 'point', '-resize', '124x184',
            '-background', 'none', '-gravity', 'center', '-extent', '128x192',
            '-define', 'png:color-type=6', portrait)
    convert('-size', '512x192', 'xc:none', OUT / 'commanders-v2.png', '-geometry', '+0+0', '-composite',
            portrait, '-geometry', '+384+0', '-composite', '-define', 'png:color-type=6', OUT / 'commanders-v3.png')
    parts = []
    native = []
    for index, (name, fit) in enumerate([('giant', '56x54'), ('cannon', '56x52'), ('ball', '42x42'), ('barrel', '46x50')]):
        cell = directory / (name + '.png')
        convert(getattr(args, name), '-trim', '+repage', '-filter', 'point', '-resize', fit,
                '-background', 'none', '-gravity', 'south', '-extent', '64x60',
                '-gravity', 'north', '-extent', '64x64', '-define', 'png:color-type=6', cell)
        parts += [cell, '-geometry', f'+{index * 64}+256', '-composite']
        native.append(Image.open(cell).copy())
    convert('-size', '256x320', 'xc:none', OUT / 'roster-v2.png', '-geometry', '+0+0', '-composite',
            *parts, '-define', 'png:color-type=6', OUT / 'roster-v3.png')

    def palette_rows(image, width, height, palette):
        # Read native art into an editable palette-character fallback catalog.
        colors = {key: tuple(bytes.fromhex(value)) for key, value in palette.items()}
        rows = []
        for y in range(height):
            row = ''
            for x in range(width):
                pixel = image.getpixel((min(image.width - 1, int((x + .5) * image.width / width)),
                                        min(image.height - 1, int((y + .5) * image.height / height))))
                row += '.' if pixel[3] < 100 else min(colors, key=lambda key: sum((pixel[i] - colors[key][i]) ** 2 for i in range(3)))
            rows.append(row)
        return rows

    catalog_path = OUT / 'roster.json'
    catalog = json.loads(catalog_path.read_text())
    catalog['palettes']['slime'] = {'a': 'e26ba6', 'l': 'ffe1ef', 'G': '39b86b', 'L': 'b5f680', 'D': '175948', 'W': 'faf9f2', 'S': 'b6bddb'}
    for index, name in enumerate(['Giant Slime', 'Slime Cannon', 'Slime Ball', 'Slime Barrel']):
        catalog['sprites'][f'card_slime_0{index + 1}'] = {
            'name': name, 'element': 'slime', 'role': ['tank', 'range', 'melee', 'melee'][index],
            'pixels': palette_rows(native[index], 16, 16, catalog['colors'] | catalog['palettes']['slime'])
        }
    catalog_path.write_text(json.dumps(catalog, indent=2) + '\n')
    catalog_path = OUT / 'commanders.json'
    catalog = json.loads(catalog_path.read_text())
    catalog['palettes']['slime'] = {'a': 'de5894', 'c': 'f39cbd', 'l': 'ffe4ed', 'd': '813d68'}
    catalog['sprites']['slime'] = {'pixels': palette_rows(Image.open(portrait), 32, 48, catalog['colors'] | catalog['palettes']['slime'])}
    catalog_path.write_text(json.dumps(catalog, indent=2) + '\n')

manifest_path = OUT / 'art_manifest.json'
manifest = json.loads(manifest_path.read_text())
manifest['commanders']['texture'] = 'res://assets/pixel/commanders-v3.png'
manifest['commanders']['frames']['slime'] = [3, 0]
manifest['units']['texture'] = 'res://assets/pixel/roster-v3.png'
for index in range(4):
    manifest['units']['frames'][f'card_slime_0{index + 1}'] = [index, 4]
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
print('Packed four Commander portraits and seventeen unit sprites; existing atlas pixels retained.')
