extends StreetScene
# Rue Dandurand, its south side (the even numbers), in ONE scene from 7e Avenue (left) to 3e Avenue (right), seen from the north
# sidewalk — a street is one scene per side (Julien). Drawn from the Street View pictures (reference/streetview/INDEX.md, "Rue
# Dandurand 2650–3050 (pairs)" and the walk "Rue Dandurand 3e–7e"; facades `dand_*`): the corner across 7e, the triplexes of
# 2968–2910 and the painted red corner at 6e, 6e Avenue, then the whole block to 5e is École Saint-Jean-de-Brébeuf's front
# (`ecole`: its pavilions, the centre, the entrance up its steps under the flag, the fence and its lawn), 5e Avenue, the long
# side of 5594 5e Avenue and the duplexes to 4e, 4e Avenue, the brick duplexes and triplexes to 3e, and the corner across 3e.
# She comes here over Dandurand from its north side (`dandurand.tscn`) at any corner, or round the corners of 5e and 6e Avenue
# south of Dandurand.


func _init() -> void:
	street_key = "dandurand_sud"
	layout = [
		"dand_s_coin_7e", "rue_7e",
		"dand_2968", "dand_2948", "dand_2936", "dand_2920", "dand_2918", "dand_2910", "dand_2902", "rue_6e",
		"ecole", "rue_5e",
		"dand_2828", "dand_2820", "dand_2812", "dand_2808", "dand_2802", "rue_4e",
		"dand_2736", "dand_2726", "dand_2716", "dand_2708", "dand_2706", "dand_2700", "rue_3e",
		"dand_s_coin_3e",
	]
	cross_streets = {"rue_7e": 520.0, "rue_6e": 560.0, "rue_5e": 540.0, "rue_4e": 520.0, "rue_3e": 520.0}
	# Where the pictures have street trees; two young ones on the school's lawn, toward its ends so they leave its front in view.
	trees_after = [2, 4, 6, 7, 9, 10, 12, 14, 15, 18, 19, 20, 22]
	tree_shift = {9: 430.0, 10: -430.0}
	tree_size = {9: 0.48, 10: 0.48}
	lamps_after = [3, 9, 13, 19]
	hydrants_at = [8.8, 16.85, 23.85]
	# The bike racks by the school, at its 5e end (2846…, 2850…).
	racks_at = [10.9]
	squirrels_at = [4.4, 14.4, 21.4]
	passerby_ages = ["adult", "senior"]
	seed_value = 2893


# At the corner she came from: over Dandurand from its north side ("dandurand_sud_from_nord_<gap>_<o|e>"), or round the corner
# of 5e or 6e Avenue ("dandurand_sud_from_<gap>_<o|e>"); o is the corner west of that avenue (right of it here), e east of it.
func _start_x() -> float:
	if Transition.arrive.begins_with("dandurand_sud_from_"):
		var rest := Transition.arrive.trim_prefix("dandurand_sud_from_").trim_prefix("nord_")
		Transition.arrive = ""
		var gap := layout.find(rest.left(-2))
		if gap >= 0:
			return _starts[gap + 1] + 40.0 if rest.ends_with("_o") else _starts[gap] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	# In front of the school's steps.
	return _street_x(layout.find("ecole") + 0.42)


# The avenues seen down their length, all running south toward Masson: sky and clouds that way. 5e and 6e are drawn (their real
# buildings, the school's sides among them); 3e, 4e and 7e aren't yet.
func _build_cross_streets() -> void:
	var seventh := _cross_street("rue_7e", "7e Avenue", 1.0)
	_generic_vista(seventh, "#7A4434", "#A0503A")
	var sixth := _cross_street("rue_6e", "6e Avenue", 1.0)
	sixth.along_name = "Rue Dandurand"
	sixth.facing = "south"
	sixth.school = true
	# Down 6e toward Masson: its east side (sixieme_est) on the left, the school's side and the church's on the right (main).
	sixth.left_walls = _walls_along("res://scenes/sixieme_est.gd", "rue_dandurand", 1)
	sixth.right_walls = _walls_along("res://scenes/main.gd", "rue_dandurand", -1)
	var fifth := _cross_street("rue_5e", "5e Avenue", 1.0)
	fifth.along_name = "Rue Dandurand"
	fifth.facing = "south"
	fifth.school = true
	# Down 5e: the school's side and its block on the left (cinquieme), the west side on the right (cinquieme_ouest).
	fifth.left_walls = _walls_along("res://scenes/cinquieme.gd", "rue_dandurand", 1)
	fifth.right_walls = _walls_along("res://scenes/cinquieme_ouest.gd", "rue_dandurand", -1)
	var fourth := _cross_street("rue_4e", "4e Avenue", 1.0)
	_generic_vista(fourth, "#6E3E2E", "#7A4A38")
	var third := _cross_street("rue_3e", "3e Avenue", -1.0)
	_generic_vista(third, "#8A4A3A", "#9A4232")


## An avenue that isn't drawn yet, down its length: plexes both sides (`_join_corners` gives the first ones our corners' height
## and brick).
func _generic_vista(cs: CrossStreet, left: String, right: String) -> void:
	cs.along_name = "Rue Dandurand"
	cs.facing = "south"
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


## What she says at the school's front door: the pupils go in by the yard.
const SCHOOL_DOOR := ["C'est mon école ! Saint-Jean-de-Brébeuf.\nLes élèves rentrent par la cour, en arrière.",
	"La grande porte, c'est pour les grands\npis les visiteurs. Nous autres, c'est par la cour !",
	"Chut… Y a de l'école là-dedans !"]


func _build_doors() -> void:
	var sixth := _cross_streets[1]
	var fifth := _cross_streets[2]
	# Round the corners onto 6e and 5e Avenue south of Dandurand: the school's side of each (main, cinquieme) and the side across
	# (sixieme_est, cinquieme_ouest).
	_add_corner(sixth, "res://scenes/sixieme_est.tscn", "6e_est_from_dandurand_sud", false, -1)
	_add_corner(sixth, "res://scenes/main.tscn", "6e_from_dandurand_sud", false, 1)
	_add_corner(fifth, "res://scenes/cinquieme.tscn", "5e_from_dandurand_sud", false, -1)
	_add_corner(fifth, "res://scenes/cinquieme_ouest.tscn", "5e_ouest_from_dandurand_sud", false, 1)
	# Every corner's crosswalk over Dandurand goes to its north side, at the same corner (east of an avenue is left of it here).
	for cs in _cross_streets:
		var gap: String = layout[_starts.find(cs.x0)]
		_add_across(cs, "res://scenes/dandurand.tscn", "dandurand_from_sud_%s_e" % gap, -1)
		_add_across(cs, "res://scenes/dandurand.tscn", "dandurand_from_sud_%s_o" % gap, 1)
	# The school's front door, at the top of its steps: she goes in by the yard, like every pupil.
	var origin := _house_origin(layout.find("ecole"))
	var mid := _tex("ecole").get_width() / 2.0
	var area := Rect2(origin + Vector2(mid - 70.0, 590.0) * HOUSE_SCALE, Vector2(140.0, 385.0) * HOUSE_SCALE)
	add_child(DoorSpot.make(area, func():
		_charlotte.express("happy", 2.0)
		Bubble.say(self, _charlotte.position + Vector2(0, -210.0), SCHOOL_DOOR[randi() % SCHOOL_DOOR.size()], 3.5), area.get_center().x))


# The school's name board on its lawn, left of the steps, behind the fence (the pictures have a board there, 2862…, 2866…).
func _build_sidewalk_props() -> void:
	var origin := _house_origin(layout.find("ecole"))
	var mid := _tex("ecole").get_width() / 2.0
	var board := SchoolBoard.new()
	board.position = origin + Vector2(mid - 330.0, _tex("ecole").get_height() - 8.0) * HOUSE_SCALE
	add_child(board)
	_label("École\nSaint-Jean-de-Brébeuf", board.position + Vector2(0, -44.0), Vector2(84, 24), 8, Color.WHITE, Color("#1D4F91"))


## The board on its two posts: navy, a white rim, a little roof of shade under it.
class SchoolBoard extends Node2D:
	func _draw() -> void:
		for px: float in [-34.0, 30.0]:
			draw_rect(Rect2(px, -40.0, 4.0, 40.0), Color("#3A3D42"))
			draw_rect(Rect2(px, -40.0, 1.5, 40.0), Color("#6E7176"))
		draw_rect(Rect2(-46.0, -62.0, 92.0, 34.0), Color("#1D4F91"))
		draw_rect(Rect2(-46.0, -62.0, 92.0, 34.0), Color("#F4F1EA"), false, 2.0)
		draw_rect(Rect2(-46.0, -28.0, 92.0, 3.0), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(-40.0, -1.0, 80.0, 3.0), Color(0, 0, 0, 0.18))
