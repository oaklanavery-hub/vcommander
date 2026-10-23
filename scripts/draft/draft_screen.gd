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
var redraw_button := Button.new()
var specialization_button := Button.new()
var _offer_scroll := ScrollContainer.new()
var _draft_actions := HBoxContainer.new()

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
    var padding := offer_content.get_parent()
    _offer_scroll.name = "DraftScroll"
    _offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _offer_scroll.follow_focus = true
    padding.add_child(_offer_scroll)
    offer_content.reparent(_offer_scroll)
    offer_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _draft_actions.name = "DraftActions"
    _draft_actions.add_theme_constant_override("separation", 8)
    offer_content.add_child(_draft_actions)
    skill_button.reparent(_draft_actions)
    skill_button.custom_minimum_size.y = 40
    skill_button.add_theme_font_size_override("font_size", 14)
    skill_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var arena: Control = get_node("Margin/Main/Board/Padding/Arena")
    arena.resized.connect(_fit_draft)
    offer_content.minimum_size_changed.connect(_fit_draft)
    _fit_draft.call_deferred()
    back_button.pressed.connect(_go_back)
    skill_button.pressed.connect(_use_commander_skill)
    battle_button.pressed.connect(_start_battle)
    redraw_button.name = "RedrawChoices"
    redraw_button.custom_minimum_size.y = 32
    redraw_button.tooltip_text = "Experiment: redraw all three choices once this round. Costs no pick, adds no time; cards may repeat. R"
    redraw_button.pressed.connect(_redraw)
    _draft_actions.add_child(redraw_button)
    _draft_actions.move_child(redraw_button, 0)
    redraw_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    redraw_button.add_theme_font_size_override("font_size", 14)
    specialization_button.name = "CommanderPath"
    specialization_button.custom_minimum_size.y = 36
    specialization_button.text = "Commander path · 1 pick (C)"
    specialization_button.tooltip_text = "Prototype: once per adventure from Round 3. Opens two ability paths; reading and cancelling cost no pick. C"
    specialization_button.pressed.connect(_open_specializations)
    offer_content.add_child(specialization_button)

    if not GameState.match_started:
        footer.text = "No active draft. Return to the Army Builder."
        skill_button.disabled = true
        battle_button.visible = false
        set_process(false)
        return

    _time_left = GameState.draft_time_left
    _refresh_all()

func _process(delta: float) -> void:
    if GameState.draft.is_phase_complete():
        return

    _time_left = maxf(0.0, _time_left - delta)
    GameState.update_draft_clock(_time_left)
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
    redraw_button.visible = GameState.draft.redraw_enabled and not complete
    redraw_button.disabled = not GameState.draft.can_redraw()
    redraw_button.text = "Redraw · %d left (R)" % (0 if GameState.draft.redraw_used else 1)
    specialization_button.visible = GameState.draft.specialization_enabled and GameState.draft.specialization_id.is_empty() and GameState.draft.round_number >= GameState.draft.specialization_first_round and not complete
    specialization_button.disabled = not GameState.draft.can_specialize()
    offer_row.visible = not complete
    _timer_bar.visible = not complete
    offer_content.get_node("Prompt").text = "Your warband is ready" if complete else "Choose one card"
    battle_button.visible = complete
    battle_button.disabled = not complete
    if complete:
        footer.text = "Ready · 3-minute battle limit. New powers ×2; earlier bonuses unchanged." if GameState.draft.sudden_death else "Ready for battle • Enter to begin. The rival reveals new picks at combat."
        timer_label.text = "Draft complete"
    else:
        if GameState.match_state.sudden_death:
            footer.text = "Sudden Death · New powers ×2; earlier bonuses unchanged. Battle limit: 3 minutes."
        elif GameState.match_state.round_number == 1:
            footer.text = "Round 1 is Army-only. Every pick rerolls all three choices."
        else:
            footer.text = "Armies and buffs persist. All units respawn at full HP each battle."
    FirstMatchGuide.draft_updated()
    if not GameState.recovery_notice.is_empty():
        footer.text = GameState.recovery_notice
    _fit_draft.call_deferred()

func _fit_draft() -> void:
    if not is_instance_valid(offer_content) or not _offer_scroll.is_inside_tree():
        return
    var arena: Control = get_node("Margin/Main/Board/Padding/Arena")
    var panel: Control = arena.get_node("DraftCenter/OfferPanel")
    panel.custom_minimum_size.x = minf(660, maxf(0, arena.size.x - 12))
    for button in offer_row.get_children():
        button.custom_minimum_size.x = 132 if arena.size.x < 660 else 156
    _offer_scroll.custom_minimum_size.y = minf(offer_content.get_combined_minimum_size().y, maxf(80, arena.size.y - 64))

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
            blessing.side_config = GameState.get_player_combat_side()
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
        str(int(WarbandStats.power_percentage(GameState.get_player_combat_side(), buff))),
        str(buff.get("stat", "stat")).replace("_", " ").to_upper(),
        BuffTile.stack_text(buff, stack)
    ]

func _refresh_skill(commander: Dictionary) -> void:
    var skill: Dictionary = commander.get("active_skill", {})
    skill_button.tooltip_text = ScreenStyle.skill_description(commander)
    skill_button.text = "%s · 1 pick · %d/2" % [
        str(skill.get("display_name", "Commander Skill")),
        GameState.draft.commander_skill_uses_remaining()
    ]
    if GameState.draft.commander_skill_used_this_round:
        skill_button.text += " · Prepared"
    skill_button.tooltip_text += "\nCosts 1 selection · At most once this round · S"
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

func _redraw() -> void:
    if GameState.draft.redraw():
        GameAudio.play_effect("pick")
        _refresh_all()

func _open_specializations() -> void:
    if not GameState.draft.can_specialize():
        return
    GameMenu.open_specializations(func():
        _time_left = GameState.draft_time_left
        _refresh_all())

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
    elif event.keycode == KEY_R and redraw_button.visible:
        _redraw()
    elif event.keycode == KEY_C and specialization_button.visible:
        _open_specializations()
    elif event.keycode == KEY_ENTER and battle_button.visible:
        _start_battle()
    else:
        return
    get_viewport().set_input_as_handled()
