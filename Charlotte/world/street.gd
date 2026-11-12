class_name Street
extends Node2D
## Sidewalk, curb, gutter (full of fallen leaves in autumn, snowbanks in winter) and asphalt (patches, cracks,
## manholes, catch basins), drawn once.
## The thousands of leaves and grit specks go into vertex-coloured meshes: drawn one by one they cost
## thousands of draw calls every frame (the whole street is a single canvas item, never culled).

const TOP := 590.0
const CURB := 662.0
const ROAD := 670.0
const BOTTOM := 720.0
const LEAVES_COUNT := 6

var width := 2000.0

# The canvas only references the batched meshes, so they must be kept alive here.
var _meshes: Array[ArrayMesh] = []


func _draw() -> void:
	_meshes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	draw_rect(Rect2(0, TOP, width, CURB - TOP), Color("#D3CEC5"))
	var x := 0.0
	var i := 0
	while x < width:
		var tone := Color("#D7D2C9") if i % 2 == 0 else Color("#CFCAC0")
		draw_colored_polygon(PackedVector2Array([Vector2(x, TOP), Vector2(x + 96, TOP), Vector2(x + 82, CURB), Vector2(x - 14, CURB)]), tone)
		draw_line(Vector2(x, TOP), Vector2(x - 14, CURB), Color("#B9B3A9"), 2.0)
		x += 96.0
		i += 1
	draw_line(Vector2(0, 627), Vector2(width, 627), Color("#BDB7AD", 0.6), 1.5)
	var ao := PackedColorArray([Color(0.2, 0.12, 0.08, 0.28), Color(0.2, 0.12, 0.08, 0.28), Color(0.2, 0.12, 0.08, 0.0), Color(0.2, 0.12, 0.08, 0.0)])
	draw_polygon(PackedVector2Array([Vector2(0, TOP), Vector2(width, TOP), Vector2(width, TOP + 18), Vector2(0, TOP + 18)]), ao)
	draw_rect(Rect2(0, CURB, width, ROAD - CURB), Color("#BDB6AB"))
	draw_line(Vector2(0, CURB), Vector2(width, CURB), Color("#E2DDD4"), 2.0)
	var asphalt := PackedColorArray([Color("#555452"), Color("#555452"), Color("#64635F"), Color("#64635F")])
	draw_polygon(PackedVector2Array([Vector2(0, ROAD), Vector2(width, ROAD), Vector2(width, BOTTOM), Vector2(0, BOTTOM)]), asphalt)
	draw_rect(Rect2(0, ROAD, width, 6), Color("#4A4947"))
	_road_details(rng)
	var grit := _Batch.new()
	for n in int(width / 3.0):
		grit.rect(Rect2(rng.randf_range(0, width), rng.randf_range(ROAD + 6, BOTTOM), 2, 2), Color("#6E6D6A") if rng.randf() < 0.5 else Color("#4F4E4C"))
	_keep(grit.draw(self))
	for gx in range(400, int(width), 900):
		_catch_basin(float(gx))
	if Season.is_winter():
		_snow_on_sidewalk(rng)
	var leaves := _Batch.new()
	_leaves(leaves, rng, width / 9.0, TOP + 4, CURB - 2)
	_leaves(leaves, rng, width / 4.0, ROAD - 2, ROAD + 12)
	# Drifts the wind piled against the curb.
	for n in int(width / 420.0):
		var x0 := rng.randf_range(0, width)
		for k in 26:
			var p := Vector2(x0 + rng.randf_range(-30, 30), ROAD + 4 + absf(rng.randfn(0.0, 3.0)))
			var xf := Transform2D(rng.randf_range(0, PI), Vector2(1.0, 0.5), 0.0, p)
			var c := _litter_color(rng.randi_range(0, LEAVES_COUNT - 1))
			var r := rng.randf_range(3.5, 6.0)
			if _shown(n * 26 + k):
				leaves.circle(xf, r, c)
	_keep(leaves.draw(self))
	if Season.is_winter():
		_snowbank(rng)


func _keep(mesh: ArrayMesh) -> void:
	if mesh:
		_meshes.append(mesh)


# What lies on the ground this season. The random draws stay the same in every season (so the rest of the
# street doesn't move); only the colour and how many are shown change.
func _litter_color(i: int) -> Color:
	var litter := Season.litter()
	return litter[i % litter.size()]


func _shown(i: int) -> bool:
	return float((i * 7919) % 1000) / 1000.0 < Season.litter_amount()


# Winter: packed snow over the sidewalk, heaped against the buildings.
func _snow_on_sidewalk(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(0, TOP, width, CURB - TOP), Color(0.96, 0.97, 1.0, 0.55))
	var pts := PackedVector2Array([Vector2(0, TOP)])
	var x := 0.0
	while x < width:
		pts.append(Vector2(x, TOP + 6.0 + rng.randf_range(0.0, 10.0)))
		x += rng.randf_range(30.0, 70.0)
	pts.append(Vector2(width, TOP))
	draw_colored_polygon(pts, Color("#F7F9FB"))
	# Shovelled path down the middle: a little darker, with boot prints.
	draw_rect(Rect2(0, TOP + 24, width, 22), Color(0.75, 0.78, 0.82, 0.35))


# Winter: the plough's snowbank along the curb, and slush on the road.
func _snowbank(rng: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array([Vector2(0, ROAD + 8)])
	var x := 0.0
	while x < width:
		pts.append(Vector2(x, CURB - 10.0 - rng.randf_range(0.0, 12.0)))
		x += rng.randf_range(24.0, 60.0)
	pts.append(Vector2(width, ROAD + 8))
	draw_colored_polygon(pts, Color("#EEF2F6"))
	var shade := PackedVector2Array([Vector2(0, ROAD + 8), Vector2(width, ROAD + 8), Vector2(width, ROAD + 2), Vector2(0, ROAD + 2)])
	draw_colored_polygon(shade, Color("#C9D3DC"))
	for i in int(width / 160.0):
		draw_set_transform(Vector2(rng.randf_range(0, width), rng.randf_range(ROAD + 14, BOTTOM - 6)), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, rng.randf_range(20.0, 60.0), Color(0.85, 0.88, 0.9, 0.35))
	draw_set_transform(Vector2.ZERO)


func _leaves(batch: _Batch, rng: RandomNumberGenerator, count: float, y0: float, y1: float) -> void:
	for n in int(count):
		var p := Vector2(rng.randf_range(0, width), rng.randf_range(y0, y1))
		var xf := Transform2D(rng.randf_range(0, PI), Vector2(1.0, 0.5), 0.0, p)
		var c := _litter_color(rng.randi_range(0, LEAVES_COUNT - 1))
		var r := rng.randf_range(3.0, 5.5)
		if _shown(n + int(y0)):
			batch.circle(xf, r, c)
			batch.line(xf, Vector2(-4, 0), Vector2(4, 0), 0.8, c.darkened(0.3))


func _road_details(rng: RandomNumberGenerator) -> void:
	# Repair patches and cracks.
	var x := rng.randf_range(100, 400)
	while x < width:
		var w := rng.randf_range(90, 220)
		var y := rng.randf_range(ROAD + 10, BOTTOM - 14)
		draw_rect(Rect2(x, y, w, rng.randf_range(14, 30)), Color("#4C4B49", 0.7))
		var crack := PackedVector2Array()
		var c := Vector2(x + w + rng.randf_range(60, 200), rng.randf_range(ROAD + 8, BOTTOM - 4))
		for k in 6:
			crack.append(c)
			c += Vector2(rng.randf_range(10, 22), rng.randf_range(-4, 4))
		draw_polyline(crack, Color("#3E3D3B"), 1.2, true)
		x += rng.randf_range(450, 800)
	# Worn painted line along the parking lane.
	var lx := 0.0
	while lx < width:
		var seg := rng.randf_range(40, 160)
		draw_line(Vector2(lx, 703), Vector2(lx + seg, 703), Color("#E8E4D8", rng.randf_range(0.25, 0.55)), 3.0)
		lx += seg + rng.randf_range(0, 14)
	# Manhole covers in the road, Montréal's cast iron "ÉGOUT" lids. No puddles any more (Julien): their random draws are still
	# made, so the rest of the street doesn't move.
	var mx := rng.randf_range(300, 700)
	while mx < width:
		_manhole(Vector2(mx, 692))
		mx += rng.randf_range(900, 1500)
	var px := rng.randf_range(500, 900)
	while px < width:
		rng.randf_range(ROAD + 14, BOTTOM - 10)
		rng.randf_range(26, 46)
		px += rng.randf_range(700, 1300)


## A Montréal sewer manhole cover, seen at a low angle: the iron frame set in a ring of patched asphalt, the round lid with its
## raised grid of squares inside two rings, "ÉGOUT" pressed into a band across it, the two pick holes, the shine of wear.
func _manhole(at: Vector2) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 31, Color("#4A4947"))
	draw_circle(Vector2.ZERO, 26, Color("#2E2D2B"))
	draw_circle(Vector2.ZERO, 23, Color("#4E4C48"))
	for gx in range(-18, 19, 6):
		for gy in range(-18, 19, 6):
			if Vector2(gx, gy).length() < 17.0 and absf(gy) > 4.0:
				draw_rect(Rect2(gx - 2, gy - 2, 4, 4), Color("#5E5B56"))
	draw_arc(Vector2.ZERO, 19.5, 0, TAU, 32, Color("#3A3936"), 1.6)
	draw_arc(Vector2.ZERO, 23, 0, TAU, 32, Color("#5E5B56"), 1.4)
	draw_rect(Rect2(-17, -3.5, 34, 7), Color("#45433F"))
	for k in 5:
		draw_rect(Rect2(-13 + k * 6.2, -2, 3.6, 4), Color("#6E6B65"))
	draw_circle(Vector2(-11, -12), 1.8, Color("#1E1D1C"))
	draw_circle(Vector2(11, 12), 1.8, Color("#1E1D1C"))
	draw_arc(Vector2.ZERO, 21, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.18), 3.0)
	draw_set_transform(Vector2.ZERO)


## A Montréal catch basin at the curb: the opening in the curb's face under its iron lip, and in the gutter the cast iron grate
## with its slots across the flow, its frame, rust at the edges and the leaves caught in it.
func _catch_basin(x: float) -> void:
	var w := 58.0
	# The inlet in the curb: a dark slot under an iron lip.
	draw_rect(Rect2(x - 4, CURB + 1, w + 8, ROAD - CURB - 1), Color("#8E8A82"))
	draw_rect(Rect2(x, CURB + 2.5, w, ROAD - CURB - 3.5), Color("#1E1D1C"))
	draw_line(Vector2(x - 4, CURB + 1.5), Vector2(x + w + 4, CURB + 1.5), Color("#5E5B56"), 2.0)
	# The grate in the gutter, a little in perspective: its frame, the bars, rust and the shine of the iron.
	var top := ROAD + 1.0
	var bottom := ROAD + 13.0
	draw_colored_polygon(PackedVector2Array([Vector2(x - 3, top), Vector2(x + w + 3, top), Vector2(x + w + 6, bottom + 2), Vector2(x - 6, bottom + 2)]), Color("#3E3C39"))
	draw_colored_polygon(PackedVector2Array([Vector2(x, top + 1.5), Vector2(x + w, top + 1.5), Vector2(x + w + 2.5, bottom), Vector2(x - 2.5, bottom)]), Color("#141312"))
	for k in 9:
		var t := (k + 0.5) / 9.0
		var a := Vector2(lerpf(x, x + w, t), top + 1.5)
		var b := Vector2(lerpf(x - 2.5, x + w + 2.5, t), bottom)
		draw_line(a, b, Color("#5A5752"), 2.4)
		draw_line(a + Vector2(-0.8, 0), b + Vector2(-0.8, 0), Color(1, 1, 1, 0.12), 0.8)
	draw_line(Vector2(x - 2.5, (top + bottom) / 2.0 + 0.8), Vector2(x + w + 2.5, (top + bottom) / 2.0 + 0.8), Color("#4A4743"), 1.6)
	draw_line(Vector2(x - 6, bottom + 2), Vector2(x + w + 6, bottom + 2), Color("#6E4A32", 0.55), 1.6)
	if not Season.is_winter():
		var lc := _litter_color(int(x) % LEAVES_COUNT)
		draw_set_transform(Vector2(x + w * 0.3, top + 5), 0.4, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 4.0, lc)
		draw_set_transform(Vector2(x + w * 0.72, top + 8), -0.6, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 3.5, lc.darkened(0.15))
		draw_set_transform(Vector2.ZERO)
	else:
		draw_rect(Rect2(x - 4, CURB - 1, w + 8, 3), Color("#F4F6F8"))


# Triangles with per-vertex colours, drawn as one mesh.
class _Batch:
	var _verts := PackedVector2Array()
	var _cols := PackedColorArray()

	func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		_verts.append_array([a, b, c])
		_cols.append_array([col, col, col])

	func rect(r: Rect2, col: Color) -> void:
		_tri(r.position, Vector2(r.end.x, r.position.y), r.end, col)
		_tri(r.position, r.end, Vector2(r.position.x, r.end.y), col)

	## Circle of radius r in the space of `xf` (so a squashed, rotated xf gives a tilted ellipse).
	func circle(xf: Transform2D, r: float, col: Color, segments := 10) -> void:
		var centre := xf.origin
		var prev := xf * Vector2(r, 0)
		for i in range(1, segments + 1):
			var next := xf * (Vector2.from_angle(TAU * i / segments) * r)
			_tri(centre, prev, next, col)
			prev = next

	func line(xf: Transform2D, a: Vector2, b: Vector2, w: float, col: Color) -> void:
		var n := (b - a).normalized().orthogonal() * w * 0.5
		var p := [xf * (a + n), xf * (b + n), xf * (b - n), xf * (a - n)]
		_tri(p[0], p[1], p[2], col)
		_tri(p[0], p[2], p[3], col)

	func draw(ci: CanvasItem) -> ArrayMesh:
		if _verts.is_empty():
			return null
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _verts
		arrays[Mesh.ARRAY_COLOR] = _cols
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		ci.draw_mesh(mesh, null)
		return mesh
