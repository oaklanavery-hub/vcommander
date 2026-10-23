class_name WarbandGuide
extends RefCounted
## Read-only relationships, never a combat score or a source of bonuses.

static func catalog() -> Dictionary:
    var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation/warband_guide.json"))
    return value if value is Dictionary else {}

static func analyze(cards: Array, signature: Dictionary) -> Dictionary:
    var data := catalog()
    var tags := {}
    var seen := {}
    for card in cards:
        var id := str(card.get("id", ""))
        if id.is_empty() or seen.has(id):
            continue
        seen[id] = true
        var ability: Dictionary = card.get("ability", {})
        var card_tags: Array = data.get("roles", {}).get(str(card.get("role", "")), []).duplicate()
        if ability.get("type") == "backline_transit":
            card_tags.erase("frontline")
        card_tags.append_array(data.get("abilities", {}).get(str(ability.get("type", "")), {}).get("tags", []))
        for tag in card_tags:
            if not tags.has(tag):
                tags[tag] = []
            var display := str(card.get("display_name", id))
            if not tags[tag].has(display):
                tags[tag].append(display)
    var matched := SetBonusChecker.progress(cards, str(signature.get("id", "")))
    var active := SetBonusChecker.is_complete(cards, str(signature.get("id", "")), int(signature.get("required_count", 4)))
    var bonus: Dictionary = signature.get("bonus", {})
    var description := str(bonus.get("description", ""))
    if description.is_empty():
        description = "+%s%% %s" % [str(bonus.get("percentage", 0)).trim_suffix(".0"), str(bonus.get("stat", "")).replace("_", " ").to_upper()]
    var theme := "Theme active: " + description if active else "Theme inactive (%d / 4): %s. Mixed armies are legal; this bonus needs four matching cards." % [matched, description]
    var notes: Array[Dictionary] = []
    for relationship in data.get("relationships", []):
        var applicable := true
        var text: String = relationship["text"]
        for tag in relationship["requires"]:
            if not tags.has(tag):
                applicable = false
                break
            text = text.replace("{" + tag + "}", ", ".join(tags[tag]))
        if applicable:
            notes.append({"id": relationship["id"], "title": relationship["title"], "text": text})
    if tags.has("death_spawn") and bonus.get("trigger") == "on_death_spawn":
        notes.append({"id": "theme_spawn", "title": "Death-spawn theme", "text": "%s creates death-spawn bodies. %s" % [", ".join(tags["death_spawn"]), "The active theme increases qualifying new bodies' attack." if active else "Complete the commander theme to give qualifying new bodies its attack bonus."]})
    var frontline := ", ".join(tags.get("frontline", []))
    if frontline.is_empty():
        frontline = "No conventional frontline selected. Flankers travel away from the opening screen."
    return {"theme_active": active, "theme_matches": matched, "theme": theme, "tags": tags, "frontline": frontline, "notes": notes}

static func glossary(filter_text: String = "") -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    var abilities: Dictionary = catalog().get("abilities", {})
    var keys := abilities.keys()
    keys.sort_custom(func(a, b): return str(abilities[a]["name"]) < str(abilities[b]["name"]))
    for key in keys:
        var value: Dictionary = abilities[key]
        if filter_text.is_empty() or (str(value["name"]) + " " + str(value["explanation"])).to_lower().contains(filter_text.to_lower()):
            entries.append(value.duplicate(true))
    return entries
