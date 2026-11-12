# T3U WebUSB test build

This branch is an **experimental** clone of [gilankpam/kepyur](https://github.com/gilankpam/kepyur) with TP-Link Archer T3U USB ID `2357:012D` added alongside T4U v3 `2357:0115` and Realtek `0BDA:B812`.

It does **not** change the `mshrem/kepyur` main Android APK branch.

## Web deployment

The `.github/workflows/pages.yml` workflow deploys this **t3u-web** branch to GitHub Pages via GitHub Actions. Set **Settings → Pages → Build and deployment → Source: GitHub Actions** in the fork and check the **Actions** page for a successful `pages` run. Until the workflow actually succeeds, `https://mshrem.github.io/kepyur/` is a proposed URL, not verified.

## Browser requirements

- Chrome or Edge on a **physical computer** where the Archer T3U is plugged in. WebUSB accesses the client computer's USB device, **not a USB device plugged into the Ubuntu VM or web server**.
- Windows: browser raw-USB access generally requires changing **only the Archer T3U** from its ordinary Realtek Wi-Fi driver to **WinUSB** with Zadig. Verify **USB ID `2357:012D`** before replacement. This disables normal Wi-Fi operation of that dongle in Windows until its original driver is restored. Do not modify the motherboard Wi-Fi adapter.
- A USB 3-capable host port and SuperSpeed connection. The browser currently watches at **20 MS/s**; this is an upstream WebUSB limitation, not an Android 40 MS/s test.

## Diagnostic workflow

Open the deployed URL with `?debug`, optionally `?debug&mhz=5658.37`. This fork **bypasses the initial band scan in debug mode** and tunes straight to the specified MHz. The debug panel has **20 MS/s** and **40 MS/s** streaming test buttons and **Copy report**; 40 MS/s may exceed what WebUSB can carry. Use the ordinary URL for the upstream scan-first UI.

For a more reliable hardware comparison:
1. Confirm the T3U has SuperSpeed on the host PC.
2. Use `?debug&mhz=5658.37` and the **20 MS/s test**; record the duration, errors and restarts.
3. Compare against the same dongle and frequency on the Pixel using Android Kepyur.
4. Treat a stalled WebUSB trace as a software/host result, not standalone proof that the dongle is defective.

## Build locally

```sh
git checkout t3u-web
git submodule update --init third_party/libusb third_party/wifi-sdr
git -C third_party/wifi-sdr submodule update --init external/devourer
nix-shell --arg web true --run scripts/build-web.sh
```

The build script applies a local alias to the checked-out `wifi-sdr/src/receiver.h` without committing a change to the submodule. The generated site is `build/web/site`. The upstream local server runs with cross-origin isolation at `http://localhost:8080` via `node web/serve.mjs`. Opening a local HTML file using `file://` is **not** supported because WebUSB/worker isolation requires a suitable secure context.

## Limitations

Not yet built and tested on a physical T3U via WebUSB. No EEPROM/eFuse/firmware flashing is involved. License: GPL-2.0, following upstream and wifi-sdr.
