extends "res://tools/capture_mastery.gd"

func journal(name: String, commander: String = "", page: int = 0) -> void:
    var journal_script = load("res://scripts/presentation/progress_journal.gd")
    journal_script.initial_commander = commander
    change_scene_to_file("res://scenes/progression/progress_journal.tscn")
    await scene_changed
    current_scene._select_tab(page)
    await save_image(name)

func collection(name: String) -> void:
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await save_image(name)

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
    state.select_commander("commander_fire_01")
    state.clear_army()
    await journal("progression_new")
    await journal("progression_achievements_new", "", 1)
    await collection("progression_collection_locked")
    award("commander_fire_01", "win")
    award("commander_fire_01", "win")
    for i in range(10):
        award("commander_fire_01", "loss")
    await journal("progression_partial", "commander_fire_01")
    for element in ["fire", "water", "earth", "slime"]:
        for i in range(5):
            award("commander_%s_01" % element, "win")
    await journal("progression_unlocked")
    await journal("progression_achievements_earned", "", 1)
    await collection("progression_collection_unlocked")
    state.clear_army()
    var rewards: Array[Dictionary] = []
    for element in ["fire", "water", "earth", "slime"]:
        var card: Dictionary = db.get_card("card_%s_05" % element)
        rewards.append(card)
        state.equip_card(card["id"])
    state.begin_match(593)
    state.opponent.configure(db.get_all_commanders(), rewards, db.sets, db.get_all_buffs(), 593)
    state.opponent.begin_round(true, false, false, state.get_player_combat_side())
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    for card in rewards:
        state.draft.unit_counts[card["id"]] = card["unit_cap"]
        state.opponent.draft.unit_counts[card["id"]] = card["unit_cap"]
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    seek(current_scene, 0)
    await save_image("progression_units_battle")
    seek(current_scene, 8.0)
    await save_image("progression_units_action")
    state.leave_match()
    state.commander_progress = CommanderProgress.new(db, "")
    for i in range(4):
        award("commander_fire_01", "win")
    var final = await final_scene(true)
    final.mastery_panel.finish_animation()
    await save_image("progression_reward_result")
    print("Progression native views: new/partial/unlocked rewards, new/earned achievements, locked/unlocked collection, all four units in battle/action, actual reward result.")
    quit(0)
