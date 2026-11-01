class_name CrossStreet
extends Node2D
## A cross street at a corner of 6e Avenue, seen down its length in one-point perspective.
## Three parts, each a separate node so they land in the right place in the draw order:
##  - VISTA (added before the houses): the street receding behind the facade line, its sidewalks,
##    the walls of the buildings along it, street trees, the street running to the horizon with
##    Mount Royal far away in the haze.
##  - GROUND (added after Street): the asphalt cutting through the 6e sidewalk, curb ramps, crosswalk.
##  - SIGNS (added with the props): the street-name posts and the stop or school sign at the corner (the utility
##    poles and wires are StreetScene's, see UtilityPoles).
## Every point is drawn as its projection at the facade line (y FACADE_Y) shrunk toward the vanishing
## point by 1 / (1 + depth).

enum Part { VISTA, GROUND, SIGNS }

const FACADE_Y := 592.0
const HORIZON_Y := 452.0
const SIDEWALK_TOP := 590.0
const ROAD_BOTTOM := 676.0
const FAR := 24.0
## Beyond this depth, details (windows) are too small to draw.
const DETAIL := 8.0
const HAZE := Color("#B9C6D6")
const ASPHALT := Color("#5A5956")
const CONCRETE := Color("#CFCAC0")
const CURB := Color("#E2DDD4")

var part := Part.VISTA
## Gap between the corner buildings, in world x at the facade line.
var x0 := 0.0
var x1 := 560.0
## Sidewalk width on each side of the cross street, at the facade line.
var sidewalk := 96.0
## School zone: yellow crosswalk and a school sign.
var school := false
## Walls along each side, nearest first: {"to": depth, "top": y at the facade line, "kind", "color"}.
var left_walls: Array = []
var right_walls: Array = []
## Plates on the corner sign: the cross street, then the street we're on.
var street_name := ""
var along_name := "6e Avenue"
## Which way the street runs away from us (Montreal's compass, the street grid's "north"): "west" ends on Mount
## Royal; any other way ends in open sky and a few clouds.
var facing := "west"
## A crossing guard works this crosswalk (the school's).
var guard := false
## Which corner (left or right edge of the gap) the signs stand on.
var sign_side := 1.0

var _rng := RandomNumberGenerator.new()
var _tree_tex: Array[Texture2D] = []
# Depth ranges where the next streets cross ours down the vista (from the walls' "cross" gaps).
var _crossings: Array[Vector2] = []
# This season's canopy colours and what lies in the gutters.
var _foliage: Array[Color] = Season.foliage()
var _litter: Array[Color] = Season.litter()


static func make(which: Part, from: CrossStreet) -> CrossStreet:
	var cs := CrossStreet.new()
	cs.part = which
	for prop in ["x0", "x1", "sidewalk", "school", "left_walls", "right_walls", "street_name", "along_name", "facing", "sign_side"]:
		cs.set(prop, from.get(prop))
	return cs


func _vp() -> Vector2:
	return Vector2((x0 + x1) / 2.0, HORIZON_Y)


## Screen position of a point that would be at `front` on the facade line, `depth` units away.
func _at(front: Vector2, depth: float) -> Vector2:
	var vp := _vp()
	return vp + (front - vp) / (1.0 + depth)


## x where the line through the vanishing point and (x, FACADE_Y) crosses height y (y below the horizon).
func _fan(x: float, y: float) -> float:
	var vp := _vp()
	return vp.x + (x - vp.x) * (y - vp.y) / (FACADE_Y - vp.y)


## The road between the curbs at height y: x range Charlotte can't step into (yet).
func road_x(y: float) -> Vector2:
	return Vector2(_fan(x0 + sidewalk, y), _fan(x1 - sidewalk, y))


func _ready() -> void:
	_rng.seed = hash(street_name)
	if part == Part.VISTA:
		# Two street trees drawn like the street's own (PropArt.tree, this season), from their own random numbers.
		var trees := RandomNumberGenerator.new()
		trees.seed = hash(street_name + along_name)
		_tree_tex = [PropArt.tree(trees), PropArt.tree(trees)]


func _draw() -> void:
	match part:
		Part.VISTA:
			_draw_vista()
		Part.GROUND:
			_draw_ground()
		Part.SIGNS:
			_draw_signs()


# ── Vista ───────────────────────────────────────────────────────

func _draw_vista() -> void:
	var vp := _vp()
	_horizon()
	# The street and its sidewalks, all the way to the horizon.
	_quad(Vector2(x0, FACADE_Y), Vector2(x1, FACADE_Y), 0.0, FAR, Color("#E9EEF2") if Season.is_winter() else CONCRETE)
	_quad(Vector2(x0 + sidewalk, FACADE_Y), Vector2(x1 - sidewalk, FACADE_Y), 0.0, FAR, ASPHALT)
	for side in [x0 + sidewalk, x1 - sidewalk]:
		draw_line(_at(Vector2(side, FACADE_Y), 0.0), _at(Vector2(side, FACADE_Y), FAR), CURB, 2.0)
	# Faded centre line, and leaves along the gutters.
	for i in 30:
		var d := i * 0.55
		draw_line(_at(Vector2(vp.x, FACADE_Y), d), _at(Vector2(vp.x, FACADE_Y), d + 0.25), Color(0.95, 0.85, 0.4, 0.35), 2.0 / (1.0 + d))
	for i in 60:
		var d := pow(_rng.randf(), 2.0) * FAR
		var gx: float = [x0 + sidewalk + 6.0, x1 - sidewalk - 6.0][i % 2] + _rng.randf_range(-12, 12)
		var lc: Color = _litter[_rng.randi_range(0, 4) % _litter.size()]
		if float(i % 10) / 10.0 < Season.litter_amount():
			draw_circle(_at(Vector2(gx, FACADE_Y), d), 4.0 / (1.0 + d), lc)
	_street_details()
	_walls(left_walls, x0, -1.0)
	_walls(right_walls, x1, 1.0)
	_far_crosswalks()
	_curb_gardens()
	_haze_band(3.0, 9.0, 0.0, 0.35)
	_haze_band(9.0, FAR, 0.35, 0.6)
	_lamps()
	# Street trees on both sidewalks, far to near, then the utility poles along the curb with their wires.
	var k := 0
	for d in [14.0, 9.5, 6.6, 4.6, 3.2, 2.2, 1.3]:
		for side in [-1.0, 1.0]:
			var tx := x0 + sidewalk * 0.35 if side < 0.0 else x1 - sidewalk * 0.35
			_tree(Vector2(tx, FACADE_Y), d + (0.3 if side > 0.0 else 0.0), k)
			k += 1
	_poles()


# Where the next streets cross ours, further down: the road runs on through, its crosswalks painted across it.
func _far_crosswalks() -> void:
	var l := x0 + sidewalk
	var r := x1 - sidewalk
	for c in _crossings:
		for edge: float in [c.x + 0.05, c.y - 0.12]:
			if edge > DETAIL:
				continue
			var n := 9
			for i in n:
				var a := lerpf(l, r, (i + 0.2) / n)
				var b := lerpf(l, r, (i + 0.75) / n)
				draw_colored_polygon(PackedVector2Array([_at(Vector2(a, FACADE_Y), edge), _at(Vector2(b, FACADE_Y), edge),
					_at(Vector2(b, FACADE_Y), edge + 0.07), _at(Vector2(a, FACADE_Y), edge + 0.07)]), Color(1, 1, 1, 0.75))


# The planted curb extensions of the cross street too (like CurbGarden on ours): on both curbs just past the corner,
# and either side of the next crossing down; a rounded bed bulging into the road, perennials, striped bollards.
func _curb_gardens() -> void:
	var spans: Array[Vector2] = [Vector2(0.1, 0.8)]
	for c in _crossings:
		spans.append(Vector2(c.x - 0.6, c.x - 0.04))
		spans.append(Vector2(c.y + 0.04, c.y + 0.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(street_name + "beds")
	var winter := Season.is_winter()
	for span in spans:
		if span.x > DETAIL:
			continue
		for dir in [1.0, -1.0]:
			var curb := x0 + sidewalk if dir > 0.0 else x1 - sidewalk
			var outer := PackedVector2Array()
			var inner := PackedVector2Array()
			for k in 13:
				var t := k / 12.0
				var d := lerpf(span.x, span.y, t)
				var off := 74.0 * pow(sin(t * PI), 0.35)
				outer.append(_at(Vector2(curb + dir * off, FACADE_Y), d))
				inner.append(_at(Vector2(curb, FACADE_Y), d))
			var bed := outer.duplicate()
			for k in range(inner.size() - 1, -1, -1):
				bed.append(inner[k])
			draw_colored_polygon(bed, Color("#EEF2F5") if winter else Color("#5A4232"))
			draw_polyline(outer, Color("#D6D1C6"), maxf(1.0, 4.0 / (1.0 + span.x)), true)
			# Plants: tufts of grass and clumps of flowers or autumn colour, sized by the distance.
			for i in 26:
				var t := rng.randf_range(0.06, 0.94)
				var d := lerpf(span.x, span.y, t)
				var off := rng.randf_range(6.0, 66.0 * pow(sin(t * PI), 0.35))
				var p := _at(Vector2(curb + dir * off, FACADE_Y), d)
				var s := 1.0 / (1.0 + d)
				var c: Color = _foliage[rng.randi_range(0, _foliage.size() - 1)]
				if winter:
					draw_line(p, p + Vector2(rng.randf_range(-3, 3), -16.0) * s, Color("#8E7A62"), maxf(1.0, 1.5 * s))
				else:
					var h := rng.randf_range(14.0, 30.0)
					for b in 3:
						draw_line(p, p + Vector2(rng.randf_range(-6.0, 6.0), -h) * s, c.darkened(0.3), maxf(1.0, 2.0 * s))
					draw_circle(p + Vector2(0, -h * 0.6) * s, rng.randf_range(9.0, 15.0) * s, c.darkened(rng.randf_range(0.0, 0.25)))
					if rng.randf() < 0.4:
						draw_circle(p + Vector2(rng.randf_range(-4, 4), -h) * s, 4.0 * s, Color("#F2C230") if rng.randf() < 0.5 else Color("#C97AB8"))
			# The bollards at its two tips.
			for t in [0.0, 1.0]:
				var d := lerpf(span.x, span.y, t)
				var foot := _at(Vector2(curb + dir * 10.0, FACADE_Y), d)
				var s := 1.0 / (1.0 + d)
				draw_line(foot, foot + Vector2(0, -34.0) * s, Color("#1E1E1E"), maxf(1.0, 6.0 * s))
				draw_line(foot + Vector2(0, -12.0) * s, foot + Vector2(0, -18.0) * s, Color("#F4F4F4"), maxf(1.0, 6.0 * s))


# Street lamps along the right curb, receding (the poles are on the left).
func _lamps() -> void:
	var curb := x1 - sidewalk + 8.0
	for d: float in [2.6, 5.6, 9.5, 14.0]:
		var s := 1.0 / (1.0 + d)
		var foot := _at(Vector2(curb, FACADE_Y), d)
		var top := _at(Vector2(curb, FACADE_Y - 330.0), d)
		var metal := Color("#6B7075").lerp(HAZE, clampf(d / FAR, 0.0, 0.6))
		draw_line(foot, top, metal, maxf(1.0, 7.0 * s))
		var arm := top + Vector2(-50.0, 6.0) * s
		draw_line(top, arm, metal, maxf(1.0, 5.0 * s))
		draw_set_transform(arm, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 16.0 * s, metal.darkened(0.2))
		draw_set_transform(Vector2.ZERO)
		draw_circle(arm + Vector2(0, 4.0) * s, 7.0 * s, Color("#FFF1C9"))


# The sidewalks' slab joints, the gutters along the curbs, a manhole cover in the road.
func _street_details() -> void:
	var d := 0.35
	while d < DETAIL:
		for side in [[x0, x0 + sidewalk], [x1 - sidewalk, x1]]:
			draw_line(_at(Vector2(side[0], FACADE_Y), d), _at(Vector2(side[1], FACADE_Y), d), Color(0, 0, 0, 0.12), maxf(1.0, 2.0 / (1.0 + d)))
		d += 0.7
	for side in [x0 + sidewalk + 7.0, x1 - sidewalk - 7.0]:
		draw_line(_at(Vector2(side, FACADE_Y), 0.0), _at(Vector2(side, FACADE_Y), FAR), Color(0, 0, 0, 0.12), 7.0)
	var mh := _at(Vector2((x0 + x1) / 2.0 + 30.0, FACADE_Y), 2.5)
	var r := 22.0 / 3.5
	draw_set_transform(mh, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, r, Color("#4A4946"))
	draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color("#6E6D68"), 1.0)
	draw_set_transform(Vector2.ZERO)


# Wooden poles along the left curb, receding, the wires sagging from one to the next down to the horizon.
func _poles() -> void:
	var curb := x0 + sidewalk - 8.0
	var depths: Array[float] = [1.6, 4.0, 7.2, 11.5, 17.0]
	var tops: Array[Vector2] = []
	var scales: Array[float] = []
	for d in depths:
		var foot := _at(Vector2(curb, FACADE_Y), d)
		var top := _at(Vector2(curb, FACADE_Y - 470.0), d)
		var s := 1.0 / (1.0 + d)
		var wood := Color("#6E5B4A").lerp(HAZE, clampf(d / FAR, 0.0, 0.6))
		draw_line(foot, top, wood, maxf(1.0, 12.0 * s))
		draw_line(top + Vector2(-46.0, 24.0) * s, top + Vector2(46.0, 24.0) * s, wood.darkened(0.2), maxf(1.0, 6.0 * s))
		tops.append(top + Vector2(0, 24.0) * s)
		scales.append(s)
	tops.append(_vp() + Vector2(0, -6))
	scales.append(0.0)
	for w in 3:
		var off := Vector2((w - 1) * 30.0, 0)
		for i in tops.size() - 1:
			var a := tops[i] + off * scales[i]
			var b := tops[i + 1] + off * scales[i + 1]
			var pts := PackedVector2Array()
			for t in 9:
				var u := t / 8.0
				pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * a.distance_to(b) * 0.06))
			draw_polyline(pts, Color(0.12, 0.1, 0.1, 0.6), 1.0, true)


# The end of the street: open sky over the gap hides the distant city behind it (the top fades out so the clouds
# above stay); then Mount Royal if the street runs west, or just a few soft clouds low over the horizon.
func _horizon() -> void:
	var sky := Season.sky()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.82, 1.0])
	grad.colors = sky
	var sky_top := 90.0
	var bands := 8
	for i in bands:
		var ya := lerpf(sky_top, HORIZON_Y + 4.0, float(i) / bands)
		var yb := lerpf(sky_top, HORIZON_Y + 4.0, float(i + 1) / bands)
		var ca := grad.sample(ya / 720.0)
		var cb := grad.sample(yb / 720.0)
		ca.a = clampf((ya - sky_top) / 50.0, 0.0, 1.0)
		cb.a = clampf((yb - sky_top) / 50.0, 0.0, 1.0)
		# Fade out toward the sides too, so the patch has no visible edge.
		var xs := [x0, x0 + 140.0, x1 - 140.0, x1]
		var fades := [0.0, 1.0, 1.0, 0.0]
		for j in 3:
			draw_polygon(PackedVector2Array([Vector2(xs[j], ya), Vector2(xs[j + 1], ya), Vector2(xs[j + 1], yb), Vector2(xs[j], yb)]),
				PackedColorArray([Color(ca, ca.a * fades[j]), Color(ca, ca.a * fades[j + 1]), Color(cb, cb.a * fades[j + 1]), Color(cb, cb.a * fades[j])]))
	if facing == "west":
		_mount_royal()
	else:
		_far_clouds()


# Soft clouds drifting low over the end of a street that doesn't face the mountain.
func _far_clouds() -> void:
	var vp := _vp()
	var white := Color(1.0, 0.98, 0.95, 0.85).lerp(Season.sky()[2], 0.3)
	for k in 3:
		var c := vp + Vector2([-170.0, 40.0, 210.0][k], [-120.0, -170.0, -95.0][k])
		for p in [Vector2(-34, 6), Vector2(-12, -10), Vector2(14, -14), Vector2(36, 2), Vector2(0, 8)]:
			draw_circle(c + p * (1.0 - k * 0.15), 22.0 * (1.0 - k * 0.15), white)


# Mount Royal on the horizon: a long hazy hill in the season's colours, the cross on its summit.
func _mount_royal() -> void:
	var vp := _vp()
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		var x := lerpf(vp.x - 440.0, vp.x + 460.0, t)
		var bump := pow(sin(t * PI), 0.8) * 150.0 + sin(t * 9.0) * 6.0 + sin(t * 23.0) * 2.5
		pts.append(Vector2(x, HORIZON_Y - bump))
	pts.append(Vector2(vp.x + 460.0, HORIZON_Y + 4.0))
	pts.append(Vector2(vp.x - 440.0, HORIZON_Y + 4.0))
	draw_colored_polygon(pts, Color("#7D7A92"))
	# Autumn woods on its flanks, faded by the distance.
	for i in 140:
		var t := _rng.randf()
		var ridge := HORIZON_Y - pow(sin(t * PI), 0.8) * 150.0
		var c := Vector2(lerpf(vp.x - 420.0, vp.x + 440.0, t), lerpf(ridge + 10.0, HORIZON_Y, _rng.randf()))
		draw_circle(c, _rng.randf_range(3.0, 6.0), Color(_foliage[i % _foliage.size()].lerp(Color("#8C8098"), 0.6), 0.45))
	draw_colored_polygon(pts, Color(HAZE, 0.18))
	# The cross, planted on the ridge itself (the same curve as the outline, where it stands).
	var ct := 460.0 / 900.0
	var ridge := pow(sin(ct * PI), 0.8) * 150.0 + sin(ct * 9.0) * 6.0 + sin(ct * 23.0) * 2.5
	var top := Vector2(vp.x + 20.0, HORIZON_Y - ridge + 3.0)
	draw_line(top, top + Vector2(0, -24), Color("#F2EEE6"), 2.5)
	draw_line(top + Vector2(-6, -17), top + Vector2(6, -17), Color("#F2EEE6"), 2.5)


# Translucent haze over the street between two depths, thicker with distance.
func _haze_band(d0: float, d1: float, a0: float, a1: float) -> void:
	var top := FACADE_Y - 460.0
	var near := [_at(Vector2(x0, top), d0), _at(Vector2(x1, top), d0), _at(Vector2(x1, FACADE_Y), d0), _at(Vector2(x0, FACADE_Y), d0)]
	var far := [_at(Vector2(x0, top), d1), _at(Vector2(x1, top), d1), _at(Vector2(x1, FACADE_Y), d1), _at(Vector2(x0, FACADE_Y), d1)]
	# The walls and the road only (faces 1-3); face 0 is open sky, where Mount Royal shows.
	for i in range(1, 4):
		var j := (i + 1) % 4
		draw_polygon(PackedVector2Array([near[i], near[j], far[j], far[i]]),
			PackedColorArray([Color(HAZE, a0), Color(HAZE, a0), Color(HAZE, a1), Color(HAZE, a1)]))


func _quad(a: Vector2, b: Vector2, d0: float, d1: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([_at(a, d0), _at(b, d0), _at(b, d1), _at(a, d1)]), col)


# A wall face running along the cross street, from `front_x` on the facade line into the distance.
func _wall_quad(front_x: float, top: float, bottom: float, d0: float, d1: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		_at(Vector2(front_x, top), d0), _at(Vector2(front_x, bottom), d0),
		_at(Vector2(front_x, bottom), d1), _at(Vector2(front_x, top), d1)]), col)


func _walls(walls: Array, front_x: float, side: float) -> void:
	# First the end walls: a building taller than the one before it (or right after a lane or a cross street) shows
	# its end wall, square to the street and facing us, above that one's roof; without it it looks like a flat
	# cut-out. Drawn far to near and before the facades, so the nearer facades hide all but what rises above them.
	var ends := []
	var d := 0.0
	var prev_top := FACADE_Y
	for w in walls:
		var open_gap: bool = w.kind in ["gap", "cross"]
		if not open_gap and float(w.top) < prev_top - 2.0 and d > 0.0:
			ends.append([d, float(w.top), prev_top, w.color])
		prev_top = FACADE_Y if open_gap else float(w.top)
		d = w.to
	ends.reverse()
	for e in ends:
		_end_wall(front_x, side, e[1], e[2], e[0], e[3])
	var d0 := 0.0
	for w in walls:
		var d1: float = w.to
		match w.kind:
			"cross":
				# The next street across: open, its crosswalk painted over our road (see _far_crosswalks).
				_crossings.append(Vector2(d0, d1))
			"gap":
				# A back lane: a tree over a board fence, the lane's opening between.
				if not _tree_tex.is_empty() and d0 < DETAIL:
					var md := (d0 + d1) / 2.0
					var sz := Vector2(380, 780) * 0.42 / (1.0 + md)
					var foot := _at(Vector2(front_x + side * 30.0, FACADE_Y - 60.0), md)
					draw_texture_rect(_tree_tex[1], Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz), false, Color.WHITE.lerp(HAZE, clampf(md / FAR, 0.0, 0.6)))
				var fence := Color("#9A958C")
				_wall_quad(front_x, FACADE_Y - 120.0, FACADE_Y, d0, d0 + (d1 - d0) * 0.3, fence)
				_wall_quad(front_x, FACADE_Y - 120.0, FACADE_Y, d1 - (d1 - d0) * 0.3, d1, fence)
				var fd := d0
				while fd < d1 and fd < DETAIL:
					if fd < d0 + (d1 - d0) * 0.3 or fd > d1 - (d1 - d0) * 0.3:
						draw_line(_at(Vector2(front_x, FACADE_Y - 120.0), fd), _at(Vector2(front_x, FACADE_Y), fd), fence.darkened(0.3), 1.0)
					fd += 0.04
			_:
				var top: float = w.top
				var col: Color = w.color
				_wall_quad(front_x, top, FACADE_Y, d0, d1, col)
				if w.has("tex"):
					_textured_wall(front_x, w, d0, d1)
				else:
					_bricks(front_x, top, d0, d1, col)
				# Seen at a glancing angle: a darker shade, the further from the sun the darker.
				_wall_quad(front_x, top, FACADE_Y, d0, d1, Color(0.1, 0.04, 0.06, 0.18 if side < 0.0 else 0.3))
				_wall_quad(front_x, top, top + 14.0, d0, d1, col.darkened(0.35))
				_wall_quad(front_x, top - 6.0, top + 2.0, d0, d1, col.lightened(0.2))
				# Where one building ends and the next begins.
				draw_line(_at(Vector2(front_x, top), d0), _at(Vector2(front_x, FACADE_Y), d0), col.darkened(0.5), maxf(1.0, 2.5 / (1.0 + d0)))
				# A chimney or a vent box on the near roofs, set back from the edge.
				if d0 < 4.0 and w.kind == "plex" and not w.has("tex"):
					var cd := d0 + (d1 - d0) * 0.3
					var cx := front_x + side * 70.0
					var chim := PackedVector2Array([_at(Vector2(cx, top - 34.0), cd), _at(Vector2(cx + side * 26.0, top - 34.0), cd),
						_at(Vector2(cx + side * 26.0, top), cd), _at(Vector2(cx, top), cd)])
					draw_colored_polygon(chim, col.darkened(0.2))
					draw_colored_polygon(PackedVector2Array([chim[0] + Vector2(0, -3), chim[1] + Vector2(0, -3), chim[1], chim[0]]), Color("#5A5E62"))
				if not w.has("tex"):
					_wall_details(w, front_x, top, d0, d1)
		d0 = d1


# A building's real facade (its street's SVG, `w.tex`) laid along the wall in perspective: cut into thin strips down
# the depth so the mapping follows it; the facade's bottom on the facade line, as on its own street; hazier further.
func _textured_wall(front_x: float, w: Dictionary, d0: float, d1: float) -> void:
	var tex: Texture2D = w.tex
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var top := FACADE_Y - th * StreetScene.HOUSE_SCALE
	var u0 := 30.0 / tw
	var u1 := (tw - 30.0) / tw
	if w.get("flip", false):
		var t := u0
		u0 = u1
		u1 = t
	var strips := clampi(int((d1 - d0) * 40.0) + 4, 4, 24)
	var tint := Color.WHITE.lerp(HAZE, clampf(d0 / FAR * 1.4, 0.0, 0.65))
	var colors := PackedColorArray([tint, tint, tint, tint])
	for i in strips:
		var ta := float(i) / strips
		var tb := float(i + 1) / strips
		var da := lerpf(d0, d1, ta)
		var db := lerpf(d0, d1, tb)
		var ua := lerpf(u0, u1, ta)
		var ub := lerpf(u0, u1, tb)
		draw_polygon(PackedVector2Array([_at(Vector2(front_x, top), da), _at(Vector2(front_x, top), db),
			_at(Vector2(front_x, FACADE_Y), db), _at(Vector2(front_x, FACADE_Y), da)]),
			colors, PackedVector2Array([Vector2(ua, 0), Vector2(ub, 0), Vector2(ub, 1), Vector2(ua, 1)]), tex)


# Exposed brickwork on a drawn wall: the courses, and near enough to see, the staggered joints between the bricks.
func _bricks(front_x: float, top: float, d0: float, d1: float, col: Color) -> void:
	var joint := Color(col.darkened(0.3), 0.35)
	var lines := PackedVector2Array()
	var y := top + 22.0
	var row := 0
	while y < FACADE_Y - 4.0:
		lines.append_array([_at(Vector2(front_x, y), d0), _at(Vector2(front_x, y), minf(d1, DETAIL))])
		var dd := d0 + (0.028 if row % 2 == 1 else 0.0)
		while dd < minf(d1, 2.5):
			lines.append_array([_at(Vector2(front_x, y), dd), _at(Vector2(front_x, minf(y + 13.0, FACADE_Y)), dd)])
			dd += 0.056
		y += 13.0
		row += 1
	draw_multiline(lines, joint, 1.0)


# A building's end wall, square to the street at depth d (parallel to the screen), from its roof (top) down to `bottom`,
# running back from the facade line by a building's depth; brick courses and the coping on top.
func _end_wall(front_x: float, side: float, top: float, bottom: float, d: float, col: Color) -> void:
	var back := front_x + side * 360.0
	var face := col.lightened(0.04)
	draw_colored_polygon(PackedVector2Array([_at(Vector2(front_x, top), d), _at(Vector2(back, top), d),
		_at(Vector2(back, bottom), d), _at(Vector2(front_x, bottom), d)]), face)
	if d < DETAIL:
		var y := top + 22.0
		while y < bottom - 2.0:
			draw_line(_at(Vector2(front_x, y), d), _at(Vector2(back, y), d), Color(face.darkened(0.3), 0.35), 1.0)
			y += 13.0
	draw_colored_polygon(PackedVector2Array([_at(Vector2(front_x, top - 6.0), d), _at(Vector2(back, top - 6.0), d),
		_at(Vector2(back, top + 2.0), d), _at(Vector2(front_x, top + 2.0), d)]), col.darkened(0.35))
	draw_line(_at(Vector2(front_x, top), d), _at(Vector2(front_x, bottom), d), col.darkened(0.5), maxf(1.0, 2.0 / (1.0 + d)))


func _wall_details(w: Dictionary, front_x: float, top: float, d0: float, d1: float) -> void:
	var glass := Color("#6F8DA2")
	var trim := Color("#ECE8E0")
	var floors := maxi(1, int(round((FACADE_Y - top) / 150.0)))
	var span := d1 - d0
	match w.kind:
		"shop":
			# The dépanneur's real front on Dandurand: blue sign, red banners, glass door, green awning up top.
			_wall_quad(front_x, FACADE_Y - 150.0, FACADE_Y - 122.0, d0 + span * 0.08, d1 - span * 0.08, Color("#25408F"))
			_wall_quad(front_x, FACADE_Y - 156.0, FACADE_Y - 150.0, d0 + span * 0.04, d1 - span * 0.04, Color("#C8312A"))
			_wall_quad(front_x, FACADE_Y - 112.0, FACADE_Y - 10.0, d0 + span * 0.15, d0 + span * 0.45, glass)
			_wall_quad(front_x, FACADE_Y - 112.0, FACADE_Y - 6.0, d0 + span * 0.55, d0 + span * 0.7, Color("#3A3A3A"))
			_wall_quad(front_x, top + 14.0, top + 40.0, d0, d1, Color("#3E8C5A"))
			_windows(front_x, top + 70.0, d0, d1, 3, glass, trim)
		"ohbon":
			# Dépanneur Oh Bon!: its sign band, the windows, the red and white checkerboard, the red footing; galleries above.
			_wall_quad(front_x, FACADE_Y - 160.0, FACADE_Y - 136.0, d0 + span * 0.04, d0 + span * 0.7, Color("#C8202A"))
			_wall_quad(front_x, FACADE_Y - 156.0, FACADE_Y - 140.0, d0 + span * 0.06, d0 + span * 0.68, Color("#F4F1EA"))
			_wall_quad(front_x, FACADE_Y - 128.0, FACADE_Y - 40.0, d0 + span * 0.06, d0 + span * 0.45, glass)
			for k in 4:
				for row in 3:
					var a := d0 + span * (0.48 + k * 0.05)
					_wall_quad(front_x, FACADE_Y - 128.0 + row * 29.0, FACADE_Y - 99.0 + row * 29.0, a, a + span * 0.05,
						Color("#D9342B") if (k + row) % 2 == 0 else Color("#F4F1EA"))
			_wall_quad(front_x, FACADE_Y - 40.0, FACADE_Y, d0 + span * 0.04, d0 + span * 0.7, Color("#D9342B"))
			for gy in [FACADE_Y - 200.0, FACADE_Y - 350.0]:
				_wall_quad(front_x, gy, gy + 6.0, d0, d0 + span * 0.7, Color("#1F1F1F"))
				_wall_quad(front_x, gy + 26.0, gy + 32.0, d0, d0 + span * 0.7, Color("#D8D4CC"))
			_windows(front_x, top + 40.0, d0, d1, 3, glass, trim)
		"corner_holt":
			# The corner building's 6e side: the red corner window and awning at the corner, white lintels, the annex.
			_wall_quad(front_x, FACADE_Y - 120.0, FACADE_Y - 30.0, d0 + span * 0.02, d0 + span * 0.18, glass)
			_wall_quad(front_x, FACADE_Y - 138.0, FACADE_Y - 120.0, d0, d0 + span * 0.2, Color("#D9342B"))
			_wall_quad(front_x, FACADE_Y - 30.0, FACADE_Y, d0 + span * 0.02, d0 + span * 0.18, Color("#D9342B"))
			_wall_quad(front_x, FACADE_Y - 120.0, FACADE_Y, d1 - span * 0.3, d1, Color("#CBC5B6"))
			_wall_quad(front_x, FACADE_Y - 140.0, FACADE_Y - 120.0, d1 - span * 0.31, d1, Color("#7E848A"))
			for f in floors - 1:
				var y := top + 40.0 + f * 150.0
				_windows(front_x, y, d0 + span * 0.1, d1 - span * 0.1, 4, glass, trim)
				_windows(front_x, y - 16.0, d0 + span * 0.1, d1 - span * 0.1, 4, trim, trim)
		"garage":
			_wall_quad(front_x, FACADE_Y - 96.0, FACADE_Y, d0 + span * 0.2, d0 + span * 0.45, trim)
			_wall_quad(front_x, FACADE_Y - 96.0, FACADE_Y, d0 + span * 0.55, d0 + span * 0.85, trim)
			_wall_quad(front_x, FACADE_Y - 150.0, FACADE_Y - 136.0, d0 + span * 0.1, d0 + span * 0.9, Color("#6E4E34"))
			_windows(front_x, top + 40.0, d0, d1, 3, glass, trim)
		"school":
			for f in floors - 1:
				_windows(front_x, top + 50.0 + f * 130.0, d0, d1, int(span * 9.0), glass, trim)
			_wall_quad(front_x, top - 6.0, top + 18.0, d0, d1, Color("#4E8C7A"))
			_wall_quad(front_x, FACADE_Y - 60.0, FACADE_Y, d0, d1, Color("#C9C2B4"))
		_:
			# Each building (about 0.55 deep): a door at the top of its steps, iron balconies on the upper floors, and
			# the outdoor stair from the first balcony down to the sidewalk.
			var count := maxi(1, int(round(span / 0.55)))
			for b in count:
				var b0 := d0 + span * b / count
				var bs := span / count
				if b0 > DETAIL:
					break
				for f in range(1, floors):
					var yb := FACADE_Y - 150.0 * f + 8.0
					_wall_quad(front_x, yb, yb + 7.0, b0 + bs * 0.05, b0 + bs * 0.62, Color("#D8D4CC"))
					_wall_quad(front_x, yb - 32.0, yb - 28.0, b0 + bs * 0.05, b0 + bs * 0.62, Color("#1F1F1F"))
					for k2 in 7:
						var bd := b0 + bs * lerpf(0.07, 0.6, k2 / 6.0)
						draw_line(_at(Vector2(front_x, yb - 30.0), bd), _at(Vector2(front_x, yb), bd), Color("#1F1F1F"), 1.0)
				_wall_quad(front_x, FACADE_Y - 116.0, FACADE_Y - 22.0, b0 + bs * 0.4, b0 + bs * 0.5, Color("#5E3A26"))
				_wall_quad(front_x, FACADE_Y - 22.0, FACADE_Y, b0 + bs * 0.36, b0 + bs * 0.54, Color("#A8A196"))
				if floors > 1:
					var s0 := _at(Vector2(front_x, FACADE_Y - 142.0), b0 + bs * 0.62)
					var s1 := _at(Vector2(front_x, FACADE_Y), b0 + bs * 0.95)
					draw_line(s0, s1, Color("#1F1F1F"), maxf(1.0, 3.0 / (1.0 + b0)))
					draw_line(s0 + Vector2(0, -30.0) / (1.0 + b0), s1 + Vector2(0, -30.0) / (1.0 + b0), Color("#1F1F1F"), 1.0)
			for f in floors:
				_windows(front_x, top + 40.0 + f * 150.0, d0, d1, maxi(2, int(span * 5.0)), glass, trim)


# A row of `count` windows on a receding wall, each 90 px tall at the facade line.
func _windows(front_x: float, y: float, d0: float, d1: float, count: int, glass: Color, trim: Color) -> void:
	if y + 90.0 > FACADE_Y - 10.0:
		return
	var step := (d1 - d0) / count
	for i in count:
		if d0 + step * i > DETAIL:
			return
		var a := d0 + step * (i + 0.25)
		var b := d0 + step * (i + 0.75)
		_wall_quad(front_x, y - 16.0, y - 6.0, a - step * 0.08, b + step * 0.08, trim.darkened(0.08))
		_wall_quad(front_x, y - 4.0, y + 94.0, a - step * 0.04, b + step * 0.04, trim)
		_wall_quad(front_x, y, y + 90.0, a, b, glass)
		_wall_quad(front_x, y + 94.0, y + 100.0, a - step * 0.07, b + step * 0.07, trim.darkened(0.12))
		if a < 4.0:
			var m := (a + b) / 2.0
			draw_line(_at(Vector2(front_x, y), m), _at(Vector2(front_x, y + 90.0), m), trim, maxf(1.0, 3.0 / (1.0 + m)))
			draw_line(_at(Vector2(front_x, y + 32.0), a), _at(Vector2(front_x, y + 32.0), b), trim, maxf(1.0, 3.0 / (1.0 + m)))


# A street tree at depth d, drawn like the street's own (one of _tree_tex, this season's), in its pit, hazier with
# distance.
func _tree(base: Vector2, d: float, k := 0) -> void:
	var s := 1.0 / (1.0 + d)
	var foot := _at(base, d)
	draw_set_transform(foot, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 46.0 * s, Color("#5A4232").lerp(HAZE, clampf(d / FAR, 0.0, 0.6)))
	draw_set_transform(Vector2.ZERO)
	var sizes: Array[float] = [1.0, 0.85, 1.15]
	var size := Vector2(380, 780) * 0.5 * s * sizes[k % 3]
	draw_texture_rect(_tree_tex[k % _tree_tex.size()], Rect2(foot - Vector2(size.x * 0.5, size.y), size), false,
		Color.WHITE.lerp(HAZE, clampf(d / FAR * 1.4, 0.0, 0.65)))


# ── Ground ──────────────────────────────────────────────────────

func _draw_ground() -> void:
	var y0 := SIDEWALK_TOP
	var y1 := ROAD_BOTTOM
	var l := x0 + sidewalk
	var r := x1 - sidewalk
	# The asphalt replaces the sidewalk and the curb where the cross street meets 6e Avenue.
	draw_colored_polygon(PackedVector2Array([Vector2(_fan(l, y0), y0), Vector2(_fan(r, y0), y0), Vector2(_fan(r, y1), y1), Vector2(_fan(l, y1), y1)]), ASPHALT)
	# Curb faces and the dropped ramps where the crosswalk meets them.
	for side in [l, r]:
		var dir := -1.0 if side == l else 1.0
		draw_line(Vector2(_fan(side, y0), y0), Vector2(_fan(side, 604.0), 604.0), CURB, 3.0)
		draw_line(Vector2(_fan(side, 656.0), 656.0), Vector2(_fan(side, y1 - 8.0), y1 - 8.0), CURB, 3.0)
		var ramp := PackedVector2Array([Vector2(_fan(side, 604.0), 604.0), Vector2(_fan(side, 656.0), 656.0),
			Vector2(_fan(side, 656.0) + dir * 26.0, 656.0), Vector2(_fan(side, 604.0) + dir * 20.0, 604.0)])
		draw_colored_polygon(ramp, Color("#BDB7AD"))
		for t in 6:
			var ty := lerpf(610.0, 650.0, t / 5.0)
			draw_circle(Vector2(_fan(side, ty) + dir * 11.0, ty), 1.6, Color("#8E5A4A"))
	# Stop line, then the crosswalk where 6e's sidewalk crosses: bars that run along the cross street.
	draw_line(Vector2(_fan(l, 597.0), 597.0), Vector2(_fan(r, 597.0), 597.0), Color(1, 1, 1, 0.75), 3.0)
	var bar := Color("#F2C230", 0.92) if school else Color(1, 1, 1, 0.88)
	var n := 9
	for i in n:
		var a := lerpf(l, r, (i + 0.2) / n)
		var b := lerpf(l, r, (i + 0.75) / n)
		draw_colored_polygon(PackedVector2Array([Vector2(_fan(a, 606.0), 606.0), Vector2(_fan(b, 606.0), 606.0),
			Vector2(_fan(b, 654.0), 654.0), Vector2(_fan(a, 654.0), 654.0)]), bar)
	# A few cracks and leaves blown onto the road.
	for i in 22:
		var y := _rng.randf_range(y0 + 4.0, y1 - 4.0)
		var x := _rng.randf_range(_fan(l, y), _fan(r, y))
		draw_set_transform(Vector2(x, y), _rng.randf_range(0.0, PI), Vector2(1.0, 0.5))
		var size := _rng.randf_range(3.0, 5.0)
		var lc: Color = _litter[_rng.randi_range(0, 4) % _litter.size()]
		if float(i % 10) / 10.0 < Season.litter_amount():
			draw_circle(Vector2.ZERO, size, lc)
	draw_set_transform(Vector2.ZERO)


# ── Signs ───────────────────────────────────────────────────────

func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	# A name post at both corners of the intersection; the stop or school-zone sign only on `sign_side`'s.
	for side in [-1.0, 1.0]:
		# At the corner of the sidewalk, by the curb, clear of the shop signs on the facades.
		var corner := x0 + sidewalk - 22.0 if side < 0.0 else x1 - sidewalk + 22.0
		var px := _fan(corner, 650.0)
		draw_rect(Rect2(px - 3, 236, 6, 416), Color("#5A5F63"))
		if side == sign_side:
			_traffic_sign(px, font)
		_name_plates(Vector2(px, 236.0), font)


# Montreal-style blue street plates: the street we're on faces us, flat; the cross street's plate is turned to run
# along that street, so it slants toward the vanishing point like the street itself.
func _name_plates(top: Vector2, font: Font) -> void:
	# The slanted plate on top, centred on the post; it tilts by at most ~30 px each way, so the flat one goes
	# well below it.
	var e := (_vp() - top).normalized()
	if e.x < 0.0:
		e = -e
	var f := 0.72
	_plate(Rect2(top.x - 80, top.y + 64, 160, 26), along_name, font)
	var origin := top + Vector2(0, 2) - e * 80.0 * f
	draw_set_transform_matrix(Transform2D(e * f, Vector2(0, 1), origin))
	_plate(Rect2(0, 0, 160, 26), street_name, font)
	draw_set_transform(Vector2.ZERO)


func _plate(r: Rect2, text: String, font: Font) -> void:
	draw_rect(r, Color.WHITE)
	draw_rect(r.grow(-2.5), Color("#1D4F91"))
	draw_string(font, Vector2(r.position.x, r.position.y + 19), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)


func _traffic_sign(px: float, font: Font) -> void:
	if school:
		var c := Vector2(px, 420)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -34), c + Vector2(30, -8), c + Vector2(30, 30), c + Vector2(-30, 30), c + Vector2(-30, -8)]), Color("#C8E03A"))
		draw_polyline(PackedVector2Array([c + Vector2(0, -34), c + Vector2(30, -8), c + Vector2(30, 30), c + Vector2(-30, 30), c + Vector2(-30, -8), c + Vector2(0, -34)]), Color("#1E1E1E"), 2.0, true)
		for k in [-1.0, 1.0]:
			var kid := c + Vector2(k * 10.0, 4.0)
			draw_circle(kid + Vector2(0, -14), 4.0, Color("#1E1E1E"))
			draw_line(kid + Vector2(0, -10), kid + Vector2(0, 6), Color("#1E1E1E"), 4.0)
			draw_line(kid + Vector2(0, 6), kid + Vector2(-4 * k, 18), Color("#1E1E1E"), 3.0)
			draw_line(kid + Vector2(0, 6), kid + Vector2(5 * k, 18), Color("#1E1E1E"), 3.0)
		draw_rect(Rect2(px - 20, 456, 40, 44), Color.WHITE)
		draw_rect(Rect2(px - 20, 456, 40, 44), Color("#1E1E1E"), false, 2.0)
		draw_string(font, Vector2(px - 20, 490), "30", HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Color("#1E1E1E"))
	else:
		var c := Vector2(px, 430)
		var oct := PackedVector2Array()
		for i in 8:
			oct.append(c + Vector2.from_angle(TAU * (i + 0.5) / 8.0) * 30.0)
		draw_colored_polygon(oct, Color.WHITE)
		var inner := PackedVector2Array()
		for p in oct:
			inner.append(c + (p - c) * 0.88)
		draw_colored_polygon(inner, Color("#C8202A"))
		draw_string(font, c + Vector2(-30, 5), "ARRÊT", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Color.WHITE)
