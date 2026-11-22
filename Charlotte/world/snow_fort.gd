class_name SnowFort
extends Node2D
## The snow fort in the middle lane (quest "fort", winter, after New Year's Day; Julien), next to the twins:
##   1. Alphée and Constance want to build one: Charlotte packs it block by block (`BUILD` clicks on it,
##      `flags.fort_blocks`), the twins cheering her on;
##   2. finished, Billie and Auguste come round with their own pile of snow and attack: a snowball fight. They pop up from
##      behind their pile to throw; she clicks one while he or she is up and her snowball hits (`HITS` of them win), a miss
##      lands in their pile. Their snowballs splat on the fort. They give up, laughing: the quest is done, and the fort stays
##      in the lane for the rest of the winter.
## As a node: the fort itself (drawn by stage), and during the fight Billie and Auguste behind their pile.

const QUEST := "fort"
const STEP := "fort_step"
const BLOCKS := "fort_blocks"
const HEADING := "❄  Le fort de neige"
const BUILD := 6
const HITS := 5
## Where Billie and Auguste's pile stands, right of the fort, and where Charlotte throws from, left of it.
const ENEMY_DX := 430.0
const THROW_DX := -120.0
## How much the camera looks ahead during the fight, so both sides are in view.
const LOOK_AHEAD := 280.0
## The fort's blocks are drawn this much bigger than `BLOCKS_AT`.
const FORT_SCALE := 1.35
## How high Billie and Auguste stand behind their pile: ducked (the top of a tuque showing) and up to throw.
const DOWN_Y := 64.0
const UP_Y := -6.0
const BUILD_LINES := [
	["Un premier bloc !", "Tasse-le ben comme il faut !"],
	["Un autre !", "Y commence à être beau !"],
	["Encore un !", "Fais-le plus haut !"],
	["Le mur monte !", "On va être cachées derrière !"],
	["Les créneaux !", "Comme un vrai château !"],
	["Pis le dernier !", "Y est fini ! Le plus beau fort de la ruelle !"],
]
const HIT_LINES := ["Ayoye ! Dans ma tuque !", "Hi hi ! Tu m'as eu !", "Pas dans le cou, c'est frette !", "Encore ?! T'es très bonne !", "Bon, bon, bon…"]

var scene: Node2D
var control: PlayerControl
var _stage := 0
var _enemies: Array[Character] = []
var _up: Array[float] = [0.0, 0.0]
var _pile: Node2D
var _fighting := false
var _hits := 0
var _next_pop := 1.5
var _next_throw := 2.5
var _rng := RandomNumberGenerator.new()


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func blocks() -> int:
	return int(GameState.flags.get(BLOCKS, 0))


## The twins can ask: winter, the quest free, and she knows them.
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST) and Twins.met()


## The fort (or its spot) is in the lane: winter, from the moment it can be asked for.
static func standing() -> bool:
	return Season.is_winter() and (can_start() or Quests.active(QUEST) or Quests.done(QUEST))


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(BLOCKS)


static func hint() -> String:
	match step():
		1:
			return "Bâtis le fort de neige avec les jumelles, dans la ruelle du milieu (%d blocs sur %d)." % [blocks(), BUILD]
		2:
			return "Bataille de balles de neige ! Clique sur Billie ou Auguste quand ils sortent la tête de derrière leur tas."
	return str(Quests.ALL[QUEST].hint)


func _ready() -> void:
	_rng.seed = 4242
	_stage = BUILD if Quests.done(QUEST) else blocks()
	if step() == 2:
		_start_fight.call_deferred()


func _process(delta: float) -> void:
	if not _fighting:
		return
	# Billie and Auguste duck behind their pile and pop up to throw.
	_next_pop -= delta
	if _next_pop <= 0.0:
		_next_pop = _rng.randf_range(1.0, 1.8)
		var who := _rng.randi_range(0, 1)
		if _up[who] <= 0.0:
			_up[who] = _rng.randf_range(1.3, 1.8)
	for i in 2:
		_up[i] = maxf(_up[i] - delta, 0.0)
		var kid := _enemies[i]
		var target := UP_Y if _up[i] > 0.0 else DOWN_Y
		kid.position.y = move_toward(kid.position.y, target, delta * 420.0)
	_next_throw -= delta
	if _next_throw <= 0.0:
		_next_throw = _rng.randf_range(1.6, 2.6)
		for i in 2:
			if _up[i] > 0.4:
				_throw(_enemies[i].global_position + Vector2(-20, -150), global_position + Vector2(_rng.randf_range(-40.0, 40.0), -40.0), false)
				break


# ── Building ──────────────────────────────────────────────────

## One block more: she packs it on, the twins say something; the last one brings the fight.
func add_block(charlotte: Character, twins_say: Callable) -> void:
	if step() != 1 or _stage >= BUILD:
		return
	charlotte.facing = 1 if position.x > charlotte.position.x else -1
	charlotte.pet(0.9, 0.6)
	Sfx.play("step_snow", global_position)
	var line: Array = BUILD_LINES[_stage]
	_stage += 1
	GameState.flags[BLOCKS] = _stage
	queue_redraw()
	Bubble.say(scene, charlotte.position + Vector2(0, -190), line[0], 2.0)
	var later := create_tween()
	later.tween_interval(1.6)
	later.tween_callback(func() -> void: twins_say.call(line[1]))
	if _stage >= BUILD:
		set_step(2)
		later.tween_interval(2.4)
		later.tween_callback(_start_fight)


# ── The fight ─────────────────────────────────────────────────

func _start_fight() -> void:
	if _fighting:
		return
	Notebook.announce("step", "Bataille de balles de neige contre Billie pis Auguste !", HEADING)
	var looks := [CharacterLook.billie(), CharacterLook.auguste()]
	for i in 2:
		Season.dress_for_weather(looks[i])
		var kid := Character.new()
		kid.look = looks[i]
		kid.facing = -1
		kid.position = Vector2(ENEMY_DX + 30.0 + i * 90.0, DOWN_Y)
		kid.scale = Vector2.ONE * StreetScene.CHAR_SCALE
		add_child(kid)
		_enemies.append(kid)
	_pile = _Pile.new()
	_pile.position = Vector2(ENEMY_DX + 75.0, 6.0)
	add_child(_pile)
	for i in 2:
		var kid := _enemies[i]
		scene.add_child(DoorSpot.make(Rect2(global_position + Vector2(ENEMY_DX + 30.0 + i * 90.0 - 45.0, -230.0), Vector2(90, 230)),
			_aim.bind(i), global_position.x + THROW_DX))
	_look_ahead(LOOK_AHEAD)
	var hello := create_tween()
	hello.tween_callback(func() -> void: _kid_says(0, "Ah ben ! Un fort ? On vous attaque !"))
	hello.tween_interval(2.4)
	hello.tween_callback(func() -> void: _kid_says(1, "Bataille de balles de neige !"))
	hello.tween_interval(1.6)
	hello.tween_callback(func() -> void: _fighting = true)


# Her snowball at Billie (0) or Auguste (1): a hit if he or she is up, else into their pile.
func _aim(i: int) -> void:
	if not _fighting:
		return
	var charlotte: Character = scene.get("_charlotte")
	charlotte.facing = 1
	charlotte.pet(0.5, 0.0)
	var kid := _enemies[i]
	var up: bool = _up[i] > 0.1
	var to := kid.global_position + (Vector2(0, -130) if up else Vector2(-40, 30))
	_throw(charlotte.position + Vector2(20, -120), to, true, func() -> void:
		if not up or not _fighting:
			return
		_hits += 1
		kid.express("laugh", 1.4)
		_up[i] = 0.0
		_kid_says(i, HIT_LINES[mini(_hits - 1, HIT_LINES.size() - 1)])
		if _hits >= HITS:
			_end_fight())


func _end_fight() -> void:
	_fighting = false
	for i in 2:
		_up[i] = 0.0
		_enemies[i].position.y = UP_Y
	var steps := create_tween()
	steps.tween_interval(1.4)
	steps.tween_callback(func() -> void: _kid_says(0, "Correct, correct, on se rend !"))
	steps.tween_interval(2.4)
	steps.tween_callback(func() -> void: _kid_says(1, "Vous êtes trop fortes !"))
	steps.tween_interval(2.4)
	steps.tween_callback(func() -> void:
		var charlotte: Character = scene.get("_charlotte")
		charlotte.express("laugh", 2.0)
		Bubble.say(scene, charlotte.position + Vector2(0, -190), "Bonne bataille ! On refait ça demain ?", 2.6))
	steps.tween_interval(2.6)
	steps.tween_callback(func() -> void:
		Sfx.play("chime")
		_look_ahead(0.0)
		Quests.complete(QUEST)
		for kid in _enemies:
			kid.facing = 1
			kid.is_walking = true)
	# They go home down the lane.
	for kid in _enemies:
		steps.parallel().tween_property(kid, "position:x", kid.position.x + 700.0, 5.0)
	steps.tween_callback(func() -> void:
		for kid in _enemies:
			kid.queue_free()
		_enemies.clear())


# The scene's camera looks `by` px ahead of Charlotte (eased), to keep both sides of the fight in view.
func _look_ahead(by: float) -> void:
	var cam: Camera2D = scene.get("_camera")
	if cam:
		create_tween().tween_property(cam, "offset:x", by, 1.2).set_trans(Tween.TRANS_SINE)


func _kid_says(i: int, text: String) -> void:
	var kid := _enemies[i]
	kid.express("talk", 1.6)
	Bubble.say(scene, kid.global_position + Vector2(0, -150), text, 2.2)


# A snowball from `from` to `to` (world), on an arc; a puff where it lands; `then` when it does.
func _throw(from: Vector2, to: Vector2, hers: bool, then := Callable()) -> void:
	var ball := _Ball.new()
	ball.position = from
	scene.add_child(ball)
	Sfx.play("swoosh", from, -6.0, 1.3 if hers else 1.1)
	var flight := create_tween()
	flight.tween_method(func(u: float) -> void:
		ball.position = from.lerp(to, u) + Vector2(0, -sin(u * PI) * 80.0), 0.0, 1.0, 0.6)
	flight.tween_callback(func() -> void:
		ball.burst()
		Sfx.play("step_snow", to)
		if then.is_valid():
			then.call())


# ── Pictures ────────────────────────────────────────────────

# The fort: blocks of packed snow, lit from the upper left, a blue shade on their right and along their joints; built
# block by block (`_stage`), crenels on top once it is finished. Its foot is at y 0, its middle at x 0.
const BLOCKS_AT := [Rect2(-96, -30, 64, 30), Rect2(-30, -30, 64, 30), Rect2(36, -30, 64, 30),
	Rect2(-64, -58, 64, 28), Rect2(2, -58, 64, 28), Rect2(-96, -84, 26, 26)]


func _draw() -> void:
	# The trampled snow where the fort goes.
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, 150.0, Color("#DCE5EE"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * FORT_SCALE)
	for i in mini(_stage, BLOCKS_AT.size()):
		_block(BLOCKS_AT[i])
	if _stage >= BUILD:
		for x in [-30.0, 36.0, 70.0]:
			_block(Rect2(x, -84, 26, 26))


# A block of packed snow: soft rounded corners, white on top, a cool shade on its right and at its foot, a little uneven.
func _block(r: Rect2) -> void:
	var round := StyleBoxFlat.new()
	round.bg_color = Color("#FBFDFF")
	round.set_corner_radius_all(7)
	round.border_color = Color("#C9D6E4")
	round.set_border_width_all(2)
	round.shadow_color = Color(0.55, 0.65, 0.8, 0.25)
	round.shadow_size = 2
	draw_style_box(round, r)
	draw_rect(Rect2(r.position + Vector2(r.size.x * 0.68, 3), Vector2(r.size.x * 0.28, r.size.y - 6)), Color(0.86, 0.9, 0.96, 0.8))
	draw_rect(Rect2(r.position + Vector2(4, r.size.y - 6), Vector2(r.size.x - 8, 3)), Color(0.8, 0.86, 0.93, 0.8))
	draw_circle(r.position + Vector2(r.size.x * 0.3, 6), 3.0, Color.WHITE)


## Billie and Auguste's pile of snow, in front of them.
class _Pile:
	extends Node2D

	func _draw() -> void:
		var top := PackedVector2Array()
		for i in 13:
			var x := -110.0 + i * 18.0
			top.append(Vector2(x, -42.0 - sin(i / 12.0 * PI) * 30.0 + sin(i * 1.7) * 4.0))
		var body := top.duplicate()
		body.append(Vector2(106, 4))
		body.append(Vector2(-110, 4))
		draw_colored_polygon(body, Color("#EEF3F8"))
		draw_polyline(top, Color.WHITE, 3.0, true)
		draw_line(Vector2(-100, 2), Vector2(100, 2), Color("#C7D5E6"), 4.0)


## A snowball in flight, then a puff of snow.
class _Ball:
	extends Node2D
	var _burst := -1.0

	func burst() -> void:
		_burst = 0.0

	func _process(delta: float) -> void:
		if _burst >= 0.0:
			_burst += delta
			if _burst > 0.4:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		if _burst < 0.0:
			draw_circle(Vector2.ZERO, 7.0, Color("#FFFFFF"))
			draw_circle(Vector2(2, 2), 4.0, Color("#DCE6F0"))
			return
		for k in 8:
			var a := TAU * k / 8.0
			draw_circle(Vector2(cos(a), sin(a)) * 22.0 * _burst / 0.4, 4.0 * (1.0 - _burst / 0.4), Color(1, 1, 1, 1.0 - _burst / 0.4))
