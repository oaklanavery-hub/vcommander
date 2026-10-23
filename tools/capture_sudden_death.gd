extends "res://tools/capture_battle_fx.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    var state := root.get_node("GameState")
    var db := root.get_node("ContentDatabase")
    var audio := root.get_node("GameAudio")
    state.commander_progress = CommanderProgress.new(db, "")
    state.local_store = LocalMatchStore.new("")
    state.match_preferences = MatchPreferences.new("")
    state.match_insights = MatchInsights.new("")
    audio.set_interface_text_scale(1.0)
    state.select_commander("commander_water_01")
    state.equip_starter_army()
    state.begin_match(204757)
    # Isolated presentation fixture: legal rosters, four drawn rounds, mixed
    # cohorts. Huge accumulated HP keeps this visual review alive past 2:00.
    for index in range(4):
        while not state.draft.is_phase_complete():
            state.draft.auto_select()
        state.match_state.begin_battle()
        state.match_state.resolve_round("draw", 120)
        state.begin_next_round()
    for draft in [state.draft, state.opponent.draft]:
        for id in draft.unit_counts:
            draft.unit_counts[id] = mini(2, int(draft.card_definitions[id]["unit_cap"]))
        for id in draft.buff_stacks:
            draft.buff_stacks[id] = 2
            draft.sudden_death_buff_stacks[id] = 1
        draft.buff_stacks["buff_health"] = 30
        draft.sudden_death_buff_stacks["buff_health"] = 4
    state.draft.current_offer.assign([{"type": "buff", "id": "buff_attack"}, {"type": "buff", "id": "buff_health"}, {"type": "buff", "id": "buff_attack_speed"}])
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("sudden_draft")
    state.draft.current_offer.assign([{"type": "buff", "id": "buff_defense"}, {"type": "buff", "id": "buff_movement_speed"}, {"type": "buff", "id": "buff_attack"}])
    current_scene._refresh_all()
    await save_image("sudden_powers")
    root.size = Vector2i(1024, 600)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.2)
    await save_image("sudden_compact")
    for button in current_scene.offer_row.get_children():
        if button.get_script() == load("res://scripts/presentation/buff_tile.gd"):
            for label in button._body.get_children():
                if label is Label and label.get_global_rect().end.x > button.get_global_rect().end.x:
                    push_error("Enhanced power text exceeds compact card bounds")
                    quit(1)
                    return
        if button.get_global_rect().end.y > root.size.y + 1:
            push_error("Enhanced power card exceeds compact viewport")
            quit(1)
            return
    audio.set_interface_text_scale(1.0)
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    state.draft.current_offer.clear()
    state.draft.selection_points = 0
    state.draft.commander_skill_used_this_round = true
    state.draft.commander_skill_uses = mini(2, state.draft.commander_skill_uses + 1)
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    current_scene._advance_prelude(BattlePrelude.DURATION)
    await save_image("sudden_battle")
    if current_scene._duration < 125 or int(state.battle_result["round_time_limit"]) != 180:
        push_error("Sudden Death visual fixture must reach the extended battle clock")
        quit(1)
        return
    seek(current_scene, 125)
    await save_image("sudden_frost_late")
    if current_scene.battlefield.frost_coverage() != 1.0:
        push_error("Frozen Field must cover the whole extended battle")
        quit(1)
        return
    current_scene._process(current_scene._duration + current_scene._tail_length + 0.1)
    await save_image("sudden_result")
    var menu := root.get_node("GameMenu")
    menu.open_help()
    await save_image("sudden_help")
    print("Sudden Death native review passed: seven views, all five enhanced powers, mixed roster, compact/larger-text bounds, actual 3:00 clock, full-field frost after 2:00 and result/help.")
    quit()
