class_name CommanderArt
extends RefCounted

static var _catalog: Dictionary = {}
static var _pictures: Dictionary = {}

static func catalog() -> Dictionary:
    if _catalog.is_empty():
        var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/commanders.json"))
        if parsed is Dictionary:
            _catalog = parsed
    return _catalog

static func icon(element: String) -> Texture2D:
    if _pictures.has(element):
        return _pictures[element]
    var data := catalog()
    var colors: Dictionary = data.get("colors", {}).duplicate()
    colors.merge(data.get("palettes", {}).get(element, {}), true)
    var sprite: Dictionary = data.get("sprites", {}).get(element, {})
    var picture := Image.create(32, 48, false, Image.FORMAT_RGBA8)
    picture.fill(Color.TRANSPARENT)
    var rows: Array = sprite.get("pixels", [])
    for y in range(rows.size()):
        var row := str(rows[y])
        for x in range(row.length()):
            var cell := row.substr(x, 1)
            if colors.has(cell):
                picture.set_pixel(x, y, Color(str(colors[cell])))
    var result := ImageTexture.create_from_image(picture)
    _pictures[element] = result
    return result
