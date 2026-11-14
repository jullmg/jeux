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

## A long gondola seen face on from inside an aisle (`w` × 470): white metal uprights, five shelves stocked to the edge with
## this department's things, the yellow price strip along each shelf's lip, a pegboard band on the second level hung with
## carded goods, the kick plate at the bottom. Canvas w × 470.
static func gondola(theme: String, w: float, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h := 470.0
	var s := _defs() + _r(0, 0, w, h, "#F4F5F6") + _r(0, 0, w, h, "url(#deep)")
	var stock := _stock(theme)
	var shelves := [440.0, 360.0, 280.0, 200.0, 120.0]
	for i in shelves.size():
		var y: float = shelves[i]
		var x := 8.0
		var k := rng.randi_range(0, stock.size() - 1)
		while x < w - 40.0:
			var kind: String = stock[k % stock.size()]
			# A facing of the same thing, then the next.
			for j in rng.randi_range(2, 5):
				var pr := _product(kind, x, y - 2.0, rng)
				s += pr[0]
				x += float(pr[1]) + 2.0
				if x > w - 40.0:
					break
			x += 6.0
			k += 1
		s += _r(0, y, w, 10, "url(#met)", 'stroke="%s"' % METAL_DARK) + _r(0, y + 10, w, 10, YELLOW)
		var tx := 30.0
		while tx < w - 30.0:
			s += _r(tx, y + 12, 22, 6, "#FFFFFF") + _r(tx + 3, y + 13.5, 16, 3, "#1E1E20", 'opacity="0.7"')
			tx += rng.randf_range(70.0, 140.0)
	# The uprights every 240 px and the kick plate.
	var ux := 0.0
	while ux <= w:
		s += _r(ux - 4, 40, 8, h - 40, "url(#met)", 'stroke="%s"' % METAL_DARK)
		ux += 240.0
	s += _r(0, 30, w, 14, GREEN) + _r(0, 30, w, 3, "#FFFFFF", 'opacity="0.3"')
	s += _r(0, h - 18, w, 18, METAL_DARK)
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
		var x := 10.0
		var kind: String = stock[rng.randi_range(0, stock.size() - 1)]
		while x < w - 40.0:
			var pr := _product(kind, x, y - 2.0, rng)
			s += pr[0]
			x += float(pr[1]) + 2.0
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
				var hh := lerpf(46.0, 18.0, a)
				s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [xa, ya - hh, xb, yb - hh * 0.9, xb, yb, xa, ya], _bright(rng), 'opacity="0.9"')
			s += _p("M%.1f %.1f L%.1f %.1f" % [near_x, ny, far_x, fy], "none", 'stroke="%s" stroke-width="%.1f"' % [YELLOW, 5.0])
		s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [near_x, 20, far_x, 170, far_x, 180, near_x, 50], GREEN)
	# The strip lights down the middle.
	for i in 4:
		var t := float(i) / 4.0
		var y := lerpf(18.0, 160.0, t)
		var hw := lerpf(60.0, 14.0, t)
		s += _r(vp.x - hw, y, hw * 2.0, lerpf(8.0, 3.0, t), "#FFFFFF", 'opacity="0.95"')
	return tex(w, h, s)


## What she buys, as a small picture (96 × 96).
static func item(kind: String) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var s := _defs()
	var pr := _product(kind, 30.0, 80.0, rng)
	s += '<g transform="translate(-32 -35) scale(1.6)">' + str(pr[0]) + '</g>'
	return tex(96, 96, s)
