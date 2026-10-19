extends SceneTree

var failed := false
var db: Node
var clock := 100.0

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    test_protocol()
    test_privacy_and_sessions()
    test_deadlines_and_rules()
    test_full_match()
    test_disconnect_policy()
    if not failed:
        print("Private room authority tests passed: protocol, trusted setup, hidden picks, retries, seat ownership, reconnect, expiry, deadlines, simultaneous skills, whole game and exact-once results.")
    quit(1 if failed else 0)

func setup_command(kind: String, theme_index: int = 0) -> Dictionary:
    var commander: Dictionary = db.get_all_commanders()[theme_index]
    var cards: Array = []
    for card in db.get_cards_by_set(commander["signature_set_id"]):
        cards.append(card["id"])
    return {"v": PrivateProtocol.VERSION, "type": kind, "commander": commander["id"], "cards": cards, "content": PrivateProtocol.content_hash(db)}

func pair(service: PrivateRoomService) -> String:
    service.handle(1, setup_command("create"), clock)
    var code: String = service.seats[1]["room"]
    var command := setup_command("join", 2)
    command["room"] = code
    service.handle(2, command, clock)
    return code

func action(kind: String, view: Dictionary, index: int = 0) -> Dictionary:
    return {"v": PrivateProtocol.VERSION, "type": kind, "round": view["round"], "revision": view["revision"], "index": index}

func test_protocol() -> void:
    var command := setup_command("create")
    check(PrivateProtocol.valid_command(command), "current content setup is valid")
    for replacement in [null, [], "pick", {"v": true, "type": "sync"}, {"v": PrivateProtocol.VERSION + 1, "type": "sync"}, {"v": PrivateProtocol.VERSION, "type": "result", "winner": "player"}, {"v": PrivateProtocol.VERSION, "type": "pick", "round": 1, "revision": 1, "index": 0.5}]:
        var bytes := JSON.stringify(replacement).to_utf8_buffer()
        check(not PrivateProtocol.valid_command(PrivateProtocol.read_json(bytes)), "reject malformed/version/forged/fractional commands")
    check(PrivateProtocol.read_json("{".to_utf8_buffer()).is_empty(), "malformed JSON returns an error without logging a parser failure")
    check(PrivateProtocol.read_json(" ".repeat(PrivateProtocol.MAX_COMMAND_BYTES + 1).to_utf8_buffer()).is_empty(), "input size bounded before parsing")
    var hash_before := PrivateProtocol.content_hash(db)
    var card_id: String = command["cards"][0]
    db.cards[card_id]["unit_cap"] += 1
    check(hash_before != PrivateProtocol.content_hash(db), "gameplay changes invalidate content negotiation")
    db.cards[card_id]["unit_cap"] -= 1
    var client := PrivateRoomClient.new()
    check(client.open("ws://example.com:8080", db) == ERR_INVALID_PARAMETER, "remote plaintext connection refused")
    client.free()

func test_privacy_and_sessions() -> void:
    var service := PrivateRoomService.new(db)
    var invalid := setup_command("create")
    invalid["cards"][3] = invalid["cards"][0]
    check(service.handle(1, invalid, clock)[0]["message"]["code"] == "invalid_loadout" and service.rooms.is_empty(), "duplicate loadout cannot allocate a room")
    invalid = setup_command("create")
    invalid["commander"] = "unknown"
    check(service.handle(1, invalid, clock)[0]["message"]["code"] == "invalid_loadout", "unknown Commander rejected")
    invalid = setup_command("create")
    invalid["cards"][0] = "unknown"
    check(service.handle(1, invalid, clock)[0]["message"]["code"] == "invalid_loadout", "unknown card rejected")
    invalid = setup_command("create")
    invalid["content"] = "stale"
    check(service.handle(1, invalid, clock)[0]["message"]["code"] == "content_mismatch", "mismatched build cannot enter")
    var messages := service.handle(1, setup_command("create"), clock)
    var session: Dictionary = messages[0]["message"].duplicate(true)
    var code: String = session["room"]
    var token: String = session["token"]
    var join := setup_command("join", 2)
    join["room"] = code
    service.handle(2, join, clock)
    check(service.handle(3, join, clock)[0]["message"]["code"] == "room_unavailable", "third seat cannot replace a player")
    var game: PrivateMatch = service.rooms[code]["game"]
    var rival_before: Dictionary = game.view_for("opponent", clock)["rival"]
    var stale := action("skill", game.view_for("player", clock))
    stale["side"] = "opponent" # untrusted seat hint is ignored
    stale["unit_counts"] = {"forged": 999}
    messages = service.handle(1, stale, clock + 1)
    check(game.drafts["player"].commander_skill_used_this_round and not game.drafts["opponent"].commander_skill_used_this_round, "connection owns seat; forged side/stats ignored")
    check(game.view_for("opponent", clock)["rival"] == rival_before, "current skill and skill budget are hidden from rival")
    var points: int = game.drafts["player"].selection_points
    service.handle(1, stale, clock + 1)
    check(game.drafts["player"].selection_points == points, "retry cannot spend another point")
    service.handle(1, action("pick", game.view_for("player", clock)), clock + 2)
    check(game.view_for("opponent", clock)["rival"] == rival_before, "current units remain hidden")
    for message in messages:
        check(not message["message"].has("token"), "state broadcasts never include credentials")
    var view := game.view_for("player", clock)
    view["self"]["unit_counts"]["forged"] = 999
    view["offer"].clear()
    check(not game.drafts["player"].unit_counts.has("forged") and not game.drafts["player"].current_offer.is_empty(), "views cannot mutate authoritative drafts")
    var resume := {"v": PrivateProtocol.VERSION, "type": "resume", "room": code, "content": service.fingerprint, "token": token}
    check(service.handle(3, resume, clock)[0]["message"]["code"] == "session_unavailable", "live seat cannot be taken over")
    service.disconnect_peer(1, clock + 2)
    var stolen := resume.duplicate()
    stolen["token"] = "0".repeat(64)
    check(service.handle(3, stolen, clock + 2)[0]["message"]["code"] == "session_unavailable", "room code does not authorize reconnect")
    service.handle(3, resume, clock + 3)
    check(service.seats[3]["side"] == "player" and game.drafts["player"].selection_points == points - 1, "bearer resumes same state without duplicate actions")
    check(service.handle(1, action("pick", game.view_for("player", clock)), clock + 3)[0]["message"]["code"] == "not_seated", "old connection loses authority")
    service.tick(clock + PrivateRoomService.LIFETIME_SECONDS)
    check(service.rooms.is_empty() and service.seats.is_empty(), "development expiry frees rooms/sessions without profile writes")

func test_deadlines_and_rules() -> void:
    var service := PrivateRoomService.new(db)
    var code := pair(service)
    var game: PrivateMatch = service.rooms[code]["game"]
    var command := action("pick", game.view_for("player", clock))
    check(not game.act("player", command, clock + 30), "deadline-boundary click cannot beat expired server timer")
    game.tick(clock + 65)
    check(game.drafts["player"].selection_points == 1 and game.drafts["opponent"].selection_points == 1, "absolute deadlines catch up two selections for both seats")
    check(is_equal_approx(game.view_for("player", clock + 65)["selection_seconds"], 25.0), "remaining timer uses next absolute deadline")
    check(not game.drafts["player"].commander_skill_used_this_round, "timeouts never select skills")
    game.tick(clock + 90)
    var requests := service.pending_battles(clock + 90)
    check(requests.size() == 1 and service.pending_battles(clock + 90).is_empty(), "ready round is claimed exactly once")
    var draw := {"winner": "draw", "duration": 120.0, "events": [], "frames": []}
    var at := clock + 90
    for round_number in range(1, 6):
        if round_number > 1:
            at += 120
            game.tick(at)
            service.pending_battles(at)
        service.finish_battle(code, round_number, draw, at + 1)
        var losses := game.match_state.losses.duplicate()
        check(game.phase == "loading" and game.match_state.losses == losses, "download does not score or start playback")
        check(not game.act("player", action("continue", game.view_for("player", at)), at + 1), "early continue cannot skip a battle")
        for side in PrivateMatch.SIDES:
            check(game.act(side, action("ready", game.view_for(side, at)), at + 2), "download readiness accepted once per seat")
        check(game.phase == "playing" and game.play_at == at + 3, "both ready schedule shared future start")
        game.tick(game.play_until - 0.001)
        check(game.match_state.losses == losses, "heart result is hidden through the shared tail")
        at = game.play_until
        game.tick(at)
        var scored := game.match_state.losses.duplicate()
        game.tick(at + 1)
        check(service.finish_battle(code, round_number, draw, at).is_empty() and game.match_state.losses == scored, "duplicate completion/tick cannot cost another heart")
        for side in PrivateMatch.SIDES:
            var peer := 1 if side == "player" else 2
            var messages := service.handle(peer, action("continue", game.view_for(side, at)), at + 2)
            check(messages[0]["message"]["type"] == "state", "both result acknowledgments advance")
        at += 2
        if round_number >= 4:
            check(game.match_state.sudden_death and game.drafts["player"].selection_points == 3, "repeated Sudden Death draws preserve approved allowance")
        else:
            check(game.drafts["player"].selection_points == 4 and game.drafts["opponent"].selection_points == 4, "both drawn sides receive normal comeback picks")
        check(service.handle(1, {"v": PrivateProtocol.VERSION, "type": "replay", "round": game.match_state.round_number}, at)[0]["message"]["code"] == "replay_unavailable", "new draft cannot retrieve prior battle as current round")

func test_full_match() -> void:
    var service := PrivateRoomService.new(db, func(): return 3187)
    var code := pair(service)
    var game: PrivateMatch = service.rooms[code]["game"]
    var round_now := clock
    var rounds := 0
    while game.phase != "complete" and rounds < 16:
        rounds += 1
        for side in PrivateMatch.SIDES:
            if rounds == 1:
                check(game.act(side, action("skill", game.view_for(side, round_now)), round_now + 1), "both sides can prepare opening skill")
            while not game.drafts[side].is_phase_complete():
                check(game.act(side, action("pick", game.view_for(side, round_now)), round_now + 2), "legal hidden draft choice")
        var requests := service.pending_battles(round_now + 3)
        check(requests.size() == 1, "one simulation per revealed round")
        if requests.is_empty():
            break
        var request: Dictionary = requests[0]
        var battle := CombatSimulator.new().simulate(request["player"], request["opponent"], request["seed"], request["balance"])
        if rounds == 1:
            var skills := 0
            for event in battle["pre_battle"].get("events", []):
                if event.get("type") == "commander_skill":
                    skills += 1
            check(skills == 2, "existing simultaneous pre-battle rules preserved")
        service.finish_battle(code, rounds, battle, round_now + 4)
        var replay_messages := service.handle(1, {"v": PrivateProtocol.VERSION, "type": "replay", "round": rounds}, round_now + 4)
        var packet: PackedByteArray = replay_messages[0]["packet"]
        var decoded := PrivateProtocol.read_replay(packet)
        check(decoded.get("replay", {}).get("winner") == battle["winner"] and decoded.get("replay", {}).get("frames", []).size() == battle["frames"].size(), "compressed wire replay retains events, frames and authoritative winner")
        var track := BattleReplay.new()
        track.configure(decoded["replay"]["frames"], decoded["replay"]["events"])
        check(packet == service.handle(2, {"v": PrivateProtocol.VERSION, "type": "replay", "round": rounds}, round_now + 4)[0]["packet"], "both seats receive identical canonical replay")
        for side in PrivateMatch.SIDES:
            game.act(side, action("ready", game.view_for(side, round_now)), round_now + 5)
        var result_at: float = game.play_until
        game.tick(result_at)
        if game.phase == "complete":
            break
        var units: Dictionary = game.drafts["player"].unit_counts.duplicate()
        var buffs: Dictionary = game.drafts["player"].buff_stacks.duplicate()
        for side in PrivateMatch.SIDES:
            game.act(side, action("continue", game.view_for(side, round_now)), result_at + 1)
        check(game.drafts["player"].unit_counts == units and game.drafts["player"].buff_stacks == buffs, "army and buffs persist into next round")
        round_now = result_at + 2
    check(game.phase == "complete" and not game.match_state.winner.is_empty(), "two human seats complete a real multi-round game")
    check(game.match_state.history.size() == rounds, "one score entry per round")

func test_disconnect_policy() -> void:
    for late_battle in [false, true]:
        var service := PrivateRoomService.new(db)
        var code := pair(service)
        var game: PrivateMatch = service.rooms[code]["game"]
        game.match_state.start(1)
        game.tick(clock + 90)
        service.pending_battles(clock + 90)
        var battle := {"winner": "opponent", "duration": 100.0 if late_battle else 10.0, "events": [], "frames": []}
        service.finish_battle(code, 1, battle, clock + 91)
        for side in PrivateMatch.SIDES:
            game.act(side, action("ready", game.view_for(side, clock)), clock + 92)
        service.disconnect_peer(2, clock + 94)
        service.tick(clock + 153.999)
        if late_battle:
            check(game.phase == "playing", "disconnect has the full sixty-second grace")
        service.tick(clock + 300)
        check(game.match_state.winner == ("player" if late_battle else "opponent"), "earlier battle completion or disconnect deadline wins temporal ordering")
        check(game.end_reason == ("disconnect_forfeit" if late_battle else "battle"), "forfeit never overwrites an earlier final battle")
        var winner := game.match_state.winner
        service.tick(clock + 301)
        check(game.match_state.winner == winner, "forfeit is idempotent")
    var service := PrivateRoomService.new(db)
    var code := pair(service)
    var token: String = service.rooms[code]["tokens"]["opponent"]
    service.disconnect_peer(2, clock + 1)
    service.handle(3, {"v": PrivateProtocol.VERSION, "type": "resume", "room": code, "content": service.fingerprint, "token": token}, clock + 60)
    service.tick(clock + 61)
    check(service.rooms[code]["game"].phase != "complete", "reconnect just inside grace cancels its deadline")
    service.disconnect_peer(1, clock + 62)
    service.disconnect_peer(3, clock + 62)
    service.tick(clock + 122)
    check(service.rooms[code]["game"].end_reason == "both_disconnected" and service.rooms[code]["game"].match_state.winner.is_empty(), "simultaneous abandoned seats cancel without fabricated winner")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
