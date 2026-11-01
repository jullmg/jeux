extends SceneTree
# Regenerates art/decor/*.svg: Godot --headless --path . --script res://tools/generate_houses.gd
# Autumn (Halloween) facades go in art/decor/, the other seasons in art/decor/<season>/ (see Season.decor).
# Every season makes the same random draws in the same order, so only the seasonal decor differs.
# Also writes art/decor/windows.json: each house's window panes, used by the game to put cats in windows.

const X0 := 30.0
const FLOOR_H := 275.0
const PORCH_FLOOR := 600.0
const BASE := 614.0
const GROUND := 700.0
const RAIL_H := 48.0
const VARIANTS := 26

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
		"bricks": ["#A8473A", "#9A3F33", "#B4513F", "#8E3A2F", "#B85C48"], "mortar": "#CDBFB0",
		"lintel": "#BEB8AC", "lintel_dark": "#8A8478", "lintel_style": "fleur",
		"top": 40.0, "parapet": "flat", "crest": true, "number": "5672",
		"door": "#C0702F", "door_dark": "#7E4520", "awning": "#7C8186", "columns": true,
		"windows": [[70.0, 110.0], [470.0, 110.0]], "door_cx": 278.0,
		"balcony": [135.0, 420.0], "porch": [135.0, 420.0],
		"stair": [Vector2(452, 336), Vector2(600, 380), Vector2(690, 520), Vector2(620, 696)],
		"fence": "black", "basement": [480.0],
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
		# (reference/coin_dépanneur_sur_6eme_coin_dandurand.jpg).
		"name": "depanneur", "kind": "depanneur_side", "width": 640.0, "halloween": false,
		"bricks": ["#6E3A2E", "#7A4234", "#5E3029", "#844A3A", "#4E2A28", "#8C5440"], "mortar": "#B9AEA2",
		"cornice": "#3F4448", "cornice_dark": "#2A2E31", "basement": [], "metal": "#1F1F1F",
	},
	{
		# Between the dépanneur and the green lane (reference/entre_entrée_ruelle_et_coin_dandurand.jpg).
		"name": "garages", "kind": "garages", "width": 780.0, "halloween": false,
		"bricks": ["#6B3A2E", "#7A4636", "#5A3028", "#86503E", "#4A2A26", "#93604A"], "mortar": "#B5AA9E",
		"trim": "#F2F0EA", "trim_dark": "#A9A398", "basement": [], "metal": "#1F1F1F",
	},
	{
		"name": "coin_holt", "kind": "side_wall", "width": 460.0,
		"bricks": ["#B5603F", "#A85536", "#C26B48", "#9C4D31", "#C77650"], "mortar": "#D6C9B9",
		"parapet": "flat", "windows": [[90.0, 90.0], [280.0, 90.0]], "basement": [], "downspout": 410.0,
	},
	{"name": "ruelle", "kind": "ruelle", "width": 300.0},
	# The green lane near the Dandurand corner (reference/Entrée_ruelle_coin_dandurand.jpg).
	{"name": "ruelle_verte", "kind": "ruelle_verte", "width": 400.0},
	# Dépanneur Xin-Xin's real front, on Rue Dandurand (reference/dépanneur_on_dandurant.jpg).
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
		"name": "ecole", "kind": "school", "width": 1400.0, "floors": 3, "top": 40.0,
		"bricks": ["#A9472F", "#9C4029", "#B44F35", "#943B26", "#B85A3E"], "mortar": "#C9B7A4",
		"trim": "#ECE8E0", "trim_dark": "#A9A398", "lintel": "#D8CFC0", "lintel_dark": "#A39A8A",
		"basement": [120.0, 420.0, 720.0], "fence": "black", "halloween": false,
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
var season := "autumn"


func _init() -> void:
	var configs: Array = HOUSES.duplicate()
	for i in VARIANTS:
		configs.append(_variant(i))
	for s in ["autumn", "spring", "summer", "winter"]:
		season = s
		if s != "autumn":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/decor/" + s))
		_generate(configs)
	FileAccess.open("res://art/decor/windows.json", FileAccess.WRITE).store_string(JSON.stringify(windows, "\t"))
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
		out = PackedStringArray()
		_svg()
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
		"garages":
			_garages()
		"modern":
			_modern()
		"school":
			_school()
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
	if k.downspout >= 0.0:
		_downspout(k.downspout, top)
	if k.parapet == "flat":
		_flat_parapet(top)
	else:
		_cornice(top)
	if k.crest:
		_crest(k.door_cx, top + 6.0)
	var first_floor := 1 if k.kind == "shop" else 0
	for f in range(first_floor, floors):
		for w in k.windows:
			_window(w[0], _win_y(f), w[1], 160.0)
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
	for f in floors:
		_door(cx, _door_top(f), _fb(f))
	if k.number != "":
		_plaque(cx, _door_top(0) + 14.0, k.number)
	var b: Array = k.balcony
	if k.awning != "":
		_awning(b[0], b[1], _door_top(floors - 1) - 26.0, _fb(floors - 1) - RAIL_H)
	for f in range(floors - 1, 0, -1):
		_rect(b[0], _fb(f) + 16, b[1] - b[0], 14, "#000000", 'opacity="0.15"')
		if k.columns:
			_column(b[0] + 4, 1.0, _fb(f) + 16, _fb(f - 1))
			_column(b[1] - 11, -1.0, _fb(f) + 16, _fb(f - 1))
		_balcony(b[0], b[1], _fb(f), [])
	var p: Array = k.porch
	if k.halloween:
		_cobweb(p[0] + 4.0, _fb(1) + 16.0, 1.0)
		_cobweb(p[1] - 4.0, _fb(1) + 16.0, -1.0)
		for gx in [b[0] + 30.0, b[1] - 40.0]:
			if rng.randf() < 0.6:
				_ghost(gx, _fb(1) + 30.0)
		_string_lights(b[0], b[1], _fb(1) - RAIL_H)
	_balcony(p[0], p[1], _fb(0), [[cx - 54, cx + 54]])
	_front_steps(cx)
	if k.halloween:
		_pumpkin(cx - 76, base_y + 2.0, 1.0, true)
		_pumpkin(cx + 78, base_y + 2.0, 0.75, rng.randf() < 0.5)
		_mums(cx + 96, ground_y)
	var s: Array = k.stair
	var p3 := Vector2(s[3].x, s[3].y + oy)
	_stairs(Vector2(s[0].x, _fb(1) + 6.0), s[1] + Vector2(0, oy), s[2] + Vector2(0, oy), p3)
	var gaps := [[cx - 66, cx + 66], [p3.x - 42, p3.x + 42]]
	gaps.sort_custom(func(a, c): return a[0] < c[0])
	_garden(gaps)
	_fence(gaps)


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
	_rect(x - 3, y - 3, w + 6, h + 6, k.trim_dark)
	_rect(x, y, w, h, k.trim)
	var lit := rng.randf() < 0.22
	_rect(x + 8, y + 8, w - 16, h - 16, "url(#warm)" if lit else "url(#glass)")
	if season == "autumn":
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


func _plaque(cx: float, cy: float, text: String) -> void:
	var gw := 7.0
	var gh := 11.0
	var gap := 4.0
	var w := text.length() * gw + (text.length() - 1) * gap + 14.0
	_rect(cx - w / 2, cy - 11, w, 22, "#1E1E1E", 'rx="3" ' + _stroke("#555555", 1))
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
	var w := 96.0
	var x := cx - w / 2
	_rect(x - 14, top - 20, w + 28, 20, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(x - 7, top, w + 14, bottom - top, k.trim_dark)
	_rect(x - 4, top, w + 8, bottom - top, k.trim)
	_rect(x + 4, top + 5, w - 8, 18, "url(#glass)")
	var dy := top + 28
	var dh := bottom - dy
	var lw := (w - 8) / 2.0
	for i in 2:
		var lx := x + 4 + i * lw
		_rect(lx, dy, lw, dh, k.door, _stroke(k.door_dark, 2))
		_rect(lx + 7, dy + 9, lw - 14, dh * 0.58, "url(#glass)", _stroke(k.door_dark, 2))
		_rect(lx + 7, dy + dh * 0.58 + 18, lw - 14, dh * 0.42 - 28, "none", _stroke(k.door_dark, 2))
	_circle(cx - 6, dy + dh * 0.62, 3, "#E3C26A")
	_circle(cx + 6, dy + dh * 0.62, 3, "#E3C26A")
	for sx in [-1.0, 1.0]:
		_lantern(cx + sx * (w / 2 + 24), top + 34)
	if season == "winter":
		_wreath(cx, top + 60)


func _lantern(x: float, y: float) -> void:
	_circle(x, y + 8, 22, "url(#glow)")
	_rect(x - 1.5, y - 12, 3, 6, "#1E1E1E")
	_path("M%s %s h16 l-3 -6 h-10 z" % [_n(x - 8), _n(y - 2)], "#1E1E1E")
	_rect(x - 6, y - 2, 12, 18, "#FFE7A3", _stroke("#1E1E1E", 2))
	_rect(x - 7, y + 16, 14, 3, "#1E1E1E")


func _awning(x0: float, x1: float, y: float, post_bottom: float) -> void:
	var dark := "#" + Color(k.awning).darkened(0.3).to_html(false)
	_rect(x0 - 16, y + 22, x1 - x0 + 32, 12, "#000000", 'opacity="0.15"')
	for px in [x0 + 2, x1 - 9]:
		_rect(px, y + 20, 7, post_bottom - y - 20, k.metal, _metal_stroke())
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


func _stairs(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	var steps := 18
	var hw := 30.0
	var pts: Array[Vector2] = []
	for i in steps + 1:
		pts.append(p0.bezier_interpolate(p1, p2, p3, float(i) / steps))
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
	if k.halloween:
		for i in [7, 12, 16]:
			if rng.randf() < 0.7:
				_pumpkin(pts[i].x + rng.randf_range(-10.0, 10.0), pts[i].y - 3.0, rng.randf_range(0.55, 0.75), rng.randf() < 0.4)


func _garden(gaps: Array) -> void:
	for seg in _segments(X0, X1, gaps):
		var x: float = seg[0] + 14.0
		while x < seg[1] - 14.0:
			var r := rng.randf_range(12.0, 20.0)
			var c := _bush(_pick(AUTUMN_BUSHES))
			_circle(x + 3, ground_y - r * 0.7 + 3, r, "#000000", 'opacity="0.15"')
			_circle(x, ground_y - r * 0.7, r, c)
			_circle(x - r * 0.3, ground_y - r * 1.0, r * 0.5, "#" + Color(c).lightened(0.25).to_html(false), 'opacity="0.8"')
			if season == "winter":
				out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#F7F9FB"/>' % [_n(x), _n(ground_y - r * 1.25), _n(r * 0.9), _n(r * 0.45)])
			if rng.randf() < 0.3:
				var fx := x + rng.randf_range(-8.0, 8.0)
				var flower := _pick(["#FFD23F", "#FFFFFF", "#C084FC"])
				if season != "winter":
					_circle(fx, ground_y - r * 1.1, 3.5, flower)
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
	var light: bool = k.fence == "white"
	var col := "#F5F5F2" if light else "#1F1F1F"
	var st := _stroke("#9A9A96", 1) if light else ""
	var pitch := 13.0 if light else 9.0
	var pw := 5.0 if light else 2.5
	var top := ground_y - 50.0
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
	for w in k.windows:
		var wy := _win_y(1) + 10.0
		_rect(w[0] - 4, wy - 4, w[1] + 8, 128, "#5E5A54")
		_rect(w[0] + 3, wy + 3, w[1] - 6, 114, "url(#glass)")
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


# A big red-brick school (from reference/School_on_dandurand.jpg): a long wing of tall paired windows
# and, near the corner, a tall pavilion with a diamond lattice in the brick. Stone sills and bands,
# green copper cornices, a small cross on the parapet.
func _school() -> void:
	var top := _top()
	var pav := X1 - 400.0
	var copper := "#4E8C7A"
	var copper_dark := "#2F5E50"
	_bricks(top, base_y)
	_wall_shading(top)
	# Pavilion: a hair forward of the wing, with a raised brick diamond lattice.
	out.append('<clipPath id="pav"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>' % [_n(pav), _n(top - 30), _n(X1 - pav), _n(base_y - top - 90)])
	_rect(pav, top - 30, X1 - pav, 30, k.mortar)
	out.append('<g clip-path="url(#pav)">')
	var d := -600.0
	while d < 900.0:
		_path("M%s %s l700 700 M%s %s l-700 700" % [_n(pav + d), _n(top - 30), _n(pav + d + 700), _n(top - 30)], "none", _stroke("#C46A50", 5) + ' opacity="0.7"')
		d += 92.0
	out.append('</g>')
	_rect(pav - 6, top - 30, 6, base_y - top + 30, "#000000", 'opacity="0.18"')
	for x in [pav, X1 - 22.0]:
		_rect(x, top - 30, 22, base_y - top + 30, "#B85A3E")
	# Stone band under the lattice and the pavilion's side entrance.
	_rect(pav - 6, base_y - 120, X1 - pav + 12, 16, k.lintel, _stroke(k.lintel_dark, 1.5))
	var dx := pav + 150.0
	_rect(dx - 20, base_y - 104, 120, 104, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(dx, base_y - 92, 80, 92, "#A8382A", _stroke("#6E2018", 2))
	_rect(dx + 8, base_y - 84, 28, 40, "url(#glass)")
	_rect(dx + 44, base_y - 84, 28, 40, "url(#glass)")
	# Wing: three rows of tall paired windows between brick pilasters.
	var bay := 132.0
	var x := X0 + 40.0
	while x + 110.0 < pav - 20.0:
		_rect(x - 18, top, 10, base_y - top, "#000000", 'opacity="0.08"')
		for f in 3:
			var wy := _win_y(f) + 10.0
			for j in 2:
				_window(x + j * 56.0, wy, 50.0, 150.0)
		x += bay
	_rect(X0, base_y - 120, pav - X0, 14, k.lintel, _stroke(k.lintel_dark, 1.5))
	# Copper cornices, the wing's slightly lower than the pavilion's.
	for c in [[X0, pav, top + 10.0], [pav - 8, X1 + 4, top - 44.0]]:
		_rect(c[0], c[2], c[1] - c[0], 26, copper, _stroke(copper_dark, 2))
		_rect(c[0], c[2] + 26, c[1] - c[0], 8, copper_dark)
		_rect(c[0], c[2] + 34, c[1] - c[0], 30, "url(#drop)")
		var dt: float = c[0] + 6.0
		while dt < c[1] - 10.0:
			_rect(dt, c[2] + 6, 6, 14, copper_dark, 'opacity="0.5"')
			dt += 18.0
	# Raised parapet with a stone cartouche and a little cross, in the middle of the wing.
	var cx := (X0 + pav) / 2.0
	_rect(cx - 90, top - 36, 180, 46, "#B85A3E", _stroke("#7E3424", 1.5))
	_rect(cx - 96, top - 44, 192, 10, copper, _stroke(copper_dark, 1.5))
	_rect(cx - 34, top - 26, 68, 30, k.lintel, _stroke(k.lintel_dark, 1.5))
	_rect(cx - 5, top - 92, 10, 50, "#7FA89A", _stroke(copper_dark, 1.5))
	_rect(cx - 18, top - 78, 36, 9, "#7FA89A", _stroke(copper_dark, 1.5))
	_foundation()
	_fence([])


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


# Dépanneur Xin-Xin's side on 6e Avenue: dark variegated brick, quoins on the corner, a tall concrete base with
# a vent, one big shop window (security grid, ads) under a granite lintel, and the corner balcony with its
# green corrugated awning poking out from the Dandurand front.
func _depanneur_side() -> void:
	var top := _top()
	var concrete := base_y - 84.0
	_bricks(top, concrete)
	_wall_shading(top)
	_flat_parapet(top)
	_quoins(X0, 1.0, top + 4.0, concrete)
	# Concrete base, stained, with the basement vent.
	_rect(X0, concrete, X1 - X0, ground_y - concrete, "#A8A49D")
	_rect(X0, concrete, X1 - X0, 6, "#BDB9B1")
	for i in 6:
		_rect(rng.randf_range(X0, X1 - 60), rng.randf_range(concrete + 20, ground_y - 30), rng.randf_range(30, 90), rng.randf_range(8, 24), "#8E8A83", 'opacity="0.35"')
	var vx := X1 - 250.0
	_rect(vx, concrete + 58, 160, 78, "#5E5A55", _stroke("#77736C", 4))
	var gx := vx + 8.0
	while gx < vx + 154.0:
		_rect(gx, concrete + 64, 2, 66, "#2E2C2A")
		gx += 7.0
	var gy := concrete + 66.0
	while gy < concrete + 130.0:
		_rect(vx + 6, gy, 148, 2, "#2E2C2A")
		gy += 7.0
	# The shop window.
	var wx := 250.0
	var ww := 320.0
	var wy := 290.0
	var wh := concrete - 20.0 - wy
	_rect(wx - 24, wy - 40, ww + 48, 34, "#8E8B85", _stroke("#6E6B66", 1.5))
	for i in 40:
		_circle(rng.randf_range(wx - 20, wx + ww + 20), rng.randf_range(wy - 36, wy - 10), 1.4, _pick(["#5E5B56", "#B5B2AB"]))
	_rect(wx + ww / 2 - 30, wy - 48, 60, 46, "#9A9790", _stroke("#6E6B66", 1.5))
	_rect(wx - 6, wy - 6, ww + 12, wh + 12, "#F2F0EA", _stroke("#B9B5AC", 2))
	_rect(wx, wy, ww, wh, "#3E4A52")
	_rect(wx + 10, wy + 14, ww - 20, 4, "#F4F8FF", 'opacity="0.9"')
	# Security grid behind the glass, top two thirds.
	var lx := wx + 8.0
	while lx < wx + ww - 6:
		_rect(lx, wy + 30, 3, wh * 0.6, "#E9EEF2", 'opacity="0.8"')
		lx += 26.0
	var ly := wy + 30.0
	while ly < wy + 30 + wh * 0.6:
		_rect(wx + 6, ly, ww - 12, 3, "#E9EEF2", 'opacity="0.8"')
		ly += 26.0
	# Ads along the bottom: a peach one with a face, a yellow one, the orange-juice one; a blue sticker up top.
	var py := wy + wh * 0.58
	_rect(wx + 14, py - 30, 62, wh * 0.42 + 24, "#F2A27A", _stroke("#C46A44", 1.5))
	_circle(wx + 45, py + 4, 18, "#E8743A")
	_rect(wx + 84, py, 70, wh * 0.42 - 6, "#F2D23A")
	_rect(wx + 88, py + 8, 62, 6, "#2E8B47")
	_rect(wx + 160, py - 6, 150, wh * 0.42, "#F29B30")
	for o in [[190, 40], [222, 52], [256, 38], [286, 54]]:
		_circle(wx + o[0], py + o[1], 13, "#F57C1F", _stroke("#C45A12", 1.5))
	_rect(wx + 200, py + 4, 22, 30, "#F4E9C8")
	_rect(wx + ww - 70, wy + 30, 40, 26, "#2E6FD0")
	_rect(wx + ww / 2 - 3, wy, 6, wh, "#F2F0EA")
	_path("M%s %s l50 0 l-90 %s l-50 0 z" % [_n(wx + ww - 120), _n(wy), _n(wh)], "#FFFFFF", 'opacity="0.1"')
	_rect(wx - 16, wy + wh + 4, ww + 32, 14, "#B8B4AC", _stroke("#8E8A83", 1.5))
	# Upstairs the 6e side is plain brick: a soldier course under the roof, a downspout, the electric meter.
	_soldier_course(top + 2.0)
	_downspout(X1 - 12.0, top)
	var mx := 150.0
	_rect(mx, concrete - 150, 34, 46, "#B9BCB8", _stroke("#7E817E", 1.5))
	_circle(mx + 17, concrete - 132, 9, "#E9ECE6", _stroke("#7E817E", 1))
	_rect(mx + 14, concrete - 104, 5, 104, "#8E918E")
	_rect(mx + 14, top + 40, 5, concrete - 150 - top - 40, "#8E918E")
	# Corner balcony: white soffit, scrolled railing, posts, and the green corrugated awning.
	var by := _fb(1) + 10.0
	_rect(0, by, 170, 18, "#ECEAE4", _stroke("#B5B1A8", 1.5))
	_rect(0, by + 18, 170, 16, "url(#drop)")
	_scroll_railing(0, 166, by - 62, by)
	for px in [4.0, 160.0]:
		_rect(px, top + 30, 6, by - top - 30, "#1F1F1F")
	_path("M0 %s L190 %s L190 %s L0 %s Z" % [_n(top - 18), _n(top + 18), _n(top + 52), _n(top + 16)], "#3E8C5A", _stroke("#2A6340", 2))
	var rx := 6.0
	while rx < 190.0:
		_path("M%s %s l0 32" % [_n(rx), _n(top - 16 + rx * 36.0 / 190.0)], "none", _stroke("#2A6340", 2.5))
		rx += 11.0
	_path("M0 %s L190 %s" % [_n(top + 16), _n(top + 52)], "none", _stroke("#F2F0EA", 4))
	_rect(0, top + 52, 190, 20, "url(#drop)")


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
	_rect(X0 - 10, slab + 26, X1 - X0 + 20, 20, "url(#drop)")
	_snow(X0 + 4, X1 - X0 - 8, slab - 64)
	# Sign band: red banners either side of the blue shop sign (its text is a label in the game).
	var band := slab + 30.0
	_rect(X0 + 6, band, X1 - X0 - 12, 62, "#F4F2EC", _stroke("#B9B5AC", 1.5))
	for b in [[X0 + 14, 230.0], [X1 - 244, 230.0]]:
		_rect(b[0], band + 6, b[1], 50, "#C8202A", _stroke("#8E1A20", 1.5))
		_path("M%s %s q30 -14 60 0 t60 0 t60 0" % [_n(b[0] + 26), _n(band + 31)], "none", _stroke("#FFFFFF", 4) + ' stroke-linecap="round"')
		_rect(b[0] + 12, band + 12, 22, 38, "#F4F2EC", 'rx="4"')
	_rect(260, band + 4, 260, 54, "#25408F", _stroke("#16285C", 2))
	_rect(X0 + 10, band + 62, X1 - X0 - 20, 4, "#FFF8D6", 'opacity="0.9"')
	# Shop windows with their posters.
	var wy := band + 82.0
	var wb := _fb(0) - 6.0
	for win in [[X0 + 36, 250.0], [X1 - 286, 250.0]]:
		_rect(win[0] - 6, wy - 6, win[1] + 12, wb - wy + 12, "#F2F0EA", _stroke("#B9B5AC", 2))
		_rect(win[0], wy, win[1], wb - wy, "#3E4A52")
		var gx: float = win[0] + 10.0
		while gx < win[0] + win[1] - 6:
			_rect(gx, wy + 4, 2, wb - wy - 8, "#E9EEF2", 'opacity="0.5"')
			gx += 22.0
	var lx: float = X0 + 56.0
	_rect(lx, wy + 30, 200, wb - wy - 46, "#2E7D4F", _stroke("#1E5A38", 2))
	for bx in [lx + 40.0, lx + 70.0]:
		_rect(bx, wy + 60, 18, 70, "#3E9A5E", 'rx="6"')
		_rect(bx + 5, wy + 44, 8, 20, "#3E9A5E")
	for i in 3:
		_rect(lx + 110, wy + 60 + i * 16, 70, 6, "#F4F2EC")
	var rxw: float = X1 - 266.0
	_rect(rxw, wy + 20, 210, wb - wy - 40, "#F4F2EC", _stroke("#C9C2B4", 2))
	_rect(rxw + 10, wy + 30, 190, 30, "#C8202A")
	_rect(rxw + 20, wy + 80, 40, 80, "#E04F5F", 'rx="6"')
	_rect(rxw + 80, wy + 90, 70, 40, "#FFFFFF", _stroke("#2B2B2B", 1.5))
	_rect(rxw + 150, wy + 130, 50, 30, "#25408F")
	# Air conditioners over the door, the door behind its grille, the civic number.
	var dx := 390.0
	for ax in [dx - 74.0, dx + 6.0]:
		_rect(ax, wy - 6, 66, 40, "#F2F2EF", _stroke("#A9A398", 1.5))
		for gy in range(0, 4):
			_rect(ax + 6, wy + gy * 8, 54, 3, "#C9C5BC")
	_rect(dx - 60, wy + 40, 120, _fb(0) - wy - 40, "#F2F0EA", _stroke("#B9B5AC", 2))
	_rect(dx - 52, wy + 48, 104, _fb(0) - wy - 48, "#3E4A52")
	var gy2 := wy + 56.0
	while gy2 < _fb(0) - 6:
		_rect(dx - 48, gy2, 96, 2.5, "#E9EEF2")
		gy2 += 16.0
	var gx2 := dx - 46.0
	while gx2 < dx + 48:
		_rect(gx2, wy + 50, 2.5, _fb(0) - wy - 54, "#E9EEF2")
		gx2 += 16.0
	_rect(dx - 20, wy + 90, 40, 26, "#F4F2EC")
	_plaque(dx + 88, wy + 64, "2891")
	# Concrete steps with a handrail.
	for i in 3:
		var w := 150.0 + i * 20.0
		_rect(dx - w / 2, _fb(0) + i * 33.0, w, 33, "#A8A49C", _stroke("#7E7A72", 1.5))
		_rect(dx - w / 2, _fb(0) + i * 33.0, w, 4, "#C9C5BC")
		if season == "winter":
			_rect(dx - w / 2 + 6, _fb(0) + i * 33.0 - 2, w - 12, 5, "#F7F9FB")
	_path("M%s %s L%s %s" % [_n(dx + 50), _n(_fb(0) - 40), _n(dx + 96), _n(ground_y - 50)], "none", _stroke("#E8E4DA", 5) + ' stroke-linecap="round"')
	_rect(dx + 92, ground_y - 54, 5, 54, "#E8E4DA")
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
	# Bright far end: the lane goes on, greener and paler.
	poly.call([at.call(l0, far), at.call(r0, far), at.call(gr, far), at.call(gl, far)], "#DCE6D8")
	for i in 4:
		_circle(lerpf(at.call(gl, far).x, at.call(gr, far).x, (i + 0.5) / 4.0), at.call(gl, far).y - 30, 22, _pick(["#7FA34A", "#9DB85A", "#E3A33A"]))
	# Concrete path, darker at the entrance, with a joint across it.
	poly.call([gl, gr, at.call(gr, far), at.call(gl, far)], "#A8A49C")
	poly.call([gl, gr, at.call(gr, 0.25), at.call(gl, 0.25)], "#9A968E")
	_path("M%s %s L%s %s" % [_n(at.call(gl, 0.25).x), _n(at.call(gl, 0.25).y), _n(at.call(gr, 0.25).x), _n(at.call(gr, 0.25).y)], "none", _stroke("#7E7A72", 2))
	var mh: Vector2 = at.call(Vector2(vp.x, ground_y), 0.45)
	out.append('<ellipse cx="%s" cy="%s" rx="16" ry="5" fill="#6E6A62" stroke="#55524C" stroke-width="1.5"/>' % [_n(mh.x), _n(mh.y)])
	# Side walls.
	for side in [[l0, gl, "#7E4E3E", "#6A4033"], [r0, gr, "#93604A", "#7A4E3C"]]:
		poly.call([side[0], at.call(side[0], far), at.call(side[1], far), side[1]], side[2])
		for t in [0.3, 0.55, 0.8]:
			var y := lerpf(side[0].y, side[1].y, t)
			var a := Vector2(side[0].x, y)
			_path("M%s %s L%s %s" % [_n(a.x), _n(a.y), _n(at.call(a, far).x), _n(at.call(a, far).y)], "none", _stroke(side[3], 1.5))
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
	for i in 140:
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
	var px: float = k.width / 2.0 + 14.0
	_rect(px - 3, 440, 6, ground_y - 446, "#C8202A", _stroke("#8E1A20", 1))
	out.append('<ellipse cx="%s" cy="%s" rx="7" ry="2.5" fill="#000000" opacity="0.25"/>' % [_n(px + 2), _n(ground_y - 4)])
	_rect(px - 66, 384, 132, 64, "#2E8B47", 'rx="8" ' + _stroke("#F4F1EA", 4))
	_path("M%s 440 q-10 -14 0 -24 q10 10 0 24 z" % _n(px - 50), "#9BD16A")
	# Trees arching over the lane: dark branches, then the canopy.
	_path("M%s 420 C%s 300 %s 200 %s 120 M%s 330 C%s 290 %s 240 %s 200" % [_n(X1 - 10), _n(X1 - 40), _n(X1 - 110), _n(X0 + 40), _n(X1 - 30), _n(X1 - 80), _n(X1 - 120), _n(X1 - 170)], "none", _stroke("#4A3428", 6) + ' stroke-linecap="round"')
	for i in 16:
		var cx2 := rng.randf_range(X0 - 10, X1 + 10)
		var cy2 := rng.randf_range(40.0, 250.0) + (cx2 - X0) * 0.18
		_circle(cx2, cy2, rng.randf_range(34.0, 58.0), _canopy(_pick(["#E3A33A", "#D9682B", "#C9562E", "#B5442E", "#E8B54A"])), _stroke(_canopy("#8E3A24"), 1.5) + ' opacity="0.95"')


# Back lane seen from the street: lane trees, clothesline, wooden fences and greenery.
func _ruelle() -> void:
	var cx: float = k.width / 2.0
	var far := 560.0
	for i in 7:
		_circle(rng.randf_range(X0, X1), rng.randf_range(300.0, 430.0), rng.randf_range(45.0, 70.0),
			_canopy(_pick(["#E3A33A", "#D9682B", "#B5442E", "#C9B03A"])), _stroke(_canopy("#8E3A24"), 2))
	_path("M%s 380 Q%s 405 %s 380" % [_n(X0), _n(cx), _n(X1)], "none", _stroke("#555555", 1.5))
	var x := X0 + 26.0
	while x < X1 - 30.0:
		var t := (x - cx) / (cx - X0)
		var y := 380.0 + 12.5 * (1.0 - t * t)
		_rect(x, y, 18, rng.randf_range(20.0, 30.0), _pick(["#FF7BA3", "#FFD23F", "#4FA3E0", "#FFFFFF", "#9B59B6"]))
		x += 30.0
	_rect(X0, far - 70, X1 - X0, 70, "#A07850")
	var px := X0 + 10.0
	while px < X1:
		_path("M%s %s V%s" % [_n(px), _n(far - 70), _n(far)], "none", _stroke("#7E5C3A", 2))
		px += 12.0
	_rect(X0 + 16, far - 96, 86, 96, "#7A9A8A", _stroke("#55705F", 2))
	_path("M%s %s l43 -22 l43 22 z" % [_n(X0 + 16), _n(far - 96)], "#5E6B73", _stroke("#3F4A50", 2))
	_path("M%s %s L%s %s L%s %s L%s %s Z" % [_n(X0 + 6), _n(ground_y), _n(cx - 40), _n(far), _n(cx + 40), _n(far), _n(X1 - 6), _n(ground_y)], "#8E8C86")
	_path("M%s %s L%s %s" % [_n(cx), _n(ground_y), _n(cx), _n(far)], "none", _stroke("#7A7872", 3))
	for side in [-1.0, 1.0]:
		for j in 7:
			var t := j / 6.0
			var edge := X1 - 6.0 if side > 0.0 else X0 + 6.0
			var bx := lerpf(cx + side * 40.0, edge, t)
			_circle(bx + side * 6.0, lerpf(far, ground_y, t) - 6.0, 8.0 + 14.0 * t, _bush(_pick(AUTUMN_BUSHES)))


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
