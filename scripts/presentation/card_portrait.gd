class_name CardPortrait
extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
var definition: Dictionary = {}
var commander := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_content(content: Dictionary, is_commander: bool) -> void:
    definition = content
    commander = is_commander
    queue_redraw()

func _draw() -> void:
    var element := str(definition.get("element", "earth"))
    var palettes := {"fire": Color("563b30"), "water": Color("294952"), "earth": Color("354b36")}
    var color: Color = palettes.get(element, Color("3d5135"))
    draw_style_box(ScreenStyle.frame(color, color.lightened(0.14), 7), Rect2(Vector2.ZERO, size))
    var horizon := floorf(size.y * 0.74)
    var halo_center := Vector2(size.x * 0.5, size.y * 0.4).floor()
    var halo_radius := floorf(minf(size.x * 0.37, size.y * 0.31))
    var halo := PackedVector2Array()
    for index in range(9):
        halo.append((halo_center + Vector2.from_angle(PI * 0.25 * index) * halo_radius).floor())
    draw_colored_polygon(halo, Color(0.95, 0.81, 0.48, 0.06))
    draw_polyline(halo, Color(0.95, 0.81, 0.48, 0.15), 1)
    var ground := PackedVector2Array([Vector2(3, horizon), Vector2(size.x * 0.22, horizon), Vector2(size.x * 0.22, horizon - 5), Vector2(size.x * 0.61, horizon - 5), Vector2(size.x * 0.61, horizon + 3), Vector2(size.x - 3, horizon + 3), size - Vector2(3, 8), size - Vector2(8, 3), Vector2(8, size.y - 3), Vector2(3, size.y - 8)])
    draw_colored_polygon(ground, color.darkened(0.24))
    for index in range(7):
        var x := (float(index) + 0.5) * size.x / 7.0
        var y := size.y * (0.15 + float(index % 3) * 0.15)
        draw_rect(Rect2(Vector2(x, y).floor(), Vector2(2, 2)), Color(0.94, 0.84, 0.60, 0.25))
    if definition.is_empty():
        return
    var picture: Texture2D = CommanderArt.icon(element) if commander else UnitArt.icon(str(definition.get("id", "")), str(definition.get("role", "range")), element)
    var source_size := picture.get_size()
    var padding := 2.0 if size.y < 160 else 16.0
    var scale_factor := maxf(0.1, minf((size.x - padding) / source_size.x, (size.y - padding) / source_size.y))
    if scale_factor >= 2.0:
        scale_factor = floorf(scale_factor)
    var draw_size := (source_size * scale_factor).floor()
    var position := ((size - draw_size) * 0.5).floor()
    var foot := position.y + draw_size.y * 0.94
    draw_rect(Rect2(Vector2(size.x * 0.3, foot), Vector2(size.x * 0.4, 4)), color.darkened(0.45))
    draw_texture_rect(picture, Rect2(position, draw_size), false)
