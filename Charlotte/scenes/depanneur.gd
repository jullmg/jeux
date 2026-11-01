extends Interior
# ══════════════════════════════════════════════════════════════
# Inside dépanneur Xin-Xin (Rue Dandurand), as a side-on cross-section, a real corner store crammed with things:
# the door with its bell, the cash machine, the counter (till, lottery terminal, scratch tickets, gum) with the
# shopkeeper behind it and the wall of shelves behind her (clock, specials board), the candy wall, low gondolas
# in the middle of the floor, bread, the coffee corner, the sloche machine, the freezer, the drinks fridges and
# the dairy cooler (Québec's 4 L milk bags), the stockroom door; suspended ceiling, fluorescent panels,
# checkered floor, a security mirror in the corner.
# Click the shopkeeper to say hello; the candy, sloche, coffee corner, freezer, fridges or dairy to buy something;
# the door to go back out onto Dandurand.
# Usage: Godot --path . res://scenes/depanneur.tscn -- --screenshot=/tmp/dep.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const SHOP := Vector2(0, 3900)
const DOOR_X := 60.0
const ATM_X := 430.0
const COUNTER_X := 760.0
const CANDY_X := 1480.0
const BREAD_X := 2010.0
const COFFEE_X := 2250.0
const SLUSH_X := 2560.0
const FREEZER_X := 2520.0
const FRIDGE_X := 2840.0
const DAIRY_X := 3300.0
const STOCK_X := 3770.0
const TUBES: Array[float] = [400.0, 1000.0, 1600.0, 2200.0, 2800.0, 3400.0]
const HELLOS := ["Bonjour Charlotte !", "Bienvenue au dépanneur !", "Il fait beau aujourd'hui !", "Tu veux des bonbons ?"]

var _clerk: Character
var _hello := 0


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": SHOP.x, "to": SHOP.y, "wall": Color("#F1EBDD"), "base": Color("#7E8A84")}]
	shell.floor_style = "tiles"
	shell.ceiling_style = "drop"
	shell.gleams = TUBES
	add_child(shell)
	_build_walls()
	_build_counter()
	_build_aisles()
	_build_coolers()
	_spawn_charlotte(DOOR_X + 240.0)
	_build_spots()
	_enter_area(SHOP)
	_finish([[700.0, "shelf"], [1900.0, "shelf"], [3100.0, "shelf"]])
	Sfx.play("bell")


func _music() -> Array:
	return ["depanneur", "street_" + Season.current, "street"]


# The door, the cash machine, the newspapers, the Halloween crate, posters and the light panels.
func _build_walls() -> void:
	for x in TUBES:
		_panel_light(x)
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	_put(ShopArt.atm(), ATM_X - 150.0, 604.0, 0.95, "floor")
	_wall_label("GUICHET", Vector2(ATM_X - 150.0 + 71.0, 604.0 - 340.0 * 0.95 + 38.0), 15, Color.WHITE, Color("#16285C"))
	_glow(Vector2(ATM_X - 150.0 + 71.0, 604.0 - 340.0 * 0.95 + 110.0), 70.0, Color(0.5, 0.85, 1.0, 0.35))
	_put(ShopArt.newspaper_rack(), ATM_X + 20.0, 606.0, 0.9, "floor")
	_put(ShopArt.lotto_poster(), ATM_X + 40.0, 330.0, 0.7, "wall")
	# The names in plain lettering on the game's own artwork (no real logos).
	_wall_label("LOTO-QUÉBEC", Vector2(ATM_X + 96.0, 228.0), 13, Color("#FFD23F"), Color("#16285C"))
	_put(ShopArt.security_mirror(), STOCK_X + 30.0, 150.0, 0.8)
	_put(ShopArt.back_door(), STOCK_X, WALL_BASE)
	_wall_label("PRIVÉ", Vector2(STOCK_X + 85.0, WALL_BASE - 440.0 + 57.0), 20, Color("#C8202A"), Color.WHITE)


# Behind the counter: the wall of shelves, the clock, the specials board and the shopkeeper on her raised floor.
func _build_counter() -> void:
	_put(ShopArt.back_shelves(), COUNTER_X - 40.0, 520.0, 1.0, "wall")
	var clock := _Clock.new()
	clock.position = Vector2(COUNTER_X + 120.0, 150.0)
	add_child(clock)
	_put(ShopArt.specials_board(), COUNTER_X + 360.0, 210.0, 0.9, "wall")
	_wall_label("SPÉCIAUX", Vector2(COUNTER_X + 468.0, 82.0), 17, Color("#FFD23F"), Color("#1E2A24"))
	var specials := Label.new()
	specials.text = "Lait 4 L ...... 5,49 $\nPain tranché .. 2,99 $\nSloche ......... 1,50 $"
	specials.add_theme_font_size_override("font_size", 13)
	specials.add_theme_color_override("font_color", Color("#F4F2EC"))
	specials.position = Vector2(COUNTER_X + 382.0, 104.0)
	add_child(specials)
	_wall_label("OUVERT", Vector2(COUNTER_X + 640.0, 120.0), 28, Color("#FF5D8F"), Color("#7A1030"))
	_glow(Vector2(COUNTER_X + 640.0, 120.0), 110.0, Color(1.0, 0.3, 0.55, 0.35))
	# The shopkeeper: a man with short black hair, warm light skin, dark eyes, a navy sweater; on the raised floor
	# behind the counter so he shows above it.
	_clerk = Character.new()
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#F1D0B0")
	look.hair_style = "short"
	look.hair_color = Color("#1A1412")
	look.eye_color = Color("#3A2618")
	look.lashes = false
	look.mouth = "smile"
	look.outfit = "sweater"
	look.outfit_color = Color("#25408F")
	look.accent_color = Color("#FFFFFF")
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B2B")
	look.shoes = "sneaker"
	look.shoe_color = Color("#2B2B2B")
	look.hat = ""
	_clerk.look = look
	_clerk.scale = Vector2.ONE * CHAR_SCALE
	_clerk.position = Vector2(COUNTER_X + 300.0, 556.0)
	add_child(_clerk)
	_put(ShopArt.counter(), COUNTER_X, 616.0, 1.0, "floor")
	_put(InteriorArt.doormat(), COUNTER_X + 160.0, 640.0)


# The candy wall, bread, coffee, and the low gondolas in the middle of the floor (in front of the walls).
func _build_aisles() -> void:
	_put(ShopArt.candy_wall(), CANDY_X, WALL_BASE, 1.0, "floor")
	_wall_label("BONBONS", Vector2(CANDY_X + 240.0, WALL_BASE - 440.0 + 32.0), 26, Color.WHITE, Color("#C84A72"))
	_put(ShopArt.bread_rack(), BREAD_X, 606.0, 1.0, "floor")
	_put(ShopArt.coffee_station(), COFFEE_X, 606.0, 0.95, "floor")
	_wall_label("CAFÉ  •  CHOCOLAT CHAUD", Vector2(COFFEE_X + 133.0, 330.0), 15, Color("#5A3A22"), Color("#F4E3C8"))
	if Season.current == "autumn":
		_put(ShopArt.halloween_display(), ATM_X + 180.0, 640.0, 0.9, "floor")
	_put(ShopArt.gondola(), CANDY_X + 60.0, 652.0, 0.85, "floor")
	_put(ShopArt.gondola(), FRIDGE_X - 40.0, 652.0, 0.85, "floor")


# The sloche machine (its swirls turn), the freezer, the drinks fridges and the dairy cooler, glowing cold.
func _build_coolers() -> void:
	var slush := _put(ShopArt.slush_machine(), SLUSH_X, 470.0, 0.85, "floor")
	_wall_label("SLUSH PUPPIE", Vector2(SLUSH_X + 94.0, slush.position.y + 27.0), 13, Color("#3D7FD0"), Color.WHITE)
	_wall_label("SLOCHE", Vector2(SLUSH_X + 94.0, slush.position.y + 4.0), 12, Color.WHITE, Color("#3D7FD0"))
	for i in 2:
		var swirl := _Swirl.new()
		swirl.position = slush.position + Vector2(22.0 + i * 92.0 + 42.0, 100.0) * 0.85
		swirl.scale = Vector2.ONE * 0.85
		swirl.tint = [Color("#7FC4F0"), Color("#FF8A8A")][i]
		add_child(swirl)
	_put(ShopArt.freezer(), FREEZER_X, 652.0, 0.9, "floor")
	_put(ShopArt.drinks_fridge(), FRIDGE_X, WALL_BASE, 1.0, "floor")
	_glow(Vector2(FRIDGE_X + 220.0, 330.0), 280.0, Color(0.8, 0.92, 1.0, 0.25))
	_put(ShopArt.milk_cooler(), DAIRY_X, WALL_BASE, 1.0, "floor")
	_wall_label("PRODUITS LAITIERS", Vector2(DAIRY_X + 220.0, WALL_BASE - 480.0 + 26.0), 18, Color.WHITE, Color("#1D4F91"))
	_glow(Vector2(DAIRY_X + 220.0, 330.0), 280.0, Color(0.85, 0.95, 1.0, 0.25))


# A square fluorescent panel in the suspended ceiling, and its cool light.
func _panel_light(x: float) -> void:
	var panel := Polygon2D.new()
	panel.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(58, 0), Vector2(58, 14), Vector2(-58, 14)])
	panel.color = Color("#FBFDFF")
	panel.position = Vector2(x, CEILING - 14.0)
	add_child(panel)
	_glow(Vector2(x, CEILING + 30.0), 320.0, Color(0.95, 0.98, 1.0, 0.22))


func _wall_label(text: String, center: Vector2, size: int, color: Color, outline: Color) -> void:
	var label := Label.new()
	label.text = text
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 5
	settings.outline_color = outline
	label.label_settings = settings
	label.size = Vector2(300, 40)
	label.position = center - label.size / 2.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


func _build_spots() -> void:
	# The door: back out onto Rue Dandurand (Transition.street_x, set on the way in, puts her at the shop door).
	add_child(DoorSpot.make(Rect2(DOOR_X + 20.0, 170, 170, 430), func():
		_control.enabled = false
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/dandurand.tscn"), DOOR_X + 110.0))
	add_child(DoorSpot.make(Rect2(COUNTER_X + 250.0, 300, 100, 150), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 250.0)
		_hello += 1, COUNTER_X + 440.0))
	add_child(DoorSpot.make(Rect2(CANDY_X, 160, 480, 330), func():
		_buy(ShopArt.treat("candy" if randf() < 0.5 else "lollipop"), "Des bonbons !"), CANDY_X + 240.0))
	add_child(DoorSpot.make(Rect2(SLUSH_X, 200, 190, 270), func():
		_buy(ShopArt.treat("slush"), "Une sloche !"), SLUSH_X + 95.0))
	add_child(DoorSpot.make(Rect2(COFFEE_X, 340, 266, 266), func():
		_buy(ShopArt.treat("chocolate"), "Un chocolat chaud !"), COFFEE_X + 133.0))
	add_child(DoorSpot.make(Rect2(FREEZER_X, 500, 290, 150), func():
		_buy(ShopArt.treat("popsicle"), "Un popsicle !"), FREEZER_X + 145.0))
	add_child(DoorSpot.make(Rect2(FRIDGE_X, 120, 440, 360), func():
		_buy(ShopArt.treat("juice"), "Un jus !"), FRIDGE_X + 220.0))
	add_child(DoorSpot.make(Rect2(DAIRY_X, 120, 440, 480), func():
		_buy(ShopArt.treat("milk"), "Un sac de lait !"), DAIRY_X + 220.0))


# She picks something; the shopkeeper thanks her.
func _buy(picture: Texture2D, text: String) -> void:
	_treat(picture, text)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _say(_clerk, "Merci, bonne journée !", 250.0))


# The slush churning round inside one of the machine's bowls.
class _Swirl:
	extends Node2D
	var tint := Color.WHITE
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var a := _t * 2.0 + i * TAU / 3.0
			var p := Vector2(cos(a) * 26.0, sin(a) * 8.0 - 10.0 + i * 18.0)
			draw_set_transform(p, 0.0, Vector2(1.0, 0.35))
			draw_arc(Vector2.ZERO, 14.0, a, a + 2.4, 10, Color(tint, 0.8), 4.0, true)
		draw_set_transform(Vector2.ZERO)


# A wall clock that shows the real time.
class _Clock:
	extends Node2D

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 34.0, Color("#2B2B2B"))
		draw_circle(Vector2.ZERO, 30.0, Color("#FBFAF6"))
		for i in 12:
			var d := Vector2.from_angle(TAU * i / 12.0)
			draw_line(d * 24.0, d * 28.0, Color("#2B2B2B"), 2.0)
		var now := Time.get_time_dict_from_system()
		var minutes: float = now.minute + now.second / 60.0
		var hours: float = fmod(now.hour, 12.0) + minutes / 60.0
		draw_line(Vector2.ZERO, Vector2.from_angle(hours / 12.0 * TAU - PI / 2.0) * 15.0, Color("#2B2B2B"), 3.5, true)
		draw_line(Vector2.ZERO, Vector2.from_angle(minutes / 60.0 * TAU - PI / 2.0) * 23.0, Color("#2B2B2B"), 2.5, true)
		draw_line(Vector2.ZERO, Vector2.from_angle(now.second / 60.0 * TAU - PI / 2.0) * 25.0, Color("#E04F5F"), 1.2, true)
		draw_circle(Vector2.ZERO, 3.0, Color("#E04F5F"))
