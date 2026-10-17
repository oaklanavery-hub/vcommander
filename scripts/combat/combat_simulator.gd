class_name CombatSimulator
extends RefCounted

const BattleEventScript = preload("res://scripts/combat/battle_event.gd")

const PLAYER_SIDE := "player"
const OPPONENT_SIDE := "opponent"
const EPSILON := 0.0001

var _rng := RandomNumberGenerator.new()
var _balance: Dictionary = {}
var _units: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _frames: Array[Dictionary] = []
var _projectiles: Array[Dictionary] = []
var _area_effects: Array[Dictionary] = []
var _pending_damage: Array[Dictionary] = []
var _pending_heal: Array[Dictionary] = []

var _time := 0.0
var _step := 0.1
var _round_limit := 120.0
var _frame_interval := 0.2
var _next_frame_time := 0.0
var _field_width := 24.0
var _field_height := 14.0
var _field_margin := 1.0
var _collision_radius := 0.42
var _move_units_per_second_at_100 := 2.5
var _projectile_units_per_second := 12.0
var _minimum_damage := 1
var _attack_speed_cap := 200
var _movement_speed_cap := 200
var _radius_small := 1.5
var _radius_medium := 2.5
var _radius_large := 3.5
var _push_small := 1.0
var _push_moderate := 2.0
var _push_large := 3.0


func simulate(
    player_side: Dictionary,
    opponent_side: Dictionary,
    battle_seed: int,
    balance: Dictionary = {}
) -> Dictionary:
    _reset(battle_seed, balance)

    _spawn_side(player_side, false)
    _spawn_side(opponent_side, true)
    _resolve_pre_battle_skills(player_side, opponent_side)
    _capture_frame(true)

    var immediate_result: String = _elimination_result()
    if not immediate_result.is_empty():
        return _finish_result(immediate_result, "pre_battle_elimination")

    while _time + EPSILON < _round_limit:
        _time = minf(_round_limit, _time + _step)
        _tick_status_effects()
        _tick_area_effects()
        _tick_auras()
        _tick_units()
        _tick_projectiles()
        _resolve_pending_effects()
        _capture_frame(false)

        var elimination: String = _elimination_result()
        if not elimination.is_empty():
            var reason := "simultaneous_elimination" if elimination == "draw" else "elimination"
            return _finish_result(elimination, reason)

    return _finish_result("draw", "timer")


func _reset(battle_seed: int, balance: Dictionary) -> void:
    _rng.seed = battle_seed
    _balance = balance.duplicate(true)
    _units.clear()
    _events.clear()
    _frames.clear()
    _projectiles.clear()
    _area_effects.clear()
    _pending_damage.clear()
    _pending_heal.clear()
    _time = 0.0
    _next_frame_time = 0.0

    var simulation: Dictionary = balance.get("simulation", {})
    var match_rules: Dictionary = balance.get("match", {})
    var stat_rules: Dictionary = balance.get("stats", {})
    var battlefield: Dictionary = balance.get("battlefield", {})
    var radii: Dictionary = simulation.get("radii", {})
    var pushback: Dictionary = simulation.get("pushback", {})

    _step = maxf(0.02, float(simulation.get("step_seconds", 0.1)))
    _frame_interval = maxf(_step, float(simulation.get("frame_interval_seconds", 0.2)))
    _round_limit = maxf(_step, float(match_rules.get("round_time_seconds", 120)))
    _field_width = maxf(8.0, float(battlefield.get("width", 24.0)))
    _field_height = maxf(6.0, float(battlefield.get("height", 14.0)))
    _field_margin = maxf(0.5, float(battlefield.get("edge_margin", 1.0)))
    _collision_radius = maxf(0.2, float(simulation.get("collision_radius", 0.42)))
    _move_units_per_second_at_100 = maxf(
        0.1,
        float(simulation.get("movement_units_per_second_at_100", 2.5))
    )
    _projectile_units_per_second = maxf(
        1.0,
        float(simulation.get("projectile_units_per_second", 12.0))
    )
    _minimum_damage = maxi(1, int(stat_rules.get("minimum_damage", 1)))
    _attack_speed_cap = maxi(1, int(stat_rules.get("attack_speed_cap", 200)))
    _movement_speed_cap = maxi(1, int(stat_rules.get("movement_speed_cap", 200)))
    _radius_small = maxf(0.1, float(radii.get("small", 1.5)))
    _radius_medium = maxf(_radius_small, float(radii.get("medium", 2.5)))
    _radius_large = maxf(_radius_medium, float(radii.get("large", 3.5)))
    _push_small = maxf(0.1, float(pushback.get("small", 1.0)))
    _push_moderate = maxf(_push_small, float(pushback.get("moderate", 2.0)))
    _push_large = maxf(_push_moderate, float(pushback.get("large", 3.0)))


func _spawn_side(side_config: Dictionary, on_right: bool) -> void:
    var side_id := str(side_config.get("id", OPPONENT_SIDE if on_right else PLAYER_SIDE))
    var cards: Array = side_config.get("cards", [])
    var counts: Dictionary = side_config.get("unit_counts", {})

    var tanks: Array[Dictionary] = []
    var melee: Array[Dictionary] = []
    var backline: Array[Dictionary] = []

    for raw_card in cards:
        if typeof(raw_card) != TYPE_DICTIONARY:
            continue
        var card: Dictionary = raw_card
        var card_id := str(card.get("id", ""))
        var count := maxi(0, int(counts.get(card_id, 0)))
        for unit_index in range(count):
            var spec: Dictionary = {
                "card": card,
                "unit_index": unit_index,
                "side_config": side_config,
                "side_id": side_id,
                "on_right": on_right
            }
            var role := str(card.get("role", "melee"))
            if role == "tank":
                tanks.append(spec)
            elif role == "melee":
                melee.append(spec)
            else:
                backline.append(spec)

    var tank_x := _field_width * (0.62 if on_right else 0.38)
    var melee_x := _field_width * (0.72 if on_right else 0.28)
    var back_x := _field_width * (0.84 if on_right else 0.16)

    _spawn_group(tanks, tank_x)
    _spawn_group(melee, melee_x)
    _spawn_group(backline, back_x)


func _spawn_group(specs: Array[Dictionary], x_position: float) -> void:
    if specs.is_empty():
        return
    var usable_height := maxf(1.0, _field_height - _field_margin * 2.0)
    var spacing := usable_height / float(specs.size() + 1)
    for index in range(specs.size()):
        var y_position := _field_margin + spacing * float(index + 1)
        _spawn_unit(specs[index], Vector2(x_position, y_position))


func _spawn_unit(spec: Dictionary, position: Vector2) -> void:
    var card: Dictionary = spec.get("card", {})
    var side_config: Dictionary = spec.get("side_config", {})
    var side_id := str(spec.get("side_id", PLAYER_SIDE))
    var unit_index := int(spec.get("unit_index", 0))
    var card_id := str(card.get("id", "card"))
    var stats: Dictionary = card.get("stats", {})
    var ability_definition: Dictionary = card.get("ability", {})
    var role := str(card.get("role", "melee"))

    var max_hp := _modified_stat(int(stats.get("health", 1)), "health", side_config)
    var attack := _modified_stat(int(stats.get("attack", 1)), "attack", side_config)
    var defense := _modified_stat(int(stats.get("defense", 0)), "defense", side_config)
    var attack_speed := _modified_stat(
        int(stats.get("attack_speed", 100)),
        "attack_speed",
        side_config
    )
    var movement_speed := _modified_stat(
        int(stats.get("movement_speed", 100)),
        "movement_speed",
        side_config
    )
    attack_speed = mini(_attack_speed_cap, maxi(1, attack_speed))
    movement_speed = mini(_movement_speed_cap, maxi(1, movement_speed))

    var unit_id := "%s:%s:%d" % [side_id, card_id, unit_index]
    var unit: Dictionary = {
        "id": unit_id,
        "card_id": card_id,
        "element": str(card.get("element", "earth")),
        "display_name": str(card.get("display_name", card_id)),
        "side": side_id,
        "role": role,
        "x": position.x,
        "y": position.y,
        "hp": float(max_hp),
        "max_hp": max_hp,
        "attack": attack,
        "defense": defense,
        "attack_speed": attack_speed,
        "movement_speed": movement_speed,
        "range": maxf(0.5, float(stats.get("range", 1))),
        "ability": ability_definition.duplicate(true),
        "alive": true,
        "stationary": false,
        "target_id": "",
        "attack_timer": 0.0,
        "ability_timer": maxf(
            0.0,
            float(ability_definition.get("tick_seconds", 0.0))
        ),
        "ability_cooldown": 0.0,
        "attack_count": 0,
        "blocked_steps": 0,
        "dots": []
    }
    _units.append(unit)
    _events.append(BattleEventScript.make("spawn", _time, {
        "side": side_id,
        "unit_id": unit_id,
        "name": unit["display_name"],
        "role": role,
        "x": position.x,
        "y": position.y
    }))


func _modified_stat(base_value: int, stat_name: String, side_config: Dictionary) -> int:
    var value := float(base_value)

    var set_bonus: Dictionary = side_config.get("set_bonus", {})
    if str(set_bonus.get("stat", "")) == stat_name:
        value *= 1.0 + float(set_bonus.get("percentage", 0)) / 100.0

    var buffs: Array = side_config.get("buffs", [])
    for raw_buff_state in buffs:
        if typeof(raw_buff_state) != TYPE_DICTIONARY:
            continue
        var buff_state: Dictionary = raw_buff_state
        var definition: Dictionary = buff_state.get("definition", {})
        if str(definition.get("stat", "")) != stat_name:
            continue
        var stacks := maxi(0, int(buff_state.get("stacks", 0)))
        var multiplier := 1.0 + float(definition.get("percentage", 0)) / 100.0
        for _stack in range(stacks):
            value *= multiplier

    return int(round(value))


func _resolve_pre_battle_skills(player_side: Dictionary, opponent_side: Dictionary) -> void:
    _spawn_summon_skill_if_active(player_side)
    _spawn_summon_skill_if_active(opponent_side)

    _emit_skill_event_if_active(player_side)
    _emit_skill_event_if_active(opponent_side)

    _apply_round_debuff_if_active(player_side, str(opponent_side.get("id", OPPONENT_SIDE)))
    _apply_round_debuff_if_active(opponent_side, str(player_side.get("id", PLAYER_SIDE)))

    _queue_damage_skill_if_active(player_side, str(opponent_side.get("id", OPPONENT_SIDE)))
    _queue_damage_skill_if_active(opponent_side, str(player_side.get("id", PLAYER_SIDE)))

    _resolve_pending_effects()


func _skill_if_active(side_config: Dictionary) -> Dictionary:
    if not bool(side_config.get("commander_skill_active", false)):
        return {}
    var commander: Dictionary = side_config.get("commander", {})
    return commander.get("active_skill", {})


func _emit_skill_event_if_active(side_config: Dictionary) -> void:
    var skill := _skill_if_active(side_config)
    if skill.is_empty():
        return
    _events.append(BattleEventScript.make("commander_skill", _time, {
        "side": str(side_config.get("id", PLAYER_SIDE)),
        "skill_id": str(skill.get("id", "")),
        "name": str(skill.get("display_name", "Commander Skill"))
    }))


func _spawn_summon_skill_if_active(side_config: Dictionary) -> void:
    var skill := _skill_if_active(side_config)
    if str(skill.get("type", "")) != "summon_stationary_units":
        return

    var side_id := str(side_config.get("id", PLAYER_SIDE))
    var on_right := side_id == OPPONENT_SIDE
    var count := maxi(0, int(skill.get("plant_count", 0)))
    var plant: Dictionary = skill.get("plant", {})
    var base_attack_interval := maxf(0.1, float(plant.get("attack_interval", 1.5)))
    var base_attack_speed := int(round(100.0 / base_attack_interval))
    var max_hp := _modified_stat(int(plant.get("health", 1)), "health", side_config)
    var defense := _modified_stat(int(plant.get("defense", 0)), "defense", side_config)
    var attack_speed := _modified_stat(base_attack_speed, "attack_speed", side_config)
    attack_speed = mini(_attack_speed_cap, maxi(1, attack_speed))
    for index in range(count):
        var position := _random_skill_spawn_position(on_right)
        var unit_id := "%s:commander_plant:%d" % [side_id, index]
        var unit: Dictionary = {
            "id": unit_id,
            "card_id": "commander_plant",
            "display_name": "Commander Plant",
            "side": side_id,
            "role": "range",
            "x": position.x,
            "y": position.y,
            "hp": float(max_hp),
            "max_hp": max_hp,
            "attack": 0,
            "defense": defense,
            "attack_speed": attack_speed,
            "movement_speed": 1,
            "range": maxf(0.5, float(plant.get("range", 5))),
            "ability": {
                "id": "commander_plant_seed",
                "display_name": "Seed Shot",
                "type": "max_hp_projectile",
                "target_max_hp_pct": float(plant.get("seed_target_max_hp_pct", 8))
            },
            "alive": true,
            "stationary": true,
            "target_id": "",
            "attack_timer": 0.0,
            "ability_timer": 0.0,
            "ability_cooldown": 0.0,
            "attack_count": 0,
            "blocked_steps": 0,
            "dots": []
        }
        _units.append(unit)
        _events.append(BattleEventScript.make("spawn", _time, {
            "side": side_id,
            "unit_id": unit_id,
            "name": "Commander Plant",
            "role": "range",
            "x": position.x,
            "y": position.y,
            "source": "commander_skill"
        }))


func _random_skill_spawn_position(side_on_right: bool) -> Vector2:
    var min_x := _field_width * (0.52 if side_on_right else 0.62)
    var max_x := _field_width * (0.90 if side_on_right else 0.98)
    if side_on_right:
        min_x = _field_width * 0.02
        max_x = _field_width * 0.38

    for _attempt in range(30):
        var candidate := Vector2(
            _rng.randf_range(min_x, max_x),
            _rng.randf_range(_field_margin, _field_height - _field_margin)
        )
        if not _position_collides(candidate, ""):
            return candidate
    return Vector2((min_x + max_x) * 0.5, _field_height * 0.5)


func _apply_round_debuff_if_active(source_side: Dictionary, target_side_id: String) -> void:
    var skill := _skill_if_active(source_side)
    if str(skill.get("type", "")) != "round_debuff":
        return

    var attack_pct := float(skill.get("enemy_attack_speed_pct", 0))
    var move_pct := float(skill.get("enemy_movement_speed_pct", 0))
    for unit in _units:
        if not bool(unit.get("alive", false)) or str(unit.get("side", "")) != target_side_id:
            continue
        var attack_speed := int(unit.get("attack_speed", 1))
        var move_speed := int(unit.get("movement_speed", 1))
        unit["attack_speed"] = maxi(1, int(round(float(attack_speed) * (1.0 + attack_pct / 100.0))))
        if not bool(unit.get("stationary", false)):
            unit["movement_speed"] = maxi(
                1,
                int(round(float(move_speed) * (1.0 + move_pct / 100.0)))
            )


func _queue_damage_skill_if_active(source_side: Dictionary, target_side_id: String) -> void:
    var skill := _skill_if_active(source_side)
    if str(skill.get("type", "")) != "targeted_aoe_max_hp":
        return

    var target_ids := _alive_unit_ids(target_side_id)
    if target_ids.is_empty():
        return
    _shuffle_strings(target_ids)

    var meteor_count := maxi(0, int(skill.get("meteors", 0)))
    var direct_pct := float(skill.get("direct_max_hp_pct", 20))
    var aoe_pct := float(skill.get("aoe_max_hp_pct", 10))
    var radius := _radius_from_value(str(skill.get("aoe_radius", "medium")))
    var source_side_id := str(source_side.get("id", PLAYER_SIDE))

    for meteor_index in range(meteor_count):
        var direct_id := target_ids[meteor_index % target_ids.size()]
        var direct_target := _unit_by_id(direct_id)
        if direct_target.is_empty():
            continue
        var impact_position := _unit_position(direct_target)
        _events.append(BattleEventScript.make("ability", _time, {
            "side": source_side_id,
            "ability": str(skill.get("display_name", "Meteor")),
            "target_id": direct_id,
            "kind": "meteor"
        }))
        _queue_raw_damage(
            direct_id,
            float(direct_target.get("max_hp", 1)) * direct_pct / 100.0,
            source_side_id,
            "",
            "commander_skill"
        )
        for splash_target in _alive_units(target_side_id):
            var splash_id := str(splash_target.get("id", ""))
            if splash_id == direct_id:
                continue
            if impact_position.distance_to(_unit_position(splash_target)) <= radius + EPSILON:
                _queue_raw_damage(
                    splash_id,
                    float(splash_target.get("max_hp", 1)) * aoe_pct / 100.0,
                    source_side_id,
                    "",
                    "commander_skill_aoe"
                )


func _tick_status_effects() -> void:
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue
        var dots: Array = unit.get("dots", [])
        var kept: Array = []
        for raw_dot in dots:
            if typeof(raw_dot) != TYPE_DICTIONARY:
                continue
            var dot: Dictionary = raw_dot
            var remaining := float(dot.get("remaining", 0.0)) - _step
            var tick_timer := float(dot.get("tick_timer", 1.0)) - _step
            while tick_timer <= EPSILON and remaining > -EPSILON:
                var source_attack := float(dot.get("source_attack", 0))
                var pct := float(dot.get("attack_pct", 0))
                _queue_raw_damage(
                    str(unit.get("id", "")),
                    source_attack * pct / 100.0,
                    str(dot.get("source_side", "")),
                    str(dot.get("source_unit_id", "")),
                    "damage_over_time"
                )
                tick_timer += maxf(0.1, float(dot.get("tick_interval", 1.0)))
            dot["remaining"] = remaining
            dot["tick_timer"] = tick_timer
            if remaining > EPSILON:
                kept.append(dot)
        unit["dots"] = kept


func _tick_area_effects() -> void:
    var kept: Array[Dictionary] = []
    for effect in _area_effects:
        var remaining := float(effect.get("remaining", 0.0)) - _step
        var tick_timer := float(effect.get("tick_timer", 0.0)) - _step
        while tick_timer <= EPSILON and remaining > -EPSILON:
            var side_id := str(effect.get("side", ""))
            var center := Vector2(float(effect.get("x", 0.0)), float(effect.get("y", 0.0)))
            var radius := float(effect.get("radius", _radius_medium))
            var heal_pct := float(effect.get("heal_max_hp_pct", 0))
            for ally in _alive_units(side_id):
                if center.distance_to(_unit_position(ally)) <= radius + EPSILON:
                    var amount := float(ally.get("max_hp", 1)) * heal_pct / 100.0
                    _pending_heal.append({
                        "target_id": str(ally.get("id", "")),
                        "amount": amount,
                        "source_unit_id": str(effect.get("source_unit_id", "")),
                        "source": "area_heal"
                    })
            tick_timer += maxf(0.1, float(effect.get("tick_seconds", 2.0)))
        effect["remaining"] = remaining
        effect["tick_timer"] = tick_timer
        if remaining > EPSILON:
            kept.append(effect)
    _area_effects = kept


func _tick_auras() -> void:
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue
        var ability: Dictionary = unit.get("ability", {})
        var ability_type := str(ability.get("type", ""))
        if ability_type != "aura_damage" and ability_type != "aura_heal":
            continue

        var timer := float(unit.get("ability_timer", 0.0)) - _step
        if timer > EPSILON:
            unit["ability_timer"] = timer
            continue

        var tick_seconds := maxf(0.1, float(ability.get("tick_seconds", 1.0)))
        unit["ability_timer"] = timer + tick_seconds
        var radius := _radius_from_value(str(ability.get("radius", "small")))
        var center := _unit_position(unit)
        var side_id := str(unit.get("side", ""))

        if ability_type == "aura_damage":
            var enemy_side := _other_side(side_id)
            var attack_pct := float(ability.get("attack_pct", 0))
            for target in _alive_units(enemy_side):
                if center.distance_to(_unit_position(target)) <= radius + EPSILON:
                    _queue_raw_damage(
                        str(target.get("id", "")),
                        float(unit.get("attack", 0)) * attack_pct / 100.0,
                        side_id,
                        str(unit.get("id", "")),
                        "aura_damage"
                    )
            _events.append(BattleEventScript.make("ability", _time, {
                "side": side_id,
                "unit_id": str(unit.get("id", "")),
                "ability": str(ability.get("display_name", "Aura"))
            }))
        else:
            var heal_pct := float(ability.get("heal_ally_max_hp_pct", 0))
            for ally in _alive_units(side_id):
                if center.distance_to(_unit_position(ally)) <= radius + EPSILON:
                    _pending_heal.append({
                        "target_id": str(ally.get("id", "")),
                        "amount": float(ally.get("max_hp", 1)) * heal_pct / 100.0,
                        "source_unit_id": str(unit.get("id", "")),
                        "source": "aura_heal"
                    })


func _tick_units() -> void:
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue

        unit["attack_timer"] = maxf(-_step, float(unit.get("attack_timer", 0.0)) - _step)
        unit["ability_cooldown"] = maxf(
            0.0,
            float(unit.get("ability_cooldown", 0.0)) - _step
        )

        var target := _locked_or_new_target(unit)
        if target.is_empty():
            continue

        var ability: Dictionary = unit.get("ability", {})
        var ability_type := str(ability.get("type", ""))
        if ability_type == "pull_then_melee":
            _tick_pull_unit(unit, target, ability)
            continue

        if str(unit.get("role", "")) == "healer":
            if _try_cast_heal(unit, ability):
                continue

        var attack_range := float(unit.get("range", 1.0))
        var distance := _unit_position(unit).distance_to(_unit_position(target))
        if distance <= attack_range + EPSILON:
            if float(unit.get("attack_timer", 0.0)) <= EPSILON:
                _perform_attack(unit, target)
            elif _is_ranged(unit) and distance < attack_range * 0.55:
                _move_away_from(unit, target)
        else:
            _move_toward(unit, target)


func _tick_pull_unit(unit: Dictionary, target: Dictionary, ability: Dictionary) -> void:
    var distance := _unit_position(unit).distance_to(_unit_position(target))
    var pull_range := maxf(1.0, float(ability.get("pull_range", 5.0)))
    if (
        distance <= pull_range + EPSILON
        and distance > 1.0 + EPSILON
        and float(unit.get("ability_cooldown", 0.0)) <= EPSILON
    ):
        var direction := (_unit_position(unit) - _unit_position(target)).normalized()
        var desired := _unit_position(unit) - direction * 0.9
        _displace_unit(target, desired)
        unit["ability_cooldown"] = maxf(0.1, float(ability.get("cooldown_seconds", 5.0)))
        _events.append(BattleEventScript.make("ability", _time, {
            "side": str(unit.get("side", "")),
            "unit_id": str(unit.get("id", "")),
            "target_id": str(target.get("id", "")),
            "ability": str(ability.get("display_name", "Pull")),
            "kind": "pull"
        }))
        distance = _unit_position(unit).distance_to(_unit_position(target))

    if distance <= 1.0 + EPSILON:
        if float(unit.get("attack_timer", 0.0)) <= EPSILON:
            _perform_attack(unit, target)
    else:
        _move_toward(unit, target)


func _try_cast_heal(unit: Dictionary, ability: Dictionary) -> bool:
    if str(ability.get("type", "")) != "area_heal":
        return false
    if float(unit.get("attack_timer", 0.0)) > EPSILON:
        return false

    var target := _nearest_injured_ally(unit, float(unit.get("range", 5.0)))
    if target.is_empty():
        return false

    var interval := _attack_interval(unit)
    unit["attack_timer"] = interval
    var radius := _radius_from_value(str(ability.get("radius", "medium")))
    var effect: Dictionary = {
        "side": str(unit.get("side", "")),
        "source_unit_id": str(unit.get("id", "")),
        "x": float(target.get("x", 0.0)),
        "y": float(target.get("y", 0.0)),
        "radius": radius,
        "remaining": maxf(0.1, float(ability.get("duration_seconds", 4.0))),
        "tick_seconds": maxf(0.1, float(ability.get("tick_seconds", 2.0))),
        "tick_timer": maxf(0.1, float(ability.get("tick_seconds", 2.0))),
        "heal_max_hp_pct": float(ability.get("heal_target_max_hp_pct", 5.0))
    }
    _area_effects.append(effect)
    _events.append(BattleEventScript.make("ability", _time, {
        "side": str(unit.get("side", "")),
        "unit_id": str(unit.get("id", "")),
        "target_id": str(target.get("id", "")),
        "ability": str(ability.get("display_name", "Heal")),
        "kind": "area_heal"
    }))
    return true


func _perform_attack(attacker: Dictionary, target: Dictionary) -> void:
    var side_id := str(attacker.get("side", ""))
    var attacker_id := str(attacker.get("id", ""))
    var target_id := str(target.get("id", ""))
    var ability: Dictionary = attacker.get("ability", {})
    var ability_type := str(ability.get("type", ""))
    var interval := _attack_interval(attacker)
    attacker["attack_timer"] = interval
    attacker["attack_count"] = int(attacker.get("attack_count", 0)) + 1

    var raw_damage := float(attacker.get("attack", 0))
    if ability_type == "empowered_attack":
        var every_n := maxi(1, int(ability.get("every_n_attacks", 3)))
        if int(attacker.get("attack_count", 0)) % every_n == 0:
            raw_damage *= float(ability.get("attack_pct", 100)) / 100.0
            _events.append(BattleEventScript.make("ability", _time, {
                "side": side_id,
                "unit_id": attacker_id,
                "target_id": target_id,
                "ability": str(ability.get("display_name", "Empowered Attack"))
            }))

    _events.append(BattleEventScript.make("attack", _time, {
        "side": side_id,
        "unit_id": attacker_id,
        "target_id": target_id,
        "kind": "ranged" if _is_ranged(attacker) else "melee"
    }))

    if _is_ranged(attacker):
        var distance := _unit_position(attacker).distance_to(_unit_position(target))
        var travel_time := distance / _projectile_units_per_second
        _projectiles.append({
            "resolve_at": _time + maxf(_step, travel_time),
            "source_id": attacker_id,
            "source_side": side_id,
            "target_id": target_id,
            "raw_damage": raw_damage,
            "ability": ability.duplicate(true)
        })
    else:
        _queue_raw_damage(
            target_id,
            raw_damage,
            side_id,
            attacker_id,
            "normal_attack"
        )


func _tick_projectiles() -> void:
    var kept: Array[Dictionary] = []
    for projectile in _projectiles:
        if float(projectile.get("resolve_at", _time)) > _time + EPSILON:
            kept.append(projectile)
            continue

        var target_id := str(projectile.get("target_id", ""))
        var target := _unit_by_id(target_id)
        if target.is_empty() or not bool(target.get("alive", false)):
            _events.append(BattleEventScript.make("projectile_fizzle", _time, {
                "source_unit_id": str(projectile.get("source_id", "")),
                "target_id": target_id
            }))
            continue

        var source_id := str(projectile.get("source_id", ""))
        var source_side := str(projectile.get("source_side", ""))
        var raw_damage := float(projectile.get("raw_damage", 0))
        var ability: Dictionary = projectile.get("ability", {})
        var ability_type := str(ability.get("type", ""))

        if ability_type == "max_hp_projectile":
            raw_damage = (
                float(target.get("max_hp", 1))
                * float(ability.get("target_max_hp_pct", 8))
                / 100.0
            )

        _queue_raw_damage(target_id, raw_damage, source_side, source_id, "projectile")
        var impact_position := _unit_position(target)

        if ability_type == "ranged_aoe":
            var radius := _radius_from_value(str(ability.get("splash_radius", "small")))
            var splash_pct := float(ability.get("splash_attack_pct", 0))
            for other in _alive_units(str(target.get("side", ""))):
                var other_id := str(other.get("id", ""))
                if other_id == target_id:
                    continue
                if impact_position.distance_to(_unit_position(other)) <= radius + EPSILON:
                    _queue_raw_damage(
                        other_id,
                        raw_damage * splash_pct / 100.0,
                        source_side,
                        source_id,
                        "splash"
                    )
        elif ability_type == "ranged_aoe_dot":
            var radius := _radius_from_value(str(ability.get("radius", "large")))
            for other in _alive_units(str(target.get("side", ""))):
                if impact_position.distance_to(_unit_position(other)) <= radius + EPSILON:
                    _apply_burn(
                        other,
                        ability,
                        source_id,
                        source_side,
                        raw_damage
                    )
        elif ability_type == "ranged_pushback":
            var source := _unit_by_id(source_id)
            if not source.is_empty():
                _push_from_source(target, source, _push_from_value(str(ability.get("pushback", "small"))))

    _projectiles = kept


func _apply_burn(
    target: Dictionary,
    ability: Dictionary,
    source_unit_id: String,
    source_side: String,
    source_attack: float
) -> void:
    var seconds := float(ability.get("burn_seconds", 0))
    var pct := float(ability.get("burn_attack_pct_per_second", 0))
    if seconds <= 0.0 or pct <= 0.0:
        return

    var dots: Array = target.get("dots", [])
    var refreshes := bool(ability.get("refreshes_duration", false))
    var status_key := str(ability.get("id", "burn"))
    if not refreshes:
        status_key = "%s:%s" % [status_key, source_unit_id]

    if refreshes:
        for raw_dot in dots:
            if typeof(raw_dot) != TYPE_DICTIONARY:
                continue
            var existing: Dictionary = raw_dot
            if str(existing.get("status_key", "")) == status_key:
                existing["remaining"] = seconds
                existing["source_attack"] = source_attack
                existing["attack_pct"] = pct
                target["dots"] = dots
                return

    dots.append({
        "status_key": status_key,
        "source_unit_id": source_unit_id,
        "source_side": source_side,
        "source_attack": source_attack,
        "attack_pct": pct,
        "remaining": seconds,
        "tick_interval": 1.0,
        "tick_timer": 1.0
    })
    target["dots"] = dots


func _resolve_pending_effects() -> void:
    if _pending_damage.is_empty() and _pending_heal.is_empty():
        return

    var damage_events := _pending_damage.duplicate(true)
    var heal_events := _pending_heal.duplicate(true)
    _pending_damage.clear()
    _pending_heal.clear()

    for damage_info in damage_events:
        var target_id := str(damage_info.get("target_id", ""))
        var target := _unit_by_id(target_id)
        if target.is_empty() or not bool(target.get("alive", false)):
            continue
        var amount := int(damage_info.get("amount", _minimum_damage))
        target["hp"] = float(target.get("hp", 0.0)) - float(amount)
        _events.append(BattleEventScript.make("damage", _time, {
            "target_id": target_id,
            "amount": amount,
            "source_side": str(damage_info.get("source_side", "")),
            "source_unit_id": str(damage_info.get("source_unit_id", "")),
            "source": str(damage_info.get("source", "damage"))
        }))

    for heal_info in heal_events:
        var target_id := str(heal_info.get("target_id", ""))
        var target := _unit_by_id(target_id)
        if target.is_empty() or not bool(target.get("alive", false)):
            continue
        var before := float(target.get("hp", 0.0))
        var maximum := float(target.get("max_hp", 1))
        var amount := maxf(0.0, float(heal_info.get("amount", 0.0)))
        target["hp"] = minf(maximum, before + amount)
        var actual_heal := maxi(0, int(round(float(target.get("hp", before)) - before)))
        if actual_heal > 0:
            _events.append(BattleEventScript.make("heal", _time, {
                "target_id": target_id,
                "amount": actual_heal,
                "source_unit_id": str(heal_info.get("source_unit_id", "")),
                "source": str(heal_info.get("source", "heal"))
            }))

    var newly_dead := _mark_newly_dead()
    while not newly_dead.is_empty():
        var chained_damage: Array[Dictionary] = []
        for dead_unit in newly_dead:
            var ability: Dictionary = dead_unit.get("ability", {})
            if str(ability.get("trigger", "")) == "on_death" and str(ability.get("type", "")) == "explosion":
                _queue_death_explosion(dead_unit, ability, chained_damage)

        if chained_damage.is_empty():
            break

        for damage_info in chained_damage:
            var target_id := str(damage_info.get("target_id", ""))
            var target := _unit_by_id(target_id)
            if target.is_empty() or not bool(target.get("alive", false)):
                continue
            var amount := int(damage_info.get("amount", _minimum_damage))
            target["hp"] = float(target.get("hp", 0.0)) - float(amount)
            _events.append(BattleEventScript.make("damage", _time, {
                "target_id": target_id,
                "amount": amount,
                "source_side": str(damage_info.get("source_side", "")),
                "source_unit_id": str(damage_info.get("source_unit_id", "")),
                "source": "death_explosion"
            }))
        newly_dead = _mark_newly_dead()


func _mark_newly_dead() -> Array[Dictionary]:
    var dead: Array[Dictionary] = []
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue
        if float(unit.get("hp", 0.0)) > 0.0:
            continue
        unit["alive"] = false
        unit["hp"] = 0.0
        dead.append(unit)
        _events.append(BattleEventScript.make("defeat", _time, {
            "side": str(unit.get("side", "")),
            "unit_id": str(unit.get("id", "")),
            "name": str(unit.get("display_name", "Unit"))
        }))
    return dead


func _queue_death_explosion(
    source: Dictionary,
    ability: Dictionary,
    damage_output: Array[Dictionary]
) -> void:
    var radius := _radius_from_value(str(ability.get("radius", "medium")))
    var center := _unit_position(source)
    var source_side := str(source.get("side", ""))
    var source_id := str(source.get("id", ""))
    var raw := float(source.get("attack", 0)) * float(ability.get("attack_pct", 100)) / 100.0
    var push_distance := _push_from_value(str(ability.get("pushback", "moderate")))

    _events.append(BattleEventScript.make("ability", _time, {
        "side": source_side,
        "unit_id": source_id,
        "ability": str(ability.get("display_name", "Explosion")),
        "kind": "on_death"
    }))

    for target in _alive_units(_other_side(source_side)):
        if center.distance_to(_unit_position(target)) > radius + EPSILON:
            continue
        damage_output.append({
            "target_id": str(target.get("id", "")),
            "amount": _damage_after_defense(raw, target),
            "source_side": source_side,
            "source_unit_id": source_id
        })
        _push_from_position(target, center, push_distance)
        _apply_burn(target, ability, source_id, source_side, float(source.get("attack", 0)))


func _queue_raw_damage(
    target_id: String,
    raw_damage: float,
    source_side: String,
    source_unit_id: String,
    source: String
) -> void:
    var target := _unit_by_id(target_id)
    if target.is_empty() or not bool(target.get("alive", false)):
        return
    _pending_damage.append({
        "target_id": target_id,
        "amount": _damage_after_defense(raw_damage, target),
        "source_side": source_side,
        "source_unit_id": source_unit_id,
        "source": source
    })


func _damage_after_defense(raw_damage: float, target: Dictionary) -> int:
    var rounded_raw := int(round(raw_damage))
    var defense := int(target.get("defense", 0))
    return maxi(_minimum_damage, rounded_raw - defense)


func _locked_or_new_target(unit: Dictionary) -> Dictionary:
    var target_id := str(unit.get("target_id", ""))
    if not target_id.is_empty():
        var current := _unit_by_id(target_id)
        if not current.is_empty() and bool(current.get("alive", false)):
            return current

    var selected := _select_target(unit)
    unit["target_id"] = str(selected.get("id", "")) if not selected.is_empty() else ""
    return selected


func _select_target(unit: Dictionary) -> Dictionary:
    var side_id := str(unit.get("side", ""))
    var enemies := _alive_units(_other_side(side_id))
    if enemies.is_empty():
        return {}

    if str(unit.get("role", "")) == "tank":
        var tanks := _filter_roles(enemies, ["tank"])
        if not tanks.is_empty():
            return _nearest_unit(unit, tanks)
        var frontline := _filter_roles(enemies, ["melee"])
        if not frontline.is_empty():
            return _nearest_unit(unit, frontline)

    return _nearest_unit(unit, enemies)


func _filter_roles(units: Array[Dictionary], roles: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for unit in units:
        if roles.has(str(unit.get("role", ""))):
            result.append(unit)
    return result


func _nearest_unit(source: Dictionary, candidates: Array[Dictionary]) -> Dictionary:
    var best: Dictionary = {}
    var best_distance := INF
    var source_position := _unit_position(source)
    for candidate in candidates:
        var distance := source_position.distance_squared_to(_unit_position(candidate))
        if distance + EPSILON < best_distance:
            best_distance = distance
            best = candidate
        elif absf(distance - best_distance) <= EPSILON:
            if str(candidate.get("id", "")) < str(best.get("id", "~")):
                best = candidate
    return best


func _nearest_injured_ally(unit: Dictionary, max_range: float) -> Dictionary:
    var best: Dictionary = {}
    var best_distance := INF
    var origin := _unit_position(unit)
    for ally in _alive_units(str(unit.get("side", ""))):
        if float(ally.get("hp", 0.0)) >= float(ally.get("max_hp", 1)) - EPSILON:
            continue
        var distance := origin.distance_to(_unit_position(ally))
        if distance > max_range + EPSILON:
            continue
        if distance + EPSILON < best_distance:
            best_distance = distance
            best = ally
        elif absf(distance - best_distance) <= EPSILON:
            if str(ally.get("id", "")) < str(best.get("id", "~")):
                best = ally
    return best


func _move_toward(unit: Dictionary, target: Dictionary) -> void:
    if bool(unit.get("stationary", false)):
        return
    var direction := (_unit_position(target) - _unit_position(unit)).normalized()
    _attempt_move(unit, direction)


func _move_away_from(unit: Dictionary, target: Dictionary) -> void:
    if bool(unit.get("stationary", false)):
        return
    var direction := (_unit_position(unit) - _unit_position(target)).normalized()
    _attempt_move(unit, direction)


func _attempt_move(unit: Dictionary, direction: Vector2) -> void:
    if direction.length_squared() <= EPSILON:
        return

    var rating := int(unit.get("movement_speed", 1))
    var distance := _move_units_per_second_at_100 * float(rating) / 100.0 * _step
    var origin := _unit_position(unit)
    var angles := [0.0, PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0]
    var unit_id := str(unit.get("id", ""))
    if abs(unit_id.hash()) % 2 == 1:
        angles = [0.0, -PI / 4.0, PI / 4.0, -PI / 2.0, PI / 2.0]

    for raw_angle in angles:
        var angle := float(raw_angle)
        var candidate := origin + direction.rotated(angle).normalized() * distance
        candidate = _clamp_position(candidate)
        if not _position_collides(candidate, unit_id):
            unit["x"] = candidate.x
            unit["y"] = candidate.y
            unit["blocked_steps"] = 0
            return

    unit["blocked_steps"] = int(unit.get("blocked_steps", 0)) + 1
    if int(unit.get("blocked_steps", 0)) >= 6:
        unit["target_id"] = ""
        unit["blocked_steps"] = 0


func _displace_unit(unit: Dictionary, desired: Vector2) -> void:
    var clamped := _clamp_position(desired)
    if not _position_collides(clamped, str(unit.get("id", ""))):
        unit["x"] = clamped.x
        unit["y"] = clamped.y


func _push_from_source(target: Dictionary, source: Dictionary, distance: float) -> void:
    _push_from_position(target, _unit_position(source), distance)


func _push_from_position(target: Dictionary, source_position: Vector2, distance: float) -> void:
    var direction := (_unit_position(target) - source_position).normalized()
    if direction.length_squared() <= EPSILON:
        direction = Vector2.RIGHT if str(target.get("side", "")) == OPPONENT_SIDE else Vector2.LEFT
    _displace_unit(target, _unit_position(target) + direction * distance)


func _position_collides(position: Vector2, ignored_unit_id: String) -> bool:
    var minimum_distance := _collision_radius * 2.0
    for other in _units:
        if not bool(other.get("alive", false)):
            continue
        if str(other.get("id", "")) == ignored_unit_id:
            continue
        if position.distance_to(_unit_position(other)) < minimum_distance - EPSILON:
            return true
    return false


func _clamp_position(position: Vector2) -> Vector2:
    return Vector2(
        clampf(position.x, _field_margin, _field_width - _field_margin),
        clampf(position.y, _field_margin, _field_height - _field_margin)
    )


func _attack_interval(unit: Dictionary) -> float:
    var effective_speed := _effective_attack_speed(unit)
    return 100.0 / float(maxi(1, effective_speed))


func _effective_attack_speed(unit: Dictionary) -> int:
    var speed := int(unit.get("attack_speed", 1))
    var side_id := str(unit.get("side", ""))
    var origin := _unit_position(unit)
    var has_freezing_aura := false

    for enemy in _alive_units(_other_side(side_id)):
        var ability: Dictionary = enemy.get("ability", {})
        if str(ability.get("type", "")) != "aura_debuff":
            continue
        var radius := _radius_from_value(str(ability.get("radius", "small")))
        if origin.distance_to(_unit_position(enemy)) <= radius + EPSILON:
            has_freezing_aura = true
            break

    if has_freezing_aura:
        var pct := 0.0
        for enemy in _alive_units(_other_side(side_id)):
            var ability: Dictionary = enemy.get("ability", {})
            if str(ability.get("type", "")) != "aura_debuff":
                continue
            var radius := _radius_from_value(str(ability.get("radius", "small")))
            if origin.distance_to(_unit_position(enemy)) <= radius + EPSILON:
                pct = float(ability.get("enemy_attack_speed_pct", -15))
                break
        speed = maxi(1, int(round(float(speed) * (1.0 + pct / 100.0))))
    return speed


func _is_ranged(unit: Dictionary) -> bool:
    var ability: Dictionary = unit.get("ability", {})
    if str(ability.get("type", "")) == "pull_then_melee":
        return false
    var role := str(unit.get("role", ""))
    return role == "range" or role == "healer"


func _radius_from_value(value: String) -> float:
    if value == "large":
        return _radius_large
    if value == "medium":
        return _radius_medium
    return _radius_small


func _push_from_value(value: String) -> float:
    if value == "large":
        return _push_large
    if value == "moderate":
        return _push_moderate
    return _push_small


func _alive_units(side_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for unit in _units:
        if bool(unit.get("alive", false)) and str(unit.get("side", "")) == side_id:
            result.append(unit)
    return result


func _alive_unit_ids(side_id: String) -> Array[String]:
    var result: Array[String] = []
    for unit in _alive_units(side_id):
        result.append(str(unit.get("id", "")))
    return result


func _unit_by_id(unit_id: String) -> Dictionary:
    for unit in _units:
        if str(unit.get("id", "")) == unit_id:
            return unit
    return {}


func _unit_position(unit: Dictionary) -> Vector2:
    return Vector2(float(unit.get("x", 0.0)), float(unit.get("y", 0.0)))


func _other_side(side_id: String) -> String:
    return OPPONENT_SIDE if side_id == PLAYER_SIDE else PLAYER_SIDE


func _shuffle_strings(values: Array[String]) -> void:
    for index in range(values.size() - 1, 0, -1):
        var swap_index := _rng.randi_range(0, index)
        var temp := values[index]
        values[index] = values[swap_index]
        values[swap_index] = temp


func _elimination_result() -> String:
    var player_alive := not _alive_units(PLAYER_SIDE).is_empty()
    var opponent_alive := not _alive_units(OPPONENT_SIDE).is_empty()
    if player_alive and opponent_alive:
        return ""
    if not player_alive and not opponent_alive:
        return "draw"
    return PLAYER_SIDE if player_alive else OPPONENT_SIDE


func _capture_frame(force: bool) -> void:
    if not force and _time + EPSILON < _next_frame_time:
        return

    var frame_units: Array[Dictionary] = []
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue
        frame_units.append({
            "id": str(unit.get("id", "")),
            "name": str(unit.get("display_name", "Unit")),
            "element": str(unit.get("element", "earth")),
            "card_id": str(unit.get("card_id", "")),
            "side": str(unit.get("side", "")),
            "role": str(unit.get("role", "")),
            "x": float(unit.get("x", 0.0)),
            "y": float(unit.get("y", 0.0)),
            "hp": maxi(0, int(round(float(unit.get("hp", 0.0))))),
            "max_hp": int(unit.get("max_hp", 1))
        })
    _frames.append({
        "time": snappedf(_time, 0.001),
        "units": frame_units
    })
    _next_frame_time = _time + _frame_interval


func _finish_result(winner: String, reason: String) -> Dictionary:
    _capture_frame(true)
    _events.append(BattleEventScript.make("battle_end", _time, {
        "winner": winner,
        "reason": reason
    }))
    return {
        "winner": winner,
        "reason": reason,
        "duration": snappedf(_time, 0.001),
        "events": _events.duplicate(true),
        "frames": _frames.duplicate(true),
        "seed": int(_rng.seed),
        "battlefield": {
            "width": _field_width,
            "height": _field_height
        }
    }
