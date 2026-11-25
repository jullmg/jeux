extends Node
## Le jeu se teste lui-même : titre, missions, les huit niveaux joués par un robot, pause, résultats et fin.
## Sert aussi à vérifier la version exportée. Écrit un rapport JSON puis quitte (code 0 si tout va bien).

var main: Node
var out: String
var report := {"ok": false, "errors": [], "levels": [], "screens": [], "min_fps": 0.0, "load_ms": []}


func _init(main_: Node, out_: String) -> void:
	main = main_
	out = out_
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_run.call_deferred()
	get_tree().create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		_fail("trop long")
		_end())


func _fail(why: String) -> void:
	report.errors.append(why)


func _expect(condition: bool, why: String) -> void:
	if not condition:
		_fail(why)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _screen(name_: String) -> void:
	report.screens.append(main.menus.screen)
	_expect(main.menus.screen == name_, "écran « %s » attendu, « %s » affiché" % [name_, main.menus.screen])
	if name_ != "":
		_expect(main.get_viewport().gui_get_focus_owner() != null, "aucun bouton sélectionné sur « %s »" % name_)


func _run() -> void:
	await _frames(10)
	_screen("titre")
	main.menus.show_select()
	await _frames(5)
	_screen("missions")
	main.menus.show_options(main.menus.show_title)
	await _frames(5)
	_screen("options")
	main.menus.show_credits()
	await _frames(5)
	_screen("credits")
	for id in range(1, Levels.COUNT + 1):
		main.show_brief(id)
		await _frames(5)
		_screen("consignes")
		var started := Time.get_ticks_msec()
		main.seed_override = 100 + id
		main.start_level(id)
		await _frames(2)
		report.load_ms.append(Time.get_ticks_msec() - started)
		_screen("")
		main.bot = Bot.new(main.sim, "equilibre", 0.35, 1.0, id)
		await _frames(30)
		main.pause_game()
		await _frames(5)
		_screen("pause")
		var frozen: float = main.sim.time
		await _frames(20)
		_expect(main.sim.time == frozen, "le jeu avance pendant la pause")
		main.resume_game()
		await _frames(3)
		_screen("")
		_expect(main.state == "jeu", "reprise après la pause")
		main.speed = 24
		var guard := 0
		while main.state == "jeu" and guard < 6000:
			guard += 1
			await get_tree().physics_frame
		main.speed = 1
		await _frames(5)
		_screen("resultats")
		_expect(main.sim.over, "niveau %d non terminé" % id)
		report.levels.append({"level": id, "score": main.sim.score, "stars": main.sim.stars(), "caught": main.sim.caught_count})
		_expect(main.sim.score > 0, "niveau %d sans un point" % id)
		_expect(main.save.best_of(id) == main.sim.score, "record non noté au niveau %d" % id)
	main.menus.show_end()
	await _frames(5)
	_screen("fin")
	main.go_title()
	await _frames(30)
	_screen("titre")
	_expect(main.sim == null, "partie encore active au titre")
	report.min_fps = Engine.get_frames_per_second()
	report.memory_mb = OS.get_static_memory_usage() / 1048576.0
	report.nodes = get_tree().get_node_count()
	_end()


func _end() -> void:
	report.ok = report.errors.is_empty()
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(report, "\t"))
	print("AUTOTEST ", "OK" if report.ok else "ÉCHEC", " ", report.errors)
	main.quit_game(0 if report.ok else 1)
