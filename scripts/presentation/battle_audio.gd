class_name BattleAudio
extends Node

var _last_cue: Dictionary = {}
var _window_start := -1.0
var _window_count := 0
var _audio_service: Node

func _ready() -> void:
    _audio_service = get_node("/root/GameAudio")

func consume_event(event: Dictionary, clock: float = -1.0) -> String:
    var cue := CombatCues.sound(event)
    if cue.is_empty():
        return ""
    var now := float(Time.get_ticks_msec()) * 0.001 if clock < 0 else clock
    var cooldown := 0.07 if cue == "meteor" else (0.25 if cue in ["heal", "healing_water", "defeat"] else 0.10)
    if now - float(_last_cue.get(cue, -100.0)) < cooldown:
        return ""
    if now - _window_start >= 0.08:
        _window_start = now
        _window_count = 0
    if _window_count >= 8 and event.get("type") != "commander_skill":
        return ""
    _window_count += 1
    _last_cue[cue] = now
    if _audio_service != null:
        _audio_service.call("play_effect", cue)
    return cue

func stop_all() -> void:
    if _audio_service != null:
        _audio_service.call("stop_effects")
