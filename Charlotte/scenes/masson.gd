extends StreetScene
# Rue Masson, the shopping street a block south of Dandurand, from the 1re to the 9e Avenue, drawn from the Street View pictures
# (reference/streetview/INDEX.md, "Rue Masson 2000–3400"; facades `masson_*` in tools/generate_houses.gd). One scene per side of
# the street (Julien: so she isn't always crossing into another scene): `masson_impair.tscn`, the odd numbers, the NORTH side,
# seen from the south sidewalk with the 1re on the left; `masson_pair.tscn`, the even numbers, the SOUTH side, seen from the
# north with the 9e on the left. Each side is put together, block after block, from `BLOCKS` (one entry per side of each block,
# as it was drawn) in the order `ORDER` gives. The crosswalk over Masson at every avenue leads to the other side, at the same
# corner. The plate at the top names the block she is in (`room_name`). A new block = one entry per side in BLOCKS, its
# place in ORDER, its facades in the generator.

## "impair" (the north side) or "pair" (the south side).
@export var side := "impair"

## The blocks, left to right as each side is seen.
const ORDER := {
	"impair": ["1re_2e", "2e_3e", "3e_4e", "4e_5e", "5e_6e", "6e_7e", "7e_8e", "8e_9e"],
	"pair": ["8e_9e", "7e_8e", "6e_7e", "5e_6e", "4e_5e", "3e_4e", "2e_3e", "1re_2e"],
}

## How each avenue is written on the plate.
const AVENUE_NAMES := {"1re": "1re", "2e": "2e", "3e": "3e", "4e": "4e", "5e": "5e", "6e": "6e", "7e": "7e", "8e": "8e", "9e": "9e"}

## Each side of each block: its layout left to right (the corners across the avenues at both ends), its two avenues (the
## gap in the layout, the avenue's name, its width), its trees (shifted clear of the signs) and lamps, where the moon rises
## on Halloween night (a fraction across `layout`, over a low building), and the shop signs:
## {art: [[x on the facade, text, text colour, outline colour, font size], …]} (laid on the sign band, 302 above its foot),
## `logos` = real logos from art/brands/ on those bands: {art: [[x, file, height], …]}.
const BLOCKS := {
	"1re_2e_impair": {
		"layout": ["masson_2595_cote", "rue_1re", "masson_2605", "masson_2611", "masson_2615", "masson_2629",
			"masson_2631", "rue_2e", "masson_2653_cote"],
		"avenues": [["rue_1re", "1re Avenue", 540.0], ["rue_2e", "2e Avenue", 540.0]],
		"trees_after": [3, 5], "tree_shift": {3: 0.0, 5: 0.0}, "lamps_after": [2, 5], "hydrants_at": [4.5], "racks_at": [5.6],
		"squirrels_at": [5.5], "moon_at": 4.5,
		"signs": {
			"masson_2605": [[410.0, "Boni-soir", "#FFFFFF", "#C8202A", 17]],
			"masson_2611": [[380.0, "Domino's", "#0B6EAF", "#FFFFFF", 15]],
			"masson_2615": [[350.0, "Le Jardin de Mathilde", "#FFFFFF", "#1A1A1A", 12]],
			"masson_2629": [[335.0, "Les Cœurs de Jupons", "#F2E6C8", "#1A1A1A", 12]],
			"masson_2631": [[235.0, "YOGA D.N.A.", "#FFFFFF", "#6E5E7E", 13], [650.0, "Restaurant Phở", "#C8202A", "#F2F0EA", 13],
				[1065.0, "Jus", "#3E9A3E", "#F2F0EA", 14]],
		},
		"logos": {"masson_2611": [[230.0, "dominos_logo.svg", 26.0]]},
		"panels": {},
	},
	"1re_2e_pair": {
		"layout": ["masson_2644", "rue_2e", "masson_2636", "masson_2620", "masson_2606", "rue_1re", "masson_2600_cote"],
		"avenues": [["rue_2e", "2e Avenue", 540.0], ["rue_1re", "1re Avenue", 540.0]],
		"trees_after": [2, 3], "tree_shift": {2: 0.0, 3: 0.0}, "lamps_after": [2, 4], "hydrants_at": [3.5], "racks_at": [],
		"squirrels_at": [3.3], "moon_at": 4.5,
		"signs": {"masson_2636": [[865.0, "koodo", "#FFFFFF", "#D6157A", 15], [1260.0, "Rosemont", "#3A3A3C", "#E9E7E1", 12]],
			"masson_2606": [[880.0, "CASERNE 29", "#C8202A", "#CFC6B2", 13]]},
		"logos": {"masson_2636": [[515.0, "telus_logo.svg", 20.0]]},
		"panels": {},
	},
	"2e_3e_impair": {
		"layout": ["masson_2645_cote", "rue_2e", "masson_2653", "masson_2661", "masson_2675", "masson_2685",
			"rue_3e", "masson_2703_cote"],
		"avenues": [["rue_2e", "2e Avenue", 540.0], ["rue_3e", "3e Avenue", 540.0]],
		"trees_after": [2, 4], "tree_shift": {2: 0.0, 4: 0.0}, "lamps_after": [3, 5], "hydrants_at": [3.5], "racks_at": [4.3],
		"squirrels_at": [4.5], "moon_at": 2.5,
		"signs": {"masson_2653": [[295.0, "Paulines", "#FFFFFF", "#1E5E3A", 15]],
			"masson_2685": [[645.0, "SAQ", "#FFFFFF", "#B5121B", 17]]},
		"panels": {},
	},
	"2e_3e_pair": {
		"layout": ["masson_2702_cote", "rue_3e", "masson_2692", "masson_2682", "masson_2666", "masson_2650", "masson_2644",
			"rue_2e", "masson_2636_cote"],
		"avenues": [["rue_3e", "3e Avenue", 540.0], ["rue_2e", "2e Avenue", 540.0]],
		"trees_after": [3, 5], "tree_shift": {3: 0.0, 5: 0.0}, "lamps_after": [2, 5], "hydrants_at": [5.8], "racks_at": [2.5],
		"squirrels_at": [6.5], "moon_at": 6.5,
		"signs": {
			"masson_2692": [[550.0, "PLACE DOLLAR", "#1E7A3E", "#FFFFFF", 17]],
			"masson_2666": [[315.0, "monteiro", "#FFFFFF", "#1A1A1A", 14]],
			"masson_2644": [[355.0, "PISTA", "#2B2B2E", "#C9CCCF", 15]],
		},
		"texts": {"masson_2682": [[430.0, 112.0, "LES FLEURS POUSSENT ENCORE", "#F7F3EA", "#5E2A20", 17]]},
		"panels": {},
	},
	"3e_4e_impair": {
		"layout": ["masson_2697_cote", "rue_3e", "masson_2703", "masson_2711", "masson_2721", "masson_2731",
			"masson_2737", "rue_4e", "masson_2801_cote"],
		"avenues": [["rue_3e", "3e Avenue", 540.0], ["rue_4e", "4e Avenue", 540.0]],
		"trees_after": [3, 4], "tree_shift": {3: 0.0, 4: 0.0}, "lamps_after": [2, 5], "hydrants_at": [3.7], "racks_at": [3.3],
		"squirrels_at": [4.4], "moon_at": 4.5,
		"signs": {
			"masson_2731": [[420.0, "Boulangerie", "#3A2A1E", "#E8E0D0", 14]],
			"masson_2737": [[335.0, "SERVICE COMPTANT", "#FFD400", "#1F4E9A", 13]],
		},
		"panels": {},
	},
	"3e_4e_pair": {
		"layout": ["masson_2802_cote", "rue_4e", "masson_2742", "masson_2734", "masson_2716", "masson_2702", "rue_3e",
			"masson_2696_cote"],
		"avenues": [["rue_4e", "4e Avenue", 540.0], ["rue_3e", "3e Avenue", 540.0]],
		"trees_after": [2, 4], "tree_shift": {2: 0.0, 4: 0.0}, "lamps_after": [2, 4], "hydrants_at": [3.5], "racks_at": [4.3],
		"squirrels_at": [4.6], "moon_at": 4.5,
		"signs": {
			"masson_2716": [[650.0, "Jean Coutu", "#1F3E8E", "#FFD400", 17]],
		},
		"panels": {"masson_2716": [[470.0, 398.0, "PJC", "#FFFFFF", "#C8202A", 10]]},
		"texts": {"masson_2702": [[500.0, 70.0, "Yoga chaud | Pilates", "#FFFFFF", "#7A3026", 15]]},
	},
	"4e_5e_impair": {
		"layout": ["masson_2755_cote", "rue_4e", "masson_2801", "masson_2811", "masson_2819", "masson_2823",
			"masson_2829", "rue_5e", "masson_2851_cote"],
		"avenues": [["rue_4e", "4e Avenue", 540.0], ["rue_5e", "5e Avenue", 540.0]],
		"trees_after": [3, 5], "tree_shift": {3: 0.0, 5: -200.0}, "lamps_after": [2, 5], "hydrants_at": [5.5], "racks_at": [3.5],
		"squirrels_at": [5.8], "moon_at": 6.5,
		"signs": {
			"masson_2801": [[225.0, "CORVETTE", "#E8202A", "#1E1E20", 15], [645.0, "BANCO · ACHETONS OR", "#FFFFFF", "#9A141A", 12]],
			"masson_2811": [[380.0, "pattes & griffes", "#FFFFFF", "#3E9A3E", 14]],
			"masson_2819": [[430.0, "pizza pizza · 737-1111", "#FFFFFF", "#9A141A", 13]],
			"masson_2823": [[515.0, "Trou.  café · sandwichs", "#FFFFFF", "#1E2A4A", 14]],

		},
		"logos": {"masson_2829": [[170.0, "bmo_logo.svg", 24.0]]},
		"panels": {},
	},
	"4e_5e_pair": {
		"layout": ["masson_2846_cote", "rue_5e", "masson_2836", "masson_2818", "masson_2812", "masson_2802",
			"rue_4e", "masson_2790_cote"],
		"avenues": [["rue_5e", "5e Avenue", 540.0], ["rue_4e", "4e Avenue", 540.0]],
		"trees_after": [3, 4], "tree_shift": {3: 0.0, 4: 0.0}, "lamps_after": [2, 4], "hydrants_at": [3.6], "racks_at": [4.5],
		"squirrels_at": [3.8], "moon_at": 3.5,
		"signs": {
			"masson_2818": [[465.0, "Fruiterie au Melon Miel", "#FFFFFF", "#D8322A", 13]],
			"masson_2812": [[335.0, "CAFÉ · BOULANGERIE", "#FFFFFF", "#2B2B2E", 11]],
		},
		"logos": {"masson_2836": [[650.0, "dollarama_logo.svg", 30.0]]},
		"panels": {},
	},
	"5e_6e_impair": {
		"layout": ["masson_2833_cote", "rue_5e", "masson_presbytere", "masson_eglise", "rue_6e", "masson_2901_cote"],
		"avenues": [["rue_5e", "5e Avenue", 540.0], ["rue_6e", "6e Avenue", 560.0]],
		"trees_after": [2], "tree_shift": {2: 150.0}, "lamps_after": [1, 3], "hydrants_at": [2.9], "racks_at": [], "squirrels_at": [3.3],
		"moon_at": 3.85, "signs": {}, "panels": {},
	},
	"5e_6e_pair": {
		"layout": ["masson_2902_cote", "rue_6e", "masson_2888", "masson_2884", "masson_2870",
			"masson_2846", "rue_5e", "masson_2840_cote"],
		"avenues": [["rue_6e", "6e Avenue", 560.0], ["rue_5e", "5e Avenue", 540.0]],
		"trees_after": [3, 4], "tree_shift": {3: 20.0, 4: -110.0}, "lamps_after": [2, 4], "hydrants_at": [4.5], "racks_at": [2.4],
		"squirrels_at": [4.3], "moon_at": 2.5,
		"signs": {
			"masson_2888": [[600.0, "BANQUE NATIONALE", "#1E1E20", "#E9E5DE", 14]],
			"masson_2870": [[295.0, "L'OEUFRIER", "#FFFFFF", "#1E1E20", 13]],
			"masson_2846": [[225.0, "LE POKE STATION", "#FFFFFF", "#4A2E22", 11], [590.0, "FLEURISTE", "#F2E6C8", "#4A2E22", 11],
				[1005.0, "TABAGIE & VAPESHOP", "#FFFFFF", "#1E1E20", 11], [1460.0, "SIMASSON", "#FFFFFF", "#4A2E22", 12]],
		},
		"logos": {"masson_2888": [[300.0, "banque_nationale_symbol.svg", 22.0]]},
		"panels": {},
	},
	"7e_8e_impair": {
		"layout": ["masson_2933_cote", "rue_7e", "masson_3003", "masson_3021", "masson_3025", "masson_3039",
			"rue_8e", "masson_3071_cote"],
		"avenues": [["rue_7e", "7e Avenue", 540.0], ["rue_8e", "8e Avenue", 540.0]],
		"trees_after": [2, 4], "tree_shift": {2: 30.0, 4: 40.0}, "lamps_after": [2, 4], "hydrants_at": [3.6], "racks_at": [4.4],
		"squirrels_at": [3.4], "moon_at": 3.5,
		"signs": {
			"masson_3003": [[700.0, "P", "#FFFFFF", "#1A1A1A", 20], [1080.0, "BOULANGERIE", "#FFFFFF", "#1A1A1A", 13]],
		},
		"logos": {"masson_3003": [[330.0, "premiere_moisson_logo_white.svg", 11.0]]},
		"panels": {},
	},
	"7e_8e_pair": {
		"layout": ["masson_3070_cote", "rue_8e", "masson_3038", "masson_3034", "masson_3028", "masson_3008",
			"masson_3000", "rue_7e", "masson_2970_cote"],
		"avenues": [["rue_8e", "8e Avenue", 540.0], ["rue_7e", "7e Avenue", 540.0]],
		"trees_after": [3, 4], "tree_shift": {3: -150.0, 4: 0.0}, "lamps_after": [2, 5], "hydrants_at": [5.6], "racks_at": [3.3],
		"squirrels_at": [2.5], "moon_at": 5.5,
		"signs": {
			"masson_3034": [[255.0, "LUNETTERIE MILOT", "#FFFFFF", "#1E1E20", 12], [725.0, "RAPOSO", "#4FB04F", "#FFFFFF", 15]],
			"masson_3008": [[725.0, "TANDOORI MASSON", "#FFFFFF", "#C8202A", 13]],
			"masson_3000": [[480.0, "COUCHE-TARD", "#E41B12", "#FFFFFF", 16]],
		},
		"logos": {"masson_3000": [[250.0, "couche_tard_owl.svg", 26.0]]},
		"panels": {},
	},
	"8e_9e_impair": {
		"layout": ["masson_3053_cote", "rue_8e", "masson_3071", "masson_3103", "masson_3107", "masson_3115", "masson_3125",
			"masson_3127", "masson_3131", "masson_3139", "rue_9e", "masson_3151_cote"],
		"avenues": [["rue_8e", "8e Avenue", 540.0], ["rue_9e", "9e Avenue", 540.0]],
		"trees_after": [3, 5, 8], "tree_shift": {3: 0.0, 5: 0.0, 8: 0.0}, "lamps_after": [2, 7], "hydrants_at": [6.5],
		"racks_at": [4.5], "squirrels_at": [5.5], "moon_at": 2.3,
		"signs": {
			"masson_3103": [[380.0, "Méga Vrac", "#FFFFFF", "#1F4E9A", 15]],
			"masson_3115": [[400.0, "QUINCAILLERIE A. LALONDE", "#1E1E20", "#F2F0EA", 12]],
			"masson_3107": [[300.0, "PEINTURE SICO", "#FFFFFF", "#C8202A", 12]],
			"masson_3131": [[340.0, "PUB", "#E8C46A", "#1E1E20", 14]],
		},
		"panels": {},
	},
	"8e_9e_pair": {
		"layout": ["masson_3150_cote", "rue_9e", "masson_3132", "masson_3128", "masson_3126", "masson_3112", "masson_3108",
			"masson_3102", "masson_3086", "rue_8e", "masson_3038_cote"],
		"avenues": [["rue_9e", "9e Avenue", 540.0], ["rue_8e", "8e Avenue", 540.0]],
		"trees_after": [3, 6], "tree_shift": {3: 0.0, 6: 0.0}, "lamps_after": [2, 6], "hydrants_at": [5.5], "racks_at": [3.5],
		"squirrels_at": [7.5], "moon_at": 4.5,
		"signs": {
			"masson_3128": [[320.0, "BOSSA", "#FFFFFF", "#1A1A1A", 15]],
			"masson_3112": [[410.0, "Poke Monster", "#FFFFFF", "#C8202A", 15]],
		},
		"panels": {},
	},
	"6e_7e_impair": {
		"layout": ["masson_eglise_cote", "rue_6e", "masson_2903", "masson_2909", "masson_2925", "masson_2933",
			"rue_7e", "masson_3001_cote"],
		"avenues": [["rue_6e", "6e Avenue", 560.0], ["rue_7e", "7e Avenue", 540.0]],
		"trees_after": [2, 4], "tree_shift": {2: -45.0, 4: 60.0}, "lamps_after": [2, 4], "hydrants_at": [2.1], "racks_at": [3.6], "squirrels_at": [2.5], "moon_at": 5.5,
		"signs": {
			"masson_2903": [[225.0, "FRAÎCHEMENT BON", "#FFFFFF", "#123322", 13], [645.0, "VOTRE FRUITERIE DE QUARTIER", "#FFFFFF", "#123322", 9]],
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
			"masson_2930": [[235.0, "COIFFURE · SPA URBAIN", "#FFFFFF", "#2B2B2E", 10], [590.0, "MÈDZ", "#FFFFFF", "#1E1E20", 12],
				[935.0, "LA PUCE · BIJOUTERIE", "#F2C230", "#141416", 11], [1535.0, "COMPTABLES", "#2B2B2E", "#E9E5DE", 10]],
			"masson_2908": [[465.0, "QUINCAILLERIE BÉLANGER", "#FFFFFF", "#3A3E42", 13]],
		},
		"logos": {"masson_2970": [[295.0, "tim_hortons_logo.svg", 28.0]], "masson_2908": [[1185.0, "rona_logo_white.svg", 17.0]],
			"masson_2902": [[945.0, "fido_logo.svg", 18.0]]},
		"panels": {},
	},
}


## This side, put together from its blocks: layout, avenues (in order), trees, lamps…, signs, and where each block's buildings
## run in the layout (`blocks`: {block: Vector2i(first, last)}).
var _side_data := {}


func _init() -> void:
	_setup()


# The street's data, its blocks joined end to end. Called again once the export is set (a scene file sets it after _init).
func _setup() -> void:
	var m := {"layout": [], "avenues": [], "trees_after": [], "tree_shift": {}, "lamps_after": [], "hydrants_at": [],
		"racks_at": [], "squirrels_at": [], "signs": {}, "logos": {}, "texts": {}, "panels": {}, "blocks": {}}
	var order: Array = ORDER[side]
	for n in order.size():
		var d: Dictionary = BLOCKS["%s_%s" % [order[n], side]]
		var lay: Array = d.layout
		# The first block keeps the corner across its first avenue; the next ones start after the avenue they share with the
		# block before; the last one keeps the corner across its last avenue.
		var start := 0 if n == 0 else 2
		var stop: int = lay.size() if n == order.size() - 1 else lay.size() - 1
		var offset: int = m.layout.size() - start
		for i in range(start, stop):
			m.layout.append(lay[i])
		for av: Array in d.avenues:
			var known := false
			for had: Array in m.avenues:
				known = known or had[0] == av[0]
			if not known:
				m.avenues.append(av)
		for t: int in d.trees_after:
			if t >= start and t < stop:
				m.trees_after.append(t + offset)
				if d.tree_shift.has(t):
					m.tree_shift[t + offset] = d.tree_shift[t]
		for t: int in d.lamps_after:
			if t >= start and t < stop:
				m.lamps_after.append(t + offset)
		for key in ["hydrants_at", "racks_at", "squirrels_at"]:
			for at: float in d[key]:
				if at >= start and at < stop:
					m[key].append(at + offset)
		for key in ["signs", "logos", "texts", "panels"]:
			m[key].merge(d.get(key, {}))
		m.blocks[order[n]] = Vector2i(offset + 2, offset + lay.size() - 3)
	_side_data = m
	street_key = "masson_%s" % side
	layout.assign(m.layout)
	cross_streets = {}
	for a: Array in m.avenues:
		cross_streets[a[0]] = a[2]
	trees_after.assign(m.trees_after)
	tree_shift = m.tree_shift
	lamps_after.assign(m.lamps_after)
	hydrants_at.assign(m.hydrants_at)
	racks_at.assign(m.racks_at)
	squirrels_at.assign(m.squirrels_at)
	seed_value = absi(hash(street_key)) % 9000 + 1000
	# The shops are shut by the time the children go round: no candy on Masson, the evening is on her block.
	gives_candy = false


func _ready() -> void:
	_setup()
	super._ready()


func _data() -> Dictionary:
	return _side_data


## The scene of the other side of the street.
func _other_side() -> String:
	return "res://scenes/masson_%s.tscn" % ("pair" if side == "impair" else "impair")


## The block whose buildings start just past layout index `i` or end just before it (an avenue's gap at `i`), on side `after`.
func _block_beside(i: int, after: bool) -> String:
	for b: String in _side_data.blocks:
		var r: Vector2i = _side_data.blocks[b]
		if (after and r.x == i + 1) or (not after and r.y == i - 1):
			return b
	return ""


# At the corner she crossed to (on her block's side of the avenue), else by the 6e Avenue, the nearest to her own block.
func _start_x() -> float:
	for a: Array in _side_data.avenues:
		var gap: String = a[0]
		var i := layout.find(gap)
		for after: bool in [true, false]:
			var b := _block_beside(i, after)
			if b != "" and _arriving("%s_from_%s_%s" % [street_key, gap, b]):
				return _starts[i + 1] + 40.0 if after else _starts[i] - 40.0
	if not is_nan(Transition.street_x):
		var x := Transition.street_x
		Transition.street_x = NAN
		return x
	return _starts[layout.find("rue_6e") + 1] + 60.0


## The block she is in, for the plate at the top of the screen (PlaceLabel), and where she is on the map.
func room_name() -> String:
	var x := _charlotte.position.x if _charlotte else 0.0
	var gaps := []
	for a: Array in _side_data.avenues:
		gaps.append([_starts[layout.find(a[0])], a[0].trim_prefix("rue_")])
	var left := ""
	var right := ""
	for g: Array in gaps:
		if g[0] <= x:
			left = g[1]
		elif right == "":
			right = g[1]
	var pair := [left, right]
	pair = pair.filter(func(v): return v != "")
	if pair.size() < 2:
		return "Rue Masson, au coin de la %s" % (pair[0] if pair.size() else "6e")
	if side == "pair":
		pair.reverse()
	return "Rue Masson, entre la %s et la %s%s" % [pair[0], pair[1], " (côté sud)" if side == "pair" else ""]


# The avenues run north from the odd side's view, south from the even side's; their far sides aren't drawn from photos yet.
func _build_cross_streets() -> void:
	var avenues: Array = _side_data.avenues
	var brick := [Color("#A8473A"), Color("#9C5A44"), Color("#B5603F"), Color("#7E4436")]
	for n in avenues.size():
		var a: Array = avenues[n]
		var cs := _cross_street(a[0], a[1], -1.0 if n == avenues.size() - 1 else 1.0)
		cs.along_name = "Rue Masson"
		cs.facing = "north" if side == "impair" else "south"
		cs.left_walls = [
			{"to": 0.8, "top": 300.0, "kind": "plex", "color": brick[n % 4]},
			{"to": 2.4, "top": 290.0, "kind": "plex", "color": brick[(n + 1) % 4]},
			{"to": CrossStreet.FAR, "top": 300.0, "kind": "plex", "color": brick[(n + 2) % 4]},
		]
		cs.right_walls = [
			{"to": 0.8, "top": 290.0, "kind": "plex", "color": brick[(n + 2) % 4]},
			{"to": 2.2, "top": 300.0, "kind": "plex", "color": brick[n % 4]},
			{"to": CrossStreet.FAR, "top": 290.0, "kind": "plex", "color": brick[(n + 1) % 4]},
		]


# The shops' names on their sign bands, and the odd sign panel on a wall.
func _decorate_house(i: int, house: Sprite2D) -> void:
	var art: String = layout[i]
	var tex_h := _tex(art).get_height()
	for s: Array in _side_data.signs.get(art, []):
		var at := house.position + Vector2(float(s[0]), tex_h - 302.0) * HOUSE_SCALE
		_label(s[1], at, Vector2(220, 22), int(s[4]), Color(s[2]), Color(s[3]))
	# Real logos (art/brands/, SOURCES.md): [x on the facade, file, height in the world], centred on the sign band.
	for l: Array in _side_data.logos.get(art, []):
		var tex: Texture2D = load("res://art/brands/%s" % l[1])
		var logo := Sprite2D.new()
		logo.texture = tex
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		logo.scale = Vector2.ONE * float(l[2]) / tex.get_height()
		# A fourth value is the logo's own height on the facade, for one not on a shop's sign band.
		logo.position = house.position + Vector2(float(l[0]), float(l[3]) if l.size() > 3 else tex_h - 302.0) * HOUSE_SCALE
		add_child(logo)
	# Words painted straight on a wall: [x, y on the facade, text, colour, outline, size].
	for t: Array in _side_data.texts.get(art, []):
		_label(t[2], house.position + Vector2(float(t[0]), float(t[1])) * HOUSE_SCALE, Vector2(360, 22), int(t[5]), Color(t[3]), Color(t[4]))
	for p: Array in _side_data.panels.get(art, []):
		var at := house.position + Vector2(float(p[0]), float(p[1])) * HOUSE_SCALE
		var board := ColorRect.new()
		board.color = Color(p[4])
		board.size = Vector2(54, 24)
		board.position = at - board.size / 2.0
		add_child(board)
		_label(p[2], at, Vector2(60, 20), int(p[5]), Color(p[3]), Color(p[4]))


# Over Masson at every avenue, to the other side of the street at the same corner: the crosswalk is painted on the corner of
# the block to the right of the avenue, and leads from that stretch of sidewalk to the same block across the street.
func _build_doors() -> void:
	var other := "pair" if side == "impair" else "impair"
	for cs in _cross_streets:
		var i := _starts.find(cs.x0)
		var gap: String = layout[i]
		var b := _block_beside(i, true)
		var right := true
		if b == "":
			b = _block_beside(i, false)
			right = false
		if b != "":
			_masson_crossing(cs, right, "masson_%s_from_%s_%s" % [other, gap, b])
		# From the north side, 6e Avenue runs up toward Dandurand: turn into it on either side of the avenue, the church's
		# side (sixieme_sud) from the corner left of it, the other side (sixieme_sud_est) from the corner right of it.
		if side == "impair" and gap == "rue_6e":
			_add_corner(cs, "res://scenes/sixieme_sud.tscn", "6e_sud_from_masson", false, -1)
			_add_corner(cs, "res://scenes/sixieme_sud_est.tscn", "6e_sud_est_from_masson", false, 1)


## The crosswalk over Masson at one corner of an avenue (`right`: the corner right of it), from that stretch of sidewalk.
func _masson_crossing(cs: CrossStreet, right: bool, arrive: String) -> void:
	var home := _segment_at(cs.x1 + 1.0) if right else _segment_at(cs.x0 - 1.0)
	var curb := home.x if right else home.y
	var ground: CrossStreet = _grounds.get(cs)
	if ground == null:
		return
	ground.own_crosswalk = 1.0 if right else -1.0
	ground.queue_redraw()
	var over := DoorSpot.make(ground.own_crosswalk_rect(), func():
		if DebugMenu.blocked(GameState.age < CROSS_AGE):
			Bubble.say(self, _charlotte.position + Vector2(0, -190), CANT_CROSS, 2.6)
			return
		_control.enabled = false
		_control.hands_off = true
		_charlotte.is_walking = false
		Bubble.say(self, _charlotte.position + Vector2(0, -190), "Je regarde des deux côtés !", 1.4)
		var toward := -1 if right else 1
		var look := create_tween()
		for s: int in [toward, -toward, toward]:
			look.tween_callback(func(): _charlotte.facing = s)
			look.tween_interval(0.45)
		look.tween_callback(func():
			Transition.arrive = arrive
			Transition.crossing = ""
			Transition.change_scene(self, _other_side())), curb)
	over.click_only = true
	over.condition = func(): return _segment_at(_charlotte.position.x) == home
	add_child(over)
