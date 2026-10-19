class_name PrivateMatch
extends RefCounted

# Server-only orchestration. No local profile or scene-tree dependencies.
const SIDES := ["player", "opponent"]
const PICK_SECONDS := 30.0

var match_state := MatchState.new()
var phase := "waiting"
var drafts: Dictionary = {}
var setups: Dictionary = {}
var public_sides: Dictionary = {}
var revisions := {"player": 0, "opponent": 0}
var deadlines := {"player": 0.0, "opponent": 0.0}
var acknowledged := {"player": false, "opponent": false}
var result: Dictionary = {}
var losses_before := {"player": 0, "opponent": 0}

var _content: Object
var _rng := RandomNumberGenerator.new()

func _init(content: Object, match_seed: int) -> void:
    _content = content
    _rng.seed = match_seed
    match_state.start(int(content.get_game_balance().get("match", {}).get("losses_to_lose_match", 4)))

func add_side(side: String, commander_id: String, card_ids: Array, now: float) -> bool:
    if phase != "waiting" or side not in SIDES or setups.has(side):
        return false
    var commander: Dictionary = _content.get_commander(commander_id)
    if commander.is_empty() or card_ids.size() != 4:
        return false
    var loadout := ArmyLoadout.new(4)
    for card_id in card_ids:
        if not card_id is String or _content.get_card(card_id).is_empty() or not loadout.equip(card_id):
            return false
    var draft := DraftSystem.new()
    draft.configure(loadout.get_cards(), _content.get_cards_by_ids(loadout.get_cards()), _content.get_all_buffs(), _rng.randi())
    setups[side] = {"commander_id": commander_id, "card_ids": loadout.get_cards()}
    drafts[side] = draft
    public_sides[side] = _combat_side(side, false)
    if setups.size() == 2:
        _begin_draft(now)
    return true

func act(side: String, command: Dictionary, now: float) -> bool:
    if side not in SIDES or not drafts.has(side):
        return false
    if int(command.get("round", -1)) != match_state.round_number:
        return false
    if command.get("type") == "continue":
        if phase != "replay" or acknowledged[side]:
            return false
        acknowledged[side] = true
        if acknowledged["player"] and acknowledged["opponent"]:
            if not match_state.advance_round():
                return false
            _begin_draft(now)
        return true
    if phase != "draft" or int(command.get("revision", -1)) != revisions[side]:
        return false
    var draft: DraftSystem = drafts[side]
    if draft.is_phase_complete() or now >= float(deadlines[side]):
        return false
    var applied := false
    if command.get("type") == "pick":
        applied = draft.select_offer(int(command.get("index", -1)))
    elif command.get("type") == "skill":
        applied = draft.use_commander_skill()
    if applied:
        _picked(side, now)
    return applied

func tick(now: float) -> bool:
    var changed := false
    if phase == "draft":
        for side in SIDES:
            var draft: DraftSystem = drafts[side]
            # Bounded by the remaining (at most four) legal selections. A stalled
            # process catches up from absolute deadlines, not from client clocks.
            while not draft.is_phase_complete() and now >= float(deadlines[side]):
                var expired_at: float = deadlines[side]
                if not draft.auto_select():
                    break
                _picked(side, expired_at)
                changed = true
    return changed

func battle_request() -> Dictionary:
    if phase != "draft" or not drafts["player"].is_phase_complete() or not drafts["opponent"].is_phase_complete():
        return {}
    if not match_state.begin_battle():
        return {}
    phase = "simulating"
    losses_before = match_state.losses.duplicate()
    for side in SIDES:
        public_sides[side] = _combat_side(side, drafts[side].commander_skill_used_this_round)
    return {"round": match_state.round_number, "player": public_sides["player"].duplicate(true),
        "opponent": public_sides["opponent"].duplicate(true), "seed": _rng.randi(),
        "balance": _content.get_game_balance().duplicate(true)}

func accept_battle(round_number: int, battle: Dictionary) -> bool:
    if phase != "simulating" or round_number != match_state.round_number:
        return false
    if not match_state.resolve_round(str(battle.get("winner", "")), float(battle.get("duration", 0))):
        return false
    result = battle.duplicate(true)
    phase = "complete" if match_state.is_complete() else "replay"
    return true

func view_for(side: String, now: float) -> Dictionary:
    if not setups.has(side):
        return {}
    var other := "opponent" if side == "player" else "player"
    var draft: DraftSystem = drafts[side]
    # No seed, RNG state, opposing offer, current counts, points, skill or revision.
    # Public snapshots are captured BEFORE either seat starts the new draft.
    return {"phase": phase, "round": match_state.round_number, "you": side,
        "losses": match_state.losses.duplicate(), "losses_before": losses_before.duplicate(),
        "sudden_death": match_state.sudden_death, "winner": match_state.winner,
        "self": _combat_side(side, draft.commander_skill_used_this_round),
        "rival": public_sides.get(other, {}).duplicate(true),
        "offer": draft.current_offer.duplicate(true), "points": draft.selection_points,
        "revision": revisions[side], "selection_seconds": maxf(0, float(deadlines[side]) - now) if phase == "draft" and not draft.is_phase_complete() else 0.0,
        "acknowledged": acknowledged[side], "replay_available": not result.is_empty()}

func _picked(side: String, picked_at: float) -> void:
    revisions[side] += 1
    deadlines[side] = picked_at + PICK_SECONDS

func _begin_draft(now: float) -> void:
    for side in SIDES:
        public_sides[side] = _combat_side(side, false)
    result.clear()
    acknowledged = {"player": false, "opponent": false}
    phase = "draft"
    for side in SIDES:
        drafts[side].begin_round(match_state.round_number == 1, bool(match_state.lost_previous[side]), match_state.sudden_death)
        revisions[side] += 1
        deadlines[side] = now + PICK_SECONDS

func _combat_side(side: String, skill_active: bool) -> Dictionary:
    var setup: Dictionary = setups[side]
    var draft: DraftSystem = drafts[side]
    var commander: Dictionary = _content.get_commander(setup["commander_id"])
    var cards: Array = _content.get_cards_by_ids(setup["card_ids"])
    var signature: Dictionary = _content.get_signature_set(str(commander.get("signature_set_id", "")))
    var bonus := {}
    if SetBonusChecker.is_complete(cards, str(signature.get("id", "")), int(signature.get("required_count", 4))):
        bonus = signature.get("bonus", {}).duplicate(true)
    var buffs: Array[Dictionary] = []
    for buff in _content.get_all_buffs():
        var stacks := draft.get_buff_stacks(str(buff["id"]))
        if stacks > 0:
            buffs.append({"definition": buff.duplicate(true), "stacks": stacks})
    return {"id": side, "commander": commander.duplicate(true), "cards": cards.duplicate(true),
        "unit_counts": draft.unit_counts.duplicate(), "buffs": buffs, "set_bonus": bonus,
        "commander_skill_active": skill_active, "skill_uses_remaining": draft.commander_skill_uses_remaining()}
