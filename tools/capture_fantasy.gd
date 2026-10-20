extends "res://tools/capture_ui.gd"

func save_checked(name: String) -> void:
    await save_image(name)
    var main: Control = current_scene.get_node("Margin/Main")
    var bounds := main.get_global_rect()
    if bounds.position.x < -1 or bounds.position.y < -1 or bounds.end.x > 1281 or bounds.end.y > 721:
        push_error("Fantasy view overflow: " + name + " " + str(bounds))
        quit(1)

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    state.commander_progress = CommanderProgress.new(db, "")
    change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    await scene_changed
    for commander in db.get_all_commanders():
        current_scene._select_commander(str(commander["id"]))
        await save_checked("fantasy_gallery_" + str(commander["element"]))
    state.select_commander("commander_fire_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    state.begin_match(1729)
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    current_scene._process(BattlePrelude.DURATION)
    current_scene._playback_time = minf(6, current_scene._duration * 0.5)
    current_scene._advance_frames()
    current_scene._advance_events()
    current_scene._toggle_details()
    await save_checked("fantasy_battle_details")
    if not state.begin_next_round():
        push_error("Fantasy fixture did not reach round two")
        quit(1)
        return
    # A legal three-blessing offer, including the two longest names.
    state.draft.current_offer = []
    var selected: Array[String] = []
    for buff in db.get_all_buffs():
        if str(buff["stat"]).ends_with("speed") or str(buff["stat"]) == "defense":
            selected.append(str(buff["id"]))
            state.draft.current_offer.append({"type": "buff", "id": buff["id"]})
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_checked("fantasy_blessings")
    print("Fantasy native views: four elemental galleries, compact battle details, long-name blessing offer.")
    quit(0)
