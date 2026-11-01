extends StreetScene
# Rue Holt, the short side of Charlotte's block, seen from across the street: 6e Avenue crosses at the left end,
# 5e Avenue at the right. No back lane opens onto Holt (they only open onto the avenues). Click either avenue to
# turn the corner: round the block without crossing a street.


func _init() -> void:
	street_key = "holt"
	layout = ["holt_nord", "rue_6e", "plex_13", "plex_14", "plex_15", "plex_16", "rue_5e", "holt_sud"]
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
	sixth.right_walls = [
		{"to": 0.6, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": 1.2, "top": 290.0, "kind": "plex", "color": Color("#7E4436")},
		{"to": 1.35, "kind": "gap"},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#A8473A")},
	]
	var fifth := _cross_street("rue_5e", "5e Avenue", -1.0)
	fifth.along_name = "Rue Holt"
	fifth.facing = "south"
	fifth.left_walls = [
		{"to": 0.6, "top": 300.0, "kind": "plex", "color": Color("#B5603F")},
		{"to": 1.1, "top": 290.0, "kind": "plex", "color": Color("#C8A27A")},
		{"to": 1.25, "kind": "gap"},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#8E3A2F")},
	]
	fifth.right_walls = [
		{"to": 0.7, "top": _house_top("holt_sud"), "kind": "plex", "color": Color("#C8A27A")},
		{"to": 2.2, "top": 280.0, "kind": "plex", "color": Color("#9C5A44")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#B5603F")},
	]


func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/main.tscn", "6e_from_holt")
	_add_corner(_cross_streets[1], "res://scenes/cinquieme.tscn", "5e_from_holt")
