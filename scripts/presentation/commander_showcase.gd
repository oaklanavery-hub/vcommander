extends Control

# Title-screen illustration only. Reuse the gallery artwork; no combat actors
# or simulation state are created by these idle poses.
const FRAMES := 32
const CYCLE := 4.8
const ACCENTS := {"fire": Color("efad60"), "water": Color("9bdcea"), "earth": Color("b7ce87"), "slime": Color("f2acd1")}
var _commanders: Array[Dictionary] = []
var _textures: Dictionary = {}
var _meshes: Dictionary = {}
var _clock := 0.0
var _refresh := 0.0
var _was_reduced := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _commanders = ContentDatabase.get_all_commanders()
    # Follow the art catalog's order without making a fixed-size roster.
    var frames: Dictionary = PixelAtlasArt.catalog().get("commanders", {}).get("frames", {})
    _commanders.sort_custom(func(a: Dictionary, b: Dictionary):
        var left: Array = frames.get(str(a.get("element", "")), [999, 999])
        var right: Array = frames.get(str(b.get("element", "")), [999, 999])
        var left_order := int(left[1]) * 100 + int(left[0])
        var right_order := int(right[1]) * 100 + int(right[0])
        return str(a.get("id", "")) < str(b.get("id", "")) if left_order == right_order else left_order < right_order
    )
    for commander in _commanders:
        var element := str(commander.get("element", ""))
        _textures[element] = PixelAtlasArt.standalone(CommanderArt.icon(element))
    _was_reduced = GameAudio.reduced_motion

func _process(delta: float) -> void:
    if GameAudio.reduced_motion != _was_reduced:
        _was_reduced = GameAudio.reduced_motion
        queue_redraw()
    if GameAudio.reduced_motion:
        return
    _clock = fmod(_clock + delta, CYCLE)
    _refresh += delta
    if _refresh >= 0.05:
        _refresh = fmod(_refresh, 0.05)
        queue_redraw()

func _draw() -> void:
    if _commanders.is_empty() or size.x <= 0 or size.y <= 0:
        return
    var columns := mini(2, _commanders.size())
    var rows := ceili(float(_commanders.size()) / columns)
    var cell := Vector2(size.x / columns, size.y / rows)
    for index in range(_commanders.size()):
        var origin := Vector2(index % columns, index / columns) * cell
        _draw_commander(_commanders[index], origin, cell, index)

func _draw_commander(commander: Dictionary, origin: Vector2, cell: Vector2, index: int) -> void:
    var element := str(commander.get("element", ""))
    var accent: Color = ACCENTS.get(element, Color("dfbd78"))
    var center := (origin + Vector2(cell.x * 0.5, cell.y * 0.43)).round()
    var foot := (origin + Vector2(cell.x * 0.5, cell.y - 37)).round()
    var radius := floorf(minf(cell.x * 0.34, cell.y * 0.35))
    var halo := PackedVector2Array()
    for point in range(13):
        halo.append((center + Vector2.from_angle(TAU * point / 12) * radius).round())
    draw_colored_polygon(halo, Color(accent, 0.065))
    draw_polyline(halo, Color(accent, 0.24), 1)
    draw_line(center - Vector2(radius + 8, 0), center - Vector2(radius - 4, 0), Color(accent, 0.5), 2)
    draw_line(center + Vector2(radius - 4, 0), center + Vector2(radius + 8, 0), Color(accent, 0.5), 2)
    draw_set_transform(foot + Vector2(0, 3), 0, Vector2(1, 0.2))
    draw_circle(Vector2.ZERO, minf(cell.x * 0.27, 70), Color("26372d"))
    draw_arc(Vector2.ZERO, minf(cell.x * 0.27, 70), 0, TAU, 20, Color(accent, 0.48), 4)
    draw_set_transform(Vector2.ZERO)
    var reduced := GameAudio.reduced_motion
    var phase := 0 if reduced else posmod(int(floor(_clock / CYCLE * FRAMES)) + index * 7, FRAMES)
    var angle := TAU * phase / FRAMES
    var picture: Texture2D = _textures[element]
    var height := floorf(minf(cell.y - 48, minf(cell.x * 1.25, 240)))
    var draw_size := Vector2(height * 2.0 / 3.0, height)
    var lift := 0.0 if reduced else (-2.0 - sin(angle) * 2.0 if element == "slime" else -sin(angle) * 0.8)
    var position := (foot - Vector2(draw_size.x * 0.5, draw_size.y) + Vector2(0, lift)).round()
    draw_set_transform(position, 0, draw_size)
    draw_mesh(_idle_mesh(element, phase, reduced), picture)
    draw_set_transform(Vector2.ZERO)
    _draw_motes(element, center, radius, accent, angle, reduced)
    var font := ThemeDB.fallback_font
    var title := str(commander.get("display_name", "Commander"))
    var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
    var label_position := Vector2(foot.x - title_width * 0.5, origin.y + cell.y - 12).round()
    draw_string(font, label_position + Vector2(1, 2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("1f3029"))
    draw_string(font, label_position, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2e4c6"))

func _idle_mesh(element: String, phase: int, reduced: bool) -> ArrayMesh:
    var key := "%s:%d:%s" % [element, phase, reduced]
    if _meshes.has(key):
        return _meshes[key]
    var vertices := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()
    var wave := 0.0 if reduced else sin(TAU * phase / FRAMES)
    var follow := 0.0 if reduced else sin(TAU * phase / FRAMES + 0.8)
    for y in range(13):
        for x in range(9):
            var uv := Vector2(x / 8.0, y / 12.0)
            var upper := 1.0 - smoothstep(0.55, 0.98, uv.y)
            var cloth := smoothstep(0.35, 0.88, absf(uv.x - 0.5) * 2) * sin(uv.y * PI)
            var offset := Vector2(wave * 0.009 * upper + follow * 0.015 * cloth, -wave * 0.005 * upper)
            if element == "water":
                offset.x += follow * 0.018 * cloth
            elif element == "earth":
                offset.x *= 0.65
            elif element == "slime":
                offset.x += (uv.x - 0.5) * wave * 0.022
                offset.y += (1.0 - uv.y) * wave * 0.01
            vertices.append(Vector3(uv.x + offset.x, uv.y + offset.y, 0))
            uvs.append(uv)
    for y in range(12):
        for x in range(8):
            var first := y * 9 + x
            indices.append_array(PackedInt32Array([first, first + 1, first + 10, first, first + 10, first + 9]))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    _meshes[key] = mesh
    return mesh

func _draw_motes(element: String, center: Vector2, radius: float, accent: Color, angle: float, reduced: bool) -> void:
    for index in range(5):
        var travel := index / 5.0 if reduced else fposmod(index / 5.0 + angle / TAU, 1.0)
        var side := -1.0 if index % 2 == 0 else 1.0
        var point := (center + Vector2(side * radius * (0.72 + index % 3 * 0.12), radius * (0.85 - travel * 1.7))).round()
        var color := Color(accent, 0.45 if reduced else 0.25 + sin(travel * PI) * 0.55)
        match element:
            "fire":
                draw_rect(Rect2(point, Vector2(2, 5)), color)
                draw_rect(Rect2(point + Vector2(0, 3), Vector2(3, 2)), Color("ef8553", color.a))
            "water":
                draw_line(point - Vector2(3, 0), point + Vector2(3, 0), color, 1)
                draw_line(point - Vector2(0, 3), point + Vector2(0, 3), color, 1)
            "earth":
                draw_colored_polygon(PackedVector2Array([point - Vector2(3, 1), point + Vector2(2, -3), point + Vector2(3, 2), point + Vector2(-2, 3)]), color)
            _:
                draw_arc(point, 2 + index % 2, 0, TAU, 8, color, 1)
                draw_rect(Rect2(point - Vector2.ONE, Vector2.ONE), Color("fff0dc", color.a))
