class_name CardPortrait
extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
const SCENERY := preload("res://assets/pixel/forest-clearing-v1.png")
const ACCENTS := {"fire": Color("e7a664"), "water": Color("8dced6"), "earth": Color("aec87e"), "slime": Color("e5a2c4")}
var definition: Dictionary = {}
var commander := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    resized.connect(queue_redraw)

func set_content(content: Dictionary, is_commander: bool) -> void:
    definition = content
    commander = is_commander
    queue_redraw()

func _draw() -> void:
    if size.x <= 6 or size.y <= 6:
        return
    var element := str(definition.get("element", "earth"))
    var accent: Color = ACCENTS.get(element, Color("b7ba84"))
    # An arched woodland vignette rather than a second rectangular card.
    var arch := PackedVector2Array()
    var center := Vector2(size.x * 0.5, minf(size.x * 0.4, size.y * 0.32) + 3)
    var radius := Vector2(size.x * 0.5 - 3, center.y - 3)
    for index in range(17):
        var angle := PI + PI * float(index) / 16.0
        arch.append((center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)).floor())
    arch.append(Vector2(size.x - 3, size.y - 10))
    arch.append(Vector2(size.x - 9, size.y - 3))
    arch.append(Vector2(9, size.y - 3))
    arch.append(Vector2(3, size.y - 10))
    var uv := PackedVector2Array()
    for point in arch:
        uv.append(point / size)
    draw_polygon(arch, PackedColorArray([Color(0.42, 0.48, 0.44, 1)]), uv, SCENERY)
    var outline := arch.duplicate()
    outline.append(arch[0])
    draw_polyline(outline, Color(accent, 0.38), 1.0, false)
    var halo := Vector2(size.x * 0.5, size.y * 0.42).floor()
    var halo_radius := floorf(minf(size.x * 0.34, size.y * 0.31))
    draw_circle(halo, halo_radius, Color(accent, 0.07))
    draw_arc(halo, halo_radius, 0, TAU, 32, Color(accent, 0.14), 1.0, false)
    if definition.is_empty():
        return
    var picture: Texture2D = CommanderArt.icon(element) if commander else UnitArt.icon(str(definition.get("id", "")), str(definition.get("role", "range")), element, int(definition.get("unit_level", 1)))
    var source_size := picture.get_size()
    var padding := 4.0 if size.y < 160 else 18.0
    var scale_factor := maxf(0.1, minf((size.x - padding) / source_size.x, (size.y - padding) / source_size.y))
    if scale_factor >= 2.0:
        scale_factor = floorf(scale_factor)
    var draw_size := (source_size * scale_factor).floor()
    var position := ((size - draw_size) * 0.5).floor()
    var foot := position.y + draw_size.y * 0.94
    var shadow := PackedVector2Array()
    for index in range(16):
        var angle := TAU * float(index) / 16.0
        shadow.append((Vector2(size.x * 0.5, foot) + Vector2(cos(angle) * size.x * 0.27, sin(angle) * 4)).floor())
    draw_colored_polygon(shadow, Color(0.025, 0.04, 0.03, 0.55))
    draw_texture_rect(picture, Rect2(position, draw_size), false)
