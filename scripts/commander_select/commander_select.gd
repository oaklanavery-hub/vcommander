extends Control

@onready var commander_row: GridContainer = $Margin/Main/Body/Gallery/CardsGrid
@onready var commander_name: Label = $Margin/Main/Body/Details/CommanderName
@onready var description_label: Label = $Margin/Main/Body/Details/Description/Padding/Content/Body
@onready var bonus_label: Label = $Margin/Main/Body/Details/Passive/Padding/Content/Body
@onready var skill_label: Label = $Margin/Main/Body/Details/Active/Padding/Content/Body
@onready var full_portrait: CardPortrait = $Margin/Main/Body/Portrait/Content/FullPortrait
@onready var build_army_button: Button = $Margin/Main/Header/Next

var commander_buttons: Dictionary = {}
var selected_commander_id := ""
var mastery_panel := CommanderMasteryPanel.new()

func _ready() -> void:
    ScreenStyle.apply(self)
    ScreenStyle.primary(build_army_button)
    var rewards := Button.new()
    rewards.text = "Rewards"
    rewards.custom_minimum_size = Vector2(110, 46)
    rewards.pressed.connect(func(): ProgressJournal.open(get_tree(), scene_file_path, selected_commander_id))
    $Margin/Main/Header.add_child(rewards)
    mastery_panel.configure(GameState.commander_progress, ContentDatabase, GameAudio)
    $Margin/Main/Body/Portrait/Content.add_child(mastery_panel)
    build_army_button.pressed.connect(_open_army_builder)
    $Margin/Main/Header/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
    if not ContentDatabase.load_errors.is_empty():
        commander_name.text = "Companions could not be loaded"
        description_label.text = "Return to the title and try again."
        build_army_button.disabled = true
        return
    for commander in ContentDatabase.get_all_commanders():
        var id := str(commander.get("id", ""))
        var tile := CardTile.new()
        tile.custom_minimum_size = Vector2(132, 232)
        tile.set_content(commander, true)
        var stats: Dictionary = GameState.commander_progress.record(id)
        tile.mastery_level = int(stats["level"])
        tile.tooltip_text += "\nMastery Level %d · %d matches · %dW / %dL" % [int(stats["level"]), int(stats["played"]), int(stats["wins"]), int(stats["losses"])]
        tile.toggle_mode = true
        tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tile.pressed.connect(_select_commander.bind(id))
        commander_buttons[id] = tile
        commander_row.add_child(tile)
    var initial_id := GameState.selected_commander_id
    if not commander_buttons.has(initial_id) and not commander_buttons.is_empty():
        initial_id = str(commander_buttons.keys()[0])
    _select_commander(initial_id)

func _select_commander(commander_id: String) -> void:
    var commander := ContentDatabase.get_commander(commander_id)
    if commander.is_empty():
        build_army_button.disabled = true
        return
    selected_commander_id = commander_id
    GameState.select_commander(commander_id)
    for id in commander_buttons:
        commander_buttons[id].set_pressed_no_signal(str(id) == commander_id)
        commander_buttons[id].queue_redraw()
    commander_name.text = str(commander.get("display_name", "Commander"))
    description_label.text = str(commander.get("description", "Choose companions to lead into the crossing."))
    full_portrait.set_content(commander, true)
    mastery_panel.show_record(commander_id)
    var signature_set := GameState.get_selected_signature_set()
    var bonus: Dictionary = signature_set.get("bonus", {})
    bonus_label.text = ScreenStyle.bonus_description(bonus) + "\n\nRequires four unique %s cards." % str(commander.get("element", "themed")).capitalize()
    skill_label.text = ScreenStyle.skill_description(commander) + "\n\n1 draft pick · 1/round · 2/match"
    build_army_button.disabled = false

func _open_army_builder() -> void:
    if selected_commander_id.is_empty():
        return
    GameState.select_commander(selected_commander_id)
    if GameState.army.size() == 0:
        for card in ContentDatabase.get_cards_by_set(str(GameState.get_selected_commander().get("signature_set_id", ""))):
            if not GameState.equip_card(str(card["id"])):
                break
    get_tree().change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
