# Roadmap

## v0.0 — Foundation ✅
- Repository structure, Godot 4.7 browser export, rules/schema/architecture, starter content, validation, CI and Pages.

## v0.1 — Commander and content system ✅
- Commander selection and data-driven content loading.

## v0.2 — Army builder ✅
- Exactly four Army slots, Commander-theme progress and shared game state.

## v0.3 — Draft prototype ✅
- Finalized match/draft/combat rules documented.
- Four unique pre-match Army cards with mixed-element support.
- Seeded three-choice draft offers.
- Opening Army-only draft.
- Summon amounts/unit caps and exhausted-card removal.
- Persistent Buff stack model and offer limits.
- Commander skill selection cost/use limits.
- 30-second per-selection timeout with random auto-pick.
- Interactive opening pre-battle draft screen.

## v0.4 — Deterministic auto-combat ✅
- Headless seeded fixed-timestep combat simulation.
- Open left-vs-right battlefield with automatic formation.
- Target locking, tank/frontline priority, ranged spacing and collision-aware movement.
- Normal `ATK - DEF` combat with speed ratings/caps and deterministic projectiles.
- Commander pre-battle skills.
- Data-driven starter unit abilities: aura damage/healing/debuffs, AoE, DoT, healing puddles, push/pull and empowered attacks.
- Battle event log, replay frames and 120-second round resolution.
- Placeholder Battle 1 visual replay against a deterministic training opponent.
- Combat determinism/regression tests.

## v0.5 — AI ✅
- Legal Army/draft choices.
- Basic decision policy.
- Hidden-current-pick opponent drafting.
- Replace the v0.4 training opponent with strategic PvAI decisions.
- Original pixel silhouettes, elemental palettes and a decorated meadow battlefield.

## v0.6 — Fire/Water/Earth vertical slice ✅
- Complete multi-round match loop.
- Four-loss condition, loser draft bonus and Sudden Death.
- Full starter content playable.
- Fantasy UI theme and viewport-tested draft, replay and result screens.

## v0.7 — Presentation and balance baseline ✅
- Thirteen original pixel silhouettes (twelve roster units and the Commander plant), shared portraits and elemental palettes.
- Procedural eight-direction movement, four-direction attacks, neutral idle/death, interpolation and event-driven VFX.
- Optional synthesized audio, pause, reduced motion, HP numbers and keyboard controls.
- Fantasy UI polish, readable rival information and full-field aspect preservation.
- Reproducible automated balance samples and capped-roster stress tests; see `PLAYTEST_REPORT.md`.
- CI screenshots, deployment validation gate, exported-PCK tests and public build identity.

## v0.7.1 — Player experience (requested after playtesting)

- Title menu, How to Play, shared pause/settings and confirmed match exit.
- Starter warbands, focused collection browsing and clearer draft/results.
- Original scenery, two music loops, nine effects and saved presentation preferences.
- Menu/navigation/persistence tests and ten visual captures.

## v0.7.2 — Reference card interface

- Portrait cards with elemental, recruit/cap and class badges.
- Commander gallery, full-body portraits and separate description/passive/active panels.
- Four warband slots, eight-column collection, filters and three local presets per Commander.
- Preset validation, art/export coverage and layout checks.

## Next major phase — Game Director scope decision

The approved elemental PvAI vertical slice is implemented. A new major roadmap phase needs an explicit direction before implementation: campaign/progression, online PvP, or VTuber/mascot roster integration. These introduce major gameplay systems, infrastructure or roster changes beyond the current approved roadmap. Human playtesting should inform further balance values; the current tuning remains provisional.
