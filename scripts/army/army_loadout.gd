class_name ArmyLoadout
extends RefCounted

var max_slots: int
var equipped_card_ids: Array[String] = []

func _init(slot_count: int = 4) -> void:
    max_slots = max(1, slot_count)

func equip(card_id: String) -> bool:
    if card_id.is_empty() or is_full():
        return false
    equipped_card_ids.append(card_id)
    return true

func unequip_at(index: int) -> bool:
    if index < 0 or index >= equipped_card_ids.size():
        return false
    equipped_card_ids.remove_at(index)
    return true

func remove_one(card_id: String) -> bool:
    var index := equipped_card_ids.find(card_id)
    if index < 0:
        return false
    equipped_card_ids.remove_at(index)
    return true

func clear() -> void:
    equipped_card_ids.clear()

func is_full() -> bool:
    return equipped_card_ids.size() >= max_slots

func size() -> int:
    return equipped_card_ids.size()

func get_cards() -> Array[String]:
    var result: Array[String] = []
    for card_id in equipped_card_ids:
        result.append(card_id)
    return result
