# v0.19 — Sudden Death growth

## Approved scope and implementation

User approved on 2026-10-24 (Asia/Kuala_Lumpur): double the percentage of **new power cards picked during Sudden Death** while preserving earlier bonuses, and give **each** Sudden Death battle a three-minute ceiling. Normal rounds remain 120 seconds. The existing three-pick repeated-draw loop, multiplicative stacking and speed caps remain. No healing penalty, damage ramp or tiebreaker was added.

Based on main `2cccf9c5953ffc6c2466a689da94134f05e2a5f2`; implementation branch `feat/sudden-death`. Core checkpoint `5c6b40125ad5d11ed70af8b8f60361fcfa714b31` was saved before long validation. Final tested PR head `d2f5bb42902f0e209a954fe3cb2caab46a336c68`; reviewed tree `157a6c5d2530cd8f3f40c3a43c1008a97ec9bccb`. Merged [PR #39](https://github.com/oaklanavery-hub/vcommander/pull/39) as `f29996f71359a092121f6c49729a811c34c8245c`, with the identical tree.

DraftSystem records total picks plus an enhanced subset. Shared WarbandStats applies normal and enhanced percentages independently before existing rounding/caps. All three side builders, effective previews and AI consume those states. Round context selects the headless 180-second ceiling and exposes the factual timer budget. Cards, mixed-cohort rosters and help explain the rule. Recovery retains exact RNG/offers/hearts and prior-public rival cohorts; completed v0.18 replays retain their original 120-second budget and ordinary powers, including after another migration restart. The next new Sudden Death round uses the approved rule.

## Focused validation and resolved findings

Content validation and existing draft, power preview, AI adaptation, recovery and private authority suites passed. Two new suites cover all five enhanced powers, mixed-strength combat/preview/future-recruit parity, repeated rounds, unlimited caps, AI value/caps, exact 120/180-second clocks, round-long frost after 120 seconds, snapshots/RNG, invalid data, hidden rival powers, old completed replay migration and unchanged hearts on replay.

Initial GDScript inference errors were corrected before passing focused tests. Native review found compact enhanced-card detail overflow; wrapping the detail and splitting mixed-cohort roster lines fixed it. An explicit typed UI reference in the capture caused an early autoload compilation dependency; the tool now loads it at runtime. The corrected seven-view capture passed explicit compact card/text bounds. Draft, compact/larger-text, late frost and help views were visually reviewed. No passing full gate was rerun for cosmetic refinement.

The known Water hybrid seed `204757` was compared once under a bounded pair of legacy/approved rules. The control exactly reproduced the old fixture: 16 rounds unfinished, 10 timeouts, nine Sudden Death draws, 1372.8 combat seconds. The approved rule had the same first seven rounds, then seven 180-second draws and a 31.5-second Earth victory in Round 15: eight timeouts, 1584.3 combat seconds. This establishes a finish in this one synthetic case, not balanced human play, shorter matches or universal freedom from stalls. Detailed reproduction is in [STRATEGY_PLAYTEST.md](../STRATEGY_PLAYTEST.md).

## Full gate

[PR CI 39989797370](https://github.com/oaklanavery-hub/vcommander/actions/runs/39989797370) completed successfully on the exact tested PR head: all 53 source suites, all 53 exported-pack suites, four JS clock cases, full native gallery including seven enhanced Sudden Death views, actual enhanced draft-button purchase with IndexedDB reload through Continue, exact mixed cohorts/RNG/180-second budget, preserved hidden rival powers/path/redraw/profile identity, two isolated WebGL2 friend sessions and the production container protocol.

## Publication

[Deploy 39990629132](https://github.com/oaklanavery-hub/vcommander/actions/runs/39990629132) completed successfully on the merged source above. It passed the full merged-source gate, release export and pack tests, publication, then downloaded the public resources/PCK, verified its source identity and SHA-256 and passed all 53 suites against that actual served pack. Explicit final log: `Deployment verified: 0.19.0 at f29996f71359a092121f6c49729a811c34c8245c`.

An independent fetch of the public build manifest confirmed version `0.19.0`, source `f29996f71359a092121f6c49729a811c34c8245c` and PCK SHA-256 `32e4ce13b7764d636b3e95f13d72657b0c500617c967ae08e30093316f573e5f`. The final documentation-only closure does not change that released source identity or rerun a passing code gate. No checks remain pending. Further anti-stall mechanics require a new product decision supported by human pacing evidence.
