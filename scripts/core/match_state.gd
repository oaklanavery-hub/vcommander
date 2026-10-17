class_name MatchState
extends RefCounted

var round_number := 1
var losses := {"player": 0, "opponent": 0}
var lost_previous := {"player": false, "opponent": false}
var sudden_death := false
var phase := "draft"
var winner := ""
var history: Array[Dictionary] = []
var _loss_limit := 4

func start(loss_limit: int = 4) -> void:
    _loss_limit = maxi(1, loss_limit)
    round_number = 1
    losses = {"player": 0, "opponent": 0}
    lost_previous = {"player": false, "opponent": false}
    sudden_death = false
    phase = "draft"
    winner = ""
    history.clear()

func begin_battle() -> bool:
    if phase != "draft":
        return false
    phase = "battle"
    return true

func resolve_round(round_winner: String, duration: float = 0.0) -> bool:
    if phase != "battle" or round_winner not in ["player", "opponent", "draw"]:
        return false
    for side in ["player", "opponent"]:
        lost_previous[side] = round_winner == "draw" or round_winner != side
        if lost_previous[side]:
            losses[side] += 1
    history.append({"round": round_number, "winner": round_winner, "duration": duration, "sudden_death": sudden_death})
    phase = "result"
    if sudden_death:
        if round_winner != "draw":
            winner = round_winner
            phase = "complete"
    elif int(losses["player"]) >= _loss_limit and int(losses["opponent"]) >= _loss_limit:
        sudden_death = true
    elif int(losses["player"]) >= _loss_limit:
        winner = "opponent"
        phase = "complete"
    elif int(losses["opponent"]) >= _loss_limit:
        winner = "player"
        phase = "complete"
    return true

func advance_round() -> bool:
    if phase != "result":
        return false
    round_number += 1
    phase = "draft"
    return true

func selections_for(side: String) -> int:
    if round_number == 1 or sudden_death:
        return 3
    return 4 if bool(lost_previous.get(side, false)) else 3

func is_complete() -> bool:
    return phase == "complete"
