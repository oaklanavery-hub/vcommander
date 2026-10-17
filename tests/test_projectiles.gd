extends SceneTree
const Simulator = preload("res://scripts/combat/combat_simulator.gd")
var failed := false

func unit(id_value: String, side: String, x: float, y: float) -> Dictionary:
    return {"id": id_value, "side": side, "x": x, "y": y, "alive": true, "hp": 100, "max_hp": 100, "defense": 0, "ability": {}}

func shot() -> Dictionary:
    return {"id": 1, "x": 0.0, "y": 2.0, "source_id": "archer", "source_side": "player", "target_id": "target", "raw_damage": 20.0, "ability": {}}

func _init() -> void:
    var sim = Simulator.new()
    sim._reset(7, {})
    sim._projectile_units_per_second = 100.0
    sim._units.assign([unit("archer", "player", 0, 2), unit("ally", "player", 2, 2), unit("blocker", "opponent", 4, 2), unit("target", "opponent", 8, 2)])
    sim._projectiles.assign([shot()])
    sim._time = 0.1
    sim._tick_projectiles()
    sim._resolve_pending_effects()
    check(sim._unit_by_id("blocker")["hp"] == 80, "first enemy intercepts a fast projectile")
    check(sim._unit_by_id("target")["hp"] == 100, "projectile stops at interceptor")
    check(sim._unit_by_id("ally")["hp"] == 100, "projectiles pass through allies")
    check(sim._projectiles.is_empty(), "intercepted projectile removed")
    sim._projectiles.assign([shot()])
    sim._unit_by_id("target")["alive"] = false
    sim._tick_projectiles()
    check(sim._projectiles.is_empty(), "dead locked target fizzles projectile")
    check(sim._unit_by_id("blocker")["hp"] == 80, "fizzle cannot damage an interceptor")
    sim._units.assign([unit("archer", "player", 0, 2), unit("target", "opponent", 8, 2)])
    sim._projectiles.assign([shot()])
    sim._projectile_units_per_second = 12.0
    for index in range(20):
        sim._time += 0.1
        sim._unit_by_id("target")["y"] = 2.0 + sin(float(index))
        sim._tick_projectiles()
        sim._resolve_pending_effects()
    check(sim._unit_by_id("target")["hp"] == 80, "committed shot follows and hits a living moving target")
    if not failed:
        print("Projectile tests passed: interception, allies, tunneling, fizzle, moving target.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
