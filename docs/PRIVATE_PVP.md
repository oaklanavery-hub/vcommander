# Private-room PvP development foundation

This is the first checkpoint of the approved friend-room milestone, not a public multiplayer release. The playable site remains PvAI v0.9.0. Hosting, the player-facing flow, browser-to-host verification, replay/pause synchronization and disconnect forfeits remain pending. No provider has been provisioned and no subscription/account/database is required to run the local harness.

## Run and verify

From the project directory with Godot 4.7 stable:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_private_rooms.gd
godot --headless --path . --script tests/test_private_network.gd
godot --headless --path . --script tools/run_private_server.gd
```

The integration test starts an ephemeral loopback server and actual WebSocket clients. It creates/joins a room, rejects a third seat, checks hidden picks, disconnects/resumes the guest, drafts, receives worker-generated identical compressed replays and finishes a multi-round match. It asserts that local Commander records are unchanged. The harness acknowledges completed simulation output directly; it does not claim to test a player watching synchronized animations or a browser deployment.

The standalone development server listens only on `127.0.0.1:8080`. `PORT` or `--port=8080` overrides its port. An explicitly requested `--listen=0.0.0.0` allows binding behind a future TLS proxy. The app client permits `ws://` only on loopback and requires `wss://` for remote hosts. Do not publish this process as a ranked service. It has in-memory rooms and no production disconnect/forfeit or restart recovery policy.

## Protocol version 1

Text messages are JSON objects. Every command includes `v: 1`; the server validates type, size and integer ranges before dispatch. Create/join/resume also include a hash of the server-compatible Commanders, cards, sets, Buffs and balance. Different content is rejected before a seat is assigned. Transport assigns a seat; a client cannot submit stats, seed, damage, remaining hearts or winner.

| Command | Required fields beyond `v`, `type` | Meaning |
| --- | --- | --- |
| `create` | `content`, `commander`, `cards` | Validate a Commander/four unique Army IDs; allocate host seat. |
| `join` | `content`, `room`, `commander`, `cards` | Claim the one empty guest seat using a six-character invitation. |
| `resume` | `content`, `room`, `token` | Restore a disconnected seat using its private bearer credential. |
| `pick` | `round`, `revision`, `index` | Select an offered card at index 0–2. |
| `skill` | `round`, `revision` | Spend a legal point on the server-defined Commander skill. |
| `sync` | — | Request the current seat-filtered state/countdown. |
| `replay` | `round` | Request the current completed battle. |
| `continue` | `round` | Acknowledge a nonfinal replay through the development integration seam. |

`session` responses contain `room` and a 256-bit reconnect token, sent only to the owning connection. Keep tokens private; clients retain them in memory, not URLs or logs. A room code cannot recover a reserved seat. Live seats reject takeover. Process restart loses rooms/sessions; persistent accounts and cloud records are separate work.

`state` responses contain the assigned `you` side, current `phase`/`round`, own offer/points/revision/countdown, own current army/skill, frozen public rival army/skill budget, connection flags, hearts and replay availability. Drafting never reveals the opponent's current counts, picks, offer, points, skill, revision or random stream. The public rival snapshot refreshes only when both sides finish. Deep copies prevent returned views from editing authority.

Battle data is one bounded binary gzip JSON message with `v`, `type: battle`, `round` and `replay`. It preserves the existing numeric event/frame/pre-battle format consumed by BattleReplay. Host is canonical `player`/left and guest `opponent`/right in this transport; the eventual player-facing adapter must explicitly implement the approved viewpoint. Both clients receive identical bytes; clients do not rerun combat or submit its outcome. Repeated completions cannot charge another heart.

## Development limits and pending policy

The process permits four rooms, sixteen connections, an 8 KiB command, eight queued incoming commands and a token-bucket command budget. Unseated/handshaking connections have ten seconds to establish a session. Binary replays are capped at 8 MiB compressed/64 MiB expanded. Duplicate replay requests are throttled per round; output backpressure disconnects rather than growing an unbounded queue. An oversized generated replay abandons the room visibly without writing a player record.

Idle rooms expire after ten minutes and all development rooms after one hour, releasing seats/replays. These are resource bounds, not competitive forfeits. Disconnected seats remain reserved while the existing thirty-second selection deadlines continue, including legal auto-picks. Local pause cannot stop the authority clock. Both seats must acknowledge a nonfinal replay to begin a new draft; no acknowledgment can select cards or submit a winner.

Before public play the Game Director must decide hosting/budget, online replay controls/pause synchronization and disconnect grace/forfeit policy. Then integrate room creation/joining, waiting/reconnect/error screens, shared draft state, pre-battle skill openings, 1× default/no-skip playback and result display. Add real browser-to-WSS tests and choose measured replay limits/capacity for the selected host. PvAI pause/mastery rules remain unchanged. Ranked matchmaking, persistence, cloud mastery, moderation and ratings require their own approved milestone.

Official networking references: [Godot WebSocketPeer](https://docs.godotengine.org/en/stable/classes/class_websocketpeer.html) and [Godot WebSocket tutorial](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).
