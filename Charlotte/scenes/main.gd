extends StreetScene
# Charlotte's side of 6e Avenue seen from the sidewalk: Dandurand on the left, Holt on the right.
# Across each cross street, the first building of the next block (the school across Dandurand).
# The generic street (sky, houses, trees, people, animals, camera) lives in StreetScene.


func _init() -> void:
	street_key = "6e"
	layout = [
		"ecole", "rue_dandurand",
		"depanneur", "garages", "ruelle_verte",
		"triplex_exemple_2", "plex_02", "plex_03", "moderne", "plex_04",
		"duplex_voisin_gauche", "duplex_charlotte", "duplex_voisin_droite",
		"plex_05", "triplex_exemple_3", "plex_06", "plex_07", "plex_08", "plex_09",
		"ruelle", "coin_holt",
		"rue_holt", "coin_holt_est",
	]
	cross_streets = {"rue_dandurand": 560.0, "rue_holt": 520.0}
	trees_after = [6, 8, 10, 13, 15, 17]
	lamps_after = [4, 9, 14, 18]
	hydrants_at = [7.5, 16.3]
	racks_at = [2.5, 12.55, 15.6]
	squirrels_at = [4.2, 9.5, 14.6, 18.4]


# In front of her duplex, back where she left the street (from her flat), at a corner or out of the lane.
func _start_x() -> float:
	if _arriving("6e_from_dandurand"):
		return _starts[layout.find("depanneur")] + 60.0
	if _arriving("6e_from_holt"):
		return _starts[layout.find("rue_holt")] - 40.0
	var lane := _from_lane()
	if not is_nan(lane):
		return lane
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _starts[layout.find("duplex_charlotte")] + 150.0


# Rue Dandurand (left, from the reference photos: the dépanneur's real front, the school across) and Rue Holt
# (right). The vistas go behind the houses.
func _build_cross_streets() -> void:
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", 1.0)
	dandurand.school = true
	dandurand.guard = true
	dandurand.left_walls = [
		{"to": 2.6, "top": _house_top("ecole"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	dandurand.right_walls = [
		{"to": 0.45, "top": _house_top("depanneur"), "kind": "shop", "color": Color("#6E3A2E")},
		{"to": 2.2, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 260.0, "kind": "plex", "color": Color("#C8A27A")},
	]
	var holt := _cross_street("rue_holt", "Rue Holt", -1.0)
	holt.left_walls = [
		{"to": 0.6, "top": _house_top("coin_holt"), "kind": "plex", "color": Color("#B5603F")},
		{"to": 2.4, "top": 290.0, "kind": "plex", "color": Color("#A8473A")},
		{"to": CrossStreet.FAR, "top": 320.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	holt.right_walls = [
		{"to": 0.7, "top": _house_top("coin_holt_est"), "kind": "plex", "color": Color("#9C6B4E")},
		{"to": 2.0, "top": 270.0, "kind": "plex", "color": Color("#8E3A2F")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B4513F")},
	]


func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "ruelle":
		# The neighbours' sign at the lane entrance by the Holt corner.
		# On its own post at the right of the entrance (drawn by the generator, as on the photo).
		var sign := _sprite(PropArt.slow_sign(), 0.6)
		sign.position = house.position + Vector2(_tex("ruelle").get_width() - 66.0, 300.0) * HOUSE_SCALE - Vector2(60.0 * 0.6, 0)
		add_child(sign)
		var mid := sign.position.x + 60.0 * 0.6
		_label("RALENTISSEZ !", Vector2(mid, sign.position.y + 12.0), Vector2(72, 12), 9, Color("#C8202A"), Color("#FFD23F"))
		_label("ENFANTS\nEN LIBERTÉ !", Vector2(mid, sign.position.y + 51.0), Vector2(72, 22), 8, Color("#1E1E1E"), Color("#FFD23F"))
	if layout[i] == "ruelle_verte":
		_label("RUELLE\nVERTE", house.position + Vector2(214, 416) * HOUSE_SCALE, Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


# The neighbours' cat on its railing.
func _build_landmarks() -> void:
	var cat := Cat.new()
	cat.position = _house_origin(layout.find("duplex_voisin_gauche")) + Vector2(300, 552) * HOUSE_SCALE
	cat.scale = Vector2.ONE * 0.7
	add_child(cat)


# Charlotte's own front door (ground floor of her duplex): click it to go inside. Click Rue Dandurand or Rue Holt
# to turn the corner, the lane entrances to go into the lane.
func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/dandurand.tscn", "dandurand_from_6e")
	_add_corner(_cross_streets[1], "res://scenes/holt.tscn", "holt_from_6e")
	_add_lane("ruelle_verte")
	_add_lane("ruelle")
	var origin := _house_origin(layout.find("duplex_charlotte"))
	var area := Rect2(origin + Vector2(278.0 - 48.0, 392.0) * HOUSE_SCALE, Vector2(96.0, 208.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_control.enabled = false
		Transition.street_x = area.get_center().x
		Sfx.play("door", area.get_center())
		Transition.change_scene(self, "res://scenes/house.tscn")))


# The dépanneur's sandwich board, out on the corner.
func _build_extra_props() -> void:
	var board := _sprite(PropArt.sandwich_board(), 0.62)
	board.position = Vector2(_starts[layout.find("depanneur")] + 70.0, CURB_Y - 14.0 - 120.0 * 0.62)
	add_child(board)
