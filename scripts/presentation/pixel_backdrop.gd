extends SubViewportContainer

const Painter = preload("res://scripts/presentation/forest_backdrop.gd")
var camp := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    stretch = true
    stretch_shrink = 4
    var viewport := SubViewport.new()
    viewport.disable_3d = true
    viewport.gui_disable_input = true
    viewport.size = Vector2i(320, 180)
    add_child(viewport)
    var painter := Painter.new()
    painter.camp = camp
    viewport.add_child(painter)
