#!/bin/bash
# Copies the games in progress (user://) into the repo, so they are kept in git as a backup.
# Run it after playing:  Charlotte/tools/sauvegarder.sh
set -e
src="$HOME/Library/Application Support/Godot/app_userdata/Charlotte"
dst="$(cd "$(dirname "$0")/.." && pwd)/sauvegardes"
[ -d "$src" ] || { echo "Aucune partie à sauvegarder ($src)"; exit 0; }
mkdir -p "$dst"
rsync -a --delete --exclude logs --exclude '.*' "$src/" "$dst/"
echo "Parties copiées dans $dst — fais un commit pour les garder."
