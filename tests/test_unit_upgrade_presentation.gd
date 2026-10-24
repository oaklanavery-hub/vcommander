extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func settle_layout() -> void:
    for index in range(4):
        await process_frame

func run() -> void:
    root.size = Vector2i(1280, 720)
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
    change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    await scene_changed
    await settle_layout()
    var tile = current_scene.available_card_buttons["card_fire_01"]
    check(int(tile.portrait.definition.get("unit_level", 1)) == 1, "original card starts with original artwork")
    menu.open_unit_upgrades("card_fire_01")
    await settle_layout()
    var purchase: Button = menu._body.find_child("Upgrade_card_fire_01", true, false)
    check(not purchase.disabled and purchase.text.contains("200 XP"), "first concrete purchase quotes 200 XP")
    var preview = menu._body.find_child("ForgeLevel2", true, false)
    check(preview.definition["unit_level"] == 2 and preview.portrait.definition["unit_level"] == 2, "unowned upgrade previews its actual Lv. 2 art")
    purchase.pressed.emit()
    await settle_layout()
    check(state.commander_progress.upgrade_balance() == 400 and state.commander_progress.unit_level("card_fire_01") == 2, "actual forge button spends once and grants the selected unit")
    check(state.commander_progress.record("commander_fire_01") == mastery, "actual purchase preserves mastery, levels, records and earned rewards")
    check(tile.definition["unit_level"] == 2 and tile.portrait.definition["unit_level"] == 2 and tile.tooltip_text.contains("Inferno Ring"), "existing army card and portrait update immediately after purchase")
    check(menu._body.find_child("Upgrade_card_fire_01", true, false).disabled, "owned upgrade cannot be purchased twice")
    menu.open_unit_upgrades("card_fire_02")
    await settle_layout()
    purchase = menu._body.find_child("Upgrade_card_fire_02", true, false)
    check(not purchase.disabled and purchase.text.contains("400 XP"), "next unit quotes 400 XP")
    purchase.pressed.emit()
    await settle_layout()
    check(state.commander_progress.upgrade_balance() == 0 and state.commander_progress.upgraded_unit_ids().size() == 2, "second actual purchase charges its quoted price")
    menu.open_unit_upgrades("card_fire_03")
    await settle_layout()
    check(menu._body.find_child("Upgrade_card_fire_03", true, false).disabled and menu._body.find_child("UpgradeNotice", true, false).text.contains("400 more XP"), "insufficient funds shows the exact shortfall")
    menu.open_unit_upgrades("card_water_06")
    await settle_layout()
    check(menu._body.find_child("Upgrade_card_water_06", true, false).disabled and menu._body.find_child("UpgradeNotice", true, false).text.contains("Unlock"), "locked companions remain previewable with clear mastery guidance")
    menu.close()
    check(state.begin_match(121), "upgraded adventure starts after the forge")
    menu.open_unit_upgrades("card_fire_03")
    await settle_layout()
    check(menu._body.find_child("Upgrade_card_fire_03", true, false).disabled and menu._body.find_child("UpgradeNotice", true, false).text.contains("current adventure"), "pending opening adventure blocks forge purchases visibly")
    root.size = Vector2i(960, 540)
    root.content_scale_size = root.size
    audio.set_interface_text_scale(1.2)
    menu.open_unit_upgrades("card_slime_06")
    await settle_layout()
    var bounds: Rect2 = menu._page_panel.get_global_rect()
    check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(bounds), "compact larger-text forge stays inside the viewport")
    var close_button: Button = menu._body.find_child("CloseForge", true, false)
    close_button.grab_focus()
    await settle_layout()
    check(close_button.has_focus() and menu._page_scroll.scroll_vertical > 0, "keyboard focus scrolls the final action into view")
    menu.close()
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
        print("Unit upgrade presentation tests passed: actual 200/400 XP buttons, mastery preservation, immediate portrait refresh, lock/shortfall/pending feedback, compact keyboard scrolling, all 24 art variants and exact field/SFX tracks.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
