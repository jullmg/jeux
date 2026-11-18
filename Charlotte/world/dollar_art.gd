class_name DollarArt
extends RefCounted
## The Dollarama on Rue Masson, drawn as SVG at runtime (like ShopArt): the long white gondolas of its aisles stocked by
## department, the aisle ends seen from the front of the store, the mouth of an aisle running back in perspective, the green
## and yellow hanging signs, and the little pictures of what she can buy. What a Dollarama sells (its own departments):
## party supplies, kitchen, cleaning, candy and snacks, toys and school supplies, the season's things; everything at most 5 $.
## Light from the upper left. Every product shape is drawn from a few helpers with their own random numbers, so a shelf
## is always the same shelf.

const GREEN := "#00843D"
const GREEN_DARK := "#005A2A"
const YELLOW := "#FFD200"
const METAL := "#E9EAEC"
const METAL_DARK := "#B9BCC0"

## The aisles, in their order from the door: [id, the sign's words].
const AISLES := [["fete", "FÊTE"], ["cuisine", "CUISINE"], ["entretien", "ENTRETIEN"], ["bonbons", "BONBONS ET COLLATIONS"],
	["jouets", "JOUETS ET ÉCOLE"], ["saison", "SAISON"]]


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return InteriorArt.tex(w, h, body)


static func _r(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _c(x: float, y: float, r: float, fill: String, extra := "") -> String:
	return '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" %s/>' % [x, y, r, fill, extra]


static func _p(d: String, fill: String, extra := "") -> String:
	return '<path d="%s" fill="%s" %s/>' % [d, fill, extra]


static func _bright(rng: RandomNumberGenerator) -> String:
	return ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#FF7BA3", "#1FB5C4", "#F2F0EA"][rng.randi_range(0, 8)]


static func _defs() -> String:
	return ('<defs><linearGradient id="met" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF"/>'
		+ '<stop offset="1" stop-color="#D5D8DC"/></linearGradient>'
		+ '<linearGradient id="shine" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.45"/>'
		+ '<stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>'
		+ '<linearGradient id="deep" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000000" stop-opacity="0.28"/>'
		+ '<stop offset="1" stop-color="#000000" stop-opacity="0"/></linearGradient></defs>')


# ── Products ────────────────────────────────────────────────────

static func _product(kind: String, x: float, base: float, rng: RandomNumberGenerator) -> Array:
	# One item standing on a shelf at `base`, its left edge at x; returns [svg, width].
	var c := _bright(rng)
	var s := ""
	var w := 30.0
	match kind:
		"balloons":
			w = 40.0
			for i in 3:
				var bc := _bright(rng)
				var bx := x + 8.0 + i * 12.0
				var by := base - 46.0 - (i % 2) * 8.0
				s += _p("M%.1f %.1f L%.1f %.1f" % [bx, by + 12.0, x + 20.0, base - 6.0], "none", 'stroke="#8E8A82" stroke-width="1"')
				s += '<ellipse cx="%.1f" cy="%.1f" rx="9" ry="11" fill="%s"/>' % [bx, by, bc]
				s += _c(bx - 3.0, by - 4.0, 2.5, "#FFFFFF", 'opacity="0.5"')
			s += _r(x + 6, base - 10, 28, 10, "#F2F0EA", 'stroke="#B9B2A5"')
		"giftbag":
			w = 32.0
			s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 5, base - 40, x + 27, base - 40, x + 30, base], c, 'stroke="#00000033"')
			s += _p("M%.1f %.1f Q%.1f %.1f %.1f %.1f" % [x + 10, base - 40, x + 16, base - 54, x + 22, base - 40], "none", 'stroke="%s" stroke-width="2"' % _bright(rng))
			s += _c(x + 16, base - 22, 5, "#FFFFFF", 'opacity="0.6"')
		"cards":
			w = 22.0
			s += _r(x + 1, base - 34, 20, 30, "#F4F1EA", 'stroke="#C9C3B8"') + _r(x + 4, base - 30, 14, 12, c)
		"hats":
			w = 26.0
			s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 13, base - 36, x + 24, base], c)
			s += _c(x + 13, base - 37, 4, YELLOW)
			s += _p("M%.1f %.1f L%.1f %.1f" % [x + 7, base - 14, x + 19, base - 14], "none", 'stroke="#FFFFFF" stroke-width="2"')
		"mug":
			w = 28.0
			s += _r(x + 3, base - 24, 18, 24, c, 'rx="3"') + _p("M%.1f %.1f q8 0 8 7 q0 7 -8 7" % [x + 21, base - 19], "none", 'stroke="%s" stroke-width="3"' % c)
			s += _r(x + 5, base - 22, 4, 18, "#FFFFFF", 'opacity="0.35"')
		"plates":
			w = 40.0
			for i in 5:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="18" ry="4" fill="%s" stroke="#00000022"/>' % [x + 20, base - 3 - i * 4, c if i % 2 == 0 else "#F4F1EA"]
		"containers":
			w = 36.0
			s += _r(x + 2, base - 22, 32, 22, "#DDEFF5", 'opacity="0.8" stroke="#9EC3D0"') + _r(x, base - 26, 36, 6, c, 'rx="2"')
		"utensils":
			w = 24.0
			for i in 3:
				s += _r(x + 4 + i * 6, base - 38, 3, 34, "#B9BCC0") + _c(x + 5.5 + i * 6, base - 40, 3, "#D5D8DC")
			s += _r(x + 1, base - 12, 22, 12, c)
		"spray":
			w = 24.0
			s += _r(x + 4, base - 34, 16, 34, c, 'rx="4"') + _r(x + 8, base - 44, 9, 10, "#F2F0EA") + _r(x + 15, base - 46, 8, 4, "#F2F0EA")
			s += _r(x + 6, base - 24, 12, 10, "#FFFFFF", 'opacity="0.7"')
		"jug":
			w = 34.0
			s += _p("M%.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 2, base - 34, x + 2, base - 44, x + 16, base - 44, x + 32, base], c)
			s += _r(x + 22, base - 50, 8, 8, "#F2F0EA") + _r(x + 6, base - 26, 16, 12, "#FFFFFF", 'opacity="0.75"')
		"sponges":
			w = 30.0
			for i in 3:
				s += _r(x + 2, base - 8 - i * 9, 26, 8, YELLOW if i % 2 == 0 else "#7CCB5A") + _r(x + 2, base - 8 - i * 9, 26, 3, "#3E8A4E")
		"towels":
			w = 34.0
			s += _r(x + 2, base - 38, 30, 38, "#F7F6F2", 'stroke="#D8D4CC"') + _r(x + 2, base - 24, 30, 10, c, 'opacity="0.8"')
		"candybag":
			w = 30.0
			s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 4, base - 38, x + 26, base - 38, x + 28, base], c)
			s += _r(x + 3, base - 42, 24, 5, c) + _c(x + 15, base - 20, 7, "#FFFFFF", 'opacity="0.7"')
			for i in 3:
				s += _c(x + 10 + i * 5, base - 20, 2.2, _bright(rng))
		"bars":
			w = 34.0
			for i in 4:
				s += _r(x + 2, base - 7 - i * 7, 30, 6, ["#5E3A22", "#C8202A", "#1D4F91", YELLOW][i % 4], 'rx="1"')
		"chips":
			w = 30.0
			s += _p("M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f Z" % [x + 2, base, x, base - 20, x + 4, base - 40, x + 26, base - 40, x + 30, base - 20, x + 28, base], c)
			s += _c(x + 15, base - 20, 7, YELLOW, 'opacity="0.8"')
		"cookies":
			w = 34.0
			s += _r(x + 2, base - 24, 30, 24, c, 'rx="2"') + _c(x + 12, base - 12, 6, "#B5803E") + _c(x + 22, base - 13, 6, "#9A6A30")
		"toycar":
			w = 36.0
			s += _r(x + 2, base - 34, 32, 34, "#E8F4FA", 'stroke="#9EC3D0"')
			s += _r(x + 7, base - 20, 22, 8, c, 'rx="3"') + _r(x + 11, base - 26, 12, 7, c, 'rx="2"') + _c(x + 12, base - 11, 3, "#2A2A2A") + _c(x + 24, base - 11, 3, "#2A2A2A")
		"balls":
			w = 30.0
			s += _c(x + 15, base - 14, 13, c) + _p("M%.1f %.1f Q%.1f %.1f %.1f %.1f" % [x + 2, base - 14, x + 15, base - 22, x + 28, base - 14], "none", 'stroke="#FFFFFF" stroke-width="3"') + _c(x + 10, base - 20, 3, "#FFFFFF", 'opacity="0.5"')
		"crayons":
			w = 30.0
			s += _r(x + 2, base - 30, 26, 30, YELLOW, 'stroke="#C9A200"')
			for i in 5:
				s += _p("M%.1f %.1f l2 -6 l2 6 z" % [x + 4 + i * 5, base - 30], ["#E04F5F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC"][i]) + _r(x + 4 + i * 5, base - 30, 4, 6, ["#E04F5F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC"][i])
			s += _r(x + 6, base - 18, 18, 8, GREEN)
		"notebooks":
			w = 30.0
			for i in 3:
				s += _r(x + 2 + i * 2, base - 34 + i * 2, 24, 32, _bright(rng), 'stroke="#00000022"')
		"dolls":
			w = 30.0
			s += _r(x + 2, base - 40, 26, 40, "#F7C6D9", 'stroke="#E0A0B8"') + _r(x + 6, base - 34, 18, 26, "#FFFFFF", 'opacity="0.7"')
			s += _c(x + 15, base - 28, 4, "#F2C29A") + _p("M%.1f %.1f l6 0 l2 12 l-10 0 z" % [x + 12, base - 24], c)
		"pumpkins":
			w = 32.0
			s += _p("M%.1f %.1f q0 -22 14 -22 q14 0 14 22 z" % [x + 2, base - 2], "#F28C28") + _r(x + 4, base - 6, 24, 6, "#E07A18")
			s += _r(x + 14, base - 28, 4, 6, "#3E6A2A") + _p("M%.1f %.1f l3 -4 l3 4 z M%.1f %.1f l3 -4 l3 4 z" % [x + 9, base - 14, x + 18, base - 14], "#2A1A0A")
		"masks":
			w = 30.0
			s += _r(x + 2, base - 38, 26, 38, "#2A2A30", 'stroke="#000"') + '<ellipse cx="%.1f" cy="%.1f" rx="9" ry="11" fill="%s"/>' % [x + 15, base - 20, ["#F4F1EA", "#7CCB5A", "#C084FC"][rng.randi_range(0, 2)]]
			s += _c(x + 12, base - 22, 2, "#000") + _c(x + 18, base - 22, 2, "#000")
		"ornaments":
			w = 30.0
			for i in 3:
				s += _c(x + 7 + i * 8, base - 8 - (i % 2) * 10, 7, _bright(rng)) + _r(x + 5 + i * 8, base - 17 - (i % 2) * 10, 4, 3, "#C9A23A")
		"eggs":
			w = 30.0
			for i in 3:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="7" fill="%s"/>' % [x + 7 + i * 8, base - 8, ["#F7C6D9", "#BFE3F7", "#FFF1A8", "#CDEFC4"][rng.randi_range(0, 3)]]
			s += _r(x + 1, base - 4, 28, 4, "#F2F0EA")
		"beachballs":
			w = 30.0
			s += _c(x + 15, base - 14, 13, "#FFFFFF") + _p("M%.1f %.1f A13 13 0 0 1 %.1f %.1f L%.1f %.1f Z" % [x + 2, base - 14, x + 15, base - 27, x + 15, base - 14], "#E04F5F")
			s += _p("M%.1f %.1f A13 13 0 0 1 %.1f %.1f L%.1f %.1f Z" % [x + 15, base - 27, x + 28, base - 14, x + 15, base - 14], "#4FA3E0") + _p("M%.1f %.1f A13 13 0 0 1 %.1f %.1f L%.1f %.1f Z" % [x + 15, base - 1, x + 2, base - 14, x + 15, base - 14], YELLOW)
		_:
			s += _r(x + 2, base - 30, w - 4, 30, c, 'stroke="#00000022"') + _r(x + 6, base - 22, w - 12, 8, "#FFFFFF", 'opacity="0.6"')
	return [s, w]


const STOCK := {
	"fete": ["balloons", "giftbag", "cards", "hats", "giftbag", "balloons", "cards"],
	"cuisine": ["mug", "plates", "containers", "utensils", "mug", "containers"],
	"entretien": ["spray", "jug", "sponges", "towels", "spray", "jug"],
	"bonbons": ["candybag", "bars", "chips", "cookies", "candybag", "chips", "bars"],
	"jouets": ["toycar", "balls", "crayons", "notebooks", "dolls", "crayons", "toycar"],
}


## What the season aisle holds this season.
static func season_stock() -> Array:
	match Season.current:
		"winter":
			return ["ornaments", "giftbag", "ornaments", "cards", "candybag"]
		"spring":
			return ["eggs", "candybag", "eggs", "cards", "balloons"]
		"summer":
			return ["beachballs", "balls", "beachballs", "toycar", "candybag"]
	return ["pumpkins", "masks", "pumpkins", "candybag", "masks"]


static func _stock(theme: String) -> Array:
	return season_stock() if theme == "saison" else STOCK.get(theme, ["box"])


# ── Gondolas ────────────────────────────────────────────────────

## How much higher than its shelves a gondola's picture goes: the overstock cartons stacked on its top.
const GONDOLA_TOP := 70.0
## The gondola's shelves (y in its picture, from its top edge GONDOLA_TOP above the green header).
const GONDOLA_SHELVES := [510.0, 430.0, 350.0, 270.0, 190.0]
const PRICES := ["1,25 $", "1,50 $", "2,00 $", "2,50 $", "3,00 $", "4,00 $", "1,00 $", "5,00 $"]


## Where the yellow price flags stick out of a gondola `w` wide: [x, y of the shelf's lip in the picture, its price].
static func talkers(w: float) -> Array:
	var out := []
	var k := 0
	var x := 150.0
	while x < w - 120.0:
		out.append([x, float(GONDOLA_SHELVES[[1, 2, 3, 0, 2, 1][k % 6]]), PRICES[(k * 3) % PRICES.size()]])
		x += 250.0 + (k % 3) * 40.0
		k += 1
	return out


## A long gondola seen face on from inside an aisle (`w` × 540): overstock cartons on its top, a green header, white metal
## uprights, a pegboard back in shadow under each shelf, five shelves stocked to the edge with this department's things in
## facings, the yellow price strip along each lip with its little white tickets, yellow price flags sticking out
## (`talkers`, their prices are labels in the scene), the kick plate at the bottom.
static func gondola(theme: String, w: float, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h := 540.0
	var t := GONDOLA_TOP
	var s := _defs()
	# Overstock on top: brown cartons, taped, some open, in stacks of one or two.
	var cx := 30.0
	while cx < w - 120.0:
		var bw := rng.randf_range(70.0, 120.0)
		var bh := rng.randf_range(34.0, 56.0)
		var stack := rng.randi_range(1, 2)
		for k in stack:
			var by := t + 30.0 - bh * (k + 1)
			var tone: String = ["#C69A64", "#B98B55", "#D2A872"][rng.randi_range(0, 2)]
			s += _r(cx, by, bw, bh, tone, 'stroke="#8E6A3E" stroke-width="1.5"')
			s += _r(cx + bw * 0.45, by, bw * 0.1, bh, "#E7D9BE", 'opacity="0.8"')
			s += _r(cx + 8, by + bh * 0.3, bw * 0.3, bh * 0.25, "#FFFFFF", 'opacity="0.55"')
			s += _r(cx + bw - 10, by, 10, bh, "#000000", 'opacity="0.12"')
		cx += bw + rng.randf_range(30.0, 160.0)
	# The back: pale metal, a pegboard of little holes, darker under each shelf where its light doesn't reach.
	s += _r(0, t + 30, w, h - t - 30, "#ECEDEE")
	var py := t + 50.0
	while py < h - 30.0:
		var px := 10.0 + fmod(py, 20.0)
		while px < w:
			s += _c(px, py, 1.4, "#C7CACE")
			px += 22.0
		py += 20.0
	for y: float in GONDOLA_SHELVES:
		s += _r(0, y - 78.0, w, 36, "url(#deep)")
	var stock := _stock(theme)
	for i in GONDOLA_SHELVES.size():
		var y: float = GONDOLA_SHELVES[i]
		var x := 8.0
		var k := rng.randi_range(0, stock.size() - 1)
		while x < w - 40.0:
			var kind: String = stock[k % stock.size()]
			# A facing of the same thing, then the next, with a little gap.
			for j in rng.randi_range(3, 6):
				var pr := _product(kind, x, y - 2.0, rng)
				s += pr[0]
				x += float(pr[1]) + 1.5
				if x > w - 40.0:
					break
			x += rng.randf_range(4.0, 12.0)
			k += 1
		# The shelf's lip, its price strip and the tickets on it, and the shade it throws on what stands below.
		s += _r(0, y, w, 10, "url(#met)", 'stroke="%s"' % METAL_DARK) + _r(0, y + 10, w, 11, YELLOW)
		s += _r(0, y + 21, w, 3, "#000000", 'opacity="0.18"')
		var tx := 30.0
		while tx < w - 30.0:
			s += _r(tx, y + 12, 24, 7, "#FFFFFF") + _r(tx + 3, y + 13.5, 12, 2, "#1E1E20", 'opacity="0.7"') + _r(tx + 3, y + 16.5, 8, 1.5, "#1E1E20", 'opacity="0.5"')
			tx += rng.randf_range(60.0, 120.0)
	# The flags: a yellow card on a clear arm, a red band at its foot.
	for tk: Array in talkers(w):
		var fx: float = tk[0]
		var fy: float = tk[1]
		s += _r(fx - 2, fy + 8, 4, 10, "#FFFFFF", 'opacity="0.6"')
		s += _r(fx - 34, fy - 32, 68, 40, YELLOW, 'rx="4" stroke="%s" stroke-width="2"' % GREEN_DARK)
		s += _r(fx - 34, fy - 2, 68, 10, "#E0302F", 'rx="2"')
		s += _r(fx - 34, fy - 32, 68, 8, "#FFFFFF", 'opacity="0.35" rx="4"')
	# The uprights every 240 px, the green header with its light from above, the kick plate.
	var ux := 0.0
	while ux <= w:
		s += _r(ux - 4, t + 40, 8, h - t - 40, "url(#met)", 'stroke="%s"' % METAL_DARK)
		ux += 240.0
	s += _r(0, t + 30, w, 16, GREEN) + _r(0, t + 30, w, 4, "#FFFFFF", 'opacity="0.3"') + _r(0, t + 44, w, 3, GREEN_DARK)
	s += _r(0, h - 20, w, 20, METAL_DARK) + _r(0, h - 20, w, 3, "#FFFFFF", 'opacity="0.4"')
	return tex(w, h, s)


## The end of an aisle's gondola as seen from the front of the store (260 × 470): a tall stocked end with the yellow "PRIX"
## card on top, this department's things down its shelves.
static func endcap(theme: String, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 260.0
	var h := 470.0
	var s := _defs() + _r(0, 30, w, h - 30, "#F4F5F6", 'stroke="%s"' % METAL_DARK)
	var stock := _stock(theme)
	for y: float in [440.0, 350.0, 260.0, 170.0]:
		# Stocked full: two of the department's things in facings of three, packed edge to edge.
		s += _r(0, y - 80.0, w, 30, "url(#deep)")
		var x := 6.0
		var kinds := [stock[rng.randi_range(0, stock.size() - 1)], stock[rng.randi_range(0, stock.size() - 1)]]
		var n := 0
		while x < w - 30.0:
			var pr := _product(kinds[(n / 3) % 2], x, y - 2.0, rng)
			s += pr[0]
			x += float(pr[1]) + 1.0
			n += 1
		s += _r(0, y, w, 10, "url(#met)") + _r(0, y + 10, w, 8, YELLOW)
	s += _r(0, 30, w, 50, GREEN) + _r(70, 0, 120, 40, YELLOW, 'rx="6" stroke="%s" stroke-width="3"' % GREEN_DARK)
	s += _r(0, h - 18, w, 18, METAL_DARK) + _r(0, 30, 8, h - 30, "#FFFFFF", 'opacity="0.4"') + _r(w - 12, 30, 12, h - 30, "#000000", 'opacity="0.12"')
	return tex(w, h, s)


## The mouth of an aisle between two ends, looking down it (w × 470): the floor's tiles running back to a far wall, the two
## gondolas either side converging, their shelves of colour, the strip lights overhead.
static func aisle_mouth(w: float, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h := 470.0
	var vp := Vector2(w / 2.0, 250.0)
	var s := _defs() + _r(0, 0, w, h, "#F7F7F5")
	# The far wall and its green band.
	s += _r(w * 0.36, 170, w * 0.28, 150, "#F2F1EC") + _r(w * 0.36, 170, w * 0.28, 14, GREEN)
	# The floor converging.
	s += _p("M0 %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [h, w * 0.36, 320, w * 0.64, 320, w, h], "#E8E6E0")
	for i in 7:
		var t := float(i) / 6.0
		var y := lerpf(320.0, h, t * t)
		s += _p("M%.1f %.1f L%.1f %.1f" % [lerpf(w * 0.36, 0, t * t), y, lerpf(w * 0.64, w, t * t), y], "none", 'stroke="#D2D0C8" stroke-width="1.5"')
	# The two gondolas, each a trapezoid of shelves.
	for side: float in [-1.0, 1.0]:
		var near_x := 0.0 if side < 0.0 else w
		var far_x := w * (0.36 if side < 0.0 else 0.64)
		s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [near_x, 20, far_x, 170, far_x, 320, near_x, h], "#F4F5F6")
		for k in 6:
			var t := float(k) / 6.0
			var ny := lerpf(60.0, h - 20.0, t)
			var fy := lerpf(178.0, 316.0, t)
			# A shelf of goods: a band of colours down the shelf, then the shelf's lip and its price strip.
			var n := 10
			for j in n:
				var a := float(j) / n
				var b := float(j + 1) / n
				var xa := lerpf(near_x, far_x, a)
				var xb := lerpf(near_x, far_x, b)
				var ya := lerpf(ny, fy, a)
				var yb := lerpf(ny, fy, b)
				# One product, a facing seen along the aisle: its colour, a white label across it, its lit top, a gap after.
				var hh := lerpf(46.0, 18.0, a) * rng.randf_range(0.6, 1.0)
				var xc := lerpf(xa, xb, 0.82)
				var yc := lerpf(ya, yb, 0.82)
				var col := _bright(rng)
				s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [xa, ya - hh, xc, yc - hh * 0.92, xc, yc, xa, ya], col)
				s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [xa, ya - hh * 0.62, xc, yc - hh * 0.58, xc, yc - hh * 0.32, xa, ya - hh * 0.36], "#FFFFFF", 'opacity="0.7"')
				s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [xa, ya - hh, xc, yc - hh * 0.92, xc, yc - hh * 0.8, xa, ya - hh * 0.86], "#FFFFFF", 'opacity="0.35"')
			s += _p("M%.1f %.1f L%.1f %.1f" % [near_x, ny, far_x, fy], "none", 'stroke="%s" stroke-width="%.1f"' % [YELLOW, 5.0])
		s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [near_x, 20, far_x, 170, far_x, 180, near_x, 50], GREEN)
	# The far end hazy with the light, and the shade between the two gondolas near the floor.
	s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [w * 0.2, 90, w * 0.8, 90, w * 0.8, 380, w * 0.2, 380], "#FFFFFF", 'opacity="0.28"')
	s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [w * 0.3, 330, w * 0.7, 330, w * 0.85, h, w * 0.15, h], "#FFFFFF", 'opacity="0.18"')
	# The strip lights down the middle.
	for i in 4:
		var t := float(i) / 4.0
		var y := lerpf(18.0, 160.0, t)
		var hw := lerpf(60.0, 14.0, t)
		s += _r(vp.x - hw, y, hw * 2.0, lerpf(8.0, 3.0, t), "#FFFFFF", 'opacity="0.95"')
	return tex(w, h, s)


# ── The front of the store ─────────────────────────────────────

## A checkout lane (560 × 380, its feet on the floor): the candy and gum rack at its mouth, the counter in white laminate with
## the green stripe, the black conveyor belt with its divider, the scanner's glass, the card terminal on its stand, the screen
## on its pole, the carousel of green bags, and the lane's light on a tall pole (its number is a label: `lane_light_at`).
static func checkout(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := _defs()
	# The impulse rack: pegs of chocolate bars, gum and mints, a sign on top.
	s += _r(6, 120, 70, 250, "#F4F5F6", 'stroke="%s" stroke-width="2"' % METAL_DARK) + _r(6, 120, 70, 20, GREEN)
	for row in 7:
		var y := 150.0 + row * 30.0
		s += _r(10, y + 22, 62, 3, METAL_DARK)
		for k in 3:
			var c: String = ["#5E3A22", "#C8202A", "#1D4F91", "#7CCB5A", YELLOW, "#E04F5F", "#C084FC"][(row * 3 + k) % 7]
			s += _r(13 + k * 20, y, 17, 22, c, 'rx="2"') + _r(15 + k * 20, y + 7, 13, 5, "#FFFFFF", 'opacity="0.65"')
	s += _r(70, 120, 6, 250, "#000000", 'opacity="0.12"')
	# The lane's light pole and its box (lit or not: the scene paints the number).
	s += _r(538, 30, 8, 210, "url(#met)", 'stroke="%s"' % METAL_DARK) + _r(516, 0, 44, 40, GREEN_DARK, 'rx="5"') + _r(520, 4, 36, 32, "#FFFFFF", 'rx="4" opacity="0.15"')
	# The counter.
	s += _r(80, 230, 470, 140, "#FBFBF8", 'stroke="#C9CCCC" stroke-width="2"')
	for px in [80.0, 236.0, 392.0]:
		s += _r(px + 4, 248, 148, 100, "#F2F3F0", 'stroke="#DCDEDB"')
	s += _r(80, 300, 470, 12, GREEN) + _r(80, 312, 470, 4, YELLOW)
	s += _r(80, 352, 470, 18, GREEN_DARK) + _r(80, 230, 470, 8, "#FFFFFF", 'opacity="0.7"')
	s += _r(530, 230, 20, 140, "#000000", 'opacity="0.08"')
	# The belt: black, a sheen, its end roller, the plastic divider, two things riding it.
	s += _r(86, 214, 250, 18, "#26272A", 'rx="4"') + _r(90, 216, 242, 4, "#FFFFFF", 'opacity="0.12"')
	s += _c(92, 223, 7, "#3A3B3F") + _r(180, 204, 60, 10, "#E9EAEC", 'rx="3" stroke="%s"' % METAL_DARK)
	s += _r(120, 190, 30, 24, _bright(rng), 'rx="3"') + _r(256, 182, 24, 32, _bright(rng), 'rx="4"')
	# The scanner's glass, red line glowing.
	s += _r(342, 216, 46, 16, "#1E2A30", 'rx="2"') + _r(346, 223, 38, 2, "#FF3B30", 'opacity="0.9"')
	# The card terminal on its stand.
	s += _r(398, 200, 6, 30, "#3A3B3F") + _r(386, 172, 30, 34, "#2B2C30", 'rx="4"') + _r(390, 176, 22, 12, "#7FD3C8") + _r(390, 192, 22, 10, "#4A4B50")
	# The screen on its pole, the store's green on it.
	s += _r(452, 150, 8, 82, "#3A3B3F") + _r(420, 108, 72, 50, "#202124", 'rx="4"') + _r(425, 113, 62, 40, "#E8F5EC")
	s += _r(425, 113, 62, 10, GREEN) + _r(430, 128, 30, 4, "#5A5A5A") + _r(430, 136, 40, 4, "#5A5A5A") + _r(465, 144, 18, 6, GREEN)
	# The bag carousel: three arms of green bags.
	s += _r(503, 150, 5, 82, "url(#met)")
	for k in 3:
		var bx := 486.0 + k * 14.0
		s += _p("M%.1f 158 l-6 44 q10 8 20 0 l-6 -44 z" % bx, ["#00A651", "#00843D", "#22B35E"][k], 'opacity="0.92"')
		s += _r(bx - 1, 154, 10, 6, "#FFFFFF", 'opacity="0.5"')
	return tex(560, 380, s)


## Where a checkout's light box is, in its picture (centre), for the lane's number.
const LANE_LIGHT_AT := Vector2(538, 20)


## The wall behind the checkouts (w × 380, its foot on the floor): white shelving stocked with a bit of everything, a green
## header with a yellow lip, a pegboard back, the yellow price strips.
static func wall_shelves(w: float, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h := 380.0
	var s := _defs() + _r(0, 30, w, h - 30, "#EEEFF0")
	var py := 50.0
	while py < h - 20.0:
		var px := 10.0 + fmod(py, 20.0)
		while px < w:
			s += _c(px, py, 1.3, "#CDD0D3")
			px += 22.0
		py += 20.0
	var all := []
	for theme: String in STOCK:
		all.append_array(STOCK[theme])
	for y: float in [360.0, 285.0, 210.0, 135.0]:
		s += _r(0, y - 70.0, w, 30, "url(#deep)")
		var x := 10.0
		while x < w - 40.0:
			var kind: String = all[rng.randi_range(0, all.size() - 1)]
			for j in rng.randi_range(2, 4):
				var pr := _product(kind, x, y - 2.0, rng)
				s += pr[0]
				x += float(pr[1]) + 1.5
				if x > w - 40.0:
					break
			x += 8.0
		s += _r(0, y, w, 8, "url(#met)") + _r(0, y + 8, w, 9, YELLOW)
	var ux := 0.0
	while ux <= w:
		s += _r(ux - 4, 30, 8, h - 30, "url(#met)", 'stroke="%s"' % METAL_DARK)
		ux += 230.0
	s += _r(0, 0, w, 32, GREEN) + _r(0, 28, w, 5, YELLOW) + _r(0, 0, w, 6, "#FFFFFF", 'opacity="0.25"')
	return tex(w, h, s)


## The storefront window beside the door (w × 420, its foot on the floor): a low white wall, then the glass in three panes of
## aluminium frame, Rue Masson outside in this season (the buildings across, the sidewalk, the road, snowbanks in winter),
## the reflections of the store's lights, and the stickers: the green band where the logo goes, a big yellow disc ("5 $",
## a label), posters.
static func storefront(w: float) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2836
	var h := 420.0
	var winter := Season.current == "winter"
	var sky: String = {"winter": "#C9D6E2", "spring": "#BFE0F4", "summer": "#AFDAF7", "autumn": "#D9E4EE"}.get(Season.current, "#C9DCEB")
	var s := _defs()
	s += _r(0, 0, w, 330, sky)
	# Across Masson: a row of brick and stone buildings, windows lit or dark, a shop band.
	var bx := -10.0
	while bx < w:
		var bw := rng.randf_range(110.0, 170.0)
		var top := rng.randf_range(40.0, 110.0)
		var brick: String = ["#A8473A", "#9C5A44", "#B88A6A", "#C9B9A0", "#7E4436"][rng.randi_range(0, 4)]
		s += _r(bx, top, bw, 240 - top, brick)
		var wy := top + 18.0
		while wy < 190.0:
			var wx := bx + 14.0
			while wx < bx + bw - 26.0:
				s += _r(wx, wy, 18, 26, "#3E4A56" if rng.randf() < 0.7 else "#F6D88A")
				wx += 34.0
			wy += 44.0
		s += _r(bx, 200, bw, 18, ["#1D4F91", "#C8202A", "#3E8E5A", "#2B2B33"][rng.randi_range(0, 3)])
		s += _r(bx + bw * 0.2, 218, bw * 0.6, 22, "#6F8DA2")
		bx += bw + 4.0
	# Their sidewalk, the road, ours.
	s += _r(0, 240, w, 20, "#E9EEF2" if winter else "#C9C6C0") + _r(0, 260, w, 50, "#5B5D61") + _r(0, 310, w, 20, "#E9EEF2" if winter else "#CFCCC6")
	for k in 6:
		s += _r(20 + k * w / 6.0, 283, 40, 4, "#E8E4D8", 'opacity="0.8"')
	if winter:
		for k in 5:
			s += '<ellipse cx="%.1f" cy="262" rx="%.1f" ry="12" fill="#F4F7FA"/>' % [rng.randf_range(0, w), rng.randf_range(40, 90)]
			s += '<ellipse cx="%.1f" cy="312" rx="%.1f" ry="10" fill="#F4F7FA"/>' % [rng.randf_range(0, w), rng.randf_range(40, 90)]
	# The store's light on the glass: broad streaks, and the ceiling lights mirrored.
	for k in 4:
		var sx := rng.randf_range(0.0, w)
		s += _p("M%.1f 0 L%.1f 0 L%.1f 330 L%.1f 330 Z" % [sx, sx + 40, sx - 60, sx - 100], "#FFFFFF", 'opacity="0.16"')
	s += _r(0, 0, w, 330, "#FFFFFF", 'opacity="0.1"')
	# Stickers: the green band along the top, posters taped low, a yellow disc.
	s += _r(0, 12, w, 44, GREEN, 'opacity="0.95"') + _r(0, 52, w, 4, YELLOW)
	s += _c(w - 90.0, 160, 58, YELLOW, 'stroke="%s" stroke-width="5"' % GREEN_DARK)
	for k in 2:
		var px := 40.0 + k * 150.0
		s += _r(px, 220, 96, 100, ["#FFFFFF", "#FFF4C2"][k], 'stroke="#C9C4B8"') + _r(px + 8, 230, 80, 40, ["#E04F5F", "#4FA3E0"][k]) + _r(px + 8, 280, 60, 8, "#5A5A5A") + _r(px + 8, 294, 44, 8, "#5A5A5A")
	# The frame: three panes, a sill, the low wall under the glass.
	for fx in [0.0, w / 3.0, 2.0 * w / 3.0, w - 10.0]:
		s += _r(fx, 0, 10, 340, "url(#met)", 'stroke="#8E959C"')
	s += _r(0, 0, w, 10, "url(#met)", 'stroke="#8E959C"') + _r(0, 330, w, 14, "url(#met)", 'stroke="#8E959C"')
	s += _r(0, 344, w, h - 344, "#F2F1EC", 'stroke="#D6D3CB"') + _r(0, h - 16, w, 16, GREEN)
	return tex(w, h, s)


## A bouquet of helium balloons tied to a weight by the till (220 × 460): foil star and heart, a rainbow foil round, latex
## balloons in the store's colours, curling ribbons down to a little weight.
static func balloon_bouquet() -> ImageTexture:
	var s := _defs()
	var weight := Vector2(110, 440)
	var balloons := [[60.0, 70.0, "star", YELLOW], [150.0, 60.0, "heart", "#E0302F"], [105.0, 40.0, "round", "rainbow"],
		[30.0, 130.0, "latex", GREEN], [190.0, 125.0, "latex", "#4FA3E0"], [80.0, 150.0, "latex", "#FF7BA3"], [140.0, 160.0, "latex", "#C084FC"]]
	for b: Array in balloons:
		var at := Vector2(b[0], b[1])
		s += _p("M%.1f %.1f Q%.1f %.1f %.1f %.1f" % [at.x, at.y + 30.0, (at.x + weight.x) / 2.0 + 20.0, (at.y + weight.y) / 2.0, weight.x, weight.y - 14.0], "none", 'stroke="#D8D4CC" stroke-width="1.2"')
	for b: Array in balloons:
		var at := Vector2(b[0], b[1])
		match b[2]:
			"star":
				var pts := ""
				for k in 10:
					var r := 34.0 if k % 2 == 0 else 15.0
					var p := at + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * r
					pts += "%.1f,%.1f " % [p.x, p.y]
				s += '<polygon points="%s" fill="%s" stroke="#C9A200" stroke-width="2"/>' % [pts, b[3]]
			"heart":
				s += _p("M%.1f %.1f c-16 -26 -46 -6 -30 16 l30 26 l30 -26 c16 -22 -14 -42 -30 -16 z" % [at.x, at.y - 6.0], b[3], 'stroke="#A51E22" stroke-width="2"')
			"round":
				var cols := ["#E0302F", "#FF8A3D", YELLOW, "#7CCB5A", "#4FA3E0", "#C084FC"]
				for k in 6:
					s += _c(at.x, at.y, 30.0 - k * 4.5, cols[k])
				s += _c(at.x, at.y, 30.0, "none", 'stroke="#B9BCC0" stroke-width="2"')
			_:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="22" ry="27" fill="%s"/>' % [at.x, at.y, b[3]]
				s += _p("M%.1f %.1f l-4 7 l8 0 z" % [at.x, at.y + 26.0], b[3])
		s += '<ellipse cx="%.1f" cy="%.1f" rx="6" ry="9" fill="#FFFFFF" opacity="0.55" transform="rotate(-25 %.1f %.1f)"/>' % [at.x - 9.0, at.y - 10.0, at.x - 9.0, at.y - 10.0]
	# The weight: a little pink heart on the floor.
	s += _p("M%.1f %.1f c-6 -10 -20 -2 -12 8 l12 10 l12 -10 c8 -10 -6 -18 -12 -8 z" % [weight.x, weight.y - 8.0], "#FF7BA3", 'stroke="#C94F7A" stroke-width="1.5"')
	return tex(220, 460, s)


## A promotional card hanging from the ceiling (240 × 84): yellow, a green border and the string's two eyelets (its words are
## a label in the scene).
static func promo_card() -> ImageTexture:
	var s := _defs()
	s += _r(4, 8, 232, 72, YELLOW, 'rx="8" stroke="%s" stroke-width="5"' % GREEN)
	s += _r(4, 8, 232, 18, "#FFFFFF", 'opacity="0.3" rx="8"')
	s += _c(40, 18, 4, "#FFFFFF", 'stroke="%s" stroke-width="2"' % GREEN_DARK) + _c(200, 18, 4, "#FFFFFF", 'stroke="%s" stroke-width="2"' % GREEN_DARK)
	return tex(240, 84, s)


## A carton an employee carries to fill the shelves (60 × 46).
static func carton() -> ImageTexture:
	var s := _r(2, 6, 56, 38, "#C69A64", 'stroke="#8E6A3E" stroke-width="2"') + _r(26, 6, 8, 38, "#E7D9BE")
	s += _p("M2 6 L12 0 L48 0 L58 6 Z", "#D2A872", 'stroke="#8E6A3E" stroke-width="1.5"') + _r(8, 20, 14, 8, "#FFFFFF", 'opacity="0.6"')
	return tex(60, 46, s)


## What she buys, as a small picture (96 × 96).
static func item(kind: String) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var s := _defs()
	var pr := _product(kind, 30.0, 80.0, rng)
	s += '<g transform="translate(-32 -35) scale(1.6)">' + str(pr[0]) + '</g>'
	return tex(96, 96, s)
