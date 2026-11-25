extends Node
## Essais d'intégration : le vrai jeu, piloté par de vraies entrées (clavier, manette, souris, tactile).
## godot --headless --path . res://tests/integration.tscn -- --no-save

var main: Node
var failures := 0
var checks := 0
var current := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		printerr("essais trop longs (dernier : %s)" % current)
		get_tree().quit(1))
	_run.call_deferred()


func check(condition: bool, what: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("  [%s] %s" % [current, what])


func frames(n := 3) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame


func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	send(e)


func tap_key(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(2)


func pad(button: JoyButton, down: bool, device := 0) -> void:
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = button
	e.pressed = down
	send(e)


func tap_pad(button: JoyButton) -> void:
	pad(button, true)
	await frames(2)
	pad(button, false)
	await frames(2)


func stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	send(e)


## Un clic (ou un doigt) à un endroit de l'écran, envoyé au jeu comme le ferait le système.
func click(at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().push_input(e, true)


func move_mouse(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	get_viewport().push_input(e, true)


func focus_text() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	return owner.text if owner is Button else ""


func find_button(text: String) -> Button:
	for b: Button in main.menus.find_children("*", "Button", true, false):
		if b.text == text and b.is_visible_in_tree() and not b.is_queued_for_deletion():
			return b
	return null


func press(text: String) -> bool:
	var b := find_button(text)
	check(b != null, "bouton « %s » introuvable sur %s" % [text, main.menus.screen])
	if b == null:
		return false
	b.pressed.emit()
	await frames(3)
	return true


## Une partie tranquille : Maman ne se retourne pas, rien n'apparaît.
func calm(level := 1) -> Sim:
	main.seed_override = 12
	main.start_level(level)
	await frames(3)
	var sim: Sim = main.sim
	sim.mom_left = 9999.0
	sim.spawn_left = 9999.0
	sim.helper_left = 9999.0
	sim.treasure_due = -1.0
	sim.food.clear()
	return sim


func run_until(condition: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().physics_frame
	return false


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames(10)
	for m in get_method_list():
		var name_: String = m.name
		if name_.begins_with("test_"):
			current = name_
			var before := failures
			main.go_title()
			await frames(3)
			await call(name_)
			for code: Key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE]:
				key(code, false)
			print(("ok     " if failures == before else "ÉCHEC  ") + name_)
	print("%d vérifications, %d échecs" % [checks, failures])
	await main.quit_game(1 if failures > 0 else 0)


func test_menus_au_clavier() -> void:
	check(main.menus.screen == "titre", "titre")
	check(focus_text() == Texts.PLAY, "le premier bouton est choisi : « %s »" % focus_text())
	await tap_key(KEY_DOWN)
	check(focus_text() == Texts.LEVELS, "flèche bas : « %s »" % focus_text())
	await tap_key(KEY_ENTER)
	check(main.menus.screen == "missions", "Entrée ouvre les missions : " + main.menus.screen)
	await tap_key(KEY_ESCAPE)
	check(main.menus.screen == "titre", "Échap revient au titre : " + main.menus.screen)
	await tap_key(KEY_ENTER)
	check(main.menus.screen == "consignes", "Jouer montre les consignes : " + main.menus.screen)
	await tap_key(KEY_ENTER)
	check(main.state == "jeu" and main.menus.screen == "", "la partie commence : " + main.state)


func test_menus_a_la_manette() -> void:
	await tap_pad(JOY_BUTTON_DPAD_DOWN)
	check(focus_text() == Texts.LEVELS, "croix bas : « %s »" % focus_text())
	await tap_pad(JOY_BUTTON_A)
	check(main.menus.screen == "missions", "A valide : " + main.menus.screen)
	await tap_pad(JOY_BUTTON_B)
	check(main.menus.screen == "titre", "B revient : " + main.menus.screen)


func test_missions_verrouillees() -> void:
	main.save.reset_defaults()
	main.menus.show_select()
	await frames()
	var grid: Array = main.menus.find_children("*", "GridContainer", true, false)
	check(grid.size() == 1 and grid[0].get_child_count() == Levels.COUNT, "huit missions")
	var open := 0
	for b: Button in grid[0].get_children():
		open += int(not b.disabled)
	check(open == 1, "une seule ouverte au début : %d" % open)
	main.save.record(1, 9000, 3)
	main.menus.show_select()
	await frames()
	grid = main.menus.find_children("*", "GridContainer", true, false)
	open = 0
	for b: Button in grid.back().get_children():
		open += int(not b.disabled)
	check(open == 2, "la deuxième s'ouvre : %d" % open)
	main.save.reset_defaults()


func test_clavier_deplace() -> void:
	var sim := await calm()
	var start := sim.dog_pos
	var screen: Vector2 = main.stage.on_screen(Vector3(start.x, 0, start.y))
	key(KEY_LEFT, true)
	await frames(30)
	key(KEY_LEFT, false)
	var after: Vector2 = main.stage.on_screen(Vector3(sim.dog_pos.x, 0, sim.dog_pos.y))
	check(after.x < screen.x - 40.0, "flèche gauche : vers la gauche de l'écran")
	screen = after
	key(KEY_W, true)
	await frames(30)
	key(KEY_W, false)
	after = main.stage.on_screen(Vector3(sim.dog_pos.x, 0, sim.dog_pos.y))
	check(after.y < screen.y - 30.0, "W : vers le haut de l'écran")
	var still := sim.dog_pos
	await frames(10)
	check(sim.dog_pos.distance_to(still) < 0.01, "relâché : elle s'arrête")


func test_manette_deplace_et_attrape() -> void:
	var sim := await calm()
	var start := sim.dog_pos
	stick(JOY_AXIS_LEFT_X, -1.0)
	await frames(30)
	stick(JOY_AXIS_LEFT_X, 0.0)
	await frames(3)
	check(sim.dog_pos.x < start.x - 0.3, "le stick déplace Blanche")
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.SMALL, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	await frames(3)
	pad(JOY_BUTTON_A, true)
	await frames(20)
	check(sim.dog_state == Sim.Dog.REACHING, "A maintenu : elle tire")
	pad(JOY_BUTTON_A, false)
	await frames(20)
	check(sim.dog_state == Sim.Dog.FREE, "A relâché : elle redescend")
	await tap_pad(JOY_BUTTON_START)
	check(main.state == "pause", "Start met en pause")
	await tap_pad(JOY_BUTTON_B)
	check(main.state == "jeu", "B reprend")


func test_espace_attrape_et_lache() -> void:
	var sim := await calm()
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.BIG, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	await frames(3)
	key(KEY_SPACE, true)
	check(await run_until(func() -> bool: return not sim.mouth.is_empty()), "Espace maintenu : attrapé")
	key(KEY_SPACE, false)
	await frames(20)
	await tap_key(KEY_SPACE)
	check(sim.mouth.is_empty() and sim.food.size() == 1, "un nouvel appui lâche le morceau")


func test_pause_et_reprise() -> void:
	var sim := await calm()
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.TREASURE, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	await tap_key(KEY_ESCAPE)
	check(main.state == "pause" and get_tree().paused and main.menus.screen == "pause", "Échap : pause")
	var t := sim.time
	var pos := sim.dog_pos
	key(KEY_LEFT, true)
	await frames(30)
	key(KEY_LEFT, false)
	check(sim.time == t and sim.dog_pos == pos, "rien ne bouge en pause")
	key(KEY_SPACE, true)
	await frames(2)
	# Reprendre avec la touche encore enfoncée : il faut la relâcher avant de prendre.
	main.resume_game()
	await frames(20)
	check(sim.dog_state == Sim.Dog.FREE, "le bouton gardé depuis le menu n'attrape rien")
	key(KEY_SPACE, false)
	await frames(3)
	key(KEY_SPACE, true)
	await frames(10)
	check(sim.dog_state == Sim.Dog.REACHING, "un nouvel appui attrape")
	key(KEY_SPACE, false)
	await frames(20)
	await tap_key(KEY_ESCAPE)
	await tap_key(KEY_ESCAPE)
	check(main.state == "jeu" and not get_tree().paused, "Échap deux fois : retour au jeu")


func test_souris_et_gros_bouton() -> void:
	var sim := await calm()
	var goal := Vector2(-0.9, 1.3)
	var at: Vector2 = main.stage.on_screen(Vector3(goal.x, 0, goal.y))
	click(at, true)
	click(at, false)
	check(await run_until(func() -> bool: return sim.dog_pos.distance_to(goal) < 0.15), "clic au sol : elle y va (%s)" % sim.dog_pos)
	var item := sim._add_item(Sim.Size.SMALL, "est_evier", sim.map.spots.est_evier.food)
	await frames(20)
	at = main.stage.on_screen(main.stage.item_position(item))
	click(at, true)
	click(at, false)
	check(await run_until(func() -> bool: return not sim.reachable_item().is_empty()), "clic sur un morceau : elle s'approche")
	await frames(10)
	var button: Button = main.hud._grab
	var centre := button.get_global_rect().get_center()
	move_mouse(centre)
	click(centre, true)
	check(await run_until(func() -> bool: return not sim.mouth.is_empty(), 200), "bouton à l'écran maintenu : attrapé")
	click(centre, false)
	await frames(3)
	check(not main.hud.grab_held, "bouton relâché")
	centre = main.hud._pause.get_global_rect().get_center()
	move_mouse(centre)
	click(centre, true)
	click(centre, false)
	await frames(3)
	check(main.state == "pause", "bouton pause à l'écran")


func finger(at: Vector2, index: int) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = true
	e.position = at
	get_viewport().push_input(e, true)


func test_deuxieme_doigt() -> void:
	# Le bouton reste tenu après la prise, et un autre doigt montre où aller.
	var sim := await calm()
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.TREASURE, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	await frames(3)
	main.hud.grab_held = true
	check(await run_until(func() -> bool: return not sim.mouth.is_empty() and sim.dog_state == Sim.Dog.FREE), "attrapé")
	var goal := Vector2(0.45, 1.3)
	finger(main.stage.on_screen(Vector3(goal.x, 0, goal.y)), 1)
	check(await run_until(func() -> bool: return sim.dog_pos.distance_to(goal) < 0.15, 90),
		"bouton tenu : le deuxième doigt la déplace (%s)" % sim.dog_pos)
	main.hud.grab_held = false


func test_but_hors_d_atteinte() -> void:
	var sim := await calm(4)
	for aim: Vector3 in [Vector3(sim.map.stool_pos.x, 0.6, sim.map.stool_pos.y), Vector3(1.8, 0.9, -0.6),
			Vector3(0.0, 0.9, -0.1)]:
		main.tap(main.stage.on_screen(aim))
		check(await run_until(func() -> bool: return main._touch_goal == Vector2.INF, 480), "le but est abandonné : %s" % aim)
		var still := sim.dog_pos
		await frames(20)
		check(sim.dog_pos.distance_to(still) < 0.01, "elle ne pousse plus contre le meuble")


func test_au_coin_oublie_le_but() -> void:
	var sim := await calm()
	sim.dog_pos = Vector2(-1.0, 1.4)
	sim.mouth = {"id": 99, "size": 3, "points": 500, "eat_left": 3.0, "spot": "", "pos": Vector2.ZERO}
	main.tap(main.stage.on_screen(Vector3(1.0, 0, 0.9)))
	sim.mom_state = Sim.Mom.LOOK
	sim._set_timer(0.5)
	check(await run_until(func() -> bool: return sim.caught_count == 1, 60), "prise en chemin")
	check(await run_until(func() -> bool: return sim.dog_state == Sim.Dog.FREE, 900), "puis libérée")
	await frames(40)
	check(sim.dog_pos.distance_to(sim.map.corner) < 0.1, "elle reste au coin tant qu'on ne dit rien (%s)" % sim.dog_pos)


func test_manette_numero_deux() -> void:
	var sim := await calm()
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.BIG, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	await frames(3)
	pad(JOY_BUTTON_A, true, 1)
	await frames(15)
	check(sim.dog_state == Sim.Dog.REACHING, "n'importe quelle manette attrape")
	pad(JOY_BUTTON_A, false, 1)
	await frames(20)


func test_start_et_p_reprennent() -> void:
	await calm()
	await tap_pad(JOY_BUTTON_START)
	check(main.state == "pause", "Start : pause")
	await tap_pad(JOY_BUTTON_START)
	check(main.state == "jeu" and not get_tree().paused, "Start : reprise")
	await tap_key(KEY_P)
	await tap_key(KEY_P)
	check(main.state == "jeu", "P : pause puis reprise")


func test_resultat_note_tout_de_suite() -> void:
	main.save.reset_defaults()
	var sim := await calm()
	sim.score = int(sim.level.stars[2])
	sim.time_left = 0.02
	await frames(6)
	check(sim.over and main.save.stars_of(1) == 3 and main.save.unlocked == 2, "noté avant l'écran des résultats")
	await tap_key(KEY_ESCAPE)
	check(main.state == "jeu" and not get_tree().paused, "pas de pause une fois le repas prêt")
	check(await run_until(func() -> bool: return main.menus.screen == "resultats", 400), "les résultats arrivent")
	main.save.reset_defaults()


func test_perte_du_focus() -> void:
	await calm()
	main.testing = false
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.testing = true
	await frames()
	check(main.state == "pause", "pause quand on change de fenêtre")


func test_recommencer_pendant_la_punition() -> void:
	var sim := await calm()
	sim.dog_pos = sim.map.spots.lave_vaisselle.stand
	sim._add_item(Sim.Size.BIG, "lave_vaisselle", sim.map.spots.lave_vaisselle.food)
	sim.mom_state = Sim.Mom.LOOK
	sim._set_timer(99.0)
	await frames(3)
	key(KEY_SPACE, true)
	check(await run_until(func() -> bool: return sim.caught_count == 1), "prise en flagrant délit")
	key(KEY_SPACE, false)
	await frames(10)
	check(Sound.history.has("au_coin"), "le cri se fait entendre")
	await tap_key(KEY_ESCAPE)
	await press(Texts.RETRY)
	check(main.state == "jeu" and main.sim != sim and main.sim.caught_count == 0 and main.sim.score == 0, "partie neuve")
	check(main.sim.dog_pos.distance_to(main.sim.map.corner) < 0.05, "de retour au coin")


func test_resultats_et_suite() -> void:
	main.save.reset_defaults()
	var sim := await calm()
	sim.score = int(sim.level.stars[1])
	sim.time_left = 0.05
	check(await run_until(func() -> bool: return main.menus.screen == "resultats", 900), "résultats")
	check(main.save.stars_of(1) == 2 and main.save.unlocked == 2, "étoiles et déblocage notés")
	await press(Texts.NEXT)
	check(main.menus.screen == "consignes" and main.level_id == 2, "mission suivante : %d" % main.level_id)
	await press(Texts.START)
	check(main.state == "jeu" and main.sim.level.id == 2, "mission 2 lancée")
	main.sim.time_left = 0.05
	main.sim.score = 0
	check(await run_until(func() -> bool: return main.menus.screen == "resultats", 900), "résultats ratés")
	check(find_button(Texts.NEXT) == null and focus_text() == Texts.RETRY, "raté : pas de suite, « Recommencer » choisi")
	await press(Texts.MENU)
	check(main.menus.screen == "titre" and main.sim == null, "retour au titre")
	check(find_button(Texts.CONTINUE) != null, "le titre propose de continuer")
	main.save.reset_defaults()


func test_options() -> void:
	main.menus.show_options(main.menus.show_title)
	await frames()
	var sliders: Array = main.menus.find_children("*", "HSlider", true, false)
	check(sliders.size() == 2, "deux curseurs")
	sliders[0].value = 0.0
	sliders[1].value = 0.4
	await frames()
	check(is_equal_approx(main.save.options.music, 0.0) and is_equal_approx(main.save.options.sfx, 0.4), "volumes notés")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "musique coupée à zéro")
	for key_: String in ["reduced_motion", "long_hints", "fullscreen"]:
		var b: Button = main.menus.find_child(key_, true, false)
		check(b != null and b.text == Texts.OFF, key_ + " à Non")
		b.pressed.emit()
		await frames()
		check(main.save.options[key_] and b.text == Texts.ON, key_ + " à Oui")
	check(main.stage.reduced_motion and main.hud.reduced_motion, "mouvements réduits appliqués")
	await calm()
	check(is_equal_approx(main.sim.hint_bonus, 0.25), "indices plus longs appliqués")
	main.go_title()
	await frames()
	main.save.record(1, 100, 1)
	main.menus.show_options(main.menus.show_title)
	await press(Texts.ERASE)
	await press(Texts.NO)
	check(main.save.total_stars() == 1, "« Non » ne touche à rien")
	await press(Texts.ERASE)
	await press(Texts.YES)
	check(main.save.total_stars() == 0 and main.save.options.long_hints, "progression effacée, options gardées")
	main.save.reset_defaults()
	main.apply_options()


func test_fin_du_jeu() -> void:
	var sim := await calm(Levels.COUNT)
	sim.score = int(sim.level.stars[0])
	sim.time_left = 0.05
	check(await run_until(func() -> bool: return main.menus.screen == "resultats", 900), "résultats de la dernière mission")
	await press(Texts.CONTINUE)
	check(main.menus.screen == "fin", "écran de fin : " + main.menus.screen)
	await press(Texts.MENU)
	check(main.menus.screen == "titre", "retour au titre")
	main.save.reset_defaults()


func test_marteler_ne_saute_pas_les_resultats() -> void:
	main.save.reset_defaults()
	var sim := await calm()
	sim.score = int(sim.level.stars[0])
	sim.time_left = 0.02
	check(await run_until(func() -> bool: return main.menus.screen == "resultats", 400), "résultats")
	for i in 4:
		await tap_key(KEY_SPACE)
		await tap_key(KEY_ENTER)
	check(main.menus.screen == "resultats", "toujours aux résultats : " + main.menus.screen)
	await get_tree().create_timer(1.3, true, false, true).timeout
	await tap_key(KEY_ENTER)
	check(main.menus.screen == "consignes", "puis la validation marche : " + main.menus.screen)
	main.save.reset_defaults()


func test_appui_tres_bref() -> void:
	var sim := await calm()
	sim.dog_pos = Vector2(-1.0, 1.4)
	for source: String in ["clavier", "bouton"]:
		sim.mouth = {"id": 99, "size": 3, "points": 500, "eat_left": 30.0, "spot": "", "pos": Vector2.ZERO}
		sim.food.clear()
		await frames(5)
		if source == "clavier":
			key(KEY_SPACE, true)
			key(KEY_SPACE, false)
		else:
			main.hud._grab.button_down.emit()
			main.hud._grab.button_up.emit()
		await frames(5)
		check(sim.mouth.is_empty(), "appui éclair (%s) : le morceau est lâché" % source)
		check(main.hud.input_kind == "clavier", "le bouton nomme la touche")
	await tap_pad(JOY_BUTTON_DPAD_LEFT)
	check(main.hud.input_kind == "manette", "puis le bouton de la manette")


func test_revoir_la_fin() -> void:
	main.save.finished_seen = true
	main.menus.show_credits()
	await press(Texts.SEE_END)
	check(main.menus.screen == "fin", "la fin se revoit")
	main.save.reset_defaults()


func test_vingt_parties_de_suite() -> void:
	var before := 0
	var nodes := 0
	for i in 22:
		main.start_level(1 + i % Levels.COUNT)
		main.bot = Bot.new(main.sim, "equilibre", 0.35, 0.9, i)
		main.speed = 20
		await frames(40)
		main.speed = 1
		main.go_title()
		await frames(4)
		if i == 2:
			before = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(after - before < 150, "objets : %d → %d" % [before, after])
	check(nodes_after - nodes < 20, "nœuds : %d → %d" % [nodes, nodes_after])
