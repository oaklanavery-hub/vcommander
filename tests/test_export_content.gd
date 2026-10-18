extends SceneTree
const Art = preload("res://scripts/presentation/pixel_unit_art.gd")
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db = root.get_node("ContentDatabase")
    check(db.load_errors.is_empty(), "content loads without errors")
    check(db.get_all_commanders().size() >= 4 and db.get_all_cards().size() >= 16, "export retains the starter roster and Slime expansion JSON")
    check(db.get_all_buffs().size() == 5 and not db.get_game_balance().is_empty(), "export retains Buffs and balance")
    check(Art.catalog().get("sprites", {}).size() == db.get_all_cards().size() + 1, "export retains every roster sprite and Commander plant")
    for card in db.get_all_cards():
        var picture := Art.icon(str(card["id"]), str(card["role"]), str(card["element"]))
        check(picture.get_width() == 64 and picture.get_height() == 64, "all detailed roster portraits available")
        check(picture is AtlasTexture, "roster uses the detailed atlas instead of a fallback")
        check_frame(picture, true)
    var plant := Art.icon("commander_plant")
    check(plant is AtlasTexture and plant.get_width() == 64, "summoned plant art is included")
    check_frame(plant, true)
    for commander in db.get_all_commanders():
        var portrait := CommanderArt.icon(str(commander["element"]))
        check(portrait.get_width() == 128 and portrait.get_height() == 192, "all detailed full-body Commander portraits available in export")
        check(portrait is AtlasTexture, "Commanders use the detailed atlas instead of a fallback")
        check_frame(portrait, false)
        var seated := PixelAtlasArt.icon("menu_commanders", str(commander["element"]))
        check(seated is AtlasTexture and seated.get_size() == Vector2(128, 128), "export retains each seated Commander")
        check_frame(seated, true)
    var scenery := load("res://assets/pixel/menu-camp-v1.png") as Texture2D
    check(scenery != null and scenery.get_size() == Vector2(640, 360), "export retains campfire scenery")
    if not failed:
        print("Export content tests passed: roster, buffs, balance and portraits.")
    quit(1 if failed else 0)

func check_frame(texture: Texture2D, require_gutter: bool) -> void:
    if not texture is AtlasTexture:
        return
    var atlas := texture as AtlasTexture
    var image := atlas.atlas.get_image().get_region(Rect2i(atlas.region))
    var mirrored := PixelAtlasArt.mirrored(texture)
    check(mirrored == PixelAtlasArt.mirrored(texture), "mirrored frames are cached")
    var mirror_image := mirrored.get_image()
    var visible := 0
    var gutter := true
    var matching_mirror := mirror_image.get_size() == image.get_size()
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var alpha := image.get_pixel(x, y).a
            if matching_mirror and image.get_pixel(x, y) != mirror_image.get_pixel(image.get_width() - 1 - x, y):
                matching_mirror = false
            if alpha > 0.05:
                visible += 1
            if require_gutter and (x == 0 or y == 0 or x == image.get_width() - 1 or y == image.get_height() - 1) and alpha > 0.01:
                gutter = false
    check(visible > 200, "atlas frame contains visible artwork")
    check(visible < image.get_width() * image.get_height() * 0.9, "atlas frame retains transparent background")
    check(gutter, "army frames have transparent outer gutters to avoid atlas bleed")
    check(matching_mirror, "left-facing art mirrors the exact frame without adjacent atlas content")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
