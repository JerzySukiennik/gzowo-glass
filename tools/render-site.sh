#!/bin/bash
# Regenerate everything the website shows from the current model:
#   SCAD -> STL -> Blender stills + turntable frames + GLB -> docs/assets/<version>/ + manifest.json
# Usage: tools/render-site.sh <version> "<one-line change note>" [--placeholder]
set -e
cd "$(dirname "$0")/.."
VER="${1:?version, e.g. v0.5}"; NOTE="${2:?change note}"; PH="$3"
B=/Applications/Blender.app/Contents/MacOS/Blender
DEST="docs/assets/$VER"; mkdir -p "$DEST/frames"

echo "== STL"; cad/export-all.sh >/dev/null
echo "== stills"; $B -b -P cad/glass_build.py -- site 2>&1 | grep -E "RENDERED|Traceback|Error" || true
echo "== frames"; $B -b -P cad/glass_build.py -- frames 2>&1 | grep -E "RENDERED|Traceback|Error" || true
echo "== glb";    $B -b -P cad/glass_build.py -- glb 2>&1 | grep -E "EXPORTED|Traceback|Error" || true

# stills -> webp (2400 px hero, 1600 px others)
for n in hero front pod eye left head; do
  ffmpeg -loglevel error -y -i "renders/site-$n.png" -vf "scale=2000:-1" -c:v libwebp -quality 88 "$DEST/$n.webp"
done
# frames -> webp 1200 px
i=0; for f in renders/frames/f*.png; do
  ffmpeg -loglevel error -y -i "$f" -vf "scale=1200:-1" -c:v libwebp -quality 82 "$DEST/frames/$(printf 'f%03d' $i).webp"; i=$((i+1))
done
cp renders/glass.glb "$DEST/glass.glb"
cp renders/glass-exploded.png "$DEST/exploded.png" 2>/dev/null || true

PLACEHOLDER=false; [ "$PH" = "--placeholder" ] && PLACEHOLDER=true
python3 - "$VER" "$NOTE" "$i" "$PLACEHOLDER" <<'PY'
import json, sys, datetime, os
ver, note, n, ph = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4] == 'true'
p = 'docs/assets/manifest.json'
m = json.load(open(p)) if os.path.exists(p) else {"versions": []}
m['versions'] = [v for v in m['versions'] if v['version'] != ver]
m['versions'].append({"version": ver, "date": datetime.date.today().isoformat(), "note": note, "frames": n, "placeholder": ph})
m['versions'].sort(key=lambda v: v['version'])
m['current'] = ver
json.dump(m, open(p, 'w'), indent=1)
print('manifest ->', ver, 'placeholder' if ph else 'final', n, 'frames')
PY
