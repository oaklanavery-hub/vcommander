extends SceneTree

const CombatSimulatorScript = preload("res://scripts/combat/combat_simulator.gd")

var _failed := false

func _card(
    card_id: String,
    role: String,
    health: int,
    attack: int,
    defense: int,
    attack_speed: int,
    movement_speed: int,
    attack_range: float,
    ability: Dictionary
) -> Dictionary:
    return {
        "id": card_id,
        "display_name": card_id,
        "role": role,
        "stats": {
            "health": health,
            "attack": attack,
            "defense": defense,
            "attack_speed": attack_speed,
            "movement_speed": movement_speed,
            "range": attack_range
        },
        "ability": ability
    }

func _side(side_id: String, card: Dictionary, skill: Dictionary = {}, skill_active: bool = false) -> Dictionary:
    return {
        "id": side_id,
        "cards": [card],
        "unit_counts": {str(card.get("id", "")): 1},
        "buffs": [],
        "set_bonus": {},
        "commander": {
            "active_skill": skill
        },
        "commander_skill_active": skill_active
    }

func _balance(round_seconds: float = 4.0) -> Dictionary:
    return {
        "match": {
            "round_time_seconds": round_seconds
        },
        "stats": {
            "minimum_damage": 1,
            "attack_speed_cap": 200,
            "movement_speed_cap": 200
        },
        "battlefield": {
            "width": 12.0,
            "height": 6.0,
            "edge_margin": 0.5
        },
        "simulation": {
            "step_seconds": 0.1,
            "frame_interval_seconds": 0.2,
            "collision_radius": 0.35,
            "movement_units_per_second_at_100": 3.0,
            "projectile_units_per_second": 12.0,
            "radii": {
                "small": 1.0,
                "medium": 2.0,
                "large": 3.0
            },
            "pushback": {
                "small": 0.5,
                "moderate": 1.0,
                "large": 1.5
            }
        }
    }

func _init() -> void:
    var player_card := _card(
        "player_sword",
        "melee",
        340,
        120,
        20,
        100,
        100,
        1.0,
        {"id": "basic", "type": "basic_melee"}
    )
    var opponent_card := _card(
        "opponent_sword",
        "melee",
        260,
        80,
        20,
        100,
        100,
        1.0,
        {"id": "basic", "type": "basic_melee"}
    )

    var simulator_a = CombatSimulatorScript.new()
    var result_a: Dictionary = simulator_a.simulate(
        _side("player", player_card),
        _side("opponent", opponent_card),
        4242,
        _balance()
    )
    var simulator_b = CombatSimulatorScript.new()
    var result_b: Dictionary = simulator_b.simulate(
        _side("player", player_card),
        _side("opponent", opponent_card),
        4242,
        _balance()
    )

    _assert(result_a.get("winner") == "player", "stronger deterministic melee unit should win")
    _assert(result_a.get("winner") == result_b.get("winner"), "same seed must reproduce winner")
    _assert(result_a.get("duration") == result_b.get("duration"), "same seed must reproduce duration")
    _assert(
        _event_fingerprint(result_a.get("events", [])) == _event_fingerprint(result_b.get("events", [])),
        "same seed must reproduce battle event sequence"
    )
    _assert(not result_a.get("frames", []).is_empty(), "combat should emit replay frames")
    _assert(_first_frame_is_left_vs_right(result_a), "player must spawn left of opponent")
    _assert(_has_damage_amount(result_a, 100), "normal damage must use ATK - DEF")

    var slow_player := _card(
        "slow_player",
        "melee",
        1000,
        10,
        100,
        50,
        1,
        1.0,
        {"id": "basic", "type": "basic_melee"}
    )
    var slow_opponent := _card(
        "slow_opponent",
        "melee",
        1000,
        10,
        100,
        50,
        1,
        1.0,
        {"id": "basic", "type": "basic_melee"}
    )
    var draw_simulator = CombatSimulatorScript.new()
    var draw_result: Dictionary = draw_simulator.simulate(
        _side("player", slow_player),
        _side("opponent", slow_opponent),
        99,
        _balance(0.2)
    )
    _assert(draw_result.get("winner") == "draw", "timer expiry with survivors must draw")
    _assert(draw_result.get("reason") == "timer", "timer draw reason must be reported")

    var buff_card := _card(
        "buff_probe",
        "melee",
        100,
        10,
        1,
        100,
        1,
        1.0,
        {"id": "basic", "type": "basic_melee"}
    )
    var buff_side := _side("player", buff_card)
    buff_side["set_bonus"] = {
        "stat": "health",
        "percentage": 10
    }
    buff_side["buffs"] = [{
        "definition": {
            "stat": "health",
            "percentage": 25
        },
        "stacks": 1
    }]
    var buff_simulator = CombatSimulatorScript.new()
    var buff_result: Dictionary = buff_simulator.simulate(
        buff_side,
        _side("opponent", slow_opponent),
        77,
        _balance(0.1)
    )
    _assert(
        _first_unit_max_hp(buff_result, "player") == 138,
        "set bonus and Buff must stack multiplicatively then round normally"
    )

    var meteor_skill := {
        "id": "meteor_test",
        "display_name": "Meteor Test",
        "type": "targeted_aoe_max_hp",
        "meteors": 6,
        "direct_max_hp_pct": 20,
        "aoe_max_hp_pct": 10,
        "aoe_radius": "medium"
    }
    var meteor_simulator = CombatSimulatorScript.new()
    var meteor_result: Dictionary = meteor_simulator.simulate(
        _side("player", player_card, meteor_skill, true),
        _side("opponent", opponent_card),
        123,
        _balance(0.5)
    )
    _assert(_has_event(meteor_result, "commander_skill"), "active Commander skill should emit event")
    _assert(
        _has_damage_source(meteor_result, "commander_skill"),
        "meteor should deal pre-battle Commander-skill damage"
    )

    if _failed:
        quit(1)
        return
    print("CombatSimulator tests passed.")
    quit(0)

func _event_fingerprint(events: Array) -> Array[String]:
    var result: Array[String] = []
    for raw_event in events:
        if typeof(raw_event) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = raw_event
        result.append("%s|%s|%s|%s|%s" % [
            str(event.get("time", "")),
            str(event.get("type", "")),
            str(event.get("unit_id", event.get("source_unit_id", ""))),
            str(event.get("target_id", "")),
            str(event.get("amount", ""))
        ])
    return result

func _first_frame_is_left_vs_right(result: Dictionary) -> bool:
    var frames: Array = result.get("frames", [])
    if frames.is_empty():
        return false
    var frame: Dictionary = frames[0]
    var player_x := 9999.0
    var opponent_x := -9999.0
    for raw_unit in frame.get("units", []):
        if typeof(raw_unit) != TYPE_DICTIONARY:
            continue
        var unit: Dictionary = raw_unit
        if str(unit.get("side", "")) == "player":
            player_x = minf(player_x, float(unit.get("x", 0.0)))
        else:
            opponent_x = maxf(opponent_x, float(unit.get("x", 0.0)))
    return player_x < opponent_x

func _first_unit_max_hp(result: Dictionary, side_id: String) -> int:
    var frames: Array = result.get("frames", [])
    if frames.is_empty():
        return 0
    var frame: Dictionary = frames[0]
    for raw_unit in frame.get("units", []):
        if typeof(raw_unit) != TYPE_DICTIONARY:
            continue
        var unit: Dictionary = raw_unit
        if str(unit.get("side", "")) == side_id:
            return int(unit.get("max_hp", 0))
    return 0

func _has_damage_amount(result: Dictionary, expected: int) -> bool:
    for raw_event in result.get("events", []):
        if typeof(raw_event) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = raw_event
        if str(event.get("type", "")) == "damage" and int(event.get("amount", 0)) == expected:
            return true
    return false

func _has_event(result: Dictionary, event_type: String) -> bool:
    for raw_event in result.get("events", []):
        if typeof(raw_event) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = raw_event
        if str(event.get("type", "")) == event_type:
            return true
    return false

func _has_damage_source(result: Dictionary, source: String) -> bool:
    for raw_event in result.get("events", []):
        if typeof(raw_event) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = raw_event
        if str(event.get("type", "")) == "damage" and str(event.get("source", "")) == source:
            return true
    return false

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("TEST FAILED: %s" % message)
