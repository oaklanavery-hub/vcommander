class_name BattleAudio
extends Node

var _last_cue: Dictionary = {}
var _window_start := -1.0
var _window_count := 0
var _priority_count := 0
var _commander_count := 0
var _audio_service: Node

func _ready() -> void:
    _audio_service = get_node("/root/GameAudio")

func consume_event(event: Dictionary, clock: float = -1.0) -> String:
    var cue := CombatCues.sound(event)
    if cue.is_empty():
        return ""
    var now := float(Time.get_ticks_msec()) * 0.001 if clock < 0 else clock
    var priority := event_priority(event)
    var cooldown := 0.07 if cue == "meteor" else (0.25 if cue in ["heal", "healing_water", "defeat", "body_fall", "magic_dissolve", "slime_pop", "wood_fall", "plant_grow", "slime_rebirth", "slime_burst"] else 0.10)
    if now - float(_last_cue.get(cue, -100.0)) < cooldown:
        return ""
    if now - _window_start >= 0.08:
        _window_start = now
        _window_count = 0
        _priority_count = 0
        _commander_count = 0
    if priority == 3:
        if _commander_count >= 2:
            return ""
        _commander_count += 1
    elif priority == 2:
        if _priority_count >= 3:
            return ""
        _priority_count += 1
    else:
        if _window_count >= 5:
            return ""
        _window_count += 1
    _last_cue[cue] = now
    if _audio_service != null:
        _audio_service.call("play_effect", cue, priority)
    return cue

static func event_priority(event: Dictionary) -> int:
    if event.get("type") == "commander_skill":
        return 3
    if event.get("type") == "spawn" and event.get("source") in ["death_split", "revival"]:
        return 2
    if event.get("type") == "ability" and event.get("kind") in ["pull", "meteor", "on_death", "area_heal", "death_area", "absorb_burst", "backline_transit", "sticky_link"]:
        return 2
    return 0

func stop_all() -> void:
    if _audio_service != null:
        _audio_service.call("stop_effects")
