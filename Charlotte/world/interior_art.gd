class_name InteriorArt
extends RefCounted
## Furniture and fixtures of Charlotte's flat, drawn as SVG at runtime (from the reference photos in
## reference/charlotte_house_inside). Each function documents its canvas; "floor" is the bottom edge.

const OAK := "#9A5E2C"
const OAK_DARK := "#5E3517"
const OAK_LIGHT := "#C08049"
const TRIM := "#F4F1EA"
const TRIM_DARK := "#C9C2B4"
const LINE := "#4A3426"


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return PropArt.tex('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body])


static func _defs() -> String:
	return ('<defs>'
		+ '<linearGradient id="frost" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F6F6"/><stop offset="0.5" stop-color="#DCE3E6"/><stop offset="1" stop-color="#C9D3D8"/></linearGradient>'
		+ '<linearGradient id="oak" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8A5226"/><stop offset="0.5" stop-color="#A9693A"/><stop offset="1" stop-color="#874F24"/></linearGradient>'
		+ '<linearGradient id="velvet" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DDA640"/><stop offset="1" stop-color="#B07A1E"/></linearGradient>'
		+ '<radialGradient id="globe" cx="0.4" cy="0.35"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.6" stop-color="#FFF4D6"/><stop offset="1" stop-color="#F2D9A0"/></radialGradient>'
		+ '<linearGradient id="outside" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BFD8E8"/><stop offset="0.6" stop-color="#9DB98C"/><stop offset="1" stop-color="#7E8F6A"/></linearGradient>'
		+ '</defs>')


static func _grain(x: float, y: float, w: float, h: float, rng: RandomNumberGenerator, n := 6) -> String:
	var s := ""
	for i in n:
		var gx := x + w * (i + 0.5) / n + rng.randf_range(-4, 4)
		s += '<path d="M%.1f %.1f q%.1f %.1f 0 %.1f" stroke="%s" stroke-width="1.3" fill="none" opacity="0.35"/>' % [gx, y + 6, rng.randf_range(-8, 8), h * 0.5, h - 12, OAK_DARK]
	return s


# ── Vestibule ────────────────────────────────────────────────

## Canvas 330x480: white front door with frosted glass, sidelights and transom. Floor at y 480.
static func front_door() -> ImageTexture:
	var s := _defs()
	s += '<rect x="4" y="4" width="322" height="476" fill="%s" stroke="%s" stroke-width="3"/>' % [TRIM, TRIM_DARK]
	s += '<rect x="20" y="20" width="290" height="70" fill="url(#frost)" stroke="%s" stroke-width="3"/>' % TRIM_DARK
	for x in [20.0, 266.0]:
		s += '<rect x="%s" y="104" width="44" height="366" fill="url(#frost)" stroke="%s" stroke-width="3"/>' % [x, TRIM_DARK]
	s += '<rect x="80" y="104" width="170" height="372" fill="#FBFAF7" stroke="%s" stroke-width="3"/>' % TRIM_DARK
	s += '<rect x="102" y="128" width="126" height="200" fill="url(#frost)" stroke="%s" stroke-width="3"/>' % TRIM_DARK
	s += '<path d="M112 140 L150 140 L118 230 Z" fill="#FFFFFF" opacity="0.6"/>'
	s += '<rect x="102" y="356" width="126" height="90" fill="none" stroke="%s" stroke-width="2.5"/>' % TRIM_DARK
	s += '<circle cx="218" cy="300" r="7" fill="#2B2B2B"/><circle cx="218" cy="326" r="5" fill="#2B2B2B"/>'
	s += '<rect x="76" y="100" width="4" height="376" fill="#000000" opacity="0.08"/>'
	return tex(330, 480, s)


## Canvas 300x330: wall shelf with brackets and hooks; helmet and basket on top; satchel, pink bag, raincoat.
static func coat_shelf() -> ImageTexture:
	var s := '<path d="M10 30 H290 V46 H10 Z" fill="%s" stroke="%s" stroke-width="3"/>' % [OAK_LIGHT, OAK_DARK]
	for x in [40.0, 250.0]:
		s += '<path d="M%s 46 h14 v12 q-2 30 -26 44 l-6 -8 q16 -14 18 -36 z" fill="%s" stroke="%s" stroke-width="2.5"/>' % [x, OAK_LIGHT, OAK_DARK]
	s += '<rect x="24" y="62" width="252" height="10" fill="%s" stroke="%s" stroke-width="2"/>' % [OAK_LIGHT, OAK_DARK]
	s += '<path d="M40 30 Q40 -2 82 -2 Q122 -2 122 30 Z" fill="#232323" stroke="#000000" stroke-width="2"/>'
	s += '<path d="M60 10 h44 M54 20 h56" stroke="#3E3E3E" stroke-width="3"/>'
	s += '<rect x="140" y="4" width="70" height="26" fill="none" stroke="#3A3A3A" stroke-width="2.5"/>'
	for x in range(146, 208, 10):
		s += '<path d="M%d 4 v26" stroke="#3A3A3A" stroke-width="1.5"/>' % x
	for x in [60.0, 110.0, 160.0, 210.0]:
		s += '<path d="M%s 70 v10 q0 6 6 6" stroke="#7A7A7A" stroke-width="3" fill="none"/>' % x
	# Brown satchel with a long strap.
	s += '<path d="M58 82 Q40 150 52 230 M66 82 Q86 150 80 230" stroke="#7A4A26" stroke-width="5" fill="none"/>'
	s += '<path d="M38 150 Q36 132 52 128 H86 Q102 132 100 150 L104 216 Q70 228 36 216 Z" fill="#8E5A30" stroke="#5A3418" stroke-width="3"/>'
	s += '<path d="M40 160 H100" stroke="#5A3418" stroke-width="2"/><rect x="62" y="166" width="14" height="10" fill="#C9A35A"/>'
	# Pink bag.
	s += '<path d="M108 84 Q104 120 112 132 M120 84 Q128 116 122 132" stroke="#C97B9A" stroke-width="3" fill="none"/>'
	s += '<path d="M100 132 Q114 118 134 132 Q142 160 122 172 Q100 170 100 132 Z" fill="#F2B6CF" stroke="#B5647F" stroke-width="2.5"/>'
	# Mustard raincoat.
	s += '<path d="M158 84 Q140 96 138 130 L132 250 Q160 262 196 250 L188 128 Q186 96 166 84 Z" fill="#E0A63A" stroke="#9C6C14" stroke-width="3"/>'
	s += '<path d="M162 96 V244 M146 150 Q140 190 142 236" stroke="#9C6C14" stroke-width="2" fill="none"/>'
	s += '<path d="M138 130 Q126 170 130 220" stroke="#C48A24" stroke-width="10" fill="none" stroke-linecap="round"/>'
	return tex(300, 330, s)


## Canvas w x h: white cast-iron radiator. Floor at the bottom.
static func radiator(w: float, h: float) -> ImageTexture:
	var s := '<rect x="2" y="%s" width="%s" height="8" fill="#DCD8D0"/>' % [h - 8, w - 4]
	var x := 4.0
	while x < w - 14:
		s += '<rect x="%s" y="6" width="12" height="%s" rx="6" fill="#F4F2EC" stroke="#B9B4AA" stroke-width="2"/>' % [x, h - 16]
		x += 13.0
	s += '<rect x="2" y="%s" width="%s" height="6" fill="#B9B4AA"/>' % [h * 0.18, w - 4]
	s += '<rect x="2" y="%s" width="%s" height="6" fill="#B9B4AA"/>' % [h * 0.82 - 6, w - 4]
	return tex(w, h, s)


## Canvas 110x130: yellow backpack slumped on the floor.
static func backpack() -> ImageTexture:
	var s := '<path d="M14 120 Q8 40 30 20 Q55 4 80 20 Q102 40 96 120 Z" fill="#F2C12E" stroke="#A8800E" stroke-width="3"/>'
	s += '<path d="M26 64 Q55 54 84 64 L86 104 Q55 112 24 104 Z" fill="#E5AE1C" stroke="#A8800E" stroke-width="2.5"/>'
	s += '<path d="M30 80 H80" stroke="#C9CCCF" stroke-width="5"/><path d="M40 28 Q55 18 70 28" stroke="#2B2B2B" stroke-width="4" fill="none"/>'
	s += '<rect x="10" y="118" width="90" height="8" rx="4" fill="#2B2B2B"/>'
	return tex(110, 130, s)


## Canvas 150x40: a pair of white sneakers and a red tuque.
static func floor_clutter() -> ImageTexture:
	var s := ""
	for x in [4.0, 44.0]:
		s += '<path d="M%s 36 Q%s 20 %s 18 L%s 16 Q%s 22 %s 36 Z" fill="#F4F4F2" stroke="#9A9A9A" stroke-width="2"/>' % [x, x, x + 8, x + 22, x + 36, x + 36]
		s += '<path d="M%s 34 H%s" stroke="#C9C9C9" stroke-width="3"/>' % [x + 2, x + 34]
	s += '<path d="M96 36 Q96 10 118 10 Q140 10 140 36 Z" fill="#B5442E" stroke="#7A2A1A" stroke-width="2"/>'
	s += '<path d="M96 30 H140" stroke="#8E3422" stroke-width="5"/>'
	return tex(150, 40, s)


## Canvas 220x500: oak door casing with a frosted transom, the open door folded against the wall.
static func oak_doorway() -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="22" height="500" fill="url(#oak)" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += '<rect x="198" y="0" width="22" height="500" fill="url(#oak)" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += '<rect x="0" y="0" width="220" height="24" fill="url(#oak)" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += '<rect x="22" y="24" width="176" height="64" fill="url(#frost)" stroke="%s" stroke-width="3"/>' % OAK_DARK
	s += '<rect x="0" y="88" width="220" height="14" fill="url(#oak)" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	return tex(220, 500, s)


## Canvas 120x400: oak door panel with ribbed frosted glass (seen open, against the wall).
static func oak_glass_door() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s := _defs()
	s += '<rect x="2" y="2" width="116" height="396" fill="url(#oak)" stroke="%s" stroke-width="3"/>' % OAK_DARK
	s += '<rect x="18" y="22" width="84" height="190" fill="url(#frost)" stroke="%s" stroke-width="3"/>' % OAK_DARK
	for x in range(24, 100, 6):
		s += '<path d="M%d 24 V210" stroke="#FFFFFF" stroke-width="1.5" opacity="0.6"/>' % x
	s += '<rect x="18" y="240" width="84" height="130" fill="none" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += _grain(18, 240, 84, 130, rng, 4)
	s += '<circle cx="104" cy="226" r="5" fill="#C9A35A" stroke="#7A5A20" stroke-width="1.5"/>'
	return tex(120, 400, s)


# ── Salon ────────────────────────────────────────────────────

## Canvas 600x230: mustard velvet sofa with a white throw and pillow. Floor at y 230.
static func sofa() -> ImageTexture:
	var s := _defs()
	s += '<path d="M40 40 Q40 12 70 12 H530 Q560 12 560 40 V150 H40 Z" fill="url(#velvet)" stroke="#8A5E14" stroke-width="3"/>'
	for x in [70.0, 230.0, 390.0]:
		s += '<path d="M%s 30 Q%s 18 %s 18 H%s Q%s 18 %s 30 V120 H%s Z" fill="#D69C34" stroke="#8A5E14" stroke-width="2.5"/>' % [x, x, x + 14, x + 126, x + 140, x + 140, x]
	s += '<path d="M14 100 Q14 80 36 80 H70 Q86 80 86 100 V200 H14 Z" fill="url(#velvet)" stroke="#8A5E14" stroke-width="3"/>'
	s += '<path d="M514 100 Q514 80 536 80 H570 Q590 80 590 100 V200 H514 Z" fill="url(#velvet)" stroke="#8A5E14" stroke-width="3"/>'
	s += '<path d="M70 130 Q70 116 86 116 H514 Q530 116 530 130 V200 H70 Z" fill="#D9A23A" stroke="#8A5E14" stroke-width="3"/>'
	s += '<path d="M300 118 V198" stroke="#8A5E14" stroke-width="2"/>'
	# Velvet sheen on the cushion tops, shadow tucked under the back cushions, piping along the seat front.
	for x in [70.0, 230.0, 390.0]:
		s += '<path d="M%s 28 Q%s 22 %s 22 H%s" stroke="#F2C66A" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/>' % [x + 12, x + 14, x + 30, x + 110]
	s += '<rect x="72" y="118" width="456" height="10" fill="#6E4A10" opacity="0.25"/>'
	s += '<path d="M90 134 H290 M312 134 H512" stroke="#F2C66A" stroke-width="5" stroke-linecap="round" opacity="0.6"/>'
	s += '<path d="M72 196 H528" stroke="#B5801E" stroke-width="3"/>'
	s += '<path d="M20 96 Q22 86 36 86 H64" stroke="#F2C66A" stroke-width="4" fill="none" opacity="0.6"/>'
	s += '<path d="M40 200 H570 V212 H40 Z" fill="#9C6C18"/>'
	for x in [60.0, 540.0]:
		s += '<rect x="%s" y="210" width="12" height="20" fill="#4A3020"/>' % x
	# Throw blanket and pillow.
	s += '<path d="M380 40 Q420 20 460 44 Q480 90 470 150 Q440 170 400 160 Q378 110 380 40 Z" fill="#EDE6DC" stroke="#B5ACA0" stroke-width="2.5"/>'
	s += '<path d="M400 60 Q420 100 412 150 M430 50 Q448 100 440 156" stroke="#C9C0B4" stroke-width="2" fill="none"/>'
	s += '<path d="M490 60 Q520 46 552 60 Q560 90 548 112 Q516 120 492 108 Q482 86 490 60 Z" fill="#FAF8F3" stroke="#C9C2B4" stroke-width="2.5"/>'
	return tex(600, 230, s)


## Canvas 760x90: the salon's faded Persian rug seen in perspective on the floor (rose field, navy medallion,
## cream border with little motifs, worn patches, fringes at both ends).
static func rug() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	# Each band is the trapezoid inset by `i`: the far edge narrower than the near one.
	var band := func(i: float) -> String:
		return "M%.1f %.1f H%.1f L%.1f %.1f H%.1f Z" % [60 + i * 1.4, 4 + i * 0.55, 700 - i * 1.4, 756 - i * 1.9, 86 - i * 0.55, 4 + i * 1.9]
	var s := '<defs><clipPath id="field"><path d="%s"/></clipPath></defs>' % band.call(30.0)
	s += '<path d="%s" fill="#8E3438" stroke="#6A2428" stroke-width="2"/>' % band.call(0.0)
	s += '<path d="%s" fill="#E6D6BC"/>' % band.call(6.0)
	# Little motifs running round the cream border.
	for x in range(80, 700, 22):
		var t := float(x - 80) / 620.0
		s += '<path d="M%.1f 8 l5 3 l-5 3 l-5 -3 z" fill="%s"/>' % [x, "#2F3E66" if x % 44 == 14 else "#B04A50"]
		s += '<path d="M%.1f 79 l6 3.5 l-6 3.5 l-6 -3.5 z" fill="%s"/>' % [lerpf(40.0, 720.0, t), "#2F3E66" if x % 44 == 14 else "#B04A50"]
	s += '<path d="%s" fill="#2F3E66"/>' % band.call(22.0)
	s += '<path d="%s" fill="#C46E78"/>' % band.call(26.0)
	s += '<g clip-path="url(#field)">'
	# Worn, sun-faded patches.
	for i in 7:
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#E2A4AA" opacity="0.35"/>' % [rng.randf_range(120, 640), rng.randf_range(25, 65), rng.randf_range(40, 90), rng.randf_range(6, 14)]
	# Scattered flowers and vines over the field.
	for i in 70:
		var x := rng.randf_range(100, 660)
		var y := rng.randf_range(22, 70)
		match i % 3:
			0:
				s += '<path d="M%.1f %.1f h6 M%.1f %.1f v4" stroke="#2F3E66" stroke-width="1.6"/>' % [x - 3, y, x, y - 2]
			1:
				s += '<circle cx="%.1f" cy="%.1f" r="2" fill="#F1E2C6"/>' % [x, y]
			2:
				s += '<path d="M%.1f %.1f q4 -4 8 0" stroke="#7A2E36" stroke-width="1.5" fill="none"/>' % [x, y]
	# Corner spandrels.
	for c in [[110.0, 22.0, 1.0, 1.0], [650.0, 22.0, -1.0, 1.0], [80.0, 70.0, 1.0, -1.0], [680.0, 70.0, -1.0, -1.0]]:
		s += '<path d="M%.1f %.1f q%.1f 0 %.1f %.1f q%.1f %.1f %.1f %.1f z" fill="#2F3E66" opacity="0.85"/>' % [c[0], c[1], c[2] * 50, c[2] * 60, c[3] * 14, -c[2] * 30, -c[3] * 2, -c[2] * 60, -c[3] * 14]
	s += '</g>'
	# Central medallion with its pendants.
	s += '<path d="M380 18 L480 46 L380 74 L280 46 Z" fill="#2F3E66" stroke="#E6D6BC" stroke-width="2"/>'
	s += '<path d="M380 26 L452 46 L380 66 L308 46 Z" fill="#E6D6BC"/>'
	s += '<path d="M380 32 L428 46 L380 60 L332 46 Z" fill="#B04A50"/>'
	s += '<circle cx="380" cy="46" r="6" fill="#2F3E66"/><circle cx="380" cy="46" r="2.5" fill="#F1E2C6"/>'
	for side in [-1.0, 1.0]:
		s += '<path d="M%.1f 46 l%.1f -7 l0 14 z" fill="#2F3E66"/>' % [380 + side * 100, side * 26]
	# Fringes.
	for x in range(64, 700, 9):
		s += '<path d="M%d 4 v-4" stroke="#EDE3D2" stroke-width="2"/>' % x
	for x in range(10, 752, 10):
		s += '<path d="M%d 86 v4" stroke="#EDE3D2" stroke-width="2"/>' % x
	return tex(760, 90, s)


## Canvas 120x160: framed posters (style 0 line drawing, 1 dark with a glowing mushroom, 2 figure grid).
static func poster(style: int) -> ImageTexture:
	var s := '<rect x="2" y="2" width="116" height="156" fill="#3A3A3A"/>'
	match style:
		0:
			s += '<rect x="8" y="8" width="104" height="144" fill="#F1ECE2"/>'
			s += '<path d="M24 40 h70 M24 60 h50 M24 80 h64 M30 110 q30 -30 60 0" stroke="#8A8478" stroke-width="2" fill="none"/>'
		1:
			s += '<rect x="8" y="8" width="104" height="144" fill="#2E2A26"/>'
			s += '<circle cx="60" cy="70" r="30" fill="#5A4A2E" opacity="0.6"/>'
			s += '<path d="M40 82 Q60 52 80 82 Z" fill="#F2E6C8"/><rect x="56" y="82" width="8" height="26" fill="#E8DCC0"/>'
		_:
			s += '<rect x="8" y="8" width="104" height="144" fill="#EFE9DE"/>'
			for r in 4:
				for c in 3:
					var x := 26.0 + c * 30.0
					var y := 30.0 + r * 32.0
					s += '<path d="M%s %s l6 -10 l6 10 m-6 -10 v-8" stroke="#5A5248" stroke-width="2" fill="none"/>' % [x, y + 10]
	s += '<path d="M8 8 L50 8 L8 70 Z" fill="#FFFFFF" opacity="0.14"/>'
	return tex(120, 160, s)


## Canvas 480x220: walnut dining table with chairs, things on top. Floor at y 220.
static func dining_table() -> ImageTexture:
	var s := '<path d="M30 78 Q30 70 40 70 H440 Q450 70 450 78 V88 H30 Z" fill="#5A3A26" stroke="#2E1C10" stroke-width="3"/>'
	s += '<path d="M40 74 H440" stroke="#8A6448" stroke-width="2.5" opacity="0.8"/><path d="M60 82 q60 -3 120 0 t140 0 t100 0" stroke="#3E2618" stroke-width="1.2" fill="none" opacity="0.6"/>'
	for x in [50.0, 410.0]:
		s += '<path d="M%s 88 h18 l-4 132 h-10 z" fill="#4A2E1C" stroke="#2E1C10" stroke-width="2"/>' % x
	s += '<rect x="60" y="56" width="70" height="14" fill="#F2E3B0" stroke="#B5A270" stroke-width="2"/><rect x="66" y="46" width="60" height="10" fill="#E07A9A"/>'
	s += '<path d="M180 70 l6 -24 h18 l6 24 z" fill="#F4F4F2" stroke="#9A9A9A" stroke-width="2"/>'
	s += '<ellipse cx="260" cy="66" rx="30" ry="5" fill="#FAF8F3" stroke="#B9B4AA" stroke-width="2"/>'
	s += '<path d="M330 70 q20 -20 50 -6 q14 6 4 6 z" fill="#9BD15A" stroke="#5E8A2E" stroke-width="2"/>'
	for x in [110.0, 300.0]:
		s += '<path d="M%s 40 Q%s 30 %s 30 H%s Q%s 30 %s 40 V112 H%s Z" fill="#3E2A1C" stroke="#1E140C" stroke-width="2.5"/>' % [x, x, x + 10, x + 60, x + 70, x + 70, x]
		s += '<rect x="%s" y="112" width="86" height="16" rx="4" fill="#4A3020" stroke="#1E140C" stroke-width="2.5"/>' % (x - 8)
		for lx in [x - 4.0, x + 66.0]:
			s += '<path d="M%s 128 l2 92 h8 l-2 -92 z" fill="#3E2A1C" stroke="#1E140C" stroke-width="1.5"/>' % lx
	return tex(480, 220, s)


## Canvas 200x380: black metal shelving with dishes, jars, plants and books. Floor at y 380.
static func black_shelf() -> ImageTexture:
	var s := '<rect x="6" y="4" width="8" height="376" fill="#1E1E1E"/><rect x="186" y="4" width="8" height="376" fill="#1E1E1E"/>'
	var cols := ["#F2EDE2", "#E8D9B5", "#C9DDE6", "#F2B6CF", "#FFFFFF", "#D9682B"]
	for i in 5:
		var y := 40.0 + i * 72.0
		s += '<rect x="2" y="%s" width="196" height="7" fill="#262626"/>' % y
		var x := 20.0
		var k := i
		while x < 176.0:
			var w := 18.0 + (k * 7) % 14
			var h := 20.0 + (k * 11) % 24
			var col: String = cols[k % cols.size()]
			if (k + i) % 5 == 0:
				s += '<path d="M%s %s q%s -%s %s 0" fill="#5FAE4F" stroke="#3E7E32" stroke-width="2"/>' % [x, y, w / 2, h + 10, w]
			elif (k + i) % 4 == 1:
				s += '<rect x="%s" y="%s" width="8" height="%s" fill="%s" stroke="#3A3A3A" stroke-width="1"/>' % [x, y - h - 6, h + 6, ["#1D4F91", "#E04F5F", "#3E8E5A", "#FFD23F"][k % 4]]
				w = 9.0
			else:
				s += '<path d="M%s %s h%s l-2 -%s h-%s z" fill="%s" stroke="#8A8478" stroke-width="1.5"/>' % [x, y, w, h, w - 4, col]
			x += w + 6.0
			k += 1
	return tex(200, 380, s)


## Canvas 80x60: ceiling medallion seen from the side.
static func medallion() -> ImageTexture:
	var s := '<path d="M2 2 H78 Q74 26 40 30 Q6 26 2 2 Z" fill="#F7F4EE" stroke="#C9C2B4" stroke-width="2"/>'
	s += '<path d="M14 8 Q40 22 66 8" stroke="#D9D2C4" stroke-width="2" fill="none"/>'
	return tex(80, 60, s)


## Canvas 70x70: frosted glass globe lamp.
static func globe() -> ImageTexture:
	var s := _defs() + '<rect x="30" y="0" width="10" height="10" fill="#C9A35A"/><circle cx="35" cy="40" r="28" fill="url(#globe)" stroke="#E2CFA0" stroke-width="2"/>'
	return tex(70, 70, s)


# ── Hallway and kitchen ──────────────────────────────────────

## Canvas 200x260: wall hooks with black puffer jackets.
static func black_coats() -> ImageTexture:
	var s := '<rect x="20" y="10" width="160" height="10" fill="#3A3A3A"/>'
	for x in [40.0, 80.0, 120.0, 160.0]:
		s += '<path d="M%s 20 v12 q0 6 6 6" stroke="#3A3A3A" stroke-width="3" fill="none"/>' % x
	s += '<path d="M44 34 Q24 60 22 120 L28 220 Q70 236 104 220 L102 110 Q98 58 72 34 Z" fill="#2B2B30" stroke="#111114" stroke-width="3"/>'
	for y in [80.0, 120.0, 160.0, 200.0]:
		s += '<path d="M26 %s Q64 %s 102 %s" stroke="#45454C" stroke-width="2.5" fill="none"/>' % [y, y + 8, y]
	s += '<path d="M112 36 Q96 70 98 140 L106 240 Q140 250 166 238 L160 120 Q156 60 134 36 Z" fill="#3A3A40" stroke="#111114" stroke-width="3"/>'
	s += '<path d="M130 40 V234" stroke="#22222A" stroke-width="2"/>'
	return tex(200, 260, s)


## Canvas 220x140: wall-mounted TV.
static func tv() -> ImageTexture:
	var s := '<rect x="4" y="4" width="212" height="126" rx="4" fill="#1A1A1C" stroke="#000000" stroke-width="2"/>'
	s += '<rect x="12" y="12" width="196" height="108" fill="#2A2E36"/><path d="M20 20 L90 20 L30 110 L20 110 Z" fill="#FFFFFF" opacity="0.08"/>'
	s += '<circle cx="196" cy="124" r="2" fill="#E04F5F"/>'
	return tex(220, 140, s)


## Canvas 90x120: blue recycling bin with flattened cardboard.
static func recycling_bin() -> ImageTexture:
	var s := '<path d="M30 6 L64 2 L70 60 L36 64 Z" fill="#C9A26E" stroke="#8A6A40" stroke-width="2"/>'
	s += '<path d="M8 40 H82 L74 118 H16 Z" fill="#2E5FB0" stroke="#1C3C78" stroke-width="3"/>'
	s += '<path d="M8 40 H82 V50 H8 Z" fill="#3A6EC4" stroke="#1C3C78" stroke-width="2"/>'
	s += '<path d="M38 74 l7 -10 l7 10 m-14 4 l-6 10 h12 m10 -14 l6 10 h-12" stroke="#FFFFFF" stroke-width="2.5" fill="none"/>'
	return tex(90, 120, s)


## Canvas 150x430: Charlotte's bedroom door, oak panels with strong grain. The "chacha" sign is added as labels.
static func panel_door() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var s := _defs()
	s += '<rect x="0" y="0" width="150" height="430" fill="url(#oak)" stroke="%s" stroke-width="3"/>' % OAK_DARK
	s += '<rect x="10" y="10" width="130" height="420" fill="#A5663A" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += '<rect x="26" y="30" width="98" height="370" fill="#B07240" stroke="%s" stroke-width="2.5"/>' % OAK_DARK
	s += '<path d="M26 30 l12 12 h74 l12 -12 M26 400 l12 -12 h74 l12 12" stroke="%s" stroke-width="2" fill="none"/>' % OAK_DARK
	for i in 6:
		var cx := 75.0 + rng.randf_range(-16, 16)
		var cy := 120.0 + i * 50.0
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="none" stroke="%s" stroke-width="1.5" opacity="0.4"/>' % [cx, cy, rng.randf_range(10, 30), rng.randf_range(16, 30), OAK_DARK]
	s += _grain(26, 30, 98, 370, rng, 5)
	s += '<circle cx="128" cy="236" r="7" fill="#E8E4D8" stroke="#8A8478" stroke-width="2"/>'
	return tex(150, 430, s)


## Canvas 560x480: the kitchen at the end of the hall: fridge covered in drawings, wood upper cabinet,
## white base cabinets with a black counter (stove, kettle, fruit bowl, utensil rail), the back door with
## a window onto the yard and the wall AC unit above, and a little island with a stool. Floor at y 480.
static func kitchen() -> ImageTexture:
	var s := _defs()
	# Fridge.
	s += '<rect x="4" y="120" width="104" height="356" rx="8" fill="#F2F2EF" stroke="#B9B4AA" stroke-width="3"/>'
	s += '<path d="M4 250 H108" stroke="#B9B4AA" stroke-width="3"/><rect x="92" y="190" width="6" height="44" rx="3" fill="#B9B4AA"/><rect x="92" y="268" width="6" height="60" rx="3" fill="#B9B4AA"/>'
	s += '<path d="M10 126 L40 126 L12 240 Z" fill="#FFFFFF" opacity="0.5"/>'
	for d in [[20, 150, "#F2C12E"], [52, 170, "#7E57C2"], [24, 280, "#F2A7C9"], [58, 300, "#1FB5C4"]]:
		s += '<rect x="%s" y="%s" width="30" height="36" fill="#FFFFFF" stroke="#D9D2C4" stroke-width="1" transform="rotate(-4 %s %s)"/>' % [d[0], d[1], d[0], d[1]]
		s += '<path d="M%s %s q8 -10 16 0 q-8 10 -16 0" fill="%s"/><circle cx="%s" cy="%s" r="3" fill="#E04F5F"/>' % [d[0] + 7, d[1] + 20, d[2], d[0] + 15, d[1] + 2]
	# Upper cabinet.
	s += '<rect x="122" y="40" width="150" height="130" fill="#D6A464" stroke="#8A6234" stroke-width="3"/>'
	for y in range(52, 166, 10):
		s += '<path d="M130 %d H264" stroke="#B98A4E" stroke-width="2"/>' % y
	# Backsplash, utensil rail, counter and base cabinets.
	s += '<rect x="120" y="200" width="180" height="60" fill="#EDEAE3"/>'
	for x in range(120, 300, 20):
		s += '<path d="M%d 200 V260" stroke="#D6D2C8" stroke-width="1.5"/>' % x
	s += '<path d="M120 230 H300" stroke="#D6D2C8" stroke-width="1.5"/>'
	s += '<path d="M140 204 H280" stroke="#9A9A9A" stroke-width="3"/>'
	for u in [[156, "M0 0 v26 M-5 26 h10 v8 h-10 z"], [190, "M0 0 v22 m0 0 q-6 4 0 12 q6 -4 0 -12"], [224, "M0 0 v30"], [256, "M0 0 v20 m-6 0 h12 l-6 12 z"]]:
		s += '<g transform="translate(%s 206)"><path d="%s" stroke="#6E6E6E" stroke-width="2.5" fill="#B9B9B9"/></g>' % [u[0], u[1]]
	s += '<rect x="114" y="260" width="192" height="14" fill="#2E2E30"/>'
	s += '<rect x="120" y="274" width="180" height="202" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2.5"/>'
	for x in [124.0, 212.0]:
		s += '<rect x="%s" y="284" width="84" height="182" fill="none" stroke="#C9C2B4" stroke-width="2"/><rect x="%s" y="300" width="22" height="4" fill="#9A9A9A"/>' % [x, x + 31]
	s += '<rect x="130" y="250" width="70" height="10" fill="#3A3A3A"/><circle cx="148" cy="255" r="3" fill="#6E6E6E"/><circle cx="182" cy="255" r="3" fill="#6E6E6E"/>'
	s += '<path d="M146 250 Q146 226 166 226 Q186 226 186 250 Z" fill="#E04F5F" stroke="#8E1A24" stroke-width="2"/><path d="M186 236 l10 -6" stroke="#8E1A24" stroke-width="3"/><path d="M156 226 q10 -10 20 0" stroke="#2B2B2B" stroke-width="2.5" fill="none"/>'
	s += '<ellipse cx="260" cy="256" rx="26" ry="6" fill="#F4F2EC" stroke="#9A9A9A" stroke-width="1.5"/>'
	for f in [[248, 248, "#E67E22"], [262, 246, "#F1C40F"], [274, 249, "#C0392B"], [256, 240, "#9BD15A"]]:
		s += '<circle cx="%s" cy="%s" r="7" fill="%s"/>' % f
	# Back door with the yard outside, AC unit above.
	s += '<rect x="318" y="30" width="170" height="52" rx="8" fill="#F7F7F5" stroke="#B9B4AA" stroke-width="2.5"/><path d="M332 66 H474" stroke="#B9B4AA" stroke-width="2"/>'
	s += '<rect x="322" y="100" width="164" height="380" fill="#F7F6F2" stroke="#C9C2B4" stroke-width="3"/>'
	s += '<rect x="332" y="104" width="144" height="40" fill="url(#outside)" stroke="#C9C2B4" stroke-width="2"/>'
	s += '<rect x="342" y="160" width="124" height="170" fill="url(#outside)" stroke="#C9C2B4" stroke-width="3"/>'
	s += '<path d="M342 250 H466" stroke="#F7F6F2" stroke-width="5"/><path d="M350 210 h108 M350 226 h108" stroke="#FFFFFF" stroke-width="2"/>'
	s += '<path d="M380 330 v-60 l20 -30 l20 30 v60" fill="#B5603F" opacity="0.5"/>'
	s += '<circle cx="458" cy="350" r="6" fill="#B9B4AA"/>'
	s += '<rect x="342" y="370" width="124" height="90" fill="none" stroke="#C9C2B4" stroke-width="2.5"/>'
	# Little island and stool.
	s += '<rect x="496" y="330" width="60" height="146" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2.5"/><rect x="490" y="318" width="70" height="14" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
	s += '<path d="M500 390 h40 M506 390 l-8 86 M534 390 l8 86" stroke="#8A6A40" stroke-width="4" fill="none"/><ellipse cx="520" cy="388" rx="24" ry="6" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
	s += '<path d="M500 318 v-16 h18 v16" fill="#F2EDE2" stroke="#9A9A9A" stroke-width="2"/>'
	return tex(560, 480, s)


## Canvas w x 70: paper bunting with pastel flags hung across the wall.
static func bunting(w: float) -> ImageTexture:
	var cols := ["#F2A7C9", "#FFD23F", "#A5D6A7", "#9DB9E8", "#FFB38A", "#D9C6E6"]
	var s := '<path d="M2 10 Q%s 40 %s 10" stroke="#B9B4AA" stroke-width="2" fill="none"/>' % [w / 2.0, w - 2.0]
	var n := int(w / 46.0)
	for i in n:
		var t := (i + 0.5) / n
		var x := t * w
		var y := 10.0 + 4.0 * t * (1.0 - t) * 30.0
		s += '<path d="M%s %s L%s %s L%s %s Z" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/>' % [x - 16, y, x + 16, y, x, y + 34, cols[i % cols.size()]]
	return tex(w, 70, s)


# ── Charlotte's bedroom ──────────────────────────────────────

## Canvas 560x300: white metal bed with a pink duvet, lilac pillow and a plush bunny. Floor at y 300.
static func bed() -> ImageTexture:
	var s := '<path d="M20 300 V60 Q20 20 70 20 Q120 20 120 60 V300" fill="none" stroke="#F4F2EC" stroke-width="10"/>'
	s += '<path d="M20 300 V60 Q20 20 70 20 Q120 20 120 60 V300" fill="none" stroke="#C9C2B4" stroke-width="2"/>'
	for x in [44.0, 70.0, 96.0]:
		s += '<path d="M%s 50 V190" stroke="#F4F2EC" stroke-width="6"/><circle cx="%s" cy="90" r="5" fill="#2B2B2B"/>' % [x, x]
	s += '<path d="M24 120 H116 M24 190 H116" stroke="#F4F2EC" stroke-width="7"/>'
	s += '<path d="M30 184 H540 V224 H30 Z" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2"/>'
	s += '<path d="M52 130 Q50 104 80 104 H190 Q214 104 212 132 Q212 160 190 162 H80 Q52 162 52 130 Z" fill="#D9C6E6" stroke="#9E86B5" stroke-width="2.5"/>'
	s += '<path d="M60 170 Q90 140 200 150 Q380 136 540 150 L546 214 Q300 236 60 214 Z" fill="#F2A7B9" stroke="#C26A84" stroke-width="3"/>'
	s += '<path d="M220 158 Q300 176 360 160 M400 152 Q450 174 520 158 M140 190 Q240 206 330 192" stroke="#E08AA2" stroke-width="2.5" fill="none"/>'
	s += '<path d="M60 206 Q300 228 546 206 L548 240 Q300 262 58 240 Z" fill="#EE97AD" stroke="#C26A84" stroke-width="2.5"/>'
	s += '<path d="M80 168 Q200 146 330 152 Q430 146 530 154" stroke="#FBD3DE" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.8"/>'
	s += '<path d="M62 238 Q300 258 546 238" stroke="#B85A76" stroke-width="5" fill="none" opacity="0.35"/>'
	s += '<path d="M70 128 Q120 112 190 116" stroke="#F0E6F6" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.8"/>'
	s += '<path d="M440 150 V300 M540 140 V300" stroke="#F4F2EC" stroke-width="8"/><path d="M440 150 V300 M540 140 V300" stroke="#C9C2B4" stroke-width="1.5"/>'
	for x in [460.0, 480.0, 500.0, 520.0]:
		s += '<path d="M%s 150 V200" stroke="#F4F2EC" stroke-width="5"/>' % x
	s += '<path d="M436 146 H544" stroke="#F4F2EC" stroke-width="8"/>'
	# Plush bunny.
	s += '<ellipse cx="250" cy="148" rx="20" ry="14" fill="#F7C6D4" stroke="#C26A84" stroke-width="2"/><circle cx="270" cy="136" r="11" fill="#F7C6D4" stroke="#C26A84" stroke-width="2"/>'
	s += '<path d="M264 126 q-4 -20 2 -22 q6 2 4 22 M274 126 q2 -20 8 -20 q4 4 -2 22" fill="#F7C6D4" stroke="#C26A84" stroke-width="2"/>'
	s += '<circle cx="273" cy="135" r="1.8" fill="#2B2B2B"/>'
	s += '<path d="M330 150 q20 -16 50 -4 q10 10 -6 14 q-30 4 -44 -10 z" fill="#1E1E22"/>'
	return tex(560, 300, s)


## Canvas 360x380: white dresser with the hamster's glass terrarium on top, in two layers so the hamster
## (a Hamster node, in these canvas units) lives between them. `front` = glass edges and glare plus the
## things standing on the dresser (photo frames, lit candle, gumball machine); otherwise the back:
## glass box, bedding, plants, a wooden hideout, the water bottle and the dresser itself. Bedding at y 152.
static func terrarium(front: bool) -> ImageTexture:
	var s := ""
	if front:
		s += '<rect x="10" y="20" width="300" height="150" fill="none" stroke="#B9C9C4" stroke-width="3"/>'
		s += '<path d="M10 20 L30 4 H330 L310 20 M310 20 L330 4 V154 L310 170" fill="none" stroke="#B9C9C4" stroke-width="2"/>'
		s += '<path d="M20 24 L60 24 L26 120 L20 120 Z M250 24 L262 24 L214 168 L202 168 Z" fill="#FFFFFF" opacity="0.28"/>'
		s += '<rect x="30" y="134" width="48" height="42" fill="#2B2B2B"/><rect x="36" y="140" width="36" height="30" fill="#8E9AA6"/>'
		s += '<rect x="86" y="146" width="36" height="30" fill="#F4F2EC" stroke="#2B2B2B" stroke-width="3"/><rect x="92" y="152" width="24" height="18" fill="#C9A88A"/>'
		s += '<path d="M240 176 v-40 h44 v40 z" fill="#F2C14E" stroke="#B58A24" stroke-width="2"/><path d="M262 136 q-4 -10 0 -18 q4 8 0 18" fill="#FFB347"/>'
		s += '<circle cx="306" cy="152" r="14" fill="#F7D6E0" stroke="#D97A9A" stroke-width="2"/><rect x="298" y="164" width="16" height="12" fill="#E04F7A"/>'
		return tex(360, 380, s)
	s += '<rect x="10" y="20" width="300" height="150" fill="#DDEFE8" fill-opacity="0.45"/>'
	s += '<path d="M10 20 L30 4 H330 L310 20 Z M310 20 L330 4 V154 L310 170 Z" fill="#E8F2EE" fill-opacity="0.4"/>'
	for x in [36.0, 84.0, 186.0, 290.0]:
		s += '<path d="M%s 150 q-10 -44 6 -66 q8 32 -6 66 M%s 150 q14 -36 30 -44 q-6 30 -30 44" fill="#5FAE4F" stroke="#3E7E32" stroke-width="2"/>' % [x, x]
	s += '<path d="M14 168 Q60 146 120 152 Q180 146 240 152 Q280 147 306 152 V170 H14 Z" fill="#E6D3A8"/>'
	for i in 40:
		var bx := 18.0 + (i * 37) % 286
		var by := 156.0 + (i * 13) % 12
		s += '<path d="M%s %s l6 -2" stroke="#C9B080" stroke-width="2"/>' % [bx, by]
	# Wooden hideout with a round door, and the water bottle clipped to the glass.
	s += '<path d="M196 152 V116 L222 98 L248 116 V152 Z" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2.5"/>'
	s += '<path d="M190 118 L222 94 L254 118" stroke="#9A6E44" stroke-width="5" fill="none" stroke-linecap="round"/>'
	s += '<path d="M212 152 V138 Q222 124 232 138 V152 Z" fill="#4A3020"/>'
	s += '<rect x="278" y="40" width="18" height="56" rx="8" fill="#BFE3F2" fill-opacity="0.8" stroke="#7FA8BA" stroke-width="2"/>'
	s += '<rect x="278" y="62" width="18" height="34" rx="8" fill="#7FC4E0" fill-opacity="0.7"/>'
	s += '<path d="M287 96 L282 118" stroke="#9A9A9A" stroke-width="3"/><rect x="276" y="40" width="22" height="8" fill="#E04F5F"/>'
	s += '<rect x="0" y="176" width="340" height="18" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2.5"/>'
	s += '<rect x="10" y="194" width="320" height="186" fill="#F7F6F2" stroke="#C9C2B4" stroke-width="2.5"/>'
	for y in [204.0, 264.0, 324.0]:
		s += '<rect x="22" y="%s" width="296" height="50" fill="none" stroke="#D9D2C4" stroke-width="2"/><rect x="156" y="%s" width="28" height="5" rx="2" fill="#C9C2B4"/>' % [y, y + 22]
	return tex(360, 380, s)


## Canvas 200x150: yellow checkerboard painting with pink flowers.
static func flower_painting() -> ImageTexture:
	var s := '<rect x="2" y="2" width="196" height="146" fill="#F7F2E0" stroke="#D9D2C4" stroke-width="2"/>'
	for r in 4:
		for c in 5:
			if (r + c) % 2 == 0:
				s += '<rect x="%d" y="%d" width="38" height="36" fill="#F2C12E"/>' % [4 + c * 38, 4 + r * 36]
	s += '<path d="M40 130 Q100 80 160 130 Z" fill="#3E8E5A"/>'
	for x in [62.0, 88.0, 112.0, 138.0]:
		s += '<circle cx="%s" cy="100" r="11" fill="#F2A7C9"/><circle cx="%s" cy="100" r="4" fill="#FFF4C4"/>' % [x, x]
	return tex(200, 150, s)


## Canvas 120x160: strawberry poster on a pink checkerboard.
static func strawberry_poster() -> ImageTexture:
	var s := '<rect x="0" y="0" width="120" height="160" fill="#F7E0EA"/>'
	for r in 8:
		for c in 6:
			if (r + c) % 2 == 0:
				s += '<rect x="%d" y="%d" width="20" height="20" fill="#E9A3C3"/>' % [c * 20, r * 20]
	for p in [[44.0, 58.0, 24.0], [78.0, 84.0, 20.0]]:
		var cx: float = p[0]
		var top: float = p[1]
		var r: float = p[2]
		s += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="#D4243F" stroke="#8E1A2C" stroke-width="2"/>' % [
			cx - r, top, cx - r, top + r * 1.3, cx, top + r * 1.8, cx + r, top + r * 1.3, cx + r, top, cx, top - r * 0.35, cx - r, top]
		for k in 7:
			s += '<ellipse cx="%s" cy="%s" rx="1.6" ry="2.4" fill="#F7D774"/>' % [cx + [-12, 0, 12, -6, 6, -10, 10][k] * r / 24.0, top + [8, 6, 8, 20, 20, 30, 30][k] * r / 24.0]
		s += '<path d="M%s %s l-12 -4 l9 -3 l-2 -9 l7 7 l7 -7 l-2 9 l9 3 l-12 4 z" fill="#3E8E5A" stroke="#2A6A40" stroke-width="1.5"/>' % [cx, top + 2]
	return tex(120, 160, s)


## Canvas 170x250: three white book ledges with colourful picture books facing out.
static func book_ledges() -> ImageTexture:
	var s := ""
	var covers := ["#F2C12E", "#7E57C2", "#E04F5F", "#3E8E5A", "#1D4F91", "#FF8A3D", "#F2A7C9", "#1FB5C4", "#8D6E63"]
	for r in 3:
		var y := 70.0 + r * 80.0
		var x := 8.0
		var k := r * 3
		while x < 150.0:
			var w := 34.0 + (k * 5) % 12
			var h := 44.0 + (k * 7) % 16
			s += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="#3A3A3A" stroke-width="1.5"/>' % [x, y - h, w, h, covers[k % covers.size()]]
			s += '<rect x="%s" y="%s" width="%s" height="%s" fill="#FFFFFF" opacity="0.5"/>' % [x + 5, y - h + 8, w - 10, 8]
			x += w + 3.0
			k += 1
		s += '<rect x="2" y="%s" width="166" height="10" fill="#F7F6F2" stroke="#C9C2B4" stroke-width="2"/>' % y
	return tex(170, 250, s)


## Canvas 180x170: fluffy white sheepskin chair. Floor at y 170.
static func fluffy_chair() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := '<path d="M20 170 L40 120 M160 170 L140 120" stroke="#8A6A40" stroke-width="5"/>'
	s += '<path d="M14 120 Q4 40 60 20 Q90 0 130 20 Q176 40 166 120 Q90 140 14 120 Z" fill="#F7F4EE" stroke="#C9C2B4" stroke-width="3"/>'
	for i in 40:
		var x := rng.randf_range(24, 156)
		var y := rng.randf_range(30, 118)
		s += '<path d="M%.1f %.1f q4 -6 8 0" stroke="#DDD6CA" stroke-width="2" fill="none"/>' % [x, y]
	return tex(180, 170, s)


## Canvas 360x260: white desk under a pile of bags and clothes, with the red office chair. Floor at y 260.
static func desk() -> ImageTexture:
	var s := '<rect x="60" y="100" width="290" height="16" fill="#F7F6F2" stroke="#C9C2B4" stroke-width="2.5"/>'
	s += '<rect x="250" y="116" width="96" height="144" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2.5"/>'
	s += '<rect x="66" y="116" width="10" height="144" fill="#F4F2EC" stroke="#C9C2B4" stroke-width="2"/>'
	for y in [130.0, 176.0, 222.0]:
		s += '<rect x="258" y="%s" width="80" height="38" fill="none" stroke="#D9D2C4" stroke-width="2"/>' % y
	s += '<path d="M200 100 q10 -40 60 -36 q40 4 40 36 z" fill="#8FB5A0" stroke="#5E8A72" stroke-width="2"/>'
	s += '<path d="M250 100 q20 -30 60 -20 q30 10 30 20 z" fill="#F2B6CF" stroke="#B5647F" stroke-width="2"/>'
	s += '<path d="M120 100 q10 -30 40 -26 l20 26 z" fill="#F2D9A0" stroke="#B5A270" stroke-width="2"/>'
	# Red office chair with a white sweater over the back.
	s += '<path d="M40 40 Q40 20 70 20 H120 Q140 20 140 40 V130 H40 Z" fill="#D9343F" stroke="#8E1A24" stroke-width="3"/>'
	s += '<path d="M60 26 Q90 14 130 30 L126 120 Q100 136 70 120 Z" fill="#F1ECE2" stroke="#B9B4AA" stroke-width="2.5"/>'
	s += '<rect x="30" y="136" width="130" height="22" rx="8" fill="#D9343F" stroke="#8E1A24" stroke-width="3"/>'
	s += '<path d="M95 158 V220 M50 240 L95 220 L140 240 M95 220 V244" stroke="#8E9399" stroke-width="7" stroke-linecap="round"/>'
	for x in [50.0, 95.0, 140.0]:
		s += '<circle cx="%s" cy="250" r="8" fill="#3A3A3A"/>' % x
	return tex(360, 260, s)


## Canvas 140x120: little white kids' table and chair. Floor at y 120.
static func kid_table() -> ImageTexture:
	var s := '<rect x="40" y="50" width="96" height="10" fill="#F7F6F2" stroke="#C9C2B4" stroke-width="2"/>'
	s += '<path d="M50 60 V120 M126 60 V120" stroke="#F4F2EC" stroke-width="7"/><path d="M50 60 V120 M126 60 V120" stroke="#C9C2B4" stroke-width="1.5"/>'
	s += '<path d="M10 20 V120 M10 70 H44 V120" stroke="#F4F2EC" stroke-width="7" fill="none"/>'
	s += '<path d="M10 20 V120 M10 70 H44 V120" stroke="#C9C2B4" stroke-width="1.5" fill="none"/>'
	s += '<path d="M10 30 H30 M10 46 H30" stroke="#F4F2EC" stroke-width="5"/>'
	s += '<circle cx="96" cy="40" r="10" fill="#F2C14E" stroke="#B58A24" stroke-width="2"/>'
	return tex(140, 120, s)


# ── Windows, plants, lamps and small things ──────────────────

## Canvas w x h: window with white trim, sheer curtains and the view out: sky, the neighbour's brick
## wall across the lane and an autumn tree.
static func window(w: float, h: float) -> ImageTexture:
	var s := _defs()
	s += '<rect x="0" y="0" width="%s" height="%s" fill="%s" stroke="%s" stroke-width="3"/>' % [w, h, TRIM, TRIM_DARK]
	s += '<rect x="16" y="16" width="%s" height="%s" fill="url(#outside)"/>' % [w - 32, h - 46]
	s += '<rect x="16" y="%s" width="%s" height="%s" fill="#B5603F" opacity="0.75"/>' % [h * 0.42, w - 32, h * 0.45]
	for y in range(int(h * 0.42) + 8, int(h) - 30, 12):
		s += '<path d="M16 %d H%s" stroke="#9A4E34" stroke-width="1.5" opacity="0.7"/>' % [y, w - 16]
	# An autumn tree in the lane: trunk and a few leaf clumps.
	s += '<path d="M%s %s V%s" stroke="#5E4636" stroke-width="7"/>' % [w * 0.36, h * 0.88, h * 0.3]
	for c in [[0.22, 0.3, 0.13, "#D35400"], [0.42, 0.22, 0.15, "#E67E22"], [0.3, 0.15, 0.11, "#F1C40F"], [0.52, 0.34, 0.1, "#C0392B"], [0.18, 0.18, 0.09, "#E59866"]]:
		s += '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % [w * c[0], h * c[1], w * c[2], c[3]]
	s += '<rect x="%s" y="16" width="8" height="%s" fill="%s"/>' % [w / 2 - 4, h - 46, TRIM]
	s += '<rect x="16" y="%s" width="%s" height="8" fill="%s"/>' % [h * 0.45, w - 32, TRIM]
	s += '<path d="M20 20 L%s 20 L30 %s L20 %s Z" fill="#FFFFFF" opacity="0.35"/>' % [w * 0.4, h * 0.6, h * 0.6]
	s += '<rect x="-6" y="%s" width="%s" height="16" fill="%s" stroke="%s" stroke-width="2"/>' % [h - 30, w + 12, TRIM, TRIM_DARK]
	# Sheer curtains gathered at the sides.
	for side in [0, 1]:
		var x0 := 4.0 if side == 0 else w - 4.0
		var dir := 1.0 if side == 0 else -1.0
		s += '<path d="M%s 4 h%s q%s %s %s %s h%s z" fill="#FBF7EE" opacity="0.8" stroke="#E3DACB" stroke-width="1.5"/>' % [x0, dir * w * 0.22, -dir * w * 0.12, h * 0.5, dir * w * 0.02, h - 34, -dir * w * 0.12]
		for k in 3:
			s += '<path d="M%s 8 q%s %s 0 %s" stroke="#E3DACB" stroke-width="1.5" fill="none"/>' % [x0 + dir * (10 + k * 10), dir * 6, h * 0.4, h - 44]
	s += '<rect x="-10" y="0" width="%s" height="6" rx="3" fill="#B08A5A"/>' % (w + 20)
	return tex(w, h, s)


## Canvas 200x330: big monstera in a terracotta pot. Floor at y 330.
static func monstera() -> ImageTexture:
	var s := ""
	var leaves := [[100, 60, -0.3, 1.0], [56, 120, -0.9, 0.9], [150, 110, 0.7, 0.95], [80, 180, -0.6, 0.8], [130, 175, 0.5, 0.85], [100, 130, 0.1, 0.9]]
	for l in leaves:
		s += '<path d="M100 250 Q%s %s %s %s" stroke="#3E6E32" stroke-width="4" fill="none"/>' % [100 + (l[0] - 100) * 0.3, l[1] + 60, l[0], l[1] + 30]
	for l in leaves:
		var cx: float = l[0]
		var cy: float = l[1]
		var r: float = 46.0 * l[3]
		s += '<g transform="translate(%s %s) rotate(%s)">' % [cx, cy, rad_to_deg(l[2])]
		s += '<path d="M0 %s Q%s %s %s 0 Q%s %s 0 %s Q%s %s %s 0 Q%s %s 0 %s Z" fill="#3E8E4A" stroke="#245E2E" stroke-width="2.5"/>' % [
			r, r * 1.1, r * 0.8, r, r * 1.0, -r * 1.1, -r, -r * 1.0, -r * 1.1, -r, -r * 1.1, r * 0.8, r]
		for k in 3:
			var y := -r * 0.5 + k * r * 0.45
			s += '<path d="M%s %s h%s M%s %s h%s" stroke="#F4EFE2" stroke-width="5" stroke-linecap="round"/>' % [r * 0.45, y, r * 0.4, -r * 0.45, y, -r * 0.4]
		s += '<path d="M0 %s V%s" stroke="#2E6E38" stroke-width="2"/></g>' % [r * 0.9, -r * 0.9]
	s += '<path d="M54 250 H146 L134 330 H66 Z" fill="#C2693F" stroke="#7E3E22" stroke-width="3"/>'
	s += '<rect x="48" y="244" width="104" height="16" rx="3" fill="#D27A4E" stroke="#7E3E22" stroke-width="2.5"/>'
	return tex(200, 330, s)


## Canvas 120x420: brass floor lamp with a linen shade. Floor at y 420.
static func floor_lamp() -> ImageTexture:
	var s := '<path d="M20 70 L100 70 L86 10 L34 10 Z" fill="#F4E6C8" stroke="#C9B48A" stroke-width="2.5"/>'
	s += '<path d="M28 66 L92 66" stroke="#FFF4D6" stroke-width="4"/>'
	s += '<rect x="57" y="70" width="6" height="330" fill="#C9A35A" stroke="#8A6A30" stroke-width="1.5"/>'
	s += '<ellipse cx="60" cy="410" rx="34" ry="8" fill="#C9A35A" stroke="#8A6A30" stroke-width="2"/>'
	return tex(120, 420, s)


## Canvas 110x130: little round side table with a mug and a book. Floor at y 130.
static func side_table() -> ImageTexture:
	var s := '<ellipse cx="55" cy="40" rx="48" ry="9" fill="#6E4424" stroke="#3E2414" stroke-width="2.5"/>'
	s += '<path d="M52 48 V122 M30 128 L52 110 L80 128" stroke="#4A2E1A" stroke-width="6" fill="none" stroke-linecap="round"/>'
	s += '<rect x="22" y="24" width="40" height="10" fill="#1D4F91" stroke="#123060" stroke-width="1.5"/>'
	s += '<path d="M70 34 V18 H86 V34 Z" fill="#F2EDE2" stroke="#9A9A9A" stroke-width="2"/><path d="M86 22 q8 2 0 10" stroke="#9A9A9A" stroke-width="2" fill="none"/>'
	return tex(110, 130, s)


## Canvas 220x30: coir doormat with a leaf pattern, seen in perspective.
static func doormat() -> ImageTexture:
	var s := '<path d="M20 2 H200 L218 28 H2 Z" fill="#B8915A" stroke="#7E5E30" stroke-width="2"/>'
	for x in range(40, 190, 24):
		s += '<path d="M%d 8 q8 6 0 14 q-8 -6 0 -14" fill="#7E5E30" opacity="0.7"/>' % x
	return tex(220, 30, s)


## Canvas 130x80: rain boots (yellow and green) standing by the door. Floor at y 80.
static func boots() -> ImageTexture:
	var s := ""
	for b in [[8.0, "#F2C12E", "#A8800E"], [66.0, "#3E8E5A", "#245E36"]]:
		var x: float = b[0]
		s += '<path d="M%s 6 H%s V56 Q%s 60 %s 64 H%s Q%s 80 %s 78 H%s Z" fill="%s" stroke="%s" stroke-width="2.5"/>' % [x + 6, x + 32, x + 34, x + 50, x + 54, x + 58, x + 50, x + 4, b[1], b[2]]
		s += '<rect x="%s" y="6" width="26" height="8" fill="%s" opacity="0.4"/>' % [x + 6, b[2]]
	return tex(130, 80, s)


## Canvas 440x170: a row of framed family photos for the hallway.
static func photo_row() -> ImageTexture:
	var s := ""
	var frames := [[0, 30, 90, 110, "#2B2B2B"], [110, 0, 120, 90, "#B08A5A"], [110, 104, 56, 64, "#F4F2EC"], [180, 104, 50, 64, "#2B2B2B"], [250, 20, 80, 100, "#F4F2EC"], [350, 40, 90, 70, "#B08A5A"]]
	var tints := ["#9DB9C9", "#E8C9A0", "#C9DDB5", "#F2B6CF", "#D9C6E6", "#F2D9A0"]
	for i in frames.size():
		var f: Array = frames[i]
		s += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [f[0], f[1], f[2], f[3], f[4]]
		s += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [f[0] + 7, f[1] + 7, f[2] - 14, f[3] - 14, tints[i]]
		var cx: float = f[0] + f[2] / 2.0
		var cy: float = f[1] + f[3] * 0.62
		s += '<circle cx="%s" cy="%s" r="%s" fill="#6E4E3A" opacity="0.6"/>' % [cx - 8, cy - 8, minf(f[2], f[3]) * 0.12]
		s += '<circle cx="%s" cy="%s" r="%s" fill="#B0623A" opacity="0.6"/>' % [cx + 10, cy - 4, minf(f[2], f[3]) * 0.1]
		s += '<path d="M%s %s q18 -16 36 0 v%s h-36 z" fill="#5A6E8E" opacity="0.5"/>' % [cx - 18, cy + 8, f[3] * 0.18]
	return tex(440, 170, s)


## Canvas w x 70: long striped runner rug for the hallway floor.
static func runner(w: float) -> ImageTexture:
	var s := '<path d="M30 2 H%s L%s 68 H2 Z" fill="#2F5D8A" stroke="#1C3C5E" stroke-width="2"/>' % [w - 30, w - 2]
	for i in 3:
		s += '<path d="M%s %s H%s" stroke="%s" stroke-width="5"/>' % [30 - i * 8, 14 + i * 20, w - 30 + i * 8, ["#F2C14E", "#E8E2D4", "#D9682B"][i]]
	return tex(w, 70, s)


## Canvas 420x90: round pink rug for the bedroom, in perspective.
static func round_rug() -> ImageTexture:
	var s := '<ellipse cx="210" cy="45" rx="206" ry="42" fill="#F2B6CF" stroke="#C97B9A" stroke-width="2"/>'
	s += '<ellipse cx="210" cy="45" rx="160" ry="30" fill="none" stroke="#FBE3EC" stroke-width="6"/>'
	s += '<ellipse cx="210" cy="45" rx="100" ry="18" fill="none" stroke="#E79AB8" stroke-width="5"/>'
	return tex(420, 90, s)


## Canvas 120x110: wicker laundry basket overflowing with clothes. Floor at y 110.
static func laundry_basket() -> ImageTexture:
	var s := '<path d="M30 30 Q20 0 60 8 Q96 0 92 30 Z" fill="#7FB3D5" stroke="#4E7E9E" stroke-width="2"/>'
	s += '<path d="M60 30 q20 -30 40 -6 q4 10 -8 6 z" fill="#F2A7B9" stroke="#C26A84" stroke-width="2"/>'
	s += '<path d="M12 30 H108 L98 108 H22 Z" fill="#D9B88A" stroke="#8A6A40" stroke-width="3"/>'
	for y in range(42, 104, 12):
		s += '<path d="M16 %d H104" stroke="#B8915A" stroke-width="2"/>' % y
	for x in range(28, 100, 14):
		s += '<path d="M%d 32 V106" stroke="#C9A472" stroke-width="2"/>' % x
	return tex(120, 110, s)


## Canvas 150x90: plushies sitting on the floor (a bear and a cat). Floor at y 90.
static func plushies() -> ImageTexture:
	var s := '<ellipse cx="45" cy="66" rx="30" ry="24" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2.5"/>'
	s += '<circle cx="45" cy="30" r="22" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2.5"/>'
	s += '<circle cx="28" cy="12" r="8" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/><circle cx="62" cy="12" r="8" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
	s += '<ellipse cx="45" cy="38" rx="9" ry="7" fill="#E8D2B4"/><circle cx="38" cy="28" r="2.5" fill="#2B2B2B"/><circle cx="52" cy="28" r="2.5" fill="#2B2B2B"/><circle cx="45" cy="36" r="2.5" fill="#2B2B2B"/>'
	s += '<ellipse cx="110" cy="70" rx="26" ry="20" fill="#F4F2EC" stroke="#9A948A" stroke-width="2.5"/>'
	s += '<circle cx="110" cy="40" r="18" fill="#F4F2EC" stroke="#9A948A" stroke-width="2.5"/>'
	s += '<path d="M96 30 l2 -16 l10 10 M124 30 l-2 -16 l-10 10" fill="#F4F2EC" stroke="#9A948A" stroke-width="2"/>'
	s += '<circle cx="104" cy="40" r="2.2" fill="#2B2B2B"/><circle cx="116" cy="40" r="2.2" fill="#2B2B2B"/><path d="M108 46 h4 l-2 2 z" fill="#E89AA8"/>'
	return tex(150, 90, s)


## Canvas 26x40: light switch plate (outlet = false) or wall outlet.
static func wall_plate(outlet: bool) -> ImageTexture:
	var s := '<rect x="2" y="2" width="22" height="36" rx="3" fill="#F7F5F0" stroke="#C9C2B4" stroke-width="1.5"/>'
	if outlet:
		s += '<rect x="9" y="9" width="2" height="6" fill="#6E6E6E"/><rect x="15" y="9" width="2" height="6" fill="#6E6E6E"/><rect x="9" y="24" width="2" height="6" fill="#6E6E6E"/><rect x="15" y="24" width="2" height="6" fill="#6E6E6E"/>'
	else:
		s += '<rect x="10" y="12" width="6" height="16" rx="2" fill="#E8E4DA" stroke="#B9B4AA" stroke-width="1"/>'
	return tex(26, 40, s)
