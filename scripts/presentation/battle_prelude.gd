class_name BattlePrelude
extends RefCounted

const DURATION := 2.8
const APPLY_TIME := 1.8
var elapsed := 0.0
var duration := 0.0
var event_end := 0
var before: Dictionary = {}
var after: Dictionary = {}
var skills: Array[Dictionary] = []
var _scheduled: Array[Dictionary] = []
var _index := 0

func _init(data: Dictionary = {}) -> void:
    before = data.get("before", {})
    after = data.get("after", {})
    event_end = int(data.get("event_end", 0))
    var plant_index := 0
    for original in data.get("events", []):
        var event: Dictionary = original.duplicate(true)
        var at := APPLY_TIME
        if event.get("type") == "commander_skill":
            skills.append(event)
            at = 0.0
        elif event.get("kind") == "meteor":
            at = 0.45 + float(event.get("index", 0)) * 0.12
        elif event.get("type") == "spawn":
            at = 0.8 + float(plant_index % 6) * 0.12
            plant_index += 1
        event["time"] = at
        _scheduled.append(event)
    if not skills.is_empty():
        duration = DURATION
    _scheduled.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

func active() -> bool:
    return elapsed < duration

func advance(delta: float) -> Array[Dictionary]:
    elapsed = minf(duration, elapsed + maxf(0, delta))
    var events: Array[Dictionary] = []
    while _index < _scheduled.size() and float(_scheduled[_index]["time"]) <= elapsed:
        events.append(_scheduled[_index])
        _index += 1
    return events

func frame() -> Dictionary:
    if elapsed >= APPLY_TIME:
        return after
    var result := before.duplicate(true)
    var ids := {}
    for unit in before.get("units", []):
        ids[str(unit["id"])] = true
    for event in _scheduled:
        if event.get("type") != "spawn" or float(event["time"]) > elapsed:
            continue
        for unit in after.get("units", []):
            if unit["id"] == event.get("unit_id") and not ids.has(str(unit["id"])):
                result["units"].append(unit)
                ids[str(unit["id"])] = true
    return result
