# UI fonts

- `PixelifySans.ttf` is the existing display typeface, unchanged. Its original notice is in `OFL-PixelifySans.txt`.
- `ui_symbols.tres` embeds a tiny TrueType face containing six original pixel glyphs: left/right arrows, filled/empty hearts, an earned star and an outline diamond. It is generated entirely from the small pixel masks in `tools/build_ui_symbols.py`; no third-party glyph outlines are copied. Rebuild with `python3 tools/build_ui_symbols.py` (development dependency: `fonttools`). The native FontFile resource loads before asset import and is ready for normal builds without that dependency.
- `pixel_display.tres` preserves Pixelify Sans as the primary face and supplies the bundled symbol fallback. `ScreenStyle` also adds that fallback to Godot's body face, preserving other configured fallbacks. The browser does not need an installed system font to render these symbols.

The font coverage regression shapes actual navigation/recruit/achievement strings with system fallback disabled. Native gallery/army/draft captures provide the visual check.
