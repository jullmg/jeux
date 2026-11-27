extends SceneTree
## Tests des règles, sans fenêtre.
## godot --headless --path . -s res://tests/run_tests.gd -- --no-save [--filtre=nom]

const DT := 1.0 / 60.0
const TMP := "user://test_sauvegarde.json"

const PIECES := ["cuisine", "salle_a_manger", "salon", "fetes"]

var map: RoomMap
var nav: Nav
var mom_nav: Nav
## Les plans et les grilles de chaque pièce : pièce → [RoomMap, Nav, Nav].
var pieces := {}
var failures := 0
var checks := 0
var current := ""


func _init() -> void:
	map = RoomMap.new()
	nav = Sim.dog_grid(map)
	mom_nav = Sim.mom_grid(map)
	pieces["cuisine"] = [map, nav, mom_nav]
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


## Les plans et grilles d'une pièce, faits une fois.
func grids(piece: String) -> Array:
	if not pieces.has(piece):
		var m := RoomMap.new(piece)
		pieces[piece] = [m, Sim.dog_grid(m), Sim.mom_grid(m)]
	return pieces[piece]


## Une partie dans le niveau `id`, sur le plan de sa pièce.
func game(id: int, seed_: int) -> Sim:
	var level := Levels.load_level(id)
	var g := grids(Levels.piece_of(level))
	return Sim.new(g[0], level, seed_, g[1], g[2])


## Un laboratoire dans une autre pièce : `overrides` doit donner ses postes.
func lab_in(piece: String, overrides := {}) -> Sim:
	var g := grids(piece)
	var m: RoomMap = g[0]
	var level := Levels.load_level(1)
	level.piece = piece
	level.spots = m.spots.keys()
	level.noisy_spots = []
	level.helpers = []
	level.spawn = [9999.0, 9999.0]
	level.treasure_at = 2.0
	level.max_items = 20
	level.duration = 9999
	level.erase("tutorial")
	for k: String in overrides:
		level[k] = overrides[k]
	var sim := Sim.new(m, level, 3, g[1], g[2])
	sim.food.clear()
	sim.mom_left = 9999.0
	sim.drain_events()
	return sim


func put(sim: Sim, size: int, spot: String) -> Dictionary:
	return sim._add_item(size, spot, sim.map.spots[spot].food)


func run(sim: Sim, seconds: float, move := Vector2.ZERO, grab := false) -> void:
	var left := seconds
	while left > 0.0001:
		sim.step(DT, move, grab)
		left -= DT


func at(sim: Sim, spot: String) -> void:
	sim.dog_pos = sim.map.spots[spot].stand


func force_look(sim: Sim) -> void:
	sim.mom_state = Sim.Mom.LOOK
	sim._set_timer(9999.0)


func types(sim: Sim) -> Array:
	return sim.drain_events().map(func(e: Dictionary) -> String: return e.type)


# ------------------------------------------------------------------ plan

func test_niveaux_valides() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var problems := Levels.validate(level, grids(Levels.piece_of(level))[0])
		check(problems.is_empty(), "niveau %d : %s" % [id, ", ".join(problems)])
		check(int(level.id) == id, "numéro du niveau %d" % id)
	# L'indice raccourcit d'une mission à l'autre ; il remonte un peu au début d'une nouvelle pièce.
	for id in range(2, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var before := Levels.load_level(id - 1)
		if Levels.piece_of(level) == Levels.piece_of(before) or id == Levels.COUNT:
			check(level.hint_min < before.hint_min, "indice plus court au niveau %d" % id)
	var last := Levels.load_level(Levels.COUNT)
	for id in range(1, Levels.COUNT):
		check(float(last.hint_min) <= float(Levels.load_level(id).hint_min), "la dernière mission a l'indice le plus court")


func test_endroits_libres() -> void:
	for piece: String in PIECES:
		var m: RoomMap = grids(piece)[0]
		check(m.is_free(m.corner, Sim.DOG_RADIUS), piece + " : le coin est libre")
		for id: String in m.spots:
			check(m.is_free(m.spots[id].stand, Sim.DOG_RADIUS - 0.01), "%s : place libre : %s" % [piece, id])
			check(m.room.has_point(m.spots[id].food), "%s : nourriture dans la pièce : %s" % [piece, id])
		for id: String in m.stations:
			var st: Dictionary = m.stations[id]
			# Assise, on est sur sa chaise ; sortie, on est hors de la pièce.
			if not st.seated and not st.outside:
				check(m.is_free(st.pos, Sim.MOM_RADIUS - 0.02), "%s : poste libre : %s" % [piece, id])
			check(st.outside != m.room.has_point(st.pos), "%s : poste %s du bon côté de la porte" % [piece, id])
		for p: Vector2 in m.ring:
			check(m.is_free(p, Sim.MOM_RADIUS - 0.02), "%s : tour libre en %s" % [piece, p])
		if m.mom_door != Vector2.INF:
			check(m.is_free(m.mom_door, Sim.MOM_RADIUS - 0.02), piece + " : la porte de Maman est libre")
		for name_: String in m.data.get("waypoints", {}):
			check(m.is_free(RoomMap.vec(m.data.waypoints[name_]), Sim.HELPER_RADIUS), "%s : passage %s" % [piece, name_])
		for id: String in m.seats:
			check(m.seats[id].chair >= 0 or m.room.has_point(m.seats[id].pos), "%s : place %s" % [piece, id])


func test_chemins_vers_chaque_endroit() -> void:
	for piece: String in PIECES:
		var m: RoomMap = grids(piece)[0]
		var n: Nav = grids(piece)[1]
		for id: String in m.spots:
			var goal: Vector2 = m.spots[id].stand
			var path := n.path(m.corner, goal)
			check(not path.is_empty() and path[path.size() - 1].distance_to(goal) < 0.15, "%s : coin → %s" % [piece, id])
			var back := n.path(goal, m.corner)
			check(not back.is_empty() and back[back.size() - 1].distance_to(m.corner) < 0.15, "%s : %s → coin" % [piece, id])


## Aucune poche : toute place libre du plancher se rejoint depuis le coin, même quand Maman est à un de ses postes,
## dans la porte ou en train de faire son tour (sinon un but touché à l'écran ou un robot pousse sans fin).
func test_aucune_poche() -> void:
	for piece: String in PIECES:
		var m: RoomMap = grids(piece)[0]
		var n: Nav = grids(piece)[1]
		var places: Dictionary = {"personne": Vector2.INF}
		for station: String in m.stations:
			var st: Dictionary = m.stations[station]
			if not st.seated and not st.outside:
				places[station] = st.pos
		if m.mom_door != Vector2.INF:
			places["porte"] = m.mom_door
		for p: Vector2 in m.ring:
			places["tour %s" % p] = p
		for where: String in places:
			var lost := _cells_out_of_reach(n, places[where])
			check(lost.is_empty(), "%s, Maman à %s : %d places hors d'atteinte, ex. %s" % [piece, where, lost.size(),
				str(lost.slice(0, 3))])


## Les places libres qu'on ne rejoint pas depuis le coin quand quelqu'un se tient en `blocker`.
func _cells_out_of_reach(n: Nav, blocker: Vector2) -> Array:
	var reach := Sim.MOM_RADIUS + n.radius
	var blocked := func(c: Vector2i) -> bool:
		return n.grid.is_point_solid(c) or (blocker != Vector2.INF and n.center(c).distance_to(blocker) < reach)
	var start := n.nearest_open(n.map.corner)
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nb := c + d
			if n.grid.region.has_point(nb) and not seen.has(nb) and not blocked.call(nb):
				seen[nb] = true
				todo.append(nb)
	var lost := []
	for x in n.grid.region.size.x:
		for y in n.grid.region.size.y:
			var c := Vector2i(x, y)
			if not blocked.call(c) and not seen.has(c):
				lost.append(n.center(c))
	return lost


func test_maman_ne_coince_jamais() -> void:
	# Quel que soit son poste, tout endroit qu'elle n'occupe pas reste accessible et on peut en revenir. Assise ou
	# sortie, elle n'est pas un obstacle ; dans la porte, elle en est un.
	for piece: String in PIECES:
		var m: RoomMap = grids(piece)[0]
		var n: Nav = grids(piece)[1]
		var places: Dictionary = {}
		for station: String in m.stations:
			var st: Dictionary = m.stations[station]
			if not st.seated and not st.outside:
				places[station] = st.pos
		if m.mom_door != Vector2.INF:
			places["porte"] = m.mom_door
		for p: Vector2 in m.ring:
			places["tour %s" % p] = p
		for where: String in places:
			var blocker := [[places[where], Sim.MOM_RADIUS]]
			for id: String in m.spots:
				var goal: Vector2 = m.spots[id].stand
				if goal.distance_to(places[where]) < Sim.MOM_RADIUS + Sim.DOG_RADIUS:
					continue
				var path := n.path(m.corner, goal, blocker)
				check(not path.is_empty() and path[path.size() - 1].distance_to(goal) < 0.2,
					"%s : Maman à %s : coin → %s" % [piece, where, id])


func test_cachette() -> void:
	var stove: Vector2 = map.stations.cuisiniere.pos
	var south := Vector2(0.02, 0.8)
	check(map.hidden(stove, south), "derrière l'îlot, vu de la cuisinière")
	check(not map.hidden(stove, Vector2(1.1, 0.4)), "à côté de l'îlot : visible")
	check(not map.hidden(stove, Vector2(0.0, 1.9)), "trop loin derrière : visible")
	check(map.hidden(map.stations.evier.pos, Vector2(-0.65, 0.0)) \
		or map.hidden(map.stations.evier.pos, Vector2(-0.62, 0.2)), "la cachette se déplace vers l'ouest")
	check(not map.hidden(map.stations.telephone.pos, south), "le sud n'est plus caché depuis le téléphone")
	var from: Vector2 = map.stations.ilot.pos
	var count := [0, 0]
	for x in range(-20, 21):
		for z in range(-20, 21):
			var p := Vector2(x, z) * 0.08
			count[0] += int(map.hidden(from, p, ""))
			count[1] += int(map.hidden(from, p, "ilot"))
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
						and map.hidden(sim.mom_pos, p, "ilot" if station == "ilot" else ""):
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


## Papa dans le chemin : Maman se chicane avec lui, tournée vers lui, sans rien remarquer (demande de Julien).
func test_chicane() -> void:
	var sim := lab({"helpers": ["papa"]})
	sim._add_helper("papa")
	var argued := false
	for i in 600:
		sim.step(DT, Vector2.ZERO, false)
		if types(sim).has("argue"):
			argued = true
			break
	check(argued, "la chicane commence")
	var papa: Dictionary = sim.helpers[0]
	check(sim.activity == "chicane" and papa.pos.distance_to(sim.mom_pos) < 1.0, "Papa est à côté d'elle")
	check(sim.mom_dir.dot((papa.pos - sim.mom_pos).normalized()) > 0.99, "elle lui fait face")
	at(sim, "lave_vaisselle")
	put(sim, Sim.Size.BIG, "lave_vaisselle")
	var seen := false
	var holding := int((Sim.GRAB_TIMES[Sim.Size.BIG] + 0.3) / DT)
	for i in int((Sim.ARGUE_TIME - 0.2) / DT):
		sim.step(DT, Vector2.ZERO, i < holding)
		seen = seen or sim.watching() or sim.warning()
	check(not seen and sim.caught_count == 0 and sim.eaten[Sim.Size.BIG] == 1, "une occasion sans surveillance")
	run(sim, 0.5)
	check(sim.activity != "chicane" and papa.state == "leave", "puis chacun retourne à ses affaires")
	# Un vacarme coupe la chicane : l'indice vient vite.
	var loud := lab({"helpers": ["papa"], "noise": true})
	loud._add_helper("papa")
	for i in 600:
		loud.step(DT, Vector2.ZERO, false)
		if loud.activity == "chicane":
			break
	loud._noise(loud.dog_pos, "tabouret")
	run(loud, 0.4)
	check(loud.activity != "chicane" and loud.mom_state != Sim.Mom.BUSY, "le bruit coupe la chicane")


## Debout à côté de Maman, Papa ne ferme jamais le passage : le chiot lui passe entre les jambes.
func test_papa_ne_coince_pas() -> void:
	var sim := lab({"helpers": ["papa"]})
	sim._add_helper("papa")
	check(sim.people_circles().size() == 2, "en marche, on le contourne")
	for i in 600:
		sim.step(DT, Vector2.ZERO, false)
		if sim.activity == "chicane":
			break
	check(sim.people_circles().size() == 1, "immobile, il laisse passer")


## Dans de vraies parties, presque chaque passage de Papa finit en chicane.
func test_chicane_presque_a_chaque_passage() -> void:
	var passes := 0
	var arguments := 0
	for g in 20:
		var sim := Sim.new(map, Levels.load_level(7 + g % 2), 300 + g, nav, mom_nav)
		var bot := Bot.new(sim, "equilibre", 0.3, 0.9, g)
		while not sim.over:
			bot.step(DT)
			sim.step(DT, bot.move, bot.grab)
			for e in sim.drain_events():
				if e.type == "helper_in" and e.who == "papa" and sim.time_left > 15.0:
					passes += 1
				if e.type == "argue":
					arguments += 1
	check(passes > 10 and arguments >= passes * 0.7, "%d chicanes pour %d passages" % [arguments, passes])


## Le jeu reste fluide sur un grand écran (retour de Julien : 45 images/s en 3440×1440).
func test_fluidite_selon_l_ecran() -> void:
	check(Fluidity.scale_for(Vector2i(1920, 1080)) == 1.0, "en 1080p, tout est calculé")
	check(Fluidity.scale_for(Vector2i(1440, 810)) == 1.0, "petite fenêtre aussi")
	for window: Vector2i in [Vector2i(3440, 1440), Vector2i(3456, 2234), Vector2i(3840, 2160)]:
		var s := Fluidity.scale_for(window)
		var pixels := window.x * window.y * s * s
		check(s < 0.75 and s >= Fluidity.LOWEST and pixels <= Fluidity.BUDGET * 1.01, "%s : %.2f" % [window, s])
	check(Fluidity.scale_for(Vector2i(7680, 4320)) == Fluidity.LOWEST, "jamais sous le plancher")
	check(Fluidity.cap_for(120.0) == 60 and Fluidity.cap_for(60.0) == 0 and Fluidity.cap_for(-1.0) == 0, "cadence")


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
			var sim := game(id, 40 + g)
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
						check(kind == "real" or kind == "retour", "niveau %d : demi-tour après une feinte" % id)
				previous = now
	for type: String in ["hint", "look", "walk", "round", "surprise", "noise", "feint_end", "caught", "distract",
			"snitch", "snitch_call", "papa_drop", "argue", "treasure", "meal_ready", "dropped", "corner_arrive"]:
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
		sim.dog_pos = map.stools[0].pos + Vector2(0.0, 0.6)
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
	var map := RoomMap.new()
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
			var sim := game(id, 700 + g)
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


# ------------------------------------------------------------------ salle à manger et salon

## Sous la table : personne debout ne voit Blanche ; assis, on voit seulement la moitié de son côté.
func test_sous_la_table() -> void:
	var m: RoomMap = grids("salle_a_manger")[0]
	var middle := Vector2(0.15, -1.8)
	var north := Vector2(0.15, -2.05)
	var south := Vector2(0.15, -1.55)
	var standing: Vector2 = m.stations.buffet.pos
	check(m.hidden(standing, middle) and m.hidden(standing, north) and m.hidden(standing, south), "debout : cachée")
	check(m.hidden(m.stations.servir.pos, north), "debout, tout près de la table : cachée")
	check(not m.hidden(standing, Vector2(1.2, -0.9)), "hors de la table : visible")
	check(not m.hidden(standing, Vector2(0.15, -2.23)), "au bord de la table : visible")
	var seated_north: Vector2 = m.seats.nord_ouest.pos
	check(not m.hidden(seated_north, north, "", true) and m.hidden(seated_north, south, "", true), "assis au nord")
	var seated_south: Vector2 = m.seats.sud_est.pos
	check(m.hidden(seated_south, north, "", true) and not m.hidden(seated_south, south, "", true), "assis au sud")
	# Dans une partie : sous la table, la gueule pleine, Maman debout la regarde et ne voit rien…
	var sim := lab_in("salle_a_manger", {"stations": ["buffet"]})
	sim.dog_pos = middle
	sim.mouth = {"id": 99, "size": 2, "points": 150, "eat_left": 999.0, "spot": "", "pos": Vector2.ZERO}
	force_look(sim)
	run(sim, 0.5)
	check(sim.dog_hidden() and sim.caught_count == 0, "sous la table, jamais prise par qui est debout")
	# … mais assise du même côté, elle la voit.
	var seated := lab_in("salle_a_manger", {"stations": ["assise"]})
	seated.dog_pos = south
	seated.mouth = sim.mouth.duplicate()
	check(seated.mom_low() and not seated.dog_hidden(), "assise, Maman voit sous la table de son côté")
	force_look(seated)
	run(seated, 0.3)
	check(seated.caught_count == 1, "prise de son côté")
	# Les pattes sur la table, jamais cachée.
	var up := lab_in("salle_a_manger", {"stations": ["buffet"]})
	at(up, "table_nord")
	put(up, Sim.Size.BIG, "table_nord")
	run(up, 0.3, Vector2.ZERO, true)
	check(up.paws_up() and not up.dog_hidden(), "les pattes sur la table, visible")


## Derrière le divan : Papa assis ne voit pas ce qui est juste derrière lui.
func test_derriere_le_divan() -> void:
	var m: RoomMap = grids("salon")[0]
	var papa: Vector2 = m.stations.divan_papa.pos
	check(m.hidden(papa, Vector2(0.1, 0.3)), "juste derrière le divan : cachée")
	check(not m.hidden(papa, Vector2(0.15, 1.9)), "devant le divan : visible")
	check(not m.hidden(papa, Vector2(1.45, 1.8)), "à côté du divan : visible")
	var sim := lab_in("salon", {"watcher": "papa", "stations": ["divan_papa"]})
	check(sim.watcher == "papa" and sim.mom_low(), "Papa surveille, assis")
	check(sim.people_circles().is_empty(), "assis, il n'est pas un obstacle")
	sim.dog_pos = Vector2(0.1, 0.3)
	sim.mouth = {"id": 99, "size": 2, "points": 150, "eat_left": 999.0, "spot": "", "pos": Vector2.ZERO}
	force_look(sim)
	run(sim, 0.5)
	check(sim.caught_count == 0, "cachée derrière le divan pendant qu'il regarde")


## Sur la table basse, on attrape le nez tendu : plus vite, et jamais cachée.
func test_table_basse() -> void:
	var sim := lab_in("salon", {"watcher": "papa", "stations": ["divan_papa"]})
	at(sim, "table_basse_nord")
	var item := put(sim, Sim.Size.SMALL, "table_basse_nord")
	check(is_equal_approx(sim.grab_time(item), Sim.GRAB_TIMES[Sim.Size.SMALL] * Sim.LOW_GRAB), "plus vite")
	run(sim, 0.3, Vector2.ZERO, true)
	check(sim.dog_state == Sim.Dog.REACHING and sim.paws_up() and not sim.dog_hidden(), "le nez tendu, visible")
	run(sim, Sim.GRAB_TIMES[Sim.Size.SMALL] * Sim.LOW_GRAB - 0.2, Vector2.ZERO, true)
	check(not sim.mouth.is_empty(), "attrapé avant le temps d'un comptoir")


## Papa surveille du divan ; un but est une très longue fenêtre, mais soudaine.
func test_papa_surveille() -> void:
	var sim := lab_in("salon", {"watcher": "papa", "stations": ["divan_papa"], "surprise_chance": 1.0,
		"surprise": {"activity": "but"}, "feint_chance": 0.0})
	sim.time = 20.0
	sim.mom_state = Sim.Mom.TURN_BACK
	sim._set_timer(0.01)
	run(sim, 0.05)
	check(sim.activity == "but" and sim.station == "divan_papa", "il fête le but, sans bouger")
	check(sim.mom_left > 5.0, "une très longue fenêtre (%.1f s)" % sim.mom_left)


## Maman part à la cuisine : on ne la voit plus, et son retour s'annonce toujours.
func test_maman_sort_et_revient() -> void:
	var sim := lab_in("salle_a_manger", {"stations": ["servir", "cuisine"], "feint_chance": 0.0, "round_chance": 0.0,
		"surprise_chance": 0.0, "serve": true, "spawn": [9999.0, 9999.0], "max_items": 6})
	sim._start_walk("cuisine", "cuisine")
	var out := false
	for i in 900:
		sim.step(DT, Vector2.ZERO, false)
		if sim.mom_out:
			out = true
			break
	check(out and types(sim).has("out"), "elle sort par la porte")
	check(sim.people_circles().is_empty() and not sim.watching(), "sortie, elle ne voit rien et ne gêne pas")
	at(sim, "table_est")
	put(sim, Sim.Size.SMALL, "table_est")
	sim.mom_left = 0.01
	run(sim, 0.05)
	check(sim.mom_state == Sim.Mom.HINT and sim.hint_kind == "retour" and sim.warning(), "son retour s'annonce")
	var start := sim.time
	while sim.mom_state == Sim.Mom.HINT:
		sim.step(DT, Vector2.ZERO, false)
	check(sim.time - start >= float(sim.level.hint_min) + Sim.RETURN_EXTRA - DT, "au moins l'indice minimal")
	check(sim.mom_state == Sim.Mom.TURN and not sim.mom_out and sim.mom_pos == sim.map.mom_door, "la voilà dans la porte")
	check(types(sim).has("back_in"), "événement d'entrée")
	while sim.mom_state != Sim.Mom.WALK:
		sim.step(DT, Vector2.ZERO, false)
	var served := false
	for i in 900:
		sim.step(DT, Vector2.ZERO, false)
		served = served or types(sim).has("served")
		if sim.mom_state == Sim.Mom.BUSY:
			break
	check(sim.station == "servir" and served, "elle entre et pose un plat")
	# La visite qui l'appelle la fait revenir de la cuisine.
	var called := lab_in("salle_a_manger", {"stations": ["servir", "cuisine"], "feint_chance": 0.0,
		"seated": [{"who": "tante", "seat": "nord_est", "role": "temoin"}]})
	called._start_walk("cuisine", "cuisine")
	for i in 900:
		called.step(DT, Vector2.ZERO, false)
		if called.mom_out:
			break
	called.mom_left = 9999.0
	var guest: Dictionary = called.seated[0]
	guest.state = "regarde"
	guest.t = 99.0
	at(called, "table_nord")
	put(called, Sim.Size.BIG, "table_nord")
	run(called, 1.2, Vector2.ZERO, true)
	check(called.mom_state == Sim.Mom.HINT and called.hint_kind == "retour", "appelée, elle revient (annoncée)")


## Dans le noir, on ne voit pas loin, sauf aux scènes claires ; la lumière ne monte pas pendant un regard.
func test_portee_dans_le_noir() -> void:
	var sim := lab_in("salon", {"stations": ["divan_maman"], "dark": {"near": 1.4, "far": 4.0}})
	sim.tv_light = 0.0
	sim._tv_target = 0.0
	sim._tv_left = 999.0
	check(is_equal_approx(sim.sight_range(), 1.4), "portée dans une scène sombre")
	sim.dog_pos = Vector2(-1.2, 3.1)
	sim.mouth = {"id": 99, "size": 2, "points": 150, "eat_left": 999.0, "spot": "", "pos": Vector2.ZERO}
	check(sim.dog_pos.distance_to(sim.mom_pos) > 1.4 and sim.dog_hidden(), "loin, dans le noir : cachée")
	sim._tv_target = 1.0
	force_look(sim)
	run(sim, 1.0)
	check(sim.tv_light == 0.0 and sim.caught_count == 0, "la lumière ne monte pas pendant qu'elle regarde")
	sim.mom_state = Sim.Mom.BUSY
	sim.mom_left = 9999.0
	run(sim, 1.0)
	check(sim.tv_light > 0.99 and is_equal_approx(sim.sight_range(), 4.0) and not sim.dog_hidden(), "scène claire : vue")
	# Pendant l'indice non plus : ce qu'on voyait en se décidant reste vrai.
	var hint := lab_in("salon", {"stations": ["divan_maman"], "dark": {"near": 1.4, "far": 4.0}, "feint_chance": 0.0})
	hint.tv_light = 0.0
	hint._tv_target = 1.0
	hint._tv_left = 999.0
	hint._hint("real", 0.6)
	run(hint, 0.5)
	check(hint.mom_state == Sim.Mom.HINT and hint.tv_light == 0.0, "la lumière ne monte pas pendant l'indice")
	# Les pattes en l'air, jamais cachée, même dans le noir.
	var up := lab_in("salon", {"stations": ["divan_maman"], "dark": {"near": 0.2, "far": 0.3}})
	at(up, "piano")
	put(up, Sim.Size.BIG, "piano")
	run(up, 0.3, Vector2.ZERO, true)
	check(up.paws_up() and not up.dog_hidden(), "dressée dans le noir : visible")


## Charlotte glisse des morceaux sous la table, de son côté ; si Maman la voit faire, c'est la chicane.
func test_charlotte_complice() -> void:
	var sim := lab_in("salle_a_manger", {"stations": ["servir"],
		"seated": [{"who": "charlotte", "seat": "sud_est", "role": "complice"}]})
	var slipped: Dictionary = {}
	for i in 1200:
		sim.step(DT, Vector2.ZERO, false)
		for e in sim.drain_events():
			if e.type == "slip":
				slipped = e.item
		if not slipped.is_empty():
			break
	var table: Rect2 = sim.map.hides[0].rect
	check(not slipped.is_empty() and table.has_point(slipped.pos) and slipped.pos.y > table.get_center().y,
		"un morceau sous la table, du côté de Charlotte")
	check(sim.map.hidden(sim.mom_pos, slipped.pos), "un morceau peu risqué : caché de qui est debout")
	var charlotte: Dictionary = sim.seated[0]
	charlotte.state = "slip"
	charlotte.t = 1.0
	sim.mom_state = Sim.Mom.TURN
	sim._set_timer(0.02)
	at(sim, "table_est")
	put(sim, Sim.Size.BIG, "table_est")
	sim.dog_state = Sim.Dog.REACHING
	sim.reach_item = sim.food.back()
	var events := []
	for i in 10:
		sim.step(DT, Vector2.ZERO, true)
		events.append_array(types(sim))
	check(events.has("busted") and sim.activity == "chicane" and sim.chicane_with == "charlotte", "la chicane")
	check(sim.caught_count == 0 and not sim.watching(), "Maman ne regarde plus que Charlotte")
	var next_look := false
	var hinted := false
	for i in 1200:
		sim.step(DT, Vector2.ZERO, false)
		for e in sim.drain_events():
			if e.type == "hint" and e.kind != "feint":
				hinted = true
			if e.type == "look":
				next_look = true
		if next_look:
			break
	check(next_look and hinted, "après la chicane, un indice avant de regarder")


## La visite assise ne voit que son côté de la table, et seulement quand elle ne jase pas.
func test_visite_a_table() -> void:
	var sim := lab_in("salle_a_manger", {"stations": ["buffet"],
		"seated": [{"who": "tante", "seat": "nord_est", "role": "temoin"}]})
	var guest: Dictionary = sim.seated[0]
	guest.state = "jase"
	guest.t = 99.0
	at(sim, "table_nord")
	put(sim, Sim.Size.TREASURE, "table_nord")
	run(sim, 1.5, Vector2.ZERO, true)
	check(not types(sim).has("snitch"), "elle jase : elle ne voit rien")
	var far := lab_in("salle_a_manger", {"stations": ["buffet"],
		"seated": [{"who": "tante", "seat": "nord_est", "role": "temoin"}]})
	far.seated[0].state = "regarde"
	far.seated[0].t = 99.0
	at(far, "table_ouest")
	put(far, Sim.Size.TREASURE, "table_ouest")
	run(far, 1.5, Vector2.ZERO, true)
	check(not types(far).has("snitch"), "l'autre bout de la table : elle ne voit pas")
	var near := lab_in("salle_a_manger", {"stations": ["buffet"],
		"seated": [{"who": "tante", "seat": "nord_est", "role": "temoin"}]})
	near.seated[0].state = "regarde"
	near.seated[0].t = 99.0
	at(near, "table_nord")
	put(near, Sim.Size.TREASURE, "table_nord")
	run(near, 0.4, Vector2.ZERO, true)
	var first := types(near)
	check(first.has("snitch") and not first.has("snitch_call"), "« Hon ! » d'abord")
	run(near, 0.7, Vector2.ZERO, true)
	check(types(near).has("snitch_call") and near.mom_state == Sim.Mom.HINT and near.caught_count == 0,
		"puis elle appelle : un vrai indice, le temps de redescendre")


## La visite qui circule va d'un endroit à l'autre sans traverser les meubles, et voit ce qui se passe.
func test_visite_qui_circule() -> void:
	var sim := lab_in("fetes", {"stations": ["servir"], "walkers": [{"who": "oncle", "start": "entree",
		"points": ["entree", "lampe", "milieu", "salon_ouest", "salon_est", "sdm_sud"]}]})
	var bad := 0
	var walked := 0.0
	var last: Vector2 = sim.walkers[0].pos
	for i in 6000:
		sim.step(DT, Vector2.ZERO, false)
		var w: Dictionary = sim.walkers[0]
		walked += w.pos.distance_to(last)
		last = w.pos
		if not sim.map.is_free(w.pos, Sim.HELPER_RADIUS - 0.05):
			bad += 1
	check(walked > 5.0 and bad == 0, "elle circule (%.1f m) sans traverser les meubles (%d)" % [walked, bad])


## En pleine chicane, Maman n'entend pas la visite : la chicane va au bout.
func test_la_visite_ne_coupe_pas_la_chicane() -> void:
	var sim := lab_in("salle_a_manger", {"stations": ["buffet"],
		"seated": [{"who": "charlotte", "seat": "sud_est", "role": "complice"},
			{"who": "oncle", "seat": "nord_est", "role": "temoin"}]})
	sim._bust(sim.seated[0])
	var guest: Dictionary = sim.seated[1]
	guest.state = "regarde"
	guest.t = 99.0
	at(sim, "table_nord")
	put(sim, Sim.Size.BIG, "table_nord")
	var heard := false
	for i in int((Sim.ARGUE_TIME - 0.3) / DT):
		sim.step(DT, Vector2.ZERO, i < 60)
		heard = heard or types(sim).has("snitch_call")
	check(heard and sim.activity == "chicane" and sim.mom_state == Sim.Mom.BUSY, "la chicane continue")


## Un niveau mal écrit est refusé avant d'être joué.
func test_niveau_mal_ecrit() -> void:
	var m: RoomMap = grids("fetes")[0]
	var level := Levels.load_level(15)
	level.walkers = [{"who": "tante", "start": "entree", "points": ["entree"]}]
	level.surprise = {"activity": "but "}
	level.dark = {"near": 2.0}
	level.seated = [{"who": "ginette", "seat": "sud_est", "role": "complice"}]
	var problems := Levels.validate(level, m)
	check(problems.size() >= 4, "problèmes trouvés : %s" % ", ".join(problems))
	var twice := Levels.load_level(10)
	twice.seated = [{"who": "papa", "seat": "sud_ouest", "role": "decor"}]
	twice.plat = "sushi"
	var found := Levels.validate(twice, grids("salle_a_manger")[0])
	check(found.has("place prise deux fois : sud_ouest") and found.has("plat inconnu : sushi"), "places et plat : %s" % str(found))


## Maman (et la visite qui circule) font le tour de la table : debout, on ne passe pas au travers. La chienne, elle,
## passe encore dessous.
func test_maman_contourne_la_table() -> void:
	for piece: String in ["salle_a_manger", "fetes"]:
		var g := grids(piece)
		var m: RoomMap = g[0]
		var table: Rect2 = m.hides[0].rect
		var mom_grid: Nav = g[2]
		for pair: Array in [["servir", "buffet"], ["buffet", "servir"], ["assise", "buffet"], ["servir", "assise"]]:
			var path := mom_grid.path(m.stations[pair[0]].pos, m.stations[pair[1]].pos)
			check(not path.is_empty(), "%s : chemin %s → %s" % [piece, pair[0], pair[1]])
			var here: Vector2 = m.stations[pair[0]].pos
			for p in path:
				for k in 10:
					check(not table.has_point(here.lerp(p, k / 10.0)), "%s : %s → %s traverse la table" % [piece, pair[0], pair[1]])
				here = p
		var dog_grid: Nav = g[1]
		check(not dog_grid.grid.is_point_solid(dog_grid.cell(table.get_center())), piece + " : la chienne passe sous la table")
	# Dans la cuisine, rien ne change.
	var kitchen := Sim.mom_grid(map)
	for x in mom_nav.grid.region.size.x:
		for y in mom_nav.grid.region.size.y:
			var c := Vector2i(x, y)
			if kitchen.grid.is_point_solid(c) != mom_nav.grid.is_point_solid(c):
				check(false, "la grille de Maman de la cuisine a changé")
				return


## Les conversations à table ne trompent jamais : la visite ne parle que lorsqu'elle jase, Charlotte pas pendant
## qu'elle glisse un morceau ; les répliques sont courtes et leurs personnes connues.
func test_conversations_a_table() -> void:
	var sim := game(12, 5)
	var talk := TableTalk.new(sim, null, null, RandomNumberGenerator.new())
	var tante: Dictionary = sim.seated[0]
	tante.state = "regarde"
	tante.t = 9.0
	check(not talk._free("tante"), "la visite qui regarde ne parle pas")
	tante.state = "jase"
	check(talk._free("tante") and talk._free("papa"), "la visite qui jase et Papa parlent")
	tante.snitch = 0.3
	check(not talk._free("tante"), "la visite qui voit Blanche ne jase plus")
	tante.snitch = 0.0
	tante.t = 0.5
	var free := talk._free_people()
	for i in Texts.TABLE_TALK.size():
		var t: Dictionary = Texts.TABLE_TALK[i]
		if TableTalk._speakers(t).has("tante"):
			check(not talk._fits(t, free), "pas de conversation qui déborde de son temps de jaser : %d" % i)
	# Quelqu'un d'absent : la conversation ne part pas, sans erreur.
	check(not talk._fits({"sur": [], "lines": [["papa", "Allo"], ["charlotte", "Allo"]]}, {"papa": Vector2.ZERO}),
		"personne absente")
	var people := ["papa", "maman", "charlotte", "tante", "oncle"]
	for t: Dictionary in Texts.TABLE_TALK:
		var guests := 0
		for line: Array in t.lines:
			check(people.has(line[0]), "personne inconnue : " + str(line[0]))
			check(str(line[1]).length() <= 56, "réplique trop longue : " + str(line[1]))
			if line[0] in ["tante", "oncle"]:
				guests += 1
		check(guests == 0 or t.lines.size() <= 3 or "noel" in t.sur, "avec la visite assise, trois répliques au plus")
	var kid := game(11, 5)
	var kid_talk := TableTalk.new(kid, null, null, RandomNumberGenerator.new())
	var charlotte: Dictionary = kid.seated[0]
	charlotte.state = "slip"
	check(not kid_talk._free("charlotte"), "Charlotte ne jase pas en glissant un morceau")
	# Au film, rien que les conversations du film ; au party, celles du party.
	for id: int in [14, 15]:
		var away := game(id, 5)
		var away_talk := TableTalk.new(away, null, null, RandomNumberGenerator.new())
		var everyone := {"papa": Vector2.ZERO, "charlotte": Vector2.ZERO, "maman": Vector2.ZERO, "tante": Vector2.ZERO,
			"oncle": Vector2.ZERO}
		for t: Dictionary in Texts.TABLE_TALK:
			if away_talk._fits(t, everyone):
				check(t.sur.has(away.level.moment), "mission %d : conversation hors de propos : %s" % [id, t.lines[0][1]])
	# Les règles n'en savent rien : la même graine donne la même partie.
	var a := game(12, 9)
	var b := game(12, 9)
	var a_talk := TableTalk.new(a, null, null, RandomNumberGenerator.new())
	a_talk._free_people()
	run(a, 20.0)
	run(b, 20.0)
	check(a.score == b.score and a.mom_pos == b.mom_pos and a.time == b.time, "les conversations ne touchent pas au hasard")


## Au party, assise au divan, Maman ne lance pas le tour de la table à l'autre bout de la maison.
func test_pas_de_tour_loin_de_la_table() -> void:
	var sim := lab_in("fetes", {"stations": ["divan_maman"], "round_chance": 1.0, "feint_chance": 0.0})
	sim.unseen_time = 9.0
	sim.mom_left = 0.01
	run(sim, 0.05)
	check(sim.mom_state == Sim.Mom.HINT and sim.hint_kind == "real", "un vrai indice, pas un tour : %s" % sim.hint_kind)
	var near := lab_in("salle_a_manger", {"stations": ["buffet"], "round_chance": 1.0, "feint_chance": 0.0})
	near.mom_left = 0.01
	run(near, 0.05)
	check(near.hint_kind == "round", "près de la table, le tour a lieu")


## Les chaises grincent quand on fonce dedans, comme le tabouret.
func test_chaise_grince() -> void:
	var sim := lab_in("salle_a_manger", {"stations": ["buffet"], "noise": true})
	var chair: Vector2 = sim.map.stools[0].pos
	sim.dog_pos = chair + Vector2(-0.6, 0.0)
	run(sim, 0.6, Vector2.RIGHT)
	var noisy := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "noise")
	check(noisy.size() == 1 and noisy[0].what == "chaise" and noisy[0].index == 0, "la chaise grince")


## Une partie qui avait fini la cuisine ouvre la suite.
func test_deblocage_apres_la_cuisine() -> void:
	write_tmp("{\"version\":1,\"unlocked\":8,\"stars\":{\"8\":1},\"best\":{\"8\":1200}}")
	var s := SaveData.new(TMP)
	check(s.unlocked == mini(Levels.COUNT, 9), "la mission suivante est ouverte (%d)" % s.unlocked)


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
	# les plats que Maman tient en servant
	for dish: String in PersonView.DISHES:
		check(foods.find_child(PersonView.DISHES[dish], true, false) is MeshInstance3D, "plat tenu : " + dish)
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


## Le double salon a toutes les parties que les plans et la scène nomment.
func test_double_salon_complet() -> void:
	var model: Node = (load("res://art/models/double_salon.glb") as PackedScene).instantiate()
	var names := ["SalleAManger", "Salon", "Lampe", "Plancher"]
	for piece: String in ["salle_a_manger", "salon", "fetes"]:
		var m: RoomMap = grids(piece)[0]
		names.append_array(m.data.get("cache", []))
		names.append_array(m.data.get("montre", {}).keys())
		names.append_array(m.data.get("cache_au", {}).keys())
		names.append(str(m.data.get("vue", "")))
		for s in m.stools:
			names.append("Chaise_" + str(s.name))
			names.append("Couvert_" + str(s.name))
	for part: String in names:
		check(model.get_node_or_null(part) != null, "double salon : " + part)
	# Le plancher des pièces et celui du corridor se touchent sans se chevaucher : deux surfaces l'une sur l'autre
	# clignotaient sous le cadre de la porte.
	var room_floor := (model.get_node("Plancher") as MeshInstance3D)
	var hall := (model.get_node("Corridor") as MeshInstance3D)
	var a := room_floor.transform * room_floor.mesh.get_aabb()
	var b := hall.transform * hall.mesh.get_aabb()
	check(a.position.x >= b.end.x - 0.001, "les planchers se chevauchent de %.3f m" % (b.end.x - a.position.x))
	model.free()


func test_taille_de_blanche() -> void:
	# Le jeu place la gueule d'après la taille du modèle : le script Blender doit dire la même.
	var script := FileAccess.get_file_as_string("res://tools/blender/dog.py")
	check(script.contains("\nTAILLE = %s\n" % str(DogView.SIZE)), "DogView.SIZE diffère de TAILLE (dog.py)")


func test_tous_les_sons_existent() -> void:
	var regex := RegEx.new()
	regex.compile("Sound\\.play\\(\"(\\w+)\"|\\[\"(couteau|brasse|eau|pas|foule)\", [0-9.]+\\]|\"(tombe|fracas|miette|prise|combo|avale|tour|alerte|victoire|rate|chaise)\"")
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
	for piece: String in PIECES:
		var m: RoomMap = grids(piece)[0]
		for id: String in m.stations:
			check(Sim.ACTIVITY_WINDOWS.has(m.stations[id].activity), "%s : poste sans durée : %s" % [piece, id])
