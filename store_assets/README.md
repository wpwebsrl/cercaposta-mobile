# CercaPosta App Store assets

The `app-store-assets` workflow creates deterministic App Store screenshots
without connecting to a real server or mailbox.

## What is generated

- 5 Italian iPhone 6.9-inch screenshots (`1320 × 2868`)
- 5 English iPhone 6.9-inch screenshots (`1320 × 2868`)
- 5 Italian iPad 13-inch screenshots (`2064 × 2752`)
- 5 English iPad 13-inch screenshots (`2064 × 2752`)
- four small contact sheets for visual review
- `manifest.json`, which lists captions, filenames and dimensions

All upload files are RGB PNGs without an alpha channel. The fixtures contain
only invented names, addresses and messages.

## Generate in GitHub Actions

1. Open **Actions → App Store assets**.
2. Select **Run workflow** on `main`.
3. Download the `cercaposta-app-store-assets` artifact when the job completes.
4. Review the four files under `output/review`.
5. Upload only the PNGs under:
   - `output/it/iphone-6.9`
   - `output/it/ipad-13`
   - `output/en/iphone-6.9`
   - `output/en/ipad-13`

Do not upload `output/review` or `output/manifest.json` to App Store Connect.

## Generate locally

With Flutter 3.32.3 and Python 3 installed:

```bash
flutter pub get
mkdir -p store_assets/raw store_assets/output
flutter test tool/store_assets/store_screenshots_test.dart --update-goldens
python3 -m venv .store-assets-venv
. .store-assets-venv/bin/activate
python -m pip install Pillow==11.3.0
python tool/store_assets/build_store_assets.py
```

The Flutter test renders production widgets with provider/API fakes scoped to
the test process. There is no screenshot/demo flag in the shipped application.

## Scene order

1. Search results
2. AI answer with original-email references
3. Email reader and attachments
4. Replies and follow-ups
5. Secure login methods

Keep this order in App Store Connect: it tells the product story from discovery
to intelligence, daily workflow and security.
