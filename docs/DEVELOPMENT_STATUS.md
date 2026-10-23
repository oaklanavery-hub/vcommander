# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Older checkpoints](history/development-through-v0.15.md) and [v0.17 implementation history](history/development-v0.17.md) are reference only.

## Verified release

- **v0.17.0**, released source `14c530a701bde2dbe66d79900bc3ab66da2a810d`, [merged PR #37](https://github.com/oaklanavery-hub/vcommander/pull/37). Reviewed game/source tree: `2a8afca3da5c882562e1681f18498ed598897911`.
- Live: https://oaklanavery-hub.github.io/vcommander/
- [PR CI 39934480534](https://github.com/oaklanavery-hub/vcommander/actions/runs/39934480534) passed on `3b39037e7b8cb2ec3baacced2b33dcedbef5d941`: 48 source suites, 48 exported-pack suites, four JS clock cases, actual browser/IndexedDB played-match restart through Continue, two isolated WebGL2 friend sessions with bundled font coverage, the production container and the complete native gallery including twelve new views. One browser-only dependency retry resolved an Ubuntu mirror timeout; passing jobs/checks were retained.
- [Deploy 39936242342](https://github.com/oaklanavery-hub/vcommander/actions/runs/39936242342) passed the same full gate on merged source, release export, publication and served-resource/source/checksum tests. Every regression suite also passed against the actual downloaded public PCK. Explicit final log: `Deployment verified: 0.17.0 at 14c530a701bde2dbe66d79900bc3ab66da2a810d`.
- Independently fetched public manifest: version 0.17.0, source above, PCK SHA-256 `a3d6db628d59c5351e51a16e322b1d456ae0a9d6a0df999abc8ffee7fa031e24`.

## Completed scope and next action

- P0: bounded atomic local match recovery preserves both drafts/RNG, pick time, hearts, skill budgets and watched-result boundaries. Exact-once settlement handles both profile/checkpoint write-order interruptions; public display metadata is rebuilt from current content. Explicitly abandoning a played match still forfeits.
- P0: power previews use the exact shared combat formula and show per-type before/after values, partial/full caps and future-recruit context. Power cards remain unlimited/legal.
- P1: seeded Swarm/Sustain/Burst/Backline pressure opponents, public-only adaptation and Casual/Standard/Veteran decision-based difficulty with equal stats/collection/pick budgets.
- P1: default-off one-free-redraw experiment for both sides, no extra pick/time, persisted allowance; bounded local pacing/timeout observations with overtime unchanged. Settings selects next-adventure rules and opens Adventure insights.
- P1: factual two-sided post-replay observations and separate optional suggestions, reversible larger text, decorative effects intensity, clearer focus, direct optional first-adventure guidance and bounded compact draft/settings/report scrolling. Whole combat field and outside roster rails remain available; essential impacts, hazards, frost and skill timing are retained.
- Code checkpoint branch `feat/pvai-experience`; closure branch `docs/release-v0.17.0` records verified release/README/history only with `[skip ci]`. No implementation, export or deployment check remains pending. The published pack intentionally identifies the released code commit, not a later documentation-only commit.
- Next: human playtesting and review local pacing samples before proposing any overtime adjustment. P2/P3 is not approved. No campaign (KIV), public PvP (Coming Soon), broad balance audit, training grounds, save transfer or paid infrastructure was added. Existing mastery, rewards, device-only developer access, pre-battle skills, 1× starts, no skip and pixel fantasy art are retained.

## Working conventions

- Read AGENTS.md and relevant rules; use current repository/checks rather than historical pending notes. Save focused checkpoints before lengthy gates; do not rerun passing full checks for routine cosmetic changes.
- Pinned Godot 4.7 runtime; focused `godot --headless --path . --script tests/test_NAME.gd` while editing. Actions owns full source/pack/browser/container/native release verification.
- Browser setup reuses the pinned verified cache with a three-minute budget. A dependency failure is not evidence of a game defect; retry only the failed job when appropriate.
- Native previews use the bounded selection by default; full PNGs remain in the Actions artifact. Dedicated P0/P1 captures: `tools/capture_player_experience.gd`.
- Automated runs use in-memory/isolated profile, checkpoint, preferences and pacing stores. The browser restart acceptance uses ordinary paths only in an isolated browser context. Never read, print or move the developer private key.
