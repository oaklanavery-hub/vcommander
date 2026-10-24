extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func settle_layout() -> void:
    for index in range(5):
        await process_frame

func run() -> void:
    root.size = Vector2i(1280, 720)
    root.content_scale_size = root.size
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    var menu := root.get_node("GameMenu")
    var audio := root.get_node("GameAudio")
    audio.settings_path = ""
    state.commander_progress = CommanderProgress.new(db, "")
    state.local_store = LocalMatchStore.new("")
    for index in range(6):
        state.commander_progress.finish_match(state.commander_progress.begin_match("commander_fire_01"), "win")
    var mastery: Dictionary = state.commander_progress.record("commander_fire_01")
    state.select_commander("commander_fire_01")
    state.equip_starter_army()
    var army: Array = state.army.get_cards().duplicate()
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    var entry: Button = current_scene.find_child("UnitForge", true, false)
    check(entry != null and current_scene.find_child("Achievements", true, false) != null, "title has separate Forge and Rewards buttons")
    entry.pressed.emit()
    await scene_changed
    await settle_layout()
    var forge = current_scene
    check(forge.name == "UnitForge" and not menu.overlay.visible and not paused, "main-menu Forge opens its own active screen")
    check(forge.unit_buttons.size() == 24 and forge.cards_grid.columns == 8, "desktop collection has all 24 units in eight columns")
    forge.unit_buttons["card_fire_01"].pressed.emit()
    var purchase: Button = forge.purchase_button
    check(not purchase.disabled and purchase.text.contains("200 XP") and forge.discount_label.visible, "first purchase shows its exact cost and bonus")
    check(forge.original_tile.definition.get("unit_level", 1) == 1 and forge.upgraded_tile.portrait.definition["unit_level"] == 2, "recipe compares real original and upgraded artwork")
    var gallery_clock: int = forge.collection_scroll.scroll_vertical
    purchase.pressed.emit()
    await settle_layout()
    check(state.commander_progress.upgrade_balance() == 400 and state.commander_progress.unit_level("card_fire_01") == 2, "actual Forge button spends once and grants the selected unit")
    check(state.commander_progress.record("commander_fire_01") == mastery, "purchases preserve lifetime mastery, levels, records and rewards")
    check(forge.unit_buttons["card_fire_01"].portrait.definition["unit_level"] == 2 and purchase.disabled, "owned gallery artwork refreshes immediately without duplicate purchases")
    check(forge.collection_scroll.scroll_vertical == gallery_clock, "purchase retains the gallery position")
    forge.unit_buttons["card_fire_02"].pressed.emit()
    check(not purchase.disabled and purchase.text.contains("400 XP") and not forge.discount_label.visible, "later purchases quote 400 XP without the first-purchase bonus")
    purchase.pressed.emit()
    await settle_layout()
    check(state.commander_progress.upgrade_balance() == 0 and state.commander_progress.upgraded_unit_ids().size() == 2, "second purchase charges its quoted cost")
    forge.select_unit("card_fire_03")
    check(purchase.disabled and forge.notice_label.text.contains("400 more XP"), "shortfall feedback shows the exact missing XP")
    var water_filter := 0
    for index in range(forge.filter_select.item_count):
        if forge.filter_select.get_item_metadata(index) == "water":
            water_filter = index
    forge.filter_select.select(water_filter)
    forge.filter_select.item_selected.emit(water_filter)
    check(forge.unit_buttons.values().filter(func(tile): return tile.visible).size() == 6, "Commander filter shows exactly its six unit cards")
    forge.unit_buttons["card_water_06"].pressed.emit()
    check(purchase.disabled and forge.notice_label.text.contains("Unlock"), "locked gallery cards preview their upgrade and mastery requirement")
    forge.back_button.pressed.emit()
    await scene_changed
    check(current_scene.name == "MainMenu" and state.army.get_cards() == army and state.selected_commander_id == "commander_fire_01", "Back returns to the title without changing the chosen Commander or army")
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    current_scene.find_child("UnitForge", true, false).pressed.emit()
    await scene_changed
    current_scene.back_button.pressed.emit()
    await scene_changed
    check(current_scene.name == "ArmyBuilder" and current_scene.available_card_buttons["card_fire_01"].portrait.definition["unit_level"] == 2 and state.army.get_cards() == army, "builder shortcut returns to the same owned warband")
    check(state.begin_match(121), "upgraded adventure starts after browsing")
    var snapshot: Dictionary = state.draft.snapshot().duplicate(true)
    load("res://scripts/presentation/unit_upgrade_forge.gd").open(self, "res://scenes/main_menu/main_menu.tscn", "card_fire_03")
    await scene_changed
    forge = current_scene
    await settle_layout()
    check(forge.purchase_button.disabled and forge.notice_label.text.contains("current adventure"), "pending adventures remain visibly protected")
    root.size = Vector2i(960, 540)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.2)
    forge.select_unit("card_slime_06")
    await settle_layout()
    var viewport := Rect2(Vector2.ZERO, Vector2(root.size)).grow(1)
    for control in [forge.margin, forge.summary, forge.back_button, forge.purchase_button, forge.filter_select, forge.balance_label, forge.collection_scroll]:
        check(viewport.encloses(control.get_global_rect()), "compact larger-text layout stays inside the viewport: " + str(control.name) + " " + str(control.get_global_rect()))
    var last_tile = forge.unit_buttons["card_water_06"]
    last_tile.grab_focus()
    await settle_layout()
    check(last_tile.has_focus() and forge.collection_scroll.scroll_vertical > 0, "keyboard focus scrolls the complete gallery")
    forge.back_button.pressed.emit()
    await scene_changed
    check(current_scene.find_child("ContinueAdventure", true, false) != null and state.draft.snapshot() == snapshot and state.commander_progress.record("commander_fire_01") == mastery, "browsing a saved adventure preserves Continue, draft/RNG and mastery")
    for card in db.get_all_cards():
        var id := str(card["id"])
        var original: AtlasTexture = load("res://scripts/presentation/pixel_unit_art.gd").icon(id)
        var evolved: AtlasTexture = load("res://scripts/presentation/pixel_unit_art.gd").icon(id, str(card["role"]), str(card["element"]), 2)
        check(original != null and evolved != null and original.atlas.resource_path != evolved.atlas.resource_path and evolved.region.size == Vector2(64, 64), "every unit has separate, bounded Lv. 2 art: " + id)
    var replay := BattleReplay.new()
    var events: Array = []
    for time in [0, 2, 4]:
        events.append({"time": time, "type": "ability", "kind": "upgrade_ground_fire", "area": {"created_at": time, "duration": 5, "refresh_key": "dragon:1", "x": time}})
    replay.configure([], events)
    check(replay.death_areas_at(-0.01).is_empty(), "ground fire cannot appear before its recorded hit")
    check(replay.death_areas[0]["replaced_at"] == 2 and replay.death_areas_at(3).size() == 1 and replay.death_areas_at(3)[0]["x"] == 2, "later refreshes cannot extend or duplicate an old field")
    check(replay.death_areas_at(4).size() == 1 and replay.death_areas_at(9).is_empty(), "new field replaces the old at its exact time and expires normally")
    for kind in ["upgrade_pulse", "ice_splinter", "upgrade_ground_fire", "upgrade_death_heal", "upgrade_death_field", "upgrade_root"]:
        var sound := CombatCues.sound({"type": "ability", "kind": kind})
        check(not sound.is_empty() and audio.EFFECTS.has(sound), "upgrade cue uses a bundled sound: " + kind)
    if not failed:
        print("Unit upgrade presentation tests passed: separate title/Forge/Rewards navigation, reference recipe and eight-column gallery, actual 200/400 XP buttons, mastery preservation, filters, lock/shortfall/pending feedback, compact keyboard scrolling, safe builder/Continue return, all 24 art variants and exact field/SFX tracks.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
