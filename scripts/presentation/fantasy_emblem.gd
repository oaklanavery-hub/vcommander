class_name FantasyEmblem
extends Control
## Small code-native foil emblems, shared by blessing cards and the journal.

var kind := "mastery"
var accent := Color("d5b578")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    var scale_factor := minf(size.x, size.y) / 64.0
    if scale_factor <= 0:
        return
    draw_set_transform((size * 0.5).floor(), 0, Vector2.ONE * scale_factor)
    draw_circle(Vector2(0, 2), 29, Color("191d19"))
    draw_circle(Vector2.ZERO, 29, Color("74583a"))
    draw_circle(Vector2.ZERO, 27, accent.darkened(0.1))
    draw_circle(Vector2.ZERO, 23, Color("2b3025"))
    draw_arc(Vector2.ZERO, 24, PI, TAU, 24, accent.lightened(0.25), 1, false)
    for index in range(8):
        var direction := Vector2.from_angle(TAU * float(index) / 8.0)
        draw_rect(Rect2((direction * 26 - Vector2.ONE).floor(), Vector2(2, 2)), Color("eed8a2"))
    var shape := PackedVector2Array()
    match kind:
        "attack":
            shape = PackedVector2Array([Vector2(-3, 5), Vector2(7, -16), Vector2(14, -18), Vector2(14, -10), Vector2(3, 9), Vector2(8, 12), Vector2(5, 16), Vector2(-1, 12), Vector2(-7, 20), Vector2(-11, 16), Vector2(-5, 8), Vector2(-11, 5), Vector2(-8, 1)])
        "health":
            shape = PackedVector2Array([Vector2(0, -9), Vector2(-5, -14), Vector2(-12, -14), Vector2(-17, -9), Vector2(-17, -2), Vector2(-12, 4), Vector2(0, 16), Vector2(12, 4), Vector2(17, -2), Vector2(17, -9), Vector2(12, -14), Vector2(5, -14)])
        "defense":
            shape = PackedVector2Array([Vector2(-14, -15), Vector2(14, -15), Vector2(14, 3), Vector2(9, 11), Vector2(0, 18), Vector2(-9, 11), Vector2(-14, 3)])
        "attack_speed":
            shape = PackedVector2Array([Vector2(3, -19), Vector2(-13, 3), Vector2(-2, 3), Vector2(-5, 20), Vector2(14, -5), Vector2(3, -5)])
        "movement_speed":
            shape = PackedVector2Array([Vector2(-8, -16), Vector2(6, -16), Vector2(7, 2), Vector2(16, 8), Vector2(16, 14), Vector2(-14, 14), Vector2(-14, 7), Vector2(-8, 1)])
        _:
            for index in range(16):
                shape.append((Vector2.from_angle(-PI * 0.5 + TAU * float(index) / 16.0) * (17 if index % 2 == 0 else 8)).floor())
    var shadow := PackedVector2Array()
    for point in shape:
        shadow.append(point + Vector2(0, 2))
    draw_colored_polygon(shadow, accent.darkened(0.65))
    draw_colored_polygon(shape, accent.lightened(0.17))
    if kind == "defense":
        draw_line(Vector2(0, -11), Vector2(0, 10), accent.darkened(0.35), 3, false)
        draw_line(Vector2(-9, -3), Vector2(9, -3), accent.darkened(0.35), 3, false)
    draw_rect(Rect2(-6, -10, 3, 3), Color("f6e9bd"))
    draw_set_transform(Vector2.ZERO)

