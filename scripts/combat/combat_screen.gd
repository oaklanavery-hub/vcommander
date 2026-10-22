extends Control

const AudioScript = preload("res://scripts/presentation/battle_audio.gd")

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var title_label: Label = $Margin/Main/Header/Title
@onready var seed_label: Label = $Margin/Main/Header/Seed
@onready var battle_timer: Label = _hearts_meter.timer_label
@onready var speed_button: Button = $Margin/Main/Header/Speed
@onready var battlefield: BattlefieldView = $Margin/Main/BattlePanel/Padding/Battlefield
@onready var player_summary: RichTextLabel = $Margin/Main/SummaryRow/PlayerPanel/Padding/PlayerSummary
@onready var opponent_summary: RichTextLabel = $Margin/Main/SummaryRow/OpponentPanel/Padding/OpponentSummary
@onready var event_log: RichTextLabel = $Margin/Main/SummaryRow/EventPanel/Padding/EventLog
@onready var pause_button: Button = $Margin/Main/Header/Pause
@onready var details_button: Button = $Margin/Main/Header/Details
@onready var sound_button: Button = $Margin/Main/OptionsRow/Sound
@onready var motion_button: Button = $Margin/Main/OptionsRow/Motion
@onready var hp_button: Button = $Margin/Main/OptionsRow/HP
@onready var summary_row: HBoxContainer = $Margin/Main/SummaryRow
@onready var next_button: Button = $Margin/Main/NextRound
@onready var result_label: Label = $Margin/Main/Result

var playback_driver: RefCounted
var battle_context: Object
var initial_hearts_revealed := false
var _source: Object

var _frames: Array = []
var _events: Array = []
var _playback_time := 0.0
var _duration := 0.0
var _end_elapsed := 0.0
const CONTACT_TAIL := 0.55
var _tail_length := CONTACT_TAIL
var _frame_index := 0
var _event_index := 0
var _speed_options: Array[float] = [1.0, 2.0, 4.0]
var _speed_index := 0
var _finished := false
var _paused := false
var _prelude := BattlePrelude.new()
var _audio = AudioScript.new()
var _log_lines: Array[String] = []
var _hearts_meter := MatchStatus.new()
var player_roster := WarbandRoster.new()
var opponent_roster := WarbandRoster.new()
var mastery_panel := CommanderMasteryPanel.new()
var inspector := UnitInspector.new()
var report_view := BattleReportView.new()
var report_button := Button.new()
var _report: Dictionary = {}

func _ready() -> void:
    _source = battle_context if battle_context != null else get_node("/root/GameState")
    ScreenStyle.apply(self)
    var stage := get_node("Margin/Main/BattlePanel/Padding")
    player_roster.name = "PlayerRoster"
    opponent_roster.name = "OpponentRoster"
    stage.add_child(player_roster)
    stage.move_child(player_roster, 0)
    stage.add_child(opponent_roster)
    battlefield.external_rosters = true
    inspector.name = "UnitInspector"
    $Margin/Main/BattlePanel/Padding.add_child(inspector)
    inspector.dismissed.connect(_close_inspection)
    battlefield.unit_selected.connect(_inspect_unit)
    report_view.name = "BattleReport"
    add_child(report_view)
    report_button.name = "BattleReportButton"
    report_button.text = "Battle report"
    report_button.pressed.connect(_open_report)
    var header := get_node("Margin/Main/Header")
    header.add_child(report_button)
    header.move_child(report_button, header.get_child_count() - 2)
    report_button.hide()
    battlefield.tooltip_text = "Click a companion to inspect its stats and abilities."
    _hearts_meter.name = "MatchHearts"
    var main := get_node("Margin/Main")
    mastery_panel.configure(_source.commander_progress, ContentDatabase, GameAudio)
    mastery_panel.name = "MasteryReward"
    main.add_child(mastery_panel)
    main.move_child(mastery_panel, main.get_child_count() - 2)
    mastery_panel.hide()
    main.add_child(_hearts_meter)
    main.move_child(_hearts_meter, 1)
    _hearts_meter.refresh(_source.match_state, initial_hearts_revealed)
    GameAudio.set_context("battle")
    GameAudio.settings_changed.connect(_update_option_labels)
    ScreenStyle.primary(next_button)
    get_node("Margin/Main/OptionsRow").hide()
    seed_label.hide()
    add_child(_audio)
    pause_button.pressed.connect(_toggle_pause)
    details_button.pressed.connect(_toggle_details)
    sound_button.pressed.connect(_toggle_sound)
    motion_button.pressed.connect(_toggle_motion)
    hp_button.pressed.connect(_toggle_hp)
    _update_option_labels()
    back_button.pressed.connect(_go_back)
    next_button.pressed.connect(_next_round)
    next_button.visible = false
    back_button.text = "Leave match"
    speed_button.pressed.connect(_cycle_speed)

    var result: Dictionary = _source.battle_result
    if result.is_empty():
        title_label.text = "No battle available"
        result_label.text = "Return to the Army Builder to start a match."
        set_process(false)
        return

    _frames = result.get("frames", [])
    _events = result.get("events", [])
    _duration = float(result.get("duration", 0.0))
    _prelude = BattlePrelude.new(result.get("pre_battle", {}))
    battlefield.replay.configure(_frames, _events, _prelude.event_end)
    _tail_length = maxf(CONTACT_TAIL, battlefield.replay.final_action_time() - _duration + CONTACT_TAIL)
    battlefield.replay_enabled = not _prelude.active()
    if _prelude.active():
        _event_index = _prelude.event_end
        speed_button.disabled = true
    seed_label.text = "Seed %d" % int(result.get("seed", _source.match_seed))

    var field: Dictionary = result.get("battlefield", {})
    battlefield.set_battlefield_size(
        float(field.get("width", 24.0)),
        float(field.get("height", 14.0))
    )
    var player_side: Dictionary = _source.get_player_combat_side()
    battlefield.set_side_configs(player_side, _source.opponent_combat_side)
    player_roster.set_side(player_side)
    opponent_roster.set_side(_source.opponent_combat_side, true)
    _hearts_meter.set_commanders(player_side.get("commander", {}), _source.opponent_combat_side.get("commander", {}))
    battlefield.configure_frost()
    if not _frames.is_empty():
        battlefield.set_frame(_frames[0])

    var round_sudden: bool = _source.match_state.sudden_death
    if not _source.match_state.history.is_empty():
        round_sudden = bool(_source.match_state.history.back().get("sudden_death", false))
    title_label.text = "The Verdant Crossing"
    _hearts_meter.round_label.text = "Round %d · %s" % [_source.match_state.round_number, "Sudden Death" if round_sudden else "Battle"]
    _hearts_meter.show_army_health(battlefield.visible_units())
    _refresh_summaries()
    _update_speed_label()
    _update_timer_label()
    result_label.text = "Battle in progress… Click or tap a companion to inspect."
    if _prelude.active():
        var names: Array[String] = []
        for skill in _prelude.skills:
            names.append(("You: " if skill.get("side") == "player" else "Rival: ") + str(skill.get("name", "Commander skill")))
        result_label.text = "   •   ".join(names) + " • Armies hold position"
        _advance_prelude(0.0)
    if playback_driver != null:
        playback_driver.attach(self)

func _process(delta: float) -> void:
    if playback_driver != null:
        playback_driver.advance(self, delta)
        return
    if _finished or _paused:
        return

    if _prelude.active():
        _advance_prelude(delta)
        return

    var step := delta * _speed_options[_speed_index]
    var remaining := _duration - _playback_time
    _playback_time = minf(_duration, _playback_time + step)
    _end_elapsed = minf(_tail_length, _end_elapsed + maxf(0, step - remaining))
    _advance_frames()
    _advance_events()
    _update_timer_label()

    if _playback_time + 0.001 >= _duration and _end_elapsed >= _tail_length:
        _finish_replay()

func _advance_prelude(delta: float) -> void:
    var events := _prelude.advance(delta)
    var frame := _prelude.frame()
    battlefield.set_playback(frame, frame, 0.0, _prelude.elapsed)
    _hearts_meter.show_army_health(battlefield.visible_units())
    _refresh_inspection()
    battlefield.prelude_skills = _prelude.skills if _prelude.active() else []
    battlefield.prelude_time = _prelude.elapsed
    for event in events:
        battlefield.consume_event(event)
        _audio.consume_event(event)
        var line := _format_event(event)
        if not line.is_empty():
            _log_lines.append(line)
    event_log.text = "\n".join(_log_lines)
    battle_timer.text = "Pre-battle • Commander skills"
    if not _prelude.active():
        battlefield.finish_replay()
        battlefield.replay_enabled = true
        battlefield.prelude_skills = []
        battlefield.set_frame(_frames[0] if not _frames.is_empty() else frame)
        _hearts_meter.show_army_health(battlefield.visible_units())
        speed_button.disabled = false
        result_label.text = "Battle in progress… Click or tap a companion to inspect."
        _update_timer_label()

func _advance_frames() -> void:
    while _frame_index + 1 < _frames.size():
        var next_frame: Dictionary = _frames[_frame_index + 1]
        if float(next_frame.get("time", 0.0)) > _playback_time + 0.001:
            break
        _frame_index += 1
    if not _frames.is_empty():
        var current: Dictionary = _frames[_frame_index]
        var next: Dictionary = _frames[mini(_frame_index + 1, _frames.size() - 1)]
        var interval := maxf(0.001, float(next.get("time", 0)) - float(current.get("time", 0)))
        battlefield.set_playback(current, next, (_playback_time - float(current.get("time", 0))) / interval, _playback_time + _end_elapsed)
        _hearts_meter.show_army_health(battlefield.visible_units())
        _refresh_inspection()

func _advance_events() -> void:
    while _event_index < _events.size():
        var event: Dictionary = _events[_event_index]
        if float(event.get("time", 0.0)) > _playback_time + 0.001:
            break
        _event_index += 1
        battlefield.consume_event(event)
        if _playback_time - float(event.get("time", 0)) < 0.15:
            _audio.consume_event(event)
        var line := _format_event(event)
        if not line.is_empty():
            _log_lines.append(line)
            if _log_lines.size() > 9:
                _log_lines.pop_front()
            event_log.text = "\n".join(_log_lines)

func _format_event(event: Dictionary) -> String:
    var event_type := str(event.get("type", ""))
    var time_text := "%05.1f" % float(event.get("time", 0.0))
    if event_type == "commander_skill":
        return "[%s] %s uses %s" % [
            time_text,
            str(event.get("side", "")).capitalize(),
            str(event.get("name", "Commander Skill"))
        ]
    if event_type == "ability":
        return "[%s] %s" % [time_text, str(event.get("ability", "Ability")).replace("_", " ").capitalize()]
    if event_type == "defeat":
        return "[%s] %s defeated" % [time_text, str(event.get("name", "Unit"))]
    if event_type == "battle_end":
        return "[%s] Battle ended: %s" % [
            time_text,
            str(event.get("reason", "complete")).replace("_", " ")
        ]
    return ""

func _refresh_summaries() -> void:
    player_summary.text = _side_summary(
        "[b]Your Army[/b]",
        _source.get_player_combat_side()
    )
    opponent_summary.text = _side_summary(
        "[b]Rival Commander[/b]",
        _source.opponent_combat_side
    )

func _side_summary(title: String, side_config: Dictionary) -> String:
    var lines: Array[String] = [title]
    var cards: Array = side_config.get("cards", [])
    var counts: Dictionary = side_config.get("unit_counts", {})
    for raw_card in cards:
        if typeof(raw_card) != TYPE_DICTIONARY:
            continue
        var card: Dictionary = raw_card
        var card_id := str(card.get("id", ""))
        var count := int(counts.get(card_id, 0))
        if count > 0:
            lines.append("%s ×%d" % [str(card.get("display_name", card_id)), count])
    if bool(side_config.get("commander_skill_active", false)):
        var commander: Dictionary = side_config.get("commander", {})
        var skill: Dictionary = commander.get("active_skill", {})
        lines.append("Commander Skill: %s" % str(skill.get("display_name", "Active")))
    for buff in side_config.get("buffs", []):
        lines.append("%s ×%d" % [str(buff.get("definition", {}).get("display_name", "Buff")), int(buff.get("stacks", 0))])
    return "\n".join(lines)

func _update_timer_label() -> void:
    battle_timer.text = "Battle · %d:%02d" % [int(_playback_time) / 60, int(_playback_time) % 60]

func _update_speed_label() -> void:
    speed_button.text = "%dx speed" % int(_speed_options[_speed_index])

func _cycle_speed() -> void:
    if playback_driver != null:
        return
    if _prelude.active() or _finished:
        return
    _speed_index = (_speed_index + 1) % _speed_options.size()
    _update_speed_label()

func _finish_replay() -> void:
    if playback_driver != null:
        playback_driver.finish(self)
        return
    if _finished:
        return
    _finished = true
    battlefield.replay_complete = true
    _hearts_meter.refresh(_source.match_state)
    battlefield.finish_replay()
    reveal_report()
    var result: Dictionary = _source.battle_result
    var winner := str(result.get("winner", "draw"))
    GameAudio.play_effect("victory" if winner == "player" else "loss")
    if winner == "player":
        result_label.text = "Victory! Your warband holds the crossing."
    elif winner == "opponent":
        result_label.text = "A setback. Your next draft gets an extra pick."
    else:
        result_label.text = "A draw. Both Commanders lose a heart."
    pause_button.disabled = true
    speed_button.disabled = true
    var match_info = _source.match_state
    if winner == "draw" and match_info.sudden_death:
        result_label.text = "Sudden Death! Win the next battle outright."
    if match_info.is_complete():
        result_label.text = "Adventure won! The crossing is yours." if match_info.winner == "player" else "Your warband will rise again. Try a new strategy."
        summary_row.hide()
        details_button.disabled = true
        mastery_panel.show_reward(_source.mastery_reward)
        next_button.text = "Play again"
    else:
        next_button.text = "Continue to %sRound %d" % ["Sudden Death • " if match_info.sudden_death else "", match_info.round_number + 1]
    next_button.visible = true
    next_button.grab_focus()

func reveal_report() -> void:
    if not _finished:
        return
    _close_inspection()
    report_button.show()
    FirstMatchGuide.battle_finished()

func _open_report() -> void:
    # Completion is gated here as well as on the button: inspection never leaks the result.
    if not _finished:
        return
    if _report.is_empty():
        _report = BattleReport.build(_source.battle_result)
    report_view.open(_report, _source.match_state.round_number)
    FirstMatchGuide.report_opened()

func _inspect_unit(unit: Dictionary) -> void:
    if unit.is_empty():
        _close_inspection()
        return
    battlefield.selected_id = str(unit.get("id", ""))
    var display := battlefield.displayed_unit(battlefield.selected_id)
    inspector.inspect(display, ContentDatabase.get_card(str(display.get("card_id", ""))), battlefield._visual_time, battlefield.frozen_sides.has(str(display.get("side", ""))) and battlefield.frost_coverage() >= 1.0)

func _refresh_inspection() -> void:
    if inspector.selected_id.is_empty():
        return
    var unit := battlefield.displayed_unit(inspector.selected_id)
    inspector.inspect(unit, ContentDatabase.get_card(str(unit.get("card_id", ""))), battlefield._visual_time, battlefield.frozen_sides.has(str(unit.get("side", ""))) and battlefield.frost_coverage() >= 1.0)

func _close_inspection() -> void:
    inspector.selected_id = ""
    inspector.hide()
    battlefield.selected_id = ""
    battlefield.queue_redraw()

func _hearts(losses: int) -> String:
    var remaining := clampi(4 - losses, 0, 4)
    return "♥".repeat(remaining) + "♡".repeat(4 - remaining)

func _go_back() -> void:
    GameMenu.confirm_leave("res://scenes/main_menu/main_menu.tscn")

func _next_round() -> void:
    if playback_driver != null:
        playback_driver.next_round(self)
        return
    next_button.disabled = true
    if _source.match_state.is_complete():
        _source.leave_match()
        get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    elif _source.begin_next_round():
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn")
    else:
        next_button.disabled = false

func _toggle_pause() -> void:
    if playback_driver != null:
        return
    if _finished:
        return
    _paused = not _paused
    pause_button.text = "Resume" if _paused else "Pause"

func _toggle_details() -> void:
    summary_row.visible = not summary_row.visible
    details_button.text = "Hide details" if summary_row.visible else "Army details"

func _toggle_sound() -> void:
    GameAudio.set_effects_volume(0.0 if GameAudio.effects_volume > 0 else 0.75)
    GameAudio.save_settings()
    _update_option_labels()

func _toggle_motion() -> void:
    BattlefieldView.reduced_motion = not BattlefieldView.reduced_motion
    GameAudio.reduced_motion = BattlefieldView.reduced_motion
    GameAudio.save_settings()
    _update_option_labels()
    battlefield.queue_redraw()

func _toggle_hp() -> void:
    BattlefieldView.show_hp_numbers = not BattlefieldView.show_hp_numbers
    GameAudio.show_hp_numbers = BattlefieldView.show_hp_numbers
    GameAudio.save_settings()
    _update_option_labels()
    battlefield.queue_redraw()

func _update_option_labels() -> void:
    sound_button.text = "Effects: On" if GameAudio.effects_volume > 0 else "Effects: Off"
    BattlefieldView.reduced_motion = GameAudio.reduced_motion
    BattlefieldView.show_hp_numbers = GameAudio.show_hp_numbers
    motion_button.text = "Motion: Reduced" if BattlefieldView.reduced_motion else "Motion: Full"
    hp_button.text = "HP numbers: On" if BattlefieldView.show_hp_numbers else "HP numbers: Off"

func _unhandled_key_input(event: InputEvent) -> void:
    if report_view.overlay.visible:
        return
    if playback_driver != null:
        if GameMenu.overlay.visible:
            return
        if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER and next_button.visible:
            _next_round()
            get_viewport().set_input_as_handled()
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_SPACE:
        _toggle_pause()
    elif event.keycode in [KEY_1, KEY_2, KEY_4] and not _prelude.active() and not _finished:
        _speed_index = {KEY_1: 0, KEY_2: 1, KEY_4: 2}[event.keycode]
        _update_speed_label()
    elif event.keycode == KEY_M:
        _toggle_sound()
    elif event.keycode == KEY_ENTER and next_button.visible:
        _next_round()
    else:
        return
    get_viewport().set_input_as_handled()
