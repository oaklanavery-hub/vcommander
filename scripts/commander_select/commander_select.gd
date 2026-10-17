extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")

@onready var commander_row: HBoxContainer = $Margin/Main/CommanderRow
@onready var commander_name: Label = $Margin/Main/DetailPanel/Padding/Details/CommanderName
@onready var element_label: Label = $Margin/Main/DetailPanel/Padding/Details/Element
@onready var set_name_label: Label = $Margin/Main/DetailPanel/Padding/Details/SetName
@onready var cards_grid: GridContainer = $Margin/Main/DetailPanel/Padding/Details/CardsGrid
@onready var bonus_label: Label = $Margin/Main/DetailPanel/Padding/Details/Bonus
@onready var build_army_button: Button = $Margin/Main/DetailPanel/Padding/Details/BuildArmy

var commander_buttons: Dictionary = {}
var selected_commander_id := ""

func _ready() -> void:
    ScreenStyle.apply(self)
    ScreenStyle.primary(build_army_button)
    build_army_button.pressed.connect(_open_army_builder)

    var summary := ContentDatabase.get_summary()
    if not summary.get("ok", false):
        commander_name.text = "Content data failed to load"
        element_label.text = "Check the Godot output log."
        set_name_label.text = ""
        bonus_label.text = "\n".join(summary.get("errors", []))
        build_army_button.disabled = true
        return

    _populate_commanders()

func _populate_commanders() -> void:
    var all_commanders := ContentDatabase.get_all_commanders()
    if all_commanders.is_empty():
        commander_name.text = "No Commanders found"
        build_army_button.disabled = true
        return

    for commander in all_commanders:
        var commander_id: String = str(commander.get("id", ""))
        var button := Button.new()
        button.custom_minimum_size = Vector2(360, 100)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        ScreenStyle.card(button, str(commander.get("element", "earth")))
        button.add_theme_font_size_override("font_size", 21)
        button.toggle_mode = true
        var themed: Array = ContentDatabase.get_cards_by_set(str(commander.get("signature_set_id", "")))
        if not themed.is_empty():
            var portrait: Dictionary = themed[0]
            button.icon = UnitArt.icon(str(portrait["id"]), str(portrait["role"]), str(portrait["element"]))
            button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        button.text = "%s\n%s" % [
            str(commander.get("display_name", commander_id)),
            str(commander.get("element", "unknown")).capitalize()
        ]
        button.pressed.connect(_select_commander.bind(commander_id))
        commander_buttons[commander_id] = button
        commander_row.add_child(button)

    var initial_id := GameState.selected_commander_id
    if initial_id.is_empty() or ContentDatabase.get_commander(initial_id).is_empty():
        initial_id = str(all_commanders[0].get("id", ""))
    _select_commander(initial_id)

func _select_commander(commander_id: String) -> void:
    var commander := ContentDatabase.get_commander(commander_id)
    if commander.is_empty():
        return

    selected_commander_id = commander_id
    GameState.select_commander(commander_id)
    build_army_button.disabled = false

    for id in commander_buttons:
        commander_buttons[id].button_pressed = str(id) == selected_commander_id

    commander_name.text = str(commander.get("display_name", commander_id))
    element_label.text = ScreenStyle.skill_description(commander)
    element_label.tooltip_text = "Costs one pick. Once per round, twice per match."

    var set_id: String = str(commander.get("signature_set_id", ""))
    var signature_set := ContentDatabase.get_signature_set(set_id)
    if signature_set.is_empty():
        set_name_label.text = "Commander theme missing"
        _clear_cards()
        bonus_label.text = ""
        return

    set_name_label.text = "Commander Theme: %s" % str(signature_set.get("display_name", set_id))
    _show_theme_cards(set_id)

    var bonus: Dictionary = signature_set.get("bonus", {})
    bonus_label.text = "4-card Theme Bonus: +%s%% %s • Any four unique cards from this theme qualify." % [
        str(int(bonus.get("percentage", 0))),
        str(bonus.get("stat", "stat")).replace("_", " ").to_upper()
    ]

func _show_theme_cards(set_id: String) -> void:
    _clear_cards()
    for card in ContentDatabase.get_cards_by_set(set_id):
        cards_grid.add_child(_make_card_preview(card))

func _make_card_preview(card: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(240, 140)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)

    var content := VBoxContainer.new()
    margin.add_child(content)

    var heading := HBoxContainer.new()
    var portrait := TextureRect.new()
    portrait.texture = UnitArt.icon(str(card.get("id", "")), str(card.get("role", "range")), str(card.get("element", "earth")))
    portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.custom_minimum_size = Vector2(38, 38)
    heading.add_child(portrait)
    var heading_text := VBoxContainer.new()
    heading.add_child(heading_text)
    content.add_child(heading)
    var name_label := Label.new()
    name_label.text = str(card.get("display_name", card.get("id", "Card")))
    name_label.add_theme_font_size_override("font_size", 19)
    heading_text.add_child(name_label)

    var role_label := Label.new()
    role_label.text = "%s • %s" % [
        str(card.get("element", "unknown")).capitalize(),
        str(card.get("role", "unit")).capitalize()
    ]
    heading_text.add_child(role_label)

    var stats: Dictionary = card.get("stats", {})
    var stat_label := Label.new()
    stat_label.text = "HP %s • ATK %s • DEF %s" % [
        str(int(stats.get("health", 0))),
        str(int(stats.get("attack", 0))),
        str(int(stats.get("defense", 0)))
    ]
    panel.tooltip_text = stat_label.text
    stat_label.queue_free()

    var draft_label := Label.new()
    draft_label.text = "Recruit %s • Up to %s" % [
        str(int(card.get("summon_amount", 0))),
        str(int(card.get("unit_cap", 0)))
    ]
    content.add_child(draft_label)

    var ability: Dictionary = card.get("ability", {})
    var ability_label := Label.new()
    ability_label.text = str(ability.get("display_name", ability.get("id", "Ability")))
    content.add_child(ability_label)

    return panel

func _clear_cards() -> void:
    for child in cards_grid.get_children():
        child.queue_free()

func _open_army_builder() -> void:
    if selected_commander_id.is_empty():
        return
    GameState.select_commander(selected_commander_id)
    if GameState.army.size() == 0:
        for card in ContentDatabase.get_cards_by_set(str(GameState.get_selected_commander().get("signature_set_id", ""))):
            if not GameState.equip_card(str(card["id"])):
                break
    get_tree().change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
