class_name UnitDeathMotion
extends RefCounted

const DURATION := 0.5

static func pose(unit: Dictionary, age: float, reduced: bool) -> Dictionary:
    var progress := clampf(age / DURATION, 0, 1)
    var profile := CombatCues.profile(str(unit.get("card_id", "")))
    var motion := str(profile.get("death_motion", "collapse"))
    var result := {"state": "death", "death_motion": motion, "progress": progress, "alpha": 1.0 - progress, "width": 1.0, "height": 1.0, "lean": 0.0, "rise": 0.0, "reduced": reduced}
    if reduced:
        return result
    var settle := smoothstep(0.0, 0.85, progress)
    match motion:
        "collapse":
            result["height"] = 1 - settle * 0.65
            result["lean"] = settle * (0.28 if unit.get("side") == "player" else -0.28)
        "wilt":
            result["height"] = 1 - settle * 0.5
            result["lean"] = settle * (0.36 if unit.get("side") == "player" else -0.36)
            result["width"] = 1 - settle * 0.2
        "dissolve":
            result["rise"] = -progress * 10
        "pop":
            var squeeze := sin(minf(progress / 0.5, 1) * PI * 0.5)
            result["width"] = 1 + squeeze * 0.45
            result["height"] = 1 - squeeze * 0.72
            result["alpha"] = 1 - smoothstep(0.2, 0.65, progress)
    return result

static func draw_body(canvas: CanvasItem, texture: Texture2D, foot: Vector2, side: float, tint: Color, pose_data: Dictionary) -> void:
    var width := side * float(pose_data.get("width", 1))
    var height := side * float(pose_data.get("height", 1))
    var source := texture.get_size()
    var progress := float(pose_data.get("progress", 0))
    var reduced := bool(pose_data.get("reduced", false))
    for y in range(8):
        for x in range(8):
            if not reduced and pose_data.get("death_motion") == "dissolve" and float((x * 5 + y * 3) % 8) / 8.0 < progress:
                continue
            var uv := Vector2(float(x) / 8, float(y) / 8)
            var lean := float(pose_data.get("lean", 0)) * (1 - uv.y) * side
            var at := foot - Vector2(width * 0.5, height * 0.9) + uv * Vector2(width, height) + Vector2(lean, float(pose_data.get("rise", 0)))
            canvas.draw_texture_rect_region(texture, Rect2(at.round(), (Vector2(width, height) / 8).ceil()), Rect2(uv * source, source / 8), tint)

static func draw_particles(canvas: CanvasItem, at: Vector2, unit: Dictionary, age: float, reduced: bool) -> void:
    if reduced or age < 0.08 or age >= DURATION:
        return
    var profile := CombatCues.profile(str(unit.get("card_id", "")))
    var motion := str(profile.get("death_motion", "collapse"))
    var progress := clampf((age - 0.08) / (DURATION - 0.08), 0, 1)
    var color := Color(str(profile.get("accent", "b7ac83")))
    color.a = 1 - progress
    var count := BattleEffects.particle_count(7 if motion in ["pop", "dissolve"] else 4)
    for index in range(count):
        var angle := float(index) * TAU / count
        var point := at + Vector2(cos(angle) * (4 + progress * 25), -sin(progress * PI) * (14 if motion == "pop" else 5))
        if motion == "dissolve":
            point = at + Vector2(cos(angle) * 18, -15 - progress * (20 + index * 3))
        elif motion == "wilt":
            point.y -= 22 * (1 - progress)
        canvas.draw_rect(Rect2(point.round(), Vector2(3, 2) if motion == "wilt" else Vector2(3, 3)), color)
