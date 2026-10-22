#!/usr/bin/env python3
"""Emit bounded native QA previews for reviewers without artifact filesystem access.

Full-resolution PNGs remain the primary Actions artifact. Only an explicit,
bounded list of already-rendered views is encoded here; no game/user data.
"""
import base64
import argparse
import hashlib
from io import BytesIO
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output-dir', type=Path, default=Path('build/qa'))
selection = parser.add_mutually_exclusive_group()
selection.add_argument('--views', nargs='+', help='Specific screenshot names to review')
selection.add_argument('--all', action='store_true', help='Emit the full legacy review set')
parser.add_argument('--max-bytes', type=int, help='Total image payload budget')
args = parser.parse_args()
ROOT = args.output_dir
if not ROOT.exists() or not any(ROOT.glob("*.png")):
    print("No native views available; inspect the preceding validation step.")
    raise SystemExit(0)
from PIL import Image
ALL_VIEWS = (
    "menu", "commander", "army", "draft", "battle", "result",
    "help", "settings", "progression_new", "progression_achievements_earned",
    "slime_commander", "frozen_field_late", "pvp_lobby",
    "fantasy_gallery_fire", "fantasy_gallery_water", "fantasy_gallery_slime",
    "fantasy_battle_details", "fantasy_blessings",
    "learning_inspection", "learning_report_player", "learning_report_rival", "learning_report_compact", "learning_report_large", "learning_help",
    "learning_guide_commander", "learning_guide_warband", "learning_guide_draft", "learning_guide_skill", "learning_guide_ready", "learning_guide_battle", "learning_guide_report", "learning_guide_complete",
    "learning_death_phases", "learning_death_reduced", "attack_slam_windup", "attack_slam_recover",
)
DEFAULT_VIEWS = ('learning_inspection', 'learning_report_player', 'learning_guide_draft',
                 'battle', 'menu', 'commander', 'army', 'draft')
VIEWS = args.views or (ALL_VIEWS if args.all else DEFAULT_VIEWS)
if any(not name.replace('_', '').isalnum() for name in VIEWS):
    parser.error('Screenshot names may contain only letters, numbers and underscores')
budget = args.max_bytes if args.max_bytes is not None else (8_000_000 if args.all else 1_500_000)
if budget <= 0:
    parser.error('Image payload budget must be positive')
emitted = 0
total_bytes = 0
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
    if total_bytes + len(payload) > budget:
        print("VC_REVIEW_OMITTED " + name + " (payload budget; full PNG is in the artifact)", flush=True)
        continue
    encoded = base64.b64encode(payload).decode("ascii")
    print(f"VC_REVIEW_BEGIN {name} image/webp {len(payload)} {hashlib.sha256(payload).hexdigest()}", flush=True)
    for start in range(0, len(encoded), 8000):
        print("VC_REVIEW_CHUNK " + name + " " + encoded[start:start + 8000], flush=True)
    print("VC_REVIEW_END " + name, flush=True)
    emitted += 1
    total_bytes += len(payload)
if not emitted:
    raise SystemExit("No native screenshots available for review")
print(f'VC_REVIEW_SUMMARY views={emitted} bytes={total_bytes}; full-resolution PNGs remain in desktop-visual-qa', flush=True)
