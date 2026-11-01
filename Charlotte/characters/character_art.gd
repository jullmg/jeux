class_name CharacterArt
extends RefCounted
## Builds a character's SVG body parts from a CharacterLook and rasterizes them at runtime.

const HEAD_CANVAS := Vector2(240, 380)
const HEAD_PIVOT := Vector2(118, 296)
const RIGS := {
	"child": {"leg": 110.0, "torso": 90.0, "arm": 76.0, "head": 1.0, "sx": 1.0},
	"teen": {"leg": 162.0, "torso": 120.0, "arm": 100.0, "head": 0.84, "sx": 1.05},
	"adult": {"leg": 210.0, "torso": 154.0, "arm": 128.0, "head": 0.72, "sx": 1.14},
	"senior": {"leg": 196.0, "torso": 148.0, "arm": 124.0, "head": 0.74, "sx": 1.14},
}

var look: CharacterLook
var p := {}


static func build(character_look: CharacterLook) -> Dictionary:
	var art := CharacterArt.new()
	art.look = character_look
	art.p = art._palette()
	return art._build()


func _build() -> Dictionary:
	var r: Dictionary = RIGS[look.age]
	var leg: float = r.leg
	var arm: float = r.arm
	var torso_h: float = r.torso
	var sx: float = r.sx * look.build
	var sy: float = torso_h / 90.0
	var torso_top := -(leg + torso_h)
	var rig := {
		"leg_len": leg, "arm_len": arm, "sx": sx, "head_scale": r.head,
		"torso_top": torso_top, "neck_y": torso_top + 8.0 * sy, "shoulder_y": torso_top + 18.0 * sy,
		"arm_x": 36.0 * sx, "leg_x": 8.0 * sx, "torso_pivot": Vector2(65.0 * sx, 0.0),
		"head_pivot": HEAD_PIVOT, "leg_pivot": Vector2(20, 6), "arm_pivot": Vector2(15, 8),
		"pack_pivot": Vector2(54, 10), "lean": deg_to_rad(5.0) if look.age == "senior" else 0.0,
	}
	var tex := {
		"head": _tex(_head_svg(false)),
		"lids": _tex(_head_svg(true)),
		"hair_back": _tex(_head_frame(_hair_back())),
		"hair_front": _tex(_head_frame(_hair_front() + _hat())),
		"torso": _tex(_torso_svg(sx, sy)),
		"arm": _tex(_arm_svg(arm)),
		"leg": _tex(_leg_svg(leg)),
	}
	if look.backpack != "":
		tex.backpack = _tex(_backpack_svg())
	return {"rig": rig, "tex": tex}


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
	if lids_only:
		for e in [[94.0, 130.0, 20.0, 24.0, "M76 132 Q94 144 112 132"], [149.0, 130.0, 17.0, 23.0, "M134 132 Q150 143 165 132"]]:
			s += _eye_wrap(e[0], e[1], _f('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="{skin}"/>' % [e[0], e[1], e[2], e[3]])
				+ _f('<path d="%s" stroke="{lash}" stroke-width="3.5" fill="none" stroke-linecap="round"/>' % e[4]))
		return _head_frame(s)
	s += _f('<ellipse cx="44" cy="132" rx="10" ry="14" fill="{skin_shade}" stroke="{skin_line}" stroke-width="3"/>')
	s += _f('<path d="M36 120 C36 76 70 58 110 58 C152 58 186 78 186 122 C186 168 156 202 112 202 C68 202 36 166 36 120 Z" fill="{skin}" stroke="{skin_line}" stroke-width="3"/>')
	s += _f('<ellipse cx="76" cy="160" rx="14" ry="9" fill="{blush}" opacity="0.6"/>')
	s += _f('<ellipse cx="164" cy="158" rx="11" ry="8" fill="{blush}" opacity="0.6"/>')
	if look.freckles:
		for f in [[70, 150], [78, 146], [84, 152], [158, 148], [166, 152], [162, 144]]:
			s += _f('<circle cx="%s" cy="%s" r="1.8" fill="{skin_line}" opacity="0.7"/>' % f)
	var lash1 := '<path d="M77 117 L72 109" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/><path d="M82 112 L79 104" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/>'
	var lash2 := '<path d="M164 117 L169 109" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/><path d="M159 112 L162 104" stroke="{lash}" stroke-width="2.5" stroke-linecap="round"/>'
	s += _eye_wrap(94, 130, _f('<ellipse cx="94" cy="130" rx="18" ry="22" fill="#FFFFFF"/>'
		+ '<circle cx="97" cy="133" r="15" fill="{iris}"/><circle cx="97" cy="136" r="10" fill="{iris_dark}"/>'
		+ '<circle cx="97" cy="135" r="6.5" fill="{pupil}"/><circle cx="103" cy="126" r="5.5" fill="#FFFFFF"/>'
		+ '<circle cx="91" cy="141" r="2.5" fill="#FFFFFF"/>'
		+ '<path d="M76 120 Q93 103 112 118" stroke="{lash}" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
		+ (lash1 if look.lashes else "")))
	s += _eye_wrap(149, 130, _f('<ellipse cx="149" cy="130" rx="15" ry="21" fill="#FFFFFF"/>'
		+ '<circle cx="152" cy="133" r="13" fill="{iris}"/><circle cx="152" cy="136" r="8.5" fill="{iris_dark}"/>'
		+ '<circle cx="152" cy="135" r="5.5" fill="{pupil}"/><circle cx="157" cy="126" r="4.8" fill="#FFFFFF"/>'
		+ '<circle cx="147" cy="141" r="2.2" fill="#FFFFFF"/>'
		+ '<path d="M134 118 Q150 103 165 120" stroke="{lash}" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
		+ (lash2 if look.lashes else "")))
	var brow_w := "4.5" if look.age in ["adult", "senior"] and not look.lashes else "3.5"
	s += _f('<path d="M80 94 Q93 86 106 91" stroke="{brow}" stroke-width="%s" fill="none" stroke-linecap="round"/>' % brow_w)
	s += _f('<path d="M138 91 Q150 86 162 94" stroke="{brow}" stroke-width="%s" fill="none" stroke-linecap="round"/>' % brow_w)
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
	if look.mouth == "open_smile":
		s += _f('<path d="M110 166 Q123 180 136 166 Z" fill="{mouth}" stroke="{mouth_line}" stroke-width="2" stroke-linejoin="round"/>')
		s += _f('<path d="M116 172 Q123 178 130 172 Q123 170 116 172 Z" fill="{tongue}"/>')
	else:
		s += _f('<path d="M110 167 Q123 177 136 167" stroke="{mouth_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
	if look.facial_hair in ["beard", "mustache"]:
		s += _f('<path d="M104 161 Q114 152 123 158 Q132 152 142 161 Q132 166 123 162 Q114 166 104 161 Z" fill="{hair}" stroke="{hair_line}" stroke-width="2"/>')
	if look.glasses != "":
		s += _f('<g fill="#FFFFFF" fill-opacity="0.15" stroke="{glasses}" stroke-width="3.5"><circle cx="94" cy="130" r="25"/><circle cx="150" cy="130" r="23"/></g>')
		s += _f('<path d="M119 127 Q123 122 127 127 M69 126 L48 122" stroke="{glasses}" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
	return _head_frame(s)


# --- Hair & hats ----------------------------------------------------------

const _CHARLOTTE_FRONT := 'M34 120 C28 60 70 24 112 24 C160 24 196 56 192 112 C184 92 170 80 150 74 C140 82 118 88 96 86 C88 78 82 74 76 72 C66 90 60 104 58 124 C54 140 52 160 56 178 C40 166 34 140 34 120 Z'
const _SWEPT_FRONT := 'M38 118 C30 62 70 28 112 28 C158 28 192 58 190 104 C176 84 150 70 120 68 C96 66 70 76 56 96 C50 104 46 112 44 124 Z'
const _CAP_BACK := 'M36 126 C28 68 70 30 112 30 C160 30 196 66 190 126 C172 146 56 146 36 126 Z'


func _hair_shape(d: String, width := 3.0) -> String:
	return _f('<path d="%s" fill="{hair}" stroke="{hair_line}" stroke-width="%s" stroke-linejoin="round"/>' % [d, width])


func _hair_back() -> String:
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
				s += _f('<circle cx="%.1f" cy="%.1f" r="30" fill="{hair}" stroke="{hair_line}" stroke-width="3"/>' % [c.x, c.y])
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
			return s + _f('<circle cx="112" cy="8" r="17" fill="{hat_light}" stroke="{hat_line}" stroke-width="2.5"/>')
		"cap":
			return _f('<path d="M36 94 C34 44 72 22 112 22 C152 22 188 44 188 94 Z" fill="{hat}" stroke="{hat_line}" stroke-width="3"/>'
				+ '<path d="M150 84 Q200 80 228 96 Q196 102 150 96 Z" fill="{hat_line}" stroke="{hat_line}" stroke-width="2"/>'
				+ '<circle cx="112" cy="24" r="6" fill="{hat_line}"/>')
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
	var s := _f('<rect x="57" y="0" width="16" height="20" fill="{neck}"/>')
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
		s += _f('<path d="M40 64 L54 66 M41 72 V80 M46 72 V81 M51 72 V80" stroke="{scarf_line}" stroke-width="2"/>')
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><g transform="scale(%s %s)">%s</g></svg>' % [
		ceili(w), ceili(h), ceili(w), ceili(h), sx, sy, s]


func _dress() -> String:
	var s := _f('<path d="M26 62 H104 Q118 100 128 140 Q120 148 108 142 Q98 150 86 143 Q76 150 65 143 Q54 150 44 143 Q32 150 22 142 Q10 148 2 140 Q12 100 26 62 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M26 66 Q14 100 4 138 Q10 144 18 141 Q24 100 34 66 Z" fill="{cloth_shade}"/>')
	s += _f('<g stroke="{cloth_fold}" stroke-width="2.5" fill="none" stroke-linecap="round"><path d="M50 72 Q46 106 40 138"/><path d="M80 72 Q84 106 90 138"/></g>')
	s += _pattern([[36, 96], [62, 88], [94, 96], [50, 122], [78, 116], [106, 126], [22, 128]], [[70, 132], [96, 110], [40, 110]])
	if look.pattern == "stripes":
		s += '<clipPath id="skirt"><path d="M26 62 H104 Q118 100 128 140 L2 140 Q12 100 26 62 Z"/></clipPath><g clip-path="url(#skirt)">'
		for y in [80, 100, 120]:
			s += _f('<rect x="0" y="%d" width="130" height="9" fill="{accent}" opacity="0.9"/>' % y)
		s += '</g>'
	s += _f('<path d="M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 L104 64 H26 L22 32 Q22 22 30 18 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M24 34 Q24 24 32 20 Q28 40 30 62 H26 Z" fill="{cloth_shade}"/>')
	s += _pattern([[80, 40], [48, 46]], [], 3.5)
	s += '<path d="M42 13 Q46 30 65 25 Q84 30 88 13 Q65 23 42 13 Z" fill="#FFFFFF" stroke="#CFC8BA" stroke-width="1.5" stroke-linejoin="round"/>'
	s += _f('<rect x="24" y="58" width="82" height="10" rx="3" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
	s += _f('<path d="M38 63 L24 54 Q20 63 24 72 Z" fill="{accent_light}" stroke="{accent_line}" stroke-width="2" stroke-linejoin="round"/>')
	s += _f('<path d="M38 63 L52 54 Q56 63 52 72 Z" fill="{accent_light}" stroke="{accent_line}" stroke-width="2" stroke-linejoin="round"/>')
	s += _f('<circle cx="38" cy="63" r="5" fill="{accent}" stroke="{accent_line}" stroke-width="2"/>')
	return s


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


func _top() -> String:
	var body := "M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 L106 98 Q106 104 100 104 H30 Q24 104 24 98 L22 32 Q22 22 30 18 Z"
	var s := _f('<path d="%s" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % body)
	s += _f('<path d="M24 34 Q24 24 32 20 Q28 50 30 102 H26 Z" fill="{cloth_shade}"/>')
	match look.pattern:
		"stripes":
			for y in [40, 58, 76]:
				s += _f('<rect x="24" y="%d" width="82" height="8" fill="{accent}" opacity="0.9"/>' % y)
		"heart":
			s += _f('<path d="M65 66 C50 54 54 40 65 48 C76 40 80 54 65 66 Z" fill="{accent}"/>')
		"star":
			s += _f('<path d="M65 38 l5 11 l12 1 l-9 8 l3 12 l-11 -6 l-11 6 l3 -12 l-9 -8 l12 -1 z" fill="{accent}"/>')
		"zigzag":
			s += _f('<path d="M24 52 l10 -8 l10 8 l10 -8 l10 8 l10 -8 l10 8 l10 -8 l8 6" stroke="{accent}" stroke-width="5" fill="none" stroke-linejoin="round"/>')
		"bike":
			# A bicycle printed on the chest: two wheels, the frame, a saddle and handlebars.
			s += _f('<g stroke="{accent}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round">'
				+ '<circle cx="48" cy="70" r="11"/><circle cx="82" cy="70" r="11"/>'
				+ '<path d="M48 70 L60 70 L76 52 L60 52 Z M60 70 L56 46 M76 52 L82 70 M52 46 H60 M76 52 L74 44 H81"/></g>')
		_:
			s += _pattern([[38, 44], [66, 54], [94, 44], [44, 78], [74, 86], [98, 74]], [[56, 34], [84, 68]])
	if look.outfit in ["sweater", "hoodie"]:
		s += _f('<rect x="24" y="94" width="82" height="10" rx="3" fill="{cloth_line}" opacity="0.5"/>')
		s += _f('<path d="M44 14 Q65 28 86 14" stroke="{cloth_line}" stroke-width="5" fill="none" stroke-linecap="round"/>')
	else:
		s += _f('<path d="M48 14 Q65 26 82 14" stroke="{cloth_line}" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
	return s


# Salopette: the shirt (accent colour) under a bib with straps and buttons; the trousers are the legs.
func _overalls() -> String:
	var body := "M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 L106 98 Q106 104 100 104 H30 Q24 104 24 98 L22 32 Q22 22 30 18 Z"
	var s := _f('<path d="%s" fill="{accent}" stroke="{accent_line}" stroke-width="2.5" stroke-linejoin="round"/>' % body)
	s += _f('<path d="M48 14 Q65 26 82 14" stroke="{accent_line}" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
	s += _f('<path d="M38 42 H92 V70 Q104 72 106 80 V100 Q106 106 100 106 H30 Q24 106 24 100 V80 Q26 72 38 70 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M26 82 Q28 74 36 72 V104 H30 Q26 104 26 98 Z" fill="{cloth_shade}"/>')
	s += _f('<path d="M42 44 L32 16 M88 44 L98 16" stroke="{cloth}" stroke-width="9" stroke-linecap="round"/>')
	s += _f('<path d="M42 44 L32 16 M88 44 L98 16" stroke="{cloth_line}" stroke-width="2" stroke-dasharray="3 3" opacity="0.7"/>')
	s += _f('<rect x="52" y="50" width="26" height="16" rx="3" fill="none" stroke="{cloth_line}" stroke-width="2"/>')
	s += '<circle cx="42" cy="47" r="4" fill="#F2B632" stroke="#A47A12" stroke-width="1.5"/><circle cx="88" cy="47" r="4" fill="#F2B632" stroke="#A47A12" stroke-width="1.5"/>'
	return s


# Coton ouaté: a hood bunched behind the neck, drawstrings and a kangaroo pocket, over a sweater-like top.
func _hoodie() -> String:
	var s := _f('<path d="M34 20 Q30 4 46 2 Q65 14 84 2 Q100 4 96 20 Q80 30 65 30 Q50 30 34 20 Z" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M58 22 L56 46 M72 22 L74 46" stroke="{accent_light}" stroke-width="2.5" stroke-linecap="round"/>')
	s += _f('<circle cx="56" cy="47" r="2.5" fill="{accent}"/><circle cx="74" cy="47" r="2.5" fill="{accent}"/>')
	s += _f('<path d="M40 96 L46 72 H84 L90 96" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	return s


func _coat() -> String:
	var s := _f('<path d="M42 12 Q65 22 88 12 L100 18 Q108 22 108 32 L114 136 Q114 144 106 144 H24 Q16 144 16 136 L22 32 Q22 22 30 18 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M24 34 Q24 24 32 20 Q26 80 22 142 H18 Z" fill="{cloth_shade}"/>')
	s += _f('<path d="M42 12 L58 40 L65 24 L72 40 L88 12" fill="{cloth_shade}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
	s += _f('<path d="M65 26 V142" stroke="{cloth_line}" stroke-width="2"/>')
	for y in [52, 76, 100]:
		s += _f('<circle cx="72" cy="%d" r="3.5" fill="{accent}" stroke="{cloth_line}" stroke-width="1.5"/>' % y)
	s += _f('<path d="M28 96 H48 M84 96 H104" stroke="{cloth_line}" stroke-width="3" stroke-linecap="round"/>')
	s += _f('<rect x="20" y="78" width="90" height="8" fill="{cloth_line}" opacity="0.35"/>')
	return s


func _arm_svg(length: float) -> String:
	var hy := 8.0 + length
	var s := _f('<rect x="9" y="20" width="12" height="%s" rx="5" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % (length - 16.0))
	s += _f('<circle cx="15" cy="%s" r="10" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % hy)
	# Under overalls the sleeves belong to the shirt, in the accent colour.
	var palette := p.duplicate()
	if look.outfit == "overalls":
		p.cloth = p.accent
		p.cloth_line = p.accent_line
	match look.sleeve:
		"puff":
			s += _f('<path d="M2 10 Q15 -3 28 10 Q30 24 24 30 H6 Q0 24 2 10 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			if look.pattern == "dots":
				s += '<circle cx="18" cy="14" r="2.8" fill="#FFFFFF"/>'
			s += '<path d="M5 28 Q15 33 25 28" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round"/>'
		"short":
			s += _f('<path d="M3 8 Q15 -2 27 8 L26 36 Q15 40 4 36 Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>')
		"long":
			s += _f('<path d="M3 8 Q15 -2 27 8 L25 %s Q15 %s 5 %s Z" fill="{cloth}" stroke="{cloth_line}" stroke-width="2.5" stroke-linejoin="round"/>' % [hy - 9, hy - 5, hy - 9])
			s += _f('<rect x="5" y="%s" width="20" height="7" rx="2" fill="{cloth_line}" opacity="0.6"/>' % (hy - 17))
	p = palette
	return '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="%d" viewBox="0 0 30 %d">%s</svg>' % [ceili(hy + 12), ceili(hy + 12), s]


func _leg_svg(length: float) -> String:
	var off := length - 110.0
	var s := ""
	match look.legwear:
		"socks":
			s += _f('<rect x="11" y="0" width="18" height="%s" rx="7" fill="{skin}" stroke="{skin_line}" stroke-width="2.5"/>' % (length - 18.0))
			s += _f('<rect x="9" y="%s" width="22" height="18" rx="4" fill="{leg}" stroke="{leg_line}" stroke-width="2"/>' % (length - 34.0))
		"tights":
			s += _f('<rect x="11" y="0" width="18" height="%s" rx="7" fill="{leg}" stroke="{leg_line}" stroke-width="2.5"/>' % (length - 18.0))
		_:
			s += _f('<rect x="8" y="0" width="24" height="%s" rx="4" fill="{leg}" stroke="{leg_line}" stroke-width="2.5"/>' % (length - 14.0))
			s += _f('<rect x="8" y="%s" width="24" height="6" fill="{leg_line}" opacity="0.5"/>' % (length - 20.0))
	s += '<g transform="translate(0 %s)">' % off
	match look.shoes:
		"mary_jane":
			s += _f('<path d="M4 108 Q2 90 18 88 H30 Q48 90 48 104 Q49 110 44 110 H6 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<path d="M16 91 Q26 96 34 91" stroke="{shoe_line}" stroke-width="3" fill="none" stroke-linecap="round"/>')
			s += _f('<ellipse cx="38" cy="98" rx="5" ry="3" fill="{shoe_light}"/>')
		"sneaker":
			s += _f('<path d="M4 108 Q2 88 18 86 H30 Q48 90 48 104 Q49 110 44 110 H6 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += '<path d="M36 92 Q48 94 48 106 L36 106 Z" fill="#FFFFFF" opacity="0.85"/>'
			s += '<path d="M18 92 L28 90 M18 98 L30 96" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>'
		"boot":
			s += _f('<path d="M8 66 H32 V96 Q48 94 48 106 Q49 110 44 110 H6 Q4 100 8 92 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<rect x="7" y="64" width="26" height="8" rx="3" fill="{shoe_line}"/>')
		"rain_boot":
			s += _f('<path d="M7 50 H33 V94 Q48 94 48 106 Q49 110 44 110 H6 Q4 100 7 90 Z" fill="{shoe}" stroke="{shoe_line}" stroke-width="2.5" stroke-linejoin="round"/>')
			s += _f('<rect x="5" y="46" width="30" height="9" rx="4" fill="{shoe_line}"/>')
			s += '<path d="M13 58 V88" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.5"/>'
			s += _f('<circle cx="40" cy="101" r="3" fill="{shoe_light}"/>')
	s += _f('<rect x="3" y="106" width="46" height="9" rx="4.5" fill="{sole}" stroke="{sock_line}" stroke-width="1.5"/>')
	s += "</g>"
	return '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="%d" viewBox="0 0 52 %d">%s</svg>' % [ceili(length + 10.0), ceili(length + 10.0), s]


func _backpack_svg() -> String:
	var s := _f('<rect x="6" y="8" width="50" height="84" rx="14" fill="{pack}" stroke="{pack_line}" stroke-width="3"/>')
	s += _f('<path d="M8 30 Q31 18 54 30 V40 H8 Z" fill="{pack_line}" opacity="0.45"/>')
	s += _f('<rect x="14" y="56" width="34" height="26" rx="7" fill="{pack}" stroke="{pack_line}" stroke-width="2.5"/>')
	s += '<circle cx="31" cy="62" r="3" fill="#FFD23F"/>'
	return '<svg xmlns="http://www.w3.org/2000/svg" width="62" height="96" viewBox="0 0 62 96">%s</svg>' % s
