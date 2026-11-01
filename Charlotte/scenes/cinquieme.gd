extends StreetScene
# 5e Avenue, the back side of Charlotte's block, seen from across the street: Rue Holt crosses at the left end,
# Rue Dandurand at the right (école Saint-Jean-de-Brébeuf across it). Two lane entrances: near Holt, and the
# green lane near Dandurand (the same H-shaped lane as from 6e Avenue, see google_map_immediate_area.png).


func _init() -> void:
	street_key = "5e"
	layout = [
		"cinq_holt_ouest", "rue_holt",
		"coin_5e_holt", "plex_17", "plex_18", "ruelle",
		"plex_19", "plex_20", "plex_21", "plex_22", "plex_23", "plex_24",
		"ruelle_verte", "plex_25", "plex_26", "coin_5e_dandurand",
		"rue_dandurand", "ecole",
	]
	cross_streets = {"rue_holt": 520.0, "rue_dandurand": 560.0}
	trees_after = [3, 6, 8, 10, 13]
	lamps_after = [4, 9, 14]
	hydrants_at = [7.5]
	racks_at = [10.5]
	squirrels_at = [6.4, 10.4]
	seed_value = 4417


func _start_x() -> float:
	if _arriving("5e_from_holt"):
		return _starts[layout.find("rue_holt") + 1] + 40.0
	if _arriving("5e_from_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	var lane := _from_lane()
	if not is_nan(lane):
		return lane
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(9.0)


# Both cross streets run east from here: no mountain that way, sky and clouds.
func _build_cross_streets() -> void:
	var holt := _cross_street("rue_holt", "Rue Holt", 1.0)
	holt.along_name = "5e Avenue"
	holt.facing = "east"
	holt.left_walls = [
		{"to": 0.7, "top": _house_top("cinq_holt_ouest"), "kind": "plex", "color": Color("#7E4436")},
		{"to": 2.3, "top": 290.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	holt.right_walls = _walls_along("res://scenes/holt.gd", "rue_5e", -1)
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", -1.0)
	dandurand.along_name = "5e Avenue"
	dandurand.facing = "east"
	dandurand.school = true
	dandurand.left_walls = _walls_along("res://scenes/dandurand.gd", "rue_5e", 1)
	dandurand.right_walls = [
		{"to": 2.6, "top": _house_top("ecole"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]


func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "ruelle_verte":
		_label("RUELLE\nVERTE", house.position + Vector2(214, 416) * HOUSE_SCALE, Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/holt.tscn", "holt_from_5e")
	_add_corner(_cross_streets[1], "res://scenes/dandurand.tscn", "dandurand_from_5e")
	_add_lane("ruelle")
	_add_lane("ruelle_verte")
