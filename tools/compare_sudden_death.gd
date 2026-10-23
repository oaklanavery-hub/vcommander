extends "res://tools/run_strategy_playtest.gd"
## A bounded paired reproduction of the known Water hybrid pacing fixture.

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var rows: Array = []
    for legacy in [true, false]:
        var balance: Dictionary = db.get_game_balance().duplicate(true)
        balance["match"]["sudden_death_round_time_seconds"] = 120 if legacy else 180
        balance["match"]["sudden_death_power_multiplier"] = 1 if legacy else 2
        var options := {"match_rules": balance["match"]}
        var available: Array = db.get_all_cards().filter(func(card): return not card.has("mastery_unlock"))
        var seed_value := 204757
        var player := AiController.new()
        var rival := AiController.new()
        var commander: Dictionary = db.get_commander("commander_water_01")
        player.configure([commander], available, db.sets, db.get_all_buffs(), seed_value, balance["stats"], options)
        rival.configure(db.get_all_commanders(), available, db.sets, db.get_all_buffs(), seed_value + 3571, balance["stats"], options)
        player.cards.assign(db.get_cards_by_ids(FIXTURES["commander_water_01"]))
        var ids: Array = player.cards.map(func(card): return card["id"])
        player.draft.configure(ids, player.cards, db.get_all_buffs(), seed_value + 7919, options)
        var match_state := MatchState.new()
        match_state.start()
        var row := {"rule": "legacy_120_normal_powers" if legacy else "approved_180_new_powers_x2", "seed": str(seed_value), "loadout": ids, "opponent": rival.commander["id"], "outcome": "unfinished_at_bound", "rounds": 0, "combat_seconds": 0.0, "timeouts": 0, "sudden_draws": 0, "round_details": []}
        for index in range(16):
            var player_public := player.get_side()
            player_public["id"] = "player"
            var rival_public := rival.get_side()
            player.begin_round(index == 0, bool(match_state.lost_previous["player"]), match_state.sudden_death, rival_public, int(match_state.losses["player"]))
            rival.begin_round(index == 0, bool(match_state.lost_previous["opponent"]), match_state.sudden_death, player_public, int(match_state.losses["opponent"]))
            var left := player.get_side(player.draft.commander_skill_used_this_round)
            left["id"] = "player"
            var result := CombatSimulator.new().simulate(left, rival.get_side(rival.draft.commander_skill_used_this_round), seed_value + match_state.round_number * 104729, balance)
            row["rounds"] += 1
            row["combat_seconds"] += float(result["duration"])
            row["timeouts"] += 1 if result["reason"] == "timer" else 0
            row["sudden_draws"] += 1 if match_state.sudden_death and result["winner"] == "draw" else 0
            row["round_details"].append({"round": match_state.round_number, "sudden": match_state.sudden_death, "duration": result["duration"], "limit": result["round_time_limit"], "winner": result["winner"], "reason": result["reason"]})
            match_state.begin_battle()
            match_state.resolve_round(result["winner"], result["duration"])
            if match_state.is_complete():
                row["outcome"] = "win" if match_state.winner == "player" else "loss"
                break
            match_state.advance_round()
        rows.append(row)
        print("Sudden Death comparison: %s · %d rounds · %.1fs combat · %d timeouts · %d Sudden Death draws · %s" % [row["rule"], row["rounds"], row["combat_seconds"], row["timeouts"], row["sudden_draws"], row["outcome"]])
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/sudden_death_comparison.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"kind": "paired_synthetic_ai_vs_ai", "human_samples": 0, "round_bound": 16, "specializations": false, "redraw": false, "fixtures": rows}, "  "))
    file.close()
    quit()
