class_name CharacterArt
extends RefCounted
## Builds a character's SVG body parts from a CharacterLook and rasterizes them at runtime.

const HEAD_CANVAS := Vector2(240, 380)
const HEAD_PIVOT := Vector2(118, 296)
const RIGS := {
	"child": {"leg": 110.0, "torso": 90.0, "arm": 76.0, "head": 1.0, "sx": 1.0},
	"tween": {"leg": 160.0, "torso": 116.0, "arm": 98.0, "head": 0.96, "sx": 1.01},
	"teen": {"leg": 162.0, "torso": 120.0, "arm": 100.0, "head": 0.84, "sx": 1.05},
	"adult": {"leg": 210.0, "torso": 154.0, "arm": 128.0, "head": 0.72, "sx": 1.14},
	"senior": {"leg": 196.0, "torso": 148.0, "arm": 124.0, "head": 0.74, "sx": 1.14},
}

## How big the hands are, by age (the arms' width is the same for everyone).
## Soft light on cloth: a sheen from the upper left fading to shade at the lower right ("cs"), and a little more shade toward the hem ("cv").
const CLOTH_DEFS := ('<defs><linearGradient id="cs" x1="0" y1="0" x2="1" y2="0.55"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>'
	+ '<stop offset="0.4" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="0.72" stop-color="#000000" stop-opacity="0.05"/>'
	+ '<stop offset="1" stop-color="#000000" stop-opacity="0.1"/></linearGradient>'
	+ '<linearGradient id="cv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000000" stop-opacity="0"/>'
	+ '<stop offset="1" stop-color="#000000" stop-opacity="0.07"/></linearGradient></defs>')
## The shin's picture reaches this far above the knee (the round cap of the joint).
const SHIN_PAD := 14.0
const HAND_SCALE := {"child": 1.0, "tween": 1.05, "teen": 1.1, "adult": 1.22, "senior": 1.18}

var look: CharacterLook
var p := {}


static func build(character_look: CharacterLook) -> Dictionary:
	var art := CharacterArt.new()
	art.look = character_look
	art.p = art._palette()
	return art._build()


var _clip_id := 0


func _build() -> Dictionary:
	var r: Dictionary = RIGS[look.age]
	var leg: float = r.leg
	var arm: float = r.arm
	var torso_h: float = r.torso
	var sx: float = r.sx * look.build
	var sy: float = torso_h / 90.0
	var torso_top := -(leg + torso_h)
	# The arm is three parts: upper arm (shoulder to elbow), forearm (elbow to wrist) and the hand with its fingers. `arm` stays the
	# reach from the shoulder to the middle of the palm, as it was when the arm was one straight piece.
	var hs: float = HAND_SCALE[look.age]
	var hand_center := 12.0 * hs
	var upper := (arm - hand_center) * 0.55
	var fore := (arm - hand_center) * 0.45
	var rig := {
		"upper_len": upper, "fore_len": fore, "hand_center": hand_center, "hand_pivot": Vector2(22.0, 6.0) * hs,
		"leg_len": leg, "arm_len": arm, "sx": sx, "head_scale": r.head,
		"torso_top": torso_top, "neck_y": torso_top + 8.0 * sy, "shoulder_y": torso_top + 18.0 * sy,
		"arm_x": 36.0 * sx, "leg_x": 8.0 * sx, "torso_pivot": Vector2(65.0 * sx, 0.0),
		"head_pivot": HEAD_PIVOT, "leg_pivot": Vector2(20, 6), "arm_pivot": Vector2(15, 8),
		"knee_y": roundf(leg * 0.5), "shin_pivot": Vector2(20, SHIN_PAD),
		"pack_pivot": Vector2(54, 10), "lean": deg_to_rad(1.5) if look.age == "senior" else 0.0,
	}
	var tex := {
		"head": _tex(_head_svg(false)),
		"lids": _tex(_head_svg(true)),
		"hair_back": _tex(_head_frame(_hair_back())),
		"hair_front": _tex(_head_frame(_hair_front() + _hat())),
		"torso": _tex(_torso_svg(sx, sy)),
		"upper": _tex(_upper_arm_svg(upper)),
		"fore": _tex(_forearm_svg(fore)),
		"hand_relaxed": _tex(_hand_svg("relaxed", hs)),
		"hand_open": _tex(_hand_svg("open", hs)),
		"hand_flat": _tex(_hand_svg("flat", hs)),
		"hand_grip": _tex(_hand_svg("grip", hs)),
		"thigh": _tex(_thigh_svg(leg)),
		"shin": _tex(_shin_svg(leg)),
	}
	if look.backpack != "":
		tex.backpack = _tex(_backpack_svg())
	return {"rig": rig, "tex": tex, "art": self}


static func _tex(svg: String) -> ImageTexture:
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# --- Palette ---------------------------------------------------------------

func _palette() -> Dictionary:
	var skin := look.skin
	var hair := look.hair_color
	var cloth := look.outfit_color
	var accent := look.accent_color
	var d := {
		"skin": _hex(skin), "skin_line": _hex(_tone(skin, 0.16, 0.25)), "skin_shade": _hex(_tone(skin, 0.04, 0.05)),
		"neck": _hex(_tone(skin, 0.06, 0.06)), "blush": "#F5A3A0", "nose": _hex(_tone(skin, 0.18, 0.3)),
		"iris": _hex(look.eye_color), "iris_dark": _hex(_tone(look.eye_color, 0.35, 0.0)), "pupil": "#22140B",
		"lash": "#2E1C12", "mouth": "#B23A48", "mouth_line": "#8E2A37", "tongue": "#F08A93",
		"hair": _hex(hair), "hair_line": _hex(_tone(hair, 0.22, 0.1)), "hair_light": _hex(hair.lightened(0.3)),
		"hair_mid": _hex(hair.lightened(0.15)),
		"cloth": _hex(cloth), "cloth_shade": _hex(_tone(cloth, 0.06, 0.08)), "cloth_line": _hex(_tone(cloth, 0.25, 0.1)),
		"cloth_fold": _hex(_tone(cloth, 0.04, 0.04)),
		"accent": _hex(accent), "accent_line": _hex(_tone(accent, 0.2, 0.1)), "accent_light": _hex(accent.lightened(0.2)),
		"leg": _hex(look.legwear_color), "leg_line": _hex(_tone(look.legwear_color, 0.25, 0.0)),
		"shoe": _hex(look.shoe_color), "shoe_line": _hex(_tone(look.shoe_color, 0.2, 0.1)), "shoe_light": _hex(look.shoe_color.lightened(0.3)),
		"hat": _hex(look.hat_color), "hat_line": _hex(_tone(look.hat_color, 0.25, 0.0)), "hat_light": _hex(look.hat_color.lightened(0.25)),
		"glasses": look.glasses if look.glasses != "" else "#2B2B2B",
		"scarf": look.scarf if look.scarf != "" else "#E04F5F",
		"pack": look.backpack if look.backpack != "" else "#4A6FA5",
		"white": "#FFFFFF", "sock_line": "#CFC8BA", "sole": "#F7F4EE",
	}
	d.scarf_line = _hex(_tone(Color(d.scarf), 0.25, 0.0))
	d.pack_line = _hex(_tone(Color(d.pack), 0.25, 0.0))
	if look.legwear == "socks" and look.legwear_color.is_equal_approx(Color.WHITE):
		d.leg_line = d.sock_line
	d.merge(look.overrides, true)
	d.brow = d.hair_line
	return d


static func _tone(c: Color, darken: float, saturate: float) -> Color:
	return Color.from_hsv(c.h, clampf(c.s * (1.0 + saturate) + saturate * 0.1, 0.0, 1.0), c.v * (1.0 - darken), c.a)


static func _hex(c: Color) -> String:
	return "#" + c.to_html(false).to_upper()


func _f(s: String) -> String:
	return s.format(p)


# --- Head -------------------------------------------------------------------

func _head_frame(body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><g transform="translate(10 100)">%s</g></svg>' % [
		HEAD_CANVAS.x, HEAD_CANVAS.y, HEAD_CANVAS.x, HEAD_CANVAS.y, body]


func _eye_wrap(cx: float, cy: float, inner: String) -> String:
	if look.age in ["adult", "senior"]:
		return '<g transform="translate(%s %s) scale(0.86) translate(%s %s)">%s</g>' % [cx, cy, -cx, -cy, inner]
	return "<g>%s</g>" % inner


func _head_svg(lids_only: bool) -> String:
	var s := ""
	if lids_only and look.eyes == "almond":
		for e in [[94.0, 130.0, 21.0, 14.0, "M74 131 Q94 137 114 129"], [149.0, 130.0, 18.0, 14.0, "M131 129 Q151 137 168 131"]]:
			s += _eye_wrap(e[0], e[1], _f('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="{skin}"/>' % [e[0], e[1], e[2], e[3]])
				+ _f('<path d="%s" stroke="{lash}" stroke-width="3.6" fill="none" stroke-linecap="round"/>' % e[4]))
		return _head_frame(s)
	if lids_only:
		for e in [[94.0, 130.0, 20.0, 24.0, "M76 132 Q94 144 112 132"], [149.0, 130.0, 17.0, 23.0, "M134 132 Q150 143 165 132"]]:
			s += _eye_wrap(e[0], e[1], _f('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="{skin}"/>' % [e[0], e[1], e[2], e[3]])
				+ _f('<path d="%s" stroke="{lash}" stroke-width="3.5" fill="none" stroke-linecap="round"/>' % e[4]))
		return _head_frame(s)
	s += _f('<ellipse cx="44" cy="132" rx="10" ry="14" fill="{skin_shade}" stroke="{skin_line}" stroke-width="3"/>')
	if look.earring:
		s += '<circle cx="43" cy="145" r="3.2" fill="#F7E08A" stroke="#B58A2E" stroke-width="1"/>'
	s += _f('<path d="M36 120 C36 76 70 58 110 58 C152 58 186 78 186 122 C186 168 156 202 112 202 C68 202 36 166 36 120 Z" fill="{skin}" stroke="{skin_line}" stroke-width="3"/>')
	s += _f('<ellipse cx="76" cy="160" rx="14" ry="9" fill="{blush}" opacity="0.6"/>')
	s += _f('<ellipse cx="164" cy="158" rx="11" ry="8" fill="{blush}" opacity="0.6"/>')
	if look.freckles:
		for f in [[70, 150], [78, 146], [84, 152], [158, 148], [166, 152], [162, 144]]:
			s += _f('<circle cx="%s" cy="%s" r="1.8" fill="{skin_line}" opacity="0.7"/>' % f)
	return _head_base_finish(s)


## What is left of the bare head once the eyes, brows, mouth and glasses (the layers that change with the expression) are set apart:
## the lines of age, the nose, and a beard or stubble.
func _head_base_finish(s: String) -> String:
	if look.age == "senior":
		s += _f('<path d="M170 124 l9 -4 M171 133 l9 1 M60 150 q6 10 4 20" stroke="{skin_line}" stroke-width="2" fill="none" stroke-linecap="round"/>')
	s += _f('<path d="M124 150 Q129 153 125 156" stroke="{nose}" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
	if look.facial_hair == "beard":
		s += _f('<path d="M52 146 C58 196 86 216 114 216 C144 216 172 196 180 146 C170 168 150 184 114 184 C80 184 60 168 52 146 Z" fill="{hair}" stroke="{hair_line}" stroke-width="2.5"/>')
	elif look.facial_hair == "stubble":
		# A few days' growth: a soft shadow along the jaw and over the lip, flecked with short hairs.
		s += _f('<path d="M54 146 C60 192 86 210 114 210 C144 210 170 192 178 146 C168 166 150 180 114 180 C80 180 62 166 54 146 Z" fill="{hair}" opacity="0.38"/>')
		s += _f('<path d="M102 162 Q114 154 123 159 Q132 154 144 162 Q132 166 123 163 Q114 166 102 162 Z" fill="{hair}" opacity="0.45"/>')
		for i in 26:
			var a := float(i) / 25.0
			var x := lerpf(64.0, 168.0, a)
			var y := 158.0 + sin(a * PI) * 40.0 + (i % 3) * 4.0
			s += _f('<circle cx="%.1f" cy="%.1f" r="1.3" fill="{hair_line}" opacity="0.55"/>' % [x, y])
	return _head_frame(s)


# --- The face layers: eyes, brows, mouth and glasses ---------------------------
# Each is a small picture of its own, cut out of the face (`FACE_CROPS`, in face coordinates), so that a character can change
# expression by swapping the pictures (`face_texture`; made when first wanted and kept).

const FACE_CROPS := {
	"eyes": Rect2(52, 90, 150, 82),
	"brows": Rect2(60, 62, 130, 56),
	"mouth": Rect2(90, 146, 68, 62),
	"glasses": Rect2(38, 96, 156, 70),
}
const EYE_KINDS := ["normal", "wide", "happy", "closed", "squint", "sleepy", "sad"]
const BROW_KINDS := ["normal", "raised", "raised_small", "furrow", "sad", "low"]
const MOUTH_KINDS := ["smile", "grin", "open", "sad", "worry", "flat", "pursed", "talk_a", "talk_b", "talk_c", "yum", "laugh", "sleep", "yawn"]

var _face_cache := {}


## The picture of a face layer: `layer` "eyes", "brows", "mouth" or "glasses", `kind` one of EYE_KINDS / BROW_KINDS / MOUTH_KINDS.
func face_texture(layer: String, kind: String) -> ImageTexture:
	var key := layer + ":" + kind
	if not _face_cache.has(key):
		var body := ""
		match layer:
			"eyes":
				body = _eyes_svg(kind)
			"brows":
				body = _brows_svg(kind)
			"mouth":
				body = _mouth_svg(kind)
			_:
				body = _glasses_svg()
		var r: Rect2 = FACE_CROPS[layer]
		_face_cache[key] = _tex('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s %s %s %s">%s</svg>' % [
			r.size.x, r.size.y, r.position.x, r.position.y, r.size.x, r.size.y, body])
	return _face_cache[key]


## Where a face layer's top-left corner sits in the head sprite's own space (the head picture's pivot is HEAD_PIVOT).
static func face_offset(layer: String) -> Vector2:
	var r: Rect2 = FACE_CROPS[layer]
	return r.position + Vector2(10.0, 100.0) - HEAD_PIVOT


func _eyes_svg(kind: String) -> String:
	if look.eyes == "almond":
		return _almond_eyes(kind)
	var out := ""
	var lash1 := '<path d="M77 117 L72 109" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/><path d="M82 112 L79 104" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/>'
	var lash2 := '<path d="M164 117 L169 109" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/><path d="M159 112 L162 104" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/>'
	# Left eye (the far one for a right-facing face: outer corner left), then right.
	for e in [
		{"cx": 94.0, "cy": 130.0, "rx": 18.0, "ry": 22.0, "ix": 97.0, "ir": 15.0, "dr": 10.0, "pr": 6.5, "h1": Vector2(103, 126), "r1": 5.5, "h2": Vector2(91, 141), "r2": 2.5,
			"arc": "M76 120 Q93 103 112 118", "lash": lash1, "closed": "M76 132 Q94 144 112 132", "outer": -1.0, "id": "rl"},
		{"cx": 149.0, "cy": 130.0, "rx": 15.0, "ry": 21.0, "ix": 152.0, "ir": 13.0, "dr": 8.5, "pr": 5.5, "h1": Vector2(157, 126), "r1": 4.8, "h2": Vector2(147, 141), "r2": 2.2,
			"arc": "M134 118 Q150 103 165 120", "lash": lash2, "closed": "M134 132 Q150 143 165 132", "outer": 1.0, "id": "rr"}]:
		var cx: float = e.cx
		var cy: float = e.cy
		var inner := ""
		match kind:
			"happy":
				# A smiling arch, like a closed happy eye, lashes at the outer corner.
				inner = _f('<path d="M%s %s Q%s %s %s %s" stroke="{lash}" stroke-width="4.4" fill="none" stroke-linecap="round"/>' % [cx - e.rx, cy + 5, cx, cy - 17, cx + e.rx, cy + 5])
				if look.lashes:
					inner += _f('<path d="M%s %s l%s -6" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/>' % [cx + e.outer * (e.rx + 1), cy + 1, e.outer * 4])
			"closed":
				inner = _f('<path d="%s" stroke="{lash}" stroke-width="3.8" fill="none" stroke-linecap="round"/>' % e.closed)
				if look.lashes:
					inner += _f('<path d="M%s %s l%s 5" stroke="{lash}" stroke-width="2.4" stroke-linecap="round"/>' % [cx + e.outer * e.rx * 0.9, cy + 9, e.outer * 4])
			_:
				var k := 1.0
				var iris_k := 1.0
				if kind == "wide":
					k = 1.13
					iris_k = 0.82
				inner = '<g transform="translate(%s %s) scale(%s) translate(%s %s)">' % [cx, cy, k, -cx, -cy]
				inner += _f('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF"/>' % [cx, cy, e.rx, e.ry])
				inner += '<g transform="translate(%s %s) scale(%s) translate(%s %s)">' % [e.ix, cy + 5, iris_k, -e.ix, -(cy + 5)]
				inner += _f('<circle cx="%s" cy="%s" r="%s" fill="{iris}"/><circle cx="%s" cy="%s" r="%s" fill="{iris_dark}"/>' % [e.ix, cy + 3, e.ir, e.ix, cy + 6, e.dr])
				inner += _f('<circle cx="%s" cy="%s" r="%s" fill="{pupil}"/>' % [e.ix, cy + 5, e.pr * (1.18 if kind == "wide" else 1.0)])
				inner += '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/><circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>' % [e.h1.x, e.h1.y, e.r1, e.h2.x, e.h2.y, e.r2]
				inner += '</g>'
				# A lid coming down over the top of the eye (squinting, sleepy, sad: the outer corner drooping).
				var drop := {"squint": [0.62, 0.62], "sleepy": [1.0, 1.0], "sad": [0.8, 0.22]}.get(kind, [0.0, 0.0]) as Array
				if kind in ["squint", "sleepy", "sad"]:
					var left: float = e.ry * (drop[0] if e.outer < 0.0 else drop[1])
					var right: float = e.ry * (drop[1] if e.outer < 0.0 else drop[0])
					inner += '<clipPath id="%s"><ellipse cx="%s" cy="%s" rx="%s" ry="%s"/></clipPath>' % [e.id, cx, cy, e.rx, e.ry]
					inner += _f('<g clip-path="url(#%s)"><path d="M%s %s L%s %s L%s %s L%s %s Z" fill="{skin}"/>' % [e.id, cx - e.rx - 4, cy - e.ry - 6, cx + e.rx + 4, cy - e.ry - 6, cx + e.rx + 4, cy - e.ry + right, cx - e.rx - 4, cy - e.ry + left])
					inner += _f('<path d="M%s %s L%s %s" stroke="{lash}" stroke-width="3" stroke-linecap="round"/></g>' % [cx - e.rx - 4, cy - e.ry + left, cx + e.rx + 4, cy - e.ry + right])
				inner += _f('<path d="%s" stroke="{lash}" stroke-width="3.5" fill="none" stroke-linecap="round"/>' % e.arc)
				if look.lashes:
					inner += _f(e.lash)
				inner += '</g>'
		out += _eye_wrap(cx, cy, inner)
	return out


## Narrow almond eyes: an almond-shaped white, a dark iris and pupil clipped to it, an upper lid line that flicks up at the
## outer corner, the outer corners lifted a little; a smooth lid with no deep crease. `kind` as for `_eyes_svg`.
func _almond_eyes(kind := "normal") -> String:
	var out := ""
	for e in [[94.0, 130.0, 8.0, "eyeL", -1.0], [149.0, 130.0, -8.0, "eyeR", 1.0]]:
		var cx: float = e[0]
		var cy: float = e[1]
		var side: float = e[4]
		var w := 20.0 if side < 0.0 else 17.0
		var k := 1.12 if kind == "wide" else 1.0
		var shape := "M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" % [cx - w, cy + 1, cx, cy - 15, cx + w, cy - 1, cx, cy + 11, cx - w, cy + 1]
		var inner := ""
		if kind == "happy":
			inner = _f('<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="{lash}" stroke-width="4" fill="none" stroke-linecap="round"/>' % [cx - w, cy + 4, cx, cy - 14, cx + w, cy + 4])
		elif kind == "closed":
			inner = _f('<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="{lash}" stroke-width="3.8" fill="none" stroke-linecap="round"/>' % [cx - w, cy + 1, cx, cy + 9, cx + w, cy - 1])
		else:
			inner = '<g transform="translate(%s %s) scale(%s) translate(%s %s)">' % [cx, cy, k, -cx, -cy]
			inner += '<clipPath id="%s"><path d="%s"/></clipPath>' % [e[3], shape]
			inner += '<path d="%s" fill="#FBFAF6"/>' % shape
			inner += _f('<g clip-path="url(#%s)"><circle cx="%.1f" cy="%.1f" r="11" fill="{iris}"/><circle cx="%.1f" cy="%.1f" r="8" fill="{iris_dark}"/><circle cx="%.1f" cy="%.1f" r="5.2" fill="{pupil}"/>' % [e[3], cx + 2, cy, cx + 2, cy + 1, cx + 2, cy + 1]
				+ '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#000000" opacity="0.28"/>' % [cx - w, cy - 3, cx, cy - 12, cx + w, cy - 3, cx + w, cy - 8, cx - w, cy - 8])
			# A lid over the top of the eye: squinting, sleepy, sad (the outer corner lower).
			var drops := {"squint": [10.0, 10.0], "sleepy": [17.0, 17.0], "sad": [14.0, 4.0]}
			if drops.has(kind):
				var d: Array = drops[kind]
				var outer_drop: float = d[0]
				var inner_drop: float = d[1]
				var left: float = outer_drop if side < 0.0 else inner_drop
				var right: float = inner_drop if side < 0.0 else outer_drop
				inner += _f('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="{skin}"/>' % [cx - w - 3, cy - 20, cx + w + 3, cy - 20, cx + w + 3, cy - 14 + right, cx - w - 3, cy - 14 + left])
				inner += _f('<path d="M%.1f %.1f L%.1f %.1f" stroke="{lash}" stroke-width="3" stroke-linecap="round"/>' % [cx - w, cy - 14 + left, cx + w, cy - 14 + right])
			inner += '</g>'
			inner += '<circle cx="%.1f" cy="%.1f" r="2.8" fill="#FFFFFF"/>' % [cx + 6, cy - 3]
			inner += _f('<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="{lash}" stroke-width="3.6" fill="none" stroke-linecap="round"/>' % [cx - w - 1, cy + 1, cx, cy - 15, cx + w + 1, cy - 1])
			# The flick at the outer corner and a thin line under the eye.
			var corner := cx + side * (w + 1.0)
			inner += _f('<path d="M%.1f %.1f L%.1f %.1f" stroke="{lash}" stroke-width="3" stroke-linecap="round"/>' % [corner, cy - 1 * 1.0 if side > 0.0 else cy + 1, corner + side * 5, cy - 6])
			inner += _f('<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="{skin_line}" stroke-width="1.4" fill="none" opacity="0.6"/>' % [cx - w + 4, cy + 7, cx, cy + 13, cx + w - 4, cy + 7])
		out += '<g transform="rotate(%.1f %.1f %.1f)">%s</g>' % [e[2], cx, cy, _eye_wrap(cx, cy, inner)]
	return out


func _brows_svg(kind: String) -> String:
	var brow_w := "4.5" if look.age in ["adult", "senior"] and not look.lashes else "3.5"
	# Outer end, the arch, the inner end of the left brow (the right one is its mirror about x = 122).
	var base := [Vector2(80, 94), Vector2(93, 86), Vector2(106, 91)] if look.eyes != "almond" else [Vector2(78, 99), Vector2(93, 93), Vector2(108, 97)]
	# (everything up by `dy`, the outer end by `out`, the inner end by `inn`, the arch by `arch`; positive = down)
	var shape: Array = {"normal": [0, 0, 0, 0], "raised": [-6, 0, 0, -2], "raised_small": [-3, 0, 0, -1], "furrow": [1, -2, 6, 1],
		"sad": [-1, 4, -7, 0], "low": [3, 0, 2, 1]}.get(kind, [0, 0, 0, 0])
	var out := ""
	for side in [-1.0, 1.0]:
		var pts: Array = []
		for i in 3:
			var q: Vector2 = base[i]
			if side > 0.0:
				q.x = 244.0 - q.x
			var adj: float = shape[0] + (shape[1] if i == 0 else (shape[3] if i == 1 else shape[2]))
			pts.append(Vector2(q.x + (shape[2] * 0.25 * -side if i == 2 and kind == "furrow" else 0.0), q.y + adj))
		var d := "M%.1f %.1f Q%.1f %.1f %.1f %.1f" % [pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y]
		out += _f('<path d="%s" stroke="{brow}" stroke-width="%s" fill="none" stroke-linecap="round"/>' % [d, brow_w])
	return out


func _mouth_svg(kind: String) -> String:
	var s := ""
	var cx := 123.0
	match kind:
		"grin":
			s += _f('<path d="M103 163 Q123 196 143 163 Q123 170 103 163 Z" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.2" stroke-linejoin="round"/>')
			s += '<path d="M107 165 Q123 172 139 165 L138 170 Q123 176 108 170 Z" fill="#FFFFFF"/>'
			s += _f('<path d="M114 182 Q123 176 132 182 Q123 189 114 182 Z" fill="{tongue}"/>')
		"laugh":
			s += _f('<path d="M100 160 Q123 202 146 160 Q123 168 100 160 Z" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.2" stroke-linejoin="round"/>')
			s += '<path d="M105 162 Q123 171 141 162 L140 168 Q123 176 106 168 Z" fill="#FFFFFF"/>'
			s += _f('<path d="M111 186 Q123 177 135 186 Q123 195 111 186 Z" fill="{tongue}"/>')
		"yum":
			s += _f('<path d="M106 164 Q123 190 140 164 Q123 169 106 164 Z" fill="{mouth}" stroke="{mouth_line}" stroke-width="2" stroke-linejoin="round"/>')
			s += _f('<path d="M126 176 Q137 177 138 186 Q130 190 124 182 Z" fill="{tongue}" stroke="{mouth_line}" stroke-width="1.4" stroke-linejoin="round"/>')
			s += _f('<path d="M134 167 Q139 166 141 161" stroke="{mouth_line}" stroke-width="2" fill="none" stroke-linecap="round"/>')
		"open":
			s += _f('<ellipse cx="123" cy="174" rx="7.5" ry="10" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.4"/>')
			s += _f('<ellipse cx="123" cy="180" rx="4.5" ry="3.4" fill="{tongue}"/>')
		"yawn":
			s += _f('<ellipse cx="123" cy="177" rx="10" ry="14" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.4"/>')
			s += _f('<ellipse cx="123" cy="186" rx="6.5" ry="5" fill="{tongue}"/>')
		"pursed":
			s += _f('<ellipse cx="123" cy="170" rx="4.5" ry="5.5" fill="{mouth}" stroke="{mouth_line}" stroke-width="2"/>')
		"sad":
			s += _f('<path d="M109 177 Q123 164 137 177" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
		"worry":
			s += _f('<path d="M113 174 Q123 168 133 174" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
		"flat":
			s += _f('<path d="M112 169 H134" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
		"sleep":
			s += _f('<path d="M114 169 Q123 174 132 169" stroke="{mouth_line}" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
		"talk_a":
			s += _f('<ellipse cx="123" cy="170" rx="9" ry="5.5" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.2"/>')
			s += _f('<ellipse cx="123" cy="173" rx="5" ry="2.2" fill="{tongue}"/>')
		"talk_b":
			s += _f('<ellipse cx="123" cy="172" rx="6" ry="8.5" fill="{mouth}" stroke="{mouth_line}" stroke-width="2.2"/>')
			s += _f('<ellipse cx="123" cy="176" rx="3.6" ry="3" fill="{tongue}"/>')
		"talk_c":
			s += _f('<path d="M112 168 Q123 174 134 168" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
		_:
			# The look's own mouth: a smile, or a small open smile.
			if look.mouth == "open_smile":
				s += _f('<path d="M110 166 Q123 180 136 166 Z" fill="{mouth}" stroke="{mouth_line}" stroke-width="2" stroke-linejoin="round"/>')
				s += _f('<path d="M116 172 Q123 178 130 172 Q123 170 116 172 Z" fill="{tongue}"/>')
			else:
				s += _f('<path d="M110 167 Q123 177 136 167" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
	if look.facial_hair in ["beard", "mustache"]:
		s += _f('<path d="M104 161 Q114 152 123 158 Q132 152 142 161 Q132 166 123 162 Q114 166 104 161 Z" fill="{hair}" stroke="{hair_line}" stroke-width="2"/>')
	return s


func _glasses_svg() -> String:
	if look.glasses == "":
		return ""
	var s := _f('<g fill="#FFFFFF" fill-opacity="0.15" stroke="{glasses}" stroke-width="3.5"><circle cx="94" cy="130" r="25"/><circle cx="150" cy="130" r="23"/></g>')
	s += _f('<path d="M119 127 Q123 122 127 127 M69 126 L48 122" stroke="{glasses}" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
	return s


# --- Hair & hats ----------------------------------------------------------

const _CHARLOTTE_FRONT := 'M34 120 C28 60 70 24 112 24 C160 24 196 56 192 112 C184 92 170 80 150 74 C140 82 118 88 96 86 C88 78 82 74 76 72 C66 90 60 104 58 124 C54 140 52 160 56 178 C40 166 34 140 34 120 Z'
const _SWEPT_FRONT := 'M38 118 C30 62 70 28 112 28 C158 28 192 58 190 104 C176 84 150 70 120 68 C96 66 70 76 56 96 C50 104 46 112 44 124 Z'
const _CAP_BACK := 'M36 126 C28 68 70 30 112 30 C160 30 196 66 190 126 C172 146 56 146 36 126 Z'


func _hair_shape(d: String, width := 3.0) -> String:
	return _f('<path d="%s" fill="{hair}" stroke="{hair_line}" stroke-width="%s" stroke-linejoin="round"/>' % [d, width]) + _strands(d)


# Fine strands of hair flowing down from the crown, darker ones and a few catching the light, clipped to the
# hair shape `d` so they never stray onto the face, whatever the hairstyle.
func _strands(d: String) -> String:
	if look.hair_style in ["curly", "buzz", "bald"]:
		return ""
	_clip_id += 1
	var id := "hair%d" % _clip_id
	var s := '<clipPath id="%s"><path d="%s"/></clipPath><g clip-path="url(#%s)" fill="none" stroke-linecap="round">' % [id, d, id]
	var wavy := look.hair_style == "long_wavy"
	for i in 13:
		var k := (i - 6.0) / 6.0
		var top := Vector2(112.0 + k * 20.0, 20.0)
		var mid := Vector2(112.0 + k * 92.0, 110.0)
		var end := Vector2(112.0 + k * 104.0 + (8.0 if wavy and i % 2 == 0 else 0.0), 280.0)
		var wave := (14.0 if i % 2 == 0 else -14.0) if wavy else 0.0
		var path := "M%.1f %.1f Q%.1f %.1f %.1f %.1f T%.1f %.1f" % [top.x, top.y, mid.x - wave, mid.y - 40.0, mid.x, mid.y, end.x, end.y]
		s += _f('<path d="%s" stroke="{hair_line}" stroke-width="1.8" opacity="0.4"/>' % path)
		if i % 3 == 1:
			s += _f('<path d="%s" stroke="{hair_light}" stroke-width="1.4" opacity="0.55" transform="translate(4 2)"/>' % path)
	return s + '</g>'


func _hair_back() -> String:
	# Under a tuque the hair is tucked in: no bun or buns sticking out above it, and curls only round the sides.
	var tucked := look.hat == "tuque"
	if tucked and look.hair_style in ["bun", "space_buns"]:
		return _hair_shape(_CAP_BACK)
	match look.hair_style:
		"long_wavy":
			return _hair_shape("M110 22 C170 20 205 60 200 120 C198 160 210 200 196 236 C188 256 168 258 160 244 C150 258 132 256 128 240 L110 190 L80 200 C78 230 70 252 52 256 C34 258 26 244 30 228 C14 220 14 196 24 180 C12 150 16 100 34 70 C52 38 80 24 110 22 Z") \
				+ _f('<g stroke="{hair_line}" stroke-width="3" fill="none" stroke-linecap="round"><path d="M36 150 C30 180 44 200 38 226"/><path d="M60 196 C62 220 58 236 50 248"/><path d="M190 150 C196 180 194 206 182 232"/></g>')
		"long_straight":
			return _hair_shape("M110 24 C166 22 200 60 196 120 L198 246 Q164 256 132 246 L112 190 L84 200 L80 248 Q50 258 24 248 L26 120 C22 60 56 26 110 24 Z") \
				+ _f('<path d="M40 150 V236 M188 150 V236" stroke="{hair_line}" stroke-width="3" stroke-linecap="round"/>')
		"bob":
			return _hair_shape("M34 120 C28 60 70 26 112 26 C160 26 196 58 194 118 C196 160 190 194 176 206 L48 206 C34 192 30 160 34 120 Z")
		"ponytail":
			return _hair_shape(_CAP_BACK) + _hair_shape("M48 84 C12 92 2 152 16 212 C22 234 42 232 40 208 C36 162 42 122 64 98 Z") \
				+ _f('<circle cx="50" cy="90" r="9" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
		"bun":
			return _hair_shape(_CAP_BACK) + _hair_shape("M76 34 m-30 0 a30 28 0 1 0 60 0 a30 28 0 1 0 -60 0") \
				+ _f('<path d="M60 44 Q76 56 94 44" stroke="{accent}" stroke-width="5" fill="none" stroke-linecap="round"/>')
		"curly":
			var s := ""
			for i in 15:
				var a := lerpf(PI * 0.62, PI * 2.38, i / 14.0)
				var c := Vector2(112, 118) + Vector2(cos(a) * 88.0, sin(a) * 92.0)
				if tucked and c.y < 96.0:
					continue
				s += _f('<circle cx="%.1f" cy="%.1f" r="%d" fill="{hair}" stroke="{hair_line}" stroke-width="3"/>' % [c.x, c.y, 24 if tucked else 30])
			return s + _hair_shape("M30 120 C30 50 70 22 112 22 C160 22 196 50 194 120 C190 170 40 170 30 120 Z", 0.0)
		"pigtails":
			return _hair_shape(_CAP_BACK) \
				+ _hair_shape("M44 96 C10 104 2 160 14 206 C20 226 40 222 38 200 C34 160 40 126 60 106 Z") \
				+ _hair_shape("M180 96 C214 104 222 160 210 206 C204 226 184 222 186 200 C190 160 184 126 164 106 Z") \
				+ _f('<circle cx="48" cy="100" r="9" fill="{accent}" stroke="{accent_line}" stroke-width="2"/><circle cx="176" cy="100" r="9" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
		"braids":
			var b := _hair_shape(_CAP_BACK)
			for side: float in [-1.0, 1.0]:
				var x0 := 112.0 + side * 70.0
				for i in 7:
					var y := 118.0 + i * 20.0
					var r := 15.0 - i * 0.8
					b += _f('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="12" fill="{hair}" stroke="{hair_line}" stroke-width="2.5" transform="rotate(%d %.1f %.1f)"/>' % [x0 + side * i * 1.5, y, r, 20 if i % 2 == 0 else -20, x0 + side * i * 1.5, y])
				var tip := Vector2(x0 + side * 11.0, 262.0)
				b += _f('<path d="M%.1f %.1f l-8 20 h16 Z" fill="{hair}" stroke="{hair_line}" stroke-width="2.5" stroke-linejoin="round"/>' % [tip.x, tip.y - 2])
				b += _f('<rect x="%.1f" y="%.1f" width="16" height="7" rx="3" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>' % [tip.x - 8, tip.y - 6])
			return b
		"space_buns":
			return _hair_shape(_CAP_BACK) \
				+ _hair_shape("M62 42 m-28 0 a28 26 0 1 0 56 0 a28 26 0 1 0 -56 0") \
				+ _hair_shape("M162 42 m-28 0 a28 26 0 1 0 56 0 a28 26 0 1 0 -56 0") \
				+ _f('<path d="M46 56 Q62 66 80 56 M146 56 Q162 66 180 56" stroke="{accent}" stroke-width="5" fill="none" stroke-linecap="round"/>')
		"short", "buzz":
			return _hair_shape(_CAP_BACK)
		"bald":
			return _hair_shape("M40 150 C30 126 36 104 50 96 L62 152 Z M184 98 C194 112 194 132 186 148 L176 150 Z", 2.5)
	return ""


func _hair_front() -> String:
	var shine := _f('<path d="M66 54 C92 36 136 36 164 52" stroke="{hair_light}" stroke-width="8" fill="none" stroke-linecap="round"/>')
	match look.hair_style:
		"long_wavy", "long_straight", "bob", "pigtails":
			return _hair_shape(_CHARLOTTE_FRONT) \
				+ _f('<path d="M76 72 C80 60 92 50 108 44" stroke="{hair_line}" stroke-width="2.5" fill="none" stroke-linecap="round"/>') \
				+ shine + _f('<path d="M176 64 C180 70 182 76 183 82" stroke="{hair_light}" stroke-width="5" fill="none" stroke-linecap="round"/>') \
				+ _f('<path d="M48 96 C46 110 46 124 48 136" stroke="{hair_mid}" stroke-width="4" fill="none" stroke-linecap="round"/>')
		"ponytail", "bun", "braids", "space_buns":
			return _hair_shape(_SWEPT_FRONT) + _f('<path d="M70 60 C92 44 132 42 160 54" stroke="{hair_light}" stroke-width="7" fill="none" stroke-linecap="round"/>')
		"curly":
			var s := ""
			for i in 7:
				s += _f('<circle cx="%d" cy="%d" r="16" fill="{hair}" stroke="{hair_line}" stroke-width="2.5"/>' % [56 + i * 20, 70 - absi(3 - i) * -3])
			return s
		"short":
			return _hair_shape("M38 122 C30 64 68 30 112 30 C158 30 194 60 190 118 C182 96 168 84 150 80 C130 90 98 90 76 82 C64 92 54 104 50 122 Z") + shine
		"buzz":
			return _hair_shape("M40 112 C36 68 70 46 112 46 C156 46 186 68 184 108 C170 94 140 86 112 86 C84 86 56 94 40 112 Z", 2.0)
	return ""


func _hat() -> String:
	match look.hat:
		"tuque":
			var s := _f('<path d="M32 86 C30 36 70 12 112 12 C156 12 194 36 192 86 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3"/>')
			s += _f('<rect x="26" y="64" width="172" height="26" rx="12" fill="{hat_line}" stroke="{hat_line}" stroke-width="2"/>')
			for x in range(36, 192, 10):
				s += _f('<path d="M%d 68 V86" stroke="{hat}" stroke-width="3" stroke-linecap="round" opacity="0.6"/>' % x)
			s += _f('<path d="M56 62 Q60 34 98 22" stroke="{hat_light}" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.35"/>')
			s += _f('<path d="M26 66 H198" stroke="{hat_light}" stroke-width="1.6" opacity="0.35"/>')
			return s + _f('<circle cx="112" cy="8" r="17" fill="{hat_light}" stroke="{hat_line}" stroke-width="2.5"/>') + _f('<path d="M100 2 Q112 -4 122 4 M102 12 Q112 6 122 12" stroke="{hat_line}" stroke-width="1.3" fill="none" opacity="0.45"/>')
		"helmet":
			# A bike helmet: a long shell with vents, a little visor at the front, the strap under the ear.
			return _f('<path d="M168 90 L172 128" stroke="#2B2B2B" stroke-width="4" stroke-linecap="round"/>'
				+ '<path d="M22 100 C12 52 56 10 116 8 C170 6 206 40 206 84 L216 90 C206 98 192 94 186 90 C150 80 84 86 22 100 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3" stroke-linejoin="round"/>'
				+ '<path d="M30 92 C80 80 150 76 204 86" stroke="#2B2B2B" stroke-width="5" fill="none" stroke-linecap="round"/>'
				+ '<path d="M62 46 Q88 30 112 30 M76 66 Q110 48 148 52 M134 22 Q160 24 178 40" stroke="{hat_line}" stroke-width="8" fill="none" stroke-linecap="round"/>'
				+ '<path d="M40 70 Q48 34 92 20" stroke="{hat_light}" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.8"/>')
		"cap":
			return _f('<path d="M36 94 C34 44 72 22 112 22 C152 22 188 44 188 94 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3"/>'
				+ '<path d="M150 84 Q200 80 228 96 Q196 102 150 96 Z" fill="{hat_line}" stroke="{hat_line}" stroke-width="2"/>'
				+ '<circle cx="112" cy="24" r="6" fill="{hat_line}"/>'
				+ '<path d="M112 26 V94 M74 36 Q86 60 90 94 M150 36 Q138 60 134 94" stroke="{hat_line}" stroke-width="1.6" fill="none" opacity="0.5"/>'
				+ '<path d="M48 70 Q56 40 90 26" stroke="{hat_light}" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.3"/>'
				+ '<path d="M152 90 Q196 90 222 98" stroke="#000000" stroke-width="3" fill="none" opacity="0.18"/>')
		"witch":
			return _f('<path d="M54 82 L132 -84 Q146 -90 146 -74 L176 80 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3" stroke-linejoin="round"/>'
				+ '<rect x="56" y="58" width="118" height="16" fill="#FF8A3D"/>'
				+ '<path d="M-6 88 Q112 62 230 88 Q112 108 -6 88 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3"/>'
				+ '<path d="M140 -40 l4 8 l8 1 l-6 6 l2 8 l-8 -4 l-8 4 l2 -8 l-6 -6 l8 -1 z" fill="#FFD23F"/>')
		"cat_ears":
			return _f('<path d="M44 92 C46 40 78 22 112 22 C150 22 180 40 182 92" stroke="{hat}" stroke-width="7" fill="none"/>'
				+ '<path d="M56 64 L58 6 L98 40 Z M128 38 L168 4 L172 62 Z" fill="{hat}" stroke="{hat_line}" stroke-width="2" stroke-linejoin="round"/>'
				+ '<path d="M64 52 L65 22 L86 40 Z M138 38 L160 20 L162 50 Z" fill="#FF9DBB"/>')
		"bow":
			return _f('<path d="M150 30 L118 8 Q108 30 118 52 Z M150 30 L182 8 Q192 30 182 52 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3" stroke-linejoin="round"/>'
				+ '<path d="M124 18 Q120 30 124 42 M176 18 Q180 30 176 42" stroke="{hat_light}" stroke-width="3" fill="none" stroke-linecap="round"/>'
				+ '<circle cx="150" cy="30" r="9" fill="{hat_light}" stroke="{hat_line}" stroke-width="3"/>')
		"crown":
			return ('<path d="M66 40 L72 -6 L92 18 L112 -16 L132 18 L152 -6 L158 40 Z" fill="#FFD23F" stroke="#C99410" stroke-width="3" stroke-linejoin="round"/>'
				+ '<rect x="64" y="34" width="96" height="12" rx="4" fill="#F2B632" stroke="#C99410" stroke-width="2.5"/>'
				+ _f('<circle cx="112" cy="40" r="5" fill="{hat}"/><circle cx="86" cy="40" r="4" fill="{hat_light}"/><circle cx="138" cy="40" r="4" fill="{hat_light}"/>')
				+ '<circle cx="72" cy="-6" r="4" fill="#FFF3B0"/><circle cx="112" cy="-16" r="4" fill="#FFF3B0"/><circle cx="152" cy="-6" r="4" fill="#FFF3B0"/>')
		"beret":
			return _f('<path d="M26 62 Q30 2 116 2 Q198 6 202 52 Q160 72 26 62 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3" stroke-linejoin="round"/>'
				+ '<path d="M40 50 Q46 14 110 12" stroke="{hat_light}" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.7"/>'
				+ '<path d="M112 2 Q114 -10 122 -12" stroke="{hat_line}" stroke-width="5" fill="none" stroke-linecap="round"/>')
		"headband":
			return _f('<path d="M38 70 C40 30 76 14 112 14 C150 14 184 30 186 70" stroke="{hat_line}" stroke-width="13" fill="none" stroke-linecap="round"/>'
				+ '<path d="M38 70 C40 30 76 14 112 14 C150 14 184 30 186 70" stroke="{hat}" stroke-width="9" fill="none" stroke-linecap="round"/>'
				+ '<path d="M60 36 Q80 22 104 19" stroke="{hat_light}" stroke-width="3" fill="none" stroke-linecap="round"/>')
	return ""


# --- Body -------------------------------------------------------------------

func _torso_svg(sx: float, sy: float) -> String:
	var w := 130.0 * sx
	var h := 152.0 * sy
	var s := CLOTH_DEFS + _f('<rect x="57" y="0" width="16" height="20" fill="{neck}"/>')
	match look.outfit:
		"dress":
			s += _dress()
		"coat":
			s += _coat()
		"overalls":
			s += _overalls()
		"hoodie":
			s += _top() + _hoodie()
		_:
			s += _top()
	if look.backpack != "":
		s += _f('<path d="M44 14 Q38 50 42 92" stroke="{pack_line}" stroke-width="6" fill="none" stroke-linecap="round"/>')
	if look.scarf != "":
		s += _f('<path d="M38 10 Q65 28 92 10 L94 24 Q65 42 36 24 Z" fill="{scarf}" stroke="{scarf_line}" stroke-width="2.5" stroke-linejoin="round"/>')
		s += _f('<path d="M44 24 L38 70 L54 72 L56 28 Z" fill="{scarf}" stroke="{scarf_line}" stroke-width="2.5" stroke-linejoin="round"/>')
		# Knitted: rows across the wrap and down the hanging end, a sheen on the fold.
		s += _f('<path d="M44 16 Q65 32 88 16 M42 21 Q65 38 90 21" stroke="{scarf_line}" stroke-width="1.3" fill="none" opacity="0.4"/>')
		for y in [34, 42, 50, 58]:
			s += _f('<path d="M%s %d L%s %d" stroke="{scarf_line}" stroke-width="1.3" opacity="0.4"/>' % [43.0 - (y - 30) * 0.12, y, 55.0 - (y - 30) * 0.12, y + 1])
		s += '<path d="M47 28 L43 62" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" opacity="0.25"/>'
		s += _f('<path d="M40 64 L54 66 M41 72 V80 M46 72 V81 M51 72 V80" stroke="{scarf_line}" stroke-width="2"/>')
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><g transform="scale(%s %s)">%s</g></svg>' % [
		ceili(w), ceili(h), ceili(w), ceili(h), sx, sy, s]


const DRESS_SKIRT := "M26 62 H104 Q118 100 128 140 Q120 148 108 142 Q98 150 86 143 Q76 150 65 143 Q54 150 44 143 Q32 150 22 142 Q10 148 2 140 Q12 100 26 62 Z"
const DRESS_BODICE := "M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 Q107 50 104 64 H26 Q23 50 22 32 Q22 22 30 18 Z"


func _dress() -> String:
	var s := _f('<path d="%s" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % DRESS_SKIRT)
	s += _sheen(DRESS_SKIRT)
	s += _f('<path d="M26 66 Q14 100 4 138 Q10 144 18 141 Q24 100 34 66 Z" fill="{cloth_shade}"/>')
	s += _f('<g stroke="{cloth_fold}" stroke-width="2.5" fill="none" stroke-linecap="round"><path d="M50 72 Q46 106 40 138"/><path d="M80 72 Q84 106 90 138"/></g>')
	# Gathers under the waistband, soft folds falling to the hem.
	s += _f('<g stroke="{cloth_line}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.4">%s</g>' % _gathers())
	s += _f('<path d="M3 139 Q10 146 22 141 Q32 148 44 142 Q54 148 65 142 Q76 148 86 142 Q98 148 108 141 Q120 146 127 139" stroke="{accent}" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.85"/>')
	s += _pattern([[36, 96], [62, 88], [94, 96], [50, 122], [78, 116], [106, 126], [22, 128]], [[70, 132], [96, 110], [40, 110]])
	if look.pattern == "stripes":
		s += '<clipPath id="skirt"><path d="M26 62 H104 Q118 100 128 140 L2 140 Q12 100 26 62 Z"/></clipPath><g clip-path="url(#skirt)">'
		for y in [80, 100, 120]:
			s += _f('<rect x="0" y="%d" width="130" height="9" fill="{accent}" opacity="0.9"/>' % y)
		s += '</g>'
	s += _f('<path d="%s" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % DRESS_BODICE)
	s += _sheen(DRESS_BODICE)
	s += _f('<path d="M24 34 Q24 24 32 20 Q28 40 30 62 H26 Z" fill="{cloth_shade}"/>')
	# Two darts and a seam under the bust give the bodice its shape.
	s += _f('<path d="M50 40 Q54 50 52 60 M80 40 Q76 50 78 60" stroke="{cloth_line}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.35"/>')
	s += _pattern([[80, 40], [48, 46]], [], 3.5)
	s += '<path d="M42 13 Q46 30 65 25 Q84 30 88 13 Q65 23 42 13 Z" fill="#FFFFFF" stroke="#CFC8BA" stroke-width="1.5" stroke-linejoin="round"/>'
	s += _f('<rect x="24" y="58" width="82" height="10" rx="3" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
	s += _f('<path d="M38 63 L24 54 Q20 63 24 72 Z" fill="{accent_light}" stroke="{accent_line}" stroke-width="2" stroke-linejoin="round"/>')
	s += _f('<path d="M38 63 L52 54 Q56 63 52 72 Z" fill="{accent_light}" stroke="{accent_line}" stroke-width="2" stroke-linejoin="round"/>')
	s += _f('<circle cx="38" cy="63" r="5" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
	return s


# The sheen and the hem shade over a garment's outline `d`.
func _sheen(d: String) -> String:
	return '<path d="%s" fill="url(#cs)"/><path d="%s" fill="url(#cv)"/>' % [d, d]


func _gathers() -> String:
	var g := ""
	for x in [36.0, 48.0, 60.0, 72.0, 84.0, 96.0]:
		g += '<path d="M%.1f 70 q-1 6 0 12"/>' % x
	for x in [16.0, 30.0, 64.0, 98.0, 112.0]:
		g += '<path d="M%.1f 140 q2 -14 -1 -26"/>' % x
	return g


# Creases on a top: under the arms, at the waist, a pull at the hem.
func _top_folds() -> String:
	return _f('<g stroke="{cloth_line}" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.4">'
		+ '<path d="M28 36 Q36 44 33 58"/><path d="M102 36 Q94 44 97 58"/>'
		+ '<path d="M44 84 Q52 90 48 100"/><path d="M86 86 Q80 92 84 100"/><path d="M60 96 q4 4 2 8"/></g>')


func _pattern(big: Array, small: Array, r := 4.5) -> String:
	var s := ""
	match look.pattern:
		"dots":
			for c in big:
				s += '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>' % [c[0], c[1], r]
			for c in small:
				s += _f('<circle cx="%s" cy="%s" r="2.5" fill="{accent_light}"/>' % c)
		"flowers":
			for c in big:
				for i in 5:
					var a := TAU * i / 5.0
					s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFFFFF"/>' % [c[0] + cos(a) * r * 0.75, c[1] + sin(a) * r * 0.75, r * 0.55]
				s += _f('<circle cx="%s" cy="%s" r="%.1f" fill="{accent}"/>' % [c[0], c[1], r * 0.45])
		"hearts":
			for c in big:
				s += _f('<path d="M0 3 C-5 -1 -3 -6 0 -3 C3 -6 5 -1 0 3 Z" transform="translate(%s %s) scale(%.2f)" fill="{accent}"/>' % [c[0], c[1], r / 3.0])
		"stars":
			for c in big:
				s += '<path d="M0 -5 l1.5 3.4 l3.6 0.3 l-2.8 2.4 l0.9 3.6 l-3.2 -2 l-3.2 2 l0.9 -3.6 l-2.8 -2.4 l3.6 -0.3 z" transform="translate(%s %s) scale(%.2f)" fill="#FFF3B0"/>' % [c[0], c[1], r / 4.0]
	return s


# The body of a top and of the shirt under overalls: shoulders, a little waist, a gently curved hem.
const TOP_BODY := "M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 Q107 58 104 78 Q103 90 106 98 Q106 106 98 105 Q65 109 32 105 Q24 106 24 98 Q27 90 26 78 Q23 58 22 32 Q22 22 30 18 Z"


func _top() -> String:
	var s := _f('<path d="%s" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % TOP_BODY)
	s += _sheen(TOP_BODY)
	s += _f('<path d="M24 34 Q24 24 32 20 Q28 50 30 102 H26 Z" fill="{cloth_shade}"/>')
	match look.pattern:
		"stripes":
			for y in [40, 58, 76]:
				s += _f('<rect x="24" y="%d" width="82" height="8" fill="{accent}" opacity="0.9"/>' % y)
		"heart":
			s += _f('<path d="M65 66 C50 54 54 40 65 48 C76 40 80 54 65 66 Z" fill="{accent}"/>')
			s += '<path d="M58 48 Q54 52 56 57" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.5"/>'
		"star":
			s += _f('<path d="M65 38 l5 11 l12 1 l-9 8 l3 12 l-11 -6 l-11 6 l3 -12 l-9 -8 l12 -1 z" fill="{accent}"/>')
		"zigzag":
			s += _f('<path d="M24 52 l10 -8 l10 8 l10 -8 l10 8 l10 -8 l10 8 l10 -8 l8 6" stroke="{accent}" stroke-width="5" fill="none" stroke-linejoin="round"/>')
		"bike":
			# A bicycle printed on the chest: two wheels, the frame, a saddle and handlebars.
			s += _f('<g transform="translate(65 60) scale(0.62) translate(-65 -60)" stroke="{accent}" stroke-width="3.6" fill="none" stroke-linecap="round" stroke-linejoin="round">'
				+ '<circle cx="48" cy="70" r="11"/><circle cx="82" cy="70" r="11"/>'
				+ '<path d="M48 70 L60 70 L76 52 L60 52 Z M60 70 L56 46 M76 52 L82 70 M52 46 H60 M76 52 L74 44 H81"/></g>')
		"birds":
			# Little birds riding skateboards, all over.
			for bird: Array in [[42, 40, "#E8812E"], [78, 36, "#3D8BD9"], [58, 62, "#C9453A"], [92, 62, "#E8812E"], [38, 76, "#3D8BD9"], [72, 86, "#7A5232"]]:
				s += '<g transform="translate(%d %d)"><ellipse cx="0" cy="-3" rx="6" ry="4.5" fill="%s"/><circle cx="5" cy="-7" r="3" fill="%s"/><path d="M8 -7 l3 1 l-3 1 z" fill="#E8B23A"/><path d="M-7 2 H7" stroke="#4A4048" stroke-width="1.8" stroke-linecap="round"/><circle cx="-4" cy="4" r="1.2" fill="#4A4048"/><circle cx="4" cy="4" r="1.2" fill="#4A4048"/></g>' % [bird[0], bird[1], bird[2], bird[2]]
		_:
			s += _pattern([[38, 44], [66, 54], [94, 44], [44, 78], [74, 86], [98, 74]], [[56, 34], [84, 68]])
	s += _top_folds()
	if look.outfit in ["sweater", "hoodie"]:
		# Knitted ribbing at the hem and a thick rolled neck; the rows of the knit show faintly.
		s += _f('<path d="M24 96 Q27 90 26 80 L104 80 Q103 90 106 96 Q106 106 98 105 Q65 109 32 105 Q24 106 24 98 Z" fill="{cloth_line}" opacity="0.38"/>')
		for x in range(30, 102, 5):
			s += _f('<path d="M%d 95 V106" stroke="{cloth_line}" stroke-width="1.4" opacity="0.5"/>' % x)
		s += _f('<path d="M26 94 Q65 100 104 94" stroke="{cloth_line}" stroke-width="1.6" fill="none" opacity="0.5"/>')
		s += _f('<path d="M42 13 Q65 31 88 13" stroke="{cloth_line}" stroke-width="7" fill="none" stroke-linecap="round"/>')
		s += _f('<path d="M44 13 Q65 29 86 13" stroke="{cloth}" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.75"/>')
		if look.outfit == "sweater" and look.pattern in ["none", "zigzag"]:
			for x in [48, 65, 82]:
				s += _f('<path d="M%d 36 q-4 5 0 10 t0 10 t0 10 t0 10" stroke="{cloth_line}" stroke-width="1.8" fill="none" opacity="0.28"/>' % x)
	else:
		# A T-shirt: a ribbed round collar, and the hem sewn up.
		s += _f('<path d="M44 13 Q65 29 86 13" stroke="{cloth_line}" stroke-width="5" fill="none" stroke-linecap="round"/>')
		s += _f('<path d="M46 14 Q65 27 84 14" stroke="{cloth}" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.6"/>')
		s += '<path d="M27 98 Q65 104 103 98" stroke="#FFFFFF" stroke-width="1.5" fill="none" stroke-dasharray="3 3" opacity="0.5"/>'
	if look.necklace != "":
		# A thin cord, and a stone hanging on it.
		s += '<path d="M48 17 Q58 30 65 34 Q72 30 82 17" stroke="#2F2A3A" stroke-width="1.6" fill="none"/>'
		s += '<path d="M65 33 L68 38 L65 46 L62 38 Z" fill="%s" stroke="#2F2A3A" stroke-width="1.2"/>' % look.necklace
	return s


# Salopette: the shirt (accent colour) under a bib with straps and buttons; the trousers are the legs.
func _overalls() -> String:
	var s := _f('<path d="%s" fill="{accent}" stroke="{accent_line}" stroke-width="2.5" stroke-linejoin="round"/>' % TOP_BODY)
	s += _sheen(TOP_BODY)
	s += _f('<path d="M48 14 Q65 26 82 14" stroke="{accent_line}" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
	s += _f('<path d="M38 42 H92 V70 Q104 72 106 80 V100 Q106 106 100 106 H30 Q24 106 24 100 V80 Q26 72 38 70 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M26 82 Q28 74 36 72 V104 H30 Q26 104 26 98 Z" fill="{cloth_shade}"/>')
	s += _f('<path d="M42 44 L32 16 M88 44 L98 16" stroke="{cloth}" stroke-width="9" stroke-linecap="round"/>')
	s += _f('<path d="M42 44 L32 16 M88 44 L98 16" stroke="{cloth_line}" stroke-width="2" stroke-dasharray="3 3" opacity="0.7"/>')
	s += _sheen("M38 42 H92 V70 Q104 72 106 80 V100 Q106 106 100 106 H30 Q24 106 24 100 V80 Q26 72 38 70 Z")
	for k in range(0, 8):
		s += _f('<path d="M%d 74 l-6 %d" stroke="{cloth_line}" stroke-width="1" opacity="0.18"/>' % [34 + k * 10, 28])
	s += _f('<rect x="50" y="48" width="30" height="20" rx="3" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2"/>')
	s += _f('<path d="M52 51 H78" stroke="{cloth_line}" stroke-width="1.2" stroke-dasharray="2.5 2.5" opacity="0.6"/>')
	s += _f('<path d="M26 80 Q32 90 30 102 M104 80 Q98 90 100 102" stroke="{cloth_line}" stroke-width="1.5" fill="none" stroke-dasharray="3 3" opacity="0.5"/>')
	s += '<circle cx="42" cy="47" r="4" fill="#F2B632" stroke="#A47A12" stroke-width="1.5"/><circle cx="88" cy="47" r="4" fill="#F2B632" stroke="#A47A12" stroke-width="1.5"/>'
	return s


# Coton ouaté: a hood bunched behind the neck, drawstrings and a kangaroo pocket, over a sweater-like top.
func _hoodie() -> String:
	var s := _f('<path d="M34 20 Q30 4 46 2 Q65 14 84 2 Q100 4 96 20 Q80 30 65 30 Q50 30 34 20 Z" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M58 22 L56 46 M72 22 L74 46" stroke="{accent_light}" stroke-width="2.5" stroke-linecap="round"/>')
	s += _f('<circle cx="56" cy="47" r="2.5" fill="{accent}"/><circle cx="74" cy="47" r="2.5" fill="{accent}"/>')
	s += _f('<path d="M34 100 Q38 86 44 74 H86 Q92 86 96 100 Q96 104 90 104 H40 Q34 104 34 100 Z" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M44 76 Q38 86 36 98 M86 76 Q92 86 94 98" stroke="{cloth_line}" stroke-width="1.4" fill="none" stroke-dasharray="3 2.5" opacity="0.6"/>')
	s += _f('<path d="M44 18 Q65 26 86 18 Q86 24 65 30 Q44 24 44 18 Z" fill="{cloth_line}" opacity="0.25"/>')
	return s


const COAT_BODY := "M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 L114 136 Q114 144 106 144 H24 Q16 144 16 136 L22 32 Q22 22 30 18 Z"


func _coat() -> String:
	var s := _f('<path d="%s" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % COAT_BODY)
	s += _sheen(COAT_BODY)
	s += _f('<path d="M24 34 Q24 24 32 20 Q26 80 22 142 H18 Z" fill="{cloth_shade}"/>')
	s += _f('<path d="M42 12 L58 40 L65 24 L72 40 L88 12" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M65 26 V142" stroke="{cloth_line}" stroke-width="2"/>')
	for y in [52, 76, 100]:
		s += _f('<circle cx="72" cy="%d" r="3.5" fill="{accent}" stroke="{cloth_line}" stroke-width="1.5"/>' % y)
	# Pockets with flaps and their stitching, a belt with its buckle, shoulder straps, a second row of buttons, the hem sewn.
	for x in [26.0, 82.0]:
		s += _f('<path d="M%s 96 H%s V108 Q%s 112 %s 112 H%s Q%s 112 %s 108 Z" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2" stroke-linejoin="round"/>' % [x, x + 22.0, x + 22.0, x + 18.0, x + 4.0, x, x])
		s += _f('<path d="M%s 98 H%s" stroke="{cloth_line}" stroke-width="1.2" stroke-dasharray="2.5 2.5" opacity="0.6"/>' % [x + 1.0, x + 21.0])
		s += _f('<circle cx="%s" cy="106" r="2.2" fill="{accent}" stroke="{cloth_line}" stroke-width="1"/>' % (x + 11.0))
	s += _f('<rect x="18" y="76" width="94" height="9" fill="{cloth_line}" opacity="0.38"/>')
	s += _f('<rect x="58" y="74" width="14" height="13" rx="2" fill="{accent}" stroke="{accent_line}" stroke-width="2"/><rect x="61" y="77" width="8" height="7" rx="1" fill="none" stroke="{accent_line}" stroke-width="1.4"/>')
	s += _f('<path d="M28 20 L44 16 M102 20 L86 16" stroke="{cloth_line}" stroke-width="5" stroke-linecap="round" opacity="0.55"/>')
	for y in [52, 66]:
		s += _f('<circle cx="58" cy="%d" r="3" fill="{accent}" stroke="{cloth_line}" stroke-width="1.3"/>' % y)
	s += _f('<path d="M20 138 Q65 144 111 138" stroke="{cloth_line}" stroke-width="1.5" fill="none" stroke-dasharray="3 3" opacity="0.5"/>')
	return s


# Under overalls the sleeves belong to the shirt, in the accent colour: run `build` with that palette and put the palette back.
func _sleeve_palette(build: Callable) -> String:
	var palette := p.duplicate()
	if look.outfit == "overalls":
		p.cloth = p.accent
		p.cloth_line = p.accent_line
	var s: String = build.call()
	p = palette
	return s


## Shoulder to elbow: the skin (with the round of the elbow at the bottom, no seam) and the sleeve, which for a long sleeve
## goes all the way down to a cloth elbow. Canvas 30 wide; the shoulder pivot is at (15, 8) and the elbow at (15, 8 + length).
func _upper_arm_svg(length: float) -> String:
	var ey := 8.0 + length
	var s := _f('<rect x="9" y="14" width="12" height="%s" rx="5" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % (length - 4.0))
	s += _f('<circle cx="15" cy="%s" r="6.5" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % ey)
	s += _f('<rect x="10.4" y="%s" width="9.2" height="13" fill="{skin}"/>' % (ey - 9.0))
	s += _sleeve_palette(func() -> String:
		var t := ""
		match look.sleeve:
			"puff":
				t += _f('<path d="M2 10 Q15 -3 28 10 Q30 24 24 30 H6 Q0 24 2 10 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
				if look.pattern == "dots":
					t += '<circle cx="18" cy="14" r="2.8" fill="#FFFFFF"/>'
				t += '<path d="M5 28 Q15 33 25 28" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round"/>'
			"short":
				t += _f('<path d="M3 8 Q15 -2 27 8 L26 36 Q15 40 4 36 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			"long":
				t += _f('<path d="M3 8 Q15 -2 27 8 L25 %s Q15 %s 5 %s Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % [ey, ey + 4.0, ey])
				t += _f('<circle cx="15" cy="%s" r="8.4" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5"/>' % ey)
				t += _f('<rect x="7" y="%s" width="16" height="12" fill="{cloth}"/>' % (ey - 11.0))
				t += _f('<path d="M8 %s q7 4 14 0 M10 %s q6 3 11 0" stroke="{cloth_line}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.45"/>' % [length * 0.4 + 8.0, length * 0.4 + 14.0])
		return t)
	return '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="%d" viewBox="0 0 30 %d">%s</svg>' % [ceili(ey + 12), ceili(ey + 12), s]


## Elbow to wrist: slimmer than the upper arm, a round cap at the elbow, and for a long sleeve the cloth down to a cuff, with the
## little creases of a bent elbow. Canvas 30 wide; the elbow pivot is at (15, 8); the wrist at (15, 8 + length).
func _forearm_svg(length: float) -> String:
	var wy := 8.0 + length
	var s := _f('<rect x="9.8" y="8" width="10.4" height="%s" rx="4.5" fill="{skin}" stroke="{skin_line}" stroke-width="2.2"/>' % (length + 3.0))
	s += _f('<circle cx="15" cy="8" r="5.8" fill="{skin}" stroke="{skin_line}" stroke-width="2.2"/>')
	s += _f('<rect x="11" y="3" width="8" height="12" fill="{skin}"/>')
	s += _f('<path d="M11 14 V%s" stroke="{skin_shade}" stroke-width="2" opacity="0.5"/>' % (wy - 4.0))
	s += _sleeve_palette(func() -> String:
		var t := ""
		if look.sleeve == "long":
			t += _f('<path d="M5.5 8 L7.6 %s L22.4 %s L24.5 8 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % [wy - 5.0, wy - 5.0])
			t += _f('<circle cx="15" cy="8" r="8.4" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5"/>')
			t += _f('<rect x="6.4" y="3" width="17.2" height="13" fill="{cloth}"/>')
			t += _f('<rect x="6.6" y="%s" width="16.8" height="8" rx="3" fill="{cloth_line}" opacity="0.55"/>' % (wy - 12.0))
			t += _f('<path d="M8.5 14 q6.5 4.5 13 0 M9.5 19.5 q5.5 3.5 11 0 M10.5 25 q4.5 3 9 0" stroke="{cloth_line}" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.4"/>')
		return t)
	return '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="%d" viewBox="0 0 30 %d">%s</svg>' % [ceili(wy + 10), ceili(wy + 10), s]


# One finger: two segments (`a1` then `a2` degrees, negative = curling forward) from its root at (x, y), width `w`.
func _finger(x: float, y: float, w: float, l1: float, l2: float, a1: float, a2: float) -> String:
	var rx := w / 2.0
	var s := '<g transform="translate(%s %s) rotate(%s)">' % [x, y, a1]
	s += _f('<rect x="%s" y="0" width="%s" height="%s" rx="%s" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/>' % [-rx, w, l1, rx])
	s += '<g transform="translate(0 %s) rotate(%s)">' % [l1 - 1.0, a2]
	s += _f('<rect x="%s" y="0" width="%s" height="%s" rx="%s" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/>' % [-rx * 0.96, w * 0.96, l2, rx * 0.96])
	s += _f('<ellipse cx="0" cy="%s" rx="%s" ry="1.6" fill="{skin_shade}" opacity="0.55"/>' % [l2 - 2.5, rx * 0.55])
	s += '</g></g>'
	return s


## A hand, wrist at the top centre, thumb on the +x (front) side: "relaxed" (fingers loosely curled, hanging), "open" (spread,
## for a wave or a stretch), "flat" (fingers together, stroking a cat or typing) or "grip" (a fist on a handle or a carton).
## Canvas 44 x 50 units (times `scale`); the wrist is at (22, 6).
func _hand_svg(mode: String, scale: float) -> String:
	var s := ""
	var palm_top := '<rect x="17" y="2" width="10" height="7" fill="{skin}"/>'
	match mode:
		"relaxed":
			# Pinky, ring, middle, index: each a little longer than the last and curled a little more.
			for f in [[16.8, 3.8, 7.5, 5.0, -2.0, -20.0], [20.8, 4.2, 9.5, 6.0, -4.0, -22.0], [24.8, 4.2, 10.0, 6.5, -6.0, -24.0], [28.6, 4.0, 9.0, 6.0, -9.0, -26.0]]:
				s += _finger(f[0], 14.0, f[1], f[2], f[3], f[4], f[5])
			s += _f('<rect x="14.2" y="4" width="15.6" height="16.5" rx="6.2" fill="{skin}" stroke="{skin_line}" stroke-width="1.7"/>')
			s += _f('<path d="M16 17.5 Q22 19.8 28.4 17.5" stroke="{skin_shade}" stroke-width="1.4" fill="none" opacity="0.6"/>')
			s += '<g transform="translate(29.2 8.5) rotate(-36)">'
			s += _f('<rect x="-2.7" y="0" width="5.4" height="8.2" rx="2.7" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/>')
			s += '<g transform="translate(0 7) rotate(-16)">'
			s += _f('<rect x="-2.5" y="-1" width="5" height="6.4" rx="2.5" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/></g></g>')
		"open":
			for f in [[16.8, 3.8, 15.0, 0.0, 14.0, 0.0], [20.8, 4.2, 18.0, 0.0, 6.0, 0.0], [24.8, 4.2, 19.0, 0.0, -3.0, 0.0], [28.6, 4.0, 17.0, 0.0, -12.0, 0.0]]:
				s += _finger(f[0], 14.0, f[1], f[2], 0.01, f[4], 0.0)
			s += _f('<rect x="14.2" y="4" width="15.6" height="16.5" rx="6.2" fill="{skin}" stroke="{skin_line}" stroke-width="1.7"/>')
			s += '<g transform="translate(29.4 9.5) rotate(-58)">'
			s += _f('<rect x="-2.8" y="0" width="5.6" height="13" rx="2.8" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/></g>')
		"flat":
			for f in [[17.3, 4.4, 13.0, 0.01, -1.0, 0.0], [21.3, 4.6, 16.0, 0.01, -2.0, 0.0], [25.3, 4.6, 17.0, 0.01, -3.0, 0.0], [29.0, 4.4, 15.5, 0.01, -4.0, 0.0]]:
				s += _finger(f[0], 14.0, f[1], f[2], f[3], f[4], 0.0)
			s += _f('<rect x="14.2" y="4" width="15.8" height="16.5" rx="6.2" fill="{skin}" stroke="{skin_line}" stroke-width="1.7"/>')
			s += '<g transform="translate(29.6 9) rotate(-14)">'
			s += _f('<rect x="-2.7" y="0" width="5.4" height="11" rx="2.7" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/></g>')
		_:
			# The fist: a block of palm, four curled fingers stacked on the front of it, the thumb folded over them.
			s += _f('<rect x="13.5" y="4" width="17" height="18" rx="7" fill="{skin}" stroke="{skin_line}" stroke-width="1.7"/>')
			for i in 4:
				var y := 8.5 + i * 4.3
				var len := 13.0 - absf(i - 1.5) * 1.0
				s += _f('<rect x="20" y="%s" width="%s" height="4.6" rx="2.3" fill="{skin}" stroke="{skin_line}" stroke-width="1.4"/>' % [y, len])
			s += _f('<path d="M20.5 8.2 H31 M20.5 12.5 H31.6 M20.5 16.8 H31.4" stroke="{skin_shade}" stroke-width="1" opacity="0.55"/>')
			s += '<g transform="translate(26 6.5) rotate(-72)">'
			s += _f('<rect x="-2.7" y="-1" width="5.4" height="10" rx="2.7" fill="{skin}" stroke="{skin_line}" stroke-width="1.5"/></g>')
	s += _f(palm_top)
	var w := ceili(44.0 * scale)
	var h := ceili(50.0 * scale)
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 44 50">%s</svg>' % [w, h, s]


## Light across a leg: lit on the left, shaded on the right ("lg").
const LEG_DEFS := ('<defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.24"/>'
	+ '<stop offset="0.4" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.2"/></linearGradient></defs>')


func _leg_body(length: float) -> String:
	var off := length - 110.0
	var s := LEG_DEFS
	match look.legwear:
		"socks":
			s += _f('<rect x="11" y="0" width="18" height="%s" rx="7" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % (length - 18.0))
			s += '<rect x="11" y="0" width="18" height="%s" rx="7" fill="url(#lg)"/>' % (length - 18.0)
			s += _f('<rect x="9" y="%s" width="22" height="18" rx="4" fill="{leg}" stroke="{leg_line}" stroke-width="2"/>' % (length - 34.0))
			s += '<rect x="9" y="%s" width="22" height="18" rx="4" fill="url(#lg)"/>' % (length - 34.0)
			# The ribbed cuff of the sock: a darker band with its ribs and a stripe.
			s += _f('<rect x="9" y="%s" width="22" height="6" rx="3" fill="{leg_line}" opacity="0.4"/>' % (length - 34.0))
			for x in range(12, 30, 3):
				s += _f('<path d="M%d %s v5" stroke="{leg_line}" stroke-width="1" opacity="0.45"/>' % [x, length - 33.0])
			s += _f('<rect x="9.5" y="%s" width="21" height="2.4" fill="{accent}" opacity="0.8"/>' % (length - 25.0))
		"tights":
			s += _f('<rect x="11" y="0" width="18" height="%s" rx="7" fill="{leg}" stroke="{leg_line}" stroke-width="2.5"/>' % (length - 18.0))
			s += '<rect x="11" y="0" width="18" height="%s" rx="7" fill="url(#lg)"/>' % (length - 18.0)
			# The sheen of knitted tights: two faint stripes of light down the leg.
			s += '<path d="M15 14 V%s M18.5 14 V%s" stroke="#FFFFFF" stroke-width="1.5" opacity="0.14" stroke-linecap="round"/>' % [length - 30.0, length - 36.0]
		_:
			s += _f('<rect x="8" y="0" width="24" height="%s" rx="4" fill="{leg}" stroke="{leg_line}" stroke-width="2.5"/>' % (length - 14.0))
			s += '<rect x="8" y="0" width="24" height="%s" rx="4" fill="url(#lg)"/>' % (length - 14.0)
			# Trousers: a turned-up cuff with its stitching, and the outer seam.
			s += _f('<rect x="8" y="%s" width="24" height="6" fill="{leg_line}" opacity="0.5"/>' % (length - 20.0))
			s += '<path d="M9 %s H31" stroke="#FFFFFF" stroke-width="1.2" stroke-dasharray="3 2.5" opacity="0.4"/>' % (length - 17.0)
			s += _f('<path d="M29 6 V%s" stroke="{leg_line}" stroke-width="1.2" stroke-dasharray="3 3" opacity="0.5"/>' % (length - 22.0))
	s += '<g transform="translate(0 %s)">' % off
	match look.shoes:
		"mary_jane":
			s += _f('<path d="M4 108 Q2 90 18 88 H30 Q48 90 48 104 Q49 110 44 110 H6 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<path d="M16 91 Q26 96 34 91" stroke="{shoe_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
			s += _f('<ellipse cx="38" cy="98" rx="5" ry="3" fill="{shoe_light}"/>')
			# The buckled strap across the foot and the shine on the toe.
			s += _f('<path d="M22 90 Q24 100 22 106" stroke="{shoe_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
			s += '<rect x="19.5" y="96" width="5.5" height="5" rx="1" fill="#F2C94C" stroke="#A47A12" stroke-width="1"/>'
		"sneaker":
			s += _f('<path d="M4 108 Q2 88 18 86 H30 Q48 90 48 104 Q49 110 44 110 H6 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += '<path d="M36 92 Q48 94 48 106 L36 106 Z" fill="#FFFFFF" opacity="0.85"/>'
			# Laces across the tongue with their eyelets, and a heel tab.
			s += '<path d="M17 91 L29 88.5 M17 96 L31 93 M18 101 L33 98" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round"/>'
			s += _f('<path d="M8 96 Q6 100 8 104" stroke="{shoe_line}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
			s += '<path d="M13 88 Q14 94 14 100" stroke="#FFFFFF" stroke-width="1.6" fill="none" opacity="0.45" stroke-linecap="round"/>'
		"boot":
			s += _f('<path d="M8 70 H32 V96 Q48 94 48 106 Q49 110 44 110 H6 Q4 100 8 92 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<rect x="7" y="68" width="26" height="8" rx="3" fill="{shoe_line}"/>')
			# Laces up the front, a stitched toe and a lighter sheen down the shaft.
			s += '<path d="M24 80 L31 82 M24 86 L31 88 M24 92 L32 94" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" opacity="0.7"/>'
			s += '<path d="M12 80 V94" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.18"/>'
			s += _f('<path d="M34 98 Q44 98 47 105" stroke="{shoe_line}" stroke-width="1.4" fill="none" stroke-dasharray="2.5 2" opacity="0.7"/>')
		"rain_boot":
			s += _f('<path d="M7 70 H33 V94 Q48 94 48 106 Q49 110 44 110 H6 Q4 100 7 90 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<rect x="5" y="66" width="30" height="8" rx="4" fill="{shoe_line}"/>')
			s += '<path d="M13 78 V90" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.5"/>'
			s += '<path d="M40 100 Q44 102 45 106" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.5"/>'
			s += _f('<circle cx="40" cy="101" r="3" fill="{shoe_light}"/>')
	s += _f('<rect x="3" y="106" width="46" height="9" rx="4.5" fill="{sole}" stroke="{sock_line}" stroke-width="1.5"/>')
	# The tread on the sole.
	for x in range(10, 46, 6):
		s += '<path d="M%d 111 v3" stroke="#A39B8B" stroke-width="1.2" opacity="0.6"/>' % x
	s += "</g>"
	return s


## The leg in two pieces joined at the knee (`rig.knee_y`, half way down): the thigh (hip pivot at (20, 6)) and the shin with its shoe
## (pivot at the knee, `SHIN_PAD` below the top of its picture). The shin carries a round cap with the knee's crease so the bend stays
## clean. Both are cut from the same drawing (`_leg_body`).
func _thigh_svg(length: float) -> String:
	var knee := roundf(length * 0.5)
	var h := ceili(knee + 2.0)
	var s := '<defs><clipPath id="th"><rect x="0" y="0" width="52" height="%s"/></clipPath></defs><g clip-path="url(#th)">%s</g>' % [knee + 1.0, _leg_body(length)]
	return '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="%d" viewBox="0 0 52 %d">%s</svg>' % [h, h, s]


func _shin_svg(length: float) -> String:
	var knee := roundf(length * 0.5)
	var total := ceili(length + 10.0 - knee + SHIN_PAD)
	var r := 9.0
	var fill := "{leg}"
	var line := "{leg_line}"
	match look.legwear:
		"socks":
			fill = "{skin}"
			line = "{skin_line}"
		"tights":
			pass
		_:
			r = 12.0
	var s := '<defs><clipPath id="sh"><rect x="0" y="%s" width="52" height="%s"/></clipPath></defs>' % [knee, length + 12.0 - knee]
	s += '<g transform="translate(0 %s)"><g clip-path="url(#sh)">%s</g>' % [SHIN_PAD - knee, _leg_body(length)]
	s += _f('<circle cx="20" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="2.5"/>' % [knee, r, fill, line])
	s += _f('<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [20.0 - r + 1.5, knee - r - 1.0, 2.0 * r - 3.0, 2.0 * r + 2.4, fill])
	if look.legwear == "socks":
		s += '<ellipse cx="23" cy="%s" rx="3.4" ry="4.4" fill="#FFFFFF" opacity="0.2"/>' % (knee + 1.0)
	else:
		s += _f('<path d="M%s %s q%s 4.5 %s 0 M%s %s q%s 3 %s 0" stroke="%s" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.5"/>' % [
			20.0 - r * 0.6, knee + 3.0, r * 0.6, r * 1.2, 20.0 - r * 0.45, knee + 9.0, r * 0.45, r * 0.9, line])
	s += '</g>'
	return '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="%d" viewBox="0 0 52 %d">%s</svg>' % [total, total, s]


func _backpack_svg() -> String:
	var s := _f('<rect x="6" y="8" width="50" height="84" rx="14" fill="{pack}" stroke="{pack_line}" stroke-width="3"/>')
	s += _f('<path d="M8 30 Q31 18 54 30 V40 H8 Z" fill="{pack_line}" opacity="0.45"/>')
	s += _f('<rect x="14" y="56" width="34" height="26" rx="7" fill="{pack}" stroke="{pack_line}" stroke-width="2.5"/>')
	s += '<circle cx="31" cy="62" r="3" fill="#FFD23F"/>'
	return '<svg xmlns="http://www.w3.org/2000/svg" width="62" height="96" viewBox="0 0 62 96">%s</svg>' % s
