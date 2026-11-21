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
	["chiens", DOG_X + DOG_W * 0.5, 230.0, DOG_X + DOG_W * 0.5, ["Les chiens courent en liberté, là-dedans !\nIls ont ben du fun.", "Les chiens jouent dans la neige !"]],
	["chalet", CHALET_X + CHALET_W * 0.5, 280.0, CHALET_X + CHALET_W * 0.5, ["Le chalet : les toilettes, pis un coin pour se reposer.", "Le chalet est chaud : on peut se réchauffer !"]],
	["piscine", POOL_X + POOL_W * 0.5, 480.0, POOL_X + POOL_W * 0.5, ["La grande piscine ! On va nager quand il fait chaud.", "C'est la patinoire, astheure ! Faut des patins."]],
	["jeux", PLAY_X + 330.0, 480.0, PLAY_X + 330.0, ["Les modules de jeux ! Ma glissoire préférée !", "Les balançoires sont gelées, mais les modules sont beaux."]],
	["court", COURT_X + COURT_W * 0.5, 330.0, COURT_X + COURT_W * 0.5, ["Le terrain de basketball.\nOn peut aussi jouer au ping-pong !", "La patinoire avec bandes : on joue au hockey !"]],
	["butte", HILL_X + HILL_W * 0.4, 360.0, HILL_X + 240.0, ["La butte de glissade ! L'hiver, on glisse dessus.", "La butte de glissade ! Faut juste un traîneau !"]],
]

var _from_x := NAN
var _visitors: Array[_Visitor] = []


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


func _process(_delta: float) -> void:
	_follow_charlotte()


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
	back.append({"kind": "iron_fence", "x": WADING_X - 230.0, "x1": WADING_X + 230.0, "y": 620.0, "h": 42.0})
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
	for spec: Dictionary in back:
		var piece := _Piece.new()
		piece.spec = spec
		piece.position = Vector2(spec.x, spec.y)
		add_child(piece)


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
	if winter:
		for k in 3:
			plan.append({"x": HILL_X + 40.0 + k * 40.0, "y": 596.0, "mode": "slide", "phase": k * 3.1, "lines": ["Wouhou ! Ça glisse en malade !", "Mes pantalons de neige sont tout mouillés !"]})
		plan.append({"x": POOL_X + 300.0, "y": BACK_Y + 14.0, "lines": ["Chu pas capable de tenir debout sur mes patins !", "La glace est belle aujourd'hui !"]})
	else:
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
	for spot: Array in SPOTS:
		var line: String = spot[4][1 if Season.is_winter() else 0]
		var x: float = spot[1]
		var half: float = spot[2]
		var id: String = spot[0]
		add_child(DoorSpot.make(Rect2(x - half, 400.0, half * 2.0, 230.0), func() -> void: _spot_clicked(id, line), spot[3]))


## A place of the park was clicked: what she says. (The activities will start from here: playground, pools, sliding.)
func _spot_clicked(_id: String, line: String) -> void:
	Bubble.say(self, _charlotte.position + Vector2(0, -190), line, 3.4)


func _leave_by_gate() -> void:
	_control.enabled = false
	# Out the way she came in: Masson's south side, at the lawn.
	Transition.street_x = float(GameState.flags.get("park_from_x", NAN))
	Transition.change_scene(self, "res://scenes/masson_pair.tscn")


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
				ParkArt.swing_set(self, 0.0, 0.0, t)
			"spring":
				ParkArt.spring_rider(self, 0.0, 0.0, s.color, t)
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
