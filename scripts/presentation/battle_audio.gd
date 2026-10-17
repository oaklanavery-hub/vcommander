class_name BattleAudio
extends Node

var _last_sound_time := -1.0

func consume_event(event: Dictionary) -> void:
    var type := str(event.get("type", ""))
    var time := float(event.get("time", 0))
    if type not in ["attack", "defeat", "commander_skill", "heal"] or time - _last_sound_time < 0.11:
        return
    _last_sound_time = time
    GameAudio.play_effect(type)

func stop_all() -> void:
    GameAudio.stop_effects()
