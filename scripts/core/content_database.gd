extends Node

var commanders: Dictionary = {}
var cards: Dictionary = {}
var sets: Dictionary = {}
var buffs: Dictionary = {}
var balances: Dictionary = {}
var progression: Dictionary = {}
var tactics: Dictionary = {}
var load_errors: Array[String] = []

func _ready() -> void:
    reload()

func reload() -> void:
    commanders.clear()
    cards.clear()
    sets.clear()
    buffs.clear()
    balances.clear()
    progression.clear()
    tactics.clear()
    load_errors.clear()

    _load_json_directory("res://data/commanders", commanders)
    _load_json_tree("res://data/cards", cards)
    _load_json_directory("res://data/sets", sets)
    _load_json_directory("res://data/buffs", buffs)
    _load_json_directory("res://data/balance", balances)
    _load_json_directory("res://data/progression", progression)
    _load_json_directory("res://data/tactics", tactics)

func get_specializations() -> Dictionary:
    return tactics.get("commander_specializations", {})

func get_summary() -> Dictionary:
    return {
        "ok": load_errors.is_empty(),
        "commanders": commanders.size(),
        "cards": cards.size(),
        "sets": sets.size(),
        "buffs": buffs.size(),
        "balances": balances.size(),
        "errors": load_errors.duplicate()
    }

func get_commander(commander_id: String) -> Dictionary:
    return commanders.get(commander_id, {})

func get_signature_set(set_id: String) -> Dictionary:
    return sets.get(set_id, {})

func get_card(card_id: String) -> Dictionary:
    return cards.get(card_id, {})

func get_buff(buff_id: String) -> Dictionary:
    return buffs.get(buff_id, {})

func get_game_balance() -> Dictionary:
    return balances.get("game_balance", {})

func get_mastery_rules() -> Dictionary:
    return progression.get("commander_mastery", {})

func get_upgrade_rules() -> Dictionary:
    return progression.get("unit_upgrades", {})

func get_achievement_rules() -> Dictionary:
    return progression.get("achievements", {})

func get_all_commanders() -> Array[Dictionary]:
    return _sorted_values(commanders)

func get_all_cards() -> Array[Dictionary]:
    return _sorted_values(cards)

func get_all_buffs() -> Array[Dictionary]:
    return _sorted_values(buffs)

func get_cards_by_ids(card_ids: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for card_id in card_ids:
        var card := get_card(str(card_id))
        if not card.is_empty():
            result.append(card)
    return result

func get_cards_by_set(set_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for card in get_all_cards():
        if str(card.get("set_id", "")) == set_id:
            result.append(card)
    return result

func _sorted_values(source: Dictionary) -> Array[Dictionary]:
    var ids: Array = source.keys()
    ids.sort()
    var result: Array[Dictionary] = []
    for content_id in ids:
        result.append(source[content_id])
    return result

func _load_json_tree(root_path: String, target: Dictionary) -> void:
    var directory := DirAccess.open(root_path)
    if directory == null:
        load_errors.append("Cannot open directory: %s" % root_path)
        return

    for directory_name in directory.get_directories():
        _load_json_directory(root_path.path_join(directory_name), target)
    _load_json_directory(root_path, target)

func _load_json_directory(path: String, target: Dictionary) -> void:
    var directory := DirAccess.open(path)
    if directory == null:
        load_errors.append("Cannot open directory: %s" % path)
        return

    for file_name in directory.get_files():
        if not file_name.ends_with(".json"):
            continue
        var file_path := path.path_join(file_name)
        var file := FileAccess.open(file_path, FileAccess.READ)
        if file == null:
            load_errors.append("Cannot read: %s" % file_path)
            continue
        var parsed = JSON.parse_string(file.get_as_text())
        if typeof(parsed) != TYPE_DICTIONARY:
            load_errors.append("Invalid JSON object: %s" % file_path)
            continue
        var content_id: String = str(parsed.get("id", ""))
        if content_id.is_empty():
            load_errors.append("Missing id: %s" % file_path)
            continue
        if target.has(content_id):
            load_errors.append("Duplicate id: %s" % content_id)
            continue
        target[content_id] = parsed
