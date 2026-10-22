extends Control

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
const SELECTION_SECONDS := 30.0

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var offer_content: VBoxContainer = $Margin/Main/Board/Padding/Arena/DraftCenter/OfferPanel/Padding/OfferContent
@onready var offer_row: HBoxContainer = offer_content.get_node("OfferRow")
@onready var skill_button: Button = offer_content.get_node("CommanderSkill")
@onready var battle_button: Button = offer_content.get_node("StartBattle")
@onready var selections_label: Label = offer_content.get_node("Selections")
@onready var player_roster: WarbandRoster = $Margin/Main/Board/Padding/PlayerRoster
@onready var opponent_roster: WarbandRoster = $Margin/Main/Board/Padding/OpponentRoster
@onready var army_summary: RichTextLabel = player_roster.summary
@onready var buff_summary: RichTextLabel = player_roster.buffs
@onready var opponent_summary: RichTextLabel = opponent_roster.summary
@onready var footer: Label = $Margin/Main/Footer

var _time_left: float = SELECTION_SECONDS
var _timer_bar := ProgressBar.new()
var _hearts_meter := MatchStatus.new()
var round_label: Label = _hearts_meter.round_label
var timer_label: Label = _hearts_meter.timer_label

func _ready() -> void:
    ScreenStyle.apply(self)
    _hearts_meter.name = "MatchHearts"
    var main := get_node("Margin/Main")
    main.add_child(_hearts_meter)
    main.move_child(_hearts_meter, 1)
    ScreenStyle.primary(battle_button)
    _timer_bar.max_value = SELECTION_SECONDS
    _timer_bar.show_percentage = false
    _timer_bar.custom_minimum_size.y = 6
    _timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    offer_content.add_child(_timer_bar)
    offer_content.move_child(_timer_bar, 2)
    back_button.pressed.connect(_go_back)
    skill_button.pressed.connect(_use_commander_skill)
    battle_button.pressed.connect(_start_battle)

    if not GameState.match_started:
        footer.text = "No active draft. Return to the Army Builder."
        skill_button.disabled = true
        battle_button.visible = false
        set_process(false)
        return

    _refresh_all()

func _process(delta: float) -> void:
    if GameState.draft.is_phase_complete():
        return

    _time_left = maxf(0.0, _time_left - delta)
    timer_label.text = "%02ds to choose" % int(ceil(_time_left))
    _timer_bar.value = _time_left
    timer_label.modulate = Color("f1a27b") if _time_left < 6 else Color.WHITE
    if _time_left <= 0.0:
        if GameState.draft.auto_select():
            _time_left = SELECTION_SECONDS
            _refresh_all()

func _refresh_all() -> void:
    _hearts_meter.refresh(GameState.match_state)
    var commander: Dictionary = GameState.get_selected_commander()
    _hearts_meter.set_commanders(commander, GameState.opponent_public_side.get("commander", {}))
    var round_number: int = GameState.match_state.round_number
    round_label.text = "Round %d · %s" % [round_number, "Sudden Death" if GameState.match_state.sudden_death else "Draft"]
    battle_button.text = "Start Battle %d" % round_number
    selections_label.text = "Selections left: %d" % GameState.draft.selection_points
    timer_label.text = "%02ds to choose" % int(ceil(_time_left))
    _timer_bar.value = _time_left
    timer_label.modulate = Color("f1a27b") if _time_left < 6 else Color.WHITE

    _refresh_offer()
    _refresh_skill(commander)
    _refresh_summaries()

    var complete: bool = bool(GameState.draft.is_phase_complete())
    offer_row.visible = not complete
    _timer_bar.visible = not complete
    offer_content.get_node("Prompt").text = "Your warband is ready" if complete else "Choose one card to grow your warband"
    battle_button.visible = complete
    battle_button.disabled = not complete
    if complete:
        footer.text = "Ready for battle • Enter to begin. The rival reveals new picks at combat."
        timer_label.text = "Draft complete"
    else:
        if GameState.match_state.sudden_death:
            footer.text = "Sudden Death: three selections each. Win a battle outright to win the match."
        elif GameState.match_state.round_number == 1:
            footer.text = "Round 1 is Army-only. Every pick rerolls all three choices."
        else:
            footer.text = "Armies and buffs persist. All units respawn at full HP each battle."
    FirstMatchGuide.draft_updated()

func _refresh_offer() -> void:
    for child in offer_row.get_children():
        offer_row.remove_child(child)
        child.queue_free()

    for index in range(GameState.draft.current_offer.size()):
        var option: Dictionary = GameState.draft.current_offer[index]
        var button: Button
        if option.get("type") == "unit":
            var card: Dictionary = ContentDatabase.get_card(str(option["id"]))
            var tile := CardTile.new()
            tile.set_content(card)
            var current: int = GameState.draft.get_unit_count(str(option["id"]))
            tile.detail_text = "%d → %d / %d" % [current, mini(int(card["unit_cap"]), current + int(card["summon_amount"])), int(card["unit_cap"])]
            tile.tooltip_text += "\nPick with " + str(index + 1)
            button = tile
        else:
            var blessing := BuffTile.new()
            blessing.definition = ContentDatabase.get_buff(str(option["id"]))
            blessing.stacks = GameState.draft.get_buff_stacks(str(option["id"]))
            button = blessing
        button.custom_minimum_size = Vector2(156, 204)
        button.disabled = GameState.draft.is_phase_complete()
        button.pressed.connect(_select_offer.bind(index))
        offer_row.add_child(button)

func _option_text(option: Dictionary) -> String:
    var option_type := str(option.get("type", ""))
    var option_id := str(option.get("id", ""))

    if option_type == "unit":
        var card: Dictionary = ContentDatabase.get_card(option_id)
        var current: int = GameState.draft.get_unit_count(option_id)
        var amount: int = int(card.get("summon_amount", 0))
        var cap: int = int(card.get("unit_cap", 0))
        var after: int = mini(cap, current + amount)
        return "%s\n%s • %s\nSummon +%d\n%d/%d → %d/%d" % [
            str(card.get("display_name", option_id)),
            str(card.get("element", "")).capitalize(),
            str(card.get("role", "unit")).capitalize(),
            amount,
            current,
            cap,
            after,
            cap
        ]

    var buff: Dictionary = ContentDatabase.get_buff(option_id)
    var stack: int = GameState.draft.get_buff_stacks(option_id)
    return "%s\n+%s%% %s\nStacks %s" % [
        str(buff.get("display_name", option_id)),
        str(int(buff.get("percentage", 0))),
        str(buff.get("stat", "stat")).replace("_", " ").to_upper(),
        BuffTile.stack_text(buff, stack)
    ]

func _refresh_skill(commander: Dictionary) -> void:
    var skill: Dictionary = commander.get("active_skill", {})
    skill_button.tooltip_text = ScreenStyle.skill_description(commander)
    skill_button.text = "%s\nCost: 1 selection • Uses left: %d/2" % [
        str(skill.get("display_name", "Commander Skill")),
        GameState.draft.commander_skill_uses_remaining()
    ]
    if GameState.draft.commander_skill_used_this_round:
        skill_button.text += " • Prepared for battle"
    skill_button.disabled = (
        GameState.draft.is_phase_complete()
        or GameState.draft.commander_skill_used_this_round
        or GameState.draft.commander_skill_uses_remaining() <= 0
    )

func _refresh_summaries() -> void:
    player_roster.set_side(GameState.get_player_combat_side())
    opponent_roster.set_side(GameState.opponent_public_side, true, true)

func _select_offer(index: int) -> void:
    var option: Dictionary = GameState.draft.current_offer[index] if index >= 0 and index < GameState.draft.current_offer.size() else {}
    if GameState.draft.select_offer(index):
        player_roster.highlighted_card = str(option.get("id", "")) if option.get("type") == "unit" else ""
        GameAudio.play_effect("pick")
        _time_left = SELECTION_SECONDS
        _refresh_all()

func _use_commander_skill() -> void:
    if GameState.draft.use_commander_skill():
        GameAudio.play_effect("commander_skill")
        _time_left = SELECTION_SECONDS
        _refresh_all()

func _start_battle() -> void:
    battle_button.disabled = true
    footer.text = "Preparing battle…"
    if GameState.run_battle():
        get_tree().change_scene_to_file("res://scenes/combat/combat.tscn")
        return
    battle_button.disabled = false
    footer.text = "Battle could not start. Finish the draft and try again."

func _go_back() -> void:
    GameMenu.confirm_leave("res://scenes/army_builder/army_builder.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_1, KEY_2, KEY_3]:
        _select_offer(int(event.keycode - KEY_1))
    elif event.keycode == KEY_S:
        _use_commander_skill()
    elif event.keycode == KEY_ENTER and battle_button.visible:
        _start_battle()
    else:
        return
    get_viewport().set_input_as_handled()
