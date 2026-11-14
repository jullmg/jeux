extends Shop
# ══════════════════════════════════════════════════════════════
# Inside Fraîchement Bon, the fruiterie and fine grocery on Rue Masson (2903, at the 6e Avenue corner, north side), as a
# side-on cross-section. Warm wood and deep green under pendant lamps: flowers by the door, tiered stands of crates heaped with
# the season's fruit and vegetables under chalk price cards, the misted wall rack of greens, the bread basket, the bulk bins of
# nuts and dried fruit, the shelves of the fine grocery (jams, olive oils, pasta, sauces, fine chocolate), the cheese and
# charcuterie counter, and the till with the cashier in her green apron.
# Click the cashier to say hello; a stand, the rack, the bread, the bulk bins, the shelves or the cheese to buy something; the
# door to go back out onto Masson.
# Usage: Godot --path . res://scenes/fraichement_bon.tscn -- --screenshot=/tmp/fb.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const SHOP := Vector2(0, 4700)
const DOOR_X := 60.0
const TILL_X := 380.0
const STANDS: Array[float] = [1080.0, 1560.0, 2040.0]
const RACK_X := 2540.0
const BREAD_X := 1100.0
const BULK_X := 3500.0
const SHELF_X := 3500.0
const CHEESE_X := 3920.0
const LAMPS: Array[float] = [400.0, 1150.0, 2300.0, 3050.0, 3800.0, 4450.0]
const HELLOS := ["Bonjour ma belle !", "As-tu goûté nos clémentines ?", "Tout est frais d'à matin !", "Bonne journée !"]

var _hello := 0


func _ready() -> void:
	var shell := RoomShell.new()
	shell.rooms = [{"from": SHOP.x, "to": SHOP.y, "wall": Color("#EFE6D6"), "base": Color("#1E4A32"), "wainscot": Color("#7A5236"),
		"wainscot_height": 160.0}]
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#B5704A"), Color("#A86644")]
	shell.gleams = LAMPS
	add_child(shell)
	_build_entrance()
	_build_till()
	_build_produce()
	_build_grocery()
	_build_lighting()
	_add_customers(3, [900.0, 1400.0, 1900.0, 2400.0, 2900.0, 3400.0, 3900.0], 57)
	_spawn_charlotte(DOOR_X + 260.0)
	_build_spots()
	_enter_area(SHOP)
	_finish([[1300.0, "basket"], [3000.0, "basket"]])
	Sfx.play("bell")


func _music() -> Array:
	return ["fraichement-bon", "depanneur", "street_" + Season.current, "street"]


# The door, baskets, flowers in their buckets, the shop's name painted along the wall.
func _build_entrance() -> void:
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	_put(ShopArt.baskets_stack(), 300.0, 640.0, 0.9, "floor")
	_put(ShopArt.flower_bucket(), 860.0, 646.0, 0.95, "floor")
	_put(ShopArt.flower_bucket(), 960.0, 646.0, 0.85, "floor")
	_wall_label("FRAÎCHEMENT BON", Vector2(1800.0, 250.0), 34, Color("#F4F1EA"), Color("#1E4A32"), 8)
	_wall_label("Votre fruiterie de quartier", Vector2(1800.0, 296.0), 18, Color("#1E4A32"), Color("#F4F1EA"), 4)


# The till near the door and the cashier in her green apron.
func _build_till() -> void:
	_clerk = Character.new()
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#E8B896")
	look.hair_style = "ponytail"
	look.hair_color = Color("#8A5A2E")
	look.eye_color = Color("#3F9B45")
	look.mouth = "smile"
	look.outfit = "overalls"
	look.outfit_color = Color("#1E4A32")
	look.accent_color = Color("#F4F1EA")
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#3A3A44")
	look.shoes = "sneaker"
	look.shoe_color = Color("#F4F1EA")
	_clerk.look = look
	_clerk.scale = Vector2.ONE * CHAR_SCALE * 1.04
	_clerk.position = Vector2(TILL_X + 520.0, 556.0)
	_clerk.fidgets = true
	_clerk.fidget_moves = ["look", "look", "stretch"]
	add_child(_clerk)
	_put(ShopArt.modern_counter(), TILL_X, 616.0, 1.0, "floor")


# Three stands of crates, then the misted wall rack of greens.
func _build_produce() -> void:
	for i in STANDS.size():
		_put(FreshArt.produce_stand(11 + i), STANDS[i], 640.0, 1.05, "floor")
	_put(FreshArt.wall_rack(21), RACK_X, WALL_BASE, 1.0, "wall")
	_wall_label("FRUITS ET LÉGUMES", Vector2(RACK_X + 450.0, WALL_BASE - 440.0), 22, Color("#F4F1EA"), Color("#1E4A32"), 6)
	_put(FreshArt.bread(31), BREAD_X - 260.0, 640.0, 0.8, "floor")


# The fine grocery: bulk bins, the wooden shelves, the cheese counter.
func _build_grocery() -> void:
	_put(FreshArt.fine_shelves(41), SHELF_X - 100.0, WALL_BASE, 1.0, "wall")
	_wall_label("ÉPICERIE FINE", Vector2(SHELF_X + 200.0, WALL_BASE - 450.0), 20, Color("#F4F1EA"), Color("#1E4A32"), 0)
	_put(FreshArt.bulk_bins(51), SHELF_X - 380.0, 640.0, 0.9, "floor")
	_put(FreshArt.cheese_counter(61), CHEESE_X, 640.0, 1.0, "floor")
	_wall_label("FROMAGES  ·  CHARCUTERIES", Vector2(CHEESE_X + 350.0, 560.0), 18, Color("#F4F1EA"), Color("#6E4A2A"), 0)


# Warm pendant lamps over everything.
func _build_lighting() -> void:
	for x in LAMPS:
		# Interior._pendant brings its own warm glow.
		_pendant(x, 110.0)
	_daylight(Vector2(DOOR_X + 40.0, 180.0), 130.0, 0.14)


func _build_spots() -> void:
	add_child(DoorSpot.make(Rect2(DOOR_X + 20.0, 170, 170, 430), func():
		_control.enabled = false
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/masson_impair.tscn"), DOOR_X + 110.0))
	add_child(DoorSpot.make(Rect2(TILL_X + 470.0, 300, 110, 160), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 230.0)
		_hello += 1, TILL_X + 420.0))
	var seasonal: Array = _seasonal()
	for i in STANDS.size():
		var x := STANDS[i]
		add_child(DoorSpot.make(Rect2(x, 340, 440, 300), func():
			var c: Array = seasonal[randi() % seasonal.size()]
			_buy(FreshArt.item(c[0]), c[1], c[2]), x + 220.0))
	add_child(DoorSpot.make(Rect2(RACK_X, 180, 900, 420), func():
		_buy(FreshArt.item("carrot"), "Des carottes croquantes !", 1.49), RACK_X + 450.0))
	add_child(DoorSpot.make(Rect2(BREAD_X - 260.0, 460, 240, 180), func():
		_buy(FreshArt.item("baguette"), "Une baguette toute chaude !", 3.49), BREAD_X - 140.0))
	add_child(DoorSpot.make(Rect2(SHELF_X - 380.0, 400, 330, 240), func():
		_buy(FreshArt.item("nuts"), "Un petit sac de noix !", 2.99), SHELF_X - 220.0))
	add_child(DoorSpot.make(Rect2(SHELF_X - 100.0, 130, 600, 470), func():
		_buy(FreshArt.item("chocolate"), "Une tablette de chocolat fin !", 3.99, "chocolate"), SHELF_X + 200.0))
	add_child(DoorSpot.make(Rect2(CHEESE_X, 340, 700, 300), func():
		_buy(FreshArt.item("cheese"), "Un morceau de fromage !", 4.99), CHEESE_X + 350.0))


# What the stands give, by season (always fruit she'd eat).
func _seasonal() -> Array:
	var base := [["apple", "Une belle pomme rouge !", 0.99], ["banana", "Une banane !", 0.49], ["orange", "Une orange !", 0.99]]
	match Season.current:
		"winter":
			base.append(["clementine", "Des clémentines !", 3.99])
		"spring", "summer":
			base.append(["strawberry", "Un casseau de fraises !", 4.99])
		_:
			base.append(["grapes", "Une grappe de raisins !", 2.99])
	return base
