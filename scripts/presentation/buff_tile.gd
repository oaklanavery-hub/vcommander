class_name BuffTile
extends Button
## A blessing offer is presentation only. The caller supplies data and handles
## selection through the existing local draft or authoritative online intent.

var definition: Dictionary = {}
var stacks := 0

func _ready() -> void:
    text = ""
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    ScreenStyle.card(self, "")
    var body := VBoxContainer.new()
    body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(body)
    body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    body.offset_left = 12
    body.offset_right = -12
    body.offset_top = 12
    body.offset_bottom = -12
    body.alignment = BoxContainer.ALIGNMENT_CENTER
    body.add_theme_constant_override("separation", 5)
    var emblem := FantasyEmblem.new()
    emblem.kind = str(definition.get("stat", "mastery"))
    emblem.accent = Color("d5b578")
    emblem.custom_minimum_size = Vector2(56, 56)
    emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    body.add_child(emblem)
    var heading := ScreenStyle.label(str(definition.get("display_name", "Warband blessing")), 20)
    heading.custom_minimum_size.y = 44
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(heading)
    var value := ScreenStyle.label("+%d%% %s" % [int(definition.get("percentage", 0)), str(definition.get("stat", "")).replace("_", " ")], 14)
    value.custom_minimum_size.y = 36
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    value.add_theme_color_override("font_color", Color("eed299"))
    body.add_child(value)
    var detail := ScreenStyle.label("Army-wide · %d / %d" % [stacks, int(definition.get("max_stacks", 3))], 12)
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_child(detail)
    tooltip_text = "%s\n+%d%% %s for the whole warband\nCurrent stacks: %d / %d" % [str(definition.get("display_name", "Blessing")), int(definition.get("percentage", 0)), str(definition.get("stat", "")).replace("_", " "), stacks, int(definition.get("max_stacks", 3))]
