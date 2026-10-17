class_name CardTile
extends Button

var definition: Dictionary = {}
var commander := false
var portrait := CardPortrait.new()
var caption := Label.new()
var empty_caption := "Empty slot"
var detail_text := ""

func _ready() -> void:
    text = ""
    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = Vector2(132, 184)
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    ScreenStyle.card(self, str(definition.get("element", "earth")))
    add_child(portrait)
    portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait.offset_left = 12
    portrait.offset_top = 36
    portrait.offset_right = -12
    portrait.offset_bottom = -49
    portrait.set_content(definition, commander)
    portrait.visible = not definition.is_empty()
    add_child(caption)
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    caption.offset_left = 7
    caption.offset_right = -7
    caption.offset_top = -46
    caption.offset_bottom = -5
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_font_size_override("font_size", 14)
    caption.text = str(definition.get("display_name", empty_caption))
    if not detail_text.is_empty():
        caption.text += "\n" + detail_text
    if definition.is_empty():
        disabled = true
    var badges := Control.new()
    badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(badges)
    badges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    badges.draw.connect(_draw_badges.bind(badges))
    toggled.connect(func(_value: bool): queue_redraw())

func set_content(content: Dictionary, is_commander := false) -> void:
    definition = content
    commander = is_commander
    var detail := "%s • %s" % [str(content.get("element", "")).capitalize(), str(content.get("role", "Commander" if is_commander else "Unit")).capitalize()]
    if not is_commander and not content.is_empty():
        detail += "\nRecruit %d per pick • Maximum %d\n%s" % [int(content.get("summon_amount", 0)), int(content.get("unit_cap", 0)), str(content.get("ability", {}).get("display_name", ""))]
        var stats: Dictionary = content.get("stats", {})
        detail += "\nHealth %d • Attack %d • Defense %d" % [int(stats.get("health", 0)), int(stats.get("attack", 0)), int(stats.get("defense", 0))]
    tooltip_text = detail

func _draw() -> void:
    if definition.is_empty():
        draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - 11, size.y * 0.5), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("8c9b7a"))
        return
    if button_pressed:
        draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("f4d895"), false, 3)

func _draw_badges(canvas: Control) -> void:
    if definition.is_empty():
        return
    _element_badge(Vector2(19, 18), str(definition.get("element", "earth")), canvas)
    if commander:
        canvas.draw_string(ThemeDB.fallback_font, Vector2(38, 23), "COMMANDER", HORIZONTAL_ALIGNMENT_LEFT, size.x - 42, 9, Color("f0ddb0"))
    else:
        var count := "%d/%d" % [int(definition.get("summon_amount", 0)), int(definition.get("unit_cap", 0))]
        var center := Vector2(size.x - 20, 17)
        canvas.draw_circle(center, 15, Color("e5d6ad"))
        canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-13, 4), count, HORIZONTAL_ALIGNMENT_CENTER, 26, 11, Color("30291f"))
        _role_badge(Vector2(size.x - 20, 53), str(definition.get("role", "range")), canvas)

func _element_badge(center: Vector2, element: String, canvas: Control) -> void:
    canvas.draw_circle(center, 13, Color("2d382b"))
    var color := Color("9fc574")
    if element == "fire":
        color = Color("eea35c")
    elif element == "water":
        color = Color("8bd0dd")
    var points := PackedVector2Array([center + Vector2(0, -9), center + Vector2(-7, 3), center + Vector2(-4, 8), center + Vector2(4, 8), center + Vector2(7, 3)])
    canvas.draw_colored_polygon(points, color)
    if element == "earth":
        canvas.draw_line(center + Vector2(-4, 6), center + Vector2(3, -4), Color("405d39"), 2)
    elif element == "fire":
        canvas.draw_rect(Rect2(center + Vector2(-2, 1), Vector2(4, 6)), Color("f7df81"))
    else:
        canvas.draw_rect(Rect2(center + Vector2(-3, 0), Vector2(2, 4)), Color("d4f1eb"))

func _role_badge(center: Vector2, role: String, canvas: Control) -> void:
    canvas.draw_circle(center, 12, Color("e5d6ad"))
    var ink := Color("3c4938")
    if role == "tank":
        canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-6, -6), center + Vector2(6, -6), center + Vector2(6, 3), center + Vector2(0, 8), center + Vector2(-6, 3)]), ink)
    elif role == "healer":
        canvas.draw_rect(Rect2(center - Vector2(2, 7), Vector2(4, 14)), ink)
        canvas.draw_rect(Rect2(center - Vector2(7, 2), Vector2(14, 4)), ink)
    elif role == "melee":
        canvas.draw_line(center + Vector2(-6, 7), center + Vector2(6, -7), ink, 3)
        canvas.draw_line(center + Vector2(-6, -1), center + Vector2(2, 6), ink, 2)
    else:
        canvas.draw_arc(center - Vector2(3, 0), 7, -PI * 0.45, PI * 0.45, 6, ink, 2)
        canvas.draw_line(center + Vector2(-5, 0), center + Vector2(7, 0), ink, 2)
