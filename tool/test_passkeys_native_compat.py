"""Exercise the actual staged Java plugin across simulated Android API boundaries."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class PasskeysNativeCompatibility(unittest.TestCase):
    def test_staged_plugin_preserves_signers_and_uses_available_api_overloads(self):
        root = Path(__file__).resolve().parents[1]
        manifest = root / "tool/android_compat_patches.json"
        stamp = hashlib.sha256(manifest.read_bytes()).hexdigest()[:20]
        relative = "src/main/java/com/corbado/passkeys_doctor/PasskeysDoctorPlugin.java"
        source = root / ".dart_tool/android-compat" / stamp / "plugins/passkeys_doctor/android" / relative
        expected = next(f["after_sha256"] for c in json.loads(manifest.read_text(encoding="utf-8"))["components"]
                        if c["name"] == "passkeys_doctor" for f in c["files"] if f["path"] == relative)
        self.assertTrue(source.is_file(), "Run the Android build to stage the reviewed plugin")
        self.assertEqual(hashlib.sha256(source.read_text(encoding="utf-8").encode()).hexdigest(), expected)
        legacy = ":".join(f"{b:02X}" for b in hashlib.sha256(b"legacy").digest())
        current = ":".join(f"{b:02X}" for b in hashlib.sha256(b"current").digest())
        files = {
            "android/os/Build.java": "package android.os; public class Build { public static class VERSION { public static int SDK_INT; } public static class VERSION_CODES { public static final int P=28; } }",
            "androidx/annotation/NonNull.java": "package androidx.annotation; public @interface NonNull {}",
            "android/content/pm/Signature.java": "package android.content.pm; public class Signature { private final byte[] bytes; public Signature(String value) { bytes=value.getBytes(java.nio.charset.StandardCharsets.UTF_8); } public byte[] toByteArray() { return bytes; } }",
            "android/content/pm/SigningInfo.java": "package android.content.pm; public class SigningInfo { public Signature[] getApkContentsSigners() { return new Signature[]{new Signature(\"current\")}; } }",
            "android/content/pm/PackageInfo.java": "package android.content.pm; public class PackageInfo { public SigningInfo signingInfo=new SigningInfo(); public Signature[] signatures={new Signature(\"legacy\")}; }",
            "android/content/pm/PackageManager.java": """package android.content.pm;
public class PackageManager {
  public static final int GET_SIGNATURES=64, GET_SIGNING_CERTIFICATES=0x08000000;
  public static int oldCalls, newCalls;
  public static class NameNotFoundException extends Exception {}
  public static class PackageInfoFlags { final long bits; private PackageInfoFlags(long n){bits=n;} public static PackageInfoFlags of(long n){return new PackageInfoFlags(n);} }
  public PackageInfo getPackageInfo(String name, int flags) throws NameNotFoundException {
    if(android.os.Build.VERSION.SDK_INT>=33) throw new AssertionError("old overload used on modern API");
    if(flags != (android.os.Build.VERSION.SDK_INT>=28 ? GET_SIGNING_CERTIFICATES : GET_SIGNATURES)) throw new AssertionError("wrong signer flags");
    oldCalls++; return new PackageInfo();
  }
  public PackageInfo getPackageInfo(String name, PackageInfoFlags flags) throws NameNotFoundException {
    if(android.os.Build.VERSION.SDK_INT<33 || flags.bits!=GET_SIGNING_CERTIFICATES) throw new AssertionError("modern API unavailable or wrong flags");
    newCalls++; return new PackageInfo();
  }
}""",
            "android/content/Context.java": "package android.content; public class Context { public android.content.pm.PackageManager getPackageManager(){return new android.content.pm.PackageManager();} public String getPackageName(){return \"synthetic.fixture\";} }",
            "io/flutter/embedding/engine/plugins/FlutterPlugin.java": "package io.flutter.embedding.engine.plugins; public interface FlutterPlugin { void onAttachedToEngine(FlutterPluginBinding b); void onDetachedFromEngine(FlutterPluginBinding b); class FlutterPluginBinding { public android.content.Context getApplicationContext(){return new android.content.Context();} public Object getBinaryMessenger(){return null;} } }",
            "com/corbado/passkeys_doctor/Messages.java": "package com.corbado.passkeys_doctor; class Messages { interface WebCredentialsApi { java.util.List<String> getFingerprints(); static void setUp(Object m,WebCredentialsApi a){} } static class FlutterError extends RuntimeException { FlutterError(String code,String message,Object detail){super(message);} } }",
            "Harness.java": """import android.os.Build; import android.content.pm.PackageManager;
import com.corbado.passkeys_doctor.PasskeysDoctorPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
public class Harness { public static void main(String[] args) {
  for(int api:new int[]{23,27,28,32,33,36}) {
    Build.VERSION.SDK_INT=api; PackageManager.oldCalls=PackageManager.newCalls=0;
    PasskeysDoctorPlugin plugin=new PasskeysDoctorPlugin(); plugin.onAttachedToEngine(new FlutterPluginBinding());
    if(!plugin.getFingerprints().equals(java.util.List.of(api<28?"LEGACY":"CURRENT"))) throw new AssertionError("signer fingerprint changed on API "+api);
    if(PackageManager.oldCalls!=(api<33?1:0) || PackageManager.newCalls!=(api>=33?1:0)) throw new AssertionError("wrong package API on "+api);
    plugin.onDetachedFromEngine(new FlutterPluginBinding());
    System.out.println("API "+api+": signer and overload verified");
  }
} }""".replace("LEGACY", legacy).replace("CURRENT", current),
        }
        java_home = Path(os.environ["JAVA_HOME"]) / "bin"
        suffix = ".exe" if os.name == "nt" else ""
        with tempfile.TemporaryDirectory(prefix="cercaposta-passkeys-native-") as temporary:
            folder = Path(temporary)
            files["com/corbado/passkeys_doctor/PasskeysDoctorPlugin.java"] = source.read_text(encoding="utf-8")
            paths = []
            for name, text in files.items():
                path = folder / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding="utf-8")
                paths.append(str(path))
            compile_result = subprocess.run([str(java_home / ("javac" + suffix)), "-encoding", "UTF-8", "--release", "11", "-d", str(folder), *paths],
                                            capture_output=True, text=True, encoding="utf-8", timeout=90)
            self.assertEqual(compile_result.returncode, 0, compile_result.stdout + compile_result.stderr)
            result = subprocess.run([str(java_home / ("java" + suffix)), "-cp", str(folder), "Harness"],
                                    capture_output=True, text=True, encoding="utf-8", timeout=90)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result.stdout.count(": signer and overload verified"), 6)


if __name__ == "__main__":
    unittest.main()
