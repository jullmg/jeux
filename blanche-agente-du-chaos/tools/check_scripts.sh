#!/bin/sh
# Compile tout le projet : affiche les erreurs de script et échoue s'il y en a.
cd "$(dirname "$0")/.."
G=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
log=$(mktemp)
status=0
perl -e 'alarm 120; exec @ARGV' "$G" --headless --path . --quit-after 600 -- --no-save --verif >"$log" 2>&1 || status=$?
if [ "$status" -ne 0 ]; then
	cat "$log"
	echo "ÉCHEC : Godot a rendu le code $status"
	exit 1
fi
if grep -E -A3 'SCRIPT ERROR|^ERROR|^WARNING' "$log"; then
	exit 1
fi
echo "scripts : OK"
