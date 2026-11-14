extends StreetScene
# 5e Avenue, its east side, seen from across the street: Rue Holt at the left end, then the back side of Charlotte's block
# (drawn from reference/streetview/5e-avenue/, 5605…–5745…), Rue Dandurand, the block of the school and the church (the school's
# side, its yard, the apartments, the cedar hedge, the church's parking lot, the presbytery's side), and Rue Masson at the right
# end. Two lane entrances on her block: near Holt, and the green lane near Dandurand (the same H-shaped lane as from 6e Avenue).


func _init() -> void:
	street_key = "5e"
	layout = [
		"cinq_holt_ouest", "rue_holt",
		"cinq_5739", "ruelle",
		"cinq_5727", "cinq_5723", "cinq_5715", "cinq_5709", "cinq_5705", "cinq_5699", "cinq_5695", "cinq_5685",
		"cinq_5673", "cinq_5669", "cinq_5663", "cinq_5655", "cinq_5645", "cinq_5637", "cinq_5629",
		"ruelle_verte", "cinq_5605", "rue_dandurand",
		"cinq_ecole", "cinq_cour", "cinq_appartements", "cinq_haie", "cinq_stationnement", "cinq_annexe", "cinq_presbytere",
		"rue_masson", "masson_2846_cote",
	]
	cross_streets = {"rue_holt": 520.0, "rue_dandurand": 560.0, "rue_masson": 600.0}
	trees_after = [2, 5, 7, 9, 12, 15, 17, 20, 22, 23, 24, 27]
	lamps_after = [4, 9, 15, 20, 24, 27]
	hydrants_at = [7.5, 26.5]
	racks_at = [10.5, 22.5]
	squirrels_at = [6.4, 10.4, 23.5]
	seed_value = 4417


func _start_x() -> float:
	if _arriving("5e_from_5e_ouest_holt"):
		return _starts[layout.find("rue_holt") + 1] + 40.0
	if _arriving("5e_from_5e_ouest_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("5e_from_5e_ouest_dandurand_sud"):
		return _starts[layout.find("rue_dandurand") + 1] + 40.0
	if _arriving("5e_from_5e_ouest_masson"):
		return _starts[layout.find("rue_masson")] - 40.0
	if _arriving("5e_from_holt"):
		return _starts[layout.find("rue_holt") + 1] + 40.0
	if _arriving("5e_from_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("5e_from_masson"):
		return _starts[layout.find("rue_masson")] - 40.0
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
	holt.right_walls = _walls_along("res://scenes/holt.gd", "rue_5e", -1, "coin_5e_holt")
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", -1.0)
	dandurand.along_name = "5e Avenue"
	dandurand.facing = "east"
	dandurand.school = true
	dandurand.left_walls = _walls_along("res://scenes/dandurand.gd", "rue_5e", 1, "coin_5e_dandurand")
	dandurand.right_walls = [
		{"to": 2.6, "top": _house_top("ecole"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	# Down Masson toward 6e, its real buildings: the presbytery and the church on the left (the north side), the south side on
	# the right.
	var masson := _cross_street("rue_masson", "Rue Masson", -1.0)
	masson.along_name = "5e Avenue"
	masson.facing = "east"
	masson.left_walls = _walls_along("res://scenes/masson.gd", "rue_5e", 1, "", {"side": "impair"})
	masson.right_walls = _walls_along("res://scenes/masson.gd", "rue_5e", -1, "", {"side": "pair"})
	# The church's great tower turns its west face toward us past the presbytery (masson_presbytere 1200 wide, the tower at
	# 1610–1990 of masson_eglise).
	var front := _tex("masson_eglise")
	masson.towers.append({"side": -1.0, "d": (1140.0 + 1580.0) * HOUSE_SCALE / 650.0, "back": 380.0 * HOUSE_SCALE,
		"tex": front, "rect": Rect2(1610.0, 0.0, 380.0, front.get_height() - 560.0)})


func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "ruelle_verte":
		_label("RUELLE\nVERTE", house.position + Vector2(_tex("ruelle_verte").get_width() / 2.0 + 90.0, 416.0) * HOUSE_SCALE, Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/holt.tscn", "holt_from_5e", false)
	_add_corner(_cross_streets[1], "res://scenes/dandurand.tscn", "dandurand_from_5e", false, -1)
	# Over 5e Avenue to its west side (cinquieme_ouest), at every corner.
	_add_across(_cross_streets[0], "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_5e_holt", 1)
	_add_across(_cross_streets[1], "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_5e_dandurand", -1)
	_add_across(_cross_streets[1], "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_5e_dandurand_sud", 1)
	_add_across(_cross_streets[2], "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_5e_masson", -1)
	# On Masson at the 5e corner of the church's block (the north side, right of 5e).
	_add_corner(_cross_streets[2], "res://scenes/masson_impair.tscn", "masson_impair_from_rue_5e_5e_6e", false, -1)
	_add_lane("ruelle")
	_add_lane("ruelle_verte")


## Where Rue Dandurand crosses, as a fraction of the street: the town map puts her on her block before it, toward Masson after.
func _dandurand_f() -> float:
	return (_starts[layout.find("rue_dandurand")] + _starts[layout.find("rue_dandurand") + 1]) / 2.0 / _street_width
