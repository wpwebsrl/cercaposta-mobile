"""Guard isolation, accepted licences and binary preservation in SDK preparation."""
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from prepare_android_sdk17 import prepare


class SdkProfile(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cercaposta-sdk-fixture-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source, self.target = self.root / "original", self.root / "build-sdk"
        for relative in ("licenses", "cmdline-tools/19.0/bin", "build-tools/35.0.0",
                         "platform-tools", "platforms/android-36"):
            (self.source / relative).mkdir(parents=True)
        (self.source / "licenses/accepted-existing").write_text("existing acceptance record\n")
        (self.source / "cmdline-tools/19.0/bin" / ("sdkmanager.bat" if os.name == "nt" else "sdkmanager")).write_text("fixture")
        (self.source / "cmdline-tools/19.0/source.properties").write_text("Pkg.Revision=19.0\n")
        (self.source / "platforms/android-36/source.properties").write_text("Pkg.Revision=2\nAndroidVersion.ApiLevel=36\n")
        (self.source / "platforms/android-36/android.jar").write_bytes(b"platform fixture")
        (self.source / "platforms/android-36/package.xml").write_text('<r xmlns:s="http://schemas.android.com/sdk/android/repo/repository2/03"/>')
        (self.source / "platform-tools/adb").write_bytes(b"platform tools fixture")

    def manager(self, command, **kwargs):
        self.assertNotIn("--licenses", command)
        self.assertEqual(kwargs["stdin"], subprocess.DEVNULL)
        destination = Path(next(p.split("=", 1)[1] for p in command if p.startswith("--sdk_root=")))
        for package in (p for p in command if p.startswith("cmdline-tools;")):
            version = package.split(";")[1]
            installed = destination / "cmdline-tools" / version
            shutil.copytree(self.source / "cmdline-tools" / version, installed, dirs_exist_ok=True)
            (installed / "package.xml").write_text(
                '<r xmlns:s="http://schemas.android.com/sdk/android/repo/repository2/03">'
                f'<localPackage path="{package}"><revision><major>{version.split(".")[0]}</major>'
                '</revision></localPackage></r>')
        if "platforms;android-36" in command:
            for relative in ("platform-tools", "platforms/android-36"):
                shutil.copytree(self.source / relative, destination / relative, dirs_exist_ok=True)
        return subprocess.CompletedProcess(command, 0)

    def invoke(self, source=None, target=None, manager=None):
        with patch("prepare_android_sdk17.require_jdk17"), patch("prepare_android_sdk17.subprocess.run", side_effect=manager or self.manager):
            return prepare(source or self.source, target or self.target, self.root / "jdk17")

    def test_separate_profile_preserves_binaries_and_existing_licences(self):
        result = self.invoke()
        self.assertEqual(result["state"], "verified")
        self.assertTrue(all(p["identical"] for p in result["comparisons"].values()))
        self.assertEqual((self.target / "licenses/accepted-existing").read_text(), "existing acceptance record\n")
        self.assertEqual((self.source / "platforms/android-36/android.jar").read_bytes(), b"platform fixture")

    def test_original_or_nested_sdk_is_rejected(self):
        for target in (self.source, self.source / "nested"):
            with self.subTest(target=target), self.assertRaisesRegex(ValueError, "separate"):
                self.invoke(target=target)

    def test_nonempty_unmarked_destination_is_rejected(self):
        self.target.mkdir()
        (self.target / "unrelated").write_text("keep")
        with self.assertRaisesRegex(ValueError, "nonempty"):
            self.invoke()
        self.assertEqual((self.target / "unrelated").read_text(), "keep")

    def test_changed_platform_bytes_are_rejected(self):
        def changed(command, **kwargs):
            result = self.manager(command, **kwargs)
            if "platforms;android-36" in command:
                (self.target / "platforms/android-36/android.jar").write_bytes(b"unexpected")
            return result
        with self.assertRaisesRegex(ValueError, "differs"):
            self.invoke(manager=changed)

    def test_changed_platform_revision_requires_review(self):
        for revision in (3, 20):
            (self.source / "platforms/android-36/source.properties").write_text(f"Pkg.Revision={revision}\nAndroidVersion.ApiLevel=36\n")
            with self.subTest(revision=revision), self.assertRaisesRegex(ValueError, "revision changed"):
                self.invoke()

    def test_marked_profile_cannot_switch_to_another_source(self):
        self.target.mkdir()
        (self.target / "cercaposta-build-sdk.json").write_text(json.dumps({"original_sdk": str(self.root / "another-sdk")}))
        with self.assertRaisesRegex(ValueError, "another source SDK"):
            self.invoke()

    def test_xml_schema_change_is_rejected_even_if_package_bytes_match(self):
        def changed(command, **kwargs):
            result = self.manager(command, **kwargs)
            if "platforms;android-36" in command:
                (self.target / "platforms/android-36/package.xml").write_text('<r xmlns:s="http://schemas.android.com/sdk/android/repo/repository2/04"/>')
            return result
        with self.assertRaisesRegex(ValueError, "schema changed"):
            self.invoke(manager=changed)

    def test_tool_registration_copies_only_installer_metadata_and_is_reused(self):
        first = self.invoke()
        tools = self.target / "cmdline-tools/19.0"
        self.assertEqual(first["newly_registered_command_line_tools"], 1)
        self.assertFalse((self.source / "cmdline-tools/19.0/package.xml").exists())
        self.assertEqual((tools / "source.properties").read_bytes(),
                         (self.source / "cmdline-tools/19.0/source.properties").read_bytes())
        metadata = (tools / "package.xml").read_bytes()
        second = self.invoke()
        self.assertEqual(second["newly_registered_command_line_tools"], 0)
        self.assertEqual((tools / "package.xml").read_bytes(), metadata)

    def test_unreviewed_tools_version_or_mismatched_directory_is_rejected(self):
        (self.source / "cmdline-tools/19.0/source.properties").write_text("Pkg.Revision=20.0\n")
        with self.assertRaisesRegex(ValueError, "directory/revision mismatch"):
            self.invoke()
        (self.target / "cmdline-tools/19.0/source.properties").write_text("Pkg.Revision=19.0\n")
        other = self.target / "cmdline-tools/20.0"
        other.mkdir()
        (other / "source.properties").write_text("Pkg.Revision=20.0\n")
        with self.assertRaisesRegex(ValueError, "Review unregistered"):
            self.invoke()

    def test_changed_official_tool_bytes_do_not_register_the_existing_tools(self):
        def changed(command, **kwargs):
            result = self.manager(command, **kwargs)
            destination = Path(next(p.split("=", 1)[1] for p in command if p.startswith("--sdk_root=")))
            (destination / "cmdline-tools/19.0/source.properties").write_text("Pkg.Revision=19.0\nchanged=true\n")
            return result
        with self.assertRaisesRegex(ValueError, "tools differ"):
            self.invoke(manager=changed)
        self.assertFalse((self.target / "cmdline-tools/19.0/package.xml").exists())

    def test_wrong_installer_identity_or_revision_is_rejected(self):
        for before, after, message in (("cmdline-tools;19.0", "cmdline-tools;23.0", "identity"),
                                       ("<major>19</major>", "<major>20</major>", "revision")):
            def changed(command, **kwargs):
                result = self.manager(command, **kwargs)
                destination = Path(next(p.split("=", 1)[1] for p in command if p.startswith("--sdk_root=")))
                metadata = destination / "cmdline-tools/19.0/package.xml"
                metadata.write_text(metadata.read_text().replace(before, after))
                return result
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                self.invoke(manager=changed)
            self.assertFalse((self.target / "cmdline-tools/19.0/package.xml").exists())

    def test_tool_metadata_schema_is_validated_before_copying(self):
        def changed(command, **kwargs):
            result = self.manager(command, **kwargs)
            destination = Path(next(p.split("=", 1)[1] for p in command if p.startswith("--sdk_root=")))
            metadata = destination / "cmdline-tools/19.0/package.xml"
            metadata.write_text(metadata.read_text().replace("repository2/03", "repository2/04"))
            return result
        with self.assertRaisesRegex(ValueError, "schema changed"):
            self.invoke(manager=changed)
        self.assertFalse((self.target / "cmdline-tools/19.0/package.xml").exists())

    def test_all_tool_packages_are_checked_before_any_metadata_is_copied(self):
        original = self.source / "cmdline-tools/23.0"
        shutil.copytree(self.source / "cmdline-tools/19.0", original)
        (original / "source.properties").write_text("Pkg.Revision=23.0\n")
        self.target.mkdir()
        (self.target / "cercaposta-build-sdk.json").write_text(json.dumps({"original_sdk": str(self.source)}))
        shutil.copytree(original, self.target / "cmdline-tools/23.0")
        def changed(command, **kwargs):
            result = self.manager(command, **kwargs)
            destination = Path(next(p.split("=", 1)[1] for p in command if p.startswith("--sdk_root=")))
            (destination / "cmdline-tools/23.0/source.properties").write_text("changed")
            return result
        with self.assertRaisesRegex(ValueError, "tools differ"):
            self.invoke(manager=changed)
        for version in ("19.0", "23.0"):
            self.assertFalse((self.target / "cmdline-tools" / version / "package.xml").exists())


if __name__ == "__main__":
    unittest.main()
