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
- Free-only Render/Docker package, bounded cold-start retry and native/browser/export/container checks. Free Singapore service is deployed on a Hobby workspace with no card; two-browser public WSS acceptance passed. The verified endpoint is configured for the v0.10.1 release.
- Later separate milestones: account-backed PvP records, cloud mastery, matchmaking and competitive ranking. No local PvAI results enter trusted competitive ratings.

## v0.11.0 — Achievements and mastery unit rewards

- Friend PvP is paused behind Coming Soon while the private-room foundation is retained.
- Eighteen local achievements with progress, permanent earned status and Commander filters.
- One new reward unit per theme at Level 3 and three wins; retain all sixteen starter cards and existing XP rules.
- Original pixel reward artwork, locked collection previews, result feedback and an Achievements & Rewards journal.
- Version-1 save migration/backfill, permanent entitlements and headless equipment/preset validation; equal available PvAI collection.

## v0.12.0 — Requested fantasy pixel presentation

- Consistent lodge/woodland materials, rounded carved cards, arched portraits and original detailed environment art throughout the existing game.
- Shared pixel display headings, readable small text, brass/control details, illustrated blessing offers and achievement medals.
- Balanced four-Commander gallery, equipped-card rack, forest battle arena and matching roster plaques.
- Source/export skin integration guards, all five blessing layouts/focus, and six additional native views alongside existing browser/container and deployment verification.
- Campaign/story remains KIV. PvP stays Coming Soon. Gameplay, unlocks, accessibility preferences and free hosting remain unchanged.

## Further major phase — Game Director scope decision

The elemental PvAI vertical slice, requested Slime Court roster expansion and personal Commander mastery are implemented. Private friend-room PvP development is approved above. Campaign/run progression is explicitly KIV/on hold. Account-backed competitive rankings and VTuber/mascot roster integration still need explicit direction. Human playtesting should inform further balance values; current tuning remains provisional.


## v0.13 — Backline specialists

Unlimited power picks and clear playable ground; four 2/4 units with backline travel, path damage/pushback, temporary crack obstacles and linked damage. Source simulation, replay/native views, exported-pack, browser/container and release verification gate this milestone. Exact numeric ability values remain playtest tuning.


## v0.14 — Mastery lineup and developer collection access

- Four starters and two rewards per Commander: Level 3 + three wins, Level 5 + six wins.
- Spore Sage joins the starting Earth army at recruit 2/cap 4.
- Versioned migration retains existing ownership/records/presets without granting old collections to new profiles.
- Private device-local developer key enables all units without forging progression; public collection stays gated.
- No accounts, campaign, PvP availability, paid hosting or unrelated balance changes.

## v0.15 — Battle feedback and learning

- Completed-battle reports for both armies with independent damage/healing/protection highlights, effective HP accounting, body survival and descendant/Commander attribution.
- Click/tap inspection beside the arena, showing only the current replay's stats, cooldowns and effects.
- Optional guided normal first match, replayable from How to play, with safe local pause/exit/restart and isolated completion preference.
- Stronger attack settling, content-driven collapse/wilt/dissolve/pop deaths, four original cues and reserved important-ability audio capacity; preserve contact timing and reduced motion.
- No balance audit, progress export/import or training grounds. Campaign remains KIV; PvP stays Coming Soon and hosting stays free.


## v0.17 — Approved P0/P1 player experience

- Resumable local adventures with exact draft/RNG/clock/heart/skill state and idempotent final settlement.
- Effective power previews, seeded public-information AI styles and decision-based difficulty.
- Default-off one-redraw-per-round experiment for both sides; local pacing evidence with existing overtime unchanged.
- Factual battle recaps, optional suggestions, larger text, effects intensity, compact scrolling and a direct optional guide entry.
- Actual browser restart/persistence acceptance, recovery/agency/accessibility regressions and twelve dedicated native views.
- Campaign KIV, PvP Coming Soon, no P2/P3 expansion or paid infrastructure.


## v0.18 — Approved strategy and learning P0/P1

- Explain equipped warband interactions, ability keywords and the existing full-theme tradeoff.
- Default-off commander-path prototype with eight content-defined ability branches, normal-pick legality, equal AI rules and exact recovery/public visibility.
- Extend local pacing context and run a bounded starter-only themed/hybrid diagnostic; publish synthetic findings and human acceptance procedure. A repeated Water-hybrid Sudden Death timeout case needs an overtime product decision.
- Verify compact/larger-text guidance and actual browser path purchase/reload through the ordinary Continue action. P2/P3 stays deferred.


## v0.19 — Approved Sudden Death growth

- Each Sudden Death battle has a 180-second ceiling; normal battles remain 120 seconds.
- Double the percentage only for newly picked Sudden Death powers. Preserve earlier strengths and enhanced subsets across repeated rounds, with shared combat/preview/AI math and the existing speed caps.
- Recover mixed cohorts, exact RNG and hidden rival powers; keep old v0.18 scored replays at their original limit and apply the new rule to subsequent rounds.
- Add enhanced-card browser purchase/reload/Continue acceptance, two focused suites and seven native views including compact/larger-text bounds and full-field frost after 2:00.
- The bounded known Water hybrid comparison finishes Round 15 after seven Sudden Death draws. Long repeated draws remain possible; human pacing evidence is still needed before any further stall-resolution mechanic. Campaign/PvP deferrals and free hosting remain.
