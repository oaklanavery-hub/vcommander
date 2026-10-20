class_name CardTile
extends Button

var definition: Dictionary = {}
var commander := false
var portrait := CardPortrait.new()
var caption := Label.new()
var empty_caption := "Empty slot"
var detail_text := ""
var mastery_level := 1
var locked := false
var _hovered := false

func _ready() -> void:
    text = ""
    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = Vector2(132, 184)
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    ScreenStyle.card(self, str(definition.get("element", "earth")))
    add_child(portrait)
    portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait.offset_left = 9
    portrait.offset_top = 34
    portrait.offset_right = -9
    portrait.offset_bottom = -45
    portrait.set_content(definition, commander)
    portrait.visible = not definition.is_empty()
    add_child(caption)
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    caption.offset_left = 7
    caption.offset_right = -7
    caption.offset_top = -43
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
    mouse_entered.connect(func():
        _hovered = true
        queue_redraw())
    mouse_exited.connect(func():
        _hovered = false
        queue_redraw())

func set_content(content: Dictionary, is_commander := false) -> void:
    definition = content
    commander = is_commander
    var detail := "%s • %s" % [str(content.get("element", "")).capitalize(), str(content.get("role", "Commander" if is_commander else "Unit")).capitalize()]
    if not is_commander and not content.is_empty():
        detail += "\nRecruit %d per pick • Maximum %d\n%s" % [int(content.get("summon_amount", 0)), int(content.get("unit_cap", 0)), str(content.get("ability", {}).get("display_name", ""))]
        var stats: Dictionary = content.get("stats", {})
        detail += "\nHealth %d • Attack %d • Defense %d" % [int(stats.get("health", 0)), int(stats.get("attack", 0)), int(stats.get("defense", 0))]
        var description := str(content.get("ability", {}).get("description", ""))
        if not description.is_empty():
            detail += "\n\n" + description
    tooltip_text = detail

func _draw() -> void:
    caption.modulate = Color("f5dfa7") if button_pressed else Color("f1e8d3")
    portrait.modulate = Color("798b85") if locked else (Color(1.07, 1.07, 1.04) if _hovered else Color.WHITE)
    var footer := ScreenStyle.frame(Color(0.06, 0.1, 0.08, 0.42), Color.TRANSPARENT, 7)
    footer.set_border_width_all(0)
    footer.corner_radius_top_left = 0
    footer.corner_radius_top_right = 0
    draw_style_box(footer, Rect2(Vector2(3, size.y - 43), Vector2(size.x - 6, 39)))
    draw_line(Vector2(12, size.y - 43), Vector2(size.x - 12, size.y - 43), Color(0.88, 0.75, 0.46, 0.35))
    if definition.is_empty():
        var center := Vector2(size.x * 0.5, size.y * 0.48).floor()
        draw_rect(Rect2(center - Vector2(2, 12), Vector2(4, 24)), Color("819478"))
        draw_rect(Rect2(center - Vector2(12, 2), Vector2(24, 4)), Color("819478"))
        return

func _draw_badges(canvas: Control) -> void:
    if definition.is_empty():
        return
    _element_badge(Vector2(19, 18), str(definition.get("element", "earth")), canvas)
    if locked:
        var banner := ScreenStyle.frame(Color("182a29"), Color("9d8c60"), 4)
        banner.set_content_margin_all(0)
        banner.set_border_width_all(1)
        canvas.draw_style_box(banner, Rect2(10, size.y - 70, size.x - 20, 22))
        canvas.draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 54), "LOCKED · MASTERY", HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 10, Color("e4c995"))
    if commander:
        canvas.draw_string(ThemeDB.fallback_font, Vector2(38, 23), "MASTERY %d" % mastery_level, HORIZONTAL_ALIGNMENT_LEFT, size.x - 42, 10, Color("f0ddb0"))
    else:
        var count := "%d/%d" % [int(definition.get("summon_amount", 0)), int(definition.get("unit_cap", 0))]
        var center := Vector2(size.x - 20, 17)
        canvas.draw_circle(center + Vector2(0, 1), 16, Color("352e25"))
        canvas.draw_circle(center, 14, Color("ecddb4"))
        canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-13, 4), count, HORIZONTAL_ALIGNMENT_CENTER, 26, 12, Color("30291f"))
        _role_badge(Vector2(size.x - 20, 53), str(definition.get("role", "range")), canvas)

func _element_badge(center: Vector2, element: String, canvas: Control) -> void:
    canvas.draw_circle(center, 14, Color("a39260"))
    canvas.draw_circle(center, 12, Color("253c33"))
    var color := Color("9fc574")
    if element == "fire":
        color = Color("eea35c")
    elif element == "water":
        color = Color("8bd0dd")
    elif element == "slime":
        color = Color("f2a1c6")
        canvas.draw_circle(center + Vector2(0, 2), 7, color)
        canvas.draw_circle(center + Vector2(-2, -3), 4, color)
        canvas.draw_rect(Rect2(center + Vector2(-3, 1), Vector2(2, 3)), Color("543247"))
        canvas.draw_rect(Rect2(center + Vector2(2, 1), Vector2(2, 3)), Color("543247"))
        return
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
