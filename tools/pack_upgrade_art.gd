extends SceneTree
## Deterministic atlas packing only: crop supplied cells and nearest-neighbor scale.
func _init() -> void:
    var source_path := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--source="):
            source_path = argument.trim_prefix("--source=")
    var source := Image.load_from_file(source_path)
    if source == null or source.get_size() != Vector2i(1536, 1024) or not source.has_mipmaps() and source.get_format() != Image.FORMAT_RGBA8:
        push_error("Expected the transparent 1536×1024 six-by-four upgrade atlas")
        quit(1)
        return
    var atlas := Image.create(384, 256, false, Image.FORMAT_RGBA8)
    atlas.fill(Color.TRANSPARENT)
    var frames := {}
    var elements := ["fire", "water", "earth", "slime"]
    for row in range(4):
        for column in range(6):
            var cell := source.get_region(Rect2i(column * 256, row * 256, 256, 256))
            var bounds := cell.get_used_rect()
            if bounds.size.x <= 0 or bounds.size.y <= 0:
                push_error("Missing upgraded sprite")
                quit(1)
                return
            var sprite := cell.get_region(bounds)
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
