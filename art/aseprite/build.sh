#!/usr/bin/env bash
# Linux/macOS twin of build.ps1. Builds scene scripts into art/aseprite/out/ for review;
# with --install also copies the PNGs into art/pixels/.
#   art/aseprite/build.sh [--install] [scene ...]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
INSTALL=0
SCENES=()
for arg in "$@"; do
  if [ "$arg" = "--install" ]; then INSTALL=1; else SCENES+=("$arg"); fi
done
EXE="${ASEPRITE:-}"
if [ -z "$EXE" ]; then
  if [ -x "$ROOT/.tools/aseprite/bin/aseprite" ]; then EXE="$ROOT/.tools/aseprite/bin/aseprite"
  elif command -v aseprite >/dev/null; then EXE="$(command -v aseprite)"
  else echo "Aseprite not found: run art/aseprite/install_aseprite.sh or set ASEPRITE" >&2; exit 1; fi
fi
OUT="$HERE/out"
mkdir -p "$OUT/preview"
: > "$OUT/.gdignore"
rm -f "$OUT"/*.png "$OUT"/preview/*.png
if [ ${#SCENES[@]} -eq 0 ]; then
  for f in "$HERE"/scenes/*.lua; do SCENES+=("$(basename "$f" .lua)"); done
fi
for scene in "${SCENES[@]}"; do
  LOG="$("$EXE" -b --script-param "kit=$HERE/lib.lua" --script-param "out=$OUT" --script "$HERE/scenes/$scene.lua" 2>&1)" || { echo "$LOG"; exit 1; }
  echo "$LOG"
  if echo "$LOG" | grep -q '\.lua:[0-9]*:'; then echo "Scene failed: $scene" >&2; exit 1; fi
done
for png in "$OUT"/*.png; do
  name="$(basename "$png" .png)"
  "$EXE" -b "$png" --scale 3 --save-as "$OUT/preview/${name}_x3.png" >/dev/null
  if [ "$INSTALL" = 1 ]; then cp "$png" "$ROOT/art/pixels/$name.png"; echo "installed art/pixels/$name.png"; fi
done
echo "Review copies: $OUT/preview"
