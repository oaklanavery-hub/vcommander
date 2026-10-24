extends CanvasLayer

var overlay := Control.new()
var _body: VBoxContainer
var _previous_pause := false
var _previous_focus: Control
var _leave_target := "res://scenes/main_menu/main_menu.tscn"
var _leave_callback := Callable()
var _page_scroll: ScrollContainer
var _page_panel: PanelContainer

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
    elif get_tree().current_scene != null and get_tree().current_scene.name == "UnitForge":
        get_tree().current_scene.call("go_back")
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
    _page_panel = panel
    panel.custom_minimum_size = Vector2(minf(700, get_viewport().get_visible_rect().size.x - 48), 0)
    center.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 28)
    panel.add_child(margin)
    _body = VBoxContainer.new()
    _body.add_theme_constant_override("separation", 10)
    _page_scroll = ScrollContainer.new()
    _page_scroll.name = "MenuScroll"
    _page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _page_scroll.follow_focus = true
    margin.add_child(_page_scroll)
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _page_scroll.add_child(_body)
    _body.minimum_size_changed.connect(_fit_page)
    _body.add_child(ScreenStyle.label(title, 32))
    var description := ScreenStyle.label(subtitle, 17)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(description)
    _body.add_child(HSeparator.new())
    _fit_page.call_deferred()

func _fit_page() -> void:
    if not is_instance_valid(_page_scroll) or not is_instance_valid(_body):
        return
    var height := get_viewport().get_visible_rect().size.y
    _page_scroll.custom_minimum_size.y = minf(maxf(80, _body.get_combined_minimum_size().y), maxf(120, height - 104))

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

func _paragraph(text: String, size: int = 17) -> Label:
    var label := ScreenStyle.label(text, size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(label)
    return label

func open_warband_guide() -> void:
    _page("Your warband's plan", "Relationships to explore. These notes describe possibilities, not a predicted winner.")
    var cards := ContentDatabase.get_cards_by_ids(GameState.army.get_cards())
    var guide := WarbandGuide.analyze(cards, GameState.get_selected_signature_set())
    _paragraph(guide["theme"])
    _paragraph("Frontline: " + str(guide["frontline"]))
    for note in guide["notes"]:
        _paragraph(str(note["title"]), 20)
        _paragraph(str(note["text"]), 16)
    if guide["notes"].is_empty():
        _paragraph("Select companions to see how their abilities can work together.")
    _button("Ability glossary", open_ability_glossary)
    _button("Back to warband", close, true).grab_focus()

func open_ability_glossary() -> void:
    _page("Ability glossary", "A quick reference for the current collection. Card tooltips and battle inspection show each unit's exact values.")
    for entry in WarbandGuide.glossary():
        _paragraph(str(entry["name"]), 20)
        _paragraph(str(entry["explanation"]), 16)
    _button("Back to warband guide", open_warband_guide, true).grab_focus()

func open_settings() -> void:
    _page("Make yourself comfortable", "Music, sound and accessibility settings are saved on this device.")
    _volume("Music", GameAudio.music_volume, GameAudio.set_music_volume)
    _volume("Sound effects", GameAudio.effects_volume, GameAudio.set_effects_volume)
    var motion := CheckButton.new()
    _skin_toggle(motion)
    motion.text = "Reduced motion"
    motion.button_pressed = GameAudio.reduced_motion
    motion.toggled.connect(func(value: bool):
        GameAudio.reduced_motion = value
        _apply_accessibility())
    _body.add_child(motion)
    var hp := CheckButton.new()
    _skin_toggle(hp)
    hp.text = "Show health numbers"
    hp.button_pressed = GameAudio.show_hp_numbers
    hp.toggled.connect(func(value: bool):
        GameAudio.show_hp_numbers = value
        _apply_accessibility())
    _body.add_child(hp)
    var text_size := CheckButton.new()
    text_size.name = "LargerText"
    _skin_toggle(text_size)
    text_size.text = "Larger interface text"
    text_size.button_pressed = GameAudio.interface_text_scale > 1.0
    text_size.toggled.connect(func(value: bool):
        GameAudio.set_interface_text_scale(1.2 if value else 1.0)
        _fit_page.call_deferred())
    _body.add_child(text_size)
    _volume("Battle effects", GameAudio.effects_intensity, func(value: float):
        GameAudio.effects_intensity = maxf(0.35, value)
        _apply_accessibility(), 35)
    var difficulty_row := HBoxContainer.new()
    var difficulty_label := ScreenStyle.label("Next opponent", 16)
    difficulty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    difficulty_row.add_child(difficulty_label)
    var difficulty := OptionButton.new()
    difficulty.name = "OpponentDifficulty"
    difficulty.custom_minimum_size = Vector2(230, 40)
    for mode in MatchPreferences.DIFFICULTIES:
        difficulty.add_item(str(mode).capitalize())
    difficulty.select(MatchPreferences.DIFFICULTIES.find(GameState.match_preferences.difficulty))
    difficulty.disabled = GameState.has_pending_adventure()
    difficulty.tooltip_text = "Casual: gentler drafting. Standard: adapts to public armies. Veteran: more consistent counters. Same stats, collection and legal picks. Change before starting an adventure."
    difficulty.item_selected.connect(func(index: int):
        GameState.match_preferences.difficulty = MatchPreferences.DIFFICULTIES[index]
        GameState.match_preferences.save())
    difficulty_row.add_child(difficulty)
    _body.add_child(difficulty_row)
    var redraw := CheckButton.new()
    redraw.name = "RedrawExperiment"
    _skin_toggle(redraw)
    redraw.text = "Experimental redraw · next adventure"
    redraw.button_pressed = GameState.match_preferences.redraw_experiment
    redraw.disabled = GameState.has_pending_adventure()
    redraw.tooltip_text = "Optional PvAI test: both sides may redraw once each round without spending a pick or resetting the timer. Off by default."
    redraw.toggled.connect(func(value: bool):
        GameState.match_preferences.redraw_experiment = value
        GameState.match_preferences.save())
    _body.add_child(redraw)
    var specialization := CheckButton.new()
    specialization.name = "SpecializationExperiment"
    _skin_toggle(specialization)
    specialization.text = "Commander paths · prototype, next adventure"
    specialization.button_pressed = GameState.match_preferences.specialization_experiment
    specialization.disabled = GameState.has_pending_adventure() or OnlineSession.active
    specialization.tooltip_text = "Optional local PvAI prototype. From Round 3, both sides may spend one normal pick once per match on a commander path. Off by default; match-only ability changes."
    specialization.toggled.connect(func(value: bool):
        GameState.match_preferences.specialization_experiment = value
        GameState.match_preferences.save())
    _body.add_child(specialization)
    _button("Adventure insights", open_insights)
    _button("Developer access" + (" · Active" if GameState.developer_access.is_enabled() else ""), open_developer_access)
    _button("Done", _back_from_page, true)
    var first_control := _body.find_child("Music", true, false) as HSlider
    if first_control != null:
        first_control.grab_focus()

func open_insights() -> void:
    _page("Your adventure pace", "Recent adventures on this device. Samples are self-selected; differences do not establish that an experiment caused an outcome.")
    var summary := GameState.match_insights.summary()
    if int(summary["rounds"]) == 0:
        _body.add_child(ScreenStyle.label("Play an adventure to start collecting pacing observations.", 18))
    else:
        var text := "%d recent adventures · %d completed · %d battles\n\nAverage battle at 1×: %.1fs\nAverage active draft: %.1fs\nDrawn rounds: %d\nTime-limit draws: %d (%.1f%%)\nRepeated Sudden Death draws: %d\nActual battle viewing: %.1f minutes" % [summary["matches"], summary["completed"], summary["rounds"], summary["average_battle"], summary["average_draft"], summary["draws"], summary["timeouts"], summary["timeout_rate"], summary["sudden_draws"], float(summary["watch_seconds"]) / 60.0]
        var totals := ScreenStyle.label(text, 18)
        totals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(totals)
        _paragraph("Recorded builds: %d themed · %d mixed\nBattles with every army card capped: %d" % [summary["themed_matches"], summary["mixed_matches"], summary["army_capped_rounds"]], 16)
    for mode in [0, 1]:
        var sample := GameState.match_insights.summary(-1, mode)
        _paragraph("Commander paths %s: %d adventures · %.1fs average battle · %d time-limit draws" % ["on" if mode == 1 else "off", sample["matches"], sample["average_battle"], sample["timeouts"]], 16)
    for experiment in [0, 1]:
        var sample := GameState.match_insights.summary(experiment)
        var label := ScreenStyle.label("%s: %d adventures, %d battles, %.1fs average battle" % ["Standard draft" if experiment == 0 else "Redraw experiment", sample["matches"], sample["rounds"], sample["average_battle"]], 15)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(label)
    var note := ScreenStyle.label("Keeps the latest 30 adventures. Paused reading time is excluded; battle time at 1× and actual viewing time are separate. Small, self-selected samples do not establish which mode is better.", 14)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(note)
    _button("Back to settings", open_settings, true).grab_focus()

func open_specializations(on_selected: Callable) -> void:
    _page("Choose your commander's path", "Prototype · one normal pick, once per adventure, from Round 3. Changes last for this adventure and affect qualifying companions of any theme.")
    for id in GameState.draft.specialization_options:
        var branch: Dictionary = GameState.draft.specialization_options[id]
        _paragraph(str(branch["display_name"]), 22)
        _paragraph(str(branch["description"]), 17)
        var affected := CommanderSpecializations.affected(ContentDatabase.get_cards_by_ids(GameState.army.get_cards()), GameState.draft.unit_counts, branch)
        _paragraph("%d recruited companions benefit now. %s" % [affected["units"], "Applies to %s, including future recruits." % ", ".join(affected["types"]) if not affected["types"].is_empty() else "No matching abilities in this warband."], 15)
        var button := _button("Choose %s · 1 pick" % branch["display_name"], func():
            if GameState.draft.choose_specialization(str(branch["id"])):
                close()
                GameAudio.play_effect("pick")
                on_selected.call())
        button.name = str(id)
        button.tooltip_text = "\n\n".join(affected["details"])
        button.disabled = not GameState.draft.can_specialize(str(id))
    _button("Keep drafting", close, true).grab_focus()

func open_developer_access() -> void:
    _page("Developer access", "Use your private developer key to try the complete collection on this device. Mastery and achievements still follow your actual match record.")
    var enabled := GameState.developer_access.is_enabled()
    var status := ScreenStyle.label("All %d companions are available with developer access." % ContentDatabase.get_all_cards().size() if enabled else "Developer access is inactive. Normal mastery requirements apply.", 16)
    status.name = "DeveloperStatus"
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(status)
    if GameState.match_started or OnlineSession.active:
        var notice := ScreenStyle.label("Return to the title before changing collection access.", 16)
        notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(notice)
    elif enabled:
        var remove_button := _button("Remove developer access", func():
            if GameState.remove_developer_access() == OK:
                open_developer_access()
            else:
                status.text = "Could not remove the saved key. Please try again.")
        remove_button.name = "RemoveDeveloperAccess"
    else:
        var key := LineEdit.new()
        key.name = "DeveloperKey"
        key.placeholder_text = "Paste your private developer key"
        key.secret = true
        key.max_length = DeveloperAccess.MAX_KEY_LENGTH
        key.custom_minimum_size = Vector2(0, 44)
        _body.add_child(key)
        var activate := func():
            var error := GameState.activate_developer_access(key.text)
            if error == OK:
                key.clear()
                open_developer_access()
            else:
                status.text = "That developer key is not valid." if error == ERR_UNAUTHORIZED else "Could not save access. Please try again after returning to the title."
        var activate_button := _button("Activate", activate, true)
        activate_button.name = "ActivateDeveloperAccess"
        key.text_submitted.connect(func(_value: String): activate.call())
        key.grab_focus()
    var back := _button("Back to settings", open_settings)
    var key_input := _body.find_child("DeveloperKey", true, false)
    if key_input != null:
        key_input.grab_focus()
    else:
        back.grab_focus()

func _volume(title: String, value: float, callback: Callable, minimum: float = 0) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    var label := ScreenStyle.label(title)
    label.custom_minimum_size.x = 150
    row.add_child(label)
    var slider := HSlider.new()
    var grip := load("res://assets/ui/slider-grip.svg") as Texture2D
    slider.add_theme_icon_override("grabber", grip)
    slider.add_theme_icon_override("grabber_highlight", grip)
    slider.name = title.replace(" ", "")
    slider.min_value = minimum
    slider.max_value = 100
    slider.step = 5
    slider.value = value * 100
    slider.custom_minimum_size = Vector2(280, 34)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.tooltip_text = "Reduce decorative particles and flashes; projectiles, impacts and active areas stay visible." if minimum > 0 else title + " volume. Set to zero to mute."
    slider.value_changed.connect(func(amount: float): callback.call(amount / 100.0))
    row.add_child(slider)
    var amount := ScreenStyle.label("%d%%" % int(value * 100))
    amount.custom_minimum_size.x = 50
    slider.value_changed.connect(func(number: float): amount.text = "%d%%" % int(number))
    row.add_child(amount)
    _body.add_child(row)

func _skin_toggle(toggle: CheckButton) -> void:
    # The project theme loads before the editor imports new textures on a clean
    # checkout. Bind icon textures only when an actual settings page is opened.
    var enabled := load("res://assets/ui/toggle-on.svg") as Texture2D
    var disabled := load("res://assets/ui/toggle-off.svg") as Texture2D
    toggle.add_theme_icon_override("checked", enabled)
    toggle.add_theme_icon_override("unchecked", disabled)
    toggle.add_theme_icon_override("checked_disabled", enabled)
    toggle.add_theme_icon_override("unchecked_disabled", disabled)

func _apply_accessibility() -> void:
    BattlefieldView.reduced_motion = GameAudio.reduced_motion
    BattlefieldView.show_hp_numbers = GameAudio.show_hp_numbers
    BattleEffects.intensity = GameAudio.effects_intensity
    GameAudio.settings_changed.emit()

func open_help() -> void:
    _page("Your first adventure", "Build a little warband. Make a few choices. Let your army do the fighting.")
    _body.add_theme_constant_override("separation", 8)
    var steps := [
        ["1   Choose a Commander", "Fire, Water, Earth or Slime. Start with their four-card warband, or mix your own."],
        ["2   Grow your army", "Choose from three cards each pick. Spend all your picks, then start the battle. Armies and buffs stay with you."],
        ["3   Watch the battle", "Your units fight automatically. Each side has four hearts. Take your rival's last heart to win; draws cost both sides a heart. If both lose their final heart, Sudden Death begins: each battle has a 3-minute limit, and new power picks have double strength. Earlier bonuses stay unchanged."],
        ["A little magic helps", "Your Commander skill costs one pick. Use it once per round and twice per match. Losing a round gives you an extra pick next round."]
    ]
    for step in steps:
        _body.add_child(ScreenStyle.label(step[0], 20))
        var detail := ScreenStyle.label(step[1], 16)
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _body.add_child(detail)
    var mastery := ScreenStyle.label("Mastery: win +100 XP · loss +50 XP · 250 XP per level. Rewards: Lv. 3 + 3 wins, then Lv. 5 + 6 wins. Spend shared XP in the unit forge: first upgrade 200 XP, then 400 each. Spending keeps mastery. Leaving a played match: loss, no XP.", 14)
    mastery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _body.add_child(mastery)
    _body.add_child(ScreenStyle.label("30 seconds per pick • Esc: menu • Space: pause battle • 1 / 2 / 4: speed", 14))
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 12)
    _body.add_child(actions)
    var guided := Button.new()
    guided.name = "GuidedFirstMatch"
    guided.text = "Replay guided match" if FirstMatchGuide.completed else "Guided first match"
    guided.custom_minimum_size = Vector2(260, 46)
    guided.pressed.connect(_start_guided_match)
    guided.disabled = OnlineSession.active
    guided.tooltip_text = "A guide through a normal local match. Your usual match rules and mastery apply."
    actions.add_child(guided)
    var done := Button.new()
    done.text = "Got it"
    done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    done.custom_minimum_size.y = 46
    done.pressed.connect(_back_from_page)
    ScreenStyle.primary(done)
    actions.add_child(done)
    done.grab_focus()

func _start_guided_match() -> void:
    if not OnlineSession.active:
        confirm_leave("res://scenes/commander_select/commander_select.tscn", FirstMatchGuide.start)

func _back_from_page() -> void:
    GameAudio.save_settings()
    if get_tree().current_scene != null and get_tree().current_scene.name != "MainMenu":
        open_pause()
    else:
        close()

func confirm_leave(target: String = "res://scenes/main_menu/main_menu.tscn", after_leave: Callable = Callable()) -> void:
    _leave_target = target
    _leave_callback = after_leave
    if OnlineSession.active and OnlineSession.client.state.get("phase") != "complete":
        _page("Leave this friend match?", "Your seat is held for 60 seconds after disconnecting. If you do not return, you forfeit. Friend playtests do not affect mastery or rank.")
        _button("Keep playing", close, true).grab_focus()
        _button("Leave match", _leave)
        return
    if not GameState.has_pending_adventure() or (GameState.match_started and GameState.match_state.is_complete()):
        _leave()
        return
    var message := "Your current match will end. No match record is counted before your first battle."
    if not GameState.commander_progress.active_match().is_empty():
        message = "Leaving now counts as a loss for this Commander and grants no mastery XP. Earned mastery levels will be kept."
    _page("Leave this match?", message)
    _button("Keep playing", close, true).grab_focus()
    _button("Leave match", _leave)

func _leave() -> void:
    var callback := _leave_callback
    close()
    FirstMatchGuide.stop()
    if OnlineSession.active:
        OnlineSession.leave()
    GameState.leave_match()
    if callback.is_valid():
        callback.call()
    get_tree().change_scene_to_file(_leave_target)

func close() -> void:
    _leave_callback = Callable()
    if not overlay.visible:
        return
    overlay.hide()
    get_tree().paused = _previous_pause
    GameAudio.save_settings()
    if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()
