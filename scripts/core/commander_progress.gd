class_name CommanderProgress
extends RefCounted

const DEFAULT_PATH := "user://commander_profile.json"
const SCHEMA_VERSION := 3
const MAX_COUNTER := 9007199254740991

var path: String
var last_save_error: Error = OK
var load_error: Error = OK
var recovered_from_backup := false
var read_only := false
var last_receipt: Dictionary = {}
var _content: Object
var _rules: Dictionary
var _primary_valid := false
var _developer_access: DeveloperAccess
var _data := {"schema_version": SCHEMA_VERSION, "match_serial": 0, "commanders": {}, "active_match": {}, "achievements": [], "unlocked_cards": []}

func _init(content: Object, storage_path: String = DEFAULT_PATH, developer_access: DeveloperAccess = null) -> void:
    _content = content
    _developer_access = developer_access
    _rules = content.get_mastery_rules().duplicate(true)
    path = storage_path
    if not path.is_empty():
        _load_profile()
    last_receipt = _data.get("last_settlement", {}).duplicate(true)
    var migrated := not read_only and int(_data["schema_version"]) < SCHEMA_VERSION
    if migrated:
        # This frozen content list preserves formerly available cards, including
        # historical presets. Fresh profiles never receive legacy entitlements.
        for id in _rules.get("legacy_available_cards", []):
            if not _content.get_card(str(id)).is_empty() and not _data["unlocked_cards"].has(id):
                _data["unlocked_cards"].append(id)
    var grants := _refresh_rewards()
    if not read_only and (grants["changed"] or migrated):
        _data["schema_version"] = SCHEMA_VERSION
        last_save_error = _save_profile()

func record(commander_id: String) -> Dictionary:
    var stats: Dictionary = _data["commanders"].get(commander_id, {"wins": 0, "losses": 0, "forfeits": 0, "xp": 0}).duplicate(true)
    var played := int(stats["wins"]) + int(stats["losses"])
    stats.merge({"played": played, "win_rate": 100.0 * float(stats["wins"]) / played if played > 0 else 0.0})
    stats.merge(progress_at(int(stats["xp"])))
    return stats

func progress_at(total_xp: int) -> Dictionary:
    var step := maxi(1, int(_rules.get("xp_per_level", 250)))
    var xp := maxi(0, total_xp)
    return {"level": 1 + int(xp / step), "xp_in_level": xp % step, "xp_per_level": step}

func active_match() -> Dictionary:
    return _data["active_match"].duplicate(true)

func begin_match(commander_id: String) -> String:
    if _content.get_commander(commander_id).is_empty() or not _data["active_match"].is_empty():
        return ""
    _data["match_serial"] = int(_data["match_serial"]) + 1
    var id := "match:%d" % int(_data["match_serial"])
    _data["active_match"] = {"id": id, "commander_id": commander_id}
    last_receipt.clear()
    _data["last_settlement"] = {}
    last_save_error = _save_profile()
    return id

func finish_match(match_id: String, outcome: String) -> Dictionary:
    if outcome not in ["win", "loss", "forfeit"] or match_id.is_empty():
        return {}
    var pending: Dictionary = _data["active_match"]
    if str(pending.get("id", "")) != match_id:
        return last_receipt.duplicate(true) if str(last_receipt.get("match_id", "")) == match_id else {}
    var commander_id := str(pending["commander_id"])
    var before := record(commander_id)
    var stats := {"wins": int(before["wins"]), "losses": int(before["losses"]), "forfeits": int(before["forfeits"]), "xp": int(before["xp"])}
    stats["wins" if outcome == "win" else "losses"] += 1
    if outcome == "forfeit":
        stats["forfeits"] += 1
    var gained := int(_rules.get("match_xp", {}).get(outcome, 0))
    stats["xp"] += gained
    _data["commanders"][commander_id] = stats
    _data["active_match"] = {}
    var grants := _refresh_rewards()
    last_receipt = {"achievements": grants["achievements"], "unlocked_cards": grants["unlocked_cards"], "match_id": match_id, "commander_id": commander_id, "outcome": outcome,
        "xp_awarded": gained, "before": before, "after": record(commander_id)}
    _data["last_settlement"] = last_receipt.duplicate(true)
    last_save_error = _save_profile()
    return last_receipt.duplicate(true)

func recover_interrupted_match() -> Dictionary:
    var pending: Dictionary = _data["active_match"]
    return finish_match(str(pending.get("id", "")), "forfeit") if not pending.is_empty() else {}

func is_card_unlocked(card_id: String) -> bool:
    return is_card_earned(card_id) or (not _content.get_card(card_id).is_empty() and _developer_access != null and _developer_access.is_enabled())

func is_card_earned(card_id: String) -> bool:
    var card: Dictionary = _content.get_card(card_id)
    return not card.is_empty() and (not card.has("mastery_unlock") or _data["unlocked_cards"].has(card_id))

func available_cards() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for card in _content.get_all_cards():
        if is_card_unlocked(str(card["id"])):
            result.append(card)
    return result

func unlocked_card_ids() -> Array:
    return _data["unlocked_cards"].duplicate()

func achievement_entries() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    for definition in _content.get_achievement_rules().get("achievements", []):
        var entry: Dictionary = definition.duplicate(true)
        entry["earned"] = _data["achievements"].has(str(entry["id"]))
        entry["progress"] = _condition_progress(entry.get("conditions", []), str(entry.get("commander_id", "")))
        entries.append(entry)
    return entries

func card_reward(card_id: String) -> Dictionary:
    var card: Dictionary = _content.get_card(card_id)
    var requirement: Dictionary = card.get("mastery_unlock", {})
    if requirement.is_empty():
        return {}
    var commander_id := str(requirement["commander_id"])
    var stats := record(commander_id)
    return {"card_id": card_id, "commander_id": commander_id, "unlocked": is_card_unlocked(card_id), "earned": is_card_earned(card_id),
        "level": int(stats["level"]), "wins": int(stats["wins"]),
        "required_level": int(requirement["level"]), "required_wins": int(requirement["wins"])}

func mastery_rewards(commander_id: String = "") -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for card in _content.get_all_cards():
        var reward := card_reward(str(card["id"]))
        if not reward.is_empty() and (commander_id.is_empty() or reward["commander_id"] == commander_id):
            result.append(reward)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a["commander_id"] != b["commander_id"]:
            return str(a["commander_id"]) < str(b["commander_id"])
        if a["required_level"] != b["required_level"]:
            return int(a["required_level"]) < int(b["required_level"])
        return str(a["card_id"]) < str(b["card_id"]))
    return result

func unlock_description(card_id: String) -> String:
    var reward := card_reward(card_id)
    if reward.is_empty():
        return "Available from the start"
    var commander: Dictionary = _content.get_commander(str(reward["commander_id"]))
    return "%s · Level %d + %d wins" % [str(commander.get("display_name", "Commander")), int(reward["required_level"]), int(reward["required_wins"])]

func _condition_progress(conditions: Array, commander_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for condition in conditions:
        var metric := str(condition["metric"])
        var value := 0
        if not commander_id.is_empty():
            var stats := record(commander_id)
            value = int(stats["wins"]) + int(stats["losses"]) - int(stats["forfeits"]) if metric == "completed" else int(stats.get(metric, 0))
        else:
            for id in _data["commanders"]:
                var stats := record(str(id))
                match metric:
                    "completed": value += int(stats["played"]) - int(stats["forfeits"])
                    "wins": value += int(stats["wins"])
                    "level": value = maxi(value, int(stats["level"]))
                    "commanders_won":
                        if not _content.get_commander(str(id)).is_empty() and int(stats["wins"]) > 0:
                            value += 1
        result.append({"metric": metric, "value": value, "target": int(condition["target"])})
    return result

func _refresh_rewards() -> Dictionary:
    var achievements: Array[String] = []
    var cards: Array[String] = []
    for entry in achievement_entries():
        if entry["earned"]:
            continue
        var earned: bool = not entry["progress"].is_empty()
        for condition in entry["progress"]:
            earned = earned and int(condition["value"]) >= int(condition["target"])
        if earned:
            var id := str(entry["id"])
            _data["achievements"].append(id)
            achievements.append(id)
    for card in _content.get_all_cards():
        var reward := card_reward(str(card["id"]))
        if not reward.is_empty() and not reward["earned"] and int(reward["level"]) >= int(reward["required_level"]) and int(reward["wins"]) >= int(reward["required_wins"]):
            var id := str(card["id"])
            _data["unlocked_cards"].append(id)
            cards.append(id)
    return {"achievements": achievements, "unlocked_cards": cards, "changed": not achievements.is_empty() or not cards.is_empty()}

func storage_notice() -> String:
    if read_only:
        return "Saved records could not be loaded. New progress is temporary this session."
    if last_save_error != OK:
        return "Progress could not be saved. Keep this game open and try again after your next match."
    if OS.has_feature("web") and not OS.is_userfs_persistent():
        return "Browser saving is unavailable. Progress may be lost when you close the game."
    return "Saved on this device · Clearing site data removes these records."

func _load_profile() -> void:
    var primary := _read_profile(path)
    if not primary.is_empty():
        _data = primary
        _primary_valid = true
        return
    var backup := _read_profile(path + ".bak")
    if not backup.is_empty():
        _data = backup
        recovered_from_backup = true
        return
    if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
        load_error = ERR_FILE_CORRUPT
        read_only = true

func _read_profile(file_path: String) -> Dictionary:
    var file := FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        return {}
    var parsed = parser.data
    if not parsed is Dictionary or not _counter(parsed.get("schema_version")) or int(parsed["schema_version"]) not in [1, 2, SCHEMA_VERSION]:
        return {}
    if not _counter(parsed.get("match_serial")) or not parsed.get("commanders") is Dictionary or not parsed.get("active_match") is Dictionary:
        return {}
    if parsed["schema_version"] == 1:
        parsed["achievements"] = []
        parsed["unlocked_cards"] = []
    for field in ["achievements", "unlocked_cards"]:
        if not parsed.get(field) is Array:
            return {}
        var seen := {}
        for id in parsed[field]:
            if not id is String or id.is_empty() or seen.has(id):
                return {}
            seen[id] = true
    for id in parsed["commanders"]:
        var entry = parsed["commanders"][id]
        if not id is String or id.is_empty() or not entry is Dictionary:
            return {}
        for key in ["wins", "losses", "forfeits", "xp"]:
            if not _counter(entry.get(key)):
                return {}
            entry[key] = int(entry[key])
        if int(entry["forfeits"]) > int(entry["losses"]):
            return {}
    var pending: Dictionary = parsed["active_match"]
    if not pending.is_empty():
        if int(parsed["match_serial"]) < 1:
            return {}
        if not pending.get("id") is String or not pending.get("commander_id") is String or str(pending["commander_id"]).is_empty():
            return {}
        if pending["id"] != "match:%d" % int(parsed["match_serial"]):
            return {}
    parsed["match_serial"] = int(parsed["match_serial"])
    var receipt = parsed.get("last_settlement", {})
    if not receipt is Dictionary:
        return {}
    if not receipt.is_empty():
        if receipt.get("match_id") != "match:%d" % int(parsed["match_serial"]) or receipt.get("outcome") not in ["win", "loss", "forfeit"] or not receipt.get("commander_id") is String:
            return {}
        if not receipt.get("after") is Dictionary or not receipt.get("before") is Dictionary or not _counter(receipt.get("xp_awarded")):
            return {}
        receipt["xp_awarded"] = int(receipt["xp_awarded"])
        for field in ["before", "after"]:
            for key in ["wins", "losses", "forfeits", "xp", "played", "level", "xp_in_level", "xp_per_level"]:
                if not _counter(receipt[field].get(key)):
                    return {}
                receipt[field][key] = int(receipt[field][key])
    parsed["last_settlement"] = receipt
    return parsed

static func _counter(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) <= MAX_COUNTER and float(value) == floor(float(value))

func _save_profile() -> Error:
    if path.is_empty():
        return OK # Explicit in-memory profile for tests and visual fixtures.
    if read_only:
        return ERR_FILE_CORRUPT
    var file_path := ProjectSettings.globalize_path(path)
    var temporary := file_path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(_data))
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK:
        return error
    if _primary_valid and FileAccess.file_exists(file_path):
        error = DirAccess.copy_absolute(file_path, file_path + ".bak")
        if error != OK:
            return error
    error = DirAccess.rename_absolute(temporary, file_path)
    if error == OK:
        _primary_valid = true
        # Keep the backup current so recovery cannot turn an already settled win
        # into a forfeit by loading an older pending-match snapshot.
        error = DirAccess.copy_absolute(file_path, file_path + ".bak")
    return error
