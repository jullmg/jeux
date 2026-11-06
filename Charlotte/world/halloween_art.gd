class_name HalloweenArt
extends RefCounted
## What the neighbours put out for Halloween night, drawn as SVG like the rest of the street. `StreetScene._build_halloween`
## hangs two or three of these on every house that gives candy (`PIECES`, its own RNG), and the dark ones get nothing.
##
## A NEW decoration = one function here and its name in `PIECES` (with the canvas size and where it sits: "step" on the
## stairs, "wall" on the facade, "rail" along the balcony, "yard" on the ground behind the fence).

## Each piece: its canvas, where it belongs, and how big it is drawn on the street.
const PIECES := {
	"jack": {"size": Vector2(90, 80), "where": "step", "scale": 0.62, "glow": Vector2(45, 40)},
	"jack_pair": {"size": Vector2(150, 84), "where": "step", "scale": 0.6, "glow": Vector2(75, 44)},
	"ghost": {"size": Vector2(110, 150), "where": "hang", "scale": 0.6},
	"web": {"size": Vector2(140, 140), "where": "corner", "scale": 0.7},
	"skeleton": {"size": Vector2(90, 190), "where": "step", "scale": 0.58},
	"grave": {"size": Vector2(110, 110), "where": "yard", "scale": 0.6},
	"cat": {"size": Vector2(100, 80), "where": "step", "scale": 0.55},
	"spider": {"size": Vector2(120, 110), "where": "wall", "scale": 0.6},
	"broom": {"size": Vector2(70, 160), "where": "step", "scale": 0.6},
	"candles": {"size": Vector2(90, 70), "where": "step", "scale": 0.55, "glow": Vector2(45, 36)},
	"bowl": {"size": Vector2(100, 70), "where": "step", "scale": 0.55},
	"scarecrow": {"size": Vector2(120, 200), "where": "yard", "scale": 0.62},
	"garland": {"size": Vector2(280, 70), "where": "rail", "scale": 0.7},
	"bats": {"size": Vector2(180, 110), "where": "wall", "scale": 0.7},
}

## The pieces a house may be given, and how likely each is.
const CHOICES := ["jack", "jack_pair", "ghost", "web", "skeleton", "grave", "cat", "spider", "broom", "candles",
	"bowl", "scarecrow", "garland", "bats", "jack", "ghost", "web", "jack_pair", "garland", "candles"]

const ORANGE := "#E8812E"
const DEEP := "#C25A14"
const PURPLE := "#7E57C2"
const BONE := "#EFEADA"
const NIGHT := "#2B2430"


static func texture(kind: String) -> ImageTexture:
	var size: Vector2 = PIECES[kind].size
	return PropArt.tex(PropArt._svg(size.x, size.y, _body(kind)))


static func _body(kind: String) -> String:
	match kind:
		"jack":
			return _jack(45, 46, 1.0)
		"jack_pair":
			return _jack(42, 48, 0.95) + _jack(106, 52, 0.72)
		"ghost":
			# A sheet ghost hung by a thread: a wavy hem, two dark eyes, a little mouth.
			var s := '<path d="M55 4 V22" stroke="#9A968E" stroke-width="2"/>'
			s += '<path d="M20 86 C16 36 40 20 55 20 C72 20 94 36 90 86 Q84 104 78 90 Q70 108 64 92 Q56 110 48 92 Q40 108 33 90 Q26 104 20 86 Z" fill="#F7F5EF" stroke="#D5CFC2" stroke-width="2.5" stroke-linejoin="round"/>'
			s += '<ellipse cx="44" cy="52" rx="7" ry="9" fill="#2B2430"/><ellipse cx="68" cy="52" rx="7" ry="9" fill="#2B2430"/>'
			s += '<ellipse cx="56" cy="70" rx="7" ry="6" fill="#2B2430"/>'
			return s + '<path d="M30 40 Q38 28 50 26" stroke="#FFFFFF" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.8"/>'
		"web":
			# A cobweb in a corner, with its spider on a thread.
			var s := ""
			for i in 7:
				var a := deg_to_rad(6.0 + i * 13.0)
				s += '<path d="M4 4 L%.1f %.1f" stroke="%s" stroke-width="2" opacity="0.85"/>' % [4.0 + cos(a) * 128.0, 4.0 + sin(a) * 128.0, BONE]
			for r in [34.0, 60.0, 86.0, 112.0]:
				var d := "M%.1f 4" % (4.0 + r)
				for i in 9:
					var a := deg_to_rad(i * 11.0)
					d += " Q%.1f %.1f %.1f %.1f" % [4.0 + cos(a + 0.1) * r * 0.86, 4.0 + sin(a + 0.1) * r * 0.86,
						4.0 + cos(a + 0.19) * r, 4.0 + sin(a + 0.19) * r]
				s += '<path d="%s" stroke="%s" stroke-width="1.8" fill="none" opacity="0.8"/>' % [d, BONE]
			s += '<path d="M96 24 V54" stroke="%s" stroke-width="1.6"/>' % BONE
			s += '<ellipse cx="96" cy="64" rx="11" ry="9" fill="#2B2430"/><circle cx="96" cy="53" r="6" fill="#2B2430"/>'
			s += '<path d="M86 58 l-12 -8 M86 64 l-14 2 M86 70 l-12 10 M106 58 l12 -8 M106 64 l14 2 M106 70 l12 10" stroke="#2B2430" stroke-width="2.5" stroke-linecap="round"/>'
			return s + '<circle cx="92" cy="51" r="2" fill="#E8542F"/><circle cx="100" cy="51" r="2" fill="#E8542F"/>'
		"skeleton":
			var s := '<ellipse cx="45" cy="26" rx="22" ry="24" fill="%s" stroke="#C9C2B0" stroke-width="2"/>' % BONE
			s += '<ellipse cx="36" cy="24" rx="7" ry="8" fill="#2B2430"/><ellipse cx="54" cy="24" rx="7" ry="8" fill="#2B2430"/>'
			s += '<path d="M42 36 l3 -6 l3 6 z" fill="#2B2430"/><path d="M32 42 h26" stroke="#2B2430" stroke-width="2"/>'
			s += '<path d="M38 44 v6 M45 44 v6 M52 44 v6" stroke="#2B2430" stroke-width="1.6"/>'
			s += '<rect x="41" y="50" width="8" height="70" rx="3" fill="%s"/>' % BONE
			for i in 4:
				s += '<path d="M41 %s q-18 2 -20 12 M49 %s q18 2 20 12" stroke="%s" stroke-width="6" fill="none" stroke-linecap="round"/>' % [58 + i * 14, 58 + i * 14, BONE]
			s += '<path d="M24 60 q-10 30 -4 56 M66 60 q10 30 4 56" stroke="%s" stroke-width="7" fill="none" stroke-linecap="round"/>' % BONE
			s += '<path d="M40 120 q-12 30 -10 58 M50 120 q12 30 10 58" stroke="%s" stroke-width="8" fill="none" stroke-linecap="round"/>' % BONE
			return s
		"grave":
			var s := '<path d="M22 108 V54 Q22 20 55 20 Q88 20 88 54 V108 Z" fill="#9A968E" stroke="#6E6A62" stroke-width="3"/>'
			s += '<path d="M28 100 V56 Q28 28 55 28 Q82 28 82 56 V100 Z" fill="#B5B0A6"/>'
			s += '<path d="M46 46 h18 M55 38 v36" stroke="#6E6A62" stroke-width="5" stroke-linecap="round"/>'
			s += '<path d="M38 84 h34 M42 94 h26" stroke="#6E6A62" stroke-width="3" opacity="0.7"/>'
			return s + '<path d="M6 108 Q55 96 104 108 Z" fill="#5E5A52"/>'
		"cat":
			# A black cat on the step, its back arched, eyes like two green moons.
			var s := '<path d="M14 72 Q18 34 44 30 Q70 26 82 50 Q90 66 86 72 Z" fill="#23232B"/>'
			s += '<circle cx="78" cy="38" r="17" fill="#23232B"/>'
			s += '<path d="M64 28 l-2 -18 l16 10 z M86 26 l10 -16 l6 18 z" fill="#23232B"/>'
			s += '<path d="M14 72 q-10 -24 2 -40 q10 6 4 40 z" fill="#23232B"/>'
			s += '<ellipse cx="72" cy="36" rx="4" ry="6" fill="#9BD16A"/><ellipse cx="86" cy="36" rx="4" ry="6" fill="#9BD16A"/>'
			return s + '<path d="M70 46 q8 4 16 0" stroke="#4A4A55" stroke-width="1.6" fill="none"/>'
		"spider":
			var s := '<path d="M60 10 V34" stroke="%s" stroke-width="2"/>' % BONE
			s += '<ellipse cx="60" cy="66" rx="26" ry="22" fill="#23232B"/><circle cx="60" cy="42" r="15" fill="#23232B"/>'
			for i in 4:
				var y := 50.0 + i * 11.0
				s += '<path d="M36 %s q-22 -6 -30 %s" stroke="#23232B" stroke-width="5" fill="none" stroke-linecap="round"/>' % [y, -14 + i * 10]
				s += '<path d="M84 %s q22 -6 30 %s" stroke="#23232B" stroke-width="5" fill="none" stroke-linecap="round"/>' % [y, -14 + i * 10]
			return s + '<circle cx="54" cy="40" r="4" fill="#E8542F"/><circle cx="66" cy="40" r="4" fill="#E8542F"/>'
		"broom":
			var s := '<rect x="31" y="4" width="8" height="112" rx="4" fill="#8A5A2E"/>'
			s += '<path d="M22 110 Q35 104 48 110 L58 156 Q35 166 12 156 Z" fill="#C9962E" stroke="#8A6A1E" stroke-width="2.5" stroke-linejoin="round"/>'
			for i in 6:
				s += '<path d="M%s 114 L%s 158" stroke="#8A6A1E" stroke-width="1.6" opacity="0.7"/>' % [20 + i * 6, 14 + i * 8]
			return s + '<rect x="20" y="106" width="30" height="8" rx="4" fill="#5E4228"/>'
		"candles":
			var s := ""
			for i in 3:
				var cx := 20.0 + i * 25.0
				var h := 30.0 + (i % 2) * 10.0
				s += '<rect x="%s" y="%s" width="14" height="%s" rx="4" fill="#F4F2EC" stroke="#D5CFC2" stroke-width="1.5"/>' % [cx - 7, 66 - h, h]
				s += '<path d="M%s %s q4 -8 0 -14 q-4 6 0 14 z" fill="#FFD23F"/>' % [cx, 66 - h]
			return s + '<rect x="4" y="62" width="82" height="8" rx="3" fill="#6E5444"/>'
		"bowl":
			var s := '<path d="M14 34 Q50 24 86 34 Q82 62 50 64 Q18 62 14 34 Z" fill="#E8542F" stroke="#B5361A" stroke-width="2.5"/>'
			for c in [["#F2C230", 32.0, 34.0], ["#7E57C2", 50.0, 30.0], ["#4FA3E0", 66.0, 34.0], ["#F4F2EC", 42.0, 26.0], ["#E8542F", 58.0, 25.0]]:
				s += '<circle cx="%s" cy="%s" r="8" fill="%s"/>' % [c[1], c[2], c[0]]
			return s + '<path d="M22 36 Q50 46 78 36" stroke="#B5361A" stroke-width="2" fill="none" opacity="0.5"/>'
		"scarecrow":
			var s := '<rect x="56" y="40" width="9" height="150" fill="#8A5A2E"/><rect x="18" y="74" width="86" height="8" rx="4" fill="#8A5A2E"/>'
			s += '<path d="M34 82 Q60 70 86 82 L92 140 Q60 152 28 140 Z" fill="#C9562E" stroke="#8E3A1E" stroke-width="2.5" stroke-linejoin="round"/>'
			s += '<path d="M34 82 l-14 16 M86 82 l14 16" stroke="#C9962E" stroke-width="6" stroke-linecap="round"/>'
			s += '<circle cx="60" cy="42" r="26" fill="#D9A23A" stroke="#A8762A" stroke-width="2.5"/>'
			s += '<path d="M30 34 Q60 16 90 34 Q60 26 30 34 Z" fill="#8A6A1E"/>'
			s += '<path d="M46 36 l10 10 l-10 10 z" fill="#2B2430"/><path d="M74 36 l-10 10 l10 10 z" fill="#2B2430"/>'
			s += '<path d="M48 60 q12 10 24 0" stroke="#2B2430" stroke-width="3" fill="none"/>'
			for i in 5:
				s += '<path d="M%s 140 l-4 18" stroke="#C9962E" stroke-width="4" stroke-linecap="round"/>' % (34 + i * 13)
			return s
		"garland":
			# A string of little pumpkins and bats along the railing.
			var s := '<path d="M4 10 Q70 44 140 18 Q210 44 276 10" stroke="#3A3A42" stroke-width="3" fill="none"/>'
			for i in 9:
				var t := (i + 0.5) / 9.0
				var gx := 4.0 + t * 272.0
				var gy := 10.0 + sin(t * PI * 2.0) * 16.0 + 16.0
				if i % 3 == 2:
					s += '<path d="M%s %s l10 -6 l10 6 l-10 10 z" fill="%s"/>' % [gx - 10, gy, PURPLE]
				else:
					s += '<circle cx="%s" cy="%s" r="9" fill="%s"/>' % [gx, gy, ORANGE]
					s += '<path d="M%s %s v-6" stroke="#4E7A30" stroke-width="3"/>' % [gx, gy - 8]
			return s
		"bats":
			var s := ""
			for b in [[20.0, 70.0, 1.0], [78.0, 24.0, 0.8], [132.0, 62.0, 0.9]]:
				s += '<g transform="translate(%s %s) scale(%s)">' % [b[0], b[1], b[2]]
				s += '<path d="M0 0 L-34 -14 L-26 4 L-40 10 L-18 18 L0 10 L18 18 L40 10 L26 4 L34 -14 Z" fill="#23232B"/>'
				s += '<circle cx="-6" cy="2" r="2.4" fill="#E8542F"/><circle cx="6" cy="2" r="2.4" fill="#E8542F"/>'
				s += "</g>"
			return s
	return ""


# A carved pumpkin: ribs, a stalk, a triangle face cut out and lit from inside.
static func _jack(cx: float, cy: float, scale: float) -> String:
	var s := '<g transform="translate(%s %s) scale(%s) translate(-45 -46)">' % [cx, cy, scale]
	s += '<path d="M45 10 q4 -10 14 -12 q-2 10 -10 14 z" fill="#4E7A30"/><rect x="41" y="4" width="9" height="14" rx="4" fill="#5E8A36"/>'
	s += '<ellipse cx="45" cy="46" rx="42" ry="32" fill="%s" stroke="%s" stroke-width="3"/>' % [ORANGE, DEEP]
	for dx in [-26.0, -13.0, 0.0, 13.0, 26.0]:
		s += '<path d="M%s 20 q-7 26 0 52" stroke="%s" stroke-width="2.5" fill="none" opacity="0.55"/>' % [45.0 + dx, DEEP]
	s += '<path d="M24 38 l12 -12 l12 12 z" fill="#2B1A08"/><path d="M66 38 l-12 -12 l-12 12 z" fill="#2B1A08"/>'
	s += '<path d="M24 56 q21 20 42 0 q-6 0 -8 -6 q-6 6 -13 0 q-7 6 -13 0 q-2 6 -8 6 z" fill="#2B1A08"/>'
	s += '<path d="M24 38 l12 -12 l12 12 z" fill="#FFD23F" opacity="0.55"/><path d="M66 38 l-12 -12 l-12 12 z" fill="#FFD23F" opacity="0.55"/>'
	s += '<path d="M24 56 q21 20 42 0 q-6 0 -8 -6 q-6 6 -13 0 q-7 6 -13 0 q-2 6 -8 6 z" fill="#FFD23F" opacity="0.5"/>'
	s += '<path d="M16 34 q6 -14 22 -18" stroke="#F2A24A" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.6"/>'
	return s + "</g>"
