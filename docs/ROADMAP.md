# Roadmap

## v0.0 — Foundation ✅
- Repository structure, Godot 4.7 browser export, rules/schema/architecture, starter content, validation, CI and Pages.

## v0.1 — Commander and content system ✅
- Commander selection and data-driven content loading.

## v0.2 — Army builder ✅
- Exactly four Army slots, Commander-theme progress and shared game state.

## v0.3 — Draft prototype ✅
- Finalized match/draft/combat rules documented.
- Four unique pre-match Army cards with mixed-element support.
- Seeded three-choice draft offers.
- Opening Army-only draft.
- Summon amounts/unit caps and exhausted-card removal.
- Persistent Buff stack model and offer limits.
- Commander skill selection cost/use limits.
- 30-second per-selection timeout with random auto-pick.
- Interactive opening pre-battle draft screen.

## v0.4 — Deterministic auto-combat ✅
- Headless seeded fixed-timestep combat simulation.
- Open left-vs-right battlefield with automatic formation.
- Target locking, tank/frontline priority, ranged spacing and collision-aware movement.
- Normal `ATK - DEF` combat with speed ratings/caps and deterministic projectiles.
- Commander pre-battle skills.
- Data-driven starter unit abilities: aura damage/healing/debuffs, AoE, DoT, healing puddles, push/pull and empowered attacks.
- Battle event log, replay frames and 120-second round resolution.
- Placeholder Battle 1 visual replay against a deterministic training opponent.
- Combat determinism/regression tests.

## v0.5 — AI ✅
- Legal Army/draft choices.
- Basic decision policy.
- Hidden-current-pick opponent drafting.
- Replace the v0.4 training opponent with strategic PvAI decisions.
- Original pixel silhouettes, elemental palettes and a decorated meadow battlefield.

## v0.6 — Fire/Water/Earth vertical slice ✅
- Complete multi-round match loop.
- Four-loss condition, loser draft bonus and Sudden Death.
- Full starter content playable.
- Fantasy UI theme and viewport-tested draft, replay and result screens.

## v0.7 — Presentation and balance baseline ✅
- Thirteen original pixel silhouettes (twelve roster units and the Commander plant), shared portraits and elemental palettes.
- Procedural eight-direction movement, four-direction attacks, neutral idle/death, interpolation and event-driven VFX.
- Optional synthesized audio, pause, reduced motion, HP numbers and keyboard controls.
- Fantasy UI polish, readable rival information and full-field aspect preservation.
- Reproducible automated balance samples and capped-roster stress tests; see `PLAYTEST_REPORT.md`.
- CI screenshots, deployment validation gate, exported-PCK tests and public build identity.

## v0.7.1 — Player experience (requested after playtesting)

- Title menu, How to Play, shared pause/settings and confirmed match exit.
- Starter warbands, focused collection browsing and clearer draft/results.
- Original scenery, two music loops, nine effects and saved presentation preferences.
- Menu/navigation/persistence tests and ten visual captures.

## v0.7.2 — Reference card interface

- Portrait cards with elemental, recruit/cap and class badges.
- Commander gallery, full-body portraits and separate description/passive/active panels.
- Four warband slots, eight-column collection, filters and three local presets per Commander.
- Preset validation, art/export coverage and layout checks.

## v0.7.3 — Requested visual refinement

- Original detailed 128×192 Commander and 64×64 army atlas artwork.
- Rounded pixel-edged cards, panel/navigation polish and richer portrait framing.
- Shared card/battle artwork with nearest-neighbor scaling and export coverage.

## v0.7.4 — Requested battle presentation

- Commander skill openings complete before movement or the combat clock starts.
- 1× default playback, normal completion without result skipping.
- Stretch/grab/drag/retract vines, role-appropriate projectiles and stronger attack/impact motion.
- Seventeen additional original battle SFX and per-cue mixing.
- Opening, vine, projectile, sound and export regression coverage.

## v0.7.5 — Combat readability feedback

- Projectiles visibly connect between replay frames; event-timed health and impact feedback.
- Persistent full-field Frozen Field, affected-army status and pixel match heart meters.
- Articulated anticipation/strike/recovery poses, bow draw/release and distinct melee/magic action effects.

## v0.8.0 — Slime Court (explicitly requested expansion)

- Slime Princess with Royal Jelly and a death-spawn attack theme bonus.
- Four Slime cards with the user-specified recruit/cap values: Giant 1/4, Cannon 2/4, Ball 2/6, Barrel 2/6.
- Generic one-generation death splitting, once-only revival, refreshing small-area speed slows and ten-second damaging death areas.
- Original pink/green/white pixel artwork, matching battle motion/VFX and five SFX, roster UI/tooltips, focused mechanics/presentation tests and native captures.

## v0.8.1 — Tactical formation feedback

- Shared deterministic formation AI for both revealed battle rosters.
- Spaced multiple ranks, frontline screening, melee wings, central healer coverage and range-aware backline placement.
- Enemy area/melee pressure, input-order invariance, mirrored policy, collision/bounds regressions and seven native formation views.

## v0.8.2 — Commander title-menu feedback

- Full-body Commander showcase replaces army-unit camp decorations.
- Looping pixel-filtered idle poses and elemental particles for every displayed Commander, with reduced motion and modal pause.
- Animation-phase and still-pose native visual review; menu navigation remains unchanged.

## v0.8.3 — Campfire menu references

- Centered title and selection buttons over an original night-forest pixel scene.
- Separate seated Commander artwork, including pink Slime Princess, with idle/fire/sky animation.
- Reduced motion, modal pause, native phase review and exported texture coverage.

## v0.8.4 — Slime Ball feedback

- Requested 30% damage absorption and repeating ten-second stored-damage bursts with medium enemy-only radius/pushback.
- Doubled death discharge, fresh revival/reset state, white charge/burst feedback, focused mechanics/replay coverage and native review.

## v0.9.0 — Personal Commander mastery (approved)

- Per-Commander whole-match records, wins/losses/forfeits, win rate and permanent XP levels.
- Win +100 XP, completed loss +25 XP, forfeit +0 XP; 250 XP per level, without combat advantages.
- Local profile/backup, interrupted-game recovery, idempotent match rewards and isolated automated profiles.
- Gallery mastery/card badges, completed-match XP/level-up feedback, reduced motion, forfeit/save guidance and native review.

## Private 1v1 PvP — Approved development milestone

- First checkpoint: server-authoritative two-seat room service, hidden simultaneous drafting, selection deadlines, immutable shared replays and reconnect credentials.
- Browser-compatible WebSocket transport and a two-client full-match integration harness; retain PvAI/local mastery behavior.
- User approved free hosting, shared 1× playback and sixty-second disconnect forfeits. Server timeline, player-facing room/draft/replay/reconnect/result flow and guest viewpoint adapter are implemented.
- Free-only Render/Docker package, bounded cold-start retry and native/browser/export/container checks. Pending before public launch: confirmed Render connection, zero-charge workspace settings, service deployment and live browser-to-WSS acceptance.
- Later separate milestones: account-backed PvP records, cloud mastery, matchmaking and competitive ranking. No local PvAI results enter trusted competitive ratings.

## Further major phase — Game Director scope decision

The elemental PvAI vertical slice, requested Slime Court roster expansion and personal Commander mastery are implemented. Private friend-room PvP development is approved above. Campaign/run progression, account-backed competitive rankings and VTuber/mascot roster integration still need explicit direction. Human playtesting should inform further balance values; current tuning remains provisional.
