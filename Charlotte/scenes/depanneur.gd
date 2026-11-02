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
const CHIPS_X := 1540.0
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
	_build_frieze()
	_build_walls()
	_build_counter()
	_build_aisles()
	_build_coolers()
	_build_extras()
	_build_lighting()
	_spawn_charlotte(DOOR_X + 240.0)
	_build_spots()
	_enter_area(SHOP)
	_finish([[640.0, "basket"], [1900.0, "basket"], [3100.0, "basket"]])
	Sfx.play("bell")


func _music() -> Array:
	return ["depanneur", "street_" + Season.current, "street"]


# The door, the cash machine, the newspapers, the Halloween crate, posters and the light panels.
func _build_walls() -> void:
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
	var neon := NeonSign.new()
	neon.lines = ["OUVERT"]
	neon.color = Color("#FF4F8B")
	neon.font_size = 30
	neon.tilt = -0.03
	neon.position = Vector2(COUNTER_X + 640.0, 112.0)
	add_child(neon)
	_glow(Vector2(COUNTER_X + 640.0, 120.0), 130.0, Color(1.0, 0.3, 0.55, 0.3))
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
	look.eyes = "almond"
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
	var cat := _LuckyCat.new()
	cat.position = Vector2(COUNTER_X + 52.0, 616.0 - 240.0 + 70.0)
	add_child(cat)
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
	_put(ShopArt.chips_gondola(), CHIPS_X, 652.0, 0.85, "floor")
	for f in ShopArt.CHIPS.size():
		var cell: Vector2 = Vector2(CHIPS_X + (3.0 + f * 72.0 + 35.0) * 0.85, 652.0 - 240.0 * 0.85 + 17.0)
		_wall_label(ShopArt.CHIPS[f].short, cell, 8, Color.WHITE, Color(Color(ShopArt.CHIPS[f].bag).darkened(0.45)), 2)
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
	_glow(Vector2(FRIDGE_X + 220.0, 330.0), 300.0, Color(0.8, 0.92, 1.0, 0.1))
	_put(ShopArt.milk_cooler(), DAIRY_X, WALL_BASE, 1.0, "floor")
	_wall_label("PRODUITS LAITIERS", Vector2(DAIRY_X + 220.0, WALL_BASE - 480.0 + 26.0), 18, Color.WHITE, Color("#1D4F91"))
	_glow(Vector2(DAIRY_X + 220.0, 330.0), 300.0, Color(0.85, 0.95, 1.0, 0.1))


# A red band with a white thread round the top of the walls, under the ceiling grid: the shop's colours.
func _build_frieze() -> void:
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(SHOP.x, 46), Vector2(SHOP.y, 46), Vector2(SHOP.y, 60), Vector2(SHOP.x, 60)])
	band.color = Color("#C8202A")
	add_child(band)
	var thread := Polygon2D.new()
	thread.polygon = PackedVector2Array([Vector2(SHOP.x, 60), Vector2(SHOP.y, 60), Vector2(SHOP.y, 64), Vector2(SHOP.x, 64)])
	thread.color = Color("#F4F2EC")
	add_child(thread)
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(SHOP.x, 64), Vector2(SHOP.y, 64), Vector2(SHOP.y, 94), Vector2(SHOP.x, 94)])
	shade.vertex_colors = PackedColorArray([Color(0.2, 0.1, 0.04, 0.14), Color(0.2, 0.1, 0.04, 0.14), Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.0)])
	add_child(shade)
	var glint := Polygon2D.new()
	glint.polygon = PackedVector2Array([Vector2(SHOP.x, 46), Vector2(SHOP.y, 46), Vector2(SHOP.y, 50), Vector2(SHOP.x, 50)])
	glint.color = Color(1, 1, 1, 0.22)
	add_child(glint)


# Everything that makes the walls and the floor of a real corner store: stock on high shelves, hanging aisle signs,
# the emergency exit, the extinguisher, the bulletin board, security cameras, baskets and a wet-floor sign.
func _build_extras() -> void:
	for at in [[290.0, 1], [1975.0, 2], [2385.0, 3]]:
		_put(ShopArt.high_shelf(at[1]), at[0], 186.0, 1.0, "wall")
	_hang(CHIPS_X + 187.0 - 68.0, "CHIPS", Color("#E8A62A"))
	_hang(FRIDGE_X + 220.0 - 68.0, "BOISSONS", Color("#2E86C1"))
	_put(ShopArt.exit_sign(), STOCK_X + 45.0, 140.0)
	_glow(Vector2(STOCK_X + 85.0, 120.0), 70.0, Color(0.3, 1.0, 0.5, 0.25))
	_put(ShopArt.fire_extinguisher(), 1395.0, 560.0, 1.0, "wall")
	_put(ShopArt.bulletin_board(), 592.0, 398.0, 0.72, "wall")
	for x in [1300.0, 2700.0]:
		_put(ShopArt.camera_dome(), x - 30.0, 78.0)
		var led := _Blink.new()
		led.position = Vector2(x - 1.0, 62.0)
		add_child(led)
	_put(ShopArt.baskets_stack(), 1340.0, 640.0, 0.9, "floor")
	_put(ShopArt.wet_floor_sign(), 296.0, 652.0, 0.9, "floor")
	_floor_wear()


# A sign hanging by two chains from the ceiling grid, its words a label on the board.
func _hang(x: float, text: String, color: Color) -> void:
	var sc := 0.8
	_put(ShopArt.hanging_sign(color.to_html(false).insert(0, "#")), x, CEILING + 100.0 * sc - 6.0, sc)
	_wall_label(text, Vector2(x + 68.0 * sc * 1.0 - 8.0, CEILING + 100.0 * sc - 6.0 - 100.0 * sc + 67.0 * sc), 15, Color.WHITE, color.darkened(0.55), 3)


# Scuffs and grime on the tiles: dark where people walk in, in front of the counter and the fridges, a few streaks.
func _floor_wear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	for spot in [[DOOR_X + 130.0, 150.0], [COUNTER_X + 200.0, 190.0], [FRIDGE_X + 220.0, 220.0], [DAIRY_X + 220.0, 200.0], [CANDY_X + 240.0, 200.0]]:
		var smudge := Polygon2D.new()
		smudge.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(spot[1], 22.0), 0.0, 24)
		smudge.color = Color(0.2, 0.15, 0.1, 0.09)
		smudge.position = Vector2(spot[0], 676.0)
		add_child(smudge)
	for i in 34:
		var scuff := Line2D.new()
		var x := rng.randf_range(SHOP.x + 80.0, SHOP.y - 80.0)
		var y := rng.randf_range(640.0, 712.0)
		scuff.points = PackedVector2Array([Vector2(x, y), Vector2(x + rng.randf_range(10.0, 40.0), y + rng.randf_range(-2.0, 2.0))])
		scuff.width = rng.randf_range(1.0, 2.2)
		scuff.default_color = Color(0.25, 0.2, 0.15, rng.randf_range(0.06, 0.14))
		add_child(scuff)


# The ceiling's recessed panels with their light falling on the wall and floor, the cold glow of the fridges on the floor,
# the daylight through the door; one panel flickers now and then.
func _build_lighting() -> void:
	for i in TUBES.size():
		var x := TUBES[i]
		var panel := Sprite2D.new()
		panel.texture = ShopArt.panel_light()
		panel.centered = false
		panel.position = Vector2(x - 70.0, 5.0)
		add_child(panel)
		var cone := Polygon2D.new()
		cone.polygon = PackedVector2Array([Vector2(x - 56.0, CEILING), Vector2(x + 56.0, CEILING), Vector2(x + 230.0, 640.0), Vector2(x - 230.0, 640.0)])
		cone.vertex_colors = PackedColorArray([Color(1, 1, 0.96, 0.055), Color(1, 1, 0.96, 0.055), Color(1, 1, 0.96, 0.0), Color(1, 1, 0.96, 0.0)])
		var add_mat := CanvasItemMaterial.new()
		add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		cone.material = add_mat
		add_child(cone)
		var glow := _glow(Vector2(x, CEILING + 30.0), 320.0, Color(0.95, 0.98, 1.0, 0.2))
		var pool := Polygon2D.new()
		pool.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(210.0, 24.0), 0.0, 24)
		pool.color = Color(1, 1, 0.94, 0.07)
		pool.position = Vector2(x, 672.0)
		pool.material = add_mat
		add_child(pool)
		if i == 2:
			var flicker := _Flicker.new()
			flicker.targets = [panel, glow, cone]
			add_child(flicker)
	for x in [FRIDGE_X + 220.0, DAIRY_X + 220.0]:
		var cold := Polygon2D.new()
		cold.polygon = CritterDraw.ellipse_points(Vector2.ZERO, Vector2(260.0, 30.0), 0.0, 24)
		cold.color = Color(0.7, 0.88, 1.0, 0.1)
		cold.position = Vector2(x, 664.0)
		var cold_mat := CanvasItemMaterial.new()
		cold_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		cold.material = cold_mat
		add_child(cold)
	_daylight(Vector2(DOOR_X + 40.0, 180.0), 130.0, 0.12)


func _wall_label(text: String, center: Vector2, size: int, color: Color, outline: Color, outline_size := 5) -> void:
	var label := Label.new()
	label.text = text
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline_size
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
	add_child(DoorSpot.make(Rect2(CANDY_X, 160, 480, 285), func():
		_buy(ShopArt.treat("candy" if randf() < 0.5 else "lollipop"), "Des bonbons !", 0.25), CANDY_X + 240.0))
	add_child(DoorSpot.make(Rect2(CHIPS_X, 448, 374, 204), func():
		_buy_chips(), CHIPS_X + 187.0))
	add_child(DoorSpot.make(Rect2(SLUSH_X, 200, 190, 270), func():
		_buy(ShopArt.treat("slush"), "Une sloche !", 1.5), SLUSH_X + 95.0))
	add_child(DoorSpot.make(Rect2(COFFEE_X, 340, 266, 266), func():
		_buy(ShopArt.treat("chocolate"), "Un chocolat chaud !", 1.25), COFFEE_X + 133.0))
	add_child(DoorSpot.make(Rect2(FREEZER_X, 500, 290, 150), func():
		_buy(ShopArt.treat("popsicle"), "Un popsicle !", 1.0), FREEZER_X + 145.0))
	add_child(DoorSpot.make(Rect2(FRIDGE_X, 120, 440, 360), func():
		_buy(ShopArt.treat("juice"), "Un jus !", 1.5), FRIDGE_X + 220.0))
	add_child(DoorSpot.make(Rect2(DAIRY_X, 120, 440, 480), func():
		_buy_milk(), DAIRY_X + 220.0))
	# Mom's milk: a "!" over the dairy cooler while she still has to pick it up.
	add_child(QuestMark.make(Vector2(DAIRY_X + 220.0, 100.0), func() -> bool:
		return Quests.active("milk") and not GameState.flags.get("has_milk", false)))


# She picks something and pays from her pocket money; the shopkeeper thanks her (or tells her she's short).
func _buy(picture: Texture2D, text: String, price: float) -> void:
	if GameState.money < price - 0.001:
		_say(_clerk, "Il te manque des sous ! C'est %s." % Quests.money_text(price), 250.0, 3.0)
		Sfx.play("pop")
		return
	GameState.money -= price
	_treat(picture, "%s  − %s" % [text, Quests.money_text(price)])
	_thanks("Merci, bonne journée !")


# A bag of chips: one of the classic flavours, picked at random (or the one she looked at).
func _buy_chips() -> void:
	var f := randi() % ShopArt.CHIPS.size()
	_buy(ShopArt.chip_treat(f), "%s !" % String(ShopArt.CHIPS[f].said).capitalize(), 1.75)


# The bag of milk: Mom's money pays for it while she's on the "milk" quest; otherwise it's like anything else.
func _buy_milk() -> void:
	if Quests.active("milk") and not GameState.flags.get("has_milk", false):
		GameState.flags["has_milk"] = true
		_treat(ShopArt.treat("milk"), "Du lait pour Maman !")
		_thanks("Bonjour à ta maman !")
	else:
		_buy(ShopArt.treat("milk"), "Un sac de lait !", 5.49)


func _thanks(text: String) -> void:
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _say(_clerk, text, 250.0))


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


# A little lucky cat on the counter, its paw beckoning, a gold coin on its chest, a bell at its neck. Origin: the base.
class _LuckyCat:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var line := Color("#9A8F80")
		draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO)
		# The waving paw first (behind the head): it swings from the shoulder.
		var swing := sin(_t * 3.2) * 0.38
		var shoulder := Vector2(14, -42)
		var paw := shoulder + Vector2(sin(0.5 + swing), -cos(0.5 + swing)) * 26.0
		draw_line(shoulder, paw, line, 11.0, true)
		draw_line(shoulder, paw, Color("#FBFAF6"), 8.5, true)
		draw_circle(paw, 6.5, line)
		draw_circle(paw, 5.0, Color("#FBFAF6"))
		draw_circle(paw + Vector2(-1, 1), 1.6, Color("#F2A7B4"))
		# Body, a little left paw, the base.
		draw_rect(Rect2(-24, -12, 48, 12), Color("#C8202A"))
		draw_rect(Rect2(-24, -12, 48, 3), Color(1, 1, 1, 0.3))
		draw_circle(Vector2(0, -34), 24.0, line)
		draw_circle(Vector2(0, -34), 22.0, Color("#FBFAF6"))
		draw_circle(Vector2(-18, -22), 7.0, Color("#FBFAF6"))
		draw_arc(Vector2(-18, -22), 7.0, 0, TAU, 12, line, 1.5, true)
		draw_circle(Vector2(-6, -42), 7.0, Color(1, 1, 1, 0.35))
		# The gold coin on its belly.
		draw_circle(Vector2(0, -20), 9.0, Color("#C99410"))
		draw_circle(Vector2(0, -20), 7.6, Color("#F2C230"))
		draw_rect(Rect2(-2.5, -24, 5, 8), Color("#C99410"))
		# The head: ears, eyes closed in a smile, a pink nose, whiskers, a red collar and its bell.
		var head := Vector2(0, -62)
		for side in [-1.0, 1.0]:
			var ear := PackedVector2Array([head + Vector2(side * 8, -12), head + Vector2(side * 18, -26), head + Vector2(side * 19, -6)])
			draw_colored_polygon(ear, Color("#FBFAF6"))
			draw_colored_polygon(PackedVector2Array([head + Vector2(side * 11, -12), head + Vector2(side * 17, -22), head + Vector2(side * 17, -9)]), Color("#F2A7B4"))
		draw_circle(head, 20.0, line)
		draw_circle(head, 18.6, Color("#FBFAF6"))
		for side in [-1.0, 1.0]:
			draw_arc(head + Vector2(side * 8, -1), 4.0, PI + 0.4, TAU - 0.4, 8, Color("#3A3A3A"), 1.6, true)
			draw_circle(head + Vector2(side * 12, 5), 3.2, Color("#F7B9C4", 0.7))
			draw_line(head + Vector2(side * 12, 6), head + Vector2(side * 22, 4), Color("#9A8F80"), 1.0)
			draw_line(head + Vector2(side * 12, 8), head + Vector2(side * 22, 10), Color("#9A8F80"), 1.0)
		draw_circle(head + Vector2(0, 4), 2.0, Color("#E07F92"))
		draw_arc(head + Vector2(0, 6), 4.0, 0.3, PI - 0.3, 8, Color("#3A3A3A"), 1.2, true)
		draw_rect(Rect2(-14, -49, 28, 5), Color("#C8202A"))
		draw_circle(Vector2(0, -44), 4.0, Color("#F2C230"))
		draw_circle(Vector2(-1, -45), 1.2, Color("#FFF3B0"))


# A tiny red light that blinks, on a security camera.
class _Blink:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var on := fmod(_t, 1.6) < 0.25
		if on:
			draw_circle(Vector2.ZERO, 5.0, Color(1, 0.2, 0.2, 0.25))
			draw_circle(Vector2.ZERO, 2.0, Color(1, 0.35, 0.3))
		else:
			draw_circle(Vector2.ZERO, 1.6, Color(0.4, 0.1, 0.1))


# A tired fluorescent panel: now and then it stutters.
class _Flicker:
	extends Node
	var targets: Array = []
	var _next := 6.0
	var _left := 0.0

	func _process(delta: float) -> void:
		_next -= delta
		if _next <= 0.0 and _left <= 0.0:
			_left = 0.45
			_next = randf_range(9.0, 25.0)
		_left = maxf(_left - delta, 0.0)
		var dim := 0.25 if _left > 0.0 and int(_left * 40.0) % 3 != 0 else 1.0
		for t in targets:
			if is_instance_valid(t):
				t.modulate.a = dim
