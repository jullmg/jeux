extends StreetScene
# Rue Dandurand, seen from across the street, looking at dépanneur Xin-Xin's real front (from the photos in
# reference/). 5e Avenue crosses at the left end, 6e Avenue at the right: click either to turn the corner.


func _init() -> void:
	street_key = "dandurand"
	# Back lanes only open onto the north-south streets (like 6e Avenue), never onto Dandurand.
	layout = ["dandurand_sud", "rue_5e", "plex_11", "plex_12", "plex_10", "depanneur_front", "rue_6e", "dandurand_nord"]
	cross_streets = {"rue_5e": 540.0, "rue_6e": 560.0}
	trees_after = [2, 3]
	lamps_after = [2]
	hydrants_at = [5.97]
	squirrels_at = [3.4]
	passerby_ages = ["adult"]
	seed_value = 2891


# Round the corner from 6e Avenue, out of the dépanneur, or in front of it.
func _start_x() -> float:
	if _arriving("dandurand_from_6e"):
		return _starts[layout.find("rue_6e")] - 40.0
	if _arriving("dandurand_from_5e"):
		return _starts[layout.find("rue_5e") + 1] + 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(5.5)


# 5e Avenue (left) and 6e Avenue (right) seen down their length, both running north from here: just sky that way.
# On 5e, Charlotte's block is on the right; on 6e, on the left (the dépanneur's side, the garages, the green lane).
func _build_cross_streets() -> void:
	var fifth := _cross_street("rue_5e", "5e Avenue", 1.0)
	fifth.along_name = "Rue Dandurand"
	fifth.facing = "north"
	fifth.left_walls = [
		{"to": 0.7, "top": _house_top("dandurand_sud"), "kind": "plex", "color": Color("#7A4A3A")},
		{"to": 2.6, "top": 290.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#A8473A")},
	]
	fifth.right_walls = _walls_along("res://scenes/cinquieme.gd", "rue_dandurand", -1, "plex_11")
	var sixth := _cross_street("rue_6e", "6e Avenue", 1.0)
	sixth.along_name = "Rue Dandurand"
	# 6e Avenue runs north from here: no mountain that way, just sky.
	sixth.facing = "north"
	sixth.left_walls = _walls_along("res://scenes/main.gd", "rue_dandurand", 1, "depanneur_front")
	sixth.right_walls = [
		{"to": 0.7, "top": _house_top("dandurand_nord"), "kind": "plex", "color": Color("#C2A07A")},
		{"to": 2.4, "top": 280.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#B5603F")},
	]


# The shop sign's words on the blue board.
func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "depanneur_front":
		_label("DÉPANNEUR XIN-XIN", house.position + Vector2(390, 396) * HOUSE_SCALE, Vector2(150, 18), 13, Color.WHITE, Color("#16285C"))
		_label("LIVRAISON", house.position + Vector2(390, 418) * HOUSE_SCALE, Vector2(150, 14), 9, Color("#FFD23F"), Color("#16285C"))


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/cinquieme.tscn", "5e_from_dandurand")
	_add_corner(_cross_streets[1], "res://scenes/main.tscn", "6e_from_dandurand")
	# The dépanneur's glass door, at the top of its steps.
	var origin := _house_origin(layout.find("depanneur_front"))
	var area := Rect2(origin + Vector2(338.0, 503.0) * HOUSE_SCALE, Vector2(104.0, 97.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_control.enabled = false
		Transition.street_x = area.get_center().x
		Sfx.play("bell")
		Transition.change_scene(self, "res://scenes/depanneur.tscn"), area.get_center().x))


# The ice chest and the flattened boxes by the dépanneur's steps, against its wall (people walk in front).
func _build_sidewalk_props() -> void:
	var origin := _house_origin(layout.find("depanneur_front"))
	var chest := _sprite(PropArt.ice_chest(), 0.5)
	chest.position = origin + Vector2(500, 700) * HOUSE_SCALE + Vector2(0, -120 * 0.5 + 12)
	add_child(chest)
	_label("GLACE", chest.position + Vector2(65, 36) * 0.5, Vector2(60, 14), 9, Color.WHITE, Color("#1D3F7A"))
	var boxes := _sprite(PropArt.cardboard(), 0.5)
	boxes.position = origin + Vector2(150, 700) * HOUSE_SCALE + Vector2(0, -80 * 0.5 + 10)
	add_child(boxes)
