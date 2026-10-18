extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    test_damage_paths()
    test_timer_and_radius()
    test_death_and_chains()
    test_revival_and_reset()
    test_full_simulation()
    if not failed:
        print("Absorb burst tests passed: exact post-defense absorption, all damage paths, timed/death bursts, enemy-only radius/pushback, chains, revival, reset and determinism.")
    quit(1 if failed else 0)

func side(owner: String, absorber: bool) -> Dictionary:
    var card: Dictionary = db.get_card("card_slime_03").duplicate(true)
    card["id"] = "future_absorber" if absorber else "future_attacker"
    if not absorber:
        card["ability"] = {"id": "basic", "type": "basic_melee"}
    return {"id": owner, "cards": [card], "unit_counts": {str(card["id"]): 1}}

func setup(owner: String = "player") -> CombatSimulator:
    var sim := CombatSimulator.new()
    sim._reset(1023, db.get_game_balance())
    sim._spawn_side(side(owner, true), owner == "opponent")
    sim._spawn_side(side(sim._other_side(owner), false), owner != "opponent")
    sim._units[0].merge({"x": 8.0, "y": 7.0, "hp": 1000.0, "max_hp": 1000, "defense": 12}, true)
    sim._units[1].merge({"x": 9.0, "y": 7.0, "hp": 1000.0, "max_hp": 1000, "defense": 200}, true)
    return sim

func hit(sim: CombatSimulator, unit: Dictionary, raw: float, cause: String = "test") -> void:
    sim._queue_raw_damage(str(unit["id"]), raw, sim._other_side(str(unit["side"])), "", cause)
    sim._resolve_pending_effects()

func bursts(sim: CombatSimulator) -> Array:
    return sim._events.filter(func(event): return event.get("kind") == "absorb_burst")

func advance(sim: CombatSimulator, time: float) -> void:
    sim._time = time
    sim._tick_absorbed_bursts()
    sim._resolve_pending_effects()

func test_damage_paths() -> void:
    for owner in ["player", "opponent"]:
        var sim := setup(owner)
        var ball: Dictionary = sim._units[0]
        hit(sim, ball, 112)
        check(is_equal_approx(float(ball["hp"]), 930) and is_equal_approx(float(ball["absorbed_damage"]), 30), "30% of post-defense damage is prevented and stored on either team")
        check(sim._events.back()["amount"] == 70 and sim._events.back()["absorbed_total"] == 30, "damage events expose actual health loss and stored charge")
        for i in range(10):
            hit(sim, ball, 1)
        check(is_equal_approx(float(ball["hp"]), 923) and is_equal_approx(float(ball["absorbed_damage"]), 33), "fractional absorption accumulates even on minimum-damage hits")
        var before := float(ball["hp"])
        sim._queue_raw_damage(str(ball["id"]), 1000, owner, "", "friendly")
        sim._resolve_pending_effects()
        check(ball["hp"] == before and is_equal_approx(float(ball["absorbed_damage"]), 33), "rejected friendly damage cannot grant charge")
        # Actual ranged release/impact, not a fabricated source tag.
        var enemy: Dictionary = sim._units[1]
        enemy["ability"] = {"id": "shot", "type": "basic_ranged"}
        enemy["role"] = "range"
        enemy["attack"] = 112
        sim._perform_attack(enemy, ball)
        sim._time += sim._step
        sim._tick_projectiles()
        sim._resolve_pending_effects()
        check(is_equal_approx(float(ball["absorbed_damage"]), 63), "projectile impact uses the same absorption path")
        sim._apply_burn(ball, {"id": "burn", "burn_seconds": 1, "burn_attack_pct_per_second": 100}, str(enemy["id"]), str(enemy["side"]), 112)
        for i in range(10):
            sim._time += sim._step
            sim._tick_status_effects()
            sim._resolve_pending_effects()
        check(is_equal_approx(float(ball["absorbed_damage"]), 93), "damage-over-time ticks are absorbed after defense")
        var caster := side(str(enemy["side"]), false)
        caster["commander_skill_active"] = true
        caster["commander"] = {"active_skill": {"type": "targeted_aoe_max_hp", "meteors": 1, "direct_max_hp_pct": 10, "aoe_max_hp_pct": 0}}
        sim._queue_damage_skill_if_active(caster, owner)
        sim._resolve_pending_effects()
        check(is_equal_approx(float(ball["absorbed_damage"]), 119.4), "pre-battle skill damage also charges the absorber")
        advance(sim, 10)
        check(is_equal_approx(float(enemy["hp"]), 880.6), "either team's burst returns the exact fractional stored total")
    var fractional := setup()
    fractional._units[0]["hp"] = 1.0
    hit(fractional, fractional._units[0], 1)
    check(is_equal_approx(float(fractional._unit_snapshot(fractional._units[0])["hp"]), 0.3), "snapshots preserve a surviving fraction of HP, including pre-battle playback")

func test_timer_and_radius() -> void:
    var sim := setup()
    var ball: Dictionary = sim._units[0]
    var enemy: Dictionary = sim._units[1]
    var edge := enemy.duplicate(true)
    edge.merge({"id": "opponent:edge", "x": 8.0, "y": 9.5}, true)
    var outside := enemy.duplicate(true)
    outside.merge({"id": "opponent:outside", "x": 8.0, "y": 4.49}, true)
    var ally := enemy.duplicate(true)
    ally.merge({"id": "player:ally", "side": "player", "x": 7.0, "y": 7.0}, true)
    sim._units.append_array([edge, outside, ally])
    hit(sim, ball, 112)
    advance(sim, 9.9)
    check(bursts(sim).is_empty(), "first burst waits a full ten seconds")
    advance(sim, 10)
    check(bursts(sim).size() == 1 and ball["alive"] and ball["absorbed_damage"] == 0, "periodic burst keeps the Slime alive and clears the stored amount")
    check(enemy["hp"] == 970 and edge["hp"] == 970, "burst deals the full stored amount, without applying defense a second time, through the medium-radius boundary")
    check(enemy["x"] == 11 and edge["y"] == 11.5, "enemies are pushed radially outward")
    check(outside["hp"] == 1000 and outside["y"] == 4.49 and ally["hp"] == 1000 and ally["x"] == 7, "allies and enemies outside the radius are unaffected")
    check(bursts(sim)[0]["radius"] == sim._radius_medium, "medium radius comes from balance data")
    hit(sim, ball, 62)
    advance(sim, 19.9)
    check(bursts(sim).size() == 1, "repeat burst does not trigger early")
    enemy["x"] = 9.0
    advance(sim, 20)
    check(bursts(sim).size() == 2 and enemy["hp"] == 955, "next burst contains only newly absorbed damage")
    advance(sim, 30)
    check(bursts(sim).size() == 2 and ball["next_burst_at"] == 40, "empty cycles reset the clock without free damage or pushback")
    # Physical constraints still apply to pushback.
    enemy["x"] = 22.5
    ball["x"] = 21.5
    hit(sim, ball, 112)
    advance(sim, 40)
    check(enemy["x"] <= 23 and enemy["hp"] == 925, "pushback respects the field edge while still dealing damage")
    sim = setup()
    ball = sim._units[0]
    enemy = sim._units[1]
    var blocker := enemy.duplicate(true)
    blocker.merge({"id": "player:blocker", "side": "player", "x": 11.0}, true)
    sim._units.append(blocker)
    hit(sim, ball, 112)
    advance(sim, 10)
    check(enemy["x"] == 9 and enemy["hp"] == 970 and blocker["hp"] == 1000, "blocked pushback preserves physical separation without cancelling damage or hitting allies")
    sim = setup()
    ball = sim._units[0]
    sim._units[1]["x"] = 20.0
    hit(sim, ball, 112)
    advance(sim, 10)
    check(bursts(sim).size() == 1 and ball["absorbed_damage"] == 0 and sim._units[1]["hp"] == 1000, "an out-of-range discharge still consumes charge")

func test_death_and_chains() -> void:
    var sim := setup()
    var ball: Dictionary = sim._units[0]
    var enemy: Dictionary = sim._units[1]
    ball["hp"] = 60.0
    sim._time = 10
    hit(sim, ball, 112)
    advance(sim, 10)
    check(not ball["alive"] and bursts(sim).size() == 1, "a lethal deadline hit produces exactly one death burst, never a normal burst first")
    check(bursts(sim)[0]["on_death"] and bursts(sim)[0]["amount"] == 60 and enemy["hp"] == 940, "the lethal hit is absorbed and the stored amount is doubled before round elimination")
    check(ball["absorbed_damage"] == 0, "death discharge consumes its charge")
    sim = setup()
    ball = sim._units[0]
    enemy = sim._units[1]
    ball["hp"] = 60.0
    # Kill an opposing explosion unit: its chained damage must also absorb.
    var imp := enemy.duplicate(true)
    imp.merge({"id": "opponent:exploder", "x": 8.0, "y": 8.0, "hp": 1.0, "defense": 0, "attack": 112,
        "ability": {"type": "explosion", "trigger": "on_death", "radius": "medium", "attack_pct": 100, "pushback": "small"}}, true)
    sim._units.append(imp)
    hit(sim, imp, 100)
    check(not ball["alive"] and bursts(sim).size() == 1 and bursts(sim)[0]["amount"] == 60, "chained death explosions pass through absorption and trigger a doubled response")
    sim = setup()
    ball = sim._units[0]
    enemy = sim._units[1]
    ball["hp"] = 60.0
    enemy["hp"] = 60.0
    sim._queue_raw_damage(str(ball["id"]), 112, "opponent", "", "simultaneous")
    sim._queue_raw_damage(str(enemy["id"]), 1000, "player", "", "simultaneous")
    sim._resolve_pending_effects()
    check(sim._elimination_result() == "draw" and bursts(sim).size() == 1, "simultaneous last-unit deaths settle all bursts before a draw")
    sim = setup()
    ball = sim._units[0]
    ball["hp"] = 0.0
    sim._pending_heal.append({"target_id": str(ball["id"]), "amount": 0})
    sim._resolve_pending_effects()
    check(bursts(sim).is_empty(), "death with no stored damage causes no damaging burst")

func test_revival_and_reset() -> void:
    var sim := setup()
    var ball: Dictionary = sim._units[0]
    ball.merge({"hp": 60.0, "revives_remaining": 1, "revive_health_pct": 50}, true)
    sim._death_spawn_attack_pct["player"] = 100
    sim._time = 4
    hit(sim, ball, 112)
    var alive := sim._alive_units("player")
    check(alive.size() == 1 and alive[0]["id"] != ball["id"], "Royal Jelly creates a fresh body after the death burst")
    var revived: Dictionary = alive[0]
    check(revived["absorbed_damage"] == 0 and revived["next_burst_at"] == 14, "revival clears charge and restarts the full timer")
    check(revived["attack"] == 150, "death-spawn attack bonus still applies to revived regular attacks")
    hit(sim, revived, 112)
    advance(sim, 10)
    check(bursts(sim).size() == 1, "revived body does not inherit the original deadline")
    sim._units[1]["x"] = float(revived["x"]) + 1
    sim._units[1]["y"] = float(revived["y"])
    advance(sim, 14)
    check(bursts(sim).size() == 2 and bursts(sim)[1]["amount"] == 30, "attack multipliers never multiply stored-damage bursts")
    var fresh := setup()
    check(fresh._units[0]["absorbed_damage"] == 0 and fresh._units[0]["next_burst_at"] == 10, "a fresh round cannot inherit charge or timers")

func test_full_simulation() -> void:
    var player := side("player", true)
    var enemy := side("opponent", false)
    player["cards"][0]["stats"]["health"] = 5000
    enemy["cards"][0]["stats"]["health"] = 5000
    var a := CombatSimulator.new().simulate(player, enemy, 814, db.get_game_balance())
    var b := CombatSimulator.new().simulate(player, enemy, 814, db.get_game_balance())
    check(a == b, "full fixed-step battle output is deterministic")
    check(a["events"].any(func(event): return event.get("kind") == "absorb_burst" and is_equal_approx(float(event["time"]), 10)), "the real simulation loop fires at ten seconds")
    check(a["events"].any(func(event): return event.get("type") == "attack" and event.get("unit_id") == "player:future_absorber:0"), "the generic ability retains regular melee attacks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
