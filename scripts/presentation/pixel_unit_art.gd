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
