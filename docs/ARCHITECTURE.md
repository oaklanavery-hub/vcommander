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

Godot scenes, controls, effects, animation and audio. Presentation reacts to system state and events.

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
    combat_simulator.gd    (v0.4)
    battle_event.gd        (v0.4)
  ai/
    ai_controller.gd       (v0.5)
```

`GameState` owns the selected Commander, four-slot unique `ArmyLoadout`, match seed and current `DraftSystem`.

`DraftSystem` owns draft legality and progression: selection points, unit counts, Buff stacks, Commander skill-use limits, seeded offer generation and auto-selection. The draft UI only displays and invokes this state.

Commander theme completion is calculated from equipped card definitions and their `set_id`. It is not hardcoded to four permanently named card IDs.

## Determinism requirement

All randomized gameplay systems accept/store an explicit match seed. A match should be reproducible from the same game state, content version and seed.

## Combat/presentation boundary

Combat code must emit plain battle events such as attack, damage, defeat, ability trigger or skill resolution. Visual scenes consume those events and animate them. Animations never decide damage.

## Multiplayer future-proofing

The first target is local player vs AI. Match orchestration should avoid assuming the opponent is always local AI so a future online provider can be added without rewriting draft/combat rules. No multiplayer backend is built until explicitly approved.
