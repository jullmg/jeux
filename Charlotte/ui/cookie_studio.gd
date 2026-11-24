class_name CookieStudio
extends CanvasLayer
## The cookies for Santa, with Maman at the kitchen counter (Julien: "something really better… she decorates the cookies as she
## likes, like the craft table but for cookies… extraordinary, with many steps"). Seven steps, in a window like the craft studio:
##   1. Ingrédients: the seven things of the recipe stand on the counter, she clicks each one and it goes into the bowl (flour and
##      sugar pour, the butter slides in, the egg is cracked, the molasses and the spices go in);
##   2. Mélanger: she stirs the bowl with the wooden spoon by turning the mouse round (the streaks fade, a ball of dough forms);
##   3. Étendre: she rolls the dough out by dragging the rolling pin up and down, and can throw some flour on the board;
##   4. Découper: she picks a cutter (`CookieArt.SHAPES`), turns it with the wheel and presses it into the dough (3 to `CUT_MAX`);
##   5. Cuire: tray in the oven, and she takes it out when the cookies are golden (too early: pale; too late: dark, then burnt and
##      she can bake another tray);
##   6. Décorer: every cookie, big on the board: icing pen (eight colours, three widths), pouring icing over all of it, candies
##      (`_candies`), sprinkles (`_sprinkles`), "Oups !" / "Refaire", "Au hasard", "Effacer";
##   7. Assiette: she chooses the plate and what Santa drinks; the plate is drawn with her own cookies on it and kept
##      (`Christmas.save_plate`), so it is what she carries and what lies under the tree.
## `closed({count, plate, drink})`, or `closed({})` if she gives up.

signal closed(result: Dictionary)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")
const INK := Color("#5A3A1E")
const STAGE_POS := Vector2(44, 120)
const STAGE_SIZE := Vector2(880, 520)
const SIDE_POS := Vector2(944, 120)
const SIDE_SIZE := Vector2(272, 520)
const RECIPE := ["3 tasses de farine", "1 tasse de cassonade", "½ tasse de beurre", "1 œuf", "½ tasse de mélasse", "2 c. à thé de gingembre", "1 c. à thé de cannelle"]
const POUR_COLORS := {"farine": "#FFFFFF", "cassonade": "#C98A4B", "melasse": "#3A1E0C", "gingembre": "#D09A3A", "cannelle": "#8A4A2A",
	"sucre": "#FFFFFF", "sel": "#FFFFFF", "levure": "#D9B26A", "eau": "#BFE3F7", "huile": "#E8C46A", "lait": "#FFFFFF", "bleuets": "#3E4EB0"}
const CUT_MAX := 10
const CUT_MIN := 3
const STIR_NEED := 3.0 * TAU
const BAKE_PALE := 4.5
const BAKE_OVER := 8.5
const BAKE_BURN := 12.0
const BAKE_END := 13.0
const BOWL_C := Vector2(440, 328)
const BOWL_RX := 190.0
const DOUGH_C := Vector2(440, 255)
const CUTTER_SCALE := 0.9
const VIEW_C := Vector2(440, 192)
const VIEW_S := 3.0
const ICING_WIDTHS := [["Fin", 2.0], ["Moyen", 3.8], ["Gros", 6.5]]

## How fast the oven's clock runs (tests only).
var speed := 1.0
## What is cooked (`CookieArt.RECIPES`: "biscuits", "pizza", "muffins"); `for_santa`: the Christmas cookies, whose plate is kept for the tree.
var recipe := "biscuits"
var for_santa := false
var _r: Dictionary
var _ingredients: Array
var _icings: Array
var _candies: Array
var _sprinkles: Array
var _plates: Array
var _drinks: Array
var _order: Array[int] = []

var _root: Control
var _panel: Panel
var _stage: _Stage
var _side: Control
var _banner_label: Label
var _ribbon: _Ribbon
var _btn_next: Button
var _btn_undo: Button
var _btn_redo: Button
var _btn_later: Button
var _toast_label: Label
var _gauge: _Gauge
var _count_label: Label
var _phase := 0
var _busy := false
var _time := 0.0
var _mouse := Vector2(-1, -1)
var _down := false
var _dirty := true
var _rng := RandomNumberGenerator.new()
var _grain: Array = []
# 1. Ingredients.
var _added: Array = []
var _pour_i := -1
var _pour_t := 0.0
# 2. Stirring.
var _stir_total := 0.0
var _stir_angle := 0.0
var _last_ang := 0.0
var _have_ang := false
var _spoon := Vector2.ZERO
var _stir_sound := 0.0
var _ball := 0.0
# 3. Rolling.
var _roll := 0.0
var _pin_y := 90.0
var _last_y := 0.0
var _roll_sound := 0.0
var _flour: Array = []
# 4. Cutting.
var _cuts: Array = []
var _cut_shape := 0
var _cut_rot := 0.0
var _cut_fx: Array = []
var _bump := 0.0
# 5. Baking.
var _oven := "ready"      # ready, in, baking, out
var _slide := 0.0
var _bake_t := 0.0
var _doneness := 0.0
var _burnt := false
# 6. Decorating.
var _cookies: Array = []
var _cur := 0
var _tab := "glacage"
var _tool := "stylo"
var _icing := 1
var _width := 1
var _candy := 0
var _sprinkle := 0
var _undo: Array = []
var _redo: Array = []
var _stroking := false
var _last_put := Vector2(1000, 1000)
# 7. Plate.
var _plate := 1
var _drink := 0


func _init() -> void:
	layer = 62


func _ready() -> void:
	add_to_group("modal")
	_apply_recipe()
	_rng.seed = 2026
	for i in 90:
		_grain.append([_rng.randf_range(0, STAGE_SIZE.x), _rng.randf_range(0, STAGE_SIZE.y), _rng.randf_range(14, 60), _rng.randf_range(0.04, 0.14)])
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(20, 12)
	_panel.size = Vector2(1240, 696)
	_panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(_panel)
	_ribbon = _Ribbon.new()
	_ribbon.studio = self
	_ribbon.position = Vector2(64, 8)
	_ribbon.size = Vector2(996, 48)
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_ribbon)
	var banner := _Banner.new()
	banner.position = Vector2(24, 62)
	banner.size = Vector2(1192, 50)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(banner)
	_banner_label = _label("", 22, INK)
	_banner_label.position = Vector2(66, 8)
	_banner_label.size = Vector2(1110, 34)
	_banner_label.clip_text = true
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(_banner_label)
	_stage = _Stage.new()
	_stage.studio = self
	_stage.position = STAGE_POS
	_stage.size = STAGE_SIZE
	_stage.clip_contents = true
	_panel.add_child(_stage)
	_side = Control.new()
	_side.position = SIDE_POS
	_side.size = SIDE_SIZE
	_panel.add_child(_side)
	_btn_later = _button("Plus tard", 20, func() -> void: _leave(), Vector2(150, 42))
	_btn_later.position = Vector2(24, 648)
	_panel.add_child(_btn_later)
	_btn_undo = _button("↶ Oups !", 20, _take_back, Vector2(130, 42))
	_btn_undo.position = Vector2(560, 648)
	_panel.add_child(_btn_undo)
	_btn_redo = _button("↷ Refaire", 20, _do_again, Vector2(130, 42))
	_btn_redo.position = Vector2(700, 648)
	_panel.add_child(_btn_redo)
	_btn_next = _button("Suivant →", 24, _next, Vector2(250, 44))
	_btn_next.position = Vector2(966, 646)
	_btn_next.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 4, 18))
	_panel.add_child(_btn_next)
	set_process(true)
	_goto(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _busy:
		get_viewport().set_input_as_handled()
		_leave()


# ── Steps ───────────────────────────────────────────────────

func _apply_recipe() -> void:
	_r = CookieArt.recipe(recipe)
	_ingredients = _r.ingredients
	_icings = _r.icings
	_candies = _r.candies
	_sprinkles = _r.sprinkles
	_plates = _r.plates
	_drinks = _r.drinks
	_order.assign(_r.order)


## Maman's words on screen `p` (the recipe's own, else the default ones).
func _line_for(p: int) -> String:
	var own: Array = _r.says
	if p < own.size() and str(own[p]) != "":
		return str(own[p])
	return SAYS[p]


func _dough_color() -> Color:
	return Color(str(_r.mix))


const SAYS := [
	"Salut Chachoue ! On fait des biscuits pour le père Noël. Mets tous les ingrédients dans le bol : clique dessus !",
	"Astheure, on mélange ! Tourne la cuillère en rond dans le bol, longtemps, jusqu'à ce que la pâte soit lisse.",
	"Là, on étend la pâte avec le rouleau : glisse-le de haut en bas, bien égal. Tu peux ajouter un peu de farine !",
	"Choisis un emporte-pièce pis appuie sur la pâte ! Tourne-le avec la molette de la souris. Fais-en au moins trois.",
	"Mets la plaque au four. Surveille-les bien : on les sort quand ils sont dorés, pas trop pâles, pas trop foncés !",
	"Décore-les comme tu veux : glaçage, bonbons, pépites ! Clique sur un biscuit, en bas, pour changer.",
	"Oh, qu'ils sont beaux ! Choisis l'assiette pis ce que le père Noël va boire avec ses biscuits.",
]


func _goto(p: int) -> void:
	_phase = p
	_busy = false
	_down = false
	_stroking = false
	_say(_line_for(p))
	_ribbon.queue_redraw()
	if p == 3:
		_cut_fx.clear()
	if p == 4 or p == 5:
		_ensure_food()
	_build_side()
	_refresh_buttons()
	_dirty = true


func _say(text: String) -> void:
	_banner_label.text = text
	_banner_label.modulate.a = 0.0
	create_tween().tween_property(_banner_label, "modulate:a", 1.0, 0.25)


func _can_next() -> bool:
	match _phase:
		0:
			return _added.size() >= _ingredients.size() and _pour_i < 0
		1:
			return _stir_total >= STIR_NEED
		2:
			return _roll >= 1.0
		3:
			return _cuts.size() >= CUT_MIN
		4:
			return _oven == "out" and not _burnt
		5, 6:
			return true
	return false


func _refresh_buttons() -> void:
	var labels := {1: "Mélanger →", 2: "Étendre la pâte →", 3: "Découper →", 4: "Mettre au four →", 5: "Décorer →", 6: "Sur l'assiette →"}
	var pos := _order.find(_phase)
	_btn_next.text = "Voilà, c'est prêt ! ♥" if pos >= _order.size() - 1 else str(labels[_order[pos + 1]])
	_btn_next.disabled = not _can_next() or _busy
	_btn_undo.visible = _phase == 3 or _phase == 5
	_btn_redo.visible = _phase == 5
	_btn_undo.disabled = (_cuts.is_empty() if _phase == 3 else _undo.is_empty())
	_btn_redo.disabled = _redo.is_empty()


func _next() -> void:
	if _busy:
		return
	Sfx.play("click")
	var pos := _order.find(_phase)
	if pos >= _order.size() - 1:
		_finish()
	else:
		_goto(_order[pos + 1])


var _cheered := 0

## Maman's word of encouragement at a third and at two thirds of a step.
func _cheer(k: float, lines: Array) -> void:
	var due := 1 if k >= 0.34 else 0
	if k >= 0.67:
		due = 2
	if due > _cheered and due <= lines.size():
		_cheered = due
		_say(str(lines[due - 1]))


func _step_done(text: String) -> void:
	_cheered = 0
	Sfx.play("chime")
	_say(text)
	_refresh_buttons()


# ── Sidebar ─────────────────────────────────────────────────

func _build_side() -> void:
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	_gauge = null
	_count_label = null
	match _phase:
		0, 1, 2:
			_side_recipe()
		3:
			_side_cutters()
		4:
			_side_oven()
		5:
			_side_decorate()
		6:
			_side_plate()


func _card(h: float) -> Panel:
	var p := Panel.new()
	p.size = Vector2(SIDE_SIZE.x, h)
	p.add_theme_stylebox_override("panel", _box(Color("#FFFDF7"), Color("#C8A27A"), 3, 18))
	_side.add_child(p)
	return p


func _side_recipe() -> void:
	var card := _card(SIDE_SIZE.y - 40.0)
	var t := _label("La recette", 28, BLUE)
	t.position = Vector2(0, 12)
	t.size = Vector2(SIDE_SIZE.x, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t)
	var sub := _label(str(_r.title), 18, Color(INK, 0.8))
	sub.position = Vector2(0, 50)
	sub.size = Vector2(SIDE_SIZE.x, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(sub)
	var lines: Array = _r.lines
	for i in lines.size():
		var done: bool = _phase > 0 or i in _added
		var row := _label(("✔  " if done else "○  ") + str(lines[i]), 19, Color("#2F7A45") if done else INK)
		row.position = Vector2(18, 88 + i * 32)
		card.add_child(row)
	# The steps still to come.
	var y: float = 88.0 + lines.size() * 32.0 + 14.0
	var pos := _order.find(_phase)
	for k in range(1, mini(_order.size() - pos, 4)):
		var id: int = _order[pos + k]
		var row := _label("   " + str(_r.steps[id]), 18, Color(INK, 0.5))
		row.position = Vector2(18, y + (k - 1) * 26)
		card.add_child(row)
	if pos < _order.size():
		var now := _label("► " + str(_r.steps[_phase]), 18, BLUE)
		now.position = Vector2(18, y - 26.0)
		now.visible = false
		card.add_child(now)
	if _phase == 2:
		var b := _button("Un peu de farine !", 20, _throw_flour, Vector2(236, 44))
		b.position = Vector2(18, SIDE_SIZE.y - 40.0 - 62.0)
		card.add_child(b)


func _side_cutters() -> void:
	var card := _card(SIDE_SIZE.y - 40.0)
	var t := _label("Emporte-pièces", 26, BLUE)
	t.position = Vector2(0, 8)
	t.size = Vector2(SIDE_SIZE.x, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t)
	for i in CookieArt.SHAPES.size():
		var id: String = CookieArt.SHAPES[i][0]
		var b := _IconButton.new()
		b.position = Vector2(14 + (i % 2) * 124, 48 + (i / 2) * 84)
		b.custom_minimum_size = Vector2(118, 80)
		b.size = Vector2(118, 80)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _cut_shape else Color.WHITE, BLUE, 3, 14))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 14))
		b.add_theme_stylebox_override("pressed", _box(YELLOW, BLUE, 3, 14))
		b.paint = func(ci: CanvasItem, mid: Vector2) -> void:
			CookieArt.cutter(ci, id, mid + Vector2(0, -6), 0.42, 0.0)
			ci.draw_string(ThemeDB.fallback_font, Vector2(0, mid.y * 2.0 - 8.0), CookieArt.SHAPES[i][1], HORIZONTAL_ALIGNMENT_CENTER, mid.x * 2.0, 15, BLUE)
		b.pressed.connect(func() -> void:
			_cut_shape = i
			Sfx.play("click")
			_build_side())
		card.add_child(b)
	_count_label = _label("", 20, INK)
	_count_label.position = Vector2(14, 48 + 4 * 84 + 2)
	_count_label.size = Vector2(244, 30)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_count_label)
	var left := _button("↺", 24, func() -> void: _cut_rot -= 0.26, Vector2(56, 40))
	left.position = Vector2(60, 48 + 4 * 84 + 32)
	card.add_child(left)
	var right := _button("↻", 24, func() -> void: _cut_rot += 0.26, Vector2(56, 40))
	right.position = Vector2(150, 48 + 4 * 84 + 32)
	card.add_child(right)
	_update_count()


func _update_count() -> void:
	if _count_label:
		_count_label.text = "Biscuits : %d  (%d à %d)" % [_cuts.size(), CUT_MIN, CUT_MAX]


func _side_oven() -> void:
	var card := _card(SIDE_SIZE.y - 40.0)
	var t := _label("Le four", 28, BLUE)
	t.position = Vector2(0, 12)
	t.size = Vector2(SIDE_SIZE.x, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t)
	_gauge = _Gauge.new()
	_gauge.studio = self
	_gauge.position = Vector2(14, 64)
	_gauge.size = Vector2(244, 110)
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_gauge)
	match _oven:
		"ready":
			var b := _button("Mettre au four !", 24, _put_in_oven, Vector2(236, 56))
			b.position = Vector2(18, 200)
			b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
			card.add_child(b)
			var tip := _label("La plaque est prête, avec\n%s. Clique pour\nla glisser dans le four !" % str(_r.get("raw", "les biscuits crus")), 18, INK)
			tip.position = Vector2(18, 280)
			card.add_child(tip)
		"baking":
			var b := _button("Sortir la plaque !", 24, func() -> void: _take_out(false), Vector2(236, 56))
			b.position = Vector2(18, 200)
			b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
			card.add_child(b)
			var tip := _label("Regarde par la fenêtre :\nils changent de couleur.\nSors-les quand ils sont\ndorés !", 18, INK)
			tip.position = Vector2(18, 280)
			card.add_child(tip)
		"out":
			if _burnt:
				var again := _button("Une autre fournée !", 22, _bake_again, Vector2(236, 52))
				again.position = Vector2(18, 200)
				again.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
				card.add_child(again)
				var keep := _button("Les décorer quand même", 20, func() -> void:
					_burnt = false
					_say("Ben là, avec du glaçage, personne va voir ! Décore-les.")
					_refresh_buttons(), Vector2(236, 52))
				keep.position = Vector2(18, 264)
				card.add_child(keep)
			else:
				var tip := _label("C'est sorti du four !\nOn laisse refroidir\nun peu, pis on continue.", 18, INK)
				tip.position = Vector2(18, 210)
				card.add_child(tip)


func _side_decorate() -> void:
	var card := _card(SIDE_SIZE.y - 40.0)
	var names: Array = _r.tabs
	var tabs := [["glacage", names[0]], ["bonbons", names[1]], ["pepites", names[2]]]
	for i in 3:
		var b := Button.new()
		b.text = tabs[i][1]
		b.position = Vector2(8 + i * 86, 8)
		b.custom_minimum_size = Vector2(82, 40)
		b.size = Vector2(82, 40)
		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if _tab == tabs[i][0] else Color.WHITE, BLUE, 3, 12))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 12))
		b.pressed.connect(func() -> void:
			_tab = tabs[i][0]
			_tool = "stylo" if _tab == "glacage" and _tool not in ["stylo", "napper"] else _tool
			Sfx.play("click")
			_build_side())
		card.add_child(b)
	match _tab:
		"glacage":
			var modes := [["stylo", "✎ Dessiner"], ["napper", "Napper"]]
			for i in 2:
				var b := _button(modes[i][1], 18, func() -> void:
					_tool = modes[i][0]
					Sfx.play("click")
					_build_side(), Vector2(120, 40))
				b.position = Vector2(10 + i * 126, 58)
				b.add_theme_stylebox_override("normal", _box(YELLOW if _tool == modes[i][0] else Color.WHITE, BLUE, 3, 12))
				card.add_child(b)
			for i in _icings.size():
				var sw := Button.new()
				sw.position = Vector2(14 + (i % 4) * 62, 114 + (i / 4) * 62)
				sw.custom_minimum_size = Vector2(54, 54)
				sw.size = Vector2(54, 54)
				var col := Color(_icings[i][1])
				sw.add_theme_stylebox_override("normal", _box(col, BLUE if i == _icing else col.darkened(0.35), 5 if i == _icing else 2, 27))
				sw.add_theme_stylebox_override("hover", _box(col.lightened(0.1), BLUE, 4, 27))
				sw.pressed.connect(func() -> void:
					_icing = i
					Sfx.play("click")
					_build_side())
				card.add_child(sw)
			if _tool == "stylo":
				for i in 3:
					var wb := _IconButton.new()
					wb.position = Vector2(14 + i * 82, 246)
					wb.custom_minimum_size = Vector2(76, 56)
					wb.size = Vector2(76, 56)
					wb.add_theme_stylebox_override("normal", _box(YELLOW if i == _width else Color.WHITE, BLUE, 3, 12))
					wb.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 12))
					wb.paint = func(ci: CanvasItem, mid: Vector2) -> void:
						ci.draw_line(Vector2(14, mid.y - 6), Vector2(mid.x * 2.0 - 14, mid.y - 6), Color(_icings[_icing][1]), float(ICING_WIDTHS[i][1]) * 1.4)
						ci.draw_string(ThemeDB.fallback_font, Vector2(0, mid.y * 2.0 - 8.0), ICING_WIDTHS[i][0], HORIZONTAL_ALIGNMENT_CENTER, mid.x * 2.0, 14, BLUE)
					wb.pressed.connect(func() -> void:
						_width = i
						Sfx.play("click")
						_build_side())
					card.add_child(wb)
				var tip := _label("Appuie et glisse dessus\npour écrire avec le glaçage.", 16, INK)
				tip.position = Vector2(14, 318)
				card.add_child(tip)
			else:
				var tip := _label("Un clic et tout est\ncouvert d'un coup.\nAjoute des lignes dessus\nensuite !", 16, INK)
				tip.position = Vector2(14, 250)
				card.add_child(tip)
		"bonbons":
			for i in _candies.size():
				var id: String = _candies[i][0]
				var b := _IconButton.new()
				b.position = Vector2(8 + (i % 3) * 88, 58 + (i / 3) * 78)
				b.custom_minimum_size = Vector2(84, 74)
				b.size = Vector2(84, 74)
				b.add_theme_stylebox_override("normal", _box(YELLOW if i == _candy else Color.WHITE, BLUE, 3, 12))
				b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 12))
				b.paint = func(ci: CanvasItem, mid: Vector2) -> void:
					CookieArt.candy_icon(ci, id, mid + Vector2(0, -8), 36.0, Color(CookieArt.CANDY_COLORS[i % CookieArt.CANDY_COLORS.size()]))
					ci.draw_string(ThemeDB.fallback_font, Vector2(0, mid.y * 2.0 - 5.0), _candies[i][1], HORIZONTAL_ALIGNMENT_CENTER, mid.x * 2.0, 11, BLUE)
				b.pressed.connect(func() -> void:
					_candy = i
					Sfx.play("click")
					_build_side())
				card.add_child(b)
			var tip := _label("Clique pour en poser un,\nou glisse pour en faire\nune rangée.", 16, INK)
			tip.position = Vector2(14, 58 + 4 * 78 + 6)
			card.add_child(tip)
		"pepites":
			for i in _sprinkles.size():
				var id: String = _sprinkles[i][0]
				var b := _IconButton.new()
				b.position = Vector2(8 + (i % 2) * 130, 58 + (i / 2) * 78)
				b.custom_minimum_size = Vector2(124, 72)
				b.size = Vector2(124, 72)
				b.add_theme_stylebox_override("normal", _box(YELLOW if i == _sprinkle else Color("#6E4A32") if id == "glace" else Color.WHITE, BLUE, 3, 12))
				b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 12))
				b.paint = func(ci: CanvasItem, mid: Vector2) -> void:
					var r := RandomNumberGenerator.new()
					r.seed = 7 + i
					ci.draw_set_transform(mid + Vector2(0, -8), 0.0, Vector2.ONE * 3.2)
					for k in 14:
						var bit := {"p": Vector2(r.randf_range(-12, 12), r.randf_range(-5, 5)) , "rot": r.randf() * TAU, "c": CookieArt.bit_color(id, r)}
						CookieArt.draw_bit(ci, id, bit)
					ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					ci.draw_string(ThemeDB.fallback_font, Vector2(0, mid.y * 2.0 - 5.0), _sprinkles[i][1], HORIZONTAL_ALIGNMENT_CENTER, mid.x * 2.0, 13, BLUE if id != "glace" else Color.WHITE)
				b.pressed.connect(func() -> void:
					_sprinkle = i
					Sfx.play("click")
					_build_side())
				card.add_child(b)
			var tip := _label("Appuie et bouge sur le\nplat pour saupoudrer.", 16, INK)
			tip.position = Vector2(14, 58 + 4 * 78 + 6)
			card.add_child(tip)
	var rnd := _button("✨ Au hasard", 17, _decorate_randomly, Vector2(122, 40))
	rnd.position = Vector2(8, SIDE_SIZE.y - 40.0 - 52.0)
	card.add_child(rnd)
	var clear := _button("Tout effacer", 17, _clear_current, Vector2(122, 40))
	clear.position = Vector2(140, SIDE_SIZE.y - 40.0 - 52.0)
	card.add_child(clear)


func _side_plate() -> void:
	var card := _card(SIDE_SIZE.y - 40.0)
	var t := _label("L'assiette", 26, BLUE)
	t.position = Vector2(0, 10)
	t.size = Vector2(SIDE_SIZE.x, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t)
	for i in _plates.size():
		var b := _button(_plates[i][1], 18, func() -> void:
			_plate = i
			Sfx.play("click")
			_build_side()
			_dirty = true, Vector2(244, 42))
		b.position = Vector2(14, 52 + i * 48)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _plate else Color.WHITE, BLUE, 3, 12))
		card.add_child(b)
	var t2 := _label("Pour boire", 26, BLUE)
	t2.position = Vector2(0, 210)
	t2.size = Vector2(SIDE_SIZE.x, 36)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t2)
	for i in _drinks.size():
		var b := _button(_drinks[i][1], 18, func() -> void:
			_drink = i
			Sfx.play("click")
			_build_side()
			_dirty = true, Vector2(244, 42))
		b.position = Vector2(14, 252 + i * 48)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _drink else Color.WHITE, BLUE, 3, 12))
		card.add_child(b)
	var tip := _label("Le père Noël en a pour\ntoute la nuit !" if for_santa else "Bon appétit,\nà vous deux !", 17, INK)
	tip.position = Vector2(14, 410)
	card.add_child(tip)


# ── Step 1: the ingredients ─────────────────────────────────

func _item_pos(i: int) -> Vector2:
	return Vector2(440.0 + (i - (_ingredients.size() - 1) / 2.0) * 122.0, 178.0)


func _click_ingredient(p: Vector2) -> void:
	if _pour_i >= 0:
		return
	for i in _ingredients.size():
		if i in _added:
			continue
		var at := _item_pos(i)
		if Rect2(at.x - 50.0, at.y - 130.0, 100.0, 150.0).has_point(p):
			_pour_i = i
			_pour_t = 0.0
			_say(str(_ingredients[i][2]))
			Sfx.play("swoosh")
			var tw := create_tween()
			tw.tween_property(self, "_pour_t", 1.0, 1.9)
			if _ingredients[i][0] == "oeuf":
				# The shell cracks on the bowl's rim: a tap, then the plop.
				get_tree().create_timer(0.86).timeout.connect(func() -> void: Sfx.play("click", Vector2.INF, -4.0, 1.5))
				get_tree().create_timer(1.35).timeout.connect(func() -> void: Sfx.play("pop", Vector2.INF, -6.0, 0.8))
			tw.tween_callback(func() -> void:
				_added.append(i)
				_pour_i = -1
				Sfx.play("pop")
				_build_side()
				if _added.size() >= _ingredients.size():
					_step_done("Tout est dans le bol ! Parfait. Astheure, on mélange.")
				_refresh_buttons())
			return


# ── Step 2: stirring ────────────────────────────────────────

func _stir_move(p: Vector2) -> void:
	var c := BOWL_C + Vector2(0, 3)
	var rel := p - c
	rel.y /= 0.55
	var d := rel.length()
	_spoon = c + Vector2(clampf(rel.x, -BOWL_RX * 0.85, BOWL_RX * 0.85), clampf(rel.y, -BOWL_RX * 0.85, BOWL_RX * 0.85) * 0.55)
	if d > 36.0 and d < BOWL_RX * 1.05:
		var ang := rel.angle()
		if _have_ang:
			var da := angle_difference(_last_ang, ang)
			if absf(da) < 1.2:
				_stir_angle += da
				if _stir_total < STIR_NEED:
					_stir_total = minf(STIR_NEED, _stir_total + absf(da))
					_stir_sound += absf(da)
					_cheer(_stir_total / STIR_NEED, ["Oui, comme ça ! Tourne encore, tu y es presque.", "La pâte devient toute lisse, continue !"])
					if _stir_sound > 1.6:
						_stir_sound = 0.0
						Sfx.play("swoosh", Vector2.INF, -12.0, randf_range(0.8, 1.1))
					if _stir_total >= STIR_NEED:
						_ball = 0.0
						create_tween().tween_property(self, "_ball", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						_step_done("Voilà, la pâte est bien lisse ! On l'étend.")
		_last_ang = ang
		_have_ang = true
	else:
		_have_ang = false


# ── Step 3: rolling ─────────────────────────────────────────

func _roll_move(p: Vector2) -> void:
	var y := clampf(p.y, 70.0, 470.0)
	var dy := absf(y - _pin_y)
	if _roll < 1.0 and absf(_pin_y - DOUGH_C.y) < lerpf(66.0, 168.0, _roll) + 24.0:
		_roll = minf(1.0, _roll + dy / 1250.0)
		_roll_sound += dy
		_cheer(_roll, ["Bien égal ! Un peu plus mince encore.", "Presque ! Il reste les bords."])
		if _roll_sound > 150.0:
			_roll_sound = 0.0
			Sfx.play("swoosh", Vector2.INF, -10.0, 0.7)
		if _roll >= 1.0:
			_step_done("Parfait, la pâte est belle et égale ! On découpe.")
	_pin_y = y


func _throw_flour() -> void:
	Sfx.play("swoosh", Vector2.INF, -8.0, 1.3)
	var r := RandomNumberGenerator.new()
	r.randomize()
	var c := Vector2(r.randf_range(200, 680), r.randf_range(110, 420))
	for i in 60:
		_flour.append([c + Vector2(r.randfn(0, 60), r.randfn(0, 40)), r.randf_range(0.8, 2.2), r.randf_range(0.3, 0.8)])
	while _flour.size() > 600:
		_flour.pop_front()
	_dirty = true


func _dough_poly(k: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var fin: Array = _r.dough
	var a := lerpf(66.0, float(fin[0]), k)
	var b := lerpf(66.0, float(fin[1]), k)
	var n := lerpf(2.0, float(fin[2]), k)
	for i in 72:
		var t := TAU * i / 72.0
		var cs := cos(t)
		var sn := sin(t)
		var x := a * signf(cs) * pow(absf(cs), 2.0 / n)
		var y := b * signf(sn) * pow(absf(sn), 2.0 / n)
		var wob := 1.0 + 0.012 * sin(t * 5.0 + 1.0) + 0.009 * sin(t * 9.0)
		pts.append(DOUGH_C + Vector2(x, y) * wob)
	return pts


# ── Step 4: cutting ─────────────────────────────────────────

func _cut_ok(p: Vector2, id: String, rot: float) -> bool:
	if _cuts.size() >= CUT_MAX:
		return false
	var dough := _dough_poly(1.0)
	for v in CookieArt.shape(id):
		var q := p + v.rotated(rot) * CUTTER_SCALE
		if not Geometry2D.is_point_in_polygon(q, dough):
			return false
	for c: Dictionary in _cuts:
		if p.distance_to(c.p) < (float(CookieArt.RADIUS[id]) + float(CookieArt.RADIUS[c.shape])) * CUTTER_SCALE * 0.84:
			return false
	return true


func _try_cut(p: Vector2) -> void:
	var id: String = CookieArt.SHAPES[_cut_shape][0]
	if _cut_ok(p, id, _cut_rot):
		_cuts.append({"shape": id, "p": p, "rot": _cut_rot, "seed": _rng.randi()})
		_cut_fx.append({"shape": id, "p": p, "rot": _cut_rot, "t": 0.0})
		Sfx.play("pop", Vector2.INF, -4.0, randf_range(0.9, 1.15))
		_update_count()
		if _cuts.size() == CUT_MIN:
			_say("Trois biscuits, c'est déjà bien ! Mais on peut en faire jusqu'à dix.")
		elif _cuts.size() == CUT_MAX:
			_say("La pâte est pleine ! On les met au four ?")
		_refresh_buttons()
	else:
		_bump = 0.35
		Sfx.play("click", Vector2.INF, -6.0, 0.6)
		if _cuts.size() >= CUT_MAX:
			_toast("Il y en a assez !")
		else:
			_toast("Pas ici : ça dépasse ou ça touche un autre biscuit.")


func _toast(text: String) -> void:
	if _toast_label:
		_toast_label.queue_free()
	_toast_label = _label(text, 20, Color.WHITE)
	_toast_label.add_theme_stylebox_override("normal", _box(Color(0.2, 0.1, 0.05, 0.85), Color(0, 0, 0, 0), 0, 14))
	_toast_label.position = Vector2(STAGE_POS.x + 220, STAGE_POS.y + STAGE_SIZE.y - 44)
	_toast_label.z_index = 10
	_panel.add_child(_toast_label)
	var lab := _toast_label
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lab):
			lab.queue_free())


# ── Step 5: the oven ────────────────────────────────────────

## What is on the tray: the cut-outs (cookies), or the one pizza, or six muffins.
func _ensure_food() -> void:
	if not _cookies.is_empty():
		return
	var shape := str(_r.shape)
	if shape == "":
		for c: Dictionary in _cuts:
			_cookies.append({"shape": c.shape, "rot": 0.0, "seed": c.seed, "doneness": 0.0, "ops": []})
	else:
		var count := 1 if (shape == "pizza" or shape == "gateau") else (8 if shape == "cookie" else 6)
		for i in count:
			_cookies.append({"shape": shape, "rot": 0.0, "seed": _rng.randi(), "doneness": 0.0, "ops": []})
	_oven = "ready"
	_slide = 0.0
	_bake_t = 0.0
	_burnt = false


func _tray_slot(i: int, n: int) -> Vector3:
	if n == 1:
		return Vector3(440.0, 440.0, 1.35)
	var rows := 1 if n <= 5 else 2
	var per := int(ceil(float(n) / rows))
	var row := i / per
	var col := i % per
	var cnt := mini(per, n - row * per)
	var x := 440.0 + (col - (cnt - 1) / 2.0) * (118.0 if rows == 1 else 112.0)
	if rows == 1:
		return Vector3(x, 438.0, 0.72)
	return Vector3(x, 412.0 + row * 62.0, 0.52)


func _put_in_oven() -> void:
	if _busy:
		return
	_oven = "in"
	_busy = true
	Sfx.play("swoosh")
	_say("Hop, dans le four ! J'ai réglé le minuteur.")
	var tw := create_tween()
	tw.tween_property(self, "_slide", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_oven = "baking"
		_busy = false
		_bake_t = 0.0
		Sfx.play("click")
		_say("Ça sent bon ! Surveille-les par la fenêtre du four.")
		_build_side()
		_refresh_buttons())
	_build_side()


func _take_out(too_late: bool) -> void:
	if _oven != "baking":
		return
	_oven = "out"
	var t := _bake_t
	_doneness = clampf(t / BAKE_END, 0.0, 1.0)
	for ck: Dictionary in _cookies:
		ck.doneness = clampf(_doneness + _rng.randf_range(-0.025, 0.025), 0.0, 1.0)
	_burnt = t >= BAKE_BURN
	var tw := create_tween()
	_slide = 1.0
	tw.tween_property(self, "_slide", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	Sfx.play("bell" if not too_late else "squeak")
	if _burnt:
		_say("Oh non, c'est brûlé ! Ça arrive à tout le monde… On en refait un ?")
	elif t < BAKE_PALE:
		_say("Un peu pâle, mais ça va être bien tendre !")
	elif t < BAKE_OVER:
		_say("Parfait, bien doré ! Tu es une vraie cuisinière.")
	else:
		_say("Un peu foncé, comme j'aime ça ! Ça va être bon pareil.")
	_build_side()
	_refresh_buttons()


func _bake_again() -> void:
	_burnt = false
	if str(_r.shape) == "":
		_cookies.clear()
		_cuts.clear()
		_cut_fx.clear()
		_oven = "ready"
		_goto(3)
		_say("Une autre fournée ! On a assez de pâte, découpe-en encore.")
		return
	# Pizza and muffins: the same food, raw again, back in the oven.
	for ck: Dictionary in _cookies:
		ck.doneness = 0.0
	_oven = "ready"
	_slide = 0.0
	_bake_t = 0.0
	_goto(4)
	_say("On recommence ! Cette fois, surveille-le bien.")


func _bake_color(t: float) -> float:
	return clampf(t / BAKE_END, 0.0, 1.0)


# ── Step 6: decorating ──────────────────────────────────────

func _cookie() -> Dictionary:
	return _cookies[clampi(_cur, 0, _cookies.size() - 1)]


func _thumb_rect(i: int) -> Rect2:
	var n := _cookies.size()
	var w := 84.0
	var x0 := (STAGE_SIZE.x - n * w) / 2.0
	return Rect2(x0 + i * w, 408.0, w - 6.0, 104.0)


func _to_local(p: Vector2) -> Vector2:
	return (p - VIEW_C) / VIEW_S


func _inside(q: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(q, CookieArt.inset(str(_cookie().shape), 1.0))


func _add_op(op: Dictionary) -> void:
	_cookie().ops.append(op)
	_undo.append(_cur)
	_redo.clear()
	_dirty = true
	_refresh_buttons()


func _deco_press(p: Vector2) -> void:
	for i in _cookies.size():
		if _thumb_rect(i).has_point(p):
			_cur = i
			Sfx.play("click")
			_dirty = true
			return
	var q := _to_local(p)
	_stroking = false
	_last_put = Vector2(1000, 1000)
	if not _inside(q):
		return
	match _tab:
		"glacage":
			if _tool == "napper":
				_add_op({"t": "flood", "c": Color(_icings[_icing][1])})
				Sfx.play("swoosh", Vector2.INF, -6.0, 1.4)
			else:
				_add_op({"t": "line", "c": Color(_icings[_icing][1]), "w": float(ICING_WIDTHS[_width][1]), "pts": PackedVector2Array([q])})
				_stroking = true
				Sfx.play("pop", Vector2.INF, -10.0, 1.3)
		"bonbons":
			_put_candy(q)
		"pepites":
			var kind: String = _sprinkles[_sprinkle][0]
			_add_op({"t": "bits", "kind": kind, "bits": []})
			_stroking = true
			_shake(q)


func _deco_drag(p: Vector2) -> void:
	if not _down or _cookies.is_empty():
		return
	var q := _to_local(p)
	match _tab:
		"glacage":
			if _tool != "stylo":
				return
			var op: Dictionary = _cookie().ops.back() if not _cookie().ops.is_empty() else {}
			if not _inside(q):
				_stroking = false
				return
			if not _stroking or op.get("t", "") != "line":
				_add_op({"t": "line", "c": Color(_icings[_icing][1]), "w": float(ICING_WIDTHS[_width][1]), "pts": PackedVector2Array([q])})
				_stroking = true
				return
			var pts: PackedVector2Array = op.pts
			if pts[pts.size() - 1].distance_to(q) >= 1.1:
				pts.append(q)
				op.pts = pts
		"bonbons":
			if _inside(q) and q.distance_to(_last_put) >= 11.0:
				_put_candy(q)
		"pepites":
			if _stroking and _inside(q):
				_shake(q)


func _put_candy(q: Vector2) -> void:
	var id: String = _candies[_candy][0]
	var c := Color(CookieArt.CANDY_COLORS[_rng.randi() % CookieArt.CANDY_COLORS.size()])
	_add_op({"t": "candy", "id": id, "p": q, "rot": _rng.randf() * TAU, "c": c})
	_last_put = q
	Sfx.play("pop", Vector2.INF, -8.0, randf_range(1.1, 1.5))


func _shake(q: Vector2) -> void:
	var ops: Array = _cookie().ops
	if ops.is_empty() or ops.back().t != "bits":
		return
	var op: Dictionary = ops.back()
	var kind: String = op.kind
	var spread := 14.0 if kind == "glace" else 9.0
	var count := 12 if kind == "glace" else (7 if kind == "sucre" else 4)
	for i in count:
		var b := q + Vector2(_rng.randfn(0.0, spread * 0.5), _rng.randfn(0.0, spread * 0.5))
		if _inside(b):
			op.bits.append({"p": b, "rot": _rng.randf() * TAU, "c": CookieArt.bit_color(kind, _rng)})
	if _rng.randf() < 0.3:
		Sfx.play("click", Vector2.INF, -18.0, _rng.randf_range(1.6, 2.2))
	_dirty = true


func _decorate_randomly() -> void:
	var ck := _cookie()
	var id: String = ck.shape
	Sfx.play("chime")
	var base := _rng.randi() % 3
	if base != 0:
		_add_op({"t": "flood", "c": Color(_icings[_rng.randi() % _icings.size()][1])})
	var col := Color(_icings[_rng.randi() % _icings.size()][1])
	var poly := CookieArt.inset(id, 9.0)
	var pts := PackedVector2Array()
	var n := 36
	for i in n + 1:
		var a := TAU * i / n
		var q := Vector2(cos(a), sin(a)) * 30.0
		pts.append(q)
	var ring := PackedVector2Array()
	for v in poly:
		ring.append(v)
	if ring.size() > 2:
		ring.append(ring[0])
		_add_op({"t": "line", "c": col, "w": 2.6, "pts": ring})
	var kinds: Array = []
	for cd: Array in _candies:
		kinds.append(cd[0])
	for i in 6 + _rng.randi() % 5:
		var q := Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-36, 36))
		if Geometry2D.is_point_in_polygon(q, CookieArt.inset(id, 8.0)):
			_add_op({"t": "candy", "id": kinds[_rng.randi() % kinds.size()], "p": q, "rot": _rng.randf() * TAU, "c": Color(CookieArt.CANDY_COLORS[_rng.randi() % 7])})
	var kind: String = _sprinkles[_rng.randi() % mini(4, _sprinkles.size())][0]
	var bits: Array = []
	for i in 30:
		var b := Vector2(_rng.randf_range(-36, 36), _rng.randf_range(-40, 40))
		if Geometry2D.is_point_in_polygon(b, CookieArt.inset(id, 6.0)):
			bits.append({"p": b, "rot": _rng.randf() * TAU, "c": CookieArt.bit_color(kind, _rng)})
	_add_op({"t": "bits", "kind": kind, "bits": bits})


func _clear_current() -> void:
	if _cookies.is_empty() or _cookie().ops.is_empty():
		return
	var n: int = _cookie().ops.size()
	for i in n:
		_take_back()
	Sfx.play("swoosh", Vector2.INF, -6.0, 0.8)


func _take_back() -> void:
	if _phase == 3:
		if not _cuts.is_empty():
			_cuts.pop_back()
			_update_count()
			Sfx.play("click", Vector2.INF, -4.0, 0.8)
			_refresh_buttons()
		return
	if _undo.is_empty():
		return
	var idx: int = _undo.pop_back()
	var op: Dictionary = _cookies[idx].ops.pop_back()
	_redo.append([idx, op])
	_cur = idx
	_dirty = true
	Sfx.play("click", Vector2.INF, -4.0, 0.8)
	_refresh_buttons()


func _do_again() -> void:
	if _redo.is_empty():
		return
	var e: Array = _redo.pop_back()
	_cookies[e[0]].ops.append(e[1])
	_undo.append(e[0])
	_cur = e[0]
	_dirty = true
	Sfx.play("click", Vector2.INF, -4.0, 1.1)
	_refresh_buttons()


# ── Stage input ─────────────────────────────────────────────

func stage_input(event: InputEvent) -> void:
	if _busy and _phase != 4:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
		_dirty = true
		match _phase:
			1:
				if _down:
					_stir_move(_mouse)
			2:
				if _down:
					_roll_move(_mouse)
			5:
				_deco_drag(_mouse)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		_mouse = mb.position
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_down = mb.pressed
			if mb.pressed:
				match _phase:
					0:
						_click_ingredient(_mouse)
					1:
						_have_ang = false
						_stir_move(_mouse)
					2:
						_last_y = _mouse.y
						_roll_move(_mouse)
					3:
						_try_cut(_mouse)
					5:
						_deco_press(_mouse)
			else:
				_stroking = false
				_have_ang = false
		elif mb.pressed and _phase == 3 and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_cut_rot += 0.26 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -0.26
		_dirty = true


func _process(delta: float) -> void:
	_time += delta
	if _phase == 4 and _oven == "baking":
		_bake_t += delta * speed
		if _gauge:
			_gauge.queue_redraw()
		if _bake_t >= BAKE_END:
			_take_out(true)
	for fx: Dictionary in _cut_fx:
		fx.t += delta
	_cut_fx = _cut_fx.filter(func(f: Dictionary) -> bool: return f.t < 0.5)
	_bump = maxf(0.0, _bump - delta)
	if _phase != 5 or _dirty:
		_stage.queue_redraw()
		_dirty = false
	if _phase == 4 and _gauge:
		_gauge.queue_redraw()


# ── Painting the stage ──────────────────────────────────────

func paint(ci: CanvasItem) -> void:
	match _phase:
		0:
			_paint_counter(ci)
			_paint_ingredients(ci)
		1:
			_paint_counter(ci)
			_paint_stirring(ci)
		2, 3:
			_paint_counter(ci)
			_paint_board(ci)
		4:
			_paint_counter(ci)
			_paint_oven(ci)
		5:
			_paint_counter(ci)
			_paint_decorating(ci)
		6:
			_paint_counter(ci)
			_paint_plate(ci)


func _paint_counter(ci: CanvasItem) -> void:
	var tone := Color("#E3C592")
	ci.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), tone)
	for i in 6:
		ci.draw_line(Vector2(0, i * 90.0 + 40), Vector2(STAGE_SIZE.x, i * 90.0 + 40), tone.darkened(0.1), 2.0)
	for g: Array in _grain:
		ci.draw_line(Vector2(g[0], g[1]), Vector2(g[0] + g[2], g[1] + 1.0), Color(0.45, 0.28, 0.1, g[3]), 1.5)
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(STAGE_SIZE.x, 0), Vector2(STAGE_SIZE.x, 40), Vector2(0, 40)]),
		PackedColorArray([Color(0.3, 0.18, 0.05, 0.28), Color(0.3, 0.18, 0.05, 0.28), Color(0.3, 0.18, 0.05, 0.0), Color(0.3, 0.18, 0.05, 0.0)]))


func _text(ci: CanvasItem, s: String, at: Vector2, size: int, color: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(ThemeDB.fallback_font, at, s, align, width, size, color)


func _bar(ci: CanvasItem, at: Vector2, w: float, k: float) -> void:
	var r := Rect2(at, Vector2(w, 18))
	ci.draw_rect(r, Color(1, 1, 1, 0.7))
	ci.draw_rect(Rect2(at, Vector2(w * clampf(k, 0, 1), 18)), Color("#5BB85D"))
	ci.draw_rect(r, BLUE, false, 2.0)


# Step 1.
func _paint_ingredients(ci: CanvasItem) -> void:
	CookieArt.bowl(ci, BOWL_C, BOWL_RX)
	_paint_bowl_contents(ci)
	for i in _ingredients.size():
		var at := _item_pos(i)
		var added := i in _added
		var hot := not added and _pour_i < 0 and Rect2(at.x - 50.0, at.y - 130.0, 100.0, 150.0).has_point(_mouse)
		if i == _pour_i:
			continue
		if added:
			ci.draw_arc(at + Vector2(0, -50), 38.0, 0.0, TAU, 28, Color(INK, 0.25), 2.0, true)
			_text(ci, "✔", at + Vector2(-14, -36), 40, Color("#2F7A45"))
			continue
		ci.draw_colored_polygon(CookieArt._ellipse(at + Vector2(0, 6), 42.0, 9.0), Color(0, 0, 0, 0.16))
		CookieArt.ingredient(ci, _ingredients[i][0], at + Vector2(0, -4.0 if hot else 0.0), 1.2 if hot else 1.12)
		_text(ci, _ingredients[i][1], at + Vector2(-60, 40), 18, INK if not hot else BLUE, 120.0, HORIZONTAL_ALIGNMENT_CENTER)
	if _pour_i >= 0:
		_paint_pour(ci)
	if _added.is_empty() and _pour_i < 0:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		_text(ci, "Clique sur un ingrédient !", Vector2(0, 270), 26, Color(BLUE, 0.6 + 0.4 * pulse), STAGE_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)


func _paint_pour(ci: CanvasItem) -> void:
	var id: String = _ingredients[_pour_i][0]
	var home := _item_pos(_pour_i)
	var t := _pour_t
	var over := Vector2(BOWL_C.x + 70.0, 175.0)
	var move := smoothstep(0.0, 0.28, t) * (1.0 - smoothstep(0.86, 1.0, t))
	var pos := home.lerp(over, move)
	var s := 1.15
	var tilt := 0.0
	if POUR_COLORS.has(id):
		tilt = -1.15 * smoothstep(0.25, 0.4, t) * (1.0 - smoothstep(0.78, 0.9, t))
	match id:
		"oeuf":
			if t < 0.45:
				CookieArt.ingredient(ci, id, pos, s, -0.5 * smoothstep(0.25, 0.45, t))
			else:
				var open := smoothstep(0.45, 0.6, t)
				var mid := pos + Vector2(0, -40)
				for side in [-1.0, 1.0]:
					ci.draw_set_transform(mid + Vector2(side * 14.0 * open, -4.0 * open), side * 0.7 * open, Vector2.ONE)
					var shell := PackedVector2Array()
					for k in 15:
						var a := PI * k / 14.0 + (0.0 if side < 0.0 else PI)
						shell.append(Vector2(cos(a) * 20.0, sin(a) * 26.0 * (1 if side > 0 else 1)))
					ci.draw_colored_polygon(shell, Color("#F3E3C8"))
					ci.draw_polyline(shell, Color("#C4A878"), 1.4, true)
					ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var fall := smoothstep(0.5, 0.78, t)
				if fall < 1.0:
					var yp := lerpf(mid.y, BOWL_C.y - 4.0, fall)
					ci.draw_colored_polygon(CookieArt._ellipse(Vector2(mid.x, yp), 15.0, 17.0 + 10.0 * fall), Color("#FFF8F0"))
					ci.draw_circle(Vector2(mid.x, yp), 10.0, Color("#F5A623"))
					ci.draw_circle(Vector2(mid.x - 3, yp - 3), 3.0, Color(1, 1, 1, 0.6))
		"beurre":
			var slide := smoothstep(0.45, 0.8, t)
			CookieArt.ingredient(ci, id, pos.lerp(Vector2(pos.x, BOWL_C.y + 6.0), slide), lerpf(s, s * 0.55, slide), 0.35 * smoothstep(0.3, 0.5, t))
		_:
			CookieArt.ingredient(ci, id, pos, s, tilt)
			if t > 0.36 and t < 0.84:
				var mid2 := pos + Vector2(0, -50.0 * s)
				var mouth := mid2 + Vector2(0, -50.0 * s).rotated(tilt)
				var col := Color(str(POUR_COLORS.get(id, "#FFFFFF")))
				for k in 14:
					var ph := fposmod(_time * 2.6 + k / 14.0, 1.0)
					var q := mouth + Vector2(sin(k * 3.1) * 5.0 + ph * 4.0, ph * (BOWL_C.y - mouth.y))
					ci.draw_circle(q, 2.8 if id in ["farine", "cassonade", "melasse", "sucre", "eau", "lait", "huile", "bleuets"] else 1.8, col)
	if t > 0.7 and id == "farine":
		ci.draw_circle(BOWL_C + Vector2(0, -8), 60.0 * (1.0 - t) * 3.0, Color(1, 1, 1, 0.18 * (1.0 - t) * 3.0))


func _paint_bowl_contents(ci: CanvasItem) -> void:
	var c := BOWL_C + Vector2(0, 3)
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
	var r := BOWL_RX * 0.9
	var blob_rng := RandomNumberGenerator.new()
	for j in _added.size():
		var id: String = _ingredients[_added[j]][0]
		blob_rng.seed = 100 + _added[j]
		var a := j * 2.4
		var p := Vector2(cos(a), sin(a)) * r * blob_rng.randf_range(0.18, 0.5)
		match id:
			"farine":
				ci.draw_circle(p, r * 0.52, Color("#F8F4EA"))
				ci.draw_circle(p + Vector2(-8, -6), r * 0.42, Color("#FFFFFF"))
			"cassonade":
				ci.draw_circle(p, r * 0.34, Color("#C99A5F"))
				ci.draw_circle(p + Vector2(-6, -4), r * 0.26, Color("#D9AE72"))
			"beurre":
				ci.draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 44)), Color("#FFE680"))
				ci.draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 14)), Color("#FFF2A8"))
			"oeuf":
				ci.draw_circle(p, r * 0.26, Color("#FFF8F0"))
				ci.draw_circle(p, r * 0.15, Color("#F5A623"))
				ci.draw_circle(p + Vector2(-5, -5), 5.0, Color(1, 1, 1, 0.6))
			"melasse":
				ci.draw_circle(p, r * 0.3, Color("#3A1E0C"))
				ci.draw_circle(p + Vector2(-8, -6), 10.0, Color(1, 1, 1, 0.2))
			"gingembre", "cannelle":
				var col := Color("#C98A2E") if id == "gingembre" else Color("#8A4A2A")
				for k in 36:
					ci.draw_circle(Vector2(blob_rng.randfn(0, r * 0.4), blob_rng.randfn(0, r * 0.4)), blob_rng.randf_range(1.5, 3.5), col)
			"bleuets":
				for k in 14:
					ci.draw_circle(Vector2(blob_rng.randfn(0, r * 0.3), blob_rng.randfn(0, r * 0.3)), 6.0, Color("#3A4A9A"))
			_:
				ci.draw_circle(p, r * 0.3, Color(str(POUR_COLORS.get(id, "#E8E0C8")), 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Step 2.
func _paint_stirring(ci: CanvasItem) -> void:
	CookieArt.bowl(ci, BOWL_C, BOWL_RX)
	var prog := clampf(_stir_total / STIR_NEED, 0.0, 1.0)
	var c := BOWL_C + Vector2(0, 3)
	var r := BOWL_RX * 0.9
	var dough := _dough_color().darkened(0.08)
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
	ci.draw_circle(Vector2.ZERO, r, Color("#EFE6D2").lerp(dough, smoothstep(0.0, 0.85, prog)))
	var streaks := [Color("#FFFFFF"), Color("#C99A5F"), Color("#FFE680"), Color("#3A1E0C"), Color("#F5A623"), Color("#FFFFFF"), Color("#6A3A1A")]
	for k in streaks.size():
		var a0 := _stir_angle + k * 0.9
		var col: Color = streaks[k]
		ci.draw_arc(Vector2.ZERO, r * (0.2 + k * 0.1), a0, a0 + 1.7 + 0.2 * k, 24, Color(col, 0.9 * (1.0 - prog)), 14.0 * (1.0 - prog * 0.5), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for k in 80:
		var q := Vector2(rng.randfn(0, r * 0.4), rng.randfn(0, r * 0.4))
		ci.draw_circle(q.rotated(_stir_angle * 0.3 * (1.0 - prog)), rng.randf_range(1.0, 2.6), Color("#7A4A24", 0.5 * prog))
	if prog >= 1.0:
		var ball := 74.0 * _ball
		ci.draw_circle(Vector2(0, 6), ball, Color("#9C7242"))
		ci.draw_circle(Vector2(0, 0), ball * 0.95, dough)
		ci.draw_circle(Vector2(-ball * 0.25, -ball * 0.3), ball * 0.45, dough.lightened(0.14))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tip := _spoon if _down or _have_ang else BOWL_C + Vector2(46, -2)
	if _mouse.x >= 0.0 and _down:
		tip = _spoon
	if prog < 1.0:
		CookieArt.spoon(ci, tip + Vector2(0, -4), -1.0)
	else:
		CookieArt.spoon(ci, BOWL_C + Vector2(150, 10), -0.25)
	if prog < 0.05:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		ci.draw_arc(BOWL_C + Vector2(0, -4), 120.0, 3.4, 6.0, 24, Color(BLUE, 0.4 + 0.4 * pulse), 5.0, true)
		_text(ci, "Tourne en rond avec la souris !", Vector2(0, 150), 26, Color(BLUE, 0.6 + 0.4 * pulse), STAGE_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(ci, Vector2(290, 498), 300.0, prog)
	_text(ci, "Bien mélangé", Vector2(290, 494), 14, INK)


# Steps 3 and 4.
func _paint_board(ci: CanvasItem) -> void:
	var board := CookieArt._rr(Vector2(60, 24), Vector2(820, 500), 26)
	ci.draw_colored_polygon(CookieArt._shifted(board, Vector2(6, 8)), Color(0, 0, 0, 0.16))
	ci.draw_colored_polygon(board, Color("#EFD9AE"))
	ci.draw_polyline(CookieArt._closed(board), Color("#B88A55"), 3.0, true)
	for i in 8:
		ci.draw_line(Vector2(76, 70 + i * 54), Vector2(804, 70 + i * 54), Color("#D8BD8A", 0.7), 2.0)
	var k := _roll if _phase == 2 else 1.0
	var poly := _dough_poly(k)
	var th := lerpf(34.0, 8.0, k)
	ci.draw_colored_polygon(CookieArt._shifted(poly, Vector2(5, th + 6.0)), Color(0, 0, 0, 0.18))
	ci.draw_colored_polygon(CookieArt._shifted(poly, Vector2(0, th)), _dough_color().darkened(0.3))
	ci.draw_colored_polygon(poly, _dough_color())
	var hl := CookieArt._shifted(CookieArt._scaled(poly, 0.9), Vector2(-4, -4))
	ci.draw_colored_polygon(hl, _dough_color().lightened(0.1))
	ci.draw_polyline(CookieArt._closed(poly), _dough_color().darkened(0.45), 1.5, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	for i in 70:
		var q := DOUGH_C + Vector2(rng.randf_range(-290, 290), rng.randf_range(-175, 175))
		if Geometry2D.is_point_in_polygon(q, poly):
			ci.draw_circle(q, rng.randf_range(0.8, 2.2), Color("#7A4A24", 0.4))
	for f: Array in _flour:
		ci.draw_circle(f[0], f[1], Color(1, 1, 1, f[2]))
	if _phase == 2:
		CookieArt.rolling_pin(ci, Vector2(440, _pin_y), 400.0)
		if _roll < 0.03:
			var pulse := 0.5 + 0.5 * sin(_time * 4.0)
			_text(ci, "↕  Glisse le rouleau de haut en bas", Vector2(0, 505), 24, Color(BLUE, 0.6 + 0.4 * pulse), STAGE_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		_bar(ci, Vector2(290, 30), 300.0, _roll)
		return
	# The pieces already cut.
	for c: Dictionary in _cuts:
		var p := CookieArt.shape(c.shape)
		var xf := func(poly_in: PackedVector2Array, grow: float) -> PackedVector2Array:
			var out := PackedVector2Array()
			for v in poly_in:
				out.append(c.p + (v * (1.0 + grow)).rotated(c.rot) * CUTTER_SCALE)
			return out
		ci.draw_colored_polygon(xf.call(p, 0.05), Color("#6B4524", 0.75))
		ci.draw_colored_polygon(xf.call(p, 0.0), _dough_color().lightened(0.08))
		ci.draw_polyline(CookieArt._closed(xf.call(p, -0.02)), Color("#FFFFFF", 0.25), 1.5, true)
	for fx: Dictionary in _cut_fx:
		var lift: float = float(fx.t) * 160.0
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		CookieArt.cutter(ci, fx.shape, fx.p, CUTTER_SCALE, fx.rot, lift)
	# The cutter under the mouse.
	if _mouse.x >= 0.0 and _mouse.y >= 24.0 and _cuts.size() < CUT_MAX:
		var id: String = CookieArt.SHAPES[_cut_shape][0]
		var ok := _cut_ok(_mouse, id, _cut_rot)
		var shake := sin(_time * 60.0) * _bump * 8.0
		CookieArt.cutter(ci, id, _mouse + Vector2(shake, -6.0), CUTTER_SCALE, _cut_rot)
		if not ok:
			var poly2 := PackedVector2Array()
			for v in CookieArt.shape(id):
				poly2.append(_mouse + v.rotated(_cut_rot) * CUTTER_SCALE)
			ci.draw_colored_polygon(poly2, Color(0.9, 0.1, 0.1, 0.25))
	if _cuts.is_empty():
		_text(ci, "Clique sur la pâte pour découper !   Molette : tourner", Vector2(0, 508), 22, Color(BLUE, 0.85), STAGE_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)


# Step 5.
func _paint_oven(ci: CanvasItem) -> void:
	# The oven: steel body, the control panel with its knobs, the window and the handle.
	var body := CookieArt._rr(Vector2(240, 8), Vector2(640, 310), 18)
	ci.draw_colored_polygon(CookieArt._shifted(body, Vector2(6, 8)), Color(0, 0, 0, 0.18))
	ci.draw_colored_polygon(body, Color("#D5DBE2"))
	ci.draw_colored_polygon(CookieArt._rr(Vector2(246, 14), Vector2(380, 304), 14), Color("#E9EEF2"))
	ci.draw_polyline(CookieArt._closed(body), Color("#8E99A6"), 3.0, true)
	ci.draw_rect(Rect2(250, 18, 380, 52), Color("#3A4350"))
	for i in 4:
		ci.draw_circle(Vector2(290 + i * 56, 44), 17.0, Color("#B8C0CA"))
		ci.draw_circle(Vector2(290 + i * 56, 44), 13.0, Color("#E1E6EB"))
		ci.draw_line(Vector2(290 + i * 56, 44), Vector2(290 + i * 56 + 7, 36), Color("#3A4350"), 3.0)
	var shown := _bake_t if _oven == "baking" else (0.0 if _oven in ["ready", "in"] else _bake_t)
	var secs := int(shown)
	_text(ci, "%02d:%02d" % [secs / 60, secs % 60], Vector2(520, 55), 26, Color("#7BE07B") if _oven == "baking" else Color("#7A8696"))
	var win := Rect2(262, 90, 356, 190)
	var door_open := _oven in ["ready", "out"]
	if door_open:
		ci.draw_rect(win, Color("#241C18"))
		for i in 3:
			ci.draw_line(Vector2(win.position.x, win.position.y + 50 + i * 55), Vector2(win.end.x, win.position.y + 50 + i * 55), Color("#6E6A66"), 3.0)
		# The door folded down in front.
		var door := PackedVector2Array([Vector2(250, 312), Vector2(630, 312), Vector2(676, 372), Vector2(204, 372)])
		ci.draw_colored_polygon(door, Color("#C4CCD5"))
		ci.draw_polyline(CookieArt._closed(door), Color("#8E99A6"), 3.0, true)
		ci.draw_line(Vector2(222, 366), Vector2(658, 366), Color("#EEF2F6"), 4.0)
	else:
		ci.draw_rect(win.grow(10), Color("#2E3640"))
		var glow := 0.0
		if _oven == "baking":
			glow = 0.55 + 0.1 * sin(_time * 5.0)
		ci.draw_rect(win, Color("#2A1A10").lerp(Color("#FF9A3C"), glow * 0.6))
		ci.draw_rect(Rect2(win.position.x, win.position.y, win.size.x, 60), Color("#FFD08A", glow * 0.25))
		# The tray, in the window, and the cookies on it.
		var inside := Vector2(0, 0)
		if _oven == "in":
			inside = Vector2(0, (1.0 - _slide) * 120.0)
		ci.draw_rect(Rect2(280, 228 + inside.y, 320, 8), Color("#8E99A6"))
		var n := _cookies.size()
		var puff := 1.0 + 0.1 * clampf(_bake_t / BAKE_PALE, 0.0, 1.0)
		for i in n:
			var sl := _tray_slot(i, n)
			var two := n > 5
			var row := 0 if (not two or i < int(ceil(n / 2.0))) else 1
			var p := Vector2(440.0 + (sl.x - 440.0) * 0.52, (190.0 if n == 1 else (206.0 if not two else 168.0 + row * 42.0)) + inside.y)
			var ck: Dictionary = _cookies[i].duplicate()
			ck.doneness = _bake_color(_bake_t) if _oven == "baking" else 0.0
			CookieArt.draw_cookie(ci, ck, p, (0.55 if n == 1 else 0.3) * puff, 0.0, false)
		ci.draw_rect(win, Color(1, 1, 1, 0.06))
		ci.draw_polyline(PackedVector2Array([Vector2(win.position.x + 14, win.end.y - 8), Vector2(win.position.x + 90, win.position.y + 8)]), Color(1, 1, 1, 0.22), 6.0, true)
		ci.draw_rect(Rect2(280, 78, 320, 7), Color("#B8C0CA"))
	if _oven == "baking":
		# While they bake: the cooling rack waiting on the counter, and Maman's two oven mitts.
		var rack := PackedVector2Array([Vector2(170, 380), Vector2(710, 380), Vector2(760, 470), Vector2(120, 470)])
		ci.draw_colored_polygon(CookieArt._shifted(rack, Vector2(4, 8)), Color(0, 0, 0, 0.16))
		ci.draw_polyline(CookieArt._closed(rack), Color("#8E99A6"), 4.0, true)
		for k in 9:
			var f := k / 8.0
			ci.draw_line(rack[0].lerp(rack[1], f), rack[3].lerp(rack[2], f), Color("#AAB3BD"), 2.0)
		for k in 5:
			var f2 := k / 4.0
			ci.draw_line(rack[0].lerp(rack[3], f2), rack[1].lerp(rack[2], f2), Color("#AAB3BD"), 2.0)
		for m in [Vector2(800, 400), Vector2(84, 420)]:
			ci.draw_colored_polygon(CookieArt._rr(m + Vector2(-22, -40), m + Vector2(22, 30), 12), Color("#D8283A"))
			ci.draw_colored_polygon(CookieArt._ellipse(m + Vector2(-24 if m.x > 400 else 24, -6), 9.0, 14.0), Color("#D8283A"))
			ci.draw_rect(Rect2(m + Vector2(-22, 10), Vector2(44, 12)), Color("#F6EFE4"))
			ci.draw_polyline(CookieArt._closed(CookieArt._rr(m + Vector2(-22, -40), m + Vector2(22, 30), 12)), Color("#7E1418"), 2.0, true)
	# The tray on the counter (raw before, baked after), in perspective.
	if _oven == "ready" or _oven == "out" or _oven == "in":
		var offset := 0.0 if _oven != "in" else _slide * 150.0
		var tray := PackedVector2Array([Vector2(130, 372 + offset), Vector2(750, 372 + offset), Vector2(806, 508 + offset), Vector2(74, 508 + offset)])
		ci.draw_colored_polygon(CookieArt._shifted(tray, Vector2(4, 8)), Color(0, 0, 0, 0.2))
		ci.draw_colored_polygon(tray, Color("#8E99A6"))
		var tray_in := PackedVector2Array([Vector2(146, 380 + offset), Vector2(734, 380 + offset), Vector2(786, 498 + offset), Vector2(94, 498 + offset)])
		ci.draw_colored_polygon(tray_in, Color("#EFE6D2"))
		var n := _cookies.size()
		var order: Array = []
		for i in n:
			order.append(i)
		for i: int in order:
			var sl := _tray_slot(i, n)
			var ck: Dictionary = _cookies[i]
			var d := float(ck.doneness) if _oven == "out" else 0.0
			var shown_ck: Dictionary = ck.duplicate()
			shown_ck.doneness = d
			CookieArt.draw_cookie(ci, shown_ck, Vector2(sl.x, sl.y + offset), sl.z, 0.0, true)
	if _oven == "out" and not _burnt and _slide <= 0.0:
		for k in 5:
			var ph := fposmod(_time * 0.5 + k * 0.2, 1.0)
			ci.draw_circle(Vector2(240 + k * 90 + sin(_time + k) * 14.0, 400 - ph * 90.0), 10.0 + ph * 16.0, Color(1, 1, 1, 0.14 * (1.0 - ph)))


# Step 6.
func _paint_decorating(ci: CanvasItem) -> void:
	# The decorating board, round and pale, with the big cookie on it.
	ci.draw_colored_polygon(CookieArt._ellipse(VIEW_C + Vector2(6, 14), 206.0, 196.0), Color(0, 0, 0, 0.14))
	ci.draw_colored_polygon(CookieArt._ellipse(VIEW_C, 206.0, 196.0), Color("#FFFDF7"))
	ci.draw_arc(VIEW_C, 206.0, 0.0, TAU, 60, Color("#D8C7A6"), 4.0, true)
	ci.draw_arc(VIEW_C, 186.0, 0.0, TAU, 60, Color("#E9DEC6"), 2.0, true)
	var ck := _cookie()
	CookieArt.draw_cookie(ci, ck, VIEW_C, VIEW_S, 0.0, true)
	# What the tool would do, at the mouse.
	if _mouse.x >= 0.0 and _mouse.y < 400.0:
		var q := _to_local(_mouse)
		var on := _inside(q)
		if _tab == "glacage" and _tool == "stylo":
			ci.draw_arc(_mouse, float(ICING_WIDTHS[_width][1]) * VIEW_S * 0.5, 0.0, TAU, 20, Color(_icings[_icing][1]), 3.0, true)
		elif _tab == "bonbons" and on:
			CookieArt._frame = Transform2D(0.0, _mouse).scaled_local(Vector2.ONE * VIEW_S)
			ci.draw_set_transform(_mouse, 0.0, Vector2.ONE * VIEW_S)
			CookieArt._candy_local(ci, _candies[_candy][0], Color(CookieArt.CANDY_COLORS[_candy % 7]))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			CookieArt._frame = Transform2D.IDENTITY
		elif _tab == "pepites":
			ci.draw_arc(_mouse, (14.0 if _sprinkles[_sprinkle][0] == "glace" else 9.0) * VIEW_S * 0.6, 0.0, TAU, 24, Color(BLUE, 0.5), 2.0, true)
		elif _tab == "glacage" and _tool == "napper" and on:
			ci.draw_arc(_mouse, 20.0, 0.0, TAU, 20, Color(_icings[_icing][1]), 5.0, true)
	# The row of cookies.
	for i in _cookies.size():
		var r := _thumb_rect(i)
		var sel := i == _cur
		ci.draw_colored_polygon(CookieArt._rr(r.position, r.end, 14), Color(YELLOW, 0.9) if sel else Color(1, 1, 1, 0.55))
		ci.draw_polyline(CookieArt._closed(CookieArt._rr(r.position, r.end, 14)), BLUE if sel else Color("#C8A27A"), 3.0 if sel else 1.5, true)
		CookieArt.draw_cookie(ci, _cookies[i], r.get_center() + Vector2(0, -2), 0.7, 0.0, false)
		if not _cookies[i].ops.is_empty():
			ci.draw_circle(r.position + Vector2(r.size.x - 10, 10), 6.0, Color("#3BAA5C"))


# Step 7.
func _paint_plate(ci: CanvasItem) -> void:
	if str(_r.shape) != "":
		CookieArt.table_scene(ci, Vector2(110, 10), 6.0, _cookies, str(_r.shape), _plates[_plate][0], _drinks[_drink][0])
	else:
		CookieArt.plate_scene(ci, Vector2(110, 10), 6.0, _cookies, _plates[_plate][0], _drinks[_drink][0], false)


# ── Finishing ───────────────────────────────────────────────

func _finish() -> void:
	if _busy:
		return
	_busy = true
	_btn_next.disabled = true
	_say("Je mets tout ça de côté…" if for_santa else "Ça sent tellement bon ! On goûte ?")
	var plate: String = _plates[_plate][0]
	var drink: String = _drinks[_drink][0]
	var cookies := _cookies
	var shape := str(_r.shape)
	var full := await _render(func(n: CanvasItem) -> void: _scene(n, cookies, shape, plate, drink, false))
	if for_santa:
		var eaten := await _render(func(n: CanvasItem) -> void: _scene(n, cookies, shape, plate, drink, true))
		Christmas.save_plate(full, eaten, plate, drink)
	Sfx.play("chime")
	# A mark out of three, for Maman to praise: baked just right, decorated, and a plate and a drink picked.
	var stars := 1
	if not _burnt and _doneness >= 0.45 and _doneness <= 0.92:
		stars += 1
	var decorated := 0
	for ck: Dictionary in cookies:
		if not (ck.get("ops", []) as Array).is_empty():
			decorated += 1
	if decorated > 0:
		stars += 1
	closed.emit({"count": cookies.size(), "plate": plate, "drink": drink, "recipe": recipe, "image": full, "stars": stars})
	queue_free()


func _scene(n: CanvasItem, cookies: Array, shape: String, plate: String, drink: String, eaten: bool) -> void:
	if shape != "":
		CookieArt.table_scene(n, Vector2.ZERO, 4.0, cookies, shape, plate, drink)
	else:
		CookieArt.plate_scene(n, Vector2.ZERO, 4.0, cookies, plate, drink, eaten)


## What `painter` draws on a transparent sheet 440 × 320.
func _render(painter: Callable) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(440, 320)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var node := _Printer.new()
	node.painter = painter
	vp.add_child(node)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


func _leave() -> void:
	if _busy:
		return
	if _phase == 0 and _added.is_empty():
		closed.emit({})
		queue_free()
		return
	var box := Panel.new()
	box.size = Vector2(560, 230)
	box.position = Vector2(340, 230)
	box.add_theme_stylebox_override("panel", _box(Color.WHITE, BLUE, 5, 22))
	box.z_index = 20
	_panel.add_child(box)
	var q := _label("Tu veux arrêter ?\nIl faudra tout recommencer.", 28, BLUE)
	q.position = Vector2(0, 24)
	q.size = Vector2(560, 90)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)
	var keep := _button("Continuer", 22, func() -> void: box.queue_free(), Vector2(210, 54))
	keep.position = Vector2(50, 140)
	keep.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	box.add_child(keep)
	var stop := _button("Arrêter", 22, func() -> void:
		closed.emit({})
		queue_free(), Vector2(210, 54))
	stop.position = Vector2(300, 140)
	box.add_child(stop)


# ── Small helpers ───────────────────────────────────────────

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
	b.size = min_size
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
	b.content_margin_left = 12
	b.content_margin_right = 12
	return b


# ── Parts ───────────────────────────────────────────────────

class _Stage:
	extends Control

	var studio: CookieStudio

	func _draw() -> void:
		studio.paint(self)

	func _gui_input(event: InputEvent) -> void:
		studio.stage_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			studio._mouse = Vector2(-1, -1)
			studio._dirty = true


class _Ribbon:
	extends Control

	var studio: CookieStudio

	func _draw() -> void:
		var order: Array = studio._order
		var w := size.x / order.size()
		var at := order.find(studio._phase)
		for pos in order.size():
			var id: int = order[pos]
			var on: bool = pos == at
			var done: bool = pos < at
			var c := Vector2(pos * w + 22.0, 24.0)
			var col := YELLOW if on else (Color("#7BC96F") if done else Color("#E4D8C0"))
			draw_circle(c, 16.0, col)
			draw_arc(c, 16.0, 0.0, TAU, 24, BLUE if on else Color("#B8A888"), 2.5, true)
			draw_string(ThemeDB.fallback_font, c + Vector2(-20, 7), "✔" if done else str(pos + 1), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 18, BLUE if (on or done) else Color("#8A7A5A"))
			draw_string(ThemeDB.fallback_font, c + Vector2(22, 6), str(studio._r.steps[id]), HORIZONTAL_ALIGNMENT_LEFT, w - 46.0, 15, BLUE if on else Color("#8A7A5A"))


class _Banner:
	extends Control

	func _draw() -> void:
		var r := CookieArt._rr(Vector2.ZERO, size, 22)
		draw_colored_polygon(r, Color("#FFFDF7"))
		draw_polyline(CookieArt._closed(r), Color("#C8A27A"), 3.0, true)
		# Maman: a round face under her wavy light-brown hair.
		var c := Vector2(34, 25)
		draw_circle(c + Vector2(0, -2), 21.0, Color("#B88A5A"))
		draw_circle(c + Vector2(0, 2), 16.0, Color("#F6D5B8"))
		draw_arc(c + Vector2(0, -2), 19.0, PI * 1.05, PI * 1.95, 14, Color("#B88A5A"), 9.0, true)
		draw_circle(c + Vector2(-6, 0), 1.8, Color("#3A2A1E"))
		draw_circle(c + Vector2(6, 0), 1.8, Color("#3A2A1E"))
		draw_arc(c + Vector2(0, 5), 5.0, 0.3, PI - 0.3, 8, Color("#B5442E"), 1.8, true)


class _Gauge:
	extends Control

	var studio: CookieStudio

	func _draw() -> void:
		var t := studio._bake_t if studio._oven in ["baking", "out"] else 0.0
		var w := size.x
		var bar := Rect2(0, 36, w, 26)
		var f := func(a: float) -> float: return a / CookieStudio.BAKE_END * w
		draw_rect(Rect2(0, 36, f.call(CookieStudio.BAKE_PALE), 26), Color("#F0D9A8"))
		draw_rect(Rect2(f.call(CookieStudio.BAKE_PALE), 36, f.call(CookieStudio.BAKE_OVER) - f.call(CookieStudio.BAKE_PALE), 26), Color("#7BC96F"))
		draw_rect(Rect2(f.call(CookieStudio.BAKE_OVER), 36, f.call(CookieStudio.BAKE_BURN) - f.call(CookieStudio.BAKE_OVER), 26), Color("#E0A04A"))
		draw_rect(Rect2(f.call(CookieStudio.BAKE_BURN), 36, w - f.call(CookieStudio.BAKE_BURN), 26), Color("#5A3320"))
		draw_rect(bar, Color("#1D4F91"), false, 2.5)
		var mx := clampf(f.call(t), 0.0, w)
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 9, 26), Vector2(mx + 9, 26), Vector2(mx, 42)]), Color("#D8283A"))
		draw_line(Vector2(mx, 40), Vector2(mx, 66), Color("#D8283A"), 3.0)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, 84), "pâles", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8A6A3A"))
		draw_string(font, Vector2(f.call(CookieStudio.BAKE_PALE) + 4, 84), "dorés !", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#2F7A45"))
		draw_string(font, Vector2(f.call(CookieStudio.BAKE_OVER) - 6, 84), "foncés", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#A8681A"))
		draw_string(font, Vector2(w - 42, 100), "brûlés", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#5A3320"))


class _IconButton:
	extends Button

	var paint: Callable

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self, size / 2.0)


class _Printer:
	extends Node2D

	var painter: Callable

	func _draw() -> void:
		painter.call(self)
