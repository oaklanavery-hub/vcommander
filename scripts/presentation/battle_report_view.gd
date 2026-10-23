class_name BattleReportView
extends CanvasLayer

signal closed
var report: Dictionary = {}
var selected_side := "player"
var overlay := Control.new()
var _body: VBoxContainer
var _detail: Label
var _tabs: Dictionary = {}
var _previous_focus: Control

func _ready() -> void:
    layer = 35
    add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.hide()

func open(value: Dictionary, round_number: int) -> void:
    report = value
    _previous_focus = get_viewport().gui_get_focus_owner()
    for child in overlay.get_children():
        overlay.remove_child(child)
        child.queue_free()
    var dimmer := ColorRect.new()
    dimmer.color = Color(0.02, 0.04, 0.03, 0.94)
    overlay.add_child(dimmer)
    dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin := MarginContainer.new()
    overlay.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + edge, 24)
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("292e26"), Color("ae905a"), 16))
    margin.add_child(panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    panel.add_child(body)
    var header := HBoxContainer.new()
    body.add_child(header)
    var title := ScreenStyle.label("Battle report · Round %d" % round_number, 30)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var close_button := Button.new()
    close_button.text = "Back to battle ×"
    close_button.custom_minimum_size.y = 42
    close_button.pressed.connect(close)
    header.add_child(close_button)
    var tabs := HBoxContainer.new()
    body.add_child(tabs)
    _tabs.clear()
    for side in ["player", "opponent"]:
        var button := Button.new()
        button.text = "Your warband" if side == "player" else "Rival warband"
        button.toggle_mode = true
        button.custom_minimum_size = Vector2(180, 40)
        button.pressed.connect(_select_side.bind(side))
        tabs.add_child(button)
        _tabs[side] = button
    _body = VBoxContainer.new()
    _body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body.add_theme_constant_override("separation", 8)
    var page_scroll := ScrollContainer.new()
    page_scroll.name = "ReportScroll"
    page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    body.add_child(page_scroll)
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page_scroll.add_child(_body)
    var note := ScreenStyle.label("Damage excludes overkill · Healing excludes overheal · Protection = HP lost + absorbed damage\nBodies alive includes splits and revivals. Select a row for its survival and ability details.", 14)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.tooltip_text = note.text
    _body.set_meta("report_note", note.text)
    note.queue_free()
    overlay.show()
    _select_side("player")
    close_button.grab_focus()

func _select_side(side: String) -> void:
    selected_side = side
    for key in _tabs:
        _tabs[key].set_pressed_no_signal(key == side)
    for child in _body.get_children():
        _body.remove_child(child)
        child.queue_free()
    var data: Dictionary = report.get("sides", {}).get(side, {})
    var highlights: Dictionary = data.get("highlights", {})
    var honors := HBoxContainer.new()
    honors.add_theme_constant_override("separation", 12)
    _body.add_child(honors)
    for metric in ["damage", "protection", "healing"]:
        var award: Dictionary = highlights.get(metric, {})
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("34382b"), Color("766d46"), 10))
        honors.add_child(panel)
        var text: String = str(metric).capitalize() + " highlight\n"
        text += str(award.get("name", "—"))
        if not award.is_empty():
            text += " · " + UnitInspection.number(float(award.get("value", 0)))
        var label := ScreenStyle.label(text, 17)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        panel.add_child(label)
    var recap: Dictionary = data.get("recap", {})
    if not recap.get("facts", []).is_empty():
        var evidence := ScreenStyle.label("Observed: " + "  ·  ".join(recap["facts"]), 16)
        evidence.name = "BattleObservations"
        evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(evidence)
        var advice := ScreenStyle.label("Try next time: " + str(recap.get("suggestion", "")), 14)
        advice.name = "BattleSuggestion"
        advice.modulate = Color("c7d0b5")
        advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(advice)
    var columns := _columns(["Companion", "Damage", "Healing", "HP lost / absorbed", "KOs", "Bodies alive"], true)
    _body.add_child(columns)
    var rows := VBoxContainer.new()
    rows.name = "CompanionRows"
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override("separation", 6)
    _body.add_child(rows)
    for row in data.get("rows", []):
        var button := Button.new()
        button.custom_minimum_size.y = 48
        button.tooltip_text = "Show survival and ability details"
        rows.add_child(button)
        var labels := _columns([str(row.get("name", "Unit")), UnitInspection.number(float(row.get("damage", 0))), UnitInspection.number(float(row.get("healing", 0))), UnitInspection.number(float(row.get("taken", 0))) + " / " + UnitInspection.number(float(row.get("absorbed", 0))), str(row.get("kills", 0)), "%d / %d" % [int(row.get("survived", 0)), int(row.get("spawned", 0))]])
        labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(labels)
        labels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        labels.offset_left = 14
        labels.offset_right = -14
        button.pressed.connect(_show_detail.bind(row))
    if data.get("rows", []).is_empty():
        rows.add_child(ScreenStyle.label("No units were recorded for this side.", 18))
    var totals: Dictionary = data.get("totals", {})
    _body.add_child(ScreenStyle.label("Warband totals   ·   Damage %s   ·   Healing %s   ·   Absorbed %s   ·   KOs %d" % [UnitInspection.number(float(totals.get("damage", 0))), UnitInspection.number(float(totals.get("healing", 0))), UnitInspection.number(float(totals.get("absorbed", 0))), int(totals.get("kills", 0))], 17))
    _detail = ScreenStyle.label("Each companion type has one row. Every body it creates contributes to that row.", 15)
    _detail.custom_minimum_size.y = 48
    _detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(_detail)
    var note := ScreenStyle.label(str(_body.get_meta("report_note", "")), 14)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(note)

func _columns(values: Array, heading: bool = false) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    var weights := [2.1, 1.0, 1.0, 1.7, 0.5, 1.0]
    for index in range(values.size()):
        var label := ScreenStyle.label(str(values[index]), 14 if heading else 16)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.size_flags_stretch_ratio = weights[index]
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        if index > 0:
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        row.add_child(label)
    return row

func _show_detail(row: Dictionary) -> void:
    if int(row.get("spawned", 0)) == 0:
        _detail.text = str(row.get("name", "Effects")) + " · Damage and healing are credited separately from companions."
    else:
        _detail.text = "%s · %d initial bodies · %d created in total · %d survived\nAverage body survival %.1fs · %d ability activations" % [str(row.get("name", "Unit")), int(row.get("initial", 0)), int(row.get("spawned", 0)), int(row.get("survived", 0)), float(row.get("average_survival", 0)), int(row.get("abilities", 0))]

func close() -> void:
    overlay.hide()
    if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()
    closed.emit()

func _input(event: InputEvent) -> void:
    if overlay.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        close()
        get_viewport().set_input_as_handled()
