extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame

func run() -> void:
    root.size = Vector2i(1280, 720)
    var audio := root.get_node("GameAudio")
    var menu := root.get_node("GameMenu")
    check(audio.settings_path.is_empty(), "scripted presentation preferences are isolated from player storage")
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    await settle()
    check(current_scene.find_child("GuidedFirstAdventure", true, false) != null, "optional first adventure has a direct visible title entry")
    var play: Button = current_scene.play_button
    var original := play.get_theme_font_size("font_size")
    audio.set_interface_text_scale(1.2)
    await settle()
    check(play.get_theme_font_size("font_size") == roundi(original * 1.2), "body/control text enlarges without scaling the battlefield or art")
    audio.set_interface_text_scale(1.2)
    check(play.get_theme_font_size("font_size") == roundi(original * 1.2), "reapplying the preference never compounds font sizes")
    var label := Label.new()
    label.add_theme_font_size_override("font_size", 15)
    root.add_child(label)
    await settle()
    check(label.get_theme_font_size("font_size") == 18, "new interface controls inherit the selected text size")
    audio.set_interface_text_scale(1.0)
    check(play.get_theme_font_size("font_size") == original and label.get_theme_font_size("font_size") == 15, "standard size restores each original size exactly")
    label.queue_free()
    audio.set_interface_text_scale(1.2)
    for size_value in [Vector2i(1280, 720), Vector2i(960, 540)]:
        root.size = size_value
        root.content_scale_size = size_value
        await settle()
        menu.open_settings()
        await settle()
        var rect: Rect2 = menu._page_panel.get_global_rect()
        check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= size_value.x + 1 and rect.end.y <= size_value.y + 1, "large-text settings fit the viewport and scroll: " + str(rect))
        check(menu._page_scroll.get_v_scroll_bar().max_value > menu._page_scroll.size.y, "long settings scroll rather than extending off screen")
        check(menu._body.find_child("Battleeffects", true, false) != null and menu._body.find_child("LargerText", true, false) != null, "effects and text settings are exposed")
        menu.close()
    var normal := BattleEffects.particle_count(12)
    audio.effects_intensity = 0.35
    menu._apply_accessibility()
    check(BattleEffects.particle_count(12) < normal and BattleEffects.particle_count(1) == 1, "low intensity reduces decoration without deleting essential contact markers")
    audio.save_settings()
    audio.effects_intensity = 1.0
    audio.interface_text_scale = 1.0
    audio.load_settings()
    check(audio.effects_intensity == 0.35 and audio.interface_text_scale == 1.2, "new preferences round-trip independently of motion and sound")
    var state := root.get_node("GameState")
    state.select_commander("commander_fire_01")
    state.equip_starter_army()
    state.match_preferences.redraw_experiment = true
    state.begin_match(907)
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await settle()
    var arena: Control = current_scene.get_node("Margin/Main/Board/Padding/Arena")
    var offer_panel: Control = arena.get_node("DraftCenter/OfferPanel")
    check(arena.get_global_rect().grow(1).encloses(offer_panel.get_global_rect()), "compact large-text offers stay within the clearing rather than covering hearts or rosters")
    state.draft.opening_phase = false
    for card in root.get_node("ContentDatabase").get_cards_by_ids(state.army.get_cards()):
        state.draft.unit_counts[str(card["id"])] = int(card["unit_cap"])
    state.draft.buff_stacks["buff_attack_speed"] = 100
    state.draft.current_offer.assign([{"type": "buff", "id": "buff_attack_speed"}, {"type": "buff", "id": "buff_movement_speed"}, {"type": "buff", "id": "buff_attack"}])
    current_scene._refresh_all()
    await settle()
    check(arena.get_global_rect().grow(1).encloses(offer_panel.get_global_rect()), "compact power offers retain the same field boundary")
    for tile in current_scene.offer_row.get_children():
        check(tile.get_global_rect().grow(1).encloses(tile.benefit_label.get_global_rect()), "actual-benefit text remains inside its rounded card at large text size")
    state.leave_match()
    state.match_preferences.redraw_experiment = false
    audio.effects_intensity = 1.0
    audio.set_interface_text_scale(1.0)
    menu._apply_accessibility()
    audio.save_settings()
    if not failed:
        print("Accessibility tests passed: direct optional guidance, reversible/noncompounding text, new controls, scrolling small/desktop settings, reduced particles with retained contacts, isolated preference persistence.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
