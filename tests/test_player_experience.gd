extends SceneTree

var failed := false
var _audio
var _menu
var _original: Dictionary = {}
var _had_settings := false
var _settings_bytes := PackedByteArray()

func _init() -> void:
    call_deferred("run")

func open_scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    await process_frame
    await process_frame
    return current_scene

func check_modal() -> void:
    var panel: Control = _menu._body.get_parent().get_parent()
    var bounds := panel.get_global_rect()
    check(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= 1281 and bounds.end.y <= 721, "modal fits desktop: " + str(bounds))

func run() -> void:
    root.size = Vector2i(1280, 720)
    _audio = root.get_node("GameAudio")
    _menu = root.get_node("GameMenu")
    var state = root.get_node("GameState")
    _had_settings = FileAccess.file_exists(_audio.SETTINGS_PATH)
    if _had_settings:
        _settings_bytes = FileAccess.get_file_as_bytes(_audio.SETTINGS_PATH)
    for key in ["music_volume", "effects_volume", "reduced_motion", "show_hp_numbers"]:
        _original[key] = _audio.get(key)
    var title = await open_scene("res://scenes/main_menu/main_menu.tscn")
    check(not title.play_button.disabled, "title has a playable entry point")
    check(title.get_node("Margin/Main").get_global_rect().end.x <= 1281, "title fits desktop")
    _menu.open_help()
    await process_frame
    await process_frame
    check_modal()
    check(paused, "help pauses the scene")
    _menu.close()
    check(not paused, "closing help restores prior pause state")
    _menu.open_settings()
    await process_frame
    await process_frame
    check_modal()
    _audio.set_music_volume(0.2)
    _audio.set_effects_volume(0.3)
    _audio.reduced_motion = true
    _audio.save_settings()
    _audio.music_volume = 1.0
    _audio.effects_volume = 1.0
    _audio.reduced_motion = false
    _audio.load_settings()
    check(is_equal_approx(_audio.music_volume, 0.2) and is_equal_approx(_audio.effects_volume, 0.3) and _audio.reduced_motion, "audio and accessibility preferences persist")
    _menu.close()
    title.start_game()
    await scene_changed
    await process_frame
    check(current_scene.name == "CommanderSelect", "Play opens Commander choice")
    check(_audio._music.playing, "music starts after player interaction")
    current_scene._open_army_builder()
    await scene_changed
    await process_frame
    check(state.army.is_full(), "first-time flow equips a valid starter warband")
    check(not current_scene.begin_draft_button.disabled, "starter warband can begin immediately")
    await process_frame
    await process_frame
    var collection: Control = current_scene.get_node("Margin/Main/CardScroll")
    check(collection.size.y >= 104, "companion collection remains visible, not collapsed")
    var visible_cards := 0
    for button in current_scene.available_card_buttons.values():
        if button.visible:
            visible_cards += 1
    check(visible_cards == 12, "collection initially shows all available companions")
    current_scene._toggle_filter()
    visible_cards = 0
    for button in current_scene.available_card_buttons.values():
        if button.visible:
            visible_cards += 1
    check(visible_cards == 4, "Commander theme filter narrows the collection")
    current_scene._toggle_filter()
    check(state.begin_match(1729), "starter match can begin")
    var draft = await open_scene("res://scenes/draft/draft.tscn")
    var points: int = state.draft.selection_points
    var time_left: float = draft._time_left
    _menu.open_pause()
    await create_timer(0.06, true).timeout
    check(is_equal_approx(draft._time_left, time_left) and state.draft.selection_points == points, "menu does not consume draft time or selections")
    _menu.confirm_leave()
    check(state.match_started, "opening leave confirmation preserves active match")
    _menu.close()
    check(state.match_started and not paused, "cancelling leave resumes same match")
    _audio.set_context("battle")
    check(_audio._playing_context == "battle" and _audio._music.stream.get_length() > 30, "battle uses its original looping score")
    _audio.set_context("menu")
    check(_audio._music.stream.get_length() > 30 and _audio._music.stream.loop, "menu score loops")
    for cue in _audio.EFFECTS:
        check(_audio._effect_streams[cue].get_length() > 0, "sound effect available in source/export: " + cue)
    _menu.confirm_leave()
    _menu._leave()
    await scene_changed
    await process_frame
    check(current_scene.name == "MainMenu" and not state.match_started and not paused, "confirmed leave returns to a usable title")
    for key in _original:
        _audio.set(key, _original[key])
    _audio.set_music_volume(_original["music_volume"])
    _audio.set_effects_volume(_original["effects_volume"])
    if _had_settings:
        var file := FileAccess.open(_audio.SETTINGS_PATH, FileAccess.WRITE)
        file.store_buffer(_settings_bytes)
        file.close()
    else:
        DirAccess.remove_absolute(_audio.SETTINGS_PATH)
    if not failed:
        print("Player experience tests passed: title flow, modal bounds, pause/exit safety, saved preferences and all audio assets.")
    _audio.stop_all()
    await create_timer(0.1, true).timeout
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
