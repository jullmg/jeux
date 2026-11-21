class_name StampArt
extends RefCounted
## The drawing pad's stamps (`DrawingPad`): little outlined pictures drawn on any CanvasItem, centred on `c`, about `r`
## px from the middle to the edge. The first fourteen are `CuteArt`'s; the rest are drawn here. `CATEGORIES` is how the
## pad shows them. **A new stamp = its id in a category + a case in `draw`.** Positions inside a case are in units of `r`.

const LINE := CuteArt.LINE
const PINK := Color("#F2A7B4")

const CATEGORIES := [
	["animaux", "Animaux", ["chat", "chien", "hamster", "capybara", "lapin", "oiseau", "poisson", "tortue", "hibou", "renard",
		"ours", "licorne", "coccinelle", "abeille", "ecureuil", "dino"]],
	["nature", "Ciel et nature", ["soleil", "lune", "nuage", "arc", "etoile", "flocon", "goutte", "eclair", "fleur", "tulipe",
		"feuille", "champignon", "sapin", "bonhomme"]],
	["bouffe", "Bouffe", ["pomme", "fraise", "carotte", "pizza", "glace", "cupcake", "biscuit", "citrouille"]],
	["choses", "Choses", ["coeur", "maison", "moi", "ballon", "couronne", "chateau", "fusee", "bateau", "fantome", "cadeau", "velo"]],
]


static func all_ids() -> Array:
	var out := []
	for cat: Array in CATEGORIES:
		out.append_array(cat[2])
	return out


static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, color: Color) -> void:
	var w := maxf(1.0, r * 0.05)
	match id:
		# ── CuteArt's ──
		"etoile":
			CuteArt.star(ci, c, r, color)
		"coeur":
			CuteArt.heart(ci, c, r * 0.9, color)
		"fleur":
			CuteArt.flower(ci, c, r * 0.9, color)
		"soleil":
			CuteArt.sun(ci, c, r * 0.6)
		"lune":
			_moon(ci, c, r)
		"nuage":
			_cloud(ci, c, r)
		"arc":
			var bands := [Color("#E04F5F"), Color("#FF8A3D"), Color("#FFD23F"), Color("#7CCB5A"), Color("#4FA3E0"), Color("#7E57C2")]
			var bw := r * 0.14
			for i in bands.size():
				ci.draw_arc(c + Vector2(0, r * 0.45), r - i * bw, PI, TAU, 32, bands[i], bw + 0.5, true)
		"papillon":
			for side in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(side * 0.45, -0.25), Vector2(0.45, 0.4), color, w)
				_e(ci, c, r, Vector2(side * 0.38, 0.32), Vector2(0.3, 0.26), color.lightened(0.3), w)
				ci.draw_circle(c + Vector2(side * 0.5, -0.3) * r, r * 0.1, Color.WHITE)
				ci.draw_line(c + Vector2(0, -0.45) * r, c + Vector2(side * 0.25, -0.85) * r, LINE, w, true)
			_e(ci, c, r, Vector2.ZERO, Vector2(0.1, 0.5), LINE, w)
		"chat":
			CuteArt.cat_head(ci, c, r * 0.85, Color("#F2A65A"))
		"chien":
			CuteArt.dog_head(ci, c, r * 0.85, Color("#D8B48A"), Color("#8D6E63"))
		"hamster":
			CuteArt.hamster_head(ci, c, r * 0.8)
		"capybara":
			CuteArt.capybara_head(ci, c, r * 0.85)
		"maison":
			CuteArt.house(ci, c, r * 0.85)
		"moi":
			CuteArt.me(ci, c, r * 0.9)
		# ── Animaux ──
		"lapin":
			var fur := Color("#F4EEE6")
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.4, -0.8), Vector2(0.2, 0.55), fur, w)
				_e(ci, c, r, Vector2(s * 0.4, -0.78), Vector2(0.1, 0.4), PINK, 0.0)
			_e(ci, c, r, Vector2(0, 0.15), Vector2(0.85, 0.72), fur, w)
			_eyes(ci, c, r, 0.3, -0.02)
			_e(ci, c, r, Vector2(0, 0.16), Vector2(0.11, 0.08), PINK, w)
			_mouth(ci, c, r, Vector2(0, 0.27), 0.13, w)
			_cheeks(ci, c, r, 0.5, 0.2)
		"oiseau":
			_p(ci, c, r, [Vector2(-0.6, 0.05), Vector2(-1.05, -0.2), Vector2(-1.0, 0.3), Vector2(-0.55, 0.3)], color.darkened(0.2), w)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.78, 0.62), color, w)
			_e(ci, c, r, Vector2(-0.05, 0.22), Vector2(0.5, 0.3), color.lightened(0.3), 0.0)
			_p(ci, c, r, [Vector2(0.66, -0.05), Vector2(1.05, 0.1), Vector2(0.66, 0.22)], Color("#F29B30"), w)
			_dot(ci, c + Vector2(0.38, -0.12) * r, r * 0.09, LINE)
			_e(ci, c, r, Vector2(-0.15, 0.1), Vector2(0.35, 0.2), color.darkened(0.15), w)
			ci.draw_line(c + Vector2(-0.1, 0.7) * r, c + Vector2(-0.1, 0.95) * r, Color("#F29B30"), w * 1.5, true)
			ci.draw_line(c + Vector2(0.2, 0.68) * r, c + Vector2(0.2, 0.95) * r, Color("#F29B30"), w * 1.5, true)
		"poisson":
			_p(ci, c, r, [Vector2(-0.55, 0.0), Vector2(-1.05, -0.45), Vector2(-1.05, 0.45)], color.darkened(0.15), w)
			_p(ci, c, r, [Vector2(-0.1, -0.5), Vector2(0.2, -0.85), Vector2(0.4, -0.45)], color.darkened(0.15), w)
			_e(ci, c, r, Vector2(0.05, 0.0), Vector2(0.7, 0.5), color, w)
			for k in 3:
				ci.draw_arc(c + Vector2(-0.3 + k * 0.22, 0.08) * r, r * 0.17, -1.1, 1.1, 8, color.darkened(0.3), w * 0.8, true)
			_dot(ci, c + Vector2(0.45, -0.1) * r, r * 0.1, Color.WHITE)
			_dot(ci, c + Vector2(0.47, -0.1) * r, r * 0.055, LINE)
			_mouth(ci, c, r, Vector2(0.6, 0.12), 0.08, w)
		"tortue":
			var green := Color("#7CCB5A")
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.45, 0.55), Vector2(0.2, 0.22), green, w)
			_p(ci, c, r, [Vector2(-0.9, 0.2), Vector2(-1.15, 0.35), Vector2(-0.88, 0.4)], green, w)
			_e(ci, c, r, Vector2(0.95, 0.05), Vector2(0.3, 0.26), green, w)
			_dot(ci, c + Vector2(1.05, 0.0) * r, r * 0.05, LINE)
			var shell := PackedVector2Array()
			for k in 21:
				var a := PI + PI * k / 20.0
				shell.append(c + Vector2(cos(a) * 0.85, sin(a) * 0.85 + 0.55) * r)
			ci.draw_colored_polygon(shell, Color("#3E8E5A"))
			ci.draw_polyline(shell, LINE, w, true)
			ci.draw_line(c + Vector2(-0.85, 0.55) * r, c + Vector2(0.85, 0.55) * r, LINE, w, true)
			for p: Vector2 in [Vector2(0, 0.0), Vector2(-0.45, 0.2), Vector2(0.45, 0.2)]:
				_e(ci, c, r, p, Vector2(0.2, 0.15), Color("#7CCB5A"), w * 0.8)
		"hibou":
			var brown := Color("#9C6B3F")
			_p(ci, c, r, [Vector2(-0.7, -0.5), Vector2(-0.8, -1.0), Vector2(-0.35, -0.7)], brown, w)
			_p(ci, c, r, [Vector2(0.7, -0.5), Vector2(0.8, -1.0), Vector2(0.35, -0.7)], brown, w)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.82, 0.88), brown, w)
			_e(ci, c, r, Vector2(0, 0.45), Vector2(0.5, 0.42), Color("#E8CFA6"), 0.0)
			for k in 3:
				ci.draw_arc(c + Vector2(0, 0.28 + k * 0.17) * r, r * 0.2, 0.3, PI - 0.3, 8, brown.darkened(0.2), w * 0.8, true)
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.33, -0.18), Vector2(0.27, 0.27), Color.WHITE, w)
				_dot(ci, c + Vector2(s * 0.33, -0.16) * r, r * 0.12, LINE)
				_dot(ci, c + Vector2(s * 0.37, -0.2) * r, r * 0.04, Color.WHITE)
			_p(ci, c, r, [Vector2(-0.1, -0.02), Vector2(0.1, -0.02), Vector2(0, 0.17)], Color("#F29B30"), w)
		"renard":
			var orange := Color("#E8812E")
			for s in [-1.0, 1.0]:
				_p(ci, c, r, [Vector2(s * 0.85, -0.2), Vector2(s * 0.8, -1.05), Vector2(s * 0.25, -0.6)], orange, w)
				_p(ci, c, r, [Vector2(s * 0.7, -0.4), Vector2(s * 0.68, -0.85), Vector2(s * 0.36, -0.58)], Color("#3A2A2A"), 0.0)
			_p(ci, c, r, [Vector2(-0.95, -0.35), Vector2(0, -0.6), Vector2(0.95, -0.35), Vector2(0.55, 0.45), Vector2(0, 0.9),
				Vector2(-0.55, 0.45)], orange, w)
			_p(ci, c, r, [Vector2(-0.9, -0.1), Vector2(-0.2, 0.2), Vector2(0, 0.88), Vector2(-0.52, 0.45)], Color.WHITE, 0.0)
			_p(ci, c, r, [Vector2(0.9, -0.1), Vector2(0.2, 0.2), Vector2(0, 0.88), Vector2(0.52, 0.45)], Color.WHITE, 0.0)
			_eyes(ci, c, r, 0.34, -0.15)
			_dot(ci, c + Vector2(0, 0.78) * r, r * 0.11, LINE)
		"ours":
			var bear := Color("#A87444")
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.68, -0.62), Vector2(0.3, 0.3), bear, w)
				_e(ci, c, r, Vector2(s * 0.68, -0.62), Vector2(0.15, 0.15), Color("#E8CFA6"), 0.0)
			_e(ci, c, r, Vector2(0, 0.05), Vector2(0.92, 0.85), bear, w)
			_e(ci, c, r, Vector2(0, 0.3), Vector2(0.42, 0.34), Color("#E8CFA6"), w * 0.8)
			_eyes(ci, c, r, 0.35, -0.15)
			_e(ci, c, r, Vector2(0, 0.17), Vector2(0.14, 0.1), LINE, 0.0)
			_mouth(ci, c, r, Vector2(0, 0.32), 0.12, w)
		"licorne":
			var rainbow := [Color("#E04F5F"), Color("#FFD23F"), Color("#7CCB5A"), Color("#4FA3E0"), Color("#7E57C2")]
			for k in 5:
				_e(ci, c, r, Vector2(-0.75 - (k % 2) * 0.12, -0.55 + k * 0.28), Vector2(0.2, 0.2), rainbow[k], w * 0.7)
			_p(ci, c, r, [Vector2(-0.1, -0.5), Vector2(-0.2, -0.95), Vector2(0.25, -0.62)], Color.WHITE, w)
			_e(ci, c, r, Vector2(0.0, 0.15), Vector2(0.78, 0.72), Color.WHITE, w)
			_p(ci, c, r, [Vector2(-0.12, -0.45), Vector2(0.0, -1.2), Vector2(0.12, -0.45)], Color("#FFD23F"), w)
			_eyes(ci, c, r, 0.3, 0.0)
			_e(ci, c, r, Vector2(0, 0.42), Vector2(0.3, 0.2), Color("#F7E3EA"), w * 0.8)
			_dot(ci, c + Vector2(-0.1, 0.42) * r, r * 0.035, LINE)
			_dot(ci, c + Vector2(0.1, 0.42) * r, r * 0.035, LINE)
			_cheeks(ci, c, r, 0.5, 0.15)
		"coccinelle":
			ci.draw_line(c + Vector2(-0.2, -0.75) * r, c + Vector2(-0.4, -1.0) * r, LINE, w, true)
			ci.draw_line(c + Vector2(0.2, -0.75) * r, c + Vector2(0.4, -1.0) * r, LINE, w, true)
			_e(ci, c, r, Vector2(0, -0.55), Vector2(0.38, 0.3), Color("#3A3A48"), w)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.88, 0.85), Color("#E04F5F"), w)
			ci.draw_line(c + Vector2(0, -0.72) * r, c + Vector2(0, 0.95) * r, LINE, w * 1.3, true)
			for p: Vector2 in [Vector2(-0.45, -0.1), Vector2(0.45, -0.1), Vector2(-0.5, 0.45), Vector2(0.5, 0.45), Vector2(-0.2, 0.7), Vector2(0.2, 0.7)]:
				_dot(ci, c + p * r, r * 0.13, LINE)
			_dot(ci, c + Vector2(-0.14, -0.58) * r, r * 0.07, Color.WHITE)
			_dot(ci, c + Vector2(0.14, -0.58) * r, r * 0.07, Color.WHITE)
		"abeille":
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.3, -0.62), Vector2(0.28, 0.42), Color(0.75, 0.9, 1.0, 0.85), w * 0.8)
			_p(ci, c, r, [Vector2(0.78, 0.05), Vector2(1.1, 0.1), Vector2(0.78, 0.2)], LINE, w * 0.6)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.85, 0.58), Color("#FFD23F"), w)
			for x: float in [-0.35, 0.1, 0.5]:
				var h1 := 0.58 * sqrt(maxf(0.0, 1.0 - pow(x / 0.85, 2.0)))
				var h2 := 0.58 * sqrt(maxf(0.0, 1.0 - pow((x + 0.17) / 0.85, 2.0)))
				_p(ci, c, r, [Vector2(x, 0.1 - h1), Vector2(x + 0.17, 0.1 - h2), Vector2(x + 0.17, 0.1 + h2), Vector2(x, 0.1 + h1)], LINE, 0.0)
			_dot(ci, c + Vector2(-0.6, 0.0) * r, r * 0.06, LINE)
			_dot(ci, c + Vector2(-0.62, 0.0) * r, r * 0.06, LINE)
			_dot(ci, c + Vector2(-0.58, -0.1) * r, r * 0.05, LINE)
			_mouth(ci, c, r, Vector2(-0.58, 0.18), 0.1, w)
		"ecureuil":
			var fur := Color("#B8743C")
			_e(ci, c, r, Vector2(0.55, -0.1), Vector2(0.45, 0.85), fur, w)
			_e(ci, c, r, Vector2(0.55, -0.05), Vector2(0.24, 0.6), Color("#E8B27A"), 0.0)
			_e(ci, c, r, Vector2(-0.05, 0.4), Vector2(0.55, 0.5), fur, w)
			_e(ci, c, r, Vector2(-0.12, 0.5), Vector2(0.3, 0.3), Color("#F0D9B5"), 0.0)
			_e(ci, c, r, Vector2(-0.3, -0.35), Vector2(0.4, 0.38), fur, w)
			_p(ci, c, r, [Vector2(-0.45, -0.6), Vector2(-0.5, -0.95), Vector2(-0.25, -0.68)], fur, w)
			_dot(ci, c + Vector2(-0.42, -0.4) * r, r * 0.07, LINE)
			_dot(ci, c + Vector2(-0.64, -0.3) * r, r * 0.07, LINE)
			_e(ci, c, r, Vector2(-0.12, 0.22), Vector2(0.14, 0.17), Color("#8D5A2B"), w * 0.8)
		"dino":
			var g := Color("#7CCB5A")
			for k in 4:
				_p(ci, c, r, [Vector2(-0.4 + k * 0.28, -0.22 - (0.05 if k % 2 == 0 else 0.0)), Vector2(-0.3 + k * 0.28, -0.55),
					Vector2(-0.12 + k * 0.28, -0.2)], Color("#F29B30"), w)
			_p(ci, c, r, [Vector2(-0.55, 0.2), Vector2(-1.1, 0.5), Vector2(-0.5, 0.5)], g, w)
			for s in [-0.3, 0.3]:
				_p(ci, c, r, [Vector2(s - 0.13, 0.5), Vector2(s + 0.13, 0.5), Vector2(s + 0.13, 0.95), Vector2(s - 0.13, 0.95)], g.darkened(0.15), w)
			_e(ci, c, r, Vector2(0, 0.2), Vector2(0.75, 0.45), g, w)
			_p(ci, c, r, [Vector2(0.4, 0.05), Vector2(0.62, -0.5), Vector2(0.88, -0.45), Vector2(0.72, 0.15)], g, w)
			_e(ci, c, r, Vector2(0.78, -0.62), Vector2(0.32, 0.25), g, w)
			_dot(ci, c + Vector2(0.84, -0.7) * r, r * 0.06, LINE)
			_mouth(ci, c, r, Vector2(0.9, -0.55), 0.07, w * 0.8)
			_e(ci, c, r, Vector2(0.0, 0.35), Vector2(0.4, 0.2), Color("#C9EDB3"), 0.0)
		# ── Ciel et nature ──
		"flocon":
			var ice := Color("#7FB8E6")
			for k in 6:
				var d := Vector2.from_angle(TAU * k / 6.0 - PI / 2.0)
				ci.draw_line(c, c + d * r, ice, w * 1.8, true)
				for t: float in [0.45, 0.72]:
					var base := c + d * r * t
					ci.draw_line(base, base + d.rotated(0.8) * r * 0.25, ice, w * 1.4, true)
					ci.draw_line(base, base + d.rotated(-0.8) * r * 0.25, ice, w * 1.4, true)
			_dot(ci, c, r * 0.12, Color.WHITE)
		"goutte":
			var pts := [Vector2(0, -1.0)]
			for k in 25:
				var a := -PI * 0.35 + PI * 1.7 * k / 24.0
				pts.append(Vector2(cos(a) * 0.62, 0.35 + sin(a) * 0.62))
			_p(ci, c, r, pts, Color("#4FA3E0"), w)
			_e(ci, c, r, Vector2(-0.22, 0.3), Vector2(0.1, 0.18), Color(1, 1, 1, 0.7), 0.0)
		"eclair":
			_p(ci, c, r, [Vector2(0.15, -1.0), Vector2(-0.6, 0.15), Vector2(-0.1, 0.15), Vector2(-0.3, 1.0), Vector2(0.65, -0.2),
				Vector2(0.1, -0.2), Vector2(0.45, -1.0)], Color("#FFD23F"), w)
		"tulipe":
			ci.draw_line(c + Vector2(0, 0.0) * r, c + Vector2(0, 1.0) * r, Color("#3E8E5A"), w * 2.0, true)
			_p(ci, c, r, [Vector2(0, 0.95), Vector2(-0.6, 0.35), Vector2(-0.3, 0.7), Vector2(0, 0.8)], Color("#5FAE4F"), w)
			_p(ci, c, r, [Vector2(0, 0.95), Vector2(0.6, 0.35), Vector2(0.3, 0.7), Vector2(0, 0.8)], Color("#5FAE4F"), w)
			var tc := color if color.s > 0.2 else Color("#E04F5F")
			_p(ci, c, r, [Vector2(-0.55, -0.55), Vector2(-0.3, -0.2), Vector2(-0.2, -0.8), Vector2(0, -0.2)], tc.lightened(0.15), w)
			_e(ci, c, r, Vector2(0, -0.2), Vector2(0.52, 0.55), tc, w)
			_p(ci, c, r, [Vector2(-0.5, -0.5), Vector2(-0.28, -0.95), Vector2(0, -0.45), Vector2(0.28, -0.95), Vector2(0.5, -0.5), Vector2(0, -0.3)], tc, w)
		"feuille":
			var half := [Vector2(0.12, -0.62), Vector2(0.42, -0.78), Vector2(0.34, -0.3), Vector2(0.95, -0.42), Vector2(0.68, 0.08),
				Vector2(0.88, 0.3), Vector2(0.3, 0.38), Vector2(0.36, 0.62), Vector2(0.06, 0.52)]
			var pts: Array = [Vector2(0, -1.0)]
			pts.append_array(half)
			var mirror := half.duplicate()
			mirror.reverse()
			for p: Vector2 in mirror:
				pts.append(Vector2(-p.x, p.y))
			_p(ci, c, r, pts, color if color.s > 0.3 and color.v > 0.3 else Color("#D9542B"), w)
			ci.draw_line(c + Vector2(0, -0.6) * r, c + Vector2(0, 1.0) * r, Color("#8D3A1E"), w * 1.5, true)
		"champignon":
			ci.draw_line(c + Vector2(-0.9, 0.95) * r, c + Vector2(0.9, 0.95) * r, Color("#5FAE4F"), w * 2.0, true)
			_p(ci, c, r, [Vector2(-0.25, 0.1), Vector2(0.25, 0.1), Vector2(0.3, 0.92), Vector2(-0.3, 0.92)], Color("#F4E6CF"), w)
			var cap := PackedVector2Array()
			for k in 21:
				var a := PI + PI * k / 20.0
				cap.append(c + Vector2(cos(a) * 0.95, sin(a) * 0.8 + 0.2) * r)
			ci.draw_colored_polygon(cap, Color("#E04F5F"))
			ci.draw_polyline(cap, LINE, w, true)
			ci.draw_line(c + Vector2(-0.95, 0.2) * r, c + Vector2(0.95, 0.2) * r, LINE, w, true)
			for p: Vector3 in [Vector3(-0.45, -0.25, 0.17), Vector3(0.1, -0.5, 0.2), Vector3(0.5, -0.15, 0.15)]:
				_dot(ci, c + Vector2(p.x, p.y) * r, r * p.z, Color.WHITE)
		"sapin":
			_p(ci, c, r, [Vector2(-0.14, 0.7), Vector2(0.14, 0.7), Vector2(0.14, 1.0), Vector2(-0.14, 1.0)], Color("#8D5A2B"), w)
			var tiers := [[0.05, 0.85, 0.45], [-0.3, 0.7, 0.35], [-0.62, 0.52, 0.3]]
			for t: Array in tiers:
				_p(ci, c, r, [Vector2(0, t[0] - t[2]), Vector2(t[1], t[0] + t[2] + 0.2), Vector2(-t[1], t[0] + t[2] + 0.2)], Color("#3E8E5A"), w)
			CuteArt.star(ci, c + Vector2(0, -0.98) * r, r * 0.2, Color("#FFD23F"))
			for p: Vector2 in [Vector2(-0.3, 0.55), Vector2(0.35, 0.4), Vector2(0.0, 0.2), Vector2(-0.2, -0.1), Vector2(0.18, -0.35)]:
				_dot(ci, c + p * r, r * 0.07, Color("#E04F5F"))
		"bonhomme":
			_e(ci, c, r, Vector2(0, 0.55), Vector2(0.55, 0.45), Color.WHITE, w)
			_e(ci, c, r, Vector2(0, -0.1), Vector2(0.4, 0.38), Color.WHITE, w)
			ci.draw_line(c + Vector2(-0.4, 0.45) * r, c + Vector2(-0.95, 0.15) * r, Color("#8D5A2B"), w * 1.5, true)
			ci.draw_line(c + Vector2(0.4, 0.45) * r, c + Vector2(0.95, 0.2) * r, Color("#8D5A2B"), w * 1.5, true)
			_p(ci, c, r, [Vector2(-0.3, -0.38), Vector2(0.3, -0.38), Vector2(0.3, -0.28), Vector2(-0.3, -0.28)], Color("#E04F5F"), w)
			_p(ci, c, r, [Vector2(-0.28, -0.42), Vector2(-0.22, -0.9), Vector2(0.22, -0.9), Vector2(0.28, -0.42)], Color("#3A3A48"), w)
			_dot(ci, c + Vector2(-0.14, -0.1) * r, r * 0.05, LINE)
			_dot(ci, c + Vector2(0.14, -0.1) * r, r * 0.05, LINE)
			_p(ci, c, r, [Vector2(0, -0.02), Vector2(0.3, 0.04), Vector2(0, 0.09)], Color("#F29B30"), w * 0.8)
			for y: float in [0.38, 0.58, 0.78]:
				_dot(ci, c + Vector2(0, y) * r, r * 0.05, LINE)
		# ── Bouffe ──
		"pomme":
			var red := color if color.s > 0.3 and color.v > 0.3 else Color("#E04F5F")
			_e(ci, c, r, Vector2(-0.28, 0.2), Vector2(0.58, 0.68), red, w)
			_e(ci, c, r, Vector2(0.28, 0.2), Vector2(0.58, 0.68), red, w)
			_e(ci, c, r, Vector2(0.0, 0.22), Vector2(0.5, 0.62), red, 0.0)
			ci.draw_line(c + Vector2(0, -0.35) * r, c + Vector2(0.1, -0.8) * r, Color("#8D5A2B"), w * 2.0, true)
			_p(ci, c, r, [Vector2(0.1, -0.7), Vector2(0.6, -0.95), Vector2(0.55, -0.55)], Color("#5FAE4F"), w)
			_e(ci, c, r, Vector2(-0.4, 0.0), Vector2(0.1, 0.2), Color(1, 1, 1, 0.55), 0.0)
		"fraise":
			_p(ci, c, r, [Vector2(-0.75, -0.45), Vector2(0.75, -0.45), Vector2(0.55, 0.3), Vector2(0, 1.0), Vector2(-0.55, 0.3)], Color("#E04F5F"), w)
			for p: Vector2 in [Vector2(-0.4, -0.1), Vector2(0.0, -0.15), Vector2(0.4, -0.1), Vector2(-0.2, 0.25), Vector2(0.2, 0.25), Vector2(0, 0.6), Vector2(-0.45, 0.2), Vector2(0.45, 0.2)]:
				_e(ci, c, r, p, Vector2(0.05, 0.08), Color("#FFE27A"), 0.0)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.55
				_p(ci, c, r, [Vector2(0, -0.5), Vector2.from_angle(a - 0.3) * 0.55 + Vector2(0, -0.5), Vector2.from_angle(a + 0.3) * 0.55 + Vector2(0, -0.5)], Color("#5FAE4F"), w * 0.8)
			ci.draw_line(c + Vector2(0, -0.6) * r, c + Vector2(0, -0.95) * r, Color("#3E8E5A"), w * 1.6, true)
		"carotte":
			for k in 3:
				var a := -PI / 2.0 + (k - 1) * 0.5
				_p(ci, c, r, [Vector2(0, -0.5) + Vector2.from_angle(a) * 0.55, Vector2(-0.07, -0.5), Vector2(0.07, -0.5)], Color("#5FAE4F"), w * 0.8)
			_p(ci, c, r, [Vector2(-0.3, -0.55), Vector2(0.3, -0.55), Vector2(0.05, 1.0)], Color("#F29B30"), w)
			for y: float in [-0.25, 0.05, 0.35]:
				ci.draw_line(c + Vector2(-0.18 + (y + 0.25) * 0.12, y) * r, c + Vector2(0.0 + (y + 0.25) * 0.05, y) * r, Color("#C7691B"), w, true)
		"pizza":
			var tip := Vector2(0, 0.95)
			_p(ci, c, r, [Vector2(-0.85, -0.65), Vector2(0.85, -0.65), tip], Color("#FFD23F"), w)
			_p(ci, c, r, [Vector2(-0.95, -0.85), Vector2(0.95, -0.85), Vector2(0.88, -0.58), Vector2(-0.88, -0.58)], Color("#D9A05B"), w)
			for p: Vector3 in [Vector3(-0.3, -0.3, 0.17), Vector3(0.3, -0.25, 0.15), Vector3(0.0, 0.1, 0.16), Vector3(0.0, 0.5, 0.1)]:
				_dot(ci, c + Vector2(p.x, p.y) * r, r * p.z, Color("#D9342B"))
		"glace":
			_p(ci, c, r, [Vector2(-0.4, 0.0), Vector2(0.4, 0.0), Vector2(0.0, 1.0)], Color("#E3B57B"), w)
			ci.draw_line(c + Vector2(-0.25, 0.15) * r, c + Vector2(0.12, 0.65) * r, Color("#B58A52"), w, true)
			ci.draw_line(c + Vector2(0.25, 0.15) * r, c + Vector2(-0.12, 0.65) * r, Color("#B58A52"), w, true)
			_e(ci, c, r, Vector2(0, -0.0), Vector2(0.5, 0.2), Color("#F7C7D2"), w)
			_e(ci, c, r, Vector2(0, -0.3), Vector2(0.48, 0.42), Color("#F7C7D2"), w)
			_e(ci, c, r, Vector2(0, -0.58), Vector2(0.4, 0.32), Color("#F4F0E6"), w)
			_dot(ci, c + Vector2(0.05, -0.95) * r, r * 0.12, Color("#D9342B"))
		"cupcake":
			_p(ci, c, r, [Vector2(-0.6, 0.15), Vector2(0.6, 0.15), Vector2(0.42, 0.95), Vector2(-0.42, 0.95)], color if color.s > 0.2 else Color("#4FA3E0"), w)
			for x: float in [-0.3, 0.0, 0.3]:
				ci.draw_line(c + Vector2(x * 1.2, 0.2) * r, c + Vector2(x, 0.92) * r, Color(0, 0, 0, 0.25), w, true)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.68, 0.22), Color("#F7C7D2"), w)
			_e(ci, c, r, Vector2(0, -0.18), Vector2(0.5, 0.24), Color("#F7C7D2"), w)
			_e(ci, c, r, Vector2(0, -0.45), Vector2(0.3, 0.22), Color("#F7C7D2"), w)
			_dot(ci, c + Vector2(0.0, -0.78) * r, r * 0.13, Color("#D9342B"))
			for p: Vector2 in [Vector2(-0.3, 0.05), Vector2(0.25, -0.2), Vector2(0.4, 0.1), Vector2(-0.15, -0.3)]:
				_dot(ci, c + p * r, r * 0.04, Color("#FFD23F"))
		"biscuit":
			_e(ci, c, r, Vector2.ZERO, Vector2(0.9, 0.9), Color("#D9A05B"), w)
			for p: Vector2 in [Vector2(-0.35, -0.3), Vector2(0.15, -0.1), Vector2(-0.2, 0.3), Vector2(0.4, 0.35), Vector2(-0.55, 0.05), Vector2(0.05, 0.62)]:
				_e(ci, c, r, p, Vector2(0.11, 0.09), Color("#5B3A29"), 0.0)
		"citrouille":
			ci.draw_line(c + Vector2(0, -0.6) * r, c + Vector2(0.05, -0.95) * r, Color("#3E8E5A"), w * 3.0, true)
			for s in [-1.0, 1.0]:
				_e(ci, c, r, Vector2(s * 0.5, 0.1), Vector2(0.45, 0.7), Color("#E8812E"), w)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.5, 0.72), Color("#F29B30"), w)
			_p(ci, c, r, [Vector2(-0.35, -0.1), Vector2(-0.12, -0.1), Vector2(-0.23, -0.35)], Color("#3A2A2A"), 0.0)
			_p(ci, c, r, [Vector2(0.35, -0.1), Vector2(0.12, -0.1), Vector2(0.23, -0.35)], Color("#3A2A2A"), 0.0)
			_p(ci, c, r, [Vector2(-0.4, 0.25), Vector2(-0.2, 0.2), Vector2(-0.1, 0.4), Vector2(0.0, 0.2), Vector2(0.1, 0.4), Vector2(0.2, 0.2), Vector2(0.4, 0.25),
				Vector2(0.25, 0.62), Vector2(-0.25, 0.62)], Color("#3A2A2A"), 0.0)
		# ── Choses ──
		"ballon":
			ci.draw_line(c + Vector2(0, 0.55) * r, c + Vector2(-0.15, 0.8) * r, LINE, w * 0.8, true)
			ci.draw_line(c + Vector2(-0.15, 0.8) * r, c + Vector2(0.1, 1.0) * r, LINE, w * 0.8, true)
			_p(ci, c, r, [Vector2(0, 0.5), Vector2(-0.13, 0.65), Vector2(0.13, 0.65)], color, w)
			_e(ci, c, r, Vector2(0, -0.2), Vector2(0.65, 0.75), color, w)
			_e(ci, c, r, Vector2(-0.28, -0.42), Vector2(0.14, 0.22), Color(1, 1, 1, 0.55), 0.0)
		"couronne":
			_p(ci, c, r, [Vector2(-0.9, 0.55), Vector2(-0.95, -0.55), Vector2(-0.45, -0.05), Vector2(0, -0.8), Vector2(0.45, -0.05),
				Vector2(0.95, -0.55), Vector2(0.9, 0.55)], Color("#FFD23F"), w)
			_p(ci, c, r, [Vector2(-0.9, 0.3), Vector2(0.9, 0.3), Vector2(0.9, 0.55), Vector2(-0.9, 0.55)], Color("#F2A23A"), w)
			for p: Vector3 in [Vector3(-0.95, -0.6, 0.1), Vector3(0, -0.85, 0.1), Vector3(0.95, -0.6, 0.1)]:
				_dot(ci, c + Vector2(p.x, p.y) * r, r * p.z, Color("#E04F5F"))
			_dot(ci, c + Vector2(-0.45, 0.42) * r, r * 0.09, Color("#4FA3E0"))
			_dot(ci, c + Vector2(0, 0.42) * r, r * 0.09, Color("#E04F5F"))
			_dot(ci, c + Vector2(0.45, 0.42) * r, r * 0.09, Color("#7CCB5A"))
		"chateau":
			var stone := Color("#C9C3D6")
			for s in [-1.0, 1.0]:
				_p(ci, c, r, [Vector2(s * 0.72 - 0.2, -0.1), Vector2(s * 0.72 + 0.2, -0.1), Vector2(s * 0.72 + 0.2, 0.95), Vector2(s * 0.72 - 0.2, 0.95)], stone, w)
				_p(ci, c, r, [Vector2(s * 0.72 - 0.28, -0.1), Vector2(s * 0.72, -0.75), Vector2(s * 0.72 + 0.28, -0.1)], Color("#E04F5F"), w)
			_p(ci, c, r, [Vector2(-0.55, 0.0), Vector2(-0.4, 0.0), Vector2(-0.4, 0.1), Vector2(-0.2, 0.1), Vector2(-0.2, 0.0), Vector2(0.0, 0.0),
				Vector2(0.0, 0.1), Vector2(0.2, 0.1), Vector2(0.2, 0.0), Vector2(0.4, 0.0), Vector2(0.4, 0.1), Vector2(0.55, 0.1),
				Vector2(0.55, 0.95), Vector2(-0.55, 0.95)], stone.lightened(0.1), w)
			_p(ci, c, r, [Vector2(-0.17, 0.95), Vector2(-0.17, 0.5), Vector2(0, 0.35), Vector2(0.17, 0.5), Vector2(0.17, 0.95)], Color("#8D5A2B"), w)
			ci.draw_line(c + Vector2(-0.72, -0.75) * r, c + Vector2(-0.72, -1.0) * r, LINE, w, true)
			_p(ci, c, r, [Vector2(-0.72, -1.0), Vector2(-0.45, -0.92), Vector2(-0.72, -0.84)], Color("#4FA3E0"), w * 0.8)
			for s in [-1.0, 1.0]:
				_p(ci, c, r, [Vector2(s * 0.72 - 0.04, 0.2), Vector2(s * 0.72 + 0.04, 0.2), Vector2(s * 0.72 + 0.04, 0.4), Vector2(s * 0.72 - 0.04, 0.4)], LINE, 0.0)
		"fusee":
			_p(ci, c, r, [Vector2(-0.5, 0.35), Vector2(-0.95, 0.95), Vector2(-0.3, 0.7)], Color("#E04F5F"), w)
			_p(ci, c, r, [Vector2(0.5, 0.35), Vector2(0.95, 0.95), Vector2(0.3, 0.7)], Color("#E04F5F"), w)
			_p(ci, c, r, [Vector2(-0.18, 0.75), Vector2(0.18, 0.75), Vector2(0.0, 1.2)], Color("#FFD23F"), w)
			_e(ci, c, r, Vector2(0, -0.05), Vector2(0.5, 0.85), Color("#F4F0E6"), w)
			_p(ci, c, r, [Vector2(-0.46, -0.45), Vector2(0, -1.15), Vector2(0.46, -0.45)], Color("#E04F5F"), w)
			_e(ci, c, r, Vector2(0, -0.05), Vector2(0.24, 0.24), Color("#7FB8E6"), w)
			_dot(ci, c + Vector2(-0.08, -0.12) * r, r * 0.06, Color(1, 1, 1, 0.8))
		"bateau":
			ci.draw_line(c + Vector2(0, -0.95) * r, c + Vector2(0, 0.45) * r, LINE, w * 1.5, true)
			_p(ci, c, r, [Vector2(0.05, -0.9), Vector2(0.85, 0.35), Vector2(0.05, 0.35)], Color.WHITE, w)
			_p(ci, c, r, [Vector2(-0.05, -0.6), Vector2(-0.6, 0.35), Vector2(-0.05, 0.35)], Color("#E04F5F"), w)
			_p(ci, c, r, [Vector2(-0.9, 0.45), Vector2(0.9, 0.45), Vector2(0.62, 0.85), Vector2(-0.62, 0.85)], Color("#8D5A2B"), w)
			for k in 4:
				ci.draw_arc(c + Vector2(-0.75 + k * 0.5, 0.95) * r, r * 0.25, PI, TAU, 8, Color("#4FA3E0"), w * 1.4, true)
		"fantome":
			var gh := PackedVector2Array()
			for k in 17:
				var a := PI + PI * k / 16.0
				gh.append(c + Vector2(cos(a) * 0.75, sin(a) * 0.8 - 0.05) * r)
			for k in range(0, 5):
				var x := 0.75 - k * 0.375
				gh.append(c + Vector2(x, -0.05 + 0.95 - (0.0 if k % 2 == 0 else 0.22)) * r)
			ci.draw_colored_polygon(gh, Color.WHITE)
			var ring := gh.duplicate()
			ring.append(gh[0])
			ci.draw_polyline(ring, LINE, w, true)
			_dot(ci, c + Vector2(-0.25, -0.25) * r, r * 0.1, LINE)
			_dot(ci, c + Vector2(0.25, -0.25) * r, r * 0.1, LINE)
			_e(ci, c, r, Vector2(0, 0.1), Vector2(0.1, 0.14), LINE, 0.0)
			_cheeks(ci, c, r, 0.45, -0.02)
		"cadeau":
			var box := color if color.s > 0.25 else Color("#4FA3E0")
			_p(ci, c, r, [Vector2(-0.8, -0.2), Vector2(0.8, -0.2), Vector2(0.8, 0.9), Vector2(-0.8, 0.9)], box, w)
			_p(ci, c, r, [Vector2(-0.9, -0.5), Vector2(0.9, -0.5), Vector2(0.9, -0.2), Vector2(-0.9, -0.2)], box.lightened(0.15), w)
			_p(ci, c, r, [Vector2(-0.12, -0.5), Vector2(0.12, -0.5), Vector2(0.12, 0.9), Vector2(-0.12, 0.9)], Color("#FFD23F"), w * 0.8)
			_e(ci, c, r, Vector2(-0.3, -0.7), Vector2(0.3, 0.2), Color("#FFD23F"), w)
			_e(ci, c, r, Vector2(0.3, -0.7), Vector2(0.3, 0.2), Color("#FFD23F"), w)
			_dot(ci, c + Vector2(0, -0.62) * r, r * 0.1, Color("#F2A23A"))
		"velo":
			for s in [-1.0, 1.0]:
				ci.draw_arc(c + Vector2(s * 0.62, 0.4) * r, r * 0.42, 0.0, TAU, 28, LINE, w * 1.6, true)
				_dot(ci, c + Vector2(s * 0.62, 0.4) * r, r * 0.05, LINE)
			var fr := color if color.s > 0.25 else Color("#E04F5F")
			var seat := c + Vector2(-0.22, -0.2) * r
			var crank := c + Vector2(0.0, 0.4) * r
			var bars := c + Vector2(0.42, -0.25) * r
			ci.draw_line(c + Vector2(-0.62, 0.4) * r, seat, fr, w * 2.0, true)
			ci.draw_line(seat, crank, fr, w * 2.0, true)
			ci.draw_line(seat, bars, fr, w * 2.0, true)
			ci.draw_line(crank, bars, fr, w * 2.0, true)
			ci.draw_line(crank, c + Vector2(-0.62, 0.4) * r, fr, w * 2.0, true)
			ci.draw_line(bars, c + Vector2(0.62, 0.4) * r, fr, w * 2.0, true)
			ci.draw_line(seat, seat + Vector2(0, -0.12) * r, LINE, w * 1.5, true)
			ci.draw_line(seat + Vector2(-0.16, -0.12) * r, seat + Vector2(0.14, -0.12) * r, LINE, w * 2.2, true)
			ci.draw_line(bars, bars + Vector2(-0.06, -0.22) * r, LINE, w * 1.5, true)
			ci.draw_line(bars + Vector2(-0.06, -0.22) * r, bars + Vector2(0.14, -0.26) * r, LINE, w * 2.0, true)


# ── Pieces ──────────────────────────────────────────────────────

static func _moon(ci: CanvasItem, c: Vector2, r: float) -> void:
	# A crescent opening to the right: the left half of the full moon, back up along a flatter inner curve.
	var moon := PackedVector2Array()
	for k in 25:
		var a := PI * 0.5 + PI * k / 24.0
		moon.append(c + Vector2(cos(a), sin(a)) * r)
	for k in range(1, 24):
		var a := PI * 1.5 - PI * k / 24.0
		moon.append(c + Vector2(cos(a) * r * 0.45, sin(a) * r))
	ci.draw_colored_polygon(moon, Color("#FFE27A"))
	var ring := moon.duplicate()
	ring.append(moon[0])
	ci.draw_polyline(ring, LINE, maxf(1.5, r * 0.06), true)
	ci.draw_circle(c + Vector2(-r * 0.74, -r * 0.18), maxf(1.2, r * 0.07), LINE)
	ci.draw_arc(c + Vector2(-r * 0.72, r * 0.12), r * 0.12, 0.3, PI - 0.3, 8, LINE, maxf(1.0, r * 0.05), true)


static func _cloud(ci: CanvasItem, c: Vector2, r: float) -> void:
	var bumps := [[Vector2(-0.55, 0.15), 0.42], [Vector2(0.55, 0.15), 0.42], [Vector2(-0.15, -0.15), 0.55], [Vector2(0.3, -0.05), 0.48]]
	for b: Array in bumps:
		ci.draw_circle(c + b[0] * r, b[1] * r + 2.0, Color("#8FB8DA"))
	for b: Array in bumps:
		ci.draw_circle(c + b[0] * r, b[1] * r, Color.WHITE)
	ci.draw_circle(c + Vector2(-0.35, 0.05) * r, r * 0.06, LINE)
	ci.draw_circle(c + Vector2(0.15, 0.05) * r, r * 0.06, LINE)
	ci.draw_circle(c + Vector2(-0.55, 0.22) * r, r * 0.1, PINK)
	ci.draw_circle(c + Vector2(0.35, 0.22) * r, r * 0.1, PINK)


# ── Helpers (positions in units of r; `w` 0 = no outline) ───────

static func _e(ci: CanvasItem, c: Vector2, r: float, at: Vector2, rad: Vector2, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * k / 28.0
		pts.append(c + (at + Vector2(cos(a) * rad.x, sin(a) * rad.y)) * r)
	ci.draw_colored_polygon(pts, col)
	if w > 0.0:
		pts.append(pts[0])
		ci.draw_polyline(pts, LINE, w, true)


static func _p(ci: CanvasItem, c: Vector2, r: float, pts: Array, col: Color, w: float) -> void:
	var arr := PackedVector2Array()
	for p: Vector2 in pts:
		arr.append(c + p * r)
	if Geometry2D.triangulate_polygon(arr).size() > 0:
		ci.draw_colored_polygon(arr, col)
	if w > 0.0:
		arr.append(arr[0])
		ci.draw_polyline(arr, LINE, w, true)


static func _dot(ci: CanvasItem, at: Vector2, rad: float, col: Color) -> void:
	ci.draw_circle(at, maxf(0.8, rad), col)


static func _eyes(ci: CanvasItem, c: Vector2, r: float, spread: float, y: float) -> void:
	for s in [-1.0, 1.0]:
		var p := c + Vector2(s * spread, y) * r
		ci.draw_circle(p, maxf(1.0, r * 0.08), LINE)
		ci.draw_circle(p + Vector2(-0.02, -0.03) * r, maxf(0.5, r * 0.025), Color.WHITE)


static func _mouth(ci: CanvasItem, c: Vector2, r: float, at: Vector2, size: float, w: float) -> void:
	ci.draw_arc(c + at * r, size * r, 0.3, PI - 0.3, 8, LINE, maxf(1.0, w * 0.9), true)


static func _cheeks(ci: CanvasItem, c: Vector2, r: float, spread: float, y: float) -> void:
	for s in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(s * spread, y + 0.12) * r, r * 0.1, Color(PINK, 0.7))
