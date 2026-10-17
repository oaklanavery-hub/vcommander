extends Control

const Art = preload("res://scripts/presentation/pixel_unit_art.gd")
var camp := false
var _clock := 0.0
var _refresh := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
    if not camp or GameAudio.reduced_motion:
        return
    _clock += delta
    _refresh += delta
    if _refresh > 0.08:
        _refresh = 0.0
        queue_redraw()

func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    draw_set_transform(Vector2.ZERO, 0, size / Vector2(320, 180))
    draw_rect(Rect2(0, 0, 320, 180), Color("26444a"))
    for y in range(0, 105, 9):
        draw_rect(Rect2(0, y, 320, 9), Color("455f5a").lerp(Color("b4ae7e"), float(y) / 140.0))
    draw_circle(Vector2(253, 36), 17, Color("f3d99c"))
    draw_circle(Vector2(257, 32), 17, Color("536e64"))
    draw_colored_polygon(PackedVector2Array([Vector2(0, 93), Vector2(41, 55), Vector2(78, 83), Vector2(130, 43), Vector2(191, 92), Vector2(249, 67), Vector2(320, 91), Vector2(320, 180), Vector2(0, 180)]), Color("547568"))
    for index in range(16):
        _pine(Vector2(index * 24 - 10, 119), 26 + index % 4 * 7, Color("315749"))
    draw_rect(Rect2(0, 115, 320, 65), Color("3b6249"))
    draw_colored_polygon(PackedVector2Array([Vector2(320, 121), Vector2(270, 128), Vector2(201, 180), Vector2(275, 180), Vector2(296, 147), Vector2(320, 142)]), Color("bc9b67"))
    for index in range(30):
        var point := Vector2((index * 47 + 13) % 320, 122 + (index * 17) % 57)
        draw_rect(Rect2(point, Vector2(3, 1)), Color("6b8654"))
        if index % 3 == 0:
            draw_rect(Rect2(point + Vector2(1, -2), Vector2(1, 2)), Color("d7bc73"))
    for index in range(5):
        var base := Vector2(index * 86 - 18, 148 + index % 2 * 11)
        draw_rect(Rect2(base.x - 5, 0, 10, base.y), Color("263d33"))
        draw_rect(Rect2(base.x + 2, 0, 2, base.y - 4), Color("4a5940"))
        _pine(base + Vector2(0, -10), 110, Color("1d4236"))
    if camp:
        _draw_camp()
    else:
        draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.08, 0.07, 0.70))
    draw_set_transform(Vector2.ZERO)

func _pine(base: Vector2, height: float, color: Color) -> void:
    for tier in range(3):
        var top := base - Vector2(0, height - tier * height * 0.23)
        var half_width := height * (0.23 + tier * 0.06)
        draw_colored_polygon(PackedVector2Array([top, top + Vector2(-half_width, height * 0.5), top + Vector2(half_width, height * 0.5)]), color)

func _draw_camp() -> void:
    draw_colored_polygon(PackedVector2Array([Vector2(229, 130), Vector2(251, 99), Vector2(279, 130)]), Color("3b302a"))
    draw_colored_polygon(PackedVector2Array([Vector2(232, 127), Vector2(251, 102), Vector2(275, 127)]), Color("d0aa67"))
    draw_colored_polygon(PackedVector2Array([Vector2(248, 127), Vector2(253, 112), Vector2(261, 127)]), Color("594a37"))
    draw_circle(Vector2(226, 146), 12, Color(0.92, 0.64, 0.25, 0.14))
    draw_line(Vector2(221, 149), Vector2(231, 145), Color("352c27"), 3)
    draw_line(Vector2(221, 145), Vector2(231, 149), Color("59432d"), 3)
    var flicker := 0.0 if GameAudio.reduced_motion else sin(_clock * 6) * 1.5
    draw_colored_polygon(PackedVector2Array([Vector2(221, 146), Vector2(226, 134 + flicker), Vector2(231, 146)]), Color("df814a"))
    draw_colored_polygon(PackedVector2Array([Vector2(224, 146), Vector2(227, 139 - flicker), Vector2(229, 146)]), Color("f7d589"))
    var cards := ContentDatabase.get_all_cards()
    for index in range(mini(3, cards.size())):
        var card: Dictionary = cards[index * 4 % cards.size()]
        var point: Vector2 = [Vector2(207, 137), Vector2(242, 155), Vector2(275, 146)][index]
        draw_circle(point + Vector2(0, 1), 6, Color(0.07, 0.13, 0.10, 0.4))
        Art.draw_unit(self, point, str(card.get("role", "range")), str(card.get("element", "earth")), 1.15, index == 2, 0, str(card.get("id", "")))
    for index in range(9):
        var point := Vector2(173 + index * 16, 57 + (index * 19) % 77)
        var glow := 0.45 + sin(_clock * 1.2 + index) * 0.25
        draw_rect(Rect2(point, Vector2.ONE), Color(1, 0.87, 0.49, glow))
