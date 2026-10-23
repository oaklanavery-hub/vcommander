# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Earlier history](history/development-through-v0.15.md), [v0.17](history/development-v0.17.md), [v0.18](history/development-v0.18.md) and [v0.19 implementation/release history](history/development-v0.19.md) are reference only.

## Verified release

- **v0.19.0**, released source `f29996f71359a092121f6c49729a811c34c8245c`, [merged PR #39](https://github.com/oaklanavery-hub/vcommander/pull/39). Reviewed game/source tree: `157a6c5d2530cd8f3f40c3a43c1008a97ec9bccb`.
- Live: https://oaklanavery-hub.github.io/vcommander/
- Each Sudden Death battle has a 180-second ceiling; only newly picked Sudden Death powers double their percentage. Earlier normal/enhanced bonuses retain their strength. Normal rounds keep 120 seconds. Existing repeated draws, three picks and speed caps remain.
- [PR CI 39989797370](https://github.com/oaklanavery-hub/vcommander/actions/runs/39989797370) passed on `d2f5bb42902f0e209a954fe3cb2caab46a336c68`: 53 source and 53 exported-pack suites, four JS clock cases, actual enhanced draft purchase/IndexedDB reload through Continue with preserved hidden rival powers, two isolated WebGL2 friend sessions, production container and full native gallery including seven new views.
- [Deploy 39990629132](https://github.com/oaklanavery-hub/vcommander/actions/runs/39990629132) completed successfully: merged-source full gate, release export, publication, served-resource/checksum verification and all 53 suites against the actual downloaded public PCK. Explicit final log: `Deployment verified: 0.19.0 at f29996f71359a092121f6c49729a811c34c8245c`.
- Independently fetched public manifest: version 0.19.0, source above, PCK SHA-256 `32e4ce13b7764d636b3e95f13d72657b0c500617c967ae08e30093316f573e5f`.

## Current scope and next decision

- Approved Sudden Death work is complete; no implementation or release checks remain pending. Completed v0.18 replays keep their old clock; new rounds/picks use the approved rule. Resume preserves mixed cohorts, RNG, hearts, path/redraw budgets and prior-public rival information.
- The bounded paired Water diagnostic reproduces the legacy control (16 rounds unfinished, nine SD draws, 1372.8s). Approved rules finish Round 15 after seven SD draws and 1584.3s. This is one synthetic fixture, not proof of universal resolution, balance or shorter human matches. See [findings and reproduction](STRATEGY_PLAYTEST.md).
- Collect human pacing evidence before any further anti-stall mechanic. No healing penalty, damage ramp or tiebreaker was authorized. Campaign remains KIV; PvP remains Coming Soon and hosting stays free.

## Working conventions

- Read AGENTS.md and relevant rules; use current repository/checks rather than historical pending notes. Save focused checkpoints and keep the handoff short. Do not repeat a passing full gate for documentation/cosmetics without an observed defect.
- Reuse pinned Godot 4.7, isolated/in-memory profiles/preferences/checkpoints/insights and bounded native previews. Never read, print or move the private developer key.
- Preserve unlimited powers, four-card armies, mixed-theme legality, automatic formation, pre-battle skill completion, 1× battle starts and no result skip. Further balance changes require an explicit product choice.
