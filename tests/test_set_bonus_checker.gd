extends SceneTree

func _init() -> void:
    var required := ["a", "b", "c", "d"]

    _assert(SetBonusChecker.progress(["a", "b"], required) == 2, "2/4 progress should equal 2")
    _assert(not SetBonusChecker.is_complete(["a", "b", "c"], required), "3/4 must not activate")
    _assert(SetBonusChecker.is_complete(["a", "b", "c", "d"], required), "4/4 must activate")
    _assert(SetBonusChecker.is_complete(["d", "b", "a", "c"], required), "order must not matter")
    _assert(not SetBonusChecker.is_complete(["a", "b", "c", "x"], required), "wrong fourth card must not activate")

    print("SetBonusChecker tests passed.")
    quit(0)

func _assert(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("TEST FAILED: %s" % message)
    quit(1)
