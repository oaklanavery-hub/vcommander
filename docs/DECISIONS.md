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
