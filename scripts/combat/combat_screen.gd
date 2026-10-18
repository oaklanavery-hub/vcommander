extends Control

const AudioScript = preload("res://scripts/presentation/battle_audio.gd")

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var title_label: Label = $Margin/Main/Header/Title
@onready var seed_label: Label = $Margin/Main/Header/Seed
@onready var battle_timer: Label = $Margin/Main/StatusRow/BattleTimer
@onready var speed_button: Button = $Margin/Main/StatusRow/Speed
@onready var battlefield: BattlefieldView = $Margin/Main/BattlePanel/Padding/Battlefield
@onready var player_summary: RichTextLabel = $Margin/Main/SummaryRow/PlayerPanel/Padding/PlayerSummary
@onready var opponent_summary: RichTextLabel = $Margin/Main/SummaryRow/OpponentPanel/Padding/OpponentSummary
@onready var event_log: RichTextLabel = $Margin/Main/SummaryRow/EventPanel/Padding/EventLog
@onready var pause_button: Button = $Margin/Main/StatusRow/Pause
@onready var details_button: Button = $Margin/Main/StatusRow/Details
@onready var sound_button: Button = $Margin/Main/OptionsRow/Sound
@onready var motion_button: Button = $Margin/Main/OptionsRow/Motion
@onready var hp_button: Button = $Margin/Main/OptionsRow/HP
@onready var summary_row: HBoxContainer = $Margin/Main/SummaryRow
@onready var next_button: Button = $Margin/Main/NextRound
@onready var result_label: Label = $Margin/Main/Result

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
var _hearts_meter := MatchHearts.new()

func _ready() -> void:
    ScreenStyle.apply(self)
    _hearts_meter.name = "MatchHearts"
    var main := get_node("Margin/Main")
    main.add_child(_hearts_meter)
    main.move_child(_hearts_meter, 2)
    _hearts_meter.refresh(GameState.match_state, false)
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

    var result: Dictionary = GameState.battle_result
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
    seed_label.text = "Seed %d" % int(result.get("seed", GameState.match_seed))

    var field: Dictionary = result.get("battlefield", {})
    battlefield.set_battlefield_size(
        float(field.get("width", 24.0)),
        float(field.get("height", 14.0))
    )
    battlefield.set_side_configs(GameState.get_player_combat_side(), GameState.opponent_combat_side)
    battlefield.configure_frost()
    if not _frames.is_empty():
        battlefield.set_frame(_frames[0])

    title_label.text = "Battle %d • %s" % [GameState.match_state.round_number, "SUDDEN DEATH" if bool(GameState.match_state.history.back().get("sudden_death", false)) else "The Verdant Crossing"]
    _refresh_summaries()
    _update_speed_label()
    _update_timer_label()
    result_label.text = "Commander skills • Armies hold position" if _prelude.active() else "Battle in progress…"
    if _prelude.active():
        _advance_prelude(0.0)

func _process(delta: float) -> void:
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
        speed_button.disabled = false
        result_label.text = "Battle in progress…"
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
        GameState.get_player_combat_side()
    )
    opponent_summary.text = _side_summary(
        "[b]Rival Commander[/b]",
        GameState.opponent_combat_side
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
    battle_timer.text = "Battle time  %d:%02d" % [int(_playback_time) / 60, int(_playback_time) % 60]

func _update_speed_label() -> void:
    speed_button.text = "Battle speed: %dx" % int(_speed_options[_speed_index])

func _cycle_speed() -> void:
    if _prelude.active() or _finished:
        return
    _speed_index = (_speed_index + 1) % _speed_options.size()
    _update_speed_label()

func _finish_replay() -> void:
    if _finished:
        return
    _finished = true
    battlefield.replay_complete = true
    _hearts_meter.refresh(GameState.match_state)
    battlefield.finish_replay()
    var result: Dictionary = GameState.battle_result
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
    var match_info = GameState.match_state
    if winner == "draw" and match_info.sudden_death:
        result_label.text = "Sudden Death! Win the next battle outright."
    result_label.text += "\nYou  %s   •   Rival  %s" % [_hearts(int(match_info.losses["player"])), _hearts(int(match_info.losses["opponent"]))]
    if match_info.is_complete():
        result_label.text = "Adventure won! The crossing is yours." if match_info.winner == "player" else "Your warband will rise again. Try a new strategy."
        next_button.text = "Play again"
    else:
        next_button.text = "Continue to %sRound %d" % ["Sudden Death • " if match_info.sudden_death else "", match_info.round_number + 1]
    next_button.visible = true
    next_button.grab_focus()

func _hearts(losses: int) -> String:
    var remaining := clampi(4 - losses, 0, 4)
    return "♥".repeat(remaining) + "♡".repeat(4 - remaining)

func _go_back() -> void:
    GameMenu.confirm_leave("res://scenes/main_menu/main_menu.tscn")

func _next_round() -> void:
    next_button.disabled = true
    if GameState.match_state.is_complete():
        GameState.leave_match()
        get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    elif GameState.begin_next_round():
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn")
    else:
        next_button.disabled = false

func _toggle_pause() -> void:
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
