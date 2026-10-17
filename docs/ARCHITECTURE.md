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

## Multiplayer future-proofing

The first target is local player vs AI. Match orchestration should avoid assuming the opponent is always local AI so a future online provider can be added without rewriting draft/combat rules. No multiplayer backend is built until explicitly approved.

## v0.7 presentation and verification

`assets/pixel/roster.json` stores replaceable 16×16 silhouettes and elemental palettes. `PixelUnitArt` consumes content IDs only to choose artwork; role/element fallbacks support new content. It supplies neutral idle/death poses, eight-direction procedural movement and four-direction attack facing. Card portraits and battlefield actors use the same catalog.

`BattlefieldView` interpolates simulator frames and consumes combat events. Projectiles, auras, area effects, burn indicators, HP, hit feedback and skill effects read simulation metadata. The field preserves its world aspect ratio and stays fully visible. Reduced motion, HP numbers, pause, playback speed and optional synthesized sound are presentation settings and never write simulation state. `BattleAudio` throttles combat cues and delegates playback to the shared `GameAudio` presentation autoload.

Projectiles advance through fixed simulation steps with swept collision against enemies, passing through allies. The original locked target remains the commitment/fizzle condition; the earliest enemy along the path can intercept. Position snapshots make the projectile visible without giving presentation authority over hit resolution.

`tools/run_checks.py` discovers all headless test suites and treats logged Godot errors as failures. `tools/capture_ui.gd` renders ten desktop screens in CI. Deployment depends on successful validation, tests the exported PCK, and writes a public commit/version manifest. `tools/verify_deployment.py` checks the served manifest, loader, JavaScript, WebAssembly and game pack, checks the exported game-pack SHA-256, then runs the downloaded pack's tests in a post-deployment CI job. Generated build and QA directories are ignored by Godot and excluded from Web exports.

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
