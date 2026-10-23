class_name AssassinEffects
extends RefCounted
## Pixel effects drawn from recorded simulation state only.

static func screen(field: Control, record: Dictionary, prefix: String) -> Vector2:
    return field._point(float(record[prefix + "_x"]), float(record[prefix + "_y"]))

static func terrain(field: Control, frame: Dictionary, time: float, reduced: bool) -> void:
    for hazard in frame.get("hazards", []):
        if float(hazard["expires_at"]) <= time:
            continue
        var alpha := clampf((float(hazard["expires_at"]) - time) / 0.5, 0, 1)
        for segment in hazard["segments"]:
            var a := screen(field, segment, "from")
            var b := screen(field, segment, "to")
            var radius: float = float(hazard["radius"]) / field._field_width * field._arena.size.x
            # The soft ground footprint matches the damaging path width. The
            # irregular stepped flames avoid a repeated fence/picket pattern.
            field.draw_line(a, b, Color(0.9, 0.24, 0.06, alpha * 0.13), radius * 2)
            field.draw_line(a, b, Color(0.22, 0.12, 0.16, alpha * 0.35), radius * 0.8)
            field.draw_line(a, b, Color(0.95, 0.3, 0.08, alpha * 0.8), 3)
            var steps := maxi(1, int(a.distance_to(b) / 6 * clampf(BattleEffects.intensity, 0.35, 1.0)))
            for index in range(steps + 1):
                var p := a.lerp(b, float(index) / float(steps)).round()
                var seed_value := absf(sin(p.x * 2.17 + p.y * 0.73))
                var sway := 0.0 if reduced else sin(time * 9 + p.x * 0.5) * 2
                var rise := 5 + seed_value * 9 + sway
                var offset := Vector2(sway, -rise)
                field.draw_rect(Rect2((p + offset).round(), Vector2(3, rise)), Color(1, 0.37, 0.08, alpha * 0.9))
                field.draw_rect(Rect2((p + offset + Vector2(1, 2)).round(), Vector2(2, maxf(2, rise - 3))), Color(1, 0.75, 0.2, alpha))
                field.draw_rect(Rect2((p + offset + Vector2(2, 4)).round(), Vector2(1, 3)), Color(1, 0.94, 0.62, alpha))
                if int(seed_value * 10) % 3 == 0 and BattleEffects.intensity >= 0.6:
                    var drift := 4.0 if reduced else fmod(time * 12 + p.x, 11.0)
                    field.draw_rect(Rect2((p + Vector2(sway + 3, -rise - drift)).round(), Vector2(2, 2)), Color(1, 0.7, 0.24, alpha * 0.8))
    for wall in frame.get("obstacles", []):
        if float(wall["expires_at"]) <= time:
            continue
        var a := screen(field, wall, "from")
        var b := screen(field, wall, "to")
        var normal := (b - a).normalized().orthogonal()
        var points := PackedVector2Array()
        var steps := maxi(2, int(a.distance_to(b) / 9))
        for index in range(steps + 1):
            var p := a.lerp(b, float(index) / float(steps))
            p += normal * (sin(float(index) * 7.31 + a.x) * 4)
            points.append(p.round())
        var alpha := clampf((float(wall["expires_at"]) - time) / 0.5, 0, 1)
        field.draw_polyline(points, Color(0.12, 0.09, 0.13, alpha), 8)
        # Broken lit lips and occasional branching fissures sit beside a dark
        # center, rather than filling the entire crack with a brown stripe.
        for index in range(1, points.size()):
            var edge := normal * (3 if index % 3 != 0 else -3)
            field.draw_line((points[index - 1] + edge).round(), (points[index] + edge).round(), Color(0.61, 0.46, 0.27, alpha), 2)
            if index % 4 == 0:
                var p := points[index]
                var branch := p + normal * (9 + index % 5)
                field.draw_line(p, branch.round(), Color(0.15, 0.11, 0.14, alpha), 3)
                field.draw_rect(Rect2((branch - Vector2(2, 3)).round(), Vector2(4, 3)), Color(0.74, 0.61, 0.4, alpha))

static func transit_at(events: Array, id: String, time: float) -> Dictionary:
    for event in events:
        if event.get("kind") != "backline_transit" or event.get("unit_id") != id:
            continue
        var transit: Dictionary = event.get("transit", {})
        if time >= float(transit.get("started_at", INF)) and time < float(transit.get("ends_at", -INF)):
            return transit
    return {}

static func actor(field: Control, unit: Dictionary, time: float, reduced: bool) -> void:
    var transit: Dictionary = unit["transit"]
    var p: Vector2 = field._point(float(unit["x"]), float(unit["y"]))
    var mode := str(transit.get("mode", "flame"))
    var direction := (screen(field, transit, "to") - screen(field, transit, "from")).normalized()
    if mode == "burrow":
        for index in range(5):
            var q := p - direction * float(index * 6)
            field.draw_rect(Rect2(q.round() - Vector2(3, 4), Vector2(6, 4 + index % 2 * 2)), Color("9d7950") if index % 2 == 0 else Color("514032"))
        field.draw_arc(p, 10, PI, TAU, 8, Color("d3b77d"), 2)
        return
    p -= Vector2(0, 13)
    var main := Color("ff883a") if mode == "flame" else Color("5dcddc")
    var light := Color("ffe39c") if mode == "flame" else Color("e3ffff")
    if mode == "gush":
        var angle := direction.angle()
        field.draw_arc(p, 12, angle - 1.2, angle + 1.2, 10, Color("276b9a"), 7)
        field.draw_arc(p, 12, angle - 1.2, angle + 1.2, 10, main, 5)
        field.draw_arc(p + direction * 2, 12, angle - 1.1, angle + 1.1, 10, light, 2)
        var normal := direction.orthogonal()
        for index in range(5):
            var drift := 0.0 if reduced else sin(time * 11 + float(index)) * 2
            var foam := p - direction * float(index * 6) + normal * (float(index % 3 - 1) * 5 + drift)
            field.draw_rect(Rect2(foam.round() - Vector2(2, 2), Vector2(5, 4)), main if index % 2 == 0 else light)
        return
    var pulse := 1.0 if reduced else 1 + sin(time * 17) * 0.15
    for index in range(6, 0, -1):
        var q := p - direction * float(index * 5)
        var extent := Vector2(3 + index % 2, 4) * (1 - float(index) / 10)
        var color := main
        color.a = 1 - float(index) / 8
        field.draw_rect(Rect2((q - extent).round(), extent * 2), color)
    field.draw_circle(p, 10 * pulse, Color(0.2, 0.12, 0.24, 0.7))
    field.draw_rect(Rect2(p - Vector2(7, 8), Vector2(14, 16)), main)
    field.draw_rect(Rect2(p - Vector2(10, 5), Vector2(20, 10)), main)
    field.draw_rect(Rect2(p - Vector2(4, 6), Vector2(8, 12)), light)
    field.draw_rect(Rect2(p - Vector2(6, 3), Vector2(12, 6)), light)

static func links(field: Control, frame: Dictionary, known: Dictionary, time: float, reduced: bool) -> void:
    for link in frame.get("links", []):
        if float(link["expires_at"]) <= time:
            continue
        var points: Array[Vector2] = []
        for id in link["target_ids"]:
            var unit: Dictionary = known.get(str(id), {})
            if unit.is_empty() or float(unit.get("hp", 0)) <= 0:
                continue
            var p: Vector2 = field._body_point(unit)
            points.append(p)
            field.draw_arc(p, 13, 0, TAU, 12, Color("dda7f3"), 2)
            for index in range(BattleEffects.particle_count(3)):
                field.draw_circle((p + Vector2(-7 + index * 7, 10 + index % 2 * 3)).round(), 2, Color("b7ecc0"))
        if points.size() != 2:
            continue
        var curve := PackedVector2Array()
        for index in range(17):
            var t := float(index) / 16
            var p := points[0].lerp(points[1], t)
            p.y += sin(t * PI) * 12
            if not reduced:
                p.y += sin(t * TAU * 2 + time * 7) * 2
            curve.append(p.round())
        field.draw_polyline(curve, Color("503456"), 6)
        field.draw_polyline(curve, Color("d49ee9"), 3)
        for index in range(2, 16, 4):
            field.draw_rect(Rect2(curve[index] - Vector2(1, 1), Vector2(3, 3)), Color("e7f6c8"))

static func number(value: float) -> String:
    if absf(value) < 1000000:
        return str(int(round(value)))
    var exponent := int(floor(log(absf(value)) / log(10.0)))
    return "%.1fe%d" % [value / pow(10.0, exponent), exponent]
