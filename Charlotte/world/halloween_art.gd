class_name HalloweenArt
extends RefCounted
## What the neighbours put out for Halloween night, drawn as SVG like the rest of the street.
## `HalloweenNight._dress_the_houses` gives every house that hands out candy three to five of these (`PIECES`, its
## own RNG); the dark ones get nothing. The set follows what is really sold for a front yard here: carved pumpkins
## and whole ones on the steps, tombstones and skeleton hands clawing out of the lawn, a bubbling cauldron, a bale
## of straw with mums and corn stalks, little lit stakes down the path, a sheet ghost hung from the balcony,
## cobwebs in the corner of the facade and a garland of pumpkins along the railing.
##
## NOTHING EVER GOES ON THE SIDEWALK: the sidewalk belongs to the people walking. Everything stands in the little
## garden behind the fence ("yard"), on the porch and its steps ("step"), on the facade ("wall", "corner"), hung
## from the balcony ("hang") or along its railing ("rail").
##
## Each canvas is drawn with its FEET on the bottom edge, so a piece can simply be stood on the ground it belongs
## to ("anchor": "foot"); the ones that hang are drawn from the top instead ("anchor": "top").
##
## A NEW decoration = one function here, its name in `PIECES` (canvas, where it goes, how big, and `glow` = where
## it carries a light) and its name in `CHOICES`.

## Each piece: its canvas, where it belongs, how big it is drawn on the street, and the lights it carries
## (canvas points, which the night's light pass turns into glows).
const PIECES := {
	# ── On the porch and its steps ──
	"jack": {"size": Vector2(96, 92), "where": "step", "scale": 0.52, "glow": [Vector2(48, 52)]},
	"jack_pair": {"size": Vector2(164, 96), "where": "step", "scale": 0.5, "glow": [Vector2(46, 54), Vector2(120, 66)]},
	"pumpkin_row": {"size": Vector2(190, 76), "where": "step", "scale": 0.46},
	"bowl": {"size": Vector2(108, 72), "where": "step", "scale": 0.48},
	"candles": {"size": Vector2(104, 108), "where": "step", "scale": 0.46, "glow": [Vector2(26, 46), Vector2(52, 32), Vector2(78, 50)]},
	"broom": {"size": Vector2(78, 172), "where": "step", "scale": 0.5},
	"cauldron": {"size": Vector2(132, 124), "where": "step", "scale": 0.5, "glow": [Vector2(66, 46)]},
	# ── In the little garden, behind the fence ──
	"grave": {"size": Vector2(118, 128), "where": "yard", "scale": 0.62},
	"graves": {"size": Vector2(188, 122), "where": "yard", "scale": 0.58},
	"bones": {"size": Vector2(168, 94), "where": "yard", "scale": 0.6},
	"skeleton": {"size": Vector2(96, 196), "where": "yard", "scale": 0.56},
	"scarecrow": {"size": Vector2(126, 204), "where": "yard", "scale": 0.58},
	"cat": {"size": Vector2(96, 88), "where": "yard", "scale": 0.56},
	"hay": {"size": Vector2(176, 112), "where": "yard", "scale": 0.58},
	"stakes": {"size": Vector2(168, 86), "where": "yard", "scale": 0.56, "glow": [Vector2(20, 22), Vector2(84, 16), Vector2(148, 24)]},
	# ── On the facade and the balcony ──
	"web": {"size": Vector2(148, 148), "where": "corner", "scale": 0.62, "anchor": "corner"},
	"ghost": {"size": Vector2(112, 156), "where": "hang", "scale": 0.6, "anchor": "top"},
	"spider": {"size": Vector2(124, 118), "where": "wall", "scale": 0.48, "anchor": "top"},
	"bats": {"size": Vector2(184, 112), "where": "wall", "scale": 0.58, "anchor": "top"},
	"garland": {"size": Vector2(288, 74), "where": "rail", "scale": 0.7, "anchor": "top"},
}

## The pieces a house may be given, and how likely each is (the ones that say "Halloween" loudest come up twice).
const CHOICES := ["jack", "jack_pair", "pumpkin_row", "bowl", "candles", "broom", "cauldron",
	"grave", "graves", "bones", "skeleton", "scarecrow", "cat", "hay", "stakes",
	"web", "ghost", "spider", "bats", "garland",
	"jack", "jack_pair", "grave", "graves", "bones", "ghost", "web", "garland", "stakes", "pumpkin_row"]

const ORANGE := "#E8812E"
const DEEP := "#C25A14"
const LIGHT := "#F4A657"
const PURPLE := "#7E57C2"
const BONE := "#EFEADA"
const BONE_SHADE := "#CFC7B2"
const BONE_LINE := "#9A9079"
const STONE := "#ADA99F"
const STONE_LIGHT := "#C6C2B6"
const STONE_DARK := "#6E6A62"
const NIGHT := "#2B2430"
const BLACK := "#23232B"
const WOOD := "#8A5A2E"
const WOOD_DARK := "#5E4228"
const EARTH := "#4A3A2C"
const EARTH_LIGHT := "#6B5646"
const STRAW := "#D9B45A"
const STRAW_DARK := "#A8862E"
const GREEN := "#5E8A36"
const BREW := "#86D468"


static func texture(kind: String) -> ImageTexture:
	var size: Vector2 = PIECES[kind].size
	return PropArt.tex(PropArt._svg(size.x, size.y, _body(kind)))


static func _body(kind: String) -> String:
	match kind:
		"jack":
			return _ground_shadow(48, 88, 34) + _jack(48, 52, 1.0, 0)
		"jack_pair":
			return _ground_shadow(46, 90, 32) + _ground_shadow(120, 92, 24) \
				+ _jack(120, 66, 0.68, 1) + _jack(46, 54, 0.98, 0)
		"pumpkin_row":
			return _pumpkin_row()
		"bowl":
			return _bowl()
		"candles":
			return _candles()
		"broom":
			return _broom()
		"cauldron":
			return _cauldron()
		"grave":
			return _ground_shadow(59, 124, 46) + _tombstone(59, 124, 1.0, 0, -2.5)
		"graves":
			return _ground_shadow(52, 118, 40) + _ground_shadow(140, 120, 34) \
				+ _tombstone(140, 120, 0.72, 2, 4.0) + _tombstone(52, 118, 0.9, 1, -3.5) + _grave_fence()
		"bones":
			return _bones()
		"skeleton":
			return _skeleton()
		"scarecrow":
			return _scarecrow()
		"cat":
			return _cat()
		"hay":
			return _hay()
		"stakes":
			return _stakes()
		"web":
			return _web()
		"ghost":
			return _ghost()
		"spider":
			return _spider()
		"bats":
			return _bats()
		"garland":
			return _garland()
	return ""


# ── Shared bits ─────────────────────────────────────────────────

# The soft dark patch a thing standing on the ground leaves under it.
static func _ground_shadow(cx: float, cy: float, rx: float) -> String:
	return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#1A1420" opacity="0.3"/>' % [cx, cy, rx, rx * 0.26]


static func _stroke(color: String, width: float) -> String:
	return 'stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % [color, width]


# A carved pumpkin standing on the ground: ribs, a curled stem, a face cut out and lit from inside.
# `face` picks which one it was carved with.
static func _jack(cx: float, base: float, scale: float, face: int) -> String:
	var s := '<g transform="translate(%s %s) scale(%s) translate(-45 -78)">' % [cx, base, scale]
	s += '<path d="M45 24 q3 -12 15 -16 q-3 13 -12 17 z" fill="%s"/>' % GREEN
	s += '<path d="M40 14 q6 -8 12 -2 q-4 4 -4 12 h-9 z" fill="#4E7A30" %s/>' % _stroke("#3C5F24", 2)
	s += '<ellipse cx="45" cy="46" rx="42" ry="32" fill="%s" %s/>' % [ORANGE, _stroke(DEEP, 3)]
	# The ribs, and the light sitting on the upper left of the shell.
	for dx: float in [-27.0, -14.0, 0.0, 14.0, 27.0]:
		s += '<path d="M%s 18 q-8 28 0 56" %s fill="none" opacity="0.5"/>' % [45.0 + dx, _stroke(DEEP, 2.5)]
	s += '<path d="M14 36 q8 -18 26 -22 q-16 10 -20 24 z" fill="%s" opacity="0.75"/>' % LIGHT
	s += '<path d="M62 70 q18 -10 20 -28 q4 22 -14 32 z" fill="%s" opacity="0.5"/>' % DEEP
	# The face, cut right through: dark inside, then the candle light coming out of it.
	var cut := ""
	match face:
		0:
			cut = 'M24 38 l13 -13 l13 13 z M66 38 l-13 -13 l-13 13 z'
			cut += ' M22 54 q23 22 46 0 q-7 1 -9 -6 q-7 7 -14 0 q-7 7 -14 0 q-2 7 -9 6 z'
		_:
			cut = 'M23 40 q10 -16 20 -2 q-10 4 -20 2 z M67 40 q-10 -16 -20 -2 q10 4 20 2 z'
			cut += ' M24 56 q21 20 42 0 q-10 10 -21 10 q-11 0 -21 -10 z M40 60 h10 v8 h-10 z'
	s += '<path d="%s" fill="#2B1408"/>' % cut
	s += '<path d="%s" fill="#FFC24A" opacity="0.72"/>' % cut
	s += '<path d="%s" fill="#FFF0B8" opacity="0.35"/>' % cut
	return s + "</g>"


# A whole pumpkin, uncarved.
static func _pumpkin(cx: float, base: float, r: float, tone: String, dark: String) -> String:
	var s := '<path d="M%s %s q2 -%s %s -%s q-2 %s -%s %s z" fill="%s"/>' % [cx, base - r * 1.5, r * 0.5, r * 0.5, r * 0.4, r * 0.4, r * 0.3, r * 0.5, GREEN]
	s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" %s/>' % [cx, base - r * 0.78, r, r * 0.78, tone, _stroke(dark, 2.4)]
	for dx: float in [-0.6, -0.2, 0.2, 0.6]:
		s += '<path d="M%s %s q-%s %s 0 %s" %s fill="none" opacity="0.45"/>' % [cx + r * dx, base - r * 1.42, r * 0.18, r * 0.7, r * 1.3, _stroke(dark, 2)]
	s += '<path d="M%s %s q%s -%s %s -%s q-%s %s -%s %s z" fill="#FFFFFF" opacity="0.2"/>' % [
		cx - r * 0.75, base - r * 0.95, r * 0.2, r * 0.45, r * 0.6, r * 0.5, r * 0.4, r * 0.2, r * 0.6, r * 0.25]
	return s


# ── On the porch ────────────────────────────────────────────────

# A row of whole pumpkins of different sizes, the way they are lined up on the steps.
static func _pumpkin_row() -> String:
	var s := ""
	var sizes := [[26.0, 22.0, ORANGE, DEEP], [68.0, 30.0, "#DE7526", "#B04F11"], [116.0, 19.0, "#F0A24A", "#C8721F"],
		[156.0, 24.0, "#E8812E", "#C25A14"]]
	for p: Array in sizes:
		s += _ground_shadow(p[0], 74.0, p[1] * 1.15)
	for p: Array in sizes:
		s += _pumpkin(p[0], 74.0, p[1], p[2], p[3])
	return s


# A big bowl of sweets left out on the step, with a note taped to it.
static func _bowl() -> String:
	var s := _ground_shadow(54, 70, 44)
	s += '<path d="M8 28 Q54 16 100 28 Q94 64 54 68 Q14 64 8 28 Z" fill="#D9452A" %s/>' % _stroke("#9E2A16", 3)
	s += '<path d="M14 31 Q54 22 94 31 Q90 44 54 48 Q18 44 14 31 Z" fill="#2B1A14" opacity="0.5"/>'
	for c: Array in [["#F2C230", 30.0, 30.0, 9.0], ["#7E57C2", 48.0, 26.0, 10.0], ["#4FA3E0", 68.0, 30.0, 9.0],
			["#F4F2EC", 40.0, 22.0, 7.0], ["#E8542F", 60.0, 21.0, 8.0], ["#86D468", 80.0, 27.0, 7.0]]:
		s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" %s/>' % [c[1], c[2], c[3], float(c[3]) * 0.8, c[0], _stroke("#2B2430", 1.6)]
		s += '<path d="M%s %s l-6 -3 M%s %s l6 -3" %s/>' % [c[1] - float(c[3]), c[2], c[1] + float(c[3]), c[2], _stroke("#2B2430", 1.4)]
	s += '<path d="M12 32 Q54 44 96 32" %s fill="none" opacity="0.45"/>' % _stroke("#9E2A16", 2)
	s += '<rect x="26" y="48" width="26" height="16" rx="2" fill="#F5EFDC" transform="rotate(-6 39 56)" %s/>' % _stroke("#C9BFA4", 1.5)
	s += '<path d="M31 54 h16 M31 59 h12" %s transform="rotate(-6 39 56)"/>' % _stroke("#8A8270", 1.6)
	return s


# Three candle lanterns on the step, their flames alive.
static func _candles() -> String:
	var s := _ground_shadow(52, 104, 46)
	for p: Array in [[26.0, 54.0], [52.0, 70.0], [78.0, 50.0]]:
		var cx: float = p[0]
		var h: float = p[1]
		var top := 100.0 - h
		# The glass of the lantern, its wax candle inside and the flame on top.
		s += '<rect x="%s" y="%s" width="20" height="%s" rx="3" fill="#F6F2E6" opacity="0.28" %s/>' % [cx - 10, top, h - 6, _stroke("#B9B1A0", 1.6)]
		s += '<rect x="%s" y="%s" width="12" height="%s" rx="3" fill="#F4F2EC" %s/>' % [cx - 6, top + 10, h - 20, _stroke("#D2CBBA", 1.6)]
		s += '<path d="M%s %s q-3 3 -3 7 q0 5 3 5 q3 0 3 -5 q0 -4 -3 -7 z" fill="#FFD23F"/>' % [cx, top + 1]
		s += '<path d="M%s %s q-2 2 -2 5 q0 3 2 3 q2 0 2 -3 q0 -3 -2 -5 z" fill="#FFF3C4"/>' % [cx, top + 3]
		s += '<rect x="%s" y="%s" width="24" height="7" rx="3" fill="%s" %s/>' % [cx - 12, 94.0, WOOD_DARK, _stroke("#3B2A18", 1.5)]
	return s


# A witch's broom leaning against the wall.
static func _broom() -> String:
	var s := _ground_shadow(36, 168, 30)
	s += '<rect x="30" y="4" width="9" height="114" rx="4" fill="%s" %s/>' % [WOOD, _stroke(WOOD_DARK, 2)]
	s += '<path d="M32 8 v108" stroke="#B5793E" stroke-width="2.5" opacity="0.5"/>'
	s += '<path d="M20 112 Q35 106 50 112 L62 166 Q35 176 10 166 Z" fill="%s" %s/>' % [STRAW, _stroke(STRAW_DARK, 2.5)]
	for i in 7:
		s += '<path d="M%s 116 L%s 170" %s opacity="0.7"/>' % [19 + i * 5, 12 + i * 7, _stroke(STRAW_DARK, 1.6)]
	s += '<path d="M20 112 Q35 106 50 112 L52 126 Q35 120 19 126 Z" fill="#E8C878" opacity="0.6"/>'
	s += '<rect x="17" y="106" width="36" height="10" rx="5" fill="%s" %s/>' % [WOOD_DARK, _stroke("#3B2A18", 1.5)]
	s += '<path d="M18 110 h34" %s opacity="0.6"/>' % _stroke("#8A6A3E", 2)
	return s


# A cauldron on its logs, something green bubbling in it.
static func _cauldron() -> String:
	var s := _ground_shadow(66, 120, 52)
	# The logs under it.
	for p: Array in [[30.0, 112.0], [66.0, 116.0], [102.0, 112.0]]:
		s += '<rect x="%s" y="%s" width="30" height="11" rx="5" fill="%s" %s/>' % [p[0] - 15, p[1], WOOD_DARK, _stroke("#3B2A18", 1.6)]
		s += '<ellipse cx="%s" cy="%s" rx="4" ry="5" fill="#C96A2E"/>' % [p[0] - 11, p[1] + 5.5]
	s += '<path d="M14 54 Q14 112 66 112 Q118 112 118 54 Z" fill="#1E1E26" %s/>' % _stroke("#0E0E14", 3)
	s += '<path d="M26 60 Q28 100 54 106 Q34 96 32 60 z" fill="#43434E" opacity="0.7"/>'
	s += '<ellipse cx="66" cy="52" rx="54" ry="15" fill="#2A2A34" %s/>' % _stroke("#0E0E14", 3)
	s += '<ellipse cx="66" cy="52" rx="44" ry="10" fill="#2E6B2A"/>'
	s += '<ellipse cx="66" cy="51" rx="42" ry="9" fill="%s"/>' % BREW
	s += '<ellipse cx="52" cy="50" rx="18" ry="4" fill="#C8F0A8" opacity="0.7"/>'
	for b: Array in [[44.0, 44.0, 6.0], [70.0, 38.0, 8.0], [88.0, 46.0, 5.0], [58.0, 30.0, 4.0]]:
		s += '<circle cx="%s" cy="%s" r="%s" fill="%s" opacity="0.8"/>' % [b[0], b[1], b[2], BREW]
		s += '<circle cx="%s" cy="%s" r="%s" fill="#E6FFD0" opacity="0.6"/>' % [b[0] - float(b[2]) * 0.3, b[1] - float(b[2]) * 0.3, float(b[2]) * 0.35]
	# Its handle, standing up over the brew.
	s += '<path d="M18 48 Q66 -8 114 48" fill="none" %s/>' % _stroke("#1E1E26", 5)
	return s


# ── In the garden ───────────────────────────────────────────────

# A tombstone leaning in the grass: a rounded slab with a carved border, RIP cut into it, moss at its foot.
static func _tombstone(cx: float, base: float, scale: float, kind: int, tilt: float) -> String:
	var s := '<g transform="translate(%s %s) rotate(%s) scale(%s) translate(0 -118)">' % [cx, base, tilt, scale]
	s += '<path d="M-44 118 V48 Q-44 2 0 2 Q44 2 44 48 V118 Z" fill="%s" %s/>' % [STONE_DARK, _stroke("#4E4B45", 3)]
	s += '<path d="M-38 116 V48 Q-38 10 0 10 Q38 10 38 48 V116 Z" fill="%s"/>' % STONE
	s += '<path d="M-38 116 V48 Q-38 10 0 10 Q6 10 10 12 Q-26 18 -26 52 V116 Z" fill="%s" opacity="0.8"/>' % STONE_LIGHT
	s += '<path d="M-29 112 V50 Q-29 20 0 20 Q29 20 29 50 V112" fill="none" %s opacity="0.6"/>' % _stroke(STONE_DARK, 2.5)
	match kind:
		0:
			# R I P, cut into the stone.
			s += '<path d="M-21 44 v30 M-21 44 h11 q7 0 7 8 q0 8 -7 8 h-11 M-13 60 l9 14" fill="none" %s/>' % _stroke(STONE_DARK, 4)
			s += '<path d="M0 44 v30" fill="none" %s/>' % _stroke(STONE_DARK, 4)
			s += '<path d="M11 74 v-30 h10 q7 0 7 8 q0 8 -7 8 h-10" fill="none" %s/>' % _stroke(STONE_DARK, 4)
		1:
			# A cross.
			s += '<path d="M-15 46 h30 M0 32 v48" fill="none" %s/>' % _stroke(STONE_DARK, 6)
		_:
			# A little skull carved in it.
			s += '<path d="M-14 42 q0 -16 14 -16 q14 0 14 16 q0 10 -5 14 h-18 q-5 -4 -5 -14 z" fill="%s"/>' % STONE_DARK
			s += '<ellipse cx="-5" cy="40" rx="4" ry="5" fill="%s"/><ellipse cx="5" cy="40" rx="4" ry="5" fill="%s"/>' % [STONE_LIGHT, STONE_LIGHT]
	s += '<path d="M-24 88 h48 M-18 98 h36" fill="none" %s opacity="0.55"/>' % _stroke(STONE_DARK, 3)
	# Cracks and the moss creeping up the foot.
	s += '<path d="M-34 70 l6 10 l-4 8" fill="none" %s opacity="0.5"/>' % _stroke(STONE_DARK, 2)
	s += '<path d="M-40 118 q10 -14 22 -6 q12 -10 24 -2 q10 -8 18 2 v6 z" fill="#4C6B3A" opacity="0.75"/>'
	return s + "</g>"


# The low picket fence around a little graveyard.
static func _grave_fence() -> String:
	var s := ""
	var x := 6.0
	while x < 182.0:
		s += '<path d="M%s 122 v-22 l4 -6 l4 6 v22 z" fill="%s" %s/>' % [x, "#4A4A52", _stroke("#2B2B33", 1.6)]
		x += 15.0
	s += '<rect x="4" y="104" width="180" height="4" fill="#3B3B43"/>'
	s += '<rect x="4" y="116" width="180" height="4" fill="#3B3B43"/>'
	return s


# Skeleton hands and forearms clawing their way out of the lawn, with the earth pushed up around them.
static func _bones() -> String:
	var s := ""
	# The mounds of earth they have pushed up, and the crack each one opened.
	for m: Array in [[38.0, 22.0], [104.0, 27.0], [140.0, 15.0]]:
		s += '<ellipse cx="%s" cy="84" rx="%s" ry="%s" fill="%s"/>' % [m[0], float(m[1]) * 1.6, m[1] * 0.52, EARTH]
		s += '<ellipse cx="%s" cy="81" rx="%s" ry="%s" fill="%s" opacity="0.85"/>' % [m[0], float(m[1]) * 1.25, float(m[1]) * 0.36, EARTH_LIGHT]
		s += '<path d="M%s 80 q6 -5 12 0 q6 5 12 0" fill="none" %s opacity="0.6"/>' % [float(m[0]) - 18.0, _stroke("#2E2318", 2)]
	s += _hand(38, 82, 1.0, -14.0)
	s += _hand(104, 84, 1.2, 12.0)
	# A third one only just breaking through: the fingertips alone.
	s += '<g transform="translate(140 82) rotate(8)">'
	for i in 3:
		s += '<path d="M%s 0 v-11 q0 -4 3.5 -4 q3.5 0 3.5 4 v11 z" fill="%s" %s/>' % [-9 + i * 7, BONE, _stroke(BONE_LINE, 1.5)]
	s += "</g>"
	# A few blades of grass in front, so they really come out of the lawn.
	for g: Array in [[14.0, 7.0], [60.0, 10.0], [84.0, 7.0], [122.0, 9.0], [152.0, 6.0]]:
		s += '<path d="M%s 88 q2 -%s 5 -%s" fill="none" %s/>' % [g[0], float(g[1]) * 1.7, g[1], _stroke("#4C6B3A", 2.6)]
	return s


# One forearm out of the ground, its hand open and clawing: the two bones of the arm, a wrist, a palm and five
# bony fingers, each with its knuckles.
static func _hand(x: float, y: float, scale: float, tilt: float) -> String:
	var line := _stroke(BONE_LINE, 1.6)
	var s := '<g transform="translate(%s %s) rotate(%s) scale(%s)">' % [x, y, tilt, scale]
	# The two bones of the forearm, coming out of the earth.
	s += '<path d="M-8 6 q-4 -18 -3 -30 q3 -3 6 0 q1 13 3 30 z" fill="%s" %s/>' % [BONE, line]
	s += '<path d="M3 6 q3 -18 4 -30 q3 -3 6 0 q-1 13 -4 30 z" fill="%s" %s/>' % [BONE, line]
	# The wrist and the palm.
	s += '<ellipse cx="0" cy="-26" rx="4" ry="3" fill="%s" %s/>' % [BONE_SHADE, line]
	s += '<path d="M-11 -30 q11 -9 22 0 q3 10 -2 15 h-18 q-5 -5 -2 -15 z" fill="%s" %s/>' % [BONE, line]
	s += '<path d="M-9 -28 q7 -6 15 -3 q-10 1 -13 12 z" fill="#FFFFFF" opacity="0.55"/>'
	# Four fingers and a thumb, bony and curled, each with two knuckles.
	for f: Array in [[-10.0, -17.0, -25.0, -22.0, -37.0], [-4.0, -8.0, -32.0, -11.0, -46.0],
			[3.0, 2.0, -33.0, 6.0, -47.0], [10.0, 14.0, -26.0, 20.0, -38.0]]:
		s += '<path d="M%s -31 Q%s %s %s %s" fill="none" %s/>' % [f[0], f[1], f[2], f[3], f[4], _stroke(BONE, 4.2)]
		s += '<path d="M%s -31 Q%s %s %s %s" fill="none" %s opacity="0.55"/>' % [f[0], f[1], f[2], f[3], f[4], _stroke(BONE_LINE, 1.2)]
		s += '<circle cx="%s" cy="%s" r="2.6" fill="%s" %s/>' % [f[1], f[2], BONE, line]
		s += '<circle cx="%s" cy="%s" r="2.2" fill="%s" %s/>' % [f[3], f[4], BONE, line]
	s += '<path d="M-11 -26 Q-21 -28 -25 -36" fill="none" %s/>' % _stroke(BONE, 4.4)
	s += '<path d="M-11 -26 Q-21 -28 -25 -36" fill="none" %s opacity="0.55"/>' % _stroke(BONE_LINE, 1.2)
	s += '<circle cx="-25" cy="-36" r="2.4" fill="%s" %s/>' % [BONE, line]
	return s + "</g>"


# A whole skeleton standing in the garden, the kind sold on a hook: a spine of vertebrae, a real ribcage, a
# pelvis, and arms and legs with their joints.
static func _skeleton() -> String:
	var line := _stroke(BONE_LINE, 1.8)
	var s := _ground_shadow(48, 192, 32)
	# Legs: thigh, knee, shin, foot.
	for side: float in [-1.0, 1.0]:
		var hx := 48.0 + side * 9.0
		s += '<path d="M%s 118 Q%s 142 %s 150" fill="none" %s/>' % [hx, hx + side * 4.0, hx + side * 6.0, _stroke(BONE, 8)]
		s += '<circle cx="%s" cy="152" r="5" fill="%s" %s/>' % [hx + side * 6.0, BONE, line]
		s += '<path d="M%s 155 Q%s 170 %s 182" fill="none" %s/>' % [hx + side * 6.0, hx + side * 7.0, hx + side * 6.0, _stroke(BONE, 6.5)]
		s += '<path d="M%s 182 q%s 0 %s 7 h-%s z" fill="%s" %s/>' % [hx + side * 3.0, side * 11.0, side * 11.0, 11, BONE, line]
	# Pelvis.
	s += '<path d="M30 104 q18 -7 36 0 q1 12 -8 16 h-20 q-9 -4 -8 -16 z" fill="%s" %s/>' % [BONE, line]
	s += '<path d="M40 112 q8 6 16 0 q-4 10 -8 10 q-4 0 -8 -10 z" fill="%s" opacity="0.6"/>' % BONE_SHADE
	# Spine: a little stack of vertebrae.
	for i in 6:
		s += '<rect x="44" y="%s" width="9" height="6" rx="2.5" fill="%s" %s/>' % [54 + i * 9, BONE, line]
	# Ribcage: five pairs of ribs curving round, with the sky showing between them.
	for i in 5:
		var ry := 58.0 + i * 11.0
		var rw := 23.0 - absf(float(i) - 1.4) * 2.2
		s += '<path d="M46 %s Q%s %s %s %s" fill="none" %s/>' % [ry, 46.0 - rw, ry + 1.0, 48.0 - rw * 0.82, ry + 12.0, _stroke(BONE, 4.6)]
		s += '<path d="M51 %s Q%s %s %s %s" fill="none" %s/>' % [ry, 51.0 + rw, ry + 1.0, 49.0 + rw * 0.82, ry + 12.0, _stroke(BONE, 4.6)]
	s += '<path d="M48 54 q-18 2 -22 10 M48 54 q18 2 22 10" fill="none" %s/>' % _stroke(BONE, 6)
	# Arms: upper arm, elbow, forearm, a little hand.
	for side: float in [-1.0, 1.0]:
		var sx := 48.0 + side * 22.0
		s += '<path d="M%s 58 Q%s 76 %s 90" fill="none" %s/>' % [sx, sx + side * 7.0, sx + side * 8.0, _stroke(BONE, 6.5)]
		s += '<circle cx="%s" cy="92" r="4.2" fill="%s" %s/>' % [sx + side * 8.0, BONE, line]
		s += '<path d="M%s 95 Q%s 110 %s 122" fill="none" %s/>' % [sx + side * 8.0, sx + side * 10.0, sx + side * 8.0, _stroke(BONE, 5.5)]
		s += '<path d="M%s 122 q%s 4 %s 12 q-%s 4 -%s -4 z" fill="%s" %s/>' % [sx + side * 6.0, side * 7.0, side * 5.0, side * 6.0, side * 7.0, BONE, line]
	s += '<rect x="43" y="44" width="11" height="12" rx="4" fill="%s" %s/>' % [BONE, line]
	s += _skull(48, 26, 1.0)
	return s


# A skull: two deep sockets, a nose and a row of teeth.
static func _skull(cx: float, cy: float, scale: float) -> String:
	var s := '<g transform="translate(%s %s) scale(%s)">' % [cx, cy, scale]
	s += '<path d="M-23 4 q0 -26 23 -26 q23 0 23 26 q0 13 -7 19 l1 10 q-17 5 -34 0 l1 -10 q-7 -6 -7 -19 z" fill="%s" %s/>' % [BONE, _stroke(BONE_LINE, 2)]
	s += '<path d="M-18 -4 q-2 -18 12 -22 q-14 8 -8 22 z" fill="#FFFFFF" opacity="0.5"/>'
	s += '<ellipse cx="-9" cy="0" rx="7.5" ry="8.5" fill="%s"/><ellipse cx="9" cy="0" rx="7.5" ry="8.5" fill="%s"/>' % [NIGHT, NIGHT]
	s += '<ellipse cx="-10.5" cy="-2" rx="2.5" ry="3" fill="#574E62" opacity="0.8"/>'
	s += '<path d="M0 8 l-4 8 h8 z" fill="%s"/>' % NIGHT
	s += '<path d="M-11 22 h22" fill="none" %s/>' % _stroke(BONE_LINE, 2)
	for i in 5:
		s += '<path d="M%s 18 v9" fill="none" %s/>' % [-10 + i * 5, _stroke(BONE_LINE, 1.6)]
	return s + "</g>"


# A scarecrow on his post, a sack over his head.
static func _scarecrow() -> String:
	var s := _ground_shadow(62, 200, 34)
	s += '<rect x="57" y="46" width="10" height="152" fill="%s" %s/>' % [WOOD, _stroke(WOOD_DARK, 2)]
	s += '<rect x="16" y="78" width="92" height="9" rx="4" fill="%s" %s/>' % [WOOD, _stroke(WOOD_DARK, 2)]
	s += '<path d="M32 86 Q62 72 92 86 L98 146 Q62 160 26 146 Z" fill="#C9562E" %s/>' % _stroke("#8E3A1E", 2.5)
	s += '<path d="M32 86 Q46 79 58 78 L54 152 Q38 150 26 146 Z" fill="#DD6A3C" opacity="0.6"/>'
	for i in 6:
		s += '<path d="M%s 92 v52" fill="none" %s opacity="0.4"/>' % [34 + i * 11, _stroke("#8E3A1E", 2)]
	# Straw out of the sleeves and the hem.
	for p: Array in [[30.0, 88.0, -16.0, 16.0], [94.0, 88.0, 16.0, 16.0]]:
		for j in 4:
			s += '<path d="M%s %s l%s %s" fill="none" %s/>' % [p[0], p[1], float(p[2]) + j * 2, float(p[3]) + j * 2, _stroke(STRAW, 3.5)]
	for i in 6:
		s += '<path d="M%s 148 l-3 20" fill="none" %s/>' % [32 + i * 12, _stroke(STRAW, 3.5)]
	s += '<path d="M36 44 q26 -18 52 0 q4 22 -8 28 q-18 8 -36 0 q-12 -6 -8 -28 z" fill="#D9A23A" %s/>' % _stroke("#A8762A", 2.5)
	s += '<path d="M38 42 q18 -14 36 -8 q-20 2 -30 14 z" fill="#E8BC62" opacity="0.7"/>'
	s += '<path d="M26 34 Q62 14 98 34 Q62 28 26 34 Z" fill="%s" %s/>' % [STRAW_DARK, _stroke("#7E6418", 2)]
	s += '<path d="M48 44 l11 11 l-11 11 z" fill="%s"/><path d="M78 44 l-11 11 l11 11 z" fill="%s"/>' % [NIGHT, NIGHT]
	s += '<path d="M50 66 q12 10 24 0" fill="none" %s/>' % _stroke(NIGHT, 3)
	for i in 4:
		s += '<path d="M%s 66 v6" fill="none" %s/>' % [54 + i * 6, _stroke(NIGHT, 2)]
	s += '<path d="M34 70 q28 10 56 0" fill="none" %s/>' % _stroke("#8E3A1E", 4)
	return s


# A black cat sitting in the garden, its tail curled round its paws.
static func _cat() -> String:
	var s := _ground_shadow(48, 86, 30)
	s += '<path d="M26 84 q-14 2 -16 -8 q-2 -8 8 -8 q8 0 12 8 z" fill="#1B1B22"/>'
	s += '<path d="M30 84 Q20 50 36 34 Q52 20 64 34 Q78 50 70 84 Z" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2.5)]
	s += '<path d="M36 80 Q30 54 40 38 Q34 60 42 80 z" fill="#3A3A46" opacity="0.7"/>'
	s += '<ellipse cx="50" cy="30" rx="19" ry="17" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2.5)]
	s += '<path d="M34 20 l-3 -18 l15 8 z M66 20 l3 -18 l-15 8 z" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2)]
	s += '<path d="M36 18 l-1 -9 l7 4 z" fill="#4A3A42" opacity="0.8"/>'
	s += '<ellipse cx="42" cy="28" rx="5" ry="7" fill="#9BD16A"/><ellipse cx="58" cy="28" rx="5" ry="7" fill="#9BD16A"/>'
	s += '<ellipse cx="42" cy="28" rx="1.8" ry="6" fill="#1B2A12"/><ellipse cx="58" cy="28" rx="1.8" ry="6" fill="#1B2A12"/>'
	s += '<circle cx="40.5" cy="25" r="1.6" fill="#FFFFFF" opacity="0.8"/><circle cx="56.5" cy="25" r="1.6" fill="#FFFFFF" opacity="0.8"/>'
	s += '<path d="M50 38 l-3 -3 h6 z" fill="#5E4A52"/>'
	s += '<path d="M46 40 q-12 -2 -18 -6 M46 42 q-12 2 -17 5 M54 40 q12 -2 18 -6 M54 42 q12 2 17 5" fill="none" %s opacity="0.7"/>' % _stroke("#6E6E7A", 1.4)
	s += '<ellipse cx="38" cy="82" rx="8" ry="5" fill="#15151B"/><ellipse cx="58" cy="82" rx="8" ry="5" fill="#15151B"/>'
	return s


# A bale of straw with pumpkins, a pot of mums and corn stalks tied behind it.
static func _hay() -> String:
	var s := _ground_shadow(88, 110, 76)
	# The corn stalks, tied in a sheaf behind.
	s += '<g transform="translate(142 108)">'
	for i in 5:
		var lean := -16.0 + i * 8.0
		s += '<path d="M0 0 Q%s -50 %s -96" fill="none" %s/>' % [lean * 0.4, lean, _stroke("#A8933E", 4)]
		s += '<path d="M%s -60 q-16 -6 -24 -20 M%s -46 q16 -8 24 -22" fill="none" %s/>' % [lean * 0.62, lean * 0.5, _stroke("#8E7C34", 3.5)]
	s += '<rect x="-12" y="-34" width="24" height="8" rx="4" fill="%s"/>' % WOOD_DARK
	s += "</g>"
	# The bale.
	s += '<rect x="14" y="58" width="104" height="50" rx="7" fill="%s" %s/>' % [STRAW, _stroke(STRAW_DARK, 3)]
	for i in 7:
		s += '<path d="M%s 62 q6 20 0 42" fill="none" %s opacity="0.5"/>' % [20 + i * 14, _stroke(STRAW_DARK, 2)]
	s += '<rect x="14" y="58" width="104" height="10" rx="5" fill="#E8C878" opacity="0.7"/>'
	s += '<rect x="40" y="56" width="7" height="54" fill="#6E5A2E"/><rect x="88" y="56" width="7" height="54" fill="#6E5A2E"/>'
	# The pot of mums and the pumpkins in front.
	s += '<path d="M116 86 h34 l-5 24 h-24 z" fill="#B5603F" %s/>' % _stroke("#8A4228", 2.5)
	s += '<rect x="113" y="80" width="40" height="9" rx="4" fill="#C47050" %s/>' % _stroke("#8A4228", 2)
	for b: Array in [[122.0, 72.0, 9.0, "#D9452A"], [134.0, 66.0, 10.0, "#E8812E"], [146.0, 74.0, 8.0, "#F2C230"],
			[128.0, 78.0, 8.0, "#C8343F"], [141.0, 80.0, 7.0, "#E8812E"]]:
		s += '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % [b[0], b[1], b[2], b[3]]
		s += '<circle cx="%s" cy="%s" r="%s" fill="#FFE2A8" opacity="0.5"/>' % [float(b[0]) - 2.0, float(b[1]) - 2.0, float(b[2]) * 0.4]
	s += _pumpkin(32, 110, 22, ORANGE, DEEP)
	s += _pumpkin(66, 110, 15, "#F0A24A", "#C8721F")
	return s


# Little lamps on stakes down the path, each a small pumpkin of glass.
static func _stakes() -> String:
	var s := ""
	for p: Array in [[20.0, 22.0, 0.9], [84.0, 16.0, 1.05], [148.0, 24.0, 0.85]]:
		var cx: float = p[0]
		var top: float = p[1]
		var k: float = p[2]
		s += _ground_shadow(cx, 84.0, 14.0 * k)
		s += '<path d="M%s 84 V%s" fill="none" %s/>' % [cx, top + 14.0 * k, _stroke("#2E2E36", 4)]
		s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#F2A24A" %s/>' % [cx, top, 13.0 * k, 11.0 * k, _stroke("#B5651A", 2)]
		s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFE2A0"/>' % [cx, top, 8.0 * k, 7.0 * k]
		s += '<path d="M%s %s l%s -%s l%s %s z" fill="#7A4410"/>' % [cx - 5.0 * k, top + 1.0, 5.0 * k, 6.0 * k, 5.0 * k, 6.0 * k]
		s += '<path d="M%s %s q%s %s %s 0" fill="#7A4410"/>' % [cx - 6.0 * k, top + 5.0 * k, 6.0 * k, 7.0 * k, 12.0 * k]
		s += '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s"/>' % [cx - 2.0 * k, top - 14.0 * k, 4.0 * k, 6.0 * k, GREEN]
	return s


# ── On the facade and the balcony ───────────────────────────────

# A cobweb in the corner of the facade, its spider hanging on a thread.
static func _web() -> String:
	var s := ""
	for i in 8:
		var a := deg_to_rad(5.0 + i * 11.5)
		s += '<path d="M4 4 L%.1f %.1f" %s opacity="0.8"/>' % [4.0 + cos(a) * 140.0, 4.0 + sin(a) * 140.0, _stroke(BONE, 1.8)]
	for r: float in [26.0, 48.0, 72.0, 98.0, 124.0]:
		var d := "M%.1f 4" % (4.0 + r)
		for i in 9:
			var a := deg_to_rad(i * 11.0)
			d += " Q%.1f %.1f %.1f %.1f" % [4.0 + cos(a + 0.1) * r * 0.84, 4.0 + sin(a + 0.1) * r * 0.84,
				4.0 + cos(a + 0.185) * r, 4.0 + sin(a + 0.185) * r]
		s += '<path d="%s" fill="none" %s opacity="0.7"/>' % [d, _stroke(BONE, 1.5)]
	s += '<path d="M98 26 V58" %s opacity="0.8"/>' % _stroke(BONE, 1.4)
	s += '<ellipse cx="98" cy="70" rx="12" ry="10" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 1.6)]
	s += '<ellipse cx="94" cy="67" rx="4" ry="3" fill="#43434E" opacity="0.8"/>'
	s += '<circle cx="98" cy="57" r="7" fill="%s"/>' % BLACK
	s += '<path d="M88 60 l-14 -9 M88 67 l-16 2 M88 74 l-13 11 M108 60 l14 -9 M108 67 l16 2 M108 74 l13 11" fill="none" %s/>' % _stroke(BLACK, 2.6)
	s += '<circle cx="94" cy="55" r="2.2" fill="#E8542F"/><circle cx="102" cy="55" r="2.2" fill="#E8542F"/>'
	return s


# A sheet ghost hung from the balcony by a thread, its hem torn into points.
static func _ghost() -> String:
	var s := '<path d="M56 0 V18" %s opacity="0.7"/>' % _stroke("#9A968E", 2)
	s += '<path d="M18 92 C14 38 40 18 56 18 C73 18 100 38 94 92 Q88 112 81 96 Q73 116 66 98 Q57 118 48 98 Q40 116 32 96 Q25 112 18 92 Z" fill="#F7F5EF" %s/>' % _stroke("#CFC9BC", 2.5)
	s += '<path d="M26 72 C22 36 40 22 54 22 C44 30 34 46 34 74 Z" fill="#FFFFFF" opacity="0.8"/>'
	s += '<path d="M74 40 q14 18 12 50 q-2 10 -6 4 q6 -28 -8 -52 z" fill="#D8D2C4" opacity="0.7"/>'
	s += '<ellipse cx="44" cy="52" rx="8" ry="10" fill="%s"/><ellipse cx="70" cy="52" rx="8" ry="10" fill="%s"/>' % [NIGHT, NIGHT]
	s += '<circle cx="42" cy="48" r="2.4" fill="#FFFFFF" opacity="0.7"/><circle cx="68" cy="48" r="2.4" fill="#FFFFFF" opacity="0.7"/>'
	s += '<ellipse cx="57" cy="72" rx="8" ry="7" fill="%s"/>' % NIGHT
	return s


# A big spider on the wall, hanging from its thread.
static func _spider() -> String:
	var s := '<path d="M62 0 V34" %s opacity="0.7"/>' % _stroke(BONE, 1.8)
	for i in 4:
		var y := 50.0 + i * 11.0
		s += '<path d="M38 %s q-24 -8 -32 %s" fill="none" %s/>' % [y, -16 + i * 11, _stroke(BLACK, 5.5)]
		s += '<path d="M86 %s q24 -8 32 %s" fill="none" %s/>' % [y, -16 + i * 11, _stroke(BLACK, 5.5)]
	s += '<ellipse cx="62" cy="72" rx="28" ry="24" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2)]
	s += '<ellipse cx="52" cy="64" rx="10" ry="7" fill="#43434E" opacity="0.7"/>'
	s += '<path d="M62 56 l-7 14 l7 12 l7 -12 z" fill="#5A3A62" opacity="0.8"/>'
	s += '<circle cx="62" cy="44" r="16" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2)]
	s += '<circle cx="55" cy="41" r="4" fill="#E8542F"/><circle cx="68" cy="41" r="4" fill="#E8542F"/>'
	s += '<circle cx="54" cy="40" r="1.5" fill="#FFD9C0"/><circle cx="67" cy="40" r="1.5" fill="#FFD9C0"/>'
	s += '<circle cx="58" cy="50" r="2.2" fill="#8E3A1E"/><circle cx="66" cy="50" r="2.2" fill="#8E3A1E"/>'
	return s


# Bats stuck on the brick, as if they had just landed.
static func _bats() -> String:
	var s := ""
	for b: Array in [[26.0, 74.0, 1.0, -8.0], [86.0, 30.0, 0.82, 6.0], [142.0, 66.0, 0.92, -4.0]]:
		s += '<g transform="translate(%s %s) rotate(%s) scale(%s)">' % [b[0], b[1], b[3], b[2]]
		s += '<path d="M0 0 L-36 -16 L-27 3 L-42 10 L-19 19 L0 11 L19 19 L42 10 L27 3 L36 -16 Z" fill="%s" %s/>' % [BLACK, _stroke("#15151B", 2)]
		s += '<path d="M-19 19 L0 11 L0 -4 L-27 3 Z" fill="#35353F" opacity="0.6"/>'
		s += '<circle cx="0" cy="-2" r="7" fill="%s"/>' % BLACK
		s += '<path d="M-6 -7 l-2 -7 l6 3 z M6 -7 l2 -7 l-6 3 z" fill="%s"/>' % BLACK
		s += '<circle cx="-3" cy="-2" r="2.2" fill="#E8542F"/><circle cx="3" cy="-2" r="2.2" fill="#E8542F"/>'
		s += "</g>"
	return s


# A garland of little pumpkins and bats along the balcony railing.
static func _garland() -> String:
	var s := '<path d="M4 8 Q72 46 144 16 Q216 46 284 8" fill="none" %s/>' % _stroke("#3A3A42", 3)
	for i in 10:
		var t := (i + 0.5) / 10.0
		var gx := 4.0 + t * 280.0
		var gy := 10.0 + sin(t * PI * 2.0) * 17.0 + 17.0
		if i % 3 == 2:
			s += '<path d="M%s %s l10 -7 l10 7 l-10 11 z" fill="%s" %s/>' % [gx - 10, gy, PURPLE, _stroke("#5E3BA0", 1.6)]
		else:
			s += '<path d="M%s %s v-7" %s/>' % [gx, gy - 9, _stroke(GREEN, 3)]
			s += '<ellipse cx="%s" cy="%s" rx="10" ry="9" fill="%s" %s/>' % [gx, gy, ORANGE, _stroke(DEEP, 1.8)]
			s += '<path d="M%s %s q0 8 0 0" %s/>' % [gx - 4, gy - 6, _stroke(DEEP, 1.4)]
			s += '<ellipse cx="%s" cy="%s" rx="3" ry="2.4" fill="#FFD9A8" opacity="0.6"/>' % [gx - 3, gy - 3]
	return s
