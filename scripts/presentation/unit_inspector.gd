class_name UnitInspector
extends PanelContainer

signal dismissed

var selected_id := ""
var heading: Label
var stats: Label
var ability_label: Label
var cooldown_label: Label
var effects_label: Label
var portrait := CardPortrait.new()
var last_unit: Dictionary = {}

func _ready() -> void:
    custom_minimum_size.x = 264
    add_theme_stylebox_override("panel", ScreenStyle.frame(Color("302f26"), Color("a68a58"), 12))
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 8)
    scroll.add_child(body)
    var close_button := Button.new()
    close_button.text = "Close inspection ×"
    close_button.custom_minimum_size.y = 34
    close_button.pressed.connect(func(): selected_id = ""; hide(); dismissed.emit())
    body.add_child(close_button)
    portrait.custom_minimum_size = Vector2(0, 76)
    body.add_child(portrait)
    heading = _label(body, 20)
    stats = _label(body, 14)
    ability_label = _label(body, 14)
    cooldown_label = _label(body, 14)
    effects_label = _label(body, 13)
    hide()

func inspect(unit: Dictionary, card: Dictionary, clock: float, frozen: bool = false) -> void:
    if unit.is_empty():
        if not selected_id.is_empty():
            cooldown_label.text = "Unit defeated · select another companion"
            stats.text = "HP 0 / " + UnitInspection.number(float(last_unit.get("max_hp", 1)))
            effects_label.text = ""
        return
    selected_id = str(unit["id"])
    last_unit = unit.duplicate(true)
    var data := UnitInspection.describe(unit, card, clock, frozen)
    heading.text = str(data["name"]) + " · " + str(data["role"]).capitalize()
    stats.text = "HP %s / %s\nAttack %s   ·   Defense %s\nAttack speed %s   ·   Move %s\nReach %s" % [UnitInspection.number(data["hp"]), UnitInspection.number(float(data["max_hp"])), UnitInspection.number(float(data["attack"])), UnitInspection.number(float(data["defense"])), UnitInspection.number(float(data["attack_speed"])), UnitInspection.number(float(data["movement_speed"])), UnitInspection.number(float(data["range"]))]
    ability_label.text = str(data["ability"]) + "\n" + str(data["description"])
    cooldown_label.text = str(data["cooldown"])
    effects_label.text = "\n".join(data["effects"]) if not data["effects"].is_empty() else "No active effects"
    var display := card if not card.is_empty() else {"id": unit.get("card_id", ""), "element": unit.get("element", "earth"), "role": unit.get("role", "range")}
    portrait.set_content(display, false)
    show()

func _label(parent: Node, font_size: int) -> Label:
    var label := ScreenStyle.label("", font_size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label
