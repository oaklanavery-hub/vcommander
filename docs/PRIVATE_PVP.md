# Private friend playtest

The approved unranked friend playtest includes create/join codes, hidden drafting, shared 1× battles and sixty-second reconnect forfeits. It does not grant local mastery or competitive rank. The free-hosting package is prepared; no Render service or public endpoint has been provisioned yet. Render is connected; billing verification, deployment and live browser-to-WSS acceptance remain pending. The local harness needs no provider account or database.

## Run and verify

From the project directory with Godot 4.7 stable:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_private_rooms.gd
godot --headless --path . --script tests/test_private_network.gd
godot --headless --path . --script tools/run_private_server.gd
```

The integration test starts an ephemeral loopback server and actual WebSocket clients. It creates/joins a room, rejects a third seat, checks hidden picks, disconnects/resumes the guest, drafts, receives worker-generated identical compressed replays and finishes a multi-round match. It asserts that local Commander records are unchanged. The harness acknowledges completed simulation output directly; it does not claim to test a player watching synchronized animations or a browser deployment.

The standalone development server listens only on `127.0.0.1:8080`. `PORT` or `--port=8080` overrides its port. An explicitly requested `--listen=0.0.0.0` allows binding behind a TLS proxy. The app client permits `ws://` only on loopback and requires `wss://` for remote hosts. Do not publish this process as a ranked service. Its sixty-second disconnect policy is described below; rooms remain in memory and cannot recover after a process restart.

## Free deployment and player flow

`render.yaml` defines one Docker web service on the **Free** plan in Singapore, no databases/disks/add-ons and no automatic redeploys. `Dockerfile` pins the official Godot 4.7 archive/checksum, imports content at build time, runs as an unprivileged user and defaults to one room with `PVP_MAX_ROOMS=1`. Native development can use up to four rooms; the configured limit returns a visible busy response without changing an existing match. There is no keep-awake automation. Free-host restarts cancel in-memory rooms.

The user's budget is strictly zero. Before provisioning, use a confirmed Render connection and verify a free workspace/service with no payment method or settings that block chargeable overages. The Free service plan alone does not prevent bandwidth/build overages on a workspace with billing enabled. Do not add payment details, upgrade a workspace/service or create a paid database/disk. Render documents free-service sleep after fifteen idle minutes and roughly one minute to wake; the game provides bounded retry/status rather than claiming immediate availability.

After the free service is deployed, obtain its actual public WSS URL and validate it against this source/content version. Configure `network/private_room_url` in project.godot, or use the explicit `?pvp_server=wss://ACTUAL_HOST` playtest query before changing the default. A native development argument `--pvp-url=ws://127.0.0.1:8080` enables the same flow. Never guess the service URL or enable an unverified default. With an endpoint configured: choose a Commander, build four cards, select **Friend match**, create/share a room code or join a friend. Reconnect credentials stay in memory within the open game; refreshing/closing the page loses that credential and the sixty-second server grace still applies.

The screen reuses existing pixel portraits/cards and battle art/audio. A read-only adapter mirrors guest coordinates/ownership/entity references so both players see their own army on the left. Shared playback has no local pause/speed/skip input; menus explain the continuing clock. Online counters and results come from the authority, and the UI cannot grant mastery.

The CI-only HTML server preloads an in-memory startup-scene override; it leaves the exported pack and ordinary HTML unchanged. CI runs two isolated Chromium WebGL2 sessions against the real headless authority and tests the exact exported game pack. It checks invite/join/draft, the Commander opening, shared clock/locked controls, guest viewpoint, result agreement and unchanged local records. A separate job builds the actual Docker image under a 512 MiB runtime cap and verifies its WebSocket protocol. Native UI integration produces ten additional captures (99 total). Passing local/CI checks do not replace the final live Render/WSS acceptance.

## Protocol version 2

Text messages are JSON objects. Every command includes `v: 2`; the server validates type, size and integer ranges before dispatch. Create/join/resume also include a hash of the server-compatible Commanders, cards, sets, Buffs and balance. Different content is rejected before a seat is assigned. Transport assigns a seat; a client cannot submit stats, seed, damage, remaining hearts or winner.

| Command | Required fields beyond `v`, `type` | Meaning |
| --- | --- | --- |
| `create` | `content`, `commander`, `cards` | Validate a Commander/four unique Army IDs; allocate host seat. |
| `join` | `content`, `room`, `commander`, `cards` | Claim the one empty guest seat using a six-character invitation. |
| `resume` | `content`, `room`, `token` | Restore a disconnected seat using its private bearer credential. |
| `pick` | `round`, `revision`, `index` | Select an offered card at index 0–2. |
| `skill` | `round`, `revision` | Spend a legal point on the server-defined Commander skill. |
| `sync` | — | Request the current seat-filtered state/countdown. |
| `replay` | `round` | Request the current completed battle. |
| `ready` | `round` | Confirm receipt of a replay; both seats schedule shared playback. |
| `continue` | `round` | Acknowledge a scored nonfinal result; both seats begin the next draft. |
| `clock` | `at` | Echo a local millisecond timestamp with monotonic server time for clock estimation. |

`session` responses contain `room` and a 256-bit reconnect token, sent only to the owning connection. Keep tokens private; clients retain them in memory, not URLs or logs. A room code cannot recover a reserved seat. Live seats reject takeover. Process restart loses rooms/sessions; persistent accounts and cloud records are separate work.

`state` responses contain the assigned `you` side, current `phase`/`round`, own offer/points/revision/countdown, own current army/skill, frozen public rival army/skill budget, connection flags, hearts and replay availability. Drafting never reveals the opponent's current counts, picks, offer, points, skill, revision or random stream. The public rival snapshot refreshes only when both sides finish. Deep copies prevent returned views from editing authority.

Battle data is one bounded binary gzip JSON message with `v`, `type: battle`, `round` and `replay`. It preserves the existing numeric event/frame/pre-battle format consumed by BattleReplay. Host is canonical `player`/left and guest `opponent`/right in this transport; the presentation adapter mirrors the guest to their own left-side viewpoint. Both clients receive identical bytes; clients do not rerun combat or submit its outcome. Repeated completions cannot charge another heart.

## Resource limits and approved policies

The process permits four rooms, sixteen connections, an 8 KiB command, eight queued incoming commands and a token-bucket command budget. Unseated/handshaking connections have ten seconds to establish a session. Binary replays are capped at 8 MiB compressed/64 MiB expanded. Duplicate replay requests are throttled per round; output backpressure disconnects rather than growing an unbounded queue. An oversized generated replay abandons the room visibly without writing a player record.

Idle rooms expire after ten minutes and all development rooms after one hour, releasing seats/replays. These are resource bounds, not competitive forfeits. Disconnected seats remain reserved while the existing thirty-second selection deadlines continue, including legal auto-picks. Local pause cannot stop the authority clock. Both seats must acknowledge a nonfinal replay to begin a new draft; no acknowledgment can select cards or submit a winner.

The user chose free hosting, shared 1× playback without local pause/speed controls and a sixty-second disconnect forfeit (ADR-013, R095–R097). Protocol v2 waits for both replay downloads, then schedules a start one second ahead. Shared duration includes BattlePrelude, simulation and the existing contact tail. Round scoring happens at the server's shared end; early continue/readiness retries cannot advance or charge another heart. Reconnect restores the current phase/timeline. Grace expiry and final battle completion are ordered by their actual deadlines even if a poll catches up both at once; an earlier final result is preserved. Simultaneous disconnect expiry cancels an abandoned match without a winner. Free-host restarts still lose in-memory sessions.

Next: complete package/browser CI, verify zero-charge settings in the selected Render workspace, deploy the prepared service and verify real browsers over WSS before enabling the default endpoint. PvAI pause/mastery rules remain unchanged. Ranked matchmaking, persistence, cloud mastery, moderation and ratings require their own approved milestone.

Official networking references: [Godot WebSocketPeer](https://docs.godotengine.org/en/stable/classes/class_websocketpeer.html) and [Godot WebSocket tutorial](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).

Hosting references: [Render free limits](https://render.com/docs/free), [Blueprint schema](https://render.com/docs/blueprint-spec), [Docker services](https://render.com/docs/docker).
