class_name LostCats
extends RefCounted
## The neighbourhood's lost cats, one quest each (same id in Quests). A poster on a pole starts the quest; the cat
## waits where it got lost (a street or the lane); petting it, Charlotte picks it up (GameState.flags.carrying)
## and carries it, from scene to scene, to its owner's front door on the street, where the owner comes out.
## Streets build all of this in StreetScene._build_lost_cats().

## "e": "e" for a she-cat (perdue, retrouvée). found / home / poster: a street_key ("6e", "5e", "holt", "dandurand") or "ruelle". found_at: StreetScene
## position (layout index + fraction), or lot index + fraction in the lane. house: the owner's facade in `home`.
const ALL := {
	"cat": {
		"name": "Pistache", "coat": 2, "collar": "#2F7BD8", "collar_name": "bleu",
		"found": "dandurand", "found_at": 3.6, "poster": "6e",
		"home": "6e", "house": "plex_05", "address": "5684, 6e Avenue", "owner": "Mme Gagnon",
	},
	"cat2": {
		"name": "Caramel", "coat": 0, "collar": "#D9342B", "collar_name": "rouge",
		"found": "ruelle", "found_at": 3.5, "poster": "5e",
		"home": "5e", "house": "plex_21", "address": "5679, 5e Avenue", "owner": "M. Tremblay",
	},
	"cat3": {
		"name": "Bijou", "coat": 4, "collar": "#E85FA0", "collar_name": "rose",
		"found": "ruelle", "found_at": 12.6, "poster": "holt",
		"home": "holt", "house": "plex_15", "address": "2655, rue Holt", "owner": "Mme Nguyen", "e": "e",
	},
}


## The lost cat Charlotte is carrying ("" if none).
static func carrying() -> String:
	return str(GameState.flags.get("carrying", ""))


## The cat itself, as it looks when lost: its coat and its collar.
static func make(id: String) -> StrayCat:
	var info: Dictionary = ALL[id]
	var cat := StrayCat.new()
	cat.coat = StrayCat.COATS[info.coat]
	cat.size = 0.66
	cat.collar = Color(info.collar)
	cat.stay = true
	return cat


## The cat curled up in Charlotte's arms, in her body's units (the same size next to her indoors and out).
static func held(id: String) -> StrayCat:
	var cat := make(id)
	cat.size = 1.25 / StreetScene.CHAR_SCALE
	cat.held()
	return cat


## A "PERDU" sheet, centred on its position: the cat's face, its name, its collar and the owner's address.
class Poster:
	extends Node2D
	var id := "cat"

	func _draw() -> void:
		var info: Dictionary = ALL[id]
		var paper := Rect2(-24, -34, 48, 66)
		draw_set_transform(Vector2.ZERO, 0.03)
		draw_rect(Rect2(paper.position + Vector2(2, 2), paper.size), Color(0, 0, 0, 0.2))
		draw_rect(paper, Color("#FBF8F0"))
		draw_rect(paper, Color("#D6CFC0"), false, 1.0)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-24, -22), "PERDU", HORIZONTAL_ALIGNMENT_CENTER, 48, 11, Color("#D0303A"))
		var coat: Dictionary = StrayCat.COATS[info.coat]
		var fur := Color(coat.base)
		var c := Vector2(0, -4)
		for side in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([c + Vector2(side * 9, -4), c + Vector2(side * 8, -14), c + Vector2(side * 2, -8)]), fur)
		draw_circle(c, 9.0, fur)
		if coat.pattern == "calico":
			draw_circle(c + Vector2(-4, -4), 4.0, Color(StrayCat.CALICO[0]))
			draw_circle(c + Vector2(5, -5), 3.0, Color(StrayCat.CALICO[1]))
		elif coat.pattern == "tabby":
			for x in [-3.0, 0.0, 3.0]:
				draw_line(c + Vector2(x, -8), c + Vector2(x * 0.8, -5), Color(coat.dark), 1.0)
		draw_circle(c + Vector2(-3.5, -1), 1.4, Color("#2B2B33"))
		draw_circle(c + Vector2(3.5, -1), 1.4, Color("#2B2B33"))
		draw_arc(c + Vector2(0, 2), 8.5, 0.6, PI - 0.6, 10, Color(info.collar), 2.0)
		draw_string(font, Vector2(-24, 15), str(info.name).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 48, 7, Color("#2B2B33"))
		draw_string(font, Vector2(-24, 22), "collier " + str(info.collar_name), HORIZONTAL_ALIGNMENT_CENTER, 48, 6, Color("#55555E"))
		draw_string(font, Vector2(-24, 29), str(info.address).get_slice(",", 0), HORIZONTAL_ALIGNMENT_CENTER, 48, 6, Color("#55555E"))
		for x in [-24.0, 15.0]:
			draw_rect(Rect2(x, -37, 9, 6), Color(0.95, 0.92, 0.75, 0.75))
