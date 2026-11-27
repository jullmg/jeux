class_name TableTalk
extends RefCounted
## Les conversations à table (et au party) : Papa, Charlotte, Maman assise et la visite jasent pendant le repas.
## Rien que de l'affichage : les règles n'en savent rien et leur hasard n'est pas touché. Pour ne jamais tromper la
## joueuse, la visite ne parle que lorsqu'elle jase pour vrai (sa bulle « … » ; quand elle regarde, elle se tait), et
## Charlotte, pas pendant qu'elle glisse un morceau.

## Le silence entre deux conversations, en secondes : Papa parle souvent.
const REST := [2.2, 4.5]
## Une réplique reste au moins ce temps-là, plus selon sa longueur.
const LINE_MIN := 1.8
const LINE_MAX := 3.6
## On jase avec qui est assez proche.
const NEAR := 3.2
## Une conversation sur trois devient une réplique seule, pour varier.
const SOLO_CHANCE := 0.3

var sim: Sim
var stage: Stage
var hud: Hud
var rng: RandomNumberGenerator
var _lines: Array = []
var _wait := 0.0
var _rest := 0.0
var _last: PersonView
var _prefer := ""
var _used: Dictionary = {}
## Le moment et le plat de la mission, pour choisir ce qui se dit.
var _tags: Array = []
## À table, dans la salle à manger : les conversations de tous les jours (sans « sur ») ne se disent que là.
var _at_table := false


func _init(sim_: Sim, stage_: Stage, hud_: Hud, rng_: RandomNumberGenerator) -> void:
	sim = sim_
	stage = stage_
	hud = hud_
	rng = rng_
	_tags = [str(sim.level.get("moment", "")), str(sim.level.get("plat", ""))]
	_at_table = sim.map.id == "salle_a_manger"
	_rest = rng.randf_range(2.5, 4.0)


## Un invité commence à jaser : une conversation avec lui part bientôt.
func nudge(who: String) -> void:
	if _lines.is_empty():
		_prefer = who
		_rest = minf(_rest, 0.4)


func step(delta: float) -> void:
	if sim.over:
		return
	if not _lines.is_empty():
		_wait -= delta
		if _wait > 0.0 or not _calm():
			return
		var line: Array = _lines.pop_front()
		if not _free(line[0]):
			# L'invité s'est remis à regarder, Charlotte glisse un morceau… le moment est passé.
			_lines.clear()
			_rest = rng.randf_range(REST[0], REST[1])
			return
		var next: String = _lines[0][0] if not _lines.is_empty() else ""
		_say(line[0], line[1], next)
		if _lines.is_empty():
			_rest = _wait + rng.randf_range(REST[0], REST[1])
		return
	_rest -= delta
	if _rest > 0.0 or not _calm() or hud.has_bubbles():
		return
	_start()


## Personne ne surveille ni ne chicane : on peut jaser sans cacher ce qui compte.
func _calm() -> bool:
	if sim.activity == "chicane" or sim.snitching():
		return false
	return sim.mom_state == Sim.Mom.BUSY or sim.mom_state == Sim.Mom.WALK


func _start() -> void:
	var free := _free_people()
	if free.is_empty():
		_rest = 1.0
		return
	var options: Array[int] = []
	var fresh: Array[int] = []
	for i in Texts.TABLE_TALK.size():
		var talk: Dictionary = Texts.TABLE_TALK[i]
		if not _fits(talk, free):
			continue
		if _prefer != "" and not _speakers(talk).has(_prefer):
			continue
		options.append(i)
		if not _used.has(i):
			fresh.append(i)
	_prefer = ""
	var pool := fresh if not fresh.is_empty() else options
	if pool.is_empty() or rng.randf() < SOLO_CHANCE:
		_solo(free)
		return
	var pick: int = pool[rng.randi_range(0, pool.size() - 1)]
	_used[pick] = true
	_lines = Texts.TABLE_TALK[pick].lines.duplicate()
	_wait = 0.0


## Une réplique seule, Papa d'abord s'il est là.
func _solo(free: Dictionary) -> void:
	var who: String = "papa" if free.has("papa") and rng.randf() < 0.7 else free.keys()[rng.randi_range(0, free.size() - 1)]
	var lines: Array = []
	var own: Dictionary = Texts.TABLE_SOLO.get(who, {})
	for tag: String in ([""] if _at_table else []) + _tags:
		lines.append_array(own.get(tag, []))
	if lines.is_empty():
		_rest = 1.0
		return
	_say(who, lines[rng.randi_range(0, lines.size() - 1)], "")
	_rest = _wait + rng.randf_range(REST[0], REST[1])


func _say(who: String, text: String, next: String) -> void:
	var view := _view(who)
	if view == null:
		return
	var seconds := clampf(0.9 + text.length() / 17.0, LINE_MIN, LINE_MAX)
	# Une seule bulle de conversation à la fois : on la lit comme un ping-pong.
	if _last and _last != view:
		hud.hush(_last)
	_last = view
	hud.bubble(view, text, seconds, true)
	var listener := _view(next) if next != "" else _nearest(view)
	stage.talk(view, listener, seconds + 0.6)
	_wait = seconds * 0.92


## Qui peut parler en ce moment, et où il est : nom → position au sol.
func _free_people() -> Dictionary:
	var out := {}
	for s in sim.seated:
		if _free(s.who):
			out[s.who] = sim.map.seats[s.seat].hips
	for w in sim.walkers:
		if _free(w.who):
			out[w.who] = w.pos
	if _free("maman"):
		out["maman"] = sim.mom_pos
	return out


func _free(who: String) -> bool:
	if who == "maman":
		return sim.watcher == "maman" and not sim.mom_out and sim.mom_seated() and sim.mom_state == Sim.Mom.BUSY \
			and sim.activity in ["manger", "jaser", "film"]
	for s in sim.seated:
		if s.who == who:
			match s.role:
				"decor":
					return who != sim.watcher
				"complice":
					return s.state == "eat" and s.snitch <= 0.0
				"temoin":
					return s.state == "jase" and s.snitch <= 0.0
	for w in sim.walkers:
		if w.who == who:
			return w.state == "pause" and w.snitch <= 0.0
	return false


static func _speakers(talk: Dictionary) -> Array:
	var out: Array = []
	for line: Array in talk.lines:
		if not out.has(line[0]):
			out.append(line[0])
	return out


## Tout le monde de la conversation est là, libre, assez proche ; la visite jase encore assez longtemps pour placer
## ses répliques.
func _fits(talk: Dictionary, free: Dictionary) -> bool:
	var tags: Array = talk.sur
	if tags.is_empty() and not _at_table:
		return false
	if not tags.is_empty() and not (tags.has(_tags[0]) or tags.has(_tags[1])):
		return false
	var who := _speakers(talk)
	for w: String in who:
		if not free.has(w):
			return false
	for w: String in who:
		for o: String in who:
			if (free[w] as Vector2).distance_to(free[o]) > NEAR:
				return false
	# Le temps qui reste à jaser à chaque invité (assis ou debout) doit couvrir sa dernière réplique.
	var at := 0.0
	for line: Array in talk.lines:
		var left := _chat_left(line[0])
		if left < at + 0.6:
			return false
		at += clampf(0.9 + str(line[1]).length() / 17.0, LINE_MIN, LINE_MAX) * 0.92
	return true


## Combien de temps quelqu'un va encore jaser (sans fin pour la famille).
func _chat_left(who: String) -> float:
	for s in sim.seated:
		if s.who == who and s.role == "temoin":
			return s.t
	for w in sim.walkers:
		if w.who == who:
			return w.t
	return INF


func _view(who: String) -> PersonView:
	if who == "maman":
		return stage.mom if sim.watcher == "maman" else null
	return stage.people.get(who)


## À qui parle quelqu'un qui parle tout seul : la personne visible la plus proche.
func _nearest(view: PersonView) -> PersonView:
	var best: PersonView = null
	var best_d := INF
	var all: Array = stage.people.values()
	all.append(stage.mom)
	for p: PersonView in all:
		if p == view or not p.visible:
			continue
		var d := p.position.distance_to(view.position)
		if d < best_d:
			best_d = d
			best = p
	return best if best_d < NEAR else null
