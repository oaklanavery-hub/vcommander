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
    var palettes := {"fire": Color("634330"), "water": Color("304f5a"), "earth": Color("3d5135")}
    var color: Color = palettes.get(element, Color("3d5135"))
    draw_rect(Rect2(Vector2.ZERO, size), color.darkened(0.32))
    draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), color)
    var horizon := size.y * 0.73
    draw_rect(Rect2(3, horizon, maxf(0, size.x - 6), maxf(0, size.y - horizon - 3)), color.darkened(0.24))
    for index in range(7):
        var x := (float(index) + 0.5) * size.x / 7.0
        var y := size.y * (0.19 + float(index % 3) * 0.12)
        draw_rect(Rect2(x, y, 2, 2), Color(0.94, 0.84, 0.60, 0.3))
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
    draw_rect(Rect2(Vector2(size.x * 0.28, size.y - 12), Vector2(size.x * 0.44, 4)), color.darkened(0.4))
    draw_texture_rect(picture, Rect2(position, draw_size), false)
