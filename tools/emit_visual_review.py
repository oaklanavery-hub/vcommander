#!/usr/bin/env python3
"""Emit bounded native QA previews for reviewers without artifact filesystem access.

Full-resolution PNGs remain the primary Actions artifact. Only an explicit,
bounded list of already-rendered views is encoded here; no game/user data.
"""
import base64
import hashlib
from io import BytesIO
from pathlib import Path
from PIL import Image

ROOT = Path("build/qa")
VIEWS = (
    "menu", "commander", "army", "draft", "battle", "result",
    "help", "settings", "progression_new", "progression_achievements_earned",
    "slime_commander", "frozen_field_late", "pvp_lobby",
    "fantasy_gallery_water", "fantasy_gallery_earth", "fantasy_gallery_slime",
    "fantasy_battle_details", "fantasy_blessings",
)
for name in VIEWS:
    source = ROOT / (name + ".png")
    if not source.is_file():
        raise SystemExit("Missing native review image: " + str(source))
    with Image.open(source) as image:
        image = image.convert("RGB")
        image.thumbnail((1280, 720), Image.Resampling.NEAREST)
        buffer = BytesIO()
        image.save(buffer, "WEBP", quality=88, method=6)
    payload = buffer.getvalue()
    if len(payload) > 250_000:
        raise SystemExit("Review image exceeds bounded size: " + name)
    encoded = base64.b64encode(payload).decode("ascii")
    print(f"VC_REVIEW_BEGIN {name} image/webp {len(payload)} {hashlib.sha256(payload).hexdigest()}", flush=True)
    for start in range(0, len(encoded), 8000):
        print("VC_REVIEW_CHUNK " + name + " " + encoded[start:start + 8000], flush=True)
    print("VC_REVIEW_END " + name, flush=True)
