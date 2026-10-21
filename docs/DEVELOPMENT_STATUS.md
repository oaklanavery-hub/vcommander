# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Released — v0.13.0 backline specialists

- Completed the user's requested unlimited power cards, clear playable map ground, and Spriggan/Nymph/Mole/Sticky Slime expansion.
- PR [#31](https://github.com/oaklanavery-hub/vcommander/pull/31) merged into main as `8e51282ac40881186bed4a779342610fdf3d6242`. Final feature head `acc68b198fd5d6c757b0e851d1abd6fadeedd06e`.
- [Feature CI #39670694653](https://github.com/oaklanavery-hub/vcommander/actions/runs/39670694653) passed every job: clean Godot 4.7 import; data/art/presentation validation; 33 source suites; 33 exported-pack suites; actual two-session WebGL2 friend flow; exact production container; 122 native views.
- All seven new native views were visually reviewed after refining flames/water/cracks and fixed blessing rows: collection, transit, terrain, cooldown, links, reduced motion, and unlimited power cards.
- [Main Deploy Web #39671260998](https://github.com/oaklanavery-hub/vcommander/actions/runs/39671260998) passed all six jobs, including fresh source/native/browser/container gates, production export/pack tests, Pages publication, and actual served-pack verification.
- Verify job `119472372376` reports: `Deployment verified: 0.13.0 at 8e51282ac40881186bed4a779342610fdf3d6242`. Actual exported/served PCK SHA256: `817a464fe94fac3bc3aed0cd010911cd0f4a9a4d3319355f9a26c3bf0a8e81d4`.
- Main native artifact `12379657473`, SHA256 `0701b470749210bb86a03dcad17c990fb67c60884a478d2ed51a4e1fb1f0ddb2`; browser artifact `12379817610`, SHA256 `7788854936422c39b19e589575eef9b4e15849f495700011901b54e3d7e71ed9`. QA artifacts expire after seven days; source art, tests and scripts remain in Git.
- Live game: https://oaklanavery-hub.github.io/vcommander/

## Implemented behavior and tuning

- All production Buff definitions use `max_stacks: 0` (unlimited). Unit caps and existing 200 speed-rating caps remain. Repeated Sudden Death drafting stays available after all unit caps. AI discounts speed boosts that cannot improve capped ratings. This removes draft exhaustion; battle draws still follow the existing 120-second/draw/Sudden Death rules.
- Tree-free central ground is mapped to the existing 24×14 world; no formation, field dimension or range changes.
- Four new ordinary, immediately available 2/4 cards. Melee Spriggan/Nymph/Mole have generic backline transit; Range Sticky Slime marks up to two enemies. Existing four-slot armies, mastery gates and presets remain.
- Explicit playtest defaults: Spriggan/Nymph cooldown 5s, transit 0.8s; Fire trail 4s, radius 0.7, 35% ATK per 0.5s; Nymph swept contact radius 1.3, 80% ATK/moderate pushback, once per enemy/cast. Only Fire/Water transit grants damage immunity.
- Mole: 5s tunnel cooldown, 1s travel, 5s crack barriers on emergence, 180% ATK third strike. Both armies route around cracks; ordinary and forced movement cannot cross, melee cannot strike across, projectiles and ability transit can cross. Crowded rising cracks evacuate actors to free shoulders when possible. Mole is not damage-immune underground.
- Sticky: 5s cooldown/duration, link radius 3.5, normal range 5. Copies 50% of actual post-defense/post-absorption HP damage to the partner, excludes overkill, retains the original allied source and cannot recurse. Duplicate links do not multiply copying to the same partner. Lone marks have no partner. Body IDs prevent revived units inheriting old marks.
- Core stats/damage use rounded floats and constant-time stack calculation; a technical 1e100 modified-stat ceiling avoids numeric overflow after impractical thousands-of-picks scales. Picks remain unlimited and large stat labels remain finite/readable.
- Original atlas `assets/pixel/roster-v5.png` preserves the previous 21 frames byte-for-byte and adds four sprites. Built-in image-generation prompts/provenance: `assets/pixel/ASSASSIN_ART.md`; packing recipe: `tools/pack_assassin_art.py`. Four new original ability WAVs bring battle cues to 26 / total effects to 35.
- Rules/schema/architecture and ADR-016 document the generic transit, terrain, shared-damage and presentation boundaries.

## Scope and next action

- Campaign remains KIV. PvP remains Coming Soon; developer-only integration enables isolated sessions. No Render settings/deployments, paid services, accounts or new hosting were introduced. A future PvP reopening requires a matching authority/content deployment and product approval.
- No implementation or release check is pending for this request. Next bounded step is user playtesting and feedback on the provisional ability numbers, or a new product milestone decision. Do not silently change these conceptual rules while tuning.
- This accurate release record is saved on `docs/assassin-release` and linked from PR #31, avoiding a documentation-only main redeployment loop. Main's implementation checkpoint predates the completed release; actual commits/Actions and this record supersede that older pending status.
