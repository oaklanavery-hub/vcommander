extends SceneTree
const Simulator = preload("res://scripts/combat/combat_simulator.gd")
var failed := false

func _init() -> void:
    call_deferred("run")

func side(db, commander: Dictionary, side_id: String) -> Dictionary:
    var cards: Array = db.get_cards_by_set(str(commander["signature_set_id"]))
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = int(card["unit_cap"])
    var buffs: Array[Dictionary] = []
    for buff in db.get_all_buffs():
        buffs.append({"definition": buff, "stacks": 3})
    return {"id": side_id, "commander": commander, "commander_skill_active": true, "cards": cards, "unit_counts": counts, "buffs": buffs, "set_bonus": db.get_signature_set(str(commander["signature_set_id"])).get("bonus", {})}

func run() -> void:
    var db = root.get_node("ContentDatabase")
    var maximum_units := 0
    for commander in db.get_all_commanders():
        for seed_value in [7001, 7002]:
            var simulator = Simulator.new()
            var result: Dictionary = simulator.simulate(side(db, commander, "player"), side(db, commander, "opponent"), seed_value, db.get_game_balance())
            check(float(result["duration"]) <= 120.001, "maxed armies always finish within round limit")
            check(str(result["winner"]) in ["player", "opponent", "draw"], "valid stress result")
            maximum_units = maxi(maximum_units, result["frames"][0]["units"].size())
            for unit in simulator._units:
                check(int(unit["attack_speed"]) <= 200 and int(unit["movement_speed"]) <= 200, "speed caps hold with every Buff maxed")
                check(float(unit["x"]) >= 0 and float(unit["x"]) <= 24 and float(unit["y"]) >= 0 and float(unit["y"]) <= 14, "unit stays in visible battlefield")
                check(float(unit["hp"]) >= 0 and float(unit["hp"]) <= float(unit["max_hp"]), "HP remains valid")
    check(maximum_units == 46, "Earth mirrors include all capped units and both six-plant skills")
    if not failed:
        print("Roster stress tests passed: six capped battles, all Buffs, all skills, up to 46 units.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
