extends Node
## Met le jeu dans les situations à vérifier à l'œil et enregistre une capture de chacune.
## godot --path . -- --no-save --scenario=/dossier [--seulement=nom,nom]

var main: Node
var dir: String
var only: PackedStringArray = []


func _init(main_: Node, dir_: String) -> void:
	main = main_
	dir = dir_
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seulement="):
			only = a.get_slice("=", 1).split(",")


func _ready() -> void:
	# La fenêtre doit rester de la taille demandée (certains gestionnaires de fenêtres l'agrandissent).
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DirAccess.make_dir_recursive_absolute(dir)
	_run.call_deferred()
	get_tree().create_timer(1200.0, true, false, true).timeout.connect(func() -> void: main.quit_game(2))


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func shot(name_: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name_ + ".png"))
	print("CAPTURE ", name_, "  appels de dessin : ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"  images/s : ", Engine.get_frames_per_second())


func until(condition: Callable, max_frames := 3000) -> bool:
	for i in max_frames:
		if main.sim == null or condition.call():
			return true
		if main.sim.over:
			break
		await get_tree().physics_frame
	print("situation jamais atteinte")
	return false


func wants(name_: String) -> bool:
	return only.is_empty() or only.has(name_)


func play(level: int, style: String, seed_ := 5) -> void:
	main.seed_override = seed_
	main.start_level(level)
	main.bot = Bot.new(main.sim, style, 0.3, 1.0, seed_)


## Images par seconde sans synchronisation verticale, temps de chargement et mémoire.
func _performance() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# « --cadence » mesure le jeu tel qu'on y joue ; sinon, sans limite, pour voir la marge.
	if not OS.get_cmdline_user_args().has("--cadence"):
		Fluidity.measuring = true
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	await wait(2.0)
	var ids: Array = [1, 8, 9, 12, 13, 14, 15, 16]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--perf="):
			ids = Array(a.get_slice("=", 1).split(",")).map(func(s: String) -> int: return int(s))
	for id: int in ids:
		var begin := Time.get_ticks_usec()
		play(id, "equilibre", 40 + id)
		await get_tree().process_frame
		var load_ms := (Time.get_ticks_usec() - begin) / 1000.0
		await wait(3.0)
		var times: Array[float] = []
		var last := Time.get_ticks_usec()
		var until_ := last + 20_000_000
		var calls := 0
		while last < until_:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			if now - last > 40000 and OS.get_cmdline_user_args().has("--pics"):
				print("PERF pic %.0f ms à t=%.2f maman=%d pose=%s cachee=%s soupcon=%.2f bruitages=%s" % [(now - last) / 1000.0,
					main.sim.time, main.sim.mom_state, main.stage.dog.pose, main.stage.dog._xray, main.sim.suspicion,
					str(Sound.history.slice(-3))])
			last = now
			calls = maxi(calls, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		times.sort()
		var total := 0.0
		for t in times:
			total += t
		print("PERF 3D calculée à %.0f %%" % (get_window().scaling_3d_scale * 100.0))
		print("PERF niveau %d : %.0f images/s en moyenne, 99 %% des images sous %.1f ms, pire %.1f ms, %d appels de dessin, chargement %.0f ms, fenêtre %s" % [
			id, 1000.0 / (total / times.size()), times[int(times.size() * 0.99)], times.back(), calls, load_ms,
			str(DisplayServer.window_get_size())])
	for i in 20:
		play(1 + i % Levels.COUNT, "equilibre", i)
		await wait(0.4)
		main.go_title()
		await wait(0.1)
		if i == 1 or i == 19:
			print("PERF mémoire après %d parties : %.1f Mo, objets %d, vidéo %.0f Mo" % [i + 1,
				OS.get_static_memory_usage() / 1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT),
				Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])


## Chaque posture vue de près, de côté.
func _poses() -> void:
	var stage: Stage = main.stage
	main.menus.close()
	main.go_title()
	main.menus.close()
	stage.view = "photo"
	var spot := Vector3(-0.35, 0, 1.45)
	stage.dog.position = spot
	stage.dog.rotation.y = PI / 2.0
	stage.mom.position = Vector3(3.5, 0, 6.0)
	stage.photo = [spot + Vector3(0.15, 0.75, 1.55), spot + Vector3(0.05, 0.42, 0.0)]
	for pose: String in ["stand", "sit", "walk", "reach", "crouch", "sulk", "happy", "surprised"]:
		stage.dog.pose = pose
		stage.dog.speed = 1.4
		stage.dog.reach_progress = 0.7
		await wait(0.9)
		await shot("p_chien_" + pose)
	stage.dog.pose = "sit"
	stage.dog.sad = true
	await wait(0.9)
	await shot("p_chien_piteux")
	stage.dog.sad = false
	# De face, puis dressée contre un comptoir, vue de côté.
	stage.dog.pose = "sit"
	stage.dog.rotation.y = 0.35
	stage.photo = [spot + Vector3(0.3, 0.62, 0.95), spot + Vector3(0.0, 0.38, 0.05)]
	await wait(0.9)
	await shot("p_chien_face")
	var edge: Dictionary = stage.map.spots.ilot_sud
	var at := Vector3(edge.stand.x, 0, edge.stand.y)
	var heading: Vector2 = edge.food - edge.stand
	stage.dog.position = at
	stage.dog.rotation.y = atan2(heading.x, heading.y)
	stage.dog.surface_y = stage.map.data.counter_height
	stage.dog.pose = "reach"
	stage.dog.reach_progress = 0.7
	stage.photo = [at + Vector3(1.75, 1.15, 0.45), at + Vector3(0.0, 0.62, -0.18)]
	await wait(0.9)
	await shot("p_chien_comptoir")
	stage.dog.set_festive(true)
	stage.dog.pose = "sit"
	stage.dog.position = at + Vector3(0.0, 0.0, 0.35)
	stage.dog.rotation.y = 0.4
	stage.photo = [stage.dog.position + Vector3(0.4, 0.75, 1.1), stage.dog.position + Vector3(0.0, 0.42, 0.0)]
	await wait(0.9)
	await shot("p_chien_noel")
	stage.dog.set_festive(false)
	stage.dog.position = Vector3(3.5, 0, 6.0)
	var stand := Vector3(-0.2, 0, 1.2)
	stage.mom.position = stand
	stage.mom.rotation.y = 0.6
	stage.photo = [stand + Vector3(0.0, 1.35, 2.5), stand + Vector3(0.0, 0.92, 0.0)]
	for pose: String in ["idle", "walk", "brasser", "couper", "laver", "frigo", "telephone", "four", "ilot", "hint", "feint",
			"round", "look", "point", "laugh", "cheer"]:
		stage.mom.pose = pose
		stage.mom.speed = 1.0
		await wait(0.8)
		await shot("p_maman_" + pose)
	stage.mom.rotation.y = 0.1
	stage.mom.pose = "idle"
	stage.photo = [stand + Vector3(0.12, 1.56, 0.95), stand + Vector3(0.0, 1.47, 0.0)]
	await wait(0.8)
	await shot("p_maman_visage")
	stage.mom.position = Vector3(3.5, 0, 6.0)
	for who: String in ["papa", "charlotte"]:
		var p := PersonView.new(who)
		stage.add_child(p)
		p.position = stand
		p.rotation.y = 0.5
		for pose: String in (["carry", "idle"] if who == "papa" else ["wave", "snitch", "walk"]):
			p.pose = pose
			p.speed = 1.0
			await wait(0.8)
			await shot("p_%s_%s" % [who, pose])
		p.queue_free()


func _run() -> void:
	await wait(1.6)
	if wants("menus"):
		await shot("01_titre")
		main.save.record(1, 2900, 2)
		main.save.record(2, 900, 1)
		main.menus.show_select()
		await wait(0.4)
		await shot("02_missions")
		# Toutes les pièces ouvertes : les cinq onglets doivent tenir, et la chambre montrer sa mission.
		for id in range(1, Levels.COUNT):
			main.save.record(id, 2000, 2)
		main.menus.show_select("chambre")
		await wait(0.4)
		await shot("02_missions_chambre")
		main.show_brief(15)
		await wait(0.4)
		await shot("03_consignes_pyjama")
		main.save.reset_defaults()
		main.save.record(1, 2900, 2)
		main.save.record(2, 900, 1)
		main.show_brief(2)
		await wait(0.4)
		await shot("03_consignes")
		main.menus.show_options(main.menus.show_title)
		await wait(0.4)
		await shot("04_options")
		main.menus.show_credits()
		await wait(0.4)
		await shot("05_credits")
	if only.has("perf"):
		await _performance()
		main.quit_game()
		return
	if wants("poses"):
		await _poses()
	if wants("jeu"):
		play(1, "equilibre")
		await wait(1.2)
		await shot("10_depart")
		await until(func() -> bool: return main.sim.dog_state == Sim.Dog.REACHING and main.sim.reach_progress > 0.22)
		await wait(0.15)
		await shot("11_attrape")
		await until(func() -> bool: return not main.sim.mouth.is_empty() and main.sim.dog_state == Sim.Dog.FREE)
		await wait(0.2)
		await shot("12_gueule")
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.HINT)
		await wait(0.25)
		await shot("13_indice")
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.LOOK)
		await wait(0.5)
		await shot("14_regarde")
		main.bot = Bot.new(main.sim, "tetu", 0.3)
		await until(func() -> bool: return main.sim.caught_count > 0)
		await wait(0.3)
		await shot("15_au_coin")
		await wait(1.1)
		await shot("16_retour")
		await until(func() -> bool: return main.sim.dog_state == Sim.Dog.IN_CORNER)
		await wait(0.9)
		await shot("17_assise_au_coin")
		main.pause_game()
		await wait(0.4)
		await shot("18_pause")
		main.resume_game()
	if wants("tutoriel"):
		# La gueule pleine quand Maman se doute : la consigne doit dire de lâcher.
		play(1, "equilibre", 5)
		await until(func() -> bool: return not main.sim.mouth.is_empty() and main.sim.mouth.size >= Sim.Size.SMALL)
		main.bot = null
		main.sim.mom_left = 0.01
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.HINT, 60)
		await wait(0.2)
		await shot("19_lacher")
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.SCOLD, 200)
		await wait(0.25)
		await shot("19_chicane")
	if wants("cachette"):
		play(2, "campeur")
		await wait(3.4)
		await shot("20_cachette")
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.LOOK)
		await wait(0.4)
		await shot("21_cachette_regard")
	if wants("niveaux"):
		for id in range(2, Levels.COUNT + 1):
			play(id, "equilibre", 20 + id)
			main.speed = 8
			await until(func() -> bool: return main.sim.time > 34.0)
			main.speed = 1
			await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY)
			await wait(0.8)
			await shot("3%d_niveau" % id)
	if wants("assis"):
		# Les postures des nouvelles pièces, de profil : assises (sans chaise : on juge le corps), debout, et Blanche.
		var stage: Stage = main.stage
		main.menus.close()
		main.go_title()
		main.menus.close()
		stage.view = "photo"
		var at := Vector3(-0.2, 0, 1.2)
		var papa: PersonView = stage._person("papa")
		stage.mom.position = Vector3(3.5, 0, 6.0)
		papa.visible = true
		papa.position = at
		papa.rotation.y = PI / 2.0
		stage.photo = [at + Vector3(0.2, 1.1, 2.6), at + Vector3(0.0, 0.7, 0.0)]
		for pose: String in ["seated", "hockey", "film", "manger", "remote", "jaser", "slip", "argue_seated", "snitch_seated"]:
			papa.seat_y = 0.48
			papa.pose = pose
			await wait(0.8)
			await shot("p_assis_" + pose)
		for pose: String in ["servir", "buffet", "carry_plate", "chat", "cheer"]:
			papa.seat_y = 0.0
			papa.pose = pose
			papa.speed = 1.0
			await wait(0.8)
			await shot("p_debout_" + pose)
		papa.visible = false
		var spot := Vector3(-0.35, 0, 1.45)
		stage.dog.position = spot
		stage.dog.rotation.y = PI / 2.0
		stage.photo = [spot + Vector3(0.15, 0.75, 1.55), spot + Vector3(0.05, 0.42, 0.0)]
		for pose: String in ["crawl", "sniff"]:
			stage.dog.pose = pose
			stage.dog.speed = 1.0
			stage.dog.reach_progress = 0.7
			await wait(0.9)
			await shot("p_chien_" + pose)
	if wants("pieces"):
		# Les nouvelles pièces : deux moments de chaque mission, et des situations précises.
		for id in range(9, Levels.COUNT + 1):
			for k in 2:
				play(id, "equilibre", 60 + id)
				main.speed = 8
				await until(func() -> bool: return main.sim.time > 22.0 + k * 31.0)
				main.speed = 1
				await wait(0.7)
				await shot("5%d_piece_%d" % [id, k])
		play(9, "equilibre", 3)
		main.bot = null
		main.sim.dog_pos = Vector2(0.15, -1.8)
		await wait(0.2)
		main.sim.dog_pos = Vector2(0.4, -1.8)
		for i in 40:
			main.sim.dog_pos += Vector2(-0.01, 0)
			await get_tree().physics_frame
		await shot("60_sous_la_table")
		play(13, "equilibre", 4)
		main.bot = null
		var item: Dictionary = main.sim._add_item(Sim.Size.BIG, "table_basse_nord", main.sim.map.spots.table_basse_nord.food)
		main.sim.dog_pos = main.sim.map.spots.table_basse_nord.stand
		main.sim.dog_state = Sim.Dog.REACHING
		main.sim.reach_item = item
		main.sim.reach_progress = 0.6
		main.sim.mom_state = Sim.Mom.LOOK
		main.sim._set_timer(99.0)
		await wait(0.8)
		await shot("61_nez_tendu_papa_regarde")
		play(11, "equilibre", 5)
		main.bot = null
		var charlotte: Dictionary = main.sim.seated[0]
		charlotte.state = "slip"
		charlotte.t = 99.0
		await wait(0.8)
		await shot("62_charlotte_glisse")
		main.sim._bust(charlotte)
		await wait(1.2)
		await shot("63_chicane_charlotte")
		play(10, "equilibre", 6)
		main.bot = null
		main.sim._start_walk("cuisine", "cuisine")
		await until(func() -> bool: return main.sim.mom_out)
		main.sim.mom_left = 0.01
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.HINT)
		await wait(0.2)
		await shot("64_retour_annonce")
	if wants("souper"):
		# La table de la salle à manger de près : les gens assis, Maman qui sert, Maman qui fait le tour de la table.
		var stage: Stage = main.stage
		var table := Vector3(0.15, 0.55, -1.8)
		for id: int in [12, 10, 9, 11]:
			play(id, "equilibre", 70 + id)
			main.bot = null
			main.sim.dog_pos = Vector2(-1.2, -0.4)
			await wait(1.2)
			stage.view = "photo"
			stage.photo = [table + Vector3(1.45, 0.75, 1.6), table]
			await wait(0.5)
			await shot("70_table_%d_sud_est" % id)
			stage.photo = [table + Vector3(-1.6, 0.7, 1.55), table]
			await wait(0.3)
			await shot("70_table_%d_sud_ouest" % id)
			# De profil, depuis le mur est : les gens assis du côté sud, leur chaise et le bord de la table.
			stage.photo = [Vector3(1.6, 0.85, -1.3), Vector3(0.3, 0.7, -1.3)]
			await wait(0.3)
			await shot("70_table_%d_profil" % id)
			stage.view = "jeu"
		play(12, "equilibre", 9)
		main.bot = null
		var stage_mom := main.stage.mom as PersonView
		stage = main.stage
		for to: String in ["servir", "buffet"]:
			main.sim._start_walk(to, main.stage.map.stations[to].activity)
			for k in 3:
				await wait(0.55)
				await shot("71_maman_vers_%s_%d" % [to, k])
			await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY, 900)
			await wait(0.6)
			stage.view = "photo"
			var at := stage_mom.position
			# Vue de l'intérieur de la pièce, du côté de la table.
			var from := Vector3(0.1, 1.55, -0.45) if to == "servir" else Vector3(0.9, 1.6, -1.7)
			stage.photo = [from, at + Vector3(0.0, 0.95, 0.0)]
			await wait(0.3)
			await shot("72_maman_" + to)
			stage.view = "jeu"
	if wants("pyjama"):
		# La soirée pyjama : la vue de jeu, les filles de près, Charlotte à chacun de ses postes.
		var stage: Stage = main.stage
		play(15, "equilibre", 8)
		main.bot = null
		await wait(1.5)
		await shot("80_pyjama")
		stage.view = "photo"
		stage.photo = [Vector3(0.2, 1.0, 1.4), Vector3(0.2, 0.45, -0.3)]
		await wait(0.5)
		await shot("81_pyjama_filles")
		stage.view = "jeu"
		for to: String in ["hamster", "danse"]:
			main.sim._start_walk(to, main.stage.map.stations[to].activity)
			await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY, 900)
			await wait(0.8)
			await shot("82_pyjama_" + to)
		main.sim._start_walk("nid", "film")
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY, 900)
		main.speed = 6
		await until(func() -> bool: return main.sim.time > 40.0)
		main.speed = 1
		await wait(0.6)
		await shot("83_pyjama_jeu")
	if wants("situations"):
		play(5, "equilibre", 3)
		# Maman est envoyée à chaque poste, sans attendre que le hasard l'y mène.
		for station: String in ["frigo", "telephone", "ilot", "evier"]:
			var what: String = main.stage.map.stations[station].activity
			main.sim._start_walk(station, what)
			await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY and main.sim.activity == what, 900)
			await wait(0.9)
			await shot("40_" + what)
		main.speed = 3
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.HINT and main.sim.hint_kind == "feint", 9000)
		main.speed = 1
		await wait(0.25)
		await shot("41_feinte")
		play(6, "equilibre", 4)
		main.speed = 3
		await until(func() -> bool: return main.sim.mom_state == Sim.Mom.HINT and main.sim.hint_kind == "round", 9000)
		main.speed = 1
		await wait(0.4)
		await shot("42_tour_indice")
		await wait(2.2)
		await shot("43_tour")
		play(7, "equilibre", 6)
		main.speed = 3
		main.sim.helpers.clear()
		main.sim._add_helper("papa")
		main.speed = 1
		await until(func() -> bool: return main.sim.activity == "chicane", 900)
		await wait(0.7)
		await shot("46_chicane_maman")
		await wait(1.5)
		await shot("46_chicane_papa")
		main.speed = 3
		for who: String in ["charlotte", "papa"]:
			main.sim.helpers.clear()
			main.sim._add_helper(who)
			main.speed = 1
			await wait(1.6)
			await shot("44_" + who)
		play(8, "equilibre", 8)
		main.speed = 6
		await until(func() -> bool: return main.sim.treasure_due < 0.0, 20000)
		main.speed = 1
		await wait(0.8)
		await shot("45_dinde")
	if wants("fin"):
		play(1, "equilibre")
		main.speed = 16
		await until(func() -> bool: return main.sim.over, 9000)
		main.speed = 1
		await wait(0.8)
		await shot("50_repas_pret")
		await wait(4.2)
		await shot("51_reussi")
		play(8, "campeur")
		main.speed = 30
		await wait(7.5)
		await shot("52_rate")
		main.menus.show_end()
		await wait(0.8)
		await shot("53_fin")
	main.quit_game()
