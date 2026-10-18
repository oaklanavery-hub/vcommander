extends Control

# Read-only title illustration, separate from Commander selection and combat.
const BACKGROUND := preload("res://assets/pixel/menu-camp-v1.png")
const FRAMES := 32
const CYCLE := 4.8
const SEATS := [Vector2(269, 625), Vector2(819, 677), Vector2(461, 677), Vector2(1011, 625)]
const ACCENTS := {"fire": Color("efad60"), "water": Color("9bdcea"), "earth": Color("b7ce87"), "slime": Color("f2acd1")}
var _commanders: Array[Dictionary] = []
var _textures: Dictionary = {}
var _meshes: Dictionary = {}
var _clock := 0.0
var _refresh := 0.0
var _was_reduced := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _commanders = ContentDatabase.get_all_commanders()
    var frames: Dictionary = PixelAtlasArt.catalog().get("menu_commanders", {}).get("frames", {})
    _commanders.sort_custom(func(a: Dictionary, b: Dictionary):
        var left: Array = frames.get(str(a.get("element", "")), [999, 0])
        var right: Array = frames.get(str(b.get("element", "")), [999, 0])
        return str(a.get("id", "")) < str(b.get("id", "")) if int(left[0]) == int(right[0]) else int(left[0]) < int(right[0])
    )
    for commander in _commanders:
        var element := str(commander.get("element", ""))
        var picture := PixelAtlasArt.icon("menu_commanders", element)
        if picture == null:
            picture = CommanderArt.icon(element)
        _textures[element] = PixelAtlasArt.standalone(picture)
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

func _seat(index: int) -> Vector2:
    if index < SEATS.size():
        return SEATS[index]
    return Vector2(96 + (index - SEATS.size()) * 130, 708)

func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    var scene_scale := size / Vector2(1280, 720)
    draw_texture_rect(BACKGROUND, Rect2(Vector2.ZERO, size), false)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.06, 0.08))
    draw_set_transform(Vector2.ZERO, 0, scene_scale)
    var angle := 0.0 if GameAudio.reduced_motion else _clock / CYCLE * TAU
    for index in range(8):
        var point := Vector2(170 + index * 139, 48 + index * 37 % 110)
        var glow := 0.45 if GameAudio.reduced_motion else 0.45 + sin(angle + index * 1.4) * 0.3
        draw_rect(Rect2(point, Vector2(2, 2)), Color(0.7, 0.83, 1, glow))
    var fire := Vector2(640, 602)
    draw_set_transform((fire + Vector2(0, 10)) * scene_scale, 0, Vector2(1, 0.32) * scene_scale)
    var pulse := 0.0 if GameAudio.reduced_motion else sin(angle * 3) * 3
    for ring in range(6):
        draw_circle(Vector2.ZERO, 150 - ring * 18 + pulse, Color(1, 0.58, 0.17, 0.016 + ring * 0.004))
    draw_set_transform(Vector2.ZERO, 0, scene_scale)
    var order := range(_commanders.size())
    order.sort_custom(func(a: int, b: int): return _seat(a).y < _seat(b).y)
    for index in order:
        _draw_commander(_commanders[index], _seat(index), index, scene_scale)
    _draw_fire(fire, angle)
    draw_set_transform(Vector2.ZERO)

func _draw_commander(commander: Dictionary, foot: Vector2, index: int, scene_scale: Vector2) -> void:
    var element := str(commander.get("element", ""))
    var picture: Texture2D = _textures[element]
    var draw_size := Vector2(224 * picture.get_width() / float(picture.get_height()), 224)
    draw_set_transform((foot - Vector2(0, 12)) * scene_scale, 0, Vector2(1, 0.18) * scene_scale)
    draw_circle(Vector2.ZERO, 92, Color(0.015, 0.025, 0.045, 0.38))
    var reduced := GameAudio.reduced_motion
    var phase := 0 if reduced else posmod(int(floor(_clock / CYCLE * FRAMES)) + index * 7, FRAMES)
    var position := (foot - Vector2(draw_size.x * 0.5, draw_size.y)).round()
    draw_set_transform(position * scene_scale, 0, draw_size * scene_scale)
    draw_mesh(_idle_mesh(element, phase, reduced), picture)
    draw_set_transform(Vector2.ZERO, 0, scene_scale)
    _draw_motes(element, foot - Vector2(0, 103), 70, ACCENTS.get(element, Color("dfbd78")), TAU * phase / FRAMES, reduced)

func _draw_fire(center: Vector2, angle: float) -> void:
    var frame := 0 if GameAudio.reduced_motion else int(_clock * 10) % 8
    var flicker: float = [0, 4, -4, 0, 8, 4, 0, -4][frame]
    var outer := PackedVector2Array([Vector2(-28, 0), Vector2(-28, -12), Vector2(-24, -12), Vector2(-24, -28), Vector2(-16, -28), Vector2(-16, -40), Vector2(-8, -40), Vector2(-8, -56 - flicker), Vector2(0, -68 - flicker), Vector2(4, -48), Vector2(12, -40), Vector2(12, -48), Vector2(20, -36), Vector2(20, -28), Vector2(28, -20), Vector2(28, -8), Vector2(24, 0)])
    var middle := PackedVector2Array([Vector2(-20, 0), Vector2(-20, -12), Vector2(-12, -12), Vector2(-12, -32), Vector2(-4, -48 - flicker), Vector2(4, -24), Vector2(12, -32), Vector2(16, -16), Vector2(20, -8), Vector2(16, 0)])
    var core := PackedVector2Array([Vector2(-12, 0), Vector2(-12, -8), Vector2(-4, -24), Vector2(0, -36), Vector2(4, -16), Vector2(12, -8), Vector2(12, 0)])
    var scene_scale := size / Vector2(1280, 720)
    draw_set_transform(center * scene_scale, 0, scene_scale)
    draw_colored_polygon(outer, Color("e6662d"))
    draw_colored_polygon(middle, Color("ffc154"))
    draw_colored_polygon(core, Color("fff1b2"))
    draw_set_transform(Vector2.ZERO, 0, scene_scale)
    for index in range(7):
        var travel := index / 7.0 if GameAudio.reduced_motion else fposmod(index / 7.0 + angle / TAU * 3, 1.0)
        var point := center + Vector2(sin(index * 2.7 + travel * 3) * (10 + travel * 22), -24 - travel * 92)
        draw_rect(Rect2((point / 2).round() * 2, Vector2(2, 4)), Color(1, 0.69, 0.3, (1.0 - travel) * 0.85))

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
            var cloth := smoothstep(0.35, 0.88, absf(uv.x - 0.5) * 2) * sin(uv.y * PI) * (1.0 - smoothstep(0.7, 0.88, uv.y))
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
    for index in range(3):
        var travel := index / 3.0 if reduced else fposmod(index / 3.0 + angle / TAU, 1.0)
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
