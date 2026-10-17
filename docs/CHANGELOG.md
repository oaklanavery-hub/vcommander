# Changelog

## v0.7.1 — Player experience

- Forest-camp title menu, original pixel scenery and a warmer forest/brass interface.
- Player guide, shared pause/settings menus, confirmed match exit and active-time draft clocks.
- Prefilled starter warbands, companion collection filtering, readable card hierarchy and advanced seed controls.
- Two original music loops, nine original sound effects, first-interaction audio activation and saved device preferences.
- Clearer battle/result language, heart feedback and a focused battle control bar.
- Navigation, modal layout, pause/exit safety, preference persistence and exported audio regression checks; ten CI screenshots.

## Development workflow — Resumable checkpoints

- Added a repository handoff and small-checkpoint instructions so interrupted AI work can resume from saved branches and check results.
- Removed duplicate standalone validation on main; Deploy Web still requires the reusable CI gate.
- Cancel superseded validation runs and bound validation, build and deployment durations to avoid indefinitely stalled jobs.

## v0.7 — Pixel presentation, accessibility and playtest baseline

- Original replaceable pixel catalog for all twelve starter units and Commander plants, shared by cards and the battlefield.
- Eight-direction movement poses, four-direction attacks, neutral idle/death, interpolation, aura/area/projectile/skill effects and burn/HP feedback.
- Optional synthesized battle tones, pause, speed shortcuts, reduced motion and HP-number controls.
- Quick themed loadouts, optional match seed and compact complete rival summaries.
- Fixed projectile interception with swept enemy collision, allied pass-through and locked-target fizzle/commitment.
- Improved generic AI valuation of first healing support; adjusted Ice Giant/Sea Serpent ATK and Giant Tree healing for the provisional baseline.
- Automated validation over 108 final-sample matches/652 battles, max-cap roster stress and visual captures.
- Deployment depends on validation, tests the actual exported PCK, excludes generated output and publishes source identity.
- Post-deployment CI verifies the served commit and game-pack SHA-256, then runs all suites from the downloaded Pages payload.
- Reusable local/deployed validation tools and an evidence-based playtest report.


## v0.6 — Complete elemental PvAI matches

- Multi-round match state, four-loss condition, comeback selections and repeated Sudden Death.
- Persistent drafted armies, Buff stacks and skill budgets with fresh battle state each round.
- Seeded replayable full matches for all three themes and mixed-element armies.
- Round/result navigation, loss counters, prepared-skill status and fantasy UI theme.
- Fixed combat event-log scene path and overflowing selection/result layouts.
- Headless match-rule, full-match and 1280×720 scene-flow regression tests.


## v0.5 — Seeded AI and battlefield art

- Independent legal AI Commander/loadout selection, role-aware draft policy and skill conservation.
- Opponent information snapshots conceal current selections until combat.
- Original element-colored pixel silhouettes, side markers, HP bars and meadow tiles.
- Explicit JSON inclusion in Web exports.
- Regression coverage over 50 seeds and 700 AI draft phases.

## v0.4 — Deterministic combat

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
