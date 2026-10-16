extends Control

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var commander_label: Label = $Margin/Main/Header/Commander
@onready var slots_row: HBoxContainer = $Margin/Main/SlotsPanel/Padding/SlotsContent/SlotsRow
@onready var set_progress_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/SetProgress
@onready var bonus_status_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/BonusStatus
@onready var army_status_label: Label = $Margin/Main/SlotsPanel/Padding/SlotsContent/ArmyStatus
@onready var cards_grid: GridContainer = $Margin/Main/CardScroll/CardsGrid

var available_card_buttons: Array[Button] = []

func _ready() -> void:
    back_button.pressed.connect(_go_back)

    var commander := GameState.get_selected_commander()
    if commander.is_empty():
        commander_label.text = "No Commander selected"
        army_status_label.text = "Return and choose a Commander first."
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
        button.custom_minimum_size = Vector2(270, 105)
        button.text = _card_button_text(card)
        button.tooltip_text = "Equip %s" % str(card.get("display_name", card_id))
        button.pressed.connect(_equip_card.bind(card_id))
        available_card_buttons.append(button)
        cards_grid.add_child(button)

func _card_button_text(card: Dictionary) -> String:
    var stats: Dictionary = card.get("stats", {})
    return "%s\n%s • HP %s • ATK %s" % [
        str(card.get("display_name", card.get("id", "Card"))),
        str(card.get("element", "unknown")).capitalize(),
        str(stats.get("health", "—")),
        str(stats.get("attack", "—"))
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
    set_progress_label.text = "Signature Set: %d / %d" % [progress, required]

    if GameState.is_full_set_active():
        bonus_status_label.text = "COMMANDER BONUS: ACTIVE — full signature set equipped"
    else:
        bonus_status_label.text = "Commander Bonus: INACTIVE — equip all signature cards"

    if GameState.army.is_full():
        army_status_label.text = "Army Ready: 4 / 4 cards equipped."
    else:
        army_status_label.text = "Choose %d more card(s): %d / %d equipped." % [
            GameState.army.max_slots - GameState.army.size(),
            GameState.army.size(),
            GameState.army.max_slots
        ]

func _refresh_available_cards() -> void:
    var full := GameState.army.is_full()
    for button in available_card_buttons:
        button.disabled = full

func _go_back() -> void:
    get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
