# CercaPosta — mobile app

Flutter client (Android + iOS) for **CercaPosta**, the intelligent e-mail
archive by [wpweb S.R.L.](https://www.wpweb.com) The app is a thin,
read-only client: search, AI chat and viewing of an archive hosted on a
CercaPosta server. All data, authentication and encryption live server-side;
the server address is entered by the user at first launch.

The server is a separate, private codebase. This repository contains the
mobile client only and is public so that CI builds (including iOS) can run
on GitHub-hosted runners.

## Build

Requirements: Flutter (see `FLUTTER_VERSION` in
`.github/workflows/mobile.yml`), Dart ≥ 3.

```bash
flutter pub get
flutter run              # debug, device/emulator of your choice
flutter test             # unit/widget tests
flutter analyze          # static analysis
```

Release builds are produced by CI (`.github/workflows/mobile.yml`):

- **push / PR** — analyze + tests + debug APK + unsigned iOS compile check;
- **manual dispatch** — signed Android App Bundle and/or iOS build uploaded
  to TestFlight (signing material comes from GitHub Secrets; forks receive
  no secrets).

## Passkeys

Passkeys are optional and use the native Android/iOS account chooser. The app is associated with
the production relying-party host `app.cercaposta.it`: Android verifies the server's Digital Asset
Links document, while iOS uses the `webcredentials:` Associated Domain entitlement. The server must
publish the matching release signing certificate / Apple Team ID. Password sign-in remains the
fallback, including on Android versions below API 28.

An encrypted archive still needs its password or recovery kit on a new/untrusted device: a passkey
authenticates the account, but it does not contain the archive decryption key.

## License

Proprietary — source available for transparency and build purposes only.
See [LICENSE](LICENSE).
