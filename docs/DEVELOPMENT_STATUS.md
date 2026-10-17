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
- Checkpoint 2 implemented: four slots above an eight-column gallery, filters, click-to-add/remove and three validated local presets per Commander. Save requires a valid full army; Clear preserves saved slots.
- All 14 local regression suites passed, including preset persistence and exported-content coverage. After applying the shared cards to unit draft offers, `tests/test_scene_flow.gd` and `tests/test_player_experience.gd` passed again.
- Native captures of all ten screens completed; Commander, warband and final draft layouts were visually inspected at 1280×720. Unit draft cards retain the current → after / cap count.
- Next: publish checkpoint 2, then verify CI/export/deployment. Remote gate results and the deployed commit belong in the PR record.
- If interrupted: inspect this branch and its PR, resume the next unchecked acceptance item, and preserve the existing playable main.
