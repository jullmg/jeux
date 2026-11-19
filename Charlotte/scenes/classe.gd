extends Interior
# Madame Nadia's class, at école Saint-Jean-de-Brébeuf (a school day's step 3, world/school.gd). Left to right: the door
# from the yard and the cubbies where the coats hang, the cork board of drawings, the windows, the pupils' desks in a row
# facing the board (Charlotte's beside Alyzée's), the board with today's date in chalk, Madame Nadia's desk, the Québec
# flag, the aquarium and the reading corner. The alphabet runs along the top of the wall.
# Charlotte sits at her desk and the lesson starts: Madame Nadia asks three questions at the board (`School.lesson`, read
# out by `Voice`, answered on a `ChoiceCard`), gives her a sticker, and at the bell the class goes down to the service de garde.
# Madame Nadia is invented (no photo): a woman in her forties, dark hair in a bun, round glasses, a mustard cardigan.

const ROOM := Vector2(0.0, 2900.0)
const DOOR_X := 70.0
## Where each pupil sits (x of the hips); Charlotte's and Alyzée's are the middle two.
const SEATS := [640.0, 880.0, 1120.0, 1360.0, 1600.0]
const MINE := 2
const HERS := 3
const SEAT_H := 50.0
const BOARD := Rect2(1780.0, 110.0, 560.0, 300.0)
const TEACHER_X := 2150.0
const TEACHER_LINES := ["Bon matin, Charlotte !", "N'oublie pas de lever la main, hein !", "As-tu bien dormi, ma belle ?",
	"On range son pupitre avant de partir !"]
const KID_LINES := [["Chut ! Madame Nadia va nous voir !", "J'ai oublié mon efface…"], ["Moi, j'aime les maths !", "Tu veux voir mon dessin ?"],
	["J'ai hâte à la récré !", "Mon crayon est tout cassé…"]]
const DAYS := ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
const MONTHS := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]

var _teacher: Character
var _alyzee: Character
var _kids: Array[Character] = []
var _seat: Seat
var _board_text: Label
var _lesson: Array = []
var _asked := 0
var _started := false
var _over := false
var _rng := RandomNumberGenerator.new()
var _teacher_line := 0


func _ready() -> void:
	_rng.randomize()
	var shell := RoomShell.new()
	shell.rooms = [{"from": ROOM.x, "to": ROOM.y, "wall": Color("#F3E9D2"), "base": Color("#6E4A2C"),
		"wainscot": Color("#A9C6B8"), "wainscot_height": 150.0}]
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#E8E2D2"), Color("#C9D3CC")]
	shell.ceiling_style = "drop"
	shell.gleams = [900.0, 1700.0, 2500.0]
	add_child(shell)
	_build_walls()
	_build_furniture()
	_build_people()
	_spawn_charlotte(DOOR_X + 160.0)
	_build_desks()
	_build_spots()
	_enter_area(ROOM)
	_finish([[300.0, "plant"], [2750.0, "plushie"]])
	_greet()


func _music() -> Array:
	return ["ecole", "house", "street_" + Season.current, "street"]


## The plate at the top of the screen (PlaceLabel).
func room_name() -> String:
	return "La classe de %s" % School.TEACHER


func _process(delta: float) -> void:
	super(delta)
	if not _started and _charlotte.is_seated() and _seat.who == _charlotte:
		_start_lesson()


# ── The room ────────────────────────────────────────────────────

func _build_walls() -> void:
	var art := RandomNumberGenerator.new()
	art.seed = 4411
	_put(ClassArt.door("#A9C6B8"), DOOR_X - 75.0, 606.0, 0.85)
	_put(ClassArt.cubbies(360.0, art), 200.0, 606.0, 0.9, "floor")
	_put(ClassArt.cork_board(art), 560.0, 330.0, 0.85, "wall")
	for wx in [860.0, 1260.0]:
		var window := _put(InteriorArt.window(170.0, 250.0), wx, 410.0, 1.0, "wall")
		_window_snow(window, 170.0, 250.0)
		_daylight(Vector2(wx, 160.0), 170.0, 0.16)
	_put(InteriorArt.wall_clock(), 2010.0, 100.0, 0.55, "wall")
	# The board, and what is written on it: today's date, then each question.
	_put(ClassArt.blackboard(BOARD.size.x, BOARD.size.y), BOARD.position.x, BOARD.end.y, 1.0, "wall")
	var now := Time.get_date_dict_from_system()
	var date := "%s %d %s" % [DAYS[int(now.weekday)], int(now.day), MONTHS[int(now.month) - 1]]
	_chalk(date.capitalize() if false else date[0].to_upper() + date.substr(1), Vector2(BOARD.get_center().x, BOARD.position.y + 44.0), 24)
	_board_text = _chalk("Bonjour, les amis !", Vector2(BOARD.get_center().x, BOARD.position.y + 140.0), 30)
	_alphabet()


# Words in chalk on the board.
func _chalk(text: String, center: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(BOARD.size.x - 60.0, 120.0)
	label.position = center - label.size / 2.0
	add_child(label)
	return label


# The alphabet along the top of the wall, a card per letter in turn of colour, capital and small.
func _alphabet() -> void:
	var colors := [Color("#E04F5F"), Color("#FFB42E"), Color("#3E8E5A"), Color("#4A6FA5"), Color("#7E57C2")]
	for i in 26:
		var x := 230.0 + i * 56.0
		var card := ColorRect.new()
		card.color = Color("#FFFDF6")
		card.size = Vector2(48, 40)
		card.position = Vector2(x, 46.0)
		add_child(card)
		var band := ColorRect.new()
		band.color = colors[i % colors.size()]
		band.size = Vector2(48, 6)
		band.position = card.position
		add_child(band)
		var letter := Label.new()
		var c := char(65 + i)
		letter.text = "%s%s" % [c, c.to_lower()]
		letter.add_theme_font_size_override("font_size", 20)
		letter.add_theme_color_override("font_color", colors[i % colors.size()].darkened(0.15))
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.size = Vector2(48, 34)
		letter.position = card.position + Vector2(0, 6)
		add_child(letter)


func _build_furniture() -> void:
	var art := RandomNumberGenerator.new()
	art.seed = 4412
	_put(ClassArt.teacher_desk(), 1860.0, 640.0, 1.0, "floor")
	_put(ClassArt.quebec_flag(), 2370.0, 610.0, 1.0)
	_put(ClassArt.aquarium(), 2440.0, 610.0, 0.95, "floor")
	var fish := _Fish.new()
	fish.tank = Rect2(2440.0 + 14.0 * 0.95, 610.0 - (230.0 - 24.0) * 0.95, (190.0 - 28.0) * 0.95, (230.0 - 150.0) * 0.95)
	add_child(fish)
	_put(ClassArt.bookcase(art), 2630.0, 640.0, 1.0, "floor")
	_put(InteriorArt.rug(), 2560.0, 700.0, 0.7)
	_put(ClassArt.beanbag("#F7A9C4"), 2740.0, 690.0, 1.0)
	_put(InteriorArt.house_plant("pothos", false), 2820.0, 610.0, 0.8, "floor")


# The pupils' chairs, then the pupils on them; the desks go on after Charlotte (drawn over their knees).
func _build_people() -> void:
	var looks := RandomNumberGenerator.new()
	looks.seed = 4413
	var chair_colors := ["#E04F5F", "#4A6FA5", "#FFB42E", "#3E8E5A", "#7E57C2"]
	for i in SEATS.size():
		_put(ClassArt.pupil_chair(chair_colors[i]), SEATS[i] - 46.0, FEET_Y + 2.0, 1.0)
	var k := 0
	for i in SEATS.size():
		if i == MINE:
			continue
		var look := CharacterLook.alyzee() if i == HERS else School.indoors(CharacterLook.random(looks, "child"))
		var kid := Character.new()
		kid.look = look
		kid.scale = Vector2.ONE * CHAR_SCALE
		kid.position = Vector2(SEATS[i], FEET_Y)
		add_child(kid)
		# Their seats are in the room too (or they leak at exit); an empty rect, so nobody can click them.
		var seat := Seat.make(Rect2(), Vector2(SEATS[i], SEATS[i]), SEAT_H, 1)
		add_child(seat)
		seat.sit(kid)
		if i == HERS:
			_alyzee = kid
		else:
			_kids.append(kid)
			add_child(DoorSpot.make(Rect2(SEATS[i] - 50.0, FEET_Y - 150.0, 100.0, 150.0), _kid_says.bind(kid, k), SEATS[i] - 110.0))
			k += 1
	_teacher = Character.new()
	_teacher.look = _nadia()
	_teacher.fidgets = true
	_teacher.scale = Vector2.ONE * CHAR_SCALE * 1.18
	_teacher.position = Vector2(TEACHER_X, FEET_Y - 10.0)
	_teacher.facing = -1
	add_child(_teacher)


func _build_desks() -> void:
	var art := RandomNumberGenerator.new()
	art.seed = 4414
	for i in SEATS.size():
		_put(ClassArt.pupil_desk(art), SEATS[i] + 14.0, FEET_Y + 4.0, 1.0)
	_seat = Seat.make(Rect2(SEATS[MINE] - 50.0, FEET_Y - 120.0, 120.0, 124.0), Vector2(SEATS[MINE], SEATS[MINE]), SEAT_H, 1)
	_seat.condition = func() -> bool: return not _started
	add_child(_seat)
	add_child(QuestMark.make(Vector2(SEATS[MINE], FEET_Y - 150.0), func() -> bool: return not _started and not _charlotte.sitting))


## Madame Nadia: dark hair in a bun, round glasses, warm brown eyes, a mustard cardigan over a navy dress, brown boots.
static func _nadia() -> CharacterLook:
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#E8BC98")
	look.hair_style = "bun"
	look.hair_color = Color("#3A2618")
	look.eye_color = Color("#6B4E2E")
	look.lashes = true
	look.mouth = "smile"
	look.glasses = "#8A4B2A"
	look.outfit = "cardigan"
	look.outfit_color = Color("#E0A526")
	look.accent_color = Color("#2E4A7A")
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "tights"
	look.legwear_color = Color("#2E3440")
	look.shoes = "boot"
	look.shoe_color = Color("#6D4C41")
	return look


func _build_spots() -> void:
	add_child(DoorSpot.make(Rect2(DOOR_X - 70.0, 300.0, 140.0, 300.0), func() -> void:
		if not _over:
			_say(_charlotte, "La classe va commencer !\nJe vais m'asseoir à mon pupitre.", 200.0)
		, DOOR_X + 60.0))
	add_child(DoorSpot.make(Rect2(TEACHER_X - 60.0, 330.0, 120.0, 340.0), func() -> void:
		if _started:
			return
		_teacher.facing = -1 if _charlotte.position.x < TEACHER_X else 1
		_teacher_says(TEACHER_LINES[_teacher_line % TEACHER_LINES.size()])
		_teacher_line += 1, TEACHER_X - 120.0))
	add_child(DoorSpot.make(Rect2(2440.0, 380.0, 180.0, 230.0), func() -> void:
		_say(_charlotte, "Coucou, les poissons !\nVous êtes ben beaux !", 200.0), 2420.0))
	add_child(DoorSpot.make(Rect2(SEATS[HERS] - 50.0, FEET_Y - 150.0, 100.0, 150.0), func() -> void:
		if not _started:
			_alyzee_says("Viens t'asseoir à côté de moi, Chachoue !"), SEATS[HERS] - 110.0))


func _teacher_says(text: String, seconds := 2.6) -> void:
	_say(_teacher, text, 300.0, seconds)


func _alyzee_says(text: String) -> void:
	_say(_alyzee, text, 175.0, 2.4)


func _kid_says(kid: Character, k: int) -> void:
	var lines: Array = KID_LINES[k % KID_LINES.size()]
	_say(kid, lines[randi() % lines.size()], 175.0, 2.4)


# ── The lesson ──────────────────────────────────────────────────

func _greet() -> void:
	var hello := create_tween()
	hello.tween_interval(1.0)
	if School.first_day():
		hello.tween_callback(func() -> void: _say(_charlotte, "Je range mon manteau dans mon casier !", 200.0))
		hello.tween_interval(2.6)
		hello.tween_callback(_teacher_says.bind("Bonjour, Charlotte ! Va t'asseoir\nà ton pupitre, à côté d'Alyzée.", 3.4))
	else:
		hello.tween_callback(_teacher_says.bind("Bon matin, Charlotte !\nAssieds-toi, on commence.", 3.0))


func _start_lesson() -> void:
	_started = true
	_control.enabled = false
	_lesson = School.lesson(_rng)
	_asked = 0
	var intro := create_tween()
	intro.tween_interval(0.8)
	if School.first_day():
		intro.tween_callback(_teacher_says.bind("Bonjour, la classe ! Aujourd'hui, on accueille\nune nouvelle amie : Alyzée !", 3.6))
		intro.tween_interval(4.2)
		intro.tween_callback(func() -> void:
			for kid in _kids:
				kid.express("happy", 2.0)
			_say(_kids[1], "Bonjour, Alyzée !", 175.0, 2.0))
		intro.tween_interval(2.4)
		intro.tween_callback(func() -> void:
			_alyzee.express("happy", 2.0)
			_alyzee_says("Merci !"))
		intro.tween_interval(2.0)
	intro.tween_callback(_teacher_says.bind("On commence ! Charlotte, tu veux répondre ?", 3.0))
	intro.tween_interval(3.2)
	intro.tween_callback(_ask)


func _ask() -> void:
	var q: Dictionary = _lesson[_asked]
	_board_text.text = q.ask
	_teacher.facing = -1
	_teacher_says(q.ask, 3.0)
	Voice.say(q.ask)
	var choices: Array = []
	for answer: String in q.answers:
		choices.append({"text": answer})
	var card := ChoiceCard.ask(self, q.ask, choices)
	card.chose.connect(_answered)


func _answered(i: int) -> void:
	if _asked >= _lesson.size():
		return
	var q: Dictionary = _lesson[_asked]
	var next := create_tween()
	if i == int(q.right):
		_charlotte.express("happy", 2.0)
		_teacher.express("happy", 2.0)
		Sfx.play("chime")
		_teacher_says(["Bravo, Charlotte ! C'est ça !", "Excellent !", "Oui ! Bien joué !"][_asked % 3], 2.2)
		_asked += 1
		next.tween_interval(2.6)
		next.tween_callback(_ask if _asked < _lesson.size() else _end_lesson)
	else:
		_charlotte.express("worry", 1.8)
		_teacher_says("Presque ! Essaie encore." if i >= 0 else "Prends ton temps, Charlotte.", 2.2)
		next.tween_interval(2.4)
		next.tween_callback(_ask_again)


func _ask_again() -> void:
	var q: Dictionary = _lesson[_asked]
	var choices: Array = []
	for answer: String in q.answers:
		choices.append({"text": answer})
	ChoiceCard.ask(self, q.ask, choices).chose.connect(_answered)


# Three right answers: a sticker, the bell, and down to the service de garde with Alyzée.
func _end_lesson() -> void:
	_board_text.text = "Bravo, la classe !"
	_teacher_says("Super travail ! Voici un autocollant\npour toi, Charlotte.", 3.0)
	GameState.flags[School.STICKERS] = int(GameState.flags.get(School.STICKERS, 0)) + 1
	_treat(ClassArt.sticker(), "Un autocollant !", 1.0)
	var bell := create_tween()
	bell.tween_interval(4.6)
	bell.tween_callback(func() -> void:
		_over = true
		Sfx.play("school_bell"))
	bell.tween_interval(1.6)
	bell.tween_callback(_teacher_says.bind("C'est la fin de la journée ! Ceux du service\nde garde, on descend avec Jade.", 3.6))
	bell.tween_interval(4.0)
	bell.tween_callback(func() -> void:
		_alyzee.express("happy", 2.0)
		_alyzee_says("Viens, Chachoue ! On va au service de garde !"))
	bell.tween_interval(3.2)
	bell.tween_callback(func() -> void:
		if School.step() > 0:
			School.set_step(4)
		Transition.change_scene_saying(self, School.GARDE, "Au service de garde…", 1.4))


# ── The fish in the aquarium ────────────────────────────────────

class _Fish:
	extends Node2D
	var tank := Rect2()
	var _t := 0.0
	const FISH := [[Color("#FF8A3D"), 0.0, 0.42], [Color("#FFD23F"), 2.1, 0.55], [Color("#E04F5F"), 4.0, 0.33]]

	func _process(delta: float) -> void:
		_t += delta
		if OnScreen.near(self, 200.0):
			queue_redraw()

	func _draw() -> void:
		for f: Array in FISH:
			var speed: float = f[2]
			var u := sin(_t * speed + f[1])
			var dir := signf(cos(_t * speed + f[1]))
			var p := Vector2(tank.position.x + tank.size.x * (0.5 + 0.38 * u), tank.position.y + tank.size.y * (0.35 + 0.15 * sin(_t * 0.7 + f[1])))
			var c: Color = f[0]
			draw_set_transform(p, 0.0, Vector2(dir, 1.0))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(-17, -6), Vector2(-17, 6)]), c.darkened(0.15))
			draw_circle(Vector2.ZERO, 7.0, c)
			draw_circle(Vector2(4, -2), 1.5, Color("#2B2B2B"))
		draw_set_transform(Vector2.ZERO)
		# A few bubbles from the bubbler.
		for k in 3:
			var y := fmod(_t * 30.0 + k * 22.0, tank.size.y)
			draw_circle(Vector2(tank.end.x - 30.0, tank.end.y - y), 2.0, Color(1, 1, 1, 0.6))
