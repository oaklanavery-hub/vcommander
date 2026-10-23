extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var cards: Array = db.get_all_cards().slice(0, 2).duplicate(true)
    cards[0]["stats"]["attack_speed"] = 150
    cards[1]["stats"]["attack_speed"] = 199
    var counts := {str(cards[0]["id"]): 2, str(cards[1]["id"]): 3}
    var buff: Dictionary = db.get_buff("buff_attack_speed")
    var side := {"id": "player", "cards": cards, "unit_counts": counts, "buffs": [{"definition": buff, "stacks": 1}], "set_bonus": {"stat": "health", "percentage": 10}}
    var original := side.duplicate(true)
    var preview := WarbandStats.power_preview(side, buff, db.get_game_balance()["stats"])
    check(preview["total"] == 5 and preview["improved"] == 2 and preview["capped"] == 3, "partial caps report exactly the bodies whose rating improves")
    check(preview["rows"][0]["before"] == 180 and preview["rows"][0]["after"] == 200, "rating preview applies rounding then the speed cap")
    check(side == original, "preview never modifies draft inputs")
    var simulator = load("res://scripts/combat/combat_simulator.gd").new()
    for definition in db.get_all_buffs():
        var next := side.duplicate(true)
        next["buffs"].append({"definition": definition, "stacks": 1})
        var result := WarbandStats.power_preview(side, definition, db.get_game_balance()["stats"])
        for index in range(cards.size()):
            var stat: String = definition["stat"]
            var expected: float = simulator._modified_stat(int(cards[index]["stats"][stat]), stat, next)
            if stat in ["attack_speed", "movement_speed"]:
                expected = clampf(expected, 1, 200)
            check(result["rows"][index]["after"] == expected, "all five previews match actual combat stat calculation including theme bonuses")
    side["buffs"][0]["stacks"] = 10000
    preview = WarbandStats.power_preview(side, buff, db.get_game_balance()["stats"])
    check(preview["improved"] == 0 and preview["capped"] == 5, "unlimited late power picks correctly show zero current speed gain")
    side["unit_counts"] = {}
    check(WarbandStats.power_preview(side, buff, db.get_game_balance()["stats"])["total"] == 0, "future recruits are separate from current-body benefit")
    var tile = load("res://scripts/presentation/buff_tile.gd").new()
    tile.definition = buff
    side["unit_counts"] = counts
    tile.side_config = side
    root.add_child(tile)
    check(tile.benefit_label.text == "All current units at limit" and not tile.disabled, "no-gain warning remains visible without banning an unlimited power pick")
    tile.queue_free()
    if not failed:
        print("Power preview tests passed: partial/full caps, rounding/theme parity, future recruits, immutable inputs and legal no-gain cards.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
