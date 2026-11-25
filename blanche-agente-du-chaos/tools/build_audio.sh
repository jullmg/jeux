#!/bin/sh
# Régénère les sons et les musiques dans audio/generated/.
set -eu
cd "$(dirname "$0")/.."
PY=${BLENDER_PYTHON:-/Applications/Blender.app/Contents/Resources/5.3/python/bin/python3.13}
"$PY" -I tools/audio/generate_audio.py
