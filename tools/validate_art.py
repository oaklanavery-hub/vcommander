#!/usr/bin/env python3
"""Validate replaceable pixel art independently of gameplay content."""
import json
from pathlib import Path
import re
import struct

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'assets/pixel/roster.json').read_text())
assert catalog['schema_version'] == 1
cards = [json.loads(path.read_text()) for path in (root / 'data/cards').rglob('*.json')]
for card in cards:
    assert card['id'] in catalog['sprites'], f"Missing sprite for {card['id']}"
    sprite = catalog['sprites'][card['id']]
    assert sprite['element'] == card['element'] and sprite['role'] == card['role']
for key, sprite in catalog['sprites'].items():
    colors = catalog['colors'] | catalog['palettes'][sprite['element']]
    assert all(re.fullmatch(r'[0-9a-fA-F]{6}', value) for value in colors.values())
    rows = sprite['pixels']
    assert len(rows) == 16 and all(len(row) == 16 for row in rows), key
    assert all(cell == '.' or cell in colors for row in rows for cell in row), key
    assert sum(cell != '.' for row in rows for cell in row) > 20, key
print(f"Art OK: {len(catalog['sprites'])} original 16×16 sprites, palette and roster coverage")

commanders = json.loads((root / 'assets/pixel/commanders.json').read_text())
assert commanders['schema_version'] == 1 and commanders['width'] == 32 and commanders['height'] == 48
for path in (root / 'data/commanders').glob('*.json'):
    commander = json.loads(path.read_text())
    element = commander['element']
    sprite = commanders['sprites'][element]
    colors = commanders['colors'] | commanders['palettes'][element]
    assert all(re.fullmatch(r'[0-9a-fA-F]{6}', value) for value in colors.values())
    assert len(sprite['pixels']) == 48 and all(len(row) == 32 for row in sprite['pixels']), element
    assert all(cell == '.' or cell in colors for row in sprite['pixels'] for cell in row), element
    assert sum(cell != '.' for row in sprite['pixels'] for cell in row) > 100, element
print(f"Commander art OK: {len(commanders['sprites'])} original 32x48 portraits and element coverage")

atlas_manifest = json.loads((root / 'assets/pixel/art_manifest.json').read_text())
assert atlas_manifest['schema_version'] == 1
for group, expected in [('menu_fire', {str(index) for index in range(6)}),
                        ('upgraded_units', {card['id'] for card in cards}),
                        ('units', {card['id'] for card in cards} | {'commander_plant'}),
                        ('menu_commanders', {json.loads(path.read_text())['element'] for path in (root / 'data/commanders').glob('*.json')}),
                        ('commanders', {json.loads(path.read_text())['element'] for path in (root / 'data/commanders').glob('*.json')})]:
    atlas = atlas_manifest[group]
    assert set(atlas['frames']) == expected, group
    path = root / atlas['texture'].removeprefix('res://')
    with path.open('rb') as stream:
        header = stream.read(26)
    assert header[:8] == b'\x89PNG\r\n\x1a\n', path
    width, height = struct.unpack('>II', header[16:24])
    assert header[25] == 6, f'Expected RGBA transparency: {path}'
    assert width % atlas['cell_size'][0] == 0 and height % atlas['cell_size'][1] == 0
    seen = set()
    for name, (x, y) in atlas['frames'].items():
        assert (x, y) not in seen, name
        seen.add((x, y))
        assert x >= 0 and y >= 0 and (x + 1) * atlas['cell_size'][0] <= width and (y + 1) * atlas['cell_size'][1] <= height, name
print(f"Detailed art OK: {len(atlas_manifest['commanders']['frames'])} Commander frames, {len(atlas_manifest['units']['frames'])} roster frames, RGBA textures and unique regions")

scene = atlas_manifest['menu_scene']
with (root / scene['texture'].removeprefix('res://')).open('rb') as stream:
    header = stream.read(26)
assert header[:8] == b'\x89PNG\r\n\x1a\n' and header[25] == 6
assert list(struct.unpack('>II', header[16:24])) == scene['size'] == [640, 360]
assert atlas_manifest['menu_commanders']['cell_size'] == [128, 128]
assert atlas_manifest['menu_fire']['cell_size'] == [80, 80]
print('Menu art OK: 640x360 scenery, four seated Commander frames, six fire frames and valid texture regions')

# Decorative environments are independent of gameplay collision/placement.
scenery_bytes = 0
for name in ("forest-clearing-v1.png", "lodge-courtyard-v1.png"):
    path = root / "assets/pixel" / name
    raw = path.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', path
    width, height = struct.unpack('>II', raw[16:24])
    assert 1280 <= width <= 2048 and 720 <= height <= 1152, path
    assert abs(width / height - 16 / 9) < 0.03, path
    assert raw[25] in (2, 6), f"Expected RGB/RGBA pixel scenery: {path}"
    scenery_bytes += len(raw)
assert scenery_bytes < 10_000_000, "Keep both scenery assets within the browser download budget"
assert (root / "assets/fonts/PixelifySans.ttf").stat().st_size < 200_000
assert "SIL OPEN FONT LICENSE" in (root / "assets/fonts/OFL-PixelifySans.txt").read_text()
print("Fantasy scenery OK: two original bounded 16:9 environments, download budget and self-hosted font license")
