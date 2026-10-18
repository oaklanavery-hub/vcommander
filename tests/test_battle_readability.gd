extends SceneTree
var failed := false

func unit(id: String, side: String, x: float) -> Dictionary:
    return {"id": id, "side": side, "x": x, "y": 2.0, "alive": true, "hp": 100, "max_hp": 100, "defense": 0, "ability": {}, "attack_speed": 100, "attack": 120, "role": "range", "card_id": "card_earth_04"}

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var sim := CombatSimulator.new()
    sim._reset(7, {})
    sim._projectile_units_per_second = 100.0
    var archer := unit("archer", "player", 0)
    var blocker := unit("blocker", "opponent", 4)
    var target := unit("target", "opponent", 8)
    sim._units.assign([archer, blocker, target])
    var before := sim._snapshot()
    sim._time = 0.1
    sim._perform_attack(archer, target)
    sim._time = 0.2
    blocker["y"] = 2.3
    sim._tick_projectiles()
    sim._resolve_pending_effects()
    var after := sim._snapshot()
    # No saved frame contains this entire short flight.
    check(before["projectiles"].is_empty() and after["projectiles"].is_empty(), "fixture reproduces launch and hit between saved frames")
    var replay := BattleReplay.new()
    replay.configure([before, after], sim._events)
    check(replay.projectiles_at(0.09).is_empty(), "shots never appear before release")
    var midway := replay.projectiles_at(0.15)
    check(midway.size() == 1 and midway[0]["position"].is_equal_approx(Vector2(2, 2.15)), "between-frame flight is drawn toward the actual moving interceptor")
    var contact := replay.projectiles_at(0.2)
    check(contact.size() == 1 and contact[0]["position"].is_equal_approx(Vector2(4, 2.3)), "shot reaches exact interceptor contact, rather than vanishing at its last snapshot")
    check(contact[0]["terminal"]["target_id"] == "blocker" and is_equal_approx(contact[0]["contact_blend"], 1.0), "contact binds to the enemy actually hit")
    check(replay.health_at("blocker", 0.199, 100) == 100 and replay.health_at("blocker", 0.2, 100) == 0, "lethal HP change occurs exactly at visible contact")
    check(replay.projectiles_at(0.25).size() == 1 and replay.projectiles_at(0.33).is_empty(), "contact remains readable briefly and then clears")
    check(replay.health_at("target", 0.2, 100) == 100, "locked target is untouched when intercepted")

    sim._reset(9, {})
    archer = unit("archer", "player", 0)
    target = unit("target", "opponent", 8)
    sim._units.assign([archer, target])
    sim._time = 0.1
    sim._perform_attack(archer, target)
    target["alive"] = false
    sim._time = 0.2
    sim._tick_projectiles()
    replay.configure([], sim._events)
    check(replay.projectiles_at(0.15).size() == 1 and replay.projectiles_at(0.2).is_empty(), "dead locked target fizzles visually at its recorded time without a fake hit")

    var match_info := MatchState.new()
    match_info.start()
    var meter = load("res://scripts/presentation/match_hearts.gd").new()
    root.add_child(meter)
    match_info.begin_battle()
    match_info.resolve_round("opponent")
    meter.refresh(match_info, false)
    check(meter.remaining("player") == 4 and meter.remaining("opponent") == 4, "replay hearts do not leak a result already scored by the simulation")
    meter.refresh(match_info)
    check(meter.remaining("player") == 3 and meter.remaining("opponent") == 4, "completed loss removes one visible heart")
    for index in range(3):
        match_info.advance_round()
        match_info.begin_battle()
        match_info.resolve_round("draw")
    meter.refresh(match_info, false)
    check(meter.remaining("player") == 1 and not meter.sudden_death, "last-heart replay does not reveal the final loss early")
    meter.refresh(match_info)
    check(meter.remaining("player") == 0 and meter.remaining("opponent") == 1, "fourth loss displays an empty meter")
    match_info.start()
    for index in range(4):
        match_info.begin_battle()
        match_info.resolve_round("draw")
        if index < 3:
            match_info.advance_round()
    meter.refresh(match_info, false)
    check(meter.remaining("player") == 1 and meter.remaining("opponent") == 1 and not meter.sudden_death, "fourth draw is hidden until revealed")
    meter.refresh(match_info)
    check(meter.remaining("player") == 0 and meter.remaining("opponent") == 0 and meter.sudden_death, "simultaneous final hearts show Sudden Death")
    meter.queue_free()

    var field = load("res://scripts/combat/battlefield_view.gd").new()
    root.add_child(field)
    var water := {"id": "player", "commander_skill_active": true, "commander": {"active_skill": {"type": "round_debuff"}}}
    field.set_side_configs(water, {"id": "opponent"})
    field.configure_frost()
    field.prelude_time = 1.7
    check(field.frost_coverage() == 1.0 and field.frozen_sides == ["opponent"], "Frozen Field covers both halves while marking only the affected army")
    field.replay_enabled = true
    field.set_playback({}, {}, 0, 119)
    field.finish_replay()
    check(field.frost_coverage() == 1.0, "full-field ice persists through late combat and round result")
    field.set_side_configs({"id": "player"}, {"id": "opponent"})
    field.configure_frost()
    check(field.frost_coverage() == 0.0 and field.frozen_sides.is_empty(), "a fresh uncast round has no stale frost")
    var pulled := unit("target", "opponent", 6)
    field.set_frame({"time": 2.0, "units": [unit("plant", "player", 2), pulled]})
    field.consume_event({"type": "ability", "kind": "pull", "time": 2.0, "unit_id": "plant", "target_id": "target", "from_x": 6.0, "from_y": 2.0, "to_x": 2.9, "to_y": 2.0, "from_hp": 100})
    field.consume_event({"type": "attack", "kind": "melee", "time": 2.0, "unit_id": "plant", "target_id": "target", "card_id": "card_earth_02"})
    field.consume_event({"type": "damage", "source": "normal_attack", "time": 2.0, "source_unit_id": "plant", "target_id": "target", "amount": 120, "hp_after": -20})
    field.consume_event({"type": "defeat", "time": 2.0, "unit_id": "target"})
    field.set_playback({"units": []}, {}, 0, 2.3)
    check(field.held_defeats().has("target"), "lethally pulled enemy stays visible until the bite reaches it")
    field.set_playback({"units": []}, {}, 0, 2.55)
    check(field.held_defeats().is_empty(), "pulled enemy dies after the displayed bite rather than disappearing before it")
    field.queue_free()

    var attack := {"type": "attack", "time": 2.0, "unit_id": "archer", "card_id": "card_earth_04", "x": 0, "y": 2, "target_x": 8, "target_y": 2}
    replay.configure([], [attack])
    check(replay.attack_at("archer", 1.73).is_empty() and not replay.attack_at("archer", 1.8).is_empty(), "attack anticipation begins before the recorded release")
    check(UnitAttackMotion.pose(attack, 1.95)["phase"] == "windup" and UnitAttackMotion.pose(attack, 2)["power"] == 1.0, "strike peaks at the exact authoritative attack time")
    check(UnitAttackMotion.pose(attack, 2.2)["phase"] == "recovery" and replay.attack_at("archer", 2.5).is_empty(), "attacks recover and return to normal motion")
    var bite := attack.duplicate()
    bite["card_id"] = "card_earth_02"
    replay.configure([], [{"type": "ability", "kind": "pull", "time": 2.0, "unit_id": "archer", "target_id": "target"}, bite.merged({"target_id": "target"}, true)])
    check(replay.attack_at("archer", 2.1).is_empty() and replay.attack_at("archer", 2.54).get("time") == 2.54, "pulling unit bites after the visual drag reaches it")
    for profile in CombatCues.catalog()["units"].values():
        var rig := str(profile["rig"])
        for amount in [Vector2(1, 0), Vector2(0, 1), Vector2(0.5, 0)]:
            var mesh := UnitAttackMotion.mesh(rig, amount.x, amount.y, false)
            var arrays := mesh.surface_get_arrays(0)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            check(vertices.size() == 81 and not UnitAttackMotion.deform(Vector2(0.75, 0.4), rig, amount.x, amount.y).is_zero_approx(), "all roster rigs visibly articulate the existing character")
            for index in range(0, indices.size(), 3):
                var a := vertices[indices[index]]
                var b := vertices[indices[index + 1]]
                var c := vertices[indices[index + 2]]
                check((b - a).cross(c - a).z > 0, "character mesh remains continuous without inverted parts")
    if not failed:
        print("Battle readability tests passed: between-frame contact/HP, interception/fizzle, unspoiled hearts, Sudden Death, persistent full-field frost and articulated attack phases.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
