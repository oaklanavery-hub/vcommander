class_name PixelUnitArt
extends RefCounted

# Replaceable presentation-only silhouettes; colors never affect the simulation.
const SHAPES := {
    "tank": ["...oooo...", "..oaaaa o..", ".oaaaaaao.", "oaaalla aao", "oaallllaao", "oaaalla aao", ".oaaaaaao.", "..oo..oo..", "..oo..oo.."],
    "melee": ["...oo....", "..oaao...", "..ollo...", "...oo....", ".oaaaao.o", "oaaaaaaoo", "..oaao.o.", "..o..o...", ".oo..oo.."],
    "range": ["....o....", "...oa o..", "..oaaa o.", ".oaaaaa o", "..ollo...", "...oo....", "..oaao.o.", ".oaaaaoo.", "oaaaaaao.", "..o..o..."],
    "healer": ["...ll....", "..laal...", ".laaaal..", "..ollo...", "...oo..l.", "..oaao.ol", ".oaaaaoo.", ".oaaaaoo.", "..o..o.o."]
}
const PALETTES := {
    "fire": [Color("dd683e"), Color("ffdc82")],
    "water": [Color("4a9cba"), Color("b5f1e3")],
    "earth": [Color("77a54b"), Color("e1d68c")]
}

static func draw_unit(canvas: CanvasItem, position: Vector2, role: String, element: String, pixel: float, flip: bool = false, bob: float = 0.0) -> void:
    var shape: Array = SHAPES.get(role, SHAPES["range"])
    var palette: Array = PALETTES.get(element, PALETTES["earth"])
    var colors := {"o": Color("302d3c"), "a": palette[0], "l": palette[1]}
    var origin := (position - Vector2(5.0 * pixel, float(shape.size()) * pixel + 2.0 + bob)).round()
    for y in range(shape.size()):
        var row: String = str(shape[y]).replace(" ", "")
        for x in range(row.length()):
            var key := row.substr(x, 1)
            if colors.has(key):
                var px := 9 - x if flip else x
                canvas.draw_rect(Rect2(origin + Vector2(px, y) * pixel, Vector2.ONE * pixel), colors[key])
