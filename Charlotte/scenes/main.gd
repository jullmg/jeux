extends Node2D

const VIEW := Vector2(1280, 720)
const HOUSE_BASE_Y := 592.0
const HOUSE_SCALE := 0.57
const CHAR_SCALE := 0.38
const CHARLOTTE_Y := 638.0
const NEIGHBOUR_Y := 612.0
const CURB_Y := 664.0
const TREE_SCALE := 0.55
const MARGIN := 30.0
# Charlotte's side of 6e Avenue seen from the sidewalk: Dandurand on the left, Holt on the right.
# Across each cross street, the first building of the next block (the school across Dandurand).
const LAYOUT: Array[String] = [
	"ecole", "rue_dandurand",
	"depanneur", "plex_01", "ruelle_verte",
	"triplex_exemple_2", "plex_02", "plex_03", "moderne", "plex_04",
	"duplex_voisin_gauche", "duplex_charlotte", "duplex_voisin_droite",
	"plex_05", "triplex_exemple_3", "plex_06", "plex_07", "plex_08", "plex_09",
	"ruelle", "coin_holt",
	"rue_holt", "coin_holt_est",
]
# Cross streets are gaps in the row (width in px at the facade line), drawn by CrossStreet.
const CROSS_STREETS := {"rue_dandurand": 560.0, "rue_holt": 520.0}
const TREES_AFTER: Array[int] = [2, 6, 8, 10, 13, 15, 17]
const LAMPS_AFTER: Array[int] = [4, 9, 14, 18]
const HYDRANTS_AT: Array[float] = [7.5, 16.3]
const RACKS_AT: Array[float] = [2.5, 12.55, 15.6]
const STRAY_CAT_Y := 646.0
const MAX_STRAY_CATS := 1

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


func _ready() -> void:
	_rng.seed = 2026
	add_child(SkyBackdrop.new())
	_starts = _layout_starts()
	_street_width = _starts[-1]
	Skyline.build(self, _street_width, VIEW.x)
	add_child(Birds.new())
	_build_cross_streets()
	_build_houses()
	_build_window_cats()
	_build_cat()
	var street := Street.new()
	street.width = _street_width
	add_child(street)
	for cs in _cross_streets:
		add_child(CrossStreet.make(CrossStreet.Part.GROUND, cs))
	var trees := _tree_textures()
	_build_tree_shadows(trees)
	_build_passersby()
	var start_x := _starts[LAYOUT.find("duplex_charlotte")] + 150.0
	if not is_nan(Transition.street_x):
		start_x = Transition.street_x
		Transition.street_x = NAN
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	# Charlotte stays on her block, up to the curbs (crossing comes later).
	_control.bounds = Vector2(_cross_streets[0].road_x(CHARLOTTE_Y).y + 8.0, _cross_streets[1].road_x(CHARLOTTE_Y).x - 8.0)
	_control.walk_top = HOUSE_BASE_Y - 200.0
	add_child(_control)
	_build_front_door()
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
	Transition.fade_in(self)
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _process(delta: float) -> void:
	_follow_charlotte()
	_spawn_stray_cats(delta)


# Charlotte's own front door (ground floor of her duplex): click it to go inside.
func _build_front_door() -> void:
	var origin := _house_origin(LAYOUT.find("duplex_charlotte"))
	var area := Rect2(origin + Vector2(278.0 - 48.0, 392.0) * HOUSE_SCALE, Vector2(96.0, 208.0) * HOUSE_SCALE)
	var door := DoorSpot.make(area, func():
		_control.enabled = false
		Transition.street_x = area.get_center().x
		Transition.change_scene(self, "res://scenes/house.tscn"))
	add_child(door)


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


func _follow_charlotte() -> void:
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)


func _spawn_charlotte(x: float) -> Character:
	var charlotte := Character.new()
	charlotte.look = CharacterLook.charlotte()
	charlotte.position = Vector2(x, CHARLOTTE_Y)
	charlotte.scale = Vector2.ONE * CHAR_SCALE
	add_child(charlotte)
	return charlotte


func _tex(art: String) -> Texture2D:
	if not _textures.has(art):
		_textures[art] = load("res://art/decor/%s.svg" % art)
	return _textures[art]


# Start x of each building along the street, plus the total street width at the end.
func _layout_starts() -> Array[float]:
	var starts: Array[float] = []
	var x := 0.0
	for art in LAYOUT:
		starts.append(x)
		x += CROSS_STREETS[art] if CROSS_STREETS.has(art) else (_tex(art).get_width() - 2.0 * MARGIN) * HOUSE_SCALE
	starts.append(x)
	return starts


func _street_x(at: float) -> float:
	var i := int(at)
	return lerpf(_starts[i], _starts[i + 1], at - i)


func _house_origin(i: int) -> Vector2:
	return Vector2(_starts[i] - MARGIN * HOUSE_SCALE, HOUSE_BASE_Y - _tex(LAYOUT[i]).get_height() * HOUSE_SCALE)


# Rue Dandurand (left, from the reference photos: the dépanneur's real front, the garage building, the
# back lane, the school across) and Rue Holt (right). The vistas go behind the houses.
func _build_cross_streets() -> void:
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", 1.0)
	dandurand.school = true
	dandurand.left_walls = [
		{"to": 2.6, "top": _house_top("ecole"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	dandurand.right_walls = [
		{"to": 0.35, "top": _house_top("depanneur"), "kind": "shop", "color": Color("#8A5A44")},
		{"to": 0.75, "top": 300.0, "kind": "garage", "color": Color("#7A4636")},
		{"to": 1.0, "kind": "gap"},
		{"to": 2.2, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 260.0, "kind": "plex", "color": Color("#C8A27A")},
	]
	var holt := _cross_street("rue_holt", "Rue Holt", -1.0)
	holt.left_walls = [
		{"to": 0.6, "top": _house_top("coin_holt"), "kind": "plex", "color": Color("#B5603F")},
		{"to": 0.85, "kind": "gap"},
		{"to": 2.4, "top": 290.0, "kind": "plex", "color": Color("#A8473A")},
		{"to": CrossStreet.FAR, "top": 320.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	holt.right_walls = [
		{"to": 0.7, "top": _house_top("coin_holt_est"), "kind": "plex", "color": Color("#9C6B4E")},
		{"to": 2.0, "top": 270.0, "kind": "plex", "color": Color("#8E3A2F")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B4513F")},
	]
	for cs in _cross_streets:
		add_child(cs)


func _cross_street(art: String, street_name: String, sign_side: float) -> CrossStreet:
	var i := LAYOUT.find(art)
	var cs := CrossStreet.new()
	cs.x0 = _starts[i]
	cs.x1 = _starts[i + 1]
	cs.street_name = street_name
	cs.sign_side = sign_side
	_cross_streets.append(cs)
	return cs


# World y of a building's roof line (its SVG's top margin is about 40 px).
func _house_top(art: String) -> float:
	return _house_origin(LAYOUT.find(art)).y + 40.0 * HOUSE_SCALE


func _build_houses() -> void:
	# Right to left, so outdoor stairs overlapping the next house stay visible.
	for i in range(LAYOUT.size() - 1, -1, -1):
		if CROSS_STREETS.has(LAYOUT[i]):
			continue
		var house := _sprite(_tex(LAYOUT[i]), HOUSE_SCALE)
		house.position = _house_origin(i)
		add_child(house)
		if LAYOUT[i] == "depanneur":
			_label("DÉPANNEUR XIN-XIN", house.position + Vector2(350, 379) * HOUSE_SCALE, Vector2(360, 30), 18, Color.WHITE, Color("#16285C"))
		elif LAYOUT[i] == "ruelle_verte":
			_label("RUELLE\nVERTE", house.position + Vector2(214, 416) * HOUSE_SCALE, Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


func _build_window_cats() -> void:
	var houses := []
	for i in LAYOUT.size():
		if not CROSS_STREETS.has(LAYOUT[i]):
			houses.append({"art": LAYOUT[i], "origin": _house_origin(i), "scale": HOUSE_SCALE})
	_window_cats = WindowCats.new()
	_window_cats.setup(houses)
	add_child(_window_cats)


func _build_cat() -> void:
	var cat := Cat.new()
	cat.position = _house_origin(LAYOUT.find("duplex_voisin_gauche")) + Vector2(300, 552) * HOUSE_SCALE
	cat.scale = Vector2.ONE * 0.7
	add_child(cat)


func _tree_textures() -> Array[Texture2D]:
	var trees: Array[Texture2D] = []
	for i in TREES_AFTER.size():
		trees.append(PropArt.tree(_rng))
	return trees


func _tree_origin(i: int) -> Vector2:
	return Vector2(_starts[TREES_AFTER[i] + 1] - 190.0 * TREE_SCALE, CURB_Y - 780.0 * TREE_SCALE)


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
		if LAYOUT[TREES_AFTER[i] + 1] in ["ruelle", "ruelle_verte"]:
			continue
		var shadow := _sprite(trees[i], TREE_SCALE)
		shadow.position = _tree_origin(i) + Vector2(80, 14)
		shadow.modulate = Color(0.22, 0.1, 0.12, 0.2)
		shadow.material = _sway(7.0, i * 1.7)
		add_child(shadow)


func _build_trees(trees: Array[Texture2D]) -> void:
	var leaf := PropArt.leaf()
	for i in trees.size():
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
	p.amount = 7
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


func _build_passersby() -> void:
	var ages := ["adult", "child", "senior", "teen"]
	for i in ages.size():
		var npc := Passerby.new()
		npc.look = CharacterLook.random(_rng, ages[i])
		npc.walk_speed = _rng.randf_range(120.0, 170.0) if ages[i] != "child" else _rng.randf_range(160.0, 210.0)
		npc.position = Vector2(_rng.randf_range(300.0, _street_width - 300.0), NEIGHBOUR_Y)
		npc.scale = Vector2.ONE * CHAR_SCALE
		npc.facing = 1 if _rng.randf() < 0.5 else -1
		npc.bounds = Vector2(80.0, _street_width - 80.0)
		npc.modulate = Color(0.94, 0.94, 0.96)
		add_child(npc)
		if ages[i] != "child" and _rng.randf() < 0.45:
			add_child(Dog.random(_rng, npc))


func _build_squirrels() -> void:
	for at in [4.2, 9.5, 14.6, 18.4]:
		var squirrel := Squirrel.new()
		var x := _street_x(at)
		squirrel.position = Vector2(x, 652)
		squirrel.scale = Vector2.ONE * 0.85
		squirrel.bounds = Vector2(maxf(x - 700.0, 60.0), minf(x + 700.0, _street_width - 60.0))
		squirrel.threat = _charlotte
		squirrel.trees = _tree_sprites
		add_child(squirrel)


func _build_props() -> void:
	for cs in _cross_streets:
		add_child(CrossStreet.make(CrossStreet.Part.SIGNS, cs))
	for after in LAMPS_AFTER:
		var lamp := _sprite(PropArt.lamppost(), 0.62)
		lamp.position = Vector2(_starts[after + 1] - 101.0 * 0.62, CURB_Y + 2.0 - 518.0 * 0.62)
		add_child(lamp)
	var hydrant_tex := PropArt.hydrant()
	for at in HYDRANTS_AT:
		var hydrant := _sprite(hydrant_tex, 0.62)
		hydrant.position = Vector2(_street_x(at) - 30.0 * 0.62, CURB_Y - 82.0 * 0.62)
		add_child(hydrant)
	var rack_tex := PropArt.rack()
	for at in RACKS_AT:
		var rack := _sprite(rack_tex, 0.8)
		rack.position = Vector2(_street_x(at), CURB_Y - 2.0 - 90.0 * 0.8)
		add_child(rack)
		for hoop in [42.0, 112.0, 182.0]:
			if _rng.randf() < 0.6:
				var bike := _sprite(PropArt.bike(_rng), 0.85)
				bike.position = Vector2(rack.position.x + hoop * 0.8 - 75.0 * 0.85, CURB_Y + 2.0 - 90.0 * 0.85)
				bike.flip_h = _rng.randf() < 0.5
				add_child(bike)


func _build_grade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var rect := ColorRect.new()
	rect.size = VIEW
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/grade.gdshader")
	mat.set_shader_parameter("sun_uv", SkyBackdrop.SUN_POS / VIEW)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _label(text: String, center: Vector2, size: Vector2, font_size: int, color: Color, outline: Color) -> void:
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


func _sprite(tex: Texture2D, sprite_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.scale = Vector2.ONE * sprite_scale
	return sprite


# Usage: Godot --path . -- --screenshot=/tmp/charlotte.png [--x=1234] [--wait=seconds]
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
