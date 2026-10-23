extends Node

# Export-only QA scene, selected explicitly by the CI HTML test server.
# Normal game startup never loads or executes this driver.
var session: Node
var ui: Control
var role := "host"
var code := ""
var started := false
var prepared_skill := false
var initial_records: Dictionary = {}
var _published_at := -1000
var font_symbols_ready := false
var probe_stage := "prepare"

func _ready() -> void:
    call_deferred("run")

func run() -> void:
    print("Browser PvP driver starting: ", OS.get_cmdline_user_args())
    var tree := get_tree()
    var root := tree.root
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--role="):
            role = argument.trim_prefix("--role=")
        elif argument.begins_with("--room="):
            code = argument.trim_prefix("--room=")
        elif argument.begins_with("--probe-stage="):
            probe_stage = argument.trim_prefix("--probe-stage=")
    if role == "local":
        await _local_recovery_probe()
        return
    session = root.get_node("OnlineSession")
    session.available = true # Explicit isolated QA seam; ordinary entry remains Coming Soon.
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
    # Keep this QA controller alive beside the actual game scene.
    ui = load("res://scenes/online/private_room.tscn").instantiate()
    root.add_child(ui)
    tree.current_scene = ui
    await tree.process_frame
    # Verify the actual WebAssembly font chain; desktop OS fonts cannot stand in.
    var style = load("res://scripts/presentation/screen_style.gd")
    font_symbols_ready = true
    for font in [style.DISPLAY_FONT, ThemeDB.fallback_font]:
        for symbol in "←→♥♡★◇":
            font_symbols_ready = font_symbols_ready and font.has_char(symbol.unicode_at(0))
    if role == "host":
        ui.create_button.pressed.emit()
    else:
        ui.code_input.text = code
        ui.join_button.pressed.emit()
    started = true
    print("Browser PvP UI ready: ", role)

func _local_recovery_probe() -> void:
    var tree := get_tree()
    var state := tree.root.get_node("GameState")
    var db := tree.root.get_node("ContentDatabase")
    # This browser context is isolated by Playwright. Use the normal persistent
    # paths so a reload also exercises ordinary autoload pending-match recovery.
    state.match_preferences = MatchPreferences.new("")
    if probe_stage in ["prepare", "sudden_prepare"]:
        state.select_commander("commander_fire_01")
        state.equip_starter_army()
        state.match_preferences.redraw_experiment = true
        state.match_preferences.specialization_experiment = true
        state.begin_match(9007199254740999)
        for index in range(2):
            while not state.draft.is_phase_complete():
                state.draft.auto_select()
            state.run_battle()
            state.begin_next_round()
        var draft_ui = load("res://scenes/draft/draft.tscn").instantiate()
        tree.root.add_child(draft_ui)
        tree.current_scene = draft_ui
        await tree.process_frame
        draft_ui.set_process(false)
        draft_ui.specialization_button.pressed.emit()
        await tree.process_frame
        var menu := tree.root.get_node("GameMenu")
        var path_button: Button = menu._body.find_child("fire_cinder_circle", true, false)
        path_button.pressed.emit()
        draft_ui.queue_free()
        state.draft.select_offer(0)
        state.update_draft_clock(11.5)
        state.draft.redraw()
        if probe_stage == "sudden_prepare":
            # Controlled late-round fixture in an isolated browser profile.
            # The enhanced pick below goes through the actual draft button.
            while not state.draft.is_phase_complete():
                state.draft.auto_select()
            for draft in [state.draft, state.opponent.draft]:
                for id in draft.unit_counts:
                    draft.unit_counts[id] = int(draft.card_definitions[id]["unit_cap"])
            state.match_state.losses = {"player": 3, "opponent": 3}
            state.match_state.begin_battle()
            state.match_state.resolve_round("draw", 120)
            state.begin_next_round()
            var sudden_ui = load("res://scenes/draft/draft.tscn").instantiate()
            tree.root.add_child(sudden_ui)
            tree.current_scene = sudden_ui
            await tree.process_frame
            sudden_ui.set_process(false)
            sudden_ui.offer_row.get_child(0).pressed.emit()
            state.draft.redraw()
            state.update_draft_clock(11.5)
            sudden_ui.queue_free()
    ui = load("res://scenes/main_menu/main_menu.tscn").instantiate()
    tree.root.add_child(ui)
    tree.current_scene = ui
    await tree.process_frame
    await tree.process_frame
    var continuation := ui.find_child("ContinueAdventure", true, false) as Button
    var data := {"stage": probe_stage, "persistent": OS.is_userfs_persistent(), "continue_visible": continuation != null, "ok": false}
    if probe_stage in ["prepare", "sudden_prepare"]:
        data["snapshot"] = state.draft.snapshot()
        data["clock"] = state.draft_time_left
        data["hearts"] = state.match_state.losses.duplicate()
        data["opponent_snapshot"] = state.opponent.draft.snapshot()
        data["public_specialization"] = state.opponent_public_side.get("specialization", {}).duplicate(true)
        data["public_buffs"] = state.opponent_public_side.get("buffs", []).duplicate(true)
        data["pending"] = state.commander_progress.active_match().get("id", "")
        data["ok"] = continuation != null and state.local_store.last_error == OK and not str(data["pending"]).is_empty()
    elif continuation != null:
        continuation.pressed.emit()
        await tree.scene_changed
        tree.current_scene.set_process(false)
        await tree.process_frame
        await tree.process_frame
        data["snapshot"] = state.draft.snapshot()
        data["clock"] = state.draft_time_left
        data["hearts"] = state.match_state.losses.duplicate()
        data["opponent_snapshot"] = state.opponent.draft.snapshot()
        data["public_specialization"] = state.opponent_public_side.get("specialization", {}).duplicate(true)
        data["public_buffs"] = state.opponent_public_side.get("buffs", []).duplicate(true)
        data["pending"] = state.commander_progress.active_match().get("id", "")
        data["scene"] = tree.current_scene.name
        data["ok"] = tree.current_scene.name == "Draft" and state.draft.redraw_used and not state.draft.can_redraw() and state.draft.specialization_id == "fire_cinder_circle" and state.draft.specialization_enabled and not state.draft.can_specialize() and state.match_seed == 9007199254740999 and state.commander_progress.record("commander_fire_01")["played"] == 0
    if probe_stage in ["sudden_prepare", "sudden_restore"]:
        data["ok"] = bool(data["ok"]) and state.draft.sudden_death and state.draft.round_time_limit == 180 and state.draft.sudden_death_buff_stacks.values().any(func(n): return int(n) > 0)
    JavaScriptBridge.eval("window.vcommanderLocalQa = " + JSON.stringify(data) + ";", true)

func _process(_delta: float) -> void:
    if not started:
        return
    var state: Dictionary = session.client.state
    if state.get("phase") == "draft" and session.can_act() and int(state.get("points", 0)) > 0:
        if not prepared_skill and not ui.skill_button.disabled:
            prepared_skill = true
            ui.skill_button.pressed.emit()
        elif ui.offers.get_child_count() > 0:
            ui.offers.get_child(0).pressed.emit()
    if Time.get_ticks_msec() - _published_at < 100:
        return
    _published_at = Time.get_ticks_msec()
    var data := {"role": role, "room": session.client.room, "phase": state.get("phase", "connecting"),
        "side": state.get("you", ""), "play_at": state.get("play_at", 0), "play_until": state.get("play_until", 0),
        "battle_time": 0.0, "opening_time": 0.0, "finished": false, "controls_locked": false,
        "local_left": false, "winner": state.get("winner", ""), "round_winner": session.replay.get("winner", ""),
        "losses": state.get("losses", {}), "records_unchanged": true, "font_symbols_ready": font_symbols_ready}
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
    var db := get_tree().root.get_node("ContentDatabase")
    var local := get_tree().root.get_node("GameState")
    for commander in db.get_all_commanders():
        if local.commander_progress.record(commander["id"]) != initial_records[commander["id"]]:
            data["records_unchanged"] = false
    JavaScriptBridge.eval("window.vcommanderPvpQa = " + JSON.stringify(data) + ";", true)
