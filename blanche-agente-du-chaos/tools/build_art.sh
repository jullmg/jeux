#!/bin/sh
# Régénère tous les modèles 3D (art/models/) et leurs aperçus (art/previews/).
# tools/build_art.sh [cuisine|blanche|famille|nourriture]
set -eu
cd "$(dirname "$0")/.."
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
wanted=${1:-tout}
build() {
	[ "$wanted" = tout ] || [ "$wanted" = "$1" ] || return 0
	echo "== $1"
	log=$(mktemp)
	if ! "$BLENDER" --background --factory-startup --python-exit-code 1 --python "tools/blender/$2.py" >"$log" 2>&1; then
		tail -30 "$log"
		exit 1
	fi
	grep -E '^(EXPORT|APERCU)' "$log" || true
}
build cuisine kitchen
build blanche dog
build famille people
build nourriture food
