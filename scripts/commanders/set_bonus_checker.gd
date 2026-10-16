class_name SetBonusChecker
extends RefCounted

static func is_complete(equipped_card_ids: Array, required_card_ids: Array, required_count: int = 4) -> bool:
    if required_count <= 0:
        return false
    if required_card_ids.size() != required_count:
        return false

    var equipped_unique: Dictionary = {}
    for card_id in equipped_card_ids:
        equipped_unique[str(card_id)] = true

    for required_id in required_card_ids:
        if not equipped_unique.has(str(required_id)):
            return false

    return true

static func progress(equipped_card_ids: Array, required_card_ids: Array) -> int:
    var equipped_unique: Dictionary = {}
    for card_id in equipped_card_ids:
        equipped_unique[str(card_id)] = true

    var matched := 0
    for required_id in required_card_ids:
        if equipped_unique.has(str(required_id)):
            matched += 1
    return matched
