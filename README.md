# VCommander

A browser-first VTuber commander drafting auto-battler built with Godot.

## Current status

**v0.4 — Deterministic Auto-Combat**

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
- battle event log and placeholder full-field replay with HP bars
- 120-second draw resolution

v0.4 uses a clearly labeled **training opponent** that mirrors your four-card loadout and auto-drafts three legal opening Army selections from a separate deterministic seed. Strategic PvAI drafting is the v0.5 milestone; the full multi-round/four-loss match loop is v0.6.

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

Open `project.godot` using Godot 4.7 stable and run the project. Choose a Commander, equip four unique Army cards, choose **Begin Match Draft**, spend all three opening selections, then choose **Start Battle 1 Preview**.
