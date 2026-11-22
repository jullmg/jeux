class_name XmasTree
extends RefCounted
## The Christmas tree (quest "sapin", winter, after the Halloween evening; Julien: it is bought at the school's tree sale, in
## the schoolyard). Step by step (`GameState.flags.sapin_step`):
##   1. Papa says it is time for the tree and waits at the front door: it leads to the schoolyard ("Papa t'amène à la vente de
##      sapins de l'école…"), since at seven she may not cross Dandurand alone;
##   2. the sale (`TreeSale`, `cour_ecole.gd` in its "sapin" mode): trees of every shape in their stands; she picks one
##      (`flags.sapin_tree`, one of `SHAPES`), the volunteer wraps it, Papa pays and carries it home;
##   3. the salon (`house.gd`): the tree in its stand in front of the window and the box of decorations beside it; she takes
##      them out one at a time (`Carry` "deco:<id>", in the order of `DECOS`) and puts each on the tree (`flags.sapin_decos`);
##   4. the star: Papa lifts her up to put it on top; the lights come on, Maman comes to see, the quest is done. The tree stays,
##      lit, all winter.

const QUEST := "sapin"
const STEP := "sapin_step"
const CHOICE := "sapin_tree"
const DONE_DECOS := "sapin_decos"
const HEADING := "🎄  Le sapin"
const YARD := "res://scenes/cour_ecole.tscn"
const HOME := "res://scenes/house.tscn"
## Where they come in at home with the tree (the salon).
const HOME_X := 1500.0
## The trees at the sale: [name on its tag, how tall, how wide, its price].
const SHAPES := [
	["Le grand mince", 1.0, 0.82, "55 $"],
	["Le beau rond", 0.9, 1.08, "60 $"],
	["Le p'tit touffu", 0.74, 0.95, "40 $"],
	["Le géant", 1.08, 1.05, "75 $"],
]
## The decorations, in the order they go on: id, what she says taking it, what she says putting it on.
const DECOS := [
	["lumieres", "Les lumières en premier !", "Tout le tour, de haut en bas !"],
	["guirlande", "La guirlande dorée !", "Ça brille !"],
	["boules", "Les boules de toutes les couleurs !", "Une rouge, une bleue, une dorée…"],
	["cannes", "Les cannes de Noël !", "Miam, on dirait des vraies !"],
]
## Canvas of a tree picture.
const W := 240.0
const H := 380.0


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func choice() -> int:
	return clampi(int(GameState.flags.get(CHOICE, 1)), 0, SHAPES.size() - 1)


static func decos() -> Array:
	return GameState.flags.get(DONE_DECOS, [])


static func add_deco(id: String) -> void:
	var now := decos().duplicate()
	if id not in now:
		now.append(id)
	GameState.flags[DONE_DECOS] = now


## The next decoration still in the box, or "" when only the star is left.
static func next_deco() -> String:
	for d: Array in DECOS:
		if d[0] not in decos():
			return d[0]
	return ""


## Papa can give it: winter, and the quest free.
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


## The tree stands in the salon: from the moment it is home until the holidays are over (New Year's Day done: it goes out).
static func in_salon() -> bool:
	return Season.is_winter() and (step() >= 3 or Quests.done(QUEST)) and not Quests.done(NewYear.QUEST)


static func clear() -> void:
	for key in [STEP, CHOICE, DONE_DECOS]:
		GameState.flags.erase(key)


static func hint() -> String:
	match step():
		1:
			return "Papa t'attend à la porte d'en avant : vous allez choisir un sapin à la vente de l'école."
		2:
			return "Choisis ton sapin parmi ceux de la vente, dans la cour d'école."
		3:
			if Carry.what() == "deco":
				return "Mets la décoration dans le sapin."
			return "Décore le sapin : prends les décorations une à une dans la boîte, à côté du sapin."
		4:
			return "Il manque l'étoile ! Demande à Papa de te soulever."
	return str(Quests.ALL[QUEST].hint)


# ── Pictures ────────────────────────────────────────────────

## A fir tree in its stand, shape `shape` (one of SHAPES), wearing `wears` (ids of DECOS, and "etoile"); `snowy` for the sale
## outdoors (snow on its boughs, no stand: a wooden cross foot). Canvas W x H, its foot on the bottom middle; light from the
## upper left.
static func picture(shape: int, wears: Array, snowy := false) -> ImageTexture:
	var info: Array = SHAPES[clampi(shape, 0, SHAPES.size() - 1)]
	var tall: float = info[1]
	var wide: float = info[2]
	var cx := W / 2.0
	var foot := H - 34.0
	var top := foot - 300.0 * tall
	var half := 92.0 * wide
	var rng := RandomNumberGenerator.new()
	rng.seed = 4400 + shape
	var s := ""
	# The stand: a red metal bowl on green legs indoors, a wooden cross outdoors.
	if snowy:
		s += '<rect x="%s" y="%s" width="96" height="10" rx="3" fill="#8A6236" stroke="#5A3E1E" stroke-width="2"/>' % [cx - 48.0, H - 12.0]
	else:
		s += '<path d="M%s %s l-14 26 M%s %s l14 26" stroke="#1F6B3A" stroke-width="5" stroke-linecap="round"/>' % [cx - 22.0, H - 30.0, cx + 22.0, H - 30.0]
		s += '<path d="M%s %s H%s L%s %s H%s Z" fill="#C8202A" stroke="#7E1418" stroke-width="2"/>' % [cx - 36.0, H - 36.0, cx + 36.0, cx + 28.0, H - 14.0, cx - 28.0]
		s += '<path d="M%s %s H%s" stroke="#FF6B6B" stroke-width="3" opacity="0.7"/>' % [cx - 30.0, H - 32.0, cx + 20.0]
	s += '<rect x="%s" y="%s" width="16" height="%s" fill="#6B4528"/>' % [cx - 8.0, foot - 20.0, H - 14.0 - foot + 20.0]
	# The boughs: tiers from the bottom up, each a skirt of needles with a ragged hem, darker on the right.
	var tiers := 6
	var tier_points: Array = []
	for t in tiers:
		var f := float(t) / tiers
		var y_hem := foot - (foot - top) * f * 0.92
		var y_top := y_hem - (foot - top) * 0.34
		var w := half * (1.0 - f * 0.86)
		tier_points.append([y_hem, y_top, w])
	for t in tiers:
		var tp: Array = tier_points[t]
		var y_hem: float = tp[0]
		var y_top: float = maxf(tp[1], top)
		var w: float = tp[2]
		var hem := ""
		var n := 9
		for i in n + 1:
			var x := cx + w - 2.0 * w * i / n
			var drop := 10.0 if i % 2 == 0 else 0.0
			hem += " L%.1f %.1f" % [x, y_hem + drop - absf(float(i) / n - 0.5) * 10.0]
		s += '<path d="M%.1f %.1f%s Z" fill="#1E5A33" stroke="#123A21" stroke-width="2" stroke-linejoin="round"/>' % [cx, y_top, hem]
		# Lit side and shaded side.
		s += '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#2F7A45" opacity="0.8"/>' % [cx - 2.0, y_top + 6.0, cx - w * 0.85, y_hem - 2.0, cx - w * 0.2, y_hem]
		s += '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#0F3A20" opacity="0.5"/>' % [cx + 3.0, y_top + 10.0, cx + w * 0.9, y_hem, cx + w * 0.35, y_hem + 4.0]
		# Needle strokes.
		for i in int(8 + w / 6.0):
			var x := rng.randf_range(cx - w * 0.9, cx + w * 0.9)
			var y := rng.randf_range(lerpf(y_top, y_hem, 0.4), y_hem)
			s += '<path d="M%.1f %.1f l%.1f 6" stroke="#4E9A5C" stroke-width="1.4" opacity="0.6"/>' % [x, y, -3.0 if x < cx else 3.0]
		if snowy:
			s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#FFFFFF" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.92"/>' % [cx - w * 0.85, y_hem - 4.0, cx - w * 0.4, y_hem - 12.0, cx, y_hem - 6.0, cx + w * 0.4, y_hem - 12.0, cx + w * 0.7, y_hem - 2.0]
	# The decorations, under the star.
	if "lumieres" in wears:
		var colours := ["#FF4D4D", "#FFD23F", "#4DA6FF", "#5BD16E", "#FF8AD8"]
		var k := 0
		for p: Vector2 in bulbs(shape):
			s += '<path d="M%.1f %.1f v-3" stroke="#1E3A1E" stroke-width="2"/>' % [p.x, p.y - 3.0]
			s += '<ellipse cx="%.1f" cy="%.1f" rx="3.6" ry="4.6" fill="%s"/>' % [p.x, p.y, colours[k % colours.size()]]
			s += '<circle cx="%.1f" cy="%.1f" r="1.3" fill="#FFFFFF" opacity="0.8"/>' % [p.x - 1.0, p.y - 1.5]
			k += 1
		# The wire between the bulbs.
		for row in _rows(shape):
			s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#1E3A1E" stroke-width="1.2" fill="none" opacity="0.7"/>' % [row[0].x, row[0].y - 4.0, (row[0].x + row[1].x) / 2.0, maxf(row[0].y, row[1].y) + 10.0, row[1].x, row[1].y - 4.0]
	if "guirlande" in wears:
		for row in _rows(shape, 0.5):
			var a: Vector2 = row[0]
			var b: Vector2 = row[1]
			var mid := Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + 16.0)
			s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#E9B824" stroke-width="7" fill="none" stroke-linecap="round" stroke-dasharray="2 3"/>' % [a.x, a.y, mid.x, mid.y, b.x, b.y]
			s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#FFF0A0" stroke-width="2" fill="none" opacity="0.8"/>' % [a.x, a.y - 1.0, mid.x, mid.y - 2.0, b.x, b.y - 1.0]
	if "boules" in wears:
		var colours := ["#D42A3A", "#E9B824", "#2E6FD8", "#C9CED6", "#9B3BD1"]
		var i := 0
		for p: Vector2 in _spots(shape, 14, 77):
			var c: String = colours[i % colours.size()]
			s += '<path d="M%.1f %.1f v-6" stroke="#B8B8B8" stroke-width="1.2"/>' % [p.x, p.y - 7.0]
			s += '<circle cx="%.1f" cy="%.1f" r="7.5" fill="%s" stroke="#00000044" stroke-width="1.2"/>' % [p.x, p.y, c]
			s += '<rect x="%.1f" y="%.1f" width="5" height="3" fill="#D9C27A"/>' % [p.x - 2.5, p.y - 9.0]
			s += '<circle cx="%.1f" cy="%.1f" r="2.4" fill="#FFFFFF" opacity="0.75"/>' % [p.x - 2.6, p.y - 2.6]
			i += 1
	if "cannes" in wears:
		for p: Vector2 in _spots(shape, 7, 91):
			s += '<path d="M%.1f %.1f V%.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#FFFFFF" stroke-width="4" fill="none" stroke-linecap="round"/>' % [p.x, p.y + 12.0, p.y - 4.0, p.x, p.y - 10.0, p.x - 4.0, p.y - 10.0, p.x - 8.0, p.y - 10.0, p.x - 8.0, p.y - 5.0]
			for k in 3:
				s += '<path d="M%.1f %.1f l4 -2" stroke="#D42A3A" stroke-width="2.4"/>' % [p.x - 2.0, p.y + 9.0 - k * 5.0]
			s += '<path d="M%.1f %.1f q2 -3 5 -2" stroke="#D42A3A" stroke-width="2.4" fill="none"/>' % [p.x - 7.0, p.y - 8.0]
	if "etoile" in wears:
		s += _star(Vector2(cx, top - 6.0), 20.0)
	return InteriorArt.tex(W, H, s)


## Where the light bulbs hang (canvas units), so a scene can lay a glow on each once they are lit.
static func bulbs(shape: int) -> Array:
	var out: Array = []
	for row in _rows(shape):
		var a: Vector2 = row[0]
		var b: Vector2 = row[1]
		for k in 5:
			var t := (k + 0.5) / 5.0
			var p := a.lerp(b, t)
			p.y += sin(PI * t) * 10.0
			out.append(p)
	return out


## The top of the tree (canvas units): where the star goes.
static func top_of(shape: int) -> Vector2:
	var tall: float = SHAPES[clampi(shape, 0, SHAPES.size() - 1)][1]
	return Vector2(W / 2.0, H - 34.0 - 300.0 * tall - 6.0)


# The tree's rows for the lights and the garland: [left point, right point] going down, each slanting a little.
static func _rows(shape: int, shift := 0.0) -> Array:
	var info: Array = SHAPES[clampi(shape, 0, SHAPES.size() - 1)]
	var foot := H - 34.0
	var top := foot - 300.0 * float(info[1])
	var half := 92.0 * float(info[2])
	var out: Array = []
	for r in 4:
		var f := (r + 0.8 + shift) / 4.6
		var y := lerpf(top + 30.0, foot - 14.0, f)
		var w := half * lerpf(0.22, 0.92, f)
		out.append([Vector2(W / 2.0 - w, y - 8.0), Vector2(W / 2.0 + w, y + 8.0)])
	return out


# Places for `count` ornaments inside the tree's outline, spread out (fixed per shape and `seed_value`).
static func _spots(shape: int, count: int, seed_value: int) -> Array:
	var info: Array = SHAPES[clampi(shape, 0, SHAPES.size() - 1)]
	var foot := H - 34.0
	var top := foot - 300.0 * float(info[1])
	var half := 92.0 * float(info[2])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + shape
	var out: Array = []
	var tries := 0
	while out.size() < count and tries < 400:
		tries += 1
		var f := rng.randf_range(0.15, 0.95)
		var y := lerpf(top + 20.0, foot - 10.0, f)
		var w := half * f * 0.85
		var p := Vector2(W / 2.0 + rng.randf_range(-w, w), y)
		var free := true
		for q: Vector2 in out:
			if q.distance_to(p) < 26.0:
				free = false
		if free:
			out.append(p)
	return out


static func _star(c: Vector2, r: float) -> String:
	var pts := ""
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts += "%.1f,%.1f " % [c.x + cos(a) * rr, c.y + sin(a) * rr]
	var s := '<polygon points="%s" fill="#FFD23F" stroke="#C99410" stroke-width="2" stroke-linejoin="round"/>' % pts
	s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFF6C8" opacity="0.8"/>' % [c.x - r * 0.15, c.y - r * 0.2, r * 0.22]
	return s


## Canvas 120 × 90: the box of decorations, open, the next things peeking out. `left`: how many decorations are still in it.
static func box(left: int) -> ImageTexture:
	# An open cardboard box in three-quarter view: the back flap standing up, the dark inside with the decorations showing
	# over its rim, the front and the right side (both faces drawn, shaded differently), a flap folded down at the front.
	var s := '<path d="M30 34 L110 34 L104 14 L36 14 Z" fill="#C9372F" stroke="#6E1A16" stroke-width="2" stroke-linejoin="round"/>'
	s += '<path d="M36 14 L104 14 L106 20 L34 20 Z" fill="#E0605A" opacity="0.5"/>'
	s += '<path d="M10 44 L90 44 L110 34 L30 34 Z" fill="#3A1512" stroke="#6E1A16" stroke-width="2" stroke-linejoin="round"/>'
	if left > 0:
		var colours := ["#D42A3A", "#E9B824", "#2E6FD8", "#9B3BD1", "#2FA34F"]
		var spots := [[34.0, 36.0], [52.0, 33.0], [70.0, 36.0], [88.0, 34.0], [44.0, 40.0]]
		s += '<path d="M24 40 Q46 28 64 38 Q82 28 100 36" stroke="#E9B824" stroke-width="4" fill="none" stroke-dasharray="2 3" stroke-linecap="round"/>'
		for i in mini(left + 1, 5):
			var p: Array = spots[i]
			s += '<circle cx="%s" cy="%s" r="8" fill="%s" stroke="#00000055" stroke-width="1.2"/><circle cx="%s" cy="%s" r="2.4" fill="#FFFFFF" opacity="0.7"/>' % [p[0], p[1], colours[i % colours.size()], p[0] - 3.0, p[1] - 3.0]
	s += '<path d="M10 44 H90 V86 H10 Z" fill="#B5302B" stroke="#6E1A16" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M90 44 L110 34 V76 L90 86 Z" fill="#8E221E" stroke="#6E1A16" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M12 46 H88" stroke="#FFFFFF" stroke-width="2" opacity="0.18"/>'
	# The front flap folded down over its face, a gold ribbon of tape and a star label.
	s += '<path d="M10 44 L90 44 L88 56 L12 56 Z" fill="#D9473F" stroke="#6E1A16" stroke-width="2" stroke-linejoin="round"/>'
	s += '<rect x="42" y="44" width="16" height="42" fill="#E9B824" stroke="#8E6C0C" stroke-width="1.5"/>'
	s += '<path d="M44 46 V84" stroke="#FFFFFF" stroke-width="1.6" opacity="0.4"/>'
	s += '<path d="M96 52 L106 46 M96 60 L106 54" stroke="#6E1A16" stroke-width="1.4" opacity="0.4"/>'
	s += _star(Vector2(26, 72), 9.0) if left >= 0 else ""
	return InteriorArt.tex(120, 90, s)


## Canvas 80 × 80: one decoration in her arms.
static func deco_item(id: String) -> ImageTexture:
	var s := ""
	match id:
		"lumieres":
			s = '<path d="M8 40 Q24 20 40 40 Q56 60 72 40" stroke="#1E3A1E" stroke-width="2.5" fill="none"/>'
			var colours := ["#FF4D4D", "#FFD23F", "#4DA6FF", "#5BD16E", "#FF8AD8"]
			for i in 5:
				var x := 10.0 + i * 15.0
				var y := 40.0 + sin(i * 1.4) * 14.0
				s += '<ellipse cx="%s" cy="%s" rx="5" ry="7" fill="%s"/>' % [x, y + 7.0, colours[i]]
		"guirlande":
			s = '<path d="M6 24 Q40 70 74 24" stroke="#E9B824" stroke-width="12" fill="none" stroke-dasharray="3 3" stroke-linecap="round"/>'
			s += '<path d="M10 52 Q40 86 70 52" stroke="#E9B824" stroke-width="10" fill="none" stroke-dasharray="3 3" stroke-linecap="round"/>'
		"boules":
			var colours := ["#D42A3A", "#E9B824", "#2E6FD8"]
			for i in 3:
				s += '<circle cx="%d" cy="%d" r="14" fill="%s" stroke="#00000044" stroke-width="1.5"/>' % [22 + i * 18, 50 - (i % 2) * 16, colours[i]]
				s += '<circle cx="%d" cy="%d" r="4" fill="#FFFFFF" opacity="0.7"/>' % [17 + i * 18, 45 - (i % 2) * 16]
		"cannes":
			for i in 3:
				var x := 22.0 + i * 18.0
				s += '<path d="M%s 74 V24 Q%s 12 %s 12 Q%s 12 %s 22" stroke="#FFFFFF" stroke-width="7" fill="none" stroke-linecap="round"/>' % [x, x, x - 8.0, x - 16.0, x - 16.0]
				for k in 5:
					s += '<path d="M%s %s l7 -4" stroke="#D42A3A" stroke-width="3.5"/>' % [x - 3.5, 70 - k * 10]
		"etoile":
			s = _star(Vector2(40, 40), 30.0)
	return InteriorArt.tex(80, 80, s)
