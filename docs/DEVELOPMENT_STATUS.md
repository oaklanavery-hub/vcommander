# Development handoff

Verify branch, tree and GitHub checks before resuming. This file is the short active handoff; [older checkpoint history](history/development-through-v0.15.md) is reference only.

## Verified release

- **v0.16.0**, released source `7dfad84e4006a8555f0577541cc4f741716ff217`, [merged PR #35](https://github.com/oaklanavery-hub/vcommander/pull/35).
- Live: https://oaklanavery-hub.github.io/vcommander/
- [CI 39849987217](https://github.com/oaklanavery-hub/vcommander/actions/runs/39849987217): 41 source suites, 41 pack suites, four JS clock cases, two WebGL2 sessions, production container and 150 native views passed. Six dedicated layout views were reviewed locally and in CI.
- [Deploy 39850683713](https://github.com/oaklanavery-hub/vcommander/actions/runs/39850683713): merged-source release gate, Web export, publication and actual served-build verification passed. Manifest version/commit, resources, PCK checksum and every downloaded-pack suite matched. Independently fetched public manifest also reports 0.16.0 at the released source above.
- Completed: shared draft/battle layout, Commander portraits/hearts and centered round/time, mirrored recruited/cap rosters outside playable ground, centered draft window, live current-HP bar, recruit highlights and readable five-power stacks. Hidden picks, pre-battle skills, 1× start, inspection, reports, guidance, mastery and private developer access are preserved.

## Completed checkpoint and next action

- Implementation branch `feat/battlefield-layout`, base `4e67ddb5bcb2f340b6560d453ae708506fe9497c`. Reviewed source tree `ad63925899041b0c14d12c9ad7a2cb9b3f28fc44` exactly matches the released code commit.
- Closure branch `docs/release-v0.16`, based on the released source, records this verified handoff only; no runtime changes or new build are needed for the closure.
- All focused and full checks passed. No deployment, export or implementation step remains. Next: human playtesting or the next explicitly scoped request.
- No gameplay/balance changes. PvP stays Coming Soon; campaign stays KIV; hosting stays free.

## Working conventions

- Read AGENTS.md and relevant project rules, then use current source/checks instead of historical pending notes.
- Use Godot 4.7 stable. Run focused `godot --headless --path . --script tests/test_NAME.gd` checks while editing; Actions owns the complete release gate.
- Browser setup: `python3 tools/setup_browser_qa.py`; CI also enforces an outer 190-second process-group limit. Cache hits still verify the exact package and install required system libraries.
- Native previews: default eight selected views / 1.5 MB image payload. `--views NAME ...` selects task-relevant views; `--all` restores the broader set. All native PNGs remain in the artifact.
- Do not read, print or move the developer's private key. Tests use in-memory/isolated profiles and synthetic credentials.
