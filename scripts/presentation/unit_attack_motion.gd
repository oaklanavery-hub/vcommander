class_name UnitAttackMotion
extends RefCounted

const WINDUP := 0.26
const RECOVERY := 0.46
static var _meshes: Dictionary = {}

static func pose(event: Dictionary, clock: float) -> Dictionary:
    var elapsed := clock - float(event.get("time", 0))
    var profile := CombatCues.event_profile(event)
    var charge := smoothstep(0.0, 1.0, (elapsed + WINDUP) / WINDUP) if elapsed < 0 else 0.0
    var power := exp(-maxf(0, elapsed) * 7.0) * (1.0 - smoothstep(0.3, RECOVERY, elapsed)) if elapsed >= 0 else 0.0
    var direction := Vector2(float(event.get("target_x", 1)) - float(event.get("x", 0)), float(event.get("target_y", 0)) - float(event.get("y", 0)))
    return {"state": "attack", "facing": posmod(int(round(direction.angle() / (PI / 2))) * 2, 8), "motion": profile.get("motion", "slash"), "rig": profile.get("rig", "claw"), "accent": profile.get("accent", ""), "charge": charge, "power": power, "attack_age": elapsed, "phase": "windup" if elapsed < 0 else ("strike" if elapsed < 0.12 else "recovery")}

static func displacement(pose: Dictionary) -> Vector2:
    var charge := float(pose.get("charge", 0))
    var power := float(pose.get("power", 0))
    var direction := Vector2.from_angle(float(pose.get("facing", 0)) * PI / 4)
    var motion := str(pose.get("motion", "slash"))
    var reach := 14.0 if motion in ["slam", "slash", "bite", "bounce"] else 4.0
    var lift := -8.0 * charge + 3 * power if motion == "slam" else -3.0 * charge
    if pose.get("rig") in ["pitcher", "plant", "tree"]:
        reach = 3.0
        lift = 0.0
    return (direction * (-6.0 * charge + reach * power) + Vector2(0, lift)).round()

# A small continuous textured mesh bends the existing pixel character instead
# of just sliding an unchanged icon. Feet stay planted while arms, heads,
# wings, branches or bow hands coil and extend. Quantized poses share meshes.
static func mesh(rig: String, charge: float, power: float, mirror: bool) -> ArrayMesh:
    var c := roundf(charge * 8) / 8
    var p := roundf(power * 12) / 12
    var key := "%s:%s:%s:%s" % [rig, c, p, mirror]
    if _meshes.has(key):
        return _meshes[key]
    var vertices := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()
    for y in range(9):
        for x in range(9):
            var uv := Vector2(float(x) / 8, float(y) / 8)
            var logical := Vector2(1 - uv.x if mirror else uv.x, uv.y)
            var offset := deform(logical, rig, c, p)
            if mirror:
                offset.x = -offset.x
            vertices.append(Vector3(uv.x + offset.x, uv.y + offset.y, 0))
            uvs.append(uv)
    for y in range(8):
        for x in range(8):
            var a := y * 9 + x
            indices.append_array(PackedInt32Array([a, a + 1, a + 10, a, a + 10, a + 9]))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    _meshes[key] = result
    return result

static func deform(uv: Vector2, rig: String, charge: float, power: float) -> Vector2:
    var upper := 1.0 - smoothstep(0.48, 0.9, uv.y)
    var arm := smoothstep(0.42, 0.82, uv.x) * sin(uv.y * PI)
    var offset := Vector2((-0.06 * charge + 0.09 * power) * upper, 0)
    match rig:
        "brute", "tree":
            var limbs := absf(uv.x - 0.5) * 2 * sin(uv.y * PI)
            offset.y = (-0.16 * charge + 0.11 * power) * limbs
            offset.x += 0.12 * power * arm
        "claw":
            offset += Vector2(0.16 * power * arm, (-0.1 * charge + 0.08 * power) * arm)
        "mage", "healer":
            offset += Vector2((0.05 * charge + 0.12 * power) * arm, -0.12 * charge * arm)
        "dragon":
            offset.y -= sin(uv.x * PI) * upper * 0.16 * charge
            offset.x += arm * 0.14 * power
        "serpent":
            offset.x += sin(uv.y * TAU) * (0.07 * charge - 0.08 * power) * upper
            offset.y += (0.07 * charge - 0.06 * power) * upper
        "pitcher", "plant":
            offset.x += (0.14 * power - 0.08 * charge) * upper
            offset.y += (-0.13 * charge + 0.08 * power) * upper
        "bow":
            offset.x += (-0.13 * charge + 0.08 * power) * sin(uv.x * PI) * sin(uv.y * PI)
            offset.y -= 0.06 * charge * arm
        "slime":
            offset = Vector2((uv.x - 0.5) * (0.3 * charge - 0.2 * power), (1 - uv.y) * (0.18 * charge - 0.16 * power))
        "cannon":
            offset = Vector2((0.03 * charge - 0.12 * power) * upper, 0.04 * charge * upper)
        "barrel":
            offset = Vector2((uv.y - 0.9) * (0.05 * charge - 0.09 * power), 0.03 * power * upper)
    return offset

static func draw_action(canvas: CanvasItem, body: Vector2, pose: Dictionary, element: String, reduced: bool) -> void:
    var charge := float(pose.get("charge", 0))
    var power := float(pose.get("power", 0))
    var direction := Vector2.from_angle(float(pose.get("facing", 0)) * PI / 4)
    var side := direction.orthogonal()
    var motion := str(pose.get("motion", "slash"))
    var accent := str(pose.get("accent", ""))
    var color := Color(accent if not accent.is_empty() else str(PixelUnitArt.palette(element).get("l", "e4dba6")))
    var hand := body + direction * 16
    if motion == "shoot" and pose.get("rig") == "bow":
        var tip_a := hand + side * 15
        var tip_b := hand - side * 15
        var grip := hand + direction * 7
        canvas.draw_polyline(PackedVector2Array([tip_a, grip + side * 6, grip - side * 6, tip_b]), Color("342f28"), 4)
        canvas.draw_polyline(PackedVector2Array([tip_a, grip + side * 6, grip - side * 6, tip_b]), Color("d4ad71"), 2)
        var string := hand - direction * (3 + charge * 10)
        canvas.draw_polyline(PackedVector2Array([tip_a, string, tip_b]), Color("f2e4ba"), 1)
        if charge > 0:
            BattleEffects.projectile(canvas, string + direction * 17, direction, "arrow", 0, true)
    elif motion in ["cast", "shoot"]:
        if charge > 0:
            canvas.draw_arc(hand, 4 + charge * 8, 0, TAU, 8, color, 2)
            for index in range(4):
                var ray := Vector2.from_angle(float(index) * PI / 2)
                canvas.draw_rect(Rect2((hand + ray * (15 - charge * 8) - Vector2.ONE).round(), Vector2(3, 3)), color)
        if power > 0.3:
            canvas.draw_line(hand.round(), (hand + direction * power * 15).round(), color, 3)
    elif power > 0.18:
        color.a = power
        if motion == "slash":
            for stripe in range(3):
                var center := hand + direction * (stripe * 4) + side * (stripe * 5 - 5)
                canvas.draw_arc(center, 17 if not reduced else 10, direction.angle() - 1.3, direction.angle() + 0.7, 7, color, 3)
        elif motion == "slam":
            canvas.draw_line((body - Vector2(0, 25) + direction * 8).round(), (hand + Vector2(0, 12)).round(), color, 5)
            canvas.draw_arc(hand + Vector2(0, 18), 10 + (1 - power) * 22, 0, PI, 8, color, 3)
        elif motion == "bite":
            canvas.draw_polyline(PackedVector2Array([hand - direction * 6 - side * 9, hand + direction * 10, hand - direction * 6 + side * 9]), color, 3)
        elif motion == "bounce":
            canvas.draw_arc(hand, 7 + (1 - power) * 10, 0, TAU, 8, color, 2)
            for index in range(4):
                var ray := Vector2.from_angle(float(index) * PI / 2 + 0.4)
                canvas.draw_rect(Rect2((hand + ray * (5 + (1 - power) * 14)).round(), Vector2(3, 3)), color)
