extends Interior
# The school's service de garde, after class (a school day's step 4, world/school.gd): a big bright room in the basement under
# a paper garland, a rainbow painted on the wall. Left to right: the door Papa comes in by, the coat hooks, the craft table,
# the block corner, the snack table with Jade the educator, and the games table where Alyzée waits. Each thing she does there is
# a little moment (a craft of the season, a tower that grows and tumbles, a snack, a game with Alyzée). Every day she has a
# drawing to make for her parents first (Julien): Jade asks for it, the craft table opens the drawing pad, and she carries
# the drawing home (`Carry` "drawing", `DrawingPad.pending`), where it goes up on the fridge. Papa comes once it is done; she
# shows it to him and tells him about her day (on the first day, her new friend: the quest is done), and "Papa te ramène à
# la maison…".

const ROOM := Vector2(0.0, 2600.0)
const DOOR_X := 110.0
const CRAFT_X := 640.0
const BLOCKS_X := 1180.0
const SNACK_X := 1540.0
const JADE_X := 1860.0
const GAME_X := 2060.0
const ALYZEE_X := 2330.0
## Emilia (quest "emilia"), between the snack table and Jade.
const EMILIA_X := 1700.0
## Papa comes this long after she has finished her drawing for her parents.
const PAPA_AFTER := 5.0
## Jade reminds her of the drawing every so often until it is done.
const REMIND_EVERY := 25.0
const JADE_ASKS := "Aujourd'hui, on fait un dessin\npour nos parents ! Va à la table de bricolage."
const JADE_REMINDS := ["N'oublie pas ton dessin pour ton papa\npis ta maman, Chachoue !", "La table de bricolage t'attend !\nTon dessin pour tes parents ?"]
## The sliding (`Sledding`, quest "glissade"): what Jade says when there is snow to slide on, as she lends the sled, and
## when they come back in.
const JADE_SLED := "Il a neigé en masse ! Avant le bricolage,\non sort glisser dans la cour. Viens me voir !"
const JADE_LENDS := "Tiens, un traîneau ! Mets ta tuque\npis sors par la porte, là-bas."
const JADE_BACK := "Ouf ! On a les joues ben rouges !\nAstheure, un dessin pour vos parents."
const JADE_LIKES := ["Wow ! C'est magnifique, Chachoue !\nTes parents vont capoter !", "Quel beau dessin !\nIl va être ben beau sur le frigo."]
const JADE_LINES := ["Bienvenue au service de garde, Chachoue !", "On se lave les mains avant la collation !",
	"On range les blocs quand on a fini, OK ?", "Ton papa va arriver bientôt."]
const ALYZEE_GAME := [
	[0, "On joue aux serpents et échelles ?"],
	[-1, "Oui ! Moi, je prends le pion bleu."],
	[0, "Six ! Je monte l'échelle !"],
	[-1, "Ah non ! Moi, je glisse sur le serpent…"],
	[0, "Hi hi ! On en refait une demain ?"],
]
## Emilia shares her mamá's concha (quest "emilia"): [who (0 Emilia, -1 Charlotte), what].
const EMILIA_SHARE := [
	[0, "Chachoue ! Ma mamá m'a donné des conchas\npour la collation. J'en ai une pour toi !"],
	[0, "C'est du pain sucré mexicain, avec une croûte\nde sucre rose qui ressemble à un coquillage."],
	[-1, "Wow ! Je peux goûter ?"],
]
const EMILIA_AFTER := [
	[0, "¿Te gusta ? Ça veut dire : t'aimes ça ?"],
	[-1, "Oui ! C'est super bon ! Gracias, Emilia !"],
	[0, "¡De nada ! Ça veut dire : y'a pas de quoi."],
]
const KID_LINES := [["Regarde mon bricolage !", "J'ai mis ben trop de colle…"], ["On fait la plus grande tour du monde !"],
	["Les pommes, c'est ma collation préférée !"]]

var _jade: Character
var _alyzee: Character
var _emilia: Character
var _papa: Character
var _kids: Array[Character] = []
var _blocks: Sprite2D
var _level := 3
var _did := false
var _wait := 0.0
var _papa_here := false
var _leaving := false
var _busy := false
var _jade_line := 0
## Her drawing for her parents is done (and in her arms), and when; how long since Jade last reminded her.
var _drew := false
var _drew_at := 0.0
var _reminded := 0.0
var _played := false


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": ROOM.x, "to": ROOM.y, "wall": Color("#FFF1C9"), "base": Color("#4A6FA5"),
		"wainscot": Color("#9CC9E8"), "wainscot_height": 140.0}]
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#F4F1EA"), Color("#BFD9EA")]
	shell.ceiling_style = "drop"
	shell.gleams = [700.0, 1500.0, 2300.0]
	add_child(shell)
	_build_room()
	_build_people()
	_spawn_charlotte(DOOR_X + 200.0)
	_build_spots()
	_enter_area(ROOM)
	_finish([[1000.0, "plushie"], [2000.0, "plant"]])
	var hello := create_tween()
	hello.tween_interval(1.0)
	if Sledding.just_back:
		# In from the sliding: cheeks red, now the drawing.
		Sledding.just_back = false
		hello.tween_callback(_jade_says.bind(JADE_BACK, 3.0))
	elif Sledding.can_start():
		hello.tween_callback(_jade_says.bind(JADE_LINES[0]))
		hello.tween_interval(3.0)
		hello.tween_callback(_jade_says.bind(JADE_SLED, 3.6))
		return
	else:
		hello.tween_callback(_jade_says.bind(JADE_LINES[0]))
	hello.tween_interval(3.0)
	hello.tween_callback(_jade_says.bind(JADE_ASKS, 3.6))


func _music() -> Array:
	return ["ecole", "house", "street_" + Season.current, "street"]


func room_name() -> String:
	return "Le service de garde"


func _process(delta: float) -> void:
	super(delta)
	if _papa_here:
		return
	_wait += delta
	if _drew:
		# On Emilia's day Papa waits until the concha has been shared (and a talk in progress is over).
		var ready := not Emilia.day() or (Emilia.shared() and not _busy)
		if _wait - _drew_at > PAPA_AFTER and ready:
			_papa_arrives()
	elif _wait - _reminded > REMIND_EVERY and _wait > 10.0 and _control.enabled and not _busy and Sledding.step() == 0 \
			and not Sledding.can_start():
		_reminded = _wait
		_jade_says(JADE_REMINDS[int(_wait) % JADE_REMINDS.size()], 3.0)


# ── The room ────────────────────────────────────────────────────

func _build_room() -> void:
	var art := RandomNumberGenerator.new()
	art.seed = 5511
	for wx in [430.0, 1700.0]:
		var window := _put(InteriorArt.window(160.0, 120.0), wx, 340.0, 1.0, "wall")
		_window_snow(window, 160.0, 120.0)
		_daylight(Vector2(wx, 220.0), 160.0, 0.12)
	_put(ClassArt.mural(560.0, 240.0), 820.0, 420.0, 1.0)
	_put(ClassArt.door("#9CC9E8"), DOOR_X - 75.0, 606.0, 0.85)
	_put(ClassArt.cubbies(300.0, art), 220.0, 606.0, 0.85, "floor")
	for gx in [0.0, 900.0, 1800.0]:
		_put(ClassArt.garland(900.0), gx, 110.0, 1.0)
	# The banner over the mural.
	var banner := ColorRect.new()
	banner.color = Color("#E04F5F")
	banner.size = Vector2(300, 40)
	banner.position = Vector2(950.0, 130.0)
	add_child(banner)
	var words := Label.new()
	words.text = "SERVICE DE GARDE"
	words.add_theme_font_size_override("font_size", 22)
	words.add_theme_color_override("font_color", Color.WHITE)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.size = banner.size
	words.position = banner.position
	add_child(words)
	for lx in [500.0, 1300.0, 2100.0]:
		_ceiling_light(lx)
	_put(ClassArt.cork_board(art), 1960.0, 400.0, 0.85, "wall")
	_put(ClassArt.toy_shelf(), 2380.0, 620.0, 0.85, "floor")
	_put(ClassArt.easel(art), 880.0, 650.0, 0.95, "floor")
	_put(ClassArt.craft_table(), CRAFT_X - 150.0, 660.0, 1.0, "floor")
	_blocks = _put(ClassArt.block_tower(_level), BLOCKS_X - 85.0, 668.0, 1.0)
	_put(ClassArt.snack_table(), SNACK_X - 120.0, 660.0, 1.0, "floor")
	_put(ClassArt.game_table(), GAME_X - 100.0, 664.0, 1.0, "floor")


func _build_people() -> void:
	var looks := RandomNumberGenerator.new()
	looks.seed = 5512
	var spots := [CRAFT_X + 110.0, BLOCKS_X + 110.0, SNACK_X - 150.0]
	for i in spots.size():
		var kid := Character.new()
		kid.look = School.indoors(CharacterLook.random(looks, "child"))
		kid.fidgets = true
		kid.scale = Vector2.ONE * CHAR_SCALE
		kid.position = Vector2(spots[i], FEET_Y - 8.0)
		kid.facing = -1 if i < 2 else 1
		add_child(kid)
		_kids.append(kid)
	_jade = Character.new()
	_jade.look = CharacterLook.jade()
	_jade.fidgets = true
	_jade.scale = Vector2.ONE * CHAR_SCALE * 1.15
	_jade.position = Vector2(JADE_X, FEET_Y - 10.0)
	_jade.facing = -1
	add_child(_jade)
	_alyzee = Character.new()
	_alyzee.look = CharacterLook.alyzee()
	_alyzee.fidgets = true
	_alyzee.scale = Vector2.ONE * CHAR_SCALE
	_alyzee.position = Vector2(ALYZEE_X, FEET_Y - 4.0)
	_alyzee.facing = -1
	add_child(_alyzee)
	if Emilia.day() or Emilia.met():
		_emilia = Character.new()
		_emilia.look = School.indoors(CharacterLook.emilia())
		_emilia.fidgets = true
		_emilia.scale = Vector2.ONE * CHAR_SCALE
		_emilia.position = Vector2(EMILIA_X, FEET_Y - 4.0)
		_emilia.facing = -1
		add_child(_emilia)


func _build_spots() -> void:
	add_child(DoorSpot.make(Rect2(CRAFT_X - 150.0, 540.0, 300.0, 130.0), _make_craft, CRAFT_X - 60.0))
	add_child(DoorSpot.make(Rect2(BLOCKS_X - 85.0, 420.0, 170.0, 250.0), _build_tower, BLOCKS_X - 120.0))
	add_child(DoorSpot.make(Rect2(SNACK_X - 120.0, 520.0, 240.0, 150.0), _have_snack, SNACK_X - 40.0))
	add_child(DoorSpot.make(Rect2(GAME_X - 100.0, 550.0, 200.0, 120.0), _play_game, GAME_X - 140.0))
	add_child(DoorSpot.make(Rect2(ALYZEE_X - 55.0, 500.0, 110.0, 170.0), _play_game, ALYZEE_X - 120.0))
	add_child(DoorSpot.make(Rect2(JADE_X - 55.0, 380.0, 110.0, 290.0), _talk_to_jade, JADE_X - 110.0))
	if _emilia:
		add_child(DoorSpot.make(Rect2(EMILIA_X - 55.0, 500.0, 110.0, 170.0), _talk_to_emilia, EMILIA_X - 120.0))
		add_child(QuestMark.make(Vector2(EMILIA_X, FEET_Y - 190.0), func() -> bool:
			return Emilia.day() and not Emilia.shared() and _control.enabled and not _busy))
	for i in _kids.size():
		var kid := _kids[i]
		add_child(DoorSpot.make(Rect2(kid.position.x - 50.0, FEET_Y - 170.0, 100.0, 170.0), func() -> void:
			var lines: Array = KID_LINES[i]
			_say(kid, lines[randi() % lines.size()], 175.0), kid.position.x - 100.0))
	add_child(DoorSpot.make(Rect2(DOOR_X - 70.0, 330.0, 140.0, 280.0), func() -> void:
		if Sledding.step() == 1:
			_out_to_slide()
		elif not _papa_here:
			_say(_charlotte, "J'attends Papa.\nIl va venir me chercher !", 200.0)
		, DOOR_X + 80.0))
	add_child(QuestMark.make(Vector2(CRAFT_X, 470.0), func() -> bool:
		return not _drew and _control.enabled and Sledding.step() == 0 and not Sledding.can_start()))
	add_child(QuestMark.make(Vector2(JADE_X, FEET_Y - 330.0), func() -> bool: return Sledding.can_start() and not _drew))
	add_child(QuestMark.make(Vector2(DOOR_X, 300.0), func() -> bool: return Sledding.step() == 1 and _control.enabled))
	add_child(QuestMark.make(Vector2(ALYZEE_X, FEET_Y - 190.0), func() -> bool: return _drew and not _played and not _papa_here))


func _talk_to_jade() -> void:
	if Sledding.can_start() and not _drew:
		_lend_sled()
	elif Sledding.step() == 1:
		_jade_says("La porte est là-bas, Chachoue !\nLes amis t'attendent dehors.")
	else:
		_jade_line += 1
		_jade_says(JADE_LINES[_jade_line % JADE_LINES.size()])


# Jade lends her a sled for the schoolyard's snow hill (quest "glissade").
func _lend_sled() -> void:
	if not Carry.take(_charlotte, "traineau"):
		_say(_charlotte, Carry.FULL_HANDS, 200.0)
		return
	Quests.start(Sledding.QUEST)
	Sledding.set_step(1)
	Sfx.play("pop", _charlotte.position + Vector2(0, -80))
	_jade.express("happy", 2.0)
	_charlotte.express("grin", 2.0)
	_jade_says(JADE_LENDS, 3.2)
	Notebook.announce("step", "Jade t'a prêté un traîneau ! Sors dans la cour.", Sledding.HEADING)


# Out through the garde's door to the schoolyard, sled in her arms.
func _out_to_slide() -> void:
	_control.enabled = false
	Sledding.set_step(2)
	Sfx.play("door")
	Transition.street_x = Sledding.YARD_START
	Transition.change_scene_saying(self, Sledding.YARD, "Le service de garde sort glisser dans la cour…", 1.4)


# Emilia: on the quest's day she shares a concha with her (and Papa waits for it); otherwise a line of hers.
func _talk_to_emilia() -> void:
	if _busy:
		return
	_emilia.facing = -1 if _charlotte.position.x < _emilia.position.x else 1
	if not Emilia.day() or Emilia.shared():
		_say(_emilia, Emilia.LINES[randi() % Emilia.LINES.size()], 175.0, 2.6)
		return
	_busy = true
	_did = true
	var steps := create_tween()
	_emilia_lines(steps, EMILIA_SHARE)
	steps.tween_callback(func() -> void:
		Sfx.play("pop", _charlotte.position + Vector2(0, -80))
		_treat(ClassArt.concha(), "Miam ! Une concha !", 0.6))
	steps.tween_interval(2.2)
	_emilia_lines(steps, EMILIA_AFTER)
	steps.tween_callback(func() -> void:
		GameState.flags[Emilia.SHARED] = true
		_emilia.express("happy", 2.0)
		_charlotte.express("happy", 2.0)
		Notebook.announce("step", "Emilia t'a fait goûter une concha ! Attends Papa pour lui raconter ta journée.", Emilia.HEADING)
		_busy = false)


func _emilia_lines(steps: Tween, lines: Array) -> void:
	for line: Array in lines:
		steps.tween_callback(func() -> void:
			if line[0] < 0:
				_say(_charlotte, line[1], 200.0, 2.4)
			else:
				_say(_emilia, line[1], 175.0, 2.4))
		steps.tween_interval(Bubble.reading_time(line[1], 2.4) + 0.2)


func _jade_says(text: String, seconds := 2.6) -> void:
	_say(_jade, text, 290.0, seconds)


func _alyzee_says(text: String) -> void:
	_say(_alyzee, text, 175.0, 2.2)


# ── What she does ───────────────────────────────────────────────

func _make_craft() -> void:
	if _busy:
		return
	if Sledding.step() == 1:
		_say(_charlotte, "On va glisser avant !\nLe dessin, ce sera après.", 200.0)
		return
	if not _drew:
		_draw_for_parents()
		return
	_did = true
	_charlotte.facing = 1
	_charlotte.pet(1.2, 0.0)
	var words := {"winter": "J'ai fait un flocon en papier !", "autumn": "J'ai fait une feuille d'automne !",
		"spring": "J'ai fait une tulipe en papier !"}
	_treat(ClassArt.craft(), str(words.get(Season.current, "J'ai fait un beau soleil !")), 1.0)


# The drawing pad, its button "Pour Papa et Maman !": the drawing is kept for home and she carries it in her arms.
func _draw_for_parents() -> void:
	_control.enabled = false
	_charlotte.facing = 1
	var pad := DrawingPad.new()
	pad.done_text = "Pour Papa et Maman !"
	pad.closed.connect(func(drawing: Image) -> void:
		_control.enabled = true
		if drawing == null:
			_say(_charlotte, "Je vais le finir tantôt…", 200.0)
			return
		DrawingPad.hold_pending(drawing)
		_drew = true
		_drew_at = _wait
		_did = true
		if not Carry.busy():
			Carry.take(_charlotte, "drawing")
		_charlotte.express("happy", 2.0)
		Sfx.play("chime")
		_jade_says(JADE_LIKES[randi() % JADE_LIKES.size()], 3.0))
	add_child(pad)


# The tower grows a block at each click; past six it tumbles down and she starts again.
func _build_tower() -> void:
	_did = true
	_charlotte.facing = 1
	_charlotte.pet(0.6, 0.6)
	_level += 1
	if _level > 6:
		_level = 1
		Sfx.play("swoosh", Vector2(BLOCKS_X, 600.0))
		_charlotte.express("surprised", 1.6)
		_say(_charlotte, "Oups ! Ça tombe !", 200.0)
	else:
		Sfx.play("pop", Vector2(BLOCKS_X, 600.0))
		if _level == 6:
			_say(_charlotte, "La plus grande tour du monde !", 200.0)
	_blocks.texture = ClassArt.block_tower(_level)
	_blocks.position.y = 668.0 - _blocks.texture.get_height()


func _have_snack() -> void:
	_did = true
	_jade_says("C'est l'heure de la collation !")
	_treat(ClassArt.snack(), "Miam ! Des pommes pis des craquelins.", 0.6)


func _play_game() -> void:
	if _busy:
		return
	_busy = true
	_did = true
	_played = true
	_alyzee.facing = -1 if _charlotte.position.x < _alyzee.position.x else 1
	var steps := create_tween()
	for line: Array in ALYZEE_GAME:
		steps.tween_callback(func() -> void:
			if line[0] < 0:
				_say(_charlotte, line[1], 200.0, 2.0)
			else:
				_alyzee_says(line[1]))
		steps.tween_interval(Bubble.reading_time(line[1], 2.0) + 0.1)
		if line[1].begins_with("Six"):
			steps.tween_callback(Sfx.play.bind("click", Vector2(GAME_X, 600.0)))
	steps.tween_callback(func() -> void:
		_alyzee.express("laugh", 1.8)
		_charlotte.express("laugh", 1.8)
		_busy = false)


# ── Papa ────────────────────────────────────────────────────────

func _papa_arrives() -> void:
	_papa_here = true
	_papa = Character.new()
	var look := CharacterLook.dad()
	# He comes in from outside: his coat on in winter.
	Season.dress_for_weather(look)
	_papa.look = look
	_papa.scale = Vector2.ONE * CHAR_SCALE * 1.18
	_papa.position = Vector2(DOOR_X, FEET_Y - 10.0)
	_papa.facing = 1
	_papa.modulate.a = 0.0
	add_child(_papa)
	Sfx.play("door", _papa.position)
	var to := clampf(_charlotte.position.x - 150.0, DOOR_X + 120.0, ROOM.y - 200.0)
	var walk := create_tween()
	walk.tween_property(_papa, "modulate:a", 1.0, 0.4)
	walk.tween_callback(func() -> void: _papa.is_walking = true)
	walk.tween_property(_papa, "position:x", to, absf(to - DOOR_X) / 170.0)
	walk.tween_callback(func() -> void:
		_papa.is_walking = false
		_papa.facing = 1 if _charlotte.position.x > _papa.position.x else -1
		_papa.express("happy", 2.0)
		_say(_papa, "Coucou, Chachoue ! C'est Papa !\nOn rentre à la maison ?", 300.0, 3.2)
		add_child(DoorSpot.make(Rect2(_papa.position.x - 60.0, 330.0, 120.0, 340.0), _go_home_with_papa, _papa.position.x + 110.0))
		add_child(QuestMark.make(_papa.position + Vector2(0, -330), func() -> bool: return not _leaving)))


# She tells him about her day (her new friend, on the first day: the quest is done); Alyzée waves; home.
func _go_home_with_papa() -> void:
	if _leaving or _busy:
		return
	_leaving = true
	_control.enabled = false
	_papa.facing = 1 if _charlotte.position.x > _papa.position.x else -1
	var lines: Array = []
	if Carry.has("drawing"):
		lines = [[_charlotte, "Regarde, Papa ! J'ai fait un dessin\npour toi pis Maman !"],
			[_papa, "Il est magnifique ! On va le mettre\nsur le frigo en arrivant."]]
	if School.first_day():
		lines += [[_charlotte, "Papa ! J'ai une nouvelle amie !\nElle s'appelle Alyzée !"],
			[_papa, "Une nouvelle amie ? Wow !\nBravo, ma grande !"]]
	elif Emilia.day():
		lines += [[_charlotte, "Papa ! Je me suis fait une amie : Emilia !\nSa mamá vient du Mexique !"],
			[_papa, "Une nouvelle amie ? Quelle belle journée !"],
			[_charlotte, "Elle m'a fait goûter une concha,\npis elle m'a appris « mariposa » !"],
			[_papa, "Une concha ? Ça a l'air délicieux !\nBravo, ma grande !"]]
	else:
		var stickers := int(GameState.flags.get(School.STICKERS, 0))
		lines += [[_charlotte, "Madame Nadia m'a donné un autocollant !\nJ'en ai %d, astheure !" % stickers],
			[_papa, "T'es ben bonne, ma Chachoue !"]]
	var talk := create_tween()
	for line: Array in lines:
		talk.tween_callback(func() -> void: _say(line[0], line[1], 300.0 if line[0] == _papa else 200.0, 2.8))
		talk.tween_interval(Bubble.reading_time(line[1], 2.8) + 0.2)
	# The star in her notebook comes now, while the room is still in view.
	talk.tween_callback(func() -> void:
		if School.first_day():
			Quests.complete(School.QUEST)
		elif Emilia.day():
			Quests.complete(Emilia.QUEST)
		_alyzee.facing = -1
		_alyzee_says("Bye, Chachoue ! À demain !")
		if _emilia:
			_emilia.facing = -1
			_say(_emilia, "¡Adiós, Chachoue ! À demain !", 175.0, 2.4))
	talk.tween_interval(3.4)
	talk.tween_callback(func() -> void:
		School.end_day()
		Transition.inside_x = School.HOME_X
		Transition.change_scene_saying(self, School.HOME, "Papa te ramène à la maison…", 1.6))
