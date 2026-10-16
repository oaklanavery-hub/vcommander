extends SceneTree

const ArmyLoadoutScript = preload("res://scripts/army/army_loadout.gd")

var _failed := false

func _init() -> void:
    var army = ArmyLoadoutScript.new(4)

    _assert(army.size() == 0, "new Army should be empty")
    _assert(army.equip("a"), "first card should equip")
    _assert(not army.equip("a"), "duplicate card IDs must be rejected")
    _assert(army.equip("b"), "second unique card should equip")
    _assert(army.equip("c"), "third unique card should equip")
    _assert(army.equip("d"), "fourth unique card should equip")
    _assert(army.is_full(), "Army should be full at four cards")
    _assert(not army.equip("e"), "fifth card must be rejected")
    _assert(army.contains("c"), "contains should find equipped IDs")
    _assert(army.unequip_at(1), "occupied slot should be removable")
    _assert(army.size() == 3, "removing a slot should reduce Army size")
    _assert(army.equip("e"), "empty slot should accept another unique card")
    _assert(not army.unequip_at(10), "invalid slot should be rejected")

    army.clear()
    _assert(army.size() == 0, "clear should empty the Army")

    if not _failed:
        print("ArmyLoadout tests passed.")
    quit(1 if _failed else 0)

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("TEST FAILED: %s" % message)
