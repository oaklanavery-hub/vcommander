extends SceneTree
## Eight bounded AI-vs-AI adventures. No player files, no balance verdict.

const FIXTURES := {
    "commander_fire_01": ["card_fire_01", "card_fire_03", "card_water_03", "card_water_05"],
    "commander_water_01": ["card_water_01", "card_water_02", "card_fire_05", "card_earth_03"],
    "commander_earth_01": ["card_earth_01", "card_earth_04", "card_slime_02", "card_fire_02"],
    "commander_slime_01": ["card_slime_01", "card_slime_03", "card_fire_05", "card_earth_05"]
}

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var available: Array = db.get_all_cards().filter(func(card): return not card.has("mastery_unlock"))
    var rows: Array = []
    var ordinal := 0
    for commander in db.get_all_commanders():
        var seed_value := 181000 + ordinal * 7919
        ordinal += 1
        for composition in ["themed", "mixed"]:
            var player := AiController.new()
            var rival := AiController.new()
            player.configure([commander], available, db.sets, db.get_all_buffs(), seed_value)
            rival.configure(db.get_all_commanders(), available, db.sets, db.get_all_buffs(), seed_value + 3571)
            var chosen: Array = db.get_cards_by_ids(FIXTURES[commander["id"]]) if composition == "mixed" else available.filter(func(card): return card.get("set_id") == commander["signature_set_id"])
            var ids: Array = chosen.map(func(card): return card["id"])
            player.cards.assign(chosen)
            player.draft.configure(ids, chosen, db.get_all_buffs(), seed_value + 7919)
            var match_state := MatchState.new()
            match_state.start()
            var row := {"commander": commander["id"], "composition": composition, "seed": str(seed_value), "loadout": ids, "opponent": rival.commander["id"], "outcome": "unfinished_at_bound", "rounds": 0, "combat_seconds": 0.0, "timeouts": 0, "sudden_draws": 0, "army_capped_rounds": 0, "round_details": []}
            for index in range(16):
                var player_public := player.get_side()
                player_public["id"] = "player"
                var rival_public := rival.get_side()
                player.begin_round(index == 0, bool(match_state.lost_previous["player"]), match_state.sudden_death, rival_public, int(match_state.losses["player"]))
                rival.begin_round(index == 0, bool(match_state.lost_previous["opponent"]), match_state.sudden_death, player_public, int(match_state.losses["opponent"]))
                var left := player.get_side(player.draft.commander_skill_used_this_round)
                left["id"] = "player"
                var result := CombatSimulator.new().simulate(left, rival.get_side(rival.draft.commander_skill_used_this_round), seed_value + match_state.round_number * 104729, db.get_game_balance())
                row["rounds"] += 1
                row["combat_seconds"] += float(result["duration"])
                row["timeouts"] += 1 if result["reason"] == "timer" else 0
                row["sudden_draws"] += 1 if match_state.sudden_death and result["winner"] == "draw" else 0
                var capped := player.draft._eligible_unit_ids().is_empty()
                row["army_capped_rounds"] += 1 if capped else 0
                row["round_details"].append({"round": match_state.round_number, "duration": result["duration"], "winner": result["winner"], "reason": result["reason"], "army_capped": capped})
                match_state.begin_battle()
                match_state.resolve_round(result["winner"], result["duration"])
                if match_state.is_complete():
                    row["outcome"] = "win" if match_state.winner == "player" else "loss"
                    break
                match_state.advance_round()
            rows.append(row)
            print("Strategy sample: %s · %s · %d rounds · %.1fs combat · %d timeouts · %s" % [commander["display_name"], composition, row["rounds"], row["combat_seconds"], row["timeouts"], row["outcome"]])
    var output := "res://build/qa/strategy_sample.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open(output, FileAccess.WRITE)
    file.store_string(JSON.stringify({"kind": "synthetic_ai_vs_ai", "human_samples": 0, "specializations": false, "redraw": false, "round_bound": 16, "fixtures": rows}, "  "))
    file.close()
    print("Synthetic strategy sample saved. No player records were read or written.")
    quit()
