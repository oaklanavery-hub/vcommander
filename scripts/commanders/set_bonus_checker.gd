class_name SetBonusChecker
extends RefCounted

static func progress(equipped_cards: Array, set_id: String) -> int:
    if set_id.is_empty():
        return 0
    var matched := 0
    var seen: Dictionary = {}
    for card in equipped_cards:
        if typeof(card) != TYPE_DICTIONARY:
            continue
        var card_id := str(card.get("id", ""))
        if card_id.is_empty() or seen.has(card_id):
            continue
        seen[card_id] = true
        if str(card.get("set_id", "")) == set_id:
            matched += 1
    return matched

static func is_complete(equipped_cards: Array, set_id: String, required_count: int = 4) -> bool:
    if required_count <= 0 or equipped_cards.size() != required_count:
        return false
    return progress(equipped_cards, set_id) == required_count
