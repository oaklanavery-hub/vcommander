extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failed = true
        push_error("TEST FAILED: " + message)

func setup(element: String, owner: String = "player") -> CombatSimulator:
    var sim := CombatSimulator.new()
    sim._reset(520, db.get_game_balance())
    var card: Dictionary = db.get_card("card_%s_06" % element).duplicate(true)
    card["id"] = "future_specialist"
    sim._spawn_side({"id": owner, "cards": [card], "unit_counts": {"future_specialist": 1}}, owner == "opponent")
    var enemy: Dictionary = db.get_card("card_earth_03").duplicate(true)
    enemy["id"] = "future_victim"
    enemy["ability"] = {"id": "basic", "type": "basic_melee"}
    sim._spawn_side({"id": sim._other_side(owner), "cards": [enemy], "unit_counts": {"future_victim": 2}}, owner != "opponent")
    var mirror := owner == "opponent"
    sim._units[0].merge({"x": 16.0 if mirror else 8.0, "y": 7.0}, true)
    sim._units[1].merge({"x": 11.0 if mirror else 13.0, "y": 7.0, "hp": 10000.0, "max_hp": 10000, "defense": 0}, true)
    sim._units[2].merge({"x": 4.0 if mirror else 20.0, "y": 7.0, "hp": 10000.0, "max_hp": 10000, "defense": 0, "role": "range"}, true)
    return sim

func advance(sim: CombatSimulator, until: float) -> void:
    while sim._time < until - 0.0001:
        sim._time += sim._step
        sim._tick_special_effects()
        sim._resolve_pending_effects()

func test_transit() -> void:
    for element in ["fire", "water", "earth"]:
        for owner in ["player", "opponent"]:
            var sim := setup(element, owner)
            var actor: Dictionary = sim._units[0]
            check(sim._begin_transit(actor, actor["ability"]), "generic future content can cast " + element)
            check(actor["target_id"] == sim._units[2]["id"], "transit chooses the enemy backline on either team")
            var before := float(actor["hp"])
            sim._queue_raw_damage(str(actor["id"]), 100, sim._other_side(owner), "other", "damage_over_time")
            sim._resolve_pending_effects()
            check((actor["hp"] == before) == (element != "earth"), "only explicitly invulnerable transit rejects damage")
            advance(sim, 1.1)
            check(actor.get("transit", {}).is_empty(), "transit resolves in bounded simulation time")
            check(absf(float(actor["x"]) - float(sim._units[2]["x"])) < 4, "arrives beside the enemy backline")
            if element == "fire":
                check(not sim._hazards.is_empty() and float(sim._units[1]["hp"]) < 10000, "swept flame trail damages enemies on its path")
                check(actor["hp"] == before, "own flame trail never damages its caster")
            if element == "water":
                var hits := sim._events.filter(func(e): return e.get("source") == "gush" and e.get("target_id") == sim._units[1]["id"])
                check(hits.size() == 1 and float(sim._units[1]["hp"]) < 10000, "gush damages each contacted enemy once")
                check(absf(float(sim._units[1]["y"]) - 7) > 0.1 or absf(float(sim._units[1]["x"]) - (11 if owner == "opponent" else 13)) > 0.1, "gush visibly displaces contacted enemies")
            if element == "earth":
                check(sim._obstacles.size() == 1, "burrow creates authoritative crack geometry")
                var expires := float(sim._obstacles[0]["expires_at"])
                advance(sim, expires - 0.1)
                check(sim._obstacles.size() == 1, "crack persists for its full five seconds")
                advance(sim, expires)
                check(sim._obstacles.is_empty(), "crack expires on its simulation deadline")
            actor["ability_cooldown"] = 0.3
            sim._tick_units()
            check(not sim._is_invulnerable(actor), "cooldown does not grant immunity")

func test_terrain() -> void:
    for owner in ["player", "opponent"]:
        var sim := setup("earth", owner)
        var actor: Dictionary = sim._units[0]
        actor.merge({"x": 8.0, "y": 7.0}, true)
        sim._units[1].merge({"x": 20.0, "y": 2.0}, true)
        sim._units[2].merge({"x": 21.0, "y": 12.0}, true)
        sim._obstacles.append({"from_x": 10.0, "from_y": 4.0, "to_x": 10.0, "to_y": 10.0, "expires_at": 5.0})
        sim._displace_unit(actor, Vector2(12, 7))
        check(actor["x"] == 8.0, "forced displacement cannot cross a crack for either team")
        for i in range(200):
            sim._move_toward(actor, {"x": 12.0, "y": 7.0})
            check(CombatTerrain.clear_line(sim._unit_position(actor), sim._unit_position(actor), sim._obstacles, sim._collision_radius), "detours never cross or occupy crack geometry")
        check(sim._unit_position(actor).distance_to(Vector2(12, 7)) < 0.6, "both teams find a route around the barrier endpoint")
    var sim := setup("earth")
    var mole: Dictionary = sim._units[0]
    var enemy: Dictionary = sim._units[1]
    mole["attack"] = 100
    for strike in range(3):
        sim._perform_attack(mole, enemy)
        sim._resolve_pending_effects()
    check(enemy["hp"] == 9620.0, "third strike is empowered without adding damage to the first two")

func test_links() -> void:
    var sim := setup("slime")
    var caster: Dictionary = sim._units[0]
    var a: Dictionary = sim._units[1]
    var b: Dictionary = sim._units[2]
    b["x"] = 12.0
    a["x"] = 11.0
    sim._cast_damage_link(caster, a, caster["ability"])
    check(sim._links.size() == 1 and sim._links[0]["target_ids"].size() == 2, "Sticky links two enemies in reach")
    sim._queue_raw_damage(str(a["id"]), 100, "player", "first_ally", "normal_attack")
    sim._queue_raw_damage(str(a["id"]), 40, "player", "second_ally", "damage_over_time")
    sim._resolve_pending_effects()
    check(a["hp"] == 9860 and b["hp"] == 9930, "damage from different allies and sources shares once without recursion")
    var duplicate: Dictionary = sim._links[0].duplicate(true)
    sim._links.append(duplicate)
    sim._queue_raw_damage(str(b["id"]), 100, "player", "first_ally", "projectile")
    sim._resolve_pending_effects()
    check(a["hp"] == 9810 and b["hp"] == 9830, "overlapping marks cannot double-copy damage to the same partner")
    advance(sim, 5)
    sim._queue_raw_damage(str(a["id"]), 100, "player", "first_ally", "normal_attack")
    sim._resolve_pending_effects()
    check(b["hp"] == 9830 and sim._links.is_empty(), "expired marks no longer share")
    b["alive"] = false
    sim._cast_damage_link(caster, a, caster["ability"])
    check(sim._links[0]["target_ids"].size() == 1, "a lone enemy can be marked without inventing another victim")
    b["alive"] = true
    sim._links.clear()
    sim._cast_damage_link(caster, a, caster["ability"])
    a["ability"] = {"type": "absorb_burst", "absorb_pct": 30}
    var before := float(b["hp"])
    sim._queue_raw_damage(str(a["id"]), 100, "player", "ally", "normal_attack")
    sim._resolve_pending_effects()
    check(is_equal_approx(before - float(b["hp"]), 35), "only actual post-absorption damage is copied")
    b["transit"] = {"invulnerable": true}
    before = float(b["hp"])
    sim._queue_raw_damage(str(a["id"]), 100, "player", "ally", "normal_attack")
    sim._resolve_pending_effects()
    check(b["hp"] == before, "shared damage respects transit invulnerability")

func test_full_simulation() -> void:
    var player := {"id": "player", "cards": [], "unit_counts": {}}
    var opponent := {"id": "opponent", "cards": [], "unit_counts": {}}
    for element in ["fire", "water", "earth", "slime"]:
        var card: Dictionary = db.get_card("card_%s_06" % element)
        for side in [player, opponent]:
            side["cards"].append(card)
            side["unit_counts"][card["id"]] = 4
    var sim := CombatSimulator.new()
    var a := sim.simulate(player, opponent, 620, db.get_game_balance())
    var b := sim.simulate(player, opponent, 620, db.get_game_balance())
    check(a == b and float(a["duration"]) <= 120, "capped specialist armies reproduce exactly and finish within the round bound")
    check(not a["frames"].back().get("links", []).is_empty() or a["events"].any(func(e): return e.get("kind") == "sticky_link"), "full combat exercises link casts")
    for stat in ["health", "attack", "defense", "attack_speed"]:
        var value := sim._modified_stat(100, stat, {"buffs": [{"definition": {"stat": stat, "percentage": 25}, "stacks": 10000}]})
        check(is_finite(value) and value >= 100, "unlimited stacking cannot overflow core arithmetic: " + stat)

func run() -> void:
    db = root.get_node("ContentDatabase")
    test_transit()
    test_terrain()
    test_links()
    test_full_simulation()
    if not failed:
        print("Assassin tests passed: mirrored transit/backline/immunity, swept trail/gush, five-second terrain and bidirectional detours, third strikes, allied damage links/expiry/absorption, capped-army determinism and numeric safety.")
    quit(1 if failed else 0)
