# Development handoff

Read this with `AGENTS.md` and verify it against the actual Git branch and GitHub Actions before working. Keep this file short and replace stale task details at each checkpoint.

## Product baseline

- Last gameplay baseline: v0.7, main commit `35d636b8039c45670d2cf9aaab7b890fefe72a3c`.
- The user confirmed that the game works on 18 October 2026 (Malaysia time).
- The approved v0.0–v0.7 roadmap is implemented. Art and balance remain provisional; see `docs/PLAYTEST_REPORT.md`.
- The next major product phase needs a direction: campaign/progression, online PvP, or VTuber/mascot integration. Do not choose an expansion on the user's behalf.

## Current checkpoint: reduce development timeout exposure

- Branch: `fix/development-checkpoints`, based on the gameplay baseline above.
- Goal: preserve progress across interrupted AI runs and remove duplicate CI work.
- Changes: small resumable batches in `AGENTS.md`; this handoff; one validation path on main through Deploy Web; cancellation of superseded validation runs; bounded CI/build/deploy job durations and Godot export/import commands.
- Evidence for the diagnosis: [the last baseline deployment](https://github.com/oaklanavery-hub/vcommander/actions/runs/38999705615) took about two minutes from validation start through served-build verification. A separate CI workflow also ran the same source validation on main. The exact cause of the user's ChatGPT timeout is unconfirmed.
- Local validation passed: `git diff --check`; Python/PyYAML parsing of both workflows, trigger ownership, dependency gates, distinct concurrency groups, timeout bounds and handoff links.
- Remote validation: inspect the checkpoint PR's CI and the merged commit's Deploy Web run in [GitHub Actions](https://github.com/oaklanavery-hub/vcommander/actions). A pending run is not a passing check. Source, visual QA, exported-pack and served-pack checks remain required.
- Next action if interrupted: find the open PR for this branch and inspect its exact head checks. Complete validation and merge only after it passes. If already merged, inspect that commit's deployment and address any failure before starting other work.
- After this checkpoint ships: gather the user's remaining concerns or the next product direction. Human playtesting should guide further balance changes.

## Handoff fields for the next task

Record the goal and acceptance checks, branch/base commit, completed changes, exact validation results and run links, remaining work, and the next executable step. Preserve unfinished work on its branch and label unrun or failed checks honestly.
