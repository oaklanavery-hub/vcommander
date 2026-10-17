# Changelog

## Unreleased

### Added
- v0.4 deterministic fixed-timestep `CombatSimulator`.
- Battle events and periodic replay frames separated from presentation.
- Left-vs-right automatic formations with tank, melee and backline placement.
- Target locking, tank targeting priority, ranged kiting, collision-aware movement and retargeting.
- Normal attack, projectile, DEF, healing, DoT, aura, push/pull and empowered-hit simulation.
- Fire, Water and Earth Commander active-skill resolution immediately before combat.
- Starter unit ability execution driven by generic JSON ability `type` values.
- Battle 1 placeholder replay screen with speed controls, event feed, HP bars and skip-to-result.
- Deterministic training opponent for the v0.4 combat harness.
- Combat simulator regression/determinism tests.
- Simulation/battlefield playtest parameters in `game_balance.json`.

### Changed
- `ContentDatabase` now loads the global balance definition.
- Commander active-skill data now declares a generic `type` consumed by combat systems.
- The opening Draft screen now leads into the v0.4 Battle 1 preview after all selections are spent.
- CI now runs headless Combat Simulator tests.

### Previous
- v0.3 seeded Draft System, starter roster and finalized rules.
- v0.2 four-slot Army Builder and shared `GameState`.
- v0.1 data-driven Commander selection.
- v0.0 project foundation, validation, CI and GitHub Pages deployment.
