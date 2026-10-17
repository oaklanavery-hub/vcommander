class_name CombatCues
extends RefCounted

static var _catalog: Dictionary = {}

static func catalog() -> Dictionary:
    if _catalog.is_empty():
        var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation/combat_cues.json"))
        if parsed is Dictionary:
            _catalog = parsed
    return _catalog

static func profile(id: String) -> Dictionary:
    var units: Dictionary = catalog().get("units", {})
    if not units.has(id):
        var pieces := id.split(":")
        id = pieces[1] if pieces.size() > 1 else id
    return units.get(id, {"projectile": "magic", "motion": "slash", "attack_sound": "attack", "impact_sound": "magic_hit"})

static func event_profile(event: Dictionary) -> Dictionary:
    var id := str(event.get("card_id", ""))
    if id.is_empty():
        id = str(event.get("source_unit_id", event.get("unit_id", "")))
    return profile(id)

static func sound(event: Dictionary) -> String:
    var type := str(event.get("type", ""))
    var profile := event_profile(event)
    if type == "commander_skill":
        return {"targeted_aoe_max_hp": "fire_cast", "round_debuff": "freeze", "summon_stationary_units": "plant_grow"}.get(str(event.get("skill_type", "")), "commander_skill")
    if type == "ability":
        return {"pull": "vine_pull", "meteor": "meteor", "on_death": "explosion", "area_heal": "healing_water"}.get(str(event.get("kind", "")), "")
    if type == "projectile_impact":
        return str(profile.get("impact_sound", "magic_hit"))
    if type == "attack":
        return str(profile.get("attack_sound", "attack"))
    if type == "damage" and event.get("source") == "normal_attack":
        return str(profile.get("impact_sound", "heavy_hit"))
    if type == "heal":
        return "heal"
    if type == "defeat":
        return "defeat"
    return ""
