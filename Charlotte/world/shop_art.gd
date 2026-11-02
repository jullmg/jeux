class_name ShopArt
extends RefCounted
## Shop furniture drawn as SVG at runtime, for interiors like dépanneur Xin-Xin (the same idea as InteriorArt,
## one function per piece, canvas size noted). Everything generic: no brands or logos. Light comes from the upper
## left: highlights on the left, shade on the right. Every piece starts with `_defs()` (shared gradients) and is built
## from a few product helpers (`_can`, `_bottle`, `_bag`, `_box`, `_jar`, `_tag`, `_lip`) so shelves read as shelves.

const TOP_LIGHT := "#FFFFFF"


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return InteriorArt.tex(w, h, body)


static func _bright(rng: RandomNumberGenerator) -> String:
	return ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#FF7BA3", "#1FB5C4"][rng.randi_range(0, 7)]


static func _grad(id: String, x2: int, y2: int, stops: Array) -> String:
	var s := '<linearGradient id="%s" x1="0" y1="0" x2="%d" y2="%d">' % [id, x2, y2]
	for st in stops:
		s += '<stop offset="%s" stop-color="%s" stop-opacity="%s"/>' % [st[0], st[1], st[2] if st.size() > 2 else 1]
	return s + '</linearGradient>'


## Gradients shared by the shop's pieces: cylinders (cans, bottles), brushed metal, glass, laminate, shelf lips, shadows.
static func _defs() -> String:
	return ('<defs>'
		+ _grad("cyl", 1, 0, [[0, "#FFFFFF", 0.5], [0.2, "#FFFFFF", 0.16], [0.6, "#000000", 0], [1, "#000000", 0.34]])
		+ _grad("metal", 1, 0, [[0, "#F4F6F8"], [0.35, "#C9CFD6"], [0.55, "#E9ECEF"], [1, "#98A0A9"]])
		+ _grad("steel", 0, 1, [[0, "#EEF1F4"], [0.5, "#C3CAD1"], [1, "#9AA3AC"]])
		+ _grad("glass", 0, 1, [[0, "#F4FBFF", 0.9], [1, "#D5E9F4", 0.9]])
		+ _grad("glare", 1, 1, [[0, "#FFFFFF", 0.55], [0.5, "#FFFFFF", 0.12], [1, "#FFFFFF", 0]])
		+ _grad("laminate", 0, 1, [[0, "#D8B27C"], [0.5, "#C9A26E"], [1, "#B88C57"]])
		+ _grad("countertop", 0, 1, [[0, "#F2EBDD"], [0.55, "#DDD3C0"], [1, "#BFB39B"]])
		+ _grad("lip", 0, 1, [[0, "#F0EDE6"], [1, "#B5B0A4"]])
		+ _grad("shade", 0, 1, [[0, "#000000", 0.3], [1, "#000000", 0]])
		+ _grad("backlit", 0, 1, [[0, "#F2F9FC"], [1, "#CFE5F1"]])
		+ _grad("wood", 0, 1, [[0, "#B98A52"], [0.5, "#A67A45"], [1, "#8A6238"]])
		+ _grad("cool", 0, 1, [[0, "#EEF8FD"], [1, "#C9E2F0"]])
		+ '<radialGradient id="dome" cx="0.35" cy="0.3"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.8"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>'
		+ '</defs>')


# ── Products ────────────────────────────────────────────────

## A can: body, a pale label band, shading round it, a rim.
static func _can(x: float, y: float, w: float, h: float, c: String) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="%s"/>' % [x, y, w, h, w * 0.16, c]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFFFFF" opacity="0.5"/>' % [x, y + h * 0.32, w, h * 0.26]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="url(#cyl)"/>' % [x, y, w, h, w * 0.16]
	s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="1.8" fill="#E4E8EC" stroke="#9AA0A6" stroke-width="0.6"/>' % [x + w / 2, y + 1.2, w / 2 - 0.6]
	return s


## A bottle with a cap, a label and a glint.
static func _bottle(x: float, y: float, w: float, h: float, c: String, cap := "#FFFFFF") -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="%s" stroke="#00000033" stroke-width="0.8"/>' % [x + w * 0.3, y + h * 0.04, w * 0.4, h * 0.26, w * 0.1, c]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="%s" stroke="#00000033" stroke-width="0.8"/>' % [x, y + h * 0.22, w, h * 0.78, w * 0.3, c]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFFFFF" opacity="0.88"/>' % [x, y + h * 0.5, w, h * 0.26]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" opacity="0.85"/>' % [x, y + h * 0.58, w, h * 0.07, c]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="url(#cyl)"/>' % [x, y + h * 0.22, w, h * 0.78, w * 0.3]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="1" fill="%s" stroke="#00000044" stroke-width="0.6"/>' % [x + w * 0.27, y, w * 0.46, h * 0.07, cap]
	return s


## A bag of chips or candy: crimped top and bottom, a window, a swoosh, a gloss.
static func _bag(x: float, y: float, w: float, h: float, c: String, rng: RandomNumberGenerator) -> String:
	var s := '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f Z" fill="%s" stroke="#00000033" stroke-width="0.8"/>' % [
		x, y + 4, x + w / 6, y, x + w / 3, y + 4, x + w / 2, y, x + 2 * w / 3, y + 4, x + 5 * w / 6, y, x + w, y + 4, x + w - 1, y + h, x + w / 2, y + h + 3, x + 1, y + h, c]
	s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f Z" fill="#FFFFFF" opacity="0.55"/>' % [x, y + h * 0.44, x + w * 0.5, y + h * 0.32, x + w, y + h * 0.5, x + w, y + h * 0.7]
	s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" opacity="0.9"/>' % [x + w * 0.5, y + h * 0.5, w * 0.2, ["#FFF3B0", "#FFE0B5", "#FFD0D8"][rng.randi_range(0, 2)]]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="url(#cyl)"/>' % [x, y + 4, w, h - 4]
	return s


## A box of crackers or cereal: a front, a shaded side, a stripe and a picture circle.
static func _box(x: float, y: float, w: float, h: float, c: String) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#00000033" stroke-width="0.8"/>' % [x, y, w, h, c]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFFFFF" opacity="0.8"/>' % [x, y + h * 0.58, w, h * 0.2]
	s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFFFFF" opacity="0.6"/>' % [x + w * 0.5, y + h * 0.3, w * 0.2]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#000000" opacity="0.16"/>' % [x + w * 0.82, y, w * 0.18, h]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="2" fill="#FFFFFF" opacity="0.55"/>' % [x, y, w]
	return s


## A glass jar with a coloured lid, full of sweets.
static func _jar(x: float, y: float, w: float, h: float, lid: String, rng: RandomNumberGenerator) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="#F2FAFD" fill-opacity="0.7" stroke="#8FB0C0" stroke-width="1.6"/>' % [x, y + 6, w, h - 6, w * 0.22]
	for k in int(w * h / 70.0):
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [x + 5 + rng.randf() * (w - 10), y + 12 + rng.randf() * (h - 20), 3.0 + rng.randf() * 1.8, _bright(rng)]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="7" rx="2.5" fill="%s" stroke="#00000044" stroke-width="0.8"/>' % [x + w * 0.1, y, w * 0.8, lid]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="url(#cyl)" opacity="0.7"/>' % [x, y + 6, w, h - 6, w * 0.22]
	s += '<path d="M%.1f %.1f q1 %.1f 4 %.1f" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.8"/>' % [x + 4, y + 14, h * 0.3, h * 0.45]
	return s


## A shelf's front lip with a price rail, and its shadow on what is below.
static func _lip(x: float, y: float, w: float) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="7" fill="url(#lip)" stroke="#9A968E" stroke-width="0.8"/>' % [x, y, w]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="9" fill="url(#shade)" opacity="0.5"/>' % [x, y + 7, w]
	return s


## A little yellow price tag.
static func _tag(x: float, y: float, hot := false) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="16" height="9" fill="%s" stroke="%s" stroke-width="0.8"/>' % [x, y, "#E0303A" if hot else "#FFE066", "#8E1A20" if hot else "#C99410"]
	s += '<rect x="%.1f" y="%.1f" width="9" height="2" fill="%s"/><rect x="%.1f" y="%.1f" width="6" height="1.6" fill="%s" opacity="0.7"/>' % [x + 3, y + 2, "#FFFFFF" if hot else "#7A5A10", x + 3, y + 5.2, "#FFFFFF" if hot else "#7A5A10"]
	return s


# ── Walls, doors and fixtures ───────────────────────────────

## Canvas 210x440: the shop door seen from inside: aluminium frame, glass with the street beyond (this season's
## tree and a brick building), a push bar, stickers, the bell on its spring and a door closer.
static func door() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="10" width="210" height="430" fill="url(#metal)" stroke="#7E858D" stroke-width="3"/>'
	s += '<rect x="14" y="24" width="182" height="416" fill="#F2F4F6" stroke="#8E959C" stroke-width="2"/>'
	# What is outside: sky, a building across the street, a tree, the sidewalk.
	s += '<rect x="28" y="38" width="154" height="316" fill="#CFE2EE"/>'
	s += '<rect x="28" y="170" width="154" height="130" fill="#A3705A" opacity="0.7"/>'
	for wx in [40, 92, 144]:
		s += '<rect x="%d" y="188" width="26" height="36" fill="#E8F0F4" opacity="0.7"/><rect x="%d" y="246" width="26" height="36" fill="#E8F0F4" opacity="0.7"/>' % [wx, wx]
	var leaf: String = {"autumn": "#E08A2E", "spring": "#9CCB6A", "summer": "#4E9A44", "winter": "#DDE5EB"}[Season.current]
	s += '<rect x="64" y="150" width="9" height="170" fill="#5E4636" opacity="0.8"/>'
	for c in [[68, 120, 34], [48, 142, 26], [90, 140, 28], [66, 96, 26]]:
		s += '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="0.9"/>' % [c[0], c[1], c[2], leaf]
	s += '<rect x="28" y="300" width="154" height="54" fill="%s"/>' % ("#EEF2F4" if Season.current == "winter" else "#BDB6A8")
	s += '<rect x="28" y="38" width="154" height="316" fill="#FFFFFF" opacity="0.22"/>'
	s += '<path d="M34 44 L92 44 L34 210 Z" fill="#FFFFFF" opacity="0.34"/><path d="M104 44 L128 44 L52 354 L34 354 Z" fill="#FFFFFF" opacity="0.1"/>'
	s += '<rect x="28" y="38" width="154" height="316" fill="none" stroke="#7E858D" stroke-width="3"/>'
	# Push bar, door closer, kick plate.
	s += '<rect x="34" y="250" width="142" height="11" rx="5" fill="url(#steel)" stroke="#6E757D" stroke-width="1.2"/>'
	s += '<rect x="34" y="244" width="8" height="23" rx="2" fill="url(#metal)"/><rect x="168" y="244" width="8" height="23" rx="2" fill="url(#metal)"/>'
	s += '<rect x="132" y="26" width="52" height="11" rx="3" fill="#6E757D"/><path d="M142 37 L100 56" stroke="#6E757D" stroke-width="4" stroke-linecap="round"/>'
	s += '<rect x="28" y="362" width="154" height="68" fill="url(#steel)" stroke="#7E858D" stroke-width="2"/>'
	s += '<path d="M40 372 L80 420 M60 372 L96 414 M140 380 L164 418" stroke="#FFFFFF" stroke-width="1.5" opacity="0.5"/><path d="M110 395 q20 6 40 -2" stroke="#7E858D" stroke-width="1.4" fill="none" opacity="0.6"/>'
	# Stickers: a round lottery one, a card one, a hanging sign.
	s += '<circle cx="48" cy="326" r="13" fill="#1D4F91" stroke="#FFFFFF" stroke-width="2"/><circle cx="48" cy="326" r="6" fill="#FFD23F"/>'
	s += '<rect x="68" y="316" width="30" height="20" rx="3" fill="#FFFFFF" stroke="#1D4F91" stroke-width="2"/><rect x="68" y="321" width="30" height="5" fill="#1D4F91"/>'
	s += '<path d="M72 96 V84 M138 96 V84" stroke="#9AA0A6" stroke-width="2"/>'
	s += '<rect x="64" y="96" width="82" height="42" rx="4" fill="#C8202A" stroke="#7A1018" stroke-width="2"/><rect x="70" y="102" width="70" height="30" rx="3" fill="none" stroke="#FFFFFF" stroke-width="2"/>'
	s += '<path d="M64 96 H146 V108 H64 Z" fill="#FFFFFF" opacity="0.18"/>'
	# The bell on its curled spring.
	s += '<path d="M168 44 q-10 4 0 8 q10 4 0 8 q-10 4 0 8" stroke="#7E858D" stroke-width="2" fill="none"/>'
	s += '<path d="M156 78 q12 -22 24 0 z" fill="#E3C26A" stroke="#A88A2E" stroke-width="2"/><circle cx="168" cy="82" r="3" fill="#A88A2E"/>'
	return tex(210, 440, s)


## Canvas 560x240: the counter: a wooden front with a red stripe, a thick top, the till and its display, the scratch
## ticket stand, a gum rack, a coin jar and paper bags (the lucky cat is a node of its own).
static func counter() -> ImageTexture:
	var s := _defs()
	# Front: toe-kick, laminate panels, a red band, a thick top with its edge and shadow.
	s += '<rect x="10" y="222" width="540" height="18" fill="#3A332C"/><rect x="10" y="222" width="540" height="3" fill="#000000" opacity="0.4"/>'
	s += '<rect x="10" y="92" width="540" height="132" fill="url(#laminate)" stroke="#7E5E3A" stroke-width="2"/>'
	for x in range(10, 550, 60):
		s += '<rect x="%d" y="104" width="52" height="112" fill="#CFA970" stroke="#8A6A40" stroke-width="1.2"/>' % (x + 4)
		s += '<path d="M%d 106 H%d M%d 106 V%d" stroke="#F0D9B0" stroke-width="2" opacity="0.8"/>' % [x + 6, x + 54, x + 6, 214]
		s += '<path d="M%d 214 H%d M%d 106 V%d" stroke="#8A6A40" stroke-width="2" opacity="0.5"/>' % [x + 6, x + 54, x + 56, 214]
	s += '<rect x="10" y="108" width="540" height="9" fill="#C8202A"/><rect x="10" y="108" width="540" height="2" fill="#FFFFFF" opacity="0.45"/><rect x="10" y="114" width="540" height="3" fill="#7A1018" opacity="0.6"/>'
	s += '<rect x="0" y="70" width="560" height="24" rx="3" fill="url(#countertop)" stroke="#A39578" stroke-width="2"/>'
	s += '<rect x="0" y="70" width="560" height="3" fill="#FFFFFF" opacity="0.7"/><rect x="0" y="90" width="560" height="4" fill="#8A7A5A" opacity="0.35"/>'
	s += '<rect x="10" y="94" width="540" height="12" fill="url(#shade)" opacity="0.7"/>'
	# Scratch tickets in a clear stand.
	s += '<rect x="76" y="2" width="170" height="68" rx="3" fill="#EEF0F2" stroke="#8E959C" stroke-width="2"/>'
	for i in 8:
		var c: String = ["#E04F5F", "#FFD23F", "#4FA3E0", "#7CCB5A", "#FF8A3D", "#C084FC", "#FF7BA3", "#1FB5C4"][i]
		s += '<rect x="%d" y="10" width="17" height="52" rx="2" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [84 + i * 20, c]
		s += '<circle cx="%d" cy="24" r="4.5" fill="#FFFFFF" opacity="0.85"/><rect x="%d" y="38" width="11" height="3" fill="#FFFFFF" opacity="0.7"/><rect x="%d" y="45" width="8" height="3" fill="#FFFFFF" opacity="0.5"/>' % [92 + i * 20, 87 + i * 20, 87 + i * 20]
	s += '<rect x="76" y="2" width="170" height="68" rx="3" fill="url(#glare)" opacity="0.5"/><rect x="76" y="58" width="170" height="12" fill="#C8202A"/>'
	# A coin jar and a pen on a chain, on the left.
	s += '<rect x="20" y="40" width="40" height="30" rx="6" fill="#F2FAFD" fill-opacity="0.75" stroke="#8FB0C0" stroke-width="2"/>'
	for c in [[30, 62], [42, 64], [52, 60], [36, 56], [46, 52]]:
		s += '<circle cx="%d" cy="%d" r="4.5" fill="#E3C26A" stroke="#A88A2E" stroke-width="1"/>' % [c[0], c[1]]
	s += '<rect x="24" y="34" width="32" height="8" rx="3" fill="#E04F5F"/>'
	# Gum and candy-bar rack.
	s += '<rect x="252" y="36" width="64" height="34" rx="2" fill="#E8E4DA" stroke="#8E959C" stroke-width="1.5"/>'
	for i in 4:
		s += '<rect x="%d" y="42" width="12" height="22" rx="2" fill="%s"/><rect x="%d" y="42" width="12" height="4" fill="#FFFFFF" opacity="0.6"/>' % [256 + i * 15, ["#7CCB5A", "#FF7BA3", "#4FA3E0", "#FFD23F"][i], 256 + i * 15]
	# The till: a screen on a stand, a card reader, a receipt sticking out of the printer.
	s += '<path d="M324 70 L334 36 H432 L442 70 Z" fill="#3A3F48" stroke="#1E2228" stroke-width="2"/>'
	s += '<rect x="344" y="42" width="78" height="24" rx="2" fill="#0F1A2A"/><rect x="348" y="45" width="70" height="18" fill="#7FD4F0"/>'
	for i in 5:
		s += '<rect x="%d" y="48" width="11" height="9" rx="1.5" fill="%s"/>' % [351 + i * 13.5, ["#FFFFFF", "#FFD23F", "#7CCB5A", "#FF8A3D", "#FFFFFF"][i]]
	s += '<rect x="348" y="45" width="70" height="7" fill="#FFFFFF" opacity="0.25"/>'
	s += '<rect x="330" y="62" width="106" height="8" fill="#2A2E36"/>'
	for i in 7:
		s += '<rect x="%d" y="64" width="9" height="4" fill="#C9CED6"/>' % (334 + i * 14)
	s += '<rect x="452" y="46" width="30" height="24" rx="3" fill="#2E343C" stroke="#14181D" stroke-width="1.5"/><rect x="458" y="50" width="18" height="7" fill="#7FD4A0"/>'
	for i in 3:
		s += '<rect x="%d" y="60" width="5" height="4" fill="#C9CED6"/>' % (458 + i * 7)
	s += '<path d="M310 70 V42 H322" stroke="#2A2E36" stroke-width="3" fill="none"/><rect x="298" y="32" width="26" height="16" rx="2" fill="#0F1A2A"/><rect x="301" y="35" width="20" height="10" fill="#7FD4F0"/>'
	s += '<rect x="488" y="52" width="14" height="18" fill="#FFFFFF" stroke="#C9CED6" stroke-width="1"/><path d="M490 56 H500 M490 60 H498 M490 64 H500" stroke="#9AA0A6" stroke-width="1"/>'
	# Paper bags and a hand-sanitiser pump on the right.
	s += '<path d="M510 70 V40 l22 -4 l18 6 V70 Z" fill="#C8A878" stroke="#8A6E3E" stroke-width="1.6"/><path d="M510 40 l22 -4 l18 6" stroke="#E0CBA0" stroke-width="2" fill="none"/>'
	s += '<rect x="534" y="48" width="10" height="22" rx="3" fill="#8FD0E0" stroke="#4E8AA0" stroke-width="1.2"/><rect x="537" y="42" width="4" height="8" fill="#4E8AA0"/><path d="M537 42 h-6" stroke="#4E8AA0" stroke-width="2.4"/>'
	return tex(560, 240, s)


## Canvas 480x440: the candy wall: pegged bags, jars of jellybeans, tubs, scoop bins of loose sweets and a lollipop
## stand, in a wooden frame under a lit pink header (sign in the game).
static func candy_wall() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := _defs()
	s += '<rect x="0" y="0" width="480" height="440" fill="#F6EAD8" stroke="#8A6E48" stroke-width="3"/>'
	s += '<rect x="0" y="0" width="14" height="440" fill="url(#wood)"/><rect x="466" y="0" width="14" height="440" fill="url(#wood)"/>'
	s += '<rect x="14" y="0" width="452" height="440" fill="#F2E3CC"/>'
	# Pegboard dots behind the top row.
	for gy in range(66, 150, 12):
		for gx in range(26, 460, 12):
			s += '<circle cx="%d" cy="%d" r="1.1" fill="#C9AE86"/>' % [gx, gy]
	s += '<rect x="22" y="10" width="436" height="46" rx="9" fill="#FF7BA3" stroke="#B5386A" stroke-width="2.5"/>'
	s += '<rect x="26" y="13" width="428" height="15" rx="7" fill="#FFFFFF" opacity="0.3"/>'
	for row in 4:
		var y := 82.0 + row * 88.0
		match row:
			0:
				# Candy bags hanging on pegs by their header cards.
				var x := 28.0
				while x < 440.0:
					s += '<path d="M%.1f %.1f V%.1f" stroke="#7E858D" stroke-width="2"/>' % [x + 14, y - 4, y + 4]
					s += '<rect x="%.1f" y="%.1f" width="28" height="9" fill="%s" stroke="#FFFFFF" stroke-width="1"/>' % [x, y + 4, _bright(rng)]
					s += _bag(x, y + 13, 28, 54, _bright(rng), rng)
					x += 34.0
			1:
				var x := 26.0
				while x < 440.0:
					s += _jar(x, y + 2, 44, 64, ["#E04F5F", "#4FA3E0", "#7CCB5A", "#FFD23F"][rng.randi_range(0, 3)], rng)
					s += _tag(x + 14, y + 72)
					x += 52.0
			2:
				var x := 24.0
				while x < 440.0:
					if rng.randf() < 0.55:
						var c := _bright(rng)
						s += '<rect x="%.1f" y="%.1f" width="40" height="50" rx="6" fill="%s"/><rect x="%.1f" y="%.1f" width="40" height="50" rx="6" fill="url(#cyl)"/>' % [x, y + 18, c, x, y + 18]
						s += '<rect x="%.1f" y="%.1f" width="44" height="9" rx="3" fill="#FFFFFF" stroke="#9A968E" stroke-width="1.2"/><circle cx="%.1f" cy="%.1f" r="8" fill="#FFFFFF" opacity="0.7"/>' % [x - 2, y + 12, x + 20, y + 44]
						x += 48.0
					else:
						s += _box(x, y + 16, 34, 52, _bright(rng))
						x += 40.0
			_:
				# Scoop bins of loose sweets, with a scoop on a hook.
				var x := 24.0
				for b in 4:
					var bw := 98.0
					s += '<path d="M%.1f %.1f H%.1f L%.1f %.1f H%.1f Z" fill="#FBFDFE" fill-opacity="0.8" stroke="#8FB0C0" stroke-width="2"/>' % [x, y + 20, x + bw, x + bw - 6, y + 70, x + 6]
					for k in 38:
						var cx := x + 8 + rng.randf() * (bw - 16)
						var cy := y + 30 + rng.randf() * 36
						s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [cx, cy, 3.4 + rng.randf() * 1.6, _bright(rng)]
					s += '<path d="M%.1f %.1f H%.1f L%.1f %.1f H%.1f Z" fill="#FFFFFF" opacity="0.28"/>' % [x, y + 20, x + bw, x + bw - 6, y + 70, x + 6]
					s += '<rect x="%.1f" y="%.1f" width="%.1f" height="10" fill="#E8EDF0" stroke="#9AA0A6" stroke-width="1.2"/>' % [x + 2, y + 12, bw - 4]
					s += '<path d="M%.1f %.1f q4 -10 8 0" stroke="#9AA0A6" stroke-width="2" fill="none"/>' % [x + bw - 20, y + 14]
					x += bw + 8.0
		s += '<rect x="14" y="%.1f" width="452" height="9" fill="url(#wood)"/><rect x="14" y="%.1f" width="452" height="2" fill="#FFFFFF" opacity="0.35"/>' % [y + 72, y + 72]
		s += '<rect x="14" y="%.1f" width="452" height="10" fill="url(#shade)" opacity="0.55"/>' % (y + 81)
	# A lollipop stand on the top of the right-hand shelf.
	s += '<rect x="404" y="400" width="58" height="34" fill="#8A6238"/>'
	for i in 7:
		var lx := 410.0 + i * 8.0
		s += '<path d="M%.1f 404 L%.1f %.1f" stroke="#F4F2EC" stroke-width="2.4"/>' % [lx, lx + (i - 3) * 2.0, 372.0 - (i % 2) * 8.0]
		s += '<circle cx="%.1f" cy="%.1f" r="7" fill="%s" stroke="#FFFFFF" stroke-width="1"/><path d="M%.1f %.1f q4 -5 7 0" stroke="#FFFFFF" stroke-width="1.6" fill="none"/>' % [lx + (i - 3) * 2.0, 366.0 - (i % 2) * 8.0, _bright(rng), lx + (i - 3) * 2.0 - 3.5, 366.0 - (i % 2) * 8.0]
	return tex(480, 440, s)


## Canvas 440x480: a drinks fridge with three glass doors: aluminium frames, the inside lit white, rows of bottles,
## cans and cartons on steel shelves with price rails, condensation, a vertical handle on each door.
static func drinks_fridge() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s := _defs()
	s += '<rect x="0" y="0" width="440" height="480" fill="url(#metal)" stroke="#6E757D" stroke-width="3"/>'
	s += '<rect x="8" y="6" width="424" height="34" rx="3" fill="#2E5FB0" stroke="#1B3E7C" stroke-width="2"/><rect x="12" y="8" width="416" height="11" rx="3" fill="#FFFFFF" opacity="0.3"/>'
	for d in 3:
		var x := 12.0 + d * 141.0
		s += '<rect x="%.1f" y="46" width="134" height="424" rx="4" fill="url(#steel)" stroke="#6E757D" stroke-width="2.5"/>' % x
		s += '<rect x="%.1f" y="54" width="118" height="408" fill="url(#backlit)" stroke="#8E959C" stroke-width="1.5"/>' % (x + 8)
		s += '<rect x="%.1f" y="54" width="5" height="408" fill="#FFFFFF"/><rect x="%.1f" y="54" width="5" height="408" fill="#FFFFFF"/>' % [x + 8, x + 121]
		for row in 4:
			var y := 62.0 + row * 100.0
			var bx := x + 16.0
			while bx < x + 112.0:
				var c: String = ["#FF8A3D", "#7CCB5A", "#E04F5F", "#4FA3E0", "#FFD23F", "#C084FC", "#1FB5C4"][rng.randi_range(0, 6)]
				match row:
					0:
						s += _bottle(bx, y + 18, 15, 56, c, ["#FFFFFF", "#2B2B2B", "#E04F5F"][rng.randi_range(0, 2)])
						bx += 19.0
					1:
						s += _can(bx, y + 30, 15, 44, c)
						bx += 18.0
					2:
						s += _box(bx, y + 22, 20, 52, c)
						bx += 24.0
					_:
						s += _bottle(bx, y + 4, 20, 70, c, "#FFFFFF")
						bx += 25.0
			s += '<rect x="%.1f" y="%.1f" width="118" height="7" fill="url(#steel)" stroke="#8E959C" stroke-width="0.8"/>' % [x + 8, y + 76]
			s += '<rect x="%.1f" y="%.1f" width="118" height="9" fill="url(#shade)" opacity="0.5"/>' % [x + 8, y + 83]
			for t in 3:
				s += _tag(x + 14 + t * 38, y + 78, t == 1 and row % 2 == 0)
		s += '<rect x="%.1f" y="54" width="118" height="408" fill="url(#glare)" opacity="0.45"/>' % (x + 8)
		s += '<path d="M%.1f 60 L%.1f 60 L%.1f 330 L%.1f 330 Z" fill="#FFFFFF" opacity="0.2"/>' % [x + 20, x + 46, x + 18, x + 8]
		s += '<rect x="%.1f" y="200" width="7" height="86" rx="3.5" fill="url(#metal)" stroke="#6E757D" stroke-width="1.2"/>' % (x + 122)
		for k in 14:
			s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFFFFF" opacity="0.5"/>' % [x + 14 + rng.randf() * 106, 380 + rng.randf() * 76, 1.0 + rng.randf() * 1.4]
	s += '<rect x="8" y="470" width="424" height="10" fill="#3A4048"/>'
	return tex(440, 480, s)


## Canvas 320x170: a chest freezer with a sliding glass lid full of ice pops, tubs and ice-cream sandwiches.
static func freezer() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := _defs()
	s += '<rect x="0" y="40" width="320" height="130" rx="10" fill="url(#steel)" stroke="#7E8A96" stroke-width="3"/>'
	s += '<rect x="0" y="40" width="320" height="130" rx="10" fill="#FFFFFF" opacity="0.55"/>'
	s += '<rect x="10" y="56" width="300" height="46" rx="6" fill="#2E5FB0"/><rect x="14" y="58" width="292" height="12" rx="5" fill="#FFFFFF" opacity="0.28"/>'
	s += '<path d="M160 64 m-16 8 a16 16 0 0 1 32 0 l-16 28 z" fill="#FFD9A0" stroke="#FFFFFF" stroke-width="2"/><circle cx="160" cy="62" r="12" fill="#FF7BA3" stroke="#FFFFFF" stroke-width="2"/><circle cx="160" cy="48" r="4" fill="#E04F5F"/>'
	s += '<rect x="6" y="118" width="308" height="8" fill="#8E959C" opacity="0.5"/>'
	for i in 8:
		s += '<rect x="%d" y="132" width="3" height="24" fill="#8E959C" opacity="0.5"/>' % (60 + i * 26)
	# The glass lid in a chrome frame, the sweets inside.
	s += '<path d="M0 40 L20 0 H300 L320 40 Z" fill="#CFE6F2" fill-opacity="0.9" stroke="#8E959C" stroke-width="3"/>'
	for i in 15:
		var x := 28.0 + i * 18.5
		var y := 6.0 + (i % 2) * 11.0
		var c := _bright(rng)
		if i % 4 == 3:
			s += '<rect x="%.1f" y="%.1f" width="15" height="19" rx="3" fill="%s" stroke="#FFFFFF" stroke-width="1.2"/><rect x="%.1f" y="%.1f" width="15" height="5" fill="#FFFFFF" opacity="0.7"/>' % [x, y, c, x, y + 7]
		else:
			s += '<rect x="%.1f" y="%.1f" width="13" height="19" rx="5" fill="%s"/><rect x="%.1f" y="%.1f" width="4" height="9" fill="#E8D2A8"/><rect x="%.1f" y="%.1f" width="13" height="19" rx="5" fill="url(#cyl)"/>' % [x, y, c, x + 4.5, y + 17, x, y]
	s += '<path d="M40 3 L130 3 L66 38 L28 38 Z" fill="#FFFFFF" opacity="0.4"/><path d="M200 3 L230 3 L196 38 L172 38 Z" fill="#FFFFFF" opacity="0.22"/>'
	s += '<rect x="8" y="34" width="304" height="8" rx="3" fill="url(#metal)" stroke="#7E8A96" stroke-width="1.5"/>'
	return tex(320, 170, s)


## Canvas 130x210: a wire rack of newspapers and magazines (black mastheads, headline lines, photos).
static func newspaper_rack() -> ImageTexture:
	var s := _defs()
	s += '<rect x="8" y="16" width="114" height="186" fill="#000000" opacity="0.06"/>'
	for i in 3:
		var y := 26.0 + i * 58.0
		s += '<rect x="16" y="%.1f" width="98" height="52" fill="#F7F4EC" stroke="#8E959C" stroke-width="1.2"/>' % y
		if i == 1:
			s += '<rect x="16" y="%.1f" width="98" height="52" fill="%s"/><rect x="26" y="%.1f" width="60" height="9" fill="#FFFFFF"/><rect x="26" y="%.1f" width="34" height="26" fill="#FFFFFF" opacity="0.7"/>' % [y, "#E04F5F", y + 5, y + 20]
		else:
			s += '<rect x="22" y="%.1f" width="66" height="9" fill="#1E1E1E"/><rect x="22" y="%.1f" width="40" height="24" fill="%s"/>' % [y + 5, y + 18, ["#9FB8D0", "", "#B8D0A0"][i]]
			for k in 3:
				s += '<rect x="66" y="%.1f" width="42" height="2.4" fill="#4A4A4A" opacity="0.7"/>' % (y + 20 + k * 6)
			s += '<rect x="22" y="%.1f" width="86" height="2" fill="#7A7A7A" opacity="0.6"/><rect x="22" y="%.1f" width="70" height="2" fill="#7A7A7A" opacity="0.6"/>' % [y + 44, y + 48]
	s += '<rect x="8" y="16" width="114" height="186" fill="none" stroke="#4E555B" stroke-width="3.5"/>'
	for y in [76, 134]:
		s += '<rect x="8" y="%d" width="114" height="3.5" fill="#4E555B"/>' % y
	s += '<path d="M8 202 l-5 9 M122 202 l5 9" stroke="#4E555B" stroke-width="4"/>'
	s += '<rect x="8" y="16" width="114" height="186" fill="url(#glare)" opacity="0.3"/>'
	return tex(130, 210, s)


## Canvas 200x140: an autumn display: a crate of carved and plain pumpkins and a cauldron of Halloween candy.
static func halloween_display() -> ImageTexture:
	var s := _defs()
	s += '<ellipse cx="100" cy="134" rx="96" ry="5" fill="#000000" opacity="0.2"/>'
	s += '<rect x="4" y="70" width="112" height="66" fill="url(#wood)" stroke="#5E4228" stroke-width="2"/>'
	for y in [84, 100, 116]:
		s += '<rect x="4" y="%d" width="112" height="2" fill="#5E4228" opacity="0.55"/>' % y
	for p in [[30, 66, 0], [60, 58, 1], [90, 66, 0], [44, 46, 0], [76, 44, 1]]:
		s += '<ellipse cx="%d" cy="%d" rx="17" ry="13" fill="#F28C28" stroke="#A84E10" stroke-width="1.5"/>' % [p[0], p[1]]
		s += '<path d="M%d %d q-6 -12 0 -24 M%d %d q6 -12 0 -24" stroke="#C86A14" stroke-width="1.4" fill="none"/>' % [p[0] - 5, p[1] + 12, p[0] + 5, p[1] + 12]
		s += '<path d="M%d %d q2 -6 6 -8" stroke="#5A6B2A" stroke-width="3" fill="none"/>' % [p[0], p[1] - 12]
		if p[2] == 1:
			s += '<path d="M%d %d l4 -6 l4 6 z M%d %d l4 -6 l4 6 z M%d %d q5 5 10 0" fill="#FFD23F" stroke="#FFD23F" stroke-width="1.5"/>' % [p[0] - 9, p[1] - 1, p[0] + 1, p[1] - 1, p[0] - 5, p[1] + 5]
		s += '<ellipse cx="%d" cy="%d" rx="17" ry="13" fill="url(#cyl)" opacity="0.7"/>' % [p[0], p[1]]
	s += '<path d="M118 82 Q118 138 158 138 Q198 138 198 82 Z" fill="#2B2B2B" stroke="#111111" stroke-width="2"/><path d="M126 90 Q130 128 150 134" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.25" stroke-linecap="round"/>'
	s += '<rect x="114" y="74" width="88" height="11" rx="5" fill="#3A3A3A" stroke="#111111" stroke-width="1.5"/>'
	for c in [[130, 70, "#FF8A3D"], [146, 64, "#C084FC"], [162, 69, "#7CCB5A"], [178, 66, "#FFD23F"], [190, 71, "#E04F5F"]]:
		s += '<rect x="%s" y="%s" width="14" height="10" rx="3" fill="%s" stroke="#FFFFFF" stroke-width="1"/>' % c
	s += '<path d="M2 70 L30 62 M2 70 L28 76 M2 70 L12 56" stroke="#FFFFFF" stroke-width="1.2" opacity="0.7" fill="none"/>'
	return tex(200, 140, s)


## Canvas 160x200: a lottery poster: a deep blue field, a big golden ball with shine, stars and a ribbon (the word
## is a label in the game).
static func lotto_poster() -> ImageTexture:
	var s := _defs()
	s += '<rect x="2" y="2" width="156" height="196" fill="#1D4F91" stroke="#102A56" stroke-width="3"/>'
	s += '<rect x="8" y="8" width="144" height="184" fill="none" stroke="#FFD23F" stroke-width="1.5" opacity="0.8"/>'
	s += '<path d="M2 2 H158 L120 80 L2 120 Z" fill="#FFFFFF" opacity="0.07"/>'
	s += '<circle cx="80" cy="122" r="46" fill="#FFD23F" stroke="#C99410" stroke-width="3"/><circle cx="80" cy="122" r="46" fill="url(#cyl)"/>'
	s += '<circle cx="64" cy="102" r="12" fill="#FFFFFF" opacity="0.5"/><circle cx="80" cy="122" r="30" fill="none" stroke="#C99410" stroke-width="2" opacity="0.6"/>'
	for st in [[30, 54], [130, 44], [24, 172], [138, 174], [80, 34]]:
		s += '<path d="M%s %s l4 9 l10 1 l-8 6 l3 10 l-9 -5 l-9 5 l3 -10 l-8 -6 l10 -1 z" fill="#FFF3B0"/>' % [st[0], st[1] - 10]
	s += '<rect x="2" y="170" width="156" height="14" fill="#C8202A"/>'
	return tex(160, 200, s)


## The classic chip flavours, in the order of the display: id, the name on the shelf, the bag's colour, its accent.
const CHIPS := [
	{"id": "creme", "name": "Crème sure et oignons", "short": "CRÈME SURE\n& OIGNONS", "bag": "#4E9A52", "accent": "#F4F2E6", "said": "des chips à la crème sure et oignons"},
	{"id": "ketchup", "name": "Ketchup", "short": "KETCHUP", "bag": "#D8352E", "accent": "#FFD23F", "said": "des chips au ketchup"},
	{"id": "bbq", "name": "Barbecue", "short": "BARBECUE", "bag": "#8E3A22", "accent": "#FF8A3D", "said": "des chips barbecue"},
	{"id": "nature", "name": "Nature", "short": "NATURE", "bag": "#F2C230", "accent": "#FFF3B0", "said": "des chips nature"},
	{"id": "vinaigre", "name": "Sel et vinaigre", "short": "SEL &\nVINAIGRE", "bag": "#2E86C1", "accent": "#E8F4FA", "said": "des chips sel et vinaigre"},
	{"id": "fromage", "name": "Fromage", "short": "FROMAGE", "bag": "#F08A24", "accent": "#FFE066", "said": "des chips au fromage"},
]


## The picture on a chip bag, for flavour `f` (an index into CHIPS), centred at (cx, cy), about `r` wide.
static func _chip_icon(f: int, cx: float, cy: float, r: float) -> String:
	var k := r / 100.0
	var g := '<g transform="translate(%.2f %.2f) scale(%.3f)">' % [cx, cy, k]
	match f:
		0:
			# Chives and a swirl of sour cream on a ring of onion.
			g += '<circle r="50" fill="none" stroke="#E8DDF0" stroke-width="16"/><circle r="30" fill="none" stroke="#C9B6DC" stroke-width="12"/>'
			g += '<path d="M-30 -50 q-10 -30 -5 -50 M10 -50 q5 -30 20 -45" stroke="#2E6E32" stroke-width="10" fill="none" stroke-linecap="round"/>'
		1:
			# A tomato with its leaves.
			g += '<circle r="56" fill="#FFFFFF" opacity="0.85"/><circle cy="4" r="44" fill="#E0301E"/>'
			g += '<path d="M-30 -36 l30 10 l30 -12 l-30 -10 z" fill="#3E8E3A" stroke="#2E6E32" stroke-width="4" stroke-linejoin="round"/>'
		2:
			# A flame.
			g += '<path d="M0 50 q-50 -30 -10 -90 q10 30 30 20 q30 30 -20 70 z" fill="#FFB02E" stroke="#FFFFFF" stroke-width="8"/>'
			g += '<path d="M0 46 q-18 -14 0 -40 q18 26 0 40 z" fill="#E0301E"/>'
		3:
			# A big crinkle chip.
			g += '<ellipse rx="56" ry="42" fill="#F7D56A" stroke="#C99410" stroke-width="7"/><path d="M-40 0 q10 -16 20 0 t20 0 t20 0" stroke="#E0A92A" stroke-width="7" fill="none"/>'
		4:
			# A vinegar drop and salt grains.
			g += '<path d="M0 -50 q-40 50 0 90 q40 -40 0 -90 z" fill="#FFFFFF" stroke="#1B5E8E" stroke-width="7"/><circle cx="50" cy="-30" r="7" fill="#FFFFFF"/><circle cx="-50" cy="30" r="6" fill="#FFFFFF"/>'
		_:
			# A wedge of cheese with holes.
			g += '<path d="M-50 40 L50 40 L30 -40 Z" fill="#FFD23F" stroke="#C99410" stroke-width="6" stroke-linejoin="round"/><circle cx="10" cy="20" r="8" fill="#E0A92A"/><circle cx="-10" cy="28" r="6" fill="#E0A92A"/>'
	return g + '</g>'


## A bag of chips of flavour `f`: crimped ends, a coloured field with a wave, the flavour's picture, a window of chips.
static func _chip_bag(x: float, y: float, w: float, h: float, f: int) -> String:
	var c: String = CHIPS[f].bag
	var a: String = CHIPS[f].accent
	var s := '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Q%.1f %.1f %.1f %.1f Z" fill="%s" stroke="#00000044" stroke-width="0.9"/>' % [
		x + 1, y + 5, x + w * 0.17, y + 1, x + w * 0.33, y + 5, x + w * 0.5, y + 1, x + w * 0.67, y + 5, x + w * 0.83, y + 1, x + w - 1, y + 5, x + w, y + h - 4, x + w - 2, y + h, x + w / 2, y + h + 3, x + 2, y + h, c]
	s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="%s" opacity="0.95"/>' % [x + 1, y + h * 0.62, x + w * 0.5, y + h * 0.45, x + w, y + h * 0.62, x + w, y + h - 2, x + 1, y + h - 2, a]
	s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="%.1f" fill="none" opacity="0.7"/>' % [x + 1, y + h * 0.58, x + w * 0.5, y + h * 0.41, x + w, y + h * 0.58, a, h * 0.03]
	s += _chip_icon(f, x + w / 2, y + h * 0.36, w * 0.8)
	s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#F7D56A" opacity="0.95" stroke="#C99410" stroke-width="0.6"/>' % [x + w / 2, y + h * 0.8, w * 0.22, w * 0.15]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="url(#cyl)"/>' % [x, y + 4, w, h - 4]
	s += '<path d="M%.1f %.1f q%.1f %.1f 0 %.1f" stroke="#FFFFFF" stroke-width="%.1f" opacity="0.55" fill="none" stroke-linecap="round"/>' % [x + w * 0.16, y + 10, w * 0.04, h * 0.25, h * 0.04, w * 0.08]
	return s


## Canvas 440x240: the chips gondola: a header with the six classic flavours' colours (names are labels in the game),
## three shelves of bags lined up flavour by flavour, price rails, a red "special" tag on the end.
static func chips_gondola() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="440" height="240" fill="#E9E5DB" stroke="#7E7A72" stroke-width="3"/>'
	s += '<rect x="0" y="0" width="440" height="40" fill="#FFFFFF" stroke="#9A968E" stroke-width="2"/>'
	for f in 6:
		s += '<rect x="%d" y="3" width="70" height="34" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [3 + f * 72, CHIPS[f].bag]
		s += '<rect x="%d" y="3" width="70" height="9" fill="#FFFFFF" opacity="0.3"/>' % (3 + f * 72)
	s += '<rect x="0" y="40" width="440" height="6" fill="#C8202A"/>'
	for row in 3:
		var y := 50.0 + row * 62.0
		for f in 6:
			for k in 2:
				s += _chip_bag(10 + f * 72 + k * 31, y + 4, 28, 50, f)
		s += _lip(4, y + 56, 432)
		for f in 6:
			s += _tag(14 + f * 72 + 22, y + 59, f == row + 2 and row != 1)
	s += '<rect x="0" y="228" width="440" height="12" fill="#6E6A62"/>'
	s += '<rect x="0" y="40" width="5" height="190" fill="#000000" opacity="0.12"/><rect x="435" y="40" width="5" height="190" fill="#000000" opacity="0.2"/>'
	return tex(440, 240, s)


## Canvas 64x64: a bag of chips of flavour `f` (what Charlotte gets).
static func chip_treat(f: int) -> ImageTexture:
	var s := _defs() + _chip_bag(12, 6, 40, 52, f)
	return tex(64, 64, s)


## Canvas 38x170: a clip strip of mini bags of chips hanging from a shelf.
static func clip_strip() -> ImageTexture:
	var s := _defs()
	s += '<path d="M19 0 V170" stroke="#7E858D" stroke-width="2"/>'
	for i in 6:
		s += _chip_bag(5, 6 + i * 27, 28, 24, i)
		s += '<rect x="14" y="%d" width="10" height="4" fill="#C9CED6" stroke="#7E858D" stroke-width="0.8"/>' % (4 + i * 27)
	return tex(38, 170, s)


## Canvas 640x300: the wall shelves behind the counter, crammed with small things (batteries, gum, toothpaste, soap,
## chargers on cards, cleaners, gift cards), yellow price tags along each shelf's lip.
static func back_shelves() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var s := _defs()
	s += '<rect x="0" y="0" width="640" height="300" fill="#DDD6C6" stroke="#8E8266" stroke-width="3"/>'
	s += '<rect x="0" y="0" width="640" height="300" fill="url(#shade)" opacity="0.18"/>'
	for row in 4:
		var y := 12.0 + row * 72.0
		var x := 10.0
		while x < 612.0:
			var kind := rng.randi_range(0, 6)
			var c := _bright(rng)
			match kind:
				0:
					s += _box(x, y + 20, 22, 36, c)
					x += 26.0
				1:
					# A rack of batteries and small cards.
					for k in 3:
						s += '<rect x="%.1f" y="%.1f" width="9" height="22" rx="2" fill="%s" stroke="#00000044" stroke-width="0.8"/><rect x="%.1f" y="%.1f" width="9" height="6" fill="#C9CED6"/>' % [x + k * 11, y + 34, ["#E04F5F", "#FFD23F", "#2B2B2B"][k], x + k * 11, y + 34]
					x += 38.0
				2:
					s += _bottle(x, y + 10, 18, 46, c, "#2B2B2B")
					x += 22.0
				3:
					# A charger on its blister card.
					s += '<rect x="%.1f" y="%.1f" width="26" height="44" fill="#F4F2EC" stroke="#9A968E" stroke-width="1.2"/><rect x="%.1f" y="%.1f" width="26" height="9" fill="%s"/>' % [x, y + 12, x, y + 12, c]
					s += '<rect x="%.1f" y="%.1f" width="14" height="22" rx="3" fill="#E8EDF2" stroke="#9AA0A6" stroke-width="1"/><circle cx="%.1f" cy="%.1f" r="2" fill="#FFFFFF"/><circle cx="%.1f" cy="%.1f" r="1.6" fill="#9A968E"/>' % [x + 6, y + 28, x + 8, y + 32, x + 13, y + 14]
					x += 31.0
				4:
					s += _can(x, y + 24, 16, 32, c)
					s += _can(x + 18, y + 24, 16, 32, _bright(rng))
					x += 38.0
				5:
					# A stack of soap bars and a tube.
					for k in 3:
						s += '<rect x="%.1f" y="%.1f" width="26" height="8" rx="2" fill="%s" stroke="#00000033" stroke-width="0.8"/>' % [x, y + 48 - k * 9, ["#F4F2EC", "#BFE3F0", "#F7C6D4"][k]]
					x += 32.0
				_:
					# Gift cards on a spinner.
					s += '<rect x="%.1f" y="%.1f" width="3" height="46" fill="#7E858D"/>' % [x + 17, y + 12]
					for k in 5:
						s += '<rect x="%.1f" y="%.1f" width="15" height="9" rx="1.5" fill="%s" stroke="#FFFFFF" stroke-width="0.8" transform="rotate(%d %.1f %.1f)"/>' % [x + 10, y + 12 + k * 8, _bright(rng), (k - 2) * 7, x + 18, y + 16 + k * 8]
					x += 40.0
			if rng.randf() < 0.4:
				s += _tag(x - 20, y + 62)
		s += '<rect x="4" y="%.1f" width="632" height="8" fill="url(#wood)"/>' % (y + 56)
		s += '<rect x="4" y="%.1f" width="632" height="2" fill="#FFFFFF" opacity="0.4"/><rect x="4" y="%.1f" width="632" height="9" fill="url(#shade)" opacity="0.5"/>' % [y + 56, y + 64]
	return tex(640, 300, s)


## Canvas 440x200: a generic low gondola in the middle of the shop: cans, boxes and bags, price rails, red tags.
static func gondola() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var s := _defs()
	s += '<rect x="0" y="0" width="440" height="200" fill="#E9E5DB" stroke="#7E7A72" stroke-width="3"/>'
	s += '<rect x="0" y="188" width="440" height="12" fill="#6E6A62"/>'
	for row in 3:
		var y := 8.0 + row * 60.0
		var x := 10.0
		while x < 420.0:
			var c := _bright(rng)
			match rng.randi_range(0, 2):
				0:
					s += _can(x, y + 18, 18, 34, c)
					x += 22.0
				1:
					s += _box(x, y + 6, 30, 46, c)
					x += 34.0
				_:
					s += _bag(x, y + 8, 26, 44, c, rng)
					x += 32.0
		s += _lip(4, y + 52, 432)
		for t in 4:
			s += _tag(rng.randf_range(14, 400), y + 55, rng.randf() < 0.3)
	s += '<rect x="0" y="0" width="5" height="200" fill="#000000" opacity="0.1"/><rect x="435" y="0" width="5" height="200" fill="#000000" opacity="0.2"/>'
	return tex(440, 200, s)


## A one-litre milk carton (a "pinte"): gable top with its fold, white with a blue band, cow spots and a screw cap.
## Original design; the name goes on it as a label in the game.
static func _carton(x: float, y: float, w: float, h: float) -> String:
	var s := '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#EEF3F7" stroke="#7E95A8" stroke-width="1.6" stroke-linejoin="round"/>' % [
		x, y + h * 0.2, x + w * 0.3, y, x + w * 0.7, y, x + w, y + h * 0.2, x + w, y + h * 0.2]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FBFDFF" stroke="#7E95A8" stroke-width="1.6"/>' % [x, y + h * 0.2, w, h * 0.8]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#2E86C1"/><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFFFFF" opacity="0.25"/>' % [x, y + h * 0.5, w, h * 0.22, x, y + h * 0.5, w, h * 0.05]
	for sp in [[0.2, 0.3, 0.1], [0.62, 0.36, 0.12], [0.4, 0.8, 0.09], [0.8, 0.85, 0.1], [0.15, 0.9, 0.07]]:
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#2B3A55" opacity="0.85"/>' % [x + w * sp[0], y + h * sp[1], w * sp[2], w * sp[2] * 0.7]
	s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#7E95A8" stroke-width="1.6"/><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="1.5" fill="#FFD23F" stroke="#C99410" stroke-width="1"/>' % [x + w * 0.5, y, x + w * 0.5, y + h * 0.2, x + w * 0.4, y - h * 0.04, w * 0.2, h * 0.06]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="url(#cyl)" opacity="0.8"/>' % [x, y + h * 0.2, w, h * 0.8]
	return s


## Canvas 440x480: an open-front dairy cooler (lit blue-white), Québec's 4 L milk bags (a bag of three little bags in
## a pitcher-style pouch), cartons, yogurts, eggs, butter and cheese; a rolled-up night blind on top.
static func milk_cooler() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var s := _defs()
	s += '<rect x="0" y="0" width="440" height="480" fill="url(#metal)" stroke="#6E757D" stroke-width="3"/>'
	s += '<rect x="8" y="6" width="424" height="38" rx="4" fill="#3B8FD0" stroke="#1D5E96" stroke-width="2"/><rect x="12" y="9" width="416" height="12" rx="4" fill="#FFFFFF" opacity="0.3"/>'
	s += '<rect x="8" y="46" width="424" height="12" rx="6" fill="url(#steel)" stroke="#8E959C" stroke-width="1.2"/>'
	s += '<rect x="14" y="62" width="412" height="378" fill="url(#cool)" stroke="#8E959C" stroke-width="2"/>'
	for row in 4:
		var y := 70.0 + row * 92.0
		var x := 24.0
		while x < 408.0:
			match row:
				0:
					# The 4 L bags: a soft white pouch, a blue label, a handle ring.
					s += '<path d="M%.1f %.1f q22 -12 44 0 l4 58 q-26 12 -52 0 z" fill="#FBFDFF" stroke="#7E95A8" stroke-width="1.8"/><path d="M%.1f %.1f q8 -16 16 0" stroke="#7E95A8" stroke-width="2.4" fill="none"/>' % [x, y + 24, x + 14, y + 12]
					s += '<rect x="%.1f" y="%.1f" width="48" height="20" fill="%s"/><rect x="%.1f" y="%.1f" width="48" height="5" fill="#FFFFFF" opacity="0.35"/>' % [x + 1, y + 50, ["#2E86C1", "#E04F5F", "#7CCB5A"][rng.randi_range(0, 2)], x + 1, y + 50]
					s += '<path d="M%.1f %.1f q8 -4 14 6" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.7" stroke-linecap="round"/>' % [x + 8, y + 36]
					x += 56.0
				1:
					s += _carton(x, y + 10, 32, 62)
					x += 38.0
				2:
					# Yogurt cups with foil lids.
					var c := _bright(rng)
					s += '<path d="M%.1f %.1f h30 l-4 38 h-22 z" fill="#FBFDFF" stroke="#8E959C" stroke-width="1.2"/><rect x="%.1f" y="%.1f" width="30" height="14" fill="%s"/><rect x="%.1f" y="%.1f" width="32" height="5" rx="2" fill="url(#steel)"/>' % [x, y + 44, x + 1, y + 54, c, x - 1, y + 40]
					s += '<path d="M%.1f %.1f h30 l-4 38 h-22 z" fill="url(#cyl)"/>' % [x, y + 44]
					x += 36.0
				_:
					if rng.randf() < 0.5:
						s += '<rect x="%.1f" y="%.1f" width="62" height="26" rx="3" fill="#E8D9B8" stroke="#B9A47A" stroke-width="1.5"/>' % [x, y + 52]
						for k in 5:
							s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="4" fill="#F6EBD8" stroke="#D9C9A8" stroke-width="0.8"/>' % [x + 9 + k * 11, y + 52]
						x += 70.0
					else:
						s += '<rect x="%.1f" y="%.1f" width="34" height="14" fill="#FFF3B0" stroke="#C99410" stroke-width="1.4"/><rect x="%.1f" y="%.1f" width="34" height="5" fill="#FFFFFF" opacity="0.6"/>' % [x, y + 62, x, y + 62]
						s += '<path d="M%.1f %.1f l22 -14 l8 14 z" fill="#FFD23F" stroke="#C99410" stroke-width="1.4" stroke-linejoin="round"/><circle cx="%.1f" cy="%.1f" r="2.2" fill="#E0A92A"/>' % [x + 40, y + 76, x + 52, y + 70]
						x += 86.0
		s += '<rect x="14" y="%.1f" width="412" height="8" fill="url(#steel)" stroke="#8E959C" stroke-width="0.8"/><rect x="14" y="%.1f" width="412" height="9" fill="url(#shade)" opacity="0.5"/>' % [y + 84, y + 92]
		for t in 6:
			s += _tag(24 + t * 64, y + 85, t == 2 and row == 0)
	s += '<rect x="14" y="62" width="412" height="378" fill="url(#glare)" opacity="0.25"/>'
	s += '<rect x="14" y="442" width="412" height="30" fill="#4A525A"/>'
	for x in range(22, 420, 10):
		s += '<rect x="%d" y="448" width="4" height="18" fill="#2C3238"/>' % x
	return tex(440, 480, s)


## Canvas 220x320: a slush machine on its stainless cabinet: two clear bowls (blue, red) with domed lids and taps, a lit
## header, a drip tray with its grate and a stack of cups. The swirling inside is drawn by the scene on top of it.
static func slush_machine() -> ImageTexture:
	var s := _defs()
	s += '<ellipse cx="110" cy="318" rx="104" ry="5" fill="#000000" opacity="0.18"/>'
	s += '<rect x="10" y="196" width="200" height="124" fill="url(#steel)" stroke="#7E858D" stroke-width="3"/>'
	s += '<rect x="20" y="206" width="180" height="42" fill="#EEF1F4" stroke="#9AA3AC" stroke-width="1.5"/>'
	for k in 8:
		s += '<rect x="%d" y="256" width="3" height="52" fill="#7E858D" opacity="0.5"/>' % (28 + k * 22)
	for i in 2:
		var x := 22.0 + i * 92.0
		var col: String = ["#3D7FD0", "#E0303A"][i]
		s += '<rect x="%.1f" y="40" width="84" height="122" rx="22" fill="%s" fill-opacity="0.82" stroke="#7E858D" stroke-width="3"/>' % [x, col]
		s += '<path d="M%.1f 44 q42 -26 84 0 z" fill="#E8EDF2" stroke="#7E858D" stroke-width="2.5"/>' % x
		s += '<rect x="%.1f" y="150" width="84" height="44" fill="url(#steel)" stroke="#7E858D" stroke-width="2"/><rect x="%.1f" y="162" width="22" height="30" rx="4" fill="#2B2B2B"/><rect x="%.1f" y="158" width="28" height="8" rx="3" fill="%s"/>' % [x, x + 31, x + 28, col]
		s += '<path d="M%.1f 52 L%.1f 52 L%.1f 130 Z" fill="#FFFFFF" opacity="0.35"/><rect x="%.1f" y="40" width="84" height="122" rx="22" fill="url(#cyl)" opacity="0.5"/>' % [x + 10, x + 32, x + 10, x]
	s += '<rect x="14" y="14" width="192" height="26" rx="9" fill="#F4F2EC" stroke="#7E858D" stroke-width="2"/><rect x="18" y="17" width="184" height="9" rx="4" fill="#FFFFFF" opacity="0.7"/>'
	s += '<rect x="6" y="186" width="208" height="10" rx="3" fill="url(#metal)" stroke="#7E858D" stroke-width="1.5"/>'
	for i in 3:
		s += '<path d="M%d 306 l3 -34 h22 l3 34 z" fill="#FBFDFF" stroke="#9AA3AC" stroke-width="1.2"/><rect x="%d" y="272" width="28" height="5" fill="%s" opacity="0.9"/>' % [150 + i * 20 - 40 + 40, 150 + i * 20 - 40 + 40, ["#3D7FD0", "#E0303A", "#FFD23F"][i]]
	return tex(220, 320, s)


## Canvas 280x280: the coffee and hot-chocolate corner: cabinet, two insulated dispensers with taps and a drip tray,
## cups under the spouts, a tower of lids, stacks of cups, a tray of sugar and stir sticks.
static func coffee_station() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="150" width="280" height="130" fill="url(#wood)" stroke="#5E4228" stroke-width="2"/>'
	for x in [8, 98, 188]:
		s += '<rect x="%d" y="162" width="84" height="108" fill="#A67A45" stroke="#5E4228" stroke-width="1.5"/><rect x="%d" y="164" width="80" height="4" fill="#F0D9B0" opacity="0.5"/><circle cx="%d" cy="184" r="3" fill="#E3C26A"/>' % [x, x + 2, x + 70]
	s += '<rect x="0" y="140" width="280" height="14" fill="#D9CDB4" stroke="#A39578" stroke-width="1.5"/><rect x="0" y="140" width="280" height="3" fill="#FFFFFF" opacity="0.6"/>'
	s += '<rect x="20" y="10" width="124" height="130" rx="8" fill="#33383F" stroke="#14181D" stroke-width="2"/><rect x="28" y="16" width="108" height="30" rx="4" fill="#5E6A74"/><rect x="32" y="20" width="100" height="9" fill="#FFFFFF" opacity="0.2"/>'
	for i in 2:
		var x := 34.0 + i * 54.0
		s += '<rect x="%.1f" y="54" width="42" height="40" rx="6" fill="url(#steel)" stroke="#6E757D" stroke-width="1.5"/><rect x="%.1f" y="60" width="10" height="6" rx="2" fill="%s"/>' % [x, x + 16, ["#E04F5F", "#7CCB5A"][i]]
		s += '<rect x="%.1f" y="94" width="8" height="8" fill="#2B2B2B"/>' % (x + 17)
		s += '<path d="M%.1f 104 h32 l-4 34 h-24 z" fill="#3E2A1E" fill-opacity="0.88" stroke="#E6EAEE" stroke-width="2"/><rect x="%.1f" y="100" width="34" height="8" rx="2" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1.2"/>' % [x + 5, x + 4]
	s += '<rect x="22" y="134" width="120" height="6" fill="#14181D"/>'
	for i in 3:
		s += '<path d="M%d 140 l4 -62 h20 l4 62 z" fill="#FBFAF6" stroke="#C9C2B4" stroke-width="1.5"/><rect x="%d" y="96" width="24" height="6" fill="%s"/>' % [160 + i * 34, 161 + i * 34, ["#C8202A", "#2E86C1", "#C8202A"][i]]
	s += '<path d="M240 140 v-20 h14 v20 z" fill="#E8EDF2" stroke="#9AA3AC" stroke-width="1.2"/><circle cx="247" cy="112" r="8" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1.2"/>'
	s += '<rect x="152" y="128" width="50" height="12" rx="3" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="1.5"/>'
	for i in 8:
		s += '<rect x="%d" y="121" width="2.5" height="9" fill="#D9B07A"/>' % (156 + i * 5.5)
	return tex(280, 280, s)


## Canvas 220x360: a wire rack of sliced bread, buns and bagels in their bags, with twist ties and labels.
static func bread_rack() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var s := _defs()
	s += '<rect x="10" y="10" width="200" height="342" fill="#000000" opacity="0.05"/>'
	for row in 4:
		var y := 20.0 + row * 82.0
		for k in 3:
			var x := 18.0 + k * 64.0
			var c := _bright(rng)
			if row == 3 and k == 1:
				# A basket of rolls.
				s += '<path d="M%.1f %.1f h58 l-6 36 h-46 z" fill="#B88850" stroke="#7A5428" stroke-width="1.5"/>' % [x, y + 38]
				for r in 5:
					s += '<ellipse cx="%.1f" cy="%.1f" rx="10" ry="8" fill="#D9A04A" stroke="#A8701E" stroke-width="1"/>' % [x + 10 + r * 9, y + 36 - (r % 2) * 5]
				continue
			s += '<rect x="%.1f" y="%.1f" width="58" height="52" rx="14" fill="#FBF7EE" fill-opacity="0.85" stroke="#C9C2B4" stroke-width="1.5"/>' % [x, y + 20]
			s += '<rect x="%.1f" y="%.1f" width="38" height="26" rx="11" fill="#D9A04A" stroke="#A8701E" stroke-width="1"/>' % [x + 10, y + 26]
			for sl in 4:
				s += '<path d="M%.1f %.1f v22" stroke="#A8701E" stroke-width="0.9" opacity="0.5"/>' % [x + 17 + sl * 8, y + 29]
			s += '<rect x="%.1f" y="%.1f" width="58" height="14" fill="%s"/><rect x="%.1f" y="%.1f" width="58" height="4" fill="#FFFFFF" opacity="0.35"/>' % [x, y + 46, c, x, y + 46]
			s += '<circle cx="%.1f" cy="%.1f" r="3.5" fill="%s" stroke="#00000044" stroke-width="0.8"/>' % [x + 29, y + 20, _bright(rng)]
			s += '<path d="M%.1f %.1f q4 6 0 12" stroke="#FFFFFF" stroke-width="2.4" fill="none" opacity="0.5" stroke-linecap="round"/>' % [x + 6, y + 30]
		s += '<rect x="10" y="%.1f" width="200" height="4" fill="#5A5F63"/><rect x="10" y="%.1f" width="200" height="8" fill="url(#shade)" opacity="0.35"/>' % [y + 74, y + 78]
	s += '<rect x="10" y="10" width="200" height="342" fill="none" stroke="#4E555B" stroke-width="4"/>'
	s += '<path d="M10 352 l-8 10 M210 352 l8 10" stroke="#4E555B" stroke-width="4"/>'
	return tex(220, 360, s)


## Canvas 150x340: a cash machine: a lit header band (its sign is a label in the game), a bright screen with buttons,
## a keypad of raised keys, the card slot with its arrow, the receipt slot and the cash door.
static func atm() -> ImageTexture:
	var s := _defs()
	s += '<rect x="10" y="20" width="130" height="320" rx="10" fill="#3A4452" stroke="#1E252D" stroke-width="3"/>'
	s += '<rect x="10" y="20" width="130" height="320" rx="10" fill="url(#cyl)" opacity="0.5"/>'
	s += '<rect x="10" y="20" width="130" height="42" rx="10" fill="#1D4F91"/><rect x="14" y="23" width="122" height="12" rx="6" fill="#FFFFFF" opacity="0.28"/>'
	s += '<rect x="22" y="72" width="106" height="84" rx="5" fill="#14202E" stroke="#0A121B" stroke-width="2"/><rect x="28" y="78" width="94" height="72" fill="#7FD4F0"/>'
	s += '<rect x="28" y="78" width="94" height="14" fill="#2E86C1"/><rect x="36" y="100" width="56" height="7" fill="#FFFFFF"/><rect x="36" y="114" width="78" height="5" fill="#FFFFFF" opacity="0.6"/><rect x="36" y="124" width="64" height="5" fill="#FFFFFF" opacity="0.5"/>'
	for k in 3:
		s += '<rect x="24" y="%d" width="4" height="12" fill="#C9CED6"/><rect x="122" y="%d" width="4" height="12" fill="#C9CED6"/>' % [84 + k * 22, 84 + k * 22]
	s += '<path d="M28 78 L70 78 L28 120 Z" fill="#FFFFFF" opacity="0.25"/>'
	for r in 4:
		for c in 3:
			s += '<rect x="%d" y="%d" width="24" height="14" rx="3" fill="#DDE1E6" stroke="#6E757D" stroke-width="1"/><rect x="%d" y="%d" width="24" height="4" rx="2" fill="#FFFFFF" opacity="0.8"/>' % [34 + c * 28, 168 + r * 19, 34 + c * 28, 168 + r * 19]
	s += '<rect x="36" y="250" width="78" height="16" rx="3" fill="#0F1318"/><path d="M60 258 h30 l-6 -5 m6 5 l-6 5" stroke="#7CCB5A" stroke-width="2" fill="none"/>'
	s += '<rect x="36" y="276" width="78" height="9" rx="3" fill="#0F1318"/><rect x="42" y="272" width="66" height="4" fill="#F4F2EC"/>'
	s += '<rect x="30" y="294" width="90" height="22" rx="4" fill="#0F1318" stroke="#6E757D" stroke-width="1.5"/><rect x="34" y="298" width="82" height="14" fill="#2A2F36"/>'
	return tex(150, 340, s)


## Canvas 120x120: the convex security mirror in a top corner, the shop reflected small and bent in it.
static func security_mirror() -> ImageTexture:
	var s := _defs()
	s += '<circle cx="60" cy="60" r="55" fill="#4E555B"/><circle cx="60" cy="60" r="50" fill="#B9D0DC"/>'
	s += '<path d="M14 84 Q60 54 106 84 L106 100 Q60 112 14 100 Z" fill="#E8E4DA" opacity="0.85"/>'
	s += '<path d="M20 70 Q60 40 100 70 L100 78 Q60 56 20 78 Z" fill="#C9A26E" opacity="0.8"/>'
	s += '<rect x="44" y="56" width="32" height="14" fill="#C8202A" opacity="0.7"/><circle cx="80" cy="48" r="5" fill="#FFD23F" opacity="0.8"/><circle cx="38" cy="50" r="6" fill="#7CCB5A" opacity="0.7"/>'
	s += '<circle cx="60" cy="60" r="50" fill="url(#dome)"/><path d="M26 34 Q46 16 72 20" stroke="#FFFFFF" stroke-width="6" fill="none" opacity="0.75" stroke-linecap="round"/>'
	s += '<circle cx="60" cy="60" r="50" fill="none" stroke="#2E343A" stroke-width="3"/>'
	return tex(120, 120, s)


## Canvas 240x170: the specials chalkboard in a wooden frame, chalk dust and doodles (its words are labels).
static func specials_board() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="240" height="170" rx="6" fill="url(#wood)" stroke="#5E4228" stroke-width="2"/>'
	s += '<rect x="10" y="10" width="220" height="150" fill="#2E3A34" stroke="#1B2420" stroke-width="2"/>'
	s += '<path d="M10 120 Q60 100 120 118 T230 110 V160 H10 Z" fill="#FFFFFF" opacity="0.06"/>'
	s += '<path d="M24 52 H216" stroke="#F4F2EC" stroke-width="2" opacity="0.5"/>'
	s += '<path d="M176 132 l10 -20 l10 20 z M186 112 v-8" stroke="#F4F2EC" stroke-width="1.8" fill="none" opacity="0.7"/>'
	s += '<path d="M30 140 h30 M30 146 h20" stroke="#FFD23F" stroke-width="2" opacity="0.7"/><path d="M200 138 l4 8 l9 1 l-7 6 l2 9" stroke="#FF8A3D" stroke-width="1.6" fill="none" opacity="0.7"/>'
	s += '<rect x="6" y="150" width="228" height="8" fill="url(#wood)" stroke="#5E4228" stroke-width="1"/><rect x="190" y="146" width="22" height="4" fill="#F4F2EC"/>'
	return tex(240, 170, s)


## Canvas 170x440: the grey metal back door to the stockroom: a push bar, a wired window, louvres, a fire-door sticker
## ("PRIVÉ" is a label).
static func back_door() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="170" height="440" fill="url(#metal)" stroke="#5E6A74" stroke-width="3"/>'
	s += '<rect x="12" y="12" width="146" height="428" fill="url(#steel)" stroke="#5E6A74" stroke-width="2"/>'
	s += '<rect x="46" y="96" width="78" height="86" fill="#B9D0DC" stroke="#4E555B" stroke-width="3"/>'
	for k in range(52, 124, 12):
		s += '<path d="M%d 96 V182" stroke="#7E95A8" stroke-width="1" opacity="0.7"/>' % k
	for k in range(108, 182, 12):
		s += '<path d="M46 %d H124" stroke="#7E95A8" stroke-width="1" opacity="0.7"/>' % k
	s += '<path d="M50 100 L84 100 L50 160 Z" fill="#FFFFFF" opacity="0.35"/>'
	for k in 6:
		s += '<rect x="30" y="%d" width="110" height="3" fill="#7E858D" opacity="0.8"/>' % (336 + k * 8)
	s += '<rect x="22" y="228" width="126" height="16" rx="7" fill="url(#steel)" stroke="#4E555B" stroke-width="1.8"/>'
	s += '<rect x="22" y="40" width="126" height="36" fill="#F4F2EC" stroke="#9AA3AC" stroke-width="1.5"/>'
	s += '<rect x="106" y="286" width="34" height="34" fill="#2E8B57" stroke="#FFFFFF" stroke-width="2"/><circle cx="123" cy="297" r="3.5" fill="#FFFFFF"/><path d="M123 301 v8 l-6 6 M123 305 l6 -4 M123 309 l5 6" stroke="#FFFFFF" stroke-width="2" fill="none"/>'
	for y in [60, 380]:
		s += '<rect x="4" y="%d" width="10" height="22" rx="2" fill="#4E555B"/>' % y
	return tex(170, 440, s)


## Canvas 64x64: a treat from the shop ("candy" a bag of jellies, "popsicle", "juice" a juice box, "lollipop", "slush",
## "chocolate", "milk" the 4 L bag).
static func treat(kind: String) -> ImageTexture:
	var s := _defs()
	match kind:
		"popsicle":
			s += '<rect x="28" y="40" width="8" height="20" rx="2" fill="#E8D2A8" stroke="#B8A27A" stroke-width="1"/><rect x="18" y="6" width="28" height="40" rx="12" fill="#FF8A3D" stroke="#C46A1E" stroke-width="1.5"/><rect x="18" y="6" width="28" height="16" rx="10" fill="#E04F5F"/><rect x="18" y="6" width="28" height="40" rx="12" fill="url(#cyl)"/>'
		"juice":
			s += '<rect x="16" y="14" width="32" height="44" rx="3" fill="#7CCB5A" stroke="#3E8E5A" stroke-width="2"/><circle cx="32" cy="38" r="10" fill="#FF8A3D"/><path d="M32 28 q4 -6 8 -3" stroke="#3E8E3A" stroke-width="2" fill="none"/><path d="M40 14 L44 2" stroke="#F4F2EC" stroke-width="3"/><rect x="16" y="14" width="32" height="44" fill="url(#cyl)"/>'
		"slush":
			s += '<path d="M18 16 H46 L42 60 H22 Z" fill="#3D7FD0" stroke="#FFFFFF" stroke-width="2"/><path d="M22 28 q10 -8 20 0" stroke="#9FD4F0" stroke-width="3" fill="none"/><path d="M20 22 q12 -14 24 0 z" fill="#7FC4F0"/><rect x="16" y="10" width="32" height="8" rx="3" fill="#F4F2EC"/><path d="M36 10 L42 0" stroke="#E04F5F" stroke-width="3"/><path d="M18 16 H46 L42 60 H22 Z" fill="url(#cyl)"/>'
		"milk":
			s += '<path d="M12 20 q20 -12 40 0 l4 38 q-24 10 -48 0 z" fill="#FFFFFF" stroke="#C9D2D8" stroke-width="2"/><rect x="14" y="36" width="36" height="10" fill="#4FA3E0"/><path d="M24 14 q8 -14 16 0" stroke="#C9D2D8" stroke-width="3" fill="none"/>'
		"chocolate":
			s += '<path d="M16 22 H48 L44 58 H20 Z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2"/><rect x="14" y="16" width="36" height="8" rx="3" fill="#5A3A22"/><rect x="20" y="34" width="24" height="10" fill="#C8202A"/><path d="M26 10 q4 -6 0 -10 M38 10 q4 -6 0 -10" stroke="#C9C2B4" stroke-width="2" fill="none"/>'
		"lollipop":
			s += '<rect x="30" y="40" width="4" height="22" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="0.8"/><circle cx="32" cy="24" r="19" fill="#FF7BA3" stroke="#FFFFFF" stroke-width="1.5"/><path d="M32 24 m-12 0 a12 12 0 1 1 24 0 a8 8 0 1 1 -16 0 a4 4 0 1 1 8 0" stroke="#FFFFFF" stroke-width="3.6" fill="none"/><circle cx="25" cy="16" r="4" fill="#FFFFFF" opacity="0.5"/>'
		_:
			s += '<path d="M14 10 L50 10 L46 58 L18 58 Z" fill="#C084FC" stroke="#7E57C2" stroke-width="2"/><rect x="12" y="6" width="40" height="8" rx="3" fill="#7E57C2"/>'
			for p in [[26, 30, "#FFD23F"], [38, 34, "#7CCB5A"], [30, 44, "#E04F5F"], [40, 46, "#4FA3E0"]]:
				s += '<circle cx="%s" cy="%s" r="5" fill="%s" stroke="#FFFFFF" stroke-width="1"/>' % p
			s += '<path d="M14 10 L50 10 L46 58 L18 58 Z" fill="url(#cyl)"/>'
	return tex(64, 64, s)


## Canvas 84x140: the pint of milk Charlotte carries home for Mom: a one-litre carton, held up in her arms (its name is a
## label added by the game).
static func milk_pint() -> ImageTexture:
	var s := _defs() + _carton(6, 8, 72, 126)
	return tex(84, 140, s)


## Canvas 400x130: a high shelf along the wall, stocked with bulk goods: toilet paper and paper towel packs, cases of
## water and pop, cereal boxes, cleaning jugs. `seed_value` changes the mix.
static func high_shelf(seed_value := 1) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + seed_value
	var s := _defs()
	var x := 6.0
	while x < 380.0:
		match rng.randi_range(0, 4):
			0:
				# A pack of toilet-paper rolls in clear plastic.
				s += '<rect x="%.1f" y="52" width="60" height="58" rx="6" fill="#F7FAFC" fill-opacity="0.85" stroke="#B9C9D2" stroke-width="1.5"/>' % x
				for r in 3:
					for k in 2:
						s += '<ellipse cx="%.1f" cy="%.1f" rx="9" ry="10" fill="#FFFFFF" stroke="#C9D2D8" stroke-width="1"/><ellipse cx="%.1f" cy="%.1f" rx="3" ry="4" fill="#E0E4E8"/>' % [x + 12 + r * 17, 70 + k * 22, x + 12 + r * 17, 70 + k * 22]
				s += '<rect x="%.1f" y="80" width="60" height="12" fill="%s" opacity="0.9"/>' % [x, _bright(rng)]
				x += 66.0
			1:
				# Paper-towel rolls standing up.
				for r in 3:
					s += '<rect x="%.1f" y="46" width="22" height="64" rx="4" fill="#FFFFFF" stroke="#C9D2D8" stroke-width="1.2"/><rect x="%.1f" y="62" width="22" height="14" fill="%s"/><rect x="%.1f" y="46" width="22" height="64" rx="4" fill="url(#cyl)"/>' % [x + r * 24, x + r * 24, _bright(rng), x + r * 24]
				x += 76.0
			2:
				# A case of water or pop: a wrapped tray of bottles.
				s += '<rect x="%.1f" y="60" width="86" height="50" rx="4" fill="#DFF0F8" fill-opacity="0.7" stroke="#8FB0C0" stroke-width="1.5"/>' % x
				for k in 6:
					s += _bottle(x + 4 + k * 13.5, 36, 12, 50, ["#4FA3E0", "#FF8A3D", "#7CCB5A"][rng.randi_range(0, 2)], "#FFFFFF")
				s += '<rect x="%.1f" y="82" width="86" height="28" fill="%s" opacity="0.9"/>' % [x, ["#2E86C1", "#E04F5F", "#2E8B57"][rng.randi_range(0, 2)]]
				x += 92.0
			3:
				for k in 3:
					s += _box(x + k * 28, 52 + (k % 2) * 4, 26, 58 - (k % 2) * 4, _bright(rng))
				x += 88.0
			_:
				var c := _bright(rng)
				s += '<path d="M%.1f 110 V62 q0 -8 8 -8 h14 q8 0 8 8 V110 Z" fill="%s" stroke="#00000044" stroke-width="1.2"/><rect x="%.1f" y="76" width="30" height="20" fill="#FFFFFF" opacity="0.85"/><rect x="%.1f" y="46" width="12" height="10" rx="2" fill="#FFFFFF" stroke="#9AA0A6" stroke-width="1"/><path d="M%.1f 60 q-6 8 0 20" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.5"/>' % [x, c, x, x + 9, x + 6]
				s += '<path d="M%.1f 110 V62 q0 -8 8 -8 h14 q8 0 8 8 V110 Z" fill="url(#cyl)"/>' % x
				x += 38.0
	s += '<rect x="0" y="108" width="400" height="12" fill="url(#wood)" stroke="#5E4228" stroke-width="1.5"/><rect x="0" y="108" width="400" height="2.5" fill="#FFFFFF" opacity="0.4"/>'
	for bx in [30.0, 360.0]:
		s += '<path d="M%.1f 120 h12 v6 q0 4 -14 4 l-4 -6 q6 0 6 -4 z" fill="#7E858D"/>' % bx
	s += '<rect x="0" y="120" width="400" height="10" fill="url(#shade)" opacity="0.5"/>'
	return tex(400, 130, s)


## Canvas 170x100: a hanging aisle sign: two chains down from the ceiling to a board with a white arrow, in `color`.
## The words are a label in the game.
static func hanging_sign(color := "#C8202A") -> ImageTexture:
	var s := _defs()
	for x in [26, 144]:
		s += '<path d="M%d 0 V44" stroke="#7E858D" stroke-width="2" stroke-dasharray="3 2"/><circle cx="%d" cy="2" r="3" fill="#5E656C"/>' % [x, x]
	s += '<rect x="4" y="42" width="162" height="50" rx="6" fill="%s" stroke="#00000066" stroke-width="2"/>' % color
	s += '<rect x="8" y="45" width="154" height="14" rx="5" fill="#FFFFFF" opacity="0.25"/>'
	s += '<rect x="4" y="42" width="162" height="50" rx="6" fill="url(#cyl)" opacity="0.4"/>'
	s += '<path d="M140 74 h-18 m8 -7 l-8 7 l8 7" stroke="#FFFFFF" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
	return tex(170, 100, s)


## Canvas 80x40: an emergency exit sign: a lit green box with the running figure and an arrow.
static func exit_sign() -> ImageTexture:
	var s := _defs()
	s += '<rect x="2" y="2" width="76" height="34" rx="4" fill="#1E8E4E" stroke="#0F5A30" stroke-width="2"/><rect x="5" y="5" width="70" height="10" rx="3" fill="#FFFFFF" opacity="0.25"/>'
	s += '<circle cx="24" cy="12" r="3.4" fill="#FFFFFF"/><path d="M24 15 l-4 9 M24 15 l5 8 l7 1 M24 18 l-8 2 M24 18 l8 -3 M20 24 l-5 8 M26 23 l3 9" stroke="#FFFFFF" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
	s += '<path d="M66 20 h-16 m6 -6 l-6 6 l6 6" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
	return tex(80, 40, s)


## Canvas 70x100: a yellow "wet floor" A-frame sign with the slipping figure.
static func wet_floor_sign() -> ImageTexture:
	var s := _defs()
	s += '<ellipse cx="35" cy="96" rx="30" ry="4" fill="#000000" opacity="0.2"/>'
	s += '<path d="M8 96 L18 8 H52 L62 96 Z" fill="#FFD23F" stroke="#B88A10" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M18 8 H52 L56 40 L14 40 Z" fill="#FFFFFF" opacity="0.28"/>'
	s += '<path d="M35 20 m-2 0 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0 M33 26 l-6 18 M35 26 l8 8 l6 2 M33 32 l-8 2 M30 44 l-8 6 M30 44 l8 10" stroke="#2B2B2B" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
	s += '<path d="M20 70 q7 -6 14 0 t14 0" stroke="#2B2B2B" stroke-width="2.6" fill="none"/><path d="M22 80 q6 -5 12 0 t12 0" stroke="#2B2B2B" stroke-width="2" fill="none"/>'
	return tex(70, 100, s)


## Canvas 60x40: a ceiling security camera dome (its blinking light is drawn by the scene).
static func camera_dome() -> ImageTexture:
	var s := _defs()
	s += '<rect x="6" y="0" width="48" height="8" fill="#E8EDF2" stroke="#9AA3AC" stroke-width="1.5"/><path d="M8 8 a22 22 0 0 0 44 0 z" fill="#2A2F36" stroke="#14181D" stroke-width="2"/>'
	s += '<path d="M14 10 a16 16 0 0 0 20 12" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.5" stroke-linecap="round"/><circle cx="30" cy="20" r="6" fill="#0F1318"/><circle cx="28" cy="18" r="2" fill="#7FD4F0" opacity="0.8"/>'
	return tex(60, 40, s)


## Canvas 44x120: a red fire extinguisher on a wall bracket, with its gauge and hose.
static func fire_extinguisher() -> ImageTexture:
	var s := _defs()
	s += '<rect x="4" y="20" width="36" height="6" fill="#4E555B"/><rect x="4" y="76" width="36" height="6" fill="#4E555B"/>'
	s += '<path d="M12 112 V36 q0 -10 10 -10 q10 0 10 10 V112 q0 6 -10 6 q-10 0 -10 -6 z" fill="#D8262E" stroke="#8E1A20" stroke-width="2"/>'
	s += '<path d="M12 112 V36 q0 -10 10 -10 q10 0 10 10 V112 q0 6 -10 6 q-10 0 -10 -6 z" fill="url(#cyl)"/>'
	s += '<rect x="14" y="58" width="16" height="22" fill="#F4F2EC"/><path d="M22 4 v14 h14 v-4 h-8 v-6 z" fill="#2B2B2B"/><rect x="16" y="14" width="12" height="8" rx="2" fill="#2B2B2B"/><circle cx="22" cy="40" r="5" fill="#F4F2EC" stroke="#4E555B" stroke-width="1.5"/><path d="M36 14 q6 14 -2 30" stroke="#2B2B2B" stroke-width="2.4" fill="none"/>'
	return tex(44, 120, s)


## Canvas 170x130: a cork bulletin board with flyers, tear-off tabs, a business card and the neighbourhood's lost-cat
## poster for Pistache.
static func bulletin_board() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var s := _defs()
	s += '<rect x="0" y="0" width="170" height="130" rx="4" fill="url(#wood)" stroke="#5E4228" stroke-width="2"/><rect x="8" y="8" width="154" height="114" fill="#C9955E" stroke="#8A6238" stroke-width="1.5"/>'
	for i in 90:
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" opacity="0.5"/>' % [10 + rng.randf() * 150, 10 + rng.randf() * 110, 0.8 + rng.randf() * 1.2, ["#A8743E", "#DDB47E", "#8A6238"][rng.randi_range(0, 2)]]
	# The lost-cat poster.
	s += '<rect x="14" y="14" width="46" height="62" fill="#FBF8F0" stroke="#D6CFC0" stroke-width="1" transform="rotate(-3 37 45)"/>'
	s += '<rect x="20" y="20" width="34" height="8" fill="#D0303A" transform="rotate(-3 37 24)"/><circle cx="37" cy="46" r="11" fill="#9AA0A8" stroke="#5E646C" stroke-width="1" transform="rotate(-3 37 46)"/><path d="M28 38 l2 -9 l6 6 M46 38 l-2 -9 l-6 6" fill="#9AA0A8" stroke="#5E646C" stroke-width="1"/><circle cx="33" cy="46" r="1.5" fill="#2B2B2B"/><circle cx="41" cy="46" r="1.5" fill="#2B2B2B"/><path d="M30 52 q7 5 14 0" stroke="#2E86C1" stroke-width="2.4" fill="none"/>'
	# Flyers with tear-off tabs.
	for f in [[70, 14, 40, 56, "#FFE066"], [116, 18, 38, 48, "#BFE3F0"], [74, 78, 36, 38, "#F7C6D4"], [118, 74, 36, 44, "#D6EFC9"]]:
		s += '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="#00000033" stroke-width="1"/>' % [f[0], f[1], f[2], f[3], f[4]]
		s += '<rect x="%d" y="%d" width="%d" height="7" fill="#2B2B2B" opacity="0.7"/>' % [f[0] + 4, f[1] + 5, f[2] - 8]
		for k in 3:
			s += '<rect x="%d" y="%d" width="%d" height="2.2" fill="#2B2B2B" opacity="0.4"/>' % [f[0] + 4, f[1] + 17 + k * 6, f[2] - 10 - k * 4]
		for k in 5:
			s += '<rect x="%d" y="%d" width="%d" height="9" fill="%s" stroke="#00000022" stroke-width="0.6"/>' % [f[0] + 2 + k * (f[2] - 4) / 5, f[1] + f[3] - 10, (f[2] - 4) / 5 - 1, f[4]]
		s += '<circle cx="%d" cy="%d" r="2.6" fill="#E04F5F" stroke="#8E1A20" stroke-width="0.8"/>' % [f[0] + f[2] / 2, f[1] + 2]
	s += '<rect x="22" y="88" width="30" height="18" fill="#FFFFFF" stroke="#C9C2B4" stroke-width="1" transform="rotate(4 37 97)"/><rect x="26" y="93" width="16" height="2.4" fill="#2B2B2B" opacity="0.6" transform="rotate(4 37 97)"/>'
	s += '<circle cx="37" cy="88" r="2.6" fill="#4FA3E0" stroke="#1D5E96" stroke-width="0.8"/><circle cx="37" cy="16" r="2.6" fill="#7CCB5A" stroke="#2E7A2A" stroke-width="0.8"/>'
	return tex(170, 130, s)


## Canvas 100x120: a stack of red plastic shopping baskets on the floor.
static func baskets_stack() -> ImageTexture:
	var s := _defs()
	s += '<ellipse cx="50" cy="116" rx="46" ry="4" fill="#000000" opacity="0.2"/>'
	for i in 4:
		var y := 84.0 - i * 18.0
		s += '<path d="M8 %.1f h84 l-8 34 h-68 z" fill="#D8262E" stroke="#8E1A20" stroke-width="2" stroke-linejoin="round"/>' % (y - 2)
		s += '<rect x="6" y="%.1f" width="88" height="7" rx="3" fill="#E8484F" stroke="#8E1A20" stroke-width="1.5"/>' % (y - 6)
		for k in 6:
			s += '<rect x="%d" y="%.1f" width="5" height="14" rx="2" fill="#8E1A20" opacity="0.5"/>' % [16 + k * 13, y + 6]
	s += '<path d="M10 24 q40 -26 80 0" stroke="#8E1A20" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M10 24 q40 -26 80 0" stroke="#E8484F" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
	return tex(100, 120, s)


## Canvas 140x28: a recessed fluorescent panel in the suspended ceiling: a frosted prismatic lens in a white frame.
static func panel_light() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="140" height="28" fill="#E4E7E4" stroke="#B5B8B4" stroke-width="1.5"/>'
	s += '<rect x="6" y="5" width="128" height="20" fill="#FBFFFF" stroke="#D5D9D6" stroke-width="1"/>'
	for k in range(10, 130, 6):
		s += '<path d="M%d 5 V25" stroke="#E4EBEA" stroke-width="1.6"/>' % k
	s += '<rect x="6" y="5" width="128" height="8" fill="#FFFFFF" opacity="0.8"/>'
	return tex(140, 28, s)
