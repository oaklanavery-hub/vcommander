# Development handoff

Verify the actual branch, tree and GitHub checks before resuming. [Earlier history](history/development-through-v0.15.md), [v0.17](history/development-v0.17.md) and [v0.18 implementation/release history](history/development-v0.18.md) are reference only.

## Verified release

- **v0.18.0**, released source `cf0be0d28179a0499fd6c83ef6e355114f095012`, [merged PR #38](https://github.com/oaklanavery-hub/vcommander/pull/38). Reviewed game/source tree: `507e5d10964625b95eecd9cf9a7af672662aae8a`.
- Live: https://oaklanavery-hub.github.io/vcommander/
- [PR CI 39976708772](https://github.com/oaklanavery-hub/vcommander/actions/runs/39976708772) passed on `0a9c5648cda0d2f414fe84fdc2bc4526b9132b74`: 51 source and 51 exported-pack suites, four JS clock cases, actual browser path purchase/IndexedDB reload through Continue with hidden rival information, two isolated WebGL2 friend sessions, production container and full native gallery including eleven new desktop/compact/larger-text views.
- [Deploy 39977556254](https://github.com/oaklanavery-hub/vcommander/actions/runs/39977556254) completed successfully with the same full gate, release export, publication, served-resource/checksum verification and all 51 suites against the actual downloaded public PCK. Explicit final log: `Deployment verified: 0.18.0 at cf0be0d28179a0499fd6c83ef6e355114f095012`.
- Independently fetched public manifest: version 0.18.0, source above, PCK SHA-256 `e9878bf331768e556d5fef654ee09f22c7ea65822db4fe2cb63c2784b20c8cb2`.

## Active — approved Sudden Death rule update

- User approved on 2026-10-24: a 180-second ceiling per Sudden Death battle; only new power picks in Sudden Death double their percentage. Earlier picks retain normal strength. Normal battles remain 120 seconds; draws continue the existing next-round loop.
- Base main `2cccf9c5953ffc6c2466a689da94134f05e2a5f2`; branch `feat/sudden-death`.
- Checkpoint 1: track enhanced pick cohorts; share exact math across combat/previews/AI; extend only Sudden Death battle clocks and validate replay/recovery/hidden public data. Preserve old checkpoint replay timing. Relevant source checks and native previews before the full Actions gate.
- Checkpoint 2: verify the known Water hybrid case with a bounded paired synthetic sample; report observations without promising that doubled growth eliminates draws.
- Core implementation and two new focused suites pass: all five mixed strengths/previews/combat, 120/180-second actual clocks, repeated rounds, capped AI, JSON recovery, hidden rival cohorts and old replay migration. Initial parser type-inference errors were corrected before the passing runs. Content validation and existing draft, power preview, AI adaptation, match recovery and private authority suites also pass. Seven native views rendered; review found compact power text overflow, corrected by wrapping the enhanced detail and splitting mixed-cohort roster lines. The second capture exposed an early tool-only typed preload of an autoload-dependent UI class; the capture now loads it at runtime. The corrected native rerun passes, including explicit compact card/text bounds; draft, compact, late frost and help images were visually reviewed. The bounded paired Water sample reproduced the legacy control (16 rounds unfinished, 9 SD draws, 1372.8s); the approved rule ended Round 15 after 7 SD draws and 1584.3s. This is one synthetic fixture, not proof of universal finish or shorter matches. Browser recovery acceptance now includes an actual enhanced draft-button pick, IndexedDB reload and Continue. This new browser case and the full Actions gate remain pending. Core checkpoint is saved remotely at `5c6b40125ad5d11ed70af8b8f60361fcfa714b31`. No extra healing reduction, damage ramp, tiebreaker, speed-cap change, campaign or public PvP was authorized.

## Working conventions

- Read AGENTS.md and relevant rules; use current repository/checks rather than historical pending notes. Save focused checkpoints and keep the handoff short. Do not repeat a passing full gate for documentation/cosmetics without an observed defect.
- Reuse pinned Godot 4.7, isolated/in-memory profiles/preferences/checkpoints/insights and the bounded native preview workflow. Never read, print or move the private developer key.
- Preserve unlimited powers, four-card armies, mixed-theme legality, automatic formation, pre-battle skill completion, 1× battle starts and no result skip. Human evidence and an explicit product choice precede an overtime rule change.
