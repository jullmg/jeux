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
	DirAccess.make_dir_recursive_absolute(dir)
	_run.call_deferred()
	get_tree().create_timer(170.0, true, false, true).timeout.connect(func() -> void: main.quit_game(2))


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
		await get_tree().physics_frame
	print("situation jamais atteinte")
	return false


func wants(name_: String) -> bool:
	return only.is_empty() or only.has(name_)


func play(level: int, style: String, seed_ := 5) -> void:
	main.seed_override = seed_
	main.start_level(level)
	main.bot = Bot.new(main.sim, style, 0.3, 1.0, seed_)


## Chaque posture vue de près, de côté.
func _poses() -> void:
	var stage: Stage = main.stage
	main.menus.close()
	stage.show_title()
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
	stage.dog.pose = "sit"
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
		main.show_brief(2)
		await wait(0.4)
		await shot("03_consignes")
		main.menus.show_options(main.menus.show_title)
		await wait(0.4)
		await shot("04_options")
		main.menus.show_credits()
		await wait(0.4)
		await shot("05_credits")
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
	if wants("situations"):
		play(5, "equilibre", 3)
		main.speed = 3
		for what: String in ["frigo", "telephone", "ilot", "laver"]:
			await until(func() -> bool: return main.sim.mom_state == Sim.Mom.BUSY and main.sim.activity == what, 9000)
			main.speed = 1
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
		for who: String in ["charlotte", "papa"]:
			await until(func() -> bool: return not main.sim.helpers.is_empty() and main.sim.helpers[0].who == who, 9000)
			main.speed = 1
			await wait(1.6)
			await shot("44_" + who)
			main.speed = 3
			await until(func() -> bool: return main.sim.helpers.is_empty(), 9000)
		play(8, "equilibre", 8)
		main.speed = 6
		await until(func() -> bool: return main.sim.treasure_done, 20000)
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
