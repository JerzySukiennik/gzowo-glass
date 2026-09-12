#!/bin/bash
# Regenerate everything the website shows from the current model:
#   SCAD -> STL -> Blender stills + turntable frames + GLB -> docs/glass/assets/<version>/ + manifest.json
# Usage: tools/render-site.sh <version> "<one-line change note>" [--placeholder]
set -e
cd "$(dirname "$0")/.."
VER="${1:?version, e.g. v0.5}"; NOTE="${2:?change note}"; PH="$3"; ONLY="$4"   # 4th arg --convert-only reuses renders/
B=/Applications/Blender.app/Contents/MacOS/Blender
DEST="docs/glass/assets/$VER"; mkdir -p "$DEST/frames"

if [ "$ONLY" != "--convert-only" ]; then
echo "== STL"; cad/export-all.sh >/dev/null
echo "== stills"; $B -b -P cad/glass_build.py -- site 2>&1 | grep -E "RENDERED|Traceback|Error" || true
echo "== frames"; rm -rf renders/frames; $B -b -P cad/glass_build.py -- frames 2>&1 | grep -E "RENDERED|Traceback|Error" || true
echo "== glb";    $B -b -P cad/glass_build.py -- glb 2>&1 | grep -E "EXPORTED|Traceback|Error" || true
fi

# stills + frames -> webp via Pillow (the bundled ffmpeg has no libwebp)
python3 - "$DEST" <<'PY'
import sys, glob, os
from PIL import Image
dest = sys.argv[1]
def conv(src, dst, w, q):
    im = Image.open(src); im = im.convert('RGBA'); im.thumbnail((w, w * 2), Image.LANCZOS); im.save(dst, 'WEBP', quality=q, method=4)
for n in ['hero', 'front', 'pod', 'eye', 'left', 'head']:
    conv(f'renders/site-{n}.png', f'{dest}/{n}.webp', 2000, 88)
frames = sorted(glob.glob('renders/frames/f*.png'))
for i, f in enumerate(frames):
    conv(f, f'{dest}/frames/f{i:03d}.webp', 1200, 82)
open(f'{dest}/.count', 'w').write(str(len(frames)))
print('webp', len(frames), 'frames + 6 stills')
PY
i=$(cat "$DEST/.count"); rm -f "$DEST/.count"
cp renders/glass.glb "$DEST/model.glb"
cp renders/glass-exploded.png "$DEST/exploded.png" 2>/dev/null || true

PLACEHOLDER=false; [ "$PH" = "--placeholder" ] && PLACEHOLDER=true
python3 - "$VER" "$NOTE" "$i" "$PLACEHOLDER" <<'PY'
import json, sys, datetime, os
ver, note, n, ph = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4] == 'true'
p = 'docs/glass/assets/manifest.json'
m = json.load(open(p)) if os.path.exists(p) else {"versions": []}
m['versions'] = [v for v in m['versions'] if v['version'] != ver]
m['versions'].append({"version": ver, "date": datetime.date.today().isoformat(), "note": note, "frames": n, "placeholder": ph})
m['versions'].sort(key=lambda v: v['version'])
m['current'] = ver
json.dump(m, open(p, 'w'), indent=1)
print('manifest ->', ver, 'placeholder' if ph else 'final', n, 'frames')
PY
