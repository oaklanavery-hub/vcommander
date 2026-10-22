#!/usr/bin/env python3
"""Rebuild the original UI symbol fallback (optional dev dependency: fonttools).

The six original pixel masks fill gaps in Pixelify Sans and Godot's body face.
No outlines from either existing font are copied or modified.
"""
from pathlib import Path
from io import BytesIO

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = Path(__file__).resolve().parents[1]
RIGHT = ("...#...", "....#..", ".....#.", "#######", ".....#.", "....#..", "...#...")
MASKS = {
    0x2190: tuple(row[::-1] for row in RIGHT),
    0x2192: RIGHT,
    0x2665: (".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."),
    0x2661: (".##.##.", "#..#..#", "#.....#", ".#...#.", "..#.#..", "...#..."),
    0x2605: ("...#...", "...#...", "#######", ".#####.", "..###..", ".##.##.", ".#...#."),
    0x25C7: ("...#...", "..#.#..", ".#...#.", "#.....#", ".#...#.", "..#.#..", "...#..."),
}


def glyph(rows):
    pen = TTGlyphPen(None)
    for y, row in enumerate(rows):
        for x, cell in enumerate(row):
            if cell != "#":
                continue
            left, bottom = 50 + x * 100, (6 - y) * 100
            pen.moveTo((left, bottom))
            pen.lineTo((left, bottom + 100))
            pen.lineTo((left + 100, bottom + 100))
            pen.lineTo((left + 100, bottom))
            pen.closePath()
    return pen.glyph()


def main():
    names = {code: f"uni{code:04X}" for code in MASKS}
    order = [".notdef", "space", *names.values()]
    font = FontBuilder(1000, isTTF=True)
    font.setupGlyphOrder(order)
    font.setupCharacterMap({32: "space", **names})
    outlines = {".notdef": glyph(()), "space": glyph(())}
    outlines.update({names[code]: glyph(rows) for code, rows in MASKS.items()})
    font.setupGlyf(outlines)
    font.setupHorizontalMetrics({name: (800, 50 if name in names.values() else 0) for name in order})
    font.setupHorizontalHeader(ascent=920, descent=-280)
    font.setupOS2(sTypoAscender=920, sTypoDescender=-280, usWinAscent=920, usWinDescent=280)
    font.setupNameTable({
        "familyName": "VCommander Pixel Symbols",
        "styleName": "Regular",
        "uniqueFontIdentifier": "VCommanderPixelSymbols-1.0",
        "fullName": "VCommander Pixel Symbols Regular",
        "psName": "VCommanderPixelSymbols-Regular",
        "version": "Version 1.000",
        "copyright": "Original VCommander UI pixel symbols.",
        "description": "Original pixel masks in tools/build_ui_symbols.py; see assets/fonts/README.md.",
    })
    font.setupPost()
    font.setupMaxp()
    font.font.recalcTimestamp = False
    font.font["head"].created = font.font["head"].modified = 2082844800
    data = BytesIO()
    font.save(data)
    payload = data.getvalue()
    destination = ROOT / "assets/fonts/ui_symbols.tres"
    # A native FontFile resource embeds this tiny TrueType face. It can load
    # during autoload parsing, before the editor has imported new assets.
    destination.write_text('[gd_resource type="FontFile" format=3]\n\n[resource]\n'
                           'antialiasing = 0\nallow_system_fallback = false\n'
                           'subpixel_positioning = 0\n'
                           'data = PackedByteArray(' + ', '.join(map(str, payload)) + ')\n')
    print(f"UI symbols: {len(MASKS)} original glyphs, {len(payload)} embedded font bytes")


if __name__ == "__main__":
    main()
