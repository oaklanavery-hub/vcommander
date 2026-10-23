class_name LocalMatchStore
extends RefCounted
## A small local checkpoint, never a replay archive or a source of progression.

const DEFAULT_PATH := "user://local_match.json"
const MAX_BYTES := 1048576
var path: String
var last_error: Error = OK
var _memory: Dictionary = {}

func _init(storage_path: String = DEFAULT_PATH) -> void:
    path = storage_path

func exists() -> bool:
    return not _memory.is_empty() if path.is_empty() else FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")

func candidates() -> Array[Dictionary]:
    if path.is_empty():
        return [] if _memory.is_empty() else [_memory.duplicate(true)]
    var values: Array[Dictionary] = []
    for candidate in [path, path + ".bak"]:
        var file := FileAccess.open(candidate, FileAccess.READ)
        if file == null or file.get_length() > MAX_BYTES:
            continue
        var parser := JSON.new()
        if parser.parse(file.get_as_text()) == OK and parser.data is Dictionary:
            values.append(parser.data)
    return values

func save(value: Dictionary) -> Error:
    if path.is_empty():
        _memory = value.duplicate(true)
        return OK
    var encoded := JSON.stringify(value)
    if encoded.to_utf8_buffer().size() > MAX_BYTES:
        last_error = ERR_OUT_OF_MEMORY
        return last_error
    var absolute := ProjectSettings.globalize_path(path)
    var file := FileAccess.open(absolute + ".tmp", FileAccess.WRITE)
    if file == null:
        last_error = FileAccess.get_open_error()
        return last_error
    file.store_string(encoded)
    file.flush()
    last_error = file.get_error()
    file.close()
    if last_error == OK:
        last_error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
    if last_error == OK:
        last_error = DirAccess.copy_absolute(absolute, absolute + ".bak")
    return last_error

func clear() -> void:
    _memory.clear()
    if path.is_empty():
        return
    for suffix in ["", ".bak", ".tmp"]:
        var absolute := ProjectSettings.globalize_path(path + suffix)
        if FileAccess.file_exists(absolute):
            var error := DirAccess.remove_absolute(absolute)
            if error != OK:
                last_error = error
