extends CanvasLayer
## Autoload "TownMap": Charlotte's map of the neighbourhood, drawn by a child. A button left of the notebook's (or the C key)
## opens a big sheet of drawing paper, north up: her block between Rue Holt (north) and Rue Dandurand (south), 5e Avenue (west)
## and 6e Avenue (east), with the houses in a column along each avenue, the lanes (an H), her house, dépanneur Xin-Xin, Oh Bon! and the school across Rue Dandurand,
## all in wobbly wax crayon (CuteArt). A little Charlotte stands where she is ("Je suis ici !") and follows her
## as the scene changes. What she can't reach is greyed over (`_Sheet._reachable`, by her age); before 8 years old a stop sign
## says she may not go farther alone. The game pauses while it is open.
## `--map` (a user arg) opens it a second after the scene starts, for screenshots.

const BLUE := Color("#1D4F91")
const INK := Color("#3A3A48")
const SHEET := Vector2(1000, 680)
const SCALE := 1.0
const CRAYONS := [Color("#E85FA0"), Color("#3D8BD9"), Color("#F2C230"), Color("#4FA34A"), Color("#E8812E"), Color("#8E5FC4")]
## The map's geometry, in sheet pixels, in the real proportions (reference/cartes/google_map_immediate_area.png): a block is about three
## times as long, Holt to Dandurand, as it is wide, 5e to 6e; the lanes run about 18 % of the way in from each street. North is up,
## west left: Rue Holt on top, the avenues run down the sheet. Left of SIDE is the paper's margin: the title, the compass, the stop sign.
const SIDE := 300.0
const FOUR_X := 345.0
const FIVE_X := 498.0
const SIX_X := 651.0
const SEVEN_X := 804.0
const EIGHT_X := 957.0
const HOLT_Y := 50.0
const DAND_Y := 510.0
const AVE_W := 20.0
const ST_W := 22.0
const LANE_X := 574.0
const LANE_T := 133.0
const LANE_B := 427.0
const HOUSE_Y := 290.0
const HOUSE_X := 621.0
const SHOP_X := 618.0
## The map goes on past the sheet: south to Rue Masson (6e Avenue runs about 260 m from Dandurand to Masson, Holt to Dandurand
## about 205 m for the 460 px of the sheet), west to Rue D'Iberville and east to Boulevard Saint-Michel along Masson. The sheet is a
## window on it that slides to wherever she is (`_pan_to`), the same size of drawing, never zoomed out.
const MASSON_Y := 1093.0
const AVE_STEP := FIVE_X - FOUR_X
const MOLSON_X := FOUR_X - 3.0 * AVE_STEP - 320.0
const IBERVILLE_X := FOUR_X - 3.0 * AVE_STEP - 640.0
const TEN_X := FOUR_X + 5.0 * AVE_STEP + 151.0
const STMICHEL_X := FOUR_X + 5.0 * AVE_STEP + 338.0
const WORLD := Rect2(IBERVILLE_X - 120.0, 0.0, STMICHEL_X + 120.0 - (IBERVILLE_X - 120.0), MASSON_Y + 150.0)
## Where each street crossing Masson lies on the map (by the gap's name in the Masson scenes).
const MASSON_GAPS := {"rue_iberville": IBERVILLE_X, "rue_molson": MOLSON_X, "rue_1re": FOUR_X - 3.0 * AVE_STEP,
	"rue_2e": FOUR_X - 2.0 * AVE_STEP, "rue_3e": FOUR_X - AVE_STEP, "rue_4e": FOUR_X, "rue_5e": FIVE_X, "rue_6e": SIX_X,
	"rue_7e": SEVEN_X, "rue_8e": EIGHT_X, "rue_9e": FOUR_X + 5.0 * AVE_STEP, "rue_10e": TEN_X, "rue_stmichel": STMICHEL_X}

## Charlotte on the sidewalks round her block.
const WALK_W := FIVE_X + 14.0
const WALK_E := SIX_X - 14.0
const WALK_N := HOLT_Y + 15.0
const WALK_S := DAND_Y - 15.0

var _button: Button
var _open := false
var _page: Control
var _sheet: _Sheet
## The map's drawing is thousands of crayon strokes: drawn once into this viewport when the map opens (or she moves), then only
## its picture slides under the window, or dragging it stutters.
var _bake: SubViewport
var _map: Node2D
const BAKE := 2.0
var _paper: _Sheet
var _top: _Sheet
var _you: _You
## How far the map has slid under the sheet (map pixels), and the slide in progress.
var _pan := Vector2.ZERO
var _slide: Tween


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
	if _open and event is InputEventKey and event.pressed:
		var step := {KEY_LEFT: Vector2(-60, 0), KEY_RIGHT: Vector2(60, 0), KEY_UP: Vector2(0, -60), KEY_DOWN: Vector2(0, 60),
			KEY_A: Vector2(-60, 0), KEY_D: Vector2(60, 0), KEY_W: Vector2(0, -60), KEY_S: Vector2(0, 60)}
		if step.has(event.keycode):
			get_viewport().set_input_as_handled()
			_stop_slide()
			_set_pan(_pan + step[event.keycode])
			return
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
		for s in [_paper, _sheet, _top]:
			s.queue_redraw()
		_rebake()
		_set_pan(Vector2.ZERO)
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
			# 6e Avenue, Charlotte's side, from Masson (the left end, past the sheet's foot) to Holt: the part below Dandurand is the
			# first `_dand_f` of its length.
			var dand: float = scene.call("_dandurand_f") if scene.has_method("_dandurand_f") else 0.0
			if f < dand:
				return {"at": Vector2(WALK_E, lerpf(MASSON_Y - ST_W / 2.0 - 10.0, DAND_Y + ST_W / 2.0 + 10.0, f / dand)), "say": "Je suis sur la 6e, vers Masson !"}
			return {"at": Vector2(WALK_E, lerpf(WALK_S, WALK_N, (f - dand) / (1.0 - dand))), "say": "Je suis ici !"}
		"sixieme_est":
			# The other side of 6e Avenue, the odd numbers: Holt on the left of the view, Dandurand, then Masson on the right.
			var dand2: float = scene.call("_dandurand_f") if scene.has_method("_dandurand_f") else 1.0
			if f > dand2:
				return {"at": Vector2(SIX_X + AVE_W / 2.0 + 8.0, lerpf(DAND_Y + ST_W / 2.0 + 10.0, MASSON_Y - ST_W / 2.0 - 10.0, (f - dand2) / (1.0 - dand2))),
					"say": "Je suis sur la 6e, vers Masson !"}
			return {"at": Vector2(SIX_X + AVE_W / 2.0 + 8.0, lerpf(HOLT_Y + ST_W / 2.0 + 6.0, DAND_Y - ST_W / 2.0 - 6.0, f / dand2)),
				"say": "Je suis en face de chez moi !"}
		"holt":
			return {"at": Vector2(lerpf(WALK_E, WALK_W, f), WALK_N), "say": "Je suis ici !"}
		"cinquieme":
			return {"at": Vector2(WALK_W, lerpf(WALK_N, WALK_S, f)), "say": "Je suis ici !"}
		"dandurand":
			return {"at": Vector2(lerpf(WALK_W, WALK_E, f), WALK_S), "say": "Je suis ici !"}
		"ruelle":
			return {"at": Vector2(LANE_X, lerpf(LANE_T, LANE_B, f)), "say": "Je suis dans la ruelle !"}
		"ruelle_dandurand":
			return {"at": Vector2(lerpf(WALK_W, WALK_E, f), LANE_B), "say": "Je suis dans la ruelle !"}
		"ruelle_holt":
			return {"at": Vector2(lerpf(WALK_E, WALK_W, f), LANE_T), "say": "Je suis dans la ruelle !"}
		"house":
			return {"at": Vector2(HOUSE_X, HOUSE_Y - 10.0), "say": "Je suis chez moi !"}
		"depanneur":
			return {"at": Vector2(SHOP_X, DAND_Y - 30.0), "say": "Je suis chez Xin-Xin !"}
		"ohbon":
			return {"at": Vector2(SHOP_X, HOLT_Y + 50.0), "say": "Je suis chez Oh Bon !"}
	if key == "masson_impair" or key == "masson_pair":
		# Rue Masson, D'Iberville to Saint-Michel: between the two crossings she stands between, as far along as she is (the scene's
		# blocks aren't all drawn at the same scale, so each block maps onto its own stretch of the map).
		var y: float = MASSON_Y - ST_W / 2.0 - 8.0 if key == "masson_impair" else MASSON_Y + ST_W / 2.0 + 8.0
		var at_x := _masson_x(scene, who.position.x if who is Node2D else 0.0)
		return {"at": Vector2(at_x, y), "say": "Je suis sur la rue Masson !"}
	return {"at": Vector2(HOUSE_X, HOUSE_Y - 10.0), "say": "Je suis ici !"}


## Where x in a Masson scene lies on the map: between the map positions of the two crossings round it.
func _masson_x(scene: Node, x: float) -> float:
	var starts: Array = scene.get("_starts")
	var lay: Array = scene.get("layout")
	var pts := []
	for i in lay.size():
		if MASSON_GAPS.has(lay[i]):
			pts.append([(starts[i] + starts[i + 1]) / 2.0, MASSON_GAPS[lay[i]]])
	if pts.size() < 2:
		return SIX_X
	for i in range(pts.size() - 1):
		if x <= pts[i + 1][0] or i == pts.size() - 2:
			var t := clampf((x - pts[i][0]) / maxf(pts[i + 1][0] - pts[i][0], 1.0), -0.2, 1.2)
			return lerpf(pts[i][1], pts[i + 1][1], t)
	return pts[-1][1]


func _place_you() -> void:
	var here := _here()
	if _sheet.here != here.at:
		_sheet.here = here.at
		_sheet.queue_redraw()
		_rebake()
	_you.position = here.at
	_you.text = here.say
	# Out of the sheet's window: the map slides to her, by itself, once it is open.
	var target := _pan_for(here.at)
	_you.bubble_left = here.at.x - target.x > 700.0
	if target != _pan:
		if _slide:
			_slide.kill()
		_slide = create_tween()
		_slide.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_slide.tween_interval(0.35)
		_slide.tween_method(_set_pan, _pan, target, clampf(target.length() / 700.0, 0.6, 1.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The slide that keeps a point of the map in the sheet's window: none while it is already well inside (her block), else the
## point in the middle of the window, as far as the map goes.
func _pan_for(at: Vector2) -> Vector2:
	var view := Rect2(SIDE, 0.0, SHEET.x - SIDE, SHEET.y)
	if view.grow(-70.0).has_point(at):
		return Vector2.ZERO
	var pan := at - view.get_center()
	pan.x = clampf(pan.x, WORLD.position.x - SIDE, WORLD.end.x - SHEET.x)
	pan.y = clampf(pan.y, 0.0, WORLD.end.y - SHEET.y)
	return pan


func _set_pan(pan: Vector2) -> void:
	pan.x = clampf(pan.x, WORLD.position.x - SIDE, WORLD.end.x - SHEET.x)
	pan.y = clampf(pan.y, 0.0, WORLD.end.y - SHEET.y)
	_pan = pan
	_map.position = Vector2(-SIDE, 0.0) - pan


func _rebake() -> void:
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE


func _stop_slide() -> void:
	if _slide:
		_slide.kill()
		_slide = null


## Dragging the map with the mouse or a finger to look round; it stays where it is left until the map is opened again.
func _drag(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_stop_slide()
		_set_pan(_pan - event.relative / SCALE)
	elif event is InputEventScreenDrag:
		_stop_slide()
		_set_pan(_pan - event.relative / SCALE)


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
	_paper = _Sheet.new()
	_paper.layer = "paper"
	_paper.size = SHEET
	holder.add_child(_paper)
	var window := Control.new()
	window.position = Vector2(SIDE, 0.0)
	window.size = Vector2(SHEET.x - SIDE, SHEET.y)
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_STOP
	window.mouse_default_cursor_shape = Control.CURSOR_DRAG
	window.gui_input.connect(_drag)
	holder.add_child(window)
	_bake = SubViewport.new()
	_bake.size = Vector2i((WORLD.size * BAKE).ceil())
	_bake.transparent_bg = true
	_bake.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_page.add_child(_bake)
	_sheet = _Sheet.new()
	_sheet.layer = "map"
	_sheet.size = WORLD.end
	_sheet.scale = Vector2.ONE * BAKE
	_sheet.position = -WORLD.position * BAKE
	_bake.add_child(_sheet)
	_map = Node2D.new()
	_map.position = Vector2(-SIDE, 0.0)
	window.add_child(_map)
	var picture := Sprite2D.new()
	picture.texture = _bake.get_texture()
	picture.centered = false
	picture.position = WORLD.position
	picture.scale = Vector2.ONE / BAKE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# What a viewport renders over a clear background is premultiplied: blended as such, or the greyed crayon comes out dark.
	var premult := CanvasItemMaterial.new()
	premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	picture.material = premult
	_map.add_child(picture)
	_you = _You.new()
	_you.set_process(false)
	_map.add_child(_you)
	_top = _Sheet.new()
	_top.layer = "top"
	_top.size = SHEET
	holder.add_child(_top)
	var hint := Label.new()
	hint.text = "C, M ou clique à côté pour fermer"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	hint.position = Vector2(0, 696)
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
	# A Node2D, not a Control: the map reaches far left of its origin (D'Iberville), where a Control's drawing is cut off.
	extends Node2D

	var size := Vector2.ZERO

	const ROAD := Color("#9AA5B5")
	const EDGE := Color("#5E6B80")
	const DASH := Color("#F7D154")
	const WALLS := [Color("#E8812E"), Color("#F2C230"), Color("#E85FA0"), Color("#3D8BD9"), Color("#8E5FC4"), Color("#E0A878"), Color("#C9503C"), Color("#6DB35A")]
	const ROOFS := [Color("#C9503C"), Color("#7A5232"), Color("#3D8BD9"), Color("#4FA34A"), Color("#8E5FC4"), Color("#3A3A48")]
	const AVENUES := [IBERVILLE_X, MOLSON_X, FOUR_X - 3.0 * AVE_STEP, FOUR_X - 2.0 * AVE_STEP, FOUR_X - AVE_STEP, FOUR_X, FIVE_X, SIX_X,
		SEVEN_X, EIGHT_X, FOUR_X + 5.0 * AVE_STEP, TEN_X, STMICHEL_X]
	const STREETS := [HOLT_Y, DAND_Y, MASSON_Y]
	var _rng := RandomNumberGenerator.new()
	## "paper" (the sheet under everything), "map" (the neighbourhood, larger than the sheet, slid under its window) or "top"
	## (the frame, the tape and the doodles in the margin, over the map).
	var layer := "map"
	## Where she stands on the map: the street she is on is never greyed, even where she may not go alone (a debug trip).
	var here := Vector2(HOUSE_X, HOUSE_Y)

	func _draw() -> void:
		_rng.seed = 2026
		match layer:
			"paper":
				_paper()
			"top":
				_decor()
				_frame()
				if DebugMenu.blocked(GameState.age < StreetScene.CROSS_AGE):
					_stop_sign()
			_:
				_block_wash()
				_roads()
				_neighbours()
				_south()
				_school()
				_lanes()
				_block_houses()
				_yards()
				_shops_and_home()
				_grey_out()
				_labels()

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
		var x0 := FIVE_X + AVE_W / 2.0 + 1.0
		var x1 := SIX_X - AVE_W / 2.0 - 1.0
		var y0 := HOLT_Y + ST_W / 2.0 + 1.0
		var y1 := DAND_Y - ST_W / 2.0 - 1.0
		CuteArt._shape(self, [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)], Color("#FFE680", 0.8), true, _rng, false)

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
		var x := 28.0
		var font := ThemeDB.fallback_font
		for i in title.length():
			var ch := title[i]
			var col: Color = CRAYONS[i % CRAYONS.size()]
			var w := font.get_char_size(ch.unicode_at(0), 40).x
			for pass_i in 2:
				draw_set_transform(Vector2(x, 54 + _rng.randf_range(-3, 3)) + Vector2(1.0, 0.8) * pass_i, _rng.randf_range(-0.12, 0.12), Vector2.ONE)
				draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(col, 1.0 if pass_i == 0 else 0.55))
			x += w + 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_text("par Chachoue ♥", Vector2(70, 92), 20, CRAYONS[0], -0.03, "l")

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
		var out := []
		for x in AVENUES:
			out.append([x - AVE_W / 2.0, x + AVE_W / 2.0])
		return out

	func _st_cuts() -> Array:
		return STREETS.map(func(y): return [y - ST_W / 2.0, y + ST_W / 2.0])

	func _roads() -> void:
		# The surfaces first (scribbled grey), then the kerbs and the yellow dashes between the crossings.
		for x in AVENUES:
			var h := AVE_W / 2.0
			CuteArt._shape(self, [Vector2(x - h, -8), Vector2(x + h, -8), Vector2(x + h, size.y + 8), Vector2(x - h, size.y + 8)], ROAD, true, _rng, false)
		for y in STREETS:
			var h := ST_W / 2.0
			CuteArt._shape(self, [Vector2(WORLD.position.x, y - h), Vector2(size.x + 8, y - h), Vector2(size.x + 8, y + h), Vector2(WORLD.position.x, y + h)], ROAD, true, _rng, false)
		for x in AVENUES:
			for side in [-1.0, 1.0]:
				for p in _pieces(-8.0, size.y + 8.0, _st_cuts()):
					CuteArt._stroke(self, [Vector2(x + side * AVE_W / 2.0, p[0]), Vector2(x + side * AVE_W / 2.0, p[1])], EDGE, 2.2, true, _rng)
			_dashes(Vector2(x, -8), Vector2(x, size.y + 8), _st_cuts().map(func(c): return [c[0] - 4.0, c[1] + 4.0]))
		for y in STREETS:
			for side in [-1.0, 1.0]:
				for p in _pieces(WORLD.position.x, size.x + 8.0, _av_cuts()):
					CuteArt._stroke(self, [Vector2(p[0], y + side * ST_W / 2.0), Vector2(p[1], y + side * ST_W / 2.0)], EDGE, 2.2, true, _rng)
			_dashes(Vector2(WORLD.position.x, y), Vector2(size.x + 8, y), _av_cuts().map(func(c): return [c[0] - 4.0, c[1] + 4.0]))
		# Zebra crossings round the block's four corners, the way she crosses.
		for x in [FIVE_X, SIX_X]:
			for y in [HOLT_Y, DAND_Y]:
				for k in 4:
					var off := -ST_W / 2.0 + 3.0 + k * (ST_W - 6.0) / 3.0
					draw_line(Vector2(x + AVE_W / 2.0 + 1.0, y + off), Vector2(x + AVE_W / 2.0 + 7.0, y + off), Color("#FFFDF7", 0.9), 2.4)

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

	# Houses one above the other along an avenue, from y0 to y1, leaving out the ranges in `skip`.
	func _column(x: float, y0: float, y1: float, solid: bool, skip := []) -> void:
		var y := y0
		while y < y1:
			var w := _rng.randf_range(24.0, 34.0)
			var h := _rng.randf_range(24.0, 34.0)
			var wall: Color = WALLS[_rng.randi() % WALLS.size()]
			var roof: Color = ROOFS[_rng.randi() % ROOFS.size()]
			var base := y + w * 0.55 + h
			var clear := true
			for r in skip:
				if base > r[0] and y < r[1]:
					y = r[1]
					clear = false
			if clear:
				if base <= y1:
					_house(Vector2(x, base), w, h, wall, roof, solid)
				y = base + _rng.randf_range(4.0, 9.0)

	func _tree(c: Vector2, r: float, solid := true) -> void:
		draw_line(c, c + Vector2(0, r * 1.2), Color("#7A5232"), 3.0)
		if solid:
			CuteArt._shape(self, CuteArt._oval(c + Vector2(0, -r * 0.2), Vector2(r, r)), Color("#4FA34A"), true, _rng)
		else:
			draw_circle(c + Vector2(0, -r * 0.2), r, Color("#4FA34A", 0.35))

	# The other blocks, faded: nothing she may go to alone, but they are there.
	func _neighbours() -> void:
		var north := HOLT_Y + ST_W / 2.0 + 4.0
		var south := DAND_Y - ST_W / 2.0 - 2.0
		var below := DAND_Y + ST_W / 2.0 + 6.0
		var above_masson := MASSON_Y - ST_W / 2.0 - 4.0
		for x in AVENUES:
			for side in [-30.0, 30.0]:
				if (x == FIVE_X and side > 0.0) or (x == SIX_X and side < 0.0):
					continue
				_column(x + side, north, south, false)
				_column(x + side, below, above_masson, false)
		# Below Dandurand on 6e Avenue, Charlotte's side: the gym, then the church to Masson; across, the row of plexes.
		_column(SIX_X + 30.0, below, above_masson, true)

	# Rue Masson and what stands along it: the shops in a row on both sides, the church between 5e and 6e on its north side, the park
	# between 1re and Molson on its south side, and the Maxi between Molson and 1re.
	func _south() -> void:
		for side in [-1.0, 1.0]:
			var y: float = MASSON_Y + side * (ST_W / 2.0 + 4.0)
			var x := IBERVILLE_X + 14.0
			while x < STMICHEL_X - 14.0:
				var w := _rng.randf_range(24.0, 32.0)
				var h := _rng.randf_range(22.0, 32.0)
				var wall: Color = WALLS[_rng.randi() % WALLS.size()]
				var roof: Color = ROOFS[_rng.randi() % ROOFS.size()]
				var on_avenue := false
				for ax in AVENUES:
					on_avenue = on_avenue or absf(x + w / 2.0 - ax) < AVE_W / 2.0 + w / 2.0 + 2.0
				var landmark: bool = (side < 0.0 and x > FIVE_X and x < SIX_X) or (side > 0.0 and x > FOUR_X - 3.0 * AVE_STEP - 320.0 and x < FOUR_X - 3.0 * AVE_STEP)
				if not on_avenue and not landmark:
					if side < 0.0:
						_house(Vector2(x + w / 2.0, y), w, h, wall, roof, true)
					else:
						_house(Vector2(x + w / 2.0, y + h + w * 0.55), w, h, wall, roof, true)
				x += w + _rng.randf_range(3.0, 7.0)
		# 6e Avenue's west side below the school, as Charlotte walks it (reference/streetview/6e-avenue/5446…–5544…): the gym in orange
		# brick, the schoolyard with its basketball hoop, the grey apartment block behind its lawn, the parish hall by the church.
		var w0 := FIVE_X + AVE_W / 2.0 + 10.0
		var w1 := SIX_X - AVE_W / 2.0 - 10.0
		var gy := DAND_Y + 176.0
		CuteArt._shape(self, [Vector2(w0 + 40, gy), Vector2(w1, gy), Vector2(w1, gy + 70), Vector2(w0 + 40, gy + 70)], Color("#D07A40"), true, _rng)
		for k in 4:
			draw_rect(Rect2(w0 + 52 + k * ((w1 - w0 - 64.0) / 4.0), gy + 12, 6, 30), Color("#BFE3F7"))
		var yy := gy + 86.0
		CuteArt._shape(self, [Vector2(w0, yy), Vector2(w1, yy), Vector2(w1, yy + 80), Vector2(w0, yy + 80)], Color("#C9C2B0"), true, _rng)
		var hoop := Vector2(w0 + 30, yy + 16)
		CuteArt._stroke(self, [hoop + Vector2(0, 50), hoop], EDGE, 2.4, true, _rng)
		draw_rect(Rect2(hoop + Vector2(-9, -8), Vector2(18, 12)), Color("#FFFDF7"))
		draw_arc(hoop + Vector2(0, 7), 5.0, 0.0, PI, 8, Color("#E8812E"), 2.0)
		var fence := []
		for k in 20:
			fence.append(Vector2(w0 + k * (w1 - w0) / 19.0, yy + (4.0 if k % 2 == 0 else 0.0)))
		CuteArt._crayon_line(self, fence, Color("#8A8176"), 1.8, _rng, 1)
		var ay := yy + 96.0
		CuteArt._shape(self, CuteArt._oval(Vector2((w0 + w1) / 2.0, ay + 70), Vector2((w1 - w0) / 2.0, 22)), Color("#9BD27E"), true, _rng)
		CuteArt._shape(self, [Vector2(w0 + 20, ay), Vector2(w1 - 20, ay), Vector2(w1 - 20, ay + 58), Vector2(w0 + 20, ay + 58)], Color("#A7AFB8"), true, _rng)
		for row in 2:
			for col in 3:
				draw_rect(Rect2(w0 + 30 + col * ((w1 - w0 - 64.0) / 3.0), ay + 8 + row * 24, 14, 14), Color("#5E6B80"))
		var hy := MASSON_Y - ST_W / 2.0 - 104.0
		CuteArt._shape(self, [Vector2(w0 + 20, hy), Vector2(w1 - 30, hy), Vector2(w1 - 30, hy + 40), Vector2(w0 + 20, hy + 40)], Color("#B5B0A6"), true, _rng)
		# The church: grey stone, its tower with the cross, between 5e and 6e on the north side.
		var c0 := FIVE_X + AVE_W / 2.0 + 10.0
		var c1 := SIX_X - AVE_W / 2.0 - 10.0
		var cb := MASSON_Y - ST_W / 2.0 - 4.0
		CuteArt._shape(self, [Vector2(c0, cb - 60), Vector2(c1, cb - 60), Vector2(c1, cb), Vector2(c0, cb)], Color("#A8A49C"), true, _rng)
		CuteArt._shape(self, [Vector2(c0 - 4, cb - 60), Vector2((c0 + c1) / 2.0, cb - 92), Vector2(c1 + 4, cb - 60)], Color("#6E6A64"), true, _rng)
		CuteArt._shape(self, [Vector2(c1 - 34, cb - 120), Vector2(c1 - 6, cb - 120), Vector2(c1 - 6, cb - 58), Vector2(c1 - 34, cb - 58)], Color("#9A968E"), true, _rng)
		CuteArt._stroke(self, [Vector2(c1 - 20, cb - 140), Vector2(c1 - 20, cb - 120)], INK, 2.4, true, _rng)
		CuteArt._stroke(self, [Vector2(c1 - 28, cb - 133), Vector2(c1 - 12, cb - 133)], INK, 2.4, true, _rng)
		for k in 4:
			draw_rect(Rect2(c0 + 14 + k * 26, cb - 46, 10, 22), Color("#BFE3F7"))
		# The park, south of Masson between 1re and Molson: a green lawn and its trees.
		var p0 := MOLSON_X + AVE_W / 2.0 + 6.0
		var p1 := FOUR_X - 3.0 * AVE_STEP - AVE_W / 2.0 - 6.0
		var pt := MASSON_Y + ST_W / 2.0 + 6.0
		CuteArt._shape(self, [Vector2(p0, pt), Vector2(p1, pt), Vector2(p1, pt + 90), Vector2(p0, pt + 90)], Color("#9BD27E"), true, _rng)
		var tx := p0 + 24.0
		while tx < p1 - 10.0:
			_tree(Vector2(tx, pt + 40.0 + _rng.randf_range(-12.0, 18.0)), 9.0)
			tx += 42.0

	func _school() -> void:
		var x0 := FIVE_X + AVE_W / 2.0 + 5.0
		var x1 := SIX_X - AVE_W / 2.0 - 5.0
		var y0 := DAND_Y + 56.0
		var y1 := DAND_Y + 158.0
		CuteArt._shape(self, [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)], Color("#C9654A"), true, _rng)
		CuteArt._shape(self, [Vector2(x0 - 6, y0), Vector2((x0 + x1) / 2.0, y0 - 30), Vector2(x1 + 6, y0)], Color("#7A5232"), true, _rng)
		for row in 2:
			for col in 4:
				draw_rect(Rect2(x0 + 12 + col * 28, y0 + 8 + row * 42, 18, 26), Color("#BFE3F7"))
				draw_rect(Rect2(x0 + 12 + col * 28, y0 + 8 + row * 42, 18, 26), Color("#5E6B80", 0.7), false, 1.5)
		draw_rect(Rect2((x0 + x1) / 2.0 - 13.0, y1 - 40.0, 26, 40), Color("#3D8BD9"))
		draw_rect(Rect2((x0 + x1) / 2.0 - 13.0, y1 - 40.0, 26, 40), Color("#5E6B80", 0.8), false, 2.0)
		# A flag on a pole, a round clock in the gable, and a zigzag fence round the yard.
		var pole := Vector2((x0 + x1) / 2.0, y0 - 30.0)
		CuteArt._stroke(self, [pole, pole + Vector2(0, -14)], Color("#5E6B80"), 2.4, true, _rng)
		CuteArt._shape(self, [pole + Vector2(0, -14), pole + Vector2(18, -10), pole + Vector2(0, -4)], Color("#D9342B"), true, _rng)
		var fence := []
		for k in 16:
			fence.append(Vector2(x0 - 6.0 + k * 8.2, y1 + 3.0 + (5.0 if k % 2 == 0 else 0.0)))
		CuteArt._crayon_line(self, fence, Color("#8A8176"), 2.0, _rng, 1)

	# ── Lanes: an H between the avenues ──

	func _lane(a: Vector2, b: Vector2, wall: Color) -> void:
		var d := (b - a).normalized()
		var n := d.orthogonal() * 5.0
		CuteArt._shape(self, [a + n, b + n, b - n, a - n], wall, true, _rng, false)
		CuteArt._stroke(self, [a + n, b + n], wall.darkened(0.35), 1.6, true, _rng)
		CuteArt._stroke(self, [a - n, b - n], wall.darkened(0.35), 1.6, true, _rng)

	func _lanes() -> void:
		var lane := Color("#D8C9AC")
		var green := Color("#A9D98A")
		var west := FIVE_X + AVE_W / 2.0 - 3.0
		var east := SIX_X - AVE_W / 2.0 + 3.0
		_lane(Vector2(west, LANE_T), Vector2(east, LANE_T), lane)
		_lane(Vector2(west, LANE_B), Vector2(east, LANE_B), green)
		_lane(Vector2(LANE_X, LANE_T), Vector2(LANE_X, LANE_B), lane)

	# The houses along the avenues, the lanes cut gaps between them.
	func _block_houses() -> void:
		var north := HOLT_Y + ST_W / 2.0 + 3.0
		var south := DAND_Y - ST_W / 2.0 - 2.0
		var lanes := [[LANE_T - 7.0, LANE_T + 7.0], [LANE_B - 7.0, LANE_B + 7.0]]
		_column(FIVE_X + AVE_W / 2.0 + 19.0, north, south, true, lanes)
		_column(HOUSE_X, LANE_T + 8.0, LANE_B - 8.0, true, [[HOUSE_Y - 62.0, HOUSE_Y + 22.0]])

	func _yards() -> void:
		for t in [[553.0, 170.0], [553.0, 225.0], [553.0, 300.0], [553.0, 375.0], [597.0, 175.0]]:
			_tree(Vector2(t[0], t[1]), 6.0)
		# Her swing in the yard behind her house.
		var s := Vector2(HOUSE_X - 30.0, HOUSE_Y - 18.0)
		CuteArt._stroke(self, [s + Vector2(-10, 14), s + Vector2(0, -2), s + Vector2(10, 14)], Color("#7A5232"), 2.0, true, _rng)
		CuteArt._crayon_line(self, [s + Vector2(-6, 8), s + Vector2(6, 8)], CRAYONS[0], 2.2, _rng, 1)
		# A little capybara in her yard by the swing.
		CuteArt.capybara(self, Vector2(HOUSE_X - 52.0, HOUSE_Y + 14.0), 8.0, true, _rng)
		# A stray cat in the lane.
		CuteArt.cat_head(self, Vector2(LANE_X, 350), 6.0, Color("#6E6E7A"), true, _rng)

	# ── Her house, Xin-Xin and Oh Bon! ──

	func _shops_and_home() -> void:
		# Her house: bigger, yellow with a red roof, a heart over it and a flag.
		var b := Vector2(HOUSE_X, HOUSE_Y)
		CuteArt._shape(self, [b + Vector2(-17, -24), b + Vector2(17, -24), b + Vector2(17, 0), b + Vector2(-17, 0)], Color("#FFD23F"), true, _rng)
		CuteArt._shape(self, [b + Vector2(-20, -24), b + Vector2(0, -42), b + Vector2(20, -24)], Color("#D9342B"), true, _rng)
		draw_rect(Rect2(b + Vector2(-3, -13), Vector2(7, 13)), Color("#3D8BD9"))
		draw_rect(Rect2(b + Vector2(7, -20), Vector2(7, 8)), Color("#BFE3F7"))
		draw_rect(Rect2(b + Vector2(-14, -20), Vector2(7, 8)), Color("#BFE3F7"))
		CuteArt.heart(self, b + Vector2(0, -50), 6.0, CRAYONS[0], true, _rng)
		# Oh Bon!: a red shop with a checkered awning, at the corner of Rue Holt.
		var o := Vector2(SHOP_X, LANE_T - 12.0)
		CuteArt._shape(self, [o + Vector2(-19, -30), o + Vector2(19, -30), o + Vector2(19, 0), o + Vector2(-19, 0)], Color("#D9342B"), true, _rng)
		for k in 8:
			draw_rect(Rect2(o + Vector2(-19 + k * 4.75, -30), Vector2(4.75, 6)), Color("#FFFDF7") if k % 2 == 0 else Color("#8E1A20"))
		draw_rect(Rect2(o + Vector2(-11, -19), Vector2(22, 19)), Color("#2B2B33"))
		draw_rect(Rect2(o + Vector2(-11, -19), Vector2(22, 19)), Color("#FFFDF7"), false, 1.5)
		# Dépanneur Xin-Xin: a yellow shop with a striped awning, at the corner of Rue Dandurand.
		var x := Vector2(SHOP_X, DAND_Y - ST_W / 2.0 - 4.0)
		CuteArt._shape(self, [x + Vector2(-19, -30), x + Vector2(19, -30), x + Vector2(19, 0), x + Vector2(-19, 0)], Color("#F2C230"), true, _rng)
		for k in 8:
			draw_rect(Rect2(x + Vector2(-19 + k * 4.75, -30), Vector2(4.75, 7)), Color("#D9342B") if k % 2 == 0 else Color("#FFFDF7"))
		draw_rect(Rect2(x + Vector2(-12, -19), Vector2(24, 19)), Color("#BFE3F7"))
		draw_rect(Rect2(x + Vector2(-12, -19), Vector2(24, 19)), Color("#5E6B80"), false, 1.5)
		CuteArt.star(self, x + Vector2(0, -10), 4.0, CRAYONS[4], false, _rng)

	# ── Where she may not go ──

	# What she can reach, as rectangles of the map: her block and the streets round it; from 8 (she may cross), also 6e Avenue down
	# to Masson and Rue Masson from D'Iberville to Saint-Michel, the corners across her streets and the school. The rest (the far
	# avenues) leads nowhere in the game yet.
	func _reachable() -> Array:
		var left := FIVE_X - AVE_W / 2.0
		var right := SIX_X + AVE_W / 2.0
		var top := HOLT_Y - ST_W / 2.0
		var bottom := DAND_Y + ST_W / 2.0
		if DebugMenu.no_limits:
			return [WORLD]
		var south := Rect2(left - 70.0, 0.0, right - left + 140.0, MASSON_Y)
		var masson := Rect2(IBERVILLE_X - 20.0, MASSON_Y - 70.0, STMICHEL_X - IBERVILLE_X + 40.0, 140.0)
		if GameState.age >= StreetScene.CROSS_AGE:
			return [south, masson]
		var open := [Rect2(left, top, right - left, bottom - top)]
		if here.y > MASSON_Y - 70.0:
			open.append(masson)
		elif here.y > bottom:
			open.append(Rect2(left - 70.0, bottom, right - left + 140.0, MASSON_Y - bottom))
		return open

	# Everything else coloured over in grey crayon, scribbled by hand, with a line round what stays hers. The names go on top, so
	# they can still be read. The map is cut on the edges of the open rectangles into cells, and each cell outside them is greyed.
	func _grey_out() -> void:
		var open: Array = _reachable()
		var grey := Color("#8E8F96", 0.8)
		var scribble := Color("#6E6F78", 0.5)
		var xs := [WORLD.position.x, WORLD.end.x]
		var ys := [WORLD.position.y, WORLD.end.y]
		for r: Rect2 in open:
			xs.append_array([clampf(r.position.x, WORLD.position.x, WORLD.end.x), clampf(r.end.x, WORLD.position.x, WORLD.end.x)])
			ys.append_array([clampf(r.position.y, WORLD.position.y, WORLD.end.y), clampf(r.end.y, WORLD.position.y, WORLD.end.y)])
		xs.sort()
		ys.sort()
		for j in range(ys.size() - 1):
			for i in range(xs.size() - 1):
				var cell := Rect2(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
				if cell.size.x < 1.0 or cell.size.y < 1.0:
					continue
				var inside := false
				for r: Rect2 in open:
					inside = inside or r.grow(0.5).encloses(cell)
				if inside:
					continue
				draw_rect(cell, grey)
				var y := cell.position.y + 5.0
				while y < cell.end.y - 5.0:
					CuteArt._crayon_line(self, [Vector2(cell.position.x + 3.0, y), Vector2(cell.end.x - 3.0, y + _rng.randf_range(-3.0, 3.0))], scribble, 2.0, _rng, 1)
					y += 12.0
		for r: Rect2 in open:
			if r != WORLD:
				CuteArt._crayon_line(self, [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position, r.position + Vector2(30, 0)], Color("#F2C230"), 3.4, _rng)

	# ── Names ──

	func _labels() -> void:
		var ink := Color("#33415A")
		_text("8e Avenue", Vector2(EIGHT_X + 5, 280), 14, ink, -PI / 2.0)
		_text("7e Avenue", Vector2(SEVEN_X + 5, 280), 14, ink, -PI / 2.0)
		_text("6e Avenue", Vector2(SIX_X + 5, 200), 15, ink, -PI / 2.0)
		_text("5e Avenue", Vector2(FIVE_X + 5, 280), 15, ink, -PI / 2.0)
		_text("4e Avenue", Vector2(FOUR_X + 5, 280), 14, ink, -PI / 2.0)
		_text("Rue Holt", Vector2(LANE_X, HOLT_Y + 5), 15, ink)
		_text("Rue Dandurand", Vector2(LANE_X, DAND_Y + 5), 15, ink)
		_text("Ma maison", Vector2(HOUSE_X - 12, HOUSE_Y + 14), 12, Color("#C2406E"), -0.03)
		_text("Oh Bon!", Vector2(SHOP_X - 46, LANE_T - 22), 12, Color("#C0262C"), 0.02)
		_text("Dépanneur\nXin-Xin", Vector2(SHOP_X - 48, DAND_Y - 44), 9, Color("#B5651D"), -0.02)
		_text("ruelle", Vector2(LANE_X - 9, 340), 11, Color("#7A6B52"), -PI / 2.0)
		_text("ruelle", Vector2(535, LANE_T + 4), 10, Color("#5E5240"), 0.0)
		_text("ruelle verte", Vector2(574, LANE_B + 4), 10, Color("#2E5E20"), 0.0)
		_text("ma cour", Vector2(HOUSE_X - 30, HOUSE_Y - 24), 9, Color("#3E7A2C"), -0.04)
		_text("minou", Vector2(LANE_X + 23, 354), 9, Color("#6E6E7A"))
		_text("École", Vector2(LANE_X, DAND_Y + 50), 15, Color("#FFF3D6"), -0.02)
		_text("Rue Masson", Vector2(LANE_X, MASSON_Y + 5), 15, ink)
		_text("Rue Masson", Vector2(FOUR_X - 2.5 * AVE_STEP, MASSON_Y + 5), 14, ink)
		_text("Rue Masson", Vector2(FOUR_X + 5.5 * AVE_STEP, MASSON_Y + 5), 14, ink)
		_text("Église", Vector2((FIVE_X + SIX_X) / 2.0 - 12.0, MASSON_Y - 50), 13, Color("#FFFDF7"), -0.02)
		_text("gym", Vector2(LANE_X + 10, DAND_Y + 215), 12, Color("#FFFDF7"), -0.02)
		_text("cour d'école", Vector2(LANE_X + 8, DAND_Y + 300), 11, Color("#5E5240"), 0.02)
		_text("Parc", Vector2((MOLSON_X + FOUR_X - 3.0 * AVE_STEP) / 2.0, MASSON_Y + 74), 15, Color("#2E5E20"), 0.02)
		for a in [[FOUR_X - 3.0 * AVE_STEP, "1re Avenue"], [FOUR_X - 2.0 * AVE_STEP, "2e Avenue"], [FOUR_X - AVE_STEP, "3e Avenue"],
				[FOUR_X + 5.0 * AVE_STEP, "9e Avenue"], [TEN_X, "10e Avenue"]]:
			_text(a[1], Vector2(a[0] + 5, 280), 14, ink, -PI / 2.0)
		for a in [[FOUR_X - 3.0 * AVE_STEP, "1re"], [FOUR_X - 2.0 * AVE_STEP, "2e"], [FOUR_X - AVE_STEP, "3e"], [FOUR_X, "4e"], [FIVE_X, "5e"],
				[SIX_X, "6e"], [SEVEN_X, "7e"], [EIGHT_X, "8e"], [FOUR_X + 5.0 * AVE_STEP, "9e"], [TEN_X, "10e"]]:
			_text(a[1] + " Avenue", Vector2(a[0] + 5, MASSON_Y - 150), 13, ink, -PI / 2.0)
		_text("Rue Molson", Vector2(MOLSON_X + 5, MASSON_Y - 150), 13, ink, -PI / 2.0)
		_text("Rue D'Iberville", Vector2(IBERVILLE_X + 5, MASSON_Y - 170), 14, ink, -PI / 2.0)
		_text("Boul. Saint-Michel", Vector2(STMICHEL_X + 5, MASSON_Y - 180), 14, ink, -PI / 2.0)

	# ── Doodles ──

	func _decor() -> void:
		_title()
		CuteArt.sun(self, Vector2(250, 150), 17.0, true, _rng)
		# Clouds and birds.
		for c in [[Vector2(70, 150), 1.0], [Vector2(125, 172), 0.8]]:
			for k in [[-14, 4, 10], [0, -2, 13], [15, 4, 10]]:
				CuteArt._shape(self, CuteArt._oval(c[0] + Vector2(k[0], k[1]) * c[1], Vector2(k[2], k[2] * 0.8) * c[1]), Color("#CFE3F5"), true, _rng)
		for b in [Vector2(170, 128), Vector2(198, 118)]:
			CuteArt._crayon_line(self, [b + Vector2(-8, 2), b + Vector2(-3, -4), b, b + Vector2(3, -4), b + Vector2(8, 2)], Color("#5A5A6A"), 1.8, _rng)
		# The compass: N, S, O (ouest), E.
		var c := Vector2(150, 270)
		var ink := Color("#33415A")
		CuteArt._crayon_line(self, [c + Vector2(0, 26), c + Vector2(0, -26)], ink, 2.2, _rng)
		CuteArt._crayon_line(self, [c + Vector2(-26, 0), c + Vector2(26, 0)], ink, 2.2, _rng)
		CuteArt._shape(self, [c + Vector2(-6, -18), c + Vector2(0, -32), c + Vector2(6, -18)], Color("#E04F5F"), true, _rng)
		_text("N", c + Vector2(0, -38), 15, Color("#C0262C"))
		_text("S", c + Vector2(0, 46), 13, ink)
		_text("O", c + Vector2(-38, 5), 13, ink)
		_text("E", c + Vector2(38, 5), 13, ink)
		# Hearts and stars in the corners, a few flowers.
		for p in [Vector2(40, 620), Vector2(262, 250), Vector2(40, 240)]:
			CuteArt.heart(self, p, 11.0, CRAYONS[0], true, _rng)
		for p in [Vector2(120, 612), Vector2(250, 620), Vector2(36, 330)]:
			CuteArt.star(self, p, 11.0, CRAYONS[2], true, _rng)
		# Capybaras: a big one in the margin, a little one in her yard by the swing.
		CuteArt.capybara(self, Vector2(180, 560), 30.0, true, _rng)
		for p in [Vector2(100, 565), Vector2(262, 340), Vector2(40, 500)]:
			CuteArt.flower(self, p, 11.0, CRAYONS[5], true, _rng)
		# What the map is for.
		_text("Mon coin du monde !", Vector2(150, 650), 18, CRAYONS[3], -0.02)

	# She is only seven: the world past the avenues is not hers yet.
	func _stop_sign() -> void:
		var c := Vector2(150, 420)
		var pts := []
		for k in 8:
			pts.append(c + Vector2.from_angle(TAU * (k + 0.5) / 8.0) * 22.0)
		CuteArt._shape(self, pts, Color("#D9342B"), true, _rng)
		_text("STOP", c + Vector2(0, 6), 14, Color("#FFFDF7"))
		_text("Pas le droit d'aller plus loin\ntoute seule !", c + Vector2(0, 42), 14, Color("#C0262C"), -0.02)
