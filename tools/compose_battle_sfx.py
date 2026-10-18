#!/usr/bin/env python3
"""Synthesize original battle Foley/magic cues without third-party samples."""
from array import array
import math
from pathlib import Path
import random
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 16000
CUES = {'arrow_release': .16, 'arrow_hit': .16, 'fire_cast': .28,
        'flame_breath': .48, 'water_cast': .30, 'ice_cast': .28,
        'seed_cast': .15, 'wood_hit': .18, 'claw': .20, 'heavy_hit': .25,
        'magic_hit': .24, 'vine_pull': .65, 'meteor': .80, 'freeze': .70,
        'plant_grow': .55, 'explosion': .50, 'healing_water': .55,
        'slime_bounce': .22, 'slime_shot': .32, 'slime_splat': .25,
        'slime_burst': .55, 'slime_rebirth': .65}

def synthesize(name, duration, seed):
    rng = random.Random(seed)
    output = []
    low = 0.0
    phase = 0.0
    for index in range(int((duration + .06) * RATE)):
        t = index / RATE
        u = min(1.0, t / duration)
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        high = noise - low
        envelope = min(1.0, t / .006) * max(0.0, 1.0 - t / duration) ** 1.5
        frequency = 180 + 450 * (1 - u)
        if name in ('arrow_release', 'claw'):
            frequency = 1200 * (1 - u) + 180
            sample = high * (.45 if name == 'arrow_release' else .7) + low * .2
        elif name in ('arrow_hit', 'wood_hit', 'seed_cast'):
            frequency = (330 if name == 'seed_cast' else 180) * math.exp(-t * 12)
            sample = low * .55 + math.sin(math.tau * 760 * t) * math.exp(-t * 50) * .15
        elif name in ('heavy_hit', 'explosion'):
            frequency = 75 * (1 - u) + 30
            sample = low * 1.5 + high * .18
        elif name in ('fire_cast', 'flame_breath'):
            frequency = 120 + 170 * u
            sample = low * 1.1 + high * (.12 + .18 * math.sin(t * 79) ** 2)
        elif name in ('water_cast', 'healing_water'):
            frequency = 480 + 260 * math.sin(t * 35) + 100 * math.sin(t * 71)
            sample = low * .45 + math.sin(math.tau * 1230 * t) * .12
        elif name in ('ice_cast', 'freeze', 'magic_hit'):
            frequency = 1300 - 650 * u
            sample = high * .27 + math.sin(math.tau * 1670 * t) * .14 + math.sin(math.tau * 2310 * t) * .09
        elif name.startswith('slime_'):
            pitch = {'slime_bounce': 310, 'slime_shot': 480, 'slime_splat': 220,
                     'slime_burst': 130, 'slime_rebirth': 620}[name]
            if name == 'slime_rebirth':
                frequency = pitch * (.55 + u * .9) + 45 * math.sin(t * 36)
                sample = low * .2 + math.sin(math.tau * 1240 * t) * .18
            else:
                frequency = pitch * math.exp(-u * 3) + 45 + 65 * math.sin(u * 15)
                sample = low * (.95 if name == 'slime_burst' else .5) + high * .06
                sample += math.sin(math.tau * (pitch * .7) * t) * .22 * math.exp(-u * 7)
        elif name == 'vine_pull':
            frequency = 90 + 550 * (u / .32 if u < .32 else (1 - u) / .68)
            sample = low * .8 + high * .15 * (1 + math.sin(t * 91))
        elif name == 'meteor':
            if t < .35:
                frequency = 600 - t * 900
                envelope *= t / .35
                sample = low * .8 + high * .15
            else:
                frequency = 75 - min(.4, t - .35) * 100
                envelope = math.exp(-(t - .35) * 8) * min(1, (t - .35) / .004)
                sample = low * 1.8 + high * .25
        else:  # roots breaking soil, leaves and a warm growing resonance
            frequency = 110 + 350 * u
            sample = low * .7 + high * .18 * math.sin(t * 53) ** 2
        phase += math.tau * max(20, frequency) / RATE
        sample += math.sin(phase) * (.42 if name not in ('arrow_release', 'claw', 'flame_breath') else .12)
        release = max(0.0, min(1.0, (duration - t) / .06))
        output.append(sample * envelope * release)
    peak = max(abs(value) for value in output) or 1
    return array('h', (int(value / peak * 24000) for value in output))

if __name__ == '__main__':
    output = ROOT / 'assets/audio'
    output.mkdir(parents=True, exist_ok=True)
    for index, (name, duration) in enumerate(CUES.items()):
        with wave.open(str(output / (name + '.wav')), 'wb') as stream:
            stream.setnchannels(1)
            stream.setsampwidth(2)
            stream.setframerate(RATE)
            stream.writeframes(synthesize(name, duration, 7300 + index).tobytes())
    print(f'Composed {len(CUES)} original battle sound effects at {RATE} Hz.')
