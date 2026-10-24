class_name UnitInspection
extends RefCounted

static func describe(unit: Dictionary, card: Dictionary, clock: float, frozen: bool = false) -> Dictionary:
    if unit.is_empty():
        return {}
    var ability: Dictionary = card.get("ability", {"type": unit.get("ability_type", "")})
    var type := str(unit.get("ability_type", ability.get("type", "")))
    var remaining := maxf(0, float(unit.get("ability_cooldown", 0)) - maxf(0, clock - float(unit.get("sample_time", clock))))
    var last: Dictionary = unit.get("last_ability", {})
    if not last.is_empty() and float(last.get("time", 0)) > float(unit.get("sample_time", 0)):
        remaining = maxf(0, float(last["time"]) + float(unit.get("ability_cooldown_seconds", ability.get("cooldown_seconds", 5))) - clock)
    var cooldown := "Passive ability"
    if type in ["backline_transit", "damage_link", "pull_then_melee"]:
        cooldown = "Ready" if remaining <= 0.001 else "Ready in %.1fs" % remaining
    elif type == "absorb_burst":
        var burst_at := float(unit.get("next_burst_at", clock))
        if last.get("kind") == "absorb_burst" and float(last.get("time", 0)) >= float(unit.get("sample_time", 0)):
            burst_at = float(last["time"]) + float(unit.get("burst_seconds", ability.get("burst_seconds", 10)))
        cooldown = "Burst in %.1fs" % maxf(0, burst_at - clock)
    elif type in ["explosion", "death_split", "death_damage_area"]:
        cooldown = "Triggers on death"
    elif not type.begins_with("aura_"):
        var attack_in := maxf(0, float(unit.get("attack_ready_at", clock)) - clock)
        cooldown = "Attack ready" if attack_in <= 0.001 else "Next attack in %.1fs" % attack_in
    var effects: Array[String] = []
    if bool(unit.get("rooted", false)) and clock < float(unit.get("root_until", INF)):
        effects.append("Rooted")
    if frozen:
        effects.append("Frozen Field · this round")
    if bool(unit.get("burning", false)):
        effects.append("Damage over time")
    if bool(unit.get("slowed", false)):
        effects.append("Slowed")
    if bool(unit.get("aura_slowed", false)):
        effects.append("Freezing aura · attack speed reduced")
    var mark: Dictionary = unit.get("sticky_mark", {})
    if not mark.is_empty():
        effects.append("Sticky link · %s%% shared damage" % number(float(mark.get("shared_damage_pct", 0))) if mark.get("target_ids", []).size() > 1 else "Sticky mark")
    if bool(unit.get("revival_ready", false)):
        effects.append("Revival ready")
    var transit: Dictionary = unit.get("transit", {})
    if not transit.is_empty():
        effects.append("Travelling · invulnerable" if transit.get("invulnerable", false) else "Travelling underground")
    if type == "absorb_burst":
        effects.append("Stored damage: " + number(float(unit.get("absorbed_damage", 0))))
    var description := ("Base ability: " + ability_text(ability) + "\nPath changes: " + str(unit["specialization_description"])) if unit.has("specialization_description") else ability_text(ability)
    var upgrade_text := str(unit.get("upgrade_description", ""))
    if not upgrade_text.is_empty() and not description.contains(upgrade_text):
        description += "\nLv. 2: " + upgrade_text
    return {"id": unit.get("id", ""), "card_id": unit.get("card_id", ""), "name": str(unit.get("name", card.get("display_name", "Unit"))) + (" · Lv. 2" if int(unit.get("unit_level", 1)) >= 2 else ""),
        "role": unit.get("role", card.get("role", "")), "hp": maxf(0, float(unit.get("hp", 0))), "max_hp": unit.get("max_hp", 1),
        "attack": unit.get("attack", 0), "defense": unit.get("defense", 0), "attack_speed": unit.get("attack_speed", 0),
        "movement_speed": unit.get("movement_speed", 0), "range": unit.get("range", 1),
        "ability": unit.get("ability_name", ability.get("display_name", "Attack")), "description": description,
        "cooldown": cooldown, "effects": effects, "element": unit.get("element", ""), "side": unit.get("side", "")}

static func ability_text(ability: Dictionary) -> String:
    var description := str(ability.get("description", ""))
    if not description.is_empty():
        return description
    match str(ability.get("type", "")):
        "aura_damage": return "Damages nearby enemies while they remain in its aura."
        "aura_heal": return "Restores nearby allies' HP while they remain in its aura."
        "aura_debuff": return "Slows nearby enemy attacks while they remain in its aura."
        "explosion": return "Explodes on death, damaging and pushing nearby enemies and leaving a burn."
        "ranged_aoe": return "Ranged attacks also damage enemies near the impact."
        "area_heal": return "Places a healing area for injured allies."
        "empowered_attack": return "Every %d attacks, strikes for %s%% attack damage." % [int(ability.get("every_n_attacks", 3)), number(float(ability.get("attack_pct", 150)))]
        "death_split": return "Splits into smaller allied bodies on death. Children share this unit's report row."
        "ranged_aoe_slow": return "Slime shots slow enemy attacks and movement around the impact."
        "max_hp_projectile": return "Stationary summon. Seed damage scales with the target's maximum HP."
        "basic_ranged": return "Fires projectiles at enemies within range."
        "basic_melee": return "Attacks enemies within melee reach."
    return "Uses its recorded ability when its conditions are met."

static func number(value: float) -> String:
    if absf(value) < 1000 and not is_equal_approx(value, roundf(value)):
        return "%.1f" % value
    return AssassinEffects.number(value)
