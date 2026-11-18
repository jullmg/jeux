class_name CoutuArt
extends RefCounted
## The Jean Coutu on Rue Masson (2716, between 3e and 4e, south side), drawn as SVG at runtime like DollarArt: a Québec
## drugstore. What its own pages say about the stores: cosmetics are the heart of the store, warm and upscale; the pharmacy's
## laboratory is in plain sight; dermo-cosmetics have their own corner; "Personnelle" is the chain's own brand. The rest is
## how a big Québec drugstore is laid out: checkouts and the photo counter by the door, the cosmetics on warm wood, the
## dermo-cosmetics and perfumes, numbered aisles (hair care, personal care, cold and pain, vitamins, baby, snacks), the
## pharmacy at the back with its two counters, its consultation room and the blood-pressure machine. Navy blue and white
## with a red accent; light from the upper left; every shelf from its own random numbers so it is always the same shelf.

const NAVY := "#1F3E8E"
const NAVY_DARK := "#142B66"
const RED := "#D8202A"
const WOOD := "#C9A27A"
const WOOD_DARK := "#9A764F"
const SHELF := "#F7F7F5"
const METAL_DARK := "#BFC3C8"

## The aisles, in their order from the cosmetics: [id, the sign's words].
const AISLES := [["cheveux", "SOINS CAPILLAIRES"], ["personnels", "SOINS PERSONNELS"], ["rhume", "RHUME, GRIPPE ET DOULEUR"],
	["vitamines", "VITAMINES ET PRODUITS NATURELS"], ["bebe", "BÉBÉ"], ["collations", "COLLATIONS ET BOISSONS"]]

## What each aisle's shelves hold (`_item` kinds).
const STOCK := {
	"cheveux": ["shampoo", "conditioner", "hairdye", "hairbrush", "shampoo", "spray"],
	"personnels": ["toothpaste", "toothbrush", "deodorant", "soap", "mouthwash", "razor"],
	"rhume": ["medbox", "syrup", "lozenges", "tissues", "medbox", "bandages"],
	"vitamines": ["pills", "amber", "gummies", "tub", "pills", "amber"],
	"bebe": ["diapers", "wipes", "babybottle", "babyfood", "diapers", "cream"],
	"collations": ["chips", "choco", "candy", "drink", "chips", "drink"],
}


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return InteriorArt.tex(w, h, body)


static func _r(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _c(x: float, y: float, r: float, fill: String, extra := "") -> String:
	return '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" %s/>' % [x, y, r, fill, extra]


static func _p(d: String, fill: String, extra := "") -> String:
	return '<path d="%s" fill="%s" %s/>' % [d, fill, extra]


static func _pick(rng: RandomNumberGenerator, colors: Array) -> String:
	return str(colors[rng.randi_range(0, colors.size() - 1)])


static func _defs() -> String:
	return ('<defs><linearGradient id="met" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF"/>'
		+ '<stop offset="1" stop-color="#D5D8DC"/></linearGradient>'
		+ '<linearGradient id="deep" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000000" stop-opacity="0.22"/>'
		+ '<stop offset="1" stop-color="#000000" stop-opacity="0"/></linearGradient>'
		+ '<linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/>'
		+ '<stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0.08"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.3"/></linearGradient>'
		+ '<linearGradient id="warm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE9C7" stop-opacity="0.75"/>'
		+ '<stop offset="1" stop-color="#FFE9C7" stop-opacity="0"/></linearGradient>'
		+ '<linearGradient id="cyl" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.45"/>'
		+ '<stop offset="0.35" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.2"/></linearGradient></defs>')


# ── Products ────────────────────────────────────────────────────

const _BRIGHT := ["#E04F5F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#1FB5C4", "#FFD23F", "#F2F0EA", "#2E6FC0"]


## One item standing on a shelf at `base`, its left edge at x: [svg, width].
static func _item(kind: String, x: float, base: float, rng: RandomNumberGenerator) -> Array:
	var c := _pick(rng, _BRIGHT)
	var s := ""
	var w := 24.0
	match kind:
		"shampoo", "conditioner":
			w = 22.0
			var hh := rng.randf_range(44.0, 54.0)
			s += _p("M%.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 2, base - hh + 10, x + 2, base - hh + 4, x + 7, base - hh + 2, x + 15, base - hh + 2, x + 20, base - hh + 4, x + 20, base - hh + 10, x + 20, base], c)
			s += _r(x + 7, base - hh - 6, 8, 8, "#F2F0EA" if kind == "shampoo" else "#2B2B30", 'rx="2"')
			s += _r(x + 4, base - hh * 0.6, 14, hh * 0.3, "#FFFFFF", 'opacity="0.75" rx="2"') + _r(x + 2, base - hh + 4, 18, hh - 4, "url(#cyl)")
		"spray":
			w = 18.0
			s += _r(x + 3, base - 46, 12, 46, c, 'rx="3"') + _r(x + 4, base - 54, 10, 8, "#C9CCD0") + _r(x + 3, base - 46, 12, 46, "url(#cyl)")
		"hairdye":
			w = 28.0
			s += _r(x + 1, base - 40, 26, 40, c, 'stroke="#00000022"') + '<ellipse cx="%.1f" cy="%.1f" rx="8" ry="10" fill="#F2C9A8"/>' % [x + 14, base - 26]
			s += _p("M%.1f %.1f q8 -12 16 0 q0 -14 -8 -14 q-8 0 -8 14 z" % [x + 6, base - 24], _pick(rng, ["#5A3A22", "#C9A060", "#8A3B1E", "#2B2B2B"]))
			s += _r(x + 3, base - 10, 22, 6, "#FFFFFF", 'opacity="0.8"')
		"hairbrush":
			w = 20.0
			s += _r(x + 3, base - 44, 14, 44, "#F2F0EA", 'stroke="#C9C4B8"') + _r(x + 6, base - 40, 8, 18, c, 'rx="4"') + _r(x + 9, base - 22, 2, 18, c)
		"toothpaste":
			w = 34.0
			s += _r(x + 1, base - 14, 32, 14, c, 'rx="2"') + _r(x + 4, base - 11, 18, 8, "#FFFFFF", 'opacity="0.8"') + _r(x + 1, base - 28, 32, 13, _pick(rng, _BRIGHT), 'rx="2"')
		"toothbrush":
			w = 18.0
			s += _r(x + 1, base - 46, 16, 46, "#E8F4FA", 'stroke="#9EC3D0"') + _r(x + 7, base - 42, 4, 36, c, 'rx="2"') + _r(x + 6, base - 42, 6, 8, "#FFFFFF")
		"deodorant":
			w = 18.0
			s += _r(x + 2, base - 36, 14, 36, c, 'rx="4"') + _r(x + 2, base - 40, 14, 6, "#F2F0EA", 'rx="3"') + _r(x + 2, base - 36, 14, 36, "url(#cyl)")
		"soap":
			w = 30.0
			s += _r(x + 1, base - 16, 28, 16, c, 'rx="3"') + _r(x + 6, base - 12, 18, 8, "#FFFFFF", 'opacity="0.7" rx="2"')
		"mouthwash":
			w = 22.0
			s += _r(x + 2, base - 46, 18, 46, _pick(rng, ["#2E9AD6", "#2FBF71", "#E04F9A"]), 'rx="4" opacity="0.9"') + _r(x + 5, base - 54, 12, 8, "#F2F0EA", 'rx="2"') + _r(x + 2, base - 46, 18, 46, "url(#cyl)")
		"razor":
			w = 22.0
			s += _r(x + 1, base - 38, 20, 38, "#E8F4FA", 'stroke="#9EC3D0"') + _r(x + 8, base - 34, 5, 28, c) + _r(x + 5, base - 36, 11, 5, "#5A5A60")
		"medbox":
			w = 30.0
			s += _r(x + 1, base - 30, 28, 30, Color(c).lerp(Color.WHITE, 0.7).to_html(false).insert(0, "#"), 'stroke="#C0C4C8"') + _r(x + 1, base - 30, 28, 9, c) + _r(x + 4, base - 16, 18, 3, "#5A5A5A") + _r(x + 4, base - 11, 12, 3, "#9A9A9A")
		"syrup":
			w = 20.0
			s += _r(x + 3, base - 36, 14, 36, "#9A4E1E", 'rx="3"') + _r(x + 6, base - 42, 8, 6, c) + _r(x + 4, base - 26, 12, 12, "#FFFFFF", 'opacity="0.85"') + _r(x + 3, base - 36, 14, 36, "url(#cyl)")
		"lozenges":
			w = 22.0
			s += _r(x + 1, base - 20, 20, 20, c, 'stroke="#00000022"') + _c(x + 11, base - 10, 5, "#FFFFFF", 'opacity="0.75"')
		"tissues":
			w = 34.0
			s += _r(x + 1, base - 30, 32, 30, _pick(rng, ["#BFE3F7", "#F7C6D9", "#CDEFC4", "#FFF1A8"]), 'stroke="#00000022"') + '<ellipse cx="%.1f" cy="%.1f" rx="9" ry="3" fill="#FFFFFF"/>' % [x + 17, base - 30]
			s += _p("M%.1f %.1f q4 -10 8 0" % [x + 13, base - 30], "#FFFFFF")
		"bandages":
			w = 24.0
			s += _r(x + 1, base - 26, 22, 26, "#F4D6B8", 'stroke="#C9A27A"') + _r(x + 4, base - 18, 16, 8, _pick(rng, ["#7CCB5A", "#FF7BA3", "#4FA3E0"]), 'rx="4"')
		"pills":
			w = 20.0
			s += _r(x + 2, base - 32, 16, 32, "#FFFFFF", 'rx="3" stroke="#D0D0D0"') + _r(x + 2, base - 38, 16, 7, c, 'rx="2"') + _r(x + 3, base - 22, 14, 10, _pick(rng, _BRIGHT), 'opacity="0.85"')
		"amber":
			w = 18.0
			s += _r(x + 2, base - 30, 14, 30, "#B8651E", 'rx="3" opacity="0.92"') + _r(x + 2, base - 35, 14, 6, "#F2F0EA", 'rx="2"') + _r(x + 3, base - 22, 12, 10, "#FFFFFF", 'opacity="0.85"') + _r(x + 2, base - 30, 14, 30, "url(#cyl)")
		"gummies":
			w = 26.0
			s += _r(x + 2, base - 34, 22, 34, "#F2F0EA", 'rx="4"') + _r(x + 2, base - 40, 22, 7, c, 'rx="3"')
			for k in 3:
				s += _c(x + 8 + k * 5, base - 16, 2.6, _pick(rng, ["#E04F5F", "#FF8A3D", "#FFD23F", "#7CCB5A"]))
		"tub":
			w = 34.0
			s += _r(x + 2, base - 40, 30, 40, _pick(rng, ["#2B2B30", "#F2F0EA", "#1F3E8E"]), 'rx="3"') + _r(x + 2, base - 44, 30, 6, c, 'rx="2"') + _r(x + 6, base - 28, 22, 12, "#FFFFFF", 'opacity="0.8"')
		"diapers":
			w = 46.0
			s += _r(x + 1, base - 42, 44, 42, _pick(rng, ["#7FC4F0", "#F7C6D9", "#CDEFC4"]), 'rx="5"') + _c(x + 23, base - 22, 9, "#FFFFFF", 'opacity="0.8"') + _r(x + 4, base - 40, 38, 6, "#FFFFFF", 'opacity="0.4" rx="3"')
		"wipes":
			w = 38.0
			s += _r(x + 1, base - 18, 36, 18, "#EAF6FB", 'rx="6" stroke="#9EC3D0"') + _r(x + 10, base - 18, 18, 6, c, 'rx="2"')
		"babybottle":
			w = 18.0
			s += _r(x + 3, base - 30, 12, 30, "#FFFFFF", 'rx="3" opacity="0.85" stroke="#C9D2D8"') + _r(x + 3, base - 34, 12, 5, c) + _p("M%.1f %.1f q3 -8 6 0 z" % [x + 6, base - 34], "#F2C29A")
		"babyfood":
			w = 18.0
			s += _r(x + 2, base - 18, 14, 18, _pick(rng, ["#F2B35A", "#E8705A", "#9ACB6A"]), 'rx="2"') + _r(x + 1, base - 22, 16, 5, "#C9CCD0", 'rx="1"')
		"cream":
			w = 22.0
			s += _r(x + 4, base - 34, 14, 34, "#FFFFFF", 'rx="5" stroke="#D0D0D0"') + _r(x + 4, base - 12, 14, 8, c) + _r(x + 6, base - 38, 10, 5, c, 'rx="1"')
		"chips":
			w = 30.0
			s += _p("M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f Z" % [x + 2, base, x, base - 20, x + 4, base - 40, x + 26, base - 40, x + 30, base - 20, x + 28, base], c)
			s += _c(x + 15, base - 20, 7, "#FFD23F", 'opacity="0.8"')
		"choco":
			w = 32.0
			for i in 4:
				s += _r(x + 1, base - 7 - i * 7, 30, 6, ["#5E3A22", "#C8202A", "#1D4F91", "#7A3E8E"][i % 4], 'rx="1"')
		"candy":
			w = 26.0
			s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [x + 2, base, x + 4, base - 34, x + 22, base - 34, x + 24, base], c) + _c(x + 13, base - 17, 6, "#FFFFFF", 'opacity="0.7"')
		"drink":
			w = 16.0
			s += _r(x + 3, base - 40, 10, 40, _pick(rng, ["#E04F5F", "#2E9AD6", "#7CCB5A", "#FF8A3D"]), 'rx="3"') + _r(x + 5, base - 46, 6, 6, "#F2F0EA") + _r(x + 3, base - 28, 10, 10, "#FFFFFF", 'opacity="0.7"')
		_:
			s += _r(x + 1, base - 28, w - 2, 28, c, 'stroke="#00000022"')
	return [s, w]


# ── Aisles ──────────────────────────────────────────────────────

const GONDOLA_TOP := 40.0
## The gondola's shelves (y in its picture).
const GONDOLA_SHELVES := [490.0, 410.0, 330.0, 250.0, 170.0]
const PRICES := ["2,49 $", "3,99 $", "4,49 $", "5,99 $", "1,99 $", "6,99 $", "2,99 $", "8,99 $"]


## Where the red price flags stick out of a gondola `w` wide: [x, y of the shelf's lip, price].
static func talkers(w: float) -> Array:
	var out := []
	var k := 0
	var x := 170.0
	while x < w - 140.0:
		out.append([x, float(GONDOLA_SHELVES[[2, 1, 3, 0, 1, 2][k % 6]]), PRICES[(k * 5) % PRICES.size()]])
		x += 280.0 + (k % 3) * 30.0
		k += 1
	return out


## A long drugstore gondola seen face on from inside an aisle (w × 520): the navy header with its white line, white shelves
## lit from above, a pale back in shade under each shelf, the department's things in neat facings, white price strips with
## their little tickets, red price flags (`talkers`, labels in the scene), a navy kick plate.
static func gondola(theme: String, w: float, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var h := 520.0
	var t := GONDOLA_TOP
	var s := _defs() + _r(0, t + 30, w, h - t - 30, "#E3E7EB")
	for y: float in GONDOLA_SHELVES:
		s += _r(0, y - 78.0, w, 34, "url(#deep)")
	var stock: Array = STOCK.get(theme, ["medbox"])
	for i in GONDOLA_SHELVES.size():
		var y: float = GONDOLA_SHELVES[i]
		var x := 8.0
		var k := rng.randi_range(0, stock.size() - 1)
		while x < w - 40.0:
			var kind: String = stock[k % stock.size()]
			for j in rng.randi_range(4, 7):
				var pr := _item(kind, x, y - 2.0, rng)
				s += pr[0]
				x += float(pr[1]) + 1.5
				if x > w - 40.0:
					break
			x += rng.randf_range(6.0, 14.0)
			k += 1
		s += _r(0, y, w, 9, "url(#met)", 'stroke="%s"' % METAL_DARK) + _r(0, y + 9, w, 12, "#FFFFFF", 'stroke="#D8DBDF"')
		s += _r(0, y + 21, w, 3, "#000000", 'opacity="0.15"')
		var tx := 26.0
		while tx < w - 30.0:
			s += _r(tx, y + 11, 26, 8, "#FFFFFF", 'stroke="%s" stroke-width="0.8"' % NAVY) + _r(tx + 3, y + 13, 12, 2, NAVY) + _r(tx + 3, y + 16, 8, 1.5, "#5A5A5A")
			tx += rng.randf_range(55.0, 110.0)
	for tk: Array in talkers(w):
		var fx: float = tk[0]
		var fy: float = tk[1]
		s += _r(fx - 2, fy + 6, 4, 10, "#FFFFFF", 'opacity="0.6"')
		s += _r(fx - 36, fy - 34, 72, 40, RED, 'rx="5" stroke="#9A141A" stroke-width="2"')
		s += _r(fx - 36, fy - 34, 72, 10, "#FFFFFF", 'opacity="0.25" rx="5"')
	var ux := 0.0
	while ux <= w:
		s += _r(ux - 4, t + 40, 8, h - t - 40, "url(#met)", 'stroke="%s"' % METAL_DARK)
		ux += 250.0
	s += _r(0, t, w, 34, NAVY) + _r(0, t + 4, w, 3, "#FFFFFF", 'opacity="0.55"') + _r(0, t + 30, w, 4, NAVY_DARK)
	s += _r(0, h - 20, w, 20, NAVY) + _r(0, h - 20, w, 3, "#FFFFFF", 'opacity="0.3"')
	return tex(w, h, s)


## The end of an aisle seen from the front of the store (260 × 470): a navy header with a red "aubaine" card on top (its price
## a label), the shelves stocked full in facings of two things, a dump bin at its foot.
static func endcap(theme: String, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 260.0
	var h := 470.0
	var s := _defs() + _r(0, 30, w, h - 30, SHELF, 'stroke="%s"' % METAL_DARK)
	var stock: Array = STOCK.get(theme, ["medbox"])
	for y: float in [360.0, 280.0, 200.0, 120.0]:
		s += _r(0, y - 76.0, w, 30, "url(#deep)")
		var x := 6.0
		var kinds := [stock[rng.randi_range(0, stock.size() - 1)], stock[rng.randi_range(0, stock.size() - 1)]]
		var n := 0
		while x < w - 30.0:
			var pr := _item(kinds[(n / 3) % 2], x, y - 2.0, rng)
			s += pr[0]
			x += float(pr[1]) + 1.0
			n += 1
		s += _r(0, y, w, 9, "url(#met)") + _r(0, y + 9, w, 10, "#FFFFFF", 'stroke="#D8DBDF"')
	# The dump bin: a wire basket of the department's small things.
	s += _r(20, 384, 220, 70, "#E8EAEC", 'stroke="#9AA0A6" stroke-width="2"')
	for k in 9:
		s += _r(26 + k * 24, 384, 2, 70, "#9AA0A6")
	var bx := 28.0
	while bx < 220.0:
		var pr := _item(stock[rng.randi_range(0, stock.size() - 1)], bx, 400.0, rng)
		s += pr[0]
		bx += float(pr[1]) * 0.9
	s += _r(0, 30, w, 50, NAVY) + _r(0, 34, w, 3, "#FFFFFF", 'opacity="0.5"') + _r(70, 0, 120, 40, RED, 'rx="6" stroke="#9A141A" stroke-width="3"')
	s += _r(0, h - 16, w, 16, NAVY) + _r(0, 30, 8, h - 30, "#FFFFFF", 'opacity="0.4"') + _r(w - 12, 30, 12, h - 30, "#000000", 'opacity="0.12"')
	return tex(w, h, s)


# ── Cosmetics ───────────────────────────────────────────────────

## A wall bay of cosmetics on warm wood (560 × 470): a lit header (the brand is a label), a mirror strip, tiers of testers in
## their trays — lipsticks, nail polish, eye-shadow palettes, foundations in a row of shades, mascaras — a deep drawer base,
## the warm light washing down from the header.
static func beauty_wall(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 560.0
	var h := 470.0
	var s := _defs() + _r(0, 0, w, h, WOOD) + _r(14, 60, w - 28, 330, "#FBF7F2")
	for gx in range(0, int(w), 14):
		s += _r(gx, 0, 1, 60, WOOD_DARK, 'opacity="0.25"')
	s += _r(14, 60, w - 28, 120, "url(#warm)")
	s += _r(0, 0, w, 52, "#FFFFFF") + _r(0, 48, w, 4, "#E9DCCB") + _r(0, 52, w, 6, WOOD_DARK)
	# A strip of mirror across the top tier, catching the light.
	s += _r(30, 70, w - 60, 34, "#D9E6EE") + _r(30, 70, w - 60, 34, "url(#glass)")
	var tiers := [[150.0, "lipstick"], [205.0, "polish"], [265.0, "palette"], [325.0, "foundation"], [380.0, "mascara"]]
	for tier: Array in tiers:
		var y: float = tier[0]
		s += _r(20, y, w - 40, 6, "#FFFFFF", 'stroke="#E2D8CC"') + _r(20, y + 6, w - 40, 3, "#000000", 'opacity="0.1"')
		var x := 28.0
		match String(tier[1]):
			"lipstick":
				while x < w - 40.0:
					var lc := _pick(rng, ["#C2185B", "#E04F5F", "#B5303A", "#F48FB1", "#8E2A37", "#E57373", "#AD1457"])
					s += _r(x, y - 22, 8, 14, "#2B2B30", 'rx="1"') + _p("M%.1f %.1f l8 0 l0 -6 l-3 -4 l-5 3 z" % [x, y - 22], lc) + _r(x, y - 8, 8, 8, "#C9A23A")
					x += 12.0
			"polish":
				while x < w - 40.0:
					var pc := _pick(rng, ["#E04F5F", "#F48FB1", "#C084FC", "#4FA3E0", "#FFD23F", "#7CCB5A", "#F2F0EA", "#8E2A37"])
					s += _r(x + 2, y - 26, 4, 8, "#2B2B30") + _r(x, y - 18, 8, 18, pc, 'rx="2"') + _r(x + 1, y - 17, 2, 14, "#FFFFFF", 'opacity="0.5"')
					x += 11.0
			"palette":
				while x < w - 70.0:
					s += _r(x, y - 30, 52, 30, "#1E1E22", 'rx="3"')
					for k in 6:
						s += _r(x + 4 + (k % 3) * 16, y - 26 + (k / 3) * 13, 13, 10, _pick(rng, ["#C8A27A", "#E8C8B0", "#9A6A50", "#F4D6C8", "#B98AA8", "#7A5A44", "#D9B07A"]), 'rx="2"')
					x += 58.0
			"foundation":
				var tones := ["#F7E2D0", "#F2D2B8", "#E8C3A0", "#D9AE88", "#C8966E", "#A87452", "#8A5A3C", "#6A4230"]
				var k2 := 0
				while x < w - 40.0:
					s += _r(x, y - 32, 14, 32, tones[k2 % tones.size()], 'rx="3"') + _r(x + 3, y - 38, 8, 7, "#2B2B30", 'rx="1"') + _r(x, y - 32, 14, 32, "url(#cyl)")
					x += 18.0
					k2 += 1
			_:
				while x < w - 40.0:
					s += _r(x + 1, y - 30, 7, 30, _pick(rng, ["#1E1E22", "#E04F9A", "#2E6FC0"]), 'rx="3"') + _r(x + 2, y - 30, 2, 26, "#FFFFFF", 'opacity="0.35"')
					x += 11.0
	# The drawer base, its handles, the wood's grain and the shade at its foot.
	s += _r(0, 392, w, h - 392, WOOD)
	for dx in [0.0, w / 2.0]:
		s += _r(dx + 10, 404, w / 2.0 - 20, 54, WOOD, 'stroke="%s" stroke-width="2"' % WOOD_DARK) + _r(dx + w / 4.0 - 24, 428, 48, 5, "#E9DCCB", 'rx="2"')
	s += _r(0, 0, 10, h, "#FFFFFF", 'opacity="0.18"') + _r(w - 14, 0, 14, h, "#000000", 'opacity="0.1"') + _r(0, h - 8, w, 8, "#000000", 'opacity="0.18"')
	return tex(w, h, s)


## The beauty island in front of the cosmetics (420 × 250): a low wooden counter, a round mirror ringed with bulbs, trays of
## testers, a stool beside it.
static func beauty_island() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2716
	var s := _defs()
	# The stool.
	s += _r(352, 180, 54, 12, "#F2F0EA", 'rx="6"') + _r(376, 192, 6, 50, "#B9BCC0") + _r(360, 238, 38, 6, "#B9BCC0", 'rx="3"')
	# The mirror on its stand, its ring of bulbs.
	s += _r(196, 70, 8, 70, "#C9A23A") + _c(200, 60, 52, "#F2F0EA") + _c(200, 60, 44, "#D9E6EE") + _c(200, 60, 44, "url(#glass)")
	for k in 12:
		var a := TAU * k / 12.0
		s += _c(200 + cos(a) * 48.0, 60 + sin(a) * 48.0, 5, "#FFF6D8", 'stroke="#E9D8A8"')
	# The counter: white top, warm wood front, a brass kick.
	s += _r(10, 140, 340, 14, "#FFFFFF", 'stroke="#E2D8CC"') + _r(16, 154, 328, 86, WOOD)
	for k in 4:
		s += _r(22 + k * 82, 160, 72, 72, WOOD, 'stroke="%s" stroke-width="2"' % WOOD_DARK)
	s += _r(16, 236, 328, 10, "#C9A23A")
	# Testers on the top: lipsticks in a tray, a palette open, little bottles.
	s += _r(30, 128, 120, 12, "#1E1E22", 'rx="2"')
	for k in 10:
		s += _r(34 + k * 11, 116, 7, 12, _pick(rng, ["#C2185B", "#E04F5F", "#F48FB1", "#8E2A37"]), 'rx="1"')
	s += _r(250, 122, 70, 18, "#1E1E22", 'rx="3"')
	for k in 5:
		s += _r(254 + k * 13, 125, 11, 12, _pick(rng, ["#C8A27A", "#E8C8B0", "#9A6A50", "#B98AA8"]), 'rx="2"')
	s += _r(0, 236, 360, 14, "#000000", 'opacity="0.1"')
	return tex(420, 250, s)


## The dermo-cosmetics wall (560 × 470): bright white, glossy shelves lit from inside, rows of skincare boxes, tubes and jars
## in the clean colours of pharmacy skin care, a header for its name (a label).
static func dermo_wall(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 560.0
	var h := 470.0
	var s := _defs() + _r(0, 0, w, h, "#FFFFFF", 'stroke="#DADDE0"') + _r(0, 0, w, 52, "#EEF4F8") + _r(0, 48, w, 4, "#9EC3D0")
	var lines := [["#1C8C5E", "#E8F4EE"], ["#2E6FC0", "#EAF1FA"], ["#4A5A6A", "#F4F4F4"], ["#E06A8A", "#FBEFF3"], ["#E07A2A", "#FDF1E6"]]
	for y: float in [150.0, 230.0, 310.0, 390.0]:
		s += _r(10, y - 80, w - 20, 80, "#F4F8FB") + _r(10, y - 80, w - 20, 26, "url(#deep)")
		var x := 18.0
		var line: Array = lines[rng.randi_range(0, lines.size() - 1)]
		while x < w - 40.0:
			var ink := str(line[0])
			var body := Color(ink).lerp(Color.WHITE, 0.62).to_html(false)
			match rng.randi_range(0, 3):
				0:
					# A box: the brand's colour on its top and a band, a white label.
					s += _r(x, y - 42, 24, 42, "#" + body, 'stroke="%s" stroke-width="1.2"' % ink) + _r(x, y - 42, 24, 11, ink) + _r(x + 3, y - 26, 18, 9, "#FFFFFF", 'opacity="0.85"')
					x += 26.0
				1:
					# A tube standing on its cap.
					s += _p("M%.1f %.1f l12 0 l-2 -40 l-8 0 z" % [x + 2, y - 6], "#" + body, 'stroke="%s" stroke-width="1.2"' % ink) + _r(x + 3, y - 6, 10, 6, ink, 'rx="1"') + _r(x + 4, y - 40, 8, 4, ink)
					x += 17.0
				2:
					# A pump bottle.
					s += _r(x + 2, y - 44, 16, 44, "#" + body, 'rx="5" stroke="%s" stroke-width="1.2"' % ink) + _r(x + 7, y - 52, 6, 8, ink) + _r(x + 7, y - 54, 12, 3, ink) + _r(x + 4, y - 30, 12, 12, "#FFFFFF", 'opacity="0.8"')
					x += 21.0
				_:
					# A jar.
					s += _r(x, y - 20, 26, 20, "#" + body, 'rx="4" stroke="%s" stroke-width="1.2"' % ink) + _r(x - 1, y - 27, 28, 8, ink, 'rx="3"')
					x += 30.0
		s += _r(10, y, w - 20, 7, "#FFFFFF", 'stroke="#C9D3DA"') + _r(10, y + 7, w - 20, 2, "#9EC3D0", 'opacity="0.7"')
	s += _r(0, h - 50, w, 50, "#EEF4F8", 'stroke="#DADDE0"') + _r(0, 0, 8, h, "#FFFFFF") + _r(w - 12, 0, 12, h, "#000000", 'opacity="0.08"')
	return tex(w, h, s)


## The perfumes, in a lit glass case (300 × 470): glass shelves, bottles of every shape catching the light, a mirrored back.
static func perfume_case() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2732
	var w := 300.0
	var h := 470.0
	var s := _defs() + _r(0, 0, w, h, "#2B2B30") + _r(10, 20, w - 20, 360, "#5A4E5C") + _r(10, 20, w - 20, 360, "#2B2B30", 'opacity="0.25"')
	# A mirrored back: the store's light in soft streaks.
	for k in 3:
		s += _p("M%.1f 20 l40 0 l-90 360 l-40 0 z" % (40.0 + k * 110.0), "#FFFFFF", 'opacity="0.07"')
	s += _r(10, 20, w - 20, 50, "url(#warm)")
	for y: float in [120.0, 210.0, 300.0, 375.0]:
		var x := 22.0
		while x < w - 50.0:
			var bc := _pick(rng, ["#F2C9D8", "#E8D9A8", "#BFE3F7", "#D8C8F0", "#F4B8A0", "#FFFFFF"])
			match rng.randi_range(0, 2):
				0:
					s += _r(x, y - 40, 26, 40, bc, 'rx="4" opacity="0.85"') + _r(x + 9, y - 50, 8, 10, "#C9A23A")
				1:
					s += _c(x + 14, y - 18, 16, bc, 'opacity="0.85"') + _r(x + 10, y - 40, 8, 8, "#2B2B30")
				_:
					s += _p("M%.1f %.1f l26 0 l-4 -36 l-18 0 z" % [x, y], bc, 'opacity="0.85"') + _r(x + 8, y - 46, 10, 10, "#C9A23A")
			s += _r(x + 3, y - 36, 3, 30, "#FFFFFF", 'opacity="0.6"')
			x += 38.0
		s += _r(10, y, w - 20, 4, "#FFFFFF", 'opacity="0.7"')
	s += _r(10, 20, w - 20, 360, "url(#glass)", 'opacity="0.35"') + _r(0, 380, w, h - 380, "#2B2B30") + _r(20, 400, w - 40, 50, "#3A3A40", 'stroke="#C9A23A" stroke-width="1.5"')
	return tex(w, h, s)


# ── The pharmacy ────────────────────────────────────────────────

## The laboratory behind the counter (1200 × 470): white wall of drawers and shelves of medicine boxes in neat rows, a glass
## partition along the top of the counter showing it all, the navy band where "PHARMACIE" goes (a label).
static func lab_wall(w: float) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var h := 470.0
	var s := _defs() + _r(0, 0, w, h, "#F4F6F8") + _r(0, 0, w, 70, NAVY) + _r(0, 64, w, 6, RED)
	var x := 20.0
	while x < w - 20.0:
		var bw := 180.0
		s += _r(x, 100, bw, 300, "#E2E8EE", 'stroke="#C3CBD3"')
		for y: float in [150.0, 200.0, 250.0, 300.0, 350.0, 395.0]:
			var px := x + 6.0
			while px < x + bw - 22.0:
				var bh := rng.randf_range(16.0, 30.0)
				var mc := _pick(rng, ["#E04F5F", "#2E6FC0", "#1C8C5E", "#FF8A3D", "#7A3E8E", "#E0B020"])
				if rng.randf() < 0.25:
					# An amber vial of pills.
					s += _r(px + 3, y - bh, 10, bh, "#B8651E", 'rx="2"') + _r(px + 3, y - bh - 4, 10, 5, "#F2F0EA", 'rx="1"')
				else:
					s += _r(px, y - bh, 16, bh, Color(mc).lerp(Color.WHITE, 0.72).to_html(false).insert(0, "#"), 'stroke="%s" stroke-width="0.8"' % mc) + _r(px, y - bh, 16, 6, mc) + _r(px + 3, y - bh + 10, 10, 2, "#5A5A5A")
				px += 18.0
			s += _r(x, y, bw, 4, "#D0D4D8")
		x += bw + 14.0
	# Drawers along the bottom, a computer, the pharmacist's scale.
	var dx := 20.0
	while dx < w - 60.0:
		s += _r(dx, 405, 60, 30, "#FFFFFF", 'stroke="#C9CDD2"') + _r(dx + 22, 418, 16, 4, "#9AA0A6", 'rx="2"')
		dx += 64.0
	s += _r(0, h - 20, w, 20, "#D0D4D8")
	return tex(w, h, s)


## The pharmacy's counter (1200 × 230): two stations under their hanging signs (labels in the scene), white tops, navy front,
## a screen and a card terminal at each, bags of prescriptions waiting in their bins between them, the glass partition above.
static func pharmacy_counter(w: float) -> ImageTexture:
	var h := 230.0
	var s := _defs()
	s += _r(0, 0, w, 90, "#E8F0F4", 'opacity="0.35"') + _r(0, 0, w, 90, "url(#glass)") + _r(0, 0, w, 3, "#B9C3CA")
	s += _r(0, 90, w, 16, "#FFFFFF", 'stroke="#D0D4D8"') + _r(6, 106, w - 12, 110, NAVY) + _r(6, 106, w - 12, 6, "#FFFFFF", 'opacity="0.25"')
	var px := 14.0
	while px < w - 60.0:
		s += _r(px, 160, 110, 52, NAVY, 'stroke="#2E52A8" stroke-width="2"')
		px += 120.0
	s += _r(6, 150, w - 12, 4, RED) + _r(0, h - 14, w, 14, NAVY_DARK)
	for st: float in [w * 0.22, w * 0.72]:
		s += _r(st - 4, 50, 8, 40, "#3A3B3F") + _r(st - 34, 30, 68, 40, "#202124", 'rx="4"') + _r(st - 30, 34, 60, 32, "#E8F0FA")
		s += _r(st - 30, 34, 60, 8, NAVY) + _r(st + 40, 62, 26, 28, "#2B2C30", 'rx="4"') + _r(st + 44, 66, 18, 10, "#7FD3C8")
	# The bins of filled prescriptions: white paper bags stapled shut.
	for k in 7:
		var bx := w * 0.38 + k * 26.0
		s += _r(bx, 56, 22, 34, "#FFFFFF", 'stroke="#C9CDD2"') + _r(bx + 2, 60, 18, 4, NAVY, 'opacity="0.6"')
	return tex(w, h, s)


## The blood-pressure machine with its seat (220 × 300): a white and navy kiosk, the cuff opening, a screen, the seat.
static func bp_machine() -> ImageTexture:
	var s := _defs()
	s += _r(20, 20, 120, 270, "#FFFFFF", 'rx="10" stroke="#C9CDD2" stroke-width="2"') + _r(20, 20, 120, 40, NAVY, 'rx="10"')
	s += _r(36, 80, 88, 56, "#202124", 'rx="4"') + _r(40, 84, 80, 48, "#DDF2E6") + _r(46, 92, 40, 12, "#1C8C5E") + _r(46, 110, 60, 6, "#5A5A5A")
	s += '<ellipse cx="80" cy="190" rx="36" ry="26" fill="#2B2C30"/><ellipse cx="80" cy="190" rx="28" ry="18" fill="#3E4046"/>'
	s += _r(20, 250, 120, 40, NAVY_DARK, 'rx="6"')
	# The seat beside it.
	s += _r(140, 180, 70, 16, NAVY, 'rx="6"') + _r(140, 120, 14, 70, NAVY, 'rx="5"') + _r(168, 196, 8, 90, "#B9BCC0") + _r(150, 284, 52, 6, "#B9BCC0", 'rx="3"')
	s += _r(20, 20, 10, 270, "#FFFFFF", 'opacity="0.5"')
	return tex(220, 300, s)


## A door to the consultation room (180 × 430): white, a little window, its sign plate (a label).
static func consult_door() -> ImageTexture:
	var s := _defs()
	s += _r(0, 0, 180, 430, "#DADDE0") + _r(14, 14, 152, 416, "#FFFFFF", 'stroke="#C9CDD2" stroke-width="2"')
	s += _r(60, 60, 60, 80, "#D9E6EE") + _r(60, 60, 60, 80, "url(#glass)") + _r(130, 230, 22, 8, "#9AA0A6", 'rx="3"')
	s += _r(40, 170, 100, 26, NAVY, 'rx="4"')
	return tex(180, 430, s)


## The photo counter by the checkouts (260 × 320): two touch-screen kiosks on a white and navy stand, the printer, sample
## prints pinned above.
static func photo_kiosk() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3030
	var s := _defs()
	for k in 5:
		var px := 14.0 + k * 48.0
		s += _r(px, 10 + (k % 2) * 6, 40, 30, "#FFFFFF", 'stroke="#C9CDD2"') + _r(px + 3, 13 + (k % 2) * 6, 34, 20, _pick(rng, ["#7FC4F0", "#F2B35A", "#9ACB6A", "#E8705A", "#C084FC"]))
	s += _r(10, 70, 240, 40, NAVY, 'rx="6"')
	for kx: float in [30.0, 140.0]:
		s += _r(kx, 120, 90, 70, "#202124", 'rx="5"') + _r(kx + 5, 125, 80, 60, "#E8F0FA") + _r(kx + 10, 132, 30, 22, "#7FC4F0") + _r(kx + 45, 132, 30, 22, "#F2B35A")
		s += _r(kx + 10, 162, 65, 16, NAVY, 'rx="3"')
	s += _r(10, 190, 240, 14, "#FFFFFF", 'stroke="#D0D4D8"') + _r(16, 204, 228, 106, "#FFFFFF", 'stroke="#D0D4D8"')
	s += _r(90, 220, 80, 30, "#E9EAEC", 'stroke="#9AA0A6"') + _r(100, 244, 60, 4, "#2B2B30") + _r(16, 290, 228, 20, NAVY)
	return tex(260, 320, s)


## A warm wooden floor laid under the cosmetics (w × 120): long boards, their joints, the light along them.
static func wood_floor(w: float) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var h := 120.0
	var s := _r(0, 0, w, h, "#C89A6A")
	var y := 0.0
	var row := 0
	while y < h:
		var bh := 8.0 + y * 0.12
		var x := -rng.randf_range(0.0, 200.0)
		while x < w:
			var bw := rng.randf_range(160.0, 320.0)
			s += _r(x, y, bw - 2, bh - 1, _pick(rng, ["#C89A6A", "#BE8F5E", "#D2A676", "#C4955F"]))
			x += bw
		s += _r(0, y + bh - 1, w, 1, "#8A6440", 'opacity="0.5"')
		y += bh
		row += 1
	s += _r(0, 0, w, 12, "#000000", 'opacity="0.12"')
	return tex(w, h, s)


## What she buys, as a small picture (96 × 96).
static func item(kind: String) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var s := _defs()
	match kind:
		"gloss":
			s += _r(40, 20, 16, 56, "#F48FB1", 'rx="5"') + _r(40, 10, 16, 14, "#2B2B30", 'rx="3"') + _r(43, 26, 4, 44, "#FFFFFF", 'opacity="0.5"')
		"polish":
			s += _r(42, 20, 12, 18, "#2B2B30") + _r(32, 36, 32, 40, "#F48FB1", 'rx="6"') + _r(36, 40, 6, 30, "#FFFFFF", 'opacity="0.45"')
		_:
			var pr := _item(kind, 30.0, 80.0, rng)
			s += '<g transform="translate(-32 -35) scale(1.6)">' + str(pr[0]) + '</g>'
	return tex(96, 96, s)
