# Free-server capacity experiment

The live v0.10.1 server remains capped at one room. This experiment measures one,
two, three and four rooms without sending stress traffic to the public server, creating
another hosted resource or changing gameplay.

## Method

Build the production image, then run:

```sh
docker build -t vcommander-capacity .
python3 tools/check_private_capacity.py --image vcommander-capacity
```

Every case starts a fresh unprivileged production container with **512 MiB RAM,
no swap and 0.15 CPU**, matching the limits observed from Render's metrics API.
Only the test entry script is mounted into that unchanged image. Clients and
report collection run outside its resource quota. There is no public-host input.

Each room has two real WebSocket clients. They create/join, reject an extra room,
send synchronized legal actions, reconnect one reserved seat during preparation,
download and compare both compressed replays, acknowledge shared playback and
compare scored hearts/results. Half-second clock requests measure responsiveness
throughout. `peak_jobs` confirms actual overlapping worker jobs.

The normal profile completes whole matches with ordinary offers, picks, caps and
skill budgets. Earth and Slime profiles seed synthetic late-game armies at the
existing unit/Buff caps and use both Commander skills; the mixed profile covers
all four Commander mirrors. Two capped rounds exercise replay replacement and
continued connections. The fixture accelerates only the already-computed replay
wait. The production combat simulation, snapshots, event recording, room service,
background workers, serialization and WebSocket transport are unchanged.

Reports include cgroup peak memory/CPU counters, largest preparation/download
wait, clock p95/maximum RTT, reconnect time, replay sizes and battle/frame/event
counts. OOMs, disconnects, mismatched results and timeouts remain explicit failed
cases. A completed benchmark job means measurements were collected; each case
has independent `functional_pass` and `within_test_budgets` verdicts.
When the kernel kills a container, the last sampled memory peak is only a lower
bound: the process cannot write its final cgroup peak after it dies. The explicit
Docker `OOMKilled` flag, rather than that last sample, identifies memory exhaustion.

The initial operational test budgets are **15% memory headroom**, preparation
within **10 seconds**, clock p95 within **1 second** and maximum clock RTT within
**5 seconds**. These are performance evaluation thresholds, not gameplay rules or
guaranteed internet latency. CI CPU scheduling, hardware and loopback networking
differ from the actual Render host, so results support a conservative capacity
recommendation rather than a guarantee for arbitrary traffic or future content.

## Current evidence

Local native smoke checks have passed normal one/two-room full matches, capped
Earth at one/two rooms, and two consecutive capped Slime/mixed rounds at four
rooms (eight clients). These validate the harness and gameplay agreement only;
the development environment has more resources than the free server. Initial
fixture typing and exhausted-draft seeding issues were corrected before the
constrained matrix. No live-capacity increase is justified by native smoke data.

The initial constrained [matrix #39274433023](https://github.com/oaklanavery-hub/vcommander/actions/runs/39274433023)
completed for one, two and four rooms at PR head `7671c0d03d14d7e525988ac8e486f40553c2380d`
(tested merge `c8a7c6b87cf3787357a6cec63ea69a8161bbd152`). One/two-room cases
completed with matching replays/results and no disconnects. Heavy two-room Earth
preparation reached 16.23 seconds and 321.84 MiB; clock RTT p95 reached 3.67 seconds.
Four-room ordinary matches completed (292.54 MiB, preparation up to 9.46 seconds),
but capped Earth and the second mixed round were killed by the 512 MiB memory
limit and disconnected all clients. Four Slime rooms completed but preparation
reached 14.80 seconds and clock p95 5.05 seconds.

The boundary matrix now adds three rooms and repeats the controls, with unchanged
production code, to determine the largest functional setting and assess response
time. The live cap remains one; no increased setting is claimed safe yet.
