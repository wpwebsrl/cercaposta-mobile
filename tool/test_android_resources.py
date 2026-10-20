"""Protect the no-backup policy and Flutter's dynamically resolved notification icon."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "android/app/src/main"
ANDROID = "{http://schemas.android.com/apk/res/android}"
TOOLS = "{http://schemas.android.com/tools}"
DOMAINS = {
    "root", "file", "database", "sharedpref", "external",
    "device_root", "device_file", "device_database", "device_sharedpref",
}


class AndroidResources(unittest.TestCase):
    def test_lint_exceptions_keep_unrelated_findings_enabled(self):
        configuration = ET.parse(ROOT / "android/app/lint.xml").getroot()
        issues = {issue.get("id"): issue for issue in configuration}
        self.assertEqual(set(issues), {"UnusedAttribute", "IconLauncherShape"})
        self.assertTrue(all(set(issue.attrib) == {"id"} for issue in issues.values()))
        locale = list(issues["UnusedAttribute"])
        self.assertEqual(len(locale), 1)
        self.assertEqual(set(locale[0].attrib), {"regexp"})
        pattern = locale[0].get("regexp")
        self.assertRegex("Attribute `localeConfig` is only used in API level 33 and higher (current min is 23)", pattern)
        for message in ("Attribute `unrelated` is only used in API level 33 and higher (current min is 23)",
                        "Attribute `localeConfig` is only used in API level 33 and higher (current min is 22)"):
            self.assertIsNone(re.search(pattern, message))
        self.assertEqual({tuple(node.attrib.items()) for node in issues["IconLauncherShape"]},
                         {(("path", f"src/main/res/mipmap-{density}/ic_launcher.png"),)
                          for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")})
        app = ET.parse(MAIN / "AndroidManifest.xml").find("application")
        self.assertEqual(app.get(ANDROID + "localeConfig"), "@xml/locales_config")
        build = (ROOT / "android/app/build.gradle.kts").read_text()
        self.assertRegex(build, r"warningsAsErrors\s*=\s*true")

    def test_sensitive_data_is_excluded_from_both_backup_transports(self):
        app = ET.parse(MAIN / "AndroidManifest.xml").find("application")
        self.assertEqual(app.get(ANDROID + "allowBackup"), "false")
        self.assertEqual(app.get(ANDROID + "fullBackupContent"), "false")
        reference = app.get(ANDROID + "dataExtractionRules")
        self.assertTrue(reference.startswith("@xml/"))
        rules = ET.parse(MAIN / "res/xml" / (reference[5:] + ".xml")).getroot()
        self.assertEqual(rules.tag, "data-extraction-rules")
        for transport in ("cloud-backup", "device-transfer"):
            with self.subTest(transport=transport):
                section = rules.find(transport)
                self.assertIsNotNone(section)
                self.assertFalse(section.findall("include"))
                self.assertEqual(
                    {(node.get("domain"), node.get("path")) for node in section},
                    {(domain, ".") for domain in DOMAINS},
                )

    def test_notification_icon_survives_resource_shrinking(self):
        source = (ROOT / "lib/core/notify/notify_service.dart").read_text(encoding="utf-8")
        icon = re.search(r"AndroidInitializationSettings\('(@drawable/[^']+)'\)", source)
        self.assertIsNotNone(icon)
        reference = icon.group(1)
        self.assertTrue((MAIN / "res/drawable" / (reference.split("/")[1] + ".xml")).is_file())
        kept = set()
        for file in (MAIN / "res/raw").glob("*.xml"):
            kept.update(ET.parse(file).getroot().get(TOOLS + "keep", "").split(","))
        self.assertIn(reference, kept)


if __name__ == "__main__":
    unittest.main()
