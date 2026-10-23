extends "res://tools/capture_ui.gd"

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
    var menu := root.get_node("GameMenu")
    state.commander_progress = CommanderProgress.new(db, "")
    state.local_store = LocalMatchStore.new("")
    audio.set_interface_text_scale(1.0)
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    await save_image("experience_menu")
    menu.open_settings()
    await save_image("experience_settings")
    var larger: CheckButton = menu._body.find_child("LargerText", true, false)
    larger.button_pressed = true
    await save_image("experience_settings_large")
    menu.close()
    audio.set_interface_text_scale(1.0)
    state.select_commander("commander_water_01")
    state.equip_starter_army()
    state.match_preferences.redraw_experiment = true
    state.begin_match(773)
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    await save_image("experience_continue")
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("experience_redraw")
    state.draft.select_offer(0)
    state.draft.use_commander_skill()
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    current_scene._advance_prelude(BattlePrelude.DURATION)
    audio.effects_intensity = 0.35
    menu._apply_accessibility()
    current_scene._playback_time = minf(3, current_scene._duration * 0.5)
    current_scene._advance_frames()
    current_scene._advance_events()
    current_scene._update_timer_label()
    await save_image("experience_low_effects")
    current_scene._process(current_scene._duration + current_scene._tail_length + 1)
    current_scene._open_report()
    await save_image("experience_recap")
    audio.set_interface_text_scale(1.2)
    root.size = Vector2i(960, 540)
    root.content_scale_size = root.size
    await save_image("experience_recap_compact")
    current_scene.report_view.close()
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    state.begin_next_round()
    for card in db.get_cards_by_ids(state.army.get_cards()):
        state.draft.unit_counts[str(card["id"])] = int(card["unit_cap"])
    for id in ["buff_attack_speed", "buff_movement_speed"]:
        state.draft.buff_stacks[id] = 100
    state.draft.current_offer.assign([{"type": "buff", "id": "buff_attack_speed"}, {"type": "buff", "id": "buff_movement_speed"}, {"type": "buff", "id": "buff_attack"}])
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("experience_power_large")
    root.size = Vector2i(960, 540)
    root.content_scale_size = root.size
    await save_image("experience_power_compact")
    menu.open_settings()
    await save_image("experience_settings_compact")
    menu.open_insights()
    await save_image("experience_insights")
    menu.close()
    audio.set_interface_text_scale(1.0)
    audio.effects_intensity = 1.0
    menu._apply_accessibility()
    print("P0/P1 native captures saved: ", output_dir)
    quit(0)
