class_name CommanderSpecializations
extends RefCounted
## Content-defined, match-only ability transformations. Never changes ownership.

static func options(catalog: Dictionary, commander_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for branch in catalog.get("branches", []):
        if branch.get("commander_id") == commander_id:
            result.append(branch.duplicate(true))
    return result

static func changed_ability(card: Dictionary, branch: Dictionary) -> Dictionary:
    var ability: Dictionary = card.get("ability", {}).duplicate(true)
    var details: Array[String] = []
    for change in branch.get("changes", []):
        if not ability.get("type", "") in change.get("ability_types", []):
            continue
        if change.has("mode") and ability.get("mode") != change["mode"]:
            continue
        var field: String = change["field"]
        if not ability.has(field) or (change.has("previous") and ability[field] != change["previous"]):
            continue
        var before = ability[field]
        var after = change.get("value", before)
        if change.has("factor"):
            after = float(before) * float(change["factor"])
        if before == after:
            continue
        ability[field] = after
        details.append("%s: %s → %s" % [field.replace("_", " "), str(before), str(after)])
    if not details.is_empty():
        ability["specialization_description"] = str(branch.get("display_name", "Specialization")) + " · " + "; ".join(details)
        ability["description"] = "Base ability: " + str(ability.get("description", "")) + "\nPath changes: " + ability["specialization_description"]
    return ability

static func affected(cards: Array, counts: Dictionary, branch: Dictionary) -> Dictionary:
    var result := {"types": [], "units": 0, "details": []}
    for card in cards:
        var ability: Dictionary = card.get("ability", {})
        var changed := changed_ability(card, branch)
        if changed == ability:
            continue
        result["types"].append(str(card.get("display_name", "Companion")))
        result["units"] += int(counts.get(str(card.get("id", "")), 0))
        result["details"].append(str(card.get("display_name", "Companion")) + ": " + str(changed.get("description", "")))
    return result

static func apply_side(side: Dictionary) -> Dictionary:
    var branch: Dictionary = side.get("specialization", {})
    if branch.is_empty():
        return side
    var result := side.duplicate(true)
    for card in result.get("cards", []):
        card["ability"] = changed_ability(card, branch)
    return result
