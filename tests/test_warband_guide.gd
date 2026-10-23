extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var data := WarbandGuide.catalog()
    for card in db.get_all_cards():
        check(data["abilities"].has(card["ability"]["type"]), "glossary covers " + card["display_name"])
    var fire: Dictionary = db.get_signature_set("set_fire_01")
    var cards: Array = db.get_cards_by_ids(["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_05"])
    var original := cards.duplicate(true)
    var themed := WarbandGuide.analyze(cards, fire)
    check(themed["theme_active"] and themed["theme"].contains("10"), "full theme explains its real bonus")
    check(themed["notes"].any(func(note): return note["id"] == "heal"), "equipped healing/frontline relationship is described")
    cards[3] = db.get_card("card_water_03")
    var mixed := WarbandGuide.analyze(cards, fire)
    check(not mixed["theme_active"] and mixed["theme_matches"] == 3 and mixed["theme"].contains("Mixed armies are legal"), "hybrid tradeoff is explicit without inventing a smaller bonus")
    var flanker := WarbandGuide.analyze(db.get_cards_by_ids(["card_fire_06"]), fire)
    check(not flanker["tags"].has("frontline"), "a backline traveller is not described as a conventional opening screen")
    var link := WarbandGuide.analyze(db.get_cards_by_ids(["card_slime_06"]), db.get_signature_set("set_slime_01"))
    check(link["notes"].any(func(note): return note["id"] == "links"), "damage links explain allied sharing and single-target limit")
    var lone := WarbandGuide.analyze(db.get_cards_by_ids(["card_water_02"]), fire)
    check(not lone["notes"].any(func(note): return note["id"] == "heal"), "missing mechanics do not create fictional relationships")
    check(original == db.get_cards_by_ids(["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_05"]), "guidance never mutates content")
    check(WarbandGuide.glossary("stored").size() == 1, "glossary can find a mechanic")
    print("Warband guide tests passed." if not failed else "TEST FAILED: warband guide")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
