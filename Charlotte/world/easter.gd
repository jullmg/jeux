class_name Easter
extends RefCounted
## The Easter egg hunt (quest "paques", spring, after Saint-Valentin; Julien: "les parents cachent des cocos de Pâques dans la
## ruelle"), step by step (`flags.paques_step`):
##   1. Maman (or Papa) wishes her a happy Easter and hands her a basket (`Carry` "panier"; if her hands are full, she comes
##      back for it); then both go out to the middle lane and wait there (gone from the flat: `parents_outside`);
##   2. the middle lane (`scenes/ruelle.gd _build_easter`): `SPOTS` eggs hidden along the fences, half hidden behind a tuft of
##      grass, a flower pot, a rubber boot, bricks, a bucket, dandelions, and a golden one on the croque-livre's roof (`Egg`, an
##      interactable, a twinkle now and then to help her); each found one goes in her basket (`flags.paques_trouves`, the
##      basket's picture fills up); Maman and Papa stand by her gate and say "Tu chauffes !" / "Tu gèles !" (`warmth`);
##   3. all found: a chocolate bunny from the Easter bunny, chocolates to her stash, the quest done, they all go in.
## **A new hiding place = a line in `SPOTS` (lot, where across it, what hides it) and, for a new cover, a case in `_cover`.**

const QUEST := "paques"
const STEP := "paques_step"
const FOUND := "paques_trouves"
const HEADING := "🐣  La chasse aux cocos"
## lot of the middle lane, where across it (0..1), what hides it ("croque" = on the croque-livre's roof), colour, pattern.
const SPOTS := [
	[0, 0.3, "herbe", 0, "rayures"],
	[2, 0.15, "pot", 1, "pois"],
	[2, 0.8, "botte", 2, "zigzag"],
	[3, 0.0, "croque", -1, "or"],
	[4, 0.55, "briques", 3, "deux"],
	[5, 0.25, "pissenlits", 4, "fleurs"],
	[6, 0.62, "seau", 5, "rayures"],
	[8, 0.4, "herbe", 6, "pois"],
	[9, 0.7, "pot", 7, "zigzag"],
	[10, 0.02, "pissenlits", 0, "deux"],
	[11, 0.55, "botte", 1, "fleurs"],
	[13, 0.4, "briques", 2, "rayures"],
]
const COLORS := ["#FF7BA3", "#4FA3E0", "#FFD23F", "#9BD84B", "#B58AD9", "#FF8A3D", "#2FB7B0", "#E04F5F"]
const LOT0 := 620.0
const LOT_W := 365.0
const GROUND_Y := 606.0
const CROQUE_TOP := 460.0


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## Easter morning: the night after she decorated eggs with Maman (`house.gd _go_to_sleep` sets `MORNING`).
const MORNING := "paques_matin"


static func can_start() -> bool:
	return Season.current == "spring" and Quests.available(QUEST) and GameState.flags.get(MORNING, false)


## The eggs she decorated with Maman (`EggStudio`): the Easter bunny hides those first.
static var _mine: Array[Texture2D] = []


static func load_mine() -> void:
	_mine.clear()
	for img: Image in EggStudio.kept():
		var copy: Image = img.duplicate()
		copy.generate_mipmaps()
		_mine.append(ImageTexture.create_from_image(copy))


## Her own egg for spot `i`, or null (the golden one is always the bunny's).
static func mine(i: int) -> Texture2D:
	if SPOTS[i][2] == "croque":
		return null
	var rank := 0
	for k in i:
		if SPOTS[k][2] != "croque":
			rank += 1
	var all := _mine.size()
	return _mine[all - 1 - rank] if rank < all else null


## Maman and Papa are out in the lane, hiding eggs and waiting for her.
static func parents_outside() -> bool:
	return step() == 2


static func found() -> Array:
	return GameState.flags.get(FOUND, [])


static func left() -> int:
	return SPOTS.size() - found().size()


static func mark(i: int) -> void:
	var f: Array = found().duplicate()
	if i not in f:
		f.append(i)
	GameState.flags[FOUND] = f


## Where egg `i` lies in the middle lane (its bottom).
static func position(i: int) -> Vector2:
	var s: Array = SPOTS[i]
	if s[2] == "croque":
		return Vector2(LOT0 + int(s[0]) * LOT_W + 70.0 + 37.0, CROQUE_TOP)
	return Vector2(LOT0 + (int(s[0]) + float(s[1])) * LOT_W, GROUND_Y)


## How warm she is: what Maman or Papa calls out, from the nearest egg still hidden.
static func warmth(from_x: float) -> String:
	var best := INF
	var best_x := from_x
	for i in SPOTS.size():
		if i in found():
			continue
		var d := absf(position(i).x - from_x)
		if d < best:
			best = d
			best_x = position(i).x
	if best == INF:
		return "Tu les as toutes trouvées !"
	if best < 260.0:
		return "Tu brûles ! Regarde ben comme il faut !"
	if best < 650.0:
		return "Tu chauffes, tu chauffes !"
	if best < 1300.0:
		return "Tu es tiède… continue %s !" % ("vers Holt" if best_x < from_x else "vers Dandurand")
	return "Brrr, tu gèles ! Va voir plus loin, %s." % ("vers Holt" if best_x < from_x else "vers Dandurand")


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(FOUND)
	GameState.flags.erase(MORNING)


static func hint() -> String:
	match step():
		1:
			return "Va chercher ton panier de Pâques : Maman te le donne."
		2:
			return "Trouve les cocos de Pâques cachés dans la ruelle du milieu (%d sur %d). Maman pis Papa te disent si tu chauffes !" % [found().size(), SPOTS.size()]
	return str(Quests.ALL[QUEST].hint)


# ── Pictures ────────────────────────────────────────────────────

static func _egg_points(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 36:
		var a := TAU * k / 36.0
		pts.append(c + Vector2(sin(a) * rx * (1.0 - 0.13 * cos(a)), -cos(a) * ry))
	return pts


## A painted egg centred at `c`: its colour (-1 = gold) and pattern ("rayures", "pois", "zigzag", "deux", "fleurs", "or").
static func draw_egg(ci: CanvasItem, c: Vector2, color_i: int, pattern: String, s := 1.0) -> void:
	var rx := 9.5 * s
	var ry := 12.5 * s
	var egg := _egg_points(c, rx, ry)
	var shade := PackedVector2Array()
	for p: Vector2 in egg:
		shade.append(p + Vector2(1.5, 1.5) * s)
	ci.draw_colored_polygon(shade, Color(0, 0, 0, 0.25))
	var base := Color("#F2C230") if color_i < 0 else Color(COLORS[color_i % COLORS.size()])
	ci.draw_colored_polygon(egg, base)
	var other := Color.WHITE if color_i < 0 else Color(COLORS[(color_i + 3) % COLORS.size()]).lightened(0.25)
	var bands: Array = []
	match pattern:
		"rayures":
			for y: float in [-0.35, 0.25]:
				bands.append(PackedVector2Array([c + Vector2(-rx * 2, (y - 0.1) * ry), c + Vector2(rx * 2, (y - 0.1) * ry), c + Vector2(rx * 2, (y + 0.1) * ry), c + Vector2(-rx * 2, (y + 0.1) * ry)]))
		"zigzag":
			var z := PackedVector2Array()
			for k in 9:
				z.append(c + Vector2(-rx * 1.2 + k * rx * 0.3, (-0.12 if k % 2 == 0 else 0.12) * ry))
			for k in range(8, -1, -1):
				z.append(c + Vector2(-rx * 1.2 + k * rx * 0.3, (0.12 if k % 2 == 0 else 0.36) * ry))
			bands.append(z)
		"deux":
			bands.append(PackedVector2Array([c + Vector2(-rx * 2, 0.05 * ry), c + Vector2(rx * 2, 0.05 * ry), c + Vector2(rx * 2, ry * 2), c + Vector2(-rx * 2, ry * 2)]))
	for band: PackedVector2Array in bands:
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, egg):
			ci.draw_colored_polygon(piece, other)
	match pattern:
		"pois":
			for d: Vector2 in [Vector2(-0.4, -0.3), Vector2(0.35, -0.05), Vector2(-0.2, 0.4), Vector2(0.3, 0.55), Vector2(0.05, -0.6)]:
				ci.draw_circle(c + Vector2(d.x * rx, d.y * ry), 1.8 * s, other)
		"fleurs":
			for d: Vector2 in [Vector2(-0.3, -0.25), Vector2(0.3, 0.3)]:
				for k in 5:
					ci.draw_circle(c + Vector2(d.x * rx, d.y * ry) + Vector2.from_angle(TAU * k / 5.0) * 2.2 * s, 1.5 * s, Color.WHITE)
				ci.draw_circle(c + Vector2(d.x * rx, d.y * ry), 1.2 * s, Color("#FFD23F"))
		"or":
			ci.draw_line(c + Vector2(-rx * 0.8, -ry * 0.1), c + Vector2(rx * 0.8, -ry * 0.1), Color("#C98A12"), 2.0 * s, true)
			ci.draw_line(c + Vector2(-rx * 0.7, ry * 0.25), c + Vector2(rx * 0.7, ry * 0.25), Color("#C98A12"), 2.0 * s, true)
	egg.append(egg[0])
	ci.draw_polyline(egg, base.darkened(0.4), 1.3 * s, true)
	ci.draw_circle(c + Vector2(-rx * 0.38, -ry * 0.45), 2.2 * s, Color(1, 1, 1, 0.7))


## What hides an egg, drawn over it; `at` is the egg's bottom.
static func _cover(ci: CanvasItem, kind: String, at: Vector2, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	match kind:
		"herbe", "pissenlits":
			for k in 16:
				var x := at.x + rng.randf_range(-18.0, 18.0)
				var h := rng.randf_range(10.0, 22.0)
				var lean := rng.randf_range(-6.0, 6.0)
				ci.draw_line(Vector2(x, at.y + 2.0), Vector2(x + lean, at.y + 2.0 - h), Color("#4E9A3A").lerp(Color("#8BCB5A"), rng.randf()), 2.2, true)
			if kind == "pissenlits":
				for k in 3:
					var p := at + Vector2(rng.randf_range(-16.0, 16.0), -rng.randf_range(12.0, 22.0))
					ci.draw_line(p, Vector2(p.x, at.y + 2.0), Color("#5B8A2E"), 1.6, true)
					for j in 8:
						ci.draw_circle(p + Vector2.from_angle(TAU * j / 8.0) * 3.4, 2.0, Color("#FFD23F"))
					ci.draw_circle(p, 2.4, Color("#F2A20F"))
		"pot":
			var x := at.x + 8.0
			var pot := PackedVector2Array([Vector2(x - 16, at.y - 26), Vector2(x + 16, at.y - 26), Vector2(x + 12, at.y + 2), Vector2(x - 12, at.y + 2)])
			for k in 3:
				var stem := Vector2(x - 8.0 + k * 8.0, at.y - 26.0)
				ci.draw_line(stem, stem + Vector2(0, -16.0 - k * 3.0), Color("#4E9A3A"), 2.0, true)
				var bloom := stem + Vector2(0, -18.0 - k * 3.0)
				ci.draw_colored_polygon(PackedVector2Array([bloom + Vector2(-4, 0), bloom + Vector2(-4, -6), bloom + Vector2(-1.5, -3), bloom + Vector2(0, -7), bloom + Vector2(1.5, -3), bloom + Vector2(4, -6), bloom + Vector2(4, 0)]), Color(["#E04F5F", "#FFD23F", "#FF7BA3"][k]))
			ci.draw_colored_polygon(pot, Color("#C8683C"))
			ci.draw_rect(Rect2(x - 18, at.y - 30, 36, 6), Color("#B05A30"))
			ci.draw_line(Vector2(x - 12, at.y - 22), Vector2(x - 9, at.y - 2), Color(1, 1, 1, 0.25), 2.0)
		"botte":
			var x := at.x - 4.0
			var boot := PackedVector2Array([Vector2(x - 8, at.y - 30), Vector2(x + 6, at.y - 30), Vector2(x + 6, at.y - 8), Vector2(x + 18, at.y - 6), Vector2(x + 20, at.y + 2), Vector2(x - 8, at.y + 2)])
			ci.draw_colored_polygon(boot, Color("#E8C43A"))
			ci.draw_rect(Rect2(x - 9, at.y - 32, 16, 5), Color("#C9A42A"))
			ci.draw_line(Vector2(x - 5, at.y - 26), Vector2(x - 5, at.y - 4), Color(1, 1, 1, 0.35), 2.0)
		"briques":
			for k in 2:
				var r := Rect2(at.x - 14.0 + k * 3.0, at.y - 9.0 - k * 9.0, 26.0, 9.0)
				ci.draw_rect(r, Color("#B4513A"))
				ci.draw_rect(r, Color("#7A3424"), false, 1.2)
		"seau":
			# A sand bucket on its side, the egg in its mouth.
			var c := at + Vector2(10, -10)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -12), c + Vector2(16, -9), c + Vector2(16, 9), c + Vector2(-4, 12)]), Color("#4FA3E0"))
			ci.draw_arc(c + Vector2(16, 0), 9.0, -PI / 2.0, PI / 2.0, 10, Color("#2E78C0"), 2.0, true)
			ci.draw_line(c + Vector2(2, -12), c + Vector2(10, -20), Color("#2E78C0"), 1.6, true)


## Canvas 120 × 110: her Easter basket, wicker with a handle and paper grass, with `eggs` eggs in it.
static func basket(eggs: int) -> ImageTexture:
	var s := '<path d="M18 48 Q60 -14 102 48" stroke="#9A6A34" stroke-width="7" fill="none" stroke-linecap="round"/>'
	s += '<path d="M18 48 Q60 -14 102 48" stroke="#D29A5A" stroke-width="3" fill="none" stroke-linecap="round"/>'
	s += '<path d="M20 52 Q60 40 100 52 L106 46 L94 44 L98 38 L86 42 L84 34 L74 42 L66 32 L60 42 L50 32 L46 42 L34 34 L32 44 L20 40 L24 48 L14 46 Z" fill="#7CCB5A"/>'
	var cols := COLORS
	for k in mini(eggs, 12):
		var x := 28.0 + (k % 6) * 13.0 + (6.0 if k >= 6 else 0.0)
		var y := 44.0 - (8.0 if k >= 6 else 0.0) - (k % 2) * 3.0
		s += '<ellipse cx="%.1f" cy="%.1f" rx="6.5" ry="8.5" fill="%s" stroke="#00000044" stroke-width="1"/>' % [x, y, "#F2C230" if k == 3 else cols[k % cols.size()]]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="1.8" ry="2.6" fill="#FFFFFF" opacity="0.6"/>' % [x - 2.0, y - 3.0]
	s += '<path d="M14 50 H106 L96 100 Q60 108 24 100 Z" fill="#C8904E" stroke="#7A5226" stroke-width="2.5" stroke-linejoin="round"/>'
	for y in [60, 72, 84, 96]:
		s += '<path d="M%d %d Q60 %d %d %d" stroke="#9A6A34" stroke-width="2" fill="none"/>' % [16 + (y - 50) / 5, y, y + 6, 104 - (y - 50) / 5, y]
	for x in range(24, 100, 10):
		s += '<path d="M%d 52 L%d 100" stroke="#A8743C" stroke-width="1.6" opacity="0.7"/>' % [x, 60 + (x - 60) * 8 / 10]
	s += '<path d="M14 50 H106" stroke="#E8B878" stroke-width="4" stroke-linecap="round"/>'
	s += '<path d="M40 58 Q60 52 80 58 L76 66 Q60 60 44 66 Z" fill="#FF7BA3" opacity="0.85"/>'
	return InteriorArt.tex(120, 110, s)


## Canvas 110 × 130: a chocolate bunny in its foil.
static func bunny() -> ImageTexture:
	var s := '<path d="M38 30 Q30 2 42 4 Q52 8 50 34 Z M62 34 Q60 6 72 4 Q82 4 74 32 Z" fill="#7A4A2A" stroke="#4A2A14" stroke-width="2"/>'
	s += '<path d="M42 10 Q40 22 46 30 M70 10 Q72 22 66 30" stroke="#A86A3E" stroke-width="3" fill="none"/>'
	s += '<ellipse cx="56" cy="46" rx="22" ry="18" fill="#7A4A2A" stroke="#4A2A14" stroke-width="2"/>'
	s += '<path d="M24 126 Q16 86 34 66 Q56 54 78 66 Q96 86 88 126 Z" fill="#E8C43A" stroke="#A88A1E" stroke-width="2"/>'
	s += '<path d="M28 100 Q56 92 84 100" stroke="#E04F5F" stroke-width="6" fill="none"/><path d="M56 96 q-12 -12 -16 -2 q6 6 16 2 q12 -12 16 -2 q-6 6 -16 2" fill="#E04F5F"/>'
	s += '<circle cx="48" cy="44" r="2.6" fill="#2A1408"/><circle cx="64" cy="44" r="2.6" fill="#2A1408"/><path d="M53 52 q3 3 6 0" stroke="#2A1408" stroke-width="1.6" fill="none"/>'
	s += '<path d="M34 80 Q38 70 46 68" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.6"/>'
	return InteriorArt.tex(110, 130, s)


# ── The egg in the lane ─────────────────────────────────────────

## One hidden egg: click it and Charlotte walks over and puts it in her basket.
class Egg:
	extends Node2D

	signal picked(i: int)

	var index := 0
	var _t := 0.0
	var _phase := 0.0
	var _taken := false

	func _ready() -> void:
		add_to_group("interactable")
		_phase = index * 1.7

	func _process(delta: float) -> void:
		_t += delta
		if OnScreen.near(self, 200.0):
			queue_redraw()

	func _draw() -> void:
		if _taken:
			return
		var s: Array = Easter.SPOTS[index]
		# It peeks out beside what hides it.
		var egg_at := Vector2({"pot": -6.0, "botte": -19.0}.get(s[2], 0.0), -12.0)
		if s[2] == "seau":
			egg_at = Vector2(16.0, -10.0)
		var hers := Easter.mine(index)
		if hers:
			# One of hers, the size of an egg in the lane.
			var h := 27.0
			var w := h * hers.get_width() / float(hers.get_height())
			draw_texture_rect(hers, Rect2(egg_at - Vector2(w, h) / 2.0, Vector2(w, h)), false)
		else:
			Easter.draw_egg(self, egg_at, int(s[3]), str(s[4]), 1.0)
		Easter._cover(self, str(s[2]), Vector2.ZERO, 40 + index)
		# A little twinkle now and then, to help.
		var tw := sin(_t * 1.3 + _phase)
		if tw > 0.92:
			var k := (tw - 0.92) / 0.08
			var c := egg_at + Vector2(6, -10)
			for a in 4:
				draw_line(c, c + Vector2.from_angle(a * PI / 2.0) * 7.0 * k, Color(1, 1, 0.8, k), 1.6, true)

	func can_interact() -> bool:
		return not _taken

	func hit_test(p: Vector2) -> bool:
		return Rect2(global_position + Vector2(-26, -44), Vector2(52, 52)).has_point(p)

	func approach_x(_from_x: float) -> float:
		return global_position.x

	func focus_x() -> float:
		return global_position.x

	func reserve() -> void:
		pass

	func release() -> void:
		pass

	func interact(_who: Character) -> void:
		if _taken:
			return
		_taken = true
		queue_redraw()
		picked.emit(index)
