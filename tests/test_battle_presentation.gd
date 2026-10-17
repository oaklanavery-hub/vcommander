extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    var audio = root.get_node("GameAudio")
    for card in db.get_all_cards():
        check(CombatCues.catalog().get("units", {}).has(str(card["id"])), "every card has a presentation profile")
        var profile := CombatCues.profile(str(card["id"]))
        for key in ["attack_sound", "impact_sound"]:
            check(audio.EFFECTS.has(str(profile[key])), "unit cue resolves to an exported sound")
    check(CombatCues.profile("card_earth_04")["projectile"] == "arrow", "archers fire arrows")
    check(CombatCues.profile("card_fire_03")["projectile"] == "fireball", "Sorcerers fire fireballs")
    check(CombatCues.profile("card_water_04")["projectile"] == "ice_shard", "Water Wizards fire crystalline magic")
    check(CombatCues.profile("commander_plant")["projectile"] == "seed", "summoned plants fire seeds")
    var cues := BattleAudio.new()
    root.add_child(cues)
    check(cues.consume_event({"type": "attack", "card_id": "card_earth_04"}, 0.0) == "arrow_release", "bow release has its own sound")
    check(cues.consume_event({"type": "attack", "card_id": "card_earth_04"}, 0.02).is_empty(), "dense identical cues are throttled")
    check(cues.consume_event({"type": "attack", "card_id": "card_fire_03"}, 0.02) == "fire_cast", "different simultaneous attacks are not globally silenced")
    check(cues.consume_event({"type": "commander_skill", "skill_type": "round_debuff"}, 0.02) == "freeze", "Commander sound survives busy attacks")
    cues.queue_free()
    var sim := CombatSimulator.new()
    sim._reset(5, {})
    var plant := {"id": "player:card_earth_02:0", "side": "player", "x": 2.0, "y": 3.0, "alive": true, "hp": 650.0, "ability_cooldown": 0.0, "attack_timer": 99.0}
    var target := {"id": "opponent:probe:0", "side": "opponent", "x": 6.0, "y": 3.0, "alive": true, "hp": 700.0}
    sim._units.assign([plant, target])
    sim._time = 0.1
    sim._tick_pull_unit(plant, target, {"pull_range": 5.0, "cooldown_seconds": 5.0})
    var pull: Dictionary = sim._events.back()
    check(pull.get("kind") == "pull" and is_equal_approx(float(pull["from_x"]), 6.0) and is_equal_approx(float(pull["to_x"]), float(target["x"])), "pull records exact original and resolved endpoints")
    var resolved := Vector2(float(target["x"]), float(target["y"]))
    check(BattleEffects.pull_position(pull, 0.1, resolved).is_equal_approx(Vector2(6, 3)), "enemy waits for the stretching vine to reach it")
    var midway := BattleEffects.pull_position(pull, 0.38, resolved)
    check(midway.x < 6.0 and midway.x > resolved.x, "grabbed enemy is visibly dragged toward the plant")
    check(BattleEffects.pull_position(pull, 0.72, resolved).is_equal_approx(resolved), "vine presentation ends at the exact simulation position")
    var second := pull.duplicate()
    second["time"] = float(pull["time"]) + 0.1
    second["from_x"] = pull["to_x"]
    second["to_x"] = float(pull["to_x"]) - 0.3
    var chain := BattleEffects.pull_chain([pull, second], str(pull["target_id"]), 0.25)
    check(chain["from_x"] == pull["from_x"] and chain["to_x"] == second["to_x"] and chain["time"] == pull["time"], "overlapping vines retain the earliest grab and latest resolved destination")
    state.select_commander("commander_fire_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    check(state.begin_match(1729), "fixture match starts")
    check(state.draft.use_commander_skill(), "Commander skill selected legally")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    # Force the fixture rival's selected skill so both sides share one prelude.
    state.opponent.draft.commander_skill_used_this_round = true
    check(state.run_battle(), "skill battle resolves")
    var result: Dictionary = state.battle_result.duplicate(true)
    var prelude := BattlePrelude.new(result.get("pre_battle", {}))
    check(prelude.skills.size() == 2 and prelude.active(), "both skills share one pre-battle sequence")
    check(not prelude.before.is_empty() and not prelude.after.is_empty(), "simulation retains before/after skill snapshots")
    var losses: Dictionary = state.match_state.losses.duplicate()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    await process_frame
    var combat = current_scene
    combat.set_process(false)
    check(combat._speed_index == 0 and combat.speed_button.text.contains("1x"), "new battle always starts at 1x")
    check(combat.get_node_or_null("Margin/Main/StatusRow/Skip") == null and not combat.has_method("_skip_to_result"), "skip control and shortcut path are removed")
    check(not combat.next_button.visible and combat.speed_button.disabled, "result and speed changes wait for skill completion")
    combat._process(0.6)
    check(is_zero_approx(combat._playback_time), "battle clock stays at zero while skill animation plays")
    var elapsed: float = combat._prelude.elapsed
    combat._toggle_pause()
    combat._process(1.0)
    check(is_equal_approx(combat._prelude.elapsed, elapsed), "pause also pauses the pre-battle sequence")
    combat._toggle_pause()
    combat._process(BattlePrelude.DURATION)
    check(not combat._prelude.active() and is_zero_approx(combat._playback_time), "skills finish before the first combat tick")
    check(not combat.speed_button.disabled and not combat.next_button.visible, "battle begins after the prelude")
    combat._process(0.1)
    check(combat._playback_time <= 0.101, "battle runs at 1x after skills")
    combat._cycle_speed()
    check(combat._speed_index == 1, "player can still choose a faster combat speed")
    combat._process(combat._duration + 1.0)
    check(combat.next_button.visible, "normal replay completion reveals results")
    check(state.match_state.losses == losses and state.battle_result == result, "presentation timing never alters scored battle or losses")
    check(state.begin_next_round(), "next-round fixture begins normally")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    check(state.run_battle(), "next battle resolves")
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    check(current_scene._speed_index == 0 and current_scene.speed_button.text.contains("1x"), "next battle resets the manually changed speed to 1x")
    for commander in db.get_all_commanders():
        var cards: Array = db.get_cards_by_set(str(commander["signature_set_id"]))
        var counts := {}
        for card in cards:
            counts[str(card["id"])] = 1
        var side := {"id": "player", "commander": commander, "commander_skill_active": true, "cards": cards, "unit_counts": counts}
        var enemy := side.duplicate(true)
        enemy["id"] = "opponent"
        var sample: Dictionary = CombatSimulator.new().simulate(side, enemy, 53, {"match": {"round_time_seconds": 0.2}})
        var opening := BattlePrelude.new(sample["pre_battle"])
        check(opening.skills.size() == 2, "all Commander types have simultaneous visual prelude metadata")
        opening.advance(BattlePrelude.DURATION)
        check(opening.frame() == sample["frames"][0], "skill sequence ends at exact authoritative battle-start frame")
    if not failed:
        print("Battle presentation tests passed: 1x, no skip, simultaneous pre-battle skills, paused clock, exact vine endpoints, unit projectiles, independent sound cues and unchanged outcomes.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
