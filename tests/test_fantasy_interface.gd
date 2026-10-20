extends SceneTree
## Integration guards for the new shared material skin and blessing offers.
## Native captures exercise actual drawing; this suite also runs in the pack.

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    var state := root.get_node("GameState")
    var db := root.get_node("ContentDatabase")
    var theme := load("res://assets/ui/fantasy_theme.tres") as Theme
    check(theme != null, "shared theme loads on source and exported-pack boots")
    for control_type in ["Button", "OptionButton", "LineEdit"]:
        var normal := theme.get_stylebox("normal", control_type)
        var focus := theme.get_stylebox("focus", control_type)
        check(normal != null and focus != null, control_type + " retains visible normal/focus skins")
        check(normal.get_minimum_size().x <= 32 and normal.get_minimum_size().y <= 24, control_type + " does not inflate compact controls")
    for path in ["res://assets/pixel/forest-clearing-v1.png", "res://assets/pixel/lodge-courtyard-v1.png"]:
        var texture := load(path) as Texture2D
        check(texture != null and texture.get_width() >= 1280 and texture.get_width() <= 2048, "production scenery is present and bounded: " + path)
    var font := load("res://assets/fonts/PixelifySans.ttf") as Font
    check(font != null and font.get_string_size("VCommander", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x > 30, "self-hosted pixel display face is usable")
    var before: Dictionary = {}
    for commander in db.get_all_commanders():
        before[str(commander["id"])] = state.commander_progress.record(str(commander["id"])).duplicate(true)
    var row := HBoxContainer.new()
    row.position = Vector2(24, 24)
    row.add_theme_constant_override("separation", 12)
    root.add_child(row)
    for buff in db.get_all_buffs():
        var tile = load("res://scripts/presentation/buff_tile.gd").new()
        tile.definition = buff
        tile.stacks = 2
        tile.custom_minimum_size = Vector2(156, 204)
        row.add_child(tile)
    for i in range(4):
        await process_frame
    for tile in row.get_children():
        var body: Control = tile.get_child(0)
        var bounds := body.get_global_rect()
        var tile_bounds: Rect2 = tile.get_global_rect()
        check(tile_bounds.grow(1).encloses(bounds), "all five blessing layouts fit their actual offer size: " + str(tile.definition["stat"]))
        check(tile.tooltip_text.contains("2 / 3"), "blessing preserves supplied stack information")
        tile.grab_focus()
        check(tile.has_focus(), "blessing remains keyboard selectable")
    for commander_id in before:
        check(state.commander_progress.record(commander_id) == before[commander_id], "constructing and focusing cosmetic cards never changes progression")
    row.queue_free()
    var room = load("res://scenes/online/private_room.tscn").instantiate()
    root.add_child(room)
    var buff: Dictionary = db.get_all_buffs()[0]
    room._render_offers({"round": 2, "revision": 1, "offer": [{"type": "buff", "id": buff["id"]}], "self": {"buffs": [{"definition": buff, "stacks": 2}]}})
    check(room.offers.get_child(0).stacks == 2, "private blessing uses the supplied public self projection, without reading authoritative draft state")
    room.queue_free()
    if not failed:
        print("Fantasy interface tests passed: compact material controls, source/pack scenery and font, all five blessing layouts and keyboard focus, no progression writes.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
