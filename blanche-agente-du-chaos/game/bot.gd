class_name Bot
extends RefCounted
## Un joueur robot : sert aux tests d'équilibrage et à la démonstration automatique.
## Il ne voit Maman qu'avec un délai de réaction, comme une personne.

## "prudent", "equilibre", "gourmand" et "novice" (lent à se décider) jouent honnêtement ; "sage" lâche tout au moindre
## indice (il sert à vérifier l'équité) ; "spam", "tetu", "miettes" et "campeur" sont des stratégies dégénérées qui ne
## doivent pas gagner.
var style: String
var reaction: float
var attentive: float
var move := Vector2.ZERO
var grab := false

var sim: Sim
var follower: Follower
var rng := RandomNumberGenerator.new()
var _seen: Array[Dictionary] = []
var _hint_id := 0.0
var _hint_believed := true
var _busy_since := 0.0
var _last_state := -1
var _target: Dictionary = {}
var _think := 0.0
var _spam := 0.0
var _hide_points: Array[Vector2] = []


func _init(sim_: Sim, style_ := "equilibre", reaction_ := 0.35, attentive_ := 0.9, seed_ := 7) -> void:
	sim = sim_
	style = style_
	reaction = reaction_
	attentive = attentive_
	rng.seed = seed_
	follower = Follower.new(sim.nav)
	var around := sim.map.island.grow(0.85)
	var x := around.position.x
	while x <= around.end.x:
		var y := around.position.y
		while y <= around.end.y:
			var p := Vector2(x, y)
			if sim.map.is_free(p, Sim.DOG_RADIUS):
				_hide_points.append(p)
			y += 0.16
		x += 0.16


func step(dt: float) -> void:
	_observe()
	var view := _perceived()
	move = Vector2.ZERO
	match style:
		"spam":
			_spam += dt
			grab = fmod(_spam, 0.24) < 0.12
			_go_to_nearest(dt)
			return
		"tetu":
			grab = sim.dog_state == Sim.Dog.REACHING or (sim.dog_state == Sim.Dog.FREE and sim.mouth.is_empty() \
				and not sim.reachable_item().is_empty())
			if sim.dog_state == Sim.Dog.FREE:
				_go_to_nearest(dt)
			return
		"campeur":
			grab = false
			var h := _hide_point(view.mom_pos, view.at_island)
			if h != Vector2.INF:
				move = follower.steer(dt, sim.dog_pos, h, _blockers())
			return
	if sim.dog_state == Sim.Dog.TO_CORNER or sim.dog_state == Sim.Dog.IN_CORNER:
		grab = false
		_target = {}
		return
	var danger := _danger(view)
	if sim.dog_state == Sim.Dog.REACHING:
		var left: float = Sim.GRAB_TIMES[sim.reach_item.size] - sim.reach_progress
		var risk: bool = style == "gourmand" and view.state == Sim.Mom.HINT and left < 0.18
		grab = not (danger or view.snitch) or risk
		return
	if sim.dog_state == Sim.Dog.LOWERING:
		grab = false
		return
	if not sim.mouth.is_empty():
		if style == "sage" and danger:
			grab = not grab
			return
		_with_food(dt, view, danger)
		return
	if danger:
		grab = false
		_target = {}
		return
	_seek_food(dt, view)
	if style == "novice":
		move *= 0.75


func _with_food(dt: float, view: Dictionary, danger: bool) -> void:
	var hidden := sim.dog_hidden(view.mom_pos, view.at_island)
	if danger:
		if hidden:
			grab = false
			return
		var h := _hide_point(view.mom_pos, view.at_island)
		if h != Vector2.INF and sim.dog_pos.distance_to(h) < 0.55:
			grab = false
			move = follower.steer(dt, sim.dog_pos, h, _blockers(), 0.03)
		else:
			# Pas le temps de se cacher : on lâche le morceau.
			grab = not grab
		return
	grab = false
	var patience := {"prudent": 0.6, "equilibre": 1.0, "gourmand": 2.0, "novice": 2.2}
	var long_meal: bool = sim.mouth.eat_left > float(patience.get(style, 1.0))
	if long_meal and not hidden:
		var h := _hide_point(view.mom_pos, view.at_island)
		if h != Vector2.INF and sim.dog_pos.distance_to(h) < 1.8:
			move = follower.steer(dt, sim.dog_pos, h, _blockers(), 0.05)


func _seek_food(dt: float, view: Dictionary) -> void:
	_think -= dt
	if _think <= 0.0 or (not _target.is_empty() and not sim.food.has(_target)):
		if style == "novice" and not _target.is_empty() and not sim.food.has(_target):
			# Il prend un moment avant de se décider de nouveau.
			_target = {}
			_think = 1.2
			grab = false
			return
		_think = 0.4
		_target = _choose(view)
	if _target.is_empty():
		grab = false
		return
	var goal: Vector2 = _target.pos if _target.spot == "" else sim.map.spots[_target.spot].stand
	var near := Sim.FLOOR_REACH * 0.8 if _target.spot == "" else Sim.REACH_DIST * 0.75
	if sim.dog_pos.distance_to(goal) <= near:
		grab = true
	else:
		grab = false
		move = follower.steer(dt, sim.dog_pos, goal, _blockers(), 0.06)


func _choose(view: Dictionary) -> Dictionary:
	var span: Array = Sim.ACTIVITY_WINDOWS.get(view.activity, [2.0, 3.0])
	var expected: float = (span[0] + span[1]) * 0.5 * float(sim.level.window_mult) * (1.0 - 0.35 * sim.suspicion)
	var remaining := maxf(0.0, expected - (sim.time - _busy_since))
	var best: Dictionary = {}
	var best_value := 0.0
	for item in sim.food:
		if style == "miettes" and item.size != Sim.Size.CRUMB:
			continue
		var goal: Vector2 = item.pos if item.spot == "" else sim.map.spots[item.spot].stand
		if goal.distance_to(sim.mom_pos) < Sim.MOM_RADIUS + Sim.DOG_RADIUS - 0.06:
			continue
		var travel := sim.dog_pos.distance_to(goal) * 1.25 / Sim.DOG_SPEED
		var grab_time: float = Sim.GRAB_TIMES[item.size]
		match style:
			"prudent", "miettes":
				if grab_time + minf(travel, 1.0) > remaining + 0.2:
					continue
			"equilibre", "novice", "sage":
				if grab_time > remaining + 0.9:
					continue
		var worth: float = pow(item.points, 1.35 if style == "gourmand" else 1.0)
		var value: float = worth / (travel + grab_time + Sim.EAT_TIMES[item.size] * 0.6 + 0.5)
		if value > best_value:
			best_value = value
			best = item
	return best


func _go_to_nearest(dt: float) -> void:
	var best := Vector2.INF
	for item in sim.food:
		var goal: Vector2 = item.pos if item.spot == "" else sim.map.spots[item.spot].stand
		if best == Vector2.INF or sim.dog_pos.distance_to(goal) < sim.dog_pos.distance_to(best):
			best = goal
	if best != Vector2.INF and sim.dog_pos.distance_to(best) > 0.2:
		move = follower.steer(dt, sim.dog_pos, best, _blockers())


func _blockers() -> Array:
	var out: Array = [[sim.mom_pos, Sim.MOM_RADIUS]]
	for h in sim.helpers:
		out.append([h.pos, Sim.HELPER_RADIUS])
	return out


func _hide_point(viewer: Vector2, at_island: bool) -> Vector2:
	var best := Vector2.INF
	var best_d := INF
	for p in _hide_points:
		var d := sim.dog_pos.distance_squared_to(p)
		if d < best_d and p.distance_to(viewer) > 0.55 and sim.map.hidden_by_island(viewer, p, at_island):
			best_d = d
			best = p
	return best


func _observe() -> void:
	if sim.mom_state != _last_state:
		if sim.mom_state == Sim.Mom.BUSY:
			_busy_since = sim.time
		_last_state = sim.mom_state
	var snitch := false
	for h in sim.helpers:
		if h.snitch > 0.0:
			snitch = true
	_seen.append({"t": sim.time, "state": sim.mom_state, "kind": sim.hint_kind, "mom_pos": sim.mom_pos,
		"at_island": sim.mom_at_island(), "activity": sim.activity, "snitch": snitch, "hint_at": sim.time})
	while _seen.size() > 1 and _seen[1].t <= sim.time - reaction:
		_seen.pop_front()


func _perceived() -> Dictionary:
	return _seen[0]


func _danger(view: Dictionary) -> bool:
	match view.state:
		Sim.Mom.HINT:
			if view.kind != "feint":
				return true
			if _last_hint_changed(view):
				_hint_believed = rng.randf() > attentive
			return _hint_believed
		Sim.Mom.TURN, Sim.Mom.LOOK, Sim.Mom.ROUND:
			return true
	_hint_id = 0.0
	return false


## Vrai la première fois qu'on remarque un indice donné.
func _last_hint_changed(view: Dictionary) -> bool:
	if _hint_id == 0.0:
		_hint_id = view.t
		return true
	return false
