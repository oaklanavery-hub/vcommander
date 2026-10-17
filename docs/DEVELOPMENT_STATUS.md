# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Battle animation, audio and pre-battle skill playback

- User requests visible stretching/retracting Pitcher Plant vines, projectiles matched to unit roles, additional SFX, each battle starting at 1×, removal of result skipping, and complete Commander skill animations before combat begins.
- Branch: `feat/battle-effects`, based on main `85acd3a4481dfdbf253ecab6a1495b7ffe0d2466` (v0.7.3 verified and live in PR #14).
- Preserve all gameplay outcomes, deterministic timing and existing rules. Commander effects already resolve before combat in simulation; add a separate visual prelude that holds the replay clock and armies until the skill presentation finishes. Both selected skills share that prelude.
- Checkpoint 1: pre-battle replay metadata and presentation clock, default 1×, remove Skip and its code paths; focused timing/flow tests, then save.
- Checkpoint 2: content-driven projectile/attack visuals, source/target pull endpoints, animated vines and impact feedback, original extra SFX with sensible per-cue throttling; save.
- Final gate: relevant headless checks, native captures of skills/vines/projectiles, PR CI, Web export and served-pack verification.
- Checkpoint 1 implemented: simulation exposes immutable before/after skill snapshots and the pre-battle event range. `BattlePrelude` schedules simultaneous skill playback while both armies and the combat clock hold. New replay instances start at 1×; Skip and its method have been removed.
- Checkpoint 1 passing checks: clean Godot import, `test_battle_presentation.gd` (all three skill types, simultaneous skills, clock hold/pause, exact final snapshot and unchanged outcomes), `test_scene_flow.gd`, `test_combat_simulator.gd`.
- Checkpoint 1 saved at `1d6de84fe72941339f3d941c946b7849be7f1157`.
- Checkpoint 2 implemented: two-strand leafy vines with extend/grab/drag/retract phases, exact pull endpoints, six projectile styles with interpolation/impact effects, attack anticipation/lunge/recovery and sprouting plants. Thirteen content-driven profiles and seventeen new original SFX use independent cue cooldowns and twelve effect voices.
- Passing focused checks: presentation/WAV validation, clean Godot import, battle presentation (including vine endpoint animation, projectile assignments and independent sound throttling), projectile collision, scene flow and player experience/audio coverage.
- A standalone headless test initially exposed an autoload compile dependency in `BattleAudio`; node lookup in `_ready` corrected it and focused checks now pass. The initial stalled test was bounded at 60s; do not rerun it unchanged.
- Next: save checkpoint 2 before native FX review; inspect three skill openings, six projectile styles and all three vine phases, then run the PR/export/deployment gate. Full remote checks remain pending until recorded in the PR.
- If interrupted: inspect this branch and its PR/checks, then resume the next unchecked checkpoint. The next major gameplay phase remains a Game Director scope decision.

## Previous task — Detailed pixel fantasy art and interface polish (released v0.7.3)

- User approved v0.7.2 layouts and requested richer character artwork, using a detailed fighting-game portrait as Commander quality reference and smaller fighter sprites as army quality reference. References guide pixel craft and readability; create original fantasy designs.
- Branch: `feat/fantasy-art`, based on main `f7f9282264cee06bab6a20e46bd8c8672b3499e9` (v0.7.2 deployed and verified in PR #13).
- Scope: distinct detailed Fire/Water/Earth Commander portraits, a detailed original 13-sprite roster atlas shared by cards and combat, rounded card frames, refined panel/button states and visual hierarchy.
- Preserve content IDs, rules, deterministic combat, menu/audio support, preset compatibility and reference screen layouts. Artwork and animation remain presentation-only.
- Checkpoint 1: generate and inspect original transparent pixel-art atlases, integrate their asset mappings and verify export coverage; save to the short-lived branch.
- Checkpoint 2: polish shared cards/theme and adapt presentation scaling/animation; inspect all affected screens at 1280×720, run relevant checks and save.
- Final gate: GitHub CI, Web export, exported-pack suites and verification of the served build before reporting the update live.
- Checkpoint 1 implemented: original transparent Commander and roster atlases generated, inspected at native pixel scale and packed into cells with gutters. Shared atlas loader, detailed card portraits and replay-driven unit rendering integrated; legacy catalogs remain fallbacks. Provenance and exact generation prompts are in `assets/pixel/CREDITS.md`.
- Checkpoint 1 saved at `a3cd8be397026342819d73f3e018025803b709f5`. Passing checks: art validation, clean Godot editor import and exported-content tests with all sixteen detailed frames.
- Checkpoint 2 implemented: rounded pixel-edged frames and panels, gold selection/hover states, darker card nameplates, richer portrait framing, taller Commander cards, navigation/scrollbars, unit/health-bar spacing and nearest-filtered camp sprites.
- Passing focused checks: data/art validation, clean import, `tests/test_scene_flow.gd`, `tests/test_player_experience.gd`, and enhanced exported-content checks for visible art, alpha, frame gutters and exact cached left-facing mirrors.
- Ten final native screen captures completed at 1280×720. Commander, builder, draft, battle and menu layouts inspected. Visual review found a rival-strip mirroring issue; cached mirrored frame textures corrected it without changing the caller's draw transform, and the final battle captures passed review.
- Next: publish checkpoint 2 and create its PR, then verify all CI/export/deployment gates. Record final run links and deployed identity in the PR; do not report live before verification passes.
- If interrupted: inspect this branch and remote checks, preserve completed checkpoints, and resume the next unchecked item. The next major gameplay phase still requires a product direction.

## Previous task — Reference-based card interface (released v0.7.2)

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
- Released in PR #13. CI, export and served-pack verification passed for v0.7.2 at `f7f9282264cee06bab6a20e46bd8c8672b3499e9`; see that PR for run links. This is the completed baseline for the current art refinement.
