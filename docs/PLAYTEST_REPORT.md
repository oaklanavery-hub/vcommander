# v0.7 Automated Playtest Report

## Method

Godot 4.7 stable, seeded full-theme AI-versus-AI matches, all nine ordered Commander pairings. The final validation used 12 seeds per pairing (2000–2011), independent of the preliminary 1000–1007 tuning sample. Each side received only previous-round public enemy information. The benchmark caps a match at 20 rounds to record an unresolved Sudden Death case; the playable game continues Sudden Death according to the rules.

The final validation completed **108 matches and 652 battles**. No match reached the benchmark cutoff. Draw and repeated Sudden Death rules are also exercised by dedicated regression tests.

## Final validation results

Wins refer to the side named in each column. The two sides use different deterministic draft seeds.

| Left Commander | Right Commander | Left wins | Right wins | Unresolved | Drawn battles | Total battles | Mean battle seconds |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Earth | Earth | 5 | 7 | 0 | 4 | 73 | 44.85 |
| Earth | Fire | 6 | 6 | 0 | 2 | 76 | 28.51 |
| Earth | Water | 7 | 5 | 0 | 9 | 71 | 48.04 |
| Fire | Earth | 3 | 9 | 0 | 0 | 68 | 29.51 |
| Fire | Fire | 10 | 2 | 0 | 0 | 79 | 16.83 |
| Fire | Water | 2 | 10 | 0 | 3 | 71 | 35.51 |
| Water | Earth | 4 | 8 | 0 | 12 | 67 | 54.84 |
| Water | Fire | 9 | 3 | 0 | 2 | 72 | 27.17 |
| Water | Water | 3 | 9 | 0 | 3 | 75 | 46.09 |

## Applied tuning

| Definition | Previous | v0.7 baseline |
| --- | ---: | ---: |
| Ice Giant ATK | 75 | 90 |
| Sea Serpent ATK | 95 | 105 |
| Giant Tree healing aura, ally Max HP per tick | 3% | 2% |

The AI now gives the first healing unit additional value once four allies are deployed. Unit roles, summon caps, skill rules and damage formulas are preserved. The preliminary 72-match sample exposed Water weakness and poor healer valuation; the final sample above uses the finished policy and tuning.

## Limits and next balance questions

These samples use full-theme armies and one basic AI policy. They establish a reproducible baseline; human drafting and mixed armies need broader playtesting. Water won 19 of 24 cross-element matches against Fire, and Earth won 15 of 24 against each other element. Track those matchups in the next playtest rather than treating the current values as final. Mirror results vary with the offered cards and seeds.

## Performance reference

Native simulation on this shared Linux environment measured a median **111.85 ms** and p95 **382.71 ms** per battle; the sample reached **36 units**. Separate stress tests exercise all unit caps, all five Buffs at three stacks and both Commander skills, including 46 units in an Earth mirror. Native timings are separate from browser frame-rate measurements.

## Visual and interaction QA

Six rendered desktop captures cover Commander selection, army building, drafting, the initial battlefield, combat effects and the round result. Headless scene-flow tests verify the 1280×720 layout, all five rival Buff stacks, next-round navigation and presentation controls. The optional sound player is stopped and released on scene exit.

The connected verification browser reports WebGL2 unavailable. The Web loader and downloaded PCK are therefore validated through resource/commit checks and Godot tests, with visual QA performed using the Compatibility renderer under software OpenGL. This does not replace a hardware browser playtest.

## Reproduce

```bash
python3 tools/run_checks.py --godot /path/to/godot
godot --headless --path . --script tools/run_balance.gd -- --seeds=12 --seed-start=2000 --output=/tmp/vcommander-balance.json
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility --script tools/capture_ui.gd -- --output-dir=build/qa
```
