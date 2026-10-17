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
