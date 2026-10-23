extends SceneTree

var failed := false
var db: Node
var source: Node

func _init() -> void:
    call_deferred("run")

func fixture(snapshot: Dictionary) -> Node:
    var state = load("res://scripts/core/game_state.gd").new()
    root.add_child(state)
    state.commander_progress = CommanderProgress.new(db, "")
    state.commander_progress._data = source.commander_progress._data.duplicate(true)
    state.commander_progress.last_receipt = source.commander_progress.last_receipt.duplicate(true)
    state.local_store = LocalMatchStore.new("")
    state.local_store.save(JSON.parse_string(JSON.stringify(snapshot)))
    return state

func run() -> void:
    db = root.get_node("ContentDatabase")
    source = load("res://scripts/core/game_state.gd").new()
    root.add_child(source)
    source.commander_progress = CommanderProgress.new(db, "")
    source.local_store = LocalMatchStore.new("")
    source.select_commander("commander_water_01")
    source.equip_starter_army()
    source.begin_match(204757)
    for index in range(4):
        while not source.draft.is_phase_complete():
            source.draft.auto_select()
        source.match_state.begin_battle()
        source.match_state.resolve_round("draw", 120)
        source.begin_next_round()
    source.draft.current_offer.assign([{"type": "buff", "id": "buff_attack"}])
    source.draft.select_offer(0)
    source.opponent.draft._apply_buff("buff_attack")
    source.checkpoint()
    var pending: Dictionary = source.local_store.candidates()[0]
    var state := fixture(pending)
    check(state.resume_match(), "an in-progress Sudden Death draft resumes through JSON")
    check(state.draft.snapshot() == source.draft.snapshot() and state.opponent.draft.snapshot() == source.opponent.draft.snapshot(), "both mixed-cohort drafts and their RNG resume exactly")
    check(state.opponent_public_side == source.opponent_public_side, "recovery keeps the prior public army separate from hidden enhanced rival picks")
    check(state.get_player_combat_side()["round_time_limit"] == 180 and state.draft.sudden_death_buff_stacks["buff_attack"] == 1, "new player bonus strength and each-battle ceiling survive restart")
    state.free()
    var invalid := pending.duplicate(true)
    invalid["public_side"]["buffs"].append({"definition": db.get_buff("buff_attack"), "stacks": 10000, "sudden_death_stacks": 10000})
    state = fixture(invalid)
    check(not state.resume_match(), "a corrupted public cohort cannot reveal or invent a rival's hidden bonuses")
    state.free()
    # Build an old-content, already-scored Sudden Death checkpoint from the same
    # legal roster. No real profile or developer credentials are used.
    var legacy := pending.duplicate(true)
    legacy["content"] = source._content_fingerprint(false, true)
    legacy["match"]["phase"] = "result"
    legacy["match"]["losses"] = {"player": 5, "opponent": 5}
    legacy["match"]["history"].append({"round": 5, "winner": "draw", "duration": 120.0, "sudden_death": true})
    for key in ["draft", "opponent_draft"]:
        legacy[key].erase("sudden_death_buff_stacks")
        legacy[key].erase("round_time_limit")
        legacy[key]["points"] = 0
        legacy[key]["offer"] = []
    for key in ["sudden_death", "round_time_limit", "sudden_death_power_multiplier"]:
        legacy["public_side"].erase(key)
    for entry in legacy["public_side"]["buffs"]:
        entry.erase("sudden_death_stacks")
        entry.erase("sudden_death_multiplier")
    state = fixture(legacy)
    check(state.resume_match(), "v0.18 scored Sudden Death checkpoints remain resumable")
    check(state.battle_result["round_time_limit"] == 120 and state.draft.sudden_death_buff_stacks.values().all(func(n): return n == 0), "old completed replay retains 120 seconds and ordinary earlier bonuses")
    var replay: Dictionary = state.battle_result.duplicate(true)
    var migrated: Dictionary = state.local_store.candidates()[0]
    var next := fixture(migrated)
    check(next.resume_match() and next.battle_result == replay, "a migrated checkpoint preserves exactly the same replay on a second restart")
    var earlier: Array = next.draft.get_buff_states()
    check(next.begin_next_round() and next.draft.round_time_limit == 180 and next.draft.get_buff_states() == earlier, "the first new round after old replay uses 180 seconds without upgrading old powers")
    next.draft.current_offer.assign([{"type": "buff", "id": "buff_attack"}])
    next.draft.select_offer(0)
    check(next.draft.sudden_death_buff_stacks["buff_attack"] == 1, "only a new post-migration pick receives enhanced strength")
    next.free()
    state.free()
    while not source.draft.is_phase_complete():
        source.draft.auto_select()
    check(source.run_battle(), "a prepared Sudden Death battle resolves with actual combat")
    var result: Dictionary = source.local_store.candidates()[0]
    var fingerprint: String = JSON.stringify(source.battle_result).sha256_text()
    state = fixture(result)
    check(state.resume_match() and JSON.stringify(state.battle_result).sha256_text() == fingerprint, "new 180-second battle reconstructs events and frames without rescoring")
    check(state.match_state.history == source.match_state.history and state.match_state.losses == source.match_state.losses, "reconstruction never charges another heart")
    state.free()
    invalid = result.duplicate(true)
    invalid["match"]["history"][0]["duration"] = 180
    state = fixture(invalid)
    check(not state.resume_match(), "180-second history is rejected for normal rounds")
    state.free()
    invalid = result.duplicate(true)
    invalid["match"]["history"].back()["duration"] = 180
    state = fixture(invalid)
    check(state.resume_match(), "180-second history is accepted for Sudden Death")
    state.free()
    source.free()
    if not failed:
        print("Sudden Death recovery tests passed: mixed cohorts, hidden rival picks, old v0.18 replay/migration, repeat restart, next-round upgrade, actual combat replay, hearts and per-round history limits.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
