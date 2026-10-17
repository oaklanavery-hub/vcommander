extends SceneTree

const Ai = preload("res://scripts/ai/ai_controller.gd")
const Simulator = preload("res://scripts/combat/combat_simulator.gd")
const Match = preload("res://scripts/core/match_state.gd")
var _timings: Array[float] = []
var _maximum_units := 0

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db = root.get_node("ContentDatabase")
    var groups: Array[Dictionary] = []
    var seed_count := 8
    var seed_start := 1000
    var output_path := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--seeds="):
            seed_count = clampi(int(argument.trim_prefix("--seeds=")), 1, 100)
        elif argument.begins_with("--seed-start="):
            seed_start = int(argument.trim_prefix("--seed-start="))
        elif argument.begins_with("--output="):
            output_path = argument.trim_prefix("--output=")
    for player_commander in db.get_all_commanders():
        for opponent_commander in db.get_all_commanders():
            var group := {"player": player_commander["element"], "opponent": opponent_commander["element"], "player_wins": 0, "opponent_wins": 0, "unresolved_sudden_death": 0, "battles": 0, "round_draws": 0, "round_seconds": 0.0}
            for seed_index in range(seed_count):
                var player = Ai.new()
                var opponent = Ai.new()
                var seed_value := seed_start + seed_index
                player.configure([player_commander], db.get_cards_by_set(str(player_commander["signature_set_id"])), db.sets, db.get_all_buffs(), seed_value)
                opponent.configure([opponent_commander], db.get_cards_by_set(str(opponent_commander["signature_set_id"])), db.sets, db.get_all_buffs(), seed_value + 1777)
                var match_info = Match.new()
                match_info.start()
                for round_index in range(20):
                    var public_player: Dictionary = player.get_side()
                    var public_opponent: Dictionary = opponent.get_side()
                    player.begin_round(round_index == 0, bool(match_info.lost_previous["player"]), match_info.sudden_death, public_opponent, int(match_info.losses["player"]))
                    opponent.begin_round(round_index == 0, bool(match_info.lost_previous["opponent"]), match_info.sudden_death, public_player, int(match_info.losses["opponent"]))
                    var player_side: Dictionary = player.get_side(player.draft.commander_skill_used_this_round)
                    player_side["id"] = "player"
                    var opponent_side: Dictionary = opponent.get_side(opponent.draft.commander_skill_used_this_round)
                    var simulator = Simulator.new()
                    var started := Time.get_ticks_usec()
                    var result: Dictionary = simulator.simulate(player_side, opponent_side, seed_value + match_info.round_number * 104729, db.get_game_balance())
                    _timings.append(float(Time.get_ticks_usec() - started) / 1000.0)
                    if not result.get("frames", []).is_empty():
                        _maximum_units = maxi(_maximum_units, result["frames"][0]["units"].size())
                    match_info.begin_battle()
                    match_info.resolve_round(str(result["winner"]), float(result["duration"]))
                    group["battles"] += 1
                    group["round_seconds"] += float(result["duration"])
                    if result["winner"] == "draw":
                        group["round_draws"] += 1
                    if match_info.is_complete():
                        group["player_wins" if match_info.winner == "player" else "opponent_wins"] += 1
                        break
                    match_info.advance_round()
                if not match_info.is_complete():
                    group["unresolved_sudden_death"] += 1
            group["mean_round_seconds"] = snappedf(float(group["round_seconds"]) / maxf(1, int(group["battles"])), 0.01)
            group.erase("round_seconds")
            groups.append(group)
            print("Balance sample ", group["player"], " vs ", group["opponent"], ": ", group["player_wins"], "-", group["opponent_wins"], " unresolved=", group["unresolved_sudden_death"])
    _timings.sort()
    var report := {
        "seed_start": seed_start, "seeds_per_pair": seed_count, "matches": seed_count * groups.size(),
        "round_limit": 20, "groups": groups,
        "performance": {"battles": _timings.size(), "median_ms": snappedf(_timings[_timings.size() / 2], 0.01), "p95_ms": snappedf(_timings[mini(_timings.size() - 1, int(ceil(_timings.size() * 0.95)) - 1)], 0.01), "maximum_units": _maximum_units}
    }
    if not output_path.is_empty():
        var file := FileAccess.open(output_path, FileAccess.WRITE)
        if file == null:
            push_error("Cannot save balance report: " + output_path)
            quit(1)
            return
        file.store_string(JSON.stringify(report, "  ") + "\n")
    print("Balance sample complete: ", report["matches"], " matches, ", _timings.size(), " battles.")
    quit(0)
