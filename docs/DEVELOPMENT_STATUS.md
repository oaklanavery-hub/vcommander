# Development handoff

Verify this handoff against GitHub and the working tree before resuming.

## Current task — Fantasy pixel presentation throughout the game

- User has placed campaign/story in KIV. Improve the complete visual interface using the supplied Hunter’s Lodge references: Commander selection, warband/collection, draft, battlefield, rewards, title and utility modals. No gameplay/progression/network rule changes.
- Branch `feat/fantasy-lodge-ui`, base main `ff40a5d391bd93e32ccc9ab5c8e567a6ec3e735f` (verified v0.11.0). PR #29 achievements/mastery is released; main Deploy Web #39373288633 passed all gates and served-pack verification. PR #28 remains separate.
- Preserve all twenty cards, four Commanders, mastery/achievements, existing animations and accessibility, full-field frost/hearts, projectile contact and deterministic tactical formations. PvP remains Coming Soon. Render and all hosting/billing settings stay unchanged.
- Art direction: original richly textured woodland/lodge scenery, carved warm timber and leather, brass inset trim, parchment primary controls, fine pixel ornament, rounded card silhouettes, elemental portrait accents. Use shared presentation components so every screen belongs to the same game.
- Local execution workspace is unavailable. Source is read/edited through GitHub; GitHub Actions supplies Godot validation, exported-pack/browser checks and native visual captures. The supplied local attachment paths cannot be opened; the matching official public CraftPix Hunter’s Lodge preview page was recovered for reference. Do not copy pack assets into the project.
- Checkpoint 1: save shared material style and original environment assets; apply to selection cards and common navigation/modals. Checkpoint 2: replace coarse battlefield ground with detailed original forest clearing; refine scene hierarchy and remaining progression/draft/utility views. Checkpoint 3: full exact-head source/export/browser/container CI, inspect representative native screens including compact battle and all elemental selections, then merge and verify Pages/served pack.
- Passing before this change: existing main CI/deployment. New checks: not yet run. No local test or attachment inspection is claimed.
- Next concrete action: implement the shared presentation checkpoint and a bounded CI screenshot review stream, then open a draft PR for remote validation.
