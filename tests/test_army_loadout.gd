extends SceneTree

const ArmyLoadoutScript = preload("res://scripts/army/army_loadout.gd")

func _init() -> void:
    var army = ArmyLoadoutScript.new(4)

    _assert(army.size() == 0, "new Army should be empty")
    _assert(army.equip("a"), "first card should equip")
    _assert(army.equip("a"), "duplicate IDs are not prohibited by current rules")
    _assert(army.equip("b"), "third card should equip")
    _assert(army.equip("c"), "fourth card should equip")
    _assert(army.is_full(), "Army should be full at four cards")
    _assert(not army.equip("d"), "fifth card must be rejected")
    _assert(army.unequip_at(1), "occupied slot should be removable")
    _assert(army.size() == 3, "removing a slot should reduce Army size")
    _assert(army.equip("d"), "empty slot should accept another card")
    _assert(not army.unequip_at(10), "invalid slot should be rejected")

    army.clear()
    _assert(army.size() == 0, "clear should empty the Army")

    print("ArmyLoadout tests passed.")
    quit(0)

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("TEST FAILED: %s" % message)
    quit(1)
