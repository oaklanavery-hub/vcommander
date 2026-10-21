class_name DraftSystem
extends RefCounted

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
var current_offer: Array[Dictionary] = []

var selection_points := 0
var round_number := 0
var opening_phase := true
var sudden_death := false
var commander_skill_uses := 0
var commander_skill_used_this_round := false
var seed := 1

var _rng := RandomNumberGenerator.new()

func configure(card_ids: Array, cards: Array, buffs: Array, match_seed: int) -> void:
    loadout_card_ids.clear()
    card_definitions.clear()
    buff_definitions.clear()
    unit_counts.clear()
    buff_stacks.clear()
    current_offer.clear()
    commander_skill_uses = 0
    round_number = 0

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

    seed = match_seed
    _rng.seed = match_seed

func begin_round(is_opening: bool, lost_previous_round: bool, is_sudden_death: bool = false) -> void:
    round_number += 1
    opening_phase = is_opening
    sudden_death = is_sudden_death
    commander_skill_used_this_round = false
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
    return true

func get_unit_count(card_id: String) -> int:
    return int(unit_counts.get(card_id, 0))

func get_buff_stacks(buff_id: String) -> int:
    return int(buff_stacks.get(buff_id, 0))

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
