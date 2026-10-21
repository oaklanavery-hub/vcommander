#!/usr/bin/env python3
"""Nearest-neighbor pack original assassin artwork without changing older frames."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel'
parser = argparse.ArgumentParser()
for element in ('fire', 'water', 'earth', 'slime'):
    parser.add_argument('--' + element, required=True, type=Path)
args = parser.parse_args()
original = Image.open(OUT / 'roster-v4.png').convert('RGBA')
atlas = Image.new('RGBA', (256, 448))
atlas.paste(original, (0, 0))
catalog = json.loads((OUT / 'roster.json').read_text())
manifest = json.loads((OUT / 'art_manifest.json').read_text())
for index, element in enumerate(('fire', 'water', 'earth', 'slime')):
    image = Image.open(getattr(args, element)).convert('RGBA')
    image = image.crop(image.getchannel('A').getbbox())
    image.thumbnail((56, 54), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (64, 64))
    frame.paste(image, ((64 - image.width) // 2, 60 - image.height))
    atlas.paste(frame, (index * 64, 384))
    card_id = f'card_{element}_06'
    card = json.loads((ROOT / f'data/cards/{element}/{card_id}.json').read_text())
    palette = {key: tuple(bytes.fromhex(value)) for key, value in
               (catalog['colors'] | catalog['palettes'][element]).items()}
    small = frame.resize((16, 16), Image.Resampling.NEAREST)
    rows = []
    for y in range(16):
        row = ''
        for x in range(16):
            pixel = small.getpixel((x, y))
            row += '.' if pixel[3] < 100 else min(palette, key=lambda key:
                sum((pixel[i] - palette[key][i]) ** 2 for i in range(3)))
        rows.append(row)
    catalog['sprites'][card_id] = {'name': card['display_name'], 'element': element,
                                  'role': card['role'], 'pixels': rows}
    manifest['units']['frames'][card_id] = [index, 6]
assert atlas.crop((0, 0, 256, 384)).tobytes() == original.tobytes()
atlas.save(OUT / 'roster-v5.png')
manifest['units']['texture'] = 'res://assets/pixel/roster-v5.png'
(OUT / 'art_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
(OUT / 'roster.json').write_text(json.dumps(catalog, indent=2) + '\n')
print('Packed four specialists; all twenty-one existing atlas frames are byte-identical.')
