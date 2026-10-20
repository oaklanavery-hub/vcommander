@tool
class_name FantasyFrame
extends StyleBox
## Shared carved-wood/leather skin. Pixel detail stays at UI scale; text never
## passes through a low-resolution viewport. This resource owns no game state.

@export var bg_color := Color("342b25")
@export var border_color := Color("89704a")
@export var border_width_left := 2
@export var border_width_top := 2
@export var border_width_right := 2
@export var border_width_bottom := 3
@export var corner_radius_top_left := 12
@export var corner_radius_top_right := 12
@export var corner_radius_bottom_left := 12
@export var corner_radius_bottom_right := 12
@export var shadow_color := Color(0.025, 0.018, 0.015, 0.45)
@export var shadow_size := 3
@export var shadow_offset := Vector2(0, 3)
@export var grain := true
@export var ornaments := true

var _surface := StyleBoxFlat.new()
var _inset := StyleBoxFlat.new()

func set_border_width_all(value: int) -> void:
    border_width_left = value
    border_width_top = value
    border_width_right = value
    border_width_bottom = value

func set_corner_radius_all(value: int) -> void:
    corner_radius_top_left = value
    corner_radius_top_right = value
    corner_radius_bottom_left = value
    corner_radius_bottom_right = value

func _draw(canvas: RID, rect: Rect2) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    _surface.bg_color = bg_color
    _surface.border_color = border_color
    _surface.border_width_left = border_width_left
    _surface.border_width_top = border_width_top
    _surface.border_width_right = border_width_right
    _surface.border_width_bottom = border_width_bottom
    _surface.corner_radius_top_left = corner_radius_top_left
    _surface.corner_radius_top_right = corner_radius_top_right
    _surface.corner_radius_bottom_left = corner_radius_bottom_left
    _surface.corner_radius_bottom_right = corner_radius_bottom_right
    _surface.corner_detail = 4
    _surface.anti_aliasing = false
    _surface.shadow_color = shadow_color
    _surface.shadow_size = shadow_size if bg_color.a > 0.5 else 0
    _surface.shadow_offset = shadow_offset
    _surface.draw(canvas, rect)
    if rect.size.x < 30 or rect.size.y < 16 or bg_color.a < 0.2:
        return
    var inner := rect.grow(-6)
    if grain:
        # Broken fine strokes suggest hand-worked material without tiled blocks.
        var highlight := Color(1.0, 0.83, 0.52, 0.055 * bg_color.a)
        var shade := Color(0.04, 0.025, 0.015, 0.1 * bg_color.a)
        var rows := mini(56, int(inner.size.y / 9))
        for row in range(rows):
            var y := floorf(inner.position.y + 4 + row * 9)
            var inset := 9.0 + float((row * 17) % 23)
            var start := inner.position.x + inset
            var finish := inner.end.x - 9 - float((row * 13) % 29)
            if finish > start:
                RenderingServer.canvas_item_add_line(canvas, Vector2(start, y), Vector2(finish, y), highlight, 1.0, false)
                var knot := start + (finish - start) * float((row * 7 + 3) % 11) / 11.0
                RenderingServer.canvas_item_add_line(canvas, Vector2(knot, y + 2), Vector2(minf(knot + 15, finish), y + 2), shade, 1.0, false)
    if border_color.a < 0.2 or maxi(border_width_left, border_width_top) == 0:
        return
    _inset.bg_color = Color.TRANSPARENT
    _inset.border_color = Color(border_color.lightened(0.25), 0.3 * border_color.a)
    _inset.set_border_width_all(1)
    _inset.set_corner_radius_all(maxi(2, mini(corner_radius_top_left, corner_radius_bottom_left) - 4))
    _inset.corner_detail = 4
    _inset.anti_aliasing = false
    _inset.draw(canvas, rect.grow(-4))
    if not ornaments or rect.size.y < 60 or rect.size.x < 90:
        return
    var metal := border_color.lightened(0.35)
    var low := border_color.darkened(0.45)
    for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
        var anchor := Vector2(rect.position.x + 9 if corner.x > 0 else rect.end.x - 9, rect.position.y + 9 if corner.y > 0 else rect.end.y - 9).floor()
        RenderingServer.canvas_item_add_line(canvas, anchor, anchor + Vector2(corner.x * 11, 0), metal, 1.0, false)
        RenderingServer.canvas_item_add_line(canvas, anchor, anchor + Vector2(0, corner.y * 11), metal, 1.0, false)
        RenderingServer.canvas_item_add_rect(canvas, Rect2(anchor - Vector2(1, 1), Vector2(3, 3)), low)
        RenderingServer.canvas_item_add_rect(canvas, Rect2(anchor, Vector2(1, 1)), metal)
