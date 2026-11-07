extends Interior
# ══════════════════════════════════════════════════════════════
# Inside Charlotte's flat, as a side-on cross-section (from reference/maison_charlotte/interieur):
# vestibule → oak glass doorway → salon (sofa, dining table) → hallway → kitchen at the back.
# Her bedroom ("chacha" on the door) is a separate area further right, reached through its door.
# Click the front door to go back out to the street. The generic parts live in Interior and RoomShell.
# Usage: Godot --path . res://scenes/house.tscn -- --screenshot=/tmp/house.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const HALL := Vector2(0, 3960)
const BEDROOM := Vector2(5000, 6650)
const VESTIBULE_END := 640.0
const SALON_END := 2260.0
const KITCHEN_START := 3400.0
const CHACHA_DOOR_X := 3120.0
## Papa's upright piano and Maman's potter's wheel, against the corridor wall.
const PIANO_X := 2300.0
const POTTERY_X := 2520.0
const BEDROOM_DOOR_X := 6440.0
const MOM_LINES := ["Bonjour ma chouette !", "As-tu faim ? Il y a des fruits.", "N'oublie pas de nourrir le hamster !", "Je t'aime, Chachoue !"]
const DAD_LINES := ["Salut Chachoue !", "On va au parc tantôt ?", "As-tu fait un beau dessin ?", "Tu veux jouer avec moi ?"]
# What's lying on the bedroom floor (kind, x in the bedroom). Tidying: she picks each one up in her arms (Carry "toy"), says
# where it goes, and the child clicks that spot to put it away. ITEMS: how she names it ("va" / "vont") and its DESTS entry.
const MESS := [["teddy", 200.0], ["pyjama", 313.0], ["sock", 426.0], ["blocks", 539.0], ["book", 652.0], ["puzzle", 765.0],
	["ball", 878.0], ["car", 991.0], ["tshirt", 1104.0], ["crayons", 1217.0], ["sneaker", 1330.0]]
const ITEMS := {
	"teddy": {"name": "Mon toutou", "verb": "va", "dest": "lit"},
	"pyjama": {"name": "Mon pyjama", "verb": "va", "dest": "panier"},
	"sock": {"name": "Mes bas", "verb": "vont", "dest": "panier"},
	"tshirt": {"name": "Mon t-shirt", "verb": "va", "dest": "panier"},
	"blocks": {"name": "Mes blocs", "verb": "vont", "dest": "jouets"},
	"ball": {"name": "Mon ballon", "verb": "va", "dest": "jouets"},
	"car": {"name": "Mon auto", "verb": "va", "dest": "jouets"},
	"book": {"name": "Mon livre", "verb": "va", "dest": "etagere"},
	"puzzle": {"name": "Mon casse-tête", "verb": "va", "dest": "bureau"},
	"crayons": {"name": "Mes crayons", "verb": "vont", "dest": "bureau"},
	"sneaker": {"name": "Mon espadrille", "verb": "va", "dest": "porte"},
}
# Where things go, in the bedroom's own x: the clickable area, where she stands, and how she says it.
const DESTS := {
	"lit": {"text": "sur mon lit", "rect": Rect2(360, 380, 448, 228), "stand": 600.0},
	"panier": {"text": "dans le panier à linge", "rect": Rect2(1290, 500, 120, 125), "stand": 1345.0},
	"jouets": {"text": "dans le coin des jouets", "rect": Rect2(760, 500, 160, 130), "stand": 840.0},
	"etagere": {"text": "sur l'étagère", "rect": Rect2(960, 280, 170, 200), "stand": 1040.0},
	"bureau": {"text": "sur mon bureau", "rect": Rect2(1110, 430, 190, 180), "stand": 1170.0},
	"porte": {"text": "près de la porte", "rect": Rect2(1440, 200, 150, 400), "stand": 1385.0},
}
const CAN_X := KITCHEN_START + 470.0
# The tip of the watering can's spout, in the held can's own space (its texture is centred, offset by (30, -4)).
const CAN_SPOUT := Vector2(86, -24)
# She steps up to the plant (toward the wall it stands against) to pour.
const POUR_STEP := 54.0
# How far in front of Charlotte the spout is while she pours (world px): she stands that far from the soil.
const POUR_REACH := 92.0
const SNACKS := [["apple", "Une pomme !"], ["yogurt", "Un yogourt !"], ["cheese", "Du fromage !"],
	["grapes", "Des raisins !"], ["carrot", "Une carotte !"], ["cookie", "Un biscuit !"]]

# Lights that the switches and the floor lamp turn on and off.
var _vestibule_light: Sprite2D
var _salon_pendant: Sprite2D
# The front of the sofa drawn over whoever sits in it (only shown while someone does).
var _sofa_front: Sprite2D
var _sofa_seat: Seat
var _floor_lamp: Array = []
var _hall_lights: Array = []
var _bedroom_lights: FairyLights
# Charlotte's drawings stuck on the fridge door with magnets.
var _fridge_art: Node2D
var _fridge_busy := false
var _mom_routine: FamilyRoutine
var _dad_routine: FamilyRoutine
var _mom: Character
var _dad: Character
var _mom_line := 0
var _dad_line := 0
# The house plants to water (id → sprite) and the watering can in the kitchen.
var _plants := {}
var _can: Sprite2D
# The can in her hands while she carries it, and whether she is pouring.
var _held_can: Sprite2D
var _can_shadows: Array[Node] = []
var _pouring := false


## For the plate at the top of the screen (PlaceLabel).
func room_name() -> String:
	if _charlotte == null:
		return ""
	var x := _charlotte.position.x
	if x >= BEDROOM.x:
		return "Ma chambre"
	if x >= KITCHEN_START:
		return "Chez moi : la cuisine"
	if x >= SALON_END:
		return "Chez moi : le corridor"
	if x >= VESTIBULE_END:
		return "Chez moi : le salon"
	return "Chez moi : le vestibule"


func _ready() -> void:
	_build_shell()
	_build_vestibule()
	_build_salon()
	_build_hallway()
	_build_bedroom()
	_build_family()
	_build_switches()
	_spawn_charlotte(470.0)
	_build_chores()
	_build_doors()
	_enter_area(BEDROOM if _charlotte.position.x >= BEDROOM.x else HALL)
	_finish([[700.0, "plant"], [1900.0, "plant"], [2900.0, "plant"], [5400.0, "plushie"], [6250.0, "plant"]])


# Charlotte's own music at home (audio/music/maison-charlotte.mp3), else the generic house theme or the street's.
func _music() -> Array:
	return ["maison-charlotte", "house", "street_" + Season.current, "street"]


# Walls, ceiling and floor of each room; white-painted trim in the hall (as in the photos), oak in the bedroom.
func _build_shell() -> void:
	var shell := RoomShell.new()
	shell.rooms = [
		{"from": 0.0, "to": VESTIBULE_END, "wall": Color("#ECE8DF"), "base": Color("#F4F1EA"), "wainscot": Color("#DCD6C8"), "wainscot_height": 170.0},
		{"from": VESTIBULE_END, "to": SALON_END, "wall": Color("#E9DCC2"), "base": Color("#6E4424"), "pattern": "stripes", "pattern_color": Color("#C9B48A"), "pattern_alpha": 0.5},
		{"from": SALON_END, "to": HALL.y, "wall": Color("#EEEBE5"), "base": Color("#F4F1EA"), "pattern": "diamonds", "pattern_color": Color("#C9C2B4"), "pattern_alpha": 0.45, "wainscot": Color("#E6E0D2"), "wainscot_height": 150.0},
		{"from": BEDROOM.x, "to": BEDROOM.y, "wall": Color("#F2E6EE"), "base": Color("#F4F1EA"), "pattern": "stars", "pattern_color": Color("#E6A3C2"), "pattern_alpha": 0.5, "wainscot": Color("#F7C9DA"), "wainscot_height": 150.0},
	]
	shell.chair_rails = [{"from": 0.0, "to": VESTIBULE_END, "y": 420.0}]
	shell.posts = [SALON_END]
	shell.casings = [
		{"x": CHACHA_DOOR_X, "w": 150.0, "top": 170.0, "color": Color("#F4F1EA")},
		{"x": BEDROOM_DOOR_X, "w": 150.0, "top": 170.0, "color": Color("#8A5228")},
	]
	shell.gleams = [320.0, 410.0, 1524.0, 1665.0, 1984.0, 2600.0, 3200.0, KITCHEN_START + 322.0, BEDROOM.x + 180.0, BEDROOM.x + 700.0]
	add_child(shell)


# Mom starts in the kitchen by the stove, Dad in the salon by the dining table, and each goes about their own chores (a
# FamilyRoutine). Click them for a word: they stop and turn to Charlotte.
# Maman's days turn round her passions: her pottery wheel, cooking, and a good coffee. Papa's: his bike, the piano, and jogging.
# `work` says where their hands go (x from where they stand, y in the world), `sit` seats them, `jog` runs on the spot.
const MOM_TASKS := [
	{"x": POTTERY_X + 18.0, "facing": 1, "task": "pottery", "prop": "clay", "prop_at": Vector2(82.0, 505.0), "work": [Vector2(70.0, 512.0), Vector2(92.0, 516.0)], "sit": 92.0, "floor": 654.0,
		"secs": 22.0, "say": ["Mon beau pot !", "Ça tourne, ça tourne…"], "done_say": ["Y est pas pire, han ?"]},
	{"x": KITCHEN_START + 340.0, "facing": -1, "task": "drink", "prop": "mug", "secs": 12.0, "say": ["Un bon café…", "Chu pas réveillée sans mon café !"]},
]
const DAD_TASKS := [
	# In the clouds, staring at nothing, a little moon floating before his empty gaze.
	{"x": 1380.0, "facing": 1, "task": "daydream", "prop": "moon", "secs": 14.0, "say": [], "done_say": ["Oups ! J'étais encore dans la lune !"]},
	{"x": 1650.0, "facing": -1, "task": "drink", "prop": "mug", "secs": 12.0, "say": ["Quel beau temps !", "Un p'tit café pis ça va mieux."]},
]


func _build_family() -> void:
	_mom = _family_member(CharacterLook.mom(), KITCHEN_START + 300.0, -1)
	_dad = _family_member(CharacterLook.dad(), 1720.0, -1)
	_mom_routine = _routine(_mom, MOM_TASKS, _talk_to_mom, Vector2(0, -350), func() -> bool:
		return Quests.available("milk") or Quests.available("menage") or Quests.available("amies") or Quests.active("milk") and Carry.has("milk"))
	_dad_routine = _routine(_dad, DAD_TASKS, _talk_to_dad, Vector2(0, -360), func() -> bool:
		return Quests.available("hamster") or Quests.available("plants"))


# A parent's routine with its click area and its "!" (over whoever has a quest for Charlotte, or is waiting for what she brings).
func _routine(who: Character, tasks: Array, on_click: Callable, mark_at: Vector2, has_quest: Callable) -> FamilyRoutine:
	var routine := FamilyRoutine.new()
	routine.who = who
	routine.tasks = tasks
	routine.spot = DoorSpot.make(Rect2(who.position.x - 55.0, 330, 110, 340), on_click, who.position.x - 90.0)
	add_child(routine.spot)
	var mark := QuestMark.make(who.position + mark_at, has_quest)
	add_child(mark)
	routine.mark = mark
	routine.mark_offset = mark_at
	add_child(routine)
	return routine


# Mom asks for milk, sends her to the dépanneur, and thanks her when she brings it home.
func _talk_to_mom() -> void:
	_mom_routine.pause(4.0, _charlotte.position.x)
	if Quests.active("milk") and Carry.has("milk"):
		Carry.put_down(_charlotte)
		_say(_mom, "Du lait ! Merci, Chachoue !", 350.0)
		Quests.complete("milk")
	elif Halloween.step() == 3:
		_count_the_candy()
	elif Halloween.step() == 2:
		_say(_mom, "Amuse-toi bien, ma chouette !\nReviens quand ton sac sera plein.", 400.0, 3.5)
	elif Halloween.step() == 1:
		_say(_mom, "Ton déguisement est dans ta commode,\nma chouette ! Vas-y !", 400.0, 3.5)
	elif Quests.start("halloween"):
		_say(_mom, "C'est l'Halloween ce soir, Chachoue !\nVa vite te déguiser dans ta chambre !", 420.0, 4.0)
		Halloween.set_step(1)
	elif Quests.start("amies"):
		if Twins.met():
			# She has already met them on her own.
			_say(_mom, "Tu as rencontré les jumelles Turcotte ?\nQuelle belle surprise, bravo !", 400.0, 3.5)
			Quests.complete("amies")
		else:
			_say(_mom, "Va jouer dans la ruelle, ma chouette !\nTu t'y feras peut-être des amies.", 400.0, 3.5)
	elif Quests.start("milk"):
		_say(_mom, "Chachoue, peux-tu aller me chercher\ndu lait au dépanneur ?", 380.0, 3.5)
	elif Quests.active("milk"):
		_say(_mom, "Le dépanneur est au coin\nde la rue Dandurand !", 380.0)
	elif Quests.start("menage"):
		_say(_mom, "Ta chambre est en désordre,\nva la ranger, ma chouette !", 380.0, 3.5)
	elif Quests.active("menage"):
		_say(_mom, "As-tu fini de ranger\nta chambre ?", 380.0)
	elif Quests.active("amies"):
		_say(_mom, "Les enfants jouent dans la ruelle du milieu,\nderrière chez nous !", 400.0)
	else:
		_say(_mom, MOM_LINES[_mom_line % MOM_LINES.size()], 350.0)
		_mom_line += 1


func _talk_to_dad() -> void:
	_dad_routine.pause(4.0, _charlotte.position.x)
	if Quests.start("hamster"):
		_say(_dad, "N'oublie pas de nourrir\nton hamster !", 390.0, 3.5)
	elif Quests.start("plants"):
		_say(_dad, "Les plantes ont soif ! L'arrosoir\nest dans la cuisine.", 390.0, 3.5)
	elif Quests.active("plants"):
		_say(_dad, "Deux au salon, deux dans le corridor\net une dans ta chambre !", 390.0, 3.5)
	else:
		_say(_dad, DAD_LINES[_dad_line % DAD_LINES.size()], 360.0)
		_dad_line += 1


# ── Chores: tidying her room, watering the plants ───────────

func _build_chores() -> void:
	var tidied: Array = GameState.flags.get("tidied", [])
	if not Quests.done("menage"):
		for m in MESS:
			# One she is holding right now (the scene reopened) or already put away is not on the floor.
			if tidied.has(m[0]) or Carry.item() == "toy:" + str(m[0]):
				continue
			var item := _put(InteriorArt.mess(m[0]), BEDROOM.x + m[1], 690.0, 1.15)
			add_child(DoorSpot.make(Rect2(item.position - Vector2(6, 10), Vector2(104, 66)), _pick_up.bind(m[0], item), BEDROOM.x + m[1] + 32.0))
		# The places things go: clickable (and marked with a "!") only while she holds a toy that goes there.
		for dest_id: String in DESTS:
			var d: Dictionary = DESTS[dest_id]
			var rect: Rect2 = d.rect
			var spot := DoorSpot.make(Rect2(rect.position + Vector2(BEDROOM.x, 0.0), rect.size), _put_away.bind(dest_id), BEDROOM.x + float(d.stand))
			spot.condition = func() -> bool: return Carry.has("toy")
			add_child(spot)
			add_child(QuestMark.make(Vector2(BEDROOM.x + rect.get_center().x, rect.get_center().y - 20.0), func() -> bool:
				return Carry.has("toy") and ITEMS[Carry.id()].dest == dest_id, 0.8))
	for id in _plants:
		var plant: Sprite2D = _plants[id]
		if _thirsty(id):
			plant.texture = plant.get_meta("thirsty")
		var area := Rect2(plant.position, plant.texture.get_size() * plant.scale)
		var spot := DoorSpot.make(area, _water.bind(id))
		# She stands beside the pot, on the side she comes from, the spout over the soil.
		var soil_x := _soil(id).x
		spot.approach = func(from_x: float) -> float: return soil_x - POUR_REACH if from_x < soil_x else soil_x + POUR_REACH
		add_child(spot)
	var before := get_child_count()
	_can = _put(InteriorArt.watering_can(), CAN_X, 606.0, 0.55, "floor")
	# Its shadows (cast and on the floor) go and come back with it.
	_can_shadows = get_children().slice(before, get_child_count() - 1)
	add_child(DoorSpot.make(Rect2(_can.position - Vector2(10, 20), Vector2(86, 70)), _take_can, CAN_X + 30.0))
	add_child(QuestMark.make(_can.position + Vector2(33, -40), func() -> bool:
		return Quests.active("plants") and not Carry.has("can"), 0.8))
	if Carry.has("can"):
		_adopt_can.call_deferred()


# A plant to water: healthy and thirsty pictures kept on the sprite, a contact shadow when it stands on the floor.
func _plant(id: String, kind: String, x: float, bottom: float, scale: float) -> void:
	var healthy := InteriorArt.house_plant(kind, false)
	if kind != "pothos":
		_floor_shadow(x + 120.0 * scale, bottom, 40.0 * scale)
	var sprite := _put(healthy, x, bottom, scale)
	sprite.set_meta("healthy", healthy)
	sprite.set_meta("thirsty", InteriorArt.house_plant(kind, true))
	sprite.set_meta("soil", InteriorArt.plant_soil(kind))
	_plants[id] = sprite


func _thirsty(id: String) -> bool:
	return not Quests.done("plants") and not (GameState.flags.get("watered", []) as Array).has(id)


# She crouches and picks it up in her arms (the one thing she holds), then says where it goes.
func _pick_up(kind: String, item: Sprite2D) -> void:
	if not is_instance_valid(item) or item.has_meta("taken"):
		return
	# Only once Mom has asked her to.
	if not Quests.active("menage"):
		_say(_charlotte, "Je rangerai ça plus tard…", 300.0)
		return
	if not Carry.take(_charlotte, "toy", kind):
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	item.set_meta("taken", true)
	_charlotte.pet(0.7, 1.0)
	Sfx.play("pop", item.position)
	# It flies from the floor into her arms (hidden there until it arrives).
	var held := _charlotte.held()
	held.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(item, "global_position", held.global_position + Vector2(0.0, -20.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(item, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		item.queue_free()
		if is_instance_valid(held):
			held.modulate.a = 1.0
		_say(_charlotte, _where(kind), 300.0, 3.4))


# "Mon toutou va sur mon lit !"
func _where(kind: String) -> String:
	var it: Dictionary = ITEMS[kind]
	return "%s %s %s !" % [it.name, it.verb, DESTS[it.dest].text]


# She clicked a place while holding a toy: right, it goes there; wrong, she says where it should go.
func _put_away(dest_id: String) -> void:
	if not Carry.has("toy"):
		return
	var kind := Carry.id()
	if ITEMS[kind].dest != dest_id:
		_charlotte.express("worry", 2.2)
		_say(_charlotte, "Pas ici ! " + _where(kind), 300.0, 3.4)
		return
	var held := _charlotte.held()
	var from := held.global_position if held else _charlotte.position
	Carry.put_down(_charlotte)
	_charlotte.pet(0.6, 0.4)
	Sfx.play("pop", from)
	var rect: Rect2 = DESTS[dest_id].rect
	var fly := Sprite2D.new()
	fly.texture = InteriorArt.mess(kind)
	fly.scale = Vector2.ONE * 0.75
	fly.position = from
	add_child(fly)
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(fly, "position", Vector2(BEDROOM.x + rect.get_center().x, rect.get_center().y), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fly, "scale", fly.scale * 0.5, 0.45)
	tween.parallel().tween_property(fly, "modulate:a", 0.0, 0.45)
	tween.tween_callback(fly.queue_free)
	var tidied: Array = GameState.flags.get("tidied", [])
	tidied.append(kind)
	GameState.flags["tidied"] = tidied
	if tidied.size() >= MESS.size():
		GameState.flags.erase("tidied")
		_say(_charlotte, "Ma chambre est toute propre !", 300.0)
		_charlotte.express("laugh", 2.4)
		Quests.complete("menage")
	else:
		_say(_charlotte, "Voilà ! Encore %d !" % (MESS.size() - tidied.size()), 300.0, 2.0)


func _take_can() -> void:
	if Quests.done("plants") or Carry.has("can"):
		_say(_charlotte, "C'est l'arrosoir.", 300.0)
		return
	if not Carry.take(_charlotte, "can"):
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	Quests.start("plants")
	Sfx.play("pop", _can.position)
	_adopt_can()


# The can in her arms (just taken, or put back there by Carry as the scene opened): the one on the kitchen floor goes.
func _adopt_can() -> void:
	Carry.restore(_charlotte)
	_held_can = _charlotte.held() as Sprite2D
	_show_can(false)


func _show_can(shown: bool) -> void:
	_can.visible = shown
	for shadow in _can_shadows:
		shadow.visible = shown


func _water(id: String) -> void:
	var plant: Sprite2D = _plants[id]
	if not _thirsty(id):
		_say(_charlotte, "Elle a assez bu !" if Quests.done("plants") or Quests.active("plants") else "Elle est belle, cette plante.", 300.0)
		return
	if not Carry.has("can") or _held_can == null:
		_say(_charlotte, "Elle a soif… Il me faut\nl'arrosoir de la cuisine !", 300.0, 3.0)
		return
	if _pouring:
		return
	# She faces the pot, lifts the can and tips it: water runs from the spout onto the soil, then she lowers it and the
	# plant perks up and greens again.
	_pouring = true
	var soil := _soil(id)
	_charlotte.facing = 1 if soil.x > _charlotte.position.x else -1
	_control.enabled = false
	var can := _held_can
	var floor_y := _charlotte.position.y
	var tween := create_tween()
	tween.tween_callback(func(): _charlotte.is_walking = true)
	tween.tween_property(_charlotte, "position:y", floor_y - POUR_STEP, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): _charlotte.is_walking = false)
	tween.tween_property(_charlotte, "carry_lift", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(can, "rotation", 0.5, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		Sfx.play("swoosh", soil)
		for k in 24:
			get_tree().create_timer(k * 0.045).timeout.connect(_drop.bind(can, soil)))
	tween.tween_interval(1.45)
	tween.tween_callback(func(): plant.texture = plant.get_meta("healthy"))
	tween.tween_property(_charlotte, "carry_lift", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(can, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(plant, "modulate", Color(0.8, 1.15, 0.85), 0.2)
	tween.tween_property(plant, "modulate", Color.WHITE, 0.6)
	tween.parallel().tween_callback(func(): _charlotte.is_walking = true)
	tween.parallel().tween_property(_charlotte, "position:y", floor_y, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): _charlotte.is_walking = false)
	var watered: Array = GameState.flags.get("watered", [])
	watered.append(id)
	GameState.flags["watered"] = watered
	var last := watered.size() >= _plants.size()
	if last:
		GameState.flags.erase("watered")
	tween.tween_callback(func():
		_pouring = false
		_control.enabled = true
		if last:
			Carry.put_down(_charlotte)
			_held_can = null
			_show_can(true)
			_say(_charlotte, "Toutes les plantes ont bu !", 300.0)
			Quests.complete("plants")
		else:
			_say(_charlotte, "Bois, petite plante !", 300.0))


# One drop of water: out of the spout (wherever the tipped can is now), a little forward, falling onto the soil.
func _drop(can: Node2D, soil: Vector2) -> void:
	if not is_instance_valid(can):
		return
	var drop := Sprite2D.new()
	drop.texture = PropArt.flake()
	drop.modulate = Color(0.55, 0.78, 1.0, 0.9)
	drop.scale = Vector2(0.22, 0.32)
	var from := can.to_global(CAN_SPOUT)
	var to := soil + Vector2(randf_range(-9, 9), randf_range(2, 6))
	drop.position = from
	add_child(drop)
	var fall := create_tween()
	fall.tween_method(func(t: float):
		drop.position = Vector2(lerpf(from.x, to.x, 1.0 - (1.0 - t) * (1.0 - t)), lerpf(from.y, to.y, t * t)), 0.0, 1.0, 0.32)
	fall.tween_callback(drop.queue_free)


# Where the water lands on plant `id`, in the world.
func _soil(id: String) -> Vector2:
	var plant: Sprite2D = _plants[id]
	return plant.position + (plant.get_meta("soil") as Vector2) * plant.scale


func _family_member(look: CharacterLook, x: float, facing: int) -> Character:
	var who := Character.new()
	who.look = look
	who.fidgets = true
	# The grown-ups stand a head taller than their daughter.
	who.scale = Vector2.ONE * CHAR_SCALE * 1.18
	who.position = Vector2(x, FEET_Y - 10.0)
	who.facing = facing
	add_child(who)
	return who


# The wall switch in each room, and the salon's floor lamp (click the lamp itself).
func _build_switches() -> void:
	_switchable(_switch_area(250.0, 330.0), 250.0, [_vestibule_light], Vector2(0.0, VESTIBULE_END))
	_switchable(_switch_area(1780.0, 330.0), 1790.0, [_salon_pendant], Vector2(VESTIBULE_END, SALON_END))
	_switchable(Rect2(1470.0, 230.0, 110.0, 370.0), 1525.0, _floor_lamp)
	_switchable(_switch_area(2480.0, 330.0), 2490.0, _hall_lights, Vector2(SALON_END, HALL.y))
	_switchable(_switch_area(BEDROOM.x + 1300.0, 330.0), BEDROOM.x + 1310.0, [_bedroom_lights], BEDROOM)


func _build_doors() -> void:
	# Front door (its glass door leaf inside the vestibule frame) → back to the street.
	add_child(DoorSpot.make(Rect2(370, 204, 170, 396), func():
		_control.enabled = false
		Sfx.play("door")
		Transition.change_scene(self, "res://scenes/main.tscn")))
	add_child(DoorSpot.make(Rect2(CHACHA_DOOR_X, 170, 150, 430), func(): _go_through(BEDROOM_DOOR_X - 40.0, BEDROOM, -1)))
	add_child(DoorSpot.make(Rect2(BEDROOM_DOOR_X, 170, 150, 430), func(): _go_through(CHACHA_DOOR_X + 75.0, HALL, 1)))
	# The kitchen's back door: out to the yard and the lane behind the house.
	add_child(DoorSpot.make(Rect2(KITCHEN_START + 300.0, 250, 120, 350), func():
		_control.enabled = false
		Sfx.play("door")
		Transition.arrive = "ruelle_from_maison"
		Transition.change_scene(self, "res://scenes/ruelle.tscn"), KITCHEN_START + 300.0))
	# The fridge: a snack.
	add_child(DoorSpot.make(Rect2(KITCHEN_START + 4.0, 240, 104, 356), _open_fridge, KITCHEN_START + 140.0))
	# Her bed: sleep until the next morning.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 360.0, 380, 448, 228), _go_to_sleep, BEDROOM.x + 600.0))
	# The book ledges: her books.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 960.0, 270, 136, 200), _open_books, BEDROOM.x + 1030.0))
	# Her desk: drawing paper and crayons.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 1110.0, 420, 300, 186), _open_drawing_pad, BEDROOM.x + 1200.0))
	# The dresser's drawers (under the terrarium): her wardrobe.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 40.0, 444, 276, 162), _open_wardrobe, BEDROOM.x + 180.0))


func _open_wardrobe() -> void:
	_control.enabled = false
	var wardrobe := Wardrobe.new(_charlotte.look)
	# All through the Halloween quest the drawers hold nothing but costumes, never her everyday clothes.
	wardrobe.costumes_only = Quests.active(Halloween.QUEST)
	wardrobe.closed.connect(func(look: CharacterLook):
		if look:
			CharacterLook.dress_charlotte(look)
			_charlotte.set_look(CharacterLook.charlotte())
			_twirl()
			_costume_chosen()
		_control.enabled = true)
	add_child(wardrobe)


# Dressed up at last: the evening can begin (she is told where to go next).
func _costume_chosen() -> void:
	if Halloween.step() != 1 or not Halloween.dressed(_charlotte):
		return
	Halloween.set_step(2)
	Notebook.announce("step", "C'est parti pour l'Halloween !")
	_say(_charlotte, "Me v'là déguisée en %s !\nJe m'en vais passer l'Halloween !" % CostumeArt.name_of(_charlotte.look.costume).to_lower(), 300.0, 4.0)


# The fridge door swings open (cold light spilling out), she takes a snack, and it floats up with a "Miam !".
func _open_fridge() -> void:
	if _fridge_busy:
		return
	_fridge_busy = true
	_charlotte.facing = -1
	Sfx.play("fridge", Vector2(KITCHEN_START + 60.0, 420.0))
	var open := Sprite2D.new()
	open.texture = InteriorArt.fridge_open()
	open.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	open.centered = false
	open.position = Vector2(KITCHEN_START - 40.0, 240.0)
	add_child(open)
	# Over the fridge and its drawings, under Charlotte.
	move_child(open, _fridge_art.get_index() + 1)
	var cold := _glow(Vector2(KITCHEN_START + 60.0, 420.0), 220.0, Color(0.75, 0.9, 1.0, 0.35))
	move_child(cold, open.get_index() + 1)
	var pick: Array = SNACKS[randi() % SNACKS.size()]
	_treat(InteriorArt.snack(pick[0]), "%s Miam !" % pick[1], 0.6)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(func():
		open.queue_free()
		cold.queue_free()
		_fridge_busy = false)


# Bedtime (nothing is asked of her first): the room goes night-blue and moonlit, she's tucked in ("Bonne nuit"), little z's float up from the
# bed; then black, "Le lendemain matin…", and she's up beside the bed (the hamster is hungry again).
func _go_to_sleep() -> void:
	_control.enabled = false
	Sfx.play("goodnight")
	Music.play(["night"], true)
	var night := CanvasLayer.new()
	night.layer = 55
	add_child(night)
	var dark := ColorRect.new()
	dark.color = Color(0.04, 0.06, 0.18, 0.0)
	dark.size = VIEW
	dark.mouse_filter = Control.MOUSE_FILTER_STOP
	night.add_child(dark)
	var moon := _glow(Vector2(BEDROOM.x + 180.0, 280.0), 260.0, Color(0.6, 0.75, 1.0, 0.0))
	var words := _night_label("Bonne nuit, Chachoue…", 40)
	words.position.y = -170.0
	night.add_child(words)
	# The z's rise from her pillow.
	var pillow := get_viewport().get_canvas_transform() * Vector2(BEDROOM.x + 420.0, 450.0)
	var zs := _night_label("z  z  z", 30)
	zs.position = pillow - Vector2(60, 20)
	zs.size = Vector2(120, 40)
	night.add_child(zs)
	var tween := create_tween()
	tween.tween_property(dark, "color:a", 0.62, 1.0)
	tween.parallel().tween_property(moon, "modulate:a", 1.0, 1.0)
	moon.modulate.a = 0.0
	moon.self_modulate = Color(1, 1, 1, 0.5)
	tween.tween_callback(func(): _charlotte.visible = false)
	tween.tween_property(words, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(zs, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(zs, "position:y", pillow.y - 110.0, 2.6)
	tween.tween_property(dark, "color", Color(0.02, 0.02, 0.05, 1.0), 0.9)
	tween.parallel().tween_property(words, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(zs, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		GameState.flags.erase("hamster_fed")
		var halloween_over: bool = Halloween.step() == 3 and GameState.flags.get("halloween_counted", false)
		if halloween_over:
			_end_halloween()
		words.text = "Le lendemain matin…" if not halloween_over else "Le lendemain matin… il a neigé !"
		words.position.y = 0.0
		moon.queue_free()
		_charlotte.position.x = BEDROOM.x + 840.0
		_charlotte.facing = -1
		_charlotte.visible = true
		Music.play(_music())
		Sfx.play("chime"))
	tween.tween_property(words, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.2)
	tween.tween_property(words, "modulate:a", 0.0, 0.4)
	tween.tween_property(dark, "color:a", 0.0, 0.8)
	tween.tween_callback(func():
		night.queue_free()
		_control.enabled = true)


# The morning after Halloween: the quest is done, the costume goes back in the drawer, and winter has come overnight.
func _end_halloween() -> void:
	var total := Halloween.candy()
	Quests.complete("halloween")
	Halloween.pack_away()
	GameState.flags.erase("halloween_counted")
	GameState.flags["halloween_total"] = total
	GameState.flags["winter_greeting"] = true
	var look := CharacterLook.charlotte()
	look.costume = ""
	CharacterLook.dress_charlotte(look)
	_charlotte.set_look(CharacterLook.charlotte())
	# Winter came overnight; the street will be white when she steps out (the save keeps the season).
	Season.current = "winter"


func _night_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#FFF3C4"))
	label.size = VIEW
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate.a = 0.0
	return label


# Back from the rounds: Maman counts the haul with her on the kitchen table, then it is time for bed.
func _count_the_candy() -> void:
	_say(_mom, "Montre-moi ta récolte, Chachoue !", 380.0, 2.4)
	_control.enabled = false
	var steps := create_tween()
	steps.tween_interval(1.6)
	steps.tween_callback(func() -> void:
		var sheet := CandyCount.new()
		sheet.closed.connect(func() -> void:
			_control.enabled = true
			_say(_charlotte, "Je vais me coucher !", 300.0, 2.4)
			GameState.flags["halloween_counted"] = true)
		add_child(sheet))


func _open_books() -> void:
	_control.enabled = false
	var books := BookReader.new()
	books.closed.connect(func(): _control.enabled = true)
	add_child(books)


func _open_drawing_pad() -> void:
	_control.enabled = false
	var pad := DrawingPad.new()
	pad.closed.connect(func(drawing: Image):
		if drawing:
			DrawingPad.keep(drawing)
			_show_fridge_drawings()
		_control.enabled = true)
	add_child(pad)


# Her kept drawings, newest last, on the fridge doors (kitchen fridge: x 3404–3508, doors split at y 370).
func _show_fridge_drawings() -> void:
	for child in _fridge_art.get_children():
		child.queue_free()
	var slots := [Vector2(KITCHEN_START + 14.0, 258.0), Vector2(KITCHEN_START + 56.0, 284.0),
		Vector2(KITCHEN_START + 16.0, 396.0), Vector2(KITCHEN_START + 58.0, 430.0)]
	var magnets := [Color("#E04F5F"), Color("#4FA3E0"), Color("#FFD23F"), Color("#7CCB5A")]
	var drawings := DrawingPad.saved()
	for i in drawings.size():
		var art := Sprite2D.new()
		art.texture = ImageTexture.create_from_image(drawings[i])
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.centered = false
		art.scale = Vector2.ONE * 40.0 / DrawingPad.PAPER.x
		art.position = slots[i]
		art.rotation = deg_to_rad([-5.0, 4.0, 3.0, -4.0][i])
		_fridge_art.add_child(art)
		var magnet := Polygon2D.new()
		magnet.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(3.5, 3.5))
		magnet.color = magnets[i]
		magnet.position = slots[i] + Vector2(20, 1).rotated(art.rotation)
		_fridge_art.add_child(magnet)


# A happy little spin in the new outfit.
func _twirl() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(func(): _charlotte.facing = -_charlotte.facing)
		tween.tween_interval(0.12)


# ─────────────────────────────────────────────────────────────
# Furniture
# ─────────────────────────────────────────────────────────────

func _build_vestibule() -> void:
	_put(InteriorArt.coat_shelf(), 14.0, 430.0, 0.9, "wall")
	_plate(250.0, 330.0, false)
	_put(InteriorArt.radiator(96.0, 150.0), 186.0, WALL_BASE, 1.0, "floor")
	_put(InteriorArt.front_door(), 290.0, WALL_BASE)
	_daylight(Vector2(330.0, 230.0), 240.0, 0.08)
	_put(InteriorArt.doormat(), 345.0, 630.0)
	_put(InteriorArt.backpack(), 40.0, 616.0, 0.9, "floor")
	_put(InteriorArt.boots(), 496.0, 612.0, 0.8, "floor")
	_put(InteriorArt.umbrella_stand(), 590.0, 614.0, 0.85, "floor")
	_put(InteriorArt.floor_clutter(), 150.0, 622.0)
	_vestibule_light = _ceiling_light(320.0)
	_put(InteriorArt.oak_doorway(), VESTIBULE_END, WALL_BASE)
	_put(InteriorArt.oak_glass_door(), VESTIBULE_END + 230.0, WALL_BASE, 1.0, "wall")


func _process(delta: float) -> void:
	super(delta)
	if _sofa_front:
		var taken := false
		for who: Character in [_charlotte, _mom, _dad]:
			if who and who.seated_amount() > 0.985 and who.sitting and who.seat_floor == _sofa_seat.floor_y and who.position.x >= _sofa_seat.span.x - 60.0 and who.position.x <= _sofa_seat.span.y + 60.0:
				taken = true
		_sofa_front.visible = taken


func _build_salon() -> void:
	_put(InteriorArt.rug(), 900.0, 694.0, 0.9)
	_plate(1700.0, 560.0, true)
	_plant("salon", "monstera", 843.0, 606.0, 0.8)
	for i in 3:
		_put(InteriorArt.poster(i), 1030.0 + i * 130.0, 340.0, 0.85, "wall")
	_put(InteriorArt.floor_lamp(), 1470.0, 604.0, 0.9, "floor")
	_floor_lamp = [_glow(Vector2(1524.0, 360.0), 200.0, Color(1.0, 0.82, 0.5, 0.4)), _glow(Vector2(1524.0, 300.0), 46.0, Color(1.0, 0.95, 0.75, 0.55))]
	_put(InteriorArt.sofa(), 960.0, 606.0, 0.85, "floor")
	# The sofa's seat: she sits anywhere along it, facing the window, her feet dangling.
	var sofa_seat := Seat.make(Rect2(1030.0, 470.0, 370.0, 136.0), Vector2(1090.0, 1340.0), 80.0)
	sofa_seat.floor_y = 622.0
	# The front of the sofa again, over whoever sits, so she sits in it and not before it.
	var sofa_tex := InteriorArt.sofa()
	var front := Sprite2D.new()
	front.texture = sofa_tex
	front.region_enabled = true
	front.region_rect = Rect2(0, 182, 505, 48)
	front.centered = false
	front.scale = Vector2.ONE * 0.85
	front.position = Vector2(960.0, 606.0 - 48.0 * 0.85)
	front.z_index = 3
	front.visible = false
	add_child(front)
	_sofa_front = front
	_sofa_seat = sofa_seat
	add_child(sofa_seat)
	_put(InteriorArt.side_table(), 1390.0, 610.0, 0.8, "floor")
	_put(InteriorArt.window(170.0, 300.0), 1580.0, 470.0, 1.0, "wall")
	_daylight(Vector2(1580.0, 170.0), 170.0, 0.12)
	_plant("fenetre", "pothos", 1590.0, 606.0, 0.5)
	_plate(1780.0, 330.0, false)
	_put(InteriorArt.dining_table(), 1780.0, 606.0, 0.85, "floor")
	_salon_pendant = _pendant(1984.0, 310.0)
	_put(InteriorArt.black_shelf(), 2110.0, WALL_BASE, 0.7, "floor")


func _build_hallway() -> void:
	_hall_lights = [_ceiling_light(2600.0), _ceiling_light(3200.0)]
	_put(InteriorArt.runner(980.0), 2320.0, 690.0)
	_put(InteriorArt.black_coats(), 2985.0, 470.0, 0.8, "wall")
	# Papa's piano and Maman's potter's wheel: the two passions of the house.
	_put(InteriorArt.piano(), PIANO_X, 606.0, 0.62, "floor")
	_put(InteriorArt.piano_bench(), PIANO_X + 196.0, 636.0, 0.9, "floor")
	_put(InteriorArt.pottery_station(), POTTERY_X, 606.0, 0.85, "floor")
	_put(InteriorArt.photo_row(), 2520.0, 260.0, 0.8, "wall")
	_put(InteriorArt.tv(), 2560.0, 400.0, 0.8, "wall")
	_build_tv(Vector2(2560.0, 400.0 - 140.0 * 0.8), 0.8)
	_plate(2480.0, 330.0, false)
	_put(InteriorArt.radiator(160.0, 150.0), 2790.0, WALL_BASE, 1.0, "floor")
	_put(InteriorArt.recycling_bin(), 2985.0, 608.0, 1.0, "floor")
	_put(InteriorArt.panel_door(), CHACHA_DOOR_X, WALL_BASE)
	_chacha_sign(Vector2(CHACHA_DOOR_X + 75.0, 330.0))
	_plant("corridor", "fiddle", 3283.0, 606.0, 0.55)
	_plant("fougere", "fern", 2690.0, 606.0, 0.5)
	_put(InteriorArt.kitchen(), KITCHEN_START, WALL_BASE)
	_dress_kitchen()
	_fridge_art = Node2D.new()
	add_child(_fridge_art)
	_show_fridge_drawings()
	_daylight(Vector2(KITCHEN_START + 322.0, 260.0), 126.0, 0.1)
	_hall_lights.append(_ceiling_light(KITCHEN_START + 200.0))


# What makes the kitchen lived in: things on top of the fridge and cabinet, a calendar, a curtain on the door glass, a
# check mat in front of the counter, a clock and a pendant over the island. (Tex of the kitchen: its top is at WALL_BASE - 480.)
func _dress_kitchen() -> void:
	var top := WALL_BASE - 480.0
	_put(InteriorArt.kitchen_toppers(), KITCHEN_START, top + 120.0)
	_put(InteriorArt.wall_calendar(), KITCHEN_START - 100.0, 300.0, 0.9, "wall")
	_put(InteriorArt.wall_clock(), KITCHEN_START - 80.0, 205.0, 0.55, "wall")
	_put(InteriorArt.kitchen_curtain(), KITCHEN_START + 336.0, top + 220.0, 0.9)
	_put(InteriorArt.kitchen_mat(), KITCHEN_START + 140.0, 636.0)
	_put(InteriorArt.house_plant("pothos", false), KITCHEN_START + 500.0, top + 318.0, 0.28)
	_hall_lights.append(_pendant(KITCHEN_START + 500.0, 270.0))


func _build_bedroom() -> void:
	var x := BEDROOM.x
	_put(InteriorArt.round_rug(), x + 380.0, 700.0, 1.0)
	_put(InteriorArt.window(180.0, 300.0), x + 90.0, 420.0, 1.0, "wall")
	_daylight(Vector2(x + 90.0, 120.0), 180.0, 0.14)
	var tank := _put(InteriorArt.terrarium(false), x + 30.0, 606.0, 0.85, "floor")
	var hamster := Hamster.new()
	hamster.position = tank.position
	hamster.scale = tank.scale
	add_child(hamster)
	add_child(QuestMark.make(tank.position + Vector2(140, -40) * tank.scale, func() -> bool:
		return Quests.active("hamster") and not GameState.flags.get("hamster_fed", false), 0.8))
	_put(InteriorArt.terrarium(true), x + 30.0, 606.0, 0.85)
	_put(InteriorArt.flower_painting(), x + 470.0, 330.0, 0.8, "wall")
	_put(InteriorArt.moon_decal(), x + 340.0, 330.0, 0.85, "wall")
	var marks := GrowthMarks.new()
	marks.position = Vector2(x + 1364.0, WALL_BASE)
	add_child(marks)
	_put(InteriorArt.wall_clock(), x + 1300.0, 260.0, 0.8, "wall")
	# A baby mobile over the bed, turning gently; stars on the ceiling that glow a little.
	var mobile := _put(InteriorArt.mobile(), x + 540.0, 270.0, 0.8)
	mobile.centered = true
	mobile.offset = Vector2(45.0, 0.0)
	mobile.position = Vector2(x + 540.0 + 36.0, CEILING + 6.0)
	var sway := create_tween().set_loops()
	sway.tween_property(mobile, "rotation", 0.06, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(mobile, "rotation", -0.06, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 16:
		var star := Polygon2D.new()
		var c := Vector2(x + rng.randf_range(20.0, 1620.0), rng.randf_range(CEILING + 2.0, CEILING + 30.0))
		var r := rng.randf_range(2.5, 4.5)
		var pts := PackedVector2Array()
		for k in 10:
			pts.append(Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (r if k % 2 == 0 else r * 0.45))
		star.polygon = pts
		star.position = c
		star.color = Color("#E8F3A8", 0.55)
		add_child(star)
	_plant("chambre", "lily", x + 272.0, 606.0, 0.5)
	_put(InteriorArt.bed(), x + 360.0, 608.0, 0.8, "floor")
	_put(InteriorArt.kid_table(), x + 830.0, 612.0, 0.75, "floor")
	_put(InteriorArt.book_ledges(), x + 960.0, 470.0, 0.8, "wall")
	_put(InteriorArt.fluffy_chair(), x + 960.0, 606.0, 0.8, "floor")
	_put(InteriorArt.strawberry_poster(), x + 1130.0, 300.0, 0.8, "wall")
	_plate(x + 1300.0, 330.0, false)
	_put(InteriorArt.desk(), x + 1110.0, 606.0, 0.85, "floor")
	_put(InteriorArt.laundry_basket(), x + 1300.0, 618.0, 0.8, "floor")
	_put(InteriorArt.plushies(), x + 770.0, 626.0, 0.8, "floor")
	_put(InteriorArt.panel_door(), BEDROOM_DOOR_X, WALL_BASE)
	_candle(Vector2(x + 30.0 + 262.0 * 0.85, 606.0 - 240.0 * 0.85), 80.0)
	_put(InteriorArt.bunting(440.0), x + 650.0, 230.0)
	_bedroom_lights = _fairy_lights(x + 40.0, 40)


# Paper sign taped to the bedroom door, each letter in a different marker colour.
func _chacha_sign(center: Vector2) -> void:
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-58, -16), Vector2(58, -19), Vector2(60, 17), Vector2(-57, 19)])
	paper.color = Color("#FBFAF6")
	paper.position = center
	add_child(paper)
	var colors := ["#7E57C2", "#F2A7C9", "#1FB5C4", "#E04F5F", "#FF8A3D", "#3E8E5A"]
	var word := "chacha"
	for i in word.length():
		var settings := LabelSettings.new()
		settings.font_size = 24
		settings.font_color = Color(colors[i])
		var letter := Label.new()
		letter.text = word[i]
		letter.label_settings = settings
		letter.position = center + Vector2(-50.0 + i * 17.0, -18.0 + (i % 2) * 2.0)
		letter.rotation = deg_to_rad(-4.0 + (i * 37) % 9)
		add_child(letter)


# The TV's picture over the InteriorArt.tv() frame at `top_left`: click to turn on and change channels.
func _build_tv(top_left: Vector2, s: float) -> void:
	var screen := TvScreen.new()
	screen.position = top_left + Vector2(12, 12) * s
	screen.scale = Vector2.ONE * s
	screen.stand_x = top_left.x + 110.0 * s
	screen.glow = _glow(top_left + Vector2(110, 120) * s, 320.0, Color(1, 1, 1, 0.3))
	add_child(screen)
