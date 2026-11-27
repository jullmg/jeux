class_name EggStudio
extends CanvasLayer
## Decorating Easter eggs with Maman at the kitchen table (Julien, 2026-11-27: "décorer un coco de Pâques avec maman"), the way
## it is really done, on an egg that turns (`shaders/egg.gdshader`: the whole shell is one 2:1 map, `_surf`, so whatever she
## puts on goes all the way round when she turns it: the arrows, the "Faire tourner" switch, or dragging beside the egg):
##   - Teinture: seven cups of dye; she dips the egg all the way, half way or just its tip in the big bowl; dyes MIX like real
##     ones (yellow, then blue, makes green: the shell is multiplied by the dye), and it comes out wet and dripping;
##   - Cire: a white wax crayon; where she draws, the dye won't take (`_wax`), so after the bath her drawing stays white;
##   - Élastiques: rubber bands round the egg; the dye can't get under them, and Maman takes them off after the bath (stripes);
##   - Pinceau: paint on top; Autocollants: Easter stickers (`StampArt`, baked once, laid on the shell undistorted where she
##     clicks); Brillants: glitter in gold, silver or rainbow that twinkles;
##   - "Oups !" takes a step back; "C'est fini !" shows it turning on its egg cup, then "Encore un coco !" or done.
## `closed` gives {eggs: [Image, …]} (the front of each finished egg), empty if she made none. Kept in `cocos/` (`keep`, `kept`).

signal closed(result: Dictionary)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")
const TW := 512
const TH := 256
const STAGE_POS := Vector2(24, 76)
const STAGE_SIZE := Vector2(640, 560)
const EGG_C := Vector2(320, 214)
const R := 118.0
const RY := 150.0
const BOWL_C := Vector2(320, 478)
const SHELL := Color("#FBF6EC")
const KEEP_MAX := 12
const UNDO := 14
const DYES := [["rouge", "Rouge", "#F2546A"], ["orange", "Orange", "#FF9A3D"], ["jaune", "Jaune", "#FFE14A"], ["vert", "Vert", "#62C46B"],
	["bleu", "Bleu", "#56A8EC"], ["mauve", "Mauve", "#A57FE0"], ["rose", "Rose", "#FF8FBE"]]
const DEPTHS := [["Tout le coco", 0.0], ["La moitié", 0.5], ["Juste le bout", 0.74]]
const TOOLS := [["teinture", "Teinture"], ["cire", "Cire"], ["elastiques", "Élastiques"], ["pinceau", "Pinceau"], ["autocollants", "Autocollants"], ["brillants", "Brillants"]]
const PAINTS := ["#E04F5F", "#FF8A3D", "#FFD23F", "#7CCB5A", "#2FB7B0", "#4FA3E0", "#1D4F91", "#7E57C2", "#FF7BA3", "#FFFFFF", "#8D6E63", "#2B2B2B"]
const STICKERS := ["lapin", "oiseau", "fleur", "tulipe", "coeur", "etoile", "coccinelle", "soleil", "arc", "abeille", "papillon"]
const GLITTERS := [["or", "Or", "#F2C230"], ["argent", "Argent", "#DCE3EC"], ["arc", "Arc-en-ciel", ""]]
const BAND_COLORS := ["#E04F5F", "#4FA3E0", "#7CCB5A", "#FFD23F", "#B58AD9"]
const TIPS := {
	"teinture": "Choisis une couleur pis trempe ton coco ! Les couleurs se mélangent : du jaune, pis du bleu par-dessus, ça fait du vert.",
	"cire": "La cire, c'est magique : là où tu dessines, la teinture prend pas. Ton dessin va rester blanc !",
	"elastiques": "Mets des élastiques autour du coco, trempe-le, pis je les enlève : ça fait des rayures !",
	"pinceau": "Peins par-dessus, ma chouette. Fais-le tourner pour peindre tout le tour !",
	"autocollants": "Colle des autocollants où tu veux. Un lapin, c'est toujours une bonne idée !",
	"brillants": "Des brillants ! Ton coco va scintiller comme un bijou.",
	"fini": "Wow ! C'est le plus beau coco que j'ai jamais vu, Chachoue !",
}

var _root: Control
var _panel: Panel
var _back: _Back
var _egg: ColorRect
var _front: _Front
var _side: VBoxContainer
var _tip: Label
var _mat: ShaderMaterial
var _surf: Image
var _wax: Image
var _glit: Image
var _surf_tex: ImageTexture
var _wax_tex: ImageTexture
var _glit_tex: ImageTexture
var _bands: Array = []
var _undo: Array = []
var _turn := 0.0
var _spin := false
var _spin_dir := 0.0
var _tool := "teinture"
var _dye := 2
var _depth := 0
var _paint := Color(PAINTS[0])
var _size := 1
var _sticker := "lapin"
var _glitter := 0
var _wet := 0.0
var _dip := 0.0
var _busy := false
var _pressing := false
var _rotating := false
var _last := Vector2(-1, -1)
var _mouse := Vector2(-1, -1)
var _dirty := false
var _time := 0.0
var _drops: Array = []
var _done: Array[Image] = []
var _rng := RandomNumberGenerator.new()
var _undo_button: Button
var _card: Control


func _init() -> void:
	layer = 60


func _ready() -> void:
	add_to_group("modal")
	_rng.seed = 41
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(20, 12)
	_panel.size = Vector2(1240, 696)
	_panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(_panel)
	var title := _label("Les cocos de Pâques avec Maman", 30, BLUE)
	title.position = Vector2(0, 14)
	title.size = Vector2(1240, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var frame := Panel.new()
	frame.position = STAGE_POS - Vector2(6, 6)
	frame.size = STAGE_SIZE + Vector2(12, 12)
	frame.add_theme_stylebox_override("panel", _box(Color("#E9DFCB"), Color("#C8A27A"), 5, 12))
	_panel.add_child(frame)
	var clip := Control.new()
	clip.position = STAGE_POS
	clip.size = STAGE_SIZE
	clip.clip_contents = true
	_panel.add_child(clip)
	_back = _Back.new()
	_back.studio = self
	_back.size = STAGE_SIZE
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_back)
	_egg = ColorRect.new()
	_egg.size = Vector2(R, RY) * 2.0
	_egg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/egg.gdshader")
	_egg.material = _mat
	clip.add_child(_egg)
	_front = _Front.new()
	_front.studio = self
	_front.size = STAGE_SIZE
	_front.mouse_filter = Control.MOUSE_FILTER_STOP
	clip.add_child(_front)
	_tip = _label("", 18, Color("#7A3E5C"))
	_tip.position = Vector2(24, 644)
	_tip.size = Vector2(640, 46)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_tip)
	_side = VBoxContainer.new()
	_side.position = Vector2(690, 70)
	_side.size = Vector2(530, 560)
	_side.add_theme_constant_override("separation", 10)
	_panel.add_child(_side)
	var bar := HBoxContainer.new()
	bar.position = Vector2(690, 640)
	bar.add_theme_constant_override("separation", 8)
	_panel.add_child(bar)
	bar.add_child(_button("Arrêter", 18, _leave, Vector2(104, 44)))
	_undo_button = _button("Oups !", 18, _take_back, Vector2(96, 44))
	bar.add_child(_undo_button)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(70, 1)
	bar.add_child(gap)
	var done := _button("C'est fini !", 22, _finish, Vector2(200, 46))
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	bar.add_child(done)
	_new_egg()


func _new_egg() -> void:
	_surf = Image.create(TW, TH, false, Image.FORMAT_RGBA8)
	_surf.fill(SHELL)
	# A few freckles of a real shell.
	for k in 60:
		_surf.set_pixel(_rng.randi() % TW, _rng.randi() % TH, SHELL.darkened(0.06))
	_wax = Image.create(TW, TH, false, Image.FORMAT_RGBA8)
	_glit = Image.create(TW, TH, false, Image.FORMAT_RGBA8)
	_surf_tex = ImageTexture.create_from_image(_surf)
	_wax_tex = ImageTexture.create_from_image(_wax)
	_glit_tex = ImageTexture.create_from_image(_glit)
	_mat.set_shader_parameter("surf", _surf_tex)
	_mat.set_shader_parameter("wax", _wax_tex)
	_mat.set_shader_parameter("glitter", _glit_tex)
	_bands.clear()
	_undo.clear()
	_turn = 0.0
	_wet = 0.0
	_set_tool("teinture")


func _process(delta: float) -> void:
	_time += delta
	if _spin:
		_turn += delta * 1.1
	if _spin_dir != 0.0:
		_turn += _spin_dir * delta * 2.4
	_wet = maxf(0.0, _wet - delta * 0.35)
	if _wet > 0.2 and randf() < delta * 5.0 * _wet and _dip == 0.0:
		_drops.append([EGG_C + Vector2(randf_range(-30, 30), RY - 8.0), 0.0])
	for d: Array in _drops:
		d[1] += delta * 600.0
		d[0].y += d[1] * delta
	_drops = _drops.filter(func(d: Array) -> bool: return d[0].y < EGG_C.y + RY + 46.0)
	if _dirty:
		_surf_tex.update(_surf)
		_wax_tex.update(_wax)
		_glit_tex.update(_glit)
		_dirty = false
	_egg.position = EGG_C - Vector2(R, RY) + Vector2(0, _dip)
	_mat.set_shader_parameter("turn", _turn)
	_mat.set_shader_parameter("wet", _wet)
	_mat.set_shader_parameter("time", _time)
	_back.queue_redraw()
	_front.queue_redraw()


# ── The side panel ──────────────────────────────────────────────

func _set_tool(id: String) -> void:
	_tool = id
	_tip.text = "Maman : " + str(TIPS.get(id, ""))
	_build_side()


func _build_side() -> void:
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	var tabs := GridContainer.new()
	tabs.columns = 3
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	_side.add_child(tabs)
	for t: Array in TOOLS:
		tabs.add_child(_toggle(str(t[1]), t[0] == _tool, func() -> void: _set_tool(str(t[0])), Vector2(166, 48), 19))
	match _tool:
		"teinture":
			_side.add_child(_label("La couleur du bain", 20, BLUE))
			var cups := HBoxContainer.new()
			cups.add_theme_constant_override("separation", 6)
			_side.add_child(cups)
			for i in DYES.size():
				var col := Color(DYES[i][2])
				var b := Button.new()
				b.custom_minimum_size = Vector2(68, 64)
				b.text = str(DYES[i][1])
				b.add_theme_font_size_override("font_size", 13)
				b.add_theme_color_override("font_color", BLUE)
				b.add_theme_stylebox_override("normal", _box(col, YELLOW if i == _dye else col.darkened(0.3), 5 if i == _dye else 2, 14))
				b.add_theme_stylebox_override("hover", _box(col.lightened(0.15), BLUE, 3, 14))
				b.add_theme_stylebox_override("focus", _box(col, YELLOW if i == _dye else col.darkened(0.3), 5 if i == _dye else 2, 14))
				b.pressed.connect(func() -> void:
					_dye = i
					Sfx.play("click")
					_build_side())
				cups.add_child(b)
			_side.add_child(_label("Jusqu'où ?", 20, BLUE))
			var depth := HBoxContainer.new()
			depth.add_theme_constant_override("separation", 8)
			_side.add_child(depth)
			for i in DEPTHS.size():
				depth.add_child(_toggle(str(DEPTHS[i][0]), i == _depth, func() -> void:
					_depth = i
					_build_side(), Vector2(160, 44), 17))
			var go := _button("Tremper le coco !", 24, _dip_egg, Vector2(320, 62))
			go.add_theme_stylebox_override("normal", _box(Color(DYES[_dye][2]).lightened(0.35), BLUE, 3, 18))
			_side.add_child(go)
		"cire", "pinceau", "brillants":
			if _tool == "pinceau":
				var grid := GridContainer.new()
				grid.columns = 6
				grid.add_theme_constant_override("h_separation", 6)
				grid.add_theme_constant_override("v_separation", 6)
				_side.add_child(grid)
				for hex: String in PAINTS:
					var col := Color(hex)
					var on := col.is_equal_approx(_paint)
					var b := Button.new()
					b.custom_minimum_size = Vector2(76, 44)
					b.add_theme_stylebox_override("normal", _box(col, YELLOW if on else col.darkened(0.3), 5 if on else 2, 12))
					b.add_theme_stylebox_override("hover", _box(col.lightened(0.15), BLUE, 3, 12))
					b.add_theme_stylebox_override("focus", _box(col, YELLOW if on else col.darkened(0.3), 5 if on else 2, 12))
					b.pressed.connect(func() -> void:
						_paint = col
						Sfx.play("click")
						_build_side())
					grid.add_child(b)
			if _tool == "brillants":
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				_side.add_child(row)
				for i in GLITTERS.size():
					row.add_child(_toggle(str(GLITTERS[i][1]), i == _glitter, func() -> void:
						_glitter = i
						_build_side(), Vector2(150, 46), 18))
			_side.add_child(_label("La grosseur", 20, BLUE))
			var sizes := HBoxContainer.new()
			sizes.add_theme_constant_override("separation", 8)
			_side.add_child(sizes)
			for i in 3:
				sizes.add_child(_toggle(["Fin", "Moyen", "Gros"][i], i == _size, func() -> void:
					_size = i
					_build_side(), Vector2(110, 44), 18))
		"elastiques":
			_text("Clique sur ton coco à la hauteur où tu veux un élastique (six au plus). Ensuite, trempe-le dans la teinture !")
			_side.add_child(_button("Enlever les élastiques", 18, func() -> void:
				if not _bands.is_empty():
					_snap()
					_bands.clear()
					Sfx.play("pop"), Vector2(260, 46)))
		"autocollants":
			var grid := GridContainer.new()
			grid.columns = 4
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			_side.add_child(grid)
			for id: String in STICKERS:
				var b := _StickerButton.new()
				b.sticker = id
				b.color = _paint
				b.custom_minimum_size = Vector2(118, 60)
				var on := id == _sticker
				b.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if on else Color.WHITE, BLUE if on else Color(BLUE, 0.3), 3 if on else 2, 12))
				b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 12))
				b.pressed.connect(func() -> void:
					_sticker = id
					Sfx.play("click")
					_build_side())
				grid.add_child(b)
			_text("La couleur, c'est celle du pinceau. Clique sur ton coco pour coller l'autocollant.")
			var sizes := HBoxContainer.new()
			sizes.add_theme_constant_override("separation", 8)
			_side.add_child(sizes)
			for i in 3:
				sizes.add_child(_toggle(["Petit", "Moyen", "Gros"][i], i == _size, func() -> void:
					_size = i
					_build_side(), Vector2(110, 44), 18))
	# Turning the egg, whatever the tool.
	_side.add_child(_label("Tourner le coco", 20, BLUE))
	var turn := HBoxContainer.new()
	turn.add_theme_constant_override("separation", 8)
	_side.add_child(turn)
	for dir: float in [-1.0, 1.0]:
		var b := _button("⟲" if dir < 0.0 else "⟳", 26, func() -> void: pass, Vector2(70, 46))
		b.button_down.connect(func() -> void: _spin_dir = dir)
		b.button_up.connect(func() -> void: _spin_dir = 0.0)
		turn.add_child(b)
	turn.add_child(_toggle("Faire tourner" if not _spin else "Arrêter de tourner", _spin, func() -> void:
		_spin = not _spin
		_build_side(), Vector2(230, 46), 18))
	_undo_button.disabled = _undo.is_empty()


# ── Painting on the shell ───────────────────────────────────────

## Where on the shell a point of the stage is: (u, v, how much the shell is squeezed there), or u < 0 off the egg.
func _uv_at(p: Vector2) -> Vector3:
	var q := (p - EGG_C) / Vector2(R, RY)
	var k := 0.88 + 0.12 * q.y
	var xs := q.x / k
	var r2 := xs * xs + q.y * q.y
	if r2 > 0.995:
		return Vector3(-1, -1, 0)
	var z := sqrt(1.0 - r2)
	var lon := atan2(xs, z) + _turn
	var lat := asin(clampf(q.y, -1.0, 1.0))
	return Vector3(fposmod(lon / TAU, 1.0) * TW, (lat / PI + 0.5) * TH, maxf(cos(lat), 0.28) * k)


# How big a round dab `r` px across on screen is on the shell's map.
func _radii(at: Vector3, r: float) -> Vector2:
	return Vector2(r / (R * at.z) * TW / TAU, r / (RY * maxf(at.z / 0.88, 0.28)) * TH / PI)


func _dab(p: Vector2) -> void:
	var at := _uv_at(p)
	if at.x < 0.0:
		return
	var r: float = [5.0, 9.0, 16.0][_size]
	if _tool == "cire":
		r *= 0.7
	var rad := _radii(at, r)
	for y in range(int(at.y - rad.y), int(at.y + rad.y) + 1):
		if y < 0 or y >= TH:
			continue
		var dy := (y - at.y) / rad.y
		for x in range(int(at.x - rad.x), int(at.x + rad.x) + 1):
			var dx := (x - at.x) / rad.x
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			var xx := posmod(x, TW)
			var a := clampf((1.0 - d) * 3.0, 0.0, 1.0)
			match _tool:
				"pinceau":
					_surf.set_pixel(xx, y, _surf.get_pixel(xx, y).lerp(_paint, a))
				"cire":
					var old := _wax.get_pixel(xx, y)
					_wax.set_pixel(xx, y, Color(1, 1, 1, maxf(old.a, a)))
				"brillants":
					if _rng.randf() < 0.5 * a:
						var col := Color(GLITTERS[_glitter][2]) if GLITTERS[_glitter][2] != "" else Color.from_hsv(_rng.randf(), 0.6, 1.0)
						_glit.set_pixel(xx, y, col.lightened(_rng.randf_range(0.0, 0.4)))
	_dirty = true


func _stroke_to(p: Vector2) -> void:
	if _last.x < 0.0:
		_dab(p)
	else:
		var step := 3.0
		var n := maxi(1, int(_last.distance_to(p) / step))
		for k in range(1, n + 1):
			_dab(_last.lerp(p, float(k) / n))
	_last = p


func stage_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = event.position
	if _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var at := _uv_at(event.position)
			if at.x < 0.0:
				# Beside the egg: she turns it.
				_rotating = true
				_last = event.position
				return
			match _tool:
				"cire", "pinceau", "brillants":
					_snap()
					_pressing = true
					_last = Vector2(-1, -1)
					_stroke_to(event.position)
				"elastiques":
					_add_band(event.position)
				"autocollants":
					_place_sticker(event.position)
				"teinture":
					_dip_egg()
		else:
			_pressing = false
			_rotating = false
			_last = Vector2(-1, -1)
	elif event is InputEventMouseMotion:
		if _rotating:
			_turn -= event.relative.x * 0.012
		elif _pressing:
			_stroke_to(event.position)


func _add_band(p: Vector2) -> void:
	if _bands.size() >= 6:
		_tip.text = "Maman : Six élastiques, c'est assez ! Trempe-le, astheure."
		return
	_snap()
	var v := clampf((asin(clampf((p.y - EGG_C.y) / RY, -1.0, 1.0)) / PI + 0.5) * TH, 20.0, TH - 20.0)
	_bands.append([v, BAND_COLORS[_bands.size() % BAND_COLORS.size()]])
	Sfx.play("squeak", Vector2.INF, -8.0, 0.8)


# A sticker laid where she clicks, sized so it looks right on the curve.
func _place_sticker(p: Vector2) -> void:
	var at := _uv_at(p)
	if at.x < 0.0:
		return
	_busy = true
	var size: float = [34.0, 52.0, 74.0][_size]
	var img := await _bake_sticker(_sticker, _paint)
	_busy = false
	_snap()
	var rad := _radii(at, size / 2.0)
	var w := maxi(4, int(rad.x * 2.0))
	var h := maxi(4, int(rad.y * 2.0))
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var pos := Vector2i(int(at.x - w / 2.0), int(at.y - h / 2.0))
	_surf.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
	if pos.x < 0:
		_surf.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos + Vector2i(TW, 0))
	elif pos.x + w > TW:
		_surf.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos - Vector2i(TW, 0))
	_dirty = true
	Sfx.play("pop")


func _bake_sticker(id: String, col: Color) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(120, 120)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var node := _Printer.new()
	node.painter = func(ci: CanvasItem) -> void: StampArt.draw(ci, id, Vector2(60, 60), 48.0, col)
	vp.add_child(node)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


# ── The dye bath ────────────────────────────────────────────────

func _dip_egg() -> void:
	if _busy:
		return
	_busy = true
	_snap()
	var col := Color(DYES[_dye][2])
	var from := float(DEPTHS[_depth][1])
	# Down until the dye's surface reaches the line where the dye must stop.
	var down := (BOWL_C.y - 44.0) - (EGG_C.y + sin((from - 0.5) * PI) * RY) + 8.0
	Sfx.play("swoosh")
	var tw := create_tween()
	tw.tween_property(self, "_dip", down, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		Sfx.play("bloop")
		_apply_dye(col, from))
	tw.tween_interval(1.1)
	tw.tween_property(self, "_dip", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_wet = 1.0
		_busy = false
		for k in 4:
			get_tree().create_timer(0.2 + k * 0.35).timeout.connect(func() -> void: Sfx.play("drip", Vector2.INF, -10.0, randf_range(0.9, 1.2)))
		if not _bands.is_empty():
			# Maman takes the bands off: the stripes show.
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				_bands.clear()
				Sfx.play("pop")
				_tip.text = "Maman : J'enlève les élastiques… Regarde tes belles rayures !")
		else:
			_tip.text = "Maman : %s" % ["Oh ! Belle couleur !", "Regarde comme ça mélange les couleurs !", "Wow, y dégoutte encore !"][randi() % 3])


# The dye takes on the shell from row `from` (0 the top) down, except under wax and bands; a soft line where it stops.
func _apply_dye(col: Color, from: float) -> void:
	var data := _surf.get_data()
	var wax := _wax.get_data()
	var start := int(from * TH)
	var band_rows := {}
	for b: Array in _bands:
		for y in range(int(b[0]) - 4, int(b[0]) + 5):
			band_rows[y] = true
	for y in range(maxi(0, start - 6), TH):
		if band_rows.has(y):
			continue
		var edge := clampf((y - (start - 6)) / 6.0, 0.0, 1.0) if from > 0.0 else 1.0
		# A wavering line where the dye stopped.
		for x in TW:
			var i := (y * TW + x) * 4
			var resist := wax[i + 3] / 255.0
			var a := edge * (1.0 - resist)
			if from > 0.0 and y < start + 2:
				a *= clampf(0.5 + 0.5 * sin(x * 0.09) + (y - start + 6) / 8.0, 0.0, 1.0)
			if a <= 0.0:
				continue
			for c in 3:
				var v := data[i + c] / 255.0
				var m := [col.r, col.g, col.b][c] as float
				data[i + c] = int(clampf(lerpf(v, v * m, a), 0.0, 1.0) * 255.0)
	_surf.set_data(TW, TH, false, Image.FORMAT_RGBA8, data)
	_dirty = true


# ── Undo, the end ───────────────────────────────────────────────

func _snap() -> void:
	_undo.append([_surf.duplicate(), _wax.duplicate(), _glit.duplicate(), _bands.duplicate(true)])
	if _undo.size() > UNDO:
		_undo.pop_front()
	_undo_button.disabled = false


func _take_back() -> void:
	if _undo.is_empty() or _busy:
		return
	var s: Array = _undo.pop_back()
	_surf = s[0]
	_wax = s[1]
	_glit = s[2]
	_bands = s[3]
	_dirty = true
	Sfx.play("swoosh")
	_undo_button.disabled = _undo.is_empty()


func _finish() -> void:
	if _busy:
		return
	if _undo.is_empty():
		_tip.text = "Maman : Il est encore tout blanc, ton coco ! Décore-le un peu."
		return
	_busy = true
	_spin = false
	_bands.clear()
	var img := await render_front()
	_done.append(img)
	Sfx.play("chime")
	_show_card()


## The egg's front, printed on a transparent sheet, cut to its edges.
func render_front() -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(R * 2.0) + 8, int(RY * 2.0) + 8)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var rect := ColorRect.new()
	rect.position = Vector2(4, 4)
	rect.size = Vector2(R, RY) * 2.0
	var m := _mat.duplicate() as ShaderMaterial
	m.set_shader_parameter("wet", 0.0)
	m.set_shader_parameter("time", 1.3)
	rect.material = m
	vp.add_child(rect)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


func _show_card() -> void:
	_card = Panel.new()
	_card.size = Vector2(560, 300)
	_card.position = Vector2(680, 200)
	_card.add_theme_stylebox_override("panel", _box(Color("#FFFDF7"), BLUE, 5, 24))
	_panel.add_child(_card)
	var t := _label("Ton coco est prêt !", 32, BLUE)
	t.position = Vector2(0, 20)
	t.size = Vector2(560, 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(t)
	var sub := _label("%d coco%s décoré%s. Maman les met à sécher." % [_done.size(), "s" if _done.size() > 1 else "", "s" if _done.size() > 1 else ""], 20, Color(BLUE, 0.85))
	sub.position = Vector2(0, 74)
	sub.size = Vector2(560, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(sub)
	var again := _button("Encore un coco !", 22, func() -> void:
		_card.queue_free()
		_busy = false
		Sfx.play("pop")
		_new_egg(), Vector2(240, 60))
	again.position = Vector2(30, 140)
	_card.add_child(again)
	var stop := _button("J'ai fini ♥", 22, func() -> void:
		closed.emit({"eggs": _done})
		queue_free(), Vector2(240, 60))
	stop.position = Vector2(290, 140)
	stop.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	_card.add_child(stop)
	_spin = true
	_tip.text = "Maman : " + str(TIPS.fini)
	for c in _side.get_children():
		c.visible = false


func _leave() -> void:
	if _busy and _card == null:
		return
	closed.emit({"eggs": _done})
	queue_free()


# ── Kept ────────────────────────────────────────────────────────

static func folder() -> String:
	return GameState.slot_dir() + "/cocos"


static func keep(img: Image) -> void:
	DirAccess.make_dir_recursive_absolute(folder())
	img.save_png("%s/%s_%d.png" % [folder(), str(int(Time.get_unix_time_from_system() * 1000.0)), randi() % 1000])
	var names := _names()
	while names.size() > KEEP_MAX:
		DirAccess.remove_absolute(folder() + "/" + str(names.pop_front()))


static func _names() -> Array:
	var dir := DirAccess.open(folder())
	if dir == null:
		return []
	var names := Array(dir.get_files()).filter(func(n: String) -> bool: return n.ends_with(".png"))
	names.sort()
	return names


## Her eggs, oldest first.
static func kept() -> Array[Image]:
	var out: Array[Image] = []
	for n: String in _names():
		var img := Image.load_from_file(folder() + "/" + n)
		if img:
			out.append(img)
	return out


static func forget_all() -> void:
	for n: String in _names():
		DirAccess.remove_absolute(folder() + "/" + n)


# ── Drawing the table ───────────────────────────────────────────

func paint_back(ci: Control) -> void:
	# A gingham tablecloth, yesterday's newspaper spread on it, and the egg's shadow.
	ci.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("#FFF7E6"))
	for k in 22:
		ci.draw_rect(Rect2(k * 32.0, 0, 16, STAGE_SIZE.y), Color(0.98, 0.75, 0.3, 0.22))
		ci.draw_rect(Rect2(0, k * 32.0, STAGE_SIZE.x, 16), Color(0.98, 0.75, 0.3, 0.22))
	var paper := PackedVector2Array([Vector2(60, 330), Vector2(590, 312), Vector2(612, 552), Vector2(40, 560)])
	ci.draw_colored_polygon(paper, Color("#ECE8DE"))
	for k in 12:
		var y := 340.0 + k * 17.0
		ci.draw_line(Vector2(70 + (k % 3) * 6.0, y), Vector2(320, y - 3), Color(0.3, 0.3, 0.3, 0.18), 2.0)
		ci.draw_line(Vector2(340, y - 3), Vector2(580, y - 8), Color(0.3, 0.3, 0.3, 0.18), 2.0)
	ci.draw_string(ThemeDB.fallback_font, Vector2(80, 336), "LE JOURNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.3, 0.3, 0.4))
	# Dye splashes on the newspaper from the eggs before.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 9:
		var c := Color(DYES[rng.randi() % DYES.size()][2])
		c.a = 0.35
		ci.draw_circle(Vector2(rng.randf_range(80, 560), rng.randf_range(360, 540)), rng.randf_range(4, 12), c)
	var shade := clampf(1.0 - _dip / 200.0, 0.0, 1.0)
	_ellipse(ci, Vector2(EGG_C.x + 16, EGG_C.y + RY + 30), Vector2(R * 0.85, 18), Color(0, 0, 0, 0.18 * shade))
	# The egg cup it rests on.
	if _dip < 4.0:
		var cup := PackedVector2Array([Vector2(EGG_C.x - 46, EGG_C.y + RY - 22), Vector2(EGG_C.x + 46, EGG_C.y + RY - 22),
			Vector2(EGG_C.x + 30, EGG_C.y + RY + 20), Vector2(EGG_C.x + 40, EGG_C.y + RY + 34), Vector2(EGG_C.x - 40, EGG_C.y + RY + 34),
			Vector2(EGG_C.x - 30, EGG_C.y + RY + 20)])
		ci.draw_colored_polygon(cup, Color("#F7C7D2"))
	# The big bowl of dye: its back rim and the liquid.
	_ellipse(ci, BOWL_C + Vector2(0, -50), Vector2(170, 34), Color("#CFE3EE"))
	_ellipse(ci, BOWL_C + Vector2(0, -44), Vector2(156, 28), Color(DYES[_dye][2]).darkened(0.15))
	for d: Array in _drops:
		ci.draw_circle(d[0], 4.0, Color(DYES[_dye][2]).darkened(0.1))


func paint_front(ci: Control) -> void:
	# The egg cup's front over the egg's bottom.
	if _dip < 4.0:
		var lip := PackedVector2Array([Vector2(EGG_C.x - 48, EGG_C.y + RY - 24), Vector2(EGG_C.x + 48, EGG_C.y + RY - 24),
			Vector2(EGG_C.x + 44, EGG_C.y + RY - 8), Vector2(EGG_C.x + 30, EGG_C.y + RY + 20), Vector2(EGG_C.x - 30, EGG_C.y + RY + 20),
			Vector2(EGG_C.x - 44, EGG_C.y + RY - 8)])
		ci.draw_colored_polygon(lip, Color("#FF9FB9"))
		ci.draw_line(Vector2(EGG_C.x - 40, EGG_C.y + RY - 16), Vector2(EGG_C.x - 28, EGG_C.y + RY + 12), Color(1, 1, 1, 0.5), 3.0)
		for k in 5:
			ci.draw_circle(Vector2(EGG_C.x - 28 + k * 14.0, EGG_C.y + RY - 4), 3.0, Color.WHITE)
	# The rubber bands round the egg.
	for b: Array in _bands:
		var lat := (float(b[0]) / TH - 0.5) * PI
		var y := EGG_C.y + sin(lat) * RY + _dip
		var half := cos(lat) * R * (0.88 + 0.12 * sin(lat))
		var col := Color(b[1])
		ci.draw_line(Vector2(EGG_C.x - half, y), Vector2(EGG_C.x + half, y + 1.0), col.darkened(0.3), 7.0, true)
		ci.draw_line(Vector2(EGG_C.x - half + 2, y - 1.0), Vector2(EGG_C.x + half - 2, y), col, 4.5, true)
		ci.draw_line(Vector2(EGG_C.x - half * 0.7, y - 2.0), Vector2(EGG_C.x - half * 0.1, y - 2.0), Color(1, 1, 1, 0.5), 1.5, true)
	# The bowl's glass front and the dye over the dipped egg.
	var liquid := Color(DYES[_dye][2])
	var front := PackedVector2Array()
	for k in 25:
		var a := PI * k / 24.0
		front.append(BOWL_C + Vector2(-cos(a) * 156.0, -44.0 + sin(a) * 28.0))
	for k in 25:
		var a := PI - PI * k / 24.0
		front.append(BOWL_C + Vector2(-cos(a) * 140.0, 70.0 + sin(a) * 14.0))
	ci.draw_colored_polygon(front, Color(liquid, 0.92))
	var glass := PackedVector2Array()
	for k in 25:
		var a := PI * k / 24.0
		glass.append(BOWL_C + Vector2(-cos(a) * 170.0, -50.0 + sin(a) * 34.0))
	for k in 25:
		var a := PI - PI * k / 24.0
		glass.append(BOWL_C + Vector2(-cos(a) * 150.0, 78.0 + sin(a) * 18.0))
	ci.draw_colored_polygon(glass, Color(0.85, 0.93, 1.0, 0.22))
	glass.append(glass[0])
	ci.draw_polyline(glass, Color(0.55, 0.7, 0.8, 0.7), 2.5, true)
	ci.draw_line(BOWL_C + Vector2(-140, -30), BOWL_C + Vector2(-128, 50), Color(1, 1, 1, 0.55), 5.0, true)
	if _dip > 120.0:
		# Bubbles round the egg in the bath.
		for k in 6:
			var t := fposmod(_time * 1.6 + k * 0.37, 1.0)
			ci.draw_circle(BOWL_C + Vector2(-60 + k * 24.0, -40.0 - t * 14.0), 3.0 * (1.0 - t), Color(1, 1, 1, 0.7 * (1.0 - t)))
	# The brush under the mouse.
	if _mouse.x >= 0.0 and _tool in ["cire", "pinceau", "brillants"] and _uv_at(_mouse).x >= 0.0:
		var r: float = [5.0, 9.0, 16.0][_size] * (0.7 if _tool == "cire" else 1.0)
		ci.draw_arc(_mouse, r, 0.0, TAU, 24, Color(0.2, 0.2, 0.3, 0.8), 1.5, true)
	elif _mouse.x >= 0.0 and _tool == "elastiques" and _uv_at(_mouse).x >= 0.0:
		ci.draw_line(Vector2(EGG_C.x - R, _mouse.y), Vector2(EGG_C.x + R, _mouse.y), Color(BAND_COLORS[_bands.size() % BAND_COLORS.size()], 0.5), 4.0)
	if not _busy and _card == null:
		ci.draw_string(ThemeDB.fallback_font, Vector2(16, 30), "Tire à côté du coco pour le faire tourner", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(BLUE, 0.6))


static func _ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 36:
		pts.append(c + Vector2(cos(TAU * k / 36.0) * rad.x, sin(TAU * k / 36.0) * rad.y))
	ci.draw_colored_polygon(pts, col)


# ── Little builders ─────────────────────────────────────────────

func _text(text: String) -> void:
	var l := _label(text, 18, Color(BLUE, 0.85))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	_side.add_child(l)


func _toggle(text: String, on: bool, press: Callable, size: Vector2, font := 17) -> Button:
	var b := _button(text, font, func() -> void:
		Sfx.play("click")
		press.call(), size)
	if on:
		b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
		b.add_theme_stylebox_override("focus", _box(YELLOW, BLUE, 3, 14))
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, size: int, on_press: Callable, min_size := Vector2(120, 46)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_color_override("font_disabled_color", Color(BLUE, 0.35))
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 14))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
	b.add_theme_stylebox_override("disabled", _box(Color(1, 1, 1, 0.5), Color(BLUE, 0.3), 2, 14))
	b.pressed.connect(on_press)
	return b


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 8
	b.content_margin_right = 8
	return b


class _Back:
	extends Control

	var studio: EggStudio

	func _draw() -> void:
		studio.paint_back(self)


class _Front:
	extends Control

	var studio: EggStudio

	func _draw() -> void:
		studio.paint_front(self)

	func _gui_input(event: InputEvent) -> void:
		studio.stage_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			studio._mouse = Vector2(-1, -1)


class _StickerButton:
	extends Button

	var sticker := ""
	var color := Color.WHITE

	func _draw() -> void:
		StampArt.draw(self, sticker, size / 2.0, minf(size.x, size.y) * 0.36, color)


class _Printer:
	extends Node2D

	var painter: Callable

	func _draw() -> void:
		painter.call(self)
