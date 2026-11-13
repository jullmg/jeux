extends StreetScene
# 6e Avenue, the other side (the east side, odd numbers), in ONE scene from Rue Holt (left) to Rue Masson (right), seen from
# Charlotte's side of the street — a street is one scene per side (Julien). Drawn from the Street View pictures
# (reference/streetview/INDEX.md, "6e Avenue 5600–5800 (impairs)" and 5385… to 5595…): facing her block, 5733 down to 5601
# (`impair_*`); Rue Dandurand; then down to Masson the red-painted corner 5595, the plexes with their outdoor stairs, the lane,
# more plexes, two duplexes of the 1960s, the parking lot, the little square with its bicycle shelter and the side of 2901 Masson
# (`six_est_sud_*`); Rue Masson and the side of 2902 across it. She gets here over 6e Avenue at any corner of main.tscn, and
# back the same way; round its corners she comes onto Holt and Dandurand east of 6e, and onto Masson's north side.


func _init() -> void:
	street_key = "6e_est"
	layout = [
		"impair_holt_nord", "rue_holt",
		"impair_coin_holt", "ruelle_impair_holt",
		"impair_5713", "impair_5707", "impair_5699", "impair_5689", "impair_5685", "impair_5679", "impair_5677",
		"impair_5669", "impair_5661", "impair_5655", "impair_5649", "impair_5641", "impair_5637", "impair_5631",
		"impair_5621", "impair_5615",
		"ruelle_impair_dandurand", "impair_5601",
		"rue_dandurand",
		"six_est_sud_5595", "six_est_sud_5581", "six_est_sud_5573", "six_est_sud_5565", "six_est_sud_5561", "six_est_sud_5551",
		"ruelle_six_est_sud",
		"six_est_sud_5535", "six_est_sud_5527", "six_est_sud_5517", "six_est_sud_5509", "six_est_sud_5501", "six_est_sud_5491",
		"six_est_sud_5471", "six_est_sud_5459", "six_est_sud_5455", "six_est_sud_5435", "six_est_sud_stationnement",
		"six_est_sud_place", "six_est_sud_2901_cote",
		"rue_masson", "masson_2902_cote",
	]
	cross_streets = {"rue_holt": 520.0, "rue_dandurand": 560.0, "rue_masson": 600.0}
	# Street trees where the pictures have them: before 5707, 5689, 5669 and 5661, 5649, 5641, 5631, 5615, and 5601's big one;
	# then below Dandurand (indices from 23).
	trees_after = [4, 6, 10, 12, 14, 15, 17, 19, 21, 24, 26, 28, 31, 33, 35, 37, 39]
	lamps_after = [5, 9, 13, 18, 25, 30, 34, 38]
	hydrants_at = [8.4, 16.5, 27.4, 36.5]
	racks_at = [7.6, 14.2, 32.6]
	squirrels_at = [5.3, 11.4, 17.6, 25.4, 31.5, 36.3]
	seed_value = 5527


# At the corner she crossed from, else in the middle of the block (a debug teleport, a reload).
func _start_x() -> float:
	if _arriving("6e_est_from_6e_holt") or _arriving("6e_est_from_holt"):
		return _starts[layout.find("rue_holt") + 1] + 40.0
	if _arriving("6e_est_from_6e_dandurand") or _arriving("6e_est_from_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("6e_est_from_6e_dandurand_sud"):
		return _starts[layout.find("rue_dandurand") + 1] + 40.0
	if _arriving("6e_est_from_6e_masson") or _arriving("6e_est_from_masson"):
		return _starts[layout.find("rue_masson")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.find("impair_5669") + 0.5)


# The cross streets run east from here: no mountain, sky and clouds. Their far sides aren't drawn from photographs yet.
func _build_cross_streets() -> void:
	var holt := _cross_street("rue_holt", "Rue Holt", 1.0)
	holt.along_name = "6e Avenue"
	holt.facing = "east"
	holt.left_walls = [
		{"to": 0.7, "top": _house_top("impair_holt_nord"), "kind": "plex", "color": Color("#8E4A3A")},
		{"to": 2.4, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	holt.right_walls = [
		{"to": 0.9, "top": _house_top("impair_coin_holt"), "kind": "plex", "color": Color("#A8473A")},
		{"to": 2.3, "top": 290.0, "kind": "plex", "color": Color("#7E4436")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", -1.0)
	dandurand.along_name = "6e Avenue"
	dandurand.facing = "east"
	dandurand.left_walls = [
		{"to": 1.0, "top": _house_top("impair_5601"), "kind": "plex", "color": Color("#C98A64")},
		{"to": 2.6, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
	]
	dandurand.right_walls = [
		{"to": 0.8, "top": _house_top("six_est_sud_5595"), "kind": "plex", "color": Color("#B84A3E")},
		{"to": 2.2, "top": 290.0, "kind": "plex", "color": Color("#A8473A")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#7E4436")},
	]
	var masson := _cross_street("rue_masson", "Rue Masson", -1.0)
	masson.along_name = "6e Avenue"
	masson.facing = "east"
	masson.left_walls = [
		{"to": 1.2, "top": _house_top("six_est_sud_2901_cote"), "kind": "plex", "color": Color("#9A4636")},
		{"to": 2.6, "top": 300.0, "kind": "plex", "color": Color("#8E3E30")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B04A38")},
	]
	masson.right_walls = [
		{"to": 1.0, "top": 300.0, "kind": "plex", "color": Color("#D4A774")},
		{"to": 2.4, "top": 330.0, "kind": "plex", "color": Color("#5E4A3E")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#C2452E")},
	]


# Round the corners onto Holt and Dandurand east of 6e (the stretches of those streets across 6e from her block) and onto
# Masson's north side; back over 6e Avenue at every corner; the lanes on this side aren't hers. Each one names its stretch of
# sidewalk, since the scene holds several.
func _build_doors() -> void:
	var holt := _cross_streets[0]
	var dandurand := _cross_streets[1]
	var masson := _cross_streets[2]
	_add_corner(holt, "res://scenes/holt.tscn", "holt_from_6e_est", false, 1)
	_add_corner(dandurand, "res://scenes/dandurand.tscn", "dandurand_from_6e_est", false, -1)
	_add_corner(masson, "res://scenes/masson_impair.tscn", "masson_impair_from_rue_6e_6e_7e", false, -1)
	_add_across(holt, "res://scenes/main.tscn", "6e_from_6e_est_holt", 1)
	_add_across(dandurand, "res://scenes/main.tscn", "6e_from_6e_est_dandurand", -1)
	_add_across(dandurand, "res://scenes/main.tscn", "6e_from_6e_est_dandurand_sud", 1)
	_add_across(masson, "res://scenes/main.tscn", "6e_from_6e_est_masson", -1)
	for art in ["ruelle_impair_holt", "ruelle_impair_dandurand", "ruelle_six_est_sud"]:
		var i := layout.find(art)
		var w := _tex(art).get_width()
		var area := Rect2(_house_origin(i) + Vector2(70.0, 330.0) * HOUSE_SCALE, Vector2(w - 140.0, 370.0) * HOUSE_SCALE)
		add_child(DoorSpot.make(area, func():
			_charlotte.express("worry", 2.0)
			Bubble.say(self, _charlotte.position + Vector2(0, -210.0), NOT_OUR_LANE[randi() % NOT_OUR_LANE.size()], 3.0), area.get_center().x))


## What she says at a lane on this side of 6e Avenue: it isn't hers, and she doesn't go into lanes she doesn't know.
const NOT_OUR_LANE := ["C'est pas ma ruelle, ça.\nJe la connais pas pantoute !",
	"Maman veut pas que j'aille\ndans les ruelles que je connais pas.",
	"Ma ruelle à moi, c'est de l'autre côté\nde la rue !"]


## How far along the scene Rue Dandurand is (0..1), for the town map (`TownMap._here`).
func _dandurand_f() -> float:
	return (_starts[layout.find("rue_dandurand")] + _starts[layout.find("rue_dandurand") + 1]) / 2.0 / _street_width
