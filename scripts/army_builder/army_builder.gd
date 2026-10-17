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

func _ready() -> void:
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
        button.custom_minimum_size = Vector2(270, 120)
        button.text = _card_button_text(card)
        button.icon = UnitArt.icon(card_id, str(card.get("role", "range")), str(card.get("element", "earth")))
        button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        button.add_theme_constant_override("icon_max_width", 40)
        button.tooltip_text = "Equip %s" % str(card.get("display_name", card_id))
        button.pressed.connect(_equip_card.bind(card_id))
        available_card_buttons[card_id] = button
        cards_grid.add_child(button)

func _card_button_text(card: Dictionary) -> String:
    var stats: Dictionary = card.get("stats", {})
    return "%s\n%s • %s\nHP %s • ATK %s • DEF %s\nSummon +%s • Cap %s" % [
        str(card.get("display_name", card.get("id", "Card"))),
        str(card.get("element", "unknown")).capitalize(),
        str(card.get("role", "unit")).capitalize(),
        str(int(stats.get("health", 0))),
        str(int(stats.get("attack", 0))),
        str(int(stats.get("defense", 0))),
        str(int(card.get("summon_amount", 0))),
        str(int(card.get("unit_cap", 0)))
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
        slot.custom_minimum_size = Vector2(270, 84)
        if index < equipped.size():
            var card := ContentDatabase.get_card(equipped[index])
            slot.text = "Slot %d\n%s\nClick to remove" % [
                index + 1,
                str(card.get("display_name", equipped[index]))
            ]
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
