#!/usr/bin/env bash
# The web version: libusb (Emscripten/WebUSB backend) -> kepyur.{js,wasm} -> the site in build/web/site.
# Run inside nix-shell (or nix-shell --arg web true). Serve it locally with: node web/serve.mjs
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/build/web
export EM_CACHE=${EM_CACHE:-$OUT/emcache}

# Keep the pinned wifi-sdr submodule unchanged in Git history while enabling
# the T3U (2357:012D) as an RTL8822B alias for this web-only build.
MODEL="$ROOT/third_party/wifi-sdr/src/receiver.h"
if ! grep -q 'pid == 0x012d' "$MODEL"; then
  if ! grep -q 'vid == 0x2357 && pid == 0x0115' "$MODEL"; then
    echo "T3U support: wifi-sdr model_pid changed upstream; stop for review" >&2
    exit 1
  fi
  sed -i 's/vid == 0x2357 && pid == 0x0115/vid == 0x2357 \&\& (pid == 0x0115 || pid == 0x012d)/' "$MODEL"
fi
grep -q 'pid == 0x012d' "$MODEL"

tool() { command -v "${KEPYUR_MIPS_PREFIX:-mipsel-unknown-linux-gnu-}$1" || command -v "mipsel-linux-gnu-$1"; }

emcmake cmake -S "$ROOT/web/libusb" -B "$OUT/libusb" -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DLIBUSB_SRC="$ROOT/third_party/libusb" -DWSDR_EXC_FLAGS="-fwasm-exceptions;-pthread" \
  -DCMAKE_INSTALL_PREFIX="$OUT/prefix" >/dev/null
cmake --build "$OUT/libusb"
cmake --install "$OUT/libusb" >/dev/null

# devourer finds libusb with pkg-config; emcmake passes EM_PKG_CONFIG_PATH on, and nix's pkg-config wrapper reads
# its per-platform variable instead of PKG_CONFIG_PATH
EM_PKG_CONFIG_PATH=$OUT/prefix/lib/pkgconfig PKG_CONFIG_PATH_x86_64_unknown_linux_gnu=$OUT/prefix/lib/pkgconfig \
  emcmake cmake -S "$ROOT/web" -B "$OUT/wasm" -G Ninja -DCMAKE_BUILD_TYPE=Release -DLIBUSB_PREFIX="$OUT/prefix" \
  -DMIPS_AS="$(tool as)" -DMIPS_LD="$(tool ld)" -DMIPS_OBJCOPY="$(tool objcopy)" >/dev/null
cmake --build "$OUT/wasm" --target kepyur

rm -rf "$OUT/site"
cp -r "$ROOT/web/site" "$OUT/site"
cp "$OUT/wasm/kepyur.js" "$OUT/wasm/kepyur.wasm" "$OUT/site/"
# the build's commit, shown in ?debug
echo "export const BUILD = '$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo dev)';" >"$OUT/site/build.js"
ls -la "$OUT/site"
