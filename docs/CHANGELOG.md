# Changelog

## v0.10.0 — Private friend playtest (hosting pending)

- Free-only Render blueprint and checksum-pinned, unprivileged Godot server image, initially limited to one room. No database, disk, paid add-ons or automatic redeploys.
- CI builds/tests the container under a 512 MiB limit and exercises the exported WebGL2 game in two isolated browser sessions, including shared opening/time, guest mirroring, result agreement and unchanged mastery.

- User-selected shared 1× clock: wait for both replay downloads, schedule one start, finish Commander openings/contact tails before scoring, and reject early continue/duplicate readiness.
- Friend-room create/join/code-copy/wait, live hidden drafting, shared battle/result and reconnect/forfeit screens, using the existing pixel portraits, cards, heart meters, attack/VFX and audio. Guest presentation mirrors all ownership/entity/position references to keep the local army on the left.
- In-memory session/cold-start retries, server-clock countdowns, online menu guidance and ten native friend-playtest captures. Entry appears only for a configured endpoint; free hosting is not yet provisioned.
- Sixty-second reserved reconnect grace and authoritative forfeits, with chronological ordering against final battles and no PvAI/mastery writes. Protocol v2 adds clock synchronization/readiness; standalone server polling is capped at 30 FPS.

- Isolated server-authoritative two-player rooms reusing existing draft, skill, combat, heart/comeback and Sudden Death rules.
- Hidden current picks, per-seat input revisions, absolute selection deadlines, validated server-owned content and exact-once battle scoring.
- Browser-compatible WebSocket client/server, cryptographic room/session credentials, reconnect, protocol/content checks, resource limits and compressed identical replays. Simulations run on independent workers.
- Focused authority and real loopback two-client full-match regressions. Friend entry is conditional on a verified server endpoint; accounts/ranking remain outside this playtest. No changes to personal PvAI records.

## v0.9.0 — Commander mastery

- Personal per-Commander PvAI match records, wins/losses/forfeits, win rate and permanent mastery.
- Full-match win +100 XP, completed loss +25 XP, forfeit +0 XP; 250 XP per level. Mastery grants no combat stats.
- Versioned local profile/backup, exact-once rewards, interrupted-match forfeits and visible save/load failure handling. Automated scripts use isolated profiles.
- Gallery mastery panels/card levels, final-match XP progress/level-up animation, reduced motion and explicit forfeit guidance.
- Focused profile/lifecycle/UI/export regressions and eight native mastery views (89 desktop captures total).

## v0.8.4 — Slime Ball: Jelly Burst

- Slime Ball absorbs/stores 30% of incoming post-defense damage while retaining regular melee attacks.
- Every ten seconds, release the stored amount in a medium enemy-only radius with outward pushback and reset; a lethal hit releases double the remaining charge.
- Exact fractional storage, shared damage/death-chain handling, empty-cycle behavior and fresh revival/round timers. Stored damage is not reduced by DEF twice or multiplied by ATK bonuses.
- White charge meter/countdown, timed white bursts, contact pushback and Slime burst SFX; formation AI recognizes the new area threat.
- Focused mechanics/replay regressions and native charged/burst/pushback/death/reduced-motion captures.

## v0.8.3 — Centered campfire title scene

- Center the title and Play/help/settings controls over a calm moonlit pixel forest clearing.
- Original seated Fire, Water, Earth and pink Slime Princess artwork replaces the standing gallery arrangement, with poses inspired by the supplied campfire references.
- Animate six separately illustrated pixel flame frames, embers, stars and Commander idle layers; keep reduced motion and modal pause.
- Add native menu art validation and exported texture/gutter coverage. Existing menu phase captures review the new composition.
- Detach stopped audio streams before engine shutdown to release the menu music decoder reliably while preserving cached playback restart.

## v0.8.2 — Animated Commander title menu

- Replace the title camp army units with a larger full-body showcase of Fire, Water, Earth and Slime Princess.
- Reuse the existing detailed pixel portraits with bounded cached idle meshes, breathing/sway, drifting cloth/hair, a gentle Princess bob and elemental embers, ice, leaves and bubbles.
- Respect reduced motion with stable poses and still effects; local modals pause the animation. Play/help/settings keep their existing flow.
- Add two animation-phase captures and a reduced-motion view to native CI review (76 desktop views total).

## v0.8.1 — Strategic automatic formations

- Both armies now use a deterministic role/ability-aware tactical planner after draft reveal instead of placing each unit type in successive sections of one vertical column.
- Spaced multi-rank deployment, Tank screens, melee wings, range-aware caster placement and central healer coverage, with wider spacing against recruited area-damage threats.
- Stable placement independent of loadout card order, mirrored team rules, collision/bounds checks and recorded formation metadata. Free movement, targeting, skills, stats and recruitment remain unchanged.
- Focused formation tests cover crowded Water, mixed/role-deficient/single/empty armies, future generic abilities, enemy pressure, custom field bounds and simulator/replay determinism.
- Seven native formation captures cover the reported Water/mixed matchup before skills, at battle start and during engagement, all themes and ranged-only support protection; CI now records 73 views.
## v0.8.0 — Slime Princess

- Added the Slime Court: Giant Slime 1/4, Slime Cannon 2/4, Slime Ball 2/6 and Slime Barrel 2/6.
- Generic once-only death splits, Royal Jelly revival, +100% attack for qualifying death-created allies, refreshing area slows and ten-second enemy-only death pools.
- Focused mechanics coverage for both teams, round reset, simultaneous pre-battle effects, speed recovery, pool duration/entry/exit and deterministic replay output.
- Pink Slime Princess, green Giant/Cannon, white Slime Ball and pink Barrel artwork; colour-matched slime shots, splashes, pools and Royal Jelly opening/revival effects.
- Slime squash/bounce, Cannon recoil, Barrel motion, smaller split bodies and five original slime SFX. Event-timed births and pool expiry remain read-only replay presentation.
- Expanded gallery/warband/draft/export coverage and eleven Slime-specific native captures. Triggered bonuses and unit abilities have accurate readable descriptions.

## v0.7.7 — Cleaner battlefield

- Removed ALLY/RIVAL word badges from summoned units and effect-name text tags from the battlefield.
- Pre-battle skill names now appear in the existing status line below the arena. Team colours, pennants, health UI, animations and full-round frost remain visual.

## v0.7.6 — Summon allegiance

- Revalidate enemy ownership for locked targets, attack release, projectile collision and damage application. Allied or invalid targets are rejected, including malformed in-flight seed locks.
- Summoned plants retain the caster’s team regardless of which half they occupy; explicit ALLY/RIVAL badges, team pennants, seed trails and summon counters make opposing Earth summons distinct.
- Regression coverage for both Earth Commanders casting together, stale allied locks, friendly damage rejection and valid enemy hits; native ownership captures.

## v0.7.5 — Combat readability

- Complete projectile flight tracks through impact, including short shots between replay frames and enemy interceptions.
- Shared character/contact anchors, a short visible contact hold and event-timed health/death feedback; a final-hit tail lets killing blows finish before results.
- Pitcher Plant bites land after the visual drag, including lethal pulls that keep the victim visible until contact.
- Full-field ice, frost crystals, affected-unit markers and a persistent Frozen Field status throughout the round.
- Shared pixel heart meters during draft, combat and results, with result-time loss reveals and Sudden Death support.
- Articulated character meshes for ten roster rigs; visible wind-up, strike and recovery timed to attacks, bow draw/release, magic charging, claw arcs, slams, bites and hit recoil.
- Contact/heart/frost/attack regression coverage and native captures of approach/hit/aftermath and all five attack styles.

## v0.7.4 — Battle presentation

- Each battle starts at 1×; removed result skipping.
- Separate pre-battle Commander skill playback holds armies and the battle clock until both selected skills finish.
- Before/after skill snapshots, pause/clock tests and normal result-completion coverage.
- Pitcher Plant vines extend, grab, drag and retract using authoritative before/after pull positions.
- Content-driven arrows, fireballs, dragon flames, water orbs, ice shards and seed shots with interpolated motion and distinct impact effects.
- Attack anticipation/lunge/recovery and sprouting Commander plants; richer meteor and freezing openings.
- Seventeen new original physical/magic SFX, per-cue throttling and twelve effect voices so different simultaneous actions remain audible.
- Presentation/profile/audio validation and native captures covering all three openings, six projectile styles and three vine phases.

## v0.7.3 — Detailed pixel fantasy artwork

- Three distinct original Commander designs: fire battlemage, tide spellcaster and forest warden, at 128×192 native pixels.
- Thirteen original 64×64 roster sprites with richer silhouettes, layered materials and transparent gutters, shared across cards, battle actors, roster summaries and camp scenery.
- Rounded pixel-edged cards and panels, darker nameplates, gold selection borders, hover feedback and refined navigation/scrollbar styling.
- Taller Commander gallery cards, framed portrait backdrops and adjusted battlefield health-bar spacing.
- Cached data-driven atlas regions, documented art provenance/prompts and exported-frame transparency/coverage checks. Rules, stats and saved presets are unchanged.

## v0.7.2 — Portrait cards and saved warbands

- Reference-based Commander gallery, full-body view and separate description, passive and active panels.
- Shared portrait cards across selection and unit drafting, with element, recruit/cap and class badges; three original 32×48 Commander portraits.
- Four equipped slots above an eight-column collection, element filtering and click-to-add/remove selection.
- Three validated local warband presets per Commander, safe empty-slot loading and non-destructive Clear.
- Commander flavor metadata, art/export coverage and preset/layout regression checks.

## v0.7.1 — Player experience

- Forest-camp title menu, original pixel scenery and a warmer forest/brass interface.
- Player guide, shared pause/settings menus, confirmed match exit and active-time draft clocks.
- Prefilled starter warbands, companion collection filtering, readable card hierarchy and advanced seed controls.
- Two original music loops, nine original sound effects, first-interaction audio activation and saved device preferences.
- Clearer battle/result language, heart feedback and a focused battle control bar.
- Navigation, modal layout, pause/exit safety, preference persistence and exported audio regression checks; ten CI screenshots.

## Development workflow — Resumable checkpoints

- Added a repository handoff and small-checkpoint instructions so interrupted AI work can resume from saved branches and check results.
- Removed duplicate standalone validation on main; Deploy Web still requires the reusable CI gate.
- Cancel superseded validation runs and bound validation, build and deployment durations to avoid indefinitely stalled jobs.

## v0.7 — Pixel presentation, accessibility and playtest baseline

- Original replaceable pixel catalog for all twelve starter units and Commander plants, shared by cards and the battlefield.
- Eight-direction movement poses, four-direction attacks, neutral idle/death, interpolation, aura/area/projectile/skill effects and burn/HP feedback.
- Optional synthesized battle tones, pause, speed shortcuts, reduced motion and HP-number controls.
- Quick themed loadouts, optional match seed and compact complete rival summaries.
- Fixed projectile interception with swept enemy collision, allied pass-through and locked-target fizzle/commitment.
- Improved generic AI valuation of first healing support; adjusted Ice Giant/Sea Serpent ATK and Giant Tree healing for the provisional baseline.
- Automated validation over 108 final-sample matches/652 battles, max-cap roster stress and visual captures.
- Deployment depends on validation, tests the actual exported PCK, excludes generated output and publishes source identity.
- Post-deployment CI verifies the served commit and game-pack SHA-256, then runs all suites from the downloaded Pages payload.
- Reusable local/deployed validation tools and an evidence-based playtest report.


## v0.6 — Complete elemental PvAI matches

- Multi-round match state, four-loss condition, comeback selections and repeated Sudden Death.
- Persistent drafted armies, Buff stacks and skill budgets with fresh battle state each round.
- Seeded replayable full matches for all three themes and mixed-element armies.
- Round/result navigation, loss counters, prepared-skill status and fantasy UI theme.
- Fixed combat event-log scene path and overflowing selection/result layouts.
- Headless match-rule, full-match and 1280×720 scene-flow regression tests.


## v0.5 — Seeded AI and battlefield art

- Independent legal AI Commander/loadout selection, role-aware draft policy and skill conservation.
- Opponent information snapshots conceal current selections until combat.
- Original element-colored pixel silhouettes, side markers, HP bars and meadow tiles.
- Explicit JSON inclusion in Web exports.
- Regression coverage over 50 seeds and 700 AI draft phases.

## v0.4 — Deterministic combat

### Added
- v0.4 deterministic fixed-timestep `CombatSimulator`.
- Battle events and periodic replay frames separated from presentation.
- Left-vs-right automatic formations with tank, melee and backline placement.
- Target locking, tank targeting priority, ranged kiting, collision-aware movement and retargeting.
- Normal attack, projectile, DEF, healing, DoT, aura, push/pull and empowered-hit simulation.
- Fire, Water and Earth Commander active-skill resolution immediately before combat.
- Starter unit ability execution driven by generic JSON ability `type` values.
- Battle 1 placeholder replay screen with speed controls, event feed, HP bars and skip-to-result.
- Deterministic training opponent for the v0.4 combat harness.
- Combat simulator regression/determinism tests.
- Simulation/battlefield playtest parameters in `game_balance.json`.

### Changed
- `ContentDatabase` now loads the global balance definition.
- Commander active-skill data now declares a generic `type` consumed by combat systems.
- The opening Draft screen now leads into the v0.4 Battle 1 preview after all selections are spent.
- CI now runs headless Combat Simulator tests.

### Previous
- v0.3 seeded Draft System, starter roster and finalized rules.
- v0.2 four-slot Army Builder and shared `GameState`.
- v0.1 data-driven Commander selection.
- v0.0 project foundation, validation, CI and GitHub Pages deployment.
