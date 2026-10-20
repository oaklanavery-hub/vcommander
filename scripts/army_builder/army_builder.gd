extends Control

@onready var back_button: Button = $Margin/Main/Setup/Actions/Navigation/Back
@onready var begin_draft_button: Button = $Margin/Main/Setup/Actions/Navigation/Battle
@onready var commander_label: Label = $Margin/Main/Setup/Actions/Commander
@onready var slots_row: HBoxContainer = $Margin/Main/Setup/SlotsRow
@onready var army_status_label: Label = $Margin/Main/Setup/Actions/Status
@onready var cards_grid: GridContainer = $Margin/Main/CardScroll/CardsGrid
@onready var seed_input: LineEdit = $Margin/Main/Setup/Actions/Advanced/Seed
@onready var theme_button: Button = $Margin/Main/Setup/Actions/Advanced/ThemeArmy
@onready var filter_select: OptionButton = $Margin/Main/Header/Filter
@onready var save_button: Button = $Margin/Main/Setup/Actions/Presets/Save

var available_card_buttons: Dictionary = {}
var preset_store: WarbandPresets
var _preset_index := 0
var _filter := "all"
var _preset_buttons: Array[Button] = []
var friend_button: Button

func _ready() -> void:
    preset_store = WarbandPresets.new(ContentDatabase, WarbandPresets.DEFAULT_PATH, 4, GameState.commander_progress)
    ScreenStyle.apply(self)
    ScreenStyle.primary(begin_draft_button)
    var rewards := Button.new()
    rewards.text = "Rewards"
    rewards.custom_minimum_size = Vector2(110, 42)
    rewards.pressed.connect(func(): ProgressJournal.open(get_tree(), scene_file_path, GameState.selected_commander_id))
    $Margin/Main/Header.add_child(rewards)
    back_button.pressed.connect(_go_back)
    begin_draft_button.pressed.connect(_begin_draft)
    friend_button = Button.new()
    friend_button.text = "Friend match" if OnlineSession.available else "PvP · Coming Soon"
    friend_button.custom_minimum_size = Vector2(156, 54)
    friend_button.visible = true
    friend_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/online/private_room.tscn"))
    var actions := get_node("Margin/Main/Setup/Actions/Navigation")
    actions.add_child(friend_button)
    theme_button.pressed.connect(_equip_theme)
    save_button.pressed.connect(_save_preset)
    $Margin/Main/Setup/Actions/Presets/Clear.pressed.connect(_clear_army)
    $Margin/Main/Setup/Actions/Options.pressed.connect(func():
        var advanced := get_node("Margin/Main/Setup/Actions/Advanced")
        advanced.visible = not advanced.visible)
    for index in range(WarbandPresets.SLOT_COUNT):
        var button: Button = get_node("Margin/Main/Setup/Actions/Presets/Preset%d" % (index + 1))
        _preset_buttons.append(button)
        button.pressed.connect(_load_preset.bind(index))
    filter_select.add_item("All elements")
    filter_select.set_item_metadata(0, "all")
    filter_select.add_item("Commander theme")
    filter_select.set_item_metadata(1, "theme")
    var elements: Array[String] = []
    for card in ContentDatabase.get_all_cards():
        var element := str(card.get("element", ""))
        if not elements.has(element):
            elements.append(element)
    elements.sort()
    for element in elements:
        filter_select.add_item(element.capitalize())
        filter_select.set_item_metadata(filter_select.item_count - 1, element)
    filter_select.item_selected.connect(_select_filter)
    var commander := GameState.get_selected_commander()
    if commander.is_empty():
        begin_draft_button.disabled = true
        army_status_label.text = "Choose a Commander before building a warband."
        return
    commander_label.text = str(commander.get("display_name", "Commander"))
    _populate_available_cards()
    _refresh()

func _populate_available_cards() -> void:
    for card in ContentDatabase.get_all_cards():
        var id := str(card.get("id", ""))
        var tile := CardTile.new()
        tile.set_content(card)
        tile.locked = not GameState.commander_progress.is_card_unlocked(id)
        if card.has("mastery_unlock"):
            tile.tooltip_text += "\n\n" + GameState.commander_progress.unlock_description(id)
            tile.tooltip_text += "\nOpen Rewards to see your progress." if tile.locked else "\nMastery reward unlocked."
        tile.toggle_mode = true
        tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tile.pressed.connect(_card_pressed.bind(id))
        available_card_buttons[id] = tile
        cards_grid.add_child(tile)

func _card_pressed(card_id: String) -> void:
    if not GameState.commander_progress.is_card_unlocked(card_id):
        var reward := GameState.commander_progress.card_reward(card_id)
        ProgressJournal.open(get_tree(), scene_file_path, str(reward.get("commander_id", "")))
        return
    if GameState.army.contains(card_id):
        _unequip_slot(GameState.army.get_cards().find(card_id))
    else:
        _equip_card(card_id)

func _equip_card(card_id: String) -> void:
    if GameState.equip_card(card_id):
        GameAudio.play_effect("pick")
        _refresh()
    else:
        _refresh_available_cards()
        army_status_label.text = "Locked · " + GameState.commander_progress.unlock_description(card_id) if not GameState.commander_progress.is_card_unlocked(card_id) else "Your warband is full. Remove a card before adding another."

func _unequip_slot(index: int) -> void:
    if GameState.unequip_card_at(index):
        _refresh()

func _refresh() -> void:
    for child in slots_row.get_children():
        slots_row.remove_child(child)
        child.queue_free()
    var cards: Array[String] = GameState.army.get_cards()
    for index in range(GameState.army.max_slots):
        var tile := CardTile.new()
        tile.custom_minimum_size = Vector2(132, 184)
        if index < cards.size():
            tile.set_content(ContentDatabase.get_card(cards[index]))
            tile.tooltip_text += "\nClick to remove from your warband."
            tile.pressed.connect(_unequip_slot.bind(index))
        else:
            tile.empty_caption = "Slot %d" % (index + 1)
        slots_row.add_child(tile)
    begin_draft_button.disabled = not GameState.army.is_full()
    friend_button.disabled = not OnlineSession.available or OnlineSession.endpoint.is_empty() or not GameState.army.is_full()
    save_button.disabled = not GameState.army.is_full()
    var bonus: Dictionary = GameState.get_selected_signature_set().get("bonus", {})
    if GameState.army.is_full():
        army_status_label.text = "4 / 4 companions ready"
        army_status_label.text += " • " + ScreenStyle.bonus_description(bonus, true) if GameState.is_full_set_active() else " • Mixed warband"
    else:
        army_status_label.text = "Choose %d more companion%s" % [GameState.army.max_slots - cards.size(), "" if cards.size() == 3 else "s"]
    _refresh_available_cards()
    _refresh_presets()

func _refresh_available_cards() -> void:
    var theme := str(GameState.get_selected_commander().get("signature_set_id", ""))
    for id in available_card_buttons:
        var tile: CardTile = available_card_buttons[id]
        var card := ContentDatabase.get_card(str(id))
        tile.visible = _filter == "all" or (_filter == "theme" and str(card.get("set_id", "")) == theme) or str(card.get("element", "")) == _filter
        tile.set_pressed_no_signal(GameState.army.contains(str(id)))
        tile.queue_redraw()

func _select_filter(index: int) -> void:
    _filter = str(filter_select.get_item_metadata(index))
    _refresh_available_cards()

func _toggle_filter() -> void:
    filter_select.select(1 if _filter == "all" else 0)
    _select_filter(filter_select.selected)

func _refresh_presets() -> void:
    for index in range(_preset_buttons.size()):
        var button := _preset_buttons[index]
        button.set_pressed_no_signal(index == _preset_index)
        var saved := not preset_store.load_slot(GameState.selected_commander_id, index).is_empty()
        button.tooltip_text = "Load saved warband" if saved else "Empty slot. Select it, then Save your current warband."

func _load_preset(index: int) -> void:
    _preset_index = index
    var cards := preset_store.load_slot(GameState.selected_commander_id, index)
    if cards.is_empty():
        _refresh_presets()
        army_status_label.text = "Preset %d is empty or includes a locked card. Build a warband, then Save." % (index + 1)
        return
    GameState.clear_army()
    for id in cards:
        GameState.equip_card(id)
    _refresh()
    army_status_label.text = "Preset %d loaded • 4 / 4 companions ready" % (index + 1)

func _save_preset() -> void:
    var error := preset_store.save_slot(GameState.selected_commander_id, _preset_index, GameState.army.get_cards())
    army_status_label.text = "Saved to Preset %d" % (_preset_index + 1) if error == OK else "Could not save. Fill all four slots and try again."
    _refresh_presets()

func _clear_army() -> void:
    GameState.clear_army()
    _refresh()

func _equip_theme() -> void:
    var cards := ContentDatabase.get_cards_by_set(str(GameState.get_selected_commander().get("signature_set_id", "")))
    if cards.size() < GameState.army.max_slots:
        return
    GameState.clear_army()
    for index in range(GameState.army.max_slots):
        GameState.equip_card(str(cards[index]["id"]))
    _refresh()

func _begin_draft() -> void:
    var seed_value := int(Time.get_unix_time_from_system() * 1000.0)
    var requested := seed_input.text.strip_edges()
    if not requested.is_empty():
        if not requested.is_valid_int():
            army_status_label.text = "Use a whole number for the match seed."
            seed_input.grab_focus()
            return
        seed_value = int(requested)
    if GameState.begin_match(seed_value):
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn")

func _go_back() -> void:
    get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
