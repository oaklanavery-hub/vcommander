extends "res://tools/capture_battle_fx.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    state.select_commander("commander_slime_01")
    state.clear_army()
    change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    await scene_changed
    await save_image("slime_commander")
    current_scene._open_army_builder()
    await scene_changed
    await save_image("slime_army")

    await prepare("slime", true)
    var player: Dictionary = state.get_player_combat_side()
    var rival := player.duplicate(true)
    rival["id"] = "opponent"
    state.opponent_combat_side = rival
    state.battle_result = CombatSimulator.new().simulate(player, rival, 1729, root.get_node("ContentDatabase").get_game_balance())
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(state.battle_result["winner"]), float(state.battle_result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    var scene = current_scene
    scene.set_process(false)
    scene._advance_prelude(1.4)
    await save_image("slime_royal_opening")
    scene._advance_prelude(BattlePrelude.DURATION)
    for shot in scene.battlefield.replay.shots:
        if shot.get("card_id") == "card_slime_02" and shot.has("terminal"):
            var launch := float(shot.get("launched_at", 0))
            var impact := float(shot["terminal"]["time"])
            seek(scene, (launch + impact) * 0.5)
            await save_image("slime_cannon_flight")
            seek(scene, impact + 0.03)
            await save_image("slime_cannon_hit")
            break
    for event in scene._events:
        if event.get("type") == "attack" and event.get("card_id") == "card_slime_03" and not captured.has("slime_ball_strike"):
            seek(scene, float(event["time"]) - 0.1)
            await save_image("slime_ball_windup")
            seek(scene, float(event["time"]) + 0.04)
            await save_image("slime_ball_strike")
        elif event.get("type") == "spawn" and event.get("source") == "death_split" and not captured.has("slime_split"):
            seek(scene, float(event["time"]) + 0.28)
            await save_image("slime_split")
        elif event.get("type") == "spawn" and event.get("source") == "revival" and not captured.has("slime_revival"):
            seek(scene, float(event["time"]) + 0.18)
            await save_image("slime_revival")
        elif event.get("kind") == "death_area" and not captured.has("slime_pool_late"):
            seek(scene, float(event["time"]) + 0.12)
            await save_image("slime_pool_burst")
            seek(scene, float(event["time"]) + 8.0)
            await save_image("slime_pool_late")
    for name in ["slime_commander", "slime_army", "slime_royal_opening", "slime_cannon_flight", "slime_cannon_hit", "slime_ball_windup", "slime_ball_strike", "slime_split", "slime_revival", "slime_pool_burst", "slime_pool_late"]:
        if not captured.has(name):
            push_error("Missing Slime capture: " + name)
            quit(1)
            return
    if not await capture_ball_bursts():
        quit(1)
        return
    print("Slime captures saved: gallery/warband, Royal Jelly, Cannon flight/contact, white Ball poses, split children, revival and pink ten-second pools.")
    quit(0)

func capture_ball_bursts() -> bool:
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    # Controlled native QA fixture: extra durability keeps the charge cycle on screen.
    # The shipped definitions are never changed by this presentation script.
    var ball: Dictionary = db.get_card("card_slime_03").duplicate(true)
    ball["stats"]["health"] = 1400
    var bear: Dictionary = db.get_card("card_earth_03").duplicate(true)
    bear["stats"].merge({"health": 6000, "attack": 60, "attack_speed": 100}, true)
    bear["ability"] = {"type": "basic_melee"}
    var player := {"id": "player", "commander": db.get_commander("commander_slime_01"), "cards": [ball], "unit_counts": {str(ball["id"]): 1}}
    var enemy := {"id": "opponent", "commander": db.get_commander("commander_earth_01"), "cards": [bear], "unit_counts": {str(bear["id"]): 1}}
    state.opponent_combat_side = enemy
    state.battle_result = CombatSimulator.new().simulate(player, enemy, 814, db.get_game_balance())
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(state.battle_result["winner"]), float(state.battle_result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    var scene = current_scene
    scene.set_process(false)
    for event in scene._events:
        if event.get("kind") != "absorb_burst":
            continue
        var time := float(event["time"])
        if not event.get("on_death", false) and not captured.has("slime_ball_burst"):
            seek(scene, time - 0.12)
            await save_image("slime_ball_charged")
            seek(scene, time + 0.08)
            await save_image("slime_ball_burst")
            seek(scene, time + 0.20)
            await save_image("slime_ball_pushback")
            scene.battlefield.reduced_motion = true
            seek(scene, time + 0.08)
            await save_image("slime_ball_burst_reduced")
            scene.battlefield.reduced_motion = false
        elif event.get("on_death", false) and not captured.has("slime_ball_death_burst"):
            seek(scene, time + 0.08)
            await save_image("slime_ball_death_burst")
    for name in ["slime_ball_charged", "slime_ball_burst", "slime_ball_pushback", "slime_ball_burst_reduced", "slime_ball_death_burst"]:
        if not captured.has(name):
            push_error("Missing Slime Ball capture: " + name)
            return false
    print("Slime Ball native views: charged, periodic burst/contact, pushback, doubled death burst and reduced motion.")
    return true
