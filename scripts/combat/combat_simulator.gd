class_name CombatSimulator
extends RefCounted

const BattleEventScript = preload("res://scripts/combat/battle_event.gd")
const Terrain = preload("res://scripts/combat/combat_terrain.gd")
const FormationPlannerScript = preload("res://scripts/ai/formation_planner.gd")

const PLAYER_SIDE := "player"
const OPPONENT_SIDE := "opponent"
const EPSILON := 0.0001

var _rng := RandomNumberGenerator.new()
var _balance: Dictionary = {}
var _units: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _frames: Array[Dictionary] = []
var _projectiles: Array[Dictionary] = []
var _projectile_sequence := 0
var _area_effects: Array[Dictionary] = []
var _pending_damage: Array[Dictionary] = []
var _pending_heal: Array[Dictionary] = []
var _pre_battle: Dictionary = {}
var _death_spawn_attack_pct: Dictionary = {}
var _spawn_sequence := 0
var _formations: Dictionary = {}
var _obstacles: Array[Dictionary] = []
var _hazards: Array[Dictionary] = []
var _links: Array[Dictionary] = []
var _terrain_revision := 0

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

    _spawn_side(player_side, false, opponent_side)
    _spawn_side(opponent_side, true, player_side)
    var before_skills := _snapshot()
    var skill_event_start := _events.size()
    _resolve_pre_battle_skills(player_side, opponent_side)
    if _events.size() > skill_event_start:
        _pre_battle = {"before": before_skills, "after": _snapshot(), "events": _events.slice(skill_event_start).duplicate(true), "event_end": _events.size()}
    _capture_frame(true)

    var immediate_result: String = _elimination_result()
    if not immediate_result.is_empty():
        return _finish_result(immediate_result, "pre_battle_elimination")

    while _time + EPSILON < _round_limit:
        _time = minf(_round_limit, _time + _step)
        _tick_special_effects()
        _tick_status_effects()
        _tick_area_effects()
        _tick_auras()
        _tick_units()
        _tick_projectiles()
        _resolve_pending_effects()
        # Lethal hits own the stored charge, including hits on a burst deadline.
        _tick_absorbed_bursts()
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
    _projectile_sequence = 0
    _area_effects.clear()
    _pending_damage.clear()
    _pending_heal.clear()
    _pre_battle.clear()
    _death_spawn_attack_pct.clear()
    _spawn_sequence = 0
    _formations.clear()
    _obstacles.clear()
    _hazards.clear()
    _links.clear()
    _terrain_revision = 0
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


func _spawn_side(side_config: Dictionary, on_right: bool, enemy_config: Dictionary = {}) -> void:
    var side_id := str(side_config.get("id", OPPONENT_SIDE if on_right else PLAYER_SIDE))
    var bonus: Dictionary = side_config.get("set_bonus", {})
    if str(bonus.get("trigger", "")) == "on_death_spawn" and str(bonus.get("stat", "")) == "attack":
        _death_spawn_attack_pct[side_id] = float(bonus.get("percentage", 0))
    var config := side_config.duplicate()
    config["id"] = side_id
    var formation := FormationPlannerScript.plan(config, enemy_config, {
        "width": _field_width, "height": _field_height, "margin": _field_margin,
        "collision_radius": _collision_radius, "settings": _balance.get("formation", {})})
    _formations[side_id] = formation
    var cards_by_id := {}
    for card in side_config.get("cards", []):
        cards_by_id[str(card.get("id", ""))] = card
    for placement in formation.get("placements", []):
        _spawn_unit({"card": cards_by_id[str(placement["card_id"])], "unit_index": placement["unit_index"],
            "side_config": side_config, "side_id": side_id, "on_right": on_right},
            Vector2(float(placement["x"]), float(placement["y"])))


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
    attack_speed = minf(_attack_speed_cap, maxf(1, attack_speed))
    movement_speed = minf(_movement_speed_cap, maxf(1, movement_speed))

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
        "absorbed_damage": 0.0,
        "next_burst_at": _time + float(ability_definition.get("burst_seconds", 10)),
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
        "starting_army": true,
        "visual_scale": 1.0,
        "speed_debuffs": [],
        "dots": []
    }
    _units.append(unit)
    _events.append(BattleEventScript.make("spawn", _time, {
        "side": side_id,
        "unit_id": unit_id,
        "name": unit["display_name"],
        "role": role,
        "x": position.x,
        "y": position.y,
        "unit": _unit_snapshot(unit)
    }))


func _modified_stat(base_value: int, stat_name: String, side_config: Dictionary) -> float:
    if base_value == 0:
        return 0.0
    var value := float(base_value)

    var set_bonus: Dictionary = side_config.get("set_bonus", {})
    if str(set_bonus.get("stat", "")) == stat_name and str(set_bonus.get("trigger", "")).is_empty():
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
        # Numerical safety only: finite floating-point output even after thousands
        # of picks. This ceiling is far beyond any playable match.
        value = exp(minf(log(1.0e100), log(maxf(1.0e-20, value)) + float(stacks) * log(multiplier)))

    return round(value)


func _resolve_pre_battle_skills(player_side: Dictionary, opponent_side: Dictionary) -> void:
    _spawn_summon_skill_if_active(player_side)
    _spawn_summon_skill_if_active(opponent_side)

    _emit_skill_event_if_active(player_side)
    _emit_skill_event_if_active(opponent_side)

    _grant_revival_if_active(player_side)
    _grant_revival_if_active(opponent_side)

    _apply_round_debuff_if_active(player_side, str(opponent_side.get("id", OPPONENT_SIDE)))
    _apply_round_debuff_if_active(opponent_side, str(player_side.get("id", PLAYER_SIDE)))

    _queue_damage_skill_if_active(player_side, str(opponent_side.get("id", OPPONENT_SIDE)))
    _queue_damage_skill_if_active(opponent_side, str(player_side.get("id", PLAYER_SIDE)))

    _resolve_pending_effects()


func _grant_revival_if_active(side_config: Dictionary) -> void:
    var skill := _skill_if_active(side_config)
    if str(skill.get("type", "")) != "army_revival":
        return
    for unit in _alive_units(str(side_config.get("id", PLAYER_SIDE))):
        if not bool(unit.get("starting_army", false)):
            continue
        unit["revives_remaining"] = maxi(0, int(skill.get("revives_per_unit", 1)))
        unit["revive_health_pct"] = clampf(float(skill.get("revive_health_pct", 50)), 1, 100)


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
        "name": str(skill.get("display_name", "Commander Skill")),
        "skill_type": str(skill.get("type", "")),
        "element": str(side_config.get("commander", {}).get("element", "earth"))
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
    attack_speed = minf(_attack_speed_cap, maxf(1, attack_speed))
    for index in range(count):
        var position := _random_skill_spawn_position(on_right)
        var unit_id := "%s:commander_plant:%d" % [side_id, index]
        var unit: Dictionary = {
            "id": unit_id,
            "card_id": "commander_plant",
            "element": str(side_config.get("commander", {}).get("element", "earth")),
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
            "summoned": true,
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
            "source": "commander_skill",
            "summoned": true,
            "unit": _unit_snapshot(unit)
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
            "kind": "meteor",
            "index": meteor_index,
            "x": impact_position.x,
            "y": impact_position.y,
            "radius": radius
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
        var active_slows: Array[Dictionary] = []
        for slow in unit.get("speed_debuffs", []):
            slow["remaining"] = float(slow.get("remaining", 0)) - _step
            if float(slow["remaining"]) > EPSILON:
                active_slows.append(slow)
        unit["speed_debuffs"] = active_slows
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
            if str(effect.get("type", "")) == "damage_area":
                for enemy in _alive_units(_other_side(side_id)):
                    if center.distance_to(_unit_position(enemy)) <= radius + EPSILON:
                        _queue_raw_damage(str(enemy["id"]), float(effect.get("damage", 0)), side_id, str(effect.get("source_unit_id", "")), "damage_area")
            else:
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

        if not unit.get("transit", {}).is_empty():
            continue
        var ability_definition: Dictionary = unit.get("ability", {})
        if str(ability_definition.get("type", "")) == "backline_transit" and float(unit.get("ability_cooldown", 0)) <= EPSILON:
            if _begin_transit(unit, ability_definition):
                continue

        var target := _locked_or_new_target(unit)
        if target.is_empty():
            continue

        var ability: Dictionary = unit.get("ability", {})
        var ability_type := str(ability.get("type", ""))
        if ability_type == "damage_link" and float(unit.get("ability_cooldown", 0)) <= EPSILON:
            _cast_damage_link(unit, target, ability)
        if ability_type == "pull_then_melee":
            _tick_pull_unit(unit, target, ability)
            continue

        if str(unit.get("role", "")) == "healer":
            if _try_cast_heal(unit, ability):
                continue

        var attack_range := float(unit.get("range", 1.0))
        var distance := _unit_position(unit).distance_to(_unit_position(target))
        var melee_blocked := not _is_ranged(unit) and not Terrain.clear_line(_unit_position(unit), _unit_position(target), _obstacles, 0.05)
        if distance <= attack_range + EPSILON and not melee_blocked:
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
        var pull_from := _unit_position(target)
        var direction := (_unit_position(unit) - _unit_position(target)).normalized()
        var desired := _unit_position(unit) - direction * 0.9
        _displace_unit(target, desired)
        unit["ability_cooldown"] = maxf(0.1, float(ability.get("cooldown_seconds", 5.0)))
        _events.append(BattleEventScript.make("ability", _time, {
            "side": str(unit.get("side", "")),
            "unit_id": str(unit.get("id", "")),
            "target_id": str(target.get("id", "")),
            "ability": str(ability.get("display_name", "Pull")),
            "kind": "pull",
            "source_x": float(unit["x"]), "source_y": float(unit["y"]),
            "from_hp": float(target["hp"]),
            "from_x": pull_from.x, "from_y": pull_from.y,
            "to_x": float(target["x"]), "to_y": float(target["y"])
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
        "kind": "area_heal",
        "card_id": str(unit.get("card_id", "")),
        "x": float(unit.get("x", 0)), "y": float(unit.get("y", 0)),
        "target_x": float(target.get("x", 0)), "target_y": float(target.get("y", 0))
    }))
    return true


func _perform_attack(attacker: Dictionary, target: Dictionary) -> void:
    var side_id := str(attacker.get("side", ""))
    if not bool(attacker.get("alive", false)) or not bool(target.get("alive", false)) or not _are_enemies(side_id, str(target.get("side", ""))):
        return
    var attacker_id := str(attacker.get("id", ""))
    var target_id := str(target.get("id", ""))
    var ability: Dictionary = attacker.get("ability", {})
    var ability_type := str(ability.get("type", ""))
    var interval := _attack_interval(attacker)
    attacker["attack_timer"] = interval
    attacker["attack_count"] = int(attacker.get("attack_count", 0)) + 1

    var raw_damage := float(attacker.get("attack", 0))
    if ability.has("every_n_attacks"):
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
        "kind": "ranged" if _is_ranged(attacker) else "melee",
        "card_id": str(attacker.get("card_id", "")),
        "x": float(attacker.get("x", 0)), "y": float(attacker.get("y", 0)),
        "target_x": float(target.get("x", 0)), "target_y": float(target.get("y", 0))
    }))

    if _is_ranged(attacker):
        _projectile_sequence += 1
        _projectiles.append({
            "id": _projectile_sequence,
            "launched_at": _time,
            "start_x": float(attacker.get("x", 0.0)), "start_y": float(attacker.get("y", 0.0)),
            "x": float(attacker.get("x", 0.0)),
            "y": float(attacker.get("y", 0.0)),
            "element": str(attacker.get("element", "earth")),
            "card_id": str(attacker.get("card_id", "")),
            "source_id": attacker_id,
            "source_side": side_id,
            "target_id": target_id,
            "raw_damage": raw_damage,
            "ability": ability.duplicate(true)
        })
        _events.append(BattleEventScript.make("projectile_launch", _time, {
            "projectile": _projectiles.back().duplicate(true)
        }))
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
        if float(projectile.get("launched_at", -1.0)) >= _time - EPSILON:
            kept.append(projectile)
            continue

        var target_id := str(projectile.get("target_id", ""))
        var target := _unit_by_id(target_id)
        var source_side := str(projectile.get("source_side", ""))
        if target.is_empty() or not bool(target.get("alive", false)) or not _are_enemies(source_side, str(target.get("side", ""))):
            _events.append(BattleEventScript.make("projectile_fizzle", _time, {
                "projectile_id": int(projectile.get("id", 0)),
                "source_unit_id": str(projectile.get("source_id", "")),
                "target_id": target_id,
                "x": float(projectile.get("x", 0)), "y": float(projectile.get("y", 0))
            }))
            continue

        var start := Vector2(float(projectile.get("x", 0)), float(projectile.get("y", 0)))
        var destination := _unit_position(target)
        var end := start.move_toward(destination, _projectile_units_per_second * _step)
        var hit := _first_projectile_hit(start, end, _other_side(source_side))
        projectile["x"] = end.x
        projectile["y"] = end.y
        if hit.is_empty():
            kept.append(projectile)
            continue
        target = hit
        target_id = str(hit.get("id", ""))

        var source_id := str(projectile.get("source_id", ""))
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
        _events.append(BattleEventScript.make("projectile_impact", _time, {
            "projectile_id": int(projectile.get("id", 0)),
            "source_unit_id": source_id, "target_id": target_id,
            "card_id": str(projectile.get("card_id", "")),
            "element": str(projectile.get("element", "earth")),
            "x": impact_position.x, "y": impact_position.y
        }))

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
        elif ability_type == "ranged_aoe_slow":
            var radius := _radius_from_value(str(ability.get("radius", "small")))
            for other in _alive_units(_other_side(source_side)):
                if impact_position.distance_to(_unit_position(other)) <= radius + EPSILON:
                    _apply_speed_debuff(other, ability)
            _events.append(BattleEventScript.make("ability", _time, {
                "side": source_side, "unit_id": source_id, "card_id": str(projectile.get("card_id", "")),
                "kind": "slow_splash", "x": impact_position.x, "y": impact_position.y, "radius": radius
            }))
        elif ability_type == "ranged_pushback":
            var source := _unit_by_id(source_id)
            if not source.is_empty():
                _push_from_source(target, source, _push_from_value(str(ability.get("pushback", "small"))))

    _projectiles = kept


func _apply_speed_debuff(target: Dictionary, ability: Dictionary) -> void:
    var slow := {
        "key": str(ability.get("id", "slow")),
        "remaining": maxf(0, float(ability.get("slow_seconds", 0))),
        "attack_speed_pct": minf(0, float(ability.get("enemy_attack_speed_pct", 0))),
        "movement_speed_pct": minf(0, float(ability.get("enemy_movement_speed_pct", 0)))
    }
    var slows: Array = target.get("speed_debuffs", [])
    for existing in slows:
        if existing.get("key") == slow["key"]:
            existing.merge(slow, true)
            return
    slows.append(slow)
    target["speed_debuffs"] = slows


# Swept circles prevent fast projectiles tunneling through the first enemy.
func _first_projectile_hit(start: Vector2, end: Vector2, enemy_side: String) -> Dictionary:
    var segment := end - start
    var length_squared := segment.length_squared()
    var earliest := INF
    var result: Dictionary = {}
    for enemy in _alive_units(enemy_side):
        var offset := start - _unit_position(enemy)
        var c := offset.length_squared() - _collision_radius * _collision_radius
        var hit_time := INF
        if c <= EPSILON:
            hit_time = 0.0
        elif length_squared > EPSILON:
            var b := 2.0 * offset.dot(segment)
            var discriminant := b * b - 4.0 * length_squared * c
            if discriminant >= 0.0:
                hit_time = (-b - sqrt(discriminant)) / (2.0 * length_squared)
        if hit_time >= 0.0 and hit_time <= 1.0 and hit_time < earliest:
            earliest = hit_time
            result = enemy
    return result


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
        _apply_damage_event(damage_info)

    for heal_info in heal_events:
        var target_id := str(heal_info.get("target_id", ""))
        var target := _unit_by_id(target_id)
        if target.is_empty() or not bool(target.get("alive", false)):
            continue
        var before := float(target.get("hp", 0.0))
        var maximum := float(target.get("max_hp", 1))
        var amount := maxf(0.0, float(heal_info.get("amount", 0.0)))
        target["hp"] = minf(maximum, before + amount)
        var actual_heal := maxf(0, float(target.get("hp", before)) - before)
        if actual_heal > 0:
            _events.append(BattleEventScript.make("heal", _time, {
                "target_id": target_id,
                "amount": actual_heal,
                "effective_healing": maxf(0, maxf(0, float(target["hp"])) - maxf(0, before)),
                "hp_after": float(target["hp"]),
                "source_unit_id": str(heal_info.get("source_unit_id", "")),
                "source": str(heal_info.get("source", "heal"))
            }))

    var newly_dead := _mark_newly_dead()
    while not newly_dead.is_empty():
        var chained_damage: Array[Dictionary] = []
        for dead_unit in newly_dead:
            var ability: Dictionary = dead_unit.get("ability", {})
            if str(ability.get("type", "")) == "absorb_burst":
                _queue_absorbed_burst(dead_unit, chained_damage, true)
            if str(ability.get("trigger", "")) == "on_death":
                match str(ability.get("type", "")):
                    "explosion":
                        _queue_death_explosion(dead_unit, ability, chained_damage)
                    "death_split":
                        _spawn_death_children(dead_unit, ability)
                    "death_damage_area":
                        _queue_death_damage_area(dead_unit, ability, chained_damage)
            if int(dead_unit.get("revives_remaining", 0)) > 0:
                _revive_unit(dead_unit)

        if chained_damage.is_empty():
            break

        for damage_info in chained_damage:
            _apply_damage_event(damage_info, "death_explosion")
        newly_dead = _mark_newly_dead()


func _apply_damage_event(damage_info: Dictionary, fallback_source: String = "damage") -> void:
    var target_id := str(damage_info.get("target_id", ""))
    var target := _unit_by_id(target_id)
    if target.is_empty() or not bool(target.get("alive", false)) or not _are_enemies(str(damage_info.get("source_side", "")), str(target.get("side", ""))):
        return
    if _is_invulnerable(target):
        return
    var hp_before := float(target.get("hp", 0))
    var amount := maxf(0, float(damage_info.get("amount", _minimum_damage)))
    var absorbed := 0.0
    var ability: Dictionary = target.get("ability", {})
    if str(ability.get("type", "")) == "absorb_burst":
        absorbed = amount * clampf(float(ability.get("absorb_pct", 0)), 0, 100) / 100.0
        target["absorbed_damage"] = float(target.get("absorbed_damage", 0)) + absorbed
    amount -= absorbed
    target["hp"] = float(target.get("hp", 0)) - amount
    var event := BattleEventScript.make("damage", _time, {
        "target_id": target_id, "amount": amount, "hp_after": float(target["hp"]),
        "hp_loss": minf(amount, maxf(0, hp_before)),
        "source_side": str(damage_info.get("source_side", "")),
        "source_unit_id": str(damage_info.get("source_unit_id", "")),
        "source": str(damage_info.get("source", fallback_source))
    })
    if absorbed > 0:
        event["absorbed"] = absorbed
        event["absorbed_total"] = float(target["absorbed_damage"])
    _events.append(event)
    if not bool(damage_info.get("no_share", false)):
        _share_damage(target, minf(amount, maxf(0, hp_before)), damage_info)


func _tick_absorbed_bursts() -> void:
    for unit in _units:
        var ability: Dictionary = unit.get("ability", {})
        if not bool(unit.get("alive", false)) or str(ability.get("type", "")) != "absorb_burst":
            continue
        if _time + EPSILON < float(unit.get("next_burst_at", 10)):
            continue
        var interval := maxf(_step, float(ability.get("burst_seconds", 10)))
        unit["next_burst_at"] = float(unit.get("next_burst_at", _time)) + interval
        _queue_absorbed_burst(unit, _pending_damage)


func _queue_absorbed_burst(source: Dictionary, damage_output: Array[Dictionary], on_death: bool = false) -> void:
    var stored := float(source.get("absorbed_damage", 0))
    if stored <= 0:
        return
    source["absorbed_damage"] = 0.0
    var ability: Dictionary = source.get("ability", {})
    var amount := stored * (float(ability.get("death_multiplier", 2)) if on_death else 1.0)
    var radius := _radius_from_value(str(ability.get("radius", "medium")))
    var origin := _unit_position(source)
    var side_id := str(source["side"])
    _events.append(BattleEventScript.make("ability", _time, {
        "kind": "absorb_burst", "ability": str(ability.get("display_name", "Burst")),
        "unit_id": str(source["id"]), "card_id": str(source.get("card_id", "")), "side": side_id,
        "x": origin.x, "y": origin.y, "radius": radius, "stored_damage": stored,
        "amount": amount, "on_death": on_death, "next_burst_at": float(source.get("next_burst_at", 0))
    }))
    # Capture every target before displacement so iteration order cannot change membership.
    var targets: Array[Dictionary] = []
    for enemy in _alive_units(_other_side(side_id)):
        if origin.distance_to(_unit_position(enemy)) <= radius + EPSILON:
            targets.append(enemy)
    for enemy in targets:
        damage_output.append({
            "target_id": str(enemy["id"]), "amount": amount,
            "source_side": side_id, "source_unit_id": str(source["id"]), "source": "absorb_burst"
        })
        var before := _unit_position(enemy)
        _push_from_position(enemy, origin, _push_from_value(str(ability.get("pushback", "moderate"))))
        _events.append(BattleEventScript.make("pushback", _time, {
            "unit_id": str(source["id"]), "target_id": str(enemy["id"]),
            "from_x": before.x, "from_y": before.y, "to_x": float(enemy["x"]), "to_y": float(enemy["y"])
        }))


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
            "name": str(unit.get("display_name", "Unit")),
            "x": float(unit["x"]), "y": float(unit["y"]), "unit": _unit_snapshot(unit)
        }))
    return dead


func _spawn_death_children(source: Dictionary, ability: Dictionary) -> void:
    if bool(source.get("split_spent", false)):
        return
    source["split_spent"] = true
    for _index in range(maxi(0, int(ability.get("spawn_count", 2)))):
        var child := source.duplicate(true)
        child["display_name"] = "Small " + str(source.get("display_name", "Unit"))
        child["max_hp"] = maxf(1, round(float(source.get("max_hp", 1)) * float(ability.get("child_health_pct", 50)) / 100.0))
        child["hp"] = float(child["max_hp"])
        child["attack"] = maxf(1, round(float(source.get("attack", 1)) * float(ability.get("child_attack_pct", 50)) / 100.0))
        child["ability"] = {"type": "basic_melee"}
        child["visual_scale"] = float(ability.get("child_visual_scale", 0.68))
        child["revives_remaining"] = 0
        _add_death_spawn(child, source, "death_split")


func _revive_unit(source: Dictionary) -> void:
    var revived := source.duplicate(true)
    revived["revives_remaining"] = int(source.get("revives_remaining", 1)) - 1
    revived["hp"] = maxf(1, round(float(source.get("max_hp", 1)) * float(source.get("revive_health_pct", 50)) / 100.0))
    _add_death_spawn(revived, source, "revival")


func _add_death_spawn(unit: Dictionary, source: Dictionary, cause: String) -> void:
    _spawn_sequence += 1
    var side_id := str(source.get("side", ""))
    unit["id"] = "%s:%s:spawn%d" % [side_id, str(unit.get("card_id", "unit")), _spawn_sequence]
    unit["attack"] = maxf(1, round(float(unit.get("attack", 1)) * (1.0 + float(_death_spawn_attack_pct.get(side_id, 0)) / 100.0)))
    unit["alive"] = true
    unit["summoned"] = true
    unit["starting_army"] = false
    unit["target_id"] = ""
    unit["dots"] = []
    unit["speed_debuffs"] = []
    unit["transit"] = {}
    unit["route"] = []
    unit["ability_cooldown"] = 0.0
    unit["attack_timer"] = 0.0
    unit["ability_timer"] = float(unit.get("ability", {}).get("tick_seconds", 0))
    unit["ability_cooldown"] = 0.0
    unit["absorbed_damage"] = 0.0
    unit["next_burst_at"] = _time + float(unit.get("ability", {}).get("burst_seconds", 10))
    unit["attack_count"] = 0
    unit["blocked_steps"] = 0
    unit["spawned_at"] = _time
    var position := _death_spawn_position(_unit_position(source))
    unit["x"] = position.x
    unit["y"] = position.y
    _units.append(unit)
    _events.append(BattleEventScript.make("spawn", _time, {
        "side": side_id, "unit_id": unit["id"], "source_unit_id": str(source.get("id", "")),
        "source": cause, "summoned": true, "name": str(unit.get("display_name", "Unit")),
        "card_id": str(unit.get("card_id", "")), "role": str(unit.get("role", "melee")),
        "x": position.x, "y": position.y, "unit": _unit_snapshot(unit)
    }))


func _death_spawn_position(origin: Vector2) -> Vector2:
    var spacing := _collision_radius * 2.0 + 0.02
    for ring in range(0, int(ceil(maxf(_field_width, _field_height) / spacing)) + 1):
        for angle_index in range(16):
            var angle := TAU * float(angle_index) / 16.0
            var position := _clamp_position(origin + Vector2.from_angle(angle) * float(ring) * spacing)
            if not _position_collides(position, ""):
                return position
    return _clamp_position(origin)


func _queue_death_damage_area(source: Dictionary, ability: Dictionary, damage_output: Array[Dictionary]) -> void:
    var radius := _radius_from_value(str(ability.get("radius", "large")))
    var side_id := str(source.get("side", ""))
    var origin := _unit_position(source)
    var attack := float(source.get("attack", 0))
    for enemy in _alive_units(_other_side(side_id)):
        if origin.distance_to(_unit_position(enemy)) <= radius + EPSILON:
            damage_output.append({
                "target_id": str(enemy["id"]), "amount": _damage_after_defense(attack * float(ability.get("attack_pct", 100)) / 100.0, enemy),
                "source_side": side_id, "source_unit_id": str(source["id"])
            })
    var duration := maxf(_step, float(ability.get("duration_seconds", 10)))
    var interval := maxf(_step, float(ability.get("tick_seconds", 1)))
    _area_effects.append({
        "type": "damage_area", "side": side_id, "source_unit_id": str(source["id"]),
        "x": origin.x, "y": origin.y, "radius": radius, "remaining": duration,
        "duration": duration, "created_at": _time, "tick_timer": interval, "tick_seconds": interval,
        "damage": attack * float(ability.get("damage_attack_pct_per_tick", 35)) / 100.0
    })
    _events.append(BattleEventScript.make("ability", _time, {
        "side": side_id, "unit_id": str(source["id"]), "card_id": str(source.get("card_id", "")),
        "ability": str(ability.get("display_name", "Spill")), "kind": "death_area",
        "x": origin.x, "y": origin.y, "radius": radius, "duration": duration,
        "area": _area_effects.back().duplicate(true)
    }))


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
    if target.is_empty() or not bool(target.get("alive", false)) or not _are_enemies(source_side, str(target.get("side", ""))):
        return
    _pending_damage.append({
        "target_id": target_id,
        "amount": _damage_after_defense(raw_damage, target),
        "source_side": source_side,
        "source_unit_id": source_unit_id,
        "source": source
    })


func _damage_after_defense(raw_damage: float, target: Dictionary) -> float:
    return maxf(_minimum_damage, round(raw_damage) - float(target.get("defense", 0)))


func _locked_or_new_target(unit: Dictionary) -> Dictionary:
    var target_id := str(unit.get("target_id", ""))
    if not target_id.is_empty():
        var current := _unit_by_id(target_id)
        if not current.is_empty() and bool(current.get("alive", false)) and _are_enemies(str(unit.get("side", "")), str(current.get("side", ""))):
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
    var origin := _unit_position(unit)
    var goal := _unit_position(target)
    if not _obstacles.is_empty():
        var cached_goal: Vector2 = unit.get("route_goal", Vector2(INF, INF))
        var path: Array = unit.get("route", [])
        if int(unit.get("route_revision", -1)) != _terrain_revision or cached_goal.distance_to(goal) > 0.9 or path.is_empty():
            path = Terrain.route(origin, goal, _obstacles, Rect2(Vector2.ONE * _field_margin, Vector2(_field_width, _field_height) - Vector2.ONE * _field_margin * 2), _collision_radius + 0.06)
            unit["route_revision"] = _terrain_revision
            unit["route_goal"] = goal
        while path.size() > 1 and origin.distance_to(path[0]) < 0.25:
            path.pop_front()
        unit["route"] = path
        if path.is_empty():
            unit["target_id"] = ""
            return
        goal = path[0]
    _attempt_move(unit, (goal - origin).normalized())


func _move_away_from(unit: Dictionary, target: Dictionary) -> void:
    if bool(unit.get("stationary", false)):
        return
    var direction := (_unit_position(unit) - _unit_position(target)).normalized()
    _attempt_move(unit, direction)


func _attempt_move(unit: Dictionary, direction: Vector2) -> void:
    if direction.length_squared() <= EPSILON:
        return

    var rating := _speed_after_debuffs(unit, "movement_speed")
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
        if not _position_collides(candidate, unit_id) and Terrain.clear_line(origin, candidate, _obstacles, _collision_radius):
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
    if not _position_collides(clamped, str(unit.get("id", ""))) and Terrain.clear_line(_unit_position(unit), clamped, _obstacles, _collision_radius):
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
    if not Terrain.clear_line(position, position, _obstacles, _collision_radius):
        return true
    var minimum_distance := _collision_radius * 2.0
    for other in _units:
        if not bool(other.get("alive", false)) or not other.get("transit", {}).is_empty():
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
    var speed := _speed_after_debuffs(unit, "attack_speed")
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


func _speed_after_debuffs(unit: Dictionary, stat: String) -> int:
    var percentage := 0.0
    for slow in unit.get("speed_debuffs", []):
        if float(slow.get("remaining", 0)) > EPSILON:
            percentage = minf(percentage, float(slow.get(stat + "_pct", 0)))
    return maxi(1, int(round(float(unit.get(stat, 1)) * (1.0 + percentage / 100.0))))


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

func _are_enemies(source_side: String, target_side: String) -> bool:
    return source_side in [PLAYER_SIDE, OPPONENT_SIDE] and target_side == _other_side(source_side)


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
    _frames.append(_snapshot())
    _next_frame_time = _time + _frame_interval

func _snapshot() -> Dictionary:
    var frame_units: Array[Dictionary] = []
    for unit in _units:
        if not bool(unit.get("alive", false)):
            continue
        frame_units.append(_unit_snapshot(unit))
    return {
        "time": snappedf(_time, 0.001),
        "units": frame_units,
        "projectiles": _projectiles.duplicate(true),
        "areas": _area_effects.duplicate(true),
        "obstacles": _obstacles.duplicate(true), "hazards": _hazards.duplicate(true), "links": _links.duplicate(true)
    }


func _unit_snapshot(unit: Dictionary) -> Dictionary:
    var effective_attack_speed := _effective_attack_speed(unit)
    return {
            "id": str(unit.get("id", "")),
            "name": str(unit.get("display_name", "Unit")),
            "element": str(unit.get("element", "earth")),
            "card_id": str(unit.get("card_id", "")),
            "side": str(unit.get("side", "")),
            "role": str(unit.get("role", "")),
            "summoned": bool(unit.get("summoned", false)),
            "visual_scale": float(unit.get("visual_scale", 1)),
            "spawned_at": float(unit.get("spawned_at", 0)),
            "attack": float(unit.get("attack", 0)),
            "defense": float(unit.get("defense", 0)),
            "attack_speed": effective_attack_speed,
            "aura_slowed": effective_attack_speed < _speed_after_debuffs(unit, "attack_speed"),
            "movement_speed": 0 if bool(unit.get("stationary", false)) else _speed_after_debuffs(unit, "movement_speed"),
            "range": float(unit.get("range", 1)),
            "sample_time": _time,
            "ability_cooldown": maxf(0, float(unit.get("ability_cooldown", 0))),
            "attack_ready_at": _time + maxf(0, float(unit.get("attack_timer", 0))),
            "ability_name": str(unit.get("ability", {}).get("display_name", "Attack")),
            "absorbed_damage": float(unit.get("absorbed_damage", 0)),
            "next_burst_at": float(unit.get("next_burst_at", 0)),
            "burst_seconds": float(unit.get("ability", {}).get("burst_seconds", 10)),
            "slowed": not unit.get("speed_debuffs", []).is_empty(),
            "revival_ready": int(unit.get("revives_remaining", 0)) > 0,
            "x": float(unit.get("x", 0.0)),
            "y": float(unit.get("y", 0.0)),
            "hp": maxf(0, float(unit.get("hp", 0.0))),
            "max_hp": float(unit.get("max_hp", 1)),
            "burning": not unit.get("dots", []).is_empty(),
            "transit": unit.get("transit", {}).duplicate(true),
            "ability_type": str(unit.get("ability", {}).get("type", "")),
            "aura_radius": _radius_from_value(str(unit.get("ability", {}).get("radius", "small"))) if str(unit.get("ability", {}).get("type", "")).begins_with("aura_") else 0.0
    }


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
        "pre_battle": _pre_battle.duplicate(true),
        "formations": _formations.duplicate(true),
        "seed": int(_rng.seed),
        "battlefield": {
            "width": _field_width,
            "height": _field_height
        }
    }


func _is_invulnerable(unit: Dictionary) -> bool:
    return bool(unit.get("transit", {}).get("invulnerable", false))


func _begin_transit(unit: Dictionary, ability: Dictionary) -> bool:
    var enemies := _alive_units(_other_side(str(unit["side"])))
    if enemies.is_empty():
        return false
    # Prefer support/ranged units, then the deepest enemy. Stable ID breaks ties.
    var direction := 1.0 if str(unit["side"]) == PLAYER_SIDE else -1.0
    enemies.sort_custom(func(a, b):
        var support_a := 1 if str(a.get("role", "")) in ["range", "healer"] else 0
        var support_b := 1 if str(b.get("role", "")) in ["range", "healer"] else 0
        if support_a != support_b:
            return support_a > support_b
        if absf(float(a["x"]) - float(b["x"])) > EPSILON:
            return float(a["x"]) * direction > float(b["x"]) * direction
        return str(a["id"]) < str(b["id"]))
    var target: Dictionary = enemies[0]
    var desired := _clamp_position(_unit_position(target) + Vector2(direction * 1.1, 0))
    var destination := _free_landing(desired, str(unit["id"]))
    if destination.x < 0:
        return false
    var origin := _unit_position(unit)
    var duration := maxf(_step, float(ability.get("transit_seconds", 0.8)))
    var transit := {"from_x": origin.x, "from_y": origin.y, "to_x": destination.x, "to_y": destination.y, "started_at": _time, "ends_at": _time + duration, "mode": str(ability.get("mode", "flame")), "invulnerable": bool(ability.get("invulnerable", false)), "hit_ids": []}
    unit["transit"] = transit
    unit["target_id"] = str(target["id"])
    unit["ability_cooldown"] = float(ability.get("cooldown_seconds", 5))
    _events.append(BattleEventScript.make("ability", _time, {"kind": "backline_transit", "side": unit["side"], "unit_id": unit["id"], "card_id": unit["card_id"], "target_id": target["id"], "transit": transit.duplicate(true)}))
    return true


func _free_landing(desired: Vector2, unit_id: String) -> Vector2:
    for ring in range(7):
        for index in range(12):
            var candidate := _clamp_position(desired + Vector2.from_angle(float(index) * TAU / 12.0) * float(ring) * 0.6)
            if not _position_collides(candidate, unit_id):
                return candidate
    return Vector2(-1, -1)


func _tick_special_effects() -> void:
    var previous_size := _obstacles.size()
    _obstacles = _obstacles.filter(func(wall): return float(wall["expires_at"]) > _time + EPSILON)
    if _obstacles.size() != previous_size:
        _terrain_revision += 1
    _links = _links.filter(func(link): return float(link["expires_at"]) > _time + EPSILON)
    for unit in _units:
        var transit: Dictionary = unit.get("transit", {})
        if not bool(unit.get("alive", false)) or transit.is_empty():
            continue
        var ability: Dictionary = unit.get("ability", {})
        var origin := _unit_position(unit)
        var progress := clampf((_time - float(transit["started_at"])) / maxf(_step, float(transit["ends_at"]) - float(transit["started_at"])), 0, 1)
        var point := Terrain.point(transit, "from").lerp(Terrain.point(transit, "to"), progress)
        unit["x"] = point.x
        unit["y"] = point.y
        if str(transit["mode"]) == "gush":
            for enemy in _alive_units(_other_side(str(unit["side"]))):
                if transit["hit_ids"].has(str(enemy["id"])):
                    continue
                if Terrain.segment_distance(origin, point, _unit_position(enemy), _unit_position(enemy)) <= float(ability.get("contact_radius", 1.3)):
                    transit["hit_ids"].append(str(enemy["id"]))
                    if not _is_invulnerable(enemy):
                        _queue_raw_damage(str(enemy["id"]), float(unit["attack"]) * float(ability.get("attack_pct", 80)) / 100.0, str(unit["side"]), str(unit["id"]), "gush")
                        var closest := Geometry2D.get_closest_point_to_segment(_unit_position(enemy), origin, point)
                        var before := _unit_position(enemy)
                        _push_from_position(enemy, closest, _push_from_value(str(ability.get("pushback", "moderate"))))
                        _events.append(BattleEventScript.make("pushback", _time, {"kind": "gush_hit", "side": unit["side"], "unit_id": unit["id"], "target_id": enemy["id"], "from_x": before.x, "from_y": before.y, "to_x": enemy["x"], "to_y": enemy["y"]}))
        if str(transit["mode"]) == "flame" and origin.distance_to(point) > EPSILON:
            # One swept segment per step; one tick per enemy per cast across all
            # segments avoids overlapping dots multiplying the trail damage.
            var cast_id := str(unit["id"]) + ":" + str(transit["started_at"])
            var hazard: Dictionary = {}
            for existing in _hazards:
                if existing["id"] == cast_id:
                    hazard = existing
                    break
            if hazard.is_empty():
                hazard = {"id": cast_id, "side": unit["side"], "source_id": unit["id"], "segments": [], "expires_at": _time + float(ability.get("trail_seconds", 4)), "next_tick": _time, "tick_seconds": float(ability.get("tick_seconds", 0.5)), "radius": float(ability.get("trail_radius", 0.7)), "damage": float(unit["attack"]) * float(ability.get("damage_attack_pct_per_tick", 35)) / 100.0}
                _hazards.append(hazard)
            hazard["segments"].append({"from_x": origin.x, "from_y": origin.y, "to_x": point.x, "to_y": point.y})
        if progress >= 1 - EPSILON:
            # Another actor may occupy the destination since cast time.
            var landing := _free_landing(point, str(unit["id"]))
            if landing.x < 0:
                landing = _free_landing(Terrain.point(transit, "from"), str(unit["id"]))
            if landing.x < 0:
                # Stay in travel briefly rather than materializing inside an actor.
                transit["ends_at"] = _time + _step
                continue
            unit["x"] = landing.x
            unit["y"] = landing.y
            unit["transit"] = {}
            unit["route"] = []
            if str(transit["mode"]) == "burrow":
                _create_crack(unit, transit, float(ability.get("obstacle_seconds", 5)))
            _events.append(BattleEventScript.make("ability", _time, {"kind": "transit_arrival", "side": unit["side"], "unit_id": unit["id"], "card_id": unit["card_id"], "x": unit["x"], "y": unit["y"], "mode": transit["mode"]}))
    _hazards = _hazards.filter(func(hazard): return float(hazard["expires_at"]) > _time + EPSILON)
    for hazard in _hazards:
        if _time + EPSILON < float(hazard["next_tick"]):
            continue
        hazard["next_tick"] = _time + float(hazard["tick_seconds"])
        for enemy in _alive_units(_other_side(str(hazard["side"]))):
            for segment in hazard["segments"]:
                if Terrain.segment_distance(Terrain.point(segment, "from"), Terrain.point(segment, "to"), _unit_position(enemy), _unit_position(enemy)) <= float(hazard["radius"]):
                    _queue_raw_damage(str(enemy["id"]), float(hazard["damage"]), str(hazard["side"]), str(hazard["source_id"]), "flame_trail")
                    break


func _create_crack(unit: Dictionary, transit: Dictionary, duration: float) -> void:
    var a := Terrain.point(transit, "from")
    var b := _unit_position(unit)
    var axis := (b - a).normalized()
    # Leave room around both ends, including when a transit begins at an edge.
    a += axis * 1.0
    b -= axis * 1.0
    if a.distance_to(b) < 1.0 or (b - a).dot(axis) <= 0:
        return
    var wall := {"from_x": a.x, "from_y": a.y, "to_x": b.x, "to_y": b.y, "expires_at": _time + duration, "side": unit["side"]}
    _obstacles.append(wall)
    _terrain_revision += 1
    # A rising crack can appear under an actor. Move its center to the nearest
    # free shoulder once; subsequent movement may never cross the barrier.
    for other in _units:
        if not bool(other.get("alive", false)) or not other.get("transit", {}).is_empty():
            continue
        var old := _unit_position(other)
        if Terrain.clear_line(old, old, _obstacles, _collision_radius):
            continue
        var normal := axis.orthogonal()
        var closest := Geometry2D.get_closest_point_to_segment(old, a, b)
        if (old - closest).dot(normal) < 0:
            normal = -normal
        for side_sign in [1.0, -1.0]:
            var proposed := _clamp_position(closest + normal * side_sign * (_collision_radius + 0.15))
            if not _position_collides(proposed, str(other["id"])):
                other["x"] = proposed.x
                other["y"] = proposed.y
                break
        if not Terrain.clear_line(_unit_position(other), _unit_position(other), _obstacles, _collision_radius):
            var fallback := _free_landing(old, str(other["id"]))
            if fallback.x >= 0:
                other["x"] = fallback.x
                other["y"] = fallback.y
        if _unit_position(other).distance_to(old) > EPSILON:
            _events.append(BattleEventScript.make("pushback", _time, {"kind": "crack_rise", "target_id": other["id"], "from_x": old.x, "from_y": old.y, "to_x": other["x"], "to_y": other["y"]}))
    _events.append(BattleEventScript.make("ability", _time, {"kind": "crack", "side": unit["side"], "unit_id": unit["id"], "wall": wall.duplicate(true)}))


func _cast_damage_link(unit: Dictionary, target: Dictionary, ability: Dictionary) -> void:
    if _unit_position(unit).distance_to(_unit_position(target)) > float(unit.get("range", 5)) + EPSILON:
        return
    var targets: Array[String] = [str(target["id"])]
    var nearby := _alive_units(_other_side(str(unit["side"])))
    nearby.sort_custom(func(a, b):
        var da := _unit_position(a).distance_squared_to(_unit_position(target))
        var db := _unit_position(b).distance_squared_to(_unit_position(target))
        return da < db if absf(da - db) > EPSILON else str(a["id"]) < str(b["id"]))
    for enemy in nearby:
        if targets.size() >= int(ability.get("max_targets", 2)):
            break
        if targets.has(str(enemy["id"])):
            continue
        if _unit_position(enemy).distance_to(_unit_position(target)) <= float(ability.get("link_radius", 3.5)) and _unit_position(enemy).distance_to(_unit_position(unit)) <= float(unit.get("range", 5)) + EPSILON:
            targets.append(str(enemy["id"]))
    _links = _links.filter(func(link): return link["source_id"] != unit["id"])
    var link := {"source_id": unit["id"], "side": unit["side"], "target_ids": targets, "expires_at": _time + float(ability.get("duration_seconds", 5)), "shared_damage_pct": float(ability.get("shared_damage_pct", 50))}
    _links.append(link)
    unit["ability_cooldown"] = float(ability.get("cooldown_seconds", 5))
    _events.append(BattleEventScript.make("ability", _time, {"kind": "sticky_link", "side": unit["side"], "unit_id": unit["id"], "card_id": unit["card_id"], "link": link.duplicate(true)}))


func _share_damage(target: Dictionary, amount: float, original: Dictionary) -> void:
    if amount <= 0:
        return
    var partners := {}
    for link in _links:
        if float(link["expires_at"]) <= _time + EPSILON or str(link["side"]) != str(original.get("source_side", "")) or not link["target_ids"].has(str(target["id"])):
            continue
        for partner_id in link["target_ids"]:
            if partner_id != str(target["id"]):
                partners[partner_id] = maxf(float(partners.get(partner_id, 0)), float(link["shared_damage_pct"]))
    for partner_id in partners:
        _apply_damage_event({"target_id": partner_id, "amount": amount * float(partners[partner_id]) / 100.0, "source_side": original.get("source_side", ""), "source_unit_id": original.get("source_unit_id", ""), "source": "sticky_share", "no_share": true})
