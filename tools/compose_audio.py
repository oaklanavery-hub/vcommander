#!/usr/bin/env python3
"""Compose VCommander's original, sample-free music and effects (requires ffmpeg)."""
from array import array
import math
from pathlib import Path
import random
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'assets/audio'
RATE = 22050
OUTPUT.mkdir(parents=True, exist_ok=True)


def note(buffer, start, duration, midi, gain, voice='harp'):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    length = int(duration * RATE)
    offset = int(start * RATE)
    for i in range(length):
        t = i / RATE
        attack = min(1, t / 0.018)
        release = min(1, (duration - t) / 0.12)
        phase = math.tau * frequency * t
        if voice == 'pad':
            sample = (math.sin(phase) + 0.18 * math.sin(phase * 2.003)) * attack * release
        else:
            sample = (math.sin(phase) + 0.28 * math.sin(phase * 2) + 0.09 * math.sin(phase * 3)) * math.exp(-t * 5) * attack * release
        buffer[(offset + i) % len(buffer)] += sample * gain


def write_wav(path, samples):
    peak = max(abs(x) for x in samples) or 1
    scale = 0.82 / max(1.0, peak)
    data = array('h', (int(max(-1, min(1, x * scale)) * 32767) for x in samples))
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(data.tobytes())


def music(name, tempo, battle=False):
    beat = 60 / tempo
    samples = array('f', [0]) * round(16 * 4 * beat * RATE)
    chords = [(50, 54, 57), (43, 47, 50), (47, 50, 54), (45, 49, 52),
              (50, 54, 57), (43, 47, 50), (40, 43, 47), (45, 49, 52)]
    melody = [(74, 78, 81, 78), (79, 78, 74, 71), (78, 81, 83, 81), (76, 73, 69, 73),
              (74, 78, 81, 86), (83, 81, 79, 78), (76, 79, 78, 74), (73, 76, 81, 73)]
    rng = random.Random(316)
    for bar in range(16):
        start = bar * 4 * beat
        chord = chords[bar % 8]
        for pitch in chord:
            note(samples, start, 4 * beat, pitch + 12, 0.045, 'pad')
        for count in (0, 2):
            note(samples, start + count * beat, beat * 1.7, chord[0] - 12, 0.22)
        for count, pitch in enumerate(melody[bar % 8]):
            note(samples, start + count * beat, beat * 0.9, pitch + (12 if bar >= 8 and count == 2 else 0), 0.15)
        for eighth in range(8):
            note(samples, start + eighth * beat / 2, beat * 0.7, chord[eighth % 3] + 24, 0.055)
        if battle:
            for count in range(4):
                position = int((start + count * beat) * RATE)
                for i in range(int(0.08 * RATE)):
                    t = i / RATE
                    sound = math.sin(math.tau * (90 - t * 300) * t) * math.exp(-t * 50) * 0.12
                    sound += rng.uniform(-1, 1) * math.exp(-t * 100) * 0.025
                    samples[(position + i) % len(samples)] += sound
    temporary = OUTPUT / (name + '.wav')
    write_wav(temporary, samples)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(temporary), '-c:a', 'libvorbis', '-q:a', '3', str(OUTPUT / (name + '.ogg'))], check=True)
    temporary.unlink()


def effect(name, pitches, duration=0.35, gain=0.35):
    samples = array('f', [0]) * int((duration + 0.3) * RATE)
    for index, pitch in enumerate(pitches):
        note(samples, index * duration / max(1, len(pitches)), duration, pitch, gain)
    write_wav(OUTPUT / (name + '.wav'), samples)


if __name__ == '__main__':
    music('campfire', 96)
    music('crossing', 112, True)
    for name, pitches, duration in [
        ('hover', [83], 0.07), ('click', [74, 81], 0.12),
        ('pick', [74, 78, 81], 0.22), ('attack', [48, 43], 0.07),
        ('defeat', [55, 48], 0.15), ('heal', [81, 86], 0.25),
        ('skill', [62, 69, 74, 81], 0.38),
        ('victory', [74, 78, 81, 86], 0.8), ('loss', [69, 66, 62], 0.7)
    ]:
        effect(name, pitches, duration)
    print('Composed two seamless music loops and nine original sound effects.')
