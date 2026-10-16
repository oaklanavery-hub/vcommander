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
    "uses_per_match": 2,
    "uses_per_round": 1,
    "selection_cost": 1,
    "timing": "pre_battle"
  }
}
```

Skill-specific parameters are data fields inside `active_skill`; generic systems must not branch on Commander IDs.

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

Global numeric rules that are not tied to a specific content item live in `data/balance/game_balance.json`, including draft sizes/timers, round time, loss limit, speed caps and minimum damage.

## Validation expectations

- IDs are unique within each content type.
- Exactly 3 starter Commanders, 12 starter Army cards, 3 starter sets and 5 starter Buff Cards exist for the current vertical slice.
- Every Commander `signature_set_id` resolves.
- Every Army card `set_id` resolves.
- Every starter set has at least four cards belonging to it.
- Every Army card has positive `summon_amount`, `unit_cap`, and required combat stats.
- `summon_amount` cannot exceed `unit_cap`.
- Every Commander active skill has positive use/cost limits.
- Every Buff Card has a positive percentage and `max_stacks` of 3.
- JSON parses without errors.
