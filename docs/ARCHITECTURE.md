# Architecture

## Core principle

VCommander separates **content data**, **game simulation**, and **presentation**.

```text
Presentation / UI / animation
          ↓ reads events/state
Game systems / simulation
          ↓ reads definitions
Content data
```

Presentation must never be the authoritative source of draft legality, combat outcomes or game rules.

## Layers

### Data — `data/`

Contains Commander, Army card, Buff, set/theme and balance definitions. Content IDs are stable identifiers and do not depend on display names.

### Core systems — `scripts/`

Generic logic such as content loading, set checking, Army loadout state, drafting, seeded combat simulation, match state and AI.

### Presentation — `scenes/`, `ui/`, `assets/`

Godot scenes, controls, effects, animation and audio. Presentation reacts to game state and battle events.

## Current/planned modules

```text
scripts/
  core/
    content_database.gd
    game_state.gd
    save_manager.gd        (future)
  army/
    army_loadout.gd
  commanders/
    set_bonus_checker.gd
    commander_system.gd    (future)
  draft/
    draft_system.gd
    draft_screen.gd
  combat/
    battle_event.gd
    combat_simulator.gd
    battlefield_view.gd
    combat_screen.gd
  ai/
    ai_controller.gd       (v0.5)
```

`GameState` owns the selected Commander, four-slot unique `ArmyLoadout`, match seed, current `DraftSystem`, and the latest combat-preview result.

`DraftSystem` owns draft legality and progression: selection points, unit counts, Buff stacks, Commander skill-use limits, seeded offer generation and auto-selection. The draft UI only displays and invokes this state.

`CombatSimulator` is a headless fixed-timestep simulation. It receives plain side configurations plus a seed and balance definition, then returns a deterministic result containing battle events and replay frames. It does not depend on Godot scene nodes, sprite animation or combat UI.

`BattlefieldView` and `combat_screen.gd` consume simulator output only. The v0.4 placeholder visualization cannot change targeting, damage or battle outcomes.

Commander theme completion is calculated from equipped card definitions and their `set_id`. It is not hardcoded to four permanently named card IDs.

## Determinism requirement

All randomized gameplay systems accept/store an explicit match seed. A match should be reproducible from the same game state, content version and seed.

v0.4 combat uses a fixed simulation timestep and seeded ordering/spawn randomness. CI checks that the same battle input and seed produce the same winner, duration and event fingerprint.

## Combat/presentation boundary

Combat emits plain dictionaries for events such as:

- `spawn`
- `commander_skill`
- `ability`
- `attack`
- `damage`
- `heal`
- `defeat`
- `battle_end`

The simulator also emits periodic position/HP frames for the temporary combat replay. Visual scenes consume these outputs; animations never decide damage.

## v0.4 training opponent boundary

Strategic AI belongs to v0.5. The v0.4 playable combat preview therefore uses a clearly labeled training opponent that:

- mirrors the player's four-card pre-match loadout,
- performs three legal opening Army-card selections from a separate deterministic seed,
- does not use a Commander skill,
- exists only to exercise combat end-to-end.

This is a test harness, not the final opponent policy.

## Multiplayer future-proofing

The first target is local player vs AI. Match orchestration should avoid assuming the opponent is always local AI so a future online provider can be added without rewriting draft/combat rules. No multiplayer backend is built until explicitly approved.
