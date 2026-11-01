class_name Interior
extends Node2D
## Base for an indoor scene seen side-on as a cross-section: Charlotte and her controls, the camera and the
## areas it can be limited to, going through doors, placing furniture (InteriorArt textures) with their
## shadows, and the lighting (window daylight, lamp glows, ceiling lights, swaying pendants, flickering
## candles). A scene extends it, builds a RoomShell and its furniture back to front, then calls
## _spawn_charlotte() and _finish(). See scenes/house.gd.

const VIEW := Vector2(1280, 720)
const CEILING := RoomShell.CEILING
const WALL_BASE := RoomShell.WALL_BASE
const FEET_Y := 668.0
const CHAR_SCALE := 0.5

var _charlotte: Character
var _camera: Camera2D
var _control := PlayerControl.new()
var _time := 0.0
# Candle glows that flicker: [sprite, base alpha, base scale].
var _flames: Array = []
# Pendant lamps that sway very gently.
var _swaying: Array[Node2D] = []


func _process(delta: float) -> void:
	_time += delta
	if _camera:
		_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)
	for f in _flames:
		var flicker := 0.82 + 0.1 * sin(_time * 11.0) + 0.08 * sin(_time * 23.0 + 1.3)
		f[0].modulate.a = f[1] * flicker
		f[0].scale = Vector2.ONE * f[2] * (0.96 + 0.04 * flicker)
	for i in _swaying.size():
		_swaying[i].rotation = sin(_time * 0.9 + i * 1.3) * 0.012


# ── Setup ───────────────────────────────────────────────────────

## Adds Charlotte (dressed as she chose), her controls and the camera. `--x=` on the command line overrides x.
func _spawn_charlotte(x: float, facing := 1) -> void:
	_charlotte = Character.new()
	_charlotte.look = CharacterLook.charlotte()
	_charlotte.fidgets = true
	_charlotte.scale = Vector2.ONE * CHAR_SCALE
	_charlotte.walk_speed = 260.0
	_charlotte.step_sound = Sfx.step_for(false)
	_charlotte.position = Vector2(x, FEET_Y)
	_charlotte.facing = facing
	if LostCats.carrying() != "":
		_charlotte.carry.call_deferred(LostCats.held(LostCats.carrying()))
	if not is_nan(Transition.inside_x):
		_charlotte.position.x = Transition.inside_x
		Transition.inside_x = NAN
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		_charlotte.position.x = x_arg.to_float()
	add_child(_charlotte)
	_control.charlotte = _charlotte
	_control.walk_top = WALL_BASE - 260.0
	add_child(_control)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	var saver := Saver.new()
	saver.who = _charlotte
	add_child(saver)


## Out-of-focus foreground (`items`: [world x, "plant" | "plushie" | "shelf"]), colour grade, fade-in, `--screenshot=`.
func _finish(foreground: Array) -> void:
	_build_foreground(foreground)
	_build_grade()
	Music.play(_music())
	Transition.fade_in(self)
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


## The soundtrack inside, first that exists (see Music): the house theme, else the street's.
func _music() -> Array:
	return ["house", "street_" + Season.current, "street"]


## Camera limits and walking bounds for one area (x from, x to) of the interior.
func _enter_area(area: Vector2) -> void:
	_camera.limit_left = int(area.x)
	_camera.limit_right = int(area.y)
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW.y)
	_control.bounds = Vector2(area.x + 70.0, area.y - 70.0)
	_camera.position = Vector2(_charlotte.position.x, VIEW.y / 2.0)
	_camera.reset_smoothing()


## Through a door to another area: fade to black, move Charlotte to `x`, facing `facing`.
func _go_through(x: float, area: Vector2, facing: int) -> void:
	_control.enabled = false
	Sfx.play("door")
	Transition.through_black(self, func():
		_control.stop()
		_charlotte.position.x = x
		_charlotte.facing = facing
		_enter_area(area)
		_control.enabled = true)


# ── Furniture ───────────────────────────────────────────────────

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


## A light switch, or an outlet, on the wall.
func _plate(x: float, y: float, outlet: bool) -> void:
	_put(InteriorArt.wall_plate(outlet), x, y, 0.8)


func _floor_shadow(cx: float, y: float, rx: float) -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(rx, 7.0), 0.0, 24)
	shadow.color = Color(0.25, 0.12, 0.04, 0.22)
	shadow.position = Vector2(cx + 6.0, y + 2.0)
	add_child(shadow)


func _fairy_lights(from_x: float, count: int) -> FairyLights:
	var lights := FairyLights.new()
	lights.from_x = from_x
	lights.count = count
	add_child(lights)
	return lights


## Something to click to turn lights on and off (a wall switch, a lamp): `lights` show only while it's on.
## With a `room` (x from, x to), that room also dims while it's off. Call it after the room's furniture
## (the dimming goes over it) and before _spawn_charlotte (she stays bright).
func _switchable(area: Rect2, stand_x: float, lights: Array, room := Vector2.ZERO) -> void:
	var dark: Polygon2D
	if room != Vector2.ZERO:
		dark = Polygon2D.new()
		dark.polygon = PackedVector2Array([Vector2(room.x, 0), Vector2(room.y, 0), Vector2(room.y, VIEW.y), Vector2(room.x, VIEW.y)])
		dark.color = Color(0.04, 0.03, 0.1, 0.3)
		dark.visible = false
		add_child(dark)
	add_child(DoorSpot.make(area, func():
		Sfx.play("click", area.get_center())
		var on: bool = not lights[0].visible
		for light in lights:
			light.visible = on
		if dark:
			dark.visible = not on, stand_x))


## A wall switch drawn by _plate(x, y, false): its clickable area.
func _switch_area(x: float, y: float) -> Rect2:
	return Rect2(x - 10.0, y - 44.0, 42.0, 54.0)


## A speech bubble over someone's head (`height` px above their feet) for a moment.
func _say(who: Node2D, text: String, height := 280.0, seconds := 2.4) -> void:
	Bubble.say(self, who.position + Vector2(0, -height), text, seconds)


## Something Charlotte gets (a snack, a treat): its picture floats up above her with `text`, and a happy sound.
func _treat(picture: Texture2D, text: String, delay := 0.0) -> void:
	var treat := Node2D.new()
	treat.position = _charlotte.position + Vector2(0, -270)
	treat.modulate.a = 0.0
	add_child(treat)
	var icon := Sprite2D.new()
	icon.texture = picture
	treat.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("#1D4F91"))
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(-110, -66)
	label.size = Vector2(220, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	treat.add_child(label)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func(): Sfx.play("miam"))
	tween.tween_property(treat, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(treat, "position:y", treat.position.y - 30.0, 1.6)
	tween.tween_interval(0.6)
	tween.tween_property(treat, "modulate:a", 0.0, 0.4)
	tween.tween_callback(treat.queue_free)


# ── Light ───────────────────────────────────────────────────────

## Daylight from a window: a soft beam slanting down to a warm patch on the floor, dust motes drifting in it.
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


func _ceiling_light(x: float) -> Sprite2D:
	var fixture := Polygon2D.new()
	fixture.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(22, 12), Vector2(-22, 12)])
	fixture.color = Color("#F7F5EF")
	fixture.position = Vector2(x, CEILING)
	add_child(fixture)
	return _glow(Vector2(x, CEILING + 20.0), 220.0, Color(1.0, 0.92, 0.75, 0.22))


## Globe pendant hanging from a ceiling medallion down to y; it sways very gently.
func _pendant(x: float, y: float) -> Sprite2D:
	_put(InteriorArt.medallion(), x - 40.0, CEILING + 60.0)
	var pivot := Node2D.new()
	pivot.position = Vector2(x, CEILING + 20.0)
	add_child(pivot)
	var cord := Line2D.new()
	cord.points = PackedVector2Array([Vector2.ZERO, Vector2(0, y - 30.0 - CEILING - 20.0)])
	cord.width = 2.0
	cord.default_color = Color("#8A7A5A")
	pivot.add_child(cord)
	var globe := Sprite2D.new()
	globe.texture = InteriorArt.globe()
	globe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	globe.position = Vector2(0, y - CEILING - 20.0)
	pivot.add_child(globe)
	var glow := _glow(Vector2(x, y), 260.0, Color(1.0, 0.88, 0.6, 0.35))
	glow.reparent(pivot)
	_swaying.append(pivot)
	return glow


## A candle flame's glow at `at`, flickering.
func _candle(at: Vector2, radius: float) -> void:
	var flame := _glow(at, radius, Color(1.0, 0.75, 0.4, 0.5))
	_flames.append([flame, 1.0, flame.scale.x])


## Soft additive light, `radius` px, fading out from `color` at the centre.
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


# ── Camera layers ───────────────────────────────────────────────

# Out-of-focus things right in front of the camera, scrolling faster than the room for depth.
func _build_foreground(items: Array) -> void:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(Foreground.SCROLL, 1.0)
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for item in items:
		var at: float = item[0]
		var x := 640.0 + (at - 640.0) * Foreground.SCROLL
		match item[1]:
			"plant":
				Foreground.add(layer, Foreground.shrub(rng), Vector2(x, 720.0 + 100.0), Vector2(260, 170)).modulate = Color(0.45, 0.42, 0.38)
			"shelf":
				var body := '<rect x="10" y="40" width="380" height="200" fill="#C9C5BC"/>'
				for i in 12:
					body += '<rect x="%d" y="%d" width="26" height="46" fill="%s"/>' % [22 + i * 30, 60 + (i % 2) * 70, ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC"][(i * 7) % 6]]
				Foreground.add(layer, body, Vector2(x, 720.0 + 120.0), Vector2(400, 240)).modulate = Color(0.5, 0.48, 0.46)
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


# Usage: Godot --path . res://scenes/<interior>.tscn -- --screenshot=/tmp/x.png [--x=1234] [--wait=seconds]
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
