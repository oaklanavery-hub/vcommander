extends Node

const ArmyLoadoutScript = preload("res://scripts/army/army_loadout.gd")
const SetBonusCheckerScript = preload("res://scripts/commanders/set_bonus_checker.gd")
const DraftSystemScript = preload("res://scripts/draft/draft_system.gd")
const MatchScript = preload("res://scripts/core/match_state.gd")
const AiScript = preload("res://scripts/ai/ai_controller.gd")
const CombatSimulatorScript = preload("res://scripts/combat/combat_simulator.gd")
const CommanderProgressScript = preload("res://scripts/core/commander_progress.gd")
const DeveloperAccessScript = preload("res://scripts/core/developer_access.gd")
const StoreScript = preload("res://scripts/core/local_match_store.gd")

signal collection_changed

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
var commander_progress: CommanderProgress
var developer_access: DeveloperAccess
var mastery_reward: Dictionary = {}
var _progress_match_id := ""
var local_store: LocalMatchStore
var draft_time_left := 30.0
var battle_watched := false
var recovery_notice := ""
var _restoring := false
var match_preferences: MatchPreferences
var active_difficulty := "standard"
var match_insights: MatchInsights
var _draft_elapsed := 0.0
var _watch_elapsed := 0.0

func _ready() -> void:
    # Tool scripts receive an in-memory profile and cannot touch a player's records.
    var arguments := OS.get_cmdline_args()
    var scripted := arguments.has("--script") or arguments.has("-s") or DisplayServer.get_name() == "headless"
    developer_access = DeveloperAccessScript.new("" if scripted else DeveloperAccessScript.DEFAULT_PATH)
    developer_access.changed.connect(_on_collection_access_changed)
    commander_progress = CommanderProgressScript.new(ContentDatabase, "" if scripted else CommanderProgressScript.DEFAULT_PATH, developer_access)
    local_store = StoreScript.new("" if scripted else StoreScript.DEFAULT_PATH)
    match_preferences = MatchPreferences.new("" if scripted else MatchPreferences.DEFAULT_PATH)
    match_insights = MatchInsights.new("" if scripted else MatchInsights.DEFAULT_PATH)
    _bind_draft()
    # A refresh preserves the pending identity. A legacy interrupted match still
    # follows the old recovery policy when there is no resumable checkpoint.
    if not local_store.exists():
        commander_progress.recover_interrupted_match()

func activate_developer_access(key: String) -> Error:
    return ERR_BUSY if has_pending_adventure() or OnlineSession.active else developer_access.activate(key)

func remove_developer_access() -> Error:
    return ERR_BUSY if has_pending_adventure() or OnlineSession.active else developer_access.remove()

func _on_collection_access_changed() -> void:
    for index in range(army.size() - 1, -1, -1):
        if not commander_progress.is_card_unlocked(army.get_cards()[index]):
            army.unequip_at(index)
    collection_changed.emit()

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
    if not commander_progress.is_card_unlocked(card_id):
        return false
    _reset_match_runtime()
    return army.equip(card_id)

func unequip_card_at(index: int) -> bool:
    _reset_match_runtime()
    return army.unequip_at(index)

func clear_army() -> void:
    _reset_match_runtime()
    army.clear()

func equip_starter_army() -> bool:
    var signature := get_selected_signature_set()
    if signature.is_empty():
        return false
    var candidate = ArmyLoadoutScript.new(army.max_slots)
    for card in ContentDatabase.get_cards_by_set(str(signature["id"])):
        if not card.has("mastery_unlock") and commander_progress.is_card_unlocked(str(card["id"])):
            candidate.equip(str(card["id"]))
        if candidate.is_full():
            break
    if not candidate.is_full():
        return false
    _reset_match_runtime()
    army = candidate
    return true

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
    for card_id in army.get_cards():
        if not commander_progress.is_card_unlocked(card_id):
            return false
    _reset_match_runtime()
    match_seed = seed_value
    match_state.start(int(ContentDatabase.get_game_balance().get("match", {}).get("losses_to_lose_match", 4)))
    draft.configure(
        army.get_cards(),
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        ContentDatabase.get_all_buffs(),
        match_seed,
        _draft_options(selected_commander_id, match_preferences.specialization_experiment)
    )
    draft.begin_round(true, false, false)
    match_started = true
    battle_result.clear()
    opponent = AiScript.new()
    active_difficulty = match_preferences.difficulty
    var preferences := _draft_options(selected_commander_id, match_preferences.specialization_experiment)
    preferences["difficulty"] = active_difficulty
    if not opponent.configure(ContentDatabase.get_all_commanders(), commander_progress.available_cards(), ContentDatabase.sets, ContentDatabase.get_all_buffs(), match_seed + 3571, ContentDatabase.get_game_balance().get("stats", {}), preferences):
        match_started = false
        return false
    opponent_public_side = opponent.get_side()
    var ready: bool = opponent.begin_round(true, false, false, get_player_combat_side())
    draft_time_left = 30.0
    battle_watched = false
    _draft_elapsed = 0.0
    _watch_elapsed = 0.0
    checkpoint()
    return ready

func run_battle() -> bool:
    if not match_started or not draft.is_phase_complete():
        return false
    if not battle_result.is_empty():
        return true

    if not match_state.begin_battle():
        return false
    if _progress_match_id.is_empty():
        _progress_match_id = commander_progress.begin_match(selected_commander_id)
    # Persist the prepared inputs/identity before simulation or profile settlement.
    checkpoint()
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
    var resolved: bool = match_state.resolve_round(str(battle_result.get("winner", "draw")), float(battle_result.get("duration", 0.0)))
    if resolved:
        var metadata := {"commander": selected_commander_id, "difficulty": active_difficulty, "redraw": draft.redraw_enabled, "specializations": draft.specialization_enabled, "composition": "themed" if is_full_set_active() else "mixed", "outcome": ("win" if match_state.winner == "player" else "loss") if match_state.is_complete() else "ongoing"}
        var history: Dictionary = match_state.history.back()
        match_insights.record_round(_progress_match_id, metadata, {"round": match_state.round_number, "winner": battle_result.get("winner"), "reason": battle_result.get("reason"), "duration": battle_result.get("duration"), "draft_seconds": _draft_elapsed, "sudden": history.get("sudden_death", false), "army_capped": draft._eligible_unit_ids().is_empty()})
    if resolved and match_state.is_complete():
        mastery_reward = commander_progress.finish_match(_progress_match_id, "win" if match_state.winner == "player" else "loss")
    battle_watched = false
    _watch_elapsed = 0.0
    checkpoint()
    return resolved

func begin_next_round() -> bool:
    if not match_started or not match_state.advance_round():
        return false
    var public_player := get_player_combat_side().duplicate(true)
    opponent_public_side = opponent.get_side()
    battle_result.clear()
    opponent_combat_side.clear()
    draft.begin_round(false, bool(match_state.lost_previous["player"]), match_state.sudden_death)
    var ready: bool = opponent.begin_round(false, bool(match_state.lost_previous["opponent"]), match_state.sudden_death, public_player, int(match_state.losses["opponent"]))
    draft_time_left = 30.0
    battle_watched = false
    _draft_elapsed = 0.0
    _watch_elapsed = 0.0
    checkpoint()
    return ready

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

    var buff_states: Array[Dictionary] = draft_state.get_buff_states()

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
        "skill_uses_remaining": draft_state.commander_skill_uses_remaining(),
        "specialization": draft_state.specialization()
    }.merged(draft_state.round_context())

func _reset_match_runtime() -> void:
    if match_insights != null and not _progress_match_id.is_empty():
        match_insights.record_watch(_progress_match_id, match_state.round_number, _watch_elapsed)
        match_insights.finish(_progress_match_id, "forfeit")
    if commander_progress != null and not _progress_match_id.is_empty():
        # A completed match is already settled; repeat calls cannot change its result.
        var outcome := ("win" if match_state.winner == "player" else "loss") if match_state.is_complete() else "forfeit"
        commander_progress.finish_match(_progress_match_id, outcome)
    elif commander_progress != null and not commander_progress.active_match().is_empty():
        commander_progress.finish_match(str(commander_progress.active_match()["id"]), "forfeit")
    if local_store != null:
        local_store.clear()
    _progress_match_id = ""
    mastery_reward.clear()
    match_started = false
    match_state.start()
    battle_result.clear()
    opponent_public_side.clear()
    opponent_combat_side.clear()
    recovery_notice = ""
    battle_watched = false

func _bind_draft() -> void:
    if not draft.changed.is_connected(_draft_changed):
        draft.changed.connect(_draft_changed)

func _draft_changed(reset_clock: bool) -> void:
    if reset_clock:
        draft_time_left = 30.0
    checkpoint()

func update_draft_clock(seconds: float) -> void:
    var previous := int(ceil(draft_time_left))
    _draft_elapsed += maxf(0, draft_time_left - clampf(seconds, 0.0, 30.0))
    draft_time_left = clampf(seconds, 0.0, 30.0)
    if int(ceil(draft_time_left)) != previous:
        checkpoint()

func mark_battle_watched() -> void:
    if not battle_watched:
        battle_watched = true
        match_insights.record_watch(_progress_match_id, match_state.round_number, _watch_elapsed)
        checkpoint()

func record_watch_time(seconds: float) -> void:
    var previous := int(_watch_elapsed)
    _watch_elapsed += maxf(0, seconds)
    if int(_watch_elapsed) != previous:
        checkpoint()

func has_pending_adventure() -> bool:
    return match_started or (local_store != null and local_store.exists()) or (commander_progress != null and not commander_progress.active_match().is_empty())

func has_saved_match() -> bool:
    if local_store == null:
        return false
    for value in local_store.candidates():
        if not _decode_checkpoint(value).is_empty():
            return true
    if local_store.exists():
        recovery_notice = "This saved adventure cannot be resumed with the current rules. Starting a new match will ask before retiring it."
    return false

func _draft_options(commander_id: String, enabled: bool) -> Dictionary:
    return {"redraw_experiment": match_preferences.redraw_experiment, "specialization_experiment": enabled, "commander_id": commander_id, "specialization_catalog": ContentDatabase.get_specializations(), "match_rules": ContentDatabase.get_game_balance().get("match", {})}

func _content_fingerprint(include_specializations: bool = false, legacy_overtime: bool = false) -> String:
    var balances: Dictionary = ContentDatabase.balances
    if legacy_overtime:
        balances = balances.duplicate(true)
        for balance in balances.values():
            balance.get("match", {}).erase("sudden_death_round_time_seconds")
            balance.get("match", {}).erase("sudden_death_power_multiplier")
    var definitions: Array = [ContentDatabase.commanders, ContentDatabase.cards, ContentDatabase.sets, ContentDatabase.buffs, balances]
    if include_specializations:
        definitions.append(ContentDatabase.get_specializations())
    return JSON.stringify(definitions).sha256_text()

func checkpoint() -> void:
    if _restoring or not match_started or local_store == null:
        return
    var info := {
        "round": match_state.round_number, "losses": match_state.losses.duplicate(),
        "lost_previous": match_state.lost_previous.duplicate(), "sudden": match_state.sudden_death,
        "phase": match_state.phase, "winner": match_state.winner, "history": match_state.history.duplicate(true)
    }
    # begin_battle is synchronous. A crash here resumes the prepared draft and
    # reruns its immutable inputs rather than pretending an unscored round ended.
    if info["phase"] == "battle":
        info["phase"] = "draft"
    var opponent_ids: Array[String] = []
    for card in opponent.cards:
        opponent_ids.append(str(card["id"]))
    var error := local_store.save({
        "schema": 1, "content": _content_fingerprint(draft.specialization_enabled), "commander": selected_commander_id,
        "army": army.get_cards(), "seed": str(match_seed), "draft": draft.snapshot(),
        "opponent_commander": str(opponent.commander.get("id", "")), "opponent_cards": opponent_ids,
        "opponent_draft": opponent.draft.snapshot(), "opponent_rng": str(opponent._rng.state),
        "difficulty": active_difficulty, "style": opponent.style, "enemy_evidence": opponent._public_enemy.duplicate(true),
        "public_side": opponent_public_side.duplicate(true), "match": info,
        "progress_id": _progress_match_id, "clock": draft_time_left, "watched": battle_watched,
        "reward": mastery_reward.duplicate(true),
        "draft_elapsed": _draft_elapsed, "watch_elapsed": _watch_elapsed
    })
    recovery_notice = "Adventure could not be saved. Keep this tab open and try again." if error != OK else ""

func resume_match() -> bool:
    if local_store == null:
        return false
    for value in local_store.candidates():
        var decoded := _decode_checkpoint(value)
        if decoded.is_empty():
            continue
        _restoring = true
        selected_commander_id = str(value["commander"])
        army = decoded["army"]
        draft = decoded["draft"]
        _bind_draft()
        opponent = decoded["opponent"]
        match_state = decoded["match"]
        match_seed = int(value["seed"])
        active_difficulty = str(value.get("difficulty", "standard"))
        _progress_match_id = str(decoded["progress_id"])
        draft_time_left = float(value["clock"])
        battle_watched = bool(value["watched"])
        _draft_elapsed = float(value.get("draft_elapsed", 0))
        _watch_elapsed = float(value.get("watch_elapsed", 0))
        mastery_reward = value.get("reward", {}).duplicate(true)
        if mastery_reward.is_empty() and commander_progress.last_receipt.get("match_id") == _progress_match_id:
            mastery_reward = commander_progress.last_receipt.duplicate(true)
        opponent_public_side = decoded["public_side"]
        match_started = true
        battle_result.clear()
        opponent_combat_side.clear()
        if match_state.phase in ["result", "complete"]:
            opponent_combat_side = opponent.get_side(opponent.draft.commander_skill_used_this_round)
            battle_result = CombatSimulatorScript.new().simulate(get_player_combat_side(), opponent_combat_side, match_seed + match_state.round_number * 104729, ContentDatabase.get_game_balance())
        if match_state.is_complete() and commander_progress.active_match().get("id") == _progress_match_id:
            # The checkpoint may have reached disk while the final profile write
            # failed. Retry that settled outcome, never turn it into a forfeit.
            mastery_reward = commander_progress.finish_match(_progress_match_id, "win" if match_state.winner == "player" else "loss")
        _restoring = false
        recovery_notice = ""
        checkpoint()
        return true
    recovery_notice = "Saved adventure could not be resumed. Your mastery records have been kept."
    return false

func _decode_checkpoint(value: Dictionary) -> Dictionary:
    var uses_specializations := bool(value.get("draft", {}).get("specialization_enabled", false)) if value.get("draft") is Dictionary else false
    var legacy_overtime: bool = value.get("content") == _content_fingerprint(uses_specializations, true)
    if value.get("schema") != 1 or (value.get("content") != _content_fingerprint(uses_specializations) and not legacy_overtime):
        return {}
    if str(value.get("difficulty", "standard")) not in MatchPreferences.DIFFICULTIES or str(value.get("style", "swarm")) not in AiScript.STYLE_NAMES or not value.get("enemy_evidence", {}) is Dictionary:
        return {}
    for key in ["seed", "opponent_rng"]:
        if not value.get(key) is String or not str(value[key]).is_valid_int():
            return {}
    if not value.get("progress_id") is String or not value.get("watched") is bool or not value.get("reward", {}) is Dictionary:
        return {}
    for field in ["draft_elapsed", "watch_elapsed"]:
        if not MatchInsights._seconds(value.get(field, 0)):
            return {}
    if not (value.get("clock") is float or value.get("clock") is int) or not is_finite(float(value["clock"])) or float(value["clock"]) < 0 or float(value["clock"]) > 30:
        return {}
    if ContentDatabase.get_commander(str(value.get("commander", ""))).is_empty() or ContentDatabase.get_commander(str(value.get("opponent_commander", ""))).is_empty():
        return {}
    var armies: Array = []
    for key in ["army", "opponent_cards"]:
        if not value.get(key) is Array or value[key].size() != 4:
            return {}
        var loadout = ArmyLoadoutScript.new(4)
        for id in value[key]:
            if not id is String or not commander_progress.is_card_unlocked(id) or not loadout.equip(id):
                return {}
        armies.append(loadout)
    for key in ["draft", "opponent_draft", "match", "public_side"]:
        if not value.get(key) is Dictionary:
            return {}
    # Completed old rounds must reconstruct with their original clock, even
    # after the upgraded checkpoint is written with the new fingerprint.
    var player_snapshot: Dictionary = value["draft"].duplicate(true)
    var rival_snapshot: Dictionary = value["opponent_draft"].duplicate(true)
    if legacy_overtime and value["match"].get("phase") in ["result", "complete"]:
        var legacy_seconds := float(ContentDatabase.get_game_balance().get("match", {}).get("round_time_seconds", 120))
        player_snapshot["round_time_limit"] = legacy_seconds
        rival_snapshot["round_time_limit"] = legacy_seconds
    var player_draft = DraftSystemScript.new()
    player_draft.configure(value["army"], ContentDatabase.get_cards_by_ids(value["army"]), ContentDatabase.get_all_buffs(), int(value["seed"]), _draft_options(str(value["commander"]), uses_specializations))
    if not player_draft.restore(player_snapshot):
        return {}
    var rival = AiScript.new()
    if not rival.configure(ContentDatabase.get_all_commanders(), commander_progress.available_cards(), ContentDatabase.sets, ContentDatabase.get_all_buffs(), int(value["seed"]) + 3571, ContentDatabase.get_game_balance().get("stats", {})):
        return {}
    rival.commander = ContentDatabase.get_commander(str(value["opponent_commander"])).duplicate(true)
    rival.signature_set = ContentDatabase.get_signature_set(str(rival.commander["signature_set_id"])).duplicate(true)
    rival.cards.assign(ContentDatabase.get_cards_by_ids(value["opponent_cards"]))
    rival.draft.configure(value["opponent_cards"], rival.cards, ContentDatabase.get_all_buffs(), int(value["seed"]) + 11490, _draft_options(str(value["opponent_commander"]), uses_specializations))
    if not rival.draft.restore(rival_snapshot):
        return {}
    if rival.draft.round_time_limit != player_draft.round_time_limit or rival.draft.sudden_death != player_draft.sudden_death:
        return {}
    if value["match"].get("phase") == "draft" and player_draft.round_time_limit != (player_draft._sudden_round_seconds if player_draft.sudden_death else player_draft._normal_round_seconds):
        return {}
    if rival.draft.specialization_enabled != player_draft.specialization_enabled:
        return {}
    rival._rng.state = int(value["opponent_rng"])
    rival.difficulty = str(value.get("difficulty", "standard"))
    rival.style = str(value.get("style", "swarm"))
    rival._public_enemy = value.get("enemy_evidence", {}).duplicate(true)
    var info: Dictionary = value["match"]
    if not CommanderProgress._counter(info.get("round")) or int(info["round"]) < 1 or info.get("phase") not in ["draft", "result", "complete"] or info.get("winner") not in ["", "player", "opponent"]:
        return {}
    if not info.get("losses") is Dictionary or not info.get("lost_previous") is Dictionary or not info.get("sudden") is bool or not info.get("history") is Array:
        return {}
    for side in ["player", "opponent"]:
        if not CommanderProgress._counter(info["losses"].get(side)) or int(info["losses"][side]) > int(info["round"]) or not info["lost_previous"].get(side) is bool:
            return {}
    var expected_history := int(info["round"]) - (1 if info["phase"] == "draft" else 0)
    if info["history"].size() != expected_history or player_draft.round_number != int(info["round"]) or rival.draft.round_number != int(info["round"]):
        return {}
    for index in range(info["history"].size()):
        var entry = info["history"][index]
        if not entry is Dictionary or entry.get("round") != index + 1 or entry.get("winner") not in ["player", "opponent", "draw"] or not entry.get("sudden_death") is bool:
            return {}
        if not (entry.get("duration") is float or entry.get("duration") is int) or not is_finite(float(entry["duration"])) or float(entry["duration"]) < 0 or float(entry["duration"]) > float(ContentDatabase.get_game_balance()["match"]["sudden_death_round_time_seconds" if entry["sudden_death"] else "round_time_seconds"]) + 0.1:
            return {}
    if info["phase"] != "draft" and (not player_draft.is_phase_complete() or not rival.draft.is_phase_complete()):
        return {}
    if (info["phase"] == "complete") != (not str(info["winner"]).is_empty()):
        return {}
    var public: Dictionary = value["public_side"]
    if not public.get("specialization", {}) is Dictionary:
        return {}
    if not public.get("sudden_death", false) is bool:
        return {}
    var public_limit = public.get("round_time_limit", player_draft._normal_round_seconds)
    if not (public_limit is int or public_limit is float) or float(public_limit) not in [player_draft._normal_round_seconds, player_draft._sudden_round_seconds]:
        return {}
    var public_specialization := str(public.get("specialization", {}).get("id", ""))
    if not public_specialization.is_empty() and (not uses_specializations or public_specialization != rival.draft.specialization_id):
        return {}
    if not public.get("commander") is Dictionary or not public.get("cards") is Array or not public.get("unit_counts") is Dictionary or not public.get("buffs") is Array:
        return {}
    if public["commander"].get("id") != value["opponent_commander"] or public["cards"].size() != 4 or not CommanderProgress._counter(public.get("skill_uses_remaining")) or int(public["skill_uses_remaining"]) > 2:
        return {}
    var seen_cards := {}
    for card in public["cards"]:
        if not card is Dictionary or not card.get("id") is String or not value["opponent_cards"].has(card["id"]) or seen_cards.has(card["id"]):
            return {}
        seen_cards[card["id"]] = true
    if public["unit_counts"].size() != 4:
        return {}
    var public_counts := {}
    for id in public["unit_counts"]:
        if not seen_cards.has(id) or not CommanderProgress._counter(public["unit_counts"][id]) or int(public["unit_counts"][id]) > int(ContentDatabase.get_card(id)["unit_cap"]):
            return {}
        public_counts[id] = int(public["unit_counts"][id])
    var public_buffs: Array = []
    var seen_buffs := {}
    for entry in public["buffs"]:
        if not entry is Dictionary or not entry.get("definition") is Dictionary or not CommanderProgress._counter(entry.get("stacks")):
            return {}
        var id := str(entry["definition"].get("id", ""))
        var definition := ContentDatabase.get_buff(id)
        if definition.is_empty() or seen_buffs.has(id):
            return {}
        seen_buffs[id] = true
        if not CommanderProgress._counter(entry.get("sudden_death_stacks", 0)):
            return {}
        var enhanced := int(entry.get("sudden_death_stacks", 0))
        var total := int(entry["stacks"])
        var private_enhanced := int(rival.draft.sudden_death_buff_stacks.get(id, 0))
        if enhanced > total or enhanced > private_enhanced or total - enhanced > rival.draft.get_buff_stacks(id) - private_enhanced:
            return {}
        var restored_buff := {"definition": definition.duplicate(true), "stacks": total}
        if enhanced > 0:
            restored_buff["sudden_death_stacks"] = enhanced
            restored_buff["sudden_death_multiplier"] = rival.draft.sudden_death_power_multiplier
        public_buffs.append(restored_buff)
    # Rebuild definitions from current content. Corrupted saved display metadata
    # can neither inject stats into advice nor crash roster rendering.
    var restored_public: Dictionary = rival.get_side()
    # Round context is public, but must not be copied from hidden current picks.
    restored_public["sudden_death"] = bool(public.get("sudden_death", false))
    restored_public["round_time_limit"] = float(public.get("round_time_limit", player_draft._normal_round_seconds))
    restored_public["unit_counts"] = public_counts
    restored_public["buffs"] = public_buffs
    restored_public["skill_uses_remaining"] = int(public["skill_uses_remaining"])
    restored_public["specialization"] = rival.draft.specialization_options.get(public_specialization, {}).duplicate(true)
    var progress_id: String = value["progress_id"]
    var pending := commander_progress.active_match()
    if progress_id.is_empty() and not pending.is_empty():
        if pending.get("commander_id") != value["commander"] or not player_draft.is_phase_complete():
            return {}
        progress_id = str(pending["id"])
    elif not progress_id.is_empty():
        var receipt := commander_progress.last_receipt
        if pending.get("id") != progress_id and (receipt.get("match_id") != progress_id or receipt.get("outcome") == "forfeit"):
            return {}
    var restored_match = MatchScript.new()
    restored_match.start(int(ContentDatabase.get_game_balance().get("match", {}).get("losses_to_lose_match", 4)))
    restored_match.round_number = int(info["round"])
    restored_match.losses = info["losses"].duplicate()
    for side in ["player", "opponent"]:
        restored_match.losses[side] = int(restored_match.losses[side])
    restored_match.lost_previous = info["lost_previous"].duplicate()
    restored_match.sudden_death = bool(info["sudden"])
    restored_match.phase = str(info["phase"])
    restored_match.winner = str(info["winner"])
    restored_match.history.assign(info["history"])
    for entry in restored_match.history:
        entry["round"] = int(entry["round"])
    return {"army": armies[0], "draft": player_draft, "opponent": rival, "match": restored_match, "progress_id": progress_id, "public_side": restored_public}
