extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func side(id: String, skill: bool = false, theme: bool = true) -> Dictionary:
    var cards: Array = db.get_cards_by_set("set_slime_01").slice(0, 4)
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = 1
    return {"id": id, "commander": db.get_commander("commander_slime_01"), "commander_skill_active": skill,
        "cards": cards, "unit_counts": counts, "set_bonus": db.get_signature_set("set_slime_01").get("bonus", {}) if theme else {}}

func setup(skill: bool = false, theme: bool = true) -> CombatSimulator:
    var sim := CombatSimulator.new()
    sim._reset(814, db.get_game_balance())
    sim._spawn_side(side("player", skill, theme), false)
    sim._spawn_side(side("opponent", false, false), true)
    if skill:
        sim._resolve_pre_battle_skills(side("player", true, theme), side("opponent", false, false))
    return sim

func kill(sim: CombatSimulator, unit: Dictionary) -> void:
    sim._queue_raw_damage(str(unit["id"]), 1000000, sim._other_side(str(unit["side"])), "", "test")
    sim._resolve_pending_effects()

func spawns(sim: CombatSimulator, cause: String) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for event in sim._events:
        if event.get("type") == "spawn" and event.get("source") == cause:
            found.append(event)
    return found

func run() -> void:
    db = root.get_node("ContentDatabase")
    var expected := [[1, 4], [2, 4], [2, 6], [2, 6]]
    var cards: Array = db.get_cards_by_set("set_slime_01").slice(0, 4)
    check(cards.size() == 4, "Slime Court keeps its four original starter cards")
    for i in range(cards.size()):
        check([int(cards[i]["summon_amount"]), int(cards[i]["unit_cap"])] == expected[i], "user-specified Slime recruit amounts/caps")
    check(SetBonusChecker.is_complete(cards, "set_slime_01", 4), "four Slime cards activate the theme")
    var mixed := cards.duplicate()
    mixed[0] = db.get_card("card_water_01")
    check(not SetBonusChecker.is_complete(mixed, "set_slime_01", 4), "mixed warband does not activate Slime theme")
    test_split()
    test_revival()
    test_slow()
    test_barrel()
    test_prebattle_and_determinism()
    if not failed:
        print("Slime commander tests passed: recruitment, death splits, revival, triggered bonus, slow expiry, ten-second enemy-only areas and determinism.")
    quit(1 if failed else 0)

func test_split() -> void:
    for owner in ["player", "opponent"]:
        var sim := setup(false, owner == "player")
        var giant := sim._unit_by_id(owner + ":card_slime_01:0")
        var original_attack := int(giant["attack"])
        check(original_attack == int(db.get_card("card_slime_01")["stats"]["attack"]), "theme never buffs ordinary round-start spawns")
        kill(sim, giant)
        var children := spawns(sim, "death_split")
        check(children.size() == 2, "a Giant produces exactly two children on either side")
        var ids := {}
        for event in children:
            var child := sim._unit_by_id(str(event["unit_id"]))
            check(child["side"] == owner and child["max_hp"] == int(giant["max_hp"]) / 2, "children retain owner and half Max HP")
            check(int(child["attack"]) == (original_attack if owner == "player" else original_attack / 2), "half attack is doubled only for a qualifying active theme")
            check(sim._unit_position(child).distance_to(sim._unit_position(giant)) < 2, "children appear near the defeated parent")
            check(float(child["visual_scale"]) < 1 and int(child["revives_remaining"]) == 0, "children are smaller without inherited revival")
            check(not ids.has(str(child["id"])), "death-created IDs are unique")
            ids[str(child["id"])] = true
            for other in sim._alive_units(owner):
                if other["id"] != child["id"]:
                    check(sim._unit_position(child).distance_to(sim._unit_position(other)) >= sim._collision_radius * 2 - 0.001, "new children do not overlap allies")
            kill(sim, child)
        check(spawns(sim, "death_split").size() == 2, "children never split recursively")

func test_revival() -> void:
    var sim := setup(true)
    var giant := sim._unit_by_id("player:card_slime_01:0")
    giant["attack_speed"] = 52
    giant["movement_speed"] = 51
    kill(sim, giant)
    var revivals := spawns(sim, "revival")
    check(revivals.size() == 1 and spawns(sim, "death_split").size() == 2, "first death splits and revives without premature elimination")
    var revived := sim._unit_by_id(str(revivals[0]["unit_id"]))
    check(revived["hp"] == round(float(giant["max_hp"]) * 0.5) and revived["max_hp"] == giant["max_hp"], "revival restores half current HP without reducing Max HP")
    check(int(revived["attack"]) == int(giant["attack"]) * 2 and giant["attack"] == db.get_card("card_slime_01")["stats"]["attack"], "only the revived body receives double attack")
    check(revived["attack_speed"] == 52 and revived["movement_speed"] == 51, "later bodies retain round-wide Frozen Field modifiers")
    check(sim._elimination_result().is_empty(), "new bodies count toward round survival immediately")
    kill(sim, revived)
    check(spawns(sim, "revival").size() == 1 and spawns(sim, "death_split").size() == 2, "revival is spent and the same Giant cannot split a second time")
    var reset := setup()
    check(reset._unit_by_id("player:card_slime_01:0").get("revives_remaining", 0) == 0, "Royal Jelly never leaks into a later round")

func test_slow() -> void:
    var sim := setup()
    var cannon := sim._unit_by_id("player:card_slime_02:0")
    var target := sim._unit_by_id("opponent:card_slime_03:0")
    var nearby := sim._unit_by_id("opponent:card_slime_04:0")
    var ally := sim._unit_by_id("player:card_slime_03:0")
    cannon.merge({"x": 3.0, "y": 7.0}, true)
    target.merge({"x": 4.0, "y": 7.0, "attack_speed": 80, "movement_speed": 100}, true)
    nearby.merge({"x": 4.0, "y": 8.0}, true)
    ally.merge({"x": 4.0, "y": 6.0}, true)
    sim._perform_attack(cannon, target)
    sim._time = 0.1
    sim._tick_projectiles()
    sim._resolve_pending_effects()
    check(not target.get("speed_debuffs", []).is_empty() and not nearby.get("speed_debuffs", []).is_empty(), "slime projectile slows its actual hit and nearby enemies")
    check(ally.get("speed_debuffs", []).is_empty(), "splash never slows allies")
    check(sim._speed_after_debuffs(target, "attack_speed") == 60 and sim._speed_after_debuffs(target, "movement_speed") == 70, "both speed reductions apply multiplicatively to the current ratings")
    sim._apply_speed_debuff(target, cannon["ability"])
    check(target["speed_debuffs"].size() == 1, "repeated Cannon splashes refresh rather than stack")
    for _i in range(30):
        sim._time += sim._step
        sim._tick_status_effects()
    check(target["speed_debuffs"].is_empty() and sim._speed_after_debuffs(target, "attack_speed") == 80, "slow expires without corrupting the round-wide base rating")

func test_barrel() -> void:
    var sim := setup()
    var barrel := sim._unit_by_id("player:card_slime_04:0")
    var enemy := sim._unit_by_id("opponent:card_slime_03:0")
    var entrant := sim._unit_by_id("opponent:card_slime_04:0")
    var ally := sim._unit_by_id("player:card_slime_03:0")
    barrel.merge({"x": 4.0, "y": 7.0}, true)
    enemy.merge({"x": 4.0, "y": 8.0, "hp": 100000.0, "max_hp": 100000, "defense": 0}, true)
    entrant.merge({"x": 12.0, "y": 7.0, "hp": 100000.0, "max_hp": 100000, "defense": 0}, true)
    ally.merge({"x": 5.0, "y": 7.0}, true)
    var ally_hp := float(ally["hp"])
    kill(sim, barrel)
    check(enemy["hp"] < 100000 and ally["hp"] == ally_hp, "Barrel explodes immediately and damages enemies only")
    check(sim._area_effects.size() == 1 and sim._area_effects[0]["remaining"] == 10.0, "Barrel leaves a full ten-second large area")
    check(sim._snapshot()["areas"][0]["type"] == "damage_area", "the damaging area is visible in replay metadata")
    for i in range(110):
        if i == 40:
            entrant["x"] = 5.0
        if i == 70:
            entrant["x"] = 12.0
        sim._time += sim._step
        sim._tick_area_effects()
        sim._resolve_pending_effects()
    var ticks := 0
    var entrant_ticks := 0
    var final_tick := 0.0
    for event in sim._events:
        if event.get("type") == "damage" and event.get("source") == "damage_area":
            if event["target_id"] == enemy["id"]:
                ticks += 1
                final_tick = float(event["time"])
            if event["target_id"] == entrant["id"]:
                entrant_ticks += 1
    check(ticks == 10 and is_equal_approx(final_tick, 10.0), "area deals ten one-second ticks including the tenth second, then stops")
    check(entrant_ticks == 3, "enemies only take pool damage while inside its radius")
    check(sim._area_effects.is_empty() and ally["hp"] == ally_hp, "expired pools are removed and never damage allies")

func test_prebattle_and_determinism() -> void:
    var player := side("player", true)
    var opponent := side("opponent", false, false)
    opponent["commander_skill_active"] = true
    opponent["commander"] = {"active_skill": {"type": "targeted_aoe_max_hp", "meteors": 6, "direct_max_hp_pct": 1000, "aoe_max_hp_pct": 0}}
    var result := CombatSimulator.new().simulate(player, opponent, 612, db.get_game_balance())
    var revivals := 0
    for event in result.get("pre_battle", {}).get("events", []):
        if event.get("source") == "revival":
            revivals += 1
    check(revivals > 0 and not result["pre_battle"]["after"]["units"].is_empty(), "simultaneous pre-battle damage respects the revival blessing")
    var a := CombatSimulator.new().simulate(side("player", true), side("opponent", true), 1018, db.get_game_balance())
    var b := CombatSimulator.new().simulate(side("player", true), side("opponent", true), 1018, db.get_game_balance())
    check(a == b, "Slime splitting, revivals, slows and areas are fully deterministic")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
