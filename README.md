# VCommander

A browser-first VTuber commander drafting auto-battler built with Godot.

## Current status

**Phase 0 — Project Foundation**

The first playable design target is deliberately small:

- 3 starter elements: Fire, Water, Earth
- 1 starter Commander per element
- 4 signature Army cards per Commander
- A full 4-card signature set activates that Commander's set bonus
- Player vs AI first; online multiplayer is not part of the initial prototype

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

Open `project.godot` using Godot 4.7 stable and run the project. Phase 0 displays a foundation/status screen and validates that the starter data can be loaded.
