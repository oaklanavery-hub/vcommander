extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var seen := {}
    for seed_value in range(12):
        for difficulty in ["casual", "standard", "veteran"]:
            var ai := AiController.new()
            var copy := AiController.new()
            ai.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value, {}, {"difficulty": difficulty})
            copy.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value, {}, {"difficulty": difficulty})
            seen[ai.style] = true
            for card in ai.cards:
                check(card == db.get_card(str(card["id"])), "difficulty/style never changes unit stats or grants stronger content")
            var public := {"cards": [db.get_card("card_water_03")], "unit_counts": {"card_water_03": 3}, "buffs": [], "set_bonus": {}}
            var with_hidden := public.duplicate(true)
            with_hidden["current_picks"] = ["secret"]
            with_hidden["future_result"] = {"winner": "opponent"}
            ai.begin_round(true, false, false, public)
            copy.begin_round(true, false, false, with_hidden)
            check(ai.get_side() == copy.get_side() and ai.draft.snapshot() == copy.draft.snapshot(), "only public evidence can affect deterministic opponent picks")
    check(seen.size() == 4, "seeded opponents cover all four distinct plans")
    var ai := AiController.new()
    ai.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), 77, {}, {"difficulty": "veteran"})
    ai._public_enemy = {"cards": [db.get_card("card_water_03")], "unit_counts": {"card_water_03": 3}}
    var flank := ai._counter_weight(db.get_card("card_fire_06"))
    ai._public_enemy = {"cards": [db.get_card("card_earth_03")], "unit_counts": {"card_earth_03": 3}}
    check(flank > ai._counter_weight(db.get_card("card_fire_06")), "backline transit gains draft value against visible healers rather than melee")
    ai._public_enemy = {"cards": [db.get_card("card_fire_02")], "unit_counts": {"card_fire_02": 9}}
    var area := ai._counter_weight(db.get_card("card_fire_03"))
    ai._public_enemy["unit_counts"]["card_fire_02"] = 1
    check(area > ai._counter_weight(db.get_card("card_fire_03")), "area pressure gains value against a public swarm")
    ai.difficulty = "casual"
    check(ai._counter_weight(db.get_card("card_fire_03")) == 1.0, "casual difficulty reduces decision pressure rather than altering stats")
    if not failed:
        print("AI adaptation tests passed: seeded styles, all three decision-based difficulties, unchanged stats, public evidence boundary and counter priorities.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
