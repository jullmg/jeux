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
# The two sash windows (salon and bedroom): their view redraws for the hour and the season, so after a night's
# sleep they must be redrawn too, or they keep showing the evening she fell asleep under (Halloween's, if that
# was the night).
var _salon_window: Sprite2D
var _bedroom_window: Sprite2D
# The snow falling past those two windows in winter (Interior._window_snow).
var _window_snows: Array[Control] = []
# The front of the sofa drawn over whoever sits in it (only shown while someone does).
var _sofa_front: Sprite2D
var _sofa_seat: Seat
var _floor_lamp: Array = []
var _hall_lights: Array = []
var _bedroom_light: Sprite2D
# The Christmas tree in front of the salon window (quest "sapin"), its box of decorations, the glow of its lights.
const XMAS_X := 1690.0
const XMAS_SCALE := 0.95
const XMAS_BOX_X := 1520.0
var _xmas_tree: Sprite2D
var _xmas_box: Sprite2D
var _xmas_busy := false
# Christmas (quest "noel"): what lies under the tree (Santa's plate, the presents), the first of the tree's glows (the
# réveillon's veil goes just under them).
const NOEL_TABLE := Rect2(1780.0, 440.0, 290.0, 170.0)
var _noel_plate: Sprite2D
var _noel_presents: Array[Sprite2D] = []
var _xmas_glow_from := -1
# The glows of the tree's bulbs [sprite, their own alpha]: they fade where someone stands in front of them.
var _xmas_bulb_glows: Array = []
var _noel_busy := false
# Her birthday (quest "anniversaire"): the decorations up, the guests, the cake.
const PARTY_TABLE_X := 1760.0
const GUEST_XS := [1010.0, 1100.0, 1190.0, 1280.0, 1370.0]
var _party_decor := {}
var _guests := {}
var _party_cake: Sprite2D
var _party_flames: Array[Sprite2D] = []
var _party_busy := false

# Charlotte's drawings stuck on the fridge door with magnets.
var _fridge_art: Node2D
var _crafts_art: Node2D
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
# The hallway TV (Papa's hockey, the movie night's film).
var _tv: TvScreen
# The movie night (Cinema, step 3): the twins waiting in front of the TV, the blanket and cushions on the floor.
var _movie_twins: Array[Character] = []
## The film on tonight (a TvShows id).
var _film := "film"
var _film_sound: FilmSound
var _sleepover := false
var _camp: Sleepover.Camp
var _shadow: Sleepover.ShadowShow
var _shows_done := 0
var _movie_nest: _Nest


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
	# Back inside (from the park or anywhere): an outing with Papa is over.
	ParkOuting.end()
	# A sled never comes home (a game saved with it in her arms is freed too).
	if Carry.has("traineau"):
		Carry.clear()
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
	_build_xmas_spots()
	_build_new_year()
	_build_birthday()
	_build_movie_night()
	_enter_area(BEDROOM if _charlotte.position.x >= BEDROOM.x else HALL)
	_finish([[700.0, "plant"], [1900.0, "plant"], [2900.0, "plant"], [5400.0, "plushie"], [6250.0, "plant"]])
	_mom_calls_for_the_candy()


# Home from the rounds with a full bag: Maman calls out from the kitchen as soon as Charlotte comes in, so it is
# plain that the counting happens with her and not on her own.
func _mom_calls_for_the_candy() -> void:
	if Halloween.step() != 3 or GameState.flags.get("halloween_counted", false):
		return
	var call := create_tween()
	call.tween_interval(1.2)
	call.tween_callback(func() -> void:
		if not is_instance_valid(_mom):
			return
		_mom_routine.pause(4.0, _charlotte.position.x)
		_say(_mom, "Chachoue ! Viens me montrer ta récolte,\nje suis dans la cuisine !", 380.0, 4.0))


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
		# Her room in turquoise, plain walls without stars (Julien, 2026-11-25).
		{"from": BEDROOM.x, "to": BEDROOM.y, "wall": Color("#CDEFEA"), "base": Color("#F4F1EA"), "wainscot": Color("#72D2C9"), "wainscot_height": 150.0},
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
		# Back from the rounds, it is Maman who counts the haul: the "!" says so.
		return Halloween.step() == 3 and not GameState.flags.get("halloween_counted", false) \
			or Quests.available("milk") or Quests.available("menage") or Quests.available("amies") \
			or Quests.active("milk") and Carry.has("milk") or Cinema.step() == 1 \
			or Quests.available(School.QUEST) or Quests.available(Party.QUEST) and School.step() == 0 \
			or Snowman.needs("boutons") and not Carry.busy() \
			or Christmas.can_start() or Christmas.step() == 1 and Carry.has("lettre") \
			or NewYear.can_start() or NewYear.step() == 3 or Tooth.can_start() \
			or Birthday.can_start() or Birthday.step() == 1)
	_dad_routine = _routine(_dad, DAD_TASKS, _talk_to_dad, Vector2(0, -360), func() -> bool:
		return Quests.available("hamster") or Quests.available("plants") or Quests.available("chips") \
			or Quests.active("chips") and Carry.has("chips") or Snowman.needs("tuque") and not Carry.busy() \
			or Snowstorm.step() == 1 or XmasTree.can_start() or XmasTree.step() == 4 or NewYear.step() == 3)
	# The morning after the storm, Papa is out front shovelling.
	if Snowstorm.dad_outside():
		_dad.visible = false
		_dad_routine.process_mode = Node.PROCESS_MODE_DISABLED
		_dad_routine.spot.queue_free()
		_dad_routine.mark.queue_free()


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
	if _hand_craft("maman"):
		return
	if Quests.active("milk") and Carry.has("milk"):
		Carry.put_down(_charlotte)
		_say(_mom, "Du lait ! Merci, Chachoue !", 350.0)
		Quests.complete("milk")
	elif Cinema.step() == 1:
		_pocket_money_for_the_movie()
	elif Cinema.step() == 2:
		_say(_mom, "Des chips pis des bonbons,\npas plus, là !", 380.0)
	elif Cinema.step() == 3:
		_say(_mom, "Tes amis t'attendent\ndevant la télé, ma chouette !", 380.0)
	elif Halloween.step() == 3:
		_count_the_candy()
	elif Halloween.step() == 2:
		_say(_mom, "Amuse-toi bien, ma chouette !\nReviens quand ton sac sera plein.", 400.0, 3.5)
	elif Halloween.step() == 1:
		_say(_mom, "Ton déguisement est dans ta commode,\nma chouette ! Vas-y !", 400.0, 3.5)
	elif Birthday.step() == 1:
		_invite_friends()
	elif Birthday.step() == 2:
		_say(_mom, "On décore le salon pour ta fête !\nLa bannière, les ballons pis la table.", 400.0, 3.2)
	elif Birthday.step() == 3:
		_say(_mom, "Bonne fête, ma grande !\nOuvre les cadeaux de tes amis !", 380.0, 3.0)
	elif Birthday.can_start() and Quests.start(Birthday.QUEST):
		Birthday.set_step(1)
		_mom.express("happy", 2.4)
		_say(_mom, "Le 1er février, c'est ta fête, Chachoue !\nOn fait une fête ici. Qui veux-tu inviter ?", 410.0, 3.6)
		var card := create_tween()
		card.tween_interval(3.8)
		card.tween_callback(_invite_friends)
	elif Tooth.step() == 1:
		_say(_mom, "Croque dans une belle pomme, ma chouette !\nY en a dans le frigo.", 400.0, 3.0)
	elif Tooth.step() == 2:
		_say(_mom, "Mets ta dent sous ton oreiller ! La fée des dents\npasse juste quand on dort.", 410.0, 3.4)
	elif Tooth.can_start() and Quests.start(Tooth.QUEST):
		Tooth.set_step(1)
		_wobbly_tooth()
	elif NewYear.step() == 1:
		_say(_mom, "Viens dans le corridor, ma chouette !\nLe Bye Bye commence à la télé.", 400.0, 3.2)
	elif NewYear.step() == 2:
		_say(_mom, "Il est minuit passé ! Au lit !", 380.0)
	elif NewYear.step() == 3:
		_ask_resolution()
	elif NewYear.can_start() and Quests.start(NewYear.QUEST):
		NewYear.set_step(1)
		_mom.express("happy", 2.4)
		_say(_mom, "C'est le 31 décembre ! À soir, tu peux veiller\njusqu'à minuit. On regarde le Bye Bye à la télé !", 410.0, 4.0)
		Notebook.announce("step", "Va regarder le Bye Bye à la télé du corridor !", NewYear.HEADING)
	elif Christmas.step() == 1 and Carry.has("lettre"):
		_letter_to_mom()
	elif Christmas.step() == 1:
		_say(_mom, "Ta lettre au père Noël, ma chouette !\nÀ ton bureau, dans ta chambre.", 400.0, 3.2)
	elif Christmas.step() == 2 and not Carry.has("biscuits"):
		_mom.express("happy", 2.0)
		_say(_mom, "On fait les biscuits ? Viens au comptoir,\nà côté du frigo !", 400.0, 3.2)
	elif Christmas.step() == 2:
		_say(_mom, "Mets-les sous le sapin, dans le salon !", 380.0)
	elif Christmas.step() == 3:
		_say(_mom, "Viens à table, c'est le réveillon !", 380.0)
	elif Christmas.step() == 4:
		_say(_mom, "Au lit, ma chouette ! Sinon le père Noël\npassera pas.", 400.0, 3.2)
	elif Christmas.step() == 5:
		_say(_mom, "Joyeux Noël, mon cœur !\nVa voir sous le sapin !", 380.0, 3.0)
	elif Christmas.can_start() and Quests.start(Christmas.QUEST):
		Christmas.set_step(1)
		_mom.express("happy", 2.4)
		_say(_mom, "Noël s'en vient, Chachoue ! As-tu écrit ta lettre\nau père Noël ? Va l'écrire à ton bureau.", 410.0, 4.0)
	elif Snowman.needs("boutons"):
		_give_for_snowman(_mom, "boutons", "Des boutons pour un bonhomme de neige ?\nTiens, ma vieille boîte à biscuits !", 400.0)
	elif School.step() == 1:
		_say(_mom, "Je t'attends à la porte d'en avant,\nma chouette ! On part pour l'école !", 400.0, 3.5)
	elif Quests.start(School.QUEST):
		School.set_step(1)
		_mom.express("happy", 2.4)
		_say(_mom, "Chachoue, c'est l'heure de l'école !\nPrends ton sac, je t'amène.", 400.0, 3.8)
		var more := create_tween()
		more.tween_interval(4.0)
		more.tween_callback(func() -> void: _say(_mom, "Je t'attends à la porte d'en avant !", 380.0))
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
	elif Party.step() == 1:
		_say(_mom, "Je t'attends à la porte d'en avant,\nma chouette ! On va au Jean Coutu.", 400.0, 3.4)
	elif Quests.available(Party.QUEST) and School.step() == 0:
		_invitation()
	elif Cinema.can_ask() or School.available_today():
		_ask_mom()
	elif School.hands_full_today():
		_mom.express("happy", 2.0)
		_say(_mom, "Finis d'abord ce que tu as à faire, ma chouette :\nl'école va t'attendre !", 400.0, 3.4)
	else:
		_ask_mom()


func _talk_to_dad() -> void:
	_dad_routine.pause(4.0, _charlotte.position.x)
	if _hand_craft("papa"):
		return
	if Quests.active("chips") and Carry.has("chips"):
		_hockey_night()
	elif Snowstorm.step() == 1:
		_dad.express("happy", 2.0)
		_say(_dad, "Toute une bordée de neige, Chachoue !\nViens m'aider à pelleter l'escalier. Je t'attends dehors !", 390.0, 4.0)
		Snowstorm.set_step(2)
		Notebook.announce("step", "Papa t'attend dehors pour pelleter, devant la maison !", Snowstorm.HEADING)
		var out := create_tween()
		out.tween_interval(4.2)
		out.tween_callback(func() -> void:
			_dad.visible = false
			_dad_routine.process_mode = Node.PROCESS_MODE_DISABLED
			_dad_routine.spot.queue_free()
			_dad_routine.mark.queue_free())
	elif NewYear.step() == 3:
		_ask_resolution()
	elif NewYear.step() == 1:
		_say(_dad, "Le Bye Bye ! Viens, ma grande,\nça commence dans le corridor.", 390.0)
	elif XmasTree.step() == 4:
		_the_star()
	elif XmasTree.step() == 3:
		_say(_dad, "Décore-le, ma grande !\nJe t'aiderai pour l'étoile.", 390.0)
	elif XmasTree.step() == 1:
		_say(_dad, "Je t'attends à la porte d'en avant !\nOn va choisir notre sapin.", 390.0)
	elif Luge.step() == 1:
		_say(_dad, "J'ai le traîneau, Chachoue ! Mets ta tuque,\nje t'attends à la porte d'en avant.", 390.0)
	elif Luge.can_start() and Quests.start(Luge.QUEST):
		Luge.set_step(1)
		_dad.express("happy", 2.4)
		_say(_dad, "Chachoue ! Y a de la belle neige : on va glisser\nsur la petite montagne du parc du Pélican !\nJe t'attends à la porte d'en avant.", 410.0, 4.6)
		Notebook.announce("step", "Papa t'attend à la porte d'en avant : on va glisser au parc du Pélican !", Luge.HEADING)
	elif Snowman.needs("tuque"):
		_give_for_snowman(_dad, "tuque", "Une tuque pour le bonhomme ? Prends ma vieille\ntuque du Canadien. Y va être champion !", 390.0)
	elif XmasTree.can_start() and Quests.start(XmasTree.QUEST):
		XmasTree.set_step(1)
		_dad.express("happy", 2.4)
		_say(_dad, "C'est le temps du sapin, Chachoue ! L'école en vend\ndans la cour. Viens, je t'attends à la porte d'en avant !", 400.0, 4.2)
	elif Quests.start("chips"):
		# His money pays for it: she gets the three dollars now.
		GameState.money += 3.0
		_say(_dad, "Le Canadien joue à soir ! Va m'acheter\ndes Ruffles crème sure et oignons chez Xin-Xin.", 390.0, 4.0)
		var more := create_tween()
		more.tween_interval(4.2)
		more.tween_callback(func() -> void: _say(_dad, "Tiens, v'là 3 piasses !", 390.0))
	elif Quests.active("chips"):
		_say(_dad, "Des Ruffles crème sure et oignons,\nchez Xin-Xin au coin de Dandurand !", 390.0, 3.5)
	elif Quests.start("hamster"):
		_say(_dad, "N'oublie pas de nourrir\nton hamster !", 390.0, 3.5)
	elif Quests.start("plants"):
		_say(_dad, "Les plantes ont soif ! L'arrosoir\nest dans la cuisine.", 390.0, 3.5)
	elif Quests.active("plants"):
		_say(_dad, "Deux au salon, deux dans le corridor\net une dans ta chambre !", 390.0, 3.5)
	else:
		_ask_dad()


## What a parent says when she hands over her craft, by what it is.
const CRAFT_LINES := {
	"carte": {"maman": "Oh, une carte ! Elle est magnifique, ma chouette.\nJe vais la garder toute ma vie.", "papa": "Une carte, pour moi ? Wow, Chachoue !\nElle est super belle."},
	"assiette": {"maman": "Hi hi ! Quel beau bonhomme !\nIl a l'air de bonne humeur.", "papa": "Ha ha ! Il est trop drôle, ton bonhomme !\nJe l'accroche tout de suite."},
	"pot": {"maman": "Un pot à crayons ! Juste ce qu'il me fallait\npour mon atelier. Merci, mon cœur !", "papa": "Un pot à crayons ! Il va être\nsur mon bureau, c'est sûr !"},
	"cadre": {"maman": "Un cadre avec ton dessin ! Je vais\nle mettre bien en vue.", "papa": "Ton dessin dans un beau cadre ?\nÇa, c'est du grand art !"},
	"collier": {"maman": "Un collier de pâtes ! Je le mets tout de suite.\nRegarde comme il me va bien !", "papa": "Un collier de pâtes ! Je vais le porter\nau travail demain, promis !"},
}


# She gives Maman or Papa what she made at the service de garde (`CraftStudio`): they look at it, and it doesn't stay anywhere afterwards.
# True when the click was about it (even for the wrong parent).
func _hand_craft(who: String) -> bool:
	if not CraftStudio.has_pending():
		return false
	var parent: Character = _mom if who == "maman" else _dad
	var height := 350.0 if who == "maman" else 360.0
	if CraftStudio.pending_for() != who:
		_say(parent, "Oh, ça, c'est pour %s, je pense !\nVa le lui donner." % ("Papa" if who == "maman" else "Maman"), height, 3.2)
		return true
	var entry := CraftStudio.pending()
	if Carry.has("bricolage"):
		Carry.put_down(_charlotte)
	_control.enabled = false
	_charlotte.express("happy", 2.4)
	parent.express("happy", 4.0)
	var look := CraftStudio.reveal(self, entry)
	look.done.connect(func() -> void:
		# It is theirs now: it doesn't stay on the table (Julien).
		CraftStudio.clear_pending()
		Sfx.play("chime")
		var lines: Dictionary = CRAFT_LINES.get(entry.kind, CRAFT_LINES.carte)
		_say(parent, lines[who], height, 4.6)
		var later := create_tween()
		later.tween_interval(1.4)
		later.tween_callback(func() -> void:
			_charlotte.express("happy", 2.4)
			_say(_charlotte, "Je t'aime, %s !" % ("Maman" if who == "maman" else "Papa"), 300.0, 2.6))
		later.tween_interval(2.8)
		later.tween_callback(func() -> void: _control.enabled = true))
	return true


# Crafts given no longer stay on the table: this only sweeps away the ones an older save had kept.
func _show_crafts() -> void:
	if _crafts_art == null:
		return
	for child in _crafts_art.get_children():
		child.queue_free()
	CraftStudio.clear_kept()
	var all := CraftStudio.kept()
	var slots := [1790.0, 1880.0, 1970.0, 2050.0]
	var start := maxi(0, all.size() - slots.size())
	for i in range(start, all.size()):
		var img: Image = all[i].image
		var sprite := Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		var k := 74.0 / float(maxi(img.get_width(), img.get_height()))
		sprite.scale = Vector2.ONE * k
		sprite.position = Vector2(slots[i - start] - img.get_width() * k * 0.5, 484.0 - img.get_height() * k)
		sprite.rotation = deg_to_rad([-3.0, 2.0, -2.0, 3.0][(i - start) % 4])
		_crafts_art.add_child(sprite)


# Maman or Papa gives her something for Billie and Auguste's snowman (`Snowman`): the button tin, the old tuque.
func _give_for_snowman(who: Character, part: String, line: String, height: float) -> void:
	if not Carry.take(_charlotte, "bonhomme", part):
		_say(_charlotte, Carry.FULL_HANDS, 200.0)
		return
	who.express("happy", 2.0)
	_say(who, line, height, 3.6)
	Sfx.play("pop", _charlotte.position + Vector2(0, -80))


# ── The Christmas tree ──────────────────────────────────────

# The tree in its stand in front of the salon window, wearing what she has put on it; while she decorates, the box beside it.
# Once it is done, its lights are on.
func _build_xmas_tree() -> void:
	var wears: Array = XmasTree.decos().duplicate()
	if Quests.done(XmasTree.QUEST):
		wears = ["lumieres", "guirlande", "boules", "cannes", "etoile"]
	_xmas_tree = _put(XmasTree.picture(XmasTree.choice(), wears), XMAS_X - XmasTree.W / 2.0 * XMAS_SCALE, 606.0 + 14.0, XMAS_SCALE, "floor")
	if Quests.done(XmasTree.QUEST):
		_xmas_lights()
		_noel_under_tree()
	elif XmasTree.step() == 3:
		_xmas_box = _put(XmasTree.box(XmasTree.DECOS.size() - XmasTree.decos().size()), XMAS_BOX_X, 690.0, 0.9)


func _build_xmas_spots() -> void:
	if _xmas_tree == null:
		return
	add_child(DoorSpot.make(Rect2(XMAS_X - 100.0, 300.0, 200.0, 320.0), _xmas_tree_clicked, XMAS_X - 140.0))
	_build_noel_spots()
	if Quests.done(XmasTree.QUEST):
		return
	add_child(QuestMark.make(Vector2(XMAS_X, 250.0), func() -> bool:
		return Carry.has("deco") and _control.enabled and not _xmas_busy))
	if _xmas_box:
		add_child(DoorSpot.make(Rect2(XMAS_BOX_X, 600.0, 110.0, 90.0), _take_deco, XMAS_BOX_X - 40.0))
		add_child(QuestMark.make(Vector2(XMAS_BOX_X + 54.0, 570.0), func() -> bool:
			return XmasTree.step() == 3 and not Carry.busy() and XmasTree.next_deco() != "" and _control.enabled))


# One decoration out of the box, into her arms.
func _take_deco() -> void:
	var next := XmasTree.next_deco()
	if next == "":
		_say(_charlotte, "La boîte est vide ! Il manque juste\nl'étoile… Papa va m'aider.", 300.0, 3.0)
		return
	if Carry.has("deco"):
		_say(_charlotte, "J'en ai déjà une dans les mains !", 300.0)
		return
	if not Carry.take(_charlotte, "deco", next):
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	Sfx.play("pop", _charlotte.position + Vector2(0, -60))
	for d: Array in XmasTree.DECOS:
		if d[0] == next:
			_say(_charlotte, d[1], 300.0)
	_xmas_box.texture = XmasTree.box(XmasTree.DECOS.size() - XmasTree.decos().size() - 1)


func _xmas_tree_clicked() -> void:
	if _xmas_busy or _noel_busy:
		return
	if Christmas.step() == 2 and Carry.has("biscuits"):
		_cookies_under_tree()
		return
	if Quests.done(XmasTree.QUEST):
		_say(_charlotte, "Y est beau, notre sapin !" if Christmas.step() != 5 else "Les cadeaux ! Vite, je les ouvre !", 300.0)
		return
	if Carry.has("deco"):
		var id := Carry.id()
		_charlotte.facing = 1
		_charlotte.pet(0.9, 0.0)
		Carry.put_down(_charlotte)
		XmasTree.add_deco(id)
		_xmas_tree.texture = XmasTree.picture(XmasTree.choice(), XmasTree.decos())
		Sfx.play("chime", Vector2(XMAS_X, 420.0))
		for d: Array in XmasTree.DECOS:
			if d[0] == id:
				_say(_charlotte, d[2], 300.0)
		if XmasTree.next_deco() == "":
			XmasTree.set_step(4)
			Notebook.announce("step", "Il manque l'étoile ! Demande à Papa de te soulever.", XmasTree.HEADING)
		return
	if XmasTree.step() == 4:
		_the_star()
	else:
		_say(_charlotte, "Il faut prendre une décoration\ndans la boîte !", 300.0)


# Papa comes over and lifts her up to the top of the tree; the star goes on, then the lights; Maman comes to see.
func _the_star() -> void:
	if _xmas_busy or not _xmas_tree:
		return
	_xmas_busy = true
	_control.enabled = false
	_dad_routine.pause(16.0, XMAS_X)
	var under := XMAS_X - 70.0
	var steps := create_tween()
	steps.tween_callback(func() -> void:
		_say(_dad, "L'étoile ! Viens ici, ma grande,\nje te soulève.", 390.0, 2.6)
		_dad.is_walking = true
		_dad.facing = 1 if under > _dad.position.x else -1
		_charlotte.is_walking = true
		_charlotte.facing = 1 if under + 30.0 > _charlotte.position.x else -1)
	steps.tween_property(_dad, "position:x", under - 30.0, 1.4)
	steps.parallel().tween_property(_charlotte, "position:x", under + 30.0, 1.4)
	steps.tween_callback(func() -> void:
		_dad.is_walking = false
		_charlotte.is_walking = false
		_dad.facing = 1
		_charlotte.facing = 1
		_dad.pet(2.6, 0.0)
		Carry.clear()
		Carry.restore(_charlotte))
	# Up she goes.
	steps.tween_property(_charlotte, "position:y", _charlotte.position.y - 170.0, 0.9).set_trans(Tween.TRANS_SINE)
	steps.tween_callback(func() -> void:
		_charlotte.pet(0.8, 0.0)
		Sfx.play("chime", Vector2(XMAS_X, 260.0))
		_xmas_tree.texture = XmasTree.picture(XmasTree.choice(), ["lumieres", "guirlande", "boules", "cannes", "etoile"])
		_charlotte.express("laugh", 2.0)
		_say(_charlotte, "L'étoile est en haut !", 300.0))
	steps.tween_interval(1.4)
	steps.tween_property(_charlotte, "position:y", FEET_Y, 0.8).set_trans(Tween.TRANS_SINE)
	steps.tween_interval(0.6)
	steps.tween_callback(func() -> void: _say(_dad, "Pis maintenant… on allume !", 390.0, 2.2))
	steps.tween_interval(2.0)
	steps.tween_callback(func() -> void:
		_xmas_lights()
		Sfx.play("goodnight", Vector2(XMAS_X, 400.0))
		_charlotte.express("wonder", 3.0)
		_dad.express("happy", 3.0))
	steps.tween_interval(1.8)
	steps.tween_callback(func() -> void:
		_say(_charlotte, "Wooow ! Y est tellement beau !", 300.0, 2.6)
		if is_instance_valid(_mom):
			_mom.express("happy", 3.0))
	steps.tween_interval(2.8)
	steps.tween_callback(func() -> void:
		if is_instance_valid(_mom):
			_say(_mom, "Oh ! Le plus beau sapin du quartier !", 350.0, 3.0)
		Quests.complete(XmasTree.QUEST)
		_xmas_busy = false
		_control.enabled = true)


# Its lights on: a warm glow on each bulb and a halo round the tree.
func _xmas_lights() -> void:
	var origin := _xmas_tree.position
	_xmas_glow_from = get_child_count()
	var colours := [Color(1.0, 0.35, 0.3), Color(1.0, 0.85, 0.3), Color(0.35, 0.65, 1.0), Color(0.4, 0.9, 0.5), Color(1.0, 0.55, 0.9)]
	var i := 0
	for p: Vector2 in XmasTree.bulbs(XmasTree.choice()):
		var bulb := _glow(origin + p * XMAS_SCALE, 16.0, Color(colours[i % colours.size()], 0.6))
		_xmas_bulb_glows.append(bulb)
		i += 1
	_xmas_bulb_glows.append(_glow(origin + XmasTree.top_of(XmasTree.choice()) * XMAS_SCALE, 46.0, Color(1.0, 0.9, 0.5, 0.55)))
	_glow(origin + Vector2(XmasTree.W / 2.0, XmasTree.H * 0.55) * XMAS_SCALE, 190.0, Color(1.0, 0.8, 0.5, 0.18))


# ── Her birthday ────────────────────────────────────────────

func _build_birthday() -> void:
	var step := Birthday.step()
	if step < 2:
		return
	for d: Array in Birthday.DECOR:
		if d[0] in Birthday.decorated():
			_party_decoration(d[0])
	if step == 2:
		var spots := {"banniere": Rect2(1000.0, 110.0, 380.0, 120.0), "ballons": Rect2(670.0, 300.0, 150.0, 300.0),
			"table": Rect2(PARTY_TABLE_X - 230.0, 470.0, 460.0, 200.0)}
		for id: String in spots:
			var r: Rect2 = spots[id]
			add_child(DoorSpot.make(r, _decorate.bind(id), r.get_center().x))
			add_child(QuestMark.make(Vector2(r.get_center().x, r.position.y - 20.0), func() -> bool:
				return Birthday.step() == 2 and id not in Birthday.decorated() and _control.enabled))
	elif step == 3:
		_guests_arrive(false)


# The invitation card: she ticks the friends she invites (five at most).
func _invite_friends() -> void:
	_control.enabled = false
	var card := Birthday.InviteCard.new()
	card.sent.connect(func(ids: Array) -> void:
		_control.enabled = true
		GameState.flags[Birthday.INVITES] = ids
		Birthday.set_step(2)
		var names: Array = ids.map(func(id: String) -> String: return Birthday.guest(id)[1])
		_say(_mom, "Les invitations sont parties !\nAstheure, on décore le salon.", 400.0, 3.2)
		Notebook.announce("step", "Invité%s : %s. Décore le salon !" % ["s" if ids.size() > 1 else "", ", ".join(names)], Birthday.HEADING)
		_build_birthday_spots_now())
	add_child(card)


# The decoration spots, built as soon as the invitations are out (the scene was built before).
func _build_birthday_spots_now() -> void:
	if Birthday.step() == 2:
		_build_birthday()


func _decorate(id: String) -> void:
	if Birthday.step() != 2 or id in Birthday.decorated():
		return
	_charlotte.pet(0.9, 0.0)
	Birthday.mark(Birthday.DECORATED, id)
	_party_decoration(id)
	Sfx.play("pop", _charlotte.position + Vector2(0, -100))
	for d: Array in Birthday.DECOR:
		if d[0] == id:
			_say(_charlotte, d[1], 300.0)
	if Birthday.decorated().size() < Birthday.DECOR.size():
		return
	Birthday.set_step(3)
	var later := create_tween()
	later.tween_interval(2.4)
	later.tween_callback(_guests_arrive.bind(true))


func _party_decoration(id: String) -> void:
	if _party_decor.has(id):
		return
	match id:
		"banniere":
			var banner := ColorRect.new()
			banner.color = Color("#E86BB0")
			banner.size = Vector2(380, 46)
			banner.position = Vector2(1000.0, 140.0)
			add_child(banner)
			var words := _label_here("BONNE FÊTE CHACHOUE !", banner.position + banner.size / 2.0, Vector2(380, 46), 24)
			_party_decor[id] = [banner, words]
		"ballons":
			_party_decor[id] = [_put(PartyArt.balloons(31), 680.0, 606.0, 0.95), _put(PartyArt.balloons(57), 1430.0, 606.0, 0.9)]
		"table":
			_party_decor[id] = [_put(PartyArt.party_table(), PARTY_TABLE_X - 220.0, 676.0, 1.0, "floor")]


func _label_here(text: String, center: Vector2, size: Vector2, font_size: int) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color("#A23A78")
	var label := Label.new()
	label.text = text
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = center - size / 2.0
	add_child(label)
	return label


# The doorbell: her friends come in and stand in the salon, each with a present for her.
func _guests_arrive(ring: bool) -> void:
	if not _guests.is_empty():
		return
	if ring:
		Sfx.play("bell")
		Notebook.announce("step", "Tes amis arrivent ! Ouvre leurs cadeaux.", Birthday.HEADING)
	_mom_routine.pause(600.0, 1300.0)
	_mom.position.x = 1560.0
	_mom.facing = -1
	var ids: Array = Birthday.invites()
	for i in ids.size():
		var id: String = ids[i]
		var kid := Character.new()
		var look := Birthday.look(id)
		look = School.indoors(look)
		kid.look = look
		kid.fidgets = true
		kid.scale = Vector2.ONE * CHAR_SCALE
		kid.position = Vector2(GUEST_XS[i], FEET_Y - 6.0)
		kid.facing = 1
		add_child(kid)
		_guests[id] = kid
		var head := -380.0 if id in ["alphee", "constance"] else -330.0
		add_child(DoorSpot.make(Rect2(kid.position + Vector2(-45, head * CHAR_SCALE), Vector2(90, -head * CHAR_SCALE)), _open_birthday_present.bind(id), kid.position.x + 80.0))
		add_child(QuestMark.make(kid.position + Vector2(0, head * CHAR_SCALE - 20.0), func() -> bool:
			return Birthday.step() == 3 and id not in Birthday.opened() and _control.enabled and not _party_busy, 0.7))
	if ring:
		var hello := create_tween()
		hello.tween_interval(0.6)
		hello.tween_callback(func() -> void:
			for kid: Character in _guests.values():
				kid.express("grin", 2.0)
			_say(_guests.values()[0], "BONNE FÊTE, CHACHOUE !", 240.0, 2.6))


func _open_birthday_present(id: String) -> void:
	if Birthday.step() != 3 or _party_busy or id in Birthday.opened():
		return
	_party_busy = true
	var g: Array = Birthday.guest(id)
	var kid: Character = _guests[id]
	kid.express("talk", 2.0)
	_say(kid, g[3], 240.0, 2.6)
	var steps := create_tween()
	steps.tween_interval(2.6)
	steps.tween_callback(func() -> void:
		_charlotte.pet(0.8, 0.3)
		Sfx.play("swoosh", _charlotte.position)
		Birthday.mark(Birthday.OPENED, id)
		_treat(Birthday.present_picture(g[4]), g[5], 0.2)
		kid.express("happy", 2.4)
		_party_busy = false
		if Birthday.opened().size() >= Birthday.invites().size():
			var cake := create_tween()
			cake.tween_interval(3.8)
			cake.tween_callback(_birthday_cake))


# Maman brings the cake: lights down, everyone sings, she blows out her candles, a slice; then her friends go home.
func _birthday_cake() -> void:
	_party_busy = true
	_control.enabled = false
	_party_cake = _put(PartyArt.cake(true), PARTY_TABLE_X - 65.0, 566.0)
	for k in 8:
		_party_flames.append(_glow(_party_cake.position + Vector2(31.0 + k * 9.7 + 1.75, 23.0), 16.0, Color(1.0, 0.75, 0.4, 0.55)))
	_say(_mom, "Le gâteau !", 380.0, 1.8)
	var everyone: Array = [_mom, _dad] + _guests.values()
	var song := create_tween()
	song.tween_interval(2.0)
	for k in Birthday.SONG.size():
		var who: Character = everyone[k % everyone.size()]
		song.tween_callback(func() -> void:
			for person: Character in everyone:
				person.express("talk", 1.6)
			_say(who, Birthday.SONG[k], 380.0 if who == _mom or who == _dad else 240.0, 1.9))
		song.tween_interval(2.1)
	song.tween_callback(func() -> void: _say(_mom, "Fais un vœu, ma chouette !", 380.0, 2.0))
	song.tween_interval(2.2)
	song.tween_callback(func() -> void:
		_charlotte.express("effort", 1.2)
		_say(_charlotte, "Fffffffffff !", 300.0, 1.2))
	song.tween_interval(1.0)
	song.tween_callback(func() -> void:
		_party_cake.texture = PartyArt.cake(false)
		for f in _party_flames:
			f.queue_free()
		_party_flames.clear()
		Sfx.play("swoosh", _party_cake.position)
		for person: Character in [_charlotte] + everyone:
			person.express("laugh", 2.4)
		_say(_dad, "Hourra ! Bonne fête, ma grande !", 390.0, 2.2))
	song.tween_interval(2.4)
	song.tween_callback(func() -> void: _treat(PartyArt.cake_slice(), "Miam ! Du gâteau au chocolat !"))
	song.tween_interval(3.6)
	song.tween_callback(func() -> void:
		_say(_guests.values()[0], "Merci pour la fête, Chachoue !\nC'était la plus belle !", 240.0, 3.0))
	song.tween_interval(3.2)
	song.tween_callback(func() -> void:
		_say(_charlotte, "Merci d'être venus, mes amis !", 300.0, 2.6)
		for kid: Character in _guests.values():
			create_tween().tween_property(kid, "modulate:a", 0.0, 1.2).set_delay(1.4))
	song.tween_interval(3.0)
	song.tween_callback(func() -> void:
		for kid: Character in _guests.values():
			kid.queue_free()
		_guests.clear()
		Sfx.play("goodnight")
		Quests.complete(Birthday.QUEST)
		# She is eight now (Julien): the notebook, the menu and her height marks say so, and she may cross the streets alone.
		Notebook.announce("step", "Joyeux anniversaire ! Tu as %d ans astheure !" % GameState.age, "🎂  Ma fête")
		_mom_routine.pause(0.1, _mom.position.x)
		_party_busy = false
		_control.enabled = true)


# ── The wobbly tooth ────────────────────────────────────────

# Her bed: the tooth fairy's coin under her pillow the morning after, the tooth going under it at bedtime, else sleep.
func _bed_clicked() -> void:
	if Tooth.step() == 3:
		_under_the_pillow()
		return
	if Tooth.step() == 2:
		_say(_charlotte, "Je mets ma dent sous mon oreiller…", 300.0, 2.0)
		var later := create_tween()
		later.tween_interval(2.0)
		later.tween_callback(_go_to_sleep)
		return
	_go_to_sleep()


func _wobbly_tooth() -> void:
	_mom.express("surprised", 2.0)
	_say(_mom, "Chachoue, souris-moi… Oh !\nTa dent d'en avant branle !", 400.0, 3.2)
	var more := create_tween()
	more.tween_interval(3.4)
	more.tween_callback(func() -> void:
		_charlotte.express("surprised", 2.0)
		_say(_charlotte, "Elle bouge toute seule !", 300.0))
	more.tween_interval(2.4)
	more.tween_callback(func() -> void:
		_say(_mom, "Croque dans une belle pomme, a va peut-être tomber.\nY en a dans le frigo.", 420.0, 3.6)
		Notebook.announce("step", "Croque dans une pomme du frigo !", Tooth.HEADING))


# The apple from the fridge: a big bite, and out comes the tooth.
func _bite_the_apple() -> void:
	_treat(InteriorArt.snack("apple"), "Crounch !", 0.4)
	Sfx.play("nibble", _charlotte.position)
	var later := create_tween()
	later.tween_interval(2.4)
	later.tween_callback(func() -> void:
		Tooth.set_step(2)
		Sfx.play("pop", _charlotte.position + Vector2(0, -120))
		_charlotte.express("grin", 2.4)
		_treat(Tooth.tooth(), "Ma dent est tombée !", 0.0)
		Notebook.announce("step", "Mets ta dent sous ton oreiller, pis dodo !", Tooth.HEADING))


# In the morning, under the pillow: the toonie.
func _under_the_pillow() -> void:
	_charlotte.pet(0.8, 0.3)
	Sfx.play("chime")
	_treat(Tooth.toonie(), "Un 2 $ ! La fée des dents est passée !", 0.2)
	Quests.complete(Tooth.QUEST)


# ── New Year's Eve and Day ──────────────────────────────────

func _build_new_year() -> void:
	_tv.before_click = func() -> bool:
		if NewYear.step() != 1:
			return false
		_new_years_eve()
		return true
	add_child(QuestMark.make(_tv.get_global_rect().get_center() - Vector2(0, 90), func() -> bool:
		return NewYear.step() == 1 and _control.enabled))
	add_child(QuestMark.make(Vector2(BEDROOM.x + 584.0, 340.0), func() -> bool:
		return (NewYear.step() == 2 or Tooth.step() == 2 or Tooth.step() == 3) and _control.enabled))


# The Bye Bye in the dimmed hall with her parents, the countdown, the wishes, then the fireworks through the salon window.
func _new_years_eve() -> void:
	_control.enabled = false
	_mom_routine.pause(90.0, _tv.stand_x)
	_dad_routine.pause(90.0, _tv.stand_x)
	var mom_was := _mom.position.x
	var dad_was := _dad.position.x
	var layer := CanvasLayer.new()
	layer.layer = 49
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.size = VIEW
	layer.add_child(black)
	var big := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 120
	settings.font_color = Color("#FFD23F")
	settings.outline_size = 14
	settings.outline_color = Color("#1D4F91")
	big.label_settings = settings
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.size = Vector2(VIEW.x, 160)
	big.position = Vector2(0, 90)
	big.modulate.a = 0.0
	var top := CanvasLayer.new()
	top.layer = 53
	top.add_child(big)
	add_child(top)
	# Lambdas copy locals: the veil goes in a dictionary so the one that takes it away sees it.
	var veil := {}
	var steps := create_tween()
	steps.tween_property(black, "color:a", 1.0, 0.6)
	steps.tween_callback(func() -> void:
		veil.node = _movie_dark()
		var show: Array[String] = ["byebye"]
		_tv.channels = show
		_tv.turn_on(0)
		Sfx.play("tv", _tv.get_global_rect().get_center())
		var spots := [[_charlotte, 2790.0], [_mom, 2880.0], [_dad, 2970.0]]
		for spot: Array in spots:
			var who: Character = spot[0]
			who.position.x = spot[1]
			who.facing = -1
			who.is_walking = false
			who.modulate = Color(0.8, 0.82, 0.96))
	steps.tween_property(black, "color:a", 0.0, 0.8)
	for line: Array in NewYear.SHOW:
		steps.tween_callback(_new_year_says.bind(line[0], line[1]))
		steps.tween_interval(2.7)
		# They turned to each other to talk (`_say`); now back to the show.
		steps.tween_callback(func() -> void:
			for who: Character in [_charlotte, _mom, _dad]:
				who.facing = -1)
		steps.tween_interval(0.5)
	# The countdown.
	steps.tween_property(big, "modulate:a", 1.0, 0.2)
	for n in range(10, 0, -1):
		steps.tween_callback(func() -> void:
			big.text = str(n)
			big.scale = Vector2.ONE
			Sfx.play("click", Vector2.INF, 0.0, 1.0 + (10 - n) * 0.04))
		steps.tween_interval(0.9)
	steps.tween_callback(func() -> void:
		big.text = "BONNE ANNÉE !"
		settings.font_size = 90
		Sfx.play("chime")
		Sfx.play("goodnight")
		for who: Character in [_charlotte, _mom, _dad]:
			who.express("laugh", 3.0))
	steps.tween_interval(2.4)
	steps.tween_property(big, "modulate:a", 0.0, 0.5)
	for line: Array in NewYear.AFTER:
		steps.tween_callback(_new_year_says.bind(line[0], line[1]))
		steps.tween_interval(3.0)
	# To the salon window for the fireworks.
	steps.tween_property(black, "color:a", 1.0, 0.6)
	var fireworks := NewYear.Fireworks.new()
	# Midnight in the salon: the whole room dimmed, the fireworks bright in the window.
	var midnight := CanvasModulate.new()
	midnight.color = Color(0.5, 0.52, 0.74)
	steps.tween_callback(func() -> void:
		veil.node.queue_free()
		add_child(midnight)
		fireworks.night = midnight.color
		_tv.turn_off()
		_tv.channels = TvShows.ALL.duplicate()
		fireworks.glass = Rect2(_salon_window.position + Vector2(14, 14), Vector2(142, 272))
		add_child(fireworks)
		# Behind the tree, just over the window's picture.
		move_child(fireworks, _salon_window.get_index() + 1)
		_charlotte.position.x = 1610.0
		_charlotte.facing = 1
		_mom.position.x = 1510.0
		_mom.facing = 1
		_dad.position.x = 1790.0
		_dad.facing = -1
		for who: Character in [_charlotte, _mom, _dad]:
			who.modulate = Color.WHITE)
	steps.tween_property(black, "color:a", 0.0, 0.6)
	steps.tween_callback(func() -> void:
		_charlotte.express("wonder", 4.0)
		_say(_charlotte, "Ooooh ! Des rouges et des bleues !", 300.0, 3.0))
	steps.tween_interval(3.4)
	steps.tween_callback(_new_year_says.bind(0, "Wow ! Une belle année qui commence."))
	steps.tween_interval(3.4)
	steps.tween_callback(_new_year_says.bind(1, "Bon, il est ben tard. Au lit, ma chouette !"))
	steps.tween_interval(3.0)
	steps.tween_property(black, "color:a", 1.0, 0.5)
	steps.tween_callback(func() -> void:
		midnight.queue_free()
		_mom.position.x = mom_was
		_dad.position.x = dad_was)
	steps.tween_property(black, "color:a", 0.0, 0.5)
	steps.tween_callback(func() -> void:
		layer.queue_free()
		top.queue_free()
		NewYear.set_step(2)
		Notebook.announce("step", "Il est minuit passé : au lit !", NewYear.HEADING)
		_control.enabled = true
		_mom_routine.pause(0.1, mom_was)
		_dad_routine.pause(0.1, dad_was))


func _new_year_says(who: int, text: String) -> void:
	if who < 0:
		_say(_charlotte, text, 300.0, 3.0)
	else:
		_say(_dad if who == 0 else _mom, text, 390.0 if who == 0 else 380.0, 3.0)


# New Year's Day: her resolution, and the wishes.
func _ask_resolution() -> void:
	_control.enabled = false
	var choices: Array = []
	for r: Array in NewYear.RESOLUTIONS:
		choices.append({"text": r[0]})
	var card := ChoiceCard.ask(self, "Ta bonne résolution pour la nouvelle année ?", choices)
	card.chose.connect(func(i: int) -> void:
		_control.enabled = true
		if i < 0 or i >= NewYear.RESOLUTIONS.size():
			return
		var r: Array = NewYear.RESOLUTIONS[i]
		GameState.flags[NewYear.RESOLUTION] = r[0]
		_say(_charlotte, r[1], 300.0, 3.2)
		var who := _mom if absf(_mom.position.x - _charlotte.position.x) < absf(_dad.position.x - _charlotte.position.x) else _dad
		var more := create_tween()
		more.tween_interval(3.4)
		more.tween_callback(func() -> void:
			who.express("happy", 2.4)
			_say(who, r[2] + "\nBonne année, pis la santé, mon cœur !", 390.0 if who == _dad else 380.0, 3.6))
		more.tween_interval(3.6)
		more.tween_callback(func() -> void:
			Sfx.play("chime")
			Quests.complete(NewYear.QUEST)))


# ── Christmas ───────────────────────────────────────────────

func _build_noel_spots() -> void:
	# The kitchen counter, for the cookies.
	add_child(DoorSpot.make(Rect2(KITCHEN_START + 120.0, 380.0, 190.0, 220.0), _bake, KITCHEN_START + 210.0))
	add_child(QuestMark.make(Vector2(KITCHEN_START + 215.0, 330.0), func() -> bool:
		return Christmas.step() == 2 and not Carry.has("biscuits") and _control.enabled and not _noel_busy))
	add_child(QuestMark.make(Vector2(XMAS_X, 250.0), func() -> bool:
		return Christmas.step() == 2 and Carry.has("biscuits") and _control.enabled))
	# The dining table, for the réveillon.
	add_child(DoorSpot.make(NOEL_TABLE, _reveillon, NOEL_TABLE.position.x - 30.0))
	add_child(QuestMark.make(NOEL_TABLE.get_center() - Vector2(0, 110), func() -> bool:
		return Christmas.step() == 3 and _control.enabled and not _noel_busy))
	# The desk (the letter) and the bed (Christmas Eve).
	add_child(QuestMark.make(Vector2(BEDROOM.x + 1260.0, 380.0), func() -> bool:
		return Christmas.step() == 1 and not Carry.has("lettre") and _control.enabled))
	add_child(QuestMark.make(Vector2(BEDROOM.x + 584.0, 340.0), func() -> bool:
		return Christmas.step() == 4 and _control.enabled))


# What lies under the tree: Santa's plate (full on Christmas Eve, crumbs and his note in the morning), and the presents.
func _noel_under_tree() -> void:
	if _xmas_tree == null:
		return
	var step := Christmas.step()
	if _noel_plate == null and step >= 3:
		_noel_plate = _put(Christmas.cookies(step >= 5), XMAS_X - 170.0, 676.0, 0.9)
	elif _noel_plate and step >= 5:
		_noel_plate.texture = Christmas.cookies(true)
	if step == 5 and _noel_presents.is_empty():
		# Six presents piled under the tree, a back row behind a front row: [x from the tree, floor, scale].
		var spots := [[-110.0, 664.0, 0.78], [-40.0, 692.0, 0.9], [30.0, 664.0, 0.8], [100.0, 694.0, 0.9], [-10.0, 640.0, 0.7], [180.0, 690.0, 0.85]]
		var order := [0, 2, 4, 1, 3, 5]
		for k in order:
			var i: int = k
			var id: String = Christmas.PRESENTS[i][0]
			var spot: Array = spots[order.find(i)]
			var box := _put(Christmas.present(i, id in Christmas.opened()), XMAS_X + float(spot[0]), float(spot[1]), float(spot[2]))
			_noel_presents.append(box)
			box.set_meta("kind", i)
			add_child(DoorSpot.make(Rect2(box.position + Vector2(10, 10), Vector2(90, 80) * float(spot[2])), _open_present.bind(i), box.position.x - 30.0))
			add_child(QuestMark.make(box.position + Vector2(48, -24), func() -> bool:
				return Christmas.step() == 5 and id not in Christmas.opened() and _control.enabled and not _noel_busy, 0.7))


# The drawing pad on her desk, for the letter: when it is done it goes in an envelope, in her arms.
func _write_to_santa() -> void:
	if Carry.busy():
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	_control.enabled = false
	var pad := DrawingPad.new()
	pad.done_text = "Pour le père Noël !"
	pad.closed.connect(func(drawing: Image) -> void:
		_control.enabled = true
		if drawing == null:
			_say(_charlotte, "Je vais la finir tantôt…", 300.0)
			return
		Carry.take(_charlotte, "lettre")
		Sfx.play("chime")
		_charlotte.express("happy", 2.0)
		_say(_charlotte, "Ma lettre est finie ! Je la donne à Maman.", 300.0)
		Notebook.announce("step", "Ta lettre est prête ! Donne-la à Maman.", Christmas.HEADING))
	add_child(pad)


func _letter_to_mom() -> void:
	Carry.put_down(_charlotte)
	Christmas.set_step(2)
	_mom.express("happy", 2.4)
	_say(_mom, "Je vais la poster au Pôle Nord :\ncode postal H0H 0H0 !", 400.0, 3.4)
	var more := create_tween()
	more.tween_interval(3.6)
	more.tween_callback(func() -> void:
		_say(_mom, "Pis astheure, on fait des biscuits\npour le père Noël ! Viens au comptoir.", 400.0, 3.4)
		Notebook.announce("step", "Fais des biscuits avec Maman, au comptoir de la cuisine !", Christmas.HEADING))


# The cookies at the counter: the whole cookie studio (mix, roll, cut, bake, decorate, plate); when it is done the plate and the
# glass are in her arms.
func _bake() -> void:
	if Christmas.step() != 2 or _noel_busy or Carry.has("biscuits"):
		return
	if Christmas.baked() >= Christmas.BAKE.size():
		# Already made (an older save, or the plate was put down on the way): take them again.
		if Carry.take(_charlotte, "biscuits"):
			_say(_charlotte, "L'assiette et le verre de lait,\nsous le sapin !", 300.0)
		else:
			_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	if Carry.busy():
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	_noel_busy = true
	_control.enabled = false
	_mom_routine.pause(6.0, _charlotte.position.x)
	_charlotte.facing = 1
	var studio := CookieStudio.new()
	studio.for_santa = true
	studio.closed.connect(func(result: Dictionary) -> void:
		_control.enabled = true
		_noel_busy = false
		if result.is_empty():
			_say(_charlotte, "On les fera tantôt, Maman !", 300.0)
			return
		_mom_routine.pause(4.0, _charlotte.position.x)
		Sfx.play("chime")
		_charlotte.express("happy", 2.4)
		_say(_mom, "Ils sont magnifiques ! Le père Noël\nva se régaler.", 380.0, 3.4)
		_treat(Christmas.cookies(), "Des biscuits pour le père Noël !", 0.4)
		Carry.take(_charlotte, "biscuits"))
	add_child(studio)


func _cookies_under_tree() -> void:
	_charlotte.facing = 1
	_charlotte.pet(0.9, 0.4)
	Carry.put_down(_charlotte)
	Christmas.set_step(3)
	_noel_under_tree()
	Sfx.play("pop", Vector2(XMAS_X - 130.0, 640.0))
	_say(_charlotte, "Voilà, père Noël ! Bon appétit !", 300.0)
	Notebook.announce("step", "C'est le réveillon ! Va à table, dans le salon.", Christmas.HEADING)


# The réveillon: the salon goes evening-dark round the lit tree, candles on the table, the family round it; then to bed.
func _reveillon() -> void:
	if Christmas.step() != 3 or _noel_busy:
		return
	_noel_busy = true
	_control.enabled = false
	_mom_routine.pause(40.0, NOEL_TABLE.get_center().x)
	_dad_routine.pause(40.0, NOEL_TABLE.get_center().x)
	var mom_was := _mom.position.x
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.size = VIEW
	var layer := CanvasLayer.new()
	layer.layer = 49
	layer.add_child(black)
	add_child(layer)
	var veil := Polygon2D.new()
	var pie := Sprite2D.new()
	var steps := create_tween()
	steps.tween_property(black, "color:a", 1.0, 0.6)
	steps.tween_callback(func() -> void:
		# Evening: everything but the tree's lights and the candles under a night-blue veil.
		# The whole flat, not just the salon: the view reaches past the salon's end and a veil that stopped there left a straight line
		# down the room (Julien: dark, then a vertical line, then not dark).
		veil.polygon = PackedVector2Array([Vector2(HALL.x - 400.0, -200.0), Vector2(HALL.y + 400.0, -200.0), Vector2(HALL.y + 400.0, VIEW.y + 200.0), Vector2(HALL.x - 400.0, VIEW.y + 200.0)])
		veil.color = Color(0.04, 0.05, 0.16, 0.45)
		add_child(veil)
		if _xmas_glow_from >= 0:
			move_child(veil, _xmas_glow_from)
		pie.texture = Christmas.tourtiere()
		pie.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pie.position = Vector2(NOEL_TABLE.get_center().x, NOEL_TABLE.position.y + 30.0)
		pie.scale = Vector2.ONE * 0.8
		add_child(pie)
		for cx in [NOEL_TABLE.position.x + 70.0, NOEL_TABLE.end.x - 70.0]:
			_candle(Vector2(cx, NOEL_TABLE.position.y + 14.0), 70.0)
		# Round the table, clear of the tree.
		# Maman and Papa at the two ends, Charlotte between them, the pie in the middle: they face each other.
		_mom.position.x = NOEL_TABLE.position.x - 30.0
		_mom.facing = 1
		_charlotte.position.x = NOEL_TABLE.position.x + 85.0
		_charlotte.facing = 1
		_dad.position.x = NOEL_TABLE.end.x + 30.0
		_dad.facing = -1
		for who: Character in [_mom, _charlotte, _dad]:
			who.is_walking = false
			who.modulate = Color(0.86, 0.84, 0.95)
		_camera.position.x = NOEL_TABLE.get_center().x - 120.0)
	steps.tween_property(black, "color:a", 0.0, 0.8)
	for line: Array in Christmas.REVEILLON:
		var who: Character = _dad if line[0] == 0 else (_mom if line[0] == 1 else _charlotte)
		var height := 390.0 if line[0] == 0 else (380.0 if line[0] == 1 else 300.0)
		steps.tween_callback(_say.bind(who, line[1], height, 3.2))
		steps.tween_interval(3.4)
		if line[1].begins_with("Pis une bûche"):
			steps.tween_callback(func() -> void: _treat(Christmas.buche(), "Miam ! De la bûche de Noël !"))
			steps.tween_interval(3.0)
	steps.tween_property(black, "color:a", 1.0, 0.6)
	steps.tween_callback(func() -> void:
		veil.queue_free()
		pie.queue_free()
		_mom.position.x = mom_was
		for who: Character in [_mom, _charlotte, _dad]:
			who.modulate = Color.WHITE
		Christmas.set_step(4)
		Notebook.announce("step", "Au lit ! Le père Noël passe quand les enfants dorment.", Christmas.HEADING))
	steps.tween_property(black, "color:a", 0.0, 0.6)
	steps.tween_callback(func() -> void:
		layer.queue_free()
		_noel_busy = false
		_control.enabled = true
		_mom_routine.pause(0.1, _mom.position.x)
		_dad_routine.pause(0.1, _dad.position.x))


# Christmas morning: she opens a present; with the last one, merry Christmas all round and the quest is done.
func _open_present(i: int) -> void:
	var id: String = Christmas.PRESENTS[i][0]
	if Christmas.step() != 5 or _noel_busy or id in Christmas.opened():
		return
	_charlotte.facing = 1
	_charlotte.pet(0.9, 0.5)
	Christmas.open_present(id)
	for box: Sprite2D in _noel_presents:
		if int(box.get_meta("kind")) == i:
			box.texture = Christmas.present(i, true)
			Sfx.play("swoosh", box.position)
	_treat(Christmas.gift_picture(id), Christmas.PRESENTS[i][1], 0.2)
	if Christmas.opened().size() < Christmas.PRESENTS.size():
		return
	_noel_busy = true
	GameState.flags[Christmas.PLUSH] = true
	var steps := create_tween()
	steps.tween_interval(3.6)
	steps.tween_callback(func() -> void:
		_dad_routine.pause(8.0, _charlotte.position.x)
		_dad.express("happy", 3.0)
		_say(_dad, "Joyeux Noël, ma Chachoue !", 390.0, 2.8))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		_charlotte.express("laugh", 2.4)
		_say(_charlotte, "Joyeux Noël, Papa ! Merci, père Noël !", 300.0, 2.8))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		Sfx.play("goodnight")
		Quests.complete(Christmas.QUEST)
		_noel_busy = false)


# ── Papa's hockey night ─────────────────────────────────────

# She hands Papa his chips: the quest is done, and the hockey goes on the hallway TV.
func _hockey_night() -> void:
	Carry.put_down(_charlotte)
	_dad.express("laugh", 2.4)
	_say(_dad, "Mes Ruffles ! T'es la meilleure, Chachoue !\nViens, on regarde le Canadien !", 390.0, 3.6)
	Quests.complete("chips")
	if _tv:
		_tv.turn_on(maxi(_tv.channels.find("hockey"), 0))
		Sfx.play("tv", _tv.get_global_rect().get_center())


# ── The movie night with the twins (Cinema) ─────────────────

# Where everyone sits on the cushions (x, facing), and the floor under them: in front of the hallway TV, nearer than where
# she walks. Charlotte first, then Alphée and Constance.
const MOVIE_SEATS := [[2545.0, 1], [2445.0, 1], [2770.0, -1], [2345.0, 1], [2870.0, -1]]
const MOVIE_FLOOR := 690.0
const CUSHION_H := 10.0
# Where the twins wait for her before the film, and what is said during it ([seconds into the film, who: -1 Charlotte,
# 0 Alphée, 1 Constance, words]).
const MOVIE_WAIT := [2700.0, 2830.0, 2960.0, 3090.0]
const MOVIE_LINES := {
	"film": [
		[1.5, 1, "Chut ! Ça commence !"],
		[8.0, -1, "Oh ! Un p'tit renard en traîneau !"],
		[16.0, 0, "Passe-moi les chips, Chachoue !"],
		[24.0, 1, "Y est bien équipé avec son foulard bleu !"],
		[32.0, -1, "Wow ! Y glisse super vite !"],
		[40.0, 0, "Pis la neige qui revole partout !"],
		[50.0, 1, "Hi hi ! Le bonhomme de neige\nlui fait bonjour !"],
		[58.0, -1, "Aww ! Y lui donne son foulard !"],
		[66.0, 0, "Miam, des bonbons !"],
		[76.0, 1, "Les aurores boréales, c'est donc beau !"],
		[86.0, -1, "Y est rendu chez eux, y va être ben au chaud."],
	],
	"grinch": [
		[1.5, 0, "Chut ! C'est mon préféré !"],
		[9.0, 1, "Ça a l'air paisible, le village…"],
		[18.0, -1, "Oh ! Y descend de sa montagne\nen cachette !"],
		[26.0, 0, "Passe-moi les chips !"],
		[34.0, 1, "Y est ben petit, son traîneau !"],
		[42.0, -1, "Hé ! Les lumières s'éteignent\nune à une…"],
		[52.0, 0, "Pas fin, ça !"],
		[62.0, 1, "Attends, ça va peut-être virer de bord."],
		[72.0, -1, "Les cloches ! Y a quelque chose qui change !"],
		[80.0, 0, "Oh ! Son cœur grandit !"],
		[88.0, 1, "Awww… C'est beau, Noël."],
	],
	"maison": [
		[1.5, 1, "J'adore ce film-là !"],
		[8.0, 0, "Y sont partis sans lui !"],
		[16.0, -1, "Aïe ! La grosse maison toute décorée !"],
		[26.0, 1, "Y saute devant la fenêtre, y est content !"],
		[34.0, 0, "Y est tout seul… pis ça a l'air le fun !"],
		[44.0, -1, "Passe-moi les bonbons !"],
		[52.0, 1, "Ha ha ! Le pot de peinture !"],
		[60.0, 0, "BONG ! Son chapeau vole !"],
		[68.0, -1, "Les voleurs sont nuls !"],
		[78.0, 1, "Y arrivent enfin ! Les phares dans la neige !"],
		[88.0, 0, "Awww, le gros câlin à la porte."],
	],
	"ratatouille": [
		[1.5, -1, "Chut ! Ça commence !"],
		[9.0, 1, "Paris, c'est donc ben beau !"],
		[18.0, 0, "La tour Eiffel qui brille !"],
		[28.0, -1, "Oh ! Une souris sur le toit !"],
		[36.0, 1, "Non, un rat ! Il est mignon pareil !"],
		[46.0, 0, "Un rat qui fait à manger ?\nHi hi !"],
		[54.0, -1, "Ça me donne faim…\nPasse-moi les chips !"],
		[62.0, 1, "Y a un chapeau de chef !"],
		[72.0, 0, "Hmm, la soupe sent bon, ça paraît !"],
		[82.0, -1, "Wow, le plat est tellement beau !"],
		[90.0, 1, "Moi aussi je veux être chef !"],
	],
	"reine": [
		[1.5, 0, "Oh, c'est celui avec le château de glace !"],
		[9.0, -1, "Les aurores boréales, wow !"],
		[18.0, 1, "Toute la neige qui tourne !"],
		[28.0, 0, "Passe-moi les bonbons, Chachoue !"],
		[36.0, -1, "Un escalier de glace qui se construit tout seul !"],
		[46.0, 1, "Je connais la chanson !"],
		[56.0, 0, "Pis le château qui pousse !"],
		[66.0, -1, "Je veux un château comme ça !"],
		[76.0, 1, "Le bonhomme de neige est content."],
		[86.0, 0, "Y a des étincelles partout, c'est magique."],
	],
	"lion": [
		[1.5, 1, "Chut ! Y a un gros soleil !"],
		[9.0, 0, "Les éléphants pis les girafes qui marchent !"],
		[18.0, -1, "Y a des oiseaux dans le ciel aussi !"],
		[28.0, 1, "Oh ! Le p'tit lionceau tout en haut du rocher !"],
		[37.0, -1, "Tout le monde le regarde !"],
		[46.0, 0, "Passe-moi les chips, Chachoue !"],
		[54.0, 1, "Wow ! Une forêt avec une cascade !"],
		[63.0, -1, "Les papillons sont beaux !"],
		[72.0, 0, "Y a trois p'tits amis qui marchent ensemble."],
		[82.0, 1, "La nuit… les étoiles… c'est ben calme."],
		[90.0, -1, "Y est devenu grand, là."],
	],
	"nemo": [
		[1.5, -1, "Chut ! Ça commence !"],
		[8.0, 1, "Le récif de corail est donc ben beau !"],
		[16.0, 0, "Regarde le p'tit poisson orange pis blanc !"],
		[26.0, -1, "Hi hi ! Y se cache dans l'anémone !"],
		[34.0, 1, "Wow, les méduses roses !"],
		[42.0, 0, "Passe-moi les bonbons, Chachoue !"],
		[50.0, -1, "Y a un banc de p'tits poissons qui tournent !"],
		[60.0, 1, "Une grosse tortue ! Y glisse avec elle !"],
		[70.0, 0, "Les bulles montent partout…"],
		[80.0, -1, "Oh ! Une baleine géante !"],
		[89.0, 1, "Ils sont revenus chez eux, bien en sécurité."],
	],
	"up": [
		[1.5, 0, "J'adore les ballons !"],
		[8.0, -1, "Y en a des tonnes qui sortent de la maison !"],
		[18.0, 1, "Chut ! Y a la ville en arrière."],
		[28.0, 0, "Wow ! La maison s'envole !"],
		[36.0, -1, "Ils sont plus hauts que les nuages !"],
		[44.0, 1, "Passe-moi les chips, Chachoue !"],
		[54.0, 0, "Oh ! Une cascade sur une montagne plate !"],
		[64.0, -1, "Pis la brume en bas, c'est beau !"],
		[74.0, 1, "Ils sont rendus au pied de la cascade !"],
		[82.0, 0, "Deux chaises sur la galerie… c'est paisible."],
		[90.0, -1, "Y a un ballon qui s'envole encore !"],
	],
	"totoro": [
		[1.5, 1, "Chut ! Y pleut sur le chemin."],
		[9.0, -1, "Une fille avec un parapluie jaune !"],
		[18.0, 0, "Oh ! Y a une grosse bête poilue à côté d'elle !"],
		[28.0, 1, "Elle est toute douce, ça se voit !"],
		[36.0, -1, "Passe-moi les bonbons !"],
		[44.0, 0, "Ça, c'est un arbre géant !"],
		[54.0, 1, "Hi hi ! Les p'tites boules noires !"],
		[64.0, -1, "Wow, la lune pis les lucioles !"],
		[74.0, 0, "La grosse bête tourne comme une toupie !"],
		[84.0, 1, "Le matin, les pousses ont poussé…"],
		[91.0, -1, "Elle est contente, la petite fille."],
	],
}
const MOVIE_END := [
	[0, "C'était trop bon !"],
	[1, "Merci pour la soirée, Chachoue !"],
	[-1, "On en refait une bientôt !"],
]


# Alyzée's birthday (Party): Maman found the invitation in her school bag, and they will go and buy a present.
func _invitation() -> void:
	Quests.start(Party.QUEST)
	Party.set_step(1)
	_mom.express("happy", 2.4)
	_say(_mom, "Regarde ce que j'ai trouvé dans ton sac d'école :\nune invitation ! C'est la fête d'Alyzée !", 400.0, 3.8)
	_treat(PartyArt.invitation(), "Une invitation !", 0.6)
	var more := create_tween()
	more.tween_interval(4.2)
	more.tween_callback(func() -> void:
		_say(_mom, "On va lui acheter un cadeau au Jean Coutu,\nsur la rue Masson. Je t'attends à la porte !", 400.0, 3.8))


func _mom_about_school() -> void:
	if Quests.available(Emilia.QUEST):
		_say(_mom, "Il paraît qu'une nouvelle élève arrive à ton école !\nVeux-tu y aller ? Passe par la porte d'en avant.", 400.0, 4.0)
		return
	_say(_mom, "Veux-tu aller à l'école aujourd'hui ?\nJe t'amène : passe par la porte d'en avant !", 400.0, 3.6)


# Once the first movie night is done, what she can ask Maman: another one, or just a word.
func _ask_mom() -> void:
	_control.enabled = false
	var school := School.available_today()
	var movie := Cinema.can_ask()
	var choices: Array = [{"text": "On cuisine ensemble ?", "note": "pizza, muffins, biscuits…"}]
	var kinds: Array = ["cook"]
	if movie:
		choices.append({"text": "On fait une soirée cinéma ?", "note": "avec un ou une amie"})
		kinds.append("movie")
	if school:
		choices.append({"text": "Je vais à l'école ?"})
		kinds.append("school")
	choices.append({"text": "Juste un câlin !"})
	kinds.append("hug")
	var card := ChoiceCard.ask(self, "Qu'est-ce que tu dis à Maman ?", choices)
	card.chose.connect(func(i: int) -> void:
		_control.enabled = true
		if i < 0:
			return
		_mom_routine.pause(4.0, _charlotte.position.x)
		var what: String = kinds[i]
		if what == "cook":
			_cook_with_mom()
		elif what == "movie":
			_choose_movie_friends()
		elif what == "school":
			_mom_about_school()
		else:
			_hug_with(_mom, _mom_routine, MOM_LINES[_mom_line % MOM_LINES.size()], 350.0)
			_mom_line += 1)


# A real hug (Julien: nothing happened, only a line): she walks up to the parent, they face each other, arms round, little
# hearts rise, then the parent says a word.
func _hug_with(who: Character, routine: FamilyRoutine, words: String, bubble_width: float) -> void:
	_control.enabled = false
	routine.pause(10.0, _charlotte.position.x)
	var side := -1 if _charlotte.position.x < who.position.x else 1
	var spot := who.position.x + side * 58.0
	var go := create_tween()
	go.tween_callback(func() -> void:
		_charlotte.facing = -side
		_charlotte.is_walking = true)
	go.tween_property(_charlotte, "position:x", spot, maxf(absf(spot - _charlotte.position.x) / 190.0, 0.05))
	go.tween_callback(func() -> void:
		_charlotte.is_walking = false
		_charlotte.facing = -side
		who.facing = side
		_charlotte.task = "hug"
		who.task = "hug"
		_charlotte.express("happy", 3.0)
		who.express("happy", 3.0)
		Sfx.play("purr", _charlotte.position)
		for k in 4:
			_heart_up(Vector2((_charlotte.position.x + who.position.x) / 2.0 + (k - 1.5) * 14.0, _charlotte.position.y - 170.0), k * 0.35))
	go.tween_interval(2.8)
	go.tween_callback(func() -> void:
		_charlotte.task = ""
		who.task = ""
		_control.enabled = true
		_say(who, words, bubble_width))


# A little pink heart that floats up and fades.
func _heart_up(at: Vector2, delay: float) -> void:
	var heart := Label.new()
	heart.text = "♥"
	heart.add_theme_font_size_override("font_size", 26)
	heart.add_theme_color_override("font_color", Color("#FF5E8A"))
	heart.add_theme_color_override("font_outline_color", Color.WHITE)
	heart.add_theme_constant_override("outline_size", 5)
	heart.position = at
	heart.z_index = 20
	heart.modulate.a = 0.0
	add_child(heart)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(heart, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(heart, "position:y", at.y - 60.0, 1.6)
	tw.tween_property(heart, "modulate:a", 0.0, 0.5)
	tw.tween_callback(heart.queue_free)


# Cooking with Maman, on demand (Julien): she picks a recipe, then the whole studio (`CookieStudio`) at the counter.
func _cook_with_mom() -> void:
	_control.enabled = false
	var card := ChoiceCard.ask(self, "Qu'est-ce qu'on cuisine ?", [
		{"text": "Une pizza maison", "note": "la pâte, la sauce, les garnitures"},
		{"text": "Un dessert", "note": "gâteau, cupcakes, muffins, biscuits"},
		{"text": "Plus tard"}])
	card.chose.connect(func(i: int) -> void:
		if i == 0:
			_open_cooking("pizza")
		elif i == 1:
			_cook_dessert()
		else:
			_control.enabled = true)


func _cook_dessert() -> void:
	var ids := ["gateau", "cupcakes", "muffins", "pepites", "biscuits"]
	var card := ChoiceCard.ask(self, "Quel dessert ?", [
		{"text": "Un gâteau au chocolat", "note": "avec du glaçage, des fruits, des bougies"},
		{"text": "Des petits gâteaux", "note": "des cupcakes bien glacés"},
		{"text": "Des muffins aux bleuets"},
		{"text": "Des biscuits aux pépites", "note": "de chocolat"},
		{"text": "Des biscuits au gingembre", "note": "à découper pis à décorer"},
		{"text": "Plus tard"}])
	card.chose.connect(func(i: int) -> void:
		if i >= ids.size():
			_control.enabled = true
			return
		_open_cooking(ids[i]))


func _open_cooking(recipe: String) -> void:
	_mom.express("happy", 2.0)
	_mom_routine.pause(8.0, _charlotte.position.x)
	var studio := CookieStudio.new()
	studio.recipe = recipe
	studio.closed.connect(func(result: Dictionary) -> void:
		_control.enabled = true
		if result.is_empty():
			_say(_charlotte, "On le fera tantôt, Maman !", 300.0)
			return
		_mom_routine.pause(4.0, _charlotte.position.x)
		Sfx.play("chime")
		var shot: Image = result.image
		shot.resize(110, 80, Image.INTERPOLATE_LANCZOS)
		shot.generate_mipmaps()
		var stars := int(result.get("stars", 2))
		var praise: String = ["Pas mal pour une première fois !", "Bravo, c'est vraiment réussi !", "Wow ! Une vraie cheffe !"][clampi(stars - 1, 0, 2)]
		_say(_mom, "%s\n%s  %s" % [str(CookieArt.recipe(str(result.recipe)).eat), "★".repeat(stars) + "☆".repeat(3 - stars), praise], 380.0, 4.2)
		_treat(ImageTexture.create_from_image(shot), "On a tout fait nous-mêmes !", 0.4))
	add_child(studio)


# Papa, on demand: to the Parc du Pélican, with him (`ParkOuting`).
func _ask_dad() -> void:
	_control.enabled = false
	var card := ChoiceCard.ask(self, "Qu'est-ce que tu dis à Papa ?", [{"text": "On va jouer au parc ?", "note": "le parc du Pélican"}, {"text": "Juste un câlin !"}])
	card.chose.connect(func(i: int) -> void:
		_control.enabled = true
		if i < 0:
			return
		_dad_routine.pause(4.0, _charlotte.position.x)
		if i == 0:
			_park_with_dad()
		else:
			_hug_with(_dad, _dad_routine, DAD_LINES[_dad_line % DAD_LINES.size()], 360.0)
			_dad_line += 1)


func _park_with_dad() -> void:
	if Carry.busy():
		_say(_charlotte, Carry.FULL_HANDS, 300.0)
		return
	_control.enabled = false
	_dad.express("happy", 3.0)
	_say(_dad, "Le parc ? Bonne idée, Chachoue !\nMets tes souliers, on y va.", 390.0, 3.0)
	var go := create_tween()
	go.tween_interval(3.2)
	go.tween_callback(func() -> void:
		ParkOuting.start()
		Transition.street_x = ParkOuting.START_X
		Transition.arrive = ""
		Transition.change_scene_saying(self, ParkOuting.PARK, "Papa t'amène jouer au parc du Pélican…"))


# Who comes to the movie night? Any friend she has met (`Cinema.FRIENDS`); with only the twins to ask, no question.
func _choose_movie_friends() -> void:
	var friends := Cinema.friends()
	_control.enabled = false
	var picker := GuestPicker.ask(self, "Qui veux-tu inviter ?", friends, Cinema.MAX_GUESTS)
	picker.picked.connect(func(ids: Array) -> void:
		_control.enabled = true
		if ids.is_empty():
			return
		Cinema.choose_guests(ids)
		Cinema.start_again()
		_pocket_money_for_the_movie(true))


# Maman gives her the pocket money for the evening's snacks (`again`: a movie night Charlotte asked for, after the quest).
func _pocket_money_for_the_movie(again := false) -> void:
	GameState.money += Cinema.MONEY
	Cinema.set_step(2)
	_mom.express("happy", 2.4)
	if again:
		_say(_mom, "Encore une soirée cinéma ? Bonne idée !\nJ'appelle %s. Tiens, 5 $." % Cinema.names(), 400.0, 3.6)
	else:
		_say(_mom, "Une soirée cinéma avec les jumelles ?\nQuelle bonne idée ! Tiens, 5 $.", 400.0, 3.6)
	Notebook.announce("step", "Maman t'a donné %s pour les grignotines !" % Quests.money_text(Cinema.MONEY), Cinema.HEADING)
	var more := create_tween()
	more.tween_interval(3.8)
	more.tween_callback(func() -> void: _say(_mom, "Des chips pis des bonbons,\npas plus, là !", 380.0))


# Step 3: the twins are already here (Maman let them in), standing in front of the TV with the blanket and the cushions
# laid out on the floor. Click them to start the film.
func _build_movie_night() -> void:
	if Cinema.step() != 3:
		return
	_movie_nest = _Nest.new()
	# Up a little from the floor they sit on, so the cushions are under their hips.
	_movie_nest.position = Vector2(2648.0, MOVIE_FLOOR - 18.0)
	add_child(_movie_nest)
	var who_comes: Array = Cinema.guests()
	_movie_nest.people = who_comes.size() + 1
	for i in who_comes.size():
		var sister := Character.new()
		sister.look = Cinema.look(str(who_comes[i]))
		sister.fidgets = true
		sister.scale = Vector2.ONE * CHAR_SCALE
		sister.position = Vector2(MOVIE_WAIT[i], FEET_Y)
		sister.facing = -1
		add_child(sister)
		_movie_twins.append(sister)
	var last_wait: float = MOVIE_WAIT[maxi(who_comes.size() - 1, 0)]
	var spot := DoorSpot.make(Rect2(MOVIE_WAIT[0] - 70.0, 260.0, last_wait - MOVIE_WAIT[0] + 140.0, 420.0), _start_movie, MOVIE_WAIT[0] - 120.0)
	spot.condition = func() -> bool: return Cinema.step() == 3 and _control.enabled
	add_child(spot)
	add_child(QuestMark.make(Vector2((MOVIE_WAIT[0] + last_wait) / 2.0, 250.0), func() -> bool: return Cinema.step() == 3 and _control.enabled))
	# Coming in, she remembers who is waiting for her.
	if _charlotte.position.x < BEDROOM.x:
		var hello := create_tween()
		hello.tween_interval(1.0)
		hello.tween_callback(func() -> void: _say(_charlotte, "%s %s\ndevant la télé !" % [Cinema.names(), "m'attendent" if Cinema.plural() else "m'attend"], 300.0, 3.0))


func _start_movie() -> void:
	if not Carry.has("snacks"):
		_say(_movie_twins[0], "As-tu les grignotines, Chachoue ?", 320.0)
		return
	_control.enabled = false
	# She picks the film, the very first night as well as the ones she asks Maman for.
	var menu := FilmMenu.ask(self, Cinema.FILMS)
	menu.chose.connect(func(id: String) -> void:
		if id == "":
			_control.enabled = true
			return
		_roll_film(id))


# The evening itself with the film `id` (a TvShows id): everyone sits, the lights go down, the film plays with its lines.
func _roll_film(id: String) -> void:
	_film = id
	for routine in [_mom_routine, _dad_routine]:
		routine.pause(TvShows.FILM_LENGTH + 14.0, 2650.0)
	_say(_charlotte, "J'ai tout ! Des chips et des bonbons !", 300.0)
	var go := create_tween()
	go.tween_interval(2.3)
	go.tween_callback(func() -> void:
		_movie_twins[0].express("grin", 2.0)
		_say(_movie_twins[0], "Yé ! Installe-toi, ça commence !", 320.0))
	go.tween_interval(2.3)
	go.tween_callback(func() -> void: Transition.through_black(self, _lights_down, 0.6))
	# The film starts when the screen is black (0.6 s); its lines come at their own time into it.
	go.tween_interval(0.6)
	var said := 0.0
	for line: Array in MOVIE_LINES.get(id, MOVIE_LINES.film):
		go.tween_interval(float(line[0]) - said)
		go.tween_callback(_movie_say.bind(line[1], line[2]))
		said = float(line[0])
	go.tween_interval(TvShows.FILM_LENGTH - said + 0.5)
	for line: Array in MOVIE_END:
		go.tween_callback(_movie_say.bind(line[0], line[1]))
		go.tween_interval(Twins.LINE_SECONDS)
	go.tween_callback(func() -> void:
		if Quests.active(Cinema.QUEST):
			Quests.complete(Cinema.QUEST)
		Sfx.play("chime", _charlotte.position)
		for who: Character in [_charlotte] + _movie_twins:
			who.express("happy", 2.4))
	go.tween_interval(2.0)
	go.tween_callback(func() -> void: Transition.through_black(self, _movie_over, 0.6))


# Everyone on the cushions, the snacks in the bowl, the hall lights off and the film on.
func _lights_down() -> void:
	var held := _charlotte.held()
	if held:
		held.visible = false
	var who: Array[Character] = [_charlotte]
	who.append_array(_movie_twins)
	# With one friend, she sits on the other side of the bowl.
	var seat_of: Array = [[0, 2], [0, 1, 2], [0, 1, 3, 2], [0, 1, 3, 2, 4]][clampi(who.size() - 2, 0, 3)]
	for i in who.size():
		var person := who[i]
		person.position.x = MOVIE_SEATS[seat_of[i]][0]
		person.facing = MOVIE_SEATS[seat_of[i]][1]
		person.seat_h = CUSHION_H
		person.seat_floor = MOVIE_FLOOR
		person.sitting = true
		person.is_walking = false
		person.fidgets = false
		person.modulate = Color(0.78, 0.8, 0.95)
	_movie_nest.bowl = true
	_movie_nest.modulate = Color(0.7, 0.72, 0.88)
	_movie_nest.queue_redraw()
	_movie_nest.dark = _movie_dark()
	_movie_nest.lights = []
	for light in _hall_lights:
		if light.visible:
			_movie_nest.lights.append(light)
			light.visible = false
	var film: Array[String] = [_film]
	_tv.channels = film
	_tv.turn_on(0)
	_film_sound = FilmSound.new()
	add_child(_film_sound)
	_film_sound.start(_film)
	Sfx.play("tv", _tv.get_global_rect().get_center())


# The film is over: the twins go home, the blanket is folded away, the lights come back on.
func _lights_up(keep_friends := false) -> void:
	if _film_sound and is_instance_valid(_film_sound):
		_film_sound.stop()
	_film_sound = null
	Carry.put_down(_charlotte)
	Cinema.clear()
	_charlotte.sitting = false
	_charlotte.fidgets = true
	_charlotte.modulate = Color.WHITE
	_charlotte.position = Vector2(MOVIE_WAIT[0] - 120.0, FEET_Y)
	_charlotte.facing = 1
	if not keep_friends:
		for sister in _movie_twins:
			sister.queue_free()
		_movie_twins.clear()
	for light in _movie_nest.lights:
		light.visible = true
	if _movie_nest.dark:
		_movie_nest.dark.queue_free()
	_movie_nest.queue_free()
	_movie_nest = null
	_tv.turn_off()
	_tv.channels = TvShows.ALL.duplicate()
	_control.enabled = true
	_say(_charlotte, "Quelle belle soirée !", 300.0)


# ── The pyjama party (`Sleepover`) ───────────────────────────────

# The film is over: the lights come back, and Charlotte decides whether her friends stay the night.
func _movie_over() -> void:
	_lights_up(true)
	_control.enabled = false
	var many := _movie_twins.size() > 1
	var card := ChoiceCard.ask(self, "%s %s dormir ici ?" % [Cinema.names(), "restent" if many else "reste"], [
		{"text": "Oui, une soirée pyjama !", "note": "dans ma chambre, sur des sacs de couchage", "color": Color("#C8B6F2")},
		{"text": "Non, %s chez %s" % ["ils rentrent" if many else "il rentre", "eux" if many else "lui"], "note": "à la prochaine !", "color": Color("#DDE6F0")}])
	card.chose.connect(func(i: int) -> void:
		if i == 0:
			_sleepover_begin()
		else:
			_friends_go_home())


# No sleepover: the friends say goodbye and go.
func _friends_go_home() -> void:
	var steps := create_tween()
	for k in _movie_twins.size():
		var who: Character = _movie_twins[k]
		steps.tween_callback(func() -> void: _say(who, MOVIE_END[mini(k, MOVIE_END.size() - 1)][1], 280.0, 2.4))
		steps.tween_interval(2.6)
	steps.tween_callback(func() -> void:
		for sister in _movie_twins:
			sister.queue_free()
		_movie_twins.clear()
		_control.enabled = true
		_say(_charlotte, "Quelle belle soirée !", 300.0))


# Yes: Maman says she'll call their parents, everyone puts on pyjamas, and the party moves to Charlotte's room.
func _sleepover_begin() -> void:
	_sleepover = true
	_shows_done = 0
	_mom.express("happy", 3.0)
	_say(_mom, "Une soirée pyjama ? Bonne idée !\nJ'appelle leurs parents.", 400.0, 3.0)
	var steps := create_tween()
	steps.tween_interval(3.4)
	steps.tween_callback(func() -> void:
		Transition.through_black(self, _sleepover_to_bedroom, 0.7))


func _sleepover_to_bedroom() -> void:
	_control.stop()
	# Pyjamas for everyone: Charlotte's own look is only lent (`_sleepover_morning` gives it back).
	_charlotte.set_look(Sleepover.pyjama(CharacterLook.charlotte(), 0))
	for k in _movie_twins.size():
		_movie_twins[k].set_look(Sleepover.pyjama(_movie_twins[k].look, k + 1))
	var x := BEDROOM.x
	_camp = Sleepover.Camp.new()
	var n := _movie_twins.size()
	for k in n:
		_camp.spots.append(x + 330.0 + k * 195.0)
		_camp.colors.append(Color(Sleepover.COLORS[(k + 1) % Sleepover.COLORS.size()]).darkened(0.1))
	add_child(_camp)
	# The people sit on the bags: they are drawn one level above them.
	_charlotte.z_index = 1
	for k in n:
		var friend: Character = _movie_twins[k]
		friend.position = Vector2(_camp.spots[k] + 10.0, FEET_Y)
		friend.facing = 1 if k % 2 == 0 else -1
		friend.sitting = true
		friend.sit_on_ground = true
		friend.seat_h = 0.0
		friend.fidgets = false
		friend.z_index = 1
		friend.modulate = Color.WHITE
	_charlotte.position = Vector2(x + 300.0, FEET_Y)
	_charlotte.facing = 1
	_charlotte.sitting = true
	_charlotte.sit_on_ground = true
	_charlotte.seat_h = 0.0
	_charlotte.modulate = Color.WHITE
	_enter_area(BEDROOM)
	# The room in the low light of a lamp.
	var dim := CanvasModulate.new()
	dim.name = "SleepoverDim"
	dim.color = Color(0.8, 0.76, 0.92)
	add_child(dim)
	var steps := create_tween()
	steps.tween_interval(1.2)
	steps.tween_callback(func() -> void:
		_movie_say(0, "On est dans ta chambre ! C'est ben beau, tes lumières !")
		Sfx.play("chime", _charlotte.position))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		_say(_charlotte, "Qu'est-ce qu'on fait en premier ?", 300.0, 2.4)
		_sleepover_menu())


# What to do, over and over, until it is time to sleep.
func _sleepover_menu() -> void:
	_control.enabled = false
	var choices: Array = [
		{"text": "Des histoires à la lampe de poche", "note": "lire un livre ensemble", "color": Color("#FFE27A")},
		{"text": "Un spectacle d'ombres", "note": "des marionnettes sur le mur", "color": Color("#B6E3B0")},
		{"text": "Une bataille d'oreillers !", "note": "attention aux plumes", "color": Color("#F7B6D2")},
		{"text": "Dodo, on éteint la lumière", "note": "bonne nuit !", "color": Color("#9DC8F0")}]
	var card := ChoiceCard.ask(self, "Qu'est-ce qu'on fait ?", choices)
	card.chose.connect(func(i: int) -> void:
		if i == 0:
			_sleepover_story()
		elif i == 1:
			_sleepover_shadows()
		elif i == 2:
			_sleepover_pillows()
		else:
			_sleepover_sleep())


func _sleepover_story() -> void:
	var reader := BookReader.new()
	reader.start_book = randi() % BookReader.BOOKS.size()
	reader.tree_exited.connect(func() -> void:
		if not is_inside_tree():
			return
		_movie_say(0, "Oh, encore ! J'adore cette histoire-là.")
		var more := create_tween()
		more.tween_interval(2.6)
		more.tween_callback(_sleepover_menu))
	add_child(reader)


func _sleepover_shadows() -> void:
	var picked: Array = Sleepover.SHADOWS[_shows_done % Sleepover.SHADOWS.size()]
	_shows_done += 1
	_shadow = Sleepover.ShadowShow.new()
	_shadow.kind = str(picked[0])
	_shadow.position = Vector2(BEDROOM.x + 1000.0, 360.0)
	_shadow.z_index = 3
	add_child(_shadow)
	_say(_charlotte, "Regardez le mur !", 300.0, 1.8)
	var steps := create_tween()
	steps.tween_interval(3.6)
	steps.tween_callback(func() -> void: _movie_say(0, str(picked[1])))
	steps.tween_interval(2.8)
	steps.tween_callback(func() -> void:
		_say(_charlotte, str(picked[2]), 300.0, 2.6)
		for who: Character in [_charlotte] + _movie_twins:
			who.express("laugh", 2.0))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		if _shadow:
			_shadow.queue_free()
			_shadow = null
		_sleepover_menu())


# Pillows fly across the room, feathers float down, everybody laughs.
func _sleepover_pillows() -> void:
	var everyone: Array[Character] = [_charlotte]
	everyone.append_array(_movie_twins)
	var steps := create_tween()
	for k in 7:
		steps.tween_callback(func() -> void:
			var from: Character = everyone[k % everyone.size()]
			var to: Character = everyone[(k + 1 + (k / everyone.size())) % everyone.size()]
			_throw_pillow(from.position + Vector2(0, -90), to.position + Vector2(0, -90))
			from.express("grin", 1.2)
			Sfx.play("swoosh", from.position, -4.0, 1.0 + (k % 3) * 0.1))
		steps.tween_interval(0.45)
	steps.tween_callback(func() -> void:
		for who: Character in everyone:
			who.express("laugh", 2.4)
		_say(_charlotte, "Haha ! J'en peux plus !", 300.0, 2.2)
		Sfx.play("chime", _charlotte.position, -6.0))
	steps.tween_interval(2.6)
	steps.tween_callback(_sleepover_menu)


func _throw_pillow(from: Vector2, to: Vector2) -> void:
	var pillow := Polygon2D.new()
	pillow.polygon = PackedVector2Array([Vector2(-22, -12), Vector2(22, -13), Vector2(24, 12), Vector2(-24, 13)])
	pillow.color = Color("#FFFDF8")
	pillow.z_index = 8
	pillow.position = from
	add_child(pillow)
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		pillow.position = from.lerp(to, u) + Vector2(0, -sin(u * PI) * 70.0)
		pillow.rotation = u * 9.0, 0.0, 1.0, 0.5)
	tw.tween_callback(func() -> void:
		for f in 5:
			_feather(to + Vector2(randf_range(-20, 20), randf_range(-30, 0)))
		pillow.queue_free())


func _feather(at: Vector2) -> void:
	var f := Polygon2D.new()
	f.polygon = PackedVector2Array([Vector2(0, -6), Vector2(3, 0), Vector2(0, 6), Vector2(-3, 0)])
	f.color = Color("#FFFFFF")
	f.position = at
	f.z_index = 8
	add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "position", at + Vector2(randf_range(-40, 40), 90.0), randf_range(1.4, 2.2))
	tw.parallel().tween_property(f, "rotation", randf_range(-4.0, 4.0), 1.8)
	tw.parallel().tween_property(f, "modulate:a", 0.0, 1.8)
	tw.tween_callback(f.queue_free)


# Maman says goodnight from the door, everybody whispers a bit, the light goes out and the night begins.
func _sleepover_sleep() -> void:
	_control.enabled = false
	_mom.position.x = BEDROOM_DOOR_X - 90.0
	_mom.facing = -1
	_mom_routine.pause(40.0, _mom.position.x - 200.0)
	_mom.express("happy", 3.0)
	_say(_mom, "Allez, au dodo, les amis !\nBonne nuit, tout le monde.", 380.0, 3.0)
	var steps := create_tween()
	steps.tween_interval(3.4)
	steps.tween_callback(func() -> void:
		for who: Character in [_charlotte] + _movie_twins:
			_say(who, "Bonne nuit !", 250.0, 1.6))
	steps.tween_interval(2.2)
	var whisper_who: Array = [_movie_twins[0], _charlotte, _movie_twins[0], _charlotte] if not _movie_twins.is_empty() else []
	for k in whisper_who.size():
		steps.tween_callback(func() -> void: _say(whisper_who[k], Sleepover.WHISPERS[k], 260.0, 2.2))
		steps.tween_interval(2.4)
	steps.tween_callback(func() -> void:
		if _camp:
			_camp.asleep = true
			_camp.queue_redraw()
		for sister in _movie_twins:
			sister.visible = false
		_go_to_sleep())


# The morning after: they wake up in the room, Maman calls them for breakfast, then they thank her and go home.
func _sleepover_morning() -> void:
	_sleepover = false
	if _camp:
		_camp.asleep = false
		_camp.queue_redraw()
	var dim := get_node_or_null("SleepoverDim")
	if dim:
		dim.queue_free()
	for k in _movie_twins.size():
		var friend: Character = _movie_twins[k]
		friend.visible = true
		friend.position = Vector2(BEDROOM.x + 560.0 + k * 150.0, FEET_Y)
		friend.sitting = false
		friend.sit_on_ground = false
		friend.facing = -1
	_charlotte.sitting = false
	_charlotte.sit_on_ground = false
	_control.enabled = false
	var steps := create_tween()
	steps.tween_interval(1.4)
	for k in Sleepover.MORNING.size():
		steps.tween_callback(func() -> void:
			if k == 2:
				_mom.position.x = BEDROOM_DOOR_X - 90.0
				_mom.facing = -1
				_say(_mom, "Déjeuner ! J'ai fait des crêpes !", 380.0, 2.6)
			elif k == 0:
				_movie_say(0, Sleepover.MORNING[0])
			else:
				_say(_charlotte, Sleepover.MORNING[1], 300.0, 2.6))
		steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		_treat(InteriorArt.snack("apple"), "Un bon déjeuner avec ses amis !", 0.8)
		Sfx.play("miam", _charlotte.position))
	steps.tween_interval(3.0)
	for k in _movie_twins.size():
		steps.tween_callback(func() -> void:
			var friend: Character = _movie_twins[k]
			friend.express("happy", 2.4)
			_say(friend, Sleepover.GOODBYE[k % Sleepover.GOODBYE.size()], 280.0, 2.6))
		steps.tween_interval(2.8)
	steps.tween_callback(func() -> void: Transition.through_black(self, _sleepover_end, 0.7))


func _sleepover_end() -> void:
	for sister in _movie_twins:
		sister.queue_free()
	_movie_twins.clear()
	if _camp:
		_camp.queue_free()
		_camp = null
	# Her own clothes back (the pyjamas were only lent), and her morning place.
	_charlotte.set_look(CharacterLook.charlotte())
	_charlotte.z_index = 0
	_charlotte.position.x = BEDROOM.x + 840.0
	_charlotte.fidgets = true
	Cinema.clear()
	_control.enabled = true
	_say(_charlotte, "Quelle soirée pyjama !", 300.0)
	Notebook.announce("step", "Soirée pyjama réussie ! Tes amis sont rentrés chez eux.", Cinema.HEADING)


# A night-blue veil over the hallway, under the TV (so its picture and glow stay bright) and over the furniture.
func _movie_dark() -> Polygon2D:
	var dark := Polygon2D.new()
	dark.polygon = PackedVector2Array([Vector2(VESTIBULE_END, 0), Vector2(HALL.y, 0), Vector2(HALL.y, VIEW.y), Vector2(VESTIBULE_END, VIEW.y)])
	dark.color = Color(0.03, 0.03, 0.12, 0.5)
	add_child(dark)
	move_child(dark, _tv.glow.get_index())
	return dark


func _movie_say(who: int, text: String) -> void:
	if who < 0:
		_charlotte.express("talk", 1.8)
		_say(_charlotte, text, 230.0, Twins.LINE_SECONDS)
		if text.contains("bonbons"):
			_charlotte.express("yum", 2.4)
			Sfx.play("miam", _charlotte.position)
		return
	var sister := _movie_twins[mini(who, _movie_twins.size() - 1)]
	sister.express("talk", 1.8)
	_say(sister, text, 250.0, Twins.LINE_SECONDS)
	if text.contains("chips"):
		Sfx.play("pop", sister.position)


# The blanket and three cushions on the floor in front of the TV, and (once the film is on) the bowl of snacks between them.
class _Nest:
	extends Node2D
	var bowl := false
	## How many sit on it, Charlotte included (2 to 5): one cushion each.
	var people := 3
	var dark: Polygon2D
	var lights: Array = []

	func _draw() -> void:
		# A plaid blanket, its near edge with a fringe.
		var blanket := PackedVector2Array([Vector2(-350, -14), Vector2(270, -16), Vector2(296, 22), Vector2(-368, 24)])
		draw_colored_polygon(blanket, Color("#C8445A"))
		for i in 13:
			var x := -340.0 + i * 50.0
			draw_line(Vector2(x, -14), Vector2(x - 6.0, 23), Color("#E9D8B4", 0.55), 5.0)
		for y in [-4.0, 10.0]:
			draw_line(Vector2(-355, y), Vector2(282, y), Color("#E9D8B4", 0.45), 4.0)
		draw_polyline(PackedVector2Array([Vector2(-350, -14), Vector2(270, -16), Vector2(296, 22), Vector2(-368, 24), Vector2(-350, -14)]), Color("#8E2A3A"), 2.0, true)
		for i in 42:
			var x := -364.0 + i * 15.8
			draw_line(Vector2(x, 24), Vector2(x - 1.0, 31), Color("#E9D8B4"), 2.0)
		# The cushions where they sit (MOVIE_SEATS, from the nest's middle at x 2648).
		var cushions := [[-103.0, Color("#F2A7C9")], [122.0, Color("#FFD23F")], [-203.0, Color("#7CCBC4")], [-303.0, Color("#C084FC")], [222.0, Color("#FF8A3D")]]
		for k in mini(people, cushions.size()):
			_cushion(Vector2(cushions[k][0], 0.0), cushions[k][1])
		if bowl:
			# The big bowl with the chips and the candy.
			var at := Vector2(20, 4)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-34, -10), at + Vector2(34, -10), at + Vector2(22, 10), at + Vector2(-22, 10)]), Color("#4FA3E0"))
			for k in 9:
				var p := at + Vector2(-26.0 + k * 6.5, -12.0 - (k % 3) * 3.0)
				draw_circle(p, 5.0, Color("#F2C230") if k % 3 else Color("#E6B020"))
			for k in 4:
				draw_circle(at + Vector2(-18.0 + k * 12.0, -17.0 + (k % 2) * 4.0), 3.2, [Color("#E04F5F"), Color("#7CCB5A"), Color("#C084FC"), Color("#FF8A3D")][k])
			draw_line(at + Vector2(-34, -10), at + Vector2(34, -10), Color("#2D6FA8"), 2.5)

	func _cushion(c: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for k in 24:
			var a := TAU * k / 24.0
			var r := Vector2(46, 17) * (1.0 - 0.08 * absf(sin(a * 2.0)))
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y - 9.0))
		draw_colored_polygon(pts, color)
		draw_polyline(pts + PackedVector2Array([pts[0]]), color.darkened(0.35), 1.5, true)
		draw_circle(c + Vector2(0, -9), 2.5, color.darkened(0.3))


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
		# Once the quest is done the plants are only decoration: no click, no "elle a assez bu".
		spot.condition = func() -> bool: return not Quests.done("plants")
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
	_switchable(_switch_area(BEDROOM.x + 1300.0, 330.0), BEDROOM.x + 1310.0, [_bedroom_light], BEDROOM)


func _build_doors() -> void:
	# Front door (its glass door leaf inside the vestibule frame) → back to the street.
	# On a school morning (the quest "ecole", step 1) Maman is waiting there, and it leads to the schoolyard instead: at seven
	# Charlotte may not cross Dandurand by herself, so Maman walks her there.
	add_child(DoorSpot.make(Rect2(370, 204, 170, 396), func():
		_control.enabled = false
		Sfx.play("door")
		# An outing with Maman or Papa is waiting at this door, but her arms are full of another errand (the snowman's
		# buttons, a cat…): she doesn't go off with it. She goes out to finish her errand; the outing waits for her.
		if Carry.busy() and (School.step() == 1 or XmasTree.step() == 1 or Luge.step() == 1 or Party.step() == 1):
			Transition.street_x = NAN
			Transition.arrive = ""
			Transition.change_scene_saying(self, "res://scenes/main.tscn", "J'ai les mains pleines : je finis ça d'abord !")
			return
		if School.step() == 1:
			_off_to_school()
			return
		if XmasTree.step() == 1:
			# With Papa to the school's tree sale: across Dandurand, which she may not cross alone at seven.
			XmasTree.set_step(2)
			Transition.street_x = TreeSale.PAPA_X + 70.0
			Transition.change_scene_saying(self, XmasTree.YARD, "Papa t'amène à la vente de sapins de l'école…")
			return
		if Luge.step() == 1:
			# With Papa to the sliding hill of the Parc du Pélican, on Rue Masson: she may not cross alone at seven.
			Luge.set_step(2)
			Transition.street_x = Luge.PARK_START_X
			Transition.arrive = ""
			Transition.change_scene_saying(self, Luge.PARK, "Papa t'amène glisser au parc du Pélican, avec le traîneau…")
			return
		if Party.step() == 1:
			# Off to Rue Masson with Maman for Alyzée's present: she can't go there alone at seven.
			Party.set_step(2)
			Transition.street_x = Party.COUTU_X
			Transition.change_scene_saying(self, Party.COUTU, "Maman t'amène au Jean Coutu, sur la rue Masson…")
			return
		if School.available_today():
			_school_or_play()
			return
		# Out of her own front door she is at her own front door, whatever an outing left behind.
		Transition.street_x = NAN
		Transition.arrive = ""
		Transition.change_scene(self, "res://scenes/main.tscn")))
	add_child(QuestMark.make(Vector2(455.0, 180.0), func() -> bool:
		return (School.step() == 1 or Party.step() == 1 or XmasTree.step() == 1 or Luge.step() == 1) and _control.enabled))
	add_child(DoorSpot.make(Rect2(CHACHA_DOOR_X, 170, 150, 430), func(): _go_through(BEDROOM_DOOR_X - 40.0, BEDROOM, -1)))
	add_child(DoorSpot.make(Rect2(BEDROOM_DOOR_X, 170, 150, 430), func(): _go_through(CHACHA_DOOR_X + 75.0, HALL, 1)))
	# The kitchen's back door: out to the yard and the lane behind the house. Shut on Halloween night like every
	# other way into a lane — the evening happens on the four streets, not out the back in the dark.
	add_child(DoorSpot.make(Rect2(KITCHEN_START + 300.0, 250, 120, 350), func():
		if DebugMenu.blocked(Halloween.night()):
			_charlotte.express("worry", 2.2)
			Sfx.play("squeak", _charlotte.position)
			_say(_charlotte, StreetScene.DARK_LANE[randi() % StreetScene.DARK_LANE.size()], 280.0, 3.0)
			return
		_control.enabled = false
		Sfx.play("door")
		Transition.arrive = "ruelle_from_maison"
		Transition.change_scene(self, "res://scenes/ruelle.tscn"), KITCHEN_START + 300.0))
	# The fridge: a snack.
	add_child(DoorSpot.make(Rect2(KITCHEN_START + 4.0, 240, 104, 356), _open_fridge, KITCHEN_START + 140.0))
	# The drawing from the service de garde, waiting to go up on it.
	add_child(QuestMark.make(Vector2(KITCHEN_START + 56.0, 210.0), func() -> bool:
		return (Carry.has("drawing") or DrawingPad.has_pending() or Snowman.needs("carotte") and not Carry.busy() or Tooth.step() == 1) and _control.enabled))
	# Her bed: sleep until the next morning.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 360.0, 380, 448, 228), _bed_clicked, BEDROOM.x + 600.0))
	# Under it, her hiding place: the shoebox of junk food.
	# Only the part showing below the bed is clickable, or a click on the box would send her to bed.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 575.0, 606, 105, 30), _open_stash, BEDROOM.x + 640.0))
	# The book ledges: her books.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 960.0, 270, 136, 200), _open_books, BEDROOM.x + 1030.0))
	# Her desk: drawing paper and crayons, and the homework of the week.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 1110.0, 420, 300, 186), _use_desk, BEDROOM.x + 1200.0))
	# A "!" over the desk as long as this week's homework isn't finished.
	add_child(QuestMark.make(Vector2(BEDROOM.x + 1372.0, 398.0), func() -> bool:
		return not Homework.all_done()))
	# The dresser's drawers (under the terrarium): her wardrobe.
	add_child(DoorSpot.make(Rect2(BEDROOM.x + 40.0, 444, 276, 162), _open_wardrobe, BEDROOM.x + 180.0))


# A school morning (the quest "ecole" done, not been today): the front door asks where she is going.
func _school_or_play() -> void:
	var card := ChoiceCard.ask(self, "Où vas-tu ce matin ?", [
		{"text": "À l'école", "note": "Maman t'accompagne"},
		{"text": "Jouer dehors", "note": "Sur la 6e Avenue"},
	])
	card.chose.connect(func(i: int) -> void:
		if i == 0:
			# A new pupil is starting at school: the quest "emilia" begins on this morning.
			Quests.start(Emilia.QUEST)
			School.set_step(1)
			_off_to_school()
		elif i == 1:
			Transition.street_x = NAN
			Transition.arrive = ""
			Transition.change_scene(self, "res://scenes/main.tscn")
		else:
			_control.enabled = true)


func _off_to_school() -> void:
	Transition.change_scene_saying(self, School.YARD, "Maman t'accompagne à l'école…")


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
	if Carry.has("drawing") or DrawingPad.has_pending():
		_drawing_on_fridge()
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
	if Tooth.step() == 1:
		_bite_the_apple()
	elif Snowman.needs("carotte") and Carry.take(_charlotte, "bonhomme", "carotte"):
		# Not a snack this time: the snowman's nose.
		_say(_charlotte, "Une belle carotte pour le nez\ndu bonhomme de neige !", 200.0)
	else:
		var pick: Array = SNACKS[randi() % SNACKS.size()]
		_treat(InteriorArt.snack(pick[0]), "%s Miam !" % pick[1], 0.6)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(func():
		open.queue_free()
		cold.queue_free()
		_fridge_busy = false)


# The drawing she brought from the service de garde goes up on the fridge door, with a magnet; Maman loves it.
func _drawing_on_fridge() -> void:
	_charlotte.facing = -1
	_charlotte.pet(0.8, 0.0)
	if Carry.has("drawing"):
		Carry.put_down(_charlotte)
	DrawingPad.put_pending_on_fridge()
	_show_fridge_drawings()
	Sfx.play("pop", Vector2(KITCHEN_START + 60.0, 380.0))
	_charlotte.express("happy", 2.0)
	_say(_charlotte, "Voilà ! Mon dessin est sur le frigo !", 200.0)
	if _mom and is_instance_valid(_mom):
		var later := create_tween()
		later.tween_interval(2.6)
		later.tween_callback(func() -> void:
			_mom.express("happy", 2.0)
			_say(_mom, "Oh, qu'il est beau, ma Chachoue !\nMerci, mon cœur.", 280.0, 3.0))


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
	var christmas_eve := Christmas.step() == 4
	var new_year := NewYear.step() == 2
	var tooth_night := Tooth.step() == 2
	var good_night := "Bonne nuit, Chachoue…"
	if christmas_eve:
		good_night = "Bonne nuit… le père Noël s'en vient !"
	elif new_year:
		good_night = "Bonne nuit… pis bonne année !"
	elif tooth_night:
		good_night = "Bonne nuit… pis bonne visite, la fée des dents !"
	var words := _night_label(good_night, 40)
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
	if christmas_eve:
		# Santa's sleigh crossing the night sky, its reindeer, its bells (`SantaFlight`).
		tween.tween_interval(1.4)
		tween.tween_callback(func() -> void: night.add_child(SantaFlight.new()))
		tween.tween_interval(SantaFlight.DURATION)
	elif tooth_night:
		# The tooth fairy, a tinkle of bells.
		tween.tween_callback(func() -> void:
			night.add_child(Tooth.Fairy.new())
			for k in 4:
				get_tree().create_timer(k * 0.5).timeout.connect(func() -> void: Sfx.play("bell", Vector2.INF, -8.0, 1.4 + k * 0.1)))
		tween.tween_interval(4.2)
	tween.tween_property(dark, "color", Color(0.02, 0.02, 0.05, 1.0), 0.9)
	tween.parallel().tween_property(words, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(zs, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		GameState.flags.erase("hamster_fed")
		# A new day: school again (if she went today, or never came back from it).
		GameState.flags.erase(School.TODAY_DONE)
		if Quests.done(School.QUEST):
			GameState.flags.erase(School.STEP)
		var halloween_over: bool = Halloween.step() == 3 and GameState.flags.get("halloween_counted", false)
		# A storm blew all night (quest "souffleuse"): Papa will need a hand with the shovel.
		var storm := not halloween_over and Snowstorm.storm_tonight()
		if storm and Quests.start(Snowstorm.QUEST):
			Snowstorm.set_step(1)
		if halloween_over:
			_end_halloween()
			# Her two windows were drawn for last night, Halloween's own dark blue with its moon and its
			# bat: redraw them now that Halloween.night() is false again, or they'd go on showing it.
			if _salon_window:
				_salon_window.texture = InteriorArt.window(170.0, 300.0)
			if _bedroom_window:
				_bedroom_window.texture = InteriorArt.window(180.0, 300.0)
			# It snowed in the night: now it falls past the windows too.
			for snow in _window_snows:
				snow.visible = Season.is_winter()
		if christmas_eve:
			Christmas.set_step(5)
			_noel_under_tree()
			Notebook.announce("step", "C'est le matin de Noël ! Va voir sous le sapin.", Christmas.HEADING)
		words.text = "Le lendemain matin… il a neigé !" if halloween_over else ("Le lendemain matin… quelle tempête !" if storm else "Le lendemain matin…")
		if christmas_eve:
			words.text = "Le matin de Noël !"
		if tooth_night:
			Tooth.set_step(3)
			words.text = "Le lendemain matin… regarde sous ton oreiller !"
			Notebook.announce("step", "Regarde sous ton oreiller !", Tooth.HEADING)
		if new_year:
			NewYear.set_step(3)
			words.text = "Le jour de l'an !"
			Notebook.announce("step", "Bonne année ! Va dire ta bonne résolution à Maman ou à Papa.", NewYear.HEADING)
		words.position.y = 0.0
		moon.queue_free()
		_charlotte.position.x = BEDROOM.x + 840.0
		_charlotte.facing = -1
		_charlotte.visible = true
		Music.play(_music())
		if _sleepover:
			get_tree().create_timer(1.6).timeout.connect(_sleepover_morning)
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
			# The bag is emptied: she puts it down, her hand free again.
			for bag in _charlotte.get_children():
				if bag is CandyBag:
					bag.queue_free()
			_charlotte.hand_mode = ""
			# The whole haul goes into the shoebox under her bed, where everything sweet ends up.
			Stash.from_halloween()
			_say(_charlotte, "Je cache tout ça sous mon lit,\net je vais me coucher !", 300.0, 3.6)
			GameState.flags["halloween_counted"] = true)
		add_child(sheet))


## What she whispers as she helps herself from the box: never out loud, it is a secret.
const STASH_MIAM := {
	"wrapped": "Miam ! Un bon p'tit bonbon…",
	"lollipop": "Un suçon ! C'est très bon, ça.",
	"chocolate": "Du chocolat ! Chut, chut, chut…",
	"gum": "Une gomme, et personne ne le sait !",
	"chips": "Des chips ! Faut pas que j'fasse de bruit…",
}


# The shoebox under her bed: she pulls it out, helps herself to one thing, and pushes it back.
func _open_stash() -> void:
	if Stash.total() == 0:
		_charlotte.express("sad", 2.6)
		_say(_charlotte, Stash.EMPTY, 300.0, 3.4)
		return
	_control.enabled = false
	Sfx.play("swoosh", _charlotte.position)
	var box := StashBox.new()
	box.closed.connect(func(eaten: String) -> void:
		_control.enabled = true
		if eaten == "":
			return
		_charlotte.express("yum", 3.2)
		Sfx.play("miam", _charlotte.position)
		_say(_charlotte, str(STASH_MIAM.get(eaten, "Miam !")), 300.0, 3.0))
	add_child(box)


func _open_books() -> void:
	_control.enabled = false
	var books := BookReader.new()
	books.closed.connect(func(): _control.enabled = true)
	add_child(books)


# Her desk does two things, so it asks: her homework, or drawing.
func _use_desk() -> void:
	if Christmas.step() == 1 and not Carry.has("lettre"):
		_write_to_santa()
		return
	_control.enabled = false
	var left := Homework.exercises().size() - Homework.done_count()
	var note := "Tout est fait !" if left == 0 else "Il te reste %d question%s" % [left, "s" if left > 1 else ""]
	var card := ChoiceCard.ask(self, "Qu'est-ce que tu veux faire ?", [
		{"text": "Mes devoirs", "note": note, "color": Color("#B8E986")},
		{"text": "Dessiner", "note": "Du papier et des crayons", "color": Color("#8FCBF2")},
	])
	card.chose.connect(func(which: int) -> void:
		if which == 0:
			_open_homework()
		elif which == 1:
			_open_drawing_pad()
		else:
			_control.enabled = true)


func _open_homework() -> void:
	_control.enabled = false
	var pad := HomeworkPad.new()
	pad.closed.connect(func() -> void: _control.enabled = true)
	add_child(pad)


func _open_drawing_pad() -> void:
	_control.enabled = false
	var pad := DrawingPad.new()
	pad.closed.connect(func(drawing: Image):
		if drawing:
			DrawingPad.keep(drawing)
		# The drawer may have put one on the fridge without finishing this one.
		_show_fridge_drawings()
		_control.enabled = true)
	add_child(pad)


# Her kept drawings, newest last, on the fridge doors (kitchen fridge: x 3404–3508, doors split at y 370).
func _show_fridge_drawings() -> void:
	for child in _fridge_art.get_children():
		child.queue_free()
	# Eight places, four on each door (a little smaller than before); when all are taken, the oldest comes down (first in,
	# first out: `DrawingPad.KEEP`).
	var slots := [Vector2(KITCHEN_START + 10.0, 252.0), Vector2(KITCHEN_START + 56.0, 262.0), Vector2(KITCHEN_START + 12.0, 304.0), Vector2(KITCHEN_START + 58.0, 316.0),
		Vector2(KITCHEN_START + 12.0, 388.0), Vector2(KITCHEN_START + 58.0, 398.0), Vector2(KITCHEN_START + 10.0, 438.0), Vector2(KITCHEN_START + 56.0, 448.0)]
	var magnets := [Color("#E04F5F"), Color("#4FA3E0"), Color("#FFD23F"), Color("#7CCB5A"), Color("#B85AD8"), Color("#FF8A3D"), Color("#2EC4B6"), Color("#FF7AB0")]
	var tilts := [-5.0, 4.0, 3.0, -4.0, 4.0, -3.0, -5.0, 3.0]
	var drawings := DrawingPad.saved()
	for i in mini(drawings.size(), slots.size()):
		var art := Sprite2D.new()
		art.texture = ImageTexture.create_from_image(drawings[i])
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.centered = false
		art.scale = Vector2.ONE * 36.0 / DrawingPad.PAPER.x
		art.position = slots[i]
		art.rotation = deg_to_rad(tilts[i])
		_fridge_art.add_child(art)
		var magnet := Polygon2D.new()
		magnet.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(3.2, 3.2))
		magnet.color = magnets[i]
		magnet.position = slots[i] + Vector2(18, 1).rotated(art.rotation)
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
	_hide_glows_behind_people(delta)
	if _sofa_front:
		var taken := false
		for who: Character in [_charlotte, _mom, _dad]:
			if who and who.seated_amount() > 0.985 and who.sitting and who.seat_floor == _sofa_seat.floor_y and who.position.x >= _sofa_seat.span.x - 60.0 and who.position.x <= _sofa_seat.span.y + 60.0:
				taken = true
		_sofa_front.visible = taken


# The tree's bulb glows are drawn over the room, so they used to shine through Papa and Charlotte standing in front of
# the tree. A glow fades out while someone's body covers it, and comes back when they step away.
func _hide_glows_behind_people(delta: float) -> void:
	if _xmas_bulb_glows.is_empty():
		return
	var people: Array[Character] = []
	for child in get_children():
		if child is Character and child.visible:
			people.append(child)
	for glow: Sprite2D in _xmas_bulb_glows:
		if not is_instance_valid(glow):
			continue
		var covered := false
		for who in people:
			var half := 46.0 * who.scale.x / 0.5
			var height := 340.0 * who.scale.x / 0.5 * 0.5
			if absf(glow.position.x - who.position.x) < half and glow.position.y < who.position.y + 10.0 and glow.position.y > who.position.y - height:
				covered = true
				break
		glow.modulate.a = move_toward(glow.modulate.a, 0.0 if covered else 1.0, delta * 8.0)


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
	_salon_window = _put(InteriorArt.window(170.0, 300.0), 1580.0, 470.0, 1.0, "wall")
	_window_snows.append(_window_snow(_salon_window, 170.0, 300.0))
	_daylight(Vector2(1580.0, 170.0), 170.0, 0.12)
	_plant("fenetre", "pothos", 1590.0, 606.0, 0.5)
	_plate(1780.0, 330.0, false)
	_put(InteriorArt.dining_table(), 1780.0, 606.0, 0.85, "floor")
	_salon_pendant = _pendant(1984.0, 310.0)
	_put(InteriorArt.black_shelf(), 2110.0, WALL_BASE, 0.7, "floor")
	_crafts_art = Node2D.new()
	add_child(_crafts_art)
	_show_crafts()
	if XmasTree.in_salon():
		_build_xmas_tree()


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
	_bedroom_window = _put(InteriorArt.window(180.0, 300.0), x + 90.0, 420.0, 1.0, "wall")
	_window_snows.append(_window_snow(_bedroom_window, 180.0, 300.0))
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
	_put(InteriorArt.wall_clock(true), x + 1300.0, 260.0, 0.8, "wall")
	# A baby mobile over the bed, turning gently.
	var mobile := _put(InteriorArt.mobile(), x + 540.0, 270.0, 0.8)
	mobile.centered = true
	mobile.offset = Vector2(45.0, 0.0)
	mobile.position = Vector2(x + 540.0 + 36.0, CEILING + 6.0)
	var sway := create_tween().set_loops()
	sway.tween_property(mobile, "rotation", 0.06, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(mobile, "rotation", -0.06, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_plant("chambre", "lily", x + 272.0, 606.0, 0.5)
	_put(InteriorArt.bed(), x + 360.0, 608.0, 0.8, "floor")
	# Her capybara plush from Christmas, sitting on her bed by the pillow.
	if Christmas.has_plush():
		_put(Christmas.capybara_plush(), x + 610.0, 512.0, 0.85)
	# Her hiding place: the shoebox of junk food, half pulled out from under the bed (it laps over the bed's skirt,
	# which is what says "under there"), and a little in the shade.
	_put(InteriorArt.stash_box(), x + 575.0, 634.0, 0.7, "floor").modulate = Color(0.86, 0.82, 0.84)
	_put(InteriorArt.kid_table(), x + 830.0, 612.0, 0.75, "floor")
	_put(InteriorArt.book_ledges(), x + 960.0, 470.0, 0.8, "wall")
	_put(InteriorArt.fluffy_chair(), x + 960.0, 606.0, 0.8, "floor")
	_put(InteriorArt.strawberry_poster(), x + 1130.0, 300.0, 0.8, "wall")
	_plate(x + 1300.0, 330.0, false)
	_put(InteriorArt.desk(), x + 1110.0, 606.0, 0.85, "floor")
	_put(InteriorArt.homework_book(), x + 1326.0, 471.0, 0.68)
	_put(InteriorArt.laundry_basket(), x + 1300.0, 618.0, 0.8, "floor")
	_put(InteriorArt.plushies(), x + 770.0, 626.0, 0.8, "floor")
	_put(InteriorArt.panel_door(), BEDROOM_DOOR_X, WALL_BASE)
	_candle(Vector2(x + 30.0 + 262.0 * 0.85, 606.0 - 240.0 * 0.85), 80.0)
	# No more fairy lights or bunting (Julien): a ceiling light, which her wall switch turns on and off.
	_bedroom_light = _ceiling_light(x + 820.0)


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
	_tv = screen
