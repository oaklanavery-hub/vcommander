extends SceneTree
var output_dir := "build/qa"
var captured := {}

func _init() -> void:
    call_deferred("run")

func save_image(name: String) -> void:
    for index in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(output_dir.path_join(name + ".png"))
    if error != OK:
        push_error("Battle FX capture failed: " + name)
        quit(1)
    captured[name] = true

func prepare(element: String, skill: bool):
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    unlock_fixture_collection(state.commander_progress, db)
    state.select_commander("commander_" + element + "_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_" + element + "_01"):
        state.equip_card(str(card["id"]))
    state.begin_match(1729)
    if skill:
        state.draft.use_commander_skill()
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    # Presentation fixtures populate the complete legal roster to cover effects.
    for card in db.get_cards_by_set("set_" + element + "_01"):
        state.draft.unit_counts[str(card["id"])] = mini(2, int(card["unit_cap"]))
    for card in state.opponent.get_side().get("cards", []):
        state.opponent.draft.unit_counts[str(card["id"])] = mini(2, int(card["unit_cap"]))
    state.opponent.draft.commander_skill_used_this_round = skill
    state.run_battle()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    return current_scene

func unlock_fixture_collection(profile: CommanderProgress, content: Object) -> void:
    # Script-mode profiles are isolated. Exercise normally earned access rather
    # than reading a player's developer credential or bypassing equipment rules.
    for commander in content.get_all_commanders():
        var id := str(commander["id"])
        while int(profile.record(id)["xp"]) < 1000 or int(profile.record(id)["wins"]) < 6:
            profile.finish_match(profile.begin_match(id), "win")

func seek(scene, time: float) -> void:
    scene.battlefield.finish_replay()
    scene._playback_time = time
    scene._frame_index = 0
    scene._event_index = scene._prelude.event_end
    scene._advance_frames()
    scene._advance_events()
    scene._update_timer_label()

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    for element in ["fire", "water", "earth"]:
        var scene = await prepare(element, true)
        scene._advance_prelude(1.15 if element == "fire" else 1.4)
        await save_image("prebattle_" + element)
        scene._advance_prelude(BattlePrelude.DURATION)
        for frame in scene._frames:
            for projectile in frame.get("projectiles", []):
                var profile := CombatCues.profile(str(projectile.get("card_id", "")))
                var name := "projectile_" + str(profile.get("projectile", "magic"))
                if captured.has(name):
                    continue
                seek(scene, float(frame["time"]) + 0.03)
                await save_image(name)
    var vines = await prepare("earth", false)
    for event in vines._events:
        if event.get("kind") == "pull":
            for entry in [["vine_extend", 0.12], ["vine_drag", 0.37], ["vine_retract", 0.62]]:
                seek(vines, float(event["time"]) + float(entry[1]))
                await save_image(str(entry[0]))
            break
    for name in ["prebattle_fire", "prebattle_water", "prebattle_earth", "projectile_arrow", "projectile_fireball", "projectile_dragonfire", "projectile_water_orb", "projectile_ice_shard", "projectile_seed", "vine_extend", "vine_drag", "vine_retract"]:
        if not captured.has(name):
            push_error("Missing battle FX coverage: " + name)
            quit(1)
            return
    print("Battle FX captures saved: three Commander preludes, six projectile styles and three vine phases.")
    quit(0)
