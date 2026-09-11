# Gzowo Glass — G.L.A.S.S.

Home-built smart glasses: a see-through HUD in front of the right eye (0.96" OLED →
fold mirror → f=50 lens → 50/50 beam splitter) driven by a XIAO ESP32-S3 Sense, with a
voice assistant (Gemini Live, Polish) running on a home server.
G.L.A.S.S. = *Gadget Labelled As Super Secret*.

## Repo layout

- `cad/glass.scad` — the print-ready parametric frame (OpenSCAD 2021.01). Source of truth.
- `cad/export-all.sh` — exports every part to `cad/stl/` (build output, wiped each run).
- `cad/glass_build.py` — Blender 4.5 script: imports the STLs, adds lenses/optics/mannequin, renders stills and a turntable into `renders/`.
- `SHOPPING.md` — parts list with prices.
- `RESEARCH.md` — what other DIY smart-glasses builds got right and wrong.

## Regenerate

```bash
cad/export-all.sh
/Applications/Blender.app/Contents/MacOS/Blender -b -P cad/glass_build.py -- stills
/Applications/Blender.app/Contents/MacOS/Blender -b -P cad/glass_build.py -- turntable
```
