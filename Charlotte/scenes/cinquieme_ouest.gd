extends StreetScene
# 5e Avenue, its west side (the even numbers), in ONE scene from Rue Masson (left) to Rue Holt (right), seen from across the
# street (the east sidewalk, looking west) — a street is one scene per side (Julien). Drawn from the Street View pictures
# (reference/streetview/INDEX.md, "5e Avenue 5300–5650 (pairs)", "5600–5800 (pairs)" and the walk 5e-avenue-massonholt):
# the side of the corner building at Masson, the buff hall, a lane, the long rows of triplexes in brick and grey stone with their
# outdoor stairs, a lane, Rue Dandurand, the long side of the corner building, a lane, more triplexes and duplexes, the low red
# cottages, a lane, the red corner at Holt. She gets here over 5e Avenue at any corner of cinquieme.tscn (from 8 years old), and
# back the same way; at Masson she turns onto its north side. The lanes on this side aren't hers.


func _init() -> void:
	street_key = "5e_ouest"
	layout = [
		"masson_2840_cote", "rue_masson", "ouest_5400", "ouest_5404", "ruelle_cinq_ouest_masson", "ouest_5424", "ouest_5426",
		"ouest_5438", "ouest_5440", "ouest_5444", "ouest_5456", "ouest_5458", "ouest_5460", "ouest_5468", "ouest_5476",
		"ouest_5482", "ouest_5484", "ouest_5494", "ouest_5500", "ouest_5506", "ouest_5510", "ouest_5514", "ouest_5520",
		"ouest_5524", "ouest_5530", "ouest_5536", "ouest_5540", "ouest_5550", "ouest_5558", "ouest_5562", "ouest_5570",
		"ouest_5574", "ouest_5580", "ruelle_cinq_ouest_sud", "ouest_5586", "ouest_5594", "rue_dandurand", "ouest_5608",
		"ruelle_cinq_ouest_dandurand", "ouest_5628", "ouest_5634", "ouest_5644", "ouest_5652", "ouest_5658", "ouest_5662",
		"ouest_5666", "ouest_5668", "ouest_5676", "ouest_5678", "ouest_5682", "ouest_5686", "ouest_5694", "ouest_5698",
		"ouest_5700", "ouest_5704", "ouest_5706", "ouest_5710", "ouest_5714", "ouest_5718", "ouest_5722",
		"ruelle_cinq_ouest_holt", "ouest_5752", "rue_holt", "cinq_ouest_holt_nord",
	]
	cross_streets = {"rue_masson": 600.0, "rue_dandurand": 560.0, "rue_holt": 520.0}
	trees_after = [2, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 34, 37, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 61]
	lamps_after = [3, 9, 14, 19, 24, 29, 35, 42, 47, 52, 57]
	hydrants_at = [12.5, 29.5, 49.5]
	racks_at = [18.5, 43.5]
	squirrels_at = [8.4, 24.4, 53.4]
	seed_value = 5602


func _start_x() -> float:
	if _arriving("5e_ouest_from_5e_masson") or _arriving("5e_ouest_from_masson"):
		return _starts[layout.find("rue_masson") + 1] + 40.0
	if _arriving("5e_ouest_from_5e_dandurand_sud"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("5e_ouest_from_5e_dandurand"):
		return _starts[layout.find("rue_dandurand") + 1] + 40.0
	if _arriving("5e_ouest_from_5e_holt"):
		return _starts[layout.find("rue_holt")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.find("ouest_5694") + 0.5)


# The cross streets run west from here, toward the mountain. Masson's real buildings both sides; Dandurand and Holt west of 5e
# aren't drawn yet.
func _build_cross_streets() -> void:
	var masson := _cross_street("rue_masson", "Rue Masson", 1.0)
	masson.along_name = "5e Avenue"
	masson.facing = "west"
	masson.left_walls = _walls_along("res://scenes/masson.gd", "rue_5e", 1, "", {"side": "pair"})
	masson.right_walls = _walls_along("res://scenes/masson.gd", "rue_5e", -1, "", {"side": "impair"})
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", 1.0)
	dandurand.along_name = "5e Avenue"
	dandurand.facing = "west"
	dandurand.left_walls = [
		{"to": 0.9, "top": _house_top("ouest_5594"), "kind": "plex", "color": Color("#A8473A")},
		{"to": 2.4, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	dandurand.right_walls = [
		{"to": 1.0, "top": _house_top("ouest_5608"), "kind": "plex", "color": Color("#B8946E")},
		{"to": 2.6, "top": 290.0, "kind": "plex", "color": Color("#8A4A3A")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
	]
	var holt := _cross_street("rue_holt", "Rue Holt", -1.0)
	holt.along_name = "5e Avenue"
	holt.facing = "west"
	holt.left_walls = [
		{"to": 0.8, "top": _house_top("ouest_5752"), "kind": "plex", "color": Color("#A8473A")},
		{"to": 2.3, "top": 290.0, "kind": "plex", "color": Color("#7E4436")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	holt.right_walls = [
		{"to": 0.7, "top": _house_top("cinq_ouest_holt_nord"), "kind": "plex", "color": Color("#8E4A3A")},
		{"to": 2.4, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
	]


# Onto Masson's north side round the corner; back over 5e Avenue at every corner; the lanes on this side aren't hers.
func _build_doors() -> void:
	var masson := _cross_streets[0]
	var dandurand := _cross_streets[1]
	var holt := _cross_streets[2]
	_add_corner(masson, "res://scenes/masson_impair.tscn", "masson_impair_from_rue_5e_4e_5e", false, 1)
	_add_across(masson, "res://scenes/cinquieme.tscn", "5e_from_5e_ouest_masson", 1)
	_add_across(dandurand, "res://scenes/cinquieme.tscn", "5e_from_5e_ouest_dandurand_sud", -1)
	_add_across(dandurand, "res://scenes/cinquieme.tscn", "5e_from_5e_ouest_dandurand", 1)
	_add_across(holt, "res://scenes/cinquieme.tscn", "5e_from_5e_ouest_holt", -1)
	for art in ["ruelle_cinq_ouest_masson", "ruelle_cinq_ouest_sud", "ruelle_cinq_ouest_dandurand", "ruelle_cinq_ouest_holt"]:
		var i := layout.find(art)
		var w := _tex(art).get_width()
		var area := Rect2(_house_origin(i) + Vector2(70.0, 330.0) * HOUSE_SCALE, Vector2(w - 140.0, 370.0) * HOUSE_SCALE)
		add_child(DoorSpot.make(area, func():
			_charlotte.express("worry", 2.0)
			Bubble.say(self, _charlotte.position + Vector2(0, -210.0), NOT_OUR_LANE[randi() % NOT_OUR_LANE.size()], 3.0), area.get_center().x))


## What she says at a lane on this side of 5e Avenue: it isn't hers.
const NOT_OUR_LANE := ["C'est pas ma ruelle, ça.\nJe la connais pas pantoute !",
	"Maman veut pas que j'aille\ndans les ruelles que je connais pas.",
	"Ma ruelle à moi, c'est de l'autre côté\nde la rue !"]


## How far along the scene Rue Dandurand is (0..1), for the town map (`TownMap._here`).
func _dandurand_f() -> float:
	return (_starts[layout.find("rue_dandurand")] + _starts[layout.find("rue_dandurand") + 1]) / 2.0 / _street_width
