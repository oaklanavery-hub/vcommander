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
