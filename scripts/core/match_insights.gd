class_name MatchInsights
extends RefCounted
## Bounded local pacing evidence. This service cannot award or alter progression.

const DEFAULT_PATH := "user://match_insights.json"
const MAX_MATCHES := 30
const MAX_ROUNDS := 64
var store: LocalMatchStore
var entries: Array[Dictionary] = []

func _init(path: String = DEFAULT_PATH) -> void:
    store = LocalMatchStore.new(path)
    for value in store.candidates():
        if _valid(value):
            entries.assign(value["entries"])
            break

func _valid(value: Dictionary) -> bool:
    if value.get("schema") != 1 or not value.get("entries") is Array or value["entries"].size() > MAX_MATCHES:
        return false
    for entry in value["entries"]:
        if not entry is Dictionary or not entry.get("id") is String or not entry.get("commander") is String or entry.get("difficulty") not in MatchPreferences.DIFFICULTIES or not entry.get("redraw") is bool or entry.get("outcome") not in ["ongoing", "win", "loss", "forfeit"]:
            return false
        for key in ["last_round", "round_count", "draws", "timeouts", "sudden_draws"]:
            if not CommanderProgress._counter(entry.get(key)):
                return false
        for key in ["battle_seconds", "draft_seconds", "watch_seconds"]:
            if not _seconds(entry.get(key)):
                return false
        if not entry.get("rounds") is Array or entry["rounds"].size() > MAX_ROUNDS:
            return false
        for row in entry["rounds"]:
            if not row is Dictionary or not CommanderProgress._counter(row.get("round")) or not _seconds(row.get("watch")):
                return false
    return true

static func _seconds(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) <= 1.0e9

func record_round(id: String, metadata: Dictionary, round_info: Dictionary) -> void:
    if id.is_empty():
        return
    var entry := _find(id)
    if entry.is_empty():
        entry = {"id": id, "commander": str(metadata.get("commander", "")), "difficulty": str(metadata.get("difficulty", "standard")), "redraw": bool(metadata.get("redraw", false)), "outcome": "ongoing", "last_round": 0, "round_count": 0, "draws": 0, "timeouts": 0, "sudden_draws": 0, "battle_seconds": 0.0, "draft_seconds": 0.0, "watch_seconds": 0.0, "rounds": []}
        entries.append(entry)
        while entries.size() > MAX_MATCHES:
            entries.pop_front()
    var number := int(round_info.get("round", 0))
    if number > int(entry["last_round"]):
        entry["last_round"] = number
        entry["round_count"] = int(entry["round_count"]) + 1
        var draw: bool = round_info.get("winner") == "draw"
        entry["draws"] = int(entry["draws"]) + (1 if draw else 0)
        entry["timeouts"] = int(entry["timeouts"]) + (1 if round_info.get("reason") == "timer" else 0)
        entry["sudden_draws"] = int(entry["sudden_draws"]) + (1 if draw and bool(round_info.get("sudden", false)) else 0)
        entry["battle_seconds"] = float(entry["battle_seconds"]) + maxf(0, float(round_info.get("duration", 0)))
        entry["draft_seconds"] = float(entry["draft_seconds"]) + maxf(0, float(round_info.get("draft_seconds", 0)))
        entry["rounds"].append({"round": number, "watch": 0.0})
        while entry["rounds"].size() > MAX_ROUNDS:
            entry["rounds"].pop_front()
    if metadata.get("outcome", "ongoing") in ["win", "loss"]:
        entry["outcome"] = metadata["outcome"]
    _save()

func record_watch(id: String, round_number: int, seconds: float) -> void:
    var entry := _find(id)
    if entry.is_empty():
        return
    for row in entry["rounds"]:
        if int(row["round"]) == round_number:
            var total := maxf(float(row["watch"]), seconds)
            entry["watch_seconds"] = float(entry["watch_seconds"]) + total - float(row["watch"])
            row["watch"] = total
            _save()
            return

func finish(id: String, outcome: String) -> void:
    var entry := _find(id)
    if not entry.is_empty() and entry["outcome"] == "ongoing" and outcome in ["win", "loss", "forfeit"]:
        entry["outcome"] = outcome
        _save()

func summary(experiment: int = -1) -> Dictionary:
    var result := {"matches": 0, "completed": 0, "rounds": 0, "draws": 0, "timeouts": 0, "sudden_draws": 0, "battle_seconds": 0.0, "draft_seconds": 0.0, "watch_seconds": 0.0}
    for entry in entries:
        if experiment >= 0 and bool(entry["redraw"]) != bool(experiment):
            continue
        result["matches"] += 1
        result["completed"] += 1 if entry["outcome"] in ["win", "loss"] else 0
        result["rounds"] += int(entry["round_count"])
        for key in ["draws", "timeouts", "sudden_draws", "battle_seconds", "draft_seconds", "watch_seconds"]:
            result[key] += entry[key]
    var count := maxi(1, int(result["rounds"]))
    result["average_battle"] = float(result["battle_seconds"]) / count
    result["average_draft"] = float(result["draft_seconds"]) / count
    result["timeout_rate"] = float(result["timeouts"]) * 100.0 / count
    return result

func _find(id: String) -> Dictionary:
    for entry in entries:
        if entry.get("id") == id:
            return entry
    return {}

func _save() -> void:
    store.save({"schema": 1, "entries": entries})
