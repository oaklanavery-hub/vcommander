extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db = root.get_node("ContentDatabase")
    var state = root.get_node("GameState")
    for commander in db.get_all_commanders():
        state.select_commander(str(commander["id"]))
        state.clear_army()
        for card in db.get_cards_by_set(str(commander["signature_set_id"])):
            state.equip_card(str(card["id"]))
        var first := play_match(state, 3187)
        var second := play_match(state, 3187)
        check(first == second, "seed reproduces complete match, all picks and battle events")
        check(not first.is_empty(), "all three starter themes run multiple rounds")
        print("Full match ", commander["element"], ": ", first.size(), " rounds; winner ", state.match_state.winner)
    # A mixed-element player loadout must also survive the complete loop.
    state.clear_army()
    var mixed := ["card_fire_01", "card_water_02", "card_earth_03", "card_earth_04"]
    for card_id in mixed:
        state.equip_card(card_id)
    play_match(state, 2026)
    if not failed:
        print("Full PvAI match integration tests passed.")
    quit(1 if failed else 0)

func play_match(state, seed_value: int) -> Array:
    check(state.begin_match(seed_value), "match starts")
    var transcript: Array = []
    for index in range(18):
        var prior_public: Dictionary = state.opponent_public_side.duplicate(true)
        var points: int = state.match_state.selections_for("player")
        check(state.draft.selection_points == points or state.draft.is_phase_complete(), "correct draft allowance")
        while not state.draft.is_phase_complete():
            check(state.draft.auto_select(), "legal player timeout pick")
        check(state.opponent_public_side == prior_public, "current AI picks stay hidden")
        check(state.run_battle(), "battle resolves")
        var result: Dictionary = state.battle_result
        transcript.append({"winner": result["winner"], "events": result["events"], "units": state.draft.unit_counts.duplicate(), "buffs": state.draft.buff_stacks.duplicate()})
        var prior_counts: Dictionary = state.draft.unit_counts.duplicate()
        var prior_buffs: Dictionary = state.draft.buff_stacks.duplicate()
        var loss_snapshot: Dictionary = state.match_state.losses.duplicate()
        check(state.run_battle() and state.match_state.losses == loss_snapshot, "replay cannot charge losses again")
        if index == 1:
            for unit in result["frames"][0]["units"]:
                check(unit["hp"] == unit["max_hp"], "round two respawns all accumulated units at full HP")
        if state.match_state.is_complete():
            check(not state.begin_next_round(), "no rounds after match completion")
            return transcript
        check(state.begin_next_round(), "continue match")
        check(state.draft.unit_counts == prior_counts, "army persists across rounds")
        check(state.draft.buff_stacks == prior_buffs, "buffs persist across rounds")
        check(not state.draft.commander_skill_used_this_round, "prepared skill resets each round")
    check(state.match_state.sudden_death, "long matches are valid repeated Sudden Death draws")
    return transcript

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
