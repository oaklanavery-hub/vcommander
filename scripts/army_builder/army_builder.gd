extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var commander_label: Label = $Margin/Main/Header/Commander
@onready var slots_row: HBoxContainer = $Margin/Main/SlotsPanel/Padding/SlotsContent/SlotsRow
@onready var set_progress_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/SetProgress
@onready var bonus_status_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/BonusStatus
@onready var army_status_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/ArmyStatus
@onready var cards_grid: GridContainer = $Margin/Main/CardScroll/CardsGrid
@onready var seed_input: LineEdit = $Margin/Main/SeedRow/Seed
@onready var theme_button: Button = $Margin/Main/SeedRow/ThemeArmy
@onready var begin_draft_button: Button = $Margin/Main/BeginDraft

var available_card_buttons: Dictionary = {}
var _show_all := false
var _filter_button := Button.new()

func _ready() -> void:
    ScreenStyle.apply(self)
    ScreenStyle.primary(begin_draft_button)
    _filter_button.text = "Browse other elements"
    _filter_button.pressed.connect(_toggle_filter)
    var main := get_node("Margin/Main")
    main.add_child(_filter_button)
    main.move_child(_filter_button, get_node("Margin/Main/CardScroll").get_index())
    get_node("Margin/Main/SeedRow/SeedLabel").hide()
    seed_input.hide()
    var advanced := Button.new()
    advanced.text = "Advanced"
    advanced.pressed.connect(func():
        seed_input.visible = not seed_input.visible
        get_node("Margin/Main/SeedRow/SeedLabel").visible = seed_input.visible)
    get_node("Margin/Main/SeedRow").add_child(advanced)
    back_button.pressed.connect(_go_back)
    theme_button.pressed.connect(_equip_theme)
    begin_draft_button.pressed.connect(_begin_draft)

    var commander := GameState.get_selected_commander()
    if commander.is_empty():
        commander_label.text = "No Commander selected"
        army_status_label.text = "Return and choose a Commander first."
        begin_draft_button.disabled = true
        return

    commander_label.text = "%s • %s" % [
        str(commander.get("display_name", "Commander")),
        str(commander.get("element", "unknown")).capitalize()
    ]

    _populate_available_cards()
    _refresh()

func _populate_available_cards() -> void:
    for card in ContentDatabase.get_all_cards():
        var card_id: String = str(card.get("id", ""))
        var button := Button.new()
        button.custom_minimum_size = Vector2(250, 104)
        button.text = _card_button_text(card)
        button.icon = UnitArt.icon(card_id, str(card.get("role", "range")), str(card.get("element", "earth")))
        button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        ScreenStyle.card(button, str(card.get("element", "earth")))
        button.tooltip_text = "HP %d • Attack %d • Defense %d\n%s" % [int(card.get("stats", {}).get("health", 0)), int(card.get("stats", {}).get("attack", 0)), int(card.get("stats", {}).get("defense", 0)), str(card.get("ability", {}).get("display_name", ""))]
        button.pressed.connect(_equip_card.bind(card_id))
        available_card_buttons[card_id] = button
        cards_grid.add_child(button)

func _card_button_text(card: Dictionary) -> String:
    return "%s\n%s • Recruit %d\n%s" % [
        str(card.get("display_name", "Companion")),
        str(card.get("role", "unit")).capitalize(),
        int(card.get("summon_amount", 0)),
        str(card.get("ability", {}).get("display_name", ""))
    ]

func _equip_card(card_id: String) -> void:
    if GameState.equip_card(card_id):
        _refresh()

func _unequip_slot(index: int) -> void:
    if GameState.unequip_card_at(index):
        _refresh()

func _refresh() -> void:
    _refresh_slots()
    _refresh_set_status()
    _refresh_available_cards()
    begin_draft_button.disabled = not GameState.army.is_full()

func _refresh_slots() -> void:
    for child in slots_row.get_children():
        child.queue_free()

    var equipped: Array[String] = GameState.army.get_cards()
    for index in range(GameState.army.max_slots):
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(250, 80)
        if index < equipped.size():
            var card := ContentDatabase.get_card(equipped[index])
            slot.text = str(card.get("display_name", equipped[index])) + "\nIn your warband"
            slot.icon = UnitArt.icon(str(card["id"]), str(card["role"]), str(card["element"]))
            slot.add_theme_constant_override("icon_max_width", 40)
            slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            slot.tooltip_text = "Click to remove this companion"
            slot.pressed.connect(_unequip_slot.bind(index))
        else:
            slot.text = "Slot %d\nEmpty" % (index + 1)
            slot.disabled = true
        slots_row.add_child(slot)

func _refresh_set_status() -> void:
    var progress := GameState.get_signature_progress()
    var required := GameState.get_signature_required_count()
    set_progress_label.text = "Commander Theme: %d / %d matching cards" % [progress, required]

    var signature_set := GameState.get_selected_signature_set()
    var bonus: Dictionary = signature_set.get("bonus", {})
    var bonus_text := "+%s%% %s" % [
        str(int(bonus.get("percentage", 0))),
        str(bonus.get("stat", "stat")).replace("_", " ").to_upper()
    ]

    if GameState.is_full_set_active():
        bonus_status_label.text = "COMMANDER BONUS ACTIVE — %s" % bonus_text
    else:
        bonus_status_label.text = "Commander Bonus INACTIVE — all 4 cards must match this Commander theme"

    if GameState.army.is_full():
        army_status_label.text = "Army Ready: 4 / 4 unique cards equipped."
    else:
        army_status_label.text = "Choose %d more unique card(s): %d / %d equipped." % [
            GameState.army.max_slots - GameState.army.size(),
            GameState.army.size(),
            GameState.army.max_slots
        ]

func _refresh_available_cards() -> void:
    var full := GameState.army.is_full()
    for card_id in available_card_buttons:
        var button: Button = available_card_buttons[card_id]
        var card := ContentDatabase.get_card(str(card_id))
        button.visible = _show_all or str(card.get("set_id", "")) == str(GameState.get_selected_commander().get("signature_set_id", ""))
        button.disabled = full or GameState.army.contains(str(card_id))

func _begin_draft() -> void:
    var seed_value := int(Time.get_unix_time_from_system() * 1000.0)
    var requested_seed := seed_input.text.strip_edges()
    if not requested_seed.is_empty():
        if not requested_seed.is_valid_int():
            army_status_label.text = "Enter a whole number for the match seed."
            seed_input.grab_focus()
            return
        seed_value = int(requested_seed)
    if GameState.begin_match(seed_value):
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn")

func _go_back() -> void:
    get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")

func _equip_theme() -> void:
    var commander: Dictionary = GameState.get_selected_commander()
    var themed: Array = ContentDatabase.get_cards_by_set(str(commander.get("signature_set_id", "")))
    if themed.size() < GameState.army.max_slots:
        return
    GameState.clear_army()
    for index in range(GameState.army.max_slots):
        GameState.equip_card(str(themed[index]["id"]))
    _refresh()

func _toggle_filter() -> void:
    _show_all = not _show_all
    _filter_button.text = "Show Commander companions" if _show_all else "Browse other elements"
    _refresh_available_cards()
