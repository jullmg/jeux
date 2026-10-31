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
	_build_grade()
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		_charlotte.position.x = x_arg.to_float()
	_enter_area(BEDROOM if _charlotte.position.x >= BEDROOM.x else HALL)
	Transition.fade_in(self)
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _process(_delta: float) -> void:
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)


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

## Puts a texture with its bottom-left corner at (x, bottom).
func _put(tex: Texture2D, x: float, bottom: float, s := 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.scale = Vector2.ONE * s
	sprite.position = Vector2(x, bottom - tex.get_height() * s)
	add_child(sprite)
	return sprite


func _build_vestibule() -> void:
	_put(InteriorArt.coat_shelf(), 14.0, 430.0, 0.9)
	_put(InteriorArt.radiator(96.0, 150.0), 186.0, WALL_BASE)
	_put(InteriorArt.front_door(), 290.0, WALL_BASE)
	_put(InteriorArt.backpack(), 40.0, 616.0, 0.9)
	_put(InteriorArt.floor_clutter(), 150.0, 622.0)
	_ceiling_light(320.0)
	_put(InteriorArt.oak_doorway(), VESTIBULE_END, WALL_BASE)
	_put(InteriorArt.oak_glass_door(), VESTIBULE_END + 230.0, WALL_BASE)


func _build_salon() -> void:
	_put(InteriorArt.rug(), 900.0, 694.0, 0.9)
	for i in 3:
		_put(InteriorArt.poster(i), 1030.0 + i * 130.0, 340.0, 0.85)
	_put(InteriorArt.sofa(), 960.0, 606.0, 0.85)
	_put(InteriorArt.dining_table(), 1580.0, 606.0, 0.85)
	_pendant(1784.0, 310.0)
	_put(InteriorArt.black_shelf(), 2030.0, WALL_BASE, 0.9)


func _build_hallway() -> void:
	_ceiling_light(2600.0)
	_ceiling_light(3200.0)
	_put(InteriorArt.black_coats(), 2330.0, 470.0, 0.8)
	_put(InteriorArt.tv(), 2540.0, 380.0, 0.9)
	_put(InteriorArt.radiator(160.0, 150.0), 2790.0, WALL_BASE)
	_put(InteriorArt.recycling_bin(), 2985.0, 608.0)
	_put(InteriorArt.panel_door(), CHACHA_DOOR_X, WALL_BASE)
	_chacha_sign(Vector2(CHACHA_DOOR_X + 75.0, 330.0))
	_put(InteriorArt.kitchen(), KITCHEN_START, WALL_BASE)
	_ceiling_light(KITCHEN_START + 200.0)


func _build_bedroom() -> void:
	var x := BEDROOM.x
	_put(InteriorArt.flower_painting(), x + 70.0, 250.0, 0.8)
	_put(InteriorArt.dresser_terrarium(), x + 30.0, 606.0, 0.85)
	_put(InteriorArt.bed(), x + 360.0, 608.0, 0.8)
	_put(InteriorArt.kid_table(), x + 830.0, 612.0, 0.75)
	_put(InteriorArt.book_ledges(), x + 960.0, 470.0, 0.8)
	_put(InteriorArt.fluffy_chair(), x + 960.0, 606.0, 0.8)
	_put(InteriorArt.strawberry_poster(), x + 1130.0, 300.0, 0.8)
	_put(InteriorArt.desk(), x + 1110.0, 606.0, 0.85)
	_put(InteriorArt.panel_door(), BEDROOM_DOOR_X, WALL_BASE)
	_glow(Vector2(x + 30.0 + 262.0 * 0.85, 606.0 - 230.0 * 0.85), 70.0, Color(1.0, 0.75, 0.4, 0.45))


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


func _ceiling_light(x: float) -> void:
	var fixture := Polygon2D.new()
	fixture.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(22, 12), Vector2(-22, 12)])
	fixture.color = Color("#F7F5EF")
	fixture.position = Vector2(x, CEILING)
	add_child(fixture)
	_glow(Vector2(x, CEILING + 20.0), 220.0, Color(1.0, 0.92, 0.75, 0.22))


func _pendant(x: float, y: float) -> void:
	_put(InteriorArt.medallion(), x - 40.0, CEILING + 60.0)
	var cord := Line2D.new()
	cord.points = PackedVector2Array([Vector2(x, CEILING + 20.0), Vector2(x, y - 30.0)])
	cord.width = 2.0
	cord.default_color = Color("#8A7A5A")
	add_child(cord)
	_put(InteriorArt.globe(), x - 35.0, y + 35.0)
	_glow(Vector2(x, y), 260.0, Color(1.0, 0.88, 0.6, 0.35))


func _glow(center: Vector2, radius: float, color: Color) -> void:
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
		# Fairy lights along the bedroom crown moulding.
		for i in 40:
			var p := Vector2(5040.0 + i * 40.0, 52.0 + sin(i * 0.9) * 6.0 + 8.0)
			draw_circle(p, 9.0, Color(1.0, 0.85, 0.5, 0.18))
			draw_circle(p, 3.2, Color("#FFE9A8"))

	func _room(x0: float, x1: float, wall: Color, base: Color, rng: RandomNumberGenerator) -> void:
		var w := x1 - x0
		draw_rect(Rect2(x0, 0, w, 34), Color("#F3F1EC"))
		var shade := PackedColorArray([wall.lightened(0.04), wall.lightened(0.04), wall.darkened(0.07), wall.darkened(0.07)])
		draw_polygon(PackedVector2Array([Vector2(x0, 34), Vector2(x1, 34), Vector2(x1, 600), Vector2(x0, 600)]), shade)
		draw_rect(Rect2(x0, 34, w, 14), Color("#F7F5F0"))
		draw_rect(Rect2(x0, 48, w, 4), Color("#D9D2C4"))
		draw_rect(Rect2(x0, 52, w, 18), Color(0, 0, 0, 0.04))
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
