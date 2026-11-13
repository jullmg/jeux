extends StreetScene
# 6e Avenue between Rue Dandurand (left) and Rue Masson (right), the other side (the east side, odd numbers), seen from
# Charlotte's side of the street like `sixieme_est` (the other side above Dandurand): drawn from the Street View pictures
# (reference/streetview/INDEX.md, "6e Avenue" 5385… to 5595…; facades `six_est_sud_*` in tools/generate_houses.gd). Left to right:
# the side of 5601 across Dandurand, Rue Dandurand, the red-painted corner 5595, the row of plexes with their outdoor stairs, the
# lane, more plexes, two duplexes of the 1960s, the parking lot, the little square with its bicycle shelter, the side of 2901
# Masson at the corner, Rue Masson and the side of 2902 across it.
# She comes here across Dandurand from `sixieme_est`, or across 6e Avenue from `sixieme_sud` at either corner; at the Masson
# corner she can turn onto Masson's north side.


func _init() -> void:
	street_key = "6e_sud_est"
	layout = [
		"six_est_sud_5601_cote", "rue_dandurand",
		"six_est_sud_5595", "six_est_sud_5581", "six_est_sud_5573", "six_est_sud_5565", "six_est_sud_5561", "six_est_sud_5551",
		"ruelle_six_est_sud",
		"six_est_sud_5535", "six_est_sud_5527", "six_est_sud_5517", "six_est_sud_5509", "six_est_sud_5501", "six_est_sud_5491",
		"six_est_sud_5471", "six_est_sud_5459", "six_est_sud_5455", "six_est_sud_5435", "six_est_sud_stationnement",
		"six_est_sud_place", "six_est_sud_2901_cote",
		"rue_masson", "masson_2902_cote",
	]
	cross_streets = {"rue_dandurand": 560.0, "rue_masson": 600.0}
	trees_after = [3, 5, 7, 10, 12, 14, 16, 18]
	lamps_after = [4, 9, 13, 17]
	hydrants_at = [6.4, 15.5]
	racks_at = [11.6]
	squirrels_at = [4.4, 10.5, 15.3]
	seed_value = 7711


func _start_x() -> float:
	if _arriving("6e_sud_est_from_6e_est") or _arriving("6e_sud_est_from_sud_dandurand"):
		return _starts[layout.find("rue_dandurand") + 1] + 40.0
	if _arriving("6e_sud_est_from_sud_masson") or _arriving("6e_sud_est_from_masson"):
		return _starts[layout.find("rue_masson")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.find("six_est_sud_5509") + 0.5)


# Both cross streets run east from here (no mountain, sky and clouds); their far sides aren't drawn from photographs yet.
func _build_cross_streets() -> void:
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", 1.0)
	dandurand.along_name = "6e Avenue"
	dandurand.facing = "east"
	dandurand.left_walls = [
		{"to": 1.0, "top": _house_top("six_est_sud_5601_cote"), "kind": "plex", "color": Color("#C98A64")},
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


# Over 6e Avenue at either corner to her side (sixieme_sud); round the Masson corner onto Masson's north side; the lane on this
# side isn't hers.
func _build_doors() -> void:
	var dandurand := _cross_streets[0]
	var masson := _cross_streets[1]
	_add_across(dandurand, "res://scenes/sixieme_sud.tscn", "6e_sud_from_est_dandurand", 1)
	_add_across(masson, "res://scenes/sixieme_sud.tscn", "6e_sud_from_est_masson", -1)
	_add_corner(masson, "res://scenes/masson_impair.tscn", "masson_impair_from_rue_6e_6e_7e", false, -1)
	var i := layout.find("ruelle_six_est_sud")
	var w := _tex("ruelle_six_est_sud").get_width()
	var area := Rect2(_house_origin(i) + Vector2(70.0, 330.0) * HOUSE_SCALE, Vector2(w - 140.0, 370.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_charlotte.express("worry", 2.0)
		Bubble.say(self, _charlotte.position + Vector2(0, -210.0), "C'est pas ma ruelle, ça.\nJe la connais pas pantoute !", 3.0), area.get_center().x))


# Crossing Dandurand northward takes her to the other side of 6e above it (sixieme_est), at its Dandurand corner.
func _cross(cs: CrossStreet) -> void:
	if cs != _cross_streets[0] or _charlotte.position.x < cs.x1:
		super._cross(cs)
		return
	_cross_to(cs, "res://scenes/sixieme_est.tscn", "6e_est_from_sud")
