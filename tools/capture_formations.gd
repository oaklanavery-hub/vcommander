extends "res://tools/capture_battle_fx.gd"

func themed(element: String, id: String, skill: bool = false) -> Dictionary:
    var db = root.get_node("ContentDatabase")
    var cards: Array = db.get_cards_by_set("set_" + element + "_01").slice(0, 4)
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = int(card["unit_cap"])
    return {"id": id, "commander": db.get_commander("commander_" + element + "_01"),
        "cards": cards, "unit_counts": counts, "commander_skill_active": skill,
        "set_bonus": db.get_signature_set("set_" + element + "_01").get("bonus", {})}

func fixture(own: Dictionary, enemy: Dictionary):
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    state.select_commander(str(own["commander"]["id"]))
    state.clear_army()
    unlock_fixture_collection(state.commander_progress, db)
    for card in own["cards"]:
        state.equip_card(str(card["id"]))
    state.begin_match(1729)
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.draft.unit_counts = own["unit_counts"].duplicate()
    state.draft.commander_skill_used_this_round = bool(own.get("commander_skill_active", false))
    state.opponent_combat_side = enemy
    state.battle_result = CombatSimulator.new().simulate(own, enemy, 1729, db.get_game_balance())
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(state.battle_result["winner"]), float(state.battle_result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    return current_scene

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var db = root.get_node("ContentDatabase")
    var enemy := themed("slime", "opponent")
    enemy["cards"] = [db.get_card("card_slime_01"), db.get_card("card_slime_04"), db.get_card("card_fire_04"), db.get_card("card_water_03")]
    enemy["unit_counts"] = {"card_slime_01": 3, "card_slime_04": 2, "card_fire_04": 2, "card_water_03": 1}
    enemy["set_bonus"] = {}
    var water = await fixture(themed("water", "player", true), enemy)
    water._advance_prelude(1.4)
    await save_image("formation_water_opening")
    water._advance_prelude(BattlePrelude.DURATION)
    seek(water, 0.0)
    await save_image("formation_water_start")
    seek(water, 2.0)
    await save_image("formation_water_engagement")
    for element in ["fire", "earth", "slime"]:
        var scene = await fixture(themed(element, "player"), themed(element, "opponent"))
        seek(scene, 0.0)
        await save_image("formation_" + element + "_start")
    var ranged := themed("water", "player")
    ranged["unit_counts"]["card_water_01"] = 0
    var scene = await fixture(ranged, themed("earth", "opponent"))
    seek(scene, 0.0)
    await save_image("formation_ranged_start")
    for name in ["formation_water_opening", "formation_water_start", "formation_water_engagement", "formation_fire_start", "formation_earth_start", "formation_slime_start", "formation_ranged_start"]:
        if not captured.has(name):
            push_error("Missing formation capture: " + name)
            quit(1)
            return
    print("Formation captures saved: crowded Water/mixed matchup, opening/engagement, all themes and ranged-only support protection.")
    quit(0)
