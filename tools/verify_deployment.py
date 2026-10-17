#!/usr/bin/env python3
"""Verify the served build identity/resources and run its PCK in Godot."""
import argparse
import json
import hashlib
import time
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.request import Request, urlopen
from urllib.error import URLError

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

info = {}
for attempt in range(12):
    try:
        info = json.loads(fetch('build-info.json'))
        if info.get('commit') == args.expected_commit:
            break
        print(f"Waiting for Pages source {args.expected_commit}; currently {info.get('commit')}", flush=True)
    except (URLError, TimeoutError, ValueError) as error:
        print(f"Waiting for Pages build identity: {error}", flush=True)
    if attempt < 11:
        time.sleep(5)
else:
    raise SystemExit(f"Pages did not serve expected source {args.expected_commit}")
assert b'canvas' in fetch('index.html'), 'Game loader missing'
assert fetch('index.js', 100), 'Engine JavaScript missing'
assert fetch('index.wasm', 8)[:4] == b'\x00asm', 'WebAssembly payload missing'
pack = fetch('index.pck')
assert pack[:4] == b'GDPC', 'Game pack missing'
assert hashlib.sha256(pack).hexdigest() == info['pack_sha256'], 'Served game pack differs from exported build'
with tempfile.TemporaryDirectory(prefix='vcommander-deploy-') as directory:
    path = Path(directory) / 'index.pck'
    path.write_bytes(pack)
    subprocess.run([sys.executable, str(ROOT / 'tools/run_checks.py'), '--godot', args.godot, '--pack', str(path)], cwd=ROOT, check=True, timeout=240)
print(f"Deployment verified: {info['version']} at {info['commit']}")
