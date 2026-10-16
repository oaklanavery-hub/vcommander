extends Control

@onready var commander_row: HBoxContainer = $Margin/Main/CommanderRow
@onready var commander_name: Label = $Margin/Main/DetailPanel/Padding/Details/CommanderName
@onready var element_label: Label = $Margin/Main/DetailPanel/Padding/Details/Element
@onready var set_name_label: Label = $Margin/Main/DetailPanel/Padding/Details/SetName
@onready var cards_grid: GridContainer = $Margin/Main/DetailPanel/Padding/Details/CardsGrid
@onready var bonus_label: Label = $Margin/Main/DetailPanel/Padding/Details/Bonus

var commander_buttons: Dictionary = {}
var selected_commander_id := ""

func _ready() -> void:
    var summary := ContentDatabase.get_summary()
    if not summary.get("ok", false):
        commander_name.text = "Content data failed to load"
        element_label.text = "Check the Godot output log."
        set_name_label.text = ""
        bonus_label.text = "\n".join(summary.get("errors", []))
        return

    _populate_commanders()

func _populate_commanders() -> void:
    var all_commanders := ContentDatabase.get_all_commanders()
    if all_commanders.is_empty():
        commander_name.text = "No Commanders found"
        return

    for commander in all_commanders:
        var commander_id: String = str(commander.get("id", ""))
        var button := Button.new()
        button.custom_minimum_size = Vector2(220, 82)
        button.toggle_mode = true
        button.text = "%s\n%s" % [
            str(commander.get("display_name", commander_id)),
            str(commander.get("element", "unknown")).capitalize()
        ]
        button.pressed.connect(_select_commander.bind(commander_id))
        commander_buttons[commander_id] = button
        commander_row.add_child(button)

    _select_commander(str(all_commanders[0].get("id", "")))

func _select_commander(commander_id: String) -> void:
    var commander := ContentDatabase.get_commander(commander_id)
    if commander.is_empty():
        return

    selected_commander_id = commander_id
    for id in commander_buttons:
        commander_buttons[id].button_pressed = str(id) == selected_commander_id

    commander_name.text = str(commander.get("display_name", commander_id))
    element_label.text = "Element: %s" % str(commander.get("element", "unknown")).capitalize()

    var set_id: String = str(commander.get("signature_set_id", ""))
    var signature_set := ContentDatabase.get_signature_set(set_id)
    if signature_set.is_empty():
        set_name_label.text = "Signature set missing"
        _clear_cards()
        bonus_label.text = ""
        return

    set_name_label.text = "Signature Set: %s" % str(signature_set.get("display_name", set_id))
    _show_signature_cards(signature_set.get("required_card_ids", []))

    var bonus: Dictionary = signature_set.get("bonus", {})
    if str(bonus.get("status", "")) == "design_pending":
        bonus_label.text = "Full-set Commander Bonus: design pending. It will activate only when all 4 signature cards are equipped."
    else:
        bonus_label.text = "Full-set Commander Bonus configured."

func _show_signature_cards(card_ids: Array) -> void:
    _clear_cards()
    var card_definitions := ContentDatabase.get_cards_by_ids(card_ids)
    for card in card_definitions:
        cards_grid.add_child(_make_card_preview(card))

func _make_card_preview(card: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(245, 150)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)

    var content := VBoxContainer.new()
    margin.add_child(content)

    var name_label := Label.new()
    name_label.text = str(card.get("display_name", card.get("id", "Card")))
    name_label.add_theme_font_size_override("font_size", 19)
    content.add_child(name_label)

    var element := Label.new()
    element.text = str(card.get("element", "unknown")).capitalize()
    content.add_child(element)

    var stats: Dictionary = card.get("stats", {})
    var stat_label := Label.new()
    stat_label.text = "HP %s  •  ATK %s  •  SPD %s" % [
        str(stats.get("health", "—")),
        str(stats.get("attack", "—")),
        str(stats.get("attack_speed", "—"))
    ]
    content.add_child(stat_label)

    var placeholder := Label.new()
    placeholder.text = "Placeholder data"
    content.add_child(placeholder)

    return panel

func _clear_cards() -> void:
    for child in cards_grid.get_children():
        child.queue_free()
