extends StreetScene
# The back lanes of Charlotte's block (reference/ruelle photos, google_map_immediate_area.png). They make an H:
# two cross lanes running from 6e to 5e Avenue, like little streets parallel to Dandurand and Holt ("dandurand",
# the green lane, and "holt"), joined in their middle by the "middle" lane that runs behind the 6e plexes.
# One script, three scenes (ruelle.tscn, ruelle_dandurand.tscn, ruelle_holt.tscn: `lane`). In a cross lane the
# avenues are at both ends (click the bright opening to come out) and the middle lane opens half way along
# ("↑ Ruelle"); the middle lane opens on the two cross lanes at its ends. Seen looking at:
#  - middle: the backs of the 6e plexes (east), Holt's end on the left;
#  - dandurand: north, 5e Avenue on the left, 6e on the right;
#  - holt: south, 6e on the left, 5e on the right.
# Reuses StreetScene's helpers (Charlotte, camera, cats, wind, grade) but builds its own scene.

const LOTS := 14
const SIDE_LOTS := 3
const LOT_W := 365.0
const END_W := 320.0
const JUNCTION_W := 300.0
## Charlotte's yard, in the middle lane: hers is the 7th plex from the Dandurand end on 6e Avenue.
const OWN_LOT := 8
const FENCE_Y := 600.0
const FRONT_KINDS := ["boards", "boards", "cedar", "tole", "picket", "chainlink", "tole", "garage", "shed", "boards", "cedar", "garden"]
const SCENES := {
	"middle": "res://scenes/ruelle.tscn", "dandurand": "res://scenes/ruelle_dandurand.tscn", "holt": "res://scenes/ruelle_holt.tscn",
	"6e": "res://scenes/main.tscn", "5e": "res://scenes/cinquieme.tscn",
}

## Which lane this scene is: "middle", "dandurand" or "holt".
@export var lane := "middle"

# Lots left to right (x from, x to; their kind), the openings (to an avenue or another lane), clothesline pulleys.
var _lots: Array[Vector2] = []
var _kinds: Array[String] = []
var _openings: Array[Dictionary] = []
var _pulleys: Array[Vector2] = []
var _poles: Array[float] = []
var _own := -1


func _ready() -> void:
	street_key = "ruelle" if lane == "middle" else "ruelle_" + lane
	seed_value = 5151 + ["middle", "dandurand", "holt"].find(lane) * 97
	_own = OWN_LOT if lane == "middle" else -1
	_rng.seed = seed_value
	_plan()
	add_child(SkyBackdrop.new())
	Skyline.build(self, _street_width, VIEW.x)
	add_child(Birds.new())
	_build_backs()
	_build_yard_trees()
	_build_fronts()
	_build_poles()
	_build_croque_livre()
	var ground := _Ground.new()
	ground.width = _street_width
	ground.hopscotch = (_lots[_own].x + _lots[_own].y) / 2.0 if _own >= 0 else -1.0
	add_child(ground)
	var start_x := _start_x()
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_start = start_x
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	_control.bounds = Vector2(maxf(90.0, _openings[0].x if lane != "middle" else 90.0),
		minf(_street_width - 90.0, _openings[-1].x if lane != "middle" else _street_width - 90.0))
	_control.walk_top = 360.0
	add_child(_control)
	_build_exits()
	var saver := Saver.new()
	saver.who = _charlotte
	add_child(saver)
	var kick := LeafKick.new()
	kick.walker = _charlotte
	add_child(kick)
	_animals = Node2D.new()
	add_child(_animals)
	# The lane's black cat, as in the photo.
	var cat := StrayCat.random(_rng)
	cat.coat = StrayCat.COATS[1]
	cat.position = Vector2(clampf(start_x + 300.0, 100.0, _street_width - 100.0), STRAY_CAT_Y)
	cat.bounds = Vector2(60.0, _street_width - 60.0)
	cat.charlotte = _charlotte
	_animals.add_child(cat)
	_build_lost_cats()
	var lines := _Clotheslines.new()
	lines.pulleys = _pulleys
	lines.seed_value = seed_value
	add_child(lines)
	_build_foreground()
	add_child(_wind)
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = int(_street_width)
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW.y)
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	_follow_charlotte()
	_camera.reset_smoothing()
	_build_grade()
	Season.add_weather(self)
	Sfx.ambience(self)
	Music.play(_music())
	Transition.fade_in(self)
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


# At the opening she came through (Transition.arrive = "<this lane>_from_<where>").
func _start_x() -> float:
	for o in _openings:
		if _arriving(o.here):
			return o.x
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _openings[-1].x - 400.0 if lane == "middle" else _openings[1].x


func _music() -> Array:
	return ["ruelle", "street_" + Season.current, "street"]


# Lost cats hide in the lane by lot (index + fraction).
func _found_x(at: float) -> float:
	var lot := _lots[int(at)]
	return lerpf(lot.x, lot.y, at - int(at))


# ── Layout ──────────────────────────────────────────────────────

func _plan() -> void:
	var lots := LOTS if lane == "middle" else SIDE_LOTS * 2
	# An opening: where it leads (scene, Transition.arrive there), its label, and the key that arrives here.
	var to_lane := func(other: String, label: String) -> Dictionary:
		return {"kind": "lane", "scene": SCENES[other], "arrive": "%s_from_%s" % ["ruelle" if other == "middle" else "ruelle_" + other, lane if lane != "middle" else "middle"],
			"label": label, "here": "%s_from_%s" % [street_key, "middle" if other == "middle" else other]}
	var to_street := func(street: String) -> Dictionary:
		var art := "ruelle_verte" if lane == "dandurand" else "ruelle"
		return {"kind": "street", "scene": SCENES[street], "arrive": "%s_from_%s" % [street, art],
			"label": "6e Avenue" if street == "6e" else "5e Avenue", "here": "%s_from_%s" % [street_key, street]}
	var plan: Array = []
	match lane:
		"middle":
			plan = ["end", to_lane.call("holt", "↑  Ruelle"), lots, to_lane.call("dandurand", "↑  Ruelle verte"), "end"]
		"dandurand":
			plan = [to_street.call("5e"), SIDE_LOTS, to_lane.call("middle", "↑  Ruelle"), SIDE_LOTS, to_street.call("6e")]
		"holt":
			plan = [to_street.call("6e"), SIDE_LOTS, to_lane.call("middle", "↑  Ruelle"), SIDE_LOTS, to_street.call("5e")]
	var x := 0.0
	for part in plan:
		if part is Dictionary:
			part.x = x + JUNCTION_W / 2.0
			_openings.append(part)
			x += JUNCTION_W
		elif part is String:
			_lots.append(Vector2(x, x + END_W))
			x += END_W
		else:
			for i in int(part):
				_lots.append(Vector2(x, x + LOT_W))
				x += LOT_W
	_street_width = x
	for i in _lots.size():
		var kind: String = FRONT_KINDS[_rng.randi_range(0, FRONT_KINDS.size() - 1)]
		if i == _own:
			kind = "picket"
		elif _own >= 0 and absi(i - _own) == 1:
			kind = "cedar" if kind in ["picket", "chainlink", "garden"] else kind
		_kinds.append(kind)
	# The green lane has its planter boxes (and the middle lane's end near it).
	if lane == "middle":
		_kinds[_lots.size() - 2] = "garden"
	elif lane == "dandurand":
		_kinds[0] = "garden"
		_kinds[-1] = "garden"


func _build_backs() -> void:
	for i in _lots.size():
		var lot := _lots[i]
		var made := LaneArt.back(_rng, lot.y - lot.x, i == _own)
		var sprite := _sprite(made[0], 1.0)
		sprite.material = weathered(i, 0.1)
		sprite.position = Vector2(lot.x, FENCE_Y - LaneArt.H)
		add_child(sprite)
		if _rng.randf() < 0.35 or i == _own:
			_pulleys.append(sprite.position + made[1])
	for o in _openings:
		var art := LaneArt.junction(_rng, JUNCTION_W) if o.kind == "lane" else LaneArt.street_end(_rng, JUNCTION_W)
		var sprite := _sprite(art, 1.0)
		sprite.position = Vector2(o.x - JUNCTION_W / 2.0, FENCE_Y - LaneArt.H)
		add_child(sprite)


# Big yard trees rising behind the fences (the crabapple in bloom in spring, red maples in autumn).
func _build_yard_trees() -> void:
	var leaf := Season.falling_texture()
	var phase := 0.0
	for i in _lots.size():
		if _rng.randf() > 0.45:
			continue
		var lot := _lots[i]
		# Yard trees of every age, from a young one just over the fence to an old giant.
		var k: float = [0.45, 0.55, 0.65, 0.78][_rng.randi_range(0, 3)]
		var tree := _sprite(PropArt.tree(_rng), k)
		tree.position = Vector2(_rng.randf_range(lot.x - 60.0, lot.y - 170.0), FENCE_Y - 30.0 - 780.0 * k)
		tree.material = _sway(6.0, phase)
		phase += 1.3
		add_child(tree)
		_tree_sprites.append(tree)
		add_child(_falling_leaves(leaf, tree.position + Vector2(190, 250) * k))


func _build_fronts() -> void:
	for i in _lots.size():
		var lot := _lots[i]
		var sprite := _sprite(LaneArt.front(_rng, lot.y - lot.x, _kinds[i], i == _own), 1.0)
		sprite.material = weathered(i + 50, 0.25)
		sprite.position = Vector2(lot.x, FENCE_Y - LaneArt.H)
		add_child(sprite)
	# Dad's bike leaning on Charlotte's fence.
	if _own >= 0:
		var own := _lots[_own]
		var bike := _sprite(PropArt.bike(_rng), 0.8)
		bike.position = Vector2(own.x + 40.0, FENCE_Y + 4.0 - 90.0 * 0.8)
		add_child(bike)


# Every lane has its croque-livre against a fence: take a book, leave a book. (Ready for a quest later.)
func _build_croque_livre() -> void:
	var lot := _lots[4 if lane == "middle" else 1]
	var box := _sprite(LaneArt.croque_livre(_rng), 0.75)
	box.position = Vector2(lot.x + 70.0, FENCE_Y + 10.0 - 200.0 * 0.75)
	add_child(box)
	var x := box.position.x + 50.0 * 0.75
	add_child(DoorSpot.make(Rect2(box.position, Vector2(100, 200) * 0.75), _open_croque_livre, x + 40.0))


func _open_croque_livre() -> void:
	var lines := ["Un croque-livre ! On prend un livre,\non en laisse un.", "Il y a plein d'histoires\nlà-dedans !"]
	Bubble.say(self, _charlotte.position + Vector2(0, -190), lines[randi() % lines.size()], 2.8)
	Sfx.play("page")


# Wooden poles along the far edge of the lane, wires from one to the next (no service drops: the galleries' own).
func _build_poles() -> void:
	var x := 180.0
	while x < _street_width - 100.0:
		_poles.append(x)
		x += _rng.randf_range(820.0, 980.0)
	var poles := UtilityPoles.new()
	poles.xs = _poles
	poles.foot = FENCE_Y + 6.0
	poles.width = _street_width
	poles.drop_y = NAN
	poles.seed_value = seed_value
	add_child(poles)


# Blurred leaf piles and shrubs right in front of the camera (no street signs back here).
func _build_foreground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(Foreground.SCROLL, 1.0)
	add_child(layer)
	var span := VIEW.x + Foreground.SCROLL * (_street_width - VIEW.x) + 300.0
	var x := rng.randf_range(150.0, 500.0)
	while x < span:
		if rng.randf() < 0.5:
			Foreground.add(layer, Foreground.leaf_pile(rng), Vector2(x, 720.0 + 26.0), Vector2(300, 110))
		else:
			Foreground.add(layer, Foreground.shrub(rng), Vector2(x, 720.0 + 70.0), Vector2(260, 170))
		x += rng.randf_range(900.0, 1500.0)


# Each opening: click it to go through. The avenues get their blue street plate, the lanes an arrow.
func _build_exits() -> void:
	for o in _openings:
		var x: float = o.x
		add_child(DoorSpot.make(Rect2(x - 110.0, 400.0, 220.0, 190.0), _leave.bind(o.scene, o.arrive), x))
		if o.kind == "street":
			_label(o.label, Vector2(x, 380.0), Vector2(150, 26), 15, Color.WHITE, Color("#1D4F91"))
		else:
			_label(o.label, Vector2(x, 392.0), Vector2(170, 26), 15, Color.WHITE, Color("#1E5E30"))
	if lane == "dandurand":
		for o in [_openings[0], _openings[-1]]:
			_label("RUELLE\nVERTE", Vector2(o.x + (110.0 if o == _openings[0] else -110.0), 446.0), Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


func _leave(scene: String, arrive: String) -> void:
	_control.enabled = false
	Transition.arrive = arrive
	Transition.change_scene(self, scene)


# The lane itself: weathered concrete in slabs, the crack down the middle with weeds, grass along the fences,
# this season's leaves (or snow), and a chalk hopscotch in front of Charlotte's yard.
class _Ground:
	extends Node2D
	var width := 4000.0
	var hopscotch := -1.0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var snow := Season.is_winter()
		var concrete := Color("#E9EDF0") if snow else Color("#A9A59D")
		draw_rect(Rect2(0, 596, width, 124), concrete)
		draw_rect(Rect2(0, 596, width, 8), Color(0, 0, 0, 0.12))
		var x := 0.0
		while x < width:
			draw_line(Vector2(x, 600), Vector2(x - 40.0, 720), concrete.darkened(0.15), 2.0)
			for i in 3:
				var p := Vector2(x + rng.randf_range(20, 240), rng.randf_range(612, 712))
				draw_line(p, p + Vector2(rng.randf_range(-30, 30), rng.randf_range(-8, 8)), concrete.darkened(0.12), 1.0)
			x += rng.randf_range(240.0, 300.0)
		# The crack down the middle, with a line of weeds in it.
		var weed: Color = Color("#C9CFD4") if snow else ({"autumn": Color("#7E8A3A"), "spring": Color("#6DA544")}.get(Season.current, Color("#4F8E3A")))
		var pts := PackedVector2Array()
		x = 0.0
		while x <= width:
			pts.append(Vector2(x, 660.0 + sin(x * 0.013) * 4.0 + rng.randf_range(-1.5, 1.5)))
			x += 18.0
		draw_polyline(pts, concrete.darkened(0.35), 2.0)
		for p in pts:
			if rng.randf() < 0.5:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 1), p + Vector2(rng.randf_range(-3, 3), -rng.randf_range(6, 13)), p + Vector2(5, 1)]), weed)
		# Grass tufts along the fences.
		x = 0.0
		while x < width:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 604), Vector2(x + rng.randf_range(-4, 4), 590 - rng.randf_range(0, 12)), Vector2(x + 8, 604)]), weed.darkened(0.1))
			x += rng.randf_range(10.0, 40.0)
		# Leaves, petals or nothing, by the season.
		var colors := Season.litter()
		for i in int(width / 8.0 * Season.litter_amount()):
			var c := Vector2(rng.randf_range(0, width), rng.randf_range(606, 718))
			var a := rng.randf_range(0, TAU)
			var r := rng.randf_range(3.0, 6.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a) * r, c + Vector2.from_angle(a + 1.9) * r * 0.5,
				c + Vector2.from_angle(a + PI) * r, c + Vector2.from_angle(a - 1.9) * r * 0.5]), colors[i % colors.size()])
		if not snow and hopscotch >= 0.0:
			_hopscotch(Vector2(hopscotch - 170.0, 676.0))

	# Chalk squares along the lane: 1, 2, 3, 4|5, 6, 7|8 (side by side across the lane: one above the other
	# here), then the CIEL half-circle; a chalk sun beside it.
	func _hopscotch(at: Vector2) -> void:
		var font := ThemeDB.fallback_font
		var chalk: Array[Color] = [Color("#F7C6D9", 0.9), Color("#BFE3F7", 0.9), Color("#FFF1A8", 0.9)]
		var cols := [[1], [2], [3], [4, 5], [6], [7, 8]]
		for c in cols.size():
			var cell: Array = cols[c]
			var h := 36.0 / cell.size()
			for k in cell.size():
				var r := Rect2(at + Vector2(c * 42.0, -18.0 + k * h), Vector2(42, h))
				draw_rect(r, chalk[c % 3], false, 2.0)
				draw_string(font, r.get_center() + Vector2(-4, 5 if h > 20 else 4), str(cell[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13 if h > 20 else 10, chalk[(c + 1) % 3])
		var end := at + Vector2(cols.size() * 42.0, 0)
		draw_arc(end, 18.0, -PI / 2.0, PI / 2.0, 16, chalk[0], 2.0)
		draw_string(font, end + Vector2(2, 4), "CIEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, chalk[2])
		var sun := at + Vector2(-34, 0)
		draw_arc(sun, 10, 0, TAU, 16, chalk[2], 2.0)
		for k in 8:
			var d := Vector2.from_angle(TAU * k / 8.0)
			draw_line(sun + d * 13.0, sun + d * 19.0, chalk[2], 2.0)


# Clotheslines from the back galleries' pulleys, running across the lane toward us (to the poles on our side,
# out of view above), with the laundry getting bigger as it comes closer. Drawn in front of everything.
class _Clotheslines:
	extends Node2D
	var pulleys: Array[Vector2] = []
	var seed_value := 1
	var _items: Array = []
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for p in pulleys:
			var end := p + Vector2(rng.randf_range(450.0, 750.0) * (1.0 if rng.randf() < 0.5 else -1.0), -p.y - 40.0)
			var line := []
			if not Season.is_winter():
				for k in rng.randi_range(2, 6):
					line.append([rng.randf_range(0.12, 0.8), rng.randi_range(0, 3), Color(PropArt._pick(rng,
						["#E74C3C", "#FFFFFF", "#3498DB", "#F1C40F", "#9B59B6", "#F7C6D9", "#2ECC71", "#ECF0F1"])), rng.randf_range(0, TAU)])
			_items.append([p, end, line])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _point(a: Vector2, b: Vector2, t: float) -> Vector2:
		return a.lerp(b, t) + Vector2(0, sin(t * PI) * 40.0)

	func _draw() -> void:
		for item in _items:
			var a: Vector2 = item[0]
			var b: Vector2 = item[1]
			for off: float in [0.0, 7.0]:
				var pts := PackedVector2Array()
				for k in 21:
					var t := k / 20.0
					pts.append(_point(a + Vector2(0, off * 0.3), b + Vector2(off * 3.0, off), t))
				draw_polyline(pts, Color(0.92, 0.92, 0.9, 0.9), 1.2 + 1.5, true)
			for thing in item[2]:
				var t: float = thing[0]
				var at := _point(a, b, t)
				var k := 0.6 + t * 1.6
				var sway := sin(_t * 1.6 + thing[3]) * 0.06
				draw_set_transform(at, sway, Vector2(k, k))
				var c: Color = thing[2]
				match thing[1]:
					0:  # A T-shirt.
						draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(20, 8), Vector2(13, 11),
							Vector2(12, 32), Vector2(-12, 32), Vector2(-13, 11), Vector2(-20, 8)]), c)
					1:  # Trousers.
						draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(11, 0), Vector2(12, 36), Vector2(3, 36),
							Vector2(0, 10), Vector2(-3, 36), Vector2(-12, 36)]), c.darkened(0.3))
					2:  # A sheet.
						draw_rect(Rect2(-22, 0, 44, 40), c.lightened(0.3))
					_:  # Socks.
						draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(2, 0), Vector2(2, 14), Vector2(7, 18), Vector2(-4, 18)]), c)
				draw_rect(Rect2(-3, -2, 6, 4), Color("#C9A24A"))
				draw_set_transform(Vector2.ZERO)
