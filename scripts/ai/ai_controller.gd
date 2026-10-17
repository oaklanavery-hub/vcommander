class_name AiController
extends RefCounted

const DraftScript = preload("res://scripts/draft/draft_system.gd")
const SetChecker = preload("res://scripts/commanders/set_bonus_checker.gd")

var commander: Dictionary = {}
var cards: Array[Dictionary] = []
var signature_set: Dictionary = {}
var draft = DraftScript.new()
var _rng := RandomNumberGenerator.new()

# Only previous-round public enemy information crosses this boundary.
func configure(commanders: Array, all_cards: Array, sets: Dictionary, buffs: Array, seed_value: int) -> bool:
    _rng.seed = seed_value
    commander.clear()
    cards.clear()
    var candidates: Array = commanders.duplicate()
    candidates.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
    if candidates.is_empty() or all_cards.size() < 4:
        return false
    commander = candidates[_rng.randi_range(0, candidates.size() - 1)].duplicate(true)
    signature_set = sets.get(str(commander.get("signature_set_id", "")), {}).duplicate(true)
    var pool: Array = all_cards.duplicate()
    pool.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
    var themed: Array = pool.filter(func(card): return card.get("set_id") == signature_set.get("id"))
    # Prefer a full theme; occasionally field a legal mixed-element army.
    if themed.size() >= 4 and _rng.randf() < 0.75:
        pool = themed
    for desired_role in ["tank", "melee", "range", "healer"]:
        var available: Array = pool.filter(func(card): return not _has_card(str(card.get("id", ""))))
        var matching: Array = available.filter(func(card): return card.get("role") == desired_role)
        if not matching.is_empty():
            available = matching
        if available.is_empty():
            return false
        cards.append(available[_rng.randi_range(0, available.size() - 1)].duplicate(true))
    var ids: Array[String] = []
    for card in cards:
        ids.append(str(card["id"]))
    draft.configure(ids, cards, buffs, seed_value + 7919)
    return true

func _has_card(card_id: String) -> bool:
    for card in cards:
        if str(card.get("id", "")) == card_id:
            return true
    return false

func begin_round(opening: bool, lost_previous: bool, sudden: bool, public_enemy: Dictionary, losses: int = 0) -> bool:
    draft.begin_round(opening, lost_previous, sudden)
    var guard := 0
    while not draft.is_phase_complete() and guard < 8:
        guard += 1
        if _should_use_skill(public_enemy, losses):
            if not draft.use_commander_skill():
                return false
        else:
            var best_index := -1
            var best_score := -INF
            for index in range(draft.current_offer.size()):
                var score := score_option(draft.current_offer[index]) + _rng.randf_range(0.0, 0.05)
                if score > best_score:
                    best_score = score
                    best_index = index
            if not draft.select_offer(best_index):
                return false
    return draft.is_phase_complete()

func _should_use_skill(public_enemy: Dictionary, losses: int) -> bool:
    if draft.commander_skill_uses_remaining() <= 0 or draft.commander_skill_used_this_round:
        return false
    if draft.round_number < 3 and losses < 3:
        return false
    var enemy_total := 0
    for count in public_enemy.get("unit_counts", {}).values():
        enemy_total += int(count)
    # Never spend the opening army away or react to a hidden current pick.
    return enemy_total > 0 and _unit_total() > 0 and (losses >= 3 or draft.round_number % 2 == 1)

func score_option(option: Dictionary) -> float:
    var option_id := str(option.get("id", ""))
    if option.get("type") == "unit":
        var card: Dictionary = draft.card_definitions.get(option_id, {})
        var stats: Dictionary = card.get("stats", {})
        var gain := mini(int(card.get("summon_amount", 0)), int(card.get("unit_cap", 0)) - draft.get_unit_count(option_id))
        var score := float(gain) * (float(stats.get("health", 0)) / 35.0 + float(stats.get("attack", 0)) / 4.0 + float(stats.get("defense", 0)) / 4.0)
        var role := str(card.get("role", ""))
        var role_total := 0
        for owned in cards:
            if str(owned.get("role", "")) == role:
                role_total += draft.get_unit_count(str(owned["id"]))
        if role_total == 0:
            score *= 1.7 if role == "tank" else 1.25
        return score
    var buff: Dictionary = draft.buff_definitions.get(option_id, {})
    var value := float(buff.get("percentage", 0)) * float(_unit_total()) * 0.65
    if str(buff.get("stat", "")) in ["health", "attack"]:
        value *= 1.2
    return value

func _unit_total() -> int:
    var result := 0
    for count in draft.unit_counts.values():
        result += int(count)
    return result

func get_side(skill_active: bool = false) -> Dictionary:
    var bonus: Dictionary = {}
    if SetChecker.is_complete(cards, str(signature_set.get("id", "")), int(signature_set.get("required_count", 4))):
        bonus = signature_set.get("bonus", {}).duplicate(true)
    var buffs: Array[Dictionary] = []
    for buff_id in draft.buff_definitions:
        var stacks: int = draft.get_buff_stacks(str(buff_id))
        if stacks > 0:
            buffs.append({"definition": draft.buff_definitions[buff_id].duplicate(true), "stacks": stacks})
    return {
        "id": "opponent", "commander": commander.duplicate(true),
        "cards": cards.duplicate(true), "unit_counts": draft.unit_counts.duplicate(true),
        "buffs": buffs, "set_bonus": bonus,
        "commander_skill_active": skill_active,
        "skill_uses_remaining": draft.commander_skill_uses_remaining()
    }
