extends SceneTree

# Isolated benchmark entry point, mounted into the unchanged production image.
# Never called by run_private_server.gd and excluded from the Web export.
var server := PrivateRoomServer.new()
var output_dir := ""
var profile := "normal"
var expected_rooms := 1
var port := 10000
var listen_address := "127.0.0.1"
var offset := 0.0
var seeded: Dictionary = {}
var peak_jobs := 0
var longest_poll_ms := 0.0
var last_sample := -1.0
var playing_since := -1.0
var seed_index := 0

func _init() -> void:
    call_deferred("start")

func start() -> void:
    Engine.max_fps = 30
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
        elif argument.begins_with("--profile="):
            profile = argument.trim_prefix("--profile=")
        elif argument.begins_with("--rooms="):
            expected_rooms = int(argument.trim_prefix("--rooms="))
        elif argument.begins_with("--port="):
            port = int(argument.trim_prefix("--port="))
        elif argument == "--listen=0.0.0.0":
            listen_address = "0.0.0.0"
    if output_dir.is_empty() or profile not in ["normal", "earth", "slime", "mixed"] or expected_rooms not in [1, 2, 4]:
        push_error("Invalid isolated capacity fixture arguments")
        quit(1)
        return
    var db = root.get_node("ContentDatabase")
    if not db.load_errors.is_empty() or server.start(db, port, listen_address) != OK:
        push_error("Capacity fixture could not start")
        quit(1)
        return
    server.time_source = now
    server.service._seed_source = func():
        seed_index += 1
        return 7000 + seed_index
    var setups: Array = []
    for commander in db.get_all_commanders():
        var cards: Array = []
        var counts := {}
        for card in db.get_cards_by_set(commander["signature_set_id"]):
            cards.append(card["id"])
            counts[card["id"]] = card["unit_cap"]
        setups.append({"commander": commander["id"], "element": commander["element"], "cards": cards, "caps": counts})
    write_json("manifest.json", {"content": server.service.fingerprint, "setups": setups,
        "room_limit": server.service.room_limit, "profile": profile})
    sample()

func now() -> float:
    return Time.get_ticks_usec() / 1000000.0 + offset

func _process(_delta: float) -> bool:
    if server.service == null:
        return false
    if profile != "normal" and server.service.rooms.size() == expected_rooms:
        for code in server.service.rooms:
            var game: PrivateMatch = server.service.rooms[code]["game"]
            var key := "%s:%d" % [code, game.match_state.round_number]
            if game.phase != "draft" or seeded.has(key):
                continue
            # Synthetic late-game state at legal caps. Only this isolated fixture
            # seeds it; clients still use the normal skill/replay/ready protocol.
            for side in PrivateMatch.SIDES:
                var draft: DraftSystem = game.drafts[side]
                for card in draft.card_definitions.values():
                    draft.unit_counts[card["id"]] = int(card["unit_cap"])
                for buff in draft.buff_definitions.values():
                    draft.buff_stacks[buff["id"]] = int(buff.get("max_stacks", 3))
                draft.selection_points = 1
                draft.commander_skill_uses = mini(game.match_state.round_number - 1, 1)
                draft.commander_skill_used_this_round = false
                draft.current_offer.clear()
                game.public_sides[side] = game._combat_side(side, false)
            seeded[key] = true
            server._send(server.service._states(code, now()))
    var before := Time.get_ticks_usec()
    server.poll()
    longest_poll_ms = maxf(longest_poll_ms, (Time.get_ticks_usec() - before) / 1000.0)
    peak_jobs = maxi(peak_jobs, server._jobs.size())
    if profile != "normal":
        for code in server.service.rooms:
            var game: PrivateMatch = server.service.rooms[code]["game"]
            if game.phase == "replay":
                # Leave one legal card for the next draft so normal automatic
                # exhaustion cannot start a battle before this fixture seeds it.
                # The next frame restores the capped synthetic benchmark state.
                for draft in game.drafts.values():
                    var buff: Dictionary = draft.buff_definitions.values()[0]
                    draft.buff_stacks[buff["id"]] = maxi(0, int(buff.get("max_stacks", 3)) - 1)
    # Skip only the already-computed presentation wait, never combat work.
    var all_playing := server.service.rooms.size() == expected_rooms
    var latest_end := 0.0
    var playing := 0
    for room in server.service.rooms.values():
        var game: PrivateMatch = room["game"]
        all_playing = all_playing and game.phase in ["playing", "complete"]
        if game.phase == "playing":
            playing += 1
            latest_end = maxf(latest_end, game.play_until)
    var wall := Time.get_ticks_usec() / 1000000.0
    if all_playing and playing > 0:
        if playing_since < 0:
            playing_since = wall
        elif wall - playing_since >= 0.5:
            offset += maxf(0, latest_end + 0.01 - now())
            playing_since = -1
    else:
        playing_since = -1
    if wall - last_sample >= 0.25:
        last_sample = wall
        sample()
    return false

func sample() -> void:
    var stats := {"peak_jobs": peak_jobs, "longest_poll_ms": longest_poll_ms,
        "wall_seconds": Time.get_ticks_usec() / 1000000.0}
    for name in ["memory.current", "memory.peak", "memory.max", "cpu.max", "cpu.stat"]:
        var path: String = "/sys/fs/cgroup/" + str(name)
        if FileAccess.file_exists(path):
            # proc/sysfs files can advertise length zero despite having data.
            var file := FileAccess.open(path, FileAccess.READ)
            if file != null:
                var lines := ""
                while not file.eof_reached():
                    lines += file.get_line() + "\n"
                stats[name] = lines.strip_edges()
    write_json("server.json", stats)

func write_json(filename: String, value: Dictionary) -> void:
    var path := output_dir.path_join(filename)
    var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
    if file == null:
        push_error("Capacity fixture cannot write report")
        quit(1)
        return
    file.store_string(JSON.stringify(value))
    file.close()
    DirAccess.rename_absolute(path + ".tmp", path)

func _finalize() -> void:
    server.stop()
