class_name UnitUpgradeVisuals
extends RefCounted
## Read-only cues for recorded upgrade events and fields, without unit labels.

static func area(canvas: CanvasItem, data: Dictionary, center: Vector2, radius: float, clock: float, reduced: bool) -> void:
    var color := Color("d7b3f2")
    if data.get("type") == "damage_area":
        color = Color("ee8e45")
    elif data.get("type") == "modifier_area":
        color = Color("a493d0") if data.get("stat") == "defense" else Color("e5a1c2")
    var fill := color
    fill.a = 0.13
    canvas.draw_circle(center, radius, fill)
    var edge := color
    edge.a = 0.65
    canvas.draw_arc(center, radius, 0, TAU, 24, edge, 2)
    for index in range(8):
        var angle := float(index) * TAU / 8.0
        var point := center + Vector2.from_angle(angle) * radius * 0.72
        if not reduced:
            point.y += sin(clock * 2 + index) * 2
        if data.get("type") == "heal":
            canvas.draw_rect(Rect2(point.round() - Vector2(1, 3), Vector2(2, 6)), color)
            canvas.draw_rect(Rect2(point.round() - Vector2(3, 1), Vector2(6, 2)), color)
        else:
            canvas.draw_rect(Rect2(point.round() - Vector2(2, 2), Vector2(4, 4)), color)

static func event(canvas: CanvasItem, kind: String, center: Vector2, radius: float, age: float, reduced: bool) -> void:
    if age < 0 or age > 0.65 or kind not in ["upgrade_pulse", "ice_splinter", "upgrade_death_heal"]:
        return
    var color := Color("f1a759") if kind == "upgrade_pulse" else (Color("9de5f1") if kind == "ice_splinter" else Color("e4d6a2"))
    color.a = 1 - age / 0.65
    var reach := radius if reduced else radius * minf(1, age / 0.3)
    canvas.draw_arc(center, reach, 0, TAU, 24, color, 3)
    for index in range(BattleEffects.particle_count(8)):
        var angle := TAU * float(index) / 8.0
        var point := center + Vector2.from_angle(angle) * reach
        canvas.draw_rect(Rect2(point.round() - Vector2(2, 2), Vector2(4, 4)), color)

static func roots(canvas: CanvasItem, center: Vector2, active: bool) -> void:
    if not active:
        return
    for index in range(3):
        var y := center.y - float(index) * 3
        var points := PackedVector2Array([Vector2(center.x - 10, y + 2), Vector2(center.x - 4, y - 1), Vector2(center.x + 3, y + 2), Vector2(center.x + 10, y - 1)])
        canvas.draw_polyline(points, Color("315a36"), 4)
        canvas.draw_polyline(points, Color("9bb966"), 2)
