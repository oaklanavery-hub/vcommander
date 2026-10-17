class_name PixelAtlasArt
extends RefCounted

const MANIFEST := "res://assets/pixel/art_manifest.json"
static var _manifest: Dictionary = {}
static var _sheets: Dictionary = {}
static var _frames: Dictionary = {}

static func catalog() -> Dictionary:
    if _manifest.is_empty() and FileAccess.file_exists(MANIFEST):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
        if parsed is Dictionary:
            _manifest = parsed
    return _manifest

static func icon(group: String, id: String) -> Texture2D:
    var key := group + "/" + id
    if _frames.has(key):
        return _frames[key]
    var atlas: Dictionary = catalog().get(group, {})
    var frames: Dictionary = atlas.get("frames", {})
    if not frames.has(id):
        return null
    if not _sheets.has(group):
        var path := str(atlas.get("texture", ""))
        if not ResourceLoader.exists(path, "Texture2D"):
            return null
        _sheets[group] = load(path)
    var cell: Array = atlas.get("cell_size", [64, 64])
    var coordinate: Array = frames[id]
    var result := AtlasTexture.new()
    result.atlas = _sheets[group]
    result.region = Rect2(int(coordinate[0]) * int(cell[0]), int(coordinate[1]) * int(cell[1]), int(cell[0]), int(cell[1]))
    result.filter_clip = true
    _frames[key] = result
    return result
