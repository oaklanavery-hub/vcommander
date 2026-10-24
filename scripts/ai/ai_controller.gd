class_name AiController
extends RefCounted

const DraftScript = preload("res://scripts/draft/draft_system.gd")
const SetChecker = preload("res://scripts/commanders/set_bonus_checker.gd")

var commander: Dictionary = {}
var cards: Array[Dictionary] = []
var signature_set: Dictionary = {}
var draft = DraftScript.new()
var _rng := RandomNumberGenerator.new()
var _stat_caps: Dictionary = {"attack_speed": 200, "movement_speed": 200}
const STYLE_NAMES := {"swarm": "Swarm", "sustain": "Sustain", "burst": "Burst", "flank": "Backline pressure"}
var difficulty := "standard"
var style := "swarm"
var _public_enemy: Dictionary = {}
var _unit_upgrades: Array[Dictionary] = []

# Only previous-round public enemy information crosses this boundary.
func configure(commanders: Array, all_cards: Array, sets: Dictionary, buffs: Array, seed_value: int, stat_rules: Dictionary = {}, preferences: Dictionary = {}) -> bool:
    _rng.seed = seed_value
    _unit_upgrades.assign(preferences.get("unit_upgrades", []).duplicate(true))
    difficulty = str(preferences.get("difficulty", "standard"))
    if difficulty not in ["casual", "standard", "veteran"]:
        difficulty = "standard"
    style = str(STYLE_NAMES.keys()[_rng.randi_range(0, STYLE_NAMES.size() - 1)])
    _public_enemy.clear()
    for stat in ["attack_speed", "movement_speed"]:
        _stat_caps[stat] = float(stat_rules.get(stat + "_cap", 200))
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
        var preferred: Array = available.filter(func(card): return _style_weight(card) > 1.0)
        if not preferred.is_empty() and _rng.randf() < 0.75:
            available = preferred
        cards.append(available[_rng.randi_range(0, available.size() - 1)].duplicate(true))
    var ids: Array[String] = []
    for card in cards:
        ids.append(str(card["id"]))
    var draft_options := preferences.duplicate(true)
    draft_options["commander_id"] = str(commander.get("id", ""))
    draft.configure(ids, cards, buffs, seed_value + 7919, draft_options)
    return true

func _has_card(card_id: String) -> bool:
    for card in cards:
        if str(card.get("id", "")) == card_id:
            return true
    return false

func begin_round(opening: bool, lost_previous: bool, sudden: bool, public_enemy: Dictionary, losses: int = 0) -> bool:
    _public_enemy.clear()
    # Whitelist prior-round public evidence. Hidden/current selections and battle
    # results cannot cross this boundary, even if a caller supplies extra fields.
    for key in ["cards", "unit_counts", "buffs", "set_bonus"]:
        if public_enemy.has(key):
            _public_enemy[key] = public_enemy[key].duplicate(true)
    draft.begin_round(opening, lost_previous, sudden)
    var guard := 0
    while not draft.is_phase_complete() and guard < 8:
        guard += 1
        var branch := _preferred_specialization()
        if not branch.is_empty() and draft.choose_specialization(branch):
            continue
        if _should_use_skill(public_enemy, losses):
            if not draft.use_commander_skill():
                return false
        else:
            var best_index := -1
            var best_score := -INF
            for index in range(draft.current_offer.size()):
                var base := score_option(draft.current_offer[index])
                var uncertainty := 0.45 if difficulty == "casual" else (0.01 if difficulty == "veteran" else 0.08)
                var score := base * _rng.randf_range(1.0 - uncertainty, 1.0 + uncertainty)
                if score > best_score:
                    best_score = score
                    best_index = index
            if draft.can_redraw() and (best_score <= 0 or _missing_frontline_offer()):
                draft.redraw()
                guard -= 1
                continue
            if not draft.select_offer(best_index):
                return false
    return draft.is_phase_complete()

func _preferred_specialization() -> String:
    if not draft.can_specialize():
        return ""
    var best := ""
    var value := 0
    # Only the AI's own recruited bodies and legal techniques inform this choice.
    for id in draft.specialization_options:
        if not draft.can_specialize(str(id)):
            continue
        var affected := CommanderSpecializations.affected(cards, draft.unit_counts, draft.specialization_options[id])
        if int(affected["units"]) > value:
            value = int(affected["units"])
            best = str(id)
    return best

func _missing_frontline_offer() -> bool:
    if draft.round_number < 2:
        return false
    var can_recruit_tank := false
    for card in cards:
        if card.get("role") == "tank":
            if draft.get_unit_count(str(card["id"])) > 0:
                return false
            can_recruit_tank = true
    for option in draft.current_offer:
        if option.get("type") == "unit" and draft.card_definitions.get(str(option.get("id", "")), {}).get("role") == "tank":
            return false
    return can_recruit_tank

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
        var ability: Dictionary = card.get("ability", {})
        if ability.get("type") in ["area_heal", "aura_heal"] and draft.get_unit_count(option_id) == 0 and _unit_total() >= 4:
            # First support unit gains value as more allies can benefit.
            var heal_pct := float(ability.get("heal_target_max_hp_pct", ability.get("heal_ally_max_hp_pct", 0)))
            score += float(_unit_total()) * heal_pct * 3.0
        return score * _style_weight(card) * _counter_weight(card)
    var buff: Dictionary = draft.buff_definitions.get(option_id, {})
    var side := get_side()
    var percentage := WarbandStats.power_percentage(side, buff)
    var value := percentage * float(_unit_total()) * 0.65
    if str(buff.get("stat", "")) in ["health", "attack"]:
        value *= 1.2
    var growth: String = str(buff.get("stat", ""))
    if style == "sustain" and growth in ["health", "defense"]:
        value *= 1.35
    elif style == "burst" and growth == "attack":
        value *= 1.4
    elif style == "flank" and growth in ["attack", "movement_speed"]:
        value *= 1.2
    elif style == "swarm":
        value *= 0.85
    if difficulty != "casual":
        var threat := _enemy_profile()
        if growth == "attack" and float(threat["defense"]) > 0:
            value *= 1.0 + minf(0.6, float(threat["defense"]) / 25.0) * (1.0 if difficulty == "veteran" else 0.6)
        if growth == "attack_speed" and float(threat["healers"]) > 0:
            value *= 1.2
    var stat := str(buff.get("stat", ""))
    if _stat_caps.has(stat):
        # Unlimited speed cards remain legal, but an already-capped army gets
        # no benefit from them. Prefer useful growth when the offer permits it.
        var weighted_gain := 0.0
        var total := 0
        var multiplier := 1 + percentage / 100.0
        for card in cards:
            var count := draft.get_unit_count(str(card["id"]))
            var cap := float(_stat_caps[stat])
            var current := WarbandStats.effective(int(card.get("stats", {}).get(stat, 100)), stat, side, _stat_caps)
            if current >= cap - 0.0001:
                current = cap
            weighted_gain += float(count) * (minf(cap, current * multiplier) - current) / maxf(0.001, current * (multiplier - 1))
            total += count
        value *= weighted_gain / float(maxi(1, total))
    return value

func _style_weight(card: Dictionary) -> float:
    var ability := str(card.get("ability", {}).get("type", ""))
    match style:
        "swarm":
            return 1.25 if int(card.get("summon_amount", 1)) >= 2 or ability == "death_split" else 1.0
        "sustain":
            return 1.35 if ability in ["area_heal", "aura_heal", "absorb_burst"] else 1.0
        "burst":
            return 1.3 if ability in ["ranged_aoe", "empowered_attack", "explosion", "absorb_burst"] else 1.0
        "flank":
            return 1.4 if ability in ["backline_transit", "pull_then_melee", "damage_link"] else 1.0
    return 1.0

func _enemy_profile() -> Dictionary:
    var threat := {"total": 0.0, "backline": 0.0, "healers": 0.0, "defense": 0.0}
    for card in _public_enemy.get("cards", []):
        var count := float(_public_enemy.get("unit_counts", {}).get(str(card.get("id", "")), 0))
        threat["total"] += count
        if str(card.get("role", "")) in ["range", "healer"]:
            threat["backline"] += count
        if str(card.get("ability", {}).get("type", "")) in ["area_heal", "aura_heal"]:
            threat["healers"] += count
        threat["defense"] += count * WarbandStats.effective(int(card.get("stats", {}).get("defense", 0)), "defense", _public_enemy, _stat_caps)
    if float(threat["total"]) > 0:
        threat["backline"] /= float(threat["total"])
        threat["healers"] /= float(threat["total"])
        threat["defense"] /= float(threat["total"])
    return threat

func _counter_weight(card: Dictionary) -> float:
    if difficulty == "casual":
        return 1.0
    var threat := _enemy_profile()
    var amount := 0.0
    var ability := str(card.get("ability", {}).get("type", ""))
    if ability in ["ranged_aoe", "ranged_aoe_dot", "aura_damage", "explosion", "death_damage_area", "absorb_burst", "damage_link"]:
        amount += minf(0.65, float(threat["total"]) / 24.0)
    if ability == "backline_transit":
        amount += float(threat["backline"]) * 0.8 + float(threat["healers"]) * 0.6
    if ability == "empowered_attack":
        amount += minf(0.5, float(threat["defense"]) / 30.0)
    return 1.0 + amount * (1.0 if difficulty == "veteran" else 0.6)

func _unit_total() -> int:
    var result := 0
    for count in draft.unit_counts.values():
        result += int(count)
    return result

func get_side(skill_active: bool = false) -> Dictionary:
    var bonus: Dictionary = {}
    if SetChecker.is_complete(cards, str(signature_set.get("id", "")), int(signature_set.get("required_count", 4))):
        bonus = signature_set.get("bonus", {}).duplicate(true)
    var buffs: Array[Dictionary] = draft.get_buff_states()
    return {
        "id": "opponent", "commander": commander.duplicate(true),
        "cards": cards.duplicate(true), "unit_counts": draft.unit_counts.duplicate(true),
        "buffs": buffs, "set_bonus": bonus,
        "commander_skill_active": skill_active,
        "skill_uses_remaining": draft.commander_skill_uses_remaining(),
        "specialization": draft.specialization(),
        "ai_plan": {"style": style, "name": str(STYLE_NAMES.get(style, "Balanced")), "difficulty": difficulty}
    }.merged(draft.round_context()).merged({} if _unit_upgrades.is_empty() else {"unit_upgrades": _unit_upgrades.duplicate(true)})
