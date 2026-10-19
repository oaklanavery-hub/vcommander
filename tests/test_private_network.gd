extends SceneTree

var failed := false
var server := PrivateRoomServer.new()
var first := PrivateRoomClient.new()
var second := PrivateRoomClient.new()
var observer := PrivateRoomClient.new()
var errors: Array = []
var first_replays: Dictionary = {}
var second_replays: Dictionary = {}
var db: Node

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    var profile: Dictionary = {}
    var progress = root.get_node("GameState").commander_progress
    for commander in db.get_all_commanders():
        profile[commander["id"]] = progress.record(commander["id"])
    var error := server.start(db, 0)
    check(error == OK and server.port > 0, "loopback service binds an ephemeral port")
    if error != OK:
        finish()
        return
    server.service = PrivateRoomService.new(db, func(): return 3187)
    for client in [first, second, observer]:
        root.add_child(client)
        client.set_process(false)
        client.failed.connect(func(code): errors.append(code))
        check(client.open("ws://127.0.0.1:%d" % server.port, db) == OK, "client opens WebSocket")
    first.battle_received.connect(func(round_number, replay): first_replays[round_number] = replay)
    second.battle_received.connect(func(round_number, replay): second_replays[round_number] = replay)
    if not await until(func(): return first.connected() and second.connected() and observer.connected(), "three connections handshake"):
        finish()
        return
    var host := setup(0)
    var guest := setup(2)
    first.create_room(host["commander"], host["cards"])
    if not await until(func(): return not first.room.is_empty(), "host gets private room/session"):
        finish()
        return
    second.join_room(first.room.to_lower(), guest["commander"], guest["cards"])
    if not await until(func(): return first.state.get("phase") == "draft" and second.state.get("phase") == "draft", "both enter the same draft"):
        finish()
        return
    observer.join_room(first.room, host["commander"], host["cards"])
    await until(func(): return errors.has("room_unavailable"), "full room rejects third seat")
    observer.close(true)
    errors.clear()
    check(first.state["you"] == "player" and second.state["you"] == "opponent", "server assigns seats")
    var rival: Dictionary = second.state["rival"].duplicate(true)
    var revision: int = first.state["revision"]
    first.act("skill")
    await until(func(): return int(first.state.get("revision", 0)) > revision, "skill accepted")
    check(second.state["rival"] == rival, "WebSocket projection hides current skill")
    var prior: Dictionary = second.state.duplicate(true)
    second.close()
    await until(func(): return server.service.seats.size() == 1, "disconnect detaches only its connection")
    check(second.open("ws://127.0.0.1:%d" % server.port, db) == OK, "reconnect socket opens")
    await until(func(): return second.connected(), "reconnect handshake")
    second.resume_room()
    await until(func(): return server.service.seats.size() == 2, "token restores same reserved seat")
    check(second.state.get("points") == prior["points"] and second.state.get("revision") == prior["revision"], "reconnect preserves choices and timer state")
    errors.clear()
    var rounds := 0
    while first.state.get("phase") != "complete" and rounds < 16:
        rounds += 1
        for client in [first, second]:
            # Bound every fixture loop; an illegal action must fail, not hang CI.
            for pick_number in range(4):
                if int(client.state.get("points", 0)) <= 0:
                    break
                var old_revision: int = client.state["revision"]
                client.act("pick", 0)
                if not await until(func(): return int(client.state.get("revision", 0)) > old_revision, "server acknowledges pick"):
                    finish()
                    return
        if not await until(func(): return first.state.get("replay_available", false) and second.state.get("replay_available", false), "background worker produces one battle"):
            finish()
            return
        first.send({"type": "replay", "round": rounds})
        second.send({"type": "replay", "round": rounds})
        if not await until(func(): return first_replays.has(rounds) and second_replays.has(rounds), "both receive compressed replay"):
            finish()
            return
        check(JSON.stringify(first_replays[rounds]) == JSON.stringify(second_replays[rounds]), "both clients receive identical battle events/frames")
        check(first.state["losses"] == second.state["losses"], "hearts agree after authoritative scoring")
        # Acknowledge through the development seam; public replay policy pending.
        if first.state.get("phase") == "complete":
            break
        first.act("continue")
        second.act("continue")
        if not await until(func(): return int(first.state.get("round", 0)) == rounds + 1 and int(second.state.get("round", 0)) == rounds + 1, "both acknowledge next draft"):
            finish()
            return
    check(first.state.get("phase") == "complete" and first.state.get("winner") == second.state.get("winner"), "two connections complete a real multi-round match")
    check(errors.is_empty(), "normal two-player flow has no protocol errors: " + str(errors))
    for commander in db.get_all_commanders():
        check(progress.record(commander["id"]) == profile[commander["id"]], "private PvP cannot write personal PvAI mastery")
    if not failed:
        print("Private WebSocket integration passed: real handshake, room code, hidden draft, third-seat rejection, reconnect, worker simulation, identical compressed replays, ", rounds, " rounds, shared winner and isolated PvAI records.")
    finish()

func setup(index: int) -> Dictionary:
    var commander: Dictionary = db.get_all_commanders()[index]
    var cards: Array = []
    for card in db.get_cards_by_set(commander["signature_set_id"]):
        cards.append(card["id"])
    return {"commander": commander["id"], "cards": cards}

func until(predicate: Callable, label: String) -> bool:
    var deadline := Time.get_ticks_msec() + 5000
    while not predicate.call() and Time.get_ticks_msec() < deadline:
        server.poll()
        for client in [first, second, observer]:
            client.poll()
        await create_timer(0.005).timeout
    var passed: bool = predicate.call()
    check(passed, label)
    return passed

func finish() -> void:
    for client in [first, second, observer]:
        client.close(true)
        client.free()
    server.stop()
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
