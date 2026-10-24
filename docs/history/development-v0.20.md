# v0.20.0 — Permanent unit upgrades

The approved unit-upgrade milestone is complete. Released game source: `197952f4203ac6fccf09c19caaa53e3ed5438af0`; reviewed source tree: `c13f5099b9c141ff88d2881aa90183dd3eff4400`. [PR #40](https://github.com/oaklanavery-hub/vcommander/pull/40) was squash-merged after the full gate.

## Delivered scope

- One permanent Lv. 2 purchase for each of 24 units, based on the supplied read-only `Vcommande upgrades.xlsx` reference (Sheet1 E2:E25). No workbook mutation.
- Shared XP equals lifetime XP across Commanders minus actual paid purchase costs. First purchase 200 XP, later purchases 400. Wins 100 XP, completed losses 50, forfeits zero. Existing XP is available; spending preserves mastery, levels, records, achievements and ownership.
- Schema-4 purchase ledger with quote/ownership/funds/pending-adventure/save guards; retain historical loss awards, old profile entitlements and exact-once settlement. Roll back before a failed write commits, while respecting an already committed primary write.
- Data-driven deterministic combat hooks for all reference effects, including delayed twin hits after DEF, seeded procs, timed roots/fields/debuffs, capped focus/shred/slows, two split generations, no repeat splitting after revival, heal-overlap bounds and nonrecursive links.
- Purchased upgrades freeze at adventure start and are supplied equally to both PvAI sides. Recover exact drafts/RNG/public information and upgraded replays without rescoring hearts or currency. Older adventures retain base-unit inputs.
- Scrollable fantasy forge in the existing menu, linked from the warband builder, Rewards and pause menu. Before/after art, full effects, quotes, shared balance and clear purchase feedback; immediate card/portrait refresh and compact larger-text keyboard scrolling.
- Separate transparent 64×64 Lv. 2 sprite atlas for all 24 units; preserve the normal atlas. Cards, rosters, living/dead/revived actors and inspection retain their recorded level. Native review removed cross-cell fragments through complete silhouette extraction. Recorded root vines, elemental pulses, persistent fields and SFX remain presentation only.
- PvP remains Coming Soon, campaign KIV, free hosting, private developer collection access, four-card/mixed armies, prelude-before-battle, 1× defaults, no skip and approved Sudden Death rules remain intact.

## Saved checkpoints

| Checkpoint | Remote commit |
| --- | --- |
| Wallet/catalog/profile migration | `df82708b3a0b2d329108f601ede58a88a6ad09c7` |
| Combat/recovery/evolved artwork | `b60a0ee12ca844b5d9c46ad9f81b9a1eb3dac4a5` |
| Forge and actual purchase UI | `ee7227b7b13c4c62e57e0c650bfeddc42658a26b` |
| Art extraction and browser/native coverage | `499d0c96d82f95481ebe76acede32cbabb474b03` |
| Updated existing XP/schema assertions | `d442d5d672d391a4f53414610634f51f14f849bc` |
| Rewards screen callback lifetime | `98dfc4d1344575ed94142ceadc1bbda85eec68d3` |
| Browser Continue visibility assertion | `b3136a5865ed2d4353477fba8c3729ab2aab7099` |

## Validation and corrected failures

[PR CI 40066452825](https://github.com/oaklanavery-hub/vcommander/actions/runs/40066452825) passed on the final branch head above: **57 source suites, 57 exported-pack suites**, four JavaScript clock cases, actual browser Rewards → forge → 200-XP purchase, separate Lv. 2 preview, IndexedDB restart and actual Continue. Browser recovery retains a 200-XP balance, 400-XP next price, 400 lifetime XP/Lv. 2 mastery, ownership, frozen AI/public upgrades, exact draft/RNG/clock, hearts and profile identity. Existing path/redraw and enhanced-Sudden-Death recovery, two isolated WebGL2 friend sessions, production container and complete native gallery passed.

The final PR run initially hit a 0.611-second friend-clock sampling difference above the existing half-second tolerance; retrying only that browser job passed, including common results and unchanged mastery. The gameplay clock and threshold were not changed.

Earlier full runs found stale 25-XP/schema-3 regression expectations; those assertions were updated while historical migration fixtures stayed intact and future-version protection moved to schema 5. A Rewards lambda retained a freed button after navigation; its update now uses the existing owner-bound refresh method. The browser probe also checked a freed title/Continue button after successful navigation; it now checks the visibility captured before navigation. Initial parser/type issues and JSON-reloaded wallet receipt integer normalization were corrected before passing.

Fourteen new native views cover all 24 before/after pairs, purchase/owned/shortfall states, compact larger-text actions, four legal upgraded battles and inspection. Source and exported cases separately cover all reference mechanics, full-recruitment Lv. 2 mirrors, numeric bounds, failed writes, corrupt ledgers, legacy migration and exact reconstruction.

Eight paired synthetic adventures completed without a time-limit draw; this is a bounded diagnostic with zero human samples, not a final balance verdict. Exact loadouts, seeds, timings and economy assumptions are in [UNIT_UPGRADES.md](../UNIT_UPGRADES.md), and art prompts/provenance are in [UPGRADE_ART.md](../../assets/pixel/UPGRADE_ART.md).

## Deployment verification

[Deploy 40067428512](https://github.com/oaklanavery-hub/vcommander/actions/runs/40067428512) completed successfully on the merged source. It passed the full merged-source gate, release export and pack tests, publication, then downloaded the public resources/PCK and verified source identity, checksum and **all 57 suites against that actual served pack**. Explicit final log: `Deployment verified: 0.20.0 at 197952f4203ac6fccf09c19caaa53e3ed5438af0`.

Independently fetched public manifest: version `0.20.0`, source above, engine `4.7.stable`, PCK SHA-256 `a59d240eac902e88330367ef785bb3a3543e34fa6698cf88bb548f8d2ba11174`. Live: https://oaklanavery-hub.github.io/vcommander/

Later documentation-only commits do not change the published game source.

