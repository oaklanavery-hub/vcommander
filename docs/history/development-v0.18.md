# v0.18 strategy and learning release history

Released 2026-10-23. Source `cf0be0d28179a0499fd6c83ef6e355114f095012`; tree `507e5d10964625b95eecd9cf9a7af672662aae8a`.
[PR #38](https://github.com/oaklanavery-hub/vcommander/pull/38) merged after [CI #39976708772](https://github.com/oaklanavery-hub/vcommander/actions/runs/39976708772) passed on `0a9c5648cda0d2f414fe84fdc2bc4526b9132b74`.

[Deploy #39977556254](https://github.com/oaklanavery-hub/vcommander/actions/runs/39977556254) completed successfully on merged source. It repeated the full source/export/browser/container/native gate, exported/published the game and checked actual served resources and pack checksum. All 51 suites passed again against the PCK downloaded from the public site. Explicit final log: `Deployment verified: 0.18.0 at cf0be0d28179a0499fd6c83ef6e355114f095012`.

Independent public manifest read confirmed version `0.18.0`, released source above and PCK SHA-256 `e9878bf331768e556d5fef654ee09f22c7ea65822db4fe2cb63c2784b20c8cb2`.

The release includes read-only equipped relationships/glossary, mixed-theme guidance, the default-off eight-path commander prototype, exact pick/RNG/timer/public-state recovery and bounded local composition/prototype/full-recruitment evidence. Browser acceptance purchased a path through the actual UI and reloaded through the actual Continue action in an isolated IndexedDB context. Four JS clock cases, two isolated WebGL2 friend sessions, the production container, all 51 source/exported-pack suites and the full native gallery passed. Eleven new native views cover desktop, compact/larger-text guidance, path purchase and insights.

Focused synthetic evidence and human acceptance procedure are in [STRATEGY_PLAYTEST.md](../STRATEGY_PLAYTEST.md). Seven of eight bounded adventures finished; Water hybrid seed `204757` reached the 16-round diagnostic bound with ten time-limit draws, nine in Sudden Death. This is neither a human occurrence estimate nor proof of an indefinitely unfinishable match. No human samples, balance verdict or experiment benefit is claimed. No full-recruitment round occurred in that sample; a separate regression verifies path buying in an actual buff-only offer after all four caps.

Next director decision: whether/how repeated Sudden Death draws should escalate or resolve a tie. Overtime and theme bonuses were retained. Further P2/P3 scope remains deferred. Documentation-only release closure intentionally leaves the published pack identifying released code rather than a later documentation commit.

## Saved implementation handoff

# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Older checkpoints](history/development-through-v0.15.md) and [v0.17 implementation history](history/development-v0.17.md) are reference only.

## Verified release

- **v0.17.0**, released source `14c530a701bde2dbe66d79900bc3ab66da2a810d`, [merged PR #37](https://github.com/oaklanavery-hub/vcommander/pull/37). Reviewed game/source tree: `2a8afca3da5c882562e1681f18498ed598897911`.
- Live: https://oaklanavery-hub.github.io/vcommander/
- [PR CI 39934480534](https://github.com/oaklanavery-hub/vcommander/actions/runs/39934480534) passed on `3b39037e7b8cb2ec3baacced2b33dcedbef5d941`: 48 source suites, 48 exported-pack suites, four JS clock cases, actual browser/IndexedDB played-match restart through Continue, two isolated WebGL2 friend sessions with bundled font coverage, the production container and the complete native gallery including twelve new views. One browser-only dependency retry resolved an Ubuntu mirror timeout; passing jobs/checks were retained.
- [Deploy 39936242342](https://github.com/oaklanavery-hub/vcommander/actions/runs/39936242342) passed the same full gate on merged source, release export, publication and served-resource/source/checksum tests. Every regression suite also passed against the actual downloaded public PCK. Explicit final log: `Deployment verified: 0.17.0 at 14c530a701bde2dbe66d79900bc3ab66da2a810d`.
- Independently fetched public manifest: version 0.17.0, source above, PCK SHA-256 `a3d6db628d59c5351e51a16e322b1d456ae0a9d6a0df999abc8ffee7fa031e24`.

## Active scope — approved P0/P1 strategy and learning

- User approved the second research round's P0/P1 on 2026-10-23. Base main: `5f767808e52d8af1ba5a5e7086c868f60512149c`; branch `feat/warband-strategy`.
- Checkpoint 1: data-driven army-builder synergy explanations, exact theme/mixed tradeoff and a compact ability glossary. Acceptance: actual equipped relationships, no invented bonuses/counters, locked previews, responsive native views.
- Checkpoint 2: default-off local commander-specialization prototype, two content-defined branches per Commander, available from Round 3, once per match at one normal pick. Equal AI access; hidden picks, replay/recovery and next-adventure preference retained. Acceptance: headless legality/behaviour, fresh/default equivalence, resumed/public boundaries, browser and native views.
- Checkpoint 3: bounded reproducible pacing/themed-versus-hybrid playtest cases with clearly labelled synthetic findings, plus a human playtest procedure using existing Adventure insights. No overtime or blanket balance changes without evidence. Automated results are not human telemetry.
- Checkpoint 1 implemented: generic read-only relationship catalog, builder entry/tradeoff and scrollable glossary. Focused `test_warband_guide.gd` passed; editor import logged no script errors. Native/browser review remains pending.
- Checkpoint 2 implemented: eight generic commander paths, pick legality/AI, effective simulation/inspection, default-off preference, stable recovery/public visibility and extra local pacing context. `test_commander_specializations.gd` and content validation passed; no script errors in the editor import.
- Focused AI/controller/adaptation, redraw/insights, match recovery, battle inspection, warband guide and new strategy-insights suites passed. Eleven native strategy views passed bounds checks at 1280×720 and 1024×600 with larger text; reviewed guide, builder, compact paths and selected draft.
- Bounded synthetic sample completed: seven of eight fixtures finished; Water hybrid seed `204757` hit the 16-round diagnostic bound with ten timeouts/nine Sudden Death draws. See `docs/STRATEGY_PLAYTEST.md`. No human samples, broad balance conclusion or overtime change is claimed. This is a product decision after the approved release.
- Final specialization regression passed, including buff-only capped armies, v0.17-shaped checkpoint compatibility, malformed counts, exact resumed specialized battles and current-time cooldowns. Native eleven-view check passed again after wording refinements.
- Pending: full Actions source/export/browser/container/native gate and deployment.
- P2/P3 remains outside scope: weekly challenges, cosmetics, sharing, campaign, public PvP, training grounds, save transfer and paid infrastructure.

## Working conventions

- Read AGENTS.md and relevant rules; use current repository/checks rather than historical pending notes. Save focused checkpoints before lengthy gates; do not rerun passing full checks for routine cosmetic changes.
- Pinned Godot 4.7 runtime; focused `godot --headless --path . --script tests/test_NAME.gd` while editing. Actions owns full source/pack/browser/container/native release verification.
- Browser setup reuses the pinned verified cache with a three-minute budget. A dependency failure is not evidence of a game defect; retry only the failed job when appropriate.
- Native previews use the bounded selection by default; full PNGs remain in the Actions artifact. Dedicated P0/P1 captures: `tools/capture_player_experience.gd`.
- Automated runs use in-memory/isolated profile, checkpoint, preferences and pacing stores. The browser restart acceptance uses ordinary paths only in an isolated browser context. Never read, print or move the developer private key.
