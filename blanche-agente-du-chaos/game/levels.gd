class_name Levels
extends RefCounted
## Les niveaux : un fichier de données par niveau dans res://levels/.

const COUNT := 8
const REQUIRED := [
	"id", "meal", "novelty", "intro", "duration", "hint_min", "window_mult", "look", "stations", "move_chance",
	"feint_chance", "surprise_chance", "round_chance", "noise", "noisy_spots", "helpers", "spots", "foods", "weights",
	"spawn", "max_items", "treasure_at", "treasure_points", "stars",
]


static func path_of(id: int) -> String:
	return "res://levels/niveau_%d.json" % id


static func load_level(id: int) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_of(id)))
	assert(parsed is Dictionary, "niveau illisible : " + path_of(id))
	return parsed


## Les problèmes d'un niveau (vide s'il est correct).
static func validate(level: Dictionary, map: KitchenMap) -> PackedStringArray:
	var out := PackedStringArray()
	for key: String in REQUIRED:
		if not level.has(key):
			out.append("clé manquante : " + key)
	if not out.is_empty():
		return out
	for s: String in level.stations:
		if not map.stations.has(s):
			out.append("poste inconnu : " + s)
	for s: String in level.spots:
		if not map.spots.has(s):
			out.append("endroit inconnu : " + s)
	for s: String in level.noisy_spots:
		if not level.spots.has(s):
			out.append("endroit bruyant absent du niveau : " + s)
	for k: String in Sim.SIZE_KEYS:
		if not level.foods.has(k):
			out.append("nourriture manquante : " + k)
	if level.stars.size() != 3 or not (level.stars[0] < level.stars[1] and level.stars[1] < level.stars[2]):
		out.append("étoiles : trois seuils croissants")
	if level.weights.size() != 3:
		out.append("poids : miette, petit, gros")
	if level.hint_min < Sim.DESCEND_TIME + 0.15:
		out.append("indice trop court pour redescendre")
	return out
