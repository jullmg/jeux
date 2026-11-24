class_name InteriorArt
extends RefCounted
## Furniture and fixtures of Charlotte's flat, drawn as SVG at runtime (from the reference photos in
## reference/maison_charlotte/interieur). Each function documents its canvas; "floor" is the bottom edge.

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
		+ '<linearGradient id="steel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F2F2EF"/><stop offset="0.45" stop-color="#C9C5BC"/><stop offset="1" stop-color="#9A968E"/></linearGradient>'
		+ _outside_gradient()
		+ '</defs>')


# What is seen through a door's glass or a window: daylight over the yard, or the deep blue of Halloween night.
static func _outside_gradient() -> String:
	if Halloween.night():
		return '<linearGradient id="outside" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16214A"/><stop offset="0.6" stop-color="#28325C"/><stop offset="1" stop-color="#3A4160"/></linearGradient>'
	return '<linearGradient id="outside" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BFD8E8"/><stop offset="0.6" stop-color="#9DB98C"/><stop offset="1" stop-color="#7E8F6A"/></linearGradient>'


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


## A framed picture, with volume: a soft shadow on the wall, a mitred frame in `kind` ("wood", "black", "gold", "white") with its light
## on the upper left, a cream mat with a bevelled opening, the picture (`inner`, drawn in the opening's own space, `pw` × `ph`, clipped)
## and a streak of reflection on the glass. `id` keeps the clip path of each frame in a sheet apart.
static func _framed(id: String, x: float, y: float, w: float, h: float, kind: String, inner: String, t := 7.0, mat := 6.0, hue := "#F4EFE4") -> String:
	var tones: Array = {
		"wood": ["#C99259", "#B27A44", "#8C5C30", "#744A24"],
		"black": ["#46464C", "#2E2E33", "#1C1C20", "#101013"],
		"gold": ["#EBC95A", "#D2A93F", "#A88120", "#8A6812"],
		"white": ["#FFFFFF", "#F4F2EC", "#DEDACF", "#CBC6B8"],
	}[kind]
	var s := '<rect x="%s" y="%s" width="%s" height="%s" rx="1.5" fill="#000000" opacity="0.16"/>' % [x + 3.5, y + 4.5, w, h]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x, y, x + w, y, x + w - t, y + t, x + t, y + t, tones[0]]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x, y, x + t, y + t, x + t, y + h - t, x, y + h, tones[1]]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x + w, y, x + w, y + h, x + w - t, y + h - t, x + w - t, y + t, tones[2]]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x, y + h, x + t, y + h - t, x + w - t, y + h - t, x + w, y + h, tones[3]]
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="#00000033" stroke-width="1"/>' % [x + 0.5, y + 0.5, w - 1.0, h - 1.0]
	if kind == "wood":
		for k in 3:
			s += '<path d="M%s %s h%s" stroke="#FFFFFF" stroke-width="0.7" opacity="0.18"/>' % [x + 4.0, y + 2.0 + k * 1.6, w - 8.0]
	if kind == "gold":
		s += '<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="#FFF3B0" stroke-width="1" opacity="0.6"/>' % [x + 2.0, y + 2.0, w - 4.0, h - 4.0]
	# The mat and its bevelled opening.
	var mx := x + t
	var my := y + t
	var mw := w - 2.0 * t
	var mh := h - 2.0 * t
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [mx, my, mw, mh, hue]
	s += '<path d="M%s %s h%s v%s" stroke="#00000022" stroke-width="1.5" fill="none"/>' % [mx, my, mw, mh]
	var px := mx + mat
	var py := my + mat
	var pw := mw - 2.0 * mat
	var ph := mh - 2.0 * mat
	s += '<defs><clipPath id="clip_%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath></defs>' % [id, px, py, pw, ph]
	s += '<g clip-path="url(#clip_%s)"><g transform="translate(%s %s)">%s</g>' % [id, px, py, inner]
	# Shade inside the opening (the mat is thicker than the picture), then the glass.
	s += '<rect x="%s" y="%s" width="%s" height="3" fill="#000000" opacity="0.22"/><rect x="%s" y="%s" width="3" height="%s" fill="#000000" opacity="0.16"/>' % [px, py, pw, px, py, ph]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="#FFFFFF" opacity="0.2"/>' % [px, py, px + pw * 0.5, py, px + pw * 0.12, py + ph, px, py + ph]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="#FFFFFF" opacity="0.1"/>' % [px + pw * 0.58, py, px + pw * 0.66, py, px + pw * 0.28, py + ph, px + pw * 0.2, py + ph]
	s += '</g>'
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="#00000044" stroke-width="1"/>' % [px, py, pw, ph]
	return s


## Canvas w x h: a white cast-iron column radiator, floor at the bottom: enamel columns that catch the light on their left, the dark
## gaps between them, a top and a bottom header, the valve with its knob, the pipe into the floor, a few chips of paint.
static func radiator(w: float, h: float) -> ImageTexture:
	var s := '<defs><linearGradient id="enamel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E4E0D6"/><stop offset="0.28" stop-color="#FFFFFF"/><stop offset="0.7" stop-color="#EDEAE2"/><stop offset="1" stop-color="#C9C4B8"/></linearGradient>'
	s += '<linearGradient id="enamel_h" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#D8D4C8"/></linearGradient></defs>'
	var foot := h - 4.0
	s += '<ellipse cx="%s" cy="%s" rx="%s" ry="4" fill="#000000" opacity="0.18"/>' % [w / 2.0, foot, w / 2.0 - 2.0]
	var n := int((w - 18.0) / 15.0)
	var x := 9.0 + (w - 18.0 - n * 15.0) / 2.0
	for k in n:
		var cx := x + k * 15.0
		# One column: a deep slot behind, the enamel cylinder over it, its highlight and its chipped foot.
		s += '<rect x="%s" y="10" width="13" height="%s" rx="6.5" fill="#6E6A60"/>' % [cx + 1.0, foot - 16.0]
		s += '<rect x="%s" y="8" width="12" height="%s" rx="6" fill="url(#enamel)" stroke="#A8A398" stroke-width="1.4"/>' % [cx, foot - 18.0]
		s += '<path d="M%s 14 v%s" stroke="#FFFFFF" stroke-width="1.6" opacity="0.8" stroke-linecap="round"/>' % [cx + 3.0, foot - 32.0]
		s += '<path d="M%s 14 v%s" stroke="#9A958A" stroke-width="1" opacity="0.5" stroke-linecap="round"/>' % [cx + 9.5, foot - 32.0]
	# Headers: the top and bottom manifolds the columns grow out of.
	for hy in [4.0, foot - 14.0]:
		s += '<rect x="3" y="%s" width="%s" height="10" rx="4" fill="url(#enamel_h)" stroke="#A8A398" stroke-width="1.6"/>' % [hy, w - 6.0]
		s += '<path d="M8 %s H%s" stroke="#FFFFFF" stroke-width="1.4" opacity="0.8"/>' % [hy + 2.5, w - 8.0]
		s += '<path d="M8 %s H%s" stroke="#B3AEA2" stroke-width="1" opacity="0.8"/>' % [hy + 8.0, w - 8.0]
	# The valve and the pipe.
	s += '<rect x="%s" y="%s" width="6" height="%s" fill="#B8B4AA" stroke="#8F8A7E" stroke-width="1.2"/>' % [w - 14.0, foot - 8.0, 8.0]
	s += '<rect x="%s" y="%s" width="12" height="9" rx="2" fill="#C9A35A" stroke="#8A6A2A" stroke-width="1.4"/>' % [w - 17.0, foot - 24.0]
	s += '<circle cx="%s" cy="%s" r="5" fill="#C9A35A" stroke="#8A6A2A" stroke-width="1.4"/><path d="M%s %s h8" stroke="#8A6A2A" stroke-width="2"/>' % [w - 11.0, foot - 34.0, w - 15.0, foot - 34.0]
	# A little wear: chips down to the black iron, and a faint rust stain by the valve.
	for chip in [[x + 20.0, foot - 28.0], [x + 61.0, 20.0], [x + 108.0, foot - 24.0]]:
		if float(chip[0]) < w - 24.0:
			s += '<circle cx="%s" cy="%s" r="1.4" fill="#4A463E"/>' % chip
	s += '<ellipse cx="%s" cy="%s" rx="5" ry="3" fill="#B26A3A" opacity="0.25"/>' % [w - 14.0, foot - 4.0]
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
	# Velvet that gives: the seat cushions sag a little in the middle, each one creased at its corners, and the back cushions
	# are buttoned, so the sofa reads as soft instead of as a block.
	for x in [72.0, 300.0]:
		s += '<path d="M%s 126 Q%s 136 %s 126" stroke="#B5801E" stroke-width="2" fill="none" opacity="0.7"/>' % [x + 10, x + 110, x + 210]
		s += '<path d="M%s 196 Q%s 186 %s 196" stroke="#F2C66A" stroke-width="2.5" fill="none" opacity="0.5"/>' % [x + 12, x + 110, x + 208]
	for x in [70.0, 230.0, 390.0]:
		s += '<circle cx="%s" cy="70" r="3.4" fill="#8A5E14" opacity="0.8"/>' % (x + 70)
		s += '<path d="M%s 42 q6 26 0 52 M%s 42 q-6 26 0 52" stroke="#8A5E14" stroke-width="1.6" fill="none" opacity="0.35"/>' % [x + 30, x + 110]
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
	var inner := ""
	var kind := "black"
	var hue := "#F4EFE4"
	match style:
		0:
			# Line art on cream: a face drawn in one stroke, a sun, a wavy line.
			inner += '<rect width="104" height="136" fill="#F1ECE2"/>'
			inner += '<circle cx="74" cy="34" r="14" fill="#E8B15A" opacity="0.85"/>'
			inner += '<path d="M18 52 Q30 30 48 44 Q64 56 58 76 Q52 94 36 90 Q24 86 28 72 Q32 62 44 66" stroke="#4A453C" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
			inner += '<path d="M30 54 q3 -3 6 0 M44 50 q3 -3 6 0" stroke="#4A453C" stroke-width="1.6" fill="none"/>'
			inner += '<path d="M14 110 Q30 98 46 110 T78 110 T104 106" stroke="#7A8F7E" stroke-width="2" fill="none"/>'
			inner += '<path d="M14 120 Q30 108 46 120 T78 120 T104 116" stroke="#B5C2B6" stroke-width="2" fill="none"/>'
		1:
			# A mushroom under a big moon, on a dark ground.
			kind = "black"
			hue = "#EDE6D6"
			inner += '<rect width="104" height="136" fill="#2A2622"/>'
			inner += '<circle cx="52" cy="56" r="34" fill="#6A5632" opacity="0.7"/><circle cx="52" cy="56" r="26" fill="#8A7242" opacity="0.5"/>'
			inner += '<path d="M28 82 Q52 36 76 82 Z" fill="#F2E6C8"/><path d="M34 76 Q52 46 70 76" stroke="#D9C9A4" stroke-width="2" fill="none"/>'
			inner += '<rect x="47" y="80" width="10" height="32" rx="3" fill="#E8DCC0"/>'
			for d in [[40, 66, 4], [56, 58, 3], [64, 72, 3.5], [48, 70, 2.5]]:
				inner += '<circle cx="%s" cy="%s" r="%s" fill="#C9A06A" opacity="0.7"/>' % d
			for st in [[12, 14], [90, 20], [22, 40], [86, 100], [14, 110]]:
				inner += '<circle cx="%s" cy="%s" r="1.4" fill="#F2E6C8"/>' % st
		_:
			# A botanical print: three sprigs on a pale page.
			kind = "white"
			hue = "#F7F3E9"
			inner += '<rect width="104" height="136" fill="#EFE9DE"/>'
			for k in 3:
				var cx := 22.0 + k * 30.0
				inner += '<path d="M%s 124 Q%s 80 %s 30" stroke="#5E7A4E" stroke-width="2" fill="none"/>' % [cx, cx - 4.0 + k * 3.0, cx + 2.0]
				for j in 6:
					var y := 40.0 + j * 14.0
					var side := 1.0 if j % 2 == 0 else -1.0
					inner += '<ellipse cx="%s" cy="%s" rx="9" ry="3.6" fill="#7E9E68" stroke="#4E6A3E" stroke-width="1" transform="rotate(%s %s %s)"/>' % [cx + side * 8.0, y, -30.0 * side, cx + side * 8.0, y]
				inner += '<circle cx="%s" cy="30" r="3.4" fill="#D8845A"/>' % (cx + 2.0)
	var s := _framed("poster%d" % style, 2.0, 2.0, 116.0, 156.0, kind, inner, 7.0, 6.0, hue)
	return tex(124, 164, s)


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


## Canvas 90x120: the blue recycling bin (Montréal's bac), its lid standing open at the back, with what she sorted poking out of it:
## a flattened cardboard box, a bundle of newspapers tied with string and a bottle. Light from the upper left, a wheel and a handle.
static func recycling_bin() -> ImageTexture:
	var s := '<defs><linearGradient id="bin" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4B8CE8"/><stop offset="0.45" stop-color="#2F67BC"/><stop offset="1" stop-color="#1F4590"/></linearGradient>'
	s += '<linearGradient id="binlid" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3B78D2"/><stop offset="1" stop-color="#2A5CAD"/></linearGradient>'
	s += '<linearGradient id="card" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9B27C"/><stop offset="1" stop-color="#B98F58"/></linearGradient></defs>'
	# The shadow on the floor.
	s += '<ellipse cx="46" cy="117" rx="40" ry="4" fill="#000000" opacity="0.22"/>'
	# The lid, open: its underside seen from the front, standing at the back.
	s += '<path d="M12 40 L78 40 L74 6 L16 8 Z" fill="url(#binlid)" stroke="#1C3C78" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M20 14 L70 13 M19 24 L71 23" stroke="#1C3C78" stroke-width="1.6" opacity="0.5"/>'
	s += '<path d="M14 40 L26 9" stroke="#FFFFFF" stroke-width="2" opacity="0.3"/>'
	# What is in it: a bottle, a bundle of newspapers, flattened cardboard.
	s += '<path d="M14 46 L14 24 Q14 20 17 18 L17 10 L22 10 L22 18 Q25 20 25 24 L25 46 Z" fill="#BFE0F2" stroke="#6F9DB8" stroke-width="1.6" opacity="0.95"/>'
	s += '<rect x="15.5" y="28" width="8" height="10" fill="#E8F4FB" opacity="0.9"/><path d="M17 20 L17 40" stroke="#FFFFFF" stroke-width="1.5" opacity="0.7"/>'
	s += '<rect x="56" y="16" width="22" height="30" fill="#EFEAD9" stroke="#A59E88" stroke-width="1.8"/>'
	for i in 5:
		s += '<path d="M59 %d H75" stroke="#6E6A5E" stroke-width="1.6" opacity="0.55"/>' % (21 + i * 5)
	s += '<path d="M56 30 H78 M67 16 V46" stroke="#B39A66" stroke-width="1.6"/>'
	s += '<path d="M26 46 L28 8 L56 4 L58 46 Z" fill="url(#card)" stroke="#8A6A40" stroke-width="2" stroke-linejoin="round"/>'
	s += '<path d="M42 5 L43 46" stroke="#8A6A40" stroke-width="1.6" opacity="0.6"/><path d="M30 12 H54 M30 20 H54" stroke="#8A6A40" stroke-width="1" opacity="0.35"/>'
	s += '<rect x="36" y="6" width="14" height="8" fill="#E6D3A8" opacity="0.7"/>'
	# The body of the bin, tapering, with its ribs, the rim and the recycling mark.
	s += '<path d="M8 44 H82 L75 110 Q75 116 69 116 H21 Q15 116 15 110 Z" fill="url(#bin)" stroke="#1C3C78" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M6 40 H84 Q86 40 86 43 V50 H4 V43 Q4 40 6 40 Z" fill="#4A8BE6" stroke="#1C3C78" stroke-width="2.5"/>'
	s += '<rect x="8" y="42" width="40" height="3" fill="#FFFFFF" opacity="0.28"/>'
	for y in [66, 84, 102]:
		var inset: float = 8.0 + (y - 44) * 0.1
		s += '<path d="M%.1f %d H%.1f" stroke="#1C3C78" stroke-width="2" opacity="0.5"/><path d="M%.1f %d H%.1f" stroke="#7FB0F2" stroke-width="1.4" opacity="0.4"/>' % [inset, y, 90 - inset, inset, y + 2, 90 - inset]
	s += '<path d="M11 52 L17 108" stroke="#FFFFFF" stroke-width="3" opacity="0.2" stroke-linecap="round"/>'
	# The recycling mark: three arrows chasing each other round a triangle, as stamped on the real bins (a shade under them
	# so they look moulded in).
	var mark := Vector2(45.0, 82.0)
	for layer in 2:
		var off := Vector2(0.0, 1.2) if layer == 0 else Vector2.ZERO
		var ink := "#1C3C78" if layer == 0 else "#FFFFFF"
		for k in 3:
			var a0 := deg_to_rad(-90.0 + 120.0 * k + 14.0)
			var a1 := deg_to_rad(-90.0 + 120.0 * k + 96.0)
			var r := 14.0
			var p0 := mark + off + Vector2(cos(a0), sin(a0)) * r
			var p1 := mark + off + Vector2(cos(a1), sin(a1)) * r
			var tangent := Vector2(-sin(a1), cos(a1))
			var normal := Vector2(cos(a1), sin(a1))
			var head := p1 + tangent * 7.0
			s += '<path d="M%.1f %.1f A%.1f %.1f 0 0 1 %.1f %.1f" stroke="%s" stroke-width="4.2" fill="none" stroke-linecap="round"%s/>' % [p0.x, p0.y, r, r, p1.x, p1.y, ink, ' opacity="0.5"' if layer == 0 else ""]
			s += '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="%s" stroke="%s" stroke-width="1" stroke-linejoin="round"%s/>' % [
				head.x, head.y, (p1 + normal * 5.6).x, (p1 + normal * 5.6).y, (p1 - normal * 5.6).x, (p1 - normal * 5.6).y, ink, ink, ' opacity="0.5"' if layer == 0 else ""]
	# A handle at the back, a wheel and its hub.
	s += '<path d="M78 46 Q92 46 92 58 V70" stroke="#1C3C78" stroke-width="4" fill="none" stroke-linecap="round"/>'
	s += '<circle cx="70" cy="114" r="6.5" fill="#23262B"/><circle cx="70" cy="114" r="2.6" fill="#8E949B"/>'
	return tex(94, 120, s)


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


## Canvas 560x480: the kitchen at the end of the hall: fridge (its door bare: Charlotte's own drawings go on it), wood upper cabinet,
## white base cabinets with a black counter (stove, kettle, fruit bowl, utensil rail), the back door with
## a window onto the yard and the wall AC unit above, and a little island with a stool. Floor at y 480.
static func kitchen() -> ImageTexture:
	var s := _defs()
	# Fridge.
	s += '<rect x="4" y="120" width="104" height="356" rx="8" fill="#F2F2EF" stroke="#B9B4AA" stroke-width="3"/>'
	s += '<path d="M4 250 H108" stroke="#B9B4AA" stroke-width="3"/><rect x="92" y="190" width="6" height="44" rx="3" fill="#B9B4AA"/><rect x="92" y="268" width="6" height="60" rx="3" fill="#B9B4AA"/>'
	s += '<path d="M10 126 L40 126 L12 240 Z" fill="#FFFFFF" opacity="0.5"/>'
	# The fridge door stays bare: only Charlotte's own drawings go on it (see DrawingPad, house.gd).
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
	# Shaker doors, not flat rectangles: a sunk panel lit at the top left, a long bar handle, and the toe-kick in shadow.
	for x in [124.0, 212.0]:
		s += '<rect x="%s" y="284" width="84" height="178" fill="#EFEBE2" stroke="#C9C2B4" stroke-width="2"/>' % x
		s += '<rect x="%s" y="296" width="60" height="154" fill="#F7F5EF" stroke="#D5CEC2" stroke-width="1.6"/>' % (x + 12)
		s += '<path d="M%s 296 H%s M%s 296 V450" stroke="#FFFFFF" stroke-width="2" opacity="0.9"/>' % [x + 12, x + 72, x + 12]
		s += '<path d="M%s 450 H%s M%s 296 V450" stroke="#C4BCAE" stroke-width="1.6" opacity="0.8"/>' % [x + 12, x + 72, x + 72]
		s += '<rect x="%s" y="300" width="7" height="48" rx="3.5" fill="url(#steel)" stroke="#8E8A82" stroke-width="1"/>' % (x + 70)
	s += '<rect x="120" y="462" width="180" height="14" fill="#CFC8BA"/><rect x="120" y="462" width="180" height="5" fill="#000000" opacity="0.18"/>'
	s += '<path d="M114 274 H306" stroke="#FFFFFF" stroke-width="2.5" opacity="0.8"/>'
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
	var s := '<defs>'
	s += '<linearGradient id="duvet" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F8C0CF"/><stop offset="0.45" stop-color="#F4A4B9"/><stop offset="1" stop-color="#E4829F"/></linearGradient>'
	s += '<linearGradient id="duvet_v" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.35"/><stop offset="0.6" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="#7A2A44" stop-opacity="0.28"/></linearGradient>'
	s += '<linearGradient id="pillow" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F0E6F8"/><stop offset="1" stop-color="#C7B0DE"/></linearGradient>'
	s += '<linearGradient id="iron" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.5" stop-color="#F0EDE6"/><stop offset="1" stop-color="#CFC9BB"/></linearGradient>'
	s += '<linearGradient id="ticking" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E4DED2"/></linearGradient>'
	s += '</defs>'
	# Shade on the floor under it (the box of sweets peeks out of it).
	s += '<ellipse cx="300" cy="296" rx="250" ry="6" fill="#000000" opacity="0.14"/>'
	# The headboard: a white iron arch, bars with their balls, two rails, and a finial on each post.
	s += '<path d="M20 296 V60 Q20 20 70 20 Q120 20 120 60 V296" fill="none" stroke="#C9C2B4" stroke-width="12"/>'
	s += '<path d="M20 296 V60 Q20 20 70 20 Q120 20 120 60 V296" fill="none" stroke="url(#iron)" stroke-width="9"/>'
	s += '<path d="M17 296 V62 Q17 24 66 24" fill="none" stroke="#FFFFFF" stroke-width="1.6" opacity="0.9"/>'
	for x in [44.0, 70.0, 96.0]:
		s += '<path d="M%s 50 V196" stroke="#C9C2B4" stroke-width="7"/><path d="M%s 50 V196" stroke="url(#iron)" stroke-width="5"/><circle cx="%s" cy="86" r="6" fill="#E9E5DA" stroke="#B8B2A2" stroke-width="1.5"/><circle cx="%s" cy="84" r="2" fill="#FFFFFF"/>' % [x, x, x, x]
	for y in [122.0, 190.0]:
		s += '<path d="M22 %s H118" stroke="#C9C2B4" stroke-width="9"/><path d="M22 %s H118" stroke="url(#iron)" stroke-width="6.5"/>' % [y, y]
	for fx in [20.0, 120.0]:
		s += '<circle cx="%s" cy="58" r="8" fill="#F4F0E6" stroke="#B8B2A2" stroke-width="1.8"/><circle cx="%s" cy="55" r="2.6" fill="#FFFFFF"/>' % [fx, fx - 2.0]
	# The side of the mattress: quilted ticking with a piped edge, then the bed's base and its short feet.
	s += '<path d="M44 222 Q300 240 548 222 V258 Q300 276 44 258 Z" fill="url(#ticking)" stroke="#BDB6A6" stroke-width="2.2"/>'
	for x in range(80, 540, 46):
		s += '<path d="M%d 226 Q%d 244 %d 262" stroke="#CFC8B8" stroke-width="1.2" fill="none" opacity="0.7"/>' % [x, x + 4, x + 2]
	s += '<path d="M44 224 Q300 242 548 224" stroke="#F7B6C6" stroke-width="3.5" fill="none"/>'
	s += '<path d="M44 256 Q300 274 548 256" stroke="#F7B6C6" stroke-width="3" fill="none" opacity="0.8"/>'
	s += '<path d="M46 262 Q300 280 546 262 V272 Q300 290 46 272 Z" fill="#E9E5DA" stroke="#B8B2A2" stroke-width="1.8"/>'
	for x in [70.0, 520.0]:
		s += '<path d="M%s 270 V296" stroke="#C9C2B4" stroke-width="9" stroke-linecap="round"/><path d="M%s 270 V296" stroke="url(#iron)" stroke-width="6" stroke-linecap="round"/>' % [x, x]
	# The big pillow (a pillowcase with a sewn border and creases) and the little cushion.
	s += '<path d="M52 132 Q48 100 84 100 H196 Q222 100 220 134 Q220 166 194 168 H84 Q52 168 52 132 Z" fill="url(#pillow)" stroke="#9E86B5" stroke-width="2.6"/>'
	s += '<path d="M62 134 Q62 112 86 112 H194 Q210 112 210 134" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0.7" stroke-dasharray="4 5"/>'
	s += '<path d="M76 118 Q140 106 206 116" stroke="#FFFFFF" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.7"/>'
	s += '<path d="M96 150 Q140 140 188 150" stroke="#A58CC0" stroke-width="2" fill="none" opacity="0.6"/><path d="M120 128 Q140 138 168 132" stroke="#A58CC0" stroke-width="1.6" fill="none" opacity="0.5"/>'
	s += '<path d="M196 146 Q192 122 218 120 H288 Q312 122 310 148 Q310 172 288 174 H218 Q196 172 196 146 Z" fill="#FBDCE8" stroke="#C26A84" stroke-width="2.4"/>'
	s += '<path d="M208 138 Q240 126 292 130" stroke="#FFFFFF" stroke-width="4.5" fill="none" stroke-linecap="round" opacity="0.8"/>'
	s += '<path d="M250 132 q-8 -10 -16 -2 q-6 8 16 24 q22 -16 16 -24 q-8 -8 -16 2 Z" fill="#F08AAE" opacity="0.65"/>'
	# The duvet: scalloped hem at the front, the sheet turned over at the top, soft light from the left, quilted diamonds.
	s += '<path d="M56 176 Q90 150 200 158 Q380 142 546 158 L550 226 Q300 250 50 226 Z" fill="url(#duvet)" stroke="#C26A84" stroke-width="3"/>'
	s += '<path d="M56 176 Q90 150 200 158 Q380 142 546 158 L550 226 Q300 250 50 226 Z" fill="url(#duvet_v)"/>'
	s += '<path d="M54 206 Q64 226 78 214 Q92 232 108 218 Q122 236 138 222 Q154 240 170 224 Q186 242 202 226 Q218 244 234 228 Q250 246 266 229 Q282 247 298 230 Q314 247 330 230 Q346 246 362 229 Q378 244 394 227 Q410 242 426 225 Q442 238 458 222 Q474 234 490 218 Q506 228 522 213 Q538 220 550 208" fill="#EE8FA9" stroke="#C26A84" stroke-width="2.4"/>'
	for x in range(70, 540, 40):
		s += '<path d="M%d 176 L%d 196 L%d 216 M%d 176 L%d 196 L%d 216" stroke="#E07C9A" stroke-width="1.6" fill="none" stroke-dasharray="4 5" opacity="0.55"/>' % [x, x + 20, x, x + 40, x + 20, x + 40]
	s += '<path d="M64 168 Q200 146 340 154 Q440 148 548 156 L550 178 Q440 168 340 176 Q200 170 62 190 Z" fill="#FFFBF4" stroke="#D6CCC0" stroke-width="2"/>'
	s += '<path d="M64 180 Q200 160 340 168 Q440 162 548 170" stroke="#F2A7B9" stroke-width="2.2" fill="none" stroke-dasharray="3 4"/>'
	# Folds in the duvet over the sleeper's feet, and its shade on the sheet.
	s += '<path d="M340 178 Q356 196 348 218 M420 176 Q436 194 428 214 M270 182 Q282 198 276 216" stroke="#D56F8E" stroke-width="2.4" fill="none" opacity="0.55" stroke-linecap="round"/>'
	s += '<path d="M60 186 Q200 168 340 176 Q440 170 548 176" stroke="#B85A76" stroke-width="3" fill="none" opacity="0.18"/>'
	# The footboard: a lower iron rail with posts and finials.
	s += '<path d="M440 148 V296 M544 138 V296" stroke="#C9C2B4" stroke-width="10"/><path d="M440 148 V296 M544 138 V296" stroke="url(#iron)" stroke-width="7"/>'
	for x in [462.0, 484.0, 506.0, 526.0]:
		s += '<path d="M%s 152 V204" stroke="#C9C2B4" stroke-width="6"/><path d="M%s 152 V204" stroke="url(#iron)" stroke-width="4"/>' % [x, x]
	s += '<path d="M434 146 H548" stroke="#C9C2B4" stroke-width="10"/><path d="M434 146 H548" stroke="url(#iron)" stroke-width="7"/>'
	for fx in [440.0, 544.0]:
		s += '<circle cx="%s" cy="138" r="7" fill="#F4F0E6" stroke="#B8B2A2" stroke-width="1.8"/><circle cx="%s" cy="135" r="2.4" fill="#FFFFFF"/>' % [fx, fx - 2.0]
	# A plush bunny leaning on the pillows.
	s += '<ellipse cx="254" cy="150" rx="22" ry="15" fill="#FBD2DE" stroke="#C26A84" stroke-width="2.2"/><circle cx="276" cy="136" r="12" fill="#FBD2DE" stroke="#C26A84" stroke-width="2.2"/>'
	s += '<path d="M270 126 q-5 -22 2 -24 q7 2 5 24 M281 126 q3 -22 9 -22 q5 4 -2 24" fill="#FBD2DE" stroke="#C26A84" stroke-width="2.2"/>'
	s += '<path d="M272 118 q-1 -12 1 -14 M286 118 q2 -12 4 -12" stroke="#F08AAE" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
	s += '<circle cx="279" cy="135" r="1.9" fill="#2B2B2B"/><circle cx="287" cy="139" r="2" fill="#F08AAE"/>'
	s += '<circle cx="236" cy="152" r="6" fill="#FFFFFF" stroke="#E4B8C6" stroke-width="1.4"/>'
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
	var inner := '<rect width="170" height="118" fill="#F6EFD6"/>'
	for r in 4:
		for c in 5:
			if (r + c) % 2 == 0:
				inner += '<rect x="%d" y="%d" width="34" height="30" fill="#F2C12E" opacity="0.85"/>' % [c * 34, r * 30]
	inner += '<path d="M30 112 Q85 56 140 112 Z" fill="#3E8E5A"/><path d="M44 108 Q85 72 126 108" stroke="#5FB07A" stroke-width="2" fill="none"/>'
	for x in [54.0, 78.0, 100.0, 124.0]:
		inner += '<path d="M%s 100 v-14" stroke="#2F6A40" stroke-width="2"/>' % x
		for a in 5:
			var ang := TAU * a / 5.0
			inner += '<ellipse cx="%s" cy="%s" rx="6" ry="4" fill="#F2A7C9" stroke="#C0678F" stroke-width="0.8" transform="rotate(%s %s %s)"/>' % [x + cos(ang) * 6.0, 84.0 + sin(ang) * 6.0, rad_to_deg(ang), x + cos(ang) * 6.0, 84.0 + sin(ang) * 6.0]
		inner += '<circle cx="%s" cy="84" r="3.6" fill="#FFF0B0" stroke="#D8A93A" stroke-width="0.8"/>' % x
	return tex(190, 140, _framed("flower", 2.0, 2.0, 184.0, 134.0, "wood", inner, 8.0, 7.0, "#FBF7EA"))


## Canvas 120x160: strawberry poster on a pink checkerboard.
static func strawberry_poster() -> ImageTexture:
	var s := '<rect x="0" y="0" width="104" height="142" fill="#F7E0EA"/>'
	for r in 8:
		for c in 6:
			if (r + c) % 2 == 0:
				s += '<rect x="%d" y="%d" width="18" height="18" fill="#E9A3C3"/>' % [c * 18, r * 18]
	for p in [[44.0, 58.0, 24.0], [78.0, 84.0, 20.0]]:
		var cx: float = p[0]
		var top: float = p[1]
		var r: float = p[2]
		s += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="#D4243F" stroke="#8E1A2C" stroke-width="2"/>' % [
			cx - r, top, cx - r, top + r * 1.3, cx, top + r * 1.8, cx + r, top + r * 1.3, cx + r, top, cx, top - r * 0.35, cx - r, top]
		for k in 7:
			s += '<ellipse cx="%s" cy="%s" rx="1.6" ry="2.4" fill="#F7D774"/>' % [cx + [-12, 0, 12, -6, 6, -10, 10][k] * r / 24.0, top + [8, 6, 8, 20, 20, 30, 30][k] * r / 24.0]
		s += '<path d="M%s %s l-12 -4 l9 -3 l-2 -9 l7 7 l7 -7 l-2 9 l9 3 l-12 4 z" fill="#3E8E5A" stroke="#2A6A40" stroke-width="1.5"/>' % [cx, top + 2]
	return tex(124, 164, _framed("straw", 2.0, 2.0, 116.0, 156.0, "white", s, 7.0, 5.0, "#FFF6F8"))


## Canvas 170x250: three white picture-book ledges. Not flat rectangles: every book has its own height, width
## and colour, a cloth band top and bottom and a few marks of a title on its spine, some lean against the next,
## one shelf has a pile lying flat and another a book stood up with its cover showing (a sun over a hill, the way
## a picture book looks). Hung on the wall.
static func book_ledges() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var covers := ["#F2C12E", "#7E57C2", "#E04F5F", "#3E8E5A", "#1D4F91", "#FF8A3D", "#F2A7C9", "#1FB5C4",
		"#8D6E63", "#C0417A", "#5AA7E0", "#E8812E"]
	var s := ""
	for r in 3:
		var base := 70.0 + r * 80.0
		var x := 7.0
		var lean := 0.0
		# The books standing along the shelf, each leaning a little once in a while.
		while x < 118.0:
			var w := rng.randf_range(13.0, 24.0)
			var h := rng.randf_range(42.0, 66.0)
			var tilt := 0.0
			if lean == 0.0 and rng.randf() < 0.22:
				tilt = rng.randf_range(7.0, 13.0)
				lean = tilt
			elif lean > 0.0:
				tilt = 0.0
				lean = 0.0
			s += _book_spine(x, base, w, h, covers[rng.randi() % covers.size()], tilt, rng)
			x += w + (6.0 if tilt > 0.0 else 1.4)
		# The end of the shelf: a pile lying flat on two of them, a book with its cover out on the other.
		if r == 1:
			s += _book_cover(x + 6.0, base, covers[rng.randi() % covers.size()])
		else:
			s += _book_pile(x + 4.0, base, covers, rng)
		# The ledge itself, over the feet of the books so they really stand on it.
		s += '<rect x="2" y="%s" width="166" height="6" rx="2" fill="#FDFCF8" stroke="#C9C2B4" stroke-width="1.6"/>' % base
		s += '<rect x="2" y="%s" width="166" height="5" rx="2" fill="#E6E0D2" stroke="#C9C2B4" stroke-width="1.4"/>' % (base + 5.0)
		s += '<rect x="6" y="%s" width="158" height="4" rx="2" fill="#000000" opacity="0.07"/>' % (base + 11.0)
	return tex(170, 250, s)


# One book standing on a ledge: a cloth spine with a band top and bottom, the marks of a title, the pages showing
# down its side, and a rounded head on the hardbacks. `tilt` leans it against its neighbour.
static func _book_spine(x: float, base: float, w: float, h: float, hue: String, tilt: float, rng: RandomNumberGenerator) -> String:
	var top := base - h
	var s := '<g transform="rotate(%.1f %s %s)">' % [-tilt, x, base]
	var hard := rng.randf() < 0.55
	if hard:
		s += '<path d="M%s %s q%s -5 %s 0 v%s h-%s z" fill="%s" %s/>' % [
			x, top + 3.0, w * 0.5, w, h - 3.0, w, hue, _edge()]
	else:
		s += '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s" %s/>' % [x, top, w, h, hue, _edge()]
	# The pages, a sliver of cream down the right, and the shade the next book throws on it.
	s += '<rect x="%s" y="%s" width="3" height="%s" fill="#F7F2E4"/>' % [x + w - 3.5, top + 3.0, h - 5.0]
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="#000000" opacity="0.16"/>' % [x + w - 2.0, top + 2.0, 2.0, h - 3.0]
	s += '<rect x="%s" y="%s" width="2.4" height="%s" fill="#FFFFFF" opacity="0.22"/>' % [x + 1.4, top + 4.0, h - 7.0]
	# Two cloth bands and a few marks for the title.
	for band: float in [top + 7.0, base - 11.0]:
		s += '<rect x="%s" y="%s" width="%s" height="2.6" fill="#FFFFFF" opacity="0.4"/>' % [x, band, w]
	var lines := 2 + (1 if h > 54.0 else 0)
	for i in lines:
		var ty := top + 18.0 + i * 7.0
		s += '<rect x="%s" y="%.1f" width="%.1f" height="2" rx="1" fill="#FFFFFF" opacity="0.75"/>' % [
			x + 4.0, ty, maxf(w - 9.0 - (i * 2.0), 4.0)]
	s += '</g>'
	return s


# Two or three books lying flat at the end of a ledge, the pages of each showing.
static func _book_pile(x: float, base: float, covers: Array, rng: RandomNumberGenerator) -> String:
	var s := ""
	var y := base
	for i in 2 + (1 if rng.randf() < 0.5 else 0):
		var w: float = 40.0 - i * 5.0 - rng.randf_range(0.0, 4.0)
		var h := 7.0
		y -= h
		var hue: String = covers[rng.randi() % covers.size()]
		var at := x + rng.randf_range(-2.0, 3.0)
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%s" rx="2" fill="%s" %s/>' % [at, y, w, h, hue, _edge()]
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="2.6" fill="#F7F2E4"/>' % [at + 1.5, y + 2.4, w - 3.0]
		y -= 1.0
	return s


# A picture book stood up with its cover out, the way they are shown on a child's ledge.
static func _book_cover(x: float, base: float, hue: String) -> String:
	var w := 32.0
	var h := 44.0
	var top := base - h
	var s := '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s" %s/>' % [x, top, w, h, hue, _edge()]
	s += '<rect x="%s" y="%s" width="3" height="%s" fill="#FFFFFF" opacity="0.25"/>' % [x + 1.5, top + 3.0, h - 6.0]
	# Its picture: a sun over a hill, framed in cream.
	s += '<rect x="%s" y="%s" width="%s" height="18" rx="2" fill="#FDF8EC"/>' % [x + 4.0, top + 6.0, w - 8.0]
	s += '<circle cx="%s" cy="%s" r="4" fill="#F2C12E"/>' % [x + w - 10.0, top + 12.0]
	s += '<path d="M%s %s q7 -9 14 0 q6 -6 10 0 z" fill="#7CCB5A"/>' % [x + 4.0, top + 24.0]
	s += '<rect x="%s" y="%s" width="%s" height="3" rx="1.5" fill="#FFFFFF" opacity="0.8"/>' % [x + 6.0, top + 29.0, w - 12.0]
	s += '<rect x="%s" y="%s" width="%s" height="3" rx="1.5" fill="#FFFFFF" opacity="0.6"/>' % [x + 9.0, top + 35.0, w - 18.0]
	return s


static func _edge() -> String:
	return 'stroke="#3A332C" stroke-width="1.3" stroke-linejoin="round"'


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
	s += '<path d="M130 100 q10 -40 60 -36 q40 4 40 36 z" fill="#8FB5A0" stroke="#5E8A72" stroke-width="2"/>'
	s += '<path d="M160 100 q20 -30 60 -20 q30 10 30 20 z" fill="#F2B6CF" stroke="#B5647F" stroke-width="2"/>'
	s += '<path d="M120 100 q10 -30 40 -26 l20 26 z" fill="#F2D9A0" stroke="#B5A270" stroke-width="2"/>'
	# Red office chair with a white sweater over the back.
	s += '<path d="M40 40 Q40 20 70 20 H120 Q140 20 140 40 V130 H40 Z" fill="#D9343F" stroke="#8E1A24" stroke-width="3"/>'
	s += '<path d="M60 26 Q90 14 130 30 L126 120 Q100 136 70 120 Z" fill="#F1ECE2" stroke="#B9B4AA" stroke-width="2.5"/>'
	s += '<rect x="30" y="136" width="130" height="22" rx="8" fill="#D9343F" stroke="#8E1A24" stroke-width="3"/>'
	s += '<path d="M95 158 V220 M50 240 L95 220 L140 240 M95 220 V244" stroke="#8E9399" stroke-width="7" stroke-linecap="round"/>'
	for x in [50.0, 95.0, 140.0]:
		s += '<circle cx="%s" cy="250" r="8" fill="#3A3A3A"/>' % x
	return tex(360, 260, s)


## Canvas 112x64: her school exercise book lying open-corner on the desk with a pencil across it, seen from the
## side the way everything on a desk is. The desk's top is at y 64.
static func homework_book() -> ImageTexture:
	# Two sheets poking out, then the blue cover over them.
	var s := '<path d="M14 54 L34 38 H102 L82 54 Z" fill="#FDFBF4" stroke="#C9C2B4" stroke-width="1.6"/>'
	s += '<path d="M10 58 L30 42 H98 L78 58 Z" fill="#FBF6EA" stroke="#C9C2B4" stroke-width="1.6"/>'
	s += '<path d="M8 52 L28 36 H96 L76 52 Z" fill="#8FB7D9" stroke="#3E6F99" stroke-width="2"/>'
	# The white label, with three lines of her writing on it.
	s += '<path d="M28 48 L40 38 H74 L62 48 Z" fill="#FDFBF4" stroke="#B8B0A0" stroke-width="1.4"/>'
	for i in 3:
		s += '<path d="M%s %s L%s %s" stroke="#9FB4C8" stroke-width="1.2"/>' % [34 + i * 2, 46 - i * 2.6, 64 + i * 2, 46 - i * 2.6]
	# A yellow pencil laid across the cover, lead end to the left.
	s += '<path d="M30 30 L84 18 L86 25 L32 37 Z" fill="#F2C14E" stroke="#B58A24" stroke-width="1.6"/>'
	s += '<path d="M30 30 L22 32 L32 37 Z" fill="#F3DCC0" stroke="#B58A24" stroke-width="1.4"/>'
	s += '<path d="M24 31.5 L22 32 L25 33.5 Z" fill="#3A3A3A"/>'
	s += '<path d="M84 18 L86 25 L92 23.6 L90 16.6 Z" fill="#E88CA6" stroke="#B5647F" stroke-width="1.4"/>'
	return tex(112, 64, s)


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

## Canvas w x h: a sash window with its white trim, sheer curtains and a real view out over the back lane — the
## season's sky, the neighbours' brick back across the lane with their windows, gallery and downpipe, the yard tree
## and the board fence, birds on the wire. On Halloween night (`Halloween.night()`) it is the evening out there:
## a deep blue sky with the moon and the stars, the neighbours' windows warm, a jack-o-lantern on their gallery
## and a bat going by.
static func window(w: float, h: float) -> ImageTexture:
	var night := Halloween.night()
	var s := _defs()
	var gx := 16.0
	var gy := 16.0
	var gw := w - 32.0
	var gh := h - 46.0
	s += '<defs><clipPath id="pane"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>' % [gx, gy, gw, gh]
	# The sky of the hour, as a gradient of its own.
	if night:
		s += ('<linearGradient id="view_sky" x1="0" y1="0" x2="0" y2="1">'
			+ '<stop offset="0" stop-color="#101A3A"/><stop offset="0.55" stop-color="#1E2C54"/>'
			+ '<stop offset="1" stop-color="#36406A"/></linearGradient></defs>')
	else:
		var sky := Season.sky()
		s += ('<linearGradient id="view_sky" x1="0" y1="0" x2="0" y2="1">'
			+ '<stop offset="0" stop-color="#%s"/><stop offset="0.5" stop-color="#%s"/>'
			+ '<stop offset="1" stop-color="#%s"/></linearGradient></defs>') % [
				sky[0].to_html(false), sky[2].to_html(false), sky[3].to_html(false)]
	s += '<g clip-path="url(#pane)">'
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="url(#view_sky)"/>' % [gx, gy, gw, gh]
	s += _view(gx, gy, gw, gh, night)
	s += "</g>"
	s += _window_frame(w, h, night)
	return tex(w, h, s)


## Only the frame of `window(w, h)`, its bars, sill, glare and curtains, on a clear sheet: laid over the window so whatever
## falls outside (the winter's snow, `Interior._window_snow`) passes behind them.
static func window_frame(w: float, h: float) -> ImageTexture:
	return tex(w, h, _defs() + _window_frame(w, h, Halloween.night()))


## Where the glass of `window(w, h)` is, in its picture.
static func window_glass(w: float, h: float) -> Rect2:
	return Rect2(16.0, 16.0, w - 32.0, h - 46.0)


static func _window_frame(w: float, h: float, night: bool) -> String:
	var gy := 16.0
	var gw := w - 32.0
	var gh := h - 46.0
	var s := ""
	# The frame round the glass, its bars, the sash and the sill.
	s += '<path d="M0 0 H%s V16 H0 Z M0 %s H%s V%s H0 Z M0 16 H16 V%s H0 Z M%s 16 H%s V%s H%s Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [
		w, gy + gh, w, h, gy + gh, w - 16.0, w, gy + gh, w - 16.0, TRIM, TRIM_DARK]
	s += '<rect x="%s" y="16" width="8" height="%s" fill="%s"/>' % [w / 2 - 4, gh, TRIM]
	s += '<rect x="16" y="%s" width="%s" height="8" fill="%s"/>' % [h * 0.45, gw, TRIM]
	s += '<path d="M20 20 L%s 20 L30 %s L20 %s Z" fill="#FFFFFF" opacity="%s"/>' % [w * 0.4, h * 0.6, h * 0.6, 0.18 if night else 0.35]
	s += '<rect x="-6" y="%s" width="%s" height="16" fill="%s" stroke="%s" stroke-width="2"/>' % [h - 30, w + 12, TRIM, TRIM_DARK]
	# Sheer curtains gathered at the sides.
	for side in [0, 1]:
		var x0 := 4.0 if side == 0 else w - 4.0
		var dir := 1.0 if side == 0 else -1.0
		s += '<path d="M%s 4 h%s q%s %s %s %s h%s z" fill="#FBF7EE" opacity="0.8" stroke="#E3DACB" stroke-width="1.5"/>' % [x0, dir * w * 0.22, -dir * w * 0.12, h * 0.5, dir * w * 0.02, h - 34, -dir * w * 0.12]
		for k in 3:
			s += '<path d="M%s 8 q%s %s 0 %s" stroke="#E3DACB" stroke-width="1.5" fill="none"/>' % [x0 + dir * (10 + k * 10), dir * 6, h * 0.4, h - 44]
	s += '<rect x="-10" y="0" width="%s" height="6" rx="3" fill="#B08A5A"/>' % (w + 20)
	return s


# What is out there, inside the glass: the lane behind the house. Everything is laid out on the pane's own
# rectangle, so the same view fits any window.
static func _view(x: float, y: float, w: float, h: float, night: bool) -> String:
	var s := ""
	var horizon := y + h * 0.24
	var ground := y + h * 0.80
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	if night:
		# The moon over the lane, and the stars.
		for i in 26:
			var sx := x + rng.randf_range(2.0, w - 2.0)
			var sy := y + rng.randf_range(2.0, h * 0.22)
			s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFF6D8" opacity="%.2f"/>' % [sx, sy, rng.randf_range(0.7, 1.5), rng.randf_range(0.4, 0.95)]
		var mx := x + w * 0.74
		var my := y + h * 0.09
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFF6D8" opacity="0.14"/>' % [mx, my, w * 0.22]
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FDF6DC"/>' % [mx, my, w * 0.085]
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#E8E0C4" opacity="0.7"/>' % [mx - w * 0.025, my - w * 0.02, w * 0.02]
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#E8E0C4" opacity="0.6"/>' % [mx + w * 0.03, my + w * 0.02, w * 0.024]
		# A bat crossing in front of the moon.
		var bx := x + w * 0.42
		var by := y + h * 0.17
		s += '<path d="M%.1f %.1f l-13 -5 l10 2 l-7 -8 l13 7 l6 -3 l6 3 l13 -7 l-7 8 l10 -2 l-13 5 z" fill="#161528" opacity="0.9"/>' % [bx, by]
	else:
		# A few soft clouds.
		for i in 3:
			var cx := x + w * (0.12 + i * 0.36) + rng.randf_range(-6.0, 6.0)
			var cy := y + h * rng.randf_range(0.03, 0.14)
			var cr := w * rng.randf_range(0.09, 0.14)
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFFFFF" opacity="0.75"/>' % [cx, cy, cr, cr * 0.5]
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFFFFF" opacity="0.65"/>' % [cx + cr * 0.7, cy + cr * 0.12, cr * 0.7, cr * 0.4]
	# The neighbours' back across the lane: a brick duplex, one flat over the other, each with its own door, the
	# gallery running along the upper floor and the stair coming down from it into the yard.
	var wall := "#7E4536" if night else "#A85C3E"
	var wall_dark := "#5E3327" if night else "#8A4530"
	var mortar := "#4E2A20" if night else "#7A3D2A"
	var iron := "#2E2E36" if night else "#3A3A42"
	var wood := "#4E3A2E" if night else "#6E5444"
	var wall_h := ground - horizon
	var floor_y := horizon + wall_h * 0.48
	s += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [x, horizon, w, wall_h + 2.0, wall]
	# Brick: the courses, and the heads staggered row by row so it reads as brick and not as stripes.
	var course := horizon + 6.0
	var row := 0
	while course < ground:
		s += '<path d="M%s %.1f H%s" stroke="%s" stroke-width="1.2" opacity="0.5"/>' % [x, course, x + w, mortar]
		var head := x - (w * 0.045 if row % 2 == 1 else 0.0)
		while head < x + w:
			s += '<path d="M%.1f %.1f v7" stroke="%s" stroke-width="1" opacity="0.32"/>' % [head, course, mortar]
			head += w * 0.09
		course += 7.0
		row += 1
	# The cornice along the roof, and the band of the floor between the two flats.
	s += '<rect x="%s" y="%s" width="%s" height="7" fill="%s"/>' % [x, horizon, w, wall_dark]
	s += '<rect x="%s" y="%s" width="%s" height="4" fill="#FFFFFF" opacity="%s"/>' % [x, horizon - 4.0, w, 0.12 if night else 0.3]
	s += '<rect x="%s" y="%.1f" width="%s" height="3" fill="%s" opacity="0.6"/>' % [x, floor_y - wall_h * 0.03, w, wall_dark]
	# The downpipe down the corner, from the cornice to the ground.
	s += '<rect x="%.1f" y="%s" width="5" height="%.1f" fill="%s"/>' % [x + w * 0.005, horizon, wall_h, wood]
	# One door and one window per flat: that is what says duplex, a home on each floor.
	var door_w := w * 0.19
	var door_h := wall_h * 0.37
	s += _view_pane(x + w * 0.44, horizon + wall_h * 0.1, w * 0.3, wall_h * 0.27, night)
	s += _view_door(x + w * 0.09, floor_y - door_h, door_w, door_h, night)
	s += _view_pane(x + w * 0.44, floor_y + wall_h * 0.08, w * 0.3, wall_h * 0.27, night)
	# Under the gallery it is in the shade, and that is where the ground-floor door is.
	s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" fill="#1A1008" opacity="%s"/>' % [x, floor_y, w, ground - floor_y, 0.3 if night else 0.22]
	s += _view_door(x + w * 0.09, ground - door_h, door_w, door_h, night)
	# The posts holding the gallery up, then its slab.
	for px: float in [0.33, 0.88]:
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>' % [x + w * px, floor_y, w * 0.035, ground - floor_y, wood]
	s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" fill="%s"/>' % [x, floor_y, w, wall_h * 0.055, "#6E6A64" if night else "#CFC7B6"]
	s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" fill="#1A1008" opacity="0.35"/>' % [x, floor_y + wall_h * 0.055, w, wall_h * 0.015]
	var winter := Season.is_winter()
	if winter:
		# Snow piled along the gallery's edge.
		s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" rx="2" fill="#F4F7FA"/>' % [x, floor_y - wall_h * 0.02, w, wall_h * 0.035]
	# The stair: a sloped beam out of the gallery, its treads, and the handrail above them.
	var st_x := x + w * 0.4
	var st_y := floor_y
	var sf_x := x + w * 0.96
	var rise := ground - floor_y
	var run := sf_x - st_x
	s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="%.1f" stroke-linecap="square" fill="none"/>' % [
		st_x, st_y + wall_h * 0.06, sf_x, ground, iron, wall_h * 0.05]
	for i in 7:
		var tt := float(i) / 7.0
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="3" fill="%s"/>' % [
			st_x + run * tt, st_y + wall_h * 0.055 + rise * tt, run / 7.0 + 2.0, "#8A857A" if night else "#C8C0AE"]
	var hr := wall_h * 0.22
	s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="2.5" fill="none"/>' % [st_x, st_y - hr, sf_x, ground - hr, iron]
	for i in 6:
		var bt := (float(i) + 0.5) / 6.0
		s += '<path d="M%.1f %.1f v%.1f" stroke="%s" stroke-width="1.6"/>' % [
			st_x + run * bt, st_y - hr + rise * bt, hr, iron]
	# The gallery rail, along the part of the floor the stair does not take.
	var rail := floor_y - wall_h * 0.24
	for ry: float in [0.0, 0.2]:
		s += '<rect x="%s" y="%.1f" width="%.1f" height="3" fill="%s"/>' % [x, rail + wall_h * ry, w * 0.4, iron]
	var bar := x + 3.0
	while bar < x + w * 0.4:
		s += '<rect x="%.1f" y="%.1f" width="2" height="%.1f" fill="%s"/>' % [bar, rail, wall_h * 0.24, iron]
		bar += w * 0.045
	if night:
		# A jack-o-lantern on their gallery.
		var px := x + w * 0.22
		var py := rail - w * 0.03
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFB347" opacity="0.28"/>' % [px, py, w * 0.11]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#E8812E" stroke="#B5651A" stroke-width="1.5"/>' % [px, py, w * 0.045, w * 0.037]
		s += '<path d="M%.1f %.1f l%.1f -%.1f l%.1f %.1f z" fill="#FFE07A"/>' % [px - w * 0.028, py - w * 0.002, w * 0.014, w * 0.016, w * 0.014, w * 0.016]
		s += '<path d="M%.1f %.1f l%.1f -%.1f l%.1f %.1f z" fill="#FFE07A"/>' % [px + w * 0.001, py - w * 0.002, w * 0.014, w * 0.016, w * 0.014, w * 0.016]
		s += '<path d="M%.1f %.1f q%.1f %.1f %.1f 0 z" fill="#FFE07A"/>' % [px - w * 0.026, py + w * 0.012, w * 0.026, w * 0.024, w * 0.052]
	# The lane itself, then the board fence at the bottom of the yard.
	s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" fill="%s"/>' % [x, ground, w, y + h - ground, "#3E4152" if night else ("#E8EEF4" if winter else "#8E9A7A")]
	s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" fill="%s" opacity="0.5"/>' % [x, ground, w, h * 0.03, "#4C5068" if night else ("#FFFFFF" if winter else "#A3AE8A")]
	if winter:
		# The yard under snow: soft drifts against their wall, footprints to the stair.
		for i in 4:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#F6F9FC"/>' % [x + w * (0.1 + i * 0.27), ground + 2.0, w * 0.16, h * 0.022]
		for i in 5:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="2.2" ry="1.2" fill="#C9D3DE"/>' % [x + w * (0.55 + i * 0.08), ground + h * (0.03 + (i % 2) * 0.012)]
	# The yard tree, in front of it all: a tapering trunk, three limbs, clumps of real leaves.
	s += _view_tree(x + w * 0.78, ground + h * 0.06, w * 0.62, h * 0.52, night)
	var board := x
	var fence_top := y + h * 0.86
	while board < x + w:
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="2" fill="%s" stroke="%s" stroke-width="1"/>' % [
			board, fence_top, w * 0.062, y + h - fence_top, "#4A4030" if night else "#9A7A4E", "#3A3024" if night else "#7E6038"]
		board += w * 0.072
	s += '<rect x="%s" y="%.1f" width="%s" height="4" fill="%s"/>' % [x, fence_top, w, "#3A3024" if night else "#7E6038"]
	if winter:
		# A cap of snow along the fence's top.
		s += '<rect x="%s" y="%.1f" width="%s" height="%.1f" rx="3" fill="#F6F9FC"/>' % [x, fence_top - 4.0, w, 7.0]
	if not night:
		# Birds on the wire, by day.
		s += '<path d="M%s %.1f Q%.1f %.1f %s %.1f" stroke="#3A3A42" stroke-width="1.6" fill="none"/>' % [
			x, y + h * 0.145, x + w * 0.5, y + h * 0.195, x + w, y + h * 0.135]
		for i in 3:
			var bx := x + w * (0.22 + i * 0.22)
			var by := y + h * (0.172 - i * 0.004)
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#4A4A55"/>' % [bx, by - 3.0, w * 0.022, w * 0.016]
			s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#4A4A55"/>' % [bx + w * 0.018, by - 5.5, w * 0.012]
	return s


# One of their windows, seen across the lane: its casing, a dark pane by day and a warm room tonight.
static func _view_pane(x: float, y: float, w: float, h: float, night: bool) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#E8E2D4" stroke="#C2B8A6" stroke-width="2"/>' % [
		x - 3.0, y - 3.0, w + 6.0, h + 6.0]
	if night:
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFCE70"/>' % [x, y, w, h]
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#FFE7B4"/>' % [x + w * 0.2, y, w * 0.6, h * 0.6]
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#B5692A" opacity="0.5"/>' % [x, y, w * 0.26, h]
	else:
		s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#4E6B7A"/>' % [x, y, w, h]
		s += '<path d="M%.1f %.1f l%.1f 0 l-%.1f %.1f l-%.1f 0 z" fill="#FFFFFF" opacity="0.2"/>' % [
			x + w * 0.45, y, w * 0.3, w * 0.35, h, w * 0.3]
	s += '<path d="M%.1f %.1f v%.1f M%.1f %.1f h%.1f" stroke="#E8E2D4" stroke-width="2"/>' % [
		x + w * 0.5, y, h, x, y + h * 0.45, w]
	return s


# One of their back doors: a painted door with its glass, a knob and a step, standing on the gallery or in the yard.
static func _view_door(x: float, y: float, w: float, h: float, night: bool) -> String:
	var s := '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#E8E2D4" stroke="#C2B8A6" stroke-width="2"/>' % [
		x - 3.0, y - 3.0, w + 6.0, h + 6.0]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>' % [x, y, w, h, "#2E4A3A" if night else "#43684F"]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>' % [
		x + w * 0.16, y + h * 0.08, w * 0.68, h * 0.4, "#FFD98A" if night else "#5E7F8C"]
	s += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="none" stroke="%s" stroke-width="1.5" opacity="0.6"/>' % [
		x + w * 0.16, y + h * 0.56, w * 0.68, h * 0.34, "#20362A"]
	s += '<circle cx="%.1f" cy="%.1f" r="2" fill="#C9A227"/>' % [x + w * 0.84, y + h * 0.54]
	return s


# The tree in the yard next door, seen through the window: a tapering trunk, three limbs and clumps of leaves in
# the season's colours (bare and snowy in winter, a silhouette at night).
static func _view_tree(cx: float, foot: float, w: float, h: float, night: bool) -> String:
	var trunk := "#2A2438" if night else "#5E4636"
	var s := '<path d="M%.1f %.1f q-%.1f -%.1f -%.1f -%.1f l%.1f 0 q%.1f %.1f %.1f %.1f z" fill="%s"/>' % [
		cx - w * 0.035, foot, w * 0.004, h * 0.4, w * 0.012, h * 0.62, w * 0.07, w * 0.008, h * 0.22, w * 0.012, h * 0.62, trunk]
	for limb: Array in [[-1.0, 0.34, 0.46], [1.0, 0.3, 0.52], [-0.6, 0.18, 0.64]]:
		s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="%.1f" fill="none" stroke-linecap="round"/>' % [
			cx, foot - h * float(limb[2]) * 0.7, cx + w * 0.07 * float(limb[0]), foot - h * (float(limb[2]) + 0.06),
			cx + w * float(limb[1]) * float(limb[0]), foot - h * (float(limb[2]) + 0.14), trunk, w * 0.022]
	if Season.current == "winter" and not night:
		for twig: Array in [[-0.3, 0.72], [0.28, 0.78], [-0.12, 0.84], [0.1, 0.9]]:
			s += '<path d="M%.1f %.1f l%.1f -%.1f" stroke="%s" stroke-width="%.1f" fill="none" stroke-linecap="round"/>' % [
				cx, foot - h * float(twig[1]), w * 0.16 * float(twig[0]), h * 0.1, trunk, w * 0.012]
		for cap: Array in [[-0.2, 0.8, 0.1], [0.22, 0.86, 0.09], [0.0, 0.94, 0.11]]:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#F2F5F8" opacity="0.9"/>' % [
				cx + w * float(cap[0]), foot - h * float(cap[1]), w * float(cap[2]), w * float(cap[2]) * 0.45]
		return s
	var leaves := Season.foliage()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var clumps := [[-0.3, 0.74, 0.17], [0.26, 0.8, 0.19], [-0.1, 0.93, 0.18], [0.12, 0.66, 0.14], [-0.34, 0.9, 0.13]]
	for i in clumps.size():
		var c: Array = clumps[i]
		var ccx := cx + w * float(c[0])
		var ccy := foot - h * float(c[1])
		var cr := w * float(c[2])
		var tone: String = "#1C2038" if night else "#" + leaves[i % leaves.size()].darkened(0.3).to_html(false)
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [ccx, ccy, cr, cr * 0.82, tone]
		if night:
			continue
		# Real leaves over the shade, lit from the upper left, turned outward.
		for k in 16:
			var a := rng.randf_range(0.0, TAU)
			var d := cr * sqrt(rng.randf()) * 0.95
			var lx := ccx + cos(a) * d
			var ly := ccy + sin(a) * d * 0.82
			var ls := cr * rng.randf_range(0.22, 0.34)
			var col: Color = leaves[rng.randi() % leaves.size()]
			if lx < ccx and ly < ccy:
				col = col.lightened(0.14)
			s += '<path d="M%.1f %.1f q%.1f -%.1f %.1f -%.1f q-%.1f %.1f -%.1f %.1f z" fill="#%s" transform="rotate(%.0f %.1f %.1f)"/>' % [
				lx, ly, ls * 0.75, ls * 0.4, ls * 1.5, ls * 0.1, ls * 0.75, ls * 0.5, ls * 1.5, ls * 0.1,
				col.to_html(false), rad_to_deg(a), lx, ly]
	return s


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


## Where the soil is in a house_plant's canvas (where the water should land).
static func plant_soil(kind: String) -> Vector2:
	var h := {"monstera": 330, "pothos": 420, "fern": 360, "fiddle": 420, "lily": 260}[kind] as int
	return Vector2(120, h - {"monstera": 80, "pothos": 130, "fern": 110, "fiddle": 76, "lily": 66}[kind] as int)


## A house plant to water, healthy or thirsty (drooping, yellowed, brown tips, dry cracked soil, a few dead leaves
## fallen by the pot). Canvas 240 wide, the pot centred, floor (or, hanging, the basket's bottom) at the canvas
## bottom: "monstera" 240x330, "pothos" (in a woven basket on a little stool, vines trailing) 240x420, "fern" (on a low wooden
## stool) 240x360, "fiddle" (fiddle-leaf fig) 240x420, "lily" (peace lily) 240x260.
static func house_plant(kind: String, thirsty: bool) -> ImageTexture:
	var t := 1.0 if thirsty else 0.0
	var leaf := Color("#3E8E4A").lerp(Color("#A59A45"), t * 0.85)
	var line := Color("#245E2E").lerp(Color("#6E5A2A"), t)
	var h := {"monstera": 330, "pothos": 420, "fern": 360, "fiddle": 420, "lily": 260}[kind] as int
	var cx := 120.0
	var s := ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"monstera":
			var soil := Vector2(cx, h - 82.0)
			for l in [[-0.12, 140.0, 0.85], [-0.6, 112.0, 0.8], [0.55, 116.0, 0.82], [-0.95, 80.0, 0.72], [0.9, 84.0, 0.75], [0.18, 100.0, 0.8]]:
				var a: float = l[0] + signf(l[0] + 0.01) * t * 0.6
				var stem_end := soil + Vector2(sin(a), -cos(a)) * float(l[1]) * (1.0 - t * 0.35)
				var droop := signf(l[0] + 0.01) * t * 1.3
				s += '<path d="M%s %s Q%s %s %s %s" stroke="%s" stroke-width="4" fill="none"/>' % [soil.x, soil.y,
					soil.x + sin(a) * 30.0, soil.y - 60.0 * (1.0 - t * 0.5), stem_end.x, stem_end.y, _hex(line)]
				s += _curved_leaf(stem_end, a + droop * 0.5, 82.0 * float(l[2]), 34.0 * float(l[2]), droop * 0.6, leaf, line, t, "split")
			s += _pot(cx, h, 92.0, 80.0, "#C2693F", "#7E3E22", t)
		"pothos":
			# A little wooden stool under a woven basket; a mound of big heart-shaped leaves (some marbled with cream) at its
			# rim, and long vines spilling over the edge and trailing down, a leaf every so often.
			var rim := h - 130.0
			s += '<ellipse cx="%s" cy="%s" rx="62" ry="5" fill="#000000" opacity="0.14"/>' % [cx, h - 3.0]
			s += '<rect x="%s" y="%s" width="116" height="10" rx="3" fill="#A8743E" stroke="#6E4520" stroke-width="2"/>' % [cx - 58, h - 66]
			s += '<rect x="%s" y="%s" width="116" height="3" rx="1.5" fill="#D0A06A" opacity="0.7"/>' % [cx - 58, h - 66]
			for lx in [cx - 48, cx + 40]:
				s += '<path d="M%s %s L%s %s" stroke="#8E5E2E" stroke-width="7" stroke-linecap="round"/>' % [lx + 4, h - 56, lx + (-4 if lx < cx else 12), h - 4]
			s += '<path d="M%s %s H%s" stroke="#8E5E2E" stroke-width="4"/>' % [cx - 46, h - 24, cx + 50]
			# The vines behind the basket's front (those that hang down the back), then the basket, then the mound and the front vines.
			var vines := [[-50.0, -1.0, 96.0], [-30.0, 1.0, 150.0], [-8.0, -1.0, 110.0], [16.0, 1.0, 82.0], [34.0, -1.0, 168.0], [52.0, 1.0, 120.0]]
			for pass_i in 2:
				if pass_i == 1:
					# The basket: a flared weave with a rolled rim, criss-crossed straw and a darker shade at its foot.
					s += '<path d="M%s %s H%s L%s %s H%s Z" fill="#D9C9A8" stroke="#9A8660" stroke-width="3" stroke-linejoin="round"/>' % [cx - 52, rim, cx + 52, cx + 40, rim + 66, cx - 40]
					for k in 6:
						var y := rim + 8.0 + k * 10.0
						var inset := k * 2.0
						s += '<path d="M%s %s H%s" stroke="#B9A580" stroke-width="1.6"/>' % [cx - 50 + inset, y, cx + 50 - inset]
					for k in 9:
						var x := cx - 46.0 + k * 11.5
						s += '<path d="M%s %s l6 10 M%s %s l-6 10" stroke="#C4B08A" stroke-width="1.3" opacity="0.8"/>' % [x, rim + 4.0, x + 6.0, rim + 4.0]
					s += '<path d="M%s %s H%s L%s %s H%s Z" fill="#7A6238" opacity="0.18"/>' % [cx - 44, rim + 50, cx + 44, cx + 40, rim + 66, cx - 40]
					s += '<rect x="%s" y="%s" width="108" height="8" rx="4" fill="#E8DABA" stroke="#9A8660" stroke-width="2"/>' % [cx - 54, rim - 4.0]
					s += '<path d="M%s %s H%s" stroke="#FFFFFF" stroke-width="1.6" opacity="0.6"/>' % [cx - 46, rim - 1.0, cx + 20]
					s += _soil(cx, rim, 48.0, t)
					# The mound: leaves of different sizes round the soil, the low outer ones leaning out, the inner ones standing up.
					for ring in 2:
						var count := 11 if ring == 0 else 7
						for k in count:
							var spread := 1.45 if ring == 0 else 0.7
							var a: float = lerpf(-spread, spread, k / float(count - 1)) + rng.randf_range(-0.07, 0.07)
							var length := (34.0 if ring == 0 else 38.0) + rng.randf_range(-4.0, 6.0)
							var base := Vector2(cx + sin(a) * (30.0 if ring == 0 else 14.0), rim - 2.0 - ring * 6.0)
							var mark := (k * 3 + ring) % 4 == 0
							s += _curved_leaf(base, a * (1.0 + t * 0.4) + signf(a) * t * 0.45, length + 14.0 * ring, length * 0.95, signf(a) * (0.1 + t * 0.7), leaf.lerp(Color("#CFE0A0"), 0.45) if mark else leaf.lerp(Color("#2F7A3E"), 0.28 * float(ring)), line, t, "heart")
				for v in vines:
					var is_back: bool = float(v[1]) < 0.0
					if is_back != (pass_i == 0):
						continue
					var x0: float = cx + float(v[0])
					var side: float = signf(float(v[0]) + 0.01)
					var length: float = float(v[2]) * (1.0 - t * 0.2)
					var pts: Array[Vector2] = []
					for k in 11:
						var q := k / 10.0
						pts.append(Vector2(x0 + side * (sin(q * 2.6) * 12.0 + q * 14.0), rim + 6.0 + q * length))
					var path := "M%s %s" % [pts[0].x, pts[0].y]
					for pt in pts.slice(1):
						path += " L%s %s" % [pt.x, pt.y]
					s += '<path d="%s" stroke="%s" stroke-width="2.4" fill="none" stroke-linecap="round"/>' % [path, _hex(line)]
					for k in range(2, pts.size()):
						if k % 2 == 1 and k < pts.size() - 1:
							continue
						var qq := k / 10.0
						var turn := 1.0 if (k / 2) % 2 == 0 else -1.0
						var size := lerpf(32.0, 20.0, qq)
						var ang := PI + turn * (0.85 + t * 0.4) + sin(k * 2.1) * 0.2
						s += _curved_leaf(pts[k], ang, size, size * 0.7, -turn * t * 0.6, leaf.lerp(Color("#CFE0A0"), 0.4) if (k + int(float(v[0]))) % 5 == 0 else leaf, line, t, "heart")
		"fern":
			# Wooden plant stand, then fronds arching out of the pot (hanging limp when thirsty).
			s += '<rect x="%s" y="%s" width="120" height="12" rx="3" fill="#A8743E" stroke="#6E4520" stroke-width="2"/>' % [cx - 60, h - 50]
			for lx in [cx - 52, cx + 44]:
				s += '<path d="M%s %s L%s %s" stroke="#8E5E2E" stroke-width="8" stroke-linecap="round"/>' % [lx + 4, h - 40, lx + (-6 if lx < cx else 14), h - 4]
			s += '<path d="M%s %s H%s" stroke="#8E5E2E" stroke-width="5"/>' % [cx - 50, h - 20, cx + 52]
			var soil := Vector2(cx, h - 114.0)
			for k in 11:
				var a := lerpf(-1.35, 1.35, k / 10.0) + rng.randf_range(-0.08, 0.08)
				var bend := signf(a) * (0.5 + t * 1.6) + a * 0.3
				s += _frond(soil, a * (1.0 - t * 0.1), 120.0 + rng.randf_range(-20, 20) - absf(a) * 18.0, bend, leaf, line, t)
			s += _pot(cx, h - 50.0, 84.0, 64.0, "#F2EEE6", "#A9A296", t)
		"fiddle":
			# A thin trunk with big violin-shaped leaves along it, the top ones upright, the rest hanging when dry.
			var base := Vector2(cx, h - 78.0)
			var top := Vector2(cx + 6.0, 80.0 + t * 20.0)
			s += '<path d="M%s %s Q%s %s %s %s" stroke="#7A5A3A" stroke-width="7" fill="none" stroke-linecap="round"/>' % [base.x, base.y, cx - 8, (base.y + top.y) / 2.0, top.x, top.y]
			for k in 9:
				var q := 0.25 + k * 0.085
				var at := base.lerp(top, q) + Vector2(sin(q * 5.0) * -4.0, 0)
				var side := 1.0 if k % 2 == 0 else -1.0
				var a := side * (1.25 - q * 0.5) + side * t * (1.2 - q * 0.5)
				var brown := t > 0.0 and k % 3 == 0
				s += _curved_leaf(at, a, 74.0 - q * 18.0, 40.0 - q * 8.0, side * t * 0.5, leaf.lerp(Color("#8E6A34"), 0.5 if brown else 0.0), line, t, "fiddle")
			s += _curved_leaf(top, 0.1, 50.0, 26.0, t * 1.2, leaf, line, t, "fiddle")
			s += _pot(cx, h, 96.0, 78.0, "#5E7E9A", "#36506A", t)
		"lily":
			# Peace lily: glossy dark leaves and white spathes; the textbook thirsty plant, flat over its pot.
			var soil := Vector2(cx, h - 74.0)
			for k in 9:
				var a := lerpf(-1.1, 1.1, k / 8.0) + rng.randf_range(-0.1, 0.1)
				var bend := signf(a) * t * 1.9 + a * 0.2
				s += '<path d="M%s %s Q%s %s %s %s" stroke="%s" stroke-width="3" fill="none"/>' % [soil.x, soil.y, soil.x + sin(a) * 20.0, soil.y - 50.0 * (1.0 - t * 0.6),
					soil.x + sin(a + bend * 0.5) * 70.0 * (1.0 - t * 0.2), soil.y - cos(a + bend * 0.5) * 70.0, _hex(line)]
				s += _curved_leaf(soil + Vector2(sin(a + bend * 0.5), -cos(a + bend * 0.5)) * 70.0 * Vector2(1.0 - t * 0.2, 1.0), a + bend * 0.7, 70.0, 26.0, bend * 0.4, leaf.darkened(0.12), line, t, "leaf")
			for k in 3:
				var a := -0.35 + k * 0.35
				var bend := (t * 2.0 if a >= 0.0 else -t * 2.0) + a * 0.2
				var tip := soil + Vector2(sin(a + bend * 0.4), -cos(a + bend * 0.4)) * 130.0 * (1.0 - t * 0.35)
				s += '<path d="M%s %s Q%s %s %s %s" stroke="%s" stroke-width="2.5" fill="none"/>' % [soil.x, soil.y, soil.x + sin(a) * 20.0, soil.y - 80.0 * (1.0 - t * 0.6), tip.x, tip.y, _hex(line)]
				s += _curved_leaf(tip, a + bend * 0.8, 40.0, 22.0, bend * 0.3, Color("#F7F6F0").lerp(Color("#D8CFA0"), t * 0.6), Color("#B9B6A8"), 0.0, "leaf")
				s += '<ellipse cx="%s" cy="%s" rx="3" ry="9" fill="#F2E7A8" transform="rotate(%s %s %s)"/>' % [tip.x, tip.y - 10.0, rad_to_deg(a + bend * 0.8), tip.x, tip.y]
			s += _pot(cx, h, 86.0, 70.0, "#E8E4DA", "#A8A296", t)
	# Fallen dead leaves on the floor by the pot.
	if thirsty and kind != "pothos":
		for k in 3:
			var fx: float = cx + [-70.0, 58.0, 82.0][k]
			s += '<ellipse cx="%s" cy="%s" rx="9" ry="3.5" fill="#9A6A30" stroke="#6E4520" stroke-width="1.5" transform="rotate(%s %s %s)"/>' % [fx, h - 4.0, [-12, 18, -6][k], fx, h - 4.0]
	return tex(240, h, s)


# A leaf along a curved midrib, from `base` toward `angle` (0 = up), its tip bending by `bend` radians. `shape`:
# "leaf", "heart" (pothos), "fiddle" (wide near the tip), "split" (monstera, with slits). `t` = how thirsty (brown
# tip and edge, wrinkles).
static func _curved_leaf(base: Vector2, angle: float, length: float, width: float, bend: float, fill: Color, line: Color, t: float, shape: String) -> String:
	var dir := func(a: float) -> Vector2: return Vector2(sin(a), -cos(a))
	var p1: Vector2 = base + dir.call(angle) * length * 0.5
	var p2: Vector2 = base + dir.call(angle + bend) * length * 0.88 + dir.call(angle) * length * 0.12
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	var mid: Array[Vector2] = []
	for k in 13:
		var q := k / 12.0
		var c := base.lerp(p1, q).lerp(p1.lerp(p2, q), q)
		var d := (p1 - base).lerp(p2 - p1, q).normalized()
		var w := width * 0.5
		match shape:
			"heart":
				w *= sin(PI * pow(q, 0.55)) * (1.0 + 0.3 * (1.0 - q))
			"fiddle":
				w *= sin(PI * pow(q, 0.45))
			_:
				w *= sin(PI * pow(q, 0.75))
		w *= 1.0 - t * 0.25 * sin(q * 9.0)
		mid.append(c)
		left.append(c + d.orthogonal() * w)
		right.append(c - d.orthogonal() * w)
	var outline := "M%s %s" % [base.x, base.y]
	for p in left:
		outline += " L%.1f %.1f" % [p.x, p.y]
	for i in range(right.size() - 1, -1, -1):
		outline += " L%.1f %.1f" % [right[i].x, right[i].y]
	var s := '<path d="%s Z" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % [outline, _hex(fill), _hex(line)]
	if shape == "split":
		for q in [0.35, 0.55, 0.75]:
			var i := int(q * 12.0)
			for side in [left, right]:
				var e: Vector2 = side[i]
				s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#F4EFE2" stroke-width="4" stroke-linecap="round"/>' % [e.x, e.y, e.lerp(mid[i], 0.55).x, e.lerp(mid[i], 0.55).y]
	var vein := "M%s %s" % [base.x, base.y]
	for p in mid:
		vein += " L%.1f %.1f" % [p.x, p.y]
	s += '<path d="%s" stroke="%s" stroke-width="1.5" fill="none" opacity="0.6"/>' % [vein, _hex(fill.lightened(0.35))]
	if t > 0.0:
		# A crisp brown tip.
		var tip := mid[12]
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#8A5A2A" opacity="0.85"/>' % [tip.x, tip.y, width * 0.16]
	return s


# A fern frond: a midrib with little leaflets on both sides, shorter toward the tip.
static func _frond(base: Vector2, angle: float, length: float, bend: float, fill: Color, line: Color, t: float) -> String:
	var dir := func(a: float) -> Vector2: return Vector2(sin(a), -cos(a))
	var p1: Vector2 = base + dir.call(angle) * length * 0.5
	var p2: Vector2 = base + dir.call(angle + bend) * length
	var s := '<path d="M%s %s Q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="2" fill="none"/>' % [base.x, base.y, p1.x, p1.y, p2.x, p2.y, _hex(line)]
	for k in range(2, 15):
		var q := k / 15.0
		var c := base.lerp(p1, q).lerp(p1.lerp(p2, q), q)
		var d := (p1 - base).lerp(p2 - p1, q).normalized()
		var size := 13.0 * (1.0 - q * 0.75)
		var col := fill.lerp(Color("#8A5A2A"), t * q * 0.8)
		for side in [-1.0, 1.0]:
			var tip: Vector2 = c + (d.orthogonal() * side * 0.85 + d * 0.5).normalized() * size + Vector2(0, t * size * 0.6)
			s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="%.1f" stroke-linecap="round"/>' % [c.x, c.y, tip.x, tip.y, _hex(col), 5.0 * (1.0 - q * 0.5)]
	return s


# A pot standing at `bottom` (rim width `w`, height `ph`) with its soil, dark and moist, or pale, dry and cracked.
static func _pot(cx: float, bottom: float, w: float, ph: float, fill: String, line: String, t: float) -> String:
	var top := bottom - ph
	var s := _soil(cx, top + 4.0, w * 0.46, t)
	s += '<path d="M%s %s H%s L%s %s H%s Z" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % [cx - w / 2.0, top, cx + w / 2.0, cx + w * 0.38, bottom - 2.0, cx - w * 0.38, fill, line]
	s += '<rect x="%s" y="%s" width="%s" height="13" rx="3" fill="%s" stroke="%s" stroke-width="2.5"/>' % [cx - w / 2.0 - 5.0, top - 4.0, w + 10.0, fill, line]
	s += '<path d="M%s %s L%s %s" stroke="#FFFFFF" stroke-width="6" opacity="0.18" stroke-linecap="round"/>' % [cx - w * 0.36, top + 14.0, cx - w * 0.3, bottom - 10.0]
	return s


static func _hex(c: Color) -> String:
	return PropArt._hex(c)


static func _soil(cx: float, y: float, rx: float, t: float) -> String:
	var s := '<ellipse cx="%s" cy="%s" rx="%s" ry="6" fill="%s"/>' % [cx, y, rx, "#4A3426" if t == 0.0 else "#A88A66"]
	if t > 0.0:
		s += '<path d="M%s %s l10 3 l8 -4 M%s %s l-8 3 l-6 -3" stroke="#6E5238" stroke-width="1.5" fill="none"/>' % [cx - rx * 0.5, y - 1.0, cx + rx * 0.4, y]
	return s


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


## Canvas 130x80: her rain boots on a rubber boot tray by the door: one yellow with white dots, one green with a yellow stripe, each
## glossy, with its cuff, pull tabs, a thick sole with a tread and a high shine, a little water and some grit on the tray. Floor at y 80.
static func boots() -> ImageTexture:
	var s := '<defs>'
	for g in [["bootY", "#FFD84A", "#F2C12E", "#C99A12"], ["bootG", "#5AB07A", "#3E8E5A", "#27663E"]]:
		s += '<linearGradient id="%s" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="%s"/><stop offset="0.4" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % g
	s += '<linearGradient id="tray" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7C828C"/><stop offset="1" stop-color="#555A63"/></linearGradient></defs>'
	# The tray: a raised rim round a darker floor, with grit and a puddle.
	s += '<path d="M2 66 Q2 62 8 62 H122 Q128 62 128 66 L124 78 Q123 80 120 80 H10 Q7 80 6 78 Z" fill="url(#tray)" stroke="#23262B" stroke-width="2"/>'
	s += '<path d="M10 66 H120 L117 75 H13 Z" fill="#454952"/><path d="M8 63.5 H122" stroke="#8E949B" stroke-width="1.6" opacity="0.7"/>'
	s += '<ellipse cx="62" cy="71" rx="16" ry="2.6" fill="#7FA9C4" opacity="0.55"/><ellipse cx="58" cy="70.4" rx="6" ry="1" fill="#FFFFFF" opacity="0.5"/>'
	for g in [[20, 70], [34, 73], [92, 72], [108, 70], [100, 74], [26, 74]]:
		s += '<circle cx="%d" cy="%d" r="1.4" fill="#8A7A60"/>' % g
	for b in [[4.0, "bootY", "#B88A0E", true], [66.0, "bootG", "#1F5434", false]]:
		var x: float = b[0]
		var body := 'M%s 6 L%s 6 L%s 46 C%s 54 %s 54 %s 60 C%s 64 %s 70 %s 73 L%s 73 L%s 50 C%s 30 %s 16 %s 6 Z' % [x + 4, x + 34, x + 36, x + 36, x + 48, x + 54, x + 60, x + 62, x + 60, x + 1, x + 2, x + 3, x + 4, x + 4]
		s += '<ellipse cx="%s" cy="74" rx="32" ry="3.4" fill="#000000" opacity="0.28"/>' % (x + 31)
		# The pull tabs on the cuff, then the boot itself and its cuff band.
		s += '<path d="M%s 8 Q%s 0 %s 8 M%s 8 Q%s 0 %s 8" stroke="%s" stroke-width="2.4" fill="none"/>' % [x + 4, x + 6, x + 10, x + 28, x + 31, x + 34, b[2]]
		s += '<path d="%s" fill="url(#%s)" stroke="%s" stroke-width="2.4" stroke-linejoin="round"/>' % [body, b[1], b[2]]
		s += '<path d="M%s 6 L%s 6 L%s 14 L%s 14 Z" fill="%s" opacity="0.38"/>' % [x + 4, x + 34, x + 35, x + 4, b[2]]
		s += '<ellipse cx="%s" cy="6" rx="15" ry="3" fill="#2A1E10" stroke="%s" stroke-width="1.6"/>' % [x + 19, b[2]]
		# A glossy strip down the shaft and a round shine on the toe.
		s += '<path d="M%s 17 Q%s 34 %s 50" stroke="#FFFFFF" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.5"/>' % [x + 11, x + 10, x + 14]
		s += '<ellipse cx="%s" cy="63" rx="5" ry="2.2" fill="#FFFFFF" opacity="0.4"/>' % (x + 50)
		# The thick sole with its tread.
		s += '<path d="M%s 68 L%s 66 Q%s 68 %s 72 L%s 77 L%s 77 Z" fill="#EFE8D4" stroke="#9A917A" stroke-width="1.6"/>' % [x + 1, x + 54, x + 62, x + 64, x + 62, x + 1]
		for k in 8:
			s += '<path d="M%s 72 V77" stroke="#B3AA92" stroke-width="1.6"/>' % (x + 6 + k * 7)
		if b[3]:
			for d in [[x + 12, 24], [x + 24, 20], [x + 18, 34], [x + 28, 36], [x + 12, 44], [x + 24, 48], [x + 40, 58], [x + 48, 66]]:
				s += '<circle cx="%s" cy="%s" r="2.3" fill="#FFFFFF" opacity="0.85"/>' % d
		else:
			s += '<path d="M%s 26 Q%s 30 %s 26 M%s 36 Q%s 40 %s 36" stroke="#FFD84A" stroke-width="3.4" fill="none" stroke-linecap="round" transform="translate(0 0)"/>' % [x + 6, x + 20, x + 35, x + 6, x + 20, x + 35]
	return tex(130, 80, s)


## Canvas 440x170: a row of framed family photos for the hallway.
static func photo_row() -> ImageTexture:
	# Family photographs in frames of their own: [x, y, w, h, frame kind, sky, ground, mood], each a little scene with people.
	var specs := [
		[0.0, 30.0, 92.0, 112.0, "black", "#9DB9C9", "#7E9E68", 0],
		[104.0, 0.0, 124.0, 92.0, "wood", "#F2D9A0", "#B8855A", 1],
		[104.0, 102.0, 58.0, 66.0, "white", "#C9DDEA", "#E8EEF2", 2],
		[172.0, 102.0, 56.0, 66.0, "black", "#F2B6CF", "#A8C28A", 0],
		[246.0, 18.0, 84.0, 104.0, "gold", "#D9C6E6", "#8EA880", 2],
		[344.0, 38.0, 94.0, 74.0, "wood", "#BFE0F0", "#6E9E6A", 1],
	]
	var s := ""
	for i in specs.size():
		var f: Array = specs[i]
		var w: float = f[2]
		var h: float = f[3]
		var t := 6.0
		var mat := 7.0
		var pw := w - 2.0 * (t + mat)
		var ph := h - 2.0 * (t + mat)
		var inner := '<rect width="%s" height="%s" fill="%s"/>' % [pw, ph, f[5]]
		inner += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [pw * 0.5, ph, pw * 0.9, ph * 0.4, f[6]]
		if int(f[7]) == 1:
			# A sun and a hill.
			inner += '<circle cx="%s" cy="%s" r="%s" fill="#FFF0B0" opacity="0.9"/>' % [pw * 0.8, ph * 0.28, pw * 0.1]
		# Two people (a tall and a small one) and, in some, a tree.
		var cx := pw * 0.5
		var base := ph * 0.9
		inner += '<ellipse cx="%s" cy="%s" rx="%s" ry="2.4" fill="#000000" opacity="0.2"/>' % [cx, base + 1.0, pw * 0.22]
		inner += '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s"/>' % [cx - pw * 0.2, base - ph * 0.36, pw * 0.14, ph * 0.36, ["#3E6AA8", "#B0623A", "#7E4E8E"][i % 3]]
		inner += '<circle cx="%s" cy="%s" r="%s" fill="#E8B898"/>' % [cx - pw * 0.13, base - ph * 0.42, pw * 0.075]
		inner += '<path d="M%s %s a%s %s 0 0 1 %s 0" fill="#5A3A24"/>' % [cx - pw * 0.205, base - ph * 0.44, pw * 0.075, pw * 0.06, pw * 0.15]
		inner += '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s"/>' % [cx + pw * 0.04, base - ph * 0.22, pw * 0.11, ph * 0.22, ["#D84A5A", "#F2C230", "#3BAA5C"][i % 3]]
		inner += '<circle cx="%s" cy="%s" r="%s" fill="#EFC3A5"/>' % [cx + pw * 0.095, base - ph * 0.27, pw * 0.058]
		inner += '<path d="M%s %s a%s %s 0 0 1 %s 0" fill="#C8884A"/>' % [cx + pw * 0.037, base - ph * 0.285, pw * 0.058, pw * 0.05, pw * 0.116]
		if i % 2 == 1:
			inner += '<rect x="%s" y="%s" width="3" height="%s" fill="#6E4E3A"/><circle cx="%s" cy="%s" r="%s" fill="#5E9A5A"/>' % [pw * 0.12, ph * 0.5, ph * 0.4, pw * 0.14, ph * 0.46, pw * 0.1]
		s += _framed("ph%d" % i, float(f[0]) + 2.0, float(f[1]) + 2.0, w, h, str(f[4]), inner, t, mat, "#F6F1E6")
	return tex(446, 176, s)


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


## Canvas 150x86: the shoebox Charlotte keeps her junk food in, pushed under her bed with the lid askew, a strip
## of tape across it, "PRIVÉ !" written on the side in crayon, a heart sticker, and a wrapper poking out. Floor at y 86.
static func stash_box() -> ImageTexture:
	# A shoebox half pulled out from under the bed: its front and side faces, corrugated edges, the lid ajar over a heap of sweets
	# (wrapped candies, a lollipop, a chocolate bar), washi tape, a crayon heart, a star sticker and a sticky note.
	var s := '<defs><linearGradient id="card" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DDB77F"/><stop offset="1" stop-color="#B98C55"/></linearGradient>'
	s += '<linearGradient id="cardlid" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#EBCB98"/><stop offset="1" stop-color="#C79C62"/></linearGradient></defs>'
	s += '<ellipse cx="78" cy="82" rx="68" ry="5" fill="#000000" opacity="0.2"/>'
	# The sweets in the box, heaped over its rim.
	for c in [[30, 34, "#E5383B"], [46, 30, "#FFD23F"], [62, 33, "#3B8BE0"], [80, 30, "#FF7BB0"], [98, 33, "#2F9E55"], [116, 35, "#FF8A2E"], [38, 38, "#8E5BD0"], [72, 37, "#E5383B"], [104, 38, "#FFD23F"]]:
		s += '<circle cx="%d" cy="%d" r="8" fill="%s" stroke="#00000033" stroke-width="1.2"/><circle cx="%d" cy="%d" r="2.4" fill="#FFFFFF" opacity="0.6"/>' % [c[0], c[1], c[2], c[0] - 3, c[1] - 3]
	for w in [[24, 36, 0.5], [122, 38, -0.4], [88, 28, 0.2]]:
		s += '<path d="M%d %d l-9 -4 l0 8 z M%d %d l9 -4 l0 8 z" fill="#FFFFFF" opacity="0.85" transform="rotate(%s %d %d)"/>' % [w[0] - 7, w[1], w[0] + 7, w[1], rad_to_deg(w[2]), w[0], w[1]]
	s += '<path d="M126 22 l8 -14" stroke="#F4F1E4" stroke-width="3" stroke-linecap="round"/><circle cx="136" cy="8" r="8" fill="#E8597A" stroke="#B5415C" stroke-width="1.8"/><path d="M132 6 q4 -4 8 0 q-4 4 -8 0" stroke="#FFFFFF" stroke-width="1.6" fill="none"/>'
	# The box: the front (lit), the right side (shaded), the rim, the corrugated edge.
	s += '<path d="M8 40 H142 L136 82 H14 Z" fill="url(#card)" stroke="#7E5E3A" stroke-width="2.8" stroke-linejoin="round"/>'
	s += '<path d="M142 40 L148 34 L142 76 L136 82 Z" fill="#9A7440" stroke="#7E5E3A" stroke-width="2" stroke-linejoin="round"/>'
	s += '<path d="M8 40 H142" stroke="#F0D7AC" stroke-width="2.4"/>'
	for x in range(20, 136, 10):
		s += '<path d="M%d 44 L%d 78" stroke="#A67E4A" stroke-width="1.5" opacity="0.4"/>' % [x, x - 2]
	s += '<path d="M12 78 H138" stroke="#7E5E3A" stroke-width="1.6" opacity="0.35"/>'
	# The lid, off and tilted against the back, with its printed band.
	s += '<path d="M4 22 L96 14 L102 26 L10 36 Z" fill="url(#cardlid)" stroke="#7E5E3A" stroke-width="2.6" stroke-linejoin="round"/>'
	s += '<path d="M10 36 L102 26 L103 31 L11 41 Z" fill="#B98C55" stroke="#7E5E3A" stroke-width="1.8"/>'
	s += '<path d="M10 27 L96 19" stroke="#F4DDB6" stroke-width="2.2" opacity="0.8"/>'
	# Decorations on the front: a washi tape, a crayon heart, a star sticker, a sticky note.
	s += '<path d="M28 38 h30 v12 h-30 z" fill="#F7B6C6" opacity="0.9" stroke="#E08AA2" stroke-width="1" transform="rotate(-4 43 44)"/>'
	s += '<path d="M32 44 h22" stroke="#FFFFFF" stroke-width="2" stroke-dasharray="3 3" opacity="0.8" transform="rotate(-4 43 44)"/>'
	s += '<path d="M72 56 q-9 -12 -18 -2 q-8 10 18 28 q26 -18 18 -28 q-9 -10 -18 2 Z" transform="translate(6 -4) scale(0.8)" fill="#E8597A" stroke="#B5415C" stroke-width="2.4"/>'
	s += '<path d="M100 50 l3 7 l8 1 l-6 5 l2 8 l-7 -4 l-7 4 l2 -8 l-6 -5 l8 -1 z" fill="#FFD23F" stroke="#C99410" stroke-width="1.4"/>'
	s += '<path d="M112 58 h22 v18 h-22 z" fill="#FFF3A8" stroke="#D6C25A" stroke-width="1.2" transform="rotate(5 123 67)"/><path d="M116 64 h13 M116 70 h9" stroke="#C8202A" stroke-width="1.8" stroke-linecap="round" transform="rotate(5 123 67)"/>'
	s += '<path d="M20 70 q14 -6 26 0 t24 0" stroke="#3B8BE0" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
	return tex(152, 86, s)


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


## Canvas 150x360: the kitchen fridge with its door swung open toward the viewer (door on the left, seen
## edge-on with its shelves), the lit inside full of food. Drawn over InteriorArt.kitchen()'s fridge.
static func fridge_open() -> ImageTexture:
	var s := '<defs>'
	s += '<linearGradient id="cold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.55" stop-color="#E6F1F8"/><stop offset="1" stop-color="#C9DCE8"/></linearGradient>'
	s += '<linearGradient id="frost" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4FAFF"/><stop offset="1" stop-color="#D2E4F0"/></linearGradient>'
	s += '<radialGradient id="bulb" cx="0.5" cy="0" r="0.9"><stop offset="0" stop-color="#FFFBEA" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFBEA" stop-opacity="0"/></radialGradient>'
	s += '<linearGradient id="side" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000000" stop-opacity="0.16"/><stop offset="0.25" stop-color="#000000" stop-opacity="0"/><stop offset="0.8" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.2"/></linearGradient>'
	s += '</defs>'
	# Cabinet, gasket, the two lit compartments with their light and shaded sides.
	s += '<rect x="44" y="2" width="104" height="356" rx="8" fill="#F2F2EF" stroke="#B9B4AA" stroke-width="3"/>'
	s += '<rect x="50" y="8" width="92" height="118" rx="4" fill="#9AA4AC"/><rect x="50" y="132" width="92" height="222" rx="4" fill="#9AA4AC"/>'
	s += '<rect x="53" y="11" width="86" height="112" fill="url(#frost)"/><rect x="53" y="135" width="86" height="216" fill="url(#cold)"/>'
	s += '<rect x="53" y="135" width="86" height="216" fill="url(#side)"/><rect x="53" y="11" width="86" height="112" fill="url(#side)"/>'
	s += '<rect x="53" y="135" width="86" height="90" fill="url(#bulb)"/>'
	s += '<rect x="84" y="136" width="24" height="5" rx="2" fill="#FFFDF2"/>'
	# Freezer: frost rim, a tub of ice cream, a bag of peas, an ice-cube tray.
	s += '<path d="M53 11 H139 V18 Q120 22 96 17 Q74 22 53 18 Z" fill="#FFFFFF" opacity="0.9"/>'
	s += '<rect x="58" y="80" width="36" height="40" rx="5" fill="#F7D6E0" stroke="#D97A9A" stroke-width="1.5"/><rect x="58" y="80" width="36" height="9" rx="4" fill="#E890B4"/><circle cx="76" cy="102" r="7" fill="#FFF3E0"/>'
	s += '<path d="M98 96 q16 -10 34 0 l-2 24 h-30 z" fill="#4E9A3E" stroke="#2E6E2A" stroke-width="1.5"/>'
	for k in 4:
		s += '<circle cx="%d" cy="%d" r="2.6" fill="#8ED16E"/>' % [106 + k * 6, 108 + (k % 2) * 4]
	s += '<rect x="58" y="60" width="78" height="14" rx="3" fill="#D6EAF5" stroke="#9AB8C8" stroke-width="1.5"/>'
	for k in 6:
		s += '<rect x="%d" y="63" width="9" height="8" rx="1.5" fill="#FFFFFF" opacity="0.8"/>' % (62 + k * 12)
	s += '<rect x="53" y="76" width="86" height="3" fill="#FFFFFF" opacity="0.7"/>'
	# Glass shelves with their bright front edges.
	for y in [196.0, 254.0, 304.0]:
		s += '<rect x="53" y="%s" width="86" height="4" fill="#BFD6E4" fill-opacity="0.85"/><rect x="53" y="%s" width="86" height="1.5" fill="#FFFFFF"/>' % [y, y]
	# Top shelf: the milk-bag pitcher, a leftovers box, a cake under its dome.
	s += '<path d="M60 194 V160 Q60 154 66 154 H80 Q86 154 86 160 V194 Z" fill="#FFFFFF" stroke="#9AA8B4" stroke-width="1.5"/>'
	s += '<path d="M62 158 q11 -10 22 0 v6 h-22 z" fill="#FBFDFF" stroke="#7E95A8" stroke-width="1.2"/><rect x="62" y="170" width="22" height="7" fill="#4FA3E0"/>'
	s += '<path d="M86 166 q8 2 6 14" stroke="#9AA8B4" stroke-width="2.5" fill="none"/>'
	s += '<rect x="94" y="174" width="42" height="20" rx="4" fill="#F4E9C8" fill-opacity="0.85" stroke="#C9B48A" stroke-width="1.5"/><rect x="92" y="170" width="46" height="6" rx="2" fill="#7FB5D9"/>'
	s += '<path d="M100 186 q8 -6 14 0 q6 -6 14 0" stroke="#E07A3A" stroke-width="3" fill="none"/>'
	# Middle shelf: a piece of cake, cheese, butter, yogurt cups.
	s += '<path d="M58 252 L58 232 L84 226 L84 246 Z" fill="#FBEBD2" stroke="#C9A878" stroke-width="1.5"/><path d="M58 232 L84 226" stroke="#E04F7A" stroke-width="4"/><circle cx="76" cy="226" r="3" fill="#E0303A"/>'
	s += '<path d="M90 252 L90 236 L112 230 V246 Z" fill="#F2C230" stroke="#C99410" stroke-width="1.5"/><circle cx="98" cy="242" r="2.2" fill="#D9A41A"/><circle cx="106" cy="238" r="1.8" fill="#D9A41A"/>'
	for k in 3:
		s += '<path d="M%d 252 l1.5 -14 h7 l1.5 14 z" fill="%s" stroke="#FFFFFF" stroke-width="1"/><rect x="%d" y="237" width="9" height="3" fill="#FFFFFF"/>' % [114 + k * 8, ["#FF7BA3", "#FFD23F", "#7FC4E0"][k], 114 + k * 8 + 0.5]
	# Lower shelf: a bowl of grapes, a jar of pickles, eggs.
	s += '<path d="M58 300 q16 10 32 0 z" fill="#E8E4DA" stroke="#9A968E" stroke-width="1.5"/>'
	for g in [[64, 294], [71, 292], [78, 294], [85, 293], [68, 287], [75, 286], [82, 287]]:
		s += '<circle cx="%d" cy="%d" r="3.6" fill="#7E57C2"/>' % g
	s += '<rect x="96" y="270" width="18" height="32" rx="4" fill="#BFD8A0" fill-opacity="0.8" stroke="#8AA870" stroke-width="1.5"/><rect x="95" y="266" width="20" height="6" rx="2" fill="#C8202A"/>'
	s += '<path d="M104 278 v18 M100 284 v14 M108 282 v14" stroke="#5E8A3A" stroke-width="2.5" stroke-linecap="round"/>'
	s += '<rect x="118" y="290" width="20" height="12" rx="2" fill="#E8D9B8" stroke="#B9A47A" stroke-width="1"/><circle cx="123" cy="290" r="3.5" fill="#F6EBD8"/><circle cx="132" cy="290" r="3.5" fill="#F6EBD8"/>'
	# Crisper drawer at the bottom, see-through, full of vegetables.
	s += '<rect x="55" y="312" width="82" height="38" rx="5" fill="#E6F2E0" fill-opacity="0.75" stroke="#9AB8A8" stroke-width="1.8"/>'
	s += '<path d="M60 340 q8 -22 22 -14 q10 -14 18 6 q-14 14 -40 8 z" fill="#7CCB5A" stroke="#4E8A3A" stroke-width="1.2"/>'
	s += '<path d="M100 332 l20 -10 l3 6 l-20 10 z" fill="#FF8A3D"/><path d="M122 322 l6 -4 M123 324 l7 0" stroke="#3E8E5A" stroke-width="2"/>'
	s += '<circle cx="112" cy="342" r="6" fill="#E0303A"/><path d="M122 346 q0 -10 8 -10 q6 0 6 10 z" fill="#FFD23F" stroke="#C99410" stroke-width="1"/>'
	s += '<rect x="58" y="314" width="76" height="4" rx="2" fill="#FFFFFF" opacity="0.6"/>'
	# The open door, edge-on: gasket, its inner face with balconies of bottles, jars and the egg tray.
	s += '<path d="M44 4 L4 22 V340 L44 358 Z" fill="#ECECE8" stroke="#B9B4AA" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M40 10 L10 25 V336 L40 352" fill="none" stroke="#9AA4AC" stroke-width="3"/>'
	s += '<path d="M12 40 L38 30 V54 L12 64 Z" fill="#F6EBD8" stroke="#C9C2B4" stroke-width="1"/>'
	for k in 3:
		s += '<ellipse cx="%d" cy="%d" rx="4" ry="5" fill="#FBF3E4" stroke="#D9C2A0" stroke-width="1"/>' % [18 + k * 7, 50 - k * 3]
	for row in [[120.0, ["#E0303A", "#FFD23F", "#F4E9C8"]], [210.0, ["#FF8A3D", "#7CCB5A", "#FFFFFF"]], [290.0, ["#4FA3E0", "#C8202A", "#F2C230"]]]:
		var y: float = row[0]
		s += '<path d="M8 %s L40 %s V%s L8 %s Z" fill="#D6EAF5" fill-opacity="0.85" stroke="#9AB8C8" stroke-width="1.5"/>' % [y, y - 10, y + 16, y + 26]
		var cols: Array = row[1]
		for k in 3:
			var bx := 11.0 + k * 9.0
			var top := y - 24.0 - k * 3.0
			s += '<rect x="%s" y="%s" width="8" height="%s" rx="3" fill="%s" stroke="#8E949A" stroke-width="0.8"/>' % [bx, top, y + 4.0 - top - k * 3.0, cols[k]]
			s += '<rect x="%s" y="%s" width="6" height="4" rx="1" fill="#5E6A74"/>' % [bx + 1.0, top - 3.0]
	s += '<path d="M6 24 L40 10" stroke="#FFFFFF" stroke-width="2" opacity="0.7"/>'
	return tex(150, 360, s)


## Canvas 64x64: a snack Charlotte takes from the fridge ("apple", "yogurt", "cheese", "grapes", "carrot", "cookie").
static func snack(kind: String) -> ImageTexture:
	var s := ""
	match kind:
		"apple":
			s = '<circle cx="26" cy="38" r="18" fill="#E0303A"/><circle cx="40" cy="38" r="18" fill="#E0303A"/><path d="M33 22 q2 -10 6 -14" stroke="#6E4E32" stroke-width="3" fill="none"/><path d="M36 16 q10 -8 16 -2 q-8 6 -16 2" fill="#7CCB5A"/><circle cx="24" cy="32" r="5" fill="#FFFFFF" opacity="0.4"/>'
		"yogurt":
			s = '<path d="M14 22 H50 L44 58 H20 Z" fill="#FFFFFF" stroke="#C9C2B4" stroke-width="2"/><rect x="12" y="16" width="40" height="8" rx="3" fill="#FF7BA3"/><circle cx="32" cy="40" r="7" fill="#FF7BA3"/>'
		"cheese":
			s = '<path d="M8 46 L56 30 V52 L8 58 Z" fill="#F2C230" stroke="#C99410" stroke-width="2"/><path d="M8 46 L40 22 L56 30 Z" fill="#F7D96A" stroke="#C99410" stroke-width="2"/><circle cx="22" cy="50" r="3" fill="#C99410"/><circle cx="40" cy="44" r="4" fill="#C99410"/>'
		"grapes":
			for p in [[24, 24], [36, 24], [18, 34], [30, 34], [42, 34], [24, 44], [36, 44], [30, 54]]:
				s += '<circle cx="%s" cy="%s" r="7" fill="#7E57C2" stroke="#5A3A9A" stroke-width="1"/>' % p
			s += '<path d="M30 18 q2 -8 8 -10" stroke="#6E4E32" stroke-width="3" fill="none"/>'
		"carrot":
			s = '<path d="M14 18 L50 34 Q46 44 38 42 Z" fill="#FF8A3D" stroke="#C45A12" stroke-width="2"/><path d="M50 34 l8 -10 M50 34 l10 -2 M50 34 l6 8" stroke="#3E8E5A" stroke-width="4" stroke-linecap="round"/>'
		_:
			s = '<circle cx="32" cy="34" r="22" fill="#D9A04A" stroke="#A8742A" stroke-width="2"/>'
			for p in [[24, 28], [38, 26], [30, 40], [42, 40], [22, 42]]:
				s += '<circle cx="%s" cy="%s" r="3.5" fill="#5A3A22"/>' % p
	return tex(64, 64, s)



# ── Chores ──────────────────────────────────────────────────

## Canvas 120x90: a green watering can, its spout to the right, "floor" at the bottom.
static func watering_can() -> ImageTexture:
	var s := '<path d="M22 30 H74 L70 86 H26 Z" fill="#4FA34A" stroke="#2F6A2A" stroke-width="3" stroke-linejoin="round"/>'
	s += '<path d="M72 50 L112 22 L116 28 L76 62 Z" fill="#4FA34A" stroke="#2F6A2A" stroke-width="3" stroke-linejoin="round"/>'
	s += '<ellipse cx="114" cy="25" rx="6" ry="8" fill="#3E8E3A" stroke="#2F6A2A" stroke-width="2" transform="rotate(-35 114 25)"/>'
	s += '<path d="M30 30 Q48 2 66 30" stroke="#2F6A2A" stroke-width="6" fill="none" stroke-linecap="round"/>'
	s += '<rect x="28" y="40" width="10" height="38" fill="#FFFFFF" opacity="0.25"/>'
	return tex(120, 90, s)


## The things lying on Charlotte's bedroom floor until she tidies up. Canvas 80x50, "floor" at the bottom. Light from
## the upper left: highlights there, a soft contact shadow under each.
static func mess(kind: String) -> ImageTexture:
	var s := '<ellipse cx="41" cy="47" rx="31" ry="3.2" fill="#3A2210" opacity="0.18"/>'
	match kind:
		"sock":
			# A pair of striped socks, one crumpled on the other.
			for k in 2:
				var dx := k * 14
				var dy := -k * 6
				s += '<path d="M%d %d H%d V%d Q%d %d %d %d H%d Q%d %d %d %d H%d Q%d %d %d %d Z" fill="%s" stroke="#B85A78" stroke-width="2" stroke-linejoin="round"/>' % [
					14 + dx, 12 + dy, 30 + dx, 28 + dy, 30 + dx, 36 + dy, 40 + dx, 36 + dy, 50 + dx, 56 + dx, 36 + dy, 56 + dx, 42 + dy, 40 + dx, 14 + dx, 46 + dy, 14 + dx, 38 + dy, "#F7B3C6" if k == 0 else "#FFD1DC"]
				for y in [17, 24]:
					s += '<rect x="%d" y="%d" width="16" height="3.5" fill="#FFFFFF" opacity="0.85"/>' % [14 + dx, y + dy]
				s += '<path d="M%d %d Q%d %d %d %d" stroke="#E07F9A" stroke-width="2" fill="none"/>' % [44 + dx, 37 + dy, 52 + dx, 37 + dy, 54 + dx, 41 + dy]
		"book":
			# An open picture book lying face down, its spine up.
			s += '<path d="M10 44 L40 34 L70 44 L40 48 Z" fill="#F7F3EA" stroke="#A8A196" stroke-width="1.5"/>'
			s += '<path d="M8 45 L40 32 L40 37 L11 48 Z" fill="#3D7FD0" stroke="#24589A" stroke-width="1.5"/><path d="M72 45 L40 32 L40 37 L69 48 Z" fill="#2F65A8" stroke="#24589A" stroke-width="1.5"/>'
			s += '<path d="M18 42 L34 36" stroke="#FFD23F" stroke-width="3" stroke-linecap="round"/><circle cx="56" cy="40" r="3" fill="#FFD23F"/>'
			s += '<path d="M40 32 V37" stroke="#1E4A80" stroke-width="2"/>'
		"ball":
			s += '<circle cx="40" cy="28" r="17" fill="#E74C3C" stroke="#9E2420" stroke-width="2"/>'
			s += '<path d="M23 28 Q40 18 57 28" stroke="#FFFFFF" stroke-width="5" fill="none"/><path d="M26 36 Q40 44 54 36" stroke="#FFD23F" stroke-width="4" fill="none"/>'
			s += '<ellipse cx="33" cy="21" rx="5" ry="3.5" fill="#FFFFFF" opacity="0.55" transform="rotate(-30 33 21)"/>'
		"tshirt":
			s += '<path d="M14 30 L28 20 Q40 25 52 20 L66 30 L59 38 L54 34 V47 H26 V34 L21 38 Z" fill="#F2C230" stroke="#B5891E" stroke-width="2" stroke-linejoin="round"/>'
			s += '<path d="M33 21 Q40 27 47 21" stroke="#B5891E" stroke-width="2" fill="none"/>'
			s += '<path d="M40 31 l2.5 5 l5.5 0.5 l-4 3.6 l1.3 5.4 l-5.3 -2.9 l-5.3 2.9 l1.3 -5.4 l-4 -3.6 l5.5 -0.5 z" fill="#FF5D8F"/>'
			s += '<path d="M30 40 Q36 43 34 47" stroke="#D9A920" stroke-width="1.5" fill="none"/>'
		"crayons":
			# The crayon box knocked over, crayons rolling out.
			s += '<path d="M10 30 L42 26 L44 44 L12 47 Z" fill="#3D8BD9" stroke="#2B5E9A" stroke-width="1.5"/><path d="M14 33 L38 30" stroke="#FFD23F" stroke-width="3"/>'
			var colors := ["#E74C3C", "#F1C40F", "#2ECC71", "#9B59B6", "#FF8A3D"]
			for i in 5:
				var x := 46 + i * 5
				var y := 30 + (i % 2) * 7
				s += '<g transform="rotate(%d %d %d)"><rect x="%d" y="%d" width="20" height="5" rx="1.5" fill="%s" stroke="#00000033" stroke-width="1"/><path d="M%d %d l4 2.5 l-4 2.5 z" fill="%s"/><rect x="%d" y="%d" width="10" height="5" fill="#FFFFFF" opacity="0.35"/></g>' % [
					-12 + i * 9, x, y, x, y, colors[i], x + 20, y, colors[i], x + 5, y]
		"pyjama":
			# Pyjama bottoms, flowered, in a heap.
			s += '<path d="M12 22 H44 L50 44 H36 L30 30 L24 46 H8 Z" fill="#B9A6E8" stroke="#7A64B8" stroke-width="2" stroke-linejoin="round"/>'
			s += '<path d="M12 22 H44 V27 H12 Z" fill="#9A86D4" stroke="#7A64B8" stroke-width="1.5"/>'
			for c in [[18, 34], [40, 36], [26, 26], [45, 41], [13, 41]]:
				s += '<circle cx="%d" cy="%d" r="2.6" fill="#FFFFFF"/><circle cx="%d" cy="%d" r="1.1" fill="#FFD23F"/>' % [c[0], c[1], c[0], c[1]]
			s += '<path d="M48 40 Q60 30 70 40 L68 46 H50 Z" fill="#B9A6E8" stroke="#7A64B8" stroke-width="2"/>'
		"blocks":
			# Three wooden letter blocks.
			var blocks := [[10, 26, "#E74C3C", "A"], [32, 30, "#3D8BD9", "B"], [52, 20, "#2ECC71", "C"]]
			for b in blocks:
				s += '<rect x="%d" y="%d" width="18" height="18" rx="2" fill="%s" stroke="#00000055" stroke-width="1.5" transform="rotate(%d %d %d)"/>' % [b[0], b[1], b[2], -8 + b[0] % 13, b[0] + 9, b[1] + 9]
				s += '<rect x="%d" y="%d" width="18" height="4" fill="#FFFFFF" opacity="0.3"/>' % [b[0], b[1]]
				s += '<text x="%d" y="%d" font-family="sans-serif" font-weight="bold" font-size="13" fill="#FFFFFF" text-anchor="middle">%s</text>' % [b[0] + 9, b[1] + 14, b[3]]
		"puzzle":
			# Puzzle pieces scattered.
			var cols := ["#FF8A3D", "#5DB6BE", "#F2C230", "#C97AB8"]
			for k in 4:
				var x := 10 + k * 16
				var y := 32 + (k % 2) * 6 - k
				s += '<path d="M%d %d h5 a3 3 0 1 1 5 0 h5 v5 a3 3 0 1 1 0 5 v5 h-15 Z" fill="%s" stroke="#00000044" stroke-width="1.2" transform="rotate(%d %d %d)"/>' % [x, y, cols[k], k * 23 - 20, x + 7, y + 7]
		"car":
			# A little red toy car on its side wheels.
			s += '<path d="M10 38 Q12 28 24 27 L32 18 H52 L60 27 Q70 28 70 38 Z" fill="#E74C3C" stroke="#9E2420" stroke-width="2" stroke-linejoin="round"/>'
			s += '<path d="M34 21 H44 V27 H29 Z M47 21 H51 L56 27 H47 Z" fill="#BFE3F5" stroke="#9E2420" stroke-width="1.2"/>'
			for wx in [24, 56]:
				s += '<circle cx="%d" cy="40" r="7" fill="#2B2B2B"/><circle cx="%d" cy="40" r="3" fill="#C9CED4"/>' % [wx, wx]
			s += '<path d="M14 31 H22" stroke="#FFFFFF" stroke-width="2" opacity="0.6"/><circle cx="67" cy="32" r="2" fill="#FFD23F"/>'
		"sneaker":
			# One sneaker, laces undone.
			s += '<path d="M10 42 Q10 30 18 28 L32 26 Q40 34 52 34 Q68 34 70 42 Z" fill="#F4F2EC" stroke="#9A948A" stroke-width="2" stroke-linejoin="round"/>'
			s += '<path d="M18 28 L32 26 Q38 32 44 33 L38 22 Q30 22 22 18 Z" fill="#FF5D8F" stroke="#C2406E" stroke-width="2" stroke-linejoin="round"/>'
			s += '<path d="M9 42 H71 V45 Q40 48 9 45 Z" fill="#E74C3C"/>'
			s += '<path d="M30 26 Q38 20 44 24 M33 28 Q46 30 52 26" stroke="#FFFFFF" stroke-width="1.6" fill="none"/>'
		_:
			# A teddy bear, fallen on its back.
			s += '<ellipse cx="46" cy="35" rx="19" ry="12" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
			s += '<ellipse cx="48" cy="35" rx="10" ry="6.5" fill="#E2C49A"/>'
			s += '<ellipse cx="64" cy="27" rx="6" ry="4.5" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/><ellipse cx="62" cy="44" rx="7" ry="4.5" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
			s += '<circle cx="22" cy="32" r="12" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/>'
			s += '<circle cx="15" cy="21" r="4.5" fill="#C49A6C" stroke="#7E5E3A" stroke-width="1.5"/><circle cx="27" cy="20" r="4.5" fill="#C49A6C" stroke="#7E5E3A" stroke-width="1.5"/>'
			s += '<ellipse cx="21" cy="36" rx="5" ry="3.5" fill="#E2C49A"/><circle cx="21" cy="34.5" r="1.6" fill="#2B2B2B"/>'
			s += '<circle cx="17" cy="29" r="1.6" fill="#2B2B2B"/><circle cx="25" cy="29" r="1.6" fill="#2B2B2B"/>'
			s += '<path d="M32 30 Q40 26 44 30" stroke="#FF5D8F" stroke-width="3" fill="none"/>'
			s += '<ellipse cx="17" cy="26" rx="3" ry="2" fill="#FFFFFF" opacity="0.4"/>'
	return tex(80, 50, s)


# ── Wall and ceiling decorations (for any room, especially a child's) ───────────────

## Canvas 110x120: a crescent moon wall decal with two small stars, pale yellow with a soft edge.
static func moon_decal() -> ImageTexture:
	var s := '<path d="M70 12 A44 44 0 1 0 98 86 A34 34 0 1 1 70 12 Z" fill="#FFE9A8" stroke="#E8C86A" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M46 30 Q34 50 40 78" stroke="#FFFFFF" stroke-width="5" fill="none" opacity="0.5" stroke-linecap="round"/>'
	s += '<path d="M92 22 l3 7 l8 1 l-6 5 l2 8 l-7 -4 l-7 4 l2 -8 l-6 -5 l8 -1 z" fill="#FFE9A8" stroke="#E8C86A" stroke-width="1.5"/>'
	s += '<path d="M24 98 l2 5 l6 1 l-4 4 l1 6 l-5 -3 l-5 3 l1 -6 l-4 -4 l6 -1 z" fill="#FFE9A8" stroke="#E8C86A" stroke-width="1.2"/>'
	return tex(110, 120, s)


## Canvas 90x230: a hanging baby mobile over a bed: a cord, a crossbar and four little felt shapes on strings (a star, a
## moon, a cloud, a heart), swaying a little (the scene rotates the node).
static func mobile() -> ImageTexture:
	var s := '<path d="M45 0 V40" stroke="#B9B1A0" stroke-width="2"/><path d="M8 44 H82" stroke="#C9A26E" stroke-width="4" stroke-linecap="round"/><circle cx="45" cy="42" r="5" fill="#E8C86A"/>'
	for k in [[12, 110, "#FFD23F", "star"], [34, 150, "#9ECFF0", "moon"], [56, 130, "#FFFFFF", "cloud"], [78, 160, "#FF8FB0", "heart"]]:
		s += '<path d="M%d 46 V%d" stroke="#B9B1A0" stroke-width="1.6"/>' % [k[0], k[1] - 16]
		match k[3]:
			"star":
				s += '<path d="M%d %d l5 11 l12 1 l-9 8 l3 12 l-11 -6 l-11 6 l3 -12 l-9 -8 l12 -1 z" fill="%s" stroke="#C99410" stroke-width="1.5"/>' % [k[0], k[1] - 16, k[2]]
			"moon":
				s += '<path d="M%d %d A13 13 0 1 0 %d %d A10 10 0 1 1 %d %d Z" fill="%s" stroke="#6E9CC0" stroke-width="1.5"/>' % [k[0] + 3, k[1] - 16, k[0] + 12, k[1] + 12, k[0] + 3, k[1] - 16, k[2]]
			"cloud":
				s += '<circle cx="%d" cy="%d" r="8" fill="%s" stroke="#C9D2D8" stroke-width="1.5"/><circle cx="%d" cy="%d" r="10" fill="%s" stroke="#C9D2D8" stroke-width="1.5"/><circle cx="%d" cy="%d" r="7" fill="%s" stroke="#C9D2D8" stroke-width="1.5"/>' % [k[0] - 8, k[1], k[2], k[0], k[1] - 4, k[2], k[0] + 9, k[1] + 1, k[2]]
			_:
				s += '<path d="M%d %d c-12 -10 -16 6 0 16 c16 -10 12 -26 0 -16 z" fill="%s" stroke="#C2406E" stroke-width="1.5"/>' % [k[0], k[1] - 6, k[2]]
	return tex(90, 230, s)


## Canvas 80x80: a round wall clock with a pastel rim and fat hands, ticking at the time it was painted (10 past 10).
static func wall_clock() -> ImageTexture:
	var s := '<defs><radialGradient id="clockface" cx="0.4" cy="0.35"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#F1E4CA"/></radialGradient>'
	s += '<linearGradient id="clockrim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F59AB8"/><stop offset="0.55" stop-color="#D8527E"/><stop offset="1" stop-color="#A83460"/></linearGradient></defs>'
	s += '<ellipse cx="43" cy="44" rx="36" ry="36" fill="#000000" opacity="0.18"/>'
	s += '<circle cx="40" cy="40" r="37" fill="url(#clockrim)" stroke="#8A2A50" stroke-width="1.6"/>'
	s += '<circle cx="40" cy="40" r="31" fill="#B8406A"/><circle cx="40" cy="40" r="30" fill="url(#clockface)" stroke="#E2CFA6" stroke-width="1.2"/>'
	for k in 60:
		var d := Vector2.from_angle(TAU * k / 60.0)
		if k % 5 == 0:
			s += '<circle cx="%.1f" cy="%.1f" r="1.9" fill="#6E4A5A"/>' % [40 + d.x * 25.0, 40 + d.y * 25.0]
		else:
			s += '<circle cx="%.1f" cy="%.1f" r="0.6" fill="#B9A0A8"/>' % [40 + d.x * 27.0, 40 + d.y * 27.0]
	s += '<path d="M42 42 L30 32" stroke="#000000" stroke-width="4" stroke-linecap="round" opacity="0.2"/><path d="M42 42 L60 30" stroke="#000000" stroke-width="3" stroke-linecap="round" opacity="0.2"/>'
	s += '<path d="M40 40 L28 30" stroke="#4A2E3C" stroke-width="4" stroke-linecap="round"/><path d="M40 40 L58 28" stroke="#4A2E3C" stroke-width="2.8" stroke-linecap="round"/>'
	s += '<path d="M40 46 L44 22" stroke="#D8283A" stroke-width="1.2" stroke-linecap="round"/><circle cx="40" cy="40" r="3.4" fill="#D8527E" stroke="#8A2A50" stroke-width="1"/><circle cx="39" cy="39" r="1.1" fill="#FFFFFF" opacity="0.8"/>'
	s += '<path d="M16 28 Q28 12 48 11" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.5" stroke-linecap="round"/>'
	s += '<ellipse cx="32" cy="26" rx="14" ry="8" fill="#FFFFFF" opacity="0.12" transform="rotate(-30 32 26)"/>'
	return tex(86, 86, s)


# ── Kitchen and entrance decor (any house) ───────────────────

## Canvas 76x96: a paper wall calendar (red header, spiral, grid of days, a few circled, a star sticker) with a pencil on a string.
static func wall_calendar() -> ImageTexture:
	var s := '<rect x="5" y="6" width="72" height="92" rx="3" fill="#000000" opacity="0.16"/><rect x="2" y="2" width="72" height="92" rx="3" fill="#FFFDF6" stroke="#B9B4AA" stroke-width="2"/>'
	s += '<path d="M60 94 Q66 86 74 84 L74 94 Z" fill="#EDE7D8" stroke="#B9B4AA" stroke-width="1"/><path d="M62 94 Q67 89 73 88" stroke="#FFFFFF" stroke-width="1" fill="none"/>'
	s += '<rect x="2" y="2" width="72" height="30" rx="3" fill="#E5604D"/><rect x="2" y="2" width="72" height="10" rx="3" fill="#F08A78" opacity="0.7"/><circle cx="38" cy="14" r="9" fill="#FFD7A8" opacity="0.9"/><path d="M26 22 Q38 8 50 22 Z" fill="#7BB661"/>'
	for k in 8:
		s += '<circle cx="%d" cy="4" r="2.2" fill="#6E6E6E"/>' % (10 + k * 8)
	for row in 5:
		for col in 7:
			var x := 8.0 + col * 9.4
			var y := 40.0 + row * 10.4
			s += '<rect x="%.1f" y="%.1f" width="6.4" height="2.2" rx="1" fill="%s" opacity="0.75"/>' % [x, y, "#D9453B" if col == 6 else "#8A8478"]
	s += '<circle cx="27" cy="52" r="5.4" fill="none" stroke="#3E86C8" stroke-width="1.6"/><circle cx="64" cy="73" r="5.4" fill="none" stroke="#3E86C8" stroke-width="1.6"/>'
	s += '<path d="M45 83 l1.8 3.8 4.2 .5 -3.1 2.8 .9 4.1 -3.8 -2.1 -3.8 2.1 .9 -4.1 -3.1 -2.8 4.2 -.5 z" fill="#FFD23F" stroke="#C99410" stroke-width="1"/>'
	s += '<path d="M72 10 Q82 30 74 60" stroke="#B9B4AA" stroke-width="1.5" fill="none"/>'
	return tex(84, 96, s)


## Canvas 300x150: what sits on top of a fridge and the cabinet beside it: a bread box, cereal boxes and a fruit basket on the
## fridge (floor of the picture at y 150), two baskets, a trailing plant and a cookie jar on the cabinet (top at y 80, x 118–270).
static func kitchen_toppers() -> ImageTexture:
	var s := _defs()
	# Fridge top (x 4–108).
	s += '<rect x="10" y="118" width="48" height="32" rx="4" fill="#C49A6C" stroke="#7E5E3A" stroke-width="2"/><path d="M10 128 H58" stroke="#7E5E3A" stroke-width="1.5"/><rect x="28" y="122" width="12" height="3" rx="1.5" fill="#7E5E3A"/>'
	s += '<rect x="62" y="102" width="20" height="48" rx="2" fill="#F2C94C" stroke="#B8901C" stroke-width="2"/><circle cx="72" cy="122" r="6" fill="#E5604D"/><path d="M62 112 H82" stroke="#B8901C" stroke-width="1.5"/>'
	s += '<rect x="84" y="110" width="18" height="40" rx="2" fill="#6AB0DE" stroke="#2F6F9F" stroke-width="2"/><circle cx="93" cy="128" r="5" fill="#FFFFFF" opacity="0.85"/>'
	# Cabinet top (top edge at y 80): baskets and a jar.
	s += '<path d="M126 80 L130 50 H168 L172 80 Z" fill="#D7B07A" stroke="#8A6A40" stroke-width="2"/><path d="M128 64 H170 M127 72 H171" stroke="#8A6A40" stroke-width="1.4"/>'
	for k in 6:
		s += '<path d="M%d 50 V80" stroke="#B88F58" stroke-width="1.2" opacity="0.8"/>' % (134 + k * 6)
	s += '<path d="M138 50 Q132 30 146 22 M150 50 Q152 26 162 18 M160 50 Q172 34 168 24" stroke="#4E8F3A" stroke-width="3" fill="none"/>'
	for lf in [[146, 22], [162, 18], [168, 24], [140, 36], [158, 34]]:
		s += '<ellipse cx="%d" cy="%d" rx="9" ry="5" fill="#6FB153" stroke="#3E7A2C" stroke-width="1.4" transform="rotate(-25 %d %d)"/>' % [lf[0], lf[1], lf[0], lf[1]]
	s += '<path d="M168 52 Q176 70 172 98 M156 52 Q150 72 154 100" stroke="#5FA845" stroke-width="3" fill="none"/>'
	s += '<path d="M190 80 L194 56 H226 L230 80 Z" fill="#C9A06A" stroke="#7E5E3A" stroke-width="2"/><path d="M192 66 H228" stroke="#7E5E3A" stroke-width="1.4"/><ellipse cx="210" cy="56" rx="16" ry="4" fill="#E7C98D" stroke="#7E5E3A" stroke-width="1.5"/>'
	s += '<path d="M236 80 Q232 58 246 56 Q260 58 256 80 Z" fill="#F2A7C9" stroke="#B5557F" stroke-width="2"/><rect x="238" y="50" width="16" height="8" rx="4" fill="#F7F5EF" stroke="#B5557F" stroke-width="2"/><circle cx="246" cy="46" r="4" fill="#B5557F"/>'
	s += '<circle cx="246" cy="70" r="6" fill="#FFFFFF" opacity="0.8"/>'
	return tex(300, 150, s)


## Canvas 150x64: a red-and-white gingham valance with scalloped edge and two tie-backs, for the kitchen door's glass.
static func kitchen_curtain() -> ImageTexture:
	var s := '<rect x="4" y="2" width="142" height="4" rx="2" fill="#8A6A40"/>'
	s += '<path d="M6 6 H144 V32 Q135 46 125 32 Q115 46 105 32 Q95 46 85 32 Q75 46 65 32 Q55 46 45 32 Q35 46 25 32 Q15 46 6 32 Z" fill="#FFFFFF" stroke="#C9776A" stroke-width="1.5"/>'
	for x in range(6, 144, 12):
		s += '<rect x="%d" y="7" width="6" height="24" fill="#E5604D" opacity="0.55"/>' % x
	for y in [9, 21]:
		s += '<rect x="7" y="%d" width="136" height="6" fill="#E5604D" opacity="0.4"/>' % y
	s += '<path d="M6 32 L6 62 Q16 54 22 36 Z" fill="#FFFFFF" stroke="#C9776A" stroke-width="1.5"/><path d="M144 32 L144 62 Q134 54 128 36 Z" fill="#FFFFFF" stroke="#C9776A" stroke-width="1.5"/>'
	s += '<path d="M7 36 L7 58 Q13 52 17 38 Z" fill="#E5604D" opacity="0.5"/><path d="M143 36 L143 58 Q137 52 133 38 Z" fill="#E5604D" opacity="0.5"/>'
	s += '<circle cx="12" cy="46" r="3" fill="#FFD23F"/><circle cx="138" cy="46" r="3" fill="#FFD23F"/>'
	return tex(150, 64, s)


## Canvas 220x34: a flat tea-towel check kitchen mat (red and cream), seen from the front like the doormat.
static func kitchen_mat() -> ImageTexture:
	var s := '<path d="M22 3 H198 L216 30 H4 Z" fill="#F6EEDC" stroke="#8E2A22" stroke-width="2"/>'
	# Red squares, row by row, following the slanted sides.
	for row in 4:
		var y0 := 3.0 + row * 6.75
		var y1 := y0 + 6.75
		var l0 := 22.0 - 18.0 * (y0 - 3.0) / 27.0
		var l1 := 22.0 - 18.0 * (y1 - 3.0) / 27.0
		var r0 := 198.0 + 18.0 * (y0 - 3.0) / 27.0
		var r1 := 198.0 + 18.0 * (y1 - 3.0) / 27.0
		for col in 8:
			if (col + row) % 2 == 0:
				var t0 := col / 8.0
				var t1 := (col + 1) / 8.0
				s += '<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#D9453B"/>' % [lerpf(l0, r0, t0), y0, lerpf(l0, r0, t1), y0, lerpf(l1, r1, t1), y1, lerpf(l1, r1, t0), y1]
	s += '<path d="M22 3 H198 L216 30 H4 Z" fill="none" stroke="#8E2A22" stroke-width="2"/>'
	return tex(220, 34, s)


## Canvas 70x150: a glazed ceramic umbrella stand with a furled yellow and a furled navy umbrella and a walking stick. Floor at y 150.
static func umbrella_stand() -> ImageTexture:
	var s := '<path d="M22 20 V110" stroke="#6E4A2A" stroke-width="4.5" stroke-linecap="round"/><path d="M15 20 Q22 6 31 20" stroke="#6E4A2A" stroke-width="4.5" fill="none" stroke-linecap="round"/>'
	# Furled yellow umbrella (handle up) and navy one, leaning a little.
	s += '<path d="M46 14 V32" stroke="#2B2B33" stroke-width="3.5" stroke-linecap="round"/><path d="M42 32 Q46 28 50 32 L52 98 Q46 104 40 98 Z" fill="#F2C94C" stroke="#B8901C" stroke-width="1.8"/><path d="M45 36 L44 96 M48 36 L49 96" stroke="#B8901C" stroke-width="1" opacity="0.7"/><rect x="43" y="60" width="6" height="5" rx="2" fill="#D9453B"/>'
	s += '<path d="M34 24 V40" stroke="#6E4A2A" stroke-width="3.5" stroke-linecap="round"/><path d="M30 40 Q34 36 38 40 L39 104 Q34 110 29 104 Z" fill="#26335E" stroke="#141B38" stroke-width="1.8"/><path d="M33 44 L32 102" stroke="#4B5C94" stroke-width="1.2" opacity="0.8"/>'
	s += '<path d="M12 78 Q35 71 58 78 L54 140 Q35 147 16 140 Z" fill="#3E86C8" stroke="#1F4F7E" stroke-width="2"/>'
	s += '<path d="M12 78 Q35 71 58 78 L56 92 Q35 86 14 92 Z" fill="#6AB0DE" opacity="0.8"/><path d="M19 90 Q35 96 51 90" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.6"/>'
	s += '<path d="M20 112 Q26 118 32 112 Q38 118 44 112" stroke="#F2C94C" stroke-width="2" fill="none"/>'
	s += '<ellipse cx="35" cy="148" rx="22" ry="3" fill="#000000" opacity="0.18"/>'
	return tex(70, 150, s)


# ── Passions of the family: the piano, the kitchen table, the pottery wheel ───

## Canvas 310x270: an upright piano seen from the front, dark walnut, music on the desk, the keys at y 126-152 (100 px above the
## floor at scale 0.75), pedals under it. Floor at y 270.
static func piano() -> ImageTexture:
	var s := '<defs><linearGradient id="pw" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A4A2E"/><stop offset="0.45" stop-color="#5B3421"/><stop offset="1" stop-color="#3E2314"/></linearGradient>'
	s += '<linearGradient id="pt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A6240"/><stop offset="1" stop-color="#6A4028"/></linearGradient>'
	s += '<linearGradient id="pk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFEFA"/><stop offset="0.8" stop-color="#F2EDE0"/><stop offset="1" stop-color="#D8D2C2"/></linearGradient>'
	s += '<linearGradient id="pb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A3A42"/><stop offset="1" stop-color="#0E0E12"/></linearGradient>'
	s += '<linearGradient id="pg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F3D27A"/><stop offset="1" stop-color="#B8862A"/></linearGradient></defs>'
	# Floor shadow, castor feet, the two short legs.
	s += '<ellipse cx="155" cy="266" rx="150" ry="7" fill="#000" fill-opacity="0.22"/>'
	s += '<rect x="14" y="244" width="30" height="24" rx="4" fill="#2E180B"/><rect x="266" y="244" width="30" height="24" rx="4" fill="#2E180B"/>'
	s += '<circle cx="29" cy="268" r="4" fill="#B8862A"/><circle cx="281" cy="268" r="4" fill="#B8862A"/>'
	# The case: a polished upright, light from the left, a lid with a bright edge.
	s += '<rect x="10" y="22" width="290" height="226" rx="8" fill="url(#pw)" stroke="#2E180B" stroke-width="3"/>'
	s += '<rect x="4" y="10" width="302" height="18" rx="6" fill="url(#pt)" stroke="#2E180B" stroke-width="3"/>'
	s += '<rect x="9" y="12" width="292" height="4" rx="2" fill="#FFFFFF" fill-opacity="0.28"/>'
	# Two brass candle holders on the lid.
	for cx in [40.0, 270.0]:
		s += '<rect x="%.1f" y="2" width="4" height="10" fill="url(#pg)"/><ellipse cx="%.1f" cy="12" rx="8" ry="2.4" fill="url(#pg)"/>' % [cx - 2.0, cx]
		s += '<rect x="%.1f" y="-4" width="5" height="8" rx="1" fill="#F4EBD0"/>' % (cx - 2.5)
	# The panel above the keys, with the music stand and a sheet.
	s += '<rect x="24" y="38" width="262" height="76" rx="4" fill="#4A2818" stroke="#2E180B" stroke-width="2"/>'
	s += '<rect x="34" y="46" width="242" height="60" rx="3" fill="#5F3624" stroke="#3A2012" stroke-width="1.5"/>'
	s += '<rect x="34" y="46" width="242" height="14" rx="3" fill="#FFFFFF" fill-opacity="0.07"/>'
	s += '<path d="M100 104 L110 44 H204 L214 104 Z" fill="#3E2314" stroke="#2E180B" stroke-width="1.5"/>'
	s += '<rect x="108" y="46" width="94" height="58" fill="#F8F3E6" stroke="#9A9486" stroke-width="1.5"/>'
	s += '<path d="M108 46 L118 40 H210 L202 46 Z" fill="#E4DDC8" stroke="#9A9486" stroke-width="1"/>'
	for y in [58.0, 64.0, 70.0, 76.0, 82.0]:
		s += '<path d="M114 %s H196" stroke="#8A8A92" stroke-width="0.8"/>' % y
	for n in [[124.0, 76.0], [138.0, 70.0], [152.0, 64.0], [166.0, 76.0], [180.0, 70.0]]:
		s += '<ellipse cx="%s" cy="%s" rx="3.2" ry="2.4" fill="#2B2B33"/><path d="M%s %s V%s" stroke="#2B2B33" stroke-width="1.1"/>' % [n[0], n[1], n[0] + 3.0, n[1], n[1] - 11.0]
	s += '<path d="M138 59 H152 M166 63 H180" stroke="#2B2B33" stroke-width="2"/>'
	# The keyboard: a felt strip, the white keys with a soft shade, the black ones with a shine, and the wood cheeks.
	s += '<rect x="18" y="114" width="274" height="12" fill="#3B2113" stroke="#2E180B" stroke-width="1.5"/><rect x="28" y="124" width="254" height="3" fill="#8C2A2A"/>'
	s += '<rect x="28" y="126" width="254" height="28" fill="url(#pk)" stroke="#444" stroke-width="1"/>'
	for i in range(1, 23):
		s += '<path d="M%.1f 126 V154" stroke="#A39F96" stroke-width="1"/>' % (28.0 + i * 254.0 / 23.0)
	for i in 22:
		if [0, 1, 3, 4, 5].has(i % 7):
			var kx := 28.0 + (i + 1) * 254.0 / 23.0 - 3.4
			s += '<rect x="%.1f" y="126" width="6.8" height="17" rx="1" fill="url(#pb)"/><rect x="%.1f" y="127" width="1.6" height="12" fill="#FFFFFF" fill-opacity="0.28"/>' % [kx, kx + 1.0]
	s += '<rect x="18" y="126" width="10" height="28" fill="#4A2817"/><rect x="282" y="126" width="10" height="28" fill="#4A2817"/>'
	# The lower board and its three pedals, brass.
	s += '<rect x="24" y="160" width="262" height="62" rx="4" fill="#4A2818" stroke="#2E180B" stroke-width="2"/>'
	s += '<rect x="40" y="168" width="230" height="46" rx="3" fill="#5F3624" stroke="#3A2012" stroke-width="1.5"/>'
	s += '<rect x="40" y="168" width="230" height="10" rx="3" fill="#FFFFFF" fill-opacity="0.06"/>'
	for x in [136.0, 156.0, 176.0]:
		s += '<rect x="%s" y="228" width="14" height="14" rx="3" fill="url(#pg)" stroke="#8A6A1C" stroke-width="1.5"/><rect x="%s" y="229" width="3" height="11" fill="#FFFFFF" fill-opacity="0.45"/>' % [x - 1.0, x + 1.0]
	s += '<rect x="10" y="22" width="9" height="226" fill="#FFFFFF" fill-opacity="0.1"/>'
	return tex(310, 270, s)


## Canvas 80x52: the piano bench, a padded seat on four legs. Floor at y 52, the seat's top at y 6.
static func piano_bench() -> ImageTexture:
	var s := '<defs><linearGradient id="bs" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B04E4E"/><stop offset="1" stop-color="#7C2E2E"/></linearGradient></defs>'
	s += '<ellipse cx="40" cy="50" rx="38" ry="3" fill="#000" fill-opacity="0.18"/>'
	s += '<rect x="10" y="26" width="7" height="26" fill="#3E2314"/><rect x="63" y="26" width="7" height="26" fill="#3E2314"/>'
	s += '<rect x="12" y="38" width="56" height="4" fill="#4E2B1A"/>'
	s += '<rect x="4" y="16" width="72" height="12" rx="3" fill="#5B3421" stroke="#2E180B" stroke-width="2"/>'
	s += '<rect x="2" y="5" width="76" height="15" rx="7" fill="url(#bs)" stroke="#4E1E1E" stroke-width="2"/>'
	for x in [18.0, 40.0, 62.0]:
		s += '<circle cx="%s" cy="12" r="1.8" fill="#E8C86A"/>' % x
	s += '<path d="M10 9 H46" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.35"/>'
	return tex(80, 52, s)


## Canvas 230x150: Maman's corner: a low stool (x 22) and her potter's wheel (centre x 118, the wheel head 118 px above the floor),
## with her finished pots on a crate at the right. Floor at y 150.
static func pottery_station() -> ImageTexture:
	var s := '<defs><linearGradient id="st" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#A8ACB3"/><stop offset="0.5" stop-color="#E4E6EA"/><stop offset="1" stop-color="#8A8E96"/></linearGradient>'
	s += '<linearGradient id="gl1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8A070"/><stop offset="1" stop-color="#A8582E"/></linearGradient>'
	s += '<linearGradient id="gl2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#B58AB0"/><stop offset="1" stop-color="#6E4468"/></linearGradient>'
	s += '<linearGradient id="gl3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7EC4C0"/><stop offset="1" stop-color="#2E7C80"/></linearGradient></defs>'
	s += '<ellipse cx="116" cy="148" rx="112" ry="5" fill="#000" fill-opacity="0.18"/>'
	# The wheel: a steel frame, the splash pan with slip stains, the wheel head turning on its shaft.
	s += '<rect x="76" y="56" width="10" height="94" fill="url(#st)"/><rect x="152" y="56" width="10" height="94" fill="url(#st)"/>'
	s += '<rect x="76" y="112" width="86" height="7" fill="#80848B"/><rect x="76" y="112" width="86" height="2" fill="#FFFFFF" fill-opacity="0.35"/>'
	s += '<path d="M66 30 H172 L162 58 H76 Z" fill="#D8D4C8" stroke="#8D897C" stroke-width="2.5"/>'
	s += '<path d="M72 36 H166 L160 54 H80 Z" fill="#C8BFAC" fill-opacity="0.6"/>'
	s += '<ellipse cx="119" cy="30" rx="53" ry="9" fill="#C6C1B3" stroke="#8D897C" stroke-width="2"/>'
	s += '<ellipse cx="119" cy="30" rx="47" ry="6.4" fill="#B3A58E" fill-opacity="0.7"/>'
	s += '<ellipse cx="119" cy="24" rx="31" ry="6" fill="#A8ACB3" stroke="#6E727A" stroke-width="2"/>'
	s += '<ellipse cx="119" cy="22" rx="24" ry="4" fill="#D2D6DC"/>'
	s += '<rect x="116" y="26" width="7" height="34" fill="url(#st)"/>'
	s += '<path d="M90 36 q6 14 2 20 M146 38 q-5 12 -1 18" stroke="#B9A48C" stroke-width="3" fill="none" opacity="0.8"/>'
	# The foot pedal and the bucket of water with a sponge by the stool.
	s += '<path d="M86 132 h44 l-4 10 h-40 z" fill="#8D919A" stroke="#5E626A" stroke-width="2"/>'
	s += '<path d="M138 122 h24 l-2 24 h-20 z" fill="#4E86C8" stroke="#2E5E94" stroke-width="2"/><ellipse cx="150" cy="122" rx="12" ry="3" fill="#8FC0EE" stroke="#2E5E94" stroke-width="1.5"/>'
	s += '<ellipse cx="156" cy="121" rx="6" ry="3" fill="#E8C84A"/>'
	# Her stool: a round seat with a woven cushion (top at y 60), three splayed legs.
	s += '<path d="M10 62 L4 150 M22 64 V150 M34 62 L42 150" stroke="#7A4E24" stroke-width="5" stroke-linecap="round"/>'
	s += '<path d="M8 100 H36" stroke="#6E4520" stroke-width="3"/>'
	s += '<ellipse cx="22" cy="60" rx="24" ry="7" fill="#B4763E" stroke="#6E4520" stroke-width="2"/>'
	s += '<ellipse cx="22" cy="58" rx="18" ry="5" fill="#E8C98A" stroke="#B4863A" stroke-width="1"/>'
	s += '<ellipse cx="18" cy="57" rx="10" ry="2.4" fill="#FFFFFF" opacity="0.4"/>'
	# Her apron on a peg above the stool.
	s += '<path d="M2 10 V26 M40 10 V26" stroke="#7A4E24" stroke-width="3"/>'
	# The crate of finished pots on a shelf: three glazed pieces, a bowl, a drip of glaze, a little label.
	s += '<rect x="176" y="112" width="52" height="38" rx="2" fill="#B58B52" stroke="#6E4E22" stroke-width="2"/><path d="M176 126 H228 M176 138 H228" stroke="#6E4E22" stroke-width="1.5"/>'
	s += '<rect x="196" y="116" width="14" height="8" rx="1" fill="#F4ECD8" stroke="#9A8A62" stroke-width="0.8"/>'
	s += '<path d="M180 112 Q175 84 190 80 Q205 84 201 112 Z" fill="url(#gl1)" stroke="#7A4527" stroke-width="2"/><path d="M184 90 Q190 95 197 90" stroke="#FFFFFF" stroke-width="1.6" fill="none" opacity="0.5"/>'
	s += '<path d="M178 96 q2 10 -1 16" stroke="#7A4527" stroke-width="1.6" fill="none" opacity="0.7"/>'
	s += '<path d="M201 112 Q203 92 213 92 Q223 94 221 112 Z" fill="url(#gl2)" stroke="#5E3A55" stroke-width="2"/><path d="M205 100 H217" stroke="#FFFFFF" stroke-width="1.4" opacity="0.4"/>'
	s += '<path d="M212 112 Q212 100 220 98 Q230 100 228 112 Z" fill="url(#gl3)" stroke="#1E5C60" stroke-width="2"/>'
	s += '<ellipse cx="190" cy="82" rx="9" ry="2.2" fill="#3A1E10" fill-opacity="0.7"/>'
	return tex(230, 150, s)
