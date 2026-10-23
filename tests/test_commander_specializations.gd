extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    var catalog: Dictionary = db.get_specializations()
    var originals: Dictionary = db.cards.duplicate(true)
    for commander in db.get_all_commanders():
        check(CommanderSpecializations.options(catalog, commander["id"]).size() == 2, "two paths for " + commander["id"])
    var fire_cards: Array = db.get_cards_by_ids(["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_05"])
    var options := {"specialization_experiment": true, "commander_id": "commander_fire_01", "specialization_catalog": catalog}
    var draft := DraftSystem.new()
    draft.configure(["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_05"], fire_cards, db.get_all_buffs(), 177, options)
    draft.begin_round(true, false)
    check(not draft.can_specialize("fire_cinder_circle"), "opening cannot buy a path")
    draft.begin_round(false, false)
    check(not draft.can_specialize("fire_cinder_circle"), "Round 2 cannot buy a path")
    draft.begin_round(false, false)
    check(not draft.choose_specialization("water_undertow"), "a different Commander's path cannot be selected")
    for card in fire_cards:
        draft.unit_counts[card["id"]] = int(card["unit_cap"])
    draft.refresh_offer()
    check(draft.current_offer.all(func(option): return option["type"] == "buff"), "fully recruited armies have the actual buff-only offer")
    var points := draft.selection_points
    check(draft.choose_specialization("fire_cinder_circle") and draft.selection_points == points - 1, "one normal pick buys one path")
    check(not draft.choose_specialization("fire_wildfire"), "a second path cannot be purchased")
    var next := DraftSystem.new()
    next.configure(draft.loadout_card_ids, fire_cards, db.get_all_buffs(), 177, options)
    check(next.restore(draft.snapshot()) and next.snapshot() == draft.snapshot(), "path and exact random state recover")
    draft.select_offer(0)
    next.select_offer(0)
    check(next.snapshot() == draft.snapshot(), "future offers remain deterministic after a path purchase")
    draft.begin_round(false, true, true)
    check(draft.specialization_id == "fire_cinder_circle" and not draft.can_specialize(), "Sudden Death retains rather than replenishes the path")
    var forged := next.snapshot()
    forged["specialization_id"] = "water_undertow"
    check(not next.restore(forged), "recovery rejects a foreign path")
    forged = next.snapshot()
    forged["specialization_enabled"] = false
    check(not next.restore(forged), "recovery rejects paths in the default rules")
    forged = next.snapshot()
    forged["unit_counts"] = "invalid"
    check(not next.restore(forged), "corrupt path checkpoint counts are rejected before reading ability coverage")
    var baseline := {"id": "player", "cards": [db.get_card("card_fire_01")], "unit_counts": {"card_fire_01": 1}}
    var enemy := {"id": "opponent", "cards": [db.get_card("card_water_01")], "unit_counts": {"card_water_01": 1}}
    var balance: Dictionary = db.get_game_balance().duplicate(true)
    balance["simulation"]["round_time_limit_seconds"] = 2.0
    var ordinary := CombatSimulator.new().simulate(baseline, enemy, 55, balance)
    var empty := baseline.duplicate(true)
    empty["specialization"] = {}
    check(ordinary == CombatSimulator.new().simulate(empty, enemy, 55, balance), "disabled paths do not change combat or the replay")
    var branch: Dictionary = catalog["branches"].filter(func(value): return value["id"] == "fire_cinder_circle")[0]
    var upgraded := baseline.duplicate(true)
    upgraded["specialization"] = branch
    var wider := CombatSimulator.new().simulate(upgraded, enemy, 55, balance)
    check(float(wider["frames"][0]["units"][0]["aura_radius"]) > float(ordinary["frames"][0]["units"][0]["aura_radius"]), "the actual simulated aura and its visible radius grow")
    check(str(wider["frames"][0]["units"][0].get("specialization_description", "")).contains("medium"), "inspection receives recorded path changes")
    var nursery: Dictionary = catalog["branches"].filter(func(value): return value["id"] == "slime_royal_nursery")[0]
    var giant := CommanderSpecializations.changed_ability(db.get_card("card_slime_01"), nursery)
    check(giant["child_health_pct"] == 75 and giant["child_attack_pct"] == 50 and giant["spawn_count"] == 2, "nursery changes child HP without changing attacks or generations")
    var surges: Dictionary = catalog["branches"].filter(func(value): return value["id"] == "slime_stored_surges")[0]
    var ball := CommanderSpecializations.changed_ability(db.get_card("card_slime_03"), surges)
    check(is_equal_approx(float(ball["burst_seconds"]), 8) and ball["absorb_pct"] == 30 and ball["death_multiplier"] == 2, "surges preserve requested absorption and doubled death burst")
    var described := UnitInspection.describe({"ability_type": "absorb_burst", "sample_time": 1.0, "last_ability": {"time": 2.0, "kind": "absorb_burst"}, "burst_seconds": 8.0, "next_burst_at": 10.0}, db.get_card("card_slime_03"), 3.0)
    check(described["cooldown"] == "Burst in 7.0s", "inspection counts down the recorded prototype interval")
    var ai := AiController.new()
    check(ai.configure([db.get_commander("commander_fire_01")], fire_cards, db.sets, db.get_all_buffs(), 173, {}, options), "AI configures the same catalog")
    for round_index in range(3):
        var public := ai.get_side()
        check(ai.begin_round(round_index == 0, false, false, {}, 0), "AI spends a legal round")
        if round_index == 2:
            check(public["specialization"].is_empty() and not ai.get_side()["specialization"].is_empty(), "old public snapshot does not reveal the AI's current path purchase")
    check(db.cards == originals, "simulation and previews never edit content definitions")
    check_recovery()
    print("Commander specialization tests passed." if not failed else "TEST FAILED: commander specializations")
    quit(1 if failed else 0)

func check_recovery() -> void:
    var source := root.get_node("GameState")
    source.match_preferences.specialization_experiment = true
    source.select_commander("commander_fire_01")
    source.equip_starter_army()
    check(source.begin_match(12345), "opted-in adventure starts")
    for round_index in range(2):
        while not source.draft.is_phase_complete():
            source.draft.auto_select()
        check(source.run_battle() and source.begin_next_round(), "prepared adventure reaches Round 3")
    check(source.draft.specialization_enabled == source.opponent.draft.specialization_enabled, "both sides use the active experiment")
    source.update_draft_clock(13.5)
    var before: Dictionary = source.local_store.candidates()[0]
    var restored := fixture(source, before)
    check(restored.resume_match(), "Round 3 resumes while the rival's current path is hidden")
    check(restored.opponent_public_side["specialization"] == source.opponent_public_side["specialization"], "recovery preserves the old public path instead of revealing the rival's purchase")
    restored.free()
    check(source.draft.choose_specialization("fire_cinder_circle"), "player buys an available path")
    check(source.draft_time_left == 30, "path purchase resets the next ordinary pick clock")
    source.update_draft_clock(16.5)
    var snapshot: Dictionary = source.local_store.candidates()[0]
    restored = fixture(source, snapshot)
    check(restored.resume_match() and restored.draft.snapshot() == source.draft.snapshot() and restored.draft_time_left == 16.5, "path, remaining picks, clock and RNG survive recovery")
    while not source.draft.is_phase_complete():
        source.draft.auto_select()
        restored.draft.auto_select()
    check(source.run_battle() and restored.run_battle(), "both reconstructed path battles run")
    check(source.battle_result == restored.battle_result, "the resumed specialized battle is identical")
    restored.free()
    source.leave_match()
    source.match_preferences.specialization_experiment = false
    source.begin_match(12346)
    var legacy: Dictionary = source.local_store.candidates()[0]
    for key in ["draft", "opponent_draft"]:
        legacy[key].erase("specialization_enabled")
        legacy[key].erase("specialization_id")
    legacy["public_side"].erase("specialization")
    restored = fixture(source, legacy)
    check(restored.resume_match() and not restored.draft.specialization_enabled and restored.draft.specialization_id.is_empty(), "v0.17-shaped default checkpoints preserve their original fingerprint and recover")
    restored.free()
    source.leave_match()

func fixture(source: Node, snapshot: Dictionary) -> Node:
    var value = load("res://scripts/core/game_state.gd").new()
    root.add_child(value)
    value.commander_progress._data = source.commander_progress._data.duplicate(true)
    value.commander_progress.last_receipt = source.commander_progress.last_receipt.duplicate(true)
    value.local_store.save(snapshot)
    return value

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
