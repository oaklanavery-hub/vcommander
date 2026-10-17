extends Node

const ArmyLoadoutScript = preload("res://scripts/army/army_loadout.gd")
const SetBonusCheckerScript = preload("res://scripts/commanders/set_bonus_checker.gd")
const DraftSystemScript = preload("res://scripts/draft/draft_system.gd")
const MatchScript = preload("res://scripts/core/match_state.gd")
const AiScript = preload("res://scripts/ai/ai_controller.gd")
const CombatSimulatorScript = preload("res://scripts/combat/combat_simulator.gd")

var selected_commander_id := ""
var army = ArmyLoadoutScript.new(4)
var draft = DraftSystemScript.new()
var match_seed := 0
var match_started := false
var match_state = MatchScript.new()

var battle_result: Dictionary = {}
var opponent = AiScript.new()
var opponent_public_side: Dictionary = {}
var opponent_combat_side: Dictionary = {}

func select_commander(commander_id: String) -> bool:
    if ContentDatabase.get_commander(commander_id).is_empty():
        return false
    if selected_commander_id != commander_id:
        army.clear()
        _reset_match_runtime()
    selected_commander_id = commander_id
    return true

func get_selected_commander() -> Dictionary:
    return ContentDatabase.get_commander(selected_commander_id)

func get_selected_signature_set() -> Dictionary:
    var commander := get_selected_commander()
    if commander.is_empty():
        return {}
    return ContentDatabase.get_signature_set(str(commander.get("signature_set_id", "")))

func equip_card(card_id: String) -> bool:
    if ContentDatabase.get_card(card_id).is_empty():
        return false
    _reset_match_runtime()
    return army.equip(card_id)

func unequip_card_at(index: int) -> bool:
    _reset_match_runtime()
    return army.unequip_at(index)

func clear_army() -> void:
    _reset_match_runtime()
    army.clear()

func get_signature_progress() -> int:
    var signature_set := get_selected_signature_set()
    if signature_set.is_empty():
        return 0
    return SetBonusCheckerScript.progress(
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        str(signature_set.get("id", ""))
    )

func get_signature_required_count() -> int:
    var signature_set := get_selected_signature_set()
    return int(signature_set.get("required_count", 4)) if not signature_set.is_empty() else 4

func is_full_set_active() -> bool:
    var signature_set := get_selected_signature_set()
    if signature_set.is_empty():
        return false
    return SetBonusCheckerScript.is_complete(
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        str(signature_set.get("id", "")),
        int(signature_set.get("required_count", 4))
    )

func begin_match(seed_value: int) -> bool:
    if selected_commander_id.is_empty() or not army.is_full():
        return false
    _reset_match_runtime()
    match_seed = seed_value
    match_state.start(int(ContentDatabase.get_game_balance().get("match", {}).get("losses_to_lose_match", 4)))
    draft.configure(
        army.get_cards(),
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        ContentDatabase.get_all_buffs(),
        match_seed
    )
    draft.begin_round(true, false, false)
    match_started = true
    battle_result.clear()
    opponent = AiScript.new()
    if not opponent.configure(ContentDatabase.get_all_commanders(), ContentDatabase.get_all_cards(), ContentDatabase.sets, ContentDatabase.get_all_buffs(), match_seed + 3571):
        match_started = false
        return false
    opponent_public_side = opponent.get_side()
    return opponent.begin_round(true, false, false, get_player_combat_side())

func run_battle() -> bool:
    if not match_started or not draft.is_phase_complete():
        return false
    if not battle_result.is_empty():
        return true

    if not match_state.begin_battle():
        return false
    var player_side := _build_combat_side(
        "player",
        draft,
        draft.commander_skill_used_this_round
    )
    opponent_combat_side = opponent.get_side(opponent.draft.commander_skill_used_this_round)

    var simulator = CombatSimulatorScript.new()
    battle_result = simulator.simulate(
        player_side,
        opponent_combat_side,
        match_seed + match_state.round_number * 104729,
        ContentDatabase.get_game_balance()
    )
    return match_state.resolve_round(str(battle_result.get("winner", "draw")), float(battle_result.get("duration", 0.0)))

func begin_next_round() -> bool:
    if not match_started or not match_state.advance_round():
        return false
    var public_player := get_player_combat_side().duplicate(true)
    opponent_public_side = opponent.get_side()
    battle_result.clear()
    opponent_combat_side.clear()
    draft.begin_round(false, bool(match_state.lost_previous["player"]), match_state.sudden_death)
    return opponent.begin_round(false, bool(match_state.lost_previous["opponent"]), match_state.sudden_death, public_player, int(match_state.losses["opponent"]))

func leave_match() -> void:
    _reset_match_runtime()

func get_player_combat_side() -> Dictionary:
    if not match_started:
        return {}
    return _build_combat_side(
        "player",
        draft,
        draft.commander_skill_used_this_round
    )

func _build_combat_side(side_id: String, draft_state, skill_active: bool) -> Dictionary:
    var counts: Dictionary = {}
    for card_id in army.get_cards():
        counts[card_id] = draft_state.get_unit_count(card_id)

    var buff_states: Array[Dictionary] = []
    for buff in ContentDatabase.get_all_buffs():
        var buff_id := str(buff.get("id", ""))
        var stacks: int = int(draft_state.get_buff_stacks(buff_id))
        if stacks <= 0:
            continue
        buff_states.append({
            "definition": buff.duplicate(true),
            "stacks": stacks
        })

    var set_bonus: Dictionary = {}
    if is_full_set_active():
        var signature_set := get_selected_signature_set()
        set_bonus = signature_set.get("bonus", {}).duplicate(true)

    return {
        "id": side_id,
        "commander": get_selected_commander().duplicate(true),
        "commander_skill_active": skill_active,
        "cards": ContentDatabase.get_cards_by_ids(army.get_cards()),
        "unit_counts": counts,
        "buffs": buff_states,
        "set_bonus": set_bonus,
        "skill_uses_remaining": draft_state.commander_skill_uses_remaining()
    }

func _reset_match_runtime() -> void:
    match_started = false
    match_state.start()
    battle_result.clear()
    opponent_public_side.clear()
    opponent_combat_side.clear()
