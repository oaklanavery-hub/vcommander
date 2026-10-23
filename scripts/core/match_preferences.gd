class_name MatchPreferences
extends RefCounted

const DEFAULT_PATH := "user://match_preferences.cfg"
const DIFFICULTIES := ["casual", "standard", "veteran"]
var path: String
var difficulty := "standard"
var redraw_experiment := false
var specialization_experiment := false

func _init(storage_path: String = DEFAULT_PATH) -> void:
    path = storage_path
    if path.is_empty():
        return
    var config := ConfigFile.new()
    if config.load(path) == OK:
        var mode := str(config.get_value("match", "difficulty", "standard"))
        difficulty = mode if mode in DIFFICULTIES else "standard"
        redraw_experiment = bool(config.get_value("match", "redraw_experiment", false))
        specialization_experiment = bool(config.get_value("match", "specialization_experiment", false))

func save() -> Error:
    if path.is_empty():
        return OK
    var config := ConfigFile.new()
    config.set_value("match", "difficulty", difficulty)
    config.set_value("match", "redraw_experiment", redraw_experiment)
    config.set_value("match", "specialization_experiment", specialization_experiment)
    return config.save(path)
