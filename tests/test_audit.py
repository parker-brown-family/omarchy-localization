"""Run the audit against fixtures and the real installed Omarchy source."""
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).parent
AUDIT = HERE.parent / "skills/omarchy-localization/scripts/omarchy-l10n-audit"
OMARCHY = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy"))


def run(fixture):
    out = subprocess.run([sys.executable, str(AUDIT), "--json", "--omarchy", str(OMARCHY), str(HERE / "fixtures" / fixture)],
                         capture_output=True, text=True)
    return out.returncode, json.loads(out.stdout or "[]")


@unittest.skipUnless((OMARCHY / "default/i18n/locales.json").exists(), "needs an Omarchy source tree")
class Audit(unittest.TestCase):
    def test_good_plugin_passes(self):
        code, items = run("good")
        self.assertEqual(code, 0, [i for i in items if i["level"] == "error"])
        self.assertFalse([i for i in items if i["level"] == "warning"])

    def test_bad_plugin_trips_every_rule(self):
        code, items = run("bad")
        self.assertEqual(code, 1)
        text = "\n".join(f'{i["level"]} {i["where"]} {i["message"]}' for i in items)
        for expected in [
            "input methods",             # Keys.onPressed event.text
            "not an Omarchy language code",  # zh_CN.json
            "lacks plural categories ['few', 'many'] that ru uses for everyday counts",
            "no Commons.Translations",
            "hardcoded string \"Type a reminder\"",
            "Qt.formatDate",
            "formatNumber",
            "password field without an input-method guard",
        ]:
            self.assertIn(expected, text)

    def test_base_language_and_sidecar_accepted(self):
        code, items = run("regional")
        self.assertEqual(code, 0, [i for i in items if i["level"] == "error"])
        text = "\n".join(i["message"] for i in items)
        self.assertIn("sidecar file", text)
        self.assertIn("only for counts like 1000000", text)  # fr many: a warning, not an error

    def test_missing_source_is_unknown_not_pass(self):
        out = subprocess.run([sys.executable, str(AUDIT), "--omarchy", "/nonexistent", str(HERE / "fixtures/good")],
                             capture_output=True, text=True)
        self.assertEqual(out.returncode, 2)


if __name__ == "__main__":
    unittest.main()
