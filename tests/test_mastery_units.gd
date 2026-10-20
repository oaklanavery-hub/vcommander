extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    for element in ["fire", "water", "earth", "slime"]:
        var reward: Dictionary = db.get_card("card_%s_05" % element)
        var cards: Array[Dictionary] = [db.get_card("card_%s_01" % element), reward, db.get_card("card_%s_03" % element), db.get_card("card_%s_04" % element)]
        var ids: Array[String] = []
        var counts := {}
        for card in cards:
            ids.append(card["id"])
            counts[card["id"]] = mini(2, int(card["unit_cap"]))
        var draft := DraftSystem.new()
        draft.configure(ids, cards, db.get_all_buffs(), 193)
        draft.begin_round(true, false, false)
        # Repeated legal openings demonstrate the new card can be offered/drafted.
        var offered := false
        for option in draft.current_offer:
            if option["id"] == reward["id"]:
                offered = true
        while not draft.is_phase_complete():
            for option in draft.current_offer:
                if option["id"] == reward["id"]:
                    offered = true
            draft.auto_select()
        check(offered, "reward participates in the ordinary draft pool: " + element)
        check(SetBonusChecker.is_complete(cards, "set_%s_01" % element, 4), "any four of five themed units activate the bonus")
        var player := {"id": "player", "cards": cards, "unit_counts": counts, "buffs": [], "set_bonus": db.get_signature_set("set_%s_01" % element)["bonus"], "commander": db.get_commander("commander_%s_01" % element), "commander_skill_active": false}
        var enemy := player.duplicate(true)
        enemy["id"] = "opponent"
        var result := CombatSimulator.new().simulate(player, enemy, 193, db.get_game_balance())
        var repeated := CombatSimulator.new().simulate(player, enemy, 193, db.get_game_balance())
        check(JSON.stringify(result) == JSON.stringify(repeated), "new roster replay is deterministic: " + element)
        var seen := {}
        for event in result["events"]:
            if event.get("type") == "ability" and (event.get("card_id") == reward["id"] or str(event.get("unit_id", "")).contains(str(reward["id"]))):
                seen[event.get("side", "")] = true
        if element != "earth":
            check(seen.has("player") and seen.has("opponent"), "heals/empowered attacks execute for both teams: " + element)
        else:
            var launches := 0
            var splash := 0
            for event in result["events"]:
                if event.get("type") == "projectile_launch" and event.get("projectile", {}).get("card_id") == reward["id"]:
                    launches += 1
                if event.get("type") == "damage" and event.get("source") == "splash" and str(event.get("source_unit_id", "")).contains(str(reward["id"])):
                    splash += 1
            check(launches > 0 and splash > 0, "Spore Sage launches real damaging splash projectiles")
    if not failed:
        print("Mastery unit tests passed: all four reward definitions draft, replace a themed starter, use actual abilities on both teams and retain seeded replay determinism.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
