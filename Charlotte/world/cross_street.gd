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
	_walls(left_walls, x0, -1.0)
	_walls(right_walls, x1, 1.0)
	_haze_band(3.0, 9.0, 0.0, 0.35)
	_haze_band(9.0, FAR, 0.35, 0.6)
	# Street trees on both sidewalks, far to near.
	for d in [14.0, 9.5, 6.6, 4.6, 3.2, 2.2, 1.3]:
		for side in [-1.0, 1.0]:
			var tx := x0 + sidewalk * 0.35 if side < 0.0 else x1 - sidewalk * 0.35
			_tree(Vector2(tx, FACADE_Y), d + (0.3 if side > 0.0 else 0.0))


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
	var d0 := 0.0
	for w in walls:
		var d1: float = w.to
		match w.kind:
			"gap":
				# A back lane: autumn trees and a glimpse of fences.
				_wall_quad(front_x, FACADE_Y - 70.0, FACADE_Y, d0, d1, Color("#A07850"))
				for t in 3:
					var d := lerpf(d0, d1, (t + 0.5) / 3.0)
					var c := _at(Vector2(front_x + side * 40.0, FACADE_Y - 190.0), d)
					draw_circle(c, 70.0 / (1.0 + d), _foliage[t % _foliage.size()])
			_:
				var top: float = w.top
				var col: Color = w.color
				_wall_quad(front_x, top, FACADE_Y, d0, d1, col)
				# Seen at a glancing angle: a darker shade, the further from the sun the darker.
				_wall_quad(front_x, top, FACADE_Y, d0, d1, Color(0.1, 0.04, 0.06, 0.18 if side < 0.0 else 0.3))
				_wall_quad(front_x, top, top + 14.0, d0, d1, col.darkened(0.35))
				_wall_details(w, front_x, top, d0, d1)
		d0 = d1


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
		_wall_quad(front_x, y - 4.0, y + 94.0, a - step * 0.04, b + step * 0.04, trim)
		_wall_quad(front_x, y, y + 90.0, a, b, glass)


func _tree(base: Vector2, d: float) -> void:
	var s := 1.0 / (1.0 + d)
	var foot := _at(base, d)
	var crown := _at(base + Vector2(0, -250), d)
	draw_line(foot, crown, Color("#5E4A3C"), maxf(1.5, 14.0 * s))
	if Season.is_winter():
		# Bare branches with a line of snow along each.
		for i in 6:
			var a := -PI / 2.0 + (i - 2.5) * 0.45
			var tip := crown + Vector2.from_angle(a) * 90.0 * s
			draw_line(crown + Vector2(0, 30) * s, tip, Color("#5E4A3C"), maxf(1.0, 6.0 * s))
			draw_line(crown + Vector2(0, 26) * s, tip + Vector2(0, -3) * s, Color("#F4F7FA"), maxf(1.0, 3.0 * s))
		return
	for i in 7:
		var a := TAU * i / 7.0 + d
		var off := Vector2(cos(a) * 70.0, sin(a) * 50.0) * s
		draw_circle(crown + off, 62.0 * s, _foliage[(i + int(d * 3.0)) % _foliage.size()].darkened(0.08 * float(i % 2)))
	draw_circle(crown + Vector2(-22, -26) * s, 40.0 * s, _foliage[2].lightened(0.15))


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
