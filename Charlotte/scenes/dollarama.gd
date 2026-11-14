extends Shop
# ══════════════════════════════════════════════════════════════
# Inside the Dollarama on Rue Masson (2836, at the 5e Avenue corner, south side), as a side-on cross-section. A big bright
# store of long parallel aisles (Julien: several aisles, faithful to what it sells): the glass door, carts and baskets, the
# checkouts with their cashier, then the ends of the six aisles, each with its green and yellow hanging sign and, between the
# ends, the aisle itself running back. Walk up to an aisle and go in (click it or ↑): inside, she walks along one long gondola
# stocked with that department — party, kitchen, cleaning, candy and snacks, toys and school, the season's things — and can
# buy something (everything at most 5 $); the near gondola is the blurred foreground. Back out at either end of the aisle.
# Usage: Godot --path . res://scenes/dollarama.tscn -- --screenshot=/tmp/dollarama.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const FRONT := Vector2(0, 5900)
const DOOR_X := 60.0
const CHECK_X := 560.0
const AISLE0 := 1820.0
const PERIOD := 620.0
const END_W := 260.0
const MOUTH_W := 360.0
## Each aisle's own area, far to the right of the front of the store.
const AISLE_AREA0 := 7000.0
const AISLE_STRIDE := 3600.0
const AISLE_LEN := 3000.0
const HELLOS := ["Bonjour !", "Tu cherches quelque chose ?", "Tout est à cinq piasses ou moins, ma belle !", "Bonne journée !"]

## What she can buy in each aisle: [picture kind, what she says, price, kind kept in her stash or ""].
const BUYS := {
	"fete": [["balloons", "Des ballons !", 2.0, ""], ["giftbag", "Un sac-cadeau !", 1.5, ""], ["hats", "Des chapeaux de fête !", 1.5, ""]],
	"cuisine": [["mug", "Une tasse pour Maman !", 2.5, ""], ["containers", "Des petits plats pour mes lunchs !", 2.0, ""]],
	"entretien": [["sponges", "Des éponges pour aider Papa !", 1.25, ""], ["spray", "Du nettoyant qui sent bon !", 1.5, ""]],
	"bonbons": [["candybag", "Un sac de bonbons !", 1.5, "wrapped"], ["bars", "Une tablette de chocolat !", 1.5, "chocolate"],
		["chips", "Un sac de chips !", 1.5, "chips"]],
	"jouets": [["crayons", "Des crayons de cire !", 2.0, ""], ["balls", "Une balle rebondissante !", 1.25, ""],
		["notebooks", "Un cahier tout neuf !", 1.5, ""]],
}

var _hello := 0
var _tubes: Array[float] = []


func _ready() -> void:
	var rooms := [{"from": FRONT.x, "to": FRONT.y, "wall": Color("#F7F7F4"), "base": Color("#00843D")}]
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		rooms.append({"from": a.x, "to": a.y, "wall": Color("#F2F2EE"), "base": Color("#00843D")})
	var x := 300.0
	while x < FRONT.y:
		_tubes.append(x)
		x += 560.0
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		var tx := a.x + 300.0
		while tx < a.y:
			_tubes.append(tx)
			tx += 600.0
	var shell := RoomShell.new()
	shell.rooms = rooms
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#F4F3EE"), Color("#E2E1DB")]
	shell.ceiling_style = "drop"
	shell.gleams = _tubes
	add_child(shell)
	_build_front()
	_build_checkouts()
	_build_aisle_ends()
	for i in DollarArt.AISLES.size():
		_build_aisle(i)
	_build_lighting()
	_add_customers(3, [700.0, 1500.0, 2100.0, 2700.0, 3300.0, 3900.0, 4500.0, 5100.0], 41)
	_spawn_charlotte(DOOR_X + 260.0)
	_build_spots()
	# A screenshot or a debug run asked for an x in one of the aisles starts there.
	var start := FRONT
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		if _charlotte.position.x >= a.x and _charlotte.position.x <= a.y:
			start = a
	_enter_area(start)
	var fg := [[1200.0, "basket"], [3400.0, "basket"]]
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		var fx := a.x + 120.0
		var k := 0
		while fx < a.y - 100.0:
			fg.append([fx, "shelves", i * 31 + k])
			fx += 900.0
			k += 1
	_finish(fg)
	Sfx.play("bell")


func _music() -> Array:
	return ["dollarama", "depanneur", "street_" + Season.current, "street"]


func _aisle_area(i: int) -> Vector2:
	var x0 := AISLE_AREA0 + i * AISLE_STRIDE
	return Vector2(x0, x0 + AISLE_LEN)


func _mouth_x(i: int) -> float:
	return AISLE0 + i * PERIOD + END_W


## The plate at the top of the screen: the front of the store, or the aisle she is in.
func room_name() -> String:
	if _charlotte == null:
		return "Dollarama, rue Masson"
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		if _charlotte.position.x >= a.x and _charlotte.position.x <= a.y:
			return "Dollarama : allée %d, %s" % [i + 1, String(DollarArt.AISLES[i][1]).to_lower()]
	return "Dollarama, rue Masson"


# The glass door, the carts and baskets, the store's name in green along the wall.
func _build_front() -> void:
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	_put(ShopArt.shopping_cart(), 300.0, 640.0, 0.9, "floor")
	_put(ShopArt.baskets_stack(), 450.0, 640.0, 0.9, "floor")
	var logo := Sprite2D.new()
	logo.texture = load("res://art/brands/dollarama_logo.svg")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.scale = Vector2.ONE * 64.0 / logo.texture.get_height()
	logo.position = Vector2(1100.0, 140.0)
	add_child(logo)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(FRONT.x, 52), Vector2(FRONT.y, 52), Vector2(FRONT.y, 70), Vector2(FRONT.x, 70)])
	band.color = Color(DollarArt.GREEN)
	add_child(band)
	_wall_label("PRIX MAXIMUM 5 $", Vector2(1100.0, 210.0), 20, Color(DollarArt.GREEN_DARK), Color(DollarArt.YELLOW), 6)


# Two checkouts, the cashier at the first in the store's green vest, candy and gum racks by the till.
func _build_checkouts() -> void:
	_clerk = Character.new()
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = Color("#D9A57E")
	look.hair_style = "bun"
	look.hair_color = Color("#2A1A12")
	look.eye_color = Color("#3E2A1E")
	look.mouth = "smile"
	look.outfit = "sweater"
	look.outfit_color = Color(DollarArt.GREEN)
	look.accent_color = Color(DollarArt.YELLOW)
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B33")
	look.shoes = "sneaker"
	look.shoe_color = Color("#2B2B33")
	_clerk.look = look
	_clerk.scale = Vector2.ONE * CHAR_SCALE * 1.04
	_clerk.position = Vector2(CHECK_X + 520.0, 556.0)
	_clerk.fidgets = true
	_clerk.fidget_moves = ["look", "look", "stretch"]
	add_child(_clerk)
	_put(ShopArt.modern_counter(), CHECK_X, 616.0, 1.0, "floor")
	_put(ShopArt.modern_counter(), CHECK_X + 640.0, 616.0, 0.9, "floor")
	_put(ShopArt.spinner_rack(), CHECK_X + 520.0 + 160.0, 640.0, 0.85, "floor")
	_put(ShopArt.gumball_machine(), 1640.0, 640.0, 0.85, "floor")
	_wall_label("CAISSE 1", Vector2(CHECK_X + 300.0, 300.0), 16, Color.WHITE, Color(DollarArt.GREEN), 4)
	_wall_label("CAISSE 2", Vector2(CHECK_X + 900.0, 300.0), 16, Color.WHITE, Color(DollarArt.GREEN), 4)


# Along the front: each aisle's stocked end, then the aisle running back, its number and department on a hanging sign.
func _build_aisle_ends() -> void:
	for i in DollarArt.AISLES.size():
		var theme: String = DollarArt.AISLES[i][0]
		var ex := AISLE0 + i * PERIOD
		_put(DollarArt.aisle_mouth(MOUTH_W, 70 + i), _mouth_x(i), WALL_BASE)
		_put(DollarArt.endcap(theme, 90 + i), ex, WALL_BASE, 1.0, "floor")
		_aisle_sign(_mouth_x(i) + MOUTH_W / 2.0, i)
	_put(DollarArt.endcap("saison", 99), AISLE0 + DollarArt.AISLES.size() * PERIOD, WALL_BASE, 1.0, "floor")


# Inside an aisle: one long gondola of its department, its sign over the middle, the way out at both ends.
func _build_aisle(i: int) -> void:
	var a := _aisle_area(i)
	var theme: String = DollarArt.AISLES[i][0]
	_put(DollarArt.gondola(theme, AISLE_LEN - 200.0, 300 + i), a.x + 100.0, WALL_BASE, 1.0, "floor")
	_aisle_sign((a.x + a.y) / 2.0, i)
	for side: float in [-1.0, 1.0]:
		var ax := a.x + 50.0 if side < 0.0 else a.y - 50.0
		_wall_label("← SORTIE" if side < 0.0 else "SORTIE →", Vector2(ax + side * -10.0, 110.0), 14, Color.WHITE, Color(DollarArt.GREEN), 4)


# A Dollarama aisle sign hanging from the ceiling grid: a green board, the aisle's number in a yellow disc, its department.
func _aisle_sign(cx: float, i: int) -> void:
	var top := 96.0
	var w := 300.0
	for dx: float in [-w * 0.35, w * 0.35]:
		var chain := Line2D.new()
		chain.points = PackedVector2Array([Vector2(cx + dx, CEILING), Vector2(cx + dx, top)])
		chain.width = 2.0
		chain.default_color = Color("#8E9196")
		add_child(chain)
	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(cx - w / 2.0, top), Vector2(cx + w / 2.0, top), Vector2(cx + w / 2.0, top + 60.0), Vector2(cx - w / 2.0, top + 60.0)])
	board.color = Color(DollarArt.GREEN)
	add_child(board)
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([Vector2(cx - w / 2.0, top + 54.0), Vector2(cx + w / 2.0, top + 54.0), Vector2(cx + w / 2.0, top + 60.0), Vector2(cx - w / 2.0, top + 60.0)])
	lip.color = Color(DollarArt.GREEN_DARK)
	add_child(lip)
	var disc := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 24:
		pts.append(Vector2(cx - w / 2.0 + 34.0, top + 30.0) + Vector2.from_angle(TAU * k / 24.0) * 22.0)
	disc.polygon = pts
	disc.color = Color(DollarArt.YELLOW)
	add_child(disc)
	_wall_label(str(i + 1), Vector2(cx - w / 2.0 + 34.0, top + 30.0), 24, Color(DollarArt.GREEN_DARK), Color(0, 0, 0, 0), 0)
	_wall_label(DollarArt.AISLES[i][1], Vector2(cx + 22.0, top + 28.0), 17 if String(DollarArt.AISLES[i][1]).length() < 14 else 13, Color.WHITE, Color(DollarArt.GREEN_DARK), 3)


func _build_lighting() -> void:
	for x in _tubes:
		var panel := Sprite2D.new()
		panel.texture = ShopArt.panel_light()
		panel.centered = false
		panel.position = Vector2(x - 70.0, 5.0)
		add_child(panel)
		_glow(Vector2(x, CEILING + 30.0), 340.0, Color(1.0, 1.0, 0.97, 0.2))
	_daylight(Vector2(DOOR_X + 40.0, 180.0), 130.0, 0.12)


func _build_spots() -> void:
	# The door: back out onto Masson (Transition.street_x, set on the way in, puts her at the shop door).
	add_child(DoorSpot.make(Rect2(DOOR_X + 20.0, 170, 170, 430), func():
		_control.enabled = false
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/masson_pair.tscn"), DOOR_X + 110.0))
	add_child(DoorSpot.make(Rect2(CHECK_X + 270.0, 300, 110, 160), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 230.0)
		_hello += 1, CHECK_X + 330.0 - 80.0))
	for i in DollarArt.AISLES.size():
		var a := _aisle_area(i)
		var mx := _mouth_x(i) + MOUTH_W / 2.0
		var area := a
		# Into the aisle from its mouth.
		add_child(DoorSpot.make(Rect2(_mouth_x(i) + 20.0, 150, MOUTH_W - 40.0, 450), func():
			_go_through(area.x + 260.0, area, 1), mx))
		# Out again at either end, back at its mouth.
		for side: float in [-1.0, 1.0]:
			var ex := a.x + 40.0 if side < 0.0 else a.y - 200.0
			add_child(DoorSpot.make(Rect2(ex, 120, 160, 480), func():
				_go_through(mx, FRONT, 1 if side > 0.0 else -1), ex + 80.0))
		# What there is to buy along it: each click picks one of the department's things.
		var theme: String = DollarArt.AISLES[i][0]
		var choices: Array = BUYS.get(theme, _season_buys())
		add_child(DoorSpot.make(Rect2(a.x + 260.0, 140, AISLE_LEN - 520.0, 460), func():
			var c: Array = choices[randi() % choices.size()]
			_buy(DollarArt.item(c[0]), c[1], c[2], c[3]), (a.x + a.y) / 2.0))


# The season aisle: what it holds now.
func _season_buys() -> Array:
	match Season.current:
		"winter":
			return [["ornaments", "Des boules de Noël !", 3.0, ""], ["candybag", "Des bonbons de Noël !", 1.5, "wrapped"]]
		"spring":
			return [["eggs", "Des œufs en plastique !", 2.5, ""], ["candybag", "Des bonbons de Pâques !", 1.5, "wrapped"]]
		"summer":
			return [["beachballs", "Un ballon de plage !", 2.5, ""], ["balls", "Une balle !", 1.25, ""]]
	return [["pumpkins", "Une citrouille en plastique !", 3.0, ""], ["masks", "Un masque d'Halloween !", 4.0, ""],
		["candybag", "Des bonbons d'Halloween !", 1.5, "wrapped"]]
