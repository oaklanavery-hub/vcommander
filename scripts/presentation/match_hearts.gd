class_name MatchHearts
extends Control

const PIXELS := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
var displayed_losses := {"player": 0, "opponent": 0}
var sudden_death := false

func _init() -> void:
    custom_minimum_size = Vector2(480, 44)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    tooltip_text = "Four hearts per Commander. A round loss costs one heart; a draw costs both sides a heart."

func refresh(match_info: MatchState, reveal_result: bool = true) -> void:
    displayed_losses = match_info.losses.duplicate()
    sudden_death = match_info.sudden_death
    if not reveal_result and not match_info.history.is_empty():
        var round: Dictionary = match_info.history.back()
        for side in ["player", "opponent"]:
            if str(round["winner"]) != side:
                displayed_losses[side] = maxi(0, int(displayed_losses[side]) - 1)
        # The result may already have triggered Sudden Death in the simulation.
        sudden_death = bool(round.get("sudden_death", false))
    queue_redraw()

func remaining(side: String) -> int:
    return clampi(4 - int(displayed_losses.get(side, 0)), 0, 4)

func _draw() -> void:
    draw_style_box(ScreenStyle.frame(Color("302d24"), Color("8c7851"), 12), Rect2(Vector2.ZERO, size))
    for side_index in range(2):
        var side := "player" if side_index == 0 else "opponent"
        var start := Vector2(14 if side_index == 0 else size.x - 230, 15)
        var color := Color("95d9cd") if side_index == 0 else Color("eab397")
        draw_string(ThemeDB.fallback_font, start + Vector2(0, 12), "YOU" if side_index == 0 else "RIVAL", HORIZONTAL_ALIGNMENT_LEFT, 60, 14, color)
        var lives := remaining(side)
        for index in range(4):
            var p := start + Vector2(60 + index * 27, 0)
            for y in range(PIXELS.size()):
                for x in range(7):
                    if PIXELS[y][x] == ".":
                        continue
                    var filled := index < lives
                    var ink := Color("dc6c79") if side_index == 0 else Color("df9b72")
                    if not filled:
                        ink = Color("40504b")
                    elif y < 2 and x < 3:
                        ink = Color("ffe2bb")
                    draw_rect(Rect2(p + Vector2(x * 3, y * 3 + 2), Vector2(3, 3)), Color("12251f"))
                    draw_rect(Rect2(p + Vector2(x * 3, y * 3), Vector2(3, 3)), ink)
        draw_string(ThemeDB.fallback_font, start + Vector2(176, 12), "%d/4" % lives, HORIZONTAL_ALIGNMENT_LEFT, 38, 14, color)
    if size.x >= 680:
        draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - 110, 28), "SUDDEN DEATH • Win outright" if sudden_death else "MATCH HEARTS", HORIZONTAL_ALIGNMENT_CENTER, 220, 13, Color("e1c990"))
