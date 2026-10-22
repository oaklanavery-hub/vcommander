# Development handoff

Verify branch, tree and GitHub checks before resuming. This file is the short active handoff; [older checkpoint history](history/development-through-v0.15.md) is reference only.

## Verified release

- **v0.16.0**, released source `7dfad84e4006a8555f0577541cc4f741716ff217`, [merged PR #35](https://github.com/oaklanavery-hub/vcommander/pull/35).
- Live: https://oaklanavery-hub.github.io/vcommander/
- [CI 39849987217](https://github.com/oaklanavery-hub/vcommander/actions/runs/39849987217): 41 source suites, 41 pack suites, four JS clock cases, two WebGL2 sessions, production container and 150 native views passed. Six dedicated layout views were reviewed locally and in CI.
- [Deploy 39850683713](https://github.com/oaklanavery-hub/vcommander/actions/runs/39850683713): merged-source release gate, Web export, publication and actual served-build verification passed. Manifest version/commit, resources, PCK checksum and every downloaded-pack suite matched. Independently fetched public manifest also reports 0.16.0 at the released source above.
- Completed: shared draft/battle layout, Commander portraits/hearts and centered round/time, mirrored recruited/cap rosters outside playable ground, centered draft window, live current-HP bar, recruit highlights and readable five-power stacks. Hidden picks, pre-battle skills, 1× start, inspection, reports, guidance, mastery and private developer access are preserved.

## Current task: missing UI symbols

- Branch `fix/ui-symbol-font`, base main `713bb9c5efa1ad6d474b2ee7f65d16347759187f`.
- User screenshots show missing-character boxes in Next/Battle buttons and recruit-count arrows. Confirmed Pixelify Sans lacks U+2190/U+2192 and the bundled body font also lacks the arrows; native system fallback had masked the browser failure.
- Implement a bundled original pixel-symbol fallback, retain existing lettering, and cover all six symbol characters currently absent from the display font. No gameplay, layout, hosting or progression changes.
- Acceptance: portable glyph shaping with system fallback disabled, actual reported button/count strings and other UI symbols; native gallery/army/draft review; focused UI checks, then full source/pack/browser/container/native release checks and actual served-build verification.
- Implemented a 2,692-byte original embedded symbol face, shared display/body fallbacks and deterministic generator. The new shaping regression verifies actual navigation/recruit/heart/achievement strings at four sizes with system fallback disabled; browser QA also checks both actual WebAssembly font chains.
- Passing: font coverage, fantasy interface, scene flow and match layout suites; import, data/presentation validators, deterministic regeneration, Python/JS syntax, six delivery-tool cases and diff checks. Native gallery/army/draft screenshots show the actual arrows correctly; thirteen UI views were captured.
- Next: publish this coherent checkpoint, run the full source/pack/browser/container/native gate (including the new WebAssembly glyph assertion), merge when green and verify the served build. PvP stays Coming Soon; campaign stays KIV; hosting stays free.

## Working conventions

- Read AGENTS.md and relevant project rules, then use current source/checks instead of historical pending notes.
- Use Godot 4.7 stable. Run focused `godot --headless --path . --script tests/test_NAME.gd` checks while editing; Actions owns the complete release gate.
- Browser setup: `python3 tools/setup_browser_qa.py`; CI also enforces an outer 190-second process-group limit. Cache hits still verify the exact package and install required system libraries.
- Native previews: default eight selected views / 1.5 MB image payload. `--views NAME ...` selects task-relevant views; `--all` restores the broader set. All native PNGs remain in the artifact.
- Do not read, print or move the developer's private key. Tests use in-memory/isolated profiles and synthetic credentials.
