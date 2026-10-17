# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Player experience and presentation

- User request (18 October 2026, Malaysia): the game works, but needs a friendly interface, stronger visuals, a game menu, sound effects and BGM.
- Branch: `feat/player-experience`, based on main `5753de373916383b72fef0d88df2d0f1c16a86d5`.
- Scope: title menu, How to Play, shared pause/settings/leave confirmation, cozy original scenery, clearer setup/draft/result hierarchy, original looping music and sound effects, persistent presentation settings.
- Acceptance: full menu → Commander → army → draft → battle → result flow; help/settings and confirmed exit; preference persistence; audio included in exports; readable 1280×720 screens; passing regression suites and deployment checks.
- Implemented: title/help/settings/pause, safe exit, starter-warband flow, warm forest scenery, card hierarchy, two music loops and nine effects.
- Local validation: all 13 suites passed with `python3 tools/run_checks.py --godot /workspace/scratch/5d3e19c21d4d/vcommander-tools/Godot_v4.7-stable_linux.x86_64`; final visual captures, fresh-import CI and deployed-pack checks remain pending.
- Native screenshot setup: local Xvfb dependencies are being prepared; no web-browser visual verification has been claimed.
- If interrupted: inspect this branch's diff/PR, complete acceptance checks, then publish after CI passes. Record exact results here and in the PR.

## Product scope

v0.7 core PvAI is playable. The user prioritizes usability and polish before campaign, online PvP or mascot expansion. Those expansions still need direction. Art and balance remain provisional.
