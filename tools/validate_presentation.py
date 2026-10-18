#!/usr/bin/env python3
"""Validate data-driven combat cues and original battle WAV files."""
from array import array
import hashlib
import json
from pathlib import Path
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / 'data/presentation/combat_cues.json').read_text())
assert catalog['schema_version'] == 1
cards = [json.loads(path.read_text()) for path in (ROOT / 'data/cards').rglob('*.json')]
assert set(catalog['units']) == {card['id'] for card in cards} | {'commander_plant'}
for profile in catalog['units'].values():
    assert profile['projectile'] in {'none', 'arrow', 'seed', 'fireball', 'dragonfire', 'water_orb', 'ice_shard'}
    assert profile['motion'] in {'slam', 'slash', 'cast', 'shoot', 'bite'}
    assert profile['rig'] in {'brute', 'claw', 'mage', 'dragon', 'serpent', 'healer', 'tree', 'pitcher', 'bow', 'plant'}
    for key in ['attack_sound', 'impact_sound']:
        assert (ROOT / 'assets/audio' / (profile[key] + '.wav')).is_file(), profile
sys.path.insert(0, str(ROOT / 'tools'))
from compose_battle_sfx import CUES
seen = set()
for name in CUES:
    path = ROOT / 'assets/audio' / (name + '.wav')
    with wave.open(str(path), 'rb') as stream:
        assert stream.getnchannels() == 1 and stream.getsampwidth() == 2
        assert stream.getframerate() == 16000 and stream.getnframes() > 1600
        raw = stream.readframes(stream.getnframes())
    samples = array('h', raw)
    if sys.byteorder != 'little':
        samples.byteswap()
    assert 1000 < max(abs(value) for value in samples) < 32767, name
    assert abs(samples[0]) < 100 and abs(samples[-1]) < 100, name
    digest = hashlib.sha256(raw).hexdigest()
    assert digest not in seen, name
    seen.add(digest)
print(f'Presentation OK: {len(catalog["units"])} unit profiles and {len(CUES)} distinct original battle SFX, valid WAVs without clipping.')
