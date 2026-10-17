class_name ScreenStyle
extends RefCounted

const Backdrop = preload("res://scripts/presentation/pixel_backdrop.gd")

static func apply(screen: Control) -> void:
    var background := Backdrop.new()
    screen.add_child(background)
    screen.move_child(background, 0)
    var main := screen.get_node_or_null("Margin/Main")
    if main == null:
        return
    var header := main.get_node_or_null("Header") as HBoxContainer
    if header == null:
        header = HBoxContainer.new()
        header.name = "TopBar"
        main.add_child(header)
        main.move_child(header, 0)
        var title := main.get_node_or_null("Title") as Label
        if title != null:
            title.reparent(header)
            title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var menu := Button.new()
    menu.name = "GameMenu"
    menu.text = "Menu"
    menu.custom_minimum_size = Vector2(88, 42)
    menu.tooltip_text = "Pause, help and settings (Esc)"
    menu.pressed.connect(GameMenu.open_pause)
    header.add_child(menu)
    GameAudio.set_context("battle" if screen.name == "Combat" else "menu")

static func primary(button: Button) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("dfbd78")
    style.border_color = Color("8b633b")
    style.set_border_width_all(2)
    style.border_width_bottom = 5
    style.set_content_margin_all(14)
    button.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = Color("f3d797")
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.add_theme_color_override("font_color", Color("302d24"))
    button.add_theme_color_override("font_hover_color", Color("302d24"))
    button.add_theme_color_override("font_pressed_color", Color("302d24"))
    button.add_theme_color_override("font_focus_color", Color("302d24"))
    button.add_theme_color_override("font_hover_pressed_color", Color("302d24"))
    button.add_theme_font_size_override("font_size", 20)

static func card(button: Button, element: String) -> void:
    var colors := {"fire": Color("70503c"), "water": Color("345d68"), "earth": Color("496342")}
    var style := StyleBoxFlat.new()
    style.bg_color = colors.get(element, Color("45554a"))
    style.border_color = Color("a09168")
    style.set_border_width_all(2)
    style.border_width_bottom = 4
    style.set_content_margin_all(14)
    button.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = style.bg_color.lightened(0.15)
    hover.border_color = Color("f2d799")
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.add_theme_constant_override("icon_max_width", 64)
    button.expand_icon = true
    button.add_theme_font_size_override("font_size", 18)

static func label(text: String, font_size: int = 18) -> Label:
    var result := Label.new()
    result.text = text
    result.add_theme_font_size_override("font_size", font_size)
    return result

static func skill_description(commander: Dictionary) -> String:
    var skill: Dictionary = commander.get("active_skill", {})
    var description := str(skill.get("display_name", "Commander magic"))
    match str(skill.get("type", "")):
        "targeted_aoe_max_hp":
            description += " — %d meteors strike the rival army with splash damage." % int(skill.get("meteors", 0))
        "round_debuff":
            description += " — slows enemy attacks by %d%% and movement by %d%% for this battle." % [absi(int(skill.get("enemy_attack_speed_pct", 0))), absi(int(skill.get("enemy_movement_speed_pct", 0)))]
        "summon_stationary_units":
            description += " — %d plants join your side on the rival's field for this battle." % int(skill.get("plant_count", 0))
    return description
