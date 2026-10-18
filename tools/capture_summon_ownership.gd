extends "res://tools/capture_battle_fx.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    await prepare("earth", true)
    var state = root.get_node("GameState")
    var player: Dictionary = state.get_player_combat_side()
    var rival := player.duplicate(true)
    rival["id"] = "opponent"
    state.opponent_combat_side = rival
    state.battle_result = CombatSimulator.new().simulate(player, rival, 1729, {})
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(state.battle_result["winner"]), float(state.battle_result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    var scene = current_scene
    scene.set_process(false)
    scene._advance_prelude(1.5)
    await save_image("summon_ownership_opening")
    scene._advance_prelude(BattlePrelude.DURATION)
    seek(scene, 2.0)
    await save_image("summon_ownership_battle")
    for event in scene._events:
        if event.get("type") == "projectile_impact" and event.get("card_id") == "commander_plant":
            seek(scene, float(event["time"]) + 0.03)
            await save_image("summon_ownership_hit")
            break
    if not captured.has("summon_ownership_hit"):
        push_error("Missing summoned seed impact coverage")
        quit(1)
        return
    print("Summon ownership captures saved: both Commanders, ally/rival plants and enemy seed contact.")
    quit(0)
