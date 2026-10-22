class_name MatchStatus
extends MatchHearts
## Shared draft/battle HUD. All readings are supplied by the current presentation.

const TEAM_BLUE := Color("79c5d2")
const TEAM_RED := Color("e49b94")
var round_label := ScreenStyle.label("Round 1", 26)
var timer_label := ScreenStyle.label("00:00", 15)
var commanders: Array[Dictionary] = [{}, {}]
var army_health := {"player": 0.0, "opponent": 0.0}
var health_available := false

func _ready() -> void:
    custom_minimum_size = Vector2(640, 100)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_PASS
    tooltip_text = "Four hearts per Commander. Losing a round costs one heart; a draw costs both sides a heart. Army health totals the living bodies currently on the field, including summons."
    for label in [round_label, timer_label]:
        add_child(label)
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
        label.offset_left = -190
        label.offset_right = 190
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    round_label.offset_top = 7
    round_label.offset_bottom = 38
    round_label.add_theme_color_override("font_color", Color("f3d59a"))
    timer_label.offset_top = 39
    timer_label.offset_bottom = 59
    resized.connect(queue_redraw)

func set_commanders(player: Dictionary, opponent: Dictionary) -> void:
    commanders.assign([player.duplicate(true), opponent.duplicate(true)])
    queue_redraw()

func show_army_health(units: Array) -> void:
    army_health = {"player": 0.0, "opponent": 0.0}
    for unit in units:
        var side := str(unit.get("side", ""))
        var hp := float(unit.get("hp", 0))
        if army_health.has(side) and is_finite(hp) and hp > 0:
            army_health[side] += hp
    health_available = true
    queue_redraw()

func _draw() -> void:
    draw_style_box(ScreenStyle.frame(Color("302b25"), Color("90754e"), 14), Rect2(Vector2.ZERO, size))
    for index in range(2):
        var rival := index == 1
        var side := "opponent" if rival else "player"
        var commander: Dictionary = commanders[index]
        var picture := CommanderArt.icon(str(commander.get("element", "earth")))
        var portrait := Rect2(size.x - 63 if rival else 15, 7, 48, 60)
        var art_size := picture.get_size()
        var fitted := art_size * minf(portrait.size.x / art_size.x, portrait.size.y / art_size.y)
        draw_texture_rect(picture, Rect2((portrait.get_center() - fitted * 0.5).floor(), fitted.floor()), false)
        var x := size.x - 284 if rival else 78.0
        var color := TEAM_RED if rival else TEAM_BLUE
        draw_string(ThemeDB.fallback_font, Vector2(x, 26), ("RIVAL · " if rival else "YOU · ") + str(commander.get("display_name", "Commander")), HORIZONTAL_ALIGNMENT_LEFT, 208, 14, color)
        for heart in range(4):
            _heart(Vector2(x + heart * 27, 37), heart < remaining(side), color)
        draw_string(ThemeDB.fallback_font, Vector2(x + 118, 52), "%d/4" % remaining(side), HORIZONTAL_ALIGNMENT_LEFT, 42, 13, Color("e8dab9"))
    var caption := "ARMY HEALTH · REVEALED AT BATTLE"
    if health_available:
        caption = "REMAINING ARMY HEALTH"
        draw_string(ThemeDB.fallback_font, Vector2(17, 76), "You  " + UnitInspection.number(army_health["player"]), HORIZONTAL_ALIGNMENT_LEFT, 220, 12, TEAM_BLUE)
        draw_string(ThemeDB.fallback_font, Vector2(size.x - 237, 76), "Rival  " + UnitInspection.number(army_health["opponent"]), HORIZONTAL_ALIGNMENT_RIGHT, 220, 12, TEAM_RED)
    if sudden_death:
        caption = "SUDDEN DEATH · WIN OUTRIGHT"
    draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - 180, 76), caption, HORIZONTAL_ALIGNMENT_CENTER, 360, 11, Color("c9b98f"))
    var bar := Rect2(16, 83, size.x - 32, 7)
    draw_rect(bar.grow(2), Color("171f1c"))
    draw_rect(bar, Color("495047"))
    if health_available:
        var total: float = army_health["player"] + army_health["opponent"]
        if total > 0:
            var split: float = bar.size.x * army_health["player"] / total
            if split > 0:
                draw_rect(Rect2(bar.position, Vector2(split, bar.size.y)), TEAM_BLUE)
            if split < bar.size.x:
                draw_rect(Rect2(bar.position + Vector2(split, 0), Vector2(bar.size.x - split, bar.size.y)), TEAM_RED)
    draw_rect(Rect2(bar.position, Vector2(bar.size.x, 2)), Color(1, 0.95, 0.8, 0.16))

func _heart(at: Vector2, filled: bool, color: Color) -> void:
    for y in range(PIXELS.size()):
        for x in range(7):
            if PIXELS[y][x] == ".":
                continue
            var ink := color if filled else Color("4b4c42")
            if filled and y < 2 and x < 3:
                ink = Color("ffe4b5")
            draw_rect(Rect2(at + Vector2(x * 3, y * 3 + 2), Vector2(3, 3)), Color("16231e"))
            draw_rect(Rect2(at + Vector2(x * 3, y * 3), Vector2(3, 3)), ink)
