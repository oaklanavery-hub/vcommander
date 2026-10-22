"""Network-free coverage of cache repair and bounded browser setup."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import setup_browser_qa as setup


class BrowserSetupTests(unittest.TestCase):
    def fixture(self, cached=False, invalid=False, npm_error=None, browser_error=None):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        prefix = Path(temporary.name)
        package = prefix / 'node_modules/playwright/package.json'
        executable = prefix / 'chromium'
        executable.touch()
        if cached:
            package.parent.mkdir(parents=True)
            package.write_text('{}')
        calls = []
        state = {'invalid': invalid}

        def runner(command, **kwargs):
            calls.append((command, kwargs))
            if command[0] == 'npm':
                self.assertFalse(package.exists(), 'a broken cached package must be removed before reinstalling')
                if npm_error:
                    raise npm_error
                package.parent.mkdir(parents=True, exist_ok=True)
                package.write_text('{}')
                state['invalid'] = False
            elif command[0] == 'node' and state['invalid']:
                raise subprocess.CalledProcessError(1, command)
            elif command[0].endswith('/playwright') and browser_error:
                raise browser_error
            return subprocess.CompletedProcess(command, 0, stdout=str(executable))

        return prefix, calls, runner

    def test_warm_cache_skips_registry_but_keeps_browser_dependencies(self):
        prefix, calls, runner = self.fixture(cached=True)
        setup.setup(prefix, runner, lambda *a, **k: None)
        self.assertFalse(any(c[0][0] == 'npm' for c in calls))
        self.assertTrue(any('--with-deps' in c[0] for c in calls))

    def test_cold_cache_installs_exact_version_with_bounded_retries(self):
        prefix, calls, runner = self.fixture()
        setup.setup(prefix, runner, lambda *a, **k: None)
        npm = next(c for c in calls if c[0][0] == 'npm')
        self.assertIn('playwright@1.64.1', npm[0])
        self.assertIn('--fetch-retries=1', npm[0])
        self.assertEqual(npm[1]['timeout'], 60)
        self.assertTrue(all(0 < options['timeout'] <= 110 for _, options in calls))

    def test_invalid_cached_module_is_repaired(self):
        prefix, calls, runner = self.fixture(cached=True, invalid=True)
        setup.setup(prefix, runner, lambda *a, **k: None)
        self.assertEqual(sum(c[0][0] == 'npm' for c in calls), 1)

    def test_registry_timeout_stops_before_browser_and_never_loops(self):
        prefix, calls, runner = self.fixture(npm_error=subprocess.TimeoutExpired('npm', 60))
        with self.assertRaises(subprocess.TimeoutExpired):
            setup.setup(prefix, runner, lambda *a, **k: None)
        self.assertEqual(len(calls), 1)

    def test_browser_failure_remains_a_failure(self):
        prefix, calls, runner = self.fixture(cached=True, browser_error=subprocess.CalledProcessError(1, 'playwright'))
        with self.assertRaises(subprocess.CalledProcessError):
            setup.setup(prefix, runner, lambda *a, **k: None)

    def test_missing_browser_cannot_claim_success(self):
        prefix, calls, runner = self.fixture(cached=True)
        (prefix / 'chromium').unlink()
        with self.assertRaises(RuntimeError):
            setup.setup(prefix, runner, lambda *a, **k: None)


if __name__ == '__main__':
    unittest.main()
