# Free-server room capacity — measured 2026-10-19

**Keep the current live cap at one room (two players).** It was the largest setting
that completed every tested workload within the existing free-server resource
limits. Two and more rooms failed valid heavy workloads. Increasing the room
setting alone would expose players to disconnections and lost in-memory matches.

| Rooms | Players | Completed profiles | Result |
|---|---:|---:|---|
| 1 | 2 | 6/6 | All tested scenarios completed; peak memory 337.18 MiB, heaviest preparation 13.93 seconds. |
| 2 | 4 | 5/6 | Ordinary and capped theme battles completed, but simultaneous 120-second healing battles exhausted the 512 MiB limit and disconnected all clients. |
| 3 | 6 | 4/6 | Heavy Earth preparation dropped all six connections; endurance battles also exhausted memory. |
| 4 | 8 | 3/6 | Earth, second-round mixed and endurance workloads exhausted memory and disconnected clients. |

One room is a functional recommendation for the measured build, not a guarantee
of instant results. Its normal-match maximum preparation was 4.46 seconds; the
full-duration endurance case reached 13.93 seconds, clock p95 3.49 seconds and
maximum clock RTT 4.32 seconds. No room count met every initial latency budget.
The live service, free plan and one-room configuration were left unchanged.

## Evidence

- [Final constrained matrix #39276595697](https://github.com/oaklanavery-hub/vcommander/actions/runs/39276595697): 24 independently recorded cases, 116 completed battle replays/results (including rounds preceding a later case failure), maximum eight concurrent clients.
- [Game regression CI #39276595440](https://github.com/oaklanavery-hub/vcommander/actions/runs/39276595440) passed source suites, native captures, exported-pack/two-browser checks and the production container protocol check.
- Measured PR head `5ca5b971350288face649f6affec603fd31a7787`; tested merge `54ee52462a1650fd19f4f32e95019e69b32ecc5e`, tree `fa6206d6d8a0614308be5f8928d1e22a0413442b`. The tested tree matches the saved harness checkpoint.
- All four raw artifact archives were downloaded, SHA-256 checked and reviewed. Permanent per-case measurements, artifact IDs and hashes are saved in [the result data](benchmarks/free-room-capacity-2026-10-19.json). Raw CI artifacts include logs and have finite retention.

The benchmark workflow's success means measurements were collected successfully.
It does **not** mean all capacity cases passed: the result data preserves each
functional and performance verdict, OOM flag, error and partial completed rounds.
A killed process cannot write its final cgroup reading; memory samples marked
`memory_peak_is_lower_bound` must not be interpreted as the actual fatal peak.
Docker's explicit `OOMKilled` flag establishes memory exhaustion. A transient
`Running` flag during teardown does not override an observed OOM event.

## Workloads and method

Build the production image and run the repeatable test:

```sh
docker build -t vcommander-capacity .
python3 tools/check_private_capacity.py --image vcommander-capacity
```

Each case starts a fresh unprivileged production container with **512 MiB RAM,
no swap and 0.15 CPU**, matching the limits observed in Render's metrics API.
Only the isolated test entry script is mounted into that image; production
simulation, room service, workers, event recording, serialization and WebSocket
transport are unchanged. Clients and report collection run outside its quota.
There is no public-host input and no additional hosted resource or paid plan.

Two real WebSocket clients per room create/join, reject an extra room, send
synchronized legal actions, reconnect a reserved seat during preparation,
download and compare both compressed replays, acknowledge shared playback and
compare authoritative hearts/results. Half-second clock requests measure
responsiveness. Recorded worker counts confirm overlapping jobs.

Six profiles run at one, two, three and four rooms:

- Normal: complete matches with ordinary offers and picks.
- Earth: capped Earth mirrors with summons, healing and all Buffs.
- Slime: capped Slime mirrors with splits, revival and death effects.
- Mixed: capped mirrors of the different Commander themes.
- Crowded: legal mixed four-card armies with the highest unit caps and both Earth skills, producing 66 starting bodies.
- Endurance: legal mixed healing/tank/absorption armies with Water skills and capped HP/DEF, without attack Buffs. The replay must reach the full 120-second round; both measured rounds did.

Capped profiles use synthetic late-game state at existing legal limits and run
two rounds to exercise replay replacement. Only the already-computed presentation
wait is accelerated. This is a server-capacity test, not a browser-rendering load
test or an exhaustive search of every possible legal army/seed.

Initial operational budgets were 15% memory headroom, preparation within ten
seconds, clock p95 within one second and maximum clock RTT within five seconds.
These are evaluation thresholds rather than gameplay rules. CI hardware, CPU
scheduling and loopback networking differ from the live host; future content or
protocol changes need fresh measurements before increasing capacity.

## What to optimize before raising the cap

The endurance replay was 10.88 MiB expanded and about 0.25 MiB compressed, while
the one-room process reached 337.18 MiB. Small network packets therefore do not
establish low server-memory use. Code inspection shows deep copies of frames and
events in `CombatSimulator._finish_result`, another full copy in
`PrivateMatch.accept_battle`, and JSON/gzip encoding in the connection poll loop.
Measured long poll times and clock delays make these useful optimization targets;
this experiment did not isolate every allocator or CPU cost.

The next engineering experiment should bound concurrent heavy simulations,
reduce duplicate/unneeded uncompressed replay retention, and move expensive
encoding outside the connection loop. Preserve immutable shared replays,
determinism, complete Commander openings/contact timing, exact-once scoring,
reconnect grace and existing gameplay. Rerun this same matrix before raising the
live cap. Increasing infrastructure spend is outside the user's free-only scope.
