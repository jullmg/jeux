class_name Levels
extends RefCounted
## Les niveaux : un fichier de données par niveau dans res://levels/. Chaque niveau dit sa pièce (`"piece"`, la cuisine
## par défaut) et qui surveille (`"watcher"`, Maman par défaut).

const COUNT := 15
const REQUIRED := [
	"id", "meal", "novelty", "intro", "duration", "hint_min", "window_mult", "look", "stations", "move_chance",
	"feint_chance", "surprise_chance", "round_chance", "noise", "noisy_spots", "helpers", "spots", "foods", "weights",
	"spawn", "max_items", "treasure_at", "treasure_points", "stars",
]
const WATCHERS := ["maman", "papa"]
const PEOPLE := ["maman", "papa", "charlotte", "tante", "oncle"]
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
		if not PEOPLE.has(p.get("who", "")):
			out.append("personne inconnue : " + str(p.get("who")))
	# Une place n'est prise qu'une fois, en comptant celle où Maman s'assoit à table.
	var taken := {}
	for id: String in level.stations:
		if map.stations.has(id) and map.stations[id].seated:
			for seat: String in map.seats:
				if (map.seats[seat].pos as Vector2).distance_to(map.stations[id].pos) < 0.05:
					taken[seat] = "maman"
	for p: Dictionary in level.get("seated", []):
		if taken.has(p.get("seat", "")):
			out.append("place prise deux fois : " + str(p.get("seat")))
		taken[p.get("seat", "")] = p.get("who", "")
	if level.has("plat") and not (PersonView.DISHES.has(level.plat) or level.plat == "cafe"):
		out.append("plat inconnu : " + str(level.plat))
	for w: Dictionary in level.get("walkers", []):
		if not PEOPLE.has(w.get("who", "")):
			out.append("personne inconnue : " + str(w.get("who")))
		var points: Array = w.get("points", [])
		var distinct := {}
		for name_: String in points:
			distinct[name_] = true
		if distinct.size() < 2 or not points.has(w.get("start", "")):
			out.append("la visite qui circule a besoin de deux endroits et d'un départ parmi eux")
		for name_: String in points:
			if not map.data.get("waypoints", {}).has(name_):
				out.append("point de passage inconnu : " + name_)
	if level.has("surprise") and not Sim.ACTIVITY_WINDOWS.has(str(level.surprise.get("activity", ""))):
		out.append("surprise inconnue : " + str(level.surprise))
	if level.has("dark") and not (level.dark.has("near") and level.dark.has("far") and level.dark.near < level.dark.far):
		out.append("le noir demande near < far")
	for key: String in ["slip_wait", "spawn", "look"]:
		if level.has(key) and (level[key].size() != 2 or level[key][0] > level[key][1]):
			out.append("intervalle mal formé : " + key)
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
