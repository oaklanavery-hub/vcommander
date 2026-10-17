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

## v0.5 — AI
- Legal Army/draft choices.
- Basic decision policy.
- Hidden-current-pick opponent drafting.
- Replace the v0.4 training opponent with strategic PvAI decisions.

## v0.6 — Fire/Water/Earth vertical slice
- Complete multi-round match loop.
- Four-loss condition, loser draft bonus and Sudden Death.
- Full starter content playable.

## v0.7+ — Presentation and balance
- Pixel-art animation/VFX/audio.
- UI polish.
- Simulation-based balance testing.
- Playtesting and accessibility improvements.
