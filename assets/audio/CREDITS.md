# VCommander audio

Original procedural compositions and sound effects created for VCommander.

- **Campfire Companions** — warm harp-like melody, arpeggios, soft sustained chords and bass, 96 BPM.
- **At the Crossing** — the adventure theme arranged with a quicker pulse and gentle percussion, 112 BPM.
- Nine effects for hovering, selecting, drafting, attacking, defeat, healing, magic and match results.
- Seventeen additional battle cues: arrow release/impact, fire casting, dragon breath, water casting, ice casting, seeds, wood/claw/heavy/magic hits, vine extension/retraction, meteors, freezing, plant growth, explosions and healing water.

The score and synthesizer source are in `tools/compose_audio.py`. No third-party recordings or sampled instruments are used. Audio is replaceable presentation content and does not determine combat timing or results.
The additional battle synthesizer is `tools/compose_battle_sfx.py`: deterministic filtered noise, pitch sweeps, plucked/resonant tones, envelopes and silent tails, exported as 16 kHz mono PCM WAV. `tools/validate_presentation.py` checks distinct files, format, coverage, clipping and click-free endpoints. Unit sound/visual assignments live in `data/presentation/combat_cues.json`.
