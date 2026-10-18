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
    scene._process(scene._duration + 1)
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
            for entry in [["windup", -0.08], ["strike", 0.025], ["recover", 0.25]]:
                seek(scene, float(event["time"]) + float(entry[1]))
                await save_image("attack_" + motion + "_" + str(entry[0]))
            captured["attack_" + motion] = true
    for name in ["frozen_field_late", "hearts_result", "contact_earth", "contact_fire", "contact_water", "attack_slam", "attack_slash", "attack_shoot", "attack_cast", "attack_bite"]:
        if not captured.has(name):
            push_error("Missing combat readability capture: " + name)
            quit(1)
            return
    print("Combat readability captures saved: persistent frost, hearts, three contact sequences and five attack phase sequences.")
    quit(0)
