#!/bin/bash
# Puts the games kept in the repo back where Godot reads them (user://). Overwrites what is there.
# Run it on a new machine, or after losing a save:  Charlotte/tools/restaurer.sh
set -e
dst="$HOME/Library/Application Support/Godot/app_userdata/Charlotte"
src="$(cd "$(dirname "$0")/.." && pwd)/sauvegardes"
[ -d "$src" ] || { echo "Rien à restaurer ($src)"; exit 1; }
mkdir -p "$dst"
rsync -a "$src/" "$dst/"
echo "Parties restaurées dans $dst."
