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


func _ready() -> void:
	_build_shell()
	_build_vestibule()
	_build_salon()
	_build_hallway()
	_build_bedroom()
	_spawn_charlotte(470.0)
	_build_doors()
	_enter_area(BEDROOM if _charlotte.position.x >= BEDROOM.x else HALL)
	_finish([[700.0, "plant"], [1900.0, "plant"], [2900.0, "plant"], [5400.0, "plushie"], [6250.0, "plant"]])


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


func _build_doors() -> void:
	# Front door (its glass door leaf inside the vestibule frame) → back to the street.
	add_child(DoorSpot.make(Rect2(370, 204, 170, 396), func():
		_control.enabled = false
		Transition.change_scene(self, "res://scenes/main.tscn")))
	add_child(DoorSpot.make(Rect2(CHACHA_DOOR_X, 170, 150, 430), func(): _go_through(BEDROOM_DOOR_X - 40.0, BEDROOM, -1)))
	add_child(DoorSpot.make(Rect2(BEDROOM_DOOR_X, 170, 150, 430), func(): _go_through(CHACHA_DOOR_X + 75.0, HALL, 1)))
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
	_ceiling_light(320.0)
	_put(InteriorArt.oak_doorway(), VESTIBULE_END, WALL_BASE)
	_put(InteriorArt.oak_glass_door(), VESTIBULE_END + 230.0, WALL_BASE, 1.0, "wall")


func _build_salon() -> void:
	_put(InteriorArt.rug(), 900.0, 694.0, 0.9)
	_plate(1700.0, 560.0, true)
	_put(InteriorArt.monstera(), 860.0, 606.0, 0.85, "floor")
	for i in 3:
		_put(InteriorArt.poster(i), 1030.0 + i * 130.0, 340.0, 0.85, "wall")
	_put(InteriorArt.floor_lamp(), 1470.0, 604.0, 0.9, "floor")
	_glow(Vector2(1524.0, 360.0), 200.0, Color(1.0, 0.82, 0.5, 0.4))
	_put(InteriorArt.sofa(), 960.0, 606.0, 0.85, "floor")
	_put(InteriorArt.side_table(), 1390.0, 610.0, 0.8, "floor")
	_put(InteriorArt.window(170.0, 300.0), 1580.0, 470.0, 1.0, "wall")
	_daylight(Vector2(1580.0, 170.0), 170.0, 0.12)
	_plate(1780.0, 330.0, false)
	_put(InteriorArt.dining_table(), 1780.0, 606.0, 0.85, "floor")
	_pendant(1984.0, 310.0)
	_put(InteriorArt.black_shelf(), 2110.0, WALL_BASE, 0.7, "floor")


func _build_hallway() -> void:
	_ceiling_light(2600.0)
	_ceiling_light(3200.0)
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
	_put(InteriorArt.monstera(), 3300.0, 606.0, 0.55, "floor")
	_put(InteriorArt.kitchen(), KITCHEN_START, WALL_BASE)
	_daylight(Vector2(KITCHEN_START + 322.0, 260.0), 126.0, 0.1)
	_ceiling_light(KITCHEN_START + 200.0)


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
	_put(InteriorArt.terrarium(true), x + 30.0, 606.0, 0.85)
	_put(InteriorArt.flower_painting(), x + 470.0, 330.0, 0.8, "wall")
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
	_fairy_lights(x + 40.0, 40)


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
