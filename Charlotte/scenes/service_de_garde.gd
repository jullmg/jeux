extends Interior
# The school's service de garde, after class (a school day's step 4, world/school.gd): a big bright room in the basement under
# a paper garland, a rainbow painted on the wall. Left to right: the door Papa comes in by, the coat hooks, the craft table,
# the block corner, the snack table with Jade the educator, and the games table where Alyzée waits. Each thing she does there is
# a little moment (a craft of the season, a tower that grows and tumbles, a snack, a game with Alyzée). Once she has done
# something (or after a while) Papa comes to pick her up; clicking him, she tells him about her day (on the first day, her
# new friend: the quest is done) and "Papa te ramène à la maison…".

const ROOM := Vector2(0.0, 2600.0)
const DOOR_X := 110.0
const CRAFT_X := 640.0
const BLOCKS_X := 1180.0
const SNACK_X := 1540.0
const JADE_X := 1860.0
const GAME_X := 2060.0
const ALYZEE_X := 2330.0
## Papa comes this long after she has done her first thing, or after `PAPA_LATEST` anyway.
const PAPA_AFTER := 5.0
const PAPA_LATEST := 40.0
const JADE_LINES := ["Bienvenue au service de garde, Chachoue !", "On se lave les mains avant la collation !",
	"On range les blocs quand on a fini, OK ?", "Ton papa va arriver bientôt."]
const ALYZEE_GAME := [
	[0, "On joue aux serpents et échelles ?"],
	[-1, "Oui ! Moi, je prends le pion bleu."],
	[0, "Six ! Je monte l'échelle !"],
	[-1, "Ah non ! Moi, je glisse sur le serpent…"],
	[0, "Hi hi ! On en refait une demain ?"],
]
const KID_LINES := [["Regarde mon bricolage !", "J'ai mis ben trop de colle…"], ["On fait la plus grande tour du monde !"],
	["Les pommes, c'est ma collation préférée !"]]

var _jade: Character
var _alyzee: Character
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
	hello.tween_callback(_jade_says.bind(JADE_LINES[0]))


func _music() -> Array:
	return ["ecole", "house", "street_" + Season.current, "street"]


func room_name() -> String:
	return "Le service de garde"


func _process(delta: float) -> void:
	super(delta)
	if _papa_here:
		return
	_wait += delta
	if _did and _wait > PAPA_AFTER or _wait > PAPA_LATEST:
		_papa_arrives()


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
	_jade.look = _jade_look()
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


## Jade, the educator: young, auburn hair in a ponytail, a teal hoodie, jeans, sneakers.
static func _jade_look() -> CharacterLook:
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#F3D3BC")
	look.hair_style = "ponytail"
	look.hair_color = Color("#8A3B1E")
	look.eye_color = Color("#3F9B45")
	look.lashes = true
	look.freckles = true
	look.mouth = "open_smile"
	look.outfit = "hoodie"
	look.outfit_color = Color("#1FB5C4")
	look.accent_color = Color("#FFD23F")
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#4A6FA5")
	look.shoes = "sneaker"
	look.shoe_color = Color("#F4F1EA")
	return look


func _build_spots() -> void:
	add_child(DoorSpot.make(Rect2(CRAFT_X - 150.0, 540.0, 300.0, 130.0), _make_craft, CRAFT_X - 60.0))
	add_child(DoorSpot.make(Rect2(BLOCKS_X - 85.0, 420.0, 170.0, 250.0), _build_tower, BLOCKS_X - 120.0))
	add_child(DoorSpot.make(Rect2(SNACK_X - 120.0, 520.0, 240.0, 150.0), _have_snack, SNACK_X - 40.0))
	add_child(DoorSpot.make(Rect2(GAME_X - 100.0, 550.0, 200.0, 120.0), _play_game, GAME_X - 140.0))
	add_child(DoorSpot.make(Rect2(ALYZEE_X - 55.0, 500.0, 110.0, 170.0), _play_game, ALYZEE_X - 120.0))
	add_child(DoorSpot.make(Rect2(JADE_X - 55.0, 380.0, 110.0, 290.0), func() -> void:
		_jade_line += 1
		_jade_says(JADE_LINES[_jade_line % JADE_LINES.size()]), JADE_X - 110.0))
	for i in _kids.size():
		var kid := _kids[i]
		add_child(DoorSpot.make(Rect2(kid.position.x - 50.0, FEET_Y - 170.0, 100.0, 170.0), func() -> void:
			var lines: Array = KID_LINES[i]
			_say(kid, lines[randi() % lines.size()], 175.0), kid.position.x - 100.0))
	add_child(DoorSpot.make(Rect2(DOOR_X - 70.0, 330.0, 140.0, 280.0), func() -> void:
		if not _papa_here:
			_say(_charlotte, "J'attends Papa.\nIl va venir me chercher !", 200.0)
		, DOOR_X + 80.0))
	add_child(QuestMark.make(Vector2(ALYZEE_X, FEET_Y - 190.0), func() -> bool: return not _did and not _papa_here))


func _jade_says(text: String) -> void:
	_say(_jade, text, 290.0, 2.6)


func _alyzee_says(text: String) -> void:
	_say(_alyzee, text, 175.0, 2.2)


# ── What she does ───────────────────────────────────────────────

func _make_craft() -> void:
	if _busy:
		return
	_did = true
	_charlotte.facing = 1
	_charlotte.pet(1.2, 0.0)
	var words := {"winter": "J'ai fait un flocon en papier !", "autumn": "J'ai fait une feuille d'automne !",
		"spring": "J'ai fait une tulipe en papier !"}
	_treat(ClassArt.craft(), str(words.get(Season.current, "J'ai fait un beau soleil !")), 1.0)


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
	if School.first_day():
		lines = [[_charlotte, "Papa ! J'ai une nouvelle amie !\nElle s'appelle Alyzée !"],
			[_papa, "Une nouvelle amie ? Wow !\nBravo, ma grande !"]]
	else:
		var stickers := int(GameState.flags.get(School.STICKERS, 0))
		lines = [[_charlotte, "Madame Nadia m'a donné un autocollant !\nJ'en ai %d, astheure !" % stickers],
			[_papa, "T'es ben bonne, ma Chachoue !"]]
	var talk := create_tween()
	for line: Array in lines:
		talk.tween_callback(func() -> void: _say(line[0], line[1], 300.0 if line[0] == _papa else 200.0, 2.8))
		talk.tween_interval(Bubble.reading_time(line[1], 2.8) + 0.2)
	# The star in her notebook comes now, while the room is still in view.
	talk.tween_callback(func() -> void:
		if School.first_day():
			Quests.complete(School.QUEST)
		_alyzee.facing = -1
		_alyzee_says("Bye, Chachoue ! À demain !"))
	talk.tween_interval(3.4)
	talk.tween_callback(func() -> void:
		School.end_day()
		Transition.inside_x = School.HOME_X
		Transition.change_scene_saying(self, School.HOME, "Papa te ramène à la maison…", 1.6))
