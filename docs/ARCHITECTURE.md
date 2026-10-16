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

Presentation must never be the authoritative source of combat outcomes or game rules.

## Layers

### Data
`data/`

Contains Commander, card, set and balance definitions. Content IDs are stable identifiers and should not depend on display names.

### Core systems
`scripts/`

Generic logic such as content loading, set checking, army loadout state, drafting, seeded combat simulation, match state and AI.

### Presentation
`scenes/`, `ui/`, `assets/`

Godot scenes, controls, effects, animation and audio. Presentation reacts to game state and events.

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
    draft_system.gd        (future)
  combat/
    combat_simulator.gd    (future)
    battle_event.gd        (future)
  ai/
    ai_controller.gd       (future)
```

`GameState` owns the currently selected Commander and four-slot `ArmyLoadout`. The Army Builder reads and mutates that state through generic methods; it does not calculate set completion itself.

## Determinism requirement

Randomized simulation must use a match seed. A battle should be reproducible from the same game state, content version, and seed.

## Combat/presentation boundary

Future combat code should emit plain battle events such as attack, damage, defeat or ability-triggered. Visual scenes consume these events and animate them. Animations do not decide damage.

## Multiplayer future-proofing

Phase 1 is local player vs AI. Match orchestration should avoid assuming the opponent is always local AI so a future online provider can be added without rewriting combat rules. No multiplayer backend is to be built until explicitly approved.
