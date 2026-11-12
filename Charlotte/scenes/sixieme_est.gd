extends StreetScene
# 6e Avenue, the other side: the odd numbers facing Charlotte's block (5601 to 5733), seen from her own sidewalk across the
# street, so Rue Holt crosses at the left end and Rue Dandurand at the right. Drawn from the Street View pictures
# (reference/streetview/INDEX.md, "6e Avenue 5600–5800 (impairs)"; the facades are the `impair_*` entries of
# tools/generate_houses.gd). She gets here by the crosswalk over 6e Avenue at either corner of main.tscn, and back the same way;
# the cross streets run east from here, to blocks the game doesn't go to yet, so their corners don't turn.


func _init() -> void:
	street_key = "6e_est"
	layout = [
		"impair_holt_nord", "rue_holt",
		"impair_coin_holt", "ruelle_impair_holt",
		"impair_5713", "impair_5707", "impair_5699", "impair_5689", "impair_5685", "impair_5679", "impair_5677",
		"impair_5669", "impair_5661", "impair_5655", "impair_5649", "impair_5641", "impair_5637", "impair_5631",
		"impair_5621", "impair_5615",
		"ruelle_impair_dandurand", "impair_5601",
		"rue_dandurand", "impair_dandurand_sud",
	]
	cross_streets = {"rue_holt": 520.0, "rue_dandurand": 560.0}
	# Street trees where the pictures have them: before 5707, 5689, 5669 and 5661, 5649, 5641, 5631, 5615, and 5601's big one.
	trees_after = [4, 6, 10, 12, 14, 15, 17, 19, 21]
	lamps_after = [5, 9, 13, 18]
	hydrants_at = [8.4, 16.5]
	racks_at = [7.6, 14.2]
	squirrels_at = [5.3, 11.4, 17.6]
	seed_value = 5527


# At the corner she crossed from, else in the middle of the block (a debug teleport, a reload).
func _start_x() -> float:
	if _arriving("6e_est_from_6e_holt"):
		return _starts[layout.find("rue_holt") + 1] + 40.0
	if _arriving("6e_est_from_6e_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.find("impair_5669") + 0.5)


# Both cross streets run east from here: no mountain, sky and clouds. Their far sides aren't drawn from photographs yet.
func _build_cross_streets() -> void:
	var holt := _cross_street("rue_holt", "Rue Holt", 1.0)
	holt.along_name = "6e Avenue"
	holt.facing = "east"
	holt.left_walls = [
		{"to": 0.7, "top": _house_top("impair_holt_nord"), "kind": "plex", "color": Color("#8E4A3A")},
		{"to": 2.4, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	holt.right_walls = [
		{"to": 0.9, "top": _house_top("impair_coin_holt"), "kind": "plex", "color": Color("#A8473A")},
		{"to": 2.3, "top": 290.0, "kind": "plex", "color": Color("#7E4436")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#C2A07A")},
	]
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", -1.0)
	dandurand.along_name = "6e Avenue"
	dandurand.facing = "east"
	dandurand.left_walls = [
		{"to": 1.0, "top": _house_top("impair_5601"), "kind": "plex", "color": Color("#C98A64")},
		{"to": 2.6, "top": 290.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
	]
	dandurand.right_walls = [
		{"to": 0.7, "top": _house_top("impair_dandurand_sud"), "kind": "plex", "color": Color("#B5603F")},
		{"to": 2.2, "top": 280.0, "kind": "plex", "color": Color("#A8473A")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#7E4436")},
	]


# Back over 6e Avenue at either corner; the lanes on this side aren't hers.
func _build_doors() -> void:
	_add_across(_cross_streets[0], "res://scenes/main.tscn", "6e_from_6e_est_holt")
	_add_across(_cross_streets[1], "res://scenes/main.tscn", "6e_from_6e_est_dandurand")
	for art in ["ruelle_impair_holt", "ruelle_impair_dandurand"]:
		var i := layout.find(art)
		var w := _tex(art).get_width()
		var area := Rect2(_house_origin(i) + Vector2(70.0, 330.0) * HOUSE_SCALE, Vector2(w - 140.0, 370.0) * HOUSE_SCALE)
		add_child(DoorSpot.make(area, func():
			_charlotte.express("worry", 2.0)
			Bubble.say(self, _charlotte.position + Vector2(0, -210.0), NOT_OUR_LANE[randi() % NOT_OUR_LANE.size()], 3.0), area.get_center().x))


## What she says at a lane on this side of 6e Avenue: it isn't hers, and she doesn't go into lanes she doesn't know.
const NOT_OUR_LANE := ["C'est pas ma ruelle, ça.\nJe la connais pas pantoute !",
	"Maman veut pas que j'aille\ndans les ruelles que je connais pas.",
	"Ma ruelle à moi, c'est de l'autre côté\nde la rue !"]
