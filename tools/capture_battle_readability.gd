extends "res://tools/capture_battle_fx.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var scene = await prepare("water", true)
    scene._advance_prelude(BattlePrelude.DURATION)
    seek(scene, minf(20, scene._duration * 0.8))
    await save_image("frozen_field_late")
    scene._process(scene._duration + scene._tail_length + 0.1)
    await save_image("hearts_result")
    for element in ["earth", "fire", "water"]:
        scene = await prepare(element, false)
        for event in scene._events:
            var card_id := str(event.get("card_id", ""))
            if event.get("type") == "projectile_impact" and not captured.has("contact_" + element):
                for entry in [["approach", -0.04], ["hit", 0.025], ["after", 0.17]]:
                    seek(scene, float(event["time"]) + float(entry[1]))
                    await save_image("contact_" + element + "_" + str(entry[0]))
                captured["contact_" + element] = true
            if event.get("type") != "attack":
                continue
            var motion := str(CombatCues.profile(card_id).get("motion", "slash"))
            if captured.has("attack_" + motion):
                continue
            var strike_time := float(event["time"])
            for cue in scene.battlefield.replay.attacks.get(str(event["unit_id"]), []):
                if is_equal_approx(float(cue.get("resolved_at", -1)), float(event["time"])):
                    strike_time = float(cue["time"])
                    break
            for entry in [["windup", -0.08], ["strike", 0.025], ["recover", 0.25]]:
                seek(scene, strike_time + float(entry[1]))
                await save_image("attack_" + motion + "_" + str(entry[0]))
            captured["attack_" + motion] = true
    await capture_lethal_pull()
    for name in ["frozen_field_late", "hearts_result", "contact_earth", "contact_fire", "contact_water", "attack_slam", "attack_slash", "attack_shoot", "attack_cast", "attack_bite", "lethal_pull_bite"]:
        if not captured.has(name):
            push_error("Missing combat readability capture: " + name)
            quit(1)
            return
    print("Combat readability captures saved: persistent frost, hearts, three contact sequences, five attack phase sequences and a lethal vine/bite/death sequence.")
    quit(0)

func capture_lethal_pull() -> void:
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    var plant: Dictionary = db.get_card("card_earth_02").duplicate(true)
    var imp: Dictionary = db.get_card("card_fire_02").duplicate(true)
    # A deterministic low-HP presentation fixture makes the first bite lethal.
    plant["stats"]["attack"] = 500
    imp["stats"]["health"] = 30
    imp["stats"]["defense"] = 0
    var player := {"id": "player", "cards": [plant], "unit_counts": {"card_earth_02": 1}}
    var rival := {"id": "opponent", "cards": [imp], "unit_counts": {"card_fire_02": 1}}
    var result := CombatSimulator.new().simulate(player, rival, 71, {})
    state.battle_result = result
    state.opponent_combat_side = rival
    state.match_state.start()
    state.match_state.begin_battle()
    state.match_state.resolve_round(str(result["winner"]), float(result["duration"]))
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    for event in result["events"]:
        if event.get("kind") != "pull":
            continue
        for entry in [["extend", 0.12], ["drag", 0.36], ["bite", 0.56], ["death", 0.78]]:
            var time := float(event["time"]) + float(entry[1])
            seek(current_scene, minf(time, current_scene._duration))
            current_scene._end_elapsed = maxf(0, time - current_scene._duration)
            current_scene._advance_frames()
            await save_image("lethal_pull_" + str(entry[0]))
        break
