class_name BookReader
extends CanvasLayer
## Charlotte's books, opened from the shelf in her bedroom: pick a book, then turn the pages (a little
## picture on the left, the story on the right). All the stories are original, written for the game.

signal closed

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
## Where the picture and the words sit on the open book, so a page can slide in from the right place.
const ART_AT := Vector2(66, 92)
const TEXT_AT := Vector2(556, 138)
const BOOKS := [
	{"title": "La noix de Noisette", "cover": "#B5603F", "pages": [
		["nut", "Noisette est un écureuil de la 6e Avenue. Un matin d'automne, il trouve la plus belle noix de toute la rue."],
		["dig", "« Je vais la cacher pour l'hiver », dit-il. Il creuse un petit trou au pied d'un érable et la recouvre de feuilles."],
		["snow", "L'hiver arrive. La neige recouvre tout. Noisette cherche, cherche… mais il ne se souvient plus où est sa noix !"],
		["sprout", "Au printemps, au pied de l'érable, une petite pousse verte sort de la terre. C'est sa noix, devenue un bébé arbre."],
		["tree", "Noisette sourit. « Un jour, cet arbre me donnera des centaines de noix. » Et il va chercher une autre cachette. Fin."],
	]},
	{"title": "Minou et la lune", "cover": "#2E3440", "pages": [
		["cat", "Minou est un chat gris qui vit sur un balcon. Chaque soir, il regarde la lune briller au-dessus des toits."],
		["moon", "« Elle a l'air d'un grand bol de lait », pense Minou. « Si je saute assez haut, je pourrai y goûter. »"],
		["jump", "Il saute sur la rampe, puis sur la corde à linge… Hop ! Il manque de tomber dans les feuilles."],
		["bowl", "En bas, une petite fille lui tend un bol de lait. La lune s'y reflète, toute ronde."],
		["sleep", "Minou boit la lune à petites gorgées, puis s'endort en ronronnant. Fin."],
	]},
	{"title": "La fusée de carton", "cover": "#4FA3E0", "pages": [
		["box", "Il pleut. Léa trouve une grande boîte de carton dans le bac de recyclage."],
		["rocket", "Avec des crayons, un peu de ruban et beaucoup d'imagination, la boîte devient une fusée."],
		["stars", "« Trois, deux, un… décollage ! » La fusée traverse les nuages et file entre les étoiles."],
		["planet", "Sur une planète violette, des petits extraterrestres jouent à la marelle. Léa joue avec eux jusqu'au soir."],
		["home", "« Léa, le souper est prêt ! » La fusée atterrit dans le salon, juste à temps. Fin."],
	]},
	{"title": "La ruelle aux trésors", "cover": "#5E8A4A", "pages": [
		["lane", "Derrière chez elle, il y a une ruelle. Mia dit que c'est le plus beau chemin du quartier."],
		["croque", "Au milieu de la ruelle, un croque-livre attend. « On prend un livre, on en laisse un », dit la pancarte."],
		["treasure", "Mia y trouve un livre tout abîmé, avec une carte dessinée à la main sur la dernière page."],
		["digging", "La carte mène au vieil érable du fond. Sous une pierre plate : une boîte de fer-blanc pleine de billes."],
		["friends", "Mia remet la boîte sous la pierre et laisse la carte dans le croque-livre. Pour le prochain. Fin."],
	]},
	{"title": "Le hibou de la 5e Avenue", "cover": "#3E4A6B", "pages": [
		["owl", "Quand tout le monde dort, un grand hibou se perche sur le fil de la 5e Avenue."],
		["roofs", "De là-haut, il voit les toits, les ruelles, et la lumière de la cuisine des gens qui veillent."],
		["mouse", "Il voit aussi une petite souris qui traverse en vitesse. « Bonne nuit, la souris », pense le hibou."],
		["nest", "Au matin, il rentre dans le gros arbre du parc, où trois bébés hiboux l'attendent en piaillant."],
		["dawn", "Le soleil se lève sur la 5e Avenue. Le hibou ferme un œil, puis l'autre. À ce soir. Fin."],
	]},
	{"title": "Caramel veut voir la neige", "cover": "#E8A65A", "pages": [
		["hamster", "Caramel est un hamster qui vit dans un grand terrarium, près d'une fenêtre."],
		["window", "Dehors, de petits flocons blancs tombent du ciel. « Qu'est-ce que c'est ? » se demande Caramel."],
		["snowball", "Charlotte rentre de l'école avec une boule de neige dans sa mitaine. Elle la montre à Caramel."],
		["melt", "Caramel la touche du bout du nez. C'est froid ! La boule fond et devient une petite flaque."],
		["sleep", "« La neige, c'est de l'eau qui fait un câlin froid », décide Caramel, avant de faire la sieste. Fin."],
	]},
]

## Set before it is added to the tree to open straight on that book (the twins' found book), instead of the shelf.
var start_book := -1
var _book := -1
var _page := 0
var _panel: Panel
var _art: _Art
var _text: RichTextLabel
var _title: Label
var _prev: Button
var _next: Button
var _shelf: HBoxContainer
var _spread: Control
var _shelf_board: _Shelf
var _turn_dir := 1


func _init() -> void:
	layer = 60


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(120, 60)
	_panel.size = Vector2(1040, 600)
	_panel.add_theme_stylebox_override("panel", _box(Color("#F6EFE4"), BLUE, 6, 26))
	root.add_child(_panel)
	_title = _label("Les livres de Charlotte", 30)
	_title.position = Vector2(0, 16)
	_title.size = Vector2(1040, 40)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)
	_shelf_board = _Shelf.new()
	_shelf_board.position = Vector2(26, 96)
	_shelf_board.size = Vector2(988, 400)
	_shelf_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_shelf_board)
	_shelf = HBoxContainer.new()
	_shelf.position = Vector2(44, 128)
	_shelf.add_theme_constant_override("separation", 18)
	_shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_shelf)
	for i in BOOKS.size():
		# Each book is a little taller or shorter than its neighbour, as on a real shelf.
		var tall := 238.0 + float((i * 5) % 3) * 12.0
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(146, 278)
		var b := Button.new()
		b.position = Vector2(0, 278.0 - tall)
		b.size = Vector2(146, tall)
		b.flat = true
		b.pressed.connect(_open_book.bind(i))
		var cover := _Cover.new()
		cover.kind = BOOKS[i].pages[0][0]
		cover.title = BOOKS[i].title
		cover.band = Color(BOOKS[i].cover)
		cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cover)
		# It lifts a little off the shelf when the mouse is on it.
		b.mouse_entered.connect(func() -> void: _lift(b, -10.0, 278.0 - tall))
		b.mouse_exited.connect(func() -> void: _lift(b, 0.0, 278.0 - tall))
		holder.add_child(b)
		_shelf.add_child(holder)
	# The open book: two cream pages with a fold down the middle, the picture on the left, the words on the right.
	_spread = _Spread.new()
	_spread.position = Vector2(34, 70)
	_spread.size = Vector2(972, 430)
	_spread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spread.visible = false
	_panel.add_child(_spread)
	_art = _Art.new()
	_art.position = ART_AT
	_art.size = Vector2(404, 386)
	_art.clip_contents = true
	_art.visible = false
	_panel.add_child(_art)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.position = Vector2(TEXT_AT.x, TEXT_AT.y)
	_text.size = Vector2(404, 300)
	_text.add_theme_font_size_override("normal_font_size", 26)
	_text.add_theme_color_override("default_color", Color("#3A2A1E"))
	_text.visible = false
	_panel.add_child(_text)
	var bar := HBoxContainer.new()
	bar.position = Vector2(40, 520)
	bar.size = Vector2(960, 56)
	bar.add_theme_constant_override("separation", 14)
	_panel.add_child(bar)
	_prev = _button(bar, "‹ Page précédente", func(): _turn(-1))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_button(bar, "Fermer", _close)
	_next = _button(bar, "Page suivante ›", func(): _turn(1))
	if start_book >= 0 and start_book < BOOKS.size():
		_book = start_book
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif _book >= 0 and event.is_action_pressed("ui_right"):
		_turn(1)
	elif _book >= 0 and event.is_action_pressed("ui_left"):
		_turn(-1)


func _open_book(i: int) -> void:
	Sfx.play("page")
	_book = i
	_page = 0
	_show()


func _turn(dir: int) -> void:
	Sfx.play("page")
	_turn_dir = dir
	var pages: Array = BOOKS[_book].pages
	_page += dir
	if _page < 0:
		# Back from the first page: the shelf again.
		_book = -1
	elif _page >= pages.size():
		_book = -1
	_show()


func _show() -> void:
	var reading := _book >= 0
	_shelf.visible = not reading
	_shelf_board.visible = not reading
	_spread.visible = reading
	_art.visible = reading
	_text.visible = reading
	_prev.visible = reading
	_next.visible = reading
	if not reading:
		_title.text = "Les livres de Charlotte"
		return
	var pages: Array = BOOKS[_book].pages
	_title.text = BOOKS[_book].title
	_art.kind = pages[_page][0]
	_art.queue_redraw()
	_text.text = _story(str(pages[_page][1]))
	_spread.page = _page + 1
	_spread.of_pages = pages.size()
	_spread.queue_redraw()
	_next.text = "Page suivante ›" if _page < pages.size() - 1 else "Fin ›"
	_slide_in()


## The page coming in: it slides from the side the reader turned towards, and fades up.
func _slide_in() -> void:
	var from := 30.0 * float(_turn_dir)
	for node: Control in [_art, _text]:
		var home: Vector2 = ART_AT if node == _art else TEXT_AT
		node.position = home + Vector2(from, 0)
		node.modulate.a = 0.0
		var tween := node.create_tween().set_parallel()
		tween.tween_property(node, "position", home, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "modulate:a", 1.0, 0.2)


## The words of a page, with a big coloured letter to start it, the way a storybook does.
func _story(words: String) -> String:
	if words.is_empty():
		return ""
	return "[font_size=54][color=#C8202A]%s[/color][/font_size]%s" % [words.substr(0, 1), words.substr(1)]


## A book lifting off the shelf under the mouse.
func _lift(b: Button, by: float, rest: float) -> void:
	b.create_tween().tween_property(b, "position:y", rest + by, 0.12).set_trans(Tween.TRANS_SINE)


func _close() -> void:
	closed.emit()
	queue_free()


func _label(s: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", BLUE)
	return l


func _button(bar: HBoxContainer, label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(220, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 16))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 16))
	b.pressed.connect(on_press)
	bar.add_child(b)
	return b


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 14
	b.content_margin_right = 14
	return b


# The picture page: a little illustration drawn for each scene of the stories.
# One page's picture: a little scene with a sky, a ground and its characters, all drawn with outlines like a picture book.
class _Art:
	extends Control

	const INK := Color("#3A2A1E")
	const NIGHT_KINDS := ["moon", "jump", "bowl", "sleep", "stars", "planet", "owl", "roofs", "mouse"]
	const INDOORS := ["box", "rocket", "home", "hamster", "window", "snowball", "melt", "nest"]
	## The back lane: its ground is cracked concrete with weeds, never a meadow.
	const LANE_KINDS := ["lane", "croque", "treasure", "digging", "friends"]

	var kind := ""

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var night := kind in NIGHT_KINDS
		var inside := kind in INDOORS
		var lane := kind in LANE_KINDS
		# The picture itself, on its own little page.
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FFFDF7"))
		var horizon := h * 0.62
		var sky_top := Color("#1B2A54") if night else Color("#8FCBEE")
		var sky_mid := Color("#35356A") if night else Color("#BBE2F4")
		var sky_low := Color("#5B4A7C") if night else Color("#EAF4F7")
		if inside:
			sky_top = Color("#E2D0B2")
			sky_mid = Color("#EFE2CA")
			sky_low = Color("#F8EEDA")
		# The sky in two bands, so it deepens toward the top the way a sky does.
		draw_polygon(PackedVector2Array([Vector2(6, 6), Vector2(w - 6, 6), Vector2(w - 6, horizon * 0.58), Vector2(6, horizon * 0.58)]),
			PackedColorArray([sky_top, sky_top, sky_mid, sky_mid]))
		draw_polygon(PackedVector2Array([Vector2(6, horizon * 0.58), Vector2(w - 6, horizon * 0.58),
			Vector2(w - 6, horizon + 16), Vector2(6, horizon + 16)]),
			PackedColorArray([sky_mid, sky_mid, sky_low, sky_low]))
		if night:
			_stars(w, horizon)
		elif not inside:
			_clouds(w)
			_far_hills(w, horizon)
		# The ground: a soft rise, not a flat band.
		var roofs := kind in ["owl", "roofs", "mouse"]
		var earth := Color("#C9A26E") if inside else (Color("#B2AA9A") if lane else
			(Color("#36334C") if roofs else (Color("#3E5E4A") if night else Color("#86BE57"))))
		var ground := PackedVector2Array([Vector2(6, h - 6), Vector2(6, horizon + 10)])
		var steps := 10
		for i in steps + 1:
			var t := float(i) / steps
			ground.append(Vector2(6 + t * (w - 12), horizon + 10 - sin(t * PI) * 16.0))
		ground.append(Vector2(w - 6, h - 6))
		draw_colored_polygon(ground, earth)
		# The light lies along the crest and the ground darkens toward the foot of the picture.
		draw_polygon(PackedVector2Array([Vector2(6, h - 6), Vector2(w - 6, h - 6), Vector2(w - 6, h * 0.82), Vector2(6, h * 0.82)]),
			PackedColorArray([earth.darkened(0.16), earth.darkened(0.16), earth, earth]))
		draw_polyline(ground.slice(1, ground.size() - 1), earth.darkened(0.26), 3.0, true)
		if inside:
			_room(w, h, horizon)
		elif roofs:
			# The near roof we are standing on, with its parapet.
			draw_rect(Rect2(6, horizon + 6, w - 12, 10), earth.lightened(0.14))
			draw_rect(Rect2(6, horizon + 6, w - 12, 10), INK, false, 2.0)
		else:
			_ground_detail(w, h, horizon, earth, night, lane)
		match kind:
			"nut", "dig":
				_tree(Vector2(110, horizon + 10), Color("#D9682B"))
				_squirrel(Vector2(w * 0.6, h * 0.76), 1.0)
				_nut(Vector2(w * 0.78, h * 0.86) if kind == "nut" else Vector2(w * 0.76, h * 0.9))
				if kind == "dig":
					draw_colored_polygon(_oval(Vector2(w * 0.76, h * 0.92), Vector2(30, 12)), Color("#6E4A2E"))
			"snow":
				_snow_ground(w, h, horizon)
				_tree(Vector2(110, horizon + 10), Color("#EDF3F8"))
				_squirrel(Vector2(w * 0.62, h * 0.78), 1.0)
				_falling(w, h, 46)
			"sprout":
				_tree(Vector2(100, horizon + 14), Color("#8FC45E"))
				var root := Vector2(w * 0.55, h * 0.86)
				draw_line(root, root + Vector2(0, -46), Color("#4E8A3A"), 6.0)
				_leaf(root + Vector2(-16, -46), -0.7, Color("#7CCB5A"))
				_leaf(root + Vector2(16, -52), 0.7, Color("#7CCB5A"))
				_squirrel(Vector2(w * 0.8, h * 0.8), -1.0)
			"tree":
				_tree(Vector2(w * 0.42, horizon + 16), Color("#7CCB5A"))
				_squirrel(Vector2(w * 0.78, h * 0.8), -1.0)
			"cat":
				_sun(Vector2(w - 78, 62))
				_balcony(w, h * 0.7)
				_cat(Vector2(w * 0.45, h * 0.68), false)
			"jump", "sleep":
				_moon(Vector2(w - 86, 72))
				_balcony(w, h * 0.7)
				_cat(Vector2(w * 0.45, h * 0.68 - (60.0 if kind == "jump" else 0.0)), kind == "sleep")
			"moon":
				_moon(Vector2(w * 0.5, h * 0.3))
				_cat(Vector2(w * 0.24, h * 0.8), false)
			"bowl":
				_moon(Vector2(w - 86, 72))
				_cat(Vector2(w * 0.34, h * 0.78), false)
				var bowl := Vector2(w * 0.68, h * 0.86)
				draw_colored_polygon(_oval(bowl, Vector2(40, 16)), Color("#F2EFE6"))
				draw_colored_polygon(_oval(bowl + Vector2(0, -3), Vector2(34, 12)), Color("#FFFDF5"))
				draw_colored_polygon(_oval(bowl + Vector2(0, -4), Vector2(16, 6)), Color("#FFF3B0"))
				draw_polyline(_oval(bowl, Vector2(40, 16)) + PackedVector2Array([_oval(bowl, Vector2(40, 16))[0]]), INK, 2.0, true)
			"box", "rocket", "home":
				if kind == "box":
					_rain(w, h)
				_carton(Vector2(w * 0.46, h * 0.62), kind != "box")
				if kind == "rocket":
					_girl(Vector2(w * 0.84, h * 0.86), "#F2C230")
				if kind == "home":
					_window(Vector2(80, h * 0.3), true)
			"stars":
				_rocket_flying(Vector2(w * 0.5, h * 0.52))
			"planet":
				draw_colored_polygon(_oval(Vector2(w * 0.5, h + 60), Vector2(w * 0.8, 180)), Color("#9B6FD8"))
				for i in 3:
					var alien := Vector2(w * 0.3 + i * 60.0, h * 0.72)
					draw_circle(alien, 18, Color("#7CCB5A"))
					draw_arc(alien, 18, 0, TAU, 18, INK, 2.0)
					draw_circle(alien + Vector2(-6, -4), 4.5, Color.WHITE)
					draw_circle(alien + Vector2(6, -4), 4.5, Color.WHITE)
					draw_line(alien + Vector2(0, -18), alien + Vector2(0, -30), INK, 2.0)
					draw_circle(alien + Vector2(0, -32), 4, Color("#FFD23F"))
			"hamster", "window", "snowball", "melt":
				_window(Vector2(w * 0.14, h * 0.2), kind != "hamster")
				_dresser(Vector2(w * 0.54, h * 0.98), 184, 86)
				_terrarium(Vector2(w * 0.54, h * 0.72), 150, 92)
				_hamster(Vector2(w * 0.54, h * 0.65))
				_terrarium_glass(Vector2(w * 0.54, h * 0.72), 150, 92)
				if kind in ["snowball", "melt"]:
					_girl(Vector2(w * 0.86, h * 0.84), "#F2C230")
				if kind == "snowball":
					_blob(Vector2(w * 0.86 - 26.0, h * 0.84 - 20.0), 15, Color("#F2F7FB"), 2.0)
				if kind == "melt":
					draw_colored_polygon(_oval(Vector2(w * 0.86 - 26.0, h * 0.84 + 14.0), Vector2(22, 8)), Color("#9FD3F0"))
			"lane", "croque", "treasure", "digging", "friends":
				_plex_backs(w, horizon)
				if kind in ["lane", "croque", "treasure"]:
					_croque_livre(Vector2(w * 0.74, horizon + 54))
				if kind == "lane":
					_girl(Vector2(w * 0.3, h * 0.8), "#F2C230")
				if kind == "croque":
					_girl(Vector2(w * 0.5, h * 0.8), "#F2C230")
				if kind == "treasure":
					_girl(Vector2(w * 0.44, h * 0.8), "#F2C230")
					_book_in_hands(Vector2(w * 0.44, h * 0.8 - 26.0))
				if kind == "digging":
					_tree(Vector2(w * 0.24, horizon + 20), Color("#D9682B"))
					_girl(Vector2(w * 0.56, h * 0.8), "#F2C230")
					_tin(Vector2(w * 0.74, h * 0.88))
				if kind == "friends":
					_girl(Vector2(w * 0.38, h * 0.8), "#F2C230")
					_girl(Vector2(w * 0.62, h * 0.8), "#7FB4D9")
			"owl", "roofs", "mouse":
				_roof_line(w, horizon)
				_moon(Vector2(w * 0.78, 74))
				if kind == "owl":
					draw_line(Vector2(10, h * 0.42), Vector2(w - 10, h * 0.38), INK, 3.0)
					_owl(Vector2(w * 0.42, h * 0.33))
				if kind == "roofs":
					_owl(Vector2(w * 0.2, h * 0.3))
					for i in 3:
						_lit_pane(Vector2(w * 0.46 + i * 52.0, h * 0.74 + float(i % 2) * 14.0), 36, 30)
				if kind == "mouse":
					_owl(Vector2(w * 0.22, h * 0.3))
					_mouse(Vector2(w * 0.68, h * 0.84))
			"nest":
				_tree(Vector2(w * 0.5, h + 40), Color("#7CCB5A"))
				var nest := Vector2(w * 0.5, h * 0.6)
				draw_colored_polygon(_oval(nest, Vector2(76, 30)), Color("#8A6A40"))
				draw_polyline(_oval(nest, Vector2(76, 30)) + PackedVector2Array([_oval(nest, Vector2(76, 30))[0]]), INK, 2.5, true)
				for i in 3:
					_owl(nest + Vector2(-44 + i * 44.0, -16), 0.42)
			"dawn":
				_sun(Vector2(w * 0.74, horizon - 30))
				_roof_line(w, horizon)
				_owl(Vector2(w * 0.3, h * 0.42), 0.8)
		# The light falls off toward the edges of the picture, then the hand-drawn frame over everything.
		for i in 9:
			draw_rect(Rect2(Vector2(6 + i, 6 + i), size - Vector2(12 + i * 2, 12 + i * 2)), Color(0.3, 0.2, 0.12, 0.02), false, 1.0)
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("#C8A27A"), false, 6.0)
		draw_rect(Rect2(Vector2(9, 9), size - Vector2(18, 18)), Color("#E8D6BC"), false, 2.0)

	# ── little pieces ───────────────────────────────────────

	func _oval(c: Vector2, r: Vector2, from := 0.0, to := TAU) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := 26
		for i in n + 1:
			var a := from + (to - from) * i / n
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		return pts

	# A round shape with the light on it: lit from the upper left, shaded along the lower right.
	func _blob(c: Vector2, r: float, fill: Color, line := 2.5) -> void:
		draw_circle(c, r, fill)
		draw_arc(c, r * 0.8, deg_to_rad(-25), deg_to_rad(145), 24, fill.darkened(0.15), r * 0.4)
		draw_circle(c + Vector2(-r * 0.33, -r * 0.33), r * 0.3, fill.lightened(0.2))
		draw_arc(c, r, 0, TAU, 30, INK, line)

	# The soft shadow a character casts on the ground, so nobody floats.
	func _shadow(at: Vector2, rx: float) -> void:
		draw_colored_polygon(_oval(at + Vector2(2, 7), Vector2(rx, rx * 0.26)), Color(0.22, 0.16, 0.1, 0.16))

	func _stars(w: float, horizon: float) -> void:
		for i in 56:
			var p := Vector2(fmod(i * 71.0, w - 24) + 12, fmod(i * 43.0, horizon - 24) + 12)
			draw_circle(p, 1.0 + float(i % 3) * 0.7, Color(1, 1, 1, 0.9))
		# A few of them twinkle, with four little points.
		for i in 5:
			var p := Vector2(fmod(i * 97.0, w - 40) + 20, fmod(i * 59.0, horizon - 40) + 20)
			for a in [Vector2(9, 0), Vector2(0, 9)]:
				draw_line(p - a, p + a, Color(1, 1, 1, 0.75), 1.6)

	func _clouds(w: float) -> void:
		for c in [[w * 0.18, 56.0, 1.0], [w * 0.66, 36.0, 0.72], [w * 0.9, 84.0, 0.56]]:
			_cloud(Vector2(c[0], c[1]), c[2])

	# A picture-book cloud: rounded humps on a flat bottom, with its grey underside.
	func _cloud(at: Vector2, k: float) -> void:
		var humps := [Vector2(-34, 6), Vector2(-8, -9), Vector2(20, 1), Vector2(44, 9)]
		var radii := [20.0, 26.0, 22.0, 16.0]
		for pass_i in 2:
			var c := Color("#D5E2EC") if pass_i == 0 else Color("#FCFEFF")
			var dy := 5.0 if pass_i == 0 else 0.0
			for i in humps.size():
				draw_circle(at + (humps[i] + Vector2(0, dy)) * k, radii[i] * k, c)
			draw_rect(Rect2(at + Vector2(-54, dy) * k, Vector2(112, 16) * k), c)

	# The hills at the end of the street, far off and hazy.
	func _far_hills(w: float, horizon: float) -> void:
		for layer in 2:
			var c := Color("#B9CBD4") if layer == 0 else Color("#A3BCC2")
			var top := horizon - 46.0 + layer * 16.0
			var pts := PackedVector2Array([Vector2(6, horizon + 12)])
			for i in 15:
				var t := float(i) / 14.0
				pts.append(Vector2(6 + t * (w - 12), top + sin(t * 6.0 + layer * 2.0) * 11.0 + cos(t * 13.0) * 4.0))
			pts.append(Vector2(w - 6, horizon + 12))
			draw_colored_polygon(pts, c)

	# A room: dotted wallpaper, the skirting board along the floor, boards and a rug.
	func _room(w: float, h: float, horizon: float) -> void:
		for i in 54:
			draw_circle(Vector2(14 + fmod(i * 67.0, w - 28), 14 + fmod(i * 41.0, horizon - 28)), 2.4, Color(1, 1, 1, 0.3))
		for i in 6:
			draw_line(Vector2(8, horizon + 22.0 + i * (h - horizon - 30.0) / 6.0),
				Vector2(w - 8, horizon + 22.0 + i * (h - horizon - 30.0) / 6.0), Color(0.4, 0.28, 0.16, 0.16), 1.6)
		draw_rect(Rect2(6, horizon + 4, w - 12, 13), Color("#F2E6D2"))
		draw_rect(Rect2(6, horizon + 4, w - 12, 13), INK, false, 2.0)
		var rug := _oval(Vector2(w * 0.52, h * 0.88), Vector2(w * 0.38, 28))
		draw_colored_polygon(rug, Color("#D9748A"))
		draw_colored_polygon(_oval(Vector2(w * 0.52, h * 0.88), Vector2(w * 0.3, 20)), Color("#E2899C"))
		draw_polyline(rug + PackedVector2Array([rug[0]]), Color("#B0506A"), 3.0, true)

	# A lit pane seen from far off, for the kitchens the owl watches from the wire.
	func _lit_pane(at: Vector2, w: float, h: float) -> void:
		draw_rect(Rect2(at - Vector2(w, h) / 2.0, Vector2(w, h)).grow(6.0), Color(1.0, 0.9, 0.55, 0.13))
		draw_rect(Rect2(at - Vector2(w, h) / 2.0, Vector2(w, h)), Color("#FFE9A8"))
		draw_rect(Rect2(at - Vector2(w, h) / 2.0, Vector2(w, h)), INK, false, 2.0)
		draw_line(at - Vector2(w / 2.0, 0), at + Vector2(w / 2.0, 0), Color("#E8D28E"), 2.0)
		draw_line(at - Vector2(0, h / 2.0), at + Vector2(0, h / 2.0), Color("#E8D28E"), 2.0)

	# What grows on the ground: tufts of grass along the crest, little stones, and weeds in the lane's crack.
	func _ground_detail(w: float, h: float, horizon: float, earth: Color, night: bool, lane: bool) -> void:
		if lane:
			# The crack down the middle of the concrete, with weeds coming up through it.
			var crack := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				crack.append(Vector2(w * 0.5 + sin(t * 3.4) * 7.0 + t * 10.0, horizon + 12.0 + t * (h - horizon - 20.0)))
			draw_polyline(crack, earth.darkened(0.3), 2.4)
			for i in 9:
				var t := (i + 0.5) / 9.0
				var at := crack[clampi(int(t * 12.0), 0, 12)]
				for b in 3:
					draw_line(at, at + Vector2(b * 4.0 - 4.0, -7.0 - float((i * 5 + b) % 4) * 1.8), Color("#6E8A4A"), 1.8)
			# The slabs' joints.
			for i in 3:
				var y := horizon + 26.0 + i * (h - horizon - 36.0) / 3.0
				draw_line(Vector2(8, y), Vector2(w - 8, y + 4), earth.darkened(0.14), 1.6)
			return
		var blade := earth.darkened(0.24)
		for i in 28:
			var t := (i + 0.5) / 28.0
			var x := 10.0 + t * (w - 20.0)
			var y := horizon + 11.0 - sin(t * PI) * 16.0
			var tall := 7.0 + float((i * 7) % 5) * 2.2
			for b in 3:
				draw_line(Vector2(x + b * 3.0 - 3.0, y + 2), Vector2(x + b * 4.5 - 7.0, y - tall), blade, 1.8)
		for i in 9:
			var x := 16.0 + fmod(i * 97.0, w - 32.0)
			var y := horizon + 32.0 + fmod(i * 53.0, maxf(h - horizon - 48.0, 10.0))
			if i % 3 == 0:
				draw_circle(Vector2(x, y), 3.5 + float(i % 2), earth.darkened(0.16))
			elif not night:
				# A little flower: five petals round a yellow heart.
				var petal := Color("#F6F0FA") if i % 2 == 0 else Color("#F7C6D9")
				for a in 5:
					draw_circle(Vector2(x, y) + Vector2(0, -4.5).rotated(TAU * a / 5.0), 3.0, petal)
				draw_circle(Vector2(x, y), 2.4, Color("#FFD23F"))

	func _falling(w: float, h: float, n: int) -> void:
		for i in n:
			var p := Vector2(fmod(i * 53.0, w - 20) + 10, fmod(i * 37.0, h - 40) + 10)
			var r := 2.2 + float(i % 3) * 1.4
			draw_circle(p, r + 1.6, Color(1, 1, 1, 0.35))
			draw_circle(p, r, Color(1, 1, 1, 0.97))

	func _rain(w: float, h: float) -> void:
		for i in 34:
			var p := Vector2(fmod(i * 61.0, w - 20) + 10, fmod(i * 29.0, h * 0.58) + 10)
			draw_line(p, p + Vector2(-5, 14), Color("#8FB8DC"), 2.4)

	func _snow_ground(w: float, h: float, horizon: float) -> void:
		var pts := PackedVector2Array([Vector2(6, h - 6), Vector2(6, horizon + 6)])
		for i in 11:
			var t := i / 10.0
			pts.append(Vector2(6 + t * (w - 12), horizon + 6 - sin(t * PI) * 18.0))
		pts.append(Vector2(w - 6, h - 6))
		draw_colored_polygon(pts, Color("#F4F8FB"))

	func _sun(at: Vector2) -> void:
		draw_circle(at, 52, Color(1.0, 0.86, 0.4, 0.3))
		_blob(at, 34, Color("#FFD23F"))

	func _moon(at: Vector2) -> void:
		draw_circle(at, 64, Color(1.0, 1.0, 0.9, 0.12))
		_blob(at, 40, Color("#FFF3C4"))
		draw_circle(at + Vector2(-12, -8), 7, Color("#F0DFA0"))
		draw_circle(at + Vector2(14, 10), 5, Color("#F0DFA0"))
		draw_circle(at + Vector2(4, -20), 4, Color("#F0DFA0"))

	func _leaf(at: Vector2, turn: float, c: Color) -> void:
		var pts := PackedVector2Array()
		for i in 12:
			var t := float(i) / 11.0
			pts.append(at + Vector2(sin(t * PI) * 13.0, -t * 30.0).rotated(turn))
		for i in range(11, -1, -1):
			var t := float(i) / 11.0
			pts.append(at + Vector2(-sin(t * PI) * 13.0, -t * 30.0).rotated(turn))
		draw_colored_polygon(pts, c)
		draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 2.0, true)

	# A tree: a tapering trunk with two limbs, and one scalloped crown with clumps of light and shade inside it.
	func _tree(base: Vector2, leaves: Color) -> void:
		var trunk := PackedVector2Array([base + Vector2(-14, 0), base + Vector2(14, 0),
			base + Vector2(8, -122), base + Vector2(-8, -122)])
		draw_colored_polygon(trunk, Color("#6E4E32"))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-14, 0), base + Vector2(-5, 0),
			base + Vector2(-3, -122), base + Vector2(-8, -122)]), Color("#8A6646"))
		draw_line(base + Vector2(-2, -92), base + Vector2(-36, -124), Color("#6E4E32"), 7.0)
		draw_line(base + Vector2(3, -98), base + Vector2(34, -128), Color("#6E4E32"), 7.0)
		draw_polyline(PackedVector2Array([base + Vector2(-14, 2), base + Vector2(-8, -122)]), INK, 2.0)
		draw_polyline(PackedVector2Array([base + Vector2(14, 2), base + Vector2(8, -122)]), INK, 2.0)
		var crown := base + Vector2(0, -156)
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			var rr := 1.0 + 0.085 * sin(a * 11.0)
			pts.append(crown + Vector2(cos(a) * 82.0 * rr, sin(a) * 56.0 * rr))
		draw_colored_polygon(pts, leaves)
		for o in [Vector2(40, 14), Vector2(10, 24), Vector2(-44, 18)]:
			draw_circle(crown + o, 21, leaves.darkened(0.13))
		for o in [Vector2(-34, -14), Vector2(4, -24)]:
			draw_circle(crown + o, 23, leaves.lightened(0.17))
		draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 2.5, true)

	func _squirrel(at: Vector2, facing: float) -> void:
		_shadow(at + Vector2(0, 18), 24)
		# A big bushy tail: a curved spine with a scalloped edge either side of it.
		var spine := PackedVector2Array()
		for i in 15:
			var t := float(i) / 14.0
			spine.append(at + Vector2(-facing * (24.0 + sin(t * PI) * 34.0), 10.0 - t * 94.0))
		var tail := PackedVector2Array()
		for i in spine.size():
			var t := float(i) / (spine.size() - 1.0)
			tail.append(spine[i] - Vector2(facing * _tail_width(t, 4.0), 0))
		for i in range(spine.size() - 1, -1, -1):
			var t := float(i) / (spine.size() - 1.0)
			tail.append(spine[i] + Vector2(facing * _tail_width(t, 5.0), 0))
		draw_colored_polygon(tail, Color("#A08A78"))
		draw_polyline(spine, Color("#B9A392"), 11.0)
		draw_polyline(tail + PackedVector2Array([tail[0]]), INK, 2.2, true)
		_blob(at, 24, Color("#A08A78"))
		_blob(at + Vector2(facing * 18, -26), 17, Color("#A08A78"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(facing * 8, -38), at + Vector2(facing * 14, -52),
			at + Vector2(facing * 22, -40)]), Color("#8E7A6A"))
		draw_circle(at + Vector2(facing * 25, -28), 3.0, INK)
		draw_circle(at + Vector2(facing * 33, -24), 2.4, Color("#5E4232"))
		draw_line(at + Vector2(facing * 10, 8), at + Vector2(facing * 22, 18), INK, 3.0)

	# How wide the bushy tail is at `t` along it: full in the middle, scalloped like fur.
	func _tail_width(t: float, waves: float) -> float:
		return 7.0 + 13.0 * sin(clampf(t, 0.0, 1.0) * PI) + 5.0 * absf(sin(t * PI * waves))

	func _nut(at: Vector2) -> void:
		_blob(at, 13, Color("#A9743A"), 2.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-13, -6), at + Vector2(13, -6),
			at + Vector2(11, -16), at + Vector2(-11, -16)]), Color("#6E4A24"))

	func _cat(at: Vector2, asleep: bool) -> void:
		_shadow(at + Vector2(0, 26), 30)
		var tail := PackedVector2Array()
		for i in 14:
			var t := float(i) / 13.0
			tail.append(at + Vector2(-34 - sin(t * PI) * 24.0, 16 - t * 56.0))
		for i in range(13, -1, -1):
			var t := float(i) / 13.0
			tail.append(at + Vector2(-26 - sin(t * PI) * 20.0, 22 - t * 52.0))
		draw_colored_polygon(tail, Color("#8E9096"))
		_blob(at, 32, Color("#8E9096"))
		_blob(at + Vector2(2, -40), 24, Color("#8E9096"))
		for e in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([at + Vector2(2 + e * 8, -58), at + Vector2(2 + e * 22, -76),
				at + Vector2(2 + e * 26, -50)]), Color("#8E9096"))
			draw_colored_polygon(PackedVector2Array([at + Vector2(2 + e * 11, -58), at + Vector2(2 + e * 19, -69),
				at + Vector2(2 + e * 21, -54)]), Color("#E8A0B4"))
			if asleep:
				draw_arc(at + Vector2(2 + e * 10, -42), 5.0, PI, TAU, 10, INK, 2.2)
			else:
				_blob(at + Vector2(2 + e * 10, -42), 5.5, Color("#9BD16A"), 1.6)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-4, -34), at + Vector2(8, -34), at + Vector2(2, -28)]), Color("#E8A0B4"))
		for i in 3:
			draw_line(at + Vector2(-20, -6 + i * 10), at + Vector2(16, -10 + i * 10), Color("#6E7076"), 2.2)

	func _hamster(at: Vector2) -> void:
		_shadow(at + Vector2(0, 26), 28)
		_blob(at, 32, Color("#E8A65A"))
		draw_circle(at + Vector2(0, 8), 20, Color("#FBF1E2"))
		for e in [-1.0, 1.0]:
			_blob(at + Vector2(e * 22, -26), 10, Color("#E8A65A"), 2.0)
			draw_circle(at + Vector2(e * 12, -8), 4.0, INK)
			draw_circle(at + Vector2(e * 20, 4), 9, Color("#F7D7A8"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -2), at + Vector2(5, -2), at + Vector2(0, 4)]), Color("#C9748A"))
		draw_line(at + Vector2(-26, 2), at + Vector2(-42, -2), INK, 1.6)
		draw_line(at + Vector2(26, 2), at + Vector2(42, -2), INK, 1.6)

	# The dresser the terrarium stands on: two drawers with their knobs.
	func _dresser(at: Vector2, w: float, h: float) -> void:
		var box := Rect2(at - Vector2(w / 2.0, h), Vector2(w, h))
		draw_rect(box, Color("#B98F5E"))
		draw_rect(Rect2(box.position, Vector2(w * 0.24, h)), Color("#C9A26E"))
		draw_rect(Rect2(box.position - Vector2(7, 9), Vector2(w + 14, 11)), Color("#C9A26E"))
		draw_rect(Rect2(box.position - Vector2(7, 9), Vector2(w + 14, 11)), INK, false, 2.0)
		for i in 2:
			var d := Rect2(box.position + Vector2(10, 10 + i * (h - 12) / 2.0), Vector2(w - 20, (h - 12) / 2.0 - 8.0))
			draw_rect(d, Color("#C9A26E"))
			draw_rect(d, INK, false, 2.0)
			draw_circle(d.get_center(), 5.0, Color("#6E5A48"))
		draw_rect(box, INK, false, 2.2)

	# Caramel's terrarium: the wooden tray, the bedding and the wheel, with the glass over him afterwards.
	func _terrarium(at: Vector2, w: float, h: float) -> void:
		var box := Rect2(at - Vector2(w / 2.0, h), Vector2(w, h))
		_shadow(at, w * 0.5)
		draw_rect(box, Color("#EAF2F6"))
		draw_rect(Rect2(box.position + Vector2(0, h * 0.62), Vector2(w, h * 0.38)), Color("#E2C79A"))
		for i in 12:
			draw_line(box.position + Vector2(8 + fmod(i * 37.0, w - 16), h * 0.66 + fmod(i * 23.0, h * 0.28)),
				box.position + Vector2(14 + fmod(i * 37.0, w - 16), h * 0.68 + fmod(i * 23.0, h * 0.28)), Color("#C9A876"), 2.0)
		# The wheel at the back.
		draw_arc(box.position + Vector2(w * 0.82, h * 0.52), 24, 0, TAU, 28, Color("#F2A27A"), 4.0)
		draw_line(box.position + Vector2(w * 0.82, h * 0.52 - 24), box.position + Vector2(w * 0.82, h * 0.52 + 24), Color("#F2A27A"), 3.0)

	func _terrarium_glass(at: Vector2, w: float, h: float) -> void:
		var box := Rect2(at - Vector2(w / 2.0, h), Vector2(w, h))
		draw_colored_polygon(PackedVector2Array([box.position + Vector2(10, h), box.position + Vector2(w * 0.42, 0),
			box.position + Vector2(w * 0.6, 0), box.position + Vector2(w * 0.28, h)]), Color(1, 1, 1, 0.22))
		draw_rect(box, Color("#D8E6EC"), false, 5.0)
		draw_rect(box, INK, false, 2.2)
		draw_rect(Rect2(box.position - Vector2(6, 10), Vector2(w + 12, 12)), Color("#8A6A4E"))
		draw_rect(Rect2(box.position - Vector2(6, 10), Vector2(w + 12, 12)), INK, false, 2.0)

	func _owl(at: Vector2, k := 1.0) -> void:
		var body := _oval(at + Vector2(0, 16 * k), Vector2(44 * k, 52 * k))
		draw_colored_polygon(body, Color("#8A6A4E"))
		draw_polyline(body + PackedVector2Array([body[0]]), INK, 2.5 * k, true)
		draw_colored_polygon(_oval(at + Vector2(0, 26 * k), Vector2(26 * k, 34 * k)), Color("#C9A880"))
		for e in [-1.0, 1.0]:
			_blob(at + Vector2(e * 19 * k, -6 * k), 16 * k, Color("#F6EFD8"), 2.2 * k)
			draw_circle(at + Vector2(e * 19 * k, -6 * k), 8 * k, INK)
			draw_circle(at + Vector2(e * 19 * k - 3 * k, -9 * k), 3 * k, Color.WHITE)
			draw_colored_polygon(PackedVector2Array([at + Vector2(e * 10 * k, -34 * k), at + Vector2(e * 34 * k, -54 * k),
				at + Vector2(e * 36 * k, -26 * k)]), Color("#8A6A4E"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-7 * k, 4 * k), at + Vector2(7 * k, 4 * k), at + Vector2(0, 20 * k)]), Color("#E8A65A"))

	func _mouse(at: Vector2) -> void:
		_shadow(at + Vector2(0, 12), 16)
		_blob(at, 16, Color("#9A9AA2"), 2.0)
		_blob(at + Vector2(16, -8), 10, Color("#9A9AA2"), 2.0)
		_blob(at + Vector2(10, -18), 7, Color("#C9A0A8"), 1.6)
		draw_circle(at + Vector2(22, -10), 2.4, INK)
		draw_line(at + Vector2(-14, 4), at + Vector2(-44, -6), INK, 2.2)

	# The balcony Minou sits on: boards with their grain, an iron rail and its cap.
	func _balcony(w: float, y: float) -> void:
		draw_rect(Rect2(14, y, w - 28, 12), Color("#7A5E4A"))
		for i in 4:
			draw_line(Vector2(18, y + 2 + i * 3.0), Vector2(w - 18, y + 2 + i * 3.0), Color("#6A503E"), 1.2)
		draw_rect(Rect2(14, y, w - 28, 12), INK, false, 2.0)
		draw_rect(Rect2(14, y + 12, w - 28, 5), Color(0, 0, 0, 0.18))
		for x in range(24, int(w) - 24, 24):
			draw_line(Vector2(x, y + 12), Vector2(x, y + 50), Color("#2B2B33"), 3.0)
			draw_circle(Vector2(x, y + 31), 3.5, Color("#2B2B33"))
		draw_line(Vector2(14, y + 50), Vector2(w - 14, y + 50), Color("#2B2B33"), 5.0)
		draw_line(Vector2(14, y + 48), Vector2(w - 14, y + 48), Color("#4A4A54"), 2.0)

	# A sash window: the glass with the daylight sliding across it, white bars, curtains drawn back and a sill.
	func _window(at: Vector2, snowing: bool, lit := false) -> void:
		var r := Rect2(at, Vector2(120, 96))
		draw_rect(Rect2(at - Vector2(9, 9), r.size + Vector2(18, 18)), Color("#EDE4D4"))
		draw_rect(Rect2(at - Vector2(9, 9), r.size + Vector2(18, 18)), INK, false, 2.0)
		draw_rect(r, Color("#FFE9A8") if lit else Color("#8FC6E8"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, 96), at + Vector2(58, 0), at + Vector2(90, 0),
			at + Vector2(32, 96)]), Color(1, 1, 1, 0.22))
		if snowing:
			for i in 14:
				draw_circle(at + Vector2(10 + fmod(i * 31.0, 100), 10 + fmod(i * 23.0, 76)), 3.0, Color.WHITE)
		draw_rect(r, Color.WHITE, false, 6.0)
		draw_rect(r, INK, false, 2.0)
		draw_line(at + Vector2(60, 0), at + Vector2(60, 96), Color.WHITE, 4.0)
		draw_line(at + Vector2(0, 48), at + Vector2(120, 48), Color.WHITE, 4.0)
		# The curtains, pulled back to the sides.
		for side in 2:
			var cx := at.x - 9.0 + float(side) * 138.0
			var dir := 1.0 if side == 0 else -1.0
			var cloth := PackedVector2Array([Vector2(cx, at.y - 9)])
			for i in 9:
				var t := float(i) / 8.0
				cloth.append(Vector2(cx + dir * (16.0 + sin(t * PI) * 10.0), at.y - 9 + t * 100.0))
			cloth.append(Vector2(cx, at.y + 95))
			draw_colored_polygon(cloth, Color("#E8778E") if side == 0 else Color("#E8778E").darkened(0.1))
			draw_polyline(cloth, INK, 1.8)
		# The sill.
		draw_rect(Rect2(at + Vector2(-17, 87), Vector2(154, 12)), Color("#E2D6BE"))
		draw_rect(Rect2(at + Vector2(-17, 87), Vector2(154, 12)), INK, false, 2.0)

	# The cardboard box: corrugated flaps and packing tape, and once it is a rocket, a nose cone drawn on in
	# crayon, fins, a porthole and a star or two.
	func _carton(at: Vector2, rocket: bool) -> void:
		_shadow(at + Vector2(0, 98), 74)
		if rocket:
			for e in [-1.0, 1.0]:
				var fin := PackedVector2Array([at + Vector2(e * 70, 46), at + Vector2(e * 104, 100), at + Vector2(e * 70, 100)])
				draw_colored_polygon(fin, Color("#E04F5F"))
				draw_polyline(fin + PackedVector2Array([fin[0]]), INK, 2.6, true)
			var cone := PackedVector2Array([at + Vector2(-48, -8), at + Vector2(0, -104), at + Vector2(48, -8)])
			draw_colored_polygon(cone, Color("#E04F5F"))
			draw_colored_polygon(PackedVector2Array([at + Vector2(-48, -8), at + Vector2(0, -104), at + Vector2(-16, -8)]),
				Color("#EE6E7C"))
			draw_polyline(cone + PackedVector2Array([cone[0]]), INK, 3.0, true)
		var box := Rect2(at + Vector2(-72, -10), Vector2(144, 110))
		draw_rect(box, Color("#C9A26E"))
		draw_rect(Rect2(at + Vector2(-72, -10), Vector2(40, 110)), Color("#D6B07D"))
		draw_rect(Rect2(at + Vector2(40, -10), Vector2(32, 110)), Color("#B98F5E"))
		# The flaps and the tape down the middle.
		draw_line(at + Vector2(-72, 18), at + Vector2(72, 18), Color("#8A6A40"), 3.0)
		draw_rect(Rect2(at + Vector2(-10, -10), Vector2(20, 28)), Color("#EDE2C8"))
		draw_rect(Rect2(at + Vector2(-10, -10), Vector2(20, 28)), Color("#C9BCA0"), false, 1.4)
		for i in 7:
			draw_line(at + Vector2(-64 + i * 21.0, 24), at + Vector2(-64 + i * 21.0, 96), Color("#B58C5C"), 1.4)
		draw_rect(box, INK, false, 3.0)
		if rocket:
			_blob(at + Vector2(0, 50), 23, Color("#9FD3F0"))
			draw_arc(at + Vector2(0, 50), 23, 0, TAU, 26, Color("#E8E4DA"), 5.0)
			draw_arc(at + Vector2(0, 50), 23, 0, TAU, 26, INK, 2.0)
			for o in [Vector2(-48, 56), Vector2(46, 72)]:
				_crayon_star(at + o, 11.0, Color("#FFD23F"))

	# A five-pointed star, the way a child draws one.
	func _crayon_star(at: Vector2, r: float, c: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + TAU * i / 10.0
			var rr := r if i % 2 == 0 else r * 0.44
			pts.append(at + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, c)
		draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 1.8, true)

	func _rocket_flying(at: Vector2) -> void:
		draw_colored_polygon(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(0, -70), at + Vector2(30, 40)]), Color("#E8E4DA"))
		draw_polyline(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(0, -70), at + Vector2(30, 40), at + Vector2(-30, 40)]), INK, 3.0, true)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(-54, 64), at + Vector2(-20, 48)]), Color("#E04F5F"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(30, 40), at + Vector2(54, 64), at + Vector2(20, 48)]), Color("#E04F5F"))
		_blob(at + Vector2(0, -16), 16, Color("#9FD3F0"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-16, 44), at + Vector2(16, 44), at + Vector2(0, 104)]), Color("#FFB347"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 44), at + Vector2(8, 44), at + Vector2(0, 80)]), Color("#FFF3B0"))

	# The backs of the plexes along the lane: brick in staggered courses, a cornice, lit windows, a wooden
	# gallery with its iron rail and a downpipe — the lane as Charlotte knows it.
	func _plex_backs(w: float, horizon: float) -> void:
		var bw := (w - 20.0) / 3.0 - 10.0
		for i in 3:
			var x := 10.0 + i * (w - 20.0) / 3.0
			var top := horizon - 150.0 + (i % 2) * 24.0
			var wall := Color("#9C5A44") if i % 2 == 0 else Color("#B08A68")
			var r := Rect2(x, top, bw, horizon - top + 14.0)
			draw_rect(r, wall)
			var yy := top + 8.0
			var row := 0
			while yy < r.end.y:
				draw_line(Vector2(x, yy), Vector2(x + bw, yy), wall.darkened(0.13), 1.3)
				var xx := x + (0.0 if row % 2 == 0 else 10.0)
				while xx < x + bw:
					draw_line(Vector2(xx, yy), Vector2(xx, yy - 8), wall.darkened(0.11), 1.2)
					xx += 20.0
				yy += 8.0
				row += 1
			draw_rect(Rect2(x, top, bw * 0.3, r.size.y), Color(1, 1, 1, 0.07))
			draw_rect(Rect2(x + bw * 0.74, top, bw * 0.26, r.size.y), Color(0, 0, 0, 0.07))
			# The cornice.
			draw_rect(Rect2(x - 4, top - 9, bw + 8, 11), wall.darkened(0.32))
			draw_rect(Rect2(x - 4, top - 9, bw + 8, 11), INK, false, 2.0)
			draw_rect(r, INK, false, 2.0)
			for kk in 2:
				var win := Rect2(x + 12 + kk * (bw * 0.48), top + 24, 28, 38)
				draw_rect(win, Color("#FFE9A8") if (i + kk) % 2 == 0 else Color("#7F97A8"))
				draw_rect(win.grow(3.0), Color("#EDE4D4"), false, 4.0)
				draw_rect(win, INK, false, 2.0)
				draw_line(win.position + Vector2(win.size.x / 2.0, 0), win.position + Vector2(win.size.x / 2.0, win.size.y), Color("#EDE4D4"), 2.0)
			# The wooden gallery with its iron rail.
			var gy := horizon - 42.0
			draw_rect(Rect2(x + 3, gy, bw - 6, 7), Color("#8A6A4E"))
			draw_rect(Rect2(x + 3, gy, bw - 6, 7), INK, false, 1.6)
			var px := x + 10.0
			while px < x + bw - 8.0:
				draw_line(Vector2(px, gy + 7), Vector2(px, gy + 30), Color("#2B2B33"), 2.0)
				px += 13.0
			draw_line(Vector2(x + 3, gy + 30), Vector2(x + bw - 3, gy + 30), Color("#2B2B33"), 3.0)
			# The downpipe.
			draw_line(Vector2(x + bw - 7, top - 4), Vector2(x + bw - 7, horizon + 12), Color("#D8D2C6"), 3.5)
		draw_line(Vector2(10, horizon + 14), Vector2(w - 10, horizon + 14), Color("#6E6A62"), 3.0)

	# The croque-livre on its post: a little glass-fronted house of books with a shingled roof.
	func _croque_livre(at: Vector2) -> void:
		_shadow(at + Vector2(0, 62), 20)
		draw_rect(Rect2(at + Vector2(-7, 0), Vector2(14, 64)), Color("#6E5A48"))
		draw_rect(Rect2(at + Vector2(-7, 0), Vector2(14, 64)), INK, false, 1.8)
		draw_rect(Rect2(at + Vector2(-44, -58), Vector2(88, 60)), Color("#4FA3A0"))
		draw_rect(Rect2(at + Vector2(-40, -54), Vector2(80, 52)), Color("#D9EFEE"))
		for i in 4:
			var b := Rect2(at + Vector2(-34 + i * 17, -48), Vector2(12, 36))
			var c: Color = [Color("#E74C3C"), Color("#F1C40F"), Color("#3498DB"), Color("#2ECC71")][i]
			draw_rect(b, c)
			draw_rect(Rect2(b.position, Vector2(4, b.size.y)), c.lightened(0.2))
			draw_rect(b, INK, false, 1.4)
		# The glass door and its handle.
		draw_colored_polygon(PackedVector2Array([at + Vector2(-40, -2), at + Vector2(-6, -54), at + Vector2(10, -54),
			at + Vector2(-24, -2)]), Color(1, 1, 1, 0.3))
		draw_rect(Rect2(at + Vector2(-40, -54), Vector2(80, 52)), INK, false, 2.2)
		draw_circle(at + Vector2(32, -28), 3.0, Color("#6E5A48"))
		draw_rect(Rect2(at + Vector2(-44, -58), Vector2(88, 60)), INK, false, 2.5)
		var roof := PackedVector2Array([at + Vector2(-54, -56), at + Vector2(0, -90), at + Vector2(54, -56)])
		draw_colored_polygon(roof, Color("#5E6B73"))
		for i in 3:
			draw_line(at + Vector2(-44 + i * 10.0, -56 - i * 6.0), at + Vector2(44 - i * 10.0, -56 - i * 6.0), Color("#4E5B63"), 1.6)
		draw_polyline(roof + PackedVector2Array([roof[0]]), INK, 2.2, true)

	# A little girl in the stories: a dress with a waist and a flared hem, real arms and legs, shoes, and a
	# round face under her fringe. Lit from the upper left like everything else.
	func _girl(at: Vector2, dress: String) -> void:
		var cloth := Color(dress)
		var skin := Color("#F3CDB0")
		_shadow(at, 26)
		# Legs, then shoes.
		for e in [-1.0, 1.0]:
			draw_line(at + Vector2(e * 9, -8), at + Vector2(e * 11, 12), skin, 7.0)
			draw_line(at + Vector2(e * 11, 12), at + Vector2(e * 11, 15), skin, 7.0)
			draw_line(at + Vector2(e * 8, 16), at + Vector2(e * 17, 16), Color("#4A3C64"), 9.0)
		# The dress.
		var body := PackedVector2Array([at + Vector2(-27, 0), at + Vector2(-21, -20), at + Vector2(-13, -36),
			at + Vector2(-12, -54), at + Vector2(12, -54), at + Vector2(13, -36), at + Vector2(21, -20), at + Vector2(27, 0)])
		draw_colored_polygon(body, cloth)
		draw_colored_polygon(PackedVector2Array([at + Vector2(5, -54), at + Vector2(13, -36), at + Vector2(21, -20),
			at + Vector2(27, 0), at + Vector2(13, 0)]), cloth.darkened(0.13))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-11, -52), at + Vector2(-5, -52), at + Vector2(-13, -22),
			at + Vector2(-19, -22)]), cloth.lightened(0.18))
		draw_polyline(body + PackedVector2Array([body[0]]), INK, 2.3, true)
		draw_line(at + Vector2(-13, -36), at + Vector2(13, -36), INK, 1.8)
		# Arms and hands.
		for e in [-1.0, 1.0]:
			draw_line(at + Vector2(e * 12, -48), at + Vector2(e * 25, -22), skin, 6.0)
			_blob(at + Vector2(e * 26, -19), 5.0, skin, 1.6)
		# Head, hair, face.
		_blob(at + Vector2(0, -71), 21, skin, 2.2)
		var hair := PackedVector2Array([at + Vector2(-22, -64), at + Vector2(-25, -82), at + Vector2(-17, -94),
			at + Vector2(0, -98), at + Vector2(17, -94), at + Vector2(25, -82), at + Vector2(22, -64),
			at + Vector2(17, -76), at + Vector2(6, -80), at + Vector2(-8, -78), at + Vector2(-17, -76)])
		draw_colored_polygon(hair, Color("#8A3B1E"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-20, -84), at + Vector2(-12, -94), at + Vector2(-4, -94),
			at + Vector2(-13, -82)]), Color("#A8512A"))
		draw_polyline(hair + PackedVector2Array([hair[0]]), INK, 2.0, true)
		draw_circle(at + Vector2(-7, -72), 2.8, INK)
		draw_circle(at + Vector2(7, -72), 2.8, INK)
		draw_circle(at + Vector2(-6.4, -73), 1.0, Color.WHITE)
		draw_circle(at + Vector2(7.6, -73), 1.0, Color.WHITE)
		for e in [-1.0, 1.0]:
			draw_circle(at + Vector2(e * 14, -66), 3.8, Color(0.94, 0.54, 0.48, 0.42))
		draw_arc(at + Vector2(0, -67), 7.0, 0.35, PI - 0.35, 12, INK, 2.0)

	func _book_in_hands(at: Vector2) -> void:
		draw_rect(Rect2(at + Vector2(-22, -10), Vector2(44, 30)), Color("#B5603F"))
		draw_rect(Rect2(at + Vector2(-22, -10), Vector2(44, 30)), INK, false, 2.0)
		draw_line(at + Vector2(0, -10), at + Vector2(0, 20), Color("#7A3F26"), 2.0)

	func _tin(at: Vector2) -> void:
		draw_rect(Rect2(at + Vector2(-30, -26), Vector2(60, 34)), Color("#B9BEC4"))
		draw_rect(Rect2(at + Vector2(-30, -26), Vector2(60, 34)), INK, false, 2.5)
		draw_rect(Rect2(at + Vector2(-34, -34), Vector2(68, 12)), Color("#9AA0A6"))
		for i in 5:
			draw_circle(at + Vector2(-20 + i * 10, -12), 5, [Color("#E74C3C"), Color("#3498DB"), Color("#F1C40F"), Color("#2ECC71"), Color("#9B59B6")][i])

	# The roofs of the avenue at night: cornices, chimneys and a lit window here and there.
	func _roof_line(w: float, horizon: float) -> void:
		var x := 6.0
		var i := 0
		while x < w - 6.0:
			var ww := minf(70.0 + float(i % 3) * 26.0, w - 6.0 - x)
			var top := horizon + 10.0 - 60.0 - float((i * 7) % 4) * 16.0
			var wall := Color("#4A4458") if i % 2 == 0 else Color("#5A5268")
			draw_rect(Rect2(x, top, ww, horizon + 16.0 - top), wall)
			draw_rect(Rect2(x, top, ww * 0.26, horizon + 16.0 - top), wall.lightened(0.07))
			# The chimney, then the cornice over it all.
			if i % 3 != 1:
				draw_rect(Rect2(x + ww * 0.62, top - 22, 16, 24), wall.darkened(0.2))
				draw_rect(Rect2(x + ww * 0.62, top - 22, 16, 24), INK, false, 2.0)
				draw_rect(Rect2(x + ww * 0.6 - 2, top - 26, 22, 6), wall.darkened(0.35))
			draw_rect(Rect2(x - 3, top - 7, ww + 6, 9), wall.darkened(0.3))
			draw_rect(Rect2(x - 3, top - 7, ww + 6, 9), INK, false, 2.0)
			draw_rect(Rect2(x, top, ww, horizon + 16.0 - top), INK, false, 2.0)
			for kk in 2:
				var lit: bool = (i + kk) % 3 == 0
				var win := Rect2(x + 12 + kk * (ww * 0.48), top + 18, 20, 26)
				if win.end.x > x + ww - 6.0:
					continue
				draw_rect(win, Color("#FFE9A8") if lit else Color("#2E2C3E"))
				draw_rect(win, INK, false, 1.8)
				if lit:
					draw_rect(win.grow(5.0), Color(1.0, 0.9, 0.55, 0.12))
			x += ww + 6.0
			i += 1


# The open book under the picture and the words: two cream pages with their grain, the fold between them, a
# ribbon bookmark down the gutter, a curled corner on the right page and the page number at the foot of each.
class _Spread:
	extends Control

	var page := 1
	var of_pages := 5
	var _rng := RandomNumberGenerator.new()

	func _draw() -> void:
		var half := size.x / 2.0
		for side in 2:
			var r := Rect2(Vector2(side * half, 0), Vector2(half, size.y))
			draw_rect(r, Color("#FFFBF0"))
		# The grain of the paper, and a warmer wash along the outer edges.
		for i in 420:
			draw_circle(Vector2(fmod(i * 131.0, size.x - 12) + 6, fmod(i * 79.0, size.y - 12) + 6), 1.0,
				Color(0.65, 0.56, 0.42, 0.07))
		for side in 2:
			for i in 14:
				var t := i / 13.0
				var x := (6.0 + t * 26.0) if side == 0 else (size.x - 6.0 - t * 26.0)
				draw_line(Vector2(x, 4), Vector2(x, size.y - 4), Color(0.72, 0.6, 0.42, 0.05 * (1.0 - t)), 2.0)
		# The fold: a shadow either side of the middle.
		for i in 10:
			var t := i / 9.0
			var a := 0.16 * (1.0 - t)
			draw_rect(Rect2(half - 16.0 * t, 0, 16.0 * t, size.y), Color(0.45, 0.33, 0.2, a * 0.5))
			draw_rect(Rect2(half, 0, 16.0 * t, size.y), Color(0.45, 0.33, 0.2, a * 0.5))
		draw_line(Vector2(half, 6), Vector2(half, size.y - 6), Color("#C9B894"), 2.0)
		for side in 2:
			draw_rect(Rect2(Vector2(side * half, 0), Vector2(half, size.y)), Color("#DCCFB4"), false, 2.0)
		# The ribbon bookmark, hanging out of the gutter.
		draw_rect(Rect2(half - 9, 2, 18, 54), Color("#C8202A"))
		draw_rect(Rect2(half - 9, 2, 6, 54), Color("#D94A52"))
		draw_colored_polygon(PackedVector2Array([Vector2(half - 9, 50), Vector2(half, 40), Vector2(half + 9, 50),
			Vector2(half + 9, 62), Vector2(half - 9, 62)]), Color("#A8141E"))
		# The corner of the right page, turned up a little.
		var c := Vector2(size.x - 4, size.y - 4)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-34, 0), c, c + Vector2(0, -34)]), Color("#F1E7D2"))
		draw_polyline(PackedVector2Array([c + Vector2(-34, 0), c + Vector2(-6, -6), c + Vector2(0, -34)]),
			Color("#C9B894"), 2.0)
		# The page number at the foot of each page.
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(half + half * 0.5 - 40.0, size.y - 18.0), "— %d —" % page,
			HORIZONTAL_ALIGNMENT_CENTER, 80, 17, Color("#B5A484"))
		# The last page of a story gets its three little stars.
		if page == of_pages:
			_rng.seed = 7
			for i in 3:
				CuteArt.star(self, Vector2(size.x * 0.75 - 40.0 + i * 40.0, size.y - 62.0), 13.0, Color("#FFD23F"), true, _rng)


# The shelf the books stand on: a waxed board with its brackets, and the wall behind it.
class _Shelf:
	extends Control

	func _draw() -> void:
		var y := size.y - 92.0
		# The books' shadow falls on the board.
		draw_rect(Rect2(28, y - 12, size.x - 56, 12), Color(0.45, 0.33, 0.2, 0.1))
		draw_rect(Rect2(8, y, size.x - 16, 20), Color("#B07A4A"))
		draw_rect(Rect2(8, y, size.x - 16, 7), Color("#C99464"))
		draw_rect(Rect2(8, y, size.x - 16, 20), Color("#7A5230"), false, 2.5)
		draw_rect(Rect2(8, y + 20, size.x - 16, 7), Color(0.3, 0.2, 0.12, 0.2))
		for e: float in [0.14, 0.86]:
			var x := size.x * e
			draw_colored_polygon(PackedVector2Array([Vector2(x - 16, y + 20), Vector2(x + 16, y + 20),
				Vector2(x, y + 54)]), Color("#8A5E38"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, y + 76), "Choisis un livre à lire…", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22,
			Color("#8A7A62"))


# A book standing on the shelf: its boards, the spine, the page edges, the first picture in a frame and the
# title under it.
class _Cover:
	extends Control

	## The size the pictures are drawn at, before the cover shrinks them.
	const PICTURE := Vector2(404, 386)

	var kind := ""
	var title := ""
	var band := Color("#B5603F")

	## The picture is drawn at its full size and then shrunk to fit the cover, so the whole scene is there
	## instead of a close-up crop of its middle.
	func _ready() -> void:
		var art := _Art.new()
		art.kind = kind
		art.size = PICTURE
		art.position = Vector2(20, 20)
		art.scale = Vector2.ONE * ((size.x - 40.0) / PICTURE.x)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	func _draw() -> void:
		draw_rect(Rect2(Vector2(3, 5), size - Vector2(2, 4)), Color(0.2, 0.14, 0.08, 0.18))
		# The page edges along the right, then the boards.
		draw_rect(Rect2(Vector2(size.x - 9, 5), Vector2(9, size.y - 10)), Color("#F2EADA"))
		for i in 5:
			draw_line(Vector2(size.x - 8 + i * 1.7, 7), Vector2(size.x - 8 + i * 1.7, size.y - 7), Color("#DCD0B8"), 1.0)
		draw_rect(Rect2(Vector2.ZERO, size - Vector2(8, 0)), band)
		draw_rect(Rect2(Vector2.ZERO, Vector2(13, size.y)), band.darkened(0.28))
		draw_line(Vector2(13, 0), Vector2(13, size.y), band.darkened(0.5), 2.0)
		for i in 3:
			draw_line(Vector2(3, 24 + i * (size.y - 48) / 2.0), Vector2(10, 24 + i * (size.y - 48) / 2.0),
				band.lightened(0.25), 2.0)
		# The frame round the picture, and the title under it.
		var pw := size.x - 40.0
		var ph := pw * PICTURE.y / PICTURE.x
		draw_rect(Rect2(Vector2(16, 16), Vector2(pw + 8, ph + 8)), Color("#F6EFE4"))
		draw_rect(Rect2(Vector2(16, 16), Vector2(pw + 8, ph + 8)), band.darkened(0.3), false, 2.0)
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(14, 6)), band.lightened(0.18), false, 2.0)
		var font := ThemeDB.fallback_font
		var top := 32.0 + ph
		draw_line(Vector2(22, top), Vector2(size.x - 18, top), Color(1, 1, 1, 0.45), 2.0)
		var lines := _wrap(font, title, size.x - 36.0)
		for i in lines.size():
			draw_string(font, Vector2(16, top + 26.0 + i * 20.0), lines[i], HORIZONTAL_ALIGNMENT_CENTER,
				size.x - 30.0, 17, Color.WHITE)
		CuteArt.star(self, Vector2(size.x / 2.0, size.y - 22.0), 9.0, Color(1, 1, 1, 0.55))

	func _wrap(font: Font, text: String, width: float) -> Array:
		var lines := []
		var line := ""
		for word in text.split(" "):
			var tryout := word if line.is_empty() else line + " " + word
			if font.get_string_size(tryout, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x > width and not line.is_empty():
				lines.append(line)
				line = word
			else:
				line = tryout
		if not line.is_empty():
			lines.append(line)
		return lines
