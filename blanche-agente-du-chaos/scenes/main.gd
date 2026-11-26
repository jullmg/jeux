extends Node
## Le chef d'orchestre : menus, partie, commandes, sons et sauvegarde.
##
## Arguments d'essai (après « -- ») : --no-save, --niveau=N, --demo (un robot joue), --graine=N,
## --autotest=fichier.json (parcourt le jeu tout seul et écrit le résultat), --scenario=dossier (captures d'écran),
## --verif (démarre puis quitte), --sauvegarde=user://fichier.json (essais de la sauvegarde).

const STEP := 1.0 / 60.0
const LONG_HINT_BONUS := 0.25
## Le nom des répliques et des poses selon la sorte d'indice.
const HINT_KEYS := {"real": "hint", "feint": "feint", "round": "round"}
const AMBIENT := {"couper": ["couteau", 0.34], "brasser": ["brasse", 1.1], "laver": ["eau", 1.15], "ilot": ["pas", 0.42],
	"surprise": ["brasse", 0.55]}

var save: SaveData
var stage: Stage
var hud: Hud
var menus: Menus
var sim: Sim
var bot: Bot
## "menu", "jeu", "pause", "fin"
var state := "menu"
var level_id := 1
## Vrai pendant les essais : pas de pause à la perte du focus, pas de plein écran.
var testing := false
var demo := false
var seed_override := -1
## Nombre de pas de règles par image (accéléré pour les essais).
var speed := 1

var _follower: Follower
var _touch_goal := Vector2.INF
## Temps passé à viser un point sans avancer, et dernière position : on abandonne un but hors d'atteinte.
var _touch_stuck := 0.0
var _touch_last := Vector2.ZERO
var _grab_prev := false
## Un appui clavier ou manette, gardé jusqu'au prochain pas des règles.
var _grab_tapped := false
var _fullscreen_applied := false
## Le résultat de la partie finie, déjà noté, en attente de l'écran.
var _result: Dictionary = {}
var _nav: Nav
var _mom_nav: Nav
## Les grilles de déplacement de chaque pièce, faites une fois : pièce → [Nav, Nav].
var _grids: Dictionary = {}
var _ambient_left := 0.0
var _chew_left := 0.0
var _step_left := 0.0
var _end_left := 0.0
var _need_release := false
var _rng := RandomNumberGenerator.new()
var _ticking_said := false
## La chicane en cours : ses répliques et la dernière qui a été dite.
var _argument: Array = []
var _argument_line := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	var args := {}
	for a in OS.get_cmdline_user_args():
		args[a.get_slice("=", 0)] = a.get_slice("=", 1) if a.contains("=") else ""
	testing = args.has("--no-save") or args.has("--autotest") or args.has("--scenario")
	demo = args.has("--demo")
	if args.has("--graine"):
		seed_override = int(args["--graine"])
	_setup_input()
	# Les essais et la démo ne gardent rien, sauf dans le fichier qu'on leur désigne.
	save = SaveData.new(args.get("--sauvegarde", "" if testing or demo else "user://save.json"))
	_rng.randomize()
	stage = Stage.new()
	stage.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(stage)
	_use_piece("cuisine")
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	hud_layer.add_child(hud)
	hud.pause_pressed.connect(pause_game)
	hud.grab_pressed.connect(func() -> void: _grab_tapped = true)
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 20
	add_child(menu_layer)
	menus = Menus.new()
	menus.save = save
	menu_layer.add_child(menus)
	menus.brief.connect(show_brief)
	menus.play.connect(start_level)
	menus.resume.connect(resume_game)
	menus.restart.connect(func() -> void: start_level(level_id))
	menus.to_title.connect(go_title)
	menus.quit_asked.connect(quit_game)
	menus.options_changed.connect(apply_options)
	apply_options()
	if args.has("--autotest"):
		add_child(load("res://scenes/autotest.gd").new(self, args["--autotest"]))
	if args.has("--scenario"):
		add_child(load("res://scenes/scenario.gd").new(self, args["--scenario"]))
	if args.has("--niveau"):
		start_level(clampi(int(args["--niveau"]), 1, Levels.COUNT))
	else:
		go_title()
	if args.has("--verif"):
		# Démarre, tourne quelques images et ressort proprement.
		get_tree().create_timer(0.4, true, false, true).timeout.connect(quit_game)


static func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_LEFT, KEY_A], "move_right": [KEY_RIGHT, KEY_D], "move_up": [KEY_UP, KEY_W],
		"move_down": [KEY_DOWN, KEY_S], "grab": [KEY_SPACE, KEY_ENTER], "pause": [KEY_ESCAPE, KEY_P],
	}
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	var buttons := {"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT, "move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN, "grab": JOY_BUTTON_A, "pause": JOY_BUTTON_START}
	for action: String in keys:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.25)
		for k: Key in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		if buttons.has(action):
			var b := InputEventJoypadButton.new()
			b.device = -1
			b.button_index = buttons[action]
			InputMap.action_add_event(action, b)
		if axes.has(action):
			var m := InputEventJoypadMotion.new()
			m.device = -1
			m.axis = axes[action][0]
			m.axis_value = axes[action][1]
			InputMap.action_add_event(action, m)
	# La manette doit aussi parcourir les menus.
	for pair: Array in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var b := InputEventJoypadButton.new()
		b.device = -1
		b.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], b):
			InputMap.action_add_event(pair[0], b)


func apply_options() -> void:
	var o := save.options
	Sound.set_volumes(o.music, o.sfx)
	stage.reduced_motion = o.reduced_motion
	hud.reduced_motion = o.reduced_motion
	_apply_hints()
	if not testing and DisplayServer.get_name() != "headless":
		# Seulement quand le réglage change : bouger un volume ne doit pas défaire un plein écran choisi autrement.
		var full: bool = o.fullscreen
		if full != _fullscreen_applied:
			_fullscreen_applied = full
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)


## Le réglage « indices plus longs ».
func _apply_hints() -> void:
	if sim:
		sim.hint_bonus = LONG_HINT_BONUS if save.options.long_hints else 0.0


# ------------------------------------------------------------------ écrans

func go_title() -> void:
	get_tree().paused = false
	state = "menu"
	sim = null
	bot = null
	hud.clear()
	stage.show_title()
	Sound.music("menu")
	menus.show_title()


func show_brief(id: int) -> void:
	get_tree().paused = false
	if sim != null:
		sim = null
		hud.clear()
		stage.show_title()
	state = "menu"
	level_id = id
	Sound.music("menu")
	menus.show_brief(id)


## Les grilles de déplacement d'une pièce (préparées une fois) et celui qui suit les doigts.
func _use_piece(piece: String) -> void:
	if not _grids.has(piece):
		var m := stage.map_for(piece)
		_grids[piece] = [Sim.dog_grid(m), Sim.mom_grid(m)]
	_nav = _grids[piece][0]
	_mom_nav = _grids[piece][1]
	_follower = Follower.new(_nav)


func start_level(id: int) -> void:
	get_tree().paused = false
	level_id = id
	var level := Levels.load_level(id)
	var piece := Levels.piece_of(level)
	_use_piece(piece)
	var seed_ := seed_override if seed_override >= 0 else _rng.randi()
	sim = Sim.new(stage.map_for(piece), level, seed_, _nav, _mom_nav)
	_apply_hints()
	bot = Bot.new(sim, "equilibre", 0.35, 0.95, 3) if demo else null
	_follower.clear()
	_touch_goal = Vector2.INF
	_ambient_left = 0.5
	_end_left = 0.0
	_result = {}
	_grab_prev = false
	_grab_tapped = false
	_need_release = true
	_ticking_said = false
	menus.close()
	stage.start_level(sim)
	hud.start(sim, stage)
	state = "jeu"
	Sound.music("jeu")
	_say_later(Texts.pick(_lines("intro"), _rng))
	_handle_events()


func _say_later(text: String) -> void:
	var game := sim
	get_tree().create_timer(0.7, false).timeout.connect(func() -> void:
		if sim == game and sim != null:
			hud.bubble(stage.mom, text, 2.0))


func pause_game() -> void:
	# Le repas servi, la partie est jouée : plus de pause qui ferait perdre le résultat de vue.
	if state != "jeu" or sim == null or sim.over:
		return
	state = "pause"
	get_tree().paused = true
	menus.show_pause()


func resume_game() -> void:
	if state != "pause":
		return
	menus.close()
	get_tree().paused = false
	state = "jeu"
	_need_release = true
	_grab_tapped = false
	hud.grab_held = false


func quit_game(code := 0) -> void:
	if state == "adieu":
		return
	state = "adieu"
	save.save_file()
	Sound.close()
	stage.ambiance.release()
	# Le serveur audio met quelques images à lâcher les sons.
	await get_tree().create_timer(0.4, true, false, true).timeout
	for i in 12:
		await get_tree().process_frame
	get_tree().quit(code)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not testing and not demo and menus != null:
		pause_game()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST and save != null:
		quit_game()


# ------------------------------------------------------------------ commandes

## Retient ce qui sert à jouer, pour que le bouton à l'écran nomme la bonne touche.
func _input(event: InputEvent) -> void:
	if hud == null:
		return
	if event is InputEventKey:
		hud.input_kind = "clavier"
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		hud.input_kind = "manette"
	elif event is InputEventScreenTouch or event is InputEventMouseButton:
		hud.input_kind = "pointeur"


func _unhandled_input(event: InputEvent) -> void:
	if state == "pause" and menus.screen == "pause" and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resume_game()
	elif state == "jeu":
		if event.is_action_pressed("grab"):
			_grab_tapped = true
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			pause_game()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tap(event.position)
		elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			tap(event.position)
		elif event is InputEventScreenTouch and event.pressed and event.index > 0:
			# Un deuxième doigt, pendant que le premier tient le bouton.
			tap(event.position)


## Toucher le plancher (ou un morceau) : Blanche y va.
func tap(screen: Vector2) -> void:
	if sim == null:
		return
	var best := Vector2.INF
	var ground := stage.floor_point(screen)
	# Dans la cachette, c'est le plancher qu'on vise : seul un morceau touché de près l'emporte.
	var hiding := ground != Vector2.INF and sim.hidden_at(ground)
	var best_d := 32.0 if hiding else 62.0
	for item in sim.food:
		var d := stage.on_screen(stage.item_position(item)).distance_to(screen)
		if d < best_d:
			best_d = d
			best = sim.stand_of(item)
	if best == Vector2.INF:
		best = ground
	if best == Vector2.INF:
		return
	if not stage.map.is_free(best, Sim.DOG_RADIUS):
		# Un meuble ou un mur : on vise la place libre la plus proche.
		best = _nav.center(_nav.nearest_open(best))
	_touch_goal = best
	_touch_stuck = 0.0


func _forget_goal() -> void:
	_touch_goal = Vector2.INF
	_follower.clear()


func _commands(delta: float) -> Array:
	if bot != null:
		bot.step(delta)
		return [bot.move, bot.grab]
	var keys := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	var move := Vector2.ZERO
	var grab := Input.is_action_pressed("grab") or hud.grab_held or _grab_tapped
	_grab_tapped = false
	# Un nouvel appui arrête la marche ; un but touché pendant que le bouton reste tenu, lui, compte.
	if grab and not _grab_prev:
		_forget_goal()
	_grab_prev = grab
	if keys.length() > 0.1:
		move = stage.floor_direction(keys)
		_forget_goal()
	elif _touch_goal != Vector2.INF and sim.dog_state == Sim.Dog.FREE:
		move = _follower.steer(delta, sim.dog_pos, _touch_goal, [[sim.mom_pos, Sim.MOM_RADIUS]])
		_touch_stuck = _touch_stuck + delta if sim.dog_pos.distance_to(_touch_last) < 0.008 else 0.0
		_touch_last = sim.dog_pos
		if move == Vector2.ZERO or sim.dog_pos.distance_to(_touch_goal) < 0.1 or _touch_stuck > 0.4:
			_forget_goal()
	if _need_release:
		if not grab:
			_need_release = false
		grab = false
	return [move, grab]


# ------------------------------------------------------------------ la partie

func _physics_process(delta: float) -> void:
	# Elle fredonne tant qu'elle est occupée : le silence est un indice de plus. Déduit de l'état, rien à éteindre ailleurs.
	Sound.hum(state == "jeu" and sim != null and not sim.over and sim.mom_state == Sim.Mom.BUSY \
		and sim.activity != "telephone" and not sim.mom_out)
	if state != "jeu" or sim == null:
		return
	for i in speed:
		if sim.over:
			break
		var c := _commands(STEP)
		sim.step(STEP, c[0], c[1])
		stage.tick()
		_handle_events()
	_sounds(delta * speed)
	_argue()
	if sim.over:
		if _result.is_empty():
			_record()
			_end_left = 2.4
		_end_left -= delta * speed
		if _end_left <= 0.0:
			_finish()


## Le résultat est noté dès que le repas est prêt : fermer le jeu juste après ne le perd pas.
func _record() -> void:
	var stars := sim.stars()
	var new_best := save.record(level_id, sim.score, stars)
	_result = {"level": level_id, "score": sim.score, "stars": stars, "eaten": sim.eaten, "caught": sim.caught_count,
		"new_best": new_best and sim.score > 0, "target": int(sim.level.stars[0])}


func _finish() -> void:
	state = "fin"
	Sound.music("")
	Sound.play("victoire" if _result.stars > 0 else "rate")
	hud.visible = false
	menus.show_results(_result)


func _handle_events() -> void:
	for e: Dictionary in sim.drain_events():
		if e.type == "caught":
			_forget_goal()
		stage.on_event(e)
		hud.on_event(e)
		_event_sound(e)
		_event_words(e)


func _event_sound(e: Dictionary) -> void:
	match e.type:
		"hint":
			if e.kind == "feint":
				Sound.play("feinte")
			elif e.kind == "retour":
				# Ses pas qui approchent dans le corridor.
				Sound.play("indice")
				for i in 3:
					get_tree().create_timer(0.12 + i * 0.16, false).timeout.connect(Sound.play.bind("pas", -4.0, 0.8))
			else:
				Sound.play("indice")
				Sound.play("tour" if e.kind == "round" else "alerte", -3.0)
		"turn":
			Sound.play("demi_tour")
		"reach":
			Sound.play("hop")
		"released":
			Sound.play("redescend")
		"grabbed":
			Sound.play("miette" if e.item.size == Sim.Size.CRUMB else "prise")
		"ate":
			if e.item.size > Sim.Size.CRUMB:
				Sound.play("combo" if e.mult > 1 else "avale")
		"dropped":
			Sound.play("lache")
		"caught":
			Sound.play("au_coin", 2.0)
		"noise":
			Sound.play("tombe" if e.what == "tabouret" else "fracas")
		"surprise":
			Sound.play("minuterie")
		"treasure":
			Sound.play("tresor")
		"distract", "snitch_call":
			Sound.play("maman_appel")
		"snitch":
			Sound.play("hon")
		"helper_in", "out", "back_in":
			Sound.play("porte")
		"served":
			Sound.play("prise", -4.0, 0.8)
		"busted":
			Sound.play("maman_appel")
		"papa_drop":
			Sound.play("tombe", -4.0)
		"freed":
			Sound.play("libre")
			if _rng.randf() < 0.4:
				Sound.play("jappe", -6.0)
		"meal_ready":
			Sound.play("repas")
		"busy":
			if e.activity == "frigo":
				Sound.play("frigo")


## Les répliques de la personne qui surveille : Papa au hockey, Maman qui chuchote pendant le film, ou Maman.
func _lines(key: String) -> Array:
	var cage := sim != null and sim.map.corner_kind == "cage"
	if cage and key in ["caught", "scold_after"]:
		return Texts.MOM["caught_cage" if key == "caught" else "scold_cage"]
	var own: Dictionary = Texts.MOM
	if sim != null and sim.watcher == "papa":
		own = Texts.PAPA_WATCH
	elif sim != null and sim.level.get("moment", "") == "film":
		own = Texts.MOM_FILM
	return own[key] if own.has(key) else Texts.MOM[key]


## Les répliques de quelqu'un d'autre que la personne qui surveille.
func _other_lines(who: String, key: String) -> Array:
	if Texts.GUESTS.has(who):
		return Texts.GUESTS[who].get(key, [])
	if who == "charlotte":
		return Texts.CHARLOTTE.get(key, [])
	return []


func _event_words(e: Dictionary) -> void:
	var say := func(who: PersonView, lines: Array, seconds := 1.8) -> void:
		if who != null and not lines.is_empty():
			hud.bubble(who, Texts.pick(lines, _rng), seconds)
	match e.type:
		"hint":
			if e.kind == "retour":
				return
			var chance := 1.0 if e.kind == "round" else 0.7
			var key: String = HINT_KEYS[e.kind]
			if sim.watcher == "papa" and e.kind == "real" and stage.hint_flavor == 1:
				# Il cherche la télécommande : il le dit, toujours.
				key = "remote"
				chance = 1.0
			if _rng.randf() < chance:
				say.call(stage.mom, _lines(key), 1.2)
		"caught":
			say.call(stage.mom, _lines("caught"), 2.0)
		"corner_arrive":
			say.call(stage.mom, _lines("scold_after"), 2.0)
		"surprise":
			say.call(stage.mom, _lines("surprise"))
		"noise":
			say.call(stage.mom, _lines("noise"), 1.2)
		"distract":
			say.call(stage.mom, Texts.MOM.distract, 2.2)
		"walk":
			if sim.map.stations[e.station].outside:
				say.call(stage.mom, Texts.MOM.out, 1.6)
		"back_in":
			say.call(stage.mom, Texts.MOM.retour, 1.4)
		"served":
			say.call(stage.mom, Texts.MOM.served, 1.6)
		"busted":
			say.call(stage.mom, Texts.MOM.busted, 1.6)
		"slip_start":
			if _rng.randf() < 0.4:
				say.call(stage.people.get(e.who), _other_lines(e.who, "slip"), 1.2)
		"chat":
			# La visite jase : une bulle de temps en temps seulement, et jamais par-dessus une autre.
			if _rng.randf() < 0.3 and not hud.has_bubbles():
				say.call(stage.people.get(e.who), _other_lines(e.who, "chat"), 1.6)
		"argue":
			var pool: Array = Texts.CHICANE_CHARLOTTE if e.get("with", "papa") == "charlotte" else Texts.CHICANE
			_argument = pool[_rng.randi_range(0, pool.size() - 1)]
			_argument_line = -1
		"helper_in":
			if stage.people.has(e.who):
				var who: PersonView = stage.people[e.who]
				var lines: Array = Texts.CHARLOTTE["in"] if e.who == "charlotte" else Texts.PAPA["in"]
				var tween := who.create_tween()
				tween.tween_interval(0.5)
				tween.tween_callback(_greet.bind(who, lines))
		"snitch":
			var who: String = e.get("who", "charlotte")
			say.call(stage.people.get(who), _other_lines(who, "snitch"), 0.9)
		"snitch_call":
			var who: String = e.get("who", "charlotte")
			say.call(stage.people.get(who), _other_lines(who, "call"), 1.6)
		"papa_drop":
			if stage.people.has("papa"):
				say.call(stage.people.papa, Texts.PAPA.drop, 1.4)


func _greet(who: PersonView, lines: Array) -> void:
	if sim != null and who.visible:
		hud.bubble(who, Texts.pick(lines, _rng), 2.0)


## La chicane se dit une réplique à la fois, Maman puis l'autre (Papa ou Charlotte), au fil du temps qu'elle dure.
func _argue() -> void:
	if sim.mom_state != Sim.Mom.BUSY or sim.activity != "chicane" or not stage.people.has(sim.chicane_with):
		return
	var step := Sim.ARGUE_TIME / _argument.size()
	var line := mini(int((Sim.ARGUE_TIME - sim.mom_left) / step), _argument.size() - 1)
	if line == _argument_line:
		return
	_argument_line = line
	var moms := line % 2 == 0
	var other: PersonView = stage.people[sim.chicane_with]
	var speaker: PersonView = stage.mom if moms else other
	# Une seule bulle à la fois : on lit la chicane comme un ping-pong.
	hud.hush(other if moms else stage.mom)
	hud.bubble(speaker, _argument[line], step)
	Sound.play("chicane_maman" if moms else "chicane_papa", -2.0)


## Les bruits qui accompagnent ce qui dure : la cuisine, les pas, la mastication, la musique.
func _sounds(delta: float) -> void:
	_ambient_left -= delta
	if sim.mom_state == Sim.Mom.BUSY and AMBIENT.has(sim.activity) and _ambient_left <= 0.0:
		var a: Array = AMBIENT[sim.activity]
		_ambient_left = a[1] * _rng.randf_range(0.9, 1.15)
		Sound.play(a[0], -9.0, _rng.randf_range(0.92, 1.08))
	_chew_left -= delta
	if not sim.mouth.is_empty() and sim.dog_state == Sim.Dog.FREE and _chew_left <= 0.0:
		_chew_left = 0.5
		Sound.play("mache", -5.0, _rng.randf_range(0.9, 1.1))
	_step_left -= delta
	if sim.dog_moving and _step_left <= 0.0:
		_step_left = 0.24
		Sound.play("pas", -10.0, _rng.randf_range(0.9, 1.15))
	var tense := sim.suspicion * 0.85
	if sim.warning() or sim.watching():
		tense += 0.45
	if sim.time_left < 20.0:
		tense += 0.3
		if not _ticking_said and not sim.over:
			_ticking_said = true
			hud.toast(Texts.TICKING)
			Sound.play("minuterie", -8.0)
	Sound.set_tension(tense)
