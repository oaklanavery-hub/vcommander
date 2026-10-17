#!/usr/bin/env python3
"""Run every regression suite and fail even when Godot logs an error with exit 0."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--pack', type=Path)
args = parser.parse_args()

def run(command, timeout=90):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    output = result.stdout + result.stderr
    if result.returncode or 'ERROR:' in output or 'TEST FAILED:' in output:
        print(output)
        raise SystemExit(result.returncode or 1)
    print(output.strip(), flush=True)

if not args.pack:
    run([sys.executable, 'tools/validate_data.py'])
    run([sys.executable, 'tools/validate_art.py'])
    run([args.godot, '--headless', '--path', '.', '--editor', '--quit'])
for test in sorted((ROOT / 'tests').glob('test_*.gd')):
    command = [args.godot, '--headless']
    if args.pack:
        command += ['--main-pack', str(args.pack.resolve()), '--script', 'res://tests/' + test.name]
    else:
        command += ['--path', '.', '--script', 'tests/' + test.name]
    run(command)
print('All regression suites passed.', flush=True)
