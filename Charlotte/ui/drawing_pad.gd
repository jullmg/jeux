class_name DrawingPad
extends CanvasLayer
## Charlotte's drawing paper, opened from her desk. Tools down the right: the crayon (three sizes), the eraser, shapes
## (drag on the paper: circle, square, triangle, heart, star, filled or outlined), writing (click where the words go, type,
## Entrée) and cute stamps (star, heart, flower, sun, moon, cloud, rainbow, butterfly, cat, dog, hamster, capybara, house,
## Charlotte herself). Crayon colours down the left; "Oups !" takes back the last thing done. "Sur le frigo !" keeps the
## drawing (saved, the newest KEEP) for the fridge.
##
## Strokes are painted straight into the image; shapes, words and stamps are drawn by a little SubViewport over a copy of
## the paper (`_bake`), and its picture becomes the paper, so they are as smooth as the rest of the UI.

signal closed(drawing: Image)

const PAPER := Vector2i(480, 320)
const KEEP := 4
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const PAPER_COLOR := Color("#FFFDF7")
const CRAYONS := ["#2B2B2B", "#E04F5F", "#FF8A3D", "#FFD23F", "#7CCB5A", "#3E8E5A", "#4FA3E0", "#1D4F91",
	"#7E57C2", "#FF7BA3", "#8D6E63", "#F2C29A", "#E8E8E8", "#B5442E"]
const SIZES := [3.0, 7.0, 14.0]
const SIZE_NAMES := ["Fin", "Moyen", "Gros"]
const TOOLS := [["crayon", "Crayon"], ["gomme", "Gomme"], ["formes", "Formes"], ["texte", "Écrire"], ["etampes", "Étampes"]]
const SHAPES := ["cercle", "carre", "triangle", "coeur", "etoile"]
const STAMPS := ["etoile", "coeur", "fleur", "soleil", "lune", "nuage", "arc", "papillon", "chat", "chien", "hamster",
	"capybara", "maison", "moi"]
## Stamp radius and letter height for the three sizes.
const STAMP_R := [16.0, 28.0, 44.0]
const TEXT_SIZE := [18, 28, 44]
const UNDO := 15

var _image: Image
var _texture: ImageTexture
var _paper: TextureRect
var _preview: _Preview
var _color := Color(CRAYONS[1])
var _tool := "crayon"
var _size_i := 1
var _shape := "cercle"
var _filled := false
var _stamp := "etoile"
var _last := Vector2(-1, -1)
var _drag_from := Vector2(-1, -1)
var _undo: Array[Image] = []
var _busy := false
var _root: Control
var _panel: Panel
var _modes: VBoxContainer
var _options: HBoxContainer
var _typing: LineEdit
var _type_at := Vector2.ZERO


func _init() -> void:
	layer = 60


func _ready() -> void:
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
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.gui_input.connect(_on_paper_input)
	_paper.mouse_exited.connect(func(): _preview.hide_ghost())
	_panel.add_child(_paper)
	_preview = _Preview.new()
	_preview.pad = self
	_preview.size = Vector2(PAPER)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_preview)
	var frame := Panel.new()
	frame.position = _paper.position - Vector2(6, 6)
	frame.size = _paper.size + Vector2(12, 12)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), Color("#C8A27A"), 6, 6))
	_panel.add_child(frame)
	# Crayons down the left.
	var crayons := GridContainer.new()
	crayons.columns = 2
	crayons.position = Vector2(60, 76)
	crayons.add_theme_constant_override("h_separation", 12)
	crayons.add_theme_constant_override("v_separation", 10)
	_panel.add_child(crayons)
	for hex in CRAYONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(48, 30)
		b.add_theme_stylebox_override("normal", _box(Color(hex), Color(hex).darkened(0.35), 2, 8))
		b.add_theme_stylebox_override("hover", _box(Color(hex).lightened(0.15), BLUE, 3, 8))
		b.add_theme_stylebox_override("pressed", _box(Color(hex), YELLOW, 4, 8))
		b.pressed.connect(func():
			_color = Color(hex)
			if _tool == "gomme":
				_tool = "crayon"
			_refresh())
		crayons.add_child(b)
	# The tools down the right, their choices in a row under the paper.
	_modes = VBoxContainer.new()
	_modes.position = Vector2(756, 72)
	_modes.add_theme_constant_override("separation", 8)
	_panel.add_child(_modes)
	_options = HBoxContainer.new()
	_options.position = Vector2(40, 410)
	_options.add_theme_constant_override("separation", 4)
	_panel.add_child(_options)
	_refresh()
	var bar := HBoxContainer.new()
	bar.position = Vector2(40, 560)
	bar.size = Vector2(880, 56)
	bar.add_theme_constant_override("separation", 14)
	_panel.add_child(bar)
	_action(bar, "Tout effacer", func():
		_remember()
		_image.fill(PAPER_COLOR)
		_texture.update(_image))
	_action(bar, "Oups !", _take_back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_action(bar, "Annuler", func(): _close(null))
	var done := _action(bar, "Sur le frigo !", func(): _close(_image))
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _typing:
			_stop_typing(false)
		else:
			_close(null)


# ── Drawing ─────────────────────────────────────────────────────

func _on_paper_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseMotion:
		_preview.mouse = event.position
		_preview.queue_redraw()
	match _tool:
		"crayon", "gomme":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				_last = event.position if event.pressed else Vector2(-1, -1)
				if event.pressed:
					_remember()
					_stroke(event.position, event.position)
			elif event is InputEventMouseMotion and _last.x >= 0.0:
				_stroke(_last, event.position)
				_last = event.position
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
		"etampes":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_bake({"kind": "stamp", "stamp": _stamp, "at": event.position, "r": STAMP_R[_size_i], "color": _color})
				Sfx.play("pop")
		"texte":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_start_typing(event.position)


func _stroke(a: Vector2, b: Vector2) -> void:
	var eraser := _tool == "gomme"
	var col := PAPER_COLOR if eraser else _color
	var r: float = SIZES[_size_i] * (2.0 if eraser else 1.0)
	var steps := maxi(1, int(a.distance_to(b) / maxf(1.0, r * 0.4)))
	for i in steps + 1:
		_dab(a.lerp(b, float(i) / steps), r, col)
	_texture.update(_image)


func _dab(c: Vector2, r: float, col: Color) -> void:
	var x0 := maxi(0, int(c.x - r))
	var x1 := mini(PAPER.x - 1, int(c.x + r))
	var y0 := maxi(0, int(c.y - r))
	var y1 := mini(PAPER.y - 1, int(c.y + r))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if Vector2(x, y).distance_squared_to(c) <= r * r:
				_image.set_pixel(x, y, col)


func _remember() -> void:
	_undo.append(_image.duplicate())
	if _undo.size() > UNDO:
		_undo.pop_front()


func _take_back() -> void:
	if _undo.is_empty() or _busy:
		return
	_image = _undo.pop_back()
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


func _stop_typing(keep: bool) -> void:
	if not _typing:
		return
	var text := _typing.text.strip_edges()
	_typing.queue_free()
	_typing = null
	_preview.queue_redraw()
	if keep and not text.is_empty():
		_bake({"kind": "text", "text": text, "at": _type_at, "size": TEXT_SIZE[_size_i], "color": _color})
		Sfx.play("pop")


# ── What the tools draw (the baked ink and the ghost under the mouse) ──

static func draw_item(ci: CanvasItem, item: Dictionary) -> void:
	match item.kind:
		"shape":
			_draw_shape(ci, item.shape, item.rect, item.filled, item.color, item.width)
		"stamp":
			_draw_stamp(ci, item.stamp, item.at, item.r, item.color)
		"text":
			var font := ThemeDB.fallback_font
			var size: int = item.size
			# The click is where the words start, on their middle line.
			ci.draw_string(font, item.at + Vector2(0, size * 0.35), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, item.color)


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
	match stamp:
		"etoile":
			CuteArt.star(ci, c, r, color)
		"coeur":
			CuteArt.heart(ci, c, r * 0.9, color)
		"fleur":
			CuteArt.flower(ci, c, r * 0.9, color)
		"soleil":
			CuteArt.sun(ci, c, r * 0.6)
		"lune":
			# A crescent opening to the right: the left half of the full moon, back up along a flatter inner curve.
			var moon := PackedVector2Array()
			for k in 25:
				var a := PI * 0.5 + PI * k / 24.0
				moon.append(c + Vector2(cos(a), sin(a)) * r)
			for k in range(1, 24):
				var a := PI * 1.5 - PI * k / 24.0
				moon.append(c + Vector2(cos(a) * r * 0.45, sin(a) * r))
			ci.draw_colored_polygon(moon, Color("#FFE27A"))
			var ring := moon.duplicate()
			ring.append(moon[0])
			ci.draw_polyline(ring, CuteArt.LINE, maxf(1.5, r * 0.06), true)
			ci.draw_circle(c + Vector2(-r * 0.74, -r * 0.18), maxf(1.2, r * 0.07), CuteArt.LINE)
			ci.draw_arc(c + Vector2(-r * 0.72, r * 0.12), r * 0.12, 0.3, PI - 0.3, 8, CuteArt.LINE, maxf(1.0, r * 0.05), true)
		"nuage":
			for b: Array in [[Vector2(-0.55, 0.15), 0.42], [Vector2(0.55, 0.15), 0.42], [Vector2(-0.15, -0.15), 0.55], [Vector2(0.3, -0.05), 0.48]]:
				ci.draw_circle(c + b[0] * r, b[1] * r + 2.0, Color("#8FB8DA"))
			for b: Array in [[Vector2(-0.55, 0.15), 0.42], [Vector2(0.55, 0.15), 0.42], [Vector2(-0.15, -0.15), 0.55], [Vector2(0.3, -0.05), 0.48]]:
				ci.draw_circle(c + b[0] * r, b[1] * r, Color.WHITE)
			ci.draw_circle(c + Vector2(-0.35, 0.05) * r, r * 0.06, CuteArt.LINE)
			ci.draw_circle(c + Vector2(0.15, 0.05) * r, r * 0.06, CuteArt.LINE)
			ci.draw_circle(c + Vector2(-0.55, 0.22) * r, r * 0.1, Color("#F2A7B4"))
			ci.draw_circle(c + Vector2(0.35, 0.22) * r, r * 0.1, Color("#F2A7B4"))
		"arc":
			var bands := [Color("#E04F5F"), Color("#FF8A3D"), Color("#FFD23F"), Color("#7CCB5A"), Color("#4FA3E0"), Color("#7E57C2")]
			var w := r * 0.14
			for i in bands.size():
				ci.draw_arc(c + Vector2(0, r * 0.45), r - i * w, PI, TAU, 32, bands[i], w + 0.5, true)
		"papillon":
			for side in [-1.0, 1.0]:
				_oval(ci, c + Vector2(side * 0.45, -0.25) * r, Vector2(0.45, 0.4) * r, color)
				_oval(ci, c + Vector2(side * 0.38, 0.32) * r, Vector2(0.3, 0.26) * r, color.lightened(0.3))
				ci.draw_circle(c + Vector2(side * 0.5, -0.3) * r, r * 0.1, Color.WHITE)
				ci.draw_line(c + Vector2(0, -0.45) * r, c + Vector2(side * 0.25, -0.85) * r, CuteArt.LINE, maxf(1.0, r * 0.05), true)
			_oval(ci, c, Vector2(0.1, 0.5) * r, CuteArt.LINE)
		"chat":
			CuteArt.cat_head(ci, c, r * 0.85, Color("#F2A65A"))
		"chien":
			CuteArt.dog_head(ci, c, r * 0.85, Color("#D8B48A"), Color("#8D6E63"))
		"hamster":
			CuteArt.hamster_head(ci, c, r * 0.8)
		"capybara":
			CuteArt.capybara_head(ci, c, r * 0.85)
		"maison":
			CuteArt.house(ci, c, r * 0.85)
		"moi":
			CuteArt.me(ci, c, r * 0.9)


static func _oval(ci: CanvasItem, c: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 32:
		pts.append(c + Vector2(cos(TAU * k / 32.0) * radii.x, sin(TAU * k / 32.0) * radii.y))
	ci.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	ci.draw_polyline(pts, CuteArt.LINE, maxf(1.0, radii.length() * 0.06), true)


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
		if pad._busy or mouse.x < 0.0:
			return
		match pad._tool:
			"formes":
				if pad._drag_from.x >= 0.0:
					DrawingPad._draw_shape(self, pad._shape, Rect2(pad._drag_from, Vector2.ZERO).expand(mouse), pad._filled, pad._color, SIZES[pad._size_i])
			"etampes":
				DrawingPad._draw_stamp(self, pad._stamp, mouse, STAMP_R[pad._size_i], pad._color)
			"texte":
				if not pad._typing:
					var h: float = TEXT_SIZE[pad._size_i]
					draw_line(mouse + Vector2(0, -h * 0.5), mouse + Vector2(0, h * 0.5), pad._color, 2.0)
			"crayon", "gomme":
				var r: float = SIZES[pad._size_i] * (2.0 if pad._tool == "gomme" else 1.0)
				draw_arc(mouse, r, 0.0, TAU, 24, Color(0.2, 0.2, 0.3), 1.5, true)


## A square button with a little drawing on it instead of words.
class _IconButton:
	extends Button

	var paint: Callable

	func _draw() -> void:
		paint.call(self, size / 2.0)


# ── Saved drawings (for the fridge) ─────────────────────────────

## The current game's drawings folder.
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


## Takes every drawing off the fridge (a new game).
static func forget_all() -> void:
	var dir := DirAccess.open(folder())
	if dir == null:
		return
	for n in dir.get_files():
		dir.remove(n)


## Keeps a new drawing, dropping the oldest beyond KEEP.
static func keep(img: Image) -> void:
	DirAccess.make_dir_recursive_absolute(folder())
	img.save_png("%s/%d.png" % [folder(), int(Time.get_unix_time_from_system() * 1000.0)])
	var dir := DirAccess.open(folder())
	var names := Array(dir.get_files()).filter(func(n: String): return n.ends_with(".png"))
	names.sort()
	while names.size() > KEEP:
		dir.remove(names.pop_front())


# ── UI ──────────────────────────────────────────────────────────

func _refresh() -> void:
	if _typing and _tool != "texte":
		_stop_typing(true)
	for child in _modes.get_children():
		child.queue_free()
	for t: Array in TOOLS:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(160, 46)
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if t[0] == _tool else Color.WHITE, BLUE, 2, 14))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
		b.pressed.connect(func():
			_tool = t[0]
			_refresh())
		_modes.add_child(b)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(160, 30)
	swatch.color = PAPER_COLOR if _tool == "gomme" else _color
	_modes.add_child(swatch)
	for child in _options.get_children():
		child.queue_free()
	# Every tool has its three sizes; then shapes and stamps show what they can make.
	for i in SIZE_NAMES.size():
		var b := Button.new()
		b.text = ["Petit", "Moyen", "Grand"][i] if _tool in ["texte", "etampes"] else SIZE_NAMES[i]
		b.custom_minimum_size = Vector2(60, 56)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _size_i else Color.WHITE, BLUE, 2, 12))
		b.pressed.connect(func():
			_size_i = i
			_refresh())
		_options.add_child(b)
	match _tool:
		"formes":
			_gap(16)
			for sh in SHAPES:
				_icon(sh == _shape, func(ci: CanvasItem, c: Vector2):
					DrawingPad._draw_shape(ci, sh, Rect2(c - Vector2(16, 16), Vector2(32, 32)), _filled, _color, 3.0),
					func(): _shape = sh)
			_gap(16)
			for f: bool in [false, true]:
				var b := Button.new()
				b.text = "Plein" if f else "Contour"
				b.custom_minimum_size = Vector2(96, 56)
				b.add_theme_font_size_override("font_size", 16)
				b.add_theme_color_override("font_color", BLUE)
				b.add_theme_stylebox_override("normal", _box(YELLOW if f == _filled else Color.WHITE, BLUE, 2, 12))
				b.pressed.connect(func():
					_filled = f
					_refresh())
				_options.add_child(b)
		"etampes":
			_gap(10)
			for st in STAMPS:
				_icon(st == _stamp, func(ci: CanvasItem, c: Vector2): DrawingPad._draw_stamp(ci, st, c, 17.0, _color),
					func(): _stamp = st, Vector2(42, 56))
		"texte":
			_gap(16)
			var hint := Label.new()
			hint.text = "Clique sur la feuille, écris, puis Entrée !"
			hint.add_theme_font_size_override("font_size", 18)
			hint.add_theme_color_override("font_color", BLUE)
			hint.custom_minimum_size = Vector2(0, 56)
			hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_options.add_child(hint)


func _gap(w: float) -> void:
	var g := Control.new()
	g.custom_minimum_size = Vector2(w, 1)
	_options.add_child(g)


func _icon(picked: bool, paint: Callable, choose: Callable, size := Vector2(56, 56)) -> void:
	var b := _IconButton.new()
	b.paint = paint
	b.custom_minimum_size = size
	b.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if picked else Color.WHITE, YELLOW if picked else BLUE, 3 if picked else 1, 12))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 2, 12))
	b.add_theme_stylebox_override("pressed", _box(Color("#FFF4C2"), YELLOW, 3, 12))
	b.pressed.connect(func():
		choose.call()
		_refresh())
	_options.add_child(b)


func _action(bar: HBoxContainer, label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(160, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 16))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 16))
	b.pressed.connect(on_press)
	bar.add_child(b)
	return b


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
