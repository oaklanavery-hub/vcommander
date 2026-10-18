class_name PixelUnitArt
extends RefCounted

static var _catalog: Dictionary = {}
static var _icons: Dictionary = {}

static func catalog() -> Dictionary:
    if _catalog.is_empty():
        var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/roster.json"))
        if parsed is Dictionary:
            _catalog = parsed
    return _catalog

static func definition(card_id: String, role: String = "range", element: String = "earth") -> Dictionary:
    var sprites: Dictionary = catalog().get("sprites", {})
    if sprites.has(card_id):
        return sprites[card_id]
    for sprite in sprites.values():
        if sprite.get("role") == role and sprite.get("element") == element:
            return sprite
    return sprites.get("commander_plant", {})

static func palette(element: String) -> Dictionary:
    var result: Dictionary = catalog().get("colors", {}).duplicate()
    result.merge(catalog().get("palettes", {}).get(element, {}), true)
    return result

static func icon(card_id: String, role: String = "range", element: String = "earth") -> Texture2D:
    var detailed := PixelAtlasArt.icon("units", card_id)
    if detailed != null:
        return detailed
    var key := card_id + role + element
    if _icons.has(key):
        return _icons[key]
    var sprite := definition(card_id, role, element)
    var colors := palette(element)
    var picture := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    picture.fill(Color.TRANSPARENT)
    var rows: Array = sprite.get("pixels", [])
    for y in range(rows.size()):
        var row := str(rows[y])
        for x in range(row.length()):
            var cell := row.substr(x, 1)
            if colors.has(cell):
                picture.fill_rect(Rect2i(x * 2, y * 2, 2, 2), Color(str(colors[cell])))
    var texture := ImageTexture.create_from_image(picture)
    _icons[key] = texture
    return texture

# All animation is derived from replay motion/events, never from game-rule state.
static func draw_unit(canvas: CanvasItem, position: Vector2, role: String, element: String, pixel: float, flip: bool = false, bob: float = 0.0, card_id: String = "", pose: Dictionary = {}) -> void:
    var detailed := PixelAtlasArt.icon("units", card_id)
    if detailed != null:
        _draw_detailed_unit(canvas, detailed, position, pixel, flip, bob, pose)
        return
    var sprite := definition(card_id, role, element)
    var colors := palette(element)
    var rows: Array = sprite.get("pixels", [])
    var state := str(pose.get("state", "idle"))
    var facing := int(pose.get("facing", 4 if flip else 0)) if state in ["move", "attack"] else 2
    var facing_offset := Vector2(roundf(cos(float(facing) * PI / 4.0)), roundf(sin(float(facing) * PI / 4.0)))
    var back := facing in [5, 6, 7]
    var mirror := facing in [3, 4, 5]
    var moving := str(pose.get("state", "idle")) == "move"
    var step := int(pose.get("step", 0)) % 4
    var death := str(pose.get("state", "idle")) == "death"
    var origin := (position - Vector2(8.0 * pixel, 15.0 * pixel + bob)).round()
    for y in range(rows.size()):
        var row := str(rows[y])
        for x in range(row.length()):
            var key := row.substr(x, 1)
            if not colors.has(key):
                continue
            if back and key == "e":
                key = "a"
            var px := 15 - x if mirror else x
            var stride := 0.0
            if moving and y >= 10:
                stride = (1.0 if x < 8 else -1.0) * (1.0 if step < 2 else -1.0)
            var color := Color(str(colors.get(key, "ffffff")))
            if bool(pose.get("hit", false)):
                color = color.lightened(0.65)
            if death:
                color.a = float(pose.get("alpha", 1.0))
            var py := float(y) * (0.55 if death else 1.0)
            var offset := facing_offset if y < 8 and state in ["move", "attack"] else Vector2.ZERO
            if moving and y >= 10:
                py += stride * facing_offset.y
                stride *= facing_offset.x
            canvas.draw_rect(Rect2(origin + (Vector2(px + stride, py) + offset) * pixel, Vector2.ONE * pixel), color)

static func _draw_detailed_unit(canvas: CanvasItem, texture: Texture2D, position: Vector2, pixel: float, flip: bool, bob: float, pose: Dictionary) -> void:
    var state := str(pose.get("state", "idle"))
    var facing := int(pose.get("facing", 4 if flip else 0))
    var direction := Vector2(cos(float(facing) * PI / 4.0), sin(float(facing) * PI / 4.0)).round()
    var mirror := facing in [3, 4, 5] if state in ["move", "attack"] else flip
    if mirror:
        texture = PixelAtlasArt.mirrored(texture)
    var moving := state == "move"
    var stride := 1.0 if int(pose.get("step", 0)) % 4 < 2 else -1.0
    var side := roundf(pixel * 24.0)
    var origin := (position - Vector2(side * 0.5, side * 0.9 + bob)).round()
    var tint := Color(1.6, 1.5, 1.3) if bool(pose.get("hit", false)) else Color.WHITE
    tint.a = float(pose.get("alpha", 1.0))
    if state == "death":
        canvas.draw_texture_rect(texture, Rect2(origin + Vector2(0, side * 0.45), Vector2(side, side * 0.55)), false, tint)
        return
    if state == "attack" and pose.has("rig"):
        var attack_mesh := UnitAttackMotion.mesh(str(pose["rig"]), float(pose.get("charge", 0)), float(pose.get("power", 0)), mirror)
        canvas.draw_mesh(attack_mesh, PixelAtlasArt.standalone(texture), Transform2D(Vector2(side, 0), Vector2(0, side), origin), tint)
        return
    if pose.get("rig") in ["slime", "cannon", "barrel"]:
        var pulse := sin(float(pose.get("cycle", 0))) * (0.09 if moving else 0.025) if pose.get("rig") == "slime" else 0.0
        var birth := clampf(float(pose.get("birth_progress", 1)), 0.05, 1)
        var dimensions := Vector2(side * (1 + pulse) * (1.2 - birth * 0.2), side * (1 - pulse) * birth)
        var foot := position - Vector2(0, bob)
        canvas.draw_texture_rect(texture, Rect2((foot - Vector2(dimensions.x * 0.5, dimensions.y * 0.9)).round(), dimensions.round()), false, tint)
        return
    var source := texture.get_size()
    # Directional body lean and alternating lower-body strips retain the existing
    # eight-direction/four-step procedural animation without driving simulation.
    for y in range(0, int(source.y), 4):
        var top := roundf(float(y) * side / source.y)
        var bottom := roundf(minf(float(y + 4), source.y) * side / source.y)
        var offset := direction * (1.0 if state == "attack" else 0.0)
        if moving and float(y) < source.y * 0.45:
            offset = Vector2(direction.x, -absf(direction.y))
        if moving and float(y) >= source.y * 0.72:
            for leg in range(2):
                var step := stride * (1.0 if leg == 0 else -1.0)
                var shift := Vector2(direction.x * step, -absf(direction.y) * step)
                var target := Rect2(origin + Vector2(float(leg) * side * 0.5, top) + shift, Vector2(side * 0.5, bottom - top))
                canvas.draw_texture_rect_region(texture, target, Rect2(float(leg) * source.x * 0.5, y, source.x * 0.5, 4), tint)
        else:
            canvas.draw_texture_rect_region(texture, Rect2(origin + Vector2(0, top) + offset, Vector2(side, bottom - top)), Rect2(0, y, source.x, minf(4, source.y - y)), tint)
