extends SceneTree

var failed := false
const STORAGE := "user://test_warband_presets.cfg"

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    DirAccess.remove_absolute(STORAGE)
    var db = root.get_node("ContentDatabase")
    var state = root.get_node("GameState")
    var store := WarbandPresets.new(db, STORAGE)
    var fire: Array[String] = []
    for card in db.get_cards_by_set("set_fire_01"):
        fire.append(str(card["id"]))
    var mixed: Array[String] = [fire[0], fire[1], "card_water_01", "card_earth_01"]
    check(store.save_slot("commander_fire_01", 0, mixed) == OK, "mixed-element warband can be saved")
    check(WarbandPresets.new(db, STORAGE).load_slot("commander_fire_01", 0) == mixed, "new service instance restores exact card IDs and order")
    check(store.load_slot("commander_water_01", 0).is_empty(), "preset slots are independent per Commander")
    var duplicate: Array[String] = [fire[0], fire[0], fire[1], fire[2]]
    var missing: Array[String] = [fire[0], fire[1], fire[2], "unknown_card"]
    var short: Array[String] = [fire[0]]
    check(store.save_slot("commander_fire_01", 0, duplicate) != OK, "duplicate-card save rejected")
    check(store.save_slot("commander_fire_01", 0, missing) != OK, "unknown-card save rejected")
    check(store.save_slot("commander_fire_01", 0, short) != OK, "incomplete save rejected")
    check(store.save_slot("commander_fire_01", 3, fire) != OK, "only three slots allowed")
    check(store.load_slot("commander_fire_01", 0) == mixed, "invalid saves cannot overwrite a valid preset")
    var config := ConfigFile.new()
    config.load(STORAGE)
    config.set_value("commander_fire_01", "preset_1", missing)
    config.save(STORAGE)
    check(store.load_slot("commander_fire_01", 1).is_empty(), "stale or malformed saved content is ignored")
    state.select_commander("commander_fire_01")
    state.clear_army()
    for id in fire:
        state.equip_card(id)
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await process_frame
    await process_frame
    var builder = current_scene
    builder.preset_store = store
    builder._load_preset(0)
    check(state.army.get_cards() == mixed, "preset UI loads through existing army rules")
    builder._card_pressed(mixed[0])
    check(state.army.size() == 3 and builder.begin_draft_button.disabled, "collection selection can remove a card and disables Battle")
    var current: Array[String] = state.army.get_cards()
    builder._load_preset(1)
    check(state.army.get_cards() == current, "empty preset preserves in-progress warband")
    builder._card_pressed(mixed[0])
    builder._save_preset()
    var saved: Array[String] = state.army.get_cards()
    check(store.load_slot("commander_fire_01", 1) == saved, "Save writes the selected preset slot")
    builder._clear_army()
    check(state.army.size() == 0 and builder.begin_draft_button.disabled and builder.save_button.disabled, "Clear empties current selection and prevents invalid actions")
    check(store.load_slot("commander_fire_01", 1) == saved, "Clear preserves saved warbands")
    builder._load_preset(1)
    check(state.army.get_cards() == saved and not builder.begin_draft_button.disabled, "saved warband restores playable selection")
    check(builder.cards_grid.columns == 8, "collection matches the eight-card reference row")
    for index in range(builder.filter_select.item_count):
        if str(builder.filter_select.get_item_metadata(index)) == "water":
            builder.filter_select.select(index)
            builder._select_filter(index)
    var visible := 0
    for button in builder.available_card_buttons.values():
        if button.visible:
            visible += 1
            check(button.definition.get("element") == "water", "element filter matches visible cards")
    check(visible == 4, "element filter reveals all four matching cards")
    await process_frame
    await process_frame
    var bounds: Rect2 = builder.get_node("Margin/Main").get_global_rect()
    check(bounds.end.x <= 1281 and bounds.end.y <= 721, "reference builder layout fits desktop")
    DirAccess.remove_absolute(STORAGE)
    if not failed:
        print("Warband preset tests passed: three local slots, validation, mixed armies, safe loading/clearing, filtering and reference layout.")
    await process_frame
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
