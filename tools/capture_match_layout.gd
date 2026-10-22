extends "res://tools/capture_ui.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var state := root.get_node("GameState")
    var db := root.get_node("ContentDatabase")
    state.commander_progress = CommanderProgress.new(db, "")
    state.select_commander("commander_slime_01")
    state.equip_starter_army()
    state.begin_match(281)
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("layout_draft")
    while not state.draft.is_phase_complete():
        current_scene._select_offer(0)
    await save_image("layout_ready")
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    current_scene._advance_prelude(BattlePrelude.DURATION)
    current_scene._playback_time = minf(3, current_scene._duration * 0.5)
    current_scene._advance_frames()
    current_scene._advance_events()
    current_scene._update_timer_label()
    await save_image("layout_battle")
    current_scene._inspect_unit(current_scene.battlefield.visible_units()[0])
    await save_image("layout_inspection")
    current_scene._close_inspection()
    current_scene._process(current_scene._duration + current_scene._tail_length + 1)
    await save_image("layout_result")
    state.begin_next_round()
    for buff in db.get_all_buffs():
        state.draft.buff_stacks[str(buff["id"])] = 17
        state.opponent.draft.buff_stacks[str(buff["id"])] = 19
    state.opponent_public_side = state.opponent.get_side()
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("layout_powercards")
    print("Match layout native views: draft, ready, live battle, inspection, result and five-power rosters.")
    quit(0)
