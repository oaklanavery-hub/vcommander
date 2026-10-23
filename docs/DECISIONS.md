# Architecture & Product Decisions

## ADR-001 — Godot 4.7 stable + GDScript

**Status:** accepted  
**Reason:** Stable Godot release; GDScript supports the web target while Godot 4 C# web export remains unsuitable for this project.

## ADR-002 — Browser-first Compatibility renderer

**Status:** accepted  
**Reason:** Godot 4 browser exports target WebGL 2 and the Compatibility renderer. Web export is configured without thread support for broad hosting/browser compatibility.

## ADR-003 — JSON-driven content

**Status:** accepted  
**Reason:** Commanders, cards and sets must grow without adding one-off hardcoded branches to core gameplay systems.

## ADR-004 — UI does not own game logic

**Status:** accepted  
**Reason:** Set checks, draft legality and combat outcomes must remain testable independently from presentation.

## ADR-005 — Seeded combat simulation

**Status:** accepted  
**Reason:** Auto-battler bugs and balance cases need exact reproduction.

## ADR-006 — Player vs AI first

**Status:** accepted  
**Reason:** Networking adds backend, synchronization and anti-cheat complexity before the core game is proven.

## ADR-007 — No generated web build in source control

**Status:** accepted  
**Reason:** GitHub Actions builds the web artifact from source, avoiding large/noisy generated commits.

## Change protocol

Before changing an accepted architectural decision, append a new ADR describing the problem, proposed replacement, affected systems and migration plan. Do not silently rewrite old decisions.

## ADR-008 — Replaceable pixel presentation catalog

**Status:** accepted

**Reason:** Original placeholder sprites must evolve alongside gameplay while remaining replaceable by final art. The presentation catalog maps content IDs to silhouettes/palettes and provides generic role/element fallbacks. Animation, VFX and sound consume simulation output only. No visual asset defines combat stats, hit timing or outcomes.

## ADR-009 — Shared player menus and audio

**Status:** accepted

**Reason:** Player-facing help, navigation, music and presentation preferences must be consistent across screens. Presentation-only autoloads own menus and audio; a local ConfigFile stores volume and accessibility preferences. Opening a local modal pauses active selection/replay time, without editing match state or recomputing combat. Leaving an active match requires confirmation. The simulation and data-driven content remain unchanged.

## ADR-010 — Shared portrait cards and local warband presets

**Status:** accepted

**Reason:** The approved wireframes use the same card language in Commander selection and army building. Presentation components render content-driven badges and replaceable portrait catalogs. A separate warband-preset service validates four unique current content IDs before storing three local slots per Commander. UI invokes existing loadout methods; preset persistence does not own combat or change army/draft legality.

## ADR-011 — Local Commander records and permanent mastery

**Status:** accepted for the user-approved personal PvAI mastery scope

**Reason:** Completed match outcomes already belong to GameState/MatchState. A separate headless CommanderProgress service owns stable-ID records, data-driven XP/level calculation, versioned atomic local persistence and one pending match/last receipt. GameState starts tracking at the first battle, settles whole matches once and records forfeits on reset; loading an interrupted pending match settles one forfeit. Replay/UI consume a copied reward receipt and never grant XP. Automated script runs use in-memory profiles and explicit isolated paths so tests/captures cannot alter player records.

This adds personal device-local progression, without replacing the accepted PvAI, combat or presentation boundaries. Permanent mastery has no combat stat effects. Account sync, competitive ratings and shared leaderboards remain separate future product decisions.

## ADR-012 — Private-room PvP foundation

**Status:** accepted for the user-approved private 1v1 development milestone; public hosting and gameplay policy pending

**Reason:** The user accepted the proposed server-authoritative friend-room milestone. Reuse DraftSystem, MatchState and CombatSimulator behind a separate headless authority. A browser-compatible WebSocket client submits intentions, never stats, seeds, damage or results. The server assigns seats, validates four-card loadouts against its own content, keeps current picks private, owns selection deadlines and simulates each battle once. Combat jobs run outside the connection/timer loop; both seats receive the same immutable replay.

First checkpoint: an isolated room service, version/content negotiation, bearer reconnect sessions, bounded WebSocket transport, and a two-client full-match integration harness. Keep the existing PvAI menus, local mastery and public build behavior unchanged. No shared ranking, account/database service, provider subscription or public endpoint is authorized by this foundation.

The development harness requires both seats to acknowledge a battle before advancing; this is an integration seam, not a final replay/pause or disconnect-forfeit rule. Disconnected seats retain a session and the draft clock continues. Development room expiry discards a room without recording a result. Before public play, decide hosting/budget, synchronized playback/pause behavior and disconnect grace/forfeit policy, then implement the player-facing flow and document those approved rules. Unranked PvP must never award trusted competitive rank from local PvAI profile data.

## ADR-013 — Free friend playtest with shared playback

**Status:** accepted by the user on 2026-10-19

The user selected free hosting, shared 1× playback (no individual pause/speed controls), and a forfeit after sixty seconds disconnected. Retain separate unranked friend matches with no account-backed rating, permanent PvP records or local PvAI mastery rewards. Prepare a single free Render service; provision only a confirmed free plan and no paid add-ons.

The authority waits for both clients to receive/acknowledge the replay, then publishes a shared future start time covering Commander opening, combat and contact tail. It settles the round once at that timeline's end; local menus cannot pause it or the selection deadline. Reconnect restores the current authoritative phase/time instead of replaying an old round. Both players continue from a scored nonfinal result before the next draft. Disconnect grace is server-timed and applies to a started two-seat match; resolving a final battle before grace expires preserves that result. Simultaneous expiry for both seats cancels the abandoned match without a reward. Process restart/room expiry cancels sessions without inventing wins. Browser client needs cold-start retry/reconnect guidance; no perpetual keep-awake process is added.

## ADR-014 — Achievements and mastery collection rewards

**Status:** accepted for the user-requested local achievements/rewards milestone (2026-10-20)

Extend the existing local CommanderProgress profile rather than introduce accounts or a second wallet. Content declares achievement conditions and optional card mastery requirements. The headless service derives progress from settled records, permanently records earned achievement IDs/card entitlements, and adds newly earned items to the existing exact-once match receipt. Schema 1 profiles migrate without altering XP, records or pending-match recovery. Existing qualifying records backfill rewards on load. Unknown historical reward IDs remain preserved.

GameState filters the selectable collection and validates equipment/begin-match; presets and UI cannot bypass unlock requirements. The AI receives the same available collection for that match. Four original cards per theme remain available from the beginning. New reward units extend theme choice to five cards; any four still activate the signature bonus. The simulator and draft rules receive normal content and never read progression. Achievements grant recognition; only declared mastery card requirements grant units, automatically and permanently. No extra currencies, purchases, accounts or level-based stat multipliers are introduced.

PvP remains implemented and covered by developer integration checks but is unavailable to ordinary players while its menu says Coming Soon. Development tests enable their own in-memory availability explicitly; a URL override cannot enable the player feature. Re-enabling PvP later requires a compatible server/content release and a product decision about collection ownership.

## ADR-016 — Temporary combat terrain and backline abilities

**Status:** accepted within the user's requested assassin expansion.

Extend the existing headless simulator with data-driven transit, path hazards and damage links. Temporary crack segments belong to simulation state and expire by simulation time. A small pure geometry helper computes visibility routes around segment endpoints, cached per unit until terrain or the destination changes. Ordinary movement and forced displacement use swept barrier checks; melee cannot strike through cracks. Ranged shots and underground/elemental transit ignore surface barriers. The existing open battlefield dimensions and formation planner are preserved. Recorded transit events, links, hazards and obstacles are read-only replay metadata; presentation never computes hits or routes. Shared damage enters the central damage pipeline with a recursion guard and retains the original allied source. No network/progression architecture changes.

## ADR-017 — Two mastery rewards and separate developer access

**Status:** accepted for the user's approved lineup and developer-only collection request (2026-10-22).

Supersede ADR-014's initial reward lineup with four content-defined starters and two rewards per Commander (Level 3 + 3 wins, Level 5 + 6 wins). Profile schema 3 permanently grants the previously ordinary collection listed in progression data when loading a valid schema-1/2 save. Validate the complete old profile before migration; new, corrupt and future profiles receive no legacy grants. Existing counters, unknown historical IDs, pending matches and earned rewards are retained through the existing atomic save/backup path. No combat system reads progression.

The static offline game has no account identity service. Use a private, randomly generated 256-bit developer key rather than a public all-units toggle. Commit only its SHA-256 verifier; deliver the key privately outside the repository. A small separate DeveloperAccess service validates and stores the credential on the current device. CommanderProgress distinguishes collection access from earned entitlements, so developer use never forges mastery, achievements or permanent card grants. The owner may revoke access locally; access changes are blocked during a match and revalidate the equipped army afterward. Automated tools use isolated/in-memory access and synthetic keys. This is local testing access, not tamper-proof account authorization or permission to trust local data in future competitive PvP. No backend or paid infrastructure is added.

## ADR-018 — Read-only battle feedback and optional guided normal play

**Status:** accepted for the user's requested reports, inspection, tutorial and presentation polish (2026-10-23).

Extend existing immutable replay metadata with effective HP loss/healing, current unit stats, cooldowns and statuses. A headless BattleReport aggregates that recorded evidence by side and stable card ID; it never simulates outcomes. Death-created bodies retain attribution, Commander/summoned effects are distinct, and damage/healing/protection highlights are separate. Reports are available only after complete replay; inspection uses the currently displayed body and time, with no future damage or hidden draft information.

Use a collapsible inspector beside the arena, preserving the full-field camera and existing click-free combat. Selecting units creates no gameplay action. Keep ownership/effect word labels off battlefield actors.

A small presentation guide orchestrates optional coach panels across the real first-match flow. Players still choose a Commander, build a legal army, spend legal selections and watch normal pre-battle/battle playback. Panels pause local clocks while reading and restore prior pause state. Finishing/ending guidance does not settle matches, grant XP, unlock units or rewrite mastery. The only new preference is local tutorial completion, with isolated/in-memory automation. Starting guidance during an existing match follows normal leave/forfeit confirmation. PvP integration remains paused and receives no tutorial pauses. No balance audit, save transfer, training mode, campaign or paid service is added.

## ADR-019 — Recoverable local matches and P0/P1 improvements

**Status:** approved by the user on 2026-10-23.

Supersede ADR-011's restart-as-forfeit policy for recoverable local PvAI matches. A separate bounded, atomic local snapshot stores content fingerprint, stable IDs, both draft/RNG states, public opponent snapshot, scored match state and selection time. A battle is reconstructed from the same inputs/seed without rescoring an already resolved round. Profile settlement retains its last receipt so recovery across a snapshot/profile write interruption cannot duplicate XP. Explicitly abandoning/replacing a played match still forfeits; merely restarting does not. Invalid/incompatible saves produce visible guidance and never silently replace player records. Automation uses memory or isolated paths.

Extend existing systems for actual power-card benefit previews, opponent styles with public-information-only adaptation and decision-based difficulty, optional one-redraw-per-round PvAI experiments, bounded device-local pacing records and factual post-replay recaps. Keep the default draft/overtime rules until the player opts into the experiment or evidence supports a further decision. Larger-text/effects-intensity preferences and optional first-match entry remain presentation only. Preserve hidden picks, equal collection, pre-battle skills, default 1×, no result skip, existing mastery, Coming Soon PvP, campaign KIV and free hosting.


## ADR-020 — Read-only warband guidance and optional match paths

**Status:** accepted for user-approved second P0/P1 research scope (2026-10-23)

Use a separate presentation catalog and pure WarbandGuide for relationships/glossary; show real equipped interactions and the existing four-card theme tradeoff without creating scores or new bonuses. Keep player-facing guidance within the existing builder and scrollable shared menu.

The commander-path prototype is a default-off, match-fixed local rule. Content declares two branches per Commander and narrowly validated generic ability transformations. DraftSystem owns one-pick purchase legality and the stable selected ID; CommanderSpecializations transforms copied ability input once at the simulation boundary. AiController gets the same catalog and uses its own composition. GameState checkpoints both rules and IDs and rebuilds prior public path metadata from trusted content, never from the rival's already-spent hidden draft. Default checkpoints keep their original fingerprint; prototype checkpoints include the technique catalog. No additional scene, account, currency, permanent stat progression or server is introduced. R117 records approved first-version mechanics and provisional values.

Extend bounded local insights with optional composition/path/full-recruitment metadata. Run a small explicit seeded matchup/pacing sample, label it synthetic, and retain the current overtime and bonuses pending human evidence. Existing campaign/PvP and P2/P3 deferrals remain.


## ADR-021 — Enhanced new Sudden Death powers and per-battle ceiling

**Status:** accepted by user (2026-10-24)

Extend each Sudden Death battle to 180 seconds while normal rounds retain 120. Double the percentage of new power picks only; preserve earlier normal and enhanced cohorts across repeated rounds. Retain the existing three-pick repeated-draw loop, multiplicative stacking and speed caps. Do not add a tiebreaker, healing penalty or damage ramp. Keep cohorts in DraftSystem and the shared WarbandStats formula, with explicit round budgets for exact old replay migration rather than silently recomputing a scored adventure under the new limit. Synthetic pacing diagnostics can identify remaining stalls but do not authorize further balance changes.
