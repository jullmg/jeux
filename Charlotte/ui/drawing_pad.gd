class_name DrawingPad
extends CanvasLayer
## Charlotte's drawing paper, opened from her desk: draw with the mouse (or a finger), pick a crayon colour,
## a line size, the eraser. "Sur le frigo !" keeps the drawing (saved, the newest KEEP) for the fridge.

signal closed(drawing: Image)

const PAPER := Vector2i(480, 320)
const KEEP := 4
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CRAYONS := ["#2B2B2B", "#E04F5F", "#FF8A3D", "#FFD23F", "#7CCB5A", "#3E8E5A", "#4FA3E0", "#1D4F91",
	"#7E57C2", "#FF7BA3", "#8D6E63", "#F2C29A", "#E8E8E8", "#B5442E"]
const SIZES := [3.0, 7.0, 14.0]

var _image: Image
var _texture: ImageTexture
var _paper: TextureRect
var _color := Color(CRAYONS[1])
var _size := 7.0
var _eraser := false
var _last := Vector2(-1, -1)
var _root: Control
var _tools: HBoxContainer


func _init() -> void:
	layer = 60


func _ready() -> void:
	_image = Image.create(PAPER.x, PAPER.y, false, Image.FORMAT_RGBA8)
	_image.fill(Color("#FFFDF7"))
	_texture = ImageTexture.create_from_image(_image)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(160, 40)
	panel.size = Vector2(960, 640)
	panel.add_theme_stylebox_override("panel", _box(Color("#F6EFE4"), BLUE, 6, 26))
	_root.add_child(panel)
	var title := Label.new()
	title.text = "Le dessin de Charlotte"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BLUE)
	title.position = Vector2(0, 14)
	title.size = Vector2(960, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_paper = TextureRect.new()
	_paper.texture = _texture
	_paper.position = Vector2(240, 70)
	_paper.size = Vector2(PAPER)
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.gui_input.connect(_on_paper_input)
	panel.add_child(_paper)
	var frame := Panel.new()
	frame.position = _paper.position - Vector2(6, 6)
	frame.size = _paper.size + Vector2(12, 12)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), Color("#C8A27A"), 6, 6))
	panel.add_child(frame)
	# Crayons down the left, sizes and eraser along the bottom, then the buttons.
	var crayons := GridContainer.new()
	crayons.columns = 2
	crayons.position = Vector2(60, 76)
	crayons.add_theme_constant_override("h_separation", 12)
	crayons.add_theme_constant_override("v_separation", 10)
	panel.add_child(crayons)
	for hex in CRAYONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(48, 30)
		b.add_theme_stylebox_override("normal", _box(Color(hex), Color(hex).darkened(0.35), 2, 8))
		b.add_theme_stylebox_override("hover", _box(Color(hex).lightened(0.15), BLUE, 3, 8))
		b.add_theme_stylebox_override("pressed", _box(Color(hex), YELLOW, 4, 8))
		b.pressed.connect(func():
			_color = Color(hex)
			_eraser = false
			_refresh_tools())
		crayons.add_child(b)
	_tools = HBoxContainer.new()
	_tools.position = Vector2(240, 410)
	_tools.add_theme_constant_override("separation", 10)
	panel.add_child(_tools)
	_refresh_tools()
	var bar := HBoxContainer.new()
	bar.position = Vector2(40, 560)
	bar.size = Vector2(880, 56)
	bar.add_theme_constant_override("separation", 14)
	panel.add_child(bar)
	_action(bar, "Tout effacer", func():
		_image.fill(Color("#FFFDF7"))
		_texture.update(_image))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_action(bar, "Annuler", func(): _close(null))
	var done := _action(bar, "Sur le frigo !", func(): _close(_image))
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(null)


# ── Drawing ─────────────────────────────────────────────────────

func _on_paper_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_last = event.position if event.pressed else Vector2(-1, -1)
		if event.pressed:
			_stroke(event.position, event.position)
	elif event is InputEventMouseMotion and _last.x >= 0.0:
		_stroke(_last, event.position)
		_last = event.position


func _stroke(a: Vector2, b: Vector2) -> void:
	var col := Color("#FFFDF7") if _eraser else _color
	var r := _size * (2.0 if _eraser else 1.0)
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

func _refresh_tools() -> void:
	for child in _tools.get_children():
		child.queue_free()
	for s in SIZES:
		var b := Button.new()
		b.text = ["Fin", "Moyen", "Gros"][SIZES.find(s)]
		b.custom_minimum_size = Vector2(110, 44)
		b.add_theme_font_size_override("font_size", 18)
		var picked: bool = s == _size and not _eraser
		b.add_theme_stylebox_override("normal", _box(YELLOW if picked else Color.WHITE, BLUE, 2, 12))
		b.add_theme_color_override("font_color", BLUE)
		b.pressed.connect(func():
			_size = s
			_eraser = false
			_refresh_tools())
		_tools.add_child(b)
	var eraser := Button.new()
	eraser.text = "Gomme"
	eraser.custom_minimum_size = Vector2(110, 44)
	eraser.add_theme_font_size_override("font_size", 18)
	eraser.add_theme_color_override("font_color", BLUE)
	eraser.add_theme_stylebox_override("normal", _box(YELLOW if _eraser else Color("#FFDCE4"), BLUE, 2, 12))
	eraser.pressed.connect(func():
		_eraser = true
		_refresh_tools())
	_tools.add_child(eraser)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(44, 44)
	swatch.color = Color("#FFFDF7") if _eraser else _color
	_tools.add_child(swatch)


func _action(bar: HBoxContainer, label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(180, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 16))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 16))
	b.pressed.connect(on_press)
	bar.add_child(b)
	return b


func _close(result: Image) -> void:
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
