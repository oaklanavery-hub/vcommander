# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Slime Princess and her army

- User requests Slime Princess, a full-theme +100% attack bonus for allies spawned after a death, Giant Slime death splitting, slowing Slime Cannon shots, basic Slime Ball melee and a large ten-second Slime Barrel death area.
- Confirmed product choices: bonus applies only to the newly spawned ally; Giant splits once on death into two half-HP/half-ATK children that cannot split; design the Commander active skill autonomously.
- Recruit/cap values supplied by the user: Giant Slime 1/4, Slime Cannon 2/4, Slime Ball 2/6, Slime Barrel 2/6.
- Branch `feat/slime-princess`, base verified v0.7.7 main `3a0fc122937974cc7d5a4647d9552bc895e8c641`. Previous release: [PR #18](https://github.com/oaklanavery-hub/vcommander/pull/18), [CI](https://github.com/oaklanavery-hub/vcommander/actions/runs/39091926835), [export/live verification](https://github.com/oaklanavery-hub/vcommander/actions/runs/39092017045).
- Active design: Royal Jelly blesses starting drafted allies before battle; each revives once at 50% HP. Death-created children do not inherit revival. Death abilities still resolve; each Giant's split can occur only once across its revival. Revival and split children receive the active theme bonus, ordinary round-start spawns do not. Temporary units never enter persistent draft counts.
- Checkpoint 1: data-driven death spawns, revival, temporary speed debuffs and damaging areas; Slime content, validators and meaningful focused mechanics tests. Stats/slow magnitudes/damage are provisional tuning.
- Checkpoint 2: original pixel art, Slime palette/cards, accurate ability/bonus descriptions, bouncing attacks, goo projectiles/areas, revival/split feedback and SFX. Keep battlefield word labels removed.
- Checkpoint 1 implemented. Passing: content validation (4 Commanders/16 cards/4 sets), clean Godot editor import, new Slime Commander suite, existing combat simulator and summon-allegiance suites.
- Tests cover the supplied recruit/cap values, both-team split ownership, half stats and triggered double attack, no recursive splitting, once-only revival, no duplicated Giant split, round reset, simultaneous skill damage, refreshing slow expiry, exact ten-second pool duration and entering/leaving it, ally safety and determinism.
- Checkpoint 1 saved at `e53ff5fd175124a570ca31e9c626e28c3ac3d914`, with executable-mode preservation at `c831abafccc10518627c54689c59a752e143e5e3`.
- Checkpoint 2 implemented: user-corrected pink Princess, green Giant/Cannon, white Ball and pink Barrel; original generated cutouts packed into expanded atlases without altering previous frames, matching fallback catalogs, accurate triggered-bonus/ability descriptions, Slime squash/bounce/recoil, event-timed births, pink pools/opening/revival, and five original SFX.
- Passing: art and presentation/WAV validators; clean editor import after correcting two GDScript type inferences; Slime presentation, export content, battle readability, battle presentation and scene-flow suites. Native Slime capture (11 frames) and standard UI capture (10 frames) passed. Reviewed gallery, warband, Royal Jelly, Cannon contact, split and late pool views.
- Presentation checkpoint saved at `5df236b0132cff448480dfbd93cfa1bb1254a14e`. Final refined native views passed and were inspected: the gallery retains desktop margins and overlapping pools leave actors readable. Existing Commander/roster atlas pixels are byte-for-byte unchanged.
- Final copy audit added Slime to title/help/diagnostic roster names; no further gameplay or asset edits. Gate these final strings with the latest PR CI.
- [PR #19](https://github.com/oaklanavery-hub/vcommander/pull/19) records final release identity and verification links. [Checkpoint CI](https://github.com/oaklanavery-hub/vcommander/actions/runs/39094832636) passed all 19 suites and 66 visual captures for the presentation head. Working tree matched that pushed checkpoint before this handoff update.
- Next: require passing [latest PR checks](https://github.com/oaklanavery-hub/vcommander/pull/19/checks) for this final documentation checkpoint, merge, then complete Web export, exported-pack and served-pack verification. Record final run links/main SHA in the PR and verify actual remote state before resuming. No further gameplay decision is pending within the Slime request; other major roadmap phases still need direction.

## Previous task — Remove battlefield text tags (released v0.7.7)

- User requests removal of effect labels and ALLY/RIVAL labels on units.
- Branch `fix/battle-labels`, based on verified v0.7.6 main `21db85512e3fdbbb1362e29c189b14726a5e0165`. Prior release and checks: [PR #17](https://github.com/oaklanavery-hub/vcommander/pull/17), [CI](https://github.com/oaklanavery-hub/vcommander/actions/runs/39090022215), [live verification](https://github.com/oaklanavery-hub/vcommander/actions/runs/39090124708).
- Scope: remove unit ownership word badges and battlefield effect-name overlays. Keep team colours, pennants, visual effects, health UI and enemy-only summon checks. Move the pre-battle skill announcement into the existing status line outside the arena.
- No gameplay/data changes or new low-impact UI tests. Gate with existing presentation/scene-flow suites and native summon/frost views; save before full PR/export/live checks.
- Implemented the focused renderer cleanup and moved the pre-battle announcement below the arena. Clean Godot import, battle-presentation and scene-flow suites passed.
- Next: save the checkpoint, inspect native summon and frost views, then require PR CI, Web export and served-pack verification. Final run links and identity belong in this branch’s PR.

## Previous task — Summoned plant allegiance (released v0.7.6)

- User reports Earth Commander plants attacking allies; they must damage enemies only.
- Branch `fix/plant-allies`, based on verified v0.7.5 main `f0565afbeca8d729aca9740a95ada760e932b48c`. Prior release: [PR #16](https://github.com/oaklanavery-hub/vcommander/pull/16), [passed CI](https://github.com/oaklanavery-hub/vcommander/actions/runs/39089075694), [passed export/live verification](https://github.com/oaklanavery-hub/vcommander/actions/runs/39089225227).
- Current inspection: normal acquisition selects enemies, but locked targets and the attack/projectile/damage paths do not independently reject allied ownership. Both sides also use identical green summoned sprites, spawning on the opposite half.
- Checkpoint: reproduce stale allied lock/seed damage in a focused regression, enforce enemy allegiance through attack and damage resolution, and visibly label summon ownership without changing skill placement, stats or rules. Include both sides casting together.
- Confirmed the new regression fails on main for stale allied locks, allied attack release, invalid seed damage and direct friendly damage injection, on both teams. The normal simultaneous-summon audit already targeted enemies; the live report’s exact trigger was not captured.
- Implemented enemy checks through target retention, attack release, source-side projectile collision and queued/applied damage. Summon metadata, ALLY/RIVAL badges, team pennants/trails and roster counts make ownership explicit.
- Passing focused suites: summon allegiance, projectile collision, combat simulator, battle presentation and battle readability. Clean Godot import passed.
- Next: save the checkpoint, inspect three simultaneous-summon native captures, then require CI/export/live verification. Final run links and deployed identity belong in this branch’s PR.
- Release gate: focused tests and native ownership review, then full PR CI, Web export, exported-pack suites and served-pack verification. Record final run links/identity in the PR.

## Previous task — Contact, persistent frost, hearts and attack readability (released v0.7.5)

- User requests shots that visibly connect, full-field Frozen Field for the entire round, visible remaining match lives and much clearer attack animation.
- Branch `feat/battle-contact`, based on verified v0.7.4 main `a30b9a38cf0deeaa67d0a0b63a483a0d00f8ca61` (PR #15).
- Checkpoint 1: record launches/terminal events and exact event HP; reconstruct flight through between-frame impacts and align contact/health feedback. Preserve physical collisions, damage and seeded outcomes. Save after focused regressions.
- Checkpoint 2: persistent full-field frost with affected-side status, shared pixel heart meters without revealing the already-scored outcome, and distinct anticipation/strike/recovery character poses and attack effects. Save before full validation.
- Final gate: native phase captures, focused regressions, full PR CI, Web export and live served-pack verification.
- Checkpoint 1 implemented. Clean Godot import and new readability tests pass for complete between-frame flights, moving interception, lethal contact/HP timing, visible contact hold and dead-target fizzle. Battle-presentation, physical-projectile and simulator regressions are the focused checkpoint gate.
- Checkpoint 1 saved at `ce66ed89e67e508f9a0eee1c1fcea2f5392211d2`; all four focused suites passed.
- Checkpoint 2 implemented: persistent full-field frost and affected-army status; shared pixel hearts that hide the scored result until playback ends; ten data-driven articulated rigs with anticipation before release, strike/recovery, bow draw, charging, melee strokes and hit recoil.
- Passing checkpoint checks: presentation metadata/WAV validation; readability, battle-presentation, player-experience and scene-flow suites. An added draft HUD row initially exceeded the desktop height; placing the compact meter in its header fixed the measured bounds and scene-flow passed again. Native phase captures and full CI/export remain pending.
- Checkpoint 2 saved at `aa08bd007dfac09e6c9560c14341dd875f71229c`. Native review completed for the standard screens and all contact/attack/frost sequences. Compact heart labels were spaced after visual review.
- Final refinements: give the killing blow a short presentation tail before results; synchronize the first Pitcher Plant bite with completed drag, including keeping a lethally pulled target visible until that bite. Added phase/held-death coverage. Readability, battle-presentation and scene-flow suites pass after these changes.
- Exact winners, durations and semantic event fingerprints match v0.7.4 across three seeded elemental battles. No balance or combat outcome change.
- Next: save this final checkpoint, complete final native captures (including a deterministic lethal pull), then require PR CI, Web export and served-pack verification. Record the run links and deployed identity in the PR.

## Previous task — Battle animation, audio and pre-battle skill playback (released v0.7.4)

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
- Checkpoint 2 saved at `3edd76cd9e793642ab2d9cf802c0a88258449452` before native FX review.
- Native review completed: ten standard screens plus twelve dedicated captures covering three skill openings, six projectile styles and vine extension/drag/retraction. Review caught overlapping pulls on one enemy; visual chains now retain the earliest grab position and latest authoritative destination, with both vines following the same displayed target. The corrected vine sequence was rendered and inspected again.
- Additional checks passed: exact results/durations/semantic combat-event fingerprints match v0.7.3 across three seeded elemental matchups; the next battle resets a manually changed speed to 1×. Enhanced battle-presentation tests pass after the final refinements.
- Next: publish the final visual-review checkpoint and open the branch PR; require full CI, Web export, exported-pack tests and live served-pack verification. Record run links/deployed identity in that PR before reporting the release live.
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
