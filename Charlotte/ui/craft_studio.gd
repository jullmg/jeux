class_name CraftStudio
extends CanvasLayer
## The craft table at the service de garde (Julien: "a bricolage for Maman or Papa, a very elaborate making interface"). She
## first chooses WHAT to make (`CraftArt.BASE_ORDER`: a card, a paper-plate face, a pencil pot, a frame for one of her drawings,
## a pasta necklace), then works on it at the bench, like at the real craft table:
##   - Peinture: tempera brush, sponge, fat roller, the pot (fills an area), eraser, on the piece itself;
##   - Papier: she picks a shape, a paper (plain, dots, stripes, checks, zigzag, glitter) and a colour, and CUTS it out with the
##     scissors by following the dotted line (or cuts it quickly), then it lies on the piece;
##   - Décos: googly eyes, noses, mouths, pompoms, buttons, bows, gems, feathers, felt flowers and every sticker of the drawing pad;
##   - Laine: wool glued on in a line, felt pen, glitter glue, wax crayon (over everything);
##   - Écrire: a word on a label, a bubble, a banner (and quick phrases for Maman or Papa).
## Anything laid on the piece is an item she can move, turn, resize, copy, flip, bring forward or send back or throw away; every
## step can be taken back ("Oups !") and done again. The necklace has its own bench: click the beads (pasta she paints, stars, hearts,
## letter beads for a word) onto the string. "C'est fini !" prints the piece (`closed`: {image, inside, kind, who}).
## Kept crafts (`keep`, `kept`) are what the parents show in the salon; `pending` is the one on its way home from the garde.

signal closed(result: Dictionary)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")
const WORK := CraftArt.WORK
const STAGE_POS := Vector2(236, 76)
const UNDO := 12
const KEEP_MAX := 8
const TABS := [["peinture", "Peinture"], ["papier", "Papier"], ["decos", "Décos"], ["laine", "Laine"], ["ecrire", "Écrire"]]
const PAINT_TOOLS := [["pinceau", "Pinceau"], ["eponge", "Éponge"], ["rouleau", "Rouleau"], ["pot", "Remplir"], ["gomme", "Gomme"]]
const INK_TOOLS := [["laine", "Laine"], ["feutre", "Feutre"], ["colle", "Colle brillante"], ["crayon", "Cire"], ["gomme", "Gomme"]]
const CARD_TONES := {"carte": "#FFE9EE", "assiette": "#E6F3E0", "pot": "#E3EEFA", "cadre": "#FFF1D6", "collier": "#EEE6F8"}
const SIZES := [["Petit", 0], ["Moyen", 1], ["Grand", 2]]
const BRUSH_R := [4.0, 9.0, 18.0]
const PAPER_S := [70.0, 120.0, 180.0]
const DECO_R := [26.0, 40.0, 62.0]
const TEXT_S := [22, 32, 46]
const PHRASES := {
	"maman": ["Pour Maman", "Je t'aime, Maman !", "Merci, Maman", "Câlins !", "Bonne fête !"],
	"papa": ["Pour Papa", "Je t'aime, Papa !", "Merci, Papa", "Câlins !", "Bonne fête !"],
	"moi": ["Chambre de Chachoue", "Entrez !", "Toc toc !", "Défense d'entrer… sauf les amis !", "Chut ! Je dors"],
}

var who := "maman"
## Straight to the bench with this thing to make (her door: `who` "moi"), without the first card.
var start_with := ""
## The drawing that goes in the frame (null = a little picture of her own).
var picture: Texture2D

var _root: Control
var _panel: Panel
var _base := ""
var _faces: Array = []
var _face := 0
var _tab := "papier"
var _ptool := "pinceau"
var _itool := "laine"
var _size_i := 1
var _color := Color(CraftArt.PALETTE[0])
var _shape := "coeur"
var _paper := "uni"
var _deco_group := 0
var _deco := "yeux"
var _sticker_cat := 0
var _text_style := "etiquette"
var _sel := -1
var _undo: Array = []
var _redo: Array = []
var _stage: _Stage
var _mouse := Vector2(-1, -1)
var _mode := ""
var _grab := Vector2.ZERO
var _start_len := 1.0
var _start_val := 1.0
var _last := Vector2(-1, -1)
var _stroke_i := 0
var _busy := false
var _nudged := false
var _cut: _Cutter
var _options: Control
var _sidebar_colors: GridContainer
var _tabs_box: VBoxContainer
var _hint: Label
var _title: Label
var _face_box: HBoxContainer
var _sel_buttons: Array[Button] = []
var _typing: LineEdit
var _typed := ""
var _toast_label: Label
var _grain := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _seed_next := 1
# The necklace.
var _beads: Array = []
var _bead := "macaroni"
var _bead_stage: _BeadStage
var _word: LineEdit


func _init() -> void:
	layer = 60


func _ready() -> void:
	add_to_group("modal")
	_make_grain()
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
	if start_with != "":
		_begin(start_with)
	else:
		_choose()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not _busy and not _cut and _sel >= 0 and not (_typing and _typing.has_focus()) \
			and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE):
		get_viewport().set_input_as_handled()
		_delete_item()
		return
	if event.is_action_pressed("ui_cancel") and not _busy:
		get_viewport().set_input_as_handled()
		if _cut:
			_close_cutter()
		elif _typing:
			_typing.release_focus()
		else:
			_leave()


# ── Step 1: what to make ────────────────────────────────────────

func _clear_panel() -> void:
	for child in _panel.get_children():
		_panel.remove_child(child)
		child.queue_free()
	_sel_buttons.clear()
	_typing = null
	_word = null


func _choose() -> void:
	_clear_panel()
	var title := _label("Qu'est-ce que tu veux fabriquer pour %s ?" % ("Maman" if who == "maman" else "Papa"), 34, BLUE)
	title.position = Vector2(0, 26)
	title.size = Vector2(1240, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var hint := _label("Choisis un bricolage. Tu pourras le décorer comme tu veux !", 20, Color(BLUE, 0.7))
	hint.position = Vector2(0, 76)
	hint.size = Vector2(1240, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(hint)
	var x := 38.0
	for id: String in CraftArt.BASE_ORDER:
		var card := Button.new()
		card.position = Vector2(x, 130)
		card.custom_minimum_size = Vector2(222, 440)
		card.size = Vector2(222, 440)
		var normal := _box(Color.WHITE, Color("#C8A27A"), 3, 18)
		normal.shadow_color = Color(0.3, 0.18, 0.05, 0.18)
		normal.shadow_size = 8
		normal.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("normal", normal)
		var hover := _box(Color("#FFF4C2"), BLUE, 4, 18)
		hover.shadow_color = Color(0.1, 0.2, 0.5, 0.25)
		hover.shadow_size = 12
		hover.shadow_offset = Vector2(0, 6)
		card.add_theme_stylebox_override("hover", hover)
		card.add_theme_stylebox_override("pressed", _box(Color("#FFE9A8"), YELLOW, 4, 18))
		card.clip_contents = true
		card.pressed.connect(func() -> void: _begin(id))
		_panel.add_child(card)
		# A pastel backdrop under the picture, a different tone for each thing to make.
		var back := Panel.new()
		back.position = Vector2(10, 10)
		back.size = Vector2(202, 238)
		back.add_theme_stylebox_override("panel", _box(Color(CARD_TONES.get(id, "#FFF7E0")), Color(CARD_TONES.get(id, "#FFF7E0")).darkened(0.12), 2, 14))
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(back)
		var pic := _CardPicture.new()
		pic.base = id
		pic.picture = picture
		pic.position = Vector2(11, 14)
		pic.size = Vector2(200, 230)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.clip_contents = true
		card.add_child(pic)
		var long_name: bool = str(CraftArt.BASES[id][0]).length() > 14
		var nm := _label(CraftArt.BASES[id][0], 22 if long_name else 26, BLUE)
		nm.position = Vector2(8, 262)
		nm.size = Vector2(206, 40)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)
		var blurb := _label(CraftArt.BASES[id][1], 17, Color(BLUE, 0.8))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.custom_minimum_size = Vector2(192, 0)
		blurb.position = Vector2(15, 312)
		blurb.size = Vector2(192, 110)
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(blurb)
		x += 234.0
	var cancel := _button("Plus tard", 20, func() -> void: _leave(), Vector2(150, 48))
	cancel.position = Vector2(1060, 620)
	_panel.add_child(cancel)


func _begin(id: String) -> void:
	_base = id
	Sfx.play("pop")
	_undo.clear()
	_redo.clear()
	_sel = -1
	_face = 0
	_faces.clear()
	if id == "collier":
		_beads.clear()
		_build_beads()
		return
	for i in (2 if id == "carte" else 1):
		var paint := Image.create(int(WORK.x), int(WORK.y), false, Image.FORMAT_RGBA8)
		var ink := Image.create(int(WORK.x), int(WORK.y), false, Image.FORMAT_RGBA8)
		_faces.append({"items": [], "paint": paint, "ink": ink, "paint_tex": ImageTexture.create_from_image(paint), "ink_tex": ImageTexture.create_from_image(ink)})
	_tab = "peinture" if id in ["pot", "assiette"] else ("decos" if id == "porte" else "papier")
	_build_work()
	if id == "cadre":
		_toast("Ton cadre est prêt pour un de tes dessins !" if not DrawingPad.gallery_names().is_empty() else "Ton cadre attend un dessin : on met une petite image.")


# ── Step 2: the bench ───────────────────────────────────────────

func _build_work() -> void:
	_clear_panel()
	_title = _label(str(CraftArt.BASES[_base][0]) if who == "moi" else "%s pour %s" % [CraftArt.BASES[_base][0], "Maman" if who == "maman" else "Papa"], 30, BLUE)
	_title.position = Vector2(0, 14)
	_title.size = Vector2(1240, 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)
	# Tabs and colours down the left.
	_tabs_box = VBoxContainer.new()
	_tabs_box.position = Vector2(20, 72)
	_tabs_box.add_theme_constant_override("separation", 6)
	_panel.add_child(_tabs_box)
	_colors_grid()
	# The piece.
	var frame := Panel.new()
	frame.position = STAGE_POS - Vector2(8, 8)
	frame.size = WORK + Vector2(16, 16)
	frame.add_theme_stylebox_override("panel", _box(Color("#E9DFCB"), Color("#C8A27A"), 5, 10))
	_panel.add_child(frame)
	_stage = _Stage.new()
	_stage.studio = self
	_stage.position = STAGE_POS
	_stage.size = WORK
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_stage)
	_face_box = HBoxContainer.new()
	_face_box.position = Vector2(STAGE_POS.x, STAGE_POS.y + WORK.y + 14)
	_face_box.add_theme_constant_override("separation", 8)
	_panel.add_child(_face_box)
	_hint = _label("", 19, Color(BLUE, 0.85))
	_hint.position = Vector2(STAGE_POS.x, STAGE_POS.y + WORK.y + 62)
	_hint.size = Vector2(WORK.x, 60)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_hint)
	_options = Control.new()
	_options.position = Vector2(STAGE_POS.x + WORK.x + 24, 72)
	_options.size = Vector2(396, 520)
	_panel.add_child(_options)
	# The bar along the bottom.
	var bar := HBoxContainer.new()
	bar.position = Vector2(20, 640)
	bar.size = Vector2(1200, 46)
	bar.add_theme_constant_override("separation", 8)
	_panel.add_child(bar)
	bar.add_child(_button("Oups !", 19, _take_back, Vector2(92, 46)))
	bar.add_child(_button("Refaire", 19, _do_again, Vector2(98, 46)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(14, 1)
	bar.add_child(gap)
	bar.add_child(_button("Au hasard !", 17, _surprise_me, Vector2(110, 46)))
	for spec: Array in [["Copier", _copy_item], ["Retourner", _flip_item], ["Devant", _to_front], ["Derrière", _to_back], ["Jeter", _delete_item]]:
		var b := _button(spec[0], 17, spec[1], Vector2(88, 46))
		bar.add_child(b)
		_sel_buttons.append(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_button("Arrêter", 19, _leave, Vector2(110, 46)))
	var done := _button("C'est fini !", 22, _finish_check, Vector2(190, 46))
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	bar.add_child(done)
	_refresh()


func _colors_grid() -> void:
	_sidebar_colors = GridContainer.new()
	_sidebar_colors.columns = 4
	_sidebar_colors.position = Vector2(20, 400)
	_sidebar_colors.add_theme_constant_override("h_separation", 6)
	_sidebar_colors.add_theme_constant_override("v_separation", 6)
	_panel.add_child(_sidebar_colors)


## Everything that depends on the tab, the tool, the selection: rebuilt after each change.
func _refresh() -> void:
	if _base == "collier":
		return
	for child in _tabs_box.get_children():
		_tabs_box.remove_child(child)
		child.queue_free()
	for t: Array in TABS:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(190, 52)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if t[0] == _tab else Color.WHITE, BLUE, 3, 14))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 14))
		b.pressed.connect(func() -> void:
			_tab = t[0]
			if t[0] != "papier" and t[0] != "decos" and t[0] != "ecrire":
				_sel = -1
			_refresh())
		_tabs_box.add_child(b)
	for child in _sidebar_colors.get_children():
		_sidebar_colors.remove_child(child)
		child.queue_free()
	for hex: String in CraftArt.PALETTE:
		var c := Color(hex)
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 28)
		var picked := c.is_equal_approx(_color)
		b.add_theme_stylebox_override("normal", _box(c, YELLOW if picked else c.darkened(0.35), 4 if picked else 2, 8))
		b.add_theme_stylebox_override("hover", _box(c.lightened(0.15), BLUE, 3, 8))
		b.add_theme_stylebox_override("pressed", _box(c, YELLOW, 4, 8))
		b.pressed.connect(func() -> void: _pick_color(c))
		_sidebar_colors.add_child(b)
	# The frame's picture: one of the drawings in her drawer.
	if _base == "cadre":
		var pick := _button("Choisir mon dessin", 18, _pick_picture, Vector2(190, 42))
		pick.disabled = DrawingPad.gallery_names().is_empty()
		pick.position = Vector2(0, 0)
		_face_box.add_child(pick)
	# The two sides of a card.
	for child in _face_box.get_children():
		_face_box.remove_child(child)
		child.queue_free()
	if _base == "carte":
		for i in 2:
			var b2 := _button(["Dehors", "Dedans"][i], 19, func() -> void: _go_face(i), Vector2(120, 42))
			b2.add_theme_stylebox_override("normal", _box(YELLOW if i == _face else Color.WHITE, BLUE, 3 if i == _face else 2, 12))
			_face_box.add_child(b2)
	for b3 in _sel_buttons:
		b3.disabled = _sel < 0
	_fill_options()
	_stage.queue_redraw()


func _fill_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	var y := 0.0
	match _tab:
		"peinture":
			_hint.text = "Peinture ! Choisis une couleur, puis peins sur ton bricolage. Le pot remplit une zone en entier."
			y = _tool_row(PAINT_TOOLS, _ptool, y, func(id: String) -> void: _ptool = id)
			y = _size_row(y)
		"laine":
			_hint.text = "Laine, feutre ou colle brillante : ça se met par-dessus tout le reste."
			y = _tool_row(INK_TOOLS, _itool, y, func(id: String) -> void: _itool = id)
			y = _size_row(y)
		"papier":
			_hint.text = "Choisis une forme, un papier, une couleur : puis découpe-la aux ciseaux, en suivant les pointillés !"
			_paper_options()
		"decos":
			_hint.text = "Clique sur une décoration pour la coller. Tu peux ensuite la bouger, la tourner et l'agrandir."
			_deco_options()
		"ecrire":
			_hint.text = "Écris un mot, choisis comment il se colle, ou prends une phrase toute faite."
			_text_options()
	if _sel >= 0 and _tab in ["papier", "decos", "ecrire"]:
		_hint.text = "Tire sur l'objet pour le bouger, sur le coin pour l'agrandir, sur le rond du haut pour le tourner."


func _tool_row(tools: Array, current: String, y: float, pick: Callable) -> float:
	var x := 0.0
	var row := 0
	for t: Array in tools:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(124, 46)
		b.position = Vector2(x, y + row * 54.0)
		b.size = Vector2(124, 46)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if t[0] == current else Color.WHITE, BLUE, 3 if t[0] == current else 2, 12))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 12))
		b.pressed.connect(func() -> void:
			pick.call(t[0])
			_refresh())
		_options.add_child(b)
		x += 132.0
		if x > 300.0:
			x = 0.0
			row += 1
	return y + (row + 1 if x == 0.0 else row + 1) * 54.0 + 8.0


func _size_row(y: float) -> float:
	var l := _label("Grosseur", 18, Color(BLUE, 0.8))
	l.position = Vector2(0, y)
	_options.add_child(l)
	var x := 96.0
	for s: Array in SIZES:
		var b := Button.new()
		b.text = s[0]
		b.position = Vector2(x, y - 6)
		b.size = Vector2(90, 40)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if s[1] == _size_i else Color.WHITE, BLUE, 2, 12))
		b.pressed.connect(func() -> void:
			_size_i = s[1]
			_resize_selected()
			_refresh())
		_options.add_child(b)
		x += 96.0
	return y + 50.0


func _paper_options() -> void:
	var y := 0.0
	var x := 0.0
	for id: String in CraftArt.SHAPES:
		var b := _IconButton.new()
		b.position = Vector2(x, y)
		b.size = Vector2(58, 52)
		var picked := id == _shape
		b.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if picked else Color.WHITE, YELLOW if picked else BLUE, 4 if picked else 1, 10))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 2, 10))
		var col := _color
		b.paint = func(ci: CanvasItem, c: Vector2) -> void:
			ci.draw_set_transform(c, 0.0, Vector2.ONE)
			var pts := CraftArt.shape_points(id, 40.0)
			if Geometry2D.triangulate_polygon(pts).size() > 0:
				ci.draw_colored_polygon(pts, col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		b.pressed.connect(func() -> void:
			_shape = id
			_refresh())
		_options.add_child(b)
		x += 64.0
		if x > 330.0:
			x = 0.0
			y += 58.0
	y += 64.0
	var pl := _label("Papier", 18, Color(BLUE, 0.8))
	pl.position = Vector2(0, y)
	_options.add_child(pl)
	y += 28.0
	x = 0.0
	for p: Array in CraftArt.PAPERS:
		var b2 := _IconButton.new()
		b2.position = Vector2(x, y)
		b2.size = Vector2(62, 50)
		var picked2: bool = p[0] == _paper
		b2.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if picked2 else Color.WHITE, YELLOW if picked2 else BLUE, 4 if picked2 else 1, 10))
		b2.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 2, 10))
		var pcol := _color
		var pid: String = p[0]
		b2.paint = func(ci: CanvasItem, c: Vector2) -> void:
			ci.draw_set_transform(c, 0.0, Vector2.ONE)
			CraftArt.draw_paper(ci, {"kind": "paper", "sub": "carre", "s": 38.0, "color": pcol, "pattern": pid, "seed": 3, "cut": false})
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		b2.pressed.connect(func() -> void:
			_paper = pid
			_refresh())
		_options.add_child(b2)
		x += 66.0
	y += 62.0
	y = _size_row(y + 4.0)
	var cut := _button("Découper aux ciseaux !", 21, func() -> void: _open_cutter(true), Vector2(296, 52))
	cut.position = Vector2(0, y + 8.0)
	cut.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	_options.add_child(cut)
	var quick := _button("Vite", 19, func() -> void: _open_cutter(false), Vector2(90, 52))
	quick.position = Vector2(306, y + 8.0)
	_options.add_child(quick)


func _deco_options() -> void:
	var x := 0.0
	var y := 0.0
	var names: Array = []
	for g: Array in CraftArt.DECO_GROUPS:
		names.append(g[1])
	names.append("Autocollants")
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.position = Vector2(x, y)
		b.size = Vector2(124, 40)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if i == _deco_group else Color.WHITE, BLUE, 3 if i == _deco_group else 2, 12))
		b.pressed.connect(func() -> void:
			_deco_group = i
			_refresh())
		_options.add_child(b)
		x += 128.0
		if x > 300.0:
			x = 0.0
			y += 46.0
	y = 98.0
	var list: Array = []
	if _deco_group < CraftArt.DECO_GROUPS.size():
		for d: Array in CraftArt.DECO_GROUPS[_deco_group][2]:
			list.append(d[0])
	else:
		# The stickers have their own boxes: the same four as the drawing pad's stamps.
		var cats: Array = StampArt.CATEGORIES
		var cb := HBoxContainer.new()
		cb.position = Vector2(0, y)
		cb.add_theme_constant_override("separation", 4)
		_options.add_child(cb)
		for i in cats.size():
			var sb := _button(cats[i][1].split(" ")[0], 15, func() -> void:
				_sticker_cat = i
				_refresh(), Vector2(92, 34))
			sb.add_theme_stylebox_override("normal", _box(YELLOW if i == _sticker_cat else Color.WHITE, BLUE, 2, 10))
			cb.add_child(sb)
		y += 42.0
		list = cats[_sticker_cat][2]
	var flow := HFlowContainer.new()
	flow.position = Vector2(0, y)
	flow.size = Vector2(396, 380)
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_options.add_child(flow)
	for id: String in list:
		var sticker := _deco_group >= CraftArt.DECO_GROUPS.size()
		var b2 := _IconButton.new()
		b2.custom_minimum_size = Vector2(62, 62)
		var col := _color
		b2.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 1, 10))
		b2.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 10))
		b2.paint = func(ci: CanvasItem, c: Vector2) -> void:
			if sticker:
				StampArt.draw(ci, id, c, 22.0, col)
			else:
				CraftArt.deco(ci, id, c, 22.0, col, 5)
		b2.pressed.connect(func() -> void: _add_deco(id, sticker))
		flow.add_child(b2)
	var note := _label("La couleur du bas change les décorations qui en ont une.", 15, Color(BLUE, 0.6))
	note.position = Vector2(0, 470)
	note.size = Vector2(396, 40)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_options.add_child(note)


func _text_options() -> void:
	_typing = LineEdit.new()
	_typing.position = Vector2(0, 0)
	_typing.size = Vector2(396, 46)
	_typing.placeholder_text = "Écris ton mot ici…"
	_typing.max_length = 28
	_typing.add_theme_font_size_override("font_size", 22)
	_typing.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 12))
	_typing.add_theme_stylebox_override("focus", _box(Color.WHITE, YELLOW, 3, 12))
	_typing.text = _typed
	_typing.text_changed.connect(func(t: String) -> void: _typed = t)
	_typing.text_submitted.connect(func(t: String) -> void: _add_text(t))
	_options.add_child(_typing)
	var x := 0.0
	var y := 58.0
	for st: Array in CraftArt.TEXT_STYLES:
		var b := Button.new()
		b.text = st[1]
		b.position = Vector2(x, y)
		b.size = Vector2(94, 40)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_stylebox_override("normal", _box(YELLOW if st[0] == _text_style else Color.WHITE, BLUE, 3 if st[0] == _text_style else 2, 12))
		b.pressed.connect(func() -> void:
			_text_style = st[0]
			if _sel >= 0 and _items()[_sel].kind == "text":
				_snap()
				_items()[_sel].style = st[0]
			_refresh())
		_options.add_child(b)
		x += 100.0
	y = _size_row(y + 56.0)
	var go := _button("Coller le mot", 21, func() -> void: _add_text(_typing.text), Vector2(396, 50))
	go.position = Vector2(0, y + 4.0)
	go.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	_options.add_child(go)
	var pl := _label("Ou une phrase toute faite :", 17, Color(BLUE, 0.8))
	pl.position = Vector2(0, y + 68.0)
	_options.add_child(pl)
	var py := y + 98.0
	for phrase: String in PHRASES[who]:
		var pb := _button(phrase, 17, func() -> void: _add_text(phrase), Vector2(396, 38))
		pb.position = Vector2(0, py)
		_options.add_child(pb)
		py += 42.0


func _pick_color(c: Color) -> void:
	_color = c
	if _sel >= 0 and _tab in ["papier", "decos", "ecrire"]:
		_snap()
		_items()[_sel].color = c
	_refresh()


func _go_face(i: int) -> void:
	_face = i
	_sel = -1
	_refresh()


# ── The items on the piece ──────────────────────────────────────

func _items() -> Array:
	return _faces[_face].items


func _center() -> Vector2:
	var r := CraftArt.base_rect(_base)
	if _base == "cadre":
		return Vector2(r.position.x + 70.0, r.position.y + 50.0)
	return r.get_center()


func _new_item(item: Dictionary) -> void:
	_snap()
	item.at = _center() + Vector2(_rng.randf_range(-24.0, 24.0), _rng.randf_range(-24.0, 24.0))
	item.rot = 0.0
	item.flip = false
	item.seed = _seed_next
	_seed_next += 1
	item.pop = 0.5
	_items().append(item)
	_sel = _items().size() - 1
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		item.pop = v
		_stage.queue_redraw(), 0.5, 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: item.erase("pop"))
	Sfx.play("pop")
	_refresh()


func _add_deco(id: String, sticker: bool) -> void:
	if _busy:
		return
	_new_item({"kind": "sticker" if sticker else "deco", "sub": id, "color": _color, "s": DECO_R[_size_i]})


## Three decorations picked and scattered for her: a quick start, or a bit of fun (each can still be moved, turned, resized or thrown away).
func _surprise_me() -> void:
	if _busy:
		return
	var groups: Array = CraftArt.DECO_GROUPS
	var r := CraftArt.base_rect(_base)
	for k in 3:
		var g: Array = groups[_rng.randi() % groups.size()]
		var list: Array = g[2]
		if list.is_empty():
			continue
		_color = Color(CraftArt.PALETTE[_rng.randi() % CraftArt.PALETTE.size()])
		_add_deco(str((list[_rng.randi() % list.size()] as Array)[0]), false)
		var it: Dictionary = _items()[_items().size() - 1]
		it.at = r.position + Vector2(_rng.randf_range(0.18, 0.82) * r.size.x, _rng.randf_range(0.18, 0.82) * r.size.y)
		it.rot = _rng.randf_range(-0.5, 0.5)
	_toast("Voilà quelques surprises ! Déplace-les où tu veux.")
	_stage.queue_redraw()


func _add_text(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty() or _busy:
		return
	_new_item({"kind": "text", "text": t, "style": _text_style, "color": _color, "s": float(TEXT_S[_size_i])})
	_typed = ""
	if _typing:
		_typing.text = ""


func _resize_selected() -> void:
	if _sel < 0 or _base == "collier" or _tab not in ["papier", "decos", "ecrire"]:
		return
	_snap()
	var it: Dictionary = _items()[_sel]
	match it.kind:
		"paper":
			it.s = PAPER_S[_size_i]
		"text":
			it.s = float(TEXT_S[_size_i])
		_:
			it.s = DECO_R[_size_i]


func _copy_item() -> void:
	if _sel < 0:
		return
	_snap()
	var copy: Dictionary = _items()[_sel].duplicate(true)
	copy.at += Vector2(26, 22)
	copy.seed = _seed_next
	_seed_next += 1
	_items().append(copy)
	_sel = _items().size() - 1
	Sfx.play("pop")
	_refresh()


func _flip_item() -> void:
	if _sel < 0:
		return
	_snap()
	_items()[_sel].flip = not _items()[_sel].flip
	_refresh()


func _to_front() -> void:
	if _sel < 0:
		return
	_snap()
	var it: Dictionary = _items().pop_at(_sel)
	_items().append(it)
	_sel = _items().size() - 1
	_refresh()


func _to_back() -> void:
	if _sel < 0:
		return
	_snap()
	var it: Dictionary = _items().pop_at(_sel)
	_items().insert(0, it)
	_sel = 0
	_refresh()


func _delete_item() -> void:
	if _sel < 0:
		return
	_snap()
	_items().remove_at(_sel)
	_sel = -1
	Sfx.play("swoosh")
	_refresh()


func _hit_item(p: Vector2) -> int:
	var items := _items()
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		var local: Vector2 = (p - it.at).rotated(-it.rot)
		var h := CraftArt.item_half(it)
		if absf(local.x) <= h.x and absf(local.y) <= h.y:
			return i
	return -1


## Where the turning knob of an item is: over it, or under it when there is no room above.
static func knob_of(it: Dictionary) -> Vector2:
	var h := CraftArt.item_half(it)
	var up: Vector2 = it.at + Vector2(0, -h.y - 30.0).rotated(it.rot)
	if up.y < 16.0 or up.x < 12.0 or up.x > WORK.x - 12.0:
		return it.at + Vector2(0, h.y + 30.0).rotated(it.rot)
	return up


func _handle_hit(p: Vector2) -> String:
	if _sel < 0:
		return ""
	var it: Dictionary = _items()[_sel]
	var h := CraftArt.item_half(it)
	if p.distance_to(knob_of(it)) <= 15.0:
		return "rotate"
	if p.distance_to(it.at + Vector2(h.x, h.y).rotated(it.rot)) <= 15.0:
		return "scale"
	return ""


# ── Input on the piece ──────────────────────────────────────────

func stage_input(event: InputEvent) -> void:
	if _busy or _cut:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
		_stage.queue_redraw()
	if _base == "collier":
		return
	if _tab == "peinture" or _tab == "laine":
		_paint_input(event)
	else:
		_item_input(event)


func _item_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var h := _handle_hit(event.position)
			if h != "":
				_snap()
				_mode = h
				var it: Dictionary = _items()[_sel]
				_start_len = maxf(8.0, (event.position - it.at).length())
				_start_val = it.s
				return
			var i := _hit_item(event.position)
			if i >= 0:
				_sel = i
				_snap()
				_mode = "move"
				_grab = _items()[i].at - event.position
				_refresh()
			else:
				_sel = -1
				_mode = ""
				_refresh()
		else:
			_mode = ""
	elif event is InputEventMouseMotion and _mode != "" and _sel >= 0:
		var it2: Dictionary = _items()[_sel]
		match _mode:
			"move":
				it2.at = (event.position + _grab).clamp(Vector2(10, 10), WORK - Vector2(10, 10))
			"scale":
				var k: float = (event.position - it2.at).length() / _start_len
				var lo := 10.0 if it2.kind == "text" else 12.0
				var hi := 90.0 if it2.kind == "text" else (320.0 if it2.kind == "paper" else 170.0)
				it2.s = clampf(_start_val * k, lo, hi)
			"rotate":
				var a: float = (event.position - it2.at).angle() + PI / 2.0
				it2.rot = 0.0 if absf(wrapf(a, -PI, PI)) < 0.09 else a
		_stage.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and _sel >= 0 \
			and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
		var it3: Dictionary = _items()[_sel]
		if event.shift_pressed:
			it3.rot += 0.12 * (1.0 if up else -1.0)
		else:
			it3.s = clampf(it3.s * (1.08 if up else 0.93), 10.0, 320.0)
		_stage.queue_redraw()


# ── Painting, wool and glue ─────────────────────────────────────

func _layer() -> Image:
	return _faces[_face].paint if _tab == "peinture" else _faces[_face].ink


func _layer_tex() -> ImageTexture:
	return _faces[_face].paint_tex if _tab == "peinture" else _faces[_face].ink_tex


func _tool() -> String:
	return _ptool if _tab == "peinture" else _itool


func _radius() -> float:
	var r: float = BRUSH_R[_size_i]
	match _tool():
		"rouleau":
			return r * 1.9
		"eponge":
			return r * 1.4
		"gomme":
			return r * 1.6
		"colle":
			return maxf(3.0, r * 0.55)
		"laine":
			return maxf(3.0, r * 0.7)
		"feutre":
			return maxf(2.0, r * 0.45)
	return r


func _paint_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _tool() == "pot":
				if CraftArt.inside(_base, event.position):
					_snap()
					_flood(Vector2i(int(event.position.x), int(event.position.y)))
					Sfx.play("pop")
				return
			if not CraftArt.inside(_base, event.position, 6.0):
				return
			_snap()
			_last = event.position
			_stroke_i = 0
			_rng.seed = int(Time.get_ticks_usec())
			_stroke(event.position, event.position)
		else:
			_last = Vector2(-1, -1)
	elif event is InputEventMouseMotion and _last.x >= 0.0:
		_stroke(_last, event.position)
		_last = event.position


func _stroke(a: Vector2, b: Vector2) -> void:
	var r := _radius()
	var steps := maxi(1, int(a.distance_to(b) / maxf(1.0, r * 0.35)))
	for i in steps + 1:
		_dab(a.lerp(b, float(i) / steps), r)
		_stroke_i += 1
	_layer_tex().update(_layer())
	_stage.queue_redraw()


func _dab(c: Vector2, r: float) -> void:
	var img := _layer()
	var col := _color
	match _tool():
		"gomme":
			_disc(img, c, r, func(_x: int, _y: int, _d: float) -> float: return 1.0, Color(0, 0, 0, 0), true)
		"pinceau":
			# Tempera: nearly solid, with the stripes of the bristles.
			_disc(img, c, r, func(x: int, y: int, d: float) -> float:
				return (0.97 if d < 0.88 else 0.6) * (0.9 + 0.1 * _grain[((x * 3) & 63) + ((y & 7) << 6)]),
				col)
		"rouleau":
			_disc(img, c, r, func(_x: int, _y: int, d: float) -> float: return 0.9 if d < 0.9 else 0.5, col)
		"eponge":
			for i in int(r * 0.9) + 3:
				var p := c + Vector2.from_angle(_rng.randf() * TAU) * r * sqrt(_rng.randf())
				_disc(img, p, _rng.randf_range(1.5, 3.5), func(_x: int, _y: int, _d: float) -> float: return 0.85, col.lightened(_rng.randf_range(-0.06, 0.1)))
		"feutre":
			_disc(img, c, r, func(_x: int, _y: int, d: float) -> float: return 0.96 if d < 0.8 else 0.6, col)
		"crayon":
			_disc(img, c, r, func(x: int, y: int, d: float) -> float:
				return 0.94 if _grain[(x & 63) + ((y & 63) << 6)] < 0.8 - d * 0.3 else 0.0, col)
		"laine":
			# A twisted strand: lit from the upper left, the twist a slanting stripe.
			_disc(img, c, r, func(x: int, y: int, d: float) -> float: return 1.0 if d < 0.95 else 0.6,
				col, false, func(x: int, y: int, d: float, base: Color) -> Color:
					var lit := base.lightened(0.28 * (1.0 - clampf((float(y) - c.y) / maxf(r, 1.0) * 0.5 + 0.5, 0.0, 1.0)))
					return lit.darkened(0.3) if (x + y * 2) % 7 < 2 or d > 0.8 else lit)
		"colle":
			_disc(img, c, r, func(_x: int, _y: int, d: float) -> float: return 0.55 if d < 0.95 else 0.3, col.lightened(0.1), false,
				func(x: int, y: int, d: float, base: Color) -> Color:
					return Color(1, 1, 1, 1).lerp(base, 0.5) if (d < 0.45 and (float(y) - c.y) < -r * 0.1) else base)
			for i in int(r * 0.7) + 1:
				var p2 := c + Vector2.from_angle(_rng.randf() * TAU) * r * sqrt(_rng.randf())
				_plot(img, int(p2.x), int(p2.y), Color.WHITE if _rng.randf() < 0.6 else Color("#FFF1B8"), 0.95)
				if _rng.randf() < 0.3:
					for off: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						_plot(img, int(p2.x) + off.x, int(p2.y) + off.y, Color("#FFF8D8"), 0.7)


## A disc of paint on `img`: `alpha(x, y, d)` its opacity (d from 0 at the middle to 1 at the rim); `shade` can change the colour per
## pixel; `erase` takes the layer's paint away instead.
func _disc(img: Image, c: Vector2, r: float, alpha: Callable, col: Color, erase := false, shade := Callable()) -> void:
	var x0 := maxi(0, int(c.x - r))
	var x1 := mini(int(WORK.x) - 1, int(c.x + r))
	var y0 := maxi(0, int(c.y - r))
	var y1 := mini(int(WORK.y) - 1, int(c.y + r))
	var r2 := r * r
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d2 := Vector2(x, y).distance_squared_to(c)
			if d2 > r2:
				continue
			if not erase and not CraftArt.inside(_base, Vector2(x, y), 1.0):
				continue
			var d := sqrt(d2) / maxf(r, 0.001)
			var a: float = alpha.call(x, y, d)
			if a <= 0.0:
				continue
			if erase:
				var old := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(old.r, old.g, old.b, old.a * (1.0 - a)))
			else:
				var cc := col
				if shade.is_valid():
					cc = shade.call(x, y, d, col)
				_plot(img, x, y, cc, a)


func _plot(img: Image, x: int, y: int, col: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= int(WORK.x) or y >= int(WORK.y):
		return
	if not CraftArt.inside(_base, Vector2(x, y), 1.0):
		return
	var d := img.get_pixel(x, y)
	var oa := a + d.a * (1.0 - a)
	if oa <= 0.0:
		return
	img.set_pixel(x, y, Color((col.r * a + d.r * d.a * (1.0 - a)) / oa, (col.g * a + d.g * d.a * (1.0 - a)) / oa,
		(col.b * a + d.b * d.a * (1.0 - a)) / oa, oa))


## The pot: fills the area of paint (or of bare piece) round `at`, never past the piece.
func _flood(at: Vector2i) -> void:
	var img := _layer()
	var w := int(WORK.x)
	var h := int(WORK.y)
	var data := img.get_data()
	var i0 := (at.y * w + at.x) * 4
	var sr := data[i0]
	var sg := data[i0 + 1]
	var sb := data[i0 + 2]
	var sa := data[i0 + 3]
	var fr := _color.r8
	var fg := _color.g8
	var fb := _color.b8
	if sa == 255 and absi(sr - fr) + absi(sg - fg) + absi(sb - fb) < 6:
		return
	var mask := PackedByteArray()
	mask.resize(w * h)
	var stack: Array[Vector2i] = [at]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var x := p.x
		var y := p.y
		if mask[y * w + x] != 0 or not _like(data, (y * w + x) * 4, sr, sg, sb, sa) or not CraftArt.inside(_base, Vector2(x, y)):
			continue
		while x > 0 and mask[y * w + x - 1] == 0 and _like(data, (y * w + x - 1) * 4, sr, sg, sb, sa) and CraftArt.inside(_base, Vector2(x - 1, y)):
			x -= 1
		var up := false
		var down := false
		while x < w and mask[y * w + x] == 0 and _like(data, (y * w + x) * 4, sr, sg, sb, sa) and CraftArt.inside(_base, Vector2(x, y)):
			mask[y * w + x] = 1
			if y > 0:
				var ok := mask[(y - 1) * w + x] == 0 and _like(data, ((y - 1) * w + x) * 4, sr, sg, sb, sa) and CraftArt.inside(_base, Vector2(x, y - 1))
				if ok and not up:
					stack.append(Vector2i(x, y - 1))
				up = ok
			if y < h - 1:
				var ok2 := mask[(y + 1) * w + x] == 0 and _like(data, ((y + 1) * w + x) * 4, sr, sg, sb, sa) and CraftArt.inside(_base, Vector2(x, y + 1))
				if ok2 and not down:
					stack.append(Vector2i(x, y + 1))
				down = ok2
			x += 1
	for k in w * h:
		if mask[k] != 0:
			data[k * 4] = fr
			data[k * 4 + 1] = fg
			data[k * 4 + 2] = fb
			data[k * 4 + 3] = 255
	var out := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	_faces[_face].paint = out
	_faces[_face].paint_tex.update(out)
	_stage.queue_redraw()


func _like(data: PackedByteArray, i: int, r: int, g: int, b: int, a: int) -> bool:
	return absi(data[i + 3] - a) <= 24 and (a < 24 or absi(data[i] - r) + absi(data[i + 1] - g) + absi(data[i + 2] - b) <= 40)


func _make_grain() -> void:
	var rg := RandomNumberGenerator.new()
	rg.seed = 2027
	var raw := PackedFloat32Array()
	raw.resize(64 * 64)
	for i in raw.size():
		raw[i] = rg.randf()
	_grain.resize(64 * 64)
	for y in 64:
		for x in 64:
			var v := (raw[x + y * 64] + raw[((x + 1) & 63) + y * 64] + raw[x + ((y + 1) & 63) * 64] + raw[((x + 1) & 63) + ((y + 1) & 63) * 64]) * 0.25
			_grain[x + y * 64] = clampf((v - 0.5) * 1.6 + 0.5, 0.0, 1.0)


# ── Undo ────────────────────────────────────────────────────────

func _state() -> Dictionary:
	if _base == "collier":
		return {"beads": _beads.duplicate(true)}
	var f: Dictionary = _faces[_face]
	return {"face": _face, "items": f.items.duplicate(true), "paint": f.paint.duplicate(), "ink": f.ink.duplicate()}


func _restore(s: Dictionary) -> void:
	if _base == "collier":
		_beads = s.beads
		_bead_refresh()
		return
	_face = s.face
	var f: Dictionary = _faces[_face]
	f.items = s.items
	f.paint = s.paint
	f.ink = s.ink
	f.paint_tex.update(f.paint)
	f.ink_tex.update(f.ink)
	_sel = -1
	_refresh()


func _snap() -> void:
	_undo.append(_state())
	_redo.clear()
	if _undo.size() > UNDO:
		_undo.pop_front()


func _take_back() -> void:
	if _undo.is_empty() or _busy:
		return
	_redo.append(_state())
	_restore(_undo.pop_back())
	Sfx.play("swoosh")


func _do_again() -> void:
	if _redo.is_empty() or _busy:
		return
	_undo.append(_state())
	_restore(_redo.pop_back())
	Sfx.play("swoosh")


# ── Drawing the piece (on the bench and when it is printed) ─────

## The bench itself: a green self-healing cutting mat, with its grid, its heavier lines and the ticks along two edges.
func paint_mat(ci: CanvasItem, area: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, area), Color("#C9DEC2"))
	var fine := Color(0.28, 0.5, 0.32, 0.16)
	var bold := Color(0.28, 0.5, 0.32, 0.3)
	var x := 0.0
	var k := 0
	while x <= area.x:
		ci.draw_line(Vector2(x, 0), Vector2(x, area.y), bold if k % 5 == 0 else fine, 1.6 if k % 5 == 0 else 1.0)
		x += 28.0
		k += 1
	var y := 0.0
	k = 0
	while y <= area.y:
		ci.draw_line(Vector2(0, y), Vector2(area.x, y), bold if k % 5 == 0 else fine, 1.6 if k % 5 == 0 else 1.0)
		y += 28.0
		k += 1
	x = 0.0
	k = 0
	while x <= area.x:
		ci.draw_line(Vector2(x, 0), Vector2(x, 9.0 if k % 5 == 0 else 5.0), Color(0.18, 0.4, 0.24, 0.6), 1.4)
		x += 28.0
		k += 1
	y = 0.0
	k = 0
	while y <= area.y:
		ci.draw_line(Vector2(0, y), Vector2(9.0 if k % 5 == 0 else 5.0, y), Color(0.18, 0.4, 0.24, 0.6), 1.4)
		y += 28.0
		k += 1


func paint_face(ci: CanvasItem, fi: int, overlay: bool) -> void:
	var f: Dictionary = _faces[fi]
	CraftArt.draw_base(ci, _base, fi, picture)
	ci.draw_texture(f.paint_tex, Vector2.ZERO)
	CraftArt.draw_over(ci, _base)
	for it: Dictionary in f.items:
		CraftArt.draw_item(ci, it)
	ci.draw_texture(f.ink_tex, Vector2.ZERO)
	if not overlay:
		return
	# The selected item's frame and handles.
	if _sel >= 0 and _sel < f.items.size() and _tab in ["papier", "decos", "ecrire"]:
		var it: Dictionary = f.items[_sel]
		var h := CraftArt.item_half(it)
		var corners: Array = []
		for p: Vector2 in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
			corners.append(it.at + p.rotated(it.rot))
		for i in 4:
			ci.draw_dashed_line(corners[i], corners[(i + 1) % 4], Color(BLUE, 0.9), 1.8, 6.0)
		var knob := knob_of(it)
		ci.draw_line(it.at + Vector2(0, -h.y if knob.y < it.at.y else h.y).rotated(it.rot), knob, Color(BLUE, 0.9), 1.8)
		ci.draw_circle(knob, 10.0, Color.WHITE)
		ci.draw_arc(knob, 10.0, 0.0, TAU, 20, BLUE, 2.2, true)
		ci.draw_arc(knob, 4.5, 0.6, TAU - 0.6, 12, BLUE, 2.0, true)
		var grip: Vector2 = corners[2]
		ci.draw_rect(Rect2(grip - Vector2(9, 9), Vector2(18, 18)), Color.WHITE)
		ci.draw_rect(Rect2(grip - Vector2(9, 9), Vector2(18, 18)), BLUE, false, 2.2)
		ci.draw_line(grip + Vector2(-3, -3), grip + Vector2(3, 3), BLUE, 2.0)
	# The brush under the mouse.
	if (_tab == "peinture" or _tab == "laine") and _mouse.x >= 0.0 and _tool() != "pot":
		ci.draw_arc(_mouse, _radius(), 0.0, TAU, 24, Color(0.2, 0.2, 0.3, 0.8), 1.5, true)
	elif _tab == "peinture" and _tool() == "pot" and _mouse.x >= 0.0:
		ci.draw_arc(_mouse, 7.0, 0.0, TAU, 16, Color(0.2, 0.2, 0.3), 2.0, true)


# ── The frame's picture ─────────────────────────────────────────

func _pick_picture() -> void:
	if _busy or _cut:
		return
	var names := DrawingPad.gallery_names()
	if names.is_empty():
		return
	var box := Panel.new()
	box.size = Vector2(760, 470)
	box.position = Vector2(240, 110)
	box.z_index = 20
	box.add_theme_stylebox_override("panel", _box(Color.WHITE, BLUE, 5, 22))
	_panel.add_child(box)
	var t := _label("Quel dessin dans le cadre ?", 28, BLUE)
	t.position = Vector2(0, 16)
	t.size = Vector2(760, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(720, 330)
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for n: String in names:
		var img := Image.load_from_file(DrawingPad.gallery_folder() + "/" + n)
		if img == null:
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, 114)
		b.add_theme_stylebox_override("normal", _box(Color.WHITE, Color("#C8A27A"), 2, 8))
		b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 3, 8))
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.position = Vector2(6, 6)
		tr.size = Vector2(158, 102)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tr)
		b.pressed.connect(func() -> void:
			_snap()
			picture = tr.texture
			Sfx.play("pop")
			box.queue_free()
			_stage.queue_redraw())
		grid.add_child(b)
	var close := _button("Garder l'image du cadre", 20, func() -> void: box.queue_free(), Vector2(300, 46))
	close.position = Vector2(230, 410)
	box.add_child(close)


# ── The scissors ────────────────────────────────────────────────

## `scissors`: she cuts it by following the dotted line (false: cut at once).
func _open_cutter(scissors: bool) -> void:
	if _busy or _cut:
		return
	if not scissors:
		_cut_done(true)
		return
	_cut = _Cutter.new()
	_cut.studio = self
	_cut.shape = _shape
	_cut.paper = _paper
	_cut.color = _color
	_cut.size = Vector2(1240, 696)
	_cut.finished.connect(func() -> void: _cut_done(false))
	_cut.cancelled.connect(_close_cutter)
	_panel.add_child(_cut)


func _close_cutter() -> void:
	if _cut:
		_cut.queue_free()
		_cut = null


func _cut_done(quick: bool) -> void:
	_close_cutter()
	Sfx.play("click")
	_new_item({"kind": "paper", "sub": _shape, "pattern": _paper, "color": _color, "s": PAPER_S[_size_i], "cut": true})
	if not quick:
		_toast("Bien découpé !")


# ── Finishing ───────────────────────────────────────────────────

func _count() -> int:
	if _base == "collier":
		return _beads.size()
	var n := 0
	for f: Dictionary in _faces:
		n += f.items.size()
		for k in ["paint", "ink"]:
			var img: Image = f[k]
			if not img.is_invisible():
				n += 2
	return n


func _finish_check() -> void:
	if _busy:
		return
	var need := 6 if _base == "collier" else 3
	if _base == "carte" and not _nudged and _count() >= need:
		var has_words := false
		for it: Dictionary in _faces[1].items:
			has_words = has_words or it.kind == "text"
		if not has_words:
			_nudged = true
			_go_face(1)
			_tab = "ecrire"
			_refresh()
			_toast("Écris un petit mot dans ta carte, dedans !")
			return
	if _count() < need:
		_toast("Ajoute encore quelque chose avant d'avoir fini !" if _base != "collier" else "Enfile encore quelques perles !")
		return
	_busy = true
	_sel = -1
	if _stage:
		_stage.queue_redraw()
	_print()


func _print() -> void:
	var result := {"kind": _base, "who": who}
	if _base == "collier":
		result.image = await _render(func(ci: CanvasItem) -> void: _paint_necklace(ci), Rect2(40, 20, 480, 330))
		result.inside = null
	else:
		# The door goes back on the door as it is: cut to its very edges.
		var rect := CraftArt.base_rect(_base) if _base == "porte" else CraftArt.base_rect(_base).grow(14.0)
		result.image = await _render(func(ci: CanvasItem) -> void: paint_face(ci, 0, false), rect)
		result.inside = null
		if _base == "carte":
			result.inside = await _render(func(ci: CanvasItem) -> void: paint_face(ci, 1, false), rect)
	_celebrate(result)


## Prints what `painter` draws on a transparent sheet, cut to `crop`.
func _render(painter: Callable, crop: Rect2) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(WORK)
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
	return img.get_region(Rect2i(crop.intersection(Rect2(Vector2.ZERO, WORK))))


func _celebrate(result: Dictionary) -> void:
	var veil := ColorRect.new()
	veil.color = Color(0.08, 0.05, 0.12, 0.0)
	veil.size = Vector2(1240, 696)
	_panel.add_child(veil)
	var card := Panel.new()
	card.size = Vector2(620, 560)
	card.position = Vector2(310, 68)
	card.add_theme_stylebox_override("panel", _box(Color("#FFFDF7"), BLUE, 6, 26))
	_panel.add_child(card)
	var t := _label("Ta porte est prête !" if who == "moi" else "Ton bricolage est prêt !", 36, BLUE)
	t.position = Vector2(0, 22)
	t.size = Vector2(620, 50)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t)
	var pic := TextureRect.new()
	pic.texture = ImageTexture.create_from_image(result.image)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.position = Vector2(60, 84)
	pic.size = Vector2(500, 340)
	pic.pivot_offset = pic.size / 2.0
	pic.scale = Vector2.ZERO
	card.add_child(pic)
	var sub := _label("Tout le monde va la voir dans le corridor !" if who == "moi" else "Ça va faire plaisir à %s !" % ("Maman" if who == "maman" else "Papa"), 26, Color(BLUE, 0.85))
	sub.position = Vector2(0, 438)
	sub.size = Vector2(620, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(sub)
	var ok := _button("Sur ma porte ♥" if who == "moi" else "Pour %s ♥" % ("Maman" if who == "maman" else "Papa"), 26, func() -> void:
		Sfx.play("chime")
		closed.emit(result)
		queue_free(), Vector2(300, 62))
	ok.position = Vector2(160, 484)
	ok.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 4, 18))
	card.add_child(ok)
	Sfx.play("chime")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(veil, "color:a", 0.35, 0.3)
	tw.tween_property(pic, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pic, "rotation", 0.0, 0.5).from(-0.15)


func _leave() -> void:
	if _busy:
		return
	if _base == "" or _count() == 0:
		closed.emit({})
		queue_free()
		return
	_confirm_leave()


func _confirm_leave() -> void:
	var box := Panel.new()
	box.size = Vector2(560, 230)
	box.position = Vector2(340, 230)
	box.add_theme_stylebox_override("panel", _box(Color.WHITE, BLUE, 5, 22))
	box.z_index = 20
	_panel.add_child(box)
	var q := _label("Tu veux arrêter ?\nTon bricolage sera perdu.", 28, BLUE)
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


func _toast(text: String) -> void:
	if _toast_label:
		_toast_label.queue_free()
	_toast_label = _label(text, 22, BLUE)
	_toast_label.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	_toast_label.position = Vector2(STAGE_POS.x + 10.0, STAGE_POS.y + WORK.y - 52.0)
	_toast_label.z_index = 10
	_panel.add_child(_toast_label)
	var label := _toast_label
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)


# ── The necklace ────────────────────────────────────────────────

const STRING_FROM := Vector2(70, 40)
const STRING_TO := Vector2(490, 40)
const STRING_SAG := 250.0


func _string_point(t: float) -> Vector2:
	return Vector2(lerpf(STRING_FROM.x, STRING_TO.x, t), STRING_FROM.y + STRING_SAG * (1.0 - pow(2.0 * t - 1.0, 2.0)))


## The beads' centres along the string, each at the arc length its neighbours leave it, and how far in all they take.
func _bead_spots() -> Array:
	var samples := 240
	var lens: Array[float] = [0.0]
	var prev := _string_point(0.0)
	for i in range(1, samples + 1):
		var p := _string_point(float(i) / samples)
		lens.append(lens[i - 1] + prev.distance_to(p))
		prev = p
	var total: float = lens[samples]
	var spots: Array = []
	# The beads are centred on the string, like a necklace held up, not piled at one end.
	var used := 30.0
	for b: Dictionary in _beads:
		used += float(b.r) * 1.12
	var at := 30.0 + maxf(0.0, ((total - 30.0) - used) * 0.5)
	var start_used := used
	for b: Dictionary in _beads:
		var span: float = b.r * 1.12
		var mid := at + span * 0.5
		var t := 1.0
		for i in range(1, samples + 1):
			if lens[i] >= mid:
				t = float(i) / samples
				break
		var p := _string_point(t)
		var q := _string_point(minf(1.0, t + 0.01))
		var q0 := _string_point(maxf(0.0, t - 0.01))
		spots.append({"p": p, "dir": (q - q0).angle()})
		at += span
	return [spots, start_used, total - 30.0]


func _build_beads() -> void:
	_clear_panel()
	_title = _label("Un collier pour %s" % ("Maman" if who == "maman" else "Papa"), 30, BLUE)
	_title.position = Vector2(0, 14)
	_title.size = Vector2(1240, 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)
	_colors_grid()
	_sidebar_colors.position = Vector2(20, 142)
	var cl := _label("Couleur des pâtes\net des perles", 18, Color(BLUE, 0.8))
	cl.position = Vector2(20, 76)
	cl.size = Vector2(200, 56)
	_panel.add_child(cl)
	var frame := Panel.new()
	frame.position = STAGE_POS - Vector2(8, 8)
	frame.size = WORK + Vector2(16, 16)
	frame.add_theme_stylebox_override("panel", _box(Color("#F3E7D3"), Color("#C8A27A"), 5, 10))
	_panel.add_child(frame)
	_bead_stage = _BeadStage.new()
	_bead_stage.studio = self
	_bead_stage.position = STAGE_POS
	_bead_stage.size = WORK
	_bead_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_bead_stage)
	_hint = _label("", 19, Color(BLUE, 0.85))
	_hint.position = Vector2(STAGE_POS.x, STAGE_POS.y + WORK.y + 14)
	_hint.size = Vector2(WORK.x, 60)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_hint)
	_options = Control.new()
	_options.position = Vector2(STAGE_POS.x + WORK.x + 24, 72)
	_options.size = Vector2(396, 540)
	_panel.add_child(_options)
	var bar := HBoxContainer.new()
	bar.position = Vector2(20, 640)
	bar.size = Vector2(1200, 46)
	bar.add_theme_constant_override("separation", 8)
	_panel.add_child(bar)
	bar.add_child(_button("Défaire", 19, _bead_undo, Vector2(110, 46)))
	bar.add_child(_button("Tout enlever", 19, func() -> void:
		if not _beads.is_empty():
			_snap()
			_beads.clear()
			_bead_refresh(), Vector2(150, 46)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_button("Arrêter", 19, _leave, Vector2(110, 46)))
	var done := _button("C'est fini !", 22, _finish_check, Vector2(190, 46))
	done.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	bar.add_child(done)
	_bead_refresh()


func _bead_refresh() -> void:
	for child in _sidebar_colors.get_children():
		_sidebar_colors.remove_child(child)
		child.queue_free()
	for hex: String in CraftArt.PALETTE:
		var c := Color(hex)
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 28)
		var picked := c.is_equal_approx(_color)
		b.add_theme_stylebox_override("normal", _box(c, YELLOW if picked else c.darkened(0.35), 4 if picked else 2, 8))
		b.add_theme_stylebox_override("hover", _box(c.lightened(0.15), BLUE, 3, 8))
		b.pressed.connect(func() -> void:
			_color = c
			_bead_refresh())
		_sidebar_colors.add_child(b)
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	var flow := HFlowContainer.new()
	flow.size = Vector2(396, 270)
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_options.add_child(flow)
	for bd: Array in CraftArt.BEADS:
		var id: String = bd[0]
		var b2 := _IconButton.new()
		b2.custom_minimum_size = Vector2(90, 82)
		var picked2 := id == _bead
		b2.add_theme_stylebox_override("normal", _box(Color("#FFF4C2") if picked2 else Color.WHITE, YELLOW if picked2 else BLUE, 4 if picked2 else 1, 12))
		b2.add_theme_stylebox_override("hover", _box(Color("#FFF8DC"), BLUE, 2, 12))
		var col := _color
		b2.paint = func(ci: CanvasItem, c: Vector2) -> void:
			CraftArt.bead(ci, id, c + Vector2(0, -8), 44.0, Color(0.9, 0.9, 0.9, 1.0) if id in ["macaroni", "penne", "rigatoni", "roue", "farfalle"] and col.is_equal_approx(Color("#FFFFFF")) else col, 0.0)
		b2.pressed.connect(func() -> void:
			_bead = id
			_add_bead(id))
		flow.add_child(b2)
		var nm := _label(bd[1], 14, Color(BLUE, 0.8))
		nm.position = Vector2(0, 0)
		nm.size = Vector2(90, 20)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = Vector2(0, 60)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b2.add_child(nm)
	var y := 292.0
	var sl := _label("Grosseur", 18, Color(BLUE, 0.8))
	sl.position = Vector2(0, y)
	_options.add_child(sl)
	var x := 96.0
	for s: Array in SIZES:
		var sb := Button.new()
		sb.text = s[0]
		sb.position = Vector2(x, y - 6)
		sb.size = Vector2(90, 40)
		sb.add_theme_font_size_override("font_size", 17)
		sb.add_theme_color_override("font_color", BLUE)
		sb.add_theme_stylebox_override("normal", _box(YELLOW if s[1] == _size_i else Color.WHITE, BLUE, 2, 12))
		sb.pressed.connect(func() -> void:
			_size_i = s[1]
			_bead_refresh())
		_options.add_child(sb)
		x += 96.0
	var wl := _label("Un mot en perles :", 18, Color(BLUE, 0.8))
	wl.position = Vector2(0, y + 56.0)
	_options.add_child(wl)
	_word = LineEdit.new()
	_word.position = Vector2(0, y + 88.0)
	_word.size = Vector2(250, 46)
	_word.max_length = 10
	_word.placeholder_text = "MAMAN"
	_word.add_theme_font_size_override("font_size", 22)
	_word.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 12))
	_word.add_theme_stylebox_override("focus", _box(Color.WHITE, YELLOW, 3, 12))
	_word.text_submitted.connect(func(t: String) -> void: _add_word(t))
	_options.add_child(_word)
	var wb := _button("Enfiler", 20, func() -> void: _add_word(_word.text), Vector2(136, 46))
	wb.position = Vector2(260, y + 88.0)
	wb.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
	_options.add_child(wb)
	var info := _bead_spots()
	var room: float = info[2] - info[1]
	_hint.text = "Clique sur une perle ou une pâte pour l'enfiler. Choisis la couleur d'abord : tu peux peindre les pâtes !" if room > 40.0 \
		else "Ton collier est plein : il est magnifique ! Appuie sur « C'est fini ! »."
	_bead_stage.queue_redraw()


func _add_bead(id: String, letter := "") -> void:
	if _busy:
		return
	var r: float = [34.0, 46.0, 60.0][_size_i]
	var info := _bead_spots()
	if info[1] + r * 1.12 > info[2]:
		_toast("Le collier est plein !")
		return
	_snap()
	_beads.append({"id": id, "color": _color, "r": r, "letter": letter, "drop": 1.0})
	Sfx.play("pop")
	var bead: Dictionary = _beads[_beads.size() - 1]
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		bead.drop = v
		_bead_stage.queue_redraw(), 1.0, 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_bead_refresh()


func _add_word(text: String) -> void:
	var t := text.strip_edges().to_upper()
	if t.is_empty():
		return
	for ch in t:
		if ch != " ":
			_add_bead("lettre", ch)
	if _word:
		_word.text = ""


func _bead_undo() -> void:
	if _beads.is_empty() or _busy:
		return
	_snap()
	_beads.pop_back()
	Sfx.play("swoosh")
	_bead_refresh()


func _paint_necklace(ci: CanvasItem) -> void:
	var info := _bead_spots()
	var spots: Array = info[0]
	# A hanging loop of string, the ribbon bow at its top, then the beads over it.
	var pts := PackedVector2Array()
	for k in 61:
		pts.append(_string_point(k / 60.0))
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(4, 9))
	ci.draw_polyline(shadow, Color(0.35, 0.2, 0.08, 0.16), 6.0, true)
	# Twine: a dark core, the lit strand, and the short slanting marks of its twist.
	ci.draw_polyline(pts, Color("#6E4E3A"), 4.4, true)
	ci.draw_polyline(pts, Color("#B58C68"), 3.0, true)
	for k in range(1, 120):
		var t := k / 120.0
		var a := _string_point(t)
		var b := _string_point(minf(1.0, t + 0.004))
		var n := (b - a).normalized().orthogonal()
		var mid := (a + b) * 0.5
		ci.draw_line(mid - n * 1.8 - (b - a).normalized() * 1.2, mid + n * 1.8 + (b - a).normalized() * 1.2, Color("#6E4E3A", 0.7), 1.0, true)
	for s in [STRING_FROM, STRING_TO]:
		# A little brass ring with the string tied through it.
		ci.draw_circle(s + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.14))
		ci.draw_circle(s, 9.0, Color("#8A6410"))
		ci.draw_circle(s + Vector2(-0.6, -0.8), 7.4, Color("#D9A82B"))
		ci.draw_circle(s, 3.6, Color("#EBD9BD"))
		ci.draw_arc(s, 3.6, 0.0, TAU, 12, Color("#8A6410"), 1.2, true)
		ci.draw_circle(s + Vector2(-3.4, -3.8), 1.8, Color(1, 1, 1, 0.8))
	for i in _beads.size():
		var b: Dictionary = _beads[i]
		var p: Vector2 = spots[i].p
		var drop: float = b.get("drop", 0.0)
		var c := p + Vector2(0, -drop * 140.0)
		var col: Color = b.color
		CraftArt.bead(ci, b.id, c, b.r, col, spots[i].dir if b.id != "lettre" else 0.0, i)
		if b.id == "lettre":
			var font := ThemeDB.fallback_font
			var size := int(b.r * 0.62)
			var w := font.get_string_size(b.letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			ci.draw_string(font, c + Vector2(-w * 0.5, size * 0.35), b.letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col.darkened(0.25) if col.get_luminance() > 0.3 else col.lightened(0.2))


# ── Keeping crafts ──────────────────────────────────────────────

const PENDING_FLAG := "bricolage"


static func folder() -> String:
	return GameState.slot_dir() + "/bricolages"


static func pending_path(inside := false) -> String:
	return GameState.slot_dir() + ("/bricolage_a_rapporter_dedans.png" if inside else "/bricolage_a_rapporter.png")


## The craft she made at the service de garde, waiting to be given at home.
static func hold_pending(result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(GameState.slot_dir())
	(result.image as Image).save_png(pending_path())
	if result.inside != null:
		(result.inside as Image).save_png(pending_path(true))
	elif FileAccess.file_exists(pending_path(true)):
		DirAccess.remove_absolute(pending_path(true))
	GameState.flags[PENDING_FLAG] = {"kind": result.kind, "who": result.who}


static func has_pending() -> bool:
	return GameState.flags.has(PENDING_FLAG) and FileAccess.file_exists(pending_path())


## {image, inside (or null), kind, who} of the pending craft.
static func pending() -> Dictionary:
	if not has_pending():
		return {}
	var meta: Dictionary = GameState.flags[PENDING_FLAG]
	var inside: Image = Image.load_from_file(pending_path(true)) if FileAccess.file_exists(pending_path(true)) else null
	return {"image": Image.load_from_file(pending_path()), "inside": inside, "kind": meta.kind, "who": meta.who}


static func clear_pending() -> void:
	GameState.flags.erase(PENDING_FLAG)
	for inside in [false, true]:
		if FileAccess.file_exists(pending_path(inside)):
			DirAccess.remove_absolute(pending_path(inside))


static func pending_for() -> String:
	return GameState.flags.get(PENDING_FLAG, {}).get("who", "")


## What a craft is called, with its article: "ta carte", "ton collier".
static func name_of(kind: String) -> String:
	return str(CraftArt.BASES[kind][0]).to_lower() if CraftArt.BASES.has(kind) else "bricolage"


## The pending craft is given: kept for the parents' shelf (the newest KEEP_MAX), no longer pending.
static func keep_pending() -> void:
	var entry := pending()
	if entry.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(folder())
	var stamp := str(int(Time.get_unix_time_from_system() * 1000.0))
	var base := "%s/%s_%s_%s" % [folder(), stamp, entry.kind, entry.who]
	(entry.image as Image).save_png(base + ".png")
	if entry.inside != null:
		(entry.inside as Image).save_png(base + "_dedans.png")
	clear_pending()
	var names := _kept_names()
	while names.size() > KEEP_MAX:
		var old: String = names.pop_front()
		DirAccess.remove_absolute(folder() + "/" + old)
		var inside_name := old.replace(".png", "_dedans.png")
		if FileAccess.file_exists(folder() + "/" + inside_name):
			DirAccess.remove_absolute(folder() + "/" + inside_name)


## Julien: what she gave to her parents doesn't stay on the table or the desk, it goes away: removes any craft kept by an
## older version of the game.
static func clear_kept() -> void:
	for n: String in _kept_names():
		DirAccess.remove_absolute(folder() + "/" + n)
		var inside_name := n.replace(".png", "_dedans.png")
		if FileAccess.file_exists(folder() + "/" + inside_name):
			DirAccess.remove_absolute(folder() + "/" + inside_name)


static func _kept_names() -> Array:
	var dir := DirAccess.open(folder())
	if dir == null:
		return []
	var names := Array(dir.get_files()).filter(func(n: String) -> bool: return n.ends_with(".png") and not n.ends_with("_dedans.png"))
	names.sort()
	return names


## The crafts the parents have, oldest first: {image, inside, kind, who}.
static func kept() -> Array:
	var out: Array = []
	for n: String in _kept_names():
		var parts := n.trim_suffix(".png").split("_")
		if parts.size() < 3:
			continue
		var inside_path := folder() + "/" + n.replace(".png", "_dedans.png")
		out.append({"image": Image.load_from_file(folder() + "/" + n), "inside": Image.load_from_file(inside_path) if FileAccess.file_exists(inside_path) else null,
			"kind": parts[1], "who": parts[2]})
	return out


## The craft shown big when it is handed over (a card opens on a click). `done` comes when she closes it.
static func reveal(parent: Node, entry: Dictionary) -> _Reveal:
	var r := _Reveal.new()
	r.entry = entry
	parent.add_child(r)
	return r


static func forget_all() -> void:
	clear_pending()
	var dir := DirAccess.open(folder())
	if dir == null:
		return
	for n in dir.get_files():
		dir.remove(n)


# ── Little builders ─────────────────────────────────────────────

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
	b.content_margin_left = 12
	b.content_margin_right = 12
	return b


# ── Parts ───────────────────────────────────────────────────────

## The piece on the bench.
class _Stage:
	extends Control

	var studio: CraftStudio

	func _draw() -> void:
		studio.paint_mat(self, size)
		studio.paint_face(self, studio._face, true)

	func _gui_input(event: InputEvent) -> void:
		studio.stage_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			studio._mouse = Vector2(-1, -1)
			queue_redraw()


## The necklace on its bench.
class _BeadStage:
	extends Control

	var studio: CraftStudio

	func _draw() -> void:
		# A felt mat on the craft table: warm, with a faint weave, a stitched border and a soft shadow under the string's loop.
		draw_rect(Rect2(Vector2.ZERO, size), Color("#EBD9BD"))
		var weave := Color(0.62, 0.45, 0.25, 0.07)
		for k in int(size.y / 14.0):
			draw_line(Vector2(0, k * 14.0), Vector2(size.x, k * 14.0), weave, 1.0)
		for k in int(size.x / 14.0):
			draw_line(Vector2(k * 14.0, 0), Vector2(k * 14.0, size.y), weave, 1.0)
		var inset := Rect2(Vector2(14, 14), size - Vector2(28, 28))
		var x := inset.position.x
		while x < inset.end.x:
			var dash := minf(9.0, inset.end.x - x)
			draw_line(Vector2(x, inset.position.y), Vector2(x + dash, inset.position.y), Color("#C98F6B"), 2.0)
			draw_line(Vector2(x, inset.end.y), Vector2(x + dash, inset.end.y), Color("#C98F6B"), 2.0)
			x += 15.0
		var y := inset.position.y
		while y < inset.end.y:
			var dash2 := minf(9.0, inset.end.y - y)
			draw_line(Vector2(inset.position.x, y), Vector2(inset.position.x, y + dash2), Color("#C98F6B"), 2.0)
			draw_line(Vector2(inset.end.x, y), Vector2(inset.end.x, y + dash2), Color("#C98F6B"), 2.0)
			y += 15.0
		studio._paint_necklace(self)


## What a printed craft is drawn by.
class _Printer:
	extends Node2D

	var painter: Callable

	func _draw() -> void:
		painter.call(self)


## What she hands over, held up for the parent to see.
class _Reveal:
	extends CanvasLayer

	signal done

	var entry := {}
	var _pic: TextureRect
	var _open := false
	var _flip: Button

	func _init() -> void:
		layer = 62

	func _ready() -> void:
		add_to_group("modal")
		var dim := ColorRect.new()
		dim.color = Color(0.08, 0.05, 0.12, 0.55)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var card := Panel.new()
		card.position = Vector2(300, 60)
		card.size = Vector2(680, 600)
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#FFFDF7")
		box.border_color = CraftStudio.BLUE
		box.set_border_width_all(6)
		box.set_corner_radius_all(26)
		card.add_theme_stylebox_override("panel", box)
		add_child(card)
		var who_name := "Maman" if entry.who == "maman" else "Papa"
		var t := Label.new()
		t.text = "Pour %s, de Chachoue !" % who_name
		t.add_theme_font_size_override("font_size", 34)
		t.add_theme_color_override("font_color", CraftStudio.BLUE)
		t.position = Vector2(0, 22)
		t.size = Vector2(680, 50)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(t)
		_pic = TextureRect.new()
		_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_pic.position = Vector2(60, 90)
		_pic.size = Vector2(560, 400)
		_pic.pivot_offset = _pic.size / 2.0
		_pic.texture = ImageTexture.create_from_image(entry.image)
		card.add_child(_pic)
		var ok := Button.new()
		ok.text = "Merci, ma chouette !"
		ok.position = Vector2(40 if entry.inside != null else 170, 520)
		ok.size = Vector2(380 if entry.inside != null else 340, 60)
		ok.add_theme_font_size_override("font_size", 26)
		ok.add_theme_color_override("font_color", CraftStudio.BLUE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = CraftStudio.YELLOW
		sb.border_color = CraftStudio.BLUE
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		ok.add_theme_stylebox_override("normal", sb)
		ok.pressed.connect(func() -> void:
			done.emit()
			queue_free())
		card.add_child(ok)
		if entry.inside != null:
			_flip = Button.new()
			_flip.text = "Ouvrir la carte"
			_flip.position = Vector2(440, 520)
			_flip.size = Vector2(200, 60)
			_flip.add_theme_font_size_override("font_size", 19)
			_flip.add_theme_color_override("font_color", CraftStudio.BLUE)
			var fb := sb.duplicate()
			fb.bg_color = Color.WHITE
			_flip.add_theme_stylebox_override("normal", fb)
			_flip.pressed.connect(_toggle)
			card.add_child(_flip)
		_pic.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(_pic, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _toggle() -> void:
		_open = not _open
		var tw := create_tween()
		tw.tween_property(_pic, "scale:x", 0.0, 0.15)
		tw.tween_callback(func() -> void:
			_pic.texture = ImageTexture.create_from_image(entry.inside if _open else entry.image)
			_flip.text = "Fermer la carte" if _open else "Ouvrir la carte")
		tw.tween_property(_pic, "scale:x", 1.0, 0.15)
		Sfx.play("page")


## A button with a little drawing on it instead of words.
class _IconButton:
	extends Button

	var paint: Callable

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self, size / 2.0)


## What a card shows of the thing to make.
class _CardPicture:
	extends Control

	var base := ""
	var picture: Texture2D

	func _draw() -> void:
		if base == "collier":
			var pts := PackedVector2Array()
			for k in 31:
				var t := k / 30.0
				pts.append(Vector2(lerpf(20, 180, t), 30 + 150.0 * (1.0 - pow(2.0 * t - 1.0, 2.0))))
			draw_polyline(pts, Color("#8D6E63"), 3.0, true)
			var ids := ["macaroni", "ronde", "farfalle", "etoile", "penne", "coeur", "roue", "ronde", "rigatoni"]
			var cols := ["#EBC879", "#E04F5F", "#4FA3E0", "#FFD23F", "#FF7BA3", "#E04F5F", "#EBC879", "#7CCB5A", "#EBC879"]
			for k in ids.size():
				var t2 := 0.12 + k * 0.095
				var p := Vector2(lerpf(20, 180, t2), 30 + 150.0 * (1.0 - pow(2.0 * t2 - 1.0, 2.0)))
				CraftArt.bead(self, ids[k], p, 34.0, Color(cols[k]), 0.0)
			return
		var rect := CraftArt.base_rect(base)
		var k2 := minf(size.x / rect.size.x, size.y / rect.size.y) * 0.92
		draw_set_transform((size - rect.size * k2) * 0.5 - rect.position * k2, 0.0, Vector2(k2, k2))
		CraftArt.draw_base(self, base, 0, picture)
		CraftArt.draw_over(self, base)
		var c := rect.get_center()
		match base:
			"carte":
				CraftArt.draw_item(self, {"kind": "paper", "sub": "coeur", "pattern": "pois", "color": Color("#E04F5F"), "s": 150.0, "at": c + Vector2(0, -20), "rot": 0.2, "seed": 3})
				CraftArt.draw_item(self, {"kind": "text", "text": "Maman", "style": "banderole", "color": Color("#4FA3E0"), "s": 30.0, "at": c + Vector2(0, 100), "rot": 0.0})
			"assiette":
				CraftArt.draw_item(self, {"kind": "deco", "sub": "yeux", "color": Color.WHITE, "s": 70.0, "at": c + Vector2(0, -30), "rot": 0.0, "seed": 1})
				CraftArt.draw_item(self, {"kind": "deco", "sub": "bouche", "color": Color("#E04F5F"), "s": 70.0, "at": c + Vector2(0, 70), "rot": 0.0, "seed": 1})
				CraftArt.draw_item(self, {"kind": "deco", "sub": "pompon", "color": Color("#FF8A3D"), "s": 60.0, "at": c + Vector2(-90, -120), "rot": 0.0, "seed": 4})
				CraftArt.draw_item(self, {"kind": "deco", "sub": "pompon", "color": Color("#FF8A3D"), "s": 60.0, "at": c + Vector2(90, -120), "rot": 0.0, "seed": 5})
			"pot":
				CraftArt.draw_item(self, {"kind": "paper", "sub": "etoile", "pattern": "uni", "color": Color("#FFD23F"), "s": 110.0, "at": c + Vector2(0, 90), "rot": 0.0, "seed": 2})
				CraftArt.draw_item(self, {"kind": "deco", "sub": "noeud", "color": Color("#E04F5F"), "s": 60.0, "at": c + Vector2(0, 30), "rot": 0.0, "seed": 1})
			"cadre":
				for p: Vector2 in [Vector2(-170, -130), Vector2(170, -130), Vector2(-170, 130), Vector2(170, 130)]:
					CraftArt.draw_item(self, {"kind": "deco", "sub": "marguerite", "color": Color.WHITE, "s": 36.0, "at": c + p, "rot": 0.0, "seed": 1})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The scissors: she drags along the dotted line of the shape and it comes away from the sheet.
class _Cutter:
	extends Control

	signal finished
	signal cancelled

	var studio: CraftStudio
	var shape := "coeur"
	var paper := "uni"
	var color := Color("#E04F5F")
	var path := PackedVector2Array()
	var cut := PackedByteArray()
	var last := -1
	var mouse := Vector2.ZERO
	var snip := 0.0
	var pressing := false
	var _done_emitted := false
	const CENTER := Vector2(620, 330)
	const SIZE := 280.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var pts := CraftArt.shape_points(shape, SIZE)
		# The outline walked every 6 px, so progress is a count of the dots she has passed.
		var out := PackedVector2Array()
		var n := pts.size()
		for i in n:
			var a := pts[i]
			var b := pts[(i + 1) % n]
			var steps := maxi(1, int(a.distance_to(b) / 6.0))
			for k in steps:
				out.append(CENTER + a.lerp(b, float(k) / steps))
		path = out
		cut.resize(path.size())
		var quit := Button.new()
		quit.text = "Vite, découpe-la pour moi"
		quit.position = Vector2(450, 626)
		quit.size = Vector2(340, 46)
		quit.add_theme_font_size_override("font_size", 19)
		quit.add_theme_color_override("font_color", CraftStudio.BLUE)
		quit.add_theme_stylebox_override("normal", studio._box(Color.WHITE, CraftStudio.BLUE, 2, 14))
		quit.pressed.connect(func() -> void:
			_done_emitted = true
			finished.emit())
		add_child(quit)
		var back := Button.new()
		back.text = "Annuler"
		back.position = Vector2(1070, 626)
		back.size = Vector2(130, 46)
		back.add_theme_font_size_override("font_size", 19)
		back.add_theme_color_override("font_color", CraftStudio.BLUE)
		back.add_theme_stylebox_override("normal", studio._box(Color.WHITE, CraftStudio.BLUE, 2, 14))
		back.pressed.connect(func() -> void: cancelled.emit())
		add_child(back)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			pressing = event.pressed
			if not event.pressed:
				last = -1
			mouse = event.position
			_advance()
		elif event is InputEventMouseMotion:
			mouse = event.position
			if pressing:
				_advance()
			queue_redraw()

	# The nearest dot to the scissors; if it is just ahead of where she last cut, the line is cut up to it.
	func _advance() -> void:
		var best := -1
		var best_d := 30.0
		for i in path.size():
			var d := mouse.distance_to(path[i])
			if d < best_d:
				best_d = d
				best = i
		if best < 0:
			return
		var n := path.size()
		if last < 0:
			last = best
		else:
			var fwd := (best - last + n) % n
			if fwd > n / 2:
				fwd -= n
			if fwd >= -2 and fwd <= 14:
				var step := 1 if fwd >= 0 else -1
				var i := last
				while i != best:
					cut[i] = 1
					i = (i + step + n) % n
				cut[best] = 1
				if fwd != 0:
					snip += 1.0
					if int(snip) % 4 == 0:
						Sfx.play("click")
				last = best
		queue_redraw()
		var count := 0
		for v in cut:
			count += v
		if count >= int(path.size() * 0.95) and not _done_emitted:
			_done_emitted = true
			finished.emit()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.12, 0.8))
		var sheet := Rect2(CENTER - Vector2(210, 210), Vector2(420, 420))
		draw_rect(Rect2(sheet.position + Vector2(6, 8), sheet.size), Color(0, 0, 0, 0.3))
		draw_rect(sheet, color)
		draw_set_transform(CENTER, 0.0, Vector2.ONE)
		CraftArt.draw_paper(self, {"kind": "paper", "sub": "carre", "s": 466.0, "color": color, "pattern": paper, "seed": 1, "cut": false})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(sheet, Color(1, 1, 1, 0.3), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, 52), "Découpe le long des pointillés : garde le bouton enfoncé", HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(0, 88), "et glisse les ciseaux sur la ligne.", HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(1, 1, 1, 0.8))
		for i in path.size():
			var next := path[(i + 1) % path.size()]
			if cut[i] == 1:
				draw_line(path[i], next, Color(0, 0, 0, 0.55), 6.0, true)
				draw_line(path[i] + Vector2(1, 1), next + Vector2(1, 1), Color(1, 1, 1, 0.5), 1.5, true)
			elif i % 2 == 0:
				draw_line(path[i], next, Color(0.1, 0.05, 0.15, 0.55), 6.0, true)
				draw_line(path[i], next, Color(1, 1, 1, 0.95), 3.0, true)
		# The scissors, open and shut as she goes.
		var open := 0.25 + 0.2 * absf(sin(snip * 0.9))
		var dir := Vector2.RIGHT
		if last >= 0:
			dir = (path[(last + 3) % path.size()] - path[(last + path.size() - 3) % path.size()]).normalized()
		draw_set_transform(mouse, dir.angle(), Vector2.ONE)
		for s in [-1.0, 1.0]:
			var blade := PackedVector2Array([Vector2(0, 0), Vector2(44, s * 44.0 * open * 0.5), Vector2(46, s * 44.0 * open * 0.5 + s * 5.0), Vector2(0, s * 8.0)])
			draw_colored_polygon(blade, Color("#C9D3DC"))
			draw_polyline(blade, Color("#5A6472"), 1.5, true)
			draw_arc(Vector2(-18, s * 16.0), 12.0, 0.0, TAU, 14, Color("#E04F5F"), 5.0, true)
		draw_circle(Vector2(0, 0), 4.0, Color("#5A6472"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

