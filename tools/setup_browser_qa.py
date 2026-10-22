#!/usr/bin/env python3
"""Reuse verified Playwright packages and bound cold browser setup."""
from pathlib import Path
import subprocess
import shutil
import sys

VERSION = '1.64.1'
PREFIX = Path(__file__).resolve().parents[1] / 'build/browser'
PROBE = """const p = require(require('path').resolve(process.argv[1]));
if (require(require('path').resolve(process.argv[1], 'package.json')).version !== process.argv[2]) process.exit(1);
process.stdout.write(p.chromium.executablePath());"""


def probe(prefix, runner):
    package = prefix / 'node_modules/playwright'
    if not (package / 'package.json').is_file():
        return None
    try:
        result = runner(['node', '-e', PROBE, str(package), VERSION],
                        check=True, timeout=5, capture_output=True, text=True)
        return Path(result.stdout.strip()) if result.stdout.strip() else None
    except (subprocess.SubprocessError, OSError):
        return None


def setup(prefix=PREFIX, runner=subprocess.run, log=print):
    executable = probe(prefix, runner)
    if executable is None:
        for name in ['playwright', 'playwright-core']:
            package = prefix / 'node_modules' / name
            if package.is_symlink():
                package.unlink()
            elif package.is_dir():
                shutil.rmtree(package)
        log('Installing pinned Playwright package (60-second limit).', flush=True)
        runner(['npm', 'install', '--prefix', str(prefix), '--no-save', '--no-audit',
                '--no-fund', '--fetch-timeout=20000', '--fetch-retries=1',
                '--fetch-retry-mintimeout=1000', '--fetch-retry-maxtimeout=3000',
                'playwright@' + VERSION], check=True, timeout=60)
        if probe(prefix, runner) is None:
            raise RuntimeError('Installed Playwright package failed its version/module check')
    else:
        log('Reusing verified Playwright ' + VERSION + ' package.', flush=True)
    # A cache never replaces system dependency installation or the real tests.
    log('Ensuring Chromium and system libraries (110-second limit).', flush=True)
    runner([str(prefix / 'node_modules/.bin/playwright'), 'install', '--with-deps',
            'chromium'], check=True, timeout=110)
    executable = probe(prefix, runner)
    if executable is None or not executable.is_file():
        raise RuntimeError('Chromium executable is missing after setup')
    log('Browser QA runtime ready.', flush=True)


if __name__ == '__main__':
    try:
        setup()
    except (subprocess.SubprocessError, OSError, RuntimeError) as error:
        print('Browser setup failed within its bounded budget: ' + str(error), file=sys.stderr)
        raise SystemExit(1)
