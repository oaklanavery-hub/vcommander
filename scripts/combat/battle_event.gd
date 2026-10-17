class_name BattleEvent
extends RefCounted

static func make(event_type: String, time_seconds: float, data: Dictionary = {}) -> Dictionary:
    var event: Dictionary = {
        "type": event_type,
        "time": snappedf(time_seconds, 0.001)
    }
    for key in data.keys():
        event[key] = data[key]
    return event
