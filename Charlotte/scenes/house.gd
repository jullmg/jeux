extends Node2D
# ══════════════════════════════════════════════════════════════
# Inside Charlotte's flat, as a side-on cross-section (from reference/charlotte_house_inside):
# vestibule → oak glass doorway → salon (sofa, dining table) → hallway → kitchen at the back.
# Her bedroom ("chacha" on the door) is a separate area further right, reached through its door.
# Click the front door to go back out to the street.
# Usage: Godot --path . res://scenes/house.tscn -- --screenshot=/tmp/house.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const VIEW := Vector2(1280, 720)
const CEILING := 34.0
const WALL_BASE := 600.0
const FEET_Y := 668.0
const CHAR_SCALE := 0.5
const HALL := Vector2(0, 3960)
const BEDROOM := Vector2(5000, 6650)
const VESTIBULE_END := 640.0
const SALON_END := 2260.0
const KITCHEN_START := 3400.0
const CHACHA_DOOR_X := 3120.0
const BEDROOM_DOOR_X := 6440.0

var _charlotte: Character
var _camera: Camera2D
var _control := PlayerControl.new()
var _time := 0.0
# Candle glows that flicker: [sprite, base alpha, base scale].
var _flames: Array = []
var _pendant_pivot: Node2D


func _ready() -> void:
	var rooms := _Rooms.new()
	add_child(rooms)
	_build_vestibule()
	_build_salon()
	_build_hallway()
	_build_bedroom()
	_charlotte = Character.new()
	_charlotte.look = CharacterLook.charlotte()
	_charlotte.scale = Vector2.ONE * CHAR_SCALE
	_charlotte.walk_speed = 260.0
	_charlotte.position = Vector2(470.0, FEET_Y)
	_charlotte.facing = 1
	add_child(_charlotte)
	_control.charlotte = _charlotte
	_control.walk_top = WALL_BASE - 260.0
	add_child(_control)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	_build_doors()
	_build_foreground()
	_build_grade()
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		_charlotte.position.x = x_arg.to_float()
	_enter_area(BEDROOM if _charlotte.position.x >= BEDROOM.x else HALL)
	Transition.fade_in(self)
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _process(delta: float) -> void:
	_time += delta
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)
	for f in _flames:
		var flicker := 0.82 + 0.1 * sin(_time * 11.0) + 0.08 * sin(_time * 23.0 + 1.3)
		f[0].modulate.a = f[1] * flicker
		f[0].scale = Vector2.ONE * f[2] * (0.96 + 0.04 * flicker)
	if _pendant_pivot:
		_pendant_pivot.rotation = sin(_time * 0.9) * 0.012


# Camera limits and walking bounds for the hall/salon/vestibule strip or the bedroom.
func _enter_area(area: Vector2) -> void:
	_camera.limit_left = int(area.x)
	_camera.limit_right = int(area.y)
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW.y)
	_control.bounds = Vector2(area.x + 70.0, area.y - 70.0)
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)
	_camera.reset_smoothing()


func _build_doors() -> void:
	# Front door (its glass door leaf inside the vestibule frame) → back to the street.
	add_child(DoorSpot.make(Rect2(370, 204, 170, 396), func():
		_control.enabled = false
		Transition.change_scene(self, "res://scenes/main.tscn")))
	add_child(DoorSpot.make(Rect2(CHACHA_DOOR_X, 170, 150, 430), func(): _go_through(BEDROOM_DOOR_X - 40.0, BEDROOM, -1)))
	add_child(DoorSpot.make(Rect2(BEDROOM_DOOR_X, 170, 150, 430), func(): _go_through(CHACHA_DOOR_X + 75.0, HALL, 1)))
	# The dresser's drawers (under the terrarium): her wardrobe.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 40.0, 444, 276, 162), _open_wardrobe, BEDROOM.x + 180.0))


func _open_wardrobe() -> void:
	_control.enabled = false
	var wardrobe := Wardrobe.new(_charlotte.look)
	wardrobe.closed.connect(func(look: CharacterLook):
		if look:
			CharacterLook.dress_charlotte(look)
			_charlotte.set_look(CharacterLook.charlotte())
			_twirl()
		_control.enabled = true)
	add_child(wardrobe)


# A happy little spin in the new outfit.
func _twirl() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(func(): _charlotte.facing = -_charlotte.facing)
		tween.tween_interval(0.12)


func _go_through(x: float, area: Vector2, facing: int) -> void:
	_control.enabled = false
	Transition.through_black(self, func():
		_control.stop()
		_charlotte.position.x = x
		_charlotte.facing = facing
		_enter_area(area)
		_control.enabled = true)


# ─────────────────────────────────────────────────────────────
# Furniture
# ─────────────────────────────────────────────────────────────

## Puts a texture with its bottom-left corner at (x, bottom). `shadow`: "wall" casts a soft shadow onto
## the wall behind (hung things), "floor" also grounds it with a contact shadow (standing furniture).
func _put(tex: Texture2D, x: float, bottom: float, s := 1.0, shadow := "") -> Sprite2D:
	if shadow != "":
		var cast := Sprite2D.new()
		cast.texture = tex
		cast.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		cast.centered = false
		cast.scale = Vector2.ONE * s
		cast.position = Vector2(x + 10.0, bottom - tex.get_height() * s + 6.0)
		cast.modulate = Color(0.25, 0.12, 0.05, 0.16)
		add_child(cast)
	if shadow == "floor":
		_floor_shadow(x + tex.get_width() * s * 0.5, bottom, tex.get_width() * s * 0.55)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.scale = Vector2.ONE * s
	sprite.position = Vector2(x, bottom - tex.get_height() * s)
	add_child(sprite)
	return sprite


func _build_vestibule() -> void:
	_put(InteriorArt.coat_shelf(), 14.0, 430.0, 0.9, "wall")
	_plate(250.0, 330.0, false)
	_put(InteriorArt.radiator(96.0, 150.0), 186.0, WALL_BASE, 1.0, "floor")
	_put(InteriorArt.front_door(), 290.0, WALL_BASE)
	_daylight(Vector2(330.0, 230.0), 240.0, 0.08)
	_put(InteriorArt.doormat(), 345.0, 630.0)
	_put(InteriorArt.backpack(), 40.0, 616.0, 0.9, "floor")
	_put(InteriorArt.boots(), 540.0, 612.0, 0.8, "floor")
	_put(InteriorArt.floor_clutter(), 150.0, 622.0)
	_ceiling_light(320.0)
	_put(InteriorArt.oak_doorway(), VESTIBULE_END, WALL_BASE)
	_put(InteriorArt.oak_glass_door(), VESTIBULE_END + 230.0, WALL_BASE, 1.0, "wall")


func _build_salon() -> void:
	_put(InteriorArt.rug(), 900.0, 694.0, 0.9)
	_plate(1700.0, 560.0, true)
	_put(InteriorArt.monstera(), 860.0, 606.0, 0.85, "floor")
	for i in 3:
		_put(InteriorArt.poster(i), 1030.0 + i * 130.0, 340.0, 0.85, "wall")
	_put(InteriorArt.floor_lamp(), 1470.0, 604.0, 0.9, "floor")
	_glow(Vector2(1524.0, 360.0), 200.0, Color(1.0, 0.82, 0.5, 0.4))
	_put(InteriorArt.sofa(), 960.0, 606.0, 0.85, "floor")
	_put(InteriorArt.side_table(), 1390.0, 610.0, 0.8, "floor")
	_put(InteriorArt.window(170.0, 300.0), 1580.0, 470.0, 1.0, "wall")
	_daylight(Vector2(1580.0, 170.0), 170.0, 0.12)
	_plate(1780.0, 330.0, false)
	_put(InteriorArt.dining_table(), 1780.0, 606.0, 0.85, "floor")
	_pendant(1984.0, 310.0)
	_put(InteriorArt.black_shelf(), 2110.0, WALL_BASE, 0.7, "floor")


func _build_hallway() -> void:
	_ceiling_light(2600.0)
	_ceiling_light(3200.0)
	_put(InteriorArt.runner(980.0), 2320.0, 690.0)
	_put(InteriorArt.black_coats(), 2330.0, 470.0, 0.8, "wall")
	_put(InteriorArt.photo_row(), 2520.0, 260.0, 0.8, "wall")
	_put(InteriorArt.tv(), 2560.0, 400.0, 0.8, "wall")
	_build_tv(Vector2(2560.0, 400.0 - 140.0 * 0.8), 0.8)
	_plate(2480.0, 330.0, false)
	_put(InteriorArt.radiator(160.0, 150.0), 2790.0, WALL_BASE, 1.0, "floor")
	_put(InteriorArt.recycling_bin(), 2985.0, 608.0, 1.0, "floor")
	_put(InteriorArt.panel_door(), CHACHA_DOOR_X, WALL_BASE)
	_chacha_sign(Vector2(CHACHA_DOOR_X + 75.0, 330.0))
	_put(InteriorArt.monstera(), 3300.0, 606.0, 0.55, "floor")
	_put(InteriorArt.kitchen(), KITCHEN_START, WALL_BASE)
	_daylight(Vector2(KITCHEN_START + 322.0, 260.0), 126.0, 0.1)
	_ceiling_light(KITCHEN_START + 200.0)


func _build_bedroom() -> void:
	var x := BEDROOM.x
	_put(InteriorArt.round_rug(), x + 380.0, 700.0, 1.0)
	_put(InteriorArt.window(180.0, 300.0), x + 90.0, 420.0, 1.0, "wall")
	_daylight(Vector2(x + 90.0, 120.0), 180.0, 0.14)
	var tank := _put(InteriorArt.terrarium(false), x + 30.0, 606.0, 0.85, "floor")
	var hamster := Hamster.new()
	hamster.position = tank.position
	hamster.scale = tank.scale
	add_child(hamster)
	_put(InteriorArt.terrarium(true), x + 30.0, 606.0, 0.85)
	_put(InteriorArt.flower_painting(), x + 470.0, 330.0, 0.8, "wall")
	_put(InteriorArt.bed(), x + 360.0, 608.0, 0.8, "floor")
	_put(InteriorArt.kid_table(), x + 830.0, 612.0, 0.75, "floor")
	_put(InteriorArt.book_ledges(), x + 960.0, 470.0, 0.8, "wall")
	_put(InteriorArt.fluffy_chair(), x + 960.0, 606.0, 0.8, "floor")
	_put(InteriorArt.strawberry_poster(), x + 1130.0, 300.0, 0.8, "wall")
	_plate(x + 1300.0, 330.0, false)
	_put(InteriorArt.desk(), x + 1110.0, 606.0, 0.85, "floor")
	_put(InteriorArt.laundry_basket(), x + 1300.0, 618.0, 0.8, "floor")
	_put(InteriorArt.plushies(), x + 770.0, 626.0, 0.8, "floor")
	_put(InteriorArt.panel_door(), BEDROOM_DOOR_X, WALL_BASE)
	var flame := _glow(Vector2(x + 30.0 + 262.0 * 0.85, 606.0 - 240.0 * 0.85), 80.0, Color(1.0, 0.75, 0.4, 0.5))
	_flames.append([flame, 1.0, flame.scale.x])
	_put(InteriorArt.bunting(440.0), x + 650.0, 230.0)
	var lights := _FairyLights.new()
	lights.from_x = x + 40.0
	lights.count = 40
	add_child(lights)


# Paper sign taped to the bedroom door, each letter in a different marker colour.
func _chacha_sign(center: Vector2) -> void:
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-58, -16), Vector2(58, -19), Vector2(60, 17), Vector2(-57, 19)])
	paper.color = Color("#FBFAF6")
	paper.position = center
	add_child(paper)
	var colors := ["#7E57C2", "#F2A7C9", "#1FB5C4", "#E04F5F", "#FF8A3D", "#3E8E5A"]
	var word := "chacha"
	for i in word.length():
		var settings := LabelSettings.new()
		settings.font_size = 24
		settings.font_color = Color(colors[i])
		var letter := Label.new()
		letter.text = word[i]
		letter.label_settings = settings
		letter.position = center + Vector2(-50.0 + i * 17.0, -18.0 + (i % 2) * 2.0)
		letter.rotation = deg_to_rad(-4.0 + (i * 37) % 9)
		add_child(letter)


func _plate(x: float, y: float, outlet: bool) -> void:
	_put(InteriorArt.wall_plate(outlet), x, y, 0.8)


func _floor_shadow(cx: float, y: float, rx: float) -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(rx, 7.0), 0.0, 24)
	shadow.color = Color(0.25, 0.12, 0.04, 0.22)
	shadow.position = Vector2(cx + 6.0, y + 2.0)
	add_child(shadow)


# Daylight from a window: a soft beam slanting down to a warm patch on the floor.
func _daylight(top_left: Vector2, width: float, strength: float) -> void:
	var beam := Polygon2D.new()
	var floor_y := 650.0
	var drop := (floor_y - top_left.y) * 0.45
	beam.polygon = PackedVector2Array([top_left, top_left + Vector2(width, 0), Vector2(top_left.x + width + drop, floor_y), Vector2(top_left.x + drop, floor_y)])
	beam.vertex_colors = PackedColorArray([Color(1, 0.96, 0.85, strength), Color(1, 0.96, 0.85, strength), Color(1, 0.92, 0.75, strength * 0.3), Color(1, 0.92, 0.75, strength * 0.3)])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beam.material = mat
	add_child(beam)
	var patch := Polygon2D.new()
	patch.polygon = PackedVector2Array([Vector2(top_left.x + drop - 10, 616), Vector2(top_left.x + width + drop + 10, 616), Vector2(top_left.x + width + drop + 50, 700), Vector2(top_left.x + drop + 20, 700)])
	patch.color = Color(1.0, 0.9, 0.65, strength * 1.4)
	patch.material = mat
	add_child(patch)
	# Dust motes drifting in the beam.
	var motes := CPUParticles2D.new()
	motes.position = top_left + Vector2(width * 0.5 + drop * 0.5, (floor_y - top_left.y) * 0.5)
	motes.amount = int(width / 8.0)
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(width * 0.45, (floor_y - top_left.y) * 0.45)
	motes.direction = Vector2(0.3, -1)
	motes.spread = 180.0
	motes.gravity = Vector2(1.5, 2.0)
	motes.initial_velocity_min = 1.0
	motes.initial_velocity_max = 6.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.2
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 0.97, 0.88, 0), Color(1, 0.97, 0.88, 0.7), Color(1, 0.97, 0.88, 0.7), Color(1, 0.97, 0.88, 0)])
	motes.color_ramp = fade
	motes.material = mat
	add_child(motes)


func _ceiling_light(x: float) -> void:
	var fixture := Polygon2D.new()
	fixture.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(22, 12), Vector2(-22, 12)])
	fixture.color = Color("#F7F5EF")
	fixture.position = Vector2(x, CEILING)
	add_child(fixture)
	_glow(Vector2(x, CEILING + 20.0), 220.0, Color(1.0, 0.92, 0.75, 0.22))


# Globe pendant hanging from a medallion; it sways very gently.
func _pendant(x: float, y: float) -> void:
	_put(InteriorArt.medallion(), x - 40.0, CEILING + 60.0)
	_pendant_pivot = Node2D.new()
	_pendant_pivot.position = Vector2(x, CEILING + 20.0)
	add_child(_pendant_pivot)
	var cord := Line2D.new()
	cord.points = PackedVector2Array([Vector2.ZERO, Vector2(0, y - 30.0 - CEILING - 20.0)])
	cord.width = 2.0
	cord.default_color = Color("#8A7A5A")
	_pendant_pivot.add_child(cord)
	var globe := Sprite2D.new()
	globe.texture = InteriorArt.globe()
	globe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	globe.position = Vector2(0, y - CEILING - 20.0)
	_pendant_pivot.add_child(globe)
	var glow := _glow(Vector2(x, y), 260.0, Color(1.0, 0.88, 0.6, 0.35))
	glow.reparent(_pendant_pivot)


# The TV's picture over the InteriorArt.tv() frame at `top_left`: click to turn on and change channels.
func _build_tv(top_left: Vector2, s: float) -> void:
	var screen := TvScreen.new()
	screen.position = top_left + Vector2(12, 12) * s
	screen.scale = Vector2.ONE * s
	screen.stand_x = top_left.x + 110.0 * s
	screen.glow = _glow(top_left + Vector2(110, 120) * s, 320.0, Color(1, 1, 1, 0.3))
	add_child(screen)


func _glow(center: Vector2, radius: float, color: Color) -> Sprite2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([color, Color(color, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	var sprite := Sprite2D.new()
	sprite.texture = t
	sprite.scale = Vector2.ONE * radius * 2.0 / 64.0
	sprite.position = center
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	add_child(sprite)
	return sprite


# Out-of-focus things right in front of the camera, scrolling faster than the room for depth.
func _build_foreground() -> void:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(Foreground.SCROLL, 1.0)
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# [world x where it should pass the screen centre, kind]
	for item in [[700.0, "plant"], [1900.0, "plant"], [2900.0, "plant"], [5400.0, "plushie"], [6250.0, "plant"]]:
		var at: float = item[0]
		var x := 640.0 + (at - 640.0) * Foreground.SCROLL
		match item[1]:
			"plant":
				Foreground.add(layer, Foreground.shrub(rng), Vector2(x, 720.0 + 100.0), Vector2(260, 170)).modulate = Color(0.45, 0.42, 0.38)
			"plushie":
				Foreground.add(layer, '<circle cx="90" cy="110" r="70" fill="#F2A7C9"/><circle cx="40" cy="50" r="28" fill="#F2A7C9"/><circle cx="140" cy="50" r="28" fill="#F2A7C9"/>', Vector2(x, 720.0 + 95.0), Vector2(180, 180)).modulate = Color(0.55, 0.5, 0.5)


func _build_grade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var rect := ColorRect.new()
	rect.size = VIEW
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/grade.gdshader")
	mat.set_shader_parameter("sun_uv", Vector2(-2.0, -2.0))
	mat.set_shader_parameter("bloom", 0.0)
	mat.set_shader_parameter("rays", 0.0)
	mat.set_shader_parameter("tint", Vector3(1.04, 1.0, 0.93))
	mat.set_shader_parameter("vignette", 0.6)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


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


# ─────────────────────────────────────────────────────────────
# Walls, ceiling, mouldings and the honey-coloured plank floor
# ─────────────────────────────────────────────────────────────

class _Rooms:
	extends Node2D

	# [start, end, wall colour, baseboard colour]
	const WALLS := [
		[0.0, 640.0, "#ECE8DF", "#F4F1EA"],
		[640.0, 2260.0, "#E9DCC2", "#6E4424"],
		[2260.0, 3960.0, "#EEEBE5", "#F4F1EA"],
		[5000.0, 6650.0, "#E4E3DF", "#6E4424"],
	]

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for w in WALLS:
			_room(w[0], w[1], Color(w[2]), Color(w[3]), rng)
		# Oak chair rail in the vestibule, white corner trim where the salon opens onto the hall.
		draw_rect(Rect2(0, 420, 640, 12), Color("#B07A44"))
		draw_rect(Rect2(0, 430, 640, 3), Color("#7A4A26"))
		draw_rect(Rect2(2248, 34, 24, 566), Color("#F4F1EA"))
		draw_line(Vector2(2248, 34), Vector2(2248, 600), Color("#C9C2B4"), 2.0)
		draw_line(Vector2(2272, 34), Vector2(2272, 600), Color("#C9C2B4"), 2.0)
		# Casings around the two bedroom doors.
		for x in [3120.0, 6440.0]:
			draw_rect(Rect2(x - 16, 154, 182, 446), Color("#7A4A26"))
			draw_rect(Rect2(x - 10, 160, 170, 440), Color("#9A5E2C"))

	func _room(x0: float, x1: float, wall: Color, base: Color, rng: RandomNumberGenerator) -> void:
		var w := x1 - x0
		var ceiling := PackedColorArray([Color("#F6F4EF"), Color("#F6F4EF"), Color("#E6E1D8"), Color("#E6E1D8")])
		draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, 34), Vector2(x0, 34)]), ceiling)
		var shade := PackedColorArray([wall.lightened(0.04), wall.lightened(0.04), wall.darkened(0.07), wall.darkened(0.07)])
		draw_polygon(PackedVector2Array([Vector2(x0, 34), Vector2(x1, 34), Vector2(x1, 600), Vector2(x0, 600)]), shade)
		# Crown moulding: cove, fillet and bead, with a soft shadow on the wall below.
		draw_rect(Rect2(x0, 34, w, 10), Color("#FBFAF6"))
		draw_rect(Rect2(x0, 44, w, 6), Color("#E3DDD2"))
		draw_rect(Rect2(x0, 50, w, 5), Color("#F7F5F0"))
		draw_line(Vector2(x0, 55), Vector2(x1, 55), Color("#CFC8BA"), 1.5)
		var cove := PackedColorArray([Color(0.2, 0.1, 0.04, 0.12), Color(0.2, 0.1, 0.04, 0.12), Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.0)])
		draw_polygon(PackedVector2Array([Vector2(x0, 56), Vector2(x1, 56), Vector2(x1, 90), Vector2(x0, 90)]), cove)
		# Plaster: faint vertical variation so the wall isn't a flat sheet.
		var px := x0
		while px < x1:
			var pw := rng.randf_range(60.0, 160.0)
			draw_rect(Rect2(px, 56, minf(pw, x1 - px), 522), Color(1, 1, 1, rng.randf_range(0.0, 0.03)))
			px += pw
		for edge in [[x0, 1.0], [x1, -1.0]]:
			var ex: float = edge[0]
			var d: float = edge[1]
			var corner := PackedColorArray([Color(0.2, 0.1, 0.04, 0.14), Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.14)])
			draw_polygon(PackedVector2Array([Vector2(ex, 34), Vector2(ex + d * 60.0, 34), Vector2(ex + d * 60.0, 600), Vector2(ex, 600)]), corner)
		draw_rect(Rect2(x0, 578, w, 22), base)
		draw_rect(Rect2(x0, 578, w, 3), base.lightened(0.25))
		# Floor: rows of planks, taller towards the camera, with staggered seams and a soft sheen.
		draw_rect(Rect2(x0, 600, w, 120), Color("#C68748"))
		var y := 600.0
		var row := 0
		var tones := [Color("#C58546"), Color("#D19355"), Color("#BC7B3F"), Color("#CB8C4E")]
		while y < 720.0:
			var h := 8.0 + row * 3.0
			var x := x0 - rng.randf_range(0.0, 200.0)
			while x < x1:
				var plank := rng.randf_range(160.0, 320.0)
				var a := maxf(x, x0)
				var b := minf(x + plank, x1)
				draw_rect(Rect2(a, y, b - a, h), tones[rng.randi_range(0, tones.size() - 1)])
				draw_line(Vector2(b, y), Vector2(b, y + h), Color("#8E5A2C"), 1.2)
				x += plank
			draw_line(Vector2(x0, y), Vector2(x1, y), Color("#9C6434"), 1.0)
			y += h
			row += 1
		draw_rect(Rect2(x0, 600, w, 6), Color(0.25, 0.12, 0.04, 0.25))
		var sx := x0 + 120.0
		while sx < x1:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, 604), Vector2(sx + 80, 604), Vector2(sx + 30, 720), Vector2(sx - 60, 720)]), Color(1, 1, 1, 0.07))
			sx += rng.randf_range(400.0, 700.0)


# Warm fairy lights strung along the bedroom crown moulding, each twinkling at its own pace.
class _FairyLights:
	extends Node2D
	var from_x := 0.0
	var count := 40
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var wire := PackedVector2Array()
		for i in count:
			wire.append(_bulb(i) + Vector2(0, -4))
		draw_polyline(wire, Color("#8A8478"), 1.2, true)
		for i in count:
			var p := _bulb(i)
			var tw := 0.65 + 0.35 * sin(_t * (1.3 + (i * 7) % 5 * 0.3) + i * 1.7)
			draw_circle(p, 11.0, Color(1.0, 0.82, 0.45, 0.14 * tw))
			draw_circle(p, 6.0, Color(1.0, 0.86, 0.5, 0.22 * tw))
			draw_circle(p, 3.2, Color(1.0, 0.93, 0.7).lerp(Color("#FFF8E6"), tw))

	func _bulb(i: int) -> Vector2:
		return Vector2(from_x + i * 40.0, 64.0 + sin(i * 0.9) * 6.0)
