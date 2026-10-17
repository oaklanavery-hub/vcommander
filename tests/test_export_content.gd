extends SceneTree
const Art = preload("res://scripts/presentation/pixel_unit_art.gd")
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db = root.get_node("ContentDatabase")
    check(db.load_errors.is_empty(), "content loads without errors")
    check(db.get_all_commanders().size() == 3 and db.get_all_cards().size() == 12, "export retains all roster JSON")
    check(db.get_all_buffs().size() == 5 and not db.get_game_balance().is_empty(), "export retains Buffs and balance")
    check(Art.catalog().get("sprites", {}).size() == 13, "export retains pixel art catalog")
    for card in db.get_all_cards():
        var picture := Art.icon(str(card["id"]), str(card["role"]), str(card["element"]))
        check(picture.get_width() == 64 and picture.get_height() == 64, "all detailed roster portraits available")
        check(picture is AtlasTexture, "roster uses the detailed atlas instead of a fallback")
    var plant := Art.icon("commander_plant")
    check(plant is AtlasTexture and plant.get_width() == 64, "summoned plant art is included")
    for commander in db.get_all_commanders():
        var portrait := CommanderArt.icon(str(commander["element"]))
        check(portrait.get_width() == 128 and portrait.get_height() == 192, "all detailed full-body Commander portraits available in export")
        check(portrait is AtlasTexture, "Commanders use the detailed atlas instead of a fallback")
    if not failed:
        print("Export content tests passed: roster, buffs, balance and portraits.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
