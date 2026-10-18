class_name BattleReplay
extends RefCounted

# Read-only presentation tracks fill the gaps between the coarse replay frames.
# In particular, a shot may launch AND hit without appearing in any frame.
var shots: Array[Dictionary] = []
var health: Dictionary = {}
var attacks: Dictionary = {}

func configure(frames: Array, events: Array, event_start: int = 0) -> void:
    shots.clear()
    health.clear()
    attacks.clear()
    var by_id := {}
    for event in events.slice(event_start):
        var type := str(event.get("type", ""))
        if type == "projectile_launch":
            var shot: Dictionary = event["projectile"].duplicate(true)
            shot["samples"] = [{"time": float(event["time"]), "x": shot["start_x"], "y": shot["start_y"]}]
            by_id[int(shot["id"])] = shot
        elif type in ["projectile_impact", "projectile_fizzle"]:
            var id := int(event.get("projectile_id", -1))
            if by_id.has(id):
                by_id[id]["terminal"] = event.duplicate(true)
        elif type in ["damage", "heal"] and event.has("hp_after"):
            var id := str(event["target_id"])
            if not health.has(id):
                health[id] = []
            health[id].append({"time": event["time"], "hp": event["hp_after"]})
        elif type == "attack":
            var id := str(event["unit_id"])
            if not attacks.has(id):
                attacks[id] = []
            attacks[id].append(event)
    for frame in frames:
        for projectile in frame.get("projectiles", []):
            var id := int(projectile["id"])
            if not by_id.has(id):
                var shot: Dictionary = projectile.duplicate(true)
                shot["samples"] = [{"time": shot.get("launched_at", frame["time"]), "x": shot.get("start_x", shot["x"]), "y": shot.get("start_y", shot["y"])}]
                by_id[id] = shot
            by_id[id]["samples"].append({"time": frame["time"], "x": projectile["x"], "y": projectile["y"]})
    for shot in by_id.values():
        var terminal: Dictionary = shot.get("terminal", {})
        if not terminal.is_empty():
            shot["samples"].append({"time": terminal["time"], "x": terminal["x"], "y": terminal["y"]})
        shot["samples"].sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
        shots.append(shot)
    shots.sort_custom(func(a, b): return float(a.get("launched_at", 0)) < float(b.get("launched_at", 0)))

func health_at(id: String, clock: float, fallback: float) -> float:
    var records: Array = health.get(id, [])
    var index := _last_at(records, clock)
    return maxf(0, float(records[index]["hp"])) if index >= 0 else fallback

func projectiles_at(clock: float) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for shot in shots:
        if clock < float(shot.get("launched_at", 0)):
            break
        var terminal: Dictionary = shot.get("terminal", {})
        var end := float(terminal.get("time", INF))
        var impact: bool = terminal.get("type") == "projectile_impact"
        # Brief visible contact survives a rendered frame stepping over the hit.
        if clock >= end + (0.12 if impact else 0.0):
            continue
        var samples: Array = shot["samples"]
        var index := maxi(0, _last_at(samples, minf(clock, end)))
        var a: Dictionary = samples[index]
        var b: Dictionary = samples[mini(index + 1, samples.size() - 1)]
        var blend := clampf((clock - float(a["time"])) / maxf(0.001, float(b["time"]) - float(a["time"])), 0, 1)
        var from := Vector2(float(a["x"]), float(a["y"]))
        var to := Vector2(float(b["x"]), float(b["y"]))
        var direction := (to - from).normalized()
        if direction.is_zero_approx() and index > 0:
            direction = (from - Vector2(float(samples[index - 1]["x"]), float(samples[index - 1]["y"]))).normalized()
        var state: Dictionary = shot.duplicate()
        state["position"] = from.lerp(to, blend)
        state["direction"] = direction
        state["contact_blend"] = (1.0 if clock >= end else blend) if impact and index >= samples.size() - 2 else 0.0
        state["impact_age"] = maxf(0, clock - end)
        result.append(state)
    return result

static func _last_at(records: Array, clock: float) -> int:
    var low := 0
    var high := records.size() - 1
    var result := -1
    while low <= high:
        var middle := (low + high) / 2
        if float(records[middle]["time"]) <= clock + 0.00001:
            result = middle
            low = middle + 1
        else:
            high = middle - 1
    return result
