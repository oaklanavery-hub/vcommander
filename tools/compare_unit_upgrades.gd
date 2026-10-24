extends SceneTree
## Four paired synthetic adventures; a bounded diagnostic, not a balance verdict.

const MIXED_WATER := ["card_water_01", "card_water_02", "card_fire_05", "card_earth_03"]

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var rows: Array = []
    var ordinal := 0
    for commander in db.get_all_commanders():
        var seed_value := 181000 + ordinal * 7919
        ordinal += 1
        var cards: Array = db.get_cards_by_ids(MIXED_WATER) if commander["element"] == "water" else db.get_cards_by_set(commander["signature_set_id"]).filter(func(card): return not card.has("mastery_unlock"))
        var ids: Array = cards.map(func(card): return card["id"])
        for upgraded in [false, true]:
            var balance: Dictionary = db.get_game_balance()
            var options := {"match_rules": balance["match"]}
            if upgraded:
                options["unit_upgrades"] = UnitUpgrades.definitions(db.get_upgrade_rules(), db.get_upgrade_rules()["units"].keys())
            var player := AiController.new()
            var rival := AiController.new()
            player.configure([commander], db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value, balance["stats"], options)
            rival.configure(db.get_all_commanders(), db.get_all_cards(), db.sets, db.get_all_buffs(), seed_value + 3571, balance["stats"], options)
            player.cards.assign(cards)
            player.draft.configure(ids, cards, db.get_all_buffs(), seed_value + 7919, options)
            var match_state := MatchState.new()
            match_state.start()
            var row := {"commander": commander["id"], "seed": str(seed_value), "loadout": ids, "all_lv2": upgraded, "rival": rival.commander["id"], "outcome": "unfinished_at_bound", "rounds": 0, "combat_seconds": 0.0, "timeouts": 0, "sudden_draws": 0, "maximum_bodies": 0, "maximum_sim_ms": 0.0}
            for round_index in range(16):
                var public_player := player.get_side()
                public_player["id"] = "player"
                var public_rival := rival.get_side()
                player.begin_round(round_index == 0, bool(match_state.lost_previous["player"]), match_state.sudden_death, public_rival, int(match_state.losses["player"]))
                rival.begin_round(round_index == 0, bool(match_state.lost_previous["opponent"]), match_state.sudden_death, public_player, int(match_state.losses["opponent"]))
                var left := player.get_side(player.draft.commander_skill_used_this_round)
                left["id"] = "player"
                var start := Time.get_ticks_usec()
                var result := CombatSimulator.new().simulate(left, rival.get_side(rival.draft.commander_skill_used_this_round), seed_value + match_state.round_number * 104729, balance)
                row["maximum_sim_ms"] = maxf(row["maximum_sim_ms"], float(Time.get_ticks_usec() - start) / 1000)
                row["rounds"] += 1
                row["combat_seconds"] += float(result["duration"])
                row["timeouts"] += 1 if result["reason"] == "timer" else 0
                row["sudden_draws"] += 1 if match_state.sudden_death and result["winner"] == "draw" else 0
                for frame in result["frames"]:
                    row["maximum_bodies"] = maxi(row["maximum_bodies"], frame["units"].size())
                match_state.begin_battle()
                match_state.resolve_round(result["winner"], result["duration"])
                if match_state.is_complete():
                    row["outcome"] = "win" if match_state.winner == "player" else "loss"
                    break
                match_state.advance_round()
            rows.append(row)
            print("Upgrade sample: %s · Lv.%d · %d rounds · %.1fs combat · %d timeouts · %s" % [commander["display_name"], 2 if upgraded else 1, row["rounds"], row["combat_seconds"], row["timeouts"], row["outcome"]])
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/unit_upgrade_comparison.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"kind": "paired_synthetic_ai_vs_ai", "human_samples": 0, "round_bound": 16, "same_collection_both_sides": true, "specializations": false, "redraw": false, "fixtures": rows}, "  "))
    file.close()
    quit()
