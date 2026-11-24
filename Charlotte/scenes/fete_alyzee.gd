extends Interior
# Alyzée's birthday party (quest "fete", world/party.gd, step 3), in her family's flat: balloons, a garland, "BONNE FÊTE
# ALYZÉE !" over the table. Left to right: the door Maman brings her in by, Alyzée waiting for her, the unicorn on the wall
# (pin the horn on it, blindfolded), the piñata hanging from the ceiling, the party table with its junk food (and the cake,
# when it is time), the TV and the cushions. The party runs in stages, a "!" over what comes next: the present, the unicorn,
# the piñata, the cake and its song, the film; the table's goodies are there all along. Then Maman comes back, Alyzée's
# mother hands out the goody bags, and "Maman te ramène à la maison…". Art in world/party_art.gd (PartyArt).

const ROOM := Vector2(0.0, 2800.0)
const DOOR_X := 110.0
const ALYZEE_X := 560.0
const MOM_X := 380.0
const POSTER_X := 1000.0
const PINATA_X := 1450.0
const TABLE_X := 1950.0
const TV_X := 2500.0
## Where they sit on the cushions for the film (Charlotte, Alyzée, then the guests), the floor under them.
const CUSHIONS := [2330.0, 2420.0, 2600.0, 2690.0, 2240.0]
const CUSHION_FLOOR := 690.0
## How many hits the piñata takes before it bursts.
const HITS := 6
const FILM := "reine"

enum Stage { GIFT, UNICORN, PINATA, CAKE, FILM, BYE }

const KID_LINES := [
	["Y a-tu des bonbons dans la piñata ?\nJ'ai tellement hâte !", "Moi, j'ai donné un toutou à Alyzée !"],
	["C'est la plus belle fête de l'année !", "Le gâteau, y est-tu au chocolat ?"],
	["Je suis bon à la piñata, tu vas voir !", "J'ai mangé trop de chips… Hi hi !"],
]
const HER_MOM_LINES := ["Servez-vous, les amis ! Y en a en masse !", "Faites attention au bâton de la piñata, hein !",
	"Ça me fait tellement plaisir que tu sois venue, Charlotte."]
const ALYZEE_LINES := ["Je suis contente que tu sois là, Chachoue !", "Huit ans ! Chu rendue grande, han ?",
	"Après, on écoute un film ! C'est moi qui l'ai choisi."]
const SONG := [
	"♪ Bonne fête à toi… ♪",
	"♪ Bonne fête à toi… ♪",
	"♪ Bonne fête, chère Alyzée… ♪",
	"♪ Bonne fête à toi ! ♪",
]
const FILM_LINES := [
	[1.5, 1, "Chut ! C'est mon film préféré !"],
	[10.0, 2, "Les aurores boréales, wow !"],
	[19.0, 3, "Toute la neige qui tourne !"],
	[28.0, -1, "Passe-moi le pop-corn, Alyzée !"],
	[37.0, 2, "Un escalier de glace qui se construit !"],
	[47.0, 1, "Je connais toute la chanson !"],
	[57.0, 3, "Le château de glace !"],
	[68.0, -1, "Je veux un château comme ça !"],
	[78.0, 2, "Le bonhomme de neige est content."],
	[88.0, 1, "J'adore la fin !"],
]

var _stage := Stage.GIFT
var _film_sound: FilmSound
var _busy := false
var _alyzee: Character
var _alyzee_spot: DoorSpot
var _her_mom: Character
var _maman: Character
var _kids: Array[Character] = []
var _poster: Sprite2D
var _pinata: _Pinata
var _hits := 0
var _cake: Sprite2D
var _cake_flames: Array[Sprite2D] = []
var _tv: TvScreen
var _dark: Polygon2D
var _line := 0
var _mom_line := 0
var _kid_line := [0, 0, 0]


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": ROOM.x, "to": ROOM.y, "wall": Color("#FDF0E0"), "base": Color("#B8607A"),
		"pattern": "dots", "pattern_color": Color("#F2B8CC"), "pattern_alpha": 0.5,
		"wainscot": Color("#F6D5E0"), "wainscot_height": 130.0}]
	shell.gleams = [600.0, 1450.0, 2300.0]
	add_child(shell)
	_build_room()
	_build_people()
	_spawn_charlotte(DOOR_X + 230.0)
	_build_spots()
	_enter_area(ROOM)
	_finish([[800.0, "plant"], [2100.0, "plushie"]])
	_arrive()


func _music() -> Array:
	return ["fete", "house", "street_" + Season.current, "street"]


func room_name() -> String:
	return "La fête d'Alyzée"


# ── The room ────────────────────────────────────────────────────

func _build_room() -> void:
	_put(ClassArt.door("#E7C9A9"), DOOR_X - 75.0, 606.0, 0.85)
	for wx in [700.0, 1700.0]:
		var window := _put(InteriorArt.window(170.0, 260.0), wx - 85.0, 430.0, 1.0, "wall")
		_window_snow(window, 170.0, 260.0)
		_daylight(Vector2(wx - 85.0, 170.0), 170.0, 0.1)
	for gx in [0.0, 900.0, 1800.0]:
		_put(ClassArt.garland(900.0), gx, 110.0, 1.0)
	# The banner over the table.
	var banner := ColorRect.new()
	banner.color = Color("#E86A9A")
	banner.size = Vector2(380, 46)
	banner.position = Vector2(TABLE_X - 190.0, 150.0)
	add_child(banner)
	var words := Label.new()
	words.text = "BONNE FÊTE ALYZÉE !"
	words.add_theme_font_size_override("font_size", 26)
	words.add_theme_color_override("font_color", Color.WHITE)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.size = banner.size
	words.position = banner.position
	add_child(words)
	for b: Array in [[250.0, 1], [1220.0, 2], [2190.0, 3], [2760.0, 4]]:
		_put(PartyArt.balloons(b[1]), b[0] - 60.0, 612.0, 0.95)
	for lx in [600.0, 1450.0, 2300.0]:
		_ceiling_light(lx)
	_poster = _put(PartyArt.unicorn_poster(), POSTER_X - 130.0, 480.0, 1.0, "wall")
	var title := _label_at("Épingle la corne !", Vector2(POSTER_X, 236.0), 18, Color("#9C4A7A"))
	title.rotation = deg_to_rad(-2.0)
	_put(InteriorArt.rug(), PINATA_X - 260.0, 694.0, 0.8)
	_pinata = _Pinata.new()
	_pinata.position = Vector2(PINATA_X, 70.0)
	add_child(_pinata)
	_put(PartyArt.party_table(), TABLE_X - 220.0, 672.0, 1.0, "floor")
	_cake = _put(PartyArt.cake(true), TABLE_X - 65.0, 560.0)
	_cake.visible = false
	# The TV over a low cabinet, the cushions on the floor before it.
	_put(InteriorArt.side_table(), TV_X - 70.0, 610.0, 0.9, "floor")
	var frame := _put(InteriorArt.tv(), TV_X - 110.0, 470.0, 1.0, "wall")
	_tv = TvScreen.new()
	_tv.position = frame.position + Vector2(12, 12)
	_tv.stand_x = TV_X
	_tv.glow = _glow(frame.position + Vector2(110, 120), 320.0, Color(1, 1, 1, 0.3))
	add_child(_tv)


func _label_at(text: String, center: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(260, 30)
	label.position = center - label.size / 2.0
	add_child(label)
	return label


func _build_people() -> void:
	var looks := RandomNumberGenerator.new()
	looks.seed = 8808
	for i in 3:
		var kid := Character.new()
		kid.look = School.indoors(CharacterLook.random(looks, "child"))
		# No school bag at a party.
		kid.look.backpack = ""
		kid.fidgets = true
		kid.scale = Vector2.ONE * CHAR_SCALE
		kid.position = Vector2([1120.0, 1330.0, 1640.0][i], FEET_Y - 6.0)
		kid.facing = -1 if i == 1 else 1
		add_child(kid)
		_kids.append(kid)
	_her_mom = Character.new()
	_her_mom.look = _her_mom_look()
	_her_mom.fidgets = true
	_her_mom.scale = Vector2.ONE * CHAR_SCALE * 1.18
	_her_mom.position = Vector2(MOM_X, FEET_Y - 10.0)
	_her_mom.facing = 1
	add_child(_her_mom)
	_alyzee = Character.new()
	_alyzee.look = CharacterLook.alyzee()
	# A party crown on her birthday.
	_alyzee.look.hat = "crown"
	_alyzee.fidgets = true
	_alyzee.scale = Vector2.ONE * CHAR_SCALE
	_alyzee.position = Vector2(ALYZEE_X, FEET_Y - 4.0)
	_alyzee.facing = -1
	add_child(_alyzee)


## Alyzée's mother: long straight black hair like hers, very pale, a plum blouse.
static func _her_mom_look() -> CharacterLook:
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#FAE8DE")
	look.hair_style = "long_straight"
	look.hair_color = Color("#1A1412")
	look.eye_color = Color("#4A2F1C")
	look.lashes = true
	look.mouth = "smile"
	look.outfit = "sweater"
	look.outfit_color = Color("#7A3E6E")
	look.accent_color = Color("#F2C230")
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B38")
	look.shoes = "boot"
	look.shoe_color = Color("#3A2A2A")
	return look


# ── What she can click ──────────────────────────────────────────

func _build_spots() -> void:
	_alyzee_spot = DoorSpot.make(Rect2(ALYZEE_X - 55.0, 470.0, 110.0, 200.0), _talk_to_alyzee, ALYZEE_X - 110.0)
	_alyzee_spot.condition = func() -> bool: return not _busy
	add_child(_alyzee_spot)
	add_child(DoorSpot.make(Rect2(POSTER_X - 130.0, 260.0, 260.0, 220.0), _unicorn_game, POSTER_X - 40.0))
	var pinata_spot := DoorSpot.make(Rect2(PINATA_X - 90.0, 200.0, 180.0, 300.0), _hit_pinata, PINATA_X - 95.0)
	pinata_spot.condition = func() -> bool: return not _pinata.burst
	add_child(pinata_spot)
	add_child(DoorSpot.make(Rect2(TABLE_X - 220.0, 470.0, 440.0, 200.0), _at_table, TABLE_X - 120.0))
	# The TV is hers to start: a click only says so (no channels to flip through).
	_tv.before_click = func() -> bool:
		if not _busy:
			_says(_charlotte, "Je vais demander à Alyzée\nde lancer le film !" if _stage == Stage.FILM else "On va écouter un film tantôt !")
		return true
	add_child(DoorSpot.make(Rect2(_her_mom.position.x - 60.0, 330.0, 120.0, 340.0), func() -> void:
		if _busy:
			return
		_say(_her_mom, HER_MOM_LINES[_mom_line % HER_MOM_LINES.size()], 330.0, 3.0)
		_mom_line += 1, _her_mom.position.x + 110.0))
	for i in _kids.size():
		var kid := _kids[i]
		var spot := DoorSpot.make(Rect2(kid.position.x - 50.0, 480.0, 100.0, 190.0), func() -> void:
			var lines: Array = KID_LINES[i]
			_say(kid, lines[_kid_line[i] % lines.size()], 190.0, 2.6)
			_kid_line[i] += 1, kid.position.x - 100.0)
		spot.condition = func() -> bool: return not _busy and _stage < Stage.FILM
		add_child(spot)
	# The "!" over what comes next.
	add_child(QuestMark.make(Vector2(ALYZEE_X, 470.0), func() -> bool: return _stage == Stage.GIFT and not _busy))
	add_child(QuestMark.make(Vector2(POSTER_X, 220.0), func() -> bool: return _stage == Stage.UNICORN and not _busy))
	add_child(QuestMark.make(Vector2(PINATA_X, 160.0), func() -> bool: return _stage == Stage.PINATA and not _busy))
	add_child(QuestMark.make(Vector2(TABLE_X, 420.0), func() -> bool: return _stage == Stage.CAKE and not _busy))
	add_child(QuestMark.make(Vector2(CUSHIONS[1] + 30.0, 470.0), func() -> bool: return _stage == Stage.FILM and not _busy))


func _says(who: Character, text: String, seconds := 2.6) -> void:
	_say(who, text, 330.0 if who == _her_mom or who == _maman else 190.0, seconds)


## Walks `who` to `x` (then faces `face`, 0 = keep), at a child's pace.
func _walk(who: Character, x: float, face := 0) -> Tween:
	var t := create_tween()
	who.facing = 1 if x > who.position.x else -1
	who.is_walking = true
	t.tween_property(who, "position:x", x, absf(x - who.position.x) / 170.0 + 0.05)
	t.tween_callback(func() -> void:
		who.is_walking = false
		if face != 0:
			who.facing = face)
	return t


# ── Arriving: Maman brings her in ───────────────────────────────

func _arrive() -> void:
	_busy = true
	_control.enabled = false
	_maman = Character.new()
	var look := CharacterLook.mom()
	Season.dress_for_weather(look)
	_maman.look = look
	_maman.scale = Vector2.ONE * CHAR_SCALE * 1.18
	_maman.position = Vector2(DOOR_X + 90.0, FEET_Y - 10.0)
	_maman.facing = 1
	add_child(_maman)
	Sfx.play("door", _maman.position)
	var hello := create_tween()
	hello.tween_interval(0.8)
	hello.tween_callback(func() -> void:
		_her_mom.express("happy", 2.0)
		_says(_her_mom, "Bienvenue, Charlotte ! Entre, entre !\nAlyzée t'attend depuis à matin !", 3.2))
	hello.tween_interval(3.4)
	hello.tween_callback(func() -> void:
		_alyzee.express("grin", 2.0)
		_says(_alyzee, "Chachoue ! T'es venue !"))
	hello.tween_interval(2.6)
	hello.tween_callback(func() -> void:
		_says(_maman, "Amuse-toi bien, ma chouette ! Je reviens\nte chercher après le film.", 3.2))
	hello.tween_interval(3.4)
	hello.tween_callback(func() -> void:
		_maman.facing = -1
		_maman.is_walking = true)
	hello.tween_property(_maman, "position:x", DOOR_X - 20.0, 0.8)
	hello.parallel().tween_property(_maman, "modulate:a", 0.0, 0.8)
	hello.tween_callback(func() -> void:
		Sfx.play("door", _maman.position)
		_maman.visible = false
		_maman.is_walking = false
		_busy = false
		_control.enabled = true)


# ── 1. The present ──────────────────────────────────────────────

func _talk_to_alyzee() -> void:
	_alyzee.facing = -1 if _charlotte.position.x < _alyzee.position.x else 1
	if _stage == Stage.GIFT:
		_give_present()
		return
	if _stage == Stage.FILM:
		_start_film()
		return
	_says(_alyzee, ALYZEE_LINES[_line % ALYZEE_LINES.size()], 2.8)
	_line += 1


func _give_present() -> void:
	_busy = true
	_control.enabled = false
	var present: Array = Party.gift()
	var steps := create_tween()
	steps.tween_callback(func() -> void: _says(_charlotte, "Bonne fête, Alyzée !\nJ'ai un cadeau pour toi !", 2.8))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		Carry.put_down(_charlotte)
		Sfx.play("swoosh", _alyzee.position)
		_alyzee.express("surprised", 1.2)
		_says(_alyzee, "Oh ! Je l'ouvre tout de suite !"))
	steps.tween_interval(2.2)
	steps.tween_callback(func() -> void:
		Sfx.play("chime", _alyzee.position)
		_alyzee.express("laugh", 2.6)
		_pop_picture(PartyArt.gift(present[0]), _alyzee.position + Vector2(0, -260))
		_says(_alyzee, present[3], 3.6))
	steps.tween_interval(3.8)
	steps.tween_callback(func() -> void:
		_charlotte.express("happy", 2.0)
		_says(_alyzee, "Merci, Chachoue ! Viens, on joue\nà épingler la corne de la licorne !", 3.2))
	steps.tween_interval(1.2)
	steps.tween_callback(func() -> void:
		_move_alyzee(POSTER_X + 190.0, -1))
	steps.tween_interval(2.2)
	steps.tween_callback(func() -> void:
		_stage = Stage.UNICORN
		_busy = false
		_control.enabled = true)


## A picture that pops up over someone and floats away (the present she opens, a candy).
func _pop_picture(tex: Texture2D, at: Vector2) -> void:
	var pic := Sprite2D.new()
	pic.texture = tex
	pic.position = at
	pic.scale = Vector2.ONE * 0.3
	add_child(pic)
	var t := create_tween()
	t.tween_property(pic, "scale", Vector2.ONE * 1.1, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.4)
	t.tween_property(pic, "modulate:a", 0.0, 0.5)
	t.tween_callback(pic.queue_free)


func _move_alyzee(x: float, face: int) -> void:
	_walk(_alyzee, x, face)
	_alyzee_spot.rect = Rect2(x - 55.0, 470.0, 110.0, 200.0)
	_alyzee_spot.stand_x = x - 110.0 if x > _charlotte.position.x else x + 110.0
	_alyzee_spot.position = Vector2(_alyzee_spot.stand_x, 670.0)


# ── 2. Pin the horn on the unicorn ──────────────────────────────

func _unicorn_game() -> void:
	if _busy or _stage < Stage.UNICORN:
		if _stage == Stage.GIFT:
			_says(_charlotte, "Une licorne sans corne !\nOn va jouer tantôt.")
		return
	_busy = true
	_control.enabled = false
	_charlotte.facing = 1
	# Alyzée comes to the poster first: she used to talk from the far end of the room, out of the picture.
	_move_alyzee(POSTER_X + 200.0, -1)
	var go := create_tween()
	go.tween_interval(maxf(absf(POSTER_X + 200.0 - _alyzee.position.x) / 170.0 + 0.5, 0.8))
	go.tween_callback(func() -> void: _says(_alyzee, "On te bande les yeux…\net tu colles la corne !", 2.6))
	go.tween_interval(2.4)
	go.tween_callback(func() -> void:
		var blind := _Blindfold.new()
		blind.area = Rect2(_poster.position, Vector2(260, 220))
		blind.pinned.connect(_horn_pinned)
		add_child(blind))


func _horn_pinned(at: Vector2) -> void:
	var horn := Sprite2D.new()
	horn.texture = PartyArt.horn()
	horn.position = at + Vector2(0, 20)
	horn.scale = Vector2.ONE * 1.6
	horn.rotation = randf_range(-0.4, 0.4)
	add_child(horn)
	Sfx.play("pop", at)
	var target := _poster.position + PartyArt.HORN_SPOT
	var miss := at.distance_to(target)
	var line := ""
	if miss < 22.0:
		line = "En plein dans le front !\nT'es une championne, Chachoue !"
		_charlotte.express("laugh", 2.4)
		Sfx.play("chime", at)
	elif miss < 60.0:
		line = "Presque ! Juste à côté de son front !"
		_charlotte.express("grin", 2.0)
	elif at.x > _poster.position.x + 170.0:
		line = "Ha ha ha ! Sur sa queue ! Une licorne\navec une corne sur la queue !"
		_charlotte.express("laugh", 2.4)
	elif at.y > _poster.position.y + 150.0:
		line = "Hi hi ! Sur ses pattes ! Elle va marcher\nsur sa corne !"
		_charlotte.express("laugh", 2.4)
	else:
		line = "Ha ha ! Sur son dos ! C'est une licorne\nqui a une corne dans le dos !"
		_charlotte.express("laugh", 2.4)
	for kid in _kids:
		kid.express("laugh", 2.0)
	var after := create_tween()
	after.tween_callback(func() -> void: _says(_alyzee, line, 3.2))
	after.tween_interval(3.4)
	if _stage == Stage.UNICORN:
		after.tween_callback(func() -> void:
			_says(_alyzee, "Astheure, la piñata ! Prends le bâton\npis frappe fort !", 3.0)
			_move_alyzee(PINATA_X + 190.0, -1)
			for i in _kids.size():
				_walk(_kids[i], [PINATA_X - 230.0, PINATA_X + 280.0, PINATA_X + 360.0][i], 1 if i == 0 else -1))
		after.tween_interval(2.2)
		after.tween_callback(func() -> void: _stage = Stage.PINATA)
	after.tween_callback(func() -> void:
		_busy = false
		_control.enabled = true)


## The blindfold: everything goes dark but a little circle round the horn in her hand, which wanders over the poster as
## she gropes; a click (or Entrée) pins it where it is.
class _Blindfold:
	extends Node2D
	signal pinned(at: Vector2)
	var area: Rect2
	var _t := 0.0
	var _cursor := Vector2.ZERO
	var _done := false
	var _horn: Texture2D

	func _ready() -> void:
		z_index = 50
		_horn = PartyArt.horn()
		add_to_group("modal")
		_t = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		var c := area.get_center()
		_cursor = c + Vector2(sin(_t * 1.3) * 0.42 + sin(_t * 3.1) * 0.12, cos(_t * 1.1) * 0.36 + sin(_t * 2.3) * 0.1) * area.size
		queue_redraw()

	func _draw() -> void:
		draw_arc(_cursor, 70.0 + 1500.0, 0.0, TAU, 96, Color(0.04, 0.03, 0.08, 0.93), 3000.0)
		draw_arc(_cursor, 70.0, 0.0, TAU, 48, Color(0.04, 0.03, 0.08, 0.5), 24.0)
		draw_texture(_horn, _cursor - Vector2(12, 6))
		var font := ThemeDB.fallback_font
		draw_string(font, _cursor + Vector2(-200, 150), "Clique pour coller la corne !", HORIZONTAL_ALIGNMENT_CENTER, 400, 22, Color("#FFF3C4"))

	func _unhandled_input(event: InputEvent) -> void:
		if _done:
			return
		var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		if click or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_done = true
			pinned.emit(_cursor)
			queue_free()


# ── 3. The piñata ───────────────────────────────────────────────

func _hit_pinata() -> void:
	if _busy or _pinata.burst:
		return
	if _stage < Stage.PINATA:
		_says(_charlotte, "Une piñata ! Elle doit être\npleine de bonbons…")
		return
	_charlotte.facing = 1
	_charlotte.pet(0.35, 0.0)
	_hits += 1
	_pinata.hit(_hits / float(HITS))
	Sfx.play("pop", _pinata.position + Vector2(0, 240), 0.0, 0.8 + _hits * 0.06)
	Bubble.say(self, _pinata.position + Vector2(60, 180), ["Paf !", "Pow !", "Bang !"][_hits % 3], 0.8)
	if _hits < HITS:
		var cheer: Character = _kids[_hits % _kids.size()]
		_says(cheer, ["Encore !", "Plus fort !", "Elle craque !", "Vas-y, Chachoue !"][_hits % 4], 1.4)
		return
	_burst()


func _burst() -> void:
	_busy = true
	_control.enabled = false
	_pinata.explode()
	Sfx.play("swoosh", _pinata.position + Vector2(0, 240))
	for who: Character in [_alyzee] + _kids:
		who.express("laugh", 2.4)
	_charlotte.express("laugh", 2.4)
	var after := create_tween()
	after.tween_callback(func() -> void: _says(_alyzee, "Des bonbons partout ! Ramassez-les !", 2.4))
	# Everyone dives for the candy.
	after.tween_interval(1.0)
	after.tween_callback(func() -> void:
		for i in _kids.size():
			_walk(_kids[i], PINATA_X + [-120.0, 90.0, 170.0][i])
			_kids[i].pet(1.6, 1.0)
		_walk(_charlotte, PINATA_X - 40.0, 1)
		_charlotte.pet(1.6, 1.0))
	after.tween_interval(2.2)
	after.tween_callback(func() -> void:
		Stash.add("wrapped", 2)
		Stash.add("lollipop", 1)
		_treat(PartyArt.snack("jujubes"), "J'ai ramassé 3 bonbons !"))
	after.tween_interval(2.6)
	after.tween_callback(func() -> void:
		_her_mom.express("happy", 2.0)
		_walk(_her_mom, TABLE_X + 260.0, -1)
		_says(_her_mom, "C'est l'heure du gâteau !\nTout le monde à la table !", 3.0))
	after.tween_interval(2.6)
	after.tween_callback(func() -> void:
		_cake.visible = true
		_cake.modulate.a = 0.0
		create_tween().tween_property(_cake, "modulate:a", 1.0, 0.5)
		for k in 8:
			_cake_flames.append(_glow(_cake.position + Vector2(31.0 + k * 9.7 + 1.75, 23.0), 16.0, Color(1.0, 0.75, 0.4, 0.55)))
		_move_alyzee(TABLE_X + 60.0, -1)
		for i in _kids.size():
			_walk(_kids[i], TABLE_X + [-170.0, 150.0, 220.0][i], 1 if i == 0 else -1)
		_stage = Stage.CAKE
		_busy = false
		_control.enabled = true)


## The piñata: a star of crêpe paper (a round body, five cones with their tassels) on its rope from the ceiling, swinging; it
## cracks with each hit, then bursts: its halves fall, the candy rains down and stays on the floor.
class _Pinata:
	extends Node2D
	const ROPE := 170.0
	const R := 52.0
	var burst := false
	var _swing := 0.0
	var _speed := 0.0
	var _t := 0.0
	var _damage := 0.0
	var _halves := [Vector2.ZERO, Vector2.ZERO]
	var _fall := 0.0
	var _candy: Array = []
	var _scraps: Array = []

	func hit(damage: float) -> void:
		_damage = damage
		_speed += 2.6

	func explode() -> void:
		burst = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var colors := [Color("#E04F5F"), Color("#FFD23F"), Color("#4FA3E0"), Color("#7CCB5A"), Color("#FF7BA3"), Color("#9C6ADE")]
		var c := _body()
		for i in 40:
			_candy.append({"p": c, "v": Vector2(rng.randf_range(-260, 260), rng.randf_range(-320, -60)), "c": colors[i % colors.size()],
				"r": rng.randf_range(0, TAU), "spin": rng.randf_range(-8, 8), "rest": false, "kind": i % 4})
		# Scraps of crêpe paper tumbling down with it.
		for i in 46:
			_scraps.append({"p": c + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40)), "v": Vector2(rng.randf_range(-150, 150), rng.randf_range(-200, 40)),
				"c": colors[rng.randi_range(0, colors.size() - 1)], "r": rng.randf_range(0, TAU), "spin": rng.randf_range(-6, 6),
				"len": rng.randf_range(9.0, 18.0)})

	func _body() -> Vector2:
		return Vector2(sin(_swing), cos(_swing)) * ROPE + Vector2(0, R)

	func _process(delta: float) -> void:
		_t += delta
		# A damped pendulum, nudged by each hit.
		_speed += -_swing * 9.0 * delta
		_speed *= exp(-1.2 * delta)
		_swing += _speed * delta
		if burst:
			_fall += delta
			var floor_y := 668.0 - position.y - 4.0
			for k in _candy:
				if k.rest:
					continue
				k.v.y += 900.0 * delta
				k.p += k.v * delta
				k.r += k.spin * delta
				if k.p.y > floor_y:
					k.p.y = floor_y
					k.v *= Vector2(0.5, -0.3)
					k.spin *= 0.4
					if absf(k.v.y) < 40.0:
						k.rest = true
			# Paper floats down slower, and stays where it lands.
			for sc in _scraps:
				if sc.p.y >= floor_y:
					continue
				sc.v.y = minf(sc.v.y + 380.0 * delta, 150.0)
				sc.v.x *= exp(-1.5 * delta)
				sc.p += sc.v * delta + Vector2(sin(_t * 4.0 + sc.r) * 18.0 * delta, 0)
				sc.r += sc.spin * delta
				sc.p.y = minf(sc.p.y, floor_y)
		if OnScreen.near(self, 300.0):
			queue_redraw()

	func _draw() -> void:
		var body := _body()
		var rope_end := body - Vector2(0, R) if not burst else Vector2(sin(_swing), cos(_swing)) * ROPE
		draw_line(Vector2(0, -20), rope_end, Color("#C9B79A"), 3.0, true)
		if not burst:
			_draw_star(body, 0.0, Vector2.ZERO)
		var floor_y := 668.0 - position.y - 4.0
		for sc in _scraps:
			draw_set_transform(sc.p, sc.r)
			draw_rect(Rect2(-sc.len / 2.0, -1.5, sc.len, 3.0), sc.c)
			draw_set_transform(Vector2.ZERO)
		# A soft shadow under every candy that has landed, then the candy.
		for k in _candy:
			if k.rest:
				draw_set_transform(Vector2(k.p.x, floor_y + 5.0), 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.22))
				draw_set_transform(Vector2.ZERO)
		for k in _candy:
			draw_set_transform(k.p, k.r, Vector2(1.4, 1.4))
			_draw_candy(k.kind, k.c)
			draw_set_transform(Vector2.ZERO)

	# A sweet, about 20 px: wrapped in a twist, a lollipop, a hard candy, a foil chocolate.
	func _draw_candy(kind: int, c: Color) -> void:
		var dark := c.darkened(0.25)
		var light := c.lightened(0.45)
		match kind:
			0:
				# Wrapped sweet: a plump body between two twisted ends, a stripe and a shine.
				draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(-12, -6), Vector2(-10, 0), Vector2(-12, 6)]), light)
				draw_colored_polygon(PackedVector2Array([Vector2(5, 0), Vector2(12, -6), Vector2(10, 0), Vector2(12, 6)]), light)
				_ellipse(Vector2.ZERO, Vector2(7.5, 5.5), dark)
				_ellipse(Vector2(0, -0.6), Vector2(6.8, 4.8), c)
				draw_rect(Rect2(-1.5, -5.0, 3.0, 10.0), Color(1, 1, 1, 0.55))
				_ellipse(Vector2(-3.0, -2.6), Vector2(2.2, 1.1), Color(1, 1, 1, 0.6))
			1:
				# Lollipop: a swirled disc on a white stick.
				draw_rect(Rect2(-1.0, 2.0, 2.0, 13.0), Color("#F4EEE4"))
				draw_circle(Vector2.ZERO, 7.5, dark)
				draw_circle(Vector2.ZERO, 6.6, c)
				draw_arc(Vector2.ZERO, 3.2, 0.0, TAU * 0.8, 12, light, 1.6, true)
				draw_arc(Vector2.ZERO, 5.6, 1.0, TAU * 0.7, 12, Color(1, 1, 1, 0.8), 1.4, true)
				_ellipse(Vector2(-2.6, -3.0), Vector2(2.0, 1.1), Color(1, 1, 1, 0.55))
			2:
				# Hard candy: a glossy round bead.
				draw_circle(Vector2.ZERO, 5.8, dark)
				draw_circle(Vector2(0.3, 0.3), 5.0, c)
				draw_circle(Vector2(-1.6, -1.8), 1.9, Color(1, 1, 1, 0.7))
			_:
				# Foil chocolate: a square with creases and a bright edge.
				draw_rect(Rect2(-6.5, -5.5, 13, 11), dark)
				draw_rect(Rect2(-5.7, -4.7, 11.4, 9.4), c)
				draw_line(Vector2(-5.7, -4.7), Vector2(5.7, 4.7), Color(1, 1, 1, 0.35), 1.2)
				draw_line(Vector2(-5.7, 0.5), Vector2(5.7, -1.0), Color(1, 1, 1, 0.25), 1.0)
				draw_rect(Rect2(-5.7, -4.7, 11.4, 2.0), Color(1, 1, 1, 0.3))

	func _ellipse(at: Vector2, r: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(at + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(pts, color)

	func _draw_star(c: Vector2, _rot: float, _off: Vector2) -> void:
		var colors := [Color("#E04F5F"), Color("#FFC21F"), Color("#3E93E0"), Color("#5CBF4A"), Color("#FF6FA0")]
		var outer := R + 38.0
		var inner := R * 1.0
		# The star's body: five kites in five colours, the left of each lit and the right in the shade.
		for i in 5:
			var a := -PI / 2.0 + i * TAU / 5.0 + sin(_t * 2.0) * 0.03
			var dir := Vector2(cos(a), sin(a))
			var left := Vector2(cos(a - TAU / 10.0), sin(a - TAU / 10.0)) * inner
			var right := Vector2(cos(a + TAU / 10.0), sin(a + TAU / 10.0)) * inner
			var col: Color = colors[i]
			draw_colored_polygon(PackedVector2Array([c, c + left, c + dir * outer, c + right]), col.darkened(0.12))
			draw_colored_polygon(PackedVector2Array([c, c + left, c + dir * outer]), col.lightened(0.1))
			# Rows of fringe along the two edges: strips of crêpe, longer toward the middle, fluttering.
			for edge in 2:
				var from := c + (left if edge == 0 else right)
				var to := c + dir * outer
				var out_n := (left - dir * inner).normalized() if edge == 0 else (right - dir * inner).normalized()
				for k in 7:
					var u := (k + 0.5) / 7.0
					var p := from.lerp(to, u)
					var wob := sin(_t * 4.0 + k * 1.7 + i) * 2.0
					var tail := p + out_n * (6.0 - u * 3.0) + Vector2(wob, 7.0 + (1.0 - u) * 4.0)
					var fc: Color = colors[(i + k + edge) % 5]
					draw_line(p, tail, fc.darkened(0.08), 3.4 - u * 1.4, true)
			# The tip's tassels.
			var tip := c + dir * outer
			for k in 3:
				var tail := tip + Vector2((k - 1) * 4.0 + sin(_t * 5.0 + k + i) * 3.0, 15.0)
				draw_line(tip, tail, colors[(i + k + 1) % 5], 3.0, true)
		# The middle: a ring of stripes and a shiny paper disc.
		draw_circle(c, R * 0.82, Color("#9C4A7A"))
		for ring in 3:
			draw_circle(c, R * 0.74 - ring * 11.0, colors[(ring + 1) % 5])
		draw_circle(c, R * 0.26, Color("#FFF3C4"))
		draw_circle(c + Vector2(-14, -16), 10.0, Color(1, 1, 1, 0.3))
		# The cracks, more with each hit.
		var cracks := int(_damage * 6.0)
		for k in cracks:
			var a := 0.6 + k * 1.1
			var p0 := c + Vector2(cos(a), sin(a)) * 8.0
			var p1 := c + Vector2(cos(a + 0.3), sin(a + 0.3)) * (R * 0.6)
			var p2 := c + Vector2(cos(a - 0.1), sin(a - 0.1)) * R
			draw_polyline(PackedVector2Array([p0, p1, p2]), Color("#3A2A2A"), 2.5, true)


# ── 4. The cake, and the table's goodies ────────────────────────

func _at_table() -> void:
	if _busy:
		return
	if _stage == Stage.CAKE:
		_sing()
		return
	# Junk food, as much as she likes.
	var goodies := [["chips", "Des chips ! Crounche, crounche…"], ["popcorn", "Du pop-corn !"], ["jujubes", "Des jujubes !"],
		["cupcake", "Un petit gâteau rose !"], ["jus", "Une boîte de jus !"]]
	var pick: Array = goodies[randi() % goodies.size()]
	_treat(PartyArt.snack(pick[0]), pick[1])


func _sing() -> void:
	_busy = true
	_control.enabled = false
	_walk(_charlotte, TABLE_X - 100.0, 1)
	_dim(0.55)
	var song := create_tween()
	song.tween_interval(0.8)
	for k in SONG.size():
		var who: Character = [_her_mom, _kids[0], _charlotte, _kids[2]][k]
		song.tween_callback(func() -> void:
			for person: Character in [_charlotte, _her_mom] + _kids:
				person.express("talk", 1.6)
			_says(who, SONG[k], 1.9))
		song.tween_interval(2.1)
	song.tween_callback(func() -> void: _says(_her_mom, "Fais un vœu, ma chérie !", 2.0))
	song.tween_interval(2.2)
	song.tween_callback(func() -> void:
		_alyzee.express("effort", 1.2)
		_says(_alyzee, "Fffffffffff !", 1.2))
	song.tween_interval(1.0)
	song.tween_callback(func() -> void:
		_cake.texture = PartyArt.cake(false)
		for f in _cake_flames:
			f.queue_free()
		_cake_flames.clear()
		Sfx.play("swoosh", _cake.position)
		_dim(0.0)
		for person: Character in [_alyzee, _charlotte, _her_mom] + _kids:
			person.express("laugh", 2.4)
		_says(_kids[1], "Hourra !", 1.6))
	song.tween_interval(2.0)
	song.tween_callback(func() -> void: _treat(PartyArt.cake_slice(), "Miam ! Du gâteau au chocolat !"))
	song.tween_interval(3.4)
	song.tween_callback(func() -> void:
		_says(_alyzee, "Astheure, le film ! Tout le monde\nsur les coussins devant la télé !", 3.0))
	song.tween_interval(1.0)
	song.tween_callback(func() -> void:
		_move_alyzee(CUSHIONS[1] + 30.0, -1)
		_stage = Stage.FILM
		_busy = false
		_control.enabled = true)


# The room's lights going down (0 = full light): a night-blue veil over everything but the TV and the candles.
func _dim(amount: float) -> void:
	if _dark == null:
		_dark = Polygon2D.new()
		_dark.polygon = PackedVector2Array([Vector2(-100, -100), Vector2(ROOM.y + 100, -100), Vector2(ROOM.y + 100, 900), Vector2(-100, 900)])
		_dark.color = Color(0.05, 0.06, 0.16, 0.0)
		add_child(_dark)
		move_child(_dark, _tv.get_index())
	create_tween().tween_property(_dark, "color:a", amount, 0.6)


# ── 5. The film, then home ──────────────────────────────────────

func _start_film() -> void:
	if _busy:
		return
	if _stage < Stage.FILM:
		_says(_charlotte, "On va écouter un film tantôt !")
		return
	if _stage > Stage.FILM:
		return
	_busy = true
	_control.enabled = false
	_stage = Stage.BYE
	_says(_alyzee, "C'est « La Reine des neiges » !\nMon film préféré !", 2.6)
	var go := create_tween()
	go.tween_interval(2.6)
	go.tween_callback(func() -> void: Transition.through_black(self, _sit_for_film, 0.6))
	go.tween_interval(0.6)
	var said := 0.0
	for line: Array in FILM_LINES:
		go.tween_interval(float(line[0]) - said)
		go.tween_callback(_film_say.bind(line[1], line[2]))
		said = float(line[0])
	go.tween_interval(TvShows.FILM_LENGTH - said + 0.5)
	go.tween_callback(func() -> void: Transition.through_black(self, _lights_up, 0.6))
	go.tween_interval(1.4)
	go.tween_callback(_goodbye)


func _film_say(who: int, text: String) -> void:
	var person: Character = _charlotte if who < 0 else ([_alyzee] + _kids)[who - 1]
	_say(person, text, 150.0, 2.4)


func _sit_for_film() -> void:
	var who: Array = [_charlotte, _alyzee] + _kids
	for i in who.size():
		var person: Character = who[i]
		person.position.x = CUSHIONS[i]
		person.facing = 1 if CUSHIONS[i] < TV_X else -1
		person.seat_h = 10.0
		person.seat_floor = CUSHION_FLOOR
		person.sitting = true
		person.is_walking = false
		person.fidgets = false
	# Her mother goes off to the kitchen: she used to stand over the children on the cushions.
	_her_mom.visible = false
	_dim(0.6)
	var film: Array[String] = [FILM]
	_tv.channels = film
	_tv.turn_on(0)
	_film_sound = FilmSound.new()
	add_child(_film_sound)
	_film_sound.start("reine")
	Sfx.play("tv", _tv.get_global_rect().get_center())


func _lights_up() -> void:
	if _film_sound and is_instance_valid(_film_sound):
		_film_sound.stop()
	_film_sound = null
	_tv.turn_off()
	_dim(0.0)
	for person: Character in [_charlotte, _alyzee] + _kids:
		person.sitting = false
		person.fidgets = true
	_charlotte.position.x = CUSHIONS[0] - 160.0
	_charlotte.facing = 1
	# Maman is back, at the door.
	_maman.visible = true
	_maman.modulate.a = 1.0
	_maman.position = Vector2(TV_X - 420.0, FEET_Y - 10.0)
	_maman.facing = 1
	_her_mom.position.x = TV_X - 300.0
	_her_mom.facing = -1
	_her_mom.visible = true


func _goodbye() -> void:
	var bye := create_tween()
	bye.tween_callback(func() -> void: _says(_maman, "Coucou, les amis ! C'était-tu une belle fête ?", 2.8))
	bye.tween_interval(3.0)
	bye.tween_callback(func() -> void:
		_her_mom.express("happy", 2.0)
		_says(_her_mom, "Un sac surprise pour chacun !\nMerci d'être venus.", 3.0))
	bye.tween_interval(1.2)
	bye.tween_callback(func() -> void:
		Stash.add("chocolate", 1)
		Stash.add("gum", 1)
		Stash.add("wrapped", 1)
		_treat(PartyArt.loot_bag(), "Un sac surprise plein de bonbons !"))
	bye.tween_interval(2.8)
	bye.tween_callback(func() -> void: _says(_charlotte, "Merci pour l'invitation, Alyzée !\nC'était la plus belle fête !", 3.0))
	bye.tween_interval(3.2)
	bye.tween_callback(func() -> void:
		_alyzee.express("happy", 2.4)
		_says(_alyzee, "Merci pour mon cadeau, Chachoue !\nT'es ma meilleure amie de l'école !", 3.2))
	bye.tween_interval(3.4)
	bye.tween_callback(func() -> void:
		if Quests.active(Party.QUEST):
			Quests.complete(Party.QUEST)
		Party.clear()
		Sfx.play("chime", _charlotte.position))
	bye.tween_interval(2.0)
	bye.tween_callback(func() -> void:
		Transition.inside_x = School.HOME_X
		# The way in left the Jean Coutu's door on Masson in street_x and nobody read it: left there, the front door
		# would put her on the Masson end of 6e.
		Transition.street_x = NAN
		Transition.arrive = ""
		Transition.change_scene_saying(self, Party.HOME, "Maman te ramène à la maison…", 1.6))
