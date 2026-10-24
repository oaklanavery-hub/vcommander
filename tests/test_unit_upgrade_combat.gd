extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func arena(seed_value: int = 42) -> CombatSimulator:
    var sim := CombatSimulator.new()
    sim._reset(seed_value, db.get_game_balance())
    return sim

func actor(sim: CombatSimulator, id: String, side: String, position: Vector2, upgraded := false) -> Dictionary:
    var card: Dictionary = db.get_card(id).duplicate(true)
    if upgraded:
        card = UnitUpgrades.changed_card(card, db.get_upgrade_rules()["units"][id])
    var index := sim._units.size()
    sim._spawn_unit({"card": card, "unit_index": index, "side_config": {}, "side_id": side}, position)
    return sim._units.back()

func enduring(unit: Dictionary, defense := 0.0) -> void:
    unit["max_hp"] = 1000000.0
    unit["hp"] = 1000000.0
    unit["defense"] = defense

func kill(sim: CombatSimulator, unit: Dictionary) -> void:
    sim._queue_raw_damage(str(unit["id"]), float(unit["max_hp"]) * 2 + float(unit["defense"]), sim._other_side(str(unit["side"])), "fixture", "fixture")
    sim._resolve_pending_effects()

func run() -> void:
    db = root.get_node("ContentDatabase")
    double_attacks()
    fire_and_ice()
    healing_and_control()
    stacking_and_splits()
    death_fields()
    old_and_seeded()
    if not failed:
        print("Unit upgrade combat tests passed: all 24 upgrades, real delayed hits/impacts, pulses/procs/fields, relative healing, roots/expiry, capped focus/shred/slows, two split generations/revival, nonrecursive death links, enemy ownership and seeded baseline parity.")
    quit(1 if failed else 0)

func double_attacks() -> void:
    for id in ["card_fire_02", "card_earth_04"]:
        var sim := arena()
        var source := actor(sim, id, "player", Vector2(3, 3), true)
        var target := actor(sim, "card_fire_01", "opponent", Vector2(3.8, 3))
        enduring(target, float(source["attack"]) * 0.9)
        sim._perform_attack(source, target)
        sim._resolve_pending_effects()
        for index in range(1, 4):
            sim._time = float(index) * 0.1
            UnitUpgradeEffects.tick(sim)
            sim._tick_projectiles()
            sim._resolve_pending_effects()
        var attacks: Array = sim._events.filter(func(event): return event["type"] == "attack")
        check(attacks.size() == 2 and float(attacks[1]["time"]) > float(attacks[0]["time"]), "double hits have two real contact/launch times")
        check(is_equal_approx(1000000.0 - float(target["hp"]), 2 * maxf(1, (round(float(source["attack"])) - float(target["defense"])) * 0.75)), "both hits apply their tuned damage")
    var sim := arena()
    var serpent := actor(sim, "card_water_02", "player", Vector2(3, 3), true)
    var ordinary := actor(sim, "card_water_02", "opponent", Vector2(8, 3))
    check(is_equal_approx(sim._attack_interval(serpent) * 2, sim._attack_interval(ordinary)), "two-headed serpent attacks twice as frequently")
    sim._perform_attack(serpent, ordinary)
    check(is_equal_approx(float(sim._projectiles[0]["raw_damage"]), float(serpent["attack"])) and sim._projectiles[0]["post_defense_multiplier"] == 0.7, "serpent tuning applies after DEF so it never receives another flat armour penalty")
    serpent["attack_speed"] = 200
    check(sim._effective_attack_speed(serpent) == 200, "dual heads never change the Attack Speed rating cap")

func fire_and_ice() -> void:
    var sim := arena()
    var golem := actor(sim, "card_fire_01", "player", Vector2(3, 3), true)
    var target := actor(sim, "card_fire_01", "opponent", Vector2(5, 3))
    var ally := actor(sim, "card_earth_03", "player", Vector2(4, 4))
    enduring(target)
    var ally_hp := float(ally["hp"])
    sim._time = 3
    UnitUpgradeEffects.tick(sim)
    sim._resolve_pending_effects()
    check(is_equal_approx(1000000.0 - float(target["hp"]), round(float(golem["attack"]) * 1.5)) and ally["hp"] == ally_hp, "three-second fire rings damage only nearby enemies")
    sim = arena()
    var wizard := actor(sim, "card_fire_03", "player", Vector2(3, 3), true)
    var primary := actor(sim, "card_fire_01", "opponent", Vector2(4, 3))
    var secondary := actor(sim, "card_fire_01", "opponent", Vector2(6, 3))
    enduring(primary)
    enduring(secondary)
    sim._perform_attack(wizard, primary)
    sim._time = 0.2
    sim._tick_projectiles()
    sim._resolve_pending_effects()
    check(float(secondary["hp"]) < 1000000 and sim._events.any(func(event): return event.get("projectile", {}).get("visual_scale", 1) > 1), "greater fireballs have larger projectile metadata and splash beyond the original small radius")
    sim = arena()
    var dragon := actor(sim, "card_fire_04", "player", Vector2(3, 3), true)
    target = actor(sim, "card_fire_01", "opponent", Vector2(4, 3))
    enduring(target)
    UnitUpgradeEffects.on_impact(sim, dragon, Vector2(4, 3))
    sim._area_effects[0]["tick_timer"] = 0.4
    UnitUpgradeEffects.on_impact(sim, dragon, Vector2(4, 3))
    check(sim._area_effects.size() == 1 and is_equal_approx(float(sim._area_effects[0]["tick_timer"]), 0.4), "dragon field refresh cannot multiply pools or starve damage by restarting its tick")
    sim._step = 1
    for index in range(5):
        sim._time += 1
        sim._tick_area_effects()
        sim._resolve_pending_effects()
    check(sim._events.filter(func(event): return event.get("source") == "upgrade_ground_fire").size() == 5 and sim._area_effects.is_empty(), "dragon ground fire ticks for five seconds then expires")
    var proc_events: Array = []
    for iteration in range(2):
        sim = arena(8109)
        var giant := actor(sim, "card_water_01", "player", Vector2(3, 3), true)
        target = actor(sim, "card_fire_01", "opponent", Vector2(3.8, 3))
        enduring(target)
        for index in range(100):
            UnitUpgradeEffects.on_hit(sim, giant, target)
        var evidence: Array = sim._events.filter(func(event): return event.get("kind") == "ice_splinter")
        check(not evidence.is_empty() and evidence.size() < 50, "ice splinters are a chance-based proc")
        proc_events.append(evidence)
    check(proc_events[0] == proc_events[1], "the same seed reproduces all proc outcomes")
    sim = arena()
    var spriggan := actor(sim, "card_fire_06", "player", Vector2(3, 3), true)
    target = actor(sim, "card_fire_01", "opponent", Vector2(18, 7))
    enduring(target)
    for cast in range(3):
        sim._time = float(cast) * 5
        target["x"] = 18 if cast != 1 else 12
        target["y"] = 7 if cast == 0 else (9 if cast == 1 else 4)
        check(sim._begin_transit(spriggan, spriggan["ability"]), "upgraded fireball finds a legal backline")
        for step in range(10):
            sim._time += 0.1
            sim._tick_special_effects()
        if cast == 1:
            check(sim._hazards.any(func(hazard): return hazard.get("expires_after_transits") == 3), "the first trail survives one later arrival beyond its old lifetime")
    check(not sim._hazards.any(func(hazard): return hazard.get("expires_after_transits") == 3), "the first trail expires after two later arrivals")
    spriggan["alive"] = false
    sim._tick_special_effects()
    check(sim._hazards.all(func(hazard): return float(hazard["expires_at"]) <= sim._time + 10.01), "orphaned extended trails have a bounded death lifetime")

func healing_and_control() -> void:
    var sim := arena()
    var phoenix := actor(sim, "card_fire_05", "player", Vector2(3, 3), true)
    var ally := actor(sim, "card_earth_03", "player", Vector2(5, 3))
    ally["max_hp"] = 1000
    ally["hp"] = 100
    var enemy := actor(sim, "card_fire_01", "opponent", Vector2(4, 4))
    var enemy_hp := float(enemy["hp"])
    kill(sim, phoenix)
    check(ally["hp"] == 400 and enemy["hp"] == enemy_hp and not phoenix["alive"], "Phoenix death burst heals 30 percent Max HP only to surviving allies")
    sim = arena()
    var penguin := actor(sim, "card_water_03", "player", Vector2(3, 3), true)
    ally = actor(sim, "card_fire_01", "player", Vector2(4, 3))
    ally["max_hp"] = 1000
    ally["hp"] = 100
    sim._try_cast_heal(penguin, penguin["ability"])
    sim._step = 2
    sim._time = 2
    sim._tick_area_effects()
    sim._resolve_pending_effects()
    check(is_equal_approx(float(ally["hp"]), 155), "Penguins gain a relative 10 percent heal, from 5 to 5.5 percent Max HP")
    sim = arena()
    var tree := actor(sim, "card_earth_01", "player", Vector2(3, 3), true)
    ally = actor(sim, "card_fire_01", "player", Vector2(7, 3))
    ally["max_hp"] = 1000
    ally["hp"] = 100
    tree["ability_timer"] = 0
    sim._tick_auras()
    sim._resolve_pending_effects()
    check(ally["hp"] == 120 and is_equal_approx(float(tree["visual_scale"]), 1.2), "ancient tree's larger aura reaches allies outside the old large radius")
    sim = arena()
    var plant := actor(sim, "card_earth_02", "player", Vector2(3, 3), true)
    enemy = actor(sim, "card_fire_06", "opponent", Vector2(6, 3))
    enduring(enemy)
    sim._tick_pull_unit(plant, enemy, plant["ability"])
    var rooted_position: Vector2 = sim._unit_position(enemy)
    sim._attempt_move(enemy, Vector2.RIGHT)
    check(sim._unit_position(enemy) == rooted_position and not sim._begin_transit(enemy, enemy["ability"]), "pulled roots stop walking and starting a backline escape")
    sim._time = 2.1
    sim._attempt_move(enemy, Vector2.RIGHT)
    check(sim._unit_position(enemy) != rooted_position, "root expiry restores movement")
    sim = arena()
    var guard := actor(sim, "card_water_05", "player", Vector2(3, 3), true)
    enemy = actor(sim, "card_fire_01", "opponent", Vector2(3.8, 3))
    enduring(enemy)
    for index in range(3):
        sim._perform_attack(guard, enemy)
    sim._resolve_pending_effects()
    check(is_equal_approx(1000000.0 - float(enemy["hp"]), 4 * float(guard["attack"])), "Tidal Guard's third strike is 200 percent")
    var wizard := actor(sim, "card_water_04", "player", Vector2(10, 7), true)
    check(wizard["ability"]["pushback"] == "moderate" and wizard["ability"]["slow_seconds"] == 1, "water wizard gains stronger pushback and its one-second slow")
    var nymph := actor(sim, "card_water_06", "player", Vector2(12, 7), true)
    check(nymph["ability"]["pushback"] == "large", "Nymph retains its distinct stronger gush push")
    sim._apply_speed_debuff(enemy, nymph["ability"])
    check(sim._speed_after_debuffs(enemy, "movement_speed") < int(enemy["movement_speed"]), "gush's added movement slow takes effect")
    sim._step = 1.1
    sim._tick_status_effects()
    check(sim._speed_after_debuffs(enemy, "movement_speed") == int(enemy["movement_speed"]), "gush/wizard slow expires after one second")

func stacking_and_splits() -> void:
    var sim := arena()
    var bear := actor(sim, "card_earth_03", "player", Vector2(3, 3), true)
    var target := actor(sim, "card_fire_01", "opponent", Vector2(3.8, 3))
    enduring(target, 100)
    for index in range(30):
        UnitUpgradeEffects.attack_profile(bear, str(target["id"]))
    check(bear["upgrade_focus_count"] == 10 and UnitUpgradeEffects.attack_profile(bear, "different")["multiplier"] == 1.05, "Bear focus is capped at 50 percent and resets on target change")
    var sage := actor(sim, "card_earth_05", "player", Vector2(3, 5), true)
    var cannon := actor(sim, "card_slime_02", "player", Vector2(3, 6), true)
    for index in range(20):
        UnitUpgradeEffects.on_hit(sim, sage, target)
        UnitUpgradeEffects.on_hit(sim, cannon, target)
    check(is_equal_approx(sim._effective_defense(target), 70), "Spore armor reduction caps at 30 percent")
    check(sim._speed_after_debuffs(target, "attack_speed") == roundi(float(target["attack_speed"]) * 0.7), "Cannon Attack Speed reduction caps at 30 percent")
    var unchanged := float(bear["defense"])
    UnitUpgradeEffects.on_hit(sim, sage, bear)
    check(sim._effective_defense(bear) == unchanged, "stacking effects reject allies")
    sim._time = 5.1
    check(sim._effective_defense(target) == 100 and sim._speed_after_debuffs(target, "attack_speed") == int(target["attack_speed"]), "stacked modifiers restore original stats after expiry")
    var mole := actor(sim, "card_earth_06", "player", Vector2(8, 8), true)
    target["x"] = 8.8
    target["y"] = 8
    for index in range(100):
        UnitUpgradeEffects.on_hit(sim, mole, target)
    check(sim._events.any(func(event): return event.get("kind") == "upgrade_knockback"), "Mole gains actual seeded knockback events")
    sim = arena()
    var giant := actor(sim, "card_slime_01", "player", Vector2(3, 3), true)
    var original_hp := float(giant["max_hp"])
    var original_attack := float(giant["attack"])
    kill(sim, giant)
    var children: Array = sim._units.filter(func(unit): return unit.get("split_depth", 0) == 1)
    check(children.size() == 2, "upgraded Giant first creates two smaller bodies")
    for child in children:
        kill(sim, child)
    var tiny: Array = sim._units.filter(func(unit): return unit.get("split_depth", 0) == 2)
    check(tiny.size() == 4 and tiny.all(func(unit): return unit["max_hp"] == round(round(original_hp * 0.5) * 0.5) and unit["attack"] == round(round(original_attack * 0.5) * 0.5)), "second generation contains four half-parent HP/ATK tiny slimes")
    for child in tiny:
        kill(sim, child)
    check(sim._units.size() == 7, "tiny slimes cannot split into an unbounded family")
    giant["revives_remaining"] = 1
    giant["revive_health_pct"] = 50
    sim._revive_unit(giant)
    kill(sim, sim._units.back())
    check(sim._units.size() == 8, "a revived original cannot split for a second time")

func death_fields() -> void:
    for id in ["card_slime_03", "card_slime_04"]:
        var sim := arena()
        var source := actor(sim, id, "player", Vector2(3, 3), true)
        var target := actor(sim, "card_fire_01", "opponent", Vector2(4, 3))
        enduring(target, 100)
        kill(sim, source)
        if id == "card_slime_03":
            check(sim._effective_defense(target) == 80, "Slime Ball leaves an enemy DEF field after its burst")
        else:
            check(sim._speed_after_debuffs(target, "movement_speed") == roundi(float(target["movement_speed"]) * 0.85) and sim._area_effects.any(func(area): return area["type"] == "damage_area"), "Slime Barrel preserves damage and adds its movement field")
        target["x"] = 12
        check(sim._effective_defense(target) == 100 and sim._speed_after_debuffs(target, "movement_speed") == int(target["movement_speed"]), "leaving a death field immediately restores its affected stat")
    var sim := arena()
    var medic := actor(sim, "card_slime_05", "player", Vector2(3, 3), true)
    var medic_two := actor(sim, "card_slime_05", "player", Vector2(3, 4), true)
    var ally := actor(sim, "card_earth_03", "player", Vector2(4, 3))
    ally["max_hp"] = 1000
    ally["hp"] = 100
    kill(sim, medic)
    kill(sim, medic_two)
    sim._step = 1
    for index in range(5):
        sim._time += 1
        sim._tick_area_effects()
        sim._resolve_pending_effects()
    check(ally["hp"] == 600 and sim._area_effects.is_empty(), "overlapping death remedies restore at most 10 percent per second for five seconds")
    sim = arena()
    var sticky := actor(sim, "card_slime_06", "player", Vector2(5, 5), true)
    var enemies: Array[Dictionary] = []
    for index in range(4):
        var unit := actor(sim, "card_fire_01", "opponent", Vector2(5.8 + float(index % 2), 5 + float(index / 2)))
        enduring(unit)
        enemies.append(unit)
    kill(sim, sticky)
    check(sim._links.size() == 1 and sim._links[0]["target_ids"].size() == 4, "Sticky's death web links every enemy in its medium radius")
    sim._queue_raw_damage(str(enemies[0]["id"]), 100, "player", "fixture", "fixture")
    sim._resolve_pending_effects()
    check(enemies[0]["hp"] == 999900 and enemies.slice(1).all(func(unit): return unit["hp"] == 999975), "death web shares 25 percent once to each partner without recursive amplification")
    sim._time = 5.1
    sim._tick_special_effects()
    check(sim._links.is_empty(), "the death web expires while its owner remains dead")

func old_and_seeded() -> void:
    var cards: Array = db.get_cards_by_set("set_fire_01").slice(0, 4)
    var counts := {}
    for card in cards:
        counts[card["id"]] = 1
    var left := {"id": "player", "cards": cards, "unit_counts": counts}
    var right := left.duplicate(true)
    right["id"] = "opponent"
    var balance: Dictionary = db.get_game_balance().duplicate(true)
    balance["match"]["round_time_seconds"] = 5
    var plain := CombatSimulator.new().simulate(left, right, 100, balance)
    left["unit_upgrades"] = []
    right["unit_upgrades"] = []
    check(CombatSimulator.new().simulate(left, right, 100, balance) == plain, "empty upgrade ownership preserves baseline battle events/frames and RNG")
    left["unit_upgrades"] = UnitUpgrades.definitions(db.get_upgrade_rules(), cards.map(func(card): return card["id"]))
    right["unit_upgrades"] = left["unit_upgrades"].duplicate(true)
    var upgraded := CombatSimulator.new().simulate(left, right, 100, balance)
    check(CombatSimulator.new().simulate(left, right, 100, balance) == upgraded, "real upgraded battles reproduce with a fixed seed")
    check(upgraded["frames"][0]["units"].all(func(unit): return unit.get("unit_level") == 2), "replay actors retain their upgraded appearance level")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
