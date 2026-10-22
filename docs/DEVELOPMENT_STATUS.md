# Development handoff

Verify branch, tree and GitHub checks before resuming. This file is the short active handoff; [older checkpoint history](history/development-through-v0.15.md) is reference only.

## Verified release

- v0.15.0, main `05e7f37ebee6022b251c25b8f1428ab31c53826f`, merged PR #33.
- Live: https://oaklanavery-hub.github.io/vcommander/
- CI [39831261015](https://github.com/oaklanavery-hub/vcommander/actions/runs/39831261015): 40 source suites, 40 pack suites, four JS clock cases, two WebGL2 sessions, production container and 144 native views passed.
- Deploy [39836962112](https://github.com/oaklanavery-hub/vcommander/actions/runs/39836962112): published source identity, resource/checksum checks and every actual served-pack suite passed.
- Completed: reports for both armies, current unit inspection, optional real-match guide, attack/death/audio polish. Commander mastery and private developer collection access are preserved.

## Current task: battlefield layout

- Branch `feat/battlefield-layout`, base main `4e67ddb5bcb2f340b6560d453ae708506fe9497c` (merged delivery improvements, PR #34).
- User approved their two-phase wireframe: persistent mirrored rosters, Commander/life strip, centered round/time, army-health balance bar, and a central draft panel over the arena.
- Implemented shared MatchStatus/WarbandRoster presentation, reserved rails outside playable ground, centered readable draft choices, current-replay health totals and recruit highlights. Hidden rival picks, pre-battle skills, 1× start, inspection, reports and progression are preserved.
- Passing focused checks: two-phase layout/state/privacy/HP/stack coverage; existing scene flow, battle presentation, inspection, mastery and Slime presentation suites; Godot import, data/presentation validators, six delivery-tool tests, workflow YAML and diff checks. Six native Compatibility-renderer views were reviewed; all five power stacks fit the standard desktop draft.
- Next: save/publish this coherent checkpoint, require one complete Actions source/exported-pack/browser/container/native gate, then merge and verify the actual deployment. No gameplay/balance changes. PvP stays Coming Soon; campaign stays KIV; hosting stays free.

## Working conventions

- Read AGENTS.md and relevant project rules, then use current source/checks instead of historical pending notes.
- Use Godot 4.7 stable. Run focused `godot --headless --path . --script tests/test_NAME.gd` checks while editing; Actions owns the complete release gate.
- Browser setup: `python3 tools/setup_browser_qa.py`; CI also enforces an outer 190-second process-group limit. Cache hits still verify the exact package and install required system libraries.
- Native previews: default eight selected views / 1.5 MB image payload. `--views NAME ...` selects task-relevant views; `--all` restores the broader set. All native PNGs remain in the artifact.
- Do not read, print or move the developer's private key. Tests use in-memory/isolated profiles and synthetic credentials.
