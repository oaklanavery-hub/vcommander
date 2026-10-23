extends SceneTree

var failed := false
var db: Node
var source: Node
const PROFILE := "user://test_match_recovery_profile.json"
const SAVE := "user://test_match_recovery_checkpoint.json"

func _init() -> void:
    call_deferred("run")

func fixture(snapshot: Dictionary) -> Node:
    var value = load("res://scripts/core/game_state.gd").new()
    root.add_child(value)
    value.commander_progress = CommanderProgress.new(db, PROFILE)
    value.commander_progress.path = ""
    value.local_store = LocalMatchStore.new("")
    value.local_store.save(snapshot)
    return value

func run() -> void:
    db = root.get_node("ContentDatabase")
    source = root.get_node("GameState")
    check(source.local_store.path.is_empty(), "scripted runs never touch the real recovery checkpoint")
    cleanup()
    source.commander_progress = CommanderProgress.new(db, PROFILE)
    source.local_store = LocalMatchStore.new(SAVE)
    source.select_commander("commander_fire_01")
    source.equip_starter_army()
    check(source.begin_match(9007199254740999), "match accepts an exact 64-bit seed")
    source.draft.select_offer(0)
    source.update_draft_clock(17.4)
    var opening: Dictionary = source.local_store.candidates()[0]
    var restored := fixture(opening)
    check(restored.has_saved_match() and restored.resume_match(), "opening draft resumes before any mastery tracking")
    check(restored.match_seed == 9007199254740999 and restored.draft_time_left == 17.4, "seed and remaining clock survive JSON without precision loss")
    check(restored.draft.snapshot() == source.draft.snapshot(), "offers, counts and RNG state restore exactly")
    source.draft.auto_select()
    restored.draft.auto_select()
    check(restored.draft.snapshot() == source.draft.snapshot(), "the next random pick and following offer are identical")
    restored.free()
    while not source.draft.is_phase_complete():
        source.draft.auto_select()
    check(source.run_battle(), "first real battle resolves")
    var active: Dictionary = source.commander_progress.active_match()
    var result_fingerprint := JSON.stringify(source.battle_result).sha256_text()
    var scored: Dictionary = source.local_store.candidates()[0]
    restored = fixture(scored)
    check(restored.resume_match(), "scored round resumes against the same pending profile identity")
    check(JSON.stringify(restored.battle_result).sha256_text() == result_fingerprint, "reconstructed battle events and frames are identical")
    check(restored.match_state.losses == source.match_state.losses and restored.match_state.history.size() == source.match_state.history.size() and restored.match_state.history[0]["winner"] == source.match_state.history[0]["winner"] and is_equal_approx(float(restored.match_state.history[0]["duration"]), float(source.match_state.history[0]["duration"])), "reconstruction cannot charge another heart or add a history entry")
    check(restored.run_battle() and restored.commander_progress.active_match() == active, "reopening the battle does not settle or restart a match")
    source.mark_battle_watched()
    var watched: Dictionary = source.local_store.candidates()[0]
    var watched_state := fixture(watched)
    check(watched_state.resume_match() and watched_state.battle_watched, "already watched result retains its presentation boundary")
    watched_state.free()
    restored.free()
    # Crash after profile settlement but before the final checkpoint write.
    var prepared: Dictionary = {}
    var prepared_profile := ""
    var guard := 0
    while not source.match_state.is_complete() and guard < 12:
        guard += 1
        check(source.begin_next_round(), "next round continues one match identity")
        while not source.draft.is_phase_complete():
            source.draft.auto_select()
        for card in db.get_cards_by_ids(source.army.get_cards()):
            source.draft.unit_counts[str(card["id"])] = int(card["unit_cap"])
        for buff in db.get_all_buffs():
            source.draft.buff_stacks[str(buff["id"])] = 6
        source.checkpoint()
        prepared = source.local_store.candidates()[0]
        prepared_profile = FileAccess.get_file_as_string(PROFILE)
        check(source.run_battle(), "strengthened integration fixture finishes a legal round")
    check(source.match_state.is_complete(), "fixture reaches a final whole-match result")
    var settled: Dictionary = source.commander_progress.record(source.selected_commander_id)
    var receipt: Dictionary = source.mastery_reward.duplicate(true)
    restored = fixture(prepared)
    check(restored.resume_match() and restored.run_battle(), "prepared final round can recover after its profile was already settled")
    check(restored.commander_progress.record(source.selected_commander_id) == settled and restored.mastery_reward == receipt, "persisted receipt prevents duplicate wins/XP and preserves rewards")
    restored.free()
    var completed: Dictionary = source.local_store.candidates()[0]
    var pending_path := "user://test_match_recovery_pending.json"
    var pending_file := FileAccess.open(pending_path, FileAccess.WRITE)
    pending_file.store_string(prepared_profile)
    pending_file.close()
    restored = fixture(completed)
    restored.commander_progress = CommanderProgress.new(db, pending_path)
    restored.commander_progress.path = ""
    check(restored.resume_match() and restored.commander_progress.record(source.selected_commander_id) == settled, "a completed checkpoint reconciles an older still-pending profile write")
    restored.leave_match()
    check(restored.commander_progress.record(source.selected_commander_id) == settled, "a recovered settled outcome never becomes a forfeit after a failed profile write")
    restored.free()
    restored = fixture(completed)
    check(restored.resume_match() and restored.match_state.is_complete(), "completed result restores without another reward")
    restored.leave_match()
    check(restored.commander_progress.record(source.selected_commander_id) == settled, "leaving a recovered final replay cannot become a forfeit")
    restored.free()
    # A valid backup survives a damaged primary. Bad metadata never mutates state.
    var file := FileAccess.open(SAVE, FileAccess.WRITE)
    file.store_string("broken json")
    file.close()
    check(source.has_saved_match(), "a current backup recovers a damaged checkpoint")
    var invalid := completed.duplicate(true)
    invalid["draft"]["unit_counts"][source.army.get_cards()[0]] = 999
    restored = fixture(invalid)
    check(not restored.resume_match() and not restored.match_started, "illegal caps cannot partially restore a game")
    invalid = completed.duplicate(true)
    invalid["public_side"]["cards"] = [false, {}, 1, "broken"]
    restored.local_store.save(invalid)
    check(not restored.resume_match() and not restored.match_started, "corrupted rival display metadata is rejected before any UI can read it")
    restored.local_store.save({"schema": 1, "content": "old rules"})
    check(not restored.has_saved_match() and not restored.recovery_notice.is_empty(), "incompatible content gives a visible notice")
    check(restored.commander_progress.record(source.selected_commander_id) == settled, "invalid recovery never edits mastery")
    restored.free()
    source.leave_match()
    source.commander_progress = CommanderProgress.new(db, "")
    source.local_store = LocalMatchStore.new("")
    cleanup()
    if not failed:
        print("Match recovery tests passed: isolated storage, exact RNG/offers/timer, identical battles/hearts, watched results, crash-window settlement, backup and invalid-save handling.")
    quit(1 if failed else 0)

func cleanup() -> void:
    for path in [PROFILE, SAVE, "user://test_match_recovery_pending.json"]:
        for suffix in ["", ".bak", ".tmp"]:
            if FileAccess.file_exists(path + suffix):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
