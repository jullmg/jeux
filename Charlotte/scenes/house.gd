extends Interior
# ══════════════════════════════════════════════════════════════
# Inside Charlotte's flat, as a side-on cross-section (from reference/charlotte_house_inside):
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
const BEDROOM_DOOR_X := 6440.0
const MOM_LINES := ["Bonjour ma chouette !", "As-tu faim ? Il y a des fruits.", "N'oublie pas de nourrir le hamster !", "Je t'aime, Chacha !"]
const DAD_LINES := ["Salut Chacha !", "On va au parc tantôt ?", "As-tu fait un beau dessin ?", "Tu veux jouer avec moi ?"]
# What's lying on the bedroom floor (kind, x in the bedroom), and where each goes when she tidies it away.
const MESS := [["teddy", 230.0], ["sock", 540.0], ["book", 700.0], ["ball", 880.0], ["tshirt", 1060.0], ["crayons", 1240.0]]
const PUT_AWAY := {"sock": Vector2(1340, 560), "tshirt": Vector2(1340, 560), "book": Vector2(1010, 300),
	"crayons": Vector2(1180, 470), "ball": Vector2(800, 600), "teddy": Vector2(800, 600)}
const CAN_X := KITCHEN_START + 470.0
const SNACKS := [["apple", "Une pomme !"], ["yogurt", "Un yogourt !"], ["cheese", "Du fromage !"],
	["grapes", "Des raisins !"], ["carrot", "Une carotte !"], ["cookie", "Un biscuit !"]]

# Lights that the switches and the floor lamp turn on and off.
var _vestibule_light: Sprite2D
var _salon_pendant: Sprite2D
var _floor_lamp: Array = []
var _hall_lights: Array = []
var _bedroom_lights: FairyLights
# Charlotte's drawings stuck on the fridge door with magnets.
var _fridge_art: Node2D
var _fridge_busy := false
var _mom: Character
var _dad: Character
var _mom_line := 0
var _dad_line := 0
# The house plants to water (id → sprite) and the watering can in the kitchen.
var _plants := {}
var _can: Sprite2D


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
		{"from": 0.0, "to": VESTIBULE_END, "wall": Color("#ECE8DF"), "base": Color("#F4F1EA")},
		{"from": VESTIBULE_END, "to": SALON_END, "wall": Color("#E9DCC2"), "base": Color("#6E4424")},
		{"from": SALON_END, "to": HALL.y, "wall": Color("#EEEBE5"), "base": Color("#F4F1EA")},
		{"from": BEDROOM.x, "to": BEDROOM.y, "wall": Color("#E4E3DF"), "base": Color("#6E4424")},
	]
	shell.chair_rails = [{"from": 0.0, "to": VESTIBULE_END, "y": 420.0}]
	shell.posts = [SALON_END]
	shell.casings = [
		{"x": CHACHA_DOOR_X, "w": 150.0, "top": 170.0, "color": Color("#F4F1EA")},
		{"x": BEDROOM_DOOR_X, "w": 150.0, "top": 170.0, "color": Color("#8A5228")},
	]
	shell.gleams = [320.0, 410.0, 1524.0, 1665.0, 1984.0, 2600.0, 3200.0, KITCHEN_START + 322.0, BEDROOM.x + 180.0, BEDROOM.x + 700.0]
	add_child(shell)


# Mom in the kitchen by the stove, Dad in the salon by the dining table. Click them for a word.
func _build_family() -> void:
	_mom = _family_member(CharacterLook.mom(), KITCHEN_START + 300.0, -1)
	_dad = _family_member(CharacterLook.dad(), 1720.0, -1)
	add_child(DoorSpot.make(Rect2(_mom.position.x - 55.0, 330, 110, 340), _talk_to_mom, _mom.position.x - 90.0))
	add_child(DoorSpot.make(Rect2(_dad.position.x - 55.0, 330, 110, 340), _talk_to_dad, _dad.position.x - 90.0))
	# A "!" over whoever has a quest for Charlotte, or is waiting for what she brings.
	add_child(QuestMark.make(_mom.position + Vector2(0, -350), func() -> bool:
		return Quests.available("milk") or Quests.available("menage") or Quests.active("milk") and GameState.flags.get("has_milk", false)))
	add_child(QuestMark.make(_dad.position + Vector2(0, -360), func() -> bool: return Quests.available("hamster") or Quests.available("plants")))


# Mom asks for milk, sends her to the dépanneur, and thanks her when she brings it home.
func _talk_to_mom() -> void:
	if Quests.active("milk") and GameState.flags.get("has_milk", false):
		GameState.flags.erase("has_milk")
		_say(_mom, "Du lait ! Merci, ma grande !", 350.0)
		Quests.complete("milk")
	elif Quests.start("milk"):
		_say(_mom, "Chacha, peux-tu aller me chercher\ndu lait au dépanneur ?", 380.0, 3.5)
	elif Quests.active("milk"):
		_say(_mom, "Le dépanneur est au coin\nde la rue Dandurand !", 380.0)
	elif Quests.start("menage"):
		_say(_mom, "Ta chambre est en désordre,\nva la ranger, ma chouette !", 380.0, 3.5)
	elif Quests.active("menage"):
		_say(_mom, "As-tu fini de ranger\nta chambre ?", 380.0)
	else:
		_say(_mom, MOM_LINES[_mom_line % MOM_LINES.size()], 350.0)
		_mom_line += 1


func _talk_to_dad() -> void:
	if Quests.start("hamster"):
		_say(_dad, "Avant le dodo, n'oublie pas\nde nourrir ton hamster !", 390.0, 3.5)
	elif Quests.start("plants"):
		_say(_dad, "Les plantes ont soif ! L'arrosoir\nest dans la cuisine.", 390.0, 3.5)
	elif Quests.active("plants"):
		_say(_dad, "Une au salon, une dans le corridor,\nune dans ta chambre !", 390.0, 3.5)
	else:
		_say(_dad, DAD_LINES[_dad_line % DAD_LINES.size()], 360.0)
		_dad_line += 1


# ── Chores: tidying her room, watering the plants ───────────

func _build_chores() -> void:
	var tidied: Array = GameState.flags.get("tidied", [])
	if not Quests.done("menage"):
		for m in MESS:
			if tidied.has(m[0]):
				continue
			var item := _put(InteriorArt.mess(m[0]), BEDROOM.x + m[1], 690.0, 1.15)
			add_child(DoorSpot.make(Rect2(item.position - Vector2(6, 10), Vector2(104, 66)), _tidy.bind(m[0], item), BEDROOM.x + m[1] + 32.0))
	for id in _plants:
		var plant: Sprite2D = _plants[id]
		if _thirsty(id):
			plant.modulate = Color(0.86, 0.74, 0.38)
			plant.skew = 0.2
		var area := Rect2(plant.position, plant.texture.get_size() * plant.scale)
		add_child(DoorSpot.make(area, _water.bind(id), area.get_center().x - 50.0))
	_can = _put(InteriorArt.watering_can(), CAN_X, 606.0, 0.55, "floor")
	add_child(DoorSpot.make(Rect2(_can.position - Vector2(10, 20), Vector2(86, 70)), _take_can, CAN_X + 30.0))
	add_child(QuestMark.make(_can.position + Vector2(33, -40), func() -> bool:
		return Quests.active("plants") and not GameState.flags.get("has_can", false), 0.8))
	if GameState.flags.get("has_can", false):
		_hold_can.call_deferred()


func _thirsty(id: String) -> bool:
	return not Quests.done("plants") and not (GameState.flags.get("watered", []) as Array).has(id)


# She crouches, picks it up, and it flies to its place (the laundry basket, the toys, the bookshelf, the desk).
func _tidy(kind: String, item: Sprite2D) -> void:
	if not is_instance_valid(item) or item.has_meta("taken"):
		return
	item.set_meta("taken", true)
	Quests.start("menage")
	_charlotte.pet(0.7, 1.0)
	Sfx.play("pop", item.position)
	var to: Vector2 = BEDROOM.x * Vector2.RIGHT + PUT_AWAY[kind]
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(item, "position", to, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(item, "scale", item.scale * 0.5, 0.5)
	tween.parallel().tween_property(item, "modulate:a", 0.0, 0.5)
	tween.tween_callback(item.queue_free)
	var tidied: Array = GameState.flags.get("tidied", [])
	tidied.append(kind)
	GameState.flags["tidied"] = tidied
	if tidied.size() >= MESS.size():
		GameState.flags.erase("tidied")
		_say(_charlotte, "Ma chambre est toute propre !", 300.0)
		Quests.complete("menage")


func _take_can() -> void:
	if Quests.done("plants") or GameState.flags.get("has_can", false):
		_say(_charlotte, "C'est l'arrosoir.", 300.0)
		return
	if LostCats.carrying() != "":
		_say(_charlotte, "J'ai les mains pleines !", 300.0)
		return
	Quests.start("plants")
	GameState.flags["has_can"] = true
	Sfx.play("pop", _can.position)
	_hold_can()


func _hold_can() -> void:
	_can.visible = false
	var held := Sprite2D.new()
	held.texture = _can.texture
	held.scale = Vector2.ONE * 0.5
	held.offset = Vector2(20, -10)
	_charlotte.carry(held)


func _water(id: String) -> void:
	var plant: Sprite2D = _plants[id]
	if not _thirsty(id):
		_say(_charlotte, "Elle a assez bu !" if Quests.done("plants") or Quests.active("plants") else "Elle est belle, cette plante.", 300.0)
		return
	if not GameState.flags.get("has_can", false):
		_say(_charlotte, "Elle a soif… Il me faut\nl'arrosoir de la cuisine !", 300.0, 3.0)
		return
	# Water pours from the can onto the pot; the plant perks up and greens again.
	var size := plant.texture.get_size() * plant.scale
	var pot := plant.position + Vector2(size.x * 0.5, size.y * 0.75)
	for i in 14:
		var drop := Sprite2D.new()
		drop.texture = PropArt.flake()
		drop.modulate = Color(0.55, 0.78, 1.0, 0.9)
		drop.scale = Vector2.ONE * 0.35
		drop.position = _charlotte.position + Vector2(40.0 * _charlotte.facing, -150.0)
		add_child(drop)
		var tween := create_tween()
		tween.tween_interval(i * 0.06)
		tween.tween_property(drop, "position", pot + Vector2(randf_range(-20, 20), randf_range(-10, 10)), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(drop.queue_free)
	Sfx.play("swoosh", pot)
	var perk := create_tween()
	perk.tween_interval(0.8)
	perk.tween_property(plant, "modulate", Color.WHITE, 0.8)
	perk.parallel().tween_property(plant, "skew", 0.0, 0.8).set_trans(Tween.TRANS_BACK)
	var watered: Array = GameState.flags.get("watered", [])
	watered.append(id)
	GameState.flags["watered"] = watered
	if watered.size() >= _plants.size():
		GameState.flags.erase("watered")
		GameState.flags.erase("has_can")
		perk.tween_callback(func():
			_charlotte.carry(null)
			_can.visible = true
			_say(_charlotte, "Toutes les plantes ont bu !", 300.0)
			Quests.complete("plants"))
	else:
		_say(_charlotte, "Bois, petite plante !", 300.0)


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
	wardrobe.closed.connect(func(look: CharacterLook):
		if look:
			CharacterLook.dress_charlotte(look)
			_charlotte.set_look(CharacterLook.charlotte())
			_twirl()
		_control.enabled = true)
	add_child(wardrobe)


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


# Bedtime: the room goes night-blue and moonlit, she's tucked in ("Bonne nuit"), little z's float up from the
# bed; then black, "Le lendemain matin…", and she's up beside the bed (the hamster is hungry again).
func _go_to_sleep() -> void:
	if Quests.active("hamster"):
		if not GameState.flags.get("hamster_fed", false):
			_say(_charlotte, "Oh ! Mon hamster n'a pas mangé !", 300.0)
			return
		Quests.complete("hamster")
	_control.enabled = false
	Sfx.play("goodnight")
	Music.play(["night"])
	var night := CanvasLayer.new()
	night.layer = 55
	add_child(night)
	var dark := ColorRect.new()
	dark.color = Color(0.04, 0.06, 0.18, 0.0)
	dark.size = VIEW
	dark.mouse_filter = Control.MOUSE_FILTER_STOP
	night.add_child(dark)
	var moon := _glow(Vector2(BEDROOM.x + 180.0, 280.0), 260.0, Color(0.6, 0.75, 1.0, 0.0))
	var words := _night_label("Bonne nuit, Chacha…", 40)
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
		words.text = "Le lendemain matin…"
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
	_put(InteriorArt.boots(), 540.0, 612.0, 0.8, "floor")
	_put(InteriorArt.floor_clutter(), 150.0, 622.0)
	_vestibule_light = _ceiling_light(320.0)
	_put(InteriorArt.oak_doorway(), VESTIBULE_END, WALL_BASE)
	_put(InteriorArt.oak_glass_door(), VESTIBULE_END + 230.0, WALL_BASE, 1.0, "wall")


func _build_salon() -> void:
	_put(InteriorArt.rug(), 900.0, 694.0, 0.9)
	_plate(1700.0, 560.0, true)
	_plants["salon"] = _put(InteriorArt.monstera(), 860.0, 606.0, 0.85, "floor")
	for i in 3:
		_put(InteriorArt.poster(i), 1030.0 + i * 130.0, 340.0, 0.85, "wall")
	_put(InteriorArt.floor_lamp(), 1470.0, 604.0, 0.9, "floor")
	_floor_lamp = [_glow(Vector2(1524.0, 360.0), 200.0, Color(1.0, 0.82, 0.5, 0.4)), _glow(Vector2(1524.0, 300.0), 46.0, Color(1.0, 0.95, 0.75, 0.55))]
	_put(InteriorArt.sofa(), 960.0, 606.0, 0.85, "floor")
	_put(InteriorArt.side_table(), 1390.0, 610.0, 0.8, "floor")
	_put(InteriorArt.window(170.0, 300.0), 1580.0, 470.0, 1.0, "wall")
	_daylight(Vector2(1580.0, 170.0), 170.0, 0.12)
	_plate(1780.0, 330.0, false)
	_put(InteriorArt.dining_table(), 1780.0, 606.0, 0.85, "floor")
	_salon_pendant = _pendant(1984.0, 310.0)
	_put(InteriorArt.black_shelf(), 2110.0, WALL_BASE, 0.7, "floor")


func _build_hallway() -> void:
	_hall_lights = [_ceiling_light(2600.0), _ceiling_light(3200.0)]
	_put(InteriorArt.runner(980.0), 2320.0, 690.0)
	_put(InteriorArt.black_coats(), 2330.0, 470.0, 0.8, "wall")
	_put(InteriorArt.photo_row(), 2520.0, 260.0, 0.8, "wall")
	_put(InteriorArt.tv(), 2560.0, 400.0, 0.8, "wall")
	_build_tv(Vector2(2560.0, 400.0 - 140.0 * 0.8), 0.8)
	_plate(2480.0, 330.0, false)
	_put(InteriorArt.radiator(160.0, 150.0), 2790.0, WALL_BASE, 1.0, "floor")
	_put(InteriorArt.recycling_bin(), 2985.0, 608.0, 1.0, "floor")
	_put(InteriorArt.panel_door(), CHACHA_DOOR_X, WALL_BASE)
	_chacha_sign(Vector2(CHACHA_DOOR_X + 75.0, 330.0))
	_plants["corridor"] = _put(InteriorArt.monstera(), 3300.0, 606.0, 0.55, "floor")
	_put(InteriorArt.kitchen(), KITCHEN_START, WALL_BASE)
	_fridge_art = Node2D.new()
	add_child(_fridge_art)
	_show_fridge_drawings()
	_daylight(Vector2(KITCHEN_START + 322.0, 260.0), 126.0, 0.1)
	_hall_lights.append(_ceiling_light(KITCHEN_START + 200.0))


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
	_plants["chambre"] = _put(InteriorArt.monstera(), x + 282.0, 606.0, 0.42, "floor")
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
