# Development handoff

Verify branch, tree and GitHub checks before resuming. This file is the short active handoff; [older checkpoint history](history/development-through-v0.15.md) is reference only.

## Verified release

- v0.15.0, main `05e7f37ebee6022b251c25b8f1428ab31c53826f`, merged PR #33.
- Live: https://oaklanavery-hub.github.io/vcommander/
- CI [39831261015](https://github.com/oaklanavery-hub/vcommander/actions/runs/39831261015): 40 source suites, 40 pack suites, four JS clock cases, two WebGL2 sessions, production container and 144 native views passed.
- Deploy [39836962112](https://github.com/oaklanavery-hub/vcommander/actions/runs/39836962112): published source identity, resource/checksum checks and every actual served-pack suite passed.
- Completed: reports for both armies, current unit inspection, optional real-match guide, attack/death/audio polish. Commander mastery and private developer collection access are preserved.

## Current task: faster development delivery

- Branch `chore/faster-delivery`, based on the verified main above.
- User asks to reduce time spent delivering development results. This is tooling/workflow work; game rules and assets are outside this change.
- Implementing: verified Playwright/Chromium caching, bounded setup/network waits, a smaller default native preview stream, concise handoffs and one-feature/focused-check/release discipline.
- Six network-free setup checks pass: warm/cold cache, invalid cached module repair, registry timeout, browser failure and missing executable. Python compile, preview selection/default/all/byte-budget/path checks, workflow YAML/retained gate checks and diff checks pass.
- Active handoff is 89% smaller (24,946 to roughly 2,700 bytes); default preview selection drops from 36 to eight. Full artifacts and release gates remain intact. Save/push this checkpoint, require one complete Actions gate, then merge when passing. Actual cold/warm CI timings remain unmeasured.
- No new gameplay, balance audit, progress export/import, training grounds, campaign, PvP availability or paid hosting changes. PvP stays Coming Soon; campaign stays KIV.

## Working conventions

- Read AGENTS.md and relevant project rules, then use current source/checks instead of historical pending notes.
- Use Godot 4.7 stable. Run focused `godot --headless --path . --script tests/test_NAME.gd` checks while editing; Actions owns the complete release gate.
- Browser setup: `python3 tools/setup_browser_qa.py`; CI also enforces an outer 190-second process-group limit. Cache hits still verify the exact package and install required system libraries.
- Native previews: default eight selected views / 1.5 MB image payload. `--views NAME ...` selects task-relevant views; `--all` restores the broader set. All native PNGs remain in the artifact.
- Do not read, print or move the developer's private key. Tests use in-memory/isolated profiles and synthetic credentials.
