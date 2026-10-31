extends Node2D
# ══════════════════════════════════════════════════════════════
# Intro screen – full living street scene + the art/logo.png title.
# Uses real game components: SkyBackdrop, Skyline, Cloud, Street, Squirrel, Cat,
# StrayCat, Dog, WindowCats, Birds, Character (Charlotte), PropArt, Foreground, Wind.
# Press "Démarrer" or Enter/Space to start.
# ══════════════════════════════════════════════════════════════

const VIEW        := Vector2(1280, 720)
const MAIN_SCENE  := "res://scenes/main.tscn"

# Intro street is a fixed 1500 px wide slice centred on Charlotte's duplex.
const STREET_W    := 1500.0
const HOUSE_SCALE := 0.57
const CHAR_SCALE  := 0.38
const HOUSE_BASE_Y:= 592.0
const CURB_Y      := 664.0
const CHARLOTTE_Y := 638.0
const MARGIN      := 30.0
const TREE_SCALE  := 0.55

# A short street section: left neighbour | Charlotte's duplex | right neighbour
const LAYOUT: Array[String] = [
	"plex_04", "duplex_voisin_gauche", "duplex_charlotte", "duplex_voisin_droite", "plex_05",
]
const TREES_AFTER: Array[int] = [0, 2, 4]

var _textures   := {}
var _starts: Array[float] = []
var _charlotte: Character
var _rng        := RandomNumberGenerator.new()
var _time        := 0.0
var _tree_texs: Array[Texture2D] = []
var _wind := Wind.new()
var _window_cats: WindowCats

# UI fade-in
var _ui_alpha   := 0.0
var _ui_layer: CanvasLayer
var _logo: Sprite2D
var _logo_base_scale := 1.0
var _halo: TextureRect

const LOGO_WIDTH := 640.0
const LOGO_Y := 205.0


func _ready() -> void:
	_rng.seed = 2026
	_starts = _layout_starts()
	# Pre-generate tree textures so shadows and canopies share the same art.
	for _i in TREES_AFTER.size():
		_tree_texs.append(PropArt.tree(_rng))

	# ── World layers ──────────────────────────────────────────
	add_child(SkyBackdrop.new())
	_build_skyline()
	add_child(Birds.new())
	_build_houses()
	_build_window_cats()
	_build_cat()
	_build_street()
	_build_tree_shadows()
	_build_passersby()
	_build_charlotte()
	_build_stray_cat()
	_build_squirrels()
	_build_trees()
	_build_props()
	Foreground.build(self, VIEW.x, VIEW.x, 11)
	add_child(_wind)

	# ── UI overlay (logo + button) ────────────────────────────
	_ui_layer = CanvasLayer.new()
	# Above the colour grade (50) so the logo keeps its true colours.
	_ui_layer.layer = 60
	add_child(_ui_layer)
	_build_logo()
	_build_start_button()

	# ── Post-process ──────────────────────────────────────────
	_build_grade()

	# Usage: Godot --path . res://scenes/intro.tscn -- --screenshot=/tmp/intro.png
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			for i in 120:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()


func _process(delta: float) -> void:
	_time += delta
	# Gentle idle sway for Charlotte while on the title screen
	if _charlotte:
		_charlotte.is_walking = false
	# Fade in the UI panel after a short delay
	_ui_alpha = minf(_ui_alpha + delta * 0.8, 1.0)
	_animate_logo()


# ─────────────────────────────────────────────────────────────
# Street geometry helpers (mirrors main.gd)
# ─────────────────────────────────────────────────────────────

func _tex(art: String) -> Texture2D:
	if not _textures.has(art):
		_textures[art] = load("res://art/decor/%s.svg" % art)
	return _textures[art]


func _layout_starts() -> Array[float]:
	var starts: Array[float] = []
	# Centre the mini-street so Charlotte's duplex lands near x=530.
	var x := 0.0
	for art in LAYOUT:
		starts.append(x)
		x += (_tex(art).get_width() - 2.0 * MARGIN) * HOUSE_SCALE
	starts.append(x)
	return starts


func _house_origin(i: int) -> Vector2:
	return Vector2(_starts[i] - MARGIN * HOUSE_SCALE,
				   HOUSE_BASE_Y - _tex(LAYOUT[i]).get_height() * HOUSE_SCALE)


func _tree_origin(slot: int) -> Vector2:
	var idx := TREES_AFTER[slot]
	var x   := _starts[clampi(idx + 1, 0, _starts.size() - 1)] - 190.0 * TREE_SCALE
	return Vector2(x, CURB_Y - 780.0 * TREE_SCALE)


func _sway(strength: float, phase: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/sway.gdshader")
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("phase", phase)
	_wind.materials.append(mat)
	return mat


func _sprite(tex: Texture2D, sprite_scale: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.centered = false
	s.scale = Vector2.ONE * sprite_scale
	return s


# ─────────────────────────────────────────────────────────────
# Skyline (parallax background – needs a fake wide street)
# ─────────────────────────────────────────────────────────────

func _build_skyline() -> void:
	Skyline.build(self, STREET_W, VIEW.x)


# ─────────────────────────────────────────────────────────────
# Houses
# ─────────────────────────────────────────────────────────────

func _build_houses() -> void:
	for i in range(LAYOUT.size() - 1, -1, -1):
		var house := _sprite(_tex(LAYOUT[i]), HOUSE_SCALE)
		house.position = _house_origin(i)
		add_child(house)


func _build_window_cats() -> void:
	var houses := []
	for i in LAYOUT.size():
		houses.append({"art": LAYOUT[i], "origin": _house_origin(i), "scale": HOUSE_SCALE})
	_window_cats = WindowCats.new()
	_window_cats.setup(houses)
	add_child(_window_cats)


# ─────────────────────────────────────────────────────────────
# Cat on the left-neighbour's railing
# ─────────────────────────────────────────────────────────────

func _build_cat() -> void:
	var idx := LAYOUT.find("duplex_voisin_gauche")
	if idx < 0:
		return
	var cat := Cat.new()
	cat.position = _house_origin(idx) + Vector2(300, 552) * HOUSE_SCALE
	cat.scale = Vector2.ONE * 0.7
	add_child(cat)


# ─────────────────────────────────────────────────────────────
# Street / sidewalk
# ─────────────────────────────────────────────────────────────

func _build_street() -> void:
	var street := Street.new()
	street.width = STREET_W
	add_child(street)


# ─────────────────────────────────────────────────────────────
# Trees
# ─────────────────────────────────────────────────────────────

func _build_tree_shadows() -> void:
	for i in TREES_AFTER.size():
		var shadow := _sprite(_tree_texs[i], TREE_SCALE)
		shadow.position = _tree_origin(i) + Vector2(80, 14)
		shadow.modulate = Color(0.22, 0.1, 0.12, 0.2)
		shadow.material = _sway(7.0, i * 1.7)
		add_child(shadow)


func _build_trees() -> void:
	var leaf := PropArt.leaf()
	for i in TREES_AFTER.size():
		var tree := _sprite(_tree_texs[i], TREE_SCALE)
		tree.position = _tree_origin(i)
		tree.material = _sway(7.0, i * 1.7)
		add_child(tree)
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


# ─────────────────────────────────────────────────────────────
# Passersby: kept to either side so they never walk behind the logo and button
# ─────────────────────────────────────────────────────────────

const WALK_ZONES: Array[Vector2] = [Vector2(70, 400), Vector2(880, 1240)]


func _build_passersby() -> void:
	var ages := ["adult", "child"]
	for i in ages.size():
		var zone := WALK_ZONES[i]
		var npc := Passerby.new()
		npc.look = CharacterLook.random(_rng, ages[i])
		npc.walk_speed = _rng.randf_range(100.0, 160.0)
		npc.position = Vector2(_rng.randf_range(zone.x, zone.y), CHARLOTTE_Y - 26.0)
		npc.scale = Vector2.ONE * CHAR_SCALE
		npc.facing = 1 if _rng.randf() < 0.5 else -1
		npc.bounds = zone
		npc.modulate = Color(0.92, 0.92, 0.94)
		add_child(npc)
		if i == 0:
			add_child(Dog.random(_rng, npc))


# ─────────────────────────────────────────────────────────────
# Charlotte (idle, centred on her duplex)
# ─────────────────────────────────────────────────────────────

func _build_charlotte() -> void:
	var idx := LAYOUT.find("duplex_charlotte")
	var x := _starts[idx] + (_starts[idx + 1] - _starts[idx]) * 0.55
	_charlotte = Character.new()
	_charlotte.look = CharacterLook.charlotte()
	_charlotte.position = Vector2(x, CHARLOTTE_Y)
	_charlotte.scale = Vector2.ONE * CHAR_SCALE
	_charlotte.facing = -1  # faces left / camera
	add_child(_charlotte)
	_window_cats.charlotte = _charlotte


# A stray cat already sitting near Charlotte, ready to come say hello.
func _build_stray_cat() -> void:
	var cat := StrayCat.random(_rng)
	cat.position = Vector2(_charlotte.position.x - 150.0, 646.0)
	cat.bounds = Vector2(720.0, 1240.0)
	cat.charlotte = _charlotte
	cat.facing = 1
	add_child(cat)


# ─────────────────────────────────────────────────────────────
# Squirrels
# ─────────────────────────────────────────────────────────────

func _build_squirrels() -> void:
	for at_frac: float in [0.22, 0.68]:
		var squirrel := Squirrel.new()
		var x: float = at_frac * (_starts[-1])
		squirrel.position = Vector2(x, 652)
		squirrel.scale = Vector2.ONE * 0.85
		squirrel.bounds = Vector2(maxf(x - 500.0, 60.0), minf(x + 500.0, STREET_W - 60.0))
		squirrel.threat = _charlotte
		add_child(squirrel)


# ─────────────────────────────────────────────────────────────
# Props (lamp, hydrant)
# ─────────────────────────────────────────────────────────────

func _build_props() -> void:
	# Lamp post at the boundary between plex_04 and duplex_voisin_gauche
	var lamp := _sprite(PropArt.lamppost(), 0.62)
	lamp.position = Vector2(_starts[1] - 101.0 * 0.62, CURB_Y + 2.0 - 518.0 * 0.62)
	add_child(lamp)

	# Hydrant in front of Charlotte's house
	var hydrant := _sprite(PropArt.hydrant(), 0.62)
	var char_idx := LAYOUT.find("duplex_charlotte")
	hydrant.position = Vector2(_starts[char_idx] + 60.0, CURB_Y - 82.0 * 0.62)
	add_child(hydrant)


# ─────────────────────────────────────────────────────────────
# Post-process grade (identical to main scene)
# ─────────────────────────────────────────────────────────────

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


# ═════════════════════════════════════════════════════════════
# LOGO & UI
# ═════════════════════════════════════════════════════════════

func _build_logo() -> void:
	var cx := VIEW.x / 2.0
	# Soft warm halo so the logo lifts off the busy brick behind it.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(1.0, 0.97, 0.9, 0.6), Color(1.0, 0.95, 0.85, 0.3), Color(1.0, 0.95, 0.85, 0.0)])
	var halo_tex := GradientTexture2D.new()
	halo_tex.gradient = grad
	halo_tex.fill = GradientTexture2D.FILL_RADIAL
	halo_tex.fill_from = Vector2(0.5, 0.5)
	halo_tex.fill_to = Vector2(1.0, 0.5)
	_halo = TextureRect.new()
	_halo.texture = halo_tex
	_halo.stretch_mode = TextureRect.STRETCH_SCALE
	_halo.size = Vector2(1000, 560)
	_halo.position = Vector2(cx, LOGO_Y + 30.0) - _halo.size / 2.0
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.modulate.a = 0.0
	_ui_layer.add_child(_halo)
	_logo = Sprite2D.new()
	_logo.texture = preload("res://art/logo.png")
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logo_base_scale = LOGO_WIDTH / _logo.texture.get_width()
	_logo.position = Vector2(cx, LOGO_Y)
	_logo.scale = Vector2.ONE * _logo_base_scale * 0.6
	_logo.modulate.a = 0.0
	_ui_layer.add_child(_logo)


# Pops in with a small overshoot, then floats gently.
func _animate_logo() -> void:
	var t := clampf(_time / 0.9, 0.0, 1.0)
	var pop := 1.0 - pow(1.0 - t, 3.0) * cos(t * PI * 1.5)
	_logo.scale = Vector2.ONE * _logo_base_scale * lerpf(0.6, 1.0, pop) * (1.0 + sin(_time * 1.6) * 0.012)
	_logo.position.y = LOGO_Y + sin(_time * 1.1) * 4.0
	_logo.rotation = sin(_time * 0.8) * 0.012
	_logo.modulate.a = _ui_alpha
	_halo.modulate.a = _ui_alpha


# ─────────────────────────────────────────────────────────────
# Start button
# ─────────────────────────────────────────────────────────────

func _build_start_button() -> void:
	var cx := VIEW.x / 2.0
	var btn_y := 392.0

	# "Démarrer" button
	var btn := Button.new()
	btn.text = "▶  Démarrer"
	var bw := 240.0
	var bh := 58.0
	btn.size = Vector2(bw, bh)
	btn.position = Vector2(cx - bw / 2.0, btn_y)

	var _mk_style := func(bg: Color, border: Color) -> StyleBoxFlat:
		var st := StyleBoxFlat.new()
		st.bg_color = bg
		st.border_color = border
		st.set_border_width_all(2)
		st.corner_radius_top_left    = 8
		st.corner_radius_top_right   = 8
		st.corner_radius_bottom_left = 8
		st.corner_radius_bottom_right = 8
		st.content_margin_left  = 14
		st.content_margin_right = 14
		st.shadow_color = Color(0.1, 0.05, 0.02, 0.35)
		st.shadow_size = 8
		st.shadow_offset = Vector2(0, 4)
		return st

	btn.add_theme_stylebox_override("normal",  _mk_style.call(Color("#1D4F91"), Color("#E8DDD0")))
	btn.add_theme_stylebox_override("hover",   _mk_style.call(Color("#FFD23F"), Color("#1D4F91")))
	btn.add_theme_stylebox_override("pressed", _mk_style.call(Color("#E6B800"), Color("#1D4F91")))
	btn.add_theme_color_override("font_color",         Color.WHITE)
	btn.add_theme_color_override("font_hover_color",   Color("#1D4F91"))
	btn.add_theme_color_override("font_pressed_color", Color("#1D4F91"))
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(_on_start_pressed)
	_ui_layer.add_child(btn)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()




