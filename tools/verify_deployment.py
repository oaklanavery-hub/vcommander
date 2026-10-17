#!/usr/bin/env python3
"""Verify the served build identity/resources and run its PCK in Godot."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--url', default='https://oaklanavery-hub.github.io/vcommander/')
parser.add_argument('--expected-commit', required=True)
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
base = args.url.rstrip('/') + '/'
suffix = '?commit=' + args.expected_commit

def fetch(name, limit=None):
    request = Request(base + name + suffix, headers={'User-Agent': 'VCommander-Deployment-Check'})
    with urlopen(request, timeout=30) as response:
        assert response.status == 200, (name, response.status)
        return response.read(limit) if limit else response.read()

info = json.loads(fetch('build-info.json'))
assert info['commit'] == args.expected_commit, f"Deployment still serves {info['commit']}"
assert b'canvas' in fetch('index.html'), 'Game loader missing'
assert fetch('index.js', 100), 'Engine JavaScript missing'
assert fetch('index.wasm', 8)[:4] == b'\x00asm', 'WebAssembly payload missing'
pack = fetch('index.pck')
assert pack[:4] == b'GDPC', 'Game pack missing'
with tempfile.TemporaryDirectory(prefix='vcommander-deploy-') as directory:
    path = Path(directory) / 'index.pck'
    path.write_bytes(pack)
    subprocess.run([sys.executable, str(ROOT / 'tools/run_checks.py'), '--godot', args.godot, '--pack', str(path)], cwd=ROOT, check=True, timeout=240)
print(f"Deployment verified: {info['version']} at {info['commit']}")
