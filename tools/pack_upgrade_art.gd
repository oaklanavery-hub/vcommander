extends SceneTree
## Deterministic sprite extraction and nearest-neighbor atlas packing.
## Generated silhouettes can cross nominal source cells; pack whole connected
## characters so a neighboring tail/weapon never leaks into another portrait.
func _init() -> void:
    var source_path := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--source="):
            source_path = argument.trim_prefix("--source=")
    var source := Image.load_from_file(source_path)
    if source == null or source.get_size() != Vector2i(1536, 1024) or source.get_format() != Image.FORMAT_RGBA8:
        push_error("Expected the transparent 1536×1024 six-by-four upgrade atlas")
        quit(1)
        return
    var atlas := Image.create(384, 256, false, Image.FORMAT_RGBA8)
    atlas.fill(Color.TRANSPARENT)
    var frames := {}
    var elements := ["fire", "water", "earth", "slime"]
    var silhouettes := extract_silhouettes(source)
    if silhouettes.size() != 24:
        push_error("Expected 24 isolated source silhouettes")
        quit(1)
        return
    for row in range(4):
        for column in range(6):
            var silhouette: Dictionary = silhouettes[row * 6 + column]
            var bounds: Rect2i = silhouette["bounds"]
            if bounds.size.x <= 0 or bounds.size.y <= 0:
                push_error("Missing upgraded sprite")
                quit(1)
                return
            var sprite := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
            sprite.fill(Color.TRANSPARENT)
            for index in silhouette["pixels"]:
                var point := Vector2i(index % source.get_width(), index / source.get_width())
                sprite.set_pixelv(point - bounds.position, source.get_pixelv(point))
            var factor := minf(54.0 / sprite.get_width(), 54.0 / sprite.get_height())
            sprite.resize(maxi(1, roundi(sprite.get_width() * factor)), maxi(1, roundi(sprite.get_height() * factor)), Image.INTERPOLATE_NEAREST)
            atlas.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i(column * 64 + (64 - sprite.get_width()) / 2, row * 64 + 60 - sprite.get_height()))
            frames["card_%s_%02d" % [elements[row], column + 1]] = [column, row]
    var error := atlas.save_png("res://assets/pixel/roster-upgrades-v1.png")
    if error != OK:
        push_error("Cannot save upgrade atlas")
        quit(1)
        return
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/art_manifest.json"))
    manifest["upgraded_units"] = {"texture": "res://assets/pixel/roster-upgrades-v1.png", "cell_size": [64, 64], "frames": frames}
    var file := FileAccess.open("res://assets/pixel/art_manifest.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  ") + "\n")
    file.close()
    print("Packed 24 transparent Lv. 2 sprites; base atlas is unchanged.")
    quit()

func extract_silhouettes(source: Image) -> Array:
    var width := source.get_width()
    var height := source.get_height()
    var bytes := source.get_data()
    var visited := PackedByteArray()
    visited.resize(width * height)
    var components: Array = []
    for start in range(width * height):
        if visited[start] != 0 or bytes[start * 4 + 3] <= 20:
            continue
        var pixels := PackedInt32Array([start])
        visited[start] = 1
        var cursor := 0
        var low := Vector2i(width, height)
        var high := Vector2i.ZERO
        while cursor < pixels.size():
            var index := pixels[cursor]
            cursor += 1
            var point := Vector2i(index % width, index / width)
            low = low.min(point)
            high = high.max(point)
            for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
                var neighbor: Vector2i = point + offset
                if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
                    continue
                var next := neighbor.y * width + neighbor.x
                if visited[next] == 0 and bytes[next * 4 + 3] > 20:
                    visited[next] = 1
                    pixels.append(next)
        if pixels.size() > 1000:
            components.append({"pixels": pixels, "bounds": Rect2i(low, high - low + Vector2i.ONE)})
    components.sort_custom(func(a, b):
        var ac: Vector2 = a["bounds"].get_center()
        var bc: Vector2 = b["bounds"].get_center()
        return int(ac.y / 256) < int(bc.y / 256) if int(ac.y / 256) != int(bc.y / 256) else ac.x < bc.x)
    return components
