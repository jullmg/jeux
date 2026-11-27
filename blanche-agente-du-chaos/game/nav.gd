class_name Nav
extends RefCounted
## Trouve un chemin sur le plancher en contournant les meubles (grille A*).

const CELL := 0.08

var map: RoomMap
var radius: float
var grid := AStarGrid2D.new()
## Les tables (cachettes « dessous ») bloquent aussi : la chienne passe dessous, pas les gens debout.
var around_tables := false


func _init(map_: RoomMap, radius_: float, around_tables_ := false) -> void:
	map = map_
	radius = radius_
	around_tables = around_tables_
	var size := Vector2i(int(ceil(map.room.size.x / CELL)), int(ceil(map.room.size.y / CELL)))
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.cell_size = Vector2(CELL, CELL)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if not map.is_free(center(c), radius) or (around_tables and map.under_table(center(c), radius)):
				grid.set_point_solid(c, true)


func center(c: Vector2i) -> Vector2:
	return map.room.position + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func cell(p: Vector2) -> Vector2i:
	var c := Vector2i(((p - map.room.position) / CELL).floor())
	return c.clamp(Vector2i.ZERO, grid.region.size - Vector2i.ONE)


## La case libre la plus proche d'un point.
func nearest_open(p: Vector2) -> Vector2i:
	var c := cell(p)
	if not grid.is_point_solid(c):
		return c
	var best := c
	var best_d := INF
	for ring in range(1, 14):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var n := c + Vector2i(dx, dy)
				if grid.region.has_point(n) and not grid.is_point_solid(n):
					var d := center(n).distance_squared_to(p)
					if d < best_d:
						best_d = d
						best = n
		if best_d < INF:
			break
	return best


## Points à suivre de `from` à `to`. `blockers` : cercles [centre, rayon] à éviter en plus.
func path(from: Vector2, to: Vector2, blockers: Array = []) -> PackedVector2Array:
	var added: Array[Vector2i] = []
	var start := nearest_open(from)
	for b: Array in blockers:
		var r: float = b[1] + radius * 0.8
		var lo := cell(b[0] - Vector2(r, r))
		var hi := cell(b[0] + Vector2(r, r))
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				var c := Vector2i(x, y)
				if c != start and not grid.is_point_solid(c) and center(c).distance_to(b[0]) < r:
					grid.set_point_solid(c, true)
					added.append(c)
	var goal := nearest_open(to)
	var ids := grid.get_id_path(start, goal)
	for c in added:
		grid.set_point_solid(c, false)
	var out := PackedVector2Array()
	if ids.is_empty():
		return out
	for i in range(1, ids.size()):
		out.append(center(ids[i]))
	if map.is_free(to, radius * 0.95):
		if out.is_empty():
			out.append(to)
		else:
			out[out.size() - 1] = to
	return _smooth(from, out, blockers)


## Retire les points intermédiaires qu'on peut sauter en ligne droite.
func _smooth(from: Vector2, pts: PackedVector2Array, blockers: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var here := from
	var i := 0
	while i < pts.size():
		var j := mini(pts.size() - 1, i + 12)
		while j > i and not _clear(here, pts[j], blockers):
			j -= 1
		out.append(pts[j])
		here = pts[j]
		i = j + 1
	return out


func _clear(a: Vector2, b: Vector2, blockers: Array) -> bool:
	var steps := int(ceil(a.distance_to(b) / CELL))
	for s in range(1, steps + 1):
		var p := a.lerp(b, float(s) / steps)
		if grid.is_point_solid(cell(p)):
			return false
		for blk: Array in blockers:
			if p.distance_to(blk[0]) < blk[1] + radius * 0.8:
				return false
	return true

