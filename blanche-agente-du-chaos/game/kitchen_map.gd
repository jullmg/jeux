class_name KitchenMap
extends RefCounted
## Le plan de la cuisine vu de dessus (data/kitchen.json) : meubles, collisions et ligne de vue.
## Les positions sont des Vector2 (x, z) en mètres.

const DATA_PATH := "res://data/kitchen.json"
## Part de la distance Maman → bord de l'îlot qui reste cachée de l'autre côté.
const SHADOW_K := 0.55
const SHADOW_MIN := 0.32
const SHADOW_MAX := 1.05
## Maman qui travaille à l'îlot voit par-dessus de près : la cachette rapetisse.
const SHADOW_AT_ISLAND := 0.55

var data: Dictionary
var room: Rect2
var island: Rect2
var obstacles: Array[Rect2] = []
var stool_pos: Vector2
var stool_r: float
var corner: Vector2
var corner_face: Vector2
var spots: Dictionary = {}
var stations: Dictionary = {}
var helper_door: Vector2


func _init(path := DATA_PATH) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "plan de cuisine illisible : " + path)
	data = parsed
	var r: Dictionary = data.room
	room = Rect2(r.x0, r.z0, r.x1 - r.x0, r.z1 - r.z0)
	for key: String in data.obstacles:
		var rect := _rect(data.obstacles[key])
		obstacles.append(rect)
		if key == "island":
			island = rect
	stool_pos = Vector2(data.stool.x, data.stool.z)
	stool_r = data.stool.r
	corner = Vector2(data.corner.x, data.corner.z)
	corner_face = vec(data.corner.face).normalized()
	for key: String in data.spots:
		var s: Dictionary = data.spots[key]
		spots[key] = {
			"stand": vec(s.stand), "food": vec(s.food), "far": float(s.far), "surface": s.surface,
		}
	for key: String in data.stations:
		var s: Dictionary = data.stations[key]
		stations[key] = {"pos": vec(s.pos), "face": vec(s.face).normalized(), "activity": s.activity}
	helper_door = vec(data.helper_door)


static func vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


static func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2] - a[0], a[3] - a[1])


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
	return pos.distance_to(stool_pos) >= radius + stool_r - 0.0001


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


## L'îlot cache-t-il, aux yeux de `viewer`, une chienne debout au sol en `target` ?
func hidden_by_island(viewer: Vector2, target: Vector2, viewer_at_island := false) -> bool:
	var rect := island.grow(-0.02)
	if rect.has_point(target):
		return false
	var hit := segment_rect(viewer, target, rect)
	if hit.is_empty() or hit[1] >= 1.0:
		return false
	var exit := viewer.lerp(target, hit[1])
	var depth := clampf(viewer.distance_to(exit) * SHADOW_K, SHADOW_MIN, SHADOW_MAX)
	if viewer_at_island:
		depth *= SHADOW_AT_ISLAND
	return exit.distance_to(target) <= depth
