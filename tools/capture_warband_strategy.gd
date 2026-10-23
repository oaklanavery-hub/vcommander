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
    var menu := root.get_node("GameMenu")
    var audio := root.get_node("GameAudio")
    state.commander_progress = CommanderProgress.new(root.get_node("ContentDatabase"), "")
    state.local_store = LocalMatchStore.new("")
    state.match_preferences = MatchPreferences.new("")
    state.match_insights = MatchInsights.new("")
    audio.set_interface_text_scale(1.0)
    state.select_commander("commander_fire_01")
    state.equip_starter_army()
    await capture("res://scenes/army_builder/army_builder.tscn", "strategy_builder")
    menu.open_warband_guide()
    await modal_image("strategy_guide")
    menu.open_ability_glossary()
    await modal_image("strategy_glossary")
    menu.close()
    state.clear_army()
    for id in ["card_fire_01", "card_fire_03", "card_water_03", "card_water_05"]:
        state.equip_card(id)
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await save_image("strategy_mixed")
    menu.open_warband_guide()
    await modal_image("strategy_mixed_guide")
    menu.close()
    state.match_preferences.specialization_experiment = true
    state.begin_match(12345)
    for index in range(2):
        while not state.draft.is_phase_complete():
            state.draft.auto_select()
        state.run_battle()
        state.begin_next_round()
    await capture("res://scenes/draft/draft.tscn", "strategy_draft")
    current_scene._open_specializations()
    await modal_image("strategy_paths")
    root.size = Vector2i(1024, 600)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.2)
    await modal_image("strategy_paths_compact")
    var chosen: Button = menu._body.find_child("fire_cinder_circle", true, false)
    chosen.pressed.emit()
    await save_image("strategy_selected")
    state.leave_match()
    menu.open_settings()
    await process_frame
    var toggle: CheckButton = menu._body.find_child("SpecializationExperiment", true, false)
    if toggle == null or not toggle.button_pressed or toggle.disabled:
        push_error("Prototype setting is not available before the next adventure")
        quit(1)
        return
    menu._page_scroll.ensure_control_visible(toggle)
    await modal_image("strategy_settings")
    menu.open_insights()
    await modal_image("strategy_insights")
    menu.close()
    audio.set_interface_text_scale(1.0)
    print("Warband strategy native review passed: eleven views, compact/larger-text bounds and actual path purchase.")
    quit()

func modal_image(filename: String) -> void:
    await save_image(filename)
    var bounds: Rect2 = root.get_node("GameMenu")._page_panel.get_global_rect()
    if bounds.position.x < -1 or bounds.position.y < -1 or bounds.end.x > root.size.x + 1 or bounds.end.y > root.size.y + 1:
        push_error("Strategy modal exceeds viewport: " + filename + " " + str(bounds))
        quit(1)
