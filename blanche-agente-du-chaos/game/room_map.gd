class_name RoomMap
extends RefCounted
## Le plan d'une pièce vu de dessus (data/pieces/<pièce>.json) : meubles, collisions, cachettes et ligne de vue.
## Les positions sont des Vector2 (x, z) en mètres.

const FOLDER := "res://data/pieces/%s.json"
## Une cachette « bloc » (l'îlot, le divan) cache l'autre côté sur une part de la distance entre celui qui regarde et
## son bord : `k` de cette distance, entre `min` et `max`. Ce sont les valeurs de l'îlot de la cuisine.
const SHADOW_K := 0.55
const SHADOW_MIN := 0.32
const SHADOW_MAX := 1.05
## Qui travaille tout contre une cachette voit par-dessus de près : elle rapetisse.
const SHADOW_AT_ISLAND := 0.55
## Sous la table, Blanche doit y être vraiment : son centre au moins à cette distance du bord.
const UNDER_MARGIN := 0.04

var id: String
var data: Dictionary
var room: Rect2
var obstacles: Array[Rect2] = []
## Les obstacles par nom.
var named: Dictionary = {}
## Les cachettes : {id, kind ("bloc" ou "dessous"), rect, height, k, min, max}.
var hides: Array[Dictionary] = []
## Les petits meubles ronds qu'on bouscule (le tabouret, les chaises) : {name, pos, r}.
var stools: Array[Dictionary] = []
var corner: Vector2
var corner_face: Vector2
## "coussin" ou "cage".
var corner_kind := "coussin"
var spots: Dictionary = {}
var stations: Dictionary = {}
## Les places assises : nom → {pos, face, chair (indice dans `stools`, -1 sans chaise)}.
var seats: Dictionary = {}
var helper_door: Vector2
## Par où Maman sort de la pièce (vers le corridor et la cuisine).
var mom_door := Vector2.INF
## Le tour de vérification autour de la cachette principale (points au sol, dans l'ordre).
var ring := PackedVector2Array()
var surfaces: Dictionary = {}


func _init(piece := "cuisine") -> void:
	id = piece
	var path := FOLDER % piece
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "plan illisible : " + path)
	data = parsed
	var r: Dictionary = data.room
	room = Rect2(r.x0, r.z0, r.x1 - r.x0, r.z1 - r.z0)
	for key: String in data.obstacles:
		var rect := _rect(data.obstacles[key])
		obstacles.append(rect)
		named[key] = rect
	for h: Dictionary in data.get("hides", []):
		var rect: Rect2 = named[h.obstacle] if h.has("obstacle") else _rect(h.rect)
		hides.append({"id": h.id, "kind": h.kind, "rect": rect, "height": float(h.get("height", 0.93)),
			"k": float(h.get("k", SHADOW_K)), "min": float(h.get("min", SHADOW_MIN)), "max": float(h.get("max", SHADOW_MAX))})
	if data.has("stool"):
		stools.append({"name": "tabouret", "pos": Vector2(data.stool.x, data.stool.z), "r": float(data.stool.r)})
	for name_: String in data.get("chairs", {}):
		var c: Dictionary = data.chairs[name_]
		stools.append({"name": name_, "pos": vec(c.pos), "r": float(c.r)})
	corner = Vector2(data.corner.x, data.corner.z)
	corner_face = vec(data.corner.face).normalized()
	corner_kind = data.corner.get("kind", "coussin")
	for key: String in data.spots:
		var s: Dictionary = data.spots[key]
		spots[key] = {
			"stand": vec(s.stand), "food": vec(s.food), "far": float(s.far), "surface": s.surface,
		}
	for key: String in data.stations:
		var s: Dictionary = data.stations[key]
		stations[key] = {"pos": vec(s.pos), "face": vec(s.face).normalized(), "activity": s.activity,
			"front": s.get("regard", "dos") == "devant", "seated": s.get("assis", false) == true,
			"outside": s.get("dehors", false) == true, "close": s.get("pres", ""),
			"hips": vec(s.get("hanches", s.pos)), "seat_y": float(s.get("siege", 0.48))}
	for key: String in data.get("seats", {}):
		var s: Dictionary = data.seats[key]
		var chair := -1
		for i in stools.size():
			if stools[i].name == s.get("chaise", ""):
				chair = i
		# `hips` : où l'on est assis, pour l'affichage (au divan, les pieds sont devant, les hanches dans le coussin).
		seats[key] = {"pos": vec(s.pos), "face": vec(s.face).normalized(), "chair": chair,
			"hips": vec(s.get("hanches", s.pos)), "seat_y": float(s.get("siege", 0.48))}
	helper_door = vec(data.helper_door)
	if data.has("mom_door"):
		mom_door = vec(data.mom_door)
	for p: Array in data.get("ring", []):
		ring.append(vec(p))
	surfaces = data.get("surfaces", {})


static func vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


static func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2] - a[0], a[3] - a[1])


## La hauteur d'un meuble où est posée la nourriture.
func surface_height(spot: String) -> float:
	return float(surfaces.get(spots[spot].surface, 0.92))


## Le cercle d'un petit meuble, pour les collisions.
func stool_circles() -> Array:
	var out: Array = []
	for s in stools:
		out.append([s.pos, s.r])
	return out


## Repousse un cercle hors des meubles, des murs et des cercles donnés ([centre, rayon]).
func resolve(pos: Vector2, radius: float, circles: Array = []) -> Vector2:
	for _i in 3:
		for c: Array in circles:
			var d: Vector2 = pos - c[0]
			var min_d: float = radius + c[1]
			if d.length() < min_d:
				pos = c[0] + (d.normalized() if d.length() > 0.0001 else Vector2.DOWN) * min_d
		for rect in obstacles:
			pos = _push_out(pos, radius, rect)
		pos.x = clampf(pos.x, room.position.x + radius, room.end.x - radius)
		pos.y = clampf(pos.y, room.position.y + radius, room.end.y - radius)
	return pos


static func _push_out(pos: Vector2, radius: float, rect: Rect2) -> Vector2:
	var near := Vector2(clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y))
	var d := pos - near
	var len := d.length()
	if len >= radius:
		return pos
	if len > 0.0001:
		return near + d / len * radius
	# Centre à l'intérieur : sortir par le bord le plus proche.
	var left := pos.x - rect.position.x
	var right := rect.end.x - pos.x
	var top := pos.y - rect.position.y
	var bottom := rect.end.y - pos.y
	var m := minf(minf(left, right), minf(top, bottom))
	if m == left:
		return Vector2(rect.position.x - radius, pos.y)
	if m == right:
		return Vector2(rect.end.x + radius, pos.y)
	if m == top:
		return Vector2(pos.x, rect.position.y - radius)
	return Vector2(pos.x, rect.end.y + radius)


## Vrai si un cercle ne touche aucun meuble et tient dans la pièce.
func is_free(pos: Vector2, radius: float) -> bool:
	if pos.x < room.position.x + radius or pos.x > room.end.x - radius:
		return false
	if pos.y < room.position.y + radius or pos.y > room.end.y - radius:
		return false
	for rect in obstacles:
		var near := Vector2(clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y))
		if pos.distance_squared_to(near) < radius * radius - 0.00001:
			return false
	for s in stools:
		if pos.distance_to(s.pos) < radius + s.r - 0.0001:
			return false
	return true


## Paramètres [entrée, sortie] (0 à 1) du segment a→b dans le rectangle, ou un tableau vide.
static func segment_rect(a: Vector2, b: Vector2, rect: Rect2) -> PackedFloat32Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for axis in 2:
		var lo := rect.position[axis]
		var hi := rect.end[axis]
		if absf(d[axis]) < 0.000001:
			if a[axis] < lo or a[axis] > hi:
				return PackedFloat32Array()
		else:
			var ta := (lo - a[axis]) / d[axis]
			var tb := (hi - a[axis]) / d[axis]
			t0 = maxf(t0, minf(ta, tb))
			t1 = minf(t1, maxf(ta, tb))
			if t0 > t1:
				return PackedFloat32Array()
	return PackedFloat32Array([t0, t1])


## Une chienne au sol en `target` est-elle cachée aux yeux de `viewer` ? `close` : la cachette contre laquelle
## travaille celui qui regarde (il voit par-dessus de près) ; `low` : il est assis ou penché, et voit sous la table
## de son côté.
func hidden(viewer: Vector2, target: Vector2, close := "", low := false) -> bool:
	for h in hides:
		if h.kind == "dessous":
			if _under(h, viewer, target, low):
				return true
		elif _behind(h, viewer, target, close == h.id):
			return true
	return false


## Derrière un bloc : l'ombre que fait le meuble, plus longue quand on le regarde de loin.
static func _behind(h: Dictionary, viewer: Vector2, target: Vector2, close: bool) -> bool:
	var rect: Rect2 = h.rect.grow(-0.02)
	if rect.has_point(target):
		return false
	var hit := segment_rect(viewer, target, rect)
	if hit.is_empty() or hit[1] >= 1.0:
		return false
	var exit := viewer.lerp(target, hit[1])
	var depth := clampf(viewer.distance_to(exit) * float(h.k), float(h.min), float(h.max))
	if close:
		depth *= SHADOW_AT_ISLAND
	return exit.distance_to(target) <= depth


## Sous la table : personne debout ne la voit ; assis ou penché, on voit seulement la moitié de son côté.
static func _under(h: Dictionary, viewer: Vector2, target: Vector2, low: bool) -> bool:
	var rect: Rect2 = h.rect.grow(-UNDER_MARGIN)
	if not rect.has_point(target):
		return false
	if not low:
		return true
	var c := rect.get_center()
	var outside := (viewer - c).abs() - rect.size / 2.0
	var axis := 0 if outside.x > outside.y else 1
	return signf(target[axis] - c[axis]) != signf(viewer[axis] - c[axis])


## Le rectangle qui contient toutes les cachettes, agrandi de `margin` et gardé dans la pièce.
func hides_area(margin: float) -> Rect2:
	var out := Rect2()
	for i in hides.size():
		var r: Rect2 = hides[i].rect.grow(margin)
		out = r if i == 0 else out.merge(r)
	return out.intersection(room)
