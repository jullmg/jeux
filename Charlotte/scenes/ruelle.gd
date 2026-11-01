extends StreetScene
# The back lane of Charlotte's block (reference/ruelle photos, google_map_immediate_area.png). The lane is an H:
# two cross lanes from 6e to 5e Avenue (near Holt, and the green lane near Dandurand) joined by this middle lane,
# seen looking toward the backs of the 6e Avenue plexes: Holt's end on the left, Dandurand's on the right.
# At each end, the cross lane: click the way down it to come out on 6e Avenue, the sign at the bottom for 5e.
# Reuses StreetScene's helpers (Charlotte, camera, cats, wind, grade) but builds its own scene.

const LOTS := 14
const LOT_W := 365.0
const END_W := 320.0
const JUNCTION_W := 300.0
## Charlotte's yard: hers is the 7th plex from the Dandurand end on 6e Avenue.
const OWN_LOT := 8
const FENCE_Y := 600.0
const FRONT_KINDS := ["boards", "boards", "cedar", "tole", "picket", "chainlink", "tole", "garage", "shed", "boards", "cedar", "garden"]

# Lots left to right (x from, x to; their kind), the two cross lanes' centres, clothesline pulleys.
var _lots: Array[Vector2] = []
var _kinds: Array[String] = []
var _junctions: Array[float] = []
var _pulleys: Array[Vector2] = []
var _poles: Array[float] = []


func _init() -> void:
	street_key = "ruelle"
	seed_value = 5151


func _ready() -> void:
	_rng.seed = seed_value
	_plan()
	add_child(SkyBackdrop.new())
	Skyline.build(self, _street_width, VIEW.x)
	add_child(Birds.new())
	_build_backs()
	_build_yard_trees()
	_build_fronts()
	_build_poles()
	var ground := _Ground.new()
	ground.width = _street_width
	ground.hopscotch = (_lots[OWN_LOT].x + _lots[OWN_LOT].y) / 2.0
	ground.junctions = _junctions
	add_child(ground)
	var start_x := _start_x()
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_start = start_x
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	_control.bounds = Vector2(90.0, _street_width - 90.0)
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
	cat.position = Vector2(start_x + 300.0, STRAY_CAT_Y)
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


# Into the lane from 6e or 5e Avenue: at the cross lane she came down.
func _start_x() -> float:
	for street in ["6e", "5e"]:
		if _arriving("ruelle_from_%s_ruelle" % street):
			return _junctions[0]
		if _arriving("ruelle_from_%s_ruelle_verte" % street):
			return _junctions[1]
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _junctions[1] - 400.0


func _music() -> Array:
	return ["ruelle", "street_" + Season.current, "street"]


# Lost cats hide in the lane by lot (index + fraction).
func _found_x(at: float) -> float:
	var lot := _lots[int(at)]
	return lerpf(lot.x, lot.y, at - int(at))


# ── Layout ──────────────────────────────────────────────────────

func _plan() -> void:
	var x := 0.0
	var widths: Array[float] = [END_W]
	for i in LOTS:
		widths.append(LOT_W)
	widths.append(END_W)
	for i in widths.size():
		if i == 1 or i == widths.size() - 1:
			_junctions.append(x + JUNCTION_W / 2.0)
			x += JUNCTION_W
		_lots.append(Vector2(x, x + widths[i]))
		x += widths[i]
	_street_width = x
	for i in _lots.size():
		var kind: String = FRONT_KINDS[_rng.randi_range(0, FRONT_KINDS.size() - 1)]
		if i == OWN_LOT:
			kind = "picket"
		elif i == OWN_LOT - 1 or i == OWN_LOT + 1:
			kind = "cedar" if kind in ["picket", "chainlink", "garden"] else kind
		_kinds.append(kind)
	# The green lane's end (near Dandurand) has its planters.
	_kinds[_lots.size() - 2] = "garden"


func _build_backs() -> void:
	for i in _lots.size():
		var lot := _lots[i]
		var made := LaneArt.back(_rng, lot.y - lot.x, i == OWN_LOT)
		var sprite := _sprite(made[0], 1.0)
		sprite.position = Vector2(lot.x, FENCE_Y - LaneArt.H)
		add_child(sprite)
		if _rng.randf() < 0.35 or i == OWN_LOT:
			_pulleys.append(sprite.position + made[1])
	for jx in _junctions:
		var sprite := _sprite(LaneArt.junction(_rng, JUNCTION_W), 1.0)
		sprite.position = Vector2(jx - JUNCTION_W / 2.0, FENCE_Y - LaneArt.H)
		add_child(sprite)


# Big yard trees rising behind the fences (the crabapple in bloom in spring, red maples in autumn).
func _build_yard_trees() -> void:
	var leaf := Season.falling_texture()
	var phase := 0.0
	for i in _lots.size():
		if _rng.randf() > 0.45:
			continue
		var lot := _lots[i]
		var tree := _sprite(PropArt.tree(_rng), 0.6)
		tree.position = Vector2(_rng.randf_range(lot.x - 60.0, lot.y - 170.0), FENCE_Y - 30.0 - 780.0 * 0.6)
		tree.material = _sway(6.0, phase)
		phase += 1.3
		add_child(tree)
		_tree_sprites.append(tree)
		add_child(_falling_leaves(leaf, tree.position + Vector2(190, 250) * 0.6))


func _build_fronts() -> void:
	for i in _lots.size():
		var lot := _lots[i]
		var sprite := _sprite(LaneArt.front(_rng, lot.y - lot.x, _kinds[i], i == OWN_LOT), 1.0)
		sprite.position = Vector2(lot.x, FENCE_Y - LaneArt.H)
		add_child(sprite)
	# Dad's bike leaning on Charlotte's fence.
	var own := _lots[OWN_LOT]
	var bike := _sprite(PropArt.bike(_rng), 0.8)
	bike.position = Vector2(own.x + 40.0, FENCE_Y + 4.0 - 90.0 * 0.8)
	add_child(bike)


# Wooden poles along the far edge of the lane, wires looping from one to the next.
func _build_poles() -> void:
	var x := 180.0
	var k := 0
	while x < _street_width - 100.0:
		var pole := _sprite(LaneArt.pole(k % 3 == 1), 1.0)
		pole.position = Vector2(x - 40.0, FENCE_Y + 10.0 - LaneArt.H)
		add_child(pole)
		_poles.append(x)
		x += _rng.randf_range(820.0, 980.0)
		k += 1
	var wires := _Wires.new()
	wires.poles = _poles
	wires.width = _street_width
	add_child(wires)


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


# The two cross lanes: up the lane to 6e Avenue, down (toward us) to 5e Avenue.
func _build_exits() -> void:
	var ends := [["ruelle", "6e_from_ruelle", "5e_from_ruelle"], ["ruelle_verte", "6e_from_ruelle_verte", "5e_from_ruelle_verte"]]
	for i in 2:
		var jx := _junctions[i]
		add_child(DoorSpot.make(Rect2(jx - 110.0, 400.0, 220.0, 190.0), _leave.bind("res://scenes/main.tscn", ends[i][1]), jx))
		add_child(DoorSpot.make(Rect2(jx - 140.0, 668.0, 280.0, 52.0), _leave.bind("res://scenes/cinquieme.tscn", ends[i][2]), jx))
		_label("↑  6e Avenue", Vector2(jx, 392.0), Vector2(160, 26), 15, Color.WHITE, Color("#1D4F91"))
		_label("↓  5e Avenue", Vector2(jx, 700.0), Vector2(160, 26), 15, Color.WHITE, Color("#1D4F91"))
		if ends[i][0] == "ruelle_verte":
			_label("RUELLE\nVERTE", Vector2(jx + 120.0, 446.0), Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


func _leave(scene: String, arrive: String) -> void:
	_control.enabled = false
	Transition.arrive = arrive
	Transition.change_scene(self, scene)


# The lane itself: weathered concrete in slabs, the crack down the middle with weeds, grass along the fences,
# this season's leaves (or snow), and a chalk hopscotch in front of Charlotte's yard.
class _Ground:
	extends Node2D
	var width := 4000.0
	var hopscotch := 0.0
	var junctions: Array[float] = []

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
		if not snow:
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


# Wires sagging from pole to pole, and off both ends.
class _Wires:
	extends Node2D
	var poles: Array[float] = []
	var width := 4000.0

	func _draw() -> void:
		var tops := [12.0 + 42.0, 12.0 + 42.0, 12.0 + 42.0, 12.0 + 120.0]
		var xs: Array[float] = [-200.0]
		xs.append_array(poles)
		xs.append(width + 200.0)
		for w in 4:
			var off: float = [-30.0, -10.0, 10.0, 0.0][w]
			for i in xs.size() - 1:
				var a := Vector2(xs[i] + off, tops[w])
				var b := Vector2(xs[i + 1] + off, tops[w])
				var pts := PackedVector2Array()
				for k in 17:
					var t := k / 16.0
					pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * (26.0 + w * 4.0)))
				draw_polyline(pts, Color(0.12, 0.12, 0.14, 0.85), 1.6, true)


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
