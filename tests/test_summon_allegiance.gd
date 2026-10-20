extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func side(id: String, db, skill: bool = true) -> Dictionary:
    var cards: Array = db.get_cards_by_set("set_earth_01").slice(0, 4)
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = 1
    return {"id": id, "commander": db.get_commander("commander_earth_01"), "commander_skill_active": skill, "cards": cards, "unit_counts": counts}

func audit(result: Dictionary) -> void:
    var owners := {}
    var summons := {"player": 0, "opponent": 0}
    var seed_hits := {"player": 0, "opponent": 0}
    for event in result["events"]:
        if event.get("type") == "spawn":
            owners[str(event["unit_id"])] = str(event["side"])
            if event.get("source") == "commander_skill":
                summons[str(event["side"])] += 1
        elif event.get("type") in ["attack", "projectile_impact", "damage"]:
            var source := str(event.get("source_unit_id", event.get("unit_id", "")))
            var target := str(event.get("target_id", ""))
            if owners.has(source) and owners.has(target):
                check(owners[source] != owners[target], "all recorded attacks/impacts/damage stay on opposing teams")
            if event.get("type") == "projectile_impact" and event.get("card_id") == "commander_plant":
                seed_hits[owners[source]] += 1
    check(summons == {"player": 6, "opponent": 6}, "each Earth Commander owns its own six plants")
    check(seed_hits["player"] > 0 and seed_hits["opponent"] > 0, "both sides' summons still land valid enemy hits")
    for unit in result["frames"][0]["units"]:
        check(bool(unit.get("summoned", false)) == str(unit["id"]).contains(":commander_plant:"), "summon ownership markers identify summoned units independently of field position")

func run() -> void:
    var db = root.get_node("ContentDatabase")
    var player := side("player", db)
    var opponent := side("opponent", db)
    var result := CombatSimulator.new().simulate(player, opponent, 1729, {"match": {"round_time_seconds": 25}})
    audit(result)
    # A bad existing lock must never bypass enemy acquisition or create
    # friendly seed damage. Exercise each boundary independently.
    for owner in ["player", "opponent"]:
        var sim := CombatSimulator.new()
        sim._reset(7, {})
        sim._spawn_side(player, false)
        sim._spawn_side(opponent, true)
        sim._resolve_pre_battle_skills(player, opponent)
        var plant := sim._unit_by_id(owner + ":commander_plant:0")
        var ally := sim._unit_by_id(owner + ":card_earth_04:0")
        plant["target_id"] = ally["id"]
        var target := sim._locked_or_new_target(plant)
        check(not target.is_empty() and target.get("side") != owner, "stale allied lock is discarded and retargeted to an enemy")
        sim._perform_attack(plant, ally)
        check(sim._projectiles.is_empty() and sim._pending_damage.is_empty(), "direct allied attack cannot release a seed or queue damage")
        var allied_plant := sim._unit_by_id(owner + ":commander_plant:1")
        plant["target_id"] = allied_plant["id"]
        check(sim._locked_or_new_target(plant).get("side") != owner, "allied summons are never valid locked enemies either")
        sim._perform_attack(plant, allied_plant)
        check(sim._projectiles.is_empty(), "plants cannot attack other allied plants")
        var health := {}
        for unit in sim._alive_units(owner):
            health[unit["id"]] = unit["hp"]
        sim._projectiles.assign([{"id": 77, "source_id": plant["id"], "source_side": owner, "target_id": ally["id"], "x": plant["x"], "y": plant["y"], "raw_damage": 100, "ability": plant["ability"]}])
        sim._time = 0.1
        sim._tick_projectiles()
        sim._resolve_pending_effects()
        check(sim._projectiles.is_empty(), "an in-flight seed with an allied lock fizzles")
        for unit in sim._alive_units(owner):
            check(unit["hp"] == health[unit["id"]], "invalid seed cannot damage its owner or any ally")
        sim._queue_raw_damage(str(ally["id"]), 100, owner, str(plant["id"]), "projectile")
        check(sim._pending_damage.is_empty(), "damage queue independently rejects friendly damage")
        sim._pending_damage.assign([{"target_id": ally["id"], "amount": 100, "source_side": owner, "source_unit_id": plant["id"], "source": "projectile"}])
        sim._resolve_pending_effects()
        check(ally["hp"] == health[ally["id"]], "damage application also rejects a malformed allied hit")
        var enemy := sim._locked_or_new_target(plant)
        var enemy_hp := 0.0
        for unit in sim._alive_units(str(enemy["side"])):
            enemy_hp += float(unit["hp"])
        plant["alive"] = false
        sim._projectile_units_per_second = 100.0
        sim._projectiles.assign([{"id": 78, "source_id": plant["id"], "source_side": owner, "target_id": enemy["id"], "x": plant["x"], "y": plant["y"], "raw_damage": 100, "ability": plant["ability"]}])
        sim._time = 0.2
        sim._tick_projectiles()
        sim._resolve_pending_effects()
        var after := 0.0
        for unit in sim._alive_units(str(enemy["side"])):
            after += float(unit["hp"])
        check(after < enemy_hp, "committed enemy seed still hits after its shooter dies")
    if not failed:
        print("Summon allegiance tests passed: both Commanders, enemy-only locks/attacks/seeds/damage and valid enemy hits.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
