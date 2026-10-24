# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. Completed notes: [through v0.15](history/development-through-v0.15.md), [v0.17](history/development-v0.17.md), [v0.18](history/development-v0.18.md), [v0.19](history/development-v0.19.md), [v0.20](history/development-v0.20.md) and [v0.21](history/development-v0.21.md).

## Verified release

- **v0.21.0**, released source `d73ee43acb096cf2788b20f67cbee55487f20200`, [merged PR #41](https://github.com/oaklanavery-hub/vcommander/pull/41). Reviewed/merged tree: `2b40db233e2c4d0503c460b479aa3290a6d6e412`. Later documentation-only commits intentionally leave the published source unchanged.
- Live: https://oaklanavery-hub.github.io/vcommander/
- Unit Forge has its own main-menu button and dedicated screen, separate from Achievements & rewards. The supplied workbench/gallery layout shows Lv. 1 + XP = Lv. 2, details/purchase, Commander filter, available XP and scrolling cards with eight desktop columns. It retains pixel fantasy materials and rounded cards. Back preserves the originating army or saved adventure/Continue; browsing can preview locked units. XP, mastery, unlock and frozen-adventure rules are unchanged.
- [PR CI 40117998434](https://github.com/oaklanavery-hub/vcommander/actions/runs/40117998434) passed on `5fed21dd5dfd16f7db495074c0a6dcb35790a4b7`: 57 source and 57 exported-pack suites, actual standalone Forge purchase/IndexedDB restart/Continue, local/Sudden Death recovery, four JS clock cases, two isolated WebGL2 friend sessions, production container and full native gallery including 17 upgrade views. Focused local navigation/layout/transaction tests and content/art/presentation validators pass.
- [Deploy 40118488020](https://github.com/oaklanavery-hub/vcommander/actions/runs/40118488020) passed the full merged-source gate, release export, publication, identity/checksum verification and **all 57 suites against the actual downloaded public PCK**. Explicit final log: `Deployment verified: 0.21.0 at d73ee43acb096cf2788b20f67cbee55487f20200`.
- Independently fetched public manifest: version 0.21.0, source above, engine 4.7.stable, PCK SHA-256 `eae147f1ce8c1136ef6ba99929481184a5c0ad06b1af7db3afdabd072079ba2f`.

## Current state

- The dedicated Forge request is complete; no implementation or deployment checks remain pending.
- Upgrade effects, caps and initial economy assumptions are in [UNIT_UPGRADES.md](UNIT_UPGRADES.md). Use human feedback on strength and grind before extending permanent progression.
- Keep PvP Coming Soon, campaign KIV, free hosting and existing private developer collection access.

## Working conventions

- Read AGENTS.md and relevant rules; inspect current repository/checks rather than historical pending notes. Save focused checkpoints and keep this handoff short. Do not repeat a passing full gate for documentation/cosmetics without an observed defect.
- Reuse pinned Godot 4.7, isolated/in-memory profiles/preferences/checkpoints/insights and bounded native previews. Never read, print or move the private developer key.
- Preserve unlimited powers, four-card/mixed armies, automatic formation, complete pre-battle skills, 1× battle starts and no skip. Normal battles retain 120 seconds; each Sudden Death battle 180, with only newly picked Sudden Death powers doubled and earlier bonuses unchanged.
