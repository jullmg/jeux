extends StreetScene
# Charlotte's side of 6e Avenue (the west side, even numbers) seen from the other sidewalk, in ONE scene from Rue Masson (left)
# to Rue Holt (right) — a street is one scene per side (Julien). Left to right: the side of the Banque Nationale across Masson,
# Rue Masson, the long side of Église Saint-Esprit and its parish hall, the modern apartment block behind its court, the
# schoolyard, the school's gym and the school's side (`ecole_6e`), all drawn from the Street View pictures (INDEX.md "6e
# Avenue" 5360… to 5590…; facades `six_sud_*`), Rue Dandurand, then her own block up to Holt, and the corner across Holt.
# The generic street (sky, houses, trees, people, animals, camera) lives in StreetScene.


var _window_neighbour: WindowNeighbour


func _init() -> void:
	street_key = "6e"
	layout = [
		"masson_2892_cote", "rue_masson",
		"six_sud_eglise", "six_sud_salle", "six_sud_appartements", "six_sud_cour", "six_sud_gymnase",
		"ecole_6e", "rue_dandurand",
		"depanneur", "garages", "ruelle_verte",
		"six_5640", "six_5644", "six_5648", "six_5652", "six_5660",
		"duplex_voisin_gauche", "duplex_charlotte", "duplex_voisin_droite",
		"six_5688", "six_5692", "six_5700", "six_5712", "duplex_jumelles", "six_5718",
		"ruelle", "coin_holt",
		"rue_holt", "coin_holt_est",
	]
	cross_streets = {"rue_masson": 600.0, "rue_dandurand": 560.0, "rue_holt": 520.0}
	# Below Dandurand (indices up to 7), then her block (indices from 8).
	trees_after = [3, 4, 5, 13, 15, 17, 20, 22, 24]
	# The tree in front of Charlotte's house stands toward its Holt end, past the window to the right of her door, big, its crown
	# high up, which leaves her doors in view.
	tree_shift = {17: 340.0}
	tree_size = {17: 0.72}
	lamps_after = [3, 5, 11, 16, 21, 25]
	hydrants_at = [4.5, 14.5, 23.3]
	racks_at = [9.5, 18.55, 22.6]
	squirrels_at = [3.5, 5.5, 11.2, 16.5, 21.6, 25.4]


# In front of her duplex, back where she left the street (from her flat), at a corner or out of the lane.
func _start_x() -> float:
	if _arriving("6e_from_dandurand") or _arriving("6e_from_6e_est_dandurand"):
		return _starts[layout.find("depanneur")] + 60.0
	if _arriving("6e_from_6e_est_dandurand_sud"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("6e_from_masson") or _arriving("6e_from_6e_est_masson"):
		return _starts[layout.find("rue_masson") + 1] + 40.0
	if _arriving("6e_from_holt") or _arriving("6e_from_6e_est_holt"):
		return _starts[layout.find("rue_holt")] - 40.0
	var lane := _from_lane()
	if not is_nan(lane):
		return lane
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _starts[layout.find("duplex_charlotte")] + 150.0


# Rue Masson, Rue Dandurand (from the reference photos: the dépanneur's real front, the school across) and Rue Holt. The
# vistas go behind the houses; all three run west from 6e (Mount Royal at the end).
func _build_cross_streets() -> void:
	# Down Masson toward 5e, its real buildings (Julien): the south side (masson_pair) on the left, the church and the north side
	# (masson_impair) on the right.
	var masson := _cross_street("rue_masson", "Rue Masson", 1.0)
	masson.facing = "west"
	masson.left_walls = _walls_along("res://scenes/masson.gd", "rue_6e", 1, "", {"side": "pair"})
	masson.right_walls = _walls_along("res://scenes/masson.gd", "rue_6e", -1, "", {"side": "impair"})
	# The church's great tower, flush with its front: down Masson it turns its east face toward us, over the corner block.
	var front := _tex("masson_eglise")
	masson.towers.append({"side": 1.0, "d": (2870.0 - 1990.0) * HOUSE_SCALE / 650.0, "back": 380.0 * HOUSE_SCALE,
		"tex": front, "rect": Rect2(1610.0, 0.0, 380.0, front.get_height() - 560.0)})
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", 1.0)
	dandurand.school = true
	dandurand.guard = true
	dandurand.left_walls = [
		{"to": 2.6, "top": _house_top("ecole_6e"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	# Along Dandurand the first wall is Xin-Xin's own front (its door, its sign, its Coors logos' band), not a plain side: it keeps
	# its real facade (no `ours`).
	dandurand.right_walls = _walls_along("res://scenes/dandurand.gd", "rue_6e", -1)
	var holt := _cross_street("rue_holt", "Rue Holt", -1.0)
	holt.left_walls = _walls_along("res://scenes/holt.gd", "rue_6e", 1, "coin_holt")
	holt.right_walls = [
		{"to": 0.7, "top": _house_top("coin_holt_est"), "kind": "plex", "color": Color("#9C6B4E")},
		{"to": 2.0, "top": 270.0, "kind": "plex", "color": Color("#8E3A2F")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B4513F")},
	]


func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "coin_holt":
		# The old man in his armchair, behind the big upper pane of the annex window right of its door (SVG 234,707
		# 84x69: annex top 665, window at x 228 y 701).
		var neighbour := WindowNeighbour.new()
		neighbour.position = house.position + Vector2(234, 707) * HOUSE_SCALE
		neighbour.size = Vector2(84, 69) * HOUSE_SCALE
		add_child(neighbour)
		_window_neighbour = neighbour
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
		_label("RUELLE\nVERTE", house.position + Vector2(_tex("ruelle_verte").get_width() / 2.0 + 90.0, 416.0) * HOUSE_SCALE, Vector2(72, 36), 12, Color.WHITE, Color("#1E5E30"))


# Charlotte's own front door (ground floor of her duplex): click it to go inside. Round the corners onto Rue Masson (by the
# church), Rue Dandurand and Rue Holt (from her block), over 6e Avenue to its other side at every corner, the lane entrances to
# go into the lane. Each one names the stretch of sidewalk it belongs to, since the scene now holds several.
func _build_doors() -> void:
	_window_neighbour.charlotte = _charlotte
	var masson := _cross_streets[0]
	var dandurand := _cross_streets[1]
	var holt := _cross_streets[2]
	_add_corner(masson, "res://scenes/masson_impair.tscn", "masson_impair_from_rue_6e_5e_6e", false, 1)
	_add_corner(dandurand, "res://scenes/dandurand.tscn", "dandurand_from_6e", false, 1)
	_add_corner(holt, "res://scenes/holt.tscn", "holt_from_6e", false, -1)
	# Over 6e Avenue itself, to the other side of the street (the odd numbers, sixieme_est), at the matching corner.
	_add_across(masson, "res://scenes/sixieme_est.tscn", "6e_est_from_6e_masson", 1)
	_add_across(dandurand, "res://scenes/sixieme_est.tscn", "6e_est_from_6e_dandurand_sud", -1)
	_add_across(dandurand, "res://scenes/sixieme_est.tscn", "6e_est_from_6e_dandurand", 1)
	_add_across(holt, "res://scenes/sixieme_est.tscn", "6e_est_from_6e_holt", -1)
	_add_lane("ruelle_verte")
	_add_lane("ruelle")
	var origin := _house_origin(layout.find("duplex_charlotte"))
	var area := Rect2(Vector2(_door_x("duplex_charlotte") - 48.0 * HOUSE_SCALE, origin.y + 392.0 * HOUSE_SCALE), Vector2(96.0, 208.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_control.enabled = false
		Transition.street_x = area.get_center().x
		Sfx.play("door", area.get_center())
		Transition.change_scene(self, "res://scenes/house.tscn")))


## How far along the scene Rue Dandurand is (0..1), for the town map (`TownMap._here`).
func _dandurand_f() -> float:
	return (_starts[layout.find("rue_dandurand")] + _starts[layout.find("rue_dandurand") + 1]) / 2.0 / _street_width
