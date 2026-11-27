class_name CraftArt
extends RefCounted
## What the craft studio (`ui/craft_studio.gd`) draws: the things she can make (`BASES`), the paper shapes she cuts out and
## the papers they are cut from, the decorations she glues on (googly eyes, pompoms, buttons, gems, felt, feathers…; the cute
## stickers are `StampArt`'s), her writing, and the necklace beads. Everything is drawn on any CanvasItem, in the studio's
## own units: the workbench is `WORK` px, light from the upper left like the rest of the game.
## **A new decoration = its id in a `DECO_GROUPS` list + a case in `deco`; a new shape = its id in `SHAPES` + a case in
## `shape_points`; a new thing to make = its entry in `BASES` + its cases in `base_rect`, `inside`, `draw_base`.**

const WORK := Vector2(560, 420)
const LINE := Color("#3A3A48")

## What she can make, in the order of the first card: id, name, what it is.
const BASE_ORDER := ["carte", "assiette", "pot", "cadre", "collier"]
const BASES := {
	"carte": ["Une carte", "Une carte à décorer, avec un mot à l'intérieur."],
	"assiette": ["Une assiette-visage", "Une assiette en carton : yeux, nez, cheveux de laine…"],
	"pot": ["Un pot à crayons", "Une vieille boîte de conserve toute belle."],
	"cadre": ["Un cadre", "Un cadre pour un de tes dessins."],
	"collier": ["Un collier", "Des pâtes et des perles sur une ficelle."],
	# Not on the garde's first card: her bedroom door, decorated from her desk (`house.gd _decorate_door`).
	"porte": ["La porte de ma chambre", "Ton nom, des autocollants, de la peinture… sur ta porte !"],
	# Her valentine (quest "valentin"), made at her desk and copied for each friend.
	"valentin": ["Un valentin", "Un cœur de papier sur un napperon de dentelle."],
}
## Her door on the bench: the corridor's door (150 × 430) at 0.96, so the picture goes back on it as it is.
const DOOR_RECT := Rect2(208, 4, 144, 412)
const DOOR_K := 144.0 / 150.0

const PALETTE := ["#E04F5F", "#FF8A3D", "#FFD23F", "#9BD84B", "#3E8E5A", "#2FB7B0", "#4FA3E0", "#1D4F91", "#7E57C2", "#FF7BA3",
	"#B5442E", "#8D6E63", "#F2C29A", "#FFFFFF", "#E8E8E8", "#2B2B2B", "#F7C7D2", "#BFE3F7", "#C9EDB3", "#FFE9A8"]

const SHAPES := ["cercle", "ovale", "carre", "rectangle", "triangle", "losange", "coeur", "etoile", "fleur", "nuage", "lune", "feuille",
	"goutte", "papillon", "bande", "vague", "maison"]
const PAPERS := [["uni", "Uni"], ["pois", "Pois"], ["rayures", "Rayures"], ["carreaux", "Carreaux"], ["zigzag", "Zigzag"],
	["paillettes", "Brillant"]]

## Decorations, in boxes: id, name. The stickers (`StampArt`) are a box of their own in the studio.
const DECO_GROUPS := [
	["visage", "Visages", [["yeux", "Yeux"], ["oeil", "Œil"], ["nez_rond", "Nez rond"], ["nez_pointe", "Nez pointu"], ["bouche", "Sourire"],
		["bouche_ouverte", "Bouche"], ["moustache", "Moustache"], ["joues", "Joues"], ["sourcils", "Sourcils"], ["lunettes", "Lunettes"]]],
	["pompons", "Pompons", [["pompon", "Pompon"], ["bouton", "Bouton"], ["bouton4", "Bouton"], ["perle", "Perle"], ["grelot", "Grelot"],
		["noeud", "Nœud"], ["spirale", "Ruban"]]],
	["brillants", "Brillants", [["gemme", "Diamant"], ["gemme_ronde", "Gemme"], ["scintille", "Scintille"], ["paillettes", "Paillettes"],
		["confettis", "Confettis"]]],
	["fete", "Fête", [["fanions", "Fanions"], ["accroche", "Accroche-porte"], ["arc_en_ciel", "Arc-en-ciel"], ["ampoules", "Lumières"]]],
	["nature", "Nature", [["plume", "Plume"], ["marguerite", "Marguerite"], ["tournesol", "Tournesol"], ["fleur_feutre", "Feutre"],
		["coeur_feutre", "Cœur"], ["etoile_feutre", "Étoile"], ["coquillage", "Coquillage"], ["feuillage", "Feuillage"]]],
]
## Beads for the necklace: id, name.
const BEADS := [["macaroni", "Macaroni"], ["penne", "Penne"], ["rigatoni", "Rigatoni"], ["roue", "Roue"], ["farfalle", "Papillon"],
	["ronde", "Perle"], ["cube", "Cube"], ["etoile", "Étoile"], ["coeur", "Cœur"], ["fleur", "Fleur"], ["bois", "Bois"]]

static var _half_cache := {}


# ── What she makes ──────────────────────────────────────────────

## Where the piece lies on the workbench (also what the picture of it is cut to).
static func base_rect(base: String) -> Rect2:
	match base:
		"carte":
			return Rect2(135, 15, 290, 390)
		"assiette":
			return Rect2(95, 25, 370, 370)
		"pot":
			return Rect2(150, 40, 260, 385)
		"cadre":
			return Rect2(60, 30, 440, 360)
		"porte":
			return DOOR_RECT
		"valentin":
			return Rect2(70, 12, 420, 396)
	return Rect2(40, 20, 480, 380)


## The window of the frame, where the picture shows.
const WINDOW := Rect2(130, 100, 300, 220)


## Can paint, glue or wool go here ? (`grow` widens the piece, to be generous at the edge.)
static func inside(base: String, p: Vector2, grow := 0.0) -> bool:
	match base:
		"carte":
			return Rect2(135, 15, 290, 390).grow(grow).has_point(p)
		"assiette":
			return p.distance_to(Vector2(280, 210)) <= 185.0 + grow
		"pot":
			var x := (p.x - 280.0) / 110.0
			if absf(x) > 1.0 + grow / 110.0:
				return false
			var top := 110.0 + 22.0 * sqrt(maxf(0.0, 1.0 - x * x))
			if p.y < top - grow:
				return false
			if p.y <= 395.0:
				return true
			return absf(p.y - 395.0) <= 22.0 * sqrt(maxf(0.0, 1.0 - x * x)) + grow
		"cadre":
			return Rect2(60, 30, 440, 360).grow(grow).has_point(p) and not WINDOW.grow(-grow).has_point(p)
		"porte":
			return DOOR_RECT.grow(grow).has_point(p)
		"valentin":
			return Geometry2D.is_point_in_polygon(HEART_C + (p - HEART_C) / (1.0 + grow / 170.0), heart_points())
	return true


## The piece before anything is on it. `picture` is the frame's drawing (null = a little scene of her own).
static func draw_base(ci: CanvasItem, base: String, face: int, picture: Texture2D) -> void:
	match base:
		"carte":
			var r := Rect2(135, 15, 290, 390)
			ci.draw_rect(Rect2(r.position + Vector2(5, 7), r.size), Color(0.3, 0.2, 0.1, 0.18))
			ci.draw_rect(r, Color("#FFFDF7"))
			for k in 18:
				ci.draw_line(Vector2(r.position.x + 8, r.position.y + 14 + k * 21), Vector2(r.end.x - 8, r.position.y + 14 + k * 21), Color(0.8, 0.75, 0.65, 0.12), 1.0)
			ci.draw_rect(r, Color("#C9BFA8"), false, 2.0)
			if face == 1:
				# Inside: the fold down the left and the faint lines to write on.
				ci.draw_line(r.position + Vector2(10, 0), r.position + Vector2(10, r.size.y), Color(0.7, 0.65, 0.55, 0.5), 2.0)
		"assiette":
			var c := Vector2(280, 210)
			var rim := PackedVector2Array()
			for k in 120:
				var a := TAU * k / 120.0
				rim.append(c + Vector2.from_angle(a) * (185.0 + 3.0 * sin(a * 40.0)))
			var shade := PackedVector2Array()
			for p: Vector2 in rim:
				shade.append(p + Vector2(5, 7))
			ci.draw_colored_polygon(shade, Color(0.3, 0.2, 0.1, 0.18))
			ci.draw_colored_polygon(rim, Color("#F6EEDF"))
			ci.draw_arc(c, 142.0, 0.0, TAU, 64, Color(0.7, 0.6, 0.45, 0.25), 3.0, true)
			ci.draw_arc(c, 170.0, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 2.0, true)
		"pot":
			# The pencils inside, then the tin.
			var top := Vector2(280, 110)
			_ellipse(ci, top, Vector2(110, 22), Color("#6B6F78"))
			var pencils := [[-60.0, -62.0, "#E04F5F"], [-25.0, -90.0, "#4FA3E0"], [12.0, -70.0, "#FFD23F"], [48.0, -96.0, "#7CCB5A"], [75.0, -58.0, "#FF8A3D"]]
			for pc: Array in pencils:
				var x: float = pc[0]
				var tipy: float = pc[1]
				var col := Color(pc[2])
				var base_pt := top + Vector2(x * 0.7, 6)
				var tip_pt := top + Vector2(x * 1.0 + 6.0 * sign(x), tipy - 20.0)
				var dir := (tip_pt - base_pt).normalized()
				var side := dir.orthogonal() * 7.0
				ci.draw_colored_polygon(PackedVector2Array([base_pt + side, base_pt - side, tip_pt - side, tip_pt + side]), col)
				ci.draw_polyline(PackedVector2Array([base_pt + side, tip_pt + side, tip_pt - side, base_pt - side]), LINE, 1.5, true)
				ci.draw_colored_polygon(PackedVector2Array([tip_pt + side, tip_pt - side, tip_pt + dir * 20.0]), Color("#F2D2A0"))
				ci.draw_colored_polygon(PackedVector2Array([tip_pt + dir * 11.0 + side * 0.4, tip_pt + dir * 11.0 - side * 0.4, tip_pt + dir * 20.0]), LINE)
			var body := PackedVector2Array([Vector2(170, 110), Vector2(390, 110), Vector2(390, 395)])
			for k in 25:
				body.append(Vector2(280, 395) + Vector2(cos(TAU * k / 48.0), sin(TAU * k / 48.0)) * Vector2(110, 22))
			body.append(Vector2(170, 395))
			ci.draw_colored_polygon(body, Color("#B9BEC7"))
			for k in 10:
				ci.draw_rect(Rect2(170 + k * 22, 110, 11, 300), Color(1, 1, 1, 0.07 + 0.05 * (k % 3)))
		"porte":
			_door(ci)
		"valentin":
			_valentine(ci)
		"cadre":
			var f := Rect2(60, 30, 440, 360)
			ci.draw_rect(Rect2(f.position + Vector2(6, 8), f.size), Color(0.3, 0.2, 0.1, 0.2))
			ci.draw_rect(f, Color("#C9A073"))
			ci.draw_rect(f, Color("#8A6A42"), false, 3.0)
			if picture != null:
				ci.draw_texture_rect(picture, WINDOW, false)
			else:
				_default_picture(ci, WINDOW)
			ci.draw_rect(WINDOW, Color("#6F5232"), false, 4.0)


## What goes over the paint and the pieces: the front rim of the tin, the glass of the frame.
static func draw_over(ci: CanvasItem, base: String) -> void:
	match base:
		"porte":
			_chacha(ci, DOOR_RECT.position + Vector2(75, 160) * DOOR_K)
		"pot":
			ci.draw_arc(Vector2(280, 110), 110.0, 0.0, PI, 32, Color("#8F949D"), 4.0, true)
			ci.draw_arc(Vector2(280, 110), 110.0, 0.0, PI, 32, Color(1, 1, 1, 0.35), 1.5, true)
		"cadre":
			ci.draw_rect(WINDOW, Color(0.3, 0.2, 0.1, 0.28), false, 6.0)
			ci.draw_colored_polygon(PackedVector2Array([WINDOW.position + Vector2(20, 8), WINDOW.position + Vector2(110, 8),
				WINDOW.position + Vector2(40, 100), WINDOW.position + Vector2(8, 100)]), Color(1, 1, 1, 0.12))


static func _default_picture(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color("#BFE3F7"))
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.7, r.size.x, r.size.y * 0.3), Color("#9BD84B"))
	CuteArt.sun(ci, r.position + Vector2(r.size.x * 0.82, r.size.y * 0.2), 22.0)
	CuteArt.house(ci, r.position + Vector2(r.size.x * 0.4, r.size.y * 0.6), 52.0)
	CuteArt.flower(ci, r.position + Vector2(r.size.x * 0.12, r.size.y * 0.82), 20.0, Color("#FF7BA3"))


# Her oak door as in the corridor (`InteriorArt.panel_door`): the frame, the panel, the raised panel, the grain, the knob.
static func _door(ci: CanvasItem) -> void:
	var o := DOOR_RECT.position
	var k := DOOR_K
	ci.draw_rect(Rect2(o + Vector2(6, 8), DOOR_RECT.size), Color(0.3, 0.2, 0.1, 0.2))
	ci.draw_rect(DOOR_RECT, Color("#9A5E2C"))
	ci.draw_rect(Rect2(o, Vector2(DOOR_RECT.size.x * 0.25, DOOR_RECT.size.y)), Color(1, 1, 1, 0.07))
	ci.draw_rect(Rect2(o + Vector2(10, 10) * k, Vector2(130, 420) * k), Color("#A5663A"))
	ci.draw_rect(Rect2(o + Vector2(10, 10) * k, Vector2(130, 420) * k), Color("#5E3517"), false, 2.4)
	var panel := Rect2(o + Vector2(26, 30) * k, Vector2(98, 370) * k)
	ci.draw_rect(panel, Color("#B07240"))
	ci.draw_rect(panel, Color("#5E3517"), false, 2.4)
	for pts: Array in [[Vector2(26, 30), Vector2(38, 42)], [Vector2(124, 30), Vector2(112, 42)], [Vector2(26, 400), Vector2(38, 388)], [Vector2(124, 400), Vector2(112, 388)]]:
		ci.draw_line(o + pts[0] * k, o + pts[1] * k, Color("#5E3517"), 2.0, true)
	ci.draw_line(o + Vector2(38, 42) * k, o + Vector2(112, 42) * k, Color("#5E3517"), 2.0, true)
	ci.draw_line(o + Vector2(38, 388) * k, o + Vector2(112, 388) * k, Color("#5E3517"), 2.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 6:
		var cx := 75.0 + rng.randf_range(-16, 16)
		var cy := 120.0 + i * 50.0
		var rad := Vector2(rng.randf_range(10, 30), rng.randf_range(16, 30)) * k
		var ring := PackedVector2Array()
		for j in 33:
			ring.append(o + Vector2(cx, cy) * k + Vector2(cos(TAU * j / 32.0) * rad.x, sin(TAU * j / 32.0) * rad.y))
		ci.draw_polyline(ring, Color(0.37, 0.21, 0.09, 0.4), 1.4, true)
	for i in 9:
		var x := 32.0 + i * 10.0 + rng.randf_range(-3, 3)
		ci.draw_line(o + Vector2(x, 36) * k, o + Vector2(x + rng.randf_range(-3, 3), 394) * k, Color(0.37, 0.21, 0.09, 0.12), 1.0)
	ci.draw_rect(DOOR_RECT, Color("#5E3517"), false, 3.0)
	var knob := o + Vector2(128, 236) * k
	ci.draw_circle(knob + Vector2(1.5, 2), 7.0, Color(0, 0, 0, 0.25))
	ci.draw_circle(knob, 7.0, Color("#E8E4D8"))
	ci.draw_arc(knob, 7.0, 0.0, TAU, 20, Color("#8A8478"), 2.0, true)
	ci.draw_circle(knob + Vector2(-2, -2), 2.2, Color.WHITE)


## The valentine's paper heart: its middle and its outline.
const HEART_C := Vector2(280, 206)


static func heart_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 72:
		var a := TAU * k / 72.0
		pts.append(HEART_C + Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a)) - 2.0) * 10.6)
	return pts


# A white lace doily under a pink paper heart.
static func _valentine(ci: CanvasItem) -> void:
	var c := HEART_C + Vector2(0, 8)
	var lace := PackedVector2Array()
	for k in 96:
		var a := TAU * k / 96.0
		lace.append(c + Vector2.from_angle(a) * (196.0 + 7.0 * cos(a * 32.0)))
	var shade := PackedVector2Array()
	for p: Vector2 in lace:
		shade.append(p + Vector2(5, 7))
	ci.draw_colored_polygon(shade, Color(0.3, 0.2, 0.1, 0.15))
	ci.draw_colored_polygon(lace, Color("#FFFDF9"))
	for ring in [[176.0, 32, 5.0], [150.0, 24, 4.0]]:
		for k in int(ring[1]):
			var a := TAU * k / float(ring[1])
			ci.draw_circle(c + Vector2.from_angle(a) * float(ring[0]), float(ring[2]), Color("#EFE3E3"))
	ci.draw_arc(c, 186.0, 0.0, TAU, 96, Color("#E8DADA"), 1.4, true)
	var heart := heart_points()
	var hs := PackedVector2Array()
	for p: Vector2 in heart:
		hs.append(p + Vector2(4, 6))
	ci.draw_colored_polygon(hs, Color(0.5, 0.1, 0.2, 0.18))
	ci.draw_colored_polygon(heart, Color("#FFC2D4"))
	# The grain of the construction paper.
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	for k in 160:
		var p := HEART_C + Vector2(rng.randf_range(-160, 160), rng.randf_range(-140, 170))
		if Geometry2D.is_point_in_polygon(p, heart):
			ci.draw_circle(p, rng.randf_range(0.6, 1.4), Color(1, 1, 1, 0.35))
	heart.append(heart[0])
	ci.draw_polyline(heart, Color("#D9668C"), 3.0, true)


## The paper "chacha" sign taped to her door, each letter in another marker (as in `house.gd _chacha_sign`).
static func _chacha(ci: CanvasItem, center: Vector2) -> void:
	var k := DOOR_K
	var paper := PackedVector2Array([Vector2(-58, -16), Vector2(58, -19), Vector2(60, 17), Vector2(-57, 19)])
	var placed := PackedVector2Array()
	for p: Vector2 in paper:
		placed.append(center + p * k)
	ci.draw_colored_polygon(placed, Color("#FBFAF6"))
	var colors := ["#7E57C2", "#F2A7C9", "#1FB5C4", "#E04F5F", "#FF8A3D", "#3E8E5A"]
	var word := "chacha"
	var font := ThemeDB.fallback_font
	for i in word.length():
		var at := center + Vector2(-50.0 + i * 17.0 + 4.0, 6.0 + (i % 2) * 2.0) * k
		ci.draw_set_transform(at, deg_to_rad(-4.0 + (i * 37) % 9))
		ci.draw_string(font, Vector2.ZERO, word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * k), Color(colors[i]))
	ci.draw_set_transform(Vector2.ZERO)


static func _ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 36:
		pts.append(c + Vector2(cos(TAU * k / 36.0) * rad.x, sin(TAU * k / 36.0) * rad.y))
	ci.draw_colored_polygon(pts, col)


# ── Paper shapes and papers ─────────────────────────────────────

## The outline of a shape about `s` px across, centred on the origin.
static func shape_points(id: String, s: float) -> PackedVector2Array:
	var h := s * 0.5
	var pts := PackedVector2Array()
	match id:
		"cercle":
			for k in 48:
				pts.append(Vector2.from_angle(TAU * k / 48.0) * h)
		"ovale":
			for k in 48:
				pts.append(Vector2(cos(TAU * k / 48.0) * h, sin(TAU * k / 48.0) * h * 0.68))
		"carre":
			pts = PackedVector2Array([Vector2(-h, -h) * 0.9, Vector2(h, -h) * 0.9, Vector2(h, h) * 0.9, Vector2(-h, h) * 0.9])
		"rectangle":
			pts = PackedVector2Array([Vector2(-h, -h * 0.62), Vector2(h, -h * 0.62), Vector2(h, h * 0.62), Vector2(-h, h * 0.62)])
		"triangle":
			pts = PackedVector2Array([Vector2(0, -h * 0.95), Vector2(h, h * 0.8), Vector2(-h, h * 0.8)])
		"losange":
			pts = PackedVector2Array([Vector2(0, -h), Vector2(h * 0.72, 0), Vector2(0, h), Vector2(-h * 0.72, 0)])
		"coeur":
			for k in 48:
				var t := TAU * k / 48.0
				var p := Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)))
				pts.append(Vector2(p.x / 17.0 * h, (p.y + 2.0) / 16.0 * h))
		"etoile":
			for k in 10:
				pts.append(Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * h * (1.0 if k % 2 == 0 else 0.42))
		"fleur":
			for k in 80:
				var a := TAU * k / 80.0
				pts.append(Vector2.from_angle(a) * h * (0.78 + 0.22 * cos(a * 5.0)))
		"nuage":
			var parts := [[Vector2(-0.45, 0.2), 0.36], [Vector2(0.45, 0.2), 0.36], [Vector2(-0.18, -0.1), 0.46], [Vector2(0.25, -0.02), 0.4]]
			var merged := PackedVector2Array()
			for pr: Array in parts:
				var circle := PackedVector2Array()
				for k in 24:
					circle.append((pr[0] + Vector2.from_angle(TAU * k / 24.0) * pr[1]) * h)
				if merged.is_empty():
					merged = circle
				else:
					var res := Geometry2D.merge_polygons(merged, circle)
					if not res.is_empty():
						merged = res[0]
			pts = merged
		"lune":
			for k in 25:
				var a := PI * 0.5 + PI * k / 24.0
				pts.append(Vector2(cos(a), sin(a)) * h)
			for k in range(1, 24):
				var a := PI * 1.5 - PI * k / 24.0
				pts.append(Vector2(cos(a) * h * 0.5, sin(a) * h))
		"feuille":
			for k in 21:
				var t := float(k) / 20.0
				pts.append(Vector2(sin(t * PI) * h * 0.62, (t - 0.5) * 2.0 * h))
			for k in range(19, 0, -1):
				var t := float(k) / 20.0
				pts.append(Vector2(-sin(t * PI) * h * 0.62, (t - 0.5) * 2.0 * h))
		"goutte":
			pts.append(Vector2(0, -h))
			for k in 25:
				var a := -PI * 0.35 + PI * 1.7 * k / 24.0
				pts.append(Vector2(cos(a) * h * 0.62, h * 0.35 + sin(a) * h * 0.62))
		"papillon":
			var wings := [[Vector2(-0.45, -0.25), Vector2(0.5, 0.45)], [Vector2(0.45, -0.25), Vector2(0.5, 0.45)],
				[Vector2(-0.35, 0.35), Vector2(0.36, 0.3)], [Vector2(0.35, 0.35), Vector2(0.36, 0.3)]]
			var merged := PackedVector2Array()
			for wg: Array in wings:
				var oval := PackedVector2Array()
				for k in 24:
					oval.append(Vector2(wg[0].x + cos(TAU * k / 24.0) * wg[1].x, wg[0].y + sin(TAU * k / 24.0) * wg[1].y) * h)
				if merged.is_empty():
					merged = oval
				else:
					var res := Geometry2D.merge_polygons(merged, oval)
					if not res.is_empty():
						merged = res[0]
			pts = merged
		"bande":
			pts = PackedVector2Array([Vector2(-h, -h * 0.16), Vector2(h, -h * 0.16), Vector2(h, h * 0.16), Vector2(-h, h * 0.16)])
		"vague":
			for k in 41:
				var x := lerpf(-h, h, k / 40.0)
				pts.append(Vector2(x, -h * 0.2 + sin(x / h * TAU * 1.5) * h * 0.1))
			for k in range(40, -1, -1):
				var x := lerpf(-h, h, k / 40.0)
				pts.append(Vector2(x, h * 0.12 + sin(x / h * TAU * 1.5) * h * 0.1))
		"maison":
			pts = PackedVector2Array([Vector2(-h * 0.8, -h * 0.1), Vector2(0, -h * 0.9), Vector2(h * 0.8, -h * 0.1), Vector2(h * 0.8, h * 0.85),
				Vector2(-h * 0.8, h * 0.85)])
	return pts


## Half the width and height of a shape drawn at size `s`.
static func shape_half(id: String, s: float) -> Vector2:
	if not _half_cache.has(id):
		var pts := shape_points(id, 100.0)
		var box := Rect2(pts[0], Vector2.ZERO)
		for p: Vector2 in pts:
			box = box.expand(p)
		_half_cache[id] = Vector2(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.y), absf(box.end.y))) / 100.0
	return _half_cache[id] * s


## The outline gone a little wobbly, as if cut by hand with scissors.
static func hand_cut(pts: PackedVector2Array, seed_: int, wobble: float) -> PackedVector2Array:
	if pts.size() < 3 or wobble <= 0.0:
		return pts
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var prev := pts[(i + n - 1) % n]
		var next := pts[(i + 1) % n]
		var normal := (next - prev).orthogonal().normalized()
		out.append(pts[i] + normal * rng.randf_range(-wobble, wobble))
	return out


## A piece of paper: its shadow, the paper (colour and pattern), a lit edge.
static func draw_paper(ci: CanvasItem, item: Dictionary) -> void:
	var s: float = item.s
	var clean := shape_points(item.sub, s)
	var pts := hand_cut(clean, int(item.get("seed", 1)), 1.4 if item.get("cut", true) else 0.0)
	# A wobble that folds the outline over itself (the heart's point) can't be filled: keep the clean one.
	if pts.size() < 3 or Geometry2D.triangulate_polygon(pts).size() == 0:
		pts = clean
	if pts.size() < 3:
		return
	var col: Color = item.color
	var shadow := PackedVector2Array()
	for p: Vector2 in pts:
		shadow.append(p + Vector2(2.5, 3.5))
	if Geometry2D.triangulate_polygon(shadow).size() > 0:
		ci.draw_colored_polygon(shadow, Color(0.2, 0.12, 0.05, 0.28))
	if Geometry2D.triangulate_polygon(pts).size() == 0:
		return
	ci.draw_colored_polygon(pts, col)
	var pattern: String = item.get("pattern", "uni")
	var mark := Color.WHITE if col.get_luminance() < 0.8 else col.darkened(0.3)
	var half := shape_half(item.sub, s)
	match pattern:
		"pois":
			var step := maxf(14.0, s * 0.16)
			var y := -half.y + step * 0.5
			var row := 0
			while y < half.y:
				var x := -half.x + step * (0.5 if row % 2 == 0 else 1.0)
				while x < half.x:
					if _in_poly(Vector2(x, y), pts) and _in_poly(Vector2(x + step * 0.3, y), pts) and _in_poly(Vector2(x - step * 0.3, y), pts) \
							and _in_poly(Vector2(x, y + step * 0.3), pts) and _in_poly(Vector2(x, y - step * 0.3), pts):
						ci.draw_circle(Vector2(x, y), step * 0.22, Color(mark, 0.9))
					x += step
				y += step * 0.9
				row += 1
		"rayures", "carreaux", "zigzag":
			var step := maxf(14.0, s * 0.15)
			var bands: Array = []
			if pattern == "rayures":
				var x := -half.x
				while x < half.x:
					bands.append(PackedVector2Array([Vector2(x, -half.y), Vector2(x + step * 0.45, -half.y), Vector2(x + step * 0.45, half.y), Vector2(x, half.y)]))
					x += step
			elif pattern == "carreaux":
				var y := -half.y
				var row := 0
				while y < half.y:
					var x := -half.x + (step if row % 2 == 0 else 0.0)
					while x < half.x:
						bands.append(PackedVector2Array([Vector2(x, y), Vector2(x + step, y), Vector2(x + step, y + step), Vector2(x, y + step)]))
						x += step * 2.0
					y += step
					row += 1
			else:
				var y := -half.y
				while y < half.y:
					var zig := PackedVector2Array()
					var x := -half.x
					var up := true
					while x <= half.x + step:
						zig.append(Vector2(x, y + (0.0 if up else step * 0.45)))
						x += step * 0.5
						up = not up
					var back := PackedVector2Array()
					for p: Vector2 in zig:
						back.append(p + Vector2(0, step * 0.2))
					back.reverse()
					zig.append_array(back)
					bands.append(zig)
					y += step * 0.8
			for band: PackedVector2Array in bands:
				for piece in Geometry2D.intersect_polygons(pts, band):
					if Geometry2D.triangulate_polygon(piece).size() > 0:
						ci.draw_colored_polygon(piece, Color(mark, 0.85))
		"paillettes":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(item.get("seed", 1)) + 7
			for k in int(s * 0.5):
				var p := Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y))
				if _in_poly(p, pts):
					var warm := rng.randf() < 0.5
					ci.draw_circle(p, rng.randf_range(0.8, 1.8), Color(1, 0.97, 0.8, 0.95) if warm else Color(1, 1, 1, 0.8))
	var ring := pts.duplicate()
	ring.append(pts[0])
	ci.draw_polyline(ring, Color(1, 1, 1, 0.35), 1.6, true)
	ci.draw_polyline(ring, Color(0, 0, 0, 0.18), 1.0, true)


static func _in_poly(p: Vector2, pts: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(p, pts)


# ── Decorations ─────────────────────────────────────────────────

static func deco(ci: CanvasItem, id: String, c: Vector2, r: float, color: Color, seed_ := 1) -> void:
	var w := maxf(1.0, r * 0.05)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	match id:
		"yeux":
			for s in [-1.0, 1.0]:
				_eye(ci, c + Vector2(s * 0.5, 0) * r, r * 0.46, s)
		"oeil":
			_eye(ci, c, r * 0.8, 1.0)
		"nez_rond":
			var nose := color if color.s > 0.3 else Color("#E04F5F")
			ci.draw_circle(c + Vector2(1.5, 2.5), r * 0.45, Color(0, 0, 0, 0.2))
			ci.draw_circle(c, r * 0.45, nose)
			ci.draw_circle(c + Vector2(-0.15, -0.15) * r, r * 0.12, Color(1, 1, 1, 0.65))
		"nez_pointe":
			StampArt._p(ci, c, r, [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0, 0.7)], color if color.s > 0.3 else Color("#FF8A3D"), w)
			ci.draw_line(c + Vector2(-0.25, -0.3) * r, c + Vector2(0.1, 0.3) * r, Color(0, 0, 0, 0.18), w, true)
		"bouche":
			ci.draw_arc(c + Vector2(0, -0.3) * r, r * 0.7, 0.35, PI - 0.35, 20, color if color.s > 0.3 else Color("#E04F5F"), r * 0.18, true)
		"bouche_ouverte":
			var mouth := PackedVector2Array()
			for k in 21:
				var a := PI * k / 20.0
				mouth.append(c + Vector2(cos(a) * 0.6, -0.15 + sin(a) * 0.55) * r)
			ci.draw_colored_polygon(mouth, Color("#7A1F2B"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, 0.3) * r, c + Vector2(0.3, 0.3) * r, c + Vector2(0.15, 0.38) * r, c + Vector2(-0.15, 0.38) * r]), Color("#F2A7B4"))
			mouth.append(mouth[0])
			ci.draw_polyline(mouth, LINE, w * 1.4, true)
			ci.draw_line(c + Vector2(-0.6, -0.15) * r, c + Vector2(0.6, -0.15) * r, Color.WHITE, r * 0.12, true)
		"moustache":
			var col := color if color.v < 0.6 else Color("#3B2A20")
			for s in [-1.0, 1.0]:
				var pts := PackedVector2Array()
				for k in 17:
					var t := k / 16.0
					pts.append(c + Vector2(s * (0.08 + t * 0.9), 0.05 - sin(t * PI) * 0.18 + t * t * 0.28) * r)
				ci.draw_polyline(pts, col, r * 0.2, true)
				ci.draw_circle(pts[16], r * 0.1, col)
		"joues":
			for s in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(s * 0.55, 0) * r, r * 0.34, Color("#FF7BA3", 0.6))
		"sourcils":
			for s in [-1.0, 1.0]:
				ci.draw_arc(c + Vector2(s * 0.5, 0.35) * r, r * 0.42, PI * 1.15, PI * 1.85, 10, color if color.v < 0.7 else Color("#3B2A20"), r * 0.13, true)
		"lunettes":
			var frame := color if color.v < 0.7 else Color("#2B2B2B")
			for s in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(s * 0.52, 0) * r, r * 0.42, Color(0.75, 0.9, 1.0, 0.3))
				ci.draw_arc(c + Vector2(s * 0.52, 0) * r, r * 0.42, 0.0, TAU, 24, frame, r * 0.09, true)
			ci.draw_line(c + Vector2(-0.1, -0.02) * r, c + Vector2(0.1, -0.02) * r, frame, r * 0.08, true)
		"pompon":
			var fluff := color
			ci.draw_circle(c + Vector2(1.5, 3.0), r * 0.55, Color(0, 0, 0, 0.18))
			ci.draw_circle(c, r * 0.52, fluff.darkened(0.12))
			for k in int(r * 5.0):
				var a := rng.randf() * TAU
				var d := r * (0.2 + 0.4 * sqrt(rng.randf()))
				var p := c + Vector2.from_angle(a) * d
				var tilt := Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * r * 0.16
				var lit := fluff.lightened(0.25) if (p - c).dot(Vector2(-1, -1)) > 0.0 else fluff
				ci.draw_line(p - tilt, p + tilt, lit, maxf(1.5, r * 0.07), true)
		"bouton", "bouton4":
			ci.draw_circle(c + Vector2(1.5, 2.5), r * 0.5, Color(0, 0, 0, 0.2))
			ci.draw_circle(c, r * 0.5, color)
			ci.draw_arc(c, r * 0.38, 0.0, TAU, 20, color.darkened(0.25), w * 1.5, true)
			ci.draw_arc(c, r * 0.5, 0.0, TAU, 20, color.lightened(0.3), w, true)
			var holes := [Vector2(-0.12, 0), Vector2(0.12, 0)] if id == "bouton" else [Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(-0.12, 0.12), Vector2(0.12, 0.12)]
			for hpt: Vector2 in holes:
				ci.draw_circle(c + hpt * r, r * 0.06, Color(0.15, 0.1, 0.08))
			if id == "bouton":
				ci.draw_line(c + Vector2(-0.12, 0) * r, c + Vector2(0.12, 0) * r, Color("#F4EEE6"), w, true)
			else:
				ci.draw_line(c + Vector2(-0.12, -0.12) * r, c + Vector2(0.12, 0.12) * r, Color("#F4EEE6"), w, true)
				ci.draw_line(c + Vector2(0.12, -0.12) * r, c + Vector2(-0.12, 0.12) * r, Color("#F4EEE6"), w, true)
		"perle":
			ci.draw_circle(c + Vector2(1.5, 2.5), r * 0.4, Color(0, 0, 0, 0.2))
			ci.draw_circle(c, r * 0.4, color)
			ci.draw_circle(c + Vector2(0.1, 0.1) * r, r * 0.3, color.darkened(0.12))
			ci.draw_circle(c + Vector2(-0.12, -0.12) * r, r * 0.12, Color(1, 1, 1, 0.8))
		"grelot":
			ci.draw_circle(c + Vector2(1.5, 2.5), r * 0.45, Color(0, 0, 0, 0.2))
			ci.draw_circle(c, r * 0.45, Color("#F2C230"))
			ci.draw_arc(c, r * 0.45, 0.0, TAU, 24, Color("#B8860B"), w * 1.5, true)
			ci.draw_line(c + Vector2(-0.4, 0.05) * r, c + Vector2(0.4, 0.05) * r, Color("#8A6A00"), w * 1.5, true)
			ci.draw_circle(c + Vector2(0, 0.14) * r, r * 0.06, Color("#8A6A00"))
			ci.draw_circle(c + Vector2(-0.16, -0.18) * r, r * 0.1, Color(1, 1, 1, 0.7))
		"noeud":
			for s in [-1.0, 1.0]:
				StampArt._p(ci, c, r, [Vector2(0, 0), Vector2(s * 0.85, -0.45), Vector2(s * 0.95, 0.0), Vector2(s * 0.85, 0.45)], color, w)
				StampArt._p(ci, c, r, [Vector2(0.0, 0.1), Vector2(s * 0.3, 0.9), Vector2(s * 0.5, 0.78), Vector2(s * 0.12, 0.05)], color.darkened(0.12), w)
			ci.draw_circle(c, r * 0.2, color.lightened(0.1))
			ci.draw_arc(c, r * 0.2, 0.0, TAU, 14, LINE, w, true)
		"spirale":
			var pts := PackedVector2Array()
			for k in 61:
				var t := k / 60.0
				var a := t * TAU * 2.5
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.1 + 0.8 * t))
			ci.draw_polyline(pts, Color(0, 0, 0, 0.18), r * 0.2 + 2.0, true)
			ci.draw_polyline(pts, color, r * 0.18, true)
			ci.draw_polyline(pts, color.lightened(0.35), r * 0.06, true)
		"gemme":
			var tint := color
			StampArt._p(ci, c, r, [Vector2(-0.8, -0.2), Vector2(-0.45, -0.7), Vector2(0.45, -0.7), Vector2(0.8, -0.2), Vector2(0, 0.85)], tint, w)
			StampArt._p(ci, c, r, [Vector2(-0.8, -0.2), Vector2(-0.45, -0.7), Vector2(-0.15, -0.2)], tint.lightened(0.4), 0.0)
			StampArt._p(ci, c, r, [Vector2(0.8, -0.2), Vector2(0.45, -0.7), Vector2(0.15, -0.2)], tint.lightened(0.25), 0.0)
			StampArt._p(ci, c, r, [Vector2(-0.15, -0.2), Vector2(0.15, -0.2), Vector2(0, 0.85)], tint.darkened(0.15), 0.0)
			ci.draw_line(c + Vector2(-0.8, -0.2) * r, c + Vector2(0.8, -0.2) * r, Color(1, 1, 1, 0.5), w, true)
			ci.draw_circle(c + Vector2(-0.3, -0.5) * r, r * 0.07, Color(1, 1, 1, 0.9))
		"gemme_ronde":
			ci.draw_circle(c, r * 0.6, color)
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(c, c + Vector2.from_angle(a) * r * 0.6, color.lightened(0.3 if k % 2 == 0 else 0.0), w, true)
			ci.draw_circle(c, r * 0.28, color.lightened(0.35))
			ci.draw_arc(c, r * 0.6, 0.0, TAU, 24, color.darkened(0.4), w * 1.4, true)
			ci.draw_circle(c + Vector2(-0.25, -0.28) * r, r * 0.09, Color(1, 1, 1, 0.9))
		"scintille":
			var gold := Color("#FFE27A") if color.v > 0.5 else color
			var pts := PackedVector2Array()
			for k in 8:
				var a := TAU * k / 8.0 - PI / 2.0
				pts.append(c + Vector2.from_angle(a) * r * (0.95 if k % 2 == 0 else 0.16))
			ci.draw_colored_polygon(pts, Color(1, 0.98, 0.85))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), gold, w * 1.6, true)
			ci.draw_circle(c, r * 0.12, Color.WHITE)
		"paillettes":
			for k in 16:
				var p := c + Vector2.from_angle(rng.randf() * TAU) * r * 0.9 * sqrt(rng.randf())
				var sc := color if k % 3 != 0 else color.lightened(0.45)
				ci.draw_circle(p, r * 0.11, sc)
				ci.draw_circle(p + Vector2(-0.03, -0.03) * r, r * 0.035, Color(1, 1, 1, 0.9))
		"confettis":
			var cols := ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF7BA3", "#7E57C2"]
			for k in 18:
				var p := c + Vector2.from_angle(rng.randf() * TAU) * r * 0.9 * sqrt(rng.randf())
				var a := rng.randf() * PI
				var d := Vector2.from_angle(a) * r * 0.1
				var n := d.orthogonal() * 0.5
				ci.draw_colored_polygon(PackedVector2Array([p - d - n, p + d - n, p + d + n, p - d + n]), Color(cols[k % cols.size()]))
		"plume":
			var tip := c + Vector2(0.5, -0.95) * r
			var root := c + Vector2(-0.45, 0.95) * r
			var mid := (tip + root) * 0.5
			var side := (tip - root).orthogonal().normalized() * r * 0.32
			var vane := PackedVector2Array([root, mid + side + (tip - root) * 0.05, tip, mid - side - (tip - root) * 0.05])
			ci.draw_colored_polygon(vane, color)
			for k in 7:
				var t := 0.15 + k * 0.11
				var q := root.lerp(tip, t)
				ci.draw_line(q, q + side * (1.0 - absf(t - 0.5)) * 1.1 + (tip - root) * 0.05, color.darkened(0.18), w, true)
				ci.draw_line(q, q - side * (1.0 - absf(t - 0.5)) * 1.1 + (tip - root) * 0.05, color.lightened(0.15), w, true)
			ci.draw_line(root - (tip - root) * 0.08, tip, color.darkened(0.45), w * 1.6, true)
		"marguerite":
			for k in 12:
				var a := TAU * k / 12.0
				StampArt._e(ci, c, r, Vector2.from_angle(a) * 0.58, Vector2(0.34, 0.14), Color.WHITE, w * 0.7)
			ci.draw_circle(c, r * 0.28, Color("#FFD23F"))
			ci.draw_arc(c, r * 0.28, 0.0, TAU, 16, Color("#B8860B"), w, true)
		"tournesol":
			for k in 14:
				var a := TAU * k / 14.0
				StampArt._e(ci, c, r, Vector2.from_angle(a) * 0.65, Vector2(0.3, 0.13), Color("#FFC21A"), w * 0.7)
			ci.draw_circle(c, r * 0.36, Color("#6B3E1E"))
			for k in 22:
				var p := c + Vector2.from_angle(rng.randf() * TAU) * r * 0.3 * sqrt(rng.randf())
				ci.draw_circle(p, r * 0.025, Color("#3A2010"))
		"fleur_feutre":
			for k in 5:
				var a := TAU * k / 5.0 - PI / 2.0
				ci.draw_circle(c + Vector2.from_angle(a) * r * 0.5, r * 0.36, color)
				_stitch_arc(ci, c + Vector2.from_angle(a) * r * 0.5, r * 0.28, color)
			ci.draw_circle(c, r * 0.28, color.lightened(0.3))
			_stitch_arc(ci, c, r * 0.2, color.lightened(0.3))
		"coeur_feutre":
			var heart := shape_points("coeur", r * 2.0)
			var moved := PackedVector2Array()
			for p: Vector2 in heart:
				moved.append(c + p)
			ci.draw_colored_polygon(moved, color)
			var inner := PackedVector2Array()
			for p: Vector2 in moved:
				inner.append(c + (p - c) * 0.8)
			_dashed(ci, inner, color.lightened(0.5))
		"etoile_feutre":
			var star := PackedVector2Array()
			for k in 10:
				star.append(c + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * r * (1.0 if k % 2 == 0 else 0.45))
			ci.draw_colored_polygon(star, color)
			var inner := PackedVector2Array()
			for p: Vector2 in star:
				inner.append(c + (p - c) * 0.78)
			_dashed(ci, inner, color.lightened(0.5))
		"coquillage":
			var shell := PackedVector2Array([c + Vector2(0, 0.85) * r])
			for k in 21:
				var a := PI * 1.08 + PI * 0.84 * k / 20.0
				shell.append(c + Vector2(cos(a) * 0.9, sin(a) * 0.95 + 0.1) * r)
			ci.draw_colored_polygon(shell, color)
			for k in 7:
				var a := PI * 1.08 + PI * 0.84 * k / 6.0
				ci.draw_line(c + Vector2(0, 0.85) * r, c + Vector2(cos(a) * 0.9, sin(a) * 0.95 + 0.1) * r, color.darkened(0.25), w, true)
			shell.append(shell[0])
			ci.draw_polyline(shell, color.darkened(0.4), w * 1.3, true)
			ci.draw_rect(Rect2(c + Vector2(-0.25, 0.8) * r, Vector2(0.5, 0.15) * r), color.darkened(0.3))
		"fanions":
			# A string of little flags across, each its own colour.
			var flags := ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF7BA3", "#7E57C2"]
			var line := PackedVector2Array()
			for j in 21:
				var t := j / 20.0
				line.append(c + Vector2(lerpf(-1.0, 1.0, t), -0.35 + sin(t * PI) * 0.25) * r)
			for j in 6:
				var t0 := (j + 0.15) / 6.0
				var t1 := (j + 0.85) / 6.0
				var a := c + Vector2(lerpf(-1.0, 1.0, t0), -0.35 + sin(t0 * PI) * 0.25) * r
				var b := c + Vector2(lerpf(-1.0, 1.0, t1), -0.35 + sin(t1 * PI) * 0.25) * r
				var tip := (a + b) / 2.0 + Vector2(0, 0.42 * r)
				var col := Color(flags[(j + seed_) % flags.size()]) if color.s < 0.15 else (color if j % 2 == 0 else color.lightened(0.45))
				ci.draw_colored_polygon(PackedVector2Array([a, b, tip]), col)
				ci.draw_polyline(PackedVector2Array([a, tip, b]), col.darkened(0.3), w, true)
			ci.draw_polyline(line, Color("#6E4E3A"), w * 1.2, true)
		"accroche":
			# A door hanger: a card with a round hole at the top for the knob.
			var card := Rect2(c + Vector2(-0.55, -0.9) * r, Vector2(1.1, 1.85) * r)
			ci.draw_rect(Rect2(card.position + Vector2(2, 3), card.size), Color(0, 0, 0, 0.2))
			ci.draw_rect(card, color if color.v > 0.25 else Color("#FFB3C7"))
			ci.draw_rect(card, color.darkened(0.35), false, w * 1.2)
			ci.draw_circle(c + Vector2(0, -0.55) * r, 0.2 * r, Color(0.3, 0.2, 0.1, 0.45))
			ci.draw_line(c + Vector2(-0.12, -0.34) * r, c + Vector2(-0.12, -0.1) * r, color.darkened(0.35), w, true)
			ci.draw_line(c + Vector2(0.12, -0.34) * r, c + Vector2(0.12, -0.1) * r, color.darkened(0.35), w, true)
			StampArt._p(ci, c + Vector2(0, 0.45) * r, r * 0.3, [Vector2(0, 0.8), Vector2(-0.9, -0.1), Vector2(-0.5, -0.7), Vector2(0, -0.3), Vector2(0.5, -0.7), Vector2(0.9, -0.1)], Color.WHITE, w)
		"arc_en_ciel":
			var bands := ["#E8542F", "#F2C230", "#5BD16E", "#4FA3E0", "#9C6CC4"]
			for j in bands.size():
				ci.draw_arc(c + Vector2(0, 0.45) * r, r * (0.95 - j * 0.13), PI, TAU, 28, Color(bands[j]), r * 0.13, true)
			for sx in [-0.78, 0.78]:
				ci.draw_circle(c + Vector2(sx, 0.48) * r, r * 0.2, Color.WHITE)
				ci.draw_circle(c + Vector2(sx + 0.16 * sign(sx), 0.42) * r, r * 0.16, Color.WHITE)
		"ampoules":
			# A little string of bulbs, glowing.
			var bulbs := ["#FF5E8A", "#FFD23F", "#5BD1E0", "#7CCB5A", "#FF8A3D"]
			var wire := PackedVector2Array()
			for j in 21:
				var t := j / 20.0
				wire.append(c + Vector2(lerpf(-1.0, 1.0, t), -0.3 + sin(t * PI) * 0.3) * r)
			ci.draw_polyline(wire, Color("#3E4A3A"), w * 1.2, true)
			for j in 5:
				var t := (j + 0.5) / 5.0
				var at := c + Vector2(lerpf(-1.0, 1.0, t), -0.3 + sin(t * PI) * 0.3 + 0.18) * r
				var col := Color(bulbs[(j + seed_) % bulbs.size()])
				ci.draw_circle(at, r * 0.2, Color(col, 0.25))
				ci.draw_circle(at, r * 0.11, col)
				ci.draw_circle(at + Vector2(-0.03, -0.04) * r, r * 0.04, Color(1, 1, 1, 0.8))
		"feuillage":
			ci.draw_line(c + Vector2(0, 0.95) * r, c + Vector2(0, -0.8) * r, Color("#3E8E5A"), w * 1.6, true)
			for k in 4:
				var y := 0.7 - k * 0.38
				for s in [-1.0, 1.0]:
					var lf := PackedVector2Array()
					for j in 11:
						var t := j / 10.0
						lf.append(c + Vector2(s * (0.05 + t * 0.55), y - t * 0.3 - sin(t * PI) * 0.16) * r)
					for j in range(9, 0, -1):
						var t := j / 10.0
						lf.append(c + Vector2(s * (0.05 + t * 0.55), y - t * 0.3 + sin(t * PI) * 0.1) * r)
					if Geometry2D.triangulate_polygon(lf).size() > 0:
						ci.draw_colored_polygon(lf, color if color.s > 0.2 else Color("#5FAE4F"))
			StampArt._e(ci, c, r, Vector2(0, -0.88), Vector2(0.14, 0.2), color if color.s > 0.2 else Color("#5FAE4F"), 0.0)


static func _eye(ci: CanvasItem, c: Vector2, rad: float, side: float) -> void:
	ci.draw_circle(c + Vector2(1.0, 1.8), rad, Color(0, 0, 0, 0.22))
	ci.draw_circle(c, rad, Color.WHITE)
	ci.draw_arc(c, rad, 0.0, TAU, 24, LINE, maxf(1.0, rad * 0.12), true)
	ci.draw_circle(c + Vector2(0.18 * side, 0.22) * rad, rad * 0.46, Color("#2B2B2B"))
	ci.draw_circle(c + Vector2(0.05 * side, 0.1) * rad, rad * 0.14, Color.WHITE)


static func _stitch_arc(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	for k in 8:
		var a := TAU * k / 8.0
		ci.draw_arc(c, rad, a, a + 0.4, 4, col.lightened(0.5), 1.4, true)


static func _dashed(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		if i % 2 == 0:
			ci.draw_line(a, b, col, 1.4, true)


## Half the size a decoration or sticker takes up, for its frame and its hit.
static func deco_half(id: String, r: float) -> Vector2:
	match id:
		"yeux":
			return Vector2(0.98, 0.5) * r
		"bouche", "bouche_ouverte", "moustache", "sourcils", "lunettes", "joues":
			return Vector2(1.0, 0.65) * r
		"pompon", "bouton", "bouton4", "perle", "grelot":
			return Vector2(0.55, 0.55) * r
		"noeud":
			return Vector2(1.0, 0.85) * r
		"fanions", "ampoules":
			return Vector2(1.0, 0.6) * r
		"accroche":
			return Vector2(0.6, 0.95) * r
		"arc_en_ciel":
			return Vector2(1.0, 0.6) * r
	return Vector2(1.0, 1.0) * r


# ── Writing ─────────────────────────────────────────────────────

const TEXT_STYLES := [["simple", "Simple"], ["etiquette", "Étiquette"], ["bulle", "Bulle"], ["banderole", "Banderole"]]


static func text_size(item: Dictionary) -> Vector2:
	var size := int(item.s)
	var w := ThemeDB.fallback_font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pad := 0.0
	match item.get("style", "simple"):
		"etiquette":
			pad = size * 0.9
		"bulle":
			pad = size * 0.7
		"banderole":
			pad = size * 1.4
	return Vector2(w + pad, size * (1.5 if item.get("style", "simple") != "simple" else 1.1))


static func draw_text(ci: CanvasItem, item: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var size := int(item.s)
	var box := text_size(item)
	var col: Color = item.color
	var dark := col.get_luminance() < 0.55
	match item.get("style", "simple"):
		"etiquette":
			var r := Rect2(-box * 0.5, box)
			StampArt._p(ci, Vector2.ZERO, 1.0, [Vector2(r.position.x + size * 0.5, r.position.y), Vector2(r.end.x, r.position.y), r.end,
				Vector2(r.position.x + size * 0.5, r.end.y), Vector2(r.position.x, r.position.y + box.y * 0.5)], Color("#FFFDF7"), 1.5)
			ci.draw_circle(Vector2(r.position.x + size * 0.45, 0), size * 0.14, Color("#8A6A42"))
			ci.draw_line(Vector2(r.position.x + size * 0.45, 0), Vector2(r.position.x - size * 0.8, -size * 0.5), Color("#8D6E63"), 1.6, true)
			ci.draw_string(font, Vector2(-box.x * 0.5 + size * 0.95, size * 0.35), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col if dark else LINE)
		"bulle":
			var r2 := Rect2(-box * 0.5, box)
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.set_corner_radius_all(int(box.y * 0.5))
			sb.border_color = col.darkened(0.3)
			sb.set_border_width_all(2)
			ci.draw_style_box(sb, r2)
			ci.draw_string(font, Vector2(-box.x * 0.5 + size * 0.35, size * 0.35), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE if dark else LINE)
		"banderole":
			var r3 := Rect2(-box * 0.5, box)
			var tail := size * 0.7
			ci.draw_colored_polygon(PackedVector2Array([r3.position + Vector2(-tail, size * 0.3), r3.position + Vector2(tail * 0.3, size * 0.3),
				r3.position + Vector2(tail * 0.3, r3.size.y), r3.position + Vector2(-tail, r3.size.y), r3.position + Vector2(-tail * 0.5, r3.size.y * 0.65)]), col.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([r3.end + Vector2(tail, -r3.size.y + size * 0.3), r3.end + Vector2(-tail * 0.3, -r3.size.y + size * 0.3),
				r3.end + Vector2(-tail * 0.3, 0), r3.end + Vector2(tail, 0), r3.end + Vector2(tail * 0.5, -r3.size.y * 0.35)]), col.darkened(0.2))
			ci.draw_rect(r3, col)
			ci.draw_line(r3.position + Vector2(0, 3), r3.position + Vector2(r3.size.x, 3), Color(1, 1, 1, 0.3), 2.0)
			ci.draw_string(font, Vector2(-box.x * 0.5 + size * 0.7, size * 0.35), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE if dark else LINE)
		_:
			var at := Vector2(-box.x * 0.5, size * 0.35)
			ci.draw_string_outline(font, at, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(3, size / 7), Color(1, 1, 1, 0.85) if dark else Color(0, 0, 0, 0.3))
			ci.draw_string(font, at, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# ── Anything that goes on a piece ───────────────────────────────

## Draws an item (paper, decoration, sticker or writing) at its place, turned and flipped.
static func draw_item(ci: CanvasItem, item: Dictionary) -> void:
	var pop: float = item.get("pop", 1.0)
	ci.draw_set_transform(item.at, item.get("rot", 0.0), Vector2(-pop if item.get("flip", false) and item.kind != "text" else pop, pop))
	match item.kind:
		"paper":
			draw_paper(ci, item)
		"deco":
			deco(ci, item.sub, Vector2.ZERO, item.s, item.color, int(item.get("seed", 1)))
		"sticker":
			StampArt.draw(ci, item.sub, Vector2.ZERO, item.s, item.color)
		"text":
			draw_text(ci, item)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func item_half(item: Dictionary) -> Vector2:
	match item.kind:
		"paper":
			return shape_half(item.sub, item.s) + Vector2(3, 3)
		"deco":
			return deco_half(item.sub, item.s) + Vector2(3, 3)
		"text":
			return text_size(item) * 0.5 + Vector2(6, 2)
	return Vector2(item.s, item.s) * 1.05


# ── Beads (the necklace) ────────────────────────────────────────
# Every bead is lit from the upper left like the rest of the game: a darker body, a lighter one shifted toward the light, a soft
# glow and a small shine, an outline of its own darker tone. Pasta is painted pasta (glossy tempera), tubes show their ridges and
# the dark hole the string goes through.

static func _oval(c: Vector2, rx: float, ry: float, rot := 0.0, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## A ball with light from the upper left, its shadow on the table, a shine.
static func _ball(ci: CanvasItem, c: Vector2, rad: float, col: Color, shine := true) -> void:
	ci.draw_circle(c, rad, col.darkened(0.34))
	ci.draw_circle(c + Vector2(-0.08, -0.1) * rad, rad * 0.9, col.darkened(0.1))
	ci.draw_circle(c + Vector2(-0.16, -0.2) * rad, rad * 0.62, col.lightened(0.14))
	ci.draw_circle(c + Vector2(-0.26, -0.34) * rad, rad * 0.3, col.lightened(0.4))
	if shine:
		ci.draw_circle(c + Vector2(-0.34, -0.4) * rad, rad * 0.13, Color(1, 1, 1, 0.9))
	ci.draw_arc(c, rad, 0.0, TAU, 28, col.darkened(0.5), maxf(1.0, rad * 0.06), true)


## A convex piece (a star, a heart, a wing) with a lit body shifted toward the upper left and a glow, round the middle `m`.
static func _bevel(ci: CanvasItem, pts: PackedVector2Array, col: Color, m := Vector2.ZERO, line := 1.6) -> void:
	ci.draw_colored_polygon(pts, col.darkened(0.3))
	var inner := PackedVector2Array()
	var glow := PackedVector2Array()
	for p in pts:
		inner.append(m + (p - m) * 0.86 + Vector2(-0.05, -0.07) * line * 4.0)
		glow.append(m + (p - m) * 0.42 + Vector2(-0.1, -0.16) * line * 5.0)
	ci.draw_colored_polygon(inner, col.lightened(0.06))
	ci.draw_colored_polygon(glow, Color(col.lightened(0.55), 0.55))
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.55), line, true)


## A tube lying along x (half length `hw`, half height `hh`): shaded across, ridged along, the string's hole in each end.
static func _tube(ci: CanvasItem, hw: float, hh: float, col: Color, ridges: int, slant := 0.0) -> void:
	var back := _oval(Vector2(hw, 0), hh * 0.42, hh, slant)
	ci.draw_colored_polygon(back, col.darkened(0.4))
	# The body in strips from the lit top to the shaded bottom.
	var strips := 9
	for i in strips:
		var u0 := float(i) / strips
		var u1 := float(i + 1) / strips
		var tone := col.lightened(0.28 * (1.0 - u0 * 1.6)) if u0 < 0.5 else col.darkened(0.34 * (u0 - 0.4))
		ci.draw_rect(Rect2(-hw, lerpf(-hh, hh, u0), hw * 2.0, (u1 - u0) * hh * 2.0 + 0.6), tone)
	for k in ridges:
		var y := lerpf(-hh * 0.85, hh * 0.85, (k + 0.5) / ridges)
		ci.draw_line(Vector2(-hw, y), Vector2(hw, y), col.darkened(0.3), maxf(1.0, hh * 0.07), true)
		ci.draw_line(Vector2(-hw, y - hh * 0.07), Vector2(hw, y - hh * 0.07), Color(col.lightened(0.5), 0.45), maxf(1.0, hh * 0.05), true)
	ci.draw_line(Vector2(-hw, -hh), Vector2(hw, -hh), col.darkened(0.5), maxf(1.0, hh * 0.06), true)
	ci.draw_line(Vector2(-hw, hh), Vector2(hw, hh), col.darkened(0.55), maxf(1.0, hh * 0.06), true)
	# The open end, with the hole.
	var rim := _oval(Vector2(-hw, 0), hh * 0.42, hh, slant)
	ci.draw_colored_polygon(rim, col.lightened(0.2))
	ci.draw_polyline(rim + PackedVector2Array([rim[0]]), col.darkened(0.5), maxf(1.0, hh * 0.07), true)
	ci.draw_colored_polygon(_oval(Vector2(-hw, 0), hh * 0.2, hh * 0.46, slant), Color(0.16, 0.1, 0.06))


## The thin cube of a letter bead: ivory front, a lit top and a shaded side.
static func _tile(ci: CanvasItem, h: float, col: Color) -> void:
	var d := h * 0.28
	ci.draw_colored_polygon(PackedVector2Array([Vector2(h, -h), Vector2(h + d, -h - d), Vector2(h + d, h - d), Vector2(h, h)]), col.darkened(0.35))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-h, -h), Vector2(-h + d, -h - d), Vector2(h + d, -h - d), Vector2(h, -h)]), Color("#FFFFFF").lerp(col, 0.15))
	ci.draw_rect(Rect2(-h, -h, h * 2.0, h * 2.0), Color("#FFFDF7"))
	ci.draw_rect(Rect2(-h, -h, h * 2.0, h * 2.0), col.darkened(0.15), false, maxf(1.6, h * 0.1))
	ci.draw_rect(Rect2(-h + h * 0.16, -h + h * 0.16, h * 1.68, h * 1.68), Color(col, 0.28), false, 1.0)


## A bead centred on `c`, `r` px across, lying along `dir` (the string's direction at that spot).
static func bead(ci: CanvasItem, id: String, c: Vector2, r: float, color: Color, dir: float, seed_ := 1) -> void:
	ci.draw_set_transform(c, dir - (PI / 2.0 if id == "macaroni" else 0.0), Vector2.ONE)
	var w := maxf(1.0, r * 0.06)
	var pasta := Color("#EBC879") if color.s < 0.1 else color
	var paint := color if color.s > 0.05 else Color("#E04F5F")
	match id:
		"macaroni":
			# A curved tube: its dark outer edge, the body, a lit line along the top of the curve, two open ends.
			var arc_pts := PackedVector2Array()
			for k in 17:
				var a := -PI * 0.58 + PI * 1.16 * k / 16.0
				arc_pts.append(Vector2(cos(a) * r * 0.55, sin(a) * r * 0.42 + r * 0.14))
			ci.draw_polyline(arc_pts, pasta.darkened(0.45), r * 0.36, true)
			ci.draw_polyline(arc_pts, pasta.darkened(0.12), r * 0.31, true)
			ci.draw_polyline(arc_pts, pasta.lightened(0.08), r * 0.22, true)
			var lit := PackedVector2Array()
			for p in arc_pts:
				lit.append(p + Vector2(-0.02, -0.07) * r)
			ci.draw_polyline(lit, Color(pasta.lightened(0.55), 0.7), r * 0.07, true)
			for e in [arc_pts[0], arc_pts[arc_pts.size() - 1]]:
				ci.draw_circle(e, r * 0.17, pasta.lightened(0.2))
				ci.draw_arc(e, r * 0.17, 0.0, TAU, 14, pasta.darkened(0.5), w, true)
				ci.draw_circle(e, r * 0.085, Color(0.16, 0.1, 0.06))
		"penne":
			_tube(ci, r * 0.52, r * 0.28, pasta, 5, 0.5)
		"rigatoni":
			_tube(ci, r * 0.5, r * 0.31, pasta, 7)
		"roue":
			# A wheel of pasta: a thick rim, six spokes with the gaps between them showing the table, a hub with its hole.
			ci.draw_circle(Vector2(1.0, 1.6), r * 0.5, Color(0, 0, 0, 0.18))
			ci.draw_circle(Vector2.ZERO, r * 0.5, pasta.darkened(0.4))
			ci.draw_circle(Vector2(-0.015, -0.02) * r, r * 0.47, pasta.lightened(0.06))
			for k in 6:
				var a0 := TAU * k / 6.0 + 0.22
				var a1 := TAU * (k + 1) / 6.0 - 0.22
				var gap := PackedVector2Array()
				for j in 7:
					gap.append(Vector2.from_angle(lerpf(a0, a1, j / 6.0)) * r * 0.37)
				for j in 7:
					gap.append(Vector2.from_angle(lerpf(a1, a0, j / 6.0)) * r * 0.16)
				ci.draw_colored_polygon(gap, Color(0.2, 0.14, 0.09, 0.85))
			ci.draw_circle(Vector2.ZERO, r * 0.15, pasta.lightened(0.18))
			ci.draw_arc(Vector2.ZERO, r * 0.5, 0.0, TAU, 28, pasta.darkened(0.5), w * 1.2, true)
			ci.draw_arc(Vector2.ZERO, r * 0.4, PI * 1.1, PI * 1.7, 10, Color(pasta.lightened(0.55), 0.7), w * 1.4, true)
			ci.draw_circle(Vector2.ZERO, r * 0.06, Color(0.16, 0.1, 0.06))
		"farfalle":
			# A bow tie: two crimped wings pinched in the middle.
			for s in [-1.0, 1.0]:
				var wing := PackedVector2Array([Vector2(s * r * 0.05, -r * 0.08)])
				for k in 9:
					var u := float(k) / 8.0
					var crimp := (r * 0.035) if k % 2 == 0 else 0.0
					wing.append(Vector2(s * (r * 0.54 - crimp), lerpf(-r * 0.4, r * 0.4, u)))
				wing.append(Vector2(s * r * 0.05, r * 0.08))
				_bevel(ci, wing, pasta, Vector2(s * r * 0.3, 0), w * 1.2)
				for k in 3:
					ci.draw_line(Vector2(s * r * 0.1, (k - 1) * r * 0.05), Vector2(s * r * 0.46, (k - 1) * r * 0.22), pasta.darkened(0.28), w, true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.09, -r * 0.14), Vector2(r * 0.09, -r * 0.14), Vector2(r * 0.07, r * 0.14), Vector2(-r * 0.07, r * 0.14)]), pasta.darkened(0.22))
			ci.draw_line(Vector2(-r * 0.04, -r * 0.12), Vector2(-r * 0.04, r * 0.12), Color(pasta.lightened(0.5), 0.6), w, true)
		"ronde":
			ci.draw_circle(Vector2(r * 0.05, r * 0.1), r * 0.4, Color(0, 0, 0, 0.2))
			_ball(ci, Vector2.ZERO, r * 0.4, paint)
		"cube":
			# A small cube with three faces: the lit top, the front, the shaded side.
			var h := r * 0.28
			var d := r * 0.14
			var cube := color if color.s > 0.05 else Color("#FFD23F")
			ci.draw_colored_polygon(PackedVector2Array([Vector2(h, -h), Vector2(h + d, -h - d), Vector2(h + d, h - d), Vector2(h, h)]), cube.darkened(0.38))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-h, -h), Vector2(-h + d, -h - d), Vector2(h + d, -h - d), Vector2(h, -h)]), cube.lightened(0.28))
			ci.draw_rect(Rect2(-h, -h, h * 2.0, h * 2.0), cube)
			ci.draw_rect(Rect2(-h * 0.8, -h * 0.8, h * 0.9, h * 0.5), Color(1, 1, 1, 0.28))
			ci.draw_rect(Rect2(-h, -h, h * 2.0, h * 2.0), cube.darkened(0.5), false, w * 1.2)
			ci.draw_polyline(PackedVector2Array([Vector2(h, -h), Vector2(h + d, -h - d), Vector2(-h + d, -h - d)]), cube.darkened(0.5), w, true)
		"etoile":
			var star := PackedVector2Array()
			for k in 10:
				star.append(Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * r * (0.5 if k % 2 == 0 else 0.25))
			_bevel(ci, star, color if color.s > 0.05 else Color("#FFD23F"))
		"coeur":
			_bevel(ci, shape_points("coeur", r * 0.9), color if color.s > 0.05 else Color("#FF7BA3"), Vector2(0, -r * 0.04))
		"fleur":
			var petal := color if color.s > 0.05 else Color("#FF7BA3")
			for k in 5:
				var pc := Vector2.from_angle(-PI / 2.0 + TAU * k / 5.0) * r * 0.25
				_ball(ci, pc, r * 0.19, petal, false)
			_ball(ci, Vector2.ZERO, r * 0.14, Color("#FFD23F"))
			ci.draw_circle(Vector2(r * 0.03, r * 0.02), r * 0.025, Color("#B8860B"))
		"bois":
			# A wooden bead: a ball of pale wood with the rings of its grain.
			var wood := Color("#D9A05B")
			ci.draw_circle(Vector2(r * 0.05, r * 0.1), r * 0.4, Color(0, 0, 0, 0.2))
			_ball(ci, Vector2.ZERO, r * 0.4, wood, false)
			for k in 3:
				ci.draw_arc(Vector2(-r * 0.06, -r * 0.05), r * (0.1 + k * 0.08), 0.5 + k * 0.3, 4.6 + k * 0.3, 12, Color("#8A5A2B", 0.55), w, true)
			ci.draw_circle(Vector2(-r * 0.14, -r * 0.16), r * 0.06, Color(1, 1, 1, 0.55))
		"lettre":
			_tile(ci, r * 0.38, color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
