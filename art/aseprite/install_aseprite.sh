#!/usr/bin/env bash
# Compiles a headless (no window) Aseprite into .tools/aseprite/bin for the Lua art scripts.
# Aseprite's EULA allows compiling for personal use only: never commit or share the binary.
# Needs git, cmake, ninja and a C++ compiler. On Debian/Ubuntu also:
#   apt-get install -y libxcursor-dev libxi-dev libxrandr-dev libfontconfig1-dev libgl1-mesa-dev
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TAG="${ASEPRITE_TAG:-v1.3.18.6}"
SRC="$ROOT/.tools/aseprite-src"
DEST="$ROOT/.tools/aseprite/bin"
if [ ! -d "$SRC/.git" ]; then
  git clone --recursive --depth 1 --branch "$TAG" https://github.com/aseprite/aseprite.git "$SRC"
fi
# The build downloads libjpeg-turbo as a GitHub archive. Some proxies refuse archive
# downloads, so fetch it with git and point the build at the checkout instead.
JPEG="$ROOT/.tools/libjpeg-turbo"
if [ ! -d "$JPEG/.git" ]; then
  git clone --depth 1 --branch 3.0.2 https://github.com/libjpeg-turbo/libjpeg-turbo.git "$JPEG"
fi
sed -i "s|URL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.2.zip|SOURCE_DIR $JPEG|; /URL_HASH SHA512=/d; /DOWNLOAD_EXTRACT_TIMESTAMP ON/d" "$SRC/cmake/FindJpegTurbo.cmake"
cmake -S "$SRC" -B "$SRC/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DLAF_BACKEND=none -DENABLE_UI=OFF -DENABLE_NEWS=OFF -DENABLE_UPDATER=OFF \
  -DENABLE_WEBSOCKET=OFF -DENABLE_CCACHE=OFF -DLAF_WITH_EXAMPLES=OFF -DLAF_WITH_TESTS=OFF
cmake --build "$SRC/build" --target aseprite
mkdir -p "$DEST"
cp -r "$SRC/build/bin/." "$DEST/"
"$DEST/aseprite" --version
