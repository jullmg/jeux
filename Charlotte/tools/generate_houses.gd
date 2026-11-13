extends SceneTree
# Regenerates art/decor/*.svg: Godot --headless --path . --script res://tools/generate_houses.gd
# Autumn (Halloween) facades go in art/decor/, the other seasons in art/decor/<season>/ (see Season.decor).
# Every season makes the same random draws in the same order, so only the seasonal decor differs.
# Also writes art/decor/windows.json: each house's window panes, used by the game to put cats in windows, and
# art/decor/doors.json: each plex's front door centre x (SVG units), where its owner comes out.

const X0 := 30.0
const FLOOR_H := 275.0
const PORCH_FLOOR := 600.0
const BASE := 614.0
const GROUND := 700.0
const RAIL_H := 48.0
const VARIANTS := 36
## How many doors have a wreath in winter.
const WREATH_PERCENT := 17

const DEFAULTS := {
	"kind": "plex", "floors": 2, "width": 700.0,
	"mortar": "#D9CFC2",
	"trim": "#F4F1EA", "trim_dark": "#B9B2A5",
	"lintel": "#BDB5A6", "lintel_dark": "#8F887B", "lintel_style": "plain", "keystone": false,
	"door": "#B5652B", "door_dark": "#7A4019",
	"metal": "#1F1F1F", "metal_light": false,
	"slab": "#F1EEE8", "slab_dark": "#C9C3B8",
	"tread": "#454545", "tread_dark": "#262626",
	"step": "#A8A196", "step_dark": "#7E786E",
	"cornice": "#6E7377", "cornice_dark": "#4A4E52",
	"awning": "", "fence": "", "columns": false,
	"lower_stone": false, "stones": ["#B9AE9E", "#C7BCAC", "#A99F90", "#BFB6A8"], "stone_mortar": "#8E867A",
	"flower_boxes": false, "curtains": false, "downspout": -1.0, "basement": [480.0],
	"top": 0.0, "parapet": "cornice", "pediment": false, "crest": false, "number": "",
	"windows": [], "ground_window": [], "door_cx": 278.0, "balcony": [130.0, 420.0], "porch": [150.0, 400.0], "stair": [],
	"shop_sign": "#2E5E3E", "bins": false, "halloween": true,
}

const AUTUMN_BUSHES := ["#B5442E", "#D9682B", "#E3A33A", "#7E8F3A", "#9C3B2A", "#5F7F3A"]
const MUMS := ["#F2B632", "#E0782E", "#8E2A3A", "#F4E3B0"]

const GLYPHS := {
	"0": [[0, 0, 1, 0, 1, 1, 0, 1, 0, 0]],
	"1": [[0.2, 0.2, 0.5, 0, 0.5, 1]],
	"2": [[0, 0, 1, 0, 1, 0.5, 0, 0.5, 0, 1, 1, 1]],
	"3": [[0, 0, 1, 0, 1, 1, 0, 1], [0, 0.5, 1, 0.5]],
	"4": [[0, 0, 0, 0.5, 1, 0.5], [1, 0, 1, 1]],
	"5": [[1, 0, 0, 0, 0, 0.5, 1, 0.5, 1, 1, 0, 1]],
	"6": [[1, 0, 0, 0, 0, 1, 1, 1, 1, 0.5, 0, 0.5]],
	"7": [[0, 0, 1, 0, 1, 1]],
	"8": [[0, 0, 1, 0, 1, 1, 0, 1, 0, 0], [0, 0.5, 1, 0.5]],
	"9": [[1, 0.5, 0, 0.5, 0, 0, 1, 0, 1, 1, 0, 1]],
}

const BRICK_PALETTES := [
	["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"],
	["#7E4436", "#8A4A3A", "#6E3A2E", "#94543F", "#743F33"],
	["#D9B88F", "#CFAE84", "#E2C39C", "#C4A079", "#DDBE96"],
	["#B5603F", "#A85536", "#C26B48", "#9C4D31", "#C77650"],
	["#7A4A3A", "#6E4234", "#865243", "#5F392D", "#8E5A48"],
	["#C8A27A", "#BC966E", "#D4AE86", "#B08A62", "#CCA680"],
]
const MORTARS := ["#CDBFB0", "#BFB2A3", "#EFE6D8", "#D6C9B9", "#C2B6A8", "#E6DCCB"]
const DOORS := [
	["#B5652B", "#7A4019"], ["#3E6B48", "#244330"], ["#2F5D8A", "#1C3C5E"],
	["#2B2B2E", "#111111"], ["#8E2F3A", "#5E1C25"], ["#F4F1EA", "#B9B2A5"],
]
# Stair shapes leaving the floor-1 balcony towards the right, relative to their start x.
const STAIR_SHAPES := [
	[Vector2(0, 336), Vector2(148, 380), Vector2(238, 520), Vector2(168, 696)],
	[Vector2(0, 336), Vector2(62, 456), Vector2(123, 576), Vector2(185, 696)],
	[Vector2(0, 336), Vector2(75, 380), Vector2(130, 520), Vector2(115, 696)],
]

# Front doors seen along the avenues of Rosemont (reference/rue/portes.jpg): raised panels, an oval of leaded glass,
# stained glass, stacked diamonds, a 1950s flat door with three little windows, a narrow glass slit, vertical planks
# with a peephole window, slanted glass slats, a half-moon fanlight, small-paned glass, an art-deco sunburst, a round
# porthole, a wrought-iron grille over the glass, horizontal panels, tall arched panels, glazed and stained-glass
# double doors; some with stained-glass sidelights.
const DOOR_STYLES := ["double", "panel", "oval", "leaded", "diamond", "slots", "slit", "planks", "slats", "fan_top", "grid",
	"sunburst", "porthole", "grille", "horizontal", "arched_panels", "double_leaded"]

const HOUSES := [
	{
		"name": "duplex_voisin_gauche",
		"bricks": ["#7E4436", "#8A4A3A", "#6E3A2E", "#94543F", "#743F33"], "mortar": "#BFB2A3",
		"trim": "#5B4A3E", "trim_dark": "#3E3128", "lintel": "#D8CDB5", "lintel_dark": "#A89C84",
		"door": "#2B2B2E", "door_dark": "#111111", "awning": "#B08A5A",
		"windows": [[120.0, 110.0], [520.0, 110.0]], "door_cx": 362.0,
		"balcony": [255.0, 470.0], "porch": [270.0, 455.0],
		"stair": [Vector2(228, 336), Vector2(170, 456), Vector2(115, 576), Vector2(60, 696)],
		"fence": "black", "downspout": 655.0, "basement": [520.0], "curtains": true,
	},
	{
		"name": "duplex_charlotte",
		# From reference/maison_charlotte/: red-brown brick mixed with dark headers, grey mortar; double-hung windows, black frames,
		# one meeting rail, glass like the other houses'; stone lintels and thick sills; varnished wood doors with smoky glass and a dark transom;
		# small blue number plates under little lanterns; a thick white balcony slab on twin iron posts with scrolls, under a
		# dark metal awning; thin widely spaced iron railings with a scroll over each door; a straight stair, pale treads on a
		# black beam; the porch's steps at the LEFT; a black mailbox; a low fence of widely spaced thin bars. No decorations.
		"bricks": ["#7F3A2D", "#8A4132", "#6E3328", "#94483A", "#3F2C27", "#783527", "#54352C"], "mortar": "#A89C90",
		"lintel": "#C9C3B6", "lintel_dark": "#8F897D", "lintel_style": "fleur", "window_style": "hung",
		"top": 40.0, "parapet": "flat", "crest": true, "number": "5672", "number_up": "5674",
		"door": "#9A5A26", "door_dark": "#553114", "door_style": "wood_glass",
		"awning": "#3F4347", "awning_posts": [313.0, 397.0], "iron_posts": [208.0, 400.0], "columns": false,
		"downspout": 50.0, "downspout2": 64.0, "halloween": false,
		"windows": [[165.0, 80.0], [478.0, 85.0]], "door_cx": 348.0,
		"balcony": [205.0, 460.0], "porch": [205.0, 460.0], "slab_h": 32.0, "iron_rail": true,
		"rail_up": [216.0, 429.0], "rail_down": [205.0, 448.0],
		"stair": [Vector2(448, 336), Vector2(510, 456), Vector2(570, 576), Vector2(628, 696)],
		"tread": "#D8D3C8", "tread_dark": "#8A857A", "stair_beam": true,
		"steps_side": "left", "mailbox": true,
		"fence": "black", "fence_style": "wide", "bare_garden": true, "basement": [120.0, 455.0],
	},
	{
		"name": "duplex_voisin_droite",
		"bricks": ["#A0452F", "#B04E36", "#8F3D2B", "#B9583D", "#963F2E"], "mortar": "#D6C9B9",
		"lower_stone": true,
		"trim": "#F7F5F0", "trim_dark": "#C9C4BA", "lintel": "#C9C0B0",
		"door": "#F4F1EA", "door_dark": "#B9B2A5",
		"metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88",
		"cornice": "#E9E6DF", "cornice_dark": "#B5B0A6",
		"windows": [[90.0, 140.0], [535.0, 105.0]], "door_cx": 335.0,
		"balcony": [250.0, 500.0], "porch": [250.0, 420.0],
		"stair": [Vector2(525, 336), Vector2(600, 380), Vector2(655, 520), Vector2(640, 696)],
		"fence": "white", "basement": [110.0], "curtains": true,
	},
	{
		# The twins Turcotte's house, 5716 6e Avenue (reference/maison_jumelles/): warm brown brick with dark mortar, black-framed
		# windows under brick arches, a glass door under a white concrete balcony with a curved wrought-iron railing, an open-tread
		# black stair curving down to the right, a low black fence; Halloween decorations as on the photos.
		"name": "duplex_jumelles", "number": "5716",
		"bricks": ["#9A4E36", "#A85A3E", "#8A4430", "#B0603F", "#94503A"], "mortar": "#8C7C6E",
		"trim": "#26201C", "trim_dark": "#0F0C0A",
		"lintel": "#B9704F", "lintel_dark": "#7A4430", "lintel_style": "arch",
		"door": "#2A2622", "door_dark": "#100D0B", "door_style": "glass", "door_surround": "lintel",
		"parapet": "flat", "downspout": 652.0,
		"windows": [[150.0, 80.0], [485.0, 85.0]], "door_cx": 345.0,
		"balcony": [225.0, 530.0], "porch": [225.0, 535.0],
		"stair": [Vector2(530, 336), Vector2(618, 380), Vector2(672, 520), Vector2(628, 696)],
		"fence": "black", "basement": [],
	},
	{
		"name": "triplex_exemple_2", "floors": 3,
		"bricks": ["#D9B88F", "#CFAE84", "#E2C39C", "#C4A079", "#DDBE96"], "mortar": "#EFE6D8",
		"lintel": "#E4D6BE", "lintel_dark": "#B3A48A", "lintel_style": "arch", "keystone": true,
		"cornice": "#E2D8C6", "cornice_dark": "#ADA28E", "pediment": true,
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "columns": true, "curtains": true,
		"windows": [[70.0, 105.0], [525.0, 105.0]], "door_cx": 350.0,
		"balcony": [200.0, 500.0], "porch": [230.0, 470.0],
		"stair": [Vector2(232, 336), Vector2(90, 380), Vector2(5, 520), Vector2(75, 696)],
		"fence": "black", "basement": [],
	},
	{
		"name": "triplex_exemple_3", "floors": 3,
		"bricks": ["#C8A27A", "#BC966E", "#D4AE86", "#B08A62", "#CCA680"], "mortar": "#E6DCCB",
		"lintel": "#C8A27A", "lintel_dark": "#9C7A56", "parapet": "flat",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "flower_boxes": true, "curtains": true,
		"tread": "#8A5A3A", "tread_dark": "#5E3B24",
		"windows": [[95.0, 105.0], [505.0, 105.0]], "door_cx": 340.0,
		"balcony": [150.0, 640.0], "porch": [260.0, 420.0],
		"stair": [Vector2(205, 336), Vector2(150, 456), Vector2(100, 576), Vector2(50, 696)],
		"basement": [],
	},
	{
		"name": "moderne", "kind": "modern",
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"lintel": "#C46A55", "lintel_dark": "#7E3A2E", "lintel_style": "arch",
		"step": "#B08F6A", "step_dark": "#7E6446", "metal": "#6B5442",
		"windows": [[150.0, 100.0], [470.0, 80.0]], "ground_window": [500.0, 100.0], "door_cx": 330.0,
		"basement": [500.0], "bins": true, "curtains": true,
	},
	{
		# Dépanneur Xin-Xin fronts Dandurand: from 6e Avenue we see its side
		# (reference/coin_dandurand/coin_dépanneur_sur_6eme_coin_dandurand.jpg).
		"name": "depanneur", "kind": "depanneur_side", "width": 640.0, "halloween": false,
		"bricks": ["#6E3A2E", "#7A4234", "#5E3029", "#844A3A", "#4E2A28", "#8C5440"], "mortar": "#B9AEA2",
		"cornice": "#3F4448", "cornice_dark": "#2A2E31", "basement": [], "metal": "#1F1F1F",
	},
	{
		# Between the dépanneur and the green lane (reference/coin_dandurand/entre_entrée_ruelle_et_coin_dandurand.jpg).
		"name": "garages", "kind": "garages", "width": 780.0, "halloween": false,
		"bricks": ["#6B3A2E", "#7A4636", "#5A3028", "#86503E", "#4A2A26", "#93604A"], "mortar": "#B5AA9E",
		"trim": "#F2F0EA", "trim_dark": "#A9A398", "basement": [], "metal": "#1F1F1F",
	},
	# The corner of 6e and Holt seen from 6e (reference/coin_holt/6eme_coin_holt.png, entree_ruelle_6eme_coin_holt.png): a long
	# brown-brick three-storey with stepped white stone lintels, a beige corrugated-metal annex with a grey shingle
	# awning on the left, and the red corner window of dépanneur Oh Bon! on the right.
	{
		"name": "coin_holt", "kind": "corner_holt", "width": 1000.0, "floors": 3, "halloween": false,
		"bricks": ["#7E4234", "#8A4A3A", "#74392D", "#93503E", "#6E3A2E", "#85463A"], "mortar": "#A8988A",
		"lintel": "#EDE8DC", "lintel_dark": "#B5AE9F", "lintel_style": "none", "basement": [],
	},
	# Dépanneur Oh Bon! on Rue Holt at the 6e corner (reference/coin_holt/holt_coin_6eme.png): red storefront, a red and white
	# checkerboard, its sign; iron galleries above, white-railed stairs up to the first one.
	{
		"name": "ohbon", "kind": "ohbon", "width": 760.0, "floors": 3, "halloween": false,
		"bricks": ["#8A4A3A", "#7E4234", "#94523F", "#74392D", "#9A5A44"], "mortar": "#B0A090",
		"lintel": "#D8CFC0", "lintel_dark": "#A39A8A", "lintel_style": "plain", "basement": [],
		"door": "#7A2E2E", "door_dark": "#4E1C1C",
	},
	{"name": "ruelle", "kind": "ruelle", "width": 560.0},
	# The green lane near the Dandurand corner (reference/ruelle/Entrée_ruelle_coin_dandurand.jpg).
	{"name": "ruelle_verte", "kind": "ruelle_verte", "width": 640.0},
	# Dépanneur Xin-Xin's real front, on Rue Dandurand (reference/coin_dandurand/dépanneur_on_dandurand.jpg).
	{
		"name": "depanneur_front", "kind": "depanneur_front", "width": 780.0, "halloween": true,
		"bricks": ["#6E3A2E", "#7A4234", "#5E3029", "#844A3A", "#4E2A28", "#8C5440"], "mortar": "#B9AEA2",
		"trim": "#F2F0EA", "trim_dark": "#A9A398", "basement": [], "metal": "#1F1F1F",
	},
	# Across 6e Avenue on Rue Dandurand: a corner building's side.
	{
		"name": "dandurand_nord", "kind": "side_wall", "width": 600.0, "floors": 3,
		"bricks": ["#C2A07A", "#B8956E", "#CDAA84", "#AE8C66", "#D4B48E"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[90.0, 90.0], [300.0, 90.0]], "basement": [], "downspout": 540.0,
	},
	# Across Rue Holt: the side wall of the next block's corner building.
	{
		"name": "coin_holt_est", "kind": "side_wall", "width": 620.0, "floors": 3,
		"bricks": ["#9C6B4E", "#8E6146", "#A87656", "#82573E", "#B07E5E"], "mortar": "#D2C6B6",
		"parapet": "flat", "windows": [[110.0, 90.0], [330.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# Round the block (6e, Dandurand, 5e, Holt): corner buildings' side walls, on the block and across the streets.
	# Across 6e Avenue on Rue Holt.
	{
		"name": "holt_nord", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[90.0, 90.0], [300.0, 90.0]], "basement": [], "downspout": 500.0,
	},
	# Across 5e Avenue on Rue Holt.
	{
		"name": "holt_sud", "kind": "side_wall", "width": 600.0,
		"bricks": ["#C8A27A", "#BC966E", "#D4AE86", "#B08A62", "#CCA680"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[120.0, 90.0], [330.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# Across Rue Holt on 5e Avenue.
	{
		"name": "cinq_holt_ouest", "kind": "side_wall", "width": 580.0, "floors": 3,
		"bricks": ["#7E4436", "#8A4A3A", "#6E3A2E", "#94543F", "#743F33"], "mortar": "#BFB2A3",
		"parapet": "flat", "windows": [[90.0, 90.0], [300.0, 90.0]], "basement": [], "downspout": 520.0,
	},
	# Charlotte's block from 5e Avenue: the side of the corner building at Holt, and at Dandurand.
	{
		"name": "coin_5e_holt", "kind": "side_wall", "width": 480.0,
		"bricks": ["#B5603F", "#A85536", "#C26B48", "#9C4D31", "#C77650"], "mortar": "#D6C9B9",
		"parapet": "flat", "windows": [[90.0, 90.0], [280.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	{
		"name": "coin_5e_dandurand", "kind": "side_wall", "width": 500.0,
		"bricks": ["#9C6B4E", "#8E6146", "#A87656", "#82573E", "#B07E5E"], "mortar": "#D2C6B6",
		"parapet": "flat", "windows": [[100.0, 90.0], [290.0, 90.0]], "basement": [], "downspout": 440.0,
	},
	# Across 5e Avenue on Rue Dandurand.
	{
		"name": "dandurand_sud", "kind": "side_wall", "width": 580.0, "floors": 3,
		"bricks": ["#7A4A3A", "#6E4234", "#865243", "#5F392D", "#8E5A48"], "mortar": "#C2B6A8",
		"parapet": "flat", "windows": [[110.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# Across Rue Dandurand: école Saint-Jean-de-Brébeuf, seen from 6e Avenue (its side).
	{
		"name": "ecole", "kind": "school", "width": 1400.0, "floors": 3, "top": 104.0,
		"bricks": ["#A9472F", "#9C4029", "#B44F35", "#943B26", "#B85A3E"], "mortar": "#C9B7A4",
		"trim": "#ECE8E0", "trim_dark": "#A9A398", "lintel": "#D8CFC0", "lintel_dark": "#A39A8A",
		"basement": [120.0, 420.0, 720.0], "fence": "black", "halloween": false,
	},
	# ── Across 6e Avenue, the odd numbers, Holt (left) to Dandurand (right) ──
	# From reference/streetview/6e-avenue/ (INDEX.md "6e Avenue 5600–5800 (impairs)"): each entry names its pictures. Seasonal
	# decorations, parked cars, bikes, bins, the plywood boarding up 5685's balcony and the children's mural on 5713's side wall
	# are left out on purpose (docs/drawing-from-streetview.md).
	# Across Rue Holt from the corner: the next block's corner building, its side.
	{
		"name": "impair_holt_nord", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#8E4A3A", "#9A5444", "#7E4234", "#A45C4A", "#86463A"], "mortar": "#C8BBAA",
		"parapet": "flat", "windows": [[100.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 500.0,
	},
	# 5721–5733, the corner (5721…, 5725…, 5729…, 5733… and close-ups).
	{
		"name": "impair_coin_holt", "kind": "corner_yard", "width": 1100.0, "door_x": 500.0,
		"bricks": ["#A8473A", "#B4513F", "#9A3F33", "#B85C48", "#8E3A2F"], "mortar": "#CFC2B4",
		"lintel": "#D9D4C8", "lintel_dark": "#A39D93", "frame": "#2B2B2E", "slab": "#E9E6DF", "slab_dark": "#B9B5AC",
		"door": "#2B2B2E", "door_dark": "#111111", "basement": [],
	},
	# The lane near Holt (5713…, 5717…).
	{"name": "ruelle_impair_holt", "kind": "lane_odd", "width": 640.0, "lane_style": "holt"},
	# 5713, beige brick duplex, the white stair up its lane side, French doors, a white canopy (5713…, 5717… and close-ups).
	{
		"name": "impair_5713",
		"bricks": ["#D9CBB0", "#CFC0A3", "#E2D5BC", "#C7B697", "#DCCFB5"], "mortar": "#EDE6D8",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E8E0D0", "lintel_dark": "#B9AE98",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "double", "door_surround": "lintel",
		"metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "canopy": "#F2F0EA",
		"parapet": "flat", "windows": [[440.0, 150.0]], "door_cx": 300.0, "balcony": [110.0, 640.0], "porch": [190.0, 410.0],
		"stair": [Vector2(180, 336), Vector2(133, 456), Vector2(87, 576), Vector2(40, 696)],
		"fence": "", "halloween": false, "basement": [450.0],
	},
	# 5707, red brick duplex, a black stair curling down to the left, a white canopy (5707…, 5709… and close-ups).
	{
		"name": "impair_5707",
		"bricks": ["#9E4A36", "#A85440", "#8E4030", "#B25C46", "#94462F"], "mortar": "#CFC2B4",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "canopy": "#F2F0EA", "parapet": "flat",
		"windows": [[80.0, 140.0], [500.0, 140.0]], "door_cx": 340.0, "balcony": [180.0, 470.0], "porch": [250.0, 430.0],
		"stair": [Vector2(190, 336), Vector2(60, 380), Vector2(10, 520), Vector2(90, 696)],
		"fence": "black", "basement": [520.0],
	},
	# 5699, a duplex: red brick upstairs over a ground floor of grey brick, a canvas awning over its door (5699…, 5703… and close-ups).
	{
		"name": "impair_5699",
		"bricks": ["#9A3F33", "#A8473A", "#8E3A2F", "#B4513F", "#94402F"], "mortar": "#CDBFB0",
		"lower_stone": true, "stones": ["#B8B2A6", "#C4BEB2", "#A8A296", "#BEB8AC"], "stone_mortar": "#8E887E",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D2C6", "lintel_dark": "#A39D93",
		"door": "#3A3A3C", "door_dark": "#1A1A1C", "door_style": "grid", "door_awning": "#8E9AA6", "canopy": "#F2F0EA",
		"parapet": "flat", "windows": [[400.0, 130.0], [550.0, 100.0]], "door_cx": 210.0, "balcony": [90.0, 330.0], "porch": [130.0, 290.0],
		"stair": [Vector2(320, 336), Vector2(380, 420), Vector2(370, 560), Vector2(330, 696)],
		"fence": "black", "basement": [],
	},
	# 5689, the newer two-storey one: red brick, a band of white bricks, a white upper floor (5689…, 5691…, 5699… and close-ups).
	{
		"name": "impair_5689", "kind": "modern", "width": 640.0, "door_x": 220.0,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"lintel": "#D8D2C6", "lintel_dark": "#A39D93", "step": "#B08F6A", "step_dark": "#7E6446", "metal": "#6B5442",
		"windows": [[150.0, 100.0], [400.0, 110.0]], "ground_window": [400.0, 110.0], "door_cx": 220.0, "basement": [],
	},
	# 5685, painted white, a balcony on the first floor only, no outdoor stair (5679…, 5685…, 5691… and close-ups).
	{
		"name": "impair_5685",
		"bricks": ["#ECEAE4", "#E4E1DA", "#F2F0EB", "#DEDAD2", "#E8E5DF"], "mortar": "#CFCAC0",
		"trim": "#4A3E34", "trim_dark": "#2E261F", "lintel": "#E6E3DC", "lintel_dark": "#B9B5AC", "lintel_style": "none",
		"door": "#3A332C", "door_dark": "#1E1A16", "door_style": "slit", "parapet": "flat",
		"windows": [[90.0, 120.0], [440.0, 130.0]], "door_cx": 260.0, "balcony": [140.0, 380.0], "porch": [190.0, 330.0],
		"door_floors": [0, 1], "balcony_floors": [1], "stair": [], "fence": "", "basement": [], "halloween": false,
	},
	# 5679, tan brick, its balconies on the right under a dark metal canopy (5677…, 5679… and close-ups).
	{
		"name": "impair_5679",
		"bricks": ["#B08A62", "#A47E58", "#BC966E", "#9A7650", "#C29C74"], "mortar": "#D8CDBE",
		"trim": "#3A3A3C", "trim_dark": "#1E1E20", "lintel": "#C9BBA6", "lintel_dark": "#9A8C76",
		"door": "#2B2B2E", "door_dark": "#111111", "door_style": "slit", "canopy": "#3A3A3C", "parapet": "flat",
		"windows": [[80.0, 140.0], [530.0, 110.0]], "door_cx": 360.0, "balcony": [250.0, 480.0], "porch": [280.0, 440.0], "muntins": "x",
		"stair": [], "fence": "black", "basement": [70.0],
	},
	# 5677, red-brown brick, a white door between its two windows, the stair curling down to the right (5677… and close-ups).
	{
		"name": "impair_5677",
		"bricks": ["#8E5640", "#9A6048", "#7E4A36", "#A46A50", "#86503C"], "mortar": "#CFC2B0",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D9D2C4", "lintel_dark": "#A39A8A",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "double", "canopy": "#F2F0EA", "parapet": "flat",
		"windows": [[70.0, 160.0], [540.0, 100.0]], "door_cx": 380.0, "balcony": [270.0, 650.0], "porch": [300.0, 460.0],
		"stair": [Vector2(480, 336), Vector2(580, 400), Vector2(620, 540), Vector2(590, 696)],
		"fence": "black", "basement": [100.0],
	},
	# 5669, red brick, a dark door under its iron balconies and their canopy, the stair down to the left (5669…, 5671… and close-ups).
	{
		"name": "impair_5669",
		"bricks": ["#A0503A", "#AA5A42", "#924632", "#B4624A", "#9A4C36"], "mortar": "#C8BBAA",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D9D2C4", "lintel_dark": "#A39A8A",
		"door": "#2B2B2E", "door_dark": "#111111", "door_style": "grille", "canopy": "#F2F0EA", "parapet": "flat",
		"windows": [[70.0, 130.0], [500.0, 130.0]], "door_cx": 340.0, "balcony": [230.0, 460.0], "porch": [260.0, 420.0],
		"stair": [Vector2(240, 336), Vector2(120, 400), Vector2(90, 540), Vector2(150, 696)],
		"fence": "black", "basement": [520.0],
	},
	# 5661, buff brick under a corbelled parapet, black iron balconies, a white door with an oval light under a fanlight
	# (5661…, 5665…, 5671… and close-ups).
	{
		"name": "impair_5661", "floors": 3,
		"bricks": ["#B8946E", "#C4A07A", "#AA8862", "#CFAB86", "#B08C66"], "mortar": "#E2D6C4",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E4DCCB", "lintel_dark": "#B3A88F",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "oval", "door_surround": "lintel", "canopy": "#F2F0EA",
		"parapet": "corbel", "windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)],
		"fence": "black", "basement": [460.0],
	},
	# 5655, red brick under a mansard of dark slate, a white balcony at each window, a white stone pilaster down the middle, no
	# outdoor stair (5649…, 5653…, 5665… and close-ups).
	{
		"name": "impair_5655",
		"bricks": ["#A84E38", "#B25840", "#9A4632", "#BC6248", "#A04A34"], "mortar": "#D8CABA",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#F2F0EA", "lintel_dark": "#C2BDB2",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "oval", "metal": "#F5F5F2", "metal_light": true,
		"parapet": "mansard", "pilasters": [350.0], "windows": [[90.0, 160.0], [440.0, 160.0]], "door_cx": 340.0,
		"balcony": [60.0, 640.0], "balconies": [[64.0, 276.0], [414.0, 626.0]], "porch": [60.0, 280.0],
		"door_floors": [0], "stair": [], "fence": "white", "halloween": false, "basement": [],
	},
	# 5649, red-brown brick, iron balconies under a white canopy, an iron stair curling down to the left (5649…, 5653… and close-ups).
	{
		"name": "impair_5649",
		"bricks": ["#9A5440", "#A65E48", "#8C4C38", "#B06850", "#945038"], "mortar": "#D2C4B2",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E8E2D6", "lintel_dark": "#B3AA9A",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "leaded", "canopy": "#F2F0EA", "parapet": "flat", "ornate": true,
		"windows": [[90.0, 140.0], [520.0, 120.0]], "door_cx": 390.0, "balcony": [270.0, 500.0], "porch": [300.0, 470.0],
		"stair": [Vector2(280, 336), Vector2(160, 400), Vector2(130, 540), Vector2(190, 696)],
		"fence": "black", "basement": [100.0],
	},
	# 5641, the newer one: red brick and its white band below, a white upper floor with wide black-framed windows (5641…, 5643…,
	# 5647… and close-ups).
	{
		"name": "impair_5641", "kind": "modern", "width": 700.0, "door_x": 240.0,
		"bricks": ["#B4513F", "#A8473A", "#B85C48", "#9A3F33", "#C0624A"], "mortar": "#D2C4B4",
		"lintel": "#D8D2C6", "lintel_dark": "#A39D93", "step": "#9A968E", "step_dark": "#6E6A62", "metal": "#2B2B2E",
		"windows": [[80.0, 220.0], [380.0, 220.0]], "ground_window": [420.0, 120.0], "door_cx": 240.0, "basement": [], "upper_frame": "#232326", "mullions": 3, "roof_rail": true,
	},
	# 5637, the little white one-storey house (5635…, 5647… and close-ups).
	{
		"name": "impair_5637", "kind": "bungalow", "width": 640.0, "door_x": 320.0,
		"trim": "#F2F0EA", "trim_dark": "#B9B5AC", "lintel": "#E4E1DA", "lintel_dark": "#B9B5AC", "lintel_style": "none",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "slots", "stripe_color": "#5E86B5",
		"windows": [[80.0, 150.0], [410.0, 150.0]], "door_cx": 320.0, "fence": "black", "basement": [],
	},
	# 5631, red brick, red and white striped awnings over its balconies, the stair down to the left (5623…, 5631…, 5635… and close-ups).
	{
		"name": "impair_5631",
		"bricks": ["#A85238", "#B25C42", "#9A4A32", "#BC664A", "#A24E36"], "mortar": "#D4C6B4",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E4DCCB", "lintel_dark": "#B3A88F",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "stripe_awnings": true, "parapet": "flat",
		"windows": [[80.0, 150.0], [480.0, 120.0]], "door_cx": 380.0, "balcony": [310.0, 620.0], "porch": [320.0, 440.0],
		"stair": [Vector2(320, 336), Vector2(200, 400), Vector2(170, 540), Vector2(230, 696)],
		"fence": "black", "basement": [100.0],
	},
	# 5621, cream brick under a pressed cornice with its little pediment, black balconies the width of the front, a steel stair with
	# wooden treads (5623…, 5631… and close-ups).
	{
		"name": "impair_5621", "floors": 3, "width": 760.0,
		"bricks": ["#E8DCC4", "#E2D4BA", "#EEE4D0", "#DCCDB2", "#E6D9BF"], "mortar": "#F2ECE0",
		"cornice": "#ECE3CF", "cornice_dark": "#B9AA8C", "pediment": true,
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#F0E8D8", "lintel_dark": "#C2B49A",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "tread": "#8A5A3A", "tread_dark": "#5E3B24",
		"windows": [[90.0, 120.0], [470.0, 150.0]], "door_cx": 320.0, "balcony": [50.0, 700.0], "porch": [220.0, 420.0],
		"stair": [Vector2(210, 336), Vector2(160, 456), Vector2(110, 576), Vector2(60, 696)],
		"fence": "wood", "basement": [],
	},
	# 5615, pale brick, concrete balconies the width of the front, a steel stair with wooden treads; its dark brick side runs along
	# the lane (5609…, 5615…, 5617… and close-ups).
	{
		"name": "impair_5615", "floors": 3, "width": 760.0,
		"bricks": ["#E2D2B4", "#D8C8A8", "#EADCC0", "#CFBF9E", "#E6D7BA"], "mortar": "#EFE7DA",
		"trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "lintel_style": "none",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "tread": "#8A5A3A", "tread_dark": "#5E3B24",
		"slab": "#D9D4CA", "slab_dark": "#A9A398", "flower_boxes": true, "parapet": "flat",
		"windows": [[60.0, 120.0], [440.0, 120.0], [596.0, 110.0]], "door_cx": 300.0, "balcony": [40.0, 720.0], "porch": [220.0, 400.0],
		"stair": [Vector2(170, 336), Vector2(127, 456), Vector2(83, 576), Vector2(40, 696)],
		"fence": "wood", "halloween": false, "basement": [],
	},
	# The lane near Dandurand (5609…, 5617…).
	{"name": "ruelle_impair_dandurand", "kind": "lane_odd", "width": 600.0, "lane_style": "dandurand"},
	# 5601–5609, the gabled block at the corner (5601…, 5605…, 5609… and close-ups).
	{
		"name": "impair_5601", "kind": "gables", "width": 1400.0, "floors": 3, "top": 48.0, "door_x": 700.0,
		"bricks": ["#C98A64", "#D0936C", "#BF805A", "#D69C74", "#C4865F"], "mortar": "#E8D9C6",
		"lintel": "#E4DCCD", "lintel_dark": "#B5AC9C", "siding": "#B98656", "door_cx": 700.0,
		"metal": "#1F1F1F", "tread": "#5A5A5A", "tread_dark": "#3A3A3A", "fence": "chain", "halloween": false, "basement": [180.0, 1124.0],
	},
	# Across Rue Dandurand: the next block's corner building, its side.
	{
		"name": "impair_dandurand_sud", "kind": "side_wall", "width": 580.0, "floors": 3,
		"bricks": ["#B5603F", "#A85536", "#C26B48", "#9C4D31", "#C77650"], "mortar": "#D6C9B9",
		"parapet": "flat", "windows": [[110.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 6e to 7e Avenue (reference/streetview/rue-masson/, INDEX.md "Rue Masson 2000–3400") ──
	# The odd side is the north side; its pictures 2901… to 2939…; the even (south) side 2902… to 2990…. Seasonal things, cars,
	# bikes, café terraces, sale posters and graffiti are left out on purpose. Shop names are labels laid by scenes/masson.gd.
	# Across 6e from 2901: the side of Église Saint-Esprit's grounds, grey stone.
	{
		"name": "masson_eglise_cote", "kind": "side_wall", "width": 600.0, "floors": 3,
		"bricks": ["#B9B4AA", "#AEA99F", "#C2BDB3", "#A8A399", "#BDB8AE"], "mortar": "#8E8A82",
		"parapet": "flat", "windows": [[160.0, 90.0], [360.0, 90.0]], "basement": [], "downspout": 540.0,
	},
	# 2901–2905, at 6e, Fraîchement Bon, the greengrocer's: red brick, a stack of balconies at the corner (the grey stone
	# building drawn here before was its side on 6e, from an old picture), two bays of shop under black signs
	# and gooseneck lamps, the fruit out front, the flats' door between them (2903… and close-ups).
	{
		"name": "masson_2903", "kind": "commerce", "width": 820.0, "floors": 3,
		"bricks": ["#8E3E30", "#9A4636", "#7E3628", "#A44E3C", "#923F31"], "mortar": "#C8BBAA", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[200.0, 110.0], [420.0, 110.0], [620.0, 110.0]],
		"projecting": [[34.0, 170.0]], "pier": "#B9B3A8", "window_style": "hung", "hung_frame": "#E8E4DA", "lamp_color": "#F2F0EA",
		"shops": [{"x0": 30.0, "x1": 420.0, "sign": "#1E4A32", "awning": "#1E4A32", "lamps": 3, "door": 360.0, "inside": "fruit", "crates": true, "transom": "none"},
			{"x0": 500.0, "x1": 790.0, "sign": "#1E4A32", "awning": "#1E4A32", "lamps": 2, "crates": true, "door": 740.0, "inside": "fruit", "transom": "none"}],
		"res_doors": [460.0], "basement": [],
	},
	# 2909–2919, Poulet Rouge: dark brown brick, the black front of the restaurant, the white doors to the flats (2909…, 2913…, 2919…).
	{
		"name": "masson_2909", "kind": "commerce", "width": 960.0, "floors": 3,
		"bricks": ["#5E3A2E", "#6E4234", "#4E3026", "#744838", "#583428"], "mortar": "#9A8E80", "parapet": "flat",
		"lintel": "#B9B3A8", "lintel_dark": "#7E786E", "window_style": "hung", "hung_frame": "#E8E4DA", "windows": [[90.0, 120.0], [330.0, 120.0], [580.0, 120.0], [800.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 720.0, "sign": "#141416", "door": 600.0, "inside": "restaurant", "wall": "#3A3230", "transom": "none", "panes": 3, "kick_h": 20.0}], "res_doors": [820.0], "basement": [],
	},
	# 2921–2931, red brick with Juliet rails at every window, white stone lintels; downstairs four shops: Aquarium café-bar,
	# N. Mode, Frites Alors!, Coyote's tacos (2919…, 2925… and close-ups).
	{
		"name": "masson_2925", "kind": "commerce", "width": 1300.0, "floors": 3,
		"bricks": ["#B04A38", "#BC5440", "#A44232", "#C25C46", "#AA4834"], "mortar": "#D8CABA", "parapet": "flat",
		"lintel": "#E8E2D6", "lintel_dark": "#B3AA9A", "juliets": true, "metal": "#1F1F1F", "window_style": "casement", "frame": "#F2F0EA",
		"windows": [[80.0, 100.0], [290.0, 100.0], [500.0, 100.0], [710.0, 100.0], [920.0, 100.0], [1130.0, 100.0]],
		"shops": [{"x0": 30.0, "x1": 300.0, "sign": "#1E3E5E", "door": 90.0, "inside": "restaurant", "front": "wood", "frame": "#3A3A3C", "kick": "panel"},
			{"x0": 300.0, "x1": 560.0, "sign": "#2B2B2E", "door": 500.0, "inside": "clothes", "transom": "none"},
			{"x0": 560.0, "x1": 860.0, "sign": "#E9E2D0", "frame": "#5A3A24", "door": 620.0, "inside": "restaurant", "front": "wood", "door_style": "double"},
			{"x0": 860.0, "x1": 1270.0, "sign": "#1E1E20", "frame": "#2B1E18", "door": 1200.0, "inside": "restaurant", "front": "wood", "kick": "tile", "tile": "#C8202A"}],
		"basement": [],
	},
	# 2933–2939, at 7e: the old bank in grey stone, fluted pilasters, a copper-topped cornice, the door at the corner (2933…, 2937…, 2939…).
	{
		"name": "masson_2933", "kind": "bank", "width": 1500.0, "floors": 2, "halloween": false,
		"stone": "#BDB8AE", "pilasters": [420.0, 800.0, 1180.0], "windows": [[110.0, 240.0], [500.0, 230.0], [880.0, 230.0]],
		"corner_side": 1.0, "basement": [],
	},
	# Across 7e from the bank: the side of Première Moisson's building, brown-buff brick on two floors (3003…).
	{
		"name": "masson_3001_cote", "kind": "side_wall", "width": 580.0, "floors": 2,
		"bricks": ["#9C7A52", "#A8845A", "#8E6E4A", "#B08C62", "#A07E56"], "mortar": "#C9B89E",
		"parapet": "flat", "windows": [[100.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 7e (left) to 6e (right). Across 7e: the side of 3000, painted pink over its brick (3000…).
	{
		"name": "masson_3000_cote", "kind": "side_wall", "width": 580.0, "floors": 2,
		"bricks": ["#D4B4AA", "#CDAEA4", "#D9BAB0", "#C9A89E", "#D6B6AC"], "mortar": "#D9BEB4",
		"parapet": "flat", "windows": [[110.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 520.0,
	},
	# 2970–2990, at 7e: four floors, the flats behind white-framed windows with Juliet rails; downstairs the Tim Hortons at the
	# corner and a row of shopfronts (2970…, 2974…, 2980…, 2982…, 2990…; the lilies painted big were on its side, on 7e).
	{
		"name": "masson_2970", "kind": "commerce", "width": 1500.0, "floors": 4, "upper": "frame", "juliets": true,
		"concrete": "#D8CDB8", "frame_piers": [30.0, 380.0, 740.0, 1100.0, 1440.0], "metal": "#2B3A6E",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E",
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#3A3A3C", "door": 130.0, "inside": "cafe", "transom": "none", "panes": 3},
			{"x0": 560.0, "x1": 1000.0, "sign": "#2B2B2E", "door": 920.0, "inside": "salon", "transom": "none", "panes": 3},
			{"x0": 1000.0, "x1": 1470.0, "sign": "#1E1E20", "door": 1080.0, "inside": "goods", "transom": "none", "panes": 3}], "basement": [],
	},
	# 2930–2958: four floors in a pale concrete frame with Juliet rails; downstairs a hair salon, Mèdz, La Puce the jeweller's, the
	# building's lobby and an accountant's (2930…, 2940…, 2950… and close-ups).
	{
		"name": "masson_2930", "kind": "commerce", "width": 1700.0, "floors": 4, "upper": "frame", "juliets": true,
		"concrete": "#D9D0BE", "frame_piers": [30.0, 440.0, 850.0, 1260.0, 1640.0], "metal": "#1F1F1F",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E",
		"shops": [{"x0": 30.0, "x1": 440.0, "sign": "#2B2B2E", "door": 380.0, "inside": "salon"},
			{"x0": 440.0, "x1": 740.0, "sign": "#1E1E20", "door": 700.0, "inside": "salon", "wall": "#E8DCCC", "transom": "none"},
			{"x0": 740.0, "x1": 1130.0, "sign": "#141416", "frame": "#141416", "door": 1080.0, "inside": "jewellery", "kick": "tile", "tile": "#C8202A"},
			{"x0": 1130.0, "x1": 1400.0, "sign": "#3A3A3C", "frame": "#3A3A3C", "door": 1265.0, "dark": true, "door_style": "double", "transom": "none"},
			{"x0": 1400.0, "x1": 1670.0, "sign": "#E9E5DE", "frame": "#4E4E50", "door": 1600.0, "inside": "office"}],
		"basement": [],
	},
	# 2908–2928, the hardware store, Quincaillerie Bélanger (RONA): two floors faced in pale grey stone panels, a taller panel of
	# brown brick over the RONA's door, the long dark sign band, its display windows (2908…, 2912…, 2916…, 2918…).
	{
		"name": "masson_2908", "kind": "commerce", "width": 1500.0, "floors": 2, "halloween": false, "upper": "stone", "upper_stone": "#CFCDC8",
		"metal_panels": [[900.0, 1260.0, "#8A5236"]],
		"bricks": ["#4E3A3E", "#5A4448", "#463438", "#62484C"], "mortar": "#8E8486", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [], "belt": "#3A3E42",
		"shops": [{"x0": 30.0, "x1": 900.0, "sign": "#3A3E42", "frame": "#2B2E32", "door": 300.0, "lamps": 4, "inside": "hardware", "kick": "brick"},
			{"x0": 900.0, "x1": 1470.0, "sign": "#1F4E9A", "frame": "#2B2E32", "door": 1180.0, "inside": "hardware", "kick": "brick", "door_style": "double"}],
		"basement": [],
	},
	# 2902–2904, at 6e: buff brick laid in corbelled bands, an arched doorway under a balcony, the dark tiled front of Fido at the
	# corner (2902…, 2904… and close-ups).
	{
		"name": "masson_2902", "kind": "commerce", "width": 1100.0, "floors": 3,
		"bricks": ["#D4A774", "#C99C6A", "#DDB07E", "#BE9262", "#D8AC78"], "mortar": "#EFE2CC", "parapet": "corbel", "window_style": "hung", "lintel_style": "arch",
		"lintel": "#C9965E", "lintel_dark": "#9A7044", "windows": [[90.0, 110.0], [320.0, 110.0], [600.0, 110.0], [860.0, 110.0]],
		"projecting": [[560.0, 760.0]], "pier": "#2E3236",
		"shops": [{"x0": 30.0, "x1": 520.0, "sign": "#2B2B2E", "frame": "#2E3236", "door": 440.0, "inside": "clothes", "kick": "brick"},
			{"x0": 820.0, "x1": 1070.0, "sign": "#FFE600", "frame": "#2E3236", "door": 945.0, "inside": "phones", "transom": "none"}],
		"res_doors": [660.0], "basement": [],
	},
	# Across 6e from 2902: the corner of the next block, its side.
	{
		"name": "masson_2892_cote", "kind": "side_wall", "width": 580.0, "floors": 3,
		"bricks": ["#7E4436", "#8A4A3A", "#6E3A2E", "#94543F", "#743F33"], "mortar": "#BFB2A3",
		"parapet": "flat", "windows": [[100.0, 90.0], [320.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 5e to 6e Avenue ──
	# The north side: the church grounds, the presbytery at 5e then Église Saint-Esprit (rue-masson/2851…, 2863…, captured for it).
	# Across 5e: BMO's side, red brick over a stone base (2833…, 2831…).
	{
		"name": "masson_2833_cote", "kind": "side_wall", "width": 560.0, "floors": 2, "lower_stone": true,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"parapet": "", "windows": [[110.0, 110.0], [330.0, 110.0]], "basement": [], "downspout": 520.0,
	},
	{
		"name": "masson_presbytere", "kind": "presbytere", "width": 1200.0, "floors": 3, "halloween": false,
		"bricks": ["#9A3E30", "#A8473A", "#8E382C", "#B04E3E", "#94402F"], "mortar": "#C9BBAC", "parapet": "flat",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "lintel_style": "arch", "door_cx": 600.0,
		"windows": [[130.0, 100.0], [330.0, 100.0], [800.0, 100.0], [990.0, 100.0]], "basement": [], "downspout": 1150.0,
	},
	{
		"name": "masson_eglise", "kind": "church", "width": 2900.0, "floors": 4, "halloween": false,
		"stone": "#C9C7C0", "church_cx": 1250.0,
	},
	# Across 6e: 2901's side, red brick over its grey stone ground floor.
	{
		"name": "masson_2901_cote", "kind": "side_wall", "width": 560.0, "floors": 3, "lower_stone": true,
		"bricks": ["#9A4636", "#A84E3C", "#8E3E30", "#B05844", "#94422F"], "mortar": "#CFC2B4",
		"parapet": "flat", "windows": [[110.0, 90.0], [330.0, 90.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 6e (left) to 5e (right). Across 6e: the side of 2902, buff brick in corbelled bands.
	{
		"name": "masson_2902_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#D4A774", "#C99C6A", "#DDB07E", "#BE9262", "#D8AC78"], "mortar": "#EFE2CC", "lintel": "#E8E0D0",
		"lintel_dark": "#B9AE98", "parapet": "corbel", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2888–2892, the Banque Nationale at 6e: two floors of red-brown brick in a frame of pale stone, big windows (2888…, 2892…).
	{
		"name": "masson_2888", "kind": "commerce", "width": 1100.0, "floors": 2, "halloween": false,
		"bricks": ["#8E4A3A", "#9A5242", "#844436", "#A0584A", "#8A4838"], "mortar": "#B9AC9E", "parapet": "flat",
		"lintel": "#D8CFBF", "lintel_dark": "#A89E8C", "lintel_style": "none", "window_style": "fixed", "frame": "#3A3A3C", "stone_frame": "#D8CFBF", "belt": "#D8CFBF",
		"windows": [[150.0, 120.0], [330.0, 120.0], [510.0, 120.0], [690.0, 120.0], [870.0, 120.0]],
		"shops": [{"x0": 100.0, "x1": 1000.0, "sign": "#E9E5DE", "frame": "#6E6A64", "door": 820.0, "inside": "bank", "transom": "none", "panes": 6}], "basement": [],
	},
	# 2884–2886: narrow, three floors of dark red-brown brick, the parapet stepped up at both ends, the middle of the two upper
	# floors set back behind black iron balconies; a café downstairs behind white frames (2886…, 2884…, 2876…). The grey stone
	# row with L'Oeufrier follows right after it: the old pictures, taken from 6e, showed a terrace on the roof, a brick building
	# and a lot that are its side and the backs behind it.
	{
		"name": "masson_2884", "kind": "commerce", "width": 640.0, "floors": 3,
		"bricks": ["#7A4A3A", "#865444", "#6E4234", "#8E5C4A", "#744636"], "mortar": "#B9AC9E", "parapet": "corbel",
		"lintel": "#C9BFAE", "lintel_dark": "#8E8474", "window_style": "hung", "hung_frame": "#F2F0EA", "windows": [[60.0, 110.0], [470.0, 110.0]],
		"loggias": [[220.0, 420.0]], "metal": "#1F1F1F",
		"shops": [{"x0": 30.0, "x1": 610.0, "sign": "#E9E7E1", "frame": "#F2F0EA", "door": 120.0, "inside": "cafe", "transom": "none", "panes": 3}],
		"basement": [],
	},
	# 2862–2872: the grey stone row goes on, L'Oeufrier at its 6e end (2870…, 2862…, 2872… close-ups).
	{
		"name": "masson_2870", "kind": "commerce", "width": 1000.0, "floors": 3, "upper": "stone", "upper_stone": "#B2AEA6",
		"bricks": ["#A9A59D", "#B2AEA6", "#A09C94"], "mortar": "#8E8A82", "parapet": "corbel",
		"lintel": "#C9C5BC", "lintel_dark": "#8E8A82", "metal": "#1F1F1F", "window_style": "slider", "frame": "#2B2B2E",
		"windows": [[80.0, 100.0], [190.0, 100.0], [430.0, 100.0], [540.0, 100.0], [780.0, 100.0], [890.0, 100.0]],
		"projecting": [[410.0, 660.0]],
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#1E1E20", "frame": "#F2F0EA", "door": 110.0, "inside": "restaurant", "wall": "#F2EEE6", "transom": "none"},
			{"x0": 560.0, "x1": 970.0, "sign": "#8A4A30", "ribs": true, "frame": "#4A2E22", "door": 900.0, "inside": "cafe", "front": "wood", "kick": "brick"}],
		"basement": [],
	},
	# 2846–2858: rusticated grey stone on three floors, windows in pairs, balconies on dark slabs, the parapet raised in shallow
	# curves; the rust-red corrugated band over its shops: Le Poke Station, a florist's, Tabagie & Vapeshop, Simasson (2858…, 2862…).
	{
		"name": "masson_2846", "kind": "commerce", "width": 1700.0, "floors": 3, "upper": "stone", "upper_stone": "#B5B1A9",
		"bricks": ["#A9A59D", "#B2AEA6", "#A09C94"], "mortar": "#8E8A82", "parapet": "corbel",
		"lintel": "#C9C5BC", "lintel_dark": "#8E8A82", "metal": "#1F1F1F", "window_style": "slider", "frame": "#2B2B2E",
		"windows": [[80.0, 100.0], [190.0, 100.0], [420.0, 100.0], [530.0, 100.0], [760.0, 100.0], [870.0, 100.0],
			[1100.0, 100.0], [1210.0, 100.0], [1440.0, 100.0], [1550.0, 100.0]],
		"projecting": [[400.0, 650.0], [1080.0, 1330.0]],
		"shops": [{"x0": 30.0, "x1": 420.0, "sign": "#8A4A30", "ribs": true, "frame": "#4A2E22", "door": 90.0, "inside": "restaurant", "wall": "#E8E4DA"},
			{"x0": 420.0, "x1": 760.0, "sign": "#8A4A30", "ribs": true, "frame": "#4A2E22", "door": 700.0, "inside": "florist", "front": "wood", "kick": "wood"},
			{"x0": 760.0, "x1": 1250.0, "sign": "#8A4A30", "ribs": true, "frame": "#1E1E20", "door": 1190.0, "inside": "goods", "kick": "tile", "tile": "#2B2B2E"},
			{"x0": 1250.0, "x1": 1670.0, "sign": "#8A4A30", "ribs": true, "frame": "#4A2E22", "door": 1310.0, "inside": "office", "transom": "none"}],
		"res_doors": [], "basement": [],
	},
	# ── Rue Masson, 7e to 8e Avenue ──
	# The north side, 7e (left) to 8e (right). Across 7e: the bank's side, stone (2933…).
	{
		"name": "masson_2933_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#BDB8AE", "#B3AEA4", "#C6C1B7", "#ADA89E", "#C0BBB1"], "mortar": "#9A958C",
		"parapet": "flat", "windows": [[110.0, 110.0], [330.0, 110.0]], "basement": [], "downspout": 520.0,
	},
	# 3001–3015, Première Moisson, the bakery: two floors of brown-buff brick, a ribbon of small windows upstairs on a stone sill,
	# a white stone band over the long black sign with its lamps, stone piers between the windows (3003…, 3011… and close-ups).
	{
		"name": "masson_3003", "kind": "commerce", "width": 1400.0, "floors": 2,
		"bricks": ["#9C7A52", "#A8845A", "#8E6E4A", "#B08C62", "#A07E56"], "mortar": "#C9B89E", "parapet": "flat",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "lintel_style": "plain", "belt": "#E2DCD0",
		"windows": [[330.0, 62.0], [410.0, 62.0], [490.0, 62.0], [570.0, 62.0], [650.0, 62.0], [730.0, 62.0], [810.0, 62.0],
			[890.0, 62.0], [970.0, 62.0], [1050.0, 62.0]], "win_h": 84.0, "win_dy": 46.0, "ribbon_sill": true, "window_style": "fixed", "frame": "#2E2A26",
		"shops": [{"x0": 30.0, "x1": 1370.0, "sign": "#1A1A1A", "frame": "#2A2A2A", "door": 700.0, "lamps": 7, "door_style": "double", "inside": "bakery", "front": "wood", "kick": "stone", "transom": "none"}],
		"piers": [260.0, 520.0, 880.0, 1140.0], "pier_stone": "#ECE8E0", "basement": [],
	},
	# 3015–3023: red brick on two floors, white windows, a black iron balcony; the sandwich shop under its dark band (3011…,
	# 3015…, 3021…). It runs on to the next building: no parking lot at 3019.
	{
		"name": "masson_3021", "kind": "commerce", "width": 1000.0, "floors": 2,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "window_style": "hung", "hung_frame": "#F2F0EA", "windows": [[90.0, 110.0], [300.0, 110.0], [760.0, 110.0]],
		"projecting": [[480.0, 700.0]], "metal": "#1F1F1F",
		"shops": [{"x0": 30.0, "x1": 520.0, "sign": "#2B2B2E", "frame": "#1E1E20", "door": 120.0, "inside": "restaurant", "kick": "brick"},
			{"x0": 520.0, "x1": 970.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 880.0, "inside": "cafe", "kick": "brick"}], "basement": [],
	},
	# 3025–3035: red brick on three floors, stone surrounds with keystones round the windows, two shops (3025…, 3031… close-ups).
	{
		"name": "masson_3025", "kind": "commerce", "width": 1000.0, "floors": 3,
		"bricks": ["#A04A3A", "#AE5442", "#943F31", "#B85E4A", "#A44C3C"], "mortar": "#CDBFB0", "parapet": "corbel",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "lintel_style": "ears", "keystone": true,
		"windows": [[100.0, 110.0], [360.0, 110.0], [610.0, 110.0], [840.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 500.0, "sign": "#B02A2A", "frame": "#2B2B2E", "door": 440.0, "inside": "restaurant", "front": "wood", "kick": "wood"},
			{"x0": 500.0, "x1": 970.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 560.0, "inside": "salon", "transom": "none"}], "basement": [],
	},
	# 3039: three floors of pinkish stucco with stone quoins at its corners, a black storefront (3039…, 3043…).
	{
		"name": "masson_3039", "kind": "commerce", "width": 720.0, "floors": 3, "upper": "stucco", "stucco": "#C9B0A4",
		"bricks": ["#D9C4B6"], "mortar": "#C9B4A6", "parapet": "flat", "quoins": true,
		"lintel": "#E8E0D4", "lintel_dark": "#B5AA98", "window_style": "hung", "hung_frame": "#F2F0EA", "windows": [[110.0, 100.0], [320.0, 100.0], [520.0, 100.0]],
		"shops": [{"x0": 30.0, "x1": 690.0, "sign": "#1A1A1A", "frame": "#1A1A1A", "door": 600.0, "inside": "cafe", "wall": "#3A3230", "transom": "none", "panes": 2}], "basement": [],
	},
	# Across 8e: the next block's corner, its side.
	{
		"name": "masson_3071_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 8e (left) to 7e (right). Across 8e: the side of 3086, brick on two floors (3076…).
	{
		"name": "masson_3070_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#A4553E", "#B05E48", "#984E38", "#B86650", "#A0523C"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 3038–3040, at 8e: red brick on three floors (3040…, 3038…).
	{
		"name": "masson_3038", "kind": "commerce", "width": 820.0, "floors": 3,
		"bricks": ["#7E3A30", "#8A4236", "#72342A", "#94483A", "#82382E"], "mortar": "#C9BBAC", "parapet": "flat",
		"lintel": "#D8D0C0", "lintel_dark": "#9E968A", "lintel_style": "ears", "window_style": "slider", "frame": "#1E1E20", "windows": [[90.0, 110.0], [330.0, 110.0], [570.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 790.0, "sign": "#2B2B2E", "frame": "#1E1E20", "door": 160.0, "inside": "restaurant", "kick": "brick"}], "basement": [],
	},
	# 3030–3034: red brick on three floors, arched windows with iron balconies on the right; Lunetterie Milot and Raposo, the
	# Portuguese pâtisserie (3034…, 3040…).
	{
		"name": "masson_3034", "kind": "commerce", "width": 1000.0, "floors": 3,
		"bricks": ["#A44E3C", "#B05846", "#984434", "#B8604C", "#A04A3A"], "mortar": "#CDBFB0", "parapet": "corbel",
		"lintel": "#E8E2D6", "lintel_dark": "#A39A8A", "lintel_style": "ears", "window_style": "slider", "frame": "#1E1E20",
		"windows": [[90.0, 110.0], [320.0, 110.0], [580.0, 110.0], [800.0, 110.0]], "projecting": [[550.0, 940.0]],
		"shops": [{"x0": 30.0, "x1": 480.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 250.0, "inside": "optician", "transom": "none"},
			{"x0": 480.0, "x1": 970.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 900.0, "inside": "bakery", "front": "wood", "kick": "tile", "tile": "#3E7A4E"}], "basement": [],
	},
	# 3016–3028: buff brick on three floors, the parapet raised in a curved crest with scrolls (3012…, 3034…).
	{
		"name": "masson_3028", "kind": "commerce", "width": 880.0, "floors": 3,
		"bricks": ["#C9A87A", "#BE9C6E", "#D2B084", "#B49266", "#CCAA7C"], "mortar": "#E6DCCB", "parapet": "scroll",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "windows": [[100.0, 110.0], [380.0, 110.0], [640.0, 110.0]],
		"projecting": [[60.0, 260.0]],
		"shops": [{"x0": 30.0, "x1": 850.0, "sign": "#3A2A20", "frame": "#2B2B2E", "door": 420.0, "awning": "#7A2A2A", "inside": "restaurant", "front": "wood", "kick": "wood", "wall": "#6E2A2A"}],
		"basement": [],
	},
	# 3004–3014: grey-beige brick on two floors, wide windows; a bar and Tandoori Masson under its red awning (3002…, 3012…).
	{
		"name": "masson_3008", "kind": "commerce", "width": 1000.0, "floors": 2,
		"bricks": ["#7E7466", "#8A8072", "#72685C", "#948A7C", "#6E6458"], "mortar": "#C9C1B4", "parapet": "flat",
		"lintel": "#9A9286", "lintel_dark": "#6E665A", "lintel_style": "none", "window_style": "fixed", "frame": "#1E1E20", "windows": [[90.0, 150.0], [330.0, 150.0], [590.0, 150.0], [810.0, 150.0]],
		"shops": [{"x0": 30.0, "x1": 480.0, "sign": "#2B2B2E", "frame": "#1E1E20", "door": 420.0, "inside": "cafe", "wall": "#2E2A28", "front": "wood"},
			{"x0": 480.0, "x1": 970.0, "sign": "#C8202A", "frame": "#2B2B2E", "door": 900.0, "awning": "#C8202A", "inside": "restaurant", "kick": "tile", "tile": "#8E2020"}], "basement": [],
	},
	# 3000–3002, at 7e: two floors of grey-brown stone brick, like Tandoori Masson's next door, the Couche-Tard downstairs (3000…,
	# 3002…; the pink wall was its side on 7e).
	{
		"name": "masson_3000", "kind": "commerce", "width": 900.0, "floors": 2,
		"bricks": ["#9E968A", "#A8A094", "#948C80", "#B0A89C", "#99917F"], "mortar": "#C9C3B8", "parapet": "flat", "lintel": "#E8E0D4", "lintel_dark": "#B5AA98", "lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E",
		"windows": [[120.0, 110.0], [380.0, 110.0], [640.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 870.0, "sign": "#F2EFE8", "frame": "#C8202A", "door": 200.0, "inside": "goods", "transom": "none", "panes": 5}], "basement": [],
	},
	# Across 7e: the side of 2970, its pale concrete frame on four floors.
	{
		"name": "masson_2970_cote", "kind": "side_wall", "width": 560.0, "floors": 4,
		"bricks": ["#D8CDB8", "#D2C7B2", "#DED3BE", "#CFC4AF"], "mortar": "#C2B8A4",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 4e to 5e Avenue ──
	# The north side, 4e (left) to 5e (right). Across 4e: the next block's corner, its side.
	{
		"name": "masson_2755_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#C9A47E", "#BE9872", "#D2AE88", "#B48E68", "#CCA882"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2801–2809, at 4e: brown brick on three floors, big windows upstairs, the pawnbroker BANCO under its red signs and a tall
	# vertical sign (2801…, 2803…).
	{
		"name": "masson_2801", "kind": "commerce", "width": 900.0, "floors": 3,
		"bricks": ["#6A4234", "#764A3C", "#5E3A2E", "#80523E"], "mortar": "#B9AC9E", "parapet": "flat",
		"lintel": "#B9B3A8", "lintel_dark": "#7E786E", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "juliets": true, "windows": [[90.0, 160.0], [380.0, 160.0], [660.0, 160.0]],
		"shops": [{"x0": 30.0, "x1": 420.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 160.0, "inside": "restaurant"}, {"x0": 420.0, "x1": 870.0, "sign": "#D8202A", "frame": "#B01A22", "door": 800.0, "inside": "goods", "kick": "panel"}], "basement": [],
	},
	# 2811–2817: red brick on two floors, the parapet stepped up in the middle; Pattes & Griffes, the pet shop, its green sign
	# (2803…, 2815…).
	{
		"name": "masson_2811", "kind": "commerce", "width": 760.0, "floors": 2,
		"bricks": ["#B04E3A", "#BC5844", "#A44632", "#C4624C", "#AA4A36"], "mortar": "#D0C4B6", "parapet": "corbel",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "window_style": "slider", "frame": "#2B2B2E", "windows": [[100.0, 100.0], [330.0, 100.0], [560.0, 100.0]],
		"shops": [{"x0": 30.0, "x1": 730.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 640.0, "inside": "goods", "wall": "#E8F0E0", "kick": "brick"}], "basement": [],
	},
	# 2819–2821: two floors of grey stucco, a row of windows upstairs; Pizza Pizza under its red sign (2817…, 2819…).
	{
		"name": "masson_2819", "kind": "commerce", "width": 860.0, "floors": 2,
		"upper": "stucco", "stucco": "#C9C7C2", "bricks": ["#C9C7C2"], "mortar": "#B5B2AC", "parapet": "flat",
		"lintel": "#E8E6E0", "lintel_dark": "#9E9A92", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 200.0], [330.0, 200.0], [570.0, 200.0]],
		"shops": [{"x0": 30.0, "x1": 830.0, "sign": "#E8502A", "frame": "#2B2B2E", "door": 760.0, "inside": "restaurant", "wall": "#E8DCC8", "transom": "none"}], "basement": [],
	},
	# 2823–2827: two floors faced in cream siding, the café Trou. under its long navy sign, its door and the flats' white door at
	# the right; no lot at 2825 (2823…, 2825…, 2827…).
	{
		"name": "masson_2823", "kind": "commerce", "width": 1200.0, "floors": 2, "upper": "siding", "siding": "#E6DFCC",
		"bricks": ["#E6DFCC"], "mortar": "#C9C2B0", "parapet": "flat",
		"lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E", "windows": [[120.0, 200.0], [560.0, 200.0], [900.0, 200.0]],
		"shops": [{"x0": 30.0, "x1": 1000.0, "sign": "#1E2A4A", "frame": "#1A1A1A", "door": 640.0, "inside": "cafe", "transom": "none", "panes": 5}],
		"res_doors": [1090.0], "basement": [],
	},
	# 2829–2833, BMO at 5e: red brick on two floors over a stone base, a cornice, wide windows in stone surrounds (2829…, 2833…).
	{
		"name": "masson_2829", "kind": "commerce", "width": 1100.0, "floors": 2, "halloween": false,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0", "parapet": "",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "belt": "#D8D2C6", "window_style": "fixed", "frame": "#2B3A4A", "lintel_style": "none", "windows": [[110.0, 150.0], [420.0, 150.0], [760.0, 150.0]],
		"shops": [{"x0": 30.0, "x1": 1070.0, "sign": "#0079C1", "frame": "#D8D2C6", "door": 980.0, "inside": "bank", "kick": "stone", "transom": "none"}],
		"piers": [330.0, 640.0], "pier_stone": "#D8D2C6", "basement": [],
	},
	# Across 5e: the presbytery's side, red brick on three floors.
	{
		"name": "masson_2851_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#9A3E30", "#A8473A", "#8E382C", "#B04E3E", "#94402F"], "mortar": "#C9BBAC",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 5e (left) to 4e (right). Across 5e: the side of the grey stone row (2846…).
	{
		"name": "masson_2846_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#B5B1A9", "#ABA79F", "#BDB9B1", "#A39F97"], "mortar": "#8E8A82",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2826–2840, Dollarama at 5e: buff brick on three floors, white-framed windows, a cornice, the long sign band (2836…, 2840…).
	{
		"name": "masson_2836", "kind": "commerce", "width": 1300.0, "floors": 3, "halloween": false,
		"bricks": ["#D6B98C", "#CDB082", "#DEC296", "#C4A678", "#D2B488"], "mortar": "#EDE3D2", "parapet": "scroll",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "windows": [[90.0, 110.0], [330.0, 110.0], [580.0, 110.0], [830.0, 110.0], [1070.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 1270.0, "sign": "#00704A", "frame": "#2B2B2E", "door": 1150.0, "inside": "goods", "transom": "none", "panes": 7}], "basement": [],
	},
	# 2816–2826: buff brick on three floors (Dollarama's building goes on), a balcony with its plants, the Fruiterie au Melon Miel
	# under its red sign and striped awning with the fruit out on the sidewalk, then the flats' door; no parking lot at 2816
	# (2826…, 2818…, 2816…).
	{
		"name": "masson_2818", "kind": "commerce", "width": 1180.0, "floors": 3,
		"bricks": ["#D2B488", "#C9AA7E", "#DABE92", "#BEA074", "#D0B084"], "mortar": "#EDE3D2", "parapet": "flat",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "windows": [[90.0, 110.0], [330.0, 110.0], [580.0, 110.0], [830.0, 110.0], [1020.0, 110.0]],
		"projecting": [[60.0, 260.0]],
		"shops": [{"x0": 30.0, "x1": 900.0, "sign": "#D8322A", "frame": "#2B2B2E", "door": 760.0, "inside": "fruit", "awning": "#D8322A", "stripes": true, "crates": true, "transom": "none"}],
		"res_doors": [1000.0], "basement": [],
	},
	# 2806–2814: buff brick on three floors, white balconies, shops under their bands (2812…, 2802…).
	{
		"name": "masson_2812", "kind": "commerce", "width": 1300.0, "floors": 3,
		"bricks": ["#CDAE80", "#C2A274", "#D6B88A", "#B8986C", "#D0B084"], "mortar": "#E6DCCB", "parapet": "corbel",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "metal": "#F2F0EA", "slab": "#F2F0EA", "window_style": "hung", "hung_frame": "#F2F0EA",
		"windows": [[80.0, 100.0], [300.0, 100.0], [560.0, 100.0], [780.0, 100.0], [1040.0, 100.0]],
		"projecting": [[260.0, 500.0], [760.0, 1000.0]],
		"shops": [{"x0": 30.0, "x1": 640.0, "sign": "#2B2B2E", "frame": "#1E1E20", "door": 560.0, "inside": "restaurant", "kick": "brick"},
			{"x0": 640.0, "x1": 1270.0, "sign": "#E8812E", "frame": "#2B2B2E", "door": 700.0, "inside": "bakery", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 2800–2804, at 4e: red brick on three floors, a café on the corner (2804…, 2800…).
	{
		"name": "masson_2802", "kind": "commerce", "width": 860.0, "floors": 3,
		"bricks": ["#9A4A3A", "#A85442", "#8E4234", "#B05C48", "#9E4E3C"], "mortar": "#C9BBAC", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "lintel_style": "none", "window_style": "slider", "frame": "#1E1E20", "projecting": [[60.0, 300.0], [540.0, 780.0]], "metal": "#F2F0EA", "slab": "#F2F0EA", "windows": [[90.0, 110.0], [360.0, 110.0], [620.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 830.0, "sign": "#E8952E", "frame": "#1E1E20", "door": 760.0, "inside": "cafe", "transom": "none", "panes": 3}], "basement": [],
	},
	# Across 4e: the next block's corner, its side.
	{
		"name": "masson_2790_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#7E5440", "#8A5E4A", "#724A38", "#946852", "#7A503C"], "mortar": "#C2B4A4",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 8e to 9e Avenue ──
	# The north side, 8e (left) to 9e (right). Across 8e: the end of the low painted wall (3053…).
	{
		"name": "masson_3053_cote", "kind": "side_wall", "width": 520.0, "floors": 2,
		"bricks": ["#D9C4B6", "#D2BDAF", "#DECBBD"], "mortar": "#C9B4A6", "parapet": "flat", "windows": [], "basement": [], "downspout": -1.0,
	},
	# 3071–3101, at 8e: two floors, the ground floor painted pale pink with big plants, buff brick above (3071…, 3081…, 3091…).
	{
		"name": "masson_3071", "kind": "commerce", "width": 1100.0, "floors": 2,
		"bricks": ["#D2B48A", "#C8A87E", "#DABE94", "#BE9E74"], "mortar": "#EDE3D2", "parapet": "flat",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "windows": [[120.0, 130.0], [420.0, 130.0], [740.0, 130.0]],
		"ground": "painted", "paint": "#EBD3CF", "mural": "plants", "mural_x0": 30.0,
		"shops": [{"x0": 760.0, "x1": 1070.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 1000.0, "inside": "clothes", "transom": "none"}], "basement": [],
	},
	# 3103–3105, Méga Vrac: grey-buff brick on three floors, its blue sign (3103…).
	{
		"name": "masson_3103", "kind": "commerce", "width": 760.0, "floors": 3,
		"bricks": ["#B9AE9A", "#AFA490", "#C3B8A4", "#A69B88"], "mortar": "#DCD4C6", "parapet": "flat",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 120.0], [330.0, 120.0], [560.0, 120.0]],
		"shops": [{"x0": 30.0, "x1": 730.0, "sign": "#1F4E9A", "frame": "#1E1E20", "door": 120.0, "inside": "fruit", "wall": "#E8E0CC", "kick": "wood", "front": "wood"}], "basement": [],
	},
	# 3107–3109: buff brick on three floors, a tall red sign hung out at the corner (3103…, 3107…).
	{
		"name": "masson_3107", "kind": "commerce", "width": 620.0, "floors": 3,
		"bricks": ["#CDB088", "#C2A47C", "#D6BA92", "#B89A72"], "mortar": "#E6DCCB", "parapet": "flat",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "lintel_style": "none", "window_style": "hung", "hung_frame": "#F2F0EA", "quoins": true, "windows": [[90.0, 110.0], [380.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 590.0, "sign": "#C8202A", "frame": "#2B2B2E", "door": 300.0, "inside": "goods", "kick": "brick"}], "basement": [],
	},
	# 3115–3121, Quincaillerie A. Lalonde: brown brick on three floors, its white sign (3107…, 3115…).
	{
		"name": "masson_3115", "kind": "commerce", "width": 800.0, "floors": 3,
		"bricks": ["#C9AE88", "#BFA47E", "#D2B892", "#B49A74"], "mortar": "#E6DCCB", "parapet": "flat", "quoins": true,
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "lintel_style": "none", "window_style": "hung", "hung_frame": "#F2F0EA", "windows": [[90.0, 110.0], [340.0, 110.0], [580.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 770.0, "sign": "#F2F0EA", "frame": "#2B2B2E", "door": 400.0, "lamps": 2, "inside": "hardware", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 3125: grey stone on three floors (3127…).
	{
		"name": "masson_3125", "kind": "commerce", "width": 640.0, "floors": 3, "upper": "stone", "upper_stone": "#A9A59D",
		"bricks": ["#A9A59D", "#B2AEA6"], "mortar": "#8E8A82", "parapet": "flat",
		"lintel": "#C9C5BC", "lintel_dark": "#8E8A82", "windows": [[90.0, 110.0], [380.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 610.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 520.0, "inside": "salon", "kick": "stone"}], "basement": [],
	},
	# 3127–3129: red brick on two floors, a shop under a yellow sign (3127…).
	{
		"name": "masson_3127", "kind": "commerce", "width": 600.0, "floors": 2,
		"bricks": ["#A04A3A", "#AE5442", "#943F31", "#B85E4A"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#8E887E", "lintel_dark": "#5E5A54", "lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E", "windows": [[90.0, 130.0], [360.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 570.0, "sign": "#F2C230", "frame": "#2B2B2E", "door": 500.0, "inside": "restaurant", "wall": "#F2E6C8", "transom": "none"}], "basement": [],
	},
	# 3131–3135: the pub, its front of rough rubble stone on two floors, black frames (3127…, 3131…).
	{
		"name": "masson_3131", "kind": "commerce", "width": 680.0, "floors": 2, "upper": "rubble",
		"bricks": ["#A89F92", "#B7AFA2"], "mortar": "#8E8A82", "parapet": "flat",
		"lintel": "#8E8A82", "lintel_dark": "#5E5A54", "trim": "#1E1E20", "trim_dark": "#0E0E10",
		"windows": [[110.0, 130.0], [420.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 650.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 340.0, "inside": "restaurant", "wall": "#3A2A20", "front": "wood", "kick": "stone"}], "basement": [],
	},
	# 3139, at 9e: red brick on two floors, a café behind its black front (3139…).
	{
		"name": "masson_3139", "kind": "commerce", "width": 860.0, "floors": 2,
		"bricks": ["#A4553E", "#B05E48", "#984E38", "#B86650"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#B9B3A8", "lintel_dark": "#7E786E", "lintel_style": "none", "window_style": "slider", "frame": "#4A3426", "windows": [[90.0, 110.0], [330.0, 110.0], [580.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 830.0, "sign": "#1E1E20", "frame": "#1E1E20", "door": 120.0, "inside": "cafe", "transom": "none", "panes": 4}], "basement": [],
	},
	# Across 9e: the next block's corner, its side.
	{
		"name": "masson_3151_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#C8A27A", "#BC966E", "#D4AE86", "#B08A62"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 9e (left) to 8e (right). Across 9e: the next block's corner, its side.
	{
		"name": "masson_3150_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 3132–3138, at 9e: red brick on three floors, balconies (3132…, 3138…).
	{
		"name": "masson_3132", "kind": "commerce", "width": 800.0, "floors": 3,
		"bricks": ["#A8503E", "#B05A46", "#9A4636", "#B86450"], "mortar": "#D0C4B6", "parapet": "corbel",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[90.0, 110.0], [330.0, 110.0], [570.0, 110.0]],
		"projecting": [[40.0, 260.0]],
		"shops": [{"x0": 30.0, "x1": 770.0, "sign": "#1F4E9A", "frame": "#1E1E20", "door": 700.0, "inside": "goods", "wall": "#E8EEF4", "kick": "brick"}], "basement": [],
	},
	# 3128–3130, Bossa: two floors clad in white, wide windows, its black sign (3132…).
	{
		"name": "masson_3128", "kind": "commerce", "width": 640.0, "floors": 2, 
		"bricks": ["#ECEAE4", "#E4E2DC", "#F2F0EA"], "mortar": "#D2CFC8", "parapet": "flat",
		"lintel": "#E8E6E0", "lintel_dark": "#B9B5AC", "lintel_style": "none", "window_style": "fixed", "frame": "#2B2B2E", "flower_boxes": true, "windows": [[90.0, 200.0], [350.0, 200.0]],
		"shops": [{"x0": 30.0, "x1": 610.0, "sign": "#1A1A1A", "frame": "#1A1A1A", "door": 300.0, "inside": "deli", "transom": "none", "panes": 2}], "basement": [],
	},
	# 3126: brick on two floors, a shop under a red sign (3132…).
	{
		"name": "masson_3126", "kind": "commerce", "width": 620.0, "floors": 2,
		"bricks": ["#9A5A44", "#A6644E", "#8E5040", "#AE6C54"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[90.0, 130.0], [360.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 590.0, "sign": "#C8202A", "frame": "#2B2B2E", "door": 520.0, "awning": "#C8202A", "inside": "bakery", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 3112–3122, Poke Monster: two floors, the upper one clad in ribbed white metal, the ground floor's wall papered with posters
	# left out (3108…, 3124…).
	{
		"name": "masson_3112", "kind": "commerce", "width": 820.0, "floors": 2, "upper": "siding", "siding": "#ECEBE6",
		"bricks": ["#E8E6E0"], "mortar": "#C9C5BC", "parapet": "flat", "trim": "#F2F0EA",
		"lintel": "#E8E6E0", "lintel_dark": "#B9B5AC", "lintel_style": "none", "windows": [[160.0, 200.0], [500.0, 140.0]],
		"shops": [{"x0": 30.0, "x1": 790.0, "sign": "#1A1A1A", "frame": "#B01A22", "door": 700.0, "inside": "restaurant", "wall": "#F2EEE6", "transom": "none"}], "basement": [],
	},
	# 3104–3110: buff brick on two floors under a pressed cornice (3108…).
	{
		"name": "masson_3108", "kind": "commerce", "width": 740.0, "floors": 2,
		"bricks": ["#CDB088", "#C2A47C", "#D6BA92", "#B89A72"], "mortar": "#E6DCCB", "parapet": "",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "windows": [[90.0, 120.0], [320.0, 120.0], [540.0, 120.0]],
		"shops": [{"x0": 30.0, "x1": 710.0, "sign": "#2B2B2E", "frame": "#1E1E20", "door": 650.0, "inside": "salon", "front": "wood", "kick": "tile", "tile": "#2E3E5E"}], "basement": [],
	},
	{
		"name": "masson_3102", "kind": "masson_lot", "lot_style": "murals", "width": 420.0, "floors": 3, "halloween": false,
		"bricks": ["#9A4636", "#A84E3C", "#8E3E30", "#B05844"], "mortar": "#C9BBAC",
	},
	# 3076–3100, at 8e: a newer building on two floors, brick with tall round-arched windows and a bay of grey metal panels (3076…).
	{
		"name": "masson_3086", "kind": "commerce", "width": 1200.0, "floors": 2,
		"bricks": ["#A4553E", "#B05E48", "#984E38", "#B86650", "#A0523C"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "windows": [], "round_windows": [[120.0, 180.0], [880.0, 180.0]],
		"metal_panels": [[380.0, 720.0]],
		"shops": [{"x0": 30.0, "x1": 1170.0, "sign": "#3A3A3C", "frame": "#3A3A3C", "door": 200.0, "inside": "office", "transom": "none", "panes": 6}], "basement": [],
	},
	# Across 8e: the side of 3038, red brick on three floors.
	{
		"name": "masson_3038_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#9A4A3A", "#A85442", "#8E4234", "#B05C48"], "mortar": "#C9BBAC",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 3e to 4e Avenue ──
	# The north side, 3e (left) to 4e (right). Across 3e: the next block's corner, its side.
	{
		"name": "masson_2697_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8503E", "#B05A46", "#9A4636", "#B86450"], "mortar": "#D0C4B6",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2701–2705, at 3e: the old bank, buff brick on three floors between tall stone pilasters, on a stone base (2703…, 2711…).
	{
		"name": "masson_2703", "kind": "bank", "width": 1000.0, "floors": 3, "halloween": false,
		"stone": "#E8E4DA", "bank_brick": true, "pilaster": "#F2EFE8", "bricks": ["#8A5E44", "#966850", "#7E5440", "#A0725A"], "mortar": "#C2B4A4", "pilasters": [260.0, 500.0, 740.0], "windows": [[80.0, 150.0], [320.0, 150.0], [560.0, 150.0], [800.0, 150.0]],
		"corner_side": -1.0, "basement": [],
	},
	# 2707–2719: brown brick on three floors, windows framed in dark green, round windows on the top floor, a shop in green, then
	# the flats' door and a second shop; no parking lot at 2719, the building runs on to its neighbour (2707…, 2711…, 2715…,
	# 2719…; the building site in front of it in the pictures left out).
	{
		"name": "masson_2711", "kind": "commerce", "width": 1320.0, "floors": 3,
		"bricks": ["#8A5A42", "#96644C", "#7E5038", "#A06C54", "#86563E"], "mortar": "#C2B4A4", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "trim": "#2B2B2E", "trim_dark": "#1A1A1C", "window_style": "slider", "frame": "#2B2B2E",
		"windows": [[90.0, 120.0], [360.0, 120.0], [630.0, 120.0], [900.0, 120.0], [1140.0, 120.0]],
		"shops": [{"x0": 30.0, "x1": 870.0, "sign": "#2E5E3E", "frame": "#1E3E28", "door": 450.0, "inside": "florist", "front": "wood", "kick": "wood"},
			{"x0": 980.0, "x1": 1290.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 1220.0, "inside": "goods", "transom": "none"}],
		"res_doors": [925.0], "basement": [],
	},
	# 2721–2729: brown brick on three floors, two buildings in one row, a green sign (2721…, 2723…).
	{
		"name": "masson_2721", "kind": "commerce", "width": 1100.0, "floors": 3,
		"bricks": ["#8E5A44", "#9A644E", "#82503C", "#A46C56", "#8A5640"], "mortar": "#C2B4A4", "parapet": "corbel",
		"lintel": "#ECE8E0", "lintel_dark": "#A39A8A", "lintel_style": "ears", "window_style": "hung", "hung_frame": "#F2F0EA", "windows": [[90.0, 110.0], [330.0, 110.0], [600.0, 110.0], [860.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#3E7A4E", "frame": "#2B2B2E", "door": 480.0, "inside": "pharmacy", "kick": "brick"},
			{"x0": 560.0, "x1": 1070.0, "sign": "#C9A040", "frame": "#3A2E20", "door": 640.0, "inside": "restaurant", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 2723–2733: red-brown brick on three floors, balconies, the boulangerie (2723…).
	{
		"name": "masson_2731", "kind": "commerce", "width": 880.0, "floors": 3,
		"bricks": ["#A0563E", "#AC6048", "#944C36", "#B46A52", "#9C523C"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "windows": [[90.0, 110.0], [340.0, 110.0], [600.0, 110.0]],
		"projecting": [[560.0, 800.0]],
		"shops": [{"x0": 30.0, "x1": 850.0, "sign": "#E8E0D0", "frame": "#3A3A3C", "door": 760.0, "inside": "bakery", "front": "wood", "kick": "tile", "tile": "#5E3A2A"}], "basement": [],
	},
	# 2737–2755, at 4e: two floors of brown brick, wide windows upstairs in stone frames, Service Comptant downstairs under its
	# blue sign, a dark front behind a grille. The mural of sky and flowers is on its side wall on 4e, not on Masson: the old
	# pictures were taken from 4e (2737… and close-ups, 2747…, 2755…).
	{
		"name": "masson_2737", "kind": "commerce", "width": 1200.0, "floors": 2,
		"bricks": ["#8E5A44", "#9A644E", "#82503C", "#A46C56", "#8A5640"], "mortar": "#C2B4A4", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E",
		"windows": [[90.0, 300.0], [480.0, 150.0], [760.0, 150.0], [1000.0, 150.0]],
		"shops": [{"x0": 30.0, "x1": 640.0, "sign": "#1F4E9A", "frame": "#2B2B2E", "door": 560.0, "inside": "office", "transom": "none", "dark": true},
			{"x0": 640.0, "x1": 1170.0, "sign": "#8E5A44", "frame": "#3A3836", "door": 1100.0, "inside": "goods", "transom": "none"}], "basement": [],
	},
	# Across 4e: the side of BANCO's building, brown brick (2801…).
	{
		"name": "masson_2801_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#7E5A44", "#8A6450", "#72503C", "#946E58"], "mortar": "#B9AC9E",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 4e (left) to 3e (right). Across 4e: the side of the corner building there (2802…).
	{
		"name": "masson_2802_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#9A4A3A", "#A85442", "#8E4234", "#B05C48"], "mortar": "#C9BBAC",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2740–2752, at 4e: brown brick on three floors under a parapet of white stone scrolls, white sills, a little balcony; the
	# corner shop under a yellow canopy (2742…, 2740…, 2734…).
	{
		"name": "masson_2742", "kind": "commerce", "width": 900.0, "floors": 3,
		"bricks": ["#7E5440", "#8A5E4A", "#724A38", "#946852", "#7A503C"], "mortar": "#C2B4A4", "parapet": "scroll",
		"lintel": "#D8D2C6", "lintel_dark": "#9E968A", "windows": [[90.0, 110.0], [380.0, 140.0], [660.0, 110.0]],
		"projecting": [[340.0, 560.0]], "window_style": "hung", "hung_frame": "#F2F0EA", "slab": "#F2F0EA", "metal": "#F2F0EA",
		"shops": [{"x0": 30.0, "x1": 870.0, "sign": "#F2C21E", "frame": "#1E1E20", "door": 120.0, "inside": "cafe", "kick": "brick", "awning": "#F2C21E"}], "basement": [],
	},
	# 2734: brown brick on three floors (2734…).
	{
		"name": "masson_2734", "kind": "commerce", "width": 760.0, "floors": 3,
		"bricks": ["#8A5E48", "#966852", "#7E5440", "#A0725A"], "mortar": "#C2B4A4", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[90.0, 110.0], [330.0, 110.0], [560.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 730.0, "sign": "#3A3A3C", "frame": "#2B2B2E", "door": 650.0, "inside": "clothes", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 2716–2732, Jean Coutu: red-brown brick on two floors, the brick piers between wide windows, its yellow sign (2716…, 2726…).
	{
		"name": "masson_2716", "kind": "commerce", "width": 1300.0, "floors": 2, "halloween": false,
		"bricks": ["#A4553E", "#B05E48", "#984E38", "#B86650", "#A0523C"], "mortar": "#CDBFB0", "parapet": "corbel",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[100.0, 220.0], [420.0, 220.0], [740.0, 220.0], [1020.0, 220.0]],
		"shops": [{"x0": 30.0, "x1": 1270.0, "sign": "#FFD400", "frame": "#3A3A3C", "door": 640.0, "inside": "pharmacy", "transom": "none", "panes": 8}], "basement": [],
	},
	# 2700–2714, at 3e: red brick on two floors, wide windows upstairs, "Yoga chaud | Pilates" in white letters along the top,
	# a band of grey stone over the big windows of the ground floor (2700…, 2702…, 2714…). The grey metal and the graffiti were
	# its side and back, seen from 3e in the old pictures.
	{
		"name": "masson_2702", "kind": "commerce", "width": 1000.0, "floors": 2,
		"bricks": ["#A8473A", "#B4513F", "#9A3F33", "#B85C48"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E", "windows": [[120.0, 260.0], [560.0, 260.0]],
		"belt": "#C9C5BC",
		"shops": [{"x0": 30.0, "x1": 970.0, "sign": "#C9C5BC", "frame": "#3A3A3C", "door": 860.0, "inside": "salon", "transom": "none", "panes": 5}], "basement": [],
	},
	# Across 3e: the next block's corner, its side.
	{
		"name": "masson_2696_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#8E8A82", "#9A968E", "#86827A", "#A29E96"], "mortar": "#B9B5AC",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 2e to 3e Avenue ──
	# The north side, 2e (left) to 3e (right). Across 2e: the next block's corner, its side.
	{
		"name": "masson_2645_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#8E4A3A", "#9A5242", "#844436", "#A0584A"], "mortar": "#B9AC9E",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2651–2659, at 2e: a low commercial building of the 1970s, two floors, a long band of windows upstairs on pale panels, shops
	# under a green awning (2653…, 2661…).
	{
		"name": "masson_2653", "kind": "commerce", "width": 1100.0, "floors": 2, "upper": "stucco", "stucco": "#D8D6D0",
		"bricks": ["#D8D6D0"], "mortar": "#B9B5AC", "parapet": "flat", "lintel": "#E8E6E0", "lintel_dark": "#9E968A", "lintel_style": "none",
		"trim": "#3A3A3C", "trim_dark": "#1E1E20",
		"windows": [[60.0, 220.0], [300.0, 220.0], [540.0, 220.0], [780.0, 220.0]],
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#1E6E3E", "frame": "#2B2B2E", "door": 420.0, "awning": "#1E6E3E", "inside": "books", "transom": "none"},
			{"x0": 560.0, "x1": 1070.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 700.0, "inside": "goods", "kick": "panel"}], "basement": [],
	},
	# 2661–2697, to 3e: one new condo building, red brick on three floors, balconies set into the wall between strips of pale
	# stone, a ground floor of pale stone piers and big windows, the SAQ under its red band at the 3e corner. No yard in the
	# middle: the old pictures from 3e made it look like two buildings (2661…, 2663…, 2675…, 2679…, 2687…, 2693…, 2697…).
	# The posters in the shop windows are left out.
	{
		"name": "masson_2661", "kind": "commerce", "width": 800.0, "floors": 3,
		"bricks": ["#A8473A", "#B4513F", "#9A3F33", "#B85C48"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#A8473A", "lintel_dark": "#8E3A2F", "lintel_style": "none", "window_style": "slider", "frame": "#1E1E20", "trim": "#2B2B2E", "trim_dark": "#1E1E20",
		"windows": [[70.0, 130.0], [300.0, 130.0]], "loggias": [[500.0, 740.0]], "upper_piers": [470.0, 770.0], "metal": "#3A3A3C",
		"pier": "#C9C5BC",
		"shops": [{"x0": 30.0, "x1": 770.0, "sign": "#3A3A3C", "frame": "#B9B5AC", "door": 400.0, "inside": "salon", "transom": "none", "panes": 3}], "basement": [],
	},
	{
		"name": "masson_2675", "kind": "commerce", "width": 1680.0, "floors": 3,
		"bricks": ["#A44A3A", "#B05444", "#984234", "#B85E4C"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#A44A3A", "lintel_dark": "#8E3A2F", "lintel_style": "none", "window_style": "slider", "frame": "#1E1E20", "trim": "#2B2B2E", "trim_dark": "#1E1E20",
		"windows": [[60.0, 130.0], [250.0, 130.0], [700.0, 130.0], [890.0, 130.0], [1340.0, 130.0], [1520.0, 130.0]],
		"loggias": [[440.0, 660.0], [1080.0, 1300.0]], "upper_piers": [420.0, 680.0, 1060.0, 1320.0], "metal": "#3A3A3C",
		"pier": "#C9C5BC",
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#3A3A3C", "frame": "#B9B5AC", "door": 470.0, "inside": "goods", "transom": "none", "panes": 3},
			{"x0": 560.0, "x1": 1100.0, "sign": "#3A3A3C", "frame": "#B9B5AC", "door": 640.0, "inside": "goods", "transom": "none", "panes": 3},
			{"x0": 1100.0, "x1": 1650.0, "sign": "#3A3A3C", "frame": "#B9B5AC", "door": 1560.0, "inside": "clothes", "transom": "none", "panes": 3}], "basement": [],
	},
	{
		"name": "masson_2685", "kind": "commerce", "width": 900.0, "floors": 3,
		"bricks": ["#A8503E", "#B05A46", "#9A4636", "#B86450"], "mortar": "#D0C4B6", "parapet": "flat",
		"lintel": "#A8503E", "lintel_dark": "#8E3A2F", "lintel_style": "none", "window_style": "slider", "frame": "#1E1E20", "trim": "#2B2B2E", "trim_dark": "#1E1E20",
		"windows": [[60.0, 130.0], [520.0, 130.0], [710.0, 130.0]], "loggias": [[250.0, 470.0]], "upper_piers": [230.0, 490.0], "metal": "#3A3A3C",
		"pier": "#C9C5BC",
		"shops": [{"x0": 30.0, "x1": 420.0, "sign": "#3A3A3C", "frame": "#B9B5AC", "door": 120.0, "inside": "cafe", "transom": "none", "panes": 2},
			{"x0": 420.0, "x1": 870.0, "sign": "#B5121B", "frame": "#B9B5AC", "door": 800.0, "inside": "goods", "transom": "none", "panes": 3}], "basement": [],
	},
	# Across 3e: the old bank's side, buff stone (2703…).
	{
		"name": "masson_2703_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#C9B48E", "#BFAA84", "#D2BE98", "#B8A27C"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 3e (left) to 2e (right). Across 3e: the side of the metal-clad corner (2702…).
	{
		"name": "masson_2702_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#B9BDB6", "#AFB3AC", "#C3C7C0"], "mortar": "#9A9E98",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2690–2696, Place Dollar at 3e: grey brick on two floors, wide windows, its green-and-white sign (2692…, 2694…, 2690…).
	{
		"name": "masson_2692", "kind": "commerce", "width": 1100.0, "floors": 2,
		"bricks": ["#8E8A82", "#9A968E", "#86827A", "#A29E96"], "mortar": "#B9B5AC", "parapet": "flat",
		"lintel": "#B9B5AC", "lintel_dark": "#7E7A72", "lintel_style": "none", "window_style": "fixed", "frame": "#2B2B2E",
		"windows": [[80.0, 200.0], [330.0, 200.0], [580.0, 200.0], [830.0, 200.0]],
		"shops": [{"x0": 30.0, "x1": 1070.0, "sign": "#F2F0EA", "frame": "#2B2B2E", "door": 980.0, "awning": "#F2F0EA", "inside": "goods", "transom": "none", "panes": 6}], "basement": [],
	},
	# 2682–2686: red brick on three floors, "Les fleurs poussent encore" painted along the top, a ground floor of dark granite
	# round a restaurant's window, the flats' door at the right (2682…, 2668…).
	{
		"name": "masson_2682", "kind": "commerce", "width": 860.0, "floors": 3,
		"bricks": ["#A44A3A", "#B05444", "#984234", "#B85E4C"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[90.0, 110.0], [360.0, 110.0], [620.0, 110.0]],
		"pier": "#3A3836",
		"shops": [{"x0": 30.0, "x1": 640.0, "sign": "#2B2A2A", "frame": "#3A3836", "door": 560.0, "inside": "restaurant", "transom": "none"}],
		"res_doors": [740.0], "basement": [],
	},
	# 2666–2668: red-brown brick on three floors, white windows, Monteiro under its black sign over a band of blue tiles, the
	# white door to the flats (2666…, 2668…, 2658…).
	{
		"name": "masson_2666", "kind": "commerce", "width": 820.0, "floors": 3,
		"bricks": ["#9A5040", "#A65A48", "#8E4838", "#B0624E"], "mortar": "#CDBFB0", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 120.0], [340.0, 120.0], [590.0, 120.0]],
		"shops": [{"x0": 30.0, "x1": 600.0, "sign": "#1A1A1A", "frame": "#1E1E20", "door": 120.0, "inside": "restaurant", "kick": "tile", "tile": "#2E5E9E"}],
		"res_doors": [700.0], "basement": [],
	},
	# 2656–2658: charcoal brick on three floors, white windows under stone lintels, a dark shopfront (2656…, 2658…).
	{
		"name": "masson_2650", "kind": "commerce", "width": 700.0, "floors": 3,
		"bricks": ["#3E3A38", "#4A4542", "#34302E", "#55504C"], "mortar": "#8E8A84", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "windows": [[90.0, 110.0], [290.0, 110.0], [490.0, 110.0]],
		"shops": [{"x0": 30.0, "x1": 560.0, "sign": "#2B2B2E", "frame": "#2B2B2E", "door": 470.0, "inside": "goods", "front": "wood", "kick": "wood"}],
		"res_doors": [620.0], "basement": [],
	},
	# 2644–2648, at 2e: Pista, two floors, brown brick over a black shopfront with its long steel sign, a white door; its side on
	# 2e has the pink mural. (2e Avenue itself is the planted square here, not a lot on Masson: 2644…, 2648…, 2650….)
	{
		"name": "masson_2644", "kind": "commerce", "width": 620.0, "floors": 2,
		"bricks": ["#7A5040", "#865A48", "#6E4838", "#8E624E"], "mortar": "#B9AC9E", "parapet": "flat",
		"lintel_style": "none", "window_style": "slider", "frame": "#1E1E20", "ribbon_sill": true, "win_h": 100.0,
		"windows": [[60.0, 160.0], [240.0, 160.0], [420.0, 160.0]],
		"shops": [{"x0": 120.0, "x1": 590.0, "sign": "#C9CCCF", "frame": "#1A1A1A", "door": 520.0, "inside": "cafe", "transom": "none", "panes": 3}],
		"res_doors": [60.0], "basement": [],
	},
	# Across 2e: the next block's corner, its side.
	{
		"name": "masson_2636_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── Rue Masson, 1re to 2e Avenue ──
	# The north side, 1re (left) to 2e (right). Across 1re: the next block's corner, its side.
	{
		"name": "masson_2595_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F"], "mortar": "#CDBFB0",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 2601–2607, at 1re: pale grey brick on three floors, the dépanneur Bonsoir under its red sign (2605…).
	{
		"name": "masson_2605", "kind": "commerce", "width": 820.0, "floors": 3,
		"bricks": ["#ECEAE4", "#E4E2DC", "#F2F0EA", "#DEDCD6"], "mortar": "#C9C7C0", "parapet": "flat",
		"lintel": "#E8E6E0", "lintel_dark": "#9E9A92", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 130.0], [330.0, 130.0], [570.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 790.0, "sign": "#D8202A", "frame": "#B01A22", "door": 160.0, "inside": "goods", "transom": "none"}], "basement": [],
	},
	# 2609–2611: charcoal brick on three floors, black balconies, Domino's (2605…, 2613…).
	{
		"name": "masson_2611", "kind": "commerce", "width": 700.0, "floors": 3,
		"bricks": ["#3E3C3A", "#4A4846", "#363432", "#52504C"], "mortar": "#6A6864", "parapet": "flat",
		"lintel": "#5E5C58", "lintel_dark": "#2E2C2A", "lintel_style": "none", "window_style": "hung", "hung_frame": "#2B2B2E", "windows": [[90.0, 110.0], [450.0, 110.0]],
		"projecting": [[250.0, 420.0]],
		"shops": [{"x0": 30.0, "x1": 670.0, "sign": "#F2F0EA", "frame": "#2B2B2E", "door": 560.0, "inside": "restaurant", "wall": "#E8E4DA", "transom": "none"}], "basement": [],
	},
	# 2613–2617: white brick on three floors, the flower shop Le Jardin under its black sign (2613…).
	{
		"name": "masson_2615", "kind": "commerce", "width": 700.0, "floors": 3,
		"bricks": ["#E8E6E0", "#DEDCD6", "#F0EEE8", "#D6D4CE"], "mortar": "#C9C7C0", "parapet": "flat",
		"lintel": "#E8E6E0", "lintel_dark": "#9E9A92", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 130.0], [400.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 670.0, "sign": "#1A1A1A", "frame": "#1A1A1A", "door": 120.0, "inside": "florist", "front": "wood", "kick": "wood"}], "basement": [],
	},
	# 2619–2629: white brick on three floors (the same as Le Jardin de Mathilde's), Les Coeurs de Jupons under a black sign, then the
	# white pier with the flats' black door (2619…, 2629… and close-ups).
	{
		"name": "masson_2629", "kind": "commerce", "width": 900.0, "floors": 3,
		"bricks": ["#E2E0DA", "#D8D6D0", "#EAE8E2", "#D0CEC8"], "mortar": "#C9C7C0", "parapet": "flat",
		"lintel": "#E8E6E0", "lintel_dark": "#9E9A92", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA", "windows": [[90.0, 130.0], [380.0, 130.0], [640.0, 130.0]],
		"shops": [{"x0": 30.0, "x1": 640.0, "sign": "#1A1A1A", "frame": "#1A1A1A", "door": 470.0, "inside": "clothes", "kick": "brick"}],
		"res_doors": [760.0], "basement": [],
	},
	# 2631–2641, at 2e: red-brown brick on two floors, Yoga D.N.A., a phở restaurant and a juice bar (2631…, 2633…).
	{
		"name": "masson_2631", "kind": "commerce", "width": 1300.0, "floors": 2,
		"bricks": ["#8E4A3A", "#9A5242", "#844436", "#A0584A"], "mortar": "#B9AC9E", "parapet": "corbel",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "lintel_style": "arch", "window_style": "hung", "hung_frame": "#F2F0EA", "juliets": true, "windows": [[90.0, 120.0], [360.0, 120.0], [640.0, 120.0], [920.0, 120.0], [1150.0, 100.0]],
		"projecting": [[60.0, 260.0]],
		"shops": [{"x0": 30.0, "x1": 440.0, "sign": "#9C8EA8", "frame": "#2B2B2E", "door": 380.0, "inside": "salon", "wall": "#A898B4", "transom": "none"},
			{"x0": 440.0, "x1": 860.0, "sign": "#F2F0EA", "frame": "#2B2B2E", "door": 800.0, "inside": "restaurant", "front": "wood", "kick": "tile", "tile": "#8E2020"},
			{"x0": 860.0, "x1": 1270.0, "sign": "#F2F0EA", "frame": "#2B2B2E", "door": 1200.0, "inside": "cafe", "wall": "#E8F4DA", "transom": "none"}], "basement": [],
	},
	# Across 2e: the side of the commercial block there (2653…).
	{
		"name": "masson_2653_cote", "kind": "side_wall", "width": 560.0, "floors": 2,
		"bricks": ["#D8D6D0", "#CECCC6", "#E0DED8"], "mortar": "#B9B5AC",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# The south side, 2e (left) to 1re (right), from the front pictures (2618…, 2620…, 2632…, 2606…, 2610…, 2614…): the red brick
	# block on three floors right at the sidewalk, white balconies stacked at its 2e corner, TELUS, Koodo and two more shops
	# downstairs; a small parking lot; and at 1re the fire station (Caserne 29), buff brick, a ribbon of windows upstairs,
	# two glass garage doors and its office. (The old pictures were taken from 1re and 2e and showed the blocks' sides.)
	{
		"name": "masson_2636", "kind": "commerce", "width": 1500.0, "floors": 3,
		"bricks": ["#A8503E", "#B05A46", "#9A4636", "#B86450", "#A44A3A"], "mortar": "#D0C4B6", "parapet": "flat",
		"lintel": "#C9C3B6", "lintel_dark": "#8E887E", "lintel_style": "none", "window_style": "slider", "frame": "#F2F0EA",
		"windows": [[250.0, 110.0], [450.0, 110.0], [650.0, 110.0], [850.0, 110.0], [1050.0, 110.0], [1250.0, 110.0]],
		"projecting": [[30.0, 200.0]], "metal": "#F2F0EA", "metal_light": true,
		"shops": [{"x0": 30.0, "x1": 330.0, "sign": "#C8202A", "frame": "#E9E7E1", "door": 270.0, "inside": "goods"},
			{"x0": 330.0, "x1": 700.0, "sign": "#4B286D", "frame": "#E9E7E1", "door": 640.0, "inside": "goods", "wall": "#EEEAF4"},
			{"x0": 700.0, "x1": 1050.0, "sign": "#D6157A", "frame": "#E9E7E1", "door": 990.0, "inside": "goods", "wall": "#F6E8F0"},
			{"x0": 1050.0, "x1": 1470.0, "sign": "#E9E7E1", "frame": "#B9B5AC", "door": 1400.0, "inside": "goods"}], "basement": [],
	},
	{
		"name": "masson_2620", "kind": "masson_lot", "lot_style": "parking", "width": 420.0, "floors": 3, "halloween": false,
		"bricks": ["#A04A3A", "#AE5442", "#943F31", "#B85E4A"], "mortar": "#CDBFB0",
	},
	{
		"name": "masson_2606", "kind": "commerce", "width": 1100.0, "floors": 2, "halloween": false,
		"bricks": ["#CDB892", "#C4AE88", "#D6C29C", "#BCA67E", "#C9B48C"], "mortar": "#E2D8C6", "parapet": "flat",
		"lintel_style": "none", "window_style": "slider", "frame": "#2B2B2E", "ribbon_sill": true, "win_h": 90.0, "win_dy": 30.0,
		"windows": [[60.0, 110.0], [180.0, 110.0], [300.0, 110.0], [420.0, 110.0], [540.0, 110.0], [660.0, 110.0], [780.0, 110.0], [900.0, 110.0]],
		"belt": "#D8D2C4", "ground": "stone", "stone": "#CFC6B2", "ground_windows": [[760.0, 200.0]],
		"shops": [{"x0": 40.0, "x1": 370.0, "front": "garage"}, {"x0": 390.0, "x1": 720.0, "front": "garage", "truck": true}],
		"res_doors": [1010.0], "basement": [],
	},
	# Across 1re: the next block's corner, its side.
	{
		"name": "masson_2600_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#C8A27A", "#BC966E", "#D4AE86", "#B08A62"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# ── 6e Avenue between Masson (left) and Dandurand (right), the west side (reference/streetview/6e-avenue/5360… to 5590…) ──
	# The long side of Église Saint-Esprit along 6e, the tower at the Masson end, red basement doors in pairs (5360…, 5418…, 5436…).
	{
		"name": "six_sud_eglise", "kind": "church_side", "width": 2600.0, "floors": 4, "halloween": false,
		"stone": "#9E9A92", "tower_x": 60.0, "bay": 300.0, "doors": [760.0, 1360.0, 1960.0],
	},
	# Its parish hall, lower down the same wall: the beige door and the red one with its sign (5438…, 5444…, 5446…).
	{
		"name": "six_sud_salle", "kind": "church_side", "width": 900.0, "floors": 4, "halloween": false,
		"stone": "#A29E96", "bay": 300.0, "hall_doors": [260.0, 620.0],
	},
	# The modern apartment block behind its court (5462…, 5470…, 5486…, 5498…, 5502…).
	{
		"name": "six_sud_appartements", "kind": "apartments", "width": 1700.0, "floors": 4, "halloween": false,
		"volumes": [[30.0, 500.0, "#C9CCCE"], [530.0, 340.0, "#5E6266"], [870.0, 500.0, "#C9CCCE"], [1370.0, 300.0, "#5E6266"]],
		"entrance": 700.0, "bricks": ["#9A4636", "#A84E3C"], "mortar": "#C9BBAC",
	},
	# The schoolyard: lawn and the fenced basketball court (5522…).
	{
		"name": "six_sud_cour", "kind": "masson_lot", "lot_style": "court", "width": 1100.0, "floors": 3, "halloween": false,
		"bricks": ["#B4693E", "#A85E36", "#BE7446"], "mortar": "#D8C8B0",
	},
	# The school's gym: orange-brown brick, a beige band, slit windows, its entrance in a beige stone block (5524…, 5534…, 5544…).
	{
		"name": "six_sud_gymnase", "kind": "gym", "width": 1600.0, "floors": 3, "halloween": false,
		"bricks": ["#B4693E", "#A85E36", "#BE7446", "#9E5832"], "mortar": "#D8C8B0", "entrance": 1340.0,
	},
	# ── 6e Avenue between Dandurand (left) and Masson (right), the east side (reference/streetview/6e-avenue/5385… to 5595…) ──
	# Across Dandurand: the side of 5601, its salmon brick.
	{
		"name": "six_est_sud_5601_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#C98A64", "#BE805A", "#D2946E", "#B47650"], "mortar": "#E6DCCB",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 520.0,
	},
	# 5591–5595, at Dandurand: two floors of brick painted red, a white door, no outdoor stair (5591…, 5595…).
	{
		"name": "six_est_sud_5595",
		"bricks": ["#B84A3E", "#B04438", "#BE5044", "#A84236"], "mortar": "#C9A49A", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#E8E0D0", "lintel_dark": "#B9AE98",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "parapet": "flat", "windows": [[80.0, 140.0], [480.0, 140.0]],
		"door_cx": 340.0, "balcony": [250.0, 430.0], "porch": [260.0, 420.0], "stair": [], "fence": "", "basement": [], "halloween": false,
	},
	# 5581, the triplex in brown brick, black balconies, a straight stair down to the left (5581…).
	{
		"name": "six_est_sud_5581", "floors": 3,
		"bricks": ["#7E5440", "#8A5E4A", "#724A38", "#946852", "#7A503C"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "grid", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(180, 336), Vector2(133, 456), Vector2(87, 576), Vector2(40, 696)], "fence": "black", "basement": [460.0],
	},
	# 5573, dark brown brick, black balconies, the stair curling down (5573…).
	{
		"name": "six_est_sud_5573", "floors": 3,
		"bricks": ["#5E3E34", "#6A4A3E", "#54362E", "#744E40"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5565, grey stone, white balconies and stair, cedars in front (5565…, 5569…).
	{
		"name": "six_est_sud_5565", "floors": 3,
		"bricks": ["#A9A59D", "#B2AEA6", "#A09C94", "#B8B4AC"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "oval", "door_surround": "lintel", "metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "parapet": "corbel",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5561, brown brick, black balconies, the stair down to the right (5561…).
	{
		"name": "six_est_sud_5561", "floors": 3,
		"bricks": ["#7E5440", "#8A5E4A", "#724A38", "#946852", "#7A503C"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "double", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(320, 336), Vector2(380, 420), Vector2(370, 560), Vector2(330, 696)], "fence": "black", "basement": [460.0],
	},
	# 5551, red brick, white balconies (5549…, 5551…, 5555…).
	{
		"name": "six_est_sud_5551", "floors": 3,
		"bricks": ["#9E4A36", "#A85440", "#8E4030", "#B25C46", "#94462F"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "door_surround": "lintel", "metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(180, 336), Vector2(133, 456), Vector2(87, 576), Vector2(40, 696)], "fence": "black", "basement": [460.0],
	},
	# The lane between the plexes (5545…): asphalt, the one-way sign, a chain-link fence.
	{
		"name": "ruelle_six_est_sud", "kind": "lane_odd", "lane_style": "dandurand", "width": 560.0, "halloween": false,
	},
	# 5535, painted white, black balconies (5531…, 5535…, 5537…).
	{
		"name": "six_est_sud_5535", "floors": 3,
		"bricks": ["#ECEAE4", "#E4E1DA", "#F2F0EB", "#DEDAD2"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "grid", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "corbel",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5527, grey stone, dark balconies (5527…, 5529…).
	{
		"name": "six_est_sud_5527", "floors": 3,
		"bricks": ["#A9A59D", "#B2AEA6", "#A09C94", "#B8B4AC"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "oval", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(180, 336), Vector2(133, 456), Vector2(87, 576), Vector2(40, 696)], "fence": "black", "basement": [460.0],
	},
	# 5517, brown brick, white balconies (5517…, 5525…).
	{
		"name": "six_est_sud_5517", "floors": 3,
		"bricks": ["#7E5440", "#8A5E4A", "#724A38", "#946852", "#7A503C"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "door_surround": "lintel", "metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "parapet": "corbel",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5509, red brick, black balconies and their flower boxes (5509…, 5511…).
	{
		"name": "six_est_sud_5509", "floors": 3,
		"bricks": ["#9E4A36", "#A85440", "#8E4030", "#B25C46", "#94462F"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "double", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(320, 336), Vector2(380, 420), Vector2(370, 560), Vector2(330, 696)], "fence": "black", "basement": [460.0],
	},
	# 5501, red-brown brick, black balconies (5499…, 5501…, 5503…).
	{
		"name": "six_est_sud_5501", "floors": 3,
		"bricks": ["#9E4A36", "#A85440", "#8E4030", "#B25C46", "#94462F"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "grid", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5491, buff brick, white balconies (5491…, 5495…).
	{
		"name": "six_est_sud_5491", "floors": 3,
		"bricks": ["#C9AE88", "#BFA47E", "#D2B892", "#B49A74"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "panel", "door_surround": "lintel", "metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(180, 336), Vector2(133, 456), Vector2(87, 576), Vector2(40, 696)], "fence": "black", "basement": [460.0],
	},
	# 5471, cream brick, black balconies (5471…, 5481…).
	{
		"name": "six_est_sud_5471", "floors": 3,
		"bricks": ["#E2D6BE", "#D8CCB4", "#EADFC8", "#D0C4AC"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "oval", "door_surround": "lintel", "metal": "#1F1F1F", "tread": "#454545", "tread_dark": "#262626", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(170, 336), Vector2(70, 400), Vector2(40, 540), Vector2(100, 696)], "fence": "black", "basement": [460.0],
	},
	# 5459, red brick, white balconies (5459…).
	{
		"name": "six_est_sud_5459", "floors": 3,
		"bricks": ["#9E4A36", "#A85440", "#8E4030", "#B25C46", "#94462F"], "mortar": "#D0C4B6", "trim": "#F7F5F0", "trim_dark": "#C9C5BC", "lintel": "#D8D0C0", "lintel_dark": "#A89E8C",
		"door": "#F4F1EA", "door_dark": "#B9B2A5", "door_style": "double", "door_surround": "lintel", "metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88", "parapet": "flat",
		"windows": [[450.0, 150.0]], "door_cx": 290.0, "balcony": [60.0, 420.0], "porch": [200.0, 380.0],
		"stair": [Vector2(320, 336), Vector2(380, 420), Vector2(370, 560), Vector2(330, 696)], "fence": "black", "basement": [460.0],
	},
	# 5455, a newer duplex of the 1960s: beige brick, a garage under the house (5455…).
	{
		"name": "six_est_sud_5455", "kind": "modern", "width": 640.0, "door_x": 220.0,
		"bricks": ["#C9AE88", "#BFA47E", "#D2B892", "#B49A74"], "mortar": "#E6DCCB",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "step": "#B9B4AA", "step_dark": "#8E8A82", "metal": "#3A3A3A",
		"windows": [[150.0, 120.0], [400.0, 120.0]], "ground_window": [400.0, 110.0], "door_cx": 220.0, "basement": [],
	},
	# 5435, the same kind, pale brick with grey stone under it (5435…).
	{
		"name": "six_est_sud_5435", "kind": "modern", "width": 640.0, "door_x": 220.0,
		"bricks": ["#D8C8B0", "#CEBEA6", "#E0D0B8", "#C4B49C"], "mortar": "#ECE4D6",
		"lintel": "#E8E0D0", "lintel_dark": "#B9AE98", "step": "#B9B4AA", "step_dark": "#8E8A82", "metal": "#F2F0EA",
		"windows": [[150.0, 120.0], [400.0, 120.0]], "ground_window": [400.0, 110.0], "door_cx": 220.0, "basement": [],
	},
	# The parking lot near Masson (5423…), the cars left out.
	{
		"name": "six_est_sud_stationnement", "kind": "masson_lot", "lot_style": "parking", "width": 700.0, "floors": 3, "halloween": false,
		"bricks": ["#9A4636", "#A84E3C", "#8E3E30", "#B05844"], "mortar": "#C9BBAC",
	},
	# The little square by Masson with its bicycle shelter (5415…, 5419…).
	{
		"name": "six_est_sud_place", "kind": "masson_lot", "lot_style": "plaza", "width": 600.0, "floors": 3, "halloween": false,
		"bricks": ["#9A4636", "#A84E3C", "#8E3E30", "#B05844"], "mortar": "#C9BBAC",
	},
	# At Masson: the side of 2901, red brick over its grey stone ground floor, the green door of the greengrocer's (5403…, 5411…).
	{
		"name": "six_est_sud_2901_cote", "kind": "side_wall", "width": 640.0, "floors": 3, "lower_stone": true,
		"bricks": ["#9A4636", "#A84E3C", "#8E3E30", "#B05844", "#94422F"], "mortar": "#CFC2B4",
		"parapet": "flat", "windows": [[110.0, 100.0], [380.0, 100.0]], "basement": [], "downspout": 40.0,
	},
	# Across 5e: the side of Dollarama's building, buff brick (2840…).
	{
		"name": "masson_2840_cote", "kind": "side_wall", "width": 560.0, "floors": 3,
		"bricks": ["#D6B98C", "#CDB082", "#DEC296", "#C4A678", "#D2B488"], "mortar": "#EDE3D2",
		"parapet": "flat", "windows": [[110.0, 100.0], [330.0, 100.0]], "basement": [], "downspout": 40.0,
	},
]

var k: Dictionary
var out := PackedStringArray()
var rng := RandomNumberGenerator.new()
var X1 := 670.0
var oy := 0.0
var base_y := BASE
var ground_y := GROUND
var windows := {}
var doors := {}
var season := "autumn"
## The Halloween-night pass: everything a house draws AFTER its windows (its doors, balconies, porch, outdoor
## stair, railings, fence and garden) on its own, written to `art/decor/over/`. On Halloween night the game lays
## that layer back over the warm light it paints in the panes, so the stairs and the railings keep passing in
## front of the lit windows instead of being covered by them.
var night := false
## Where the facade's "over" layer starts in `out` (set right after the last window is drawn).
var split := 0


func _init() -> void:
	var configs: Array = HOUSES.duplicate()
	for i in VARIANTS:
		configs.append(_variant(i))
	for s in ["autumn", "spring", "summer", "winter"]:
		season = s
		if s != "autumn":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/decor/" + s))
		_generate(configs)
	# And once more in autumn, keeping only what each house draws in front of its windows, for Halloween night.
	season = "autumn"
	night = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/decor/over"))
	_generate(configs)
	night = false
	FileAccess.open("res://art/decor/windows.json", FileAccess.WRITE).store_string(JSON.stringify(windows, "\t"))
	FileAccess.open("res://art/decor/doors.json", FileAccess.WRITE).store_string(JSON.stringify(doors, "\t"))
	quit()


func _generate(configs: Array) -> void:
	for cfg in configs:
		k = DEFAULTS.duplicate(true)
		k.merge(cfg, true)
		X1 = k.width - 30.0
		oy = (int(k.floors) - 2) * FLOOR_H
		base_y = BASE + oy
		ground_y = GROUND + oy
		rng.seed = hash(k.name)
		if k.kind == "plex" or k.has("door_x"):
			doors[k.name] = k.get("door_x", k.door_cx)
		out = PackedStringArray()
		split = 0
		_clips = 0
		_svg()
		if night:
			# Only what is drawn in front of the windows, on its own transparent sheet.
			if split <= 0:
				continue
			var over := PackedStringArray([out[0], out[1]])
			over.append_array(out.slice(split))
			FileAccess.open("res://art/decor/over/%s.svg" % k.name, FileAccess.WRITE).store_string("\n".join(over))
			continue
		var path := "res://art/decor/%s.svg" % k.name if season == "autumn" else "res://art/decor/%s/%s.svg" % [season, k.name]
		FileAccess.open(path, FileAccess.WRITE).store_string("\n".join(out))


func _variant(i: int) -> Dictionary:
	rng.seed = 1000 + i
	var p := rng.randi_range(0, BRICK_PALETTES.size() - 1)
	var d: Array = DOORS[rng.randi_range(0, DOORS.size() - 1)]
	var cfg := {
		"name": "plex_%02d" % (i + 1),
		"floors": 3 if rng.randf() < 0.4 else 2,
		"bricks": BRICK_PALETTES[p], "mortar": MORTARS[p],
		"door": d[0], "door_dark": d[1],
		"door_cx": 278.0, "windows": [[70.0, 110.0], [470.0, 110.0]],
		"balcony": [130.0, 420.0], "porch": [150.0, 400.0],
		"lintel_style": ["plain", "plain", "ears", "arch"][rng.randi_range(0, 3)],
		"keystone": rng.randf() < 0.3,
		"flower_boxes": rng.randf() < 0.35, "curtains": rng.randf() < 0.5,
		"fence": ["black", "white", ""][rng.randi_range(0, 2)],
		"lower_stone": rng.randf() < 0.15, "columns": rng.randf() < 0.4,
		"awning": "#7C8186" if rng.randf() < 0.3 else "",
		"pediment": rng.randf() < 0.3,
		"halloween": rng.randf() < 0.75,
	}
	if rng.randf() < 0.3:
		var crest := rng.randf() < 0.4
		cfg.merge({"parapet": "flat", "crest": crest, "top": 40.0 if crest else 0.0})
	if rng.randf() < 0.4:
		cfg.merge({"metal": "#F5F5F2", "metal_light": true, "tread": "#C8C8C4", "tread_dark": "#8C8C88",
			"cornice": "#E9E6DF", "cornice_dark": "#B5B0A6"})
	var stair := []
	for v in STAIR_SHAPES[rng.randi_range(0, STAIR_SHAPES.size() - 1)]:
		stair.append(Vector2(450.0 + v.x, v.y))
	cfg.stair = stair
	if rng.randf() < 0.5:
		_mirror(cfg)
	# Drawn last, so the rest of each house stays as it was (reference/rue/portes.jpg, reference/rue/escaliers.jpg).
	cfg.door_style = DOOR_STYLES[rng.randi_range(0, DOOR_STYLES.size() - 1)]
	cfg.door_surround = ["lintel", "cornice", "pediment", "arch", "cornice"][rng.randi_range(0, 4)]
	cfg.ornate = rng.randf() < 0.5
	cfg.stair_kind = "landing" if rng.randf() < 0.3 else "curve"
	cfg.sidelights = rng.randf() < 0.3
	cfg.lamp_style = ["lantern", "globe", "coach", "cylinder", "box", "single", "left", "globe"][rng.randi_range(0, 7)]
	return cfg


func _mirror(cfg: Dictionary) -> void:
	var w := 700.0
	cfg.door_cx = w - cfg.door_cx
	var wins := []
	for win in cfg.windows:
		wins.append([w - win[0] - win[1], win[1]])
	cfg.windows = wins
	cfg.balcony = [w - cfg.balcony[1], w - cfg.balcony[0]]
	cfg.porch = [w - cfg.porch[1], w - cfg.porch[0]]
	var stair := []
	for v in cfg.stair:
		stair.append(Vector2(w - v.x, v.y))
	cfg.stair = stair
	cfg.basement = [w - 96.0 - 480.0]


func _fb(f: int) -> float:
	return PORCH_FLOOR + oy - FLOOR_H * f


func _win_y(f: int) -> float:
	return _fb(f) - 190.0


func _door_top(f: int) -> float:
	return _fb(f) - 208.0


func _top() -> float:
	return k.top if k.top > 0.0 else _fb(int(k.floors) - 1) - 260.0


func _svg() -> void:
	var w: float = k.width
	out.append('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">' % [_n(w), _n(ground_y), _n(w), _n(ground_y)])
	out.append('<defs>'
		+ '<linearGradient id="glass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C4E0EC"/><stop offset="1" stop-color="#557A90"/></linearGradient>'
		+ '<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.1"/><stop offset="1" stop-color="#000000" stop-opacity="0.16"/></linearGradient>'
		+ '<radialGradient id="glow"><stop offset="0" stop-color="#FFE9A8" stop-opacity="0.75"/><stop offset="1" stop-color="#FFE9A8" stop-opacity="0"/></radialGradient>'
		+ '<linearGradient id="warm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7B5"/><stop offset="1" stop-color="#D98E4A"/></linearGradient>'
		+ '<linearGradient id="drop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A1408" stop-opacity="0.3"/><stop offset="1" stop-color="#2A1408" stop-opacity="0"/></linearGradient>'
		+ '<linearGradient id="sun" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFE6B8" stop-opacity="0.14"/><stop offset="0.5" stop-color="#FFE6B8" stop-opacity="0"/><stop offset="1" stop-color="#1A0C14" stop-opacity="0.12"/></linearGradient>'
		+ '<radialGradient id="pumpkin_glow"><stop offset="0" stop-color="#FFB347" stop-opacity="0.6"/><stop offset="1" stop-color="#FFB347" stop-opacity="0"/></radialGradient>'
		+ '</defs>')
	match k.kind:
		"ruelle":
			_ruelle()
		"ruelle_verte":
			_ruelle_verte()
		"depanneur_side":
			_depanneur_side()
		"depanneur_front":
			_depanneur_front()
		"corner_holt":
			_corner_holt()
		"ohbon":
			_ohbon()
		"garages":
			_garages()
		"modern":
			_modern()
		"school":
			_school()
		"gables":
			_gables()
		"bungalow":
			_bungalow()
		"corner_yard":
			_corner_yard()
		"lane_odd":
			_lane_odd()
		"commerce":
			_commerce()
		"bank":
			_bank()
		"church":
			_church()
		"presbytere":
			_building()
			_presbytere()
		"masson_lot":
			_masson_lot()
		"church_side":
			_church_side()
		"apartments":
			_apartments()
		"gym":
			_gym()
		"mural_wall":
			_mural_wall()
		_:
			_building()
	out.append('</svg>')


func _building() -> void:
	var top := _top()
	var floors: int = k.floors
	if k.lower_stone:
		_bricks(top, _fb(1) + 31.0)
		_stones(_fb(1) + 39.0, base_y)
		_rect(X0, _fb(1) + 25.0, X1 - X0, 14, k.lintel, _stroke(k.lintel_dark, 1.5))
	else:
		_bricks(top, base_y)
	_wall_shading(top)
	_foundation()
	for px: float in k.get("pilasters", []):
		_rect(px - 13, top, 26, base_y - top, k.lintel, _stroke(k.lintel_dark, 1.5))
		_rect(px - 13, top, 5, base_y - top, "#FFFFFF", 'opacity="0.3"')
		_rect(px + 8, top, 5, base_y - top, "#000000", 'opacity="0.12"')
	if k.downspout >= 0.0:
		_downspout(k.downspout, top)
	if k.get("downspout2", -1.0) >= 0.0:
		_downspout(k.downspout2, top)
	match k.parapet:
		"flat":
			_flat_parapet(top)
		"mansard":
			_mansard(top)
		"corbel":
			_corbel_parapet(top)
		_:
			_cornice(top)
	if k.crest:
		_crest(k.door_cx, top + 6.0)
	var first_floor := 1 if k.kind == "shop" else 0
	for f in range(first_floor, floors):
		for w in k.windows:
			_window(w[0], _win_y(f), w[1], 160.0)
	# Everything from here on (doors, balconies, porch, stair, railings, fence, garden) is the house's "over" layer.
	split = out.size()
	match k.kind:
		"shop":
			_storefront()
		"plex":
			_plex_front()


# Vertical falloff, plus the low sun warming the left of the facade and the right falling into shade.
func _wall_shading(top: float) -> void:
	_rect(X0, top, X1 - X0, base_y - top, "url(#shade)")
	_rect(X0, top, X1 - X0, base_y - top, "url(#sun)")
	_rect(X0, top, 3, base_y - top, "#000000", 'opacity="0.25"')
	_rect(X1 - 3, top, 3, base_y - top, "#000000", 'opacity="0.25"')


func _plex_front() -> void:
	var floors: int = k.floors
	var cx: float = k.door_cx
	for f: int in k.get("door_floors", range(floors)):
		_door(cx, _door_top(f), _fb(f))
	if k.get("door_awning", "") != "":
		_stripe_awning(cx - 74, cx + 74, _door_top(0) - 46.0, k.door_awning)
	# (Charlotte's doors carry their own little plates: see _wood_door.)
	if k.number != "" and k.get("door_style", "") != "wood_glass":
		_plaque(cx, _door_top(0) + 14.0, k.number)
	if k.get("mailbox", false):
		var mx: float = cx - 78.0
		var my := _door_top(0) + 92.0
		_rect(mx - 17, my, 34, 21, "#1B2233", 'rx="2" ' + _stroke("#0E1220", 1))
		_rect(mx + 4, my + 7, 6, 6, "#F2F2F2")
		_rect(mx + 6, my + 9, 2, 2, "#D9342B")
		for lx in [mx - 8.0, mx + 8.0]:
			_rect(lx, my + 21, 2.5, 9, "#1B2233")
	var b: Array = k.balcony
	# Most of the plexes across 6e Avenue have a balcony per flat rather than one gallery (`balconies`: one span each).
	var spans: Array = k.get("balconies", [b])
	if k.awning != "":
		_awning(b[0], b[1], _door_top(floors - 1) - 26.0, _fb(floors - 1) - RAIL_H)
	if k.get("canopy", "") != "":
		for span: Array in spans:
			_alu_canopy(span[0], span[1], _door_top(floors - 1) - 56.0)
	var slab_h: float = k.get("slab_h", 16.0)
	for f in range(floors - 1, 0, -1):
		if not f in k.get("balcony_floors", range(1, floors)):
			continue
		if k.get("stripe_awnings", false):
			for span: Array in spans:
				_stripe_awning(span[0], span[1], _door_top(f) - 30.0)
		for span: Array in spans:
			_rect(span[0], _fb(f) + 16, span[1] - span[0], 14, "#000000", 'opacity="0.15"')
		if k.columns:
			_column(b[0] + 4, 1.0, _fb(f) + 16, _fb(f - 1))
			_column(b[1] - 11, -1.0, _fb(f) + 16, _fb(f - 1))
		if k.get("iron_rail", false):
			_iron_balcony(b[0], b[1], k.rail_up[0], k.rail_up[1], _fb(f), slab_h, [], cx, -1.0)
			for px: float in k.get("iron_posts", []):
				_iron_post(px, _fb(f) + slab_h + 8.0, _fb(f - 1))
				_rect(px + 10.0, _fb(0) + slab_h, 5, ground_y - _fb(0) - slab_h - 30.0, "#9AA0A6", _stroke("#6E7277", 1))
		else:
			for span: Array in spans:
				_balcony(span[0], span[1], _fb(f), [])
	var p: Array = k.porch
	if k.halloween:
		_cobweb(p[0] + 4.0, _fb(1) + 16.0, 1.0)
		_cobweb(p[1] - 4.0, _fb(1) + 16.0, -1.0)
		for gx in [b[0] + 30.0, b[1] - 40.0]:
			if rng.randf() < 0.6:
				_ghost(gx, _fb(1) + 30.0)
		_string_lights(b[0], b[1], _fb(1) - RAIL_H)
	if k.get("steps_side", "") == "left":
		# The porch is up on posts and its steps go down at the left end, between curled iron rails.
		_iron_balcony(p[0], p[1], k.rail_down[0], k.rail_down[1], _fb(0), slab_h, [[p[0] - 6.0, p[0] + 34.0]], cx, 1.0)
		if season == "winter":
			_vintage_lights(p[0] + 34.0, k.rail_down[1], _fb(0) - 62.0)
			var first := 0
			for px: float in k.get("iron_posts", []):
				_vintage_post(px, _fb(1) + slab_h + 10.0, _fb(0) - 62.0, first)
				first += 2
		_side_steps(p[0] + 8.0)
	else:
		_balcony(p[0], p[1], _fb(0), [[cx - 54, cx + 54]])
		_front_steps(cx)
	if k.halloween:
		_pumpkin(cx - 76, base_y + 2.0, 1.0, true)
		_pumpkin(cx + 78, base_y + 2.0, 0.75, rng.randf() < 0.5)
		_mums(cx + 96, ground_y)
	var s: Array = k.stair
	if s.is_empty():
		# No outdoor stair (the upper flats go in by an inside one): only the front door's gap in the fence.
		var inside := [[cx - 66, cx + 66]]
		_garden(inside)
		_fence(inside)
		return
	var p3 := Vector2(s[3].x, s[3].y + oy)
	var p0 := Vector2(s[0].x, _fb(1) + 6.0)
	if k.get("stair_kind", "curve") == "landing":
		# An L: a straight flight down to a landing on iron posts, then back the other way to the sidewalk.
		var d := signf(p3.x - p0.x)
		var land := Vector2(p0.x + d * 118.0, lerpf(p0.y, ground_y, 0.52))
		p3 = Vector2(land.x - d * 96.0, ground_y)
		var f1 := land - Vector2(d * 30.0, 0)
		_stairs(p0, p0.lerp(f1, 1.0 / 3.0), p0.lerp(f1, 2.0 / 3.0), f1)
		_landing(land)
		var f2 := land - Vector2(d * 30.0, -4.0)
		_stairs(f2, f2.lerp(p3, 1.0 / 3.0), f2.lerp(p3, 2.0 / 3.0), p3)
	else:
		_stairs(p0, s[1] + Vector2(0, oy), s[2] + Vector2(0, oy), p3)
	var gaps := [[cx - 66, cx + 66], [p3.x - 42, p3.x + 42]]
	if k.get("steps_side", "") == "left":
		gaps = [[p[0] - 90.0, p[0] + 5.0], [p3.x - 42, p3.x + 42]]
	gaps.sort_custom(func(a, c): return a[0] < c[0])
	_garden(gaps)
	_fence(gaps)


# Steps down at the left end of a raised porch: treads, with a curled wrought-iron rail on the outer side.
func _side_steps(right: float) -> void:
	var count := 4
	var top := _fb(0) + 16.0
	var run := 108.0
	var sh := (ground_y - top) / count
	for i in count:
		var x := right - run * float(i + 1) / count
		_rect(x, top + i * sh, right - x + 6.0, sh, k.step, _stroke(k.step_dark, 1.5))
		_rect(x, top + i * sh, right - x + 6.0, 3, "#FFFFFF", 'opacity="0.25"')
	# The two curved rails, one each side of the steps, their bars following the curve, a heart on each, a curl at the foot.
	for rail in [[Vector2(right - 12.0, _fb(0) - 62.0), Vector2(right - run - 14.0, ground_y - 54.0)], [Vector2(right + 30.0, _fb(0) - 62.0), Vector2(right - run + 44.0, ground_y - 54.0)]]:
		var a: Vector2 = rail[0]
		var c: Vector2 = rail[1]
		var bend := Vector2(lerpf(a.x, c.x, 0.72), lerpf(a.y, c.y, 0.2))
		var pts: Array[Vector2] = []
		for i in 13:
			var t := i / 12.0
			pts.append(a.lerp(bend, t).lerp(bend.lerp(c, t), t))
		_line(_polyline(pts, Vector2.ZERO), 4.0)
		for i in range(1, 12, 2):
			_rect(pts[i].x - 1, pts[i].y, 2, minf(ground_y - pts[i].y - 2.0, 54.0), k.metal)
		_iron_heart(pts[5].x, pts[5].y + 24.0, 8.0)
		_path("M%s %s c-10 0 -12 14 -4 16 c6 1 6 -7 1 -6" % [_n(c.x), _n(c.y)], "none", _stroke(k.metal, 3))


func _bricks(y0: float, y1: float) -> void:
	_rect(X0, y0, X1 - X0, y1 - y0, k.mortar)
	var row := 0
	var y := y0
	while y < y1:
		var h := minf(11.0, y1 - y)
		var x := X0 - (18.0 if row % 2 == 1 else 0.0)
		while x < X1:
			var bx := maxf(x, X0)
			var bw := minf(x + 34.0, X1) - bx
			if bw > 1.0:
				_rect(bx, y, bw, h, _pick(k.bricks))
			x += 36.0
		y += 13.0
		row += 1


func _stones(y0: float, y1: float) -> void:
	_rect(X0, y0, X1 - X0, y1 - y0, k.stone_mortar)
	var y := y0
	while y < y1:
		var h := minf(23.0, y1 - y)
		var x := X0 - rng.randf_range(0.0, 50.0)
		while x < X1:
			var w := rng.randf_range(55.0, 95.0)
			var bx := maxf(x, X0)
			var bw := minf(x + w - 3.0, X1) - bx
			if bw > 1.0:
				_rect(bx, y, bw, h, _pick(k.stones))
			x += w
		y += 26.0


func _foundation() -> void:
	_rect(X0, base_y, X1 - X0, ground_y - base_y, "#A39D93")
	_rect(X0, base_y, X1 - X0, 5, "#BDB7AD")
	for y in [base_y + 26.0, base_y + 54.0]:
		_rect(X0, y, X1 - X0, 1.5, "#000000", 'opacity="0.08"')
	for x in k.basement:
		_rect(x, base_y + 22, 96, 44, k.trim, _stroke(k.trim_dark, 2))
		if k.get("window_style", "") == "hung":
			_rect(x, base_y + 22, 96, 44, "#1E1A18", _stroke("#0F0C0A", 2))
			_rect(x + 6, base_y + 28, 84, 32, "url(#glass)")
			continue
		_rect(x + 6, base_y + 28, 84, 32, "url(#glass)")
		_rect(x + 46, base_y + 28, 4, 32, k.trim)


func _downspout(x: float, top: float) -> void:
	var st := _stroke("#B9B7B0", 1.5)
	_rect(x, top - 30, 9, ground_y - top + 24, "#ECEBE6", st)
	_rect(x - 3, top - 18, 15, 8, "#ECEBE6", st)
	_rect(x - 6, ground_y - 10, 20, 8, "#ECEBE6", st)


func _cornice(top: float) -> void:
	out.append('<g transform="translate(0 %s)">' % _n(top - 70.0))
	if k.pediment:
		var cx := (X0 + X1) / 2.0
		_path("M%s 22 V14 Q%s 2 %s 14 V22 Z" % [_n(cx - 80), _n(cx), _n(cx + 80)], k.cornice, _stroke(k.cornice_dark, 2))
		_circle(cx, 14, 5, k.cornice_dark, 'opacity="0.5"')
	_rect(X0, 48, X1 - X0, 24, k.cornice)
	_rect(X0, 72, X1 - X0, 10, "#000000", 'opacity="0.18"')
	_rect(X0, 82, X1 - X0, 46, "url(#drop)")
	var x := X0 + 6.0
	while x < X1 - 10.0:
		_rect(x, 40, 8, 8, k.cornice_dark)
		x += 14.0
	_rect(X0, 22, X1 - X0, 12, k.cornice, _stroke(k.cornice_dark, 2))
	_rect(X0, 34, X1 - X0, 6, k.cornice_dark)
	var count := 8
	var gap := (X1 - X0 - 34.0) / count
	for i in count:
		_rect(X0 + 30.0 + i * gap, 54, gap - 26.0, 12, "none", _stroke(k.cornice_dark, 1.5))
	for i in count + 1:
		_path("M%s 40 h14 v8 q0 22 -10 28 q-4 -10 -4 -36 z" % _n(X0 + 10.0 + i * gap), k.cornice, _stroke(k.cornice_dark, 1.5))
	_snow(X0, X1 - X0, 22)
	out.append('</g>')


func _window(x: float, y: float, w: float, h: float) -> void:
	match k.lintel_style:
		"ears":
			_rect(x - 8, y - 18, w + 16, 18, k.lintel, _stroke(k.lintel_dark, 1.5))
			_rect(x - 8, y - 18, w + 16, 3, "#FFFFFF", 'opacity="0.3"')
			for ex in [x - 22.0, x + w]:
				_rect(ex, y - 23, 22, 27, k.lintel, _stroke(k.lintel_dark, 1.5))
				_rect(ex + 3, y - 20, 16, 21, "none", _stroke(k.lintel_dark, 1))
				_rosette(ex + 11, y - 9.5)
		"fleur":
			_fleur_lintel(x, y, w)
		"arch":
			var d := "M%s %s Q%s %s %s %s" % [_n(x - 6), _n(y + 2), _n(x + w / 2), _n(y - 34), _n(x + w + 6), _n(y + 2)]
			_path(d, "none", _stroke(k.lintel_dark, 17))
			_path(d, "none", _stroke(k.lintel, 13) + ' stroke-dasharray="7 2"')
		"none":
			pass
		_:
			_rect(x - 12, y - 20, w + 24, 20, k.lintel, _stroke(k.lintel_dark, 1.5))
	if k.keystone:
		var ky := y - 38.0 if k.lintel_style == "arch" else y - 24.0
		_path("M%s %s h20 l-3 26 h-14 z" % [_n(x + w / 2 - 10), _n(ky)], k.lintel, _stroke(k.lintel_dark, 1.5))
	match k.get("window_style", ""):
		"hung":
			_hung_window(x, y, w, h)
			return
		"casement":
			_casement(x, y, w, h)
			return
		"slider", "fixed":
			_modern_window(x, y, w, h, k.window_style == "slider")
			return
	_rect(x - 3, y - 3, w + 6, h + 6, k.trim_dark)
	_rect(x, y, w, h, k.trim)
	var lit := rng.randf() < 0.22
	_rect(x + 8, y + 8, w - 16, h - 16, "url(#warm)" if lit else "url(#glass)")
	if season == "autumn" and not night:
		if not windows.has(k.name):
			windows[k.name] = []
		windows[k.name].append({"pane": [x + 8, y + 8, w - 16, h - 16], "bar_y": y + h * 0.34, "trim": k.trim,
			"lit": lit, "flower_box": k.flower_boxes})
	if k.halloween and rng.randf() < 0.18 and season == "autumn":
		for b in 2:
			_bat(x + w * (0.35 + b * 0.3), y + h * (0.3 + b * 0.2), 0.8)
	if k.curtains:
		var gh := h - 16
		_path("M%s %s h22 q-8 %s 2 %s h-24 z" % [_n(x + 8), _n(y + 8), _n(gh * 0.5), _n(gh)], "#F3E9D8", 'opacity="0.92"')
		_path("M%s %s h-22 q8 %s -2 %s h24 z" % [_n(x + w - 8), _n(y + 8), _n(gh * 0.5), _n(gh)], "#F3E9D8", 'opacity="0.92"')
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [
		_n(x + w * 0.55), _n(y + 8), _n(x + w * 0.55 + 16), _n(y + 8),
		_n(x + 24), _n(y + h * 0.55), _n(x + 8), _n(y + h * 0.55)], "#FFFFFF", 'opacity="0.22"')
	var ty := y + h * 0.34
	if k.get("muntins", "") == "x" and y < _win_y(0) - 20.0:
		var parts := PackedStringArray()
		var cell := (w - 16.0) / 3.0
		for i in 3:
			var gx := x + 8.0 + i * cell
			parts.append("M%s %s L%s %s M%s %s L%s %s" % [_n(gx), _n(y + 8), _n(gx + cell), _n(ty), _n(gx + cell), _n(y + 8), _n(gx), _n(ty)])
		_path(" ".join(parts), "none", _stroke(k.trim, 3.5))
	_rect(x + 4, ty - 3, w - 8, 6, k.trim)
	_rect(x + w / 2 - 3, ty, 6, y + h - ty - 4, k.trim)
	# Recess: the lintel and the left jamb shade the glass.
	_rect(x + 8, y + 8, w - 16, 10, "url(#drop)")
	_rect(x + 8, y + 8, 7, h - 16, "#000000", 'opacity="0.14"')
	_rect(x - 10, y + h + 3, w + 20, 9, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(x - 6, y + h + 12, w + 12, 5, "#000000", 'opacity="0.15"')
	if k.flower_boxes:
		var fx := x + 12.0
		while fx < x + w - 10:
			var bloom := _pick(["#FF7BA3", "#FFD23F", "#FFFFFF", "#C084FC"])
			if season == "winter":
				_circle(fx, y + h - 12, 6, "#3E5A3A")
				_circle(fx, y + h - 15, 4, "#F7F9FB")
			else:
				_circle(fx, y + h - 14, 7, "#5FAE4F")
				_circle(fx + 2, y + h - 18, 4, "#E04F5F" if season == "summer" and int(fx) % 2 == 0 else bloom)
			fx += 13.0
		_rect(x + 4, y + h - 12, w - 8, 15, "#7A5236", _stroke("#5A3B26", 1.5))
	_snow(x - 10, w + 20, y + h + 3)


# A double-hung window (reference/maison_charlotte/): a black frame, one meeting rail and no upright, the same glass as the other
# houses', a thick stone sill.
func _hung_window(x: float, y: float, w: float, h: float) -> void:
	var FRAME: String = k.get("hung_frame", "#1E1A18")
	_rect(x - 2, y - 2, w + 4, h + 4, "#" + Color(FRAME).darkened(0.45).to_html(false))
	_rect(x, y, w, h, FRAME)
	var pane_h := (h - 16.0) * 0.47
	var rail_y := y + 8.0 + pane_h
	var lower_y := rail_y + 6.0
	var lower_h := y + h - 8.0 - lower_y
	var lit := rng.randf() < 0.22
	var glass := "url(#warm)" if lit else "url(#glass)"
	_rect(x + 8, y + 8, w - 16, pane_h, glass)
	_rect(x + 8, lower_y, w - 16, lower_h, glass)
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x + w * 0.55), _n(y + 8), _n(x + w * 0.55 + 16), _n(y + 8), _n(x + 24), _n(y + 8 + pane_h), _n(x + 8), _n(y + 8 + pane_h)], "#FFFFFF", 'opacity="0.22"')
	_rect(x + 8, y + 8, w - 16, 10, "url(#drop)")
	_rect(x + 8, y + 8, 7, h - 16, "#000000", 'opacity="0.14"')
	if season == "autumn" and not night:
		if not windows.has(k.name):
			windows[k.name] = []
		windows[k.name].append({"pane": [x + 8, y + 8, w - 16, h - 16], "bar_y": rail_y, "trim": FRAME, "lit": lit, "flower_box": false, "no_cat": y > _fb(1)})
	_rect(x - 14, y + h + 2, w + 28, 15, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(x - 14, y + h + 2, w + 28, 3, "#FFFFFF", 'opacity="0.25"')
	_rect(x - 10, y + h + 17, w + 20, 5, "#000000", 'opacity="0.16"')
	_snow(x - 14, w + 28, y + h + 2)


# The railing on the photos: thin bars wide apart, a hand rail with a second one just under it, a low rail above the slab, a pair of
# iron scrolls standing on the rail over the door, close-set bars where it turns back to the wall (`dense`: its side, -1 or 1).
# Under it the thick white slab with a stone top and a cream soffit.
func _iron_balcony(sx0: float, sx1: float, x0: float, x1: float, floor_y: float, slab_h: float, gaps: Array, crest_x: float, dense: float) -> void:
	var top := floor_y - 62.0
	for seg in _segments(x0, x1, gaps):
		var a: float = seg[0]
		var b: float = seg[1]
		var x := a + 6.0
		while x < b - 4.0:
			_rect(x, top, 2, floor_y - 8.0 - top, k.metal)
			var close: bool = (dense > 0.0 and x > x1 - 30.0) or (dense < 0.0 and x < x0 + 30.0)
			x += 5.0 if close else 12.0
		_rect(a, top - 1, b - a, 3.5, k.metal)
		_rect(a, top + 8, b - a, 2, k.metal)
		_rect(a, floor_y - 10, b - a, 2.5, k.metal)
		for px in [a, b - 3.5]:
			_rect(px, top - 3, 3.5, floor_y - top + 3, k.metal)
		_snow(a, b - a, top - 1)
	if crest_x >= 0.0:
		for side in [-1.0, 1.0]:
			_path("M%s %s c%s -1 %s -4 %s -10 c%s -5 %s -6 %s -2 c%s 2 %s 4 %s 2" % [_n(crest_x), _n(top - 1), _n(side * 8), _n(side * 16), _n(side * 20), _n(side * 2), _n(side * -7), _n(side * -7), _n(side * 1), _n(side * 4), _n(side * 4)], "none", _stroke(k.metal, 2) + ' stroke-linecap="round"')
	# Hearts low on the railing, one each side of the door, downstairs.
	if dense > 0.0:
		for side in [-1.0, 1.0]:
			_iron_heart(crest_x + side * 34.0, floor_y - 21.0, 9.0)
	_rect(sx0 - 6, floor_y, sx1 - sx0 + 12, slab_h, k.slab, _stroke(k.slab_dark, 1.5))
	_rect(sx0 - 6, floor_y, sx1 - sx0 + 12, 5, "#B9B5AC")
	_rect(sx0 - 6, floor_y + slab_h - 4, sx1 - sx0 + 12, 4, k.slab_dark)
	_rect(sx0 + 4, floor_y + slab_h, sx1 - sx0 - 8, 8, "#D9D2C2")
	_rect(sx0 + 4, floor_y + slab_h + 8, sx1 - sx0 - 8, 22, "url(#drop)")
	_snow(sx0 - 6, sx1 - sx0 + 12, floor_y - 2)


# Winter on Charlotte's porch (5672): an old string of big painted bulbs, a dark green wire in swags along the hand rail, the bulbs
# hanging from it in turn red, green, blue, orange and white, each with its socket, a shine and a soft glow; it also climbs the
# two posts that hold up the balcony (`_vintage_post`).
func _vintage_lights(x0: float, x1: float, rail_y: float) -> void:
	const SWAG := 44.0
	var n := int((x1 - x0) / SWAG)
	var step := (x1 - x0) / n
	var wire := ""
	for i in n:
		var a := x0 + i * step
		wire += "%s%s %s Q%s %s %s %s " % ["M" if i == 0 else "", _n(a), _n(rail_y + 1), _n(a + step / 2.0), _n(rail_y + 20), _n(a + step), _n(rail_y + 1)]
	_path(wire, "none", _stroke("#1F3A26", 2))
	var count := 0
	for i in n:
		for t in [0.25, 0.75]:
			var u: float = t
			# On the curve of the swag.
			_vintage_bulb(x0 + i * step + step * u, rail_y + 1.0 + 38.0 * u * (1.0 - u), count)
			count += 1


# The same string climbing one of the balcony's twin posts, winding from one upright to the other.
func _vintage_post(x: float, y0: float, y1: float, first: int) -> void:
	const TURN := 32.0
	const WIDE := 20.0
	var wire := "M%s %s" % [_n(x + 1.0), _n(y1)]
	var y := y1
	var left := true
	var count := first
	while y - TURN > y0:
		y -= TURN
		left = not left
		var px := x + (1.0 if left else WIDE + 1.0)
		wire += " Q%s %s %s %s" % [_n(x + WIDE / 2.0), _n(y + TURN * 0.35), _n(px), _n(y)]
	_path(wire, "none", _stroke("#1F3A26", 2))
	y = y1
	left = true
	while y - TURN > y0:
		y -= TURN
		left = not left
		_vintage_bulb(x + (1.0 if left else WIDE + 1.0), y, count)
		count += 1


func _vintage_bulb(px: float, py: float, count: int) -> void:
	const BULBS := ["#D9342B", "#2E9E4F", "#2F6DB5", "#F08A24", "#F4EFE0"]
	var color: String = BULBS[count % BULBS.size()]
	_circle(px, py + 11, 10, color, 'opacity="0.28"')
	_rect(px - 2.5, py, 5, 4, "#1F3A26")
	_path("M%s %s c-5 4 -5 9 0 13 c5 -4 5 -9 0 -13 z" % [_n(px), _n(py + 3)], color, _stroke("#00000055", 0.8))
	_circle(px - 1.3, py + 7, 1.1, "#FFFFFF", 'opacity="0.75"')


# A wrought-iron heart: two scrolls rising from one point and curling in at the top.
func _iron_heart(cx: float, cy: float, r: float, width := 2.0) -> void:
	for side in [-1.0, 1.0]:
		_path("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s" % [_n(cx), _n(cy + r), _n(cx + side * r * 1.5), _n(cy), _n(cx + side * r * 1.25), _n(cy - r * 1.15), _n(cx + side * r * 0.5), _n(cy - r * 0.95), _n(cx + side * r * 0.1), _n(cy - r * 0.85), _n(cx + side * r * 0.2), _n(cy - r * 0.3), _n(cx + side * r * 0.5), _n(cy - r * 0.45)], "none", _stroke(k.metal, width) + ' stroke-linecap="round"')


# Twin thin uprights holding up the balcony, iron scrolls between them at the top and the foot.
func _iron_post(x: float, y0: float, y1: float) -> void:
	const GAP := 20.0
	for px in [x, x + GAP]:
		_rect(px, y0, 2.5, y1 - y0, k.metal)
	for y: float in [y0 + 12.0, y1 - 46.0]:
		_rect(x, y - 4, GAP + 2.5, 2, k.metal)
		_rect(x, y + 36, GAP + 2.5, 2, k.metal)
		for k2 in 2:
			var cy := y + 8.0 + k2 * 18.0
			_path("M%s %s c5 -7 15 -7 16 0 c0 5 -8 5 -7 0" % [_n(x + 3), _n(cy)], "none", _stroke(k.metal, 1.6) + ' stroke-linecap="round"')


# Stone band with a carved fleur-de-lis block in the middle, between two recessed panels.
func _fleur_lintel(x: float, y: float, w: float) -> void:
	var lx := x - 12.0
	var lw := w + 24.0
	var h := 24.0
	var ly := y - h
	var bw := 26.0
	var bx := x + w / 2 - bw / 2
	_rect(lx, ly, lw, h, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(lx, ly, lw, 3, "#FFFFFF", 'opacity="0.3"')
	for seg in [[lx + 4, bx - 4], [bx + bw + 4, lx + lw - 4]]:
		_rect(seg[0], ly + 5, seg[1] - seg[0], h - 9, "none", _stroke(k.lintel_dark, 1) + ' opacity="0.7"')
	_rect(bx + 2, ly, bw, h + 2, "#000000", 'opacity="0.15"')
	_rect(bx, ly - 2, bw, h + 2, k.lintel, _stroke(k.lintel_dark, 1.5))
	_fleur(bx + bw / 2, ly + h / 2 - 1, 0.95, k.lintel_dark)


func _fleur(cx: float, cy: float, s: float, color: String) -> void:
	out.append('<g transform="translate(%s %s) scale(%s)" fill="%s">' % [_n(cx), _n(cy), str(s), color])
	out.append('<path d="M0 -10 C3 -6 4 -2 1.5 2 H-1.5 C-4 -2 -3 -6 0 -10 Z"/>')
	out.append('<path d="M1.5 1.5 C2 -4 9 -7 9.5 -1.5 C9.8 2 6.5 2.5 5.5 0 C5.5 3 3.5 3.5 1.5 3 Z"/>')
	out.append('<path d="M-1.5 1.5 C-2 -4 -9 -7 -9.5 -1.5 C-9.8 2 -6.5 2.5 -5.5 0 C-5.5 3 -3.5 3.5 -1.5 3 Z"/>')
	out.append('<rect x="-5" y="2.5" width="10" height="2.2" rx="1"/>')
	out.append('<path d="M-1.5 4.7 H1.5 L2.2 10 L0 8.5 L-2.2 10 Z"/>')
	out.append('<path d="M-1.8 4.7 C-4 5 -6 6.5 -5.5 9 C-4 8 -2.5 6.8 -1.8 6 Z"/>')
	out.append('<path d="M1.8 4.7 C4 5 6 6.5 5.5 9 C4 8 2.5 6.8 1.8 6 Z"/>')
	out.append('</g>')


func _flat_parapet(top: float) -> void:
	_rect(X0 - 4, top - 12, X1 - X0 + 8, 12, "#8E9296", _stroke("#63676B", 1.5))
	_rect(X0 - 4, top - 12, X1 - X0 + 8, 3, "#B7BBBF")
	_rect(X0, top, X1 - X0, 6, "#000000", 'opacity="0.15"')
	_snow(X0 - 4, X1 - X0 + 8, top - 12)


# Carved stone panel with a face in relief, centred above the upper door.
func _crest(cx: float, y: float) -> void:
	var w := 62.0
	var h := 50.0
	var x := cx - w / 2
	var dark: String = k.lintel_dark
	_rect(x + 3, y + 3, w, h, "#000000", 'opacity="0.2"')
	_rect(x, y, w, h, k.lintel, _stroke(dark, 1.5))
	_path("M%s %s h%s l-5 5 h%s v%s l-5 5 z" % [_n(x), _n(y), _n(w), _n(-(w - 10)), _n(h - 10)], "#FFFFFF", 'opacity="0.35"')
	_path("M%s %s h%s l5 -5 h%s v%s l5 -5 z" % [_n(x + w), _n(y + h), _n(-w), _n(w - 10), _n(-(h - 10))], "#000000", 'opacity="0.18"')
	var c := Vector2(cx, y + h / 2)
	for i in 16:
		var a := TAU * i / 16.0
		var d := Vector2(cos(a), sin(a))
		var p0 := c + d * 13.5
		var p1 := c + d * Vector2(26, 19)
		_path("M%s %s L%s %s" % [_n(p0.x), _n(p0.y), _n(p1.x), _n(p1.y)], "none", _stroke(dark, 1.5) + ' opacity="0.7"')
	_circle(c.x + 1.5, c.y + 1.5, 12, "#000000", 'opacity="0.22"')
	_circle(c.x, c.y, 12, k.lintel, _stroke(dark, 1.5))
	_circle(c.x - 2, c.y - 2, 8, "#FFFFFF", 'opacity="0.2"')
	var face := _stroke(dark, 1.6) + ' stroke-linecap="round"'
	_path("M%s %s q2.5 -2.5 5 0 M%s %s q2.5 -2.5 5 0" % [_n(c.x - 7), _n(c.y - 2), _n(c.x + 2), _n(c.y - 2)], "none", face)
	_path("M%s %s v4 h-1.5" % [_n(c.x), _n(c.y - 1)], "none", face)
	_path("M%s %s q4 3.5 8 0" % [_n(c.x - 4), _n(c.y + 5)], "none", face)


func _rosette(cx: float, cy: float) -> void:
	for d in [Vector2(0, -3.5), Vector2(3.5, 0), Vector2(0, 3.5), Vector2(-3.5, 0)]:
		_circle(cx + d.x, cy + d.y, 3, k.lintel_dark, 'opacity="0.55"')
	_circle(cx, cy, 2, k.lintel_dark)


func _small_plaque(cx: float, cy: float, text: String, scale: float, fill: String) -> void:
	out.append('<g transform="translate(%s %s) scale(%s) translate(%s %s)">' % [_n(cx), _n(cy), _n(scale), _n(-cx), _n(-cy)])
	_plaque(cx, cy, text, fill)
	out.append('</g>')


func _plaque(cx: float, cy: float, text: String, fill := "#1E1E1E") -> void:
	var gw := 7.0
	var gh := 11.0
	var gap := 4.0
	var w := text.length() * gw + (text.length() - 1) * gap + 14.0
	_rect(cx - w / 2, cy - 11, w, 22, fill, 'rx="3" ' + _stroke("#555555", 1))
	var gx := cx - w / 2 + 7.0
	for ch in text:
		if GLYPHS.has(ch):
			for stroke in GLYPHS[ch]:
				var parts := PackedStringArray()
				for i in range(0, stroke.size(), 2):
					parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(gx + stroke[i] * gw), _n(cy - gh / 2 + stroke[i + 1] * gh)])
				_path(" ".join(parts), "none", _stroke("#FFFFFF", 1.8) + ' stroke-linecap="round" stroke-linejoin="round"')
		gx += gw + gap


func _door(cx: float, top: float, bottom: float) -> void:
	if k.get("door_style", "") == "wood_glass":
		_wood_door(cx, top, bottom, is_equal_approx(bottom, _fb(0)))
		return
	var w := 96.0
	var x := cx - w / 2
	var style: String = k.get("door_style", "double")
	_door_surround(cx, top, w)
	_rect(x - 7, top, w + 14, bottom - top, k.trim_dark)
	_rect(x - 4, top, w + 8, bottom - top, k.trim)
	# The transom over the door: a fan of glass under an arched surround, else a plain glazed light.
	if k.get("door_surround", "lintel") == "arch":
		_path("M%s %s A%s 22 0 0 1 %s %s Z" % [_n(x + 4), _n(top + 23), _n((w - 8) / 2.0), _n(x + w - 4), _n(top + 23)], "url(#glass)", _stroke(k.door_dark, 1.5))
		for a in [0.25, 0.5, 0.75]:
			var p := Vector2(cx, top + 23) + Vector2(-cos(a * PI), -sin(a * PI) * 0.5) * (w - 8) / 2.0
			_path("M%s %s L%s %s" % [_n(cx), _n(top + 23), _n(p.x), _n(p.y)], "none", _stroke(k.door_dark, 1.2))
	else:
		_rect(x + 4, top + 5, w - 8, 18, "url(#glass)")
		if style == "leaded":
			_leading(Rect2(x + 4, top + 5, w - 8, 18))
	var dy := top + 28
	var dh := bottom - dy
	match style:
		"double", "double_leaded":
			var lw := (w - 8) / 2.0
			for i in 2:
				var lx := x + 4 + i * lw
				_rect(lx, dy, lw, dh, k.door, _stroke(k.door_dark, 2))
				_rect(lx + 7, dy + 9, lw - 14, dh * 0.58, "url(#glass)", _stroke(k.door_dark, 2))
				if style == "double_leaded":
					_leading(Rect2(lx + 7, dy + 9, lw - 14, dh * 0.58))
				_rect(lx + 7, dy + dh * 0.58 + 18, lw - 14, dh * 0.42 - 28, "none", _stroke(k.door_dark, 2))
			_circle(cx - 6, dy + dh * 0.62, 3, "#E3C26A")
			_circle(cx + 6, dy + dh * 0.62, 3, "#E3C26A")
		_:
			if k.get("sidelights", false):
				# Narrow stained-glass lights each side of a narrower door, a small panel under each.
				for sx in [x + 4.0, x + w - 18.0]:
					_rect(sx, dy, 14, dh * 0.72, "url(#glass)", _stroke(k.door_dark, 1.5))
					_leading(Rect2(sx, dy, 14, dh * 0.72))
					_rect(sx, dy + dh * 0.72, 14, dh * 0.28, k.door, _stroke(k.door_dark, 1.5))
				_door_leaf(style, Rect2(x + 20, dy, w - 40, dh))
			else:
				_door_leaf(style, Rect2(x + 4, dy, w - 8, dh))
	_door_lamps(cx, top, w)
	_door_wreath(cx, top, top + 60)


# Charlotte's doors (reference/maison_charlotte/): varnished wood under a stone lintel with a carved fleur-de-lis, a dark transom, a tall
# pane of smoky glass over a panel, a black lock plate. Downstairs it is wide with a narrow smoky light each side, a little lantern
# each side and the blue number plate under the left one; upstairs a single door, a lantern and blue plate on the right.
func _wood_door(cx: float, top: float, bottom: float, ground: bool) -> void:
	var w := 118.0 if ground else 74.0
	var x := cx - w / 2.0
	var dark: String = k.door_dark
	var over := 12.0 if ground else 16.0
	_rect(x - over, top - 28, w + over * 2.0, 26, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(x - over, top - 28, w + over * 2.0, 3, "#FFFFFF", 'opacity="0.3"')
	_fleur(cx, top - 15, 0.85, k.lintel_dark)
	_rect(x - 3, top - 2, w + 6, bottom - top + 2, dark)
	_rect(x, top, w, bottom - top, k.door)
	_rect(x + 7, top + 6, w - 14, 17, "#2A3433", _stroke(dark, 1.5))
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x + w * 0.42), _n(top + 6), _n(x + w * 0.56), _n(top + 6), _n(x + w * 0.48), _n(top + 23), _n(x + w * 0.34), _n(top + 23)], "#FFFFFF", 'opacity="0.16"')
	var leaf := Rect2(x + 6, top + 29, w - 12, bottom - top - 33)
	if ground:
		for sx in [x + 7.0, x + w - 23.0]:
			_rect(sx, top + 29, 16, bottom - top - 36, "#4F5856", _stroke(dark, 1.5))
			_rect(sx + 5, top + 34, 3, bottom - top - 46, "#CFD6D4", 'opacity="0.35"')
		leaf = Rect2(x + 28, top + 29, w - 56, bottom - top - 33)
	_rect(leaf.position.x, leaf.position.y, leaf.size.x, leaf.size.y, k.door, _stroke(dark, 2))
	var pane := Rect2(leaf.position.x + 10, leaf.position.y + 13, leaf.size.x - 20, leaf.size.y * 0.56)
	_rect(pane.position.x - 2, pane.position.y - 2, pane.size.x + 4, pane.size.y + 4, dark)
	_rect(pane.position.x, pane.position.y, pane.size.x, pane.size.y, "#4F5856")
	_path("M%s %s q-5 %s 3 %s q5 %s -3 %s h9 q6 %s -2 %s q-6 %s 2 %s z" % [_n(pane.get_center().x + 4), _n(pane.position.y), _n(pane.size.y * 0.25), _n(pane.size.y * 0.5), _n(pane.size.y * 0.25), _n(pane.size.y * 0.5), _n(-pane.size.y * 0.25), _n(-pane.size.y * 0.5), _n(-pane.size.y * 0.25), _n(-pane.size.y * 0.5)], "#CFD6D4", 'opacity="0.4"')
	_raised(leaf.position.x + 10, pane.end.y + 10, leaf.size.x - 20, leaf.end.y - pane.end.y - 18)
	_rect(leaf.position.x + 3, pane.end.y - 30, 5, 32, "#161616", 'rx="1"')
	if ground:
		_wall_lantern(x - 19.0, top + 26.0)
		_wall_lantern(x + w + 19.0, top + 26.0)
		_small_plaque(x - 19.0, top + 50.0, k.number, 0.5, "#1F3A6E")
	else:
		_wall_lantern(x + w + 15.0, top + 24.0)
		_small_plaque(x + w + 15.0, top + 48.0, k.number_up, 0.5, "#1F3A6E")
	_door_wreath(cx, top, top + 70)


# A little black wall lantern with a frosted glass.
func _wall_lantern(x: float, y: float) -> void:
	_circle(x, y + 4, 15, "url(#glow)")
	_rect(x - 1.5, y - 12, 3, 5, "#1A1A1A")
	_path("M%s %s h14 l-3 -6 h-8 z" % [_n(x - 7), _n(y - 2)], "#1A1A1A")
	_rect(x - 5, y - 2, 10, 13, "#ECE7DA", _stroke("#1A1A1A", 1.5))
	_rect(x - 6, y + 11, 12, 2.5, "#1A1A1A")


# What tops the doorway: a plain lintel, a cornice on two scrolled brackets, a little pediment, or an arch.
func _door_surround(cx: float, top: float, w: float) -> void:
	var x := cx - w / 2
	match k.get("door_surround", "lintel"):
		"cornice":
			_rect(x - 16, top - 24, w + 32, 18, k.lintel, _stroke(k.lintel_dark, 1.5))
			_rect(x - 26, top - 34, w + 52, 10, k.lintel, _stroke(k.lintel_dark, 1.5))
			_rect(x - 26, top - 26, w + 52, 2, k.lintel_dark)
			for bx in [x - 14.0, x + w + 4.0]:
				_path("M%s %s h10 v8 q0 14 -5 22 q-5 -8 -5 -22 z" % [_n(bx), _n(top - 24)], k.lintel, _stroke(k.lintel_dark, 1.5))
				_circle(bx + 5, top - 14, 2.5, k.lintel_dark)
		"pediment":
			_rect(x - 14, top - 20, w + 28, 20, k.lintel, _stroke(k.lintel_dark, 1.5))
			_path("M%s %s L%s %s L%s %s Z" % [_n(x - 20), _n(top - 20), _n(cx), _n(top - 50), _n(x + w + 20), _n(top - 20)], k.lintel, _stroke(k.lintel_dark, 1.5))
			_path("M%s %s L%s %s L%s %s" % [_n(x - 8), _n(top - 24), _n(cx), _n(top - 42), _n(x + w + 8), _n(top - 24)], "none", _stroke(k.lintel_dark, 1.2))
		"arch":
			_path("M%s %s A%s 34 0 0 1 %s %s Z" % [_n(x - 14), _n(top + 2), _n(w / 2 + 14), _n(x + w + 14), _n(top + 2)], k.lintel, _stroke(k.lintel_dark, 1.5))
			_rect(cx - 6, top - 34, 12, 16, k.lintel_dark)
		_:
			_rect(x - 14, top - 20, w + 28, 20, k.lintel, _stroke(k.lintel_dark, 1.5))


# A single door leaf in one of the Rosemont styles, with its knob and brass mail slot.
func _door_leaf(style: String, r: Rect2) -> void:
	var dark: String = k.door_dark
	_rect(r.position.x, r.position.y, r.size.x, r.size.y, k.door, _stroke(dark, 2))
	_rect(r.position.x, r.position.y, 4, r.size.y, "#FFFFFF", 'opacity="0.12"')
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	match style:
		"panel":
			for row in 3:
				for col in 2:
					var px := x + 10 + col * (w - 20) / 2.0
					var py := y + 10 + row * (h - 20) / 3.0
					_raised(px + 3, py + 3, (w - 20) / 2.0 - 6, (h - 20) / 3.0 - 8)
		"oval":
			_path("M%s %s a%s %s 0 1 0 0.01 0 z" % [_n(x + w / 2), _n(y + 12), _n(w * 0.3), _n(h * 0.3)], "url(#glass)", _stroke(dark, 2.5))
			for k2 in [-1.0, 1.0]:
				_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x + w / 2), _n(y + 22), _n(x + w / 2 + k2 * w * 0.2), _n(y + 12 + h * 0.3), _n(x + w / 2), _n(y + 2 + h * 0.6), _n(x + w / 2 + k2 * w * 0.06), _n(y + 12 + h * 0.3)], "none", _stroke("#3A3A3A", 1.0))
			_raised(x + 12, y + h * 0.7, w - 24, h * 0.24)
		"leaded":
			var g := Rect2(x + 9, y + 9, w - 18, h * 0.5)
			_rect(g.position.x, g.position.y, g.size.x, g.size.y, "url(#glass)", _stroke(dark, 2))
			_leading(g)
			_raised(x + 10, y + h * 0.62, (w - 26) / 2.0, h * 0.32)
			_raised(x + 16 + (w - 26) / 2.0, y + h * 0.62, (w - 26) / 2.0, h * 0.32)
		"diamond":
			for row in 3:
				var cy := y + h * (0.2 + row * 0.3)
				var dw := w * 0.36
				var dh2 := h * 0.12
				_path("M%s %s l%s %s l%s %s l%s %s z" % [_n(x + w / 2), _n(cy - dh2), _n(dw), _n(dh2), _n(-dw), _n(dh2), _n(-dw), _n(-dh2)], "none", _stroke(dark, 2))
				_path("M%s %s l%s %s l%s %s l%s %s z" % [_n(x + w / 2), _n(cy - dh2 * 0.55), _n(dw * 0.55), _n(dh2 * 0.55), _n(-dw * 0.55), _n(dh2 * 0.55), _n(-dw * 0.55), _n(-dh2 * 0.55)], "#FFFFFF", 'opacity="0.12"')
		"slots":
			for row in 3:
				_rect(x + w / 2 - 9, y + h * (0.16 + row * 0.2), 18, 18, "url(#glass)", _stroke(dark, 2))
		"slit":
			_rect(x + w * 0.62, y + h * 0.1, 10, h * 0.55, "url(#glass)", _stroke(dark, 2))
		"planks":
			var px := x + 9.0
			while px < x + w - 4.0:
				_path("M%s %s V%s" % [_n(px), _n(y + 2), _n(y + h - 2)], "none", _stroke(dark, 1.2))
				px += 9.0
			_rect(x + w / 2 - 8, y + h * 0.14, 16, 16, "url(#glass)", _stroke(dark, 2))
			for hy in [y + h * 0.2, y + h * 0.8]:
				_rect(x + 2, hy, w * 0.45, 5, "#2B2B2B")
		"slats":
			for row in 5:
				var sy := y + h * (0.12 + row * 0.12)
				_path("M%s %s l%s -8 v8 l-%s 8 z" % [_n(x + w * 0.22), _n(sy + 8), _n(w * 0.56), _n(w * 0.56)], "url(#glass)", _stroke(dark, 1.5))
		"fan_top":
			var c := Vector2(x + w / 2, y + h * 0.3)
			_path("M%s %s A%s %s 0 0 1 %s %s Z" % [_n(x + 8), _n(c.y), _n(w / 2 - 8), _n(h * 0.2), _n(x + w - 8), _n(c.y)], "url(#glass)", _stroke(dark, 2))
			for a in [0.2, 0.4, 0.6, 0.8]:
				var p := c + Vector2(-cos(a * PI) * (w / 2 - 8), -sin(a * PI) * h * 0.2)
				_path("M%s %s L%s %s" % [_n(c.x), _n(c.y), _n(p.x), _n(p.y)], "none", _stroke(dark, 1.2))
			_raised(x + 10, y + h * 0.38, (w - 26) / 2.0, h * 0.56)
			_raised(x + 16 + (w - 26) / 2.0, y + h * 0.38, (w - 26) / 2.0, h * 0.56)
		"grid":
			var g := Rect2(x + 9, y + 9, w - 18, h * 0.48)
			_rect(g.position.x, g.position.y, g.size.x, g.size.y, "url(#glass)", _stroke(dark, 2))
			for col in [1, 2]:
				_path("M%s %s V%s" % [_n(g.position.x + g.size.x * col / 3.0), _n(g.position.y), _n(g.end.y)], "none", _stroke(dark, 1.5))
			for row in [1, 2, 3]:
				_path("M%s %s H%s" % [_n(g.position.x), _n(g.position.y + g.size.y * row / 4.0), _n(g.end.x)], "none", _stroke(dark, 1.5))
			_raised(x + 10, y + h * 0.62, w - 20, h * 0.32)
		"glass":
			# One big pane in a thin black frame, a plain panel under it.
			var pane := Rect2(x + 7, y + 7, w - 14, h * 0.74)
			_rect(pane.position.x, pane.position.y, pane.size.x, pane.size.y, "url(#glass)", _stroke(dark, 2.5))
			_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(pane.position.x + pane.size.x * 0.55), _n(pane.position.y), _n(pane.position.x + pane.size.x * 0.8), _n(pane.position.y), _n(pane.position.x + pane.size.x * 0.25), _n(pane.end.y), _n(pane.position.x), _n(pane.end.y)], "#FFFFFF", 'opacity="0.16"')
			_raised(x + 8, y + h * 0.8, w - 16, h * 0.15)
		"sunburst":
			var base := Vector2(x + w / 2, y + h * 0.46)
			for k2 in 5:
				var a0 := PI + k2 * PI / 5.0
				var p0 := base + Vector2.from_angle(a0) * w * 0.4
				var p1 := base + Vector2.from_angle(a0 + PI / 5.0 - 0.08) * w * 0.4
				_path("M%s %s L%s %s L%s %s Z" % [_n(base.x), _n(base.y), _n(p0.x), _n(p0.y), _n(p1.x), _n(p1.y)], "url(#glass)", _stroke(dark, 1.2))
			_raised(x + 10, y + h * 0.56, w - 20, h * 0.38)
		"porthole":
			_circle(x + w / 2, y + h * 0.28, w * 0.2, "url(#glass)", _stroke(dark, 4))
			_circle(x + w / 2, y + h * 0.28, w * 0.24, "none", _stroke("#C9A24A", 2))
		"grille":
			var g := Rect2(x + 9, y + 9, w - 18, h * 0.7)
			_rect(g.position.x, g.position.y, g.size.x, g.size.y, "url(#glass)", _stroke(dark, 2))
			for row in 3:
				var cy := g.position.y + g.size.y * (0.2 + row * 0.3)
				_path("M%s %s c-10 -4 -12 -16 -2 -18 c6 -1 7 6 2 7 M%s %s c10 -4 12 -16 2 -18 c-6 -1 -7 6 -2 7" % [_n(g.get_center().x), _n(cy), _n(g.get_center().x), _n(cy)], "none", _stroke("#1F1F1F", 2))
			_path("M%s %s V%s" % [_n(g.get_center().x), _n(g.position.y), _n(g.end.y)], "none", _stroke("#1F1F1F", 2))
			_raised(x + 10, y + h * 0.82, w - 20, h * 0.13)
		"horizontal":
			for row in 4:
				_raised(x + 9, y + 10 + row * (h - 20) / 4.0, w - 18, (h - 20) / 4.0 - 8)
		"arched_panels":
			for col in 2:
				var px := x + 9 + col * (w - 18) / 2.0
				var pw := (w - 18) / 2.0 - 5
				_path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(px), _n(y + h * 0.62), _n(y + 22), _n(pw / 2), _n(14), _n(px + pw), _n(y + 22), _n(y + h * 0.62)], "none", _stroke(dark, 2))
				_raised(px, y + h * 0.7, pw, h * 0.24)
	_rect(x + w / 2 - 12, y + h * 0.56, 24, 5, "#C9A24A", _stroke("#8E6E2A", 1))
	_circle(x + w - 12, y + h * 0.52, 3.5, "#E3C26A")


func _raised(x: float, y: float, w: float, h: float) -> void:
	_rect(x, y, w, h, "none", _stroke(k.door_dark, 2))
	_rect(x + 4, y + 4, w - 8, h - 8, "#FFFFFF", 'opacity="0.08"')
	_path("M%s %s h%s M%s %s v%s" % [_n(x + 1), _n(y + h - 1), _n(w - 2), _n(x + w - 1), _n(y + 1), _n(h - 2)], "none", _stroke("#000000", 1.5) + ' opacity="0.2"')


# Stained glass: lead lines in arcs and a few coloured pieces (amber, ruby, green).
func _leading(g: Rect2) -> void:
	var c := g.get_center()
	for piece in [["#E8B04A", -0.3, -0.25], ["#B03A4A", 0.3, -0.25], ["#4E8A5A", 0.0, 0.2], ["#E8B04A", 0.0, -0.05]]:
		_circle(c.x + piece[1] * g.size.x, c.y + piece[2] * g.size.y, minf(g.size.x, g.size.y) * 0.16, piece[0], 'opacity="0.55"')
	var lead := _stroke("#3A3A3A", 1.2)
	_path("M%s %s Q%s %s %s %s" % [_n(g.position.x), _n(g.end.y), _n(c.x), _n(g.position.y - g.size.y * 0.3), _n(g.end.x), _n(g.end.y)], "none", lead)
	_path("M%s %s V%s M%s %s H%s" % [_n(c.x), _n(g.position.y), _n(g.end.y), _n(g.position.x), _n(c.y), _n(g.end.x)], "none", lead)
	_circle(c.x, c.y, minf(g.size.x, g.size.y) * 0.18, "none", lead)


# The lights by the front door, in this house's style (`lamp_style`): a pair either side, a single one hung over the
# door, or just one on the left.
func _door_lamps(cx: float, top: float, w: float) -> void:
	var style: String = k.get("lamp_style", "lantern")
	match style:
		"single":
			_lamp("pendant", cx, top - 30)
		"left":
			_lamp("lantern", cx - (w / 2 + 24), top + 34)
		_:
			for sx in [-1.0, 1.0]:
				_lamp(style, cx + sx * (w / 2 + 24), top + 34)


func _lamp(style: String, x: float, y: float) -> void:
	match style:
		"globe":
			# A frosted glass globe on a little brass bracket.
			_circle(x, y + 6, 24, "url(#glow)")
			_path("M%s %s q8 -2 8 6" % [_n(x - 8), _n(y - 10)], "none", _stroke("#B08A3A", 2.5))
			_rect(x - 3, y - 6, 6, 4, "#B08A3A")
			_circle(x, y + 7, 9, "#FFF4DA", _stroke("#D9CBA8", 1.5))
			_circle(x - 3, y + 4, 3, "#FFFFFF", 'opacity="0.7"')
		"coach":
			# A carriage lamp: gilded frame, a pointed cap and a finial.
			_circle(x, y + 8, 24, "url(#glow)")
			_path("M%s %s l8 -10 l8 10 z" % [_n(x - 8), _n(y - 4)], "#2B2B2B", _stroke("#C9A24A", 1.5))
			_circle(x, y - 16, 2.5, "#C9A24A")
			_path("M%s %s h14 l-2 20 h-10 z" % [_n(x - 7), _n(y - 4)], "#FFE7A3", _stroke("#C9A24A", 2))
			_path("M%s %s V%s" % [_n(x), _n(y - 4), _n(y + 16)], "none", _stroke("#C9A24A", 1))
			_rect(x - 6, y + 16, 12, 4, "#2B2B2B")
		"cylinder":
			# A modern up-and-down cylinder washing the brick with light.
			_circle(x, y - 14, 16, "url(#glow)")
			_circle(x, y + 30, 16, "url(#glow)")
			_rect(x - 5, y - 6, 10, 26, "#3A3D42", 'rx="3"')
			_rect(x - 4, y - 8, 8, 3, "#FFF1C9")
			_rect(x - 4, y + 19, 8, 3, "#FFF1C9")
		"box":
			# A square black box with a frosted face.
			_circle(x, y + 8, 22, "url(#glow)")
			_rect(x - 8, y - 4, 16, 18, "#1E1E1E")
			_rect(x - 5, y - 1, 10, 12, "#F4EEDC")
			_path("M%s %s V%s M%s %s H%s" % [_n(x), _n(y - 1), _n(y + 11), _n(x - 5), _n(y + 5), _n(x + 5)], "none", _stroke("#1E1E1E", 1))
		"pendant":
			# Hung on a chain under the lintel, over the door.
			_path("M%s %s V%s" % [_n(x), _n(y - 20), _n(y - 4)], "none", _stroke("#2B2B2B", 1.5) + ' stroke-dasharray="2 2"')
			_lantern(x, y + 4)
		_:
			_lantern(x, y)


func _lantern(x: float, y: float) -> void:
	_circle(x, y + 8, 22, "url(#glow)")
	_rect(x - 1.5, y - 12, 3, 6, "#1E1E1E")
	_path("M%s %s h16 l-3 -6 h-10 z" % [_n(x - 8), _n(y - 2)], "#1E1E1E")
	_rect(x - 6, y - 2, 12, 18, "#FFE7A3", _stroke("#1E1E1E", 2))
	_rect(x - 7, y + 16, 14, 3, "#1E1E1E")


func _awning(x0: float, x1: float, y: float, post_bottom: float) -> void:
	var dark := "#" + Color(k.awning).darkened(0.3).to_html(false)
	_rect(x0 - 16, y + 22, x1 - x0 + 32, 12, "#000000", 'opacity="0.15"')
	var thin: Array = k.get("awning_posts", [])
	if thin.is_empty():
		for px in [x0 + 2, x1 - 9]:
			_rect(px, y + 20, 7, post_bottom - y - 20, k.metal, _metal_stroke())
	else:
		# Thin iron bars from the balcony rail, a brace back up to the wall from each.
		for px: float in thin:
			_rect(px, y + 20, 3, post_bottom - y - 20, k.metal)
			_path("M%s %s L%s %s" % [_n(px + 1.5), _n(y + 58), _n(px + 34), _n(y + 22)], "none", _stroke(k.metal, 2))
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0 - 10), _n(y), _n(x1 + 10), _n(x1 + 18), _n(y + 20), _n(x0 - 18)], k.awning, _stroke(dark, 2))
	var x := x0 - 8.0
	while x < x1 + 10:
		_path("M%s %s V%s" % [_n(x), _n(y + 1), _n(y + 18)], "none", _stroke(dark, 1.5))
		x += 9.0
	_rect(x0 - 20, y + 18, x1 - x0 + 40, 5, dark)
	_snow(x0 - 10, x1 - x0 + 20, y)


func _column(x: float, dir: float, y0: float, y1: float) -> void:
	_rect(x, y0, 7, y1 - y0, k.metal, _metal_stroke())
	_path("M%s %s q%s -4 %s -26" % [_n(x + 3.5 + dir * 3.5), _n(y0 + 26), _n(dir * 12), _n(dir * 22)], "none", _stroke(k.metal, 3))


func _balcony(x0: float, x1: float, floor_y: float, gaps: Array) -> void:
	var top := floor_y - RAIL_H
	for seg in _segments(x0, x1, gaps):
		var a: float = seg[0]
		var b: float = seg[1]
		var x := a + 8.0
		while x < b - 6.0:
			_rect(x, top + 4, 2.5, RAIL_H - 6, k.metal, _metal_stroke())
			x += 10.0
		var sx := a + 40.0
		while sx < b - 30.0:
			_scroll(sx, top + RAIL_H * 0.5)
			sx += 64.0
		_rect(a, top, b - a, 5, k.metal, _metal_stroke())
		_rect(a, floor_y - 9, b - a, 3, k.metal, _metal_stroke())
		for px in [a, b - 6]:
			_rect(px, top - 4, 6, RAIL_H + 4, k.metal, _metal_stroke())
			_circle(px + 3, top - 6, 4, k.metal, _metal_stroke())
	_rect(x0 - 6, floor_y, x1 - x0 + 12, 16, k.slab, _stroke(k.slab_dark, 2))
	_rect(x0 - 6, floor_y + 11, x1 - x0 + 12, 5, k.slab_dark)
	_rect(x0 - 2, floor_y + 16, x1 - x0 + 4, 36, "url(#drop)")
	for seg in _segments(x0, x1, gaps):
		_snow(seg[0], seg[1] - seg[0], top)
		_snow(seg[0], seg[1] - seg[0], floor_y - 6)


func _scroll(cx: float, cy: float) -> void:
	var d := "M%s %s c-12 -4 -14 -20 -4 -22 c6 -1 8 6 3 8 M%s %s c12 -4 14 -20 4 -22 c-6 -1 -8 6 -3 8" % [_n(cx), _n(cy + 12), _n(cx), _n(cy + 12)]
	if k.metal_light:
		_path(d, "none", _stroke("#8E8E8A", 4.5))
	_path(d, "none", _stroke(k.metal, 2.5))


func _front_steps(cx: float) -> void:
	var count := 5
	var sh := (ground_y - base_y) / count
	for i in count:
		var w := 96.0 + i * 8.0
		var y := base_y + i * sh
		_rect(cx - w / 2, y, w, sh, k.step, _stroke(k.step_dark, 1.5))
		_rect(cx - w / 2, y, w, 3, "#FFFFFF", 'opacity="0.25"')
		if season == "winter":
			_rect(cx - w / 2 + 6, y - 2, w - 12, 5, "#F7F9FB")
	for sx in [-1.0, 1.0]:
		var top := Vector2(cx + sx * 54.0, _fb(0) - RAIL_H)
		var bottom := Vector2(cx + sx * 70.0, ground_y - RAIL_H)
		for i in 4:
			var p := top.lerp(bottom, (i + 1) / 5.0)
			_rect(p.x - 1.25, p.y, 2.5, RAIL_H, k.metal, _metal_stroke())
		_line("M%s %s L%s %s" % [_n(top.x), _n(top.y), _n(bottom.x), _n(bottom.y)], 4.5)
		_rect(bottom.x - 3, bottom.y - 2, 6, RAIL_H + 2, k.metal, _metal_stroke())


func _landing(c: Vector2) -> void:
	for px in [c.x - 32.0, c.x + 26.0]:
		_rect(px, c.y, 6, ground_y - c.y, k.metal, _metal_stroke())
	_rect(c.x - 36, c.y - 3, 72, 9, k.tread, _stroke(k.tread_dark, 1))
	var x := c.x - 32.0
	while x < c.x + 34.0:
		_rect(x, c.y - RAIL_H, 2.5, RAIL_H, k.metal, _metal_stroke())
		x += 9.0
	_rect(c.x - 36, c.y - RAIL_H - 2, 72, 5, k.metal, _metal_stroke())


func _stairs(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	var steps := int(clampf(p0.distance_to(p3) / 20.0, 6.0, 18.0))
	var hw := 30.0
	var pts: Array[Vector2] = []
	for i in steps + 1:
		pts.append(p0.bezier_interpolate(p1, p2, p3, float(i) / steps))
	if k.get("stair_beam", false):
		# The black steel beam the treads sit on.
		_path(_polyline(pts, Vector2(0, 12)), "none", _stroke(k.metal, 20))
	for side in [-1.0, 1.0]:
		if side > 0.0:
			for i in range(1, steps + 1):
				var p := pts[i]
				_rect(p.x - hw, p.y - 3, hw * 2, 7, k.tread, _stroke(k.tread_dark, 1))
				_rect(p.x - hw, p.y - 3, hw * 2, 2, "#FFFFFF", 'opacity="0.25"')
		for p in pts:
			_rect(p.x + side * hw - 1.25, p.y - RAIL_H, 2.5, RAIL_H, k.metal, _metal_stroke())
		if k.metal_light and side > 0.0:
			for i in range(0, steps, 2):
				var m := (pts[i] + pts[i + 1]) * 0.5
				_circle(m.x + hw, m.y - RAIL_H * 0.5, 6, "none", _stroke(k.metal, 2.5))
		_line(_polyline(pts, Vector2(side * hw, 5)), 6.0)
		_line(_polyline(pts, Vector2(side * hw, -RAIL_H)), 4.5)
		if k.get("ornate", false):
			# Wrought-iron spades between the balusters, and a scrolled newel at the foot.
			for i in range(1, steps, 2):
				var m := (pts[i] + pts[i + 1]) * 0.5 + Vector2(side * hw, -RAIL_H * 0.55)
				_path("M%s %s c-5 -4 -5 -10 0 -12 c5 2 5 8 0 12 z" % [_n(m.x), _n(m.y + 6)], k.metal, _metal_stroke())
			var foot := pts[-1] + Vector2(side * hw, -RAIL_H)
			_path("M%s %s c%s 0 %s 14 %s 16 c-6 0 -8 -6 -4 -8" % [_n(foot.x), _n(foot.y), _n(side * 10), _n(side * 12), _n(side * 4)], "none", _stroke(k.metal, 3.5))
	if k.halloween:
		for f in [0.4, 0.66, 0.9]:
			var i := int(f * steps)
			if rng.randf() < 0.7:
				_pumpkin(pts[i].x + rng.randf_range(-10.0, 10.0), pts[i].y - 3.0, rng.randf_range(0.55, 0.75), rng.randf() < 0.4)


# Leafy plants on the soil in summer and autumn (a few turning yellow in autumn): clumps of small leaves over a dark shade,
# some taller, lit from the upper left. The same random draws in every season; in the others only the soil shows.
func _greenery(x0: float, x1: float) -> void:
	var tones: Array = ["#3E8E3A", "#4FA34A", "#2F7A30", "#5DB55A", "#367F33"] if season == "summer" else ["#5F8F3A", "#7FA34A", "#4E7A30", "#8FA84A", "#C9A23A"]
	var show := season == "summer" or season == "autumn"
	var x := x0 + 8.0
	while x < x1 - 6.0:
		var r := rng.randf_range(18.0, 32.0)
		var cy := ground_y - r * 0.8
		if show:
			_circle(x + 2, cy + 3, r, "#22381F", 'opacity="0.75"')
		for i in 34:
			var a := rng.randf_range(0.0, TAU)
			var d := sqrt(rng.randf()) * r
			var p := Vector2(x + cos(a) * d, cy + sin(a) * d * 0.9)
			var tone: String = tones[rng.randi_range(0, tones.size() - 1)]
			var turn := rng.randf_range(0.0, 180.0)
			var lit := (x - p.x + cy - p.y) / (r * 2.0)
			if show and p.y < ground_y:
				var c := Color(tone).lightened(lit * 0.3) if lit > 0.0 else Color(tone).darkened(-lit * 0.3)
				# A leaf, turned away from the middle of the clump, not a flat ellipse.
				_plant_leaf(p, 9.0, rad_to_deg(Vector2(p.x - x, p.y - cy).angle() + PI / 2.0) + (turn - 90.0) * 0.12, "#" + c.to_html(false))
		x += r * rng.randf_range(1.0, 1.5)


func _garden(gaps: Array) -> void:
	if k.get("bare_garden", false):
		# Dark soil behind the fence, a few fallen leaves on it, as on the photos.
		for seg in _segments(X0, X1, gaps):
			_rect(seg[0], ground_y - 40, seg[1] - seg[0], 40, "#6B5646")
			_greenery(seg[0], seg[1])
			var lx: float = seg[0] + 4.0
			while lx < seg[1] - 4.0:
				_leaf(lx, ground_y - rng.randf_range(1.0, 26.0), rng.randf_range(0.0, TAU))
				lx += rng.randf_range(14.0, 30.0)
			if season == "winter":
				_rect(seg[0], ground_y - 14, seg[1] - seg[0], 14, "#F2F5F8")
		return
	for seg in _segments(X0, X1, gaps):
		var x: float = seg[0] + 14.0
		while x < seg[1] - 14.0:
			var r := rng.randf_range(12.0, 20.0)
			var c := _bush(_pick(AUTUMN_BUSHES))
			_shrub(x, r, c)
			if rng.randf() < 0.3:
				var fx := x + rng.randf_range(-8.0, 8.0)
				var flower := _pick(["#FFD23F", "#FFFFFF", "#C084FC"])
				if season != "winter":
					_bloom(fx, ground_y - r * 1.15, 4.6, flower)
			x += rng.randf_range(18.0, 34.0)
		var lx: float = seg[0] + 4.0
		while lx < seg[1] - 4.0:
			_leaf(lx, ground_y - rng.randf_range(1.0, 5.0), rng.randf_range(0.0, TAU))
			lx += rng.randf_range(6.0, 16.0)
		if season == "winter":
			_rect(seg[0], ground_y - 8, seg[1] - seg[0], 8, "#F2F5F8")


func _fence(gaps: Array) -> void:
	if k.fence == "":
		return
	if k.fence == "wood":
		_wood_fence(gaps)
		return
	if k.fence == "chain":
		_chain_fence(gaps)
		return
	var light: bool = k.fence == "white"
	var col := "#F5F5F2" if light else "#1F1F1F"
	var st := _stroke("#9A9A96", 1) if light else ""
	var pitch := 13.0 if light else 9.0
	var pw := 5.0 if light else 2.5
	var top := ground_y - 50.0
	if k.get("fence_style", "") == "wide":
		# Thin bars wide apart standing a little over the top rail, a thicker post with a round cap at each end.
		top = ground_y - 58.0
		for seg in _segments(X0, X1, gaps):
			var bar: float = seg[0] + 12.0
			while bar < seg[1] - 8.0:
				_rect(bar, top, 2, ground_y - top - 3, col)
				bar += 15.0
			_rect(seg[0], top + 10, seg[1] - seg[0], 3, col)
			_rect(seg[0], ground_y - 11, seg[1] - seg[0], 3, col)
			_snow(seg[0], seg[1] - seg[0], top + 10)
			# Iron hearts along it, one every few bars.
			var heart: float = seg[0] + 34.5
			while heart < seg[1] - 18.0:
				_iron_heart(heart, ground_y - 31.0, 11.0, 2.4)
				heart += 120.0
			for px in [seg[0], seg[1] - 6.0]:
				_rect(px, top - 2, 6, ground_y - top + 2, col)
				_circle(px + 3, top - 3, 4, col)
		return
	for seg in _segments(X0, X1, gaps):
		var a: float = seg[0]
		var b: float = seg[1]
		var x := a + 8.0
		while x < b - 6.0:
			_rect(x, top + 2, pw, ground_y - top - 4, col, st)
			if not light:
				_path("M%s %s l3 -8 l3 8 z" % [_n(x - 1.75), _n(top + 4)], col)
			x += pitch
		_rect(a, top + 6, b - a, 4, col, st)
		_rect(a, ground_y - 12, b - a, 4, col, st)
		_snow(a, b - a, top + 2)
		for px in [a, b - 8]:
			_rect(px, top - 4, 8, ground_y - top + 4, col, st)
			_rect(px - 2, top - 8, 12, 5, col, st)


# Modern infill: brick ground floor with white checker band and quoins, white stucco upper floor.
func _modern() -> void:
	var top := _top()
	var cx: float = k.door_cx
	var mid := _fb(1) + 10.0
	_rect(X0, top, X1 - X0, mid - top, "#ECEAE4")
	_rect(X0, top, X1 - X0, mid - top, "url(#shade)")
	_rect(X0 - 4, top - 10, X1 - X0 + 8, 10, "#D9D6CF", _stroke("#B5B1A8", 1.5))
	if k.get("roof_rail", false):
		# A roof terrace: its glass rail set back from the front, catching the sky.
		var ry := top - 10.0
		_rect(X0 + 60, ry - 46, X1 - X0 - 120, 46, "#CFE4EC", 'opacity="0.4"')
		var gx := X0 + 60.0
		while gx <= X1 - 60.0:
			_rect(gx - 1.5, ry - 48, 3, 48, "#2B2B2E")
			gx += (X1 - X0 - 120.0) / 4.0
		_rect(X0 + 58, ry - 50, X1 - X0 - 116, 4, "#2B2B2E")
	for w in k.windows:
		var wy := _win_y(1) + 10.0
		_rect(w[0] - 4, wy - 4, w[1] + 8, 128, k.get("upper_frame", "#5E5A54"))
		_rect(w[0] + 3, wy + 3, w[1] - 6, 114, "url(#glass)")
		var panes: int = k.get("mullions", 0)
		for m in range(1, panes):
			_rect(w[0] + 3 + (w[1] - 6) * m / float(panes) - 2.5, wy + 3, 5, 114, k.get("upper_frame", "#5E5A54"))
		if panes > 0:
			_path("M%s %s l%s 0 l%s %s l%s 0 z" % [_n(w[0] + w[1] * 0.2), _n(wy + 3), _n(w[1] * 0.08), _n(-w[1] * 0.1), _n(114), _n(-w[1] * 0.08)], "#FFFFFF", 'opacity="0.2"')
		if k.curtains:
			_path("M%s %s h24 q-8 57 2 114 h-26 z" % [_n(w[0] + 3), _n(wy + 3)], "#F3E9D8", 'opacity="0.92"')
		_rect(w[0] - 8, wy + 122, w[1] + 16, 8, "#CFCBC2")
	_rect(X0 - 6, mid, X1 - X0 + 12, 12, "#B7B3AA", _stroke("#8F8B83", 1.5))
	var gy := mid + 12.0
	_bricks(gy, base_y)
	_wall_shading(gy)
	var by := gy + 22.0
	var i := 0
	var x := X0 + 8.0
	while x < X1 - 44.0:
		_rect(x, by + (i % 2) * 11.0, 12, 10, "#F2EFE8")
		x += 13.0
		i += 1
	var qy := gy
	var row := 0
	while qy < base_y - 10.0:
		var qw := 30.0 if row % 2 == 0 else 18.0
		_rect(X1 - qw - 4, qy, qw, 11, "#F2EFE8")
		qy += 13.0
		row += 1
	_foundation()
	var gw: Array = k.ground_window
	_window(gw[0], _win_y(0), gw[1], 160.0)
	var dt := _door_top(0) + 10.0
	var dh := _fb(0) - dt
	_rect(cx - 38, dt, 76, dh, "#8C7A62", _stroke("#5E5242", 2))
	_rect(cx - 30, dt + 6, 60, 20, "url(#glass)")
	_rect(cx - 30, dt + 32, 60, dh - 40, "url(#glass)", _stroke("#5E5242", 1.5))
	_circle(cx - 22, dt + dh * 0.6, 3, "#D9D6CF")
	_rect(cx - 90, dt - 34, 180, 22, "#D8CBB0", _stroke("#A89A7E", 1.5))
	_rect(cx - 86, dt - 12, 172, 6, "#000000", 'opacity="0.15"')
	_circle(cx - 66, dt + 22, 8, "#F4F1EA", _stroke("#9A968E", 1.5))
	_rect(cx - 76, dt + 70, 18, 24, "#2B2B2B")
	_rect(cx - 110, _fb(0), 220, 14, k.step, _stroke(k.step_dark, 1.5))
	_front_steps(cx)
	_garden([[cx - 120, cx + 120]])
	_pumpkin(cx - 70, _fb(0), 1.1, true)
	_pumpkin(cx + 74, _fb(0), 0.8, false)
	if k.bins:
		_bin(X0 + 40, "#2E7D32")
		_bin(X0 + 92, "#5F6368")


func _bin(x: float, color: String) -> void:
	var dark := "#" + Color(color).darkened(0.35).to_html(false)
	_path("M%s %s h40 l-4 58 h-32 z" % [_n(x), _n(ground_y - 62)], color, _stroke(dark, 2))
	_rect(x - 3, ground_y - 68, 46, 8, color, 'rx="3" ' + _stroke(dark, 2))
	_circle(x + 8, ground_y - 3, 4, "#222222")


# Corner store: sign board (text added in the game), striped awning, shelves behind the windows.
func _storefront() -> void:
	var cx: float = k.width / 2.0
	var y0 := _door_top(0) - 30.0
	var dark := "#" + Color(k.shop_sign).darkened(0.35).to_html(false)
	_rect(X0 + 16, y0 - 6, X1 - X0 - 32, 46, k.shop_sign, _stroke(dark, 2.5))
	var ay := y0 + 44.0
	var x := X0 + 16.0
	var i := 0
	while x < X1 - 30.0:
		_path("M%s %s h28 l4 30 h-28 z" % [_n(x), _n(ay)], "#FFFFFF" if i % 2 == 0 else k.shop_sign, _stroke(dark, 1))
		x += 28.0
		i += 1
	var wy := ay + 46.0
	var wb := _fb(0) - 4.0
	for r in [[X0 + 24, cx - 54], [cx + 54, X1 - 24]]:
		_rect(r[0] - 5, wy - 5, r[1] - r[0] + 10, wb - wy + 10, dark)
		_rect(r[0], wy, r[1] - r[0], wb - wy, "url(#glass)")
		for sy in [wy + 46.0, wy + 92.0, wy + 136.0]:
			if sy > wb - 6.0:
				continue
			var px: float = r[0] + 10.0
			while px < r[1] - 20.0:
				var ph := rng.randf_range(12.0, 28.0)
				_rect(px, sy - ph, rng.randf_range(8.0, 14.0), ph, _pick(["#E74C3C", "#F1C40F", "#3498DB", "#2ECC71", "#E67E22", "#FFFFFF", "#9B59B6"]))
				px += rng.randf_range(13.0, 19.0)
			_rect(r[0] + 4, sy, r[1] - r[0] - 8, 4, "#8A7A66")
		_path("M%s %s l40 0 l-60 %s l-40 0 z" % [_n(r[1] - 70), _n(wy), _n(wb - wy)], "#FFFFFF", 'opacity="0.12"')
	_rect(X0 + 40, wy + 12, 54, 20, "#FF3B30", 'rx="5" opacity="0.9"')
	_rect(cx - 46, wy - 12, 92, _fb(0) - wy + 12, dark)
	_rect(cx - 40, wy - 6, 80, _fb(0) - wy + 6, "url(#glass)")
	_rect(cx - 40, wy + 70, 80, 5, dark)
	_front_steps(cx)


# A big red-brick school (from reference/coin_dandurand/School_on_dandurand.jpg): a long wing of tall paired windows
# and, near the corner, a tall pavilion with a diamond lattice in the brick. Stone sills and bands,
# green copper cornices, a small cross on the parapet.
func _school() -> void:
	# École Saint-Jean-de-Brébeuf, from reference/coin_dandurand/School_on_dandurand.jpg: a long red-brick block between two
	# blank end pavilions patterned with a brick diamond lattice, a green copper cornice stepping up over them, the centre
	# entrance with its stone surround, red doors, steps and flagpole, and the cross on the parapet over it.
	var top := _top()
	var copper := "#4E8C7A"
	var copper_dark := "#2F5E50"
	var copper_light := "#7FB8A4"
	var pav := 300.0
	var l1 := X0 + pav
	var r1 := X1 - pav
	var stone_top := base_y - 92.0
	_bricks(top, base_y)
	_wall_shading(top)
	# ── The two end pavilions: blank walls with the big diamond lattice, a hair forward of the centre.
	for side in [[X0, l1], [r1, X1]]:
		var a: float = side[0]
		var b: float = side[1]
		var id := "pav%d" % int(a)
		out.append('<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>' % [id, _n(a), _n(top - 34), _n(b - a), _n(stone_top - top + 34)])
		_rect(a, top - 34, b - a, stone_top - top + 34, k.bricks[0])
		out.append('<g clip-path="url(#%s)">' % id)
		var d := -700.0
		while d < 1000.0:
			_path("M%s %s l800 800" % [_n(a + d), _n(top - 34)], "none", _stroke("#8E3A26", 7) + ' opacity="0.75"')
			_path("M%s %s l-800 800" % [_n(a + d + 800), _n(top - 34)], "none", _stroke("#8E3A26", 7) + ' opacity="0.75"')
			_path("M%s %s l800 800" % [_n(a + d + 7), _n(top - 34)], "none", _stroke("#C46A50", 3) + ' opacity="0.45"')
			d += 110.0
		out.append('</g>')
		# The pavilion's corners, and the shadow it throws on the recessed centre.
		for cx in [a, b - 20.0]:
			_rect(cx, top - 34, 20, stone_top - top + 34, k.bricks[2])
	_rect(l1, top - 20, 10, stone_top - top + 20, "#000000", 'opacity="0.2"')
	_rect(r1 - 10, top - 20, 10, stone_top - top + 20, "#000000", 'opacity="0.14"')
	# ── The centre: three floors of wide windows between brick piers, stone sill bands, decorative brick in the spandrels.
	var floor_h := (stone_top - top - 40.0) / 3.0
	var groups := int((r1 - l1 - 120.0) / 230.0)
	var gap := (r1 - l1 - 60.0) / float(groups)
	for f in 3:
		var fy := stone_top - 26.0 - f * floor_h
		var wh := floor_h * 0.62
		# The sill band runs the whole way across.
		_rect(l1 + 6, fy + 6, r1 - l1 - 12, 8, k.lintel, _stroke(k.lintel_dark, 1.2))
		_snow(l1 + 6, r1 - l1 - 12, fy + 6)
		for g in groups:
			var gx := l1 + 30.0 + g * gap
			var n := 3 if gap > 200.0 else 2
			var ww := (gap - 76.0) / float(n)
			for j in n:
				var wx := gx + j * (ww + 8.0)
				if wx + ww > r1 - 30.0:
					break
				_school_window(wx, fy - wh, ww, wh)
			# A brick pier between the groups, a little proud of the wall.
			if g > 0:
				_rect(gx - 26, fy - floor_h + 10, 14, floor_h, k.bricks[3], 'opacity="0.8"')
		# Between the floors, a course of brick diamonds like the photo's.
		if f < 2:
			var dx := l1 + 40.0
			while dx < r1 - 40.0:
				_path("M%s %s l12 -12 l12 12 l-12 12 z" % [_n(dx), _n(fy - wh - 26)], "#8E3A26", 'opacity="0.5"')
				dx += 40.0
	# ── The centre entrance: stone surround, red double doors, steps, handrails, the flag over the door.
	var cx := (l1 + r1) / 2.0
	var dt := stone_top - 150.0
	_rect(cx - 86, dt - 26, 172, 26, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(cx - 74, dt, 148, base_y - dt, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(cx - 70, dt - 42, 140, 18, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(cx - 52, dt + 16, 104, base_y - dt - 16, "#A8382A", _stroke("#6E2018", 2.5))
	_path("M%s %s V%s" % [_n(cx), _n(dt + 16), _n(base_y)], "none", _stroke("#6E2018", 2))
	for j in 2:
		_rect(cx - 44 + j * 54, dt + 26, 36, 54, "url(#glass)", _stroke("#6E2018", 2))
		_rect(cx - 44 + j * 54, dt + 96, 36, 46, "#8E2C20", _stroke("#6E2018", 1.5))
	# The flagpole with the Québec flag, out over the door.
	_path("M%s %s l54 -16" % [_n(cx + 4), _n(dt - 50)], "none", _stroke("#8E8A82", 4))
	var fx := cx + 18.0
	var fy2 := dt - 60.0
	_rect(fx, fy2, 70, 46, "#1D4F91", _stroke("#143A6E", 1.5))
	_rect(fx + 31, fy2, 8, 46, "#FFFFFF")
	_rect(fx, fy2 + 19, 70, 8, "#FFFFFF")
	for j in 4:
		_path("M%s %s l4 -7 l4 7 l-4 4 z" % [_n(fx + 12 + (j % 2) * 42), _n(fy2 + 12 + int(j / 2) * 26)], "#FFFFFF")
	# Steps down to the sidewalk, with their handrails.
	for i in range(1, 4):
		var w := 150.0 + i * 16.0
		_rect(cx - w / 2, base_y + (i - 1) * 22.0, w, 22, "#BDB7AD", _stroke("#8E8A82", 1.2))
		_rect(cx - w / 2, base_y + (i - 1) * 22.0, w, 3, "#D9D4C8")
	for hx in [cx - 92.0, cx + 86.0]:
		_path("M%s %s L%s %s" % [_n(hx), _n(base_y + 62), _n(hx + 6), _n(dt + 10)], "none", _stroke("#1F1F1F", 4))
	# ── The stone base course along the whole facade, with the basement windows.
	_rect(X0, stone_top, X1 - X0, base_y - stone_top, "#C9C4B8", _stroke("#A39D93", 1.5))
	_rect(X0, stone_top, X1 - X0, 6, "#E2DED4")
	_snow(X0, X1 - X0, stone_top)
	var bx := X0 + 70.0
	while bx < X1 - 90.0:
		if absf(bx - cx) > 110.0:
			_rect(bx, stone_top + 22, 70, 42, "#A8382A", _stroke("#6E2018", 1.5))
			_rect(bx + 5, stone_top + 27, 60, 32, "url(#glass)", 'opacity="0.7"')
		bx += 150.0
	# ── The copper cornice: along the centre, stepping up over each pavilion.
	for c in [[l1 - 6.0, r1 + 6.0, top + 6.0], [X0 - 6.0, l1 + 6.0, top - 34.0], [r1 - 6.0, X1 + 6.0, top - 34.0]]:
		var a: float = c[0]
		var b: float = c[1]
		var cy: float = c[2]
		_rect(a, cy - 10, b - a, 10, copper_light, _stroke(copper_dark, 1.5))
		_rect(a + 4, cy, b - a - 8, 22, copper, _stroke(copper_dark, 2))
		var dt2: float = a + 10.0
		while dt2 < b - 14.0:
			_rect(dt2, cy + 3, 7, 16, copper_dark, 'opacity="0.45"')
			dt2 += 20.0
		_rect(a, cy + 22, b - a, 7, copper_dark)
		_rect(a + 4, cy + 29, b - a - 8, 26, "url(#drop)")
		_snow(a, b - a, cy - 10)
	# ── Over the entrance: the stone cartouche on the parapet and the cross.
	_rect(cx - 104, top - 30, 208, 36, k.bricks[1], _stroke("#7E3424", 1.5))
	_rect(cx - 110, top - 40, 220, 12, copper, _stroke(copper_dark, 1.5))
	_path("M%s %s q%s -26 %s 0 z" % [_n(cx - 54), _n(top - 2), _n(54), _n(108)], k.lintel, _stroke(k.lintel_dark, 1.5))
	_circle(cx, top - 14, 9, k.lintel, _stroke(k.lintel_dark, 1.2))
	_rect(cx - 5, top - 96, 10, 58, copper_light, _stroke(copper_dark, 1.5))
	_rect(cx - 19, top - 82, 38, 10, copper_light, _stroke(copper_dark, 1.5))
	_snow(cx - 110, 220, top - 40)
	_foundation()
	_fence([])


# A school window: a tall dark-framed sash with a transom, a stone sill under it (reference/coin_dandurand).
func _school_window(x: float, y: float, w: float, h: float) -> void:
	_rect(x - 5, y + h, w + 10, 9, k.lintel, _stroke(k.lintel_dark, 1.2))
	_snow(x - 5, w + 10, y + h)
	_rect(x, y, w, h, "#2E2A26", _stroke("#1A1714", 1.5))
	_rect(x + 3, y + 3, w - 6, h * 0.26, "#6E8898")
	_rect(x + 3, y + h * 0.3, w - 6, h * 0.68 - 3, "#60808F")
	_rect(x + 3, y + h * 0.3, w - 6, h * 0.3, "#89A4B0", 'opacity="0.8"')
	var bar := x + w / 2.0
	_rect(bar - 1.5, y + 3, 3, h - 6, "#2E2A26")
	_rect(x + 3, y + h * 0.26 + 2, w - 6, 3, "#2E2A26")
	# The light caught in the top corner of the glass.
	_path("M%s %s l%s 0 l%s %s z" % [_n(x + 4), _n(y + 5), _n(w * 0.5), _n(-w * 0.5), _n(h * 0.42)], "#FFFFFF", 'opacity="0.3"')


# Grey stone quoins down a corner of the wall, alternating long and short.
func _quoins(x: float, dir: float, y0: float, y1: float) -> void:
	var y := y0
	var i := 0
	while y < y1 - 4.0:
		var w := 44.0 if i % 2 == 0 else 28.0
		var h := minf(26.0, y1 - y)
		_rect(x if dir > 0.0 else x - w, y, w, h - 3, _pick(["#9E9A92", "#A8A49C", "#8F8B84"]), _stroke("#76726B", 1))
		y += 29.0
		i += 1


# A row of bricks set on end, just under the roof line, with a corbelled course above it.
func _soldier_course(y: float) -> void:
	_rect(X0, y, X1 - X0, 30, k.mortar)
	var x := X0 + 1.0
	while x < X1:
		_rect(x, y + 1, minf(12.0, X1 - x), 28, _pick(k.bricks))
		x += 14.0
	_rect(X0 - 4, y - 8, X1 - X0 + 8, 9, _pick(k.bricks), _stroke("#3E2420", 1))
	_rect(X0, y + 30, X1 - X0, 8, "#000000", 'opacity="0.15"')


# Wrought-iron railing with S-scrolls between two posts.
func _scroll_railing(x0: float, x1: float, top: float, bottom: float) -> void:
	var st := _stroke("#1F1F1F", 3) + ' fill="none" stroke-linecap="round"'
	_rect(x0, top, x1 - x0, 5, "#1F1F1F")
	_rect(x0, bottom - 5, x1 - x0, 5, "#1F1F1F")
	# Panels of two mirrored curls rising from the bottom rail into a lyre, with a ring between them.
	var h := bottom - top
	var pw := 52.0
	var x := x0 + 6.0
	while x + pw <= x1 - 6.0:
		var c := x + pw / 2.0
		for side in [-1.0, 1.0]:
			out.append('<path d="M%s %s C%s %s %s %s %s %s c%s 0 %s %s %s %s" %s/>' % [
				_n(c), _n(bottom - 5), _n(c + side * 22), _n(bottom - h * 0.35), _n(c + side * 24), _n(top + h * 0.2), _n(c + side * 10), _n(top + h * 0.22),
				_n(-side * 8), _n(-side * 10), _n(h * 0.18), _n(side * -2), _n(h * 0.2), st])
		_circle(c, top + h * 0.55, 3.5, "none", _stroke("#1F1F1F", 2.5))
		out.append('<path d="M%s %s v%s" %s/>' % [_n(x + pw), _n(top + 4), _n(h - 8), st])
		x += pw
	for px in [x0, x1 - 6]:
		_rect(px, top - 6, 6, h + 6, "#1F1F1F")


# ── Dépanneur Xin-Xin, its side on 6e Avenue ───────────────────────────────
# From reference/coin_dandurand/coin_dépanneur_sur_6eme_coin_dandurand.jpg: old variegated brick with burnt
# headers, patched mortar and soot running down from the parapet; quoins at the corner; a parged concrete base
# with its barred vent; and the one big shop window — the shop lit behind the glass, its dropped ceiling, tubes,
# shelves and packs, the security grid over the lower two thirds and the posters taped along the bottom — under
# a rough granite lintel on a projecting sill. Round the corner the Dandurand balcony's white soffit, its
# scrolled railing and the green corrugated awning poke out past the building's edge.
func _depanneur_side() -> void:
	var top := _top()
	var concrete := base_y - 84.0
	_bricks(top, concrete)
	_brick_wear(top, concrete)
	_soldier_course(top + 2.0)
	_wall_shading(top)
	_flat_parapet(top)
	_quoins(X0, 1.0, top + 4.0, concrete)
	_depanneur_base(concrete)
	_depanneur_window(286.0, concrete - 22.0)
	_depanneur_fittings(top, concrete)
	_depanneur_corner(top)


# A wall that has stood there a hundred years: single headers fired almost black, patches of fresher mortar,
# pale washes between the courses, soot run down from under the parapet, and the weep holes along the bottom.
func _brick_wear(y0: float, y1: float) -> void:
	var row := 0
	var y := y0
	while y < y1 - 12.0:
		var x := X0 - (18.0 if row % 2 == 1 else 0.0)
		while x < X1:
			if rng.randf() < 0.06:
				var bx := maxf(x, X0)
				var bw := minf(x + 34.0, X1) - bx
				if bw > 3.0:
					_rect(bx, y, bw, 11, _pick(["#3A211C", "#48291F", "#2C1915"]))
			x += 36.0
		y += 13.0
		row += 1
	for i in 3:
		var pw := rng.randf_range(100.0, 240.0)
		_rect(rng.randf_range(X0, X1 - pw), rng.randf_range(y0 + 40.0, y1 - 70.0), pw,
			rng.randf_range(15.0, 42.0), "#CCC2B4", 'opacity="0.2"')
	for i in 6:
		var ew := rng.randf_range(14.0, 36.0)
		_rect(rng.randf_range(X0 + 10.0, X1 - ew - 10.0), rng.randf_range(y0 + 30.0, y1 - 160.0), ew,
			rng.randf_range(60.0, 150.0), "#EAE2D6", 'opacity="0.1"')
	# Soot washed down from under the parapet, wider at the top.
	for i in 7:
		var sw := rng.randf_range(16.0, 46.0)
		var sx := rng.randf_range(X0 + 6.0, X1 - sw - 6.0)
		var sh := rng.randf_range(70.0, 200.0)
		_path("M%s %s h%s l%s %s h%s z" % [_n(sx), _n(y0), _n(sw), _n(-sw * 0.3), _n(sh), _n(-sw * 0.4)],
			"#231713", 'opacity="0.1"')
	var wx := X0 + 46.0
	while wx < X1 - 30.0:
		_rect(wx, y1 - 11.0, 4, 9, "#2A1A16", 'opacity="0.5"')
		wx += 74.0


# The parged concrete base: trowelled render with a drip course at its top, old water stains, a crack running
# down from it, the hose bib, and the basement vent recessed in its frame.
func _depanneur_base(concrete: float) -> void:
	_rect(X0, concrete, X1 - X0, ground_y - concrete, "#A8A49D")
	for i in 9:
		_rect(rng.randf_range(X0, X1 - 70.0), rng.randf_range(concrete + 20.0, ground_y - 26.0),
			rng.randf_range(34.0, 100.0), rng.randf_range(8.0, 26.0), "#8E8A83", 'opacity="0.3"')
	for i in 4:
		_rect(rng.randf_range(X0 + 30.0, X1 - 40.0), concrete + 10, rng.randf_range(10.0, 26.0),
			rng.randf_range(26.0, 62.0), "#7E7A73", 'opacity="0.2"')
	# Trowel marks left in the render, and the grime where it meets the sidewalk.
	for i in 14:
		var tw := rng.randf_range(40.0, 130.0)
		_path("M%s %s h%s" % [_n(rng.randf_range(X0, X1 - tw)), _n(rng.randf_range(concrete + 14.0, ground_y - 16.0)), _n(tw)],
			"none", _stroke("#B8B4AD", 2) + ' opacity="0.5"')
	_path("M%s %s l6 18 l-5 16 l7 22 l-3 16" % [_n(X0 + 92.0), _n(concrete + 12)], "none", _stroke("#7A766F", 2))
	_rect(X0, ground_y - 20, X1 - X0, 20, "#000000", 'opacity="0.1"')
	_rect(X0, ground_y - 9, X1 - X0, 9, "#6E6A64", 'opacity="0.35"')
	# The drip course capping the render.
	_rect(X0 - 4, concrete - 8, X1 - X0 + 8, 11, "#BFBBB3", _stroke("#8E8A83", 1))
	_rect(X0 - 4, concrete - 8, X1 - X0 + 8, 3, "#D2CEC6")
	_rect(X0 - 4, concrete + 3, X1 - X0 + 8, 5, "#000000", 'opacity="0.16"')
	_snow(X0 - 4, X1 - X0 + 8, concrete - 8)
	# The hose bib.
	_rect(X1 - 74, concrete + 32, 7, 18, "#8E918E")
	_circle(X1 - 70.5, concrete + 30, 7, "#B9BCB8", _stroke("#7E817E", 1.5))
	# The basement vent: a frame set into the render, its grille deep behind.
	var vx := X1 - 248.0
	var vy := concrete + 56.0
	_rect(vx - 6, vy - 6, 172, 90, "#8E8A83", _stroke("#75716B", 1.5))
	_rect(vx, vy, 160, 78, "#3A3835")
	var gx := vx + 6.0
	while gx < vx + 154.0:
		_rect(gx, vy + 6, 2, 66, "#56534E")
		gx += 7.0
	var gy := vy + 8.0
	while gy < vy + 72.0:
		_rect(vx + 6, gy, 148, 2, "#56534E")
		gy += 7.0
	_rect(vx, vy, 160, 7, "#000000", 'opacity="0.4"')


# The one big shop window, `wy` to `wb`: the granite lintel, the white painted wood frame and mullion, the lit
# shop behind the glass, the security grid over the lower two thirds, the posters along the bottom, the street
# caught in the pane, and the projecting concrete sill.
func _depanneur_window(wy: float, wb: float) -> void:
	var wx := 214.0
	var ww := 306.0
	var wh := wb - wy
	# Rough granite lintel, projecting, with its shadow thrown on the brick below.
	_rect(wx - 30, wy - 48, ww + 60, 40, "#938F89", _stroke("#6E6B66", 1.5))
	_rect(wx - 30, wy - 48, ww + 60, 7, "#AEAAA4")
	for i in 80:
		_circle(rng.randf_range(wx - 26.0, wx + ww + 26.0), rng.randf_range(wy - 44.0, wy - 12.0),
			rng.randf_range(0.9, 2.2), _pick(["#625F5A", "#B7B3AD", "#7E7B76", "#565350"]))
	_rect(wx - 30, wy - 9, ww + 60, 8, "#000000", 'opacity="0.2"')
	_snow(wx - 30, ww + 60, wy - 48)
	# The glass, and the shop's own light behind it.
	_rect(wx - 10, wy - 10, ww + 20, wh + 20, "#EEEADF", _stroke("#B9B3A8", 2))
	_rect(wx, wy, ww, wh, "#2F3A41")
	_shop_glass_glow(wx, wy, ww, wh, 613)
	# The dropped ceiling and its fluorescent tubes, deep inside.
	_rect(wx + 2, wy + 2, ww - 4, 18, "#C9C4B6", 'opacity="0.5"')
	for tx in [wx + 20.0, wx + ww * 0.54]:
		_rect(tx, wy + 24, ww * 0.34, 7, "#FFF6D8", 'opacity="0.85"')
		_rect(tx, wy + 31, ww * 0.34, 6, "#FFE9A8", 'opacity="0.35"')
	# Shelves of tins, bottles and boxes against the glass, and the blue packs stacked at the back.
	_shop_glass_goods(wx + 4, wy + 36, ww - 8, 104.0, 613, 2)
	for i in 3:
		_rect(wx + ww - 84, wy + 46 + i * 17.0, 62, 15, "#4C9BD8", _stroke("#2F6FA8", 1))
		_rect(wx + ww - 78, wy + 50 + i * 17.0, 26, 7, "#F2F6FA", 'opacity="0.75"')
	# The security grid behind the glass, over the lower two thirds.
	var gt := wy + wh * 0.3
	var gh := wh * 0.56
	var lx := wx + 8.0
	while lx < wx + ww - 6.0:
		_rect(lx, gt, 2.5, gh, "#EFF3F6", 'opacity="0.75"')
		lx += 24.0
	var ly := gt
	while ly < gt + gh:
		_rect(wx + 6, ly, ww - 12, 2.5, "#EFF3F6", 'opacity="0.75"')
		ly += 24.0
	# The posters taped along the bottom of the pane.
	var py := wy + wh * 0.58
	var ph := wh * 0.42 - 8.0
	# A peach one with a face on it.
	_rect(wx + 12, py - 24, 64, ph + 20, "#F2A27A", _stroke("#C46A44", 1.5))
	_circle(wx + 44, py + 10, 21, "#E8743A")
	_circle(wx + 44, py + 7, 14, "#F7CBA6")
	_path("M%s %s q6 7 12 0" % [_n(wx + 38), _n(py + 12)], "none", _stroke("#C4503A", 2.5))
	_rect(wx + 20, py + ph - 6, 48, 5, "#FBE3CE", 'opacity="0.8"')
	# A yellow one with its green band and its lines of red writing.
	_rect(wx + 84, py - 4, 70, ph, "#F2D23A", _stroke("#C9A820", 1.5))
	_rect(wx + 90, py + 4, 58, 8, "#2E8B47")
	for i in 3:
		_rect(wx + 90, py + 20 + i * 11.0, 54.0 - i * 12.0, 5, "#C8202A")
	# The juice ad: oranges and three slim cans.
	_rect(wx + 162, py - 12, 130, ph + 8, "#F29B30", _stroke("#C4701A", 1.5))
	for o in [[26.0, 44.0, 14.0], [58.0, 56.0, 12.0], [92.0, 42.0, 13.0], [114.0, 58.0, 11.0]]:
		_circle(wx + 162 + o[0], py + o[1], o[2], "#F57C1F", _stroke("#C45A12", 1.5))
		_path("M%s %s q7 -6 12 -1" % [_n(wx + 162 + o[0] - 2), _n(py + o[1] - o[2])], "none", _stroke("#4E8A3A", 2.5))
	for i in 3:
		var cx2 := wx + 176.0 + i * 20.0
		_rect(cx2, py + 2, 14, 38, "#F7D98E", 'rx="3" ' + _stroke("#C49A3A", 1))
		_rect(cx2 + 1, py + 14, 12, 9, "#E8542F")
	# The white mullion down the middle, the street in the glass, and the frame's peeling paint.
	_rect(wx + ww / 2 - 5, wy, 10, wh, "#EEEADF", _stroke("#C3BCB0", 1))
	_shop_glass_shine(wx, wy, ww, wh)
	for i in 10:
		_rect((wx - 9.0) if i % 2 == 0 else (wx + ww + 1.0), rng.randf_range(wy, wb - 14.0),
			8, rng.randf_range(6.0, 20.0), "#C0B7A8", 'opacity="0.5"')
	# The projecting concrete sill.
	_rect(wx - 22, wb + 8, ww + 44, 16, "#B5B1A9", _stroke("#8A8780", 1.5))
	_rect(wx - 22, wb + 8, ww + 44, 5, "#C8C4BC")
	_rect(wx - 22, wb + 24, ww + 44, 7, "#000000", 'opacity="0.18"')
	_snow(wx - 22, ww + 44, wb + 8)


# What is screwed to the side wall: the meter on its board with the service mast going up to the roof, the
# cable sagging in from the pole, and two old anchor plates where a sign used to hang.
func _depanneur_fittings(top: float, concrete: float) -> void:
	var mx := 96.0
	_path("M%s %s Q%s %s %s %s" % [_n(X1 - 6), _n(top + 26), _n((mx + X1) / 2.0), _n(top + 104),
		_n(mx + 26), _n(top + 58)], "none", _stroke("#1F1F1F", 3))
	_rect(mx + 15, top + 40, 6, concrete - 166 - top - 40, "#8E918E")
	_path("M%s %s q1 -20 24 -22" % [_n(mx + 18), _n(top + 46)], "none", _stroke("#8E918E", 6))
	for sy in [top + 100.0, top + 200.0, top + 300.0]:
		_rect(mx + 11, sy, 14, 5, "#6E716E")
	_rect(mx - 6, concrete - 172, 52, 66, "#6E5A44", _stroke("#4E3F2E", 1.5))
	_rect(mx, concrete - 166, 40, 52, "#B9BCB8", _stroke("#7E817E", 1.5))
	_rect(mx + 5, concrete - 161, 30, 20, "#D7DAD6", _stroke("#8E918E", 1))
	_circle(mx + 20, concrete - 132, 10, "#E9ECE6", _stroke("#7E817E", 1))
	_rect(mx + 17, concrete - 114, 6, 114, "#8E918E")


# Round the corner from Dandurand: the balcony's white soffit and its scrolled railing on black posts, with the
# green corrugated awning over them, poking out past the corner of the building.
func _depanneur_corner(top: float) -> void:
	var by := _fb(1) + 10.0
	_rect(0, by, 132, 20, "#ECEAE4", _stroke("#B5B1A8", 1.5))
	for i in 5:
		_rect(rng.randf_range(0.0, 104.0), by + rng.randf_range(3.0, 13.0), rng.randf_range(16.0, 40.0), 3,
			"#B9B2A4", 'opacity="0.55"')
	_rect(0, by + 20, 132, 18, "url(#drop)")
	_scroll_railing(0, 126, by - 64, by)
	_snow(0, 126, by - 64)
	for px in [4.0, 120.0]:
		_rect(px, top + 34, 7, by - top - 34, "#1F1F1F")
	_path("M0 %s L152 %s L152 %s L0 %s Z" % [_n(top - 20), _n(top + 14), _n(top + 50), _n(top + 16)],
		"#3E8C5A", _stroke("#2A6340", 2))
	var rx := 6.0
	while rx < 152.0:
		_path("M%s %s l0 34" % [_n(rx), _n(top - 18 + rx * 34.0 / 152.0)], "none", _stroke("#2A6340", 2.5))
		rx += 11.0
	_path("M0 %s L152 %s" % [_n(top + 16), _n(top + 50)], "none", _stroke("#F2F0EA", 4))
	_rect(0, top + 50, 152, 22, "url(#drop)")


# Dépanneur Xin-Xin's front on Dandurand: under a long balcony (scrolled railing, white soffit, green corrugated
# awning on top), a white sign band with the blue shop sign in the middle (text added in the game) between two
# red banners; below, two shop windows full of posters on either side of a glass door behind a grille, two air
# conditioners over the door, the civic number, concrete steps with a handrail, white quoins at the corners.
func _depanneur_front() -> void:
	var top := _top()
	_bricks(top, base_y)
	_wall_shading(top)
	_flat_parapet(top)
	for x in [X0, X1]:
		var y := top + 4.0
		var i := 0
		while y < base_y - 6.0:
			var w := 34.0 if i % 2 == 0 else 22.0
			_rect(x if x == X0 else x - w, y, w, 22, "#E8E4DA", _stroke("#B5B0A6", 1))
			y += 26.0
			i += 1
	_foundation()
	# Upstairs windows, half hidden by the balcony.
	for wx in [120.0, 540.0]:
		_window(wx, _win_y(1), 110.0, 150.0)
	# Green corrugated awning over the balcony.
	var ay := top + 6.0
	_path("M%s %s H%s L%s %s H%s Z" % [_n(X0 - 16), _n(ay), _n(X1 + 16), _n(X1 + 24), _n(ay + 30), _n(X0 - 24)], "#3E8C5A", _stroke("#2A6340", 2))
	var rx := X0 - 14.0
	while rx < X1 + 20.0:
		_path("M%s %s V%s" % [_n(rx), _n(ay + 2), _n(ay + 28)], "none", _stroke("#2A6340", 2))
		rx += 10.0
	_rect(X0 - 24, ay + 28, X1 - X0 + 48, 5, "#F2F0EA")
	_rect(X0 - 20, ay + 33, X1 - X0 + 40, 26, "url(#drop)")
	_snow(X0 - 16, X1 - X0 + 32, ay)
	# Balcony: posts, scrolled railing, white peeling soffit.
	var slab := _fb(1) + 18.0
	for px in [X0 + 6.0, X1 - 12.0]:
		_rect(px, ay + 30, 6, slab - ay - 30, "#1F1F1F")
	_scroll_railing(X0 + 4, X1 - 4, slab - 64, slab)
	_rect(X0 - 10, slab, X1 - X0 + 20, 26, "#E8E4D8", _stroke("#B9B5AC", 1.5))
	for i in 9:
		_rect(rng.randf_range(X0, X1 - 60), slab + rng.randf_range(4, 18), rng.randf_range(20, 60), 4, "#B9B2A4", 'opacity="0.6"')
	for tx in [X0 + 60.0, X0 + 250.0, X1 - 300.0, X1 - 110.0]:
		_rect(tx, slab + 18, 70, 5, "#FFF8E0")
		_circle(tx + 35, slab + 24, 26, "url(#glow)")
	_rect(X0 - 10, slab + 26, X1 - X0 + 20, 34, "url(#drop)")
	_snow(X0 + 4, X1 - X0 - 8, slab - 64)
	# Sign band: red banners either side of the blue shop sign (its text is a label in the game).
	var band := slab + 30.0
	_rect(X0 + 6, band, X1 - X0 - 12, 62, "#F4F2EC", _stroke("#B9B5AC", 1.5))
	for b in [[X0 + 14, 230.0], [X1 - 244, 230.0]]:
		_rect(b[0], band + 6, b[1], 50, "#FBFAF6", _stroke("#C8202A", 2))
	_rect(260, band + 4, 260, 54, "#25408F", _stroke("#16285C", 2))
	_rect(X0 + 10, band + 62, X1 - X0 - 20, 4, "#FFF8D6", 'opacity="0.9"')
	# Shop windows with their posters.
	var wy := band + 82.0
	var wb := _fb(0) - 6.0
	for win in [[X0 + 36, 250.0], [X1 - 286, 250.0]]:
		_rect(win[0] - 6, wy - 6, win[1] + 12, wb - wy + 12, "#F2F0EA", _stroke("#B9B5AC", 2))
		_rect(win[0], wy, win[1], wb - wy, "#3E4A52")
		_shop_glass_glow(win[0], wy, win[1], wb - wy, int(win[0]) * 31 + 7)
		var gx: float = win[0] + 10.0
		while gx < win[0] + win[1] - 6:
			_rect(gx, wy + 4, 2, wb - wy - 8, "#E9EEF2", 'opacity="0.5"')
			gx += 22.0
	# Left window: the big green beer poster ("Plus qu'une course", its words a label in the game), two green bottles on it.
	var lx: float = X0 + 76.0
	_rect(lx, wy + 30, 170, wb - wy - 40, "#1E7A44", _stroke("#0E4A28", 2))
	_rect(lx + 8, wy + 40, 154, 50, "#2E9A5A")
	for bx in [lx + 24.0, lx + 50.0]:
		_rect(bx, wy + 110, 18, 74, "#3EAA5E", 'rx="6"')
		_rect(bx + 5, wy + 94, 8, 20, "#3EAA5E")
		_rect(bx + 2, wy + 134, 14, 18, "#F2F0EA")
	_path("M%s %s q30 18 60 0 q20 -10 40 0" % [_n(lx + 86), _n(wy + 170)], "none", _stroke("#F2C230", 5))
	# Right window: the shop behind the security grille, the Coors Light neon (a logo in the game), a pink poster.
	var rxw: float = X1 - 280.0
	_shop_glass_goods(rxw, wy + 60, 240, wb - wy - 70, int(rxw) * 31 + 7, 2)
	_rect(rxw + 170, wy + 90, 46, 90, "#E86A8E", _stroke("#A83A5E", 1.5))
	var grx := rxw + 4.0
	while grx < rxw + 246.0:
		_rect(grx, wy + 50, 2.5, wb - wy - 54, "#E9EEF2", 'opacity="0.85"')
		grx += 20.0
	var gry := wy + 50.0
	while gry < wb - 4.0:
		_rect(rxw, gry, 250, 2.5, "#E9EEF2", 'opacity="0.85"')
		gry += 20.0
	for win in [[X0 + 36, 250.0], [X1 - 286, 250.0]]:
		_shop_glass_shine(win[0], wy, win[1], wb - wy)
	# Air conditioners over the door, the door behind its grille, the civic number.
	var dx := 390.0
	for ax in [dx - 74.0, dx + 6.0]:
		_rect(ax, wy - 14, 66, 40, "#F2F2EF", _stroke("#A9A398", 1.5))
		for gy in range(0, 4):
			_rect(ax + 6, wy - 8 + gy * 8, 54, 3, "#C9C5BC")
	# A full-height shop door, down to the top step.
	var dt := wy + 28.0
	var db := _fb(0) + 33.0
	_rect(dx - 60, dt, 120, db - dt, "#F2F0EA", _stroke("#B9B5AC", 2))
	_rect(dx - 52, dt + 8, 104, db - dt - 8, "#3E4A52")
	var gy2 := dt + 16.0
	while gy2 < db - 6:
		_rect(dx - 48, gy2, 96, 2.5, "#E9EEF2")
		gy2 += 16.0
	var gx2 := dx - 46.0
	while gx2 < dx + 48:
		_rect(gx2, dt + 10, 2.5, db - dt - 14, "#E9EEF2")
		gx2 += 16.0
	_rect(dx - 20, dt + 62, 40, 26, "#F4F2EC")
	_rect(dx + 34, dt + (db - dt) * 0.55, 6, 22, "#B9BEC4", 'rx="2"')
	# Concrete steps with a handrail.
	for i in range(1, 3):
		var w := 150.0 + i * 20.0
		_rect(dx - w / 2, _fb(0) + i * 33.0, w, 33, "#A8A49C", _stroke("#7E7A72", 1.5))
		_rect(dx - w / 2, _fb(0) + i * 33.0, w, 4, "#C9C5BC")
		if season == "winter":
			_rect(dx - w / 2 + 6, _fb(0) + i * 33.0 - 2, w - 12, 5, "#F7F9FB")
	_path("M%s %s L%s %s" % [_n(dx + 50), _n(_fb(0) - 40), _n(dx + 96), _n(ground_y - 50)], "none", _stroke("#E8E4DA", 5) + ' stroke-linecap="round"')
	_rect(dx + 92, ground_y - 54, 5, 54, "#E8E4DA")
	# The little white picket fence at the left, along the next lot.
	var px := X0 + 4.0
	while px < X0 + 150.0:
		_path("M%s %s V%s L%s %s L%s %s V%s Z" % [_n(px), _n(ground_y - 2), _n(ground_y - 60), _n(px + 5), _n(ground_y - 68), _n(px + 10), _n(ground_y - 60), _n(ground_y - 2)], "#F4F2EC", _stroke("#B9B5AC", 1))
		px += 16.0
	_rect(X0, ground_y - 46, 152, 5, "#F4F2EC", _stroke("#B9B5AC", 1))
	# Glass blocks low on the left, and Halloween by the steps.
	for i in 4:
		_rect(X0 + 40 + i * 22, base_y + 18, 20, 20, "#D6EAF5", _stroke("#9AB8C8", 1))
	if k.halloween:
		_pumpkin(dx - 110, ground_y, 1.0, true)
		_pumpkin(dx + 120, ground_y, 0.8, false)


# The two-storey garage building: on the left a white door under an arched fanlight, a small barred window
# and a grey door with a tag; on the right two white garage doors (glass lights in one, dark windows and a
# no-parking disc in the other) with the "défense de stationner" sign between, a round wall lamp, quoins,
# and above them a wooden balcony on iron brackets with a scrolled railing in front of a grilled window.
func _garages() -> void:
	var top := _top()
	_bricks(top, ground_y - 8)
	_wall_shading(top)
	_flat_parapet(top)
	_quoins(X1, -1.0, top + 4.0, ground_y - 8)
	_rect(X0, ground_y - 10, X1 - X0, 10, "#9E9A92")
	var door_top := ground_y - 150.0
	# Left: white door with fanlight and step.
	var dx := 80.0
	_path("M%s %s V%s A34 34 0 0 1 %s %s V%s Z" % [_n(dx - 6), _n(ground_y - 8), _n(door_top - 4), _n(dx + 62), _n(door_top - 4), _n(ground_y - 8)], "#F2F0EA", _stroke("#B9B5AC", 2))
	_path("M%s %s A28 28 0 0 1 %s %s Z" % [_n(dx), _n(door_top - 4), _n(dx + 56), _n(door_top - 4)], "url(#glass)")
	_rect(dx, door_top, 56, 142, "#F7F6F2", _stroke("#B9B5AC", 1.5))
	_rect(dx + 12, door_top + 16, 32, 46, "url(#glass)")
	_circle(dx + 46, door_top + 80, 3, "#8E8A83")
	_rect(dx - 14, ground_y - 12, 84, 12, "#A8A49C", _stroke("#7E7A72", 1))
	_rect(170, ground_y - 120, 46, 34, "#3E4A52", _stroke("#B9B5AC", 3))
	for gx in [181.0, 193.0, 205.0]:
		_rect(gx, ground_y - 118, 2, 30, "#E9EEF2")
	var mx := 240.0
	_rect(mx, door_top + 6, 68, 136, "#8E9296", _stroke("#5E6266", 2))
	_path("M%s %s c8 -14 16 -2 10 8 c-6 10 10 14 16 0 M%s %s c6 6 14 -4 20 4" % [_n(mx + 10), _n(door_top + 70), _n(mx + 14), _n(door_top + 100)], "none", _stroke("#F4F4F4", 2.5) + ' stroke-linecap="round"')
	_rect(mx + 6, door_top - 36, 56, 26, "#C7C3BA", _stroke("#8E8A83", 1.5))
	_soldier_course(top + 2.0)
	# Upstairs on the left: three tall windows under segmental brick arches, stone sills.
	for wx in [70.0, 166.0, 252.0]:
		var wy := _win_y(1) + 6.0
		_path("M%s %s Q%s %s %s %s" % [_n(wx - 8), _n(wy + 6), _n(wx + 31), _n(wy - 22), _n(wx + 70), _n(wy + 6)], "none", _stroke("#4A2A26", 14))
		_path("M%s %s Q%s %s %s %s" % [_n(wx - 8), _n(wy + 6), _n(wx + 31), _n(wy - 22), _n(wx + 70), _n(wy + 6)], "none", _stroke("#86503E", 10) + ' stroke-dasharray="6 2"')
		_rect(wx - 3, wy - 3, 68, 140, "#B9B5AC")
		_rect(wx, wy, 62, 134, "#F2F0EA")
		_rect(wx + 6, wy + 6, 50, 122, "url(#glass)")
		_rect(wx + 6, wy + 50, 50, 4, "#F2F0EA")
		_rect(wx + 6, wy + 6, 50, 10, "url(#drop)")
		_rect(wx - 8, wy + 136, 78, 9, "#A8A49C", _stroke("#7E7A72", 1))
	# Garage doors.
	var doors := [[350.0, 150.0, 160.0, 4], [540.0, 170.0, 190.0, 5]]
	for gi in doors.size():
		var g: Array = doors[gi]
		var x: float = g[0]
		var w: float = g[1]
		var h: float = g[2]
		var y := ground_y - 8 - h
		_rect(x - 8, y - 8, w + 16, h + 8, "#F2F0EA", _stroke("#B9B5AC", 2))
		_rect(x, y, w, h, "#ECEBE6", _stroke("#B5B1A8", 1.5))
		var cols: int = g[3]
		for c in cols:
			var cx := x + 6 + c * (w - 12) / cols
			var cw := (w - 12) / cols - 6
			_rect(cx, y + 8, cw, 26, "url(#glass)" if gi == 0 else "#2E3236", _stroke("#B5B1A8", 1))
			for r in 3:
				_rect(cx, y + 44 + r * ((h - 52) / 3.0), cw, (h - 52) / 3.0 - 6, "none", _stroke("#C9C5BC", 1.5))
		for i in 4:
			_rect(rng.randf_range(x + 6, x + w - 30), rng.randf_range(y + 50, ground_y - 30), rng.randf_range(10, 30), rng.randf_range(3, 8), "#B5B1A8", 'opacity="0.5"')
	_circle(560.0 + 34, ground_y - 8 - 190 + 92, 14, "#FFFFFF", _stroke("#1E1E1E", 1.5))
	_circle(594, ground_y - 106, 11, "none", _stroke("#C8202A", 3))
	_path("M586 %s l16 -16" % _n(ground_y - 98), "none", _stroke("#C8202A", 3))
	_rect(620, ground_y - 122, 24, 32, "#4FB0E8")
	_rect(624, ground_y - 112, 16, 10, "#F2D23A")
	# "Défense de stationner en tout temps".
	_rect(500, ground_y - 8 - 190 - 4, 56, 30, "#FFFFFF", _stroke("#9A968E", 1))
	for i in 3:
		_rect(506, ground_y - 8 - 190 + 2 + i * 8, 44, 3, "#C8202A")
	# Round wall lamp.
	_path("M%s %s a14 14 0 0 1 0 28 z" % [_n(X1 - 36), _n(ground_y - 150)], "#8E8A83", _stroke("#5E5A55", 1.5))
	# White gutter pipe, then the wooden balcony on iron brackets, the grilled window behind its railing.
	_rect(330, ground_y - 230, X1 - 330, 9, "#ECEAE4", _stroke("#B9B5AC", 1))
	var deck := _fb(1) + 18.0
	# The balcony door: glazed, behind a black grille of scrolls.
	_path("M462 %s Q535 %s 608 %s" % [_n(deck - 196), _n(deck - 222), _n(deck - 196)], "none", _stroke("#4A2A26", 14))
	_rect(470, deck - 196, 130, 196, "#F2F0EA", _stroke("#B9B5AC", 2))
	_rect(478, deck - 188, 54, 186, "url(#glass)")
	_rect(538, deck - 188, 54, 186, "url(#glass)")
	_rect(478, deck - 188, 114, 14, "url(#drop)")
	for cx in [505.0, 565.0]:
		for cy in [deck - 160.0, deck - 110.0]:
			_path("M%s %s c-14 -10 -14 -26 0 -22 c14 -4 14 12 0 22 z" % [_n(cx), _n(cy)], "none", _stroke("#1F1F1F", 2.5))
			_circle(cx, cy + 14, 5, "none", _stroke("#1F1F1F", 2.5))
	_scroll_railing(360, X1 - 4, deck - 70, deck)
	_rect(350, deck, X1 - 346, 30, "#8A6440", _stroke("#5E4228", 1.5))
	var pl := 356.0
	while pl < X1 - 4:
		_rect(pl, deck + 2, 2, 26, "#6E4E32")
		pl += 14.0
	_rect(350, deck + 30, X1 - 346, 22, "url(#drop)")
	for bx in [380.0, 520.0, 680.0]:
		_path("M%s %s L%s %s L%s %s" % [_n(bx), _n(deck + 30), _n(bx + 40), _n(deck + 140), _n(bx + 40), _n(deck + 30)], "none", _stroke("#1F1F1F", 4) + ' stroke-linejoin="round"')


# The green lane seen from its entrance, in perspective toward (cx, 470): brick side walls (pipes and a
# tag on the left, a colourful mural on the right), a leafy concrete path, a big white planter with black
# dots, a wooden planter box, a red pole carrying the "Ruelle verte" sign (text added in the game) and
# orange trees arching over it all.
func _ruelle_verte() -> void:
	const TREE_SEED := 41
	var vp := Vector2(k.width / 2.0, 470.0)
	var at := func(p: Vector2, d: float) -> Vector2: return vp + (p - vp) * (1.0 - d)
	var poly := func(pts: Array, fill: String, extra := "") -> void:
		var parts := PackedStringArray()
		for i in pts.size():
			parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(pts[i].x), _n(pts[i].y)])
		_path(" ".join(parts) + " Z", fill, extra)
	var far := 0.68
	var l0 := Vector2(X0, 60)
	var r0 := Vector2(X1, 60)
	var gl := Vector2(X0, ground_y)
	var gr := Vector2(X1, ground_y)
	_lane_through(vp, 1.0 - far)
	# Concrete path, darker at the entrance, with a joint across it.
	poly.call([gl, gr, at.call(gr, far), at.call(gl, far)], "#A8A49C")
	poly.call([gl, gr, at.call(gr, 0.25), at.call(gl, 0.25)], "#9A968E")
	_path("M%s %s L%s %s" % [_n(at.call(gl, 0.25).x), _n(at.call(gl, 0.25).y), _n(at.call(gr, 0.25).x), _n(at.call(gr, 0.25).y)], "none", _stroke("#7E7A72", 2))
	_lane_ground_detail(vp, far)
	var mh: Vector2 = at.call(Vector2(vp.x, ground_y), 0.45)
	out.append('<ellipse cx="%s" cy="%s" rx="16" ry="5" fill="#6E6A62" stroke="#55524C" stroke-width="1.5"/>' % [_n(mh.x), _n(mh.y)])
	# Side walls.
	for side in [[l0, gl, "#7E4E3E", "#6A4033"], [r0, gr, "#93604A", "#7A4E3C"]]:
		poly.call([side[0], at.call(side[0], far), at.call(side[1], far), side[1]], side[2])
		for t in [0.3, 0.55, 0.8]:
			var y := lerpf(side[0].y, side[1].y, t)
			var a := Vector2(side[0].x, y)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(at.call(a, far).x), _n(at.call(a, far).y)], "none", _stroke(side[3], 1.5))
	_lane_wall_detail(vp, far, 0.1, 0.06)
	# Left wall: white conduits, a meter box, a yellow box with a plant, a blue tag.
	for y in [372.0, 388.0]:
		var a := Vector2(X0, y)
		var b: Vector2 = at.call(a, 0.55)
		_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#E9E6DE", 4))
	_rect(X0 + 6, 380, 5, 150, "#E9E6DE")
	_rect(X0 + 16, 470, 14, 22, "#D9D6CE", _stroke("#9A968E", 1))
	var yb: Vector2 = at.call(Vector2(X0, 540), 0.42)
	_rect(yb.x - 4, yb.y - 26, 18, 30, "#E8C33A", _stroke("#A88A1E", 1.5))
	_circle(yb.x + 5, yb.y - 34, 9, "#5F8F3A")
	var tag: Vector2 = at.call(Vector2(X0, 560), 0.2)
	_path("M%s %s c6 -16 14 -16 12 0 c-2 14 10 14 12 -2 c2 -14 12 -12 10 4" % [_n(tag.x - 4), _n(tag.y)], "none", _stroke("#2F4FA8", 3.5) + ' stroke-linecap="round"')
	_path("M%s %s c4 -10 10 -10 8 0" % [_n(tag.x + 2), _n(tag.y - 22)], "none", _stroke("#F4F1EA", 2) + ' stroke-linecap="round"')
	# Right wall: the painted mural further in.
	var m0 := 0.38
	var m1 := 0.62
	poly.call([at.call(Vector2(X1, 430), m0), at.call(Vector2(X1, 430), m1), at.call(gr, m1), at.call(gr, m0)], "#3D7FD0")
	poly.call([at.call(Vector2(X1, 500), m0), at.call(Vector2(X1, 470), m1), at.call(gr, m1), at.call(gr, m0)], "#6FBF4A")
	for i in 3:
		var f: Vector2 = at.call(Vector2(X1, 520 + i * 40), lerpf(m0, m1, (i + 0.5) / 3.0))
		out.append('<ellipse cx="%s" cy="%s" rx="5" ry="9" fill="#F2C230" stroke="#2B2B2B" stroke-width="1"/>' % [_n(f.x), _n(f.y)])
	# Leaves carpeting the path, thickest along the right.
	for i in int(k.width * 0.35):
		var d := pow(rng.randf(), 1.6) * far
		var u := rng.randf()
		if rng.randf() < 0.5:
			u = lerpf(0.65, 1.0, rng.randf())
		var p: Vector2 = at.call(Vector2(lerpf(X0 + 6, X1 - 6, u), ground_y - 4), d)
		_leaf(p.x, p.y, rng.randf_range(0.0, PI))
	# Wooden planter box along the right wall, heaped with leaves.
	poly.call([Vector2(X1, ground_y - 46), at.call(Vector2(X1, ground_y - 46), 0.4), at.call(Vector2(X1 - 34, ground_y - 46), 0.4), Vector2(X1 - 34, ground_y - 46)], "#B5442E")
	poly.call([Vector2(X1 - 34, ground_y - 46), at.call(Vector2(X1 - 34, ground_y - 46), 0.4), at.call(Vector2(X1 - 34, ground_y), 0.4), Vector2(X1 - 34, ground_y)], "#8A6440", _stroke("#5E4228", 1.5))
	for i in 5:
		var pp: Vector2 = at.call(Vector2(X1 - 16, ground_y - 50), i * 0.08)
		_circle(pp.x, pp.y - 6, 10 - i, _pick(["#5F8F3A", "#7FA34A", "#C9562E"]))
	# Big round white concrete planter with black dots, a plant in it.
	var pc := Vector2(X0 + 62, ground_y - 46)
	out.append('<ellipse cx="%s" cy="%s" rx="50" ry="10" fill="#000000" opacity="0.18"/>' % [_n(pc.x + 6), _n(ground_y - 2)])
	_path("M%s %s L%s %s Q%s %s %s %s L%s %s Z" % [_n(pc.x - 46), _n(pc.y), _n(pc.x - 40), _n(ground_y - 6), _n(pc.x), _n(ground_y + 4), _n(pc.x + 40), _n(ground_y - 6), _n(pc.x + 46), _n(pc.y)], "#EDEBE5", _stroke("#B9B5AC", 2))
	out.append('<ellipse cx="%s" cy="%s" rx="46" ry="11" fill="#D9D6CE" stroke="#B9B5AC" stroke-width="2"/>' % [_n(pc.x), _n(pc.y)])
	for dot in [[-28, 18, 6], [-6, 26, 8], [20, 16, 5], [34, 30, 4], [-34, 34, 4]]:
		_circle(pc.x + dot[0], pc.y + dot[1], dot[2], "#1E1E1E")
	for i in 7:
		var a := lerpf(-2.6, -0.5, i / 6.0)
		_path("M%s %s q%s %s %s %s" % [_n(pc.x), _n(pc.y - 4), _n(cos(a) * 20), _n(sin(a) * 40), _n(cos(a) * 34), _n(sin(a) * 30)], "none", _stroke(_pick(["#5F8F3A", "#7FA34A", "#4E7A30"]), 5) + ' stroke-linecap="round"')
	# Red pole with the green lane sign.
	var px: float = k.width / 2.0 + 90.0
	_rect(px - 3, 440, 6, ground_y - 446, "#C8202A", _stroke("#8E1A20", 1))
	out.append('<ellipse cx="%s" cy="%s" rx="7" ry="2.5" fill="#000000" opacity="0.25"/>' % [_n(px + 2), _n(ground_y - 4)])
	_rect(px - 66, 384, 132, 64, "#2E8B47", 'rx="8" ' + _stroke("#F4F1EA", 4))
	_path("M%s 440 q-10 -14 0 -24 q10 10 0 24 z" % _n(px - 50), "#9BD16A")
	# Brick courses along both side walls, and the stone quoins at the left building's corner (photo).
	for side in [[l0, gl, "#6A4033"], [r0, gr, "#7A4E3C"]]:
		var y: float = side[0].y + 12.0
		while y < side[1].y - 8.0:
			var a := Vector2(side[0].x, y)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(at.call(a, 0.5).x), _n(at.call(a, 0.5).y)], "none", _stroke(side[2], 0.8) + ' opacity="0.55"')
			y += 9.0
	var qy := 120.0
	while qy < ground_y - 60.0:
		_rect(X0, qy, 26 if int(qy / 34.0) % 2 == 0 else 16, 16, "#C9C3B6", _stroke("#9A948A", 1))
		qy += 34.0
	# A round electricity meter on the left wall, a child's red tricycle by the stairs on the right.
	var meter: Vector2 = at.call(Vector2(X0, 500), 0.12)
	_circle(meter.x + 4, meter.y, 9, "#D9D6CE", _stroke("#8E8A82", 1.5))
	_circle(meter.x + 4, meter.y, 5, "#B9C6CC")
	var trike: Vector2 = at.call(Vector2(X1 - 60, ground_y - 4), 0.3)
	_circle(trike.x - 12, trike.y - 8, 8, "none", _stroke("#2B2B2B", 2.5))
	_circle(trike.x + 12, trike.y - 8, 8, "none", _stroke("#2B2B2B", 2.5))
	_path("M%s %s l12 -16 l12 16 M%s %s v-10 h8" % [_n(trike.x - 12), _n(trike.y - 8), _n(trike.x), _n(trike.y - 24)], "none", _stroke("#D9342B", 4) + ' stroke-linecap="round"')
	# The lane tree from the photo: rising on the right and arching right over the entrance. Own seed, so the entrance's width doesn't change it.
	_lane_air_detail(vp, far)
	rng.seed = TREE_SEED
	_fine_tree(Vector2(X1 - 54, ground_y - 46), 400.0, -PI * 0.78, 1.05, ["#E3A33A", "#D9682B", "#C9562E", "#B5442E", "#E8B54A"])


# The lanes of all the blocks are in line: looking in from the street we see down this one to the next avenue, across it
# to the next block's lane entrance, and so on to the vanishing point `vp`, under the open sky. `start`: the scale where the
# entrance's own walls end (the art draws them over this). Scale at depth z is 1 / (1 + z), z counted in entrance widths or so.
func _lane_through(vp: Vector2, start: float, sky_fade := 0.0) -> void:
	const BLOCK := 3.6
	const AVENUE := 1.2
	const BLOCKS := 4
	_lane_sky(sky_fade)
	var last := BLOCKS * BLOCK + (BLOCKS - 1) * AVENUE
	_lane_quad(vp, X0 - vp.x, X1 - vp.x, 1.0 / (1.0 + last), 0.0, _hazed("#B3AFA6", 0.8))
	for b in range(BLOCKS - 1, -1, -1):
		var near := b * (BLOCK + AVENUE)
		var far := near + BLOCK
		if b < BLOCKS - 1:
			_lane_avenue(vp, far, far + AVENUE, b)
		if b == 0:
			near = 1.0 / start - 1.0
		_lane_stretch(vp, near, far, b)


# The open sky down the lane, hiding the distant city behind it, fading in from above; and, `fade` > 0, in from both sides
# over that width, for a lane whose neighbour is too low to hide the sky's edge (the corner yard across 6e).
func _lane_sky(fade := 0.0) -> void:
	# Season.sky()'s colours: this script can't load Season (autoloads aren't there in a --script run).
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.82, 1.0])
	grad.colors = PackedColorArray({
		"spring": [Color("#5A9BD8"), Color("#93C6EC"), Color("#D3E8F3"), Color("#F4E9D6"), Color("#F3D9C4")],
		"summer": [Color("#3A82D4"), Color("#6CB2EA"), Color("#B6DCF2"), Color("#E8F1EE"), Color("#F5E4C4")],
		"winter": [Color("#8EA6C0"), Color("#B2C4D5"), Color("#D6DFE7"), Color("#E7E3DE"), Color("#E0D3CA")],
		"autumn": [Color("#4F86C6"), Color("#86B5E0"), Color("#C9DDEB"), Color("#F6D9B4"), Color("#F4B98C")]}[season])
	var stops := ""
	for i in 5:
		# The sprite's y in the view: its foot on the houses' base line, at the houses' scale.
		var y := lerpf(0.0, ground_y - 200.0, i / 4.0)
		var view_y := 592.0 + (y - ground_y) * 0.57
		stops += '<stop offset="%s" stop-color="#%s" stop-opacity="%s"/>' % [_n(i / 4.0), grad.sample(view_y / 720.0).to_html(false), _n(clampf(y / 120.0, 0.0, 1.0))]
	out.append('<defs><linearGradient id="lanesky" x1="0" y1="0" x2="0" y2="1">%s</linearGradient></defs>' % stops)
	if fade <= 0.0:
		_rect(X0, 0, X1 - X0, ground_y - 200.0, "url(#lanesky)")
		return
	_rect(X0 + fade, 0, X1 - X0 - 2.0 * fade, ground_y - 200.0, "url(#lanesky)")
	const STRIPS := 12
	for i in STRIPS:
		var w := fade / STRIPS
		var o := _n(pow((i + 0.5) / STRIPS, 1.5))
		_rect(X0 + i * w, 0, w + 0.5, ground_y - 200.0, "url(#lanesky)", 'opacity="%s"' % o)
		_rect(X1 - (i + 1) * w - 0.5, 0, w + 0.5, ground_y - 200.0, "url(#lanesky)", 'opacity="%s"' % o)


func _hazed(c: String, amount: float) -> String:
	return "#" + Color(c).lerp(Color("#CFD6DC"), clampf(amount, 0.0, 0.8)).to_html(false)


func _lane_point(vp: Vector2, u: float, y: float, scale: float) -> Vector2:
	return vp + Vector2(u, y - vp.y) * scale


# A strip of ground between u0 and u1 from scale s0 to s1.
func _lane_quad(vp: Vector2, u0: float, u1: float, s0: float, s1: float, fill: String) -> void:
	_lane_poly([_lane_point(vp, u0, ground_y, s0), _lane_point(vp, u1, ground_y, s0), _lane_point(vp, u1, ground_y, s1), _lane_point(vp, u0, ground_y, s1)], fill)


func _lane_poly(pts: Array, fill: String) -> void:
	var parts := PackedStringArray()
	for i in pts.size():
		parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(pts[i].x), _n(pts[i].y)])
	_path(" ".join(parts) + " Z", fill)


# A wall along the lane at u, from scale s0 to s1, up to `top`.
func _lane_wall(vp: Vector2, u: float, top: float, s0: float, s1: float, fill: String) -> void:
	_lane_poly([_lane_point(vp, u, top, s0), _lane_point(vp, u, top, s1), _lane_point(vp, u, ground_y, s1), _lane_point(vp, u, ground_y, s0)], fill)


# The avenue between two blocks: its sidewalks and road, seen across.
func _lane_avenue(vp: Vector2, z0: float, z1: float, b: int) -> void:
	var haze := (b + 1) * 0.2
	var wide := (X1 - X0) * 6.0
	var snowy := season == "winter"
	_lane_quad(vp, -wide, wide, 1.0 / (1.0 + z0), 1.0 / (1.0 + z1), _hazed("#E4E8EC" if snowy else "#C9C4B8", haze))
	_lane_quad(vp, -wide, wide, 1.0 / (1.0 + z0 + 0.25), 1.0 / (1.0 + z1 - 0.25), _hazed("#6A6C70" if snowy else "#57544F", haze))


# One block's lane, from depth z0 to z1, far to near: the ground, the plex backs set back behind the yards, trees in the yards,
# the yard fences, the corner buildings' sides and (except this entrance's own) their facades on the avenue, which make the entrance.
func _lane_stretch(vp: Vector2, z0: float, z1: float, b: int) -> void:
	var haze := b * 0.2
	var ul := X0 - vp.x
	var ur := X1 - vp.x
	var at_z := func(z: float) -> float: return 1.0 / (1.0 + z)
	var s0: float = at_z.call(z0)
	var s1: float = at_z.call(z1)
	_lane_quad(vp, ul, ur, s0, s1, _hazed("#E4E8EC" if season == "winter" else "#B3AFA6", haze))
	var corner := z0 + 0.9
	var yards: float = s0 if b == 0 else at_z.call(corner)
	for u in [ul, ur]:
		var brick: String = _pick(["#8E5A46", "#A0654C", "#7E4E3E", "#B08A68"])
		_lane_wall(vp, u * 2.4, 130.0, yards, s1, _hazed(brick, haze + 0.12))
		var kinds: int = rng.randi_range(3, 5)
		for n in kinds:
			# Far to near along the yards.
			var z := lerpf(z1, maxf(z0, corner), (n + 0.5) / kinds)
			var scale: float = at_z.call(z)
			var tree: Vector2 = Vector2(vp.x + u * 1.55 * scale, vp.y + (ground_y - vp.y) * scale)
			var crown: float = vp.y + (rng.randf_range(150.0, 260.0) - vp.y) * scale
			_path("M%s %s L%s %s" % [_n(tree.x), _n(tree.y), _n(tree.x), _n(crown)], "none", _stroke(_hazed("#4A3428", haze), maxf(10.0 * scale, 0.8)))
			for c in 7:
				var at: Vector2 = Vector2(tree.x + rng.randf_range(-85.0, 85.0) * scale, crown + rng.randf_range(-55.0, 45.0) * scale)
				_circle(at.x, at.y, maxf(rng.randf_range(30.0, 52.0) * scale, 1.0), _hazed(_canopy(_pick(["#E3A33A", "#D9682B", "#C9562E", "#B5442E"])), haze + 0.05))
		_lane_wall(vp, u, ground_y - 170.0, yards, s1, _hazed("#8A7A62", haze))
		if b == 0:
			# Boards on the near fences.
			var z := z1 - 0.35
			while z > z0:
				var a: Vector2 = _lane_point(vp, u, ground_y - 170.0, at_z.call(z))
				var c: Vector2 = _lane_point(vp, u, ground_y, at_z.call(z))
				_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(c.x), _n(c.y)], "none", _stroke("#5E5344", 1.0))
				z -= 0.3
		else:
			var top := 90.0 + rng.randf_range(0.0, 40.0)
			_lane_wall(vp, u, top, s0, yards, _hazed(brick, haze))
			var side: float = signf(u)
			var near_x: float = vp.x + u * s0
			var wide: float = absf(u) * 6.0 * s0
			var y0: float = vp.y + (top - vp.y) * s0
			var y1: float = vp.y + (ground_y - vp.y) * s0
			_rect(minf(near_x, near_x + side * wide), y0, wide, y1 - y0, _hazed(brick, haze - 0.05))
			for row in 3:
				for col in 6:
					var wx: float = near_x + side * (0.1 + col * 0.16) * wide
					_rect(wx - 0.03 * wide, y0 + (0.12 + row * 0.28) * (y1 - y0), 0.06 * wide, 0.16 * (y1 - y0), _hazed("#C6D2D6", haze))


# A tree drawn branch by branch: a trunk to `fork_y`, limbs splitting three times around `heading` (radians, -PI/2 =
# straight up), hundreds of small leaves in clusters at the twigs (this season's colours), bare and snowy in winter.
# The same random draws in every season.
func _fine_tree(base: Vector2, fork_y: float, heading: float, size: float, autumn: Array) -> void:
	var bark := "#4A3428"
	var fork := Vector2(base.x + cos(heading) * (base.y - fork_y) * 0.25, fork_y)
	_path("M%s %s Q%s %s %s %s" % [_n(base.x), _n(base.y), _n(base.x), _n(lerpf(base.y, fork_y, 0.6)), _n(fork.x), _n(fork.y)], "none", _stroke(bark, 13.0 * size) + ' stroke-linecap="round"')
	_path("M%s %s Q%s %s %s %s" % [_n(base.x - 3), _n(base.y), _n(base.x - 3), _n(lerpf(base.y, fork_y, 0.6)), _n(fork.x - 3), _n(fork.y)], "none", _stroke("#6E5444", 3.0 * size) + ' stroke-linecap="round" opacity="0.7"')
	var twigs: Array[Vector2] = []
	var limbs: Array = []
	for i in 3:
		_limb(fork, heading + (i - 1) * 0.55 + rng.randf_range(-0.15, 0.15), 120.0 * size, 9.0 * size, 3, twigs, limbs)
	for l in limbs:
		_path("M%s %s Q%s %s %s %s" % [_n(l[0].x), _n(l[0].y), _n(l[1].x), _n(l[1].y), _n(l[2].x), _n(l[2].y)], "none", _stroke(bark, l[3]) + ' stroke-linecap="round"')
		if season == "winter" and l[3] > 2.5:
			_path("M%s %s Q%s %s %s %s" % [_n(l[0].x), _n(l[0].y - l[3] * 0.5), _n(l[1].x), _n(l[1].y - l[3] * 0.5), _n(l[2].x), _n(l[2].y - l[3] * 0.5)], "none", _stroke("#F7F9FB", 2.0) + ' stroke-linecap="round"')
	# Leaves: darker ones underneath first, then the lit ones, in clusters round each twig.
	for layer in 2:
		for t in twigs:
			for j in 22:
				var p := t + Vector2(rng.randf_range(-16, 16), rng.randf_range(-14, 10)) * size
				var a := rng.randf_range(0.0, 180.0)
				var c := _canopy(autumn[rng.randi_range(0, autumn.size() - 1)])
				if layer == 0:
					c = "#" + Color(c).darkened(0.3).to_html(false)
				elif rng.randf() < 0.3:
					c = "#" + Color(c).lightened(0.2).to_html(false)
				if season != "winter":
					out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" transform="rotate(%s %s %s)"/>' % [_n(p.x), _n(p.y), _n(5.5 * size), _n(2.6 * size), c, _n(a), _n(p.x), _n(p.y)])


func _limb(from: Vector2, angle: float, length: float, width: float, depth: int, twigs: Array[Vector2], limbs: Array) -> void:
	var to := from + Vector2.from_angle(angle) * length
	var bend := (to - from).orthogonal().normalized() * length * rng.randf_range(-0.18, 0.18)
	limbs.append([from, from.lerp(to, 0.5) + bend, to, maxf(width, 1.6)])
	if depth == 0:
		twigs.append(to)
		# Short twigs fanning out at the tip, for the leaves to hang on.
		for i in 3:
			var tip := to + Vector2.from_angle(angle + (i - 1) * 0.7) * length * 0.35
			limbs.append([to, to.lerp(tip, 0.5), tip, 1.4])
			twigs.append(tip)
		return
	twigs.append(from.lerp(to, 0.45))
	twigs.append(from.lerp(to, 0.75))
	for i in rng.randi_range(2, 3):
		_limb(to, angle + rng.randf_range(-0.65, 0.65), length * rng.randf_range(0.58, 0.76), width * 0.62, depth - 1, twigs, limbs)


# The lane entrance by the Holt corner (reference/ruelle/entree_ruelle_6eme_coin_holt.png): on the right the corner
# building's tall brick side, black conduits running down it, tags, its concrete footing; on the left the next
# building's side with an iron stair and wooden treads curling up to a gallery; at the far end a white garage door
# in a red frame under a black railing; a one-way sign on its post, the post of the "enfants en liberté" sign
# (StreetScene hangs the sign), a yellow pole; a tree reaching over.
func _ruelle() -> void:
	var cx: float = k.width / 2.0
	var vp := Vector2(cx + 10.0, 470.0)
	var far := 0.72
	var at := func(p: Vector2, d: float) -> Vector2: return vp + (p - vp) * (1.0 - d)
	var poly := func(pts: Array, fill: String, extra := "") -> void:
		var parts := PackedStringArray()
		for i in pts.size():
			parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(pts[i].x), _n(pts[i].y)])
		_path(" ".join(parts) + " Z", fill, extra)
	var gl := Vector2(X0, ground_y)
	var gr := Vector2(X1, ground_y)
	_lane_through(vp, 1.0 - far)
	# The lane: concrete, its joints, a seam of weeds.
	poly.call([gl, gr, at.call(gr, far), at.call(gl, far)], "#B3AFA6")
	for d in [0.25, 0.5]:
		_path("M%s %s L%s %s" % [_n(at.call(gl, d).x), _n(at.call(gl, d).y), _n(at.call(gr, d).x), _n(at.call(gr, d).y)], "none", _stroke("#8E8A82", 1.5))
	_path("M%s %s L%s %s" % [_n(cx), _n(ground_y), _n(at.call(Vector2(cx, ground_y), far).x), _n(at.call(Vector2(cx, ground_y), far).y)], "none", _stroke(_bush("#7E8F3A"), 2.5))
	_lane_ground_detail(vp, far)
	# Left: the neighbour's brick side, and its stair: wooden treads between two curling black stringers.
	var lw := ["#8E4E3C", "#A85A44"]
	poly.call([Vector2(X0, 140), at.call(Vector2(X0, 140), far), at.call(gl, far), gl], lw[0])
	var y := 150.0
	while y < ground_y - 6.0:
		_path("M%s %s L%s %s" % [_n(X0), _n(y), _n(at.call(Vector2(X0, y), far).x), _n(at.call(Vector2(X0, y), far).y)], "none", _stroke(lw[1], 0.8) + ' opacity="0.6"')
		y += 10.0
	_lane_wall_detail(vp, far, 0.1, 0.22)
	# The white garage door in its red frame, in the wall further along, a black railing above.
	var door := func(y: float, d: float) -> Vector2: return at.call(Vector2(X0, y), d)
	poly.call([door.call(ground_y - 236, 0.5), door.call(ground_y - 236, 0.66), door.call(ground_y, 0.66), door.call(ground_y, 0.5)], "#B5302A")
	poly.call([door.call(ground_y - 226, 0.51), door.call(ground_y - 226, 0.65), door.call(ground_y, 0.65), door.call(ground_y, 0.51)], "#F2F0EA")
	_path("M%s %s L%s %s" % [_n(door.call(ground_y - 262, 0.5).x), _n(door.call(ground_y - 262, 0.5).y), _n(door.call(ground_y - 262, 0.66).x), _n(door.call(ground_y - 262, 0.66).y)], "none", _stroke("#1F1F1F", 3))
	var s0 := Vector2(X0 + 64, ground_y - 4)
	var s3: Vector2 = at.call(Vector2(X0, 380), 0.35)
	var s1 := Vector2(X0 + 120, ground_y - 150)
	var s2 := Vector2(X0 + 70, 400)
	var inner: Array[Vector2] = []
	var outer: Array[Vector2] = []
	for i in 15:
		var t := i / 14.0
		var p := s0.bezier_interpolate(s1, s2, s3, t)
		inner.append(p)
		outer.append(p + Vector2(-34.0 * (1.0 - t * 0.6), 6.0 * (1.0 - t)))
	for i in range(1, 15):
		_path("M%s %s L%s %s" % [_n(inner[i].x), _n(inner[i].y), _n(outer[i].x), _n(outer[i].y)], "none", _stroke("#8E6A44", 5.0 * (1.0 - i / 20.0)))
	for rail in [inner, outer]:
		_path(_polyline(rail, Vector2.ZERO), "none", _stroke("#1F1F1F", 3.0))
		_path(_polyline(rail, Vector2(0, -RAIL_H)), "none", _stroke("#1F1F1F", 2.5))
		for i in range(0, 15, 2):
			_path("M%s %s v%s" % [_n(rail[i].x), _n(rail[i].y), _n(-RAIL_H)], "none", _stroke("#1F1F1F", 1.5))
	# Right: the corner building's tall side, its footing, its conduits and tags.
	var rw := ["#7E4234", "#9A5A48"]
	poly.call([Vector2(X1, 0), at.call(Vector2(X1, 0), far), at.call(gr, far), gr], rw[0])
	y = 8.0
	while y < ground_y - 40.0:
		_path("M%s %s L%s %s" % [_n(X1), _n(y), _n(at.call(Vector2(X1, y), far).x), _n(at.call(Vector2(X1, y), far).y)], "none", _stroke(rw[1], 0.8) + ' opacity="0.6"')
		y += 10.0
	poly.call([Vector2(X1, ground_y - 46), at.call(Vector2(X1, ground_y - 46), far), at.call(gr, far), gr], "#B9B3A8")
	for d in [0.1, 0.16]:
		var top: Vector2 = at.call(Vector2(X1, 60), d)
		var bot: Vector2 = at.call(Vector2(X1, ground_y - 50), d)
		_path("M%s %s L%s %s Q%s %s %s %s" % [_n(top.x), _n(top.y), _n(bot.x), _n(bot.y), _n(bot.x), _n(bot.y + 14), _n(bot.x + 16), _n(bot.y + 16)], "none", _stroke("#1A1A1A", 4))
	var tag: Vector2 = at.call(Vector2(X1, ground_y - 110), 0.3)
	_path("M%s %s c4 -14 10 -14 9 0 c-1 12 8 12 9 -2 c1 -10 9 -10 8 2 m4 -8 l8 0" % [_n(tag.x - 14), _n(tag.y)], "none", _stroke("#2B3A6E", 2.5) + ' stroke-linecap="round"')
	var tag2: Vector2 = at.call(Vector2(X1, ground_y - 22), 0.12)
	_path("M%s %s l4 -12 l4 12 m4 -12 v12 h6 m4 -12 v12 h6" % [_n(tag2.x - 14), _n(tag2.y)], "none", _stroke("#C8202A", 2) + ' stroke-linecap="round"')
	# A yellow pole leaning on the wall, the one-way sign, and the post for the neighbours' sign.
	_path("M%s %s L%s %s" % [_n(X1 - 70), _n(ground_y - 2), _n(X1 - 50), _n(ground_y - 170)], "none", _stroke("#E8C33A", 5) + ' stroke-linecap="round"')
	_rect(X0 + 26, 430, 6, ground_y - 430, "#8E9399")
	_rect(X0 + 2, 418, 70, 26, "#1E1E1E", 'rx="2"')
	_path("M%s 431 h46 m-12 -8 l12 8 l-12 8" % _n(X0 + 12), "none", _stroke("#FFFFFF", 4) + ' stroke-linecap="round" stroke-linejoin="round"')
	_rect(X1 - 39, 360, 6, ground_y - 360, "#8E9399")
	# The tree reaching over from the left.
	_lane_air_detail(vp, far)
	_fine_tree(Vector2(X0 - 30, 420), 300.0, -PI * 0.38, 0.75, ["#E3A33A", "#D9682B", "#C9B03A", "#B5442E"])


# Stone lintels in steps (a tall middle block and two lower shoulders), white like on the photos of the corner.
func _stepped_lintel(x: float, y: float, w: float) -> void:
	_rect(x - 14, y - 12, w + 28, 12, k.lintel, _stroke(k.lintel_dark, 1))
	_rect(x + w * 0.25, y - 26, w * 0.5, 14, k.lintel, _stroke(k.lintel_dark, 1))
	for sx in [x - 14.0, x + w + 2.0]:
		_rect(sx, y, 12, 14, k.lintel, _stroke(k.lintel_dark, 1))


func _diamond(cx: float, cy: float, r: float) -> void:
	_path("M%s %s l%s %s l%s %s l%s %s z" % [_n(cx), _n(cy - r), _n(r), _n(r), _n(-r), _n(r), _n(-r), _n(-r)], "#4E5C70", _stroke("#36404E", 1))


func _corner_holt() -> void:
	var top := _top()
	_bricks(top, base_y)
	# The coping and the cream corner caps of the roofline, a corbelled band below.
	_rect(X0 - 4, top - 10, X1 - X0 + 8, 12, "#5E3328")
	for cxx in [X0 + 14.0, X1 - 14.0]:
		_rect(cxx - 16, top - 24, 32, 16, "#E3C48A", _stroke("#B5975E", 1.5))
		_rect(cxx - 10, top - 32, 20, 8, "#E3C48A", _stroke("#B5975E", 1.5))
	var bx := X0 + 6.0
	while bx < X1 - 10.0:
		_rect(bx, top + 10, 10, 8, "#5E3328", 'opacity="0.55"')
		bx += 20.0
	_wall_shading(top)
	_foundation()
	var bays := [170.0, 380.0, 590.0, 800.0]
	for f in [1, 2]:
		for wx in bays:
			_window(wx, _win_y(f), 74, 150)
			_stepped_lintel(wx, _win_y(f), 74)
		for i in 3:
			_diamond((bays[i] + bays[i + 1] + 74.0) / 2.0, _win_y(f) + 70.0, 9.0)
	for wx in [bays[1], bays[2]]:
		_window(wx, _win_y(0) + 30.0, 74, 120)
		_stepped_lintel(wx, _win_y(0) + 30.0, 74)
	# Conduits down the wall, plaques, a tag near the ground.
	for px in [510.0, 522.0]:
		_rect(px, top + 50, 5, base_y - top - 60, "#1A1A1A")
	_path("M510 %s q0 14 -16 16" % _n(base_y - 10), "none", _stroke("#1A1A1A", 5))
	_rect(470, base_y - 150, 26, 18, "#F4F1EA", _stroke("#B9B2A5", 1))
	_rect(560, base_y - 120, 18, 22, "#D9D6CE", _stroke("#9A968E", 1))
	_path("M640 %s c4 -12 10 -12 9 0 c-1 10 8 10 9 -2 c1 -9 8 -9 7 2" % _n(base_y - 40), "none", _stroke("#6E6A9A", 2.5) + ' stroke-linecap="round"')
	# The beige corrugated annex on the left with its grey shingle awning, white door and two windows.
	var ax0 := X0
	var ax1 := X0 + 300.0
	var atop := _fb(0) - 210.0
	_rect(ax0, atop, ax1 - ax0, base_y - atop, "#CBC5B6")
	var cx := ax0
	var light := true
	while cx < ax1:
		_rect(cx, atop, 5, base_y - atop, "#DAD5C8" if light else "#B5AFA0")
		cx += 5.0
		light = not light
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(ax0 - 12), _n(atop), _n(ax1 + 12), _n(atop), _n(ax1), _n(atop - 46), _n(ax0), _n(atop - 46)], "#7E848A", _stroke("#5E6268", 1.5))
	for r in 4:
		var yy := atop - 46.0 + r * 11.5
		_path("M%s %s H%s" % [_n(ax0 - 2), _n(yy), _n(ax1 + 2)], "none", _stroke("#6A7076", 1))
		var sx := ax0 + (r % 2) * 8.0
		while sx < ax1:
			_path("M%s %s v11" % [_n(sx), _n(yy)], "none", _stroke("#6A7076", 0.8))
			sx += 16.0
	_rect(ax0 - 12, atop - 2, ax1 - ax0 + 24, 6, "#F2F0EA")
	# Its windows (reference photo): a big fixed pane over a row of small ones, two on the left, three on the right;
	# the white door with its narrow glass slot, the black mailbox and house number, a small black wall lamp.
	for wn in [[ax0 + 22, 92.0, 2], [ax0 + 198, 96.0, 3]]:
		var wx2: float = wn[0]
		var ww: float = wn[1]
		var wy2 := atop + 36.0
		var wh := 104.0
		_rect(wx2, wy2, ww, wh, "#F2F0EA", _stroke("#C9C3B8", 1.5))
		_rect(wx2 + 6, wy2 + 6, ww - 12, wh * 0.66, "url(#glass)")
		var low := wy2 + 6.0 + wh * 0.66 + 5.0
		var lh := wy2 + wh - 6.0 - low
		var panes: int = wn[2]
		var pw := (ww - 12.0 - (panes - 1) * 4.0) / panes
		for k2 in panes:
			_rect(wx2 + 6 + k2 * (pw + 4.0), low, pw, lh, "url(#glass)")
		_rect(wx2 - 4, wy2 + wh, ww + 8, 6, "#F2F0EA", _stroke("#C9C3B8", 1))
	_rect(ax0 + 128, atop + 22, 58, base_y - atop - 22, "#F4F2EC", _stroke("#C9C3B8", 2))
	_rect(ax0 + 132, atop + 26, 50, base_y - atop - 26, "#FAF8F3", _stroke("#D9D4CA", 1))
	_rect(ax0 + 166, atop + 36, 10, 46, "url(#glass)", _stroke("#C9C3B8", 1))
	_circle(ax0 + 138, atop + 112, 3, "#B9B2A5")
	_rect(ax0 + 104, atop + 70, 18, 10, "#1E1E1E")
	_rect(ax0 + 102, atop + 84, 22, 16, "#1E1E1E", 'rx="2"')
	_rect(ax0 + 112, atop + 30, 7, 10, "#1E1E1E")
	_circle(ax0 + 115, atop + 28, 4, "#1E1E1E")
	# The dépanneur's red corner window: posters behind the glass, a red awning, a red footing.
	var sx0 := X1 - 200.0
	var sx1 := X1 - 6.0
	var wy := _fb(0) - 190.0
	_rect(sx0, wy, sx1 - sx0, base_y - 50 - wy, "#2E3A44", _stroke("#1A1A1A", 3))
	_rect(sx0 + 8, wy + 8, sx1 - sx0 - 16, base_y - 66 - wy, "url(#glass)", 'opacity="0.55"')
	for pst in [[sx0 + 20, wy + 30, "#F2C230"], [sx0 + 70, wy + 20, "#E74C3C"], [sx0 + 120, wy + 40, "#F4F1EA"], [sx0 + 40, wy + 90, "#3498DB"]]:
		_rect(pst[0], pst[1], 40, 50, pst[2], 'opacity="0.85"')
	_rect(sx0, base_y - 50, sx1 - sx0, 50, "#D9342B")
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(sx0 - 10), _n(wy), _n(sx1 + 6), _n(wy), _n(sx1), _n(wy - 34), _n(sx0), _n(wy - 34)], "#D9342B", _stroke("#9E2420", 1.5))
	_rect(sx0 - 10, wy - 4, sx1 - sx0 + 16, 5, "#F4F1EA")


func _ohbon() -> void:
	var top := _top()
	_bricks(top, base_y)
	_wall_shading(top)
	_foundation()
	_flat_parapet(top)
	var store1 := 530.0
	# Upstairs: galleries with their doors across the left, windows on the right; a white soffit over the top one.
	for f in [1, 2]:
		_door(200.0, _door_top(f), _fb(f))
		_door(330.0, _door_top(f), _fb(f))
		_window(440.0, _win_y(f), 70, 150)
		_window(620.0, _win_y(f), 74, 150)
		_balcony(X0, store1, _fb(f), [])
	_rect(X0 - 8, _door_top(2) - 52, store1 - X0 + 16, 16, "#EDEBE5", _stroke("#B9B5AC", 1.5))
	_rect(X0 - 4, _door_top(2) - 36, store1 - X0 + 8, 30, "url(#drop)")
	# The storefront (reference/coin_holt/holt_coin_6eme.png), left to right: a narrow window (a beer neon goes in it), the
	# black-framed glass door, the big window (the "OH BON!" neon goes in it, holt.gd), the red and white checkerboard,
	# a white board. Over it a sloping brown canopy edged with a red fascia, and the white light-box sign over the door
	# and the big window; a red footing under it all, little black handrails at the step.
	var st := _fb(1) + 8.0
	_rect(X0, st, store1 - X0, base_y - st, "#3A2E2E")
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(X0 - 6), _n(st + 30), _n(store1 + 6), _n(st + 30), _n(store1), _n(st), _n(X0), _n(st)], "#6E5444", _stroke("#4A3428", 1))
	var slat := X0 + 6.0
	while slat < store1:
		_path("M%s %s L%s %s" % [_n(slat), _n(st + 1), _n(slat - 3), _n(st + 29)], "none", _stroke("#5A4436", 1))
		slat += 9.0
	_rect(X0 - 6, st + 30, store1 - X0 + 12, 16, "#D9342B", _stroke("#9E2420", 1))
	var wy := st + 92.0
	var wb := base_y - 62.0
	# Narrow left window: posters, lottery stickers.
	_rect(X0 + 6, wy, 92, wb - wy, "#2E3A44", _stroke("#1A1A1A", 3))
	_shop_glass_glow(X0 + 6, wy, 92, wb - wy, 113)
	_shop_glass_goods(X0 + 6, wy, 92, wb - wy, 113, 2)
	_rect(X0 + 6, wy, 92, wb - wy, "url(#glass)", 'opacity="0.45"')
	_rect(X0 + 16, wb - 60, 30, 40, "#F2C230", 'opacity="0.8"')
	_rect(X0 + 54, wb - 46, 34, 26, "#4E8A5A", 'opacity="0.8"')
	_shop_glass_shine(X0 + 6, wy, 92, wb - wy)
	# The door: black frame, glass, its number on the glass, a push bar.
	_rect(X0 + 104, wy - 6, 74, base_y - wy + 6, "#1F1F1F")
	_rect(X0 + 111, wy + 2, 60, base_y - wy - 12, "url(#glass)")
	_rect(X0 + 111, wy + 2, 60, base_y - wy - 12, "#2E3A44", 'opacity="0.35"')
	out.append('<text x="%s" y="%s" font-size="11" font-family="sans-serif" fill="#F4F1EA">2092</text>' % [_n(X0 + 118), _n(wy + 18)])
	_rect(X0 + 114, wy + 120, 54, 5, "#B9B9B9")
	# The big window: dark glass, posters along the bottom.
	_rect(X0 + 184, wy, 150, wb - wy, "#2E3A44", _stroke("#1A1A1A", 3))
	_shop_glass_glow(X0 + 184, wy, 150, wb - wy, 271)
	_shop_glass_goods(X0 + 184, wy, 150, wb - wy, 271, 3)
	_rect(X0 + 184, wy, 150, wb - wy, "url(#glass)", 'opacity="0.4"')
	for pst in [[X0 + 192, "#4E8A5A"], [X0 + 226, "#F2C230"], [X0 + 262, "#3D7FD0"], [X0 + 296, "#F4F1EA"]]:
		_rect(pst[0], wb - 34, 30, 28, pst[1], 'opacity="0.85"')
	_shop_glass_shine(X0 + 184, wy, 150, wb - wy)
	# The light-box sign over the door and the big window (its words are labels in holt.gd).
	_rect(X0 + 86, st + 52, 250, 32, "#F4F1EA", _stroke("#9A968E", 2))
	_rect(X0 + 96, st + 60, 18, 14, "#D9342B")
	_rect(X0 + 216, st + 58, 110, 20, "#D9342B")
	# The checkerboard, squares of 26.
	var cx0 := X0 + 340.0
	var cy := st + 60.0
	var row := 0
	while cy < wb - 2.0:
		var cxx := cx0
		var col := row % 2
		while cxx < cx0 + 156.0 - 1.0:
			_rect(cxx, cy, 26, minf(26.0, wb - cy), "#D9342B" if col % 2 == 0 else "#F4F1EA")
			cxx += 26.0
			col += 1
		cy += 26.0
		row += 1
	_rect(cx0 + 160, wb - 70, 30, 70, "#F4F1EA", _stroke("#C9C3B8", 1))
	# The red footing and the step's little handrails.
	_rect(X0, wb, store1 - X0, base_y - wb, "#D9342B")
	_rect(X0 + 104, wb, 74, base_y - wb, "#1F1F1F")
	for hx in [X0 + 60.0, X0 + 200.0]:
		_path("M%s %s l0 -40 l40 0 l0 40" % [_n(hx), _n(base_y)], "none", _stroke("#1F1F1F", 3))
	# White-railed straight stairs from the sidewalk up to the first gallery.
	var keep_metal: String = k.metal
	k.metal = "#F2F2EE"
	k.tread = "#3A3A3A"
	k.tread_dark = "#1F1F1F"
	var p0 := Vector2(store1 - 10.0, _fb(1) + 6.0)
	var p3 := Vector2(store1 + 170.0, ground_y)
	_stairs(p0, p0.lerp(p3, 1.0 / 3.0), p0.lerp(p3, 2.0 / 3.0), p3)
	k.metal = keep_metal


# --- Autumn & Halloween -----------------------------------------------------

# A fallen leaf in autumn; a petal in spring, a green leaf in summer, a tuft of snow in winter.
func _leaf(x: float, y: float, a: float) -> void:
	var c := _pick(["#D9682B", "#B5442E", "#E3A33A", "#C9562E", "#8E3A24"])
	match season:
		"spring":
			c = ["#F7C6D9", "#FBE0EA", "#FFFFFF", "#E890B4", "#F2A7C9"][int(x) % 5]
		"summer":
			if int(x * 7.0) % 4 != 0:
				return
			c = ["#4FA34A", "#6DB86A", "#3E8E3A"][int(x) % 3]
		"winter":
			out.append('<ellipse cx="%s" cy="%s" rx="7" ry="3" fill="#F7F9FB"/>' % [_n(x), _n(y)])
			return
	out.append('<ellipse cx="%s" cy="%s" rx="4.5" ry="2.4" fill="%s" transform="rotate(%s %s %s)"/>' % [_n(x), _n(y), c, _n(rad_to_deg(a)), _n(x), _n(y)])


func _pumpkin(cx: float, bottom: float, s: float, carved: bool) -> void:
	if season != "autumn":
		_planter(cx, bottom, s)
		return
	var w := 34.0 * s
	var h := 26.0 * s
	var cy := bottom - h / 2
	if carved:
		_circle(cx, cy, w * 1.4, "url(#pumpkin_glow)")
	out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#000000" opacity="0.18"/>' % [_n(cx + 3), _n(bottom - 1), _n(w * 0.6), _n(h * 0.15)])
	for i in [-1.0, 1.0, 0.0]:
		var col := "#F28C28" if i == 0.0 else "#E07418"
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="#A84E10" stroke-width="1.5"/>' % [
			_n(cx + i * w * 0.22), _n(cy), _n(w * (0.32 if i == 0.0 else 0.3)), _n(h / 2), col])
	_path("M%s %s q2 -8 7 -10" % [_n(cx), _n(cy - h / 2 + 2)], "none", _stroke("#5A6B2A", 3.5 * s) + ' stroke-linecap="round"')
	if carved:
		var e := 5.0 * s
		_path("M%s %s l%s %s l%s %s z M%s %s l%s %s l%s %s z" % [
			_n(cx - 9 * s), _n(cy - 1 * s), _n(e * 0.5), _n(-e), _n(e * 0.5), _n(e),
			_n(cx + 4 * s), _n(cy - 1 * s), _n(e * 0.5), _n(-e), _n(e * 0.5), _n(e)], "#FFD36B")
		_path("M%s %s l3 3 l3 -3 l3 3 l3 -3 l3 3 l3 -3" % [_n(cx - 9 * s), _n(cy + 4 * s)], "none",
			_stroke("#FFD36B", 2.5 * s) + ' stroke-linejoin="round"')


func _mums(cx: float, bottom: float) -> void:
	_path("M%s %s h26 l-4 20 h-18 z" % [_n(cx - 13), _n(bottom - 22)], "#8A5A3A", _stroke("#5E3B24", 1.5))
	var c := _pick(MUMS)
	if season != "autumn":
		_planter_plant(cx, bottom - 22, 1.0)
		return
	for i in 9:
		var a := TAU * i / 9.0
		_circle(cx + cos(a) * 11.0, bottom - 32 + sin(a) * 8.0, 6.5, c, _stroke("#" + Color(c).darkened(0.25).to_html(false), 1))
	_circle(cx, bottom - 34, 7, "#" + Color(c).lightened(0.2).to_html(false))


func _ghost(cx: float, top: float) -> void:
	if season == "winter":
		# A glass bauble star hanging instead.
		_path("M%s %s V%s" % [_n(cx), _n(top - 14), _n(top + 6)], "none", _stroke("#DDDDDD", 1))
		_path("M%s %s l4 9 l10 1 l-8 6 l3 10 l-9 -5 l-9 5 l3 -10 l-8 -6 l10 -1 z" % [_n(cx), _n(top + 4)], "#FFD23F", _stroke("#C99410", 1.5))
		return
	if season != "autumn":
		return
	_path("M%s %s V%s" % [_n(cx), _n(top - 14), _n(top)], "none", _stroke("#DDDDDD", 1))
	_path("M%s %s q-17 0 -17 22 v26 l5.7 -6 l5.7 6 l5.7 -6 l5.7 6 l5.7 -6 l5.7 6 v-26 q0 -22 -17 -22 z" % [_n(cx), _n(top)],
		"#FBFBF8", _stroke("#C9C9C2", 1.5) + ' stroke-linejoin="round"')
	_circle(cx - 5, top + 15, 2.6, "#2B2B2B")
	_circle(cx + 5, top + 15, 2.6, "#2B2B2B")
	out.append('<ellipse cx="%s" cy="%s" rx="2.5" ry="3.5" fill="#2B2B2B"/>' % [_n(cx), _n(top + 24)])


func _cobweb(x: float, y: float, dir: float) -> void:
	if season != "autumn":
		return
	var st := _stroke("#F4F4F0", 1) + ' opacity="0.75"'
	for i in 5:
		var a := PI * 0.5 * i / 4.0
		_path("M%s %s L%s %s" % [_n(x), _n(y), _n(x + dir * cos(a) * 42.0), _n(y + sin(a) * 42.0)], "none", st)
	for ring in [12.0, 24.0, 36.0]:
		var parts := PackedStringArray()
		for i in 5:
			var a := PI * 0.5 * i / 4.0
			parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(x + dir * cos(a) * ring), _n(y + sin(a) * ring)])
		_path(" ".join(parts), "none", st)
	_circle(x + dir * 22.0, y + 26.0, 3.5, "#1E1E1E")


func _string_lights(x0: float, x1: float, y: float) -> void:
	var pts := PackedStringArray()
	var x := x0 + 6.0
	while x < x1 - 6.0:
		pts.append("%s%s %s" % ["M" if pts.is_empty() else "L", _n(x), _n(y + 3 + 7.0 * sin(PI * fmod((x - x0) / 40.0, 1.0)))])
		x += 5.0
	_path(" ".join(pts), "none", _stroke("#2B2B2B", 1))
	x = x0 + 14.0
	var i := 0
	while x < x1 - 10.0:
		var sag := 7.0 * sin(PI * fmod((x - x0) / 40.0, 1.0))
		var col := "#FF8A3D" if i % 2 == 0 else "#B266FF"
		if season == "winter":
			col = ["#FF5D5D", "#FFD23F", "#5DD06A", "#5DA8FF"][i % 4]
		elif season != "autumn":
			col = "#FFF3C4"
		_circle(x, y + 8 + sag, 7, col, 'opacity="0.35"')
		_circle(x, y + 7 + sag, 3.2, col)
		x += 20.0
		i += 1


# Seasonal planters where the Halloween pumpkins sit: tulips, geraniums, or a little snowy spruce.
func _planter(cx: float, bottom: float, s: float) -> void:
	var w := 30.0 * s
	_path("M%s %s h%s l%s %s h%s z" % [_n(cx - w / 2), _n(bottom - 18 * s), _n(w), _n(-4 * s), _n(18 * s), _n(-w + 8 * s)], "#B5603F", _stroke("#7E3E28", 1.5))
	_planter_plant(cx, bottom - 18 * s, s)


func _planter_plant(cx: float, soil: float, s: float) -> void:
	match season:
		"spring":
			for i in 5:
				var x := cx + (i - 2) * 6.0 * s
				_path("M%s %s V%s" % [_n(x), _n(soil), _n(soil - 20 * s)], "none", _stroke("#4E8A3A", 2.5 * s))
				out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [_n(x), _n(soil - 22 * s), _n(4 * s), _n(6 * s), ["#E04F5F", "#FFD23F", "#F2A7C9", "#FF8A3D", "#C084FC"][i]])
		"summer":
			for i in 6:
				_circle(cx + (i - 2.5) * 5.0 * s, soil - 8 * s - (i % 2) * 4 * s, 7 * s, "#4FA34A")
			for i in 4:
				_circle(cx + (i - 1.5) * 7.0 * s, soil - 18 * s, 4.5 * s, "#E0303A")
		"winter":
			_path("M%s %s l%s %s h%s z" % [_n(cx - 14 * s), _n(soil), _n(14 * s), _n(-38 * s), _n(14 * s)], "#2E5A3A", _stroke("#1E3E28", 1.5))
			_path("M%s %s l%s %s l%s %s" % [_n(cx - 10 * s), _n(soil - 8 * s), _n(10 * s), _n(-6 * s), _n(10 * s), _n(6 * s)], "none", _stroke("#F7F9FB", 3 * s))
			_circle(cx, soil - 38 * s, 3 * s, "#FFD23F")


# Winter: a cushion of snow on a ledge from x to x + w at height y.
func _snow(x: float, w: float, y: float) -> void:
	if season != "winter" or w <= 4.0:
		return
	var parts := PackedStringArray(["M%s %s" % [_n(x), _n(y + 1)]])
	var i := 0
	var sx := x
	while sx < x + w:
		var step := minf(14.0, x + w - sx)
		parts.append("Q%s %s %s %s" % [_n(sx + step / 2), _n(y - 5 - (i % 3)), _n(sx + step), _n(y + 0.5)])
		sx += step
		i += 1
	parts.append("L%s %s L%s %s Z" % [_n(x + w), _n(y + 2), _n(x), _n(y + 2)])
	_path(" ".join(parts), "#F7F9FB", _stroke("#D3DCE4", 1))


# Winter: only some doors have a wreath, always the same ones (from the house and the floor, no random numbers drawn).
func _door_wreath(cx: float, top: float, cy: float) -> void:
	if season == "winter" and absi(hash("%s:%d" % [k.name, int(top)])) % 100 < WREATH_PERCENT:
		_wreath(cx, cy)


# Winter: a wreath with a red bow on the door.
func _wreath(cx: float, cy: float) -> void:
	_circle(cx, cy, 15, "none", _stroke("#2E5A3A", 8))
	for i in 8:
		var a := TAU * i / 8.0
		_circle(cx + cos(a) * 15.0, cy + sin(a) * 15.0, 2.2, "#C8202A" if i % 2 == 0 else "#FFD23F")
	_path("M%s %s l-8 -6 v12 z M%s %s l8 -6 v12 z" % [_n(cx), _n(cy + 15), _n(cx), _n(cy + 15)], "#C8202A")


# A lane tree's leaf clump colour this season (snow-laden branches in winter).
func _canopy(autumn: String) -> String:
	var i := absi(hash(autumn)) % 5
	match season:
		"spring":
			return ["#9BCB6A", "#F7C6D9", "#B5D97A", "#F2A7C9", "#7FB85A"][i]
		"summer":
			return ["#3E8E3A", "#4FA34A", "#2F7A30", "#5DB55A", "#367F33"][i]
		"winter":
			return ["#E8EEF3", "#DCE4EA", "#F4F7FA", "#CBD5DD", "#E2E8EE"][i]
	return autumn


# A garden bush's colour this season (the autumn one maps to a spring, summer or snowy-evergreen one).
func _bush(autumn: String) -> String:
	var i := AUTUMN_BUSHES.find(autumn)
	match season:
		"spring":
			return ["#7FB85A", "#9BCB6A", "#F2A7C9", "#5F9F4A", "#A6D07A", "#6FA048"][i]
		"summer":
			return ["#3E8E3A", "#4FA34A", "#2F7A30", "#5DB55A", "#367F33", "#447F33"][i]
		"winter":
			return ["#3E5A44", "#4A5A4A", "#3A5040", "#46584A", "#3E4E44", "#4E6050"][i]
	return autumn


func _bat(cx: float, cy: float, s: float) -> void:
	_path("M%s %s q-6 -6 -14 -2 q4 2 3 6 q4 -2 6 2 q2 -3 5 -2 q3 -1 5 2 q2 -4 6 -2 q-1 -4 3 -6 q-8 -4 -14 2 z" % [_n(cx), _n(cy)], "#1E1E1E",
		'transform="translate(%s %s) scale(%s) translate(%s %s)"' % [_n(cx), _n(cy), str(s), _n(-cx), _n(-cy)])


func _segments(x0: float, x1: float, gaps: Array) -> Array:
	var segs := []
	var a := x0
	for g in gaps:
		if g[0] > a and g[0] < x1:
			segs.append([a, g[0]])
		a = maxf(a, g[1])
	if a < x1:
		segs.append([a, x1])
	return segs


func _polyline(pts: Array[Vector2], offset: Vector2) -> String:
	var parts := PackedStringArray()
	for i in pts.size():
		parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(pts[i].x + offset.x), _n(pts[i].y + offset.y)])
	return " ".join(parts)


func _line(d: String, width: float) -> void:
	if k.metal_light:
		_path(d, "none", _stroke("#8E8E8A", width + 2) + ' stroke-linecap="round" stroke-linejoin="round"')
	_path(d, "none", _stroke(k.metal, width) + ' stroke-linecap="round" stroke-linejoin="round"')


func _metal_stroke() -> String:
	return _stroke("#8E8E8A", 1) if k.metal_light else ""


func _pick(colors: Array) -> String:
	return colors[0] if rng.randf() < 0.55 else colors[rng.randi_range(1, colors.size() - 1)]


func _n(v: float) -> String:
	return str(snappedf(v, 0.1))


func _stroke(color: String, width: float) -> String:
	return 'stroke="%s" stroke-width="%s"' % [color, _n(width)]


func _rect(x: float, y: float, w: float, h: float, fill: String, extra := "") -> void:
	out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" %s/>' % [_n(x), _n(y), _n(w), _n(h), fill, extra])


func _circle(x: float, y: float, r: float, fill: String, extra := "") -> void:
	out.append('<circle cx="%s" cy="%s" r="%s" fill="%s" %s/>' % [_n(x), _n(y), _n(r), fill, extra])


func _path(d: String, fill: String, extra := "") -> void:
	out.append('<path d="%s" fill="%s" %s/>' % [d, fill, extra])


# ── Across 6e Avenue: the odd side, from Street View ─────────────────────────
# The buildings facing Charlotte's block, 5601 to 5733 (reference/streetview/INDEX.md, "6e Avenue 5600–5800 (impairs)"), drawn as
# docs/drawing-from-streetview.md says. What they share goes into options any plex can take (a mansard, a corbelled parapet, flat
# aluminium canopies, striped canvas awnings, one balcony per flat, wooden and chain-link fences); the few that are like nothing
# else on the street are kinds of their own (`_gables`, `_bungalow`, `_corner_yard`, `_lane_odd`).


# A mansard front over the top floor (6e-avenue/5649…, 5653…, 5665…): a steep face of dark slate shingles from a white fascia
# just over the windows up to its ridge, between two brick fire walls capped in stone that stand a little proud of it.
func _mansard(top: float) -> void:
	var slate: String = k.get("slate", "#4B4F57")
	var slate_dark := "#" + Color(slate).darkened(0.38).to_html(false)
	var slate_light := "#" + Color(slate).lightened(0.22).to_html(false)
	var wall := 26.0
	var ridge := top - 16.0
	var eave := top + 54.0
	var a := X0 + wall
	var b := X1 - wall
	# The face leans back, so it is a little narrower at the ridge; light from the upper left fades across it.
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(a), _n(eave), _n(a + 6), _n(ridge), _n(b - 6), _n(ridge), _n(b), _n(eave)], slate, _stroke(slate_dark, 2))
	var y := ridge + 7.0
	var row := 0
	while y < eave - 3.0:
		var lean := lerpf(6.0, 0.0, (y - ridge) / (eave - ridge))
		_path("M%s %s H%s" % [_n(a + lean), _n(y), _n(b - lean)], "none", _stroke(slate_dark, 1.3))
		_path("M%s %s H%s" % [_n(a + lean), _n(y - 1.5), _n(b - lean)], "none", _stroke(slate_light, 0.8) + ' opacity="0.45"')
		var x := a + lean + (10.0 if row % 2 == 1 else 0.0)
		while x < b - lean - 4.0:
			_path("M%s %s v%s" % [_n(x), _n(y - 7.0), _n(7.0)], "none", _stroke(slate_dark, 1.0) + ' opacity="0.65"')
			x += 20.0
		y += 8.0
		row += 1
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(a), _n(eave), _n(a + 6), _n(ridge), _n(b - 6), _n(ridge), _n(b), _n(eave)], "url(#sun)")
	_rect(a + 4, ridge - 5, b - a - 8, 6, slate_light, _stroke(slate_dark, 1))
	# The fascia at the eave, its gutter, the shade it throws on the bricks.
	_rect(a - 6, eave, b - a + 12, 10, "#F4F2EC", _stroke("#B9B5AC", 1.5))
	_rect(a - 6, eave + 10, b - a + 12, 4, "#C9C5BC")
	_rect(a - 2, eave + 14, b - a + 4, 18, "url(#drop)")
	# The two fire walls, brick, under a stone cap each.
	for side: float in [X0, b]:
		var y0 := ridge - 12.0
		_rect(side, y0, wall, eave - y0 + 14.0, k.bricks[0])
		var by := y0 + 4.0
		while by < eave + 12.0:
			_rect(side, by, wall, 1.5, k.mortar)
			by += 13.0
		_rect(side, y0, wall, eave - y0 + 14.0, "url(#shade)")
		_rect(side - 3, y0 - 8, wall + 6, 9, k.lintel, _stroke(k.lintel_dark, 1.5))
		_rect(side - 3, y0 - 8, wall + 6, 2, "#FFFFFF", 'opacity="0.35"')
		_snow(side - 3, wall + 6, y0 - 8)
	_snow(a + 4, b - a - 8, ridge - 5)
	_snow(a - 6, b - a + 12, eave)


# A corbelled brick parapet (6e-avenue/5661…, 5671…): two courses of brick dentils standing out under a stone coping, its middle
# third raised a few courses under its own coping, a short pier at each end.
func _corbel_parapet(top: float) -> void:
	var brick: String = k.bricks[0]
	var dark := "#" + Color(brick).darkened(0.25).to_html(false)
	var mid0 := lerpf(X0, X1, 0.33)
	var mid1 := lerpf(X0, X1, 0.67)
	_rect(mid0, top - 22, mid1 - mid0, 24, brick)
	_rect(mid0, top - 9, mid1 - mid0, 1.5, k.mortar)
	for px: float in [X0 - 2.0, X1 - 26.0]:
		_rect(px, top - 26, 28, 30, brick)
		_rect(px, top - 13, 28, 1.5, k.mortar)
	_rect(X0 - 4, top - 10, X1 - X0 + 8, 10, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(X0 - 4, top - 10, X1 - X0 + 8, 2, "#FFFFFF", 'opacity="0.35"')
	_rect(mid0 - 6, top - 32, mid1 - mid0 + 12, 10, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(mid0 - 6, top - 32, mid1 - mid0 + 12, 2, "#FFFFFF", 'opacity="0.35"')
	for px: float in [X0 - 2.0, X1 - 26.0]:
		_rect(px - 3, top - 33, 34, 8, k.lintel, _stroke(k.lintel_dark, 1.5))
	# The dentils: every other brick standing out, each with its shadow under it and to the right.
	for course in 2:
		var y := top + 16.0 + course * 13.0
		var x := X0 + 4.0 + course * 9.0
		while x < X1 - 12.0:
			_rect(x + 2, y + 2, 12, 10, "#000000", 'opacity="0.22"')
			_rect(x, y, 12, 10, dark if course == 0 else brick, _stroke(dark, 0.8))
			_rect(x, y, 12, 2, "#FFFFFF", 'opacity="0.18"')
			x += 18.0
	_rect(X0, top + 44, X1 - X0, 5, dark)
	_rect(X0, top + 49, X1 - X0, 12, "url(#drop)")
	_snow(X0 - 4, X1 - X0 + 8, top - 10)
	_snow(mid0 - 6, mid1 - mid0 + 12, top - 32)


# The flat aluminium canopy over a top balcony (6e-avenue/5649…, 5661…, 5669…, 5677…): a white fascia on a ribbed soffit seen from
# below, its shade on the wall, a thin bracket back to the wall at each end. It stands on no posts.
func _alu_canopy(x0: float, x1: float, y: float) -> void:
	var col: String = k.canopy
	var dark := "#" + Color(col).darkened(0.32).to_html(false)
	var under := "#" + Color(col).darkened(0.14).to_html(false)
	var l := x0 - 26.0
	var r := x1 + 26.0
	var deep := 34.0
	_rect(x0 - 6, y + 16 + deep, x1 - x0 + 12, 46, "url(#drop)")
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0 - 6), _n(y + 16 + deep), _n(x1 + 6), _n(r), _n(y + 16), _n(l)], under, _stroke(dark, 1))
	var x := l + 10.0
	while x < r - 4.0:
		var wx := lerpf(x0 - 6, x1 + 6, (x - l) / (r - l))
		_path("M%s %s L%s %s" % [_n(x), _n(y + 16), _n(wx), _n(y + 16 + deep)], "none", _stroke(dark, 0.9) + ' opacity="0.5"')
		x += 12.0
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0 - 6), _n(y + 16 + deep), _n(x1 + 6), _n(r), _n(y + 16), _n(l)], "url(#drop)", 'opacity="0.6"')
	_rect(l, y, r - l, 17, col, _stroke(dark, 1.5))
	_rect(l, y, r - l, 4, "#FFFFFF", 'opacity="0.6"')
	_rect(l, y + 13, r - l, 4, dark, 'opacity="0.45"')
	for side: float in [-1.0, 1.0]:
		var bx := x0 - 2.0 if side < 0.0 else x1 + 2.0
		_path("M%s %s L%s %s" % [_n(bx), _n(y + 16 + deep + 14), _n(bx + side * 20.0), _n(y + 17)], "none", _stroke(k.metal, 3) + ' stroke-linecap="round"')
	_snow(l, r - l, y)


# A canvas awning in red and white stripes over a balcony door and window (6e-avenue/5623…, 5631…, 5635…): along the wall at the
# top, sloping out and down to a scalloped valance, on two thin arms, its shade on the bricks under it.
func _stripe_awning(x0: float, x1: float, y: float, colour := "") -> void:
	var red: String = colour if colour != "" else k.get("stripe_color", "#C8343A")
	var pale := "#F4F1EA"
	var drop := 44.0
	var reach := 14.0
	_rect(x0 - 4, y + drop + 6, x1 - x0 + 8, 30, "url(#drop)")
	var n := maxi(int((x1 - x0) / 15.0), 4)
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var a0 := lerpf(x0, x1, t0)
		var a1 := lerpf(x0, x1, t1)
		var b0 := lerpf(x0 - reach, x1 + reach, t0)
		var b1 := lerpf(x0 - reach, x1 + reach, t1)
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(a0), _n(y), _n(a1), _n(y), _n(b1), _n(y + drop), _n(b0), _n(y + drop)], red if i % 2 == 0 else pale)
		# The scalloped valance hanging from its edge.
		_path("M%s %s H%s V%s Q%s %s %s %s Z" % [_n(b0), _n(y + drop), _n(b1), _n(y + drop + 8), _n((b0 + b1) / 2.0), _n(y + drop + 16), _n(b0), _n(y + drop + 8)], red if i % 2 == 0 else pale)
	# The canvas curves away from the light toward its edge.
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0 - reach * 0.5), _n(y + drop * 0.5), _n(x1 + reach * 0.5), _n(x1 + reach), _n(y + drop), _n(x0 - reach)], "#000000", 'opacity="0.1"')
	_path("M%s %s H%s" % [_n(x0), _n(y), _n(x1)], "none", _stroke("#" + Color(red).darkened(0.35).to_html(false), 3))
	_path("M%s %s H%s" % [_n(x0 - reach), _n(y + drop), _n(x1 + reach)], "none", _stroke("#" + Color(red).darkened(0.35).to_html(false), 1.5))
	for side: float in [-1.0, 1.0]:
		var ax := x0 + 4.0 if side < 0.0 else x1 - 4.0
		_path("M%s %s L%s %s" % [_n(ax), _n(y + drop + 30), _n(ax + side * reach), _n(y + drop)], "none", _stroke("#5E6266", 2))
	_snow(x0, x1 - x0, y)


# A low fence of wooden pickets, the wood left its own warm colour (6e-avenue/5615…, 5631…).
func _wood_fence(gaps: Array) -> void:
	var wood: String = k.get("fence_wood", "#C98A62")
	var dark := "#" + Color(wood).darkened(0.3).to_html(false)
	var top := ground_y - 44.0
	for seg in _segments(X0, X1, gaps):
		var a: float = seg[0]
		var b: float = seg[1]
		_rect(a, top + 10, b - a, 6, dark)
		_rect(a, ground_y - 14, b - a, 6, dark)
		var x := a + 4.0
		var i := 0
		while x < b - 8.0:
			var h := 4.0 if i % 2 == 0 else 0.0
			_path("M%s %s V%s L%s %s L%s %s V%s Z" % [_n(x), _n(ground_y - 2), _n(top + 4 - h), _n(x + 5), _n(top - 2 - h), _n(x + 10), _n(top + 4 - h), _n(ground_y - 2)], wood, _stroke(dark, 1))
			_rect(x + 1, top + 2 - h, 2.5, ground_y - top - 6 + h, "#FFFFFF", 'opacity="0.22"')
			x += 15.0
			i += 1
		_snow(a, b - a, top - 2)


# A chain-link fence on galvanised posts (6e-avenue/5601…, 5605…, 5617…): the mesh in two crossing sets of fine wires, a top rail.
func _chain_fence(gaps: Array) -> void:
	var top := ground_y - 58.0
	var wire := _stroke("#B9BDC1", 1.1) + ' opacity="0.75"'
	for seg in _segments(X0, X1, gaps):
		var a: float = seg[0]
		var b: float = seg[1]
		var parts := PackedStringArray()
		var x := a - (ground_y - top)
		while x < b:
			# One wire down to the right and one down to the left from every point along the top, clipped to the panel.
			var x0 := maxf(x, a)
			var y0 := top + (x0 - x)
			var x1 := minf(x + (ground_y - top), b)
			var y1 := top + (x1 - x)
			if x1 > x0:
				parts.append("M%s %s L%s %s" % [_n(x0), _n(y0), _n(x1), _n(y1)])
			var u0 := maxf(x, a)
			var v0 := ground_y - (u0 - x)
			var u1 := minf(x + (ground_y - top), b)
			var v1 := ground_y - (u1 - x)
			if u1 > u0:
				parts.append("M%s %s L%s %s" % [_n(u0), _n(v0), _n(u1), _n(v1)])
			x += 9.0
		_path(" ".join(parts), "none", wire)
		_rect(a, top - 2, b - a, 4, "#A9AEB3", _stroke("#7E8388", 0.8))
		var px := a
		while px <= b:
			_rect(px - 2.5, top - 6, 5, ground_y - top + 6, "#A9AEB3", _stroke("#7E8388", 0.8))
			_rect(px - 4, top - 9, 8, 4, "#8E9398")
			px += maxf((b - a) / maxf(roundf((b - a) / 120.0), 1.0), 40.0)
		_snow(a, b - a, top - 2)


# A hydrangea bush: leaves, and big round heads of flowers, white in summer, gone pink and papery in autumn, bare and snowy in
# winter. The same random draws in every season.
func _hydrangea(x: float, r: float) -> void:
	_shrub(x, r, "#5E8A3A")
	var heads: Array = {"spring": [], "summer": ["#F4F3EE", "#E9EEF2", "#F7F1E6"], "autumn": ["#D9B5A0", "#E3C6B2", "#C99C8A", "#E8D5C0"], "winter": []}[season]
	for i in 4:
		var hx := x + rng.randf_range(-r * 0.7, r * 0.7)
		var hy := ground_y - r * rng.randf_range(0.7, 1.35)
		var hr := r * rng.randf_range(0.28, 0.4)
		if heads.is_empty():
			continue
		var c: String = heads[i % heads.size()]
		_circle(hx + 2, hy + 3, hr * 0.95, "#000000", 'opacity="0.14"')
		_circle(hx, hy, hr * 0.8, "#" + Color(c).darkened(0.18).to_html(false))
		for j in 14:
			var a := TAU * j / 14.0 + j * 0.7
			var d := hr * (0.15 + 0.62 * float(j % 5) / 4.0)
			var f := Vector2(hx + cos(a) * d, hy + sin(a) * d * 0.9)
			var lit := (hx - f.x + hy - f.y) / (hr * 2.0)
			var tone := Color(c).lightened(clampf(lit, 0.0, 1.0) * 0.25) if lit > 0.0 else Color(c).darkened(clampf(-lit, 0.0, 1.0) * 0.2)
			for petal in 4:
				var pa := petal * PI / 2.0 + a
				_circle(f.x + cos(pa) * hr * 0.11, f.y + sin(pa) * hr * 0.11, hr * 0.12, "#" + tone.to_html(false))
			_circle(f.x, f.y, hr * 0.05, "#" + Color(c).darkened(0.35).to_html(false))


# A glass balcony rail: clear panels with the sky in them between thin black posts, a black cap rail (6e-avenue/5725…, 5729…).
func _glass_rail(x0: float, x1: float, floor_y: float) -> void:
	var top := floor_y - 52.0
	_rect(x0 - 6, floor_y, x1 - x0 + 12, 14, k.slab, _stroke(k.slab_dark, 1.5))
	_rect(x0 - 2, floor_y + 14, x1 - x0 + 4, 26, "url(#drop)")
	_rect(x0, top, x1 - x0, floor_y - top, "#CFE4EC", 'opacity="0.35"')
	var x := x0
	while x < x1 - 2.0:
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x + 10), _n(top + 4), _n(x + 22), _n(top + 4), _n(x + 8), _n(floor_y - 4), _n(x - 4), _n(floor_y - 4)], "#FFFFFF", 'opacity="0.25"')
		x += 44.0
	var px := x0
	while px <= x1 + 0.5:
		_rect(px - 1.5, top, 3, floor_y - top, "#1F1F1F")
		px += maxf((x1 - x0) / maxf(roundf((x1 - x0) / 90.0), 1.0), 30.0)
	_rect(x0 - 2, top - 3, x1 - x0 + 4, 4, "#1F1F1F")
	_snow(x0 - 6, x1 - x0 + 12, floor_y - 2)


# 5601–5609, at the Dandurand corner (6e-avenue/5601…, 5605…, 5609… and their close-ups): a block of the 1990s in salmon brick,
# three floors and a half. Two bays faced in tan siding come forward under their own gables; between them the way in: a gabled
# porch on two thin posts over a landing a few steps up, two white doors side by side, a black railing and its stair down to the
# left; small white windows high in the brick. A chain-link fence along the sidewalk, hydrangeas behind it.
func _gables() -> void:
	var top := _top()
	_bricks(top, base_y)
	_wall_shading(top)
	_foundation()
	_flat_parapet(top)
	var cx: float = k.door_cx
	var siding: String = k.get("siding", "#B9875A")
	var siding_dark := "#" + Color(siding).darkened(0.3).to_html(false)
	var trim := "#3E4146"
	var eave := 420.0
	var peak := 330.0
	# Small white windows high in the brick, and narrow ones each side of the porch (the photos).
	for w: Array in [[cx - 34.0, 96.0, 68.0, 92.0], [cx - 40.0, 300.0, 80.0, 150.0], [500.0, 300.0, 56.0, 150.0],
			[k.width - 556.0, 300.0, 56.0, 150.0], [512.0, 560.0, 56.0, 140.0], [k.width - 568.0, 560.0, 56.0, 140.0],
			[244.0, 180.0, 62.0, 92.0], [k.width - 306.0, 180.0, 62.0, 92.0]]:
		_casement(w[0], w[1], w[2], w[3])
	# The two bays.
	for bay: Array in [[110.0, 440.0], [k.width - 440.0, k.width - 110.0]]:
		var a: float = bay[0]
		var b: float = bay[1]
		var mid := (a + b) / 2.0
		var bottom := _fb(0) - 6.0
		_rect(a + 10, eave, b - a, bottom - eave + 10, "#000000", 'opacity="0.18"')
		_rect(a, eave, b - a, bottom - eave, siding)
		var y := eave + 12.0
		while y < bottom:
			_rect(a, y, b - a, 1.6, siding_dark, 'opacity="0.55"')
			_rect(a, y + 1.6, b - a, 1.2, "#FFFFFF", 'opacity="0.12"')
			y += 13.0
		_rect(a, eave, b - a, bottom - eave, "url(#sun)")
		_rect(b - 6, eave, 6, bottom - eave, "#000000", 'opacity="0.15"')
		# Its gable: the same siding, a dark fascia, the eaves turning back at the ends.
		_path("M%s %s L%s %s L%s %s Z" % [_n(a), _n(eave), _n(mid), _n(peak), _n(b), _n(eave)], siding)
		var gy := eave - 12.0
		while gy > peak + 6.0:
			var half := (b - a) / 2.0 * (gy - peak) / (eave - peak)
			_rect(mid - half, gy, half * 2.0, 1.6, siding_dark, 'opacity="0.55"')
			gy -= 13.0
		_path("M%s %s L%s %s L%s %s" % [_n(a - 18), _n(eave + 8), _n(mid), _n(peak - 10), _n(b + 18), _n(eave + 8)], "none", _stroke(trim, 9) + ' stroke-linejoin="miter"')
		_path("M%s %s L%s %s L%s %s" % [_n(a - 18), _n(eave + 15), _n(mid), _n(peak - 3), _n(b + 18), _n(eave + 15)], "none", _stroke("#F2F0EA", 3) + ' opacity="0.8"')
		for e: float in [a - 18.0, b - 4.0]:
			_rect(e, eave + 8, 22, 8, trim)
		_snow(a - 18, mid - a + 18, peak - 14)
		# Its two windows, one over the other.
		_casement(mid - 72, 470.0, 144, 150)
		_casement(mid - 72, 676.0, 144, 150)
		_rect(a, bottom, b - a, 8, "#8E8A82")
	split = out.size()
	# The porch: landing a few steps up, its roof on two thin posts, the doors under it.
	var land := _fb(0)
	var l0 := cx - 150.0
	var l1 := cx + 150.0
	var roof := land - 250.0
	var rpeak := roof - 92.0
	for dx: float in [-48.0, 48.0]:
		_rect(cx + dx - 40, land - 196, 80, 196, "#E9E6DF", _stroke("#B9B5AC", 2))
		_rect(cx + dx - 34, land - 190, 68, 190, "#F7F5F0", _stroke("#C9C5BC", 1.5))
		_rect(cx + dx - 24, land - 172, 48, 54, "url(#glass)", _stroke("#B9B5AC", 1.5))
		_raised(cx + dx - 24, land - 104, 48, 84)
		_circle(cx + dx + (24.0 if dx < 0.0 else -24.0), land - 98, 3, "#C9C5BC")
	_door_lamps(cx, land - 196, 160)
	_rect(l0 - 6, roof + 2, l1 - l0 + 12, 22, "#3A2E28")
	for px: float in [l0 + 4.0, l1 - 10.0]:
		_rect(px, roof + 14, 6, land - roof - 14, "#2B2B2E")
	_path("M%s %s L%s %s L%s %s Z" % [_n(l0 + 4), _n(roof + 4), _n(cx), _n(rpeak + 12), _n(l1 - 4), _n(roof + 4)], "#ECE7DC")
	var gy2 := roof - 4.0
	while gy2 > rpeak + 16.0:
		var half2 := (l1 - l0 - 8.0) / 2.0 * (gy2 - rpeak - 12.0) / (roof - rpeak - 8.0)
		_rect(cx - half2, gy2, half2 * 2.0, 1.4, "#C9C1B0")
		gy2 -= 11.0
	_path("M%s %s L%s %s L%s %s" % [_n(l0 - 14), _n(roof + 10), _n(cx), _n(rpeak), _n(l1 + 14), _n(roof + 10)], "none", _stroke(trim, 9))
	_circle(cx, roof + 12, 4, "#FFE9A8")
	_snow(l0 - 14, cx - l0 + 14, rpeak - 4)
	# The landing, its railing, and the stair down to the left.
	_rect(l0 - 6, land, l1 - l0 + 12, 14, "#8E8A82", _stroke("#6E6A62", 1.5))
	_balcony(l0, l1, land, [[l0 - 8.0, l0 + 44.0]])
	_stairs(Vector2(l0 + 18, land + 6), Vector2(l0 - 20, land + 36), Vector2(l0 - 60, land + 66), Vector2(l0 - 100, ground_y))
	# Hydrangeas and the chain-link fence along the sidewalk.
	for hx: float in [80.0, 200.0, 340.0, 470.0, cx + 200.0, cx + 330.0, k.width - 300.0, k.width - 150.0]:
		_hydrangea(hx, rng.randf_range(28.0, 40.0))
	_chain_fence([[l0 - 140.0, l0 - 60.0]])
	if k.halloween:
		_pumpkin(cx - 60, land, 0.9, true)
		_pumpkin(cx + 70, land, 0.7, false)


# A window of today in a plain opening (Rue Masson's renovated fronts): a thin frame in `frame` (black, brown, aluminium), one
# big pane (`fixed`) or two panes sliding side by side (`slider`), a narrow sill.
func _modern_window(x: float, y: float, w: float, h: float, slider: bool) -> void:
	var frame: String = k.get("frame", "#2B2B2E")
	_rect(x - 3, y - 3, w + 6, h + 6, "#000000", 'opacity="0.25"')
	_rect(x, y, w, h, frame)
	var lit := rng.randf() < 0.2
	_rect(x + 5, y + 5, w - 10, h - 10, "url(#warm)" if lit else "url(#glass)")
	_path("M%s %s l%s 0 l%s %s l%s 0 z" % [_n(x + w * 0.5), _n(y + 5), _n(w * 0.16), _n(-w * 0.3), _n((h - 10) * 0.6), _n(-w * 0.16)], "#FFFFFF", 'opacity="0.2"')
	_rect(x + 5, y + 5, w - 10, 8, "url(#drop)")
	if slider:
		_rect(x + w / 2.0 - 3, y + 5, 6, h - 10, frame)
		_rect(x + w / 2.0 + 3, y + 5, 2, h - 10, "#000000", 'opacity="0.2"')
	if season == "autumn" and not night:
		if not windows.has(k.name):
			windows[k.name] = []
		windows[k.name].append({"pane": [x + 5, y + 5, w - 10, h - 10], "bar_y": y + h * 0.5, "trim": frame, "lit": lit, "flower_box": false})
	_rect(x - 6, y + h + 2, w + 12, 6, k.lintel, _stroke(k.lintel_dark, 1))
	_snow(x - 6, w + 12, y + h + 2)


# A white casement window in a plain opening: two tall sashes and a stone sill (the 1990s blocks and the renovated plexes).
func _casement(x: float, y: float, w: float, h: float) -> void:
	var frame: String = k.get("frame", "#F7F5F0")
	_rect(x - 3, y - 3, w + 6, h + 6, "#000000", 'opacity="0.25"')
	_rect(x, y, w, h, frame)
	var lit := rng.randf() < 0.2
	var half := (w - 18.0) / 2.0
	for i in 2:
		var gx := x + 6.0 + i * (half + 6.0)
		_rect(gx, y + 6, half, h - 12, "url(#warm)" if lit else "url(#glass)")
		_path("M%s %s l%s 0 l%s %s l%s 0 z" % [_n(gx + half * 0.55), _n(y + 6), _n(half * 0.25), _n(-half * 0.45), _n((h - 12) * 0.5), _n(-half * 0.25)], "#FFFFFF", 'opacity="0.22"')
		_rect(gx, y + 6, half, 8, "url(#drop)")
	if season == "autumn" and not night:
		if not windows.has(k.name):
			windows[k.name] = []
		windows[k.name].append({"pane": [x + 6, y + 6, w - 12, h - 12], "bar_y": y + h * 0.5, "trim": frame, "lit": lit, "flower_box": false})
	_rect(x - 8, y + h + 2, w + 16, 8, k.lintel, _stroke(k.lintel_dark, 1))
	_rect(x - 4, y + h + 10, w + 8, 4, "#000000", 'opacity="0.15"')
	_snow(x - 8, w + 16, y + h + 2)


# 5637, the little one-storey house between the plexes (6e-avenue/5635…, 5647…): white siding under a flat roof, a white door in
# the middle under a small aluminium awning, a window each side, a narrow black iron fence along the sidewalk with its gate.
func _bungalow() -> void:
	var top := 404.0
	var cx: float = k.door_cx
	var siding: String = k.get("siding", "#F1EFE9")
	_rect(X0, top, X1 - X0, base_y - top, siding)
	var y := top + 14.0
	while y < base_y:
		_rect(X0, y, X1 - X0, 1.6, "#C9C5BC")
		_rect(X0, y + 1.6, X1 - X0, 1, "#FFFFFF", 'opacity="0.5"')
		y += 14.0
	_wall_shading(top)
	_rect(X0 - 10, top - 18, X1 - X0 + 20, 18, "#ECEAE4", _stroke("#B9B5AC", 1.5))
	_rect(X0 - 10, top - 23, X1 - X0 + 20, 5, "#9AA0A6")
	_rect(X0, top, X1 - X0, 12, "url(#drop)")
	for cap_x: float in [X0 - 10.0, X1 + 4.0]:
		_rect(cap_x, top - 18, 6, base_y - top + 18, "#E4E1DA", _stroke("#B9B5AC", 1))
	_snow(X0 - 10, X1 - X0 + 20, top - 23)
	_foundation()
	for w in k.windows:
		_window(w[0], 446.0, w[1], 126.0)
	var dw := 82.0
	_rect(cx - dw / 2 - 6, 452, dw + 12, _fb(0) - 452, "#D9D6CE", _stroke("#B9B5AC", 1.5))
	_door_leaf(k.get("door_style", "slots"), Rect2(cx - dw / 2, 458, dw, _fb(0) - 458))
	_stripe_awning(cx - 64, cx + 64, 404.0)
	_door_lamps(cx, 458, dw)
	_door_wreath(cx, 458, 518)
	split = out.size()
	_rect(cx - 62, _fb(0), 124, 14, k.step, _stroke(k.step_dark, 1.5))
	_front_steps(cx)
	var gaps := [[cx - 66, cx + 66]]
	_garden(gaps)
	_fence(gaps)
	if k.halloween:
		_pumpkin(cx - 52, _fb(0), 0.9, true)


# The corner of 6e and Holt across the street (6e-avenue/5721…5733 and their close-ups): a two-storey house in red brick on a base
# painted terracotta, at the corner, and beside it its big yard. Along the sidewalk a low terracotta wall: in front of the house a
# white picket fence between brick piers, then a wooden gate between two piers with a black lantern on each, then a tall fence of
# red-stained boards with a lattice along its top, the yard's big old tree rising behind it. Cedars by the corner.
func _corner_yard() -> void:
	var house := 620.0
	var top := 170.0
	# Behind the yard, across the backyards, the houses of Rue Holt, hazy: the distant city must not show as a pale slab over
	# a yard this low. On a saved random state, so the yard's own draws don't change.
	var saved := rng.state
	_back_row(house, X1, ground_y - 560.0, ground_y - 120.0)
	rng.state = saved
	var keep := X1
	X1 = house
	_bricks(top, base_y)
	_wall_shading(top)
	_flat_parapet(top)
	X1 = keep
	# The terracotta base all along the house.
	_rect(X0, base_y - 46, house - X0, ground_y - base_y + 46, "#B8553C", _stroke("#8E3F2C", 1.5))
	_rect(X0, base_y - 46, house - X0, 4, "#D27A5E")
	for w: Array in [[70.0, 120.0], [250.0, 120.0]]:
		_casement(w[0], 214.0, w[1], 140.0)
		_casement(w[0], 432.0, w[1], 140.0)
	# The way in at the right of the house: a door under a flat white canopy, a balcony with a glass rail over it.
	var dx := 500.0
	_rect(dx - 52, 408, 104, _fb(0) - 408, "#2B2B2E")
	_door_leaf("slit", Rect2(dx - 44, 416, 88, _fb(0) - 416))
	_rect(dx - 70, 392, 140, 12, "#F2F0EA", _stroke("#B9B5AC", 1.5))
	_rect(dx - 66, 404, 132, 14, "url(#drop)")
	_casement(dx - 50, 214, 100, 150)
	_glass_rail(house - 220, house - 6, 372.0)
	_door_wreath(dx, 416, 476)
	split = out.size()
	# Cedars by the corner, evergreen, snow on them in winter.
	for c: Array in [[58.0, 300.0], [104.0, 330.0]]:
		_cedar(c[0], c[1])
	for s: Array in [[150.0, 30.0], [262.0, 26.0], [372.0, 32.0], [560.0, 28.0]]:
		_shrub(s[0], s[1], _bush(_pick(AUTUMN_BUSHES)))
	# The yard's tree, behind the fence.
	rng.seed = hash(k.name) + 7
	# Kept inside the drawing: its crown stops short of the lane, which is drawn as a picture of its own.
	_fine_tree(Vector2(830, ground_y - 60), 420.0, -PI * 0.55, 1.25, ["#E3A33A", "#D9A23A", "#C9562E", "#E8B54A", "#D9682B"])
	# The low terracotta wall along the sidewalk.
	_rect(X0, ground_y - 46, X1 - X0, 46, "#B8553C", _stroke("#8E3F2C", 1.5))
	_rect(X0, ground_y - 46, X1 - X0, 4, "#D27A5E")
	_snow(X0, X1 - X0, ground_y - 46)
	var piers := [X0, 220.0, 420.0, 610.0, 700.0]
	# White pickets in front of the house, between the piers.
	for i in 3:
		var a: float = piers[i] + 30.0
		var b: float = piers[i + 1]
		_rect(a, ground_y - 86, b - a, 5, "#F4F2EC", _stroke("#B9B5AC", 0.8))
		_rect(a, ground_y - 62, b - a, 5, "#F4F2EC", _stroke("#B9B5AC", 0.8))
		var x := a + 4.0
		while x < b - 8.0:
			_path("M%s %s V%s L%s %s L%s %s V%s Z" % [_n(x), _n(ground_y - 46), _n(ground_y - 92), _n(x + 4.5), _n(ground_y - 100), _n(x + 9), _n(ground_y - 92), _n(ground_y - 46)], "#F7F5F0", _stroke("#B9B5AC", 0.8))
			x += 15.0
		_snow(a, b - a, ground_y - 86)
	# The wooden gate, its arched top, between the last two piers.
	var g0: float = piers[3] + 30.0
	var g1: float = piers[4]
	_path("M%s %s V%s Q%s %s %s %s V%s Z" % [_n(g0), _n(ground_y - 4), _n(ground_y - 140), _n((g0 + g1) / 2.0), _n(ground_y - 162), _n(g1), _n(ground_y - 140), _n(ground_y - 4)], "#9A4A34", _stroke("#6A3022", 1.5))
	var bx := g0 + 6.0
	while bx < g1 - 4.0:
		_rect(bx, ground_y - 150, 1.5, 146, "#6A3022", 'opacity="0.6"')
		bx += 10.0
	_rect(g0, ground_y - 96, g1 - g0, 6, "#6A3022")
	# The tall board fence in front of the yard, a lattice along its top, posts every so often.
	var f0: float = piers[4] + 30.0
	var ftop := ground_y - 196.0
	_rect(f0, ftop + 30, X1 - f0, ground_y - 46 - ftop - 30, "#9A4A34")
	var x2 := f0
	while x2 < X1:
		_rect(x2, ftop + 30, 1.6, ground_y - 46 - ftop - 30, "#6A3022", 'opacity="0.55"')
		_rect(x2 + 2, ftop + 30, 2, ground_y - 46 - ftop - 30, "#C2664A", 'opacity="0.35"')
		x2 += 13.0
	_rect(f0, ftop + 24, X1 - f0, 6, "#6A3022")
	_rect(f0, ftop, X1 - f0, 24, "#9A4A34", 'opacity="0.35"')
	var parts := PackedStringArray()
	var lx := f0 - 24.0
	while lx < X1:
		parts.append("M%s %s L%s %s M%s %s L%s %s" % [_n(maxf(lx, f0)), _n(ftop + 24 - (maxf(lx, f0) - lx)), _n(minf(lx + 24, X1)), _n(ftop + 24 - (minf(lx + 24, X1) - lx)),
			_n(maxf(lx, f0)), _n(ftop + (maxf(lx, f0) - lx)), _n(minf(lx + 24, X1)), _n(ftop + (minf(lx + 24, X1) - lx))])
		lx += 12.0
	_path(" ".join(parts), "none", _stroke("#9A4A34", 3))
	_rect(f0, ftop - 4, X1 - f0, 6, "#7E3A28")
	var px := f0
	while px < X1:
		_rect(px, ftop - 10, 10, ground_y - 46 - ftop + 10, "#7E3A28")
		px += 150.0
	_snow(f0, X1 - f0, ftop - 4)
	# The piers last, over the panels, each brick with a stone cap; a lantern on the two by the gate.
	for i in piers.size():
		var p: float = piers[i]
		_rect(p, ground_y - 120, 30, 120, k.bricks[1])
		var py := ground_y - 116.0
		while py < ground_y:
			_rect(p, py, 30, 1.5, k.mortar)
			py += 13.0
		_rect(p, ground_y - 120, 30, 120, "url(#shade)")
		_rect(p - 4, ground_y - 128, 38, 9, "#D9D4C8", _stroke("#A39D93", 1))
		_snow(p - 4, 38, ground_y - 128)
		if i >= 3:
			_lantern_post(p + 15.0, ground_y - 128.0)


# A narrow evergreen (a cedar hedge tree): a tall rounded cone of dark sprays, the sun on its left, snow on it in winter.
func _cedar(x: float, top: float) -> void:
	var bottom := ground_y - 40.0
	var w := 46.0
	_path("M%s %s Q%s %s %s %s Q%s %s %s %s Z" % [_n(x - w / 2), _n(bottom), _n(x - w * 0.6), _n(top + 60), _n(x), _n(top), _n(x + w * 0.6), _n(top + 60), _n(x + w / 2), _n(bottom)], "#2F4E2C")
	for i in 40:
		var t := rng.randf()
		var y := lerpf(top + 10.0, bottom - 6.0, t)
		var half := w * 0.5 * clampf(sqrt(t) * 1.15, 0.2, 1.0)
		var sx := x + rng.randf_range(-half, half)
		var c := "#4E7A3E" if sx < x else "#3A5E34"
		_path("M%s %s q%s %s %s %s" % [_n(sx), _n(y), _n(-6), _n(-4), _n(-10), _n(4)], "none", _stroke(c, 3) + ' stroke-linecap="round"')
	if season == "winter":
		for i in 6:
			var y := lerpf(top + 20.0, bottom - 20.0, i / 5.0)
			out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="5" fill="#F7F9FB"/>' % [_n(x - 4), _n(y), _n(w * 0.25 * clampf(float(i + 1) / 5.0, 0.3, 1.0))])


# A black lantern on top of a gate pier.
func _lantern_post(x: float, y: float) -> void:
	_circle(x, y - 22, 18, "url(#glow)")
	_rect(x - 8, y - 4, 16, 4, "#1A1A1A")
	_rect(x - 7, y - 32, 14, 28, "#ECE7DA", _stroke("#1A1A1A", 2))
	_path("M%s %s h14 v28 h-14 z M%s %s v28" % [_n(x - 7), _n(y - 32), _n(x), _n(y - 32)], "none", _stroke("#1A1A1A", 1.5))
	_path("M%s %s l9 -9 l9 9 z" % [_n(x - 9), _n(y - 32)], "#1A1A1A")


# The lane entrances across 6e Avenue (k.lane_style). "holt", near Holt (6e-avenue/5713…, 5717…): wide and gravelled, the corner
# yard's red board fence on its terracotta wall running in along its left, the beige brick side of 5713 on its right, a yellow
# diamond sign for the children on a pole. "dandurand", near Dandurand (6e-avenue/5609…, 5617…): asphalt, the dark brick side of
# 5615 on its left, a chain-link fence on its right with 5601's salmon brick beyond, the one-way sign on its pole.
func _lane_odd() -> void:
	var holt: bool = k.get("lane_style", "holt") == "holt"
	var cx: float = k.width / 2.0
	var vp := Vector2(cx + (14.0 if holt else -10.0), 470.0)
	var far := 0.7
	var at := func(p: Vector2, d: float) -> Vector2: return vp + (p - vp) * (1.0 - d)
	var poly := func(pts: Array, fill: String, extra := "") -> void:
		var parts := PackedStringArray()
		for i in pts.size():
			parts.append("%s%s %s" % ["M" if i == 0 else "L", _n(pts[i].x), _n(pts[i].y)])
		_path(" ".join(parts) + " Z", fill, extra)
	var gl := Vector2(X0, ground_y)
	var gr := Vector2(X1, ground_y)
	_lane_through(vp, 1.0 - far, 220.0)
	var r := RandomNumberGenerator.new()
	r.seed = hash(k.name) + 3
	if holt:
		# Pale gravel, two darker ruts worn in it, pebbles thickest near the mouth.
		poly.call([gl, gr, at.call(gr, far), at.call(gl, far)], "#E6EBEE" if season == "winter" else "#CDBFA2")
		for side: float in [-1.0, 1.0]:
			var a0: Vector2 = at.call(Vector2(cx + side * 120.0, ground_y), 0.0)
			var a1: Vector2 = at.call(Vector2(cx + side * 120.0, ground_y), far)
			_path("M%s %s L%s %s" % [_n(a0.x), _n(a0.y), _n(a1.x), _n(a1.y)], "none", _stroke("#B3A486", 26) + ' opacity="0.5"')
		for i in 260:
			var d := pow(r.randf(), 1.8) * far
			var p: Vector2 = at.call(Vector2(lerpf(X0, X1, r.randf()), ground_y), d)
			var s: float = 2.6 * (1.0 - d)
			if season != "winter":
				_circle(p.x, p.y - s, s, ["#B8A98C", "#DDD2BA", "#A39477", "#E8DFCC"][i % 4])
	else:
		poly.call([gl, gr, at.call(gr, far), at.call(gl, far)], "#E6EBEE" if season == "winter" else "#77777A")
		for i in 4:
			var d := r.randf_range(0.05, far * 0.85)
			var p: Vector2 = at.call(Vector2(lerpf(X0 + 30.0, X1 - 30.0, r.randf()), ground_y), d)
			var w: float = r.randf_range(50.0, 110.0) * (1.0 - d)
			_rect(p.x - w / 2.0, p.y - w * 0.12, w, w * 0.24, "#8A8A8C" if season != "winter" else "#F2F4F6", 'opacity="0.6"')
		_lane_ground_detail(vp, far)
	# The left side.
	if holt:
		var base_top := ground_y - 46.0
		var ftop := ground_y - 196.0
		poly.call([Vector2(X0, base_top), at.call(Vector2(X0, base_top), far), at.call(gl, far), gl], "#B8553C")
		poly.call([Vector2(X0, ftop), at.call(Vector2(X0, ftop), far), at.call(Vector2(X0, base_top), far), Vector2(X0, base_top)], "#9A4A34")
		for i in 26:
			var d := far * i / 26.0
			var a: Vector2 = at.call(Vector2(X0, ftop + 30.0), d)
			var b: Vector2 = at.call(Vector2(X0, base_top), d)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#6A3022", maxf(1.6 * (1.0 - d), 0.5)) + ' opacity="0.55"')
		var l0: Vector2 = at.call(Vector2(X0, ftop + 24.0), 0.0)
		var l1: Vector2 = at.call(Vector2(X0, ftop + 24.0), far)
		_path("M%s %s L%s %s" % [_n(l0.x), _n(l0.y), _n(l1.x), _n(l1.y)], "none", _stroke("#6A3022", 5))
		var c0: Vector2 = at.call(Vector2(X0, ftop - 2.0), 0.0)
		var c1: Vector2 = at.call(Vector2(X0, ftop - 2.0), far)
		_path("M%s %s L%s %s" % [_n(c0.x), _n(c0.y), _n(c1.x), _n(c1.y)], "none", _stroke("#7E3A28", 6))
	else:
		var wtop := 70.0
		poly.call([Vector2(X0, wtop), at.call(Vector2(X0, wtop), far), at.call(gl, far), gl], "#6E3A2E")
		var y := wtop + 10.0
		while y < ground_y - 6.0:
			var a := Vector2(X0, y)
			var b: Vector2 = at.call(a, far)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#4E2A22", 0.8) + ' opacity="0.55"')
			y += 11.0
		poly.call([Vector2(X0, ground_y - 54), at.call(Vector2(X0, ground_y - 54), far), at.call(gl, far), gl], "#A8A49C")
	# The right side.
	if holt:
		var wtop := 300.0
		poly.call([Vector2(X1, wtop), at.call(Vector2(X1, wtop), far), at.call(gr, far), gr], "#D6C6A6")
		var y := wtop + 10.0
		while y < ground_y - 6.0:
			var a := Vector2(X1, y)
			var b: Vector2 = at.call(a, far)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#B3A07E", 0.8) + ' opacity="0.6"')
			y += 11.0
		poly.call([Vector2(X1, ground_y - 40), at.call(Vector2(X1, ground_y - 40), far), at.call(gr, far), gr], "#A8A49C")
		_lane_wall_detail(vp, far, 0.9, 0.12)
	else:
		poly.call([Vector2(X1, 120.0), at.call(Vector2(X1, 120.0), far), at.call(gr, far), gr], "#C08A68")
		var y := 130.0
		while y < ground_y - 6.0:
			var a := Vector2(X1, y)
			var b: Vector2 = at.call(a, far)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#9C6A4E", 0.8) + ' opacity="0.55"')
			y += 11.0
		_lane_wall_detail(vp, far, 0.14, 0.3)
		# The chain-link fence in front of 5601's side yard, coming out to the sidewalk.
		var ftop := ground_y - 64.0
		var parts := PackedStringArray()
		for i in 30:
			var d0 := far * 0.5 * i / 30.0
			var d1 := far * 0.5 * (i + 1) / 30.0
			var a: Vector2 = at.call(Vector2(X1 - 30.0, ftop), d0)
			var b: Vector2 = at.call(Vector2(X1 - 30.0, ground_y), d1)
			var c: Vector2 = at.call(Vector2(X1 - 30.0, ground_y), d0)
			var e: Vector2 = at.call(Vector2(X1 - 30.0, ftop), d1)
			parts.append("M%s %s L%s %s M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y), _n(c.x), _n(c.y), _n(e.x), _n(e.y)])
		_path(" ".join(parts), "none", _stroke("#B9BDC1", 0.9) + ' opacity="0.7"')
		for d: float in [0.0, 0.12, 0.24, 0.35]:
			var a: Vector2 = at.call(Vector2(X1 - 30.0, ftop - 4.0), d)
			var b: Vector2 = at.call(Vector2(X1 - 30.0, ground_y), d)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y)], "none", _stroke("#A9AEB3", maxf(5.0 * (1.0 - d), 1.5)))
		var t0: Vector2 = at.call(Vector2(X1 - 30.0, ftop), 0.0)
		var t1: Vector2 = at.call(Vector2(X1 - 30.0, ftop), 0.35)
		_path("M%s %s L%s %s" % [_n(t0.x), _n(t0.y), _n(t1.x), _n(t1.y)], "none", _stroke("#A9AEB3", 3.5))
	_lane_air_detail(vp, far)
	# The signs at the mouth.
	if holt:
		var px := X0 + 70.0
		_rect(px - 2.5, ground_y - 250, 5, 248, "#2B2B2E")
		var sc := Vector2(px, ground_y - 268)
		_path("M%s %s l26 26 l-26 26 l-26 -26 z" % [_n(sc.x), _n(sc.y - 26)], "#F2C230", _stroke("#1E1E1E", 2.5))
		_path("M%s %s l26 26 l-26 26 l-26 -26 z" % [_n(sc.x), _n(sc.y - 26)], "none", _stroke("#F2C230", 1) + ' transform="translate(0 0)"')
		for kid: float in [-7.0, 7.0]:
			_circle(sc.x + kid, sc.y - 8, 3.2, "#1E1E1E")
			_path("M%s %s v12 m-5 -8 h10 m-8 18 l3 -10 l3 10" % [_n(sc.x + kid), _n(sc.y - 4)], "none", _stroke("#1E1E1E", 2.2) + ' stroke-linecap="round"')
		rng.seed = hash(k.name) + 11
		_fine_tree(Vector2(X0 - 90, ground_y - 120), 260.0, -PI * 0.3, 1.0, ["#E3A33A", "#D9A23A", "#C9562E", "#E8B54A"])
	else:
		var px := X1 - 64.0
		_rect(px - 3, ground_y - 260, 6, 258, "#8E9399")
		out.append('<ellipse cx="%s" cy="%s" rx="7" ry="2.5" fill="#000000" opacity="0.25"/>' % [_n(px + 2), _n(ground_y - 3)])
		_rect(px - 44, ground_y - 282, 88, 28, "#1E1E1E", 'rx="2"')
		_path("M%s %s h-60 m12 -9 l-12 9 l12 9" % [_n(px + 32), _n(ground_y - 268)], "none", _stroke("#FFFFFF", 5) + ' stroke-linecap="round" stroke-linejoin="round"')


# ── Rue Masson: shops downstairs, flats upstairs ────────────────────────────
# From reference/streetview/rue-masson/ (INDEX.md, "Rue Masson 2000–3400"). The commercial street a block south of Dandurand:
# `_commerce` is any of its mixed buildings (the flats' floors over a row of shopfronts, or over a stone base, or over a painted
# wall), `_bank` the stone banks at its corners. A shop's name is not drawn here: the street scene lays it on the sign band
# as a label (scenes/masson.gd), like Oh Bon!'s.


# A building of the commercial street. Upstairs: brick (or a concrete frame, `upper: "frame"`) with its windows, Juliet
# rails, balconies, a belt course and the roof line; downstairs (`ground`): "shops" (a row of `shops`), "stone" (a grey
# stone base with windows set high), or "painted" (a painted wall, a mural on it, and its `shops`).
func _commerce() -> void:
	var top := _top()
	var belt := _fb(0) - 250.0
	var floors: int = k.floors
	if k.get("upper", "brick") == "frame":
		_frame_upper(top, belt)
	else:
		if k.get("upper", "brick") == "stone":
			_ashlar(top, belt + 4.0, k.get("upper_stone", "#B5B2AA"))
		elif k.get("upper", "brick") == "stucco":
			_stucco(top, belt + 4.0, k.stucco)
		elif k.get("upper", "brick") == "rubble":
			_rubble(top, belt + 4.0)
		elif k.get("upper", "brick") == "siding":
			_siding(top, belt + 4.0, k.get("siding", "#ECEBE6"))
		else:
			_bricks(top, belt + 4.0)
		_wall_shading(top)
		match k.parapet:
			"flat":
				_flat_parapet(top)
			"corbel":
				_corbel_parapet(top)
			"scroll":
				_scroll_parapet(top)
			_:
				_cornice(top)
		if k.get("sky_mural", false):
			_sky_mural(top, belt)
		for rw: Array in k.get("round_windows", []):
			_round_window(rw[0], rw[1], top + 50.0, belt - 30.0)
		for mp: Array in k.get("metal_panels", []):
			if mp.size() > 2:  # a panel of its own colour, brick-red for the RONA's (2908…)
				_siding_panel(mp[0], mp[1], top - 40.0, belt + 4.0, mp[2])
			else:
				_siding_panel(mp[0], mp[1], top, belt + 4.0)
		if k.get("quoins", false):
			_corner_quoins(X0, top, belt)
			_corner_quoins(X1 - 44.0, top, belt)
		for f in range(1, floors):
			if k.get("ribbon_sill", false) and not k.windows.is_empty():
				var last: Array = k.windows[-1]
				var sx0: float = k.windows[0][0]
				_rect(sx0 - 40, _win_y(f) + k.get("win_dy", 0.0) - 22, last[0] + last[1] - sx0 + 80, k.get("win_h", 160.0) + 30, "#000000", 'opacity="0.1"')
			for w in k.windows:
				_window(w[0], _win_y(f) + k.get("win_dy", 0.0), w[1], k.get("win_h", 160.0))
				if k.get("juliets", false):
					_juliet(w[0], w[1], _win_y(f) + 160.0)
		# Balconies set into the wall (`loggias`: [x0, x1] bays), each floor a dark recess with its glass door and a glass rail,
		# and pale stone strips up the front (`upper_piers`: x of each), the new condos at 2e–3e (2661…, 2675…, 2687…).
		for lg: Array in k.get("loggias", []):
			for f in range(1, floors):
				var ly := _win_y(f) - 20.0
				_rect(lg[0], ly, lg[1] - lg[0], _fb(f) - ly, "#3A302C")
				_rect(lg[0], ly, lg[1] - lg[0], 14, "#000000", 'opacity="0.35"')
				_rect(lg[0] + 18, ly + 24, (lg[1] - lg[0]) * 0.45, _fb(f) - ly - 26, "url(#glass)", 'opacity="0.7"')
				_glass_rail(lg[0] + 6, lg[1] - 6, _fb(f))
		for up: float in k.get("upper_piers", []):
			_rect(up - 22, top, 44, belt - top + 4, "#C9C5BC", _stroke("#9E9A92", 1))
			_rect(up - 22, top, 8, belt - top + 4, "#FFFFFF", 'opacity="0.3"')
		for bal: Array in k.get("projecting", []):
			for f in range(1, floors):
				_balcony(bal[0], bal[1], _fb(f), [])
				_rect(bal[0] - 6, _fb(f) + 16, bal[1] - bal[0] + 12, 34, k.slab_dark)
		# A wooden rail round a roof terrace.
		if k.get("roof_rail", "") != "":
			var rail: String = k.roof_rail
			_rect(X0, top - 74, X1 - X0, 6, rail)
			_rect(X0, top - 40, X1 - X0, 4, rail)
			var post := X0
			while post <= X1:
				_rect(post, top - 74, 7, 64, rail)
				post += 34.0
			_snow(X0, X1 - X0, top - 74)
	# The belt between the shops and the flats: stone, or a dark cornice band.
	_rect(X0 - 4, belt, X1 - X0 + 8, 16, k.get("belt", "#B9B3A8"), _stroke("#8E887E", 1.5))
	_rect(X0 - 4, belt, X1 - X0 + 8, 3, "#FFFFFF", 'opacity="0.3"')
	_rect(X0, belt + 16, X1 - X0, 10, "#000000", 'opacity="0.2"')
	_snow(X0 - 4, X1 - X0 + 8, belt)
	var ground: String = k.get("ground", "shops")
	if ground == "stone":
		_ashlar(belt + 16.0, ground_y, k.get("stone", "#A9A49C"))
		for w in k.get("ground_windows", []):
			_rect(w[0] - 4, belt + 56, w[1] + 8, 96, "#5E5A54")
			_rect(w[0], belt + 60, w[1], 88, "url(#glass)")
			_glass_shine(w[0], belt + 60, w[1], 88)
			_rect(w[0] - 10, belt + 152, w[1] + 20, 8, "#C9C3B6", _stroke("#8E887E", 1))
	elif ground == "painted":
		_rect(X0, belt + 16, X1 - X0, ground_y - belt - 16, k.get("paint", "#E9E7E1"))
		var py := belt + 24.0
		while py < ground_y:
			_rect(X0, py, X1 - X0, 1.2, "#C9C5BC", 'opacity="0.7"')
			py += 13.0
		if k.get("mural_stripes", false):
			var sx := X0 - 200.0
			while sx < X1:
				_path("M%s %s L%s %s" % [_n(sx), _n(ground_y - 6), _n(sx + 160), _n(belt + 16)], "none", _stroke("#F4F2EE", 6))
				sx += 150.0
		if k.get("mural", "") == "lilies":
			_lily_mural(k.get("mural_x0", X0), X1, belt + 16.0, ground_y)
		elif k.get("mural", "") == "plants":
			_plants_mural(k.get("mural_x0", X0), X1, belt + 16.0, ground_y)
		elif k.get("mural", "") == "graffiti":
			_graffiti_mural(k.get("mural_x0", X0), X1, belt + 16.0, ground_y)
	else:
		_rect(X0, belt + 16, X1 - X0, ground_y - belt - 16, k.get("pier", "#3A3836"))
	for door_x: float in k.get("res_doors", []):
		_res_door(door_x, belt + 40.0)
	split = out.size()
	for shop: Dictionary in k.get("shops", []):
		_shopfront(shop, belt + 16.0)
	for p: float in k.get("piers", []):
		_rect(p - 10, belt + 16, 20, ground_y - belt - 16, k.get("pier_stone", "#B9B3A8"), _stroke("#8E887E", 1))
		_rect(p - 10, belt + 16, 5, ground_y - belt - 16, "#FFFFFF", 'opacity="0.25"')
	# A frame of pale stone: a pier up each end and a coping along the top (the Banque Nationale at 6e).
	var frame_stone: String = k.get("stone_frame", "")
	if frame_stone != "":
		for fx: float in [X0, X1 - 70.0]:
			_rect(fx, top - 20, 70, ground_y - top + 14, frame_stone, _stroke("#A89E8C", 1.5))
			_rect(fx, top - 20, 8, ground_y - top + 14, "#FFFFFF", 'opacity="0.25"')
			var jy := top + 40.0
			while jy < ground_y - 20.0:
				_rect(fx, jy, 70, 1.5, "#A89E8C")
				jy += 64.0
		_rect(X0, top - 30, X1 - X0, 34, frame_stone, _stroke("#A89E8C", 1.5))
		_rect(X0, top - 30, X1 - X0, 4, "#FFFFFF", 'opacity="0.3"')
		_snow(X0, X1 - X0, top - 30)
	_rect(X0, ground_y - 6, X1 - X0, 6, "#8E8A82")


# A garage bay instead of a shop (`front: "garage"`, the fire station at 1re, 2606–2614…): a pale surround, and a sectional
# door of glass panes in a white grid, the dark bay behind it (a fire truck's red when `truck`).
func _garage_bay(shop: Dictionary, top: float) -> void:
	var x0: float = shop.x0
	var x1: float = shop.x1
	var y0 := top + 30.0
	_rect(x0, y0 - 14, x1 - x0, ground_y - y0 + 14, shop.get("frame", "#D8D2C4"), _stroke("#A89E8C", 1.5))
	var gx0 := x0 + 14.0
	var gx1 := x1 - 14.0
	_rect(gx0, y0, gx1 - gx0, ground_y - y0 - 4, "#2A2E32")
	if shop.get("truck", false):
		_rect(gx0 + 20, y0 + 70, gx1 - gx0 - 40, ground_y - y0 - 90, "#9E1C1C")
		_rect(gx0 + 30, y0 + 84, (gx1 - gx0) * 0.35, 46, "#3A4650")
		_rect(gx0 + 20, ground_y - 64, gx1 - gx0 - 40, 10, "#E9E7E1")
	var cols := maxi(int((gx1 - gx0) / 70.0), 3)
	var rows := 5
	var ph := (ground_y - y0 - 4) / rows
	for r in rows:
		for c in cols:
			var px := lerpf(gx0, gx1, float(c) / cols)
			_rect(px + 3, y0 + r * ph + 3, (gx1 - gx0) / cols - 6, ph - 6, "url(#glass)", 'opacity="0.55"')
	for r in range(rows + 1):
		_rect(gx0, y0 + r * ph - 3, gx1 - gx0, 6, "#F2F0EA")
	for c in range(cols + 1):
		_rect(lerpf(gx0, gx1, float(c) / cols) - 3, y0, 6, ground_y - y0 - 4, "#F2F0EA")


# One shopfront on the street (`shop`: x0, x1 its bay; sign: the colour of its sign band, where the scene writes the name;
# frame: the colour of its frame; door: x of its glass door; awning: a colour (striped with `stripes`) or nothing; lamps: how
# many gooseneck lamps over the sign; crates: fruit and vegetables in their crates out on the sidewalk; dark: no lights on).
func _shopfront(shop: Dictionary, top: float) -> void:
	var x0: float = shop.x0
	var x1: float = shop.x1
	var frame: String = shop.get("frame", "#1E1E20")
	var front: String = shop.get("front", "alu")
	var sign_h := 56.0
	var glass_top := top + sign_h + 12.0
	var kick_h: float = shop.get("kick_h", 28.0 if front == "alu" else 70.0)
	var kick := ground_y - kick_h
	if front == "garage":
		_garage_bay(shop, top)
		return
	_rect(x0, top, x1 - x0, ground_y - top, frame)
	_rect(x0 + 4, top + 4, x1 - x0 - 8, sign_h, shop.get("sign", "#1E1E20"), _stroke("#000000", 1) + ' opacity="0.95"')
	_rect(x0 + 4, top + 4, x1 - x0 - 8, 4, "#FFFFFF", 'opacity="0.18"')
	_rect(x0 + 4, top + sign_h + 4, x1 - x0 - 8, 8, "#000000", 'opacity="0.35"')
	# A band of corrugated metal instead of a flat sign board (2846…: rust-red, ribbed).
	if shop.get("ribs", false):
		var rx := x0 + 8.0
		while rx < x1 - 8.0:
			_rect(rx, top + 6, 3, sign_h - 4, "#000000", 'opacity="0.24"')
			_rect(rx + 3, top + 6, 1.5, sign_h - 4, "#FFFFFF", 'opacity="0.16"')
			rx += 9.0
	var gx0 := x0 + 10.0
	var gx1 := x1 - 10.0
	var seed_value := int(hash(k.name) % 997) + int(x0)
	# What is behind the glass: the shop's own inside (`inside`), lit, or dark when it is closed.
	_rect(gx0, glass_top, gx1 - gx0, kick - glass_top, "#2F3A41")
	if not shop.get("dark", false):
		_shop_inside(shop.get("inside", "goods"), gx0, glass_top, gx1 - gx0, kick - glass_top, seed_value, shop.get("wall", ""))
	# Its door (`door_style`): a glass door and its push bar, two glass doors, or a wooden door with a pane.
	var dx: float = shop.get("door", (x0 + x1) / 2.0)
	var door_style: String = shop.get("door_style", "glass")
	var dw := 76.0 if door_style != "double" else 140.0
	_rect(dx - dw / 2.0, glass_top - 2, dw, ground_y - glass_top - 4, frame)
	match door_style:
		"wood":
			var wood: String = shop.get("door_color", "#6E4226")
			_rect(dx - 32, glass_top + 4, 64, ground_y - glass_top - 16, wood, _stroke("#3E2414", 1.5))
			_rect(dx - 22, glass_top + 14, 44, 90, "url(#warm)" if not shop.get("dark", false) else "#33404A", 'opacity="0.8"')
			_rect(dx - 22, glass_top + 120, 44, ground_y - glass_top - 150, "none", _stroke("#3E2414", 1.5))
			_circle(dx + 22, glass_top + 112, 3, "#C9A23A")
		"double":
			for side: float in [-1.0, 1.0]:
				var cx := dx + side * 34.0
				_rect(cx - 30, glass_top + 4, 60, ground_y - glass_top - 16, "#33404A")
				if not shop.get("dark", false):
					_rect(cx - 30, glass_top + 4, 60, ground_y - glass_top - 16, "url(#warm)", 'opacity="0.55"')
				_rect(cx - 4 * side - 2, glass_top + 90, 4, 50, "#C9C5BC")
		_:
			_rect(dx - 32, glass_top + 4, 64, ground_y - glass_top - 16, "#33404A")
			if not shop.get("dark", false):
				_rect(dx - 32, glass_top + 4, 64, ground_y - glass_top - 16, "url(#warm)", 'opacity="0.55"')
			_rect(dx - 28, glass_top + 100, 56, 5, "#C9C5BC")
	# The panes: mullions down the window (`panes` of them, or one every 150), and across the top the transom (`transom`): a bar,
	# a row of small panes, or nothing.
	var n: int = shop.get("panes", maxi(int((gx1 - gx0) / 150.0), 1))
	var mull := 6.0 if front == "alu" else 10.0
	for i in range(1, n):
		var mx := lerpf(gx0, gx1, float(i) / n)
		if absf(mx - dx) > dw / 2.0 + 12.0:
			_rect(mx - mull / 2.0, glass_top, mull, kick - glass_top, frame)
	match shop.get("transom", "bar" if front == "alu" else "panes"):
		"bar":
			_rect(gx0, glass_top + 34, gx1 - gx0, 5, frame, 'opacity="0.9"')
		"panes":
			_rect(gx0, glass_top + 44, gx1 - gx0, 7, frame)
			var tx := gx0
			while tx < gx1:
				if absf(tx - dx) > dw / 2.0:
					_rect(tx - 2, glass_top, 4, 44, frame)
				tx += 38.0
	# The bulkhead under the glass (`kick`): a plain panel, raised wooden panels, glazed tiles, brick or stone.
	match shop.get("kick", "panel" if front == "alu" else "wood"):
		"wood":
			_rect(gx0, kick, gx1 - gx0, ground_y - kick - 6, frame)
			var px := gx0 + 8.0
			while px < gx1 - 40.0:
				if absf(px + 30.0 - dx) > dw / 2.0 + 30.0:
					_rect(px, kick + 10, 60, ground_y - kick - 26, "none", _stroke("#000000", 2) + ' opacity="0.3"')
					_rect(px + 2, kick + 12, 56, 3, "#FFFFFF", 'opacity="0.15"')
				px += 72.0
		"tile":
			_rect(gx0, kick, gx1 - gx0, ground_y - kick - 6, shop.get("tile", "#2E5E5A"))
			var ty := kick
			while ty < ground_y - 8.0:
				_rect(gx0, ty, gx1 - gx0, 1.2, "#FFFFFF", 'opacity="0.35"')
				ty += 12.0
			var tx2 := gx0
			while tx2 < gx1:
				_rect(tx2, kick, 1.2, ground_y - kick - 6, "#FFFFFF", 'opacity="0.35"')
				tx2 += 12.0
		"brick":
			var brick: String = k.bricks[0]
			_rect(gx0, kick, gx1 - gx0, ground_y - kick - 6, k.mortar)
			var by := kick + 1.0
			var row := 0
			while by < ground_y - 10.0:
				var bx := gx0 - (12.0 if row % 2 == 1 else 0.0)
				while bx < gx1:
					var a2 := maxf(bx, gx0)
					var b2 := minf(bx + 22.0, gx1)
					if b2 - a2 > 2.0:
						_rect(a2, by, b2 - a2, 7, k.bricks[(row + int(bx)) % k.bricks.size()] if k.bricks.size() > 1 else brick)
					bx += 24.0
				by += 9.0
				row += 1
		"stone":
			_rect(gx0, kick, gx1 - gx0, ground_y - kick - 6, "#A9A49C", _stroke("#7E7A72", 1))
			_rect(gx0, kick, gx1 - gx0, 4, "#C9C5BC")
		_:
			_rect(gx0, kick, gx1 - gx0, ground_y - kick - 6, frame)
	_rect(gx0, kick, gx1 - gx0, 3, "#FFFFFF", 'opacity="0.15"')
	_glass_shine(gx0, glass_top, gx1 - gx0, kick - glass_top)
	var awning: String = shop.get("awning", "")
	if awning != "":
		if shop.get("stripes", false):
			_stripe_awning(x0 + 8, x1 - 8, top + sign_h + 10, awning)
		else:
			_plain_awning(x0 + 8, x1 - 8, top + sign_h + 10, awning)
	var lamps: int = shop.get("lamps", 0)
	for i in lamps:
		_gooseneck(lerpf(x0, x1, (i + 0.5) / lamps), top - 4.0)
	if shop.get("crates", false):
		_fruit_crates(x0 + 24, x1 - 24)
	_door_wreath(dx, glass_top, glass_top + 60)


# What a shop window shows of the shop, by kind: "goods" (shelves of tins, bottles and boxes: a dépanneur, a pharmacy), "cafe",
# "restaurant", "clothes", "fruit", "bank", "salon", "office" (blinds down), "florist", "bakery", "hardware", "pharmacy". Its own
# random numbers, so the rest of the facade doesn't move.
func _shop_inside(kind: String, x: float, y: float, w: float, h: float, seed_value: int, wall_color := "") -> void:
	if kind == "goods":
		_shop_glass_glow(x, y, w, h, seed_value)
		_shop_glass_goods(x + 4, y + 30, w - 8, h - 40, seed_value, 2)
		return
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 7 + 3
	_clips += 1
	out.append('<clipPath id="in%d"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath><g clip-path="url(#in%d)">' % [_clips, _n(x), _n(y), _n(w), _n(h), _clips])
	var walls := {"cafe": "#C99A6A", "restaurant": "#B5664A", "clothes": "#ECE8E0", "fruit": "#E8E0C8", "bank": "#E4E2DC",
		"salon": "#F0EEE8", "office": "#D8D4CC", "florist": "#DDE6D2", "bakery": "#E8D2A8", "hardware": "#D2C8B4", "pharmacy": "#F4F4F2"}
	walls.merge({"deli": "#E2D2B4", "books": "#C9A27A", "optician": "#E4E0D8", "jewellery": "#3A2E2A", "phones": "#ECEAE6"})
	var wall: String = "#" + Color(wall_color if wall_color != "" else walls.get(kind, "#D8CDBA")).darkened(0.12).to_html(false)
	var floor_y := y + h - 14.0
	# Depth, the same for every shop: the back wall, its warm light, the dark of the ceiling at the top, a row of lights.
	_rect(x, y, w, h, wall)
	_rect(x, y, w, h, "url(#warm)", 'opacity="0.25"')
	_rect(x, y, w, 26, "#1E1A18", 'opacity="0.55"')
	var lamp_x := x + 30.0
	while lamp_x < x + w - 10.0:
		_rect(lamp_x - 14, y + 20, 28, 4, "#FFF2D0")
		_circle(lamp_x, y + 30, 16, "url(#glow)")
		lamp_x += 90.0
	_rect(x, floor_y, w, 14, "#" + Color(wall).darkened(0.35).to_html(false))
	match kind:
		"cafe", "restaurant":
			# Pendant lamps, a counter or banquette at the back, little tables and chairs by the glass.
			var lx := x + 40.0
			while lx < x + w:
				_path("M%s %s V%s" % [_n(lx), _n(y), _n(y + 30)], "none", _stroke("#2A2A2A", 1.5))
				_path("M%s %s l12 0 l-4 -10 l-4 0 z" % [_n(lx - 6), _n(y + 40)], "#2A2A2A")
				_circle(lx, y + 42, 10, "#FFE2A0", 'opacity="0.8"')
				lx += r.randf_range(70.0, 110.0)
			_rect(x, floor_y - 60, w, 60, "#" + Color(wall).darkened(0.25).to_html(false))
			if kind == "cafe":
				_rect(x + w * 0.6, floor_y - 74, 50, 30, "#C9C5BC", _stroke("#5E5A54", 1.5))
				_rect(x + 12, y + 50, 60, 44, "#2A2E2C", _stroke("#8A6A4A", 3))
				for l in 4:
					_rect(x + 18, y + 58 + l * 9, r.randf_range(24.0, 46.0), 2, "#E8E4DA")
			var tx := x + 30.0
			while tx < x + w - 30.0:
				var cloth := "#F2F0EA" if kind == "restaurant" else "#3A2A20"
				_rect(tx - 18, floor_y - 34, 36, 5, cloth)
				_rect(tx - 2, floor_y - 30, 4, 30, "#2A2A2A")
				for cs: float in [-1.0, 1.0]:
					_rect(tx + cs * 26 - 3, floor_y - 44, 4, 44, "#3A2A20")
					_rect(tx + cs * 26 - 8, floor_y - 22, 14, 4, "#3A2A20")
				tx += r.randf_range(90.0, 130.0)
		"clothes":
			_rect(x + 10, y + 46, w - 20, 3, "#8E8A82")
			var cx := x + 20.0
			var colors := ["#C8202A", "#1F3E8E", "#F2C230", "#3A3A3C", "#E85FA0", "#4FA34A", "#E8E4DA", "#8E5FC4"]
			while cx < x + w - 20.0:
				var c: String = colors[r.randi_range(0, colors.size() - 1)]
				_path("M%s %s l8 -4 l8 4 l4 6 l-4 2 v%s h-16 v-%s l-4 -2 z" % [_n(cx), _n(y + 54), _n(r.randf_range(50.0, 80.0)), _n(0)], c)
				cx += r.randf_range(18.0, 26.0)
			# A mannequin in the window.
			var mx := x + w * 0.8
			_circle(mx, floor_y - 110, 9, "#E8E4DA")
			_path("M%s %s l14 0 l4 50 l-22 0 z" % [_n(mx - 7), _n(floor_y - 100)], colors[r.randi_range(0, 3)])
			_rect(mx - 1, floor_y - 50, 2, 50, "#8E8A82")
		"fruit":
			for row in 3:
				var ry := floor_y - 20.0 - row * 34.0
				_rect(x, ry, w, 6, "#8A6A4A")
				var fx := x + 8.0
				while fx < x + w - 8.0:
					var fc: String = ["#E04A3A", "#F2C230", "#4FA34A", "#E8812E", "#8E2A4A"][r.randi_range(0, 4)]
					for f in 4:
						_circle(fx + f * 9.0, ry - 6, 5.5, fc)
					fx += 44.0
		"bank":
			_rect(x, floor_y - 50, w, 50, "#C9C5BC")
			_rect(x, floor_y - 54, w, 6, "#8E8A82")
			var ax := x + 30.0
			while ax < x + w - 40.0:
				_rect(ax, floor_y - 120, 40, 70, "#3A3E44", _stroke("#1E1E20", 1.5))
				_rect(ax + 6, floor_y - 112, 28, 20, "#5EA8E8")
				ax += 160.0
			_shrub(x + w - 30.0, 22.0, "#3E7A3A")
		"salon":
			var sx := x + 30.0
			while sx < x + w - 30.0:
				_rect(sx - 22, y + 30, 44, 70, "#DDE6EC", _stroke("#B9B5AC", 2))
				_rect(sx - 16, floor_y - 48, 32, 30, "#1E1E20")
				_rect(sx - 3, floor_y - 18, 6, 18, "#8E8A82")
				sx += 110.0
		"office":
			_rect(x, y + 26, w, h - 26, "#C9C2B4")
			var by := y + 4.0
			while by < y + h * 0.8:
				_rect(x, by, w, 3, "#B9B5AC")
				by += 8.0
		"florist":
			var px := x + 14.0
			while px < x + w - 10.0:
				var pr := r.randf_range(16.0, 30.0)
				_rect(px - 8, floor_y - 18, 16, 18, "#8A5A3A")
				_shrub(px, pr, ["#3E7A3A", "#4E8A44", "#2E6A3A"][r.randi_range(0, 2)])
				for b in 3:
					_bloom(px + r.randf_range(-pr, pr) * 0.6, floor_y - 18 - r.randf_range(4.0, pr * 1.4), 5.0, ["#E85FA0", "#F2C230", "#E8E4DA", "#C8202A"][r.randi_range(0, 3)])
				px += r.randf_range(34.0, 50.0)
		"bakery":
			for row in 3:
				var ry := y + 40.0 + row * 40.0
				_rect(x + 10, ry, w - 20, 4, "#8A6A4A")
				var bx := x + 18.0
				while bx < x + w - 24.0:
					out.append('<ellipse cx="%s" cy="%s" rx="13" ry="6" fill="#C98A3A" stroke="#8A5A2A" stroke-width="1"/>' % [_n(bx), _n(ry - 6)])
					bx += 30.0
			_rect(x, floor_y - 40, w, 40, "#E8E4DA", _stroke("#B9B5AC", 1.5))
		"hardware":
			_rect(x, y + 20, w, h * 0.5, "#B9A882")
			var hx := x + 12.0
			while hx < x + w - 12.0:
				_rect(hx, y + 40 + r.randf_range(0.0, 30.0), 6, r.randf_range(20.0, 40.0), ["#C8202A", "#F2C230", "#3A3A3C", "#1F4E9A"][r.randi_range(0, 3)])
				hx += 16.0
			var cx2 := x + 10.0
			while cx2 < x + w - 20.0:
				_rect(cx2, floor_y - 26, 18, 24, ["#E8E4DA", "#3D8BD9", "#4FA34A", "#E8812E"][r.randi_range(0, 3)], _stroke("#5E5A54", 1))
				cx2 += 22.0
		"pharmacy", "phones":
			_shop_glass_goods(x + 4, y + 30, w - 8, h - 40, seed_value, 3)
		"deli":
			# A sandwich counter: menu boards high up, the glass case of breads and fillings, a cutting board, a coffee machine.
			var mx := x + 20.0
			while mx < x + w - 70.0:
				_rect(mx, y + 34, 70, 44, "#1E1E20", _stroke("#8A6A4A", 2))
				for l in 4:
					_rect(mx + 8, y + 42 + l * 9, r.randf_range(30.0, 54.0), 2, "#F2F0EA")
				mx += 90.0
			_rect(x, floor_y - 56, w, 56, "#8A5A3A")
			_rect(x + 10, floor_y - 92, w - 20, 38, "#CFE6EE", 'opacity="0.55"')
			var bx := x + 24.0
			while bx < x + w - 24.0:
				out.append('<ellipse cx="%s" cy="%s" rx="16" ry="6" fill="#D49A50" stroke="#8A5A2A" stroke-width="1"/>' % [_n(bx), _n(floor_y - 62)])
				_rect(bx - 12, floor_y - 80, 24, 8, ["#C8202A", "#4FA34A", "#F2E6C8"][r.randi_range(0, 2)])
				bx += 40.0
			_rect(x + w - 60, floor_y - 120, 36, 30, "#3A3A3C", _stroke("#1E1E20", 1.5))
		"books":
			for row in 4:
				var ry := y + 40.0 + row * 34.0
				_rect(x, ry + 28, w, 4, "#5A3A24")
				var bk := x + 4.0
				while bk < x + w - 6.0:
					var bw := r.randf_range(5.0, 10.0)
					var bh := r.randf_range(18.0, 27.0)
					_rect(bk, ry + 28 - bh, bw, bh, ["#C8202A", "#1F4E9A", "#F2C230", "#3E7A4E", "#E8E4DA", "#5E3A7E"][r.randi_range(0, 5)])
					bk += bw + 1.0
			_rect(x + w * 0.3, floor_y - 40, w * 0.4, 40, "#8A5A3A")
		"optician":
			# Frames on lit shelves along the wall, a mirror, a little desk.
			for row in 3:
				var ry := y + 44.0 + row * 36.0
				_rect(x + 8, ry + 14, w - 16, 3, "#B9B5AC")
				var fx := x + 18.0
				while fx < x + w - 24.0:
					var fc: String = ["#1E1E20", "#8A3A2A", "#2E4E7E", "#C9A040"][r.randi_range(0, 3)]
					for side in 2:
						out.append('<ellipse cx="%s" cy="%s" rx="6" ry="4.5" fill="none" stroke="%s" stroke-width="2"/>' % [_n(fx + side * 14.0), _n(ry + 8), fc])
					_rect(fx + 5, ry + 7, 4, 1.5, fc)
					fx += 36.0
			_rect(x + w - 50, floor_y - 110, 34, 70, "#DDE6EC", _stroke("#B9B5AC", 2))
			_rect(x + 20, floor_y - 34, 70, 34, "#F2F0EA", _stroke("#B9B5AC", 1.5))
		"jewellery":
			# Lit glass cases on a dark wall, rings and chains sparkling.
			for c in 2:
				var cy := y + 50.0 + c * 50.0
				_rect(x + 10, cy, w - 20, 34, "#F2EEE6", 'opacity="0.85"')
				var jx := x + 20.0
				while jx < x + w - 20.0:
					_circle(jx, cy + 20, 4, "none", _stroke("#E8C24A", 2))
					_circle(jx + 2, cy + 18, 1.2, "#FFFFFF")
					jx += 22.0
			_rect(x, floor_y - 40, w, 40, "#5A4A3A")
	out.append('</g>')


# `_shop_glass_shine` clipped to its pane, for the narrow shop windows of Masson (the shared one overflows them; it is left as
# it is for the shops that already use it).
var _clips := 0
func _glass_shine(x: float, y: float, w: float, h: float) -> void:
	_clips += 1
	out.append('<clipPath id="pane%d"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath><g clip-path="url(#pane%d)">' % [_clips, _n(x), _n(y), _n(w), _n(h), _clips])
	_shop_glass_shine(x, y, w, h)
	out.append('</g>')


# A canvas awning in one colour, its scalloped valance a shade darker.
func _plain_awning(x0: float, x1: float, y: float, colour: String) -> void:
	var dark := "#" + Color(colour).darkened(0.3).to_html(false)
	var drop := 40.0
	var reach := 16.0
	_rect(x0 - 4, y + drop + 6, x1 - x0 + 8, 26, "url(#drop)")
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0), _n(y), _n(x1), _n(x1 + reach), _n(y + drop), _n(x0 - reach)], colour, _stroke(dark, 1.5))
	_path("M%s %s H%s L%s %s H%s Z" % [_n(x0 - reach * 0.5), _n(y + drop * 0.5), _n(x1 + reach * 0.5), _n(x1 + reach), _n(y + drop), _n(x0 - reach)], "#000000", 'opacity="0.12"')
	var x := x0 - reach
	while x < x1 + reach - 2.0:
		_path("M%s %s h18 v7 q-9 8 -18 0 z" % [_n(x), _n(y + drop)], dark)
		x += 18.0
	_snow(x0, x1 - x0, y)


# A gooseneck lamp over a shop sign: a black arm curling out from the wall, a dish shade, its light on the sign.
func _gooseneck(x: float, y: float) -> void:
	var c: String = k.get("lamp_color", "#1A1A1A")
	_circle(x + 18, y + 40, 22, "url(#glow)")
	_path("M%s %s q0 -22 14 -22 q14 0 14 14" % [_n(x), _n(y + 8)], "none", _stroke(c, 3))
	_path("M%s %s l14 0 l-4 9 l-6 0 z" % [_n(x + 21), _n(y)], c, _stroke("#8E8A82", 0.8))
	_rect(x - 3, y + 6, 6, 8, c)


# Crates of fruit and vegetables out on the sidewalk in front of a greengrocer's, on a low stand.
func _fruit_crates(x0: float, x1: float) -> void:
	var y := ground_y - 34.0
	_rect(x0, y + 18, x1 - x0, 16, "#6E5A44")
	var x := x0
	var i := 0
	var produce := ["#E8812E", "#D9342B", "#F2C230", "#7FA34A", "#E8542F", "#9C3B6E"]
	while x < x1 - 70.0:
		_rect(x, y - 6, 66, 26, "#C9A06A", _stroke("#8A6A3E", 1.5))
		for s in 3:
			_rect(x, y + s * 8.0 - 2.0, 66, 1.5, "#8A6A3E", 'opacity="0.6"')
		var c: String = produce[(i + int(x0)) % produce.size()]
		for j in 6:
			_circle(x + 8 + j * 10.0, y - 8.0 - (j % 2) * 4.0, 7, c, _stroke("#" + Color(c).darkened(0.3).to_html(false), 1))
			_circle(x + 6 + j * 10.0, y - 10.0 - (j % 2) * 4.0, 2.5, "#FFFFFF", 'opacity="0.35"')
		x += 74.0
		i += 1


# A Juliet rail across the bottom of an upper window: black bars between two little posts, a scroll in the middle.
func _juliet(x: float, w: float, y: float) -> void:
	var top := y - 46.0
	_rect(x - 8, top, w + 16, 4, k.metal)
	_rect(x - 8, y - 6, w + 16, 4, k.metal)
	var bx := x - 2.0
	while bx < x + w + 4.0:
		_rect(bx, top + 4, 2, 36, k.metal)
		bx += 9.0
	_scroll((x * 2.0 + w) / 2.0, top + 12.0)
	_rect(x - 12, y - 2, w + 24, 8, k.lintel, _stroke(k.lintel_dark, 1))
	_snow(x - 8, w + 16, top)


# The narrow door to the flats upstairs, between the shops: a dark frame, a glass door, its little lamp and number.
func _res_door(x: float, top: float) -> void:
	_rect(x - 36, top - 6, 72, ground_y - top + 6, "#C9C3B6", _stroke("#8E887E", 1.5))
	_rect(x - 28, top + 2, 56, ground_y - top - 8, "#2B2B2E")
	_rect(x - 22, top + 10, 44, (ground_y - top) * 0.55, "url(#glass)")
	_rect(x - 22, top + 10, 44, 6, "url(#drop)")
	_circle(x + 16, top + (ground_y - top) * 0.62, 2.5, "#C9A227")
	_wall_lantern(x + 46, top + 20)


# Ashlar: big blocks of grey stone in courses, each block a slightly different grey, its joints shaded under the light.
func _ashlar(y0: float, y1: float, stone: String) -> void:
	_rect(X0, y0, X1 - X0, y1 - y0, "#" + Color(stone).darkened(0.25).to_html(false))
	var y := y0
	var row := 0
	while y < y1:
		var h := minf(46.0, y1 - y)
		var x := X0 - (60.0 if row % 2 == 1 else 0.0)
		while x < X1:
			var bx := maxf(x, X0)
			var bw := minf(x + 118.0, X1) - bx
			if bw > 2.0:
				var tone := Color(stone).lightened(rng.randf_range(-0.06, 0.08))
				_rect(bx + 1.5, y + 1.5, bw - 3.0, h - 3.0, "#" + tone.to_html(false))
				_rect(bx + 1.5, y + 1.5, bw - 3.0, 3, "#FFFFFF", 'opacity="0.18"')
			x += 120.0
		y += 48.0
		row += 1


# A modern concrete frame (Masson's four-storey blocks): piers and floor slabs in pale concrete,
# each bay filled with windows in white frames, a Juliet rail across the lower half.
func _frame_upper(top: float, belt: float) -> void:
	var concrete: String = k.get("concrete", "#D9D0BE")
	var dark := "#" + Color(concrete).darkened(0.25).to_html(false)
	_rect(X0, top, X1 - X0, belt - top + 4, "#4E5A62")
	var piers: Array = k.get("frame_piers", [X0, X1 - 30.0])
	var floors: int = k.floors
	for f in range(1, floors):
		var fy := _fb(f) - 248.0
		for i in piers.size() - 1:
			var a: float = piers[i] + 30.0
			var b: float = piers[i + 1]
			_rect(a, fy, b - a, 230, "url(#glass)")
			_path("M%s %s l%s 0 l%s %s l%s 0 z" % [_n(a + (b - a) * 0.5), _n(fy), _n((b - a) * 0.12), _n(-(b - a) * 0.18), _n(230), _n(-(b - a) * 0.12)], "#FFFFFF", 'opacity="0.18"')
			var panes := maxi(int((b - a) / 90.0), 2)
			for p in range(0, panes + 1):
				_rect(a + (b - a) * p / float(panes) - 3.0, fy, 6, 230, "#F2F0EA")
			_rect(a, fy + 120, b - a, 6, "#F2F0EA")
			if season == "autumn" and not night:
				if not windows.has(k.name):
					windows[k.name] = []
				windows[k.name].append({"pane": [a + 4, fy + 4, b - a - 8, 222], "bar_y": fy + 120, "trim": "#F2F0EA", "lit": false, "flower_box": false})
			if k.get("juliets", false):
				_juliet(a + 10, b - a - 20, fy + 228)
		_rect(X0, _fb(f) - 18, X1 - X0, 26, concrete, _stroke(dark, 1.5))
		_rect(X0, _fb(f) - 18, X1 - X0, 4, "#FFFFFF", 'opacity="0.3"')
		_snow(X0, X1 - X0, _fb(f) - 18)
	for p: float in piers:
		_rect(p, top, 30, belt - top, concrete, _stroke(dark, 1.5))
		_rect(p, top, 6, belt - top, "#FFFFFF", 'opacity="0.25"')
	_rect(X0 - 4, top - 14, X1 - X0 + 8, 18, concrete, _stroke(dark, 1.5))
	_snow(X0 - 4, X1 - X0 + 8, top - 14)


# The lilies painted big across a white wall (Masson's 2970–2990, the building of the Tim Hortons at 7e): long
# stems, white calla flowers outlined in blue, a red and a white diagonal band crossing behind them.
func _lily_mural(x0: float, x1: float, y0: float, y1: float) -> void:
	for band: Array in [[0.15, "#FFFFFF"], [0.35, "#FFFFFF"], [0.55, "#C8343A"]]:
		var bx: float = lerpf(x0, x1, band[0])
		_path("M%s %s L%s %s" % [_n(bx), _n(y1), _n(bx + (y1 - y0) * 0.75), _n(y0)], "none", _stroke(band[1], 12) + ' opacity="0.85"')
	for f: Array in [[0.14, 0.2, 2.1], [0.36, 0.42, 1.6], [0.66, 0.16, 2.3], [0.88, 0.4, 1.8]]:
		var cx: float = lerpf(x0, x1, f[0])
		var cy: float = lerpf(y0, y1, f[1])
		var s: float = f[2]
		_path("M%s %s Q%s %s %s %s" % [_n(cx), _n(cy + 40 * s), _n(cx + 10 * s), _n(cy + 120 * s), _n(cx - 6 * s), _n(y1)], "none", _stroke("#5E8A3A", 5 * s))
		_path("M%s %s c%s %s %s %s %s %s c%s %s %s %s %s %s c%s %s %s %s %s %s z" % [_n(cx + 6 * s), _n(cy + 40 * s),
			_n(-30 * s), _n(-10 * s), _n(-44 * s), _n(-46 * s), _n(-20 * s), _n(-70 * s),
			_n(10 * s), _n(30 * s), _n(34 * s), _n(40 * s), _n(40 * s), _n(70 * s),
			_n(-6 * s), _n(4 * s), _n(-14 * s), _n(4 * s), _n(-20 * s), _n(0)], "#FBFAF6", _stroke("#3E5E9A", 2.6))
		_path("M%s %s c%s %s %s %s %s %s" % [_n(cx + 4 * s), _n(cy + 34 * s), _n(4 * s), _n(-16 * s), _n(8 * s), _n(-30 * s), _n(4 * s), _n(-44 * s)], "none", _stroke("#F2C230", 3 * s))
		_path("M%s %s c-14 10 -30 30 -24 56" % [_n(cx - 4 * s), _n(cy + 60 * s)], "none", _stroke("#5E8A3A", 6 * s) + ' stroke-linecap="round"')


# A bank of stone at a corner (Masson's 2933–2939 at 7e, a physiotherapy clinic now): two floors of big grey stone blocks, fluted
# pilasters up the front, a deep cornice and its green copper flashing, wide windows in bronze frames, the door and its lamp
# at the cut-off corner (`corner_side`: -1 left, 1 right).
func _bank() -> void:
	var top := _top()
	var stone: String = k.get("stone", "#BDB8AE")
	_ashlar(top, ground_y, stone)
	_wall_shading(top)
	# The cornice and its green copper top.
	_rect(X0 - 8, top - 26, X1 - X0 + 16, 30, stone, _stroke("#8E887E", 1.5))
	_rect(X0 - 8, top - 32, X1 - X0 + 16, 8, "#6E9A86", _stroke("#4E7A66", 1))
	_rect(X0 - 4, top + 4, X1 - X0 + 8, 10, "#000000", 'opacity="0.2"')
	var x := X0 + 10.0
	while x < X1 - 10.0:
		_rect(x, top - 4, 10, 8, "#" + Color(stone).darkened(0.15).to_html(false))
		x += 22.0
	_snow(X0 - 8, X1 - X0 + 16, top - 32)
	# Pilasters, fluted, between the bays.
	# The wall itself may be brick between the stone (`bank_brick`, 2703…), the pilasters in their own stone (`pilaster`).
	if k.get("bank_brick", false):
		_bricks(top, ground_y - 6.0)
	var pil: String = k.get("pilaster", "#" + Color(stone).lightened(0.06).to_html(false))
	for p: float in k.get("pilasters", []):
		_rect(p - 18, top, 36, ground_y - top - 10, pil, _stroke("#8E887E", 1.5))
		for fl in 4:
			_rect(p - 12 + fl * 7.0, top + 30, 2, ground_y - top - 70, "#" + Color(stone).darkened(0.2).to_html(false))
		_rect(p - 24, top, 48, 16, stone, _stroke("#8E887E", 1))
	# Upstairs, small paired windows; downstairs, wide ones, each in a bronze frame with a transom.
	for w in k.windows:
		for i in 2:
			var wx: float = w[0] + i * (w[1] / 2.0 + 6.0)
			_rect(wx - 3, _win_y(1) + 30 - 3, w[1] / 2.0 - 6 + 6, 118, "#5E4A36")
			_rect(wx, _win_y(1) + 30, w[1] / 2.0 - 6, 112, "url(#glass)")
			_rect(wx, _win_y(1) + 30 + 40, w[1] / 2.0 - 6, 4, "#5E4A36")
		_rect(w[0] - 4, _win_y(0) + 10, w[1] + 8, 180, "#4E3E2E")
		_rect(w[0], _win_y(0) + 14, w[1], 172, "url(#glass)")
		_rect(w[0], _win_y(0) + 56, w[1], 5, "#4E3E2E")
		_rect(w[0] + w[1] / 2.0 - 2, _win_y(0) + 61, 4, 125, "#4E3E2E")
		_glass_shine(w[0], _win_y(0) + 14, w[1], 172)
		if season == "autumn" and not night:
			if not windows.has(k.name):
				windows[k.name] = []
			windows[k.name].append({"pane": [w[0], _win_y(0) + 14, w[1], 172], "bar_y": _win_y(0) + 56, "trim": "#4E3E2E", "lit": false, "flower_box": false})
		_rect(w[0] - 12, _win_y(0) + 190, w[1] + 24, 10, "#" + Color(stone).darkened(0.1).to_html(false), _stroke("#8E887E", 1))
	split = out.size()
	# The door at the corner, under its pediment, a lamp on its post beside it.
	var side: float = k.get("corner_side", 1.0)
	var dx: float = X1 - 70.0 if side > 0.0 else X0 + 70.0
	_rect(dx - 46, _fb(0) - 230, 92, ground_y - _fb(0) + 230, "#" + Color(stone).darkened(0.1).to_html(false), _stroke("#8E887E", 1.5))
	_rect(dx - 36, _fb(0) - 216, 72, ground_y - _fb(0) + 210, "#3A3028")
	_rect(dx - 30, _fb(0) - 210, 60, 110, "url(#glass)")
	_path("M%s %s L%s %s L%s %s Z" % [_n(dx - 56), _n(_fb(0) - 230), _n(dx), _n(_fb(0) - 270), _n(dx + 56), _n(_fb(0) - 230)], stone, _stroke("#8E887E", 1.5))
	var lx := dx - side * 92.0
	_rect(lx - 3, ground_y - 250, 6, 250, "#1A1A1A")
	_rect(lx - 9, ground_y - 282, 18, 32, "#ECE7DA", _stroke("#1A1A1A", 2))
	_path("M%s %s l12 -10 l12 10 z" % [_n(lx - 12), _n(ground_y - 282)], "#1A1A1A")
	_circle(lx, ground_y - 266, 26, "url(#glow)")


# ── Rue Masson, 7e to 8e: stucco, scrolled parapets, a low painted wall, a passage of murals, a parking lot ──

# A smooth stucco wall, faintly mottled, from y0 to y1.
func _stucco(y0: float, y1: float, color: String) -> void:
	_rect(X0, y0, X1 - X0, y1 - y0, color)
	for i in int((X1 - X0) * (y1 - y0) / 9000.0):
		var tone := Color(color).lightened(rng.randf_range(-0.06, 0.06))
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#%s" opacity="0.5"/>' % [_n(rng.randf_range(X0, X1)), _n(rng.randf_range(y0, y1)), _n(rng.randf_range(20.0, 60.0)), _n(rng.randf_range(10.0, 30.0)), tone.to_html(false)])


# Long-and-short stone quoins up a corner, x the outer edge's left.
func _corner_quoins(x: float, y0: float, y1: float) -> void:
	var y := y0 + 4.0
	var i := 0
	while y < y1 - 30.0:
		var w := 44.0 if i % 2 == 0 else 30.0
		var qx := x if x < (X0 + X1) / 2.0 else x + 44.0 - w
		_rect(qx, y, w, 34, k.lintel, _stroke(k.lintel_dark, 1))
		_rect(qx, y, w, 3, "#FFFFFF", 'opacity="0.3"')
		y += 38.0
		i += 1


# A parapet raised in the middle in a curved crest ending in scrolls, under a stone coping (3012…, 3028…).
func _scroll_parapet(top: float) -> void:
	var brick: String = k.bricks[0]
	var cx := (X0 + X1) / 2.0
	var hw := (X1 - X0) * 0.22
	_rect(X0 - 4, top - 14, X1 - X0 + 8, 14, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(X0 - 4, top - 14, X1 - X0 + 8, 3, "#FFFFFF", 'opacity="0.35"')
	_path("M%s %s Q%s %s %s %s Q%s %s %s %s Z" % [_n(cx - hw), _n(top - 14), _n(cx - hw * 0.5), _n(top - 96), _n(cx), _n(top - 98), _n(cx + hw * 0.5), _n(top - 96), _n(cx + hw), _n(top - 14)], brick, _stroke(k.lintel_dark, 1))
	_path("M%s %s Q%s %s %s %s Q%s %s %s %s" % [_n(cx - hw - 8), _n(top - 12), _n(cx - hw * 0.5), _n(top - 106), _n(cx), _n(top - 108), _n(cx + hw * 0.5), _n(top - 106), _n(cx + hw + 8), _n(top - 12)], "none", _stroke(k.lintel, 10) + ' stroke-linecap="round"')
	for side: float in [-1.0, 1.0]:
		var sx := cx + side * (hw + 6.0)
		_circle(sx, top - 24, 13, k.lintel, _stroke(k.lintel_dark, 1.2))
		_circle(sx + side * 3.0, top - 24, 5, "#000000", 'opacity="0.15"')
	_rect(cx - 50, top - 70, 100, 34, "#" + Color(brick).lightened(0.1).to_html(false), _stroke(k.lintel_dark, 1))
	_snow(X0 - 4, X1 - X0 + 8, top - 14)


# A wall painted from end to end with big bright shapes outlined in black, no lettering (2700…, 2714…): the graffiti murals.
func _graffiti_mural(x0: float, x1: float, y0: float, y1: float) -> void:
	var colors := ["#E85FA0", "#3D8BD9", "#F2C230", "#E8812E", "#4FA34A", "#5EC8C0", "#E04A3A", "#8E5FC4"]
	_clips += 1
	out.append('<clipPath id="gra%d"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath><g clip-path="url(#gra%d)">' % [_clips, _n(x0), _n(y0), _n(x1 - x0), _n(y1 - y0), _clips])
	# Slanted fields of colour right across, then big rounded shapes and swooshes over them, black outlines, white highlights.
	var fx := x0 - 40.0
	var f := 0
	while fx < x1:
		var fw := rng.randf_range(110.0, 190.0)
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(fx + 40), _n(y0), _n(fx + fw + 70), _n(y0), _n(fx + fw), _n(y1), _n(fx - 30), _n(y1)], colors[(f * 3 + 1) % colors.size()])
		fx += fw
		f += 1
	for i in int((x1 - x0) / 120.0):
		var c: String = colors[(i * 5) % colors.size()]
		var x := rng.randf_range(x0 + 30.0, x1 - 30.0)
		var y := rng.randf_range(y0 + 50.0, y1 - 40.0)
		var r := rng.randf_range(34.0, 64.0)
		if i % 3 == 0:
			_path("M%s %s q%s %s %s %s q%s %s %s %s" % [_n(x - r * 1.4), _n(y + r * 0.3), _n(r * 0.7), _n(-r * 1.2), _n(r * 1.6), _n(-r * 0.4), _n(r * 0.8), _n(r * 0.6), _n(r * 1.4), _n(-r * 0.2)], "none", _stroke("#1A1A1A", 18) + ' stroke-linecap="round"')
			_path("M%s %s q%s %s %s %s q%s %s %s %s" % [_n(x - r * 1.4), _n(y + r * 0.3), _n(r * 0.7), _n(-r * 1.2), _n(r * 1.6), _n(-r * 0.4), _n(r * 0.8), _n(r * 0.6), _n(r * 1.4), _n(-r * 0.2)], "none", _stroke(c, 11) + ' stroke-linecap="round"')
		else:
			_path("M%s %s q%s %s %s %s q%s %s %s %s q%s %s %s %s z" % [_n(x - r), _n(y), _n(r * 0.2), _n(-r), _n(r), _n(-r * 0.6), _n(r), _n(r * 0.3), _n(r * 0.7), _n(r), _n(-r * 0.8), _n(r * 0.5), _n(-r * 1.7), _n(-r * 0.4)], c, _stroke("#1A1A1A", 5))
			_path("M%s %s q%s %s %s %s" % [_n(x - r * 0.6), _n(y - r * 0.1), _n(r * 0.3), _n(-r * 0.4), _n(r * 0.8), _n(-r * 0.2)], "none", _stroke("#FFFFFF", 5) + ' opacity="0.75" stroke-linecap="round"')
		_circle(x + r * 0.9, y - r * 0.8, 4, "#FFFFFF", 'opacity="0.85"')
	out.append('</g>')


# A mural of big leaves and flowers painted across a wall (3071…, 2737…): broad green leaves of several greens with their
# veins, round blossoms, a few doves, over the wall's own paint.
func _plants_mural(x0: float, x1: float, y0: float, y1: float) -> void:
	_clips += 1
	out.append('<clipPath id="pl%d"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath><g clip-path="url(#pl%d)">' % [_clips, _n(x0), _n(y0), _n(x1 - x0), _n(y1 - y0), _clips])
	var greens := ["#2E7A4E", "#4FA34A", "#1E5E3E", "#6EB85A", "#3E8A6E"]
	var x := x0 + 20.0
	var i := 0
	while x < x1:
		var base := Vector2(x, y1 + 10.0)
		for l in 3:
			var ang := -PI / 2.0 + (l - 1) * 0.55 + rng.randf_range(-0.2, 0.2)
			var length := (y1 - y0) * rng.randf_range(0.55, 0.95)
			var tip := base + Vector2(cos(ang), sin(ang)) * length
			var side := Vector2(-sin(ang), cos(ang)) * length * 0.22
			var mid := (base + tip) / 2.0
			_path("M%s %s Q%s %s %s %s Q%s %s %s %s Z" % [_n(base.x), _n(base.y), _n(mid.x + side.x), _n(mid.y + side.y), _n(tip.x), _n(tip.y), _n(mid.x - side.x), _n(mid.y - side.y), _n(base.x), _n(base.y)], greens[(i + l) % greens.size()], _stroke("#143A28", 2))
			_path("M%s %s L%s %s" % [_n(base.x), _n(base.y), _n(tip.x), _n(tip.y)], "none", _stroke("#B8E0A0", 2) + ' opacity="0.7"')
		if i % 2 == 0:
			var fy := y0 + rng.randf_range(30.0, (y1 - y0) * 0.5)
			var fc: String = ["#E85FA0", "#F2C230", "#E8812E", "#F2F0EA"][i % 4]
			for pet in 6:
				var a := TAU * pet / 6.0
				_circle(x + 40 + cos(a) * 14.0, fy + sin(a) * 14.0, 10, fc, _stroke("#5A2A3A", 1.2))
			_circle(x + 40, fy, 8, "#F2C230")
		x += rng.randf_range(90.0, 130.0)
		i += 1
	out.append('</g>')


# A mural over a whole upper floor: a sky with clouds over rolling hills (2737…).
func _sky_mural(top: float, belt: float) -> void:
	var hill := belt - 60.0
	for c in 5:
		var cx := lerpf(X0 + 80.0, X1 - 80.0, c / 4.0) + rng.randf_range(-30.0, 30.0)
		var cy := top + rng.randf_range(40.0, 110.0)
		for p in 4:
			_circle(cx + (p - 1.5) * 26.0, cy + absf(p - 1.5) * 6.0, 26.0 - absf(p - 1.5) * 4.0, "#F4F6F8", 'opacity="0.9"')
	_path("M%s %s Q%s %s %s %s T%s %s T%s %s V%s H%s Z" % [_n(X0), _n(hill), _n(lerpf(X0, X1, 0.2)), _n(hill - 90), _n(lerpf(X0, X1, 0.4)), _n(hill - 20), _n(lerpf(X0, X1, 0.7)), _n(hill - 40), _n(X1), _n(hill - 70), _n(belt + 4), _n(X0)], "#6EA86A")
	_path("M%s %s Q%s %s %s %s T%s %s V%s H%s Z" % [_n(X0), _n(hill + 30), _n(lerpf(X0, X1, 0.3)), _n(hill - 20), _n(lerpf(X0, X1, 0.55)), _n(hill + 20), _n(X1), _n(hill + 10), _n(belt + 4), _n(X0)], "#4E8A4E")


# Rough rubble stone laid in a wall (3131…): irregular grey and buff stones in thick mortar, the light on their upper left.
func _rubble(y0: float, y1: float) -> void:
	_rect(X0, y0, X1 - X0, y1 - y0, "#8E8A82")
	var tones := ["#B7AFA2", "#A89F92", "#C4BBAE", "#9C9286", "#BDB09C", "#A0988C"]
	var y := y0 + 3.0
	while y < y1 - 6.0:
		var h := rng.randf_range(26.0, 44.0)
		var x := X0 + rng.randf_range(-20.0, 0.0)
		while x < X1:
			var w := rng.randf_range(40.0, 90.0)
			var a := Vector2(maxf(x, X0) + 3.0, y + rng.randf_range(0.0, 5.0))
			var b := Vector2(minf(x + w, X1) - 3.0, y + rng.randf_range(0.0, 5.0))
			var c := Vector2(b.x - rng.randf_range(0.0, 6.0), minf(y + h, y1) - rng.randf_range(2.0, 6.0))
			var d := Vector2(a.x + rng.randf_range(0.0, 6.0), minf(y + h, y1) - rng.randf_range(2.0, 6.0))
			if b.x - a.x > 8.0:
				_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y), _n(c.x), _n(c.y), _n(d.x), _n(d.y)], tones[rng.randi_range(0, tones.size() - 1)])
				_path("M%s %s L%s %s" % [_n(a.x), _n(a.y + 1), _n(b.x), _n(b.y + 1)], "none", _stroke("#FFFFFF", 2) + ' opacity="0.25"')
			x += w
		y += h


# Ribbed metal siding over the whole upper floor (3112…, white over Poke Monster).
func _siding(y0: float, y1: float, color: String) -> void:
	_siding_panel(X0, X1, y0, y1, color)


func _siding_panel(x0: float, x1: float, y0: float, y1: float, color := "#B9BDC1") -> void:
	_rect(x0, y0, x1 - x0, y1 - y0, color)
	# Ribbed across (`siding_dir` "h": the red corrugated band of the RONA, 2908…), or up and down.
	if k.get("siding_dir", "v") == "h":
		var y := y0 + 4.0
		while y < y1 - 2.0:
			_rect(x0, y, x1 - x0, 3, "#000000", 'opacity="0.16"')
			_rect(x0, y + 3, x1 - x0, 1.5, "#FFFFFF", 'opacity="0.22"')
			y += 11.0
		_rect(x0, y0, x1 - x0, 6, "#000000", 'opacity="0.12"')
		return
	var x := x0 + 4.0
	while x < x1 - 2.0:
		_rect(x, y0, 2.5, y1 - y0, "#000000", 'opacity="0.1"')
		_rect(x + 2.5, y0, 1.5, y1 - y0, "#FFFFFF", 'opacity="0.25"')
		x += 12.0
	_rect(x0, y0, x1 - x0, 6, "#000000", 'opacity="0.12"')


# A tall window with a round top, in a white frame (3086…): its glass, the fanlight bars, a sill.
func _round_window(x: float, w: float, y0: float, y1: float) -> void:
	var r := w / 2.0
	var outer := "M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x - 8), _n(y1), _n(y0 + r), _n(r + 8), _n(r + 8), _n(x + w + 8), _n(y0 + r), _n(y1)]
	_path(outer, "#F2F0EA", _stroke("#B9B5AC", 1.5))
	var glass := "M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x), _n(y1 - 4), _n(y0 + r + 6), _n(r), _n(r), _n(x + w), _n(y0 + r + 6), _n(y1 - 4)]
	_path(glass, "url(#glass)")
	_rect(x, y0 + r + 6, w, 5, "#F2F0EA")
	for i in range(1, 4):
		var a := PI + PI * i / 4.0
		_path("M%s %s L%s %s" % [_n(x + r), _n(y0 + r + 6), _n(x + r + cos(a) * r), _n(y0 + r + 6 + sin(a) * r)], "none", _stroke("#F2F0EA", 4))
	_rect(x + r - 2, y0 + r + 6, 4, y1 - y0 - r - 10, "#F2F0EA")
	_glass_shine(x, y0 + r + 6, w, y1 - y0 - r - 10)
	_rect(x - 14, y1, w + 28, 10, "#D8D2C6", _stroke("#9E968A", 1))
	_snow(x - 14, w + 28, y1)


# A low wall along the sidewalk, one storey, painted with big flowers, smiling faces and round medallions (3043…, 3053…), the
# buildings behind it hazy across their parking lot.
func _mural_wall() -> void:
	var g := ground_y
	var wall_top := g - 330.0
	_back_row(X0, X1, g - 700.0, wall_top + 10.0)
	_rect(X0, wall_top, X1 - X0, g - wall_top, "#E4DED4")
	_rect(X0 - 4, wall_top - 10, X1 - X0 + 8, 12, "#B9B3A8", _stroke("#8E887E", 1))
	_snow(X0 - 4, X1 - X0 + 8, wall_top - 10)
	split = out.size()
	var colors := ["#E85FA0", "#F2C230", "#3D8BD9", "#E8812E", "#8E5FC4", "#4FA34A"]
	# Medallions: a pale disc, a dark ring, a creature drawn in black inside.
	for i in 2:
		var mx := X0 + 110.0 + i * 170.0
		var my := g - 170.0
		_circle(mx, my, 62, "#F2EFE8", _stroke("#1A1A1A", 5))
		_path("M%s %s q22 -40 44 0 q-22 30 -44 0 z M%s %s l-10 -26 M%s %s l10 -26" % [_n(mx - 22), _n(my + 6), _n(mx - 8), _n(my - 12), _n(mx + 8), _n(my - 12)], "none", _stroke("#1A1A1A", 4))
		_circle(mx - 8, my, 4, "#1A1A1A")
		_circle(mx + 8, my, 4, "#1A1A1A")
	# Flowers and smiling faces all over the rest.
	var fx := X0 + 400.0
	var n := 0
	while fx < X1 - 40.0:
		var fy := g - 250.0 + (n % 3) * 70.0
		if n % 4 == 3:
			_circle(fx, fy, 30, "#F2C230", _stroke("#1A1A1A", 3))
			_circle(fx - 10, fy - 6, 3.5, "#1A1A1A")
			_circle(fx + 10, fy - 6, 3.5, "#1A1A1A")
			_path("M%s %s q10 12 20 0" % [_n(fx - 10), _n(fy + 8)], "none", _stroke("#1A1A1A", 3))
		else:
			for pet in 6:
				var a := TAU * pet / 6.0
				_circle(fx + cos(a) * 22.0, fy + sin(a) * 22.0, 15, colors[(n + pet) % colors.size()], _stroke("#1A1A1A", 2))
			_circle(fx, fy, 13, "#F2C230", _stroke("#1A1A1A", 2))
			_path("M%s %s Q%s %s %s %s" % [_n(fx), _n(fy + 36), _n(fx - 12), _n(g - 60), _n(fx + 4), _n(g - 20)], "none", _stroke("#3E8A4E", 5))
		fx += 78.0
		n += 1


# ── Rue Masson, 5e to 6e: the church and its presbytery ──────────────────────
# From rue-masson/2851… (AteR4eKT, usCf6EmL, krau45Tn, j7kmhWm0) and 2863… and their close-ups: Église Saint-Esprit de Rosemont
# set back behind its wide flight of steps, pale grey stone, its tower in the middle, three arched doors of brown wood under
# tracery, buttresses with pinnacles, a low aisle each side; the grounds round it with their trees, cedars and iron fence.
# The tower's top is above every picture: drawn as a short copper pyramid with its cross, over a belfry stage.

# Rough-faced stone in courses over a rectangle, each block its own tone (`_ashlar` for any part of a facade).
func _stone_courses(x0: float, y0: float, x1: float, y1: float, stone: String, course := 40.0, block := 96.0) -> void:
	_rect(x0, y0, x1 - x0, y1 - y0, "#" + Color(stone).darkened(0.22).to_html(false))
	var y := y0
	var row := 0
	while y < y1:
		var h := minf(course - 2.0, y1 - y)
		var x := x0 - (block / 2.0 if row % 2 == 1 else 0.0)
		while x < x1:
			var bx := maxf(x, x0)
			var bw := minf(x + block - 2.0, x1) - bx
			if bw > 2.0 and h > 1.0:
				var tone := Color(stone).lightened(rng.randf_range(-0.05, 0.07))
				_rect(bx + 1.0, y + 1.0, bw - 2.0, h - 2.0, "#" + tone.to_html(false))
				_rect(bx + 1.0, y + 1.0, bw - 2.0, 2.5, "#FFFFFF", 'opacity="0.2"')
			x += block
		y += course
		row += 1


# A pointed (lancet) window in a stone surround, its stained glass in small leaded panes: x its middle, y0 the arch's tip.
const CHURCH_GLASS := ["#2E4A78", "#3A5A8E", "#26406A", "#44689E"]
func _lancet(x: float, y0: float, y1: float, w: float, trim: String, palette: Array = []) -> void:
	var r := w / 2.0
	var spring := y0 + w * 0.85
	var outer := "M%s %s V%s Q%s %s %s %s Q%s %s %s %s V%s Z" % [_n(x - r - 12), _n(y1), _n(spring), _n(x - r - 12), _n(y0 - 6), _n(x), _n(y0 - 22), _n(x + r + 12), _n(y0 - 6), _n(x + r + 12), _n(spring), _n(y1)]
	_path(outer, trim, _stroke("#8A867E", 1.5))
	var glass := "M%s %s V%s Q%s %s %s %s Q%s %s %s %s V%s Z" % [_n(x - r), _n(y1), _n(spring), _n(x - r), _n(y0 + 8), _n(x), _n(y0), _n(x + r), _n(y0 + 8), _n(x + r), _n(spring), _n(y1)]
	_path(glass, "#2C3646")
	# The leaded panes, a little colour in them, catching the light low down.
	var colors: Array = palette if not palette.is_empty() else ["#3E5E8E", "#8E3E3E", "#C9A23A", "#3E7A5E", "#5E4A8E"]
	var py := spring - 10.0
	var row := 0
	while py < y1 - 8.0:
		for i in 3:
			var px := x - r + 4.0 + i * (w - 8.0) / 3.0
			_rect(px + 1, py + 1, (w - 8.0) / 3.0 - 2.0, 20, colors[(row + i * 2) % colors.size()], 'opacity="0.55"')
		py += 24.0
		row += 1
	_path(glass, "url(#glass)", 'opacity="0.35"')
	if not palette.is_empty():
		_rect(x - r + 5, y1 - (y1 - spring) * 0.45, w - 10, (y1 - spring) * 0.45 - 6, "none", _stroke("#C9A84A", 2) + ' opacity="0.8"')
	_rect(x - 1.5, spring - 20, 3, y1 - spring + 20, "#8A867E")
	_path("M%s %s Q%s %s %s %s Q%s %s %s %s" % [_n(x - r + 6), _n(spring + 6), _n(x - r * 0.4), _n(spring - 30), _n(x), _n(spring - 4), _n(x + r * 0.4), _n(spring - 30), _n(x + r - 6), _n(spring + 6)], "none", _stroke("#8A867E", 3))
	_rect(x - r - 16, y1, w + 32, 10, trim, _stroke("#8A867E", 1))
	_snow(x - r - 16, w + 32, y1)


# A carved Art Deco band (2851… close-ups): a row of upright triangles between two fillets, each with a smaller one inside.
func _deco_band(x0: float, x1: float, y: float, h: float, trim: String) -> void:
	_rect(x0, y, x1 - x0, h, trim, _stroke("#8A867E", 1))
	_rect(x0, y + 3, x1 - x0, 1.2, "#8A867E", 'opacity="0.8"')
	_rect(x0, y + h - 4, x1 - x0, 1.2, "#8A867E", 'opacity="0.8"')
	var tx := x0 + 4.0
	var tw := h * 0.9
	while tx + tw < x1 - 2.0:
		_path("M%s %s L%s %s L%s %s Z" % [_n(tx), _n(y + h - 6), _n(tx + tw / 2.0), _n(y + 6), _n(tx + tw), _n(y + h - 6)], "none", _stroke("#8A867E", 1.4))
		_path("M%s %s L%s %s L%s %s Z" % [_n(tx + tw * 0.3), _n(y + h - 8), _n(tx + tw / 2.0), _n(y + h * 0.45), _n(tx + tw * 0.7), _n(y + h - 8)], "#000000", 'opacity="0.12"')
		tx += tw + 3.0


# A small carved lozenge.
func _lozenge(x: float, y: float, r: float, trim: String) -> void:
	_path("M%s %s l%s %s l%s %s l%s %s z" % [_n(x), _n(y - r), _n(r), _n(r), _n(-r), _n(r), _n(-r), _n(-r)], trim, _stroke("#8A867E", 1.3))
	_path("M%s %s l%s %s l%s %s l%s %s z" % [_n(x), _n(y - r * 0.5), _n(r * 0.5), _n(r * 0.5), _n(-r * 0.5), _n(r * 0.5), _n(-r * 0.5), _n(-r * 0.5)], "#000000", 'opacity="0.12"')


# An angel carved in the stone, standing on its pedestal under a little spire, hands joined, wings folded (2851… close-ups).
func _angel(x: float, foot: float, h: float, trim: String) -> void:
	var line := _stroke("#8A867E", 1.2)
	_rect(x - 16, foot, 32, 20, trim, line)
	_rect(x - 20, foot + 20, 40, 8, trim, line)
	# The wings behind, the robe, the head, the joined hands.
	_path("M%s %s Q%s %s %s %s L%s %s Z" % [_n(x - 4), _n(foot - h * 0.78), _n(x - 22), _n(foot - h * 0.7), _n(x - 16), _n(foot - h * 0.2), _n(x - 6), _n(foot - h * 0.3)], trim, line)
	_path("M%s %s Q%s %s %s %s L%s %s Z" % [_n(x + 4), _n(foot - h * 0.78), _n(x + 22), _n(foot - h * 0.7), _n(x + 16), _n(foot - h * 0.2), _n(x + 6), _n(foot - h * 0.3)], trim, line)
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x - 9), _n(foot - h * 0.74), _n(x + 9), _n(foot - h * 0.74), _n(x + 13), _n(foot), _n(x - 13), _n(foot)], trim, line)
	for f in 3:
		_rect(x - 6 + f * 5.0, foot - h * 0.5, 1.2, h * 0.48, "#8A867E", 'opacity="0.6"')
	_circle(x, foot - h * 0.84, h * 0.09, trim, line)
	_path("M%s %s l4 -8 l4 8 z" % [_n(x - 4), _n(foot - h * 0.5)], "#8A867E", 'opacity="0.6"')
	_rect(x + 8, foot - h * 0.74, 5, h * 0.74, "#000000", 'opacity="0.12"')
	# Its canopy: a small hood and spire over the head.
	_path("M%s %s L%s %s L%s %s Z" % [_n(x - 14), _n(foot - h - 2), _n(x), _n(foot - h - 40), _n(x + 14), _n(foot - h - 2)], trim, line)
	_rect(x - 15, foot - h - 4, 30, 6, trim, line)


# A stepped buttress up a facade, with its pinnacle: x its middle, from y0 (the pinnacle's foot) down to y1.
func _buttress(x: float, y0: float, y1: float, w: float, stone: String, trim: String) -> void:
	_stone_courses(x - w / 2.0, y0, x + w / 2.0, y1, stone, 40.0, w)
	_rect(x - w / 2.0, y0, 6, y1 - y0, "#FFFFFF", 'opacity="0.18"')
	_rect(x + w / 2.0 - 8, y0, 8, y1 - y0, "#000000", 'opacity="0.14"')
	for t: float in [0.35, 0.7]:
		var sy := lerpf(y0, y1, t)
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(x - w / 2.0 - 6), _n(sy + 14), _n(x - w / 2.0 - 6), _n(sy + 4), _n(x + w / 2.0 + 6), _n(sy - 10), _n(x + w / 2.0 + 6), _n(sy + 14)], trim, _stroke("#8A867E", 1))
		_snow(x - w / 2.0 - 6, w + 12, sy - 4)
	# The pinnacle: a little shaft, its gable faces and a spike with a finial.
	_rect(x - w / 2.0 + 4, y0 - 46, w - 8, 46, trim, _stroke("#8A867E", 1))
	_path("M%s %s L%s %s L%s %s Z" % [_n(x - w / 2.0 + 2), _n(y0 - 46), _n(x), _n(y0 - 118), _n(x + w / 2.0 - 2), _n(y0 - 46)], trim, _stroke("#8A867E", 1.2))
	_path("M%s %s L%s %s L%s %s Z" % [_n(x), _n(y0 - 118), _n(x + w / 2.0 - 2), _n(y0 - 46), _n(x + 4), _n(y0 - 46)], "#000000", 'opacity="0.12"')
	_circle(x, y0 - 122, 5, trim, _stroke("#8A867E", 1))


# One of the church's doors: brown wood in planks under a tracery fanlight, deep in its stepped arch.
func _church_door(x: float, w: float, floor_y: float, h: float, trim: String, stone: String) -> void:
	var r := w / 2.0
	var spring := floor_y - h + r
	for order: Array in [[r + 34.0, trim], [r + 20.0, "#" + Color(stone).darkened(0.1).to_html(false)], [r + 8.0, "#" + Color(stone).darkened(0.25).to_html(false)]]:
		var a: float = order[0]
		_path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x - a), _n(floor_y), _n(spring), _n(a), _n(a), _n(x + a), _n(spring), _n(floor_y)], order[1], _stroke("#8A867E", 1.2))
	_path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x - r), _n(floor_y), _n(spring), _n(r), _n(r), _n(x + r), _n(spring), _n(floor_y)], "#6E4226", _stroke("#3E2414", 2))
	# The fanlight: dark glass in the arch, its iron tracery in rays and a ring.
	_path("M%s %s A%s %s 0 0 1 %s %s Z" % [_n(x - r + 4), _n(spring + 6), _n(r - 4), _n(r - 4), _n(x + r - 4), _n(spring + 6)], "#232A33")
	for i in 7:
		var a := PI + PI * (i + 0.5) / 7.0
		_path("M%s %s L%s %s" % [_n(x), _n(spring + 6), _n(x + cos(a) * (r - 6)), _n(spring + 6 + sin(a) * (r - 6))], "none", _stroke("#C9C5BC", 1.6) + ' opacity="0.7"')
	_path("M%s %s A%s %s 0 0 1 %s %s" % [_n(x - r * 0.45), _n(spring + 6), _n(r * 0.45), _n(r * 0.45), _n(x + r * 0.45), _n(spring + 6)], "none", _stroke("#C9C5BC", 1.6) + ' opacity="0.7"')
	_rect(x - r, spring + 6, w, 8, "#4A2C18")
	# Two leaves of vertical planks, their iron studs and handles.
	var py := spring + 14.0
	var px := x - r + 6.0
	while px < x + r - 6.0:
		_rect(px, py, 1.5, floor_y - py, "#3E2414", 'opacity="0.6"')
		_rect(px + 1.5, py, 2, floor_y - py, "#FFFFFF", 'opacity="0.08"')
		px += 16.0
	_rect(x - 1.5, py, 3, floor_y - py, "#2A160A")
	for sy in [py + 40.0, floor_y - 60.0]:
		_rect(x - r + 6, sy, w - 12, 5, "#2A2A2A", 'opacity="0.7"')
	_rect(x - 10, lerpf(py, floor_y, 0.5), 6, 22, "#C9A23A")
	_rect(x + 4, lerpf(py, floor_y, 0.5), 6, 22, "#C9A23A")


# A row of brick buildings further back (behind a churchyard or a lot): plain walls of a few tones, their windows, flat roofs,
# veiled in the haze of the distance.
func _back_row(x0: float, x1: float, top: float, bottom: float) -> void:
	var tones := ["#9A5A48", "#A8664E", "#8E5040", "#B07A5E", "#946050"]
	var x := x0
	var i := 0
	while x < x1:
		var w := minf(rng.randf_range(260.0, 380.0), x1 - x)
		var t := top + rng.randf_range(-40.0, 60.0)
		_rect(x, t, w, bottom - t, tones[i % tones.size()])
		_rect(x, t - 8, w, 10, "#6E6A64")
		var wy := t + 40.0
		while wy < bottom - 90.0:
			var wx := x + 30.0
			while wx < x + w - 70.0:
				_rect(wx, wy, 50, 74, "#E2DCCF")
				_rect(wx + 4, wy + 4, 42, 66, "#5A6E7E")
				wx += 100.0
			wy += 150.0
		_snow(x, w, t - 8)
		x += w
		i += 1
	_rect(x0, top - 120, x1 - x0, bottom - top + 120, "#C9D6E2", 'opacity="0.38"')


# The grass of a churchyard or a lot, the season's.
func _lawn(x0: float, x1: float, y0: float) -> void:
	var c: String = {"winter": "#EEF2F5", "spring": "#6FA04A", "summer": "#5E9440"}.get(season, "#7E8A4A")
	_rect(x0, y0, x1 - x0, ground_y - y0, c)
	if season == "winter":
		# Snow is never flat white: blue in the hollows, a few drifts catching the light.
		_rect(x0, y0, x1 - x0, ground_y - y0, "#B9C8DA", 'opacity="0.35"')
		var dx := x0
		while dx < x1:
			out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" opacity="0.7"/>' % [_n(dx + 40), _n(y0 + (ground_y - y0) * 0.55), _n(60), _n(10)])
			dx += 140.0
	_rect(x0, y0, x1 - x0, 4, "#000000", 'opacity="0.1"')
	if season != "winter":
		for i in int((x1 - x0) / 9.0):
			var gx := x0 + 4.0 + i * 9.0 + rng.randf_range(-3.0, 3.0)
			_path("M%s %s l%s %s" % [_n(gx), _n(ground_y - 2), _n(rng.randf_range(-3.0, 3.0)), _n(-rng.randf_range(6.0, 14.0))], "none", _stroke("#" + Color(c).darkened(0.25).to_html(false), 1.5))


# A black iron fence along the sidewalk from x0 to x1, spear-topped bars between square posts.
func _iron_fence(x0: float, x1: float) -> void:
	var top := ground_y - 64.0
	var bar := x0 + 6.0
	while bar < x1 - 4.0:
		_rect(bar, top + 6, 2.5, ground_y - top - 8, "#1F1F1F")
		_path("M%s %s l3.5 -9 l3.5 9 z" % [_n(bar - 2.25), _n(top + 7)], "#1F1F1F")
		bar += 12.0
	_rect(x0, top + 12, x1 - x0, 3, "#1F1F1F")
	_rect(x0, ground_y - 12, x1 - x0, 3, "#1F1F1F")
	_snow(x0, x1 - x0, top + 12)
	var post := x0
	while post <= x1:
		_rect(post - 4, top - 4, 8, ground_y - top + 4, "#1F1F1F")
		_circle(post, top - 6, 5, "#1F1F1F")
		post += 240.0


func _church() -> void:
	var stone: String = k.get("stone", "#C9C6BE")
	var trim := "#" + Color(stone).lightened(0.12).to_html(false)
	var cx: float = k.church_cx
	var g := ground_y
	var floor_y := g - 100.0
	var half := 560.0
	var aisle := 300.0
	var tw := 190.0
	var bay_top := g - 690.0
	var tower_top := g - 840.0
	var belfry_top := g - 955.0
	var spire_top := g - 1010.0
	var aisle_top := g - 420.0
	# Behind the grounds, across the yards: the plexes of the avenue beyond, a little hazy with the distance.
	_back_row(X0, X1, g - 600.0, g - 100.0)
	# The grounds, in front of everything and round the church.
	_lawn(X0, X1, g - 110.0)
	# The aisles, low, under their slate roofs.
	for side: float in [-1.0, 1.0]:
		var a0: float = cx + side * half
		var a1: float = cx + side * (half + aisle)
		_stone_courses(minf(a0, a1), aisle_top, maxf(a0, a1), floor_y, stone)
		_rect(minf(a0, a1) - 4, aisle_top - 6, aisle + 8, 14, trim, _stroke("#8A867E", 1))
		_snow(minf(a0, a1) - 4, aisle + 8, aisle_top - 6)
		_deco_band(minf(a0, a1) + 10, maxf(a0, a1) - 10, aisle_top + 26.0, 26.0, trim)
		_lancet(cx + side * (half + aisle / 2.0), aisle_top + 90.0, aisle_top + 270.0, 44.0, trim, CHURCH_GLASS)
	# The front: its two bays either side of the tower, crenellated along the top.
	_stone_courses(cx - half, bay_top, cx + half, floor_y, stone)
	_rect(cx - half, bay_top, 2 * half, floor_y - bay_top, "url(#sun)")
	for side: float in [-1.0, 1.0]:
		var m := cx + side * tw
		var e := cx + side * half
		var mx := minf(m, e)
		var ex := maxf(m, e)
		_rect(mx - 6, bay_top - 16, ex - mx + 12, 18, trim, _stroke("#8A867E", 1))
		_rect(mx - 6, bay_top - 16, ex - mx + 12, 3, "#FFFFFF", 'opacity="0.3"')
		_snow(mx - 6, ex - mx + 12, bay_top - 16)
		_deco_band(mx + 30, ex - 30, bay_top + 30.0, 28.0, trim)
		var wx := cx + side * (tw + half) / 2.0
		_lancet(wx, g - 640.0, g - 470.0, 62.0, trim, CHURCH_GLASS)
		_lozenge(wx, g - 690.0 + 26.0, 13.0, trim)
		_lozenge(wx, g - 428.0, 11.0, trim)
	# The tower, up through the middle, its belfry with tall louvred openings, a copper pyramid and its cross.
	_stone_courses(cx - tw, tower_top, cx + tw, floor_y, stone)
	_rect(cx - tw, tower_top, 8, floor_y - tower_top, "#FFFFFF", 'opacity="0.16"')
	_rect(cx + tw - 10, tower_top, 10, floor_y - tower_top, "#000000", 'opacity="0.12"')
	_rect(cx - tw - 8, tower_top - 12, 2 * tw + 16, 16, trim, _stroke("#8A867E", 1))
	_snow(cx - tw - 8, 2 * tw + 16, tower_top - 12)
	_stone_courses(cx - tw + 24, belfry_top, cx + tw - 24, tower_top - 12, stone)
	for side: float in [-1.0, 1.0]:
		var bx := cx + side * 62.0
		_path("M%s %s V%s Q%s %s %s %s Q%s %s %s %s V%s Z" % [_n(bx - 26), _n(tower_top - 26), _n(belfry_top + 50), _n(bx - 26), _n(belfry_top + 16), _n(bx), _n(belfry_top + 8), _n(bx + 26), _n(belfry_top + 16), _n(bx + 26), _n(belfry_top + 50), _n(tower_top - 26)], "#2A2E34", _stroke(trim, 4))
		var ly := belfry_top + 40.0
		while ly < tower_top - 30.0:
			_rect(bx - 24, ly, 48, 4, "#8E8A82")
			ly += 11.0
	_rect(cx - tw + 14, belfry_top - 10, 2 * tw - 28, 14, trim, _stroke("#8A867E", 1))
	_path("M%s %s L%s %s L%s %s Z" % [_n(cx - tw + 18), _n(belfry_top - 10), _n(cx), _n(spire_top), _n(cx + tw - 18), _n(belfry_top - 10)], "#6E9A86", _stroke("#4E7A66", 1.5))
	_path("M%s %s L%s %s L%s %s Z" % [_n(cx), _n(spire_top), _n(cx + tw - 18), _n(belfry_top - 10), _n(cx + 10), _n(belfry_top - 10)], "#000000", 'opacity="0.14"')
	if season == "winter":
		_path("M%s %s L%s %s L%s %s Z" % [_n(cx - 40), _n(spire_top + 30), _n(cx), _n(spire_top + 4), _n(cx + 30), _n(spire_top + 26)], "#F7F9FB")
	_rect(cx - 3, spire_top - 46, 6, 50, "#3A3A3A")
	_rect(cx - 16, spire_top - 34, 32, 6, "#3A3A3A")
	for side: float in [-1.0, 1.0]:
		var px := cx + side * (tw - 6.0)
		_rect(px - 12, tower_top - 52, 24, 40, trim, _stroke("#8A867E", 1))
		_path("M%s %s L%s %s L%s %s Z" % [_n(px - 14), _n(tower_top - 52), _n(px), _n(tower_top - 104), _n(px + 14), _n(tower_top - 52)], trim, _stroke("#8A867E", 1))
	# Its tall window over the great door, and a carved band of little blind arches right across the front.
	_lancet(cx, g - 760.0, g - 480.0, 74.0, trim, CHURCH_GLASS)
	_deco_band(cx - tw + 30, cx + tw - 30, g - 456.0, 30.0, trim)
	_lozenge(cx, g - 412.0, 12.0, trim)
	# The buttresses: at the front's corners and either side of the tower.
	for bx: float in [cx - half, cx - tw, cx + tw, cx + half]:
		var top := tower_top + 60.0 if absf(bx - cx) < tw + 1.0 else bay_top + 20.0
		_buttress(bx, top, floor_y, 54.0, stone, trim)
	# The three doors, the great one in the middle.
	_church_door(cx, 150.0, floor_y, 320.0, trim, stone)
	for side: float in [-1.0, 1.0]:
		_church_door(cx + side * (tw + half) / 2.0, 118.0, floor_y, 262.0, trim, stone)
	# The angels standing on the buttresses either side of the great door and at the front's corners, under little spires.
	for bx: float in [cx - half, cx - tw, cx + tw, cx + half]:
		_angel(bx, floor_y - 250.0, 110.0, trim)
	split = out.size()
	# The flight of steps right across, its cheek walls, the handrails and the lamps on their posts.
	var s0 := cx - half - 40.0
	var s1 := cx + half + 40.0
	for i in 8:
		var sy := floor_y + i * 12.5
		var inset := 0.0
		_rect(s0 + inset, sy, s1 - s0 - 2 * inset, 12.5, "#C2BEB6" if i % 2 == 0 else "#BAB6AE")
		_rect(s0 + inset, sy, s1 - s0 - 2 * inset, 3, "#E2DED6")
		_rect(s0 + inset, sy + 10.5, s1 - s0 - 2 * inset, 2, "#8A867E", 'opacity="0.6"')
		_snow(s0, s1 - s0, sy)
	for side: float in [-1.0, 1.0]:
		var wx: float = cx + side * (half + 40.0)
		_stone_courses(minf(wx, wx - side * 70.0), floor_y - 30.0, maxf(wx, wx - side * 70.0), g, stone, 34.0, 70.0)
		_rect(minf(wx, wx - side * 70.0) - 4, floor_y - 38.0, 78, 10, trim, _stroke("#8A867E", 1))
		_snow(minf(wx, wx - side * 70.0) - 4, 78, floor_y - 38.0)
		for mid: float in [tw * 0.55, (tw + half) / 2.0 + 90.0]:
			var hx: float = cx + side * mid
			_path("M%s %s L%s %s M%s %s L%s %s M%s %s L%s %s" % [_n(hx), _n(floor_y - 40), _n(hx), _n(g - 6), _n(hx - 3), _n(floor_y - 40), _n(hx - 3), _n(g - 40), _n(hx), _n(floor_y - 40), _n(hx + 26 * side), _n(floor_y - 40)], "none", _stroke("#9A9C9E", 3.5) + ' stroke-linecap="round"')
		# The lamp post at each end of the steps: a black post with its cluster of lanterns.
		var lx: float = cx + side * (half + 5.0)
		_rect(lx - 5, floor_y - 290, 10, 260, "#1A1A1A")
		_rect(lx - 9, floor_y - 40, 18, 12, "#1A1A1A")
		_circle(lx, floor_y - 310, 26, "url(#glow)")
		_rect(lx - 10, floor_y - 334, 20, 40, "#ECE7DA", _stroke("#1A1A1A", 2.5))
		_rect(lx - 1, floor_y - 334, 2, 40, "#1A1A1A")
		_path("M%s %s l13 -12 l13 12 z" % [_n(lx - 13), _n(floor_y - 334)], "#1A1A1A")
		_rect(lx - 8, floor_y - 294, 16, 6, "#1A1A1A")
	# The grounds either side: cedars along the left, a big tree on the right, the iron fence along the sidewalk.
	var left_end := cx - half - aisle
	var right_start := cx + half + aisle
	var cedar := X0 + 50.0
	while cedar < left_end - 30.0:
		_cedar(cedar, g - 260.0 - rng.randf_range(0.0, 60.0))
		cedar += 70.0
	_fine_tree(Vector2(lerpf(right_start, X1, 0.3), g - 70.0), g - 300.0, -PI * 0.62, 1.35, ["#E3A33A", "#D9682B", "#C9562E", "#E8B54A", "#D9A23A"])
	_fine_tree(Vector2(lerpf(right_start, X1, 0.78), g - 66.0), g - 280.0, -PI * 0.4, 1.25, ["#D9A23A", "#C9562E", "#E3A33A", "#B5442E"])
	for i in 4:
		_shrub(right_start + 60.0 + i * 120.0, 30.0 + rng.randf_range(0.0, 10.0), "#3E6A3A")
	_iron_fence(X0, s0 - 72.0)
	_iron_fence(s1 + 72.0, X1)


# The presbytery beside it, from the close-ups of 2851… (AteR4eKT, usCf6EmL): red brick on three floors, buff brick laid in
# zigzag friezes, a band of green copper along the roof with a raised curved gable and its cross in the middle, white
# globes on posts, segmental arches over the windows, the porch on four grey columns under its own curved gable; junipers and
# an iron fence in front. Drawn over `_building()` (bricks, windows, foundation).
func _zigzag_frieze(x0: float, x1: float, y: float, h: float) -> void:
	var buff := "#E2C98E"
	var cell := 9.0
	var rows := int(h / cell)
	var x := x0
	var col := 0
	while x < x1 - cell:
		for r in rows:
			var zig := absi((col % (rows * 2 - 2)) - (rows - 1)) if rows > 1 else 0
			if r == zig or r == (zig + rows / 2) % rows:
				_rect(x + 1, y + r * cell + 1, cell - 2, cell - 2, buff)
		x += cell
		col += 1


func _presbytere() -> void:
	var top := _top()
	var cx: float = k.door_cx
	var copper := "#5E8E76"
	_zigzag_frieze(X0, X1, top + 20.0, 45.0)
	# The copper band along the roof, a lattice pressed into it.
	_rect(X0 - 8, top - 40, X1 - X0 + 16, 50, copper, _stroke("#3E6E56", 1.5))
	var lx := X0
	while lx < X1:
		_path("M%s %s l14 22 l14 -22 M%s %s l14 -22 l14 22" % [_n(lx), _n(top - 30), _n(lx), _n(top + 2)], "none", _stroke("#8EBEA6", 1.4) + ' opacity="0.7"')
		lx += 28.0
	_rect(X0 - 8, top - 44, X1 - X0 + 16, 8, "#4E7E66")
	_snow(X0 - 8, X1 - X0 + 16, top - 44)
	# The raised gable over the middle, curved, its cross in buff brick, a globe at each shoulder.
	var gw := 170.0
	_path("M%s %s V%s Q%s %s %s %s Q%s %s %s %s V%s Z" % [_n(cx - gw), _n(top - 40), _n(top - 60), _n(cx - gw * 0.6), _n(top - 130), _n(cx), _n(top - 132), _n(cx + gw * 0.6), _n(top - 130), _n(cx + gw), _n(top - 60), _n(top - 40)], k.bricks[0], _stroke(k.lintel_dark, 1.5))
	_path("M%s %s Q%s %s %s %s Q%s %s %s %s" % [_n(cx - gw - 6), _n(top - 58), _n(cx - gw * 0.6), _n(top - 138), _n(cx), _n(top - 140), _n(cx + gw * 0.6), _n(top - 138), _n(cx + gw + 6), _n(top - 58)], "none", _stroke("#D8D2C6", 9) + ' stroke-linecap="round"')
	_zigzag_frieze(cx - gw + 20, cx + gw - 20, top - 70.0, 27.0)
	_rect(cx - 5, top - 118, 10, 40, "#E2C98E")
	_rect(cx - 16, top - 106, 32, 10, "#E2C98E")
	for side: float in [-1.0, 1.0]:
		var gx := cx + side * (gw + 4.0)
		_rect(gx - 9, top - 82, 18, 26, "#D8D2C6", _stroke("#9E968A", 1))
		_circle(gx, top - 92, 12, "#F2EFE8", _stroke("#9E968A", 1))
	# Buff friezes between the floors too.
	_zigzag_frieze(X0, X1, _fb(1) + 8.0, 27.0)
	split = out.size()
	# The porch: steps up, four grey columns, the curved gable with its cross and two globes.
	var pw := 150.0
	var porch := _fb(0)
	for i in 7:
		var sy := porch + i * ((ground_y - porch) / 7.0)
		_rect(cx - 70 - i * 3.0, sy, 140 + i * 6.0, (ground_y - porch) / 7.0, "#9C968C" if i % 2 == 0 else "#A9A398")
		_rect(cx - 70 - i * 3.0, sy, 140 + i * 6.0, 2, "#C9C3B8")
	_rect(cx - 52, _door_top(0), 104, porch - _door_top(0), "#5E3A22", _stroke("#3E2414", 2))
	_rect(cx - 40, _door_top(0) + 14, 80, 90, "url(#glass)")
	_rect(cx - 40, _door_top(0) + 120, 80, 4, "#3E2414")
	var col_top := porch - 250.0
	for p: float in [-pw, -pw + 52.0, pw - 52.0, pw]:
		var px: float = cx + p
		_rect(px - 13, col_top, 26, porch - col_top, "#C9C5BC", _stroke("#8E8A82", 1.2))
		_rect(px - 13, col_top, 7, porch - col_top, "#FFFFFF", 'opacity="0.25"')
		_rect(px - 18, col_top - 10, 36, 12, "#D8D4CC", _stroke("#8E8A82", 1))
		_rect(px - 18, porch - 14, 36, 14, "#B9B5AC", _stroke("#8E8A82", 1))
	_rect(cx - pw - 26, col_top - 34, 2 * pw + 52, 26, "#D8D4CC", _stroke("#8E8A82", 1.2))
	_path("M%s %s Q%s %s %s %s" % [_n(cx - pw - 20), _n(col_top - 34), _n(cx), _n(col_top - 130), _n(cx + pw + 20), _n(col_top - 34)], k.bricks[1], _stroke("#D8D2C6", 7))
	_zigzag_frieze(cx - 80, cx + 80, col_top - 74.0, 27.0)
	_rect(cx - 4, col_top - 112, 8, 34, "#E2C98E")
	_rect(cx - 13, col_top - 102, 26, 8, "#E2C98E")
	for side: float in [-1.0, 1.0]:
		_circle(cx + side * (pw + 20.0), col_top - 48, 11, "#F2EFE8", _stroke("#9E968A", 1))
	_snow(cx - pw - 26, 2 * pw + 52, col_top - 34)
	# The junipers in front and the iron fence along the sidewalk.
	for jx: float in [X0 + 60.0, X0 + 170.0, cx - 230.0, cx + 230.0, X1 - 170.0, X1 - 60.0]:
		_shrub(jx, 44.0 + rng.randf_range(0.0, 10.0), "#3A6A44")
	_iron_fence(X0, cx - 80.0)
	_iron_fence(cx + 80.0, X1)


# The lot between the shops at 2876 (rue-masson/2876…): a gap in the row, asphalt, the backs of the plexes beyond with their
# black iron stair, a teal shed painted with leaves and flowers, a big tree; the bins, crates and cars of the picture left out.
func _masson_lot() -> void:
	match k.get("lot_style", "shed"):
		"murals":
			_mural_passage()
			return
		"plaza":
			_plaza()
			return
		"setback":
			_setback()
			return
		"court":
			_school_court()
			return
		"parking":
			_parking_lot()
			return
	var g := ground_y
	var back := g - 160.0
	# The plexes behind, across their yards: brick, windows, the iron stair zigzagging down.
	_bricks(g - 720.0, back)
	_rect(X0, g - 720.0, X1 - X0, back - g + 720.0, "#1A1428", 'opacity="0.18"')
	for wx: float in [X0 + 40.0, X0 + 230.0]:
		for f in 2:
			_rect(wx, g - 680.0 + f * 250.0, 80, 120, "#E9E3D6")
			_rect(wx + 6, g - 674.0 + f * 250.0, 68, 108, "url(#glass)")
	for i in 3:
		var sy := g - 470.0 + i * 120.0
		_path("M%s %s L%s %s" % [_n(X0 + 150), _n(sy), _n(X0 + 330), _n(sy + 110)], "none", _stroke("#1A1A1A", 6))
		_rect(X0 + 140, sy - 6, 200, 6, "#1A1A1A")
	# The ground: old asphalt, a patch, the edge of the sidewalk.
	_rect(X0, back, X1 - X0, g - back, "#7E7C78")
	_rect(X0, back, X1 - X0, 6, "#000000", 'opacity="0.2"')
	out.append('<ellipse cx="%s" cy="%s" rx="60" ry="10" fill="#6A6864" opacity="0.6"/>' % [_n(X0 + 140), _n(g - 60)])
	_snow(X0, X1 - X0, back + 2)
	split = out.size()
	# The teal shed with its painted leaves and flowers, and a board fence beside it.
	var sx0 := X1 - 230.0
	_rect(sx0, g - 230.0, 200, 200, "#5EB8B0", _stroke("#3E8A84", 2))
	_path("M%s %s L%s %s L%s %s Z" % [_n(sx0 - 8), _n(g - 228), _n(sx0 + 100), _n(g - 262), _n(sx0 + 208), _n(g - 228)], "#4E5256")
	_snow(sx0 - 8, 216, g - 236)
	for i in 6:
		var p := Vector2(sx0 + 30 + i * 30, g - 80 - (i % 3) * 40.0)
		_plant_leaf(p, 30.0, -30.0 + i * 25.0, ["#3E8A4E", "#2E6E3E", "#6EA84E"][i % 3])
	for i in 3:
		_bloom(sx0 + 50 + i * 55, g - 170 + (i % 2) * 30.0, 12.0, ["#F2C230", "#E8812E", "#E85FA0"][i])
	_circle(sx0 + 150, g - 190, 18, "#F2C230")
	_wood_fence([[X0, sx0 - 170.0], [sx0, X1]])
	_fine_tree(Vector2(sx0 - 40, g - 40), g - 380.0, -PI * 0.55, 1.0, ["#E3A33A", "#D9A23A", "#C9562E", "#E8B54A"])


# A narrow passage between two buildings, its brick walls painted over from top to bottom in bright murals (3016…, 3022…,
# 3026…): big swirling shapes and colour fields, no lettering; a black fire escape zigzagging up the back wall.
func _mural_passage() -> void:
	var g := ground_y
	_bricks(g - 780.0, g - 120.0)
	var colors := ["#E85FA0", "#3D8BD9", "#F2C230", "#E8812E", "#8E5FC4", "#4FA34A", "#E04A3A", "#5EC8C0"]
	# The painting keeps to the wall: a clip over the brick, broad fields of colour first, then bold shapes outlined in black.
	_clips += 1
	var top := g - 720.0
	var bottom := g - 130.0
	out.append('<clipPath id="mur%d"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath><g clip-path="url(#mur%d)">' % [_clips, _n(X0), _n(top), _n(X1 - X0), _n(bottom - top), _clips])
	var fx := X0
	var f := 0
	while fx < X1:
		var fw := rng.randf_range(90.0, 160.0)
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(fx), _n(top), _n(fx + fw + 30), _n(top), _n(fx + fw - 20), _n(bottom), _n(fx - 40), _n(bottom)], colors[(f * 3) % colors.size()], 'opacity="0.85"')
		fx += fw
		f += 1
	for i in 9:
		var c: String = colors[(i * 5 + 2) % colors.size()]
		var x := rng.randf_range(X0 + 40.0, X1 - 40.0)
		var y := rng.randf_range(top + 60.0, bottom - 60.0)
		var r := rng.randf_range(40.0, 80.0)
		_path("M%s %s q%s %s %s %s q%s %s %s %s q%s %s %s %s z" % [_n(x - r), _n(y), _n(r * 0.3), _n(-r * 0.9), _n(r * 1.1), _n(-r * 0.5), _n(r * 0.9), _n(r * 0.4), _n(r * 0.6), _n(r * 0.9), _n(-r * 0.9), _n(r * 0.6), _n(-r * 1.7), _n(-r * 0.4)], c, _stroke("#1A1A1A", 5))
		_path("M%s %s q%s %s %s %s" % [_n(x - r * 0.5), _n(y), _n(r * 0.3), _n(-r * 0.4), _n(r * 0.9), _n(-r * 0.1)], "none", _stroke("#FFFFFF", 5) + ' opacity="0.7" stroke-linecap="round"')
		# A few drips and stars of spray.
		_rect(x + r * 0.2, y + r * 0.5, 4, rng.randf_range(14.0, 34.0), c)
		_circle(x - r * 0.8, y - r * 0.7, 5, "#FFFFFF", 'opacity="0.8"')
	out.append('</g>')
	for i in 4:
		var sy := g - 640.0 + i * 120.0
		_rect(X0 + 70, sy - 6, 200, 6, "#1A1A1A")
		_path("M%s %s L%s %s" % [_n(X0 + 90), _n(sy), _n(X0 + 250), _n(sy + 114)], "none", _stroke("#1A1A1A", 6))
		var rail := X0 + 90.0
		while rail < X0 + 270.0:
			_rect(rail, sy - 40, 2, 34, "#1A1A1A")
			rail += 14.0
		_rect(X0 + 70, sy - 42, 200, 3, "#1A1A1A")
	_rect(X0, g - 120.0, X1 - X0, 120, "#7E7C78")
	_rect(X0, g - 120.0, X1 - X0, 6, "#000000", 'opacity="0.2"')
	_snow(X0, X1 - X0, g - 116.0)
	split = out.size()


# A little public square at a corner (2644…, 2648…): paving, long concrete planters of shrubs and grasses, benches, striped
# bollards, the brick backs of the buildings round it.
func _plaza() -> void:
	var g := ground_y
	_back_row(X0, X1, g - 560.0, g - 120.0)
	_rect(X0, g - 120.0, X1 - X0, 120, "#B9B4AA")
	var px := X0
	while px < X1:
		_rect(px, g - 120.0, 1.5, 120, "#8E8A82", 'opacity="0.5"')
		px += 60.0
	_snow(X0, X1 - X0, g - 118.0)
	split = out.size()
	var shrub_colors := {"winter": "#6A5A4A", "spring": "#4E8A44", "summer": "#3E7A3A"}
	var c: String = shrub_colors.get(season, "#C04A30")
	for b in 2:
		var bx0 := X0 + 30.0 + b * (X1 - X0) * 0.5
		var bx1 := bx0 + (X1 - X0) * 0.42
		for i in int((bx1 - bx0) / 46.0):
			_shrub(bx0 + 20.0 + i * 46.0, 30.0 + rng.randf_range(0.0, 10.0), c if i % 2 == 0 else "#8A9A4A")
		_rect(bx0, g - 60, bx1 - bx0, 46, "#A8A49C", _stroke("#7E7A72", 1.5))
		_rect(bx0, g - 60, bx1 - bx0, 5, "#C9C5BC")
		_rect(bx0 + 10, g - 50, bx1 - bx0 - 20, 4, "#5EC8C0", 'opacity="0.8"')
		_snow(bx0, bx1 - bx0, g - 60)
	# A bench, and a striped bollard at each end.
	var bench := (X0 + X1) / 2.0
	_rect(bench - 60, g - 52, 120, 8, "#8A6A4A")
	_rect(bench - 60, g - 72, 120, 6, "#8A6A4A")
	for lx: float in [bench - 54.0, bench + 50.0]:
		_rect(lx, g - 72, 4, 72, "#3A3A3A")
	for bx: float in [X0 + 14.0, X1 - 14.0]:
		_rect(bx - 4, g - 70, 8, 70, "#1A1A1A")
		for st in 3:
			_rect(bx - 4, g - 64 + st * 18.0, 8, 7, "#F2F0EA")


# A block set back from the street behind its lawn (2606…, 2618…, 2636…): the apartment buildings of the 1960s, plain brick
# on three floors with rows of windows, or (`white`) a low white commercial building with ribbon windows; a shop band
# (`band`, its colour) on the ground floor, trees and red shrubs on the lawn.
func _setback() -> void:
	var g := ground_y
	var lawn_top := g - 150.0
	var white: bool = k.get("white", false)
	var floors := 2 if white else 3
	var fh := 135.0
	var top := lawn_top - floors * fh - 20.0
	var x0 := X0
	var x1 := X1 - 150.0
	if white:
		_rect(x0, top, x1 - x0, lawn_top - top, "#ECEAE4", _stroke("#B9B5AC", 1.5))
		for f in floors:
			var wy := top + 30.0 + f * fh
			_rect(x0 + 20, wy, x1 - x0 - 40, 60, "#3A4048")
			_rect(x0 + 24, wy + 4, x1 - x0 - 48, 52, "url(#glass)")
			var mx := x0 + 80.0
			while mx < x1 - 40.0:
				_rect(mx, wy, 4, 60, "#3A4048")
				mx += 90.0
			_glass_shine(x0 + 24, wy + 4, x1 - x0 - 48, 52)
	else:
		var keep1 := X1
		X1 = x1
		_bricks(top, lawn_top)
		X1 = keep1
		for f in floors:
			var wx := x0 + 50.0
			while wx < x1 - 80.0:
				_rect(wx, top + 34.0 + f * fh, 70, 76, "#E8E4DA")
				_rect(wx + 4, top + 38.0 + f * fh, 62, 68, "url(#glass)")
				_rect(wx + 33, top + 38.0 + f * fh, 4, 68, "#E8E4DA")
				wx += 140.0
	_rect(x0 - 6, top - 12, x1 - x0 + 12, 14, "#8E8A82")
	_snow(x0 - 6, x1 - x0 + 12, top - 12)
	var band: String = k.get("band", "")
	if band != "":
		_rect(x0 + 60, lawn_top - fh + 10, (x1 - x0) * 0.55, 36, band)
		_rect(x0 + 60, lawn_top - fh + 46, (x1 - x0) * 0.55, fh - 46, "#2F3A41")
		_rect(x0 + 64, lawn_top - fh + 50, (x1 - x0) * 0.55 - 8, fh - 54, "url(#warm)", 'opacity="0.4"')
	split = out.size()
	_lawn(X0, X1, lawn_top)
	# The lawn lies flat, away from us: the building's shadow along its back edge, a path to the door, a low hedge along the
	# sidewalk (in winter a snowbank with the hedge's twigs poking out), so it never reads as a white wall.
	_rect(X0, lawn_top, X1 - X0, 26, "#3A4A6A" if season == "winter" else "#000000", 'opacity="0.22"')
	var hx := X0 + 14.0
	while hx < X1 - 10.0:
		if absf(hx - (X0 + (X1 - X0) * 0.45 + 30.0)) > 50.0:
			_shrub(hx, 22.0, "#3E6A3A")
		hx += 34.0
	_rect(X0 + (X1 - X0) * 0.45, lawn_top, 60, ground_y - lawn_top, "#B9B4AA")
	if white:
		var sx := X0 + 30.0
		while sx < X1 - 20.0:
			_shrub(sx, 40.0, {"winter": "#6A5A4A", "spring": "#6A3A3A", "summer": "#7A3A34"}.get(season, "#A83A2E"))
			sx += 60.0
	else:
		_fine_tree(Vector2(X0 + 140.0, g - 40.0), g - 330.0, -PI * 0.5, 1.0, ["#E3A33A", "#D9682B", "#C9562E", "#E8B54A"])


# The schoolyard by 6e (5522…): a lawn, then the basketball court behind a tall green chain-link fence, its hoop, the school's
# brick beyond.
func _school_court() -> void:
	var g := ground_y
	_back_row(X0, X1, g - 520.0, g - 140.0)
	_lawn(X0, X1, g - 140.0)
	var c0 := X0 + 80.0
	_rect(c0, g - 140.0, X1 - c0, 140, "#6E7A86")
	_rect(c0 + 20, g - 120.0, X1 - c0 - 40, 3, "#F2F0EA")
	split = out.size()
	var top := g - 300.0
	var post := c0
	while post <= X1:
		_rect(post - 3, top, 6, g - top, "#3E5E4A")
		post += 120.0
	var mesh := c0
	while mesh < X1:
		_path("M%s %s L%s %s M%s %s L%s %s" % [_n(mesh), _n(top), _n(mesh + 30), _n(g - 4), _n(mesh + 30), _n(top), _n(mesh), _n(g - 4)], "none", _stroke("#4E7A5E", 1) + ' opacity="0.55"')
		mesh += 15.0
	_rect(c0, top, X1 - c0, 5, "#3E5E4A")
	var hx := (c0 + X1) / 2.0
	_rect(hx - 4, g - 260, 8, 160, "#3A3A3A")
	_rect(hx - 40, g - 290, 80, 50, "#F2F0EA", _stroke("#3A3A3A", 2))
	_rect(hx - 16, g - 246, 32, 5, "#E8502A")


# A parking lot behind a low hedge (3021…): asphalt with its painted lines, the brick backs beyond; the cars left out.
func _parking_lot() -> void:
	var g := ground_y
	_back_row(X0, X1, g - 620.0, g - 150.0)
	_rect(X0, g - 150.0, X1 - X0, 150, "#7A7874")
	var lx := X0 + 40.0
	while lx < X1:
		_path("M%s %s L%s %s" % [_n(lx), _n(g - 140), _n(lx - 30), _n(g - 60)], "none", _stroke("#E8E4DA", 3) + ' opacity="0.8"')
		lx += 110.0
	_snow(X0, X1 - X0, g - 146.0)
	split = out.size()
	var hx := X0 + 30.0
	while hx < X1 - 20.0:
		_shrub(hx, 34.0, "#3E6A3A")
		hx += 52.0


# ── 6e Avenue between Dandurand and Masson, the west side ───────────────────
# From reference/streetview/6e-avenue/5360… to 5590… (and their close-ups): the long side of Église Saint-Esprit along 6e, its
# parish hall, the modern apartment block behind its court, the schoolyard, the school's gym; the school itself (`ecole`) is
# already drawn from its photo and kept.

# The church's long side (5360…, 5412…, 5418…, 5436…, 5444…): rock-faced grey stone in bays between buttresses, tall
# round-headed windows in pale stone surrounds, small square windows above and below, a belt course, and in the basement the red
# doors in pairs at the top of their steps with black rails; the tower's side at the Masson end (`tower_x`).
func _church_side() -> void:
	var stone: String = k.get("stone", "#9E9A92")
	var trim := "#D8D4CC"
	var g := ground_y
	var top := g - 640.0
	var base := g - 120.0
	_stone_courses(X0, top, X1, g - 6.0, stone, 34.0, 70.0)
	# The rough face: darker speckles on every stone.
	for i in int((X1 - X0) * (g - top) / 2600.0):
		_rect(rng.randf_range(X0, X1), rng.randf_range(top, g), rng.randf_range(4.0, 10.0), rng.randf_range(2.0, 5.0), "#5E5A54", 'opacity="0.35"')
	_rect(X0 - 6, top - 18, X1 - X0 + 12, 20, trim, _stroke("#8A867E", 1))
	_snow(X0 - 6, X1 - X0 + 12, top - 18)
	_rect(X0, base - 12, X1 - X0, 12, trim, _stroke("#8A867E", 1))
	var tx: float = k.get("tower_x", -1.0)
	if tx > 0.0:
		_stone_courses(tx, g - 960.0, tx + 260.0, top, stone, 34.0, 70.0)
		_rect(tx - 8, g - 975.0, 276, 18, trim, _stroke("#8A867E", 1))
		_lancet(tx + 130.0, g - 920.0, g - 760.0, 54.0, trim, CHURCH_GLASS)
	var bay: float = k.get("bay", 300.0)
	var x := X0 + 20.0
	while x < X1 - 40.0:
		if tx > 0.0 and x > tx - 60.0 and x < tx + 260.0:
			x += bay
			continue
		# A buttress, then the bay's windows: the tall round-headed one, a small square one above and one below the belt.
		_rect(x, top, 34, g - top - 6, "#" + Color(stone).darkened(0.08).to_html(false), _stroke("#6E6A64", 1))
		_rect(x, top, 8, g - top - 6, "#FFFFFF", 'opacity="0.12"')
		var wx := x + bay / 2.0 - 30.0
		_round_window_stone(wx, 60.0, top + 120.0, base - 80.0, trim)
		_square_window(wx + 14.0, top + 36.0, 32.0, trim)
		_square_window(wx + 14.0, base + 20.0, 32.0, trim)
		x += bay
	# The basement doors: red, in pairs, at the top of a few steps with black rails (`doors`: their x).
	split = out.size()
	for dx: float in k.get("doors", []):
		for side: float in [-1.0, 1.0]:
			_rect(dx + side * 30.0 - 24.0, base - 6.0, 48, 94, "#A8302A", _stroke("#5E1A16", 2))
			_rect(dx + side * 30.0 - 18.0, base + 4.0, 36, 30, "#C84A40", 'opacity="0.5"')
		_rect(dx - 64, base - 12, 128, 8, trim)
		for st in 3:
			_rect(dx - 70 - st * 10.0, base + 88.0 + st * 10.0, 140 + st * 20.0, 10, "#8E8A82", _stroke("#6E6A64", 1))
		for side: float in [-1.0, 1.0]:
			_path("M%s %s L%s %s" % [_n(dx + side * 74.0), _n(base + 40), _n(dx + side * 96.0), _n(g - 6)], "none", _stroke("#1A1A1A", 3))
	for dx: float in k.get("hall_doors", []):
		_rect(dx - 26, base + 4.0, 52, g - base - 22, ["#C9B88E", "#A8302A"][int(dx) % 2], _stroke("#3A3A3A", 2))
		_rect(dx - 16, base + 14.0, 32, 30, "#E8E4DA", 'opacity="0.6"')
	if k.get("fence", "") == "iron":
		_iron_fence(X0, X1)


# A round-headed window in a pale stone surround, small panes.
func _round_window_stone(x: float, w: float, y0: float, y1: float, trim: String) -> void:
	var r := w / 2.0
	_path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x - 10), _n(y1 + 6), _n(y0 + r), _n(r + 10), _n(r + 10), _n(x + w + 10), _n(y0 + r), _n(y1 + 6)], trim, _stroke("#8A867E", 1.2))
	_path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % [_n(x), _n(y1), _n(y0 + r), _n(r), _n(r), _n(x + w), _n(y0 + r), _n(y1)], "url(#glass)")
	_rect(x + w / 2.0 - 1.5, y0 + 6, 3, y1 - y0 - 6, "#E8E4DA")
	var py := y0 + r + 30.0
	while py < y1:
		_rect(x, py, w, 2.5, "#E8E4DA")
		py += 36.0
	_rect(x - 12, y1 + 4, w + 24, 8, trim, _stroke("#8A867E", 1))
	_snow(x - 12, w + 24, y1 + 4)


func _square_window(x: float, y: float, w: float, trim: String) -> void:
	_rect(x - 6, y - 6, w + 12, w + 12, trim, _stroke("#8A867E", 1))
	_rect(x, y, w, w, "url(#glass)")


# The modern apartment block (5462…, 5470…, 5486…, 5498…, 5502…): set back behind a planted court with a path and benches,
# volumes of pale and dark grey metal panels side by side, balconies with metal rails stacked up the pale ones, an entrance
# under a canopy.
func _apartments() -> void:
	var g := ground_y
	var court := g - 130.0
	var top := g - 820.0
	_back_row(X0, X1, g - 860.0, court)
	var vols: Array = k.get("volumes", [[X0, 420.0, "#C9CCCE"], [450.0, 300.0, "#5E6266"], [750.0, 420.0, "#C9CCCE"]])
	for v: Array in vols:
		var vx: float = v[0]
		var vw: float = v[1]
		var col: String = v[2]
		var vt := top + (40.0 if col == "#5E6266" else 0.0)
		_rect(vx, vt, vw, court - vt, col, _stroke("#3A3E42", 1.5))
		var px := vx + 6.0
		while px < vx + vw - 4.0:
			_rect(px, vt, 2, court - vt, "#000000", 'opacity="0.08"')
			px += 36.0
		var f := 0
		var fy := vt + 40.0
		while fy < court - 120.0:
			var wx := vx + 30.0
			while wx < vx + vw - 90.0:
				_rect(wx, fy, 70, 90, "#2B3036")
				_rect(wx + 4, fy + 4, 62, 82, "url(#glass)")
				wx += 110.0
			if col != "#5E6266":
				# A balcony on each floor of the pale volumes.
				_rect(vx + vw - 150.0, fy + 92.0, 140, 10, "#8E9296")
				var bx := vx + vw - 146.0
				while bx < vx + vw - 12.0:
					_rect(bx, fy + 56.0, 2, 36, "#3A3E42")
					bx += 10.0
				_rect(vx + vw - 150.0, fy + 54.0, 140, 3, "#3A3E42")
			fy += 130.0
			f += 1
		_snow(vx, vw, vt - 4.0)
	split = out.size()
	# The entrance under its canopy, then the court: lawn, a path, low shrubs, two benches.
	var ex: float = k.get("entrance", 560.0)
	_rect(ex - 70, court - 150, 140, 150, "#2B3036")
	_rect(ex - 62, court - 142, 124, 142, "url(#glass)")
	_rect(ex - 100, court - 170, 200, 18, "#5E6266", _stroke("#2B3036", 1.5))
	_lawn(X0, X1, court)
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(ex - 50), _n(court), _n(ex + 50), _n(court), _n(ex + 90), _n(g), _n(ex - 90), _n(g)], "#B9B4AA")
	var sx := X0 + 30.0
	while sx < X1 - 20.0:
		if absf(sx - ex) > 120.0:
			_shrub(sx, 24.0 + rng.randf_range(0.0, 8.0), "#3E6A3A")
		sx += 70.0
	for bx: float in [ex - 200.0, ex + 160.0]:
		_rect(bx, g - 60, 60, 8, "#8A6A4A")
		_rect(bx + 4, g - 52, 4, 20, "#3A3A3A")
		_rect(bx + 52, g - 52, 4, 20, "#3A3A3A")


# The school's gym on 6e (5522…, 5524…, 5534…, 5544…): a long low wall of orange-brown brick with a beige band, tall slit windows,
# and the entrance in a beige stone block with dark glass doors under a small canopy (`entrance`).
func _gym() -> void:
	var g := ground_y
	var top := g - 430.0
	_bricks(top, g - 6.0)
	_wall_shading(top)
	_rect(X0 - 4, top - 14, X1 - X0 + 8, 16, "#B9A88E", _stroke("#8E7E66", 1))
	_snow(X0 - 4, X1 - X0 + 8, top - 14)
	_rect(X0, g - 150, X1 - X0, 16, "#D8C8A8")
	var ex: float = k.get("entrance", -1.0)
	var x := X0 + 60.0
	while x < X1 - 40.0:
		if ex < 0.0 or absf(x - ex) > 160.0:
			_rect(x, top + 60, 18, 160, "#2B2E32")
			_rect(x + 3, top + 63, 12, 154, "url(#glass)")
		x += 150.0
	split = out.size()
	if ex > 0.0:
		_rect(ex - 120, top - 30, 240, g - top + 24, "#D8CCB4", _stroke("#A89A80", 1.5))
		_rect(ex - 80, top + 40, 40, 90, "#2B2E32")
		_rect(ex + 40, top + 40, 40, 90, "#2B2E32")
		_rect(ex - 70, g - 200, 140, 194, "#1E2226")
		_rect(ex - 64, g - 194, 62, 182, "url(#glass)")
		_rect(ex + 2, g - 194, 62, 182, "url(#glass)")
		_rect(ex - 90, g - 222, 180, 14, "#3A3A3A")


# ── What every lane entrance seen from the street gets ───────────────────────
# Three layers over the entrance's own art, so both lanes (`_ruelle_verte`, `_ruelle`) read as a real lane: the ground
# (its crack of weeds, patches, tyre tracks), the walls (windows, creeper, the sun on the left wall and the
# shade on the right) and the air (wires and a clothesline across the gap). Their own RNG, and the same draws in every
# season, so adding them doesn't move anything else.

func _lane_at(vp: Vector2, p: Vector2, d: float) -> Vector2:
	return vp + (p - vp) * (1.0 - d)


# Weeds, patches and tyre tracks on the concrete; snow instead in winter. Drawn right after the ground.
func _lane_ground_detail(vp: Vector2, far: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 9241
	var snowy := season == "winter"
	# Two tyre tracks worn down the lane.
	for side in [-1.0, 1.0]:
		var pts := PackedStringArray()
		for i in 9:
			var d := far * i / 8.0
			var p := _lane_at(vp, Vector2(vp.x + side * (X1 - X0) * 0.19, ground_y), d)
			pts.append("%s%s %s" % ["M" if i == 0 else "L", _n(p.x), _n(p.y)])
		_path(" ".join(pts), "none", _stroke("#E6E9EC" if snowy else "#9A968E", 7) + ' opacity="0.45" stroke-linecap="round"')
	# The crack down the middle, wandering, with its seam of weeds.
	var crack := PackedStringArray()
	var weeds: Array[Vector2] = []
	for i in 11:
		var d := far * i / 10.0
		var p := _lane_at(vp, Vector2(vp.x + r.randf_range(-26.0, 26.0) * (1.0 - d), ground_y), d)
		crack.append("%s%s %s" % ["M" if i == 0 else "L", _n(p.x), _n(p.y)])
		if i % 2 == 1:
			weeds.append(p)
	_path(" ".join(crack), "none", _stroke("#7E7A72", 2.2) + ' opacity="0.8"')
	if not snowy:
		for w in weeds:
			var h: float = r.randf_range(8.0, 16.0) * (1.0 - (w.y - vp.y) / maxf(ground_y - vp.y, 1.0) * 0.0 + 0.0)
			var scale: float = clampf((w.y - vp.y) / maxf(ground_y - vp.y, 1.0), 0.2, 1.0)
			for b in 5:
				var a := lerpf(-2.5, -0.6, b / 4.0) + r.randf_range(-0.2, 0.2)
				_path("M%s %s q%s %s %s %s" % [_n(w.x), _n(w.y), _n(cos(a) * h * 0.3 * scale), _n(sin(a) * h * scale), _n(cos(a) * h * 0.8 * scale), _n(sin(a) * h * 0.8 * scale)],
					"none", _stroke(_bush("#6E8A3A"), maxf(1.8 * scale, 0.7)) + ' stroke-linecap="round"')
	# Worn patches of old asphalt (no puddle: Julien).
	for i in 5:
		var d := r.randf_range(0.05, far * 0.9)
		var p := _lane_at(vp, Vector2(lerpf(X0 + 20.0, X1 - 20.0, r.randf()), ground_y), d)
		var rx: float = r.randf_range(22.0, 48.0) * (1.0 - d)
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.5"/>' % [_n(p.x), _n(p.y), _n(rx), _n(rx * 0.26), "#EFF2F4" if snowy else "#9C978D"])


# Windows up the side walls, creeper over them, and the light: the left wall catches the low sun, the right one is in shade
# and throws it across the lane. `free_left` / `free_right`: the nearest depth where a window may go on that wall.
func _lane_wall_detail(vp: Vector2, far: float, free_left := 0.08, free_right := 0.08) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4517
	var quad := func(a: Vector2, b: Vector2, c: Vector2, d: Vector2, fill: String, extra := "") -> void:
		_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(a.x), _n(a.y), _n(b.x), _n(b.y), _n(c.x), _n(c.y), _n(d.x), _n(d.y)], fill, extra)
	for side in [[X0, free_left], [X1, free_right]]:
		var x: float = side[0]
		var d0: float = side[1]
		for i in 3:
			var near: float = d0 + i * 0.145
			var deep: float = near + 0.085
			if deep > far - 0.04:
				break
			for row in 2:
				var top := 168.0 + row * 152.0
				var bot := top + 104.0
				var a := _lane_at(vp, Vector2(x, top), near)
				var b := _lane_at(vp, Vector2(x, top), deep)
				var c := _lane_at(vp, Vector2(x, bot), deep)
				var e := _lane_at(vp, Vector2(x, bot), near)
				quad.call(a, b, c, e, "#2E2A26")
				var inset := 0.1
				quad.call(a.lerp(c, inset), b.lerp(e, inset), c.lerp(a, inset), e.lerp(b, inset),
					"#C3D2D8" if r.randf() < 0.6 else "#F2D79A")
				# A pale sill under it.
				var s0 := _lane_at(vp, Vector2(x, bot + 6.0), near)
				var s1 := _lane_at(vp, Vector2(x, bot + 6.0), deep)
				_path("M%s %s L%s %s" % [_n(s0.x), _n(s0.y), _n(s1.x), _n(s1.y)], "none", _stroke("#D9D4C8", 4) + ' opacity="0.9"')
	# Virginia creeper spilling down the right wall, bare stems in winter.
	var colors := {"spring": ["#8FBF5A", "#A8CE6E", "#6E9E44"], "summer": ["#3E8E3A", "#4FA34A", "#2F7A30"],
		"autumn": ["#C8402E", "#D9682B", "#9E2F26"], "winter": []}[season] as Array
	for i in 26:
		var d: float = r.randf_range(0.04, minf(far - 0.06, 0.5))
		var y: float = r.randf_range(150.0, 470.0)
		var p := _lane_at(vp, Vector2(X1, y), d)
		var s: float = 1.0 - d
		_path("M%s %s q%s %s %s %s" % [_n(p.x), _n(p.y), _n(-6.0 * s), _n(16.0 * s), _n(-2.0 * s), _n(34.0 * s)], "none", _stroke("#6E5A3A", maxf(1.6 * s, 0.6)))
		if colors.is_empty():
			continue
		for n in 4:
			var lp := p + Vector2(r.randf_range(-10.0, 4.0), r.randf_range(0.0, 32.0)) * s
			_circle(lp.x, lp.y, maxf(r.randf_range(4.0, 7.5) * s, 1.0), colors[n % colors.size()])
	# The sun down the left wall, the shade on the right one and on the ground under it.
	var lit := [_lane_at(vp, Vector2(X0, 60.0), 0.0), _lane_at(vp, Vector2(X0, 60.0), far), _lane_at(vp, Vector2(X0, ground_y), far), _lane_at(vp, Vector2(X0, ground_y), 0.0)]
	quad.call(lit[0], lit[1], lit[2], lit[3], "#FFF2CE", 'opacity="0.14"')
	var shade := [_lane_at(vp, Vector2(X1, 0.0), 0.0), _lane_at(vp, Vector2(X1, 0.0), far), _lane_at(vp, Vector2(X1, ground_y), far), _lane_at(vp, Vector2(X1, ground_y), 0.0)]
	quad.call(shade[0], shade[1], shade[2], shade[3], "#2A2630", 'opacity="0.16"')
	var g0 := _lane_at(vp, Vector2(X1, ground_y), 0.0)
	var g1 := _lane_at(vp, Vector2(X1, ground_y), far)
	var g2 := _lane_at(vp, Vector2(lerpf(X0, X1, 0.52), ground_y), far)
	var g3 := _lane_at(vp, Vector2(lerpf(X0, X1, 0.3), ground_y), 0.0)
	quad.call(g0, g1, g2, g3, "#3A3340", 'opacity="0.13"')


# Wires from wall to wall, and the neighbours' clothesline with its washing. Drawn last, over everything but the tree.
func _lane_air_detail(vp: Vector2, far: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 6803
	for d in [0.12, 0.34, 0.54]:
		if d > far - 0.05:
			continue
		var a := _lane_at(vp, Vector2(X0, 150.0 + r.randf_range(-20.0, 20.0)), d)
		var b := _lane_at(vp, Vector2(X1, 160.0 + r.randf_range(-20.0, 20.0)), d)
		var sag: float = 26.0 * (1.0 - d)
		_path("M%s %s Q%s %s %s %s" % [_n(a.x), _n(a.y), _n((a.x + b.x) / 2.0), _n((a.y + b.y) / 2.0 + sag), _n(b.x), _n(b.y)], "none", _stroke("#2B2B2B", maxf(2.2 * (1.0 - d), 0.8)))
	# The clothesline: a line on its pulleys with a few things pegged to it, nearer the camera.
	var d := 0.23
	var la := _lane_at(vp, Vector2(X0 + 10.0, 300.0), d)
	var lb := _lane_at(vp, Vector2(X1 - 10.0, 316.0), d)
	var sag := 18.0 * (1.0 - d)
	_path("M%s %s Q%s %s %s %s" % [_n(la.x), _n(la.y), _n((la.x + lb.x) / 2.0), _n((la.y + lb.y) / 2.0 + sag), _n(lb.x), _n(lb.y)], "none", _stroke("#D9D4C8", maxf(1.8 * (1.0 - d), 0.7)))
	# Nobody hangs the washing out in January: the line stays bare (the same random draws all the same).
	var wash := ["#E8E4DA", "#7FB4D9", "#E07A9A", "#F2D79A", "#9BD16A"]
	for i in 5:
		var t := 0.18 + i * 0.16
		var on := la.lerp(lb, t) + Vector2(0.0, sag * 2.0 * t * (1.0 - t) * 2.0)
		var w: float = r.randf_range(13.0, 20.0) * (1.0 - d)
		var h: float = r.randf_range(20.0, 32.0) * (1.0 - d)
		if season == "winter":
			continue
		_path("M%s %s h%s l%s %s q%s %s %s 0 l%s %s z" % [_n(on.x - w / 2.0), _n(on.y), _n(w), _n(w * 0.12), _n(h), _n(-w * 0.6), _n(5.0 * (1.0 - d)), _n(-w * 1.24), _n(w * 0.12), _n(-h)],
			wash[i % wash.size()], _stroke("#B9B4AA", 1) + ' opacity="0.95"')


# ── Shop windows: what you see through the glass ────────────────────────────
# A dépanneur's window is never a dark pane: the shop is lit inside, there are shelves of tins and bottles against the glass,
# a poster or two taped up, and the street reflected over the lot. `_shop_glass_inside` goes on right after the pane is drawn,
# `_shop_glass_shine` last of all, over whatever the storefront put in the window. Own RNG: the rest of the street is unmoved.

const SHOP_GOODS := ["#E8542F", "#F2C230", "#3D7FD0", "#4E8A5A", "#E07A9A", "#F4F1EA", "#9C6CC4", "#E8812E"]


# The shop's own light behind the glass, warm, strongest low down where the lamps are.
func _shop_glass_glow(x: float, y: float, w: float, h: float, seed_value: int) -> void:
	var gid := "shoplit%d" % seed_value
	out.append('<defs><linearGradient id="%s" x1="0" y1="0" x2="0" y2="1">' % gid
		+ '<stop offset="0" stop-color="#FFE7B4" stop-opacity="0.12"/><stop offset="0.55" stop-color="#FFD98E" stop-opacity="0.3"/>'
		+ '<stop offset="1" stop-color="#FFC66A" stop-opacity="0.5"/></linearGradient></defs>')
	_rect(x, y, w, h, "url(#%s)" % gid)


# Shelves of tins, bottles and boxes against the glass, and a poster taped up, inside the given part of the pane.
func _shop_glass_goods(x: float, y: float, w: float, h: float, seed_value: int, rows := 0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	if rows <= 0:
		rows = 3 if h > 120.0 else 2
	for row in rows:
		var sy: float = y + h * (0.3 + row * 0.26)
		if sy > y + h - 14.0:
			break
		var dim: float = 0.9 - row * 0.12
		var gx: float = x + 6.0
		while gx < x + w - 12.0:
			var kind := r.randi() % 3
			var col: String = SHOP_GOODS[r.randi() % SHOP_GOODS.size()]
			match kind:
				0:
					# A tin, with its band.
					_rect(gx, sy - 13, 8, 13, col, 'opacity="%s" rx="1.5"' % _n(dim))
					_rect(gx, sy - 9, 8, 4, "#F4F1EA", 'opacity="%s"' % _n(dim * 0.8))
					gx += 10.0
				1:
					# A bottle: a body and a neck.
					_rect(gx + 1, sy - 15, 7, 15, col, 'opacity="%s" rx="2"' % _n(dim))
					_rect(gx + 3, sy - 20, 3, 6, col, 'opacity="%s"' % _n(dim * 0.9))
					gx += 10.0
				_:
					# A box.
					_rect(gx, sy - 11, 13, 11, col, 'opacity="%s"' % _n(dim))
					_rect(gx + 2, sy - 8, 9, 3, "#F4F1EA", 'opacity="%s"' % _n(dim * 0.7))
					gx += 15.0
		_rect(x + 3, sy, w - 6, 2.5, "#8E8278", 'opacity="%s"' % _n(dim * 0.8))
	# A poster taped to the inside of the glass, its corner turned.
	var pw: float = minf(w * 0.42, 54.0)
	var px: float = x + r.randf_range(6.0, maxf(w - pw - 6.0, 7.0))
	var py: float = y + h * 0.1
	_rect(px, py, pw, pw * 0.8, "#F7F3E8", _stroke("#C9C3B8", 1) + ' opacity="0.92"')
	_rect(px + 4, py + 5, pw - 8, pw * 0.22, SHOP_GOODS[r.randi() % SHOP_GOODS.size()], 'opacity="0.9"')
	for i in 2:
		_rect(px + 6, py + pw * 0.4 + i * 7.0, pw - 16, 3, "#B9B2A4", 'opacity="0.8"')


func _shop_glass_shine(x: float, y: float, w: float, h: float) -> void:
	# The street in the glass: two broad diagonal streaks, and the sky caught along the top.
	var d := minf(w, h)
	_path("M%s %s l%s %s l%s 0 l%s %s Z" % [_n(x + w * 0.1), _n(y + h), _n(d * 0.75), _n(-h), _n(d * 0.3), _n(-d * 0.75), _n(h)],
		"#FFFFFF", 'opacity="0.12"')
	_path("M%s %s l%s %s l%s 0 l%s %s Z" % [_n(x + w * 0.56), _n(y + h), _n(d * 0.75), _n(-h), _n(d * 0.14), _n(-d * 0.75), _n(h)],
		"#FFFFFF", 'opacity="0.08"')
	_rect(x, y, w, h * 0.18, "#CFE0EC", 'opacity="0.18"')


# One leaf of a garden plant, the same shape as the trees' and the lanes': a narrow base, widest low down, a drawn-out tip.
# `turn` in degrees, 0 = pointing up.
const PLANT_LEAF := [Vector2(0, 0.16), Vector2(-0.28, -0.02), Vector2(-0.52, -0.38), Vector2(-0.40, -0.76), Vector2(-0.14, -1.08),
	Vector2(0, -1.3), Vector2(0.16, -1.06), Vector2(0.41, -0.74), Vector2(0.52, -0.37), Vector2(0.29, -0.02)]


func _plant_leaf(p: Vector2, size: float, turn: float, color: String) -> void:
	var a := deg_to_rad(turn)
	var c := cos(a) * size
	var sn := sin(a) * size
	var d := ""
	for i in PLANT_LEAF.size():
		var q: Vector2 = PLANT_LEAF[i]
		d += "%s%s %s" % ["M" if i == 0 else "L", _n(p.x + q.x * c - q.y * sn), _n(p.y + q.x * sn + q.y * c)]
	_path(d + " Z", color)


# A shrub in a front garden: a dark mass, leaves all over it turned outward and lit from the upper left, a few sprigs standing
# proud of it. In winter the leaves are gone: bare twigs under a cap of snow. The same random draws in every season.
func _shrub(x: float, r: float, c: String) -> void:
	var winter := season == "winter"
	var base := Vector2(x, ground_y - r * 0.7)
	if not winter:
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#000000" opacity="0.15"/>' % [_n(x + 3), _n(base.y + 4), _n(r), _n(r * 0.92)])
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#%s"/>' % [_n(x), _n(base.y), _n(r * 0.92), _n(r * 0.86), Color(c).darkened(0.32).to_html(false)])
	var leaves := int(r * 1.8)
	for i in leaves:
		var a := rng.randf_range(0.0, TAU)
		var d := sqrt(rng.randf()) * r
		var p := base + Vector2(cos(a) * d, sin(a) * d * 0.9)
		var jitter := rng.randf_range(-22.0, 22.0)
		var pale := rng.randf() < 0.3
		if p.y > ground_y - 2.0:
			continue
		if winter:
			# A bare twig instead of the leaf.
			if i % 3 == 0:
				_path("M%s %s L%s %s" % [_n(base.x), _n(ground_y - 2), _n(p.x), _n(p.y)], "none", _stroke("#7A6450", 1.2) + ' opacity="0.8"')
			continue
		var lit := (base.x - p.x + base.y - p.y) / (r * 2.0)
		var tone := Color(c).lightened(clampf(lit, 0.0, 1.0) * 0.34) if lit > 0.0 else Color(c).darkened(clampf(-lit, 0.0, 1.0) * 0.28)
		if pale:
			tone = tone.lightened(0.12)
		_plant_leaf(p, r * 0.42, rad_to_deg((p - base).angle() + PI / 2.0) + jitter, "#" + tone.to_html(false))
	if winter:
		out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#F7F9FB"/>' % [_n(x), _n(ground_y - r * 1.05), _n(r * 0.9), _n(r * 0.45)])


# A little flower: five petals round a heart.
func _bloom(x: float, y: float, r: float, color: String) -> void:
	for i in 5:
		var a := TAU * i / 5.0 - PI / 2.0
		_circle(x + cos(a) * r * 0.7, y + sin(a) * r * 0.7, r * 0.52, color)
	_circle(x, y, r * 0.4, "#F2C230" if color != "#FFD23F" else "#E8812E")
