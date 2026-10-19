extends SceneTree

var failed := false
var db: Node
var state: Node

func _init() -> void:
    call_deferred("run")

func prepare(commander: String, seed_value: int = 3187) -> void:
    check(state.select_commander(commander), "Commander can be selected")
    state.clear_army()
    for card in db.get_cards_by_set(str(db.get_commander(commander)["signature_set_id"])):
        state.equip_card(str(card["id"]))
    check(state.begin_match(seed_value), "legal match starts")

func draft_and_battle() -> void:
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    check(state.run_battle(), "real headless battle resolves")

func run() -> void:
    db = root.get_node("ContentDatabase")
    state = root.get_node("GameState")
    check(state.commander_progress.path.is_empty(), "automated script runs never open the actual player profile")
    state.commander_progress = CommanderProgress.new(db, "")
    var ids: Array = db.commanders.keys()
    var first := str(ids[0])
    var second := str(ids[1])
    prepare(first)
    state.leave_match()
    check(state.commander_progress.record(first)["played"] == 0, "leaving the opening draft before battle never records a match")
    prepare(first)
    draft_and_battle()
    var pending: Dictionary = state.commander_progress.active_match()
    check(not pending.is_empty() and state.commander_progress.record(first)["played"] == 0 and state.mastery_reward.is_empty(), "one battle is not a complete multi-round match and grants no XP")
    var original_losses: Dictionary = state.match_state.losses.duplicate()
    check(state.run_battle() and state.match_state.losses == original_losses and state.commander_progress.active_match() == pending, "re-entering a scored battle cannot start a second tracked match")
    check(state.begin_next_round(), "the same tracked match continues")
    draft_and_battle()
    check(state.commander_progress.active_match() == pending and state.commander_progress.record(first)["played"] == 0, "subsequent rounds keep one pending identity")
    state.leave_match()
    state.leave_match()
    check(state.commander_progress.record(first)["played"] == 1 and state.commander_progress.record(first)["losses"] == 1 and state.commander_progress.record(first)["forfeits"] == 1 and state.commander_progress.record(first)["xp"] == 0, "leaving an unfinished played match records exactly one forfeit loss")
    prepare(first)
    draft_and_battle()
    state.select_commander(second)
    check(state.commander_progress.record(first)["forfeits"] == 2 and state.commander_progress.record(second)["played"] == 0, "changing Commander settles the old owner's match instead of moving its record")
    test_completed_match(first, true)
    test_completed_match(second, false)
    state.leave_match()
    if not failed:
        print("Mastery lifecycle tests passed: script isolation, unplayed drafts, whole-match ownership, replay/reset idempotency, forfeits, real final wins/losses and one permanent reward.")
    quit(1 if failed else 0)

func test_completed_match(commander: String, player_strong: bool) -> void:
    prepare(commander)
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    # Legal capped rosters/buffs create decisive integration fixtures in one round.
    state.match_state.start(1)
    set_strength(state.draft, db.get_cards_by_ids(state.army.get_cards()), player_strong)
    set_strength(state.opponent.draft, state.opponent.get_side()["cards"], not player_strong)
    var before: Dictionary = state.commander_progress.record(commander)
    check(state.run_battle() and state.match_state.is_complete(), "decisive full match resolves")
    check(state.match_state.winner == ("player" if player_strong else "opponent"), "fixture produces the intended final outcome")
    var reward: Dictionary = state.mastery_reward.duplicate(true)
    var after: Dictionary = state.commander_progress.record(commander)
    var expected := 100 if player_strong else 25
    check(after["played"] == before["played"] + 1 and after["xp"] == before["xp"] + expected and reward["xp_awarded"] == expected, "only final match outcome grants its approved XP")
    check(state.commander_progress.active_match().is_empty(), "final settlement clears the persisted pending match")
    state.run_battle()
    state.leave_match()
    check(state.commander_progress.record(commander) == after, "replaying or leaving a completed match cannot award again or change it into a forfeit")

func set_strength(draft, cards: Array, strong: bool) -> void:
    draft.unit_counts.clear()
    draft.buff_stacks.clear()
    for i in range(cards.size()):
        if strong or i == 0:
            draft.unit_counts[str(cards[i]["id"])] = int(cards[i]["unit_cap"]) if strong else 1
    if strong:
        for buff in db.get_all_buffs():
            draft.buff_stacks[str(buff["id"])] = 3

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
