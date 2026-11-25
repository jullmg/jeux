#!/bin/sh
# tools/montage.sh sortie.png colonnes largeur images…
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
"$BLENDER" --background --factory-startup --python-exit-code 1 --python "$(dirname "$0")/blender/montage.py" -- "$@" | grep PLANCHE
