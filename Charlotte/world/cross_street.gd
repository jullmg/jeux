class_name CrossStreet
extends Node2D
## A cross street at a corner of 6e Avenue, seen down its length in one-point perspective.
## Three parts, each a separate node so they land in the right place in the draw order:
##  - VISTA (added before the houses): the street receding behind the facade line, its sidewalks,
##    the walls of the buildings along it, street trees, distant houses.
##  - GROUND (added after Street): the asphalt cutting through the 6e sidewalk, curb ramps, crosswalk.
##  - SIGNS (added with the props): poles and signs at the corner.
## Every point is drawn as its projection at the facade line (y FACADE_Y) shrunk toward the vanishing
## point by 1 / (1 + depth).

enum Part { VISTA, GROUND, SIGNS }

const FACADE_Y := 592.0
const HORIZON_Y := 452.0
const SIDEWALK_TOP := 590.0
const ROAD_BOTTOM := 676.0
const FAR := 7.0
const ASPHALT := Color("#5A5956")
const CONCRETE := Color("#CFCAC0")
const CURB := Color("#E2DDD4")
const LEAVES := [Color("#D9682B"), Color("#B5442E"), Color("#E3A33A"), Color("#C9562E"), Color("#8E3A24")]

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
## Plate on the corner sign.
var street_name := ""
## Which corner (left or right edge of the gap) the signs stand on.
var sign_side := 1.0

var _rng := RandomNumberGenerator.new()


static func make(which: Part, from: CrossStreet) -> CrossStreet:
	var cs := CrossStreet.new()
	cs.part = which
	for prop in ["x0", "x1", "sidewalk", "school", "left_walls", "right_walls", "street_name", "sign_side"]:
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
	var far_y := HORIZON_Y + (FACADE_Y - HORIZON_Y) / (1.0 + FAR)
	# Distant houses closing the view, then the street and its sidewalks.
	var fl := _at(Vector2(x0, FACADE_Y), FAR)
	var fr := _at(Vector2(x1, FACADE_Y), FAR)
	draw_rect(Rect2(fl.x - 4, far_y - 40, fr.x - fl.x + 8, 40), Color("#A86A52"))
	for i in 5:
		draw_rect(Rect2(lerpf(fl.x, fr.x, (i + 0.25) / 5.0), far_y - 32, 4, 6), Color("#5E7486"))
		draw_rect(Rect2(lerpf(fl.x, fr.x, (i + 0.25) / 5.0), far_y - 18, 4, 6), Color("#5E7486"))
	_quad(Vector2(x0, FACADE_Y), Vector2(x1, FACADE_Y), 0.0, FAR, CONCRETE)
	_quad(Vector2(x0 + sidewalk, FACADE_Y), Vector2(x1 - sidewalk, FACADE_Y), 0.0, FAR, ASPHALT)
	for side in [x0 + sidewalk, x1 - sidewalk]:
		draw_line(_at(Vector2(side, FACADE_Y), 0.0), _at(Vector2(side, FACADE_Y), FAR), CURB, 2.0)
	# Faded centre line, and leaves along the gutters.
	for i in 12:
		var d := i * 0.55
		draw_line(_at(Vector2(vp.x, FACADE_Y), d), _at(Vector2(vp.x, FACADE_Y), d + 0.25), Color(0.95, 0.85, 0.4, 0.35), 2.0 / (1.0 + d))
	for i in 60:
		var d := pow(_rng.randf(), 2.0) * FAR
		var gx: float = [x0 + sidewalk + 6.0, x1 - sidewalk - 6.0][i % 2] + _rng.randf_range(-12, 12)
		draw_circle(_at(Vector2(gx, FACADE_Y), d), 4.0 / (1.0 + d), LEAVES[_rng.randi_range(0, LEAVES.size() - 1)])
	_walls(left_walls, x0, -1.0)
	_walls(right_walls, x1, 1.0)
	# Street trees on both sidewalks, far to near.
	for d in [5.0, 3.4, 2.2, 1.3]:
		for side in [-1.0, 1.0]:
			var tx := x0 + sidewalk * 0.35 if side < 0.0 else x1 - sidewalk * 0.35
			_tree(Vector2(tx, FACADE_Y), d + (0.3 if side > 0.0 else 0.0))


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
					draw_circle(c, 70.0 / (1.0 + d), LEAVES[t % LEAVES.size()])
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
		var a := d0 + step * (i + 0.25)
		var b := d0 + step * (i + 0.75)
		_wall_quad(front_x, y - 4.0, y + 94.0, a - step * 0.04, b + step * 0.04, trim)
		_wall_quad(front_x, y, y + 90.0, a, b, glass)


func _tree(base: Vector2, d: float) -> void:
	var s := 1.0 / (1.0 + d)
	var foot := _at(base, d)
	var crown := _at(base + Vector2(0, -250), d)
	draw_line(foot, crown, Color("#5E4A3C"), maxf(1.5, 14.0 * s))
	for i in 7:
		var a := TAU * i / 7.0 + d
		var off := Vector2(cos(a) * 70.0, sin(a) * 50.0) * s
		draw_circle(crown + off, 62.0 * s, LEAVES[(i + int(d * 3.0)) % LEAVES.size()].darkened(0.08 * float(i % 2)))
	draw_circle(crown + Vector2(-22, -26) * s, 40.0 * s, LEAVES[2].lightened(0.15))


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
		draw_circle(Vector2.ZERO, _rng.randf_range(3.0, 5.0), LEAVES[_rng.randi_range(0, LEAVES.size() - 1)])
	draw_set_transform(Vector2.ZERO)


# ── Signs ───────────────────────────────────────────────────────

func _draw_signs() -> void:
	var font := ThemeDB.fallback_font
	# At the corner of the sidewalk, by the curb, clear of the shop signs on the facades.
	var corner := x0 + sidewalk - 22.0 if sign_side < 0.0 else x1 - sidewalk + 22.0
	var px := _fan(corner, 650.0)
	var foot := Vector2(px, 652.0)
	# Wooden utility pole carrying the wires that cross the street.
	var pole_x := _fan(x0 + 50.0 if sign_side > 0.0 else x1 - 50.0, 600.0)
	draw_rect(Rect2(pole_x - 5, 120, 10, 482), Color("#6B5644"))
	draw_rect(Rect2(pole_x - 5, 120, 3, 482), Color("#8A735E"))
	draw_rect(Rect2(pole_x - 26, 136, 52, 6), Color("#5A4636"))
	for i in 3:
		var wy := 140.0 + i * 4.0
		var pts := PackedVector2Array()
		for t in 9:
			var x := lerpf(pole_x - 700.0, pole_x + 700.0, t / 8.0)
			pts.append(Vector2(x, wy + 26.0 * (1.0 - pow(absf(t / 4.0 - 1.0), 2.0)) - 20.0))
		draw_polyline(pts, Color(0.12, 0.1, 0.1, 0.7), 1.2, true)
	# Sign post: the cross street's plate, plus a school zone sign or a stop sign.
	draw_rect(Rect2(px - 3, 360, 6, foot.y - 360), Color("#5A5F63"))
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
	# Montreal-style blue street plates.
	var names := [street_name, "6e Avenue"]
	for i in names.size():
		var r := Rect2(px - 80, 296 + i * 30, 160, 26)
		draw_rect(r, Color.WHITE)
		draw_rect(r.grow(-2.5), Color("#1D4F91"))
		draw_string(font, Vector2(r.position.x, r.position.y + 19), names[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)
