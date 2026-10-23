# Development handoff

Verify branch, tree and GitHub checks before resuming. This file is the short active handoff; [older checkpoint history](history/development-through-v0.15.md) is reference only.

## Verified release

- **v0.16.1**, released source `fd0c1ee431df91c5101327f5a03ba418c4c93626`, [merged PR #36](https://github.com/oaklanavery-hub/vcommander/pull/36).
- Live: https://oaklanavery-hub.github.io/vcommander/
- [CI 39854783801](https://github.com/oaklanavery-hub/vcommander/actions/runs/39854783801): 42 source suites, 42 pack suites, four JS clock cases, two WebGL2 sessions with both actual browser font chains checked, production container and 150 native views passed.
- [Deploy 39855363694](https://github.com/oaklanavery-hub/vcommander/actions/runs/39855363694): merged-source release gate, Web export, publication and actual served-build verification passed. Resources, PCK checksum and every downloaded-pack suite matched. An independent public manifest fetch reports 0.16.1 at the released source above.
- Fixed: browser boxes in Next/Battle/recruit arrows. Six original bundled pixel symbols fill display/body font gaps; existing letters/metrics and other configured fallbacks are preserved. The tiny native FontFile resource loads before asset import without installed fonts or a new runtime dependency.
- Retained: shared draft/battle layout, Commander portraits/hearts/round/time, mirrored recruited/cap rosters, centered draft, live HP bar, five-power stacks, pre-battle skills, 1× start, reports, inspection, guidance, mastery and private developer access.

## Active scope — P0/P1 player experience

- Approved 2026-10-23: resumable local PvAI, effective power previews, adaptive AI styles/difficulty, an optional one-redraw experiment, local pacing evidence, factual battle recaps, larger text/effects controls and discoverable guidance.
- Branch `feat/player-experience`, base `6eaffa7366049821a3e8ffad9eb00441d3d560ad`. Checkpoint 1 complete: bounded atomic snapshots, same-match recovery, remaining pick clock, watched-result boundary and persisted exact-once settlement receipts.
- Redraw stays opt-in; overtime rules remain unchanged pending pacing evidence. No P2/P3 expansion, balance audit, training grounds, save transfer, campaign, PvP reopening or paid services.
- Focused checks passed: project import, `test_match_recovery`, draft system, Commander progress, mastery lifecycle, scene flow and first-match guidance. Recovery checks cover >53-bit seeds/RNG continuation, identical event/frame output, no extra hearts/XP, a final-settlement write interruption, backup and invalid content/caps. Full source/pack/browser/container/native gate remains pending until the remaining checkpoints are ready.
- Next: actual-benefit power previews and adaptive public-information-only opponent drafting. Then optional redraw, pacing records/recaps and accessibility/native review. Main/base match; the closure-only main commit intentionally skipped CI.

## Previous completed checkpoint

- Implementation branch `fix/ui-symbol-font`, base `713bb9c5efa1ad6d474b2ee7f65d16347759187f`; reviewed source tree `30cb7092397af123dc2eac9673a68c65a8ff0d29` exactly matches the released code commit.
- Font regression shapes actual navigation/recruit/heart/achievement strings at four sizes with OS fallback disabled and checks bundled glyph IDs on real buttons/cards. Browser QA independently checks both actual WebAssembly font chains. Gallery/army/draft arrows were reviewed; font generation is byte-for-byte reproducible.
- Closure branch `docs/release-v0.16.1`, based on the released source, records this verified handoff only. No implementation, export or deployment check remains. Next: human playtesting or the next explicitly scoped request.
- No gameplay, layout, progression or hosting changes. PvP stays Coming Soon; campaign stays KIV; hosting stays free.

## Working conventions

- Read AGENTS.md and relevant project rules, then use current source/checks instead of historical pending notes.
- Use Godot 4.7 stable. Run focused `godot --headless --path . --script tests/test_NAME.gd` checks while editing; Actions owns the complete release gate.
- Browser setup: `python3 tools/setup_browser_qa.py`; CI also enforces an outer 190-second process-group limit. Cache hits still verify the exact package and install required system libraries.
- Native previews: default eight selected views / 1.5 MB image payload. `--views NAME ...` selects task-relevant views; `--all` restores the broader set. All native PNGs remain in the artifact.
- Do not read, print or move the developer's private key. Tests use in-memory/isolated profiles and synthetic credentials.
