# VCommander

A browser-first VTuber commander drafting auto-battler built with Godot.

## Current status

**v0.7 — Elemental PvAI Vertical Slice**

The current playable prototype supports:

- Fire, Water and Earth starter Commanders
- 12 approved starter Army cards with initial playtest stats/abilities
- exactly 4 unique pre-match Army cards, freely mixed across elements
- Commander themed-set bonuses when all four selected cards match the theme
- seeded 3-choice pre-battle drafting
- Army-card summon amounts and maximum unit counts
- opening Battle 1 draft restricted to Army cards
- 5 persistent Army-wide Buff Cards with multiplicative stacking and 3-stack caps
- Commander skill selection cost and twice-per-match / once-per-round limits
- 30-second pick timer and random auto-selection on timeout
- deterministic left-vs-right auto-combat after the opening draft
- automatic Tank → Melee → Backline formation, target locking, movement/collision and ranged spacing
- Commander skills and the starter roster's data-driven unit abilities
- twelve distinct original pixel units, full-field battle playback and HP bars
- eight-direction movement poses, four-direction attacks, neutral idle/death and combat VFX
- optional sound, reduced motion, HP numbers, pause and keyboard shortcuts
- seeded match input, Commander-theme quick equip and visible opponent progress
- 120-second draw resolution

The opponent now selects its own Commander and unique four-card loadout, drafts legally using a seeded policy, and conceals current picks until combat. The battlefield uses original elemental pixel artwork, a meadow arena, projectile/skill effects and readable side markers. Matches now continue until one side reaches four losses. Draws cost both sides a loss; simultaneous fourth losses trigger repeated Sudden Death rounds. Losing sides receive a fourth selection in normal rounds. Armies, Buffs and skill budgets persist while battle units respawn at full HP.

## Technology

- Godot 4.7 stable
- GDScript
- Compatibility renderer for browser support
- JSON-driven gameplay content
- deterministic fixed-timestep combat simulation
- GitHub Actions for validation and web deployment
- GitHub Pages for the browser build

## Source of truth

Read these before changing gameplay:

1. `AGENTS.md`
2. `docs/GAME_RULES.md`
3. `docs/ARCHITECTURE.md`
4. `docs/DATA_SCHEMA.md`
5. `docs/DECISIONS.md`

## Development workflow

`main` remains playable. Work happens on short-lived branches, passes validation/tests, then enters `main` through a pull request.

## Local start

Open `project.godot` using Godot 4.7 stable and run the project. Choose a Commander, equip four unique Army cards, choose **Begin Match Draft**, spend all three opening selections, then choose **Start Battle 1**. Continue through the result screen until the match ends.

## Controls

| Screen | Input | Action |
| --- | --- | --- |
| Draft | 1 / 2 / 3 | Choose the corresponding offered card |
| Draft | S | Prepare Commander skill |
| Draft | Enter | Start battle after selections are spent |
| Battle | Space | Pause/resume playback |
| Battle | 1 / 2 / 4 | Set battle speed |
| Battle | M | Toggle sound |
| Result | Enter | Continue to the next round |

Use **Equip Commander theme** for a quick themed army. Leave the optional seed empty for a new match, or reuse a seed with the same setup and picks to reproduce a match. Sound starts off; motion and HP-number controls are available during battle. Current rival draft choices are concealed until combat.

## Verification and playtesting

Run `python3 tools/run_checks.py --godot /path/to/godot` for all content/art validation and headless suites. Run `godot --headless --path . --script tools/run_balance.gd -- --seeds=8 --seed-start=1000 --output=/tmp/balance.json` for a reproducible AI sample. See `docs/PLAYTEST_REPORT.md` for methods, tuning and limitations.

CI also renders six desktop screenshots and tests the exported game pack. A deployed build can be verified with `python3 tools/verify_deployment.py --expected-commit <full-main-sha> --godot /path/to/godot`.
