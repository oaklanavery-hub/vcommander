# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Reference-based card interface

- User supplied three wireframes: portrait army/Commander cards with badges; four warband slots with collection/filter/presets; Commander gallery, full portrait and separate description/passive/active panels.
- Branch: `feat/card-gallery`, based on main `d5851c0a0ec9712b369d72939aa697b4949d298d` (v0.7.1 live and verified).
- Scope: reusable portrait cards, original replaceable Commander portraits, the two reference layouts, element filtering and three locally saved warband presets per Commander.
- Preserve gameplay, current sound/menu support, mixed-element legality and draft flow. Badge fractions show recruits per pick / maximum count from content data.
- Preset behavior: choose a slot to load it; an empty slot preserves the current army; Save stores a complete valid warband; Clear clears the current army without deleting saved presets.
- Acceptance: reference layout at 1280×720, readable cards/badges/description panels, safe preset round trips and invalid-save rejection, full menu-to-match flow and existing regressions, exported/deployed verification.
- Checkpoint 1 implemented: shared portrait cards, element/class/recruit-cap badges, three original Commander portraits and the reference gallery/full-view/description layout.
- Checkpoint 1 validation: content/art validation and `tests/test_scene_flow.gd` passed; the new Commander screen was rendered and visually inspected at 1280×720.
- Next: rebuild the warband screen, add validated preset persistence and exercise the complete flow. Full final CI/export/deployment checks are pending.
- If interrupted: inspect this branch and its PR, resume the next unchecked acceptance item, and preserve the existing playable main.
