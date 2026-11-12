extends StreetScene
# Rue Holt, the short side of Charlotte's block, seen from across the street: 6e Avenue crosses at the left end,
# 5e Avenue at the right. No back lane opens onto Holt (they only open onto the avenues). Click either avenue to
# turn the corner: round the block without crossing a street.


func _init() -> void:
	street_key = "holt"
	# Dépanneur Oh Bon! on the 6e corner (reference/coin_holt/holt_coin_6eme.png), then the plexes.
	layout = ["holt_nord", "rue_6e", "ohbon", "plex_14", "plex_15", "plex_16", "plex_28", "rue_5e", "holt_sud"]
	cross_streets = {"rue_6e": 560.0, "rue_5e": 540.0}
	trees_after = [2, 4]
	lamps_after = [3]
	hydrants_at = [2.15]
	racks_at = [4.6]
	squirrels_at = [3.5]
	passerby_ages = ["senior"]
	seed_value = 3317


func _start_x() -> float:
	if _arriving("holt_from_6e"):
		return _starts[layout.find("rue_6e") + 1] + 40.0
	if _arriving("holt_from_5e"):
		return _starts[layout.find("rue_5e")] - 40.0
	if _arriving("holt_from_6e_est"):
		return _starts[layout.find("rue_6e")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(4.0)


# Both avenues run south from here (Montreal's compass): sky at the end, no mountain.
func _build_cross_streets() -> void:
	var sixth := _cross_street("rue_6e", "6e Avenue", 1.0)
	sixth.along_name = "Rue Holt"
	sixth.facing = "south"
	# The odd side of 6e Avenue, from the Street View pictures (sixieme_est).
	sixth.left_walls = _walls_along("res://scenes/sixieme_est.gd", "rue_holt", 1, "holt_nord")
	sixth.right_walls = _walls_along("res://scenes/main.gd", "rue_holt", -1, "ohbon")
	var fifth := _cross_street("rue_5e", "5e Avenue", -1.0)
	fifth.along_name = "Rue Holt"
	fifth.facing = "south"
	fifth.left_walls = _walls_along("res://scenes/cinquieme.gd", "rue_holt", 1, "plex_16")
	fifth.right_walls = [
		{"to": 0.7, "top": _house_top("holt_sud"), "kind": "plex", "color": Color("#C8A27A")},
		{"to": 2.2, "top": 280.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#B5603F")},
	]


# Dépanneur Oh Bon! (reference/coin_holt/holt_coin_6eme.png): the words on its light-box sign, "OH BON!" in red neon in the big
# window right of the door, a beer neon in the narrow window (plain text, no logos). SVG coordinates: the shop's
# first gallery floor at y 600, the light box at x 116-366, y 660-692.
func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] != "ohbon":
		return
	var at := func(p: Vector2) -> Vector2: return house.position + p * HOUSE_SCALE
	_label("OH BON!", at.call(Vector2(164, 675)), Vector2(60, 14), 10, Color("#D9342B"), Color("#F4F1EA"))
	_label("DÉPANNEUR", at.call(Vector2(301, 676)), Vector2(62, 12), 8, Color.WHITE, Color("#D9342B"))
	var neon := NeonSign.new()
	neon.lines = ["OH", "BON!"]
	neon.font_size = 16
	neon.position = at.call(Vector2(289, 760))
	add_child(neon)
	var beer := NeonSign.new()
	beer.lines = ["BIÈRE"]
	beer.vertical = true
	beer.tilt = 0.0
	beer.font_size = 8
	beer.color = Color("#FF5A3A")
	beer.position = at.call(Vector2(62, 755))
	add_child(beer)


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/main.tscn", "6e_from_holt")
	_add_corner(_cross_streets[1], "res://scenes/cinquieme.tscn", "5e_from_holt")
	# Across 6e from her block, round onto the other side of 6e Avenue (sixieme_est).
	_add_corner(_cross_streets[0], "res://scenes/sixieme_est.tscn", "6e_est_from_holt", false, -1)
	# Oh Bon!'s black-framed glass door (SVG x 134-208, y 694-889): in to the shop.
	var origin := _house_origin(layout.find("ohbon"))
	var area := Rect2(origin + Vector2(134.0, 694.0) * HOUSE_SCALE, Vector2(74.0, 195.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		# Shut on Halloween night: the dépanneurs close early that evening.
		if _shop_shut():
			return
		_control.enabled = false
		Transition.street_x = area.get_center().x
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/ohbon.tscn"), area.get_center().x))
