extends StreetScene
# The Parc du Pélican, the city's real park at 2590 rue Masson, between 1re Avenue and rue Molson (montreal.ca/lieux/parc-du-pelican),
# entered from Masson's south side at the lawn between 1re and Molson (`masson.gd` SHOP_DOORS, the gate on the left here). It is the
# place of the park activities to come: the playground, the swimming pool and the wading pool, the sliding hill. What the city lists is
# there: a chalet near Masson (restrooms, a rest area), a wading pool for the under-tens, a big outdoor pool, playgrounds, a dog park, a
# basketball court and ping-pong tables, a sliding hill, and in winter a hockey rink with boards and a free-skating rink (the pool's basin,
# flooded). The city's coordinates put the wading pool west of the dog park and the chalet; the rest of the order is ours.
# Left to right: the gate, the wading pool, the dog park, the chalet, the swimming pool, the playground (the big structure, the swings, the
# sandbox, the spring riders), the court and the ping-pong table, the hill. Seasons: the pools are open in summer, covered in autumn,
# drained in spring; in winter the big pool is the skating rink, the court the hockey rink, the hill white with sleds.
# Ground features lie flat on the ground behind the line she walks on (`ParkArt.flat`); tall ones stand on their feet. Each place she can
# go to is a `SPOTS` entry: a click walks her there and she says what she will do (the activities will take over those clicks).
# Builds its own scene, like the schoolyard and the lanes.

const PARK_W := 8000.0
## Where the lawn begins (the backdrop's line), where the pieces stand, and the line Charlotte and the visitors walk on.
const FOOT := 566.0
const BACK_Y := 606.0
const LANE_Y := 638.0
const GATE_X := 150.0
const START_X := 360.0
const WADING_X := 900.0
const DOG_X := 1380.0
const DOG_W := 720.0
const CHALET_X := 2300.0
const CHALET_W := 700.0
const POOL_X := 3200.0
const POOL_W := 1040.0
const PLAY_X := 4600.0
const COURT_X := 5700.0
const COURT_W := 700.0
const HILL_X := 6760.0
const HILL_W := 1100.0

## Where she may go and what she says there: [id, x of the place's middle, half width, where she stands, [summer-ish line, winter line]].
## The activities (playground, pools, sliding) hook onto these ids.
const SPOTS := [
	["pataugeoire", WADING_X, 190.0, WADING_X, ["La pataugeoire, c'est pour les moins de 10 ans !\nChu assez petite, moi !", "La pataugeoire est couverte de neige.\nElle ouvre en été !"]],
	["chiens", DOG_X + DOG_W * 0.5, 230.0, DOG_X + DOG_W * 0.5, ["Les chiens courent en liberté, là-dedans !\nIls s'amusent beaucoup.", "Les chiens jouent dans la neige !"]],
	["chalet", CHALET_X + CHALET_W * 0.5, 280.0, CHALET_X + CHALET_W * 0.5, ["Le chalet : les toilettes et un coin pour se reposer.", "Le chalet est chaud : on peut se réchauffer !"]],
	["piscine", POOL_X + POOL_W * 0.5, 480.0, POOL_X + POOL_W * 0.5, ["La grande piscine ! On va nager quand il fait chaud.", "C'est la patinoire, astheure ! Faut des patins."]],
	["jeux", PLAY_X + 330.0, 480.0, PLAY_X + 330.0, ["Les modules de jeux ! Ma glissoire préférée !", "Les balançoires sont gelées, mais les modules sont beaux."]],
	["court", COURT_X + COURT_W * 0.5, 330.0, COURT_X + COURT_W * 0.5, ["Le terrain de basketball.\nOn peut aussi jouer au ping-pong !", "La patinoire avec bandes : on joue au hockey !"]],
	["butte", HILL_X + HILL_W * 0.4, 360.0, HILL_X + 240.0, ["La butte de glissade ! L'hiver, on glisse dessus.", "La butte de glissade ! Faut juste un traîneau !"]],
]

var _visitors: Array[_Visitor] = []
var _swings: _Piece
var _springs: Array[_Piece] = []
var _pieces_by_kind := {}
## A play in progress (a swing, the slide…): clicks wait until it is over.
var _busy := false
## Papa, at the foot of the hill during the sledding quest (`Luge`), and the sleds of the runs.
var _papa: _Visitor
var _sleds: Array[Sprite2D] = []
const SLED_SCALE := 0.8
const SLED_RIM := 10.0
const PEAK := 0.32


func _ready() -> void:
	street_key = "parc_pelican"
	seed_value = 2590
	_rng.seed = seed_value
	_street_width = PARK_W
	add_child(SkyBackdrop.new())
	var far_city := _FarCity.new()
	far_city.seed_value = seed_value + 1
	add_child(far_city)
	DepthBlur.far(self)
	add_child(Birds.new())
	_build_park_trees()
	var ground := _Ground.new()
	ground.seed_value = seed_value
	add_child(ground)
	_build_park_pieces()
	_build_park_labels()
	_build_park_people()
	var start_x := START_X
	# A saved game or the debug menu brings her back where she was; the way in from Masson leaves it alone (it is Masson's x).
	if not is_nan(Transition.street_x) and Transition.arrive == "":
		start_x = Transition.street_x
	Transition.street_x = NAN
	var x_arg := _arg("--x=")
	if not x_arg.is_empty():
		start_x = x_arg.to_float()
	_charlotte = _spawn_charlotte(start_x)
	_control.charlotte = _charlotte
	_control.bounds = Vector2(80.0, PARK_W - 80.0)
	_control.walk_top = FOOT - 120.0
	add_child(_control)
	_build_park_doors()
	if Luge.step() == 2:
		_build_luge()
	elif ParkOuting.active():
		_build_outing_papa()
	var saver := Saver.new()
	saver.who = _charlotte
	add_child(saver)
	var kick := LeafKick.new()
	kick.walker = _charlotte
	add_child(kick)
	add_child(_wind)
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = int(PARK_W)
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
	var shot := _arg("--screenshot=")
	if not shot.is_empty():
		_save_screenshot(shot)


func _process(delta: float) -> void:
	_follow_charlotte()
	_cheer_cool = maxf(0.0, _cheer_cool - delta)
	_follow_papa(delta)


func room_name() -> String:
	return "Parc du Pélican"


# ── The park ────────────────────────────────────────────────────

# Big trees across the back of the park, hazier than the lawn's own, swaying (bare in winter, in their colours in autumn).
func _build_park_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 2
	var leaf := Season.falling_texture()
	var x := 120.0
	var i := 0
	while x < PARK_W - 60.0:
		var k := rng.randf_range(0.46, 0.66)
		var foot := Vector2(x + rng.randf_range(-60.0, 60.0), FOOT - 6.0 + rng.randf_range(-8.0, 6.0))
		var tree := _sprite(PropArt.tree(rng), k)
		tree.position = foot - Vector2(190.0, 780.0) * k
		tree.material = _sway(6.0, i * 1.7)
		add_child(tree)
		if i % 3 == 0:
			add_child(_falling_leaves(leaf, tree.position + Vector2(190, 250) * k))
		x += rng.randf_range(300.0, 520.0)
		i += 1


func _build_park_pieces() -> void:
	var back: Array[Dictionary] = []
	var winter := Season.is_winter()
	var summer := Season.current == "summer"
	# The gate end: the sign on its posts, a bench, a bin, lamps along the path.
	back.append({"kind": "gate", "x": GATE_X, "y": BACK_Y + 10.0})
	back.append({"kind": "sign", "x": GATE_X + 150.0, "y": BACK_Y, "w": 320.0, "h": 78.0})
	back.append({"kind": "bench", "x": GATE_X + 560.0, "y": BACK_Y + 6.0})
	back.append({"kind": "bin", "x": GATE_X + 700.0, "y": BACK_Y + 6.0})
	back.append({"kind": "iron_fence", "x": 0.0, "x1": GATE_X - 50.0, "y": BACK_Y + 4.0, "h": 64.0})
	for lx: float in [320.0, 1240.0, 2160.0, 3080.0, 4440.0, 5560.0, 6600.0]:
		back.append({"kind": "lamp", "x": lx, "y": BACK_Y + 8.0})
	# The wading pool, with its fence and the water mushroom; a bench for the parents.
	back.append({"kind": "wading_pool", "x": WADING_X, "y": 584.0, "r": 150.0, "animated": true})
	back.append({"kind": "iron_fence", "x": WADING_X - 230.0, "x1": WADING_X - 46.0, "y": 620.0, "h": 42.0})
	back.append({"kind": "iron_fence", "x": WADING_X + 46.0, "x1": WADING_X + 230.0, "y": 620.0, "h": 42.0})
	back.append({"kind": "water_mushroom", "x": WADING_X, "y": 588.0, "animated": true})
	back.append({"kind": "bench", "x": WADING_X + 230.0, "y": BACK_Y + 4.0})
	back.append({"kind": "fountain", "x": WADING_X - 250.0, "y": BACK_Y + 4.0})
	# The dog park: fenced, a gate, wood chips, a bench, an agility tunnel.
	back.append({"kind": "dog_park", "x": DOG_X, "y": 560.0, "w": DOG_W})
	back.append({"kind": "chain_fence", "x": DOG_X, "x1": DOG_X + DOG_W, "y": 612.0, "h": 96.0, "gate_at": DOG_X + DOG_W * 0.5 - 34.0, "gate_w": 68.0})
	back.append({"kind": "chain_fence", "x": DOG_X, "x1": DOG_X + DOG_W, "y": 558.0, "h": 96.0})
	# The chalet near Masson with its hedge, a bench, the fountain.
	back.append({"kind": "chalet", "x": CHALET_X, "y": BACK_Y - 4.0, "w": CHALET_W})
	back.append({"kind": "hedge", "x": CHALET_X - 24.0, "y": BACK_Y + 8.0, "w": CHALET_W + 48.0})
	back.append({"kind": "bench", "x": CHALET_X + 130.0, "y": BACK_Y + 30.0})
	back.append({"kind": "fountain", "x": CHALET_X + CHALET_W + 80.0, "y": BACK_Y + 8.0})
	# The swimming pool: its basin on the ground (the skating rink in winter), the deck, the fence, the lifeguard's chair, parasols.
	back.append({"kind": "swim_pool", "x": POOL_X, "y": 536.0, "w": POOL_W, "d": 300.0, "animated": true})
	back.append({"kind": "chain_fence", "x": POOL_X - 60.0, "x1": POOL_X + POOL_W + 60.0, "y": 620.0, "h": 52.0, "gate_at": POOL_X + POOL_W * 0.5 - 40.0, "gate_w": 80.0, "alpha": 0.22})
	if not winter:
		back.append({"kind": "lifeguard", "x": POOL_X + 140.0, "y": 542.0})
		back.append({"kind": "ladder", "x": POOL_X + 560.0, "y": 556.0})
		back.append({"kind": "ladder", "x": POOL_X + 860.0, "y": 556.0})
		if summer:
			back.append({"kind": "parasol", "x": POOL_X + 340.0, "y": 606.0, "color": Color("#E04F5F")})
			back.append({"kind": "parasol", "x": POOL_X + 760.0, "y": 606.0, "color": Color("#4FA3E0")})
	# The playground: the rubber surface, the big structure, the swings, the sandbox, the spring riders, a bench.
	back.append({"kind": "rubber", "x": PLAY_X - 40.0, "y": 566.0, "w": 1000.0, "d": 150.0})
	back.append({"kind": "sandbox", "x": PLAY_X, "y": 578.0, "w": 150.0})
	back.append({"kind": "structure", "x": PLAY_X + 270.0, "y": 600.0})
	back.append({"kind": "swings", "x": PLAY_X + 640.0, "y": 600.0, "animated": true})
	back.append({"kind": "spring", "x": PLAY_X + 560.0, "y": 610.0, "color": Color("#E04F5F"), "animated": true})
	back.append({"kind": "spring", "x": PLAY_X + 610.0, "y": 616.0, "color": Color("#4FA3E0"), "animated": true})
	back.append({"kind": "chain_fence", "x": PLAY_X - 40.0, "x1": PLAY_X + 960.0, "y": 560.0, "h": 60.0})
	back.append({"kind": "bench", "x": PLAY_X + 960.0, "y": BACK_Y + 8.0})
	# The court (the hockey rink in winter) and the ping-pong table.
	back.append({"kind": "court", "x": COURT_X, "y": 566.0, "w": COURT_W, "d": 140.0})
	if winter:
		back.append({"kind": "boards", "x": COURT_X - 8.0, "x1": COURT_X + COURT_W + 8.0, "y": 606.0})
		back.append({"kind": "net", "x": COURT_X + 20.0, "y": 600.0, "facing": 1.0})
		back.append({"kind": "net", "x": COURT_X + COURT_W - 60.0, "y": 600.0, "facing": -1.0})
	else:
		back.append({"kind": "hoop", "x": COURT_X + 6.0, "y": 602.0, "facing": 1.0})
		back.append({"kind": "hoop", "x": COURT_X + COURT_W - 6.0, "y": 602.0, "facing": -1.0})
		back.append({"kind": "chain_fence", "x": COURT_X - 20.0, "x1": COURT_X + COURT_W + 20.0, "y": 562.0, "h": 120.0})
	back.append({"kind": "pingpong", "x": COURT_X + COURT_W + 130.0, "y": 606.0})
	# The sliding hill, behind everything on its side.
	back.append({"kind": "hill", "x": HILL_X, "y": 596.0, "w": HILL_W})
	back.append({"kind": "bench", "x": HILL_X + HILL_W + 40.0, "y": BACK_Y + 6.0})
	if GameState.flags.get("park_castle", false) and not winter:
		back.append({"kind": "castle", "x": PLAY_X + 80.0, "y": 596.0})
	for spec: Dictionary in back:
		var piece := _Piece.new()
		piece.spec = spec
		piece.position = Vector2(spec.x, spec.y)
		add_child(piece)
		_pieces_by_kind[spec.kind] = piece
		if spec.kind == "swings":
			_swings = piece
		elif spec.kind == "spring":
			_springs.append(piece)


func _build_park_labels() -> void:
	var white := Color.WHITE
	var clear := Color(0, 0, 0, 0)
	_label("PARC DU PÉLICAN", Vector2(GATE_X + 310.0, BACK_Y - 90.0), Vector2(300, 40), 22, white, Color("#1E4A34"))
	_label("2590, rue Masson", Vector2(GATE_X + 310.0, BACK_Y - 62.0), Vector2(300, 24), 13, Color("#DCEFE4"), clear)
	_label("PATAUGEOIRE\nmoins de 10 ans", Vector2(WADING_X, 424.0), Vector2(200, 44), 14, Color("#1D4F91"), Color(1, 1, 1, 0.8))
	_label("PARC À CHIENS", Vector2(DOG_X + DOG_W * 0.5, 596.0 - 120.0), Vector2(180, 24), 14, Color("#2B2F33"), Color(1, 1, 1, 0.8))
	_label("CHALET", Vector2(CHALET_X + CHALET_W * 0.5, BACK_Y - 188.0), Vector2(160, 24), 15, Color("#F4F4F4"), Color("#3A4A42"))
	_label("PATINOIRE LIBRE" if Season.is_winter() else "PISCINE EXTÉRIEURE", Vector2(POOL_X + POOL_W * 0.5, 410.0), Vector2(320, 30), 18, Color("#1D4F91"), Color(1, 1, 1, 0.85))
	_label("AIRE DE JEUX", Vector2(PLAY_X + 330.0, 372.0), Vector2(200, 26), 16, Color("#1D4F91"), Color(1, 1, 1, 0.85))
	_label("PATINOIRE AVEC BANDES" if Season.is_winter() else "BASKETBALL", Vector2(COURT_X + COURT_W * 0.5, 430.0), Vector2(320, 26), 16, Color("#1D4F91"), Color(1, 1, 1, 0.85))
	_label("BUTTE DE GLISSADE", Vector2(HILL_X + HILL_W * 0.32, 560.0 - 290.0), Vector2(240, 26), 16, Color("#1D4F91"), Color(1, 1, 1, 0.85))


# People in the park: a parent on a bench, children at the playground and the pool, a lifeguard in summer, sledders in winter.
func _build_park_people() -> void:
	var looks := RandomNumberGenerator.new()
	looks.seed = seed_value + 3
	var winter := Season.is_winter()
	var summer := Season.current == "summer"
	var plan: Array[Dictionary] = []
	plan.append({"x": CHALET_X + 360.0, "y": BACK_Y + 30.0, "age": "adult", "lines": ["Quelle belle journée au parc !", "Mon petit adore la butte, l'hiver."]})
	plan.append({"x": PLAY_X + 240.0, "y": LANE_Y - 22.0, "lines": ["Regarde-moi grimper !", "Chu le roi du module !"]})
	plan.append({"x": PLAY_X + 520.0, "y": LANE_Y - 12.0, "lines": ["Pousse-moi plus fort sur la balançoire !", "Des fois on joue à la cachette ici."]})
	plan.append({"x": PLAY_X + 905.0, "y": BACK_Y + 8.0, "age": "adult", "lines": ["Pas trop haut, hein !", "Mets ta tuque, ma chouette !"]})
	if summer:
		plan.append({"x": WADING_X - 70.0, "y": LANE_Y - 18.0, "lines": ["L'eau est ben bonne !", "Le champignon m'arrose tout le temps !"]})
		plan.append({"x": WADING_X + 120.0, "y": LANE_Y - 18.0, "lines": ["Chu trempé de la tête aux pieds !", "On y va-tu à la grande piscine ?"]})
		plan.append({"x": POOL_X + 90.0, "y": BACK_Y + 12.0, "age": "adult", "guard": true, "lines": ["Pas de course autour de la piscine !", "On nage à son aise, mais prudemment."]})
	if winter and Luge.step() != 2:
		for k in 3:
			plan.append({"x": HILL_X + 40.0 + k * 40.0, "y": 596.0, "mode": "slide", "phase": k * 3.1, "lines": ["Wouhou ! Ça glisse en malade !", "Mes pantalons de neige sont tout mouillés !"]})
		plan.append({"x": POOL_X + 300.0, "y": BACK_Y + 14.0, "lines": ["Chu pas capable de tenir debout sur mes patins !", "La glace est belle aujourd'hui !"]})
	elif not winter:
		plan.append({"x": HILL_X + 520.0, "y": 596.0 - ParkArt.hill_height(0.47) + 4.0, "lines": ["On voit tout le parc d'en haut !", "L'hiver, on glisse ici !"]})
	for spot: Dictionary in plan:
		var v := _Visitor.new()
		var look := CharacterLook.random(looks, str(spot.get("age", "child")))
		Season.dress_for_weather(look)
		if spot.get("guard", false):
			look.outfit = "tshirt"
			look.outfit_color = Color("#D9342B")
		v.look = look
		v.lines = spot.lines
		v.mode = str(spot.get("mode", "idle"))
		v.phase = float(spot.get("phase", 0.0))
		v.position = Vector2(spot.x, spot.y)
		v.scale = Vector2.ONE * CHAR_SCALE
		v.facing = 1 if looks.randf() < 0.5 else -1
		v.hill = Vector2(HILL_X, 596.0)
		v.hill_w = HILL_W
		if spot.get("age", "child") == "adult":
			v.head = -400.0
		add_child(v)
		_visitors.append(v)
	# The dogs of the dog park, running about inside the fence.
	for k in 2:
		var d := _DogRunner.new()
		d.lo = DOG_X + 40.0
		d.hi = DOG_X + DOG_W - 40.0
		d.y = 584.0 + k * 10.0
		d.fur = [Color("#C98A4A"), Color("#4A4A4A")][k]
		d.position = Vector2(DOG_X + 200.0 + k * 260.0, d.y)
		add_child(d)


func _build_park_doors() -> void:
	add_child(DoorSpot.make(Rect2(GATE_X - 80.0, 380.0, 160.0, 270.0), _leave_by_gate, GATE_X + 20.0))
	# Things to play with come first (the first interactable under the click wins), then the places' own lines.
	var winter := Season.is_winter()
	var swing_x := PLAY_X + 640.0
	_play_spot(Rect2(swing_x + 20.0, 410.0, 230.0, 200.0), _swing, swing_x + 150.0)
	_play_spot(Rect2(PLAY_X + 520.0, 540.0, 45.0, 76.0), _spring.bind(0), PLAY_X + 480.0)
	_play_spot(Rect2(PLAY_X + 566.0, 540.0, 70.0, 76.0), _spring.bind(1), PLAY_X + 680.0)
	_play_spot(Rect2(PLAY_X + 150.0, 420.0, 250.0, 190.0), _slide_down, PLAY_X + 479.0)
	_play_spot(Rect2(PLAY_X - 20.0, 560.0, 200.0, 60.0), _castle, PLAY_X + 80.0)
	if not winter:
		_play_spot(Rect2(COURT_X, 300.0, COURT_W, 310.0), _shoot, COURT_X + COURT_W * 0.38)
	else:
		_play_spot(Rect2(COURT_X, 480.0, COURT_W, 130.0), _shoot, COURT_X + COURT_W * 0.38)
	_play_spot(Rect2(COURT_X + COURT_W + 100.0, 510.0, 170.0, 100.0), _pingpong, COURT_X + COURT_W + 80.0)
	if Season.current == "summer":
		_play_spot(Rect2(WADING_X - 150.0, 480.0, 300.0, 130.0), _wade, WADING_X)
	for fx: float in [WADING_X - 250.0, CHALET_X + CHALET_W + 80.0]:
		_play_spot(Rect2(fx - 24.0, 540.0, 48.0, 70.0), _drink.bind(fx), fx)
	for spot: Array in SPOTS:
		var line: String = spot[4][1 if winter else 0]
		var x: float = spot[1]
		var half: float = spot[2]
		var id: String = spot[0]
		add_child(DoorSpot.make(Rect2(x - half, 400.0, half * 2.0, 230.0), func() -> void: _spot_clicked(id, line), spot[3]))


func _play_spot(area: Rect2, action: Callable, stand: float) -> void:
	if area.has_area():
		add_child(DoorSpot.make(area, func() -> void:
			if _busy or _charlotte.sitting:
				return
			action.call()
			_cheer(), stand))


## A place of the park was clicked: what she says. (The activities will start from here: playground, pools, sliding.)
func _spot_clicked(_id: String, line: String) -> void:
	Bubble.say(self, _charlotte.position + Vector2(0, -190), line, 3.4)


func _leave_by_gate() -> void:
	if Luge.step() == 2:
		Bubble.say(self, _charlotte.position + Vector2(0, -190), "Papa m'attend pour glisser !\nOn s'en va pas tout de suite.", 3.0)
		return
	if ParkOuting.active():
		_control.enabled = false
		var ask := ChoiceCard.ask(self, "On rentre à la maison avec Papa ?", [{"text": "Oui, on rentre !"}, {"text": "Encore un peu !"}])
		ask.chose.connect(func(i: int) -> void:
			if i == 1:
				_control.enabled = true
				return
			ParkOuting.end()
			Carry.put_down(_charlotte)  # the sled stays at the park
			Transition.inside_x = School.HOME_X
			Transition.street_x = NAN
			Transition.arrive = ""
			Transition.change_scene_saying(self, School.HOME, "Papa te ramène à la maison…", 1.4))
		return
	_control.enabled = false
	if Carry.has("traineau"):
		Carry.put_down(_charlotte)
	# Out the way she came in: Masson's south side, at the lawn.
	Transition.street_x = float(GameState.flags.get("park_from_x", NAN))
	Transition.change_scene(self, "res://scenes/masson_pair.tscn")


# ── Papa at the park (`ParkOuting`) ─────────────────────────────

var _outing_papa: _Visitor
var _cheer_cool := 0.0
## How many free slides she has had with Papa (not the quest's): alone, together, a race, round again.
var _free_runs := 0


func _build_outing_papa() -> void:
	var look := CharacterLook.dad()
	Season.dress_for_weather(look)
	var papa := _Visitor.new()
	papa.look = look
	papa.lines = ParkOuting.LINES
	papa.position = Vector2(_charlotte.position.x - 130.0, 616.0)
	papa.scale = Vector2.ONE * CHAR_SCALE * 1.18
	papa.head = -420.0
	papa.facing = 1
	add_child(papa)
	_outing_papa = papa
	_papa = papa
	if Season.is_winter():
		# Papa brought the sled and the skates: the hill and the rink are for playing, as long as she likes.
		_play_spot_first(Rect2(HILL_X + 40.0, 330.0, 760.0, 280.0), _luge_run, HILL_X + 170.0)
		_play_spot_first(Rect2(POOL_X + 20.0, 470.0, POOL_W - 40.0, 150.0), _skate, POOL_X + 140.0)
	_play_spot_first(Rect2(560.0, 540.0, 1300.0, 80.0), _play_with_papa, 900.0)
	var hello := create_tween()
	hello.tween_interval(1.3)
	hello.tween_callback(func() -> void:
		papa.say("Voilà le parc du Pélican, ma grande !\nOn a le traîneau pis les patins : glisse, patine, joue !" if Season.is_winter() else "Voilà le parc du Pélican, ma grande !\nAmuse-toi : balançoire, glissoire, ballon… ou une course avec moi !", 4.2)
		papa.body.express("happy", 3.0))


# He walks a few steps behind her, and stops beside her, looking her way.
func _follow_papa(delta: float) -> void:
	if _outing_papa == null or not is_instance_valid(_outing_papa) or _busy:
		return
	var body: Character = _outing_papa.body
	var target := _charlotte.position.x + (-140.0 if _charlotte.facing > 0 else 140.0)
	var dx := target - _outing_papa.position.x
	if absf(dx) > 760.0:
		# Far behind (she ran across the park): he is beside her again, out of sight.
		_outing_papa.position.x = target
		return
	if absf(dx) > 50.0:
		_outing_papa.position.x += signf(dx) * minf(absf(dx), 200.0 * delta)
		body.is_walking = true
		body.facing = 1 if dx > 0.0 else -1
	else:
		body.is_walking = false
		body.facing = 1 if _charlotte.position.x >= _outing_papa.position.x else -1


# After a game, Papa says a kind word (not after every one).
func _cheer() -> void:
	if _outing_papa == null or _cheer_cool > 0.0:
		return
	_cheer_cool = 8.0
	var papa := _outing_papa
	var t := create_tween()
	t.tween_interval(2.4)
	t.tween_callback(func() -> void:
		if is_instance_valid(papa):
			papa.say(ParkOuting.CHEERS[randi() % ParkOuting.CHEERS.size()], 2.8)
			papa.body.express("happy", 2.4))


# ── Play ────────────────────────────────────────────────────────

func _begin_play() -> void:
	_busy = true
	_control.hands_off = true
	_charlotte.is_walking = false
	_charlotte.running = false


func _end_play() -> void:
	_charlotte.sitting = false
	_charlotte.sit_on_ground = false
	_charlotte.seat_h = 0.0
	_charlotte.position.y = CHARLOTTE_Y
	_charlotte.is_walking = false
	_control.hands_off = false
	_busy = false


func _say_c(text: String, seconds := 2.4) -> void:
	_charlotte.express("grin", seconds)
	Bubble.say(self, _charlotte.position + Vector2(0, -190), text, seconds)


# A swing: she sits in the middle one and pumps, the swing getting higher then slower, the set's own swings still.
func _swing() -> void:
	if _swings == null:
		return
	_begin_play()
	var top_y := 600.0 - 190.0
	var hx := _swings.position.x + 120.0
	_swings.ride_k = 1
	_charlotte.facing = 1
	_charlotte.sitting = true
	_charlotte.sit_on_ground = false
	var pushed := _outing_papa != null and is_instance_valid(_outing_papa)
	if pushed:
		# Papa behind her, pushing: each push sends her higher.
		_outing_papa.position = Vector2(hx - 118.0, 616.0)
		_outing_papa.body.is_walking = false
		_outing_papa.body.facing = 1
		for k in 6:
			get_tree().create_timer(0.5 + k * 1.15).timeout.connect(func() -> void:
				if _busy and is_instance_valid(_outing_papa):
					_outing_papa.body.pet(0.7, 0.2)
					Sfx.play("swoosh", _charlotte.position, -6.0, 0.8 + k * 0.05))
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if _busy and is_instance_valid(_outing_papa):
				_outing_papa.say("Accroche-toi bien ! Je pousse !", 2.2))
		get_tree().create_timer(4.4).timeout.connect(func() -> void:
			if _busy:
				_say_c("Plus haut, Papa ! Plus haut !", 2.0))
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		var amp := (0.75 if pushed else 0.5) * sin(PI * u) + 0.04
		var a := amp * sin(u * 26.0)
		_swings.ride_a = a
		_swings.queue_redraw()
		var seat_y := top_y + cos(a) * 132.0
		_charlotte.position = Vector2(hx + sin(a) * 132.0, 612.0)
		_charlotte.seat_h = 612.0 - seat_y - 4.0, 0.0, 1.0, 8.0 if pushed else 7.0)
	tw.tween_callback(func() -> void:
		_swings.ride_k = -1
		_swings.queue_redraw()
		_charlotte.position.x = hx - 50.0
		_end_play()
		_say_c("Wouiiii ! Plus haut !")
		if pushed and is_instance_valid(_outing_papa):
			_outing_papa.say("Ha ha ! Tu voles, ma grande !", 2.4))
	Sfx.play("swoosh", _charlotte.position)
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if _busy:
			_say_c("Regarde comme je vole !", 1.8))


func _spring(i: int) -> void:
	if i >= _springs.size():
		return
	var rider := _springs[i]
	_begin_play()
	rider.ride = true
	_charlotte.facing = 1
	_charlotte.sitting = true
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		var lean := 0.3 * sin(u * 4.2 * 5.0)
		rider.t = u * 5.0
		rider.queue_redraw()
		_charlotte.position = Vector2(rider.position.x + lean * 40.0 + 12.0, rider.position.y + 6.0)
		_charlotte.seat_h = 58.0 + 8.0 * absf(cos(u * 4.2 * 5.0)), 0.0, 1.0, 5.0)
	tw.tween_callback(func() -> void:
		rider.ride = false
		rider.queue_redraw()
		_charlotte.position.x = rider.position.x - 80.0
		_end_play()
		_say_c("Hue ! Mon cheval sautillant !"))


# The slide: up the ladder of the little tower, across the bridge, down it on her bottom.
func _slide_down() -> void:
	_begin_play()
	var base_x := PLAY_X + 270.0
	var ladder_x := base_x + 209.0
	var deck_y := 600.0 - 106.0
	_charlotte.facing = 1
	_charlotte.is_walking = true
	var tw := create_tween()
	tw.tween_property(_charlotte, "position:y", deck_y + 6.0, 1.5)
	tw.tween_callback(func() -> void: _charlotte.facing = -1)
	tw.tween_property(_charlotte, "position:x", base_x + 8.0, 1.6)
	tw.tween_callback(func() -> void:
		_charlotte.is_walking = false
		_charlotte.facing = -1
		_charlotte.sitting = true
		_charlotte.sit_on_ground = true
		_charlotte.seat_h = 0.0
		_say_c("Youhou !", 1.4))
	tw.tween_interval(0.5)
	tw.tween_method(func(u: float) -> void:
		var a := Vector2(base_x + 6.0, deck_y + 8.0)
		var b := Vector2(base_x - 100.0, 596.0)
		_charlotte.position = a.lerp(b, u), 0.0, 1.0, 1.1)
	tw.tween_callback(func() -> void:
		Sfx.play("swoosh", _charlotte.position)
		_charlotte.sit_on_ground = false
		_charlotte.sitting = false)
	tw.tween_property(_charlotte, "position", Vector2(base_x - 150.0, CHARLOTTE_Y), 0.5)
	tw.tween_callback(func() -> void:
		_end_play()
		_say_c("Encore ! Encore !")
		if _outing_papa != null and is_instance_valid(_outing_papa):
			# Papa catches her at the bottom of the slide and whirls her round.
			_outing_papa.position.x = _charlotte.position.x - 70.0
			_outing_papa.body.facing = 1
			_outing_papa.body.pet(1.0, 0.6)
			_outing_papa.say("Hop ! Je t'ai attrapée !", 2.4)
			_whirl(_charlotte, 6))


## Round and round: she turns on the spot (the puppet flips side to side), up on her toes, laughing.
func _whirl(who: Character, turns: int) -> void:
	var tw := create_tween()
	for k in turns:
		tw.tween_callback(func() -> void: who.facing = -who.facing)
		tw.tween_property(who, "position:y", who.position.y - 22.0, 0.11)
		tw.tween_property(who, "position:y", who.position.y, 0.11)
	tw.tween_callback(func() -> void: who.express("laugh", 1.6))


func _castle() -> void:
	if Season.is_winter():
		_spot_clicked("sable", "Le bac à sable est plein de neige.\nOn y bâtit des châteaux l'été !")
		return
	_begin_play()
	_charlotte.facing = 1
	_charlotte.pet(2.6, 1.0)
	_say_c("Je bâtis un château de sable !", 2.2)
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_callback(func() -> void:
		if not GameState.flags.get("park_castle", false):
			GameState.flags["park_castle"] = true
			var piece := _Piece.new()
			piece.spec = {"kind": "castle", "x": PLAY_X + 80.0, "y": 596.0}
			piece.position = Vector2(PLAY_X + 80.0, 596.0)
			piece.scale = Vector2.ZERO
			add_child(piece)
			var grow := create_tween()
			grow.tween_property(piece, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("pop", _charlotte.position)
		_end_play()
		_say_c("Ta-da ! Un château avec des tours !"))


# The water mushroom: she wades into the wading pool, splashing.
func _wade() -> void:
	_begin_play()
	_charlotte.facing = 1
	_charlotte.is_walking = true
	var tw := create_tween()
	tw.tween_property(_charlotte, "position:y", 598.0, 0.8)
	tw.tween_callback(func() -> void:
		_charlotte.is_walking = false
		_say_c("Brr ! Elle est froide, mais c'est bon !", 2.2)
		for k in 3:
			_spray(_charlotte.position + Vector2((k - 1) * 40.0, -30.0), 1.4))
	tw.tween_interval(2.6)
	tw.tween_callback(func() -> void:
		_charlotte.is_walking = true
		_spray(_charlotte.position + Vector2(0, -20.0), 1.2))
	tw.tween_property(_charlotte, "position:y", CHARLOTTE_Y, 0.8)
	tw.tween_callback(func() -> void:
		_end_play()
		_say_c("Chu trempée jusqu'aux genoux !"))


func _drink(fx: float) -> void:
	_begin_play()
	_charlotte.facing = 1
	_charlotte.pet(1.8, 1.0)
	Sfx.play("swoosh", _charlotte.position)
	_spray(Vector2(fx, 540.0), 1.2)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func() -> void:
		_end_play()
		_say_c("Glou glou ! De l'eau fraîche !"))


# A shot: a basketball at the hoop in summer (it goes in, or not), a puck into the net on the hockey rink in winter.
func _shoot() -> void:
	_begin_play()
	_charlotte.facing = 1
	var winter := Season.is_winter()
	var scores := randf() < 0.6
	var ball := _Ball.new()
	ball.kind = "puck" if winter else "basket"
	add_child(ball)
	var from := _charlotte.position + Vector2(36.0, -90.0)
	_charlotte.pet(0.7, 0.0)
	var tw := create_tween()
	tw.tween_interval(0.5)
	if winter:
		var net := Vector2(COURT_X + COURT_W - 24.0, 584.0)
		var start := Vector2(_charlotte.position.x + 50.0, 590.0)
		tw.tween_method(func(u: float) -> void: ball.position = start.lerp(net if scores else net + Vector2(-60.0 if false else 0.0, -50.0), u), 0.0, 1.0, 1.1)
	else:
		var rim := Vector2(COURT_X + COURT_W - 6.0 - 30.0 - 13.0, 602.0 - 258.0)
		tw.tween_method(func(u: float) -> void:
			var p := from.lerp(rim, u)
			p.y -= sin(PI * u) * 130.0
			if not scores and u > 0.85:
				p.x -= (u - 0.85) * 160.0
			ball.position = p, 0.0, 1.0, 1.2)
		if scores:
			tw.tween_property(ball, "position:y", rim.y + 90.0, 0.35)
		else:
			tw.tween_property(ball, "position", rim + Vector2(-90.0, 150.0), 0.6)
	tw.tween_callback(func() -> void:
		ball.queue_free()
		Sfx.play("pop", _charlotte.position)
		_end_play()
		if scores:
			_charlotte.express("grin", 2.0)
			_say_c("Panier !" if not winter else "But ! Papa va être fier !", 2.0)
		else:
			_charlotte.express("worry", 1.6)
			_say_c("Raté… j'essaie encore !" if not winter else "Dans le poteau ! Encore !", 2.0))


# Ping-pong against the table's far end: the ball hops along it, a rally of a few; it takes two to play.
func _pingpong() -> void:
	_begin_play()
	_charlotte.facing = 1
	var tx := COURT_X + COURT_W + 130.0
	var y := 606.0 - 62.0
	var ball := _Ball.new()
	ball.kind = "pingpong"
	add_child(ball)
	var tw := create_tween()
	for k in 6:
		var a := tx + (14.0 if k % 2 == 0 else 106.0)
		var b := tx + (106.0 if k % 2 == 0 else 14.0)
		tw.tween_method(func(u: float) -> void:
			ball.position = Vector2(lerpf(a, b, u), y - 10.0 - sin(PI * u) * 40.0), 0.0, 1.0, 0.32)
		tw.tween_callback(func() -> void:
			Sfx.play("click", ball.position)
			_charlotte.pet(0.25, 0.0))
	tw.tween_callback(func() -> void:
		ball.queue_free()
		_end_play()
		_say_c("Faut être deux pour jouer vraiment !\nPapa va venir avec moi."))


func _spray(at: Vector2, seconds: float) -> void:
	var fx := _Spray.new()
	fx.position = at
	fx.life = seconds
	add_child(fx)


# ── Skating, and games with Papa (`ParkOuting`) ─────────────────

# On the rink (the big pool in winter) with her skates on: a lap to the right, one back with a wave, then a pirouette; Papa glides
# behind her. As long as she likes.
func _skate() -> void:
	if not Season.is_winter():
		return
	_begin_play()
	var c := _charlotte
	var papa: Character = _outing_papa.body if _outing_papa != null and is_instance_valid(_outing_papa) else null
	var left := POOL_X + 140.0
	var right := POOL_X + POOL_W - 140.0
	var y := 616.0
	c.task = "skate"
	if papa:
		papa.task = "skate"
	c.position.y = y
	_say_c("Mes patins ! Ça glisse, ça glisse !", 2.2)
	if papa:
		_outing_papa.say("Tiens bon sur tes patins, Chachoue !\nJe te suis !", 2.6)
	Sfx.play("swoosh", c.position, -4.0, 1.3)
	var glide := func(u: float, from: float, to: float, dir: float, wob: float) -> void:
		var x := lerpf(from, to, u)
		c.facing = int(dir)
		c.position = Vector2(x, y + sin(u * PI * 2.0) * wob)
		if papa:
			papa.get_parent().position = Vector2(x - dir * 120.0, y + sin(u * PI * 2.0 + 0.6) * wob * 0.6)
			papa.facing = int(dir)
		if randf() < 0.05:
			_spray(c.position + Vector2(0, -4), 0.5)
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void: glide.call(u, c.position.x, right, 1.0, 14.0), 0.0, 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_say_c("Regarde-moi aller, Papa !", 1.8)
		c.facing = -1)
	tw.tween_method(func(u: float) -> void: glide.call(u, right, left + 300.0, -1.0, 18.0), 0.0, 1.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_say_c("Une pirouette !", 1.4)
		Sfx.play("pop", c.position, -4.0, 1.4)
		if papa:
			_outing_papa.say("Wow ! Bravo !", 1.8)
		_whirl(c, 8))
	tw.tween_interval(2.4)
	tw.tween_callback(func() -> void:
		c.task = ""
		if papa:
			papa.task = ""
		c.facing = 1
		_end_play()
		c.express("laugh", 2.0)
		_say_c("C'est trop l'fun, patiner !", 2.4))


# Snowballs in winter, catch with a ball the rest of the year: Charlotte and Papa throw to each other, dodge, laugh.
func _play_with_papa() -> void:
	if _outing_papa == null or not is_instance_valid(_outing_papa):
		return
	_begin_play()
	var c := _charlotte
	var papa: Character = _outing_papa.body
	var winter := Season.is_winter()
	var mid := clampf(c.position.x, 700.0, 1700.0)
	c.position.x = mid - 230.0
	c.facing = 1
	_outing_papa.position = Vector2(mid + 230.0, 616.0)
	papa.facing = -1
	papa.is_walking = false
	c.is_walking = false
	_outing_papa.say("Prépare-toi ! Une bataille de balles de neige !" if winter else "Attrape ! On joue au ballon !", 2.4)
	var lines_c := ["Raté, Papa !", "Ha ha ! Tu m'as pas eue !", "Je t'ai eu !", "Encore, encore !"]
	var tw := create_tween()
	tw.tween_interval(1.8)
	for round_i in 4:
		var from_c := round_i % 2 == 0
		tw.tween_callback(func() -> void:
			var thrower: Character = c if from_c else papa
			thrower.pet(0.5, 0.2)
			Sfx.play("swoosh", c.position, -6.0, 1.2))
		tw.tween_method(func(u: float) -> void:
			var a: Vector2 = c.position + Vector2(20, -120)
			var b: Vector2 = _outing_papa.position + Vector2(-20, -120)
			if not from_c:
				var s := a
				a = b
				b = s
			_ball_at(a.lerp(b, u) + Vector2(0, -sin(u * PI) * 70.0), winter), 0.0, 1.0, 0.8)
		tw.tween_callback(func() -> void:
			_ball_at(Vector2.INF, winter)
			if from_c:
				papa.express("surprised", 1.2)
				_outing_papa.say(["Oh ! Ma tuque !", "Touché !", "Ouf ! Bien visé !"][round_i % 3] if winter else "Bien lancé !", 1.6)
				_spray(_outing_papa.position + Vector2(0, -150), 0.6)
			else:
				c.facing = 1
				_say_c(lines_c[round_i % lines_c.size()], 1.6)
				var hop := create_tween()
				hop.tween_property(c, "position:y", c.position.y - 28.0, 0.15)
				hop.tween_property(c, "position:y", 616.0, 0.15))
		tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		c.express("laugh", 2.2)
		_outing_papa.say("Ha ha ha ! Match nul, ma grande !\nT'es championne !", 2.8)
		_whirl(c, 4))
	tw.tween_interval(2.6)
	tw.tween_callback(func() -> void:
		_end_play())


var _toss: Node2D


# One ball (a snowball, or a beach ball) in the air at `at`; `Vector2.INF` takes it away.
func _ball_at(at: Vector2, snow: bool) -> void:
	if at == Vector2.INF:
		if _toss:
			_toss.queue_free()
			_toss = null
		return
	if _toss == null:
		var b := _Toss.new()
		b.snow = snow
		add_child(b)
		_toss = b
	_toss.position = at


## What is thrown: a white snowball, or a striped ball.
class _Toss:
	extends Node2D
	var snow := true

	func _draw() -> void:
		if snow:
			draw_circle(Vector2(1.5, 2.0), 11.0, Color(0.5, 0.6, 0.75, 0.35))
			draw_circle(Vector2.ZERO, 11.0, Color("#F4F8FC"))
			draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("#B8C8DC"), 1.6, true)
			draw_circle(Vector2(-3.5, -3.5), 3.0, Color.WHITE)
		else:
			draw_circle(Vector2.ZERO, 13.0, Color("#E5383B"))
			draw_arc(Vector2.ZERO, 13.0, -0.6, 2.4, 14, Color("#FFD23F"), 6.0, true)
			draw_arc(Vector2.ZERO, 13.0, 2.6, 5.2, 14, Color("#3B8BE0"), 6.0, true)
			draw_circle(Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.6))


# ── Sledding with Papa (quest "luge") ───────────────────────────

func _hill(u: float) -> Vector2:
	return ParkArt.hill_point(HILL_X, 596.0, HILL_W, u) + Vector2(0.0, 5.0)


func _slope(u: float) -> float:
	var a := _hill(maxf(u - 0.02, 0.0))
	var b := _hill(minf(u + 0.02, 1.0))
	return clampf((b - a).angle(), -0.7, 0.7)


func _build_luge() -> void:
	# Papa at the foot of the hill, in his winter things, his own sled by his boots.
	var look := CharacterLook.dad()
	Season.dress_for_weather(look)
	_papa = _Visitor.new()
	_papa.look = look
	_papa.lines = ["Prête à glisser, ma grande ?", "Cliquez sur la butte pour glisser !"]
	_papa.position = Vector2(HILL_X + 150.0, 616.0)
	_papa.scale = Vector2.ONE * CHAR_SCALE * 1.18
	_papa.head = -420.0
	_papa.facing = 1
	add_child(_papa)
	_play_spot_first(Rect2(HILL_X + 40.0, 330.0, 760.0, 280.0), _luge_run, HILL_X + 170.0)
	add_child(QuestMark.make(Vector2(HILL_X + 330.0, 330.0), func() -> bool: return Luge.step() == 2 and not _busy and _control.enabled, 0.8))
	var hello := create_tween()
	hello.tween_interval(1.4)
	hello.tween_callback(func() -> void:
		_papa.say("Voilà la petite montagne du parc du Pélican !\nTiens, prends le traîneau, Chachoue.", 3.6)
		_papa.body.express("happy", 3.0))
	hello.tween_interval(4.0)
	hello.tween_callback(func() -> void:
		if not Carry.busy():
			Carry.take(_charlotte, "traineau")
		_say_c("Youpi ! Allons-y !", 2.0))


## The first interactable under a click wins, and the play spots were added before: this one goes to the front of the group.
func _play_spot_first(area: Rect2, action: Callable, stand: float) -> void:
	var door := DoorSpot.make(area, func() -> void:
		if _busy:
			return
		action.call(), stand)
	add_child(door)
	move_child(door, 0)


func _make_sled(big: bool, tint: Color) -> Sprite2D:
	var sled := Sprite2D.new()
	sled.texture = Sledding.sled()
	sled.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sled.scale = Vector2.ONE * (SLED_SCALE * (1.5 if big else 1.0))
	sled.offset = Vector2(24, 0)
	sled.modulate = tint
	add_child(sled)
	_sleds.append(sled)
	return sled


func _sit(who: Character) -> void:
	who.is_walking = false
	who.sitting = true
	who.sit_on_ground = true
	who.seat_h = 0.0
	who.facing = 1


func _luge_run() -> void:
	if _busy or _papa == null or not (Luge.step() == 2 or (ParkOuting.active() and Season.is_winter())):
		return
	var quest := Luge.step() == 2
	var n := Luge.runs() if quest else _free_runs % 3
	_begin_play()
	var c := _charlotte
	var pb := _papa.body
	var together := n == 1
	var race := n == 2
	var with_papa := together or race
	# The sled(s): hers is already in her arms.
	Carry.put_down(c)
	var sled_c := _make_sled(together, Color.WHITE)
	var sled_p: Sprite2D = null
	if race:
		sled_p = _make_sled(false, Color("#6FA8FF"))
	sled_c.visible = false
	if sled_p:
		sled_p.visible = false
	var lines_before := ["Vas-y, Chachoue ! Je te regarde d'en bas !", "On y va ensemble ! Je m'assois derrière toi,\naccroche-toi bien !", "Une course ! Le premier en bas gagne !\nUn, deux, trois, go !"]
	_papa.say(lines_before[n], 3.2)
	c.facing = 1
	c.is_walking = true
	if with_papa:
		pb.facing = 1
		pb.is_walking = true
	var tw := create_tween()
	tw.tween_interval(1.0)
	# Up the hill on foot, the sled under her arm.
	tw.tween_method(func(u: float) -> void:
		c.position = _hill(u)
		if with_papa:
			_papa.position = _hill(maxf(u - 0.035, 0.01)), 0.03, PEAK, 3.4)
	tw.tween_callback(func() -> void:
		_sit(c)
		sled_c.visible = true
		if with_papa:
			_sit(pb)
			if together:
				_papa.position = _hill(PEAK - 0.03)
			else:
				_papa.position = _hill(PEAK - 0.05)
				sled_p.visible = true
		_place_sleds(PEAK, sled_c, sled_p, together)
		_say_c("Wiiiii !" if n != 2 else "Je vais gagner !", 1.6))
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void: Sfx.play("swoosh", c.position))
	# Down the long slope: Charlotte first; Papa, heavier, a little slower.
	tw.tween_method(func(s: float) -> void:
		var uc := lerpf(PEAK, 0.97, ease(s, 1.7))
		c.position = _hill(uc)
		if together:
			_papa.position = _hill(maxf(uc - 0.03, 0.0))
		elif race:
			_papa.position = _hill(lerpf(PEAK - 0.05, 0.93, ease(s * 0.94, 1.7)))
		_place_sleds(uc, sled_c, sled_p, together), 0.0, 1.0, 2.6)
	tw.tween_callback(func() -> void:
		for who: Character in [c, pb]:
			who.sitting = false
			who.sit_on_ground = false
			who.seat_h = 0.0
		for sl in _sleds:
			sl.queue_free()
		_sleds.clear()
		if quest:
			Luge.add_run()
		else:
			_free_runs += 1
		c.express("laugh", 2.0))
	tw.tween_interval(0.6)
	var afters := ["Wouhou ! C'est amusant ! Encore !", "Haha ! Ça va vite à deux !", "Ah ben ! Tu m'as battu, Chachoue ! Tu es très vite !"]
	tw.tween_callback(func() -> void:
		if n == 2:
			_papa.say("Tu m'as battu ! T'es ben plus vite que ton père !", 3.0)
		else:
			_say_c(afters[n], 2.4))
	tw.tween_interval(2.6)
	# Back to the foot: on foot, along the flat.
	tw.tween_callback(func() -> void:
		c.is_walking = true
		c.facing = -1
		if with_papa:
			pb.is_walking = true
			pb.facing = -1)
	tw.tween_method(func(u: float) -> void:
		c.position = Vector2(lerpf(HILL_X + HILL_W * 0.97, HILL_X + 240.0, u), 616.0)
		if with_papa:
			_papa.position = Vector2(lerpf(HILL_X + HILL_W * 0.94, HILL_X + 150.0, u), 616.0), 0.0, 1.0, 2.8)
	tw.tween_callback(func() -> void:
		c.is_walking = false
		pb.is_walking = false
		pb.facing = 1
		c.facing = 1
		if not quest or Luge.runs() < Luge.RUNS:
			if not Carry.busy():
				Carry.take(c, "traineau")
			_end_play_keep()
			if quest:
				_papa.say(["Prête pour la deuxième ? Cette fois, on glisse à deux !", "Dernière descente : une course !"][mini(Luge.runs() - 1, 1)], 3.2)
			else:
				_papa.say(["Encore ? Cette fois, on glisse à deux !", "Une course, cette fois ! Le premier en bas gagne !", "On recommence ? Toute seule, ma grande !"][_free_runs % 3], 3.2)
		else:
			_luge_finish())


func _place_sleds(u: float, sled_c: Sprite2D, sled_p: Sprite2D, together: bool) -> void:
	var ang := _slope(u)
	sled_c.rotation = ang
	sled_c.position = (_charlotte.position + (_papa.position if together else _charlotte.position)) * 0.5 + Vector2(0, -SLED_RIM).rotated(ang) if together else _charlotte.position + Vector2(0, -SLED_RIM).rotated(ang)
	if sled_p:
		var ap := _slope(clampf((_papa.position.x - HILL_X) / HILL_W, 0.0, 1.0))
		sled_p.rotation = ap
		sled_p.position = _papa.position + Vector2(0, -SLED_RIM).rotated(ap)


# After a run Charlotte is free again (hands on, the sled in her arms), waiting at the foot for the next one.
func _end_play_keep() -> void:
	_charlotte.sitting = false
	_charlotte.position.y = 616.0
	_control.hands_off = false
	_busy = false


# The third time down: Papa is proud, and takes her home for a hot chocolate. The quest is done.
func _luge_finish() -> void:
	var steps := create_tween()
	steps.tween_callback(func() -> void:
		_papa.say("Quelle belle journée ! On rentre prendre\nun bon chocolat chaud, ma grande ?", 3.6)
		_charlotte.express("happy", 3.0))
	steps.tween_interval(4.0)
	steps.tween_callback(func() -> void:
		Carry.put_down(_charlotte)
		_say_c("Oui ! Merci, Papa ! C'était trop l'fun !", 2.6)
		Quests.complete(Luge.QUEST))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		Luge.clear()
		_control.enabled = false
		_busy = false
		Transition.inside_x = School.HOME_X
		Transition.street_x = NAN
		Transition.change_scene_saying(self, School.HOME, "Papa te ramène à la maison…", 1.4))


# ── Parts ───────────────────────────────────────────────────────

## The city far behind the park: a row of pale mid-rise blocks (the condos seen over the lawn on Masson), hazy, and a church spire.
class _FarCity:
	extends Node2D
	var seed_value := 0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var base := FOOT - 4.0
		var x := -40.0
		while x < PARK_W:
			var w := rng.randf_range(170.0, 340.0)
			var h := rng.randf_range(110.0, 250.0)
			var tones: Array[Color] = [Color("#D9D7D2"), Color("#CFCCC4"), Color("#E3E0D8"), Color("#C8C9CC")]
			var tone: Color = tones[rng.randi_range(0, 3)]
			draw_rect(Rect2(x, base - h, w, h), tone)
			draw_rect(Rect2(x, base - h, w, 8.0), Color(1, 1, 1, 0.25))
			var fy := base - h + 22.0
			while fy < base - 18.0:
				var wx := x + 12.0
				while wx < x + w - 24.0:
					draw_rect(Rect2(wx, fy, 18.0, 14.0), Color("#8E9AA4", 0.55))
					wx += 30.0
				fy += 34.0
			x += w + rng.randf_range(10.0, 90.0)
		# The haze over it all, so it sits far away.
		draw_rect(Rect2(0, base - 270.0, PARK_W, 280.0), Color("#C9D6E2", 0.5))
		for k in 5:
			draw_rect(Rect2(0, base - 270.0 + k * 54.0, PARK_W, 54.0), Color("#C9D6E2", 0.06))
		var sx := 1400.0
		while sx < PARK_W:
			draw_colored_polygon(PackedVector2Array([Vector2(sx - 22.0, base - 150.0), Vector2(sx, base - 330.0), Vector2(sx + 22.0, base - 150.0)]), Color("#B7C1CC", 0.7))
			sx += 3900.0


## One piece of the park, drawn by `ParkArt`: `spec.kind` says which. Animated ones redraw only near the view.
class _Piece:
	extends Node2D

	var spec := {}
	var t := 0.0
	## A swing or spring rider she is on (the scene drives it while she rides).
	var ride_k := -1
	var ride_a := 0.0
	var ride := false

	func _process(delta: float) -> void:
		if not spec.get("animated", false):
			set_process(false)
			return
		if OnScreen.near(self, 900.0):
			t += delta
			queue_redraw()

	func _draw() -> void:
		var s := spec
		match s.kind:
			"gate":
				ParkArt.gate(self, 0.0, 0.0)
			"sign":
				ParkArt.sign_board(self, 0.0, 0.0, s.w, s.h)
			"bench":
				ParkArt.bench(self, 0.0, 0.0)
			"bin":
				ParkArt.trash_bin(self, 0.0, 0.0)
			"lamp":
				ParkArt.lamp(self, 0.0, 0.0)
			"fountain":
				ParkArt.drinking_fountain(self, 0.0, 0.0)
			"iron_fence":
				ParkArt.iron_fence(self, 0.0, s.x1 - s.x, 0.0, s.h)
			"chain_fence":
				var gate_at: float = s.get("gate_at", -1.0) - s.x
				ParkArt.chain_fence(self, 0.0, s.x1 - s.x, 0.0, s.h, gate_at, s.get("gate_w", 0.0), s.get("alpha", 0.5))
			"wading_pool":
				ParkArt.wading_pool(self, Vector2.ZERO, s.r, t)
			"water_mushroom":
				ParkArt.water_mushroom(self, 0.0, 0.0, t)
			"dog_park":
				var d: float = 160.0
				ParkArt.flat_rect(self, Rect2(0.0, 0.0, s.w, d), Color("#B8946A") if not Season.is_winter() else Color("#EEF3F8"), 4.0)
				ParkArt.bench(self, s.w - 150.0, 48.0, 90.0)
				# A low agility tunnel and a hurdle.
				draw_arc(Vector2(120.0, 52.0), 32.0, PI, TAU, 12, Color("#E8812E"), 14.0, true)
				draw_rect(Rect2(300.0, 30.0, 60.0, 4.0), Color("#FFFFFF"))
				draw_rect(Rect2(300.0, 30.0, 4.0, 22.0), Color("#E04F5F"))
				draw_rect(Rect2(356.0, 30.0, 4.0, 22.0), Color("#E04F5F"))
			"chalet":
				ParkArt.chalet(self, 0.0, 0.0, s.w)
			"hedge":
				ParkArt.hedge(self, 0.0, 0.0, s.w)
			"swim_pool":
				ParkArt.swim_pool(self, 0.0, 0.0, s.w, s.d, t)
			"lifeguard":
				ParkArt.lifeguard_chair(self, 0.0, 0.0)
			"ladder":
				ParkArt.pool_ladder(self, 0.0, 0.0)
			"parasol":
				ParkArt.parasol(self, 0.0, 0.0, s.color)
			"rubber":
				ParkArt.rubber_floor(self, 0.0, 0.0, s.w, s.d)
			"sandbox":
				ParkArt.sandbox(self, 0.0, 0.0, s.w)
			"structure":
				ParkArt.play_structure(self, 0.0, 0.0)
			"swings":
				ParkArt.swing_set(self, 0.0, 0.0, t, ride_k, ride_a)
			"spring":
				ParkArt.spring_rider(self, 0.0, 0.0, s.color, t, ride)
			"castle":
				ParkArt.sandcastle(self, 0.0, 0.0)
			"court":
				ParkArt.court(self, 0.0, 0.0, s.w, s.d)
			"boards":
				ParkArt.boards(self, 0.0, s.x1 - s.x, 0.0)
			"net":
				ParkArt.hockey_net(self, 0.0, 0.0, s.facing)
			"hoop":
				ParkArt.basketball_hoop(self, 0.0, 0.0, s.facing)
			"pingpong":
				ParkArt.ping_pong(self, 0.0, 0.0)
			"hill":
				ParkArt.hill(self, 0.0, 0.0, s.w)


## The lawn, the paths, the leaves: one flat drawing under everything, behind the line she walks on.
class _Ground:
	extends Node2D
	var seed_value := 0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + 9
		var winter := Season.is_winter()
		draw_rect(Rect2(0, FOOT, PARK_W, 720.0 - FOOT), ParkArt.lawn())
		for k in 8:
			draw_rect(Rect2(0, FOOT + k * 20.0, PARK_W, 20.0), Color(0, 0, 0, 0.012 * k) if not winter else Color(0.55, 0.65, 0.8, 0.014 * k))
		draw_rect(Rect2(0, FOOT, PARK_W, 12.0), Color(1, 1, 1, 0.1))
		# The stroller-friendly path of stone dust, winding along the front of everything (trodden snow in winter).
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		var x := 0.0
		while x <= PARK_W:
			var wob := 7.0 * sin(x / 260.0)
			top.append(Vector2(x, 616.0 + wob))
			bottom.append(Vector2(x, 676.0 + wob))
			x += 40.0
		var strip := top.duplicate()
		for i in range(bottom.size() - 1, -1, -1):
			strip.append(bottom[i])
		draw_colored_polygon(strip, Color("#D8CBB0") if not winter else Color("#DDE5EC"))
		draw_polyline(top, Color(1, 1, 1, 0.35), 2.0, true)
		# The paved places: the court and ping-pong, the chalet's apron, the pools' decks come with their pieces.
		draw_rect(Rect2(COURT_X - 40.0, 562.0, COURT_W + 80.0, 50.0), Color("#8E9096") if not winter else Color("#E4ECF2"))
		draw_rect(Rect2(COURT_X + COURT_W + 60.0, 578.0, 200.0, 36.0), Color("#8E9096") if not winter else Color("#E4ECF2"))
		draw_rect(Rect2(CHALET_X - 40.0, 586.0, CHALET_W + 80.0, 30.0), Color("#B4B0A8") if not winter else Color("#E4ECF2"))
		for i in 1400:
			var px := rng.randf_range(0.0, PARK_W)
			var py := rng.randf_range(FOOT, 720.0)
			draw_rect(Rect2(px, py, rng.randf_range(1.0, 3.0), 1.2), Color(1, 1, 1, 0.08) if rng.randf() < 0.5 else Color(0, 0, 0, 0.08))
		if Season.current == "autumn":
			var litter: Array[Color] = Season.litter()
			for i in 420:
				var lx := rng.randf_range(0.0, PARK_W)
				var ly := FOOT + absf(rng.randfn(0.0, 40.0)) + 8.0
				draw_set_transform(Vector2(lx, ly), rng.randf_range(-1.0, 1.0), Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, rng.randf_range(3.0, 6.0), litter[rng.randi_range(0, litter.size() - 1)])
			draw_set_transform(Vector2.ZERO)
		elif Season.current == "spring" or Season.current == "summer":
			for i in 160:
				var fx := rng.randf_range(0.0, PARK_W)
				var fy := rng.randf_range(FOOT + 10.0, 700.0)
				draw_circle(Vector2(fx, fy), 2.2, [Color("#FFFFFF"), Color("#FFD23F"), Color("#FF7BA3")][i % 3])


## A person in the park: idle with a line or two, or (winter, "slide") a child climbing the hill and sliding down it on her bottom.
class _Visitor:
	extends Node2D

	var look: CharacterLook
	var lines: Array = []
	var mode := "idle"
	var facing := 1
	var phase := 0.0
	var head := -340.0
	var hill := Vector2.ZERO
	var hill_w := 1100.0
	var body: Character
	var _line := 0
	var _t := 0.0

	func _ready() -> void:
		body = Character.new()
		body.look = look
		body.facing = facing
		body.fidgets = mode == "idle"
		body.walk_speed = 130.0
		add_child(body)
		_t = phase
		add_to_group("interactable")

	func _process(delta: float) -> void:
		if mode != "slide":
			return
		_t += delta
		# A turn: up the near slope on foot (9 s), a rest at the top (1.5 s), down the long one (3 s), back along the foot (4 s).
		var cycle := 17.5
		var s := fposmod(_t, cycle)
		var peak := 0.32
		if s < 9.0:
			var u := lerpf(0.02, peak, s / 9.0)
			_place(u)
			body.sitting = false
			body.is_walking = true
			body.facing = 1
		elif s < 10.5:
			_place(peak)
			body.is_walking = false
			body.sitting = true
			body.sit_on_ground = true
			body.seat_h = 0.0
		elif s < 13.5:
			var u2 := lerpf(peak, 0.97, ease((s - 10.5) / 3.0, 1.7))
			_place(u2)
			body.facing = 1
		else:
			var u3 := lerpf(0.97, 0.02, (s - 13.5) / 4.0)
			body.sitting = false
			body.is_walking = true
			body.facing = -1
			position = Vector2(hill.x + hill_w * u3, hill.y + 6.0)

	func _place(u: float) -> void:
		position = Vector2(hill.x + hill_w * u, hill.y - ParkArt.hill_height(u) + 5.0)

	func say(text: String, seconds := 2.4) -> void:
		body.express("talk", Bubble.reading_time(text, seconds) * 0.8)
		Bubble.say(get_parent(), global_position + Vector2(0, head) * scale - Vector2(0, 12), text, seconds)

	func can_interact() -> bool:
		return true

	func hit_test(p: Vector2) -> bool:
		return Rect2(global_position + Vector2(-60, head) * scale, Vector2(120, -head) * scale).has_point(p)

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


## A ball, a puck: drawn by `ParkArt.ball`, moved by the scene's tweens.
class _Ball:
	extends Node2D
	var kind := "basket"

	func _draw() -> void:
		ParkArt.ball(self, kind)


## Drops of water thrown up and falling back (the fountain, her splashing).
class _Spray:
	extends Node2D
	var life := 1.2
	var _t := 0.0
	var _seed := 0

	func _ready() -> void:
		_seed = randi()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > life:
			queue_free()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed
		for k in 16:
			var vx := rng.randf_range(-70.0, 70.0)
			var vy := rng.randf_range(-190.0, -90.0)
			var t := fmod(_t + rng.randf_range(0.0, 0.3), 0.9)
			var p := Vector2(vx * t, vy * t + 260.0 * t * t)
			draw_circle(p, 2.6, Color(0.7, 0.9, 1.0, clampf(1.0 - _t / life, 0.0, 1.0)))


## A dog of the dog park, running up and down inside the fence.
class _DogRunner:
	extends Node2D

	var lo := 0.0
	var hi := 100.0
	var y := 584.0
	var fur := Color("#C98A4A")
	var _dir := 1.0
	var _t := 0.0
	var _rest := 0.0

	func _ready() -> void:
		add_to_group("interactable")

	func can_interact() -> bool:
		return true

	func hit_test(p: Vector2) -> bool:
		return Rect2(global_position + Vector2(-50, -70), Vector2(110, 80)).has_point(p)

	func approach_x(_from_x: float) -> float:
		return global_position.x

	func focus_x() -> float:
		return global_position.x

	func reserve() -> void:
		pass

	func release() -> void:
		pass

	func interact(_who: Character) -> void:
		Sfx.play("bark", global_position)
		_rest = 1.0
		Bubble.say(get_parent(), global_position + Vector2(0, -90), ["Ouaf !", "Ouaf ouaf !", "Wouf !"][randi() % 3], 1.4)

	func _process(delta: float) -> void:
		if not OnScreen.near(self, 600.0):
			return
		_t += delta
		if _rest > 0.0:
			_rest -= delta
		else:
			position.x += _dir * 150.0 * delta
			if position.x > hi or position.x < lo or randf() < 0.004:
				_dir = -_dir
				_rest = randf_range(0.4, 1.6)
		queue_redraw()

	func _draw() -> void:
		ParkArt.dog(self, Vector2.ZERO, _dir, _t if _rest <= 0.0 else _t * 0.2, fur)
