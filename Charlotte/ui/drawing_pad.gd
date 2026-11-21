class_name DrawingPad
extends CanvasLayer
## Charlotte's drawing paper, opened from her desk. Tools down the right: brushes (wax crayon, felt pen, watercolour, spray,
## rainbow pen, glitter; three sizes), the eraser, the paint pot (fills an area), the pipette (takes a colour off the
## paper), shapes (drag on the paper), writing and stamps (about fifty, in four boxes: `StampArt`). A stamp or a line of
## writing is first LAID ON the paper, not stuck: drag it, pull its corner to resize, its top knob to turn it, flip it,
## then "Poser" (or click elsewhere). Colours down the left: fourteen crayons and a mixer (a square and a rainbow strip).
## "Oups !" / "Refaire" go back and forth; "Mes dessins" is the drawer of every drawing she has kept, to carry on with one
## or to put it on the fridge. The button at the bottom right keeps the drawing (`done_text`).
##
## Strokes are painted straight into the image (`_dab`); shapes, words and stamps are drawn by a little SubViewport over a
## copy of the paper (`_bake`), and its picture becomes the paper, so they are as smooth as the rest of the UI.

signal closed(drawing: Image)

const PAPER := Vector2i(480, 320)
## Drawings kept on the fridge (newest), and in the drawer.
const KEEP := 4
const GALLERY_MAX := 48
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const PAPER_COLOR := Color("#FFFDF7")
const CRAYONS := ["#2B2B2B", "#E04F5F", "#FF8A3D", "#FFD23F", "#7CCB5A", "#3E8E5A", "#4FA3E0", "#1D4F91",
	"#7E57C2", "#FF7BA3", "#8D6E63", "#F2C29A", "#E8E8E8", "#B5442E"]
const SIZES := [3.0, 7.0, 14.0]
const SIZE_NAMES := ["Fin", "Moyen", "Gros"]
const TOOLS := [["pinceau", "Pinceaux"], ["gomme", "Gomme"], ["pot", "Remplir"], ["pipette", "Pipette"], ["formes", "Formes"],
	["texte", "Écrire"], ["etampes", "Étampes"]]
const BRUSHES := [["crayon", "Cire"], ["feutre", "Feutre"], ["aquarelle", "Aquarelle"], ["spray", "Spray"],
	["arcenciel", "Arc-en-ciel"], ["paillettes", "Paillettes"]]
const SHAPES := ["cercle", "carre", "triangle", "coeur", "etoile"]
## Stamp radius and letter height for the three sizes.
const STAMP_R := [16.0, 28.0, 44.0]
const TEXT_SIZE := [18, 28, 44]
const UNDO := 15
## How different from the clicked pixel a pixel may be (sum of the three channels, of 765) and still be filled.
const FILL_TOLERANCE := 44
const FILL_FRINGE := 130

## The words on the button that keeps the drawing ("Pour Papa et Maman !" at the service de garde).
var done_text := "Sur le frigo !"
## False where a drawing is for someone else (the service de garde): the drawer can't put one on the fridge.
var fridge_ok := true
var _image: Image
var _texture: ImageTexture
var _paper: TextureRect
var _preview: _Preview
var _flt: _Float
var _color := Color(CRAYONS[1])
var _tool := "pinceau"
var _brush := "crayon"
var _size_i := 1
var _shape := "cercle"
var _filled := false
var _stamp := "etoile"
var _cat := 0
var _last := Vector2(-1, -1)
var _drag_from := Vector2(-1, -1)
var _undo: Array[Image] = []
var _redo: Array[Image] = []
var _busy := false
var _dirty := false
var _from := ""
var _root: Control
var _panel: Panel
var _modes: VBoxContainer
var _options: HBoxContainer
var _options2: HFlowContainer
var _floatbox: VBoxContainer
var _mixer: _Mixer
var _typing: LineEdit
var _type_at := Vector2.ZERO
var _gal: Panel
var _gal_sel := ""
var _toast_label: Label
## The stamp or the words laid on the paper and not yet fixed: {kind, stamp|text, at, r|size, rot, flip, color}.
var _float := {}
var _fmode := ""
var _fgrab := Vector2.ZERO
var _fstart_len := 1.0
var _fstart_val := 1.0
var _hue := 0.0
var _gx := 0
var _gy := 0
var _grain := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	layer = 60


func _ready() -> void:
	_make_grain()
	_image = Image.create(PAPER.x, PAPER.y, false, Image.FORMAT_RGBA8)
	_image.fill(PAPER_COLOR)
	_texture = ImageTexture.create_from_image(_image)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(160, 40)
	_panel.size = Vector2(960, 640)
	_panel.add_theme_stylebox_override("panel", _box(Color("#F6EFE4"), BLUE, 6, 26))
	_root.add_child(_panel)
	var title := Label.new()
	title.text = "Le dessin de Charlotte"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BLUE)
	title.position = Vector2(0, 14)
	title.size = Vector2(960, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	_paper = TextureRect.new()
	_paper.texture = _texture
	_paper.position = Vector2(240, 70)
	_paper.size = Vector2(PAPER)
	_paper.clip_contents = true
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.gui_input.connect(_on_paper_input)
	_paper.mouse_exited.connect(func(): _preview.hide_ghost())
	_panel.add_child(_paper)
	_preview = _Preview.new()
	_preview.pad = self
	_preview.size = Vector2(PAPER)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_preview)
	_flt = _Float.new()
	_flt.pad = self
	_flt.size = Vector2(PAPER)
	_flt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_flt)
	var frame := Panel.new()
	frame.position = _paper.position - Vector2(6, 6)
	frame.size = _paper.size + Vector2(12, 12)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), Color("#C8A27A"), 6, 6))
	_panel.add_child(frame)
	# Crayons down the left, the mixer under them.
	var crayons := GridContainer.new()
	crayons.columns = 3
	crayons.position = Vector2(40, 74)
	crayons.add_theme_constant_override("h_separation", 8)
	crayons.add_theme_constant_override("v_separation", 8)
	_panel.add_child(crayons)
	for hex in CRAYONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 28)
		b.add_theme_stylebox_override("normal", _box(Color(hex), Color(hex).darkened(0.35), 2, 8))
		b.add_theme_stylebox_override("hover", _box(Color(hex).lightened(0.15), BLUE, 3, 8))
		b.add_theme_stylebox_override("pressed", _box(Color(hex), YELLOW, 4, 8))
		b.pressed.connect(func():
			_set_color(Color(hex))
			_mixer.show_color(_color))
		crayons.add_child(b)
	_mixer = _Mixer.new()
	_mixer.pad = self
	_mixer.position = Vector2(40, 262)
	_mixer.size = Vector2(148, 122)
	_panel.add_child(_mixer)
	_mixer.show_color(_color)
	# The tools down the right, their choices in two rows under the paper.
	_modes = VBoxContainer.new()
	_modes.position = Vector2(756, 72)
	_modes.add_theme_constant_override("separation", 4)
	_panel.add_child(_modes)
	_floatbox = VBoxContainer.new()
	_floatbox.position = Vector2(756, 436)
	_floatbox.add_theme_constant_override("separation", 4)
	_panel.add_child(_floatbox)
	_options = HBoxContainer.new()
	_options.position = Vector2(40, 402)
	_options.add_theme_constant_override("separation", 4)
	_panel.add_child(_options)
	_options2 = HFlowContainer.new()
	_options2.position = Vector2(40, 460)
	_options2.size = Vector2(700, 100)
	_options2.add_theme_constant_override("h_separation", 4)
	_options2.add_theme_constant_override("v_separation", 4)
	_panel.add_child(_options2)
	_refresh()
	var bar := HBoxContainer.new()
	bar.position = Vector2(28, 580)
	bar.size = Vector2(904, 48)
	bar.add_theme_constant_override("separation", 10)
	_panel.add_child(bar)
	_action(bar, "Effacer tout", func():
		_discard_float()
		_remember()
		_image.fill(PAPER_COLOR)
		_texture.update(_image), 138)
	_action(bar, "Oups !", _take_back, 92)
	_action(bar, "Refaire", _do_again, 100)
	_action(bar, "Mes dessins", _open_gallery, 142)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_action(bar, "Annuler", func(): _close(null), 108)
	var done := _action(bar, done_text, _finish, 200)
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))


func _process(_delta: float) -> void:
	# The spray keeps spraying while the button is held still.
	if _tool == "pinceau" and _brush == "spray" and _last.x >= 0.0 and not _busy and _gal == null:
		_dab(_preview.mouse, _radius())
		_texture.update(_image)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _gal:
			_close_gallery()
		elif _typing:
			_stop_typing(false)
		elif not _float.is_empty():
			_discard_float()
		else:
			_close(null)
	elif event.is_action_pressed("ui_accept") and not _float.is_empty() and not _typing and _gal == null:
		get_viewport().set_input_as_handled()
		_commit_float()
	elif event is InputEventKey and event.pressed and not _typing and not _float.is_empty() \
			and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE):
		get_viewport().set_input_as_handled()
		_discard_float()


# ── Colour ──────────────────────────────────────────────────────

func _set_color(c: Color) -> void:
	_color = Color(c, 1.0)
	if _tool == "gomme" or _tool == "pipette":
		_tool = "pinceau"
	if not _float.is_empty():
		_float.color = _color
		_flt.queue_redraw()
	_refresh()


# ── Drawing ─────────────────────────────────────────────────────

func _on_paper_input(event: InputEvent) -> void:
	if _busy or _gal:
		return
	if event is InputEventMouseMotion:
		_preview.mouse = event.position
		_preview.queue_redraw()
	match _tool:
		"pinceau", "gomme":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				_last = event.position if event.pressed else Vector2(-1, -1)
				if event.pressed:
					_remember()
					_gx = _rng.randi() & 63
					_gy = _rng.randi() & 63
					_stroke(event.position, event.position)
			elif event is InputEventMouseMotion and _last.x >= 0.0:
				_stroke(_last, event.position)
				_last = event.position
		"pot":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_remember()
				_flood(Vector2i(clampi(int(event.position.x), 0, PAPER.x - 1), clampi(int(event.position.y), 0, PAPER.y - 1)), _color)
				Sfx.play("pop")
		"pipette":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var p := Vector2i(clampi(int(event.position.x), 0, PAPER.x - 1), clampi(int(event.position.y), 0, PAPER.y - 1))
				_color = Color(_image.get_pixelv(p), 1.0)
				_mixer.show_color(_color)
				_tool = "pinceau"
				Sfx.play("pop")
				_refresh()
		"formes":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_drag_from = event.position
				elif _drag_from.x >= 0.0:
					var rect := Rect2(_drag_from, Vector2.ZERO).expand(event.position)
					_drag_from = Vector2(-1, -1)
					# A click without a drag still makes a shape, of a fair size.
					if rect.size.length() < 8.0:
						rect = Rect2(event.position - Vector2(30, 30), Vector2(60, 60))
					_bake({"kind": "shape", "shape": _shape, "rect": rect, "filled": _filled, "color": _color, "width": SIZES[_size_i]})
		"etampes", "texte":
			_float_input(event)


func _radius() -> float:
	if _tool == "gomme":
		return SIZES[_size_i] * 2.0
	var r: float = SIZES[_size_i]
	match _brush:
		"aquarelle":
			return r * 1.7
		"spray":
			return r * 2.4
		"paillettes":
			return r * 1.4
		"feutre":
			return r * 0.85
	return r


func _stroke(a: Vector2, b: Vector2) -> void:
	var r := _radius()
	var steps := maxi(1, int(a.distance_to(b) / maxf(1.0, r * 0.35)))
	for i in steps + 1:
		_dab(a.lerp(b, float(i) / steps), r)
	_texture.update(_image)
	_dirty = true


## One touch of the brush at `c`. Every brush works the pixels in its own way (see BRUSHES).
func _dab(c: Vector2, r: float) -> void:
	if _tool == "gomme":
		_disc(c, r, func(_x: int, _y: int, _d: float) -> float: return 1.0, PAPER_COLOR)
		return
	match _brush:
		"crayon":
			# Wax: it catches the paper's grain, so little specks stay bare, more at the edge.
			_disc(c, r, func(x: int, y: int, d: float) -> float:
				var g := _grain[((x + _gx) & 63) + (((y + _gy) & 63) << 6)]
				return 0.94 if g < 0.8 - d * 0.35 else 0.0, _color)
		"feutre":
			_disc(c, r, func(_x: int, _y: int, d: float) -> float: return 0.95 if d < 0.85 else 0.55, _color)
		"aquarelle":
			_disc(c, r, func(_x: int, _y: int, d: float) -> float: return 0.1 * (1.0 - d * d), _color)
		"spray":
			for i in int(r * r * 0.18) + 2:
				var p := c + Vector2.from_angle(_rng.randf() * TAU) * r * sqrt(_rng.randf()) * (0.4 + 0.6 * _rng.randf())
				_plot(int(p.x), int(p.y), _color, 0.75)
				if r > 20.0 and _rng.randf() < 0.3:
					_plot(int(p.x) + 1, int(p.y), _color, 0.5)
		"arcenciel":
			_hue = fposmod(_hue + 0.012, 1.0)
			_disc(c, r, func(_x: int, _y: int, d: float) -> float: return 0.95 if d < 0.85 else 0.5, Color.from_hsv(_hue, 0.8, 1.0))
		"paillettes":
			_disc(c, r, func(_x: int, _y: int, d: float) -> float: return 0.16 * (1.0 - d * d), _color)
			for i in 2 + int(r * 0.25):
				var p := c + Vector2.from_angle(_rng.randf() * TAU) * r * sqrt(_rng.randf())
				var x := int(p.x)
				var y := int(p.y)
				var bright := _color.lightened(0.55) if _rng.randf() < 0.6 else Color("#FFF6C8")
				_plot(x, y, Color.WHITE, 0.95)
				if _rng.randf() < 0.5:
					for off: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						_plot(x + off.x, y + off.y, bright, 0.8)
					if r > 12.0:
						_plot(x + 2, y, bright, 0.5)
						_plot(x - 2, y, bright, 0.5)


## Paints a disc of radius `r` at `c`: `alpha(x, y, d)` gives each pixel's opacity (d = 0 at the middle, 1 at the rim).
func _disc(c: Vector2, r: float, alpha: Callable, col: Color) -> void:
	var x0 := maxi(0, int(c.x - r))
	var x1 := mini(PAPER.x - 1, int(c.x + r))
	var y0 := maxi(0, int(c.y - r))
	var y1 := mini(PAPER.y - 1, int(c.y + r))
	var r2 := r * r
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d2 := Vector2(x, y).distance_squared_to(c)
			if d2 <= r2:
				var a: float = alpha.call(x, y, sqrt(d2) / maxf(r, 0.001))
				if a > 0.0:
					_plot(x, y, col, a)


func _plot(x: int, y: int, col: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= PAPER.x or y >= PAPER.y:
		return
	if a >= 0.99:
		_image.set_pixel(x, y, col)
	else:
		_image.set_pixel(x, y, _image.get_pixel(x, y).lerp(col, a))


## A 64×64 tile of paper grain (clumped noise, 0 to 1), wrapped over the sheet.
func _make_grain() -> void:
	var rg := RandomNumberGenerator.new()
	rg.seed = 2026
	var raw := PackedFloat32Array()
	raw.resize(64 * 64)
	for i in raw.size():
		raw[i] = rg.randf()
	_grain.resize(64 * 64)
	for y in 64:
		for x in 64:
			var v := (raw[x + y * 64] + raw[((x + 1) & 63) + y * 64] + raw[x + ((y + 1) & 63) * 64] + raw[((x + 1) & 63) + ((y + 1) & 63) * 64]) * 0.25
			_grain[x + y * 64] = clampf((v - 0.5) * 1.6 + 0.5, 0.0, 1.0)


## The paint pot: floods the area round `at` (pixels close to its colour) with `col`, taking in the soft fringe of the lines.
func _flood(at: Vector2i, col: Color) -> void:
	var w := PAPER.x
	var h := PAPER.y
	var data := _image.get_data()
	var i0 := (at.y * w + at.x) * 4
	var sr := data[i0]
	var sg := data[i0 + 1]
	var sb := data[i0 + 2]
	var fr := col.r8
	var fg := col.g8
	var fb := col.b8
	if absi(sr - fr) + absi(sg - fg) + absi(sb - fb) < 6:
		return
	var mask := PackedByteArray()
	mask.resize(w * h)
	var stack: Array[Vector2i] = [at]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var x := p.x
		var y := p.y
		if mask[y * w + x] != 0 or not _near(data, (y * w + x) * 4, sr, sg, sb, FILL_TOLERANCE):
			continue
		while x > 0 and mask[y * w + x - 1] == 0 and _near(data, (y * w + x - 1) * 4, sr, sg, sb, FILL_TOLERANCE):
			x -= 1
		var up := false
		var down := false
		while x < w and mask[y * w + x] == 0 and _near(data, (y * w + x) * 4, sr, sg, sb, FILL_TOLERANCE):
			mask[y * w + x] = 1
			if y > 0:
				var ok := mask[(y - 1) * w + x] == 0 and _near(data, ((y - 1) * w + x) * 4, sr, sg, sb, FILL_TOLERANCE)
				if ok and not up:
					stack.append(Vector2i(x, y - 1))
				up = ok
			if y < h - 1:
				var ok2 := mask[(y + 1) * w + x] == 0 and _near(data, ((y + 1) * w + x) * 4, sr, sg, sb, FILL_TOLERANCE)
				if ok2 and not down:
					stack.append(Vector2i(x, y + 1))
				down = ok2
			x += 1
	# One more pixel into the soft edge of what borders it, so no pale halo is left round the lines.
	var grown := mask.duplicate()
	for y in h:
		for x in w:
			if mask[y * w + x] != 0:
				continue
			var near_fill := (x > 0 and mask[y * w + x - 1] == 1) or (x < w - 1 and mask[y * w + x + 1] == 1) \
				or (y > 0 and mask[(y - 1) * w + x] == 1) or (y < h - 1 and mask[(y + 1) * w + x] == 1)
			if near_fill and _near(data, (y * w + x) * 4, sr, sg, sb, FILL_FRINGE):
				grown[y * w + x] = 1
	for k in w * h:
		if grown[k] != 0:
			data[k * 4] = fr
			data[k * 4 + 1] = fg
			data[k * 4 + 2] = fb
			data[k * 4 + 3] = 255
	_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	_texture.set_image(_image)
	_dirty = true


func _near(data: PackedByteArray, i: int, r: int, g: int, b: int, tol: int) -> bool:
	return absi(data[i] - r) + absi(data[i + 1] - g) + absi(data[i + 2] - b) <= tol


func _remember() -> void:
	_undo.append(_image.duplicate())
	_redo.clear()
	_dirty = true
	if _undo.size() > UNDO:
		_undo.pop_front()


func _take_back() -> void:
	if _busy or _gal:
		return
	if not _float.is_empty() or _typing:
		_discard_float()
		return
	if _undo.is_empty():
		return
	_redo.append(_image.duplicate())
	_image = _undo.pop_back()
	_texture.set_image(_image)
	Sfx.play("swoosh")


func _do_again() -> void:
	if _busy or _gal or _redo.is_empty():
		return
	_commit_float_now()
	_undo.append(_image.duplicate())
	_image = _redo.pop_back()
	_texture.set_image(_image)
	Sfx.play("swoosh")


## Draws a shape, a word or a stamp over the paper: a small viewport shows the paper with the thing on it, once, and
## what it rendered becomes the paper.
func _bake(item: Dictionary) -> void:
	_busy = true
	_remember()
	var vp := SubViewport.new()
	vp.size = PAPER
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var under := Sprite2D.new()
	under.texture = ImageTexture.create_from_image(_image)
	under.centered = false
	vp.add_child(under)
	var ink := _Ink.new()
	ink.item = item
	vp.add_child(ink)
	await RenderingServer.frame_post_draw
	var out := vp.get_texture().get_image()
	out.convert(Image.FORMAT_RGBA8)
	_image = out
	_texture.set_image(_image)
	vp.queue_free()
	_busy = false
	_preview.queue_redraw()


# ── The stamp or the words laid on the paper ────────────────────

func _float_half() -> Vector2:
	if _float.kind == "text":
		var size: float = _float.size
		var w := ThemeDB.fallback_font.get_string_size(_float.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x
		return Vector2(w * 0.5 + 4.0, size * 0.62)
	var r: float = _float.r
	return Vector2(r * 1.05, r * 1.05)


func _float_hit(p: Vector2) -> String:
	var h := _float_half()
	var rot: float = _float.rot
	var at: Vector2 = _float.at
	if p.distance_to(at + Vector2(0, -h.y - 28.0).rotated(rot)) <= 14.0:
		return "rotate"
	if p.distance_to(at + Vector2(h.x, h.y).rotated(rot)) <= 14.0:
		return "scale"
	var l := (p - at).rotated(-rot)
	if absf(l.x) <= h.x and absf(l.y) <= h.y:
		return "move"
	return ""


func _float_value() -> float:
	return _float.size if _float.kind == "text" else _float.r


func _float_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var hit := _float_hit(event.position) if not _float.is_empty() else ""
			if hit != "":
				_fmode = hit
				_fgrab = _float.at - event.position
				_fstart_len = maxf(8.0, (event.position - _float.at).length())
				_fstart_val = _float_value()
				return
			if _typing:
				_stop_typing(true)
			if not _float.is_empty():
				await _commit_float()
			_place(event.position)
		else:
			_fmode = ""
	elif event is InputEventMouseMotion and _fmode != "" and not _float.is_empty():
		match _fmode:
			"move":
				_float.at = (event.position + _fgrab).clamp(Vector2.ZERO, Vector2(PAPER))
			"scale":
				var k: float = (event.position - _float.at).length() / _fstart_len
				if _float.kind == "text":
					_float.size = clampf(_fstart_val * k, 10.0, 120.0)
				else:
					_float.r = clampf(_fstart_val * k, 8.0, 200.0)
			"rotate":
				var a: float = (event.position - _float.at).angle() + PI / 2.0
				# A little pull toward upright, so it is easy to stand it straight.
				_float.rot = 0.0 if absf(wrapf(a, -PI, PI)) < 0.09 else a
		_flt.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and not _float.is_empty() \
			and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
		if event.shift_pressed:
			_float.rot += 0.12 * (1.0 if up else -1.0)
		elif _float.kind == "text":
			_float.size = clampf(_float.size * (1.08 if up else 0.93), 10.0, 120.0)
		else:
			_float.r = clampf(_float.r * (1.08 if up else 0.93), 8.0, 200.0)
		_flt.queue_redraw()


func _place(at: Vector2) -> void:
	if _tool == "texte":
		_start_typing(at)
		return
	_float = {"kind": "stamp", "stamp": _stamp, "at": at, "r": STAMP_R[_size_i], "rot": 0.0, "flip": false, "color": _color}
	Sfx.play("pop")
	_flt.queue_redraw()
	_refresh()


## Fixes the laid thing onto the paper.
func _commit_float() -> void:
	if _float.is_empty():
		return
	var item := _float
	_float = {}
	_fmode = ""
	_flt.queue_redraw()
	_refresh()
	await _bake(item)


## The same, when nothing may wait (the paper is about to be kept or changed).
func _commit_float_now() -> void:
	if _float.is_empty():
		return
	_commit_float()


func _discard_float() -> void:
	if _typing:
		_stop_typing(false)
	_float = {}
	_fmode = ""
	_flt.queue_redraw()
	_refresh()


# ── Writing ─────────────────────────────────────────────────────

func _start_typing(at: Vector2) -> void:
	if _typing:
		_stop_typing(true)
	_type_at = at
	_typing = LineEdit.new()
	_typing.placeholder_text = "Écris ici…"
	_typing.max_length = 40
	_typing.add_theme_font_size_override("font_size", 20)
	_typing.add_theme_color_override("font_color", _color if _color.v < 0.85 else BLUE)
	_typing.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.92), BLUE, 2, 10))
	_typing.add_theme_stylebox_override("focus", _box(Color(1, 1, 1, 0.95), YELLOW, 3, 10))
	_typing.custom_minimum_size = Vector2(220, 40)
	_typing.position = _paper.position + Vector2(clampf(at.x - 20.0, 0.0, PAPER.x - 220.0), clampf(at.y - 50.0, 0.0, PAPER.y - 40.0))
	_typing.text_submitted.connect(func(_t: String): _stop_typing(true))
	_panel.add_child(_typing)
	_typing.grab_focus()
	_preview.queue_redraw()


## The words are typed; they are then laid on the paper like a stamp (to move, turn, resize) rather than fixed at once.
func _stop_typing(keep: bool) -> void:
	if not _typing:
		return
	var text := _typing.text.strip_edges()
	_typing.queue_free()
	_typing = null
	_preview.queue_redraw()
	if keep and not text.is_empty():
		var size: int = TEXT_SIZE[_size_i]
		var w := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_float = {"kind": "text", "text": text, "at": (_type_at + Vector2(w * 0.5, 0.0)).clamp(Vector2.ZERO, Vector2(PAPER)),
			"size": float(size), "rot": 0.0, "flip": false, "color": _color}
		Sfx.play("pop")
		_flt.queue_redraw()
		_refresh()


# ── What the tools draw (the baked ink and the ghost under the mouse) ──

static func draw_item(ci: CanvasItem, item: Dictionary) -> void:
	match item.kind:
		"shape":
			_draw_shape(ci, item.shape, item.rect, item.filled, item.color, item.width)
		"stamp":
			ci.draw_set_transform(item.at, item.get("rot", 0.0), Vector2(-1.0 if item.get("flip", false) else 1.0, 1.0))
			_draw_stamp(ci, item.stamp, Vector2.ZERO, item.r, item.color)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"text":
			var font := ThemeDB.fallback_font
			var size: int = int(item.size)
			var w := font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			ci.draw_set_transform(item.at, item.get("rot", 0.0), Vector2.ONE)
			ci.draw_string(font, Vector2(-w * 0.5, size * 0.35), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, item.color)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _shape_points(shape: String, rect: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := rect.get_center()
	var h := rect.size / 2.0
	match shape:
		"cercle":
			for k in 48:
				pts.append(c + Vector2(cos(TAU * k / 48.0) * h.x, sin(TAU * k / 48.0) * h.y))
		"carre":
			pts = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		"triangle":
			pts = PackedVector2Array([Vector2(c.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		"coeur":
			for k in 48:
				var t := TAU * k / 48.0
				var p := Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)))
				pts.append(c + Vector2(p.x / 17.0 * h.x, (p.y + 2.5) / 15.0 * h.y))
		"etoile":
			for k in 10:
				var a := -PI / 2.0 + TAU * k / 10.0
				var f := 1.0 if k % 2 == 0 else 0.45
				pts.append(c + Vector2(cos(a) * h.x * f, sin(a) * h.y * f + h.y * 0.1))
	return pts


static func _draw_shape(ci: CanvasItem, shape: String, rect: Rect2, filled: bool, color: Color, width: float) -> void:
	var pts := _shape_points(shape, rect)
	if pts.size() < 3:
		return
	if filled and Geometry2D.triangulate_polygon(pts).size() > 0:
		ci.draw_colored_polygon(pts, color)
	var ring := pts.duplicate()
	ring.append(pts[0])
	ci.draw_polyline(ring, color.darkened(0.25) if filled else color, width, true)


static func _draw_stamp(ci: CanvasItem, stamp: String, c: Vector2, r: float, color: Color) -> void:
	StampArt.draw(ci, stamp, c, r, color)


## The ink baked into the paper.
class _Ink:
	extends Node2D

	var item := {}

	func _draw() -> void:
		DrawingPad.draw_item(self, item)


## Over the paper: the shape being dragged out, the stamp or the words' place under the mouse, faded.
class _Preview:
	extends Control

	var pad: DrawingPad
	var mouse := Vector2(-1, -1)

	func hide_ghost() -> void:
		mouse = Vector2(-1, -1)
		queue_redraw()

	func _init() -> void:
		modulate = Color(1, 1, 1, 0.55)

	func _draw() -> void:
		if pad._busy or mouse.x < 0.0 or pad._gal:
			return
		match pad._tool:
			"formes":
				if pad._drag_from.x >= 0.0:
					DrawingPad._draw_shape(self, pad._shape, Rect2(pad._drag_from, Vector2.ZERO).expand(mouse), pad._filled, pad._color, SIZES[pad._size_i])
			"etampes":
				if pad._float.is_empty():
					DrawingPad._draw_stamp(self, pad._stamp, mouse, STAMP_R[pad._size_i], pad._color)
			"texte":
				if not pad._typing and pad._float.is_empty():
					var h: float = TEXT_SIZE[pad._size_i]
					draw_line(mouse + Vector2(0, -h * 0.5), mouse + Vector2(0, h * 0.5), pad._color, 2.0)
			"pinceau", "gomme":
				draw_arc(mouse, pad._radius(), 0.0, TAU, 24, Color(0.2, 0.2, 0.3), 1.5, true)
			"pot", "pipette":
				draw_arc(mouse, 7.0, 0.0, TAU, 16, Color(0.2, 0.2, 0.3), 2.0, true)
				draw_line(mouse + Vector2(-11, 0), mouse + Vector2(11, 0), Color(0.2, 0.2, 0.3), 1.5)
				draw_line(mouse + Vector2(0, -11), mouse + Vector2(0, 11), Color(0.2, 0.2, 0.3), 1.5)


## The laid stamp or words, with their frame and handles: the corner to resize, the knob on top to turn.
class _Float:
	extends Control

	var pad: DrawingPad

	func _draw() -> void:
		if pad._float.is_empty():
			return
		var f: Dictionary = pad._float
		DrawingPad.draw_item(self, f)
		var h := pad._float_half()
		var rot: float = f.rot
		var at: Vector2 = f.at
		var corners := []
		for p: Vector2 in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
			corners.append(at + p.rotated(rot))
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], Color(DrawingPad.BLUE, 0.85), 1.6, 5.0)
		var knob := at + Vector2(0, -h.y - 28.0).rotated(rot)
		draw_line(at + Vector2(0, -h.y).rotated(rot), knob, Color(DrawingPad.BLUE, 0.85), 1.6)
		draw_circle(knob, 9.0, Color.WHITE)
		draw_arc(knob, 9.0, 0.0, TAU, 20, DrawingPad.BLUE, 2.0, true)
		draw_arc(knob, 4.0, 0.6, TAU - 0.6, 12, DrawingPad.BLUE, 1.8, true)
		var grip: Vector2 = corners[2]
		draw_rect(Rect2(grip - Vector2(8, 8), Vector2(16, 16)), Color.WHITE)
		draw_rect(Rect2(grip - Vector2(8, 8), Vector2(16, 16)), DrawingPad.BLUE, false, 2.0)
		draw_line(grip + Vector2(-3, -3), grip + Vector2(3, 3), DrawingPad.BLUE, 1.8)


## Any colour: a square (paleness across, darkness down) over a strip of every hue.
class _Mixer:
	extends Control

	var pad: DrawingPad
	var hue := 0.0
	var sat := 1.0
	var val := 1.0
	var _sv: ImageTexture
	var _bar: ImageTexture
	var _sv_hue := -1.0
	var _grab := ""
	const SV := Rect2(0, 0, 148, 96)
	const BAR := Rect2(0, 104, 148, 16)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var bar := Image.create(148, 1, false, Image.FORMAT_RGBA8)
		for x in 148:
			bar.set_pixel(x, 0, Color.from_hsv(x / 147.0, 1.0, 1.0))
		_bar = ImageTexture.create_from_image(bar)

	func show_color(c: Color) -> void:
		if c.s > 0.02:
			hue = c.h
		sat = c.s
		val = c.v
		queue_redraw()

	func _make_sv() -> void:
		_sv_hue = hue
		var img := Image.create(74, 48, false, Image.FORMAT_RGBA8)
		for y in 48:
			for x in 74:
				img.set_pixel(x, y, Color.from_hsv(hue, x / 73.0, 1.0 - y / 47.0))
		_sv = ImageTexture.create_from_image(img)

	func _draw() -> void:
		if _sv == null or not is_equal_approx(_sv_hue, hue):
			_make_sv()
		draw_texture_rect(_sv, SV, false)
		draw_rect(SV, Color(DrawingPad.BLUE), false, 2.0)
		draw_texture_rect(_bar, BAR, false)
		draw_rect(BAR, Color(DrawingPad.BLUE), false, 2.0)
		var p := Vector2(sat * SV.size.x, (1.0 - val) * SV.size.y)
		draw_arc(p, 6.0, 0.0, TAU, 16, Color.WHITE, 3.0, true)
		draw_arc(p, 6.0, 0.0, TAU, 16, Color(0.1, 0.1, 0.2), 1.2, true)
		var hx := hue * BAR.size.x
		draw_rect(Rect2(hx - 3, BAR.position.y - 3, 6, BAR.size.y + 6), Color.WHITE)
		draw_rect(Rect2(hx - 3, BAR.position.y - 3, 6, BAR.size.y + 6), Color(0.1, 0.1, 0.2), false, 1.5)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_grab = "sv" if SV.has_point(event.position) else ("bar" if BAR.grow(6).has_point(event.position) else "")
			else:
				_grab = ""
		if (event is InputEventMouseButton and event.pressed or event is InputEventMouseMotion and _grab != "") and _grab != "":
			if _grab == "sv":
				sat = clampf(event.position.x / SV.size.x, 0.0, 1.0)
				val = 1.0 - clampf(event.position.y / SV.size.y, 0.0, 1.0)
			else:
				hue = clampf(event.position.x / BAR.size.x, 0.0, 1.0)
			queue_redraw()
			pad._set_color(Color.from_hsv(hue, sat, val))


## A square button with a little drawing on it instead of words.
class _IconButton:
	extends Button

	var paint: Callable

	func _draw() -> void:
		paint.call(self, size / 2.0)


# ── Saved drawings (the fridge, the drawer) ─────────────────────

## The current game's drawings folder: the ones on the fridge.
static func folder() -> String:
	return GameState.slot_dir() + "/drawings"


## The kept drawings, oldest first.
static func saved() -> Array[Image]:
	var out: Array[Image] = []
	var dir := DirAccess.open(folder())
	if dir == null:
		return out
	var names := Array(dir.get_files()).filter(func(n: String): return n.ends_with(".png"))
	names.sort()
	for n in names:
		var img := Image.load_from_file(folder() + "/" + n)
		if img:
			out.append(img)
	return out


## Takes every drawing off the fridge and out of the drawer (a new game).
static func forget_all() -> void:
	for f in [folder(), gallery_folder()]:
		var dir := DirAccess.open(f)
		if dir == null:
			continue
		for n in dir.get_files():
			dir.remove(n)


## The drawing she made at the service de garde for her parents, until it is on the fridge (kept apart from the fridge's).
static func pending_path() -> String:
	return GameState.slot_dir() + "/dessin_a_rapporter.png"


static func hold_pending(img: Image) -> void:
	DirAccess.make_dir_recursive_absolute(GameState.slot_dir())
	img.save_png(pending_path())


static func has_pending() -> bool:
	return FileAccess.file_exists(pending_path())


static func pending() -> Image:
	return Image.load_from_file(pending_path()) if FileAccess.file_exists(pending_path()) else null


## Home: the drawing she brought goes up on the fridge.
static func put_pending_on_fridge() -> void:
	var img := pending()
	if img:
		keep(img)
		DirAccess.remove_absolute(pending_path())


## Keeps a new drawing on the fridge, dropping the oldest beyond KEEP.
static func keep(img: Image) -> void:
	DirAccess.make_dir_recursive_absolute(folder())
	img.save_png("%s/%d.png" % [folder(), int(Time.get_unix_time_from_system() * 1000.0)])
	var dir := DirAccess.open(folder())
	var names := Array(dir.get_files()).filter(func(n: String): return n.ends_with(".png"))
	names.sort()
	while names.size() > KEEP:
		dir.remove(names.pop_front())


## The drawer: every drawing she has finished (or left in it), newest first, GALLERY_MAX at most.
static func gallery_folder() -> String:
	return GameState.slot_dir() + "/galerie"


static func gallery_names() -> Array:
	var dir := DirAccess.open(gallery_folder())
	if dir == null:
		return []
	var names := Array(dir.get_files()).filter(func(n: String): return n.ends_with(".png"))
	names.sort()
	names.reverse()
	return names


## Puts a drawing in the drawer (in place of `replace`, the file it was opened from, if any) and returns its file name.
## Test runs (`GameState.enabled()` false) leave the drawer alone.
static func to_gallery(img: Image, replace := "") -> String:
	if not GameState.enabled():
		return ""
	DirAccess.make_dir_recursive_absolute(gallery_folder())
	if replace != "" and FileAccess.file_exists(gallery_folder() + "/" + replace):
		DirAccess.remove_absolute(gallery_folder() + "/" + replace)
	var name := "%d.png" % int(Time.get_unix_time_from_system() * 1000.0)
	img.save_png(gallery_folder() + "/" + name)
	var names := gallery_names()
	while names.size() > GALLERY_MAX:
		DirAccess.remove_absolute(gallery_folder() + "/" + names.pop_back())
	return name


# ── The drawer ──────────────────────────────────────────────────

func _save_current() -> void:
	if _dirty:
		_from = DrawingPad.to_gallery(_image, _from)
		_dirty = false


func _open_gallery() -> void:
	if _gal or _busy:
		return
	if not _float.is_empty() or _typing:
		_commit_float_now()
		await get_tree().create_timer(0.15).timeout
	_save_current()
	_gal_sel = ""
	_gal = Panel.new()
	_gal.position = Vector2(28, 62)
	_gal.size = Vector2(904, 506)
	_gal.add_theme_stylebox_override("panel", _box(Color("#F6EFE4"), Color("#C8A27A"), 5, 18))
	_panel.add_child(_gal)
	var t := Label.new()
	t.text = "Mes dessins"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", BLUE)
	t.position = Vector2(0, 10)
	t.size = Vector2(904, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gal.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.name = "scroll"
	scroll.position = Vector2(20, 56)
	scroll.size = Vector2(864, 372)
	_gal.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "grid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var row := HBoxContainer.new()
	row.position = Vector2(20, 442)
	row.size = Vector2(864, 50)
	row.add_theme_constant_override("separation", 10)
	_gal.add_child(row)
	_action(row, "Nouvelle feuille", func():
		_image.fill(PAPER_COLOR)
		_texture.set_image(_image)
		_undo.clear()
		_redo.clear()
		_from = ""
		_dirty = false
		_close_gallery(), 170)
	_action(row, "Continuer", func(): _gallery_open_selected(), 130)
	if fridge_ok:
		_action(row, "Sur le frigo", func(): _gallery_fridge(), 140)
	_action(row, "Jeter", func(): _gallery_throw(), 90)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	_action(row, "Retour", func(): _close_gallery(), 110)
	_fill_gallery()


func _fill_gallery() -> void:
	var grid: GridContainer = _gal.get_node("scroll/grid")
	for child in grid.get_children():
		child.queue_free()
	var names := DrawingPad.gallery_names()
	if names.is_empty():
		var l := Label.new()
		l.text = "Pas encore de dessin rangé…"
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", BLUE)
		grid.add_child(l)
		return
	for n: String in names:
		var img := Image.load_from_file(DrawingPad.gallery_folder() + "/" + n)
		if img == null:
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(206, 140)
		var sel := n == _gal_sel
		b.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if sel else Color.WHITE, YELLOW if sel else Color("#C8A27A"), 5 if sel else 2, 10))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 3, 10))
		b.add_theme_stylebox_override("pressed", _box(Color("#FFF4C2"), YELLOW, 5, 10))
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.position = Vector2(8, 8)
		tr.size = Vector2(190, 124)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
		b.pressed.connect(func():
			_gal_sel = n
			_fill_gallery())
		grid.add_child(b)


func _gallery_open_selected() -> void:
	if _gal_sel == "":
		_toast("Choisis un dessin d'abord !")
		return
	var img := Image.load_from_file(DrawingPad.gallery_folder() + "/" + _gal_sel)
	if img == null:
		return
	img.convert(Image.FORMAT_RGBA8)
	_image = img
	_texture.set_image(_image)
	_undo.clear()
	_redo.clear()
	_from = _gal_sel
	_dirty = false
	_close_gallery()


func _gallery_fridge() -> void:
	if _gal_sel == "":
		_toast("Choisis un dessin d'abord !")
		return
	var img := Image.load_from_file(DrawingPad.gallery_folder() + "/" + _gal_sel)
	if img:
		DrawingPad.keep(img)
		Sfx.play("chime")
		_toast("Sur le frigo !")


func _gallery_throw() -> void:
	if _gal_sel == "":
		_toast("Choisis un dessin d'abord !")
		return
	DirAccess.remove_absolute(DrawingPad.gallery_folder() + "/" + _gal_sel)
	if _from == _gal_sel:
		_from = ""
	_gal_sel = ""
	Sfx.play("swoosh")
	_fill_gallery()


func _close_gallery() -> void:
	if _gal:
		_gal.queue_free()
		_gal = null


## A word that shows a moment at the top of the panel.
func _toast(text: String) -> void:
	if _toast_label:
		_toast_label.queue_free()
	_toast_label = Label.new()
	_toast_label.text = text
	_toast_label.add_theme_font_size_override("font_size", 24)
	_toast_label.add_theme_color_override("font_color", BLUE)
	_toast_label.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	_toast_label.position = Vector2(330, 8)
	_toast_label.z_index = 10
	_panel.add_child(_toast_label)
	var label := _toast_label
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)


# ── UI ──────────────────────────────────────────────────────────

func _refresh() -> void:
	if _typing and _tool != "texte":
		_stop_typing(true)
	for child in _modes.get_children():
		_modes.remove_child(child)
		child.queue_free()
	for t: Array in TOOLS:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(160, 40)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if t[0] == _tool else Color.WHITE, BLUE, 2, 14))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
		b.pressed.connect(func():
			if not _float.is_empty() and t[0] != _tool:
				await _commit_float()
			_tool = t[0]
			_refresh())
		_modes.add_child(b)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(160, 26)
	swatch.color = PAPER_COLOR if _tool == "gomme" else _color
	_modes.add_child(swatch)
	# The laid stamp's own buttons.
	for child in _floatbox.get_children():
		_floatbox.remove_child(child)
		child.queue_free()
	if not _float.is_empty():
		_small(_floatbox, "Poser ✓", func(): _commit_float(), true)
		if _float.kind == "stamp":
			_small(_floatbox, "Retourner ↔", func():
				_float.flip = not _float.flip
				_flt.queue_redraw())
		_small(_floatbox, "Jeter", func(): _discard_float())
	for row: Container in [_options, _options2]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	match _tool:
		"pinceau":
			for br: Array in BRUSHES:
				var b := Button.new()
				b.text = br[1]
				b.custom_minimum_size = Vector2(92 if br[0] != "arcenciel" else 118, 50)
				b.add_theme_font_size_override("font_size", 17)
				b.add_theme_color_override("font_color", BLUE)
				b.add_theme_stylebox_override("normal", _box(YELLOW if br[0] == _brush else Color.WHITE, BLUE, 2, 12))
				b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 12))
				b.pressed.connect(func():
					_brush = br[0]
					_refresh())
				_options.add_child(b)
			_sizes(_options2)
		"gomme":
			_hint(_options, "Frotte pour effacer.")
			_sizes(_options2)
		"pot":
			_hint(_options, "Touche une zone pour la remplir de couleur !")
		"pipette":
			_hint(_options, "Touche la feuille pour prendre la couleur qui est là.")
		"formes":
			_gap(_options, 6)
			for sh in SHAPES:
				_icon(_options, sh == _shape, func(ci: CanvasItem, c: Vector2):
					DrawingPad._draw_shape(ci, sh, Rect2(c - Vector2(16, 16), Vector2(32, 32)), _filled, _color, 3.0),
					func(): _shape = sh)
			_gap(_options, 16)
			for f: bool in [false, true]:
				var b := Button.new()
				b.text = "Plein" if f else "Contour"
				b.custom_minimum_size = Vector2(96, 50)
				b.add_theme_font_size_override("font_size", 16)
				b.add_theme_color_override("font_color", BLUE)
				b.add_theme_stylebox_override("normal", _box(YELLOW if f == _filled else Color.WHITE, BLUE, 2, 12))
				b.pressed.connect(func():
					_filled = f
					_refresh())
				_options.add_child(b)
			_sizes(_options2)
		"texte":
			_hint(_options, "Clique, écris, Entrée : ensuite tu peux le bouger.")
			_sizes(_options2)
		"etampes":
			for i in StampArt.CATEGORIES.size():
				var b := Button.new()
				b.text = StampArt.CATEGORIES[i][1]
				b.custom_minimum_size = Vector2(120, 50)
				b.add_theme_font_size_override("font_size", 17)
				b.add_theme_color_override("font_color", BLUE)
				b.add_theme_stylebox_override("normal", _box(YELLOW if i == _cat else Color.WHITE, BLUE, 2, 12))
				b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 12))
				b.pressed.connect(func():
					_cat = i
					_refresh())
				_options.add_child(b)
			_gap(_options, 12)
			_sizes(_options)
			for st: String in StampArt.CATEGORIES[_cat][2]:
				_icon(_options2, st == _stamp, func(ci: CanvasItem, c: Vector2): DrawingPad._draw_stamp(ci, st, c, 16.0, _color),
					func():
						_stamp = st
						if not _float.is_empty() and _float.kind == "stamp":
							_float.stamp = st
							_flt.queue_redraw(), Vector2(46, 46))


func _sizes(into: Container) -> void:
	for i in SIZE_NAMES.size():
		var b := Button.new()
		b.text = ["Petit", "Moyen", "Grand"][i] if _tool in ["texte", "etampes"] else SIZE_NAMES[i]
		b.custom_minimum_size = Vector2(62, 46 if into == _options2 else 50)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _size_i else Color.WHITE, BLUE, 2, 12))
		b.pressed.connect(func():
			_size_i = i
			if not _float.is_empty():
				if _float.kind == "text":
					_float.size = float(TEXT_SIZE[i])
				else:
					_float.r = STAMP_R[i]
				_flt.queue_redraw()
			_refresh())
		into.add_child(b)


func _hint(into: Container, text: String) -> void:
	var hint := Label.new()
	hint.text = text
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", BLUE)
	hint.custom_minimum_size = Vector2(0, 50)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	into.add_child(hint)


func _gap(into: Container, w: float) -> void:
	var g := Control.new()
	g.custom_minimum_size = Vector2(w, 1)
	into.add_child(g)


func _icon(into: Container, picked: bool, paint: Callable, choose: Callable, size := Vector2(50, 50)) -> void:
	var b := _IconButton.new()
	b.paint = paint
	b.custom_minimum_size = size
	b.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if picked else Color.WHITE, YELLOW if picked else BLUE, 3 if picked else 1, 12))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 2, 12))
	b.add_theme_stylebox_override("pressed", _box(Color("#FFF4C2"), YELLOW, 3, 12))
	b.pressed.connect(func():
		choose.call()
		_refresh())
	into.add_child(b)


func _small(into: Container, label: String, on_press: Callable, main := false) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(160, 40)
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_stylebox_override("normal", _box(YELLOW if main else Color.WHITE, BLUE, 3 if main else 2, 14))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
	b.pressed.connect(on_press)
	into.add_child(b)


func _action(bar: HBoxContainer, label: String, on_press: Callable, width := 150.0) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(width, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 16))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 16))
	b.pressed.connect(on_press)
	bar.add_child(b)
	return b


## "Poser" what is laid, put the drawing in the drawer, and hand it over.
func _finish() -> void:
	if _busy:
		return
	if not _float.is_empty() or _typing:
		if _typing:
			_stop_typing(true)
		await _commit_float()
	_close_gallery()
	DrawingPad.to_gallery(_image, _from)
	_dirty = false
	_close(_image)


func _close(result: Image) -> void:
	if _busy:
		return
	Sfx.play("chime" if result else "pop")
	closed.emit(result)
	queue_free()


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 12
	b.content_margin_right = 12
	return b
