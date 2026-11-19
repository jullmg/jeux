class_name Snowman
extends Sprite2D
## The snowman of Billie and Auguste (quest "bonhomme", winter, after the Halloween evening; Julien). The two little
## neighbours roll the three balls in the middle lane; Charlotte brings what it still lacks, one thing at a time in her arms
## (`Carry` "bonhomme:<part>"): the carrot for its nose from the kitchen fridge, Maman's tin of buttons, Papa's old
## Canadiens tuque. Each one she hands them goes on it; with all three the quest is done, and it stays in the lane for the
## rest of the winter. What it has is `GameState.flags.bonhomme_parts`.
##
## As a node: the snowman itself, drawn in the kids' own units (it is a child of `BillieAuguste`), its foot at y 0.

const QUEST := "bonhomme"
const FLAG := "bonhomme_parts"
const HEADING := "⛄  Le bonhomme de neige"
## What it lacks, in the order the notebook lists them.
const PARTS := ["carotte", "boutons", "tuque"]
## What each part is called, and where she finds it (the notebook's hint).
const NAMES := {"carotte": "une carotte pour le nez", "boutons": "des boutons", "tuque": "une tuque"}
## The same, once she has it in her arms.
const THE := {"carotte": "la carotte", "boutons": "les boutons", "tuque": "la tuque"}
const WHERE := {"carotte": "dans le frigo de la cuisine", "boutons": "demande à Maman", "tuque": "demande à Papa"}
## The canvas, in the kids' units: the foot of the snowman at the bottom middle.
const W := 260.0
const H := 420.0


## The parts it already wears.
static func parts() -> Array:
	return GameState.flags.get(FLAG, [])


static func has_part(part: String) -> bool:
	return part in parts()


static func add_part(part: String) -> void:
	var now := parts().duplicate()
	if part not in now:
		now.append(part)
	GameState.flags[FLAG] = now


static func missing() -> Array:
	return PARTS.filter(func(p: String) -> bool: return not has_part(p))


## The quest is on, the snowman still lacks `part`, and she isn't already bringing it.
static func needs(part: String) -> bool:
	return Quests.active(QUEST) and not has_part(part) and Carry.item() != "bonhomme:" + part


## Billie and Auguste can ask her: it is winter (there is snow to roll) and the quest is free.
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


## In the lane: from the moment they start it, and all winter after.
static func standing() -> bool:
	return Season.is_winter() and (Quests.active(QUEST) or Quests.done(QUEST))


static func clear() -> void:
	GameState.flags.erase(FLAG)


## What the notebook says next.
static func hint() -> String:
	if Carry.what() == "bonhomme":
		return "Apporte %s à Billie et Auguste, dans la ruelle du milieu." % THE.get(Carry.id(), "ça")
	var lacks: Array = []
	for p: String in missing():
		lacks.append("%s (%s)" % [NAMES[p], WHERE[p]])
	if lacks.is_empty():
		return "Le bonhomme est presque fini : va voir Billie et Auguste dans la ruelle du milieu !"
	return "Billie et Auguste ont roulé les boules dans la ruelle du milieu. Il manque " + ", ".join(lacks) + ". Une chose à la fois dans tes bras !"


func _ready() -> void:
	centered = false
	offset = Vector2(-W / 2.0, -H)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	refresh()


## Redraws it with what it wears now.
func refresh() -> void:
	texture = picture(parts())


# ── Pictures ────────────────────────────────────────────────

## The snowman, wearing `wears` (some of PARTS). Canvas W x H, its foot at the bottom middle; light from the upper left.
static func picture(wears: Array) -> ImageTexture:
	var s := '<defs>'
	s += '<radialGradient id="snow" cx="0.36" cy="0.32" r="0.75"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.6" stop-color="#EEF3F8"/><stop offset="1" stop-color="#B9C8D8"/></radialGradient>'
	s += '<radialGradient id="mound" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C7D4E2"/></radialGradient>'
	s += '</defs>'
	var cx := W / 2.0
	# The snow heaped round its foot, and its shadow thrown to the right.
	s += '<ellipse cx="%s" cy="%s" rx="118" ry="18" fill="#8FA3B8" opacity="0.45"/>' % [cx + 22.0, H - 12.0]
	s += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="url(#mound)"/>' % [cx - 112.0, H - 6.0, cx - 60.0, H - 40.0, cx, H - 36.0, cx + 70.0, H - 40.0, cx + 116.0, H - 6.0]
	# Three balls, the bottom one a little squashed by the weight, each with the scrape of its rolling.
	var balls := [[cx, H - 92.0, 86.0, 80.0], [cx + 2.0, H - 222.0, 64.0, 60.0], [cx - 1.0, H - 318.0, 46.0, 46.0]]
	for b: Array in balls:
		s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="url(#snow)" stroke="#9FB2C6" stroke-width="2.5"/>' % b
		s += '<path d="M%s %s q%s %s %s %s" stroke="#C9D6E3" stroke-width="3" fill="none" stroke-linecap="round"/>' % [b[0] - b[2] * 0.7, b[1] + b[3] * 0.2, b[2] * 0.6, b[3] * 0.35, b[2] * 1.3, b[3] * 0.1]
		s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" opacity="0.85"/>' % [b[0] - b[2] * 0.38, b[1] - b[3] * 0.42, b[2] * 0.22, b[3] * 0.12]
	# Two branches for arms, each with a twig.
	s += _branch(Vector2(cx - 58.0, H - 236.0), Vector2(cx - 122.0, H - 290.0), -1.0)
	s += _branch(Vector2(cx + 60.0, H - 232.0), Vector2(cx + 124.0, H - 268.0), 1.0)
	# Coal eyes and a smile of pebbles, the kids' own.
	var head := Vector2(balls[2][0], balls[2][1])
	for e in [-15.0, 15.0]:
		s += '<circle cx="%s" cy="%s" r="5.5" fill="#262626"/><circle cx="%s" cy="%s" r="1.6" fill="#8A8A8A"/>' % [head.x + e, head.y - 8.0, head.x + e - 1.8, head.y - 9.8]
	for i in 5:
		var a := deg_to_rad(30.0 + i * 30.0)
		s += '<circle cx="%s" cy="%s" r="3.2" fill="#3A3A3A"/>' % [head.x + cos(a) * 22.0, head.y + 4.0 + sin(a) * 14.0]
	if "carotte" in wears:
		s += '<path d="M%s %s L%s %s L%s %s Z" fill="#FF8A2E" stroke="#C45A12" stroke-width="2" stroke-linejoin="round"/>' % [head.x - 2.0, head.y - 4.0, head.x + 46.0, head.y + 6.0, head.x - 1.0, head.y + 6.0]
		for k in 3:
			s += '<path d="M%s %s l3 7" stroke="#C45A12" stroke-width="1.5"/>' % [head.x + 10.0 + k * 10.0, head.y - 2.0 + k * 2.6]
	if "boutons" in wears:
		var colours := ["#E5383B", "#2E6FD8", "#F2B705"]
		for i in 3:
			s += _button(Vector2(balls[1][0] - 2.0 + i * 1.5, balls[1][1] - 34.0 + i * 30.0), 9.0, colours[i])
	if "tuque" in wears:
		s += _tuque(Vector2(head.x, head.y - 26.0), 50.0, true)
	return InteriorArt.tex(W, H, s)


static func _branch(from: Vector2, to: Vector2, side: float) -> String:
	var mid := from.lerp(to, 0.55)
	var s := '<path d="M%s %s L%s %s" stroke="#5C3B22" stroke-width="7" stroke-linecap="round"/>' % [from.x, from.y, to.x, to.y]
	s += '<path d="M%s %s l%s %s" stroke="#5C3B22" stroke-width="4" stroke-linecap="round"/>' % [mid.x, mid.y, side * 10.0, -26.0]
	s += '<path d="M%s %s l%s %s" stroke="#5C3B22" stroke-width="3.5" stroke-linecap="round"/>' % [to.x, to.y, side * 16.0, 4.0]
	s += '<path d="M%s %s l%s %s" stroke="#5C3B22" stroke-width="3" stroke-linecap="round"/>' % [to.x, to.y, side * 6.0, -14.0]
	return s


static func _button(c: Vector2, r: float, colour: String) -> String:
	var s := '<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="#00000055" stroke-width="1.5"/>' % [c.x, c.y, r, colour]
	s += '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="#FFFFFF66" stroke-width="1.2"/>' % [c.x, c.y, r * 0.68]
	for d in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		s += '<circle cx="%s" cy="%s" r="1.6" fill="#00000088"/>' % [c.x + d.x * r * 0.28, c.y + d.y * r * 0.28]
	return s


## Papa's old tuque of the Canadiens: red, a blue band with a white stripe, the white pompom. `c` is the middle of its brim,
## `r` half its width; `on_head` tilts it a little.
static func _tuque(c: Vector2, r: float, on_head: bool) -> String:
	var s := '<g transform="rotate(%s %s %s)">' % [-8.0 if on_head else 0.0, c.x, c.y]
	s += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="#C8102E" stroke="#8E0B20" stroke-width="2.5"/>' % [c.x - r, c.y, c.x - r * 0.95, c.y - r * 1.25, c.x, c.y - r * 1.3, c.x + r * 0.95, c.y - r * 1.25, c.x + r, c.y]
	# Knitted ribs down the crown.
	for i in 5:
		var x := c.x - r * 0.6 + i * r * 0.3
		s += '<path d="M%s %s Q%s %s %s %s" stroke="#A50D26" stroke-width="1.6" fill="none"/>' % [x, c.y - 4.0, x + (x - c.x) * 0.12, c.y - r * 0.7, c.x + (x - c.x) * 0.4, c.y - r * 1.15]
	s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" opacity="0.18"/>' % [c.x - r * 0.38, c.y - r * 0.8, r * 0.22, r * 0.32]
	# The turned-up cuff: blue, with its white stripe.
	s += '<rect x="%s" y="%s" width="%s" height="%s" rx="7" fill="#1D3A8A" stroke="#13265C" stroke-width="2.5"/>' % [c.x - r * 1.04, c.y - r * 0.36, r * 2.08, r * 0.46]
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="#FFFFFF"/>' % [c.x - r * 1.0, c.y - r * 0.17, r * 2.0, r * 0.08]
	for i in 12:
		var x := c.x - r * 0.95 + i * r * 0.17
		s += '<path d="M%s %s v%s" stroke="#13265C" stroke-width="1" opacity="0.6"/>' % [x, c.y - r * 0.32, r * 0.12]
	# The pompom.
	s += '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" stroke="#C9CED6" stroke-width="2"/>' % [c.x + 2.0, c.y - r * 1.36, r * 0.3]
	for i in 8:
		var a := TAU * i / 8.0
		s += '<path d="M%s %s l%s %s" stroke="#D5DAE2" stroke-width="1.6"/>' % [c.x + 2.0 + cos(a) * r * 0.12, c.y - r * 1.36 + sin(a) * r * 0.12, cos(a) * r * 0.14, sin(a) * r * 0.14]
	s += '</g>'
	return s


## What she carries to the lane: the carrot, Maman's button tin, Papa's tuque. Canvas 90 x 90, held in her arms.
static func item(part: String) -> ImageTexture:
	var s := ""
	match part:
		"carotte":
			s = '<path d="M10 30 L78 52 Q74 66 60 62 Z" fill="#FF8A2E" stroke="#C45A12" stroke-width="2.5" stroke-linejoin="round"/>'
			for k in 4:
				s += '<path d="M%s %s l4 7" stroke="#C45A12" stroke-width="1.6"/>' % [26 + k * 12, 36 + k * 4]
			s += '<path d="M76 54 l10 -16 M76 54 l14 -4 M76 54 l8 12" stroke="#3E8E3A" stroke-width="5" stroke-linecap="round"/>'
		"boutons":
			# The blue butter-cookie tin every grandmother keeps her buttons in, open, buttons heaped in it.
			s = '<ellipse cx="45" cy="70" rx="38" ry="12" fill="#163E8C"/>'
			s += '<rect x="7" y="44" width="76" height="26" fill="#1F55B5"/><path d="M7 52 H83" stroke="#E7C14E" stroke-width="2"/><path d="M7 64 H83" stroke="#E7C14E" stroke-width="1.5"/>'
			s += '<ellipse cx="45" cy="44" rx="38" ry="12" fill="#2A63C4" stroke="#E7C14E" stroke-width="2"/>'
			s += '<ellipse cx="45" cy="44" rx="33" ry="9" fill="#173E86"/>'
			var colours := ["#E5383B", "#F2B705", "#FFFFFF", "#3BAA5C", "#E86BB0", "#8A5A2B", "#2E6FD8"]
			for i in 9:
				s += _button(Vector2(20.0 + i * 6.5, 40.0 + (i % 3) * 3.0 - (2.0 if i % 2 == 0 else 0.0)), 5.5, colours[i % colours.size()])
		"tuque":
			s = _tuque(Vector2(45, 74), 36.0, false)
	return InteriorArt.tex(90, 90, s)
