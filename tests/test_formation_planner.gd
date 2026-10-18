extends SceneTree

var failed := false
var db: Node
var field := {"width": 24.0, "height": 14.0, "margin": 1.0, "collision_radius": 0.42}

func _init() -> void:
    call_deferred("run")

func side(element: String, capped: bool = true) -> Dictionary:
    var cards: Array = db.get_cards_by_set("set_" + element + "_01")
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = int(card["unit_cap"] if capped else card["summon_amount"])
    return {"id": "player", "cards": cards, "unit_counts": counts}

func run() -> void:
    db = root.get_node("ContentDatabase")
    var original := side("water")
    var water := FormationPlanner.plan(original, {}, field)
    var initial := original.duplicate(true)
    check(water["placements"].size() == 19, "capped Water army keeps all nineteen recruited bodies")
    var healers: Array = water["placements"].filter(func(u): return u["role"] == "healer")
    var tanks: Array = water["placements"].filter(func(u): return u["role"] == "tank")
    var damage: Array = water["placements"].filter(func(u): return u["role"] == "range")
    var depths := {}
    for unit in damage:
        depths[float(unit["x"])] = true
    check(depths.size() >= 2, "crowded ranged units use multiple ranks instead of one type-sorted column")
    for healer in healers:
        check(absf(float(healer["y"]) - 7) <= 3, "healers occupy the central protected pocket")
        check(tanks.any(func(tank): return float(tank["x"]) > float(healer["x"]) and absf(float(tank["y"]) - float(healer["y"])) <= 1.7), "healers have a forward Tank screen")
        check(tanks.any(func(tank): return point(tank).distance_to(point(healer)) <= 5), "healing starts within reach of frontline allies")
    var serpents: Array = water["placements"].filter(func(u): return u["card_id"] == "card_water_02")
    var wizards: Array = water["placements"].filter(func(u): return u["card_id"] == "card_water_04")
    check(serpents.all(func(u): return float(u["x"]) > float(wizards[0]["x"])), "shorter-range attackers stand ahead of the long-range casters")
    check(absf(average_y(serpents) - 7) < 0.01 and absf(average_y(wizards) - 7) < 0.01, "each damage group is balanced across the field instead of assigned to the top or bottom")
    check_safe(water, field)
    var shuffled := original.duplicate(true)
    shuffled["cards"].reverse()
    check(FormationPlanner.plan(shuffled, {}, field) == water, "loadout card order does not affect tactical placement")
    check(original == initial, "planning never mutates cards or persistent army state")
    var mirrored := original.duplicate(true)
    mirrored["id"] = "opponent"
    var right := FormationPlanner.plan(mirrored, {}, field)
    for i in range(water["placements"].size()):
        var a: Dictionary = water["placements"][i]
        var b: Dictionary = right["placements"][i]
        check(is_equal_approx(float(a["x"]) + float(b["x"]), 24) and is_equal_approx(float(a["y"]), float(b["y"])), "both teams receive mirrored placement with equal tactical rules")
    for element in ["fire", "water", "earth", "slime"]:
        for capped in [false, true]:
            var own := side(element, capped)
            var plan := FormationPlanner.plan(own, side("fire"), field)
            check_safe(plan, field)
            check_role_depth(plan)
    test_threat_response(original, water)
    test_mixed_and_edge_cases()
    test_simulator(original)
    if not failed:
        print("Formation planner tests passed: strategic Water ranks/support/range, mirrored teams, card-order invariance, area-threat response, legal spacing, mixed/edge armies and deterministic integration.")
    quit(1 if failed else 0)

func test_threat_response(own: Dictionary, baseline: Dictionary) -> void:
    var area_enemy := side("fire")
    var spread := FormationPlanner.plan(own, area_enemy, field)
    check(float(spread["spacing"]) > float(baseline["spacing"]) and spread["strategy"] == "spread", "enemy area damage produces a more dispersed formation")
    var unrecruited := area_enemy.duplicate(true)
    unrecruited["unit_counts"] = {}
    check(FormationPlanner.plan(own, unrecruited, field) == baseline, "equipped but unrecruited threats do not influence formation")
    var blast := {"id": "future_area", "role": "range", "stats": {"health": 300, "range": 6}, "ability": {"type": "ranged_aoe_dot"}}
    var future_enemy := {"cards": [blast], "unit_counts": {"future_area": 8}}
    check(FormationPlanner.plan(own, future_enemy, field)["strategy"] == "spread", "future cards work through generic ability behavior rather than known IDs")
    check_safe(spread, field)

func test_mixed_and_edge_cases() -> void:
    var cards := [db.get_card("card_fire_02"), db.get_card("card_water_01"), db.get_card("card_slime_03"), db.get_card("card_earth_03")]
    var counts := {}
    for card in cards:
        counts[str(card["id"])] = int(card["unit_cap"])
    var mixed := {"cards": cards, "unit_counts": counts}
    var plan := FormationPlanner.plan(mixed, side("slime"), field)
    check(plan["placements"].size() == 27, "crowded mixed army retains every recruited unit")
    check_safe(plan, field)
    check_role_depth(plan)
    var small_field := {"width": 12.0, "height": 6.0, "margin": 0.5, "collision_radius": 0.35}
    check_safe(FormationPlanner.plan(side("water"), side("fire"), small_field), small_field)
    var ranged := side("water")
    ranged["unit_counts"]["card_water_01"] = 0
    var ranged_plan := FormationPlanner.plan(ranged, {}, field)
    check_safe(ranged_plan, field)
    var support: Array = ranged_plan["placements"].filter(func(u): return u["role"] == "healer")
    var shooters: Array = ranged_plan["placements"].filter(func(u): return u["role"] == "range")
    check(support.all(func(h): return shooters.any(func(s): return float(s["x"]) > float(h["x"]))), "ranged-only armies still protect support behind a damage screen")
    var single := side("water")
    single["unit_counts"] = {"card_water_03": 1}
    var lone := FormationPlanner.plan(single, {}, field)
    check(lone["placements"].size() == 1 and lone["placements"][0]["y"] == 7, "single support unit remains centered and legal")
    check(FormationPlanner.plan({}, {}, field)["placements"].is_empty(), "empty armies are valid for pre-battle elimination")

func test_simulator(own: Dictionary) -> void:
    var enemy := own.duplicate(true)
    enemy["id"] = "opponent"
    var a := CombatSimulator.new().simulate(own, enemy, 1018, {"match": {"round_time_seconds": 1}})
    var b := CombatSimulator.new().simulate(own, enemy, 1018, {"match": {"round_time_seconds": 1}})
    check(a == b, "same battle inputs and seed preserve deterministic simulation")
    var reordered := own.duplicate(true)
    reordered["cards"].reverse()
    check(a == CombatSimulator.new().simulate(reordered, enemy, 1018, {"match": {"round_time_seconds": 1}}), "reordering equipped cards cannot alter layout or simultaneous combat ordering")
    check(a["formations"]["player"]["placements"].size() == 19 and a["formations"]["opponent"]["placements"].size() == 19, "both armies actually use their planned positions before combat")
    var positions := {}
    for event in a["events"]:
        if event.get("type") == "spawn":
            positions[str(event["unit_id"])] = Vector2(float(event["x"]), float(event["y"]))
            check(positions[str(event["unit_id"])].is_equal_approx(point(event["unit"])), "spawn event and embedded snapshot agree on the planned position")
    for unit in a["frames"][0]["units"]:
        check(positions[str(unit["id"])].is_equal_approx(point(unit)), "first replay frame uses the authoritative planned position")

func check_role_depth(plan: Dictionary) -> void:
    for unit in plan["placements"]:
        for other in plan["placements"]:
            if unit["role"] == "tank" and other["role"] != "tank":
                check(float(unit["x"]) > float(other["x"]), "Tanks screen every non-Tank rank")
            if unit["role"] == "melee" and other["role"] in ["range", "healer"]:
                check(float(unit["x"]) > float(other["x"]), "melee ranks stay ahead of the backline")

func check_safe(plan: Dictionary, layout: Dictionary) -> void:
    var units: Array = plan["placements"]
    var ids := {}
    for i in range(units.size()):
        var u: Dictionary = units[i]
        var id := str(u["card_id"]) + ":" + str(u["unit_index"])
        check(not ids.has(id), "no recruited body is duplicated")
        ids[id] = true
        check(float(u["x"]) >= float(layout["margin"]) - 0.001 and float(u["x"]) < float(layout["width"]) * 0.5, "player formation stays within its starting half")
        check(float(u["y"]) >= float(layout["margin"]) and float(u["y"]) <= float(layout["height"]) - float(layout["margin"]), "formation respects vertical bounds")
        for j in range(i):
            check(point(u).distance_to(point(units[j])) >= float(layout["collision_radius"]) * 2 + 0.001, "starting units never physically overlap")

func point(unit: Dictionary) -> Vector2:
    return Vector2(float(unit.get("x", 0)), float(unit.get("y", 0)))

func average_y(units: Array) -> float:
    var total := 0.0
    for unit in units:
        total += float(unit["y"])
    return total / maxf(1, units.size())

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
