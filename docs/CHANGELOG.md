# Changelog

## Unreleased

### Added
- v0.3 seeded three-choice Draft System and opening pre-battle draft screen.
- 30-second selection timer with random card auto-pick.
- Unit summon amounts/caps, persistent unit-count progression and card exhaustion.
- Five stackable Army-wide Buff Card definitions with three-stack caps.
- Commander active-skill selection cost and use-limit state.
- Finalized starter Fire/Water/Earth roster names, initial stats and ability data.
- Data-driven Commander themed-set bonuses.
- Expanded authoritative match, draft, combat, targeting and presentation rules.
- Draft-system automated tests.

### Changed
- Army loadouts now reject duplicate card IDs.
- Commander set activation now checks whether all four equipped cards match the Commander's theme rather than four permanently hardcoded required card IDs.
- Army Builder now shows approved starter stats, uniqueness, themed-set effect and a path into the Draft prototype.

### Previous
- v0.2 four-slot Army Builder and shared `GameState`.
- v0.1 data-driven Commander selection.
- v0.0 project foundation, validation, CI and GitHub Pages deployment.
