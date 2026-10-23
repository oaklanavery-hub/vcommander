class_name BuffTile
extends Button
## A blessing offer is presentation only. The caller supplies data and handles
## selection through the existing local draft or authoritative online intent.

var definition: Dictionary = {}
var stacks := 0
var side_config: Dictionary = {}
var benefit_label: Label

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
    body.add_theme_constant_override("separation", 4)
    var emblem := FantasyEmblem.new()
    emblem.kind = str(definition.get("stat", "mastery"))
    emblem.accent = Color("d5b578")
    emblem.custom_minimum_size = Vector2(48, 48)
    emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    body.add_child(emblem)
    var heading := ScreenStyle.label(str(definition.get("display_name", "Warband blessing")), 20)
    heading.custom_minimum_size.y = 42 if not side_config.is_empty() else 54
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(heading)
    var value := ScreenStyle.label("+%d%% %s" % [int(definition.get("percentage", 0)), str(definition.get("stat", "")).replace("_", " ")], 14)
    value.custom_minimum_size.y = 30 if not side_config.is_empty() else 44
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    value.add_theme_color_override("font_color", Color("eed299"))
    body.add_child(value)
    var detail := ScreenStyle.label("%d stacks · ∞" % stacks, 12)
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_child(detail)
    tooltip_text = "%s\n+%d%% %s for the whole warband\nCurrent stacks: %s" % [str(definition.get("display_name", "Blessing")), int(definition.get("percentage", 0)), str(definition.get("stat", "")).replace("_", " "), stack_text(definition, stacks)]

    var rating_cap := int(ContentDatabase.get_game_balance().get("stats", {}).get(str(definition.get("stat", "")) + "_cap", 0))
    if rating_cap > 0:
        tooltip_text += "\nSpeed rating limit: %d. Additional picks do not increase a rating already at its limit." % rating_cap
    if not side_config.is_empty():
        var preview := WarbandStats.power_preview(side_config, definition, ContentDatabase.get_game_balance().get("stats", {}))
        benefit_label = ScreenStyle.label("Improves %d / %d units" % [preview["improved"], preview["total"]], 12)
        benefit_label.name = "EffectiveBenefit"
        if int(preview["total"]) == 0:
            benefit_label.text = "For future recruits"
        elif int(preview["capped"]) == int(preview["total"]):
            benefit_label.text = "All current units at limit"
            benefit_label.modulate = Color("f1b586")
        elif int(preview["improved"]) == 0:
            benefit_label.text = "No current stat increase"
        benefit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        benefit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.add_child(benefit_label)
        tooltip_text += "\n\nNext pick · Current recruited army"
        for row in preview["rows"]:
            tooltip_text += "\n%s ×%d: %s → %s" % [row["name"], row["count"], UnitInspection.number(float(row["before"])), UnitInspection.number(float(row["after"]))]
        tooltip_text += "\nIncludes theme bonuses, rounding and rating limits. Permanent power also affects future recruits."

static func stack_text(buff: Dictionary, count: int) -> String:
    var limit := int(buff.get("max_stacks", 0))
    return "%d / %d" % [count, limit] if limit > 0 else "%d · No limit" % count
