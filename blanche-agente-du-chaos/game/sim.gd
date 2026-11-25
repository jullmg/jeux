class_name Sim
extends RefCounted
## Toutes les règles d'un niveau, sans affichage : Blanche, Maman, la nourriture, les aides et le pointage.
## On appelle step() avec les commandes ; l'affichage lit l'état et la liste d'événements.

enum Dog { FREE, REACHING, LOWERING, TO_CORNER, IN_CORNER }
## WALK : elle change de place sans surveiller. ROUND : le tour de l'îlot, les yeux ouverts, toujours annoncé.
enum Mom { BUSY, HINT, TURN, LOOK, TURN_BACK, SCOLD, WALK, ROUND }
enum Size { CRUMB, SMALL, BIG, TREASURE }

const DOG_RADIUS := 0.2
const MOM_RADIUS := 0.23
const HELPER_RADIUS := 0.2
const DOG_SPEED := 1.7
const CARRY_SPEED := 1.4
const SULK_SPEED := 1.35
const REACH_DIST := 0.34
const FLOOR_REACH := 0.36
const CRUMB_REACH := 0.24
const DESCEND_TIME := 0.2
const CATCH_GRACE := 0.08
const TURN_TIME := 0.25
const TURN_BACK_TIME := 0.3
const SCOLD_TIME := 1.6
const FEINT_TIME := 0.6
const MOM_WALK := 1.05
const ROUND_WALK := 0.85
const NEAR_MOM := 1.05
const GRAB_TIMES := [0.3, 1.0, 2.0, 3.5]
const EAT_TIMES := [0.0, 0.5, 1.5, 3.0]
const BASE_POINTS := [10, 50, 150, 500]
## Les noms des tailles dans les données des niveaux.
const SIZE_KEYS := ["crumb", "small", "big", "treasure"]
## Ce qui rend Maman méfiante d'un coup (la jauge va de 0 à 1) : un morceau qui disparaît, selon sa taille, un bruit,
## Blanche prise sur le fait.
const WARY_FOOD := [0.0, 0.06, 0.13, 0.24]
const WARY_NOISE := 0.18
const WARY_CAUGHT := 0.3
## La part des fenêtres que la méfiance retranche, quand la jauge est pleine.
const WARY_WINDOW := 0.3
## Au bout de combien de temps un trésor perdu revient sur un meuble.
const TREASURE_RETURN := 12.0
## Durée d'une fenêtre selon ce que fait Maman (secondes, avant les ajustements).
const ACTIVITY_WINDOWS := {
	"brasser": [3.5, 5.0], "four": [3.0, 4.5], "couper": [2.2, 3.2], "laver": [3.2, 4.8], "frigo": [5.0, 6.5],
	"telephone": [6.0, 8.0], "ilot": [2.8, 4.0], "surprise": [7.0, 9.0], "charlotte": [6.0, 7.5],
}
## Le tour de l'îlot (points au sol, dans le sens des aiguilles).
const RING := [Vector2(0.72, -1.14), Vector2(0.76, -0.2), Vector2(0.74, 0.95), Vector2(-0.1, 1.06),
	Vector2(-1.02, 0.9), Vector2(-1.1, -0.1), Vector2(-0.98, -1.14), Vector2(-0.1, -1.15)]
const PAPA_PATH := [Vector2(-1.0, 1.35), Vector2(0.0, 1.28), Vector2(0.86, 0.98), Vector2(0.86, -0.1),
	Vector2(0.86, 0.98), Vector2(0.0, 1.28), Vector2(-1.0, 1.35)]

var map: KitchenMap
var level: Dictionary
var nav: Nav
var mom_nav: Nav
var rng := RandomNumberGenerator.new()
var events: Array[Dictionary] = []

var time := 0.0
var time_left := 0.0
var over := false
## Réglage d'accessibilité : indices plus longs.
var hint_bonus := 0.0

var dog_pos: Vector2
var dog_dir: Vector2
var dog_state := Dog.FREE
var dog_moving := false
var dog_still_time := 0.0
var reach_item: Dictionary = {}
var reach_progress := 0.0
var lower_left := 0.0
var mouth: Dictionary = {}
var corner_path := PackedVector2Array()
var corner_left := 0.0
var _grab_was := false
var _grab_used := false

var mom_pos: Vector2
var mom_dir: Vector2
var mom_state := Mom.BUSY
var mom_left := 0.0
var mom_len := 1.0
var station := ""
var activity := ""
var hint_kind := "real"
var feinted := false
var mom_path := PackedVector2Array()
## Ce qu'elle fait en arrivant à son nouveau poste.
var walk_activity := ""
var walk_speed := MOM_WALK
var round_points := PackedVector2Array()
var unseen_time := 0.0
var _caught_timer := 0.0

var food: Array[Dictionary] = []
var _next_id := 1
var spawn_left := 0.0
## Quand le trésor doit apparaître (ou réapparaître) ; -1 : rien d'attendu.
var treasure_due := -1.0
var crumb_left := 1.5

var helpers: Array[Dictionary] = []
var helper_left := 0.0
var stool_cool := 0.0

var score := 0
var streak := 0
var suspicion := 0.0
var caught_count := 0
var eaten := [0, 0, 0, 0]


func _init(map_: KitchenMap, level_: Dictionary, seed_ := 1, nav_: Nav = null, mom_nav_: Nav = null) -> void:
	map = map_
	level = level_
	nav = nav_ if nav_ != null else dog_grid(map)
	mom_nav = mom_nav_ if mom_nav_ != null else mom_grid(map)
	rng.seed = seed_
	time_left = level.duration
	treasure_due = float(level.duration) * float(level.treasure_at)
	dog_pos = map.corner
	dog_dir = map.corner_face
	station = level.stations[0]
	var st: Dictionary = map.stations[station]
	mom_pos = st.pos
	mom_dir = st.face
	_enter_busy(st.activity, 1.5)
	spawn_left = _rand(level.spawn)
	helper_left = rng.randf_range(12.0, 18.0)
	var initial := mini(3, int(level.max_items))
	for i in initial:
		_spawn_food(Size.SMALL if i == 0 else -1)


## Les grilles de déplacement de Blanche et de Maman (à partager entre les parties).
static func dog_grid(map_: KitchenMap) -> Nav:
	return Nav.new(map_, DOG_RADIUS - 0.01)


static func mom_grid(map_: KitchenMap) -> Nav:
	return Nav.new(map_, MOM_RADIUS - 0.02)


# ------------------------------------------------------------------ lecture

func watching() -> bool:
	return mom_state == Mom.LOOK or mom_state == Mom.ROUND


## Un vrai indice (pas une feinte) : elle va se retourner ou faire le tour.
func warning() -> bool:
	return mom_state == Mom.HINT and hint_kind != "feint"


func snitching() -> bool:
	return helpers.any(func(h: Dictionary) -> bool: return h.snitch > 0.0)


## En route vers le coin, ou assise à y purger sa peine.
func punished() -> bool:
	return dog_state == Dog.TO_CORNER or dog_state == Dog.IN_CORNER


func paws_up() -> bool:
	return dog_state == Dog.REACHING or dog_state == Dog.LOWERING


## Cachée derrière l'îlot, vue de là où est Maman. Jamais pendant une prise.
func dog_hidden(viewer := Vector2.INF, at_island := false) -> bool:
	if paws_up():
		return false
	if viewer == Vector2.INF:
		viewer = mom_pos
		at_island = mom_at_island()
	return map.hidden_by_island(viewer, dog_pos, at_island)


func mom_at_island() -> bool:
	return station == "ilot" and mom_pos.distance_to(map.stations.ilot.pos) < 0.2


## Ce qui vaudrait un « AU COIN ! » si Maman regardait.
func dog_infraction() -> bool:
	if punished():
		return false
	if paws_up():
		return true
	return not mouth.is_empty() and not dog_hidden()


func at_corner() -> bool:
	return dog_pos.distance_to(map.corner) < 0.32


func multiplier() -> int:
	if streak >= 6:
		return 3
	if streak >= 3:
		return 2
	return 1


func stars() -> int:
	var n := 0
	for threshold: float in level.stars:
		if score >= threshold:
			n += 1
	return n


func drain_events() -> Array[Dictionary]:
	var out := events.duplicate()
	events.clear()
	return out


## Où se tenir pour prendre un morceau.
func stand_of(item: Dictionary) -> Vector2:
	return item.pos if item.spot == "" else map.spots[item.spot].stand


## La durée d'une fenêtre de ce niveau, raccourcie par le soupçon.
func scaled_window(seconds: float) -> float:
	return seconds * float(level.window_mult) * (1.0 - WARY_WINDOW * suspicion)


## Les personnes présentes, comme cercles [centre, rayon].
func people_circles() -> Array:
	var out: Array = [[mom_pos, MOM_RADIUS]]
	for h in helpers:
		out.append([h.pos, HELPER_RADIUS])
	return out


## Le morceau que Blanche peut attraper d'ici ({} s'il n'y en a pas).
func reachable_item() -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for item in food:
		var d := dog_pos.distance_to(stand_of(item))
		if d > (FLOOR_REACH if item.spot == "" else REACH_DIST):
			continue
		if d < best_d:
			best_d = d
			best = item
	return best


func food_name(item: Dictionary) -> String:
	return level.foods[SIZE_KEYS[item.size]][1]


# ------------------------------------------------------------------ avancer

func step(dt: float, move: Vector2, grab: bool) -> void:
	if over:
		return
	time += dt
	time_left -= dt
	var pressed := grab and not _grab_was
	_grab_was = grab
	if not grab:
		_grab_used = false
	_step_dog(dt, move, grab, pressed)
	_step_mom(dt)
	_step_helpers(dt)
	_step_food(dt)
	_step_suspicion(dt)
	_check_caught(dt)
	if time_left <= 0.0:
		time_left = 0.0
		over = true
		_emit("meal_ready", {"stars": stars()})


func _step_dog(dt: float, move: Vector2, grab: bool, pressed: bool) -> void:
	dog_moving = false
	match dog_state:
		Dog.TO_CORNER:
			_walk_to_corner(dt)
		Dog.IN_CORNER:
			corner_left -= dt
			if corner_left <= 0.0:
				dog_state = Dog.FREE
				_emit("freed")
		Dog.REACHING:
			if not grab:
				_lower()
				_emit("released")
			else:
				reach_progress += dt
				if reach_progress >= GRAB_TIMES[reach_item.size]:
					_take(reach_item)
					_lower()
					_grab_used = true
		Dog.LOWERING:
			if pressed and not mouth.is_empty():
				_drop()
			lower_left -= dt
			if lower_left <= 0.0:
				dog_state = Dog.FREE
		Dog.FREE:
			_move_dog(dt, move)
			if not mouth.is_empty():
				if pressed:
					_drop()
				else:
					mouth.eat_left -= dt * (0.35 if dog_moving else 1.0)
					if mouth.eat_left <= 0.0:
						_score(mouth)
						mouth = {}
			elif grab and not _grab_used and (pressed or not dog_moving):
				var item := reachable_item()
				if not item.is_empty():
					if item.spot == "":
						_take(item)
						_grab_used = true
					else:
						dog_state = Dog.REACHING
						reach_item = item
						reach_progress = 0.0
						dog_dir = (map.spots[item.spot].food - dog_pos).normalized()
						dog_moving = false
						_emit("reach", {"item": item})
	dog_still_time = 0.0 if dog_moving or paws_up() else dog_still_time + dt


func _move_dog(dt: float, move: Vector2) -> void:
	if move.length() < 0.1:
		return
	var speed := CARRY_SPEED if not mouth.is_empty() else DOG_SPEED
	var wanted := move.limit_length(1.0) * speed * dt
	var before := dog_pos
	var circles := _body_circles(dog_pos, move)
	dog_pos = map.resolve(dog_pos + wanted, DOG_RADIUS, circles)
	dog_dir = move.normalized()
	dog_moving = dog_pos.distance_to(before) > wanted.length() * 0.15
	if bool(level.noise) and stool_cool <= 0.0 and dog_pos.distance_to(map.stool_pos) < DOG_RADIUS + map.stool_r + 0.006:
		if (map.stool_pos - before).normalized().dot(move.normalized()) > 0.6:
			stool_cool = 4.0
			_noise(map.stool_pos, "tabouret")
	for i in range(food.size() - 1, -1, -1):
		var item := food[i]
		if item.spot == "" and item.size == Size.CRUMB and mouth.is_empty() and dog_pos.distance_to(item.pos) < CRUMB_REACH:
			food.remove_at(i)
			_emit("grabbed", {"item": item})
			_score(item)


## Les corps qui bloquent Blanche. Si quelqu'un lui a marché dessus, elle peut toujours se glisser dehors.
func _body_circles(from: Vector2, move: Vector2) -> Array:
	var circles: Array = [[map.stool_pos, map.stool_r]]
	for c: Array in people_circles():
		var away: Vector2 = from - c[0]
		if away.length() < DOG_RADIUS + c[1] - 0.01 and move.normalized().dot(away.normalized()) > -0.35:
			continue
		circles.append(c)
	return circles


func _lower() -> void:
	dog_state = Dog.LOWERING
	lower_left = DESCEND_TIME
	reach_item = {}
	reach_progress = 0.0


func _take(item: Dictionary) -> void:
	var noisy: bool = item.spot != "" and item.size >= Size.SMALL and level.noisy_spots.has(item.spot)
	food.erase(item)
	_emit("grabbed", {"item": item})
	if item.size > Size.CRUMB:
		_wary(WARY_FOOD[item.size], "food")
	if item.size == Size.CRUMB:
		_score(item)
	else:
		mouth = item.duplicate()
		mouth.eat_left = EAT_TIMES[item.size]
		mouth.spot = ""
	if noisy:
		_noise(dog_pos, "ustensile")


func _drop() -> void:
	var item := mouth
	mouth = {}
	# Il faut relâcher le bouton avant de reprendre quoi que ce soit.
	_grab_used = true
	var pos := map.resolve(dog_pos + dog_dir * 0.24, 0.06)
	item.pos = pos
	item.spot = ""
	item.erase("eat_left")
	food.append(item)
	# Lâcher coûte le combo : se cacher derrière l'îlot vaut mieux.
	var broke := streak >= 3
	streak = 0
	_emit("dropped", {"item": item, "combo_lost": broke})


func _score(item: Dictionary) -> void:
	if item.size > Size.CRUMB:
		streak += 1
	var mult := multiplier()
	var points: int = item.points * mult
	score += points
	eaten[item.size] += 1
	_emit("ate", {"item": item, "points": points, "mult": mult})


func _walk_to_corner(dt: float) -> void:
	if corner_path.is_empty() or dog_pos.distance_to(map.corner) < 0.06:
		dog_pos = map.corner
		dog_dir = map.corner_face
		dog_state = Dog.IN_CORNER
		corner_left = 2.0 + 0.5 * minf(caught_count - 1, 4)
		_emit("corner_arrive")
		return
	var step_ := _advance(dog_pos, dog_dir, corner_path, SULK_SPEED * dt)
	dog_pos = step_.pos
	dog_dir = step_.dir
	corner_path = step_.path
	dog_moving = true


## Avance de `length` le long d'un chemin : nouvelle position, direction, chemin restant et points franchis.
static func _advance(pos: Vector2, dir: Vector2, path: PackedVector2Array, length: float) -> Dictionary:
	var done := 0
	while length > 0.0 and done < path.size():
		var d := pos.distance_to(path[done])
		if d <= length:
			pos = path[done]
			done += 1
			length -= d
		else:
			dir = (path[done] - pos).normalized()
			pos += dir * length
			length = 0.0
	return {"pos": pos, "dir": dir, "path": path.slice(done), "done": done}


## Personne ne traverse Blanche : on la pousse un peu.
func _nudge_dog(from: Vector2, radius: float) -> void:
	if dog_state == Dog.FREE and dog_pos.distance_to(from) < radius + DOG_RADIUS:
		dog_pos = map.resolve(dog_pos, DOG_RADIUS, [[from, radius], [map.stool_pos, map.stool_r]])


# ------------------------------------------------------------------ Maman

func _step_mom(dt: float) -> void:
	match mom_state:
		Mom.BUSY:
			var drain := 1.0
			if dog_state == Dog.REACHING and dog_pos.distance_to(mom_pos) < NEAR_MOM:
				drain = 1.5
			mom_left -= dt * drain
			if mom_left <= 0.0:
				_end_window()
		Mom.HINT:
			mom_left -= dt
			if mom_left <= 0.0:
				if hint_kind == "feint":
					_emit("feint_end")
					mom_state = Mom.BUSY
					_set_timer(rng.randf_range(1.0, 2.4))
				elif hint_kind == "round":
					_start_round()
				else:
					mom_state = Mom.TURN
					_set_timer(TURN_TIME)
					_emit("turn")
		Mom.TURN:
			mom_left -= dt
			mom_dir = _turned(1.0 - mom_left / mom_len)
			if mom_left <= 0.0:
				mom_state = Mom.LOOK
				_set_timer(_rand(level.look) + suspicion * 0.8)
				mom_dir = _look_dir()
				_emit("look")
		Mom.LOOK:
			mom_left -= dt
			if mom_left <= 0.0:
				mom_state = Mom.TURN_BACK
				_set_timer(TURN_BACK_TIME)
				_emit("turn_back")
		Mom.TURN_BACK:
			mom_left -= dt
			mom_dir = _turned(maxf(0.0, mom_left / mom_len))
			if mom_left <= 0.0:
				_next_activity()
		Mom.SCOLD:
			mom_left -= dt
			mom_dir = (dog_pos - mom_pos).normalized()
			if mom_left <= 0.0:
				var st: Dictionary = map.stations[station]
				if mom_pos.distance_to(st.pos) > 0.15:
					# Elle retourne à ses chaudrons sans regarder : jamais de surveillance sans indice.
					_start_walk(station, st.activity)
				else:
					mom_dir = _look_dir()
					mom_state = Mom.TURN_BACK
					_set_timer(TURN_BACK_TIME)
					_emit("turn_back")
		Mom.WALK:
			if _follow_mom(dt, walk_speed):
				var st: Dictionary = map.stations[station]
				mom_pos = st.pos
				mom_dir = st.face
				_enter_busy(walk_activity)
		Mom.ROUND:
			if _follow_mom(dt, ROUND_WALK):
				_start_walk(station, map.stations[station].activity)


func _end_window() -> void:
	if not feinted and rng.randf() < float(level.feint_chance):
		feinted = true
		_hint("feint", FEINT_TIME)
		return
	var camping := unseen_time > 4.5
	if float(level.round_chance) > 0.0 and (camping or rng.randf() < float(level.round_chance)):
		unseen_time = 0.0
		_hint("round", _hint_time() + 0.35)
		return
	_hint("real", _hint_time())


func _hint_time() -> float:
	return float(level.hint_min) + hint_bonus + rng.randf_range(0.0, 0.25)


func _hint(kind: String, duration: float) -> void:
	hint_kind = kind
	mom_state = Mom.HINT
	_set_timer(duration)
	_emit("hint", {"kind": kind})


func _set_timer(t: float) -> void:
	mom_left = t
	mom_len = t


## La direction où Maman regarde quand elle se retourne.
func _look_dir() -> Vector2:
	var face: Vector2 = map.stations[station].face
	return face if station == "ilot" else -face


func _turned(f: float) -> Vector2:
	var face: Vector2 = map.stations[station].face
	var target := _look_dir()
	if face.is_equal_approx(target):
		return face
	return face.rotated(PI * clampf(f, 0.0, 1.0))


func _start_walk(to: String, what: String, speed := MOM_WALK) -> void:
	station = to
	activity = ""
	walk_activity = what
	walk_speed = speed
	mom_state = Mom.WALK
	mom_path = mom_nav.path(mom_pos, map.stations[station].pos)
	_emit("walk", {"station": station})


func _start_round() -> void:
	var start := 0
	for i in RING.size():
		if mom_pos.distance_to(RING[i]) < mom_pos.distance_to(RING[start]):
			start = i
	var way := 1 if rng.randf() < 0.5 else -1
	var points := rng.randi_range(4, 6)
	mom_path = PackedVector2Array()
	for k in points:
		mom_path.append(RING[posmod(start + k * way, RING.size())])
	mom_state = Mom.ROUND
	activity = ""
	_emit("round")


## Avance le long du chemin ; vrai quand elle est arrivée.
func _follow_mom(dt: float, speed: float) -> bool:
	var step_ := _advance(mom_pos, mom_dir, mom_path, speed * dt)
	mom_pos = step_.pos
	mom_dir = step_.dir
	mom_path = step_.path
	_nudge_dog(mom_pos, MOM_RADIUS)
	return mom_path.is_empty()


func _next_activity() -> void:
	if time > 15.0 and rng.randf() < float(level.surprise_chance):
		var to := "cuisiniere" if level.stations.has("cuisiniere") else str(level.stations[0])
		_emit("surprise")
		if to != station:
			_start_walk(to, "surprise", MOM_WALK * 1.4)
		else:
			mom_dir = map.stations[station].face
			_enter_busy("surprise")
		return
	if level.stations.size() > 1 and rng.randf() < float(level.move_chance):
		var options: Array = level.stations.duplicate()
		options.erase(station)
		var next: String = options[rng.randi_range(0, options.size() - 1)]
		_start_walk(next, map.stations[next].activity)
		return
	var verify := rng.randf() < suspicion * 0.45
	mom_dir = map.stations[station].face
	_enter_busy(map.stations[station].activity)
	if verify:
		_set_timer(rng.randf_range(0.8, 1.5))
		feinted = true


func _enter_busy(what: String, extra := 0.0) -> void:
	activity = what
	walk_activity = ""
	mom_state = Mom.BUSY
	feinted = false
	var span: Array = ACTIVITY_WINDOWS[what]
	var t := scaled_window(rng.randf_range(span[0], span[1]))
	_set_timer(maxf(1.0, t) + extra)
	_emit("busy", {"station": station, "activity": what})


## Un bruit : la fenêtre se referme vite.
func _noise(pos: Vector2, what: String) -> void:
	_wary(WARY_NOISE, "noise")
	_emit("noise", {"pos": pos, "what": what})
	if mom_state == Mom.BUSY:
		mom_left = minf(mom_left, 0.2)
		feinted = true
	elif mom_state == Mom.HINT and hint_kind == "feint":
		_hint("real", _hint_time())


func _check_caught(dt: float) -> void:
	if not watching() or not dog_infraction():
		_caught_timer = 0.0
		return
	_caught_timer += dt
	if _caught_timer < CATCH_GRACE:
		return
	_caught_timer = 0.0
	caught_count += 1
	var lost := mouth
	if not lost.is_empty() and lost.size == Size.TREASURE:
		# Maman le remet sur le comptoir un peu plus tard.
		treasure_due = time + TREASURE_RETURN
	mouth = {}
	reach_item = {}
	reach_progress = 0.0
	streak = 0
	_wary(WARY_CAUGHT, "caught")
	corner_path = nav.path(dog_pos, map.corner, [[mom_pos, MOM_RADIUS]])
	if corner_path.is_empty():
		corner_path = nav.path(dog_pos, map.corner)
	dog_state = Dog.TO_CORNER
	mom_state = Mom.SCOLD
	mom_path = PackedVector2Array()
	_set_timer(SCOLD_TIME)
	_emit("caught", {"lost": lost})


func _wary(amount: float, why: String) -> void:
	suspicion = minf(1.0, suspicion + amount)
	_emit("wary", {"why": why})


## La méfiance retombe avec le temps, plus vite quand Blanche reste sage, surtout dans son coin.
func _step_suspicion(dt: float) -> void:
	var change := -0.013
	var seen := watching() and not dog_hidden()
	if not dog_moving and not paws_up() and mouth.is_empty():
		if at_corner():
			change -= 0.07
		elif seen:
			change -= 0.03
	if seen and not at_corner() and (dog_state == Dog.FREE):
		change += 0.02
	if unseen_time > 3.0 and watching() and dog_hidden():
		change += 0.05
	suspicion = clampf(suspicion + change * dt, 0.0, 1.0)
	if watching() and dog_hidden():
		unseen_time += dt
	elif watching():
		unseen_time = maxf(0.0, unseen_time - dt * 2.0)
	stool_cool -= dt


# ------------------------------------------------------------------ nourriture

func _step_food(dt: float) -> void:
	spawn_left -= dt
	if spawn_left <= 0.0:
		spawn_left = _rand(level.spawn)
		_spawn_food(-1)
	if treasure_due >= 0.0 and time >= treasure_due and _spawn_food(Size.TREASURE):
		treasure_due = -1.0
	if mom_state == Mom.BUSY and activity == "couper":
		crumb_left -= dt
		if crumb_left <= 0.0:
			crumb_left = rng.randf_range(1.2, 2.4)
			_spawn_floor_crumb()


func _spawn_floor_crumb() -> void:
	var floor_count := 0
	for item in food:
		if item.spot == "" and item.size == Size.CRUMB:
			floor_count += 1
	if floor_count >= 3:
		return
	for _i in 8:
		var p := mom_pos + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.4, 0.75)
		if map.is_free(p, 0.12):
			_add_item(Size.CRUMB, "", p)
			return


func _spawn_food(size: int) -> bool:
	var on_counters := 0
	var used := {}
	for item in food:
		if item.spot != "":
			on_counters += 1
			used[item.spot] = true
	var free: Array = level.spots.filter(func(s: String) -> bool: return not used.has(s))
	if free.is_empty() or (size != Size.TREASURE and on_counters >= int(level.max_items)):
		return false
	if size < 0:
		var w: Array = level.weights
		var roll: float = rng.randf() * (w[0] + w[1] + w[2])
		size = Size.CRUMB if roll < w[0] else (Size.SMALL if roll < w[0] + w[1] else Size.BIG)
	# Les grosses prises sont plutôt loin du coin.
	var total := 0.0
	var weights: Array[float] = []
	for s: String in free:
		var far: float = map.spots[s].far
		var wt := 1.0
		if size >= Size.BIG:
			wt = 0.1 + far * far
		elif size == Size.CRUMB:
			wt = 1.3 - far
		weights.append(wt)
		total += wt
	var pick := rng.randf() * total
	var chosen: String = free[free.size() - 1]
	for i in free.size():
		pick -= weights[i]
		if pick <= 0.0:
			chosen = free[i]
			break
	var item := _add_item(size, chosen, map.spots[chosen].food)
	if size == Size.TREASURE:
		_emit("treasure", {"item": item})
	return true


func _add_item(size: int, spot: String, pos: Vector2) -> Dictionary:
	var points: int = int(level.treasure_points) if size == Size.TREASURE else BASE_POINTS[size]
	var item := {"id": _next_id, "size": size, "spot": spot, "pos": pos, "points": points}
	_next_id += 1
	food.append(item)
	_emit("spawn", {"item": item})
	return item


# ------------------------------------------------------------------ Papa et Charlotte

func _step_helpers(dt: float) -> void:
	if level.helpers.is_empty():
		return
	if helpers.is_empty():
		helper_left -= dt
		if helper_left <= 0.0:
			var who: String = level.helpers[rng.randi_range(0, level.helpers.size() - 1)]
			_add_helper(who)
		return
	var h := helpers[0]
	if h.state == "stay":
		h.t -= dt
		if h.t <= 0.0:
			h.state = "leave"
			h.path = nav.path(h.pos, map.helper_door)
	else:
		_follow_helper(h, dt)
		if h.path.is_empty():
			if h.state == "enter":
				h.state = "stay"
				h.t = 4.5
				if mom_state == Mom.BUSY:
					_enter_busy("charlotte")
					_emit("distract")
			else:
				helpers.clear()
				helper_left = rng.randf_range(16.0, 26.0)
				_emit("helper_out", {"who": h.who})
				return
	if h.who == "charlotte":
		_step_snitch(h, dt)
	elif h.drop_at >= 0 and h.index >= h.drop_at:
		h.drop_at = -1
		var p := map.resolve(h.pos + Vector2(-0.3, 0.05), 0.1)
		_add_item(Size.SMALL, "", p)
		_emit("papa_drop", {"pos": p})


func _add_helper(who: String) -> void:
	var h := {"who": who, "pos": map.helper_door, "dir": Vector2.UP, "state": "enter", "t": 0.0, "snitch": 0.0,
		"cool": 0.0, "index": 0, "drop_at": -1, "path": PackedVector2Array()}
	if who == "papa":
		h.path = PackedVector2Array(PAPA_PATH)
		h.path.append(map.helper_door)
		h.state = "cross"
		h.drop_at = rng.randi_range(2, 4) if rng.randf() < 0.75 else -1
	else:
		var goal := mom_pos + Vector2(0.0, 0.6)
		if not map.is_free(goal, HELPER_RADIUS):
			goal = mom_pos + Vector2(-0.6, 0.35)
		h.path = nav.path(h.pos, goal)
	helpers.append(h)
	_emit("helper_in", {"who": who})


func _follow_helper(h: Dictionary, dt: float) -> void:
	var step_ := _advance(h.pos, h.dir, h.path, (0.8 if h.who == "papa" else 1.0) * dt)
	h.pos = step_.pos
	h.dir = step_.dir
	h.path = step_.path
	h.index += step_.done
	_nudge_dog(h.pos, HELPER_RADIUS)


## Charlotte voit Blanche faire : « Hon ! », puis elle appelle Maman si ça continue.
func _step_snitch(h: Dictionary, dt: float) -> void:
	h.cool -= dt
	# Les pattes en l'air, Blanche dépasse toujours : l'îlot ne la cache pas à Charlotte non plus.
	var sees: bool = h.cool <= 0.0 and dog_state == Dog.REACHING and h.pos.distance_to(dog_pos) < 2.3
	if not sees:
		h.snitch = 0.0
		return
	if h.snitch == 0.0:
		_emit("snitch")
	h.snitch += dt
	if h.snitch >= 0.9:
		h.snitch = 0.0
		h.cool = 2.5
		_emit("snitch_call")
		if mom_state == Mom.BUSY or (mom_state == Mom.HINT and hint_kind == "feint"):
			feinted = true
			_hint("real", _hint_time())


func _rand(span: Array) -> float:
	return rng.randf_range(span[0], span[1])


func _emit(type: String, extra: Dictionary = {}) -> void:
	extra.type = type
	extra.time = time
	events.append(extra)
