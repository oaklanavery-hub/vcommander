#!/usr/bin/env python3
"""Emit bounded native QA previews for reviewers without artifact filesystem access.

Full-resolution PNGs remain the primary Actions artifact. Only an explicit,
bounded list of already-rendered views is encoded here; no game/user data.
"""
import base64
import hashlib
from io import BytesIO
from pathlib import Path

ROOT = Path("build/qa")
if not ROOT.exists() or not any(ROOT.glob("*.png")):
    print("No native views available; inspect the preceding validation step.")
    raise SystemExit(0)
from PIL import Image
VIEWS = (
    "menu", "commander", "army", "draft", "battle", "result",
    "help", "settings", "progression_new", "progression_achievements_earned",
    "slime_commander", "frozen_field_late", "pvp_lobby",
    "fantasy_gallery_fire", "fantasy_gallery_water", "fantasy_gallery_slime",
    "fantasy_battle_details", "fantasy_blessings",
    "assassins_collection", "assassins_transit", "assassins_terrain", "assassins_cooldown", "assassins_links", "assassins_reduced", "assassins_powercards",
)
emitted = 0
for name in VIEWS:
    source = ROOT / (name + ".png")
    if not source.is_file():
        print("VC_REVIEW_MISSING " + name, flush=True)
        continue
    with Image.open(source) as image:
        image = image.convert("RGB")
        image.thumbnail((1280, 720), Image.Resampling.NEAREST)
        buffer = BytesIO()
        image.save(buffer, "WEBP", quality=88, method=6)
    payload = buffer.getvalue()
    if len(payload) > 250_000:
        image.thumbnail((960, 540), Image.Resampling.NEAREST)
        buffer = BytesIO()
        image.save(buffer, "WEBP", quality=82, method=6)
        payload = buffer.getvalue()
    if len(payload) > 250_000:
        raise SystemExit("Review image exceeds bounded size: " + name)
    encoded = base64.b64encode(payload).decode("ascii")
    print(f"VC_REVIEW_BEGIN {name} image/webp {len(payload)} {hashlib.sha256(payload).hexdigest()}", flush=True)
    for start in range(0, len(encoded), 8000):
        print("VC_REVIEW_CHUNK " + name + " " + encoded[start:start + 8000], flush=True)
    print("VC_REVIEW_END " + name, flush=True)
    emitted += 1
if not emitted:
    raise SystemExit("No native screenshots available for review")
