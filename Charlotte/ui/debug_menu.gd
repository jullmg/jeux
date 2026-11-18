extends CanvasLayer
## Autoload. `--season=<spring|summer|autumn|winter>` (or printemps/été/automne/hiver) picks the season at
## start, and `--halloween` starts the evening of the Halloween quest (step 2: night out on the rounds). In debug builds, F1 opens a small menu to switch seasons while playing, to reset, start or finish any quest
## (to test it again) and to teleport to any place of the game: the scene reloads with a fade and Charlotte reappears
## where she was (or at the chosen place). EVERY NEW PLACE goes in PLACES below; a scene (.tscn in res://scenes) that is not
## listed shows up on its own under "Autres lieux" so it can never be forgotten.

const ALIASES := {"printemps": "spring", "ete": "summer", "été": "summer", "automne": "autumn", "hiver": "winter"}
## Debug: everywhere is open. Charlotte crosses the streets whatever her age, the back lanes and the two dépanneurs
## take her in even on Halloween night, and her map is no longer greyed over. Set from the menu, kept for the session
## only (never saved), and off in a release build since the menu cannot be opened there. Gates ask it through
## `blocked()`, never by reading it.
var no_limits := false
## Debug: Charlotte crosses without stopping to look both ways first (`StreetScene._look_both_ways`), to test crossings
## quickly. Session only, never saved, like `no_limits`.
var skip_look := false
## The story flags each quest leaves behind, cleared with it.
## Story flags that belong to no quest, cleared by "Tout effacer".
const OTHER_FLAGS := ["met_twins", "met_billie_auguste", "devoirs", "candy_bag_kind"]
const QUEST_FLAGS := {"amies": ["met_twins", "met_billie_auguste"], "cachette": ["cachette_found"], "livre": ["book_found", "croque_checked"], "halloween": ["halloween_step", "candy", "candy_bag", "candy_bag_kind", "halloween_doors", "halloween_counted", "halloween_total", "winter_greeting"], "hamster": ["hamster_fed"], "menage": ["tidied"], "plants": ["watered"], "cinema": ["cinema_step", "cinema_snacks"]}
## What a quest puts in her arms (a lost cat's quest id is the cat's id, handled by `Carry.cat_id()`).
const QUEST_CARRIES := {"milk": "milk", "plants": "can", "menage": "toy", "livre": "book", "chips": "chips", "cinema": "snacks"}

## The places to teleport to, in the order of the menu: {name, scene, and where: `x` (Charlotte's x in the scene), or `arrive`
## (the Transition.arrive key of a corner or lane opening), or nothing for the scene's usual start}. Sorted like the map:
## {"group": …} is a category (folds open and shut), {"sub": …} one street side, one building or one lane inside it; the
## avenues' corners run north to south (Holt, Dandurand, Masson), Masson's blocks west to east (D'Iberville to Saint-Michel),
## each corner "au nord" / "au sud" when there is one on both sides of the cross street. **Add a line in its place for each new
## place** (a new street, room, shop, lane, corner, a spot inside a building); a scene left out shows under "Autres lieux".
const PLACES := [
	{"group": "Mon bloc"},
	{"sub": "Chez Charlotte"},
	{"name": "Vestibule", "scene": "house", "x": 300.0},
	{"name": "Salon", "scene": "house", "x": 1500.0},
	{"name": "Corridor (télé)", "scene": "house", "x": 2900.0},
	{"name": "Cuisine (Maman, arrosoir, porte de la cour)", "scene": "house", "x": 3700.0},
	{"name": "Chambre de Charlotte", "scene": "house", "x": 5700.0},
	{"sub": "6e Avenue, côté ouest (sa maison)"},
	{"name": "Devant chez Charlotte", "scene": "main"},
	{"name": "Coin Holt, au nord", "scene": "main", "arrive": "6e_from_6e_est_holt_nord"},
	{"name": "Coin Holt, au sud", "scene": "main", "arrive": "6e_from_holt"},
	{"name": "Coin Dandurand, au nord (Xin-Xin)", "scene": "main", "arrive": "6e_from_dandurand"},
	{"name": "Coin Dandurand, au sud (l'école)", "scene": "main", "arrive": "6e_from_6e_est_dandurand_sud"},
	{"name": "Coin Masson, au nord (l'église)", "scene": "main", "arrive": "6e_from_masson"},
	{"name": "Coin Masson, au sud", "scene": "main", "arrive": "6e_from_6e_est_masson_sud"},
	{"sub": "Les ruelles"},
	{"name": "Ruelle du milieu (la cour de Charlotte)", "scene": "ruelle"},
	{"name": "Ruelle du milieu (les jumelles)", "scene": "ruelle", "x": 2400.0},
	{"name": "Ruelle près de Holt", "scene": "ruelle_holt"},
	{"name": "Ruelle verte (près de Dandurand)", "scene": "ruelle_dandurand"},
	{"group": "Autour du bloc"},
	{"sub": "Rue Holt (côté sud)"},
	{"name": "Coin 6e, côté est", "scene": "holt", "arrive": "holt_from_6e_est"},
	{"name": "Coin 6e (dépanneur Oh Bon!)", "scene": "holt", "arrive": "holt_from_6e"},
	{"name": "Milieu", "scene": "holt"},
	{"name": "Coin 5e", "scene": "holt", "arrive": "holt_from_5e"},
	{"name": "Coin 5e, côté ouest", "scene": "holt", "arrive": "holt_from_5e_ouest"},
	{"sub": "Rue Dandurand (côté nord)"},
	{"name": "Coin 5e, côté ouest", "scene": "dandurand", "arrive": "dandurand_from_5e_ouest"},
	{"name": "Coin 5e", "scene": "dandurand", "arrive": "dandurand_from_5e"},
	{"name": "Dépanneur Xin-Xin", "scene": "dandurand"},
	{"name": "Coin 6e", "scene": "dandurand", "arrive": "dandurand_from_6e"},
	{"name": "Coin 6e, côté est", "scene": "dandurand", "arrive": "dandurand_from_6e_est"},
	{"sub": "6e Avenue, côté est"},
	{"name": "Coin Holt, au nord", "scene": "sixieme_est", "arrive": "6e_est_from_6e_holt_nord"},
	{"name": "Coin Holt, au sud", "scene": "sixieme_est", "arrive": "6e_est_from_6e_holt"},
	{"name": "Milieu", "scene": "sixieme_est"},
	{"name": "Coin Dandurand, au nord", "scene": "sixieme_est", "arrive": "6e_est_from_6e_dandurand"},
	{"name": "Coin Dandurand, au sud", "scene": "sixieme_est", "arrive": "6e_est_from_6e_dandurand_sud"},
	{"name": "Coin Masson, au nord", "scene": "sixieme_est", "arrive": "6e_est_from_masson"},
	{"name": "Coin Masson, au sud", "scene": "sixieme_est", "arrive": "6e_est_from_6e_masson_sud"},
	{"sub": "5e Avenue, côté est (le dos du bloc)"},
	{"name": "Coin Holt, au nord", "scene": "cinquieme", "arrive": "5e_from_5e_ouest_holt_nord"},
	{"name": "Coin Holt, au sud", "scene": "cinquieme", "arrive": "5e_from_holt"},
	{"name": "Milieu", "scene": "cinquieme"},
	{"name": "Coin Dandurand, au nord", "scene": "cinquieme", "arrive": "5e_from_dandurand"},
	{"name": "Coin Dandurand, au sud (l'école)", "scene": "cinquieme", "arrive": "5e_from_5e_ouest_dandurand_sud"},
	{"name": "Coin Masson, au nord", "scene": "cinquieme", "arrive": "5e_from_masson"},
	{"name": "Coin Masson, au sud", "scene": "cinquieme", "arrive": "5e_from_5e_ouest_masson_sud"},
	{"sub": "5e Avenue, côté ouest"},
	{"name": "Coin Holt, au nord", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_5e_holt_nord"},
	{"name": "Coin Holt, au sud", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_5e_holt"},
	{"name": "Milieu", "scene": "cinquieme_ouest"},
	{"name": "Coin Dandurand, au nord", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_5e_dandurand"},
	{"name": "Coin Dandurand, au sud", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_5e_dandurand_sud"},
	{"name": "Coin Masson, au nord", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_masson"},
	{"name": "Coin Masson, au sud", "scene": "cinquieme_ouest", "arrive": "5e_ouest_from_5e_masson_sud"},
	{"group": "Rue Masson"},
	{"sub": "Côté nord (numéros impairs)"},
	{"name": "Coin D'Iberville", "scene": "masson_impair", "arrive": "masson_impair_from_rue_iberville_iberville_molson"},
	{"name": "Entre Molson et la 1re", "scene": "masson_impair", "arrive": "masson_impair_from_rue_molson_molson_1re"},
	{"name": "Entre la 1re et la 2e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_1re_1re_2e"},
	{"name": "Entre la 2e et la 3e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_2e_2e_3e"},
	{"name": "Entre la 3e et la 4e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_3e_3e_4e"},
	{"name": "Entre la 4e et la 5e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_4e_4e_5e"},
	{"name": "Entre la 5e et la 6e (l'église)", "scene": "masson_impair", "arrive": "masson_impair_from_rue_5e_5e_6e"},
	{"name": "Entre la 6e et la 7e (Fraîchement Bon)", "scene": "masson_impair", "arrive": "masson_impair_from_rue_6e_6e_7e"},
	{"name": "Entre la 7e et la 8e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_7e_7e_8e"},
	{"name": "Entre la 8e et la 9e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_8e_8e_9e"},
	{"name": "Entre la 9e et la 10e", "scene": "masson_impair", "arrive": "masson_impair_from_rue_9e_9e_10e"},
	{"name": "Entre la 10e et Saint-Michel", "scene": "masson_impair", "arrive": "masson_impair_from_rue_stmichel_10e_stmichel"},
	{"sub": "Côté sud (numéros pairs)"},
	{"name": "Coin D'Iberville", "scene": "masson_pair", "arrive": "masson_pair_from_rue_iberville_iberville_molson"},
	{"name": "Entre Molson et la 1re (le parc)", "scene": "masson_pair", "arrive": "masson_pair_from_rue_1re_molson_1re"},
	{"name": "Entre la 1re et la 2e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_2e_1re_2e"},
	{"name": "Entre la 2e et la 3e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_3e_2e_3e"},
	{"name": "Entre la 3e et la 4e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_4e_3e_4e"},
	{"name": "Entre la 4e et la 5e (Dollarama)", "scene": "masson_pair", "arrive": "masson_pair_from_rue_5e_4e_5e"},
	{"name": "Entre la 5e et la 6e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_6e_5e_6e"},
	{"name": "Entre la 6e et la 7e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_7e_6e_7e"},
	{"name": "Entre la 7e et la 8e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_8e_7e_8e"},
	{"name": "Entre la 8e et la 9e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_9e_8e_9e"},
	{"name": "Entre la 9e et la 10e", "scene": "masson_pair", "arrive": "masson_pair_from_rue_10e_9e_10e"},
	{"name": "Entre la 10e et Saint-Michel", "scene": "masson_pair", "arrive": "masson_pair_from_rue_stmichel_10e_stmichel"},
	{"group": "Magasins"},
	{"sub": "Dépanneur Xin-Xin (rue Dandurand)"},
	{"name": "Entrée", "scene": "depanneur"},
	{"name": "Comptoir", "scene": "depanneur", "x": 1000.0},
	{"name": "Bonbons et chips", "scene": "depanneur", "x": 1750.0},
	{"name": "Sloche et café", "scene": "depanneur", "x": 2450.0},
	{"name": "Frigos et lait", "scene": "depanneur", "x": 3100.0},
	{"sub": "Dépanneur Oh Bon! (rue Holt)"},
	{"name": "Entrée", "scene": "ohbon"},
	{"name": "Comptoir et télé", "scene": "ohbon", "x": 1100.0},
	{"name": "Bonbons et chips", "scene": "ohbon", "x": 1900.0},
	{"name": "Frigos et lait", "scene": "ohbon", "x": 2800.0},
	{"sub": "Dollarama (rue Masson, côté sud)"},
	{"name": "Entrée et caisses", "scene": "dollarama"},
	{"name": "Allée 1 : fête", "scene": "dollarama", "x": 7300.0},
	{"name": "Allée 2 : cuisine", "scene": "dollarama", "x": 10900.0},
	{"name": "Allée 3 : entretien", "scene": "dollarama", "x": 14500.0},
	{"name": "Allée 4 : bonbons et collations", "scene": "dollarama", "x": 18100.0},
	{"name": "Allée 5 : jouets et école", "scene": "dollarama", "x": 21700.0},
	{"name": "Allée 6 : saison", "scene": "dollarama", "x": 25300.0},
	{"sub": "Fraîchement Bon (rue Masson, côté nord)"},
	{"name": "Entrée et caisse", "scene": "fraichement_bon"},
	{"name": "Fruits et légumes", "scene": "fraichement_bon", "x": 2000.0},
	{"name": "Épicerie fine et fromages", "scene": "fraichement_bon", "x": 3700.0},
	{"group": "Autres"},
	{"name": "Écran titre", "scene": "intro"},
]
## The scenes that are indoors: a place's `x` there is where she stands inside (Transition.inside_x), not on a street.
const INTERIORS: Array[String] = ["house", "depanneur", "ohbon", "dollarama", "fraichement_bon"]
## Scenes that are not places to go to (listed nowhere on purpose).
const NOT_PLACES: Array[String] = []

var _panel: PanelContainer


## **THE one way to stop Charlotte going somewhere.** `rule` is why she may not (too young to cross, a lane in the
## dark, a shop that has closed…): this returns true when she really is stopped, and false while "Sans limites" is on.
##
##     if DebugMenu.blocked(GameState.age < CROSS_AGE):
##         Bubble.say(...)   # she says why and stays where she is
##         return
##
## **Every new gate goes through it**, so the debug switch opens that place too without anyone having to remember it.
## A limit that is not a yes-or-no refusal (the grey crayon on the map) reads `no_limits` instead.
func blocked(rule: bool) -> bool:
	return rule and not no_limits


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--season="):
			var s := arg.trim_prefix("--season=").to_lower()
			s = ALIASES.get(s, s)
			if s in Season.ALL:
				Season.current = s
		elif arg == "--halloween":
			# The Halloween evening, for a screenshot or a test run: the quest on, out on the rounds.
			GameState.quests[Halloween.QUEST] = "active"
			GameState.flags[Halloween.STEP] = 2


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		if _panel:
			_close()
		else:
			_open()


func _open() -> void:
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.12, 0.18, 0.92)
	box.border_color = Color("#FFD23F")
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.position = Vector2(20, 20)
	add_child(_panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	_panel.add_child(columns)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	columns.add_child(list)
	var title := Label.new()
	title.text = "Saisons (debug, F1)"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)
	for s in Season.ALL:
		var b := Button.new()
		b.text = ("▶ " if s == Season.current else "") + Season.NAMES[s]
		b.custom_minimum_size = Vector2(220, 40)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_switch.bind(s))
		list.add_child(b)
	_quest_list(columns)
	_places_list(columns)


# The places (see PLACES): a search box, then each category folded open or shut (a click on its heading), the street sides,
# buildings and lanes inside it, and last any scene nobody listed.
func _places_list(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	var title := Label.new()
	title.text = "Aller à…"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	column.add_child(_no_limits_button())
	column.add_child(_skip_look_button())
	var search := LineEdit.new()
	search.placeholder_text = "Chercher un lieu…"
	search.text = _search
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 15)
	column.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	search.text_changed.connect(func(text: String) -> void:
		_search = text
		_fill_places(list))
	_fill_places(list)


## Which categories are open (this session); the one holding the current scene opens by itself the first time.
static var _open_groups := {}
static var _search := ""


func _fill_places(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()
	var here := get_tree().current_scene.scene_file_path.get_file().get_basename() if get_tree().current_scene else ""
	var needle := _search.strip_edges().to_lower()
	# Split PLACES into categories, each a list of its subheadings and places.
	var groups: Array = []
	for place: Dictionary in PLACES:
		if place.has("group"):
			groups.append({"name": place.group, "items": []})
		elif not groups.is_empty():
			groups[-1].items.append(place)
	var known := {}
	for g: Dictionary in groups:
		var shown: Array = []
		var sub := ""
		var sub_shown := ""
		for item: Dictionary in g.items:
			if item.has("sub"):
				sub = item.sub
				continue
			known[item.scene] = true
			if needle != "" and not ("%s %s %s" % [g.name, sub, item.name]).to_lower().contains(needle):
				continue
			if sub != sub_shown:
				shown.append({"sub": sub})
				sub_shown = sub
			shown.append(item)
		if shown.is_empty():
			continue
		if not _open_groups.has(g.name):
			_open_groups[g.name] = g.items.any(func(p: Dictionary) -> bool: return str(p.get("scene", "")) == here)
		var open: bool = needle != "" or _open_groups[g.name]
		var count := shown.filter(func(p: Dictionary) -> bool: return not p.has("sub")).size()
		var head := Button.new()
		head.text = "%s %s  (%d)" % ["▾" if open else "▸", g.name, count]
		head.alignment = HORIZONTAL_ALIGNMENT_LEFT
		head.flat = true
		head.add_theme_font_size_override("font_size", 17)
		head.add_theme_color_override("font_color", Color("#FFD23F"))
		head.add_theme_color_override("font_hover_color", Color("#FFE680"))
		var group_name: String = g.name
		head.pressed.connect(func() -> void:
			_open_groups[group_name] = not _open_groups[group_name]
			_fill_places(list))
		list.add_child(head)
		if not open:
			continue
		for item: Dictionary in shown:
			if item.has("sub"):
				if item.sub == "":
					continue
				var label := Label.new()
				label.text = "   " + item.sub
				label.add_theme_color_override("font_color", Color("#9FD4F0"))
				label.add_theme_font_size_override("font_size", 14)
				list.add_child(label)
				continue
			var b := _place_button(("      " if g.items.any(func(p: Dictionary) -> bool: return p.has("sub")) else "   ") + item.name, item)
			if str(item.scene) == here:
				b.add_theme_color_override("font_color", Color("#9AE6A1"))
			list.add_child(b)
	var lost: Array[String] = []
	var dir := DirAccess.open("res://scenes")
	if dir:
		for file in dir.get_files():
			var id := file.get_basename()
			if file.ends_with(".tscn") and not known.has(id) and not NOT_PLACES.has(id):
				lost.append(id)
	if not lost.is_empty():
		var head := Label.new()
		head.text = "Autres lieux (à classer dans PLACES)"
		head.add_theme_color_override("font_color", Color("#FF9D6A"))
		head.add_theme_font_size_override("font_size", 15)
		list.add_child(head)
		for id in lost:
			list.add_child(_place_button(id, {"scene": id}))


# The switch that opens the whole neighbourhood: no age to cross a street, no door shut on Halloween night, no grey
# crayon on the map. Nothing is rebuilt, every gate asks on the spot, so the menu just redraws itself.
func _no_limits_button() -> Button:
	var b := Button.new()
	b.text = "▶ Sans limites : OUI" if no_limits else "Sans limites : non"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.tooltip_text = ("Traverser les rues à tout âge, entrer dans les ruelles et les dépanneurs même le soir de\n"
		+ "l'Halloween, et la carte n'est plus grisée. Pour l'essai seulement : rien n'est sauvegardé.")
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("#9AE6A1") if no_limits else Color("#CFCFD8"))
	b.pressed.connect(func() -> void:
		no_limits = not no_limits
		_close()
		_open())
	return b


# The switch that lets her cross without looking both ways first (and without saying so).
func _skip_look_button() -> Button:
	var b := Button.new()
	b.text = "▶ Traverser sans regarder : OUI" if skip_look else "Traverser sans regarder : non"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.tooltip_text = ("Charlotte traverse sans s'arrêter regarder des deux côtés, et le trottoir continue par-dessus les rues :\n"
		+ "elle marche tout droit d'un pâté à l'autre, sans cliquer. Pour l'essai seulement.")
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("#9AE6A1") if skip_look else Color("#CFCFD8"))
	b.pressed.connect(func() -> void:
		skip_look = not skip_look
		_close()
		_open())
	return b


func _place_button(text: String, place: Dictionary) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(_teleport.bind(place))
	return b


# Straight to a place: the scene reloads with Charlotte there. Leaves her hands as they are (what she carries is saved).
func _teleport(place: Dictionary) -> void:
	_close()
	Transition.street_x = NAN
	Transition.inside_x = NAN
	Transition.arrive = str(place.get("arrive", ""))
	Transition.crossing = ""
	var scene_name := str(place.scene)
	if place.has("x"):
		if scene_name in INTERIORS:
			Transition.inside_x = float(place.x)
		else:
			Transition.street_x = float(place.x)
	Transition.change_scene(get_tree().current_scene, "res://scenes/%s.tscn" % scene_name)


# One row per quest: its state, "Effacer" (back to not started, its flags cleared), "Activer" (in the notebook now,
# whatever it waits for) and "Finir" (done, with its star and reward).
func _quest_list(parent: Control) -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	parent.add_child(list)
	var title := Label.new()
	title.text = "Quêtes"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)
	for id: String in Quests.ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)
		var label := Label.new()
		var state := Quests.status(id)
		label.text = "%s  %s" % [{"": "·", "active": "▶", "done": "★"}[state], id]
		label.custom_minimum_size = Vector2(120, 0)
		label.add_theme_font_size_override("font_size", 17)
		row.add_child(label)
		for action in [["Effacer", ""], ["Activer", "active"], ["Finir", "done"]]:
			var b := Button.new()
			b.text = action[0]
			b.add_theme_font_size_override("font_size", 15)
			b.disabled = state == action[1]
			b.pressed.connect(_set_quest.bind(id, action[1]))
			row.add_child(b)
	# The homework of the week is no quest, but it starts over the same way.
	var devoirs := HBoxContainer.new()
	devoirs.add_theme_constant_override("separation", 8)
	list.add_child(devoirs)
	var left := Label.new()
	var count := Homework.exercises().size()
	left.text = "%s  devoirs %d/%d" % ["★" if Homework.all_done() else "▶", Homework.done_count(), count]
	left.custom_minimum_size = Vector2(120, 0)
	left.add_theme_font_size_override("font_size", 17)
	devoirs.add_child(left)
	for action: Array in [["Effacer", false], ["Tout finir", true]]:
		var b := Button.new()
		b.text = action[0]
		b.add_theme_font_size_override("font_size", 15)
		b.disabled = Homework.all_done() if action[1] else Homework.done_count() == 0
		b.pressed.connect(func() -> void:
			if action[1]:
				Homework.finish_all()
			else:
				Homework.reset()
			_close()
			_reload())
		devoirs.add_child(b)
	var all := Button.new()
	all.text = "Tout effacer"
	all.add_theme_font_size_override("font_size", 15)
	all.pressed.connect(func():
		for id: String in Quests.ORDER:
			_clear_quest(id)
		for flag: String in OTHER_FLAGS:
			GameState.flags.erase(flag)
		_close()
		_reload())
	list.add_child(all)


func _set_quest(id: String, state: String) -> void:
	_clear_quest(id)
	if state != "":
		GameState.quests[id] = "active"
	if state == "done":
		Quests.complete(id)
	_close()
	_reload()


func _clear_quest(id: String) -> void:
	GameState.quests.erase(id)
	for flag: String in QUEST_FLAGS.get(id, []):
		GameState.flags.erase(flag)
	if Carry.what() == QUEST_CARRIES.get(id, "-") or Carry.cat_id() == id:
		Carry.clear()


func _close() -> void:
	_panel.queue_free()
	_panel = null


func _switch(to: String) -> void:
	_close()
	if to == Season.current:
		return
	Season.current = to
	_reload()


# Reloads the scene (the world rebuilds from the season and the quests), Charlotte where she was.
func _reload() -> void:
	var scene := get_tree().current_scene
	var charlotte = scene.get("_charlotte")
	if charlotte is Character:
		if scene.scene_file_path.ends_with("main.tscn"):
			Transition.street_x = charlotte.position.x
		else:
			Transition.inside_x = charlotte.position.x
	Transition.change_scene(scene, scene.scene_file_path)
