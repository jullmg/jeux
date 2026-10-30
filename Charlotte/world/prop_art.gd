class_name PropArt
extends RefCounted
## Street props drawn as SVG at runtime: autumn trees, cars, bikes, racks, lampposts, hydrants, leaves.

const TREE_PALETTES := [
	["#C0392B", "#D9542E", "#A93226", "#E67E22", "#B03A2E"],
	["#E67E22", "#D35400", "#F39C12", "#E59866", "#CA6F1E"],
	["#F1C40F", "#E5B33A", "#D4AC0D", "#F7DC6F", "#E8A33D"],
	["#E67E22", "#C0392B", "#F1C40F", "#9BAE4A", "#D35400"],
]
const CAR_COLORS := ["#C0392B", "#2E4A7A", "#E8E6E1", "#2B2B2B", "#7F8C8D", "#1F6E5C", "#D4A017", "#5B2C6F", "#A9CCE3"]
const BIKE_COLORS := ["#E74C3C", "#3498DB", "#1ABC9C", "#F1C40F", "#2C3E50", "#E67E22", "#9B59B6", "#ECF0F1"]


static func tex(svg: String, raster := 1.0) -> ImageTexture:
	var img := Image.new()
	img.load_svg_from_string(svg, raster)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _svg(w: float, h: float, body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body]


static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)


static func _pick(rng: RandomNumberGenerator, items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)]


# Canvas 380x780, trunk base at (190, 780). Light comes from the upper right.
static func tree(rng: RandomNumberGenerator) -> ImageTexture:
	var pal: Array = _pick(rng, TREE_PALETTES)
	var s := '<path d="M172 780 C174 700 168 600 176 520 C178 470 160 430 128 392 L142 382 C168 410 182 436 188 466 C196 428 220 398 254 378 L264 392 C234 414 210 450 204 520 C200 600 208 700 212 780 Z" fill="#6E5A4C" stroke="#4A3A30" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M184 760 C182 700 186 640 182 580 M196 740 C198 680 194 620 198 560" stroke="#4A3A30" stroke-width="2.5" fill="none" stroke-linecap="round"/>'
	s += '<path d="M204 770 C202 700 206 620 200 540" stroke="#8C7664" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.7"/>'
	var blobs := []
	for i in 19:
		var a := rng.randf_range(0.0, TAU)
		var d := sqrt(rng.randf())
		blobs.append([190.0 + cos(a) * d * 128.0, 250.0 + sin(a) * d * 150.0, rng.randf_range(48.0, 74.0), _pick(rng, pal)])
	blobs.sort_custom(func(a, b): return a[1] < b[1])
	for b in blobs:
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [b[0] - 10, b[1] + 14, b[2], _hex(Color(b[3]).darkened(0.35))]
	for b in blobs:
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [b[0], b[1], b[2], b[3]]
	for b in blobs:
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" opacity="0.75"/>' % [b[0] + b[2] * 0.3, b[1] - b[2] * 0.35, b[2] * 0.5, _hex(Color(b[3]).lightened(0.28))]
	for i in 150:
		var a := rng.randf_range(0.0, TAU)
		var d := sqrt(rng.randf())
		var x := 190.0 + cos(a) * d * 175.0
		var y := 250.0 + sin(a) * d * 195.0
		s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="3" fill="%s" transform="rotate(%d %.1f %.1f)"/>' % [
			x, y, _hex(Color(_pick(rng, pal)).lightened(rng.randf_range(-0.2, 0.25))), rng.randi_range(0, 180), x, y]
	return tex(_svg(380, 780, s))


# Side view facing right, canvas 440x150; wheels are separate sprites at (100,128) and (340,128).
static func car(rng: RandomNumberGenerator, kind: String) -> ImageTexture:
	var c := Color(_pick(rng, CAR_COLORS))
	var body := _hex(c)
	var dark := _hex(c.darkened(0.3))
	var light := _hex(c.lightened(0.3))
	var shape := ""
	var windows := ""
	match kind:
		"hatch":
			shape = "M20 118 Q16 92 30 78 Q46 52 96 46 H282 Q322 48 358 80 L410 88 Q430 94 430 112 L428 122 Q426 128 416 128 H376 A36 36 0 0 0 304 128 H136 A36 36 0 0 0 64 128 H30 Q20 128 20 118 Z"
			windows = "M44 82 Q58 58 100 54 H246 V82 Z M256 54 H284 Q318 56 346 82 H256 Z"
		"suv":
			shape = "M18 116 Q14 70 28 46 Q36 30 70 28 H300 Q330 30 360 66 L412 76 Q432 84 432 106 L430 120 Q428 128 418 128 H376 A36 36 0 0 0 304 128 H136 A36 36 0 0 0 64 128 H28 Q18 128 18 116 Z"
			windows = "M34 70 Q40 40 74 38 H238 V70 Z M248 38 H296 Q322 40 348 70 H248 Z"
		_:
			shape = "M18 118 Q14 96 30 90 L110 80 Q150 42 206 38 H290 Q330 40 366 78 L410 86 Q430 92 430 112 L428 122 Q426 128 416 128 H376 A36 36 0 0 0 304 128 H136 A36 36 0 0 0 64 128 H28 Q18 128 18 118 Z"
			windows = "M122 80 Q156 50 206 48 H246 V80 Z M256 48 H288 Q322 50 352 80 H256 Z"
	var s := '<defs><linearGradient id="win" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D8ECF4"/><stop offset="1" stop-color="#5C7A8E"/></linearGradient>'
	s += '<linearGradient id="paint" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="0.55" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>' % [light, body, dark]
	s += '<ellipse cx="220" cy="140" rx="206" ry="10" fill="#000000" opacity="0.28"/>'
	s += '<path d="%s" fill="url(#paint)" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [shape, dark]
	s += '<path d="%s" fill="url(#win)" stroke="#2B2B2B" stroke-width="2.5" stroke-linejoin="round"/>' % windows
	s += '<path d="M150 56 L180 50 L140 78 L120 78 Z" fill="#FFFFFF" opacity="0.35"/>'
	s += '<path d="M250 84 V124 M150 86 V122" stroke="%s" stroke-width="2" opacity="0.8"/>' % dark
	s += '<rect x="200" y="94" width="22" height="5" rx="2" fill="%s"/><rect x="290" y="94" width="22" height="5" rx="2" fill="%s"/>' % [dark, dark]
	s += '<path d="M24 102 H420" stroke="#FFFFFF" stroke-width="2" opacity="0.25"/>'
	s += '<path d="M404 94 Q424 96 426 106 L404 106 Z" fill="#FFF3C4" stroke="#B0A070" stroke-width="1.5"/>'
	s += '<path d="M20 96 L34 94 L34 108 L18 108 Z" fill="#E74C3C" stroke="#922B21" stroke-width="1.5"/>'
	s += '<rect x="14" y="112" width="34" height="9" rx="4" fill="#4A4A4A"/><rect x="398" y="112" width="34" height="9" rx="4" fill="#4A4A4A"/>'
	s += '<path d="M346 80 l16 -10 l6 10 z" fill="%s" stroke="#2B2B2B" stroke-width="1.5"/>' % body
	for wx in [100.0, 340.0]:
		s += '<circle cx="%s" cy="128" r="38" fill="#1E1E1E"/>' % wx
	return tex(_svg(440, 150, s))


static func wheel() -> ImageTexture:
	var s := '<circle cx="36" cy="36" r="34" fill="#2B2B2B"/><circle cx="36" cy="36" r="31" fill="none" stroke="#3E3E3E" stroke-width="3"/>'
	s += '<circle cx="36" cy="36" r="21" fill="#C8CCD0" stroke="#8E9399" stroke-width="2"/>'
	for i in 5:
		var a := TAU * i / 5.0
		s += '<path d="M36 36 L%.1f %.1f" stroke="#8E9399" stroke-width="5" stroke-linecap="round"/>' % [36 + cos(a) * 18, 36 + sin(a) * 18]
	s += '<circle cx="36" cy="36" r="6" fill="#6E747A"/>'
	return tex(_svg(72, 72, s))


# Canvas 150x92, ground at y 90.
static func bike(rng: RandomNumberGenerator) -> ImageTexture:
	var col: String = _pick(rng, BIKE_COLORS)
	var s := ""
	for wx in [32.0, 118.0]:
		s += '<circle cx="%s" cy="62" r="26" fill="none" stroke="#2B2B2B" stroke-width="4.5"/>' % wx
		s += '<circle cx="%s" cy="62" r="22" fill="none" stroke="#B0B4B8" stroke-width="1.5"/>' % wx
		for i in 8:
			var a := TAU * i / 8.0
			s += '<path d="M%s 62 l%.1f %.1f" stroke="#B0B4B8" stroke-width="1"/>' % [wx, cos(a) * 22, sin(a) * 22]
	var st := 'stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"' % col
	s += '<path d="M32 62 L72 64 L62 28 Z M62 30 L102 28 L72 64 M102 28 L118 62" %s/>' % st
	s += '<path d="M100 26 L104 14 L116 12" stroke="#2B2B2B" stroke-width="4" fill="none" stroke-linecap="round"/>'
	s += '<path d="M50 22 Q60 16 72 22 Z" fill="#2B2B2B" stroke="#2B2B2B" stroke-width="4" stroke-linejoin="round"/>'
	s += '<circle cx="72" cy="64" r="7" fill="none" stroke="#555555" stroke-width="2"/>'
	if rng.randf() < 0.4:
		s += '<path d="M106 18 h26 l-4 18 h-20 z" fill="#C49A6C" stroke="#8A6A44" stroke-width="2"/>'
		s += '<circle cx="114" cy="16" r="5" fill="#F28C28"/><circle cx="124" cy="15" r="5" fill="#FFD23F"/>'
	return tex(_svg(150, 92, s))


# Canvas 220x92: three Montreal-style hoops, ground at y 90.
static func rack() -> ImageTexture:
	var s := ""
	for x in [20.0, 90.0, 160.0]:
		s += '<path d="M%s 90 V40 Q%s 16 %s 16 Q%s 16 %s 40 V90" stroke="#5E6266" stroke-width="7" fill="none"/>' % [x, x, x + 22, x + 44, x + 44]
		s += '<path d="M%s 88 V42 Q%s 20 %s 20" stroke="#9AA0A6" stroke-width="2" fill="none"/>' % [x + 2, x + 2, x + 22]
	return tex(_svg(220, 92, s))


# Canvas 150x520, ground at y 518; lamp head on the left side over the street.
static func lamppost() -> ImageTexture:
	var s := '<rect x="96" y="40" width="10" height="470" fill="#6B7075" stroke="#4A4E52" stroke-width="2"/>'
	s += '<rect x="90" y="488" width="22" height="30" rx="3" fill="#5A5F63"/>'
	s += '<path d="M101 44 Q101 14 60 14 L30 16" stroke="#6B7075" stroke-width="8" fill="none" stroke-linecap="round"/>'
	s += '<ellipse cx="30" cy="20" rx="26" ry="10" fill="#7C8186" stroke="#4A4E52" stroke-width="2"/>'
	s += '<ellipse cx="30" cy="26" rx="18" ry="4" fill="#FFF1C9"/>'
	s += '<rect x="96" y="150" width="10" height="4" fill="#4A4E52"/><rect x="96" y="320" width="10" height="4" fill="#4A4E52"/>'
	return tex(_svg(150, 520, s))


# Canvas 60x84, ground at y 82.
static func hydrant() -> ImageTexture:
	var s := '<ellipse cx="30" cy="80" rx="22" ry="4" fill="#000000" opacity="0.2"/>'
	s += '<rect x="16" y="28" width="28" height="50" rx="6" fill="#C0392B" stroke="#7B241C" stroke-width="2.5"/>'
	s += '<path d="M14 30 Q30 4 46 30 Z" fill="#E8E6E1" stroke="#9A9890" stroke-width="2.5"/>'
	s += '<rect x="26" y="4" width="8" height="10" rx="2" fill="#E8E6E1" stroke="#9A9890" stroke-width="2"/>'
	s += '<rect x="4" y="42" width="14" height="12" rx="3" fill="#E8E6E1" stroke="#9A9890" stroke-width="2"/>'
	s += '<rect x="42" y="42" width="14" height="12" rx="3" fill="#E8E6E1" stroke="#9A9890" stroke-width="2"/>'
	s += '<rect x="12" y="74" width="36" height="8" rx="2" fill="#7B241C"/>'
	s += '<path d="M22 34 V70" stroke="#FFFFFF" stroke-width="3" opacity="0.3" stroke-linecap="round"/>'
	return tex(_svg(60, 84, s))


static func leaf() -> ImageTexture:
	var s := '<path d="M2 8 Q8 0 20 2 Q22 8 16 13 Q6 15 2 8 Z" fill="#FFFFFF"/><path d="M3 8 L18 4" stroke="#DDDDDD" stroke-width="1"/>'
	return tex(_svg(24, 16, s))
