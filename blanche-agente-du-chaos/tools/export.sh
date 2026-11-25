#!/bin/sh
# Produit l'application macOS dans build/, signée « ad hoc », puis la vérifie.
#   tools/export.sh            exporte et teste (sans fenêtre) l'application exportée
set -eu
cd "$(dirname "$0")/.."
G=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
name="Blanche Pronovost agente du Chaos"
app="build/$name.app"
tmp=$(mktemp -d)
trap '/bin/rm -rf "$tmp"' EXIT

echo "== importation"
perl -e 'alarm 300; exec @ARGV' "$G" --headless --path . --import >"$tmp/import" 2>&1 || true
echo "== exportation"
mkdir -p build
/bin/rm -rf "$app" "build/Blanche-macOS.zip"
status=0
perl -e 'alarm 400; exec @ARGV' "$G" --headless --path . --export-release macOS "$app" >"$tmp/export" 2>&1 || status=$?
if [ "$status" -ne 0 ] || [ ! -d "$app" ] || grep -E '^ERROR' "$tmp/export"; then
	cat "$tmp/export"
	echo "ÉCHEC de l'exportation (code $status)"
	exit 1
fi
codesign --verify --deep --strict "$app"
binary="$app/Contents/MacOS/$(ls "$app/Contents/MacOS" | head -1)"
echo "   architectures : $(lipo -archs "$binary")"

echo "== aucune photo ni donnée personnelle dans l'application"
if find "$app" -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.zip' -o -iname '*.heic' | grep .; then
	echo "ÉCHEC : fichiers inattendus"
	exit 1
fi
pck="$app/Contents/Resources/$name.pck"
if [ -f "$pck" ] && strings "$pck" | grep -E 'reference/|\.jpg|Photos-1-001' | head -3 | grep .; then
	echo "ÉCHEC : trace des photos dans le paquet"
	exit 1
fi

echo "== essai de l'application exportée (sans fenêtre)"
save="user://essai_export.json"
real="$HOME/Library/Application Support/BlancheAgenteDuChaos/essai_export.json"
/bin/rm -f "$real"
for tour in 1 2; do
	status=0
	perl -e 'alarm 300; exec @ARGV' "$binary" --headless -- "--sauvegarde=$save" "--autotest=$tmp/auto$tour.json" \
		>"$tmp/run$tour" 2>&1 || status=$?
	grep AUTOTEST "$tmp/run$tour" || true
	if [ "$status" -ne 0 ] || grep -E 'SCRIPT ERROR|^ERROR|were leaked' "$tmp/run$tour"; then
		cat "$tmp/run$tour"
		echo "ÉCHEC de l'essai $tour (code $status)"
		exit 1
	fi
done
/usr/bin/python3 -I - "$tmp/auto1.json" "$tmp/auto2.json" <<'PY'
import json, sys
first, second = (json.load(open(p)) for p in sys.argv[1:])
assert first["start_unlocked"] == 1 and first["start_stars"] == 0, "la première ouverture n'était pas neuve"
assert second["start_unlocked"] == 8 and second["start_stars"] == first["end_stars"] > 0, \
    f"la sauvegarde n'a pas survécu au redémarrage : {second['start_unlocked']}, {second['start_stars']}"
print(f"   sauvegarde conservée après redémarrage : {second['start_stars']} étoiles, mission {second['start_unlocked']}")
PY
/bin/rm -f "$real"

(cd build && ditto -c -k --keepParent "$name.app" Blanche-macOS.zip)
echo "== prêt : $app ($(du -sh "$app" | cut -f1)), build/Blanche-macOS.zip ($(du -sh build/Blanche-macOS.zip | cut -f1))"
