class_name WarbandRoster
extends PanelContainer
## Persistent recruited counts, separate from live bodies and the playable arena.

const UnitArt = preload("res://scripts/presentation/pixel_unit_art.gd")
const STAT_NAMES := {"attack": "ATK", "health": "HP", "defense": "DEF", "attack_speed": "ASPD", "movement_speed": "MOVE"}
var summary := RichTextLabel.new()
var buffs := RichTextLabel.new()
var rows := VBoxContainer.new()
var heading := ScreenStyle.label("YOUR WARBAND", 15)
var note := ScreenStyle.label("Recruited / cap", 11)
var config: Dictionary = {}
var highlighted_card := ""
var hidden_picks := false
var rival := false
var scroll := ScrollContainer.new()

func _ready() -> void:
    custom_minimum_size.x = 168
    var frame := ScreenStyle.frame(Color("302c25"), Color("81704c"), 12)
    frame.set_content_margin_all(9)
    add_theme_stylebox_override("panel", frame)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 5)
    scroll.add_child(column)
    for label in [heading, note]:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(label)
    rows.add_theme_constant_override("separation", 5)
    column.add_child(rows)
    for label in [summary, buffs]:
        label.bbcode_enabled = true
        label.fit_content = true
        label.scroll_active = false
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("normal_font_size", 12)
        label.add_theme_font_size_override("bold_font_size", 12)
        column.add_child(label)
    refresh()

func set_side(side: Dictionary, is_rival: bool = false, picks_hidden: bool = false) -> void:
    config = side.duplicate(true)
    rival = is_rival
    hidden_picks = picks_hidden
    if is_node_ready():
        refresh()

func refresh() -> void:
    heading.text = "RIVAL WARBAND" if rival else "YOUR WARBAND"
    heading.add_theme_color_override("font_color", MatchStatus.TEAM_RED if rival else MatchStatus.TEAM_BLUE)
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    for card in config.get("cards", []):
        var id := str(card.get("id", ""))
        var count := int(config.get("unit_counts", {}).get(id, 0))
        var row := PanelContainer.new()
        row.name = id
        row.custom_minimum_size.y = 48
        var style := ScreenStyle.frame(Color("242b24"), Color("d9ba76") if id == highlighted_card else Color("5f6246"), 8)
        style.set_content_margin_all(4)
        style.ornaments = false
        row.add_theme_stylebox_override("panel", style)
        row.tooltip_text = "%s · %s\nRecruited %d / %d\n%s" % [str(card.get("display_name", id)), str(card.get("role", "Unit")).capitalize(), count, int(card.get("unit_cap", 0)), str(card.get("ability", {}).get("description", ""))]
        var line := HBoxContainer.new()
        line.mouse_filter = Control.MOUSE_FILTER_IGNORE
        line.add_theme_constant_override("separation", 4)
        row.add_child(line)
        var portrait := TextureRect.new()
        portrait.texture = UnitArt.icon(id, str(card.get("role", "range")), str(card.get("element", "earth")))
        portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.custom_minimum_size = Vector2(32, 36)
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        portrait.modulate.a = 1.0 if count > 0 else 0.45
        var words := VBoxContainer.new()
        words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        words.alignment = BoxContainer.ALIGNMENT_CENTER
        words.mouse_filter = Control.MOUSE_FILTER_IGNORE
        words.add_theme_constant_override("separation", 1)
        var title := ScreenStyle.label(str(card.get("display_name", id)), 12)
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var amount := ScreenStyle.label("%d / %d" % [count, int(card.get("unit_cap", 0))], 14)
        amount.add_theme_color_override("font_color", Color("f1d89d") if id == highlighted_card else Color("b9c8ac"))
        for label in [title, amount]:
            label.mouse_filter = Control.MOUSE_FILTER_IGNORE
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rival else HORIZONTAL_ALIGNMENT_LEFT
            words.add_child(label)
        line.add_child(words if rival else portrait)
        line.add_child(portrait if rival else words)
        rows.add_child(row)
    var bonus: Dictionary = config.get("set_bonus", {})
    var theme := "Theme inactive" if bonus.is_empty() else ScreenStyle.bonus_description(bonus, true)
    summary.text = "[b]Theme[/b]\n%s\nSkill uses: %d/2" % [theme, int(config.get("skill_uses_remaining", 2))]
    if bool(config.get("commander_skill_active", false)):
        summary.text += " · Prepared"
    if hidden_picks:
        summary.text += "\nNew picks hidden"
    if rival and config.has("ai_plan"):
        var plan: Dictionary = config["ai_plan"]
        summary.text += "\n%s · %s" % [str(plan.get("difficulty", "standard")).capitalize(), str(plan.get("name", "Balanced"))]
    var entries: Array[String] = []
    for buff in config.get("buffs", []):
        var definition: Dictionary = buff.get("definition", {})
        entries.append("%s +%d%% ×%d" % [str(STAT_NAMES.get(str(definition.get("stat", "")), "Power")), int(definition.get("percentage", 0)), int(buff.get("stacks", 0))])
    buffs.text = "[b]Power cards[/b]\n" + ("None yet" if entries.is_empty() else "\n".join(entries))
