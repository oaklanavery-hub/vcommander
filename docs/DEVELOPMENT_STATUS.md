# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Earlier history](history/development-through-v0.15.md), [v0.17](history/development-v0.17.md), [v0.18](history/development-v0.18.md), [v0.19](history/development-v0.19.md) and [v0.20 implementation/release history](history/development-v0.20.md) are reference only.

## Verified release

- **v0.20.0**, released source `197952f4203ac6fccf09c19caaa53e3ed5438af0`, [merged PR #40](https://github.com/oaklanavery-hub/vcommander/pull/40). Reviewed source tree: `c13f5099b9c141ff88d2881aa90183dd3eff4400`. Later documentation-only commits intentionally leave the published source unchanged.
- Live: https://oaklanavery-hub.github.io/vcommander/
- All 24 units have a permanent Lv. 2 ability and distinct pixel artwork, with before/after forge previews. Shared spendable XP is earned lifetime XP minus paid purchases: first upgrade 200 XP, later ones 400. Completed wins grant 100 XP, losses 50, forfeits zero. Existing XP is available; spending preserves Commander mastery, levels, records, achievements and ownership.
- Upgrades freeze at adventure start and are supplied equally to both PvAI sides. Purchases require an unlocked companion and no pending adventure. Recovery preserves exact upgrades, drafts/RNG, hidden/public boundaries, replay, hearts and currency; older adventures keep base units.
- [PR CI 40066452825](https://github.com/oaklanavery-hub/vcommander/actions/runs/40066452825) passed on `b3136a5865ed2d4353477fba8c3729ab2aab7099`: 57 source and 57 exported-pack suites, four JS clock cases, actual forge purchase/IndexedDB restart/Continue, existing local/path/Sudden Death recovery, two isolated WebGL2 friend sessions, production container and full native gallery including 14 new upgrade views. A transient friend-clock sample required retrying only the browser job; the threshold and gameplay clock were unchanged.
- [Deploy 40067428512](https://github.com/oaklanavery-hub/vcommander/actions/runs/40067428512) completed successfully: full merged-source gate, release export, publication, served identity/checksum verification and **all 57 suites against the actual downloaded public PCK**. Explicit final log: `Deployment verified: 0.20.0 at 197952f4203ac6fccf09c19caaa53e3ed5438af0`.
- Independently fetched public manifest: version 0.20.0, source above, engine 4.7.stable, PCK SHA-256 `a59d240eac902e88330367ef785bb3a3543e34fa6698cf88bb548f8d2ba11174`.

## Current state

- Active request (2026-10-25): give Unit Forge its own main-menu button and dedicated screen following the supplied layout: Lv. 1 + XP cost = Lv. 2, description/purchase beside it, filter and available XP above a scrollable card gallery. Keep the fantasy pixel theme and existing upgrade rules.
- Branch `feat/forge-screen`, base main `67fafa6317bc03c7f916068b96d07a3df9608ab7`; actual v0.20 deployment remains verified. Checkpoint 1: scene/navigation and focused transaction/layout tests. Checkpoint 2: native/browser acceptance, full release gate, merge/deploy/public verification. No new balance audit or artwork generation is needed for this UI-only request.
- Dedicated scene/navigation and the reference workbench/gallery layout are implemented. Focused Forge transactions/layout, scene flow, player experience, developer-access UI lifecycle, guide and accessibility suites pass. A viewport-based column calculation corrected compact resizing before passing. Native capture passes 17 views, including separate title entry, actual purchase, filter/scroll, compact larger text and existing unit/battle art coverage. Browser acceptance now follows the main-menu Forge and Back route; the actual exported-browser flow and full release gate remain pending.
- [UNIT_UPGRADES.md](UNIT_UPGRADES.md) records all effects, caps, economy assumptions and the eight-adventure paired synthetic diagnostic. These are initial playtest values, with no human balance/retention claim. Art prompts/provenance: [UPGRADE_ART.md](../assets/pixel/UPGRADE_ART.md).
- Next: use player feedback on upgrade strength and grind before extending permanent progression. Keep PvP Coming Soon, campaign KIV, free hosting and existing private developer collection access.

## Working conventions

- Read AGENTS.md and relevant rules; inspect current repository/checks rather than historical pending notes. Save focused checkpoints and keep this handoff short. Do not repeat a passing full gate for documentation/cosmetics without an observed defect.
- Reuse pinned Godot 4.7, isolated/in-memory profiles/preferences/checkpoints/insights and bounded native previews. Never read, print or move the private developer key.
- Preserve unlimited powers, four-card/mixed armies, automatic formation, complete pre-battle skills, 1× battle starts and no skip. Normal battles retain 120 seconds; each Sudden Death battle 180, with only newly picked Sudden Death powers doubled and earlier bonuses unchanged.
