class_name WarbandPresets
extends RefCounted

const DEFAULT_PATH := "user://warband_presets.cfg"
const SLOT_COUNT := 3
var path: String
var max_cards: int
var _content
var _progress: Object

func _init(content_source: Object, storage_path: String = DEFAULT_PATH, card_count: int = 4, progress: Object = null) -> void:
    _content = content_source
    path = storage_path
    max_cards = card_count
    _progress = progress

func _valid(commander_id: String, slot: int, cards: Array[String]) -> bool:
    if _content.get_commander(commander_id).is_empty() or slot < 0 or slot >= SLOT_COUNT or cards.size() != max_cards:
        return false
    var candidate := ArmyLoadout.new(max_cards)
    for id in cards:
        if _content.get_card(id).is_empty() or (_progress != null and not _progress.is_card_unlocked(id)) or not candidate.equip(id):
            return false
    return candidate.is_full()

func save_slot(commander_id: String, slot: int, cards: Array[String]) -> Error:
    if not _valid(commander_id, slot, cards):
        return ERR_INVALID_PARAMETER
    var config := ConfigFile.new()
    var error := config.load(path)
    if error != OK and error != ERR_FILE_NOT_FOUND:
        return error
    config.set_value(commander_id, "preset_%d" % slot, cards)
    return config.save(path)

func load_slot(commander_id: String, slot: int) -> Array[String]:
    var result: Array[String] = []
    var config := ConfigFile.new()
    if config.load(path) != OK:
        return result
    var raw = config.get_value(commander_id, "preset_%d" % slot, [])
    if not raw is Array and not raw is PackedStringArray:
        return result
    for id in raw:
        if not id is String:
            result.clear()
            return result
        result.append(id)
    if not _valid(commander_id, slot, result):
        result.clear()
    return result
