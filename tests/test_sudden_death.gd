extends SceneTree

var failed := false
var db: Node

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    var cards: Array = db.get_cards_by_set("set_fire_01").slice(0, 4)
    var ids: Array = cards.map(func(card): return card["id"])
    var draft := DraftSystem.new()
    var options := {"match_rules": db.get_game_balance()["match"]}
    draft.configure(ids, cards, db.get_all_buffs(), 7919, options)
    draft.begin_round(false, false)
    for buff in db.get_all_buffs():
        draft._apply_buff(str(buff["id"]))
    var earlier := draft.get_buff_states()
    draft.begin_round(false, true, true)
    check(draft.selection_points == 3 and draft.round_time_limit == 180, "each Sudden Death draft gets three picks and a 180-second battle")
    check(draft.get_buff_states() == earlier, "entering Sudden Death never upgrades earlier picks")
    for buff in db.get_all_buffs():
        var id: String = buff["id"]
        var stat: String = buff["stat"]
        var side := {"cards": [{"id": "future", "display_name": "Future recruit", "stats": {stat: 100}}], "unit_counts": {"future": 2}, "buffs": draft.get_buff_states()}.merged(draft.round_context())
        var preview := WarbandStats.power_preview(side, buff, db.get_game_balance()["stats"])
        var expected: float = round(100.0 * (1.0 + float(buff["percentage"]) / 100.0) * (1.0 + 2.0 * float(buff["percentage"]) / 100.0))
        check(preview["rows"][0]["after"] == minf(200, expected), "all five enhanced previews use double percentage, not two ordinary stacks")
        draft._apply_buff(id)
        check(draft.get_buff_stacks(id) == 2 and draft.sudden_death_buff_stacks[id] == 1, "total counts retain an enhanced subset")
        check(WarbandStats.modified(100, stat, {"buffs": draft.get_buff_states()}) == expected, "combat and future recruit stats preserve mixed pick strengths")
        check(int(WarbandStats.power_percentage(side, buff)) == 2 * int(buff["percentage"]), "all five new power values are doubled")
    var saved := draft.snapshot()
    var copy := DraftSystem.new()
    copy.configure(ids, cards, db.get_all_buffs(), 0, options)
    check(copy.restore(saved) and copy.snapshot() == saved, "mixed cohorts, offer, time limit and RNG restore exactly")
    draft.auto_select()
    copy.auto_select()
    check(copy.snapshot() == draft.snapshot(), "recovery preserves the next actual pick")
    var before := draft.get_buff_states()
    draft.begin_round(false, true, true)
    check(draft.round_time_limit == 180 and draft.get_buff_states() == before, "a repeated Sudden Death round neither shortens its ceiling nor redoubles old picks")
    var invalid := saved.duplicate(true)
    invalid["sudden_death_buff_stacks"]["buff_attack"] = 99
    var previous := copy.snapshot()
    check(not copy.restore(invalid) and copy.snapshot() == previous, "invalid enhanced subsets cannot partly mutate a draft")
    invalid = saved.duplicate(true)
    invalid["sudden_death_buff_stacks"]["buff_attack"] = 0.5
    check(not copy.restore(invalid), "fractional enhanced counts are rejected")
    invalid = saved.duplicate(true)
    invalid["round_time_limit"] = 181
    check(not copy.restore(invalid), "a saved battle cannot exceed the ceiling")
    var old := saved.duplicate(true)
    old.erase("sudden_death_buff_stacks")
    old.erase("round_time_limit")
    check(copy.restore(old) and copy.sudden_death_buff_stacks.values().all(func(n): return n == 0), "old saves treat every earlier pick as ordinary")
    for entry in before:
        entry["stacks"] = 10000
        entry["sudden_death_stacks"] = 5000
    for stat in ["attack_speed", "movement_speed"]:
        check(WarbandStats.effective(100, stat, {"buffs": before}, db.get_game_balance()["stats"]) == 200, "mixed unlimited power counts stay finite and retain speed limits")
    var ai := AiController.new()
    ai.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), 77)
    ai.draft.unit_counts[ai.cards[0]["id"]] = 2
    var ordinary := ai.score_option({"type": "buff", "id": "buff_attack"})
    ai.draft.begin_round(false, false, true)
    check(is_equal_approx(ai.score_option({"type": "buff", "id": "buff_attack"}), ordinary * 2), "AI values doubled growth under the same rule")
    for stat in ["attack_speed", "movement_speed"]:
        var buff_id: String = "buff_" + stat
        ai.draft.buff_stacks[buff_id] = 10000
        ai.draft.sudden_death_buff_stacks[buff_id] = 9999
        check(ai.score_option({"type": "buff", "id": buff_id}) == 0, "AI does not overvalue already-capped enhanced speed")
    check_clocks()
    if not failed:
        print("Sudden Death tests passed: mixed strengths, all five previews/combat/future recruits, repeat rounds, snapshots/RNG, invalid data, unlimited caps, equal AI and 120/180-second clocks.")
    quit(1 if failed else 0)

func check_clocks() -> void:
    var card := {"id": "enduring", "display_name": "Enduring", "role": "tank", "stats": {"health": 100000000, "attack": 1, "defense": 1, "attack_speed": 100, "movement_speed": 100, "range": 1.0}, "ability": {"type": "basic_melee"}}
    var left := {"id": "player", "cards": [card], "unit_counts": {"enduring": 1}, "buffs": []}
    var right := left.duplicate(true)
    right["id"] = "opponent"
    var normal := CombatSimulator.new().simulate(left, right, 31337, db.get_game_balance())
    check(normal["duration"] == 120 and normal["round_time_limit"] == 120 and normal["winner"] == "draw", "normal battles retain the actual 120-second ceiling")
    left["sudden_death"] = true
    right["sudden_death"] = true
    left["commander"] = db.get_commander("commander_water_01")
    left["commander_skill_active"] = true
    var sudden := CombatSimulator.new().simulate(left, right, 31337, db.get_game_balance())
    check(sudden["duration"] == 180 and sudden["round_time_limit"] == 180 and sudden["winner"] == "draw", "each Sudden Death battle runs to its own actual 180-second ceiling")
    check(not sudden["pre_battle"].is_empty() and sudden["frames"][0]["time"] == 0, "commander prelude remains outside battle time")
    var final_units: Array = sudden["frames"].back()["units"]
    var rival: Dictionary = final_units.filter(func(unit): return unit["side"] == "opponent")[0]
    check(int(rival["attack_speed"]) < 100, "Frozen Field's round-long slow remains active after 120 seconds")
    var match_state := MatchState.new()
    match_state.start()
    match_state.sudden_death = true
    match_state.begin_battle()
    match_state.resolve_round("draw", 180)
    check(match_state.advance_round() and match_state.sudden_death and match_state.selections_for("player") == 3, "a 180-second draw continues existing Sudden Death rules")
    left["round_time_limit"] = 120.0
    right["round_time_limit"] = 120.0
    var legacy := CombatSimulator.new().simulate(left, right, 31337, db.get_game_balance())
    check(legacy["duration"] == 120, "an explicit old replay keeps its original limit")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
