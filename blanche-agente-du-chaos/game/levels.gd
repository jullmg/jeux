class_name Levels
extends RefCounted
## Les niveaux : un fichier de données par niveau dans res://levels/. Chaque niveau dit sa pièce (`"piece"`, la cuisine
## par défaut) et qui surveille (`"watcher"`, Maman par défaut).

const COUNT := 8
const REQUIRED := [
	"id", "meal", "novelty", "intro", "duration", "hint_min", "window_mult", "look", "stations", "move_chance",
	"feint_chance", "surprise_chance", "round_chance", "noise", "noisy_spots", "helpers", "spots", "foods", "weights",
	"spawn", "max_items", "treasure_at", "treasure_points", "stars",
]
const WATCHERS := ["maman", "papa"]
const ROLES := ["complice", "temoin", "decor"]


static func path_of(id: int) -> String:
	return "res://levels/niveau_%d.json" % id


static func load_level(id: int) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_of(id)))
	assert(parsed is Dictionary, "niveau illisible : " + path_of(id))
	return parsed


## La pièce où se joue un niveau.
static func piece_of(level: Dictionary) -> String:
	return str(level.get("piece", "cuisine"))


## Les problèmes d'un niveau (vide s'il est correct). `map` est le plan de sa pièce.
static func validate(level: Dictionary, map: RoomMap) -> PackedStringArray:
	var out := PackedStringArray()
	for key: String in REQUIRED:
		if not level.has(key):
			out.append("clé manquante : " + key)
	if not out.is_empty():
		return out
	if map.id != piece_of(level):
		out.append("plan de la mauvaise pièce : " + map.id)
	if not WATCHERS.has(level.get("watcher", "maman")):
		out.append("personne qui surveille inconnue : " + str(level.watcher))
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
	for p: Dictionary in level.get("seated", []):
		if not map.seats.has(p.get("seat", "")):
			out.append("place inconnue : " + str(p.get("seat")))
		if not ROLES.has(p.get("role", "")):
			out.append("rôle inconnu : " + str(p.get("role")))
	for w: Dictionary in level.get("walkers", []):
		for name_: String in w.points + [w.start]:
			if not map.data.get("waypoints", {}).has(name_):
				out.append("point de passage inconnu : " + name_)
	var outside: Array = level.stations.filter(func(s: String) -> bool: return map.stations.has(s) and map.stations[s].outside)
	if not outside.is_empty() and map.mom_door == Vector2.INF:
		out.append("sortie sans porte dans le plan")
	if outside.size() == level.stations.size():
		out.append("aucun poste dans la pièce")
	if outside.has(level.stations[0]):
		out.append("le premier poste doit être dans la pièce")
	if float(level.round_chance) > 0.0 and map.ring.is_empty():
		out.append("tour demandé sans tour dans le plan")
	if level.stars.size() != 3 or not (level.stars[0] < level.stars[1] and level.stars[1] < level.stars[2]):
		out.append("étoiles : trois seuils croissants")
	if level.weights.size() != 3:
		out.append("poids : miette, petit, gros")
	if level.hint_min < Sim.DESCEND_TIME + 0.15:
		out.append("indice trop court pour redescendre")
	return out
