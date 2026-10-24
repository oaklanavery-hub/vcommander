# v0.21 — Dedicated Unit Forge

## Scope and source

The 2026-10-25 request separates the Forge from Achievements & rewards and gives it its own main-menu button. The supplied wireframe specifies original card + quoted XP = upgraded card, ability details and purchase on the right, then Commander filter, available XP and a scrollable collection. The implementation retains the existing pixel fantasy scenery, wood/brass frames and rounded cards. No new art, balance, economy, profile schema or combat mechanics were introduced.

- Base main: `67fafa6317bc03c7f916068b96d07a3df9608ab7`.
- Branch: `feat/forge-screen`; saved implementation checkpoint `efe59e8d36ecf6f284ce1db6e4b517300f0b07a1`, final checked head `5fed21dd5dfd16f7db495074c0a6dcb35790a4b7`.
- [PR #41](https://github.com/oaklanavery-hub/vcommander/pull/41), merged source `d73ee43acb096cf2788b20f67cbee55487f20200`; merged tree independently matches reviewed tree `2b40db233e2c4d0503c460b479aa3290a6d6e412`.

## Behavior

The standalone Control scene owns presentation only. Existing profile/state APIs retain purchase authority, quotes, unlock checks, atomic persistence, shared XP, mastery and adventure freezing. The workbench stays visible above the independently scrolling gallery, showing all 24 units in eight desktop columns. Locked companions can be previewed with their mastery requirement. Ownership, artwork, exact XP shortfall and purchase feedback refresh immediately; the first-upgrade bonus disappears after purchase. Commander filtering leaves the selected army unchanged.

Back returns to the originating title or builder without resetting the army or saved adventure. The builder shortcut opens the same screen; the old rewards/pause modal entry is removed. A pending adventure remains protected from purchases. Keyboard scrolling, compact layouts and larger text retain access to the controls. A viewport-based column calculation corrected a compact resize/minimum-width loop during focused testing. The XP label has a dark outline for scenery contrast. ADR-023 supersedes only ADR-022's modal presentation choice.

## Validation

Focused Forge transactions/layout/navigation, scene flow, player experience, developer-access UI lifecycle, guide and accessibility suites pass. Content, art and presentation validators pass. Native Compatibility rendering passes 17 upgrade views: all four before/after rosters, separate main-menu entry, purchase/owned/shortfall, filter/scroll, compact larger text, four upgraded battles and recorded inspection.

[PR CI 40117998434](https://github.com/oaklanavery-hub/vcommander/actions/runs/40117998434) passed on the final branch head without retry: **57 source suites and 57 exported-pack suites**, four JavaScript clock cases, actual main-menu/standalone Forge purchase, separate Lv. 2 preview, IndexedDB restart and actual Continue. Browser recovery preserves 200 XP balance, 400 XP next price, lifetime XP/mastery, ownership, frozen AI/public upgrades, exact draft/RNG, hearts and profile identity. Existing local/path and Sudden Death recovery, two isolated WebGL2 friend sessions, production container and the full native gallery passed.

## Deployment verification

[Deploy 40118488020](https://github.com/oaklanavery-hub/vcommander/actions/runs/40118488020) completed successfully on the merged source without retry. It passed the full merged-source/browser/container/native gate, release export and pack tests, publication, then downloaded the public resources/PCK and verified source identity, checksum and **all 57 suites against that actual served pack**. Explicit final log: `Deployment verified: 0.21.0 at d73ee43acb096cf2788b20f67cbee55487f20200`.

Independently fetched public manifest: version `0.21.0`, source above, engine `4.7.stable`, PCK SHA-256 `eae147f1ce8c1136ef6ba99929481184a5c0ad06b1af7db3afdabd072079ba2f`. Live: https://oaklanavery-hub.github.io/vcommander/

Later documentation-only commits do not change the published game source.
