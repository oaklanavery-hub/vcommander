# VCommander

A browser-first VTuber commander drafting auto-battler built with Godot.

## Current status

**v0.2 — Army Builder**

The current prototype supports:

- 3 starter elements: Fire, Water, Earth
- 1 starter Commander per element
- 4 signature Army cards per Commander
- Commander selection loaded from JSON
- A four-slot Army Builder using the full starter card pool
- Live signature-set progress from `0/4` to `4/4`
- A generic Commander Bonus ACTIVE state when the full signature set is equipped
- Player vs AI remains the first match target; drafting and combat are not implemented yet

Gameplay values and names in `data/` are placeholders unless explicitly approved in `docs/GAME_RULES.md`.

## Technology

- Godot 4.7 stable
- GDScript
- Compatibility renderer for browser support
- JSON-driven gameplay content
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

`main` should remain playable. Work happens on short-lived branches, passes validation, then enters `main` through a pull request.

## Local start

Open `project.godot` using Godot 4.7 stable and run the project. Choose a Commander, open the Army Builder, equip four cards, and observe signature-set progress and bonus activation.
