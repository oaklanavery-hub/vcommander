# Data Schema

All gameplay content JSON currently uses `schema_version: 1`.

## IDs

IDs are lowercase snake_case and remain stable after release. Display names may change without changing IDs.

## Commander

Required core fields:

```json
{
  "schema_version": 1,
  "id": "commander_fire_01",
  "display_name": "Fire Commander",
  "element": "fire",
  "signature_set_id": "set_fire_01",
  "status": "playtest",
  "active_skill": {
    "id": "meteor_barrage",
    "display_name": "Meteor Barrage",
    "type": "targeted_aoe_max_hp",
    "uses_per_match": 2,
    "uses_per_round": 1,
    "selection_cost": 1,
    "timing": "pre_battle"
  }
}
```

`active_skill.type` selects a generic combat behavior. Skill-specific parameters live beside it inside `active_skill`; generic systems must not branch on Commander IDs.

The optional Commander `description` is player-facing flavor text. It does not grant abilities or modify stats.

Detailed presentation atlases use `assets/pixel/art_manifest.json` schema 1. Each group provides a texture resource path, a two-number `cell_size`, and a `frames` map from stable presentation/content IDs to zero-based column/row coordinates. Frames are unique, within the RGBA texture bounds, and never define gameplay stats. The current atlases cover three Commander elements and all twelve Army cards plus the summoned Commander plant.

Starter skill behavior types in v0.4 are:

- `targeted_aoe_max_hp`
- `round_debuff`
- `summon_stationary_units`

## Army card

Required core fields:

```json
{
  "schema_version": 1,
  "id": "card_fire_01",
  "display_name": "Magma Golem",
  "element": "fire",
  "set_id": "set_fire_01",
  "status": "playtest",
  "role": "tank",
  "summon_amount": 1,
  "unit_cap": 3,
  "stats": {
    "health": 1250,
    "attack": 85,
    "defense": 60,
    "attack_speed": 60,
    "movement_speed": 55,
    "range": 1
  },
  "ability": {
    "id": "burning_aura",
    "type": "aura_damage"
  }
}
```

`attack_speed` and `movement_speed` are whole-number ratings. `summon_amount` is how many units one draft pick adds; `unit_cap` is the maximum army count for that card during the match.

The simulator consumes generic `ability.type` behavior. Current starter types include aura damage/healing/debuffs, basic ranged attacks, ranged AoE/DoT/pushback, area healing, pull-then-melee, empowered attacks and on-death explosions.

## Commander themed set

```json
{
  "schema_version": 1,
  "id": "set_fire_01",
  "display_name": "Fire Commander Theme",
  "element": "fire",
  "required_count": 4,
  "activation": "all_equipped_cards_match_set",
  "bonus": {
    "stat": "attack",
    "percentage": 10,
    "stacking": "multiplicative"
  }
}
```

Cards belong to a theme through `set_id`. A theme is allowed to contain more than four cards; activation checks the four equipped cards, not a permanently hardcoded list of four card IDs.

## Buff card

```json
{
  "schema_version": 1,
  "id": "buff_attack",
  "display_name": "Attack Boost",
  "stat": "attack",
  "percentage": 15,
  "max_stacks": 3,
  "stacking": "multiplicative",
  "status": "playtest"
}
```

Buffs live in `data/buffs/`. They are not part of the four-card pre-match Army loadout.

## Balance

Global numeric playtest values that are not tied to a specific content item live in `data/balance/game_balance.json`.

The v0.4 simulator reads:

```json
{
  "battlefield": {
    "width": 24.0,
    "height": 14.0,
    "edge_margin": 1.0
  },
  "simulation": {
    "step_seconds": 0.1,
    "frame_interval_seconds": 0.2,
    "collision_radius": 0.42,
    "movement_units_per_second_at_100": 2.5,
    "projectile_units_per_second": 12.0,
    "radii": {
      "small": 1.5,
      "medium": 2.5,
      "large": 3.5
    }
  }
}
```

These are playtest tuning values, not new conceptual gameplay rules.

## Combat-side runtime input

`CombatSimulator` receives runtime dictionaries assembled by `GameState`, not stored JSON files. Each side includes:

- side ID
- Commander definition
- whether that round's Commander skill is active
- the four Army card definitions
- current drafted unit counts
- active Buff definitions/stacks
- active Commander-themed set bonus, if any

The simulator returns a result with winner/reason/duration, a battle-event array and replay frames.
When Commander skills are selected, the result also includes `pre_battle` with `before` and `after` snapshots, copied skill-resolution `events`, and `event_end` (the exclusive index in the main event array). This is playback metadata; skill damage and summons still resolve once at simulation time zero. Normal battle frames begin after resolution.

## Validation expectations

- IDs are unique within each content type.
- Exactly 3 starter Commanders, 12 starter Army cards, 3 starter sets, 5 starter Buff Cards and 1 global balance file exist for the current vertical slice.
- Every Commander `signature_set_id` resolves.
- Every Commander active skill defines an `id`, generic `type`, and positive use/cost limits.
- Every Army card `set_id` resolves.
- Every starter set has at least four cards belonging to it.
- Every Army card has positive `summon_amount`, `unit_cap`, and required combat stats.
- `summon_amount` cannot exceed `unit_cap`.
- Every Army card defines an ability `id` and generic `type`.
- Every Buff Card has a positive percentage and `max_stacks` of 3.
- Required battlefield/simulation balance values are positive.
- JSON parses without errors.

## Presentation metadata (v0.7)

Combat replay units include stable `card_id`, `element`, HP, position, ability type, aura radius and burn state. Frames also include projectile positions and temporary healing areas. Commander/meteor events carry generic behavior types, elemental colors and impact coordinates. These fields are read-only presentation output; they never provide gameplay input.

The separate `assets/pixel/roster.json` catalog uses its own schema version 1: common colors, elemental palettes and a `sprites` dictionary keyed by presentation/content ID. Each sprite defines a name, element, role and sixteen rows of sixteen palette characters. `.` is transparent. `tools/validate_art.py` verifies palette validity, dimensions and coverage of all starter cards independently of gameplay content validation.

`assets/pixel/commanders.json` uses the same palette-character approach for original 32×48 full-body portraits keyed by element. Commander cards and the full portrait share this catalog. A card's recruit/cap fraction and class badge always read its content definition, independently of the artwork.

## Local warband preset data

`user://warband_presets.cfg` contains Commander-ID sections with `preset_0`, `preset_1` and `preset_2` arrays of four stable Army card IDs. Saved order is preserved. Loading validates the Commander, all card IDs, uniqueness and completeness against current content; invalid data yields an empty result and does not alter the active loadout. This local data is never exported as content or used to grant units.
