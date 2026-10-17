extends Control

const Backdrop = preload("res://scripts/presentation/pixel_backdrop.gd")
var play_button: Button

func _ready() -> void:
    GameAudio.set_context("menu")
    var background := Backdrop.new()
    background.camp = true
    add_child(background)
    var shade := ColorRect.new()
    shade.color = Color(0.035, 0.09, 0.07, 0.78)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.anchor_right = 0.49
    var margin := MarginContainer.new()
    margin.name = "Margin"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 64
    margin.offset_top = 54
    margin.offset_right = -64
    margin.offset_bottom = -42
    var main := HBoxContainer.new()
    main.name = "Main"
    main.add_theme_constant_override("separation", 70)
    margin.add_child(main)
    var left := VBoxContainer.new()
    left.custom_minimum_size.x = 470
    left.alignment = BoxContainer.ALIGNMENT_CENTER
    left.add_theme_constant_override("separation", 16)
    main.add_child(left)
    var eyebrow := ScreenStyle.label("A LITTLE WARBAND. A GRAND ADVENTURE.", 14)
    eyebrow.add_theme_color_override("font_color", Color("dfbd78"))
    left.add_child(eyebrow)
    left.add_child(ScreenStyle.label("VCOMMANDER", 56))
    var subtitle := ScreenStyle.label("Gather your companions.\nMake your stand at the Verdant Crossing.", 20)
    left.add_child(subtitle)
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 18
    left.add_child(spacer)
    play_button = Button.new()
    play_button.name = "Play"
    play_button.text = "Play"
    play_button.custom_minimum_size.y = 68
    ScreenStyle.primary(play_button)
    play_button.pressed.connect(start_game)
    left.add_child(play_button)
    var how := Button.new()
    how.text = "How to play"
    how.custom_minimum_size.y = 48
    how.pressed.connect(GameMenu.open_help)
    left.add_child(how)
    var settings := Button.new()
    settings.text = "Settings"
    settings.custom_minimum_size.y = 48
    settings.pressed.connect(GameMenu.open_settings)
    left.add_child(settings)
    left.add_child(ScreenStyle.label("FIRE  ·  WATER  ·  EARTH", 15))
    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.alignment = BoxContainer.ALIGNMENT_END
    main.add_child(right)
    var caption := ScreenStyle.label("THE VERDANT CROSSING", 16)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    right.add_child(caption)
    var note := ScreenStyle.label("A cozy strategy showdown\nagainst a rival Commander", 17)
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    right.add_child(note)
    play_button.grab_focus()

func start_game() -> void:
    GameAudio.unlock()
    GameState.leave_match()
    get_tree().change_scene_to_file("res://scenes/commander_select/commander_select.tscn")
