extends SceneTree
## Tests des règles, sans fenêtre.
## godot --headless --path . -s res://tests/run_tests.gd -- --no-save [--filtre=nom]

const DT := 1.0 / 60.0
const TMP := "user://test_sauvegarde.json"

var map: KitchenMap
var nav: Nav
var mom_nav: Nav
var failures := 0
var checks := 0
var current := ""


func _init() -> void:
	map = KitchenMap.new()
	nav = Sim.dog_grid(map)
	mom_nav = Sim.mom_grid(map)
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filtre="):
			filter = arg.get_slice("=", 1)
	var count := 0
	for m in get_script().get_script_method_list():
		var name: String = m.name
		if name.begins_with("test_") and (filter == "" or name.contains(filter)):
			current = name
			var before := failures
			call(name)
			count += 1
			print(("ok     " if failures == before else "ÉCHEC  ") + name)
	DirAccess.remove_absolute(TMP)
	DirAccess.remove_absolute(TMP + ".abime")
	print("%d tests, %d vérifications, %d échecs" % [count, checks, failures])
	quit(1 if failures > 0 or count == 0 else 0)


func check(condition: bool, what: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("  [%s] %s" % [current, what])


## Un niveau de laboratoire : Maman ne bouge pas et ne se retourne pas toute seule.
func lab(overrides := {}) -> Sim:
	var level := Levels.load_level(1)
	level.spawn = [9999.0, 9999.0]
	level.treasure_at = 2.0
	level.max_items = 20
	level.duration = 9999
	for k: String in overrides:
		level[k] = overrides[k]
	var sim := Sim.new(map, level, 3, nav, mom_nav)
	sim.food.clear()
	sim.mom_left = 9999.0
	sim.drain_events()
	return sim


func put(sim: Sim, size: int, spot: String) -> Dictionary:
	return sim._add_item(size, spot, map.spots[spot].food)


func run(sim: Sim, seconds: float, move := Vector2.ZERO, grab := false) -> void:
	var left := seconds
	while left > 0.0001:
		sim.step(DT, move, grab)
		left -= DT


func at(sim: Sim, spot: String) -> void:
	sim.dog_pos = map.spots[spot].stand


func force_look(sim: Sim) -> void:
	sim.mom_state = Sim.Mom.LOOK
	sim._set_timer(9999.0)


func types(sim: Sim) -> Array:
	return sim.drain_events().map(func(e: Dictionary) -> String: return e.type)


# ------------------------------------------------------------------ plan

func test_niveaux_valides() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var problems := Levels.validate(level, map)
		check(problems.is_empty(), "niveau %d : %s" % [id, ", ".join(problems)])
		check(int(level.id) == id, "numéro du niveau %d" % id)
	for id in range(2, Levels.COUNT + 1):
		check(Levels.load_level(id).hint_min < Levels.load_level(id - 1).hint_min, "indice plus court au niveau %d" % id)


func test_endroits_libres() -> void:
	check(map.is_free(map.corner, Sim.DOG_RADIUS), "le coin est libre")
	for id: String in map.spots:
		check(map.is_free(map.spots[id].stand, Sim.DOG_RADIUS - 0.01), "place libre : " + id)
	for id: String in map.stations:
		check(map.is_free(map.stations[id].pos, Sim.MOM_RADIUS - 0.02), "poste libre : " + id)


func test_chemins_vers_chaque_endroit() -> void:
	for id: String in map.spots:
		var goal: Vector2 = map.spots[id].stand
		var path := nav.path(map.corner, goal)
		check(not path.is_empty() and path[path.size() - 1].distance_to(goal) < 0.15, "coin → " + id)


func test_maman_ne_coince_jamais() -> void:
	# Quel que soit son poste, tout endroit qu'elle n'occupe pas reste accessible et on peut en revenir.
	for station: String in map.stations:
		var blocker := [[map.stations[station].pos, Sim.MOM_RADIUS]]
		for id: String in map.spots:
			var goal: Vector2 = map.spots[id].stand
			if goal.distance_to(map.stations[station].pos) < Sim.MOM_RADIUS + Sim.DOG_RADIUS:
				continue
			var path := nav.path(map.corner, goal, blocker)
			check(not path.is_empty() and path[path.size() - 1].distance_to(goal) < 0.2,
				"Maman à %s : coin → %s" % [station, id])


func test_cachette() -> void:
	var stove: Vector2 = map.stations.cuisiniere.pos
	var south := Vector2(0.02, 0.8)
	check(map.hidden_by_island(stove, south), "derrière l'îlot, vu de la cuisinière")
	check(not map.hidden_by_island(stove, Vector2(1.1, 0.4)), "à côté de l'îlot : visible")
	check(not map.hidden_by_island(stove, Vector2(0.0, 1.9)), "trop loin derrière : visible")
	check(map.hidden_by_island(map.stations.evier.pos, Vector2(-0.65, 0.0)) \
		or map.hidden_by_island(map.stations.evier.pos, Vector2(-0.62, 0.2)), "la cachette se déplace vers l'ouest")
	check(not map.hidden_by_island(map.stations.telephone.pos, south), "le sud n'est plus caché depuis le téléphone")
	var from: Vector2 = map.stations.ilot.pos
	var count := [0, 0]
	for x in range(-20, 21):
		for z in range(-20, 21):
			var p := Vector2(x, z) * 0.08
			count[0] += int(map.hidden_by_island(from, p, false))
			count[1] += int(map.hidden_by_island(from, p, true))
	check(count[1] > 0 and count[1] < count[0], "à l'îlot, la cachette rapetisse : %s" % str(count))


func test_jamais_cachee_les_pattes_en_l_air() -> void:
	var sim := lab()
	at(sim, "ilot_sud")
	check(sim.dog_hidden(), "au sol derrière l'îlot, cachée")
	put(sim, Sim.Size.BIG, "ilot_sud")
	run(sim, 0.2, Vector2.ZERO, true)
	check(sim.paws_up() and not sim.dog_hidden() and sim.dog_infraction(), "les pattes sur l'îlot, visible")
	force_look(sim)
	run(sim, 0.3, Vector2.ZERO, true)
	check(sim.caught_count == 1, "prise sur l'îlot vue de partout")


# ------------------------------------------------------------------ attraper et manger

func test_attraper_et_manger() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	var item := put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 0.9, Vector2.ZERO, true)
	check(sim.dog_state == Sim.Dog.REACHING and sim.mouth.is_empty(), "pas encore attrapé après 0,9 s")
	run(sim, 0.15, Vector2.ZERO, true)
	check(not sim.mouth.is_empty() and sim.mouth.id == item.id, "attrapé après 1 s")
	check(sim.score == 0, "les points comptent quand c'est avalé")
	run(sim, 0.8)
	check(sim.mouth.is_empty() and sim.score == 50, "avalé : 50 points, obtenu %d" % sim.score)


func test_relacher_avant_la_fin() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.BIG, "lave_vaisselle")
	run(sim, 1.5, Vector2.ZERO, true)
	run(sim, Sim.DESCEND_TIME + 0.05)
	check(sim.dog_state == Sim.Dog.FREE and sim.mouth.is_empty() and sim.food.size() == 1, "le morceau reste là")
	run(sim, 1.0, Vector2.ZERO, true)
	check(sim.mouth.is_empty(), "la progression repart de zéro")


func test_redescendre_est_plus_court_que_tout_indice() -> void:
	for id in range(1, Levels.COUNT + 1):
		check(Sim.DESCEND_TIME <= 0.25 and Sim.DESCEND_TIME < Levels.load_level(id).hint_min, "niveau %d" % id)


func test_garder_le_bouton_ne_reprend_pas() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 3.0, Vector2.ZERO, true)
	check(sim.score == 50 and sim.mouth.is_empty(), "bouton gardé : le morceau est mangé, pas lâché")
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 1.5, Vector2.ZERO, true)
	check(sim.dog_state == Sim.Dog.FREE and sim.food.size() == 1, "il faut relâcher avant une autre prise")


func test_lacher_et_reprendre() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.TREASURE, "lave_vaisselle")
	run(sim, 3.55, Vector2.ZERO, true)
	run(sim, 0.3)
	check(not sim.mouth.is_empty(), "le trésor est dans la gueule")
	run(sim, DT * 2, Vector2.ZERO, true)
	check(sim.mouth.is_empty() and sim.food.size() == 1 and sim.food[0].spot == "", "un appui le lâche par terre")
	check(not sim.dog_infraction(), "lâché : plus d'infraction")
	run(sim, 0.1)
	run(sim, 0.1, Vector2.ZERO, true)
	check(not sim.mouth.is_empty(), "on le ramasse d'un appui")
	check(sim.mouth.points == 500, "il garde sa valeur")


func test_miettes_par_terre() -> void:
	var sim := lab()
	sim._add_item(Sim.Size.CRUMB, "", sim.dog_pos + Vector2(-0.5, 0.0))
	run(sim, 0.6, Vector2.LEFT)
	check(sim.score == 10 and sim.food.is_empty(), "miette avalée en passant : %d" % sim.score)
	check(sim.streak == 0, "les miettes ne montent pas le combo")


func test_combo() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	var gains: Array = []
	for i in 7:
		put(sim, Sim.Size.SMALL, "lave_vaisselle")
		var before := sim.score
		run(sim, 1.05, Vector2.ZERO, true)
		run(sim, 0.8)
		gains.append(sim.score - before)
	check(gains == [50, 50, 100, 100, 100, 150, 150], "combo ×2 puis ×3 : %s" % str(gains))
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	force_look(sim)
	run(sim, 0.3, Vector2.ZERO, true)
	check(sim.streak == 0 and sim.multiplier() == 1, "se faire prendre remet le combo à ×1")


func test_occupee_ne_voit_rien() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.TREASURE, "lave_vaisselle")
	for state: int in [Sim.Mom.BUSY, Sim.Mom.HINT, Sim.Mom.TURN, Sim.Mom.TURN_BACK]:
		sim.mom_state = state
		sim.hint_kind = "feint"
		sim._set_timer(9999.0)
		sim.step(DT, Vector2.ZERO, true)
		sim._check_caught(1.0)
		check(sim.caught_count == 0, "état %d : pas de surveillance" % state)


func test_air_sage() -> void:
	var sim := lab()
	force_look(sim)
	run(sim, 3.0)
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 3.0)
	check(sim.caught_count == 0, "sage au coin ou ailleurs : aucun risque")


func test_delai_de_grace() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.BIG, "lave_vaisselle")
	force_look(sim)
	run(sim, 0.05, Vector2.ZERO, true)
	check(sim.caught_count == 0, "pas avant le délai de grâce")
	run(sim, 0.08, Vector2.ZERO, true)
	check(sim.caught_count == 1, "prise juste après")


func test_bouche_pleine_cachee() -> void:
	var sim := lab()
	at(sim, "ilot_sud")
	sim.mouth = {"id": 99, "size": Sim.Size.TREASURE, "points": 500, "eat_left": 3.0, "spot": "", "pos": Vector2.ZERO}
	force_look(sim)
	run(sim, 1.0)
	check(sim.caught_count == 0, "cachée, la gueule pleine : sauve")
	sim.dog_pos = map.spots.lave_vaisselle.stand
	run(sim, 0.2)
	check(sim.caught_count == 1 and sim.mouth.is_empty(), "visible, la gueule pleine : au coin, morceau perdu")


func test_cachee_elle_le_reste_pendant_un_regard() -> void:
	# Qui s'est bien cachée avant que Maman regarde n'est pas découverte sans un nouvel indice.
	for station: String in map.stations:
		var sim := lab({"stations": map.stations.keys(), "move_chance": 1.0})
		sim.station = station
		sim.mom_pos = map.stations[station].pos
		sim.mom_dir = map.stations[station].face
		var spot := Vector2.INF
		for x in range(-22, 23):
			for z in range(-22, 23):
				var p := Vector2(x, z) * 0.08
				if spot == Vector2.INF and map.is_free(p, Sim.DOG_RADIUS) and p.distance_to(sim.mom_pos) > 0.6 \
						and map.hidden_by_island(sim.mom_pos, p, station == "ilot"):
					spot = p
		if spot == Vector2.INF:
			continue
		sim.dog_pos = spot
		sim.mouth = {"id": 99, "size": 3, "points": 500, "eat_left": 999.0, "spot": "", "pos": Vector2.ZERO}
		sim.mom_left = 0.01
		var looked := false
		for i in 900:
			sim.step(DT, Vector2.ZERO, false)
			looked = looked or sim.mom_state == Sim.Mom.LOOK
			if looked and sim.mom_state == Sim.Mom.BUSY:
				break
		check(looked and sim.caught_count == 0, "%s : cachée, jamais prise (%d)" % [station, sim.caught_count])


func test_lacher_coute_le_combo() -> void:
	var sim := lab()
	sim.streak = 7
	sim.mouth = {"id": 99, "size": 2, "points": 150, "eat_left": 9.0, "spot": "", "pos": Vector2.ZERO}
	run(sim, 0.05, Vector2.ZERO, true)
	check(sim.mouth.is_empty() and sim.streak == 0 and sim.multiplier() == 1, "combo remis à zéro")


func test_lacher_pendant_la_descente() -> void:
	var sim := lab()
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 1.02, Vector2.ZERO, true)
	check(sim.dog_state == Sim.Dog.LOWERING, "en train de redescendre")
	run(sim, DT)
	run(sim, 0.8, Vector2.ZERO, true)
	check(sim.mouth.is_empty() and sim.food.size() == 1, "lâché pour de bon, même bouton tenu")


func test_tresor_rendu() -> void:
	var sim := lab()
	sim.dog_pos = map.spots.lave_vaisselle.stand
	sim.mouth = {"id": 99, "size": 3, "points": 500, "eat_left": 3.0, "spot": "", "pos": Vector2.ZERO}
	force_look(sim)
	run(sim, 0.2)
	check(sim.caught_count == 1 and sim.food.is_empty(), "échappé")
	run(sim, 13.0)
	check(sim.food.any(func(i: Dictionary) -> bool: return i.size == Sim.Size.TREASURE), "le trésor revient sur un meuble")


func test_papa_ressort_par_la_porte() -> void:
	var sim := lab({"helpers": ["papa"]})
	sim._add_helper("papa")
	var last := Vector2.ZERO
	for i in 3000:
		sim.step(DT, Vector2.ZERO, false)
		if sim.helpers.is_empty():
			break
		last = sim.helpers[0].pos
	check(sim.helpers.is_empty() and last.distance_to(map.helper_door) < 0.1, "parti par la porte (%s)" % last)


func test_manger_est_plus_lent_en_marchant() -> void:
	var a := lab()
	var b := lab()
	for s: Sim in [a, b]:
		s.dog_pos = Vector2(-1.0, 1.4)
		s.mouth = {"id": 99, "size": 2, "points": 150, "eat_left": 1.5, "spot": "", "pos": Vector2.ZERO}
	run(a, 1.0)
	run(b, 1.0, Vector2.RIGHT)
	check(a.mouth.eat_left < b.mouth.eat_left - 0.4, "immobile, on mange plus vite")


# ------------------------------------------------------------------ au coin

func test_au_coin() -> void:
	for id: String in map.spots:
		for station: String in ["cuisiniere", "frigo", "evier", "telephone"]:
			var sim := lab()
			sim.station = station
			sim.mom_pos = map.stations[station].pos
			at(sim, id)
			sim.dog_state = Sim.Dog.REACHING
			sim.reach_item = put(sim, Sim.Size.BIG, id)
			force_look(sim)
			run(sim, 0.2, Vector2.ZERO, true)
			check(sim.dog_state == Sim.Dog.TO_CORNER, "%s : en route vers le coin" % id)
			var t := 0.0
			var frozen := true
			while sim.dog_state != Sim.Dog.FREE and t < 20.0:
				sim.step(DT, Vector2.LEFT, fmod(t, 0.4) < 0.2)
				if sim.paws_up() or not sim.mouth.is_empty():
					frozen = false
				t += DT
			check(sim.dog_state == Sim.Dog.FREE and sim.dog_pos.distance_to(map.corner) < 0.1,
				"%s : arrive au coin puis reprend la main (%.1f s)" % [id, t])
			check(frozen, "%s : aucune prise pendant la punition" % id)
			check(sim.caught_count == 1, "%s : prise une seule fois" % id)


func test_punition_plus_longue_aux_recidives() -> void:
	var waits: Array = []
	var sim := lab()
	for i in 6:
		sim.caught_count += 1
		sim.dog_state = Sim.Dog.TO_CORNER
		sim.corner_path = PackedVector2Array()
		sim.dog_pos = map.corner
		sim.step(DT, Vector2.ZERO, false)
		waits.append(sim.corner_left)
		sim.dog_state = Sim.Dog.FREE
	check(waits[0] >= 2.0 and waits[1] > waits[0] and waits[5] <= 4.0, str(waits))


# ------------------------------------------------------------------ Maman

func test_toute_surveillance_suit_un_indice() -> void:
	var seen := {}
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		for g in 6:
			var sim := Sim.new(map, level, 40 + g, nav, mom_nav)
			var bot := Bot.new(sim, ["equilibre", "tetu", "campeur"][g % 3], 0.3, 0.9, g)
			var previous := sim.mom_state
			var hint_start := -1.0
			var hint_len := 0.0
			var kind := ""
			while not sim.over:
				bot.step(DT)
				sim.step(DT, bot.move, bot.grab)
				for e in sim.drain_events():
					seen[e.type] = true
					if e.type == "hint":
						hint_start = e.time
						kind = e.kind
				var now := sim.mom_state
				if now != previous:
					if previous == Sim.Mom.HINT:
						hint_len = sim.time - hint_start
					var watching_now := now == Sim.Mom.LOOK or now == Sim.Mom.ROUND
					var was := previous == Sim.Mom.LOOK or previous == Sim.Mom.ROUND
					if watching_now and not was:
						var from_turn := previous == Sim.Mom.TURN and now == Sim.Mom.LOOK
						var from_round := previous == Sim.Mom.HINT and now == Sim.Mom.ROUND and kind == "round"
						check(from_turn or from_round, "niveau %d : surveillance sans indice (%d → %d)" % [id, previous, now])
						check(hint_len >= float(level.hint_min) - DT * 1.5,
							"niveau %d : indice de %.3f s sous %.2f" % [id, hint_len, level.hint_min])
					if now == Sim.Mom.TURN:
						check(kind == "real", "niveau %d : demi-tour après une feinte" % id)
				previous = now
	for type: String in ["hint", "look", "walk", "round", "surprise", "noise", "feint_end", "caught", "distract",
			"snitch", "snitch_call", "papa_drop", "treasure", "meal_ready", "dropped", "corner_arrive"]:
		check(seen.has(type), "jamais arrivé pendant les parties : " + type)


func test_indices_plus_longs() -> void:
	var a := lab()
	var b := lab()
	b.hint_bonus = 0.3
	a.rng.seed = 5
	b.rng.seed = 5
	check(is_equal_approx(b._hint_time() - a._hint_time(), 0.3), "réglage d'accessibilité")


func test_bruit_referme_la_fenetre() -> void:
	var sim := lab({"noise": true, "noisy_spots": ["lave_vaisselle"]})
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.SMALL, "lave_vaisselle")
	run(sim, 1.05, Vector2.ZERO, true)
	check(sim.suspicion > 0.1, "la méfiance monte")
	check(sim.mom_state != Sim.Mom.BUSY or sim.mom_left <= 0.2, "la fenêtre se referme")
	var events := types(sim)
	check(events.has("noise"), "bruit signalé")


func test_tabouret() -> void:
	for noisy: bool in [true, false]:
		var sim := lab({"noise": noisy})
		sim.dog_pos = map.stool_pos + Vector2(0.0, 0.6)
		run(sim, 0.6, Vector2.UP)
		check(types(sim).has("noise") == noisy, "tabouret bruyant : %s" % noisy)


func test_soupcon() -> void:
	var sim := lab()
	sim.suspicion = 0.8
	run(sim, 5.0)
	check(sim.suspicion < 0.45, "assise au coin, le soupçon redescend : %.2f" % sim.suspicion)
	var short := lab()
	var long := lab()
	short.suspicion = 1.0
	short.rng.seed = 9
	long.rng.seed = 9
	short._enter_busy("brasser")
	long._enter_busy("brasser")
	check(short.mom_left < long.mom_left, "soupçon élevé : fenêtre plus courte")


## La jauge doit se voir bouger (demande de Julien) : chaque morceau la fait monter, plus il est gros.
func test_mefiance_visible() -> void:
	var before := 0.0
	for size: int in [Sim.Size.SMALL, Sim.Size.BIG, Sim.Size.TREASURE]:
		var sim := lab()
		var item := put(sim, size, "nord_gauche")
		sim._take(item)
		check(sim.suspicion > before and sim.suspicion >= 0.05, "morceau %d : méfiance %.2f" % [size, sim.suspicion])
		before = sim.suspicion
		check(types(sim).has("wary"), "la raison est signalée")
	var crumb := lab()
	crumb._take(put(crumb, Sim.Size.CRUMB, "nord_gauche"))
	check(crumb.suspicion == 0.0, "une miette ne se remarque pas")
	# Et pendant une vraie partie, même la première mission la fait monter nettement.
	var map := KitchenMap.new()
	var peaks := 0.0
	for g in 10:
		var sim := Sim.new(map, Levels.load_level(1), 100 + g)
		var bot := Bot.new(sim, "equilibre", 0.4, 0.9, 200 + g)
		var peak := 0.0
		while not sim.over:
			bot.step(0.05)
			sim.step(0.05, bot.move, bot.grab)
			sim.events.clear()
			peak = maxf(peak, sim.suspicion)
		peaks += peak
	check(peaks / 10.0 > 0.25, "sommet moyen de la mission 1 : %.2f" % (peaks / 10.0))


func test_tour_de_l_ilot_contre_le_camping() -> void:
	var sim := lab({"round_chance": 0.01})
	sim.unseen_time = 6.0
	sim.mom_left = 0.01
	run(sim, 0.05)
	check(sim.mom_state == Sim.Mom.HINT and sim.hint_kind == "round", "annoncé par un indice")
	run(sim, 3.0)
	check(sim.mom_state == Sim.Mom.ROUND or sim.mom_state == Sim.Mom.WALK, "elle fait le tour")


func test_charlotte_denonce_apres_un_indice() -> void:
	var sim := lab({"helpers": ["charlotte"]})
	at(sim, "lave_vaisselle")
	sim._add_helper("charlotte")
	sim.helpers[0].pos = sim.dog_pos + Vector2(-0.7, 0.5)
	sim.helpers[0].state = "stay"
	sim.helpers[0].t = 99.0
	put(sim, Sim.Size.TREASURE, "lave_vaisselle")
	run(sim, 0.4, Vector2.ZERO, true)
	var first := types(sim)
	check(first.has("snitch") and not first.has("snitch_call"), "« Hon ! » d'abord")
	run(sim, 0.7, Vector2.ZERO, true)
	var then := types(sim)
	check(then.has("snitch_call") and then.has("hint"), "puis Maman donne son indice")
	check(sim.mom_state == Sim.Mom.HINT and sim.caught_count == 0, "il reste le temps de redescendre")


func test_fin_du_niveau_et_etoiles() -> void:
	var sim := lab({"duration": 2, "stars": [100, 200, 300]})
	sim.score = 220
	run(sim, 2.1)
	check(sim.over and sim.stars() == 2 and types(sim).has("meal_ready"), "le repas est prêt")
	var time := sim.time
	run(sim, 1.0)
	check(sim.time == time, "plus rien ne bouge après la fin")


func test_robot_sage_jamais_pris() -> void:
	# Équité : qui réagit à l'indice (plus vite que l'indice minimal) ne se fait jamais prendre.
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var reaction: float = minf(0.45, float(level.hint_min) - 0.02)
		var caught := 0
		for g in 8:
			var sim := Sim.new(map, level, 700 + g, nav, mom_nav)
			var bot := Bot.new(sim, "sage", reaction, 1.0, g)
			while not sim.over:
				bot.step(DT)
				sim.step(DT, bot.move, bot.grab)
				sim.events.clear()
			caught += sim.caught_count
		check(caught == 0, "niveau %d : le robot sage (%.2f s) pris %d fois" % [id, reaction, caught])


func test_meme_graine_meme_partie() -> void:
	var results: Array = []
	for i in 2:
		var sim := Sim.new(map, Levels.load_level(7), 11, nav, mom_nav)
		var bot := Bot.new(sim, "equilibre", 0.4, 0.9, 4)
		while not sim.over:
			bot.step(DT)
			sim.step(DT, bot.move, bot.grab)
			sim.events.clear()
		results.append([sim.score, sim.caught_count, sim.dog_pos, sim.mom_pos])
	check(results[0] == results[1], str(results))


func test_toujours_dans_la_piece() -> void:
	var sim := lab({"helpers": ["papa", "charlotte"], "stations": ["cuisiniere", "frigo", "evier", "planche"], "move_chance": 1.0})
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var move := Vector2.ZERO
	var bad := 0
	sim.mom_left = 1.0
	for i in 20000:
		if i % 30 == 0:
			move = Vector2.from_angle(rng.randf() * TAU)
		sim.step(DT, move, rng.randf() < 0.02)
		sim.events.clear()
		if not map.is_free(sim.dog_pos, Sim.DOG_RADIUS - 0.03) and sim.dog_state == Sim.Dog.FREE:
			bad += 1
	check(bad == 0, "Blanche dans un meuble %d fois" % bad)


# ------------------------------------------------------------------ sauvegarde

func write_tmp(text: String) -> void:
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_sauvegarde_aller_retour() -> void:
	DirAccess.remove_absolute(TMP)
	var s := SaveData.new(TMP)
	check(s.unlocked == 1 and s.total_stars() == 0, "nouvelle partie")
	check(s.record(1, 500, 2), "nouveau record")
	check(not s.record(1, 100, 0), "pas un record")
	s.options.music = 0.25
	s.options.long_hints = true
	s.save_file()
	var t := SaveData.new(TMP)
	check(t.unlocked == 2 and t.stars_of(1) == 2 and t.best_of(1) == 500, "relu")
	check(is_equal_approx(t.options.music, 0.25) and t.options.long_hints, "options relues")
	t.erase_progress()
	var u := SaveData.new(TMP)
	check(u.unlocked == 1 and u.total_stars() == 0 and u.options.long_hints, "effacer garde les options")


func test_deblocage() -> void:
	DirAccess.remove_absolute(TMP)
	var s := SaveData.new(TMP)
	s.record(1, 10, 0)
	check(s.unlocked == 1, "sans étoile, rien ne s'ouvre")
	for id in range(1, Levels.COUNT + 1):
		s.record(id, 100, 1)
	check(s.unlocked == Levels.COUNT, "jamais au-delà du dernier")


func test_sauvegarde_abimee() -> void:
	for text: String in ["", "{", "[1,2]", "null", "\"salut\"",
			"{\"unlocked\":\"beaucoup\",\"stars\":[1],\"best\":{\"99\":5,\"x\":1,\"1\":\"a\"},\"options\":{\"music\":\"fort\",\"fullscreen\":3}}",
			"{\"unlocked\":9999,\"stars\":{\"1\":50},\"options\":{\"music\":40,\"sfx\":-2}}"]:
		write_tmp(text)
		var s := SaveData.new(TMP)
		check(s.unlocked >= 1 and s.unlocked <= Levels.COUNT, "déblocage sûr : " + text)
		check(s.stars_of(1) >= 0 and s.stars_of(1) <= 3, "étoiles sûres : " + text)
		check(s.options.music >= 0.0 and s.options.music <= 1.0 and s.options.fullscreen is bool, "options sûres : " + text)


func test_sans_sauvegarde() -> void:
	DirAccess.remove_absolute(TMP)
	var s := SaveData.new("")
	s.record(1, 100, 1)
	check(s.unlocked == 2 and not s.save_file() and not FileAccess.file_exists(TMP), "--no-save n'écrit rien")


# ------------------------------------------------------------------ ressources

func test_modeles_de_nourriture() -> void:
	var foods: Node = (load("res://art/models/nourriture.glb") as PackedScene).instantiate()
	for id in range(1, Levels.COUNT + 1):
		for entry: Array in Levels.load_level(id).foods.values():
			check(foods.find_child(entry[0], true, false) is MeshInstance3D, "niveau %d : modèle %s" % [id, entry[0]])
	foods.free()


func test_modeles_complets() -> void:
	for name_: String in ["cuisine", "blanche", "maman", "papa", "charlotte"]:
		var model: Node = (load("res://art/models/%s.glb" % name_) as PackedScene).instantiate()
		if name_ == "cuisine":
			for part: String in ["PorteFrigo", "Tabouret", "Ilot"]:
				check(model.find_child(part, true, false) != null, "cuisine : " + part)
		else:
			var skeletons := model.find_children("*", "Skeleton3D", true, false)
			check(skeletons.size() == 1, name_ + " : un squelette")
			var bones: Array = ["jaw", "tail3", "lidL", "browR", "earL", "hpawR"] if name_ == "blanche" else ["head", "handR", "footL"]
			for b: String in bones:
				check(skeletons[0].find_bone(b) >= 0, "%s : os %s" % [name_, b])
			if name_ != "blanche":
				for mouth: String in ["Sourire", "Neutre", "Ouverte", "Fachee"]:
					check(model.find_child("Bouche" + mouth, true, false) != null, name_ + " : bouche " + mouth)
		model.free()


func test_taille_de_blanche() -> void:
	# Le jeu place la gueule d'après la taille du modèle : le script Blender doit dire la même.
	var script := FileAccess.get_file_as_string("res://tools/blender/dog.py")
	check(script.contains("\nTAILLE = %s\n" % str(DogView.SIZE)), "DogView.SIZE diffère de TAILLE (dog.py)")


func test_tous_les_sons_existent() -> void:
	var regex := RegEx.new()
	regex.compile("Sound\\.play\\(\"(\\w+)\"|\\[\"(couteau|brasse|eau|pas)\", [0-9.]+\\]|\"(tombe|fracas|miette|prise|combo|avale|tour|alerte|victoire|rate)\"")
	var found := {}
	for path: String in ["res://scenes/main.gd", "res://ui/menus.gd", "res://ui/ui_style.gd"]:
		for m in regex.search_all(FileAccess.get_file_as_string(path)):
			for i in range(1, 4):
				if m.get_string(i) != "":
					found[m.get_string(i)] = true
	check(found.size() > 20, "sons trouvés dans le code : %d" % found.size())
	for sound: String in found:
		check(ResourceLoader.exists("res://audio/generated/%s.wav" % sound), "son absent : " + sound)
	for track: String in ["menu", "jeu", "tension"]:
		check(ResourceLoader.exists("res://audio/generated/musique_%s.wav" % track), "musique : " + track)
	# La couche de tension joue par-dessus la musique du jeu : les deux boucles doivent durer pareil.
	var game_track: AudioStream = load("res://audio/generated/musique_jeu.wav")
	var tension_track: AudioStream = load("res://audio/generated/musique_tension.wav")
	check(absf(game_track.get_length() - tension_track.get_length()) < 0.001, "jeu et tension de même durée")


func test_textes_complets() -> void:
	for activity: String in Sim.ACTIVITY_WINDOWS:
		check(Texts.ACTIVITY.has(activity), "activité sans texte : " + activity)
	for id: String in map.stations:
		check(Sim.ACTIVITY_WINDOWS.has(map.stations[id].activity), "poste sans durée : " + id)
