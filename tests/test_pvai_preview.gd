extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    state.select_commander("commander_fire_01")
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    check(state.begin_match(1729), "match starts")
    var public_before: Dictionary = state.opponent_public_side.duplicate(true)
    check(not state.run_combat_preview(), "cannot fight before picks spent")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    check(state.opponent_public_side == public_before, "player picks cannot expose opponent picks")
    check(public_before["unit_counts"].values().all(func(count): return count == 0), "opening rival counts concealed")
    check(state.run_combat_preview(), "PvAI simulation runs")
    var result: Dictionary = state.battle_result.duplicate(true)
    check(state.opponent_combat_side["unit_counts"].values().any(func(count): return count > 0), "rival composition revealed at combat")
    check(state.run_combat_preview() and state.battle_result == result, "revisiting combat reuses result")
    if not failed:
        print("PvAI preview integration tests passed.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
