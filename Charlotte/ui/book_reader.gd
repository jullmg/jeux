class_name BookReader
extends CanvasLayer
## Charlotte's books, opened from the shelf in her bedroom: pick a book, then turn the pages (a little
## picture on the left, the story on the right). All the stories are original, written for the game.

signal closed

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
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
var _text: Label
var _title: Label
var _prev: Button
var _next: Button
var _shelf: HBoxContainer
var _spread: Control


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
	_shelf = HBoxContainer.new()
	_shelf.position = Vector2(56, 130)
	_shelf.add_theme_constant_override("separation", 22)
	_panel.add_child(_shelf)
	for i in BOOKS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 236)
		var cover := Color(BOOKS[i].cover)
		b.add_theme_stylebox_override("normal", _box(cover, cover.darkened(0.4), 5, 10))
		b.add_theme_stylebox_override("hover", _box(cover.lightened(0.1), YELLOW, 5, 10))
		b.add_theme_stylebox_override("pressed", _box(cover, YELLOW, 5, 10))
		b.pressed.connect(_open_book.bind(i))
		# The cover: the first page's picture, with the title on a band across the bottom.
		var art := _Cover.new()
		art.kind = BOOKS[i].pages[0][0]
		art.title = BOOKS[i].title
		art.band = cover
		art.position = Vector2(10, 10)
		art.size = b.custom_minimum_size - Vector2(20, 20)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.clip_contents = true
		b.add_child(art)
		_shelf.add_child(b)
	# The open book: two cream pages with a fold down the middle, the picture on the left, the words on the right.
	_spread = _Spread.new()
	_spread.position = Vector2(34, 70)
	_spread.size = Vector2(972, 430)
	_spread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spread.visible = false
	_panel.add_child(_spread)
	_art = _Art.new()
	_art.position = Vector2(66, 92)
	_art.size = Vector2(404, 386)
	_art.clip_contents = true
	_art.visible = false
	_panel.add_child(_art)
	_text = _label("", 26)
	_text.position = Vector2(556, 120)
	_text.size = Vector2(404, 330)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_color", Color("#3A2A1E"))
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
	_text.text = pages[_page][1]
	_spread.page = _page + 1
	_spread.of_pages = pages.size()
	_spread.queue_redraw()
	_next.text = "Page suivante ›" if _page < pages.size() - 1 else "Fin ›"


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
	const INDOORS := ["box", "home", "hamster", "window", "snowball", "melt", "nest"]

	var kind := ""

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var night := kind in NIGHT_KINDS
		var inside := kind in INDOORS
		# The picture itself, on its own little page.
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FFFDF7"))
		var horizon := h * 0.62
		var sky_top := Color("#20305C") if night else Color("#9FD2F0")
		var sky_low := Color("#4A3F72") if night else Color("#DCEFF8")
		if inside:
			sky_top = Color("#E8D9BE")
			sky_low = Color("#F6ECD8")
		draw_polygon(PackedVector2Array([Vector2(6, 6), Vector2(w - 6, 6), Vector2(w - 6, horizon), Vector2(6, horizon)]),
			PackedColorArray([sky_top, sky_top, sky_low, sky_low]))
		if night:
			_stars(w, horizon)
		elif not inside:
			_clouds(w)
		# The ground: a soft rise, not a flat band.
		var earth := Color("#C9A26E") if inside else (Color("#3E5E4A") if night else Color("#8FC45E"))
		var ground := PackedVector2Array([Vector2(6, h - 6), Vector2(6, horizon + 10)])
		var steps := 10
		for i in steps + 1:
			var t := float(i) / steps
			ground.append(Vector2(6 + t * (w - 12), horizon + 10 - sin(t * PI) * 16.0))
		ground.append(Vector2(w - 6, h - 6))
		draw_colored_polygon(ground, earth)
		draw_polyline(ground.slice(1, ground.size() - 1), earth.darkened(0.22), 3.0, true)
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
				_balcony(w, h * 0.56)
				_cat(Vector2(w * 0.45, h * 0.54), false)
			"jump", "sleep":
				_moon(Vector2(w - 86, 72))
				_balcony(w, h * 0.56)
				_cat(Vector2(w * 0.45, h * 0.54 - (60.0 if kind == "jump" else 0.0)), kind == "sleep")
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
				_carton(Vector2(w * 0.5, h * 0.66), kind != "box")
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
				_window(Vector2(w * 0.2, h * 0.22), kind != "hamster")
				_hamster(Vector2(w * 0.62, h * 0.74))
				if kind == "snowball":
					draw_circle(Vector2(w * 0.86, h * 0.64), 24, Color("#F2F7FB"))
					draw_arc(Vector2(w * 0.86, h * 0.64), 24, 0, TAU, 22, Color("#B9CCDA"), 2.0)
				if kind == "melt":
					draw_colored_polygon(_oval(Vector2(w * 0.84, h * 0.9), Vector2(30, 10)), Color("#9FD3F0"))
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
					_book_in_hands(Vector2(w * 0.44, h * 0.72))
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
						_window(Vector2(w * 0.42 + i * 58.0, h * 0.68), false, true)
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
		# The frame last, over everything.
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("#C8A27A"), false, 5.0)

	# ── little pieces ───────────────────────────────────────

	func _oval(c: Vector2, r: Vector2, from := 0.0, to := TAU) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := 26
		for i in n + 1:
			var a := from + (to - from) * i / n
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		return pts

	func _blob(c: Vector2, r: float, fill: Color, line := 2.5) -> void:
		draw_circle(c, r, fill)
		draw_arc(c, r, 0, TAU, 26, INK, line)

	func _stars(w: float, horizon: float) -> void:
		for i in 56:
			var p := Vector2(fmod(i * 71.0, w - 24) + 12, fmod(i * 43.0, horizon - 24) + 12)
			draw_circle(p, 1.0 + float(i % 3) * 0.7, Color(1, 1, 1, 0.9))

	func _clouds(w: float) -> void:
		for c in [[w * 0.18, 54.0, 1.0], [w * 0.62, 38.0, 0.72], [w * 0.86, 76.0, 0.56]]:
			var at := Vector2(c[0], c[1])
			var k: float = c[2]
			for o in [Vector2(-26, 6), Vector2(0, -6), Vector2(26, 4), Vector2(50, 10)]:
				draw_circle(at + o * k, 20.0 * k, Color(1, 1, 1, 0.92))

	func _falling(w: float, h: float, n: int) -> void:
		for i in n:
			draw_circle(Vector2(fmod(i * 53.0, w - 20) + 10, fmod(i * 37.0, h - 40) + 10), 3.2, Color(1, 1, 1, 0.95))

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

	func _tree(base: Vector2, leaves: Color) -> void:
		draw_colored_polygon(PackedVector2Array([base + Vector2(-13, 0), base + Vector2(13, 0),
			base + Vector2(7, -120), base + Vector2(-7, -120)]), Color("#6E4E32"))
		draw_line(base + Vector2(-2, -90), base + Vector2(-34, -120), Color("#6E4E32"), 7.0)
		draw_line(base + Vector2(3, -96), base + Vector2(32, -126), Color("#6E4E32"), 7.0)
		var crown := base + Vector2(0, -150)
		for o in [Vector2(-44, 14), Vector2(40, 18), Vector2(-16, -22), Vector2(22, -14), Vector2(0, 24)]:
			_blob(crown + o, 40, leaves)
		for o in [Vector2(-30, -6), Vector2(14, -24)]:
			draw_circle(crown + o, 16, leaves.lightened(0.22))

	func _squirrel(at: Vector2, facing: float) -> void:
		var tail := PackedVector2Array()
		for i in 16:
			var t := float(i) / 15.0
			tail.append(at + Vector2(-facing * (30.0 + sin(t * PI) * 26.0), -t * 86.0))
		for i in range(15, -1, -1):
			var t := float(i) / 15.0
			tail.append(at + Vector2(-facing * (62.0 + sin(t * PI) * 10.0), -t * 78.0))
		draw_colored_polygon(tail, Color("#A08A78"))
		draw_polyline(tail + PackedVector2Array([tail[0]]), INK, 2.2, true)
		_blob(at, 24, Color("#A08A78"))
		_blob(at + Vector2(facing * 18, -26), 17, Color("#A08A78"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(facing * 8, -38), at + Vector2(facing * 14, -52),
			at + Vector2(facing * 22, -40)]), Color("#8E7A6A"))
		draw_circle(at + Vector2(facing * 25, -28), 3.0, INK)
		draw_circle(at + Vector2(facing * 33, -24), 2.4, Color("#5E4232"))
		draw_line(at + Vector2(facing * 10, 8), at + Vector2(facing * 22, 18), INK, 3.0)

	func _nut(at: Vector2) -> void:
		_blob(at, 13, Color("#A9743A"), 2.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-13, -6), at + Vector2(13, -6),
			at + Vector2(11, -16), at + Vector2(-11, -16)]), Color("#6E4A24"))

	func _cat(at: Vector2, asleep: bool) -> void:
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
		_blob(at, 32, Color("#E8A65A"))
		draw_circle(at + Vector2(0, 8), 20, Color("#FBF1E2"))
		for e in [-1.0, 1.0]:
			_blob(at + Vector2(e * 22, -26), 10, Color("#E8A65A"), 2.0)
			draw_circle(at + Vector2(e * 12, -8), 4.0, INK)
			draw_circle(at + Vector2(e * 20, 4), 9, Color("#F7D7A8"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -2), at + Vector2(5, -2), at + Vector2(0, 4)]), Color("#C9748A"))
		draw_line(at + Vector2(-26, 2), at + Vector2(-42, -2), INK, 1.6)
		draw_line(at + Vector2(26, 2), at + Vector2(42, -2), INK, 1.6)

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
		_blob(at, 16, Color("#9A9AA2"), 2.0)
		_blob(at + Vector2(16, -8), 10, Color("#9A9AA2"), 2.0)
		_blob(at + Vector2(10, -18), 7, Color("#C9A0A8"), 1.6)
		draw_circle(at + Vector2(22, -10), 2.4, INK)
		draw_line(at + Vector2(-14, 4), at + Vector2(-44, -6), INK, 2.2)

	func _balcony(w: float, y: float) -> void:
		draw_rect(Rect2(14, y, w - 28, 10), Color("#6E5444"))
		draw_rect(Rect2(14, y, w - 28, 10), INK, false, 2.0)
		for x in range(24, int(w) - 24, 26):
			draw_line(Vector2(x, y + 10), Vector2(x, y + 48), Color("#2B2B33"), 3.0)
		draw_line(Vector2(14, y + 48), Vector2(w - 14, y + 48), Color("#2B2B33"), 4.0)

	func _window(at: Vector2, snowing: bool, lit := false) -> void:
		var r := Rect2(at, Vector2(120, 96))
		draw_rect(r, Color("#FFE9A8") if lit else Color("#8FC6E8"))
		draw_rect(r, Color.WHITE, false, 6.0)
		draw_rect(r, INK, false, 2.0)
		draw_line(at + Vector2(60, 0), at + Vector2(60, 96), Color.WHITE, 4.0)
		draw_line(at + Vector2(0, 48), at + Vector2(120, 48), Color.WHITE, 4.0)
		if snowing:
			for i in 14:
				draw_circle(at + Vector2(10 + fmod(i * 31.0, 100), 10 + fmod(i * 23.0, 76)), 3.0, Color.WHITE)

	func _carton(at: Vector2, rocket: bool) -> void:
		var box := Rect2(at + Vector2(-72, -10), Vector2(144, 110))
		draw_rect(box, Color("#C9A26E"))
		draw_rect(box, INK, false, 3.0)
		draw_line(at + Vector2(-72, 20), at + Vector2(72, 20), Color("#8A6A40"), 3.0)
		if rocket:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-72, -10), at + Vector2(0, -98), at + Vector2(72, -10)]), Color("#E04F5F"))
			draw_polyline(PackedVector2Array([at + Vector2(-72, -10), at + Vector2(0, -98), at + Vector2(72, -10)]), INK, 3.0, true)
			_blob(at + Vector2(0, 42), 22, Color("#9FD3F0"))

	func _rocket_flying(at: Vector2) -> void:
		draw_colored_polygon(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(0, -70), at + Vector2(30, 40)]), Color("#E8E4DA"))
		draw_polyline(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(0, -70), at + Vector2(30, 40), at + Vector2(-30, 40)]), INK, 3.0, true)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-30, 40), at + Vector2(-54, 64), at + Vector2(-20, 48)]), Color("#E04F5F"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(30, 40), at + Vector2(54, 64), at + Vector2(20, 48)]), Color("#E04F5F"))
		_blob(at + Vector2(0, -16), 16, Color("#9FD3F0"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-16, 44), at + Vector2(16, 44), at + Vector2(0, 104)]), Color("#FFB347"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 44), at + Vector2(8, 44), at + Vector2(0, 80)]), Color("#FFF3B0"))

	func _plex_backs(w: float, horizon: float) -> void:
		for i in 3:
			var x := 10.0 + i * (w - 20.0) / 3.0
			var top := horizon - 150.0 + (i % 2) * 24.0
			draw_rect(Rect2(x, top, (w - 20.0) / 3.0 - 10.0, horizon - top + 14.0), Color("#9C5A44") if i % 2 == 0 else Color("#B08A68"))
			draw_rect(Rect2(x, top, (w - 20.0) / 3.0 - 10.0, horizon - top + 14.0), INK, false, 2.0)
			for k in 2:
				draw_rect(Rect2(x + 16 + k * 52, top + 26, 30, 40), Color("#FFE9A8") if (i + k) % 2 == 0 else Color("#7F97A8"))
		draw_line(Vector2(10, horizon + 14), Vector2(w - 10, horizon + 14), Color("#6E6A62"), 3.0)

	func _croque_livre(at: Vector2) -> void:
		draw_rect(Rect2(at + Vector2(-6, 0), Vector2(12, 64)), Color("#6E5A48"))
		draw_rect(Rect2(at + Vector2(-44, -58), Vector2(88, 60)), Color("#4FA3A0"))
		draw_rect(Rect2(at + Vector2(-44, -58), Vector2(88, 60)), INK, false, 2.5)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-52, -56), at + Vector2(0, -88), at + Vector2(52, -56)]), Color("#5E6B73"))
		for i in 4:
			draw_rect(Rect2(at + Vector2(-34 + i * 17, -48), Vector2(12, 36)), [Color("#E74C3C"), Color("#F1C40F"), Color("#3498DB"), Color("#2ECC71")][i])

	func _girl(at: Vector2, dress: String) -> void:
		draw_colored_polygon(PackedVector2Array([at + Vector2(-20, 0), at + Vector2(20, 0), at + Vector2(13, -52), at + Vector2(-13, -52)]), Color(dress))
		draw_polyline(PackedVector2Array([at + Vector2(-20, 0), at + Vector2(20, 0), at + Vector2(13, -52), at + Vector2(-13, -52), at + Vector2(-20, 0)]), INK, 2.2, true)
		_blob(at + Vector2(0, -70), 22, Color("#F3CDB0"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-23, -70), at + Vector2(-23, -92), at + Vector2(23, -92), at + Vector2(23, -70),
			at + Vector2(16, -78), at + Vector2(-16, -78)]), Color("#8A3B1E"))
		draw_circle(at + Vector2(-8, -70), 2.6, INK)
		draw_circle(at + Vector2(8, -70), 2.6, INK)
		draw_arc(at + Vector2(0, -64), 7.0, 0.3, PI - 0.3, 10, INK, 2.0)
		draw_line(at + Vector2(-16, -8), at + Vector2(-12, 16), INK, 3.0)
		draw_line(at + Vector2(16, -8), at + Vector2(12, 16), INK, 3.0)

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

	func _roof_line(w: float, horizon: float) -> void:
		var x := 6.0
		var i := 0
		while x < w - 6.0:
			var ww := 70.0 + float(i % 3) * 26.0
			var top := horizon + 10.0 - 60.0 - float((i * 7) % 4) * 16.0
			draw_rect(Rect2(x, top, ww, horizon + 16.0 - top), Color("#4A4458") if i % 2 == 0 else Color("#5A5268"))
			draw_rect(Rect2(x, top, ww, horizon + 16.0 - top), INK, false, 2.0)
			if i % 2 == 0:
				draw_rect(Rect2(x + 14, top + 18, 22, 26), Color("#FFE9A8"))
			x += ww + 6.0
			i += 1


# The open book under the picture and the words: two cream pages, the fold between them, and the page number.
class _Spread:
	extends Control

	var page := 1
	var of_pages := 5

	func _draw() -> void:
		var half := size.x / 2.0
		for side in 2:
			var r := Rect2(Vector2(side * half, 0), Vector2(half, size.y))
			draw_rect(r, Color("#FFFBF0"))
			draw_rect(r, Color("#DCCFB4"), false, 2.0)
		# The fold: a shadow either side of the middle.
		for i in 10:
			var t := i / 9.0
			var a := 0.16 * (1.0 - t)
			draw_rect(Rect2(half - 16.0 * t, 0, 16.0 * t, size.y), Color(0.45, 0.33, 0.2, a * 0.5))
			draw_rect(Rect2(half, 0, 16.0 * t, size.y), Color(0.45, 0.33, 0.2, a * 0.5))
		draw_line(Vector2(half, 6), Vector2(half, size.y - 6), Color("#C9B894"), 2.0)
		# A page number at the foot of the right page.
		var font := ThemeDB.fallback_font
		var words := "%d / %d" % [page, of_pages]
		var at := Vector2(size.x - 70.0, size.y - 16.0)
		draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#A89878"))


# A book on the shelf: its first picture, with the title on a band across the bottom.
class _Cover:
	extends _Art

	var title := ""
	var band := Color("#B5603F")

	func _draw() -> void:
		super._draw()
		var font := ThemeDB.fallback_font
		var h := 72.0
		draw_rect(Rect2(Vector2(0, size.y - h), Vector2(size.x, h)), Color(band, 0.92))
		draw_line(Vector2(0, size.y - h), Vector2(size.x, size.y - h), Color(1, 1, 1, 0.5), 2.0)
		var lines := _wrap(font, title, size.x - 16.0)
		for i in lines.size():
			var y := size.y - h + 26.0 + i * 20.0
			draw_string(font, Vector2(8, y), lines[i], HORIZONTAL_ALIGNMENT_CENTER, size.x - 16.0, 17, Color.WHITE)

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
