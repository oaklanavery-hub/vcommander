# Data Schema

All content JSON currently uses `schema_version: 1`.

## IDs

IDs are lowercase snake_case and immutable once released. Display names may change without changing IDs.

Examples:

- `commander_fire_01`
- `card_fire_01`
- `set_fire_01`

## Commander

Required fields:

```json
{
  "schema_version": 1,
  "id": "commander_fire_01",
  "display_name": "Fire Commander",
  "element": "fire",
  "signature_set_id": "set_fire_01",
  "status": "placeholder"
}
```

## Army card

Required fields:

```json
{
  "schema_version": 1,
  "id": "card_fire_01",
  "display_name": "Fire Army 1",
  "element": "fire",
  "set_id": "set_fire_01",
  "status": "placeholder",
  "stats": {
    "health": 100,
    "attack": 10,
    "attack_speed": 1.0
  },
  "tags": ["starter", "placeholder"]
}
```

Placeholder stats exist only to exercise loading/validation. They are not approved balance.

## Signature set

```json
{
  "schema_version": 1,
  "id": "set_fire_01",
  "display_name": "Fire Starter Set",
  "element": "fire",
  "required_count": 4,
  "required_card_ids": ["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_04"],
  "bonus": {
    "status": "design_pending",
    "effects": []
  }
}
```

`effects` stays empty until the bonus is explicitly designed.

## Validation expectations

- IDs must be unique within their content type.
- Commander `signature_set_id` must resolve.
- Set card references must resolve.
- Starter sets currently require exactly four unique cards.
- Each referenced starter card must reference the same `set_id`.
- JSON must parse without errors.
