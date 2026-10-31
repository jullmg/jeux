extends Interior
# ══════════════════════════════════════════════════════════════
# Inside dépanneur Xin-Xin (Rue Dandurand), as a side-on cross-section: the door with its bell, the newspaper
# rack, the counter with the till and the shopkeeper, the candy wall, chips, the freezer of ice pops and the
# drinks fridges, under fluorescent tubes, on a checkered floor. Click the shopkeeper to say hello; the candy,
# the freezer or the fridge to buy a treat; the door to go back out onto Dandurand.
# Usage: Godot --path . res://scenes/depanneur.tscn -- --screenshot=/tmp/dep.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const SHOP := Vector2(0, 3200)
const DOOR_X := 60.0
const COUNTER_X := 700.0
const CANDY_X := 1360.0
const CHIPS_X := 1880.0
const FREEZER_X := 2300.0
const FRIDGE_X := 2680.0
const TUBES: Array[float] = [420.0, 1000.0, 1640.0, 2280.0, 2900.0]
const HELLOS := ["Bonjour Charlotte !", "Bienvenue au dépanneur !", "Il fait beau aujourd'hui !", "Tu veux des bonbons ?"]

var _clerk: Character
var _hello := 0


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": SHOP.x, "to": SHOP.y, "wall": Color("#EEE6D0"), "base": Color("#8E948A")}]
	shell.floor_style = "tiles"
	shell.gleams = TUBES
	add_child(shell)
	_build_shop()
	_spawn_charlotte(DOOR_X + 240.0)
	_build_spots()
	_enter_area(SHOP)
	_finish([[900.0, "plant"], [2600.0, "plant"]])
	Sfx.play("bell")


func _build_shop() -> void:
	for x in TUBES:
		_tube(x)
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	_put(ShopArt.newspaper_rack(), DOOR_X + 250.0, 606.0, 0.9, "floor")
	if Season.current == "autumn":
		_put(ShopArt.halloween_display(), DOOR_X + 400.0, 612.0, 0.9, "floor")
	# Behind the counter: a lottery poster, the "OUVERT" sign, and the shopkeeper.
	_put(ShopArt.lotto_poster(), COUNTER_X + 110.0, 330.0, 0.8, "wall")
	_wall_label("LOTO", Vector2(COUNTER_X + 174.0, 196.0), 22, Color("#FFD23F"), Color("#16285C"))
	_wall_label("OUVERT", Vector2(COUNTER_X + 420.0, 180.0), 30, Color("#FF5D8F"), Color("#7A1030"))
	_glow(Vector2(COUNTER_X + 420.0, 180.0), 110.0, Color(1.0, 0.3, 0.55, 0.35))
	_clerk = Character.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2891
	_clerk.look = CharacterLook.random(rng, "adult")
	_clerk.look.outfit = "sweater"
	_clerk.look.outfit_color = Color("#25408F")
	_clerk.look.hat = ""
	_clerk.scale = Vector2.ONE * CHAR_SCALE
	# On the raised floor behind the counter, so she shows above it.
	_clerk.position = Vector2(COUNTER_X + 280.0, 556.0)
	_clerk.facing = 1
	add_child(_clerk)
	_put(ShopArt.counter(), COUNTER_X, 616.0, 1.0, "floor")
	_put(ShopArt.candy_wall(), CANDY_X, WALL_BASE, 1.0, "floor")
	_wall_label("BONBONS", Vector2(CANDY_X + 240.0, WALL_BASE - 440.0 + 32.0), 26, Color.WHITE, Color("#C84A72"))
	_put(ShopArt.chips_shelf(), CHIPS_X, WALL_BASE, 1.0, "floor")
	_put(ShopArt.drinks_fridge(), FRIDGE_X, WALL_BASE, 1.0, "floor")
	_glow(Vector2(FRIDGE_X + 220.0, 330.0), 280.0, Color(0.8, 0.92, 1.0, 0.25))
	_put(ShopArt.freezer(), FREEZER_X, 640.0, 1.0, "floor")


# A long fluorescent tube on the ceiling, and its cool glow.
func _tube(x: float) -> void:
	var tube := Polygon2D.new()
	tube.polygon = PackedVector2Array([Vector2(-110, 0), Vector2(110, 0), Vector2(104, 14), Vector2(-104, 14)])
	tube.color = Color("#F8FBFF")
	tube.position = Vector2(x, CEILING)
	add_child(tube)
	_glow(Vector2(x, CEILING + 30.0), 300.0, Color(0.95, 0.98, 1.0, 0.2))


func _wall_label(text: String, center: Vector2, size: int, color: Color, outline: Color) -> void:
	var label := Label.new()
	label.text = text
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 5
	settings.outline_color = outline
	label.label_settings = settings
	label.size = Vector2(240, 40)
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
	add_child(DoorSpot.make(Rect2(COUNTER_X + 230.0, 300, 100, 150), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 250.0)
		_hello += 1, COUNTER_X + 420.0))
	add_child(DoorSpot.make(Rect2(CANDY_X, 160, 480, 440), func():
		_buy(ShopArt.treat("candy" if randf() < 0.5 else "lollipop"), "Des bonbons !"), CANDY_X + 240.0))
	add_child(DoorSpot.make(Rect2(FREEZER_X, 470, 320, 170), func():
		_buy(ShopArt.treat("popsicle"), "Un popsicle !"), FREEZER_X + 160.0))
	add_child(DoorSpot.make(Rect2(FRIDGE_X, 120, 440, 480), func():
		_buy(ShopArt.treat("juice"), "Un jus !"), FRIDGE_X + 220.0))


# She picks something; the shopkeeper thanks her.
func _buy(picture: Texture2D, text: String) -> void:
	_treat(picture, text)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): _say(_clerk, "Merci, bonne journée !", 250.0))

