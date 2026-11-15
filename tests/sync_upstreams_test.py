"""Check source pinning and bundle replacement through the public CLI."""
import json
from pathlib import Path
import subprocess
import stat
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/sync-upstreams.py"


class SyncUpstreamsTest(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name) / "project"
        self.root.mkdir()
        self.remote = Path(self.scratch.name) / "remote"
        self.remote.mkdir()
        self.git("init", "-q")
        (self.remote / "bundle").mkdir()
        (self.remote / "bundle/SKILL.md").write_text("---\nname: upstream\n---\n# Writing\n")
        (self.remote / "bundle/LICENSE").write_text("Test license\n")
        (self.remote / "bundle/guide.txt").write_text("Original guidance.\n")
        self.git("add", ".")
        self.git("commit", "-qm", "initial source")
        self.git("tag", "v1.0.0")
        self.revision = self.git("rev-parse", "HEAD").strip()
        self.destination = self.root / "skills/writing/vendor/upstream"
        self.bundle = {
            "name": "upstream",
            "repository": self.remote.as_uri(),
            "version": "v1.0.0",
            "revision": self.revision,
            "source": "bundle",
            "destination": "skills/writing/vendor/upstream",
            "include": ["."],
            "patches": ["patches/upstream.patch"],
        }
        (self.root / "patches").mkdir()
        self.patch = self.root / "patches/upstream.patch"
        self.patch.write_text(
            "diff --git a/guide.txt b/guide.txt\n"
            "--- a/guide.txt\n+++ b/guide.txt\n@@ -1 +1 @@\n"
            "-Original guidance.\n+Local guidance.\n"
        )
        self.write_manifest([self.bundle])

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-c", "user.name=Test", "-c", "user.email=test@example.invalid", *args],
            cwd=self.remote, text=True, stderr=subprocess.PIPE,
        )

    def write_manifest(self, bundles):
        (self.root / "upstreams.json").write_text(json.dumps({"bundles": bundles}))

    def sync(self, *args):
        return subprocess.run(
            ["python3", str(SCRIPT), "--root", str(self.root), *args],
            capture_output=True, text=True,
        )

    def test_generation_applies_patch_and_check_detects_drift(self):
        # The generated copy must retain resources while exposing only the wrapper's skill name.
        result = self.sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.destination / "guide.txt").read_text(), "Local guidance.\n")
        self.assertTrue((self.destination / "INSTRUCTIONS.md").is_file())
        self.assertFalse((self.destination / "SKILL.md").exists())
        self.assertIn(self.revision, (self.destination / "UPSTREAM.md").read_text())
        self.assertEqual(self.sync("--check").returncode, 0)
        # Executable bits affect how installed resources can be invoked.
        instructions = self.destination / "INSTRUCTIONS.md"
        original_mode = stat.S_IMODE(instructions.stat().st_mode)
        instructions.chmod(original_mode ^ stat.S_IXUSR)
        self.assertEqual(self.sync("--check").returncode, 1)
        instructions.chmod(original_mode)
        (self.destination / "guide.txt").write_text("Changed output.\n")
        self.assertEqual(self.sync("--check").returncode, 1)
        self.assertEqual((self.destination / "guide.txt").read_text(), "Changed output.\n")
        self.assertEqual(self.sync().returncode, 0)
        self.assertEqual(self.sync("--check").returncode, 0)

    def test_moved_tag_is_rejected_without_replacing_output(self):
        # A moved tag must not override the reviewed commit pin.
        self.assertEqual(self.sync().returncode, 0)
        (self.remote / "bundle/guide.txt").write_text("Moved release.\n")
        self.git("add", ".")
        self.git("commit", "-qm", "move release")
        self.git("tag", "-f", "v1.0.0")
        result = self.sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("commit mismatch", result.stderr)
        self.assertEqual((self.destination / "guide.txt").read_text(), "Local guidance.\n")

    def test_failed_patch_preserves_every_bundle(self):
        # An incompatible later bundle must not leave an earlier bundle partially updated.
        self.assertEqual(self.sync().returncode, 0)
        before = (self.destination / "UPSTREAM.md").read_bytes()
        other = dict(self.bundle, name="other", destination="skills/writing/vendor/other", patches=["patches/broken.patch"])
        (self.root / "patches/broken.patch").write_text("Not a patch.\n")
        self.bundle["patches"] = []
        self.write_manifest([self.bundle, other])
        self.assertNotEqual(self.sync().returncode, 0)
        self.assertEqual((self.destination / "guide.txt").read_text(), "Local guidance.\n")
        self.assertEqual((self.destination / "UPSTREAM.md").read_bytes(), before)
        self.assertFalse((self.root / other["destination"]).exists())

    def test_copy_selection_omits_unneeded_upstream_files(self):
        # Single-file workflows must not pull in unrelated upstream development files.
        self.bundle.update(include=["SKILL.md", "LICENSE"], patches=[])
        self.write_manifest([self.bundle])
        self.assertEqual(self.sync().returncode, 0)
        self.assertTrue((self.destination / "LICENSE").is_file())
        self.assertFalse((self.destination / "guide.txt").exists())

    def test_output_must_stay_in_a_vendor_directory(self):
        # A manifest mistake must not replace another part of the repository.
        self.bundle["destination"] = "../outside"
        self.write_manifest([self.bundle])
        result = self.sync()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination", result.stderr)


if __name__ == "__main__":
    unittest.main()
