import contextlib
import importlib.util
import io
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('release', Path(__file__).resolve().parents[1] / 'scripts/update_release.py')
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)

class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.previous_root, release.ROOT = release.ROOT, self.root
        for name in ['Sources', 'scripts', 'docs', 'Resources']:
            (self.root / name).mkdir()
        (self.root / 'Sources/App.swift').write_text('initial code')
        (self.root / 'Package.swift').write_text('package')
        (self.root / 'docs/help.template.html').write_text('Guide {{VERSION}} {{BUILD}} {{BUILD_DATE}}')
        (self.root / 'Info.plist').write_bytes(plistlib.dumps({}))
    def tearDown(self):
        release.ROOT = self.previous_root
        self.temporary.cleanup()
    def run_release(self, *arguments):
        argv, sys.argv = sys.argv, ['update_release.py', *arguments]
        try:
            with contextlib.redirect_stdout(io.StringIO()): release.main()
        finally: sys.argv = argv
    def info(self): return plistlib.loads((self.root / 'Info.plist').read_bytes())
    def testFirstBuildAndRebuild(self):
        self.run_release()
        self.assertEqual(self.info()['CFBundleVersion'], '4')
        self.assertEqual(self.info()['CFBundleShortVersionString'], '1.3.0')
        self.run_release()
        self.assertEqual(self.info()['CFBundleVersion'], '5')
        self.assertEqual(self.info()['CFBundleShortVersionString'], '1.3.0')
        self.run_release('--check')
    def testCodeChangeRequiresGuideUpdate(self):
        self.run_release()
        (self.root / 'Sources/App.swift').write_text('changed code')
        with self.assertRaisesRegex(SystemExit, 'update docs/help.template.html'): self.run_release()
        self.assertEqual(self.info()['CFBundleVersion'], '4')
    def testCodeAndGuideChangeBumpVersionTogether(self):
        self.run_release()
        (self.root / 'Sources/App.swift').write_text('changed code')
        with (self.root / 'docs/help.template.html').open('a') as file: file.write(' Reviewed.')
        self.run_release()
        self.assertEqual(self.info()['CFBundleShortVersionString'], '1.3.1')
        self.assertEqual(self.info()['CFBundleVersion'], '5')
        self.assertIn('1.3.1', (self.root / 'Resources/help.html').read_text())
        self.run_release('--check')
    def testCheckRejectsOutdatedGuide(self):
        self.run_release()
        (self.root / 'Resources/help.html').write_text('old content')
        with self.assertRaisesRegex(SystemExit, 'guide does not match'): self.run_release('--check')

if __name__ == '__main__': unittest.main()
