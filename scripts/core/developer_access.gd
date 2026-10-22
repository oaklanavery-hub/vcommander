class_name DeveloperAccess
extends RefCounted

signal changed

const DEFAULT_PATH := "user://developer_access.cfg"
const VERIFIER_SETTING := "development/collection_key_sha256"
const MAX_KEY_LENGTH := 128

var path: String
var last_save_error: Error = OK
var _verifier: String
var _credential := ""

func _init(storage_path: String = DEFAULT_PATH, verification_hash: String = "__project__") -> void:
    path = storage_path
    _verifier = str(ProjectSettings.get_setting(VERIFIER_SETTING, "")) if verification_hash == "__project__" else verification_hash
    if path.is_empty() or not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > 1024:
        return
    file.close()
    var config := ConfigFile.new()
    if config.load(path) == OK and config.get_value("access", "schema_version", 0) == 1:
        var value = config.get_value("access", "key", "")
        if value is String and _matches(value):
            _credential = value

func is_enabled() -> bool:
    return _matches(_credential)

func activate(key: String) -> Error:
    var candidate := key.strip_edges()
    if not _matches(candidate):
        return ERR_UNAUTHORIZED
    last_save_error = _save_credential(candidate)
    if last_save_error != OK:
        return last_save_error
    var was_enabled := is_enabled()
    _credential = candidate
    if not was_enabled:
        changed.emit()
    return OK

func remove() -> Error:
    if not path.is_empty() and FileAccess.file_exists(path):
        last_save_error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        if last_save_error != OK:
            return last_save_error
    last_save_error = OK
    var was_enabled := is_enabled()
    _credential = ""
    if was_enabled:
        changed.emit()
    return OK

func _matches(value: String) -> bool:
    return value.length() >= 32 and value.length() <= MAX_KEY_LENGTH and _verifier.length() == 64 and value.sha256_text() == _verifier

func _save_credential(value: String) -> Error:
    if path.is_empty():
        return OK # Explicit isolated access for tests; never read player storage.
    var config := ConfigFile.new()
    config.set_value("access", "schema_version", 1)
    config.set_value("access", "key", value)
    var temporary := ProjectSettings.globalize_path(path + ".tmp")
    var error := config.save(temporary)
    if error != OK:
        return error
    return DirAccess.rename_absolute(temporary, ProjectSettings.globalize_path(path))
