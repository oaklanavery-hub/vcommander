class_name BattleReport
extends RefCounted

# Aggregation consumes completed immutable replay evidence, never combat rules.
static func build(result: Dictionary) -> Dictionary:
    var duration := maxf(0, float(result.get("duration", 0)))
    var bodies := {}
    var rows := {}
    var events: Array = result.get("events", [])
    for event in events:
        if event.get("type") == "spawn" and event.has("unit"):
            _register(bodies, rows, event["unit"], float(event.get("time", 0)), str(event.get("source", "")).is_empty())
    for frame in result.get("frames", []):
        for unit in frame.get("units", []):
            _register(bodies, rows, unit, float(unit.get("spawned_at", frame.get("time", 0))), not bool(unit.get("summoned", false)))
    var last_hit := {}
    for event in events:
        var type := str(event.get("type", ""))
        var target_id := str(event.get("target_id", ""))
        var target: Dictionary = bodies.get(target_id, {})
        var source_id := str(event.get("source_unit_id", event.get("unit_id", "")))
        var source: Dictionary = bodies.get(source_id, {})
        var source_side := str(event.get("source_side", source.get("side", event.get("side", ""))))
        var source_key := str(source.get("key", ""))
        if source_key.is_empty() and source_side in ["player", "opponent"] and type in ["damage", "commander_skill"]:
            source_key = _effect_row(rows, source_side, type == "commander_skill" or str(event.get("source", "")).begins_with("commander_skill"))
        if type == "damage" and not target.is_empty():
            var amount := maxf(0, float(event.get("hp_loss", minf(float(event.get("amount", 0)), maxf(0, float(event.get("hp_after", 0)) + float(event.get("amount", 0)))))))
            rows[target["key"]]["taken"] += amount
            rows[target["key"]]["absorbed"] += maxf(0, float(event.get("absorbed", 0)))
            if rows.has(source_key) and source_side != target["side"]:
                rows[source_key]["damage"] += amount
                if amount > 0:
                    last_hit[target_id] = source_key
        elif type == "heal" and not source.is_empty() and not target.is_empty() and source["side"] == target["side"]:
            rows[source_key]["healing"] += maxf(0, float(event.get("effective_healing", event.get("amount", 0))))
        elif type == "defeat":
            var id := str(event.get("unit_id", ""))
            if bodies.has(id) and not bodies[id].has("died_at"):
                bodies[id]["died_at"] = float(event.get("time", duration))
                if last_hit.has(id):
                    rows[last_hit[id]]["kills"] += 1
        elif type == "ability" and not source.is_empty():
            rows[source_key]["abilities"] += 1
        elif type == "commander_skill" and rows.has(source_key):
            rows[source_key]["abilities"] += 1
    for body in bodies.values():
        var row: Dictionary = rows[body["key"]]
        row["active_seconds"] += maxf(0, minf(duration, float(body.get("died_at", duration))) - float(body["born_at"]))
        if not body.has("died_at"):
            row["survived"] += 1
    var report := {"duration": duration, "winner": result.get("winner", "draw"), "reason": result.get("reason", ""), "sides": {}}
    for side in ["player", "opponent"]:
        var entries: Array[Dictionary] = []
        var totals := {"damage": 0.0, "healing": 0.0, "absorbed": 0.0, "taken": 0.0, "kills": 0, "spawned": 0, "survived": 0}
        for row in rows.values():
            if row["side"] != side:
                continue
            row["protection"] = float(row["taken"]) + float(row["absorbed"])
            row["average_survival"] = float(row["active_seconds"]) / maxi(1, int(row["spawned"]))
            entries.append(row.duplicate(true))
            for metric in totals:
                totals[metric] += row[metric]
        entries.sort_custom(func(a: Dictionary, b: Dictionary): return str(a["card_id"]) < str(b["card_id"]))
        var highlights := {}
        for metric in ["damage", "healing", "protection"]:
            var best: Dictionary = {}
            for row in entries:
                if float(row[metric]) > float(best.get("value", 0)):
                    best = {"card_id": row["card_id"], "name": row["name"], "value": row[metric]}
            highlights[metric] = best
        report["sides"][side] = {"rows": entries, "totals": totals, "highlights": highlights, "recap": recap(result, side)}
    return report

static func recap(result: Dictionary, side: String) -> Dictionary:
    var facts: Array[String] = []
    var suggestion := "Compare your recruit and power choices with the rival's report before the next draft."
    var events: Array = result.get("events", [])
    var living := {}
    var identities := {}
    var had_frontline := false
    var opening_bodies := 0
    var created := 0
    var lost_frontline := -1.0
    var remaining_backline := 0
    var incoming := 0.0
    var linked := 0.0
    var commander := 0.0
    var index := 0
    while index < events.size():
        var time := float(events[index].get("time", 0))
        # Deaths, revivals and splits at the same simulation time are one fact.
        while index < events.size() and absf(float(events[index].get("time", 0)) - time) < 0.00001:
            var event: Dictionary = events[index]
            if event.get("type") == "spawn" and event.get("unit") is Dictionary:
                var unit: Dictionary = event["unit"]
                var id := str(unit.get("id", ""))
                identities[id] = unit
                if unit.get("side") == side:
                    living[id] = unit
                    if time <= 0.00001 and str(event.get("source", "")).is_empty() and not bool(unit.get("summoned", false)):
                        opening_bodies += 1
                        had_frontline = had_frontline or _frontline(unit)
                    if event.get("source") in ["death_split", "revival"]:
                        created += 1
            elif event.get("type") == "defeat":
                living.erase(str(event.get("unit_id", "")))
            elif event.get("type") == "damage":
                var target: Dictionary = identities.get(str(event.get("target_id", "")), {})
                if target.get("side") == side and event.get("source_side") != side:
                    var amount := maxf(0, float(event.get("hp_loss", 0)))
                    incoming += amount
                    if event.get("source") == "sticky_share":
                        linked += amount
                    if str(event.get("source", "")).begins_with("commander_skill"):
                        commander += amount
            index += 1
        var front := 0
        var back := 0
        for unit in living.values():
            if _frontline(unit):
                front += 1
            elif str(unit.get("role", "")) in ["range", "healer"] and not bool(unit.get("summoned", false)):
                back += 1
        if had_frontline and front == 0 and back > 0 and lost_frontline < 0:
            lost_frontline = time
            remaining_backline = back
    if lost_frontline >= 0:
        facts.append("Frontline gone at %.1fs; %d ranged/support bodies remained." % [lost_frontline, remaining_backline])
        suggestion = "Reinforce the frontline or add sustain before another army-wide power."
    elif opening_bodies > 0 and not had_frontline:
        facts.append("No frontline bodies were present at the opening.")
        suggestion = "Consider an early frontline recruit to give ranged and healing units time to act."
    if incoming > 0 and linked / incoming >= 0.2:
        facts.append("Linked hits caused %.0f%% of incoming HP loss." % (linked * 100.0 / incoming))
        if lost_frontline < 0:
            suggestion = "Try removing the enemy link support sooner, or compare a tougher opening frontline."
    elif incoming > 0 and commander / incoming >= 0.5:
        facts.append("Commander opening damage caused %.0f%% of incoming HP loss." % (commander * 100.0 / incoming))
    if result.get("reason") == "timer":
        facts.append("Both armies still had living units at the %.0fs limit." % float(result.get("duration", 0)))
        if lost_frontline < 0:
            suggestion = "Compare attack growth against healing and defence; stronger damage may help break a repeated draw."
    elif created > 0 and facts.size() < 2:
        facts.append("Splits and revivals created %d extra allied bodies." % created)
    if facts.is_empty() and opening_bodies > 0:
        facts.append("The fight resolved in %.1fs." % float(result.get("duration", 0)))
    return {"facts": facts.slice(0, 2), "suggestion": suggestion if not facts.is_empty() else ""}

static func _frontline(unit: Dictionary) -> bool:
    return str(unit.get("role", "")) in ["tank", "melee"] and str(unit.get("ability_type", "")) != "backline_transit" and not bool(unit.get("summoned", false))

static func _register(bodies: Dictionary, rows: Dictionary, unit: Dictionary, born_at: float, initial: bool) -> void:
    var id := str(unit.get("id", ""))
    var side := str(unit.get("side", ""))
    if id.is_empty() or bodies.has(id) or side not in ["player", "opponent"]:
        return
    var card_id := str(unit.get("card_id", ""))
    if card_id.is_empty():
        return
    var key := side + ":" + card_id
    if not rows.has(key):
        rows[key] = _row(side, card_id, str(unit.get("name", card_id)), str(unit.get("role", "")), str(unit.get("element", "")))
        rows[key]["summoned"] = bool(unit.get("summoned", false))
    rows[key]["spawned"] += 1
    if initial and not bool(unit.get("summoned", false)):
        rows[key]["initial"] += 1
    bodies[id] = {"key": key, "side": side, "born_at": maxf(0, born_at)}

static func _effect_row(rows: Dictionary, side: String, commander: bool) -> String:
    var card_id := "@commander" if commander else "@effects"
    var key := side + ":" + card_id
    if not rows.has(key):
        rows[key] = _row(side, card_id, "Commander skill" if commander else "Other effects", "commander" if commander else "effect", "")
    return key

static func _row(side: String, card_id: String, name: String, role: String, element: String) -> Dictionary:
    return {"side": side, "card_id": card_id, "name": name, "role": role, "element": element, "summoned": false,
        "damage": 0.0, "healing": 0.0, "absorbed": 0.0, "taken": 0.0, "kills": 0, "abilities": 0,
        "initial": 0, "spawned": 0, "survived": 0, "active_seconds": 0.0}
