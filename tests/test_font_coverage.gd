extends SceneTree
## Browser portability: native OS fallback must not hide missing UI glyphs.
var failed := false
const SYMBOLS := "←→♥♡★◇"
const EXAMPLES := ["Next →", "Battle →", "0 → 1 / 3", "0 → 2 / 6", "← Back", "★ EARNED", "◇ IN PROGRESS", "♥♥♡♡", "1× speed · 17 stacks · ∞"]

func _init() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)

func shape(font: Font, text: String, size: int, symbol_rids: Array[RID]) -> void:
    var ts := TextServerManager.get_primary_interface()
    var line := ts.create_shaped_text()
    check(ts.shaped_text_add_string(line, text, font.get_rids(), size), "actual UI string can be shaped: " + text)
    ts.shaped_text_shape(line)
    var glyphs := ts.shaped_text_get_glyphs(line)
    check(not glyphs.is_empty(), "visible glyphs exist: " + text)
    for glyph in glyphs:
        var c := text.substr(int(glyph["start"]), 1)
        if c in ["\n", "\r", "\t"]:
            continue
        check(glyph["font_rid"].is_valid() and int(glyph["index"]) > 0, "no missing-character box at size %d in %s" % [size, text])
        if SYMBOLS.contains(c):
            check(symbol_rids.has(glyph["font_rid"]), "symbol comes from the bundled pixel face, not a host OS: " + c)
    ts.free_rid(line)

func run() -> void:
    var style = load("res://scripts/presentation/screen_style.gd")
    var body := ThemeDB.fallback_font as FontFile
    var previous: Array[Font] = body.fallbacks.duplicate()
    style.ensure_font_fallbacks()
    var count := body.fallbacks.size()
    style.ensure_font_fallbacks()
    check(body.fallbacks.size() == count, "opening additional screens never duplicates the shared fallback")
    for existing in previous:
        check(body.fallbacks.has(existing), "existing body fallbacks are preserved")
    var display: FontVariation = style.DISPLAY_FONT
    var letters := display.base_font as FontFile
    var symbols: FontFile = style.SYMBOL_FONT
    check(not letters.has_char("→".unicode_at(0)), "fixture reproduces the original missing display arrow")
    check(display.get_string_size("VCommander", HORIZONTAL_ALIGNMENT_LEFT, -1, 24) == letters.get_string_size("VCommander", HORIZONTAL_ALIGNMENT_LEFT, -1, 24), "ordinary pixel lettering and its metrics stay unchanged")
    var old_display_fallback := letters.allow_system_fallback
    var old_body_fallback := body.allow_system_fallback
    letters.allow_system_fallback = false
    body.allow_system_fallback = false
    check(not symbols.allow_system_fallback, "symbol face has no system-font dependency")
    for font in [display, body]:
        for c in SYMBOLS:
            check(font.has_char(c.unicode_at(0)), "bundled display/body chain covers " + c)
        for text in EXAMPLES:
            for size in [12, 16, 20, 28]:
                shape(font, text, size, symbols.get_rids())
    var button := Button.new()
    button.text = "Next →"
    style.primary(button)
    root.add_child(button)
    shape(button.get_theme_font("font"), button.text, button.get_theme_font_size("font_size"), symbols.get_rids())
    var tile = load("res://scripts/presentation/card_tile.gd").new()
    tile.set_content(root.get_node("ContentDatabase").get_all_cards()[0])
    tile.detail_text = "0 → 1 / 3"
    root.add_child(tile)
    await process_frame
    shape(tile.caption.get_theme_font("font"), tile.caption.text, tile.caption.get_theme_font_size("font_size"), symbols.get_rids())
    button.queue_free()
    tile.queue_free()
    letters.allow_system_fallback = old_display_fallback
    body.allow_system_fallback = old_body_fallback
    if not failed:
        print("Font coverage tests passed: actual Next/Battle/recruit/achievement/heart strings, four sizes, body and pixel headings, real buttons/cards and bundled glyph IDs with system fallback disabled.")
    quit(1 if failed else 0)
