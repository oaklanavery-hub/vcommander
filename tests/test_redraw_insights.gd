extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    check(state.match_insights.store.path.is_empty() and state.match_preferences.path.is_empty(), "automated matches never use actual pacing/preferences files")
    check(not state.match_preferences.redraw_experiment, "default draft has no manual redraw")
    state.select_commander("commander_water_01")
    state.equip_starter_army()
    state.match_preferences.redraw_experiment = true
    check(state.begin_match(317), "opt-in match starts")
    check(state.draft.redraw_enabled and state.opponent.draft.redraw_enabled, "both sides have the same optional rule")
    state.update_draft_clock(8.5)
    var points: int = state.draft.selection_points
    check(state.draft.redraw(), "one opening redraw is legal")
    check(state.draft.selection_points == points and state.draft_time_left == 8.5, "redraw grants neither an extra selection nor extra time")
    check(state.draft.current_offer.all(func(option): return option.get("type") == "unit"), "opening redraw remains army-only")
    check(not state.draft.redraw(), "second redraw in the same round is rejected")
    var saved: Dictionary = state.local_store.candidates()[0]
    var recovered = load("res://scripts/core/game_state.gd").new()
    root.add_child(recovered)
    recovered.local_store.save(saved)
    check(recovered.resume_match() and not recovered.draft.can_redraw() and recovered.draft_time_left == 8.5, "restarting cannot replenish the redraw allowance or timer")
    recovered.free()
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    check(not state.draft.redraw(), "a completed draft cannot redraw")
    check(state.run_battle(), "experiment uses normal combat")
    var summary: Dictionary = state.match_insights.summary(1)
    check(summary["rounds"] == 1 and summary["average_draft"] == 21.5, "active draft seconds are recorded independently of simulation duration")
    state.run_battle()
    check(state.match_insights.summary(1)["rounds"] == 1, "reopening a battle cannot duplicate observations")
    state.record_watch_time(3.0)
    state.mark_battle_watched()
    state.mark_battle_watched()
    check(state.match_insights.summary(1)["watch_seconds"] == 3.0, "viewing time is separate and idempotent")
    check(state.begin_next_round() and state.draft.can_redraw(), "allowance refreshes at the next round")
    state.leave_match()
    state.match_preferences.redraw_experiment = false
    var journal := MatchInsights.new("")
    var metadata := {"commander": "fixture", "difficulty": "standard", "redraw": false}
    var round_info := {"round": 1, "winner": "draw", "reason": "timer", "duration": 120.0, "draft_seconds": 12.0, "sudden": true}
    journal.record_round("fixture", metadata, round_info)
    journal.record_round("fixture", metadata, round_info)
    var observation := journal.summary()
    check(observation["rounds"] == 1 and observation["timeouts"] == 1 and observation["sudden_draws"] == 1, "timer/Sudden Death evidence counts a scored round only once")
    journal.record_watch("fixture", 1, 30)
    journal.record_watch("fixture", 1, 30)
    check(journal.summary()["watch_seconds"] == 30, "recovered watch receipts cannot duplicate viewing time")
    check(journal.summary(1)["matches"] == 0, "default and opted-in observations remain distinguishable")
    for index in range(40):
        journal.record_round("fixture:%d" % index, metadata, round_info)
    check(journal.entries.size() == MatchInsights.MAX_MATCHES, "local history is bounded")
    if not failed:
        print("Redraw and pacing tests passed: opt-in/equal rules, unchanged pick clock, persisted allowance, next-round reset, isolated metrics, timing separation, deduplication and bounded samples.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
