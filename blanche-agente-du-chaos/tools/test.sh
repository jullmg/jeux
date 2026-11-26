#!/bin/sh
# Tous les tests automatiques. Échoue au moindre problème.
#   tools/test.sh             rapide (quelques minutes)
#   tools/test.sh --complet   avec 1000 parties de robots par niveau et par profil
set -eu
cd "$(dirname "$0")/.."
G=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
games=150
[ "${1:-}" = "--complet" ] && games=1000
tmp=$(mktemp -d)
trap '/bin/rm -rf "$tmp"' EXIT

# Lance Godot sans fenêtre avec une limite de temps ; échoue si le journal contient une erreur ou une fuite.
godot() {
	limit=$1
	shift
	status=0
	perl -e 'alarm shift; exec @ARGV' "$limit" "$G" --headless --path . "$@" >"$tmp/log" 2>&1 || status=$?
	grep -v '^Godot Engine' "$tmp/log" | grep -v '^$' || true
	if [ "$status" -ne 0 ]; then
		echo "ÉCHEC (code $status)"
		exit 1
	fi
	if grep -E 'SCRIPT ERROR|Parse Error|were leaked|still in use' "$tmp/log" >/dev/null; then
		echo "ÉCHEC : erreurs ou fuites dans le journal"
		exit 1
	fi
}

echo "== importation et compilation"
perl -e 'alarm 300; exec @ARGV' "$G" --headless --path . --import >"$tmp/import" 2>&1 || true
if grep -E -A3 'SCRIPT ERROR|^ERROR' "$tmp/import"; then
	exit 1
fi
tools/check_scripts.sh
echo "== règles du jeu"
godot 400 -s res://tests/run_tests.gd -- --no-save
echo "== non-régression de la cuisine (missions 1 à 8)"
godot 300 -s res://tests/regression.gd -- --no-save
echo "== intégration (vraies entrées)"
godot 300 res://tests/integration.tscn -- --no-save
echo "== parcours complet"
godot 400 -- "--autotest=$tmp/auto.json"
echo "== équilibrage"
tools/check_balance.py --games "$games"
echo
echo "TOUS LES TESTS PASSENT"
