extends CanvasLayer

var overlay := Control.new()
var _body: VBoxContainer
var _previous_pause := false
var _previous_focus: Control
var _leave_target := "res://scenes/main_menu/main_menu.tscn"

func _ready() -> void:
    layer = 50
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.hide()
    _apply_accessibility()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
        return
    if overlay.visible:
        close()
    elif get_tree().current_scene != null and get_tree().current_scene.name != "MainMenu":
        open_pause()
    get_viewport().set_input_as_handled()

func _page(title: String, subtitle: String) -> void:
    if not overlay.visible:
        _previous_pause = get_tree().paused
        _previous_focus = get_viewport().gui_get_focus_owner()
    for child in overlay.get_children():
        overlay.remove_child(child)
        child.queue_free()
    overlay.show()
    get_tree().paused = true
    var dimmer := ColorRect.new()
    dimmer.color = Color(0.02, 0.05, 0.04, 0.86)
    overlay.add_child(dimmer)
    dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    overlay.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(650, 0)
    center.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 28)
    panel.add_child(margin)
    _body = VBoxContainer.new()
    _body.add_theme_constant_override("separation", 10)
    margin.add_child(_body)
    _body.add_child(ScreenStyle.label(title, 32))
    var description := ScreenStyle.label(subtitle, 17)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(description)
    _body.add_child(HSeparator.new())

func _button(text: String, callback: Callable, primary := false) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 46
    button.pressed.connect(callback)
    if primary:
        ScreenStyle.primary(button)
    _body.add_child(button)
    return button

func open_pause() -> void:
    _page("A moment by the campfire", "The online match continues while this menu is open. Shared battles stay at 1×." if OnlineSession.active else "Your adventure can wait a moment. Take your time.")
    _button("Resume game", close, true).grab_focus()
    _button("Settings", open_settings)
    _button("How to play", open_help)
    _button("Return to title", confirm_leave)

func open_settings() -> void:
    _page("Make yourself comfortable", "Music, sound and accessibility settings are saved on this device.")
    _volume("Music", GameAudio.music_volume, GameAudio.set_music_volume)
    _volume("Sound effects", GameAudio.effects_volume, GameAudio.set_effects_volume)
    var motion := CheckButton.new()
    motion.text = "Reduced motion"
    motion.button_pressed = GameAudio.reduced_motion
    motion.toggled.connect(func(value: bool):
        GameAudio.reduced_motion = value
        _apply_accessibility())
    _body.add_child(motion)
    var hp := CheckButton.new()
    hp.text = "Show health numbers"
    hp.button_pressed = GameAudio.show_hp_numbers
    hp.toggled.connect(func(value: bool):
        GameAudio.show_hp_numbers = value
        _apply_accessibility())
    _body.add_child(hp)
    _button("Done", _back_from_page, true).grab_focus()

func _volume(title: String, value: float, callback: Callable) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    var label := ScreenStyle.label(title)
    label.custom_minimum_size.x = 150
    row.add_child(label)
    var slider := HSlider.new()
    slider.name = title.replace(" ", "")
    slider.min_value = 0
    slider.max_value = 100
    slider.step = 5
    slider.value = value * 100
    slider.custom_minimum_size = Vector2(280, 34)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.tooltip_text = title + " volume. Set to zero to mute."
    slider.value_changed.connect(func(amount: float): callback.call(amount / 100.0))
    row.add_child(slider)
    var amount := ScreenStyle.label("%d%%" % int(value * 100))
    amount.custom_minimum_size.x = 50
    slider.value_changed.connect(func(number: float): amount.text = "%d%%" % int(number))
    row.add_child(amount)
    _body.add_child(row)

func _apply_accessibility() -> void:
    BattlefieldView.reduced_motion = GameAudio.reduced_motion
    BattlefieldView.show_hp_numbers = GameAudio.show_hp_numbers
    GameAudio.settings_changed.emit()

func open_help() -> void:
    _page("Your first adventure", "Build a little warband. Make a few choices. Let your army do the fighting.")
    _body.add_theme_constant_override("separation", 8)
    var steps := [
        ["1   Choose a Commander", "Fire, Water, Earth or Slime. Start with their four-card warband, or mix your own."],
        ["2   Grow your army", "Choose from three cards each pick. Spend all your picks, then start the battle. Armies and buffs stay with you."],
        ["3   Watch the battle", "Your units fight automatically. Each side has four hearts. Take your rival's last heart to win; draws cost both sides a heart."],
        ["A little magic helps", "Your Commander skill costs one pick. Use it once per round and twice per match. Losing a round gives you an extra pick next round."]
    ]
    for step in steps:
        _body.add_child(ScreenStyle.label(step[0], 20))
        var detail := ScreenStyle.label(step[1], 16)
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(detail)
    var mastery := ScreenStyle.label("Mastery: full-match win +100 XP · loss +25 XP · 250 XP per level. Leaving after battle begins counts as a loss with no XP.", 14)
    mastery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(mastery)
    _body.add_child(ScreenStyle.label("30 seconds per pick • Esc: menu • Space: pause battle • 1 / 2 / 4: speed", 14))
    _button("Got it", _back_from_page, true).grab_focus()

func _back_from_page() -> void:
    GameAudio.save_settings()
    if get_tree().current_scene != null and get_tree().current_scene.name != "MainMenu":
        open_pause()
    else:
        close()

func confirm_leave(target: String = "res://scenes/main_menu/main_menu.tscn") -> void:
    _leave_target = target
    if OnlineSession.active and OnlineSession.client.state.get("phase") != "complete":
        _page("Leave this friend match?", "Your seat is held for 60 seconds after disconnecting. If you do not return, you forfeit. Friend playtests do not affect mastery or rank.")
        _button("Keep playing", close, true).grab_focus()
        _button("Leave match", _leave)
        return
    if not GameState.match_started or GameState.match_state.is_complete():
        _leave()
        return
    var message := "Your current match will end. No match record is counted before your first battle."
    if not GameState.commander_progress.active_match().is_empty():
        message = "Leaving now counts as a loss for this Commander and grants no mastery XP. Earned mastery levels will be kept."
    _page("Leave this match?", message)
    _button("Keep playing", close, true).grab_focus()
    _button("Leave match", _leave)

func _leave() -> void:
    close()
    if OnlineSession.active:
        OnlineSession.leave()
    GameState.leave_match()
    get_tree().change_scene_to_file(_leave_target)

func close() -> void:
    if not overlay.visible:
        return
    overlay.hide()
    get_tree().paused = _previous_pause
    GameAudio.save_settings()
    if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()
