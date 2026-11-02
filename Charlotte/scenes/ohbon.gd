extends Shop
# ══════════════════════════════════════════════════════════════
# Inside dépanneur Oh Bon! (rue Holt, at the 6e Avenue corner), as a side-on cross-section. The opposite of Xin-Xin: bright
# and tidy. White walls with a red-and-white checkerboard frieze (like its storefront), a pale polished floor, everything in
# straight rows with room to walk: a modern counter with the shopkeeper, tidy shelves behind her, a BIG TV mounted high on
# the wall playing shows (it changes channel on its own; click it for the next one), the candy wall, a chips gondola, the
# drinks fridges and the dairy cooler, the coffee corner, a plant by the door.
# Click the shopkeeper to say hello; the candy, chips, fridges, dairy or coffee to buy something; the TV to change channel;
# the door to go back out onto Rue Holt.
# Usage: Godot --path . res://scenes/ohbon.tscn -- --screenshot=/tmp/ohbon.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const SHOP := Vector2(0, 3900)
const DOOR_X := 60.0
const COUNTER_X := 780.0
const CANDY_X := 1560.0
const CHIPS_X := 2110.0
const FRIDGE_X := 2560.0
const DAIRY_X := 3060.0
const COFFEE_X := 3560.0
const TUBES: Array[float] = [450.0, 1100.0, 1750.0, 2400.0, 3050.0, 3700.0]
const TV_CHANNELS: Array[String] = ["news", "animals", "cartoon", "hockey", "weather", "cooking", "space", "music", "game"]
const HELLOS := ["Bonjour Charlotte !", "Bienvenue chez Oh Bon !", "Une belle journée, hein ?", "Tu veux des chips ?"]

var _hello := 0
var _tv: TvScreen


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": SHOP.x, "to": SHOP.y, "wall": Color("#FAF8F3"), "base": Color("#D9342B")}]
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#F6F3EC"), Color("#DCDCD6")]
	shell.ceiling_style = "drop"
	shell.gleams = TUBES
	add_child(shell)
	_build_frieze()
	_build_entrance()
	_build_counter()
	_build_tv()
	_build_aisles()
	_build_lighting()
	_add_customers(2, [420.0, 1250.0, 1700.0, 2200.0, 2700.0, 3200.0], 29)
	_steam(Vector2(COFFEE_X + 100.0, 330.0))
	_spawn_charlotte(DOOR_X + 240.0)
	_build_spots()
	_enter_area(SHOP)
	_finish([[900.0, "basket"], [2500.0, "basket"]])
	Sfx.play("bell")


func _music() -> Array:
	return ["depanneur", "street_" + Season.current, "street"]


# The red-and-white checkerboard of its storefront, round the top of the walls.
func _build_frieze() -> void:
	var y := 48.0
	var size := 14.0
	for row in 2:
		var x := SHOP.x
		var col := row % 2
		while x < SHOP.y:
			var sq := Polygon2D.new()
			sq.polygon = PackedVector2Array([Vector2(x, y), Vector2(x + size, y), Vector2(x + size, y + size), Vector2(x, y + size)])
			sq.color = Color("#D9342B") if col % 2 == 0 else Color("#FFFFFF")
			add_child(sq)
			x += size
			col += 1
		y += size
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(SHOP.x, 76), Vector2(SHOP.y, 76), Vector2(SHOP.y, 104), Vector2(SHOP.x, 104)])
	shade.vertex_colors = PackedColorArray([Color(0.2, 0.1, 0.04, 0.1), Color(0.2, 0.1, 0.04, 0.1), Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.0)])
	add_child(shade)


# The door, a stack of baskets on a stand, hand sanitiser, a plant, three framed posters.
func _build_entrance() -> void:
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	_put(ShopArt.baskets_stack(), 330.0, 640.0, 0.9, "floor")
	_put(ShopArt.fire_extinguisher(), 440.0, 560.0, 1.0, "wall")
	var plant := _put(InteriorArt.house_plant("fiddle", false), 470.0, 630.0, 0.6, "floor")
	plant.z_index = 0
	for i in 3:
		_put(InteriorArt.poster(i), 520.0 + i * 100.0, 330.0, 0.62, "wall")


# The counter, the shopkeeper behind it and the tidy shelves behind her.
func _build_counter() -> void:
	_put(ShopArt.tidy_back_shelves(), COUNTER_X - 20.0, 520.0, 1.0, "wall")
	_clerk = Character.new()
	# The shopkeeper: a slightly heavy, bald man with Cambodian features: warm brown skin, almond eyes, a friendly smile, a
	# red polo shirt.
	var look := CharacterLook.new()
	look.age = "adult"
	look.build = 1.16
	look.skin = Color("#C28A5C")
	look.hair_style = "bald"
	look.hair_color = Color("#1E1612")
	look.eye_color = Color("#2E1E14")
	look.eyes = "almond"
	look.lashes = false
	look.mouth = "smile"
	look.outfit = "sweater"
	look.outfit_color = Color("#D9342B")
	look.accent_color = Color("#FFFFFF")
	look.pattern = "none"
	look.sleeve = "short"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B33")
	look.shoes = "sneaker"
	look.shoe_color = Color("#2B2B33")
	_clerk.look = look
	_clerk.scale = Vector2.ONE * CHAR_SCALE * 1.04
	_clerk.position = Vector2(COUNTER_X + 520.0, 556.0)
	_clerk.fidgets = true
	_clerk.fidget_moves = ["look", "look", "stretch"]
	add_child(_clerk)
	_put(ShopArt.modern_counter(), COUNTER_X, 616.0, 1.0, "floor")
	_put(InteriorArt.doormat(), COUNTER_X + 190.0, 640.0)
	# On the wall to the right of the counter, between it and the candy wall: the clock and the neon.
	var clock := _Clock.new()
	clock.position = Vector2(COUNTER_X + 705.0, 225.0)
	add_child(clock)
	var neon := NeonSign.new()
	neon.lines = ["OH BON!"]
	neon.color = Color("#FF4A3A")
	neon.font_size = 28
	neon.tilt = 0.0
	neon.position = Vector2(COUNTER_X + 705.0, 140.0)
	add_child(neon)
	_glow(Vector2(COUNTER_X + 705.0, 145.0), 80.0, Color(1.0, 0.3, 0.2, 0.18))


# The big TV, mounted high above the counter: a black frame on a bracket, the picture changing channel on its own.
func _build_tv() -> void:
	var s := 1.75
	var top_left := Vector2(COUNTER_X + 110.0, 70.0)
	var bracket := Polygon2D.new()
	bracket.polygon = PackedVector2Array([top_left + Vector2(150, 125) * s, top_left + Vector2(170, 125) * s, top_left + Vector2(176, 150) * s, top_left + Vector2(144, 150) * s])
	bracket.color = Color("#2B2B33")
	add_child(bracket)
	var frame := Sprite2D.new()
	frame.texture = InteriorArt.tv()
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.centered = false
	frame.position = top_left
	frame.scale = Vector2.ONE * s
	add_child(frame)
	_tv = TvScreen.new()
	_tv.channels = TV_CHANNELS.duplicate()
	_tv.position = top_left + Vector2(12, 12) * s
	_tv.scale = Vector2.ONE * s
	_tv.stand_x = COUNTER_X + 330.0 - 120.0
	_tv.auto_cycle = 22.0
	_tv.glow = _glow(top_left + Vector2(110, 70) * s, 420.0, Color(1, 1, 1, 0.22))
	add_child(_tv)
	_tv.turn_on(randi() % TV_CHANNELS.size())


# Everything in straight rows, with room to walk between.
func _build_aisles() -> void:
	_put(ShopArt.candy_wall(), CANDY_X, WALL_BASE, 1.0, "floor")
	_wall_label("BONBONS", Vector2(CANDY_X + 240.0, WALL_BASE - 440.0 + 32.0), 26, Color.WHITE, Color("#C84A72"))
	_put(ShopArt.chips_gondola(), CHIPS_X, 652.0, 0.85, "floor")
	for f in ShopArt.CHIPS.size():
		var cell := Vector2(CHIPS_X + (3.0 + f * 72.0 + 35.0) * 0.85, 652.0 - 240.0 * 0.85 + 17.0)
		_wall_label(ShopArt.CHIPS[f].short, cell, 8, Color.WHITE, Color(Color(ShopArt.CHIPS[f].bag).darkened(0.45)), 2)
	_hang(CHIPS_X + 187.0 - 68.0, "CHIPS", Color("#E8A62A"))
	_put(ShopArt.drinks_fridge(), FRIDGE_X, WALL_BASE, 1.0, "floor")
	_glow(Vector2(FRIDGE_X + 220.0, 330.0), 300.0, Color(0.8, 0.92, 1.0, 0.1))
	_hang(FRIDGE_X + 220.0 - 68.0, "BOISSONS", Color("#2E86C1"))
	_put(ShopArt.milk_cooler(), DAIRY_X, WALL_BASE, 1.0, "floor")
	_wall_label("PRODUITS LAITIERS", Vector2(DAIRY_X + 220.0, WALL_BASE - 480.0 + 26.0), 18, Color.WHITE, Color("#1D4F91"))
	_glow(Vector2(DAIRY_X + 220.0, 330.0), 300.0, Color(0.85, 0.95, 1.0, 0.1))
	_put(ShopArt.coffee_station(), COFFEE_X, 606.0, 0.95, "floor")
	_wall_label("CAFÉ  •  CHOCOLAT CHAUD", Vector2(COFFEE_X + 133.0, 330.0), 15, Color("#5A3A22"), Color("#F4E3C8"))
	# A fruit stand by the entrance, flowers and a card rack by the counter, a gumball machine and a water cooler at the back:
	# each in its place with room around it.
	_put(ShopArt.produce_crates(), 540.0, 646.0, 0.78, "floor")
	_put(ShopArt.flower_bucket(), 1350.0, 646.0, 0.9, "floor")
	_put(ShopArt.spinner_rack(), 1450.0, 640.0, 0.95, "floor")
	_put(ShopArt.gumball_machine(), 3680.0, 640.0, 0.9, "floor")
	_put(ShopArt.water_cooler(), 3790.0, 640.0, 0.95, "floor")
	_put(ShopArt.exit_sign(), SHOP.y - 150.0, 158.0)
	_glow(Vector2(SHOP.y - 110.0, 138.0), 70.0, Color(0.3, 1.0, 0.5, 0.25))


# Panels in the ceiling with a clean white light on the walls and the pale floor.
func _build_lighting() -> void:
	for x in TUBES:
		var panel := Sprite2D.new()
		panel.texture = ShopArt.panel_light()
		panel.centered = false
		panel.position = Vector2(x - 70.0, 5.0)
		add_child(panel)
		var cone := Polygon2D.new()
		cone.polygon = PackedVector2Array([Vector2(x - 56.0, CEILING), Vector2(x + 56.0, CEILING), Vector2(x + 230.0, 640.0), Vector2(x - 230.0, 640.0)])
		cone.vertex_colors = PackedColorArray([Color(1, 1, 0.97, 0.06), Color(1, 1, 0.97, 0.06), Color(1, 1, 0.97, 0.0), Color(1, 1, 0.97, 0.0)])
		var add_mat := CanvasItemMaterial.new()
		add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		cone.material = add_mat
		add_child(cone)
		_glow(Vector2(x, CEILING + 30.0), 320.0, Color(1.0, 0.99, 0.95, 0.18))
	_daylight(Vector2(DOOR_X + 40.0, 180.0), 130.0, 0.12)


func _build_spots() -> void:
	# The door: back out onto Rue Holt (Transition.street_x, set on the way in, puts her at the shop door).
	add_child(DoorSpot.make(Rect2(DOOR_X + 20.0, 170, 170, 430), func():
		_control.enabled = false
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/holt.tscn"), DOOR_X + 110.0))
	add_child(DoorSpot.make(Rect2(COUNTER_X + 270.0, 300, 110, 160), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 230.0)
		_hello += 1, COUNTER_X + 330.0 - 80.0))
	add_child(DoorSpot.make(Rect2(CANDY_X, 160, 480, 285), func():
		_buy(ShopArt.treat("candy" if randf() < 0.5 else "lollipop"), "Des bonbons !", 0.25), CANDY_X + 240.0))
	add_child(DoorSpot.make(Rect2(CHIPS_X, 448, 374, 204), func():
		_buy_chips(), CHIPS_X + 187.0))
	add_child(DoorSpot.make(Rect2(COFFEE_X, 340, 266, 266), func():
		_buy(ShopArt.treat("chocolate"), "Un chocolat chaud !", 1.25), COFFEE_X + 133.0))
	add_child(DoorSpot.make(Rect2(FRIDGE_X, 120, 440, 360), func():
		_buy(ShopArt.treat("juice"), "Un jus !", 1.5), FRIDGE_X + 220.0))
	add_child(DoorSpot.make(Rect2(DAIRY_X, 120, 440, 480), func():
		_buy_milk(), DAIRY_X + 220.0))
	add_child(QuestMark.make(Vector2(DAIRY_X + 220.0, 100.0), func() -> bool:
		return Quests.active("milk") and not Carry.has("milk")))
