class_name UnitUpgradeEffects
extends RefCounted
## Reusable Lv. 2 hooks. All per-unit behavior/tuning comes from content traits.

static func initialize(unit: Dictionary, time: float) -> void:
    for key in ["upgrade_debuffs", "root_until", "upgrade_focus_target", "upgrade_focus_count", "upgrade_heal_ticks", "upgrade_pulse_next", "transits_completed"]:
        unit.erase(key)
    var pulse := UnitUpgrades.get_trait(unit, "pulse_damage")
    if not pulse.is_empty():
        unit["upgrade_pulse_next"] = time + float(pulse["interval"])

static func attack_profile(unit: Dictionary, target_id: String) -> Dictionary:
    var result := {"hits": 1, "multiplier": 1.0, "post_defense_multiplier": 1.0}
    for spec in unit.get("upgrade_traits", []):
        match str(spec["type"]):
            "attack_hits":
                result["hits"] = int(spec["hits"])
                result["post_defense_multiplier"] *= float(spec["damage_pct"]) / 100.0
            "attack_rate":
                result["post_defense_multiplier"] *= float(spec["damage_pct"]) / 100.0
            "focus_damage":
                var count := int(unit.get("upgrade_focus_count", 0)) if str(unit.get("upgrade_focus_target", "")) == target_id else 0
                count = mini(int(spec["max_stacks"]), count + 1)
                unit["upgrade_focus_target"] = target_id
                unit["upgrade_focus_count"] = count
                result["multiplier"] *= 1.0 + float(count) * float(spec["stack_pct"]) / 100.0
    return result

static func tick(sim: RefCounted) -> void:
    if not sim._upgrade_effects_active:
        return
    var kept: Array[Dictionary] = []
    for strike in sim._followup_attacks:
        if float(strike["at"]) > float(sim._time) + 0.0001:
            kept.append(strike)
            continue
        var source: Dictionary = sim._unit_by_id(str(strike["source_id"]))
        var target: Dictionary = sim._unit_by_id(str(strike["target_id"]))
        if source.is_empty() or target.is_empty() or not bool(source.get("alive", false)) or not bool(target.get("alive", false)):
            continue
        if not sim._are_enemies(str(source["side"]), str(target["side"])):
            continue
        var distance: float = sim._unit_position(source).distance_to(sim._unit_position(target))
        var reach := float(source.get("range", 1)) if sim._is_ranged(source) else (1.0 if source.get("ability", {}).get("type") == "pull_then_melee" else float(source.get("range", 1)))
        if distance <= reach + 0.0001 and (sim._is_ranged(source) or CombatTerrain.clear_line(sim._unit_position(source), sim._unit_position(target), sim._obstacles, 0.05)):
            sim._perform_strike(source, target, float(strike["damage"]), float(strike.get("damage_scale", 1)))
    sim._followup_attacks = kept
    for unit in sim._units:
        if not bool(unit.get("alive", false)):
            continue
        var spec := UnitUpgrades.get_trait(unit, "pulse_damage")
        if spec.is_empty() or float(sim._time) + 0.0001 < float(unit.get("upgrade_pulse_next", 0)):
            continue
        unit["upgrade_pulse_next"] = float(sim._time) + float(spec["interval"])
        var radius: float = sim._radius_from_value(str(spec["radius"]))
        var position: Vector2 = sim._unit_position(unit)
        for enemy in sim._alive_units(sim._other_side(str(unit["side"]))):
            if position.distance_to(sim._unit_position(enemy)) <= radius + 0.0001:
                sim._queue_raw_damage(str(enemy["id"]), float(unit["attack"]) * float(spec["attack_pct"]) / 100.0, str(unit["side"]), str(unit["id"]), "upgrade_pulse")
        emit(sim, unit, "upgrade_pulse", {"x": position.x, "y": position.y, "radius": radius})

static func on_hit(sim: RefCounted, source: Dictionary, target: Dictionary) -> void:
    if source.is_empty() or not sim._are_enemies(str(source.get("side", "")), str(target.get("side", ""))) or sim._is_invulnerable(target):
        return
    for spec in source.get("upgrade_traits", []):
        if spec["type"] == "hit_debuff":
            var debuffs: Array = target.get("upgrade_debuffs", [])
            var found := false
            for existing in debuffs:
                if existing["key"] == spec["key"]:
                    existing["stacks"] = mini(int(spec["max_stacks"]), int(existing["stacks"]) + 1) if float(existing["until"]) > float(sim._time) else 1
                    existing["until"] = float(sim._time) + float(spec["duration_seconds"])
                    found = true
                    break
            if not found:
                debuffs.append({"key": spec["key"], "stat": spec["stat"], "percentage": spec["percentage"], "stacks": 1, "until": float(sim._time) + float(spec["duration_seconds"])})
            target["upgrade_debuffs"] = debuffs
            emit(sim, source, "upgrade_debuff", {"target_id": target["id"], "stat": spec["stat"]})
        elif spec["type"] == "attack_proc" and sim._rng.randf() * 100.0 < float(spec["chance_pct"]):
            var position: Vector2 = sim._unit_position(target)
            if spec["action"] == "area_damage":
                var radius: float = sim._radius_from_value(str(spec["radius"]))
                for enemy in sim._alive_units(sim._other_side(str(source["side"]))):
                    if position.distance_to(sim._unit_position(enemy)) <= radius + 0.0001:
                        sim._queue_raw_damage(str(enemy["id"]), float(source["attack"]) * float(spec["attack_pct"]) / 100.0, str(source["side"]), str(source["id"]), "ice_splinter")
                emit(sim, source, "ice_splinter", {"x": position.x, "y": position.y, "radius": radius})
            else:
                sim._push_from_source(target, source, sim._push_from_value(str(spec["pushback"])))
                emit(sim, source, "upgrade_knockback", {"target_id": target["id"], "x": position.x, "y": position.y})
                sim._events.append(BattleEvent.make("pushback", sim._time, {"target_id": target["id"], "from_x": position.x, "from_y": position.y, "to_x": target["x"], "to_y": target["y"]}))

static func on_impact(sim: RefCounted, source: Dictionary, position: Vector2) -> void:
    var spec := UnitUpgrades.get_trait(source, "impact_area")
    if spec.is_empty():
        return
    var effect := make_area(sim, source, spec, "damage_area", position)
    effect["source"] = "upgrade_ground_fire"
    effect["refresh_key"] = str(source["id"]) + ":upgrade_ground_fire"
    # Refresh a caster's field without restarting its damage tick countdown.
    var kept: Array[Dictionary] = []
    for existing in sim._area_effects:
        if existing.get("source") == "upgrade_ground_fire" and existing.get("source_unit_id") == source.get("id"):
            effect["tick_timer"] = float(existing.get("tick_timer", 1))
        else:
            kept.append(existing)
    sim._area_effects = kept
    sim._area_effects.append(effect)
    emit(sim, source, "upgrade_ground_fire", {"area": effect.duplicate(true), "x": position.x, "y": position.y, "radius": effect["radius"]})

static func on_death(sim: RefCounted, source: Dictionary) -> void:
    var position: Vector2 = sim._unit_position(source)
    for spec in source.get("upgrade_traits", []):
        var radius: float = sim._radius_from_value(str(spec.get("radius", "medium")))
        match str(spec["type"]):
            "death_heal":
                for ally in sim._alive_units(str(source["side"])):
                    if position.distance_to(sim._unit_position(ally)) <= radius + 0.0001:
                        heal(sim, source, ally, float(ally["max_hp"]) * float(spec["heal_pct"]) / 100.0)
                emit(sim, source, "upgrade_death_heal", {"x": position.x, "y": position.y, "radius": radius})
            "death_field", "death_heal_area":
                var effect := make_area(sim, source, spec, "modifier_area" if spec["type"] == "death_field" else "heal", position)
                sim._area_effects.append(effect)
                emit(sim, source, "upgrade_death_field", {"area": effect.duplicate(true), "x": position.x, "y": position.y, "radius": radius})
            "death_link":
                var targets: Array[String] = []
                for enemy in sim._alive_units(sim._other_side(str(source["side"]))):
                    if position.distance_to(sim._unit_position(enemy)) <= radius + 0.0001:
                        targets.append(str(enemy["id"]))
                var link := {"source_id": source["id"], "side": source["side"], "target_ids": targets, "expires_at": float(sim._time) + float(spec["duration_seconds"]), "shared_damage_pct": float(spec["shared_damage_pct"])}
                sim._links.append(link)
                emit(sim, source, "sticky_link", {"link": link.duplicate(true), "x": position.x, "y": position.y, "radius": radius})

static func make_area(sim: RefCounted, source: Dictionary, spec: Dictionary, kind: String, position: Vector2) -> Dictionary:
    var interval := float(spec.get("tick_seconds", 1))
    return {"type": kind, "side": source["side"], "source_unit_id": source["id"], "card_id": source.get("card_id", ""), "element": source.get("element", "earth"), "x": position.x, "y": position.y, "radius": sim._radius_from_value(str(spec.get("radius", "large"))), "remaining": spec["duration_seconds"], "duration": spec["duration_seconds"], "created_at": float(sim._time), "tick_timer": interval, "tick_seconds": interval, "damage": float(source["attack"]) * float(spec.get("attack_pct", 0)) / 100.0, "heal_max_hp_pct": spec.get("heal_pct", 0), "stat": spec.get("stat", ""), "percentage": spec.get("percentage", 0), "stacking_key": spec.get("stacking_key", ""), "upgrade_field": true}

static func heal(sim: RefCounted, source: Dictionary, target: Dictionary, amount: float) -> void:
    var before := float(target["hp"])
    target["hp"] = minf(float(target["max_hp"]), before + maxf(0, amount))
    var actual := maxf(0, float(target["hp"]) - before)
    if actual > 0:
        sim._events.append(BattleEvent.make("heal", sim._time, {"target_id": target["id"], "amount": actual, "effective_healing": actual, "hp_after": target["hp"], "source_unit_id": source["id"], "source": "upgrade_death_heal"}))

static func modifier_pct(sim: RefCounted, unit: Dictionary, stat: String) -> float:
    if not sim._upgrade_effects_active:
        return 0.0
    var total := 0.0
    for entry in unit.get("upgrade_debuffs", []):
        if entry["stat"] == stat and float(entry["until"]) > float(sim._time) + 0.0001:
            total += float(entry["percentage"]) * int(entry["stacks"])
    var field := 0.0
    for area in sim._area_effects:
        if area.get("type") == "modifier_area" and area.get("stat") == stat and area.get("side") != unit.get("side") and float(area.get("remaining", 0)) > 0:
            var position := Vector2(float(area["x"]), float(area["y"]))
            if position.distance_to(sim._unit_position(unit)) <= float(area["radius"]) + 0.0001:
                field = maxf(field, float(area["percentage"]))
    return clampf(total + field, 0, 60)

static func rooted(sim: RefCounted, unit: Dictionary) -> bool:
    return float(unit.get("root_until", 0)) > float(sim._time) + 0.0001

static func emit(sim: RefCounted, source: Dictionary, kind: String, data: Dictionary) -> void:
    var event := {"side": source["side"], "unit_id": source["id"], "card_id": source.get("card_id", ""), "kind": kind, "ability": source.get("upgrade_name", "Lv. 2")}
    event.merge(data, true)
    sim._events.append(BattleEvent.make("ability", sim._time, event))
