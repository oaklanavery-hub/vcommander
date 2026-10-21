class_name BattlefieldView
extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
const GROUND := preload("res://assets/pixel/forest-clearing-v1.png")
static var reduced_motion := false
static var show_hp_numbers := false
var _frame: Dictionary = {}
var _next_frame: Dictionary = {}
var _field_width := 24.0
var _field_height := 14.0
var _visual_time := 0.0
var _blend := 0.0
var _arena := Rect2()
var _known: Dictionary = {}
var _poses: Dictionary = {}
var _effects: Array[Dictionary] = []
var _sides: Array[Dictionary] = []
var prelude_skills: Array = []
var prelude_time := 0.0
var replay := BattleReplay.new()
var replay_enabled := false
var replay_complete := false
var frozen_sides: Array[String] = []

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func configure_frost() -> void:
    frozen_sides.clear()
    for side in _sides:
        var skill: Dictionary = side.get("commander", {}).get("active_skill", {})
        if bool(side.get("commander_skill_active", false)) and skill.get("type") == "round_debuff":
            var affected := "opponent" if side.get("id", "player") == "player" else "player"
            if not frozen_sides.has(affected):
                frozen_sides.append(affected)
    queue_redraw()

func frost_coverage() -> float:
    if frozen_sides.is_empty():
        return 0.0
    return 1.0 if replay_enabled else clampf((prelude_time - 0.3) / 1.3, 0, 1)

func set_side_configs(player: Dictionary, opponent: Dictionary) -> void:
    _sides.assign([player, opponent])

func set_battlefield_size(width: float, height: float) -> void:
    _field_width = maxf(1.0, width)
    _field_height = maxf(1.0, height)
    queue_redraw()

func set_frame(frame: Dictionary) -> void:
    set_playback(frame, frame, 0.0, float(frame.get("time", 0.0)))

func set_playback(frame: Dictionary, next_frame: Dictionary, blend: float, time: float) -> void:
    _frame = frame
    _next_frame = next_frame
    _blend = clampf(blend, 0.0, 1.0)
    _visual_time = time
    for unit in frame.get("units", []):
        _known[str(unit.get("id", ""))] = unit
    _effects = _effects.filter(func(effect): return time - float(effect.get("time", 0)) < 1.2)
    queue_redraw()

func finish_replay() -> void:
    _effects.clear()
    _poses.clear()
    queue_redraw()

func consume_event(event: Dictionary) -> void:
    var type := str(event.get("type", ""))
    var unit_id := str(event.get("unit_id", event.get("source_unit_id", "")))
    var target_id := str(event.get("target_id", ""))
    if type == "spawn":
        var pieces := unit_id.split(":")
        var info: Dictionary = event.get("unit", _known.get(unit_id, {})).duplicate()
        info.merge({"id": unit_id, "x": info.get("x", event.get("x", 0)), "y": info.get("y", event.get("y", 0)), "side": event.get("side", "player"), "role": event.get("role", "range"), "card_id": pieces[1] if pieces.size() > 1 else ""}, true)
        info["summoned"] = bool(event.get("summoned", info.get("summoned", false)))
        _known[unit_id] = info
        if event.get("source") == "commander_skill":
            var sprout := event.duplicate(true)
            sprout["type"] = "summon"
            _effects.append(sprout)
        elif event.get("source") in ["death_split", "revival"]:
            var birth := event.duplicate(true)
            birth["type"] = "rebirth" if event.get("source") == "revival" else "split_birth"
            _effects.append(birth)
        return
    if _visual_time - float(event.get("time", 0)) > 1.2:
        return
    var source: Dictionary = _known.get(unit_id, {})
    if type == "defeat" and event.has("unit"):
        source = event["unit"]
    var target: Dictionary = _known.get(target_id, {})
    if type == "attack":
        var pose: Dictionary = _poses.get(unit_id, {})
        var direction := Vector2(float(event.get("target_x", target.get("x", 0))) - float(event.get("x", source.get("x", 0))), float(event.get("target_y", target.get("y", 0))) - float(event.get("y", source.get("y", 0))))
        var motion := str(CombatCues.event_profile(event).get("motion", "slash"))
        pose["attack_started"] = float(event.get("time", 0))
        for effect in _effects:
            if effect.get("kind") == "pull" and effect.get("target_id") == target_id and float(event.get("time", 0)) - float(effect.get("time", 0)) < 0.15:
                pose["attack_started"] = float(effect.get("time", 0)) + 0.54
        pose["attack_duration"] = 0.42 if motion == "slam" else 0.32
        pose["attack_until"] = float(pose["attack_started"]) + float(pose["attack_duration"])
        pose["motion"] = motion
        pose["attack_facing"] = posmod(int(round(direction.angle() / (PI / 2.0))) * 2, 8)
        _poses[unit_id] = pose
    if type in ["damage", "heal", "defeat", "ability", "commander_skill", "attack", "projectile_impact"]:
        var at: Dictionary = target if type in ["damage", "heal"] or event.get("kind") == "meteor" else source
        var effect := event.duplicate(true)
        if event.get("kind") == "pull":
            effect["target_unit"] = target.duplicate()
        var profile := CombatCues.event_profile(event)
        effect.merge({"x": event.get("x", at.get("x", 0)), "y": event.get("y", at.get("y", 0)), "unit": at.duplicate(), "unit_id": target_id if type in ["damage", "heal"] else unit_id, "element": event.get("element", source.get("element", "earth")), "style": profile.get("projectile" if type == "projectile_impact" else "motion", "slash")}, true)
        if type == "attack" and event.get("kind") == "melee" and profile.has("impact_style"):
            effect["style"] = profile["impact_style"]
        if type == "attack":
            effect["time"] = _poses.get(unit_id, {}).get("attack_started", event.get("time", 0))
        if type == "damage" and event.get("source") == "normal_attack":
            for pull in _effects:
                if pull.get("kind") == "pull" and pull.get("unit_id") == event.get("source_unit_id") and pull.get("target_id") == target_id and float(event.get("time", 0)) - float(pull.get("time", 0)) < 0.15:
                    effect["time"] = float(pull["time"]) + 0.54
        if type == "defeat":
            for hit in _effects:
                if hit.get("type") != "damage" or hit.get("target_id") != unit_id or float(hit.get("hp_after", 1)) > 0 or float(hit.get("time", 0)) <= float(event.get("time", 0)):
                    continue
                effect["time"] = hit["time"]
                for pull in _effects:
                    if pull.get("kind") == "pull" and pull.get("target_id") == unit_id and pull.get("unit_id") == hit.get("source_unit_id"):
                        effect["x"] = pull["to_x"]
                        effect["y"] = pull["to_y"]
                        effect["unit"] = pull.get("target_unit", source).duplicate()
        _effects.append(effect)
        if _effects.size() > 240:
            _effects.pop_front()

func _point(x: float, y: float) -> Vector2:
    return (_arena.position + Vector2(x / _field_width * _arena.size.x, y / _field_height * _arena.size.y)).round()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("22291f"))
    var height := maxf(1.0, size.y - 8.0)
    var width := height * _field_width / _field_height
    if width > size.x - 8.0:
        width = size.x - 8.0
        height = width * _field_height / _field_width
    _arena = Rect2((size - Vector2(width, height)) * 0.5, Vector2(width, height))
    _draw_ground()
    _draw_frost()
    _draw_rosters()
    var next_units := {}
    for unit in _next_frame.get("units", []):
        next_units[str(unit.get("id", ""))] = unit
    var held := held_defeats()
    var originals: Array = _frame.get("units", []).duplicate()
    var ids := {}
    for unit in originals:
        ids[str(unit.get("id", ""))] = true
    for id in held:
        if not ids.has(id):
            originals.append(held[id])
            ids[id] = true
    if replay_enabled:
        for birth in replay.births_since(float(_frame.get("time", 0)), _visual_time):
            if not ids.has(str(birth["id"])):
                originals.append(birth)
                ids[str(birth["id"])] = true
    var units: Array = []
    for original in originals:
        var unit: Dictionary = original.duplicate()
        var id_value := str(unit.get("id", ""))
        var next: Dictionary = next_units.get(id_value, original)
        var direction := Vector2(float(next.get("x", 0)) - float(original.get("x", 0)), float(next.get("y", 0)) - float(original.get("y", 0)))
        var unit_blend := _blend
        var born_at := float(original.get("spawned_at", 0))
        if born_at > float(_frame.get("time", 0)):
            unit_blend = clampf((_visual_time - born_at) / maxf(0.001, float(_next_frame.get("time", born_at)) - born_at), 0, 1)
        unit["x"] = lerpf(float(original.get("x", 0)), float(next.get("x", 0)), unit_blend)
        unit["y"] = lerpf(float(original.get("y", 0)), float(next.get("y", 0)), unit_blend)
        if replay_enabled:
            unit["hp"] = replay.health_at(id_value, _visual_time, float(unit.get("hp", 0)))
            unit["absorbed_damage"] = replay.absorbed_at(id_value, _visual_time, float(unit.get("absorbed_damage", 0)))
            if float(unit["hp"]) <= 0 and not held.has(id_value):
                continue
            var push := replay.pushback_at(id_value, _visual_time)
            if not push.is_empty():
                var progress := 1.0 if reduced_motion else clampf((_visual_time - float(push["time"])) / 0.22, 0, 1)
                var start := Vector2(float(push["from_x"]), float(push["from_y"]))
                var end := Vector2(float(push["to_x"]), float(push["to_y"]))
                var point := start.lerp(end, 1 - pow(1 - progress, 3))
                unit["x"] = point.x
                unit["y"] = point.y
            else:
                var pending := replay.pending_pushback(id_value, _visual_time, float(_next_frame.get("time", 0)))
                if not pending.is_empty():
                    # Coarse snapshots include the jump: do not anticipate it before impact.
                    var progress := clampf((_visual_time - float(_frame.get("time", 0))) / maxf(0.001, float(pending["time"]) - float(_frame.get("time", 0))), 0, 1)
                    unit["x"] = lerpf(float(original.get("x", 0)), float(pending["from_x"]), progress)
                    unit["y"] = lerpf(float(original.get("y", 0)), float(pending["from_y"]), progress)
        var pull := BattleEffects.pull_chain(_effects, id_value, _visual_time)
        if not pull.is_empty():
            var age := _visual_time - float(pull.get("time", 0))
            var point := BattleEffects.pull_position(pull, age, Vector2(float(unit["x"]), float(unit["y"])))
            unit["x"] = point.x
            unit["y"] = point.y
            unit["_pull_visual"] = true
            if age < 0.54:
                unit["hp"] = pull.get("from_hp", unit.get("hp", 0))
        var pose: Dictionary = _poses.get(id_value, {"facing": 4 if unit.get("side") == "opponent" else 0})
        pose["rig"] = CombatCues.profile(str(unit.get("card_id", ""))).get("rig", "claw")
        pose["cycle"] = _visual_time * 8 + float(unit.get("y", 0))
        pose["birth_progress"] = clampf((_visual_time - born_at) / 0.35, 0, 1) if born_at > 0 and not reduced_motion else 1.0
        pose["state"] = "move" if direction.length() > 0.01 else "idle"
        if direction.length() > 0.01:
            pose["facing"] = posmod(int(round(direction.angle() / (PI / 4.0))), 8)
        pose["step"] = int(_visual_time * 8.0)
        if float(pose.get("attack_until", 0)) > _visual_time and _visual_time >= float(pose.get("attack_started", 0)):
            pose["state"] = "attack"
            pose["facing"] = int(pose.get("attack_facing", 0))
        if replay_enabled:
            var attack := replay.attack_at(id_value, _visual_time)
            if not attack.is_empty():
                pose.merge(UnitAttackMotion.pose(attack, _visual_time), true)
        if bool(unit.get("_pull_visual", false)):
            pose["state"] = "idle"
        _poses[id_value] = pose
        _known[id_value] = unit
        units.append(unit)
        _draw_aura(unit)
    var areas: Array = _frame.get("areas", []).filter(func(area): return not replay_enabled or area.get("type") != "damage_area")
    if replay_enabled:
        areas.append_array(replay.death_areas_at(_visual_time))
    for area in areas:
        var center := _point(float(area.get("x", 0)), float(area.get("y", 0)))
        var radius := float(area.get("radius", 1)) / _field_width * _arena.size.x
        if area.get("type") == "damage_area":
            BattleEffects.slime_pool(self, center, radius, float(area.get("remaining", 0)), float(area.get("duration", 10)), _visual_time, reduced_motion)
        else:
            draw_circle(center, radius, Color(0.35, 0.8, 0.71, 0.16))
            draw_arc(center, radius, 0, TAU, 16, Color("8bc7c0"), 1)
    units.sort_custom(func(a, b): return float(a.get("y", 0)) < float(b.get("y", 0)))
    for unit in units:
        _draw_unit(unit)
    _draw_royal_opening()
    for effect in _effects:
        var age := _visual_time - float(effect.get("time", 0))
        if effect.get("type") == "defeat" and age >= 0 and age < 0.5:
            var corpse: Dictionary = effect.get("unit", {}).duplicate()
            corpse["x"] = effect.get("x", corpse.get("x", 0))
            corpse["y"] = effect.get("y", corpse.get("y", 0))
            _known[str(effect.get("unit_id", ""))] = corpse
            _poses[str(effect.get("unit_id", ""))] = {"state": "death"}
    _draw_projectiles()
    _draw_effects()

func held_defeats() -> Dictionary:
    var result := {}
    for effect in _effects:
        if effect.get("type") != "defeat" or float(effect.get("time", 0)) <= _visual_time:
            continue
        var unit: Dictionary = effect.get("unit", {}).duplicate()
        unit["x"] = effect.get("x", unit.get("x", 0))
        unit["y"] = effect.get("y", unit.get("y", 0))
        result[str(effect.get("unit_id", ""))] = unit
    return result

func _draw_frost() -> void:
    var coverage := frost_coverage()
    if coverage <= 0:
        return
    # The scenery covers BOTH halves; the rules still debuff only enemies of
    # the Commander who cast it. This layer persists until the scene is freed.
    var field := Rect2(_arena.position, Vector2(_arena.size.x * coverage, _arena.size.y))
    draw_rect(field, Color(0.57, 0.82, 0.91, 0.34))
    draw_rect(field, Color(0.7, 0.94, 0.98, 0.7), false, 3)
    for index in range(56):
        var p := _arena.position + Vector2(12 + (index * 83) % maxi(1, int(_arena.size.x - 24)), 50 + (index * 61) % maxi(1, int(_arena.size.y - 62)))
        if p.x > field.end.x - 8:
            continue
        var radius := 3.0 + float(index % 3)
        for axis in range(3):
            var ray := Vector2.from_angle(float(axis) * PI / 3) * radius
            draw_line((p - ray).round(), (p + ray).round(), Color(0.78, 0.96, 1.0, 0.6), 1)
        if index % 3 == 0:
            var crack := PackedVector2Array([p + Vector2(-12, 7), p + Vector2(-4, 3), p + Vector2(1, 7), p + Vector2(11, -2)])
            draw_polyline(crack, Color(0.76, 0.93, 0.97, 0.3), 1)

func _draw_ground() -> void:
    # Only the tree-free central clearing is playable. Decorative tree canopies
    # are outside this UV window, including the actor height above its feet.
    # The unchanged world-to-screen arena still owns all
    # positions, frost coverage, projectile contacts and formation coordinates.
    var rim := ScreenStyle.frame(Color("263121"), Color("8a754b"), 12)
    rim.set_content_margin_all(0)
    rim.ornaments = false
    draw_style_box(rim, _arena.grow(3))
    var points := PackedVector2Array()
    var uv := PackedVector2Array()
    var radius := minf(10, _arena.size.y * 0.06)
    var corners := [
        [_arena.position + Vector2(radius, radius), PI],
        [Vector2(_arena.end.x - radius, _arena.position.y + radius), PI * 1.5],
        [_arena.end - Vector2(radius, radius), 0.0],
        [Vector2(_arena.position.x + radius, _arena.end.y - radius), PI * 0.5]
    ]
    for corner in corners:
        for index in range(5):
            var angle := float(corner[1]) + PI * 0.5 * float(index) / 4.0
            var point: Vector2 = corner[0] + Vector2.from_angle(angle) * radius
            points.append(point)
            uv.append(Vector2(0.21, 0.23) + (point - _arena.position) / _arena.size * Vector2(0.58, 0.42))
    draw_polygon(points, PackedColorArray([Color(0.89, 0.94, 0.88, 1)]), uv, GROUND)

func roster_layout(card_count: int) -> Dictionary:
    var compact := size.y < 330
    var spacing := minf(40, (size.y - 100) / maxf(1, card_count)) if compact else 48.0
    return {"compact": compact, "first_y": 54.0 if compact else 77.0,
        "spacing": spacing, "icon_size": minf(24, spacing - 2) if compact else 30.0}

func _draw_rosters() -> void:
    if _arena.position.x < 160 or _sides.size() != 2:
        return
    for index in range(2):
        var x := _arena.end.x + 20 if index == 1 else 16.0
        var color := Color("e8a48c") if index == 1 else Color("9dd9cc")
        var panel_x := _arena.end.x + 10 if index == 1 else 6.0
        var panel_width := minf(_arena.position.x - 18, size.x - panel_x - 6)
        var panel := ScreenStyle.frame(Color("302e24"), Color("706342"), 12)
        panel.set_content_margin_all(0)
        panel.ornaments = false
        draw_style_box(panel, Rect2(panel_x, 6, panel_width, maxf(1, size.y - 12)))
        var config: Dictionary = _sides[index]
        var layout := roster_layout(config.get("cards", []).size())
        var compact: bool = layout["compact"]
        draw_string(ThemeDB.fallback_font, Vector2(x, 26 if compact else 34), "RIVAL WARBAND" if index == 1 else "YOUR WARBAND", HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 24, 14, color)
        var y := float(layout["first_y"])
        for card in config.get("cards", []):
            var id_value := str(card.get("id", ""))
            var count := int(config.get("unit_counts", {}).get(id_value, 0))
            var icon_size := float(layout["icon_size"])
            draw_texture_rect(UnitArt.icon(id_value, str(card.get("role", "range")), str(card.get("element", "earth"))), Rect2(Vector2(x, y - icon_size + 3), Vector2.ONE * icon_size), false)
            if compact:
                draw_string(ThemeDB.fallback_font, Vector2(x + 30, y - 4), "%s ×%d" % [str(card.get("display_name", "Unit")), count], HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 60, 12, Color("eee2c3"))
            else:
                draw_string(ThemeDB.fallback_font, Vector2(x + 34, y - 10), str(card.get("display_name", "Unit")), HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 60, 12, Color("eee2c3"))
                draw_string(ThemeDB.fallback_font, Vector2(x + 34, y + 8), "Recruited: %d" % count, HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 60, 11, Color("a8b9a5"))
            y += float(layout["spacing"])
        var bonus: Dictionary = config.get("set_bonus", {})
        var bonus_text := "Theme inactive" if bonus.is_empty() else ScreenStyle.bonus_description(bonus, true)
        draw_string(ThemeDB.fallback_font, Vector2(x, y + 8), bonus_text, HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 24, 13, color)
        var skill: Dictionary = config.get("commander", {}).get("active_skill", {})
        if bool(config.get("commander_skill_active", false)) and skill.get("type") == "summon_stationary_units":
            var count := 0
            for unit in _frame.get("units", []):
                if bool(unit.get("summoned", false)) and unit.get("side") == config.get("id"):
                    count += 1
            draw_string(ThemeDB.fallback_font, Vector2(x, y + 32), ("Rival summons: " if index == 1 else "Allied summons: ") + str(count), HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 24, 13, color)

func _draw_aura(unit: Dictionary) -> void:
    var radius := float(unit.get("aura_radius", 0)) / _field_width * _arena.size.x
    if radius <= 0:
        return
    var color := Color("dc9958")
    if unit.get("ability_type") == "aura_heal":
        color = Color("a9cc70")
    elif unit.get("ability_type") == "aura_debuff":
        color = Color("86d1e0")
    color.a = 0.24
    draw_arc(_point(float(unit["x"]), float(unit["y"])), radius, 0, TAU, 16, color, 1)

func _draw_unit(unit: Dictionary) -> void:
    var p := _point(float(unit.get("x", 0)), float(unit.get("y", 0)))
    var id_value := str(unit.get("id", ""))
    var side := str(unit.get("side", "player"))
    var pose: Dictionary = _poses.get(id_value, {})
    var pixel := (2.0 if _arena.size.y >= 300 else 1.0) * float(unit.get("visual_scale", 1))
    var bob := 0.0 if reduced_motion else floorf(sin(_visual_time * 4.0 + float(unit.get("y", 0))) + 1.0)
    pose["hit"] = false
    if not reduced_motion:
        for effect in _effects:
            if effect["type"] == "damage" and effect["unit_id"] == id_value and _visual_time >= float(effect["time"]) and _visual_time - float(effect["time"]) < 0.12:
                pose["hit"] = true
    var shadow := PackedVector2Array([p + Vector2(-16, -1), p + Vector2(-11, -5), p + Vector2(10, -5), p + Vector2(16, -1), p + Vector2(11, 3), p + Vector2(-11, 3)])
    draw_colored_polygon(shadow, Color(0.08, 0.13, 0.10, 0.55))
    draw_rect(Rect2(p + Vector2(-10, 3), Vector2(20, 2)), Color("e8a087") if side == "opponent" else Color("8bd9ce"))
    var sprite_position := _sprite_position(unit, pose)
    if reduced_motion and pose.has("rig"):
        pose = pose.duplicate()
        pose["charge"] = float(pose.get("charge", 0)) * 0.2
        pose["power"] = float(pose.get("power", 0)) * 0.2
    UnitArt.draw_unit(self, sprite_position, str(unit.get("role", "range")), str(unit.get("element", "earth")), pixel, side == "opponent", bob, str(unit.get("card_id", "")), pose)
    if pose.get("state") == "attack" and pose.has("rig"):
        UnitAttackMotion.draw_action(self, _body_point(unit), pose, str(unit.get("element", "earth")), reduced_motion)
    var ratio := clampf(float(unit.get("hp", 0)) / maxf(1.0, float(unit.get("max_hp", 1))), 0.0, 1.0)
    var bar := p + Vector2(-14, -22 * pixel - 4)
    if bool(unit.get("summoned", false)):
        var team := Color("eda086") if side == "opponent" else Color("8bd9ce")
        draw_arc(p, 15, 0, TAU, 8, team, 2)
        draw_line(p + Vector2(17, 0), p + Vector2(17, -13), Color("27382f"), 2)
        draw_colored_polygon(PackedVector2Array([p + Vector2(17, -13), p + Vector2(26, -10), p + Vector2(17, -6)]), team)
    draw_rect(Rect2(bar - Vector2.ONE, Vector2(30, 6)), Color("292b38"))
    draw_rect(Rect2(bar, Vector2(floorf(28 * ratio), 4)), Color("91d7a0") if side == "player" else Color("edaa8c"))
    if unit.get("ability_type") == "absorb_burst":
        var stored := float(unit.get("absorbed_damage", 0))
        var charge := clampf(stored / maxf(1, float(unit.get("max_hp", 1))), 0, 1)
        draw_rect(Rect2(bar + Vector2(0, 6), Vector2(28, 3)), Color("344954"))
        draw_rect(Rect2(bar + Vector2(0, 6), Vector2(ceilf(28 * charge), 3)), Color("effaff"))
        if stored > 0:
            var interval := maxf(0.1, float(unit.get("burst_seconds", 10)))
            var progress := fposmod(_visual_time - float(unit.get("spawned_at", 0)), interval) / interval
            draw_arc(p + Vector2(0, -1), 19, -PI / 2, -PI / 2 + TAU * progress, 20, Color(0.86, 0.96, 1, 0.7), 2)
            var glow := 0.65 if reduced_motion else 0.65 + sin(_visual_time * (4 + progress * 8)) * 0.15
            draw_arc(_body_point(unit), 15, PI, TAU, 8, Color(0.88, 0.98, 1, glow), 2)
    if bool(unit.get("burning", false)):
        draw_rect(Rect2(bar + Vector2(29, -1), Vector2(3, 6)), Color("ffb966"))
    if frozen_sides.has(side) and frost_coverage() >= 1.0:
        draw_arc(p, 14, 0, TAU, 8, Color(0.7, 0.93, 0.98, 0.7), 1)
        draw_rect(Rect2(bar + Vector2(-5, 0), Vector2(3, 4)), Color("bdeff3"))
    if bool(unit.get("slowed", false)):
        draw_arc(p, 11, 0, TAU, 8, Color("9de47f"), 2)
        draw_rect(Rect2(bar + Vector2(33, 0), Vector2(3, 4)), Color("a9e383"))
    if bool(unit.get("revival_ready", false)):
        var crown := bar + Vector2(31, -5)
        draw_rect(Rect2(crown, Vector2(9, 3)), Color("f5c77d"))
        for tip in [0, 4, 8]:
            draw_rect(Rect2(crown + Vector2(tip, -3), Vector2(2, 4)), Color("f2a1c6"))
    if show_hp_numbers:
        draw_string(ThemeDB.fallback_font, bar + Vector2(-4, -3), "%d/%d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 1))], HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color("fff3d5"))

func _sprite_position(unit: Dictionary, pose: Dictionary) -> Vector2:
    var sprite_position := _point(float(unit.get("x", 0)), float(unit.get("y", 0)))
    if not reduced_motion and pose.get("state") == "attack" and pose.has("rig"):
        sprite_position += UnitAttackMotion.displacement(pose) * float(unit.get("visual_scale", 1))
    elif not reduced_motion and pose.get("state") == "attack":
        var progress := clampf((_visual_time - float(pose.get("attack_started", 0))) / maxf(0.01, float(pose.get("attack_duration", 0.32))), 0, 1)
        var direction := Vector2.from_angle(float(pose.get("facing", 0)) * PI / 4.0)
        var motion := str(pose.get("motion", "slash"))
        var weight := 5.0 if motion in ["slam", "slash", "bite"] else 2.0
        var lunge := -2.0 * sin(progress * PI / 0.2) if progress < 0.2 else sin((progress - 0.2) / 0.8 * PI) * weight
        sprite_position += (direction * lunge).round()
        if motion == "slam":
            sprite_position.y += roundf(sin(progress * PI) * 3.0)
    if not reduced_motion:
        for effect in _effects:
            if effect.get("type") != "damage" or effect.get("target_id") != unit.get("id"):
                continue
            var age := _visual_time - float(effect.get("time", 0))
            if age < 0 or age >= 0.24:
                continue
            var source: Dictionary = _known.get(str(effect.get("source_unit_id", "")), {})
            var away := Vector2(float(unit.get("x", 0)) - float(source.get("x", unit.get("x", 0))), float(unit.get("y", 0)) - float(source.get("y", unit.get("y", 0)))).normalized()
            sprite_position += (away * sin(age / 0.24 * PI) * 5).round()
            break
    return sprite_position

func _body_point(unit: Dictionary) -> Vector2:
    var pixel := (2.0 if _arena.size.y >= 300 else 1.0) * float(unit.get("visual_scale", 1))
    var bob := 0.0 if reduced_motion else floorf(sin(_visual_time * 4.0 + float(unit.get("y", 0))) + 1.0)
    return _sprite_position(unit, _poses.get(str(unit.get("id", "")), {})) - Vector2(0, pixel * 11 + bob)

func _draw_royal_opening() -> void:
    for skill in prelude_skills:
        if skill.get("skill_type") != "army_revival":
            continue
        var progress := clampf((prelude_time - 0.2) / 1.6, 0, 1)
        var fade := minf(progress * 3, clampf((BattlePrelude.DURATION - prelude_time) / 0.6, 0, 1))
        for unit in _frame.get("units", []):
            if unit.get("side") != skill.get("side"):
                continue
            var p := _point(float(unit["x"]), float(unit["y"]))
            draw_arc(p, 15 + progress * 8, 0, TAU, 12, Color(1, 0.64, 0.83, fade * 0.8), 2)
            for index in range(3):
                var height: float = 12 + (0 if reduced_motion else fmod(prelude_time * 30 + index * 13, 52))
                draw_arc((p + Vector2(index * 10 - 10, -height)).round(), 3 + index, 0, TAU, 8, Color(1, 0.75, 0.88, fade), 2)

func _draw_projectiles() -> void:
    if not replay_enabled or replay_complete:
        return
    for projectile in replay.projectiles_at(_visual_time):
        var point: Vector2 = projectile["position"]
        var pixel := 2.0 if _arena.size.y >= 300 else 1.0
        var p := _point(point.x, point.y) - Vector2(0, pixel * 11)
        var terminal: Dictionary = projectile.get("terminal", {})
        var target: Dictionary = _known.get(str(terminal.get("target_id", projectile.get("target_id", ""))), {})
        if not target.is_empty() and terminal.get("type") == "projectile_impact":
            var destination := _point(float(terminal["x"]), float(terminal["y"])) - Vector2(0, pixel * 11)
            p += (_body_point(target) - destination) * float(projectile["contact_blend"])
        var profile := CombatCues.profile(str(projectile.get("card_id", "")))
        var direction: Vector2 = projectile["direction"]
        var style := str(profile.get("projectile", "magic"))
        # The arrow tip, rather than its shaft center, reaches the body anchor.
        if style == "arrow":
            p -= direction * 5
        elif style == "ice_shard":
            p -= direction * 8
        if style == "seed":
            var team := Color("eda086") if projectile.get("source_side") == "opponent" else Color("8bd9ce")
            draw_line((p - direction * 12).round(), (p - direction * 18).round(), team, 2)
        BattleEffects.projectile(self, p.round(), direction, style, _visual_time, reduced_motion)

func _draw_effects() -> void:
    for effect in _effects:
        var age := _visual_time - float(effect.get("time", 0))
        if age < 0:
            continue
        var type := str(effect.get("type", ""))
        var p := _point(float(effect.get("x", 0)), float(effect.get("y", 0)))
        if effect.get("kind") == "pull":
            var origin: Dictionary = _known.get(str(effect.get("unit_id", "")), {})
            var source := _point(float(origin.get("x", effect.get("source_x", 0))), float(origin.get("y", effect.get("source_y", 0)))) + Vector2(0, -20)
            var target: Dictionary = _known.get(str(effect.get("target_id", "")), {})
            var current := _point(float(target.get("x", effect.get("to_x", 0))), float(target.get("y", effect.get("to_y", 0)))) + Vector2(0, -20)
            BattleEffects.vine(self, source, current, age, reduced_motion)
        elif type == "projectile_impact":
            var target: Dictionary = _known.get(str(effect.get("target_id", "")), {})
            var contact := _body_point(target) if not target.is_empty() else p + Vector2(0, -22)
            BattleEffects.impact(self, contact, str(effect.get("style", "magic")), age, reduced_motion)
        elif type == "summon" and age < 0.8:
            for index in range(5):
                var offset := Vector2.from_angle(float(index) * TAU / 5.0) * 13
                var height := 7.0 if reduced_motion else 5 + sin(clampf(age / 0.8, 0, 1) * PI) * 18
                draw_line((p + offset).round(), (p + offset - Vector2(0, height)).round(), Color("a4c974"), 3)
            draw_arc(p, 16, 0, TAU, 12, Color(0.8, 0.86, 0.47, 1.0 - age), 2)
        elif type in ["rebirth", "split_birth"] and age < 0.7:
            var color := BattleEffects.slime_color("slime_pink" if type == "rebirth" else "slime_green")
            color.a = 1 - age / 0.7
            draw_arc(p, 12 + (0 if reduced_motion else age * 34), 0, TAU, 12, color, 2)
            for index in range(5):
                var offset := Vector2.from_angle(float(index) * TAU / 5) * 15
                var rise := 8.0 if reduced_motion else sin(age / 0.7 * PI) * 26
                draw_circle((p + offset - Vector2(0, rise)).round(), 3, color)
        elif type in ["damage", "heal"]:
            if age > 0.7:
                continue
            var color := Color("a6e6ba") if type == "heal" else Color("ffe1a1")
            color.a = 1.0 - age / 0.7
            if not show_hp_numbers:
                if age < 0.2:
                    draw_rect(Rect2(p + Vector2(9, -18), Vector2(5, 2)), color)
                    draw_rect(Rect2(p + Vector2(10, -20), Vector2(2, 6)), color)
                continue
            draw_string(ThemeDB.fallback_font, p + Vector2(-8, -48 - (0.0 if reduced_motion else age * 24)), ("+" if type == "heal" else "") + str(int(effect.get("amount", 0))), HORIZONTAL_ALIGNMENT_CENTER, 40, 12, color)
        elif type == "defeat" and age < 0.5:
            var unit: Dictionary = effect.get("unit", {})
            var pose := {"state": "death", "alpha": 1.0 - age * 2.0}
            UnitArt.draw_unit(self, p, str(unit.get("role", "range")), str(unit.get("element", "earth")), 2.0 * float(unit.get("visual_scale", 1)), false, 0.0, str(unit.get("card_id", "")), pose)
        elif type == "attack" and effect.get("kind") == "melee" and age < 0.2:
            var unit: Dictionary = _known.get(str(effect.get("target_id", "")), {})
            var target := _body_point(unit) if not unit.is_empty() else _point(float(effect.get("target_x", 0)), float(effect.get("target_y", 0))) - Vector2(0, 22)
            BattleEffects.impact(self, target, str(effect.get("style", "slash")), age, reduced_motion)
        elif type == "ability" and effect.get("kind") == "meteor" and age < 1.0:
            var strike_age := age
            if strike_age < 0:
                continue
            var fall := clampf(strike_age / 0.35, 0, 1)
            var meteor := p if reduced_motion else p + Vector2(-50, -100) * (1.0 - fall)
            if fall < 1.0 and not reduced_motion:
                BattleEffects.projectile(self, meteor.round(), Vector2(0.5, 1).normalized(), "dragonfire", _visual_time, reduced_motion)
                draw_rect(Rect2(meteor.round() - Vector2(3, 3), Vector2(6, 6)), Color("8f563e"))
            else:
                BattleEffects.impact(self, p, "fireball", strike_age - 0.35, reduced_motion)
                draw_arc(p, 18 if reduced_motion else 12 + (strike_age - 0.35) * 60, 0, TAU, 12, Color(1.0, 0.65, 0.3, 1.0 - age), 3)
        elif type == "ability" and effect.get("kind") == "on_death":
            BattleEffects.impact(self, p + Vector2(0, -16), "dragonfire", age, reduced_motion)
        elif type == "ability" and effect.get("kind") == "absorb_burst":
            var radius := float(effect.get("radius", 2.5)) / _field_width * _arena.size.x
            BattleEffects.absorbed_burst(self, p, radius, age, bool(effect.get("on_death", false)), reduced_motion)
        elif type == "ability" and effect.get("kind") in ["death_area", "slow_splash"]:
            var style := "slime_pink" if effect.get("kind") == "death_area" else "slime_green"
            BattleEffects.impact(self, p + Vector2(0, -12), style, age, reduced_motion)
            if age < 0.45:
                var radius := float(effect.get("radius", 1)) / _field_width * _arena.size.x
                var color := BattleEffects.slime_color(style)
                color.a = 1 - age / 0.45
                draw_arc(p, radius * clampf(age / 0.25, 0, 1), 0, TAU, 16, color, 2)
        elif type == "ability" and age < 0.5:
            var color := Color(str(UnitArt.palette(str(effect.get("element", "earth"))).get("l", "ffffff")))
            color.a = (1.0 - age * 2.0) * 0.6
            draw_arc(p, 16.0 if reduced_motion else 12.0 + age * 40, 0, TAU, 12, color, 2)
        elif type == "commander_skill" and age < 1.0 and prelude_skills.is_empty() and effect.get("skill_type") == "round_debuff":
            draw_rect(_arena, Color(0.45, 0.8, 0.95, (1.0 - age) * 0.12))
