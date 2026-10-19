extends "res://tools/capture_battle_fx.gd"

func award(commander: String, outcome: String) -> void:
    var state = root.get_node("GameState")
    var id: String = state.commander_progress.begin_match(commander)
    state.commander_progress.finish_match(id, outcome)

func gallery(name: String, commander: String) -> void:
    change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    await scene_changed
    current_scene._select_commander(commander)
    await save_image(name)

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    var audio = root.get_node("GameAudio")
    var reduced: bool = audio.reduced_motion
    audio.reduced_motion = false
    state.commander_progress = CommanderProgress.new(db, "")
    await gallery("mastery_new", "commander_earth_01")
    for i in range(30):
        award("commander_fire_01", "win")
    for i in range(10):
        award("commander_fire_01", "loss")
    for i in range(8):
        award("commander_water_01", "win")
    for i in range(12):
        award("commander_water_01", "loss")
        award("commander_slime_01", "win")
    for i in range(4):
        award("commander_slime_01", "loss")
    await gallery("mastery_gallery", "commander_slime_01")
    state.commander_progress = CommanderProgress.new(db, "")
    award("commander_fire_01", "win")
    award("commander_fire_01", "win")
    var scene = await final_scene(true)
    scene.mastery_panel.set_process(false)
    await save_image("mastery_reward_start")
    scene.mastery_panel.finish_animation()
    await save_image("mastery_level_up")
    audio.reduced_motion = true
    scene.mastery_panel.show_reward(state.mastery_reward)
    await save_image("mastery_reduced_motion")
    audio.reduced_motion = false
    scene = await final_scene(false)
    scene.mastery_panel.finish_animation()
    await save_image("mastery_loss")
    state.begin_match(3187)
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    var menu = root.get_node("GameMenu")
    menu.confirm_leave()
    await save_image("mastery_forfeit")
    menu.close()
    state.leave_match()
    state.commander_progress.read_only = true
    await gallery("mastery_save_warning", "commander_fire_01")
    state.commander_progress.read_only = false
    audio.reduced_motion = reduced
    for name in ["mastery_new", "mastery_gallery", "mastery_reward_start", "mastery_level_up", "mastery_reduced_motion", "mastery_loss", "mastery_forfeit", "mastery_save_warning"]:
        if not captured.has(name):
            push_error("Missing mastery capture: " + name)
            quit(1)
            return
    print("Mastery native views: new/populated gallery, reward start, level-up, reduced motion, loss, forfeit and save warning.")
    quit(0)

func final_scene(player_strong: bool):
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    state.select_commander("commander_fire_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    state.begin_match(3187)
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.match_state.start(1)
    set_strength(state.draft, db.get_cards_by_set("set_fire_01"), player_strong)
    set_strength(state.opponent.draft, state.opponent.get_side()["cards"], not player_strong)
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    var scene = current_scene
    scene.set_process(false)
    seek(scene, scene._duration)
    scene._finish_replay()
    return scene

func set_strength(draft, cards: Array, strong: bool) -> void:
    draft.unit_counts.clear()
    draft.buff_stacks.clear()
    for i in range(cards.size()):
        if strong or i == 0:
            draft.unit_counts[str(cards[i]["id"])] = int(cards[i]["unit_cap"]) if strong else 1
    if strong:
        for buff in root.get_node("ContentDatabase").get_all_buffs():
            draft.buff_stacks[str(buff["id"])] = 3
