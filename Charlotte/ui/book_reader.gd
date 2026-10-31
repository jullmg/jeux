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
	{"title": "Caramel veut voir la neige", "cover": "#E8A65A", "pages": [
		["hamster", "Caramel est un hamster qui vit dans un grand terrarium, près d'une fenêtre."],
		["window", "Dehors, de petits flocons blancs tombent du ciel. « Qu'est-ce que c'est ? » se demande Caramel."],
		["snowball", "Charlotte rentre de l'école avec une boule de neige dans sa mitaine. Elle la montre à Caramel."],
		["melt", "Caramel la touche du bout du nez. C'est froid ! La boule fond et devient une petite flaque."],
		["sleep", "« La neige, c'est de l'eau qui fait un câlin froid », décide Caramel, avant de faire la sieste. Fin."],
	]},
]

var _book := -1
var _page := 0
var _panel: Panel
var _art: _Art
var _text: Label
var _title: Label
var _prev: Button
var _next: Button
var _shelf: HBoxContainer


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
	_shelf.position = Vector2(70, 110)
	_shelf.add_theme_constant_override("separation", 40)
	_panel.add_child(_shelf)
	for i in BOOKS.size():
		var b := Button.new()
		b.text = BOOKS[i].title
		b.custom_minimum_size = Vector2(200, 300)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		var cover := Color(BOOKS[i].cover)
		b.add_theme_stylebox_override("normal", _box(cover, cover.darkened(0.4), 6, 10))
		b.add_theme_stylebox_override("hover", _box(cover.lightened(0.1), YELLOW, 6, 10))
		b.add_theme_stylebox_override("pressed", _box(cover, YELLOW, 6, 10))
		b.pressed.connect(_open_book.bind(i))
		_shelf.add_child(b)
	# The open book: picture page on the left, text page on the right.
	_art = _Art.new()
	_art.position = Vector2(60, 80)
	_art.size = Vector2(440, 400)
	_art.clip_contents = true
	_art.visible = false
	_panel.add_child(_art)
	_text = _label("", 26)
	_text.position = Vector2(540, 110)
	_text.size = Vector2(440, 340)
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
	_book = i
	_page = 0
	_show()


func _turn(dir: int) -> void:
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
class _Art:
	extends Control

	var kind := ""

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("#FFFDF7"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("#C8A27A"), false, 4.0)
		var c := size / 2.0
		var night := kind in ["moon", "jump", "bowl", "sleep", "stars", "planet"]
		var sky := Color("#1E2A4A") if night else Color("#CDE7F6")
		draw_rect(Rect2(8, 8, w - 16, h * 0.62), sky)
		draw_rect(Rect2(8, h * 0.62 + 8, w - 16, h * 0.38 - 16), Color("#E6D3A8") if kind in ["box", "home", "hamster", "window", "snowball", "melt"] else Color("#9BCB6A"))
		match kind:
			"nut", "dig":
				_tree(Vector2(120, h * 0.62 + 8), Color("#D9682B"))
				_squirrel(c + Vector2(40, 70))
				_nut(c + Vector2(110, 96) if kind == "nut" else c + Vector2(80, 112))
				if kind == "dig":
					draw_circle(c + Vector2(80, 116), 20, Color("#7A5236"))
			"snow":
				draw_rect(Rect2(8, h * 0.62 + 8, w - 16, h * 0.38 - 16), Color("#F4F7FA"))
				_tree(Vector2(120, h * 0.62 + 8), Color("#F4F7FA"))
				_squirrel(c + Vector2(40, 70))
				for i in 40:
					draw_circle(Vector2(fmod(i * 53.0, w - 20) + 10, fmod(i * 37.0, h * 0.6) + 10), 3, Color.WHITE)
			"sprout":
				draw_line(c + Vector2(0, 110), c + Vector2(0, 70), Color("#4E8A3A"), 5.0)
				draw_circle(c + Vector2(-12, 70), 12, Color("#7CCB5A"))
				draw_circle(c + Vector2(12, 64), 12, Color("#7CCB5A"))
				_squirrel(c + Vector2(110, 80))
			"tree":
				_tree(c + Vector2(-40, 120), Color("#7CCB5A"))
				_squirrel(c + Vector2(110, 80))
			"cat", "jump", "sleep":
				if kind == "cat":
					draw_circle(Vector2(w - 80, 60), 30, Color("#FFD23F"))
				else:
					_moon(Vector2(w - 90, 70))
				draw_rect(Rect2(20, h * 0.5, w - 40, 8), Color("#2B2B2B"))
				_cat(c + Vector2(0, 30 if kind != "jump" else -60), kind == "sleep")
			"moon":
				_moon(c + Vector2(0, -40))
				_cat(c + Vector2(-100, 110), false)
			"bowl":
				_moon(Vector2(w - 90, 70))
				_cat(c + Vector2(-60, 90), false)
				draw_circle(c + Vector2(60, 140), 34, Color("#F4F1EA"))
				draw_circle(c + Vector2(60, 140), 26, Color("#FFFDF5"))
				draw_circle(c + Vector2(60, 140), 12, Color("#FFF3B0"))
			"box", "rocket", "home":
				draw_rect(Rect2(c.x - 70, c.y + 10, 140, 110), Color("#C9A26E"))
				draw_rect(Rect2(c.x - 70, c.y + 10, 140, 110), Color("#8A6A40"), false, 3.0)
				if kind != "box":
					draw_colored_polygon(PackedVector2Array([c + Vector2(-70, 10), c + Vector2(0, -80), c + Vector2(70, 10)]), Color("#E04F5F"))
					draw_circle(c + Vector2(0, 60), 22, Color("#4FA3E0"))
				if kind == "box":
					for i in 30:
						draw_line(Vector2(fmod(i * 61.0, w), fmod(i * 23.0, h * 0.6)), Vector2(fmod(i * 61.0, w) - 4, fmod(i * 23.0, h * 0.6) + 12), Color("#7FA8D0"), 2.0)
			"stars", "planet":
				for i in 60:
					draw_circle(Vector2(fmod(i * 71.0, w - 20) + 10, fmod(i * 43.0, h * 0.6) + 10), 2, Color.WHITE)
				if kind == "planet":
					draw_circle(c + Vector2(0, 160), 150, Color("#9B6FD8"))
					for i in 3:
						var a := c + Vector2(-60 + i * 60, 30)
						draw_circle(a, 16, Color("#7CCB5A"))
						draw_circle(a + Vector2(-6, -4), 4, Color.WHITE)
						draw_circle(a + Vector2(6, -4), 4, Color.WHITE)
				else:
					draw_colored_polygon(PackedVector2Array([c + Vector2(-30, 40), c + Vector2(0, -60), c + Vector2(30, 40)]), Color("#C9A26E"))
					draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 40), c + Vector2(14, 40), c + Vector2(0, 90)]), Color("#FFB347"))
			"hamster", "window", "snowball", "melt":
				draw_rect(Rect2(40, 40, 160, 150), Color("#8FC6E8"))
				draw_rect(Rect2(40, 40, 160, 150), Color.WHITE, false, 6.0)
				if kind != "hamster":
					for i in 20:
						draw_circle(Vector2(50 + fmod(i * 37.0, 140), 50 + fmod(i * 29.0, 130)), 3, Color.WHITE)
				_hamster(c + Vector2(60, 110))
				if kind == "snowball":
					draw_circle(c + Vector2(130, 80), 22, Color("#F4F7FA"))
				if kind == "melt":
					draw_set_transform(c + Vector2(110, 132), 0.0, Vector2(1.0, 0.3))
					draw_circle(Vector2.ZERO, 26, Color("#9FD3F0"))
					draw_set_transform(Vector2.ZERO)

	func _tree(base: Vector2, leaves: Color) -> void:
		draw_line(base, base + Vector2(0, -130), Color("#6E4E32"), 14.0)
		for o in [Vector2(-40, -130), Vector2(34, -138), Vector2(0, -168), Vector2(-16, -104), Vector2(40, -100)]:
			draw_circle(base + o, 40, leaves)

	func _squirrel(at: Vector2) -> void:
		draw_circle(at + Vector2(-26, -30), 24, Color("#8E7A6A"))
		draw_circle(at, 20, Color("#A08A78"))
		draw_circle(at + Vector2(18, -20), 13, Color("#A08A78"))
		draw_circle(at + Vector2(24, -22), 2.5, Color.BLACK)

	func _nut(at: Vector2) -> void:
		draw_circle(at, 12, Color("#8A5A2A"))
		draw_rect(Rect2(at.x - 12, at.y - 14, 24, 8), Color("#5A3A1A"))

	func _moon(at: Vector2) -> void:
		draw_circle(at, 46, Color("#FFF3C4"))
		draw_circle(at + Vector2(-14, -10), 8, Color("#F2E3A8"))
		draw_circle(at + Vector2(16, 12), 6, Color("#F2E3A8"))

	func _cat(at: Vector2, asleep: bool) -> void:
		draw_circle(at, 32, Color("#8E9096"))
		draw_circle(at + Vector2(0, -38), 24, Color("#8E9096"))
		for e in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([at + Vector2(e * 6, -56), at + Vector2(e * 22, -74), at + Vector2(e * 24, -46)]), Color("#8E9096"))
			if asleep:
				draw_line(at + Vector2(e * 9 - 5, -40), at + Vector2(e * 9 + 5, -40), Color.BLACK, 2.0)
			else:
				draw_circle(at + Vector2(e * 9, -40), 4, Color("#7CCB5A"))

	func _hamster(at: Vector2) -> void:
		draw_circle(at, 30, Color("#E8A65A"))
		draw_circle(at + Vector2(6, 6), 18, Color("#FBF1E2"))
		draw_circle(at + Vector2(-14, -26), 9, Color("#E8A65A"))
		draw_circle(at + Vector2(14, -26), 9, Color("#E8A65A"))
		draw_circle(at + Vector2(-8, -6), 3.5, Color.BLACK)
		draw_circle(at + Vector2(10, -6), 3.5, Color.BLACK)
