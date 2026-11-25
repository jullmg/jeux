#!/bin/sh
# Captures d'écran du jeu, sans son, en arrière-plan, sur l'écran du MacBook.
#   tools/shots.sh dossier [résolution] [--seulement=menus,jeu,tutoriel,cachette,niveaux,situations,fin,poses,perf]
set -eu
cd "$(dirname "$0")/.."
out=$(mkdir -p "$1" && cd "$1" && pwd)
res=${2:-1600x900}
only=${3:-}
log="$out/journal.txt"
open -W -g -n -a /Applications/Godot.app --stdout "$log" --stderr "$log.err" --args --path "$PWD" \
	--screen "$(tools/ecran_macbook.sh)" --audio-driver Dummy --resolution "$res" \
	--quit-after 60000 -- --no-save "--scenario=$out" $only ${4:-}
grep -E 'CAPTURE|situation|PERF' "$log" || true
if grep -E -A3 'SCRIPT ERROR|^ERROR|^WARNING' "$log.err"; then
	exit 1
fi
