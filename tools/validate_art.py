#!/usr/bin/env python3
"""Validate replaceable pixel art independently of gameplay content."""
import json
from pathlib import Path
import re

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
print('Commander art OK: three original 32x48 portraits and element coverage')
