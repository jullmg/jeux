extends CanvasLayer
## Autoload "TownMap": Charlotte's map of the neighbourhood, drawn by a child. A button left of the notebook's (or the C key)
## opens a big sheet of drawing paper: her block between Rue Holt and Rue Dandurand, 6e and 5e Avenue, with the houses
## in a row, the lanes (an H), her house, dépanneur Xin-Xin, Oh Bon! and the school across Rue Dandurand,
## all in wobbly wax crayon (CuteArt). A little Charlotte stands where she is ("Je suis ici !") and follows her
## as the scene changes. What she can't reach is greyed over (`_Sheet._reachable`, by her age); before 8 years old a stop sign
## says she may not go farther alone. The game pauses while it is open.
## `--map` (a user arg) opens it a second after the scene starts, for screenshots.

const BLUE := Color("#1D4F91")
const INK := Color("#3A3A48")
const SHEET := Vector2(1000, 640)
const SCALE := 0.94
const CRAYONS := [Color("#E85FA0"), Color("#3D8BD9"), Color("#F2C230"), Color("#4FA34A"), Color("#E8812E"), Color("#8E5FC4")]
## The map's geometry, in sheet pixels (north is up, west left).
const HOLT_X := 250.0
const DAND_X := 720.0
const SEVEN_Y := 100.0
const SIX_Y := 235.0
const FIVE_Y := 450.0
const FOUR_Y := 585.0
const AVE_W := 34.0
const ST_W := 30.0
const LANE_Y := 345.0
const LANE_L := 335.0
const LANE_R := 635.0
const HOUSE_X := 477.0
const BLOCK_TOP := 254.0
const BLOCK_BOTTOM := 432.0

var _button: Button
var _open := false
var _page: Control
var _sheet: _Sheet
var _you: _You


func _ready() -> void:
	layer = 76
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = Button.new()
	_button.custom_minimum_size = Vector2(52, 52)
	_button.position = Vector2(1280 - 52 - 14 - 64 - 64, 14)
	_button.focus_mode = Control.FOCUS_NONE
	_button.tooltip_text = "Ma carte (C ou M)"
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.85 if state == "normal" else 1.0)
		box.border_color = BLUE
		box.set_border_width_all(3 if state != "normal" else 2)
		box.set_corner_radius_all(26)
		_button.add_theme_stylebox_override(state, box)
	_button.pressed.connect(toggle)
	_button.draw.connect(_draw_icon)
	add_child(_button)
	_build_page()
	if OS.get_cmdline_user_args().has("--map"):
		await get_tree().create_timer(1.0).timeout
		if not _open:
			toggle()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var shown := scene != null and not scene.scene_file_path.ends_with("intro.tscn") and not scene.scene_file_path.contains("/tools/")
	var notebook := get_node_or_null("/root/Notebook")
	_button.visible = shown and not _open and not (notebook and notebook._open)
	if not shown and _open:
		toggle()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if not _open and not get_tree().get_nodes_in_group("modal").is_empty():
		return
	var opens: bool = event.keycode == KEY_C or (event.keycode == KEY_M and not event.shift_pressed)
	if _open and (opens or event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		toggle()
	elif not _open and opens and _button.visible and not get_tree().paused:
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_open = not _open
	if _open:
		_sheet.queue_redraw()
		_place_you()
	_page.visible = _open
	_you.set_process(_open)
	get_tree().paused = _open
	Sfx.play("page")


# ── Where she is ────────────────────────────────────────────

## Where Charlotte stands on the sheet, from the scene she is in (and how far along its street or lane she is), and what
## she says there.
func _here() -> Dictionary:
	var scene := get_tree().current_scene
	var key := scene.scene_file_path.get_file().get_basename() if scene else ""
	var f := 0.5
	var width: Variant = scene.get("_street_width") if scene else null
	var who: Variant = scene.get("_charlotte") if scene else null
	if width is float and width > 0.0 and who is Node2D:
		f = clampf(who.position.x / width, 0.0, 1.0)
	# The street scenes show their street from across the road: 6e Avenue runs Dandurand (left) to Holt (right), Rue Holt
	# 6e to 5e, 5e Avenue Holt to Dandurand, Rue Dandurand 5e to 6e; the lanes the same way round.
	match key:
		"main":
			return {"at": Vector2(lerpf(700.0, 272.0, f), 252.0), "say": "Je suis ici !"}
		"holt":
			return {"at": Vector2(274.0, lerpf(262.0, 428.0, f)), "say": "Je suis ici !"}
		"cinquieme":
			return {"at": Vector2(lerpf(272.0, 698.0, f), 430.0), "say": "Je suis ici !"}
		"dandurand":
			return {"at": Vector2(696.0, lerpf(428.0, 262.0, f)), "say": "Je suis ici !"}
		"ruelle":
			return {"at": Vector2(lerpf(LANE_L, LANE_R, f), LANE_Y), "say": "Je suis dans la ruelle !"}
		"ruelle_dandurand":
			return {"at": Vector2(LANE_R, lerpf(428.0, 262.0, f)), "say": "Je suis dans la ruelle !"}
		"ruelle_holt":
			return {"at": Vector2(LANE_L, lerpf(262.0, 428.0, f)), "say": "Je suis dans la ruelle !"}
		"house":
			return {"at": Vector2(HOUSE_X, 252.0), "say": "Je suis chez moi !"}
		"depanneur":
			return {"at": Vector2(682.0, 252.0), "say": "Je suis chez Xin-Xin !"}
		"ohbon":
			return {"at": Vector2(292.0, 252.0), "say": "Je suis chez Oh Bon !"}
	return {"at": Vector2(HOUSE_X, 252.0), "say": "Je suis ici !"}


func _place_you() -> void:
	var here := _here()
	_you.position = here.at
	_you.text = here.say
	_you.bubble_left = here.at.x > 560.0


# ── The page ────────────────────────────────────────────────

func _build_page() -> void:
	_page = Control.new()
	_page.size = Vector2(1280, 720)
	_page.visible = false
	add_child(_page)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.5)
	dim.size = _page.size
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			toggle())
	_page.add_child(dim)
	var holder := Control.new()
	holder.size = SHEET
	holder.scale = Vector2.ONE * SCALE
	holder.pivot_offset = SHEET / 2.0
	holder.rotation = -0.012
	holder.position = (_page.size - SHEET) / 2.0 + Vector2(0, -8)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(holder)
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.size = SHEET
	shadow.position = Vector2(8, 11)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)
	_sheet = _Sheet.new()
	_sheet.size = SHEET
	_sheet.clip_contents = true
	holder.add_child(_sheet)
	_you = _You.new()
	_you.set_process(false)
	_sheet.add_child(_you)
	var hint := Label.new()
	hint.text = "C, M ou clique à côté pour fermer"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	hint.position = Vector2(0, 690)
	hint.size = Vector2(1280, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(hint)


# A folded map with a dotted path to a red cross.
func _draw_icon() -> void:
	var c := Vector2(26, 26)
	var pts := PackedVector2Array([c + Vector2(-15, -10), c + Vector2(-5, -13), c + Vector2(5, -9), c + Vector2(15, -12),
		c + Vector2(15, 12), c + Vector2(5, 15), c + Vector2(-5, 11), c + Vector2(-15, 14)])
	_button.draw_colored_polygon(pts, Color("#F4E8C8"))
	var ring := pts.duplicate()
	ring.append(pts[0])
	_button.draw_polyline(ring, BLUE, 2.0, true)
	_button.draw_line(c + Vector2(-5, -13), c + Vector2(-5, 11), Color("#C9B68A"), 1.5)
	_button.draw_line(c + Vector2(5, -9), c + Vector2(5, 15), Color("#C9B68A"), 1.5)
	for k in 4:
		_button.draw_circle(c + Vector2(-10.0 + k * 4.5, 6.0 - k * 2.6), 1.3, Color("#4FA34A"))
	_button.draw_line(c + Vector2(6, -7), c + Vector2(12, -1), Color("#E04F5F"), 2.5, true)
	_button.draw_line(c + Vector2(12, -7), c + Vector2(6, -1), Color("#E04F5F"), 2.5, true)


# ── The little Charlotte who says where she is ──────────────

class _You:
	extends Node2D

	var text := "Je suis ici !"
	var bubble_left := false
	var _t := 0.0
	var _style := StyleBoxFlat.new()

	func _init() -> void:
		_style.bg_color = Color("#FFFDF7")
		_style.border_color = Color("#E85FA0")
		_style.set_border_width_all(3)
		_style.set_corner_radius_all(12)
		z_index = 10

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		var bob := sin(_t * 3.2) * 3.0
		# A red pin on the spot, then Charlotte drawing herself above it, bouncing a little.
		draw_circle(Vector2(0, 0), 5.0, Color("#E04F5F"))
		draw_arc(Vector2(0, 0), 8.0 + sin(_t * 3.2) * 1.5, 0.0, TAU, 20, Color("#E04F5F", 0.5), 2.0, true)
		CuteArt.me(self, Vector2(0, -44.0 + bob), 20.0, true, rng)
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 22.0
		var x := -30.0 - w if bubble_left else 30.0
		var rect := Rect2(x, -78.0 + bob * 0.5, w, 30.0)
		draw_style_box(_style, rect)
		draw_string(font, rect.position + Vector2(11, 21), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#C2406E"))


# ── The drawing ─────────────────────────────────────────────

class _Sheet:
	extends Control

	const ROAD := Color("#9AA5B5")
	const EDGE := Color("#5E6B80")
	const DASH := Color("#F7D154")
	const WALLS := [Color("#E8812E"), Color("#F2C230"), Color("#E85FA0"), Color("#3D8BD9"), Color("#8E5FC4"), Color("#E0A878"), Color("#C9503C"), Color("#6DB35A")]
	const ROOFS := [Color("#C9503C"), Color("#7A5232"), Color("#3D8BD9"), Color("#4FA34A"), Color("#8E5FC4"), Color("#3A3A48")]
	var _rng := RandomNumberGenerator.new()

	func _draw() -> void:
		_rng.seed = 2026
		_paper()
		_block_wash()
		_roads()
		_neighbours()
		_school()
		_lanes()
		_block_houses()
		_yards()
		_shops_and_home()
		_grey_out()
		_labels()
		_decor()
		_frame()
		if GameState.age < StreetScene.CROSS_AGE:
			_stop_sign()

	# ── Paper and frame ──

	func _paper() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FFFDF7"))
		for i in 420:
			draw_circle(Vector2(_rng.randf_range(4, size.x - 4), _rng.randf_range(4, size.y - 4)), _rng.randf_range(0.5, 1.0), Color(0.55, 0.45, 0.3, 0.1))
		# Crumpled-in-a-schoolbag fold lines.
		for x in [size.x * 0.5]:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.5, 0.45, 0.35, 0.07), 3.0)
		draw_line(Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5), Color(0.5, 0.45, 0.35, 0.07), 3.0)

	# Her block, coloured in pale yellow so it stands out from all the others.
	func _block_wash() -> void:
		var x0 := HOLT_X + ST_W / 2.0 + 1.0
		var x1 := DAND_X - ST_W / 2.0 - 1.0
		CuteArt._shape(self, [Vector2(x0, SIX_Y + AVE_W / 2.0), Vector2(x1, SIX_Y + AVE_W / 2.0), Vector2(x1, FIVE_Y - AVE_W / 2.0), Vector2(x0, FIVE_Y - AVE_W / 2.0)], Color("#FFE680", 0.8), true, _rng, false)

	func _frame() -> void:
		var inset := 9.0
		var r := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
		CuteArt._crayon_line(self, [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position, r.position + Vector2(40, 0)], Color("#F2C230"), 3.6, _rng)
		# Washi tape on two corners.
		_tape(Vector2(-14, 50), -0.78, Color("#F7C6D9", 0.85))
		_tape(Vector2(size.x - 70, -10), 0.62, Color("#BFE3F7", 0.85))
		_tape(Vector2(size.x - 54, size.y - 62), -0.7, Color("#D7F0C2", 0.85))
		_tape(Vector2(10, size.y - 24), 0.5, Color("#FFE9A8", 0.85))

	func _tape(at: Vector2, angle: float, color: Color) -> void:
		var d := Vector2.from_angle(angle)
		var n := d.orthogonal()
		draw_colored_polygon(PackedVector2Array([at, at + d * 96, at + d * 96 + n * 26, at + n * 26]), color)
		for k in 7:
			var p := at + d * (8 + k * 13) + n * 5
			draw_line(p, p + n * 14, Color(1, 1, 1, 0.5), 2.0)

	# ── Handwriting: each letter a little off, gone over twice like a pressed crayon ──

	func _text(s: String, at: Vector2, size_px: int, color: Color, rot := 0.0, align := "c") -> void:
		var font := ThemeDB.fallback_font
		var lines := s.split("\n")
		for li in lines.size():
			var line: String = lines[li]
			var total := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
			var x := -total / 2.0 if align == "c" else (-total if align == "r" else 0.0)
			var origin := at + Vector2(0, li * (size_px + 3)).rotated(rot)
			for ch in line:
				var w := font.get_char_size(ch.unicode_at(0), size_px).x
				var jitter := Vector2(0, _rng.randf_range(-1.6, 1.6)).rotated(rot)
				var a := _rng.randf_range(-0.09, 0.09)
				var sz := size_px + _rng.randi_range(-1, 1)
				for pass_i in 2:
					draw_set_transform(origin + Vector2(x, 0).rotated(rot) + jitter + Vector2(0.7, 0.5) * pass_i, rot + a, Vector2.ONE)
					draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(color, 1.0 if pass_i == 0 else 0.55))
				x += w
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _title() -> void:
		var title := "Mon quartier"
		var x := 40.0
		var font := ThemeDB.fallback_font
		for i in title.length():
			var ch := title[i]
			var col: Color = CRAYONS[i % CRAYONS.size()]
			var w := font.get_char_size(ch.unicode_at(0), 44).x
			for pass_i in 2:
				draw_set_transform(Vector2(x, 54 + _rng.randf_range(-3, 3)) + Vector2(1.0, 0.8) * pass_i, _rng.randf_range(-0.12, 0.12), Vector2.ONE)
				draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(col, 1.0 if pass_i == 0 else 0.55))
			x += w + 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_text("par Chachoue ♥", Vector2(352, 56), 20, CRAYONS[0], -0.03, "l")

	# ── Roads ──

	# Pieces of [a, b] left once the [lo, hi] ranges in `cuts` are taken out.
	func _pieces(a: float, b: float, cuts: Array) -> Array:
		var out := []
		var t := a
		for c in cuts:
			if c[0] >= b:
				break
			if c[0] > t:
				out.append([t, c[0]])
			t = maxf(t, c[1])
		if t < b:
			out.append([t, b])
		return out

	func _av_cuts() -> Array:
		return [[SEVEN_Y - AVE_W / 2.0, SEVEN_Y + AVE_W / 2.0], [SIX_Y - AVE_W / 2.0, SIX_Y + AVE_W / 2.0], [FIVE_Y - AVE_W / 2.0, FIVE_Y + AVE_W / 2.0], [FOUR_Y - AVE_W / 2.0, FOUR_Y + AVE_W / 2.0]]

	func _st_cuts() -> Array:
		return [[HOLT_X - ST_W / 2.0, HOLT_X + ST_W / 2.0], [DAND_X - ST_W / 2.0, DAND_X + ST_W / 2.0]]

	func _roads() -> void:
		# The surfaces first (scribbled grey), then the kerbs and the yellow dashes between the crossings.
		for y in [SEVEN_Y, SIX_Y, FIVE_Y, FOUR_Y]:
			var h := AVE_W / 2.0
			CuteArt._shape(self, [Vector2(-8, y - h), Vector2(size.x + 8, y - h), Vector2(size.x + 8, y + h), Vector2(-8, y + h)], ROAD, true, _rng, false)
		for x in [HOLT_X, DAND_X]:
			var h := ST_W / 2.0
			CuteArt._shape(self, [Vector2(x - h, 64), Vector2(x + h, 64), Vector2(x + h, size.y + 8), Vector2(x - h, size.y + 8)], ROAD, true, _rng, false)
		for y in [SEVEN_Y, SIX_Y, FIVE_Y, FOUR_Y]:
			for side in [-1.0, 1.0]:
				for p in _pieces(-8.0, size.x + 8.0, _st_cuts()):
					CuteArt._stroke(self, [Vector2(p[0], y + side * AVE_W / 2.0), Vector2(p[1], y + side * AVE_W / 2.0)], EDGE, 2.6, true, _rng)
			_dashes(Vector2(-8, y), Vector2(size.x + 8, y), _st_cuts().map(func(c): return [c[0] - 6.0, c[1] + 6.0]))
		for x in [HOLT_X, DAND_X]:
			for side in [-1.0, 1.0]:
				for p in _pieces(64.0, size.y + 8.0, _av_cuts()):
					CuteArt._stroke(self, [Vector2(x + side * ST_W / 2.0, p[0]), Vector2(x + side * ST_W / 2.0, p[1])], EDGE, 2.6, true, _rng)
			_dashes(Vector2(x, 64), Vector2(x, size.y + 8), _av_cuts().map(func(c): return [c[0] - 6.0, c[1] + 6.0]))
		# Zebra crossings round the block's four corners, the way she crosses.
		for y in [SIX_Y, FIVE_Y]:
			for x in [HOLT_X, DAND_X]:
				for k in 5:
					var off := -ST_W / 2.0 + 3.0 + k * (ST_W - 6.0) / 4.0
					draw_line(Vector2(x + off, y - AVE_W / 2.0 - 8.0), Vector2(x + off, y - AVE_W / 2.0 - 1.0), Color("#FFFDF7", 0.9), 3.0)

	func _dashes(a: Vector2, b: Vector2, cuts: Array) -> void:
		var horizontal := absf(b.y - a.y) < 0.5
		var from := a.x if horizontal else a.y
		var to := b.x if horizontal else b.y
		var t := from + 6.0
		while t < to - 14.0:
			var skip := false
			for c in cuts:
				if t + 14.0 > c[0] and t < c[1]:
					skip = true
			if not skip:
				var p0 := Vector2(t, a.y) if horizontal else Vector2(a.x, t)
				var p1 := Vector2(t + 14.0, a.y) if horizontal else Vector2(a.x, t + 14.0)
				CuteArt._crayon_line(self, [p0, p1], DASH, 3.0, _rng, 1)
			t += 27.0 + _rng.randf_range(-2.0, 2.0)

	# ── Houses ──

	# A child's house. `solid` = coloured with crayon; otherwise the cheap pale version for the far blocks.
	func _house(base: Vector2, w: float, h: float, wall: Color, roof: Color, solid := true) -> void:
		var half := w / 2.0
		var body := [base + Vector2(-half, -h), base + Vector2(half, -h), base + Vector2(half, 0), base + Vector2(-half, 0)]
		var top := [base + Vector2(-half - 3.0, -h), base + Vector2(0, -h - w * 0.55), base + Vector2(half + 3.0, -h)]
		if solid:
			CuteArt._shape(self, body, wall, true, _rng)
			CuteArt._shape(self, top, roof, true, _rng)
			draw_rect(Rect2(base + Vector2(-3, -h * 0.5), Vector2(6, h * 0.5)), Color("#7A5232"))
			draw_rect(Rect2(base + Vector2(half * 0.35, -h * 0.8), Vector2(w * 0.22, h * 0.3)), Color("#BFE3F7"))
			draw_rect(Rect2(base + Vector2(-half * 0.8, -h * 0.8), Vector2(w * 0.22, h * 0.3)), Color("#BFE3F7"))
		else:
			draw_colored_polygon(PackedVector2Array(body), Color(wall, 0.35))
			draw_colored_polygon(PackedVector2Array(top), Color(roof, 0.35))
			draw_polyline(PackedVector2Array(body + [body[0]]), Color(EDGE, 0.35), 1.6)
			draw_polyline(PackedVector2Array(top + [top[0]]), Color(EDGE, 0.35), 1.6)

	func _row(x0: float, x1: float, base_y: float, solid: bool, skip := [], height := Vector2(24.0, 34.0)) -> void:
		var x := x0
		while x < x1:
			var w := _rng.randf_range(24.0, 34.0)
			var h := _rng.randf_range(height.x, height.y)
			var wall: Color = WALLS[_rng.randi() % WALLS.size()]
			var roof: Color = ROOFS[_rng.randi() % ROOFS.size()]
			var cx := x + w / 2.0
			var blocked := false
			for r in skip:
				if cx > r[0] - w / 2.0 and cx < r[1] + w / 2.0:
					blocked = true
			if not blocked and cx + w / 2.0 < x1 + 4.0:
				_house(Vector2(cx, base_y), w, h, wall, roof, solid)
			x += w + _rng.randf_range(2.0, 6.0)

	func _tree(c: Vector2, r: float, solid := true) -> void:
		draw_line(c, c + Vector2(0, r * 1.2), Color("#7A5232"), 3.0)
		if solid:
			CuteArt._shape(self, CuteArt._oval(c + Vector2(0, -r * 0.2), Vector2(r, r)), Color("#4FA34A"), true, _rng)
		else:
			draw_circle(c + Vector2(0, -r * 0.2), r, Color("#4FA34A", 0.35))

	# The other blocks, faded: nothing she may go to alone, but they are there.
	func _neighbours() -> void:
		var east := DAND_X + ST_W / 2.0 + 8.0
		var west := HOLT_X - ST_W / 2.0 - 8.0
		var holt_e := HOLT_X + ST_W / 2.0 + 6.0
		var dand_w := DAND_X - ST_W / 2.0 - 6.0
		# North of 6e (between 7e and 6e).
		for base in [150.0, 202.0]:
			_row(holt_e, dand_w, base, false)
			_row(20.0, west, base, false)
			_row(east + 6.0, 840.0, base, false)
		# South of 5e (between 5e and 4e).
		for base in [510.0, 560.0]:
			_row(holt_e, dand_w, base, false)
			_row(20.0, west, base, false)
			if GameState.age >= StreetScene.CROSS_AGE or base < 520.0:
				_row(east + 6.0, size.x - 20.0 if GameState.age >= StreetScene.CROSS_AGE else 830.0, base, false)
		# Across Rue Holt, west of her block: more houses, to the edge of the sheet.
		_row(20.0, west, 305.0, false)
		_row(20.0, west, 345.0, false)
		_row(20.0, west, 425.0, false)

	func _school() -> void:
		var x0 := 770.0
		var x1 := 955.0
		var y0 := 285.0
		var y1 := 425.0
		CuteArt._shape(self, [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)], Color("#C9654A"), true, _rng)
		CuteArt._shape(self, [Vector2(x0 - 6, y0), Vector2((x0 + x1) / 2.0, y0 - 30), Vector2(x1 + 6, y0)], Color("#7A5232"), true, _rng)
		for row in 2:
			for col in 6:
				draw_rect(Rect2(x0 + 14 + col * 28, y0 + 14 + row * 44, 18, 26), Color("#BFE3F7"))
				draw_rect(Rect2(x0 + 14 + col * 28, y0 + 14 + row * 44, 18, 26), Color("#5E6B80", 0.7), false, 1.5)
		draw_rect(Rect2((x0 + x1) / 2.0 - 13.0, y1 - 40.0, 26, 40), Color("#3D8BD9"))
		draw_rect(Rect2((x0 + x1) / 2.0 - 13.0, y1 - 40.0, 26, 40), Color("#5E6B80", 0.8), false, 2.0)
		# A flag on a pole, a round clock in the gable, and a zigzag fence round the yard.
		var pole := Vector2((x0 + x1) / 2.0, y0 - 30.0)
		CuteArt._stroke(self, [pole, pole + Vector2(0, -34)], Color("#5E6B80"), 2.4, true, _rng)
		CuteArt._shape(self, [pole + Vector2(0, -34), pole + Vector2(24, -28), pole + Vector2(0, -20)], Color("#D9342B"), true, _rng)
		var fence := []
		for k in 24:
			fence.append(Vector2(x0 - 6.0 + k * 8.2, y1 + 8.0 + (6.0 if k % 2 == 0 else 0.0)))
		CuteArt._crayon_line(self, fence, Color("#8A8176"), 2.0, _rng, 1)

	# ── Lanes: an H between the avenues ──

	func _lane(a: Vector2, b: Vector2, wall: Color) -> void:
		var d := (b - a).normalized()
		var n := d.orthogonal() * 7.0
		CuteArt._shape(self, [a + n, b + n, b - n, a - n], wall, true, _rng, false)
		CuteArt._stroke(self, [a + n, b + n], wall.darkened(0.35), 2.0, true, _rng)
		CuteArt._stroke(self, [a - n, b - n], wall.darkened(0.35), 2.0, true, _rng)

	func _lanes() -> void:
		var lane := Color("#D8C9AC")
		var green := Color("#A9D98A")
		_lane(Vector2(LANE_L, BLOCK_TOP - 3.0), Vector2(LANE_L, BLOCK_BOTTOM + 3.0), lane)
		_lane(Vector2(LANE_R, BLOCK_TOP - 3.0), Vector2(LANE_R, BLOCK_BOTTOM + 3.0), green)
		_lane(Vector2(LANE_L, LANE_Y), Vector2(LANE_R, LANE_Y), lane)

	# The houses facing the avenues, the lanes cut gaps through them.
	func _block_houses() -> void:
		var gaps := [[LANE_L - 20.0, LANE_L + 20.0], [LANE_R - 20.0, LANE_R + 20.0], [HOUSE_X - 40.0, HOUSE_X + 40.0]]
		_row(316.0, 652.0, 302.0, true, gaps)
		_row(316.0, 652.0, 430.0, true, [[LANE_L - 20.0, LANE_L + 20.0], [LANE_R - 20.0, LANE_R + 20.0]], Vector2(24.0, 32.0))
		for t in [[283.0, 352.0], [284.0, 400.0], [690.0, 354.0], [688.0, 402.0]]:
			_tree(Vector2(t[0], t[1]), 9.0)

	func _yards() -> void:
		for t in [[385.0, 322.0], [420.0, 388.0], [596.0, 386.0], [525.0, 394.0], [455.0, 392.0], [372.0, 380.0]]:
			_tree(Vector2(t[0], t[1]), 8.0)
		# Her swing in the yard behind her house.
		var s := Vector2(HOUSE_X + 78.0, 320.0)
		CuteArt._stroke(self, [s + Vector2(-16, 22), s + Vector2(0, -2), s + Vector2(16, 22)], Color("#7A5232"), 2.6, true, _rng)
		CuteArt._crayon_line(self, [s + Vector2(-9, 1), s + Vector2(-9, 16)], Color("#5E6B80"), 1.6, _rng, 1)
		CuteArt._crayon_line(self, [s + Vector2(9, 1), s + Vector2(9, 16)], Color("#5E6B80"), 1.6, _rng, 1)
		CuteArt._crayon_line(self, [s + Vector2(-11, 16), s + Vector2(11, 16)], CRAYONS[0], 3.0, _rng, 1)
		# A stray cat in the lane.
		CuteArt.cat_head(self, Vector2(603, 337), 8.0, Color("#6E6E7A"), true, _rng)

	# ── Her house, Xin-Xin and Oh Bon! ──

	func _shops_and_home() -> void:
		# Her house: bigger, yellow with a red roof, a heart over it and a flag.
		var b := Vector2(HOUSE_X, 306.0)
		CuteArt._shape(self, [b + Vector2(-27, -36), b + Vector2(27, -36), b + Vector2(27, 0), b + Vector2(-27, 0)], Color("#FFD23F"), true, _rng)
		CuteArt._shape(self, [b + Vector2(-32, -36), b + Vector2(0, -62), b + Vector2(32, -36)], Color("#D9342B"), true, _rng)
		draw_rect(Rect2(b + Vector2(-5, -20), Vector2(10, 20)), Color("#3D8BD9"))
		draw_rect(Rect2(b + Vector2(10, -30), Vector2(12, 12)), Color("#BFE3F7"))
		draw_rect(Rect2(b + Vector2(-22, -30), Vector2(12, 12)), Color("#BFE3F7"))
		CuteArt.heart(self, b + Vector2(40, -52), 9.0, CRAYONS[0], true, _rng)
		# Oh Bon!: a red shop with a checkered awning, at the corner of Rue Holt.
		var o := Vector2(292.0, 306.0)
		CuteArt._shape(self, [o + Vector2(-23, -34), o + Vector2(23, -34), o + Vector2(23, 0), o + Vector2(-23, 0)], Color("#D9342B"), true, _rng)
		for k in 8:
			draw_rect(Rect2(o + Vector2(-23 + k * 5.75, -34), Vector2(5.75, 7)), Color("#FFFDF7") if k % 2 == 0 else Color("#8E1A20"))
		draw_rect(Rect2(o + Vector2(-14, -22), Vector2(28, 22)), Color("#2B2B33"))
		draw_rect(Rect2(o + Vector2(-14, -22), Vector2(28, 22)), Color("#FFFDF7"), false, 1.5)
		# Dépanneur Xin-Xin: a yellow shop with a striped awning, at the corner of Rue Dandurand.
		var x := Vector2(680.0, 306.0)
		CuteArt._shape(self, [x + Vector2(-25, -34), x + Vector2(25, -34), x + Vector2(25, 0), x + Vector2(-25, 0)], Color("#F2C230"), true, _rng)
		for k in 8:
			draw_rect(Rect2(x + Vector2(-25 + k * 6.25, -34), Vector2(6.25, 9)), Color("#D9342B") if k % 2 == 0 else Color("#FFFDF7"))
		draw_rect(Rect2(x + Vector2(-15, -22), Vector2(30, 22)), Color("#BFE3F7"))
		draw_rect(Rect2(x + Vector2(-15, -22), Vector2(30, 22)), Color("#5E6B80"), false, 1.5)
		CuteArt.star(self, x + Vector2(0, -12), 5.0, CRAYONS[4], false, _rng)

	# ── Where she may not go ──

	# What she can reach: her block and the streets round it; from 8 (she may cross), also the corners across them and the school.
	# The rest (7e, 4e, west of the corners) leads nowhere in the game yet.
	func _reachable() -> Rect2:
		var top := SIX_Y - AVE_W / 2.0
		var bottom := FIVE_Y + AVE_W / 2.0
		if GameState.age >= StreetScene.CROSS_AGE:
			return Rect2(182.0, top - 52.0, 780.0, bottom - top + 104.0)
		return Rect2(HOLT_X - ST_W / 2.0, top, DAND_X - HOLT_X + ST_W, bottom - top)

	# Everything else coloured over in grey crayon, scribbled by hand, with a line round what stays hers. The names go on top, so
	# they can still be read, and the title and the doodles too.
	func _grey_out() -> void:
		var open := _reachable()
		var first := 66.0
		var grey := Color("#8E8F96", 0.8)
		var scribble := Color("#6E6F78", 0.5)
		for r: Rect2 in [Rect2(0, first, size.x, open.position.y - first), Rect2(0, open.end.y, size.x, size.y - open.end.y),
				Rect2(0, open.position.y, open.position.x, open.size.y), Rect2(open.end.x, open.position.y, size.x - open.end.x, open.size.y)]:
			draw_rect(r, grey)
			var y := r.position.y + 5.0
			while y < r.end.y - 5.0:
				CuteArt._crayon_line(self, [Vector2(r.position.x + 3.0, y), Vector2(r.end.x - 3.0, y + _rng.randf_range(-3.0, 3.0))], scribble, 2.0, _rng, 1)
				y += 12.0
		CuteArt._crayon_line(self, [open.position, Vector2(open.end.x, open.position.y), open.end, Vector2(open.position.x, open.end.y), open.position, open.position + Vector2(30, 0)], Color("#F2C230"), 3.4, _rng)

	# ── Names ──

	func _labels() -> void:
		var ink := Color("#33415A")
		_text("7e Avenue", Vector2(560, SEVEN_Y + 6), 16, ink)
		_text("6e Avenue", Vector2(590, SIX_Y + 6), 18, ink)
		_text("5e Avenue", Vector2(480, FIVE_Y + 6), 18, ink)
		_text("4e Avenue", Vector2(650, FOUR_Y + 6), 16, ink)
		_text("Rue Holt", Vector2(HOLT_X + 5, 355), 16, ink, -PI / 2.0)
		_text("Rue Dandurand", Vector2(DAND_X + 5, 345), 16, ink, -PI / 2.0)
		_text("Ma maison", Vector2(HOUSE_X, 330), 15, Color("#C2406E"), -0.03)
		_text("Oh Bon!", Vector2(300, 326), 13, Color("#C0262C"), 0.02)
		_text("Dépanneur\nXin-Xin", Vector2(676, 322), 11, Color("#B5651D"), -0.02)
		_text("ruelle", Vector2(LANE_L - 11, LANE_Y + 22), 12, Color("#7A6B52"), -PI / 2.0)
		_text("ruelle verte", Vector2(LANE_R + 12, LANE_Y + 26), 12, Color("#3E7A2C"), -PI / 2.0)
		_text("ruelle", Vector2(425, LANE_Y + 17), 12, Color("#7A6B52"), 0.0)
		_text("ma cour", Vector2(597, 322), 11, Color("#3E7A2C"), -0.04)
		_text("minou", Vector2(606, 357), 11, Color("#6E6E7A"))
		_text("École", Vector2(862, 281), 17, Color("#FFF3D6"), -0.02)

	# ── Doodles ──

	func _decor() -> void:
		_title()
		CuteArt.sun(self, Vector2(932, 44), 17.0, true, _rng)
		# Clouds and birds.
		for c in [[Vector2(790, 34), 1.0], [Vector2(836, 52), 0.8]]:
			for k in [[-14, 4, 10], [0, -2, 13], [15, 4, 10]]:
				CuteArt._shape(self, CuteArt._oval(c[0] + Vector2(k[0], k[1]) * c[1], Vector2(k[2], k[2] * 0.8) * c[1]), Color("#CFE3F5"), true, _rng)
		for b in [Vector2(640, 38), Vector2(668, 28)]:
			CuteArt._crayon_line(self, [b + Vector2(-8, 2), b + Vector2(-3, -4), b, b + Vector2(3, -4), b + Vector2(8, 2)], Color("#5A5A6A"), 1.8, _rng)
		# The compass: N, S, O (ouest), E.
		var c := Vector2(906, 168)
		var ink := Color("#33415A")
		CuteArt._crayon_line(self, [c + Vector2(0, 26), c + Vector2(0, -26)], ink, 2.2, _rng)
		CuteArt._crayon_line(self, [c + Vector2(-26, 0), c + Vector2(26, 0)], ink, 2.2, _rng)
		CuteArt._shape(self, [c + Vector2(-6, -18), c + Vector2(0, -32), c + Vector2(6, -18)], Color("#E04F5F"), true, _rng)
		_text("N", c + Vector2(0, -38), 15, Color("#C0262C"))
		_text("S", c + Vector2(0, 46), 13, ink)
		_text("O", c + Vector2(-38, 5), 13, ink)
		_text("E", c + Vector2(38, 5), 13, ink)
		# Hearts and stars in the corners, a few flowers.
		for p in [Vector2(40, 610), Vector2(960, 440), Vector2(930, 612)]:
			CuteArt.heart(self, p, 11.0, CRAYONS[0], true, _rng)
		for p in [Vector2(120, 606), Vector2(890, 480), Vector2(30, 126)]:
			CuteArt.star(self, p, 11.0, CRAYONS[2], true, _rng)
		for p in [Vector2(170, 598), Vector2(852, 610), Vector2(70, 516)]:
			CuteArt.flower(self, p, 11.0, CRAYONS[5], true, _rng)
		# What the map is for.
		_text("Mon coin du monde !", Vector2(340, 624), 18, CRAYONS[3], -0.02)

	# She is only seven: the world past the avenues is not hers yet.
	func _stop_sign() -> void:
		var c := Vector2(880, 520)
		var pts := []
		for k in 8:
			pts.append(c + Vector2.from_angle(TAU * (k + 0.5) / 8.0) * 22.0)
		CuteArt._shape(self, pts, Color("#D9342B"), true, _rng)
		_text("STOP", c + Vector2(0, 6), 14, Color("#FFFDF7"))
		_text("Pas le droit d'aller plus loin\ntoute seule !", c + Vector2(0, 42), 14, Color("#C0262C"), -0.02)
