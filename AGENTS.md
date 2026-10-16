# AI Development Rules

This file is mandatory context for AI-assisted development of VCommander.

## Before editing

1. Read `docs/GAME_RULES.md`.
2. Read `docs/ARCHITECTURE.md`.
3. Read `docs/DATA_SCHEMA.md` when changing content data.
4. Read `docs/DECISIONS.md` before proposing structural changes.

## Non-negotiable rules

- Do not invent or silently change game rules.
- If a requested gameplay change modifies a rule, update `GAME_RULES.md` in the same change.
- Do not hardcode individual cards, Commanders, elements, or set bonuses into generic gameplay systems.
- Content definitions belong in `data/`.
- UI must not own game rules.
- Combat logic must be able to run without animations or UI.
- Random gameplay must accept an explicit seed so matches can be reproduced.
- `main` should remain playable and exportable.
- Prefer small, focused changes over broad rewrites.
- New systems should include validation or tests when practical.
- Do not restructure the architecture merely to implement a feature. Record an architectural proposal in `docs/DECISIONS.md` first.
- Update `docs/CHANGELOG.md` for meaningful project changes.

## Placeholder rule

Anything marked `placeholder`, `provisional`, or `design_pending` is infrastructure, not approved final game design. Do not treat placeholder stats, names, abilities, or art direction as locked decisions.

## Branch naming

Use short branches such as:

- `feat/commander-selection`
- `feat/draft-system`
- `fix/set-bonus-check`
- `balance/fire-starter`
- `docs/combat-rules`

## Definition of done

A change is not complete until:

- the project opens without script/parser errors,
- data validation passes,
- relevant tests pass,
- documentation matches the implemented behavior,
- generated build output is not committed.
