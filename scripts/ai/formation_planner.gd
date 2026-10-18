class_name FormationPlanner
extends RefCounted

# A bounded tactical heuristic, shared by both armies. It reads only the
# revealed battle rosters; it neither simulates candidate battles nor drafts.
static func plan(side: Dictionary, enemy: Dictionary, field: Dictionary) -> Dictionary:
    var units := _roster(side)
    if units.is_empty():
        return {"placements": [], "strategy": "empty", "spacing": 0.0}
    var width := float(field.get("width", 24))
    var height := float(field.get("height", 14))
    var margin := float(field.get("margin", 1))
    var collision := float(field.get("collision_radius", 0.42))
    var settings: Dictionary = field.get("settings", {})
    var pressure := _enemy_pressure(enemy)
    var minimum_spacing := collision * 2 + 0.02
    var desired_spacing := maxf(minimum_spacing, float(settings.get("spacing_units", 1.65)))
    desired_spacing *= lerpf(1, float(settings.get("area_spread_multiplier", 1.2)), float(pressure["area"]))
    var usable_height := maxf(minimum_spacing, height - 2 * margin - 1.0)
    var row_limit := mini(int(settings.get("maximum_rows", 7)), int(floor(usable_height / desired_spacing)) + 1)
    var rows := clampi(int(ceil(sqrt(float(units.size()) * 1.6))), 1, maxi(1, row_limit))
    rows = mini(rows, units.size())
    if rows % 2 == 0 and rows < row_limit and _has_healer(units):
        rows += 1
    var groups: Array = [[], [], []]
    for unit in units:
        groups[int(unit["tier"])].append(unit)
    var columns := _column_counts(groups, rows)
    var column_total := int(columns[0]) + int(columns[1]) + int(columns[2])
    var front := width * 0.38
    var horizontal_room := maxf(minimum_spacing, front - margin)
    if column_total > 1 and horizontal_room / float(column_total - 1) < minimum_spacing:
        # Crowded custom battlefields may need more rows and tighter spacing;
        # retain physical separation rather than dropping or overlapping units.
        rows = maxi(1, mini(units.size(), int(floor(usable_height / minimum_spacing)) + 1))
        columns = _column_counts(groups, rows)
        column_total = int(columns[0]) + int(columns[1]) + int(columns[2])
    var x_spacing := minf(desired_spacing, horizontal_room / float(maxi(1, column_total - 1)))
    var y_spacing := minf(desired_spacing, usable_height / float(maxi(1, rows - 1)))
    var placements: Array[Dictionary] = []
    var guards: Array[Dictionary] = []
    var first_column := 0
    for tier in range(3):
        var group: Array = groups[tier]
        var column_count := int(columns[tier])
        if group.is_empty():
            continue
        group.sort_custom(_priority)
        var slots: Array[Dictionary] = []
        for column in range(column_count):
            for row in range(rows):
                slots.append({"rank": first_column + column, "depth": column,
                    "x": front - float(first_column + column) * x_spacing,
                    "y": height * 0.5 + (float(row) - float(rows - 1) * 0.5) * y_spacing})
        var band: Array[Dictionary] = []
        var shortest_reach := INF
        var longest_reach := 0.0
        for unit in group:
            if str(unit["role"]) != "healer":
                shortest_reach = minf(shortest_reach, float(unit["reach"]))
                longest_reach = maxf(longest_reach, float(unit["reach"]))
        for unit in group:
            var best_index := 0
            var best_score := INF
            for index in range(slots.size()):
                var score := _slot_cost(unit, slots[index], column_count, height, y_spacing,
                    shortest_reach, longest_reach, guards, pressure)
                if score < best_score - 0.00001:
                    best_score = score
                    best_index = index
            var slot: Dictionary = slots[best_index]
            slots.remove_at(best_index)
            band.append({"card_id": str(unit["card_id"]), "unit_index": int(unit["unit_index"]),
                "role": str(unit["role"]), "rank": int(slot["rank"]),
                "x": float(slot["x"]), "y": float(slot["y"]), "durability": float(unit["durability"])})
        _center_columns(band, height, margin)
        placements.append_array(band)
        if tier < 2:
            guards.append_array(band)
        first_column += column_count
    # Input card order cannot change placement or simultaneous-action ordering.
    placements.sort_custom(func(a, b):
        if str(a["card_id"]) != str(b["card_id"]):
            return str(a["card_id"]) < str(b["card_id"])
        return int(a["unit_index"]) < int(b["unit_index"]))
    var mirrored := str(side.get("id", "player")) == "opponent"
    for placement in placements:
        if mirrored:
            placement["x"] = width - float(placement["x"])
        placement.erase("durability")
    return {"placements": placements, "strategy": "spread" if float(pressure["area"]) > 0 else "screened",
        "spacing": y_spacing, "rank_spacing": x_spacing, "ranks": column_total,
        "enemy_area_pressure": float(pressure["area"]), "enemy_melee_pressure": float(pressure["melee"])}

static func _roster(side: Dictionary) -> Array[Dictionary]:
    var units: Array[Dictionary] = []
    for card in side.get("cards", []):
        var count := maxi(0, int(side.get("unit_counts", {}).get(card.get("id"), 0)))
        var stats: Dictionary = card.get("stats", {})
        var role := str(card.get("role", "melee"))
        var ability: Dictionary = card.get("ability", {})
        for index in range(count):
            units.append({"card_id": str(card.get("id", "")), "unit_index": index, "role": role,
                "tier": 0 if role == "tank" else (1 if role == "melee" else 2),
                "ability_type": str(ability.get("type", "")),
                "reach": float(ability.get("pull_range", stats.get("range", 1))),
                "durability": float(stats.get("health", 1)) * (1 + float(stats.get("defense", 0)) / 100)})
    return units

static func _has_healer(units: Array) -> bool:
    return units.any(func(unit): return str(unit.get("role", "")) == "healer")

static func _column_counts(groups: Array, rows: int) -> Array[int]:
    var result: Array[int] = []
    for group in groups:
        result.append(int(ceil(float(group.size()) / float(maxi(1, rows)))))
    var backline: Array = groups[2]
    if _has_healer(backline) and backline.any(func(unit): return str(unit["role"]) != "healer"):
        result[2] = maxi(2, result[2])
    return result

static func _priority(a: Dictionary, b: Dictionary) -> bool:
    var a_healer := str(a["role"]) == "healer"
    var b_healer := str(b["role"]) == "healer"
    if a_healer != b_healer:
        return a_healer
    if int(a["tier"]) == 1:
        var a_contact := str(a["ability_type"]) in ["explosion", "death_damage_area", "absorb_burst", "aura_damage", "aura_debuff"]
        var b_contact := str(b["ability_type"]) in ["explosion", "death_damage_area", "absorb_burst", "aura_damage", "aura_debuff"]
        if a_contact != b_contact:
            return a_contact
    if int(a["tier"]) == 2 and not is_equal_approx(float(a["reach"]), float(b["reach"])):
        return float(a["reach"]) > float(b["reach"])
    if not is_equal_approx(float(a["durability"]), float(b["durability"])):
        return float(a["durability"]) > float(b["durability"]) if int(a["tier"]) == 0 else float(a["durability"]) < float(b["durability"])
    if str(a["card_id"]) != str(b["card_id"]):
        return str(a["card_id"]) < str(b["card_id"])
    return int(a["unit_index"]) < int(b["unit_index"])

static func _slot_cost(unit: Dictionary, slot: Dictionary, columns: int, height: float, spacing: float,
    shortest: float, longest: float, guards: Array[Dictionary], pressure: Dictionary) -> float:
    var role := str(unit["role"])
    var tier := int(unit["tier"])
    var desired_depth := 0.0
    if tier == 2:
        desired_depth = float(mini(1, columns - 1)) if role == "healer" else clampf((float(unit["reach"]) - shortest) / maxf(1, longest - shortest), 0, 1) * float(columns - 1)
    var score := absf(float(slot["depth"]) - desired_depth) * 9.0
    var centered_y := (float(slot["y"]) - height * 0.5) / maxf(0.1, spacing)
    var center_weight := 3.0 if role == "healer" else (0.25 if tier == 1 else 0.8)
    score += centered_y * centered_y * center_weight
    if guards.is_empty():
        return score
    var nearest_screen := INF
    var coverage := 0.0
    var total_weight := 0.0
    var screen_edge := 0.0
    for guard in guards:
        nearest_screen = minf(nearest_screen, absf(float(slot["y"]) - float(guard["y"])))
        screen_edge = maxf(screen_edge, absf(float(guard["y"]) - height * 0.5))
        var weight := sqrt(float(guard["durability"]))
        total_weight += weight
        if Vector2(float(slot["x"]), float(slot["y"])).distance_to(Vector2(float(guard["x"]), float(guard["y"]))) <= float(unit["reach"]):
            coverage += weight
    if role == "healer":
        score += (1 - coverage / maxf(1, total_weight)) * 32
        score += nearest_screen / spacing * (2 + float(pressure["melee"]) * 3)
    elif tier == 1:
        # Melee wings can advance around their own screen rather than pile up
        # directly behind a Tank. Keep those wings close enough to reconnect.
        var flank := minf(height * 0.3, screen_edge + spacing * 0.7)
        score += absf(absf(float(slot["y"]) - height * 0.5) - flank) / spacing * 2
    else:
        score += nearest_screen / spacing * (1 + float(pressure["melee"]) * 2)
    return score

static func _center_columns(placements: Array[Dictionary], height: float, margin: float) -> void:
    var by_rank := {}
    for placement in placements:
        var rank := int(placement["rank"])
        if not by_rank.has(rank):
            by_rank[rank] = []
        by_rank[rank].append(placement)
    for column in by_rank.values():
        var mean := 0.0
        var top := INF
        var bottom := -INF
        for placement in column:
            mean += float(placement["y"])
            top = minf(top, float(placement["y"]))
            bottom = maxf(bottom, float(placement["y"]))
        mean /= float(column.size())
        var shift := clampf(height * 0.5 - mean, margin - top, height - margin - bottom)
        for placement in column:
            placement["y"] = float(placement["y"]) + shift

static func _enemy_pressure(enemy: Dictionary) -> Dictionary:
    var total := 0.0
    var area := 0.0
    var melee := 0.0
    for card in enemy.get("cards", []):
        var count := float(enemy.get("unit_counts", {}).get(card.get("id"), 0))
        total += count
        var ability_type := str(card.get("ability", {}).get("type", ""))
        if ability_type in ["ranged_aoe", "ranged_aoe_dot", "explosion", "death_damage_area", "absorb_burst", "aura_damage"]:
            area += count
        if str(card.get("role", "")) in ["tank", "melee"] or ability_type == "pull_then_melee":
            melee += count
    var skill: Dictionary = enemy.get("commander", {}).get("active_skill", {})
    if bool(enemy.get("commander_skill_active", false)) and skill.get("type") == "targeted_aoe_max_hp":
        area += maxf(1, total * 0.5)
    return {"area": clampf(area / maxf(1, total), 0, 1), "melee": clampf(melee / maxf(1, total), 0, 1)}
