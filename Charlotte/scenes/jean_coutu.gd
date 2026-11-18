extends Shop
# ══════════════════════════════════════════════════════════════
# Inside the Jean Coutu on Rue Masson (2716, between 3e and 4e, south side), as a side-on cross-section, built like the
# Dollarama (Julien: several aisles, the same products as a real one). From the door: the storefront window on Masson, two
# checkouts and the photo counter; the cosmetics on warm wood, the heart of the store (its own pages say so), with their
# beauty island and an advisor; the dermo-cosmetics and the perfumes; then the ends of six numbered aisles, each running
# back (hair care, personal care, cold and pain, vitamins, baby, snacks); and at the back the pharmacy in plain sight, its
# laboratory behind the glass, two counters, the consultation room and the blood-pressure machine. Walk up to an aisle and
# go in (click it or ↑): one long gondola of its department, the near one blurred, out again at either end.
# Usage: Godot --path . res://scenes/jean_coutu.tscn -- --screenshot=/tmp/jc.png [--x=1234] [--wait=seconds]
# ══════════════════════════════════════════════════════════════

const FRONT := Vector2(0, 11400)
const DOOR_X := 60.0
const WINDOW_X := 290.0
const WINDOW_W := 560.0
const CHECK_X := 900.0
const LANE_STEP := 600.0
const PHOTO_X := 2110.0
const BEAUTY_X := 2440.0
const BEAUTY_END := 4240.0
const DERMO_X := 4260.0
const PERFUME_X := 4860.0
const AISLE0 := 5300.0
const PERIOD := 620.0
const END_W := 260.0
const MOUTH_W := 360.0
const LAB_X := 9640.0
const LAB_W := 1200.0
const CONSULT_X := 9420.0
const BP_X := 10900.0
## Each aisle's own area, far to the right of the front of the store.
const AISLE_AREA0 := 12000.0
const AISLE_STRIDE := 3600.0
const AISLE_LEN := 3000.0
## The brands over the cosmetics bays (Québec's own first).
const BEAUTY_BRANDS := ["Lise Watier", "Annabelle", "L'Oréal Paris"]

const HELLOS := ["Bonjour, ma belle !", "As-tu trouvé ce que tu cherchais ?", "Bonne journée, là !", "Dis bonjour à tes parents !"]
const BEAUTY_LINES := ["Bonjour ! Tu veux essayer un brillant à lèvres ?", "Les vernis roses sont en spécial, ma chouette !", "T'as ben de beaux cheveux, toi !"]
const PHARMACIST_LINES := ["Allô Charlotte ! T'es pas malade, j'espère ?", "Les médicaments, c'est juste avec tes parents, OK ?",
	"Lave-toi ben les mains, c'est la saison du rhume !", "Si t'as une question, gêne-toi pas !"]

## What she can buy in each aisle: [picture kind, what she says, price, kind kept in her stash or ""]; an empty list is a
## department she leaves to her parents (`HANDS_OFF`).
const BUYS := {
	"cheveux": [["hairbrush", "Une brosse à cheveux !", 4.99, ""], ["spray", "Un démêlant qui sent la pomme !", 4.49, ""]],
	"personnels": [["toothbrush", "Une brosse à dents pour enfants !", 2.99, ""], ["soap", "Un savon qui sent la fraise !", 1.99, ""]],
	"rhume": [["tissues", "Des mouchoirs !", 1.99, ""], ["bandages", "Des pansements de couleur !", 3.49, ""]],
	"vitamines": [],
	"bebe": [["babybottle", "Un biberon pour ma poupée !", 3.99, ""]],
	"collations": [["chips", "Un sac de chips !", 2.99, "chips"], ["choco", "Une tablette de chocolat !", 1.99, "chocolate"],
		["candy", "Des jujubes !", 1.49, "wrapped"]],
}
const HANDS_OFF := "Les vitamines, c'est Maman pis Papa qui choisissent."

var _hello := 0
var _beauty_line := 0
var _pharma_line := 0
var _tubes: Array[float] = []
var _advisor: Character
var _pharmacist: Character
var _bp_busy := false


func _ready() -> void:
	var rooms := [{"from": FRONT.x, "to": FRONT.y, "wall": Color("#F6F7F8"), "base": Color(CoutuArt.NAVY)}]
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		rooms.append({"from": a.x, "to": a.y, "wall": Color("#F2F3F5"), "base": Color(CoutuArt.NAVY)})
	var x := 300.0
	while x < FRONT.y:
		if x < BEAUTY_X or x > BEAUTY_END:
			_tubes.append(x)
		x += 560.0
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		var tx := a.x + 300.0
		while tx < a.y:
			_tubes.append(tx)
			tx += 600.0
	var shell := RoomShell.new()
	shell.rooms = rooms
	shell.floor_style = "tiles"
	shell.tile_colors = [Color("#F1F2F2"), Color("#E3E5E6")]
	shell.ceiling_style = "drop"
	shell.gleams = _tubes
	add_child(shell)
	_build_front()
	_build_checkouts()
	_build_beauty()
	_build_aisle_ends()
	for i in CoutuArt.AISLES.size():
		_build_aisle(i)
	_build_pharmacy()
	_build_lighting()
	_add_customers(4, [1300.0, 2700.0, 3300.0, 3900.0, 4500.0, 6000.0, 7800.0, 9900.0, 10500.0], 2716)
	_spawn_charlotte(DOOR_X + 260.0)
	_build_spots()
	# A screenshot or a debug run asked for an x in one of the aisles starts there.
	var start := FRONT
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		if _charlotte.position.x >= a.x and _charlotte.position.x <= a.y:
			start = a
	_enter_area(start)
	var fg := [[1300.0, "basket"], [3600.0, "plant"], [7600.0, "basket"], [10300.0, "plant"]]
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		var fx := a.x + 120.0
		var k := 0
		while fx < a.y - 100.0:
			fg.append([fx, "shelves", i * 37 + k])
			fx += 900.0
			k += 1
	_finish(fg)
	Sfx.play("bell")


func _music() -> Array:
	return ["jean-coutu", "dollarama", "depanneur", "street_" + Season.current, "street"]


func _aisle_area(i: int) -> Vector2:
	var x0 := AISLE_AREA0 + i * AISLE_STRIDE
	return Vector2(x0, x0 + AISLE_LEN)


func _mouth_x(i: int) -> float:
	return AISLE0 + i * PERIOD + END_W


## The plate at the top of the screen: the part of the store she is in, or the aisle.
func room_name() -> String:
	if _charlotte == null:
		return "Jean Coutu, rue Masson"
	var x := _charlotte.position.x
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		if x >= a.x and x <= a.y:
			return "Jean Coutu : allée %d, %s" % [i + 1, String(CoutuArt.AISLES[i][1]).to_lower()]
	if x >= BEAUTY_X and x < AISLE0:
		return "Jean Coutu : les cosmétiques"
	if x >= CONSULT_X - 100.0:
		return "Jean Coutu : la pharmacie"
	return "Jean Coutu, rue Masson"


# ── The front: door, window, checkouts, photo ───────────────

func _build_front() -> void:
	_put(ShopArt.door(), DOOR_X, WALL_BASE)
	_put(InteriorArt.doormat(), DOOR_X + 30.0, 630.0)
	var window := _put(DollarArt.storefront(WINDOW_W, CoutuArt.NAVY, CoutuArt.RED, CoutuArt.NAVY_DARK, false), WINDOW_X, WALL_BASE)
	_wall_label("Jean Coutu", window.position + Vector2(170.0, 34.0), 24, Color.WHITE, Color(CoutuArt.NAVY_DARK), 2)
	_wall_label("PHARMACIE", window.position + Vector2(WINDOW_W - 130.0, 34.0), 16, Color.WHITE, Color(CoutuArt.RED), 2)
	_put(ShopArt.baskets_stack(), 330.0, 646.0, 0.9, "floor")
	_put(ShopArt.shopping_cart(), 470.0, 650.0, 0.85, "floor")
	# Behind the checkouts: a wall of small things for the road (travel sizes, lip balm, gum), the store's name over it.
	_put(CoutuArt.gondola("personnels", 1240.0, 5), CHECK_X - 20.0, WALL_BASE, 0.78)
	_wall_label("Jean Coutu", Vector2(CHECK_X + 600.0, 150.0), 44, Color(CoutuArt.NAVY), Color.WHITE, 6)
	_wall_label("PHARMACIE · SANTÉ · BEAUTÉ", Vector2(CHECK_X + 600.0, 196.0), 17, Color(CoutuArt.RED), Color.WHITE, 4)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(FRONT.x, 52), Vector2(FRONT.y, 52), Vector2(FRONT.y, 66), Vector2(FRONT.x, 66)])
	band.color = Color(CoutuArt.NAVY)
	add_child(band)
	# The photo counter beside the checkouts.
	var photo := _put(CoutuArt.photo_kiosk(), PHOTO_X, 646.0, 1.0, "floor")
	_wall_label("PHOTO", photo.position + Vector2(130.0, 90.0), 20, Color.WHITE, Color(CoutuArt.NAVY), 0)


# Two checkouts in the store's navy and red (white bags on the carousel), the cashier at the first in a navy polo, the first
# lane's light on.
func _build_checkouts() -> void:
	_clerk = _staff(Color(CoutuArt.NAVY), "tshirt", "ponytail", Color("#3A2618"), Color("#E8B892"))
	_clerk.position = Vector2(CHECK_X + 330.0, 556.0)
	_clerk.facing = -1
	for lane in 2:
		var lx := CHECK_X + lane * LANE_STEP
		_put(DollarArt.checkout(31 + lane, CoutuArt.NAVY, CoutuArt.NAVY_DARK, CoutuArt.RED, ["#FFFFFF", "#EEF2F6", "#F6F4EE"]), lx, 616.0, 1.0, "floor")
		var light := Vector2(lx, 616.0 - 380.0) + DollarArt.LANE_LIGHT_AT
		if lane == 0:
			_glow(light, 60.0, Color(1.0, 0.95, 0.85, 0.5))
		_wall_label(str(lane + 1), light, 26, Color.WHITE if lane == 0 else Color("#7A86A8"), Color(CoutuArt.NAVY_DARK), 3)


## Someone who works here, in the store's colours.
func _staff(top: Color, outfit: String, hair: String, hair_color: Color, skin: Color) -> Character:
	var who := Character.new()
	var look := CharacterLook.new()
	look.age = "adult"
	look.skin = skin
	look.hair_style = hair
	look.hair_color = hair_color
	look.eye_color = Color("#3E2A1E")
	look.mouth = "smile"
	look.outfit = outfit
	look.outfit_color = top
	look.accent_color = Color.WHITE
	look.pattern = "none"
	look.sleeve = "long"
	look.legwear = "pants"
	look.legwear_color = Color("#2B2B33")
	look.shoes = "sneaker"
	look.shoe_color = Color("#2B2B33")
	who.look = look
	who.scale = Vector2.ONE * CHAR_SCALE * 1.04
	who.fidgets = true
	who.fidget_moves = ["look", "look", "stretch"]
	add_child(who)
	return who


# ── Cosmetics, dermo-cosmetics, perfumes ────────────────────

# Warm wood underfoot, three wall bays of testers under their brands, warm pendant lights, the beauty island with its
# lit mirror, the advisor in black; then the bright white dermo-cosmetics and the lit perfume case.
func _build_beauty() -> void:
	_put(CoutuArt.wood_floor(BEAUTY_END - BEAUTY_X + 40.0), BEAUTY_X - 20.0, 720.0)
	_wall_label("COSMÉTIQUES", Vector2((BEAUTY_X + BEAUTY_END) / 2.0, 104.0), 30, Color(CoutuArt.WOOD_DARK), Color.WHITE, 6)
	for b in 3:
		var bx := BEAUTY_X + b * 600.0
		_put(CoutuArt.beauty_wall(50 + b), bx, WALL_BASE, 1.0, "floor")
		_wall_label(BEAUTY_BRANDS[b], Vector2(bx + 280.0, WALL_BASE - 470.0 + 26.0), 20, Color("#2B2B30"), Color(0, 0, 0, 0), 0)
	# Warm pendants where the bays meet (one hung over the middle of a bay hid the accent of the big sign).
	for b in 4:
		_pendant(BEAUTY_X + b * 600.0 - 10.0, 60.0)
	_advisor = _staff(Color("#1E1E22"), "sweater", "long_straight", Color("#2A1A12"), Color("#F2C8A8"))
	_advisor.position = Vector2(BEAUTY_X + 1460.0, FEET_Y - 6.0)
	_advisor.facing = -1
	_put(CoutuArt.beauty_island(), BEAUTY_X + 840.0, 662.0, 0.95, "floor")
	_put(CoutuArt.dermo_wall(61), DERMO_X, WALL_BASE, 1.0, "floor")
	_wall_label("DERMOCOSMÉTIQUES", Vector2(DERMO_X + 280.0, WALL_BASE - 470.0 + 26.0), 19, Color("#2E6FC0"), Color(0, 0, 0, 0), 0)
	_put(CoutuArt.perfume_case(), PERFUME_X, WALL_BASE, 1.0, "floor")
	_wall_label("PARFUMS", Vector2(PERFUME_X + 150.0, WALL_BASE - 470.0 - 18.0), 20, Color(CoutuArt.WOOD_DARK), Color.WHITE, 4)
	# A small warm spot over the perfumes' case, from above (not over the glass: it washed the bottles out).
	_glow(Vector2(PERFUME_X + 150.0, WALL_BASE - 470.0), 120.0, Color(1.0, 0.9, 0.7, 0.25))


# ── Aisles ──────────────────────────────────────────────────

# Along the front: each aisle's stocked end with this week's price, then the aisle running back under its navy sign.
func _build_aisle_ends() -> void:
	for i in CoutuArt.AISLES.size():
		var theme: String = CoutuArt.AISLES[i][0]
		var ex := AISLE0 + i * PERIOD
		_put(DollarArt.aisle_mouth(MOUTH_W, 170 + i, CoutuArt.NAVY, "#FFFFFF"), _mouth_x(i), WALL_BASE)
		_put(CoutuArt.endcap(theme, 190 + i), ex, WALL_BASE, 1.0, "floor")
		_wall_label(CoutuArt.PRICES[(i * 3 + 1) % CoutuArt.PRICES.size()], Vector2(ex + 130.0, WALL_BASE - 470.0 + 20.0), 22, Color.WHITE, Color(0, 0, 0, 0), 0)
		_aisle_sign(_mouth_x(i) + MOUTH_W / 2.0, i)
	_put(CoutuArt.endcap("collations", 199), AISLE0 + CoutuArt.AISLES.size() * PERIOD, WALL_BASE, 1.0, "floor")


# Inside an aisle: one long gondola of its department, its red price flags, its sign over the middle, the way out at both ends.
func _build_aisle(i: int) -> void:
	var a := _aisle_area(i)
	var theme: String = CoutuArt.AISLES[i][0]
	var w := AISLE_LEN - 200.0
	var shelf := _put(CoutuArt.gondola(theme, w, 400 + i), a.x + 100.0, WALL_BASE, 1.0, "floor")
	for tk: Array in CoutuArt.talkers(w):
		_wall_label(tk[2], shelf.position + Vector2(float(tk[0]), float(tk[1]) - 16.0), 16, Color.WHITE, Color(0, 0, 0, 0), 0)
	_aisle_sign((a.x + a.y) / 2.0, i)
	for side: float in [-1.0, 1.0]:
		var ax := a.x + 50.0 if side < 0.0 else a.y - 50.0
		_wall_label("← SORTIE" if side < 0.0 else "SORTIE →", Vector2(ax + side * -10.0, 110.0), 14, Color.WHITE, Color(CoutuArt.NAVY), 4)


# An aisle sign hanging from the ceiling: a navy board, the aisle's number in a white disc, its department in white.
func _aisle_sign(cx: float, i: int) -> void:
	var top := 92.0
	var w := 320.0
	for dx: float in [-w * 0.35, w * 0.35]:
		var chain := Line2D.new()
		chain.points = PackedVector2Array([Vector2(cx + dx, CEILING), Vector2(cx + dx, top)])
		chain.width = 2.0
		chain.default_color = Color("#8E9196")
		add_child(chain)
	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(cx - w / 2.0, top), Vector2(cx + w / 2.0, top), Vector2(cx + w / 2.0, top + 64.0), Vector2(cx - w / 2.0, top + 64.0)])
	board.color = Color(CoutuArt.NAVY)
	add_child(board)
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([Vector2(cx - w / 2.0, top + 58.0), Vector2(cx + w / 2.0, top + 58.0), Vector2(cx + w / 2.0, top + 64.0), Vector2(cx - w / 2.0, top + 64.0)])
	lip.color = Color(CoutuArt.RED)
	add_child(lip)
	var disc := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 24:
		pts.append(Vector2(cx - w / 2.0 + 34.0, top + 30.0) + Vector2.from_angle(TAU * k / 24.0) * 22.0)
	disc.polygon = pts
	disc.color = Color.WHITE
	add_child(disc)
	_wall_label(str(i + 1), Vector2(cx - w / 2.0 + 34.0, top + 30.0), 24, Color(CoutuArt.NAVY), Color(0, 0, 0, 0), 0)
	var words: String = CoutuArt.AISLES[i][1]
	_wall_label(words, Vector2(cx + 22.0, top + 28.0), 16 if words.length() < 18 else 12, Color.WHITE, Color(CoutuArt.NAVY_DARK), 2)


# ── The pharmacy ────────────────────────────────────────────

# At the back, in plain sight: the laboratory behind the glass under its big sign, the pharmacist in her white coat behind the
# counter with its two stations, the door of the consultation room, the blood-pressure machine with its seat, a row of chairs.
func _build_pharmacy() -> void:
	_put(CoutuArt.consult_door(), CONSULT_X, WALL_BASE)
	_wall_label("CONSULTATION", Vector2(CONSULT_X + 90.0, WALL_BASE - 430.0 + 183.0), 13, Color.WHITE, Color(0, 0, 0, 0), 0)
	_put(CoutuArt.lab_wall(LAB_W), LAB_X, WALL_BASE)
	_wall_label("PHARMACIE", Vector2(LAB_X + LAB_W / 2.0, WALL_BASE - 470.0 + 34.0), 34, Color.WHITE, Color(CoutuArt.NAVY_DARK), 2)
	_pharmacist = _staff(Color("#FBFBF8"), "coat", "bob", Color("#5A3A22"), Color("#D9A57E"))
	_pharmacist.position = Vector2(LAB_X + LAB_W * 0.22 + 60.0, 556.0)
	_pharmacist.facing = -1
	_put(CoutuArt.pharmacy_counter(LAB_W), LAB_X, 640.0, 1.0, "floor")
	for st: Array in [[0.22, "DÉPÔT DES ORDONNANCES"], [0.72, "CUEILLETTE"]]:
		_hanging_board(LAB_X + LAB_W * float(st[0]), 250.0, st[1])
	_put(CoutuArt.bp_machine(), BP_X, 650.0, 1.0, "floor")
	_wall_label("TENSION\nARTÉRIELLE", Vector2(BP_X + 80.0, 650.0 - 300.0 + 40.0), 11, Color.WHITE, Color(0, 0, 0, 0), 0)
	# The chain's own brand, on its display at the end of the store.
	_put(CoutuArt.endcap("rhume", 250), BP_X + 240.0, WALL_BASE, 1.0, "floor")
	_wall_label("Personnelle", Vector2(BP_X + 370.0, WALL_BASE - 470.0 + 20.0), 18, Color.WHITE, Color(0, 0, 0, 0), 0)



func _hanging_board(cx: float, y: float, words: String) -> void:
	var w := 260.0
	for dx: float in [-w * 0.35, w * 0.35]:
		var chain := Line2D.new()
		chain.points = PackedVector2Array([Vector2(cx + dx, CEILING), Vector2(cx + dx, y)])
		chain.width = 2.0
		chain.default_color = Color("#8E9196")
		add_child(chain)
	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(cx - w / 2.0, y), Vector2(cx + w / 2.0, y), Vector2(cx + w / 2.0, y + 40.0), Vector2(cx - w / 2.0, y + 40.0)])
	board.color = Color.WHITE
	add_child(board)
	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(cx - w / 2.0, y), Vector2(cx + w / 2.0, y), Vector2(cx + w / 2.0, y + 40.0), Vector2(cx - w / 2.0, y + 40.0), Vector2(cx - w / 2.0, y)])
	edge.width = 3.0
	edge.default_color = Color(CoutuArt.NAVY)
	add_child(edge)
	_wall_label(words, Vector2(cx, y + 20.0), 14 if words.length() < 14 else 12, Color(CoutuArt.NAVY), Color(0, 0, 0, 0), 0)


func _build_lighting() -> void:
	for x in _tubes:
		var panel := Sprite2D.new()
		panel.texture = ShopArt.panel_light()
		panel.centered = false
		panel.position = Vector2(x - 70.0, 5.0)
		add_child(panel)
		_glow(Vector2(x, CEILING + 30.0), 340.0, Color(1.0, 1.0, 0.98, 0.2))
	# The cosmetics are lit warm.
	for b in 3:
		_glow(Vector2(BEAUTY_X + b * 600.0 + 280.0, 240.0), 260.0, Color(1.0, 0.86, 0.66, 0.12))
	_daylight(Vector2(DOOR_X + 40.0, 180.0), 130.0, 0.12)


# ── What she can click ──────────────────────────────────────

func _build_spots() -> void:
	# The door: back out onto Masson (Transition.street_x, set on the way in, puts her at the shop door).
	add_child(DoorSpot.make(Rect2(DOOR_X + 20.0, 170, 170, 430), func():
		_control.enabled = false
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/masson_pair.tscn"), DOOR_X + 110.0))
	add_child(DoorSpot.make(Rect2(CHECK_X + 270.0, 280, 120, 190), func():
		_say(_clerk, HELLOS[_hello % HELLOS.size()], 230.0)
		_hello += 1, CHECK_X + 200.0))
	add_child(DoorSpot.make(Rect2(PHOTO_X, 330, 260, 320), func():
		_say(_charlotte, "Un jour, je vais faire imprimer\nmes dessins en photo !", 300.0, 3.0), PHOTO_X + 130.0))
	# Cosmetics: a lip gloss or a nail polish (she is seven: the pink ones).
	for b in 3:
		var bx := BEAUTY_X + b * 600.0
		add_child(DoorSpot.make(Rect2(bx + 20.0, 180.0, 520.0, 300.0), func():
			if randf() < 0.5:
				_buy(CoutuArt.item("gloss"), "Un brillant à lèvres aux fraises !", 3.99)
			else:
				_buy(CoutuArt.item("polish"), "Du vernis à ongles rose !", 3.49), bx + 280.0))
	add_child(DoorSpot.make(Rect2(BEAUTY_X + 840.0, 520.0, 360.0, 140.0), func():
		_charlotte.express("happy", 2.5)
		_say(_charlotte, "Je me regarde dans le miroir…\nQue je suis belle !", 300.0, 3.0), BEAUTY_X + 1020.0))
	add_child(DoorSpot.make(Rect2(_advisor.position.x - 55.0, 330.0, 110.0, 340.0), func():
		_say(_advisor, BEAUTY_LINES[_beauty_line % BEAUTY_LINES.size()], 290.0, 3.0)
		_beauty_line += 1, _advisor.position.x - 100.0))
	add_child(DoorSpot.make(Rect2(DERMO_X + 10.0, 180.0, 540.0, 400.0), func():
		_say(_charlotte, "Ça, c'est pour la peau des grands !", 300.0), DERMO_X + 280.0))
	add_child(DoorSpot.make(Rect2(PERFUME_X, 180.0, 300.0, 400.0), func():
		_charlotte.express("wonder", 2.5)
		_say(_charlotte, "Mmmh ! Ça sent les fleurs !", 300.0), PERFUME_X + 150.0))
	# The pharmacy.
	add_child(DoorSpot.make(Rect2(LAB_X + 120.0, 300.0, 300.0, 260.0), func():
		_say(_pharmacist, PHARMACIST_LINES[_pharma_line % PHARMACIST_LINES.size()], 290.0, 3.2)
		_pharma_line += 1, LAB_X + 200.0))
	add_child(DoorSpot.make(Rect2(CONSULT_X, 170.0, 180.0, 430.0), func():
		_say(_charlotte, "C'est la salle où la pharmacienne\nparle aux gens en privé.", 300.0, 3.2), CONSULT_X + 90.0))
	add_child(DoorSpot.make(Rect2(BP_X, 350.0, 220.0, 300.0), _measure_pressure, BP_X + 240.0))
	for i in CoutuArt.AISLES.size():
		var a := _aisle_area(i)
		var mx := _mouth_x(i) + MOUTH_W / 2.0
		var area := a
		add_child(DoorSpot.make(Rect2(_mouth_x(i) + 20.0, 150, MOUTH_W - 40.0, 450), func():
			_go_through(area.x + 260.0, area, 1), mx))
		for side: float in [-1.0, 1.0]:
			var ex := a.x + 40.0 if side < 0.0 else a.y - 200.0
			add_child(DoorSpot.make(Rect2(ex, 120, 160, 480), func():
				_go_through(mx, FRONT, 1 if side > 0.0 else -1), ex + 80.0))
		var theme: String = CoutuArt.AISLES[i][0]
		var choices: Array = BUYS.get(theme, [])
		add_child(DoorSpot.make(Rect2(a.x + 260.0, 140, AISLE_LEN - 520.0, 460), func():
			if choices.is_empty():
				_say(_charlotte, HANDS_OFF, 300.0, 3.0)
				return
			var c: Array = choices[randi() % choices.size()]
			_buy(CoutuArt.item(c[0]), c[1], c[2], c[3]), (a.x + a.y) / 2.0))


# The blood-pressure machine: she puts her arm in, it hums, and the screen says she is in great shape.
func _measure_pressure() -> void:
	if _bp_busy:
		return
	_bp_busy = true
	_control.enabled = false
	_charlotte.facing = -1
	_say(_charlotte, "Je mets mon bras dans la machine…", 300.0, 2.4)
	var steps := create_tween()
	steps.tween_interval(2.4)
	steps.tween_callback(func() -> void: Sfx.play("squeak", _charlotte.position, -6.0, 0.6))
	steps.tween_interval(1.6)
	steps.tween_callback(func() -> void:
		Bubble.say(self, Vector2(BP_X + 80.0, 300.0), "♥ 98 · Parfait pour\nune grande de %d ans !" % GameState.age, 3.4)
		_charlotte.express("laugh", 2.4))
	steps.tween_interval(3.0)
	steps.tween_callback(func() -> void:
		_bp_busy = false
		_control.enabled = true)
