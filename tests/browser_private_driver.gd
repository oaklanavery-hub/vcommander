extends SceneTree

# Export-only QA entry point, selected explicitly by the CI HTML test server.
# Normal game startup never loads or executes this driver.
var session: Node
var ui: Control
var role := "host"
var code := ""
var started := false
var prepared_skill := false
var initial_records: Dictionary = {}
var _published_at := -1000

func _init() -> void:
    call_deferred("run")

func run() -> void:
    print("Browser PvP driver starting: ", OS.get_cmdline_user_args())
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--role="):
            role = argument.trim_prefix("--role=")
        elif argument.begins_with("--room="):
            code = argument.trim_prefix("--room=")
    session = root.get_node("OnlineSession")
    print("Browser PvP endpoint: ", session.endpoint)
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    for commander in db.get_all_commanders():
        initial_records[commander["id"]] = state.commander_progress.record(commander["id"])
    var commander: Dictionary = db.get_all_commanders()[0 if role == "host" else 2]
    state.select_commander(commander["id"])
    state.clear_army()
    for card in db.get_cards_by_set(commander["signature_set_id"]):
        state.equip_card(card["id"])
    change_scene_to_file("res://scenes/online/private_room.tscn")
    await scene_changed
    await process_frame
    ui = current_scene
    if role == "host":
        ui.create_button.pressed.emit()
    else:
        ui.code_input.text = code
        ui.join_button.pressed.emit()
    started = true
    print("Browser PvP UI ready: ", role)

func _process(_delta: float) -> bool:
    if not started:
        return false
    var state: Dictionary = session.client.state
    if state.get("phase") == "draft" and session.can_act() and int(state.get("points", 0)) > 0:
        if not prepared_skill and not ui.skill_button.disabled:
            prepared_skill = true
            ui.skill_button.pressed.emit()
        elif ui.offers.get_child_count() > 0:
            ui.offers.get_child(0).pressed.emit()
    if Time.get_ticks_msec() - _published_at < 100:
        return false
    _published_at = Time.get_ticks_msec()
    var data := {"role": role, "room": session.client.room, "phase": state.get("phase", "connecting"),
        "side": state.get("you", ""), "play_at": state.get("play_at", 0), "play_until": state.get("play_until", 0),
        "battle_time": 0.0, "opening_time": 0.0, "finished": false, "controls_locked": false,
        "local_left": false, "winner": state.get("winner", ""), "round_winner": session.replay.get("winner", ""),
        "losses": state.get("losses", {}), "records_unchanged": true}
    var combat = ui.battle_screen
    if combat != null:
        data["battle_time"] = combat._playback_time
        data["opening_time"] = combat._prelude.elapsed
        data["finished"] = combat._finished
        data["controls_locked"] = not combat.pause_button.visible and not combat.speed_button.visible and combat._speed_index == 0
        var units: Array = combat._source.battle_result.get("frames", [])[0].get("units", [])
        var left := 0
        var right := 0
        for unit in units:
            if unit["side"] == "player" and float(unit["x"]) < 12:
                left += 1
            elif unit["side"] == "opponent" and float(unit["x"]) > 12:
                right += 1
        data["local_left"] = left > 0 and right > 0
    var db := root.get_node("ContentDatabase")
    var local := root.get_node("GameState")
    for commander in db.get_all_commanders():
        if local.commander_progress.record(commander["id"]) != initial_records[commander["id"]]:
            data["records_unchanged"] = false
    JavaScriptBridge.eval("window.vcommanderPvpQa = " + JSON.stringify(data) + ";", true)
    return false
