extends StreetScene
# Rue Masson, the shopping street a block south of Dandurand, one scene per side of each block between two avenues (Julien),
# drawn from the Street View pictures (reference/streetview/INDEX.md, "Rue Masson 2000–3400"; facades `masson_*` in
# tools/generate_houses.gd). One script, a scene per `block` and `side`: the odd numbers are the NORTH side (seen from the
# south sidewalk, so the lower avenue is on the left), the even numbers the SOUTH side (seen from the north, the higher avenue
# on the left). Shop names are labels laid on their sign bands. The crosswalk over Masson at either corner leads to the other
# side of the same block (`_add_across`). A new block = one entry in BLOCKS, its facades in the generator, two .tscn files.

## Which block: the two avenues it lies between, e.g. "6e_7e".
@export var block := "6e_7e"
## "impair" (the north side) or "pair" (the south side).
@export var side := "impair"

## Each side of each block: its layout left to right (the corners across the avenues at both ends), its two avenues (the
## gap in the layout, the avenue's name, its width), its trees (shifted clear of the signs) and lamps, where the moon rises
## on Halloween night (a fraction across `layout`, over a low building), and the shop signs:
## {art: [[x on the facade, text, text colour, outline colour, font size], …]} (laid on the sign band, 302 above its foot).
const BLOCKS := {
	"6e_7e_impair": {
		"layout": ["masson_eglise_cote", "rue_6e", "masson_2901", "masson_2903", "masson_2909", "masson_2925", "masson_2933",
			"rue_7e", "masson_3001_cote"],
		"avenues": [["rue_6e", "6e Avenue", 560.0], ["rue_7e", "7e Avenue", 540.0]],
		"trees_after": [2, 5], "tree_shift": {2: -45.0, 5: 60.0}, "lamps_after": [2, 5], "hydrants_at": [2.1], "racks_at": [4.6], "squirrels_at": [3.5], "moon_at": 6.5,
		"signs": {
			"masson_2903": [[225.0, "FRAÎCHEMENT BON", "#FFFFFF", "#1E1E20", 13], [645.0, "VOTRE FRUITERIE DE QUARTIER", "#FFFFFF", "#1E1E20", 9]],
			"masson_2909": [[375.0, "POULET ROUGE", "#FFFFFF", "#C8202A", 15]],
			"masson_2925": [[165.0, "AQUARIUM", "#FFFFFF", "#1E3E5E", 11], [430.0, "N. MODE", "#FFFFFF", "#2B2B2E", 11],
				[710.0, "FRITES ALORS!", "#C8202A", "#E9E2D0", 12], [1065.0, "COYOTE · TACOS", "#E8812E", "#1E1E20", 12]],
		},
		"panels": {"masson_2933": [[1290.0, 430.0, "KINATEX", "#FFFFFF", "#1E1E20", 10]]},
	},
	"6e_7e_pair": {
		"layout": ["masson_3000_cote", "rue_7e", "masson_2970", "masson_2930", "masson_2908", "masson_2902", "rue_6e",
			"masson_2892_cote"],
		"avenues": [["rue_7e", "7e Avenue", 540.0], ["rue_6e", "6e Avenue", 560.0]],
		"trees_after": [2, 3, 4], "tree_shift": {2: -50.0, 3: 73.0}, "lamps_after": [2, 4], "hydrants_at": [3.6], "racks_at": [2.3], "squirrels_at": [3.2], "moon_at": 4.5,
		"signs": {
			"masson_2970": [[295.0, "Tim Hortons", "#C8202A", "#3A3A3C", 16]],
			"masson_2930": [[235.0, "COIFFURE · SPA URBAIN", "#FFFFFF", "#2B2B2E", 10], [590.0, "MÈDZ", "#FFFFFF", "#1E1E20", 12],
				[935.0, "LA PUCE · BIJOUTERIE", "#F2C230", "#141416", 11], [1535.0, "COMPTABLES", "#2B2B2E", "#E9E5DE", 10]],
			"masson_2908": [[465.0, "QUINCAILLERIE BÉLANGER", "#FFFFFF", "#3A3E42", 13], [1185.0, "RONA", "#FFFFFF", "#1F4E9A", 16]],
			"masson_2902": [[945.0, "fido", "#F2C230", "#2B2B2E", 13]],
		},
		"panels": {},
	},
}


func _init() -> void:
	_setup()


# The street's data from BLOCKS. Called again once the exports are set (a scene file sets them after _init).
func _setup() -> void:
	var data: Dictionary = BLOCKS["%s_%s" % [block, side]]
	street_key = "masson_%s_%s" % [block, side]
	layout.assign(data.layout)
	cross_streets = {}
	for a: Array in data.avenues:
		cross_streets[a[0]] = a[2]
	trees_after.assign(data.trees_after)
	tree_shift = data.tree_shift.duplicate()
	lamps_after.assign(data.lamps_after)
	hydrants_at.assign(data.hydrants_at)
	racks_at.assign(data.racks_at)
	squirrels_at.assign(data.squirrels_at)
	seed_value = absi(hash(street_key)) % 9000 + 1000
	# The shops are shut by the time the children go round: no candy on Masson, the evening is on her block.
	gives_candy = false


func _ready() -> void:
	_setup()
	super._ready()


func _data() -> Dictionary:
	return BLOCKS["%s_%s" % [block, side]]


## The scene of the other side of this block.
func _other_side() -> String:
	return "res://scenes/masson_%s_%s.tscn" % [block, "pair" if side == "impair" else "impair"]


# At the corner she crossed to, else in the middle of the block.
func _start_x() -> float:
	for a: Array in _data().avenues:
		var gap: String = a[0]
		if _arriving("%s_from_%s" % [street_key, gap]):
			var i := layout.find(gap)
			return _starts[i + 1] + 40.0 if i == 1 else _starts[i] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _street_x(layout.size() / 2.0)


# On Halloween night the moon rises over the block's lowest building (the bank, the hardware store): the others reach the top.
func _moon_x() -> float:
	return _street_x(_data().moon_at)


# The avenues run north from the odd side's view, south from the even side's; their far sides aren't drawn from photos yet.
func _build_cross_streets() -> void:
	var avenues: Array = _data().avenues
	for n in avenues.size():
		var a: Array = avenues[n]
		var cs := _cross_street(a[0], a[1], 1.0 if n == 0 else -1.0)
		cs.along_name = "Rue Masson"
		cs.facing = "north" if side == "impair" else "south"
		var brick := [Color("#A8473A"), Color("#9C5A44"), Color("#B5603F"), Color("#7E4436")]
		cs.left_walls = [
			{"to": 0.8, "top": 300.0, "kind": "plex", "color": brick[n]},
			{"to": 2.4, "top": 290.0, "kind": "plex", "color": brick[n + 1]},
			{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": brick[n + 2]},
		]
		cs.right_walls = [
			{"to": 0.8, "top": 290.0, "kind": "plex", "color": brick[n + 2]},
			{"to": 2.2, "top": 300.0, "kind": "plex", "color": brick[n]},
			{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": brick[n + 1]},
		]


# The shops' names on their sign bands, and the odd sign panel on a wall.
func _decorate_house(i: int, house: Sprite2D) -> void:
	var art: String = layout[i]
	var tex_h := _tex(art).get_height()
	for s: Array in _data().signs.get(art, []):
		var at := house.position + Vector2(float(s[0]), tex_h - 302.0) * HOUSE_SCALE
		_label(s[1], at, Vector2(220, 22), int(s[4]), Color(s[2]), Color(s[3]))
	for p: Array in _data().panels.get(art, []):
		var at := house.position + Vector2(float(p[0]), float(p[1])) * HOUSE_SCALE
		var board := ColorRect.new()
		board.color = Color(p[4])
		board.size = Vector2(54, 24)
		board.position = at - board.size / 2.0
		add_child(board)
		_label(p[2], at, Vector2(60, 20), int(p[5]), Color(p[3]), Color(p[4]))


# Over Masson at either corner, to the other side of this block.
func _build_doors() -> void:
	for n in _cross_streets.size():
		var gap: String = _data().avenues[n][0]
		_add_across(_cross_streets[n], _other_side(), "masson_%s_%s_from_%s" % [block, "pair" if side == "impair" else "impair", gap])
