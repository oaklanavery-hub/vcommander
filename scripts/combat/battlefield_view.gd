class_name BattlefieldView
extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
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
var _impacts: Dictionary = {}

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
        var info: Dictionary = _known.get(unit_id, {}).duplicate()
        info.merge({"id": unit_id, "x": info.get("x", event.get("x", 0)), "y": info.get("y", event.get("y", 0)), "side": event.get("side", "player"), "role": event.get("role", "range"), "card_id": pieces[1] if pieces.size() > 1 else ""}, true)
        _known[unit_id] = info
        if event.get("source") == "commander_skill":
            var sprout := event.duplicate(true)
            sprout["type"] = "summon"
            _effects.append(sprout)
        return
    if _visual_time - float(event.get("time", 0)) > 1.2:
        return
    var source: Dictionary = _known.get(unit_id, {})
    var target: Dictionary = _known.get(target_id, {})
    if type == "attack":
        var pose: Dictionary = _poses.get(unit_id, {})
        var direction := Vector2(float(event.get("target_x", target.get("x", 0))) - float(event.get("x", source.get("x", 0))), float(event.get("target_y", target.get("y", 0))) - float(event.get("y", source.get("y", 0))))
        var motion := str(CombatCues.event_profile(event).get("motion", "slash"))
        pose["attack_started"] = float(event.get("time", 0))
        for effect in _effects:
            if effect.get("kind") == "pull" and effect.get("target_id") == target_id and float(event.get("time", 0)) - float(effect.get("time", 0)) < 0.15:
                pose["attack_started"] = float(effect.get("time", 0)) + 0.25
        pose["attack_duration"] = 0.42 if motion == "slam" else 0.32
        pose["attack_until"] = float(pose["attack_started"]) + float(pose["attack_duration"])
        pose["motion"] = motion
        pose["attack_facing"] = posmod(int(round(direction.angle() / (PI / 2.0))) * 2, 8)
        _poses[unit_id] = pose
    if type == "projectile_impact":
        _impacts[int(event.get("projectile_id", 0))] = float(event.get("time", 0))
    if type in ["damage", "heal", "defeat", "ability", "commander_skill", "attack", "projectile_impact"]:
        var at: Dictionary = target if type in ["damage", "heal"] or event.get("kind") == "meteor" else source
        var effect := event.duplicate(true)
        var profile := CombatCues.event_profile(event)
        effect.merge({"x": event.get("x", at.get("x", 0)), "y": event.get("y", at.get("y", 0)), "unit": at.duplicate(), "unit_id": target_id if type in ["damage", "heal"] else unit_id, "element": event.get("element", source.get("element", "earth")), "style": profile.get("projectile" if type == "projectile_impact" else "motion", "slash")}, true)
        if type == "attack":
            effect["time"] = _poses.get(unit_id, {}).get("attack_started", event.get("time", 0))
        _effects.append(effect)
        if _effects.size() > 240:
            _effects.pop_front()

func _point(x: float, y: float) -> Vector2:
    return (_arena.position + Vector2(x / _field_width * _arena.size.x, y / _field_height * _arena.size.y)).round()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("172d28"))
    var height := maxf(1.0, size.y - 8.0)
    var width := height * _field_width / _field_height
    if width > size.x - 8.0:
        width = size.x - 8.0
        height = width * _field_height / _field_width
    _arena = Rect2((size - Vector2(width, height)) * 0.5, Vector2(width, height))
    _draw_ground()
    _draw_rosters()
    var next_units := {}
    for unit in _next_frame.get("units", []):
        next_units[str(unit.get("id", ""))] = unit
    var units: Array = []
    for original in _frame.get("units", []):
        var unit: Dictionary = original.duplicate()
        var id_value := str(unit.get("id", ""))
        var next: Dictionary = next_units.get(id_value, original)
        var direction := Vector2(float(next.get("x", 0)) - float(original.get("x", 0)), float(next.get("y", 0)) - float(original.get("y", 0)))
        unit["x"] = lerpf(float(original.get("x", 0)), float(next.get("x", 0)), _blend)
        unit["y"] = lerpf(float(original.get("y", 0)), float(next.get("y", 0)), _blend)
        var pull := BattleEffects.pull_chain(_effects, id_value, _visual_time)
        if not pull.is_empty():
            var age := _visual_time - float(pull.get("time", 0))
            var point := BattleEffects.pull_position(pull, age, Vector2(float(unit["x"]), float(unit["y"])))
            unit["x"] = point.x
            unit["y"] = point.y
            unit["_pull_visual"] = true
            if age < 0.45:
                unit["hp"] = pull.get("from_hp", unit.get("hp", 0))
        var pose: Dictionary = _poses.get(id_value, {"facing": 4 if unit.get("side") == "opponent" else 0})
        pose["state"] = "move" if direction.length() > 0.01 else "idle"
        if direction.length() > 0.01:
            pose["facing"] = posmod(int(round(direction.angle() / (PI / 4.0))), 8)
        pose["step"] = int(_visual_time * 8.0)
        if float(pose.get("attack_until", 0)) > _visual_time and _visual_time >= float(pose.get("attack_started", 0)):
            pose["state"] = "attack"
            pose["facing"] = int(pose.get("attack_facing", 0))
        if bool(unit.get("_pull_visual", false)):
            pose["state"] = "idle"
        _poses[id_value] = pose
        _known[id_value] = unit
        units.append(unit)
        _draw_aura(unit)
    for area in _frame.get("areas", []):
        var center := _point(float(area.get("x", 0)), float(area.get("y", 0)))
        var radius := float(area.get("radius", 1)) / _field_width * _arena.size.x
        draw_circle(center, radius, Color(0.35, 0.8, 0.71, 0.16))
        draw_arc(center, radius, 0, TAU, 16, Color("8bc7c0"), 1)
    units.sort_custom(func(a, b): return float(a.get("y", 0)) < float(b.get("y", 0)))
    for unit in units:
        _draw_unit(unit)
    _draw_projectiles()
    _draw_effects()
    _draw_prelude()

func _draw_prelude() -> void:
    if prelude_skills.is_empty():
        return
    var names: Array[String] = []
    for skill in prelude_skills:
        names.append(("You: " if skill.get("side") == "player" else "Rival: ") + str(skill.get("name", "Commander skill")))
        if skill.get("skill_type") == "round_debuff":
            var right: bool = skill.get("side") == "player"
            var region := Rect2(_arena.position + Vector2(_arena.size.x * 0.5 if right else 0.0, 0), Vector2(_arena.size.x * 0.5, _arena.size.y))
            var progress := clampf((prelude_time - 0.3) / 1.3, 0, 1)
            draw_rect(Rect2(region.position, Vector2(region.size.x * progress, region.size.y)), Color(0.5, 0.8, 0.95, 0.18))
            for index in range(14):
                var p := region.position + Vector2(18 + (index * 43) % maxi(1, int(region.size.x - 36)), 80 + (index * 71) % maxi(1, int(region.size.y - 100)))
                var radius := 5.0 * progress
                for axis in range(3):
                    var ray := Vector2.from_angle(float(axis) * PI / 3.0) * radius
                    draw_line((p - ray).round(), (p + ray).round(), Color("c5f2f5"), 2)
    var banner := Rect2(_arena.position + Vector2(12, 12), Vector2(_arena.size.x - 24, 48))
    draw_style_box(ScreenStyle.frame(Color(0.07, 0.15, 0.13, 0.96), Color("d9bf7f"), 8), banner)
    draw_string(ThemeDB.fallback_font, banner.position + Vector2(10, 30), "   •   ".join(names), HORIZONTAL_ALIGNMENT_CENTER, banner.size.x - 20, 18, Color("f5dda3"))

func _draw_ground() -> void:
    draw_rect(_arena.grow(4), Color("b4a272"))
    draw_rect(_arena, Color("42664c"))
    for y in range(0, int(_arena.size.y), 16):
        for x in range(0, int(_arena.size.x), 16):
            var pattern := (x * 17 + y * 31) % 97
            var tile := Rect2(_arena.position + Vector2(x, y), Vector2(minf(16, _arena.size.x - x), minf(16, _arena.size.y - y)))
            draw_rect(tile, Color("3e6048") if pattern < 42 else Color("42674b"))
            if pattern < 10:
                draw_rect(Rect2(tile.position + Vector2(4, 7), Vector2(2, 4)), Color("7d9b60"))
            if pattern == 16:
                draw_rect(Rect2(tile.position + Vector2(8, 8), Vector2(3, 3)), Color("edc888"))
    var path_y := _arena.get_center().y
    draw_rect(Rect2(Vector2(_arena.position.x, path_y - 24), Vector2(_arena.size.x, 48)), Color("817951"))
    for x in range(4, int(_arena.size.x - 16), 24):
        draw_rect(Rect2(Vector2(_arena.position.x + x, path_y - 10 + (x % 5) * 3), Vector2(12, 5)), Color("aaa06e"))
    for right in [false, true]:
        var flag := _arena.position + Vector2(_arena.size.x - 20 if right else 12, 12)
        draw_rect(Rect2(flag, Vector2(3, 35)), Color("302c3c"))
        draw_rect(Rect2(flag + Vector2(3, 0), Vector2(12, 16)), Color("d98c78") if right else Color("89d8ce"))

func _draw_rosters() -> void:
    if _arena.position.x < 160 or _sides.size() != 2:
        return
    for index in range(2):
        var x := _arena.end.x + 20 if index == 1 else 16.0
        var color := Color("e8a48c") if index == 1 else Color("9dd9cc")
        draw_string(ThemeDB.fallback_font, Vector2(x, 34), "RIVAL WARBAND" if index == 1 else "YOUR WARBAND", HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 24, 14, color)
        var y := 77.0
        var config: Dictionary = _sides[index]
        for card in config.get("cards", []):
            var id_value := str(card.get("id", ""))
            var count := int(config.get("unit_counts", {}).get(id_value, 0))
            draw_texture_rect(UnitArt.icon(id_value, str(card.get("role", "range")), str(card.get("element", "earth"))), Rect2(Vector2(x, y - 27), Vector2(30, 30)), false)
            draw_string(ThemeDB.fallback_font, Vector2(x + 34, y - 10), str(card.get("display_name", "Unit")), HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 60, 12, Color("eee2c3"))
            draw_string(ThemeDB.fallback_font, Vector2(x + 34, y + 8), "Recruited: %d" % count, HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 60, 11, Color("a8b9a5"))
            y += 48
        var bonus: Dictionary = config.get("set_bonus", {})
        var bonus_text := "Theme inactive" if bonus.is_empty() else "+%d%% %s" % [int(bonus.get("percentage", 0)), str(bonus.get("stat", "")).replace("_", " ")]
        draw_string(ThemeDB.fallback_font, Vector2(x, y + 8), bonus_text, HORIZONTAL_ALIGNMENT_LEFT, _arena.position.x - 24, 13, color)

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
    var pixel := 2.0 if _arena.size.y >= 300 else 1.0
    var bob := 0.0 if reduced_motion else floorf(sin(_visual_time * 4.0 + float(unit.get("y", 0))) + 1.0)
    pose["hit"] = false
    if not reduced_motion:
        for effect in _effects:
            if effect["type"] == "damage" and effect["unit_id"] == id_value and _visual_time - float(effect["time"]) < 0.12:
                pose["hit"] = true
    var shadow := PackedVector2Array([p + Vector2(-16, -1), p + Vector2(-11, -5), p + Vector2(10, -5), p + Vector2(16, -1), p + Vector2(11, 3), p + Vector2(-11, 3)])
    draw_colored_polygon(shadow, Color(0.08, 0.13, 0.10, 0.55))
    draw_rect(Rect2(p + Vector2(-10, 3), Vector2(20, 2)), Color("e8a087") if side == "opponent" else Color("8bd9ce"))
    var sprite_position := p
    if not reduced_motion and pose.get("state") == "attack":
        var progress := clampf((_visual_time - float(pose.get("attack_started", 0))) / maxf(0.01, float(pose.get("attack_duration", 0.32))), 0, 1)
        var direction := Vector2.from_angle(float(pose.get("facing", 0)) * PI / 4.0)
        var motion := str(pose.get("motion", "slash"))
        var weight := 5.0 if motion in ["slam", "slash", "bite"] else 2.0
        var lunge := -2.0 * sin(progress * PI / 0.2) if progress < 0.2 else sin((progress - 0.2) / 0.8 * PI) * weight
        sprite_position += (direction * lunge).round()
        if motion == "slam":
            sprite_position.y += roundf(sin(progress * PI) * 3.0)
    UnitArt.draw_unit(self, sprite_position, str(unit.get("role", "range")), str(unit.get("element", "earth")), pixel, side == "opponent", bob, str(unit.get("card_id", "")), pose)
    var ratio := clampf(float(unit.get("hp", 0)) / maxf(1.0, float(unit.get("max_hp", 1))), 0.0, 1.0)
    var bar := p + Vector2(-14, -22 * pixel - 4)
    draw_rect(Rect2(bar - Vector2.ONE, Vector2(30, 6)), Color("292b38"))
    draw_rect(Rect2(bar, Vector2(floorf(28 * ratio), 4)), Color("91d7a0") if side == "player" else Color("edaa8c"))
    if bool(unit.get("burning", false)):
        draw_rect(Rect2(bar + Vector2(29, -1), Vector2(3, 6)), Color("ffb966"))
    if show_hp_numbers:
        draw_string(ThemeDB.fallback_font, bar + Vector2(-4, -3), "%d/%d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 1))], HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color("fff3d5"))

func _draw_projectiles() -> void:
    var upcoming := {}
    for projectile in _next_frame.get("projectiles", []):
        upcoming[int(projectile.get("id", 0))] = projectile
    var visible: Array = _frame.get("projectiles", []).duplicate()
    var current_ids := {}
    for projectile in visible:
        current_ids[int(projectile.get("id", 0))] = true
    for projectile in upcoming.values():
        if not current_ids.has(int(projectile.get("id", 0))) and _visual_time >= float(projectile.get("launched_at", 0)):
            var birth: Dictionary = projectile.duplicate()
            birth["x"] = birth.get("start_x", birth.get("x", 0))
            birth["y"] = birth.get("start_y", birth.get("y", 0))
            birth["_birth"] = true
            visible.append(birth)
    for projectile in visible:
        var id := int(projectile.get("id", 0))
        if _impacts.has(id) and _visual_time >= float(_impacts[id]):
            continue
        var next: Dictionary = upcoming.get(id, projectile)
        var blend := _blend
        if bool(projectile.get("_birth", false)):
            var launched := float(projectile.get("launched_at", 0))
            blend = clampf((_visual_time - launched) / maxf(0.001, float(_next_frame.get("time", 0)) - launched), 0, 1)
        var point := Vector2(lerpf(float(projectile.get("x", 0)), float(next.get("x", 0)), blend), lerpf(float(projectile.get("y", 0)), float(next.get("y", 0)), blend))
        var p := _point(point.x, point.y) + Vector2(0, -22)
        var target: Dictionary = _known.get(str(projectile.get("target_id", "")), {})
        var destination := _point(float(target.get("x", point.x + 1)), float(target.get("y", point.y))) + Vector2(0, -22)
        var profile := CombatCues.profile(str(projectile.get("card_id", projectile.get("source_id", ""))))
        BattleEffects.projectile(self, p, (destination - p).normalized(), str(profile.get("projectile", "magic")), _visual_time, reduced_motion)

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
            BattleEffects.impact(self, p + Vector2(0, -22), str(effect.get("style", "magic")), age, reduced_motion)
        elif type == "summon" and age < 0.8:
            for index in range(5):
                var offset := Vector2.from_angle(float(index) * TAU / 5.0) * 13
                var height := 7.0 if reduced_motion else 5 + sin(clampf(age / 0.8, 0, 1) * PI) * 18
                draw_line((p + offset).round(), (p + offset - Vector2(0, height)).round(), Color("a4c974"), 3)
            draw_arc(p, 16, 0, TAU, 12, Color(0.8, 0.86, 0.47, 1.0 - age), 2)
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
            UnitArt.draw_unit(self, p + Vector2(0, 10), str(unit.get("role", "range")), str(unit.get("element", "earth")), 2.0, false, 0.0, str(unit.get("card_id", "")), pose)
        elif type == "attack" and effect.get("kind") == "melee" and age < 0.2:
            var target := _point(float(effect.get("target_x", effect.get("x", 0))), float(effect.get("target_y", effect.get("y", 0)))) + Vector2(0, -20)
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
        elif type == "ability" and age < 0.5:
            var color := Color(str(UnitArt.palette(str(effect.get("element", "earth"))).get("l", "ffffff")))
            color.a = (1.0 - age * 2.0) * 0.6
            draw_arc(p, 16.0 if reduced_motion else 12.0 + age * 40, 0, TAU, 12, color, 2)
        elif type == "commander_skill" and age < 1.0 and prelude_skills.is_empty():
            var color := Color(str(UnitArt.palette(str(effect.get("element", "earth"))).get("l", "e9d291")))
            if effect.get("skill_type") == "round_debuff":
                draw_rect(_arena, Color(0.45, 0.8, 0.95, (1.0 - age) * 0.12))
            color.a = 1.0 - age
            draw_string(ThemeDB.fallback_font, _arena.position + Vector2(12, 32), str(effect.get("name", "Commander skill")), HORIZONTAL_ALIGNMENT_CENTER, _arena.size.x - 24, 22, color)
