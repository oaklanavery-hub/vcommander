extends SceneTree

const Ai = preload("res://scripts/ai/ai_controller.gd")
const Database = preload("res://scripts/core/content_database.gd")
var failed := false

func _init() -> void:
    var db = Database.new()
    db.reload()
    for seed_value in range(50):
        var ai = Ai.new()
        var copy = Ai.new()
        check(ai.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value), "AI setup must succeed")
        copy.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value)
        check(ai.get_side() == copy.get_side(), "seed must reproduce setup")
        check(ai.cards.size() == 4, "exactly four cards")
        var ids := {}
        for card in ai.cards:
            ids[card["id"]] = true
        check(ids.size() == 4, "unique loadout")
        var public_before: Dictionary = ai.get_side()
        var enemy := {"unit_counts": {"public_unit": 6}}
        for round_index in range(14):
            check(ai.begin_round(round_index == 0, round_index % 2 == 0, round_index > 10, enemy, mini(round_index, 3)), "AI spends all legal selections")
            copy.begin_round(round_index == 0, round_index % 2 == 0, round_index > 10, enemy, mini(round_index, 3))
            check(ai.get_side() == copy.get_side(), "seed reproduces all decisions")
            for card in ai.cards:
                var count: int = ai.draft.get_unit_count(str(card["id"]))
                check(count <= int(card["unit_cap"]), "unit caps respected")
            for buff in db.get_all_buffs():
                check(ai.draft.get_buff_stacks(str(buff["id"])) <= 3, "buff caps respected")
            check(ai.draft.commander_skill_uses <= 2, "skill use cap respected")
            if round_index == 0:
                check(ai.draft.buff_stacks.values().all(func(value): return value == 0), "opening army only")
                check(ai.draft.commander_skill_uses == 0, "AI preserves opening summons")
        check(public_before["unit_counts"].values().all(func(count): return count == 0), "snapshot does not reveal future picks")
        check(public_before["skill_uses_remaining"] == 2, "snapshot does not reveal skill spending")
    var support_ai = Ai.new()
    support_ai.configure([db.get_commander("commander_water_01")], db.get_cards_by_set("set_water_01"), db.sets, db.get_all_buffs(), 77)
    support_ai.draft.unit_counts["card_water_01"] = 4
    support_ai.draft.unit_counts["card_water_02"] = 4
    var first_healer: float = support_ai.score_option({"type": "unit", "id": "card_water_03"})
    check(first_healer > support_ai.score_option({"type": "unit", "id": "card_water_01"}), "AI values the first healer for an established army")
    support_ai.draft.unit_counts["card_water_03"] = 1
    check(support_ai.score_option({"type": "unit", "id": "card_water_03"}) < first_healer, "support coverage has diminishing draft value")
    db.free()
    if not failed:
        print("AiController tests passed: 50 seeds, 700 drafting phases.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
