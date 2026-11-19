extends StreetScene
# Rue Dandurand, its north side (the odd numbers), in ONE scene from 3e Avenue (left) to 7e Avenue (right), seen from the south
# sidewalk — a street is one scene per side (Julien). Drawn from the Street View pictures (reference/streetview/INDEX.md, "Rue
# Dandurand 2650–3050 (impairs)" and the walk "Rue Dandurand 3e–7e"; facades `dand_*`): the corner across 3e, the dépanneur 7
# jours at the 3e corner, the buff and salmon triplexes, the duplexes of the 1970s over their garages, 4e Avenue, the grey stone
# triplex and the red-brick rows with their crests, the tan triplexes, 5e Avenue, Charlotte's own block (2851–2881 and dépanneur
# Xin-Xin's real front, from the photos in reference/), 6e Avenue, the walk-ups and the block of the 1970s to 7e, and the corner
# across 7e. She turns onto 5e and 6e at their corners; at every corner the crosswalk over Dandurand leads to its south side
# (`dandurand_sud.tscn`), with the school.


func _init() -> void:
	street_key = "dandurand"
	# Back lanes only open onto the north-south streets (like 6e Avenue), never onto Dandurand.
	layout = [
		"dand_n_coin_3e", "rue_3e",
		"dand_2701", "dand_2711", "dand_2727", "dand_2733", "dand_2751", "dand_2767", "rue_4e",
		"dand_2801", "dand_2813", "dand_2819", "dand_2827", "dand_2831", "dand_2833", "dand_2849", "rue_5e",
		"dand_2851", "dand_2853", "dand_2865", "dand_2879", "depanneur_front", "rue_6e",
		"dand_2901", "dand_2907", "dand_2915", "dand_2919", "dand_2939", "rue_7e",
		"dand_n_coin_7e",
	]
	cross_streets = {"rue_3e": 520.0, "rue_4e": 520.0, "rue_5e": 540.0, "rue_6e": 560.0, "rue_7e": 520.0}
	# Where the pictures have street trees (the young ones by 2701 and 2873, the big ones by 2711, 2801, 2851, 2879, 2915…).
	trees_after = [2, 3, 5, 9, 10, 12, 14, 17, 18, 20, 23, 25, 26]
	lamps_after = [4, 11, 19, 24]
	hydrants_at = [2.1, 15.9, 21.97, 27.9]
	racks_at = [13.5]
	squirrels_at = [10.4, 18.4, 25.4]
	passerby_ages = ["adult", "senior"]
	seed_value = 2891


# Round a corner from 5e or 6e Avenue, over Dandurand from its south side, out of the dépanneur, or in front of it.
func _start_x() -> float:
	if _arriving("dandurand_from_6e"):
		return _starts[layout.find("rue_6e")] - 40.0
	if _arriving("dandurand_from_5e"):
		return _starts[layout.find("rue_5e") + 1] + 40.0
	if _arriving("dandurand_from_6e_est"):
		return _starts[layout.find("rue_6e") + 1] + 40.0
	if _arriving("dandurand_from_5e_ouest"):
		return _starts[layout.find("rue_5e")] - 40.0
	# Over Dandurand from the south side: "dandurand_from_sud_<gap>_<o|e>", the corner west (o) or east (e) of that avenue.
	if Transition.arrive.begins_with("dandurand_from_sud_"):
		var rest := Transition.arrive.trim_prefix("dandurand_from_sud_")
		Transition.arrive = ""
		var gap := layout.find(rest.left(-2))
		if gap >= 0:
			return _starts[gap] - 40.0 if rest.ends_with("_o") else _starts[gap + 1] + 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.find("depanneur_front") + 0.5)


# The avenues seen up their length, all running north from here: just sky that way. 5e and 6e are drawn (their real buildings);
# 3e, 4e and 7e aren't yet.
func _build_cross_streets() -> void:
	var third := _cross_street("rue_3e", "3e Avenue", 1.0)
	_generic_vista(third, "#8E4A3A", "#B5603F")
	var fourth := _cross_street("rue_4e", "4e Avenue", 1.0)
	_generic_vista(fourth, "#A8473A", "#7E4436")
	var fifth := _cross_street("rue_5e", "5e Avenue", 1.0)
	fifth.along_name = "Rue Dandurand"
	fifth.facing = "north"
	fifth.school = true
	# The west side of 5e Avenue, from the Street View pictures (cinquieme_ouest).
	fifth.left_walls = _walls_along("res://scenes/cinquieme_ouest.gd", "rue_dandurand", 1, "dand_2849")
	fifth.right_walls = _walls_along("res://scenes/cinquieme.gd", "rue_dandurand", -1, "dand_2851")
	var sixth := _cross_street("rue_6e", "6e Avenue", 1.0)
	sixth.along_name = "Rue Dandurand"
	# 6e Avenue runs north from here: no mountain that way, just sky.
	sixth.facing = "north"
	sixth.school = true
	sixth.left_walls = _walls_along("res://scenes/main.gd", "rue_dandurand", 1, "depanneur_front")
	# The odd side of 6e Avenue, from the Street View pictures (sixieme_est).
	sixth.right_walls = _walls_along("res://scenes/sixieme_est.gd", "rue_dandurand", -1, "dand_2901")
	var seventh := _cross_street("rue_7e", "7e Avenue", -1.0)
	_generic_vista(seventh, "#9C5A44", "#B4513F")


## An avenue that isn't drawn yet, up its length: plexes both sides, the corner buildings first (`_join_corners` gives them our
## corners' height and brick).
func _generic_vista(cs: CrossStreet, left: String, right: String) -> void:
	cs.along_name = "Rue Dandurand"
	cs.facing = "north"
	cs.left_walls = [
		{"to": 0.9, "top": 300.0, "kind": "plex", "color": Color(left)},
		{"to": 2.4, "top": 290.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	cs.right_walls = [
		{"to": 0.9, "top": 300.0, "kind": "plex", "color": Color(right)},
		{"to": 2.3, "top": 290.0, "kind": "plex", "color": Color("#7E4436")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
	]


# The shop sign's words on the blue board.
func _decorate_house(i: int, house: Sprite2D) -> void:
	if layout[i] == "depanneur_front":
		_label("DÉPANNEUR XIN-XIN", house.position + Vector2(390, 396) * HOUSE_SCALE, Vector2(150, 18), 13, Color.WHITE, Color("#16285C"))
		_label("LIVRAISON  514 728-8827", house.position + Vector2(390, 418) * HOUSE_SCALE, Vector2(150, 14), 8, Color("#FFD23F"), Color("#16285C"))
		# The Coors logos either side of the shop's sign, the Coors Light neon in the right window and the words of the green
		# poster in the left one, as on reference/coin_dandurand/dépanneur_on_dandurand.jpg (art/brands/SOURCES.md).
		for at: Vector2 in [Vector2(159, 396), Vector2(621, 396)]:
			_logo(house, "coors_logo_red.svg", at, 22.0)
		_logo(house, "coors_light_logo.svg", Vector2(590, 478), 11.0)
		_label("Plus qu'une\ncourse", house.position + Vector2(191, 500) * HOUSE_SCALE, Vector2(80, 30), 8, Color.WHITE, Color("#0E4A28"))
	if layout[i] == "dand_2701":
		# The dépanneur 7 jours at the 3e corner: its orange sign band (`_corner_shop`).
		_label("dépanneur 7 jours", house.position + Vector2(115, 643) * HOUSE_SCALE, Vector2(88, 20), 9, Color("#2A1A10"), Color("#F4F1EA"))


## A brand's logo (art/brands/) laid on a facade at `at` (its SVG units), `height` px high in the world.
func _logo(house: Sprite2D, file: String, at: Vector2, height: float) -> void:
	var tex: Texture2D = load("res://art/brands/%s" % file)
	var logo := Sprite2D.new()
	logo.texture = tex
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.scale = Vector2.ONE * height / tex.get_height()
	logo.position = house.position + at * HOUSE_SCALE
	add_child(logo)


func _build_doors() -> void:
	var fifth := _cross_streets[2]
	var sixth := _cross_streets[3]
	# Round the corners onto 5e and 6e Avenue: her block's side of each (cinquieme, main) and the side across (cinquieme_ouest,
	# sixieme_est).
	_add_corner(fifth, "res://scenes/cinquieme.tscn", "5e_from_dandurand", false, 1)
	_add_corner(fifth, "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_dandurand", false, -1)
	_add_corner(sixth, "res://scenes/main.tscn", "6e_from_dandurand", false, -1)
	_add_corner(sixth, "res://scenes/sixieme_est.tscn", "6e_est_from_dandurand", false, 1)
	# Every corner's crosswalk over Dandurand goes to its south side, at the same corner.
	for cs in _cross_streets:
		var gap: String = layout[_starts.find(cs.x0)]
		_add_across(cs, "res://scenes/dandurand_sud.tscn", "dandurand_sud_from_nord_%s_o" % gap, -1)
		_add_across(cs, "res://scenes/dandurand_sud.tscn", "dandurand_sud_from_nord_%s_e" % gap, 1)
	# The dépanneur's glass door, at the top of its steps.
	var origin := _house_origin(layout.find("depanneur_front"))
	var area := Rect2(origin + Vector2(338.0, 503.0) * HOUSE_SCALE, Vector2(104.0, 97.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		# Shut on Halloween night: the dépanneurs close early that evening.
		if _shop_shut():
			return
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
