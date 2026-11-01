class_name StreetScene
extends Node2D
## Base for an outdoor street seen from across the road: sky, skyline, the row of houses (`layout`, facade SVGs
## from tools/generate_houses.gd), cross streets (CrossStreet gaps), the sidewalk, street trees, lamps,
## hydrants, bike racks, passersby with dogs, stray cats, squirrels, window cats, wind, Charlotte and the
## camera. A street extends it, fills the data in _init() and overrides the hooks (see scenes/main.gd).
## Usage: Godot --path . res://scenes/<street>.tscn -- --screenshot=/tmp/x.png [--x=1234] [--wait=seconds]

const VIEW := Vector2(1280, 720)
const HOUSE_BASE_Y := 592.0
const HOUSE_SCALE := 0.57
const CHAR_SCALE := 0.38
const CHARLOTTE_Y := 638.0
const NEIGHBOUR_Y := 612.0
const CURB_Y := 664.0
const TREE_SCALE := 0.55
const MARGIN := 30.0
const STRAY_CAT_Y := 646.0
const MAX_STRAY_CATS := 1
## Charlotte may cross a street on her own from this age; before that she stays on her block (corners and lanes).
const CROSS_AGE := 8
const LANE_SCENE := "res://scenes/ruelle.tscn"

# ── The street's data (set by the subclass in _init) ────────────
## Buildings left to right (facade SVG names), with cross streets as gaps named in `cross_streets`.
var layout: Array[String] = []
## Cross street gaps: name → width in px at the facade line.
var cross_streets := {}
## A street tree at the start of the building after each of these layout indices.
var trees_after: Array[int] = []
var lamps_after: Array[int] = []
## Fractional layout positions (index + fraction across that building).
var hydrants_at: Array[float] = []
var racks_at: Array[float] = []
var squirrels_at: Array[float] = []
var passerby_ages: Array[String] = ["adult", "child", "senior", "teen"]
## Seed for this street's random details, so it looks the same on every run.
var seed_value := 2026
## Short name used in corner and lane hand-overs ("6e", "5e", "holt", "dandurand"): Transition.arrive keys
## are "<street>_from_<where>".
var street_key := ""

var _street_width := 0.0
var _starts: Array[float] = []
var _textures := {}
var _charlotte: Character
var _camera: Camera2D
# Filled by _build_trees, after the squirrels (which share this array) are built behind them.
var _tree_sprites: Array[Sprite2D] = []
var _rng := RandomNumberGenerator.new()
var _wind := Wind.new()
var _animals: Node2D
var _window_cats: WindowCats
var _cat_timer := 3.0
var _control := PlayerControl.new()
var _cross_streets: Array[CrossStreet] = []
# The sidewalk's stretches between cross streets (x from, x to); Charlotte walks one at a time and crosses between them.
var _segments: Array[Vector2] = []
# The utility poles' x, left to right.
var _pole_xs: Array[float] = []
# The crossing guard at the school's crosswalk, if any (key: the CrossStreet).
var _guards := {}
# Where Charlotte started (worked out once: _start_x() may consume Transition's hand-over).
var _start := 0.0


func _ready() -> void:
	_rng.seed = seed_value
	add_child(SkyBackdrop.new())
	_starts = _layout_starts()
	_street_width = _starts[-1]
	Skyline.build(self, _street_width, VIEW.x)
	add_child(Birds.new())
	_build_cross_streets()
	for cs in _cross_streets:
		add_child(cs)
	_build_houses()
	_build_window_cats()
	_build_landmarks()
	var street := Street.new()
	street.width = _street_width
	add_child(street)
	for cs in _cross_streets:
		add_child(CrossStreet.make(CrossStreet.Part.GROUND, cs))
	_build_sidewalk_props()
	var trees := _tree_textures()
	_build_tree_shadows(trees)
	_build_passersby()
	var start_x := _start_x()
	_start = start_x
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	_segments = _walk_segments()
	_control.bounds = _segment_at(start_x)
	_control.walk_top = HOUSE_BASE_Y - 200.0
	add_child(_control)
	_build_doors()
	for cs in _cross_streets:
		_add_crossing(cs)
	var saver := Saver.new()
	saver.who = _charlotte
	add_child(saver)
	_window_cats.charlotte = _charlotte
	var kick := LeafKick.new()
	kick.walker = _charlotte
	add_child(kick)
	# Stray cats walk the sidewalk just in front of Charlotte, so her petting hand lands on their heads.
	_animals = Node2D.new()
	add_child(_animals)
	_spawn_cat(start_x + 260.0)
	_build_squirrels()
	_build_trees(trees)
	_build_props()
	_build_lost_cats()
	Foreground.build(self, _street_width, VIEW.x)
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


func _process(delta: float) -> void:
	_follow_charlotte()
	_spawn_stray_cats(delta)


# ── Hooks for the street ────────────────────────────────────────

## Where Charlotte starts (when no --x= is given).
func _start_x() -> float:
	return _street_width / 2.0


## The sidewalk split into stretches at each cross street's curbs.
func _walk_segments() -> Array[Vector2]:
	var segments: Array[Vector2] = []
	var left := 60.0
	var sorted := _cross_streets.duplicate()
	sorted.sort_custom(func(a, b): return a.x0 < b.x0)
	for cs in sorted:
		var road: Vector2 = cs.road_x(CHARLOTTE_Y)
		segments.append(Vector2(left, road.x - 8.0))
		left = road.y + 8.0
	segments.append(Vector2(left, _street_width - 60.0))
	return segments


## The stretch of sidewalk that x is on.
func _segment_at(x: float) -> Vector2:
	for seg in _segments:
		if x <= seg.y + 1.0:
			return seg
	return _segments[-1]


## Configure each cross street (its walls, signs) with _cross_street(); they're added for you.
func _build_cross_streets() -> void:
	pass


## Labels or extras on a house just placed (layout index i).
func _decorate_house(_i: int, _house: Sprite2D) -> void:
	pass


## One-off characters or details on the facades (e.g. a cat on a railing).
func _build_landmarks() -> void:
	pass


## Clickable doors and corners.
func _build_doors() -> void:
	pass


## Turning the corner: click a cross street and Charlotte walks to the curb on her side, then `scene` (another
## street) loads with Transition.arrive = `arrive`, so that street knows which corner she comes round.
## Only from the sidewalk Charlotte started on (the block the corner belongs to); the crosswalk below is for crossing.
func _add_corner(cs: CrossStreet, scene: String, arrive: String) -> void:
	var home := _control.bounds
	var curb := home.y if cs.x0 > _start else home.x
	var area := Rect2(cs.x0 + 30.0, 380.0, cs.x1 - cs.x0 - 60.0, 218.0)
	var spot := DoorSpot.make(area, func():
		_control.enabled = false
		Transition.arrive = arrive
		Transition.change_scene(self, scene), curb)
	spot.condition = func(): return _segment_at(_charlotte.position.x) == home
	add_child(spot)


## The crosswalk: click it and Charlotte goes to the curb on her side, looks both ways, and crosses to the other
## side (and back the same way). At the school's crosswalk the crossing guard steps out with her stop paddle.
func _add_crossing(cs: CrossStreet) -> void:
	var road := cs.road_x(630.0)
	var area := Rect2(road.x, 600.0, road.y - road.x, CURB_Y - 600.0)
	var spot := DoorSpot.make(area, _cross.bind(cs))
	spot.approach = func(from_x: float) -> float:
		var curbs := cs.road_x(CHARLOTTE_Y)
		return curbs.x - 8.0 if from_x < (cs.x0 + cs.x1) / 2.0 else curbs.y + 8.0
	add_child(spot)
	if cs.guard:
		var guard := CrossingGuard.new()
		guard.scale = Vector2.ONE * CHAR_SCALE
		guard.position = Vector2(cs.road_x(CHARLOTTE_Y + 12.0).x - 34.0, CHARLOTTE_Y + 12.0)
		guard.walk_speed = 150.0
		add_child(guard)
		_guards[cs] = guard


func _cross(cs: CrossStreet) -> void:
	if GameState.age < CROSS_AGE:
		Bubble.say(self, _charlotte.position + Vector2(0, -190), "Je n'ai pas le droit de traverser\ntoute seule !", 2.6)
		return
	var curbs := cs.road_x(CHARLOTTE_Y)
	var mid := (cs.x0 + cs.x1) / 2.0
	var going_right := _charlotte.position.x < mid
	var dir := 1 if going_right else -1
	var to := curbs.y + 8.0 if going_right else curbs.x - 8.0
	var walk_time := absf(to - _charlotte.position.x) / _charlotte.walk_speed
	_control.enabled = false
	_control.hands_off = true
	_charlotte.is_walking = false
	Bubble.say(self, _charlotte.position + Vector2(0, -190), "Je regarde des deux côtés !", 1.4)
	var tween := create_tween()
	# Look both ways first: toward the road, back, and toward it again.
	for look in [dir, -dir, dir]:
		tween.tween_callback(func(): _charlotte.facing = look)
		tween.tween_interval(0.45)
	if _guards.has(cs):
		_guards[cs].escort(mid, walk_time + 0.6)
		tween.tween_interval(0.9)
	tween.tween_callback(func():
		_charlotte.facing = dir
		_charlotte.is_walking = true)
	tween.tween_property(_charlotte, "position:x", to, walk_time)
	tween.tween_callback(func():
		_charlotte.is_walking = false
		_control.bounds = _segment_at(to)
		_control.hands_off = false
		_control.enabled = true)



## A back lane's entrance (the "ruelle" or "ruelle_verte" building in `layout`): click it and Charlotte walks into
## the lane (scenes/ruelle.tscn), which knows which entrance from Transition.arrive.
func _add_lane(art: String) -> void:
	var i := layout.find(art)
	var w := _tex(art).get_width()
	var area := Rect2(_house_origin(i) + Vector2(70.0, 330.0) * HOUSE_SCALE, Vector2(w - 140.0, 370.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_control.enabled = false
		Transition.arrive = "ruelle_from_%s_%s" % [street_key, art]
		Transition.change_scene(self, LANE_SCENE), area.get_center().x))


## Where Charlotte comes out of the lane onto this street (NAN if she isn't coming from it).
func _from_lane() -> float:
	for art in ["ruelle", "ruelle_verte"]:
		if layout.has(art) and _arriving("%s_from_%s" % [street_key, art]):
			return _street_x(layout.find(art) + 0.5)
	return NAN


## Takes the corner hand-over: true (and clears it) when Charlotte is arriving round `key`.
func _arriving(key: String) -> bool:
	if Transition.arrive != key:
		return false
	Transition.arrive = ""
	return true


## The soundtrack here, first that exists (see Music): this season's street theme, then the street theme.
func _music() -> Array:
	return ["street_" + Season.current, "street"]


## Things standing at the back of the sidewalk, against the buildings: added right after the sidewalk, so the
## passersby, Charlotte and the animals walk in front of them.
func _build_sidewalk_props() -> void:
	pass


## Street-specific props, before the generic lamps, hydrants and racks (these are drawn in front of people,
## like the curbside lamps).
func _build_extra_props() -> void:
	pass


# ── Lost cats (LostCats) ────────────────────────────────────────

## This street's part in the lost-cat quests: the cat in Charlotte's arms, the "PERDU" poster, the lost cat
## waiting here, and the owner's front door.
func _build_lost_cats() -> void:
	var held := LostCats.carrying()
	if held != "":
		_charlotte.carry(LostCats.held(held))
	for id in LostCats.ALL:
		var info: Dictionary = LostCats.ALL[id]
		if info.poster == street_key and (Quests.available(id) or Quests.active(id)):
			_add_poster(id)
		if info.found == street_key and Quests.active(id) and held != id:
			_add_lost_cat(id)
		if info.home == street_key and Quests.active(id):
			_add_owner_door(id)


## Where a found_at position is on this street (the lane counts in lots).
func _found_x(at: float) -> float:
	return _street_x(at)


## Where this street's "PERDU" poster hangs (its centre): stapled to the utility pole nearest the second lamp.
func _poster_spot() -> Vector2:
	var near := _starts[lamps_after[mini(1, lamps_after.size() - 1)] + 1]
	var best := _pole_xs[0]
	for x in _pole_xs:
		if absf(x - near) < absf(best - near):
			best = x
	return Vector2(best, 528.0)


## x of a plex's front door (art/decor/doors.json, from the generator).
func _door_x(art: String) -> float:
	if _door_data.is_empty():
		_door_data = JSON.parse_string(FileAccess.get_file_as_string("res://art/decor/doors.json"))
	return _house_origin(layout.find(art)).x + float(_door_data.get(art, 350.0)) * HOUSE_SCALE


static var _door_data := {}


func _add_poster(id: String) -> void:
	var info: Dictionary = LostCats.ALL[id]
	var at := _poster_spot()
	var poster := LostCats.Poster.new()
	poster.id = id
	poster.position = at
	add_child(poster)
	add_child(QuestMark.make(at + Vector2(0, -66), func() -> bool: return Quests.available(id), 0.7))
	add_child(DoorSpot.make(Rect2(at - Vector2(26, 36), Vector2(52, 72)), func():
		var said := "%s… où es-tu ?" % info.name
		if Quests.start(id):
			said = "%s est perdu%s !\nJe vais %s retrouver !" % [info.name, info.get("e", ""), "la" if info.has("e") else "le"]
		Bubble.say(self, _charlotte.position + Vector2(0, -190), said, 2.6), at.x - 34.0))


# The lost cat, wearing its collar, waiting near where it was last seen. Pet it and Charlotte picks it up.
func _add_lost_cat(id: String) -> void:
	var cat := LostCats.make(id)
	var x := _found_x(float(LostCats.ALL[id].found_at))
	var room := _segment_at(x) if not _segments.is_empty() else Vector2(60.0, _street_width - 60.0)
	cat.position = Vector2(x, STRAY_CAT_Y)
	cat.bounds = Vector2(maxf(x - 350.0, room.x), minf(x + 350.0, room.y))
	cat.charlotte = _charlotte
	cat.on_pet = func():
		cat.on_pet = Callable()
		Bubble.say(self, _charlotte.position + Vector2(0, -190), "Je te tiens, %s !\nOn rentre chez toi." % LostCats.ALL[id].name, 2.6)
		get_tree().create_timer(StrayCat.PET_TIME).timeout.connect(func():
			cat.queue_free()
			GameState.flags["carrying"] = id
			_charlotte.carry(LostCats.held(id)))
	_animals.add_child(cat)


# The owner's door: with the cat in her arms, Charlotte rings and the owner comes out.
func _add_owner_door(id: String) -> void:
	var info: Dictionary = LostCats.ALL[id]
	var x := _door_x(info.house)
	_label(str(info.address).get_slice(",", 0), Vector2(x, 396.0), Vector2(48, 16), 11, Color.WHITE, Color("#2B2B2B"))
	add_child(QuestMark.make(Vector2(x, 360.0), func() -> bool: return LostCats.carrying() == id))
	var spot := DoorSpot.make(Rect2(x - 60.0, 400.0, 120.0, 200.0), _bring_home.bind(id, x), x)
	spot.condition = func() -> bool: return LostCats.carrying() == id
	add_child(spot)


func _bring_home(id: String, x: float) -> void:
	var info: Dictionary = LostCats.ALL[id]
	_control.enabled = false
	Sfx.play("door", Vector2(x, 500.0))
	var owner := Character.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	owner.look = CharacterLook.random(rng, "adult")
	# "Mme" or "M.": a look that matches.
	var madame := str(info.owner).begins_with("Mme")
	owner.look.lashes = madame
	owner.look.facial_hair = ""
	if madame and owner.look.hair_style in ["short", "buzz", "bald"]:
		owner.look.hair_style = "long"
	elif not madame and not owner.look.hair_style in ["short", "buzz", "bald"]:
		owner.look.hair_style = "short"
	Season.dress_for_weather(owner.look)
	owner.scale = Vector2.ONE * CHAR_SCALE
	owner.position = Vector2(x + 46.0, CHARLOTTE_Y - 4.0)
	owner.facing = -1
	owner.modulate.a = 0.0
	add_child(owner)
	var tween := create_tween()
	tween.tween_property(owner, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func():
		Bubble.say(self, owner.position + Vector2(0, -200), "%s ! Tu l'as retrouvé%s !\nMerci, Charlotte !" % [info.name, info.get("e", "")], 3.0)
		Sfx.play("meow", owner.position))
	tween.tween_interval(1.2)
	tween.tween_callback(func():
		_charlotte.carry(null)
		GameState.flags.erase("carrying")
		var cat := LostCats.make(id)
		cat.position = Vector2(x + 18.0, STRAY_CAT_Y)
		cat.wander = false
		cat.facing = 1
		_animals.add_child(cat)
		Quests.complete(id)
		_control.enabled = true)
	tween.tween_interval(3.0)
	tween.tween_property(owner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(owner.queue_free)


# ── Layout ──────────────────────────────────────────────────────

func _tex(art: String) -> Texture2D:
	if not _textures.has(art):
		_textures[art] = load(Season.decor(art))
	return _textures[art]


# Start x of each building along the street, plus the total street width at the end.
func _layout_starts() -> Array[float]:
	var starts: Array[float] = []
	var x := 0.0
	for art in layout:
		starts.append(x)
		x += cross_streets[art] if cross_streets.has(art) else (_tex(art).get_width() - 2.0 * MARGIN) * HOUSE_SCALE
	starts.append(x)
	return starts


func _street_x(at: float) -> float:
	var i := int(at)
	return lerpf(_starts[i], _starts[i + 1], at - i)


func _house_origin(i: int) -> Vector2:
	return Vector2(_starts[i] - MARGIN * HOUSE_SCALE, HOUSE_BASE_Y - _tex(layout[i]).get_height() * HOUSE_SCALE)


# World y of a building's roof line (its SVG's top margin is about 40 px).
func _house_top(art: String) -> float:
	return _house_origin(layout.find(art)).y + 40.0 * HOUSE_SCALE


func _cross_street(art: String, street_name: String, sign_side: float) -> CrossStreet:
	var i := layout.find(art)
	var cs := CrossStreet.new()
	cs.x0 = _starts[i]
	cs.x1 = _starts[i + 1]
	cs.street_name = street_name
	cs.sign_side = sign_side
	_cross_streets.append(cs)
	return cs


func _build_houses() -> void:
	# Right to left, so outdoor stairs overlapping the next house stay visible.
	for i in range(layout.size() - 1, -1, -1):
		if cross_streets.has(layout[i]):
			continue
		var house := _sprite(_tex(layout[i]), HOUSE_SCALE)
		house.position = _house_origin(i)
		add_child(house)
		_decorate_house(i, house)


func _build_window_cats() -> void:
	var houses := []
	for i in layout.size():
		if not cross_streets.has(layout[i]):
			houses.append({"art": layout[i], "origin": _house_origin(i), "scale": HOUSE_SCALE})
	_window_cats = WindowCats.new()
	_window_cats.setup(houses)
	add_child(_window_cats)


# ── Utility poles ───────────────────────────────────────────────

## Wooden poles at the curb (in front of the people, like the lamps), every 650-780 px, clear of the cross streets, the
## trees, lamps, hydrants and bike racks; the wires run from one to the next. Their own random numbers, so the
## street's other draws don't change.
func _build_utility_poles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99
	var blocked: Array[Vector2] = []
	for cs in _cross_streets:
		blocked.append(Vector2(cs.x0 - 40.0, cs.x1 + 40.0))
	for after in trees_after + lamps_after:
		blocked.append(Vector2(_starts[after + 1] - 45.0, _starts[after + 1] + 45.0))
	for at in hydrants_at:
		blocked.append(Vector2(_street_x(at) - 35.0, _street_x(at) + 35.0))
	for at in racks_at:
		blocked.append(Vector2(_street_x(at) - 30.0, _street_x(at) + 190.0))
	var x := 160.0
	while true:
		var moved := true
		while moved:
			moved = false
			for b in blocked:
				if x >= b.x and x <= b.y:
					x = b.y + 1.0
					moved = true
		if x > _street_width - 100.0:
			break
		_pole_xs.append(x)
		x += rng.randf_range(650.0, 780.0)
	var poles := UtilityPoles.new()
	poles.xs = _pole_xs
	poles.foot = CURB_Y - 2.0
	poles.width = _street_width
	poles.seed_value = seed_value
	add_child(poles)


# ── Trees ───────────────────────────────────────────────────────

func _tree_textures() -> Array[Texture2D]:
	var trees: Array[Texture2D] = []
	for i in trees_after.size():
		trees.append(PropArt.tree(_rng))
	return trees


func _tree_origin(i: int) -> Vector2:
	return Vector2(_starts[trees_after[i] + 1] - 190.0 * TREE_SCALE, CURB_Y - 780.0 * TREE_SCALE)


func _sway(strength: float, phase: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/sway.gdshader")
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("phase", phase)
	_wind.materials.append(mat)
	return mat


# The low sun on the left throws the canopies' shadows up and to the right, onto the facades.
func _build_tree_shadows(trees: Array[Texture2D]) -> void:
	for i in trees.size():
		if layout[trees_after[i] + 1].begins_with("ruelle"):
			continue
		var shadow := _sprite(trees[i], TREE_SCALE)
		shadow.position = _tree_origin(i) + Vector2(80, 14)
		shadow.modulate = Color(0.22, 0.1, 0.12, 0.2)
		shadow.material = _sway(7.0, i * 1.7)
		add_child(shadow)


func _build_trees(trees: Array[Texture2D]) -> void:
	var leaf := Season.falling_texture()
	for i in trees.size():
		# The square of grass or of the neighbours' flowers round the trunk, cut into the sidewalk by the curb.
		var pit := TreePit.new()
		pit.position = Vector2(_starts[trees_after[i] + 1], CURB_Y)
		pit.seed_value = seed_value * 31 + i
		add_child(pit)
		var tree := _sprite(trees[i], TREE_SCALE)
		tree.position = _tree_origin(i)
		tree.material = _sway(7.0, i * 1.7)
		add_child(tree)
		_tree_sprites.append(tree)
		add_child(_falling_leaves(leaf, tree.position + Vector2(190, 250) * TREE_SCALE))


func _falling_leaves(leaf: Texture2D, at: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = at
	p.texture = leaf
	p.amount = maxi(1, int(7 * Season.falling_amount()))
	p.emitting = Season.falling_amount() > 0.0
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(80, 50)
	p.direction = Vector2(1, 0.3)
	p.spread = 60.0
	p.gravity = Vector2(8, 26)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 24.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.9
	p.color_initial_ramp = PropArt.leaf_colors()
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	p.color_ramp = fade
	return p


# ── Life on the street ──────────────────────────────────────────

func _build_passersby() -> void:
	for i in passerby_ages.size():
		var npc := Passerby.new()
		npc.look = CharacterLook.random(_rng, passerby_ages[i])
		Season.dress_for_weather(npc.look)
		npc.walk_speed = _rng.randf_range(120.0, 170.0) if passerby_ages[i] != "child" else _rng.randf_range(160.0, 210.0)
		npc.position = Vector2(_rng.randf_range(300.0, _street_width - 300.0), NEIGHBOUR_Y)
		npc.scale = Vector2.ONE * CHAR_SCALE
		npc.facing = 1 if _rng.randf() < 0.5 else -1
		npc.bounds = Vector2(80.0, _street_width - 80.0)
		npc.modulate = Color(0.94, 0.94, 0.96)
		add_child(npc)
		if passerby_ages[i] != "child" and _rng.randf() < 0.45:
			add_child(Dog.random(_rng, npc))


func _build_squirrels() -> void:
	for at in squirrels_at:
		var squirrel := Squirrel.new()
		var x := _street_x(at)
		squirrel.position = Vector2(x, 652)
		squirrel.scale = Vector2.ONE * 0.85
		squirrel.bounds = Vector2(maxf(x - 700.0, 60.0), minf(x + 700.0, _street_width - 60.0))
		squirrel.threat = _charlotte
		# Bare winter trees have no canopy to hide in.
		if not Season.is_winter():
			squirrel.trees = _tree_sprites
		add_child(squirrel)


# Now and then a stray cat wanders in from just off screen.
func _spawn_stray_cats(delta: float) -> void:
	_cat_timer -= delta
	if _cat_timer > 0.0:
		return
	_cat_timer = _rng.randf_range(30.0, 70.0)
	if _animals.get_child_count() >= MAX_STRAY_CATS:
		return
	var cx := _camera.get_screen_center_position().x
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var x := cx + side * (VIEW.x / 2.0 + 60.0)
	if x < 40.0 or x > _street_width - 40.0:
		side = -side
		x = cx + side * (VIEW.x / 2.0 + 60.0)
	_spawn_cat(x).walk_to(cx - side * _rng.randf_range(0.0, 400.0), 55.0)


func _spawn_cat(x: float) -> StrayCat:
	var cat := StrayCat.random(_rng)
	cat.position = Vector2(x, STRAY_CAT_Y)
	cat.bounds = Vector2(40.0, _street_width - 40.0)
	cat.charlotte = _charlotte
	_animals.add_child(cat)
	return cat


func _spawn_charlotte(x: float) -> Character:
	var charlotte := Character.new()
	charlotte.look = CharacterLook.charlotte()
	charlotte.step_sound = Sfx.step_for(true)
	charlotte.position = Vector2(x, CHARLOTTE_Y)
	charlotte.scale = Vector2.ONE * CHAR_SCALE
	add_child(charlotte)
	return charlotte


func _follow_charlotte() -> void:
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)


# ── Props ───────────────────────────────────────────────────────

func _build_props() -> void:
	_build_extra_props()
	_build_utility_poles()
	for cs in _cross_streets:
		add_child(CrossStreet.make(CrossStreet.Part.SIGNS, cs))
	for after in lamps_after:
		var lamp := _sprite(PropArt.lamppost(), 0.62)
		lamp.position = Vector2(_starts[after + 1] - 101.0 * 0.62, CURB_Y + 2.0 - 518.0 * 0.62)
		add_child(lamp)
	var hydrant_tex := PropArt.hydrant()
	for at in hydrants_at:
		var hydrant := _sprite(hydrant_tex, 0.62)
		hydrant.position = Vector2(_street_x(at) - 30.0 * 0.62, CURB_Y - 82.0 * 0.62)
		add_child(hydrant)
	var rack_tex := PropArt.rack()
	for at in racks_at:
		var rack := _sprite(rack_tex, 0.8)
		rack.position = Vector2(_street_x(at), CURB_Y - 2.0 - 90.0 * 0.8)
		add_child(rack)
		for hoop in [42.0, 112.0, 182.0]:
			if _rng.randf() < 0.6:
				var bike := _sprite(PropArt.bike(_rng), 0.85)
				bike.position = Vector2(rack.position.x + hoop * 0.8 - 75.0 * 0.85, CURB_Y + 2.0 - 90.0 * 0.85)
				bike.flip_h = _rng.randf() < 0.5
				add_child(bike)


# ── Helpers ─────────────────────────────────────────────────────

func _build_grade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var rect := ColorRect.new()
	rect.size = VIEW
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/grade.gdshader")
	mat.set_shader_parameter("sun_uv", SkyBackdrop.SUN_POS / VIEW)
	mat.set_shader_parameter("tint", Season.tint())
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _label(text: String, center: Vector2, size: Vector2, font_size: int, color: Color, outline: Color) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 3
	settings.outline_color = outline
	var label := Label.new()
	label.text = text
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = center - size / 2.0
	add_child(label)
	return label


func _sprite(tex: Texture2D, sprite_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.scale = Vector2.ONE * sprite_scale
	return sprite


func _save_screenshot(path: String) -> void:
	for i in 8:
		await get_tree().process_frame
	var wait := _arg("--wait=")
	if not wait.is_empty():
		await get_tree().create_timer(wait.to_float()).timeout
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _arg(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
