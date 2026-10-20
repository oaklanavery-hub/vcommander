extends SceneTree

var failed := false
var db: Node
var state: Node
var session: Node
var server := PrivateRoomServer.new()
var guest := PrivateRoomClient.new()
var virtual_now := 100.0
var output_dir := ""

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = ProjectSettings.globalize_path("res://" + argument.trim_prefix("--output-dir="))
            DirAccess.make_dir_recursive_absolute(output_dir)
    db = root.get_node("ContentDatabase")
    state = root.get_node("GameState")
    session = root.get_node("OnlineSession")
    session.available = true # Explicit isolated QA seam; ordinary entry remains Coming Soon.
    for path in ["res://scripts/network/private_room_screen.gd", "res://scripts/network/shared_battle_presentation.gd", "res://scripts/combat/combat_screen.gd"]:
        var script = load(path)
        if script == null or not script.can_instantiate():
            check(false, "presentation script compiles with autoloads: " + path)
            guest.free()
            quit(1)
            return
    var profile: Dictionary = {}
    for commander in db.get_all_commanders():
        profile[commander["id"]] = state.commander_progress.record(commander["id"])
    check(server.start(db, 0) == OK, "presentation fixture binds loopback")
    server.time_source = func(): return virtual_now
    server.service = PrivateRoomService.new(db, func(): return 3187)
    session.endpoint = "ws://127.0.0.1:%d" % server.port
    root.add_child(guest)
    guest.set_process(false)
    var commander: Dictionary = db.get_all_commanders()[0]
    state.select_commander(commander["id"])
    state.clear_army()
    for card in db.get_cards_by_set(commander["signature_set_id"]):
        state.equip_card(card["id"])
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await process_frame
    check(current_scene.friend_button.visible and not current_scene.friend_button.disabled, "configured endpoint exposes ready friend entry")
    await capture("pvp_warband")
    current_scene.friend_button.pressed.emit()
    await scene_changed
    await process_frame
    var ui = current_scene
    await capture("pvp_lobby")
    check_bounds(ui.main, "room lobby")
    ui.create_button.pressed.emit()
    if not await until(func(): return session.client.state.get("phase") == "waiting", "create-room UI receives invitation"):
        finish()
        return
    check(ui.copy_button.visible and ui.room_label.text.contains(session.client.room), "host can see/copy room code")
    await capture("pvp_waiting")
    check(guest.open(session.endpoint, db) == OK, "friend socket opens")
    await until(func(): return guest.connected(), "friend socket handshakes")
    var guest_commander: Dictionary = db.get_all_commanders()[2]
    var cards: Array = []
    for card in db.get_cards_by_set(guest_commander["signature_set_id"]):
        if not card.has("mastery_unlock"):
            cards.append(card["id"])
    guest.join_room(session.client.room, guest_commander["id"], cards)
    if not await until(func(): return session.client.state.get("phase") == "draft" and guest.state.get("phase") == "draft", "friend joins UI draft"):
        finish()
        return
    check(ui.offers.get_child_count() == 3, "real server offers become three selectable cards")
    check(ui.timer_label.get_line_count() == 1, "online countdown stays on one readable line")
    check_bounds(ui.main, "online draft")
    await capture("pvp_draft")
    var revision: int = session.client.state["revision"]
    ui.skill_button.pressed.emit()
    await until(func(): return int(session.client.state["revision"]) > revision, "UI prepares server-owned skill")
    var menu := root.get_node("GameMenu")
    menu.open_pause()
    check(menu._body.get_child(1).text.contains("online match continues"), "menu explains online clock")
    var before_menu: int = session.client.state["revision"]
    var menu_key := InputEventKey.new()
    menu_key.pressed = true
    menu_key.keycode = KEY_1
    ui._unhandled_key_input(menu_key)
    server.poll()
    await process_frame
    server.poll()
    await process_frame
    check(int(session.client.state["revision"]) == before_menu, "modal menu blocks draft hotkeys while networking continues")
    await capture("pvp_menu")
    virtual_now += 30.01
    server.poll()
    await until(func(): return int(session.client.state["points"]) == 1, "draft timer keeps running under menu")
    menu.close()
    for client in [session.client, guest]:
        for pick_index in range(4):
            if int(client.state.get("points", 0)) <= 0:
                break
            var old: int = client.state["revision"]
            if client == session.client:
                ui.offers.get_child(0).pressed.emit()
            else:
                client.act("pick", 0)
            if not await until(func(): return int(client.state.get("revision", 0)) > old, "draft click receives authority acknowledgment"):
                finish()
                return
    if not await until(func(): return not session.replay.is_empty() and guest.state.get("replay_available", false), "UI downloads authoritative replay"):
        finish()
        return
    guest.battle_received.connect(func(_round, _replay): guest.act("ready"))
    guest.send({"type": "replay", "round": guest.state["round"]})
    if not await until(func(): return session.client.state.get("phase") == "playing" and ui.battle_screen != null, "both downloads create shared battle view"):
        finish()
        return
    var combat = ui.battle_screen
    check(not combat.speed_button.visible and not combat.pause_button.visible and combat._speed_index == 0, "online battle has fixed 1x and no local pause/speed")
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_4
    combat._unhandled_key_input(key)
    check(combat._speed_index == 0, "speed hotkey cannot change shared playback")
    var flip := PrivatePerspective.battle_for_player(session.replay, "opponent")
    var original: Dictionary = session.replay["frames"][0]["units"][0]
    var mirrored: Dictionary = flip["frames"][0]["units"][0]
    check(original["side"] != mirrored["side"] and is_equal_approx(float(original["x"]) + float(mirrored["x"]), 24.0), "guest viewpoint mirrors ownership and exact coordinates")
    virtual_now = float(session.client.state["play_at"]) + 0.8
    await sync_clock()
    await process_frame
    check(combat._prelude.active() and combat._playback_time == 0, "shared Commander opening holds battle time at zero")
    await capture("pvp_opening")
    virtual_now = float(session.client.state["play_at"]) + combat._prelude.duration + 4.0
    await sync_clock()
    await process_frame
    check(absf(combat._playback_time - 4) < 0.2, "UI follows shared server time at 1x")
    await capture("pvp_battle")
    guest.close()
    await until(func(): return not session.client.state.get("connected", {}).get("opponent", true), "rival disconnect reaches battle view")
    await capture("pvp_reconnect")
    check(combat.seed_label.visible and combat.seed_label.text.contains("reconnecting"), "rival grace is visible during battle")
    guest.open(session.endpoint, db)
    await until(func(): return guest.connected(), "friend reconnects")
    guest.resume_room()
    await until(func(): return session.client.state.get("connected", {}).get("opponent", false), "same friend seat resumes")
    virtual_now = float(session.client.state["play_until"]) + 0.1
    await sync_clock()
    if not await until(func(): return combat._finished, "result appears only after shared timeline"):
        finish()
        return
    check(not combat.mastery_panel.visible and combat.next_button.visible, "friend result has continuation without local XP")
    check_bounds(combat.get_node("Margin/Main"), "shared result")
    await capture("pvp_result")
    var final_state: Dictionary = session.client.state.duplicate(true)
    session.client.state["phase"] = "complete"
    session.client.state["end_reason"] = "disconnect_forfeit"
    session.client.state["winner"] = "player"
    session.status = "Friend match complete. No mastery or ranked rewards."
    session.changed.emit()
    await process_frame
    check(ui.wait_label.text.contains("did not reconnect"), "forfeit result clearly explains the outcome")
    await capture("pvp_forfeit")
    session.client.state = final_state
    for item in db.get_all_commanders():
        check(state.commander_progress.record(item["id"]) == profile[item["id"]], "all online UI paths leave PvAI mastery untouched")
    if not failed:
        print("Private presentation tests passed: real create/join/draft clicks, bounds, online menu timer, shared opening/1x/hotkeys, mirrored guest, reconnect/result/forfeit views and isolated mastery.")
    finish()

func sync_clock() -> void:
    session.client.send({"type": "clock", "at": Time.get_ticks_msec()})
    await until(func(): return absf(session.client.server_time() - virtual_now) < 0.1, "clock sample reaches presentation")

func until(predicate: Callable, label: String) -> bool:
    var deadline := Time.get_ticks_msec() + 5000
    while not predicate.call() and Time.get_ticks_msec() < deadline:
        server.poll()
        guest.poll()
        await create_timer(0.005).timeout
    var passed: bool = predicate.call()
    check(passed, label)
    return passed

func capture(name: String) -> void:
    if output_dir.is_empty():
        return
    await process_frame
    await process_frame
    await process_frame
    var picture := root.get_texture().get_image()
    check(picture.save_png(output_dir.path_join(name + ".png")) == OK, "native capture saved")

func check_bounds(control: Control, label: String) -> void:
    var rect := control.get_global_rect()
    check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= 1281 and rect.end.y <= 721, label + " fits desktop: " + str(rect))

func finish() -> void:
    root.get_node("GameMenu").close()
    session.active = false
    session.client.close(true)
    guest.close(true)
    guest.free()
    server.stop()
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
