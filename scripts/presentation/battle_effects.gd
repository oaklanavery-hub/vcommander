class_name BattleEffects
extends RefCounted

static var intensity := 1.0

static func particle_count(normal: int) -> int:
    return maxi(1, ceili(float(normal) * clampf(intensity, 0.35, 1.0)))

static func absorbed_burst(canvas: CanvasItem, center: Vector2, radius: float, age: float, on_death: bool, reduced: bool) -> void:
    if age < 0 or age >= 0.65:
        return
    var progress := clampf(age / 0.30, 0, 1)
    var fade := 1 - age / 0.65
    var color := Color(0.88, 0.97, 1, fade)
    var extent := radius if reduced else radius * (1 - pow(1 - progress, 2))
    canvas.draw_arc(center, extent, 0, TAU, 24, color, 3 if on_death else 2)
    if age < 0.30:
        canvas.draw_arc(center + Vector2(0, -10), maxf(6, extent * 0.72), 0, TAU, 16, Color(0.70, 0.88, 0.95, fade * 0.65), 2)
    var count := particle_count(12 if on_death else 8)
    for index in range(count):
        var angle := float(index) * TAU / count
        var point := center + Vector2.from_angle(angle) * extent
        if not reduced:
            point.y -= sin(progress * PI) * 12
        var size := 4.0 if on_death else 3.0
        canvas.draw_rect(Rect2(point.round() - Vector2.ONE * size * 0.5, Vector2.ONE * size), color)
    impact(canvas, center + Vector2(0, -14), "slime_white", age, reduced)

const PULL_SECONDS := 0.72

static func pull_chain(effects: Array, target_id: String, clock: float) -> Dictionary:
    var result := {}
    for effect in effects:
        var age := clock - float(effect.get("time", 0))
        if effect.get("kind") != "pull" or effect.get("target_id") != target_id or age < 0 or age >= PULL_SECONDS:
            continue
        if result.is_empty():
            result = effect.duplicate()
        else:
            result["to_x"] = effect.get("to_x", result.get("to_x", 0))
            result["to_y"] = effect.get("to_y", result.get("to_y", 0))
    return result

static func pull_position(event: Dictionary, age: float, current: Vector2) -> Vector2:
    var start := Vector2(float(event.get("from_x", current.x)), float(event.get("from_y", current.y)))
    var end := Vector2(float(event.get("to_x", current.x)), float(event.get("to_y", current.y)))
    if age < 0.22:
        return start
    if age < 0.54:
        var t := clampf((age - 0.22) / 0.32, 0, 1)
        return start.lerp(end, t * t * (3.0 - 2.0 * t))
    return end.lerp(current, clampf((age - 0.54) / 0.18, 0, 1))

static func vine(canvas: CanvasItem, root: Vector2, caught: Vector2, age: float, reduced: bool) -> void:
    if age < 0 or age >= PULL_SECONDS:
        return
    var tip := root.lerp(caught, clampf(age / 0.22, 0, 1)) if age < 0.22 else caught
    if age > 0.54:
        tip = caught.lerp(root, clampf((age - 0.54) / 0.18, 0, 1))
    var direction := (tip - root).normalized()
    var perpendicular := Vector2(-direction.y, direction.x)
    for strand in range(2):
        var points := PackedVector2Array()
        for index in range(13):
            var t := float(index) / 12.0
            var bend := sin(t * PI) * (8.0 if strand == 0 else -7.0)
            if not reduced:
                bend += sin(t * TAU * 2.0 - age * 15) * 2.0 * sin(t * PI)
            points.append((root.lerp(tip, t) + perpendicular * bend).round())
        canvas.draw_polyline(points, Color("203d28"), 6)
        canvas.draw_polyline(points, Color("74a84e") if strand == 0 else Color("4f833e"), 3)
        for index in [3, 7, 10]:
            var p := points[index]
            var leaf := perpendicular * (5 if index % 2 == 0 else -5)
            canvas.draw_colored_polygon(PackedVector2Array([p, p + leaf - direction * 4, p + leaf * 1.5, p + direction * 3]), Color("a5c66a"))
    if age >= 0.18 and age < 0.56:
        canvas.draw_arc(tip, 9, -PI * 0.8, PI * 0.8, 10, Color("9ac461"), 3)

static func projectile(canvas: CanvasItem, p: Vector2, direction: Vector2, style: String, clock: float, reduced: bool) -> void:
    if direction.length_squared() < 0.01:
        direction = Vector2.RIGHT
    var side := Vector2(-direction.y, direction.x)
    match style:
        "arrow":
            var tail := p - direction * 15
            canvas.draw_line(tail.round(), (p + direction * 3).round(), Color("2f2b25"), 4)
            canvas.draw_line(tail.round(), p.round(), Color("d1a976"), 2)
            canvas.draw_colored_polygon(PackedVector2Array([(p + direction * 5).round(), (p - direction * 2 + side * 4).round(), (p - direction * 2 - side * 4).round()]), Color("e8e7c9"))
            canvas.draw_line((tail + side * 4).round(), (tail + direction * 5).round(), Color("e8dba6"), 2)
            canvas.draw_line((tail - side * 4).round(), (tail + direction * 5).round(), Color("e8dba6"), 2)
        "ice_shard":
            canvas.draw_colored_polygon(PackedVector2Array([(p + direction * 10).round(), (p + side * 5).round(), (p - direction * 9).round(), (p - side * 5).round()]), Color("5eaccc"))
            canvas.draw_line((p - direction * 7).round(), (p + direction * 8).round(), Color("d5f6ef"), 3)
        "seed":
            canvas.draw_colored_polygon(PackedVector2Array([(p + direction * 6).round(), (p + side * 4).round(), (p - direction * 5).round(), (p - side * 4).round()]), Color("66843f"))
            canvas.draw_rect(Rect2((p - Vector2(2, 2)).round(), Vector2(5, 4)), Color("e9c879"))
            canvas.draw_line((p - direction * 6).round(), (p - direction * 10 + side * 3).round(), Color("a5c76b"), 2)
        "dragonfire":
            for index in range(particle_count(5)):
                var wave := 0.0 if reduced else sin(clock * 22 + index) * 2
                var center := (p - direction * float(index * 5) + side * wave).round()
                var radius := float(7 - index)
                canvas.draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), Color("b44a32") if index > 2 else Color("ed8e42"))
            canvas.draw_rect(Rect2((p - Vector2(3, 3)).round(), Vector2(6, 6)), Color("ffe7a0"))
        "water_orb":
            for index in range(particle_count(3)):
                canvas.draw_circle((p - direction * (7 + index * 5)).round(), 2, Color(0.4, 0.8, 0.88, 0.6 - index * 0.15))
            canvas.draw_circle(p, 6, Color("397c9b"))
            canvas.draw_circle(p, 4, Color("81d3d7"))
            canvas.draw_rect(Rect2((p - Vector2(3, 3)).round(), Vector2(2, 3)), Color("e3f5e9"))
        "slime_green", "slime_white", "slime_pink":
            var color := slime_color(style)
            var outline := color.darkened(0.55)
            var wobble := 0.0 if reduced else roundf(sin(clock * 16) * 1.5)
            for index in range(particle_count(3)):
                var tail := (p - direction * (10 + index * 5) + side * wobble * (index + 1)).round()
                canvas.draw_circle(tail, 3 - index * 0.5, Color(color, 0.6 - index * 0.15))
            canvas.draw_circle(p, 8, outline)
            canvas.draw_circle(p + Vector2(0, wobble), 6, color)
            canvas.draw_rect(Rect2(p + Vector2(-4, -4), Vector2(3, 2)), color.lightened(0.65))
            canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(2, 3)), outline)
            canvas.draw_rect(Rect2(p + Vector2(4, 0), Vector2(2, 3)), outline)
        _:
            for index in range(particle_count(3)):
                var drift := 0.0 if reduced else sin(clock * 18 + index) * 2
                canvas.draw_rect(Rect2((p - direction * float(6 + index * 5) + side * drift - Vector2(2, 2)).round(), Vector2(4, 4)), Color("d76532") if index < 2 else Color("935039"))
            canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(6, 0), p + Vector2(0, 7), p + Vector2(-6, 0)]), Color("ef9d42"))
            canvas.draw_rect(Rect2((p - Vector2(3, 3)).round(), Vector2(6, 6)), Color("ffe5a0"))

static func impact(canvas: CanvasItem, p: Vector2, style: String, age: float, reduced: bool) -> void:
    var progress := clampf(age / 0.45, 0, 1)
    if age < 0 or progress >= 1:
        return
    var colors := {"arrow": Color("e5c991"), "seed": Color("b8ce6f"), "water_orb": Color("9ae0e1"), "ice_shard": Color("d0f6f4"), "slam": Color("c9ad80"), "slash": Color("efdcb5"), "bite": Color("b8cb78")}
    var color: Color = slime_color(style) if style.begins_with("slime_") else colors.get(style, Color("ffb85e"))
    color.a = (1.0 - progress) * (0.4 + 0.6 * clampf(intensity, 0.35, 1.0))
    if age < 0.1:
        canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -8), p + Vector2(8, 0), p + Vector2(0, 8), p + Vector2(-8, 0)]), Color(Color("fff3d5"), clampf(intensity, 0.35, 1.0)))
    if style.begins_with("slime_"):
        canvas.draw_arc(p, 5 + progress * 14, 0, TAU, 10, color, 3)
        var count := particle_count(6)
        for index in range(count):
            var ray := Vector2.from_angle(float(index) * TAU / count)
            var point: Vector2 = (p + ray * (6 + (0 if reduced else progress * 22))).round()
            canvas.draw_circle(point, maxf(1, 4 - progress * 3), color)
    elif style == "water_orb":
        canvas.draw_arc(p, 7 + progress * 14, 0, TAU, 12, color, 2)
    elif style == "slash":
        for offset in [-6, 0, 6]:
            canvas.draw_line((p + Vector2(-8 + offset, -8)).round(), (p + Vector2(5 + offset, 7)).round(), color, 2)
    else:
        var count := particle_count(6)
        for index in range(count):
            var ray := Vector2.from_angle(float(index) * TAU / count)
            var distance := 7.0 if reduced else 3 + progress * 19
            var point := (p + ray * distance).round()
            if style in ["arrow", "ice_shard"]:
                canvas.draw_line(point, (point + ray * 6).round(), color, 2)
            else:
                canvas.draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), color)

static func slime_color(style: String) -> Color:
    return {"slime_green": Color("91e876"), "slime_white": Color("f0edff"), "slime_pink": Color("f69bc9")}.get(style, Color("f69bc9"))

static func slime_pool(canvas: CanvasItem, center: Vector2, radius: float, remaining: float, duration: float, clock: float, reduced: bool) -> void:
    var fade := clampf(remaining, 0, 1)
    var rim := slime_color("slime_pink")
    var polygon := PackedVector2Array()
    for index in range(17):
        var angle := TAU * float(index) / 16
        var ripple := 0.0 if reduced else sin(clock * 2 + float(index) * 1.7) * 2
        polygon.append((center + Vector2.from_angle(angle) * (radius + ripple)).round())
    canvas.draw_colored_polygon(polygon, Color(0.73, 0.23, 0.48, fade * 0.08))
    canvas.draw_polyline(polygon, Color(rim, fade * 0.22), 1)
    var age_fraction := 1 - clampf(remaining / maxf(0.01, duration), 0, 1)
    for index in range(particle_count(5)):
        var angle := float(index) * 2.4
        var position := center + Vector2.from_angle(angle) * radius * (0.25 + float(index % 3) * 0.23)
        var bubble := 2.0 if reduced else 2 + sin(clock * 3 + index) * 1.3
        canvas.draw_arc(position.round(), bubble, 0, TAU, 6, Color(rim, fade * (0.5 - age_fraction * 0.2)), 1)
