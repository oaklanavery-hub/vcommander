extends SceneTree
const Match = preload("res://scripts/core/match_state.gd")
var failed := false

func _init() -> void:
    var state = Match.new()
    state.start()
    check(not state.resolve_round("player"), "cannot resolve draft")
    check(not state.advance_round(), "cannot skip draft")
    check(state.selections_for("player") == 3, "opening has three selections")
    for index in range(4):
        check(state.begin_battle(), "start battle")
        check(not state.begin_battle(), "cannot start twice")
        check(state.resolve_round("player"), "resolve battle")
        check(not state.resolve_round("player"), "cannot score same battle twice")
        if index < 3:
            check(state.advance_round(), "advance to next draft")
            check(state.selections_for("opponent") == 4, "loser gets comeback point")
            check(state.selections_for("player") == 3, "winner gets normal points")
    check(state.is_complete() and state.winner == "player", "four losses end match")
    check(not state.advance_round(), "complete match cannot advance")
    state.start()
    for index in range(4):
        state.begin_battle()
        state.resolve_round("draw")
        check(state.losses["player"] == index + 1 and state.losses["opponent"] == index + 1, "draw costs both sides a loss")
        if index < 3:
            state.advance_round()
            check(state.selections_for("player") == 4 and state.selections_for("opponent") == 4, "both get comeback after a draw")
    check(state.sudden_death and not state.is_complete(), "simultaneous fourth losses enter Sudden Death")
    state.advance_round()
    check(state.selections_for("player") == 3 and state.selections_for("opponent") == 3, "Sudden Death has three selections each")
    state.begin_battle()
    state.resolve_round("draw")
    check(state.sudden_death and not state.is_complete(), "Sudden Death draw repeats")
    state.advance_round()
    check(state.selections_for("player") == 3, "repeated Sudden Death still uses three")
    state.begin_battle()
    state.resolve_round("opponent")
    check(state.is_complete() and state.winner == "opponent", "decisive Sudden Death ends match")
    check(state.history.size() == 6, "history records each battle once")
    if not failed:
        print("MatchState tests passed: four-loss, comeback, draw, Sudden Death, transition guards.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
