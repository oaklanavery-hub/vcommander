# Focused strategy and pacing playtest — v0.18

## Scope and reproduction

This is a bounded **synthetic AI-vs-AI diagnostic**, not human playtesting, telemetry, a representative win rate or a complete balance audit. No player persistence or developer credentials were read. The user approved focused pacing and themed-versus-hybrid evaluation; overtime and theme bonuses were not changed.

Run `godot --headless --path . --script tools/run_strategy_playtest.gd` with the pinned Godot 4.7 runtime. The tool writes ignored `build/qa/strategy_sample.json`. It runs eight fixed starter-only adventures, one themed/mixed pair per Commander, using the same rival setup seed within each pair. Both policies use Standard decision rules and the legal draft/skill/heart/comeback/Sudden Death loop. Redraw and commander paths are off. Each fixture stops after 16 rounds; stopping the diagnostic is not a new game rule or an awarded result.

The fixed player loadouts and left-side orientation, one seed per pair, heuristic policies and small sample limit any balance conclusion. Each paired rival can make different later counter-picks because the previous public army differs. A win here describes the fixture policy and matchup, not player skill or a Commander tier.

## Recorded results

| Commander | Build | Seed | Rounds | Combat at 1× | Time-limit draws | Sudden Death draws | Result |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Earth | themed | 181000 | 5 | 240.4s | 0 | 0 | win |
| Earth | mixed | 181000 | 6 | 283.0s | 1 | 0 | win |
| Fire | themed | 188919 | 6 | 69.3s | 0 | 0 | win |
| Fire | mixed | 188919 | 7 | 93.5s | 0 | 0 | win |
| Slime | themed | 196838 | 6 | 135.4s | 0 | 0 | win |
| Slime | mixed | 196838 | 5 | 79.0s | 0 | 0 | win |
| Water | themed | 204757 | 7 | 291.1s | 0 | 0 | win |
| Water | mixed | 204757 | 16 | 1372.8s | 10 | 9 | unfinished_at_bound |

These durations are simulated combat only. They exclude commander openings, actual playback speed, draft decisions, paused reading and menus. They are not predictions of human session length.

## Findings and retained decisions

- Seven fixtures completed. The Water hybrid at seed `204757` did not complete within the diagnostic bound: rounds 7–16 all reached 120 seconds, including nine Sudden Death draws. Its 1,372.8 seconds of simulated combat establishes a repeatable pacing concern, not proof that the match can never finish or an estimate of how often humans encounter it.
- Three hybrid fixtures completed wins, and the fourth kept drawing. This does not justify a partial-theme bonus, a blanket hybrid buff or unit nerfs. The builder now explains the existing four-matching-card tradeoff.
- None of these eight draft policies filled all four unit caps. This sample therefore cannot establish the quality of buff-only late-game decisions. The separate specialization regression explicitly fills every cap and verifies a legal one-pick path purchase from the resulting buff-only offer.
- Preserve current overtime until a product decision chooses how repeated Sudden Death draws should resolve. Candidate designs are escalating combat overtime or a finite tie resolution; they have different effects on healing, defense and match fairness. Unlimited power cards alone do not prevent the observed sequence of draws.
- Paths remain a default-off prototype. Their current values are not declared balanced or proven to improve retention. Neither automated fixtures nor local self-selected comparisons establish a causal benefit.

## Exact hybrid fixtures

- `commander_earth_01`: `card_earth_01`, `card_earth_04`, `card_slime_02`, `card_fire_02`.
- `commander_fire_01`: `card_fire_01`, `card_fire_03`, `card_water_03`, `card_water_05`.
- `commander_slime_01`: `card_slime_01`, `card_slime_03`, `card_fire_05`, `card_earth_05`.
- `commander_water_01`: `card_water_01`, `card_water_02`, `card_fire_05`, `card_earth_03`.

## Human acceptance to collect next

Use ordinary profiles and Settings → Adventure insights; do not reset ownership or records to conduct a test. Begin with paths and redraw off, then use matched difficulty/collection and a comparable build for an opted-in path adventure. Keep each experiment identified separately. The latest 30 adventures retain aggregate battle/draft/viewing time, time-limit draws, repeated Sudden Death, build composition and full-recruitment rounds.

Record whether a new player can explain the lost theme bonus in a mixed build, name a useful interaction without external help, find the glossary, understand both path effects and the one-pick cost, and cancel reading without spending a pick or losing time. Check that a restarted chosen path, hidden rival choice and following offer stay consistent. Complete ordinary match/XP settlement and compact/larger-text reading.

Review actual match lengths and repeated-draw cases before selecting an overtime rule. A small convenience sample is directional evidence only. No human observations were available during this implementation, and none are fabricated here.


## Approved Sudden Death comparison — v0.19

The user subsequently approved a 180-second ceiling **per Sudden Death battle**, doubling only power cards newly picked in Sudden Death. Earlier bonuses remain unchanged. Normal rounds remain 120 seconds, with no new healing penalty, damage ramp or tiebreaker. This supersedes the earlier decision to defer overtime; other findings above remain historical v0.18 observations.

Reproduce with `godot --headless --path . --script tools/compare_sudden_death.gd`. It runs only the known Water mixed fixture at seed `204757`, starter collection, Standard policies, paths/redraw off and a 16-round diagnostic bound. The two runs share setup/seed/loadout and use the current shared AI/stat code. The control sets Sudden Death to 120 seconds and new-power multiplier 1; the approved run uses 180 and 2. Ignored output is `build/qa/sudden_death_comparison.json`.

| Rule | Rounds observed | Time-limit draws | Sudden Death draws | Combat at 1× | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| Control: 120 seconds, ordinary powers | 16 | 10 | 9 | 1,372.8s | Unfinished at diagnostic bound |
| Approved: 180 seconds, new powers ×2 | 15 | 8 | 7 | 1,584.3s | Earth defeats Water in Round 15 |

The control exactly reproduced the recorded v0.18 case. Both runs had identical first seven rounds; Round 7 was the normal 120-second draw that triggered Sudden Death. The approved run then drew Rounds 8–14 at 180 seconds each and ended Round 15 by elimination at 31.5 seconds. This single paired fixture demonstrates a changed outcome and an eventual finish in this case, with fewer observed drawn rounds but more total simulated combat than the bounded control. It does **not** prove that all stalemates finish or that human matches are shorter or balanced. Repeated three-minute draws remain possible under the approved rules. No human results were available or invented.
