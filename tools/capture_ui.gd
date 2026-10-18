extends SceneTree
var output_dir := "user://visual_qa"

func _init() -> void:
    call_deferred("run")

func save_image(filename: String) -> void:
    for index in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(output_dir.path_join(filename + ".png"))
    if error != OK:
        push_error("Visual capture failed: " + filename)
        quit(1)

func capture(scene_path: String, filename: String) -> void:
    change_scene_to_file(scene_path)
    await scene_changed
    await save_image(filename)

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = "res://" + output_dir
    output_dir = ProjectSettings.globalize_path(output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    var menu = root.get_node("GameMenu")
    await capture("res://scenes/main_menu/main_menu.tscn", "menu")
    var audio = root.get_node("GameAudio")
    var reduced: bool = audio.reduced_motion
    var showcase = current_scene.get_node("Margin/Main/Commanders/Showcase")
    showcase.set_process(false)
    audio.reduced_motion = false
    showcase._clock = 1.2
    showcase.queue_redraw()
    await save_image("menu_motion_1")
    showcase._clock = 2.4
    showcase.queue_redraw()
    await save_image("menu_motion_2")
    audio.reduced_motion = true
    showcase.queue_redraw()
    await save_image("menu_reduced_motion")
    audio.reduced_motion = reduced
    showcase.set_process(true)
    menu.open_help()
    await save_image("help")
    menu.close()
    menu.open_settings()
    await save_image("settings")
    menu.close()
    await capture("res://scenes/commander_select/commander_select.tscn", "commander")
    state.select_commander("commander_fire_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    await capture("res://scenes/army_builder/army_builder.tscn", "army")
    state.begin_match(1729)
    await capture("res://scenes/draft/draft.tscn", "draft")
    menu.open_pause()
    await save_image("pause")
    menu.close()
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.run_battle()
    await capture("res://scenes/combat/combat.tscn", "battle")
    current_scene._playback_time = minf(6.0, float(state.battle_result.get("duration", 0)) * 0.5)
    current_scene._advance_frames()
    current_scene._advance_events()
    current_scene._paused = true
    await save_image("combat_effects")
    current_scene._paused = false
    current_scene._process(BattlePrelude.DURATION)
    current_scene._process(current_scene._duration + 1.0)
    await save_image("result")
    print("Visual captures saved: ", output_dir)
    quit(0)
