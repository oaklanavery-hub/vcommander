extends SceneTree

const DraftSystemScript = preload("res://scripts/draft/draft_system.gd")

func _card(card_id: String, summon_amount: int, unit_cap: int) -> Dictionary:
    return {
        "id": card_id,
        "display_name": card_id,
        "summon_amount": summon_amount,
        "unit_cap": unit_cap
    }

func _buff(buff_id: String) -> Dictionary:
    return {
        "id": buff_id,
        "display_name": buff_id,
        "max_stacks": 3
    }

func _init() -> void:
    var cards := [
        _card("a", 1, 2),
        _card("b", 2, 4),
        _card("c", 2, 6),
        _card("d", 1, 2)
    ]
    var buffs := [_buff("atk"), _buff("hp"), _buff("def"), _buff("spd"), _buff("move")]

    var draft = DraftSystemScript.new()
    draft.configure(["a", "b", "c", "d"], cards, buffs, 12345)
    draft.begin_round(true, false)

    _assert(draft.selection_points == 3, "opening round must start with three selections")
    _assert(draft.current_offer.size() == 3, "opening offer should contain three choices")
    for option in draft.current_offer:
        _assert(option.get("type") == "unit", "opening round must be Army-only")

    var first_id := str(draft.current_offer[0].get("id"))
    _assert(draft.select_offer(0), "unit choice should apply")
    _assert(draft.get_unit_count(first_id) > 0, "unit choice should add units")
    _assert(draft.selection_points == 2, "selection should spend one point")

    _assert(draft.use_commander_skill(), "Commander skill should be usable once in the round")
    _assert(not draft.use_commander_skill(), "Commander skill cannot be used twice in one round")
    _assert(draft.commander_skill_uses == 1, "skill use should persist")
    _assert(draft.selection_points == 1, "skill should cost one selection")

    var deterministic_a = DraftSystemScript.new()
    var deterministic_b = DraftSystemScript.new()
    deterministic_a.configure(["a", "b", "c", "d"], cards, buffs, 777)
    deterministic_b.configure(["a", "b", "c", "d"], cards, buffs, 777)
    deterministic_a.begin_round(false, false)
    deterministic_b.begin_round(false, false)
    _assert(deterministic_a.current_offer == deterministic_b.current_offer, "same seed should produce same offer")

    var normal = DraftSystemScript.new()
    normal.configure(["a", "b", "c", "d"], cards, buffs, 9876)
    normal.begin_round(false, true)
    _assert(normal.selection_points == 4, "previous-round loser should get four selections")
    _assert(_count_type(normal.current_offer, "buff") <= 2, "offer may have at most two buffs while units remain")
    _assert(_count_type(normal.current_offer, "unit") >= 1, "offer must include an Army card while units remain")

    normal.unit_counts["a"] = 2
    normal.unit_counts["b"] = 4
    normal.unit_counts["c"] = 6
    normal.unit_counts["d"] = 2
    normal.refresh_offer()
    _assert(normal.current_offer.size() == 3, "all-unit-exhausted offer should still show three buffs")
    _assert(_count_type(normal.current_offer, "buff") == 3, "three buffs are allowed after all units exhaust")

    normal.buff_stacks["atk"] = 3
    normal.refresh_offer()
    for option in normal.current_offer:
        _assert(str(option.get("id")) != "atk", "3/3 buff must leave the offer pool")

    print("DraftSystem tests passed.")
    quit(0)

func _count_type(options: Array, option_type: String) -> int:
    var count := 0
    for option in options:
        if str(option.get("type", "")) == option_type:
            count += 1
    return count

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("TEST FAILED: %s" % message)
    quit(1)
