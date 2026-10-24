# VCommander

A browser-first VTuber commander drafting auto-battler built with Godot.

## Current status

**v0.20.0 — The unit forge**

Spend shared adventure XP on permanent Lv. 2 abilities and new pixel artwork for all 24 units. The first upgrade costs 200 XP, later ones 400 XP; mastery, levels, records and earned units stay intact. The forge is available from the warband builder, Rewards and pause menu. Purchases apply from the next adventure, with the same upgraded collection available to the AI. [Upgrade effects and economy](docs/UNIT_UPGRADES.md).

Every Sudden Death battle has its own three-minute ceiling. Only new power cards picked during Sudden Death get double their percentage; earlier bonuses retain their strength. Normal battles keep their two-minute limit. Previews, mixed-strength rosters, AI and recovery use the same rules, including preservation of old completed replays. [Release verification](https://github.com/oaklanavery-hub/vcommander/actions/runs/39990629132) passed against the actual public game pack.

The current playable prototype supports:

- **Army builder → Warband guide** explains equipped interactions, ability keywords and the exact mixed-theme tradeoff
- **Settings → Commander paths** enables a default-off local prototype: two paths per Commander, one normal pick from Round 3, once per adventure, with equal AI access and recoverable state
- local pacing insights distinguish path participation and themed/mixed builds; [focused synthetic playtest findings](docs/STRATEGY_PLAYTEST.md) document a repeated timeout case and the bounded approved-rule comparison

- **Continue adventure** after restart; explicit abandonment stays separate and final mastery settlement remains exact-once
- effective power previews with before/after values and visible partial/full speed-cap warnings
- Swarm, Sustain, Burst and Backline pressure opponents; difficulty changes their decisions rather than unit stats or collection access
- a default-off redraw experiment: both sides get one free redraw per round, with no extra pick or timer reset
- **Settings → Adventure insights** for bounded local pacing/time-limit observations; normal and Sudden Death samples remain distinguishable
- optional post-replay ideas separated from recorded facts, reversible larger body/control text, configurable decorative effects and a direct first-adventure guide entry

- replay-current companion HP, modified stats, ability cooldowns and active effects in a separate inspector beside the field
- post-playback reports with effective damage/healing, absorption, kills, bodies alive and survival, including death-created/revived bodies and Commander effects
- a playable, optional guide through a normal match, with paused reading time and unchanged mastery/reward rules
- clearer anticipation/recovery, four types of death motion, four new original death sounds and reserved audio capacity for important abilities; reduced motion retains static fades
- four starting units and two mastery rewards per Commander at Level 3 + three wins and Level 5 + six wins; existing collection ownership is retained

- unlimited power-card picks, including after every unit reaches its cap; speed rating caps remain and AI discounts ineffective speed boosts
- Spriggan, Nymph, Mole and Sticky Slime, each 2/4: elemental backline travel, fire paths, damaging water gushes/pushback, five-second cracks that both armies route around, third-strike damage and shared enemy damage links
- original pixel art and distinct ability sounds for all four new units, with mastery collection access and the existing four-card loadout limit
- tree-free playable grass throughout the battlefield; decorative scenery does not overlap units

- a shared woodland lodge art direction across Commander/army selection, drafting, battle, achievements and menus: original detailed scenery, arched portrait vignettes, rounded carved frames, brass trim and pixel display lettering
- a detailed open forest clearing with matching roster plaques; existing tactical formations, frost coverage, hit timing and unit animations remain intact
- illustrated blessing offers, achievement medals, a balanced four-Commander gallery and styled settings controls

- **PvP · Coming Soon**: friend matches are paused; the tested private-room implementation is retained
- eighteen local achievements and eight mastery reward units, with progress in the Achievements & Rewards journal

- separate personal PvAI records for every Commander: matches, wins/losses/forfeits, win rate, permanent mastery levels and XP progress
- full-match win +100 XP, completed loss +50 XP, forfeit +0 XP; every 250 XP earns a level, with no combat stat advantages
- gallery mastery displays/card levels and an animated completed-match XP reward, with reduced motion and device-local profile/backup saving

- a centered title and menu over an original moonlit pixel forest, with all four Commanders seated around an animated campfire; idle poses, cloth/hair, embers, stars and elemental motes respect reduced motion

- Slime Ball stores 30% of post-defense damage, bursts every 10s with medium-area enemy pushback, and releases double its stored amount on death
- shared tactical formation AI: multi-rank deployment, Tank screens, melee wings, central healer coverage, range-aware placement and spacing against opposing area damage
- Commander skill openings that finish before armies move and the battle clock begins
- stretching/retracting Pitcher Plant vines, visible enemy pulls, distinct arrows/fireballs/flames/water/ice/seeds and impact/attack motion
- every battle starts at 1×, with results shown after the battle completes
- four distinct detailed Commander designs and twenty-five detailed unit sprites (twenty-four collectible units plus the summoned plant), shared by cards and battles
- Slime Princess: pink royal artwork, Royal Jelly's once-per-ally revival and +100% attack for qualifying death spawns
- Giant Slime 1/4 (green split Tank), Slime Cannon 2/4 (green slowing shots), Slime Ball 2/6 (white damage-absorbing Melee), Slime Barrel 2/6 (pink ten-second death pools)
- rounded pixel-edged card frames, gold selection borders, darker nameplates and refined panels/navigation
- portrait Commander/army cards with element, class and recruit/cap badges
- Commander gallery, full-body portrait and separate description, passive and active panels
- four warband slots, an eight-column collection, element filters and three saved presets per Commander
- a forest-camp title menu, How to Play and shared pause/settings menus
- starter warbands, a filtered companion collection and clearer draft/result guidance
- two original looping music tracks, 39 sound effects and saved volume/accessibility settings

- Fire, Water and Earth starter Commanders
- 16 starter Army cards and 8 mastery reward cards with provisional playtest stats/ability tuning
- exactly 4 unique pre-match Army cards, freely mixed across elements
- Commander themed-set bonuses when all four selected cards match the theme
- seeded 3-choice pre-battle drafting
- Army-card summon amounts and maximum unit counts
- opening Battle 1 draft restricted to Army cards
- 5 persistent Army-wide Buff Cards with multiplicative stacking and unlimited picks (existing speed caps still apply)
- Commander skill selection cost and twice-per-match / once-per-round limits
- 30-second pick timer and random auto-selection on timeout
- deterministic left-vs-right auto-combat after the opening draft
- automatic Tank → Melee → Backline formation, target locking, movement/collision and ranged spacing
- Commander skills and the starter roster's data-driven unit abilities
- sixteen starter Army units and eight mastery reward units plus summoned plants, full-field battle playback, HP bars and match heart meters
- eight-direction movement poses, four-direction attacks, neutral idle/death and combat VFX
- optional sound, reduced motion, HP numbers, pause and keyboard shortcuts
- seeded match input, Commander-theme quick equip and visible opponent progress
- 120-second normal battle limit and 180-second limit for each Sudden Death battle

The opponent now selects its own Commander and unique four-card loadout, drafts legally using a seeded policy, and conceals current picks until combat. The battlefield uses original elemental pixel artwork, a meadow arena, projectile/skill effects and readable side markers. Matches now continue until one side reaches four losses. Draws cost both sides a loss; simultaneous fourth losses trigger repeated Sudden Death rounds. Losing sides receive a fourth selection in normal rounds. Armies, Buffs and skill budgets persist while battle units respawn at full HP.

## Technology

- Godot 4.7 stable
- GDScript
- Compatibility renderer for browser support
- JSON-driven gameplay content
- deterministic fixed-timestep combat simulation
- GitHub Actions for validation and web deployment
- GitHub Pages for the browser build

## Source of truth

Read these before changing gameplay:

1. `AGENTS.md`
2. `docs/GAME_RULES.md`
3. `docs/ARCHITECTURE.md`
4. `docs/DATA_SCHEMA.md`
5. `docs/DECISIONS.md`

## Development workflow

`main` remains playable. Work happens on short-lived branches, passes validation/tests, then enters `main` through a pull request.

AI development uses small, resumable checkpoints rather than bundling several milestones into one result. `docs/DEVELOPMENT_STATUS.md` records the current branch, checks and next step. After an interruption, ask: **Resume VCommander from `docs/DEVELOPMENT_STATUS.md`; verify the branch and existing checks, then complete the next focused checkpoint.** Saved commits preserve progress; they do not remove ChatGPT session limits or automatically start another turn.

Pull requests run CI. On `main`, Deploy Web calls that same validation workflow once before exporting, publishing and checking the served game. Superseded validation runs are cancelled and jobs have bounded durations. The full source, visual and exported/deployed-pack checks remain enabled.

## Local start

Friend PvP is **Coming Soon** while development focuses on PvAI progression. The private-room implementation and integration tests are retained for later. See [the developer playtest guide](docs/PRIVATE_PVP.md).

Open `project.godot` using Godot 4.7 stable and run the project. Choose **Play**, select a Commander card and choose **Next**. Keep their prefilled starter warband or select cards to add/remove companions, choose **Battle**, spend all opening picks, then start the battle. Continue through the results until the match ends. **How to play** is available from the title menu and **Menu / Esc** throughout the game. Local menus pause the draft clock; leaving an active match asks for confirmation.

## Controls

| Screen | Input | Action |
| --- | --- | --- |
| Any game screen | Esc | Pause menu, help and settings |
| Draft | 1 / 2 / 3 | Choose the corresponding offered card |
| Draft | S | Prepare Commander skill |
| Draft experiment | R | Use the once-per-round redraw without resetting the timer |
| Draft | Enter | Start battle after selections are spent |
| Battle | Space | Pause/resume playback |
| Battle | 1 / 2 / 4 | Set battle speed |
| Battle | M | Toggle sound |
| Result | Enter | Continue to the next round |

Music and sound begin after the first player interaction. **Settings** has separate music/effects volume, larger text, reduced motion, health numbers and decorative battle-effects intensity, saved on the current device. Choose the next opponent difficulty and optional redraw experiment before starting an adventure; these rules stay fixed for the active/recovered match. Set a volume to zero to mute it. **Advanced match options** in the warband screen reveals the optional match seed; reuse it with the same setup and picks to reproduce a match. Current rival draft choices are concealed until combat. Audio credits and composition source are in `assets/audio/CREDITS.md` and `tools/compose_audio.py`.

## Cards and warband presets

A card’s top-left badge identifies its element. Army cards show recruits per pick / unit cap at the top right, with a class symbol underneath (shield: Tank, sword: Melee, bow: Range, cross: Healer). Hover for ability and stat details. The Commander portrait, theme passive and active skill are shown separately before army building.

Headings use the self-hosted OFL-licensed Pixelify Sans face; smaller body/badge text retains the readable fallback. The lodge/forest images are original decorative presentation assets and never define collision or formation positions. Campaign development is currently on hold (KIV).

Detailed artwork uses transparent 128×192 Commander and 64×64 unit atlas cells with nearest-neighbor display. Designs are original generated fantasy artwork; provenance and exact prompts are in `assets/pixel/CREDITS.md`. Combat movement/attacks remain procedural presentation driven by the replay.

Choose Preset 1, 2 or 3, then **Save** a complete four-card warband. Clicking a populated preset loads it. Empty slots preserve the current selection; **Clear** empties only the current warband. Presets are saved per Commander on this device and are checked against current content before loading. The top-right dropdown filters the collection; a gold card border marks equipped companions.

## Verification and playtesting

Run `python3 tools/run_checks.py --godot /path/to/godot` for all content/art validation and headless suites. Run `godot --headless --path . --script tools/run_balance.gd -- --seeds=8 --seed-start=1000 --output=/tmp/balance.json` for a reproducible AI sample. See `docs/PLAYTEST_REPORT.md` for methods, tuning and limitations.

CI renders the full desktop capture gallery, including seven dedicated Sudden Death views, eleven warband strategy views, twelve recovery/redraw/recap/accessibility views as well as title animation phases/reduced motion, help/settings/pause, projectile contact, attack phases, frost, summon ownership, the Slime Court and tactical formations, all four elemental galleries, compact battle details and long blessing labels, and tests the exported game pack. Bounded native review previews supplement the full-resolution PNG artifact. A deployed build can be verified with `python3 tools/verify_deployment.py --expected-commit <full-main-sha> --godot /path/to/godot`.

## Commander mastery

Each Commander starts at Level 1 and keeps a separate personal PvAI match record on this device/browser. Win a complete match for 100 XP, finish a lost match for 50 XP, and earn one permanent level every 250 XP. A better win ratio earns mastery faster at the same match count. Individual battle rounds never grant separate XP; mastery levels provide no combat stat multipliers. New collection rewards are described below.

Leaving before the first battle has no record. Explicitly leaving or replacing a played unfinished match counts as one loss/forfeit with zero XP. Closing or refreshing a recoverable adventure preserves it: use **Continue adventure** to restore the same draft/clock or replay the same unwatched battle at 1×. A previously watched result may reopen directly. Legacy pending records without a checkpoint retain their old forfeit policy, while incompatible/corrupt checkpoints show guidance and preserve records. An already resolved final match keeps its actual outcome, including recovery across profile/checkpoint write interruptions. Replaying a result never awards XP again. The gallery shows each Commander's level, record, win rate and next-level progress; the final match result animates the XP gain after battle playback.

Records use local browser/device storage and a backup. Clearing site data or using a different browser/device does not retain the same record; private browsing or blocked storage may prevent saving. Visible notices explain save/load failures, and an unreadable profile is preserved instead of silently overwritten. This release does not provide account sync, online competitive ratings or a shared leaderboard. Automated test/capture scripts use isolated profiles.

## Achievements and unit rewards

Open **Achievements & rewards** on the title screen, or **Rewards** in the Commander gallery/warband builder. Eighteen achievements track completed matches, wins, Commander coverage and mastery milestones. Forfeits do not count as completed matches for achievements. Earned achievements and unlocked units remain permanent on this device.

Every Commander has four starters and two permanent mastery rewards. Both the required level and win count must be met:

| Commander | Starters | Level 3 + 3 wins | Level 5 + 6 wins |
| --- | --- | --- | --- |
| Fire | Magma Golem, Fire Imp, Sorcerer, Ash Phoenix | Spriggan | Dragon |
| Water | Ice Giant, Sea Serpent, Penguins, Tidal Guard | Water Wizard | Nymph |
| Earth | Giant Tree, Bear, Wood Archers, Spore Sage | Pitcher Plant | Mole |
| Slime Princess | Giant Slime, Slime Cannon, Slime Ball, Jelly Medic | Slime Barrel | Sticky Slime |

Spore Sage is now recruit 2/cap 4. The complete collection has twenty-four cards; any four unique themed cards activate the signature bonus. Rewards may be mixed into any warband and are never auto-equipped. Locked previews show both requirements. Valid existing profiles permanently retain their previous collection, including preset eligibility, and their records/XP stay unchanged. New profiles follow this lineup. Clearing site data removes local progress; no account or purchase is required.

The developer can enter a privately supplied key under **Settings → Developer access** to use all units on that device. The public repository/build contains only a verifier, never the key. Access does not grant mastery, achievements or match records; the journal labels unearned units as developer access. Removing access retains actual earned rewards. Finish or leave a match before changing access. This is local testing access, not account authentication or trusted competitive authorization.
