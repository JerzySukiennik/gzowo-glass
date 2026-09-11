#!/bin/bash
# Export every printable part of glass.scad to cad/stl/. The folder is a BUILD
# OUTPUT: it is wiped first so stale files cannot survive.
set -e
cd "$(dirname "$0")"
O=/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD
rm -rf stl && mkdir -p stl
PARTS="front pod_r pod_l lid_r lid_l temple_r temple_l"
for p in $PARTS; do
  ( $O -o "stl/$p.stl" -D "part=\"$p\"" -D "show_parts=false" glass.scad 2>&1 | grep -iE "error|warning" | grep -v "Deprecated" || true ; echo "exported $p" ) &
done
wait
ls -la stl
