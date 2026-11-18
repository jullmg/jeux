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

const FRONT := Vector2(0, 6400)
const DOOR_X := 60.0
## The storefront window right of the door, the two checkout lanes after it.
const WINDOW_X := 290.0
const WINDOW_W := 560.0
const CHECK_X := 900.0
const LANE_STEP := 600.0
const AISLE0 := 2340.0
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
## The cards hanging from the ceiling at the front: [x, words].
## Only over the front: along the aisle ends they'd hide the ends' price cards and the aisle signs.
const PROMOS := [[600.0, "PRIX MAXIMUM 5 $"], [1150.0, "NOUVEAUTÉS"], [2050.0, "AUBAINES DE LA SAISON"]]
## Who restocks the shelves, and in which aisle (index into DollarArt.AISLES), at what x along it.
const STOCKER_AISLE := 2
const STOCKER_AT := 1450.0


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
	_build_stocker()
	_build_lighting()
	_build_promos()
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


# The glass door, the storefront window with Masson outside and the store's stickers, the carts and baskets under it, the
# wall of shelves behind the checkouts with the store's sign over it, the green band under the ceiling.
func _build_front() -> void:
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	var window := _put(DollarArt.storefront(WINDOW_W), WINDOW_X, WALL_BASE)
	var logo_tex: Texture2D = load("res://art/brands/dollarama_logo.svg")
	var on_glass := Sprite2D.new()
	on_glass.texture = logo_tex
	on_glass.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	on_glass.scale = Vector2.ONE * 34.0 / logo_tex.get_height()
	on_glass.position = window.position + Vector2(170.0, 34.0)
	add_child(on_glass)
	var disc := window.position + Vector2(WINDOW_W - 90.0, 160.0)
	_wall_label("PRIX\nMAXIMUM", disc + Vector2(0.0, -24.0), 13, Color(DollarArt.GREEN_DARK), Color(0, 0, 0, 0), 0)
	_wall_label("5 $", disc + Vector2(0.0, 14.0), 34, Color(DollarArt.GREEN_DARK), Color.WHITE, 4)
	_put(ShopArt.shopping_cart(), 330.0, 646.0, 0.9, "floor")
	_put(ShopArt.shopping_cart(), 380.0, 652.0, 0.9)
	_put(ShopArt.baskets_stack(), 600.0, 646.0, 0.9, "floor")
	# Behind the checkouts, the wall stocked to the ceiling's band, the store's name big over it.
	_put(DollarArt.wall_shelves(1360.0, 7), CHECK_X - 20.0, WALL_BASE)
	var logo := Sprite2D.new()
	logo.texture = logo_tex
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.scale = Vector2.ONE * 72.0 / logo_tex.get_height()
	logo.position = Vector2(CHECK_X + 660.0, 172.0)
	add_child(logo)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(FRONT.x, 52), Vector2(FRONT.y, 52), Vector2(FRONT.y, 70), Vector2(FRONT.x, 70)])
	band.color = Color(DollarArt.GREEN)
	add_child(band)


# Two checkout lanes, the cashier at the first in the store's green, the first lane's light on, the second's off; a bouquet of
# helium balloons by the till (it bobs), the gumball machine.
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
	# Behind the end of the belt, between the scanner and the screen (which would hide her face).
	_clerk.position = Vector2(CHECK_X + 330.0, 556.0)
	_clerk.facing = -1
	_clerk.fidgets = true
	_clerk.fidget_moves = ["look", "look", "stretch"]
	add_child(_clerk)
	for lane in 2:
		var lx := CHECK_X + lane * LANE_STEP
		_put(DollarArt.checkout(11 + lane), lx, 616.0, 1.0, "floor")
		var light := Vector2(lx, 616.0 - 380.0) + DollarArt.LANE_LIGHT_AT
		if lane == 0:
			_glow(light, 60.0, Color(1.0, 0.95, 0.5, 0.5))
		_wall_label(str(lane + 1), light, 26, Color(DollarArt.YELLOW) if lane == 0 else Color("#6E7A72"), Color(DollarArt.GREEN_DARK), 3)
	var bouquet := _put(DollarArt.balloon_bouquet(), CHECK_X + 2.0 * LANE_STEP - 40.0, 652.0, 0.8)
	var bob := create_tween().set_loops()
	bob.tween_property(bouquet, "position:y", bouquet.position.y - 6.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(bouquet, "position:y", bouquet.position.y, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_put(ShopArt.gumball_machine(), AISLE0 - 100.0, 640.0, 0.85, "floor")


# The yellow cards hanging from the ceiling at the front, turning a little in the air of the door.
func _build_promos() -> void:
	for k in PROMOS.size():
		var promo: Array = PROMOS[k]
		var card := Node2D.new()
		card.position = Vector2(float(promo[0]), CEILING)
		add_child(card)
		for dx: float in [-80.0, 80.0]:
			var string := Line2D.new()
			string.points = PackedVector2Array([Vector2(dx, 0.0), Vector2(dx, 44.0)])
			string.width = 1.5
			string.default_color = Color("#9A9DA2")
			card.add_child(string)
		var art := Sprite2D.new()
		art.texture = DollarArt.promo_card()
		art.position = Vector2(0.0, 74.0)
		card.add_child(art)
		var words := Label.new()
		words.text = promo[1]
		words.size = Vector2(230, 40)
		words.position = Vector2(-115.0, 66.0)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		words.add_theme_font_size_override("font_size", 17 if String(promo[1]).length() < 18 else 14)
		words.add_theme_color_override("font_color", Color(DollarArt.GREEN_DARK))
		card.add_child(words)
		var sway := create_tween().set_loops()
		sway.tween_property(card, "rotation", 0.025, 2.2 + k * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway.tween_property(card, "rotation", -0.025, 2.2 + k * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Someone in the store's green restocking an aisle: a carton in their arms, a hand truck of boxes beside them.
func _build_stocker() -> void:
	var a := _aisle_area(STOCKER_AISLE)
	_put(ShopArt.hand_truck(), a.x + STOCKER_AT + 120.0, 650.0, 0.8, "floor")
	_put(ShopArt.box_stack(4), a.x + STOCKER_AT + 150.0, 646.0, 0.75, "floor")
	var who := Character.new()
	var look := CharacterLook.new()
	look.age = "teen"
	look.skin = Color("#F0C8A8")
	look.hair_style = "short"
	look.hair_color = Color("#6B4A2E")
	look.eye_color = Color("#4E7FA8")
	look.mouth = "smile"
	look.outfit = "tshirt"
	look.outfit_color = Color(DollarArt.GREEN)
	look.accent_color = Color(DollarArt.YELLOW)
	look.pattern = "none"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B33")
	look.shoes = "sneaker"
	look.shoe_color = Color("#E9EAEC")
	who.look = look
	who.scale = Vector2.ONE * CHAR_SCALE * 1.04
	who.position = Vector2(a.x + STOCKER_AT, FEET_Y - 4.0)
	who.facing = 1
	who.fidgets = true
	who.fidget_moves = ["look", "stretch"]
	add_child(who)
	var box := Sprite2D.new()
	box.texture = DollarArt.carton()
	box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	box.scale = Vector2.ONE * 2.2
	who.carry(box)


# Along the front: each aisle's stocked end, then the aisle running back, its number and department on a hanging sign.
func _build_aisle_ends() -> void:
	for i in DollarArt.AISLES.size():
		var theme: String = DollarArt.AISLES[i][0]
		var ex := AISLE0 + i * PERIOD
		_put(DollarArt.aisle_mouth(MOUTH_W, 70 + i), _mouth_x(i), WALL_BASE)
		_put(DollarArt.endcap(theme, 90 + i), ex, WALL_BASE, 1.0, "floor")
		# The yellow card on top of the end: this week's price.
		_wall_label(DollarArt.PRICES[(i * 5 + 1) % DollarArt.PRICES.size()], Vector2(ex + 130.0, WALL_BASE - 470.0 + 20.0), 22, Color(DollarArt.GREEN_DARK), Color(0, 0, 0, 0), 0)
		_aisle_sign(_mouth_x(i) + MOUTH_W / 2.0, i)
	_put(DollarArt.endcap("saison", 99), AISLE0 + DollarArt.AISLES.size() * PERIOD, WALL_BASE, 1.0, "floor")


# Inside an aisle: one long gondola of its department, its sign over the middle, the way out at both ends.
func _build_aisle(i: int) -> void:
	var a := _aisle_area(i)
	var theme: String = DollarArt.AISLES[i][0]
	var w := AISLE_LEN - 200.0
	var shelf := _put(DollarArt.gondola(theme, w, 300 + i), a.x + 100.0, WALL_BASE, 1.0, "floor")
	# The prices on the yellow flags sticking out of the shelves.
	for tk: Array in DollarArt.talkers(w):
		_wall_label(tk[2], shelf.position + Vector2(float(tk[0]), float(tk[1]) - 18.0), 16, Color(DollarArt.GREEN_DARK), Color(0, 0, 0, 0), 0)
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
	add_child(DoorSpot.make(Rect2(CHECK_X + 270.0, 280, 120, 190), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 230.0)
		_hello += 1, CHECK_X + 200.0))
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
