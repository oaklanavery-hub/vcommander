class_name PrivateBattleContext
extends RefCounted

# Read-only adapter for the existing battle presentation. It never invokes
# GameState, CombatSimulator or CommanderProgress settlement.
var battle_result: Dictionary = {}
var match_state := MatchState.new()
var match_seed := 0
var opponent_combat_side: Dictionary = {}
var commander_progress: CommanderProgress
var mastery_reward: Dictionary = {}
var _player: Dictionary = {}

func _init(state: Dictionary, battle: Dictionary, content: Object) -> void:
    battle_result = PrivatePerspective.battle_for_player(battle, str(state.get("you", "player")))
    commander_progress = CommanderProgress.new(content, "")
    match_seed = int(battle_result.get("seed", 0))
    update(state)

func update(state: Dictionary) -> void:
    var view := PrivatePerspective.state_for_player(state)
    _player = view.get("self", {}).duplicate(true)
    opponent_combat_side = view.get("rival", {}).duplicate(true)
    match_state.round_number = int(view.get("round", 1))
    match_state.losses = view.get("losses", {"player": 0, "opponent": 0}).duplicate()
    match_state.sudden_death = bool(view.get("sudden_death", false))
    match_state.winner = str(view.get("winner", ""))
    match_state.phase = "complete" if view.get("phase") == "complete" else "result"
    match_state.history.clear()
    for item in view.get("history", []):
        match_state.history.append(item.duplicate(true))

func get_player_combat_side() -> Dictionary:
    return _player.duplicate(true)
