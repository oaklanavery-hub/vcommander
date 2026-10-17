# AI Development Rules

This file is mandatory context for AI-assisted development of VCommander.

Read `docs/DEVELOPMENT_STATUS.md` at the start of a development run, then inspect the actual branch, working tree and remote checks before resuming. The repository state takes precedence over an older handoff.

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

## Resumable development

- Split large requests into small, independently verifiable checkpoints. Aim for roughly 5–10 minutes of implementation and validation per checkpoint; this is a planning target, not a guarantee about platform timeouts.
- Select one focused change and its acceptance checks before editing. When authorized to continue autonomously, save each completed checkpoint before starting the next one. Do not expand the approved product scope to fill a run.
- Update `docs/DEVELOPMENT_STATUS.md` before a substantial change and at each checkpoint. Record the goal, branch/base commit, completed work, exact checks and results, pending work, and next concrete step. Distinguish passing, failed and not-yet-run checks.
- Commit and push coherent work to its short-lived branch before lengthy validation or export. An incomplete checkpoint may be saved on a branch, but must not be merged into `main` until the definition of done is met.
- During editing, run checks relevant to the change. Use GitHub Actions for the full validation and export gate; do not repeat an unchanged full test run or large balance simulation without a new reason. Large balance samples are for balance changes and explicit audits.
- Give external commands bounded timeouts. If a command stalls, save its command, output and current state; investigate or use an available alternative instead of repeatedly starting the same stalled operation.
- Before ending a run, leave the branch, check/run links and next action in the handoff. A saved checkpoint enables resumption; it does not make a new ChatGPT turn start automatically or remove platform limits.

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
