class_name BattlefieldView
extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
var _frame: Dictionary = {}
var _field_width := 24.0
var _field_height := 14.0
var _visual_time := 0.0

func set_battlefield_size(width: float, height: float) -> void:
    _field_width = maxf(1.0, width)
    _field_height = maxf(1.0, height)
    queue_redraw()

func set_frame(frame: Dictionary) -> void:
    _frame = frame.duplicate(true)
    _visual_time = float(frame.get("time", 0.0))
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("35513f"))
    # Fixed decorative tiles, never simulation obstacles or gameplay RNG.
    for y in range(0, int(size.y), 16):
        for x in range(0, int(size.x), 16):
            var pattern := (x * 17 + y * 31) % 97
            var shade := Color("3e6048") if pattern < 42 else Color("42674b")
            draw_rect(Rect2(Vector2(x, y), Vector2(16, 16)), shade)
            if pattern < 10:
                draw_rect(Rect2(Vector2(x + 4, y + 7), Vector2(2, 4)), Color("75925b"))
            if pattern == 16:
                draw_rect(Rect2(Vector2(x + 8, y + 8), Vector2(3, 3)), Color("e9c581"))
    var path_y := floorf(size.y * 0.5 / 8.0) * 8.0
    draw_rect(Rect2(Vector2(0, path_y - 26), Vector2(size.x, 52)), Color("7e7854"))
    for x in range(0, int(size.x), 24):
        draw_rect(Rect2(Vector2(x + 4, path_y - 12 + (x % 5) * 3), Vector2(12, 5)), Color("9b9166"))
    draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("b7a871"), false, 3.0)
    for on_right in [false, true]:
        var flag_x := size.x - 22.0 if on_right else 20.0
        draw_rect(Rect2(Vector2(flag_x, 16), Vector2(3, 36)), Color("382f3d"))
        draw_rect(Rect2(Vector2(flag_x + 3, 16), Vector2(19, 14)), Color("db8972") if on_right else Color("80c7c4"))
    var units: Array = _frame.get("units", []).duplicate()
    units.sort_custom(func(a, b): return float(a.get("y", 0)) < float(b.get("y", 0)))
    for unit in units:
        _draw_unit(unit)

func _draw_unit(unit: Dictionary) -> void:
    var p := Vector2(float(unit.get("x", 0)) / _field_width * size.x, float(unit.get("y", 0)) / _field_height * size.y).round()
    var side := str(unit.get("side", "player"))
    var role := str(unit.get("role", "range"))
    var pixel := 3.0 if role == "tank" else 2.0
    draw_rect(Rect2(p + Vector2(-12, -2), Vector2(24, 5)), Color(0.12, 0.19, 0.17, 0.6))
    draw_rect(Rect2(p + Vector2(-9, 3), Vector2(18, 2)), Color("e89880") if side == "opponent" else Color("9bdcd6"))
    var bob := floorf(sin(_visual_time * 5.0 + float(unit.get("y", 0))) + 1.0)
    UnitArt.draw_unit(self, p, role, str(unit.get("element", "earth")), pixel, side == "opponent", bob)
    var ratio := clampf(float(unit.get("hp", 0)) / maxf(1.0, float(unit.get("max_hp", 1))), 0.0, 1.0)
    var bar := p + Vector2(-13, -36 if role == "tank" else -28)
    draw_rect(Rect2(bar - Vector2.ONE, Vector2(28, 5)), Color("292b38"))
    draw_rect(Rect2(bar, Vector2(floorf(26 * ratio), 3)), Color("8bd28a") if side == "player" else Color("f0a087"))
