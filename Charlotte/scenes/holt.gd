extends StreetScene
# Rue Holt, the short side of Charlotte's block, seen from across the street: 6e Avenue crosses at the left end,
# 5e Avenue at the right. No back lane opens onto Holt (they only open onto the avenues). Click either avenue to
# turn the corner: round the block without crossing a street.


func _init() -> void:
	street_key = "holt"
	# Dépanneur Oh Bon! on the 6e corner (reference/holt_coin_6eme.png), then the plexes.
	layout = ["holt_nord", "rue_6e", "ohbon", "plex_14", "plex_15", "plex_16", "rue_5e", "holt_sud"]
	cross_streets = {"rue_6e": 560.0, "rue_5e": 540.0}
	trees_after = [2, 4]
	lamps_after = [3]
	hydrants_at = [2.15]
	racks_at = [4.6]
	squirrels_at = [3.5]
	passerby_ages = ["adult", "senior"]
	seed_value = 3317


func _start_x() -> float:
	if _arriving("holt_from_6e"):
		return _starts[layout.find("rue_6e") + 1] + 40.0
	if _arriving("holt_from_5e"):
		return _starts[layout.find("rue_5e")] - 40.0
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
	sixth.left_walls = [
		{"to": 0.7, "top": _house_top("holt_nord"), "kind": "plex", "color": Color("#A8473A")},
		{"to": 2.4, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	sixth.right_walls = _walls_along("res://scenes/main.gd", "rue_holt", -1)
	var fifth := _cross_street("rue_5e", "5e Avenue", -1.0)
	fifth.along_name = "Rue Holt"
	fifth.facing = "south"
	fifth.left_walls = _walls_along("res://scenes/cinquieme.gd", "rue_holt", 1)
	fifth.right_walls = [
		{"to": 0.7, "top": _house_top("holt_sud"), "kind": "plex", "color": Color("#C8A27A")},
		{"to": 2.2, "top": 280.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#B5603F")},
	]


# Dépanneur Oh Bon!'s sign and window lettering (plain text, not its logo).
func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "ohbon":
		var sy := _house_origin(i).y + (875.0 - 270.0 + 20.0) * HOUSE_SCALE
		_label("DÉPANNEUR", Vector2(house.position.x + 280.0 * HOUSE_SCALE, sy), Vector2(150, 18), 13, Color("#C8202A"), Color("#F4F1EA"))
		_label("OH BON !", Vector2(house.position.x + 137.0 * HOUSE_SCALE, sy + 60.0), Vector2(100, 26), 20, Color("#E8352B"), Color("#FFFFFF"))


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/main.tscn", "6e_from_holt")
	_add_corner(_cross_streets[1], "res://scenes/cinquieme.tscn", "5e_from_holt")
