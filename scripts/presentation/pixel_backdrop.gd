extends Control
## Full-resolution original pixel scenery; interface text stays sharp and native.

const SCENERY := preload("res://assets/pixel/lodge-courtyard-v1.png")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    resized.connect(queue_redraw)

func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    var source := SCENERY.get_size()
    var scale_factor := maxf(size.x / source.x, size.y / source.y)
    var visible_source := size / scale_factor
    draw_texture_rect_region(SCENERY, Rect2(Vector2.ZERO, size), Rect2((source - visible_source) * 0.5, visible_source))
    # Preserve the illustrated setting while keeping all text legible.
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.04, 0.035, 0.37))
