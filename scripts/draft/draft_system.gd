class_name DraftSystem
extends RefCounted

signal changed(reset_clock: bool)

const DEFAULT_SELECTIONS := 3
const LOSER_SELECTIONS := 4
const OFFER_SIZE := 3
const MAX_BUFFS_WITH_UNITS := 2
const COMMANDER_SKILL_USES_PER_MATCH := 2

var loadout_card_ids: Array[String] = []
var card_definitions: Dictionary = {}
var buff_definitions: Dictionary = {}
var unit_counts: Dictionary = {}
var buff_stacks: Dictionary = {}
var sudden_death_buff_stacks: Dictionary = {}
var round_time_limit := 120.0
var sudden_death_power_multiplier := 2.0
var _normal_round_seconds := 120.0
var _sudden_round_seconds := 180.0
var current_offer: Array[Dictionary] = []

var selection_points := 0
var round_number := 0
var opening_phase := true
var sudden_death := false
var commander_skill_uses := 0
var commander_skill_used_this_round := false
var seed := 1

var _rng := RandomNumberGenerator.new()
var redraw_enabled := false
var redraw_used := false
var redraws_taken := 0
var specialization_enabled := false
var specialization_id := ""
var specialization_options: Dictionary = {}
var specialization_first_round := 3
var specialization_cost := 1

func configure(card_ids: Array, cards: Array, buffs: Array, match_seed: int, options: Dictionary = {}) -> void:
    loadout_card_ids.clear()
    card_definitions.clear()
    buff_definitions.clear()
    unit_counts.clear()
    buff_stacks.clear()
    sudden_death_buff_stacks.clear()
    var match_rules: Dictionary = options.get("match_rules", {})
    _normal_round_seconds = float(match_rules.get("round_time_seconds", 120))
    _sudden_round_seconds = float(match_rules.get("sudden_death_round_time_seconds", 180))
    sudden_death_power_multiplier = float(match_rules.get("sudden_death_power_multiplier", 2))
    round_time_limit = _normal_round_seconds
    sudden_death = false
    current_offer.clear()
    commander_skill_uses = 0
    round_number = 0
    redraw_enabled = bool(options.get("redraw_experiment", false))
    redraw_used = false
    redraws_taken = 0
    specialization_enabled = bool(options.get("specialization_experiment", false))
    specialization_id = ""
    specialization_options.clear()
    var catalog: Dictionary = options.get("specialization_catalog", {})
    specialization_first_round = int(catalog.get("first_round", 3))
    specialization_cost = int(catalog.get("selection_cost", 1))
    for branch in CommanderSpecializations.options(catalog, str(options.get("commander_id", ""))):
        specialization_options[str(branch["id"])] = branch

    for raw_id in card_ids:
        var card_id := str(raw_id)
        if not card_id.is_empty() and not loadout_card_ids.has(card_id):
            loadout_card_ids.append(card_id)

    for card in cards:
        if typeof(card) != TYPE_DICTIONARY:
            continue
        var card_id := str(card.get("id", ""))
        if loadout_card_ids.has(card_id):
            card_definitions[card_id] = card
            unit_counts[card_id] = 0

    for buff in buffs:
        if typeof(buff) != TYPE_DICTIONARY:
            continue
        var buff_id := str(buff.get("id", ""))
        if not buff_id.is_empty():
            buff_definitions[buff_id] = buff
            buff_stacks[buff_id] = 0
            sudden_death_buff_stacks[buff_id] = 0

    seed = match_seed
    _rng.seed = match_seed

func begin_round(is_opening: bool, lost_previous_round: bool, is_sudden_death: bool = false) -> void:
    round_number += 1
    opening_phase = is_opening
    sudden_death = is_sudden_death
    round_time_limit = _sudden_round_seconds if sudden_death else _normal_round_seconds
    commander_skill_used_this_round = false
    redraw_used = false
    selection_points = DEFAULT_SELECTIONS
    if not is_opening and lost_previous_round and not is_sudden_death:
        selection_points = LOSER_SELECTIONS
    refresh_offer()

func refresh_offer() -> Array[Dictionary]:
    current_offer.clear()
    if selection_points <= 0:
        return current_offer

    var eligible_units: Array[String] = _eligible_unit_ids()
    var eligible_buffs: Array[String] = _eligible_buff_ids()

    if opening_phase:
        current_offer = _make_options(_take_random(eligible_units, OFFER_SIZE), "unit")
    elif eligible_units.is_empty():
        current_offer = _make_options(_take_random(eligible_buffs, OFFER_SIZE), "buff")
    else:
        var minimum_buffs: int = maxi(0, OFFER_SIZE - eligible_units.size())
        var maximum_buffs: int = mini(MAX_BUFFS_WITH_UNITS, eligible_buffs.size())
        maximum_buffs = mini(maximum_buffs, OFFER_SIZE - 1)
        minimum_buffs = mini(minimum_buffs, maximum_buffs)
        var buff_count: int = 0
        if maximum_buffs > 0:
            buff_count = _rng.randi_range(minimum_buffs, maximum_buffs)
        var unit_count: int = mini(OFFER_SIZE - buff_count, eligible_units.size())
        if unit_count == 0:
            unit_count = mini(1, eligible_units.size())
            buff_count = mini(OFFER_SIZE - unit_count, eligible_buffs.size())

        current_offer.append_array(_make_options(_take_random(eligible_units, unit_count), "unit"))
        current_offer.append_array(_make_options(_take_random(eligible_buffs, buff_count), "buff"))
        _shuffle_options(current_offer)

    if current_offer.is_empty():
        selection_points = 0
    return current_offer.duplicate(true)

func select_offer(index: int) -> bool:
    if index < 0 or index >= current_offer.size() or selection_points <= 0:
        return false

    var option: Dictionary = current_offer[index]
    var option_type := str(option.get("type", ""))
    var option_id := str(option.get("id", ""))
    var applied := false

    if option_type == "unit":
        applied = _apply_unit(option_id)
    elif option_type == "buff":
        applied = _apply_buff(option_id)

    if not applied:
        return false

    selection_points -= 1
    if selection_points > 0:
        refresh_offer()
    else:
        current_offer.clear()
    changed.emit(true)
    return true

func auto_select() -> bool:
    if current_offer.is_empty() or selection_points <= 0:
        return false
    return select_offer(_rng.randi_range(0, current_offer.size() - 1))

func use_commander_skill() -> bool:
    if selection_points <= 0:
        return false
    if commander_skill_uses >= COMMANDER_SKILL_USES_PER_MATCH:
        return false
    if commander_skill_used_this_round:
        return false

    commander_skill_uses += 1
    commander_skill_used_this_round = true
    selection_points -= 1
    if selection_points > 0:
        refresh_offer()
    else:
        current_offer.clear()
    changed.emit(true)
    return true

func can_redraw() -> bool:
    return redraw_enabled and not redraw_used and selection_points > 0 and not current_offer.is_empty()

func redraw() -> bool:
    if not can_redraw():
        return false
    redraw_used = true
    redraws_taken += 1
    refresh_offer()
    changed.emit(false) # No extra pick and no extra decision time.
    return true

func can_specialize(id: String = "") -> bool:
    if not specialization_enabled or not specialization_id.is_empty() or round_number < specialization_first_round or opening_phase or selection_points < specialization_cost:
        return false
    if id.is_empty():
        for option_id in specialization_options:
            if can_specialize(str(option_id)):
                return true
        return false
    return specialization_options.has(id) and not CommanderSpecializations.affected(card_definitions.values(), unit_counts, specialization_options[id])["types"].is_empty()

func choose_specialization(id: String) -> bool:
    if not can_specialize(id):
        return false
    specialization_id = id
    selection_points -= specialization_cost
    refresh_offer()
    changed.emit(true)
    return true

func specialization() -> Dictionary:
    return specialization_options.get(specialization_id, {}).duplicate(true)

func snapshot() -> Dictionary:
    return {
        "seed": str(seed), "rng_state": str(_rng.state),
        "unit_counts": unit_counts.duplicate(), "buff_stacks": buff_stacks.duplicate(),
        "sudden_death_buff_stacks": sudden_death_buff_stacks.duplicate(), "round_time_limit": round_time_limit,
        "offer": current_offer.duplicate(true), "points": selection_points,
        "round": round_number, "opening": opening_phase, "sudden": sudden_death,
        "skill_uses": commander_skill_uses, "skill_prepared": commander_skill_used_this_round,
        "redraw_enabled": redraw_enabled, "redraw_used": redraw_used, "redraws_taken": redraws_taken,
        "specialization_enabled": specialization_enabled, "specialization_id": specialization_id
    }

# Configure current content first; validate everything before mutating this draft.
func restore(value: Dictionary) -> bool:
    for field in ["seed", "rng_state"]:
        if not value.get(field) is String or not str(value[field]).is_valid_int():
            return false
    for field in ["opening", "sudden", "skill_prepared"]:
        if not value.get(field) is bool:
            return false
    for field in ["points", "round", "skill_uses"]:
        if not CommanderProgress._counter(value.get(field)):
            return false
    if int(value["points"]) > LOSER_SELECTIONS or int(value["round"]) < 1 or int(value["skill_uses"]) > COMMANDER_SKILL_USES_PER_MATCH:
        return false
    if bool(value["skill_prepared"]) and int(value["skill_uses"]) == 0:
        return false
    if not value.get("redraw_enabled", false) is bool or not value.get("redraw_used", false) is bool or not CommanderProgress._counter(value.get("redraws_taken", 0)):
        return false
    if bool(value.get("redraw_used", false)) and (not bool(value.get("redraw_enabled", false)) or int(value.get("redraws_taken", 0)) == 0):
        return false
    if not value.get("specialization_enabled", false) is bool or not value.get("specialization_id", "") is String:
        return false
    var saved_specialization: String = value.get("specialization_id", "")
    if not saved_specialization.is_empty():
        if not bool(value.get("specialization_enabled", false)) or not specialization_options.has(saved_specialization) or int(value["round"]) < specialization_first_round:
            return false
    for field in ["unit_counts", "buff_stacks"]:
        if not value.get(field) is Dictionary:
            return false
        var definitions: Dictionary = card_definitions if field == "unit_counts" else buff_definitions
        if value[field].size() != definitions.size():
            return false
        for id in value[field]:
            if not definitions.has(id) or not CommanderProgress._counter(value[field][id]):
                return false
            if field == "unit_counts" and int(value[field][id]) > int(definitions[id].get("unit_cap", 0)):
                return false
    if not saved_specialization.is_empty() and CommanderSpecializations.affected(card_definitions.values(), value["unit_counts"], specialization_options[saved_specialization])["types"].is_empty():
        return false
    var enhanced: Dictionary = {}
    if value.has("sudden_death_buff_stacks"):
        if not value["sudden_death_buff_stacks"] is Dictionary or value["sudden_death_buff_stacks"].size() != buff_definitions.size():
            return false
        enhanced = value["sudden_death_buff_stacks"]
        for id in enhanced:
            if not buff_definitions.has(id) or not CommanderProgress._counter(enhanced[id]) or int(enhanced[id]) > int(value["buff_stacks"][id]) or (not bool(value["sudden"]) and int(enhanced[id]) > 0):
                return false
    var seconds = value.get("round_time_limit", _sudden_round_seconds if bool(value["sudden"]) else _normal_round_seconds)
    if not (seconds is int or seconds is float) or not is_finite(float(seconds)):
        return false
    # A migrated, already-scored v0.18 replay keeps its original normal limit.
    if float(seconds) != _normal_round_seconds and (not bool(value["sudden"]) or float(seconds) != _sudden_round_seconds):
        return false
    if not value.get("offer") is Array or value["offer"].size() > OFFER_SIZE:
        return false
    var seen := {}
    for option in value["offer"]:
        if not option is Dictionary or not option.get("id") is String:
            return false
        var id: String = option["id"]
        if seen.has(id):
            return false
        seen[id] = true
        if option.get("type") == "unit":
            if not card_definitions.has(id) or int(value["unit_counts"][id]) >= int(card_definitions[id]["unit_cap"]):
                return false
        elif option.get("type") == "buff":
            if not buff_definitions.has(id) or bool(value["opening"]):
                return false
        else:
            return false
    if (int(value["points"]) > 0) == value["offer"].is_empty():
        return false
    seed = int(value["seed"])
    _rng.seed = seed
    _rng.state = int(value["rng_state"])
    unit_counts.clear()
    buff_stacks.clear()
    for id in value["unit_counts"]:
        unit_counts[id] = int(value["unit_counts"][id])
    for id in value["buff_stacks"]:
        buff_stacks[id] = int(value["buff_stacks"][id])
        sudden_death_buff_stacks[id] = int(enhanced.get(id, 0))
    round_time_limit = float(seconds)
    current_offer.assign(value["offer"])
    selection_points = int(value["points"])
    round_number = int(value["round"])
    opening_phase = bool(value["opening"])
    sudden_death = bool(value["sudden"])
    commander_skill_uses = int(value["skill_uses"])
    commander_skill_used_this_round = bool(value["skill_prepared"])
    redraw_enabled = bool(value.get("redraw_enabled", false))
    redraw_used = bool(value.get("redraw_used", false))
    redraws_taken = int(value.get("redraws_taken", 0))
    specialization_enabled = bool(value.get("specialization_enabled", false))
    specialization_id = saved_specialization
    return true

func get_unit_count(card_id: String) -> int:
    return int(unit_counts.get(card_id, 0))

func get_buff_stacks(buff_id: String) -> int:
    return int(buff_stacks.get(buff_id, 0))

func get_buff_states() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for id in buff_definitions:
        var stacks := get_buff_stacks(str(id))
        if stacks <= 0:
            continue
        var entry := {"definition": buff_definitions[id].duplicate(true), "stacks": stacks}
        var enhanced := int(sudden_death_buff_stacks.get(id, 0))
        if enhanced > 0:
            entry["sudden_death_stacks"] = enhanced
            entry["sudden_death_multiplier"] = sudden_death_power_multiplier
        result.append(entry)
    return result

func round_context() -> Dictionary:
    return {"sudden_death": sudden_death, "round_time_limit": round_time_limit, "sudden_death_power_multiplier": sudden_death_power_multiplier}

func commander_skill_uses_remaining() -> int:
    return maxi(0, COMMANDER_SKILL_USES_PER_MATCH - commander_skill_uses)

func is_phase_complete() -> bool:
    return selection_points <= 0

func _apply_unit(card_id: String) -> bool:
    if not card_definitions.has(card_id):
        return false
    var card: Dictionary = card_definitions[card_id]
    var current: int = get_unit_count(card_id)
    var cap: int = int(card.get("unit_cap", 0))
    var summon_amount: int = int(card.get("summon_amount", 0))
    if current >= cap or summon_amount <= 0:
        return false
    unit_counts[card_id] = mini(cap, current + summon_amount)
    return true

func _apply_buff(buff_id: String) -> bool:
    if not buff_definitions.has(buff_id):
        return false
    var buff: Dictionary = buff_definitions[buff_id]
    var current: int = get_buff_stacks(buff_id)
    var max_stacks: int = int(buff.get("max_stacks", 0))
    if max_stacks > 0 and current >= max_stacks:
        return false
    buff_stacks[buff_id] = current + 1
    if sudden_death:
        sudden_death_buff_stacks[buff_id] = int(sudden_death_buff_stacks.get(buff_id, 0)) + 1
    return true

func _eligible_unit_ids() -> Array[String]:
    var result: Array[String] = []
    for card_id in loadout_card_ids:
        if not card_definitions.has(card_id):
            continue
        var card: Dictionary = card_definitions[card_id]
        if get_unit_count(card_id) < int(card.get("unit_cap", 0)):
            result.append(card_id)
    return result

func _eligible_buff_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in buff_definitions.keys():
        var buff_id := str(raw_id)
        var buff: Dictionary = buff_definitions[buff_id]
        if int(buff.get("max_stacks", 0)) == 0 or get_buff_stacks(buff_id) < int(buff.get("max_stacks", 0)):
            result.append(buff_id)
    result.sort()
    return result

func _make_options(ids: Array[String], option_type: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for option_id in ids:
        result.append({"type": option_type, "id": option_id})
    return result

func _take_random(values: Array[String], count: int) -> Array[String]:
    var shuffled: Array[String] = values.duplicate()
    for i in range(shuffled.size() - 1, 0, -1):
        var j: int = _rng.randi_range(0, i)
        var temp: String = shuffled[i]
        shuffled[i] = shuffled[j]
        shuffled[j] = temp
    var result: Array[String] = []
    for i in range(mini(count, shuffled.size())):
        result.append(shuffled[i])
    return result

func _shuffle_options(values: Array[Dictionary]) -> void:
    for i in range(values.size() - 1, 0, -1):
        var j: int = _rng.randi_range(0, i)
        var temp: Dictionary = values[i]
        values[i] = values[j]
        values[j] = temp
