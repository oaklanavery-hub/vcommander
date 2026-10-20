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
    margin.offset_top = 76
    margin.offset_right = -24
    margin.offset_bottom = -224
    var main := VBoxContainer.new()
    main.name = "Main"
    main.alignment = BoxContainer.ALIGNMENT_CENTER
    main.add_theme_constant_override("separation", 12)
    margin.add_child(main)
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
    play_button = _menu_button("Play", 56)
    play_button.name = "Play"
    ScreenStyle.primary(play_button)
    play_button.pressed.connect(start_game)
    main.add_child(play_button)
    var rewards := _menu_button("Achievements & rewards", 44)
    rewards.name = "Achievements"
    rewards.pressed.connect(func(): ProgressJournal.open(get_tree(), scene_file_path))
    main.add_child(rewards)
    var how := _menu_button("How to play", 44)
    how.pressed.connect(GameMenu.open_help)
    main.add_child(how)
    var settings := _menu_button("Settings", 44)
    settings.pressed.connect(GameMenu.open_settings)
    main.add_child(settings)
    play_button.grab_focus()

func _center_label(label: Label) -> void:
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _menu_button(text: String, height: float) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(320, height)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    var normal := ScreenStyle.frame(Color("14263a"), Color("7d8994"), 9)
    normal.set_border_width_all(1)
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("263f53")
    hover.border_color = Color("dfbd78")
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("0e1e30")
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    return button

func start_game() -> void:
    GameAudio.unlock()
    GameState.leave_match()
    get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
