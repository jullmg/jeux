extends Node2D

const SIDEWALK_Y := 655.0
const GROUND_Y := 690.0
const HOUSE_SCALE := 0.62
const CHARLOTTE_SCALE := 0.45
const TREE_SCALE := 0.6
const MARGIN := 30.0
# Charlotte's side of 6e Avenue seen from the sidewalk: Dandurand on the left, Holt on the right.
const LAYOUT: Array[String] = [
	"depanneur", "plex_01", "ruelle",
	"triplex_exemple_2", "plex_02", "plex_03", "moderne", "plex_04",
	"duplex_voisin_gauche", "duplex_charlotte", "duplex_voisin_droite",
	"plex_05", "triplex_exemple_3", "plex_06", "plex_07", "plex_08", "plex_09",
	"ruelle", "coin_holt",
]
const TREES_AFTER: Array[int] = [4, 6, 8, 11, 13, 15]

var _street_width := 0.0
var _textures := {}
var _charlotte: Charlotte
var _camera: Camera2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#BFE3F2"))
	var starts := _layout_starts()
	_street_width = starts[-1]
	_build_far_rooftops()
	_build_houses(starts)
	_build_trees(starts)
	_build_street_sign(100.0, "Rue Dandurand")
	_build_street_sign(_street_width - 100.0, "Rue Holt")
	var start_x := starts[LAYOUT.find("duplex_charlotte")] + 150.0
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_charlotte = _spawn(Vector2(start_x, GROUND_Y))
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = int(_street_width)
	_camera.limit_top = 0
	_camera.limit_bottom = 720
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	_follow_charlotte()
	_camera.reset_smoothing()
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _draw() -> void:
	draw_rect(Rect2(0, SIDEWALK_Y, _street_width, 720 - SIDEWALK_Y), Color("#CFCBC4"))
	draw_rect(Rect2(0, SIDEWALK_Y, _street_width, 6), Color("#B3AEA6"))
	for x in range(0, int(_street_width), 120):
		draw_line(Vector2(x, SIDEWALK_Y + 6), Vector2(x - 30, 720), Color("#B9B4AC"), 2.0)


func _process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	_charlotte.is_walking = dir != 0.0
	if dir != 0.0:
		_charlotte.facing = 1 if dir > 0.0 else -1
		_charlotte.position.x = clampf(_charlotte.position.x + dir * Charlotte.WALK_SPEED * delta, 60.0, _street_width - 60.0)
	_follow_charlotte()


func _follow_charlotte() -> void:
	_camera.position = Vector2(_charlotte.position.x, 360)


func _spawn(pos: Vector2) -> Charlotte:
	var charlotte := Charlotte.new()
	charlotte.position = pos
	charlotte.scale = Vector2.ONE * CHARLOTTE_SCALE
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
		x += (_tex(art).get_width() - 2.0 * MARGIN) * HOUSE_SCALE
	starts.append(x)
	return starts


func _build_far_rooftops() -> void:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(0.4, 1.0)
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := -200.0
	while x < _street_width:
		var w := rng.randf_range(140, 260)
		var top := rng.randf_range(60, 160)
		var block := Polygon2D.new()
		block.polygon = PackedVector2Array([Vector2(x, top), Vector2(x + w, top), Vector2(x + w, SIDEWALK_Y), Vector2(x, SIDEWALK_Y)])
		block.color = Color("#9DB8C9").darkened(rng.randf_range(0.0, 0.12))
		layer.add_child(block)
		x += w - 4


func _build_houses(starts: Array[float]) -> void:
	# Right to left, so outdoor stairs overlapping the next house stay visible.
	for i in range(LAYOUT.size() - 1, -1, -1):
		var tex := _tex(LAYOUT[i])
		var house := _sprite(tex, HOUSE_SCALE)
		house.position = Vector2(starts[i] - MARGIN * HOUSE_SCALE, SIDEWALK_Y + 5.0 - tex.get_height() * HOUSE_SCALE)
		add_child(house)
		if LAYOUT[i] == "depanneur":
			_label("DÉPANNEUR", house.position + Vector2(350, 379) * HOUSE_SCALE, Vector2(360, 30), 22, Color("#FFD23F"), Color("#1E3A28"))


func _build_trees(starts: Array[float]) -> void:
	var tex := _tex("tree")
	for i in TREES_AFTER:
		var tree := _sprite(tex, TREE_SCALE)
		tree.position = Vector2(starts[i + 1] + 6.0 - 170.0 * TREE_SCALE, SIDEWALK_Y + 20.0 - 760.0 * TREE_SCALE)
		add_child(tree)


# Montreal-style blue street name plates on a pole.
func _build_street_sign(x: float, cross_street: String) -> void:
	var base := Vector2(x, SIDEWALK_Y + 24.0)
	var pole := ColorRect.new()
	pole.color = Color("#5A5F63")
	pole.position = base + Vector2(-3, -310)
	pole.size = Vector2(6, 310)
	add_child(pole)
	var names := [cross_street, "6e Avenue"]
	for i in names.size():
		var top_left := base + Vector2(-80, -300 + i * 38)
		var border := ColorRect.new()
		border.color = Color.WHITE
		border.position = top_left
		border.size = Vector2(160, 32)
		add_child(border)
		var plate := ColorRect.new()
		plate.color = Color("#1D4F91")
		plate.position = top_left + Vector2(3, 3)
		plate.size = Vector2(154, 26)
		add_child(plate)
		_label(names[i], top_left + Vector2(80, 16), Vector2(154, 26), 17, Color.WHITE, Color("#1D4F91"))


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
	sprite.centered = false
	sprite.scale = Vector2.ONE * sprite_scale
	return sprite


# Usage: Godot --path . -- --screenshot=/tmp/charlotte.png [--x=1234]
func _save_screenshot(path: String) -> void:
	for i in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _arg(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
