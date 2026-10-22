extends "res://tools/capture_battle_fx.gd"

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
    unlock_fixture_collection(state.commander_progress, db)
    state.select_commander("commander_fire_01")
    state.clear_army()
    var cards: Array = []
    for element in ["fire", "water", "earth", "slime"]:
        state.equip_card("card_%s_06" % element)
        cards.append(db.get_card("card_%s_06" % element))
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await save_image("assassins_collection")
    state.begin_match(520)
    var player: Dictionary = state.get_player_combat_side()
    player["cards"] = cards
    player["unit_counts"] = {}
    for card in cards:
        player["unit_counts"][card["id"]] = 2
        state.draft.unit_counts[card["id"]] = 2
    var rival := player.duplicate(true)
    rival["id"] = "opponent"
    state.opponent_combat_side = rival
    state.battle_result = CombatSimulator.new().simulate(player, rival, 520, db.get_game_balance())
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(state.battle_result["winner"]), float(state.battle_result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    var scene = current_scene
    scene.set_process(false)
    for entry in [["assassins_transit", 0.45], ["assassins_terrain", 1.8], ["assassins_cooldown", 4.8]]:
        seek(scene, float(entry[1]))
        await save_image(str(entry[0]))
    for event in scene._events:
        if event.get("kind") == "sticky_link" and event.get("link", {}).get("target_ids", []).size() == 2:
            seek(scene, float(event["time"]) + 0.25)
            await save_image("assassins_links")
            break
    scene.battlefield.reduced_motion = true
    seek(scene, 0.45)
    await save_image("assassins_reduced")
    scene.battlefield.reduced_motion = false
    state.begin_next_round()
    for id in state.draft.unit_counts:
        state.draft.unit_counts[id] = int(db.get_card(str(id))["unit_cap"])
    for id in state.draft.buff_stacks:
        state.draft.buff_stacks[id] = 12
    state.draft.refresh_offer()
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await save_image("assassins_powercards")
    for name in ["assassins_collection", "assassins_transit", "assassins_terrain", "assassins_cooldown", "assassins_links", "assassins_reduced", "assassins_powercards"]:
        if not captured.has(name):
            push_error("Missing specialist view: " + name)
            quit(1)
            return
    print("Specialist native views: collection, transit, terrain/trails, cooldown, shared links, reduced motion.")
    quit(0)
