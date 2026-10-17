#!/usr/bin/env python3
"""Write the public source identity beside an exported game."""
import argparse
import json
import hashlib
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('output_dir', type=Path)
parser.add_argument('--commit')
args = parser.parse_args()
match = re.search(r'^config/version="([^"]+)"', (root / 'project.godot').read_text(), re.MULTILINE)
commit = args.commit or subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
assert re.fullmatch(r'[a-f0-9]{40}', commit), 'Expected a full commit SHA'
info = {'version': match[1] if match else 'development', 'commit': commit, 'engine': '4.7.stable'}
args.output_dir.mkdir(parents=True, exist_ok=True)
info['pack_sha256'] = hashlib.sha256((args.output_dir / 'index.pck').read_bytes()).hexdigest()
(args.output_dir / 'build-info.json').write_text(json.dumps(info, indent=2) + '\n')
print('Build identity:', info)
