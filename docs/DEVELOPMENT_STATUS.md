# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Player experience and presentation

- User request (18 October 2026, Malaysia): the game works, but needs a friendly interface, stronger visuals, a game menu, sound effects and BGM.
- Branch: `feat/player-experience`, based on main `5753de373916383b72fef0d88df2d0f1c16a86d5`.
- Scope: title menu, How to Play, shared pause/settings/leave confirmation, cozy original scenery, clearer setup/draft/result hierarchy, original looping music and sound effects, persistent presentation settings.
- Acceptance: full menu → Commander → army → draft → battle → result flow; help/settings and confirmed exit; preference persistence; audio included in exports; readable 1280×720 screens; passing regression suites and deployment checks.
- Implemented: title/help/settings/pause, safe exit, starter-warband flow, warm forest scenery, card hierarchy, two music loops and nine effects.
- Local validation: all 13 suites passed with `python3 tools/run_checks.py --godot /workspace/scratch/5d3e19c21d4d/vcommander-tools/Godot_v4.7-stable_linux.x86_64`; final visual captures, fresh-import CI and deployed-pack checks remain pending.
- Native visual review: ten 1280×720 Compatibility-renderer captures inspected (title, help, settings, Commander, warband, draft, pause, battle, effects and result). Fixed a collapsed collection, focused-button contrast and undersized portraits. Added a collection visibility/filter regression check.
- After those fixes, `tests/test_player_experience.gd` and `tests/test_scene_flow.gd` both passed. Audio files were verified as 40.0s / 34.29s original loops plus nine effects.
- PR: https://github.com/oaklanavery-hub/vcommander/pull/12 — current checks and final run links are recorded there. The initial head passed CI at https://github.com/oaklanavery-hub/vcommander/actions/runs/39053920966. Final-head CI and post-merge deployment verification must pass before release.
- No hardware/browser audio audition is claimed; the cloud verification browser lacks WebGL2. Native renders and source/export/deployed-pack tests provide the automated evidence.
- If interrupted: inspect this branch's diff/PR, complete the current-head CI/visual acceptance checks, then merge. If already merged, verify its Deploy Web run. Do not restart completed gameplay work. Final evidence is in the PR and Actions run for its merge commit.

## Product scope

v0.7 core PvAI is playable. The user prioritizes usability and polish before campaign, online PvP or mascot expansion. Those expansions still need direction. Art and balance remain provisional.
