extends SceneTree

const SetBonusCheckerScript = preload("res://scripts/commanders/set_bonus_checker.gd")

func _card(card_id: String, set_id: String) -> Dictionary:
    return {"id": card_id, "set_id": set_id}

func _init() -> void:
    var fire_four := [
        _card("a", "fire"),
        _card("b", "fire"),
        _card("c", "fire"),
        _card("d", "fire")
    ]
    var mixed := [
        _card("a", "fire"),
        _card("b", "fire"),
        _card("c", "fire"),
        _card("x", "water")
    ]

    _assert(SetBonusCheckerScript.progress(fire_four, "fire") == 4, "four themed cards should show 4/4 progress")
    _assert(SetBonusCheckerScript.is_complete(fire_four, "fire", 4), "any four cards from the Commander theme should activate")
    _assert(SetBonusCheckerScript.progress(mixed, "fire") == 3, "mixed Army should show only matching theme progress")
    _assert(not SetBonusCheckerScript.is_complete(mixed, "fire", 4), "mixed fourth card must prevent activation")
    _assert(not SetBonusCheckerScript.is_complete(fire_four.slice(0, 3), "fire", 4), "three cards must not activate")

    print("SetBonusChecker tests passed.")
    quit(0)

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("TEST FAILED: %s" % message)
    quit(1)
