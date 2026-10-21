# Architecture

## Core principle

VCommander separates **content data**, **game simulation**, and **presentation**.

```text
Presentation / UI / animation
          ↓ reads events/state
Game systems / simulation
          ↓ reads definitions
Content data
```

Presentation must never be the authoritative source of draft legality, combat outcomes or game rules.

## Layers

### Data — `data/`

Contains Commander, Army card, Buff, set/theme and balance definitions. Content IDs are stable identifiers and do not depend on display names.

### Core systems — `scripts/`

Generic logic such as content loading, set checking, Army loadout state, drafting, seeded combat simulation, match state and AI.

### Presentation — `scenes/`, `ui/`, `assets/`

Godot scenes, controls, effects, animation and audio. Presentation reacts to game state and battle events.

## Current/planned modules

```text
scripts/
  core/
    content_database.gd
    game_state.gd
    match_state.gd
    save_manager.gd        (future)
  army/
    army_loadout.gd
  commanders/
    set_bonus_checker.gd
    commander_system.gd    (future)
  draft/
    draft_system.gd
    draft_screen.gd
  combat/
    battle_event.gd
    combat_simulator.gd
    battlefield_view.gd
    combat_screen.gd
  ai/
    ai_controller.gd
```

`GameState` owns the selected Commander, four-slot unique `ArmyLoadout`, match seed, current `DraftSystem`, seeded AI opponent, immutable public opponent snapshot, and latest combat result.

`DraftSystem` owns draft legality and progression: selection points, unit counts, Buff stacks, Commander skill-use limits, seeded offer generation and auto-selection. The draft UI only displays and invokes this state.

`CombatSimulator` is a headless fixed-timestep simulation. It receives plain side configurations plus a seed and balance definition, then returns a deterministic result containing battle events and replay frames. It does not depend on Godot scene nodes, sprite animation or combat UI.

`BattlefieldView` and `combat_screen.gd` consume simulator output only. The presentation cannot change targeting, damage or battle outcomes.

Commander theme completion is calculated from equipped card definitions and their `set_id`. It is not hardcoded to four permanently named card IDs.

## Determinism requirement

All randomized gameplay systems accept/store an explicit match seed. A match should be reproducible from the same game state, content version and seed.

v0.4 combat uses a fixed simulation timestep and seeded ordering/spawn randomness. CI checks that the same battle input and seed produce the same winner, duration and event fingerprint.

## Combat/presentation boundary

Combat emits plain dictionaries for events such as:

- `spawn`
- `commander_skill`
- `ability`
- `attack`
- `damage`
- `heal`
- `defeat`
- `battle_end`

The simulator also emits periodic position/HP frames for the temporary combat replay. Visual scenes consume these outputs; animations never decide damage.

## Match lifecycle

`MatchState` is a headless rules/state machine: draft → battle → result → next draft, or complete. It owns round-loss counts, comeback allowances, Sudden Death and small battle-history summaries. Battle resolution is guarded so revisiting a replay cannot charge a second loss. Both fourth losses in a draw trigger repeated three-selection Sudden Death rounds until an outright winner.

`GameState` assembles fresh combat inputs from the persistent player/AI drafts, uses a separate deterministic seed per round, and scores the simulator result immediately. Replay timing and animation never alter outcomes. The UI advances to the next draft only after replay completion. All accumulated units are respawned by each new simulator instance; temporary combat statuses and summoned plants do not enter persistent draft counts.

## AI information boundary

`AiController` owns a separate seeded `DraftSystem`, Commander and unique four-card loadout. Its generic policy scores legal offered units by summon gain, stats and role coverage, and army-wide Buffs by marginal value. Commander skills are conserved for later or critical rounds. Setup and tie-breaks accept an explicit seed.

At the start of drafting, `GameState` captures a deep public opponent snapshot before the AI spends points. The AI receives only the player's previous-round public composition. Neither side can inspect the other's current picks. The completed opponent draft is revealed only when combat begins. Presentation-only pixel silhouettes live in `scripts/presentation/` and consume replay metadata.

`FormationPlanner` is a deterministic, headless tactical heuristic called by `CombatSimulator` after draft reveal, using both completed battle rosters. It has no access to draft choices while they are hidden and does not change the draft AI. It assigns legal rank slots by generic roles, attack/pull reach, durability, healing coverage, frontline screening and enemy area/melee pressure. The planner uses no card/Commander/element-specific behavior and runs a bounded slot-scoring pass rather than simulating candidate battles. Canonical content ID/index ordering is only a tie-break and keeps card order from assigning units to top/bottom blocks. Both armies use mirrored geometry and the same policy. The result records placement metadata for review; UI never calculates deployment.

## Multiplayer future-proofing

The first target is local player vs AI. The user has now approved a private 1v1 room milestone (ADR-012). Its isolated authority lives in `scripts/network/`; it does not replace GameState. The private friend playtest uses the verified public Render WSS endpoint. See `docs/PRIVATE_PVP.md` for the protocol, runnable server, approved playtest policies and deployment gate.

`PrivateMatch` owns two independent DraftSystems, a MatchState and deep-copied public snapshots. Each seat's revision plus the round number rejects stale/retried input. Absolute monotonic selection deadlines catch up bounded missed picks; client clocks, menus and timestamps cannot alter them. Combat inputs are assembled from the server's content; each draft has an independent seeded random stream and future seeds are never sent with hidden picks.

`PrivateRoomService` owns capacity, cryptographic invitation codes, per-seat 256-bit bearer credentials, reserved reconnect seats and filtered projections. A code permits joining an empty guest seat; it cannot recover an occupied/disconnected seat. Credentials are sent only to their owner and kept in client memory, never URLs/logs. No CommanderProgress service is read or written. Development idle/lifetime expiry discards a room without a win/loss or XP reward.

`PrivateRoomServer` polls bounded WebSocket connections/commands and launches isolated Thread jobs for pending battles. Workers receive copied inputs and their own CombatSimulator; they never access rooms or the scene tree. The poll loop alone accepts completed jobs and caches a size-bounded gzip JSON replay; scoring waits for the shared presentation deadline. Both seats receive that identical canonical replay. State messages contain no opposing current draft, RNG state or credentials. `PrivateRoomClient` is a browser-compatible intent/state transport with explicit reconnect and WSS validation; it continues polling through local menus. Player-facing integration and shared playback are implemented below; account-backed ranking remains separate.

ADR-013/R095–R097 supersede the development acknowledgment seam with shared 1× playback and sixty-second disconnect forfeits. Protocol v2 adds download readiness and clock samples. SharedBattleClock covers the existing Commander opening, combat and contact tail; authority scores once at the scheduled end. Chronological deadline ordering preserves earlier final results even after a stalled poll. No shared rating/profile writes are introduced.

`OnlineSession` keeps the connection, reconnect credential and replay in memory across presentation screens. It handles bounded cold-start retries, download/readiness and safe intent acknowledgments. `private_room_screen.gd` renders create/join/wait/draft/reconnect/forfeit states and uses the ordinary Commander/card artwork. The Army Builder exposes friend entry only for a configured endpoint. The endpoint is a project setting, development argument or explicit Web query override; it is never a credential.

The existing combat scene accepts an optional read-only PrivateBattleContext and SharedBattlePresentation driver. PvAI retains its normal GameState source and local controls. The driver consumes estimated server time, preserves monotonic visual progress, removes local pause/speed inputs and delegates all scoring to the authority. It reuses the packed scene's original script so owned controls are constructed once. PrivatePerspective mirrors guest coordinates, side IDs, owner maps and entity references consistently so each player sees their own army on the left. Online menus keep processing/rendering the shared timeline and explain that the match continues.

## v0.7 presentation and verification

`assets/pixel/roster.json` stores replaceable 16×16 silhouettes and elemental palettes. `PixelUnitArt` consumes content IDs only to choose artwork; role/element fallbacks support new content. It supplies neutral idle/death poses, eight-direction procedural movement and four-direction attack facing. Card portraits and battlefield actors use the same catalog.

`BattlefieldView` interpolates simulator frames and consumes combat events. Projectiles, auras, area effects, burn indicators, HP, hit feedback and skill effects read simulation metadata. The field preserves its world aspect ratio and stays fully visible. Reduced motion, HP numbers, pause, playback speed and optional synthesized sound are presentation settings and never write simulation state. `BattleAudio` throttles combat cues and delegates playback to the shared `GameAudio` presentation autoload.

Projectiles advance through fixed simulation steps with swept collision against enemies, passing through allies. The original locked target remains the commitment/fizzle condition; the earliest enemy along the path can intercept. Position snapshots make the projectile visible without giving presentation authority over hit resolution.

`tools/run_checks.py` discovers all headless test suites and treats logged Godot errors as failures. `tools/capture_ui.gd` renders thirteen desktop views in CI, including title animation phases and reduced motion. Deployment depends on successful validation, tests the exported PCK, and writes a public commit/version manifest. `tools/verify_deployment.py` checks the served manifest, loader, JavaScript, WebAssembly and game pack, checks the exported game-pack SHA-256, then runs the downloaded pack's tests in a post-deployment CI job. Generated build and QA directories are ignored by Godot and excluded from Web exports.

## Player menus and audio

`GameMenu` is a presentation-only CanvasLayer that pauses local scene processing for help/settings/pause modals, restores the previous pause state on close, and confirms before discarding an active match. `GameAudio` owns two original looping scores, pooled effects and a local ConfigFile for volume/accessibility. Playback unlocks on player interaction. `ScreenStyle` supplies shared scenery, navigation and card hierarchy. These services never decide draft legality or battle results.

## Reference card interface and warband presets

`CardTile` and `CardPortrait` render content-defined card identity, recruit/cap and class badges. `CommanderArt` serves detailed atlas portraits shared by gallery cards and the full view, retaining the replaceable 32×48 palette catalog as a fallback. Commander descriptions are presentation metadata; theme and skill effects still read the existing definitions.

`WarbandPresets` receives a content source, validates complete unique loadouts with `ArmyLoadout`, and stores three ConfigFile slots under each Commander ID. Unknown/duplicate/stale entries are rejected before the UI invokes normal `GameState` equip methods. Clear affects only the current selection. Preset storage never participates in match scoring or combat.

## Detailed pixel artwork

`PixelAtlasArt` maps presentation IDs to cached `AtlasTexture` regions using `assets/pixel/art_manifest.json`. The original generated artwork is packed with nearest-neighbor sampling into 128×192 Commander and 64×64 unit cells, with transparent gutters and a common unit foot baseline. The same unit frames feed cards, roster summaries and battlefield rendering. The earlier editable palette catalogs remain safe fallbacks for unmapped content.

The detailed battlefield renderer preserves directional lean, four-step movement, attack facing, hit feedback and death fade as procedural presentation. These are not separately hand-drawn animation frames and never decide hit timing or outcomes. See `assets/pixel/CREDITS.md` for provenance and prompts and `tools/pack_pixel_art.py` for the reviewed crop/packing recipe.

## Pre-battle skill presentation

`CombatSimulator` records the before/after snapshots and event range around its existing simultaneous pre-battle skill resolution. `BattlePrelude` schedules those read-only events on a separate presentation clock. The combat scene keeps replay time at zero until that sequence finishes, then begins the existing battle frames at 1×. Pausing also holds the opening sequence. Animation never re-runs effects or changes scored outcomes. Results appear only after normal playback completes; there is no result-skip control.

## Combat cues and visual effects

`CombatCues` reads role-appropriate projectile, motion and sound assignments from `data/presentation/combat_cues.json`. `BattleEffects` draws pixel arrows, flames, water/ice/seed shots, impact particles and the two-strand leafy vine. Pull animation consumes recorded before/after endpoints and temporarily overrides only displayed positions/HP; it settles at the current authoritative frame. Attack anticipation, strikes and recovery remain cosmetic.

`BattleAudio` maps events to distinct cues with independent real-time cooldowns and a burst budget. Commander cues retain priority; the shared twelve-voice audio pool favors idle voices. The seventeen additional original effects are reproducible from `tools/compose_battle_sfx.py`. CI validates profiles/WAV integrity, all suites and dedicated native opening/projectile/vine captures.

## Contact reconstruction

`BattleReplay` indexes immutable launch, terminal, health and attack events alongside snapshots. It interpolates each shot through its recorded impact on the enemy actually hit, including shots whose complete lifetime falls between snapshots. The renderer shares its animated body anchor with projectile contact and hit effects; a brief contact hold keeps fast hits readable. Exact recorded health changes and deaths appear at event time, rather than waiting for the next frame. None of these tracks writes simulator or match state.

`UnitAttackMotion` reads scheduled attacks for anticipation before release, a strike at the recorded attack time, and recovery. Small cached continuous meshes articulate the existing nearest-filtered character textures according to data-driven rigs. Weapon/spell strokes and recoil share the body anchor; reduced motion uses compact poses. Healing casts also use this track. These are procedural poses, not separately drawn sprite frames.

`MatchHearts` shows both loss counters during drafting and battle. Combat displays the counters from before the current scored round until playback completes, including hiding a newly-triggered Sudden Death result. Persistent frost reads the selected round skill and covers the full arena, independently of transient opening effects; only affected units receive status markers. A new battle scene/configuration resets it.

A short presentation tail after the simulation duration lets final impacts/deaths finish before result cleanup. Pull-then-bite cues can extend that tail; a lethally pulled actor is retained visually until the delayed bite, without resurrecting it in simulation. Damage flashes, corpse location and contact use the same displayed endpoint.

## Summon allegiance

Enemy ownership is checked when retaining a target lock, releasing an attack, advancing projectiles, queueing damage and applying damage. Projectile collision uses the firing side’s opposing team rather than trusting the locked target’s team. A dead shooter’s committed projectile can still hit a valid enemy. Summons keep their caster’s side when placed in the enemy half. Snapshot/spawn metadata marks summoned units so presentation can show team-coloured pennants, counters and seed trails without inferring ownership from position.

Battlefield effect names and unit ownership word badges are omitted to reduce visual clutter. Pre-battle skill names appear in the combat scene’s existing status line outside the arena; the battlefield keeps the actual visual effects and colour markers.

## Slime Court runtime extensions

Content-driven `death_split`, `death_damage_area` and `army_revival` behaviors extend the existing death-resolution and pre-battle paths. Death-created units receive unique IDs, inherit their source's owner and already-modified stats, and apply a triggered set multiplier only to the new body. Split consumption and revival allowance are explicit per-body state. Starting-army blessing excludes temporary summons, and all spawned units remain outside persistent draft counts. No Commander/card IDs select these mechanics.

Temporary speed debuffs store duration and percentages independently of base ratings. Refreshing a splash does not compound it; effective speeds combine the strongest temporary slow with existing round modifiers and aura behavior. Damaging areas share the existing area-effect clock, retain source ownership after death and check enemy presence/radius each pulse. Death abilities and revival finish before elimination is checked.

Birth events include presentation snapshots so `BattleReplay` can display new bodies between periodic frames. Death-area events include a copied area so visible pools begin and expire at their recorded times. New Slime mesh rigs, green shots, white/pink impacts, pink pool/opening/revival effects and original sound cues consume metadata only. Lower-opacity overlapping pools preserve actor readability. Artwork/palette mappings remain separate from gameplay and retain previous atlas pixels.

## Title Commander campfire scene

`commander_showcase.gd` loads the current Commander definitions and seated menu atlas, and draws a separate moonlit background below the title controls. Menu portraits and scenery are declared in `art_manifest.json` and packed by `tools/pack_menu_art.py`; the existing gallery and battlefield artwork is unchanged. The title and selection buttons share the screen center line. Seated figures occupy the lower clearing around a cosmetic fire without taking over selection or combat.

A bounded 32-pose mesh cache supplies gentle idle movement while keeping logs and feet planted. Six separately illustrated flame frames, embers, stars and elemental particles share the presentation clock and nearest-neighbor sampling. Reduced motion uses still poses/effects; normal scene pause holds the clock. This illustration creates no army/combat actors, does not select a Commander and does not write game state. Source art/packing validation and exported-pack coverage check the new textures.

## Stored-damage bursts

The generic `absorb_burst` ability intercepts post-defense damage in the shared ordinary/chained damage application helper. Fractional prevention accumulates on the current body. Periodic discharges run after damage/death resolution so lethal deadline hits own a single doubled death burst. Death discharges participate in the existing bounded-by-bodies death chain; revival clears charge and schedules a fresh body timer. Stored damage bypasses a second DEF/ATK calculation. The formation heuristic recognizes this generic area/contact behavior.

Replay indexes charge transitions and pushback endpoints alongside health. The field shows a white charge bar/countdown rim and a medium-radius white pixel burst with the existing Slime burst cue. Reduced motion keeps compact static cues and immediate pushback endpoints. Presentation never determines damage, timing, targets or displacement.

## Commander mastery and records

`CommanderProgress` is a headless stable-ID profile service owned by GameState. Progression rules load through ContentDatabase from their own data group. Versioned local records are written using a temporary file/rename and a current backup; corruption recovery preserves unreadable files rather than silently resetting them. The service validates counters, protects its internal dictionaries, derives level/win rate, tracks one monotonic pending match and makes settlement idempotent. Interrupted stored matches recover as zero-XP forfeit losses.

GameState begins profile tracking at the first battle, settles only authoritative complete-match outcomes, and treats resets of an unfinished played match as forfeits for its original Commander. Combat simulation inputs/results and seeds do not read mastery. A copied before/after receipt supplies result presentation. Automated script runs use in-memory profiles; focused persistence tests explicitly supply isolated paths. See ADR-011 and R092–R094.

## Achievement journal and collection entitlements

CommanderProgress extends its existing atomic profile to schema 2, retaining earned achievement/card IDs and migrating version-1 records on load. Conditions and mastery requirements are content-defined; record-based backfill and settlement grant permanently once. Copied journal entries and match receipts are read-only presentation inputs. New units use the existing simulator abilities with no new combat branches.

GameState enforces equipment/start eligibility and passes the same available collection to AI setup. WarbandPresets accepts an optional eligibility service for player-facing validation, before an invalid preset can clear the current army. The collection shows all content, sends locked-card clicks to the journal and equips only earned cards. ProgressJournal provides filterable reward/achievement views, reachable from title/gallery/builder; it preserves the entry screen and current warband. The result panel displays new grants without settling again. OnlineSession's product gate prevents ordinary connection attempts independently of configured URL; explicit isolated QA enables the retained transport path.

## Lodge material presentation

`FantasyFrame` is a presentation-only `StyleBox` resource wrapping native rounded geometry with fine broken grain, inset brass and small corner ornaments. The global theme and `ScreenStyle.frame` share it, including compact/transparent progress and focus states. Its content margins preserve existing layout contracts. Settings texture icons bind when the page opens rather than during the project theme's pre-import initialization.

`PixelBackdrop` displays original lodge scenery directly with nearest sampling; it no longer renders coarse polygons through a 320×180 viewport. `CardPortrait` masks the original woodland texture to an arched vignette and reuses the unchanged Commander/unit atlas. `BuffTile` and `FantasyEmblem` display supplied definitions/stacks and delegate selections to their existing local/server caller. Pixelify Sans is used for display headings, with the existing fallback for small body text.

`BattlefieldView` maps the new decorative clearing texture onto the unchanged world arena. No scenery supplies collision, formation slots, targeting or timing. Frost still covers that complete arena, and existing attack/contact/replay code remains authoritative only in the simulator. `tools/capture_fantasy.gd` covers all four galleries, compact battlefield details and long blessing names in addition to the existing native views; bounded review previews supplement the full-resolution Actions artifact.


## Temporary battle terrain and backline effects

`CombatTerrain` is a pure geometry helper for swept capsule barriers and bounded visibility-graph routes. CombatSimulator owns temporary cracks, per-unit route caches, timed transit, path hazards and nonrecursive damage links. It expires them by the deterministic simulation clock and records ordinary replay dictionaries. Central damage application checks explicit transit immunity before all damage sources, then shares actual HP damage with an explicit recursion guard. The existing recursive guest perspective mirrors coordinates/IDs for the added state without protocol-specific exceptions. `AssassinEffects` only draws recorded state and original sprites; it never changes collision, damage or targeting.
