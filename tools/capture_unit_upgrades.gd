extends "res://tools/capture_battle_fx.gd"

func gallery(element: String) -> void:
    var previous := current_scene
    var scene := Control.new()
    root.add_child(scene)
    current_scene = scene
    scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if previous != null:
        previous.queue_free()
    load("res://scripts/presentation/screen_style.gd").apply(scene)
    var margin := MarginContainer.new()
    scene.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 28)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    margin.add_child(body)
    body.add_child(load("res://scripts/presentation/screen_style.gd").label(element.capitalize() + " companions · original and Lv. 2", 30))
    var db := root.get_node("ContentDatabase")
    var cards: Array = db.get_cards_by_set("set_" + element + "_01")
    for level in [1, 2]:
        body.add_child(load("res://scripts/presentation/screen_style.gd").label("LV. %d" % level, 18))
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        body.add_child(row)
        for base in cards:
            var card: Dictionary = base if level == 1 else UnitUpgrades.changed_card(base, db.get_upgrade_rules()["units"][base["id"]])
            var tile = load("res://scripts/presentation/card_tile.gd").new()
            tile.set_content(card)
            tile.custom_minimum_size = Vector2(184, 238)
            row.add_child(tile)
            var texture: Texture2D = load("res://scripts/presentation/pixel_unit_art.gd").icon(str(card["id"]), str(card["role"]), element, level)
            var picture := texture.get_image()
            if picture == null or picture.get_used_rect().size == Vector2i.ZERO or picture.get_pixel(0, 0).a > 0.01:
                push_error("Missing/opaque portrait in native renderer: " + str(card["id"]))
    await save_image("upgrades_roster_" + element)

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    var menu := root.get_node("GameMenu")
    var audio := root.get_node("GameAudio")
    state.commander_progress = CommanderProgress.new(db, "")
    state.local_store = LocalMatchStore.new("")
    audio.set_interface_text_scale(1.0)
    for element in ["fire", "water", "earth", "slime"]:
        await gallery(element)
    state.select_commander("commander_fire_01")
    state.equip_starter_army()
    for index in range(2):
        state.commander_progress.finish_match(state.commander_progress.begin_match("commander_fire_01"), "win")
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    await save_image("upgrades_main_menu")
    current_scene.find_child("UnitForge", true, false).pressed.emit()
    await scene_changed
    current_scene.select_unit("card_fire_01")
    await save_image("upgrades_forge_first")
    current_scene.purchase_button.pressed.emit()
    await save_image("upgrades_forge_owned")
    current_scene.unit_buttons["card_fire_02"].pressed.emit()
    await save_image("upgrades_forge_shortfall")
    current_scene.filter_select.select(1)
    current_scene.filter_select.item_selected.emit(1)
    await save_image("upgrades_forge_filtered")
    current_scene.filter_select.select(0)
    current_scene.filter_select.item_selected.emit(0)
    current_scene.unit_buttons["card_water_06"].grab_focus()
    for index in range(5):
        await process_frame
    current_scene.collection_scroll.scroll_vertical = int(current_scene.collection_scroll.get_v_scroll_bar().max_value)
    await save_image("upgrades_forge_scrolled")
    root.size = Vector2i(960, 540)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.2)
    current_scene.select_unit("card_slime_06")
    await save_image("upgrades_forge_compact")
    current_scene.unit_buttons["card_water_06"].grab_focus()
    for index in range(5):
        await process_frame
    current_scene.collection_scroll.scroll_vertical = int(current_scene.collection_scroll.get_v_scroll_bar().max_value)
    await save_image("upgrades_forge_compact_action")
    current_scene.back_button.pressed.emit()
    await scene_changed
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.0)
    for commander in db.get_all_commanders():
        for index in range(25):
            state.commander_progress.finish_match(state.commander_progress.begin_match(str(commander["id"])), "win")
    for card in db.get_all_cards():
        if state.commander_progress.unit_level(str(card["id"])) == 1:
            if not state.purchase_unit_upgrade(str(card["id"]), state.commander_progress.upgrade_cost()).get("ok", false):
                push_error("Native fixture purchase failed: " + str(card["id"]))
                quit(1)
                return
    var rosters := {"fire": [1, 3, 4, 6], "water": [1, 2, 4, 6], "earth": [1, 2, 5, 6], "slime": [1, 3, 5, 6]}
    for element in rosters:
        state.leave_match()
        state.select_commander("commander_" + element + "_01")
        state.clear_army()
        for number in rosters[element]:
            state.equip_card("card_%s_%02d" % [element, number])
        state.begin_match(1729)
        while not state.draft.is_phase_complete():
            state.draft.auto_select()
        for card in db.get_cards_by_ids(state.army.get_cards()):
            state.draft.unit_counts[card["id"]] = 2
        state.run_battle()
        change_scene_to_file("res://scenes/combat/combat.tscn")
        await scene_changed
        current_scene.set_process(false)
        current_scene._advance_prelude(BattlePrelude.DURATION)
        var time := minf(6, current_scene._duration * 0.5)
        for event in current_scene._events:
            if (element == "earth" and event.get("kind") == "upgrade_root") or (element == "fire" and event.get("kind") == "upgrade_ground_fire") or (element == "slime" and event.get("kind") == "upgrade_death_field"):
                time = float(event["time"]) + 0.2
                break
        seek(current_scene, time)
        await save_image("upgrades_battle_" + element)
        if element == "earth":
            for unit in current_scene.battlefield._frame.get("units", []):
                if unit.get("unit_level") == 2:
                    current_scene._inspect_unit(unit)
                    break
            await save_image("upgrades_inspection")
    print("Unit upgrade native captures saved: 24 original/Lv. 2 comparisons, actual forge purchase/shortfall, compact larger-text actions, four upgraded battles and recorded inspection.")
    quit(0)
