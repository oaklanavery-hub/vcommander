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

Detailed presentation atlases use `assets/pixel/art_manifest.json` schema 1. Each atlas group provides a texture resource path, a two-number `cell_size`, and a `frames` map from stable presentation/content IDs to zero-based column/row coordinates. Frames are unique, within the RGBA texture bounds, and never define gameplay stats. The current atlases cover four Commander themes and all sixteen Army cards plus the summoned Commander plant. `menu_commanders` adds four transparent 128×128 seated frames keyed by Commander element for the title scene. `menu_fire` adds six 80×80 transparent flame frames keyed `0` through `5`, packed with a common root anchor. The separate `menu_scene` entry provides a background `texture` path and pixel `size` (640×360), rather than atlas cells; neither menu resource supplies gameplay data.

Starter skill behavior types in v0.4 are:

- `targeted_aoe_max_hp`
- `round_debuff`
- `summon_stationary_units`
- `army_revival`: `revives_per_unit` and `revive_health_pct`; applies to starting drafted units before pre-battle damage.

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

Slime adds generic `death_split` (`trigger: on_death`, `spawn_count`, `child_health_pct`, `child_attack_pct`, `child_visual_scale`), `ranged_aoe_slow` (`radius`, negative enemy speed percentages and `slow_seconds`) and `death_damage_area` (`trigger: on_death`, `radius`, burst `attack_pct`, `duration_seconds`, `tick_seconds`, `damage_attack_pct_per_tick`). Split children have basic attacks and no split/revival inheritance. On-death abilities remain content-driven.

`absorb_burst` uses `absorb_pct` (greater than 0 and below 100), positive `burst_seconds` and `death_multiplier`, a named `radius` and named `pushback`. It retains normal melee attacks. Runtime `absorbed_damage` stores fractional post-defense prevention and `next_burst_at` schedules each body independently; both reset on birth/revival. The shared damage application path covers ordinary and chained damage. Discharges queue the stored amount directly without a second DEF calculation.

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

A bonus may define `trigger: on_death_spawn` with `stat: attack`. Its percentage applies only to a newly created or revived body after a death; ordinary spawn stat calculation skips this trigger. Optional `description` and `summary` strings describe triggered bonuses accurately in the interface.

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

`game_balance.formation` defines positive `spacing_units`, `area_spread_multiplier` (at least 1), and whole-number `maximum_rows`. The planner increases spacing according to the actually recruited opposing area's damage capability, then fits collision-safe ranks to the battlefield. It reads existing roles, stats and ability types; no per-card formation coordinates are stored.

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
Its `formations` dictionary records each side's strategy, spacing, rank count, enemy pressure and canonical unit placements (`card_id`, `unit_index`, role, rank, x/y). This is a read-only record of the authoritative initial layout. Spawn events and the first frame use those same positions before Commander skills; summoned/revived bodies retain their existing placement rules.
When Commander skills are selected, the result also includes `pre_battle` with `before` and `after` snapshots, copied skill-resolution `events`, and `event_end` (the exclusive index in the main event array). This is playback metadata; skill damage and summons still resolve once at simulation time zero. Normal battle frames begin after resolution.
Pull events provide `source_x/y`, `from_x/y`, `to_x/y` and original target HP for the visual grab/drag. These record the collision-resolved displacement, including a blocked pull with identical endpoints. Projectile frames include `card_id`, launch position/time and source/target IDs; `projectile_impact` events provide the projectile ID, source/card/target and impact coordinates. Attack events provide source/target coordinates. These fields do not drive combat outcomes.

`data/presentation/combat_cues.json` is presentation schema 1. Its `units` map assigns each current card/plant ID a projectile style (`none`, `arrow`, `seed`, `fireball`, `dragonfire`, `water_orb`, `ice_shard`), attack motion (`slam`, `slash`, `cast`, `shoot`, `bite`) and attack/impact sound cue names. Unknown content falls back to a generic presentation profile.

## Validation expectations

- IDs are unique within each content type.
- Content groups are nonempty and there is one global balance file. The roster currently contains 4 Commanders, 16 Army cards, 4 themes and 5 Buff Cards, including the Slime Court expansion.
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

Projectile launches also emit `projectile_launch` with a copied projectile dictionary. Both terminal event types carry `projectile_id` and final `x/y`; impact identifies the actual interceptor, while fizzle retains the dead locked target. Damage/heal events include exact `hp_after` (rendered clamped at zero). This playback metadata covers flights and health changes between periodic frames.

Combat cue profiles also declare a presentation-only `rig`: `brute`, `claw`, `mage`, `dragon`, `serpent`, `healer`, `tree`, `pitcher`, `bow`, `plant`, `slime`, `cannon` or `barrel`. This selects character articulation, never combat behavior. `slime_green` projectiles and optional `impact_style`/`accent` values preserve the requested green/white/pink unit identities; `bounce` is a presentation-only attack motion. Area-heal cast events include source/card and source/target coordinates for the same attack-pose timeline.

Spawn events and replay-unit snapshots carry a `summoned` boolean for temporary Commander summons. Their existing `side` is always the casting Commander’s team. Presentation uses this flag and side for ownership markers; field coordinates never determine allegiance.

Death-created units use unique `side:card_id:spawnN` IDs and emit `spawn` with `source: death_split` or `revival`, the parent `source_unit_id`, and a read-only `unit` snapshot. Snapshots include `visual_scale`, `spawned_at`, `slowed`, `revival_ready` and attack for review; none is a source of game rules. Damaging area frames include `type: damage_area`, owner, center/radius, `created_at`, duration and remaining time.

Absorbing-unit snapshots include `absorbed_damage`, `burst_seconds` and `next_burst_at`. Actual damage events include fractional `amount`/`hp_after` and, for prevention, `absorbed`/`absorbed_total`. `ability` events with `kind: absorb_burst` record stored/released damage, radius, center and `on_death`; `pushback` events record target/from/to endpoints. These are read-only replay tracks, including exact charge reset between frames; they never feed back into simulation.

Defeat events include the exact final `x/y` and `unit` snapshot so a corpse remains aligned with its death burst even when the actor disappears between periodic frames. Pending pushback holds the recorded pre-hit endpoint until the event time instead of interpolating toward a future displacement.
