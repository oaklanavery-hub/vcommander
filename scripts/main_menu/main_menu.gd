extends Control

const Showcase = preload("res://scripts/presentation/commander_showcase.gd")
var play_button: Button

func _ready() -> void:
    GameAudio.set_context("menu")
    var scene := Showcase.new()
    scene.name = "CampfireScene"
    add_child(scene)
    var margin := MarginContainer.new()
    margin.name = "Margin"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 24
    margin.offset_top = 36
    margin.offset_right = -24
    margin.offset_bottom = -140
    var scroll := ScrollContainer.new()
    scroll.name = "Main"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    margin.add_child(scroll)
    var center := CenterContainer.new()
    center.name = "MenuCenter"
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.add_child(center)
    var main := VBoxContainer.new()
    main.name = "MenuContents"
    main.alignment = BoxContainer.ALIGNMENT_CENTER
    main.add_theme_constant_override("separation", 12)
    center.add_child(main)
    var eyebrow := ScreenStyle.label("THE VERDANT CROSSING", 14)
    eyebrow.add_theme_color_override("font_color", Color("c6bd9d"))
    _center_label(eyebrow)
    main.add_child(eyebrow)
    var title := ScreenStyle.label("VCOMMANDER", 60)
    title.name = "Title"
    title.add_theme_color_override("font_color", Color("f4d99d"))
    title.add_theme_color_override("font_outline_color", Color("0b1728"))
    title.add_theme_color_override("font_shadow_color", Color("08101c"))
    title.add_theme_constant_override("outline_size", 6)
    title.add_theme_constant_override("shadow_offset_y", 4)
    _center_label(title)
    main.add_child(title)
    var subtitle := ScreenStyle.label("A little warband. A grand adventure.", 18)
    subtitle.add_theme_color_override("font_color", Color("d5dce0"))
    _center_label(subtitle)
    main.add_child(subtitle)
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 8
    main.add_child(spacer)
    var can_continue: bool = GameState.has_saved_match()
    if can_continue:
        var continue_button := _menu_button("Continue adventure", 52)
        continue_button.name = "ContinueAdventure"
        ScreenStyle.primary(continue_button)
        continue_button.pressed.connect(_continue_adventure)
        main.add_child(continue_button)
    play_button = _menu_button("Play", 56)
    if GameState.has_pending_adventure():
        play_button.text = "New adventure"
    play_button.name = "Play"
    if not can_continue:
        ScreenStyle.primary(play_button)
    play_button.pressed.connect(start_game)
    main.add_child(play_button)
    if not FirstMatchGuide.completed:
        var guide := _menu_button("First adventure · guided", 44)
        guide.name = "GuidedFirstAdventure"
        guide.tooltip_text = "Learn through a normal adventure with optional paused notes. Uses the usual mastery and match rules."
        guide.pressed.connect(func(): GameMenu.confirm_leave("res://scenes/commander_select/commander_select.tscn", FirstMatchGuide.start))
        main.add_child(guide)
    var rewards := _menu_button("Rewards & unit forge", 44)
    rewards.name = "Achievements"
    rewards.pressed.connect(func(): ProgressJournal.open(get_tree(), scene_file_path))
    main.add_child(rewards)
    var how := _menu_button("How to play", 44)
    how.pressed.connect(GameMenu.open_help)
    main.add_child(how)
    var settings := _menu_button("Settings", 44)
    settings.pressed.connect(GameMenu.open_settings)
    main.add_child(settings)
    if not GameState.recovery_notice.is_empty():
        var notice := ScreenStyle.label(GameState.recovery_notice, 14)
        notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        main.add_child(notice)
    var continue_entry := main.get_node_or_null("ContinueAdventure") as Button
    (continue_entry if continue_entry != null else play_button).grab_focus()

func _center_label(label: Label) -> void:
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _menu_button(text: String, height: float) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(320, height)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    var normal := ScreenStyle.frame(Color("34312a"), Color("9a7d50"), 12)
    normal.set_border_width_all(1)
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    var hover := normal.duplicate() as FantasyFrame
    hover.bg_color = Color("514533")
    hover.border_color = Color("dfbd78")
    var pressed := normal.duplicate() as FantasyFrame
    pressed.bg_color = Color("29271f")
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    return button

func start_game() -> void:
    GameAudio.unlock()
    GameMenu.confirm_leave("res://scenes/commander_select/commander_select.tscn")

func _continue_adventure() -> void:
    GameAudio.unlock()
    if GameState.resume_match():
        get_tree().change_scene_to_file("res://scenes/draft/draft.tscn" if GameState.match_state.phase == "draft" else "res://scenes/combat/combat.tscn")
    else:
        play_button.tooltip_text = GameState.recovery_notice
