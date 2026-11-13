extends StreetScene
# 6e Avenue between Rue Masson (left) and Rue Dandurand (right), Charlotte's side (the west side, even numbers), seen from the
# east sidewalk like her own block: drawn from the Street View pictures (reference/streetview/INDEX.md, "6e Avenue" 5360… to
# 5590…; facades `six_sud_*` in tools/generate_houses.gd). Left to right: the side of the Banque Nationale across Masson, Rue
# Masson, the long side of Église Saint-Esprit and its parish hall, the modern apartment block behind its court, the schoolyard,
# the school's gym and the school itself (`ecole`, already drawn from its photo, the same as at the left end of main.tscn), Rue
# Dandurand and the side of Xin-Xin across it.
# She comes here by crossing Dandurand southward from her block (main.tscn), and crossing it back takes her home again; at the
# Masson corner she can turn onto Rue Masson (its north side, by the church).


func _init() -> void:
	street_key = "6e_sud"
	layout = [
		"masson_2892_cote", "rue_masson",
		"six_sud_eglise", "six_sud_salle", "six_sud_appartements", "six_sud_cour", "six_sud_gymnase", "ecole_6e",
		"rue_dandurand", "depanneur",
	]
	cross_streets = {"rue_masson": 600.0, "rue_dandurand": 560.0}
	trees_after = [3, 4, 5]
	lamps_after = [3, 5]
	hydrants_at = [4.5]
	racks_at = []
	squirrels_at = [3.5, 5.5]
	seed_value = 6602


# At the Dandurand curb when she came across from her block, at the Masson corner when she came round it, else by the court.
func _start_x() -> float:
	if _arriving("6e_sud_from_6e"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if _arriving("6e_sud_from_masson") or _arriving("6e_sud_from_est_masson"):
		return _starts[layout.find("rue_masson") + 1] + 40.0
	if _arriving("6e_sud_from_est_dandurand"):
		return _starts[layout.find("rue_dandurand")] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _starts[layout.find("six_sud_appartements")] + 200.0


# Both cross streets run west from 6e (Mount Royal at the end). Down Masson the church's front and the Masson shops (north side);
# down Dandurand the school on the left and Xin-Xin's front on the right, as from her block.
func _build_cross_streets() -> void:
	var masson := _cross_street("rue_masson", "Rue Masson", 1.0)
	masson.facing = "west"
	masson.left_walls = [
		{"to": 1.2, "top": 330.0, "kind": "plex", "color": Color("#8E4A3A")},
		{"to": 2.6, "top": 300.0, "kind": "plex", "color": Color("#B5B1A9")},
		{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	# The church's grey stone front along Masson, then the presbytery's red brick and the shops beyond (its facade is too tall to be
	# laid in perspective as a texture).
	masson.right_walls = [
		{"to": 1.4, "top": 230.0, "kind": "plex", "color": Color("#A8A49C")},
		{"to": 2.0, "top": 300.0, "kind": "plex", "color": Color("#9A3E30")},
		{"to": CrossStreet.FAR, "top": 310.0, "kind": "plex", "color": Color("#8E5A44")},
	]
	var dandurand := _cross_street("rue_dandurand", "Rue Dandurand", -1.0)
	dandurand.school = true
	dandurand.left_walls = [
		{"to": 2.6, "top": _house_top("ecole_6e"), "kind": "school", "color": Color("#A9472F")},
		{"to": CrossStreet.FAR, "top": 330.0, "kind": "plex", "color": Color("#9C5A44")},
	]
	dandurand.right_walls = _walls_along("res://scenes/dandurand.gd", "rue_6e", -1)


# Round the Masson corner onto Rue Masson's north side (by the church), and over 6e Avenue to its other side.
func _build_doors() -> void:
	_add_corner(_cross_streets[0], "res://scenes/masson_impair.tscn", "masson_impair_from_rue_6e_5e_6e", false, 1)
	# Over 6e Avenue at either corner, to the other side (sixieme_sud_est).
	_add_across(_cross_streets[0], "res://scenes/sixieme_sud_est.tscn", "6e_sud_est_from_sud_masson", 1)
	_add_across(_cross_streets[1], "res://scenes/sixieme_sud_est.tscn", "6e_sud_est_from_sud_dandurand", -1)


# Crossing Dandurand northward takes her back onto her own block (main.tscn), at its Dandurand corner.
func _cross(cs: CrossStreet) -> void:
	if cs != _cross_streets[1] or _charlotte.position.x > cs.x1:
		super._cross(cs)
		return
	_cross_to(cs, "res://scenes/main.tscn", "6e_from_sud")
