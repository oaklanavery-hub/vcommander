extends Control

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var title_label: Label = $Margin/Main/Header/Title
@onready var seed_label: Label = $Margin/Main/Header/Seed
@onready var battle_timer: Label = $Margin/Main/StatusRow/BattleTimer
@onready var speed_button: Button = $Margin/Main/StatusRow/Speed
@onready var skip_button: Button = $Margin/Main/StatusRow/Skip
@onready var battlefield: BattlefieldView = $Margin/Main/BattlePanel/Padding/Battlefield
@onready var player_summary: RichTextLabel = $Margin/Main/SummaryRow/PlayerPanel/Padding/PlayerSummary
@onready var opponent_summary: RichTextLabel = $Margin/Main/SummaryRow/OpponentPanel/Padding/OpponentSummary
@onready var event_log: RichTextLabel = $Margin/Main/SummaryRow/EventPanel/Padding/EventLog
@onready var next_button: Button = $Margin/Main/NextRound
@onready var result_label: Label = $Margin/Main/Result

var _frames: Array = []
var _events: Array = []
var _playback_time := 0.0
var _duration := 0.0
var _frame_index := 0
var _event_index := 0
var _speed_options: Array[float] = [1.0, 2.0, 4.0]
var _speed_index := 1
var _finished := false
var _log_lines: Array[String] = []

func _ready() -> void:
    back_button.pressed.connect(_go_back)
    next_button.pressed.connect(_next_round)
    next_button.visible = false
    back_button.text = "Leave match"
    speed_button.pressed.connect(_cycle_speed)
    skip_button.pressed.connect(_skip_to_result)

    var result: Dictionary = GameState.battle_result
    if result.is_empty():
        title_label.text = "No battle available"
        result_label.text = "Return to the Army Builder to start a match."
        set_process(false)
        return

    _frames = result.get("frames", [])
    _events = result.get("events", [])
    _duration = float(result.get("duration", 0.0))
    seed_label.text = "Seed %d" % int(result.get("seed", GameState.match_seed))

    var field: Dictionary = result.get("battlefield", {})
    battlefield.set_battlefield_size(
        float(field.get("width", 24.0)),
        float(field.get("height", 14.0))
    )
    if not _frames.is_empty():
        battlefield.set_frame(_frames[0])

    title_label.text = "Battle %d • %s" % [GameState.match_state.round_number, "SUDDEN DEATH" if GameState.match_state.sudden_death else "The Verdant Crossing"]
    _refresh_summaries()
    _update_speed_label()
    _update_timer_label()
    result_label.text = "Combat replay running…"

func _process(delta: float) -> void:
    if _finished:
        return

    _playback_time = minf(
        _duration,
        _playback_time + delta * _speed_options[_speed_index]
    )
    _advance_frames()
    _advance_events()
    _update_timer_label()

    if _playback_time + 0.001 >= _duration:
        _finish_replay()

func _advance_frames() -> void:
    while _frame_index + 1 < _frames.size():
        var next_frame: Dictionary = _frames[_frame_index + 1]
        if float(next_frame.get("time", 0.0)) > _playback_time + 0.001:
            break
        _frame_index += 1
        battlefield.set_frame(next_frame)

func _advance_events() -> void:
    while _event_index < _events.size():
        var event: Dictionary = _events[_event_index]
        if float(event.get("time", 0.0)) > _playback_time + 0.001:
            break
        _event_index += 1
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
        return "[%s] %s" % [time_text, str(event.get("ability", "Ability"))]
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
    battle_timer.text = "Battle %05.1f / %05.1f sec" % [_playback_time, _duration]

func _update_speed_label() -> void:
    speed_button.text = "Replay speed: %dx" % int(_speed_options[_speed_index])

func _cycle_speed() -> void:
    _speed_index = (_speed_index + 1) % _speed_options.size()
    _update_speed_label()

func _skip_to_result() -> void:
    _playback_time = _duration
    if not _frames.is_empty():
        _frame_index = _frames.size() - 1
        battlefield.set_frame(_frames[_frame_index])
    _advance_events()
    _update_timer_label()
    _finish_replay()

func _finish_replay() -> void:
    if _finished:
        return
    _finished = true
    var result: Dictionary = GameState.battle_result
    var winner := str(result.get("winner", "draw"))
    var reason := str(result.get("reason", "complete")).replace("_", " ")
    if winner == "player":
        result_label.text = "PLAYER WINS • %s" % reason
    elif winner == "opponent":
        result_label.text = "RIVAL WINS • %s" % reason
    else:
        result_label.text = "DRAW • %s" % reason
    speed_button.disabled = true
    skip_button.disabled = true
    var match_info = GameState.match_state
    result_label.text += " • Round losses: You %d | Rival %d" % [int(match_info.losses["player"]), int(match_info.losses["opponent"])]
    if match_info.is_complete():
        result_label.text = "MATCH WON!" if match_info.winner == "player" else "MATCH LOST • A new strategy awaits"
        next_button.text = "Choose a new Commander"
    else:
        next_button.text = "Continue to %sRound %d" % ["Sudden Death • " if match_info.sudden_death else "", match_info.round_number + 1]
    next_button.visible = true

func _go_back() -> void:
    GameState.leave_match()
    get_tree().change_scene_to_file("res://scenes/army_builder/army_builder.tscn")

func _next_round() -> void:
    next_button.disabled = true
    if GameState.match_state.is_complete():
        GameState.leave_match()
        get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
    elif GameState.begin_next_round():
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn")
    else:
        next_button.disabled = false
