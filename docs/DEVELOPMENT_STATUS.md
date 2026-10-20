# Development handoff

Verify this handoff against GitHub and the actual branch before resuming.

## Current state — v0.12.0 merged; Pages verification pending

- User requested a coherent fantasy pixel interface throughout the game using Hunter’s Lodge references. Campaign/story is explicitly KIV/on hold. PvP remains Coming Soon. Do not begin a campaign, reopen PvP, add accounts or change gameplay without new direction.
- Implemented and merged [PR #30](https://github.com/oaklanavery-hub/vcommander/pull/30). Exact feature head `a1a09522b1785a39c3fb5cf9ed78467b1488ea21`; main squash `6680fe7c6ef8747e921c7eac59ecb34dcdca84ab`. Feature branch `feat/fantasy-lodge-ui`.
- Original detailed lodge courtyard and forest clearing, shared rounded carved/leather frames with brass inset trim, arched portrait vignettes, pixel display headings, balanced two-column Commander gallery, equipped-card rack, blessing emblems, achievement medals, themed settings/dropdowns/tooltips and battlefield roster plaques. Existing character sprites/animations, world coordinates/contact/frost, formations, gameplay and progression are preserved.
- Pixelify Sans is self-hosted under its retained OFL notice. The notice is explicitly included and tested in the exported pack. No premium reference-pack assets were copied. Provenance is in `assets/pixel/CREDITS.md`.
- [Exact-head CI #39470800303](https://github.com/oaklanavery-hub/vcommander/actions/runs/39470800303) passed all 31 source suites, all 31 exported-pack suites, real two-session WebGL2 browser flow, the exact production container and all 115 native captures.
- Reviewed eighteen representative native views, including all four full Commander portraits, title, collection, draft/blessings, rewards/achievements, help/settings, normal/frozen/compact battlefield and result. Corrected achievement status wrapping and aligned blessing rows; actual layout/line-count assertions cover the regressions. Final critical review image hashes match the reviewed refinement head.
- Native artifact `12286872836`, SHA-256 `1e76edbbe972718d5e94e7f9d9c703d5ac42398236f72589701500bf969e559e`. Browser artifact `12287636224`, SHA-256 `a3151758364f6458f6e9a5f5262df80593967f18a069f25884e6000a13c5b84d`. Full-resolution PNGs and bounded review previews are retained by Actions.
- [Main Deploy Web #39471568484](https://github.com/oaklanavery-hub/vcommander/actions/runs/39471568484) has passed all three reusable CI jobs and is exporting/testing the final Web release. Actual Pages deployment and served-pack verification are pending. No public v0.12.0 success is claimed yet.
- Execution workspace was unavailable. Work was saved through GitHub and tested/rendered through Actions. The missing local reference paths were not read through Library; matching official public previews recovered the art direction. No cloud browser login is needed.
- All hosting/billing settings remain untouched. Render `srv-dbb1lr3ncjis73ar08rg` stays free, one instance, PVP_MAX_ROOMS=1 and auto-deploy off. The current ordinary client blocks PvP. Do not deploy this presentation-only change to Render.
- This docs-only handoff branch records release progress without retriggering a documentation-only main deployment loop. Final source/release identities also belong in PR #30.
- Next concrete action: inspect main run #39471568484; require build, deploy and verify success, record the actual served pack checksum/version, update this handoff and PR #30, then report the live game. No further implementation is pending for this visual request.
