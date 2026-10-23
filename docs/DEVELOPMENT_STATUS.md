# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Earlier history](history/development-through-v0.15.md), [v0.17](history/development-v0.17.md) and [v0.18 implementation/release history](history/development-v0.18.md) are reference only.

## Verified release

- **v0.18.0**, released source `cf0be0d28179a0499fd6c83ef6e355114f095012`, [merged PR #38](https://github.com/oaklanavery-hub/vcommander/pull/38). Reviewed game/source tree: `507e5d10964625b95eecd9cf9a7af672662aae8a`.
- Live: https://oaklanavery-hub.github.io/vcommander/
- [PR CI 39976708772](https://github.com/oaklanavery-hub/vcommander/actions/runs/39976708772) passed on `0a9c5648cda0d2f414fe84fdc2bc4526b9132b74`: 51 source and 51 exported-pack suites, four JS clock cases, actual browser path purchase/IndexedDB reload through Continue with hidden rival information, two isolated WebGL2 friend sessions, production container and full native gallery including eleven new desktop/compact/larger-text views.
- [Deploy 39977556254](https://github.com/oaklanavery-hub/vcommander/actions/runs/39977556254) completed successfully with the same full gate, release export, publication, served-resource/checksum verification and all 51 suites against the actual downloaded public PCK. Explicit final log: `Deployment verified: 0.18.0 at cf0be0d28179a0499fd6c83ef6e355114f095012`.
- Independently fetched public manifest: version 0.18.0, source above, PCK SHA-256 `e9878bf331768e556d5fef654ee09f22c7ea65822db4fe2cb63c2784b20c8cb2`.

## Completed approved P0/P1 and next decision

- P1: Army Builder → Warband guide explains real equipped relationships, conventional frontline, the exact four-card theme tradeoff and collection ability keywords. No partial-theme bonuses or outcome predictions.
- P1: Settings → Commander paths enables a default-off local prototype for the next adventure. Two content-defined paths per Commander, from Round 3, once per adventure at one normal pick. Equal AI cost/availability, copied ability transformations, exact recovery and current-time inspection; prior public rival choices remain hidden across restart.
- P0/P1: local insights distinguish composition/prototype participation and full-recruitment rounds. [Focused playtest report](STRATEGY_PLAYTEST.md) documents eight bounded synthetic starter-only adventures and a human acceptance procedure. Seven finished; Water hybrid seed `204757` reached the 16-round diagnostic bound with ten timeouts/nine Sudden Death draws. No human samples or broad balance conclusion is claimed.
- Product decision required next: how repeated Sudden Death draws should escalate or resolve. Current overtime and theme bonuses remain. Human pacing/build-comprehension observations are the next evidence step; automated samples do not replace them.
- No implementation, export, publication or verification remains pending for the approved release. Published pack identity intentionally refers to released code, not later documentation-only closure.
- P2/P3 remains deferred: weekly challenges, cosmetics, sharing, campaign (KIV), public PvP (Coming Soon), training grounds, save transfer and paid infrastructure.

## Working conventions

- Read AGENTS.md and relevant rules; use current repository/checks rather than historical pending notes. Save focused checkpoints and keep the handoff short. Do not repeat a passing full gate for documentation/cosmetics without an observed defect.
- Reuse pinned Godot 4.7, isolated/in-memory profiles/preferences/checkpoints/insights and the bounded native preview workflow. Never read, print or move the private developer key.
- Preserve unlimited powers, four-card armies, mixed-theme legality, automatic formation, pre-battle skill completion, 1× battle starts and no result skip. Human evidence and an explicit product choice precede an overtime rule change.
