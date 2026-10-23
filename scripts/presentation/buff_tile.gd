class_name BuffTile
extends Button
## A blessing offer is presentation only. The caller supplies data and handles
## selection through the existing local draft or authoritative online intent.

var definition: Dictionary = {}
var stacks := 0
var side_config: Dictionary = {}
var benefit_label: Label
var _body: VBoxContainer

func _ready() -> void:
    text = ""
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    ScreenStyle.card(self, "")
    var body := VBoxContainer.new()
    _body = body
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
    emblem.custom_minimum_size = Vector2(32, 32) if not side_config.is_empty() else Vector2(48, 48)
    emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    body.add_child(emblem)
    var stat_name := str(definition.get("stat", "Power")).replace("_", " ").capitalize()
    if definition.get("stat") == "movement_speed":
        stat_name = "Move speed"
    var heading := ScreenStyle.label(stat_name if not side_config.is_empty() else str(definition.get("display_name", "Warband blessing")), 18 if not side_config.is_empty() else 20)
    heading.custom_minimum_size.y = 52 if not side_config.is_empty() else 54
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(heading)
    var percentage := int(WarbandStats.power_percentage(side_config, definition))
    var value := ScreenStyle.label("+%d%%" % percentage if not side_config.is_empty() else "+%d%% %s" % [percentage, str(definition.get("stat", "")).replace("_", " ")], 14)
    value.custom_minimum_size.y = 24 if not side_config.is_empty() else 44
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    value.add_theme_color_override("font_color", Color("eed299"))
    body.add_child(value)
    var detail := ScreenStyle.label(("Sudden Death ×2\n%d picks · ∞" if bool(side_config.get("sudden_death", false)) else "%d stacks · ∞") % stacks, 12)
    detail.custom_minimum_size.y = 34 if bool(side_config.get("sudden_death", false)) else 18
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_child(detail)
    tooltip_text = "%s\n+%d%% %s for the whole warband\nCurrent stacks: %s" % [str(definition.get("display_name", "Blessing")), percentage, str(definition.get("stat", "")).replace("_", " "), stack_text(definition, stacks)]

    if bool(side_config.get("sudden_death", false)):
        tooltip_text += "\nThis new pick has double strength. Earlier bonuses keep their original strength."

    var rating_cap := int(ContentDatabase.get_game_balance().get("stats", {}).get(str(definition.get("stat", "")) + "_cap", 0))
    if rating_cap > 0:
        tooltip_text += "\nSpeed rating limit: %d. Additional picks do not increase a rating already at its limit." % rating_cap
    if not side_config.is_empty():
        var preview := WarbandStats.power_preview(side_config, definition, ContentDatabase.get_game_balance().get("stats", {}))
        benefit_label = ScreenStyle.label("Improves %d / %d units" % [preview["improved"], preview["total"]], 12)
        benefit_label.name = "EffectiveBenefit"
        benefit_label.custom_minimum_size.y = 34
        if int(preview["total"]) == 0:
            benefit_label.text = "For future recruits"
        elif int(preview["capped"]) == int(preview["total"]):
            benefit_label.text = "All units at limit"
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
    body.minimum_size_changed.connect(_fit_contents)
    _fit_contents.call_deferred()

func _fit_contents() -> void:
    if is_instance_valid(_body):
        custom_minimum_size.y = maxf(204, _body.get_combined_minimum_size().y + 24)

static func stack_text(buff: Dictionary, count: int) -> String:
    var limit := int(buff.get("max_stacks", 0))
    return "%d / %d" % [count, limit] if limit > 0 else "%d · No limit" % count

static func applied_text(entry: Dictionary) -> String:
    var percentage := int(entry.get("definition", {}).get("percentage", 0))
    var total := int(entry.get("stacks", 0))
    var enhanced := int(entry.get("sudden_death_stacks", 0))
    var parts: Array[String] = []
    if total > enhanced:
        parts.append("+%d%% ×%d" % [percentage, total - enhanced])
    if enhanced > 0:
        parts.append("SD +%d%% ×%d" % [int(percentage * float(entry.get("sudden_death_multiplier", 2))), enhanced])
    return "\n".join(parts)
