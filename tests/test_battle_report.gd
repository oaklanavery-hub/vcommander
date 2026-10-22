extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func body(id: String, side: String, card: String, role: String = "melee") -> Dictionary:
    return {"id": id, "side": side, "card_id": card, "name": card, "role": role, "hp": 100.0, "max_hp": 100.0}

func row(report: Dictionary, side: String, card: String) -> Dictionary:
    for entry in report["sides"][side]["rows"]:
        if entry["card_id"] == card:
            return entry
    return {}

func run() -> void:
    var a := body("p:a", "player", "future_family", "tank")
    var child := body("p:child", "player", "future_family", "tank")
    var healer := body("p:h", "player", "future_healer", "healer")
    var b := body("o:b", "opponent", "future_enemy")
    var result := {"duration": 5.0, "winner": "player", "reason": "elimination", "frames": [], "events": [
        {"type": "spawn", "time": 0, "unit": a}, {"type": "spawn", "time": 0, "unit": b}, {"type": "spawn", "time": 0, "unit": healer},
        {"type": "damage", "time": 1, "target_id": "p:a", "source_unit_id": "o:b", "source_side": "opponent", "amount": 70.0, "hp_loss": 70.0, "hp_after": 30.0, "absorbed": 30.0},
        {"type": "heal", "time": 1.5, "target_id": "p:a", "source_unit_id": "p:h", "amount": 19, "effective_healing": 18.5, "hp_after": 48.5},
        {"type": "damage", "time": 2, "target_id": "p:a", "source_unit_id": "o:b", "source_side": "opponent", "amount": 200.0, "hp_loss": 48.5, "hp_after": -151.5},
        {"type": "defeat", "time": 2, "unit_id": "p:a"},
        {"type": "spawn", "time": 2, "source": "death_split", "unit": child},
        {"type": "ability", "time": 2.1, "unit_id": "p:child"},
        {"type": "damage", "time": 3, "target_id": "o:b", "source_unit_id": "p:a", "source_side": "player", "amount": 500.0, "hp_loss": 100.0, "hp_after": -400.0},
        {"type": "damage", "time": 3, "target_id": "o:b", "source_unit_id": "p:child", "source_side": "player", "amount": 500.0, "hp_loss": 0.0, "hp_after": -900.0},
        {"type": "defeat", "time": 3, "unit_id": "o:b"}
    ]}
    var original := JSON.stringify(result)
    var report := BattleReport.build(result)
    check(JSON.stringify(result) == original and report == BattleReport.build(result), "aggregation is deterministic and never mutates replay evidence")
    var family := row(report, "player", "future_family")
    check(family["damage"] == 100 and family["kills"] == 1 and family["absorbed"] == 30 and family["taken"] == 118.5, "overkill is excluded, late hits do not steal kills and dead sources retain damage credit")
    check(family["initial"] == 1 and family["spawned"] == 2 and family["survived"] == 1 and family["average_survival"] == 2.5 and family["abilities"] == 1, "children group with their card while bodies and actual survival stay separate")
    check(row(report, "player", "future_healer")["healing"] == 18.5, "healing uses the effective fractional HP change")
    check(report["sides"]["player"]["highlights"]["healing"]["card_id"] == "future_healer" and report["sides"]["player"]["highlights"]["protection"]["card_id"] == "future_family", "healers and protectors get their own evidence-based highlights")
    check(report["sides"]["opponent"]["totals"]["damage"] == report["sides"]["player"]["totals"]["taken"], "two-sided damage/taken totals conserve HP loss")
    test_real_events()
    var empty := BattleReport.build({})
    check(empty["sides"]["player"]["rows"].is_empty() and empty["sides"]["player"]["highlights"]["damage"].is_empty(), "empty evidence invents no actors, highlights or results")
    if not failed:
        print("Battle report tests passed: exact HP/overkill/healing/absorption, both sides, kill attribution, death sources/children, survival, separate highlights, Commander summons and replay immutability.")
    quit(1 if failed else 0)

func test_real_events() -> void:
    var db := root.get_node("ContentDatabase")
    var sim := CombatSimulator.new()
    sim._reset(104, db.get_game_balance())
    var card: Dictionary = db.get_card("card_slime_03").duplicate(true)
    sim._spawn_side({"id": "player", "cards": [card], "unit_counts": {card["id"]: 1}}, false)
    var unit: Dictionary = sim._units[0]
    unit["hp"] = 10.0
    sim._pending_damage.append({"target_id": unit["id"], "source_side": "opponent", "source_unit_id": "", "source": "commander_skill_direct", "amount": 100.0})
    sim._resolve_pending_effects()
    var damage: Dictionary = sim._events.filter(func(e): return e.get("type") == "damage")[0]
    check(damage["amount"] == 70 and damage["hp_loss"] == 10 and damage["absorbed"] == 30, "real simulation records capped HP damage without changing full absorption or burst charge")
    var report := BattleReport.build({"duration": 0, "events": sim._events, "frames": []})
    check(row(report, "opponent", "@commander")["damage"] == 10 and row(report, "opponent", "@commander")["kills"] == 1, "pre-battle Commander damage is attributed separately from army units")
    sim = CombatSimulator.new()
    sim._reset(105, db.get_game_balance())
    sim._spawn_side({"id": "player", "cards": [card], "unit_counts": {card["id"]: 1}}, false)
    unit = sim._units[0]
    unit["hp"] = float(unit["max_hp"]) - 0.3
    sim._pending_heal.append({"target_id": unit["id"], "source_unit_id": unit["id"], "amount": 100.0})
    sim._resolve_pending_effects()
    var heal: Dictionary = sim._events.back()
    check(heal["type"] == "heal" and is_equal_approx(float(heal["effective_healing"]), 0.3), "real capped healing preserves fractions instead of dropping a sub-half-HP event")
    var commander := {"id": "player", "commander_skill_active": true, "commander": db.get_commander("commander_earth_01")}
    sim._spawn_summon_skill_if_active(commander)
    var summons: Array = sim._events.filter(func(e): return e.get("type") == "spawn" and e.get("summoned", false))
    check(summons.size() == 6 and summons[0].has("unit"), "Commander summons carry the same immutable actor identity as ordinary births")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
