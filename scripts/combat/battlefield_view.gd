class_name BattlefieldView
extends Control

var _frame: Dictionary = {}
var _field_width := 24.0
var _field_height := 14.0

func set_battlefield_size(width: float, height: float) -> void:
    _field_width = maxf(1.0, width)
    _field_height = maxf(1.0, height)
    queue_redraw()

func set_frame(frame: Dictionary) -> void:
    _frame = frame.duplicate(true)
    queue_redraw()

func _draw() -> void:
    var area := Rect2(Vector2.ZERO, size)
    draw_rect(area, Color(0.075, 0.085, 0.105, 1.0), true)
    draw_rect(area.grow(-2.0), Color(0.28, 0.31, 0.36, 1.0), false, 2.0)

    var mid_x := size.x * 0.5
    draw_line(
        Vector2(mid_x, 0.0),
        Vector2(mid_x, size.y),
        Color(0.35, 0.38, 0.43, 0.75),
        2.0
    )

    var units: Array = _frame.get("units", [])
    for raw_unit in units:
        if typeof(raw_unit) != TYPE_DICTIONARY:
            continue
        var unit: Dictionary = raw_unit
        _draw_unit(unit)

func _draw_unit(unit: Dictionary) -> void:
    var world_x := float(unit.get("x", 0.0))
    var world_y := float(unit.get("y", 0.0))
    var screen_position := Vector2(
        world_x / _field_width * size.x,
        world_y / _field_height * size.y
    )

    var role := str(unit.get("role", ""))
    var side := str(unit.get("side", "player"))
    var half_size := 7.0
    if role == "tank":
        half_size = 10.0
    elif role == "healer":
        half_size = 8.0

    var fill := Color(0.32, 0.75, 0.96, 1.0)
    if side == "opponent":
        fill = Color(0.96, 0.42, 0.32, 1.0)

    var body := Rect2(
        screen_position - Vector2(half_size, half_size),
        Vector2(half_size * 2.0, half_size * 2.0)
    )
    draw_rect(body, fill, true)
    draw_rect(body, Color(0.03, 0.04, 0.05, 1.0), false, 1.0)

    var hp := float(unit.get("hp", 0))
    var max_hp := maxf(1.0, float(unit.get("max_hp", 1)))
    var ratio := clampf(hp / max_hp, 0.0, 1.0)
    var bar_width := half_size * 2.2
    var bar_origin := screen_position + Vector2(-bar_width * 0.5, -half_size - 6.0)
    draw_rect(Rect2(bar_origin, Vector2(bar_width, 3.0)), Color(0.12, 0.13, 0.15, 1.0), true)
    draw_rect(
        Rect2(bar_origin, Vector2(bar_width * ratio, 3.0)),
        Color(0.48, 0.9, 0.46, 1.0),
        true
    )
