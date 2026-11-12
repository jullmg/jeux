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
## The story flags each quest leaves behind, cleared with it.
## Story flags that belong to no quest, cleared by "Tout effacer".
const OTHER_FLAGS := ["met_twins", "met_billie_auguste", "devoirs", "candy_bag_kind"]
const QUEST_FLAGS := {"amies": ["met_twins", "met_billie_auguste"], "cachette": ["cachette_found"], "livre": ["book_found", "croque_checked"], "halloween": ["halloween_step", "candy", "candy_bag", "candy_bag_kind", "halloween_doors", "halloween_counted", "halloween_total", "winter_greeting"], "hamster": ["hamster_fed"], "menage": ["tidied"], "plants": ["watered"]}
## What a quest puts in her arms (a lost cat's quest id is the cat's id, handled by `Carry.cat_id()`).
const QUEST_CARRIES := {"milk": "milk", "plants": "can", "menage": "toy", "livre": "book"}

## The places to teleport to, in the order of the menu: {name, scene, and where: `x` (Charlotte's x in the scene), or `arrive`
## (the Transition.arrive key of a corner or lane opening), or nothing for the scene's usual start}. A line with only a
## "group" is a heading. Add a line here for each new place (a new street, room, shop, lane, a spot inside a building).
const PLACES := [
	{"group": "Rues"},
	{"name": "6e Avenue : chez Charlotte", "scene": "main"},
	{"name": "6e Avenue : coin Dandurand", "scene": "main", "arrive": "6e_from_dandurand"},
	{"name": "6e Avenue : coin Holt", "scene": "main", "arrive": "6e_from_holt"},
	{"name": "6e Avenue, l'autre côté : milieu", "scene": "sixieme_est"},
	{"name": "6e Avenue, l'autre côté : coin Holt", "scene": "sixieme_est", "arrive": "6e_est_from_6e_holt"},
	{"name": "6e Avenue, l'autre côté : coin Dandurand", "scene": "sixieme_est", "arrive": "6e_est_from_6e_dandurand"},
	{"name": "Rue Dandurand : dépanneur Xin-Xin", "scene": "dandurand"},
	{"name": "Rue Dandurand : coin 6e", "scene": "dandurand", "arrive": "dandurand_from_6e"},
	{"name": "Rue Dandurand : coin 5e", "scene": "dandurand", "arrive": "dandurand_from_5e"},
	{"name": "5e Avenue : milieu", "scene": "cinquieme"},
	{"name": "5e Avenue : coin Holt", "scene": "cinquieme", "arrive": "5e_from_holt"},
	{"name": "5e Avenue : coin Dandurand", "scene": "cinquieme", "arrive": "5e_from_dandurand"},
	{"name": "Rue Holt : dépanneur Oh Bon!", "scene": "holt"},
	{"name": "Rue Holt : coin 6e", "scene": "holt", "arrive": "holt_from_6e"},
	{"name": "Rue Holt : coin 5e", "scene": "holt", "arrive": "holt_from_5e"},
	{"name": "Rue Masson 1re–2e, côté nord : milieu", "scene": "masson_1re_2e_impair"},
	{"name": "Rue Masson 1re–2e, côté sud : milieu", "scene": "masson_1re_2e_pair"},
	{"name": "Rue Masson 2e–3e, côté nord : milieu", "scene": "masson_2e_3e_impair"},
	{"name": "Rue Masson 2e–3e, côté sud : milieu", "scene": "masson_2e_3e_pair"},
	{"name": "Rue Masson 3e–4e, côté nord : milieu", "scene": "masson_3e_4e_impair"},
	{"name": "Rue Masson 3e–4e, côté sud : milieu", "scene": "masson_3e_4e_pair"},
	{"name": "Rue Masson 4e–5e, côté nord : milieu", "scene": "masson_4e_5e_impair"},
	{"name": "Rue Masson 4e–5e, côté sud : milieu", "scene": "masson_4e_5e_pair"},
	{"name": "Rue Masson 5e–6e, côté nord : l'église", "scene": "masson_5e_6e_impair"},
	{"name": "Rue Masson 5e–6e, côté sud : milieu", "scene": "masson_5e_6e_pair"},
	{"name": "Rue Masson 6e–7e, côté nord : milieu", "scene": "masson_6e_7e_impair"},
	{"name": "Rue Masson 6e–7e, côté nord : coin 6e", "scene": "masson_6e_7e_impair", "arrive": "masson_6e_7e_impair_from_rue_6e"},
	{"name": "Rue Masson 6e–7e, côté sud : milieu", "scene": "masson_6e_7e_pair"},
	{"name": "Rue Masson 6e–7e, côté sud : coin 7e", "scene": "masson_6e_7e_pair", "arrive": "masson_6e_7e_pair_from_rue_7e"},
	{"name": "Rue Masson 7e–8e, côté nord : milieu", "scene": "masson_7e_8e_impair"},
	{"name": "Rue Masson 7e–8e, côté sud : milieu", "scene": "masson_7e_8e_pair"},
	{"name": "Rue Masson 8e–9e, côté nord : milieu", "scene": "masson_8e_9e_impair"},
	{"name": "Rue Masson 8e–9e, côté sud : milieu", "scene": "masson_8e_9e_pair"},
	{"group": "Ruelles"},
	{"name": "Ruelle du milieu (cour de Charlotte)", "scene": "ruelle"},
	{"name": "Ruelle du milieu (les jumelles y sont si la quête « amies » est lancée)", "scene": "ruelle", "x": 2400.0},
	{"name": "Ruelle verte (parallèle à Dandurand)", "scene": "ruelle_dandurand"},
	{"name": "Ruelle près de Holt", "scene": "ruelle_holt"},
	{"group": "Chez Charlotte"},
	{"name": "Vestibule", "scene": "house", "x": 300.0},
	{"name": "Salon", "scene": "house", "x": 1500.0},
	{"name": "Corridor (télé)", "scene": "house", "x": 2900.0},
	{"name": "Cuisine (Maman, arrosoir)", "scene": "house", "x": 3700.0},
	{"name": "Chambre de Charlotte", "scene": "house", "x": 5700.0},
	{"group": "Dépanneur Xin-Xin"},
	{"name": "Entrée", "scene": "depanneur"},
	{"name": "Comptoir", "scene": "depanneur", "x": 1000.0},
	{"name": "Bonbons et chips", "scene": "depanneur", "x": 1750.0},
	{"name": "Sloche et café", "scene": "depanneur", "x": 2450.0},
	{"name": "Frigos et lait", "scene": "depanneur", "x": 3100.0},
	{"group": "Dépanneur Oh Bon!"},
	{"name": "Entrée", "scene": "ohbon"},
	{"name": "Comptoir et télé", "scene": "ohbon", "x": 1100.0},
	{"name": "Bonbons et chips", "scene": "ohbon", "x": 1900.0},
	{"name": "Frigos et lait", "scene": "ohbon", "x": 2800.0},
	{"group": "Autres"},
	{"name": "Écran titre", "scene": "intro"},
]
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


# A scrolling list of buttons, one per place (see PLACES), then any scene nobody listed.
func _places_list(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var title := Label.new()
	title.text = "Aller à…"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)
	list.add_child(_no_limits_button())
	var known := {}
	for place: Dictionary in PLACES:
		if place.has("group"):
			var head := Label.new()
			head.text = place.group
			head.add_theme_color_override("font_color", Color("#9FD4F0"))
			head.add_theme_font_size_override("font_size", 15)
			list.add_child(head)
			continue
		known[place.scene] = true
		list.add_child(_place_button(place.name, place))
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
		if scene_name in ["house", "depanneur", "ohbon"]:
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
