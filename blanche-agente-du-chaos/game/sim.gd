class_name Sim
extends RefCounted
## Toutes les règles d'un niveau, sans affichage : Blanche, la personne qui surveille, la nourriture, les aides et le
## pointage. On appelle step() avec les commandes ; l'affichage lit l'état et la liste d'événements.
##
## La personne qui surveille est Maman, ou Papa (`watcher`) ; ses variables gardent le préfixe `mom_`.

enum Dog { FREE, REACHING, LOWERING, TO_CORNER, IN_CORNER }
## WALK : elle change de place sans surveiller. ROUND : le tour de l'îlot, les yeux ouverts, toujours annoncé.
## Hors de la pièce (à la cuisine), elle reste BUSY ; son retour est un indice (« retour ») puis TURN dans la porte.
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
## Sur une table basse, on attrape le nez tendu, sans se dresser : plus vite.
const LOW_GRAB := 0.65
const EAT_TIMES := [0.0, 0.5, 1.5, 3.0]
const BASE_POINTS := [10, 50, 150, 500]
## La chicane quand Papa est dans le chemin : Maman ne regarde plus que lui.
const ARGUE_TIME := 6.0
const AFTER_ARGUE := [0.9, 1.6]
## Les noms des tailles dans les données des niveaux.
const SIZE_KEYS := ["crumb", "small", "big", "treasure"]
## Ce qui rend Maman méfiante d'un coup (la jauge va de 0 à 1) : un morceau qui disparaît, selon sa taille, un bruit,
## Blanche prise sur le fait.
const WARY_FOOD := [0.0, 0.06, 0.13, 0.24]
const WARY_NOISE := 0.18
const WARY_CAUGHT := 0.3
## La part des fenêtres que la méfiance retranche, quand la jauge est pleine.
const WARY_WINDOW := 0.3
## La punition dure un peu plus dans la cage que sur un coussin.
const CAGE_EXTRA := 0.6
## Au bout de combien de temps un trésor perdu revient sur un meuble.
const TREASURE_RETURN := 12.0
## Durée d'une fenêtre selon ce que fait Maman (secondes, avant les ajustements).
const ACTIVITY_WINDOWS := {
	"brasser": [3.5, 5.0], "four": [3.0, 4.5], "couper": [2.2, 3.2], "laver": [3.2, 4.8], "frigo": [5.0, 6.5],
	"telephone": [6.0, 8.0], "ilot": [2.8, 4.0], "surprise": [7.0, 9.0], "charlotte": [6.0, 7.5],
	"chicane": [ARGUE_TIME, ARGUE_TIME],
	"servir": [2.6, 3.6], "manger": [3.6, 5.0], "buffet": [3.2, 4.4], "disque": [5.0, 6.5], "cuisine": [5.5, 7.5],
	"hockey": [3.4, 4.8], "but": [7.0, 9.0], "film": [3.6, 5.0], "jaser": [3.0, 4.2],
}
## Le retour de la cuisine s'annonce un peu plus longtemps : il faut lire l'icône au bord de l'écran.
const RETURN_EXTRA := 0.25
## Charlotte complice : le geste de glisser un morceau sous la table, et l'attente entre deux.
const SLIP_TIME := 1.3
const SLIP_WAIT := [4.5, 8.0]
## La visite assise à table : elle jase, puis regarde autour ; elle voit ce qui se passe de son côté de la table.
const GUEST_CHAT := [3.5, 6.0]
const GUEST_LOOK := [2.0, 3.5]
const GUEST_SIGHT := 0.85
const SNITCH_SIGHT := 2.3
const SNITCH_TIME := 0.9
const WALKER_SPEED := 0.8
const WALKER_SIGHT := 1.4
## La visite jase longtemps entre deux déplacements.
const WALKER_CHAT := [4.0, 7.5]
## Le noir : la lumière de la télé, d'une scène à l'autre, et le temps qu'elle met à changer.
const TV_SCENES := [0.0, 0.15, 0.35, 0.7, 1.0]
const TV_SCENE_TIME := [3.0, 7.0]
const TV_RAMP := 0.6


var map: RoomMap
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
## Elle est sortie de la pièce (à la cuisine).
var mom_out := false
## Elle revient de la cuisine avec un plat : elle le pose en arrivant.
var _serving := false
## Avec qui elle se chicane : "papa" ou "charlotte".
var chicane_with := "papa"
## "maman" ou "papa".
var watcher := "maman"

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
## Les personnes assises (Charlotte à table, la visite, Papa au divan) : {who, seat, role, pos, dir, state, t, snitch, cool}.
var seated: Array[Dictionary] = []
## La visite qui circule : {who, pos, dir, state, path, t, snitch, cool}.
var walkers: Array[Dictionary] = []
## La lumière de la télé (le noir) : 0 pour une scène sombre, 1 pour une scène claire.
var tv_light := 1.0
var _tv_target := 1.0
var _tv_left := 0.0
var _tv_rng := RandomNumberGenerator.new()

var score := 0
var streak := 0
var suspicion := 0.0
var caught_count := 0
var eaten := [0, 0, 0, 0]


func _init(map_: RoomMap, level_: Dictionary, seed_ := 1, nav_: Nav = null, mom_nav_: Nav = null) -> void:
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
	watcher = level.get("watcher", "maman")
	_setup_people()
	if level.has("dark"):
		_tv_rng.seed = seed_ + 7919
		tv_light = 0.35
		_tv_target = tv_light
		_tv_left = _tv_rng.randf_range(TV_SCENE_TIME[0], TV_SCENE_TIME[1])


## Les grilles de déplacement de Blanche et de Maman (à partager entre les parties).
static func dog_grid(map_: RoomMap) -> Nav:
	return Nav.new(map_, DOG_RADIUS - 0.01)


static func mom_grid(map_: RoomMap) -> Nav:
	return Nav.new(map_, MOM_RADIUS - 0.02)


# ------------------------------------------------------------------ lecture

func watching() -> bool:
	return mom_state == Mom.LOOK or mom_state == Mom.ROUND


## Un vrai indice (pas une feinte) : elle va se retourner ou faire le tour.
func warning() -> bool:
	return mom_state == Mom.HINT and hint_kind != "feint"


func snitching() -> bool:
	for list: Array in [helpers, seated, walkers]:
		for h in list:
			if h.snitch > 0.0:
				return true
	return false


## En route vers le coin, ou assise à y purger sa peine.
func punished() -> bool:
	return dog_state == Dog.TO_CORNER or dog_state == Dog.IN_CORNER


func paws_up() -> bool:
	return dog_state == Dog.REACHING or dog_state == Dog.LOWERING


## Cachée (derrière l'îlot ou le divan, sous la table, ou dans le noir), vue de là où est la personne qui surveille.
## Jamais pendant une prise.
func dog_hidden(viewer := Vector2.INF, close := "", low := false) -> bool:
	if paws_up():
		return false
	if viewer == Vector2.INF:
		viewer = viewpoint()
		close = mom_close()
		low = mom_low()
	return hidden_at(dog_pos, viewer, close, low)


## Un point du plancher est-il caché à la personne qui surveille (ou à `viewer`) ?
func hidden_at(p: Vector2, viewer := Vector2.INF, close := "", low := false) -> bool:
	if viewer == Vector2.INF:
		viewer = viewpoint()
		close = mom_close()
		low = mom_low()
	return map.hidden(viewer, p, close, low) or p.distance_to(viewer) > sight_range()


## D'où elle verra la pièce : là où elle est, ou la porte par où elle reviendra de la cuisine.
func viewpoint() -> Vector2:
	return map.mom_door if mom_out else mom_pos


## La cachette contre laquelle elle travaille (elle voit par-dessus de près), ou "".
func mom_close() -> String:
	var st: Dictionary = map.stations[station]
	var c: String = st.close
	if c != "" and mom_pos.distance_to(st.pos) < 0.2:
		return c
	return ""


## Assise à table ou penchée pendant son tour : elle voit sous la table, de son côté.
func mom_low() -> bool:
	if mom_state == Mom.ROUND:
		return true
	var st: Dictionary = map.stations[station]
	return st.seated and mom_state != Mom.WALK and mom_pos.distance_to(st.pos) < 0.2


## Jusqu'où on voit : partout, sauf dans le noir, où ça dépend de la lumière de la télé.
func sight_range() -> float:
	if not level.has("dark"):
		return INF
	return lerpf(float(level.dark.near), float(level.dark.far), tv_light)


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


## Les personnes à contourner, comme cercles [centre, rayon]. Quelqu'un debout et immobile n'en est pas une : le
## chiot lui passe entre les jambes (sinon Papa et Maman pourraient le coincer pendant toute une chicane). Assise, ou
## sortie de la pièce, la personne qui surveille n'en est pas une non plus.
func people_circles() -> Array:
	var out: Array = []
	if not mom_out and (mom_state == Mom.ROUND or not mom_low()):
		out.append([mom_pos, MOM_RADIUS])
	for h in helpers:
		if h.state in ["enter", "cross", "leave"]:
			out.append([h.pos, HELPER_RADIUS])
	for w in walkers:
		if w.state == "walk":
			out.append([w.pos, HELPER_RADIUS])
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


## Le temps qu'il faut tenir pour attraper ce morceau.
func grab_time(item: Dictionary) -> float:
	var t: float = GRAB_TIMES[item.size]
	if item.spot != "" and map.spots[item.spot].surface == "low":
		return t * LOW_GRAB
	return t


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
	_step_seated(dt)
	_step_walkers(dt)
	_step_food(dt)
	_step_suspicion(dt)
	_step_tv(dt)
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
				if reach_progress >= grab_time(reach_item):
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
	for i in map.stools.size():
		var s: Dictionary = map.stools[i]
		if bool(level.noise) and stool_cool <= 0.0 and dog_pos.distance_to(s.pos) < DOG_RADIUS + s.r + 0.006:
			if (s.pos - before).normalized().dot(move.normalized()) > 0.6:
				stool_cool = 4.0
				_noise(s.pos, "tabouret" if s.name == "tabouret" else "chaise", i)
	for i in range(food.size() - 1, -1, -1):
		var item := food[i]
		if item.spot == "" and item.size == Size.CRUMB and mouth.is_empty() and dog_pos.distance_to(item.pos) < CRUMB_REACH:
			food.remove_at(i)
			_emit("grabbed", {"item": item})
			_score(item)


## Les corps qui bloquent Blanche. Si quelqu'un lui a marché dessus, elle peut toujours se glisser dehors.
func _body_circles(from: Vector2, move: Vector2) -> Array:
	var circles: Array = map.stool_circles()
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
		corner_left = 2.0 + 0.5 * minf(caught_count - 1, float(level.get("repeat_max", 4)))
		if map.corner_kind == "cage":
			# Dans sa cage, on attend que Maman ait fermé puis rouvert la porte.
			corner_left += CAGE_EXTRA
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
		dog_pos = map.resolve(dog_pos, DOG_RADIUS, [[from, radius]] + map.stool_circles())


# ------------------------------------------------------------------ Maman

func _step_mom(dt: float) -> void:
	match mom_state:
		Mom.BUSY:
			var drain := 1.0
			# Pendant la chicane, elle ne remarque rien de ce qui se passe à côté d'elle.
			if activity != "chicane" and not mom_out and dog_state == Dog.REACHING and dog_pos.distance_to(mom_pos) < NEAR_MOM:
				drain = 1.5
			mom_left -= dt * drain
			if mom_left <= 0.0:
				if activity == "chicane":
					# La chicane finie, elle retourne à ses affaires, mais pas pour longtemps : « Où est Blanche ? »
					# La surveillance viendra, comme toujours, avec son indice.
					_back_to_work()
					_set_timer(rng.randf_range(AFTER_ARGUE[0], AFTER_ARGUE[1]))
					feinted = true
				else:
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
					if mom_out:
						# Elle arrive de la cuisine : la voilà dans la porte, qui regarde la pièce.
						mom_out = false
						mom_pos = map.mom_door
						mom_dir = map.stations[station].face
						_nudge_dog(mom_pos, MOM_RADIUS)
						_emit("back_in")
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
				if st.outside:
					# Prise sur le fait en entrant : elle entre pour de bon.
					_go_in()
				elif mom_pos.distance_to(st.pos) > 0.15:
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
				if st.outside:
					mom_out = true
					_emit("out")
				_enter_busy(walk_activity)
				if _serving:
					_serving = false
					_serve()
		Mom.ROUND:
			if _follow_mom(dt, ROUND_WALK):
				_start_walk(station, map.stations[station].activity)


func _end_window() -> void:
	if mom_out:
		# Son retour s'annonce toujours : des pas, « J'arrive ! », puis elle est dans la porte.
		_hint("retour", _hint_time() + RETURN_EXTRA)
		return
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


## La direction où elle regarde quand elle se retourne (à l'îlot, assise ou dans la porte : devant elle).
func _look_dir() -> Vector2:
	var st: Dictionary = map.stations[station]
	var face: Vector2 = st.face
	return face if st.front else -face


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
	var goal: Vector2 = map.stations[station].pos
	if map.stations[station].outside:
		# Elle sort par la porte : on la perd de vue au seuil.
		goal = map.mom_door
	mom_path = mom_nav.path(mom_pos, goal)
	_emit("walk", {"station": station})


func _start_round() -> void:
	var ring := map.ring
	var start := 0
	for i in ring.size():
		if mom_pos.distance_to(ring[i]) < mom_pos.distance_to(ring[start]):
			start = i
	var way := 1 if rng.randf() < 0.5 else -1
	var points := rng.randi_range(4, 6)
	mom_path = PackedVector2Array()
	for k in points:
		mom_path.append(ring[posmod(start + k * way, ring.size())])
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


func _back_to_work() -> void:
	var st: Dictionary = map.stations[station]
	mom_dir = st.face
	_enter_busy(st.activity)


## Papa s'en vient et la chicane n'a pas encore eu lieu.
func _papa_coming() -> bool:
	return helpers.any(func(h: Dictionary) -> bool: return h.who == "papa" and h.state in ["cross", "wait"])


func _next_activity() -> void:
	if map.stations[station].outside:
		_go_in()
		return
	if _papa_coming():
		# Elle reste à son poste : Papa va finir dans son chemin.
		_back_to_work()
		return
	if time > 15.0 and rng.randf() < float(level.surprise_chance):
		if level.has("surprise"):
			# Une surprise sur place (le but des Canadiens) : très longue, mais soudaine.
			_emit("surprise")
			mom_dir = map.stations[station].face
			_enter_busy(str(level.surprise.activity))
			return
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


## Un bruit : la fenêtre se referme vite. `index` : le petit meuble bousculé.
func _noise(pos: Vector2, what: String, index := -1) -> void:
	_wary(WARY_NOISE, "noise")
	_emit("noise", {"pos": pos, "what": what, "index": index})
	if mom_state == Mom.BUSY and activity == "chicane":
		# Le vacarme coupe la chicane net.
		activity = map.stations[station].activity
		mom_dir = map.stations[station].face
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
	match h.state:
		"stay":
			h.t -= dt
			if h.t <= 0.0:
				_leave(h)
		"argue":
			h.t -= dt
			if h.t <= 0.0 or mom_state != Mom.BUSY or activity != "chicane":
				_leave(h)
		"wait":
			_wait_for_mom(h, dt)
		_:
			_follow_helper(h, dt)
			if h.path.is_empty():
				match h.state:
					"enter":
						h.state = "stay"
						h.t = 4.5
						if mom_state == Mom.BUSY:
							_enter_busy("charlotte")
							_emit("distract")
					"cross":
						h.state = "wait"
					_:
						helpers.clear()
						helper_left = rng.randf_range(16.0, 26.0)
						_emit("helper_out", {"who": h.who})
						return
	if h.who == "charlotte":
		_step_snitch(h, dt)
	elif h.drop_in >= 0.0 and h.state == "cross":
		h.drop_in -= dt
		if h.drop_in < 0.0:
			var p := map.resolve(h.pos + Vector2(-0.3, 0.05), 0.1)
			_add_item(Size.SMALL, "", p)
			_emit("papa_drop", {"pos": p})


func _leave(h: Dictionary) -> void:
	h.state = "leave"
	h.path = nav.path(h.pos, map.helper_door)


## Une place libre tout près de Maman : là où se tenir pour lui parler (Charlotte), ou juste à côté d'elle, dans son
## chemin (Papa : de côté, on les voit se faire face).
func _beside_mom(who := "charlotte") -> Vector2:
	var offsets := [Vector2(0.0, 0.6), Vector2(-0.6, 0.35), Vector2(0.6, 0.35), Vector2(-0.65, 0.0), Vector2(0.65, 0.0)]
	if who == "papa":
		offsets = [Vector2(0.65, 0.05), Vector2(-0.65, 0.05), Vector2(0.6, 0.35), Vector2(-0.6, 0.35), Vector2(0.0, 0.6)]
	for offset: Vector2 in offsets:
		if map.is_free(mom_pos + offset, HELPER_RADIUS):
			return mom_pos + offset
	return map.resolve(mom_pos + Vector2(0.0, 0.7), HELPER_RADIUS, [[mom_pos, MOM_RADIUS]])


## Papa est arrivé : la chicane part dès que Maman a la tête à ses chaudrons.
func _wait_for_mom(h: Dictionary, dt: float) -> void:
	h.t += dt
	if mom_state == Mom.BUSY:
		if h.pos.distance_to(mom_pos) > 1.0:
			h.state = "cross"
			h.path = nav.path(h.pos, _beside_mom(h.who))
			return
		h.state = "argue"
		h.t = ARGUE_TIME
		feinted = false
		activity = "chicane"
		_set_timer(ARGUE_TIME)
		mom_dir = (h.pos - mom_pos).normalized()
		_emit("argue")
	elif h.t > 8.0:
		_leave(h)


func _add_helper(who: String) -> void:
	var h := {"who": who, "pos": map.helper_door, "dir": Vector2.UP, "state": "enter", "t": 0.0, "snitch": 0.0,
		"cool": 0.0, "drop_in": -1.0, "path": nav.path(map.helper_door, _beside_mom(who))}
	if who == "papa":
		# Les bras pleins, il lui arrive d'échapper quelque chose en chemin.
		h.state = "cross"
		h.drop_in = rng.randf_range(0.6, 1.6) if rng.randf() < 0.75 else -1.0
	helpers.append(h)
	_emit("helper_in", {"who": who})


func _follow_helper(h: Dictionary, dt: float) -> void:
	var step_ := _advance(h.pos, h.dir, h.path, (0.8 if h.who == "papa" else 1.0) * dt)
	h.pos = step_.pos
	h.dir = step_.dir
	h.path = step_.path
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


# ------------------------------------------------------------------ hors de la pièce

## Elle revient de la cuisine (ou se fait prendre dans la porte) : elle va à un poste de la pièce, un plat à la main.
func _go_in() -> void:
	var inside: Array = level.stations.filter(func(s: String) -> bool: return not map.stations[s].outside)
	var next: String = inside[rng.randi_range(0, inside.size() - 1)]
	_serving = level.get("serve", false) == true
	_start_walk(next, map.stations[next].activity)


## Elle pose le plat qu'elle rapporte de la cuisine.
func _serve() -> void:
	if _spawn_food(-1):
		_emit("served")


# ------------------------------------------------------------------ personnes assises et visite qui circule

func _setup_people() -> void:
	for s: Dictionary in level.get("seated", []):
		var seat: Dictionary = map.seats[s.seat]
		var p := {"who": s.who, "seat": s.seat, "role": s.role, "pos": seat.pos, "dir": seat.face, "state": "eat",
			"t": 0.0, "snitch": 0.0, "cool": 0.0, "dropped": 0}
		match s.role:
			"complice":
				p.t = _rand(level.get("slip_wait", SLIP_WAIT))
			"temoin":
				p.state = "jase"
				p.t = rng.randf_range(GUEST_CHAT[0], GUEST_CHAT[1])
		seated.append(p)
	var points: Dictionary = map.data.get("waypoints", {})
	for w: Dictionary in level.get("walkers", []):
		var at: Vector2 = RoomMap.vec(points[w.start])
		walkers.append({"who": w.who, "pos": at, "dir": Vector2.DOWN, "state": "pause", "path": PackedVector2Array(),
			"t": rng.randf_range(1.0, 3.0), "snitch": 0.0, "cool": 0.0, "points": w.points})


func _step_seated(dt: float) -> void:
	for s in seated:
		match s.role:
			"complice":
				_step_accomplice(s, dt)
			"temoin":
				_step_guest(s, dt)


## Charlotte à table glisse des morceaux sous la table. Si Maman la voit faire, c'est la chicane.
func _step_accomplice(s: Dictionary, dt: float) -> void:
	var watching_inside: bool = watching() and not mom_out and not map.stations[station].outside
	match s.state:
		"eat":
			s.t -= dt
			if s.t <= 0.0 and not watching() and mom_state != Mom.SCOLD:
				s.state = "slip"
				s.t = SLIP_TIME
				_emit("slip_start", {"who": s.who})
		"slip":
			if watching_inside and mom_state == Mom.LOOK:
				_bust(s)
				return
			s.t -= dt
			if s.t <= 0.0:
				s.state = "eat"
				s.t = _rand(level.get("slip_wait", SLIP_WAIT))
				_slip_piece(s)
		"argue":
			if mom_state != Mom.BUSY or activity != "chicane":
				s.state = "eat"
				var wait: Array = level.get("slip_wait", SLIP_WAIT)
				s.t = rng.randf_range(wait[0] + 3.0, wait[1] + 4.0)


## Maman a vu Charlotte nourrir la chienne : elle ne regarde plus qu'elle, le temps de la chicane.
func _bust(s: Dictionary) -> void:
	s.state = "argue"
	chicane_with = s.who
	mom_state = Mom.BUSY
	feinted = false
	activity = "chicane"
	_set_timer(ARGUE_TIME)
	mom_dir = (s.pos - mom_pos).normalized()
	_emit("busted", {"who": s.who})
	_emit("argue", {"with": s.who})


## Le morceau tombe sous la table, du côté de Charlotte.
func _slip_piece(s: Dictionary) -> void:
	var floor_count := 0
	for item in food:
		if item.spot == "" and item.has("from"):
			floor_count += 1
	if floor_count >= 2:
		return
	var under: Dictionary = {}
	for h in map.hides:
		if h.kind == "dessous":
			under = h
	if under.is_empty():
		return
	var rect: Rect2 = under.rect.grow(-0.14)
	var p: Vector2 = s.pos.lerp(rect.get_center(), 0.55) + Vector2(rng.randf_range(-0.12, 0.12), 0.0)
	p = p.clamp(rect.position, rect.end)
	var item := _add_item(Size.SMALL, "", p)
	item.from = s.who
	_emit("slip", {"who": s.who, "item": item})


## La visite à table : elle jase, puis regarde autour ; si Blanche se dresse à table de son côté, elle le dit.
func _step_guest(s: Dictionary, dt: float) -> void:
	s.t -= dt
	s.cool -= dt
	if s.t <= 0.0:
		if s.state == "jase":
			s.state = "regarde"
			s.t = rng.randf_range(GUEST_LOOK[0], GUEST_LOOK[1])
		else:
			s.state = "jase"
			s.t = rng.randf_range(GUEST_CHAT[0], GUEST_CHAT[1])
			_emit("chat", {"who": s.who})
	var sees: bool = s.state == "regarde" and s.cool <= 0.0 and dog_state == Dog.REACHING \
		and map.spots[reach_item.spot].food.distance_to(s.pos) < GUEST_SIGHT
	_snitch_step(s, sees, dt)


## Quelqu'un voit Blanche se dresser : « Hon ! », puis il appelle si ça continue (un vrai indice).
func _snitch_step(h: Dictionary, sees: bool, dt: float) -> void:
	if not sees:
		h.snitch = 0.0
		return
	if h.snitch == 0.0:
		_emit("snitch", {"who": h.who})
	h.snitch += dt
	if h.snitch >= SNITCH_TIME:
		h.snitch = 0.0
		h.cool = 2.5
		_emit("snitch_call", {"who": h.who})
		if mom_out:
			# Appelée de la cuisine, elle revient (son retour s'annonce comme toujours).
			if mom_state == Mom.BUSY:
				mom_left = minf(mom_left, 0.2)
		elif mom_state == Mom.BUSY or (mom_state == Mom.HINT and hint_kind == "feint"):
			feinted = true
			_hint("real", _hint_time())


## La visite qui circule : elle va d'un endroit à l'autre, s'arrête pour jaser, et voit ce qui se passe autour.
func _step_walkers(dt: float) -> void:
	var points: Dictionary = map.data.get("waypoints", {})
	for w in walkers:
		w.cool -= dt
		if w.state == "pause":
			w.t -= dt
			if w.t <= 0.0:
				var options: Array = w.points.duplicate()
				var here := ""
				for name_: String in options:
					if RoomMap.vec(points[name_]).distance_to(w.pos) < 0.2:
						here = name_
				options.erase(here)
				var next: String = options[rng.randi_range(0, options.size() - 1)]
				w.path = nav.path(w.pos, RoomMap.vec(points[next]))
				w.state = "walk"
		else:
			var step_ := _advance(w.pos, w.dir, w.path, WALKER_SPEED * dt)
			w.pos = step_.pos
			w.dir = step_.dir
			w.path = step_.path
			_nudge_dog(w.pos, HELPER_RADIUS)
			if w.path.is_empty():
				w.state = "pause"
				w.t = rng.randf_range(WALKER_CHAT[0], WALKER_CHAT[1])
		# En jasant, la visite ne voit rien ; en marchant, elle voit ce qui se passe autour d'elle.
		var sees: bool = w.state == "walk" and w.cool <= 0.0 and dog_state == Dog.REACHING \
			and w.pos.distance_to(dog_pos) < WALKER_SIGHT
		_snitch_step(w, sees, dt)


# ------------------------------------------------------------------ le noir

## La lumière de la télé change d'une scène à l'autre ; elle ne monte jamais pendant qu'on regarde.
func _step_tv(dt: float) -> void:
	if not level.has("dark"):
		return
	_tv_left -= dt
	if _tv_left <= 0.0:
		_tv_left = _tv_rng.randf_range(TV_SCENE_TIME[0], TV_SCENE_TIME[1])
		_tv_target = TV_SCENES[_tv_rng.randi_range(0, TV_SCENES.size() - 1)]
	var want := _tv_target
	if (watching() or mom_state == Mom.TURN) and want > tv_light:
		want = tv_light
	tv_light = move_toward(tv_light, want, dt / TV_RAMP)


func _rand(span: Array) -> float:
	return rng.randf_range(span[0], span[1])


func _emit(type: String, extra: Dictionary = {}) -> void:
	extra.type = type
	extra.time = time
	events.append(extra)
