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
    if not failed:
        print("Battle readability tests passed: between-frame flight, moving interception, contact, exact lethal HP and fizzle.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
