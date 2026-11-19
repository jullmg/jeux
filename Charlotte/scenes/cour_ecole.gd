extends StreetScene
# The schoolyard of école Saint-Jean-de-Brébeuf at recess (the quest "ecole", world/school.gd): seen from the yard, the school's
# back wall with its pupils' door and the bell, a chain-link fence at each end with the street beyond (the gate Maman brings
# her through on the left), the painted games on the asphalt (under snow in winter, when the plough's snow hill stands at the
# right end), the climbing frame, a bench, the basketball hoop. Her classmates play (tag, skipping, a ball, the slide or the
# snow hill), a supervisor keeps an eye on them, and Alyzée, new at school, sits alone on the bench.
# On a Saturday in December the school sells Christmas trees in the yard (`TreeSale`, quest "sapin"): Papa brings her.
# Maman says goodbye at the gate on step 1 → 2 of the quest; meeting Alyzée and playing tag rings the bell; everyone goes in
# through the door and "Après l'école…" takes her home. Reuses StreetScene's helpers (sky, Charlotte, camera, wind, grade)
# but builds its own scene, like the lanes.
# After class, the service de garde can come out here to slide (`Sledding`, quest "glissade"): then Jade stands by the door
# instead of the supervisor, there is no bell and no Alyzée (she stays in), and the snow hill is Charlotte's to slide down.

const YARD_W := 2600.0
## The school's back wall (world x of its left end, its width) and the line where the yard meets it.
const WALL_X := 250.0
const WALL_W := 2100.0
const WALL_FOOT := 566.0
## The pupils' door (world x of its middle) and the gate in the left fence.
const DOOR_X := 1580.0
const GATE_X := 125.0
const BENCH_X := 1250.0
const FRAME_X := 850.0
const HILL_X := 1990.0
const HOOP_X := 2190.0
## Where the classmates stand, a little behind Charlotte (so she passes in front of them), and the yard's own people.
const KID_Y := 624.0
const START_X := 340.0
## How long the children play before the bell on an ordinary school day (seconds).
const RECESS := 35.0

const SUPERVISOR_LINES := ["Pas de bousculade, les amis !", "On reste dans la cour, hein !", "Attention en haut de la glissoire !"]
const WINTER_SUPERVISOR := "Pas de balles de neige, les amis !"
const JADE_LINES := ["Un à la fois sur la butte, les amis !", "Glisse, Chachoue ! Je te regarde.", "On garde nos mitaines, hein !"]
## The sled under her: its size, and how high it holds her hips over the snow (world px).
const SLED_SCALE := 0.8
const SLED_SEAT := 0.0
## How far over the snow the sled's rim comes (world px): her boots' height once she sits, so the tray hides her coat's hem.
const SLED_RIM := 10.0
## Charlotte's way up and down the hill (world): from the top, down its worn track on the right, out onto the flat.
const SLIDE_PATH := [Vector2(2190, 462), Vector2(2260, 486), Vector2(2320, 544), Vector2(2370, 590), Vector2(2400, 612),
	Vector2(2440, 632), Vector2(2490, 638)]

var _alyzee: Alyzee
var _kids: Array[_Kid] = []
var _supervisor: _Kid
var _mom: Character
var _bell_rung := false
var _recess := 0.0
## The garde is out sliding (`Sledding.in_yard()`), not recess.
var _garde := false
## A Saturday: the school's Christmas tree sale (`XmasTree`, step 2), no pupils.
var _sale: TreeSale
var _sled: Sprite2D
var _sliding := false


func _ready() -> void:
	street_key = "cour_ecole"
	_garde = Sledding.in_yard()
	seed_value = 7313
	_rng.seed = seed_value
	_street_width = YARD_W
	add_child(SkyBackdrop.new())
	Skyline.build(self, YARD_W, VIEW.x)
	DepthBlur.far(self)
	add_child(Birds.new())
	_build_backdrop()
	var ground := _Ground.new()
	ground.seed_value = seed_value
	add_child(ground)
	_build_furniture()
	if XmasTree.step() == 2:
		_sale = TreeSale.new()
		_sale.scene = self
		add_child(_sale)
	else:
		_build_classmates()
		if not _garde:
			_build_alyzee()
	var start_x := START_X
	# A saved game, or the debug menu, brings her back where she was.
	if not is_nan(Transition.street_x):
		start_x = Transition.street_x
		Transition.street_x = NAN
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_start = start_x
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	_control.bounds = Vector2(80.0, YARD_W - 80.0)
	_control.walk_top = WALL_FOOT - 260.0
	add_child(_control)
	if _alyzee:
		_alyzee.control = _control
	_build_doors()
	var saver := Saver.new()
	saver.who = _charlotte
	add_child(saver)
	var kick := LeafKick.new()
	kick.walker = _charlotte
	add_child(kick)
	add_child(_wind)
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = int(YARD_W)
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW.y)
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	_follow_charlotte()
	_camera.reset_smoothing()
	_build_grade()
	Season.add_weather(self)
	Sfx.ambience(self)
	Music.play(_music())
	Transition.fade_in(self)
	if _sale:
		_sale.build_spots()
	elif School.step() == 1:
		_mom_says_goodbye()
	elif _garde:
		_build_sledding()
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _process(delta: float) -> void:
	_follow_charlotte()
	# On an ordinary school day (Alyzée is already her friend) the bell rings by itself after a while of play.
	if School.step() == 2 and Alyzee.met() and not _bell_rung and _control.enabled and not _control.hands_off:
		_recess += delta
		if _recess > RECESS:
			_ring_the_bell()


# ── What stands in the yard ─────────────────────────────────────

# Far to near: the street beyond the fences and its trees, the fences (the gate on the left), the school's back wall.
func _build_backdrop() -> void:
	var art := RandomNumberGenerator.new()
	art.seed = seed_value + 1
	var ends := [Vector2(0.0, WALL_X), Vector2(WALL_X + WALL_W, YARD_W)]
	for span: Vector2 in ends:
		var beyond := _sprite(SchoolYardArt.beyond(span.y - span.x + 40.0, art), 1.0)
		beyond.position = Vector2(span.x - 20.0, WALL_FOOT - 300.0)
		add_child(beyond)
	var trees := RandomNumberGenerator.new()
	trees.seed = seed_value + 2
	var leaf := Season.falling_texture()
	for i in 2:
		var k := 0.5 if i == 0 else 0.56
		var foot := Vector2(70.0 if i == 0 else YARD_W - 110.0, WALL_FOOT - 4.0)
		var tree := _sprite(PropArt.tree(trees), k)
		tree.position = foot - Vector2(190.0, 780.0) * k
		tree.material = _sway(6.0, i * 2.3)
		add_child(tree)
		add_child(_falling_leaves(leaf, tree.position + Vector2(190, 250) * k))
	for span: Vector2 in ends:
		var gate := GATE_X - span.x if span.x == 0.0 else -1.0
		var fence := _sprite(SchoolYardArt.fence(span.y - span.x, gate), 1.0)
		fence.position = Vector2(span.x, WALL_FOOT - 230.0)
		add_child(fence)
	var wall := _sprite(SchoolYardArt.back_wall(WALL_W, DOOR_X - WALL_X, art), 1.0)
	wall.position = Vector2(WALL_X, WALL_FOOT - SchoolYardArt.WALL_H)
	add_child(wall)
	# The plate over the pupils' door (words as a label: SVG text doesn't render).
	var plate := ColorRect.new()
	plate.color = Color("#1D4F91")
	plate.size = Vector2(150, 22)
	plate.position = Vector2(DOOR_X - 75.0, WALL_FOOT - SchoolYardArt.DOOR_H - 78.0)
	add_child(plate)
	_label("ENTRÉE DES ÉLÈVES", plate.position + plate.size / 2.0, plate.size, 11, Color.WHITE, Color(1, 1, 1, 0))


func _build_furniture() -> void:
	# A bike rack by the gate, with a bike or two out of winter.
	var rack := _sprite(PropArt.rack(), 0.8)
	rack.position = Vector2(GATE_X + 120.0, WALL_FOOT + 30.0 - 90.0 * 0.8)
	add_child(rack)
	if not Season.is_winter():
		var bikes := RandomNumberGenerator.new()
		bikes.seed = seed_value + 5
		for hoop in [42.0, 182.0]:
			var bike := _sprite(PropArt.bike(bikes), 0.85)
			bike.position = Vector2(rack.position.x + hoop * 0.8 - 75.0 * 0.85, WALL_FOOT + 32.0 - 90.0 * 0.85)
			add_child(bike)
	var frame := _sprite(SchoolYardArt.climbing_frame(), 1.0)
	frame.position = Vector2(FRAME_X, 612.0 - 260.0)
	add_child(frame)
	if Season.is_winter():
		var hill := _sprite(SchoolYardArt.snow_hill(), 1.0)
		hill.position = Vector2(HILL_X, 616.0 - 170.0)
		add_child(hill)
	else:
		var hoop := _sprite(SchoolYardArt.hoop(), 1.0)
		hoop.position = Vector2(HOOP_X - 40.0, 606.0 - 330.0)
		add_child(hoop)
	var bench := _sprite(SchoolYardArt.bench(), 1.0)
	bench.position = Vector2(BENCH_X, KID_Y - 64.0)
	add_child(bench)


# Her classmates at play, all a little behind the line she walks on, each with a line or two when she clicks them.
func _build_classmates() -> void:
	var looks := RandomNumberGenerator.new()
	looks.seed = seed_value + 3
	var winter := Season.is_winter()
	var plan := [
		{"x": 520.0, "mode": "tag", "lines": ["Tague ! T'es gelée !", "Chu trop vite pour toi !"]},
		{"x": 700.0, "mode": "tag", "lines": ["Attends, chu essoufflé !", "On joue à la tague gelée ?"]},
		{"x": 1010.0, "y": 612.0 - 112.0, "mode": "idle", "lines": ["Chu le roi de la montagne !", "Regarde, je vais glisser !"]},
		{"x": 1830.0, "mode": "rope", "lines": ["Un, deux, trois, quatre… j'en suis à cinquante !", "Veux-tu tourner la corde ?"]},
	]
	if winter and _garde:
		# The hill is Charlotte's: this one watches from its foot.
		plan.append({"x": HILL_X - 70.0, "mode": "idle", "lines": ["Vas-y, Chachoue ! Glisse !", "Wouhou ! T'es allée vite en malade !"]})
	elif winter:
		plan.append({"x": HILL_X + 200.0, "y": 616.0 - 156.0, "mode": "slide",
			"lines": ["Wouhou ! Ça glisse en malade !", "Mes pantalons de neige sont tout mouillés !"]})
	else:
		plan.append({"x": HOOP_X + 30.0, "mode": "ball", "lines": ["Lance-moi le ballon !", "J'ai fait un panier, t'as-tu vu ?"]})
	plan.append({"x": 1130.0, "mode": "idle", "lines": ["As-tu fait tes devoirs ?", "Ma dent bouge, regarde !"]})
	for spot: Dictionary in plan:
		var kid := _Kid.new()
		var look := CharacterLook.random(looks, "child")
		Season.dress_for_weather(look)
		kid.look = look
		kid.mode = spot.mode
		kid.lines = spot.lines
		kid.position = Vector2(spot.x, spot.get("y", KID_Y))
		kid.scale = Vector2.ONE * CHAR_SCALE
		kid.facing = 1 if looks.randf() < 0.5 else -1
		add_child(kid)
		_kids.append(kid)
	# The two playing tag chase each other between the hopscotch and the climbing frame.
	_kids[0].partner = _kids[1]
	_kids[1].partner = _kids[0]
	_kids[0].it = true
	for i in 2:
		_kids[i].lo = 420.0
		_kids[i].hi = 820.0
	_kids[4].hill = Vector2(HILL_X, 616.0)
	# The supervisor, by the door: a grown-up in a long coat with her whistle.
	_supervisor = _Kid.new()
	var grown := CharacterLook.random(looks, "adult")
	grown.outfit = "coat"
	grown.outfit_color = Color("#2E4A7A")
	grown.facial_hair = ""
	grown.lashes = true
	Season.dress_for_weather(grown)
	_supervisor.look = grown
	_supervisor.mode = "idle"
	_supervisor.lines = SUPERVISOR_LINES + ([WINTER_SUPERVISOR] if winter else [])
	if _garde:
		# Out with the service de garde: Jade, in her winter coat.
		var jade := CharacterLook.jade()
		Season.dress_for_weather(jade)
		_supervisor.look = jade
		_supervisor.lines = JADE_LINES
	_supervisor.position = Vector2(DOOR_X + 130.0, KID_Y - 4.0)
	_supervisor.scale = Vector2.ONE * CHAR_SCALE
	_supervisor.facing = -1
	_supervisor.head = -440.0
	add_child(_supervisor)


func _build_alyzee() -> void:
	_alyzee = Alyzee.new()
	_alyzee.position = Vector2(BENCH_X + 100.0, KID_Y)
	_alyzee.scale = Vector2.ONE * CHAR_SCALE
	_alyzee.bounds = Vector2(380.0, DOOR_X - 60.0)
	if Alyzee.met():
		_alyzee.position.x = BENCH_X + 230.0
	add_child(_alyzee)
	_alyzee.played.connect(_ring_the_bell)
	add_child(QuestMark.make(_alyzee.position + Vector2(0, -150), _alyzee.waiting))


# The gate (back home, once school is over) and the pupils' door (not before the bell).
func _build_doors() -> void:
	add_child(DoorSpot.make(Rect2(GATE_X - 60.0, WALL_FOOT - 220.0, 120.0, 230.0), _leave_by_gate, GATE_X + 60.0))
	add_child(DoorSpot.make(Rect2(DOOR_X - 60.0, WALL_FOOT - 140.0, 120.0, 150.0), func() -> void:
		if _garde:
			_charlotte_says("Encore une glissade avant de rentrer !")
			return
		if _sale:
			_charlotte_says("C'est fermé, c'est samedi !\nOn est venus pour les sapins.")
			return
		if not _bell_rung:
			_charlotte_says("La cloche a pas encore sonné !\nC'est encore la récré !")
			return
		_go_to_class(), DOOR_X))
	add_child(QuestMark.make(Vector2(DOOR_X, WALL_FOOT - 170.0), func() -> bool: return _bell_rung and _control.enabled))


# ── Sliding with the service de garde ───────────────────────────

func _build_sledding() -> void:
	add_child(DoorSpot.make(Rect2(HILL_X + 40.0, 616.0 - 170.0, 380.0, 190.0), _slide, SLIDE_PATH[5].x))
	add_child(QuestMark.make(Vector2(HILL_X + 200.0, 616.0 - 220.0), func() -> bool:
		return Sledding.step() == 2 and not _sliding and _control.enabled))
	var hello := create_tween()
	hello.tween_interval(1.0)
	hello.tween_callback(func() -> void: _supervisor.say("Allez, Chachoue ! La butte est à toi !\nGlisse trois fois, pis on rentre.", 3.4))


# Up the hill on foot (the sled in her arms), sit on it at the top, down the track on her own speed and out onto the flat.
func _slide() -> void:
	if _sliding or Sledding.step() != 2:
		return
	_sliding = true
	_control.hands_off = true
	var path: Array = SLIDE_PATH
	var climb := create_tween()
	_charlotte.facing = -1
	_charlotte.is_walking = true
	var up := path.slice(0, 6)
	up.reverse()
	climb.tween_method(func(u: float) -> void: _charlotte.position = _along(up, u), 0.0, 1.0, 2.4)
	climb.tween_callback(func() -> void:
		_charlotte.is_walking = false
		_charlotte.facing = 1
		# The sled out of her arms and under her.
		_charlotte.carry(null)
		_sled = Sprite2D.new()
		_sled.texture = Sledding.sled()
		_sled.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_sled.scale = Vector2.ONE * SLED_SCALE
		# In front of her: she sits down in the tray, its rim at her hips (the canvas's middle line, y 30).
		_sled.offset = Vector2(24, 0)
		add_child(_sled)
		_charlotte.sitting = true
		_charlotte.sit_on_ground = true
		# Her hips in the tray, its rim at her waist hiding her coat's hem.
		_charlotte.seat_h = SLED_SEAT
		_follow_sled())
	climb.tween_interval(0.6)
	climb.tween_callback(func() -> void:
		_charlotte.express("grin", 2.0)
		_charlotte_says("Wiiiii !")
		Sfx.play("swoosh", _charlotte.position))
	climb.tween_method(func(u: float) -> void:
		_charlotte.position = _along(path, ease(u, 1.7))
		_follow_sled(), 0.0, 1.0, 1.8)
	climb.tween_interval(0.5)
	climb.tween_callback(_landed)


# Sled under her: on the slope's angle, a little under her feet (the tray she sits in).
func _follow_sled() -> void:
	if _sled == null:
		return
	var at := _charlotte.position
	var ahead := _along(SLIDE_PATH, clampf(_progress(at) + 0.04, 0.0, 1.0))
	var back := _along(SLIDE_PATH, clampf(_progress(at) - 0.04, 0.0, 1.0))
	_sled.rotation = clampf((ahead - back).angle(), -0.45, 0.45) if ahead.distance_to(back) > 1.0 else 0.0
	# Its rim at her boots, its bottom a little into the snow.
	_sled.position = at + Vector2(0, -SLED_RIM).rotated(_sled.rotation)


func _landed() -> void:
	_charlotte.sitting = false
	_charlotte.sit_on_ground = false
	_charlotte.seat_h = 0.0
	_charlotte.position.y = CHARLOTTE_Y
	if _sled:
		_sled.queue_free()
		_sled = null
	Carry.restore(_charlotte)
	Sledding.add_run()
	_sliding = false
	_charlotte.express("laugh", 2.0)
	if Sledding.runs() < Sledding.RUNS:
		var again := ["Encore ! Encore !", "C'est trop l'fun !", "J'ai de la neige dans le cou !"]
		_charlotte_says(again[(Sledding.runs() - 1) % again.size()])
		_control.hands_off = false
		return
	_back_inside()


# The third time down: Jade takes the sled back, the star, and in they go to warm up.
func _back_inside() -> void:
	var steps := create_tween()
	steps.tween_interval(0.6)
	steps.tween_callback(func() -> void:
		_supervisor.say("Bravo, Chachoue ! T'as glissé comme une championne !\nOn rentre se réchauffer.", 3.4))
	steps.tween_interval(3.8)
	steps.tween_callback(func() -> void:
		Carry.put_down(_charlotte)
		Quests.complete(Sledding.QUEST)
		_charlotte_says("Merci, Jade !"))
	steps.tween_interval(2.2)
	steps.tween_callback(func() -> void:
		Sledding.just_back = true
		_control.enabled = false
		Sfx.play("door")
		Transition.change_scene_saying(self, Sledding.GARDE, "On rentre au service de garde…", 1.2))


# How far along the path a point is (0 at the top, 1 out on the flat), by its x.
func _progress(at: Vector2) -> float:
	var first: Vector2 = SLIDE_PATH[0]
	var last: Vector2 = SLIDE_PATH[SLIDE_PATH.size() - 1]
	return clampf((at.x - first.x) / (last.x - first.x), 0.0, 1.0)


static func _along(path: Array, u: float) -> Vector2:
	var f := clampf(u, 0.0, 1.0) * (path.size() - 1)
	var i := mini(int(f), path.size() - 2)
	return (path[i] as Vector2).lerp(path[i + 1], f - i)


func _leave_by_gate() -> void:
	if _sale:
		_charlotte_says("On choisit notre sapin d'abord !")
		return
	if not School.can_leave():
		_charlotte_says("Je reste à l'école jusqu'à la fin de la journée.\nC'est Papa qui vient me chercher !")
		return
	_go_home()


# ── The day ─────────────────────────────────────────────────────

# Step 1 → 2: Maman brought her through the gate; she says goodbye and goes back out the way they came.
func _mom_says_goodbye() -> void:
	School.set_step(2)
	_mom = Character.new()
	var look := CharacterLook.mom()
	Season.dress_for_weather(look)
	_mom.look = look
	_mom.scale = Vector2.ONE * CHAR_SCALE
	_mom.position = Vector2(START_X - 110.0, CHARLOTTE_Y - 4.0)
	_mom.facing = 1
	add_child(_mom)
	move_child(_mom, _charlotte.get_index())
	_charlotte.facing = -1
	_control.hands_off = true
	var steps := create_tween()
	steps.tween_interval(0.8)
	steps.tween_callback(func() -> void: _mom_says("Bonne journée, ma chouette !\nJe reviens te chercher après l'école."))
	steps.tween_interval(3.6)
	steps.tween_callback(func() -> void: _charlotte_says("Bye, Maman !"))
	steps.tween_interval(1.4)
	steps.tween_callback(func() -> void:
		_mom.facing = -1
		_mom.is_walking = true
		_control.hands_off = false
		Notebook.announce("step", "C'est la récré ! Va jouer dans la cour.", School.HEADING))
	steps.tween_property(_mom, "position:x", GATE_X, (_mom.position.x - GATE_X) / 150.0)
	# Through the gate and away down the street: smaller as she goes, then gone.
	steps.tween_property(_mom, "position", Vector2(GATE_X - 20.0, WALL_FOOT - 2.0), 1.2)
	steps.parallel().tween_property(_mom, "scale", Vector2.ONE * CHAR_SCALE * 0.82, 1.2)
	steps.tween_property(_mom, "modulate:a", 0.0, 0.6)
	steps.tween_callback(_mom.queue_free)


# The game of tag is over: the bell rings, the supervisor calls them in, everyone lines up at the door and goes in; Alyzée
# waits for Charlotte, and they go in together.
func _ring_the_bell() -> void:
	_bell_rung = true
	_control.hands_off = true
	var bell := Vector2(DOOR_X - SchoolYardArt.DOOR_W / 2.0 - 46.0, WALL_FOOT - SchoolYardArt.BASE_H - 70.0)
	Sfx.play("school_bell", bell)
	Bubble.say(self, bell - Vector2(0, 26), "DRIIIIING !", 2.0)
	var steps := create_tween()
	steps.tween_interval(1.4)
	steps.tween_callback(func() -> void:
		_supervisor.say("C'est la fin de la récré !\nEn rang, tout le monde !")
		for i in _kids.size():
			_kids[i].go_in(DOOR_X + 40.0 + i * 16.0))
	steps.tween_interval(3.0)
	var first := School.first_day()
	steps.tween_callback(func() -> void:
		_alyzee.kid.facing = 1 if _charlotte.position.x > _alyzee.position.x else -1
		_alyzee.say("Viens, Chachoue !\nOn s'assoit ensemble en classe ?" if first else "Viens, Chachoue ! On rentre !"))
	steps.tween_interval(3.2)
	if first:
		steps.tween_callback(func() -> void:
			_charlotte.facing = 1 if _alyzee.position.x > _charlotte.position.x else -1
			_charlotte_says("Oui ! T'es mon amie, astheure !"))
		steps.tween_interval(2.6)
	steps.tween_callback(func() -> void:
		_control.hands_off = false
		_charlotte_says("On rentre en classe !"))


# In through the pupils' door after the bell: the classroom (step 3).
func _go_to_class() -> void:
	_control.enabled = false
	Sfx.play("door")
	if School.step() == 2:
		School.set_step(3)
	Transition.change_scene(self, School.CLASS)


# Out by the gate when it isn't a school day (only the debug menu brings her here then): home.
func _go_home() -> void:
	_control.enabled = false
	Sfx.play("door")
	Transition.inside_x = School.HOME_X
	Transition.change_scene_saying(self, School.HOME, "Tu rentres à la maison…", 1.2)


func _charlotte_says(text: String) -> void:
	Bubble.say(self, _charlotte.position + Vector2(0, -190), text, 2.4)


func _mom_says(text: String) -> void:
	Bubble.say(self, _mom.position + Vector2(0, -235), text, 3.4)


# ── One of the children (or the supervisor) ─────────────────────

class _Kid:
	extends Node2D
	## What they are doing: "idle", "tag" (chasing `partner` or running from them), "rope" (skipping), "ball" (bouncing it),
	## "slide" (down the snow hill and back up), or "line" (going in at the bell).
	var mode := "idle"
	var look: CharacterLook
	var lines: Array = []
	var facing := 1
	## The top of the head, in the Character's own units (for the bubble and the click).
	var head := -340.0
	var body: Character
	var partner: _Kid
	var it := false
	var lo := 0.0
	var hi := 2600.0
	## The snow hill's left foot (world), for "slide".
	var hill := Vector2.ZERO
	var _t := 0.0
	var _pause := 0.0
	var _line := 0
	var _slide := 0.0
	var _door := 0.0
	var _rope: Array[_Rope] = []
	var _ball: _Ball

	func _ready() -> void:
		if mode == "rope":
			_rope.append(_Rope.new())
			_rope[0].kid = self
			add_child(_rope[0])
		body = Character.new()
		body.look = look
		body.facing = facing
		body.fidgets = mode == "idle"
		if mode == "rope":
			body.task = "skip"
		# Their legs keep time with how fast they go (as Charlotte's do).
		body.walk_speed = 130.0
		add_child(body)
		if mode == "rope":
			_rope.append(_Rope.new())
			_rope[1].kid = self
			_rope[1].front = true
			add_child(_rope[1])
		if mode == "ball":
			_ball = _Ball.new()
			_ball.kid = self
			add_child(_ball)
		add_to_group("interactable")

	func _process(delta: float) -> void:
		_t += delta
		match mode:
			"tag":
				_tag(delta)
			"rope":
				# A hop as the rope comes under the feet, her hands on the handles.
				body.position.y = -pow(maxf(-cos(_rope_phase()), 0.0), 1.6) * HOP
				var h := handles()
				body.work = [to_global(h[0]), to_global(h[1])]
				if OnScreen.near(self, 200.0):
					for r in _rope:
						r.queue_redraw()
			"ball":
				if absf(sin(_t * 3.2)) > 0.85:
					body.pet(0.1, 0.0)
				if OnScreen.near(self, 200.0):
					_ball.queue_redraw()
			"slide":
				_sliding(delta)
			"line":
				_to_door(delta)

	# Tag: whoever is "it" runs after the other, who runs off to the far end; caught, they swap.
	func _tag(delta: float) -> void:
		if _pause > 0.0:
			_pause -= delta
			body.is_walking = false
			body.running = false
			return
		var speed := 230.0 if it else 205.0
		var target := partner.position.x if it else (lo if partner.position.x > position.x else hi)
		var dx := target - position.x
		if absf(dx) < 6.0:
			body.is_walking = false
			body.running = false
		else:
			body.is_walking = true
			body.running = true
			body.facing = 1 if dx > 0.0 else -1
			position.x += signf(dx) * minf(speed * delta, absf(dx))
		if it and absf(partner.position.x - position.x) < 26.0:
			it = false
			partner.it = true
			_pause = 0.9
			partner._pause = 1.2
			if OnScreen.near(self, 0.0) and randf() < 0.35:
				say("Tague !", 1.2)

	# Down the snow hill sitting, up again on foot, a rest at the top.
	func _sliding(delta: float) -> void:
		var path := [Vector2(200, 16), Vector2(270, 40), Vector2(330, 98), Vector2(380, 144), Vector2(410, 166)]
		_slide += delta
		var top: Vector2 = hill + path[0] - Vector2(0, 170)
		if _slide < 2.5:
			body.sitting = true
			body.sit_on_ground = true
			body.seat_h = 0.0
			body.facing = 1
			position = top
		elif _slide < 3.9:
			var u := ease((_slide - 2.5) / 1.4, 1.6)
			position = hill - Vector2(0, 170) + _along(path, u)
		elif _slide < 4.8:
			body.sitting = false
		elif _slide < 8.0:
			var u2 := 1.0 - (_slide - 4.8) / 3.2
			body.is_walking = true
			body.facing = -1
			position = hill - Vector2(0, 170) + _along(path, u2)
		else:
			body.is_walking = false
			_slide = 0.0

	func _along(path: Array, u: float) -> Vector2:
		var f := clampf(u, 0.0, 1.0) * (path.size() - 1)
		var i := mini(int(f), path.size() - 2)
		return (path[i] as Vector2).lerp(path[i + 1], f - i)

	## The bell: stop playing and walk to the door, then in.
	func go_in(door_x: float) -> void:
		mode = "line"
		_door = door_x
		body.sitting = false
		body.fidgets = false
		body.position.y = 0.0
		body.task = ""
		body.work = []
		if _ball:
			_ball.visible = false
		for r in _rope:
			r.visible = false
		# Down off the climbing frame or the hill first.
		var t := create_tween()
		t.tween_property(self, "position:y", 624.0, 0.4)

	func _to_door(delta: float) -> void:
		var dx := _door - position.x
		if absf(dx) < 4.0:
			body.is_walking = false
			modulate.a = move_toward(modulate.a, 0.0, delta * 1.5)
			if modulate.a <= 0.0:
				queue_free()
			return
		body.is_walking = true
		body.running = false
		body.facing = 1 if dx > 0.0 else -1
		position.x += signf(dx) * minf(150.0 * delta, absf(dx))

	func say(text: String, seconds := 2.4) -> void:
		body.express("talk", Bubble.reading_time(text, seconds) * 0.8)
		Bubble.say(get_parent(), global_position + Vector2(0, head) * scale - Vector2(0, 12), text, seconds)

	func can_interact() -> bool:
		return mode != "line"

	func hit_test(p: Vector2) -> bool:
		var at := global_position + body.position * scale
		return Rect2(at + Vector2(-60, head) * scale, Vector2(120, -head) * scale).has_point(p)

	func approach_x(from_x: float) -> float:
		return global_position.x + (70.0 if from_x > global_position.x else -70.0)

	func focus_x() -> float:
		return global_position.x

	func reserve() -> void:
		pass

	func release() -> void:
		pass

	func interact(_who: Character) -> void:
		if lines.is_empty():
			return
		say(lines[_line % lines.size()])
		_line += 1

	## Turns of the rope a second, and how high she hops over it (her own units).
	const ROPE_TURNS := 1.25
	const HOP := 38.0

	## Where the rope is in its turn: 0 straight over her head, PI under her feet. It comes down in front of her and goes
	## back up behind (sin > 0 = in front).
	func _rope_phase() -> float:
		return fmod(_t * TAU * ROPE_TURNS, TAU)

	## Where her hands go, in her own units (front hand's first): out beside her hips, the wrists turning a small circle with
	## the rope, highest when it is overhead.
	func handles() -> Array:
		var phase := _rope_phase()
		var out: Array = []
		for i: int in [1, 0]:
			var shoulder := to_local(body.shoulder_position(i))
			var side := signf(shoulder.x) if absf(shoulder.x) > 1.0 else (-1.0 if i == 1 else 1.0)
			out.append(shoulder + Vector2(side * (40.0 + sin(phase) * 6.0), 78.0 - cos(phase) * 10.0))
		return out

	## The rope's ends (where it leaves each handle), how far its middle has swung from the line between them (+ down, - up),
	## and whether it is in front of her.
	func rope_points() -> Array:
		var phase := _rope_phase()
		# The handles are in her fists, wherever the arms really got to.
		var h := [to_local(body.hand_at(1)), to_local(body.hand_at(0))]
		var a: Vector2 = h[0] + Vector2(signf(h[0].x - h[1].x) * 10.0, 22.0)
		var b: Vector2 = h[1] + Vector2(signf(h[1].x - h[0].x) * 10.0, 22.0)
		var hands_y := (a.y + b.y) / 2.0
		# Down to just over the ground under her feet, up well over her head (and her hop), round a loop seen edge-on.
		var down := -hands_y - 4.0
		var up := hands_y - head + 40.0
		var c := -cos(phase)
		var swing := c * (down if c > 0.0 else up)
		return [a, b, swing, sin(phase) > 0.0, h]

	func ball_position() -> Vector2:
		return Vector2(70.0, -30.0 - absf(sin(_t * 3.2)) * 190.0)


class _Rope:
	extends Node2D
	var kid: _Kid
	var front := false

	func _draw() -> void:
		var pts: Array = kid.rope_points()
		if pts[3] == front:
			# The loop: lifted most at its middle, rounder than a sag so it reads as a rope swung wide.
			var a: Vector2 = pts[0]
			var b: Vector2 = pts[1]
			var line := PackedVector2Array()
			for k in 25:
				var t := k / 24.0
				line.append(a.lerp(b, t) + Vector2(0.0, pts[2] * pow(sin(PI * t), 0.75)))
			var color := Color("#E85FA0") if front else Color("#C9468A")
			draw_polyline(line, color, 11.0, true)
		# The handles in her fists, in front of her hands whichever way the rope goes, pointing down toward the rope.
		if front:
			for i in 2:
				var hand: Vector2 = pts[4][i]
				var tip: Vector2 = pts[i]
				var dir := (tip - hand).normalized()
				draw_line(hand - dir * 12.0, tip, Color("#C99A1E"), 18.0, true)
				draw_line(hand - dir * 12.0, tip, Color("#F2C230"), 13.0, true)


class _Ball:
	extends Node2D
	var kid: _Kid
	var color := Color("#E8662A")

	func _draw() -> void:
		var p := kid.ball_position()
		var h := -p.y
		draw_set_transform(Vector2(70, 2), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 26.0 - h * 0.05, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO)
		draw_circle(p, 26.0, color)
		draw_arc(p, 26.0, 0, TAU, 24, color.darkened(0.35), 3.0, true)
		draw_line(p + Vector2(-26, 0), p + Vector2(26, 0), color.darkened(0.4), 2.0, true)
		draw_arc(p + Vector2(-34, 0), 26.0, -0.9, 0.9, 10, color.darkened(0.4), 2.0, true)
		draw_arc(p + Vector2(34, 0), 26.0, PI - 0.9, PI + 0.9, 10, color.darkened(0.4), 2.0, true)
		draw_circle(p + Vector2(-9, -10), 6.0, Color(1, 1, 1, 0.35))


# ── The yard's ground ───────────────────────────────────────────

# Asphalt, its grain and cracks, the shade at the wall's foot and the painted games (hopscotch, the big circle, the
# basketball key), dead leaves blown against the wall in autumn; in winter, packed snow trodden grey where the children run,
# banks along the wall. Drawn once.
class _Ground:
	extends Node2D
	var seed_value := 0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + 9
		var foot := WALL_FOOT
		var winter := Season.is_winter()
		var base := Color("#EEF2F6") if winter else Color("#6A6966")
		draw_rect(Rect2(0, foot, YARD_W, 720.0 - foot), base)
		# Farther is hazier and lighter, nearer darker.
		for k in 8:
			draw_rect(Rect2(0, foot + k * 20.0, YARD_W, 20.0), Color(0, 0, 0, 0.012 * k) if not winter else Color(0.55, 0.65, 0.8, 0.012 * k))
		draw_rect(Rect2(0, foot, YARD_W, 10.0), Color(0, 0, 0, 0.16 if not winter else 0.06))
		if winter:
			# Trodden paths where everyone runs, banks against the wall.
			for i in 14:
				var x := rng.randf_range(0.0, YARD_W)
				draw_set_transform(Vector2(x, rng.randf_range(618.0, 690.0)), 0.0, Vector2(1.0, 0.12))
				draw_circle(Vector2.ZERO, rng.randf_range(90.0, 220.0), Color("#C9CED6", 0.22))
			draw_set_transform(Vector2.ZERO)
			_snowbank(foot, rng)
			for i in 600:
				draw_rect(Rect2(rng.randf_range(0.0, YARD_W), rng.randf_range(foot, 720.0), 2.0, 1.0), Color("#B9C6D6", 0.5))
			return
		for i in 1400:
			var tone := rng.randf()
			draw_rect(Rect2(rng.randf_range(0.0, YARD_W), rng.randf_range(foot, 720.0), rng.randf_range(1.0, 3.0), 1.2),
				Color(1, 1, 1, 0.08) if tone < 0.5 else Color(0, 0, 0, 0.1))
		for i in 6:
			var p := Vector2(rng.randf_range(0.0, YARD_W), rng.randf_range(600.0, 700.0))
			var crack := PackedVector2Array([p])
			for k in 6:
				p += Vector2(rng.randf_range(14.0, 34.0), rng.randf_range(-5.0, 5.0))
				crack.append(p)
			draw_polyline(crack, Color(0.15, 0.15, 0.15, 0.4), 1.3, true)
		_hopscotch(Vector2(470.0, 652.0))
		# The big circle for ballon-chasseur and the basketball key.
		draw_set_transform(Vector2(1880.0, 660.0), 0.0, Vector2(1.0, 0.26))
		draw_arc(Vector2.ZERO, 170.0, 0, TAU, 64, Color("#F4F1EA", 0.75), 7.0, true)
		draw_set_transform(Vector2(HOOP_X + 86.0, 640.0), 0.0, Vector2(1.0, 0.26))
		draw_arc(Vector2.ZERO, 120.0, 0, PI, 32, Color("#FFD23F", 0.7), 6.0, true)
		draw_set_transform(Vector2.ZERO)
		if Season.current == "autumn":
			var litter: Array[Color] = Season.litter()
			for i in 260:
				var x := rng.randf_range(0.0, YARD_W)
				var y := foot + absf(rng.randfn(0.0, 10.0)) + 2.0
				draw_set_transform(Vector2(x, y), rng.randf_range(-1.0, 1.0), Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, rng.randf_range(3.0, 6.0), litter[rng.randi_range(0, litter.size() - 1)])
			draw_set_transform(Vector2.ZERO)

	# The bank the plough left along the wall and the fences: one long drift, its height rising and falling, lit on top, a
	# blue shade along its foot.
	func _snowbank(foot: float, rng: RandomNumberGenerator) -> void:
		var phase := [rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU)]
		var top := PackedVector2Array()
		var x := 0.0
		while x <= YARD_W:
			var h := 22.0 + 9.0 * sin(x / 170.0 + phase[0]) + 6.0 * sin(x / 61.0 + phase[1]) + 3.0 * sin(x / 23.0 + phase[2])
			# Shovelled clear in front of the pupils' door.
			h *= smoothstep(70.0, 130.0, absf(x - DOOR_X))
			top.append(Vector2(x, foot + 4.0 - h))
			x += 12.0
		var body := top.duplicate()
		body.append(Vector2(YARD_W, foot + 18.0))
		body.append(Vector2(0.0, foot + 18.0))
		var shade := PackedVector2Array()
		for p in top:
			shade.append(p + Vector2(0.0, 12.0))
		shade.append(Vector2(YARD_W, foot + 26.0))
		shade.append(Vector2(0.0, foot + 26.0))
		draw_colored_polygon(shade, Color("#C7D5E6"))
		draw_colored_polygon(body, Color("#F4F8FC"))
		draw_polyline(top, Color("#FFFFFF"), 3.0, true)

	# The hopscotch painted on the asphalt, flattened by the view: 1, 2, 3, 4–5, 6, 7–8, and the sky ("Ciel") at the top.
	func _hopscotch(at: Vector2) -> void:
		var paint := Color("#FFD23F", 0.85)
		var cell := Vector2(56.0, 20.0)
		var x := at.x
		var rows := [1, 1, 1, 2, 1, 2, 1]
		var n := 1
		for r: int in rows:
			for k in r:
				var y := at.y - (cell.y * r) / 2.0 + k * cell.y
				var box := Rect2(Vector2(x, y), Vector2(cell.x, cell.y))
				if r == 1:
					box = Rect2(Vector2(x, at.y - cell.y / 2.0), Vector2(cell.x, cell.y))
				draw_rect(box, paint, false, 3.0)
				draw_string(ThemeDB.fallback_font, box.position + Vector2(cell.x / 2.0 - 6.0, cell.y - 4.0), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, paint)
				n += 1
			x += cell.x
		draw_set_transform(Vector2(x + 26.0, at.y), 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, 30.0, -PI / 2.0, PI / 2.0, 16, paint, 4.0, true)
		draw_set_transform(Vector2.ZERO)
