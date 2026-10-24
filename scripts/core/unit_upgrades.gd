class_name UnitUpgrades
extends RefCounted
## Pure, content-defined Lv. 2 transformations; no profile, UI or autoload reads.

static func definitions(catalog: Dictionary, ids: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for id in ids:
        var entry: Dictionary = catalog.get("units", {}).get(str(id), {})
        if not entry.is_empty():
            var definition := entry.duplicate(true)
            definition["unit_id"] = str(id)
            result.append(definition)
    return result

static func changed_card(card: Dictionary, definition: Dictionary) -> Dictionary:
    if definition.is_empty() or int(card.get("unit_level", 1)) >= 2:
        return card.duplicate(true)
    var result := card.duplicate(true)
    result["unit_level"] = 2
    result["upgrade_name"] = str(definition.get("name", "Lv. 2"))
    result["upgrade_description"] = str(definition.get("description", ""))
    result["upgrade_traits"] = definition.get("traits", []).duplicate(true)
    result["upgrade_visual"] = definition.get("visual", {}).duplicate(true)
    result["ability"] = result.get("ability", {}).duplicate(true)
    result["ability"].merge(definition.get("ability_overrides", {}), true)
    result["ability"]["description"] = str(result["ability"].get("description", "")) + "\nLv. 2: " + str(definition.get("description", ""))
    return result

static func apply_side(side: Dictionary) -> Dictionary:
    if side.get("unit_upgrades", []).is_empty():
        return side
    var result := side.duplicate(true)
    for index in range(result.get("cards", []).size()):
        var card: Dictionary = result["cards"][index]
        for definition in result["unit_upgrades"]:
            if definition.get("unit_id") == card.get("id"):
                result["cards"][index] = changed_card(card, definition)
                break
    return result

static func get_trait(unit: Dictionary, kind: String) -> Dictionary:
    for entry in unit.get("upgrade_traits", []):
        if entry.get("type") == kind:
            return entry
    return {}
