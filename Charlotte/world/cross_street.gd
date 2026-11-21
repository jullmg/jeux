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
##  - MOUTH (instead of GROUND, in a back lane that comes out on this street): the street's sidewalks and road carrying
##    on toward us, to the bottom of the view, past the end of the lane's concrete.
## Every point is drawn as its projection at the facade line (y FACADE_Y) shrunk toward the vanishing
## point by 1 / (1 + depth).

enum Part { VISTA, GROUND, SIGNS, MOUTH }

const FACADE_Y := 592.0
const HORIZON_Y := 452.0
static var _mountains := {}
const SIDEWALK_TOP := 590.0
const ROAD_BOTTOM := 676.0
const VIEW_BOTTOM := 720.0
const FAR := 24.0
## Beyond this depth, details (windows) are too small to draw.
const DETAIL := 8.0
const HAZE := Color("#B9C6D6")
const ASPHALT := Color("#5A5956")
const CONCRETE := Color("#CFCAC0")
const CURB := Color("#E2DDD4")
## Street trees down the vista: how far along (depths, clear of the poles at 1.6, 4, 7.2, 11.5 and the lamps at 2.6, 5.6, 9.5, 14), how
## far from the curb, and the size of their pits (half across the sidewalk, half along the street in depth at d = 0).
const TREES_LEFT: Array[float] = [1.05, 2.8, 5.5, 9.2, 14.0]
const TREES_RIGHT: Array[float] = [1.3, 4.0, 7.4, 11.6, 16.0]
const TREE_FROM_CURB := 26.0
const PIT_HALF := 19.0
const PIT_ALONG := 0.09

var part := Part.VISTA
## Gap between the corner buildings, in world x at the facade line.
var x0 := 0.0
var x1 := 560.0
## Sidewalk width on each side of the cross street, at the facade line.
const SIDEWALK := 96.0
var sidewalk := SIDEWALK
## School zone: yellow crosswalk and a school sign.
var school := false
## Walls along each side, nearest first: {"to": depth, "top": y at the facade line, "kind", "color"}.
var left_walls: Array = []
var right_walls: Array = []
## Volumes standing back from a wall line, drawn behind the walls so only what rises over them shows: a church tower that is
## on the cross street's own front, seen from the side down the vista. Each {side (-1 left, 1 right), back (px out from that
## side's wall line), d0, d1 (depth), tex, rect (the part of tex to lay on the face, in its pixels)}.
var towers: Array = []
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
## MOUTH: which side of the street the lane comes in from (-1 left, 1 right): its curb is dropped.
var lane_side := 1.0
## Seen from a back lane: no corner here, so no planted curb extensions right before us; and the open sky painted over the
## distant city fades in slowly, leaving the sun (see _horizon).
var from_lane := false

## The crosswalks over OUR street at this intersection (the ones that go toward the camera), one at each corner that has
## one: -1 = along the gap's left edge, 1 = its right edge. Every corner she can stand on gets one (Julien: she must be
## able to cross on both sides of the cross street). Set on the GROUND part with `add_own(side)` by
## `StreetScene._add_corner` / `_add_across` (and Masson's `_masson_crossing`), which also make it clickable
## (`own_crosswalk_rect(side)`).
var own_sides: Array[float] = []
const OWN_CROSSWALK_W := 88.0
const OWN_CROSSWALK_TOP := 664.0

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
	for prop in ["x0", "x1", "sidewalk", "school", "left_walls", "right_walls", "towers", "street_name", "along_name", "facing", "sign_side", "lane_side"]:
		cs.set(prop, from.get(prop))
	return cs


## The grids the walls are drawn with (`_wall_grid`), kept alive as long as the vista.
var _wall_meshes: Array[Mesh] = []
## The worst a picture's level line bends, in px, over every grid drawn so far, in any vista (`_wall_grid`): the check tool
## (`tools/check_walls.gd`) fails above `MAX_BEND`. A saw along a wall's bricks and roof line is what this keeps out.
static var worst_bend := 0.0
static var grids_drawn := 0
static var grid_cells := 0
const MAX_BEND := 0.75

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


## The crosswalk over our own street, at the curb: its two ends, in line with the cross street's sidewalk (Julien), from that
## sidewalk's curb outward over the corner. Below the curb both its edges run toward the vanishing point, the very lines of the
## cross street's curb and sidewalk carried on, so it widens as it comes toward us; the planted curb extension beside it is
## moved out of its way (`own_clear`).
func _own_ends(side: float) -> Vector2:
	var curbs := road_x(OWN_CROSSWALK_TOP)
	if side < 0.0:
		return Vector2(curbs.x - OWN_CROSSWALK_W, curbs.x)
	return Vector2(curbs.y, curbs.y + OWN_CROSSWALK_W)


## x of the line from (x, OWN_CROSSWALK_TOP) toward the vanishing point, at height y.
func _own_edge(x: float, y: float) -> float:
	var vp := _vp()
	return vp.x + (x - vp.x) * (y - vp.y) / (OWN_CROSSWALK_TOP - vp.y)


## How far the crosswalk over our own street reaches along the curb on `side` (-1 the gap's left, 1 its right), down to the
## bottom of the view, plus a little room: a planted curb extension on that side starts beyond it.
func own_clear(side: float) -> float:
	var e := _own_ends(side)
	if side < 0.0:
		return minf(e.x, _own_edge(e.x, VIEW_BOTTOM)) - 14.0
	return maxf(e.y, _own_edge(e.y, VIEW_BOTTOM)) + 14.0


## Paints the crosswalk over our own street at the corner on `side` (-1 left, 1 right of the gap).
func add_own(side: float) -> void:
	if not own_sides.has(side):
		own_sides.append(side)
	queue_redraw()


func has_own(side: float) -> bool:
	return own_sides.has(side)


## Where the crosswalk over our own street at the corner on `side` lies (world rectangle, from the corner's dropped curb to
## the bottom of the view).
func own_crosswalk_rect(side: float) -> Rect2:
	var e := _own_ends(side)
	var l := minf(e.x, _own_edge(e.x, VIEW_BOTTOM))
	var r := maxf(e.y, _own_edge(e.y, VIEW_BOTTOM))
	return Rect2(l - 4.0, OWN_CROSSWALK_TOP - 14.0, r - l + 8.0, VIEW_BOTTOM - OWN_CROSSWALK_TOP + 14.0)


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
		Part.MOUTH:
			_draw_mouth()


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
	for t: Dictionary in towers:
		_tower_face(t)
	_walls(left_walls, x0, -1.0)
	_walls(right_walls, x1, 1.0)
	_far_crosswalks()
	_curb_gardens()
	_haze_band(3.0, 9.0, 0.0, 0.35)
	_haze_band(9.0, FAR, 0.35, 0.6)
	_lamps()
	# Street trees on both sidewalks, far to near, then the utility poles along the curb with their wires.
	# At the curb, as on the street itself, not in the middle of the sidewalk: between the poles (left curb) and lamps (right curb).
	var planted := []
	for d: float in TREES_LEFT:
		planted.append([d, x0 + sidewalk - TREE_FROM_CURB])
	for d: float in TREES_RIGHT:
		planted.append([d, x1 - sidewalk + TREE_FROM_CURB])
	planted.sort_custom(func(a, b): return a[0] > b[0])
	var k := 0
	for t in planted:
		_tree(Vector2(t[1], FACADE_Y), t[0], k)
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
	var spans: Array[Vector2] = []
	if not from_lane:
		spans.append(Vector2(0.1, 0.8))
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
	draw_circle(Vector2.ZERO, r * 1.25, Color("#4A4946"))
	draw_circle(Vector2.ZERO, r, Color("#2E2D2B"))
	draw_circle(Vector2.ZERO, r * 0.86, Color("#4E4C48"))
	draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 16, Color("#3A3936"), 1.0)
	draw_rect(Rect2(-r * 0.7, -r * 0.14, r * 1.4, r * 0.28), Color("#45433F"))
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
	# From a lane the gap is where the sun hangs: a long fade, the sun and the city's roofs dissolving into the haze.
	var fade := 240.0 if from_lane else 50.0
	var bands := 16 if from_lane else 8
	for i in bands:
		var ya := lerpf(sky_top, HORIZON_Y + 4.0, float(i) / bands)
		var yb := lerpf(sky_top, HORIZON_Y + 4.0, float(i + 1) / bands)
		var ca := grad.sample(ya / 720.0)
		var cb := grad.sample(yb / 720.0)
		ca.a = clampf((ya - sky_top) / fade, 0.0, 1.0)
		cb.a = clampf((yb - sky_top) / fade, 0.0, 1.0)
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


# Mount Royal on the horizon, its picture made once per season.
func _mount_royal() -> void:
	# The draws the old hill took, so the rest of the vista stays as it is.
	for i in 420:
		_rng.randf()
	var picture := _mountain_picture()
	draw_texture(picture, Vector2(_vp().x - picture.get_width() / 2.0, HORIZON_Y + 4.0 - picture.get_height()))


# The mountain's height above the horizon, t 0..1 across it: the long ridge with its summit a little right of the middle, the
# Westmount shoulder on the left.
static func _mountain_ridge(t: float) -> float:
	var hill := pow(sin(t * PI), 0.55)
	return hill * (66.0 + 30.0 * exp(-pow((t - 0.52) / 0.1, 2.0)) + 14.0 * exp(-pow((t - 0.3) / 0.06, 2.0))) + sin(t * 41.0) * 1.5 * hill


# Mount Royal far off: a paler ridge behind, then the woods in this season's colours, clumps of trees massed from the ridge down,
# lit on the slopes facing the sun (left), bluer and lost in mist toward its foot; the cross and the tower on the summit.
static func _mountain_picture() -> ImageTexture:
	if _mountains.has(Season.current):
		return _mountains[Season.current]
	const W := 1300.0
	const H := 150.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var air := Color("#92A8C6")
	var tones: Array[Color] = []
	for palette in Season.tree_palettes():
		for c: String in palette:
			tones.append(Color(c))
	if tones.is_empty():
		# Winter: bare grey woods, snow showing through.
		tones = [Color("#8D8C96"), Color("#A5A5AF"), Color("#D9DEE5"), Color("#77767F"), Color("#EEF1F4")]
	var outline := func(scale: float, shift: float, color: Color) -> String:
		var pts := ""
		for i in 49:
			var t := i / 48.0
			pts += "%.1f,%.1f " % [lerpf(10.0, W - 10.0, t), H - _mountain_ridge(clampf(t + shift, 0.0, 1.0)) * scale]
		return '<polygon points="%s %.1f,%.1f 10,%.1f" fill="#%s"/>' % [pts, W - 10.0, H, H, color.to_html(false)]
	var s := '<defs><linearGradient id="mist" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#%s" stop-opacity="0"/><stop offset="1" stop-color="#%s" stop-opacity="0.85"/></linearGradient></defs>' % [air.to_html(false), air.lightened(0.15).to_html(false)]
	s += outline.call(0.82, -0.07, air.lerp(Color.WHITE, 0.12))
	var mean := Color(0, 0, 0)
	for c in tones:
		mean += c / float(tones.size())
	s += outline.call(1.0, 0.0, Color(mean.r, mean.g, mean.b).lerp(air, 0.5).darkened(0.08))
	# Row after row from the ridge down, so the nearer trees lie over the farther ones.
	for row in 30:
		var depth := row / 30.0
		for i in 190:
			var t := rng.randf()
			var ridge := _mountain_ridge(t)
			var x := lerpf(10.0, W - 10.0, t)
			var y := H - ridge * (1.0 - depth) + rng.randf_range(-3.0, 3.0)
			var tone: Color = tones[rng.randi_range(0, tones.size() - 1)]
			var slope := _mountain_ridge(clampf(t + 0.02, 0.0, 1.0)) - _mountain_ridge(clampf(t - 0.02, 0.0, 1.0))
			tone = tone.lightened(clampf(slope * 0.05, 0.0, 0.2)) if slope > 0.0 else tone.darkened(clampf(-slope * 0.05, 0.0, 0.25))
			tone = tone.lerp(air, 0.6 + depth * 0.14)
			if ridge > 2.0:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#%s"/>' % [x, y, rng.randf_range(2.0, 4.0), rng.randf_range(1.4, 2.8), tone.to_html(false)]
	# The treetops along the ridge, so it has no clean edge.
	for i in 700:
		var t := rng.randf()
		var tone: Color = tones[rng.randi_range(0, tones.size() - 1)].lerp(air, 0.62)
		var ridge := _mountain_ridge(t)
		if ridge > 2.0:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#%s"/>' % [lerpf(10.0, W - 10.0, t), H - ridge, rng.randf_range(1.6, 3.0), rng.randf_range(1.2, 2.4), tone.to_html(false)]
	s += '<rect x="0" y="%.1f" width="%.1f" height="60" fill="url(#mist)"/>' % [H - 60.0, W]
	# The cross on the summit, and the radio tower beside it.
	var summit := 0.52
	var foot := Vector2(lerpf(10.0, W - 10.0, summit), H - _mountain_ridge(summit) + 3.0)
	var mast := foot + Vector2(26.0, 2.0)
	s += '<path d="M%.1f %.1f V%.1f M%.1f %.1f H%.1f" stroke="#AEB6C2" stroke-width="1" fill="none"/>' % [mast.x, mast.y, mast.y - 22.0, mast.x - 2.0, mast.y - 15.0, mast.x + 2.0]
	s += '<path d="M%.1f %.1f V%.1f M%.1f %.1f H%.1f" stroke="#F4F0E8" stroke-width="1.8" fill="none"/>' % [foot.x, foot.y, foot.y - 17.0, foot.x - 5.0, foot.y - 12.0, foot.x + 5.0]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [W, H, W, H, s]
	var picture := PropArt.tex(svg)
	_mountains[Season.current] = picture
	return picture


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
	var pts := PackedVector2Array([
		_at(Vector2(front_x, top), d0), _at(Vector2(front_x, bottom), d0),
		_at(Vector2(front_x, bottom), d1), _at(Vector2(front_x, top), d1)])
	# Far down the street a window shrinks to a sliver that `draw_colored_polygon` can't triangulate (Godot reports it): a quad
	# is drawn as a primitive instead, which never needs triangulating; one with no area at all is skipped.
	if absf((pts[2] - pts[0]).cross(pts[3] - pts[1])) < 0.01:
		return
	draw_primitive(pts, PackedColorArray([col, col, col, col]), PackedVector2Array())


func _walls(walls: Array, front_x: float, side: float) -> void:
	# First the end walls: a building taller than the one before it (or right after a lane or a cross street) shows
	# its end wall, square to the street and facing us, above that one's roof; without it it looks like a flat
	# cut-out. Drawn far to near and before the facades, so the nearer facades hide all but what rises above them.
	var ends := []
	var d := 0.0
	var prev_top := FACADE_Y
	for w in walls:
		var open_gap: bool = w.kind in ["gap", "cross", "park", "lot"]
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
			"park", "lot":
				_open_lot(w.kind, front_x, side, d0, d1)
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
				if w.has("tex"):
					# Its own picture only: a flat fill to the picture's full height showed as a block of colour wherever the
					# facade is lower than its picture (the church's side beside its tower). The glancing shade is in the tint.
					_textured_wall(front_x, w, d0, d1, side)
				elif w.kind == "plex":
					# A row of plexes: drawn whole by `_plex_row` (walls, windows, balconies, stairs, cornice).
					_plex_row(w, front_x, top, d0, d1, side)
					d0 = d1
					continue
				elif w.kind == "side":
					# The corner building's flank (`StreetScene._join_corners`): no door, balcony or stair on it.
					_side_wall(w, front_x, top, d0, d1, side)
					d0 = d1
					continue
				else:
					_wall_quad(front_x, top, FACADE_Y, d0, d1, col)
					_bricks(front_x, top, d0, d1, col)
					# Seen at a glancing angle: a darker shade, the further from the sun the darker.
					_wall_quad(front_x, top, FACADE_Y, d0, d1, Color(0.1, 0.04, 0.06, 0.18 if side < 0.0 else 0.3))
					_wall_quad(front_x, top, top + 14.0, d0, d1, col.darkened(0.35))
				if not w.has("tex"):
					_wall_quad(front_x, top - 6.0, top + 2.0, d0, d1, col.lightened(0.2))
				# Where one building ends and the next begins.
				draw_line(_at(Vector2(front_x, top), d0), _at(Vector2(front_x, FACADE_Y), d0), col.darkened(0.5), maxf(1.0, 2.5 / (1.0 + d0)))
				if not w.has("tex"):
					_wall_details(w, front_x, top, d0, d1, side)
		d0 = d1


# An open corner lot along the street instead of a building: a park (its lawn running back, big trees, a low iron fence) or a
# parking lot (asphalt behind a low hedge, a few tall lamp posts). Its ground lies flat beyond the sidewalk line.
func _open_lot(kind: String, front_x: float, side: float, d0: float, d1: float) -> void:
	var back := front_x + side * 900.0
	var ground: Color
	if kind == "park":
		ground = {"winter": Color("#E4E9EE"), "spring": Color("#7AAE58"), "summer": Color("#5E9A44")}.get(Season.current, Color("#8EA052"))
	else:
		ground = Color("#7A7874")
	ground = ground.lerp(HAZE, clampf(d0 / FAR, 0.0, 0.5))
	draw_colored_polygon(PackedVector2Array([_at(Vector2(front_x, FACADE_Y), d0), _at(Vector2(back, FACADE_Y), d0),
		_at(Vector2(back, FACADE_Y), d1), _at(Vector2(front_x, FACADE_Y), d1)]), ground)
	if kind == "park":
		# The trees, far to near so the near ones cover the far ones, a little in from the fence.
		if not _tree_tex.is_empty():
			var ds: Array[float] = []
			var td := d0 + 0.08
			while td < d1 - 0.04 and td < DETAIL:
				ds.append(td)
				td += 0.3
			ds.reverse()
			for i in ds.size():
				var md: float = ds[i]
				var sz := Vector2(380, 780) * 0.62 / (1.0 + md)
				var foot := _at(Vector2(front_x + side * (90.0 + 120.0 * float(i % 2)), FACADE_Y), md)
				draw_texture_rect(_tree_tex[i % 2], Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz), false, Color.WHITE.lerp(HAZE, clampf(md / FAR, 0.0, 0.6)))
		var iron := Color("#262626")
		_wall_quad(front_x, FACADE_Y - 44.0, FACADE_Y - 40.0, d0, d1, iron)
		var fd := d0
		while fd < d1 and fd < DETAIL:
			draw_line(_at(Vector2(front_x, FACADE_Y - 44.0), fd), _at(Vector2(front_x, FACADE_Y), fd), iron, 1.0)
			fd += 0.02
	else:
		var hedge: Color = {"winter": Color("#6A5A4A"), "spring": Color("#4E8A44"), "summer": Color("#3E7A3A")}.get(Season.current, Color("#A8442E"))
		_wall_quad(front_x, FACADE_Y - 50.0, FACADE_Y, d0, d1, hedge.lerp(HAZE, clampf(d0 / FAR, 0.0, 0.5)))
		_wall_quad(front_x, FACADE_Y - 50.0, FACADE_Y - 40.0, d0, d1, hedge.lightened(0.15))
		var ld := d0 + 0.2
		while ld < d1 and ld < DETAIL:
			draw_line(_at(Vector2(front_x + side * 120.0, FACADE_Y - 420.0), ld), _at(Vector2(front_x + side * 120.0, FACADE_Y), ld), Color("#3A3A3A"), maxf(1.0, 4.0 / (1.0 + ld)))
			ld += 0.6


# A tower's side face running back from depth d0 to d1, `back` px out from the wall line, its picture taken from `rect` of
# the tower's own front; its foot on the facade line, its top where the picture's top is.
func _tower_face(t: Dictionary) -> void:
	if t.has("d"):
		_tower_end(t)
		return
	var tex: Texture2D = t.tex
	var r: Rect2 = t.rect
	var side: float = t.side
	var x: float = (x0 if side < 0.0 else x1) + side * float(t.back)
	var top := FACADE_Y - (tex.get_height() - r.position.y) * StreetScene.HOUSE_SCALE
	var bottom := FACADE_Y - (tex.get_height() - r.end.y) * StreetScene.HOUSE_SCALE
	var u0 := r.position.x / tex.get_width()
	var u1 := r.end.x / tex.get_width()
	var v0 := r.position.y / tex.get_height()
	var v1 := r.end.y / tex.get_height()
	var d0: float = t.d0
	var d1: float = t.d1
	var span := absf(_at(Vector2(x, top), d0).x - _at(Vector2(x, top), d1).x)
	var strips := clampi(int(span / 4.0) + 4, 4, 120)
	# Its side, out of the sun: a little darker than its front.
	var tint := Color.WHITE.darkened(0.2 if side < 0.0 else 0.3)
	_wall_grid(tex, x, top, bottom, d0, d1, u1 if side < 0.0 else u0, u0 if side < 0.0 else u1, v0, v1, tint, strips)


# A tower's face square to the view (`d`: its depth), from the wall line out by `back` px: seen down a street that runs along
# the tower's front, the side it turns toward us, standing over the lower buildings nearer to us.
func _tower_end(t: Dictionary) -> void:
	var tex: Texture2D = t.tex
	var r: Rect2 = t.rect
	var side: float = t.side
	var line: float = x0 if side < 0.0 else x1
	var out := line + side * float(t.back)
	var top := FACADE_Y - (tex.get_height() - r.position.y) * StreetScene.HOUSE_SCALE
	var bottom := FACADE_Y - (tex.get_height() - r.end.y) * StreetScene.HOUSE_SCALE
	var d: float = t.d
	var tint := Color.WHITE.lerp(HAZE, clampf(d / FAR * 1.4, 0.0, 0.6)).darkened(0.08)
	var u0 := r.position.x / tex.get_width()
	var u1 := r.end.x / tex.get_width()
	var v0 := r.position.y / tex.get_height()
	var v1 := r.end.y / tex.get_height()
	var a := _at(Vector2(line, top), d)
	var b := _at(Vector2(out, top), d)
	var c := _at(Vector2(out, bottom), d)
	var e := _at(Vector2(line, bottom), d)
	var ua := u0 if side > 0.0 else u1
	var ub := u1 if side > 0.0 else u0
	draw_polygon(PackedVector2Array([a, b, c, e]), PackedColorArray([tint, tint, tint, tint]),
		PackedVector2Array([Vector2(ua, v0), Vector2(ub, v0), Vector2(ub, v1), Vector2(ua, v1)]), tex)
	# Its edge toward the street catches the light.
	draw_line(a, e, Color(1, 1, 1, 0.25), maxf(1.0, 3.0 / (1.0 + d)))


# A building's real facade (its street's SVG, `w.tex`) laid along the wall in perspective: cut into thin strips down
# the depth so the mapping follows it; the facade's bottom on the facade line, as on its own street; hazier further.
func _textured_wall(front_x: float, w: Dictionary, d0: float, d1: float, side := 1.0) -> void:
	var tex: Texture2D = w.tex
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var top := FACADE_Y - th * StreetScene.HOUSE_SCALE
	# `fit_top`: the corner building's other face, its roof brought to our corner's (`StreetScene._join_corners`): the
	# picture is stretched a little, top to bottom, so its roof line lands there.
	if w.has("fit_top") and w.has("roof"):
		var k := (FACADE_Y - float(w.fit_top)) / maxf((th - float(w.roof)) * StreetScene.HOUSE_SCALE, 1.0)
		top = FACADE_Y - th * StreetScene.HOUSE_SCALE * k
	# `crop`: only up to its roof line, so a tower that really stands elsewhere (see `towers`) isn't painted on the wall.
	var v_top := 0.0
	if w.get("crop", false):
		top = float(w.top) - 4.0
		v_top = 1.0 - (FACADE_Y - top) / (th * StreetScene.HOUSE_SCALE)
	var u0 := 30.0 / tw
	var u1 := (tw - 30.0) / tw
	if w.get("flip", false):
		var t := u0
		u0 = u1
		u1 = t
	# Each strip is two triangles mapped flat, which kinks the facade's level lines (roof, stone courses) into a saw where it
	# bends: thin strips on screen, about 6 px each, keep that kink too small to see.
	var span := absf(_at(Vector2(front_x, top), d0).x - _at(Vector2(front_x, top), d1).x)
	var strips := clampi(int(span / 6.0) + 4, 4, 200)
	var tint := Color.WHITE.lerp(HAZE, clampf(d0 / FAR * 1.4, 0.0, 0.65)).darkened(0.16 if side < 0.0 else 0.27)
	_wall_grid(tex, front_x, top, FACADE_Y, d0, d1, u0, u1, v_top, 1.0, tint, strips)


# The worst bend (px) a grid of `strips` by `rows` makes of a level line: the middle of each cell where its two triangles
# put it, against where it truly is.
func _grid_bend(x: float, top: float, bottom: float, d0: float, d1: float, strips: int, rows: int) -> float:
	var worst := 0.0
	for i in strips:
		var da := lerpf(d0, d1, float(i) / strips)
		var db := lerpf(d0, d1, float(i + 1) / strips)
		for r in rows:
			var ya := lerpf(top, bottom, float(r) / rows)
			var yb := lerpf(top, bottom, float(r + 1) / rows)
			var mid := (_at(Vector2(x, ya), da) + _at(Vector2(x, yb), db)) * 0.5
			var truth := _at(Vector2(x, (ya + yb) * 0.5), (da + db) * 0.5)
			worst = maxf(worst, mid.distance_to(truth))
	return worst


# A picture laid on a receding wall as a grid, `strips` columns down the depth and several rows: a level line of the picture
# (the roof, a course of bricks, a balcony) is a straight line on a real wall, and so it is here. One quad of two triangles
# bends it into a V at the diagonal, which read as a saw along every wall; with rows the quads are near enough to
# parallelograms that the bend is a fraction of a pixel. u runs from `ua` at depth d0 to `ub` at d1, v from `va` at `top` to `vb`.
func _wall_grid(tex: Texture2D, x: float, top: float, bottom: float, d0: float, d1: float, ua: float, ub: float, va: float, vb: float,
		tint: Color, strips: int) -> void:
	# Rows enough that no cell bends a level line by more than a fraction of a pixel (`MAX_BEND`): the nearer and the taller
	# the wall, the more it takes.
	var rows := clampi(int(absf(bottom - top) / 28.0) + 4, 6, 24)
	while rows < 96 and _grid_bend(x, top, bottom, d0, d1, strips, rows) > MAX_BEND * 0.6:
		rows *= 2
	# (and, when rows alone can't, narrower strips: a wall right at the camera is much wider than its 6 px strips assume)
	while strips < 1200 and _grid_bend(x, top, bottom, d0, d1, strips, rows) > MAX_BEND * 0.6:
		strips *= 2
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for i in strips + 1:
		var t := float(i) / strips
		var d := lerpf(d0, d1, t)
		for r in rows + 1:
			var f := float(r) / rows
			verts.append(_at(Vector2(x, lerpf(top, bottom, f)), d))
			uvs.append(Vector2(lerpf(ua, ub, t), lerpf(va, vb, f)))
			cols.append(tint)
	var idx := PackedInt32Array()
	for i in strips:
		for r in rows:
			var a := i * (rows + 1) + r
			var b := a + rows + 1
			idx.append_array([a, b, b + 1, a, b + 1, a + 1])
			# Where the middle of this cell lands on the diagonal the two triangles share, against where it really is: the
			# difference is how much a level line of the picture bends here.
			var mid := (verts[a] + verts[b + 1]) * 0.5
			var truth := _at(Vector2(x, lerpf(top, bottom, (r + 0.5) / rows)), lerpf(d0, d1, (i + 0.5) / strips))
			worst_bend = maxf(worst_bend, mid.distance_to(truth))
	grids_drawn += 1
	grid_cells += strips * rows
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# The canvas item keeps only the mesh's RID: the node holds the mesh itself, or it is freed when this returns.
	_wall_meshes.append(mesh)
	draw_mesh(mesh, tex)


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


func _wall_details(w: Dictionary, front_x: float, top: float, d0: float, d1: float, side := 1.0) -> void:
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
			# A row of plexes (each about 0.55 deep), drawn as volumes and not painted on the wall (Julien: the buildings down the
			# cross streets looked flat): each its own shade of brick and its party wall; the windows set into the wall; the cornice
			# jutting out along the top; then, far to near so the nearer ones cover the farther, what juts out toward the street —
			# the iron balconies on their slabs with the shade they throw, the outdoor stair coming down in front, the door's steps.
			var out := -side
			var winter := Season.is_winter()
			var count := maxi(1, int(round(span / 0.55)))
			var bs := span / count
			var tints := [Color(1, 1, 1, 0.07), Color(0, 0, 0, 0.07), Color(1, 0.85, 0.7, 0.07), Color(0, 0, 0, 0.0), Color(0.25, 0.1, 0.05, 0.1)]
			for b in count:
				var b0 := d0 + bs * b
				if b0 > DETAIL:
					break
				_wall_quad(front_x, top, FACADE_Y, b0, b0 + bs, tints[(int(d0 * 97.0) + b * 3) % tints.size()])
				if b > 0:
					draw_line(_at(Vector2(front_x, top), b0), _at(Vector2(front_x, FACADE_Y), b0), Color(0, 0, 0, 0.28), maxf(1.0, 2.5 / (1.0 + b0)))
			for f in floors:
				_windows(front_x, top + 40.0 + f * 150.0, d0, d1, maxi(2, int(span * 5.0)), glass, trim)
			_cornice(front_x, out, top, d0, minf(d1, DETAIL * 1.5), w.color, winter)
			var bi := count - 1
			while bi >= 0:
				var b0 := d0 + bs * bi
				bi -= 1
				if b0 > DETAIL:
					continue
				for f in range(1, floors):
					_balcony(front_x, out, FACADE_Y - 150.0 * f + 8.0, b0 + bs * 0.05, b0 + bs * 0.62, winter)
				_wall_quad(front_x, FACADE_Y - 116.0, FACADE_Y - 22.0, b0 + bs * 0.4, b0 + bs * 0.5, Color("#5E3A26"))
				_wall_quad(front_x, FACADE_Y - 120.0, FACADE_Y - 116.0, b0 + bs * 0.38, b0 + bs * 0.52, trim)
				_steps(front_x, out, b0 + bs * 0.36, b0 + bs * 0.54, winter)
				if floors > 1:
					_outdoor_stair(front_x, out, FACADE_Y - 142.0, b0 + bs * 0.62, b0 + bs * 0.95, winter)


# ── A row of plexes down a vista ─────────────────────────────────
# Julien (2026-11-18): the buildings down the cross streets needed a drastic improvement — the walls were flat fills and the
# balconies sat in front of the windows. Now each building is laid out on ONE floor height: every storey has its floor line,
# two windows and a door; the balcony of an upper storey is ON that floor, in front of its door (the railing hides the bottom of
# the windows, as on a real plex), with no posts under it (Julien); the outdoor stair comes down from the first one.
# Each building has its own brick (red, brown, buff, grey stone), frames and door colour, real courses of brick with their
# staggered joints and a few darker bricks up close, a stone base, stone lintels and sills, and the row a bracketed cornice.

const PLEX_BRICKS := [Color("#A8473A"), Color("#9C5A44"), Color("#B5603F"), Color("#7E4436"), Color("#C29A6A"), Color("#8E8A84"),
	Color("#B86A48"), Color("#94402F")]
const PLEX_FRAMES := [Color("#ECE8E0"), Color("#2B2B2E"), Color("#5E3A26"), Color("#2E5A44"), Color("#E8DCC0")]
const PLEX_DOORS := [Color("#5E3A26"), Color("#2E4E8E"), Color("#8E2A2A"), Color("#2B2B2E"), Color("#3E6A4E")]
const PLEX_BASE := 26.0


func _plex_row(w: Dictionary, front_x: float, top: float, d0: float, d1: float, side: float) -> void:
	var out := -side
	var winter := Season.is_winter()
	var span := d1 - d0
	var count := maxi(1, int(round(span / 0.55)))
	var bs := span / count
	var ground := FACADE_Y - PLEX_BASE
	var floors := maxi(2, int(round((ground - top) / 150.0)))
	var fh := (ground - top) / floors
	var corner: Color = w.color
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d0 * 1000.0) + int(front_x) * 3
	var styles := []
	for b in count:
		var i := absi(int(d0 * 131.0) + b * 7 + int(front_x))
		# The first building is the corner's own (its colour and material read off its front, `StreetScene._wall_look`); the
		# others are plexes of brick of their own colour, now and then a greystone.
		var material: String = str(w.get("material", "brick")) if b == 0 else ("stone" if i % 7 == 3 else "brick")
		var brick: Color = corner
		if b > 0:
			brick = Color("#9C978E").lerp(corner, 0.15) if material == "stone" else corner.lerp(PLEX_BRICKS[i % PLEX_BRICKS.size()], 0.7)
		styles.append({"brick": brick, "material": material, "frame": PLEX_FRAMES[(i / 3) % PLEX_FRAMES.size()],
			"door": PLEX_DOORS[(i / 5) % PLEX_DOORS.size()], "lit": i % 4, "seed": i})
	# ── The walls, far to near: brick, courses, base, openings, then the glancing shade over all of it.
	var b := count - 1
	while b >= 0:
		var b0 := d0 + bs * b
		var b1 := b0 + bs
		var st: Dictionary = styles[b]
		b -= 1
		if b0 > FAR:
			continue
		var brick: Color = st.brick
		_wall_quad(front_x, top, ground, b0, b1, brick)
		if b0 < DETAIL:
			_wall_texture(front_x, top + 18.0, ground, b0, b1, brick, str(st.material), rng)
		# The light: the top of the wall catches the sun, its foot is in the shade of the street.
		_wall_quad(front_x, top, top + (ground - top) * 0.35, b0, b1, Color(1.0, 0.95, 0.85, 0.07))
		_wall_quad(front_x, ground - (ground - top) * 0.25, ground, b0, b1, Color(0, 0, 0, 0.08))
		_wall_quad(front_x, ground, FACADE_Y, b0, b1, Color("#A9A396").lerp(brick, 0.15))
		_wall_quad(front_x, ground, ground + 3.0, b0, b1, Color("#D2CCC0"))
		if b0 < DETAIL:
			for f in floors:
				var floor_y := ground - f * fh
				var wtop := floor_y - fh * 0.8
				var sill := floor_y - fh * 0.2
				var k: int = st.seed + f * 3
				_plex_window(front_x, wtop, sill, b0 + bs * 0.08, b0 + bs * 0.29, st, (f + b) % 4 == st.lit, k)
				_plex_window(front_x, wtop, sill, b0 + bs * 0.66, b0 + bs * 0.87, st, false, k + 1)
				_plex_door(front_x, wtop, floor_y if f > 0 else ground - 4.0, b0 + bs * 0.38, b0 + bs * 0.54, st, f == 0)
		_wall_quad(front_x, top, FACADE_Y, b0, b1, Color(0.1, 0.04, 0.06, 0.16 if side < 0.0 else 0.28))
		if b0 > d0:
			draw_line(_at(Vector2(front_x, top), b0), _at(Vector2(front_x, FACADE_Y), b0), Color(0, 0, 0, 0.3), maxf(1.0, 2.5 / (1.0 + b0)))
	_cornice(front_x, out, top, d0, minf(d1, DETAIL * 1.5), corner, winter)
	# ── What juts out, far to near.
	var bi := count - 1
	while bi >= 0:
		var b0 := d0 + bs * bi
		bi -= 1
		if b0 > DETAIL:
			continue
		for f in range(floors - 1, 0, -1):
			var floor_y := ground - f * fh
			# No posts under it (Julien).
			_balcony(front_x, out, floor_y, b0 + bs * 0.03, b0 + bs * 0.97, winter)
		_front_yard(front_x, out, b0 + bs * 0.03, b0 + bs * 0.33, winter)
		_steps(front_x, out, b0 + bs * 0.36, b0 + bs * 0.56, winter)
		if floors > 1:
			_outdoor_stair(front_x, out, ground - fh, b0 + bs * 0.62, b0 + bs * 0.97, winter)


# The wall's own material: brick courses, the big blocks of a greystone, or the boards of a light cladding with its white
# corner boards.
func _wall_texture(front_x: float, y0: float, y1: float, d0: float, d1: float, col: Color, material: String, rng: RandomNumberGenerator) -> void:
	match material:
		"stone":
			var joint := Color(col.darkened(0.3), 0.5)
			var lines := PackedVector2Array()
			var y := y0
			var row := 0
			while y < y1:
				lines.append_array([_at(Vector2(front_x, y), d0), _at(Vector2(front_x, y), minf(d1, DETAIL))])
				var dd := d0 + (0.04 if row % 2 == 1 else 0.0)
				while dd < minf(d1, 3.0):
					lines.append_array([_at(Vector2(front_x, y), dd), _at(Vector2(front_x, minf(y + 22.0, y1)), dd)])
					dd += 0.08
				y += 22.0
				row += 1
			draw_multiline(lines, joint, 1.0)
			if d0 < 2.0:
				for i in 24:
					var bd := rng.randf_range(d0, minf(d1, 2.0))
					var by := y0 + float(rng.randi_range(0, int((y1 - y0) / 22.0) - 1)) * 22.0
					_wall_quad(front_x, by + 1.0, by + 21.0, bd, bd + 0.07, Color(col.lightened(0.12), 0.5) if rng.randf() < 0.5 else Color(col.darkened(0.12), 0.5))
		"siding":
			var lines := PackedVector2Array()
			var y := y0
			while y < y1:
				lines.append_array([_at(Vector2(front_x, y), d0), _at(Vector2(front_x, y), minf(d1, DETAIL))])
				y += 8.0
			draw_multiline(lines, Color(col.darkened(0.25), 0.45), 1.0)
			for cd: float in [d0, d1 - 0.015]:
				_wall_quad(front_x, y0 - 18.0, y1, cd, cd + 0.015, Color("#F4F2EC"))
		_:
			_brick_courses(front_x, y0, y1, d0, d1, col, rng)


# A corner building's side wall down the cross street: its own brick (or stone, or siding), the light at its top and the
# shade at its foot, its parged base, the coping, and a few windows per floor near the front, as a plex's flank has; never a
# door, a balcony or a stair (those are on its front, on our street).
func _side_wall(w: Dictionary, front_x: float, top: float, d0: float, d1: float, side: float) -> void:
	var col: Color = w.color
	var ground := FACADE_Y - PLEX_BASE
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d0 * 1000.0) + int(front_x) * 5
	_wall_quad(front_x, top, ground, d0, d1, col)
	if d0 < DETAIL:
		_wall_texture(front_x, top + 18.0, ground, d0, d1, col, str(w.get("material", "brick")), rng)
	_wall_quad(front_x, top, top + (ground - top) * 0.35, d0, d1, Color(1.0, 0.95, 0.85, 0.07))
	_wall_quad(front_x, ground - (ground - top) * 0.25, ground, d0, d1, Color(0, 0, 0, 0.08))
	_wall_quad(front_x, ground, FACADE_Y, d0, d1, Color("#A9A396").lerp(col, 0.15))
	_wall_quad(front_x, ground, ground + 3.0, d0, d1, Color("#D2CCC0"))
	var floors := maxi(1, int(round((ground - top) / 150.0)))
	var fh := (ground - top) / floors
	var near := d0 + (d1 - d0) * 0.55
	for f in floors:
		_windows(front_x, top + fh * f + fh * 0.3, d0, near, 2, Color("#6F8DA2"), Color("#ECE8E0"))
	_wall_quad(front_x, top, FACADE_Y, d0, d1, Color(0.1, 0.04, 0.06, 0.18 if side < 0.0 else 0.3))
	_wall_quad(front_x, top - 6.0, top + 2.0, d0, d1, col.lightened(0.2))
	_wall_quad(front_x, top, top + 14.0, d0, d1, col.darkened(0.35))
	draw_line(_at(Vector2(front_x, top), d1), _at(Vector2(front_x, FACADE_Y), d1), col.darkened(0.5), maxf(1.0, 2.5 / (1.0 + d1)))


# The little front yard under the first window: a low iron fence at the sidewalk's edge, shrubs of the season against the
# wall (a mound of snow in winter).
func _front_yard(front_x: float, out: float, da: float, db: float, winter: bool) -> void:
	if da > DETAIL:
		return
	# A shrub's own colours (not the street trees' canopy: in autumn those orange balls read as pumpkins).
	var pair: Array = {"spring": [Color("#4E7E3A"), Color("#7AAE58")], "summer": [Color("#2E5E2E"), Color("#4E8A3E")],
		"autumn": [Color("#5A5A2E"), Color("#8E7A3A")]}.get(Season.current, [Color("#5A5A2E"), Color("#8E7A3A")])
	var d := da + 0.02
	while d < db:
		var at := _at(Vector2(front_x + out * 14.0, FACADE_Y - 6.0), d)
		var r := 12.0 / (1.0 + d)
		if winter:
			# A low mound of snow along the wall (too far off to see, it would only be a degenerate polygon).
			if r < 2.5:
				d += 0.08
				continue
			var mound := PackedVector2Array()
			for k in 12:
				var ang := PI + PI * k / 11.0
				mound.append(at + Vector2(cos(ang) * r * 1.3, sin(ang) * r * 0.55))
			draw_colored_polygon(mound, Color("#F2F5F8"))
		else:
			# A clump of leaves: three lobes in shade, lit tops from the upper left.
			for lobe: Vector2 in [Vector2(-0.55, 0.0), Vector2(0.45, -0.1), Vector2(-0.05, -0.5)]:
				draw_circle(at + lobe * r, r * 0.62, pair[0])
			for lobe: Vector2 in [Vector2(-0.7, -0.15), Vector2(0.3, -0.3), Vector2(-0.2, -0.65)]:
				draw_circle(at + lobe * r, r * 0.32, pair[1])
		d += 0.08
	var iron := Color("#262626")
	var fx := front_x + out * 30.0
	draw_line(_at(Vector2(fx, FACADE_Y - 18.0), da), _at(Vector2(fx, FACADE_Y - 18.0), db), iron, maxf(1.0, 2.0 / (1.0 + da)))
	draw_line(_at(Vector2(front_x, FACADE_Y - 18.0), db), _at(Vector2(fx, FACADE_Y - 18.0), db), iron, maxf(1.0, 2.0 / (1.0 + da)))
	var pd := da
	while pd <= db and pd < 3.0:
		draw_line(_at(Vector2(fx, FACADE_Y - 18.0), pd), _at(Vector2(fx, FACADE_Y), pd), iron, 1.0)
		pd += 0.025


# Brick courses on a wall face: mortar lines, and up close the staggered joints and a few bricks fired darker.
func _brick_courses(front_x: float, y0: float, y1: float, d0: float, d1: float, col: Color, rng: RandomNumberGenerator) -> void:
	var mortar := Color(col.lightened(0.35), 0.45)
	var joint := Color(col.darkened(0.35), 0.4)
	var lines := PackedVector2Array()
	var y := y0
	var row := 0
	var near := minf(d1, 2.2)
	while y < y1:
		lines.append_array([_at(Vector2(front_x, y), d0), _at(Vector2(front_x, y), minf(d1, DETAIL))])
		if d0 < near:
			var dd := d0 + (0.02 if row % 2 == 1 else 0.0)
			while dd < near:
				lines.append_array([_at(Vector2(front_x, y), dd), _at(Vector2(front_x, minf(y + 9.0, y1)), dd)])
				dd += 0.04
		y += 9.0
		row += 1
	draw_multiline(lines, mortar, 1.0)
	if d0 < 1.4:
		for i in 60:
			var bd := rng.randf_range(d0, minf(d1, 1.4))
			var by := y0 + float(rng.randi_range(0, int((y1 - y0) / 9.0) - 1)) * 9.0
			_wall_quad(front_x, by + 1.0, by + 8.0, bd, bd + 0.035, joint if rng.randf() < 0.6 else Color(col.lightened(0.15), 0.5))


# A plex window on a receding wall: a stone lintel, the frame in the building's colour, glass with the sky in it (or lit, or
# curtained), the reveal's shade, the muntins up close, a stone sill.
func _plex_window(front_x: float, top: float, bottom: float, a: float, b: float, st: Dictionary, lit: bool, k := 0) -> void:
	var wd := b - a
	var frame: Color = st.frame
	_wall_quad(front_x, top - 13.0, top - 2.0, a - wd * 0.12, b + wd * 0.12, Color("#D8D2C4"))
	_wall_quad(front_x, top - 3.0, top - 1.0, a - wd * 0.12, b + wd * 0.12, Color(0, 0, 0, 0.18))
	_wall_quad(front_x, top, bottom, a, b, frame)
	var ga := a + wd * 0.1
	var gb := b - wd * 0.1
	var gt := top + 5.0
	var gbm := bottom - 5.0
	if lit:
		_wall_quad(front_x, gt, gbm, ga, gb, Color("#F2D49A"))
	else:
		_wall_quad(front_x, gt, gbm, ga, gb, Color("#6F8DA2"))
		_wall_quad(front_x, gt, gt + (gbm - gt) * 0.4, ga, gb, Color("#A9C3D2"))
		_wall_quad(front_x, gt, gt + (gbm - gt) * 0.12, ga, gb, Color(1, 1, 1, 0.25))
	# Some have their curtains half drawn.
	if k % 3 == 1:
		var curtain := Color("#F2EDE2") if k % 2 == 0 else Color("#E8D2B8")
		_wall_quad(front_x, gt, gbm, ga, ga + (gb - ga) * 0.22, curtain)
		_wall_quad(front_x, gt, gbm, gb - (gb - ga) * 0.22, gb, curtain)
	_wall_quad(front_x, gt, gbm, ga, ga + (gb - ga) * 0.2, Color(0, 0, 0, 0.22))
	if a < 3.0:
		var m := (ga + gb) / 2.0
		draw_line(_at(Vector2(front_x, gt), m), _at(Vector2(front_x, gbm), m), frame, maxf(1.0, 2.5 / (1.0 + m)))
		draw_line(_at(Vector2(front_x, gt + (gbm - gt) * 0.45), ga), _at(Vector2(front_x, gt + (gbm - gt) * 0.45), gb), frame, maxf(1.0, 2.5 / (1.0 + m)))
	_wall_quad(front_x, bottom, bottom + 6.0, a - wd * 0.1, b + wd * 0.1, Color("#E0DACE"))
	_wall_quad(front_x, bottom + 6.0, bottom + 9.0, a - wd * 0.08, b + wd * 0.08, Color(0, 0, 0, 0.15))
	# Now and then a window box: flowers in the warm seasons, a cap of snow in winter, bare soil in autumn's end.
	if k % 5 == 2 and a < DETAIL:
		_wall_quad(front_x, bottom - 12.0, bottom, a - wd * 0.04, b + wd * 0.04, Color("#6E4A30"))
		var bloom: Color = {"winter": Color("#F4F7FA"), "spring": Color("#F28CB0"), "summer": Color("#E8503A"), "autumn": Color("#E8A23A")}.get(Season.current, Color("#E8A23A"))
		_wall_quad(front_x, bottom - 18.0, bottom - 12.0, a, b, bloom)


# A plex door: the street door at the foot (panelled, a transom over it), or an upper flat's door out onto its balcony (glass
# in its top half), under a stone lintel.
func _plex_door(front_x: float, top: float, bottom: float, a: float, b: float, st: Dictionary, street: bool) -> void:
	var wd := b - a
	_wall_quad(front_x, top - 13.0, top - 2.0, a - wd * 0.1, b + wd * 0.1, Color("#D8D2C4"))
	_wall_quad(front_x, top, bottom, a, b, st.frame)
	var door: Color = st.door
	_wall_quad(front_x, top + 4.0, bottom, a + wd * 0.1, b - wd * 0.1, door)
	if street:
		_wall_quad(front_x, top + 4.0, top + 22.0, a + wd * 0.1, b - wd * 0.1, Color("#8FA8B8"))
		_wall_quad(front_x, top + 26.0, bottom - 6.0, a + wd * 0.18, b - wd * 0.18, door.darkened(0.2))
	else:
		_wall_quad(front_x, top + 8.0, top + (bottom - top) * 0.5, a + wd * 0.2, b - wd * 0.2, Color("#8FA8B8"))
	_wall_quad(front_x, top + 4.0, bottom, a + wd * 0.1, a + wd * 0.22, Color(0, 0, 0, 0.2))


# A flat plane jutting out from the wall at height y, from the wall line to `out_x`, between depths da and db (a balcony's slab,
# a step's tread, a cornice's underside): above the horizon we see its underside, below it its top.
func _ledge(front_x: float, out_x: float, y: float, da: float, db: float, col: Color) -> void:
	var pts := PackedVector2Array([_at(Vector2(front_x, y), da), _at(Vector2(out_x, y), da), _at(Vector2(out_x, y), db), _at(Vector2(front_x, y), db)])
	if absf((pts[2] - pts[0]).cross(pts[3] - pts[1])) < 0.01:
		return
	draw_primitive(pts, PackedColorArray([col, col, col, col]), PackedVector2Array())


# The near end of something jutting out (square to the view at depth d), from the wall line to `out_x`, between heights.
func _end_face(front_x: float, out_x: float, y0: float, y1: float, d: float, col: Color) -> void:
	var pts := PackedVector2Array([_at(Vector2(front_x, y0), d), _at(Vector2(out_x, y0), d), _at(Vector2(out_x, y1), d), _at(Vector2(front_x, y1), d)])
	if absf((pts[2] - pts[0]).cross(pts[3] - pts[1])) < 0.01:
		return
	draw_primitive(pts, PackedColorArray([col, col, col, col]), PackedVector2Array())


# The cornice along the top of a row: it juts out, its underside in shade, its face, a lit edge (snow on it in winter).
func _cornice(front_x: float, out: float, top: float, da: float, db: float, col: Color, winter: bool) -> void:
	var ox := front_x + out * 16.0
	_ledge(front_x, ox, top + 16.0, da, db, col.darkened(0.55))
	_wall_quad(ox, top - 4.0, top + 16.0, da, db, col.darkened(0.15))
	_wall_quad(ox, top + 10.0, top + 16.0, da, db, col.darkened(0.4))
	_wall_quad(ox, top - 6.0, top - 2.0, da, db, Color("#F4F7FA") if winter else col.lightened(0.3))
	_end_face(front_x, ox, top - 4.0, top + 16.0, da, col.lightened(0.05))
	# Its brackets under the overhang, close enough to see.
	var bd := da + 0.03
	while bd < minf(db, DETAIL):
		_end_face(front_x, front_x + out * 12.0, top + 16.0, top + 30.0, bd, col.darkened(0.45))
		bd += 0.06


# An iron balcony on its slab, jutting out from the wall at floor height y between depths da and db: the shade it throws on the
# wall under it, the slab (its underside or top, its front edge, its near end), the railing's bars and rail, snow in winter.
func _balcony(front_x: float, out: float, y: float, da: float, db: float, winter: bool) -> void:
	var ox := front_x + out * 46.0
	var iron := Color("#1F1F1F")
	var slab := Color("#D8D4CC")
	var w := maxf(1.0, 1.6 / (1.0 + da))
	_wall_quad(front_x, y + 8.0, y + 44.0, da + 0.02, db + 0.03, Color(0, 0, 0, 0.14))
	if y < HORIZON_Y:
		# Seen from below: the underside in shade, its joists across it, darker against the wall.
		_ledge(front_x, ox, y + 8.0, da, db, slab.darkened(0.5))
		_ledge(front_x, lerpf(front_x, ox, 0.3), y + 8.0, da, db, Color(0, 0, 0, 0.18))
		var jd := da + 0.04
		while jd < db and jd < DETAIL:
			draw_line(_at(Vector2(front_x, y + 8.0), jd), _at(Vector2(ox, y + 8.0), jd), slab.darkened(0.65), maxf(1.0, 2.0 / (1.0 + jd)))
			jd += 0.07
	else:
		_ledge(front_x, ox, y, da, db, Color("#F4F7FA") if winter else slab)
	_wall_quad(ox, y, y + 8.0, da, db, slab.darkened(0.08))
	_end_face(front_x, ox, y, y + 8.0, da, slab.lightened(0.05))
	if winter:
		_wall_quad(ox, y - 3.0, y, da, db, Color("#F4F7FA"))
	# The railing: a top rail along the front and down the near end, bars between.
	draw_line(_at(Vector2(ox, y - 30.0), da), _at(Vector2(ox, y - 30.0), db), iron, w)
	draw_line(_at(Vector2(front_x, y - 30.0), da), _at(Vector2(ox, y - 30.0), da), iron, w)
	var bars := clampi(int((db - da) * 40.0), 3, 14)
	for k in bars + 1:
		var bd := lerpf(da, db, float(k) / bars)
		draw_line(_at(Vector2(ox, y - 30.0), bd), _at(Vector2(ox, y), bd), iron, maxf(1.0, w * 0.6))
	for k in 4:
		var bx := lerpf(front_x, ox, (k + 0.5) / 4.0)
		draw_line(_at(Vector2(bx, y - 30.0), da), _at(Vector2(bx, y), da), iron, maxf(1.0, w * 0.6))


# The outdoor stair from the first balcony (y) down to the sidewalk, in front of the wall: its treads, its stringer, its
# handrail and posts, from depth da at the top to db at the foot.
func _outdoor_stair(front_x: float, out: float, y: float, da: float, db: float, winter: bool) -> void:
	var iron := Color("#1F1F1F")
	var tread := Color("#F4F7FA") if winter else Color("#B9B2A6")
	var xi := front_x + out * 18.0
	var xo := front_x + out * 46.0
	var n := 10
	for k in n:
		var t := (k + 0.5) / n
		var ty := lerpf(y, FACADE_Y, t)
		var td := lerpf(da, db, t)
		draw_line(_at(Vector2(xi, ty), td), _at(Vector2(xo, ty), td), tread, maxf(1.0, 2.6 / (1.0 + td)))
	draw_line(_at(Vector2(xo, y), da), _at(Vector2(xo, FACADE_Y), db), iron, maxf(1.0, 2.4 / (1.0 + da)))
	draw_line(_at(Vector2(xo, y - 30.0), da), _at(Vector2(xo, FACADE_Y - 30.0), db), iron, maxf(1.0, 1.6 / (1.0 + da)))
	for k in 5:
		var t := float(k) / 4.0
		var py := lerpf(y, FACADE_Y, t)
		var pd := lerpf(da, db, t)
		draw_line(_at(Vector2(xo, py - 30.0), pd), _at(Vector2(xo, py), pd), iron, 1.0)


# The door's steps: two treads jutting out, their fronts, snow on them in winter.
func _steps(front_x: float, out: float, da: float, db: float, winter: bool) -> void:
	var stone := Color("#A8A196")
	for k in 2:
		var ox := front_x + out * (14.0 + k * 12.0)
		var y := FACADE_Y - 22.0 + k * 11.0
		_ledge(front_x, ox, y, da, db, Color("#F4F7FA") if winter else stone.lightened(0.15))
		_wall_quad(ox, y, y + 11.0, da, db, stone.darkened(0.1))
		_end_face(front_x, ox, y, y + 11.0, da, stone)


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
		# The glass: most reflect the sky, some are lit warm, some have their curtains drawn.
		var pick := (int(d0 * 131.0) + i * 7 + int(y)) % 9
		var pane := Color("#F2D49A") if pick == 0 else (Color("#E8E2D6") if pick == 1 else glass)
		_wall_quad(front_x, y, y + 90.0, a, b, pane)
		_wall_quad(front_x, y, y + 30.0, a, b, Color(1, 1, 1, 0.12))
		# Set into the wall: the reveal's shade along its near side and under its head.
		_wall_quad(front_x, y, y + 90.0, a, a + (b - a) * 0.18, Color(0, 0, 0, 0.22))
		_wall_quad(front_x, y, y + 6.0, a, b, Color(0, 0, 0, 0.18))
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
	# Its pit, cut into the sidewalk along the curb: earth (snow in winter) inside a stone edge.
	var along := PIT_ALONG * (1.0 + d)
	var earth := (Color("#E6ECF0") if Season.is_winter() else Color("#5A4232")).lerp(HAZE, clampf(d / FAR, 0.0, 0.6))
	var edge := Color("#A8A397").lerp(HAZE, clampf(d / FAR, 0.0, 0.6))
	var inner := Vector2(base.x - PIT_HALF, FACADE_Y)
	var outer := Vector2(base.x + PIT_HALF, FACADE_Y)
	_quad(inner, outer, d - along, d + along, edge)
	_quad(inner + Vector2(5, 0), outer - Vector2(5, 0), d - along * 0.8, d + along * 0.8, earth)
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
	# The other crosswalk of the corner, over our own street: it leaves the corner toward us. It starts at a dropped curb
	# with its warning dots, like the ramps of the crosswalk above; its edges run to the vanishing point like the cross
	# street's, so it widens as it comes nearer; and its bars lie along the curb, each thicker and further from the last
	# as the road comes toward us, until it runs off the bottom of the view.
	for own_side in own_sides:
		var e := _own_ends(own_side)
		var ramp_top := OWN_CROSSWALK_TOP - 12.0
		draw_colored_polygon(PackedVector2Array([Vector2(e.x + 6.0, ramp_top), Vector2(e.y - 6.0, ramp_top),
			Vector2(e.y, OWN_CROSSWALK_TOP + 1.0), Vector2(e.x, OWN_CROSSWALK_TOP + 1.0)]), Color("#BDB7AD"))
		draw_line(Vector2(e.x + 6.0, ramp_top), Vector2(e.y - 6.0, ramp_top), Color("#A39D93"), 1.5)
		var dots := int((e.y - e.x - 24.0) / 7.0)
		for row in 2:
			for i in dots:
				draw_circle(Vector2(e.x + 14.0 + i * 7.0 + row * 3.5, ramp_top + 4.0 + row * 4.5), 1.4, Color("#8E5A4A"))
		var by := OWN_CROSSWALK_TOP + 3.0
		var thick := 6.0
		while by < VIEW_BOTTOM:
			var by1 := minf(by + thick, VIEW_BOTTOM)
			draw_colored_polygon(PackedVector2Array([Vector2(_own_edge(e.x, by), by), Vector2(_own_edge(e.y, by), by),
				Vector2(_own_edge(e.y, by1), by1), Vector2(_own_edge(e.x, by1), by1)]), bar)
			# Worn by the tyres: two greyer patches across each bar, where the wheels of the cars go.
			for wear in [0.3, 0.72]:
				var wx := lerpf(_own_edge(e.x, by), _own_edge(e.y, by), wear)
				draw_rect(Rect2(wx - 5.0, by, 10.0, by1 - by), Color(0.42, 0.42, 0.44, 0.35))
			by = by1 + thick * 0.85
			thick *= 1.35
	# Leaves blown over the intersection, and above all the street's line of them along the gutter, which has to carry on
	# across the gap instead of stopping dead at the corner: thinner in the middle, where the cars sweep it.
	for i in 22:
		var y := _rng.randf_range(y0 + 4.0, y1 - 4.0)
		var x := _rng.randf_range(_fan(l, y), _fan(r, y))
		draw_set_transform(Vector2(x, y), _rng.randf_range(0.0, PI), Vector2(1.0, 0.5))
		var size := _rng.randf_range(3.0, 5.0)
		var lc: Color = _litter[_rng.randi_range(0, 4) % _litter.size()]
		if float(i % 10) / 10.0 < Season.litter_amount():
			draw_circle(Vector2.ZERO, size, lc)
	var gutter := int((r - l) / 4.0)
	for i in gutter:
		var t := (i + 0.5) / float(gutter)
		var y := _rng.randf_range(Street.ROAD - 8.0, Street.ROAD + 8.0)
		var x := lerpf(_fan(l, y), _fan(r, y), t)
		var keep := lerpf(1.0, 0.35, sin(t * PI))
		var size := _rng.randf_range(3.0, 5.5)
		var lc: Color = _litter[_rng.randi_range(0, 4) % _litter.size()]
		if _rng.randf() > keep or float((i * 7919) % 1000) / 1000.0 >= Season.litter_amount():
			continue
		draw_set_transform(Vector2(x + _rng.randf_range(-3.0, 3.0), y), _rng.randf_range(0.0, PI), Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, size, lc)
		draw_line(Vector2(-4, 0), Vector2(4, 0), lc.darkened(0.3), 0.8)
	draw_set_transform(Vector2.ZERO)


# ── Where a back lane comes out ─────────────────────────────────

# The street coming toward us past the lane's mouth: its two sidewalks and the road, fanning out to the bottom of the view,
# slab joints across the sidewalks (depths below 0: in front of the facade line), the curb dropped where the lane meets it.
func _draw_mouth() -> void:
	var y0 := SIDEWALK_TOP
	var y1 := VIEW_BOTTOM
	var l := x0 + sidewalk
	var r := x1 - sidewalk
	var walk := Color("#E9EEF2") if Season.is_winter() else CONCRETE
	var band := func(a: float, b: float, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(_fan(a, y0), y0), Vector2(_fan(b, y0), y0), Vector2(_fan(b, y1), y1), Vector2(_fan(a, y1), y1)]), col)
	band.call(x0, l, walk)
	band.call(r, x1, walk)
	band.call(l, r, ASPHALT)
	# The curbs, and on the lane's side the dropped curb the lane's traffic drives over.
	var dropped := r if lane_side > 0.0 else l
	var kerb := l if lane_side > 0.0 else r
	draw_line(Vector2(_fan(kerb, y0), y0), Vector2(_fan(kerb, y1), y1), CURB, 3.0)
	band.call(dropped, dropped + lane_side * 22.0, Color("#BDB7AD"))
	draw_line(Vector2(_fan(dropped, y0), y0), Vector2(_fan(dropped, y1), y1), Color("#A8A397"), 2.0)
	# The seam where the lane's concrete meets the sidewalk.
	var edge := x1 if lane_side > 0.0 else x0
	draw_line(Vector2(_fan(edge, y0), y0), Vector2(_fan(edge, y1), y1), walk.darkened(0.28), 2.0)
	# Slab joints, closer together with distance.
	var d := 0.0
	var nearest := (FACADE_Y - HORIZON_Y) / (y1 - HORIZON_Y) - 1.0
	while d > nearest:
		var thick := 1.6 / (1.0 + d)
		for side in [[x0, l], [r, x1]]:
			draw_line(_at(Vector2(side[0], FACADE_Y), d), _at(Vector2(side[1], FACADE_Y), d), walk.darkened(0.16), thick)
		d -= 0.07
	# Faded centre line, as down the vista.
	var vp := _vp()
	draw_line(_at(Vector2(vp.x, FACADE_Y), -0.05), _at(Vector2(vp.x, FACADE_Y), -0.2), Color(0.95, 0.85, 0.4, 0.35), 3.0)
	draw_line(_at(Vector2(vp.x, FACADE_Y), -0.3), _at(Vector2(vp.x, FACADE_Y), -0.42), Color(0.95, 0.85, 0.4, 0.35), 4.0)
	# Leaves in the gutters and blown onto the road.
	for i in 26:
		var y := _rng.randf_range(y0 + 4.0, y1 - 4.0)
		var gutter := _rng.randf() < 0.6
		var x := _fan((l if i % 2 == 0 else r) + _rng.randf_range(-6.0, 6.0), y) if gutter else _rng.randf_range(_fan(l, y), _fan(r, y))
		draw_set_transform(Vector2(x, y), _rng.randf_range(0.0, PI), Vector2(1.0, 0.5))
		var size := _rng.randf_range(3.0, 5.5)
		var lc: Color = _litter[_rng.randi_range(0, 4) % _litter.size()]
		if float(i % 10) / 10.0 < Season.litter_amount():
			draw_circle(Vector2.ZERO, size, lc)
	draw_set_transform(Vector2.ZERO)


# ── Signs ───────────────────────────────────────────────────────

const POST_TOP := 232.0
const POST_FOOT := 652.0
const SIGN_INK := Color("#1A1A1A")
const SCHOOL_GREEN := Color("#C9E23A")
static var _bold: FontVariation


func _draw_signs() -> void:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	# A name post at both corners of the intersection; the stop or school-zone sign on `sign_side`'s, the pedestrian
	# crossing sign on the other.
	for side in [-1.0, 1.0]:
		# At the corner of the sidewalk, by the curb, clear of the shop signs on the facades.
		var corner := x0 + sidewalk - 22.0 if side < 0.0 else x1 - sidewalk + 22.0
		var px := _fan(corner, 650.0)
		_post(px)
		if side == sign_side:
			_traffic_sign(px)
		else:
			_crossing_sign(Vector2(px, 440))
		_name_plates(Vector2(px, POST_TOP), side)


# A round galvanised post: lit on the left, a cap, a collar where it goes into the sidewalk, a few stickers.
func _post(px: float) -> void:
	var r := Rect2(px - 3.5, POST_TOP, 7, POST_FOOT - POST_TOP)
	draw_rect(r, Color("#7D8389"))
	draw_rect(Rect2(r.position.x + 0.8, r.position.y, 1.8, r.size.y), Color("#BFC5CB"))
	draw_rect(Rect2(r.end.x - 1.8, r.position.y, 1.8, r.size.y), Color("#555A5F"))
	draw_rect(Rect2(px - 4.5, POST_TOP - 3, 9, 4), Color("#5E6368"))
	draw_rect(Rect2(px - 5.5, POST_FOOT - 10, 11, 10), Color("#666B70"))
	draw_rect(Rect2(px - 5.5, POST_FOOT - 10, 3, 10), Color("#9AA0A6"))
	draw_rect(Rect2(px - 3.5, POST_FOOT - 26, 7, 16), Color("#8A6A4A", 0.35))
	draw_rect(Rect2(px - 3.5, 552, 7, 9), Color("#F2EFE6"))
	draw_rect(Rect2(px - 3.5, 554, 7, 2), Color("#D23B3B"))


# Montreal-style blue street plates: the street we're on faces us, flat; the cross street's plate is turned to run
# along that street, so it slants toward the vanishing point like the street itself.
func _name_plates(top: Vector2, side: float) -> void:
	# The slanted plate on top, centred on the post; it tilts by at most ~30 px each way, so the flat one goes
	# well below it.
	var e := (_vp() - top).normalized()
	if e.x < 0.0:
		e = -e
	var f := 0.72
	_clamp(Vector2(top.x, top.y + 62))
	_clamp(Vector2(top.x, top.y + 94))
	_plate(Rect2(top.x - 80, top.y + 64, 160, 28), along_name, true)
	var origin := top + Vector2(0, 2) - e * 80.0 * f
	draw_set_transform_matrix(Transform2D(e * f, Vector2(0, 1), origin))
	_plate(Rect2(0, 0, 160, 28), street_name, side > 0.0)
	draw_set_transform(Vector2.ZERO)
	_clamp(top + Vector2(0, 1))


func _clamp(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-5, -2.5), Vector2(10, 5)), Color("#5E6368"))
	draw_rect(Rect2(at + Vector2(-5, -2.5), Vector2(10, 1.5)), Color("#A5ABB1"))
	draw_circle(at, 1.2, Color("#3A3D42"))


# One plate: a rounded white-rimmed blue panel with an edge showing its thickness, a faint sheen, the generic ("Rue",
# "Avenue") smaller than the name, the ordinal's "e" raised. `lit`: the side facing the sun gets the sheen.
func _plate(r: Rect2, text: String, lit: bool) -> void:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(5)
	box.anti_aliasing = true
	box.bg_color = Color("#0E2A52")
	draw_style_box(box, Rect2(r.position + Vector2(1.2, 2.0), r.size))
	box.bg_color = Color("#F4F6F8")
	draw_style_box(box, r)
	box.set_corner_radius_all(3)
	box.bg_color = Color("#1D4F91")
	draw_style_box(box, r.grow(-2.6))
	box.bg_color = Color(1, 1, 1, 0.1 if lit else 0.05)
	draw_style_box(box, Rect2(r.position + Vector2(2.6, 2.6), Vector2(r.size.x - 5.2, r.size.y * 0.42)))
	# The words, measured first to centre them.
	var parts: Array = []
	var words := text.split(" ")
	for word in words:
		if word in ["Rue", "Avenue", "Boulevard", "Ruelle"]:
			parts.append([word, 11 if word == words[0] and words.size() > 1 else 15, 0.0])
		elif word.length() >= 2 and word.ends_with("e") and word.left(-1).is_valid_int():
			parts.append([word.left(-1), 17, 0.0])
			parts.append(["e", 10, -6.0])
		else:
			parts.append([word, 17, 0.0])
	var width := 0.0
	for i in parts.size():
		width += _bold.get_string_size(parts[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, parts[i][1]).x
		if i < parts.size() - 1 and parts[i + 1][0] != "e":
			width += 4.0
	var x := r.position.x + (r.size.x - width) / 2.0
	var base := r.position.y + r.size.y / 2.0 + 6.0
	for i in parts.size():
		var word: String = parts[i][0]
		var size: int = parts[i][1]
		var raise: float = parts[i][2]
		draw_string(_bold, Vector2(x, base + raise), word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)
		x += _bold.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if i < parts.size() - 1 and parts[i + 1][0] != "e":
			x += 4.0


func _traffic_sign(px: float) -> void:
	if school:
		_school_sign(Vector2(px, 420))
	else:
		_stop_sign(Vector2(px, 432))


func _octagon(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(c + Vector2.from_angle(TAU * (i + 0.5) / 8.0) * r)
	return pts


# Québec's ARRÊT: a red octagon with a white rim, its edge showing, a sheen on the sunny side, two bolts.
func _stop_sign(c: Vector2) -> void:
	draw_colored_polygon(_octagon(c + Vector2(1.4, 2.0), 33.0), Color("#5A0E12"))
	draw_colored_polygon(_octagon(c, 33.0), Color("#F7F7F5"))
	draw_colored_polygon(_octagon(c, 29.5), Color("#C8202A"))
	var sheen := _octagon(c, 29.5)
	var half := PackedVector2Array([sheen[3], sheen[4], sheen[5], c])
	draw_colored_polygon(half, Color(1, 1, 1, 0.1))
	var oct := _octagon(c, 31.3)
	oct.append(oct[0])
	draw_polyline(oct, Color(0, 0, 0, 0.12), 0.8, true)
	var w := _bold.get_string_size("ARRÊT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(_bold, c + Vector2(-w / 2.0, 6), "ARRÊT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	for dy in [-24.0, 24.0]:
		draw_circle(c + Vector2(0, dy), 1.6, Color("#B9BEC4"))


# The school zone: the fluorescent yellow-green pentagon with two children walking, and the 30 km/h limit under it.
func _school_sign(c: Vector2) -> void:
	var penta := PackedVector2Array([c + Vector2(0, -36), c + Vector2(32, -9), c + Vector2(32, 32), c + Vector2(-32, 32), c + Vector2(-32, -9)])
	var back := PackedVector2Array()
	for p in penta:
		back.append(p + Vector2(1.4, 2.0))
	draw_colored_polygon(back, Color("#3A4A0A"))
	draw_colored_polygon(penta, SCHOOL_GREEN)
	var rim := PackedVector2Array()
	for p in penta:
		rim.append(c + (p - c) * 0.9 + Vector2(0, 1))
	rim.append(rim[0])
	draw_polyline(rim, SIGN_INK, 2.0, true)
	_walker(c + Vector2(-9, 18), 0.82, 1.0)
	_walker(c + Vector2(10, 20), 0.66, 1.0)
	draw_line(c + Vector2(-24, 24), c + Vector2(24, 24), SIGN_INK, 1.6)
	# The speed limit: a white panel, the number in a red ring.
	var r := Rect2(c.x - 22, 458, 44, 52)
	draw_rect(Rect2(r.position + Vector2(1.4, 2), r.size), Color("#2A2A2A"))
	draw_rect(r, Color("#F7F7F5"))
	draw_rect(r.grow(-2.5), SIGN_INK, false, 1.2)
	var o := Vector2(c.x, 478)
	draw_arc(o, 15.0, 0, TAU, 28, Color("#C8202A"), 4.0, true)
	var w := _bold.get_string_size("30", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(_bold, o + Vector2(-w / 2.0, 5.5), "30", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, SIGN_INK)
	w = ThemeDB.fallback_font.get_string_size("km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(ThemeDB.fallback_font, Vector2(c.x - w / 2.0, 505), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, SIGN_INK)


# The pedestrian crossing: a fluorescent yellow-green square, a black rim, someone walking across the stripes.
func _crossing_sign(c: Vector2) -> void:
	var r := Rect2(c - Vector2(27, 27), Vector2(54, 54))
	draw_rect(Rect2(r.position + Vector2(1.4, 2), r.size), Color("#3A4A0A"))
	draw_rect(r, SCHOOL_GREEN)
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.4)), Color(1, 1, 1, 0.1))
	draw_rect(r.grow(-3.0), SIGN_INK, false, 1.8)
	for k in 4:
		draw_rect(Rect2(c + Vector2(-19 + k * 10.5, 15), Vector2(6, 4)), SIGN_INK)
	_walker(c + Vector2(0, 12), 1.0, 1.0)
	for dy in [-22.0, 22.0]:
		draw_circle(c + Vector2(0, dy), 1.3, Color("#8E9A40"))


# A pictogram walker (feet at `foot`), striding toward `dir`.
func _walker(foot: Vector2, k: float, dir: float) -> void:
	var hip := foot + Vector2(0, -14) * k
	var neck := hip + Vector2(2.5 * dir, -13) * k
	draw_circle(neck + Vector2(1.0 * dir, -4.2) * k, 4.0 * k, SIGN_INK)
	draw_line(hip, neck, SIGN_INK, 4.6 * k, true)
	draw_line(hip, hip + Vector2(6.5 * dir, 7.5) * k, SIGN_INK, 3.6 * k, true)
	draw_line(hip + Vector2(6.5 * dir, 7.5) * k, foot + Vector2(8 * dir, 0), SIGN_INK, 3.2 * k, true)
	draw_line(hip, hip + Vector2(-4 * dir, 8) * k, SIGN_INK, 3.6 * k, true)
	draw_line(hip + Vector2(-4 * dir, 8) * k, foot + Vector2(-8 * dir, -1) * k, SIGN_INK, 3.2 * k, true)
	var shoulder := neck + Vector2(-0.6 * dir, 2.5) * k
	draw_line(shoulder, shoulder + Vector2(5.5 * dir, 8) * k, SIGN_INK, 2.8 * k, true)
	draw_line(shoulder, shoulder + Vector2(-5 * dir, 7.5) * k, SIGN_INK, 2.8 * k, true)
